#!/usr/bin/env bash
# Read-only payload for one privileged remote telemetry transaction.
#
# Do not install or retain this file on the DUT. For a later authorized run,
# pass its audited body as the `bash -c` payload and pass the reader path as
# argv[1], expanded by the unprivileged remote shell from $HOME before sudo.
# The only device operation is the accepted O_RDONLY/pread reader.
#
# Expected argv:
#   $1 = exact accepted xdma_axil_read path
#   $2 = expected SHA-256 of that reader
# Arm-A post-processing must require:
#   source commit f007dc172d43d30b02729755e60382f8ce3dbff4
#   GIT words f007dc17/2d43d30b/02729755/e60382f8/ce3dbff4
#   BUILD_FLAGS 00000002
# The completed build gate sealed the Arm-A bit at 2192144 bytes and SHA-256
# B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191.
# DETAIL0..DETAIL5 are the complete 192-bit host-visible diagnostic window in
# this formal register map. The internal eight-entry NACK log is not BAR
# visible; do not claim that this collector retrieves it.

set -euo pipefail

reader=${1:?reader path required}
expected_reader_sha=${2:?reader SHA-256 required}
expected_reader_sha=${expected_reader_sha,,}
read_count=0

emit_raw() {
  local tag=$1
  local text=$2
  printf 'RAW_BEGIN=%s\n%s\nRAW_END=%s\n' "$tag" "$text" "$tag"
}

reader_call() {
  local tag=$1
  local offset=$2
  local expected=$3
  local output rc observed
  if output=$("$reader" /dev/xdma0_user "$offset" "$expected" 2>&1); then
    rc=0
  else
    rc=$?
  fi
  read_count=$((read_count + 1))
  emit_raw "$tag" "$output"
  observed=$(printf '%s\n' "$output" | awk -F= '$1 == "AXI_LITE_OBSERVED" { value=$2 } END { print value }')
  if [[ ! $observed =~ ^0x[0-9A-Fa-f]{8}$ ]]; then
    printf 'READER_PARSE_ERROR=%s OFFSET=%s RC=%s\n' "$tag" "$offset" "$rc" >&2
    exit 31
  fi
  READER_RC=$rc
  local observed_digits=${observed:2}
  READER_OBSERVED="0x${observed_digits^^}"
}

read_expect() {
  local name=$1
  local offset=$2
  local expected=${3#0x}
  expected=${expected#0X}
  expected="0x${expected^^}"
  reader_call "IDENTITY_${name}" "$offset" "$expected"
  printf 'IDENTITY_FIELD=%s OFFSET=%s VALUE=%s EXPECTED=%s READER_RC=%s\n' \
    "$name" "$offset" "$READER_OBSERVED" "$expected" "$READER_RC"
  if [[ $READER_OBSERVED != "$expected" || $READER_RC -ne 0 ]]; then
    printf 'IDENTITY_GATE=FAIL_%s\n' "$name" >&2
    exit 32
  fi
}

read_observed() {
  local snapshot=$1
  local name=$2
  local offset=$3
  local start_ns end_ns
  start_ns=$(date +%s%N)
  # Expected zero is intentional. A nonzero observed value makes the accepted
  # reader return 3; that is data, not a transport failure.
  reader_call "${snapshot}_${name}" "$offset" 0x00000000
  end_ns=$(date +%s%N)
  printf 'SNAPSHOT=%s FIELD=%s OFFSET=%s VALUE=%s READER_RC=%s READ_START_NS=%s READ_END_NS=%s\n' \
    "$snapshot" "$name" "$offset" "$READER_OBSERVED" "$READER_RC" "$start_ns" "$end_ns"
}

snapshot() {
  local s=$1
  printf 'SNAPSHOT_BEGIN=%s UTC=%s\n' "$s" "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
  read_observed "$s" FRAME         0x00000060
  read_observed "$s" VCLK          0x00000080
  read_observed "$s" SAV           0x00000084
  read_observed "$s" RECORD_COMMIT 0x00000088
  read_observed "$s" STATUS        0x0000008C
  read_observed "$s" NACK          0x00000090
  read_observed "$s" TIMEOUT       0x00000094
  read_observed "$s" SUMMARY       0x00000098
  read_observed "$s" FIRST_ERROR   0x0000009C
  read_observed "$s" DETAIL0       0x000000A0
  read_observed "$s" DETAIL1       0x000000A4
  read_observed "$s" DETAIL2       0x000000A8
  read_observed "$s" DETAIL3       0x000000AC
  read_observed "$s" DETAIL4       0x000000B0
  read_observed "$s" DETAIL5       0x000000B4
  printf 'SNAPSHOT_END=%s UTC=%s\n' "$s" "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
}

if [[ $(id -u) -ne 0 ]]; then
  printf 'PRIVILEGE_GATE=FAIL_NOT_ROOT\n' >&2
  exit 20
fi
if [[ ! -f $reader || ! -x $reader ]]; then
  printf 'READER_GATE=FAIL_NOT_EXECUTABLE\n' >&2
  exit 21
fi
actual_reader_sha=$(sha256sum -- "$reader" | awk '{print tolower($1)}')
printf 'READER_PATH=%s\nREADER_SHA256=%s\n' "$reader" "$actual_reader_sha"
if [[ $actual_reader_sha != "$expected_reader_sha" ]]; then
  printf 'READER_GATE=FAIL_SHA256\n' >&2
  exit 22
fi
if [[ ! -c /dev/xdma0_user ]]; then
  printf 'USER_NODE_GATE=FAIL_NOT_CHARACTER_DEVICE\n' >&2
  exit 23
fi

boot_before=$(< /proc/sys/kernel/random/boot_id)
printf 'BOOT_ID_BEFORE=%s\n' "$boot_before"

# Strict common identity. Diagnostic provenance is collected below and must be
# classified per arm by the Windows-side gate.
read_expect BLOCK_ID         0x00000000 0xA40A0C07
read_expect PROTOCOL         0x00000004 0x0000400B
read_expect CAPABILITIES     0x00000008 0x00031002
read_expect DIAGNOSTIC_MAGIC 0x00002000 0x00000000

for item in \
  GIT_SHA_W0:0x00000010 GIT_SHA_W1:0x00000014 \
  GIT_SHA_W2:0x00000018 GIT_SHA_W3:0x0000001C \
  GIT_SHA_W4:0x00000020 BUILD_FLAGS:0x0000002C; do
  name=${item%%:*}
  offset=${item##*:}
  reader_call "PROVENANCE_${name}" "$offset" 0x00000000
  printf 'PROVENANCE_FIELD=%s OFFSET=%s VALUE=%s READER_RC=%s\n' \
    "$name" "$offset" "$READER_OBSERVED" "$READER_RC"
done

snapshot T0
sleep 1
snapshot T1

boot_after=$(< /proc/sys/kernel/random/boot_id)
printf 'BOOT_ID_AFTER=%s\n' "$boot_after"
if [[ $boot_after != "$boot_before" ]]; then
  printf 'BOOT_ID_STABILITY=FAIL\n' >&2
  exit 33
fi

printf 'BOOT_ID_STABILITY=PASS\n'
printf 'MMIO_READS_THIS_TRANSACTION=%s\n' "$read_count"
printf 'AXI_LITE_WRITES_THIS_TRANSACTION=0\n'
printf 'C2H_TRANSFERS_THIS_TRANSACTION=0\n'
printf 'H2C_TRANSFERS_THIS_TRANSACTION=0\n'
printf 'TELEMETRY_READ_ONLY=YES\n'
