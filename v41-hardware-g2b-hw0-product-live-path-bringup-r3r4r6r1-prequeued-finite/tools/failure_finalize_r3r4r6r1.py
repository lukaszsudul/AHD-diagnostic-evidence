#!/usr/bin/env python3
"""Take the authorized S3/final snapshot after the failed finite session."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
import time

from controller_r3r4r6r1 import Mmio, delta32, delta64, hardware_quiescent


TASK = "G2B-HW0-PRODUCT-R3R4R6R1"


def append_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    with path.open("a", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        for row in rows:
            writer.writerow({name: row.get(name, "") for name in fieldnames})
        handle.flush()
        os.fsync(handle.fileno())


def write_exclusive(path: Path, value: object) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", required=True)
    parser.add_argument("--logs-dir", required=True)
    parser.add_argument("--controller-result", required=True)
    args = parser.parse_args()
    logs = Path(args.logs_dir)
    controller = json.loads(Path(args.controller_result).read_text())
    baseline = controller["baseline_snapshot"]
    mmio = Mmio(args.user_node)
    try:
        control = mmio.read(0x380C, "S3_FAILURE_FINALIZE")
        status = mmio.read(0x3810, "S3_FAILURE_FINALIZE")
        if not hardware_quiescent(control, status):
            raise RuntimeError("R3R4R6R1_ROLLBACK_UNSAFE_ACTIVE_DMA")
        epoch = mmio.read(0x3838, "S3_FAILURE_FINALIZE")
        error_status = mmio.read(0x383C, "S3_FAILURE_FINALIZE")
        last_error_cause = mmio.read(0x3840, "S3_FAILURE_FINALIZE")
        final = mmio.snapshot("FINAL_FAILURE_POST_QUIESCENCE")
        deltas = {
            "attempted": delta32(final["attempted"], baseline["attempted"]),
            "committed": delta32(final["committed"], baseline["committed"]),
            "streamed": delta32(final["streamed"], baseline["streamed"]),
            "dropped": delta32(final["dropped"], baseline["dropped"]),
            "overflow": delta32(final["overflow"], baseline["overflow"]),
            "discontinuity": delta32(
                final["discontinuity"], baseline["discontinuity"]),
            "abandoned": delta32(final["abandoned"], baseline["abandoned"]),
            "reset_events": delta32(
                final["reset_events"], baseline["reset_events"]),
            "beats": delta64(final["beats"], baseline["beats"]),
            "last_global": final["last_global"],
            "last_attempt": final["last_attempt"],
        }
        s3 = {
            "Checkpoint": "S3", "Epoch": epoch,
            "ErrorStatus": error_status,
            "LastErrorCause": last_error_cause,
            "Attempted": final["attempted"],
            "Committed": final["committed"],
            "Streamed": final["streamed"],
            "Dropped": final["dropped"],
            "Overflow": final["overflow"],
            "Discontinuity": final["discontinuity"],
            "Timestamp": time.time_ns(),
        }
        result = {
            "schema": "R3R4R6R1_FAILURE_FINALIZE_RESULT_V1",
            "task": TASK,
            "result": "PASS",
            "stream_disabled": control == 0,
            "physical_quiescence": "PASS",
            "control": control,
            "status": status,
            "S3": s3,
            "final_snapshot": final,
            "counter_deltas": deltas,
            "post_capture_error_cleared": False,
            "additional_control_write": False,
        }
        append_csv(
            logs / "mmio-write-ledger.csv",
            ["Timestamp", "Operation", "Offset", "Value", "Purpose",
             "Precondition", "Authorized", "Result", "CompletionMonotonicNs"],
            mmio.ledger)
        append_csv(
            logs / "mmio-raw.csv",
            ["Timestamp", "Label", "Operation", "Offset", "Value", "Result"],
            mmio.raw_rows)
        append_csv(
            logs / "error-timeline.csv",
            ["Checkpoint", "Epoch", "ErrorStatus", "LastErrorCause",
             "Attempted", "Committed", "Streamed", "Dropped", "Overflow",
             "Discontinuity", "Timestamp"],
            [s3])
        write_exclusive(logs / "failure-finalize-result.json", result)
        print(json.dumps(result, separators=(",", ":")))
        return 0
    finally:
        mmio.close()


if __name__ == "__main__":
    raise SystemExit(main())
