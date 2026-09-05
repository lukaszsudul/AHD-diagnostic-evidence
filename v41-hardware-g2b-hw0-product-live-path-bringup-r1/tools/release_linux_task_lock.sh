#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
lock_path=/tmp/ahd-g2b-hw0-product-r1.lock
receipt_path="$lock_path/receipt.json"
expected_task=G2B-HW0-PRODUCT-R1
expected_sha=AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7

echo TASK_ID="$expected_task"
echo MODE=RELEASE_EXACT_TASK_LOCAL_LINUX_LOCK
printf 'UTC_START=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"

[ "$lock_path" = /tmp/ahd-g2b-hw0-product-r1.lock ]
[ -d "$lock_path" ]
[ -f "$receipt_path" ]
[ "$(find "$lock_path" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]

python3 - "$receipt_path" "$expected_task" "$expected_sha" <<'PY'
import datetime
import json
import os
import sys

path, expected_task, expected_sha = sys.argv[1:]
with open(path, "r", encoding="utf-8") as handle:
    receipt = json.load(handle)
if receipt.get("task_id") != expected_task:
    raise SystemExit("LOCK_TASK_ID_MISMATCH")
if receipt.get("candidate_bitstream_sha256") != expected_sha:
    raise SystemExit("LOCK_CANDIDATE_SHA_MISMATCH")
if receipt.get("lock_release_state") != "HELD":
    raise SystemExit("LOCK_NOT_HELD")
receipt["exact_ahd_endpoint_bdf"] = "N/A_ENDPOINT_NOT_RECOVERED"
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
rm -- "$receipt_path"
rmdir -- "$lock_path"
[ ! -e "$lock_path" ]
echo LINUX_LOCK_PRESENT_AFTER_RELEASE=NO
echo LINUX_LOCK_RELEASE_RESULT=PASS
printf 'UTC_END=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
