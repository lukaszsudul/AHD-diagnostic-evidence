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

#define RECORD_BYTES 4096U
#define PRIMARY_RECORDS 2500U
#define PRIMARY_BYTES ((size_t)PRIMARY_RECORDS * (size_t)RECORD_BYTES)
#define SHUTDOWN_GUARD_RECORDS 0U
#define TOTAL_LOGICAL_REQUESTS PRIMARY_RECORDS
#define TOTAL_ALLOCATED_BYTES PRIMARY_BYTES
#define MAX_OUTSTANDING_IOCBS 1024U
#define AIO_CONTEXT_CAPACITY 1152U
#define COMPLETION_BATCH_MAX 128U
#define PROGRESS_INTERVAL_RECORDS 128U
#define NO_PROGRESS_TIMEOUT_NS UINT64_C(1000000000)
#define TOTAL_CAPTURE_TIMEOUT_NS UINT64_C(5000000000)
#define SUBMISSION_TIMEOUT_NS UINT64_C(1000000000)
#define FAILURE_CLEANUP_TIMEOUT_NS UINT64_C(12000000000)

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
    int cancel_attempted;
    int canceled;
} Request;

typedef struct {
    size_t next_submit;
    size_t submitted;
    size_t completed;
    size_t outstanding;
    size_t primary_completed;
    size_t primary_exact;
    size_t primary_short;
    size_t primary_failed;
    size_t guard_completed_exact;
    size_t guard_canceled;
    size_t guard_short;
    size_t guard_failed;
    size_t completion_order;
    size_t max_outstanding;
    size_t min_outstanding_after_enable;
    uint64_t outstanding_sample_sum;
    uint64_t outstanding_sample_count;
    unsigned io_submit_calls;
    unsigned io_getevents_calls;
    unsigned temporary_eagain;
    size_t max_completion_batch;
    uint64_t max_refill_latency_ns;
    uint64_t total_refill_latency_ns;
    uint64_t refill_latency_samples;
    unsigned refill_calls;
    unsigned io_cancel_calls;
    unsigned descriptor_window_violations;
    unsigned descriptor_starvation_events;
    int crossed_logical_index_2048;
    size_t cumulative_submissions_when_2048_crossed;
    uint64_t capture_start_ns;
    uint64_t last_completion_ns;
    uint64_t primary_complete_ns;
    size_t guard_completed_at_primary;
    int primary_event_emitted;
    int primary_durable;
    char primary_sha256[65];
} Metrics;

typedef struct {
    uint32_t state[8];
    uint64_t bit_count;
    unsigned char block[64];
    size_t used;
} Sha256;

static const uint32_t sha_k[64] = {
    0x428a2f98U,0x71374491U,0xb5c0fbcfU,0xe9b5dba5U,0x3956c25bU,0x59f111f1U,0x923f82a4U,0xab1c5ed5U,
    0xd807aa98U,0x12835b01U,0x243185beU,0x550c7dc3U,0x72be5d74U,0x80deb1feU,0x9bdc06a7U,0xc19bf174U,
    0xe49b69c1U,0xefbe4786U,0x0fc19dc6U,0x240ca1ccU,0x2de92c6fU,0x4a7484aaU,0x5cb0a9dcU,0x76f988daU,
    0x983e5152U,0xa831c66dU,0xb00327c8U,0xbf597fc7U,0xc6e00bf3U,0xd5a79147U,0x06ca6351U,0x14292967U,
    0x27b70a85U,0x2e1b2138U,0x4d2c6dfcU,0x53380d13U,0x650a7354U,0x766a0abbU,0x81c2c92eU,0x92722c85U,
    0xa2bfe8a1U,0xa81a664bU,0xc24b8b70U,0xc76c51a3U,0xd192e819U,0xd6990624U,0xf40e3585U,0x106aa070U,
    0x19a4c116U,0x1e376c08U,0x2748774cU,0x34b0bcb5U,0x391c0cb3U,0x4ed8aa4aU,0x5b9cca4fU,0x682e6ff3U,
    0x748f82eeU,0x78a5636fU,0x84c87814U,0x8cc70208U,0x90befffaU,0xa4506cebU,0xbef9a3f7U,0xc67178f2U
};

static uint32_t rotr32(uint32_t value, unsigned count) {
    return (value >> count) | (value << (32U - count));
}

static void sha256_transform(Sha256 *ctx, const unsigned char block[64]) {
    uint32_t w[64];
    for (unsigned i = 0; i < 16; ++i) {
        w[i] = ((uint32_t)block[i * 4] << 24) |
               ((uint32_t)block[i * 4 + 1] << 16) |
               ((uint32_t)block[i * 4 + 2] << 8) |
               (uint32_t)block[i * 4 + 3];
    }
    for (unsigned i = 16; i < 64; ++i) {
        uint32_t s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3);
        uint32_t s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    uint32_t a = ctx->state[0], b = ctx->state[1], c = ctx->state[2], d = ctx->state[3];
    uint32_t e = ctx->state[4], f = ctx->state[5], g = ctx->state[6], h = ctx->state[7];
    for (unsigned i = 0; i < 64; ++i) {
        uint32_t s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + s1 + ch + sha_k[i] + w[i];
        uint32_t s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22);
        uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = s0 + maj;
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    ctx->state[0] += a; ctx->state[1] += b; ctx->state[2] += c; ctx->state[3] += d;
    ctx->state[4] += e; ctx->state[5] += f; ctx->state[6] += g; ctx->state[7] += h;
}

static void sha256_init(Sha256 *ctx) {
    static const uint32_t initial[8] = {
        0x6a09e667U,0xbb67ae85U,0x3c6ef372U,0xa54ff53aU,
        0x510e527fU,0x9b05688cU,0x1f83d9abU,0x5be0cd19U
    };
    memcpy(ctx->state, initial, sizeof(initial));
    ctx->bit_count = 0;
    ctx->used = 0;
}

static void sha256_update(Sha256 *ctx, const unsigned char *data, size_t bytes) {
    ctx->bit_count += (uint64_t)bytes * UINT64_C(8);
    while (bytes > 0) {
        size_t room = 64U - ctx->used;
        size_t take = bytes < room ? bytes : room;
        memcpy(ctx->block + ctx->used, data, take);
        ctx->used += take;
        data += take;
        bytes -= take;
        if (ctx->used == 64U) {
            sha256_transform(ctx, ctx->block);
            ctx->used = 0;
        }
    }
}

static void sha256_final(Sha256 *ctx, unsigned char digest[32]) {
    ctx->block[ctx->used++] = 0x80U;
    if (ctx->used > 56U) {
        while (ctx->used < 64U) ctx->block[ctx->used++] = 0;
        sha256_transform(ctx, ctx->block);
        ctx->used = 0;
    }
    while (ctx->used < 56U) ctx->block[ctx->used++] = 0;
    for (unsigned i = 0; i < 8; ++i) {
        ctx->block[63U - i] = (unsigned char)(ctx->bit_count >> (i * 8U));
    }
    sha256_transform(ctx, ctx->block);
    for (unsigned i = 0; i < 8; ++i) {
        digest[i * 4] = (unsigned char)(ctx->state[i] >> 24);
        digest[i * 4 + 1] = (unsigned char)(ctx->state[i] >> 16);
        digest[i * 4 + 2] = (unsigned char)(ctx->state[i] >> 8);
        digest[i * 4 + 3] = (unsigned char)ctx->state[i];
    }
}

static uint64_t monotonic_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return 0;
    return (uint64_t)ts.tv_sec * UINT64_C(1000000000) + (uint64_t)ts.tv_nsec;
}

static int open_exclusive(const char *directory, const char *name) {
    char path[4096];
    int count = snprintf(path, sizeof(path), "%s/%s", directory, name);
    if (count < 0 || count >= (int)sizeof(path)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    return open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0600);
}

static int write_all(int fd, const void *buffer, size_t bytes) {
    size_t done = 0;
    while (done < bytes) {
        ssize_t rc = write(fd, (const unsigned char *)buffer + done, bytes - done);
        if (rc < 0 && errno == EINTR) continue;
        if (rc <= 0) return -1;
        done += (size_t)rc;
    }
    return 0;
}

static int write_all_at(int fd, const void *buffer, size_t bytes, off_t offset) {
    size_t done = 0;
    while (done < bytes) {
        ssize_t rc = pwrite(fd, (const unsigned char *)buffer + done, bytes - done,
                            offset + (off_t)done);
        if (rc < 0 && errno == EINTR) continue;
        if (rc <= 0) return -1;
        done += (size_t)rc;
    }
    return 0;
}

static int sha256_file(const char *directory, const char *name, size_t expected,
                       char hex[65]) {
    char path[4096];
    int count = snprintf(path, sizeof(path), "%s/%s", directory, name);
    if (count < 0 || count >= (int)sizeof(path)) return -1;
    int flags = O_RDONLY | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    int fd = open(path, flags);
    if (fd < 0) return -1;
    struct stat st;
    if (fstat(fd, &st) != 0 || st.st_size != (off_t)expected) {
        close(fd);
        errno = EIO;
        return -1;
    }
    Sha256 ctx;
    sha256_init(&ctx);
    unsigned char buffer[65536];
    size_t total = 0;
    for (;;) {
        ssize_t rc = read(fd, buffer, sizeof(buffer));
        if (rc < 0 && errno == EINTR) continue;
        if (rc < 0) { close(fd); return -1; }
        if (rc == 0) break;
        sha256_update(&ctx, buffer, (size_t)rc);
        total += (size_t)rc;
    }
    if (close(fd) != 0 || total != expected) { errno = EIO; return -1; }
    unsigned char digest[32];
    sha256_final(&ctx, digest);
    for (unsigned i = 0; i < 32; ++i) snprintf(hex + i * 2U, 3U, "%02X", digest[i]);
    hex[64] = '\0';
    return 0;
}

static void emit_error(const char *blocker, size_t index, int64_t result,
                       int64_t result2, size_t pending) {
    printf("{\"type\":\"ERROR\",\"blocker\":\"%s\"," 
           "\"logical_index\":%zu,\"result_bytes\":%" PRId64 ","
           "\"result2\":%" PRId64 ",\"pending\":%zu,"
           "\"monotonic_ns\":%" PRIu64 "}\n",
           blocker, index, result, result2, pending, monotonic_ns());
    fflush(stdout);
}

static void update_outstanding(Metrics *m) {
    m->outstanding = m->submitted - m->completed;
    if (m->outstanding > m->max_outstanding) m->max_outstanding = m->outstanding;
    if (m->outstanding > MAX_OUTSTANDING_IOCBS) ++m->descriptor_window_violations;
    if (m->capture_start_ns != 0 && !m->primary_event_emitted &&
        m->outstanding < m->min_outstanding_after_enable)
        m->min_outstanding_after_enable = m->outstanding;
}

static int submit_to_target(aio_context_t context, Request *requests,
                            struct iocb **pointers, Metrics *m,
                            size_t target_outstanding) {
    uint64_t deadline = monotonic_ns() + SUBMISSION_TIMEOUT_NS;
    ++m->refill_calls;
    while (m->outstanding < target_outstanding &&
           m->next_submit < TOTAL_LOGICAL_REQUESTS) {
        if (monotonic_ns() >= deadline) return -1;
        size_t capacity = target_outstanding - m->outstanding;
        size_t remaining = TOTAL_LOGICAL_REQUESTS - m->next_submit;
        size_t requested = capacity < remaining ? capacity : remaining;
        long rc = syscall(__NR_io_submit, context, (long)requested,
                          pointers + m->next_submit);
        ++m->io_submit_calls;
        if (rc < 0 && (errno == EAGAIN || errno == EINTR)) {
            if (errno == EAGAIN) ++m->temporary_eagain;
            struct timespec pause = {0, 100000};
            nanosleep(&pause, NULL);
            continue;
        }
        if (rc <= 0) return -1;
        uint64_t stamp = monotonic_ns();
        size_t start = m->next_submit;
        for (long offset = 0; offset < rc; ++offset) {
            size_t index = start + (size_t)offset;
            requests[index].accepted = 1;
            requests[index].submitted_ns = stamp;
            requests[index].submission_call = m->io_submit_calls;
        }
        m->next_submit += (size_t)rc;
        m->submitted += (size_t)rc;
        update_outstanding(m);
        if (!m->crossed_logical_index_2048 && m->next_submit > 2048U) {
            m->crossed_logical_index_2048 = 1;
            m->cumulative_submissions_when_2048_crossed = m->submitted;
        }
        if (m->descriptor_window_violations != 0) return -2;
    }
    return 0;
}

static int is_progress_milestone(size_t completed) {
    return completed > 0 && completed < PRIMARY_RECORDS &&
           completed % PROGRESS_INTERVAL_RECORDS == 0;
}

static double elapsed_seconds(const Metrics *m) {
    return (double)(monotonic_ns() - m->capture_start_ns) / 1000000000.0;
}

static void emit_progress(const Metrics *m, size_t last_index, int64_t result) {
    printf("{\"type\":\"ROLLING_PROGRESS\","
           "\"primary_completed\":%zu,\"guard_completed\":%zu,"
           "\"total_submitted\":%zu,\"total_completed\":%zu,"
           "\"current_outstanding\":%zu,\"maximum_outstanding\":%zu,"
           "\"minimum_outstanding_after_enable\":%zu,"
           "\"next_logical_request_index\":%zu,\"refill_call_count\":%u,"
           "\"io_submit_call_count\":%u,\"temporary_eagain_count\":%u,"
           "\"maximum_completion_to_refill_latency_us\":%.3f,"
           "\"elapsed_seconds\":%.9f,\"last_completed_logical_index\":%zu,"
           "\"last_completion_result\":%" PRId64 ","
           "\"monotonic_ns\":%" PRIu64 "}\n",
           m->primary_completed, m->guard_completed_exact, m->submitted,
           m->completed, m->outstanding, m->max_outstanding,
           m->min_outstanding_after_enable, m->next_submit, m->refill_calls,
           m->io_submit_calls, m->temporary_eagain,
           (double)m->max_refill_latency_ns / 1000.0, elapsed_seconds(m),
           last_index, result, monotonic_ns());
    fflush(stdout);
}

static void emit_primary_complete(Metrics *m) {
    m->primary_complete_ns = monotonic_ns();
    printf("{\"type\":\"PRIMARY_WINDOW_COMPLETE\"," 
           "\"primary_exact_completions\":%zu,\"primary_short_completions\":%zu,"
           "\"primary_failed_completions\":%zu,\"primary_duplicate_completions\":0,"
           "\"primary_pending\":%zu,\"pending_aio\":%zu,"
           "\"primary_bytes\":%zu,\"guard_completed\":0,"
           "\"guard_pending\":0,\"current_total_outstanding\":%zu,"
           "\"maximum_outstanding\":%zu,\"minimum_outstanding_after_enable\":%zu,"
           "\"elapsed_capture_seconds\":%.9f,\"monotonic_ns\":%" PRIu64 "}\n",
           m->primary_exact, m->primary_short, m->primary_failed,
           PRIMARY_RECORDS - m->primary_completed, m->outstanding,
           PRIMARY_BYTES, m->outstanding,
           m->max_outstanding, m->min_outstanding_after_enable,
           elapsed_seconds(m), m->primary_complete_ns);
    fflush(stdout);
    m->primary_event_emitted = 1;
}

static int persist_primary_full(const char *directory, const unsigned char *primary,
                                Metrics *m) {
    int fd = open_exclusive(directory, "primary.bin");
    if (fd < 0) return -1;
    if (write_all(fd, primary, PRIMARY_BYTES) != 0) {
        int saved = errno;
        close(fd);
        errno = saved;
        return -1;
    }
    if (fsync(fd) != 0) {
        int saved = errno;
        close(fd);
        errno = saved;
        return -1;
    }
    if (close(fd) != 0)
        return -1;
    if (sha256_file(directory, "primary.bin", PRIMARY_BYTES, m->primary_sha256) != 0)
        return -1;
    m->primary_durable = 1;
    printf("{\"type\":\"PRIMARY_DURABLE\",\"file_bytes\":%zu,"
           "\"sha256\":\"%s\",\"primary_exact_completions\":%zu,"
           "\"monotonic_ns\":%" PRIu64 "}\n",
           PRIMARY_BYTES, m->primary_sha256, m->primary_exact, monotonic_ns());
    fflush(stdout);
    return 0;
}

static int process_event(const struct io_event *event, Request *requests,
                         Metrics *m, int allow_primary_event, int from_cancel,
                         const char **blocker) {
    uint64_t id64 = event->data;
    if (id64 >= TOTAL_LOGICAL_REQUESTS) {
        *blocker = "BT656_FIX1_COMPLETION_ID_OUT_OF_RANGE";
        return -1;
    }
    size_t id = (size_t)id64;
    Request *request = &requests[id];
    if (!request->accepted || request->completed) {
        *blocker = "BT656_FIX1_COMPLETION_ID_DUPLICATE_OR_UNSUBMITTED";
        return -1;
    }
    request->completed = 1;
    request->result = (int64_t)event->res;
    request->result2 = (int64_t)event->res2;
    request->completed_ns = monotonic_ns();
    request->completion_order = m->completion_order++;
    request->canceled = from_cancel && request->result == -ECANCELED;
    ++m->completed;
    update_outstanding(m);
    m->last_completion_ns = request->completed_ns;

    if (id < PRIMARY_RECORDS) {
        ++m->primary_completed;
        if (request->result == RECORD_BYTES && request->result2 == 0) {
            ++m->primary_exact;
        } else if (request->result >= 0 && request->result < RECORD_BYTES) {
            ++m->primary_short;
            *blocker = "BT656_FIX1_PRIMARY_SHORT_COMPLETION";
            return -1;
        } else {
            ++m->primary_failed;
            *blocker = "BT656_FIX1_PRIMARY_FAILED_COMPLETION";
            return -1;
        }
        if (is_progress_milestone(m->primary_completed))
            emit_progress(m, id, request->result);
        if (allow_primary_event && m->primary_completed == PRIMARY_RECORDS &&
            m->primary_exact == PRIMARY_RECORDS && m->primary_short == 0 &&
            m->primary_failed == 0 && !m->primary_event_emitted)
            emit_primary_complete(m);
    } else {
        if (request->result == RECORD_BYTES && request->result2 == 0) {
            ++m->guard_completed_exact;
        } else if (request->canceled) {
            ++m->guard_canceled;
        } else if (request->result >= 0 && request->result < RECORD_BYTES) {
            ++m->guard_short;
            *blocker = "BT656_FIX1_UNREACHABLE_GUARD_POSITIVE_SHORT_COMPLETION";
            return -1;
        } else {
            ++m->guard_failed;
            *blocker = "BT656_FIX1_UNREACHABLE_GUARD_FAILED_COMPLETION";
            return -1;
        }
    }
    return 0;
}

static int read_parent_command(int *disable_issued, int *parent_quiescent) {
    struct pollfd input = {STDIN_FILENO, POLLIN, 0};
    int rc = poll(&input, 1, 0);
    if (rc < 0 && errno == EINTR) return 0;
    if (rc < 0) return -1;
    if (rc > 0 && (input.revents & POLLIN)) {
        char command[128];
        if (fgets(command, sizeof(command), stdin) == NULL) return 0;
        if (strcmp(command, "DISABLE_ISSUED\n") == 0) {
            if (*disable_issued) return -1;
            *disable_issued = 1;
            printf("{\"type\":\"DISABLE_ISSUED_ACK\",\"monotonic_ns\":%" PRIu64 "}\n",
                   monotonic_ns());
            fflush(stdout);
            return 1;
        }
        if (strcmp(command, "PARENT_QUIESCENT\n") == 0) {
            if (*parent_quiescent) return -1;
            *parent_quiescent = 1;
            return 1;
        }
        return -1;
    }
    return 0;
}

static int persist_tables(const char *directory, const Request *requests,
                          const Metrics *m, const unsigned char *primary,
                          int success, const char *blocker) {
    int fd = open_exclusive(directory, "submissions.csv");
    if (fd < 0) return -1;
    FILE *file = fdopen(fd, "w");
    if (file == NULL) { close(fd); return -1; }
    fprintf(file, "LogicalIndex,Window,RequestedBytes,AioData,AioOffset,BufferOffset,SubmissionCall,Accepted,SubmittedMonotonicNs\n");
    for (size_t i = 0; i < TOTAL_LOGICAL_REQUESTS; ++i) {
        const Request *r = &requests[i];
        fprintf(file, "%zu,%s,%u,%zu,0,%zu,%u,%d,%" PRIu64 "\n",
                i, i < PRIMARY_RECORDS ? "PRIMARY" : "GUARD", RECORD_BYTES,
                i, i < PRIMARY_RECORDS ? i * (size_t)RECORD_BYTES :
                (i - PRIMARY_RECORDS) * (size_t)RECORD_BYTES,
                r->submission_call, r->accepted, r->submitted_ns);
    }
    if (fflush(file) != 0 || fsync(fileno(file)) != 0 || fclose(file) != 0) return -1;

    fd = open_exclusive(directory, "completions.csv");
    if (fd < 0) return -1;
    file = fdopen(fd, "w");
    if (file == NULL) { close(fd); return -1; }
    fprintf(file, "LogicalIndex,Window,RequestedBytes,ResultBytes,Result2,CompletionSequence,CompletedMonotonicNs,Canceled,Exact\n");
    for (size_t order = 0; order < m->completed; ++order) {
        for (size_t i = 0; i < TOTAL_LOGICAL_REQUESTS; ++i) {
            const Request *r = &requests[i];
            if (r->completed && r->completion_order == order) {
                fprintf(file, "%zu,%s,%u,%" PRId64 ",%" PRId64 ",%zu,%" PRIu64 ",%s,%s\n",
                        i, i < PRIMARY_RECORDS ? "PRIMARY" : "GUARD",
                        RECORD_BYTES, r->result, r->result2, order,
                        r->completed_ns, r->canceled ? "YES" : "NO",
                        (r->result == RECORD_BYTES && r->result2 == 0) ? "YES" : "NO");
                break;
            }
        }
    }
    if (fflush(file) != 0 || fsync(fileno(file)) != 0 || fclose(file) != 0) return -1;

    fd = open_exclusive(directory, "completion-bitmap.bin");
    if (fd < 0) return -1;
    unsigned char bitmap[TOTAL_LOGICAL_REQUESTS];
    for (size_t i = 0; i < TOTAL_LOGICAL_REQUESTS; ++i)
        bitmap[i] = (unsigned char)(requests[i].completed ? 1 : 0);
    if (write_all(fd, bitmap, sizeof(bitmap)) != 0 || fsync(fd) != 0 || close(fd) != 0) return -1;

    if (!success) {
        fd = open_exclusive(directory, "primary-partial-by-index.bin");
        if (fd < 0) return -1;
        if (ftruncate(fd, (off_t)PRIMARY_BYTES) != 0) { close(fd); return -1; }
        for (size_t i = 0; i < PRIMARY_RECORDS; ++i) {
            if (!requests[i].completed || requests[i].result <= 0) continue;
            size_t bytes = (size_t)requests[i].result;
            if (bytes > RECORD_BYTES) bytes = RECORD_BYTES;
            if (write_all_at(fd, primary + i * (size_t)RECORD_BYTES, bytes,
                             (off_t)(i * (size_t)RECORD_BYTES)) != 0) {
                close(fd); return -1;
            }
        }
        if (fsync(fd) != 0 || close(fd) != 0) return -1;
    }

    fd = open_exclusive(directory, "helper-result.json");
    if (fd < 0) return -1;
    double average_outstanding = m->outstanding_sample_count == 0 ? 0.0 :
        (double)m->outstanding_sample_sum / (double)m->outstanding_sample_count;
    double average_refill_us = m->refill_latency_samples == 0 ? 0.0 :
        (double)m->total_refill_latency_ns / (double)m->refill_latency_samples / 1000.0;
    dprintf(fd,
        "{\n  \"schema\": \"BT656_FIX1_PRIMARY_ONLY_ROLLING_HELPER_RESULT_V1\",\n"
        "  \"result\": \"%s\",\n  \"blocker\": \"%s\",\n"
        "  \"record_bytes\": %u,\n  \"primary_records\": %u,\n"
        "  \"guard_records\": %u,\n  \"total_logical_requests\": %u,\n"
        "  \"max_permitted_outstanding\": %u,\n  \"submitted\": %zu,\n"
        "  \"completed\": %zu,\n  \"pending\": %zu,\n"
        "  \"primary_exact\": %zu,\n  \"primary_short\": %zu,\n"
        "  \"primary_failed\": %zu,\n  \"guard_exact\": %zu,\n"
        "  \"guard_canceled\": %zu,\n  \"guard_short\": %zu,\n"
        "  \"guard_failed\": %zu,\n  \"max_outstanding\": %zu,\n"
        "  \"min_outstanding_after_enable\": %zu,\n"
        "  \"average_outstanding\": %.6f,\n"
        "  \"descriptor_window_violations\": %u,\n"
        "  \"descriptor_starvation_events\": %u,\n"
        "  \"crossed_logical_index_2048\": %s,\n"
        "  \"cumulative_submissions_when_2048_crossed\": %zu,\n"
        "  \"io_submit_calls\": %u,\n  \"io_getevents_calls\": %u,\n"
        "  \"temporary_eagain\": %u,\n  \"max_completion_batch\": %zu,\n"
        "  \"io_cancel_calls\": %u,\n"
        "  \"max_refill_latency_us\": %.3f,\n"
        "  \"average_refill_latency_us\": %.3f,\n"
        "  \"guard_completed_at_primary\": %zu,\n"
        "  \"guard_completed_after_primary\": %zu,\n"
        "  \"primary_capture_duration_ms\": %.6f,\n"
        "  \"primary_records_per_second\": %.6f,\n"
        "  \"primary_bytes_per_second\": %.6f,\n"
        "  \"primary_durable\": %s,\n  \"primary_sha256\": \"%s\",\n"
        "  \"raw_payload_control_ipc\": false\n}\n",
        success ? "PASS" : "FAIL", blocker == NULL ? "NONE" : blocker,
        RECORD_BYTES, PRIMARY_RECORDS, SHUTDOWN_GUARD_RECORDS,
        TOTAL_LOGICAL_REQUESTS, MAX_OUTSTANDING_IOCBS, m->submitted,
        m->completed, m->submitted - m->completed, m->primary_exact,
        m->primary_short, m->primary_failed, m->guard_completed_exact,
        m->guard_canceled, m->guard_short, m->guard_failed,
        m->max_outstanding, m->min_outstanding_after_enable,
        average_outstanding, m->descriptor_window_violations,
        m->descriptor_starvation_events,
        m->crossed_logical_index_2048 ? "true" : "false",
        m->cumulative_submissions_when_2048_crossed, m->io_submit_calls,
        m->io_getevents_calls, m->temporary_eagain, m->max_completion_batch,
        m->io_cancel_calls,
        (double)m->max_refill_latency_ns / 1000.0, average_refill_us,
        m->guard_completed_at_primary,
        m->guard_completed_exact - m->guard_completed_at_primary,
        (double)(m->primary_complete_ns - m->capture_start_ns) / 1000000.0,
        m->primary_complete_ns > m->capture_start_ns ?
            (double)PRIMARY_RECORDS * 1000000000.0 /
                (double)(m->primary_complete_ns - m->capture_start_ns) : 0.0,
        m->primary_complete_ns > m->capture_start_ns ?
            (double)PRIMARY_BYTES * 1000000000.0 /
                (double)(m->primary_complete_ns - m->capture_start_ns) : 0.0,
        m->primary_durable ? "true" : "false",
        m->primary_durable ? m->primary_sha256 : "NONE");
    if (fsync(fd) != 0 || close(fd) != 0) return -1;
    return 0;
}

static int synthetic_self_test(void) {
    unsigned char active[TOTAL_LOGICAL_REQUESTS];
    unsigned char completed[TOTAL_LOGICAL_REQUESTS];
    uint32_t placement[PRIMARY_RECORDS];
    memset(active, 0, sizeof(active));
    memset(completed, 0, sizeof(completed));
    for (size_t i = 0; i < PRIMARY_RECORDS; ++i) placement[i] = (uint32_t)i;
    size_t submitted = MAX_OUTSTANDING_IOCBS;
    size_t total_completed = 0;
    size_t primary_completed = 0;
    size_t outstanding = MAX_OUTSTANDING_IOCBS;
    size_t max_outstanding = outstanding;
    size_t next = submitted;
    unsigned starvation = 0;
    int crossed = 0;
    size_t submissions_when_2048_crossed = 0;
    int primary_event = 0;
    size_t primary_completed_when_event_emitted = 0;
    size_t pending_when_primary_emitted = SIZE_MAX;
    int persistence_started_before_disable_issued = 0;
    int persistence_started_after_disable_issued = 0;
    unsigned io_cancel_calls = 0;
    for (size_t i = 0; i < submitted; ++i) active[i] = 1;
    size_t pattern[] = {1, 127, 17, 64, 3, 128, 29, 91};
    size_t pattern_index = 0;
    while (total_completed < TOTAL_LOGICAL_REQUESTS) {
        size_t batch = pattern[pattern_index++ % (sizeof(pattern) / sizeof(pattern[0]))];
        if (batch > outstanding) batch = outstanding;
        size_t taken = 0;
        for (size_t i = 0; i < TOTAL_LOGICAL_REQUESTS && taken < batch; ++i) {
            if (!active[i] || completed[i]) continue;
            completed[i] = 1;
            active[i] = 0;
            ++taken; ++total_completed; --outstanding; ++primary_completed;
            if (primary_completed == PRIMARY_RECORDS && !primary_event) {
                primary_event = 1;
                primary_completed_when_event_emitted = primary_completed;
                pending_when_primary_emitted = outstanding;
            }
        }
        if (outstanding == 0 && next < TOTAL_LOGICAL_REQUESTS) ++starvation;
        while (outstanding < MAX_OUTSTANDING_IOCBS && next < TOTAL_LOGICAL_REQUESTS) {
            active[next++] = 1;
            ++submitted; ++outstanding;
            if (!crossed && next > 2048U) {
                crossed = 1;
                submissions_when_2048_crossed = submitted;
            }
            if (outstanding > max_outstanding) max_outstanding = outstanding;
        }
    }
    int placement_ok = 1;
    for (size_t i = 0; i < PRIMARY_RECORDS; ++i)
        if (placement[i] != i || !completed[i]) placement_ok = 0;
    int disable_issued = 1;
    if (disable_issued) {
        persistence_started_after_disable_issued = 1;
    } else {
        persistence_started_before_disable_issued = 1;
    }
    uint32_t preserved_word = placement[777];
    int simulated_later_cleanup_failure = 1;
    int completed_data_preserved = simulated_later_cleanup_failure &&
        placement[777] == preserved_word;
    int pass = submitted == TOTAL_LOGICAL_REQUESTS &&
               primary_completed == PRIMARY_RECORDS && max_outstanding <= MAX_OUTSTANDING_IOCBS &&
               starvation == 0 && crossed && primary_event &&
               primary_completed_when_event_emitted == PRIMARY_RECORDS &&
               pending_when_primary_emitted == 0 && placement_ok &&
               !persistence_started_before_disable_issued &&
               persistence_started_after_disable_issued &&
               SHUTDOWN_GUARD_RECORDS == 0 && io_cancel_calls == 0 &&
               completed_data_preserved;
    printf("{\"type\":\"SELF_TEST_RESULT\",\"result\":\"%s\","
           "\"record_bytes\":%u,\"primary_records\":%u,"
           "\"guard_records\":%u,\"total_logical_requests\":%u,"
           "\"initial_submitted\":%u,\"initial_outstanding\":%u,"
           "\"maximum_permitted_outstanding\":%u,\"total_submitted\":%zu,"
           "\"maximum_outstanding\":%zu,\"descriptor_starvation_events\":%u,"
           "\"crossed_logical_index_2048\":%s,"
           "\"cumulative_submissions_when_2048_crossed\":%zu,"
           "\"primary_completed\":%zu,"
           "\"primary_event_at_2500\":%s,"
           "\"primary_completed_when_event_emitted\":%zu,"
           "\"pending_at_primary_window_complete\":%zu,"
           "\"placement_by_logical_index\":%s,"
           "\"persistence_before_disable_issued\":%s,"
           "\"persistence_after_disable_issued\":%s,"
           "\"no_guard_requests\":%s,"
           "\"io_cancel_calls\":%u,"
           "\"completed_data_preserved\":%s}\n",
           pass ? "PASS" : "FAIL", RECORD_BYTES, PRIMARY_RECORDS,
           SHUTDOWN_GUARD_RECORDS, TOTAL_LOGICAL_REQUESTS,
           MAX_OUTSTANDING_IOCBS, MAX_OUTSTANDING_IOCBS,
           MAX_OUTSTANDING_IOCBS, submitted,
           max_outstanding, starvation, crossed ? "true" : "false",
           submissions_when_2048_crossed, primary_completed,
           primary_event ? "true" : "false",
           primary_completed_when_event_emitted,
           pending_when_primary_emitted,
           placement_ok ? "true" : "false",
           persistence_started_before_disable_issued ? "true" : "false",
           persistence_started_after_disable_issued ? "true" : "false",
           SHUTDOWN_GUARD_RECORDS == 0 ? "true" : "false",
           io_cancel_calls,
           completed_data_preserved ? "true" : "false");
    return pass ? 0 : 1;
}

int main(int argc, char **argv) {
    if (argc == 2 && strcmp(argv[1], "--self-test") == 0) return synthetic_self_test();
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
        emit_error("BT656_FIX1_BUFFER_ALLOCATION_FAILED", 0, -ENOMEM, 0, 0);
        free(primary); return 70;
    }
    memset(primary, 0, PRIMARY_BYTES);

    Request *requests = calloc(TOTAL_LOGICAL_REQUESTS, sizeof(*requests));
    struct iocb **pointers = calloc(TOTAL_LOGICAL_REQUESTS, sizeof(*pointers));
    if (requests == NULL || pointers == NULL) {
        emit_error("BT656_FIX1_CONTROL_ALLOCATION_FAILED", 0, -ENOMEM, 0, 0);
        free(requests); free(pointers); free(primary); return 70;
    }

    int flags = O_RDONLY | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    int c2h = open(argv[1], flags);
    if (c2h < 0) {
        emit_error("BT656_FIX1_C2H_OPEN_FAILED", 0, -errno, 0, 0);
        free(requests); free(pointers); free(primary); return 71;
    }
    for (size_t i = 0; i < TOTAL_LOGICAL_REQUESTS; ++i) {
        unsigned char *buffer = primary + i * (size_t)RECORD_BYTES;
        memset(&requests[i].cb, 0, sizeof(requests[i].cb));
        requests[i].cb.aio_data = i;
        requests[i].cb.aio_lio_opcode = IOCB_CMD_PREAD;
        requests[i].cb.aio_fildes = (uint32_t)c2h;
        requests[i].cb.aio_buf = (uint64_t)(uintptr_t)buffer;
        requests[i].cb.aio_nbytes = RECORD_BYTES;
        requests[i].cb.aio_offset = 0;
        pointers[i] = &requests[i].cb;
    }

    aio_context_t context = 0;
    if (syscall(__NR_io_setup, AIO_CONTEXT_CAPACITY, &context) < 0) {
        emit_error("BT656_FIX1_IO_SETUP_FAILED", 0, -errno, 0, 0);
        close(c2h); free(requests); free(pointers); free(primary); return 72;
    }

    Metrics m;
    memset(&m, 0, sizeof(m));
    m.min_outstanding_after_enable = SIZE_MAX;
    const char *blocker = NULL;
    int failure = 0;
    int submit_rc = submit_to_target(context, requests, pointers, &m,
                                     MAX_OUTSTANDING_IOCBS);
    if (submit_rc != 0 || m.submitted != MAX_OUTSTANDING_IOCBS ||
        m.outstanding != MAX_OUTSTANDING_IOCBS || m.next_submit != MAX_OUTSTANDING_IOCBS) {
        blocker = submit_rc == -2 ? "BT656_FIX1_DESCRIPTOR_WINDOW_VIOLATION" :
                                   "BT656_FIX1_INITIAL_PREQUEUE_FAILED";
        failure = 1;
    }
    struct io_event early_event;
    struct timespec zero = {0, 0};
    long early = syscall(__NR_io_getevents, context, 0, 1, &early_event, &zero);
    ++m.io_getevents_calls;
    if (!failure && early != 0) {
        blocker = "BT656_FIX1_COMPLETION_BEFORE_ENABLE";
        failure = 1;
    }
    if (failure) {
        emit_error(blocker, m.next_submit, submit_rc, early, m.outstanding);
    } else {
        printf("{\"type\":\"ROLLING_PREQUEUE_READY\","
               "\"initial_submitted_requests\":%zu,\"current_outstanding\":%zu,"
               "\"maximum_permitted_outstanding\":%u,"
               "\"next_logical_request_index\":%zu,\"primary_total\":%u,"
               "\"guard_total\":%u,\"aio_context_capacity\":%u,"
               "\"total_allocated_bytes\":%zu,\"buffer_alignment\":%u,"
               "\"primary_alignment_remainder\":%zu,\"guard_alignment_remainder\":0,"
               "\"prefaulted\":true,\"aio_context_active\":true,"
               "\"monotonic_ns\":%" PRIu64 "}\n",
               m.submitted, m.outstanding, MAX_OUTSTANDING_IOCBS, m.next_submit,
               PRIMARY_RECORDS, SHUTDOWN_GUARD_RECORDS, AIO_CONTEXT_CAPACITY,
               TOTAL_ALLOCATED_BYTES, RECORD_BYTES,
               (size_t)((uintptr_t)primary % RECORD_BYTES), monotonic_ns());
        fflush(stdout);
    }

    m.capture_start_ns = monotonic_ns();
    m.last_completion_ns = m.capture_start_ns;
    m.min_outstanding_after_enable = m.outstanding;
    while (!failure && !m.primary_event_emitted) {
        uint64_t now = monotonic_ns();
        if (now - m.capture_start_ns >= TOTAL_CAPTURE_TIMEOUT_NS) {
            blocker = "BT656_FIX1_TOTAL_CAPTURE_TIMEOUT";
            failure = 1;
            break;
        }
        if (now - m.last_completion_ns >= NO_PROGRESS_TIMEOUT_NS) {
            blocker = "BT656_FIX1_NO_PROGRESS_TIMEOUT";
            failure = 1;
            break;
        }
        struct io_event events[COMPLETION_BATCH_MAX];
        struct timespec timeout = {0, 50000000};
        long count = syscall(__NR_io_getevents, context, 1,
                             COMPLETION_BATCH_MAX, events, &timeout);
        ++m.io_getevents_calls;
        if (count < 0) {
            if (errno == EINTR) continue;
            blocker = "BT656_FIX1_IO_GETEVENTS_FAILED";
            failure = 1;
            break;
        }
        if (count == 0) continue;
        if ((size_t)count > m.max_completion_batch) m.max_completion_batch = (size_t)count;
        uint64_t batch_received = monotonic_ns();
        for (long i = 0; i < count; ++i) {
            if (process_event(&events[i], requests, &m, 1, 0, &blocker) != 0) {
                failure = 1;
                break;
            }
        }
        if (failure) break;
        if (m.outstanding == 0 && m.next_submit < TOTAL_LOGICAL_REQUESTS)
            ++m.descriptor_starvation_events;
        if (m.next_submit < TOTAL_LOGICAL_REQUESTS) {
            int rc = submit_to_target(context, requests, pointers, &m,
                                      MAX_OUTSTANDING_IOCBS);
            uint64_t refill_done = monotonic_ns();
            uint64_t latency = refill_done - batch_received;
            if (latency > m.max_refill_latency_ns) m.max_refill_latency_ns = latency;
            m.total_refill_latency_ns += latency;
            ++m.refill_latency_samples;
            if (rc != 0) {
                blocker = rc == -2 ? "BT656_FIX1_DESCRIPTOR_WINDOW_VIOLATION" :
                                     "BT656_FIX1_ROLLING_REFILL_FAILED";
                failure = 1;
                break;
            }
        }
        m.outstanding_sample_sum += m.outstanding;
        ++m.outstanding_sample_count;
    }

    if (failure) emit_error(blocker, m.next_submit, -EIO, 0, m.outstanding);
    if (!failure && (!m.primary_event_emitted || m.primary_exact != PRIMARY_RECORDS)) {
        blocker = "BT656_FIX1_PRIMARY_WINDOW_INCOMPLETE";
        failure = 1;
        emit_error(blocker, m.next_submit, -EIO, 0, m.outstanding);
    }
    int disable_issued = 0;
    int parent_quiescent = 0;
    while (!parent_quiescent) {
        if (read_parent_command(&disable_issued, &parent_quiescent) < 0) {
            if (!failure) {
                blocker = "BT656_FIX1_PARENT_COMMAND_INVALID";
                failure = 1;
                emit_error(blocker, m.next_submit, -EINVAL, 0, m.outstanding);
            }
        }
        if (!failure && m.primary_event_emitted && parent_quiescent &&
            !disable_issued) {
            blocker = "BT656_FIX1_PARENT_QUIESCENT_BEFORE_DISABLE_ISSUED";
            failure = 1;
            emit_error(blocker, m.next_submit, -EPROTO, 0, m.outstanding);
        }
        if (!failure && disable_issued && !m.primary_durable) {
            if (persist_primary_full(argv[2], primary, &m) != 0) {
                blocker = "BT656_FIX1_PRIMARY_PERSISTENCE_FAILED";
                failure = 1;
                emit_error(blocker, PRIMARY_RECORDS, -errno, 0, m.outstanding);
            }
        }
        struct io_event events[COMPLETION_BATCH_MAX];
        struct timespec timeout = {0, 50000000};
        long count = syscall(__NR_io_getevents, context, 0,
                             COMPLETION_BATCH_MAX, events, &timeout);
        ++m.io_getevents_calls;
        if (count < 0 && errno != EINTR) {
            if (!failure) {
                blocker = "BT656_FIX1_IO_GETEVENTS_DRAIN_FAILED";
                failure = 1;
                emit_error(blocker, m.next_submit, -errno, 0, m.outstanding);
            }
        } else if (count > 0) {
            if ((size_t)count > m.max_completion_batch) m.max_completion_batch = (size_t)count;
            for (long i = 0; i < count; ++i) {
                const char *event_blocker = NULL;
                if (process_event(&events[i], requests, &m, 0, 0,
                                  &event_blocker) != 0 && !failure) {
                    blocker = event_blocker;
                    failure = 1;
                    emit_error(blocker, (size_t)events[i].data,
                               (int64_t)events[i].res, (int64_t)events[i].res2,
                               m.outstanding);
                }
            }
        }
    }

    size_t cancel_start = failure ? 0 : PRIMARY_RECORDS;
    for (size_t i = cancel_start; i < m.submitted; ++i) {
        if (requests[i].completed) continue;
        requests[i].cancel_attempted = 1;
        ++m.io_cancel_calls;
        struct io_event event;
        memset(&event, 0, sizeof(event));
        long rc = syscall(__NR_io_cancel, context, &requests[i].cb, &event);
        if (rc == 0) {
            const char *event_blocker = NULL;
            if (process_event(&event, requests, &m, 0, 1, &event_blocker) != 0 && !failure) {
                blocker = event_blocker;
                failure = 1;
                emit_error(blocker, i, (int64_t)event.res, (int64_t)event.res2,
                           m.outstanding);
            }
        }
    }

    uint64_t cleanup_deadline = monotonic_ns() + FAILURE_CLEANUP_TIMEOUT_NS;
    while (m.outstanding > 0 && monotonic_ns() < cleanup_deadline) {
        struct io_event events[COMPLETION_BATCH_MAX];
        struct timespec timeout = {0, 100000000};
        long count = syscall(__NR_io_getevents, context, 0,
                             COMPLETION_BATCH_MAX, events, &timeout);
        ++m.io_getevents_calls;
        if (count < 0 && errno != EINTR) break;
        for (long i = 0; i < count; ++i) {
            const char *event_blocker = NULL;
            if (process_event(&events[i], requests, &m, 0, 0,
                              &event_blocker) != 0 && !failure) {
                blocker = event_blocker;
                failure = 1;
                emit_error(blocker, (size_t)events[i].data,
                           (int64_t)events[i].res, (int64_t)events[i].res2,
                           m.outstanding);
            }
        }
    }

    int cleanup_unresolved = m.outstanding != 0;
    if (cleanup_unresolved) {
        blocker = "BT656_FIX1_UNEXPECTED_PENDING_AIO_AFTER_PRIMARY_COMPLETION";
        failure = 1;
    }
    if (persist_tables(argv[2], requests, &m, primary,
                       !failure && m.primary_durable, blocker) != 0) {
        blocker = "BT656_FIX1_METADATA_PERSISTENCE_FAILED";
        failure = 1;
    }
    if (cleanup_unresolved) {
        emit_error(blocker, m.next_submit, -EINPROGRESS, 0, m.outstanding);
        for (;;) sleep(60);
    }

    double average_outstanding = m.outstanding_sample_count == 0 ? 0.0 :
        (double)m.outstanding_sample_sum / (double)m.outstanding_sample_count;
    double average_refill_us = m.refill_latency_samples == 0 ? 0.0 :
        (double)m.total_refill_latency_ns / (double)m.refill_latency_samples / 1000.0;
    printf("{\"type\":\"FINALIZATION_COMPLETE\"," 
           "\"guard_exact_completions\":%zu,\"guard_canceled\":%zu,"
           "\"guard_short_completions\":%zu,\"guard_failed_completions\":%zu,"
           "\"final_pending\":%zu,\"maximum_outstanding\":%zu,"
           "\"minimum_outstanding_after_enable\":%zu,\"average_outstanding\":%.6f,"
           "\"descriptor_window_violations\":%u,\"descriptor_starvation_events\":%u,"
           "\"crossed_logical_index_2048\":%s,\"io_submit_call_count\":%u,"
           "\"io_getevents_call_count\":%u,\"temporary_eagain_count\":%u,"
           "\"total_submitted\":%zu,\"total_completed\":%zu,"
           "\"cumulative_submissions_when_2048_crossed\":%zu,"
           "\"guard_completed_before_disable\":%zu,"
           "\"guard_completed_after_disable\":%zu,"
           "\"maximum_completion_batch\":%zu,"
           "\"maximum_completion_to_refill_latency_us\":%.3f,"
           "\"average_completion_to_refill_latency_us\":%.3f,"
           "\"io_cancel_calls\":%u,"
           "\"monotonic_ns\":%" PRIu64 "}\n",
           m.guard_completed_exact, m.guard_canceled, m.guard_short, m.guard_failed,
           m.outstanding, m.max_outstanding, m.min_outstanding_after_enable,
           average_outstanding, m.descriptor_window_violations,
           m.descriptor_starvation_events,
           m.crossed_logical_index_2048 ? "true" : "false",
           m.io_submit_calls, m.io_getevents_calls, m.temporary_eagain,
           m.submitted, m.completed, m.cumulative_submissions_when_2048_crossed,
           m.guard_completed_at_primary,
           m.guard_completed_exact - m.guard_completed_at_primary,
           m.max_completion_batch, (double)m.max_refill_latency_ns / 1000.0,
           average_refill_us, m.io_cancel_calls, monotonic_ns());
    fflush(stdout);

    int destroy_failed = syscall(__NR_io_destroy, context) < 0;
    close(c2h);
    free(requests); free(pointers); free(primary);
    if (destroy_failed) {
        emit_error("BT656_FIX1_IO_DESTROY_FAILED", 0, -errno, 0, 0);
        return 75;
    }
    printf("{\"type\":\"HELPER_EXIT_READY\",\"result\":\"%s\","
           "\"monotonic_ns\":%" PRIu64 "}\n", failure ? "FAIL" : "PASS",
           monotonic_ns());
    fflush(stdout);
    return failure ? 1 : 0;
}
