#!/usr/bin/env python3
"""Version-gated, bounded, read-only decoder for the v41 R1f experiment.

The live backend uses ``pread`` on an already-proven XDMA user node opened
``O_RDONLY``.  The JSON backend exists for deterministic offline fixtures and
never opens a device.  No MMIO-write primitive is implemented in this file.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import struct
import sys
import time
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

try:
    import read_nvp_r1e as r1e
except ModuleNotFoundError:  # pragma: no cover - package-style import
    from . import read_nvp_r1e as r1e


class R1FDecodeError(RuntimeError):
    """A version, map, coherence, or instrumentation contract failed."""


R1F_FIRST = 0x20A0
R1F_END_EXCLUSIVE = 0x3600
R1F_OFFSETS = tuple(range(R1F_FIRST, R1F_END_EXCLUSIVE, 4))
LOCAL_OFFSETS = tuple(range(0x0000, 0x00E4, 4))
R1E_OFFSETS = tuple(range(0x2000, 0x20A0, 4))
LEGACY_DETAIL_OFFSETS = tuple(range(0x10080, 0x100DC, 4))
LEGACY17_OFFSETS = tuple(range(0x10098, 0x100DC, 4))
READ_OFFSETS = tuple(sorted(set(
    LOCAL_OFFSETS + R1E_OFFSETS + R1F_OFFSETS + LEGACY_DETAIL_OFFSETS
)))

EXPECTED_HEADER = {
    0x20A0: 0x31463152,
    0x20A4: 1,
    0x20A8: 0x000007FF,
    0x20AC: 1,
    0x20B0: 192,
    0x20B4: 6,
    0x20B8: 64,
    0x20BC: 7,
    0x20C0: 0x80008500,  # proven bank 0x00, register 0x85, data 0x00
    0x20C4: 25000,
    0x20C8: 25000,
    0x20CC: 10000,
    0x20D0: 10,
    0x20D4: 1000,
    0x20D8: 12000,
    0x20DC: 512,
}

PHASES = {
    "WADDR": (0x20E0, 0x20E4),
    "REGADDR": (0x20E8, 0x20EC),
    "DATA": (0x20F0, 0x20F4),
    "RADDR": (0x20F8, 0x20FC),
}
PROBE_PHASES = {
    "WADDR": (0x2200, 0x2A00),
    "REGADDR": (0x2280, 0x2E00),
    "DATA": (0x2300, 0x3200),
}
AUTOINIT_PHASE_NAMES = {
    0: "PH_ORIGINAL", 1: "PH_INIT", 2: "PH_WIN_BANK",
    3: "PH_WIN_READ", 4: "PH_OUT_BANK", 5: "PH_OUT_READ",
    6: "PH_AFE_BANK", 7: "PH_AFE_READ", 8: "PH_RESTORE",
}
TRANSACTION_KIND_NAMES = {
    1: "ORIGINAL_BANK_READ", 2: "PREINIT_BANK_SELECT_WRITE",
    3: "PREINIT_BANK_VERIFY_READ", 4: "INIT_BANK_SELECT_WRITE",
    5: "INIT_BANK_VERIFY_READ", 6: "INIT_TARGET_WRITE",
    7: "WINDOW_BANK_WRITE", 8: "WINDOW_REGISTER_READ",
    9: "OUTPUT_BANK_WRITE", 10: "OUTPUT_REGISTER_READ",
    11: "AFE_BANK_WRITE", 12: "AFE_REGISTER_READ",
    13: "RESTORE_BANK_WRITE",
}
READ_KINDS = frozenset((1, 3, 5, 8, 10, 12))
WRITE_KINDS = frozenset((2, 4, 6, 7, 9, 11, 13))
INIT_TABLE_KINDS = frozenset((4, 5, 6))
BANK_VERIFY_RESULT_NAMES = {
    0: "NOT_APPLICABLE", 1: "PASS_MATCHED",
    2: "WRITE_NACK_OR_EARLIER_PHASE_FAILURE",
    3: "VERIFY_TRANSPORT_NACK", 4: "VERIFY_TIMEOUT",
    5: "VERIFY_VALUE_MISMATCH", 6: "VERIFY_NOT_REACHED",
}
BANK_UPDATE_REASON_NAMES = {
    0: "NO_CHANGE", 1: "ORIGINAL_READ_PROVED_BANK",
    2: "ACKED_DIRECT_SELECTOR_WRITE_PROVED_BANK",
    3: "VERIFIED_SELECTOR_READBACK_PROVED_BANK",
    4: "RESTORE_SELECTOR_WRITE_PROVED_BANK",
    5: "SELECTOR_WRITE_FAILURE_INVALIDATED_CACHE",
    6: "SELECTOR_VERIFY_TRANSPORT_FAILURE_INVALIDATED_CACHE",
    7: "SELECTOR_VERIFY_MISMATCH_INVALIDATED_CACHE",
    8: "RESET_OR_START_STATE_INVALID",
    9: "DEFERRED_PENDING_VERIFY_NO_CHANGE",
}


def _word(words: Mapping[int, int], offset: int) -> int:
    value = int(words.get(offset, 0))
    if not 0 <= value <= 0xFFFFFFFF:
        raise R1FDecodeError(f"word 0x{offset:05X} is outside uint32")
    return value


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise R1FDecodeError(message)


def _reserved_zero(value: int, allowed_mask: int, name: str) -> None:
    _require((value & ~allowed_mask) == 0,
             f"{name} has nonzero reserved bits: 0x{value:08X}")


def _nullable(value: int, valid: bool) -> int | None:
    return value if valid else None


def read_word(fd: int, offset: int, os_module=os) -> int:
    payload = os_module.pread(fd, 4, offset)
    if len(payload) != 4:
        raise R1FDecodeError(
            f"pread at 0x{offset:05X} returned {len(payload)} bytes")
    return struct.unpack("<I", payload)[0]


def read48_coherent(fd: int, low_offset: int, high_offset: int,
                    os_module=os) -> tuple[int, int]:
    for _ in range(3):
        high_before = read_word(fd, high_offset, os_module) & 0xFFFF
        low = read_word(fd, low_offset, os_module)
        high_after = read_word(fd, high_offset, os_module) & 0xFFFF
        if high_before == high_after:
            return low, high_after
    raise R1FDecodeError(f"incoherent 48-bit read at 0x{low_offset:05X}")


def collect_word_map(fd: int, os_module=os) -> dict[int, int]:
    """Perform the bounded read inventory.  This function has no write path."""
    result = {offset: read_word(fd, offset, os_module) for offset in READ_OFFSETS}
    # Replace single-pass words with high/low/high coherent captures for every
    # 48-bit lifecycle/timestamp pair interpreted by this reader.
    for low_offset, high_offset in ((0x200C, 0x2010), (0x2014, 0x2018),
                                    (0x2168, 0x216C), (0x2170, 0x2174)):
        low, high = read48_coherent(fd, low_offset, high_offset, os_module)
        result[low_offset] = low
        result[high_offset] = high
    return result


def _decode_lifecycle(words: Mapping[int, int]) -> dict[str, Any] | None:
    if _word(words, 0x2000) != 0x314B4C43:
        return None
    actual = ((_word(words, 0x2018) & 0xFFFF) << 32) | _word(words, 0x2014)
    expected = (_word(words, 0x2058) << 32) | _word(words, 0x2054)
    signed = actual - expected
    shortening = max(-signed, 0)
    return {
        "actual": actual,
        "expected": expected,
        "signed_error_cycles": signed,
        "shortening_cycles": shortening,
        "extension_cycles": max(signed, 0),
        "shortening_ticks_exact": shortening / 1251,
        "shortening_ticks_nearest": round(shortening / 1251),
        "shortening_residual_cycles":
            shortening - round(shortening / 1251) * 1251,
    }


def _decode_legacy(words: Mapping[int, int]) -> dict[str, Any]:
    detail_words = [_word(words, offset) for offset in LEGACY_DETAIL_OFFSETS]
    try:
        decoded = r1e.decode_detail(detail_words)
    except RuntimeError as exc:
        raise R1FDecodeError(str(exc)) from exc
    _require(decoded["header_consistency"] == "PASS",
             "legacy ordered-NACK header consistency failed")
    return decoded


def _decode_header(words: Mapping[int, int]) -> dict[str, Any]:
    identity = [_word(words, address) for address in sorted(EXPECTED_HEADER)]
    _require(not all(value == 0xFFFFFFFF for value in identity),
             "all-ones R1f identity is rejected")
    for address, expected in EXPECTED_HEADER.items():
        actual = _word(words, address)
        _require(actual == expected,
                 f"R1f header 0x{address:05X}: expected 0x{expected:08X}, "
                 f"got 0x{actual:08X}")
    return {
        "magic": "0x31463152", "version": 1, "capabilities": "0x000007FF",
        "record_version": 1, "record_width_bits": 192,
        "record_words": 6, "log_capacity": 64,
        "probe_phase_mask": "0x00000007",
        "safe_target": {"bank": 0x00, "register": 0x85, "data": 0x00,
                        "proven": True},
        "autoinit_i2c_hz": 25000, "probe_i2c_hz": 25000,
        "target_opportunities_per_phase": 10000,
        "blocks_per_phase": 10, "opportunities_per_block": 1000,
        "max_attempts_per_phase": 12000, "index_capacity_per_phase": 512,
    }


def _decode_phase_counters(words: Mapping[int, int], legacy: Mapping[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    phase_nack_sum = 0
    for name, (opp_address, nack_address) in PHASES.items():
        opportunities = _word(words, opp_address)
        nacks = _word(words, nack_address)
        _require(nacks <= opportunities,
                 f"autoinit {name} NACKs exceed opportunities")
        result[name] = {"opportunities": opportunities, "nacks": nacks,
                        "acks": opportunities - nacks,
                        "rate": (nacks / opportunities) if opportunities else None}
        phase_nack_sum += nacks

    starts = _word(words, 0x2100)
    completions = _word(words, 0x2104)
    failed = _word(words, 0x2108)
    timeouts = _word(words, 0x210C)
    _require(completions <= starts, "autoinit completions exceed starts")
    _require(failed <= starts, "failed transactions exceed starts")
    _require(timeouts <= failed, "timeout transactions exceed failed transactions")
    status = _word(words, 0x2110)
    _reserved_zero(status, 0xF, "PHASE_COUNTER_STATUS")
    _require(status == 0xF, f"invalid PHASE_COUNTER_STATUS 0x{status:08X}")
    legacy_aggregate = _word(words, 0x2114)
    _require(legacy_aggregate == int(legacy["nack_count"]),
             "R1f legacy aggregate does not match inherited detail vector")
    _require(_word(words, 0x2118) == phase_nack_sum,
             "R1F_PHASE_NACK_SUM does not match decoded phase counters")
    _require(phase_nack_sum == legacy_aggregate,
             "sum of phase NACK counters does not match legacy aggregate")
    reconciliation = _word(words, 0x211C)
    _reserved_zero(reconciliation, 0x7, "PHASE_RECONCILIATION_STATUS")
    _require(reconciliation == 0x7,
             f"invalid PHASE_RECONCILIATION_STATUS 0x{reconciliation:08X}")
    result["transactions"] = {
        "starts": starts, "completions": completions,
        "failed": failed, "timeouts": timeouts,
    }
    result["legacy_aggregate_nacks"] = legacy_aggregate
    result["phase_nack_sum"] = phase_nack_sum
    result["status"] = "PASS_FINAL_NO_SATURATION_COHERENT"
    return result


def _decode_record(raw: Sequence[int], entry: int) -> dict[str, Any]:
    _require(len(raw) == 6, "record must contain six words")
    w0, w1, w2, w3, w4, w5 = (int(value) for value in raw)
    transaction_index = w0 & 0xFFFF
    table_slot = (w0 >> 16) & 0xFFFF
    legacy_operation = w1 & 0xFF
    phase = (w1 >> 8) & 0xF
    kind = (w1 >> 12) & 0xF
    opportunity_bitmap = (w1 >> 16) & 0xF
    nack_bitmap = (w1 >> 20) & 0xF
    nack_count = (w1 >> 24) & 0x7
    timeout = bool((w1 >> 27) & 1)
    completed = bool((w1 >> 28) & 1)
    valid = bool((w1 >> 29) & 1)
    _require((w1 >> 30) == 0, f"record {entry}: word1 reserved bits nonzero")

    register_raw = w2 & 0xFF
    write_raw = (w2 >> 8) & 0xFF
    read_raw = (w2 >> 16) & 0xFF
    reg_valid = bool((w2 >> 24) & 1)
    write_valid = bool((w2 >> 25) & 1)
    read_valid = bool((w2 >> 26) & 1)
    requested_valid = bool((w2 >> 27) & 1)
    physical_before_valid = bool((w2 >> 28) & 1)
    selector_valid = bool((w2 >> 29) & 1)
    verify_expected_valid = bool((w2 >> 30) & 1)
    verify_observed_valid = bool((w2 >> 31) & 1)

    requested_raw = w3 & 0xFF
    physical_before_raw = (w3 >> 8) & 0xFF
    selector_raw = (w3 >> 16) & 0xFF
    verify_expected_raw = (w3 >> 24) & 0xFF
    verify_observed_raw = w4 & 0xFF
    physical_after_raw = (w4 >> 8) & 0xFF
    physical_after_valid = bool((w4 >> 16) & 1)
    verify_result = (w4 >> 17) & 0x7
    update_reason = (w4 >> 20) & 0xF
    fsm_state = (w4 >> 24) & 0xFF
    fsm_context = w5 & 0xFF
    terminal_error = (w5 >> 8) & 0xFF
    _require((w5 >> 16) == 0, f"record {entry}: word5 reserved bits nonzero")

    _require(valid, f"stored record {entry} has record_valid=0")
    _require(phase in AUTOINIT_PHASE_NAMES,
             f"record {entry}: reserved high-level phase {phase}")
    _require(kind in TRANSACTION_KIND_NAMES,
             f"record {entry}: invalid/reserved transaction kind {kind}")
    _require((nack_bitmap & ~opportunity_bitmap) == 0,
             f"record {entry}: NACK bitmap is not a subset of opportunity bitmap")
    _require(nack_count == nack_bitmap.bit_count(),
             f"record {entry}: NACK count does not equal bitmap population")
    _require(nack_bitmap != 0 or timeout or terminal_error != 0,
             f"record {entry}: valid record has no failure cause")
    _require(completed or timeout,
             f"record {entry}: incomplete non-timeout record")
    _require(opportunity_bitmap & 1,
             f"record {entry}: transaction has no WADDR opportunity")
    if opportunity_bitmap & 0x2:
        _require(opportunity_bitmap & 0x1,
                 f"record {entry}: REGADDR reached without WADDR")
    if opportunity_bitmap & 0xC:
        _require((opportunity_bitmap & 0x3) == 0x3,
                 f"record {entry}: terminal phase reached without prerequisites")
    allowed_phase_bits = 0xB if kind in READ_KINDS else 0x7
    _require((opportunity_bitmap & ~allowed_phase_bits) == 0,
             f"record {entry}: phase bitmap conflicts with transaction kind")
    if kind in READ_KINDS:
        _require(not write_valid, f"record {entry}: read kind marks write data valid")
    if kind in WRITE_KINDS:
        _require(not read_valid, f"record {entry}: write kind marks read data valid")
    if kind in INIT_TABLE_KINDS:
        _require(table_slot != 0xFFFF,
                 f"record {entry}: init kind lacks exact table slot")
    else:
        _require(table_slot == 0xFFFF,
                 f"record {entry}: non-init kind has a table slot")
    if selector_valid:
        _require(reg_valid and register_raw == 0xFF,
                 f"record {entry}: selector validity requires register 0xFF")
    _require(verify_result in BANK_VERIFY_RESULT_NAMES,
             f"record {entry}: reserved bank-verify result {verify_result}")
    _require(update_reason in BANK_UPDATE_REASON_NAMES,
             f"record {entry}: reserved bank-update reason {update_reason}")
    if verify_result == 1:
        _require(verify_expected_valid and verify_observed_valid and
                 verify_expected_raw == verify_observed_raw,
                 f"record {entry}: PASS_MATCHED lacks equal valid bytes")
    _require(fsm_state < 35, f"record {entry}: FSM state is outside exact R1e enum")

    return {
        "entry": entry,
        "raw_words": [f"0x{value:08X}" for value in raw],
        "transaction_index_16": transaction_index,
        "table_slot_index_16": table_slot,
        "legacy_operation_index_8": legacy_operation,
        "legacy_operation_index_authoritative": False,
        "autoinit_phase_code": phase,
        "autoinit_phase": AUTOINIT_PHASE_NAMES[phase],
        "transaction_kind_code": kind,
        "transaction_kind": TRANSACTION_KIND_NAMES[kind],
        "phase_opportunity_bitmap": opportunity_bitmap,
        "phase_nack_bitmap": nack_bitmap,
        "nack_count_within_transaction": nack_count,
        "timeout": timeout, "transaction_completed": completed,
        "record_valid": valid,
        "register_address": _nullable(register_raw, reg_valid),
        "write_data": _nullable(write_raw, write_valid),
        "read_data": _nullable(read_raw, read_valid),
        "requested_bank": _nullable(requested_raw, requested_valid),
        "physical_bank_before":
            _nullable(physical_before_raw, physical_before_valid),
        "selector_value_sent": _nullable(selector_raw, selector_valid),
        "bank_verify_expected":
            _nullable(verify_expected_raw, verify_expected_valid),
        "bank_verify_observed":
            _nullable(verify_observed_raw, verify_observed_valid),
        "physical_bank_after":
            _nullable(physical_after_raw, physical_after_valid),
        "valid_bits": {
            "register_address": reg_valid, "write_data": write_valid,
            "read_data": read_valid, "requested_bank": requested_valid,
            "physical_bank_before": physical_before_valid,
            "selector_value": selector_valid,
            "verify_expected": verify_expected_valid,
            "verify_observed": verify_observed_valid,
            "physical_bank_after": physical_after_valid,
        },
        "bank_verify_result_code": verify_result,
        "bank_verify_result": BANK_VERIFY_RESULT_NAMES[verify_result],
        "bank_update_reason_code": update_reason,
        "bank_update_reason": BANK_UPDATE_REASON_NAMES[update_reason],
        "fsm_state": fsm_state, "fsm_context": fsm_context,
        "terminal_error_code": terminal_error,
    }


def _decode_log(words: Mapping[int, int], failed_transactions: int) -> dict[str, Any]:
    total = _word(words, 0x2120)
    stored = _word(words, 0x2124)
    overflow_word = _word(words, 0x2128)
    _reserved_zero(overflow_word, 0x1, "R1F_FAILED_TXN_OVERFLOW")
    overflow = bool(overflow_word)
    first = _word(words, 0x212C)
    last = _word(words, 0x2130)
    _reserved_zero(first, 0xFFFF, "R1F_FIRST_FAILED_TXN_INDEX")
    _reserved_zero(last, 0xFFFF, "R1F_LAST_FAILED_TXN_INDEX")
    status = _word(words, 0x2134)
    _reserved_zero(status, 0x3FF, "LOG_STATUS")
    next_serial = _word(words, 0x2138)
    _reserved_zero(next_serial, 0x1FFFF, "NEXT_TRANSACTION_SERIAL")
    _require((next_serial & 0x10000) == 0,
             "transaction serial overflow is set")
    _require(total == failed_transactions,
             "failed-transaction total does not equal autoinit failed count")
    _require(stored == min(total, 64), "stored count is not min(total,64)")
    _require(overflow == (total > 64),
             "failed-log overflow does not start exactly at failure 65")
    _require(bool(status & 0x4) == overflow,
             "LOG_STATUS overflow disagrees with overflow word")
    _require((status & 0x78) == 0x78,
             "LOG_STATUS coherence/unused/immutability gates are not all set")
    _require((status & 0x380) == 0,
             "LOG_STATUS serial/protocol/saturation error set")

    first_valid = bool(status & 1)
    last_valid = bool(status & 2)
    _require(first_valid == (total > 0) and last_valid == (total > 0),
             "failed-log first/last validity disagrees with total")
    raw_records = [
        [_word(words, 0x2400 + entry * 0x18 + index * 4) for index in range(6)]
        for entry in range(64)
    ]
    records = [_decode_record(raw_records[index], index) for index in range(stored)]
    for index in range(stored, 64):
        _require(all(value == 0 for value in raw_records[index]),
                 f"unused failed-transaction record {index} is not all zero")
    indices = [record["transaction_index_16"] for record in records]
    _require(all(left < right for left, right in zip(indices, indices[1:])),
             "failed-transaction serials are not strictly chronological")
    if records:
        _require(first == records[0]["transaction_index_16"],
                 "first failed index disagrees with record zero")
        if not overflow:
            _require(last == records[-1]["transaction_index_16"],
                     "last failed index disagrees with final stored record")
    else:
        _require(first == 0 and last == 0,
                 "empty log first/last words must be zero")
    return {
        "total": total, "stored": stored, "overflow": overflow,
        "first_index": first if first_valid else None,
        "last_index": last if last_valid else None,
        "next_transaction_serial": next_serial & 0xFFFF,
        "records": records,
        "all_64_entries_raw_words": [
            [f"0x{value:08X}" for value in raw] for raw in raw_records
        ],
        "structural_consistency": "PASS",
    }


def _expand_nack_events(records: Sequence[Mapping[str, Any]]) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for record in records:
        bitmap = int(record["phase_nack_bitmap"])
        for bit, phase_code in ((0, 1), (1, 2), (2, 3), (3, 4)):
            if bitmap & (1 << bit):
                events.append({
                    "transaction_index_16": record["transaction_index_16"],
                    "legacy_operation_index_8": record["legacy_operation_index_8"],
                    "phase_code": phase_code,
                    "register": record["register_address"],
                    "write_data": record["write_data"],
                    "requested_bank": record["requested_bank"],
                    "physical_bank_before": record["physical_bank_before"],
                })
    return events


def _reconcile_legacy(log: Mapping[str, Any], legacy: Mapping[str, Any]) -> dict[str, Any]:
    expanded = _expand_nack_events(log["records"])
    if log["overflow"]:
        _require(len(expanded) >= min(int(legacy["nack_count"]), 8),
                 "overflowed R1f prefix cannot explain legacy first eight")
    else:
        _require(len(expanded) == int(legacy["nack_count"]),
                 "expanded R1f phase-NACK events do not equal legacy aggregate")
    legacy_records = list(legacy["records"])
    _require(len(legacy_records) == min(len(expanded), 8),
             "legacy stored event count does not match expanded prefix")
    comparisons: list[dict[str, Any]] = []
    for index, (event, old) in enumerate(zip(expanded[:8], legacy_records)):
        _require(old["valid"] == 1, f"legacy record {index} is not valid")
        checks = {
            "legacy_operation":
                event["legacy_operation_index_8"] == old["operation_index"],
            "phase": event["phase_code"] == old["phase_code"],
        }
        if event["register"] is not None:
            checks["register"] = event["register"] == old["register"]
        if event["write_data"] is not None:
            checks["write_data"] = event["write_data"] == old["data"]
        if event["requested_bank"] is not None:
            checks["requested_bank"] = event["requested_bank"] == old["metadata_bank"]
        if event["physical_bank_before"] is not None and old["physical_bank_valid"]:
            checks["physical_bank_before"] = (
                event["physical_bank_before"] == old["physical_bank"])
        failed = [name for name, passed in checks.items() if not passed]
        _require(not failed,
                 f"legacy/R1f reconciliation failed at event {index}: {failed}")
        comparisons.append({"event": index, "transaction_index_16":
                            event["transaction_index_16"], "checks": checks})
    return {"result": "PASS", "expanded_event_count": len(expanded),
            "scope": ("FIRST_64_FAILED_TRANSACTIONS_PREFIX" if log["overflow"]
                      else "COMPLETE_FAILED_TRANSACTION_LOG"),
            "compared_prefix_count": len(comparisons), "comparisons": comparisons}


def _metrics_from_indices(indices: Sequence[int], n: int = 10000) -> dict[str, int | None]:
    if not indices:
        return {"first": None, "last": None, "max_streak": 0,
                "adjacent_pairs": 0, "runs": 1 if n else 0}
    event_set = set(indices)
    max_streak = 0
    streak = 0
    adjacent = 0
    for index in range(n):
        if index in event_set:
            streak += 1
            max_streak = max(max_streak, streak)
            if index - 1 in event_set:
                adjacent += 1
        else:
            streak = 0
    runs = 1 + sum(((index in event_set) != ((index - 1) in event_set))
                   for index in range(1, n)) if n else 0
    return {"first": indices[0], "last": indices[-1],
            "max_streak": max_streak, "adjacent_pairs": adjacent, "runs": runs}


def _decode_index_log(words: Mapping[int, int], base: int, stored: int) -> list[int]:
    _require(0 <= stored <= 512, "probe NACK-index stored count exceeds capacity")
    all_indices: list[int] = []
    for ordinal in range(512):
        packed = _word(words, base + 4 * (ordinal // 2))
        value = (packed >> (16 * (ordinal & 1))) & 0xFFFF
        if ordinal < stored:
            all_indices.append(value)
        else:
            _require(value == 0,
                     f"unused probe index {ordinal} at 0x{base:05X} is nonzero")
    _require(all(0 <= value < 10000 for value in all_indices),
             "probe target-NACK index outside 0..9999")
    _require(all(left < right for left, right in zip(all_indices, all_indices[1:])),
             "probe target-NACK indices are not strictly increasing")
    return all_indices


def _decode_probe_phase(words: Mapping[int, int], name: str,
                        base: int, index_base: int) -> dict[str, Any]:
    status = _word(words, base)
    _reserved_zero(status, 0xFF, f"{name} probe STATUS")
    attempts = _word(words, base + 0x04)
    prereq_w = tuple(_word(words, base + off) for off in (0x08, 0x0C, 0x10))
    prereq_r = tuple(_word(words, base + off) for off in (0x14, 0x18, 0x1C))
    target_opportunities = _word(words, base + 0x20)
    target_acks = _word(words, base + 0x24)
    target_nacks = _word(words, base + 0x28)
    timeouts = _word(words, base + 0x2C)
    first_word = _word(words, base + 0x30)
    last_word = _word(words, base + 0x34)
    _reserved_zero(first_word, 0xFFFF, f"{name} first NACK index")
    _reserved_zero(last_word, 0xFFFF, f"{name} last NACK index")
    stored = _word(words, base + 0x44)
    overflow_word = _word(words, base + 0x48)
    _reserved_zero(overflow_word, 1, f"{name} index overflow")
    overflow = bool(overflow_word)
    blocks = [_word(words, base + 0x4C + 4 * index) for index in range(10)]
    for address in range(base + 0x74, base + 0x80, 4):
        _require(_word(words, address) == 0,
                 f"{name} probe reserved word 0x{address:05X} is nonzero")

    _require((status & 0x7) == 0x7,
             f"{name} probe is not enabled/done/target-complete")
    _require((status & 0xE0) == 0,
             f"{name} probe overflow/saturation/attempt-limit status set")
    _require(attempts <= 12000, f"{name} probe attempts exceed frozen maximum")
    _require(target_opportunities == 10000,
             f"{name} target opportunities are not exactly 10000")
    _require(target_acks + target_nacks == target_opportunities,
             f"{name} target ACK+NACK invariant failed")
    _require(timeouts == 0, f"{name} probe timeout count is nonzero")
    _require(sum(blocks) == target_nacks,
             f"{name} block NACK sum disagrees with aggregate")
    _require(all(count <= 1000 for count in blocks),
             f"{name} probe block count exceeds 1000")
    first_valid = bool(status & 0x8)
    last_valid = bool(status & 0x10)
    _require(first_valid == (target_nacks > 0) and
             last_valid == (target_nacks > 0),
             f"{name} first/last validity disagrees with NACK count")
    _require(stored == min(target_nacks, 512),
             f"{name} stored index count is not min(NACKs,512)")
    _require(overflow == (target_nacks > 512),
             f"{name} index overflow does not start at NACK 513")
    _require(bool(status & 0x20) == overflow,
             f"{name} status/index-overflow word mismatch")
    indices = _decode_index_log(words, index_base, stored)
    if not overflow:
        metrics = _metrics_from_indices(indices)
        expected_first = metrics["first"] if metrics["first"] is not None else 0
        expected_last = metrics["last"] if metrics["last"] is not None else 0
        _require(first_word == expected_first and last_word == expected_last,
                 f"{name} first/last index disagrees with index log")
        _require(_word(words, base + 0x38) == metrics["max_streak"],
                 f"{name} maximum NACK streak disagrees with index log")
        _require(_word(words, base + 0x3C) == metrics["adjacent_pairs"],
                 f"{name} adjacent-pair count disagrees with index log")
        _require(_word(words, base + 0x40) == metrics["runs"],
                 f"{name} run count disagrees with index log")
        calculated_blocks = [0] * 10
        for index in indices:
            calculated_blocks[index // 1000] += 1
        _require(calculated_blocks == blocks,
                 f"{name} block table disagrees with index log")
    else:
        metrics = None

    if name == "WADDR":
        _require(prereq_w == (0, 0, 0) and prereq_r == (0, 0, 0),
                 "WADDR target block has prerequisite counters")
    elif name == "REGADDR":
        _require(prereq_w[1] + prereq_w[2] == prereq_w[0],
                 "REGADDR WADDR prerequisite counters incoherent")
        _require(prereq_r == (0, 0, 0),
                 "REGADDR target block has REGADDR prerequisite counters")
        _require(target_opportunities <= prereq_w[1],
                 "REGADDR target opportunities exceed prerequisite WADDR ACKs")
    else:
        _require(prereq_w[1] + prereq_w[2] == prereq_w[0],
                 "DATA WADDR prerequisite counters incoherent")
        _require(prereq_r[1] + prereq_r[2] == prereq_r[0],
                 "DATA REGADDR prerequisite counters incoherent")
        _require(prereq_r[0] <= prereq_w[1] and
                 target_opportunities <= prereq_r[1],
                 "DATA prerequisite reachability counters incoherent")

    return {
        "phase": name, "status": f"0x{status:08X}", "attempts": attempts,
        "prerequisite_waddr": {"opportunities": prereq_w[0],
                               "acks": prereq_w[1], "nacks": prereq_w[2]},
        "prerequisite_regaddr": {"opportunities": prereq_r[0],
                                 "acks": prereq_r[1], "nacks": prereq_r[2]},
        "target_opportunities": target_opportunities,
        "target_acks": target_acks, "target_nacks": target_nacks,
        "timeouts": timeouts, "first_nack_index_raw":
            first_word if first_valid else None,
        "last_nack_index_raw": last_word if last_valid else None,
        "max_consecutive_nacks": _word(words, base + 0x38),
        "adjacent_nack_pairs": _word(words, base + 0x3C),
        "binary_run_count": _word(words, base + 0x40),
        "index_stored": stored, "index_overflow": overflow,
        "block_nacks": blocks,
        "nack_indices_raw_zero_based": indices,
        "nack_indices_analysis_one_based": [value + 1 for value in indices],
        "sequence_metrics_reconciled": metrics is not None,
    }


def _decode_probe(words: Mapping[int, int]) -> dict[str, Any]:
    status = _word(words, 0x214C)
    _reserved_zero(status, 0x3FF, "TRI_PHASE_PROBE_STATUS")
    _require(status == 0x3FB,
             f"invalid terminal TRI_PHASE_PROBE_STATUS 0x{status:08X}")
    timeout_total = _word(words, 0x2150)
    _require(timeout_total == 0, "probe timeout total is nonzero")
    setup_status = _word(words, 0x2154)
    _reserved_zero(setup_status, 0x1FFF, "PROBE_SETUP_RESTORE_STATUS")
    _require(setup_status == 0x7FF,
             f"probe setup/restore contract failed: 0x{setup_status:08X}")

    def valid_byte(address: int, extra_mask: int = 0) -> tuple[int, int]:
        value = _word(words, address)
        allowed = 0x1FF | extra_mask
        _reserved_zero(value, allowed, f"packed byte 0x{address:05X}")
        _require(value & 0x100, f"packed byte 0x{address:05X} is invalid")
        return value & 0xFF, value

    pre, _ = valid_byte(0x2158)
    post, _ = valid_byte(0x215C)
    original_bank, _ = valid_byte(0x2160)
    restored_bank, restored_word = valid_byte(0x2164, 0x200)
    _require(pre == 0 and post == 0 and pre == post,
             "safe target pre/post readback is not frozen value 0x00")
    _require(restored_word & 0x200 and restored_bank == original_bank,
             "original bank was not restored and verified")
    _reserved_zero(_word(words, 0x216C), 0xFFFF, "PROBE_START_FREERUN_HI")
    _reserved_zero(_word(words, 0x2174), 0xFFFF, "PROBE_DONE_FREERUN_HI")
    start = ((_word(words, 0x216C) & 0xFFFF) << 32) | _word(words, 0x2168)
    done = ((_word(words, 0x2174) & 0xFFFF) << 32) | _word(words, 0x2170)
    _require(done >= start, "probe completion timestamp precedes start")
    for address in range(0x2178, 0x2200, 4):
        _require(_word(words, address) == 0,
                 f"reserved R1f header word 0x{address:05X} is nonzero")

    decoded_phases = {
        name: _decode_probe_phase(words, name, base, index_base)
        for name, (base, index_base) in PROBE_PHASES.items()
    }
    _require(sum(item["timeouts"] for item in decoded_phases.values()) == timeout_total,
             "per-phase probe timeouts do not equal header total")

    global_status = _word(words, 0x2380)
    _require(global_status == status,
             "probe global status differs from header status")
    total_attempts = _word(words, 0x2388)
    _require(total_attempts == sum(item["attempts"] for item in decoded_phases.values()),
             "probe total attempts disagree with per-phase blocks")
    _require(_word(words, 0x238C) == timeout_total,
             "scheduler timeout total disagrees with header")
    _require(_word(words, 0x2390) == 0 and _word(words, 0x2394) == 0,
             "probe setup/restore failure code is nonzero")
    original_detail, _ = valid_byte(0x2398)
    safe_bank_detail, safe_bank_word = valid_byte(0x239C, 0x200)
    pre_detail, pre_word = valid_byte(0x23A0, 0x200)
    post_detail, post_word = valid_byte(0x23A4, 0x600)
    restored_detail, restored_detail_word = valid_byte(0x23A8, 0x200)
    _require(original_detail == original_bank,
             "original-bank detail disagrees with header")
    _require(safe_bank_detail == 0 and safe_bank_word & 0x200,
             "safe bank readback is not matched bank 0x00")
    _require(pre_detail == 0 and pre_word & 0x200,
             "safe target pre-readback detail mismatch")
    _require(post_detail == 0 and (post_word & 0x600) == 0x600,
             "safe target post-readback detail mismatch")
    _require(restored_detail == original_bank and restored_detail_word & 0x200,
             "restored-bank detail mismatch")
    _require(_word(words, 0x23AC) == 0x1F,
             "bus-idle qualification did not pass")
    _require(_word(words, 0x23B0) == 0x7,
             "probe/original line-release status did not pass")
    _require(_word(words, 0x23B4) == 3,
             "terminal scheduler phase is not COMPLETE")
    _require(_word(words, 0x23B8) == 0 and _word(words, 0x23BC) == 0,
             "probe attempt-limit or saturation status is nonzero")
    for address in range(0x23C0, 0x2400, 4):
        _require(_word(words, address) == 0,
                 f"reserved scheduler word 0x{address:05X} is nonzero")
    return {
        "class": "ACTIVE_POST_AUTOINIT_DIAGNOSTIC",
        "status": "PASS_COMPLETE_NO_ABORT_RESTORED",
        "setup_restore_status": f"0x{setup_status:08X}",
        "safe_target_pre": pre, "safe_target_post": post,
        "original_bank": original_bank, "restored_bank": restored_bank,
        "start_freerun": start, "done_freerun": done,
        "scheduler_rounds": _word(words, 0x2384),
        "total_attempts": total_attempts, "phases": decoded_phases,
    }


def _decode_bank_invariants(words: Mapping[int, int]) -> dict[str, Any]:
    checks = _word(words, 0x213C)
    errors = _word(words, 0x2140)
    first = _word(words, 0x2144)
    final = _word(words, 0x2148)
    _reserved_zero(final, 0x1FF, "FINAL_PHYSICAL_BANK_STATE")
    first_valid = bool(first >> 31)
    _require((errors == 0) == (not first_valid),
             "bank invariant error count/first-error validity disagree")
    first_decoded = None if not first_valid else {
        "code": (first >> 24) & 0x7F,
        "transaction_index": (first >> 8) & 0xFFFF,
        "transaction_kind": (first >> 4) & 0xF,
        "phase": first & 0xF,
    }
    return {
        "check_count": checks, "error_count": errors,
        "first_error": first_decoded,
        "final_physical_bank": (final & 0xFF) if final & 0x100 else None,
        "coherence": ("PASS_ZERO_INVARIANT_ERRORS" if errors == 0
                      else "CONTRADICTION_MEASURED"),
    }


def validate_scientific_sample(decoded: Mapping[str, Any]) -> None:
    if decoded["image"] != "r1f":
        raise R1FDecodeError("scientific R1f validation requested for non-R1f image")
    _require(not decoded["failed_transaction_log"]["overflow"],
             "R1f failed-transaction log overflow invalidates sample")
    _require(decoded["bank_invariants"]["error_count"] == 0,
             "bank invariant error count is nonzero")
    _require(decoded["probe"]["status"] == "PASS_COMPLETE_NO_ABORT_RESTORED",
             "tri-phase probe is not a valid terminal sample")


def decode_word_map(words: Mapping[int, int], expect: str = "r1f",
                    require_scientific_valid: bool = True) -> dict[str, Any]:
    """Decode one complete word map; omitted fixture addresses read as zero."""
    if expect not in ("r1f", "formal", "none"):
        raise ValueError("expect must be r1f, formal, or none")
    r1f_values = [_word(words, address) for address in R1F_OFFSETS]
    if expect == "none":
        if _word(words, 0x20A0) == EXPECTED_HEADER[0x20A0]:
            expect = "r1f"
        elif all(value == 0 for value in r1f_values):
            expect = "formal"
        else:
            raise R1FDecodeError("unable to classify R1f range")
    legacy = _decode_legacy(words)
    common = {
        "raw_local_telemetry": {
            f"0x{address:05X}": _word(words, address) for address in LOCAL_OFFSETS
        },
        "raw_r1e_page": {
            f"0x{address:05X}": _word(words, address) for address in R1E_OFFSETS
        },
        "legacy_17_words": [
            f"0x{_word(words, address):08X}" for address in LEGACY17_OFFSETS
        ],
        "legacy_ordered_nack": legacy,
        "lifecycle": _decode_lifecycle(words),
    }
    if expect == "formal":
        _require(all(value == 0 for value in r1f_values),
                 "formal image did not return deterministic zero across 0x20A0..0x35FF")
        return {"image": "formal", "r1f_reserved_range_zero": True, **common}

    header = _decode_header(words)
    phase_counters = _decode_phase_counters(words, legacy)
    log = _decode_log(words, phase_counters["transactions"]["failed"])
    reconciliation = _reconcile_legacy(log, legacy)
    bank = _decode_bank_invariants(words)
    probe = _decode_probe(words)
    result = {
        "image": "r1f", "header": header,
        "phase_counters": phase_counters,
        "failed_transaction_log": log,
        "legacy_reconciliation": reconciliation,
        "bank_invariants": bank, "probe": probe, **common,
    }
    if require_scientific_valid:
        validate_scientific_sample(result)
    return result


def static_projection(decoded: Mapping[str, Any]) -> dict[str, Any]:
    result = {
        "image": decoded["image"],
        "local": {
            f"0x{address:05X}": decoded["raw_local_telemetry"][f"0x{address:05X}"]
            for address in r1e.STATIC_LOCAL
        },
        "r1e": {key: value for key, value in decoded["raw_r1e_page"].items()
                if key not in ("0x0200C", "0x02010")},
        "legacy": decoded["legacy_17_words"],
    }
    for key in ("header", "phase_counters", "failed_transaction_log",
                "legacy_reconciliation", "bank_invariants", "probe",
                "r1f_reserved_range_zero"):
        if key in decoded:
            result[key] = decoded[key]
    return result


def _flatten(value: Any, prefix: str = "") -> list[tuple[str, Any]]:
    rows: list[tuple[str, Any]] = []
    if isinstance(value, Mapping):
        for key in sorted(value):
            rows.extend(_flatten(value[key], f"{prefix}.{key}" if prefix else str(key)))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            rows.extend(_flatten(item, f"{prefix}[{index}]"))
    else:
        rows.append((prefix, value))
    return rows


def write_outputs(decoded: Mapping[str, Any], words: Mapping[int, int],
                  output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "decoded.json").write_text(
        json.dumps(decoded, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    with (output_dir / "raw_mmio_inventory.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("offset", "value"))
        for address in READ_OFFSETS:
            writer.writerow((f"0x{address:05X}", f"0x{_word(words, address):08X}"))
    with (output_dir / "decoded_flat.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("field", "value"))
        writer.writerows(_flatten(decoded))
    with (output_dir / "failed_transactions.csv").open("w", newline="", encoding="utf-8") as handle:
        fieldnames = (
            "entry", "transaction_index_16", "table_slot_index_16",
            "legacy_operation_index_8", "autoinit_phase", "transaction_kind",
            "phase_opportunity_bitmap", "phase_nack_bitmap",
            "nack_count_within_transaction", "timeout", "transaction_completed",
            "register_address", "write_data", "read_data", "requested_bank",
            "physical_bank_before", "selector_value_sent",
            "bank_verify_expected", "bank_verify_observed", "physical_bank_after",
            "bank_verify_result", "bank_update_reason", "fsm_state", "fsm_context",
            "terminal_error_code",
        )
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for record in decoded.get("failed_transaction_log", {}).get("records", []):
            writer.writerow(record)
    with (output_dir / "phase_opportunities.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("phase", "opportunities", "acks", "nacks", "rate"))
        for phase in PHASES:
            if "phase_counters" in decoded:
                item = decoded["phase_counters"][phase]
                writer.writerow((phase, item["opportunities"], item["acks"],
                                 item["nacks"], item["rate"]))
    with (output_dir / "probe_per_phase.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("phase", "attempts", "target_opportunities", "target_acks",
                         "target_nacks", "timeouts", "first_raw", "last_raw",
                         "max_streak", "adjacent_pairs", "runs", "index_overflow"))
        for phase, item in decoded.get("probe", {}).get("phases", {}).items():
            writer.writerow((phase, item["attempts"], item["target_opportunities"],
                             item["target_acks"], item["target_nacks"], item["timeouts"],
                             item["first_nack_index_raw"], item["last_nack_index_raw"],
                             item["max_consecutive_nacks"], item["adjacent_nack_pairs"],
                             item["binary_run_count"], item["index_overflow"]))
    with (output_dir / "probe_blocks.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("phase", "block", "first_analysis_index",
                         "last_analysis_index", "nacks", "rate"))
        for phase, item in decoded.get("probe", {}).get("phases", {}).items():
            for block, nacks in enumerate(item["block_nacks"]):
                writer.writerow((phase, block, block * 1000 + 1, (block + 1) * 1000,
                                 nacks, nacks / 1000))
    with (output_dir / "probe_nack_indices.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(("phase", "ordinal", "raw_zero_based", "analysis_one_based"))
        for phase, item in decoded.get("probe", {}).get("phases", {}).items():
            for ordinal, raw in enumerate(item["nack_indices_raw_zero_based"]):
                writer.writerow((phase, ordinal, raw, raw + 1))
    (output_dir / "bank_invariant_report.json").write_text(
        json.dumps(decoded.get("bank_invariants"), indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    (output_dir / "lifecycle_calculation.json").write_text(
        json.dumps(decoded.get("lifecycle"), indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


def _load_fixture(path: Path) -> dict[int, int]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    raw = payload.get("words", payload)
    if not isinstance(raw, Mapping):
        raise R1FDecodeError("offline input must contain a 'words' mapping")
    result: dict[int, int] = {}
    for key, value in raw.items():
        address = int(key, 0) if isinstance(key, str) else int(key)
        decoded_value = int(value, 0) if isinstance(value, str) else int(value)
        result[address] = decoded_value
    return result


def _one_snapshot(words: Mapping[int, int], expect: str) -> dict[str, Any]:
    return decode_word_map(words, expect=expect, require_scientific_valid=True)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--node", help="exact already-proven XDMA user node")
    source.add_argument("--input-json", type=Path,
                        help="offline sparse word-map fixture; omitted words are zero")
    parser.add_argument("--expect", choices=("r1f", "formal", "none"), default="none")
    parser.add_argument("--twice", action="store_true")
    parser.add_argument("--delay", type=float, default=1.0)
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args(argv)

    if args.input_json:
        words0 = _load_fixture(args.input_json)
        decoded0 = _one_snapshot(words0, args.expect)
        words1 = None
        decoded1 = None
        if args.twice:
            words1 = words0
            decoded1 = _one_snapshot(words1, args.expect)
    else:
        fd = os.open(args.node, os.O_RDONLY | os.O_CLOEXEC)
        try:
            words0 = collect_word_map(fd)
            decoded0 = _one_snapshot(words0, args.expect)
            words1 = None
            decoded1 = None
            if args.twice:
                time.sleep(max(args.delay, 0.0))
                words1 = collect_word_map(fd)
                decoded1 = _one_snapshot(words1, args.expect)
        finally:
            os.close(fd)
    if decoded1 is not None:
        _require(static_projection(decoded0) == static_projection(decoded1),
                 "T0/T1 static R1f telemetry mismatch")
    result = {"T0": decoded0, "T1": decoded1,
              "READ_ONLY": "YES", "STATIC_SNAPSHOTS_MATCH":
                  "YES" if decoded1 is not None else "NOT_REQUESTED"}
    if args.output_dir:
        write_outputs(decoded0, words0, args.output_dir)
    print(json.dumps(result, indent=2, sort_keys=True))
    print("READ_ONLY=YES")
    print(f"STATIC_SNAPSHOTS_MATCH={result['STATIC_SNAPSHOTS_MATCH']}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except R1FDecodeError as error:
        print(f"R1F_DECODE_ERROR={error}", file=sys.stderr)
        raise SystemExit(2)
