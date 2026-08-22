#!/usr/bin/env python3
"""Issue exactly one R1d PROBE_CONTROL pwrite; never retries."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import struct

PROBE_CONTROL_OFFSET = 0x2208
COMMANDS = {"START_50KHZ": 0x00000001, "START_25KHZ": 0x00000003}


def write_once(fd: int, value: int, os_module=os) -> int:
    payload = struct.pack("<I", value)
    written = os_module.pwrite(fd, payload, PROBE_CONTROL_OFFSET)
    if written != 4:
        raise RuntimeError(f"single pwrite returned {written}, expected 4")
    return written


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=COMMANDS)
    parser.add_argument("--node", required=True,
                        help="exact already-proven XDMA user node")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    value = COMMANDS[args.command]
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    print(f"RECEIPT_BEFORE_UTC={now}")
    print(f"NODE={args.node}")
    print(f"OFFSET=0x{PROBE_CONTROL_OFFSET:08X}")
    print(f"VALUE=0x{value:08X}")
    print("PWRITE_TRANSACTIONS_PLANNED=1")
    if args.dry_run:
        print("DRY_RUN=YES")
        print("PWRITE_TRANSACTIONS_ISSUED=0")
        return 0
    fd = os.open(args.node, os.O_WRONLY | getattr(os, "O_SYNC", 0))
    try:
        write_once(fd, value)
    finally:
        os.close(fd)
    print(f"RECEIPT_AFTER_UTC={dt.datetime.now(dt.timezone.utc).isoformat()}")
    print("PWRITE_TRANSACTIONS_ISSUED=1")
    print("RETRY_COUNT=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
