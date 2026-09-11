#!/usr/bin/env python3
"""Governed 4x4 NVP scan orchestrator; all capture work remains DUT-local."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import time
from typing import Any

from availability_classifier_r3r1 import (
    AVAILABILITY_CLASSES,
    CAPTURE_ELIGIBLE_CLASSES,
    firmware_advance_response,
    validate_complete_matrix,
)
from controller_nvp_capture_r3r1 import Mmio as ProductMmio
from controller_nvp_capture_r3r1 import hardware_quiescent
from controller_nvp_capture_r3r1 import runtime_identity as read_product_identity


TASK = "G2B-NVP-VIDEO-DIAG1-R3R1"
DIAG_MAGIC = 0x4E565034
DIAG_VERSION = 0x00010002
DIAG_CAPABILITIES = 0x3C08
CAP_CURRENT_SESSION_SNAPSHOT_V1 = 1 << 8
CAP_HOST_OWNED_SESSION_HISTORY = 1 << 9
CAP_ONCHIP_16_SESSION_HISTORY = 1 << 10
CAP_MMIO_WRITE_RESPONSE_PROTOCOL_FIXED = 1 << 11
CONTROL = 0x3C0C
STATUS = 0x3C10
ERROR = 0x3C14
ROUND_CHANNEL = 0x3C1C
SESSION = 0x3C20
HOST_RESPONSE = 0x3C34
CURRENT_RESULT_WORD_0 = 0x3D00
CURRENT_RESULT_VALID = 0x3D20
CURRENT_RESULT_SESSION_ID = 0x3D24
CURRENT_RESULT_GENERATION = 0x3D28
DIAG_STATE = 0x3C18
ORIGINAL_ROUTE = 0x3C44
ORIGINAL_BGDCOL_78 = 0x3C48
ORIGINAL_BGDCOL_79 = 0x3C4C
I2C_TRANSACTION_COUNT = 0x3C50
I2C_NACK_COUNT = 0x3C54
I2C_TIMEOUT_COUNT = 0x3C58
FIRST_I2C_ERROR = 0x3C5C
LAST_I2C_ERROR = 0x3C60
RESTORE_STATUS = 0x3C6C
I2C_RECOVERY_COUNT = 0x3C70
COLORS = {0x6: "RED", 0x4: "GREEN", 0x3: "CYAN", 0x1: "WHITE_75_PERCENT"}
CLASSES = {
    1: "ACTIVE_STABLE", 2: "NO_VIDEO_STABLE", 3: "LOCK_UNSTABLE",
    4: "STATUS_CONTRADICTORY", 5: "I2C_STATUS_ERROR",
}
ORDERS = ((1, 2, 3, 4), (4, 3, 2, 1), (2, 3, 4, 1), (3, 4, 1, 2))
COLOR_CODES_BY_ROUND = (
    (0x6, 0x4, 0x3, 0x1),
    (0x1, 0x6, 0x4, 0x3),
    (0x3, 0x1, 0x6, 0x4),
    (0x4, 0x3, 0x1, 0x6),
)
HOST_HISTORY_FIELDS = [
    "SessionID", "SnapshotGeneration", "SnapshotCoherenceRetries", "Round",
    "RoundPosition", "Channel", "RouteRequested", "RouteReadback",
    "AssignedBGDCOL", "BGDCOLCode", "BGDCOL78", "BGDCOL79", "RawNOVID",
    "RawAGCLock", "RawComparatorLock", "RawHLock", "RawChannelStatus",
    "Classification", "ClassificationCode", "StableSamples",
    "TotalStatusSamples", "I2CTransactionCount", "I2CNackCountLow8",
    "I2CTimeoutCountLow8", "I2CBusRecoveryCountLow8", "I2CNackOverflow",
    "I2CTimeoutOverflow", "I2CBusRecoveryOverflow", "CurrentError",
    "FirstI2CErrorLow8", "LastI2CErrorLow8", "SnapshotWords",
    "CaptureResult", "CaptureBlocker", "FrameSequence", "FrameSHA256",
    "PNG_SHA256", "PixelClassification", "CleanupResult",
    "AvailabilityClassification", "CaptureEligible", "CaptureAttempted",
    "SessionObservationResult", "CapturePass", "FirmwareAdvanceAck",
    "FirmwareResponseRaw",
]
CAPTURE_DETAIL_FIELDS = [
    "PrimaryBytes",
    "PrimaryExactCompletions", "PrimaryShortCompletions",
    "PrimaryFailedCompletions", "PrimaryDuplicateCompletions",
    "PrimaryMissingCompletions", "PrimaryPendingCompletions",
    "RecordIntegrityFailures", "GlobalSequenceGaps", "AttemptSequenceGaps",
    "OverflowFlagRecords", "MalformedPrecedingFlagRecords",
    "SourceMalformedDelta", "SourceDroppedDelta", "Line0Present", "Line0SOF",
    "FrameReconstruction", "FrameSequence", "FrameSHA256", "DisableLatencyUs",
    "PhysicalQuiescence", "FinalPendingAIO", "NativeHelperNormalExit",
    "CleanupResult",
]
PIXEL_DETAIL_FIELDS = [
    "AssignedColor", "StatusClass", "DominantUYVY",
    "DominantFraction", "ExactBlackFraction", "UniqueUYVYWords",
    "UniqueYValues", "UniqueUValues", "UniqueVValues", "YMin", "YMax",
    "YMean", "YStdDev", "UMean", "UVariance", "VMean", "VVariance",
    "UniqueScanlineHashes", "LongestIdenticalScanlineRun",
    "HorizontalEdgeEnergy", "VerticalEdgeEnergy", "AssignedColorPixelMatch",
]
CAPTURE_HISTORY_FIELDS = HOST_HISTORY_FIELDS + [
    field for field in CAPTURE_DETAIL_FIELDS if field not in HOST_HISTORY_FIELDS
]
PIXEL_HISTORY_FIELDS = HOST_HISTORY_FIELDS + [
    field for field in PIXEL_DETAIL_FIELDS if field not in HOST_HISTORY_FIELDS
]
SNAPSHOT_COHERENCE_FIELDS = [
    "TimestampNs", "Phase", "ExpectedSession", "Attempt", "Retry",
    "Valid0", "Generation0", "Session0", "Word0Session", "Generation1",
    "Session1", "Valid1", "FirmwareCurrentSession", "MetadataUpperBitsZero",
    "Result", "FailureReasons",
]
FRAME_CLASSIFICATIONS = {
    "EXACT_DIGITAL_BLACK", "NEAR_BLACK_LOW_VARIANCE",
    "UNIFORM_BGDCOL_RED", "UNIFORM_BGDCOL_GREEN",
    "UNIFORM_BGDCOL_CYAN", "UNIFORM_BGDCOL_WHITE",
    "UNIFORM_OTHER_COLOR", "NONBLACK_LOW_CONTRAST",
    "NONBLACK_SPATIALLY_VARYING", "INVALID_OR_CORRUPT",
}
NO_CAPTURE_CLASSIFICATIONS = {
    "NOT_RUN_NO_VCLK", "NOT_RUN_CLOCK_PRESENT_NO_SAV",
    "NOT_RUN_SAV_RATE_UNQUALIFIED", "NOT_RUN_RESET_REGRESSION",
}


class ScanError(RuntimeError):
    pass


class BlockedError(ScanError):
    """An operational prerequisite prevented the intended measurement."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ScanError(message)


def require_unblocked(condition: bool, message: str) -> None:
    if not condition:
        raise BlockedError(message)


def write_json(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fields: list[str], rows: list[dict[str, Any]]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows({field: row.get(field, "") for field in fields}
                         for row in rows)
        handle.flush()
        os.fsync(handle.fileno())


def append_csv(path: Path, fields: list[str], row: dict[str, Any]) -> None:
    new_file = not path.exists()
    with path.open("a", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        if new_file:
            writer.writeheader()
        writer.writerow({field: row.get(field, "") for field in fields})
        handle.flush()
        os.fsync(handle.fileno())


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")))
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def fsync_directory(path: Path) -> None:
    flags = os.O_RDONLY
    if hasattr(os, "O_DIRECTORY"):
        flags |= os.O_DIRECTORY
    try:
        fd = os.open(path, flags)
    except PermissionError:
        if os.name == "nt":
            return
        raise
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def write_csv_atomic(path: Path, fields: list[str],
                     rows: list[dict[str, Any]]) -> None:
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows({field: row.get(field, "") for field in fields}
                         for row in rows)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)
    fsync_directory(path.parent)


def write_jsonl_atomic(path: Path, rows: list[dict[str, Any]]) -> None:
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="\n") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")))
            handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)
    fsync_directory(path.parent)


def persist_host_histories(status_csv: Path, status_jsonl: Path,
                           capture_csv: Path, pixel_csv: Path,
                           status_rows: list[dict[str, Any]],
                           capture_rows: list[dict[str, Any]],
                           pixel_rows: list[dict[str, Any]]) -> None:
    """Persist the canonical JSONL first, then its three CSV projections."""
    write_jsonl_atomic(status_jsonl, status_rows)
    write_csv_atomic(status_csv, HOST_HISTORY_FIELDS, status_rows)
    write_csv_atomic(capture_csv, CAPTURE_HISTORY_FIELDS, capture_rows)
    write_csv_atomic(pixel_csv, PIXEL_HISTORY_FIELDS, pixel_rows)


def verify_persisted_host_histories(status_csv: Path, status_jsonl: Path,
                                    capture_csv: Path,
                                    pixel_csv: Path) -> dict[str, Any]:
    """Read back the four host-owned histories before declaring scan PASS."""
    paths = (status_csv, status_jsonl, capture_csv, pixel_csv)
    require(all(path.is_file() for path in paths),
            "NVP_DIAG1_R1_HOST_HISTORY_FILE_MISSING")

    def csv_rows(path: Path) -> list[dict[str, Any]]:
        with path.open(encoding="utf-8", newline="") as handle:
            return list(csv.DictReader(handle))

    status_rows = csv_rows(status_csv)
    capture_rows = csv_rows(capture_csv)
    pixel_rows = csv_rows(pixel_csv)
    json_rows = [json.loads(line) for line in
                 status_jsonl.read_text(encoding="utf-8").splitlines()]
    collections = (status_rows, json_rows, capture_rows, pixel_rows)
    require(all(len(rows) == 16 for rows in collections),
            "NVP_DIAG1_R1_HOST_HISTORY_PERSISTED_ROW_COUNT_INVALID")
    expected_ids = list(range(1, 17))
    for rows in collections:
        require([int(row["SessionID"]) for row in rows] == expected_ids,
                "NVP_DIAG1_R1_HOST_HISTORY_PERSISTED_SESSION_SET_INVALID")
    require(all(set(HOST_HISTORY_FIELDS).issubset(row) for row in json_rows),
            "NVP_DIAG1_R1_HOST_HISTORY_JSONL_SCHEMA_INVALID")
    generations = [int(row["SnapshotGeneration"]) for row in json_rows]
    pairs = {(int(row["Round"]), int(row["Channel"])) for row in json_rows}
    require(generations == expected_ids and len(pairs) == 16,
            "NVP_DIAG1_R1_HOST_HISTORY_PERSISTED_SEQUENCE_INVALID")
    def valid_result(row: dict[str, Any]) -> bool:
        if row["CleanupResult"] != "PASS":
            return False
        if row["CaptureResult"] == "PASS":
            return bool(
                row["PixelClassification"] in FRAME_CLASSIFICATIONS -
                {"INVALID_OR_CORRUPT"} and
                isinstance(row["FrameSHA256"], str) and
                len(row["FrameSHA256"]) == 64 and
                row["CapturePass"] is True)
        if row["CaptureResult"] == "NOT_RUN":
            return bool(
                row["PixelClassification"] in NO_CAPTURE_CLASSIFICATIONS and
                row["CapturePass"] is False and
                row["SessionObservationResult"] ==
                "PASS_NO_BT656_CAPTURE_NOT_RUN" and
                row["FirmwareAdvanceAck"] == "PASS_AND_QUIESCENT")
        return False

    require(all(valid_result(row) for row in json_rows),
            "NVP_DIAG1_R3R1_HOST_HISTORY_PERSISTED_RESULT_INVALID")
    return {
        "status_csv_rows": len(status_rows),
        "status_jsonl_rows": len(json_rows),
        "capture_csv_rows": len(capture_rows),
        "pixel_csv_rows": len(pixel_rows),
        "unique_sessions": len(set(expected_ids)),
        "unique_round_channel_pairs": len(pairs),
        "generations_monotonic": True,
        "sha256": {
            path.name: hashlib.sha256(path.read_bytes()).hexdigest().upper()
            for path in paths
        },
    }


class DiagnosticMmio:
    def __init__(self, path: str, ledger: list[dict[str, Any]]) -> None:
        flags = os.O_RDWR | os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        self.fd = os.open(path, flags)
        self.ledger = ledger

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def read(self, offset: int, purpose: str) -> int:
        require(0x3C00 <= offset <= 0x3FFF and offset % 4 == 0,
                "NVP_DIAG1_DIAGNOSTIC_MMIO_READ_ALLOWLIST_VIOLATION")
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, "NVP_DIAG1_SHORT_DIAGNOSTIC_MMIO_READ")
        value = struct.unpack("<I", raw)[0]
        self.ledger.append({
            "TimestampNs": time.time_ns(), "Operation": "READ",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Result": "PASS",
        })
        return value

    def write_control(self, value: int, purpose: str) -> None:
        require(value in (1, 2, 4, 8, 16),
                "NVP_DIAG1_CONTROL_COMMAND_NOT_WHITELISTED")
        self._write(CONTROL, value, purpose)

    def write_capture_response(self, session_id: int, outcome: str) -> None:
        require(1 <= session_id <= 16, "NVP_DIAG1_RESPONSE_SESSION_INVALID")
        outcomes = {"PASS": 0x9, "FAIL": 0xA, "ABORT": 0xC}
        require(outcome in outcomes, "NVP_DIAG1_RESPONSE_OUTCOME_INVALID")
        low = outcomes[outcome]
        self._write(HOST_RESPONSE, (session_id << 16) | low,
                    f"HOST_CAPTURE_RESPONSE_{outcome}")

    def _write(self, offset: int, value: int, purpose: str) -> None:
        written = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(written == 4, "NVP_DIAG1_SHORT_DIAGNOSTIC_MMIO_WRITE")
        self.ledger.append({
            "TimestampNs": time.time_ns(), "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Result": "PASS",
        })


def status_bits(value: int) -> dict[str, bool]:
    return {
        "busy": bool(value & 0x001), "prepared": bool(value & 0x002),
        "capture_ready": bool(value & 0x004), "done": bool(value & 0x008),
        "error": bool(value & 0x010), "baseline_restored": bool(value & 0x020),
        "i2c_owned": bool(value & 0x040), "i2c_bus_idle": bool(value & 0x080),
        "scan_active": bool(value & 0x100),
    }


def wait_for(mmio: DiagnosticMmio, predicate, timeout: float,
             purpose: str) -> tuple[int, dict[str, bool]]:
    deadline = time.monotonic() + timeout
    last = 0
    while time.monotonic() < deadline:
        last = mmio.read(STATUS, purpose)
        bits = status_bits(last)
        if bits["error"]:
            code = mmio.read(ERROR, purpose + "_ERROR")
            raise ScanError(f"NVP_DIAG1_FIRMWARE_ERROR:0x{code:08X}")
        if predicate(bits):
            return last, bits
        time.sleep(0.010)
    raise ScanError(f"NVP_DIAG1_WAIT_TIMEOUT:{purpose}:0x{last:08X}")


def wait_for_baseline_restore(mmio: DiagnosticMmio, timeout: float,
                              purpose: str) -> tuple[int, dict[str, bool]]:
    """Wait through the expected firmware error state until restore completes."""
    deadline = time.monotonic() + timeout
    last = 0
    while time.monotonic() < deadline:
        last = mmio.read(STATUS, purpose)
        bits = status_bits(last)
        if (bits["baseline_restored"] and not bits["i2c_owned"] and
                bits["i2c_bus_idle"]):
            return last, bits
        time.sleep(0.010)
    raise ScanError(f"NVP_DIAG1_BASELINE_RESTORE_TIMEOUT:{purpose}:0x{last:08X}")


def require_exact_c2h_unowned(path: str) -> dict[str, Any]:
    """Use a device-targeted holder query; never inventory unrelated processes."""
    executable = "/usr/bin/fuser"
    require_unblocked(Path(executable).is_file(),
                      "NVP_DIAG1_R3_EXACT_C2H_HOLDER_TOOL_UNAVAILABLE")
    completed = subprocess.run(
        [executable, "--", path], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, check=False, text=True)
    holders = completed.stdout.strip()
    require_unblocked(completed.returncode in (0, 1),
                      "NVP_DIAG1_R3_EXACT_C2H_HOLDER_QUERY_FAILED")
    require_unblocked(completed.returncode == 1 and not holders,
                      "NVP_DIAG1_R3_PREBASELINE_C2H_HOLDER_PRESENT")
    return {
        "device": path,
        "holder_query": "TARGETED_FUSER_ONLY",
        "holders": [],
        "pending_aio": 0,
    }


def run_checked(command: list[str], log: Path, label: str) -> None:
    completed = subprocess.run(command, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, check=False)
    log.write_bytes(completed.stdout)
    require(completed.returncode == 0,
            f"NVP_DIAG1_{label}_FAILED:RC={completed.returncode}")


def read_json(path: Path) -> dict[str, Any]:
    require(path.is_file(), f"NVP_DIAG1_REQUIRED_RESULT_MISSING:{path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"NVP_DIAG1_RESULT_SCHEMA_INVALID:{path}")
    return value


BASELINE_FIELDS = [
    "route", "bgcolor_78", "bgcolor_79", "i2c_transaction_count",
    "i2c_nack_count", "i2c_timeout_count", "first_i2c_error",
    "last_i2c_error", "restore_status", "i2c_recovery_count",
    "diag_status", "diag_state", "diag_error", "diag_capabilities",
]


def read_visible_baseline_pass(mmio: DiagnosticMmio,
                               phase: str) -> dict[str, int]:
    """Read one host-visible functional baseline and its safety status."""
    return {
        "route": mmio.read(ORIGINAL_ROUTE, phase),
        "bgcolor_78": mmio.read(ORIGINAL_BGDCOL_78, phase),
        "bgcolor_79": mmio.read(ORIGINAL_BGDCOL_79, phase),
        "i2c_transaction_count": mmio.read(I2C_TRANSACTION_COUNT, phase),
        "i2c_nack_count": mmio.read(I2C_NACK_COUNT, phase),
        "i2c_timeout_count": mmio.read(I2C_TIMEOUT_COUNT, phase),
        "first_i2c_error": mmio.read(FIRST_I2C_ERROR, phase),
        "last_i2c_error": mmio.read(LAST_I2C_ERROR, phase),
        "restore_status": mmio.read(RESTORE_STATUS, phase),
        "i2c_recovery_count": mmio.read(I2C_RECOVERY_COUNT, phase),
        "diag_status": mmio.read(STATUS, phase),
        "diag_state": mmio.read(DIAG_STATE, phase),
        "diag_error": mmio.read(ERROR, phase),
        "diag_capabilities": mmio.read(DIAG_CAPABILITIES, phase),
    }


def persist_baseline_ledger(root: Path, name: str,
                            baseline: dict[str, int]) -> str:
    """Persist an immutable JSON/CSV ledger and JSON digest."""
    json_path = root / f"BASELINE_{name}.json"
    csv_path = root / f"BASELINE_{name}.csv"
    sha_path = root / f"BASELINE_{name}.sha256"
    rendered = {
        "baseline": name,
        "captured_utc_ns": time.time_ns(),
        "original_bank_host_visible": False,
        "original_bank_classification":
            "FIRMWARE_PRIVATE_OPERATIONAL_CONTEXT",
        **baseline,
        "route_hex": f"0x{baseline['route'] & 0xFF:02X}",
        "bgcolor_78_hex": f"0x{baseline['bgcolor_78'] & 0xFF:02X}",
        "bgcolor_79_hex": f"0x{baseline['bgcolor_79'] & 0xFF:02X}",
    }
    write_json(json_path, rendered)
    write_csv(csv_path, list(rendered), [rendered])
    digest = hashlib.sha256(json_path.read_bytes()).hexdigest().upper()
    with sha_path.open("x", encoding="ascii", newline="\n") as handle:
        handle.write(f"{digest}  {json_path.name}\n")
        handle.flush()
        os.fsync(handle.fileno())
    fsync_directory(root)
    return digest


def execute_prepare(mmio: DiagnosticMmio, baseline_root: Path,
                    name: str, expected_start_count: int
                    ) -> tuple[dict[str, int], str]:
    """Execute one physical PREPARE and prove a fresh command excursion."""
    observed_start_count = mmio.read(
        I2C_TRANSACTION_COUNT, f"PREPARE_{name}_START_COUNT")
    require_unblocked(observed_start_count == expected_start_count,
                      f"NVP_DIAG1_R3_PREPARE_{name}_START_COUNT_DRIFT")
    mmio.write_control(2, f"PREPARE_{name}")
    deadline = time.monotonic() + 10.0
    started = False
    last_status = 0
    last_state = 0
    last_count = observed_start_count
    bits: dict[str, bool] = status_bits(0)
    while time.monotonic() < deadline:
        last_status = mmio.read(STATUS, f"PREPARE_{name}_WAIT_STATUS")
        bits = status_bits(last_status)
        last_state = mmio.read(DIAG_STATE, f"PREPARE_{name}_WAIT_STATE")
        last_count = mmio.read(
            I2C_TRANSACTION_COUNT, f"PREPARE_{name}_WAIT_COUNT")
        if bits["error"]:
            code = mmio.read(ERROR, f"PREPARE_{name}_WAIT_ERROR")
            raise BlockedError(
                f"NVP_DIAG1_R3_PREPARE_{name}_FIRMWARE_ERROR:"
                f"0x{code:08X}")
        # This witness prevents PREPARE_B from accepting the still-asserted
        # terminal flags left by PREPARE_A.  A completed command observed only
        # after the first poll is still proven fresh by its strictly advanced
        # transaction count.
        started = started or bits["busy"] or last_state != 0 or (
            last_count > observed_start_count)
        terminal = (
            not bits["busy"] and bits["prepared"] and
            not bits["capture_ready"] and not bits["scan_active"] and
            not bits["error"] and bits["baseline_restored"] and
            not bits["i2c_owned"] and bits["i2c_bus_idle"] and
            last_state == 0 and last_count > observed_start_count
        )
        if started and terminal:
            break
        time.sleep(0.002)
    else:
        raise BlockedError(
            f"NVP_DIAG1_R3_PREPARE_{name}_FRESH_EXECUTION_TIMEOUT:"
            f"STATUS=0x{last_status:08X}:STATE={last_state}:"
            f"START_COUNT={observed_start_count}:LAST_COUNT={last_count}")
    require_unblocked(bits["prepared"] and bits["baseline_restored"],
                      f"NVP_DIAG1_R3_PREPARE_{name}_STATUS_INVALID")
    first = read_visible_baseline_pass(mmio, f"PREPARE_{name}_READ_1")
    second = read_visible_baseline_pass(mmio, f"PREPARE_{name}_READ_2")
    require_unblocked(first == second,
                      f"NVP_DIAG1_R3_PREPARE_{name}_HOST_DOUBLE_READ_MISMATCH")
    require_unblocked(first["diag_state"] == 0 and first["diag_error"] == 0 and
                      first["i2c_nack_count"] == 0 and
                      first["i2c_timeout_count"] == 0 and
                      first["i2c_recovery_count"] == 0 and
                      first["first_i2c_error"] == 0 and
                      first["last_i2c_error"] == 0,
                      f"NVP_DIAG1_R3_PREPARE_{name}_ERROR_STATE")
    checked = status_bits(first["diag_status"])
    require_unblocked(checked["prepared"] and checked["baseline_restored"] and
                      not checked["busy"] and not checked["capture_ready"] and
                      not checked["scan_active"] and not checked["error"] and
                      not checked["i2c_owned"] and checked["i2c_bus_idle"],
                      f"NVP_DIAG1_R3_PREPARE_{name}_COMPLETION_STATE_INVALID")
    first["captured_utc_ns"] = time.time_ns()
    first["captured_monotonic_ns"] = time.monotonic_ns()
    return first, persist_baseline_ledger(baseline_root, name, first)


def capture_session(args: argparse.Namespace, session_id: int, round_number: int,
                    channel: int, color: str, status_class: str) -> dict[str, Any]:
    label = f"session-{session_id:02d}-r{round_number}-ch{channel}"
    private_dir = args.private_root / label
    logs_dir = args.logs_root / label
    image_dir = args.images_root / label
    private_dir.mkdir(parents=True, mode=0o700)
    logs_dir.mkdir(parents=True, mode=0o700)
    image_dir.mkdir(parents=True, mode=0o700)

    capture_command = [
        sys.executable, str(args.capture_controller),
        "--user-node", args.user_node, "--c2h-node", args.c2h_node,
        "--native-helper", str(args.native_helper),
        "--private-dir", str(private_dir), "--logs-dir", str(logs_dir),
        "--linux-lock", str(args.linux_lock),
        "--expected-git-sha", args.expected_git_sha,
        "--expected-build-flags", args.expected_build_flags,
    ]
    run_checked(capture_command, logs_dir / "capture-controller.console.log",
                f"SESSION_{session_id:02d}_CAPTURE")
    controller_result = read_json(logs_dir / "controller-result.json")
    require(controller_result.get("result") == "PASS",
            f"NVP_DIAG1_SESSION_{session_id:02d}_CAPTURE_CONTRACT_FAILED")
    availability = controller_result.get("source_availability", {})
    availability_class = availability.get("availability_classification")
    require(availability_class in AVAILABILITY_CLASSES,
            f"NVP_DIAG1_R3R1_SESSION_{session_id:02d}_AVAILABILITY_INVALID")
    capture_result = controller_result.get("capture_result")
    if capture_result == "NOT_RUN":
        write_counts = controller_result.get("mmio_write_counts", {})
        quiescence = controller_result.get("physical_quiescence", {})
        no_capture_class = controller_result.get("capture_result_detail")
        require(
            controller_result.get("capture_eligible") is False and
            controller_result.get("native_helper_launched") is False and
            controller_result.get("aio_submitted") == 0 and
            controller_result.get("stream_enable_writes") == 0 and
            controller_result.get("stream_disable_writes") == 0 and
            controller_result.get("final_pending_aio") == 0 and
            write_counts.get("STREAM_ENABLE", 0) == 0 and
            write_counts.get("NORMAL_DISABLE", 0) == 0 and
            write_counts.get("SAFETY_DISABLE", 0) == 0 and
            quiescence.get("result") == "PASS" and
            controller_result.get("session_observation_result") ==
                "PASS_NO_BT656_CAPTURE_NOT_RUN" and
            controller_result.get("capture_pass") is False and
            no_capture_class in NO_CAPTURE_CLASSIFICATIONS,
            f"NVP_DIAG1_R3R1_SESSION_{session_id:02d}_NO_CAPTURE_PROOF_FAILED")
        return {
            "session_id": session_id, "round": round_number,
            "channel": channel, "assigned_color": color,
            "status_class": status_class,
            "controller": controller_result,
            "availability": availability,
            "validation": {"result": "NOT_RUN"},
            "pixels": {"result": "NOT_RUN",
                       "classification": no_capture_class},
            "private_dir": str(private_dir), "logs_dir": str(logs_dir),
            "images_dir": str(image_dir),
        }
    require(capture_result == "PASS" and
            controller_result.get("capture_eligible") is True,
            f"NVP_DIAG1_R3R1_SESSION_{session_id:02d}_CAPTURE_DISPATCH_INVALID")
    completion = controller_result.get("primary_completion", {})
    finalization = controller_result.get("native_finalization", {})
    disable_latency_us = controller_result.get("primary_complete_to_disable_us")
    require(completion.get("primary_exact_completions") == 2500 and
            completion.get("primary_bytes") == 10_240_000 and
            completion.get("primary_short_completions") == 0 and
            completion.get("primary_failed_completions") == 0 and
            completion.get("primary_duplicate_completions") == 0 and
            completion.get("primary_pending") == 0 and
            completion.get("pending_aio") == 0 and
            finalization.get("final_pending") == 0 and
            controller_result.get("normal_disable_completed") is True and
            controller_result.get("parent_quiescent_completed") is True and
            controller_result.get("native_helper_absent") is True and
            controller_result.get("native_helper_exit_code") == 0 and
            isinstance(disable_latency_us, (int, float)) and
            0 <= disable_latency_us <= 500,
            f"NVP_DIAG1_SESSION_{session_id:02d}_FINITE_CAPTURE_FAILED")

    validation_command = [
        sys.executable, str(args.validator), "--abi", str(args.abi),
        "--primary", str(private_dir / "primary.bin"),
        "--controller-result", str(logs_dir / "controller-result.json"),
        "--private-dir", str(private_dir), "--logs-dir", str(logs_dir),
    ]
    run_checked(validation_command, logs_dir / "validator.console.log",
                f"SESSION_{session_id:02d}_VALIDATION")
    validation = read_json(logs_dir / "validation-result.json")
    require(validation.get("result") == "PASS" and
            validation.get("record_integrity_failures") == 0 and
            validation.get("global_sequence_gaps") == 0 and
            validation.get("attempt_sequence_gaps") == 0 and
            validation.get("overflow_flag_records") == 0 and
            validation.get("malformed_preceding_flag_records") == 0 and
            validation.get("source_malformed_snapshot_delta") == 0 and
            validation.get("source_dropped_snapshot_delta") == 0 and
            validation.get("line_0_present") is True and
            validation.get("line_0_sof") is True and
            validation.get("frame_reconstruction") == "PASS",
            f"NVP_DIAG1_SESSION_{session_id:02d}_STRUCTURAL_CAPTURE_FAILED")

    analyzer_command = [
        sys.executable, str(args.pixel_analyzer),
        "--frame", str(private_dir / "qualified-frame.uyvy"),
        "--png", str(private_dir / "qualified-frame.png"),
        "--output-dir", str(image_dir), "--session-id", str(session_id),
        "--round", str(round_number), "--channel", str(channel),
        "--assigned-color", color, "--status-class", status_class,
    ]
    run_checked(analyzer_command, logs_dir / "pixel-analyzer.console.log",
                f"SESSION_{session_id:02d}_PIXEL_ANALYSIS")
    pixels = read_json(image_dir / "pixel-statistics.json")
    require(pixels.get("result") == "PASS" and
            pixels.get("classification") != "INVALID_OR_CORRUPT",
            f"NVP_DIAG1_SESSION_{session_id:02d}_PIXEL_ANALYSIS_INVALID")
    require(controller_result.get("primary_file_sha256") ==
            validation.get("primary_file_sha256") and
            validation.get("raw_frame_sha256") == pixels.get("frame_sha256") and
            validation.get("viewable_frame_sha256") == pixels.get("png_sha256"),
            f"NVP_DIAG1_SESSION_{session_id:02d}_CAPTURE_HASH_CHAIN_MISMATCH")
    return {
        "session_id": session_id, "round": round_number, "channel": channel,
        "assigned_color": color, "status_class": status_class,
        "controller": controller_result, "availability": availability,
        "validation": validation,
        "pixels": pixels, "private_dir": str(private_dir),
        "logs_dir": str(logs_dir), "images_dir": str(image_dir),
    }


def collect_partial_session(args: argparse.Namespace, session_id: int,
                            round_number: int, channel: int, color: str,
                            status_class: str) -> dict[str, Any]:
    """Collect already-durable child artifacts without claiming they passed."""
    label = f"session-{session_id:02d}-r{round_number}-ch{channel}"
    private_dir = args.private_root / label
    logs_dir = args.logs_root / label
    image_dir = args.images_root / label

    def optional_json(path: Path) -> dict[str, Any]:
        if not path.is_file():
            return {}
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}
        return value if isinstance(value, dict) else {}

    return {
        "session_id": session_id, "round": round_number, "channel": channel,
        "assigned_color": color, "status_class": status_class,
        "controller": optional_json(logs_dir / "controller-result.json"),
        "validation": optional_json(logs_dir / "validation-result.json"),
        "pixels": optional_json(image_dir / "pixel-statistics.json"),
        "private_dir": str(private_dir), "logs_dir": str(logs_dir),
        "images_dir": str(image_dir),
    }


def history_updates(session_result: dict[str, Any], capture_result: str,
                    blocker: str | None) -> tuple[dict[str, Any], dict[str, Any]]:
    """Flatten capture/pixel artifacts into durable host-history fields."""
    controller_result = session_result.get("controller", {})
    validation = session_result.get("validation", {})
    pixels = session_result.get("pixels", {})
    completion = controller_result.get("primary_completion", {})
    finalization = controller_result.get("native_finalization", {})
    quiescence = controller_result.get("physical_quiescence", {})
    availability = controller_result.get("source_availability", {})

    exact = completion.get("primary_exact_completions")
    short = completion.get("primary_short_completions")
    failed = completion.get("primary_failed_completions")
    duplicate = completion.get("primary_duplicate_completions")
    if all(isinstance(value, int) for value in (exact, short, failed, duplicate)):
        missing = max(0, 2500 - exact - short - failed - duplicate)
    else:
        missing = None
    final_pending = finalization.get("final_pending")
    if final_pending is None:
        final_pending = completion.get("pending_aio")
    if final_pending is None:
        final_pending = controller_result.get("final_pending_aio")
    quiescence_result = (quiescence.get("result") if isinstance(quiescence, dict)
                         else quiescence)
    if quiescence_result is None:
        quiescence_result = controller_result.get("failure_path_quiescence")
    helper_absent = controller_result.get("native_helper_absent")
    if helper_absent is None:
        helper_absent = controller_result.get("native_helper_exit_code") is not None
    cleanup_pass = (
        quiescence_result == "PASS" and final_pending == 0 and helper_absent is True
    )
    cleanup_failed = (
        quiescence_result == "FAIL" or
        (isinstance(final_pending, int) and final_pending != 0) or
        helper_absent is False
    )
    cleanup_result = ("PASS" if cleanup_pass else
                      "FAIL" if cleanup_failed else "UNRESOLVED")
    capture_fields = {
        "CaptureResult": capture_result,
        "CaptureBlocker": blocker or "",
        "PrimaryBytes": completion.get("primary_bytes"),
        "PrimaryExactCompletions": exact,
        "PrimaryShortCompletions": short,
        "PrimaryFailedCompletions": failed,
        "PrimaryDuplicateCompletions": duplicate,
        "PrimaryMissingCompletions": missing,
        "PrimaryPendingCompletions": completion.get("primary_pending"),
        "RecordIntegrityFailures": validation.get("record_integrity_failures"),
        "GlobalSequenceGaps": validation.get("global_sequence_gaps"),
        "AttemptSequenceGaps": validation.get("attempt_sequence_gaps"),
        "OverflowFlagRecords": validation.get("overflow_flag_records"),
        "MalformedPrecedingFlagRecords": validation.get(
            "malformed_preceding_flag_records"),
        "SourceMalformedDelta": validation.get("source_malformed_snapshot_delta"),
        "SourceDroppedDelta": validation.get("source_dropped_snapshot_delta"),
        "Line0Present": validation.get("line_0_present"),
        "Line0SOF": validation.get("line_0_sof"),
        "FrameReconstruction": validation.get("frame_reconstruction"),
        "FrameSequence": validation.get("frame_source_sequence", "NOT_REACHED"),
        "FrameSHA256": pixels.get("frame_sha256",
                                  validation.get("raw_frame_sha256", "NOT_REACHED")),
        "PNG_SHA256": pixels.get("png_sha256",
                                 validation.get("viewable_frame_sha256",
                                                "NOT_REACHED")),
        "PixelClassification": pixels.get("classification", "NOT_REACHED"),
        "DisableLatencyUs": controller_result.get("primary_complete_to_disable_us"),
        "PhysicalQuiescence": quiescence_result,
        "FinalPendingAIO": final_pending,
        "NativeHelperNormalExit":
            controller_result.get("native_helper_exit_code") == 0,
        "CleanupResult": cleanup_result,
        "AvailabilityClassification": availability.get(
            "availability_classification"),
        "CaptureEligible": controller_result.get("capture_eligible"),
        "CaptureAttempted": controller_result.get(
            "native_helper_launched", False),
        "SessionObservationResult": controller_result.get(
            "session_observation_result"),
        "CapturePass": controller_result.get("capture_pass"),
        "FirmwareAdvanceAck": controller_result.get(
            "firmware_advance_ack"),
        "FirmwareResponseRaw": "NOT_YET_ACKNOWLEDGED",
    }
    pixel_fields = {
        "AssignedColor": session_result.get("assigned_color"),
        "StatusClass": session_result.get("status_class"),
        "DominantUYVY": pixels.get("dominant_uyvy_word_hex"),
        "DominantFraction": pixels.get("dominant_uyvy_fraction"),
        "ExactBlackFraction": pixels.get("exact_black_fraction"),
        "UniqueUYVYWords": pixels.get("unique_uyvy_words"),
        "UniqueYValues": pixels.get("unique_y_values"),
        "UniqueUValues": pixels.get("unique_u_values"),
        "UniqueVValues": pixels.get("unique_v_values"),
        "YMin": pixels.get("y_min"), "YMax": pixels.get("y_max"),
        "YMean": pixels.get("y_mean"), "YStdDev": pixels.get("y_stddev"),
        "UMean": pixels.get("u_mean"), "UVariance": pixels.get("u_variance"),
        "VMean": pixels.get("v_mean"), "VVariance": pixels.get("v_variance"),
        "UniqueScanlineHashes": pixels.get("unique_scanline_hashes"),
        "LongestIdenticalScanlineRun": pixels.get(
            "longest_identical_scanline_run"),
        "HorizontalEdgeEnergy": pixels.get("horizontal_edge_energy"),
        "VerticalEdgeEnergy": pixels.get("vertical_edge_energy"),
        "AssignedColorPixelMatch": pixels.get("assigned_bgcolor_pixel_match"),
    }
    return capture_fields, pixel_fields


def decode_result_entry(words: list[int]) -> dict[str, Any]:
    require(len(words) == 8, "NVP_DIAG1_R1_SNAPSHOT_WORD_COUNT_INVALID")
    return {
        "session_id": words[0] & 0xFFFF,
        "round": (words[0] >> 18) & 0x7,
        "channel": (words[0] >> 21) & 0x7,
        "classification": (words[0] >> 24) & 0xFF,
        "route_requested": (words[1] >> 24) & 0xFF,
        "route_readback": (words[1] >> 16) & 0xFF,
        "bgcolor_code": (words[1] >> 8) & 0xFF,
        "stable_sample_count": words[1] & 0xFF,
        "raw_novid": (words[2] >> 24) & 0xFF,
        "raw_agc_lock": (words[2] >> 16) & 0xFF,
        "raw_cmp_lock": (words[2] >> 8) & 0xFF,
        "raw_h_lock": words[2] & 0xFF,
        "raw_channel_status": (words[3] >> 24) & 0xFF,
        "bgcolor_78": (words[3] >> 16) & 0xFF,
        "bgcolor_79": (words[3] >> 8) & 0xFF,
        "total_status_samples": words[3] & 0xFF,
        "round_position": (words[4] >> 6) & 0x7,
        "round_index_redundant": (words[4] >> 3) & 0x7,
        "channel_redundant": words[4] & 0x7,
        "classification_redundant": (words[4] >> 16) & 0xFF,
        "i2c_transaction_count_at_snapshot": words[5],
        "i2c_nack_count_low8": words[6] & 0xFF,
        "i2c_timeout_count_low8": (words[6] >> 8) & 0xFF,
        "i2c_bus_recovery_count_low8": (words[6] >> 16) & 0xFF,
        "i2c_nack_count_overflow": bool(words[6] & (1 << 24)),
        "i2c_timeout_count_overflow": bool(words[6] & (1 << 25)),
        "i2c_bus_recovery_count_overflow": bool(words[6] & (1 << 26)),
        "error": words[7] & 0xFFFF,
        "first_i2c_error_low8": (words[7] >> 16) & 0xFF,
        "last_i2c_error_low8": (words[7] >> 24) & 0xFF,
        "snapshot_words_hex": [f"0x{word:08X}" for word in words],
        "reserved_bits_zero": (
            (words[0] & 0x00030000) == 0 and
            (words[1] & 0xF800F000) == 0 and
            (words[4] & 0xFF00FE00) == 0 and
            (words[6] & 0xF8000000) == 0
        ),
    }


def read_coherent_snapshot(mmio: DiagnosticMmio, expected_session: int,
                           max_retries: int = 3,
                           attempt_rows: list[dict[str, Any]] | None = None,
                           phase: str = "PRE_CAPTURE") -> tuple[dict[str, Any], int]:
    """Read valid/generation/session around the payload and fail closed on drift."""
    for retry in range(max_retries + 1):
        valid0 = mmio.read(CURRENT_RESULT_VALID, "SNAPSHOT_VALID_PRE")
        generation0_raw = mmio.read(CURRENT_RESULT_GENERATION,
                                    "SNAPSHOT_GENERATION_PRE")
        session0_raw = mmio.read(CURRENT_RESULT_SESSION_ID,
                                 "SNAPSHOT_SESSION_PRE")
        words = [mmio.read(CURRENT_RESULT_WORD_0 + word * 4,
                           f"SNAPSHOT_WORD_{word}") for word in range(8)]
        generation1_raw = mmio.read(CURRENT_RESULT_GENERATION,
                                    "SNAPSHOT_GENERATION_POST")
        session1_raw = mmio.read(CURRENT_RESULT_SESSION_ID,
                                 "SNAPSHOT_SESSION_POST")
        valid1 = mmio.read(CURRENT_RESULT_VALID, "SNAPSHOT_VALID_POST")
        firmware_session_raw = mmio.read(SESSION, "SNAPSHOT_FIRMWARE_SESSION")
        decoded = decode_result_entry(words)
        metadata_upper_bits_zero = (
            generation0_raw >> 16 == 0 and generation1_raw >> 16 == 0 and
            session0_raw >> 16 == 0 and session1_raw >> 16 == 0 and
            firmware_session_raw >> 16 == 0
        )
        generation0 = generation0_raw & 0xFFFF
        generation1 = generation1_raw & 0xFFFF
        session0 = session0_raw & 0xFFFF
        session1 = session1_raw & 0xFFFF
        firmware_session = firmware_session_raw & 0xFFFF
        failure_reasons = []
        if valid0 != 1:
            failure_reasons.append("VALID0_NOT_ONE")
        if valid1 != 1:
            failure_reasons.append("VALID1_NOT_ONE")
        if generation0_raw != generation1_raw:
            failure_reasons.append("GENERATION_CHANGED")
        if session0_raw != session1_raw:
            failure_reasons.append("SNAPSHOT_SESSION_CHANGED")
        if decoded["session_id"] != session0:
            failure_reasons.append("WORD0_SESSION_MISMATCH")
        if session0_raw != firmware_session_raw:
            failure_reasons.append("FIRMWARE_SESSION_MISMATCH")
        if session0 != expected_session:
            failure_reasons.append("EXPECTED_SESSION_MISMATCH")
        if not metadata_upper_bits_zero:
            failure_reasons.append("METADATA_UPPER_BITS_NONZERO")
        coherent = (
            not failure_reasons
        )
        if attempt_rows is not None:
            attempt_rows.append({
                "TimestampNs": time.time_ns(), "Phase": phase,
                "ExpectedSession": expected_session, "Attempt": retry + 1,
                "Retry": retry, "Valid0": valid0,
                "Generation0": generation0_raw, "Session0": session0_raw,
                "Word0Session": decoded["session_id"],
                "Generation1": generation1_raw, "Session1": session1_raw,
                "Valid1": valid1,
                "FirmwareCurrentSession": firmware_session_raw,
                "MetadataUpperBitsZero": metadata_upper_bits_zero,
                "Result": "PASS" if coherent else "RETRY",
                "FailureReasons": ";".join(failure_reasons),
            })
        if coherent:
            decoded["snapshot_generation"] = generation0
            decoded["snapshot_coherence_retries"] = retry
            decoded["firmware_current_session"] = firmware_session
            return decoded, retry
    if attempt_rows is not None and attempt_rows:
        attempt_rows[-1]["Result"] = "FAIL"
    raise ScanError(
        f"NVP_DIAG1_R1_SNAPSHOT_COHERENCE_FAILED:SESSION={expected_session}"
    )


def summarize(sessions: list[dict[str, Any]], firmware: list[dict[str, Any]]) -> dict[str, Any]:
    route_passes = sum(row["route_readback"] & 0xF == row["channel"] - 1
                       for row in firmware)
    no_video_rows = [row for row in sessions if row["status_class"] == "NO_VIDEO_STABLE"]
    bg_rows = [row for row in no_video_rows
               if row["pixels"]["classification"].startswith("UNIFORM_BGDCOL_") and
               row["pixels"].get("assigned_bgcolor_pixel_match") is True]
    bg_classes = {row["pixels"]["classification"] for row in bg_rows}
    bg_assigned_colors = {row["assigned_color"] for row in bg_rows}
    bg_hashes = {row["pixels"]["frame_sha256"] for row in bg_rows}
    bg_dominant_words = {row["pixels"].get("dominant_uyvy_word_hex") for row in bg_rows}
    stuck_black = any(row["pixels"]["classification"] == "EXACT_DIGITAL_BLACK"
                      for row in no_video_rows)
    all_structural = len(sessions) == 16 and all(
        row["controller"].get("result") == "PASS" and
        row["validation"].get("result") == "PASS" and
        row["validation"].get("record_integrity_failures") == 0 and
        row["validation"].get("global_sequence_gaps") == 0 and
        row["validation"].get("attempt_sequence_gaps") == 0 and
        row["validation"].get("overflow_flag_records") == 0 and
        row["validation"].get("malformed_preceding_flag_records") == 0 and
        row["validation"].get("source_dropped_snapshot_delta") == 0 and
        row["validation"].get("frame_reconstruction") == "PASS"
        for row in sessions
    )
    channel_summary: dict[str, Any] = {}
    logical_camera = None
    camera_temporal = "NOT_TESTED"
    per_channel_bgcolor_pass = True
    for channel in range(1, 5):
        rows = [row for row in sessions if row["channel"] == channel]
        active = [row for row in rows if row["status_class"] == "ACTIVE_STABLE"]
        no_video = [row for row in rows if row["status_class"] == "NO_VIDEO_STABLE"]
        live = [row for row in active if row["pixels"]["classification"] in
                ("NONBLACK_SPATIALLY_VARYING", "NONBLACK_LOW_CONTRAST") and
                 not row["pixels"]["assigned_bgcolor_pixel_match"]]
        hashes = {row["pixels"]["frame_sha256"] for row in live}
        channel_bg_rows = [row for row in no_video
                           if row["pixels"].get("assigned_bgcolor_pixel_match") is True and
                           row["pixels"]["classification"].startswith(
                               "UNIFORM_BGDCOL_")]
        channel_bg_colors = {row["assigned_color"] for row in channel_bg_rows}
        channel_bg_hashes = {row["pixels"]["frame_sha256"] for row in channel_bg_rows}
        channel_bg_dominants = {
            row["pixels"].get("dominant_uyvy_word_hex") for row in channel_bg_rows
        }
        # Every NO_VIDEO_STABLE observation must match the assigned BGDCOL.
        # The additional distinctness gate applies when all four rounds for a
        # channel are no-video.  Do not let an ACTIVE/unstable round mask a
        # wrong-color no-video observation in one of the remaining rounds.
        channel_bg_pass = len(channel_bg_rows) == len(no_video) and (
            len(no_video) != 4 or (
                len(channel_bg_colors) >= 3 and len(channel_bg_hashes) >= 3 and
                len(channel_bg_dominants) >= 3
            )
        )
        per_channel_bgcolor_pass = per_channel_bgcolor_pass and channel_bg_pass
        channel_summary[f"CH{channel}"] = {
            "active_rounds": len(active), "no_video_rounds": len(no_video),
            "unstable_or_contradictory_rounds": 4 - len(active) - len(no_video),
            "complete_captures": len(rows),
            "exact_black_captures": sum(row["pixels"]["classification"] ==
                                         "EXACT_DIGITAL_BLACK" for row in rows),
            "bgcolor_matched_captures": len(channel_bg_rows),
            "nonblack_live_captures": len(live),
            "frame_hashes": sorted({row["pixels"]["frame_sha256"] for row in rows}),
            "bgcolor_gate": "PASS" if channel_bg_pass else "FAIL",
            "distinct_bgcolor_assignments": len(channel_bg_colors),
            "distinct_bgcolor_hashes": len(channel_bg_hashes),
            "distinct_bgcolor_dominant_words": len(channel_bg_dominants),
        }
        if len(active) >= 2 and len(live) >= 2 and logical_camera is None:
            logical_camera = channel
            camera_temporal = "PASS" if len(hashes) >= 2 else "STATIC"

    bgcolor_multi_color = (
        len(bg_assigned_colors) >= 3 and len(bg_hashes) >= 3 and
        len(bg_dominant_words) >= 3 and per_channel_bgcolor_pass
    )
    if stuck_black:
        digital_path = "FAIL_STUCK_DIGITAL_BLACK"
    elif bgcolor_multi_color:
        digital_path = "PASS_BGDCOL_MULTI_COLOR"
    elif logical_camera is not None:
        digital_path = "PASS_LIVE_NONBLACK"
    else:
        digital_path = "UNRESOLVED"

    all_no_video = len(no_video_rows) == 16
    contradictory = any(row["status_class"] in
                        ("LOCK_UNSTABLE", "STATUS_CONTRADICTORY") for row in sessions)
    if stuck_black or route_passes != 16 or not all_structural or not per_channel_bgcolor_pass:
        overall = "FAIL"
    elif logical_camera is not None:
        spatial = any(row["channel"] == logical_camera and
                      row["pixels"]["classification"] == "NONBLACK_SPATIALLY_VARYING"
                      for row in sessions)
        if spatial and camera_temporal == "PASS":
            overall = "PASS_END_TO_END_CAMERA_IMAGE_QUALIFIED"
        elif spatial and camera_temporal == "STATIC":
            overall = "PASS_END_TO_END_STATIC_CAMERA_IMAGE_QUALIFIED"
        else:
            # Repeated ACTIVE status plus non-black low-contrast content proves
            # the logical VIN, but it does not satisfy the stronger spatial
            # image gate.  Keep the external connector explicitly open.
            overall = "PASS_LOGICAL_CAMERA_CHANNEL_IDENTIFIED_PHYSICAL_CONNECTOR_OPEN"
    elif all_no_video and digital_path == "PASS_BGDCOL_MULTI_COLOR":
        overall = "PASS_ALL_CHANNELS_NO_VIDEO_DIGITAL_PATH_PROVEN_BY_BGDCOL"
    elif contradictory:
        overall = "PASS_SCAN_COMPLETE_STATUS_CONTRADICTORY"
    elif digital_path in ("PASS_BGDCOL_MULTI_COLOR", "PASS_LIVE_NONBLACK"):
        overall = "PASS_DIGITAL_PATH_PROVEN_CAMERA_FORMAT_OR_ANALOG_INPUT_OPEN"
    else:
        overall = "FAIL"
    return {
        "route_readbacks_passed": route_passes,
        "bgcolor_classes_observed": sorted(bg_classes),
        "bgcolor_colors_captured_distinctly": len(bg_assigned_colors),
        "bgcolor_frame_hashes_distinct": len(bg_hashes),
        "bgcolor_dominant_words_distinct": len(bg_dominant_words),
        "per_channel_bgcolor_gate": per_channel_bgcolor_pass,
        "all_captures_structurally_valid": all_structural,
        "downstream_digital_pixel_path": digital_path,
        "logical_active_camera_channel": logical_camera,
        "camera_temporal_response": camera_temporal,
        "all_channels_no_video": all_no_video,
        "channel_summary": channel_summary,
        "overall_result": overall,
    }


def summarize_r3r1(sessions: list[dict[str, Any]],
                    firmware: list[dict[str, Any]]) -> dict[str, Any]:
    """Summarize a complete observation matrix without equating ACK with capture."""
    validate_complete_matrix([
        {
            "session_id": row["session_id"], "round": row["round"],
            "channel": row["channel"],
            "availability_classification": row["controller"]
                ["source_availability"]["availability_classification"],
        }
        for row in sessions
    ])
    route_passes = sum(
        row["route_readback"] & 0xF == row["channel"] - 1
        for row in firmware)
    captures = [row for row in sessions
                if row["controller"].get("capture_result") == "PASS"]
    no_captures = [row for row in sessions
                   if row["controller"].get("capture_result") == "NOT_RUN"]
    eligible = [row for row in sessions
                if row["controller"].get("capture_eligible") is True]
    reset_recovered = [row for row in sessions if row["controller"]
                       ["source_availability"]["availability_classification"] ==
                       "BT656_READY_ONLY_AFTER_RESET"]
    reset_regressed = [row for row in sessions if row["controller"]
                       ["source_availability"]["availability_classification"] ==
                       "BT656_READY_PRE_RESET_BUT_LOST_AFTER_RESET"]
    no_sav = [row for row in no_captures if row["controller"]
              ["source_availability"]["availability_classification"] ==
              "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET"]
    no_vclk = [row for row in no_captures if row["controller"]
               ["source_availability"]["availability_classification"] ==
               "NO_VCLK_RESET_NOT_ATTEMPTED"]
    all_capture_structure = all(
        row["validation"].get("result") == "PASS" and
        row["validation"].get("record_integrity_failures") == 0 and
        row["validation"].get("global_sequence_gaps") == 0 and
        row["validation"].get("attempt_sequence_gaps") == 0 and
        row["validation"].get("overflow_flag_records") == 0 and
        row["validation"].get("malformed_preceding_flag_records") == 0 and
        row["validation"].get("source_dropped_snapshot_delta") == 0 and
        row["validation"].get("frame_reconstruction") == "PASS"
        for row in captures)
    all_no_capture_safe = all(
        row["controller"].get("native_helper_launched") is False and
        row["controller"].get("aio_submitted") == 0 and
        row["controller"].get("stream_enable_writes") == 0 and
        row["controller"].get("final_pending_aio") == 0 and
        row["controller"].get("physical_quiescence", {}).get("result") == "PASS"
        for row in no_captures)

    channel_summary: dict[str, Any] = {}
    logical_camera: int | None = None
    camera_temporal = "NOT_TESTED"
    multi_color_channels: list[int] = []
    captured_channels: list[int] = []
    for channel in range(1, 5):
        rows = [row for row in sessions if row["channel"] == channel]
        channel_available = [row for row in rows if row["controller"]
                             ["source_availability"]
                             ["availability_classification"] in
                             CAPTURE_ELIGIBLE_CLASSES]
        channel_captures = [row for row in rows if row in captures]
        if channel_captures:
            captured_channels.append(channel)
        classes = [row["controller"]["source_availability"]
                   ["availability_classification"] for row in rows]
        if len(channel_available) == 4:
            availability_summary = "BT656_AVAILABLE_4_OF_4"
        elif channel_available:
            availability_summary = "BT656_AVAILABLE_INTERMITTENT"
        elif len(rows) == 4 and all(
                value == "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET"
                for value in classes):
            availability_summary = "CLOCK_PRESENT_NO_SAV_4_OF_4"
        elif len(rows) == 4 and all(
                value == "NO_VCLK_RESET_NOT_ATTEMPTED" for value in classes):
            availability_summary = "NO_VCLK_4_OF_4"
        elif len(rows) == 4:
            availability_summary = "MIXED_AVAILABILITY"
        else:
            availability_summary = "NOT_ENOUGH_VALID_OBSERVATIONS"

        bg_rows = [row for row in channel_captures
                   if row["status_class"] == "NO_VIDEO_STABLE" and
                   row["pixels"].get("assigned_bgcolor_pixel_match") is True and
                   str(row["pixels"].get("classification", "")).startswith(
                       "UNIFORM_BGDCOL_")]
        colors = {row["assigned_color"] for row in bg_rows}
        hashes = {row["pixels"].get("frame_sha256") for row in bg_rows}
        dominants = {row["pixels"].get("dominant_uyvy_word_hex")
                     for row in bg_rows}
        if len(colors) >= 3 and len(hashes) >= 3 and len(dominants) >= 3:
            bg_path = "PROVEN_MULTI_COLOR"
            multi_color_channels.append(channel)
        elif bg_rows:
            bg_path = "PROVEN_SINGLE_COLOR"
        elif not channel_captures:
            bg_path = "NOT_TESTED_NO_BT656"
        else:
            bg_path = "FAIL_COLOR_MISMATCH"

        live = [row for row in channel_captures
                if row["status_class"] == "ACTIVE_STABLE" and
                row["pixels"].get("classification") in
                ("NONBLACK_SPATIALLY_VARYING", "NONBLACK_LOW_CONTRAST") and
                row["pixels"].get("assigned_bgcolor_pixel_match") is False]
        if len(live) >= 2 and logical_camera is None:
            logical_camera = channel
            camera_temporal = (
                "PASS" if len({row["pixels"].get("frame_sha256")
                               for row in live}) >= 2 else "STATIC")
        channel_summary[f"CH{channel}"] = {
            "availability": availability_summary,
            "availability_classes": classes,
            "captures": len(channel_captures),
            "bgcolor_colors_captured": len(colors),
            "bgcolor_pixel_path": bg_path,
            "active_camera_captures": len(live),
        }

    if multi_color_channels:
        digital_path = "PASS_MULTI_COLOR_ONE_OR_MORE_CHANNELS"
    elif captures:
        digital_path = "PASS_SINGLE_COLOR_CH1_INHERITED_AND_CONFIRMED"
    elif no_captures:
        digital_path = "NOT_PROVEN"
    else:
        digital_path = "PARTIAL_PASS"

    if logical_camera is not None:
        spatial = any(
            row["channel"] == logical_camera and
            row["pixels"].get("classification") ==
            "NONBLACK_SPATIALLY_VARYING" for row in captures)
        if spatial and camera_temporal == "PASS":
            overall = "PASS_END_TO_END_CAMERA_IMAGE_QUALIFIED"
        else:
            overall = "PASS_LOGICAL_CAMERA_CHANNEL_IDENTIFIED_PHYSICAL_CONNECTOR_OPEN"
    elif reset_regressed:
        overall = "PASS_RESET_REGRESSION_IDENTIFIED_MATRIX_COMPLETE"
    elif reset_recovered:
        overall = "PASS_RESET_RECOVERED_ONE_OR_MORE_ROUTES"
    elif len(eligible) == 16 and len(captures) == 16:
        overall = "PASS_ALL_FOUR_CHANNELS_BT656_AVAILABLE_CAMERA_NOT_DETECTED"
    elif not eligible:
        overall = "PASS_NO_CHANNEL_BT656_AVAILABLE_MATRIX_COMPLETE"
    elif (set(captured_channels) == {1} and
          channel_summary["CH1"]["availability"] ==
          "BT656_AVAILABLE_4_OF_4"):
        overall = "PASS_CH1_ONLY_BT656_AVAILABLE_MATRIX_COMPLETE"
    else:
        overall = "PASS_PARTIAL_BT656_AVAILABILITY_MATRIX_COMPLETE"

    return {
        "overall_result": overall,
        "route_readbacks_passed": route_passes,
        "sessions_observed": len(sessions),
        "sessions_acknowledged": len(sessions),
        "capture_eligible_sessions": len(eligible),
        "captures_attempted": len(captures),
        "captures_completed": len(captures),
        "captures_passed": len(captures),
        "captures_failed": 0,
        "no_capture_no_sav_sessions": len(no_sav),
        "no_capture_no_vclk_sessions": len(no_vclk),
        "reset_recovered_sessions": len(reset_recovered),
        "reset_regression_sessions": len(reset_regressed),
        "all_attempted_captures_structurally_valid": all_capture_structure,
        "all_no_capture_sessions_safe": all_no_capture_safe,
        "downstream_digital_pixel_path": digital_path,
        "logical_active_camera_channel": logical_camera,
        "camera_temporal_response": camera_temporal,
        "multi_color_channels": multi_color_channels,
        "channel_summary": channel_summary,
    }


def persist_r3r1_availability(root: Path,
                              sessions: list[dict[str, Any]]) -> None:
    """Persist compact and window-level availability evidence on the DUT."""
    window_rows: list[dict[str, Any]] = []
    matrix_rows: list[dict[str, Any]] = []
    reset_rows: list[dict[str, Any]] = []
    outcome_rows: list[dict[str, Any]] = []
    for session in sessions:
        controller = session["controller"]
        availability = controller["source_availability"]
        for phase, key in (
                ("PRE_RESET", "pre_reset_source_observation"),
                ("POST_RESET_SHORT", "post_reset_short_source_observation"),
                ("POST_RESET_EXTENDED",
                 "post_reset_extended_source_observation")):
            window = controller.get(key)
            if not window:
                continue
            window_rows.append({
                "SessionID": session["session_id"], "Round": session["round"],
                "Channel": session["channel"], "Phase": phase,
                "ElapsedMs": window.get("elapsed_ms"),
                "VCLKDelta": window.get("vclk_delta"),
                "VCLKRate": window.get("vclk_rate"),
                "SAVDelta": window.get("sav_delta"),
                "SAVRate": window.get("sav_rate"),
                "VCLKPerSAV": window.get("vclk_per_sav"),
                "SourceReady": window.get("source_ready"),
                "SourceLocked": window.get("source_locked"),
                "SourceFatal": window.get("source_fatal"),
                "TransportFatal": window.get("transport_fatal"),
                "NVPFatal": window.get("nvp_fatal"),
                "SourceMalformedDelta": window.get("source_malformed_delta"),
                "SourceDroppedDelta": window.get("source_dropped_delta"),
                "Qualified": window.get("qualified"),
            })
        selected_post = controller.get("post_reset_source_observation") or {}
        pre = controller.get("pre_reset_source_observation") or {}
        matrix_rows.append({
            "SessionID": session["session_id"], "Round": session["round"],
            "Channel": session["channel"],
            "AssignedBGDCOL": session["assigned_color"],
            "NVPClassification": session["status_class"],
            "PreResetVCLKRate": pre.get("vclk_rate"),
            "PreResetSAVRate": pre.get("sav_rate"),
            "PreResetVCLKPerSAV": pre.get("vclk_per_sav"),
            "ResetAttempted": availability.get("reset_attempted"),
            "ResetResult": controller.get("reset_stream_state"),
            "PostResetVCLKRate": selected_post.get("vclk_rate"),
            "PostResetSAVRate": selected_post.get("sav_rate"),
            "PostResetVCLKPerSAV": selected_post.get("vclk_per_sav"),
            "AvailabilityClassification": availability[
                "availability_classification"],
            "CaptureEligible": controller.get("capture_eligible"),
            "CaptureAttempted": controller.get("native_helper_launched", False),
            "CaptureResult": controller.get("capture_result"),
            "FrameClassification": session["pixels"].get("classification"),
            "FirmwareAdvanceAck": controller.get("firmware_advance_ack"),
        })
        reset_rows.append({
            "SessionID": session["session_id"],
            "PreResetQualified": availability.get("pre_reset_qualified"),
            "ResetAttempted": availability.get("reset_attempted"),
            "ResetAcknowledged": availability.get("reset_acknowledged"),
            "PostResetQualified": availability.get("post_reset_qualified"),
            "AvailabilityClassification": availability[
                "availability_classification"],
        })
        outcome_rows.append({
            "SessionID": session["session_id"],
            "SessionObservationResult": controller.get(
                "session_observation_result"),
            "CaptureResult": controller.get("capture_result"),
            "CapturePass": controller.get("capture_pass"),
            "CaptureBytes": controller.get("capture_bytes"),
            "CaptureRecords": controller.get("capture_records"),
            "FirmwareAdvanceAck": controller.get("firmware_advance_ack"),
            "FirmwareResponseRaw":
                f"0x{firmware_advance_response(session['session_id']):08X}",
        })
    write_csv_atomic(root / "availability-windows.csv",
                     list(window_rows[0]), window_rows)
    write_csv_atomic(root / "reset-isolation.csv",
                     list(reset_rows[0]), reset_rows)
    write_csv_atomic(root / "availability-matrix.csv",
                     list(matrix_rows[0]), matrix_rows)
    write_csv_atomic(root / "session-outcomes.csv",
                     list(outcome_rows[0]), outcome_rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", default="/dev/xdma0_user")
    parser.add_argument("--c2h-node", default="/dev/xdma0_c2h_0")
    parser.add_argument("--native-helper", required=True, type=Path)
    parser.add_argument("--capture-controller", required=True, type=Path)
    parser.add_argument("--validator", required=True, type=Path)
    parser.add_argument("--pixel-analyzer", required=True, type=Path)
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--private-root", required=True, type=Path)
    parser.add_argument("--logs-root", required=True, type=Path)
    parser.add_argument("--images-root", required=True, type=Path)
    parser.add_argument("--baseline-root", required=True, type=Path)
    parser.add_argument("--linux-lock", required=True, type=Path)
    parser.add_argument("--expected-git-sha", required=True)
    parser.add_argument("--expected-build-flags", required=True)
    args = parser.parse_args()

    args.private_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    args.logs_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    args.images_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    args.baseline_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    ledger: list[dict[str, Any]] = []
    sessions: list[dict[str, Any]] = []
    status_rows: list[dict[str, Any]] = []
    firmware_rows: list[dict[str, Any]] = []
    result: dict[str, Any] = {"result": "FAIL", "blocker": None}
    mmio: DiagnosticMmio | None = None
    pending_response: int | None = None
    snapshot_retries_total = 0
    snapshot_sessions: set[int] = set()
    snapshot_round_channels: set[tuple[int, int]] = set()
    last_snapshot_generation = 0
    host_history_records: list[dict[str, Any]] = []
    capture_history_records: list[dict[str, Any]] = []
    pixel_history_records: list[dict[str, Any]] = []
    snapshot_coherence_records: list[dict[str, Any]] = []
    failure_session_context: dict[str, Any] | None = None
    response_withheld_for_unsafe_quiescence = False
    product_identity: dict[str, Any] | None = None
    autoinit_identity: dict[str, Any] | None = None
    prebaseline_quiescence: dict[str, Any] | None = None
    baseline_a: dict[str, int] | None = None
    baseline_b: dict[str, int] | None = None
    baseline_comparison: dict[str, Any] | None = None
    baseline_gate_passed = False
    status_history_csv = args.logs_root / "session_status_history.csv"
    status_history_jsonl = args.logs_root / "session_status_history.jsonl"
    capture_history_csv = args.logs_root / "session_capture_history.csv"
    pixel_history_csv = args.logs_root / "session_pixel_history.csv"
    snapshot_coherence_csv = args.logs_root / "snapshot_coherence.csv"
    persist_host_histories(
        status_history_csv, status_history_jsonl, capture_history_csv,
        pixel_history_csv, host_history_records, capture_history_records,
        pixel_history_records)
    write_csv_atomic(snapshot_coherence_csv, SNAPSHOT_COHERENCE_FIELDS,
                     snapshot_coherence_records)
    try:
        lock = read_json(args.linux_lock / "receipt.json")
        require(lock.get("task") == TASK and lock.get("state") == "HELD",
                "NVP_DIAG1_LINUX_TASK_LOCK_INVALID")
        product_mmio = ProductMmio(args.user_node)
        try:
            product_identity = read_product_identity(
                product_mmio, args.expected_git_sha,
                int(args.expected_build_flags, 0))
            require(product_mmio.read(0x3800, "R2R2_TRANSPORT_IDENTITY") ==
                    0x43324831,
                    "NVP_DIAG1_R2R2_G2B_C2H_MAGIC_MISMATCH")
            require(product_mmio.read(0x3804, "R2R2_TRANSPORT_IDENTITY") ==
                    0x00010000,
                    "NVP_DIAG1_R2R2_TRANSPORT_ABI_VERSION_MISMATCH")
            pre_control = product_mmio.read(0x380C, "R3_PREBASELINE")
            pre_status = product_mmio.read(0x3810, "R3_PREBASELINE")
            require_unblocked(hardware_quiescent(pre_control, pre_status),
                              "NVP_DIAG1_R3_PREBASELINE_NOT_QUIESCENT")
            autoinit_status = product_mmio.read(0x008C,
                                                "R3_AUTOINIT")
            autoinit_nack_count = product_mmio.read(0x0090,
                                                    "R3_AUTOINIT")
            autoinit_timeout_count = product_mmio.read(0x0094,
                                                       "R3_AUTOINIT")
            autoinit_identity = {
                "done": bool(autoinit_status & 0x1),
                "error": bool(autoinit_status & 0x2),
                "busy": bool(autoinit_status & 0x4),
                "nack_count": autoinit_nack_count & 0xFFFF,
                "timeout_count": autoinit_timeout_count & 0xFFFF,
                "nvp_reset_released": bool(autoinit_status & 0x8),
                "raw_status": f"0x{autoinit_status:08X}",
                "raw_nack_count": f"0x{autoinit_nack_count:08X}",
                "raw_timeout_count": f"0x{autoinit_timeout_count:08X}",
            }
            require(not autoinit_identity["busy"] and
                    not autoinit_identity["error"] and
                    autoinit_identity["done"] and
                    autoinit_identity["nack_count"] == 0 and
                    autoinit_identity["timeout_count"] == 0 and
                    autoinit_identity["nvp_reset_released"],
                    "NVP_DIAG1_R3_AUTOINIT_IDENTITY_MISMATCH")
        finally:
            product_mmio.close()

        prebaseline_quiescence = require_exact_c2h_unowned(args.c2h_node)
        prebaseline_quiescence.update({
            "control": f"0x{pre_control:08X}",
            "status": f"0x{pre_status:08X}",
            "physical_quiescence": "PASS",
        })

        mmio = DiagnosticMmio(args.user_node, ledger)
        require(mmio.read(0x3C00, "IDENTITY") == DIAG_MAGIC,
                "NVP_DIAG1_MAGIC_MISMATCH")
        require(mmio.read(0x3C04, "IDENTITY") == DIAG_VERSION,
                "NVP_DIAG1_VERSION_MISMATCH")
        capabilities = mmio.read(DIAG_CAPABILITIES, "IDENTITY_CAPABILITIES")
        require(capabilities == 0x00000BFF and
                capabilities & CAP_CURRENT_SESSION_SNAPSHOT_V1 and
                capabilities & CAP_HOST_OWNED_SESSION_HISTORY and
                capabilities & CAP_MMIO_WRITE_RESPONSE_PROTOCOL_FIXED and
                not capabilities & CAP_ONCHIP_16_SESSION_HISTORY,
                "NVP_DIAG1_R3_CAPABILITIES_MISMATCH")
        runtime_parameters = {
            "settle_time_ms": mmio.read(0x3C24, "RUNTIME_CONTRACT"),
            "status_sample_interval_ms": mmio.read(
                0x3C28, "RUNTIME_CONTRACT"),
            "required_stable_samples": mmio.read(0x3C2C,
                                                  "RUNTIME_CONTRACT"),
            "maximum_status_wait_ms": mmio.read(0x3C30,
                                                 "RUNTIME_CONTRACT"),
            "total_scan_sessions": mmio.read(0x3C68, "RUNTIME_CONTRACT"),
        }
        require(runtime_parameters == {
                    "settle_time_ms": 200,
                    "status_sample_interval_ms": 100,
                    "required_stable_samples": 5,
                    "maximum_status_wait_ms": 2000,
                    "total_scan_sessions": 16,
                }, "NVP_DIAG1_RUNTIME_SCAN_CONTRACT_MISMATCH")
        mmio.write_control(1, "DIAG_CLEAR")
        _, clear_bits = wait_for(
            mmio,
            lambda value: (
                not value["busy"] and not value["prepared"] and
                not value["capture_ready"] and not value["scan_active"] and
                not value["error"] and not value["i2c_owned"] and
                value["i2c_bus_idle"]
            ),
            2.0,
            "DIAG_CLEAR_WAIT",
        )
        require(not clear_bits["prepared"] and
                mmio.read(DIAG_STATE, "DIAG_CLEAR_STATE") == 0 and
                mmio.read(ERROR, "DIAG_CLEAR_ERROR") == 0 and
                mmio.read(I2C_NACK_COUNT, "DIAG_CLEAR_I2C") == 0 and
                mmio.read(I2C_TIMEOUT_COUNT, "DIAG_CLEAR_I2C") == 0 and
                mmio.read(I2C_RECOVERY_COUNT, "DIAG_CLEAR_I2C") == 0,
                "NVP_DIAG1_R2R2_INITIAL_CLEAR_STATE_INVALID")
        c0 = mmio.read(I2C_TRANSACTION_COUNT, "PREPARE_C0")

        baseline_a, baseline_a_sha = execute_prepare(
            mmio, args.baseline_root, "A", c0)
        c1 = baseline_a["i2c_transaction_count"]
        baseline_b, baseline_b_sha = execute_prepare(
            mmio, args.baseline_root, "B", c1)
        c2 = baseline_b["i2c_transaction_count"]
        require_unblocked(c1 > c0 and c2 > c1,
                          "NVP_DIAG1_R3_PREPARE_TRANSACTION_COUNTER_NOT_"
                          "STRICTLY_INCREASING")
        delta_a = c1 - c0
        delta_b = c2 - c1
        require_unblocked(delta_a == delta_b,
                          "NVP_DIAG1_R3_PREPARE_TRANSACTION_SEQUENCE_MISMATCH")
        require_unblocked(
            baseline_a["bgcolor_78"] == baseline_b["bgcolor_78"] and
            baseline_a["bgcolor_79"] == baseline_b["bgcolor_79"] and
            baseline_a["route"] == baseline_b["route"],
            "NVP_DIAG1_R3_FUNCTIONAL_BASELINE_MISMATCH")
        require_unblocked((baseline_b["bgcolor_78"] & 0xFF) == 0x88 and
                          (baseline_b["bgcolor_79"] & 0xFF) == 0x88 and
                          (baseline_b["route"] & 0x0F) == 0,
                          "NVP_DIAG1_R3_BASELINE_CONTRADICTS_PRODUCT_AUTOINIT")
        baseline_comparison = {
            "result": "PASS",
            "baseline_a_sha256": baseline_a_sha,
            "baseline_b_sha256": baseline_b_sha,
            "prepare_a_transaction_start": c0,
            "prepare_a_transaction_end": c1,
            "prepare_a_transaction_delta": delta_a,
            "prepare_b_transaction_start": c1,
            "prepare_b_transaction_end": c2,
            "prepare_b_transaction_delta": delta_b,
            "prepare_a_captured_utc_ns": baseline_a["captured_utc_ns"],
            "prepare_a_captured_monotonic_ns":
                baseline_a["captured_monotonic_ns"],
            "prepare_b_captured_utc_ns": baseline_b["captured_utc_ns"],
            "prepare_b_captured_monotonic_ns":
                baseline_b["captured_monotonic_ns"],
            "bgcolor_78_equal": True,
            "bgcolor_79_equal": True,
            "route_equal": True,
            "accepted_product_crosscheck": True,
            "active_restore_authority": "PREPARE_B",
            "original_bank_host_visible": False,
            "original_bank_double_host_comparison":
                "NOT_AVAILABLE_BY_FROZEN_FIRMWARE_DESIGN",
            "original_bank_authority":
                "PREPARE_B_FIRMWARE_PRIVATE_VALUE",
            "original_bank_safety_method": (
                "EACH_PREPARE_READS_AND_RESTORES_BANK;"
                "FINAL_VERIFY_RESTORE_PHYSICALLY_READS_AND_COMPARES_BANK"
            ),
            "original_bank_governance_disposition":
                "ACCEPTED_FIRMWARE_PRIVATE_OPERATIONAL_CONTEXT",
            "functional_nvp_writes_before_baseline_agreement": 0,
        }
        baseline_comparison["double_prepare_baseline_gate"] = "PASS"
        baseline_comparison["scan_start_authorized_monotonic_ns"] = (
            time.monotonic_ns())
        write_json(args.baseline_root / "baseline-comparison.json",
                   baseline_comparison)
        write_csv(args.baseline_root / "baseline-comparison.csv",
                  list(baseline_comparison), [baseline_comparison])
        original = {
            "route": baseline_b["route"] & 0xFF,
            "bgcolor_78": baseline_b["bgcolor_78"] & 0xFF,
            "bgcolor_79": baseline_b["bgcolor_79"] & 0xFF,
        }
        baseline_gate_passed = True
        mmio.write_control(4, "START_4X4_SCAN")

        for expected_session in range(1, 17):
            wait_for(mmio, lambda bits: bits["capture_ready"], 10.0,
                     f"SESSION_{expected_session:02d}_READY")
            snapshot, retries = read_coherent_snapshot(
                mmio, expected_session, attempt_rows=snapshot_coherence_records,
                phase="PRE_CAPTURE")
            write_csv_atomic(snapshot_coherence_csv, SNAPSHOT_COHERENCE_FIELDS,
                             snapshot_coherence_records)
            snapshot_retries_total += retries
            session_id = snapshot["session_id"]
            round_number = snapshot["round"]
            channel = snapshot["channel"]
            route = snapshot["route_readback"]
            bg78 = snapshot["bgcolor_78"]
            bg79 = snapshot["bgcolor_79"]
            class_code = snapshot["classification"]
            color_code = snapshot["bgcolor_code"] & 0xF
            require(session_id == expected_session and
                    1 <= round_number <= 4 and 1 <= channel <= 4,
                    "NVP_DIAG1_SESSION_ROUND_CHANNEL_RANGE_INVALID")
            require(round_number ==
                    (expected_session - 1) // 4 + 1 and channel ==
                    ORDERS[round_number - 1][(expected_session - 1) % 4],
                    "NVP_DIAG1_SESSION_OR_ORDER_MISMATCH")
            require((route & 0xF) == channel - 1,
                    "NVP_DIAG1_ROUTE_READBACK_MISMATCH")
            expected_color_code = COLOR_CODES_BY_ROUND[round_number - 1][channel - 1]
            expected_bg78 = (
                (COLOR_CODES_BY_ROUND[round_number - 1][1] << 4) |
                COLOR_CODES_BY_ROUND[round_number - 1][0]
            )
            expected_bg79 = (
                (COLOR_CODES_BY_ROUND[round_number - 1][3] << 4) |
                COLOR_CODES_BY_ROUND[round_number - 1][2]
            )
            require(class_code in CLASSES and color_code in COLORS and
                    color_code == expected_color_code and bg78 == expected_bg78 and
                    bg79 == expected_bg79,
                    "NVP_DIAG1_STATUS_OR_COLOR_CODE_INVALID")
            require(snapshot["reserved_bits_zero"] and snapshot["error"] == 0 and
                    snapshot["route_requested"] == channel - 1 and
                    snapshot["round_index_redundant"] == round_number - 1 and
                    snapshot["round_position"] == (expected_session - 1) % 4 and
                    snapshot["channel_redundant"] == channel and
                    snapshot["classification_redundant"] == class_code and
                    (class_code not in (1, 2, 4) or
                     snapshot["stable_sample_count"] == 5),
                    "NVP_DIAG1_R1_SNAPSHOT_SEMANTIC_REDUNDANCY_FAILED")
            require(session_id not in snapshot_sessions,
                    "NVP_DIAG1_R1_DUPLICATE_SESSION_SNAPSHOT")
            require((round_number, channel) not in snapshot_round_channels,
                    "NVP_DIAG1_R1_DUPLICATE_ROUND_CHANNEL_SNAPSHOT")
            require(snapshot["snapshot_generation"] == expected_session and
                    snapshot["snapshot_generation"] > last_snapshot_generation,
                    "NVP_DIAG1_R1_SNAPSHOT_GENERATION_NOT_MONOTONIC")
            snapshot_sessions.add(session_id)
            snapshot_round_channels.add((round_number, channel))
            last_snapshot_generation = snapshot["snapshot_generation"]
            status_class = CLASSES[class_code]
            color = COLORS[color_code]
            snapshot_row = {
                "SessionID": session_id, "Round": round_number,
                "Channel": channel,
                "SnapshotGeneration": snapshot["snapshot_generation"],
                "SnapshotCoherenceRetries": retries,
                "RoundPosition": snapshot["round_position"],
                "Classification": status_class,
                "ClassificationCode": class_code,
                "RouteRequested": f"0x{snapshot['route_requested']:02X}",
                "RouteReadback": f"0x{route:02X}", "AssignedBGDCOL": color,
                "BGDCOLCode": f"0x{color_code:X}",
                "BGDCOL78": f"0x{bg78:02X}", "BGDCOL79": f"0x{bg79:02X}",
                "RawNOVID": f"0x{snapshot['raw_novid']:02X}",
                "RawAGCLock": f"0x{snapshot['raw_agc_lock']:02X}",
                "RawComparatorLock": f"0x{snapshot['raw_cmp_lock']:02X}",
                "RawHLock": f"0x{snapshot['raw_h_lock']:02X}",
                "RawChannelStatus": f"0x{snapshot['raw_channel_status']:02X}",
                "StableSamples": snapshot["stable_sample_count"],
                "TotalStatusSamples": snapshot["total_status_samples"],
                "I2CTransactionCount": snapshot[
                    "i2c_transaction_count_at_snapshot"],
                "I2CNackCountLow8": snapshot["i2c_nack_count_low8"],
                "I2CTimeoutCountLow8": snapshot["i2c_timeout_count_low8"],
                "I2CBusRecoveryCountLow8": snapshot[
                    "i2c_bus_recovery_count_low8"],
                "I2CNackOverflow": snapshot["i2c_nack_count_overflow"],
                "I2CTimeoutOverflow": snapshot["i2c_timeout_count_overflow"],
                "I2CBusRecoveryOverflow": snapshot[
                    "i2c_bus_recovery_count_overflow"],
                "CurrentError": f"0x{snapshot['error']:04X}",
                "FirstI2CErrorLow8":
                    f"0x{snapshot['first_i2c_error_low8']:02X}",
                "LastI2CErrorLow8":
                    f"0x{snapshot['last_i2c_error_low8']:02X}",
                "SnapshotWords": ";".join(snapshot["snapshot_words_hex"]),
                "CaptureResult": "NOT_STARTED",
                "CaptureBlocker": "",
                "FrameSequence": "NOT_REACHED",
                "FrameSHA256": "NOT_REACHED",
                "PNG_SHA256": "NOT_REACHED",
                "PixelClassification": "NOT_REACHED",
                "CleanupResult": "NOT_REACHED",
            }
            status_rows.append(snapshot_row)
            firmware_rows.append(snapshot)
            # The coherent status result is durable before the finite capture
            # begins; FPGA history is neither consulted nor required later.
            host_history_records.append(snapshot_row)
            capture_history_records.append(dict(snapshot_row))
            pixel_history_records.append(dict(snapshot_row))
            persist_host_histories(
                status_history_csv, status_history_jsonl, capture_history_csv,
                pixel_history_csv, host_history_records,
                capture_history_records, pixel_history_records)
            pending_response = session_id
            mmio.close()
            mmio = None

            capture_error: BaseException | None = None
            try:
                session_result = capture_session(args, session_id, round_number,
                                                 channel, color, status_class)
            except BaseException as exc:
                capture_error = exc
                session_result = collect_partial_session(
                    args, session_id, round_number, channel, color, status_class)

            mmio = DiagnosticMmio(args.user_node, ledger)
            post_attempt_start = len(snapshot_coherence_records)
            post_capture_error: BaseException | None = None
            try:
                post_capture_snapshot, post_retries = read_coherent_snapshot(
                    mmio, session_id,
                    attempt_rows=snapshot_coherence_records,
                    phase="POST_CAPTURE")
                require(post_capture_snapshot["snapshot_generation"] ==
                        snapshot["snapshot_generation"] and
                        post_capture_snapshot["snapshot_words_hex"] ==
                        snapshot["snapshot_words_hex"] and
                        (mmio.read(0x3C38, "POST_CAPTURE_ROUTE") & 0xFF) == route,
                        "NVP_DIAG1_R1_SNAPSHOT_OR_ROUTE_CHANGED_DURING_CAPTURE")
            except BaseException as exc:
                post_capture_error = exc
                if capture_error is None:
                    capture_error = exc
            finally:
                post_attempts = len(snapshot_coherence_records) - post_attempt_start
                post_retries = max(0, post_attempts - 1)
                snapshot_retries_total += post_retries
                total_session_retries = retries + post_retries
                snapshot_row["SnapshotCoherenceRetries"] = total_session_retries
                capture_history_records[-1][
                    "SnapshotCoherenceRetries"] = total_session_retries
                pixel_history_records[-1][
                    "SnapshotCoherenceRetries"] = total_session_retries
                write_csv_atomic(
                    snapshot_coherence_csv, SNAPSHOT_COHERENCE_FIELDS,
                    snapshot_coherence_records)

            capture_outcome = (
                session_result.get("controller", {}).get("capture_result")
                if capture_error is None else "FAIL")
            require(capture_outcome in ("PASS", "NOT_RUN", "FAIL"),
                    "NVP_DIAG1_R3R1_CAPTURE_OUTCOME_INVALID")
            capture_blocker = (None if capture_error is None else
                               (str(capture_error) or type(capture_error).__name__))
            if (post_capture_error is not None and
                    post_capture_error is not capture_error):
                post_detail = (str(post_capture_error) or
                               type(post_capture_error).__name__)
                capture_blocker = (
                    f"{capture_blocker};POST_CAPTURE_SNAPSHOT_CHECK:{post_detail}")
            capture_fields, pixel_fields = history_updates(
                session_result, capture_outcome, capture_blocker)
            snapshot_row.update(capture_fields)
            capture_history_records[-1].update(capture_fields)
            pixel_history_records[-1].update(capture_fields)
            pixel_history_records[-1].update(pixel_fields)
            persist_host_histories(
                status_history_csv, status_history_jsonl, capture_history_csv,
                pixel_history_csv, host_history_records,
                capture_history_records, pixel_history_records)

            if capture_error is not None:
                failure_session_context = {
                    "session_id": session_id,
                    "capture_blocker": capture_blocker,
                    "controller_result": str(
                        Path(session_result["logs_dir"]) /
                        "controller-result.json"),
                    "native_helper_pid": session_result.get(
                        "controller", {}).get("native_helper_pid"),
                    "native_helper_absent": session_result.get(
                        "controller", {}).get("native_helper_absent"),
                    "final_pending_aio": capture_fields.get("FinalPendingAIO"),
                    "physical_quiescence": capture_fields.get(
                        "PhysicalQuiescence"),
                    "cleanup_result": capture_fields.get("CleanupResult"),
                    "failure_response_withheld": False,
                }
                if capture_fields.get("PhysicalQuiescence") != "PASS":
                    response_withheld_for_unsafe_quiescence = True
                    failure_session_context["failure_response_withheld"] = True
                    raise ScanError(
                        f"NVP_DIAG1_SESSION_{session_id:02d}_FAILURE_"
                        "RESPONSE_WITHHELD_PHYSICAL_QUIESCENCE_NOT_PROVEN")
                mmio.write_capture_response(session_id, "FAIL")
                pending_response = None
                wait_for_baseline_restore(
                    mmio, 15.0, f"SESSION_{session_id:02d}_FAILURE_RESTORE")
                raise ScanError(
                    f"NVP_DIAG1_SESSION_{session_id:02d}_CAPTURE_FAILED:"
                    f"{capture_blocker}") from capture_error

            sessions.append(session_result)
            mmio.write_capture_response(session_id, "PASS")
            pending_response = None
            wait_for(mmio, lambda bits: not bits["capture_ready"], 2.0,
                     f"SESSION_{session_id:02d}_ACKNOWLEDGED")
            require(mmio.read(CURRENT_RESULT_VALID,
                              f"SESSION_{session_id:02d}_VALID_CLEARED") == 0,
                    "NVP_DIAG1_R1_SNAPSHOT_VALID_NOT_CLEARED")
            response_raw = firmware_advance_response(session_id)
            response_hex = f"0x{response_raw:08X}"
            for row in (snapshot_row, capture_history_records[-1],
                        pixel_history_records[-1]):
                row["FirmwareAdvanceAck"] = "PASS_AND_QUIESCENT"
                row["FirmwareResponseRaw"] = response_hex
            persist_host_histories(
                status_history_csv, status_history_jsonl,
                capture_history_csv, pixel_history_csv,
                host_history_records, capture_history_records,
                pixel_history_records)

        wait_for(mmio, lambda bits: bits["done"] and bits["baseline_restored"],
                 15.0, "SCAN_DONE_AND_RESTORE")
        require(len(snapshot_sessions) == 16 and len(snapshot_round_channels) == 16 and
                len(firmware_rows) == 16 and len(host_history_records) == 16 and
                len(capture_history_records) == 16 and
                len(pixel_history_records) == 16,
                "NVP_DIAG1_R1_HOST_SESSION_HISTORY_INCOMPLETE")
        final_state = {
            "status": mmio.read(STATUS, "FINAL"),
            "error": mmio.read(ERROR, "FINAL"),
            "route": mmio.read(0x3C38, "FINAL") & 0xFF,
            "bgcolor_78": mmio.read(0x3C3C, "FINAL") & 0xFF,
            "bgcolor_79": mmio.read(0x3C40, "FINAL") & 0xFF,
            "original_route": mmio.read(ORIGINAL_ROUTE, "FINAL") & 0xFF,
            "original_bgcolor_78": mmio.read(ORIGINAL_BGDCOL_78,
                                              "FINAL") & 0xFF,
            "original_bgcolor_79": mmio.read(ORIGINAL_BGDCOL_79,
                                              "FINAL") & 0xFF,
            "i2c_transaction_count": mmio.read(0x3C50, "FINAL"),
            "i2c_nack_count": mmio.read(0x3C54, "FINAL"),
            "i2c_timeout_count": mmio.read(0x3C58, "FINAL"),
            "i2c_bus_recovery_count": mmio.read(0x3C70, "FINAL"),
            "completed_sessions": mmio.read(0x3C64, "FINAL"),
            "restore_status": mmio.read(0x3C6C, "FINAL"),
        }
        require(final_state["completed_sessions"] == 16 and
                 final_state["error"] == 0 and final_state["restore_status"] == 3 and
                status_bits(final_state["status"])["baseline_restored"] and
                 status_bits(final_state["status"])["i2c_bus_idle"] and
                 not status_bits(final_state["status"])["i2c_owned"] and
                 final_state["route"] == original["route"] and
                 final_state["bgcolor_78"] == original["bgcolor_78"] and
                 final_state["bgcolor_79"] == original["bgcolor_79"] and
                final_state["original_route"] == original["route"] and
                final_state["original_bgcolor_78"] ==
                    original["bgcolor_78"] and
                final_state["original_bgcolor_79"] ==
                    original["bgcolor_79"] and
                 final_state["i2c_nack_count"] == 0 and
                 final_state["i2c_timeout_count"] == 0,
                 "NVP_VIDEO_DIAG1_PRODUCT_BASELINE_RESTORE_FAILED")
        final_state["original_bank_final_verify"] = (
            "PASS_FIRMWARE_INTERNAL_PHYSICAL_READBACK"
        )

        persisted_history = verify_persisted_host_histories(
            status_history_csv, status_history_jsonl, capture_history_csv,
            pixel_history_csv)

        persist_r3r1_availability(args.logs_root, sessions)
        summary = summarize_r3r1(sessions, firmware_rows)
        result = {
            "result": "PASS", "blocker": None,
            "overall_result": summary["overall_result"],
            "diagnostic_identity": {"magic": f"0x{DIAG_MAGIC:08X}",
                                    "version": f"0x{DIAG_VERSION:08X}",
                                    "capabilities": f"0x{capabilities:08X}"},
            "runtime_parameters": runtime_parameters,
            "product_identity": product_identity,
            "autoinit_identity": autoinit_identity,
            "prebaseline_quiescence": prebaseline_quiescence,
            "baseline_a": baseline_a, "baseline_b": baseline_b,
            "baseline_comparison": baseline_comparison,
            "original_baseline": original, "final_state": final_state,
            "persisted_host_history": persisted_history,
            "summary": summary, "sessions": sessions,
            "firmware_results": firmware_rows,
            "snapshot_protocol": {
                "coherent_snapshots": len(firmware_rows),
                "coherence_retries": snapshot_retries_total,
                "duplicate_sessions": 0,
                "missing_sessions": 16 - len(snapshot_sessions),
                "unique_round_channel_pairs": len(snapshot_round_channels),
                "last_generation": last_snapshot_generation,
                "history_owner": "HOST",
            },
        }
    except BlockedError as exc:
        result = {"result": "BLOCKED",
                  "blocker": str(exc) or type(exc).__name__,
                  "sessions_completed": len(sessions),
                  "product_identity": product_identity,
                  "autoinit_identity": autoinit_identity,
                  "prebaseline_quiescence": prebaseline_quiescence,
                  "baseline_a": baseline_a, "baseline_b": baseline_b,
                  "baseline_comparison": baseline_comparison}
        if mmio is not None:
            result["restore_failure"] = (
                "NOT_ATTEMPTED_BEFORE_DOUBLE_PREPARE_BASELINE_AGREEMENT")
    except BaseException as exc:
        result = {"result": "FAIL", "blocker": str(exc) or type(exc).__name__,
                  "sessions_completed": len(sessions),
                  "product_identity": product_identity,
                  "autoinit_identity": autoinit_identity,
                  "prebaseline_quiescence": prebaseline_quiescence,
                  "baseline_a": baseline_a, "baseline_b": baseline_b,
                  "baseline_comparison": baseline_comparison}
        if failure_session_context is not None:
            result["failure_session_context"] = failure_session_context
        if mmio is not None:
            try:
                state = status_bits(mmio.read(STATUS, "FAILURE_RESTORE_CHECK"))
                if not baseline_gate_passed:
                    # PREPARE is read-only apart from temporary bank-selector
                    # writes.  Before A/B agreement, no baseline is authorized
                    # for functional NVP restore writes, so fail closed without
                    # issuing ABORT or RESTORE.
                    result["restore_failure"] = (
                        "NOT_ATTEMPTED_BEFORE_DOUBLE_PREPARE_BASELINE_"
                        "AGREEMENT")
                else:
                    safe_restore_complete = (
                        state["baseline_restored"] and
                        not state["i2c_owned"] and state["i2c_bus_idle"] and
                        mmio.read(ERROR, "FAILURE_RESTORE_ERROR") == 0 and
                        mmio.read(RESTORE_STATUS,
                                  "FAILURE_RESTORE_STATUS") == 3 and
                        baseline_b is not None and
                        (mmio.read(0x3C38, "FAILURE_RESTORE_ROUTE") & 0xFF) ==
                            (baseline_b["route"] & 0xFF) and
                        (mmio.read(0x3C3C, "FAILURE_RESTORE_BG78") & 0xFF) ==
                            (baseline_b["bgcolor_78"] & 0xFF) and
                        (mmio.read(0x3C40, "FAILURE_RESTORE_BG79") & 0xFF) ==
                            (baseline_b["bgcolor_79"] & 0xFF))
                    if not safe_restore_complete:
                        if response_withheld_for_unsafe_quiescence:
                            result["restore_failure"] = (
                                "NVP_DIAG1_FAILURE_RESPONSE_WITHHELD_TO_"
                                "PREVENT_ROUTE_CHANGE_WITHOUT_PHYSICAL_"
                                "QUIESCENCE")
                        elif (pending_response is not None and
                              state["capture_ready"]):
                            mmio.write_capture_response(
                                pending_response, "ABORT")
                            pending_response = None
                        elif not state["error"]:
                            mmio.write_control(
                                8, "FAILURE_ABORT_AND_SAFE_RESTORE")
                        if not response_withheld_for_unsafe_quiescence:
                            wait_for_baseline_restore(
                                mmio, 15.0, "FAILURE_SAFE_RESTORE_WAIT")
                            restored = status_bits(mmio.read(
                                STATUS, "FAILURE_RESTORE_FINAL_STATUS"))
                            require(restored["baseline_restored"] and
                                    not restored["i2c_owned"] and
                                    restored["i2c_bus_idle"] and
                                    mmio.read(ERROR,
                                              "FAILURE_RESTORE_FINAL_ERROR") == 0 and
                                    mmio.read(RESTORE_STATUS,
                                              "FAILURE_RESTORE_FINAL_CODE") == 3 and
                                    baseline_b is not None and
                                    (mmio.read(0x3C38,
                                               "FAILURE_RESTORE_FINAL_ROUTE") & 0xFF) ==
                                        (baseline_b["route"] & 0xFF) and
                                    (mmio.read(0x3C3C,
                                               "FAILURE_RESTORE_FINAL_BG78") & 0xFF) ==
                                        (baseline_b["bgcolor_78"] & 0xFF) and
                                    (mmio.read(0x3C40,
                                               "FAILURE_RESTORE_FINAL_BG79") & 0xFF) ==
                                        (baseline_b["bgcolor_79"] & 0xFF),
                                    "NVP_DIAG1_R3_PRODUCT_BASELINE_RESTORE_FAILED")
                            result["failure_restore_verified"] = {
                                "result": "PASS",
                                "visible_baseline_equals_prepare_b": True,
                                "firmware_internal_bank_verify":
                                    "PASS_FIRMWARE_INTERNAL_PHYSICAL_READBACK",
                            }
            except BaseException as restore_error:
                result["restore_failure"] = str(restore_error)
    finally:
        if mmio is not None:
            mmio.close()
        if ledger:
            write_csv(args.logs_root / "diagnostic-mmio-ledger.csv",
                      ["TimestampNs", "Operation", "Offset", "Value", "Purpose",
                       "Result"], ledger)
        if status_rows:
            write_csv(args.logs_root / "status-samples.csv", list(status_rows[0]),
                      status_rows)
        if firmware_rows:
            write_csv(args.logs_root / "scan-results.csv", list(firmware_rows[0]),
                      firmware_rows)
        write_csv_atomic(snapshot_coherence_csv, SNAPSHOT_COHERENCE_FIELDS,
                         snapshot_coherence_records)
        write_json(args.logs_root / "scan-controller-result.json", result)

    print(json.dumps({"result": result["result"],
                      "overall_result": result.get("overall_result"),
                      "blocker": result.get("blocker")}, sort_keys=True), flush=True)
    return 0 if result["result"] == "PASS" else (
        2 if result["result"] == "BLOCKED" else 1)


if __name__ == "__main__":
    raise SystemExit(main())
