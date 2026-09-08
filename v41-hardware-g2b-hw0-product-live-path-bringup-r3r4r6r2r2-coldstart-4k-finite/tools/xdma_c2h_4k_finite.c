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
#include <sys/stat.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

#define PRIMARY_RECORDS 2500U
#define RECORD_BYTES 4096U
#define PRIMARY_BYTES ((size_t)PRIMARY_RECORDS * (size_t)RECORD_BYTES)
#define AIO_CAPACITY 4096U
#define SUBMIT_TIMEOUT_NS UINT64_C(15000000000)
#define FAILURE_DRAIN_NS UINT64_C(10000000000)

typedef struct {
    struct iocb cb;
    uint64_t submitted_ns;
    uint64_t completed_ns;
    int64_t result;
    int64_t result2;
    size_t completion_order;
    unsigned submission_call;
    int accepted;
    int completed;
} Request;

static uint64_t monotonic_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        return 0;
    }
    return (uint64_t)ts.tv_sec * UINT64_C(1000000000) + (uint64_t)ts.tv_nsec;
}

static void emit_simple(const char *type) {
    printf("{\"type\":\"%s\",\"monotonic_ns\":%" PRIu64 "}\n",
           type, monotonic_ns());
    fflush(stdout);
}

static void emit_error(const char *blocker, size_t index, int64_t result,
                       int64_t result2, size_t pending) {
    printf("{\"type\":\"ERROR\",\"blocker\":\"%s\","
           "\"index\":%zu,\"result_bytes\":%" PRId64 ","
           "\"result2\":%" PRId64 ",\"pending\":%zu,"
           "\"monotonic_ns\":%" PRIu64 "}\n",
           blocker, index, result, result2, pending, monotonic_ns());
    fflush(stdout);
}

static int write_all_at(int fd, const void *buffer, size_t bytes, off_t offset) {
    size_t done = 0;
    while (done < bytes) {
        ssize_t rc = pwrite(fd, (const char *)buffer + done, bytes - done,
                            offset + (off_t)done);
        if (rc < 0 && errno == EINTR) {
            continue;
        }
        if (rc <= 0) {
            return -1;
        }
        done += (size_t)rc;
    }
    return 0;
}

static int open_exclusive(const char *directory, const char *name) {
    char path[4096];
    int count = snprintf(path, sizeof(path), "%s/%s", directory, name);
    if (count < 0 || count >= (int)sizeof(path)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    return open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
                0600);
}

static int persist_metadata(const char *directory, const Request *requests,
                            size_t submitted, size_t completed,
                            size_t exact, size_t short_count,
                            size_t failed_count, unsigned submit_calls) {
    int fd = open_exclusive(directory, "submissions.csv");
    if (fd < 0) {
        return -1;
    }
    FILE *file = fdopen(fd, "w");
    if (file == NULL) {
        close(fd);
        return -1;
    }
    fprintf(file, "RequestIndex,RequestedBytes,AioData,AioOffset,BufferOffset,"
                  "SubmissionCall,Accepted,SubmittedMonotonicNs\n");
    for (size_t index = 0; index < PRIMARY_RECORDS; ++index) {
        const Request *request = &requests[index];
        fprintf(file, "%zu,%u,%zu,0,%zu,%u,%d,%" PRIu64 "\n",
                index, RECORD_BYTES, index, index * (size_t)RECORD_BYTES,
                request->submission_call, request->accepted,
                request->submitted_ns);
    }
    if (fflush(file) != 0 || fsync(fileno(file)) != 0 || fclose(file) != 0) {
        return -1;
    }

    fd = open_exclusive(directory, "completions.csv");
    if (fd < 0) {
        return -1;
    }
    file = fdopen(fd, "w");
    if (file == NULL) {
        close(fd);
        return -1;
    }
    fprintf(file, "RequestIndex,RequestedBytes,ResultBytes,Result2,"
                  "CompletionSequence,CompletedMonotonicNs,Exact\n");
    for (size_t order = 0; order < completed; ++order) {
        for (size_t index = 0; index < PRIMARY_RECORDS; ++index) {
            const Request *request = &requests[index];
            if (request->completed && request->completion_order == order) {
                fprintf(file, "%zu,%u,%" PRId64 ",%" PRId64 ",%zu,%" PRIu64
                              ",%s\n",
                        index, RECORD_BYTES, request->result, request->result2,
                        order, request->completed_ns,
                        (request->result == RECORD_BYTES && request->result2 == 0)
                            ? "YES" : "NO");
                break;
            }
        }
    }
    if (fflush(file) != 0 || fsync(fileno(file)) != 0 || fclose(file) != 0) {
        return -1;
    }

    fd = open_exclusive(directory, "helper-result.json");
    if (fd < 0) {
        return -1;
    }
    dprintf(fd,
            "{\n  \"schema\": \"R3R4R6R2R2_4K_HELPER_RESULT_V1\",\n"
            "  \"requested_records\": %u,\n  \"request_bytes\": %u,\n"
            "  \"requested_bytes\": %zu,\n  \"submitted_requests\": %zu,\n"
            "  \"completed_requests\": %zu,\n  \"exact_completions\": %zu,\n"
            "  \"short_completions\": %zu,\n  \"failed_completions\": %zu,\n"
            "  \"pending_requests\": %zu,\n  \"submission_calls\": %u,\n"
            "  \"assembly_basis\": \"REQUEST_INDEX\",\n"
            "  \"raw_payload_control_ipc\": false\n}\n",
            PRIMARY_RECORDS, RECORD_BYTES, PRIMARY_BYTES, submitted, completed,
            exact, short_count, failed_count, submitted - completed, submit_calls);
    if (fsync(fd) != 0 || close(fd) != 0) {
        return -1;
    }
    return 0;
}

static int persist_primary(const char *directory, const unsigned char *primary,
                           const Request *requests, int complete_window) {
    const char *name = complete_window ? "primary.bin" : "primary-partial-by-index.bin";
    int fd = open_exclusive(directory, name);
    if (fd < 0) {
        return -1;
    }
    if (complete_window) {
        if (write_all_at(fd, primary, PRIMARY_BYTES, 0) != 0) {
            close(fd);
            return -1;
        }
    } else {
        for (size_t index = 0; index < PRIMARY_RECORDS; ++index) {
            if (!requests[index].completed || requests[index].result <= 0) {
                continue;
            }
            size_t bytes = (size_t)requests[index].result;
            if (bytes > RECORD_BYTES) {
                bytes = RECORD_BYTES;
            }
            if (write_all_at(fd, primary + index * (size_t)RECORD_BYTES, bytes,
                             (off_t)(index * (size_t)RECORD_BYTES)) != 0) {
                close(fd);
                return -1;
            }
        }
    }
    if (fsync(fd) != 0 || close(fd) != 0) {
        return -1;
    }
    return 0;
}

static int read_parent_command(int *parent_quiescent) {
    struct pollfd input = {STDIN_FILENO, POLLIN, 0};
    int rc = poll(&input, 1, 0);
    if (rc < 0 && errno == EINTR) {
        return 0;
    }
    if (rc < 0) {
        return -1;
    }
    if (rc > 0 && (input.revents & POLLIN)) {
        char command[128];
        if (fgets(command, sizeof(command), stdin) != NULL &&
            strcmp(command, "PARENT_QUIESCENT\n") == 0) {
            *parent_quiescent = 1;
            return 1;
        }
        return -1;
    }
    return 0;
}

static void cancel_pending(aio_context_t context, Request *requests,
                           size_t submitted, size_t *completed,
                           size_t *completion_order) {
    for (size_t index = 0; index < submitted; ++index) {
        if (requests[index].completed) {
            continue;
        }
        struct io_event event;
        memset(&event, 0, sizeof(event));
        long rc = syscall(__NR_io_cancel, context, &requests[index].cb, &event);
        if (rc == 0) {
            requests[index].completed = 1;
            requests[index].result = (int64_t)event.res;
            requests[index].result2 = (int64_t)event.res2;
            requests[index].completed_ns = monotonic_ns();
            requests[index].completion_order = (*completion_order)++;
            ++(*completed);
        }
    }
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s /dev/xdma0_c2h_0 PRIVATE_DIRECTORY\n", argv[0]);
        return 64;
    }
    if (strcmp(argv[1], "/dev/xdma0_c2h_0") != 0) {
        fprintf(stderr, "exact C2H device required\n");
        return 64;
    }
    umask(0077);
    setvbuf(stdout, NULL, _IOLBF, 0);

    unsigned char *primary = NULL;
    if (posix_memalign((void **)&primary, RECORD_BYTES, PRIMARY_BYTES) != 0) {
        emit_simple("BUFFER_ALLOCATION_FAILED");
        return 70;
    }
    memset(primary, 0, PRIMARY_BYTES); /* allocates and prefaults every page */

    Request *requests = calloc(PRIMARY_RECORDS, sizeof(*requests));
    struct iocb **pointers = calloc(PRIMARY_RECORDS, sizeof(*pointers));
    if (requests == NULL || pointers == NULL) {
        emit_simple("CONTROL_ALLOCATION_FAILED");
        free(requests);
        free(pointers);
        free(primary);
        return 70;
    }

    int flags = O_RDONLY | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    int c2h = open(argv[1], flags);
    if (c2h < 0) {
        emit_simple("C2H_OPEN_FAILED");
        free(requests);
        free(pointers);
        free(primary);
        return 71;
    }

    for (size_t index = 0; index < PRIMARY_RECORDS; ++index) {
        Request *request = &requests[index];
        memset(&request->cb, 0, sizeof(request->cb));
        request->cb.aio_data = index;
        request->cb.aio_lio_opcode = IOCB_CMD_PREAD;
        request->cb.aio_fildes = (uint32_t)c2h;
        request->cb.aio_buf = (uint64_t)(uintptr_t)(primary + index * RECORD_BYTES);
        request->cb.aio_nbytes = RECORD_BYTES;
        request->cb.aio_offset = 0;
        pointers[index] = &request->cb;
    }

    aio_context_t context = 0;
    if (syscall(__NR_io_setup, AIO_CAPACITY, &context) < 0) {
        emit_simple("IO_SETUP_FAILED");
        close(c2h);
        free(requests);
        free(pointers);
        free(primary);
        return 72;
    }

    size_t submitted = 0;
    unsigned submit_calls = 0;
    uint64_t submit_deadline = monotonic_ns() + SUBMIT_TIMEOUT_NS;
    while (submitted < PRIMARY_RECORDS && monotonic_ns() < submit_deadline) {
        long rc = syscall(__NR_io_submit, context,
                          (long)(PRIMARY_RECORDS - submitted),
                          pointers + submitted);
        ++submit_calls;
        if (rc < 0 && (errno == EINTR || errno == EAGAIN)) {
            struct timespec pause = {0, 1000000};
            nanosleep(&pause, NULL);
            continue;
        }
        if (rc <= 0) {
            break;
        }
        uint64_t stamp = monotonic_ns();
        for (long offset = 0; offset < rc; ++offset) {
            size_t index = submitted + (size_t)offset;
            requests[index].accepted = 1;
            requests[index].submitted_ns = stamp;
            requests[index].submission_call = submit_calls;
        }
        submitted += (size_t)rc;
    }

    struct io_event early[16];
    struct timespec zero_timeout = {0, 0};
    long early_count = syscall(__NR_io_getevents, context, 0, 16, early,
                               &zero_timeout);
    if (submitted != PRIMARY_RECORDS || early_count != 0) {
        emit_error("R3R4R6R2R2_AIO_PREQUEUE_FAILED", submitted,
                   (int64_t)submitted, (int64_t)early_count,
                   submitted);
        size_t completed = 0;
        size_t order = 0;
        cancel_pending(context, requests, submitted, &completed, &order);
        syscall(__NR_io_destroy, context);
        close(c2h);
        free(requests);
        free(pointers);
        free(primary);
        return 73;
    }

    printf("{\"type\":\"PREQUEUE_READY\",\"request_count\":%u,"
           "\"submitted_requests\":%zu,\"request_bytes\":%u,"
           "\"primary_bytes\":%zu,\"pending\":%zu,"
           "\"alignment\":%u,\"alignment_remainder\":%zu,"
           "\"submit_calls\":%u,\"aio_context_active\":true,"
           "\"prefaulted\":true,\"monotonic_ns\":%" PRIu64 "}\n",
           PRIMARY_RECORDS, submitted, RECORD_BYTES, PRIMARY_BYTES, submitted,
           RECORD_BYTES, (size_t)((uintptr_t)primary % RECORD_BYTES),
           submit_calls, monotonic_ns());
    fflush(stdout);

    size_t completed = 0;
    size_t exact = 0;
    size_t short_count = 0;
    size_t failed_count = 0;
    size_t completion_order = 0;
    int failure_reported = 0;
    int parent_quiescent = 0;
    uint64_t failure_cleanup_deadline = 0;

    while (completed < PRIMARY_RECORDS) {
        int command = read_parent_command(&parent_quiescent);
        if (command < 0) {
            failure_reported = 1;
            emit_error("R3R4R6R2R2_PARENT_COMMAND_INVALID", PRIMARY_RECORDS,
                       -EINVAL, 0, submitted - completed);
        }
        if (parent_quiescent && failure_cleanup_deadline == 0) {
            failure_cleanup_deadline = monotonic_ns() + FAILURE_DRAIN_NS;
        }
        if (failure_cleanup_deadline != 0 &&
            monotonic_ns() >= failure_cleanup_deadline) {
            cancel_pending(context, requests, submitted, &completed,
                           &completion_order);
            failure_cleanup_deadline = UINT64_MAX;
            if (completed < submitted) {
                emit_error("R3R4R6R2R2_PENDING_AIO_AFTER_CANCEL", PRIMARY_RECORDS,
                           -EINPROGRESS, 0, submitted - completed);
                break;
            }
        }

        struct io_event events[128];
        struct timespec timeout = {0, 100000000};
        long count = syscall(__NR_io_getevents, context, 0, 128, events, &timeout);
        if (count < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (!failure_reported) {
                emit_error("R3R4R6R2R2_IO_GETEVENTS_FAILED", PRIMARY_RECORDS,
                           -errno, 0, submitted - completed);
                failure_reported = 1;
            }
            continue;
        }
        for (long event_index = 0; event_index < count; ++event_index) {
            uint64_t id = events[event_index].data;
            if (id >= PRIMARY_RECORDS || requests[id].completed) {
                if (!failure_reported) {
                    emit_error("R3R4R6R2R2_COMPLETION_ID_INVALID", (size_t)id,
                               (int64_t)events[event_index].res,
                               (int64_t)events[event_index].res2,
                               submitted - completed);
                    failure_reported = 1;
                }
                continue;
            }
            Request *request = &requests[id];
            request->completed = 1;
            request->result = (int64_t)events[event_index].res;
            request->result2 = (int64_t)events[event_index].res2;
            request->completed_ns = monotonic_ns();
            request->completion_order = completion_order++;
            ++completed;
            if (request->result == RECORD_BYTES && request->result2 == 0) {
                ++exact;
            } else {
                if (request->result >= 0 && request->result < RECORD_BYTES) {
                    ++short_count;
                } else {
                    ++failed_count;
                }
                if (!failure_reported) {
                    emit_error("R3R4R6R2R2_4K_PRIMARY_REQUEST_NOT_EXACT",
                               (size_t)id, request->result, request->result2,
                               submitted - completed);
                    failure_reported = 1;
                }
            }
        }
    }

    int complete_window = (completed == PRIMARY_RECORDS &&
                           exact == PRIMARY_RECORDS && short_count == 0 &&
                           failed_count == 0);
    if (complete_window) {
        printf("{\"type\":\"PRIMARY_WINDOW_COMPLETE\","
               "\"exact_completions\":%zu,\"short_completions\":%zu,"
               "\"failed_completions\":%zu,\"pending\":%zu,"
               "\"primary_bytes\":%zu,\"monotonic_ns\":%" PRIu64 "}\n",
               exact, short_count, failed_count, submitted - completed,
               PRIMARY_BYTES, monotonic_ns());
        fflush(stdout);
    }

    int persistence_failed = 0;
    if (persist_primary(argv[2], primary, requests, complete_window) != 0 ||
        persist_metadata(argv[2], requests, submitted, completed, exact,
                         short_count, failed_count, submit_calls) != 0) {
        persistence_failed = 1;
        emit_error("R3R4R6R2R2_PRIMARY_PERSISTENCE_FAILED", PRIMARY_RECORDS,
                   -errno, 0, submitted - completed);
    } else {
        printf("{\"type\":\"PRIMARY_PERSISTENCE_COMPLETE\","
               "\"file_bytes\":%zu,\"complete_window\":%s,"
               "\"pending\":%zu,\"monotonic_ns\":%" PRIu64 "}\n",
               complete_window ? PRIMARY_BYTES : 0,
               complete_window ? "true" : "false", submitted - completed,
               monotonic_ns());
        fflush(stdout);
    }

    while (!parent_quiescent) {
        struct pollfd input = {STDIN_FILENO, POLLIN, 0};
        int rc = poll(&input, 1, 1000);
        if (rc < 0 && errno == EINTR) {
            continue;
        }
        if (rc <= 0) {
            continue;
        }
        if (read_parent_command(&parent_quiescent) < 0) {
            emit_error("R3R4R6R2R2_PARENT_COMMAND_INVALID", PRIMARY_RECORDS,
                       -EINVAL, 0, submitted - completed);
            failure_reported = 1;
        }
    }

    int destroy_failed = syscall(__NR_io_destroy, context) < 0;
    close(c2h);
    free(requests);
    free(pointers);
    free(primary);
    if (destroy_failed) {
        emit_simple("IO_DESTROY_FAILED");
        return 75;
    }
    emit_simple("HELPER_EXIT_READY");
    return (complete_window && !persistence_failed && !failure_reported) ? 0 : 1;
}
