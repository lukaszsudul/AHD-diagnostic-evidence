#!/usr/bin/env bash
# R1g runtime identity/provenance leaf. This leaf opens only the already-proven
# XDMA user BAR node with O_RDONLY and uses pread. It has no MMIO, PCIe, driver,
# I2C, reboot, programming, DMA, or filesystem mutation path.

set -euo pipefail

role=${1:?role required}
expected_r1g_commit=${2:?expected R1g commit required}
node=${3:-/dev/xdma0_user}

case "$role" in
  r1g)
    [[ $expected_r1g_commit =~ ^[0-9a-f]{40}$ ]] || {
      printf 'RUNTIME_PROVENANCE_GATE=FAIL_EXPECTED_COMMIT_FORMAT\n'
      exit 64
    }
    ;;
  formal)
    [[ $expected_r1g_commit == NOT_APPLICABLE ]] || {
      printf 'RUNTIME_PROVENANCE_GATE=FAIL_FORMAL_COMMIT_ARGUMENT\n'
      exit 64
    }
    ;;
  *)
    printf 'RUNTIME_PROVENANCE_GATE=FAIL_ROLE\n'
    exit 64
    ;;
esac

python3 - "$role" "$expected_r1g_commit" "$node" <<'PY'
import os
import struct
import sys

role, expected_commit, node = sys.argv[1:]

def word(fd: int, offset: int) -> int:
    raw = os.pread(fd, 4, offset)
    if len(raw) != 4:
        raise RuntimeError(f"short pread at 0x{offset:08X}")
    return struct.unpack("<I", raw)[0]

fd = os.open(node, os.O_RDONLY | os.O_CLOEXEC)
try:
    values = {offset: word(fd, offset) for offset in (
        0x0000, 0x0004, 0x0008,
        0x0010, 0x0014, 0x0018, 0x001C, 0x0020, 0x002C,
        0x2000,
    )}
    common = (values[0x0000], values[0x0004], values[0x0008])
    expected_common = (0xA40A0C07, 0x0000400B, 0x00031002)
    if common != expected_common:
        raise RuntimeError(f"common identity mismatch: {common!r}")
    git_sha = "".join(f"{values[offset]:08x}" for offset in
                      (0x0010, 0x0014, 0x0018, 0x001C, 0x0020))
    build_flags = values[0x002C]
    diagnostic_word = values[0x2000]
    print(f"RAW_BLOCK_ID=0x{values[0x0000]:08X}")
    print(f"RAW_PROTOCOL=0x{values[0x0004]:08X}")
    print(f"RAW_CAPABILITIES=0x{values[0x0008]:08X}")
    print(f"RAW_RECONSTRUCTED_GIT_SHA={git_sha}")
    print(f"RAW_BUILD_FLAGS=0x{build_flags:08X}")
    print(f"RAW_DIAGNOSTIC_WORD_0X2000=0x{diagnostic_word:08X}")
    if role == "r1g":
        if git_sha != expected_commit:
            raise RuntimeError("R1g source-commit provenance mismatch")
        if build_flags != 0x00000002:
            raise RuntimeError("R1g BUILD_FLAGS mismatch")
        if diagnostic_word != 0x314B4C43:
            raise RuntimeError("R1g inherited lifecycle magic mismatch")
        print("RUNTIME_IMAGE=R1G_EXACT_SOURCE_AND_BUILD_FLAGS")
    else:
        if diagnostic_word != 0:
            raise RuntimeError("formal diagnostic magic is not zero")
        nonzero = []
        for offset in range(0x20A0, 0x3600, 4):
            value = word(fd, offset)
            if value:
                nonzero.append((offset, value))
                if len(nonzero) == 8:
                    break
        if nonzero:
            raise RuntimeError(f"formal R1f/R1g range not zero: {nonzero!r}")
        print("RUNTIME_IMAGE=FORMAL_PHASE2_EXACT_IDENTITY_R1F_R1G_RANGE_ZERO")
finally:
    os.close(fd)

print("RUNTIME_READER_OPEN_MODE=O_RDONLY_PREAD_ONLY")
print("RUNTIME_PROVENANCE_GATE=PASS")
PY

printf 'MMIO_ACCESS=READ_ONLY\n'
printf 'AXI_LITE_WRITES=0\n'
printf 'C2H_TRANSFERS=0\n'
printf 'H2C_TRANSFERS=0\n'
