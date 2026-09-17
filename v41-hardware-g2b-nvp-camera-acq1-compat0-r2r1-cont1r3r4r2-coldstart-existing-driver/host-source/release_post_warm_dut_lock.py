#!/usr/bin/env python3
"""Release only this task's exact post-warm DUT lock after safe cleanup."""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path

TASK = "G2B-NVP-CAMERA-ACQ1-COMPAT0-R2R1-CONT1R3R4R2-COLDSTART"
SESSION = "2220ad01-c657-4104-9ca6-c42b3a88f476"
BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
RUN = BASE / "g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart" / "20260917T063836Z"
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
RECEIPT = LOCK / "receipt.json"
RELEASE = RUN / "private" / "dut_post_warm_lock_release.json"
EXPECTED_RECEIPT_SHA = "781C41888D4204B2DB6011444A7B0F5E95AB420D03F0C73B4E9AEE6B7A3D084F"

if os.geteuid() != 1000 or Path("/proc/sys/kernel/random/boot_id").read_text().strip() != BOOT:
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_ACCOUNT_OR_BOOT_MISMATCH")
if not LOCK.is_dir() or LOCK.is_symlink() or LOCK.owner() != "vcdeagent1" or \
        LOCK.stat().st_mode & 0o777 != 0o700 or LOCK.resolve().parent != BASE.resolve():
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_PATH_OR_OWNER_MISMATCH")
if sorted(p.name for p in LOCK.iterdir()) != ["receipt.json"]:
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_UNEXPECTED_LOCK_CONTENT")
raw = RECEIPT.read_bytes()
if hashlib.sha256(raw).hexdigest().upper() != EXPECTED_RECEIPT_SHA:
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_RECEIPT_HASH_MISMATCH")
receipt = json.loads(raw)
if receipt.get("task") != TASK or receipt.get("session_identity") != SESSION or \
        receipt.get("boot_id") != BOOT or receipt.get("state") != "HELD" or \
        receipt.get("lock_path") != str(LOCK) or receipt.get("run_root") != str(RUN):
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_AUTHORITY_MISMATCH")
if RELEASE.exists() or RELEASE.is_symlink():
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_RECEIPT_ALREADY_EXISTS")
release = {
    "schema": "AHD_V41_CONT1R3R4R2_FINAL_DUT_LOCK_RELEASE_V1",
    "task": TASK,
    "session_identity": SESSION,
    "boot_id": BOOT,
    "lock_path": str(LOCK),
    "original_lock_receipt_sha256": EXPECTED_RECEIPT_SHA,
    "release_reason": "HARD_STOP_AFTER_25_CAMPAIGN_SCANS_SAFE_TARGET_CLEANUP_COMPLETE",
    "released_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}
os.umask(0o077)
with RELEASE.open("x", encoding="utf-8", newline="\n") as stream:
    json.dump(release, stream, sort_keys=True, separators=(",", ":"))
    stream.write("\n")
    stream.flush()
    os.fsync(stream.fileno())
os.unlink(RECEIPT)
os.rmdir(LOCK)
if LOCK.exists() or LOCK.is_symlink():
    raise SystemExit("FINAL_DUT_LOCK_RELEASE_DIRECTORY_REMAINED")
print(json.dumps({
    "result": "PASS",
    "lock_released": True,
    "release_receipt_sha256": hashlib.sha256(RELEASE.read_bytes()).hexdigest().upper(),
    "release": release,
}, sort_keys=True, separators=(",", ":")))
