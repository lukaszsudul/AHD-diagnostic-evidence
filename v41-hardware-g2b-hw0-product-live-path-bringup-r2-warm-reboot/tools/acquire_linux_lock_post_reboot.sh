#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
umask 077

lock_path=/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock
receipt_path="$lock_path/receipt.json"
expected_boot_id=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac
actual_boot_id="$(cat /proc/sys/kernel/random/boot_id)"

[ "$(hostname)" = VCDE-DUT-1 ]
[ "$(id -u)" = 1000 ]
[ "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8 ]
[ "$actual_boot_id" = "$expected_boot_id" ]
[ ! -e "$lock_path" ]
[ ! -e /tmp/ahd-g2b-hw0-product-r2.lock ]

relevant_process_count="$(ps -eo comm= | awk 'BEGIN {IGNORECASE=1} /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$/ {count++} END {print count+0}')"
[ "$relevant_process_count" -eq 0 ]
xdma_module_count="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
[ "$xdma_module_count" -eq 0 ]
shopt -s nullglob
nodes=(/dev/xdma*)
[ "${#nodes[@]}" -eq 0 ]
other_task_lock_count="$(find /tmp /run/lock /var/lock -maxdepth 2 -type d \( -iname 'ahd*.lock' -o -iname 'g2b*.lock' -o -iname 'xdma*.lock' -o -iname 'fpga*.lock' \) -print 2>/dev/null | wc -l)"
[ "$other_task_lock_count" -eq 0 ]

mkdir -- "$lock_path"
python3 - "$receipt_path" "$actual_boot_id" <<'PY'
import datetime
import json
import socket
import sys

path, boot_id = sys.argv[1:]
receipt = {
    "task_id": "G2B-HW0-PRODUCT-R2",
    "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
    "controller_identity": "NBLSUDUL",
    "linux_dut_identity": "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111",
    "hostname": socket.gethostname(),
    "pre_reboot_boot_id": "37131b8d-0e38-4b4e-b77a-b3bda55b4e97",
    "post_reboot_boot_id": boot_id,
    "task_owner_session": "Codex task 01a07308-25ee-7e23-9402-5c9b49a6c7bc / root agent",
    "lock_phase": "POST_REBOOT",
    "lock_timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    "maximum_warm_reboots": 1,
    "warm_reboots_executed": 1,
    "authorized_reboot_budget_remaining": 0,
    "power_cycles_executed": 0,
    "sram_program_operations_in_r2": 0,
    "flash_program_operations": 0,
    "relevant_process_count_before_lock": 0,
    "xdma_module_count_before_lock": 0,
    "xdma_device_node_count_before_lock": 0,
    "other_task_lock_count_before_lock": 0,
    "controller_lock_state": "HELD",
    "lock_release_state": "HELD",
}
with open(path, "x", encoding="utf-8", newline="\n") as handle:
    json.dump(receipt, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY

[ -f "$receipt_path" ]
echo "LINUX_POST_REBOOT_LOCK=HELD"
echo "LINUX_POST_REBOOT_LOCK_PATH=$lock_path"
echo "RELEVANT_PROCESS_COUNT_BEFORE_LOCK=$relevant_process_count"
echo "XDMA_MODULE_COUNT_BEFORE_LOCK=$xdma_module_count"
echo "XDMA_DEVICE_NODE_COUNT_BEFORE_LOCK=${#nodes[@]}"
echo "OTHER_TASK_LOCK_COUNT_BEFORE_LOCK=$other_task_lock_count"
cat "$receipt_path"
