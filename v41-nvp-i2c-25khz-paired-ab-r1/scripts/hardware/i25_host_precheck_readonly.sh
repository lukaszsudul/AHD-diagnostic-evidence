#!/usr/bin/env bash
# Read-only DUT state collector. Intended to run in one later authorized sudo
# transaction. It performs no bind/unbind, module action, PCI reset/rescan,
# MMIO, DMA, reboot, or filesystem write.

set -euo pipefail

expected_bdf=0000:01:00.0
pinned_module=${1:?exact pinned module path required}
expected_module_sha=${2:?expected pinned module SHA-256 required}
accepted_loader=${3:?exact accepted loader path required}
expected_loader_sha=${4:?expected accepted loader SHA-256 required}
expected_module_sha=${expected_module_sha,,}
expected_loader_sha=${expected_loader_sha,,}

hex_file() {
  local path=$1
  local value
  value=$(< "$path")
  printf '%s' "${value#0x}"
}

bar_size() {
  local index=$1
  local start end flags
  read -r start end flags < <(sed -n "$((index + 1))p" "/sys/bus/pci/devices/$expected_bdf/resource")
  if [[ -z ${start:-} || -z ${end:-} || $start == 0000000000000000 && $end == 0000000000000000 ]]; then
    printf '0'
  else
    printf '%s' "$((16#$end - 16#$start + 1))"
  fi
}

printf 'REMOTE_USER=%s\n' "${SUDO_USER:-$(id -un)}"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
printf 'HOSTNAME=%s\n' "$(hostname)"
printf 'CURRENT_BOOT_ID=%s\n' "$(< /proc/sys/kernel/random/boot_id)"
printf 'CURRENT_KERNEL=%s\n' "$(uname -r)"
printf 'UPTIME_START=%s\n' "$(uptime -s)"

if [[ ! -f $pinned_module || ! -f $accepted_loader ]]; then
  printf 'PINNED_ARTIFACT_GATE=FAIL_MISSING_FILE\n'
  exit 39
fi
actual_module_sha=$(sha256sum -- "$pinned_module" | awk '{print tolower($1)}')
actual_loader_sha=$(sha256sum -- "$accepted_loader" | awk '{print tolower($1)}')
printf 'PINNED_XDMA_ARTIFACT_PATH=%s\n' "$pinned_module"
printf 'PINNED_XDMA_ARTIFACT_SHA256=%s\n' "${actual_module_sha^^}"
printf 'ACCEPTED_XDMA_LOADER_PATH=%s\n' "$accepted_loader"
printf 'ACCEPTED_XDMA_LOADER_SHA256=%s\n' "${actual_loader_sha^^}"
if [[ $actual_module_sha != "$expected_module_sha" || $actual_loader_sha != "$expected_loader_sha" ]]; then
  printf 'PINNED_ARTIFACT_GATE=FAIL_SHA256\n'
  exit 39
fi
printf 'PINNED_ARTIFACT_GATE=PASS\n'
printf 'PINNED_MODULE_VERSION=%s\n' "$(modinfo -F version -- "$pinned_module" 2>/dev/null || true)"
printf 'PINNED_MODULE_VERMAGIC=%s\n' "$(modinfo -F vermagic -- "$pinned_module" 2>/dev/null || true)"
printf 'PINNED_MODULE_SIGNER=%s\n' "$(modinfo -F signer -- "$pinned_module" 2>/dev/null || true)"
printf 'PINNED_MODULE_SRCVERSION=%s\n' "$(modinfo -F srcversion -- "$pinned_module" 2>/dev/null || true)"

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

if [[ ${#endpoints[@]} -ne 1 || ${endpoints[0]} != "$expected_bdf" ]]; then
  printf 'ENDPOINT_GATE=FAIL_COUNT_OR_BDF\n'
  exit 40
fi

dev="/sys/bus/pci/devices/$expected_bdf"
vendor=$(hex_file "$dev/vendor")
device=$(hex_file "$dev/device")
subvendor=$(hex_file "$dev/subsystem_vendor")
subdevice=$(hex_file "$dev/subsystem_device")
class=$(hex_file "$dev/class")
printf 'ENDPOINT_BDF=%s\n' "$expected_bdf"
printf 'ENDPOINT_VENDOR_DEVICE=%s:%s\n' "$vendor" "$device"
printf 'ENDPOINT_SUBSYSTEM=%s:%s\n' "$subvendor" "$subdevice"
printf 'ENDPOINT_CLASS=%s\n' "$class"

speed=$(< "$dev/current_link_speed")
width=$(< "$dev/current_link_width")
printf 'CURRENT_LINK_SPEED_RAW=%s\n' "$speed"
printf 'CURRENT_LINK_WIDTH_RAW=%s\n' "$width"
if [[ $speed == 2.5* && $width == 1 ]]; then
  printf 'ENDPOINT_LINK=GEN1_X1\n'
else
  printf 'ENDPOINT_LINK=UNEXPECTED\n'
fi

printf 'BAR0_BYTES=%s\n' "$(bar_size 0)"
printf 'BAR1_BYTES=%s\n' "$(bar_size 1)"

if [[ -L $dev/driver ]]; then
  driver_path=$(readlink -f -- "$dev/driver")
  printf 'ENDPOINT_BOUND_DRIVER=%s\n' "$(basename "$driver_path")"
  printf 'ENDPOINT_DRIVER_PATH=%s\n' "$driver_path"
else
  printf 'ENDPOINT_BOUND_DRIVER=ABSENT\n'
  printf 'ENDPOINT_DRIVER_PATH=ABSENT\n'
fi
printf 'DRIVER_OVERRIDE_RAW=%s\n' "$(tr -d '\000\n' < "$dev/driver_override" 2>/dev/null || true)"

if [[ -d /sys/module/xdma ]]; then
  printf 'XDMA_MODULE_PRESENT=YES\n'
  if [[ -r /sys/module/xdma/version ]]; then
    printf 'XDMA_LOADED_VERSION=%s\n' "$(< /sys/module/xdma/version)"
  else
    printf 'XDMA_LOADED_VERSION=NOT_EXPOSED\n'
  fi
  awk '$1 == "xdma" { printf "XDMA_PROC_MODULES_SIZE=%s\nXDMA_PROC_MODULES_REFCNT=%s\nXDMA_PROC_MODULES_STATE=%s\n", $2, $3, $5 }' /proc/modules
  for property in srcversion taint refcnt; do
    if [[ -r /sys/module/xdma/$property ]]; then
      printf 'XDMA_SYS_MODULE_%s=%s\n' "${property^^}" "$(< "/sys/module/xdma/$property")"
    fi
  done
  printf 'XDMA_MODULE_SEARCH_PATH=%s\n' "$(modinfo -n xdma 2>/dev/null || true)"
  printf 'XDMA_MODULE_SEARCH_VERSION=%s\n' "$(modinfo -F version xdma 2>/dev/null || true)"
  printf 'XDMA_BOUND_DEVICE_LIST=%s\n' "$(find /sys/bus/pci/drivers/xdma -maxdepth 1 -type l -printf '%f\n' 2>/dev/null | sort | paste -sd, -)"
  printf 'LOADED_XDMA_PROVENANCE=REVIEW_REQUIRED_PREEXISTENCE_PLUS_EXACT_ACCEPTED_LOAD_CHAIN\n'
else
  printf 'XDMA_MODULE_PRESENT=NO\n'
  printf 'LOADED_XDMA_PROVENANCE=FAIL_MODULE_ABSENT\n'
fi

for spec in XDMA_USER:/dev/xdma0_user XDMA_CONTROL:/dev/xdma0_control; do
  key=${spec%%:*}
  node=${spec#*:}
  if [[ -c $node ]]; then
    printf '%s_NODE=CHARACTER_DEVICE\n' "$key"
    stat -Lc "${key}_MAJOR_MINOR=%t:%T ${key}_MODE=%a ${key}_OWNER=%U:${key}_GROUP=%G" "$node"
  elif [[ -e $node ]]; then
    printf '%s_NODE=PRESENT_NOT_CHARACTER_DEVICE\n' "$key"
  else
    printf '%s_NODE=ABSENT\n' "$key"
  fi
done

mapfile -t all_xdma_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
mapfile -t expected_xdma_nodes < <(
  printf '%s\n' \
    xdma0_user xdma0_control xdma0_c2h_0 xdma0_h2c_0 xdma0_xvc \
    xdma0_events_0 xdma0_events_1 xdma0_events_2 xdma0_events_3 \
    xdma0_events_4 xdma0_events_5 xdma0_events_6 xdma0_events_7 \
    xdma0_events_8 xdma0_events_9 xdma0_events_10 xdma0_events_11 \
    xdma0_events_12 xdma0_events_13 xdma0_events_14 xdma0_events_15 | sort
)
observed_nodes_csv=$(printf '%s\n' "${all_xdma_nodes[@]}" | paste -sd, -)
expected_nodes_csv=$(printf '%s\n' "${expected_xdma_nodes[@]}" | paste -sd, -)
printf 'XDMA_ALL_NODE_COUNT=%s\n' "${#all_xdma_nodes[@]}"
printf 'XDMA_ALL_NODE_LIST=%s\n' "$(if [[ ${#all_xdma_nodes[@]} -gt 0 ]]; then printf '%s' "$observed_nodes_csv"; else printf NONE; fi)"
printf 'XDMA_EXPECTED_NODE_COUNT=%s\n' "${#expected_xdma_nodes[@]}"
printf 'XDMA_EXPECTED_NODE_LIST=%s\n' "$expected_nodes_csv"
for node_name in "${all_xdma_nodes[@]}"; do
  node_path="/dev/$node_name"
  stat -Lc 'XDMA_NODE=%n TYPE=%F MAJOR_MINOR=%t:%T MODE=%a OWNER=%U GROUP=%G' "$node_path"
done
if [[ $observed_nodes_csv == "$expected_nodes_csv" ]]; then
  printf 'XDMA_ALL_NODES_CLASSIFICATION=PASS_EXACT_ACCEPTED_21_NODE_SET\n'
else
  printf 'XDMA_ALL_NODES_CLASSIFICATION=FAIL_UNEXPECTED_OR_MISSING_NODE\n'
fi
printf 'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=REVIEW_REQUIRED_WITH_CONTINUITY_AND_LOADER_EVIDENCE\n'

open_pids=$(
  find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
if [[ -n $open_pids ]]; then
  printf 'XDMA_OPEN_PROCESS_COUNT=%s\n' "$(tr ',' '\n' <<< "$open_pids" | wc -l)"
  printf 'XDMA_OPEN_PIDS=%s\n' "$open_pids"
else
  printf 'XDMA_OPEN_PROCESS_COUNT=0\n'
  printf 'XDMA_OPEN_PIDS=NONE\n'
fi
printf 'XDMA_INTERRUPT_ROWS_BEGIN\n'
grep -i 'xdma' /proc/interrupts 2>/dev/null || true
printf 'XDMA_INTERRUPT_ROWS_END\n'
printf 'DMA_NODE_EXISTENCE_IS_ACTIVITY=NO\n'
printf 'DMA_ACTIVITY=REVIEW_REQUIRED_REQUIRE_ZERO_OPEN_NODE_OWNERS_AND_ZERO_TASK_DMA_COMMANDS\n'

# Preserve targeted evidence for a human/fail-closed reviewer. Automatic grep
# count alone is not sufficient to declare kernel health PASS.
kernel_matches=$(journalctl -b -k --no-pager 2>/dev/null | grep -Ei \
  'AER:.*(fatal|non-fatal|uncorrected)|xdma.*(fail|error)|unknown symbol|module verification.*fail|probe.*fail' || true)
printf 'TARGETED_KERNEL_MATCH_COUNT=%s\n' "$(if [[ -n $kernel_matches ]]; then printf '%s\n' "$kernel_matches" | wc -l; else printf 0; fi)"
printf 'TARGETED_KERNEL_MATCHES_BEGIN\n%s\nTARGETED_KERNEL_MATCHES_END\n' "$kernel_matches"
printf 'KERNEL_AER_XDMA_HEALTH=REVIEW_REQUIRED\n'
printf 'MANUAL_REVIEW_REQUIRED_FIELDS=LOADED_XDMA_PROVENANCE,XDMA_ALL_NODES_CLASSIFICATION,DMA_ACTIVITY,KERNEL_AER_XDMA_HEALTH,WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND\n'
printf 'HOST_PRECHECK_READ_ONLY=YES\n'
