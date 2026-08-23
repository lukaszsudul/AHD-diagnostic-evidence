#!/usr/bin/env bash
# Read-only completion of R4 discovery after an inherited command-substitution
# expression rendered readable /sys/module version fields empty.

set -euo pipefail

fail() {
  printf 'SUPPLEMENTAL_DISCOVERY_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

expected_kernel=7.0.0-29-generic
expected_bdf=0000:01:00.0
pinned_module=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
accepted_reader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/xdma_axil_read
expected_reader_sha=808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E

printf 'SUPPLEMENTAL_CURRENT_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
printf 'SUPPLEMENTAL_BOOT_ID=%s\n' "$(< /proc/sys/kernel/random/boot_id)"
printf 'SUPPLEMENTAL_KERNEL=%s\n' "$(uname -r)"
[[ $(uname -r) == "$expected_kernel" ]] || fail KERNEL 71

[[ -d /sys/module/xdma ]] || fail XDMA_MODULE_ABSENT 89
[[ -r /sys/module/xdma/version && -r /sys/module/xdma/srcversion ]] || fail XDMA_PROPERTIES_UNREADABLE 89
loaded_version=$(cat -- /sys/module/xdma/version)
loaded_srcversion=$(cat -- /sys/module/xdma/srcversion)
pinned_version=$(modinfo -F version -- "$pinned_module")
pinned_srcversion=$(modinfo -F srcversion -- "$pinned_module")
printf 'XDMA_LOADED_VERSION_DIRECT=%s\n' "$loaded_version"
printf 'XDMA_PINNED_VERSION=%s\n' "$pinned_version"
printf 'XDMA_LOADED_SRCVERSION_DIRECT=%s\n' "$loaded_srcversion"
printf 'XDMA_PINNED_SRCVERSION=%s\n' "$pinned_srcversion"
[[ $loaded_version == 2025.2.0 && $loaded_version == "$pinned_version" ]] || fail WRONG_SAME_NAME_XDMA_VERSION 90
[[ ${loaded_srcversion^^} == ${pinned_srcversion^^} ]] || fail WRONG_SAME_NAME_XDMA_SRCVERSION 90
driver=$(basename "$(readlink -f -- /sys/bus/pci/devices/$expected_bdf/driver)")
printf 'ENDPOINT_BOUND_DRIVER_DIRECT=%s\n' "$driver"
[[ $driver == xdma ]] || fail XDMA_NOT_BOUND 90
printf 'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO\n'

mapfile -t observed_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
mapfile -t expected_nodes < <(printf '%s\n' xdma0_user xdma0_control xdma0_c2h_0 xdma0_h2c_0 xdma0_xvc xdma0_events_{0..15} | sort)
observed_csv=$(printf '%s\n' "${observed_nodes[@]}" | sed '/^$/d' | paste -sd, -)
expected_csv=$(printf '%s\n' "${expected_nodes[@]}" | paste -sd, -)
printf 'XDMA_NODE_COUNT_DIRECT=%s\n' "${#observed_nodes[@]}"
printf 'XDMA_NODE_LIST_DIRECT=%s\n' "${observed_csv:-NONE}"
[[ $observed_csv == "$expected_csv" ]] || fail XDMA_NODE_SET 91

open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
printf 'XDMA_OPEN_PROCESS_COUNT=%s\n' "$(if [[ -n $open_pids ]]; then tr ',' '\n' <<< "$open_pids" | wc -l; else printf 0; fi)"
printf 'XDMA_OPEN_PIDS=%s\n' "${open_pids:-NONE}"
[[ -z $open_pids ]] || fail XDMA_NODE_OWNER 93
printf 'TASK_DMA_COMMANDS=0\n'

critical_matches=$(
  journalctl -b -k --no-pager 2>/dev/null |
    grep -Ei 'AER:.*(fatal|non-fatal|uncorrected)|pcieport.*AER.*error|xdma.*(fail|error)|unknown symbol|probe.*fail' |
    grep -Fiv 'module verification failed: signature and/or required key missing - tainting kernel' || true
)
critical_count=$(if [[ -n $critical_matches ]]; then printf '%s\n' "$critical_matches" | wc -l; else printf 0; fi)
printf 'TARGETED_KERNEL_CRITICAL_MATCH_COUNT=%s\n' "$critical_count"
printf 'TARGETED_KERNEL_CRITICAL_MATCHES_BEGIN\n%s\nTARGETED_KERNEL_CRITICAL_MATCHES_END\n' "$critical_matches"
[[ $critical_count -eq 0 ]] || fail KERNEL_AER_XDMA_HEALTH 94
printf 'KERNEL_AER_XDMA_HEALTH=PASS\n'

[[ -x $accepted_reader ]] || fail ACCEPTED_READER_MISSING 95
actual_reader_sha=$(sha256sum -- "$accepted_reader" | awk '{print toupper($1)}')
printf 'ACCEPTED_READER_PATH=%s\n' "$accepted_reader"
printf 'ACCEPTED_READER_SHA256=%s\n' "$actual_reader_sha"
[[ $actual_reader_sha == "$expected_reader_sha" ]] || fail ACCEPTED_READER_SHA 95

/usr/bin/python3 - /dev/xdma0_user <<'PY'
import os, struct, sys
node = sys.argv[1]
offsets = {
    'BLOCK_ID': 0x0000, 'PROTOCOL': 0x0004, 'CAPABILITIES': 0x0008,
    'GIT_SHA_W0': 0x0010, 'GIT_SHA_W1': 0x0014, 'GIT_SHA_W2': 0x0018,
    'GIT_SHA_W3': 0x001C, 'GIT_SHA_W4': 0x0020,
    'BUILD_FLAGS': 0x002C, 'DIAGNOSTIC_MAGIC': 0x2000,
}
fd = os.open(node, os.O_RDONLY | os.O_CLOEXEC)
try:
    for name, offset in offsets.items():
        data = os.pread(fd, 4, offset)
        if len(data) != 4:
            raise RuntimeError(f'short pread at 0x{offset:08X}')
        print(f'RAW_TASK_READER_{name}=0x{struct.unpack("<I", data)[0]:08X}')
finally:
    os.close(fd)
print('RAW_TASK_READER_MODE=O_RDONLY_PREAD_ONLY')
PY

for spec in \
  BLOCK_ID:0x00000000:0xA40A0C07 \
  PROTOCOL:0x00000004:0x0000400B \
  CAPABILITIES:0x00000008:0x00031002 \
  DIAGNOSTIC_MAGIC:0x00002000:0x00000000; do
  name=${spec%%:*}
  rest=${spec#*:}
  offset=${rest%%:*}
  expected=${rest#*:}
  set +e
  output=$("$accepted_reader" /dev/xdma0_user "$offset" "$expected" 2>&1)
  rc=$?
  set -e
  printf 'ACCEPTED_READER_RAW_BEGIN=%s\n%s\nACCEPTED_READER_RAW_END=%s\n' "$name" "$output" "$name"
  observed=$(printf '%s\n' "$output" | awk -F= '$1=="AXI_LITE_OBSERVED" {v=$2} END {print v}')
  [[ $observed =~ ^0x[0-9A-Fa-f]{8}$ ]] || fail ACCEPTED_READER_PARSE 96
  printf 'ACCEPTED_READER_FIELD=%s OFFSET=%s OBSERVED=%s EXPECTED=%s RC=%s\n' \
    "$name" "$offset" "${observed^^}" "$expected" "$rc"
done

printf 'START_STATE_DISCOVERY_MMIO=READ_ONLY\n'
printf 'SUPPLEMENTAL_DISCOVERY_GATE=PASS\n'
