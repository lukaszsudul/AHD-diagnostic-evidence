#!/usr/bin/env python3
"""Parent-owned MMIO controller for one R3R4R6R1 prequeued finite capture."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
import selectors
import struct
import subprocess
import sys
import time
import traceback
from typing import Any

TASK = "G2B-HW0-PRODUCT-R3R4R6R1"
PRIMARY_BYTES = 10_240_000
GUARD_BYTES = 4_194_304
RECORD_BYTES = 4096
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


def json_safe_event(event: dict[str, Any]) -> None:
    allowed = (str, int, float, bool, type(None))
    require(all(isinstance(value, allowed) for value in event.values()),
            "R3R4R6R1_NATIVE_EVENT_NOT_METADATA_ONLY")


class Mmio:
    def __init__(self, node: str) -> None:
        flags = os.O_RDWR | os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        self.node = node
        self.fd = os.open(node, flags)
        self.raw_rows: list[dict[str, Any]] = []
        self.ledger: list[dict[str, Any]] = []
        self.last_error_read: int | None = None

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def read(self, offset: int, label: str) -> int:
        require(offset % 4 == 0 and any(lo <= offset <= hi
                for lo, hi in READ_RANGES),
                "R3R4R6R1_MMIO_READ_ALLOWLIST_VIOLATION")
        stamp = time.time_ns()
        data = os.pread(self.fd, 4, offset)
        require(len(data) == 4, "R3R4R6R1_SHORT_MMIO_READ")
        value = struct.unpack("<I", data)[0]
        if offset == 0x383C:
            self.last_error_read = value
        self.raw_rows.append({
            "Timestamp": stamp, "Label": label, "Operation": "READ",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Result": "PASS",
        })
        return value

    def write(self, offset: int, value: int, purpose: str,
              precondition: str) -> int:
        intents = [row for row in self.ledger if row["Result"] == "INTENT"]
        reset_count = sum(row["Purpose"] == "RESET_STREAM_STATE"
                          for row in intents)
        enable_count = sum(row["Purpose"] == "STREAM_ENABLE"
                           for row in intents)
        normal_disable_count = sum(row["Purpose"] == "NORMAL_DISABLE"
                                   for row in intents)
        safety_disable_count = sum(row["Purpose"] == "SAFETY_DISABLE"
                                   for row in intents)
        snapshot_count = sum(row["Purpose"] == "COHERENT_SNAPSHOT"
                             for row in intents)
        w1c_count = sum(row["Purpose"] == "SESSION_NORMALIZATION_W1C"
                        for row in intents)
        if (offset, value, purpose) == (0x380C, 4, "RESET_STREAM_STATE"):
            require(reset_count == 0, "R3R4R6R1_RESET_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 1, "STREAM_ENABLE"):
            require(enable_count == 0,
                    "R3R4R6R1_STREAM_ENABLE_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "NORMAL_DISABLE"):
            require(normal_disable_count == 0,
                    "R3R4R6R1_NORMAL_DISABLE_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "SAFETY_DISABLE"):
            require(enable_count == 1 and safety_disable_count == 0,
                    "R3R4R6R1_SAFETY_DISABLE_WRITE_PRECONDITION_FAILED")
        elif (offset, value, purpose) == (0x3844, 1, "COHERENT_SNAPSHOT"):
            require(snapshot_count < 3,
                    "R3R4R6R1_SNAPSHOT_WRITE_BUDGET_EXCEEDED")
        elif offset == 0x383C and purpose == "SESSION_NORMALIZATION_W1C":
            require(w1c_count == 0 and self.last_error_read is not None,
                    "R3R4R6R1_W1C_WRITE_BUDGET_OR_READ_PRECONDITION")
            require(value != 0 and value == (self.last_error_read & 0x3F),
                    "R3R4R6R1_W1C_MASK_NOT_FROM_IMMEDIATE_READ")
            require(precondition == "POST_RESET_QUIESCENT",
                    "R3R4R6R1_W1C_QUIESCENT_PRECONDITION_FAILED")
        else:
            raise GateError("R3R4R6R1_MMIO_WRITE_ALLOWLIST_VIOLATION")
        stamp = time.time_ns()
        base = {
            "Timestamp": stamp, "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Precondition": precondition,
            "Authorized": "YES",
        }
        self.ledger.append({**base, "Result": "INTENT"})
        count = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(count == 4, "R3R4R6R1_SHORT_MMIO_WRITE")
        completed_ns = time.monotonic_ns()
        self.ledger.append({**base, "Result": "PASS",
                            "CompletionMonotonicNs": completed_ns})
        self.raw_rows.append({
            "Timestamp": stamp, "Label": purpose, "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Result": "PASS",
        })
        return completed_ns

    def counters(self, label: str) -> dict[str, int]:
        result = {name: self.read(offset, label)
                  for name, offset in COUNTER_OFFSETS.items()}
        result["beats"] = ((result["beats_high"] << 32) |
                           result["beats_low"])
        return result

    def checkpoint(self, name: str) -> dict[str, Any]:
        stamp = time.time_ns()
        epoch = self.read(0x3838, name)
        error = self.read(0x383C, name)
        cause = self.read(0x3840, name)
        counters = self.counters(name)
        return {
            "Checkpoint": name, "Epoch": epoch,
            "ErrorStatus": error, "LastErrorCause": cause,
            "Attempted": counters["attempted"],
            "Committed": counters["committed"],
            "Streamed": counters["streamed"],
            "Dropped": counters["dropped"],
            "Overflow": counters["overflow"],
            "Discontinuity": counters["discontinuity"],
            "Timestamp": stamp,
        }

    def snapshot(self, label: str) -> dict[str, Any]:
        epoch = self.read(0x3838, label)
        generation = self.read(0x384C, label)
        require((self.read(0x3810, label) & 0x300) == 0,
                "R3R4R6R1_SNAPSHOT_OR_RESET_BUSY")
        self.write(0x3844, 1, "COHERENT_SNAPSHOT", label)
        deadline = time.monotonic() + 2.0
        expected_generation = (generation + 1) & 0xFFFFFFFF
        while True:
            snapshot_status = self.read(0x3848, label) & 3
            observed_generation = self.read(0x384C, label)
            if snapshot_status == 2 and observed_generation == expected_generation:
                break
            require(time.monotonic() < deadline,
                    "R3R4R6R1_COHERENT_SNAPSHOT_TIMEOUT")
            time.sleep(0.001)
        counters = self.counters(label)
        require(self.read(0x3838, label) == epoch,
                "R3R4R6R1_SNAPSHOT_EPOCH_CHANGED")
        return {
            "label": label, "epoch": epoch,
            "generation": expected_generation, **counters,
        }


def hardware_quiescent(control: int, status: int) -> bool:
    return control == 0 and status & 0x10F == 0x004


def prove_quiescence(mmio: Mmio, label: str,
                     timeout_seconds: float = 10.0) -> tuple[bool, list[dict]]:
    deadline = time.monotonic() + timeout_seconds
    observations: list[dict] = []
    consecutive = 0
    first_accepted: float | None = None
    while time.monotonic() < deadline:
        sample_start = time.monotonic()
        control = mmio.read(0x380C, label)
        status = mmio.read(0x3810, label)
        accepted = hardware_quiescent(control, status)
        now = time.monotonic()
        if accepted:
            if consecutive == 0:
                first_accepted = now
            consecutive += 1
        else:
            consecutive = 0
            first_accepted = None
        span = 0.0 if first_accepted is None else now - first_accepted
        observations.append({
            "Timestamp": time.time_ns(), "Label": label,
            "Sample": len(observations) + 1, "Control": control,
            "Status": status, "Accepted": accepted,
            "Consecutive": consecutive, "SpanMs": round(span * 1000, 3),
        })
        if consecutive >= 5 and span >= 0.400:
            return True, observations
        remaining = 0.100 - (time.monotonic() - sample_start)
        if remaining > 0:
            time.sleep(remaining)
    return False, observations


def read_native_event(process: subprocess.Popen[str], selector: selectors.BaseSelector,
                      deadline: float) -> dict[str, Any]:
    while time.monotonic() < deadline:
        ready = selector.select(timeout=min(0.25, deadline - time.monotonic()))
        if ready:
            line = process.stdout.readline() if process.stdout else ""
            require(bool(line), "R3R4R6R1_NATIVE_HELPER_STDOUT_CLOSED")
            event = json.loads(line)
            require(isinstance(event, dict) and isinstance(event.get("type"), str),
                    "R3R4R6R1_NATIVE_EVENT_SCHEMA_INVALID")
            json_safe_event(event)
            return event
        if process.poll() is not None:
            raise GateError("R3R4R6R1_NATIVE_HELPER_EXITED_BEFORE_REQUIRED_EVENT")
    raise GateError("R3R4R6R1_NATIVE_HELPER_EVENT_TIMEOUT")


def wait_for_type(process: subprocess.Popen[str], selector: selectors.BaseSelector,
                  expected: str, deadline: float,
                  events: list[dict[str, Any]]) -> dict[str, Any]:
    while True:
        event = read_native_event(process, selector, deadline)
        events.append(event)
        if event["type"] == "ERROR":
            raise GateError(str(event.get("blocker") or
                                "R3R4R6R1_NATIVE_HELPER_UNSPECIFIED_ERROR"))
        if event["type"] == expected:
            return event


def write_json(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, Any]]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})
        handle.flush()
        os.fsync(handle.fileno())


def delta32(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFF


def delta64(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFFFFFFFFFF


def run(args: argparse.Namespace) -> dict[str, Any]:
    result: dict[str, Any] = {
        "schema": "R3R4R6R1_CONTROLLER_RESULT_V1", "task": TASK,
        "result": "FAIL", "blocker": None, "events": [],
        "parent_owned_mmio": True, "raw_payload_control_ipc": False,
        "primary_requested_bytes": PRIMARY_BYTES,
        "guard_requested_bytes": GUARD_BYTES,
        "unauthorized_mmio_writes": 0,
    }
    mmio: Mmio | None = None
    process: subprocess.Popen[str] | None = None
    selector: selectors.BaseSelector | None = None
    stream_enabled = False
    normal_disabled = False
    parent_quiescent = False
    quiescence_rows: list[dict[str, Any]] = []
    timeline: list[dict[str, Any]] = []
    start_capture_monotonic = 0.0
    try:
        lock_directory = Path(args.linux_lock)
        require(lock_directory.is_dir(),
                "R3R4R6R1_LINUX_TASK_LOCK_NOT_HELD")
        lock_receipt_path = lock_directory / "receipt.json"
        require(lock_receipt_path.is_file(),
                "R3R4R6R1_LINUX_TASK_LOCK_RECEIPT_MISSING")
        lock_receipt = json.loads(lock_receipt_path.read_text(encoding="utf-8"))
        require(lock_receipt.get("task") == TASK and
                lock_receipt.get("state") == "HELD",
                "R3R4R6R1_LINUX_TASK_LOCK_RECEIPT_INVALID")
        result["linux_lock_receipt"] = lock_receipt
        require(Path(args.user_node).is_char_device(),
                "OWNER_ATTESTED_RUNTIME_STATE_CONTRADICTED_BY_USER_NODE")
        require(Path(args.c2h_node).is_char_device(),
                "OWNER_ATTESTED_RUNTIME_STATE_CONTRADICTED_BY_C2H_NODE")
        require(Path(args.native_helper).is_file(),
                "R3R4R6R1_NATIVE_HELPER_MISSING")
        Path(args.private_dir).mkdir(parents=True, exist_ok=True, mode=0o700)
        Path(args.logs_dir).mkdir(parents=True, exist_ok=True, mode=0o700)

        mmio = Mmio(args.user_node)
        control = mmio.read(0x380C, "S0")
        status = mmio.read(0x3810, "S0")
        require(hardware_quiescent(control, status),
                "OWNER_ATTESTED_RUNTIME_STATE_CONTRADICTED_BY_S0_QUIESCENCE")
        s0 = mmio.checkpoint("S0")
        timeline.append(s0)
        result["S0"] = s0
        result["S0_owner_expected"] = {
            "Epoch": 3,
            "ErrorStatus": 0x00000007,
            "LastErrorCause": 0x00000003,
        }
        result["S0_deviations"] = {
            key: {"expected": expected, "observed": s0[key]}
            for key, expected in result["S0_owner_expected"].items()
            if s0[key] != expected
        }
        require(s0["Epoch"] == 3,
                "OWNER_ATTESTED_STATE_OPERATIONAL_CONTRADICTION:S0_EPOCH_NOT_3")

        mmio.write(0x380C, 4, "RESET_STREAM_STATE", "S0_QUIESCENT")
        reset_deadline = time.monotonic() + 5.0
        while True:
            control = mmio.read(0x380C, "RESET_WAIT")
            status = mmio.read(0x3810, "RESET_WAIT")
            if hardware_quiescent(control, status):
                break
            require(time.monotonic() < reset_deadline,
                    "R3R4R6R1_RESET_STREAM_STATE_TIMEOUT")
            time.sleep(0.001)
        s1 = mmio.checkpoint("S1")
        timeline.append(s1)
        result["S1"] = s1
        require(s1["Epoch"] == 4,
                "R3R4R6R1_RESET_EPOCH_3_TO_4_FAILED")
        require((s1["ErrorStatus"] & ~0x3F) == 0,
                "R3R4R6R1_S1_ERROR_STATUS_OUTSIDE_W1C_ALLOWLIST")

        normalization_mask = mmio.read(0x383C, "S1_W1C_READ") & 0x3F
        result["session_normalization_w1c_mask"] = normalization_mask
        if normalization_mask:
            mmio.write(0x383C, normalization_mask,
                       "SESSION_NORMALIZATION_W1C", "POST_RESET_QUIESCENT")
        post_normalization = mmio.read(0x383C, "S2")
        require((post_normalization & 0x3F) == 0,
                "R3R4R6R1_SESSION_NORMALIZATION_DID_NOT_CLEAR")
        s2_epoch = mmio.read(0x3838, "S2")
        s2_error = mmio.read(0x383C, "S2")
        s2_cause = mmio.read(0x3840, "S2")
        baseline = mmio.snapshot("BASELINE_PRE_ENABLE")
        s2 = {
            "Checkpoint": "S2", "Epoch": s2_epoch,
            "ErrorStatus": s2_error, "LastErrorCause": s2_cause,
            "Attempted": baseline["attempted"],
            "Committed": baseline["committed"],
            "Streamed": baseline["streamed"],
            "Dropped": baseline["dropped"],
            "Overflow": baseline["overflow"],
            "Discontinuity": baseline["discontinuity"],
            "Timestamp": time.time_ns(),
        }
        timeline.append(s2)
        result["S2"] = s2
        result["baseline_snapshot"] = baseline

        process = subprocess.Popen(
            [args.native_helper, args.c2h_node, args.private_dir],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, text=True, bufsize=1, close_fds=True)
        selector = selectors.DefaultSelector()
        require(process.stdout is not None, "R3R4R6R1_NATIVE_STDOUT_PIPE_MISSING")
        selector.register(process.stdout, selectors.EVENT_READ)
        prequeue = wait_for_type(process, selector, "PREQUEUE_READY",
                                 time.monotonic() + 15.0, result["events"])
        require(prequeue.get("primary_bytes") == PRIMARY_BYTES and
                prequeue.get("guard_bytes") == GUARD_BYTES and
                prequeue.get("primary_submit_result") == 1 and
                prequeue.get("guard_submit_result") == 1,
                "R3R4R6R1_PREQUEUE_READY_CONTRACT_FAILED")
        result["prequeue_ready"] = prequeue

        enable_completed_ns = mmio.write(
            0x380C, 1, "STREAM_ENABLE", "PREQUEUE_READY")
        stream_enabled = True
        start_capture_monotonic = time.monotonic()
        result["prequeue_ready_to_enable_latency_us"] = round(
            (enable_completed_ns - int(prequeue["monotonic_ns"])) / 1000.0, 3)

        primary = wait_for_type(process, selector, "PRIMARY_BUFFER_COMPLETE",
                                start_capture_monotonic + 30.0,
                                result["events"])
        result["primary_completion"] = primary
        primary_result = int(primary["result_bytes"])
        if primary_result == PRIMARY_BYTES:
            disable_completed_ns = mmio.write(
                0x380C, 0, "NORMAL_DISABLE", "PRIMARY_BUFFER_COMPLETE")
            normal_disabled = True
        else:
            disable_completed_ns = mmio.write(
                0x380C, 0, "SAFETY_DISABLE", "PRIMARY_AIO_RESULT_NOT_EXACT")
        stream_enabled = False
        result["primary_completion_to_disable_latency_us"] = round(
            (disable_completed_ns - int(primary["monotonic_ns"])) / 1000.0, 3)

        parent_quiescent, quiescence_rows = prove_quiescence(
            mmio, "POST_DISABLE")
        require(parent_quiescent,
                "R3R4R6R1_PARENT_HARDWARE_QUIESCENCE_NOT_PROVEN")
        result["parent_hardware_quiescence"] = {
            "result": "PASS", "samples": len(quiescence_rows),
            "accepted_samples": quiescence_rows[-1]["Consecutive"],
            "span_ms": quiescence_rows[-1]["SpanMs"],
        }
        require(process.stdin is not None, "R3R4R6R1_NATIVE_STDIN_PIPE_MISSING")
        process.stdin.write("PARENT_QUIESCENT\n")
        process.stdin.flush()
        process.stdin.close()

        native_deadline = time.monotonic() + 20.0
        while process.poll() is None:
            event = read_native_event(process, selector, native_deadline)
            result["events"].append(event)
            if event["type"] == "ERROR":
                result.setdefault("native_errors", []).append(event)
        while True:
            try:
                event = read_native_event(process, selector,
                                          time.monotonic() + 0.05)
            except GateError:
                break
            result["events"].append(event)
        stderr = process.stderr.read() if process.stderr else ""
        result["native_helper_exit_code"] = process.returncode
        result["native_helper_stderr"] = stderr
        require(not stderr.strip(), "R3R4R6R1_NATIVE_HELPER_STDERR_NONEMPTY")
        require(process.returncode == 0,
                "R3R4R6R1_NATIVE_HELPER_EXIT_FAILED")

        final_control = mmio.read(0x380C, "FINAL_PHYSICAL_STATE")
        final_status = mmio.read(0x3810, "FINAL_PHYSICAL_STATE")
        require(hardware_quiescent(final_control, final_status),
                "R3R4R6R1_FINAL_PHYSICAL_QUIESCENCE_LOST")
        result["final_physical_state"] = {
            "control": final_control,
            "status": final_status,
            "stream_disabled": final_control == 0,
            "dma_quiescent": True,
        }
        s3_epoch = mmio.read(0x3838, "S3")
        s3_error = mmio.read(0x383C, "S3")
        s3_cause = mmio.read(0x3840, "S3")
        final_snapshot = mmio.snapshot("FINAL_POST_QUIESCENCE")
        s3 = {
            "Checkpoint": "S3", "Epoch": s3_epoch,
            "ErrorStatus": s3_error, "LastErrorCause": s3_cause,
            "Attempted": final_snapshot["attempted"],
            "Committed": final_snapshot["committed"],
            "Streamed": final_snapshot["streamed"],
            "Dropped": final_snapshot["dropped"],
            "Overflow": final_snapshot["overflow"],
            "Discontinuity": final_snapshot["discontinuity"],
            "Timestamp": time.time_ns(),
        }
        timeline.append(s3)
        result["S3"] = s3
        result["final_snapshot"] = final_snapshot
        result["counter_deltas"] = {
            "attempted": delta32(final_snapshot["attempted"],
                                 baseline["attempted"]),
            "committed": delta32(final_snapshot["committed"],
                                 baseline["committed"]),
            "streamed": delta32(final_snapshot["streamed"],
                                baseline["streamed"]),
            "dropped": delta32(final_snapshot["dropped"],
                               baseline["dropped"]),
            "overflow": delta32(final_snapshot["overflow"],
                                baseline["overflow"]),
            "discontinuity": delta32(final_snapshot["discontinuity"],
                                     baseline["discontinuity"]),
            "abandoned": delta32(final_snapshot["abandoned"],
                                 baseline["abandoned"]),
            "reset_events": delta32(final_snapshot["reset_events"],
                                    baseline["reset_events"]),
            "beats": delta64(final_snapshot["beats"], baseline["beats"]),
            "last_global": final_snapshot["last_global"],
            "last_attempt": final_snapshot["last_attempt"],
        }
        require(primary_result == PRIMARY_BYTES,
                "PRIMARY_AIO_FINITE_BUFFER_NOT_FILLED")
        result["result"] = "PASS"
        result["blocker"] = None
        return result
    except BaseException as exc:
        result["result"] = "FAIL"
        result["blocker"] = (str(exc).strip() or type(exc).__name__)
        result["exception_type"] = type(exc).__name__
        result["traceback"] = traceback.format_exc()
        if mmio is not None and stream_enabled:
            try:
                mmio.write(0x380C, 0, "SAFETY_DISABLE",
                           "POST_ENABLE_EXCEPTION_STREAM_ACTIVE")
                stream_enabled = False
                passed, failure_rows = prove_quiescence(mmio, "FAILURE_PATH")
                quiescence_rows.extend(failure_rows)
                parent_quiescent = passed
                result["failure_path_quiescence"] = "PASS" if passed else "FAIL"
            except BaseException as cleanup_exc:
                result["failure_path_quiescence"] = "FAIL"
                result["failure_path_quiescence_detail"] = str(cleanup_exc)
        if (process is not None and process.poll() is None and parent_quiescent and
                process.stdin is not None and not process.stdin.closed):
            try:
                process.stdin.write("PARENT_QUIESCENT\n")
                process.stdin.flush()
                process.stdin.close()
                process.wait(timeout=20.0)
            except BaseException as wait_exc:
                result["native_failure_wait"] = str(wait_exc)
        return result
    finally:
        if selector is not None:
            selector.close()
        if mmio is not None:
            result["mmio_write_intents"] = sum(
                row["Result"] == "INTENT" for row in mmio.ledger)
            intents = [row for row in mmio.ledger if row["Result"] == "INTENT"]
            result["mmio_write_counts"] = {
                purpose: sum(row["Purpose"] == purpose for row in intents)
                for purpose in (
                    "RESET_STREAM_STATE", "SESSION_NORMALIZATION_W1C",
                    "COHERENT_SNAPSHOT", "STREAM_ENABLE", "NORMAL_DISABLE",
                    "SAFETY_DISABLE",
                )
            }
            result["normal_disable_completed"] = normal_disabled
            result["parent_quiescent_completed"] = parent_quiescent
            mmio.close()
            logs = Path(args.logs_dir)
            logs.mkdir(parents=True, exist_ok=True, mode=0o700)
            if not (logs / "mmio-write-ledger.csv").exists():
                write_csv(logs / "mmio-write-ledger.csv",
                          ["Timestamp", "Operation", "Offset", "Value",
                           "Purpose", "Precondition", "Authorized", "Result",
                           "CompletionMonotonicNs"], mmio.ledger)
            if not (logs / "mmio-raw.csv").exists():
                write_csv(logs / "mmio-raw.csv",
                          ["Timestamp", "Label", "Operation", "Offset",
                           "Value", "Result"], mmio.raw_rows)
        logs = Path(args.logs_dir)
        if timeline and not (logs / "error-timeline.csv").exists():
            write_csv(logs / "error-timeline.csv",
                      ["Checkpoint", "Epoch", "ErrorStatus", "LastErrorCause",
                       "Attempted", "Committed", "Streamed", "Dropped",
                       "Overflow", "Discontinuity", "Timestamp"], timeline)
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
        "primary_result_bytes": result.get("primary_completion", {}).get(
            "result_bytes"),
        "prequeue_ready_to_enable_latency_us": result.get(
            "prequeue_ready_to_enable_latency_us"),
        "primary_completion_to_disable_latency_us": result.get(
            "primary_completion_to_disable_latency_us"),
    }, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
