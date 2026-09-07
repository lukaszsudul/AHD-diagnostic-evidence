#!/usr/bin/env python3
"""Acquire or release the exact task-local Linux lock for R3R4R6R1."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import time


TASK = "G2B-HW0-PRODUCT-R3R4R6R1"
REMOTE_ROOT = Path(
    "/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r6r1/"
    "20260907T202452Z")
LOCK = Path("/tmp/ahd-g2b-hw0-product-r3r4r6r1-20260907T202452Z.lock")
RECEIPT = LOCK / "receipt.json"


def write_exclusive(path: Path, value: dict) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("acquire", "release"))
    args = parser.parse_args()
    if args.action == "acquire":
        try:
            LOCK.mkdir(mode=0o700)
        except FileExistsError:
            raise RuntimeError("R3R4R6R1_TASK_LOCK_UNAVAILABLE") from None
        value = {
            "task": TASK,
            "state": "HELD",
            "remote_root": str(REMOTE_ROOT),
            "process_id": os.getpid(),
            "acquired_utc_ns": time.time_ns(),
        }
        try:
            write_exclusive(RECEIPT, value)
        except BaseException:
            LOCK.rmdir()
            raise
    else:
        value = json.loads(RECEIPT.read_text(encoding="utf-8"))
        if (value.get("task") != TASK or value.get("state") != "HELD" or
                value.get("remote_root") != str(REMOTE_ROOT)):
            raise RuntimeError("R3R4R6R1_LINUX_TASK_LOCK_OWNER_MISMATCH")
        RECEIPT.unlink()
        LOCK.rmdir()
        value = {
            "task": TASK,
            "state": "RELEASED",
            "remote_root": str(REMOTE_ROOT),
            "released_utc_ns": time.time_ns(),
        }
        write_exclusive(REMOTE_ROOT / "logs" / "linux-lock-release.json", value)
    print(json.dumps(value, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
