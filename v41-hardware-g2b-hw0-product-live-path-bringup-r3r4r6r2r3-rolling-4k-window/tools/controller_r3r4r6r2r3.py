#!/usr/bin/env python3
"""Parent-owned MMIO controller for the one-shot R3R4R6R2R3 4-KiB capture."""

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


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R3"
PRIMARY_RECORDS = 2500
RECORD_BYTES = 4096
PRIMARY_BYTES = PRIMARY_RECORDS * RECORD_BYTES
GUARD_RECORDS = 32
GUARD_BYTES = GUARD_RECORDS * RECORD_BYTES
TOTAL_LOGICAL_REQUESTS = PRIMARY_RECORDS + GUARD_RECORDS
MAX_OUTSTANDING_IOCBS = 1024
NO_PROGRESS_TIMEOUT_SECONDS = 1.0
TOTAL_CAPTURE_TIMEOUT_SECONDS = 5.0
READ_RANGES = ((0x0000, 0x0030), (0x0080, 0x00B4), (0x3800, 0x3858))
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
                "R3R4R6R2R3_MMIO_READ_ALLOWLIST_VIOLATION")
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, "R3R4R6R2R3_SHORT_MMIO_READ")
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
            require(count(purpose) == 0, "R3R4R6R2R3_RESET_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 1, "STREAM_ENABLE"):
            require(count(purpose) == 0, "R3R4R6R2R3_ENABLE_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "NORMAL_DISABLE"):
            require(count(purpose) == 0, "R3R4R6R2R3_NORMAL_DISABLE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "SAFETY_DISABLE"):
            require(count("STREAM_ENABLE") == 1 and count(purpose) == 0,
                    "R3R4R6R2R3_SAFETY_DISABLE_PRECONDITION_FAILED")
        elif (offset, value, purpose) == (0x3844, 1, "COHERENT_SNAPSHOT"):
            require(count(purpose) < 4, "R3R4R6R2R3_SNAPSHOT_BUDGET_EXCEEDED")
        elif offset == 0x383C and purpose == "SESSION_NORMALIZATION_W1C":
            require(count(purpose) == 0 and self.last_error_read is not None,
                    "R3R4R6R2R3_W1C_READ_OR_BUDGET_PRECONDITION_FAILED")
            require(value != 0 and value == (self.last_error_read & 0x3F),
                    "R3R4R6R2R3_W1C_MASK_NOT_FROM_IMMEDIATE_READ")
            require(precondition == "POST_RESET_QUIESCENT",
                    "R3R4R6R2R3_W1C_QUIESCENCE_PRECONDITION_FAILED")
        else:
            raise GateError("R3R4R6R2R3_MMIO_WRITE_ALLOWLIST_VIOLATION")
        started = time.time_ns()
        base = {
            "Timestamp": started, "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Precondition": precondition, "Authorized": "YES",
        }
        self.ledger.append({**base, "Result": "INTENT"})
        written = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(written == 4, "R3R4R6R2R3_SHORT_MMIO_WRITE")
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
                "R3R4R6R2R3_SNAPSHOT_OR_RESET_BUSY")
        self.write(0x3844, 1, "COHERENT_SNAPSHOT", label)
        expected_generation = (generation + 1) & 0xFFFFFFFF
        deadline = time.monotonic() + 2.0
        while True:
            status = self.read(0x3848, label) & 3
            observed_generation = self.read(0x384C, label)
            if status == 2 and observed_generation == expected_generation:
                break
            require(time.monotonic() < deadline,
                    "R3R4R6R2R3_COHERENT_SNAPSHOT_TIMEOUT")
            time.sleep(0.001)
        counters = self.counters(label)
        require(self.read(0x3838, label) == epoch,
                "R3R4R6R2R3_SNAPSHOT_EPOCH_CHANGED")
        return {"label": label, "epoch": epoch,
                "generation": expected_generation, **counters}


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


def source_readiness(mmio: Mmio) -> dict[str, Any]:
    require(mmio.read(0x3800, "READINESS") == 0x43324831,
            "R3R4R6R2R3_G2B_C2H_MAGIC_ABSENT")
    require(mmio.read(0x3804, "READINESS") == 0x00010000,
            "R3R4R6R2R3_TRANSPORT_ABI_VERSION_NOT_1")
    before = {offset: mmio.read(offset, "READINESS_BEFORE")
              for offset in range(0x80, 0xB8, 4)}
    deadline = time.monotonic() + 30.0
    last: dict[str, Any] = {}
    while time.monotonic() < deadline:
        interval_start = time.monotonic()
        time.sleep(3.0)
        after = {offset: mmio.read(offset, "READINESS_AFTER")
                 for offset in range(0x80, 0xB8, 4)}
        elapsed = time.monotonic() - interval_start
        vclk = (after[0x80] - before[0x80]) & 0xFFFFFFFF
        sav = (after[0x84] - before[0x84]) & 0xFFFFFFFF
        ratio = vclk / max(1, sav)
        sav_per_second = sav / elapsed
        g2b_status = mmio.read(0x3810, "READINESS_STATUS")
        last = {
            "nvp_values": {f"0x{key:04X}": value for key, value in after.items()},
            "vclk_delta": vclk, "sav_delta": sav,
            "vclk_per_sav": ratio, "sav_per_second": sav_per_second,
            "g2b_status": g2b_status,
        }
        ready = (
            (after[0x8C] & 0x3F) == 0x39 and
            after[0x90] == 0 and after[0x94] == 0 and
            not (after[0x9C] & 0x80000000) and
            5200 <= ratio <= 5360 and 20000 <= sav_per_second <= 35000 and
            (g2b_status & 0xC0) == 0xC0 and not (g2b_status & 0x800)
        )
        if ready:
            return {
                "result": "PASS", "nack_count": after[0x90],
                "init_error": after[0x94], "physical_input": 0,
                "source_ready": True, "source_locked": True, **last,
            }
        before = after
    raise GateError("R3R4R6R2R3_LIVE_SOURCE_NOT_READY:" +
                    json.dumps(last, sort_keys=True))


class MetadataEventReader:
    """Unbuffered line reader so burst progress events cannot hide in TextIO."""

    def __init__(self, process: subprocess.Popen[bytes]) -> None:
        require(process.stdout is not None, "R3R4R6R2R3_NATIVE_STDOUT_PIPE_MISSING")
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
                require(bool(raw), "R3R4R6R2R3_NATIVE_EMPTY_EVENT")
                try:
                    event = json.loads(raw.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                    raise GateError("R3R4R6R2R3_NATIVE_EVENT_SCHEMA_INVALID") from exc
                require(isinstance(event, dict) and isinstance(event.get("type"), str),
                        "R3R4R6R2R3_NATIVE_EVENT_SCHEMA_INVALID")
                require(all(isinstance(value, (str, int, float, bool, type(None)))
                            for value in event.values()),
                        "R3R4R6R2R3_NATIVE_EVENT_NOT_METADATA_ONLY")
                return event
            ready = self.selector.select(
                timeout=min(0.05, max(0.0, deadline - time.monotonic())))
            if ready:
                chunk = os.read(self.fd, 65536)
                if chunk:
                    self.buffer.extend(chunk)
                    continue
                if self.process.poll() is not None:
                    raise GateError("R3R4R6R2R3_NATIVE_STDOUT_CLOSED")
            if self.process.poll() is not None and not self.buffer:
                raise GateError("R3R4R6R2R3_NATIVE_EXITED_BEFORE_REQUIRED_EVENT")
        raise GateError("R3R4R6R2R3_NATIVE_EVENT_TIMEOUT")


def record_event(event: dict[str, Any], events: list[dict[str, Any]],
                 event_log: Any) -> None:
    events.append(event)
    event_log.write(json.dumps(event, sort_keys=True, separators=(",", ":")) + "\n")
    event_log.flush()
    os.fsync(event_log.fileno())


def wait_event(reader: MetadataEventReader, expected: str, deadline: float,
               events: list[dict[str, Any]], event_log: Any) -> dict[str, Any]:
    while True:
        event = reader.read(deadline)
        record_event(event, events, event_log)
        if event["type"] == "ERROR":
            raise GateError(str(event.get("blocker") or
                                "R3R4R6R2R3_NATIVE_UNSPECIFIED_ERROR"))
        if event["type"] == expected:
            return event


def wait_primary_window(reader: MetadataEventReader,
                        events: list[dict[str, Any]], event_log: Any) -> dict[str, Any]:
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
                raise GateError("R3R4R6R2R3_TOTAL_CAPTURE_TIMEOUT") from exc
            if now >= progress_deadline:
                raise GateError("R3R4R6R2R3_NO_PROGRESS_TIMEOUT") from exc
            raise
        record_event(event, events, event_log)
        if event["type"] == "ERROR":
            raise GateError(str(event.get("blocker") or
                                "R3R4R6R2R3_NATIVE_UNSPECIFIED_ERROR"))
        if event["type"] == "ROLLING_PROGRESS":
            progress_deadline = time.monotonic() + NO_PROGRESS_TIMEOUT_SECONDS
        if event["type"] == "PRIMARY_WINDOW_COMPLETE":
            return event


def run(args: argparse.Namespace) -> dict[str, Any]:
    result: dict[str, Any] = {
        "schema": "R3R4R6R2R3_CONTROLLER_RESULT_V1", "task": TASK,
        "result": "FAIL", "blocker": None, "events": [],
        "record_bytes": RECORD_BYTES, "primary_records": PRIMARY_RECORDS,
        "primary_requested_bytes": PRIMARY_BYTES, "guard_records": GUARD_RECORDS,
        "guard_requested_bytes": GUARD_BYTES,
        "total_logical_requests": TOTAL_LOGICAL_REQUESTS,
        "max_outstanding_iocbs": MAX_OUTSTANDING_IOCBS,
        "parent_owned_mmio": True, "raw_payload_control_ipc": False,
        "unauthorized_mmio_writes": 0,
    }
    mmio: Mmio | None = None
    process: subprocess.Popen[bytes] | None = None
    reader: MetadataEventReader | None = None
    event_log: Any = None
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
        require(lock_receipt.is_file(), "R3R4R6R2R3_LINUX_TASK_LOCK_NOT_HELD")
        lock = json.loads(lock_receipt.read_text(encoding="utf-8"))
        require(lock.get("task") == TASK and lock.get("state") == "HELD",
                "R3R4R6R2R3_LINUX_TASK_LOCK_RECEIPT_INVALID")
        require(Path(args.user_node).is_char_device(),
                "R3R4R6R2R3_DRIVER_OR_NODE_OPERATION_FAILED:USER_NODE")
        require(Path(args.c2h_node).is_char_device(),
                "R3R4R6R2R3_DRIVER_OR_NODE_OPERATION_FAILED:C2H_NODE")
        require(Path(args.native_helper).is_file(),
                "R3R4R6R2R3_NATIVE_HELPER_MISSING")
        Path(args.private_dir).mkdir(parents=True, exist_ok=True, mode=0o700)
        logs.mkdir(parents=True, exist_ok=True, mode=0o700)
        event_log = (logs / "rolling-progress.jsonl").open(
            "x", encoding="utf-8", newline="\n")

        mmio = Mmio(args.user_node)
        result["source_readiness"] = source_readiness(mmio)
        control = mmio.read(0x380C, "S0")
        status = mmio.read(0x3810, "S0")
        require(hardware_quiescent(control, status),
                "R3R4R6R2R3_S0_NOT_PHYSICALLY_QUIESCENT")
        s0 = mmio.checkpoint("S0")
        timeline.append(s0)
        result["S0"] = s0

        mmio.write(0x380C, 4, "RESET_STREAM_STATE", "S0_QUIESCENT")
        reset_deadline = time.monotonic() + 5.0
        while True:
            control = mmio.read(0x380C, "RESET_WAIT")
            status = mmio.read(0x3810, "RESET_WAIT")
            if hardware_quiescent(control, status):
                break
            require(time.monotonic() < reset_deadline,
                    "R3R4R6R2R3_RESET_STREAM_STATE_TIMEOUT")
            time.sleep(0.001)
        s1 = mmio.checkpoint("S1")
        timeline.append(s1)
        result["S1"] = s1
        require(s1["Epoch"] == ((s0["Epoch"] + 1) & 0xFFFFFFFF),
                "R3R4R6R2R3_RESET_EPOCH_TRANSITION_FAILED")

        normalization = mmio.read(0x383C, "S1_W1C_READ") & 0x3F
        result["session_normalization_w1c_mask"] = normalization
        if normalization:
            mmio.write(0x383C, normalization, "SESSION_NORMALIZATION_W1C",
                       "POST_RESET_QUIESCENT")
        post_error = mmio.read(0x383C, "S2")
        require((post_error & 0x3F) == 0,
                "R3R4R6R2R3_SESSION_NORMALIZATION_DID_NOT_CLEAR")
        s2_cause = mmio.read(0x3840, "S2")
        baseline = mmio.snapshot("BASELINE_PRE_ENABLE")
        s2 = snapshot_row(
            "S2", baseline, post_error, s2_cause,
            mmio.read(0x380C, "S2"), mmio.read(0x3810, "S2"))
        timeline.append(s2)
        result["S2"] = s2
        result["baseline_snapshot"] = baseline

        process = subprocess.Popen(
            [args.native_helper, args.c2h_node, args.private_dir],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            bufsize=0, close_fds=True)
        reader = MetadataEventReader(process)
        prequeue = wait_event(reader, "ROLLING_PREQUEUE_READY",
                              time.monotonic() + 15.0, result["events"], event_log)
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
                "R3R4R6R2R3_ROLLING_PREQUEUE_READY_CONTRACT_FAILED")
        result["rolling_prequeue_ready"] = prequeue

        enable_ns = mmio.write(0x380C, 1, "STREAM_ENABLE",
                               "ROLLING_PREQUEUE_READY")
        stream_enabled = True
        result["prequeue_ready_to_enable_latency_us"] = round(
            (enable_ns - int(prequeue["monotonic_ns"])) / 1000.0, 3)
        primary = wait_primary_window(reader, result["events"], event_log)
        result["primary_completion"] = primary
        require(primary.get("primary_exact_completions") == PRIMARY_RECORDS and
                primary.get("primary_short_completions") == 0 and
                primary.get("primary_failed_completions") == 0 and
                primary.get("primary_pending") == 0 and
                primary.get("primary_bytes") == PRIMARY_BYTES and
                isinstance(primary.get("maximum_outstanding"), int) and
                primary["maximum_outstanding"] <= MAX_OUTSTANDING_IOCBS,
                "R3R4R6R2R3_PRIMARY_WINDOW_INCOMPLETE")

        disable_ns = mmio.write(0x380C, 0, "NORMAL_DISABLE",
                                "PRIMARY_WINDOW_COMPLETE")
        normal_disabled = True
        stream_enabled = False
        result["primary_complete_to_disable_us"] = round(
            (disable_ns - int(primary["monotonic_ns"])) / 1000.0, 3)
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

        parent_quiescent, quiescence_rows = prove_quiescence(mmio, "POST_DISABLE")
        require(parent_quiescent, "R3R4R6R2R3_PHYSICAL_QUIESCENCE_NOT_PROVEN")
        result["physical_quiescence"] = {
            "result": "PASS", "total_samples": len(quiescence_rows),
            "accepted_samples": quiescence_rows[-1]["Consecutive"],
            "span_ms": quiescence_rows[-1]["SpanMs"],
        }
        require(process.stdin is not None, "R3R4R6R2R3_NATIVE_STDIN_PIPE_MISSING")
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

        exit_event = None
        durable_event = None
        guard_event = None
        native_deadline = time.monotonic() + 15.0
        while exit_event is None:
            event = reader.read(native_deadline)
            record_event(event, result["events"], event_log)
            if event["type"] == "ERROR":
                raise GateError(str(event.get("blocker") or
                                    "R3R4R6R2R3_NATIVE_POST_CAPTURE_ERROR"))
            if event["type"] == "PRIMARY_DURABLE":
                durable_event = event
            elif event["type"] == "GUARD_CLEANUP_COMPLETE":
                guard_event = event
            elif event["type"] == "HELPER_EXIT_READY":
                exit_event = event
        process.wait(timeout=max(0.1, native_deadline - time.monotonic()))
        stderr_bytes = process.stderr.read() if process.stderr else b""
        stderr = stderr_bytes.decode("utf-8", errors="replace")
        result["native_helper_exit_code"] = process.returncode
        result["native_helper_stderr"] = stderr
        result["primary_durable"] = durable_event
        result["guard_cleanup"] = guard_event
        require(process.returncode == 0 and not stderr.strip() and
                durable_event is not None and guard_event is not None and
                exit_event.get("result") == "PASS",
                "R3R4R6R2R3_NATIVE_HELPER_FINALIZATION_FAILED")
        require(durable_event.get("file_bytes") == PRIMARY_BYTES and
                durable_event.get("primary_exact_completions") == PRIMARY_RECORDS and
                isinstance(durable_event.get("sha256"), str) and
                len(durable_event["sha256"]) == 64,
                "R3R4R6R2R3_PRIMARY_DURABILITY_CONTRACT_FAILED")
        require(guard_event.get("guard_exact_completions", 0) +
                guard_event.get("guard_canceled", 0) == GUARD_RECORDS and
                guard_event.get("guard_short_completions") == 0 and
                guard_event.get("guard_failed_completions") == 0 and
                guard_event.get("final_pending") == 0 and
                guard_event.get("maximum_outstanding", MAX_OUTSTANDING_IOCBS + 1)
                <= MAX_OUTSTANDING_IOCBS and
                guard_event.get("descriptor_window_violations") == 0 and
                guard_event.get("descriptor_starvation_events") == 0 and
                guard_event.get("crossed_logical_index_2048") is True,
                "R3R4R6R2R3_GUARD_OR_DESCRIPTOR_FINAL_CONTRACT_FAILED")

        helper_result_path = Path(args.private_dir) / "helper-result.json"
        require(helper_result_path.is_file(),
                "R3R4R6R2R3_HELPER_RESULT_MISSING")
        helper_result = json.loads(helper_result_path.read_text(encoding="utf-8"))
        result["rolling_metrics"] = helper_result
        require(helper_result.get("result") == "PASS" and
                helper_result.get("submitted") == TOTAL_LOGICAL_REQUESTS and
                helper_result.get("completed") == TOTAL_LOGICAL_REQUESTS and
                helper_result.get("pending") == 0 and
                helper_result.get("primary_exact") == PRIMARY_RECORDS and
                helper_result.get("primary_short") == 0 and
                helper_result.get("primary_failed") == 0 and
                helper_result.get("guard_exact", 0) +
                helper_result.get("guard_canceled", 0) == GUARD_RECORDS and
                helper_result.get("guard_short") == 0 and
                helper_result.get("guard_failed") == 0 and
                helper_result.get("max_outstanding", MAX_OUTSTANDING_IOCBS + 1)
                <= MAX_OUTSTANDING_IOCBS and
                helper_result.get("descriptor_window_violations") == 0 and
                helper_result.get("descriptor_starvation_events") == 0 and
                helper_result.get("crossed_logical_index_2048") is True,
                "R3R4R6R2R3_ROLLING_METRICS_FINAL_CONTRACT_FAILED")

        primary_path = Path(args.private_dir) / "primary.bin"
        require(primary_path.is_file() and primary_path.stat().st_size == PRIMARY_BYTES,
                "R3R4R6R2R3_PRIMARY_FILE_SIZE_INVALID")
        result["primary_file"] = str(primary_path)
        result["primary_file_bytes"] = primary_path.stat().st_size
        result["primary_file_sha256"] = durable_event["sha256"]
        result["primary_completion_progress_last_reported"] = max(
            (int(event.get("primary_completed", 0)) for event in result["events"]
             if event.get("type") == "ROLLING_PROGRESS"), default=0)
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
        if event_log is not None:
            event_log.flush()
            os.fsync(event_log.fileno())
            event_log.close()
        if reader is not None:
            reader.close()
        if mmio is not None:
            intents = [row for row in mmio.ledger if row["Result"] == "INTENT"]
            result["mmio_write_counts"] = {
                purpose: sum(row["Purpose"] == purpose for row in intents)
                for purpose in ("RESET_STREAM_STATE", "SESSION_NORMALIZATION_W1C",
                                "COHERENT_SNAPSHOT", "STREAM_ENABLE",
                                "NORMAL_DISABLE", "SAFETY_DISABLE")
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
    args = parser.parse_args()
    result = run(args)
    output = Path(args.logs_dir) / "controller-result.json"
    if not output.exists():
        write_json(output, result)
    print(json.dumps({
        "task": TASK, "result": result["result"],
        "blocker": result.get("blocker"),
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
