#!/usr/bin/env bash
# R4 read-only kernel/boot/PCI/driver discovery. No files, modules, PCI state,
# MMIO, DMA, GRUB state, or hardware configuration are changed.

set -euo pipefail

expected_kernel=7.0.0-29-generic
expected_bdf=0000:01:00.0
expected_user=vcdeagent1
expected_module_path=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
expected_loader_path=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
pinned_module=$expected_module_path
expected_module_sha=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
accepted_loader=$expected_loader_path
expected_loader_sha=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
bar_parser_b64=${1:?BAR parser payload required}
expected_bar_parser_sha=${2:?BAR parser SHA required}
expected_module_sha=${expected_module_sha,,}
expected_loader_sha=${expected_loader_sha,,}

fail() {
  printf 'HOST_PREFLIGHT_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

hex_file() {
  local value
  value=$(< "$1")
  printf '%s' "${value#0x}"
}

printf 'REMOTE_USER=%s\n' "${SUDO_USER:-UNKNOWN}"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
printf 'HOSTNAME=%s\n' "$(hostname)"
printf 'CURRENT_BOOT_ID=%s\n' "$(< /proc/sys/kernel/random/boot_id)"
printf 'CURRENT_KERNEL=%s\n' "$(uname -r)"
printf 'UPTIME_START=%s\n' "$(uptime -s)"
printf 'PROC_CMDLINE=%s\n' "$(< /proc/cmdline)"
[[ ${SUDO_USER:-} == "$expected_user" && $(id -un) == root ]] || fail REMOTE_USER_OR_PRIVILEGE 69

current_kernel=$(uname -r)
[[ $current_kernel == "$expected_kernel" ]] || fail CURRENT_KERNEL 71
boot_image=$(sed -n 's/.*BOOT_IMAGE=\([^ ]*\).*/\1/p' /proc/cmdline)
printf 'PROC_CMDLINE_BOOT_IMAGE=%s\n' "${boot_image:-NOT_FOUND}"
[[ $boot_image == *vmlinuz-7.0.0-29-generic* ]] || fail PROC_CMDLINE_BOOT_IMAGE 72
[[ -d /lib/modules/$expected_kernel ]] || fail MODULE_DIRECTORY 73
printf 'EXPECTED_MODULE_DIRECTORY=/lib/modules/%s\n' "$expected_kernel"
printf 'EXPECTED_MODULE_DIRECTORY_PRESENT=YES\n'

[[ -f $pinned_module && -f $accepted_loader ]] || fail PINNED_FILE_MISSING 74
[[ $pinned_module == "$expected_module_path" && $accepted_loader == "$expected_loader_path" ]] || fail PINNED_LITERAL_PATH 74
[[ ! -L $pinned_module && ! -L $accepted_loader ]] || fail PINNED_PATH_SYMLINK 74
[[ $(realpath -- "$pinned_module") == "$expected_module_path" && $(realpath -- "$accepted_loader") == "$expected_loader_path" ]] || fail PINNED_REALPATH 74
actual_module_sha=$(sha256sum -- "$pinned_module" | awk '{print tolower($1)}')
actual_loader_sha=$(sha256sum -- "$accepted_loader" | awk '{print tolower($1)}')
module_version=$(modinfo -F version -- "$pinned_module" 2>/dev/null || true)
module_vermagic=$(modinfo -F vermagic -- "$pinned_module" 2>/dev/null || true)
module_srcversion=$(modinfo -F srcversion -- "$pinned_module" 2>/dev/null || true)
loader_mode=$(stat -Lc '%a' -- "$accepted_loader")
printf 'PINNED_MODULE_PATH=%s\n' "$pinned_module"
printf 'PINNED_MODULE_SHA256=%s\n' "${actual_module_sha^^}"
printf 'PINNED_MODULE_VERSION=%s\n' "$module_version"
printf 'PINNED_MODULE_VERMAGIC=%s\n' "$module_vermagic"
printf 'PINNED_MODULE_SRCVERSION=%s\n' "$module_srcversion"
printf 'ACCEPTED_LOADER_PATH=%s\n' "$accepted_loader"
printf 'ACCEPTED_LOADER_SHA256=%s\n' "${actual_loader_sha^^}"
printf 'ACCEPTED_LOADER_MODE=%s\n' "$loader_mode"
[[ $actual_module_sha == "$expected_module_sha" ]] || fail MODULE_SHA 75
[[ $actual_loader_sha == "$expected_loader_sha" ]] || fail LOADER_SHA 76
[[ $module_version == 2025.2.0 ]] || fail MODULE_VERSION 77
[[ $module_vermagic == "$expected_kernel "* ]] || fail MODULE_VERMAGIC 78
[[ $loader_mode == 644 ]] || fail LOADER_MODE 79
printf 'CURRENT_KERNEL_EQUALS_PINNED_VERMAGIC=YES\n'

[[ -r /etc/default/grub && -r /boot/grub/grub.cfg ]] || fail GRUB_FILES 80
command -v grub-editenv >/dev/null 2>&1 || fail GRUB_EDITENV_TOOL 81
printf 'ACTIVE_BOOTLOADER=GRUB\n'
printf 'GRUB_DEFAULT_FILE_RELEVANT_BEGIN\n'
grep -E '^[[:space:]]*GRUB_(DEFAULT|SAVEDEFAULT|TIMEOUT_STYLE|TIMEOUT)=' /etc/default/grub || true
printf 'GRUB_DEFAULT_FILE_RELEVANT_END\n'
grub_default=$(sed -n 's/^[[:space:]]*GRUB_DEFAULT[[:space:]]*=[[:space:]]*//p' /etc/default/grub | tail -n 1)
grub_default=${grub_default%\"}
grub_default=${grub_default#\"}
grub_default=${grub_default%\'}
grub_default=${grub_default#\'}
grub_env=$(grub-editenv /boot/grub/grubenv list 2>/dev/null || grub-editenv list)
printf 'GRUB_ENV_BEGIN\n%s\nGRUB_ENV_END\n' "$grub_env"
saved_entry=$(printf '%s\n' "$grub_env" | awk -F= '$1=="saved_entry" {sub(/^[^=]*=/,""); print; exit}')
next_entry=$(printf '%s\n' "$grub_env" | awk -F= '$1=="next_entry" {sub(/^[^=]*=/,""); print; exit}')
printf 'GRUB_DEFAULT_NORMALIZED=%s\n' "${grub_default:-NOT_SET}"
printf 'GRUB_SAVED_ENTRY=%s\n' "${saved_entry:-NONE}"
printf 'GRUB_NEXT_ENTRY=%s\n' "${next_entry:-NONE}"
printf 'GRUB_KERNEL29_MENU_ENTRIES_BEGIN\n'
grep -nE "menuentry .*7\\.0\\.0-29-generic|submenu .*Advanced options" /boot/grub/grub.cfg || true
printf 'GRUB_KERNEL29_MENU_ENTRIES_END\n'

persistent_kernel29=NO
selected_entry=NONE
if [[ $grub_default == saved && $saved_entry == *7.0.0-29-generic* ]]; then
  persistent_kernel29=YES
  selected_entry=$saved_entry
elif [[ $grub_default == *7.0.0-29-generic* ]]; then
  persistent_kernel29=YES
  selected_entry=$grub_default
fi
printf 'PERSISTENT_DEFAULT_KERNEL29=%s\n' "$persistent_kernel29"
[[ $persistent_kernel29 == YES ]] || fail NEXT_REBOOT_DEFAULT_UNPROVEN 82
if [[ -n $next_entry && $next_entry != *7.0.0-29-generic* ]]; then
  fail NEXT_ENTRY_OTHER_KERNEL 83
fi
printf 'NEXT_ENTRY_SELECTS_OTHER_KERNEL=NO\n'
selected_leaf=${selected_entry##*>}
selected_line=$(grep -nF -- "$selected_leaf" /boot/grub/grub.cfg | grep -E "menuentry .*7\\.0\\.0-29-generic" | head -n 1 | cut -d: -f1 || true)
[[ $selected_line =~ ^[0-9]+$ ]] || fail SELECTED_GRUB_ENTRY_NOT_FOUND 83
selected_block=$(sed -n "${selected_line},$((selected_line + 40))p" /boot/grub/grub.cfg)
printf 'GRUB_SELECTED_ENTRY_BLOCK_BEGIN\n%s\nGRUB_SELECTED_ENTRY_BLOCK_END\n' "$selected_block"
printf '%s\n' "$selected_block" | grep -Eq '^[[:space:]]*linux[[:space:]].*/vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' || fail SELECTED_GRUB_LINUX_IMAGE 83
printf 'NEXT_REBOOT_KERNEL_PROVEN=7.0.0-29-generic\n'

for evidence_dir in \
  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r4/bootstrap_driver \
  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r4/arm_a_driver \
  /home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r4/arm_b_driver; do
  state=ABSENT_FRESH
  if [[ -e $evidence_dir ]]; then
    [[ -d $evidence_dir ]] || fail DRIVER_EVIDENCE_PATH_NOT_DIRECTORY 83
    [[ -z $(find "$evidence_dir" -mindepth 1 -maxdepth 1 -print -quit) ]] || fail DRIVER_EVIDENCE_PATH_NOT_EMPTY 83
    state=PRESENT_EMPTY
  fi
  printf 'FRESH_DRIVER_EVIDENCE_DIRECTORY=%s STATE=%s\n' "$evidence_dir" "$state"
done

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
[[ ${#endpoints[@]} -eq 1 && ${endpoints[0]} == "$expected_bdf" ]] || fail ENDPOINT_COUNT_OR_BDF 84
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
[[ $vendor:$device == 10ee:7011 && $subvendor:$subdevice == 10ee:0007 && $class == 058000 ]] || fail ENDPOINT_IDENTITY 85
speed=$(< "$dev/current_link_speed")
width=$(< "$dev/current_link_width")
printf 'CURRENT_LINK_SPEED_RAW=%s\n' "$speed"
printf 'CURRENT_LINK_WIDTH_RAW=%s\n' "$width"
[[ $speed == 2.5* && $width == 1 ]] || fail ENDPOINT_LINK 86
printf 'ENDPOINT_LINK=GEN1_X1\n'
printf 'PCI_RESOURCE_RAW_BEGIN\n'
cat -- "$dev/resource"
printf 'PCI_RESOURCE_RAW_END\n'
actual_bar_parser_sha=$(printf '%s' "$bar_parser_b64" | /usr/bin/base64 -d | sha256sum | awk '{print toupper($1)}')
printf 'BAR_PARSER_REMOTE_SHA256=%s\n' "$actual_bar_parser_sha"
[[ $actual_bar_parser_sha == ${expected_bar_parser_sha^^} ]] || fail BAR_PARSER_SHA 87
bar_output=$(printf '%s' "$bar_parser_b64" | /usr/bin/base64 -d | /usr/bin/python3 - --bdf "$bdf") || fail BAR_PARSER_EXECUTION 87
printf 'BAR_PARSER_OUTPUT_BEGIN\n%s\nBAR_PARSER_OUTPUT_END\n' "$bar_output"
bar0=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR0_BYTES" {print $2; exit}')
bar1=$(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR1_BYTES" {print $2; exit}')
printf 'BAR0_BYTES=%s\nBAR1_BYTES=%s\n' "$bar0" "$bar1"
[[ $bar0 == 131072 && $bar1 == 65536 ]] || fail BAR_GEOMETRY 88
printf 'RESOURCE0_STAT_BYTES=%s\n' "$(stat -Lc '%s' -- "$dev/resource0" 2>/dev/null || printf NOT_AVAILABLE)"
printf 'RESOURCE1_STAT_BYTES=%s\n' "$(stat -Lc '%s' -- "$dev/resource1" 2>/dev/null || printf NOT_AVAILABLE)"
printf 'LSPCI_RAW_BEGIN\n'
lspci -Dnnvv -s "$bdf"
printf 'LSPCI_RAW_END\n'

if [[ -L $dev/driver ]]; then
  endpoint_driver=$(basename "$(readlink -f -- "$dev/driver")")
else
  endpoint_driver=ABSENT
fi
printf 'ENDPOINT_BOUND_DRIVER=%s\n' "$endpoint_driver"
loaded=NO
if [[ -d /sys/module/xdma ]]; then loaded=YES; fi
printf 'XDMA_MODULE_PRESENT=%s\n' "$loaded"
mapfile -t observed_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
mapfile -t expected_nodes < <(printf '%s\n' xdma0_user xdma0_control xdma0_c2h_0 xdma0_h2c_0 xdma0_xvc xdma0_events_{0..15} | sort)
observed_csv=$(printf '%s\n' "${observed_nodes[@]}" | sed '/^$/d' | paste -sd, -)
expected_csv=$(printf '%s\n' "${expected_nodes[@]}" | paste -sd, -)
printf 'XDMA_NODE_COUNT=%s\n' "${#observed_nodes[@]}"
printf 'XDMA_NODE_LIST=%s\n' "${observed_csv:-NONE}"
printf 'XDMA_EXPECTED_NODE_LIST=%s\n' "$expected_csv"

if [[ $loaded == YES ]]; then
  loaded_version=$(< /sys/module/xdma/version 2>/dev/null || true)
  loaded_srcversion=$(< /sys/module/xdma/srcversion 2>/dev/null || true)
  printf 'XDMA_LOADED_VERSION=%s\n' "$loaded_version"
  printf 'XDMA_LOADED_SRCVERSION=%s\n' "$loaded_srcversion"
  [[ $endpoint_driver == xdma ]] || fail LOADED_XDMA_NOT_BOUND 89
  [[ $loaded_version == 2025.2.0 && ${loaded_srcversion^^} == ${module_srcversion^^} ]] || fail WRONG_SAME_NAME_XDMA 90
  [[ $observed_csv == "$expected_csv" ]] || fail XDMA_NODE_SET 91
  printf 'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO\n'
  printf 'PRE_ARM_A_DRIVER_LOAD_REQUIRED=NO\n'
else
  [[ $endpoint_driver == ABSENT && ${#observed_nodes[@]} -eq 0 ]] || fail ABSENT_MODULE_STATE_INCOHERENT 92
  printf 'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO\n'
  printf 'PRE_ARM_A_DRIVER_LOAD_REQUIRED=YES\n'
fi

open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
if [[ -n $open_pids ]]; then
  printf 'XDMA_OPEN_PROCESS_COUNT=%s\nXDMA_OPEN_PIDS=%s\n' "$(tr ',' '\n' <<< "$open_pids" | wc -l)" "$open_pids"
  fail XDMA_NODE_OWNER 93
fi
printf 'XDMA_OPEN_PROCESS_COUNT=0\nXDMA_OPEN_PIDS=NONE\n'
printf 'TASK_DMA_COMMANDS=0\n'
printf 'XDMA_INTERRUPT_ROWS_BEGIN\n'
grep -i xdma /proc/interrupts 2>/dev/null || true
printf 'XDMA_INTERRUPT_ROWS_END\n'
critical_matches=$(journalctl -b -k --no-pager 2>/dev/null | grep -Ei 'AER:.*(fatal|non-fatal|uncorrected)|pcieport.*AER.*error|xdma.*(fail|error)|unknown symbol|probe.*fail' || true)
critical_count=$(if [[ -n $critical_matches ]]; then printf '%s\n' "$critical_matches" | wc -l; else printf 0; fi)
printf 'TARGETED_KERNEL_CRITICAL_MATCH_COUNT=%s\n' "$critical_count"
printf 'TARGETED_KERNEL_CRITICAL_MATCHES_BEGIN\n%s\nTARGETED_KERNEL_CRITICAL_MATCHES_END\n' "$critical_matches"
[[ $critical_count -eq 0 ]] || fail KERNEL_AER_XDMA_HEALTH 94
printf 'KERNEL_AER_XDMA_HEALTH=PASS\n'
printf 'BAR_PARSER_AUTHORITY=PYTHON_INT_BASE_ZERO\n'
printf 'HOST_PREFLIGHT_READ_ONLY=YES\n'
printf 'HOST_PREFLIGHT_GATE=PASS\n'

accepted_reader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/xdma_axil_read
expected_reader_sha=808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E
[[ -x $accepted_reader ]] || fail ACCEPTED_READER_MISSING 95
actual_reader_sha=$(sha256sum -- "$accepted_reader" | awk '{print toupper($1)}')
printf 'ACCEPTED_READER_PATH=%s\n' "$accepted_reader"
printf 'ACCEPTED_READER_SHA256=%s\n' "$actual_reader_sha"
[[ $actual_reader_sha == "$expected_reader_sha" ]] || fail ACCEPTED_READER_SHA 95

/usr/bin/python3 - /dev/xdma0_user <<'PY'
import os, struct, sys
node = sys.argv[1]
offsets = {
    'BLOCK_ID': 0x0000,
    'PROTOCOL': 0x0004,
    'CAPABILITIES': 0x0008,
    'GIT_SHA_W0': 0x0010,
    'GIT_SHA_W1': 0x0014,
    'GIT_SHA_W2': 0x0018,
    'GIT_SHA_W3': 0x001C,
    'GIT_SHA_W4': 0x0020,
    'BUILD_FLAGS': 0x002C,
    'DIAGNOSTIC_MAGIC': 0x2000,
}
fd = os.open(node, os.O_RDONLY | os.O_CLOEXEC)
try:
    for name, offset in offsets.items():
        data = os.pread(fd, 4, offset)
        if len(data) != 4:
            raise RuntimeError(f'short pread at 0x{offset:08X}')
        value = struct.unpack('<I', data)[0]
        print(f'RAW_TASK_READER_{name}=0x{value:08X}')
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
