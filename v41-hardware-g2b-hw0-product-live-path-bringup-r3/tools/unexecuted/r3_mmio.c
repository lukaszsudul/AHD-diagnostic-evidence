#define _POSIX_C_SOURCE 200809L

/*
 * AHD v41 G2B-HW0-PRODUCT-R3 fail-closed MMIO accessor.
 *
 * This task-local program deliberately provides no mmap path, no PCI access,
 * and no generic write primitive. Each invocation performs exactly one
 * aligned four-byte pread/pwrite through a proven /dev/xdmaN_user node and
 * appends one durable audit row. R3 node-to-BDF proof remains an external
 * prerequisite; --bdf records the already-proven identity on every access.
 */

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#ifndef O_CLOEXEC
#define O_CLOEXEC 0
#endif
#ifndef O_NOFOLLOW
#define O_NOFOLLOW 0
#endif

enum operation_kind {
  OP_READ,
  OP_WRITE
};

static void usage(const char *program) {
  fprintf(stderr,
          "usage:\n"
          "  %s --self-test\n"
          "  %s --node /dev/xdmaN_user --bdf DDDD:BB:SS.F --log FILE "
          "read OFFSET\n"
          "  %s --node /dev/xdmaN_user --bdf DDDD:BB:SS.F --log FILE "
          "write OFFSET VALUE\n",
          program, program, program);
}

static int parse_u32(const char *text, uint32_t *value) {
  char *end = NULL;
  unsigned long long parsed;
  if (!text || text[0] == '-' || text[0] == '+')
    return -1;
  errno = 0;
  parsed = strtoull(text, &end, 0);
  if (errno || end == text || *end != '\0' || parsed > UINT32_MAX)
    return -1;
  *value = (uint32_t)parsed;
  return 0;
}

static int valid_node(const char *node) {
  static const char prefix[] = "/dev/xdma";
  static const char suffix[] = "_user";
  const char *cursor;
  if (!node || strncmp(node, prefix, sizeof(prefix) - 1) != 0)
    return 0;
  cursor = node + sizeof(prefix) - 1;
  if (!isdigit((unsigned char)*cursor))
    return 0;
  while (isdigit((unsigned char)*cursor))
    cursor++;
  return strcmp(cursor, suffix) == 0;
}

static int valid_bdf(const char *bdf) {
  size_t index;
  if (!bdf || strlen(bdf) != 12 || bdf[4] != ':' || bdf[7] != ':' ||
      bdf[10] != '.')
    return 0;
  for (index = 0; index < 12; index++) {
    if (index == 4 || index == 7 || index == 10)
      continue;
    if (!isxdigit((unsigned char)bdf[index]))
      return 0;
  }
  return 1;
}

static void canonical_bdf(const char *input, char output[13]) {
  size_t index;
  for (index = 0; index < 12; index++)
    output[index] = (char)tolower((unsigned char)input[index]);
  output[12] = '\0';
}

static int safe_text(const char *text) {
  const unsigned char *cursor = (const unsigned char *)text;
  if (!text || !*text)
    return 0;
  for (; *cursor; cursor++) {
    if (*cursor == '\n' || *cursor == '\r' || *cursor == ',')
      return 0;
  }
  return 1;
}

static int read_allowed(uint32_t offset) {
  if ((offset & 3u) != 0)
    return 0;
  return offset <= UINT32_C(0x0030) ||
         (offset >= UINT32_C(0x0080) && offset <= UINT32_C(0x00b4)) ||
         (offset >= UINT32_C(0x3800) && offset <= UINT32_C(0x3858));
}

static int write_allowed(uint32_t offset, uint32_t value) {
  if ((offset & 3u) != 0)
    return 0;
  if (offset == UINT32_C(0x380c))
    return value == 0 || value == 1;
  if (offset == UINT32_C(0x3844))
    return value == 1;
  return 0;
}

static void encode_le32(uint32_t value, unsigned char bytes[4]) {
  bytes[0] = (unsigned char)(value & 0xffu);
  bytes[1] = (unsigned char)((value >> 8) & 0xffu);
  bytes[2] = (unsigned char)((value >> 16) & 0xffu);
  bytes[3] = (unsigned char)((value >> 24) & 0xffu);
}

static uint32_t decode_le32(const unsigned char bytes[4]) {
  return (uint32_t)bytes[0] | ((uint32_t)bytes[1] << 8) |
         ((uint32_t)bytes[2] << 16) | ((uint32_t)bytes[3] << 24);
}

static int timestamp(char utc[40], uint64_t *monotonic_ns) {
  struct timespec real_time;
  struct timespec monotonic_time;
  struct tm broken_down;
  char whole_seconds[24];
  if (clock_gettime(CLOCK_REALTIME, &real_time) != 0 ||
      clock_gettime(CLOCK_MONOTONIC, &monotonic_time) != 0 ||
      !gmtime_r(&real_time.tv_sec, &broken_down) ||
      !strftime(whole_seconds, sizeof(whole_seconds), "%Y-%m-%dT%H:%M:%S",
                &broken_down))
    return -1;
  if (snprintf(utc, 40, "%s.%09ldZ", whole_seconds, real_time.tv_nsec) >= 40)
    return -1;
  *monotonic_ns = (uint64_t)monotonic_time.tv_sec * UINT64_C(1000000000) +
                  (uint64_t)monotonic_time.tv_nsec;
  return 0;
}

static int open_audit_log(const char *path, int *needs_header) {
  int fd;
  struct stat metadata;
  fd = open(path, O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0600);
  if (fd < 0)
    return -1;
  if (fstat(fd, &metadata) != 0 || !S_ISREG(metadata.st_mode)) {
    int saved = errno ? errno : EINVAL;
    close(fd);
    errno = saved;
    return -1;
  }
  *needs_header = metadata.st_size == 0;
  return fd;
}

static int audit_row(int log_fd, int needs_header, const char *node,
                     const char *bdf, uint32_t offset, const char *operation,
                     int have_value, uint32_t value, const char *result,
                     int error_number, ssize_t byte_count) {
  char utc[40];
  uint64_t monotonic_ns;
  int failed = 0;
  if (timestamp(utc, &monotonic_ns) != 0)
    return -1;
  if (flock(log_fd, LOCK_EX) != 0)
    return -1;
  if (needs_header &&
      dprintf(log_fd,
              "timestamp_utc,monotonic_ns,node,bdf,offset,operation,value,"
              "result,errno,bytes\n") < 0)
    failed = 1;
  if (!failed) {
    if (have_value) {
      if (dprintf(log_fd,
                  "%s,%" PRIu64 ",%s,%s,0x%08" PRIX32 ",%s,0x%08" PRIX32
                  ",%s,%d,%zd\n",
                  utc, monotonic_ns, node, bdf, offset, operation, value,
                  result, error_number, byte_count) < 0)
        failed = 1;
    } else if (dprintf(log_fd,
                       "%s,%" PRIu64 ",%s,%s,0x%08" PRIX32
                       ",%s,NA,%s,%d,%zd\n",
                       utc, monotonic_ns, node, bdf, offset, operation, result,
                       error_number, byte_count) < 0) {
      failed = 1;
    }
  }
  if (!failed && fsync(log_fd) != 0)
    failed = 1;
  if (flock(log_fd, LOCK_UN) != 0)
    failed = 1;
  return failed ? -1 : 0;
}

static int self_test(void) {
  static const uint32_t good_reads[] = {
      0x0000, 0x0030, 0x0080, 0x00b4, 0x3800, 0x3858};
  static const uint32_t bad_reads[] = {
      0x0001, 0x0034, 0x007c, 0x00b8, 0x37fc, 0x385c, 0xffffffff};
  unsigned char bytes[4];
  size_t index;
  for (index = 0; index < sizeof(good_reads) / sizeof(good_reads[0]); index++)
    if (!read_allowed(good_reads[index]))
      return 1;
  for (index = 0; index < sizeof(bad_reads) / sizeof(bad_reads[0]); index++)
    if (read_allowed(bad_reads[index]))
      return 1;
  if (!write_allowed(0x380c, 0) || !write_allowed(0x380c, 1) ||
      !write_allowed(0x3844, 1) || write_allowed(0x380c, 2) ||
      write_allowed(0x3844, 0) || write_allowed(0x383c, 1) ||
      write_allowed(0x0034, 0x13579bdf))
    return 1;
  encode_le32(UINT32_C(0x78563412), bytes);
  if (bytes[0] != 0x12 || bytes[1] != 0x34 || bytes[2] != 0x56 ||
      bytes[3] != 0x78 || decode_le32(bytes) != UINT32_C(0x78563412))
    return 1;
  if (!valid_node("/dev/xdma0_user") || !valid_node("/dev/xdma127_user") ||
      valid_node("/dev/xdma0_c2h_0") || valid_node("/tmp/xdma0_user") ||
      !valid_bdf("0000:01:00.0") || valid_bdf("01:00.0"))
    return 1;
  puts("R3_MMIO_SELF_TEST=PASS");
  return 0;
}

int main(int argc, char **argv) {
  const char *node;
  const char *bdf_input;
  const char *log_path;
  const char *operation_text;
  char bdf[13];
  enum operation_kind operation;
  uint32_t offset;
  uint32_t value = 0;
  unsigned char bytes[4];
  int node_fd = -1;
  int log_fd = -1;
  int needs_header = 0;
  int open_flags;
  struct stat node_metadata;
  ssize_t transferred = -1;
  int access_errno = 0;
  const char *result = "FAIL_INTERNAL";
  int exit_code = 1;

  if (argc == 2 && strcmp(argv[1], "--self-test") == 0)
    return self_test();
  if ((argc != 9 && argc != 10) || strcmp(argv[1], "--node") != 0 ||
      strcmp(argv[3], "--bdf") != 0 || strcmp(argv[5], "--log") != 0) {
    usage(argv[0]);
    return 2;
  }
  node = argv[2];
  bdf_input = argv[4];
  log_path = argv[6];
  operation_text = argv[7];
  if (!valid_node(node) || !valid_bdf(bdf_input) || !safe_text(node) ||
      !safe_text(log_path)) {
    fprintf(stderr, "R3_MMIO_POLICY_REJECTED=invalid node, BDF, or log path\n");
    return 2;
  }
  canonical_bdf(bdf_input, bdf);
  if (strcmp(operation_text, "read") == 0 && argc == 9) {
    operation = OP_READ;
  } else if (strcmp(operation_text, "write") == 0 && argc == 10) {
    operation = OP_WRITE;
  } else {
    usage(argv[0]);
    return 2;
  }
  if (parse_u32(argv[8], &offset) != 0 ||
      (operation == OP_WRITE && parse_u32(argv[9], &value) != 0)) {
    fprintf(stderr, "R3_MMIO_POLICY_REJECTED=invalid numeric argument\n");
    return 2;
  }
  if ((operation == OP_READ && !read_allowed(offset)) ||
      (operation == OP_WRITE && !write_allowed(offset, value))) {
    fprintf(stderr,
            "R3_MMIO_POLICY_REJECTED=offset/value outside exact R3 authority\n");
    return 3;
  }

  log_fd = open_audit_log(log_path, &needs_header);
  if (log_fd < 0) {
    fprintf(stderr, "open audit log: %s\n", strerror(errno));
    return 4;
  }
  open_flags = (operation == OP_READ ? O_RDONLY : O_RDWR) | O_CLOEXEC |
               O_NOFOLLOW;
  node_fd = open(node, open_flags);
  if (node_fd < 0) {
    access_errno = errno;
    result = "FAIL_OPEN_NODE";
    goto record_result;
  }
  if (fstat(node_fd, &node_metadata) != 0 || !S_ISCHR(node_metadata.st_mode)) {
    access_errno = errno ? errno : ENODEV;
    result = "FAIL_NOT_CHAR_DEVICE";
    goto record_result;
  }

  if (operation == OP_READ) {
    errno = 0;
    transferred = pread(node_fd, bytes, sizeof(bytes), (off_t)offset);
    access_errno = transferred == (ssize_t)sizeof(bytes) ? 0 :
                   (errno ? errno : EIO);
    if (transferred == (ssize_t)sizeof(bytes)) {
      value = decode_le32(bytes);
      result = "PASS";
      exit_code = 0;
    } else {
      result = "FAIL_PREAD";
    }
  } else {
    encode_le32(value, bytes);
    errno = 0;
    transferred = pwrite(node_fd, bytes, sizeof(bytes), (off_t)offset);
    access_errno = transferred == (ssize_t)sizeof(bytes) ? 0 :
                   (errno ? errno : EIO);
    if (transferred == (ssize_t)sizeof(bytes)) {
      result = "PASS";
      exit_code = 0;
    } else {
      result = "FAIL_PWRITE";
    }
  }

record_result:
  if (audit_row(log_fd, needs_header, node, bdf, offset, operation_text,
                operation == OP_WRITE || exit_code == 0, value, result,
                access_errno, transferred) != 0) {
    fprintf(stderr, "R3_MMIO_AUDIT_LOG=FAIL\n");
    exit_code = 5;
  }
  if (node_fd >= 0)
    close(node_fd);
  close(log_fd);
  printf("R3_MMIO_RESULT=%s\n", result);
  printf("R3_MMIO_NODE=%s\n", node);
  printf("R3_MMIO_BDF=%s\n", bdf);
  printf("R3_MMIO_OFFSET=0x%08" PRIX32 "\n", offset);
  printf("R3_MMIO_OPERATION=%s\n", operation_text);
  if (operation == OP_WRITE || exit_code == 0)
    printf("R3_MMIO_VALUE=0x%08" PRIX32 "\n", value);
  if (exit_code != 0)
    fprintf(stderr, "R3_MMIO_ERRNO=%d\n", access_errno);
  return exit_code;
}
