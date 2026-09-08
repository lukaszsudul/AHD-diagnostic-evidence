#!/usr/bin/env python3
"""Remove only authorized stale task locks and manage the R3R4R6R2R2 lock."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import time


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R2"
ROOT = Path("/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r2/20260908T081532Z")
LOCK = Path("/tmp/ahd-g2b-hw0-product-r3r4r6r2r2-20260908T081532Z.lock")
STALE = {
    Path("/tmp/ahd-g2b-hw0-product-r3r4r6r1-20260907T202452Z.lock"):
        ("G2B-HW0-PRODUCT-R3R4R6R1",
         "/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r1/20260907T202452Z"),
    Path("/tmp/ahd-g2b-hw0-product-r3r4r6r2-20260908T061945Z.lock"):
        ("G2B-HW0-PRODUCT-R3R4R6R2",
         "/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2/20260908T061945Z"),
    Path("/tmp/ahd-g2b-hw0-product-r3r4r6r2r1-20260908T073817Z.lock"):
        ("G2B-HW0-PRODUCT-R3R4R6R2R1",
         "/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r1/20260908T073817Z"),
}


def write_exclusive(path: Path, value: dict) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def remove_exact(lock: Path, expected_task: str, expected_root: str) -> dict | None:
    if not lock.exists():
        return None
    receipt = lock / "receipt.json"
    if not lock.is_dir() or not receipt.is_file() or set(lock.iterdir()) != {receipt}:
        raise RuntimeError("R3R4R6R2R2_STALE_LINUX_LOCK_CONTENT_INVALID:" + str(lock))
    value = json.loads(receipt.read_text(encoding="utf-8"))
    if (value.get("task") != expected_task or value.get("state") != "HELD" or
            value.get("remote_root") != expected_root):
        raise RuntimeError("R3R4R6R2R2_STALE_LINUX_LOCK_OWNER_MISMATCH:" + str(lock))
    receipt.unlink()
    lock.rmdir()
    return {"task": expected_task, "remote_root": expected_root}


def acquire(clean_stale: bool, reacquire: bool) -> dict:
    removed = []
    if clean_stale:
        for path, identity in STALE.items():
            item = remove_exact(path, *identity)
            if item:
                removed.append(item)
    if reacquire and LOCK.exists():
        item = remove_exact(LOCK, TASK, str(ROOT))
        if item:
            removed.append(item)
    try:
        LOCK.mkdir(mode=0o700)
    except FileExistsError:
        raise RuntimeError("R3R4R6R2R2_TASK_LOCK_UNAVAILABLE") from None
    value = {
        "task": TASK, "state": "HELD", "remote_root": str(ROOT),
        "process_id": os.getpid(), "acquired_utc_ns": time.time_ns(),
        "exact_stale_locks_removed": removed,
    }
    try:
        write_exclusive(LOCK / "receipt.json", value)
    except BaseException:
        LOCK.rmdir()
        raise
    return value


def release() -> dict:
    receipt = LOCK / "receipt.json"
    value = json.loads(receipt.read_text(encoding="utf-8"))
    if (value.get("task") != TASK or value.get("state") != "HELD" or
            value.get("remote_root") != str(ROOT)):
        raise RuntimeError("R3R4R6R2R2_LINUX_TASK_LOCK_OWNER_MISMATCH")
    receipt.unlink()
    LOCK.rmdir()
    released = {"task": TASK, "state": "RELEASED", "remote_root": str(ROOT),
                "released_utc_ns": time.time_ns()}
    write_exclusive(ROOT / "logs" / "linux-lock-release.json", released)
    return released


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("clean-acquire", "reacquire", "release"))
    action = parser.parse_args().action
    if action == "clean-acquire":
        value = acquire(True, False)
    elif action == "reacquire":
        value = acquire(False, True)
    else:
        value = release()
    print(json.dumps(value, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
