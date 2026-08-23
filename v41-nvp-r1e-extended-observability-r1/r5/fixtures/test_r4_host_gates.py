#!/usr/bin/env python3
"""Offline R4 identity, lifecycle, ordered-log, probe, and formal-page fixtures."""

from __future__ import annotations

import importlib.util
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


reader = load("r1e_reader", ROOT / "scripts" / "read_nvp_r1e.py")
identity = load("identity", ROOT / "scripts" / "verify_runtime_identity.py")


class FakeOs:
    def __init__(self, values: dict[int, int]):
        self.values = values

    def pread(self, _fd: int, size: int, offset: int) -> bytes:
        assert size == 4
        return struct.pack("<I", self.values[offset])


def record(op: int, phase: int, reg: int, data: int, pb: int, mb: int) -> int:
    return op | phase << 8 | reg << 16 | data << 24 | pb << 32 | mb << 40 | 3 << 48


def detail_words(nack_count: int, records: list[int], overflow: int) -> list[int]:
    value = nack_count << 128
    value |= min(nack_count, 8) << 192
    value |= overflow << 196
    value |= 8 << 216
    for index, raw in enumerate(records):
        value |= raw << (224 + 64 * index)
    return [(value >> (32 * index)) & 0xFFFFFFFF for index in range(23)]


def main() -> int:
    assert identity.is_exact_formal(identity.EXPECTED)
    assert not identity.is_exact_formal((0xFFFFFFFF,) * 4)
    assert not identity.is_exact_formal((0xA40A0C07, 0x400B, 0x31002, 1))

    expected = 132584734
    fake = FakeOs({0x2014: expected & 0xFFFFFFFF, 0x2018: expected >> 32})
    assert reader.read48(7, 0x2014, 0x2018, fake) == expected

    ordered = reader.decode_detail(detail_words(
        2,
        [record(4, 1, 0xFF, 2, 1, 2), record(5, 3, 0x20, 0x11, 2, 2)],
        0,
    ))
    assert ordered["header_consistency"] == "PASS"
    assert [x["phase_name"] for x in ordered["records"]] == ["WRITE_ADDRESS_ACK", "DATA_ACK"]
    overflow = reader.decode_detail(detail_words(
        9, [record(i, 2, i, i, 0, 0) for i in range(8)], 1
    ))
    assert overflow["header_consistency"] == "PASS"
    assert overflow["control_flow_replay_scope"] == "PARTIAL_FIRST_8_RECORDS_ONLY"

    low, high = reader.wilson95(0, 10000)
    assert low == 0.0 and 0.00038 < high < 0.00039

    formal = {
        "r1e_page": {f"0x{x:05X}": 0 for x in range(0x2000, 0x2100, 4)},
        "ordered_nack": {"header_consistency": "PASS"},
    }
    reader.validate(formal, "formal")
    formal_bad = {"r1e_page": dict(formal["r1e_page"]), "ordered_nack": {"header_consistency": "PASS"}}
    formal_bad["r1e_page"]["0x02000"] = 1
    try:
        reader.validate(formal_bad, "formal")
        raise AssertionError("nonzero formal R1e page was accepted")
    except RuntimeError:
        pass

    r1e_page = {f"0x{x:05X}": 0 for x in range(0x2000, 0x2100, 4)}
    r1e_page.update({
        "0x02000": 0x314B4C43, "0x02004": 1,
        "0x02040": 0x31453152, "0x02044": 1,
        "0x0204C": 25000, "0x02050": 1251,
        "0x02054": 132584734, "0x02064": 10000,
        "0x02068": 10000, "0x0206C": 10000,
        "0x02070": 0, "0x02074": 0, "0x02078": 1,
    })
    r1e = {"r1e_page": r1e_page, "ordered_nack": {"header_consistency": "PASS"}}
    reader.validate(r1e, "r1e")
    r1e_bad = {"r1e_page": dict(r1e_page), "ordered_nack": {"header_consistency": "PASS"}}
    r1e_bad["r1e_page"]["0x0206C"] = 9999
    try:
        reader.validate(r1e_bad, "r1e")
        raise AssertionError("invalid probe ACK+NACK sum was accepted")
    except RuntimeError:
        pass

    print("FORMAL_IDENTITY_ACCEPTANCE_FIXTURE=PASS")
    print("ALL_ONES_IDENTITY_REJECTION_FIXTURE=PASS")
    print("LIFECYCLE_COHERENT_READ_FIXTURE=PASS")
    print("ORDERED_LOG_FIXTURES=PASS")
    print("PROBE_INVARIANT_FIXTURES=PASS")
    print("WILSON_FIXTURES=PASS")
    print("FORMAL_R1E_PAGE_ZERO_FIXTURE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
