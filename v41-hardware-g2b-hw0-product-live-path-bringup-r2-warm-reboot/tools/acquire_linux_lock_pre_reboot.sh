#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

lock_path=/tmp/ahd-g2b-hw0-product-r2.lock
receipt_path="$lock_path/receipt.json"
expected_boot_id=37131b8d-0e38-4b4e-b77a-b3bda55b4e97
actual_boot_id="$(cat /proc/sys/kernel/random/boot_id)"

[ "$actual_boot_id" = "$expected_boot_id" ]
mkdir -- "$lock_path"

python3 - "$receipt_path" "$actual_boot_id" <<'PY'
import datetime
import json
import os
import socket
import sys

path, boot_id = sys.argv[1:]
receipt = {
    "task_id": "G2B-HW0-PRODUCT-R2",
    "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
    "controller_identity": "NBLSUDUL",
    "linux_dut_identity": "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111",
    "hostname": socket.gethostname(),
    "pre_reboot_boot_id": boot_id,
    "task_owner_session": "Codex task 01a07308-25ee-7e23-9402-5c9b49a6c7bc / root agent",
    "lock_phase": "PRE_REBOOT",
    "lock_timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    "maximum_warm_reboots": 1,
    "warm_reboots_executed": 0,
    "lock_release_state": "HELD",
}
with open(path, "x", encoding="utf-8", newline="\n") as handle:
    json.dump(receipt, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY

[ -f "$receipt_path" ]
echo "LINUX_LOCK=HELD"
echo "LINUX_LOCK_PATH=$lock_path"
cat "$receipt_path"
