#!/usr/bin/env bash
# One R6 host-baseline sample. This is a privileged but strictly read-only
# inventory because the next-boot proof requires reading the GRUB state.

set -euo pipefail

sample_index=${1:?sample index required}
expected_user=vcdeagent1
expected_kernel=7.0.0-29-generic

fail() {
  printf 'HOST_BASELINE_SAMPLE_GATE=FAIL_%s\n' "$1"
  exit "${2:-70}"
}

case "$sample_index" in
  1|2|3) ;;
  *) fail SAMPLE_INDEX 64 ;;
esac

[[ $(id -un) == root && ${SUDO_USER:-} == "$expected_user" ]] || fail REMOTE_USER_OR_PRIVILEGE 65

hostname_value=$(hostname)
kernel_value=$(uname -r)
boot_id=$(cat -- /proc/sys/kernel/random/boot_id)
uptime_seconds=$(awk '{print $1}' /proc/uptime)
utc=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)

[[ -n $hostname_value ]] || fail HOSTNAME 66
[[ $kernel_value == "$expected_kernel" ]] || fail CURRENT_KERNEL 67
[[ $boot_id =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || fail BOOT_ID 68
[[ $uptime_seconds =~ ^[0-9]+([.][0-9]+)?$ ]] || fail UPTIME 69
grep -Eq '(^|[[:space:]])BOOT_IMAGE=[^ ]*vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' /proc/cmdline || fail BOOT_IMAGE 70
[[ -d /lib/modules/$expected_kernel ]] || fail MODULE_DIRECTORY 71

[[ -r /etc/default/grub && -r /boot/grub/grub.cfg ]] || fail GRUB_FILES 72
command -v grub-editenv >/dev/null 2>&1 || fail GRUB_EDITENV_TOOL 73
grub_default=$(sed -n 's/^[[:space:]]*GRUB_DEFAULT[[:space:]]*=[[:space:]]*//p' /etc/default/grub | tail -n 1)
grub_default=${grub_default%\"}; grub_default=${grub_default#\"}
grub_default=${grub_default%\'}; grub_default=${grub_default#\'}
grub_env=$(grub-editenv /boot/grub/grubenv list)
saved_entry=$(printf '%s\n' "$grub_env" | awk -F= '$1=="saved_entry" {sub(/^[^=]*=/,""); print; exit}')
next_entry=$(printf '%s\n' "$grub_env" | awk -F= '$1=="next_entry" {sub(/^[^=]*=/,""); print; exit}')

selected_entry=NONE
selection_source=NONE
if [[ -n $next_entry ]]; then
  [[ $next_entry == *7.0.0-29-generic* ]] || fail NEXT_ENTRY_OTHER_KERNEL 74
  selected_entry=$next_entry
  selection_source=ONE_SHOT_NEXT_ENTRY
elif [[ $grub_default == saved && $saved_entry == *7.0.0-29-generic* ]]; then
  selected_entry=$saved_entry
  selection_source=PERSISTENT_SAVED_ENTRY
elif [[ $grub_default == *7.0.0-29-generic* ]]; then
  selected_entry=$grub_default
  selection_source=PERSISTENT_EXPLICIT_ENTRY
else
  fail NEXT_REBOOT_DEFAULT_UNPROVEN 75
fi

selected_leaf=${selected_entry##*>}
selected_line=$(grep -nF -- "$selected_leaf" /boot/grub/grub.cfg | grep -E 'menuentry .*7\.0\.0-29-generic' | head -n 1 | cut -d: -f1 || true)
[[ $selected_line =~ ^[0-9]+$ ]] || fail SELECTED_GRUB_ENTRY_NOT_FOUND 76
selected_block=$(sed -n "${selected_line},$((selected_line + 40))p" /boot/grub/grub.cfg)
printf '%s\n' "$selected_block" | grep -Eq '^[[:space:]]*linux[[:space:]].*/vmlinuz-7\.0\.0-29-generic([[:space:]]|$)' || fail SELECTED_GRUB_LINUX_IMAGE 77

printf 'HOST_BASELINE_SAMPLE_INDEX=%s\n' "$sample_index"
printf 'HOSTNAME=%s\n' "$hostname_value"
printf 'REMOTE_USER=%s\n' "${SUDO_USER}"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
printf 'CURRENT_KERNEL=%s\n' "$kernel_value"
printf 'CURRENT_BOOT_ID=%s\n' "$boot_id"
printf 'UPTIME_SECONDS=%s\n' "$uptime_seconds"
printf 'REMOTE_UTC=%s\n' "$utc"
printf 'PROC_CMDLINE=%s\n' "$(cat -- /proc/cmdline)"
printf 'GRUB_DEFAULT_NORMALIZED=%s\n' "${grub_default:-NOT_SET}"
printf 'GRUB_SAVED_ENTRY=%s\n' "${saved_entry:-NONE}"
printf 'GRUB_NEXT_ENTRY=%s\n' "${next_entry:-NONE}"
printf 'NEXT_BOOT_SELECTION_SOURCE=%s\n' "$selection_source"
printf 'NEXT_BOOT_SELECTED_ENTRY=%s\n' "$selected_entry"
printf 'NEXT_REBOOT_KERNEL_PROVEN=%s\n' "$expected_kernel"
printf 'HOST_BASELINE_SAMPLE_READ_ONLY=YES\n'
printf 'HOST_BASELINE_SAMPLE_GATE=PASS\n'
