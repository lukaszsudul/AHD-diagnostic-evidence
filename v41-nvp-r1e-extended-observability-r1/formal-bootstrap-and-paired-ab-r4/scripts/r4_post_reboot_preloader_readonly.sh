#!/usr/bin/env bash
# R4 post-reboot, pre-loader gate. This script is read-only: it validates the
# new boot, exact PCIe function/BARs, absence of XDMA, and kernel health.

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
expected_module_sha=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
expected_loader_sha=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F

case "$role" in
  formal_bootstrap) evidence_dir=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r4/bootstrap_driver ;;
  arm_a_r1e)        evidence_dir=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r4/arm_a_driver ;;
  arm_b_formal)     evidence_dir=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r4/arm_b_driver ;;
  *) printf 'PRELOADER_GATE=FAIL_ROLE\n'; exit 64 ;;
esac

fail() {
  printf 'PRELOADER_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

hex_file() {
  local value
  value=$(cat -- "$1")
  printf '%s' "${value#0x}"
}

printf 'PRELOADER_ROLE=%s\n' "$role"
printf 'PRELOADER_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
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
printf 'PROC_CMDLINE=%s\n' "$(cat -- /proc/cmdline)"
[[ $current_kernel == "$expected_kernel" ]] || fail KERNEL 72
grep -Eq '(^|[[:space:]])BOOT_IMAGE=[^ ]*vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' /proc/cmdline || fail BOOT_IMAGE 73

[[ -f $pinned_module && ! -L $pinned_module ]] || fail PINNED_MODULE_PATH 74
[[ -f $accepted_loader && ! -L $accepted_loader ]] || fail ACCEPTED_LOADER_PATH 75
module_sha=$(sha256sum -- "$pinned_module" | awk '{print toupper($1)}')
loader_sha=$(sha256sum -- "$accepted_loader" | awk '{print toupper($1)}')
module_version=$(modinfo -F version -- "$pinned_module")
module_vermagic=$(modinfo -F vermagic -- "$pinned_module")
loader_mode=$(stat -Lc '%a' -- "$accepted_loader")
printf 'PINNED_MODULE_SHA256=%s\n' "$module_sha"
printf 'PINNED_MODULE_VERSION=%s\n' "$module_version"
printf 'PINNED_MODULE_VERMAGIC=%s\n' "$module_vermagic"
printf 'ACCEPTED_LOADER_SHA256=%s\n' "$loader_sha"
printf 'ACCEPTED_LOADER_MODE=%s\n' "$loader_mode"
[[ $module_sha == "$expected_module_sha" && $module_version == 2025.2.0 && $module_vermagic == "$expected_kernel "* ]] || fail PINNED_MODULE_IDENTITY 76
[[ $loader_sha == "$expected_loader_sha" && $loader_mode == 644 ]] || fail ACCEPTED_LOADER_IDENTITY 77
[[ ! -e $evidence_dir ]] || fail DRIVER_EVIDENCE_DIRECTORY_NOT_FRESH 78
printf 'DRIVER_EVIDENCE_DIRECTORY=%s\n' "$evidence_dir"
printf 'DRIVER_EVIDENCE_DIRECTORY_STATE=ABSENT_FRESH\n'

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
[[ ${#endpoints[@]} -eq 1 && ${endpoints[0]} == "$expected_bdf" ]] || fail ENDPOINT_COUNT_OR_BDF 79
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
[[ $vendor:$device == 10ee:7011 && $subvendor:$subdevice == 10ee:0007 && $class == 058000 ]] || fail ENDPOINT_IDENTITY 80
speed=$(cat -- "$dev/current_link_speed")
width=$(cat -- "$dev/current_link_width")
printf 'CURRENT_LINK_SPEED_RAW=%s\n' "$speed"
printf 'CURRENT_LINK_WIDTH_RAW=%s\n' "$width"
[[ $speed == 2.5* && $width == 1 ]] || fail ENDPOINT_LINK 81
printf 'ENDPOINT_LINK=GEN1_X1\n'
printf 'PCI_RESOURCE_RAW_BEGIN\n'
cat -- "$dev/resource"
printf 'PCI_RESOURCE_RAW_END\n'

bar_parser_sha=$(printf '%s' "$bar_parser_gz_b64" | base64 -d | gzip -dc | sha256sum | awk '{print toupper($1)}')
printf 'BAR_PARSER_SHA256=%s\n' "$bar_parser_sha"
[[ $bar_parser_sha == ${expected_bar_parser_sha^^} ]] || fail BAR_PARSER_SHA 82
bar_output=$(printf '%s' "$bar_parser_gz_b64" | base64 -d | gzip -dc | python3 - --bdf "$bdf") || fail BAR_PARSER_EXECUTION 82
printf 'BAR_PARSER_OUTPUT_BEGIN\n%s\nBAR_PARSER_OUTPUT_END\n' "$bar_output"
bar0=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR0_BYTES" {print $2; exit}')
bar1=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR1_BYTES" {print $2; exit}')
[[ $bar0 == 131072 && $bar1 == 65536 ]] || fail BAR_GEOMETRY 83
printf 'BAR0_BYTES=%s\nBAR1_BYTES=%s\n' "$bar0" "$bar1"

if [[ -L $dev/driver ]]; then
  printf 'ENDPOINT_BOUND_DRIVER=%s\n' "$(basename "$(readlink -f -- "$dev/driver")")"
  fail ENDPOINT_NOT_UNBOUND 84
fi
printf 'ENDPOINT_BOUND_DRIVER=ABSENT\n'
[[ ! -d /sys/module/xdma ]] || fail XDMA_MODULE_PRESENT 85
loaded_count=$(awk '$1=="xdma" {count++} END {print count+0}' /proc/modules)
printf 'XDMA_LOADED_MODULE_ROWS=%s\n' "$loaded_count"
[[ $loaded_count -eq 0 ]] || fail XDMA_MODULE_ROW_PRESENT 85
mapfile -t observed_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
printf 'XDMA_NODE_COUNT=%s\n' "${#observed_nodes[@]}"
printf 'XDMA_NODE_LIST=%s\n' "${observed_nodes[*]:-NONE}"
[[ ${#observed_nodes[@]} -eq 0 ]] || fail XDMA_NODES_PRESENT 86

open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
printf 'XDMA_OPEN_PIDS=%s\n' "${open_pids:-NONE}"
[[ -z $open_pids ]] || fail XDMA_NODE_OWNER 87
printf 'TASK_DMA_COMMANDS=0\n'

critical_matches=$(
  journalctl -b -k --no-pager 2>/dev/null |
    grep -Ei 'AER:.*(fatal|non-fatal|uncorrected)|pcieport.*AER.*error|xdma.*(fail|error)|unknown symbol|probe.*fail' |
    grep -Fiv 'module verification failed: signature and/or required key missing - tainting kernel' || true
)
critical_count=$(if [[ -n $critical_matches ]]; then printf '%s\n' "$critical_matches" | wc -l; else printf 0; fi)
printf 'TARGETED_KERNEL_CRITICAL_MATCH_COUNT=%s\n' "$critical_count"
printf 'TARGETED_KERNEL_CRITICAL_MATCHES_BEGIN\n%s\nTARGETED_KERNEL_CRITICAL_MATCHES_END\n' "$critical_matches"
[[ $critical_count -eq 0 ]] || fail KERNEL_AER_XDMA_HEALTH 88
printf 'KERNEL_AER_XDMA_HEALTH=PASS\n'
printf 'PRELOADER_READ_ONLY=YES\n'
printf 'PRELOADER_GATE=PASS\n'
