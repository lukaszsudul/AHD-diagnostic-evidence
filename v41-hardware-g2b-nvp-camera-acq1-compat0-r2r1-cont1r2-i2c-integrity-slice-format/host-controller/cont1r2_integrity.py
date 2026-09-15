#!/usr/bin/env python3
"""Read-only SCAN1 integrity campaign and recovered-NACK characterization.

The only MMIO writes in this module are the frozen SCAN1 ONESHOT and ACK
control values.  It has no ACQ action interface and no generic I2C interface.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import struct
import sys
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping

BUNDLE_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(BUNDLE_ROOT))

from scan1 import decoder, manifest, mmio
import cont1r1_projection as projection


EXPECTED_MAGIC = 0x4E565343
EXPECTED_VERSION = 0x00010001
EXPECTED_CAPABILITIES = 0x0000000F
EXPECTED_ENTRIES = 82
EXPECTED_GROUPS = 10
EXPECTED_CLEAN_TRANSACTIONS = 105
QUALIFICATION_TARGET = 10_000
FAST_CADENCE_ARM = 256
SAME_CADENCE_CHARACTERIZATION_MAX = 256
SPACED_CADENCE_CHARACTERIZATION_MAX = 256
SPACED_CADENCE_MIN_INTERVAL_SECONDS = 1.0
RECOVERED_NACK_EVENT_LIMIT = 10
CHECKPOINT_INTERVAL = 100

EXPECTED_MANIFEST_ENTRIES, EXPECTED_PROHIBITED_READS, EXPECTED_RAW_MANIFEST = (
    manifest.load_and_validate()
)
EXPECTED_MANIFEST_KEYS = tuple(
    (int(item.bank), int(item.register)) for item in EXPECTED_MANIFEST_ENTRIES
)

STATUS_NAMES = {
    0x0: "NONE",
    0x1: "WADDR_NACK",
    0x2: "REGADDR_NACK",
    0x3: "RADDR_NACK",
    0x4: "SCL_TIMEOUT",
    0x5: "BUS_IDLE_TIMEOUT",
    0x6: "BANK_VERIFY_MISMATCH",
    0x7: "ENTRY_BANK_READ_FAILURE",
    0x8: "ENTRY_BANK_RESTORE_FAILURE",
    0x9: "AUTOINIT_PREEMPTED",
    0xA: "INTERNAL_PROTOCOL_ERROR",
}


class IntegrityError(RuntimeError):
    pass


class IntegrityHardStop(IntegrityError):
    pass


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise IntegrityError(reason)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def canonical_json(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def decode_status(status: int) -> dict[str, object]:
    code = (int(status) >> 4) & 0x0F
    return {
        "value_valid": bool(status & 0x01),
        "retried": bool(status & 0x02),
        "bank_verified": bool(status & 0x04),
        "skipped_after_abort": bool(status & 0x08),
        "error_code": code,
        "error_name": STATUS_NAMES.get(code, f"RESERVED_0x{code:X}"),
    }


def raw_word(item: Mapping[str, object]) -> int:
    return (
        (int(item["bank"]) << 24)
        | (int(item["register"]) << 16)
        | (int(item["value"]) << 8)
        | int(item["status"])
    )


def entry_context(entries: list[dict[str, object]], index: int) -> dict[str, object] | None:
    if index < 0 or index >= len(entries):
        return None
    item = entries[index]
    return {
        "index": int(item["index"]),
        "bank": f"0x{int(item['bank']):02X}",
        "register": f"0x{int(item['register']):02X}",
        "raw_word": f"0x{raw_word(item):08X}",
        "value": f"0x{int(item['value']):02X}",
        "status": f"0x{int(item['status']):02X}",
    }


def event_rows(snapshot: Mapping[str, object], scan_index: int, cadence: str) -> list[dict[str, object]]:
    entries = [dict(item) for item in snapshot["raw_register_set"]]
    rows: list[dict[str, object]] = []
    for item in entries:
        status = int(item["status"])
        decoded = decode_status(status)
        if not decoded["retried"] and decoded["error_code"] == 0:
            continue
        index = int(item["index"])
        exact_phase = str(decoded["error_name"])
        if decoded["retried"] and decoded["value_valid"] and decoded["error_code"] == 0:
            exact_phase = "NOT_ENCODED"
        rows.append(
            {
                "scan_index": scan_index,
                "cadence": cadence,
                "entry_index": index,
                "bank": f"0x{int(item['bank']):02X}",
                "register": f"0x{int(item['register']):02X}",
                "raw_word": f"0x{raw_word(item):08X}",
                "value": f"0x{int(item['value']):02X}",
                "status": f"0x{status:02X}",
                "decoded_status": decoded,
                "exact_encoded_error_category_or_phase": exact_phase,
                "retry_flag": bool(decoded["retried"]),
                "final_validity": bool(decoded["value_valid"]),
                "previous_entry": entry_context(entries, index - 1),
                "next_entry": entry_context(entries, index + 1),
            }
        )
    return rows


def analyze_snapshot(
    snapshot: Mapping[str, object],
    scan_index: int,
    cadence: str,
    err_cnt_before: int = 0,
) -> dict[str, object]:
    entries = [dict(item) for item in snapshot["raw_register_set"]]
    events = event_rows(snapshot, scan_index, cadence)
    recovered = [
        row
        for row in events
        if row["retry_flag"] and row["final_validity"]
        and row["decoded_status"]["error_code"] == 0
    ]
    unrecovered = [row for row in events if not row["final_validity"]]
    nack_count = len(recovered)
    timeout_count = 0
    bank_verify_failures = 0
    for row in events:
        code = int(row["decoded_status"]["error_code"])
        if code in (1, 2, 3):
            nack_count += 1
        if code in (4, 5):
            timeout_count += 1
        if code == 6:
            bank_verify_failures += 1

    generation_before = int(snapshot.get("generation_before", snapshot.get("generation", 0)))
    generation_after = int(snapshot.get("generation_after", snapshot.get("generation", 0)))
    snapshot_mutation = generation_before != generation_after
    scan_flags = int(snapshot["scan_flags"])
    snapshot_valid = bool(scan_flags & 0x01) and bool(snapshot.get("snapshot_valid", True))
    restore_verified = bool(scan_flags & 0x04) and bool(snapshot.get("restore_verified", True))
    entry_count = int(snapshot["entry_count"])
    valid_count = int(snapshot["valid_entry_count"])
    failed_count = int(snapshot["failed_entry_count"])
    retried_count = int(snapshot["retried_entry_count"])
    transactions = int(snapshot["transaction_count"])
    expected_with_retries = EXPECTED_CLEAN_TRANSACTIONS + retried_count

    incomplete_publication = (
        not snapshot_valid
        or entry_count != EXPECTED_ENTRIES
        or valid_count != EXPECTED_ENTRIES
        or failed_count != 0
        or len(entries) != EXPECTED_ENTRIES
    )
    status_identity_failures = sum(
        1
        for expected, item in zip(EXPECTED_MANIFEST_ENTRIES, entries)
        if (int(item["bank"]), int(item["register"]))
        != (int(expected.bank), int(expected.register))
    )
    if status_identity_failures:
        incomplete_publication = True
    status_rows = [decode_status(int(item["status"])) for item in entries]
    entry_status_failures = sum(
        not row["value_valid"] or not row["bank_verified"] or row["error_code"] != 0
        for row in status_rows
    )
    observed_retried_entries = sum(bool(row["retried"]) for row in status_rows)
    counter_reconciliation_failed = (
        observed_retried_entries != retried_count
        or sum(not row["value_valid"] for row in status_rows) != failed_count
    )

    projection_result = "FAIL"
    projection_error = None
    try:
        projected = projection.configuration_projection({"raw_register_set": entries})
        require(len(projected) == 13, "PROJECTION_FIELD_COUNT_NOT_13")
        projection_result = "PASS"
    except Exception as exc:  # preserved verbatim as a sanitized class/message
        projection_error = f"{type(exc).__name__}:{exc}"

    transaction_mismatch = transactions != expected_with_retries
    hard_stop_reasons: list[str] = []
    if unrecovered:
        hard_stop_reasons.append("UNRECOVERED_ENTRY_ERROR")
    if timeout_count:
        hard_stop_reasons.append("TIMEOUT")
    if bank_verify_failures:
        hard_stop_reasons.append("BANK_VERIFY_FAILURE")
    if incomplete_publication:
        hard_stop_reasons.append("INCOMPLETE_PUBLICATION")
    if snapshot_mutation:
        hard_stop_reasons.append("SNAPSHOT_MUTATION")
    if not restore_verified:
        hard_stop_reasons.append("ENTRY_BANK_RESTORE_FAILURE")
    if transaction_mismatch:
        hard_stop_reasons.append("TRANSACTION_COUNT_RECONCILIATION_FAILED")
    if entry_status_failures and not unrecovered:
        hard_stop_reasons.append("ENTRY_STATUS_VALIDATION_FAILED")
    if counter_reconciliation_failed:
        hard_stop_reasons.append("HEADER_ENTRY_COUNTER_RECONCILIATION_FAILED")
    if projection_result != "PASS":
        hard_stop_reasons.append("PROJECTION_FAILURE")

    event_delta = len(events)
    return {
        "scan_index": scan_index,
        "cadence": cadence,
        "generation": generation_before,
        "entry_count": entry_count,
        "bank_group_count": int(snapshot.get("bank_group_count", EXPECTED_GROUPS)),
        "transaction_count": transactions,
        "expected_transaction_count": expected_with_retries,
        "valid_entry_count": valid_count,
        "failed_entry_count": failed_count,
        "retried_entry_count": retried_count,
        "nack_count": nack_count,
        "timeout_count": timeout_count,
        "bank_verify_failure_count": bank_verify_failures,
        "incomplete_publication": incomplete_publication,
        "snapshot_mutation": snapshot_mutation,
        "entry_bank_restore": "PASS" if restore_verified else "FAIL",
        "a8_pre": int(snapshot["a8_pre"]),
        "a8_post": int(snapshot["a8_post"]),
        "projection": projection_result,
        "projection_error": projection_error,
        "event_count": len(events),
        "recovered_nack_count": len(recovered),
        "unrecovered_error_count": len(unrecovered),
        "entry_status_failure_count": entry_status_failures,
        "counter_reconciliation_failed": counter_reconciliation_failed,
        "events": events,
        "err_cnt_authority": "HOST_DERIVED_FROM_FROZEN_SCAN_EVENTS",
        "err_cnt_before": err_cnt_before,
        "err_cnt_after": err_cnt_before + event_delta,
        "err_cnt_delta": event_delta,
        "hard_stop": bool(hard_stop_reasons),
        "hard_stop_reasons": hard_stop_reasons,
        "clean_105_transaction_scan": (
            not hard_stop_reasons
            and not recovered
            and nack_count == 0
            and transactions == EXPECTED_CLEAN_TRANSACTIONS
        ),
    }


def checkpoint_due(completed_scans: int) -> bool:
    return completed_scans > 0 and completed_scans % CHECKPOINT_INTERVAL == 0


def qualification_resume_allowed(checkpoint_exists: bool) -> bool:
    # Qualification is one uninterrupted governed process. A checkpoint is
    # evidence only and is never accepted as a resume token.
    return not checkpoint_exists


def characterization_should_stop(total_recovered_nacks: int, additional_scans: int) -> bool:
    return (
        total_recovered_nacks >= RECOVERED_NACK_EVENT_LIMIT
        or additional_scans >= SAME_CADENCE_CHARACTERIZATION_MAX
    )


def deterministic_summary(rows: Iterable[Mapping[str, object]]) -> dict[str, int]:
    material = [dict(row) for row in rows]
    return {
        "scans": len(material),
        "clean_scans": sum(bool(row.get("clean_105_transaction_scan")) for row in material),
        "nacks": sum(int(row.get("nack_count", 0)) for row in material),
        "retries": sum(int(row.get("retried_entry_count", 0)) for row in material),
        "timeouts": sum(int(row.get("timeout_count", 0)) for row in material),
        "bank_verify_failures": sum(int(row.get("bank_verify_failure_count", 0)) for row in material),
        "incomplete_publications": sum(bool(row.get("incomplete_publication")) for row in material),
        "snapshot_mutations": sum(bool(row.get("snapshot_mutation")) for row in material),
        "projection_passes": sum(row.get("projection") == "PASS" for row in material),
    }


@dataclass
class FrozenRead:
    snapshot: dict[str, object]
    raw_bytes: bytes


class LiveScanner:
    def __init__(self, device: mmio.MmioDevice):
        self.device = device
        self.entries, self.prohibited, _ = manifest.load_and_validate()

    def identity(self) -> dict[str, object]:
        digest_words = [self.device.read32(mmio.DIGEST_BASE + 4 * index) for index in range(8)]
        digest = "".join(f"{word:08X}" for word in digest_words)
        result = {
            "magic": self.device.read32(mmio.MAGIC),
            "version": self.device.read32(mmio.VERSION),
            "capabilities": self.device.read32(mmio.CAPABILITIES),
            "entry_count": self.device.read32(mmio.ENTRY_COUNT),
            "manifest_sha256": digest,
        }
        expected = {
            "magic": EXPECTED_MAGIC,
            "version": EXPECTED_VERSION,
            "capabilities": EXPECTED_CAPABILITIES,
            "entry_count": EXPECTED_ENTRIES,
            "manifest_sha256": manifest.SEMANTIC_SHA256,
        }
        if result != expected:
            raise IntegrityHardStop(f"RUNTIME_IDENTITY_LOSS:{result!r}")
        return result

    def wait_terminal(self, timeout_seconds: float = 3.0) -> int:
        deadline = time.monotonic() + timeout_seconds
        while time.monotonic() < deadline:
            status = self.device.read32(mmio.STATUS)
            if status & mmio.STATUS_DONE:
                return status
            if status & (mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT):
                raise IntegrityHardStop(f"SCANNER_TERMINAL_ERROR:{status:#010x}")
            time.sleep(0.005)
        raise IntegrityHardStop("SCANNER_ONESHOT_TIMEOUT_OR_STUCK_BUSY")

    def read_frozen(self) -> FrozenRead:
        for consistency_attempt in range(1, 4):
            generation_before = self.device.read32(mmio.GENERATION)
            header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
            header_words = [self.device.read32(address) for address in header_addresses]
            group_words = [self.device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
            entry_words = [self.device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(EXPECTED_ENTRIES)]
            generation_after = self.device.read32(mmio.GENERATION)
            values = {address: value for address, value in zip(header_addresses, header_words)}
            if generation_before != generation_after or not values[mmio.STATUS] & mmio.STATUS_DONE:
                continue
            digest = "".join(f"{values[mmio.DIGEST_BASE + 4 * index]:08X}" for index in range(8))
            if digest != manifest.SEMANTIC_SHA256:
                raise IntegrityHardStop("FROZEN_MANIFEST_IDENTITY_MISMATCH")
            raw_entries = []
            for expected, word in zip(self.entries, entry_words):
                raw_entries.append(
                    {
                        "index": int(expected.index),
                        "bank": (word >> 24) & 0xFF,
                        "register": (word >> 16) & 0xFF,
                        "value": (word >> 8) & 0xFF,
                        "status": word & 0xFF,
                        "authority": expected.authority,
                    }
                )
            scan_flags = values[mmio.SCAN_FLAGS]
            entry_bank_word = values[mmio.ENTRY_BANK]
            exit_bank_word = values[mmio.EXIT_BANK]
            a8_word = values[mmio.A8_PRE_POST]
            raw_words = header_words + group_words + entry_words
            raw = struct.pack(f"<{len(raw_words)}I", *raw_words)
            snapshot: dict[str, object] = {
                "generation_before": generation_before,
                "generation_after": generation_after,
                "consistency_attempt": consistency_attempt,
                "manifest_sha256": digest,
                "entry_count": int(values[mmio.ENTRY_COUNT]),
                "valid_entry_count": int(values[mmio.VALID_ENTRY_COUNT]),
                "failed_entry_count": int(values[mmio.FAILED_ENTRY_COUNT]),
                "retried_entry_count": int(values[mmio.RETRIED_ENTRY_COUNT]),
                "first_error_index": int(values[mmio.FIRST_ERROR_INDEX]),
                "first_error_detail": int(values[mmio.FIRST_ERROR_DETAIL]),
                "bank_group_count": EXPECTED_GROUPS,
                "transaction_count": int(scan_flags >> 16),
                "scan_flags": int(scan_flags),
                "snapshot_valid": bool(scan_flags & 0x01),
                "restore_verified": bool(scan_flags & 0x04),
                "entry_bank": int(entry_bank_word & 0xFF),
                "entry_bank_valid": bool(entry_bank_word & 0x100),
                "exit_bank": int(exit_bank_word & 0xFF),
                "exit_bank_valid": bool(exit_bank_word & 0x100),
                "a8_pre": int(a8_word & 0xFF),
                "a8_post": int((a8_word >> 8) & 0xFF),
                "start_ticks": int(values[mmio.START_TICKS_LO] | (values[mmio.START_TICKS_HI] << 32)),
                "end_ticks": int(values[mmio.END_TICKS_LO] | (values[mmio.END_TICKS_HI] << 32)),
                "raw_register_set": raw_entries,
                "group_words": group_words,
            }
            return FrozenRead(snapshot=snapshot, raw_bytes=raw)
        raise IntegrityHardStop("SNAPSHOT_MUTATION_OR_CONSISTENCY_RETRIES_EXHAUSTED")

    def start(self) -> None:
        self.identity()
        status = self.device.read32(mmio.STATUS)
        if status & mmio.STATUS_IDLE == 0 or status & (
            mmio.STATUS_BUSY | mmio.STATUS_DONE | mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT
        ):
            raise IntegrityHardStop(f"SCANNER_NOT_CLEAN_IDLE:{status:#010x}")
        self.device.write32(mmio.CONTROL, mmio.CONTROL_ONESHOT)
        self.wait_terminal()

    def acknowledge(self) -> None:
        self.device.write32(mmio.CONTROL, mmio.CONTROL_ACK_CLEAR)
        deadline = time.monotonic() + 1.0
        while time.monotonic() < deadline:
            status = self.device.read32(mmio.STATUS)
            if status & mmio.STATUS_IDLE and not status & (
                mmio.STATUS_BUSY | mmio.STATUS_DONE | mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT
            ):
                return
            time.sleep(0.002)
        raise IntegrityHardStop("SCANNER_ACK_DID_NOT_RETURN_CLEAN_IDLE")


class Recorder:
    def __init__(self, root: Path, runtime_identity: Mapping[str, object]):
        if root.exists():
            raise IntegrityError("CAMPAIGN_ROOT_PREEXISTING_NO_RESUME")
        root.mkdir(parents=True, mode=0o700)
        self.root = root
        self.raw_handle = (root / "private-snapshots.bin").open("xb")
        self.scan_handle = (root / "scans.jsonl").open("x", encoding="utf-8", newline="\n")
        self.event_handle = (root / "events.jsonl").open("x", encoding="utf-8", newline="\n")
        self.rolling = hashlib.sha256()
        self.rows: list[dict[str, object]] = []
        self.events: list[dict[str, object]] = []
        self.err_cnt = 0
        self.session_identity = str(uuid.uuid4())
        self.started_ns = time.time_ns()
        session = {
            "schema": "AHD_V41_CONT1R2_INTEGRITY_SESSION_V1",
            "session_identity": self.session_identity,
            "started_utc_ns": self.started_ns,
            "runtime_identity": dict(runtime_identity),
            "qualification_resume_permitted": False,
            "qualification_target": QUALIFICATION_TARGET,
        }
        (root / "session.json").write_text(json.dumps(session, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    def persist(self, summary: dict[str, object], raw: bytes) -> None:
        offset = self.raw_handle.tell()
        self.raw_handle.write(raw)
        self.raw_handle.flush()
        summary["raw_offset"] = offset
        summary["raw_size"] = len(raw)
        summary["snapshot_sha256"] = sha256_bytes(raw)
        self.rolling.update(raw)
        summary["rolling_snapshot_sha256"] = self.rolling.hexdigest().upper()
        for event in summary.pop("events"):
            event["snapshot_sha256"] = summary["snapshot_sha256"]
            self.event_handle.write(canonical_json(event) + "\n")
            self.event_handle.flush()
            os.fsync(self.event_handle.fileno())
            self.events.append(event)
        self.scan_handle.write(canonical_json(summary) + "\n")
        self.scan_handle.flush()
        if summary["event_count"] or summary["hard_stop"]:
            os.fsync(self.scan_handle.fileno())
            os.fsync(self.raw_handle.fileno())
        self.err_cnt = int(summary["err_cnt_after"])
        self.rows.append(dict(summary))
        if checkpoint_due(len(self.rows)):
            self.checkpoint()

    def checkpoint(self) -> None:
        self.raw_handle.flush()
        self.scan_handle.flush()
        self.event_handle.flush()
        os.fsync(self.raw_handle.fileno())
        os.fsync(self.scan_handle.fileno())
        os.fsync(self.event_handle.fileno())
        value = {
            "schema": "AHD_V41_CONT1R2_INTEGRITY_CHECKPOINT_V1",
            "session_identity": self.session_identity,
            "completed_recorded_scans": len(self.rows),
            "host_derived_err_cnt": self.err_cnt,
            "rolling_snapshot_sha256": self.rolling.hexdigest().upper(),
            "summary": deterministic_summary(self.rows),
            "recorded_utc_ns": time.time_ns(),
            "resume_permitted_for_10000_pass": False,
        }
        temp = self.root / "checkpoint.json.tmp"
        temp.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        os.replace(temp, self.root / "checkpoint.json")

    def close(self) -> None:
        self.checkpoint()
        self.raw_handle.close()
        self.scan_handle.close()
        self.event_handle.close()


def perform_scan(
    scanner: LiveScanner,
    recorder: Recorder,
    scan_index: int,
    cadence: str,
) -> dict[str, object]:
    host_start = time.monotonic_ns()
    utc_start = time.time_ns()
    scanner.start()
    frozen = scanner.read_frozen()
    host_end = time.monotonic_ns()
    summary = analyze_snapshot(frozen.snapshot, scan_index, cadence, recorder.err_cnt)
    summary.update(
        timestamp_utc_ns=utc_start,
        host_duration_ns=host_end - host_start,
        scan_duration_ticks=int(frozen.snapshot["end_ticks"]) - int(frozen.snapshot["start_ticks"]),
    )
    recorder.persist(summary, frozen.raw_bytes)
    scanner.acknowledge()
    if summary["hard_stop"]:
        raise IntegrityHardStop("SCAN_HARD_STOP:" + ",".join(summary["hard_stop_reasons"]))
    return summary


def write_csv(root: Path, name: str, rows: list[dict[str, object]]) -> None:
    fields = [
        "scan_index", "cadence", "generation", "timestamp_utc_ns", "host_duration_ns",
        "scan_duration_ticks", "entry_count", "bank_group_count", "transaction_count",
        "expected_transaction_count", "err_cnt_before", "err_cnt_after", "err_cnt_delta",
        "nack_count", "retried_entry_count", "timeout_count", "bank_verify_failure_count",
        "incomplete_publication", "snapshot_mutation", "a8_pre", "a8_post", "snapshot_sha256",
        "rolling_snapshot_sha256", "projection", "clean_105_transaction_scan", "hard_stop",
    ]
    with (root / name).open("x", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def run_live(device_path: str, output_root: Path) -> dict[str, object]:
    with mmio.MmioDevice(device_path) as device:
        scanner = LiveScanner(device)
        identity = scanner.identity()
        recorder = Recorder(output_root, identity)
        control: dict[str, object] | None = None
        qualification: list[dict[str, object]] = []
        same_cadence: list[dict[str, object]] = []
        spaced_cadence: list[dict[str, object]] = []
        trigger: dict[str, object] | None = None
        outcome = "FAIL_HARD_ERROR"
        hard_error = None
        try:
            control = perform_scan(scanner, recorder, 0, "CONTROL")
            if control["recovered_nack_count"]:
                trigger = control
            else:
                require(control["clean_105_transaction_scan"], "CONTROL_SCAN_NOT_CLEAN")
                for index in range(1, QUALIFICATION_TARGET + 1):
                    row = perform_scan(scanner, recorder, index, "FAST_BACK_TO_BACK_QUALIFICATION")
                    qualification.append(row)
                    if row["recovered_nack_count"]:
                        trigger = row
                        break

            if trigger is None:
                totals = deterministic_summary(qualification)
                require(len(qualification) == QUALIFICATION_TARGET, "QUALIFICATION_NOT_10000")
                require(totals == {
                    "scans": QUALIFICATION_TARGET,
                    "clean_scans": QUALIFICATION_TARGET,
                    "nacks": 0,
                    "retries": 0,
                    "timeouts": 0,
                    "bank_verify_failures": 0,
                    "incomplete_publications": 0,
                    "snapshot_mutations": 0,
                    "projection_passes": QUALIFICATION_TARGET,
                }, f"ZERO_ERROR_TOTAL_MISMATCH:{totals!r}")
                outcome = "PASS_ZERO_ERROR"
            else:
                total_recovered = int(trigger["recovered_nack_count"])
                additional = 0
                while not characterization_should_stop(total_recovered, additional):
                    row = perform_scan(
                        scanner,
                        recorder,
                        len(qualification) + additional + 1,
                        "SAME_BACK_TO_BACK_CHARACTERIZATION",
                    )
                    same_cadence.append(row)
                    additional += 1
                    total_recovered += int(row["recovered_nack_count"])
                if total_recovered < RECOVERED_NACK_EVENT_LIMIT:
                    previous_completion = time.monotonic()
                    for spaced_index in range(1, SPACED_CADENCE_CHARACTERIZATION_MAX + 1):
                        delay = SPACED_CADENCE_MIN_INTERVAL_SECONDS - (time.monotonic() - previous_completion)
                        if delay > 0:
                            time.sleep(delay)
                        row = perform_scan(
                            scanner,
                            recorder,
                            len(qualification) + len(same_cadence) + spaced_index,
                            "SPACED_1000MS_CHARACTERIZATION",
                        )
                        previous_completion = time.monotonic()
                        spaced_cadence.append(row)
                        total_recovered += int(row["recovered_nack_count"])
                        if total_recovered >= RECOVERED_NACK_EVENT_LIMIT:
                            break
                outcome = "FAIL_RETRIED_NACK"
        except BaseException as exc:
            hard_error = f"{type(exc).__name__}:{exc}"
            outcome = "FAIL_HARD_ERROR"
        finally:
            recorder.close()

        all_rows = recorder.rows
        write_csv(output_root, "CONT1R2_ALL_SCAN_SUMMARIES.csv", all_rows)
        write_csv(output_root, "CONT1R2_QUALIFICATION_SCANS.csv", qualification)
        write_csv(output_root, "CONT1R2_SAME_CADENCE_SCANS.csv", same_cadence)
        write_csv(output_root, "CONT1R2_SPACED_CADENCE_SCANS.csv", spaced_cadence)
        result = {
            "schema": "AHD_V41_CONT1R2_I2C_INTEGRITY_CAMPAIGN_V1",
            "result": outcome,
            "hard_error": hard_error,
            "session_identity": recorder.session_identity,
            "runtime_identity": identity,
            "control_scan": control,
            "qualification_target": QUALIFICATION_TARGET,
            "qualification_completed_scans": len(qualification),
            "qualification_summary": deterministic_summary(qualification),
            "fast_cadence_isolation_scans": min(len(qualification), FAST_CADENCE_ARM),
            "same_cadence_characterization_scans": len(same_cadence),
            "same_cadence_summary": deterministic_summary(same_cadence),
            "spaced_cadence_characterization_scans": len(spaced_cadence),
            "spaced_cadence_summary": deterministic_summary(spaced_cadence),
            "all_recorded_scans": len(all_rows),
            "all_summary": deterministic_summary(all_rows),
            "total_recovered_nacks": sum(int(row["recovered_nack_count"]) for row in all_rows),
            "recovered_nack_event_limit_reached": (
                sum(int(row["recovered_nack_count"]) for row in all_rows)
                >= RECOVERED_NACK_EVENT_LIMIT
            ),
            "functional_writes_permitted": outcome == "PASS_ZERO_ERROR",
            "functional_nvp_writes": 0,
            "generic_host_i2c": "ABSENT",
            "qualification_resume_used": False,
            "checkpoint_interval": CHECKPOINT_INTERVAL,
            "raw_snapshot_file": str(output_root / "private-snapshots.bin"),
            "raw_snapshot_file_sha256": hashlib.sha256((output_root / "private-snapshots.bin").read_bytes()).hexdigest().upper(),
        }
        (output_root / "CONT1R2_I2C_INTEGRITY_RESULT.json").write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        print(canonical_json(result))
        if outcome == "FAIL_HARD_ERROR":
            raise IntegrityHardStop(hard_error or outcome)
        return result


def self_test() -> None:
    entries, _, _ = manifest.load_and_validate()
    if len(entries) != EXPECTED_ENTRIES:
        raise IntegrityError("SELF_TEST_MANIFEST")
    if projection.manifest_preflight()["result"] != "PASS":
        raise IntegrityError("SELF_TEST_PROJECTION")
    if mmio.CONTROL_ONESHOT != 1 or mmio.CONTROL_ACK_CLEAR != 2:
        raise IntegrityError("SELF_TEST_CONTROL_VALUES")
    print("PASS CONT1R2_INTEGRITY_CONTROLLER_SELF_TEST")


def main(argv: list[str] | None = None) -> int:
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--run", action="store_true")
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--output-root", type=Path)
    args = parser.parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    if args.output_root is None:
        parser.error("--output-root is required with --run")
    run_live(args.device, args.output_root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
