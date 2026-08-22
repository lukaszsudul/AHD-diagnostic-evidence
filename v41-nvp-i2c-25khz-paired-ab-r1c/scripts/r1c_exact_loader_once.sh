#!/usr/bin/env bash
# Exact one-shot pinned XDMA loader for the three R1c authorized roles.

set -euo pipefail

[[ $# -eq 3 ]] || { printf 'LOADER_RESULT=FAIL_ARGUMENT_COUNT\n'; exit 59; }
role=$1
parser_b64=$2
parser_sha=$3
kernel=7.0.0-29-generic
module=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
module_sha=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
loader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
loader_sha=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
bdf=0000:01:00.0
expected_parser_sha=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922

case "$role" in
  PRE_ARM_A) evidence=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_i2c_25khz_r1c/pre_arm_a_driver ;;
  ARM_A) evidence=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_i2c_25khz_r1c/arm_a_driver ;;
  ARM_B) evidence=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_i2c_25khz_r1c/arm_b_driver ;;
  *) printf 'LOADER_RESULT=FAIL_ROLE\n'; exit 60 ;;
esac

fail() {
  printf 'LOADER_RESULT=FAIL_%s\n' "$1"
  exit "${2:-61}"
}

printf 'LOADER_ROLE=%s\n' "$role"
printf 'REMOTE_USER=%s\n' "${SUDO_USER:-UNKNOWN}"
printf 'REMOTE_EFFECTIVE_USER=%s\n' "$(id -un)"
[[ ${SUDO_USER:-} == vcdeagent1 && $(id -un) == root ]] || fail USER_OR_PRIVILEGE
[[ $(uname -r) == "$kernel" ]] || fail KERNEL
[[ -f $module && -f $loader && ! -L $module && ! -L $loader ]] || fail PINNED_FILES
[[ $(realpath -- "$module") == "$module" && $(realpath -- "$loader") == "$loader" ]] || fail PINNED_REALPATH
actual_module_sha=$(sha256sum -- "$module" | awk '{print toupper($1)}')
actual_loader_sha=$(sha256sum -- "$loader" | awk '{print toupper($1)}')
vermagic=$(modinfo -F vermagic -- "$module")
version=$(modinfo -F version -- "$module")
srcversion=$(modinfo -F srcversion -- "$module")
mode=$(stat -Lc '%a' -- "$loader")
printf 'EXPLICIT_MODULE_PATH=%s\n' "$module"
printf 'MODULE_SHA256=%s\n' "$actual_module_sha"
printf 'MODULE_VERSION=%s\n' "$version"
printf 'MODULE_VERMAGIC=%s\n' "$vermagic"
printf 'MODULE_SRCVERSION=%s\n' "$srcversion"
printf 'EXPLICIT_LOADER_PATH=%s\n' "$loader"
printf 'LOADER_SHA256=%s\n' "$actual_loader_sha"
printf 'LOADER_MODE=%s\n' "$mode"
printf 'REMOTE_EVIDENCE_DIRECTORY=%s\n' "$evidence"
[[ $actual_module_sha == "$module_sha" && $actual_loader_sha == "$loader_sha" ]] || fail PINNED_SHA
[[ $version == 2025.2.0 && $vermagic == "$kernel "* && $mode == 644 ]] || fail MODULE_LOADER_PROPERTIES
[[ $parser_sha == "$expected_parser_sha" ]] || fail BAR_PARSER_ARGUMENT_SHA
[[ ! -e $evidence ]] || fail EVIDENCE_NOT_FRESH

mapfile -t endpoints < <(lspci -Dnn -d 10ee:7011)
[[ ${#endpoints[@]} -eq 1 && ${endpoints[0]%% *} == "$bdf" ]] || fail ENDPOINT
[[ ! -d /sys/module/xdma ]] || fail PREEXISTING_XDMA
[[ ! -L /sys/bus/pci/devices/$bdf/driver ]] || fail ENDPOINT_ALREADY_BOUND
if find /dev -maxdepth 1 -name 'xdma*' -print -quit 2>/dev/null | grep -q .; then fail STALE_NODES; fi
open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
[[ -z $open_pids ]] || fail NODE_OWNER
printf 'PRELOAD_GATE=PASS\n'
printf 'LOADER_COMMAND=/usr/bin/bash %s %s %s %s\n' "$loader" "$module" "$module_sha" "$evidence"
printf 'DRIVER_LOADER_INVOCATION_CONSUMED=1\n'
printf 'DRIVER_LOADER_START_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
set +e
/usr/bin/bash "$loader" "$module" "$module_sha" "$evidence"
loader_rc=$?
set -e
printf 'DRIVER_LOADER_EXIT_CODE=%s\n' "$loader_rc"
printf 'DRIVER_LOADER_END_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
[[ $loader_rc -eq 0 ]] || fail LOADER_EXIT

[[ -L /sys/bus/pci/devices/$bdf/driver ]] || fail DRIVER_NOT_BOUND
[[ $(basename "$(readlink -f -- /sys/bus/pci/devices/$bdf/driver)") == xdma ]] || fail WRONG_BOUND_DRIVER
[[ -d /sys/module/xdma ]] || fail MODULE_NOT_LOADED
[[ $(< /sys/module/xdma/version) == 2025.2.0 ]] || fail LOADED_VERSION
[[ $(< /sys/module/xdma/srcversion) == "$srcversion" ]] || fail LOADED_SRCVERSION
mapfile -t observed_nodes < <(find /dev -maxdepth 1 -name 'xdma*' -printf '%f\n' 2>/dev/null | sort)
mapfile -t expected_nodes < <(printf '%s\n' xdma0_user xdma0_control xdma0_c2h_0 xdma0_h2c_0 xdma0_xvc xdma0_events_{0..15} | sort)
observed_csv=$(printf '%s\n' "${observed_nodes[@]}" | sed '/^$/d' | paste -sd, -)
expected_csv=$(printf '%s\n' "${expected_nodes[@]}" | paste -sd, -)
printf 'XDMA_NODE_COUNT=%s\n' "${#observed_nodes[@]}"
printf 'XDMA_NODE_LIST=%s\n' "$observed_csv"
[[ $observed_csv == "$expected_csv" ]] || fail NODE_SET
open_pids=$(
  { find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null || true; } |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
[[ -z $open_pids ]] || fail POSTLOAD_NODE_OWNER
printf 'XDMA_OPEN_PROCESS_COUNT=0\n'
[[ -r $evidence/driver_load_gate.txt ]] || fail LOADER_GATE_FILE
grep -qx 'XDMA_DRIVER_LOAD=PASS' "$evidence/driver_load_gate.txt" || fail LOADER_GATE_PASS
grep -qx "XDMA_MODULE_SHA256=${module_sha,,}" "$evidence/driver_load_gate.txt" || fail LOADER_GATE_SHA
grep -qx 'XDMA_ENDPOINT_COUNT=1' "$evidence/driver_load_gate.txt" || fail LOADER_GATE_ENDPOINT_COUNT
grep -qx "XDMA_BDF=$bdf" "$evidence/driver_load_gate.txt" || fail LOADER_GATE_BDF
grep -qx 'PREEXISTING_XDMA_MODULE=NO' "$evidence/driver_load_gate.txt" || fail LOADER_GATE_PREEXISTING_MODULE
grep -qx 'XDMA_USER_NODE=/dev/xdma0_user' "$evidence/driver_load_gate.txt" || fail LOADER_GATE_USER_NODE

parser_path=$evidence/parse_pci_bars.py
printf '%s' "$parser_b64" | /usr/bin/base64 -d > "$parser_path" || fail BAR_PARSER_DECODE
actual_parser_sha=$(sha256sum -- "$parser_path" | awk '{print toupper($1)}')
printf 'BAR_PARSER_SHA256=%s\n' "$actual_parser_sha"
[[ $actual_parser_sha == "$expected_parser_sha" ]] || fail BAR_PARSER_REMOTE_SHA
bar_output=$(/usr/bin/python3 "$parser_path" --bdf "$bdf") || fail BAR_PARSER_EXECUTION
printf '%s\n' "$bar_output"
[[ $(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR0_BYTES"{print $2}') == 131072 ]] || fail BAR0_GEOMETRY
[[ $(printf '%s\n' "$bar_output" | awk -F= '$1=="BAR1_BYTES"{print $2}') == 65536 ]] || fail BAR1_GEOMETRY

expected_taint='xdma: module verification failed: signature and/or required key missing - tainting kernel'
expected_taint_count=$(grep -Fc "$expected_taint" "$evidence/xdma_driver_dmesg.txt" 2>/dev/null || true)
critical_matches=$(
  { grep -Ei 'fail|error|unknown symbol|AER:.*(fatal|non-fatal|uncorrected)' "$evidence/xdma_driver_dmesg.txt" 2>/dev/null || true; } |
    grep -Fv "$expected_taint" || true
)
critical_count=$(if [[ -n $critical_matches ]]; then printf '%s\n' "$critical_matches" | wc -l; else printf 0; fi)
printf 'EXPECTED_UNSIGNED_MODULE_TAINT_COUNT=%s\n' "$expected_taint_count"
printf 'POSTLOAD_CRITICAL_MATCH_COUNT=%s\n' "$critical_count"
printf 'POSTLOAD_CRITICAL_MATCHES_BEGIN\n%s\nPOSTLOAD_CRITICAL_MATCHES_END\n' "$critical_matches"
[[ $expected_taint_count -eq 1 && $critical_count -eq 0 ]] || fail POSTLOAD_KERNEL_HEALTH
printf 'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO\n'
printf 'TASK_DMA_COMMANDS=0\n'
printf 'LOADER_RESULT=PASS\n'
