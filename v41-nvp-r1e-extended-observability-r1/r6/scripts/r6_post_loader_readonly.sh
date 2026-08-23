#!/usr/bin/env bash
# R6 post-loader gate. This script performs read-only validation of the exact
# XDMA module/binding/nodes, BARs, host health, and FPGA runtime identity.

set -euo pipefail

role=${1:?phase role required}
previous_boot_id=${2:?previous boot ID required}
bar_parser_gz_b64=${3:?compressed BAR parser required}
expected_bar_parser_sha=${4:?BAR parser SHA-256 required}

expected_kernel=7.0.0-29-generic
expected_bdf=0000:01:00.0
expected_user=vcdeagent1
pinned_module=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
accepted_loader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
accepted_reader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/xdma_axil_read
expected_module_sha=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
expected_loader_sha=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
expected_reader_sha=808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E

case "$role" in
  formal_bootstrap) evidence_dir=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r6/bootstrap_driver ;;
  arm_a_r1e)        evidence_dir=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r6/arm_a_driver ;;
  arm_b_formal)     evidence_dir=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r6/arm_b_driver ;;
  *) printf 'POST_LOADER_GATE=FAIL_ROLE\n'; exit 64 ;;
esac

fail() {
  printf 'POST_LOADER_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

hex_file() {
  local value
  value=$(cat -- "$1")
  printf '%s' "${value#0x}"
}

printf 'POST_LOADER_ROLE=%s\n' "$role"
printf 'POST_LOADER_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
printf 'REMOTE_SUDO_USER=%s\n' "${SUDO_USER:-UNKNOWN}"
[[ $(id -un) == root && ${SUDO_USER:-} == "$expected_user" ]] || fail REMOTE_USER_OR_PRIVILEGE 69

[[ $previous_boot_id =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || fail PREVIOUS_BOOT_ID_FORMAT 70
current_boot_id=$(cat -- /proc/sys/kernel/random/boot_id)
printf 'PREVIOUS_BOOT_ID=%s\n' "$previous_boot_id"
printf 'CURRENT_BOOT_ID=%s\n' "$current_boot_id"
[[ $current_boot_id != "$previous_boot_id" ]] || fail BOOT_ID_NOT_CHANGED 71
printf 'BOOT_ID_CHANGED=YES\n'
current_kernel=$(uname -r)
printf 'CURRENT_KERNEL=%s\n' "$current_kernel"
[[ $current_kernel == "$expected_kernel" ]] || fail KERNEL 72

[[ -f $pinned_module && ! -L $pinned_module ]] || fail PINNED_MODULE_PATH 73
[[ -f $accepted_loader && ! -L $accepted_loader ]] || fail ACCEPTED_LOADER_PATH 74
[[ -x $accepted_reader && ! -L $accepted_reader ]] || fail ACCEPTED_READER_PATH 75
module_sha=$(sha256sum -- "$pinned_module" | awk '{print toupper($1)}')
loader_sha=$(sha256sum -- "$accepted_loader" | awk '{print toupper($1)}')
reader_sha=$(sha256sum -- "$accepted_reader" | awk '{print toupper($1)}')
pinned_version=$(modinfo -F version -- "$pinned_module")
pinned_vermagic=$(modinfo -F vermagic -- "$pinned_module")
pinned_srcversion=$(modinfo -F srcversion -- "$pinned_module")
loader_mode=$(stat -Lc '%a' -- "$accepted_loader")
printf 'PINNED_MODULE_SHA256=%s\n' "$module_sha"
printf 'PINNED_MODULE_VERSION=%s\n' "$pinned_version"
printf 'PINNED_MODULE_VERMAGIC=%s\n' "$pinned_vermagic"
printf 'PINNED_MODULE_SRCVERSION=%s\n' "$pinned_srcversion"
printf 'ACCEPTED_LOADER_SHA256=%s\n' "$loader_sha"
printf 'ACCEPTED_LOADER_MODE=%s\n' "$loader_mode"
printf 'ACCEPTED_READER_SHA256=%s\n' "$reader_sha"
[[ $module_sha == "$expected_module_sha" && $pinned_version == 2025.2.0 && $pinned_vermagic == "$expected_kernel "* ]] || fail PINNED_MODULE_IDENTITY 76
[[ $loader_sha == "$expected_loader_sha" && $loader_mode == 644 ]] || fail ACCEPTED_LOADER_IDENTITY 77
[[ $reader_sha == "$expected_reader_sha" ]] || fail ACCEPTED_READER_IDENTITY 78
[[ -d $evidence_dir ]] || fail DRIVER_EVIDENCE_DIRECTORY_MISSING 79
[[ -n $(find "$evidence_dir" -mindepth 1 -maxdepth 1 -print -quit) ]] || fail DRIVER_EVIDENCE_DIRECTORY_EMPTY 79
printf 'DRIVER_EVIDENCE_DIRECTORY=%s\n' "$evidence_dir"
printf 'DRIVER_EVIDENCE_DIRECTORY_STATE=PRESENT_NONEMPTY\n'

mapfile -t endpoints < <(
  for dev in /sys/bus/pci/devices/*; do
    [[ -r $dev/vendor && -r $dev/device ]] || continue
    if [[ $(hex_file "$dev/vendor") == 10ee && $(hex_file "$dev/device") == 7011 ]]; then
      basename "$dev"
    fi
  done | sort
)
printf 'ENDPOINT_COUNT=%s\n' "${#endpoints[@]}"
printf 'ENDPOINT_LIST=%s\n' "${endpoints[*]:-NONE}"
[[ ${#endpoints[@]} -eq 1 && ${endpoints[0]} == "$expected_bdf" ]] || fail ENDPOINT_COUNT_OR_BDF 80
bdf=${endpoints[0]}
dev=/sys/bus/pci/devices/$bdf
vendor=$(hex_file "$dev/vendor")
device=$(hex_file "$dev/device")
subvendor=$(hex_file "$dev/subsystem_vendor")
subdevice=$(hex_file "$dev/subsystem_device")
class=$(hex_file "$dev/class")
printf 'ENDPOINT_BDF=%s\n' "$bdf"
printf 'ENDPOINT_VENDOR_DEVICE=%s:%s\n' "$vendor" "$device"
printf 'ENDPOINT_SUBSYSTEM=%s:%s\n' "$subvendor" "$subdevice"
printf 'ENDPOINT_CLASS=%s\n' "$class"
[[ $vendor:$device == 10ee:7011 && $subvendor:$subdevice == 10ee:0007 && $class == 058000 ]] || fail ENDPOINT_IDENTITY 81
speed=$(cat -- "$dev/current_link_speed")
width=$(cat -- "$dev/current_link_width")
printf 'CURRENT_LINK_SPEED_RAW=%s\n' "$speed"
printf 'CURRENT_LINK_WIDTH_RAW=%s\n' "$width"
[[ $speed == 2.5* && $width == 1 ]] || fail ENDPOINT_LINK 82
printf 'ENDPOINT_LINK=GEN1_X1\n'
printf 'PCI_RESOURCE_RAW_BEGIN\n'
cat -- "$dev/resource"
printf 'PCI_RESOURCE_RAW_END\n'

bar_parser_sha=$(printf '%s' "$bar_parser_gz_b64" | base64 -d | gzip -dc | sha256sum | awk '{print toupper($1)}')
printf 'BAR_PARSER_SHA256=%s\n' "$bar_parser_sha"
[[ $bar_parser_sha == ${expected_bar_parser_sha^^} ]] || fail BAR_PARSER_SHA 83
bar_output=$(printf '%s' "$bar_parser_gz_b64" | base64 -d | gzip -dc | python3 - --bdf "$bdf") || fail BAR_PARSER_EXECUTION 83
printf 'BAR_PARSER_OUTPUT_BEGIN\n%s\nBAR_PARSER_OUTPUT_END\n' "$bar_output"
bar0=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR0_BYTES" {print $2; exit}')
bar1=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR1_BYTES" {print $2; exit}')
[[ $bar0 == 131072 && $bar1 == 65536 ]] || fail BAR_GEOMETRY 84
printf 'BAR0_BYTES=%s\nBAR1_BYTES=%s\n' "$bar0" "$bar1"

[[ -d /sys/module/xdma ]] || fail XDMA_MODULE_ABSENT 85
loaded_count=$(awk '$1=="xdma" {count++} END {print count+0}' /proc/modules)
printf 'XDMA_LOADED_MODULE_ROWS=%s\n' "$loaded_count"
[[ $loaded_count -eq 1 ]] || fail XDMA_MODULE_ROW_COUNT 85
[[ -r /sys/module/xdma/version && -r /sys/module/xdma/srcversion ]] || fail XDMA_MODULE_PROPERTIES 86
loaded_version=$(cat -- /sys/module/xdma/version)
loaded_srcversion=$(cat -- /sys/module/xdma/srcversion)
printf 'XDMA_LOADED_VERSION=%s\n' "$loaded_version"
printf 'XDMA_LOADED_SRCVERSION=%s\n' "$loaded_srcversion"
[[ $loaded_version == "$pinned_version" && ${loaded_srcversion^^} == ${pinned_srcversion^^} ]] || fail WRONG_SAME_NAME_XDMA 87
[[ -L $dev/driver ]] || fail ENDPOINT_UNBOUND 88
bound_driver=$(basename "$(readlink -f -- "$dev/driver")")
bound_module=$(readlink -f -- "$dev/driver/module")
printf 'ENDPOINT_BOUND_DRIVER=%s\n' "$bound_driver"
printf 'ENDPOINT_BOUND_MODULE=%s\n' "$bound_module"
[[ $bound_driver == xdma && $bound_module == /sys/module/xdma ]] || fail XDMA_BINDING_IDENTITY 88

mapfile -t observed_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
mapfile -t expected_nodes < <(printf '%s\n' xdma0_user xdma0_control xdma0_c2h_0 xdma0_h2c_0 xdma0_xvc xdma0_events_{0..15} | sort)
observed_csv=$(printf '%s\n' "${observed_nodes[@]}" | sed '/^$/d' | paste -sd, -)
expected_csv=$(printf '%s\n' "${expected_nodes[@]}" | paste -sd, -)
printf 'XDMA_NODE_COUNT=%s\n' "${#observed_nodes[@]}"
printf 'XDMA_NODE_LIST=%s\n' "$observed_csv"
printf 'XDMA_EXPECTED_NODE_LIST=%s\n' "$expected_csv"
[[ $observed_csv == "$expected_csv" ]] || fail XDMA_NODE_SET 89
open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
printf 'XDMA_OPEN_PIDS=%s\n' "${open_pids:-NONE}"
[[ -z $open_pids ]] || fail XDMA_NODE_OWNER 90
printf 'TASK_DMA_COMMANDS=0\n'

critical_matches=$(
  journalctl -b -k --no-pager 2>/dev/null |
    grep -Ei 'AER:.*(fatal|non-fatal|uncorrected)|pcieport.*AER.*error|xdma.*(fail|error)|unknown symbol|probe.*fail' |
    grep -Fiv 'module verification failed: signature and/or required key missing - tainting kernel' || true
)
critical_count=$(if [[ -n $critical_matches ]]; then printf '%s\n' "$critical_matches" | wc -l; else printf 0; fi)
printf 'TARGETED_KERNEL_CRITICAL_MATCH_COUNT=%s\n' "$critical_count"
printf 'TARGETED_KERNEL_CRITICAL_MATCHES_BEGIN\n%s\nTARGETED_KERNEL_CRITICAL_MATCHES_END\n' "$critical_matches"
[[ $critical_count -eq 0 ]] || fail KERNEL_AER_XDMA_HEALTH 91
printf 'KERNEL_AER_XDMA_HEALTH=PASS\n'

python3 - "$role" /dev/xdma0_user <<'PY'
import os
import struct
import sys

role, node = sys.argv[1:]

def word(fd: int, offset: int) -> int:
    data = os.pread(fd, 4, offset)
    if len(data) != 4:
        raise RuntimeError(f"short pread at 0x{offset:08X}")
    return struct.unpack("<I", data)[0]

fd = os.open(node, os.O_RDONLY | os.O_CLOEXEC)
try:
    values = {offset: word(fd, offset) for offset in (
        0x0000, 0x0004, 0x0008,
        0x0010, 0x0014, 0x0018, 0x001C, 0x0020, 0x002C,
        0x2000, 0x2040, 0x2044, 0x2048, 0x204C, 0x2050,
        0x2054, 0x2058, 0x2064,
    )}
    common = (values[0x0000], values[0x0004], values[0x0008])
    expected_common = (0xA40A0C07, 0x0000400B, 0x00031002)
    if common != expected_common:
        raise RuntimeError(f"common identity mismatch: {common!r}")
    git_sha = "".join(f"{values[offset]:08x}" for offset in (0x10, 0x14, 0x18, 0x1C, 0x20))
    print(f"RAW_BLOCK_ID=0x{values[0x0000]:08X}")
    print(f"RAW_PROTOCOL=0x{values[0x0004]:08X}")
    print(f"RAW_CAPABILITIES=0x{values[0x0008]:08X}")
    print(f"RAW_RECONSTRUCTED_GIT_SHA={git_sha}")
    print(f"RAW_BUILD_FLAGS=0x{values[0x002C]:08X}")
    print(f"RAW_PAGE_0X2000=0x{values[0x2000]:08X}")
    if role == "arm_a_r1e":
        expected_git = "f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd"
        expected_page = {
            0x2000: 0x314B4C43, 0x2040: 0x31453152,
            0x2044: 1, 0x2048: 0x1F, 0x204C: 25000,
            0x2050: 1251, 0x2054: 132584734, 0x2058: 0,
            0x2064: 10000,
        }
        if git_sha != expected_git or values[0x002C] != 2:
            raise RuntimeError("R1e source/build provenance mismatch")
        for offset, expected in expected_page.items():
            if values[offset] != expected:
                raise RuntimeError(
                    f"R1e page 0x{offset:04X}: expected 0x{expected:08X}, got 0x{values[offset]:08X}"
                )
        print("RUNTIME_IMAGE=R1E_EXACT_PROVENANCE")
    else:
        formal_page = [word(fd, offset) for offset in range(0x2000, 0x2100, 4)]
        if any(formal_page):
            raise RuntimeError("formal image R1e page is not zero/reserved")
        print("RUNTIME_IMAGE=FORMAL_PHASE2_EXACT_IDENTITY_PAGE_ZERO")
finally:
    os.close(fd)
print("RAW_READER_MODE=O_RDONLY_PREAD_ONLY")
PY

for spec in \
  BLOCK_ID:0x00000000:0xA40A0C07 \
  PROTOCOL:0x00000004:0x0000400B \
  CAPABILITIES:0x00000008:0x00031002; do
  name=${spec%%:*}
  rest=${spec#*:}
  offset=${rest%%:*}
  expected=${rest#*:}
  printf 'ACCEPTED_READER_BEGIN=%s\n' "$name"
  "$accepted_reader" /dev/xdma0_user "$offset" "$expected"
  printf 'ACCEPTED_READER_END=%s\n' "$name"
done
if [[ $role != arm_a_r1e ]]; then
  printf 'ACCEPTED_READER_BEGIN=DIAGNOSTIC_MAGIC\n'
  "$accepted_reader" /dev/xdma0_user 0x00002000 0x00000000
  printf 'ACCEPTED_READER_END=DIAGNOSTIC_MAGIC\n'
fi

printf 'POST_LOADER_MMIO=READ_ONLY\n'
printf 'POST_LOADER_GATE=PASS_%s\n' "${role^^}"
