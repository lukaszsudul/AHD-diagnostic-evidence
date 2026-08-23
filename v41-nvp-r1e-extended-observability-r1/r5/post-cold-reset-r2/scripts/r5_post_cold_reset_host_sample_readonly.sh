#!/usr/bin/env bash
# One R5 post-cold-reset host-stability sample. Read-only and non-privileged.

set -euo pipefail

sample_index=${1:?sample index required}
expected_user=vcdeagent1
expected_kernel=7.0.0-29-generic

case "$sample_index" in
  1|2|3) ;;
  *) printf 'HOST_STABILITY_SAMPLE_GATE=FAIL_SAMPLE_INDEX\n'; exit 64 ;;
esac

hostname_value=$(hostname)
user_value=$(id -un)
kernel_value=$(uname -r)
boot_id=$(cat -- /proc/sys/kernel/random/boot_id)
uptime_seconds=$(awk '{print $1}' /proc/uptime)
utc=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)

[[ -n $hostname_value ]] || { printf 'HOST_STABILITY_SAMPLE_GATE=FAIL_HOSTNAME\n'; exit 65; }
[[ $user_value == "$expected_user" ]] || { printf 'HOST_STABILITY_SAMPLE_GATE=FAIL_USER\n'; exit 66; }
[[ $kernel_value == "$expected_kernel" ]] || { printf 'HOST_STABILITY_SAMPLE_GATE=FAIL_KERNEL\n'; exit 67; }
[[ $boot_id =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || {
  printf 'HOST_STABILITY_SAMPLE_GATE=FAIL_BOOT_ID\n'; exit 68;
}
[[ $uptime_seconds =~ ^[0-9]+([.][0-9]+)?$ ]] || {
  printf 'HOST_STABILITY_SAMPLE_GATE=FAIL_UPTIME\n'; exit 69;
}

printf 'HOST_STABILITY_SAMPLE_INDEX=%s\n' "$sample_index"
printf 'HOSTNAME=%s\n' "$hostname_value"
printf 'REMOTE_USER=%s\n' "$user_value"
printf 'CURRENT_KERNEL=%s\n' "$kernel_value"
printf 'CURRENT_BOOT_ID=%s\n' "$boot_id"
printf 'UPTIME_SECONDS=%s\n' "$uptime_seconds"
printf 'REMOTE_UTC=%s\n' "$utc"
printf 'HOST_STABILITY_SAMPLE_READ_ONLY=YES\n'
printf 'HOST_STABILITY_SAMPLE_GATE=PASS\n'
