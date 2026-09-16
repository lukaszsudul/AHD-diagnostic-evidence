"""Read and fail-closed decode of frozen CONT1R3 SCAN1 telemetry."""

from __future__ import annotations

import hashlib
import struct
import time
from importlib.resources import files
from typing import Iterable, Mapping, Sequence

from scan1 import manifest

from . import contract


class TelemetryGateError(RuntimeError):
    pass


def _require(condition: bool, reason: str) -> None:
    if not condition:
        raise TelemetryGateError(reason)


def words_sha256(words: Iterable[int]) -> str:
    payload = b"".join(struct.pack("<I", int(word) & 0xFFFFFFFF) for word in words)
    return hashlib.sha256(payload).hexdigest().upper()


def schema_sha256() -> str:
    payload = files("cont1r3.resources").joinpath("CONT1R3_TELEMETRY_SCHEMA.json").read_bytes()
    return hashlib.sha256(payload).hexdigest().upper()


def _header_value(words: Sequence[int], address: int) -> int:
    return int(words[(address - contract.TELEMETRY_BASE) // 4])


def validate_identity(header_words: Sequence[int]) -> dict:
    _require(len(header_words) == 32, "CONT1R3_TELEMETRY_HEADER_WORD_COUNT")
    schema_digest = "".join(
        f"{_header_value(header_words, 0x12840 + 4 * index):08X}"
        for index in range(8)
    )
    manifest_digest = "".join(
        f"{_header_value(header_words, 0x12860 + 4 * index):08X}"
        for index in range(8)
    )
    actual = (
        _header_value(header_words, 0x12800),
        _header_value(header_words, 0x12804),
        _header_value(header_words, 0x12808),
        _header_value(header_words, 0x12814),
        _header_value(header_words, 0x12818),
        _header_value(header_words, 0x1281C),
        _header_value(header_words, 0x12820),
        _header_value(header_words, 0x1282C),
        _header_value(header_words, 0x12830),
        _header_value(header_words, 0x12834),
        _header_value(header_words, 0x12838),
        _header_value(header_words, 0x1283C),
        schema_digest,
        manifest_digest,
    )
    expected = (
        contract.TELEMETRY_MAGIC,
        contract.TELEMETRY_VERSION,
        contract.TELEMETRY_CAPABILITIES,
        contract.ENTRY_COUNT,
        contract.GROUP_COUNT,
        contract.ENTRY_RECORD_WORDS,
        contract.MAXIMUM_EVENTS,
        contract.COUNTER_FREQUENCY_HZ,
        contract.COUNTER_WIDTH_BITS,
        contract.GROUP_RECORD_WORDS,
        contract.GROUP_RECORD_BASE,
        contract.ENTRY_RECORD_BASE,
        contract.EXPECTED_SCHEMA_SHA256,
        contract.EXPECTED_MANIFEST_SHA256,
    )
    _require(actual == expected, f"CONT1R3_RUNTIME_IDENTITY_MISMATCH:{actual!r}")
    _require(schema_sha256() == contract.EXPECTED_SCHEMA_SHA256,
             "CONT1R3_LOCAL_SCHEMA_DIGEST_MISMATCH")
    return {
        "magic": actual[0], "version": actual[1], "capabilities": actual[2],
        "entry_count": actual[3], "group_count": actual[4],
        "schema_sha256": schema_digest, "manifest_sha256": manifest_digest,
        "counter_frequency_hz": actual[7], "counter_width_bits": actual[8],
    }


def decode_group(words: Sequence[int], expected_index: int) -> dict:
    _require(len(words) == contract.GROUP_RECORD_WORDS, "CONT1R3_GROUP_RECORD_SIZE")
    context = int(words[0])
    group = contract.EXECUTION_GROUPS[expected_index]
    decoded = {
        "group_index": context & 0xF,
        "first_entry_index": (context >> 4) & 0x7F,
        "entry_count": (context >> 11) & 0x7F,
        "current_bank": (context >> 18) & 0xFF,
        "previous_bank_valid": bool(context & (1 << 26)),
        "bank_changed": bool(context & (1 << 27)),
        "same_bank_reselection": bool(context & (1 << 28)),
        "previous_bank": int(words[1]) & 0xFF,
        "verify_completion_tick": int(words[2]) | (int(words[3]) << 32),
        "verify_transaction_sequence": int(words[4]),
        "name": group.name,
    }
    expected = {
        "group_index": group.index, "first_entry_index": group.start,
        "entry_count": group.count, "current_bank": group.bank,
        "previous_bank_valid": group.previous_bank_valid,
        "bank_changed": group.bank_changed,
        "same_bank_reselection": group.same_bank_reselection,
        "previous_bank": group.previous_bank,
    }
    for key, value in expected.items():
        _require(decoded[key] == value,
                 f"CONT1R3_GROUP_CONTEXT_MISMATCH:{expected_index}:{key}")
    _require(context >> 29 == 0 and int(words[1]) >> 8 == 0,
             f"CONT1R3_GROUP_RESERVED_BITS_NONZERO:{expected_index}")
    return decoded


def decode_entry(words: Sequence[int], expected_entry, groups: Sequence[Mapping]) -> dict:
    _require(len(words) == contract.ENTRY_RECORD_WORDS, "CONT1R3_ENTRY_RECORD_SIZE")
    transaction_final = int(words[6])
    group_context = int(words[7])
    target_context = int(words[8])
    outcome = int(words[9])
    group_index = (group_context >> 7) & 0xF
    _require(group_index < len(groups), f"CONT1R3_ENTRY_GROUP_RANGE:{expected_entry.index}")
    group = groups[group_index]
    start_tick = int(words[1]) | (int(words[2]) << 32)
    verify_tick = int(words[3]) | (int(words[4]) << 32)
    delta_ticks = (start_tick - verify_tick) & ((1 << 64) - 1)
    decoded = {
        "scan_generation": int(words[0]),
        "first_attempt_start_tick": start_tick,
        "verify_completion_tick": verify_tick,
        "time_since_verify_ticks": delta_ticks,
        "time_since_verify_ns": contract.ticks_to_ns(delta_ticks),
        "first_attempt_transaction_sequence": int(words[5]),
        "transactions_since_verify": transaction_final & 0xFFFF,
        "final_value": (transaction_final >> 16) & 0xFF,
        "entry_index": group_context & 0x7F,
        "group_index": group_index,
        "position_in_group": (group_context >> 11) & 0x7F,
        "current_verified_bank": (group_context >> 18) & 0xFF,
        "previous_bank_valid": bool(group_context & (1 << 26)),
        "bank_changed": bool(group_context & (1 << 27)),
        "same_bank_reselection": bool(group_context & (1 << 28)),
        "group_verify_success_observed": bool(group_context & (1 << 29)),
        "previous_group_bank": target_context & 0xFF,
        "target_register": (target_context >> 8) & 0xFF,
        "manifest_target_bank": (target_context >> 16) & 0xFF,
        "exposure_valid": bool(outcome & (1 << 0)),
        "first_attempt_complete": bool(outcome & (1 << 1)),
        "first_attempt_success": bool(outcome & (1 << 2)),
        "first_attempt_failure_event": bool(outcome & (1 << 3)),
        "retry_attempted": bool(outcome & (1 << 4)),
        "retry_complete": bool(outcome & (1 << 5)),
        "retry_success": bool(outcome & (1 << 6)),
        "final_value_valid": bool(outcome & (1 << 7)),
        "first_attempt_timeout": bool(outcome & (1 << 8)),
        "retry_timeout": bool(outcome & (1 << 9)),
        "outcome_group_verify_success": bool(outcome & (1 << 10)),
        "first_attempt_raw_cause": (outcome >> 16) & 0xF,
        "first_attempt_decoded_cause": (outcome >> 20) & 0xF,
        "retry_raw_cause": (outcome >> 24) & 0xF,
        "retry_decoded_cause": (outcome >> 28) & 0xF,
    }
    decoded["first_attempt_raw_cause_name"] = contract.RAW_CAUSES.get(
        decoded["first_attempt_raw_cause"], "UNKNOWN")
    decoded["first_attempt_decoded_cause_name"] = contract.DECODED_CAUSES.get(
        decoded["first_attempt_decoded_cause"], "UNKNOWN")
    expected_group = contract.EXECUTION_GROUPS[group_index]
    checks = {
        "entry_index": expected_entry.index,
        "position_in_group": expected_entry.index - expected_group.start,
        "current_verified_bank": expected_group.bank,
        "previous_bank_valid": expected_group.previous_bank_valid,
        "bank_changed": expected_group.bank_changed,
        "same_bank_reselection": expected_group.same_bank_reselection,
        "previous_group_bank": expected_group.previous_bank,
        "target_register": expected_entry.register,
        "manifest_target_bank": expected_entry.bank,
        "verify_completion_tick": int(group["verify_completion_tick"]),
    }
    for key, value in checks.items():
        _require(decoded[key] == value,
                 f"CONT1R3_ENTRY_CONTEXT_MISMATCH:{expected_entry.index}:{key}")
    _require(group_context >> 30 == 0 and target_context >> 24 == 0 and
             transaction_final >> 24 == 0 and ((outcome >> 11) & 0x1F) == 0,
             f"CONT1R3_ENTRY_RESERVED_BITS_NONZERO:{expected_entry.index}")
    return decoded


def validate_frozen(
    header_words: Sequence[int],
    group_words: Sequence[int],
    entry_words: Sequence[int],
    legacy_generation: int,
    legacy_entry_words: Sequence[int],
    legacy_transaction_count: int,
    legacy_scan_start_tick: int | None = None,
    legacy_scan_end_tick: int | None = None,
) -> dict:
    identity = validate_identity(header_words)
    _require(len(group_words) == contract.GROUP_COUNT * contract.GROUP_RECORD_WORDS,
             "CONT1R3_GROUP_WORD_COUNT")
    _require(len(entry_words) == contract.ENTRY_COUNT * contract.ENTRY_RECORD_WORDS,
             "CONT1R3_ENTRY_WORD_COUNT")
    _require(len(legacy_entry_words) == contract.ENTRY_COUNT,
             "CONT1R3_LEGACY_ENTRY_WORD_COUNT")
    status = _header_value(header_words, 0x1280C)
    generation = _header_value(header_words, 0x12810)
    event_count = _header_value(header_words, 0x12824)
    exposure_count = _header_value(header_words, 0x12828)
    _require(status & 0xF == 0xB, f"CONT1R3_TELEMETRY_NOT_COMPLETE_COHERENT:{status:#x}")
    _require(not status & (1 << 2), "CONT1R3_TELEMETRY_OVERFLOW")
    _require(generation == legacy_generation, "CONT1R3_GENERATION_MISMATCH")
    _require(exposure_count == contract.ENTRY_COUNT, "CONT1R3_EXPOSURE_COUNT_NOT_82")
    _require(event_count <= contract.MAXIMUM_EVENTS, "CONT1R3_EVENT_COUNT_RANGE")

    groups = [
        decode_group(group_words[index * contract.GROUP_RECORD_WORDS:
                                 (index + 1) * contract.GROUP_RECORD_WORDS], index)
        for index in range(contract.GROUP_COUNT)
    ]
    if legacy_scan_start_tick is not None and legacy_scan_end_tick is not None:
        scan_duration = (legacy_scan_end_tick - legacy_scan_start_tick) & ((1 << 64) - 1)
        _require(scan_duration < (1 << 63), "CONT1R3_SCAN_TICK_WRAP_AMBIGUITY")
        for group in groups:
            group_offset = (group["verify_completion_tick"] - legacy_scan_start_tick) & ((1 << 64) - 1)
            _require(group_offset <= scan_duration,
                     f"CONT1R3_VERIFY_TICK_OUTSIDE_SCAN:{group['group_index']}")
    entries, _, _ = manifest.load_and_validate()
    exposures = [
        decode_entry(entry_words[index * contract.ENTRY_RECORD_WORDS:
                                 (index + 1) * contract.ENTRY_RECORD_WORDS],
                     entries[index], groups)
        for index in range(contract.ENTRY_COUNT)
    ]

    expected_transactions_by_group = [0] * contract.GROUP_COUNT
    expected_sequence: int | None = None
    events: list[dict] = []
    for exposure, legacy_word in zip(exposures, legacy_entry_words):
        index = exposure["entry_index"]
        group_index = exposure["group_index"]
        _require(exposure["scan_generation"] == generation,
                 f"CONT1R3_ENTRY_GENERATION_MISMATCH:{index}")
        if legacy_scan_start_tick is not None and legacy_scan_end_tick is not None:
            start_offset = (exposure["first_attempt_start_tick"] - legacy_scan_start_tick) & ((1 << 64) - 1)
            _require(start_offset <= scan_duration and
                     exposure["time_since_verify_ticks"] <= scan_duration,
                     f"CONT1R3_EXPOSURE_TICK_OUTSIDE_SCAN:{index}")
        _require(exposure["exposure_valid"] and exposure["first_attempt_complete"] and
                 exposure["group_verify_success_observed"] and
                 exposure["outcome_group_verify_success"],
                 f"CONT1R3_INCOMPLETE_EXPOSURE:{index}")
        _require(exposure["transactions_since_verify"] ==
                 expected_transactions_by_group[group_index],
                 f"CONT1R3_TRANSACTION_CONTEXT_MISMATCH:{index}")
        if exposure["position_in_group"] == 0:
            expected_sequence = (groups[group_index]["verify_transaction_sequence"] + 1) & 0xFFFFFFFF
        _require(exposure["first_attempt_transaction_sequence"] == expected_sequence,
                 f"CONT1R3_TRANSACTION_SEQUENCE_MISMATCH:{index}")
        expected_transactions_by_group[group_index] += 1
        expected_sequence = (int(expected_sequence) + 1) & 0xFFFFFFFF
        legacy_value = (int(legacy_word) >> 8) & 0xFF
        _require(exposure["final_value_valid"] and exposure["final_value"] == legacy_value,
                 f"CONT1R3_FINAL_VALUE_MISMATCH:{index}")
        if exposure["first_attempt_failure_event"]:
            _require(not exposure["first_attempt_success"] and
                     exposure["first_attempt_raw_cause"] in (1, 2, 3) and
                     exposure["first_attempt_decoded_cause"] ==
                     exposure["first_attempt_raw_cause"] and
                     exposure["retry_attempted"] and exposure["retry_complete"] and
                     exposure["retry_success"] and not exposure["retry_timeout"] and
                     exposure["retry_raw_cause"] == 0 and
                     exposure["retry_decoded_cause"] == 0,
                     f"CONT1R3_RECOVERED_EVENT_INVALID:{index}")
            events.append(dict(exposure))
            expected_transactions_by_group[group_index] += 1
            expected_sequence = (int(expected_sequence) + 1) & 0xFFFFFFFF
        else:
            _require(exposure["first_attempt_success"] and
                     not exposure["retry_attempted"] and
                     exposure["first_attempt_raw_cause"] == 0 and
                     exposure["first_attempt_decoded_cause"] == 0,
                     f"CONT1R3_CLEAN_EXPOSURE_INVALID:{index}")
    _require(len(events) == event_count, "CONT1R3_EVENT_COUNT_RECONCILIATION")
    _require(legacy_transaction_count == contract.CLEAN_TRANSACTION_COUNT + event_count,
             "CONT1R3_LEGACY_TRANSACTION_RECONCILIATION")
    return {
        "identity": identity,
        "status": status,
        "generation": generation,
        "event_count": event_count,
        "exposure_count": exposure_count,
        "overflow": False,
        "groups": groups,
        "exposures": exposures,
        "events": events,
        "raw_sha256": words_sha256(list(header_words) + list(group_words) + list(entry_words)),
    }


def read_header(device) -> list[int]:
    return [device.read32(address) for address in contract.HEADER_ADDRESSES]


def read_identity(device) -> dict:
    identity = validate_identity(read_header(device))
    actual = (
        device.read32(contract.IMPLEMENTATION_MAGIC_ADDRESS),
        device.read32(contract.IMPLEMENTATION_VERSION_ADDRESS),
    )
    expected = (contract.IMPLEMENTATION_MAGIC, contract.IMPLEMENTATION_VERSION)
    _require(actual == expected,
             f"CONT1R3R1_IMPLEMENTATION_IDENTITY_MISMATCH:{actual!r}")
    identity["implementation_magic"] = actual[0]
    identity["implementation_version"] = actual[1]
    return identity


def read_frozen(device, snapshot: Mapping, attempts: int = 3) -> dict:
    legacy_words = list(snapshot["_raw_words"][-contract.ENTRY_COUNT:])
    deadline = time.monotonic() + 2.0
    while True:
        readiness = device.read32(0x1280C)
        _require(not readiness & (1 << 2), "CONT1R3R1_WRITER_OVERFLOW")
        if readiness & 0xF == 0xB:
            break
        _require(time.monotonic() < deadline,
                 "CONT1R3R1_TELEMETRY_PUBLICATION_TIMEOUT")
        time.sleep(0.001)
    for attempt in range(1, attempts + 1):
        header_before = read_header(device)
        group_words = [device.read32(address) for address in contract.GROUP_ADDRESSES]
        entry_words = [device.read32(address) for address in contract.ENTRY_ADDRESSES]
        header_after = read_header(device)
        if header_before != header_after:
            continue
        result = validate_frozen(
            header_after, group_words, entry_words,
            int(snapshot["generation"]), legacy_words,
            int(snapshot["transaction_count"]),
            int(snapshot["start_ticks"]), int(snapshot["end_ticks"]),
        )
        result["consistency_attempt"] = attempt
        result["_raw_words"] = list(header_after) + group_words + entry_words
        return result
    raise TelemetryGateError("CONT1R3_TELEMETRY_CONSISTENCY_RETRIES_EXHAUSTED")
