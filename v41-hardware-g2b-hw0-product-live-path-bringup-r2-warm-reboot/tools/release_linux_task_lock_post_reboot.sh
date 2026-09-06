#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

lock_path=/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock
receipt_path="$lock_path/receipt.json"
expected_task=G2B-HW0-PRODUCT-R2
expected_sha=AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7
expected_boot=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac

echo TASK_ID="$expected_task"
echo MODE=RELEASE_EXACT_POST_REBOOT_LINUX_TASK_LOCK
echo UTC_START="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
[ "$(hostname)" = VCDE-DUT-1 ]
[ "$(id -u)" = 1000 ]
[ "$(cat /proc/sys/kernel/random/boot_id)" = "$expected_boot" ]
[ "$lock_path" = /tmp/ahd-g2b-hw0-product-r2-post-reboot.lock ]
[ -d "$lock_path" ]
[ -f "$receipt_path" ]
[ "$(find "$lock_path" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]

python3 - "$receipt_path" "$expected_task" "$expected_sha" "$expected_boot" <<'PY'
import datetime
import json
import os
import sys

path, expected_task, expected_sha, expected_boot = sys.argv[1:]
with open(path, "r", encoding="utf-8") as handle:
    receipt = json.load(handle)
checks = {
    "task_id": expected_task,
    "candidate_bitstream_sha256": expected_sha,
    "post_reboot_boot_id": expected_boot,
    "lock_phase": "POST_REBOOT",
    "warm_reboots_executed": 1,
    "authorized_reboot_budget_remaining": 0,
    "lock_release_state": "HELD",
}
for key, value in checks.items():
    if receipt.get(key) != value:
        raise SystemExit(f"LOCK_RECEIPT_MISMATCH:{key}")
receipt["exact_ahd_endpoint_bdf"] = "0000:01:00.0"
receipt["final_endpoint_state"] = "10ee:7011 Gen2 x1 UNBOUND"
receipt["final_xdma_state"] = "MODULE_UNLOADED; PCI_DRIVER_ABSENT; DEVICE_NODES_0"
receipt["final_jtag_state"] = "xc7a35t 0362D093 index0 DONE1"
receipt["first_blocker"] = "BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE"
receipt["lock_release_state"] = "RELEASED_AFTER_FINAL_STATE_CAPTURE"
receipt["release_timestamp_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
temporary = path + ".tmp"
with open(temporary, "x", encoding="utf-8", newline="\n") as handle:
    json.dump(receipt, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
os.replace(temporary, path)
PY

echo RELEASED_RECEIPT_BEGIN
cat "$receipt_path"
echo RELEASED_RECEIPT_END
echo RELEASED_RECEIPT_SHA256="$(sha256sum "$receipt_path" | awk '{print $1}')"
rm -- "$receipt_path"
rmdir -- "$lock_path"
[ ! -e "$lock_path" ]
echo LINUX_LOCK_PRESENT_AFTER_RELEASE=NO
echo LINUX_LOCK_RELEASE_RESULT=PASS
echo UTC_END="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
