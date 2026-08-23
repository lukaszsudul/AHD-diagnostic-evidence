#!/usr/bin/env bash
# R6 pre-bootstrap safety discovery. Read-only; accepts
# either zero or one exact expected FPGA endpoint and absent XDMA state.

set -euo pipefail

baseline_boot_id=${1:?R6 boot ID baseline required}
bar_parser_gz_b64=${2:?compressed BAR parser required}
expected_bar_parser_sha=${3:?BAR parser SHA-256 required}

expected_kernel=7.0.0-29-generic
expected_user=vcdeagent1
expected_bdf=0000:01:00.0
pinned_module=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
accepted_loader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
accepted_reader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/xdma_axil_read
expected_module_sha=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
expected_loader_sha=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
expected_reader_sha=808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E

fail() {
  printf 'PRE_BOOTSTRAP_HOST_SAFETY_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

hex_file() {
  local value
  value=$(cat -- "$1")
  printf '%s' "${value#0x}"
}

printf 'DISCOVERY_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
printf 'REMOTE_SUDO_USER=%s\n' "${SUDO_USER:-UNKNOWN}"
[[ $(id -un) == root && ${SUDO_USER:-} == "$expected_user" ]] || fail REMOTE_USER_OR_PRIVILEGE 69

[[ $baseline_boot_id =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || fail BASELINE_BOOT_ID_FORMAT 70
hostname_value=$(hostname)
current_kernel=$(uname -r)
current_boot_id=$(cat -- /proc/sys/kernel/random/boot_id)
uptime_seconds=$(awk '{print $1}' /proc/uptime)
printf 'HOSTNAME=%s\n' "$hostname_value"
printf 'CURRENT_KERNEL=%s\n' "$current_kernel"
printf 'R6_BOOT_ID_BASELINE=%s\n' "$baseline_boot_id"
printf 'CURRENT_BOOT_ID=%s\n' "$current_boot_id"
printf 'UPTIME_SECONDS=%s\n' "$uptime_seconds"
printf 'UPTIME_START=%s\n' "$(uptime -s)"
printf 'PROC_CMDLINE=%s\n' "$(cat -- /proc/cmdline)"
[[ $current_kernel == "$expected_kernel" ]] || fail CURRENT_KERNEL 71
[[ $current_boot_id == "$baseline_boot_id" ]] || fail BOOT_ID_CHANGED_AFTER_STABILITY_GATE 72
grep -Eq '(^|[[:space:]])BOOT_IMAGE=[^ ]*vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' /proc/cmdline || fail BOOT_IMAGE 73
[[ -d /lib/modules/$expected_kernel ]] || fail MODULE_DIRECTORY 74

[[ -f $pinned_module && ! -L $pinned_module ]] || fail PINNED_MODULE_PATH 75
[[ -f $accepted_loader && ! -L $accepted_loader ]] || fail ACCEPTED_LOADER_PATH 76
[[ -x $accepted_reader && ! -L $accepted_reader ]] || fail ACCEPTED_READER_PATH 77
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
[[ $module_sha == "$expected_module_sha" && $pinned_version == 2025.2.0 && $pinned_vermagic == "$expected_kernel "* ]] || fail PINNED_MODULE_IDENTITY 78
[[ $loader_sha == "$expected_loader_sha" && $loader_mode == 644 ]] || fail ACCEPTED_LOADER_IDENTITY 79
[[ $reader_sha == "$expected_reader_sha" ]] || fail ACCEPTED_READER_IDENTITY 80

[[ -r /etc/default/grub && -r /boot/grub/grub.cfg ]] || fail GRUB_FILES 81
command -v grub-editenv >/dev/null 2>&1 || fail GRUB_EDITENV_TOOL 82
grub_default=$(sed -n 's/^[[:space:]]*GRUB_DEFAULT[[:space:]]*=[[:space:]]*//p' /etc/default/grub | tail -n 1)
grub_default=${grub_default%\"}; grub_default=${grub_default#\"}
grub_default=${grub_default%\'}; grub_default=${grub_default#\'}
grub_env=$(grub-editenv /boot/grub/grubenv list 2>/dev/null || grub-editenv list)
saved_entry=$(printf '%s\n' "$grub_env" | awk -F= '$1=="saved_entry" {sub(/^[^=]*=/,""); print; exit}')
next_entry=$(printf '%s\n' "$grub_env" | awk -F= '$1=="next_entry" {sub(/^[^=]*=/,""); print; exit}')
printf 'GRUB_DEFAULT_NORMALIZED=%s\n' "${grub_default:-NOT_SET}"
printf 'GRUB_SAVED_ENTRY=%s\n' "${saved_entry:-NONE}"
printf 'GRUB_NEXT_ENTRY=%s\n' "${next_entry:-NONE}"
persistent_kernel29=NO
selected_entry=NONE
if [[ $grub_default == saved && $saved_entry == *7.0.0-29-generic* ]]; then
  persistent_kernel29=YES; selected_entry=$saved_entry
elif [[ $grub_default == *7.0.0-29-generic* ]]; then
  persistent_kernel29=YES; selected_entry=$grub_default
fi
[[ $persistent_kernel29 == YES ]] || fail NEXT_REBOOT_DEFAULT_UNPROVEN 83
if [[ -n $next_entry && $next_entry != *7.0.0-29-generic* ]]; then fail NEXT_ENTRY_OTHER_KERNEL 84; fi
selected_leaf=${selected_entry##*>}
selected_line=$(grep -nF -- "$selected_leaf" /boot/grub/grub.cfg | grep -E 'menuentry .*7\.0\.0-29-generic' | head -n 1 | cut -d: -f1 || true)
[[ $selected_line =~ ^[0-9]+$ ]] || fail SELECTED_GRUB_ENTRY_NOT_FOUND 85
selected_block=$(sed -n "${selected_line},$((selected_line + 40))p" /boot/grub/grub.cfg)
printf '%s\n' "$selected_block" | grep -Eq '^[[:space:]]*linux[[:space:]].*/vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' || fail SELECTED_GRUB_LINUX_IMAGE 86
printf 'NEXT_REBOOT_KERNEL_PROVEN=%s\n' "$expected_kernel"

for evidence_dir in \
  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r6/bootstrap_driver \
  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r6/arm_a_driver \
  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r6/arm_b_driver; do
  [[ ! -e $evidence_dir ]] || fail DRIVER_EVIDENCE_DIRECTORY_NOT_FRESH 87
  printf 'FRESH_DRIVER_EVIDENCE_DIRECTORY=%s STATE=ABSENT_FRESH\n' "$evidence_dir"
done

mapfile -t xilinx_functions < <(
  for dev in /sys/bus/pci/devices/*; do
    [[ -r $dev/vendor ]] || continue
    [[ $(hex_file "$dev/vendor") == 10ee ]] && basename "$dev"
  done | sort
)
mapfile -t expected_endpoints < <(
  for dev in /sys/bus/pci/devices/*; do
    [[ -r $dev/vendor && -r $dev/device ]] || continue
    if [[ $(hex_file "$dev/vendor") == 10ee && $(hex_file "$dev/device") == 7011 ]]; then basename "$dev"; fi
  done | sort
)
printf 'XILINX_FUNCTION_COUNT=%s\n' "${#xilinx_functions[@]}"
printf 'XILINX_FUNCTION_LIST=%s\n' "${xilinx_functions[*]:-NONE}"
printf 'EXPECTED_ENDPOINT_COUNT=%s\n' "${#expected_endpoints[@]}"
printf 'EXPECTED_ENDPOINT_LIST=%s\n' "${expected_endpoints[*]:-NONE}"
[[ ${#expected_endpoints[@]} -le 1 ]] || fail MULTIPLE_EXPECTED_ENDPOINTS 88
[[ ${#xilinx_functions[@]} -eq ${#expected_endpoints[@]} ]] || fail FOREIGN_XILINX_ENDPOINT 89

endpoint_present=NO
endpoint_driver=ABSENT
bdf=NONE
if [[ ${#expected_endpoints[@]} -eq 1 ]]; then
  endpoint_present=YES
  bdf=${expected_endpoints[0]}
  [[ $bdf == "$expected_bdf" ]] || fail ENDPOINT_BDF 90
  dev=/sys/bus/pci/devices/$bdf
  vendor=$(hex_file "$dev/vendor"); device=$(hex_file "$dev/device")
  subvendor=$(hex_file "$dev/subsystem_vendor"); subdevice=$(hex_file "$dev/subsystem_device")
  class=$(hex_file "$dev/class")
  printf 'ENDPOINT_BDF=%s\n' "$bdf"
  printf 'ENDPOINT_VENDOR_DEVICE=%s:%s\n' "$vendor" "$device"
  printf 'ENDPOINT_SUBSYSTEM=%s:%s\n' "$subvendor" "$subdevice"
  printf 'ENDPOINT_CLASS=%s\n' "$class"
  [[ $vendor:$device == 10ee:7011 && $subvendor:$subdevice == 10ee:0007 && $class == 058000 ]] || fail ENDPOINT_IDENTITY 91
  speed=$(cat -- "$dev/current_link_speed"); width=$(cat -- "$dev/current_link_width")
  printf 'CURRENT_LINK_SPEED_RAW=%s\n' "$speed"
  printf 'CURRENT_LINK_WIDTH_RAW=%s\n' "$width"
  [[ $speed == 2.5* && $width == 1 ]] || fail ENDPOINT_LINK 92
  printf 'ENDPOINT_LINK=GEN1_X1\n'
  printf 'PCI_RESOURCE_RAW_BEGIN\n'; cat -- "$dev/resource"; printf 'PCI_RESOURCE_RAW_END\n'
  bar_parser_sha=$(printf '%s' "$bar_parser_gz_b64" | base64 -d | gzip -dc | sha256sum | awk '{print toupper($1)}')
  printf 'BAR_PARSER_SHA256=%s\n' "$bar_parser_sha"
  [[ $bar_parser_sha == ${expected_bar_parser_sha^^} ]] || fail BAR_PARSER_SHA 93
  bar_output=$(printf '%s' "$bar_parser_gz_b64" | base64 -d | gzip -dc | python3 - --bdf "$bdf") || fail BAR_PARSER_EXECUTION 94
  printf 'BAR_PARSER_OUTPUT_BEGIN\n%s\nBAR_PARSER_OUTPUT_END\n' "$bar_output"
  bar0=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR0_BYTES" {print $2; exit}')
  bar1=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR1_BYTES" {print $2; exit}')
  [[ $bar0 == 131072 && $bar1 == 65536 ]] || fail BAR_GEOMETRY 95
  printf 'BAR0_BYTES=%s\nBAR1_BYTES=%s\n' "$bar0" "$bar1"
  if [[ -L $dev/driver ]]; then endpoint_driver=$(basename "$(readlink -f -- "$dev/driver")"); fi
else
  printf 'ENDPOINT_BDF=ABSENT_ACCEPTED_PRE_BOOTSTRAP\n'
  printf 'ENDPOINT_LINK=NOT_AVAILABLE_ENDPOINT_ABSENT\n'
  printf 'BAR0_BYTES=NOT_AVAILABLE_ENDPOINT_ABSENT\n'
  printf 'BAR1_BYTES=NOT_AVAILABLE_ENDPOINT_ABSENT\n'
fi
printf 'PRE_BOOTSTRAP_ENDPOINT_STATE=%s\n' "$(if [[ $endpoint_present == YES ]]; then printf PRESENT_EXACT; else printf ABSENT_ACCEPTED; fi)"
printf 'ENDPOINT_BOUND_DRIVER=%s\n' "$endpoint_driver"

loaded_rows=$(awk '$1=="xdma" {count++} END {print count+0}' /proc/modules)
[[ $loaded_rows -le 1 ]] || fail MULTIPLE_XDMA_MODULE_ROWS 96
loaded=NO
if [[ -d /sys/module/xdma ]]; then loaded=YES; fi
printf 'XDMA_MODULE_PRESENT=%s\n' "$loaded"
printf 'XDMA_LOADED_MODULE_ROWS=%s\n' "$loaded_rows"
if [[ $loaded == YES ]]; then
  [[ $loaded_rows -eq 1 && -r /sys/module/xdma/version && -r /sys/module/xdma/srcversion ]] || fail XDMA_MODULE_PROPERTIES 97
  loaded_version=$(cat -- /sys/module/xdma/version)
  loaded_srcversion=$(cat -- /sys/module/xdma/srcversion)
  printf 'XDMA_LOADED_VERSION=%s\n' "$loaded_version"
  printf 'XDMA_LOADED_SRCVERSION=%s\n' "$loaded_srcversion"
  [[ $loaded_version == "$pinned_version" && ${loaded_srcversion^^} == ${pinned_srcversion^^} ]] || fail WRONG_SAME_NAME_XDMA 98
else
  [[ $loaded_rows -eq 0 ]] || fail XDMA_MODULE_STATE_INCOHERENT 99
  printf 'XDMA_LOADED_VERSION=ABSENT_ACCEPTED\n'
  printf 'XDMA_LOADED_SRCVERSION=ABSENT_ACCEPTED\n'
fi
if [[ $endpoint_driver != ABSENT ]]; then
  [[ $endpoint_driver == xdma && $loaded == YES ]] || fail WRONG_BOUND_DRIVER 100
fi
printf 'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO\n'

mapfile -t observed_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
mapfile -t expected_nodes < <(printf '%s\n' xdma0_user xdma0_control xdma0_c2h_0 xdma0_h2c_0 xdma0_xvc xdma0_events_{0..15} | sort)
observed_csv=$(printf '%s\n' "${observed_nodes[@]}" | sed '/^$/d' | paste -sd, -)
expected_csv=$(printf '%s\n' "${expected_nodes[@]}" | paste -sd, -)
printf 'XDMA_NODE_COUNT=%s\n' "${#observed_nodes[@]}"
printf 'XDMA_NODE_LIST=%s\n' "${observed_csv:-NONE}"
if [[ ${#observed_nodes[@]} -ne 0 ]]; then
  [[ $loaded == YES && $observed_csv == "$expected_csv" ]] || fail XDMA_NODE_SET_OR_MODULE 101
fi
printf 'PRE_BOOTSTRAP_DRIVER_STATE=%s\n' "$(if [[ $loaded == YES ]]; then printf EXACT_PINNED_PRESENT; else printf ABSENT_ACCEPTED; fi)"

open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
printf 'XDMA_OPEN_PIDS=%s\n' "${open_pids:-NONE}"
[[ -z $open_pids ]] || fail XDMA_NODE_OWNER 102
printf 'XDMA_NODE_OWNERS=0\n'
printf 'TASK_DMA_COMMANDS=0\n'

critical_matches=$(
  journalctl -b -k --no-pager 2>/dev/null |
    grep -Ei 'AER:.*(fatal|non-fatal|uncorrected)|pcieport.*AER.*error|xdma.*(fail|error)|unknown symbol|probe.*fail' |
    grep -Fiv 'module verification failed: signature and/or required key missing - tainting kernel' || true
)
critical_count=$(if [[ -n $critical_matches ]]; then printf '%s\n' "$critical_matches" | wc -l; else printf 0; fi)
printf 'TARGETED_KERNEL_CRITICAL_MATCH_COUNT=%s\n' "$critical_count"
printf 'TARGETED_KERNEL_CRITICAL_MATCHES_BEGIN\n%s\nTARGETED_KERNEL_CRITICAL_MATCHES_END\n' "$critical_matches"
[[ $critical_count -eq 0 ]] || fail KERNEL_AER_XDMA_HEALTH 103
printf 'KERNEL_AER_XDMA_HEALTH=PASS\n'

if [[ $endpoint_present == NO ]]; then
  printf 'PRE_BOOTSTRAP_RUNTIME_IDENTITY=NOT_AVAILABLE_ENDPOINT_ABSENT_ACCEPTED\n'
elif [[ $endpoint_driver != xdma || ! -e /dev/xdma0_user ]]; then
  printf 'PRE_BOOTSTRAP_RUNTIME_IDENTITY=NOT_AVAILABLE_DRIVER_OR_NODE_ABSENT_ACCEPTED\n'
else
  set +e
  identity_output=$(python3 - /dev/xdma0_user <<'PY'
import os, struct, sys
fd = os.open(sys.argv[1], os.O_RDONLY | os.O_CLOEXEC)
try:
    for name, offset in (("BLOCK_ID",0), ("PROTOCOL",4), ("CAPABILITIES",8), ("DIAGNOSTIC_MAGIC",0x2000)):
        data = os.pread(fd, 4, offset)
        if len(data) != 4:
            raise RuntimeError(f"short pread at 0x{offset:08X}")
        print(f"PRE_BOOTSTRAP_RAW_{name}=0x{struct.unpack('<I', data)[0]:08X}")
finally:
    os.close(fd)
print("PRE_BOOTSTRAP_RAW_READER_MODE=O_RDONLY_PREAD_ONLY")
PY
  )
  identity_rc=$?
  set -e
  printf 'PRE_BOOTSTRAP_RUNTIME_READER_RC=%s\n' "$identity_rc"
  printf 'PRE_BOOTSTRAP_RUNTIME_READER_OUTPUT_BEGIN\n%s\nPRE_BOOTSTRAP_RUNTIME_READER_OUTPUT_END\n' "$identity_output"
  printf 'PRE_BOOTSTRAP_RUNTIME_IDENTITY=UNPROVEN_INFORMATIONAL_READ_ONLY\n'
fi

printf 'R6_BOOT_ID_CONTINUITY=PASS_BASELINE_UNCHANGED\n'
printf 'PRE_BOOTSTRAP_DISCOVERY_READ_ONLY=YES\n'
printf 'PRE_BOOTSTRAP_HOST_SAFETY_GATE=PASS\n'
