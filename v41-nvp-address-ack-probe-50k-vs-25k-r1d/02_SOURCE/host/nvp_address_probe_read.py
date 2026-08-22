#!/usr/bin/env python3
"""Read-only R1d probe register snapshot tool."""

from __future__ import annotations

import argparse
import json
import os
import struct

REGISTERS = {
    "PROBE_MAGIC": 0x2200,
    "PROBE_VERSION": 0x2204,
    "PROBE_STATUS": 0x220C,
    "PROBE_COUNT": 0x2210,
    "PROBE_NACK_COUNT": 0x2214,
    "PROBE_TIMEOUT_COUNT": 0x2218,
    "PROBE_TARGET_COUNT": 0x221C,
    "PROBE_DIVIDER": 0x2220,
    "PROBE_TICK_CYCLES": 0x2224,
    "PROBE_CAMPAIGN_INDEX": 0x2228,
}


def read_word(fd: int, offset: int, os_module=os) -> int:
    payload = os_module.pread(fd, 4, offset)
    if len(payload) != 4:
        raise RuntimeError(f"pread at 0x{offset:X} returned {len(payload)} bytes")
    return struct.unpack("<I", payload)[0]


def snapshot(fd: int, os_module=os) -> dict[str, int]:
    return {name: read_word(fd, offset, os_module) for name, offset in REGISTERS.items()}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--node", required=True,
                        help="exact already-proven XDMA user node")
    parser.add_argument("--twice", action="store_true",
                        help="require two complete static snapshots to match")
    args = parser.parse_args()
    fd = os.open(args.node, os.O_RDONLY)
    try:
        first = snapshot(fd)
        if args.twice:
            second = snapshot(fd)
            if first != second:
                raise RuntimeError("two complete probe snapshots differ")
    finally:
        os.close(fd)
    print(json.dumps(first, sort_keys=True))
    print("READ_ONLY=YES")
    print(f"STATIC_SNAPSHOTS_MATCH={'YES' if args.twice else 'NOT_REQUESTED'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
