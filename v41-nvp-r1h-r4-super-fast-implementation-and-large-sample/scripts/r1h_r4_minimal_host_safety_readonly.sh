#!/usr/bin/env bash
# R1h-R4 minimal pre-bootstrap host gate. Read-only by construction.
set -euo pipefail

expected_kernel=7.0.0-29-generic
expected_user=vcdeagent1
pinned_module=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
accepted_loader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
expected_module_sha=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
expected_loader_sha=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F

fail() {
  printf 'R1H_R4_HOST_SAFETY_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

printf 'DISCOVERY_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
printf 'REMOTE_SUDO_USER=%s\n' "${SUDO_USER:-UNKNOWN}"
[[ $(id -un) == root && ${SUDO_USER:-} == "$expected_user" ]] || fail REMOTE_USER_OR_PRIVILEGE 69

kernel=$(uname -r)
printf 'CURRENT_KERNEL=%s\n' "$kernel"
printf 'CURRENT_BOOT_ID=%s\n' "$(cat -- /proc/sys/kernel/random/boot_id)"
printf 'PROC_CMDLINE=%s\n' "$(cat -- /proc/cmdline)"
[[ $kernel == "$expected_kernel" ]] || fail CURRENT_KERNEL 71
grep -Eq '(^|[[:space:]])BOOT_IMAGE=[^ ]*vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' /proc/cmdline || fail BOOT_IMAGE 72
[[ -d /lib/modules/$expected_kernel ]] || fail MODULE_DIRECTORY 73

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

[[ -r /etc/default/grub && -r /boot/grub/grub.cfg ]] || fail GRUB_FILES 78
command -v grub-editenv >/dev/null 2>&1 || fail GRUB_EDITENV_TOOL 79
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
if [[ $grub_default == saved && $saved_entry == *7.0.0-29-generic* ]]; then
  persistent_kernel29=YES
elif [[ $grub_default == *7.0.0-29-generic* ]]; then
  persistent_kernel29=YES
fi
[[ $persistent_kernel29 == YES ]] || fail NEXT_REBOOT_DEFAULT_UNPROVEN 80
if [[ -n $next_entry && $next_entry != *7.0.0-29-generic* ]]; then fail NEXT_ENTRY_OTHER_KERNEL 81; fi
printf 'NEXT_REBOOT_KERNEL_PROVEN=%s\n' "$expected_kernel"

open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
printf 'XDMA_OPEN_PIDS=%s\n' "${open_pids:-NONE}"
[[ -z $open_pids ]] || fail XDMA_NODE_OWNER 82
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
[[ $critical_count -eq 0 ]] || fail KERNEL_AER_XDMA_HEALTH 83
printf 'KERNEL_AER_XDMA_HEALTH=PASS\n'
printf 'MMIO_READS=0\n'
printf 'MMIO_WRITES=0\n'
printf 'DMA_TRANSFERS=0\n'
printf 'HOST_SAFETY_DISCOVERY_READ_ONLY=YES\n'
printf 'R1H_R4_HOST_SAFETY_GATE=PASS\n'
