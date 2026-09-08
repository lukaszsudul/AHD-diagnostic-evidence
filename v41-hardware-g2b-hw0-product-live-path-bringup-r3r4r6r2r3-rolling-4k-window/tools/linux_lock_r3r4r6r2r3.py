#!/usr/bin/env python3
"""Manage only the fresh R3R4R6R2R3 Linux task lock."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import time


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R3"
ROOT = Path("/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r3/20260908T102555Z")
LOCK = Path("/tmp/ahd-g2b-hw0-product-r3r4r6r2r3-20260908T102555Z.lock")


def write_exclusive(path: Path, value: dict) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def acquire() -> dict:
    try:
        LOCK.mkdir(mode=0o700)
    except FileExistsError:
        raise RuntimeError("R3R4R6R2R3_FRESH_TASK_LOCK_UNAVAILABLE") from None
    value = {
        "task": TASK,
        "state": "HELD",
        "remote_root": str(ROOT),
        "process_id": os.getpid(),
        "acquired_utc_ns": time.time_ns(),
        "historical_locks_inspected": False,
    }
    try:
        write_exclusive(LOCK / "receipt.json", value)
    except BaseException:
        LOCK.rmdir()
        raise
    return value


def release() -> dict:
    receipt = LOCK / "receipt.json"
    if not receipt.is_file():
        raise RuntimeError("R3R4R6R2R3_LINUX_LOCK_RECEIPT_MISSING")
    value = json.loads(receipt.read_text(encoding="utf-8"))
    if (value.get("task") != TASK or value.get("state") != "HELD" or
            value.get("remote_root") != str(ROOT)):
        raise RuntimeError("R3R4R6R2R3_LINUX_LOCK_OWNER_MISMATCH")
    receipt.unlink()
    LOCK.rmdir()
    released = {
        "task": TASK,
        "state": "RELEASED",
        "remote_root": str(ROOT),
        "released_utc_ns": time.time_ns(),
    }
    write_exclusive(ROOT / "logs" / "linux-lock-release.json", released)
    return released


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("acquire", "release"))
    args = parser.parse_args()
    value = acquire() if args.action == "acquire" else release()
    print(json.dumps(value, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
