#!/usr/bin/env python3
"""Parent-owned MMIO controller for the one-shot R3R4R6R2R2 4-KiB capture."""

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


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R2"
PRIMARY_RECORDS = 2500
RECORD_BYTES = 4096
PRIMARY_BYTES = PRIMARY_RECORDS * RECORD_BYTES
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
                "R3R4R6R2R2_MMIO_READ_ALLOWLIST_VIOLATION")
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, "R3R4R6R2R2_SHORT_MMIO_READ")
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
            require(count(purpose) == 0, "R3R4R6R2R2_RESET_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 1, "STREAM_ENABLE"):
            require(count(purpose) == 0, "R3R4R6R2R2_ENABLE_WRITE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "NORMAL_DISABLE"):
            require(count(purpose) == 0, "R3R4R6R2R2_NORMAL_DISABLE_BUDGET_EXCEEDED")
        elif (offset, value, purpose) == (0x380C, 0, "SAFETY_DISABLE"):
            require(count("STREAM_ENABLE") == 1 and count(purpose) == 0,
                    "R3R4R6R2R2_SAFETY_DISABLE_PRECONDITION_FAILED")
        elif (offset, value, purpose) == (0x3844, 1, "COHERENT_SNAPSHOT"):
            require(count(purpose) < 3, "R3R4R6R2R2_SNAPSHOT_BUDGET_EXCEEDED")
        elif offset == 0x383C and purpose == "SESSION_NORMALIZATION_W1C":
            require(count(purpose) == 0 and self.last_error_read is not None,
                    "R3R4R6R2R2_W1C_READ_OR_BUDGET_PRECONDITION_FAILED")
            require(value != 0 and value == (self.last_error_read & 0x3F),
                    "R3R4R6R2R2_W1C_MASK_NOT_FROM_IMMEDIATE_READ")
            require(precondition == "POST_RESET_QUIESCENT",
                    "R3R4R6R2R2_W1C_QUIESCENCE_PRECONDITION_FAILED")
        else:
            raise GateError("R3R4R6R2R2_MMIO_WRITE_ALLOWLIST_VIOLATION")
        started = time.time_ns()
        base = {
            "Timestamp": started, "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Precondition": precondition, "Authorized": "YES",
        }
        self.ledger.append({**base, "Result": "INTENT"})
        written = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(written == 4, "R3R4R6R2R2_SHORT_MMIO_WRITE")
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
            "ErrorStatus": self.read(0x383C, name),
            "LastErrorCause": self.read(0x3840, name),
            "Attempted": counters["attempted"],
            "Committed": counters["committed"],
            "Streamed": counters["streamed"],
            "Dropped": counters["dropped"],
            "Overflow": counters["overflow"],
            "Discontinuity": counters["discontinuity"],
            "Timestamp": time.time_ns(),
        }

    def snapshot(self, label: str) -> dict[str, Any]:
        epoch = self.read(0x3838, label)
        generation = self.read(0x384C, label)
        require((self.read(0x3810, label) & 0x300) == 0,
                "R3R4R6R2R2_SNAPSHOT_OR_RESET_BUSY")
        self.write(0x3844, 1, "COHERENT_SNAPSHOT", label)
        expected_generation = (generation + 1) & 0xFFFFFFFF
        deadline = time.monotonic() + 2.0
        while True:
            status = self.read(0x3848, label) & 3
            observed_generation = self.read(0x384C, label)
            if status == 2 and observed_generation == expected_generation:
                break
            require(time.monotonic() < deadline,
                    "R3R4R6R2R2_COHERENT_SNAPSHOT_TIMEOUT")
            time.sleep(0.001)
        counters = self.counters(label)
        require(self.read(0x3838, label) == epoch,
                "R3R4R6R2R2_SNAPSHOT_EPOCH_CHANGED")
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
            "R3R4R6R2R2_G2B_C2H_MAGIC_ABSENT")
    require(mmio.read(0x3804, "READINESS") == 0x00010000,
            "R3R4R6R2R2_TRANSPORT_ABI_VERSION_NOT_1")
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
    raise GateError("R3R4R6R2R2_LIVE_SOURCE_NOT_READY:" +
                    json.dumps(last, sort_keys=True))


def read_event(process: subprocess.Popen[str], selector: selectors.BaseSelector,
               deadline: float) -> dict[str, Any]:
    while time.monotonic() < deadline:
        ready = selector.select(timeout=min(0.25, max(0.0, deadline - time.monotonic())))
        if ready:
            line = process.stdout.readline() if process.stdout else ""
            require(bool(line), "R3R4R6R2R2_NATIVE_STDOUT_CLOSED")
            event = json.loads(line)
            require(isinstance(event, dict) and isinstance(event.get("type"), str),
                    "R3R4R6R2R2_NATIVE_EVENT_SCHEMA_INVALID")
            require(all(isinstance(value, (str, int, float, bool, type(None)))
                        for value in event.values()),
                    "R3R4R6R2R2_NATIVE_EVENT_NOT_METADATA_ONLY")
            return event
        if process.poll() is not None:
            raise GateError("R3R4R6R2R2_NATIVE_EXITED_BEFORE_REQUIRED_EVENT")
    raise GateError("R3R4R6R2R2_NATIVE_EVENT_TIMEOUT")


def wait_event(process: subprocess.Popen[str], selector: selectors.BaseSelector,
               expected: str, deadline: float,
               events: list[dict[str, Any]]) -> dict[str, Any]:
    while True:
        event = read_event(process, selector, deadline)
        events.append(event)
        if event["type"] == "ERROR":
            raise GateError(str(event.get("blocker") or
                                "R3R4R6R2R2_NATIVE_UNSPECIFIED_ERROR"))
        if event["type"] == expected:
            return event


def run(args: argparse.Namespace) -> dict[str, Any]:
    result: dict[str, Any] = {
        "schema": "R3R4R6R2R2_CONTROLLER_RESULT_V1", "task": TASK,
        "result": "FAIL", "blocker": None, "events": [],
        "primary_records": PRIMARY_RECORDS, "primary_requested_bytes": PRIMARY_BYTES,
        "aio_request_bytes": RECORD_BYTES, "parent_owned_mmio": True,
        "raw_payload_control_ipc": False, "unauthorized_mmio_writes": 0,
    }
    mmio: Mmio | None = None
    process: subprocess.Popen[str] | None = None
    selector: selectors.BaseSelector | None = None
    stream_enabled = False
    parent_quiescent = False
    timeline: list[dict[str, Any]] = []
    quiescence_rows: list[dict[str, Any]] = []
    normal_disabled = False
    try:
        lock_receipt = Path(args.linux_lock) / "receipt.json"
        require(lock_receipt.is_file(), "R3R4R6R2R2_LINUX_TASK_LOCK_NOT_HELD")
        lock = json.loads(lock_receipt.read_text(encoding="utf-8"))
        require(lock.get("task") == TASK and lock.get("state") == "HELD",
                "R3R4R6R2R2_LINUX_TASK_LOCK_RECEIPT_INVALID")
        require(Path(args.user_node).is_char_device(),
                "R3R4R6R2R2_DRIVER_OR_NODE_OPERATION_FAILED:USER_NODE")
        require(Path(args.c2h_node).is_char_device(),
                "R3R4R6R2R2_DRIVER_OR_NODE_OPERATION_FAILED:C2H_NODE")
        require(Path(args.native_helper).is_file(),
                "R3R4R6R2R2_NATIVE_HELPER_MISSING")
        Path(args.private_dir).mkdir(parents=True, exist_ok=True, mode=0o700)
        Path(args.logs_dir).mkdir(parents=True, exist_ok=True, mode=0o700)

        mmio = Mmio(args.user_node)
        result["source_readiness"] = source_readiness(mmio)
        control = mmio.read(0x380C, "S0")
        status = mmio.read(0x3810, "S0")
        require(hardware_quiescent(control, status),
                "R3R4R6R2R2_S0_NOT_PHYSICALLY_QUIESCENT")
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
                    "R3R4R6R2R2_RESET_STREAM_STATE_TIMEOUT")
            time.sleep(0.001)
        s1 = mmio.checkpoint("S1")
        timeline.append(s1)
        result["S1"] = s1
        require(s1["Epoch"] == ((s0["Epoch"] + 1) & 0xFFFFFFFF),
                "R3R4R6R2R2_RESET_EPOCH_TRANSITION_FAILED")

        normalization = mmio.read(0x383C, "S1_W1C_READ") & 0x3F
        result["session_normalization_w1c_mask"] = normalization
        if normalization:
            mmio.write(0x383C, normalization, "SESSION_NORMALIZATION_W1C",
                       "POST_RESET_QUIESCENT")
        post_error = mmio.read(0x383C, "S2")
        require((post_error & 0x3F) == 0,
                "R3R4R6R2R2_SESSION_NORMALIZATION_DID_NOT_CLEAR")
        s2_epoch = mmio.read(0x3838, "S2")
        s2_cause = mmio.read(0x3840, "S2")
        baseline = mmio.snapshot("BASELINE_PRE_ENABLE")
        s2 = {
            "Checkpoint": "S2", "Epoch": s2_epoch,
            "ErrorStatus": post_error, "LastErrorCause": s2_cause,
            "Attempted": baseline["attempted"], "Committed": baseline["committed"],
            "Streamed": baseline["streamed"], "Dropped": baseline["dropped"],
            "Overflow": baseline["overflow"],
            "Discontinuity": baseline["discontinuity"], "Timestamp": time.time_ns(),
        }
        timeline.append(s2)
        result["S2"] = s2
        result["baseline_snapshot"] = baseline

        process = subprocess.Popen(
            [args.native_helper, args.c2h_node, args.private_dir],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, bufsize=1, close_fds=True)
        selector = selectors.DefaultSelector()
        require(process.stdout is not None, "R3R4R6R2R2_NATIVE_STDOUT_PIPE_MISSING")
        selector.register(process.stdout, selectors.EVENT_READ)
        prequeue = wait_event(process, selector, "PREQUEUE_READY",
                              time.monotonic() + 20.0, result["events"])
        require(prequeue.get("request_count") == PRIMARY_RECORDS and
                prequeue.get("submitted_requests") == PRIMARY_RECORDS and
                prequeue.get("request_bytes") == RECORD_BYTES and
                prequeue.get("primary_bytes") == PRIMARY_BYTES and
                prequeue.get("pending") == PRIMARY_RECORDS and
                prequeue.get("alignment_remainder") == 0,
                "R3R4R6R2R2_PREQUEUE_READY_CONTRACT_FAILED")
        result["prequeue_ready"] = prequeue

        enable_ns = mmio.write(0x380C, 1, "STREAM_ENABLE", "PREQUEUE_READY")
        stream_enabled = True
        result["prequeue_ready_to_enable_latency_us"] = round(
            (enable_ns - int(prequeue["monotonic_ns"])) / 1000.0, 3)
        primary = wait_event(process, selector, "PRIMARY_WINDOW_COMPLETE",
                             time.monotonic() + 30.0, result["events"])
        result["primary_completion"] = primary
        require(primary.get("exact_completions") == PRIMARY_RECORDS and
                primary.get("short_completions") == 0 and
                primary.get("failed_completions") == 0 and
                primary.get("pending") == 0 and
                primary.get("primary_bytes") == PRIMARY_BYTES,
                "R3R4R6R2R2_4K_PRIMARY_WINDOW_INCOMPLETE")

        disable_ns = mmio.write(0x380C, 0, "NORMAL_DISABLE",
                                "PRIMARY_WINDOW_COMPLETE")
        normal_disabled = True
        stream_enabled = False
        result["primary_complete_to_disable_us"] = round(
            (disable_ns - int(primary["monotonic_ns"])) / 1000.0, 3)
        result["pending_aio_at_disable"] = primary["pending"]

        parent_quiescent, quiescence_rows = prove_quiescence(mmio, "POST_DISABLE")
        require(parent_quiescent, "R3R4R6R2R2_PHYSICAL_QUIESCENCE_NOT_PROVEN")
        result["physical_quiescence"] = {
            "result": "PASS", "total_samples": len(quiescence_rows),
            "accepted_samples": quiescence_rows[-1]["Consecutive"],
            "span_ms": quiescence_rows[-1]["SpanMs"],
        }
        require(process.stdin is not None, "R3R4R6R2R2_NATIVE_STDIN_PIPE_MISSING")
        process.stdin.write("PARENT_QUIESCENT\n")
        process.stdin.flush()
        process.stdin.close()

        s3_epoch = mmio.read(0x3838, "S3")
        s3_error = mmio.read(0x383C, "S3")
        s3_cause = mmio.read(0x3840, "S3")
        final = mmio.snapshot("FINAL_POST_QUIESCENCE")
        s3 = {
            "Checkpoint": "S3", "Epoch": s3_epoch,
            "ErrorStatus": s3_error, "LastErrorCause": s3_cause,
            "Attempted": final["attempted"], "Committed": final["committed"],
            "Streamed": final["streamed"], "Dropped": final["dropped"],
            "Overflow": final["overflow"],
            "Discontinuity": final["discontinuity"], "Timestamp": time.time_ns(),
        }
        timeline.append(s3)
        result["S3"] = s3
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

        exit_seen = False
        persistence_seen = False
        native_deadline = time.monotonic() + 30.0
        while not exit_seen:
            event = read_event(process, selector, native_deadline)
            result["events"].append(event)
            if event["type"] == "ERROR":
                raise GateError(str(event.get("blocker") or
                                    "R3R4R6R2R2_NATIVE_POST_CAPTURE_ERROR"))
            persistence_seen |= event["type"] == "PRIMARY_PERSISTENCE_COMPLETE"
            exit_seen |= event["type"] == "HELPER_EXIT_READY"
        process.wait(timeout=max(0.1, native_deadline - time.monotonic()))
        stderr = process.stderr.read() if process.stderr else ""
        result["native_helper_exit_code"] = process.returncode
        result["native_helper_stderr"] = stderr
        require(process.returncode == 0 and not stderr.strip() and persistence_seen,
                "R3R4R6R2R2_NATIVE_HELPER_FINALIZATION_FAILED")
        primary_path = Path(args.private_dir) / "primary.bin"
        require(primary_path.is_file() and primary_path.stat().st_size == PRIMARY_BYTES,
                "R3R4R6R2R2_PRIMARY_FILE_SIZE_INVALID")
        result["primary_file"] = str(primary_path)
        result["primary_file_bytes"] = primary_path.stat().st_size
        result["result"] = "PASS"
        result["blocker"] = None
        return result
    except BaseException as exc:
        result["result"] = "FAIL"
        result["blocker"] = str(exc).strip() or type(exc).__name__
        result["exception_type"] = type(exc).__name__
        result["traceback"] = traceback.format_exc()
        if mmio is not None and stream_enabled:
            try:
                mmio.write(0x380C, 0, "SAFETY_DISABLE",
                           "POST_ENABLE_EXCEPTION_STREAM_ACTIVE")
                stream_enabled = False
                parent_quiescent, rows = prove_quiescence(mmio, "FAILURE_PATH")
                quiescence_rows.extend(rows)
                result["failure_path_quiescence"] = "PASS" if parent_quiescent else "FAIL"
            except BaseException as cleanup_error:
                result["failure_path_quiescence"] = "FAIL"
                result["failure_path_quiescence_detail"] = str(cleanup_error)
        if (process is not None and process.poll() is None and parent_quiescent and
                process.stdin is not None and not process.stdin.closed):
            try:
                process.stdin.write("PARENT_QUIESCENT\n")
                process.stdin.flush()
                process.stdin.close()
                process.wait(timeout=15.0)
            except BaseException as wait_error:
                result["native_failure_wait"] = str(wait_error)
        if process is not None:
            result["native_helper_exit_code"] = process.poll()
        return result
    finally:
        if selector is not None:
            selector.close()
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
            logs = Path(args.logs_dir)
            if not (logs / "mmio-write-ledger.csv").exists():
                write_csv(logs / "mmio-write-ledger.csv",
                          ["Timestamp", "Operation", "Offset", "Value", "Purpose",
                           "Precondition", "Authorized", "Result",
                           "CompletionMonotonicNs"], mmio.ledger)
            if not (logs / "mmio-raw.csv").exists():
                write_csv(logs / "mmio-raw.csv",
                          ["Timestamp", "Label", "Operation", "Offset", "Value",
                           "Result"], mmio.raw_rows)
        logs = Path(args.logs_dir)
        if timeline and not (logs / "error-timeline.csv").exists():
            write_csv(logs / "error-timeline.csv",
                      ["Checkpoint", "Epoch", "ErrorStatus", "LastErrorCause",
                       "Attempted", "Committed", "Streamed", "Dropped", "Overflow",
                       "Discontinuity", "Timestamp"], timeline)
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
        "exact_completions": result.get("primary_completion", {}).get(
            "exact_completions"),
        "primary_bytes": result.get("primary_completion", {}).get("primary_bytes"),
        "prequeue_ready_to_enable_latency_us": result.get(
            "prequeue_ready_to_enable_latency_us"),
        "primary_complete_to_disable_us": result.get(
            "primary_complete_to_disable_us"),
    }, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
