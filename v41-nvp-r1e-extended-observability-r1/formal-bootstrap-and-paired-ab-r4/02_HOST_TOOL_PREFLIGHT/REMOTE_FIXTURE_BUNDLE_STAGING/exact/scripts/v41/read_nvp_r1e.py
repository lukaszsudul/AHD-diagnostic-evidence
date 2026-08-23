#!/usr/bin/env python3
"""Bounded read-only R1e/formal telemetry and ordered-NACK decoder."""

from __future__ import annotations

import argparse
import json
import math
import os
import struct
import time
from typing import Any

PHASE_NAMES = {
    0x01: "WRITE_ADDRESS_ACK",
    0x02: "REGISTER_ADDRESS_ACK",
    0x03: "DATA_ACK",
    0x04: "READ_ADDRESS_ACK",
}
STATIC_LOCAL = tuple(range(0x8C, 0xB8, 4))
STATIC_R1E = tuple(range(0x2014, 0x2098, 4))
R1E_PAGE = tuple(range(0x2000, 0x2100, 4))
LEGACY_DETAIL = tuple(range(0x10080, 0x100DC, 4))


def read_word(fd: int, offset: int, os_module=os) -> int:
    payload = os_module.pread(fd, 4, offset)
    if len(payload) != 4:
        raise RuntimeError(f"pread at 0x{offset:05X} returned {len(payload)} bytes")
    return struct.unpack("<I", payload)[0]


def read48(fd: int, low: int, high: int, os_module=os) -> int:
    for _ in range(3):
        high1 = read_word(fd, high, os_module) & 0xFFFF
        lowv = read_word(fd, low, os_module)
        high2 = read_word(fd, high, os_module) & 0xFFFF
        if high1 == high2:
            return (high1 << 32) | lowv
    raise RuntimeError(f"incoherent 48-bit counter at 0x{low:05X}")


def decode_detail(words: list[int]) -> dict[str, Any]:
    if len(words) != 23:
        raise RuntimeError("legacy detail vector must contain 23 words")
    value = sum(word << (32 * index) for index, word in enumerate(words))
    field = lambda hi, lo: (value >> lo) & ((1 << (hi - lo + 1)) - 1)
    count = field(195, 192)
    overflow = field(196, 196)
    records = []
    for index in range(8):
        raw = field(224 + index * 64 + 63, 224 + index * 64)
        records.append({
            "index": index,
            "raw": f"0x{raw:016X}",
            "operation_index": raw & 0xFF,
            "phase_code": (raw >> 8) & 0xFF,
            "phase_name": PHASE_NAMES.get((raw >> 8) & 0xFF, "UNKNOWN"),
            "register": (raw >> 16) & 0xFF,
            "data": (raw >> 24) & 0xFF,
            "physical_bank": (raw >> 32) & 0xFF,
            "metadata_bank": (raw >> 40) & 0xFF,
            "valid": (raw >> 48) & 1,
            "physical_bank_valid": (raw >> 49) & 1,
            "reserved": (raw >> 50) & 0x3FFF,
        })
    aggregate = field(143, 128)
    consistent = (count == min(aggregate, 8) and
                  overflow == int(aggregate > 8) and
                  all(record["valid"] for record in records[:count]))
    return {
        "phase": field(7, 0), "operation_index": field(15, 8),
        "table_length": field(31, 16), "first_error_valid": field(80, 80),
        "first_error_code": field(95, 88),
        "first_error_step": field(103, 96),
        "first_error_metadata_bank": field(111, 104),
        "first_error_register": field(119, 112),
        "first_error_data": field(127, 120),
        "nack_count": aggregate, "timeout_count": field(159, 144),
        "i2c_state": field(167, 160), "original_ff": field(175, 168),
        "restored_ff": field(183, 176),
        "first_error_physical_bank": field(191, 184),
        "log_count": count, "log_overflow": overflow,
        "physical_bank_valid": field(197, 197),
        "current_metadata_bank": field(207, 200),
        "current_physical_bank": field(215, 208),
        "log_capacity": field(223, 216),
        "header_consistency": "PASS" if consistent else "FAIL",
        "control_flow_replay_scope":
            "PARTIAL_FIRST_8_RECORDS_ONLY" if overflow else "COMPLETE_LOG_AVAILABLE",
        "records": records[:count],
    }


def wilson95(successes: int, total: int) -> tuple[float, float]:
    if total <= 0:
        raise RuntimeError("Wilson interval requires positive total")
    z = 1.959963984540054
    p = successes / total
    denominator = 1 + z * z / total
    centre = (p + z * z / (2 * total)) / denominator
    half = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total * total)) / denominator
    return centre - half, centre + half


def snapshot(fd: int, os_module=os) -> dict[str, Any]:
    local = {f"0x{off:05X}": read_word(fd, off, os_module)
             for off in range(0, 0xE4, 4)}
    page = {f"0x{off:05X}": read_word(fd, off, os_module) for off in R1E_PAGE}
    legacy_words = [read_word(fd, off, os_module) for off in LEGACY_DETAIL]
    legacy_log_raw = [read_word(fd, off, os_module)
                      for off in range(0x10098, 0x100DC, 4)]
    detail = decode_detail(legacy_words)
    probe_count = page["0x02068"]
    probe_nack = page["0x02070"]
    probe_stats = None
    if probe_count:
        low, high = wilson95(probe_nack, probe_count)
        probe_stats = {
            "rate": probe_nack / probe_count,
            "rate_ppm": 1_000_000 * probe_nack / probe_count,
            "wilson95_lower": low, "wilson95_upper": high,
            "rule_of_three_upper_approx": 3 / probe_count if probe_nack == 0 else None,
        }
    actual = read48(fd, 0x2014, 0x2018, os_module)
    expected = (page["0x02058"] << 32) | page["0x02054"]
    signed = actual - expected if page["0x02000"] == 0x314B4C43 else None
    lifecycle = None if signed is None else {
        "actual": actual, "expected": expected, "signed_error_cycles": signed,
        "shortening_cycles": max(-signed, 0), "extension_cycles": max(signed, 0),
        "shortening_ticks_exact": max(-signed, 0) / 1251,
        "shortening_ticks_nearest": round(max(-signed, 0) / 1251),
        "shortening_residual_cycles":
            max(-signed, 0) - round(max(-signed, 0) / 1251) * 1251,
    }
    return {
        "local": local, "r1e_page": page,
        "legacy_nack_raw_17_words": [f"0x{x:08X}" for x in legacy_log_raw],
        "ordered_nack": detail, "lifecycle": lifecycle,
        "probe_statistics": probe_stats,
        "coherent_freerun": read48(fd, 0x200C, 0x2010, os_module),
    }


def static_projection(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "local": {f"0x{x:05X}": item["local"][f"0x{x:05X}"] for x in STATIC_LOCAL},
        "r1e": {f"0x{x:05X}": item["r1e_page"][f"0x{x:05X}"] for x in STATIC_R1E},
        "legacy": item["legacy_nack_raw_17_words"],
    }


def validate(item: dict[str, Any], expected_image: str) -> None:
    page = item["r1e_page"]
    if item["ordered_nack"]["header_consistency"] != "PASS":
        raise RuntimeError("ordered-NACK header/record consistency failed")
    if expected_image == "formal":
        if any(page.values()):
            raise RuntimeError("formal image did not return zero across 0x2000..0x20FF")
    elif expected_image == "r1e":
        required = {
            "0x02000": 0x314B4C43, "0x02004": 1,
            "0x02040": 0x31453152, "0x02044": 1,
            "0x0204C": 25000, "0x02050": 1251,
            "0x02054": 132584734, "0x02064": 10000,
            "0x02068": 10000, "0x02074": 0,
        }
        for key, value in required.items():
            if page[key] != value:
                raise RuntimeError(f"R1e invariant {key} expected {value} got {page[key]}")
        status = page["0x02078"]
        if not (status & 1) or (status & 2) or (status & 4):
            raise RuntimeError(f"invalid R1e probe terminal status 0x{status:08X}")
        if page["0x0206C"] + page["0x02070"] != page["0x02068"]:
            raise RuntimeError("probe ACK+NACK invariant failed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--node", required=True, help="exact already-proven XDMA user node")
    parser.add_argument("--expect", choices=("r1e", "formal", "none"), default="none")
    parser.add_argument("--twice", action="store_true")
    parser.add_argument("--delay", type=float, default=1.0)
    args = parser.parse_args()
    fd = os.open(args.node, os.O_RDONLY | os.O_CLOEXEC)
    try:
        first = snapshot(fd)
        validate(first, args.expect)
        second = None
        if args.twice:
            time.sleep(max(args.delay, 0.0))
            second = snapshot(fd)
            validate(second, args.expect)
            if static_projection(first) != static_projection(second):
                raise RuntimeError("T0/T1 static telemetry mismatch")
    finally:
        os.close(fd)
    print(json.dumps({"T0": first, "T1": second}, indent=2, sort_keys=True))
    print("READ_ONLY=YES")
    print(f"STATIC_SNAPSHOTS_MATCH={'YES' if args.twice else 'NOT_REQUESTED'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
