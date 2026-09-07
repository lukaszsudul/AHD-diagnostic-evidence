#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/aio_abi.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

#define PRIMARY_BYTES 10240000UL
#define GUARD_BYTES 4194304UL
#define RECORD_BYTES 4096UL
#define BUFFER_ALIGNMENT 4096UL
#define PRIMARY_REQUEST_ID 1ULL
#define GUARD_REQUEST_ID 2ULL

static long raw_io_setup(unsigned int nr_events, aio_context_t *context) {
    return syscall(__NR_io_setup, nr_events, context);
}

static long raw_io_submit(aio_context_t context, long nr,
                          struct iocb **requests) {
    return syscall(__NR_io_submit, context, nr, requests);
}

static long raw_io_getevents(aio_context_t context, long minimum, long maximum,
                             struct io_event *events,
                             struct timespec *timeout) {
    return syscall(__NR_io_getevents, context, minimum, maximum, events,
                   timeout);
}

static long raw_io_destroy(aio_context_t context) {
    return syscall(__NR_io_destroy, context);
}

static uint64_t monotonic_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        return 0;
    }
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static uint64_t realtime_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) != 0) {
        return 0;
    }
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static void prefault_buffer(void *buffer, size_t size) {
    volatile unsigned char *bytes = (volatile unsigned char *)buffer;
    size_t offset;
    for (offset = 0; offset < size; offset += 4096UL) {
        bytes[offset] = 0;
    }
    if (size != 0) {
        bytes[size - 1] = 0;
    }
}

static int write_all(int fd, const unsigned char *data, size_t size) {
    size_t written = 0;
    while (written < size) {
        ssize_t result = write(fd, data + written, size - written);
        if (result < 0 && errno == EINTR) {
            continue;
        }
        if (result <= 0) {
            return -1;
        }
        written += (size_t)result;
    }
    return 0;
}

static int persist_exclusive(const char *path, const void *data, size_t size) {
    int flags = O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    int fd = open(path, flags, S_IRUSR | S_IWUSR);
    if (fd < 0) {
        return -1;
    }
    int result = 0;
    if (write_all(fd, (const unsigned char *)data, size) != 0 ||
        fsync(fd) != 0) {
        result = -1;
    }
    if (close(fd) != 0) {
        result = -1;
    }
    return result;
}

static int path_join(char *destination, size_t capacity, const char *directory,
                     const char *name) {
    int count = snprintf(destination, capacity, "%s/%s", directory, name);
    return count > 0 && (size_t)count < capacity ? 0 : -1;
}

static int persist_metadata(const char *path, int64_t primary_result,
                            int64_t guard_result, uint64_t prequeue_ns,
                            uint64_t primary_completion_ns,
                            uint64_t guard_completion_ns,
                            uint64_t persistence_ns) {
    int flags = O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    int fd = open(path, flags, S_IRUSR | S_IWUSR);
    if (fd < 0) {
        return -1;
    }
    char buffer[2048];
    int count = snprintf(
        buffer, sizeof(buffer),
        "{\n"
        "  \"schema\": \"R3R4R6_NATIVE_AIO_COMPLETIONS_V1\",\n"
        "  \"primary_request_id\": 1,\n"
        "  \"guard_request_id\": 2,\n"
        "  \"primary_requested_bytes\": %lu,\n"
        "  \"guard_requested_bytes\": %lu,\n"
        "  \"primary_result_bytes\": %" PRId64 ",\n"
        "  \"guard_result\": %" PRId64 ",\n"
        "  \"prequeue_ready_monotonic_ns\": %" PRIu64 ",\n"
        "  \"primary_completion_monotonic_ns\": %" PRIu64 ",\n"
        "  \"guard_completion_monotonic_ns\": %" PRIu64 ",\n"
        "  \"persistence_complete_monotonic_ns\": %" PRIu64 ",\n"
        "  \"raw_payload_in_metadata\": false\n"
        "}\n",
        PRIMARY_BYTES, GUARD_BYTES, primary_result, guard_result, prequeue_ns,
        primary_completion_ns, guard_completion_ns, persistence_ns);
    int result = 0;
    if (count <= 0 || (size_t)count >= sizeof(buffer) ||
        write_all(fd, (const unsigned char *)buffer, (size_t)count) != 0 ||
        fsync(fd) != 0) {
        result = -1;
    }
    if (close(fd) != 0) {
        result = -1;
    }
    return result;
}

static void emit_error(const char *blocker, int error_number) {
    printf("{\"type\":\"ERROR\",\"blocker\":\"%s\","
           "\"errno\":%d,\"monotonic_ns\":%" PRIu64 "}\n",
           blocker, error_number, monotonic_ns());
    fflush(stdout);
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s C2H_NODE PRIVATE_DIRECTORY\n", argv[0]);
        return 64;
    }
    setvbuf(stdout, NULL, _IOLBF, 0);

    const char *c2h_path = argv[1];
    const char *private_directory = argv[2];
    void *primary_buffer = NULL;
    void *guard_buffer = NULL;
    aio_context_t context = 0;
    int c2h_fd = -1;
    int exit_code = 1;
    bool context_active = false;
    bool primary_done = false;
    bool guard_done = false;
    int64_t primary_result = INT64_MIN;
    int64_t guard_result = INT64_MIN;
    uint64_t primary_completion_ns = 0;
    uint64_t guard_completion_ns = 0;
    uint64_t prequeue_ns = 0;

    if (posix_memalign(&primary_buffer, BUFFER_ALIGNMENT, PRIMARY_BYTES) != 0 ||
        posix_memalign(&guard_buffer, BUFFER_ALIGNMENT, GUARD_BYTES) != 0) {
        emit_error("R3R4R6_ALIGNED_BUFFER_ALLOCATION_FAILED", errno);
        goto cleanup;
    }
    prefault_buffer(primary_buffer, PRIMARY_BYTES);
    prefault_buffer(guard_buffer, GUARD_BYTES);

    int open_flags = O_RDONLY | O_CLOEXEC;
#ifdef O_NOFOLLOW
    open_flags |= O_NOFOLLOW;
#endif
    c2h_fd = open(c2h_path, open_flags);
    if (c2h_fd < 0) {
        emit_error("R3R4R6_C2H_OPEN_FAILED", errno);
        goto cleanup;
    }
    if (raw_io_setup(4, &context) != 0) {
        emit_error("R3R4R6_IO_SETUP_FAILED", errno);
        goto cleanup;
    }
    context_active = true;

    struct iocb primary_request;
    struct iocb guard_request;
    memset(&primary_request, 0, sizeof(primary_request));
    memset(&guard_request, 0, sizeof(guard_request));
    primary_request.aio_data = PRIMARY_REQUEST_ID;
    primary_request.aio_lio_opcode = IOCB_CMD_PREAD;
    primary_request.aio_fildes = (uint32_t)c2h_fd;
    primary_request.aio_buf = (uint64_t)(uintptr_t)primary_buffer;
    primary_request.aio_nbytes = PRIMARY_BYTES;
    primary_request.aio_offset = 0;
    guard_request.aio_data = GUARD_REQUEST_ID;
    guard_request.aio_lio_opcode = IOCB_CMD_PREAD;
    guard_request.aio_fildes = (uint32_t)c2h_fd;
    guard_request.aio_buf = (uint64_t)(uintptr_t)guard_buffer;
    guard_request.aio_nbytes = GUARD_BYTES;
    guard_request.aio_offset = 0;

    struct iocb *submission[1];
    submission[0] = &primary_request;
    long primary_submit = raw_io_submit(context, 1, submission);
    if (primary_submit != 1) {
        emit_error("R3R4R6_PRIMARY_IO_SUBMIT_FAILED", errno);
        goto cleanup;
    }
    submission[0] = &guard_request;
    long guard_submit = raw_io_submit(context, 1, submission);
    if (guard_submit != 1) {
        emit_error("R3R4R6_GUARD_IO_SUBMIT_FAILED", errno);
        goto cleanup;
    }

    prequeue_ns = monotonic_ns();
    printf("{\"type\":\"PREQUEUE_READY\",\"primary_request_id\":1,"
           "\"guard_request_id\":2,\"primary_bytes\":%lu,"
           "\"guard_bytes\":%lu,\"total_bytes\":%lu,"
           "\"buffer_alignment\":%lu,\"primary_buffer_mod_alignment\":%lu,"
           "\"guard_buffer_mod_alignment\":%lu,"
           "\"primary_submit_result\":%ld,\"guard_submit_result\":%ld,"
           "\"buffers_prefaulted\":true,\"aio_context_active\":true,"
           "\"monotonic_ns\":%" PRIu64 ",\"realtime_ns\":%" PRIu64 "}\n",
           PRIMARY_BYTES, GUARD_BYTES, PRIMARY_BYTES + GUARD_BYTES,
           BUFFER_ALIGNMENT,
           (unsigned long)((uintptr_t)primary_buffer % BUFFER_ALIGNMENT),
           (unsigned long)((uintptr_t)guard_buffer % BUFFER_ALIGNMENT),
           primary_submit, guard_submit, prequeue_ns, realtime_ns());

    while (!primary_done || !guard_done) {
        struct io_event events[2];
        struct timespec timeout = {.tv_sec = 1, .tv_nsec = 0};
        long count = raw_io_getevents(context, 1, 2, events, &timeout);
        if (count < 0) {
            if (errno == EINTR) {
                continue;
            }
            emit_error("R3R4R6_IO_GETEVENTS_FAILED", errno);
            goto cleanup;
        }
        for (long index = 0; index < count; ++index) {
            uint64_t request_id = events[index].data;
            int64_t result = (int64_t)events[index].res;
            int64_t result2 = (int64_t)events[index].res2;
            uint64_t completion_ns = monotonic_ns();
            if (request_id == PRIMARY_REQUEST_ID && !primary_done) {
                primary_done = true;
                primary_result = result;
                primary_completion_ns = completion_ns;
                printf("{\"type\":\"PRIMARY_BUFFER_COMPLETE\","
                       "\"request_id\":1,\"result_bytes\":%" PRId64 ","
                       "\"result2\":%" PRId64 ",\"monotonic_ns\":%" PRIu64
                       "}\n",
                       result, result2, completion_ns);
            } else if (request_id == GUARD_REQUEST_ID && !guard_done) {
                guard_done = true;
                guard_result = result;
                guard_completion_ns = completion_ns;
                printf("{\"type\":\"GUARD_AIO_COMPLETE\","
                       "\"request_id\":2,\"result\":%" PRId64 ","
                       "\"result2\":%" PRId64 ",\"monotonic_ns\":%" PRIu64
                       "}\n",
                       result, result2, completion_ns);
            } else {
                emit_error("R3R4R6_UNEXPECTED_AIO_COMPLETION", 0);
                goto cleanup;
            }
        }
    }

    printf("{\"type\":\"AIO_COMPLETIONS_READY\","
           "\"primary_result_bytes\":%" PRId64 ","
           "\"guard_result\":%" PRId64 ",\"monotonic_ns\":%" PRIu64
           "}\n",
           primary_result, guard_result, monotonic_ns());

    char command[128];
    if (fgets(command, sizeof(command), stdin) == NULL ||
        strcmp(command, "PARENT_QUIESCENT\n") != 0) {
        emit_error("R3R4R6_PARENT_QUIESCENT_COMMAND_MISSING", 0);
        goto cleanup;
    }

    if (raw_io_destroy(context) != 0) {
        emit_error("R3R4R6_IO_DESTROY_FAILED", errno);
        goto cleanup;
    }
    context_active = false;
    if (close(c2h_fd) != 0) {
        c2h_fd = -1;
        emit_error("R3R4R6_C2H_CLOSE_FAILED", errno);
        goto cleanup;
    }
    c2h_fd = -1;

    size_t primary_returned = primary_result > 0 ? (size_t)primary_result : 0;
    size_t guard_returned = guard_result > 0 ? (size_t)guard_result : 0;
    if (primary_returned > PRIMARY_BYTES || guard_returned > GUARD_BYTES) {
        emit_error("R3R4R6_AIO_RESULT_EXCEEDS_BUFFER", 0);
        goto cleanup;
    }
    size_t guard_full_bytes = guard_returned - (guard_returned % RECORD_BYTES);
    size_t guard_partial_bytes = guard_returned % RECORD_BYTES;

    char primary_path[4096];
    char guard_path[4096];
    char guard_records_path[4096];
    char guard_partial_path[4096];
    char metadata_path[4096];
    if (path_join(primary_path, sizeof(primary_path), private_directory,
                  "primary-buffer.bin") != 0 ||
        path_join(guard_path, sizeof(guard_path), private_directory,
                  "guard-returned.bin") != 0 ||
        path_join(guard_records_path, sizeof(guard_records_path),
                  private_directory, "guard-records.bin") != 0 ||
        path_join(guard_partial_path, sizeof(guard_partial_path),
                  private_directory, "guard-partial.bin") != 0 ||
        path_join(metadata_path, sizeof(metadata_path), private_directory,
                  "aio-completions-native.json") != 0) {
        emit_error("R3R4R6_PRIVATE_PATH_TOO_LONG", 0);
        goto cleanup;
    }

    if (persist_exclusive(primary_path, primary_buffer, primary_returned) != 0 ||
        persist_exclusive(guard_path, guard_buffer, guard_returned) != 0 ||
        persist_exclusive(guard_records_path, guard_buffer,
                          guard_full_bytes) != 0 ||
        persist_exclusive(guard_partial_path,
                          (const unsigned char *)guard_buffer + guard_full_bytes,
                          guard_partial_bytes) != 0) {
        emit_error("R3R4R6_PRIVATE_CAPTURE_PERSISTENCE_FAILED", errno);
        goto cleanup;
    }
    uint64_t persistence_ns = monotonic_ns();
    if (persist_metadata(metadata_path, primary_result, guard_result,
                         prequeue_ns, primary_completion_ns,
                         guard_completion_ns, persistence_ns) != 0) {
        emit_error("R3R4R6_NATIVE_METADATA_PERSISTENCE_FAILED", errno);
        goto cleanup;
    }

    printf("{\"type\":\"PERSISTENCE_COMPLETE\","
           "\"primary_persisted_bytes\":%zu,"
           "\"guard_returned_bytes\":%zu,\"guard_full_bytes\":%zu,"
           "\"guard_partial_bytes\":%zu,\"monotonic_ns\":%" PRIu64
           "}\n",
           primary_returned, guard_returned, guard_full_bytes,
           guard_partial_bytes, persistence_ns);

    if (primary_result != (int64_t)PRIMARY_BYTES) {
        emit_error("PRIMARY_AIO_FINITE_BUFFER_NOT_FILLED", 0);
        exit_code = 3;
    } else if (guard_result < 0 && guard_result != -(int64_t)ETIMEDOUT) {
        emit_error("R3R4R6_GUARD_AIO_COMPLETION_FAILED", 0);
        exit_code = 4;
    } else {
        printf("{\"type\":\"NATIVE_HELPER_COMPLETE\",\"result\":\"PASS\","
               "\"monotonic_ns\":%" PRIu64 "}\n",
               monotonic_ns());
        exit_code = 0;
    }

cleanup:
    if (context_active) {
        (void)raw_io_destroy(context);
    }
    if (c2h_fd >= 0) {
        (void)close(c2h_fd);
    }
    free(primary_buffer);
    free(guard_buffer);
    return exit_code;
}
