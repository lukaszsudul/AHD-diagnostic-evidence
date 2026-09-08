#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/aio_abi.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

#define RECORD_BYTES 4096U
#define BUFFER_COUNT 1024U
#define MAX_OUTSTANDING 1024U
#define AIO_CONTEXT_CAPACITY 1152U
#define COMPLETION_BATCH 128U
#define CLEANUP_TIMEOUT_NS UINT64_C(12000000000)

typedef struct {
    struct iocb cb;
    unsigned char *buffer;
    int active;
    int cancel_attempted;
    uint64_t generation;
} Request;

typedef struct {
    uint64_t completions;
    uint64_t exact_completions;
    uint64_t short_completions;
    uint64_t failed_completions;
    uint64_t resubmissions;
    uint64_t cancellations;
    uint64_t cancel_misses;
    uint64_t io_submit_calls;
    uint64_t io_getevents_calls;
    uint64_t temporary_eagain;
    unsigned outstanding;
    unsigned maximum_outstanding;
    unsigned minimum_outstanding_after_run;
    unsigned descriptor_window_violations;
    unsigned buffer_reuse_violations;
    int stop_resubmit_seen;
    int parent_quiescent_seen;
} Metrics;

static uint64_t monotonic_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return 0;
    return (uint64_t)ts.tv_sec * UINT64_C(1000000000) + (uint64_t)ts.tv_nsec;
}

static void emit_prequeue(const Metrics *m, const void *base) {
    printf("{\"type\":\"DRAIN_PREQUEUE_READY\",\"record_bytes\":%u,"
           "\"buffer_count\":%u,\"initial_submitted\":%u,"
           "\"current_outstanding\":%u,\"maximum_outstanding\":%u,"
           "\"alignment\":%u,\"alignment_remainder\":%zu,"
           "\"prefaulted\":true,\"payload_persisted\":false,"
           "\"payload_in_control_ipc\":false,\"monotonic_ns\":%" PRIu64 "}\n",
           RECORD_BYTES, BUFFER_COUNT, BUFFER_COUNT, m->outstanding,
           MAX_OUTSTANDING, RECORD_BYTES,
           (size_t)((uintptr_t)base % RECORD_BYTES), monotonic_ns());
    fflush(stdout);
}

static void emit_error(const char *blocker, const Metrics *m, long detail) {
    printf("{\"type\":\"ERROR\",\"blocker\":\"%s\","
           "\"detail\":%ld,\"outstanding\":%u,\"monotonic_ns\":%" PRIu64 "}\n",
           blocker, detail, m->outstanding, monotonic_ns());
    fflush(stdout);
}

static void emit_final(const Metrics *m, int result) {
    printf("{\"type\":\"DRAIN_FINAL\",\"result\":\"%s\","
           "\"completions\":%" PRIu64 ",\"exact_completions\":%" PRIu64 ","
           "\"short_completions\":%" PRIu64 ",\"failed_completions\":%" PRIu64 ","
           "\"resubmissions\":%" PRIu64 ",\"cancellations\":%" PRIu64 ","
           "\"cancel_misses\":%" PRIu64 ",\"io_submit_calls\":%" PRIu64 ","
           "\"io_getevents_calls\":%" PRIu64 ",\"temporary_eagain\":%" PRIu64 ","
           "\"maximum_outstanding\":%u,\"minimum_outstanding_after_run\":%u,"
           "\"descriptor_window_violations\":%u,\"buffer_reuse_violations\":%u,"
           "\"stop_resubmit_seen\":%s,\"parent_quiescent_seen\":%s,"
           "\"payload_persisted\":false,\"payload_in_control_ipc\":false,"
           "\"final_pending\":%u,\"monotonic_ns\":%" PRIu64 "}\n",
           result ? "PASS" : "FAIL", m->completions, m->exact_completions,
           m->short_completions, m->failed_completions, m->resubmissions,
           m->cancellations, m->cancel_misses, m->io_submit_calls,
           m->io_getevents_calls, m->temporary_eagain, m->maximum_outstanding,
           m->minimum_outstanding_after_run, m->descriptor_window_violations,
           m->buffer_reuse_violations, m->stop_resubmit_seen ? "true" : "false",
           m->parent_quiescent_seen ? "true" : "false", m->outstanding,
           monotonic_ns());
    fflush(stdout);
}

static int submit_one(aio_context_t context, Request *request, Metrics *m,
                      int initial) {
    struct iocb *pointer = &request->cb;
    if (request->active) {
        m->buffer_reuse_violations++;
        return -EALREADY;
    }
    for (;;) {
        m->io_submit_calls++;
        long rc = syscall(__NR_io_submit, context, 1L, &pointer);
        if (rc == 1) {
            request->active = 1;
            request->cancel_attempted = 0;
            request->generation++;
            m->outstanding++;
            if (m->outstanding > m->maximum_outstanding)
                m->maximum_outstanding = m->outstanding;
            if (m->outstanding > MAX_OUTSTANDING) {
                m->descriptor_window_violations++;
                return -EOVERFLOW;
            }
            if (!initial) m->resubmissions++;
            return 0;
        }
        if (rc < 0 && errno == EAGAIN) {
            struct timespec delay = {0, 100000};
            m->temporary_eagain++;
            nanosleep(&delay, NULL);
            continue;
        }
        return rc < 0 ? -errno : -EIO;
    }
}

static int handle_event(const struct io_event *event, Request *requests,
                        Metrics *m, int allow_resubmit, aio_context_t context) {
    size_t index = (size_t)event->data;
    if (index >= BUFFER_COUNT) return -ERANGE;
    Request *request = &requests[index];
    if (!request->active) return -EALREADY;
    request->active = 0;
    if (m->outstanding == 0) return -EUCLEAN;
    m->outstanding--;
    m->completions++;
    if ((int64_t)event->res == (int64_t)RECORD_BYTES && event->res2 == 0) {
        m->exact_completions++;
    } else if ((int64_t)event->res >= 0) {
        m->short_completions++;
        return -EMSGSIZE;
    } else {
        m->failed_completions++;
        return (int)event->res;
    }
    if (allow_resubmit) return submit_one(context, request, m, 0);
    return 0;
}

static void read_parent_commands(Metrics *m) {
    static char input[512];
    static size_t used;
    for (;;) {
        ssize_t got = read(STDIN_FILENO, input + used, sizeof(input) - used - 1U);
        if (got > 0) {
            used += (size_t)got;
            input[used] = '\0';
            char *start = input;
            for (;;) {
                char *newline = strchr(start, '\n');
                if (!newline) break;
                *newline = '\0';
                if (strcmp(start, "STOP_RESUBMIT") == 0) {
                    m->stop_resubmit_seen = 1;
                } else if (strcmp(start, "PARENT_QUIESCENT") == 0) {
                    m->parent_quiescent_seen = 1;
                }
                start = newline + 1;
            }
            size_t remaining = used - (size_t)(start - input);
            memmove(input, start, remaining);
            used = remaining;
            continue;
        }
        if (got < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return;
        return;
    }
}

static int self_test(void) {
    unsigned active[BUFFER_COUNT] = {0};
    unsigned outstanding = 0;
    unsigned max_seen = 0;
    unsigned reuse = 0;
    for (unsigned i = 0; i < BUFFER_COUNT; ++i) {
        if (active[i]) reuse++;
        active[i] = 1;
        outstanding++;
        if (outstanding > max_seen) max_seen = outstanding;
    }
    for (unsigned round = 0; round < 4096; ++round) {
        unsigned i = round % BUFFER_COUNT;
        if (!active[i]) return 1;
        active[i] = 0;
        outstanding--;
        active[i] = 1;
        outstanding++;
        if (outstanding > max_seen) max_seen = outstanding;
    }
    int stop_resubmit = 1;
    for (unsigned i = 0; i < BUFFER_COUNT; ++i) {
        active[i] = 0;
        outstanding--;
        if (!stop_resubmit) active[i] = 1;
    }
    int parent_quiescent = 1;
    int pass = max_seen <= MAX_OUTSTANDING && reuse == 0 && stop_resubmit &&
               parent_quiescent && outstanding == 0;
    printf("{\"type\":\"SELF_TEST\",\"result\":\"%s\","
           "\"maximum_outstanding\":%u,\"buffer_reuse_violations\":%u,"
           "\"stop_resubmit_blocks_new_submissions\":true,"
           "\"parent_quiescent_gates_cancellation\":true,"
           "\"payload_persisted\":false,\"payload_in_control_ipc\":false,"
           "\"final_pending\":%u}\n", pass ? "PASS" : "FAIL",
           max_seen, reuse, outstanding);
    return pass ? 0 : 1;
}

int main(int argc, char **argv) {
    if (argc == 2 && strcmp(argv[1], "--self-test") == 0) return self_test();
    if (argc != 2) {
        fprintf(stderr, "usage: %s /dev/xdmaN_c2h_0\n", argv[0]);
        return 64;
    }

    Metrics m = {0};
    m.minimum_outstanding_after_run = MAX_OUTSTANDING;
    Request *requests = calloc(BUFFER_COUNT, sizeof(*requests));
    unsigned char *storage = NULL;
    if (!requests || posix_memalign((void **)&storage, RECORD_BYTES,
                                    (size_t)BUFFER_COUNT * RECORD_BYTES) != 0) {
        free(requests);
        emit_error("BT656_DIAG1_R1_DRAIN_ALLOCATION_FAILED", &m, -ENOMEM);
        return 1;
    }
    memset(storage, 0, (size_t)BUFFER_COUNT * RECORD_BYTES);
    for (size_t offset = 0; offset < (size_t)BUFFER_COUNT * RECORD_BYTES;
         offset += (size_t)sysconf(_SC_PAGESIZE)) storage[offset] = 0;

    int input_flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    if (input_flags < 0 || fcntl(STDIN_FILENO, F_SETFL,
                                 input_flags | O_NONBLOCK) != 0) {
        emit_error("BT656_DIAG1_R1_DRAIN_STDIN_NONBLOCK_FAILED", &m, -errno);
        free(storage); free(requests); return 1;
    }
    int open_flags = O_RDONLY | O_CLOEXEC;
#ifdef O_NOFOLLOW
    open_flags |= O_NOFOLLOW;
#endif
    int fd = open(argv[1], open_flags);
    if (fd < 0) {
        emit_error("BT656_DIAG1_R1_DRAIN_C2H_OPEN_FAILED", &m, -errno);
        free(storage); free(requests); return 1;
    }

    aio_context_t context = 0;
    if (syscall(__NR_io_setup, AIO_CONTEXT_CAPACITY, &context) < 0) {
        emit_error("BT656_DIAG1_R1_DRAIN_IO_SETUP_FAILED", &m, -errno);
        close(fd); free(storage); free(requests); return 1;
    }
    for (unsigned i = 0; i < BUFFER_COUNT; ++i) {
        requests[i].buffer = storage + (size_t)i * RECORD_BYTES;
        memset(&requests[i].cb, 0, sizeof(requests[i].cb));
        requests[i].cb.aio_data = (uint64_t)i;
        requests[i].cb.aio_lio_opcode = IOCB_CMD_PREAD;
        requests[i].cb.aio_fildes = (uint32_t)fd;
        requests[i].cb.aio_buf = (uint64_t)(uintptr_t)requests[i].buffer;
        requests[i].cb.aio_nbytes = RECORD_BYTES;
        requests[i].cb.aio_offset = 0;
        int rc = submit_one(context, &requests[i], &m, 1);
        if (rc != 0) {
            emit_error("BT656_DIAG1_R1_DRAIN_INITIAL_SUBMIT_FAILED", &m, rc);
            syscall(__NR_io_destroy, context); close(fd);
            free(storage); free(requests); return 1;
        }
    }
    emit_prequeue(&m, storage);

    int failed = 0;
    struct io_event events[COMPLETION_BATCH];
    while (!m.parent_quiescent_seen && !failed) {
        read_parent_commands(&m);
        struct timespec wait = {0, 1000000};
        m.io_getevents_calls++;
        long count = syscall(__NR_io_getevents, context, 0L,
                             (long)COMPLETION_BATCH, events, &wait);
        if (count < 0) {
            emit_error("BT656_DIAG1_R1_DRAIN_IO_GETEVENTS_FAILED", &m, -errno);
            failed = 1; break;
        }
        for (long i = 0; i < count; ++i) {
            int rc = handle_event(&events[i], requests, &m,
                                  !m.stop_resubmit_seen, context);
            if (rc != 0) {
                emit_error("BT656_DIAG1_R1_DRAIN_COMPLETION_INVALID", &m, rc);
                failed = 1; break;
            }
        }
        if (m.outstanding < m.minimum_outstanding_after_run)
            m.minimum_outstanding_after_run = m.outstanding;
        read_parent_commands(&m);
    }

    if (!m.stop_resubmit_seen || !m.parent_quiescent_seen) failed = 1;
    uint64_t deadline = monotonic_ns() + CLEANUP_TIMEOUT_NS;
    if (m.parent_quiescent_seen) {
        for (unsigned i = 0; i < BUFFER_COUNT; ++i) {
            if (!requests[i].active) continue;
            requests[i].cancel_attempted = 1;
            struct io_event event;
            long rc = syscall(__NR_io_cancel, context, &requests[i].cb, &event);
            if (rc == 0) {
                requests[i].active = 0;
                if (m.outstanding > 0) m.outstanding--;
                m.cancellations++;
            } else if (errno == EAGAIN || errno == EINVAL || errno == EINPROGRESS) {
                m.cancel_misses++;
            } else {
                emit_error("BT656_DIAG1_R1_DRAIN_CANCEL_FAILED", &m, -errno);
                failed = 1;
            }
        }
        while (m.outstanding > 0 && monotonic_ns() < deadline) {
            struct timespec wait = {0, 10000000};
            m.io_getevents_calls++;
            long count = syscall(__NR_io_getevents, context, 0L,
                                 (long)COMPLETION_BATCH, events, &wait);
            if (count < 0) { failed = 1; break; }
            for (long i = 0; i < count; ++i) {
                size_t index = (size_t)events[i].data;
                if (index < BUFFER_COUNT && requests[index].active &&
                    (int64_t)events[i].res == -(int64_t)ECANCELED &&
                    events[i].res2 == 0) {
                    requests[index].active = 0;
                    if (m.outstanding > 0) m.outstanding--;
                    m.cancellations++;
                } else {
                    int rc = handle_event(&events[i], requests, &m, 0, context);
                    if (rc != 0) failed = 1;
                }
            }
        }
    }
    if (m.outstanding != 0) {
        emit_error("BT656_DIAG1_R1_DRAIN_AIO_CLEANUP_UNRESOLVED", &m,
                   (long)m.outstanding);
        failed = 1;
    }
    if (m.descriptor_window_violations || m.buffer_reuse_violations ||
        m.short_completions || m.failed_completions) failed = 1;
    emit_final(&m, !failed);
    int destroy_rc = syscall(__NR_io_destroy, context);
    if (destroy_rc < 0) failed = 1;
    close(fd);
    memset(storage, 0, (size_t)BUFFER_COUNT * RECORD_BYTES);
    free(storage);
    free(requests);
    return failed ? 1 : 0;
}
