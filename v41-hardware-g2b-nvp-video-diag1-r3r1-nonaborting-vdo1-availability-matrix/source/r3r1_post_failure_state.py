#!/usr/bin/env python3
"""Bounded, read-only R3R1 post-failure transport and restore snapshot."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import struct


class ReadTimeout(RuntimeError):
    pass


def alarm(_signum, _frame):
    raise ReadTimeout("NVP_DIAG1_R3R1_POST_FAILURE_MMIO_TIMEOUT")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", default="/dev/xdma0_user")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        raise RuntimeError("NVP_DIAG1_R3R1_POST_FAILURE_OUTPUT_EXISTS")
    flags = os.O_RDONLY | os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(args.user_node, flags)
    previous = signal.signal(signal.SIGALRM, alarm)

    def read32(offset: int) -> int:
        signal.setitimer(signal.ITIMER_REAL, 2.0)
        try:
            data = os.pread(fd, 4, offset)
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0.0)
        if len(data) != 4:
            raise RuntimeError("NVP_DIAG1_R3R1_POST_FAILURE_SHORT_READ")
        value = struct.unpack("<I", data)[0]
        if value == 0xFFFFFFFF:
            raise RuntimeError("NVP_DIAG1_R3R1_POST_FAILURE_FFFFFFFF")
        return value

    try:
        offsets = {
            "transport_control": 0x380C,
            "transport_status": 0x3810,
            "diag_status": 0x3C10,
            "diag_error": 0x3C14,
            "diag_state": 0x3C18,
            "current_round_channel": 0x3C1C,
            "current_session_id": 0x3C20,
            "current_route": 0x3C38,
            "current_bgcolor_78": 0x3C3C,
            "current_bgcolor_79": 0x3C40,
            "original_route": 0x3C44,
            "original_bgcolor_78": 0x3C48,
            "original_bgcolor_79": 0x3C4C,
            "i2c_transaction_count": 0x3C50,
            "i2c_nack_count": 0x3C54,
            "i2c_timeout_count": 0x3C58,
            "first_i2c_error": 0x3C5C,
            "last_i2c_error": 0x3C60,
            "acknowledged_session_count": 0x3C64,
            "scan_total_sessions": 0x3C68,
            "restore_status": 0x3C6C,
            "i2c_recovery_count": 0x3C70,
            "current_result_valid": 0x3D20,
        }
        raw = {name: read32(offset) for name, offset in offsets.items()}
        status = raw["diag_status"]
        decoded = {
            "busy": bool(status & 0x001),
            "prepared": bool(status & 0x002),
            "capture_ready": bool(status & 0x004),
            "done": bool(status & 0x008),
            "error": bool(status & 0x010),
            "product_baseline_restored": bool(status & 0x020),
            "diagnostic_i2c_owns_bus": bool(status & 0x040),
            "i2c_bus_idle": bool(status & 0x080),
            "scan_active": bool(status & 0x100),
        }
        result = {
            "result": "PASS",
            "read_only": True,
            "raw": {name: f"0x{value:08X}" for name, value in raw.items()},
            "decoded_diag_status": decoded,
            "visible_product_baseline": (
                (raw["current_route"] & 0xFF) == 0x00 and
                (raw["current_bgcolor_78"] & 0xFF) == 0x88 and
                (raw["current_bgcolor_79"] & 0xFF) == 0x88 and
                (raw["original_route"] & 0xFF) == 0x00 and
                (raw["original_bgcolor_78"] & 0xFF) == 0x88 and
                (raw["original_bgcolor_79"] & 0xFF) == 0x88
            ),
            "firmware_internal_restore_verify": (
                raw["restore_status"] == 3 and
                decoded["product_baseline_restored"] and
                not decoded["diagnostic_i2c_owns_bus"] and
                decoded["i2c_bus_idle"]
            ),
            "i2c_clean": (
                raw["i2c_nack_count"] == 0 and
                raw["i2c_timeout_count"] == 0 and
                raw["i2c_recovery_count"] == 0 and
                raw["first_i2c_error"] == 0 and
                raw["last_i2c_error"] == 0
            ),
            "transport_disabled_and_ring_empty": (
                raw["transport_control"] == 0 and
                (raw["transport_status"] & 0x10F) == 0x004
            ),
        }
        args.output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        with args.output.open("x", encoding="utf-8", newline="\n") as handle:
            json.dump(result, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        print(json.dumps(result, sort_keys=True), flush=True)
        return 0
    finally:
        signal.signal(signal.SIGALRM, previous)
        os.close(fd)


if __name__ == "__main__":
    raise SystemExit(main())
