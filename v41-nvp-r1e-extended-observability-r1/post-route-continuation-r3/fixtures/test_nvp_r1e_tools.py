#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("reader", ROOT / "scripts/v41/read_nvp_r1e.py")
assert SPEC and SPEC.loader
reader = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reader)


def make_detail(nack_count: int, records: list[int], overflow: int = 0) -> list[int]:
    value = 0
    value |= nack_count << 128
    value |= min(nack_count, 8) << 192
    value |= overflow << 196
    value |= 8 << 216
    for index, record in enumerate(records):
        value |= record << (224 + 64 * index)
    return [(value >> (32 * index)) & 0xFFFFFFFF for index in range(23)]


def record(op: int, phase: int, reg: int, data: int, pb: int, mb: int) -> int:
    return op | phase << 8 | reg << 16 | data << 24 | pb << 32 | mb << 40 | 3 << 48


def main() -> int:
    words = make_detail(2, [record(4, 1, 0xFF, 2, 1, 2),
                            record(5, 3, 0x20, 0x11, 2, 2)])
    decoded = reader.decode_detail(words)
    assert decoded["header_consistency"] == "PASS"
    assert decoded["records"][0]["phase_name"] == "WRITE_ADDRESS_ACK"
    assert decoded["records"][1]["phase_name"] == "DATA_ACK"
    assert decoded["records"][0]["register"] == 0xFF
    zero_low, zero_high = reader.wilson95(0, 10000)
    assert zero_low == 0.0
    assert 0.00038 < zero_high < 0.00039
    low, high = reader.wilson95(100, 10000)
    assert low < 0.01 < high and math.isfinite(low) and math.isfinite(high)
    overflow = reader.decode_detail(make_detail(9, [record(i, 2, i, i, 0, 0)
                                                     for i in range(8)], 1))
    assert overflow["header_consistency"] == "PASS"
    assert overflow["control_flow_replay_scope"] == "PARTIAL_FIRST_8_RECORDS_ONLY"
    print("R1E_HOST_DECODE_FIXTURES=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
