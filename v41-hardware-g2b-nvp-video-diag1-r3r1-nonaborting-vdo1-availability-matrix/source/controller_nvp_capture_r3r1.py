#!/usr/bin/env python3
"""Parent-owned MMIO controller reused for one NVP DIAG1 finite capture."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
import selectors
import struct
import subprocess
import time
import traceback
from typing import Any

from availability_classifier_r3r1 import (
    choose_post_window,
    classify as classify_availability,
    no_capture_classification,
    qualified as availability_window_qualified,
    session_semantics,
)


TASK = "G2B-NVP-VIDEO-DIAG1-R3R1"
PRIMARY_RECORDS = 2500
RECORD_BYTES = 4096
PRIMARY_BYTES = PRIMARY_RECORDS * RECORD_BYTES
GUARD_RECORDS = 0
GUARD_BYTES = GUARD_RECORDS * RECORD_BYTES
TOTAL_LOGICAL_REQUESTS = PRIMARY_RECORDS + GUARD_RECORDS
MAX_OUTSTANDING_IOCBS = 1024
DISABLE_WORD = struct.pack("<I", 0)
NO_PROGRESS_TIMEOUT_SECONDS = 1.0
TOTAL_CAPTURE_TIMEOUT_SECONDS = 5.0
MAX_DISABLE_LATENCY_US = 500.0
READ_RANGES = ((0x0000, 0x0030), (0x006C, 0x0074),
               (0x0080, 0x00B4), (0x3800, 0x3858))
COUNTER_OFFSETS = {
    "attempted": 0x3814,
    "committed": 0x3818,
    "streamed": 0x381C,
    "dropped": 0x3820,
    "overflow": 0x3824,
    "discontinuity": 0x3828,
    "beats_low": 0x382C,
    "beats_high": 0x3830,
    "last_global": 0x3834,
    "abandoned": 0x3850,
    "reset_events": 0x3854,
    "last_attempt": 0x3858,
}


class GateError(RuntimeError):
    pass


def require(condition: bool, blocker: str) -> None:
    if not condition:
        raise GateError(blocker)


def validate_disable_latency(latency_us: float) -> None:
    require(0.0 <= latency_us <= MAX_DISABLE_LATENCY_US,
            "NVP_DIAG1_PRIMARY_COMPLETE_TO_DISABLE_GT_500_US")


def write_json(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fields: list[str], rows: list[dict[str, Any]]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fields})
        handle.flush()
        os.fsync(handle.fileno())


def delta32(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFF


def delta64(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFFFFFFFFFF


class Mmio:
    def __init__(self, node: str) -> None:
        flags = os.O_RDWR | os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        self.fd = os.open(node, flags)
        self.raw_rows: list[dict[str, Any]] = []
        self.ledger: list[dict[str, Any]] = []
        self.last_error_read: int | None = None

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def read(self, offset: int, label: str) -> int:
        require(offset % 4 == 0 and any(lo <= offset <= hi for lo, hi in READ_RANGES),
                "R3R4R6R2R4_MMIO_READ_ALLOWLIST_VIOLATION")
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, "R3R4R6R2R4_SHORT_MMIO_READ")
        value = struct.unpack("<I", raw)[0]
        if offset == 0x383C:
            self.last_error_read = value
        self.raw_rows.append({
            "Timestamp": time.time_ns(), "Label": label, "Operation": "READ",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Result": "PASS",
        })
        return value

    def write(self, offset: int, value: int, purpose: str,
              precondition: str) -> int:
        intents = [row for row in self.ledger if row["Result"] == "INTENT"]
        count = lambda name: sum(row["Purpose"] == name for row in intents)
        if (offset, value, purpose) == (0x380C, 4, "RESET_STREAM_STATE"):
            require(count(purpose) == 0, "R3R4R6R2R4_RESET_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 4, "POST_TARGET_TAIL_FLUSH"):
            require(count(purpose) == 0 and count("NORMAL_DISABLE") == 1,
                    "BT656_FIX1_POST_TARGET_TAIL_FLUSH_PRECONDITION_FAILED")
        elif (offset, value, purpose) == (0x380C, 1, "STREAM_ENABLE"):
            require(count(purpose) == 0, "R3R4R6R2R4_ENABLE_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "NORMAL_DISABLE"):
            require(count(purpose) == 0, "R3R4R6R2R4_NORMAL_DISABLE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "SAFETY_DISABLE"):
            require(count("STREAM_ENABLE") == 1 and count(purpose) == 0,
                    "R3R4R6R2R4_SAFETY_DISABLE_PRECONDITION_FAILED")
        elif (offset, value, purpose) == (0x3844, 1, "COHERENT_SNAPSHOT"):
            require(count(purpose) < 4, "R3R4R6R2R4_SNAPSHOT_BUDGET_EXCEEDED")
        elif offset == 0x383C and purpose == "SESSION_NORMALIZATION_W1C":
            require(count(purpose) == 0 and self.last_error_read is not None,
                    "R3R4R6R2R4_W1C_READ_OR_BUDGET_PRECONDITION_FAILED")
            require(value != 0 and value == (self.last_error_read & 0x3F),
                    "R3R4R6R2R4_W1C_MASK_NOT_FROM_IMMEDIATE_READ")
            require(precondition == "POST_RESET_QUIESCENT",
                    "R3R4R6R2R4_W1C_QUIESCENCE_PRECONDITION_FAILED")
        else:
            raise GateError("R3R4R6R2R4_MMIO_WRITE_ALLOWLIST_VIOLATION")
        started = time.time_ns()
        base = {
            "Timestamp": started, "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Precondition": precondition, "Authorized": "YES",
        }
        self.ledger.append({**base, "Result": "INTENT"})
        written = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(written == 4, "R3R4R6R2R4_SHORT_MMIO_WRITE")
        completed_ns = time.monotonic_ns()
        self.ledger.append({**base, "Result": "PASS",
                            "CompletionMonotonicNs": completed_ns})
        self.raw_rows.append({
            "Timestamp": started, "Label": purpose, "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Result": "PASS",
        })
        return completed_ns

    def counters(self, label: str) -> dict[str, int]:
        values = {name: self.read(offset, label)
                  for name, offset in COUNTER_OFFSETS.items()}
        values["beats"] = values["beats_low"] | (values["beats_high"] << 32)
        return values

    def checkpoint(self, name: str) -> dict[str, Any]:
        counters = self.counters(name)
        return {
            "Checkpoint": name,
            "Epoch": self.read(0x3838, name),
            "Control": self.read(0x380C, name),
            "Status": self.read(0x3810, name),
            "ErrorStatus": self.read(0x383C, name),
            "LastErrorCause": self.read(0x3840, name),
            "Attempted": counters["attempted"],
            "Committed": counters["committed"],
            "Streamed": counters["streamed"],
            "Dropped": counters["dropped"],
            "Overflow": counters["overflow"],
            "Discontinuity": counters["discontinuity"],
            "Abandoned": counters["abandoned"],
            "BeatsStreamed": counters["beats"],
            "LastGlobalSequence": counters["last_global"],
            "LastAttemptSequence": counters["last_attempt"],
            "Timestamp": time.time_ns(),
        }

    def snapshot(self, label: str) -> dict[str, Any]:
        epoch = self.read(0x3838, label)
        generation = self.read(0x384C, label)
        require((self.read(0x3810, label) & 0x300) == 0,
                "R3R4R6R2R4_SNAPSHOT_OR_RESET_BUSY")
        self.write(0x3844, 1, "COHERENT_SNAPSHOT", label)
        expected_generation = (generation + 1) & 0xFFFFFFFF
        deadline = time.monotonic() + 2.0
        while True:
            status = self.read(0x3848, label) & 3
            observed_generation = self.read(0x384C, label)
            if status == 2 and observed_generation == expected_generation:
                break
            require(time.monotonic() < deadline,
                    "R3R4R6R2R4_COHERENT_SNAPSHOT_TIMEOUT")
            time.sleep(0.001)
        counters = self.counters(label)
        require(self.read(0x3838, label) == epoch,
                "R3R4R6R2R4_SNAPSHOT_EPOCH_CHANGED")
        return {"label": label, "epoch": epoch,
                "generation": expected_generation, **counters}

    def live_checkpoint(self, label: str) -> dict[str, Any]:
        """Read a non-coherent pre-reset checkpoint without issuing a write."""
        counters = self.counters(label)
        return {
            "Checkpoint": label,
            "Epoch": self.read(0x3838, label),
            "Control": self.read(0x380C, label),
            "Status": self.read(0x3810, label),
            "ErrorStatus": self.read(0x383C, label),
            "LastErrorCause": self.read(0x3840, label),
            "Attempted": counters["attempted"],
            "Committed": counters["committed"],
            "Streamed": counters["streamed"],
            "Dropped": counters["dropped"],
            "Overflow": counters["overflow"],
            "Discontinuity": counters["discontinuity"],
            "Abandoned": counters["abandoned"],
            "BeatsStreamed": counters["beats"],
            "LastGlobalSequence": counters["last_global"],
            "LastAttemptSequence": counters["last_attempt"],
            "Timestamp": time.time_ns(),
        }


def hardware_quiescent(control: int, status: int) -> bool:
    return control == 0 and (status & 0x10F) == 0x004


def prove_quiescence(mmio: Mmio, label: str,
                     timeout_seconds: float = 10.0) -> tuple[bool, list[dict]]:
    deadline = time.monotonic() + timeout_seconds
    rows: list[dict[str, Any]] = []
    consecutive = 0
    first: float | None = None
    while time.monotonic() < deadline:
        sample_start = time.monotonic()
        control = mmio.read(0x380C, label)
        status = mmio.read(0x3810, label)
        accepted = hardware_quiescent(control, status)
        now = time.monotonic()
        if accepted:
            if consecutive == 0:
                first = now
            consecutive += 1
        else:
            consecutive = 0
            first = None
        span = 0.0 if first is None else now - first
        rows.append({
            "Timestamp": time.time_ns(), "Label": label,
            "Sample": len(rows) + 1, "Control": f"0x{control:08X}",
            "Status": f"0x{status:08X}", "Accepted": accepted,
            "Consecutive": consecutive, "SpanMs": round(span * 1000, 3),
        })
        if consecutive >= 5 and span >= 0.400:
            return True, rows
        remaining = 0.100 - (time.monotonic() - sample_start)
        if remaining > 0:
            time.sleep(remaining)
    return False, rows


SOURCE_REGISTER_OFFSETS = tuple(range(0x80, 0xB8, 4))


def read_source_observability(mmio: Mmio, label: str) -> dict[str, Any]:
    """Read the complete source block currently exposed by the R3 image."""
    nvp_values = {offset: mmio.read(offset, label)
                  for offset in SOURCE_REGISTER_OFFSETS}
    return {
        "timestamp_ns": time.time_ns(),
        "monotonic_ns": time.monotonic_ns(),
        "vclk_count": nvp_values[0x80],
        "sav_count": nvp_values[0x84],
        "record_commit_count": nvp_values[0x88],
        "nvp_init_status": nvp_values[0x8C],
        "nvp_nack_count": nvp_values[0x90],
        "nvp_init_error": nvp_values[0x94],
        "nvp_detail_status": nvp_values[0x9C],
        "source_malformed_count": mmio.read(0x70, label),
        "source_dropped_count": mmio.read(0x74, label),
        "g2b_control": mmio.read(0x380C, label),
        "g2b_status": mmio.read(0x3810, label),
        "transport_error_status": mmio.read(0x383C, label),
        "transport_last_error_cause": mmio.read(0x3840, label),
        "raw_registers": {f"0x{key:04X}": value
                          for key, value in nvp_values.items()},
        "raw_vdo_toggle_count": "NOT_EXPOSED_CURRENT_PROFILE",
        "raw_ff_count": "NOT_EXPOSED_CURRENT_PROFILE",
        "ff0000xy_candidate_count": "NOT_EXPOSED_CURRENT_PROFILE",
        "legal_sav_count": nvp_values[0x84],
        "legal_eav_count": "NOT_EXPOSED_CURRENT_PROFILE",
        "illegal_marker_count": "NOT_EXPOSED_CURRENT_PROFILE",
        "parser_state": "NOT_EXPOSED_CURRENT_PROFILE",
        "parser_lock": "NOT_EXPOSED_CURRENT_PROFILE",
    }


def observe_source_availability(mmio: Mmio, label: str,
                                duration_seconds: float) -> dict[str, Any]:
    """Measure one bounded, read-only VDO1/BT.656 source window."""
    require(duration_seconds > 0, "R3R1_SOURCE_WINDOW_DURATION_INVALID")
    before = read_source_observability(mmio, label + "_BEFORE")
    started = time.monotonic()
    time.sleep(duration_seconds)
    after = read_source_observability(mmio, label + "_AFTER")
    elapsed = time.monotonic() - started
    require(elapsed > 0, "R3R1_SOURCE_WINDOW_CLOCK_INVALID")
    vclk_delta = delta32(after["vclk_count"], before["vclk_count"])
    sav_delta = delta32(after["sav_count"], before["sav_count"])
    ratio = (vclk_delta / sav_delta) if sav_delta else None
    g2b_status = int(after["g2b_status"])
    error_status = int(after["transport_error_status"])
    nvp_init_status = int(after["nvp_init_status"])
    result = {
        "label": label,
        "requested_duration_ms": round(duration_seconds * 1000.0, 3),
        "elapsed_ms": round(elapsed * 1000.0, 3),
        "before": before, "after": after,
        "vclk_delta": vclk_delta,
        "vclk_rate": vclk_delta / elapsed,
        "sav_delta": sav_delta,
        "sav_rate": sav_delta / elapsed,
        "vclk_per_sav": ratio,
        "source_ready": bool(g2b_status & 0x40),
        "source_locked": bool(g2b_status & 0x80),
        "source_fatal": bool(g2b_status & 0x800),
        "transport_fatal": bool(error_status & 0x38),
        "nvp_fatal": bool(
            (nvp_init_status & 0x3F) != 0x39 or
            int(after["nvp_nack_count"]) != 0 or
            int(after["nvp_init_error"]) != 0 or
            (int(after["nvp_detail_status"]) & 0x80000000)
        ),
        "mmio_counter_consistent": True,
        "source_malformed_delta": delta32(
            int(after["source_malformed_count"]),
            int(before["source_malformed_count"])),
        "source_dropped_delta": delta32(
            int(after["source_dropped_count"]),
            int(before["source_dropped_count"])),
    }
    result["qualified"] = availability_window_qualified(result)
    return result


def runtime_identity(mmio: Mmio, expected_git_sha: str,
                     expected_build_flags: int) -> dict[str, Any]:
    values = {offset: mmio.read(offset, "RUNTIME_IDENTITY")
              for offset in range(0x0000, 0x0034, 4)}
    observed_sha = "".join(f"{values[offset]:08x}"
                           for offset in range(0x0010, 0x0024, 4))
    require(values[0x0000] == 0xA40A0C07,
            "BT656_FIX1_RUNTIME_BLOCK_ID_MISMATCH")
    require(values[0x0004] == 0x0000400B,
            "BT656_FIX1_RUNTIME_PROTOCOL_MISMATCH")
    require(values[0x0008] == 0x00031002,
            "BT656_FIX1_RUNTIME_CAPABILITIES_MISMATCH")
    require(values[0x000C] == 0x00010000,
            "BT656_FIX1_RUNTIME_BUILD_SCHEMA_MISMATCH")
    require(observed_sha == expected_git_sha.lower(),
            "BT656_FIX1_RUNTIME_GIT_SHA_MISMATCH")
    require(values[0x0024] == 0x07E90002,
            "BT656_FIX1_RUNTIME_VIVADO_VERSION_MISMATCH")
    require(values[0x002C] == expected_build_flags,
            "BT656_FIX1_RUNTIME_BUILD_FLAGS_MISMATCH")
    require(values[0x0030] == 0x58444D41,
            "BT656_FIX1_RUNTIME_TRANSPORT_SIGNATURE_MISMATCH")
    return {
        "result": "PASS",
        "git_sha": observed_sha,
        "build_flags": f"0x{values[0x002C]:08X}",
        "block_id": f"0x{values[0x0000]:08X}",
        "protocol": f"0x{values[0x0004]:08X}",
        "capabilities": f"0x{values[0x0008]:08X}",
        "transport_signature": f"0x{values[0x0030]:08X}",
    }


class MetadataEventReader:
    """Unbuffered line reader so burst progress events cannot hide in TextIO."""

    def __init__(self, process: subprocess.Popen[bytes]) -> None:
        require(process.stdout is not None, "R3R4R6R2R4_NATIVE_STDOUT_PIPE_MISSING")
        self.process = process
        self.fd = process.stdout.fileno()
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.fd, selectors.EVENT_READ)
        self.buffer = bytearray()

    def close(self) -> None:
        self.selector.close()

    def read(self, deadline: float) -> dict[str, Any]:
        while time.monotonic() < deadline:
            newline = self.buffer.find(b"\n")
            if newline >= 0:
                raw = bytes(self.buffer[:newline])
                del self.buffer[:newline + 1]
                require(bool(raw), "R3R4R6R2R4_NATIVE_EMPTY_EVENT")
                try:
                    event = json.loads(raw.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                    raise GateError("R3R4R6R2R4_NATIVE_EVENT_SCHEMA_INVALID") from exc
                require(isinstance(event, dict) and isinstance(event.get("type"), str),
                        "R3R4R6R2R4_NATIVE_EVENT_SCHEMA_INVALID")
                require(all(isinstance(value, (str, int, float, bool, type(None)))
                            for value in event.values()),
                        "R3R4R6R2R4_NATIVE_EVENT_NOT_METADATA_ONLY")
                return event
            ready = self.selector.select(
                timeout=min(0.05, max(0.0, deadline - time.monotonic())))
            if ready:
                chunk = os.read(self.fd, 65536)
                if chunk:
                    self.buffer.extend(chunk)
                    continue
                if self.process.poll() is not None:
                    raise GateError("R3R4R6R2R4_NATIVE_STDOUT_CLOSED")
            if self.process.poll() is not None and not self.buffer:
                raise GateError("R3R4R6R2R4_NATIVE_EXITED_BEFORE_REQUIRED_EVENT")
        raise GateError("R3R4R6R2R4_NATIVE_EVENT_TIMEOUT")


def record_event(event: dict[str, Any], events: list[dict[str, Any]]) -> None:
    """Buffer metadata only; active-capture events are never written here."""
    events.append(event)


def persist_buffered_events(path: Path, events: list[dict[str, Any]]) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as event_log:
        for event in events:
            event_log.write(json.dumps(
                event, sort_keys=True, separators=(",", ":")) + "\n")
        event_log.flush()
        os.fsync(event_log.fileno())


def fast_normal_disable(mmio: Mmio) -> int:
    """Critical path: direct already-open-fd MMIO write, then timestamp only."""
    written = os.pwrite(mmio.fd, DISABLE_WORD, 0x380C)
    completion_ns = time.monotonic_ns()
    require(written == 4, "R3R4R6R2R4_FAST_NORMAL_DISABLE_SHORT_WRITE")
    return completion_ns


def wait_event(reader: MetadataEventReader, expected: str, deadline: float,
               events: list[dict[str, Any]]) -> dict[str, Any]:
    while True:
        event = reader.read(deadline)
        record_event(event, events)
        if event["type"] == "ERROR":
            raise GateError(str(event.get("blocker") or
                                "R3R4R6R2R4_NATIVE_UNSPECIFIED_ERROR"))
        if event["type"] == expected:
            return event


def wait_primary_window(reader: MetadataEventReader,
                        events: list[dict[str, Any]]) -> dict[str, Any]:
    started = time.monotonic()
    total_deadline = started + TOTAL_CAPTURE_TIMEOUT_SECONDS
    progress_deadline = started + NO_PROGRESS_TIMEOUT_SECONDS
    while True:
        deadline = min(total_deadline, progress_deadline)
        try:
            event = reader.read(deadline)
        except GateError as exc:
            now = time.monotonic()
            if now >= total_deadline:
                raise GateError("R3R4R6R2R4_TOTAL_CAPTURE_TIMEOUT") from exc
            if now >= progress_deadline:
                raise GateError("R3R4R6R2R4_NO_PROGRESS_TIMEOUT") from exc
            raise
        if event["type"] == "PRIMARY_WINDOW_COMPLETE":
            return event
        record_event(event, events)
        if event["type"] == "ERROR":
            raise GateError(str(event.get("blocker") or
                                "R3R4R6R2R4_NATIVE_UNSPECIFIED_ERROR"))
        if event["type"] == "ROLLING_PROGRESS":
            progress_deadline = time.monotonic() + NO_PROGRESS_TIMEOUT_SECONDS


def run(args: argparse.Namespace) -> dict[str, Any]:
    result: dict[str, Any] = {
        "schema": "BT656_FIX1_CONTROLLER_RESULT_V1", "task": TASK,
        "result": "FAIL", "blocker": None, "events": [],
        "record_bytes": RECORD_BYTES, "primary_records": PRIMARY_RECORDS,
        "primary_requested_bytes": PRIMARY_BYTES, "guard_records": GUARD_RECORDS,
        "guard_requested_bytes": GUARD_BYTES,
        "total_logical_requests": TOTAL_LOGICAL_REQUESTS,
        "max_outstanding_iocbs": MAX_OUTSTANDING_IOCBS,
        "parent_owned_mmio": True, "raw_payload_control_ipc": False,
        "unauthorized_mmio_writes": 0, "native_helper_pid": None,
    }
    mmio: Mmio | None = None
    process: subprocess.Popen[bytes] | None = None
    reader: MetadataEventReader | None = None
    stream_enabled = False
    parent_quiescent = False
    parent_signal_sent = False
    timeline: list[dict[str, Any]] = []
    quiescence_rows: list[dict[str, Any]] = []
    normal_disabled = False
    logs = Path(args.logs_dir)

    def snapshot_row(name: str, snapshot: dict[str, Any], error: int,
                     cause: int, control: int, status: int) -> dict[str, Any]:
        return {
            "Checkpoint": name, "Epoch": snapshot["epoch"],
            "Control": control, "Status": status,
            "ErrorStatus": error, "LastErrorCause": cause,
            "Attempted": snapshot["attempted"], "Committed": snapshot["committed"],
            "Streamed": snapshot["streamed"], "Dropped": snapshot["dropped"],
            "Overflow": snapshot["overflow"],
            "Discontinuity": snapshot["discontinuity"],
            "Abandoned": snapshot["abandoned"],
            "BeatsStreamed": snapshot["beats"],
            "LastGlobalSequence": snapshot["last_global"],
            "LastAttemptSequence": snapshot["last_attempt"],
            "Timestamp": time.time_ns(),
        }

    try:
        lock_receipt = Path(args.linux_lock) / "receipt.json"
        require(lock_receipt.is_file(), "R3R4R6R2R4_LINUX_TASK_LOCK_NOT_HELD")
        lock = json.loads(lock_receipt.read_text(encoding="utf-8"))
        require(lock.get("task") == TASK and lock.get("state") == "HELD",
                "R3R4R6R2R4_LINUX_TASK_LOCK_RECEIPT_INVALID")
        require(Path(args.user_node).is_char_device(),
                "R3R4R6R2R4_DRIVER_OR_NODE_OPERATION_FAILED:USER_NODE")
        require(Path(args.c2h_node).is_char_device(),
                "R3R4R6R2R4_DRIVER_OR_NODE_OPERATION_FAILED:C2H_NODE")
        Path(args.private_dir).mkdir(parents=True, exist_ok=True, mode=0o700)
        logs.mkdir(parents=True, exist_ok=True, mode=0o700)
        mmio = Mmio(args.user_node)
        result["runtime_identity"] = runtime_identity(
            mmio, args.expected_git_sha, args.expected_build_flags)
        require(mmio.read(0x3800, "SOURCE_IDENTITY") == 0x43324831,
                "R3R1_G2B_C2H_MAGIC_ABSENT")
        require(mmio.read(0x3804, "SOURCE_IDENTITY") == 0x00010000,
                "R3R1_TRANSPORT_ABI_VERSION_NOT_1")
        control = mmio.read(0x380C, "S0")
        status = mmio.read(0x3810, "S0")
        require(hardware_quiescent(control, status),
                "R3R1_S0_NOT_PHYSICALLY_QUIESCENT")
        s0 = mmio.live_checkpoint("S0_PRE_RESET_READ_ONLY")
        timeline.append(s0)
        result["S0"] = s0

        pre_reset = observe_source_availability(mmio, "PRE_RESET", 0.250)
        result["pre_reset_source_observation"] = pre_reset

        if pre_reset["vclk_delta"] == 0:
            availability = classify_availability(
                pre_reset, None, reset_attempted=False,
                reset_acknowledged=False)
            result["source_availability"] = availability
            result["reset_stream_state"] = "NOT_RUN_SOURCE_CLOCK_ABSENT"
            result["post_reset_source_observation"] = None
            parent_quiescent, quiescence_rows = prove_quiescence(
                mmio, "NO_VCLK_NO_CAPTURE")
            require(parent_quiescent,
                    "R3R1_NO_VCLK_PHYSICAL_QUIESCENCE_NOT_PROVEN")
            result["physical_quiescence"] = {
                "result": "PASS", "total_samples": len(quiescence_rows),
                "accepted_samples": quiescence_rows[-1]["Consecutive"],
                "span_ms": quiescence_rows[-1]["SpanMs"],
            }
            semantics = session_semantics(
                availability=availability["availability_classification"],
                capture_result="NOT_RUN", quiescent=True,
                helper_launched=False, aio_submitted=0,
                stream_enable_writes=0)
            result.update(semantics)
            result.update({
                "capture_eligible": False,
                "capture_result_detail": "NOT_RUN_NO_VCLK",
                "capture_bytes": 0, "capture_records": 0,
                "aio_submitted": 0, "stream_enable_writes": 0,
                "stream_disable_writes": 0,
                "native_helper_launched": False,
                "final_pending_aio": 0,
                "result": "PASS", "blocker": None,
            })
            return result

        mmio.write(0x380C, 4, "RESET_STREAM_STATE", "S0_QUIESCENT")
        reset_deadline = time.monotonic() + 5.0
        reset_completed = False
        while True:
            control = mmio.read(0x380C, "RESET_WAIT")
            status = mmio.read(0x3810, "RESET_WAIT")
            if hardware_quiescent(control, status):
                reset_completed = True
                break
            if time.monotonic() >= reset_deadline:
                result["source_availability"] = classify_availability(
                    pre_reset, None, reset_attempted=True,
                    reset_acknowledged=False)
                raise GateError("R3R1_RESET_ACK_TIMEOUT_WITH_VCLK")
            time.sleep(0.001)
        require(reset_completed, "R3R1_RESET_ACK_TIMEOUT_WITH_VCLK")
        s1 = mmio.checkpoint("S1")
        timeline.append(s1)
        result["S1"] = s1
        require(s1["Epoch"] == ((s0["Epoch"] + 1) & 0xFFFFFFFF),
                "R3R4R6R2R4_RESET_EPOCH_TRANSITION_FAILED")

        normalization = mmio.read(0x383C, "S1_W1C_READ") & 0x3F
        result["session_normalization_w1c_mask"] = normalization
        if normalization:
            mmio.write(0x383C, normalization, "SESSION_NORMALIZATION_W1C",
                       "POST_RESET_QUIESCENT")
        post_error = mmio.read(0x383C, "S2")
        require((post_error & 0x3F) == 0,
                "R3R4R6R2R4_SESSION_NORMALIZATION_DID_NOT_CLEAR")
        s2_cause = mmio.read(0x3840, "S2")
        baseline = mmio.snapshot("BASELINE_PRE_ENABLE")
        s2 = snapshot_row(
            "S2", baseline, post_error, s2_cause,
            mmio.read(0x380C, "S2"), mmio.read(0x3810, "S2"))
        timeline.append(s2)
        result["S2"] = s2
        result["baseline_snapshot"] = baseline

        post_reset_short = observe_source_availability(
            mmio, "POST_RESET_SHORT", 0.250)
        post_reset_extended = None
        if not availability_window_qualified(post_reset_short):
            post_reset_extended = observe_source_availability(
                mmio, "POST_RESET_EXTENDED", 1.500)
        selected_post = choose_post_window(
            post_reset_short, post_reset_extended)
        availability = classify_availability(
            pre_reset, selected_post, reset_attempted=True,
            reset_acknowledged=True)
        result["post_reset_short_source_observation"] = post_reset_short
        result["post_reset_extended_source_observation"] = post_reset_extended
        result["post_reset_source_observation"] = selected_post
        result["source_availability"] = availability
        result["reset_stream_state"] = "PASS"
        result["capture_eligible"] = availability["capture_eligible"]

        if availability["availability_classification"] in (
                "SOURCE_FATAL_STATUS", "MMIO_COUNTER_INCONSISTENT"):
            raise GateError(availability["availability_classification"])

        if not availability["capture_eligible"]:
            parent_quiescent, quiescence_rows = prove_quiescence(
                mmio, "NO_CAPTURE_POST_RESET")
            require(parent_quiescent,
                    "R3R1_NO_CAPTURE_PHYSICAL_QUIESCENCE_NOT_PROVEN")
            result["physical_quiescence"] = {
                "result": "PASS", "total_samples": len(quiescence_rows),
                "accepted_samples": quiescence_rows[-1]["Consecutive"],
                "span_ms": quiescence_rows[-1]["SpanMs"],
            }
            no_capture_class = no_capture_classification(
                availability["availability_classification"])
            semantics = session_semantics(
                availability=availability["availability_classification"],
                capture_result="NOT_RUN", quiescent=True,
                helper_launched=False, aio_submitted=0,
                stream_enable_writes=0)
            result.update(semantics)
            result.update({
                "capture_result_detail": no_capture_class,
                "capture_bytes": 0, "capture_records": 0,
                "aio_submitted": 0, "stream_enable_writes": 0,
                "stream_disable_writes": 0,
                "native_helper_launched": False,
                "final_pending_aio": 0,
                "result": "PASS", "blocker": None,
            })
            return result

        require(Path(args.native_helper).is_file(),
                "R3R1_NATIVE_HELPER_MISSING")

        process = subprocess.Popen(
            [args.native_helper, args.c2h_node, args.private_dir],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            bufsize=0, close_fds=True)
        result["native_helper_pid"] = process.pid
        result["native_helper_launched"] = True
        reader = MetadataEventReader(process)
        prequeue = wait_event(reader, "ROLLING_PREQUEUE_READY",
                              time.monotonic() + 15.0, result["events"])
        require(prequeue.get("initial_submitted_requests") == MAX_OUTSTANDING_IOCBS and
                prequeue.get("current_outstanding") == MAX_OUTSTANDING_IOCBS and
                prequeue.get("maximum_permitted_outstanding") == MAX_OUTSTANDING_IOCBS and
                prequeue.get("next_logical_request_index") == MAX_OUTSTANDING_IOCBS and
                prequeue.get("primary_total") == PRIMARY_RECORDS and
                prequeue.get("guard_total") == GUARD_RECORDS and
                prequeue.get("aio_context_capacity") == 1152 and
                prequeue.get("total_allocated_bytes") == PRIMARY_BYTES + GUARD_BYTES and
                prequeue.get("buffer_alignment") == RECORD_BYTES and
                prequeue.get("primary_alignment_remainder") == 0 and
                prequeue.get("guard_alignment_remainder") == 0 and
                prequeue.get("prefaulted") is True and
                prequeue.get("aio_context_active") is True,
                "R3R4R6R2R4_ROLLING_PREQUEUE_READY_CONTRACT_FAILED")
        result["rolling_prequeue_ready"] = prequeue

        enable_ns = mmio.write(0x380C, 1, "STREAM_ENABLE",
                               "ROLLING_PREQUEUE_READY")
        stream_enabled = True
        result["prequeue_ready_to_enable_latency_us"] = round(
            (enable_ns - int(prequeue["monotonic_ns"])) / 1000.0, 3)
        primary = wait_primary_window(reader, result["events"])
        require(primary.get("type") == "PRIMARY_WINDOW_COMPLETE",
                "R3R4R6R2R4_PRIMARY_EVENT_TYPE_INVALID")

        disable_ns = fast_normal_disable(mmio)
        normal_disabled = True
        stream_enabled = False
        require(process.stdin is not None,
                "R3R4R6R2R4_NATIVE_STDIN_PIPE_MISSING")
        process.stdin.write(b"DISABLE_ISSUED\n")
        process.stdin.flush()

        record_event(primary, result["events"])
        ledger_time = time.time_ns()
        fast_base = {
            "Timestamp": ledger_time, "Operation": "WRITE",
            "Offset": "0x380C", "Value": "0x00000000",
            "Purpose": "NORMAL_DISABLE", "Precondition": "PRIMARY_WINDOW_COMPLETE",
            "Authorized": "YES",
        }
        mmio.ledger.append({**fast_base, "Result": "INTENT"})
        mmio.ledger.append({**fast_base, "Result": "PASS",
                            "CompletionMonotonicNs": disable_ns})
        mmio.raw_rows.append({
            "Timestamp": ledger_time, "Label": "NORMAL_DISABLE",
            "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000000",
            "Result": "PASS",
        })
        result["disable_issued_after_mmio"] = True
        result["primary_completion"] = primary
        require(primary.get("primary_exact_completions") == PRIMARY_RECORDS and
                primary.get("primary_short_completions") == 0 and
                primary.get("primary_failed_completions") == 0 and
                primary.get("primary_duplicate_completions") == 0 and
                primary.get("primary_pending") == 0 and
                primary.get("pending_aio") == 0 and
                primary.get("primary_bytes") == PRIMARY_BYTES and
                primary.get("guard_pending") == 0 and
                isinstance(primary.get("maximum_outstanding"), int) and
                primary["maximum_outstanding"] <= MAX_OUTSTANDING_IOCBS,
                "R3R4R6R2R4_PRIMARY_WINDOW_INCOMPLETE")

        result["primary_complete_to_disable_us"] = round(
            (disable_ns - int(primary["monotonic_ns"])) / 1000.0, 3)
        validate_disable_latency(result["primary_complete_to_disable_us"])
        result["guard_pending_at_disable"] = primary.get("guard_pending")

        sp_error = mmio.read(0x383C, "SP")
        sp_cause = mmio.read(0x3840, "SP")
        sp_snapshot = mmio.snapshot("PRIMARY_WINDOW_EVIDENCE")
        sp = snapshot_row(
            "SP", sp_snapshot, sp_error, sp_cause,
            mmio.read(0x380C, "SP"), mmio.read(0x3810, "SP"))
        timeline.append(sp)
        result["SP"] = sp
        result["primary_window_snapshot"] = sp_snapshot

        post_target_tail = not hardware_quiescent(sp["Control"], sp["Status"])
        result["post_target_shutdown_tail"] = (
            "PRESENT" if post_target_tail else "NONE")
        result["post_target_tail_flush"] = "NOT_REQUIRED"
        if post_target_tail:
            before_flush_epoch = sp["Epoch"]
            mmio.write(0x380C, 4, "POST_TARGET_TAIL_FLUSH",
                       "PRIMARY_COMPLETE_AND_NORMAL_DISABLE_ISSUED")
            flush_deadline = time.monotonic() + 5.0
            while True:
                flush_control = mmio.read(0x380C, "POST_TARGET_TAIL_FLUSH_WAIT")
                flush_status = mmio.read(0x3810, "POST_TARGET_TAIL_FLUSH_WAIT")
                if hardware_quiescent(flush_control, flush_status):
                    break
                require(time.monotonic() < flush_deadline,
                        "BT656_FIX1_POST_TARGET_TAIL_FLUSH_TIMEOUT")
                time.sleep(0.001)
            after_flush_epoch = mmio.read(0x3838, "POST_TARGET_TAIL_FLUSH_EPOCH")
            require(after_flush_epoch == ((before_flush_epoch + 1) & 0xFFFFFFFF),
                    "BT656_FIX1_POST_TARGET_TAIL_FLUSH_EPOCH_FAILED")
            result["post_target_tail_flush"] = "PASS"
            result["post_target_tail_flush_epoch_before"] = before_flush_epoch
            result["post_target_tail_flush_epoch_after"] = after_flush_epoch

        parent_quiescent, quiescence_rows = prove_quiescence(mmio, "POST_DISABLE")
        require(parent_quiescent, "R3R4R6R2R4_PHYSICAL_QUIESCENCE_NOT_PROVEN")
        result["physical_quiescence"] = {
            "result": "PASS", "total_samples": len(quiescence_rows),
            "accepted_samples": quiescence_rows[-1]["Consecutive"],
            "span_ms": quiescence_rows[-1]["SpanMs"],
        }
        require(process.stdin is not None, "R3R4R6R2R4_NATIVE_STDIN_PIPE_MISSING")
        process.stdin.write(b"PARENT_QUIESCENT\n")
        process.stdin.flush()
        process.stdin.close()
        parent_signal_sent = True

        s3_error = mmio.read(0x383C, "S3")
        s3_cause = mmio.read(0x3840, "S3")
        final = mmio.snapshot("FINAL_POST_QUIESCENCE")
        s3 = snapshot_row(
            "S3", final, s3_error, s3_cause,
            mmio.read(0x380C, "S3"), mmio.read(0x3810, "S3"))
        timeline.append(s3)
        result["S3"] = s3
        result["last_error_cause_changed_during_session"] = (
            s3_cause != s2_cause)
        result["final_snapshot"] = final
        result["counter_deltas"] = {
            "attempted": delta32(final["attempted"], baseline["attempted"]),
            "committed": delta32(final["committed"], baseline["committed"]),
            "streamed": delta32(final["streamed"], baseline["streamed"]),
            "dropped": delta32(final["dropped"], baseline["dropped"]),
            "overflow": delta32(final["overflow"], baseline["overflow"]),
            "discontinuity": delta32(final["discontinuity"], baseline["discontinuity"]),
            "abandoned": delta32(final["abandoned"], baseline["abandoned"]),
            "beats": delta64(final["beats"], baseline["beats"]),
            "last_global": final["last_global"],
            "last_attempt": final["last_attempt"],
        }
        result["post_target_counter_deltas"] = {
            "attempted": delta32(final["attempted"], sp_snapshot["attempted"]),
            "committed": delta32(final["committed"], sp_snapshot["committed"]),
            "streamed": delta32(final["streamed"], sp_snapshot["streamed"]),
            "dropped": delta32(final["dropped"], sp_snapshot["dropped"]),
            "overflow": delta32(final["overflow"], sp_snapshot["overflow"]),
            "discontinuity": delta32(final["discontinuity"],
                                     sp_snapshot["discontinuity"]),
            "abandoned": delta32(final["abandoned"], sp_snapshot["abandoned"]),
            "beats": delta64(final["beats"], sp_snapshot["beats"]),
        }

        exit_event = None
        durable_event = None
        finalization_event = None
        native_deadline = time.monotonic() + 15.0
        while exit_event is None:
            event = reader.read(native_deadline)
            record_event(event, result["events"])
            if event["type"] == "ERROR":
                raise GateError(str(event.get("blocker") or
                                    "R3R4R6R2R4_NATIVE_POST_CAPTURE_ERROR"))
            if event["type"] == "PRIMARY_DURABLE":
                durable_event = event
            elif event["type"] == "FINALIZATION_COMPLETE":
                finalization_event = event
            elif event["type"] == "HELPER_EXIT_READY":
                exit_event = event
        process.wait(timeout=max(0.1, native_deadline - time.monotonic()))
        stderr_bytes = process.stderr.read() if process.stderr else b""
        stderr = stderr_bytes.decode("utf-8", errors="replace")
        result["native_helper_exit_code"] = process.returncode
        result["native_helper_stderr"] = stderr
        result["primary_durable"] = durable_event
        result["native_finalization"] = finalization_event
        require(process.returncode == 0 and not stderr.strip() and
                durable_event is not None and finalization_event is not None and
                exit_event.get("result") == "PASS",
                "R3R4R6R2R4_NATIVE_HELPER_FINALIZATION_FAILED")
        require(durable_event.get("file_bytes") == PRIMARY_BYTES and
                durable_event.get("primary_exact_completions") == PRIMARY_RECORDS and
                isinstance(durable_event.get("sha256"), str) and
                len(durable_event["sha256"]) == 64,
                "R3R4R6R2R4_PRIMARY_DURABILITY_CONTRACT_FAILED")
        require(finalization_event.get("guard_exact_completions", 0) == 0 and
                finalization_event.get("guard_canceled", 0) == 0 and
                finalization_event.get("guard_short_completions") == 0 and
                finalization_event.get("guard_failed_completions") == 0 and
                finalization_event.get("final_pending") == 0 and
                finalization_event.get("io_cancel_calls") == 0 and
                finalization_event.get("total_submitted") == PRIMARY_RECORDS and
                finalization_event.get("total_completed") == PRIMARY_RECORDS and
                finalization_event.get("maximum_outstanding", MAX_OUTSTANDING_IOCBS + 1)
                <= MAX_OUTSTANDING_IOCBS and
                finalization_event.get("descriptor_window_violations") == 0 and
                finalization_event.get("descriptor_starvation_events") == 0 and
                finalization_event.get("crossed_logical_index_2048") is True,
                "R3R4R6R2R4_GUARD_OR_DESCRIPTOR_FINAL_CONTRACT_FAILED")

        helper_result_path = Path(args.private_dir) / "helper-result.json"
        require(helper_result_path.is_file(),
                "R3R4R6R2R4_HELPER_RESULT_MISSING")
        helper_result = json.loads(helper_result_path.read_text(encoding="utf-8"))
        result["rolling_metrics"] = helper_result
        require(helper_result.get("result") == "PASS" and
                helper_result.get("submitted") == TOTAL_LOGICAL_REQUESTS and
                helper_result.get("completed") == TOTAL_LOGICAL_REQUESTS and
                helper_result.get("pending") == 0 and
                helper_result.get("primary_exact") == PRIMARY_RECORDS and
                helper_result.get("primary_short") == 0 and
                helper_result.get("primary_failed") == 0 and
                helper_result.get("guard_records") == 0 and
                helper_result.get("guard_exact", 0) == 0 and
                helper_result.get("guard_canceled", 0) == 0 and
                helper_result.get("guard_short") == 0 and
                helper_result.get("guard_failed") == 0 and
                helper_result.get("io_cancel_calls") == 0 and
                helper_result.get("max_outstanding", MAX_OUTSTANDING_IOCBS + 1)
                <= MAX_OUTSTANDING_IOCBS and
                helper_result.get("descriptor_window_violations") == 0 and
                helper_result.get("descriptor_starvation_events") == 0 and
                helper_result.get("crossed_logical_index_2048") is True,
                "R3R4R6R2R4_ROLLING_METRICS_FINAL_CONTRACT_FAILED")

        primary_path = Path(args.private_dir) / "primary.bin"
        require(primary_path.is_file() and primary_path.stat().st_size == PRIMARY_BYTES,
                "R3R4R6R2R4_PRIMARY_FILE_SIZE_INVALID")
        result["primary_file"] = str(primary_path)
        result["primary_file_bytes"] = primary_path.stat().st_size
        result["primary_file_sha256"] = durable_event["sha256"]
        result["primary_completion_progress_last_reported"] = max(
            (int(event.get("primary_completed", 0)) for event in result["events"]
             if event.get("type") == "ROLLING_PROGRESS"), default=0)
        result.update(session_semantics(
            availability=availability["availability_classification"],
            capture_result="PASS", quiescent=True,
            helper_launched=True, aio_submitted=PRIMARY_RECORDS,
            stream_enable_writes=1))
        result["capture_result_detail"] = "PASS"
        result["capture_bytes"] = PRIMARY_BYTES
        result["capture_records"] = PRIMARY_RECORDS
        result["aio_submitted"] = PRIMARY_RECORDS
        result["stream_enable_writes"] = 1
        result["stream_disable_writes"] = 1
        result["final_pending_aio"] = 0
        result["result"] = "PASS"
        result["blocker"] = None
        return result
    except BaseException as exc:
        result["result"] = "FAIL"
        result["blocker"] = str(exc).strip() or type(exc).__name__
        result["exception_type"] = type(exc).__name__
        result["traceback"] = traceback.format_exc()
        if mmio is not None:
            try:
                if stream_enabled:
                    mmio.write(0x380C, 0, "SAFETY_DISABLE",
                               "POST_ENABLE_EXCEPTION_STREAM_ACTIVE")
                    stream_enabled = False
                if not parent_quiescent:
                    parent_quiescent, rows = prove_quiescence(mmio, "FAILURE_PATH")
                    quiescence_rows.extend(rows)
                result["failure_path_quiescence"] = (
                    "PASS" if parent_quiescent else "FAIL")
            except BaseException as cleanup_error:
                result["failure_path_quiescence"] = "FAIL"
                result["failure_path_quiescence_detail"] = str(cleanup_error)
        if (process is not None and process.poll() is None and parent_quiescent and
                not parent_signal_sent and process.stdin is not None and
                not process.stdin.closed):
            try:
                process.stdin.write(b"PARENT_QUIESCENT\n")
                process.stdin.flush()
                process.stdin.close()
                parent_signal_sent = True
            except BaseException as signal_error:
                result["native_parent_quiescent_signal"] = str(signal_error)
        if process is not None and process.poll() is None and parent_signal_sent:
            try:
                process.wait(timeout=15.0)
            except subprocess.TimeoutExpired:
                result["aio_cleanup_unresolved"] = True
        if process is not None:
            result["native_helper_exit_code"] = process.poll()
            if process.poll() is not None and process.stderr is not None:
                result["native_helper_stderr"] = process.stderr.read().decode(
                    "utf-8", errors="replace")
        return result
    finally:
        result["native_helper_absent"] = (
            process is None or process.poll() is not None)
        result["native_helper_state"] = (
            "ABSENT" if result["native_helper_absent"] else
            "PRESENT_PRESERVED_FOR_PENDING_AIO")
        event_path = logs / "rolling-progress.jsonl"
        if result["events"] and not event_path.exists():
            persist_buffered_events(event_path, result["events"])
        if reader is not None:
            reader.close()
        if mmio is not None:
            intents = [row for row in mmio.ledger if row["Result"] == "INTENT"]
            result["mmio_write_counts"] = {
                purpose: sum(row["Purpose"] == purpose for row in intents)
                for purpose in ("RESET_STREAM_STATE", "SESSION_NORMALIZATION_W1C",
                                "COHERENT_SNAPSHOT", "STREAM_ENABLE",
                                "NORMAL_DISABLE", "POST_TARGET_TAIL_FLUSH",
                                "SAFETY_DISABLE")
            }
            result["normal_disable_completed"] = normal_disabled
            result["parent_quiescent_completed"] = parent_quiescent
            mmio.close()
            if not (logs / "mmio-write-ledger.csv").exists():
                write_csv(logs / "mmio-write-ledger.csv",
                          ["Timestamp", "Operation", "Offset", "Value", "Purpose",
                           "Precondition", "Authorized", "Result",
                           "CompletionMonotonicNs"], mmio.ledger)
            if not (logs / "mmio-raw.csv").exists():
                write_csv(logs / "mmio-raw.csv",
                          ["Timestamp", "Label", "Operation", "Offset", "Value",
                           "Result"], mmio.raw_rows)
        if timeline and not (logs / "error-timeline.csv").exists():
            write_csv(logs / "error-timeline.csv",
                      ["Checkpoint", "Epoch", "Control", "Status", "ErrorStatus",
                       "LastErrorCause", "Attempted", "Committed", "Streamed",
                       "Dropped", "Overflow", "Discontinuity", "Abandoned",
                       "BeatsStreamed", "LastGlobalSequence", "LastAttemptSequence",
                       "Timestamp"], timeline)
        if quiescence_rows and not (logs / "quiescence-samples.csv").exists():
            write_csv(logs / "quiescence-samples.csv",
                      ["Timestamp", "Label", "Sample", "Control", "Status",
                       "Accepted", "Consecutive", "SpanMs"], quiescence_rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", required=True)
    parser.add_argument("--c2h-node", required=True)
    parser.add_argument("--native-helper", required=True)
    parser.add_argument("--private-dir", required=True)
    parser.add_argument("--logs-dir", required=True)
    parser.add_argument("--linux-lock", required=True)
    parser.add_argument("--expected-git-sha", required=True)
    parser.add_argument("--expected-build-flags", required=True,
                        type=lambda value: int(value, 0))
    args = parser.parse_args()
    result = run(args)
    output = Path(args.logs_dir) / "controller-result.json"
    if not output.exists():
        write_json(output, result)
    print(json.dumps({
        "task": TASK, "result": result["result"],
        "blocker": result.get("blocker"),
        "availability_classification": result.get(
            "source_availability", {}).get("availability_classification"),
        "capture_eligible": result.get("capture_eligible"),
        "capture_result": result.get("capture_result"),
        "primary_exact_completions": result.get("primary_completion", {}).get(
            "primary_exact_completions"),
        "primary_bytes": result.get("primary_completion", {}).get("primary_bytes"),
        "prequeue_ready_to_enable_latency_us": result.get(
            "prequeue_ready_to_enable_latency_us"),
        "primary_complete_to_disable_us": result.get(
            "primary_complete_to_disable_us"),
    }, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
