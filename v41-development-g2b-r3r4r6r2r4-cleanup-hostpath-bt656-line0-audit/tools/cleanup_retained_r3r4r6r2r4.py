#!/usr/bin/env python3
"""One-shot cleanup-only RESET_STREAM_STATE for retained R3R4R6R2R3 state."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
import struct
import time


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R4"
CONTROL = 0x380C
STATUS = 0x3810
EPOCH = 0x3838
ERROR_STATUS = 0x383C
LAST_ERROR_CAUSE = 0x3840
ABANDONED = 0x3850


def read32(fd: int, offset: int) -> int:
    data = os.pread(fd, 4, offset)
    if len(data) != 4:
        raise RuntimeError(f"R3R4R6R2R4_SHORT_MMIO_READ:0x{offset:04X}")
    return struct.unpack("<I", data)[0]


def quiescent(control: int, status: int) -> bool:
    return control == 0 and (status & 0x10F) == 0x004


def state(fd: int) -> dict[str, int | str]:
    return {
        "Epoch": read32(fd, EPOCH),
        "Control": f"0x{read32(fd, CONTROL):08X}",
        "Status": f"0x{read32(fd, STATUS):08X}",
        "RecordsAbandoned": read32(fd, ABANDONED),
        "ErrorStatus": f"0x{read32(fd, ERROR_STATUS):08X}",
        "LastErrorCause": f"0x{read32(fd, LAST_ERROR_CAUSE):08X}",
        "TimestampNs": time.time_ns(),
    }


def durable_json(path: Path, value: object) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def durable_csv(path: Path, rows: list[dict[str, object]]) -> None:
    fields = ["TimestampNs", "Sample", "Control", "Status", "Accepted",
              "Consecutive", "SpanMs"]
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
        handle.flush()
        os.fsync(handle.fileno())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", required=True)
    parser.add_argument("--logs-dir", required=True)
    args = parser.parse_args()
    logs = Path(args.logs_dir)
    logs.mkdir(parents=True, exist_ok=True, mode=0o700)
    receipt_path = logs / "cleanup-reset-result.json"
    samples_path = logs / "cleanup-quiescence.csv"
    ledger_path = logs / "cleanup-mmio-ledger.csv"
    for path in (receipt_path, samples_path, ledger_path):
        if path.exists():
            raise RuntimeError("R3R4R6R2R4_CLEANUP_RECEIPT_ALREADY_EXISTS")

    flags = os.O_RDWR | os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(args.user_node, flags)
    rows: list[dict[str, object]] = []
    result: dict[str, object] = {
        "task": TASK,
        "result": "FAIL",
        "write_count": 0,
        "write_offset": "0x380C",
        "write_value": "0x00000004",
        "purpose": "CLEANUP_ONLY_RESET_STREAM_STATE",
    }
    ledger: list[dict[str, object]] = []
    try:
        before = state(fd)
        result["before"] = before
        intent_ns = time.time_ns()
        ledger.append({
            "TimestampNs": intent_ns,
            "Operation": "INTENT",
            "Offset": "0x380C",
            "Value": "0x00000004",
            "Purpose": "CLEANUP_ONLY_RESET_STREAM_STATE",
            "Result": "INTENT",
        })
        written = os.pwrite(fd, struct.pack("<I", 4), CONTROL)
        if written != 4:
            raise RuntimeError("R3R4R6R2R4_CLEANUP_RESET_SHORT_WRITE")
        result["write_count"] = 1
        ledger.append({
            "TimestampNs": time.time_ns(),
            "Operation": "WRITE",
            "Offset": "0x380C",
            "Value": "0x00000004",
            "Purpose": "CLEANUP_ONLY_RESET_STREAM_STATE",
            "Result": "PASS",
        })

        reset_deadline = time.monotonic() + 5.0
        while True:
            control = read32(fd, CONTROL)
            status = read32(fd, STATUS)
            if quiescent(control, status):
                break
            if time.monotonic() >= reset_deadline:
                raise RuntimeError("R3R4R6R2R4_CLEANUP_RESET_TIMEOUT")
            time.sleep(0.001)

        deadline = time.monotonic() + 10.0
        consecutive = 0
        first_accepted: float | None = None
        passed = False
        while time.monotonic() < deadline:
            sample_start = time.monotonic()
            control = read32(fd, CONTROL)
            status = read32(fd, STATUS)
            accepted = quiescent(control, status)
            now = time.monotonic()
            if accepted:
                if consecutive == 0:
                    first_accepted = now
                consecutive += 1
            else:
                consecutive = 0
                first_accepted = None
            span = 0.0 if first_accepted is None else now - first_accepted
            rows.append({
                "TimestampNs": time.time_ns(),
                "Sample": len(rows) + 1,
                "Control": f"0x{control:08X}",
                "Status": f"0x{status:08X}",
                "Accepted": accepted,
                "Consecutive": consecutive,
                "SpanMs": round(span * 1000.0, 3),
            })
            if consecutive >= 5 and span >= 0.400:
                passed = True
                break
            remaining = 0.100 - (time.monotonic() - sample_start)
            if remaining > 0:
                time.sleep(remaining)
        if not passed:
            raise RuntimeError("R3R4R6R2R4_CLEANUP_PHYSICAL_QUIESCENCE_FAILED")

        after = state(fd)
        result["after"] = after
        result["epoch_transition"] = (
            f"{before['Epoch']}->{after['Epoch']}"
        )
        result["records_abandoned_delta"] = (
            int(after["RecordsAbandoned"]) - int(before["RecordsAbandoned"])
        ) & 0xFFFFFFFF
        result["quiescence"] = {
            "result": "PASS",
            "sample_count": len(rows),
            "accepted_count": consecutive,
            "span_ms": rows[-1]["SpanMs"],
        }
        result["result"] = "PASS"
    except BaseException as exc:
        result["blocker"] = str(exc).strip() or type(exc).__name__
    finally:
        os.close(fd)
        durable_csv(samples_path, rows)
        fields = ["TimestampNs", "Operation", "Offset", "Value", "Purpose", "Result"]
        with ledger_path.open("x", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(ledger)
            handle.flush()
            os.fsync(handle.fileno())
        durable_json(receipt_path, result)

    print(json.dumps({
        "task": TASK,
        "result": result["result"],
        "epoch_transition": result.get("epoch_transition"),
        "records_abandoned_delta": result.get("records_abandoned_delta"),
        "quiescence": result.get("quiescence"),
        "blocker": result.get("blocker"),
    }, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
