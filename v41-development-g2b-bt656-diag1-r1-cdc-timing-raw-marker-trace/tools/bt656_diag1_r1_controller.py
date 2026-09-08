#!/usr/bin/env python3
"""One-shot parent-owned MMIO controller for BT656 DIAG1-R1 trace capture."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import selectors
import struct
import subprocess
import time
import traceback
from typing import Any


TASK = "G2B-BT656-DIAG1-R1"
TRACE_MAGIC = 0x42543635
TRACE_VERSION = 0x00010000
TRACE_DONE_LIMIT_SECONDS = 0.150
TRACE_POLL_SECONDS = 0.000100
DONE_TO_DISABLE_LIMIT_US = 500.0
BUFFER_COUNT = 1024
READ_RANGES = ((0x0000, 0x0030), (0x0080, 0x00B4),
               (0x3800, 0x3858), (0x3C00, 0x3FFF))
COUNTER_OFFSETS = {
    "attempted": 0x3814, "committed": 0x3818, "streamed": 0x381C,
    "dropped": 0x3820, "overflow": 0x3824,
    "discontinuity": 0x3828, "beats_low": 0x382C,
    "beats_high": 0x3830, "last_global": 0x3834,
    "abandoned": 0x3850, "reset_events": 0x3854,
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
            writer.writerow({name: row.get(name, "") for name in fields})
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
        self.raw: list[dict[str, Any]] = []
        self.ledger: list[dict[str, Any]] = []
        self.last_error_read: int | None = None
        self.trace_read_pass = 0
        self.trace_read_next = 0

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def read(self, offset: int, label: str) -> int:
        require(offset % 4 == 0 and any(lo <= offset <= hi for lo, hi in READ_RANGES),
                "BT656_DIAG1_R1_MMIO_READ_ALLOWLIST_VIOLATION")
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, "BT656_DIAG1_R1_SHORT_MMIO_READ")
        value = struct.unpack("<I", raw)[0]
        if offset == 0x383C:
            self.last_error_read = value
        self.raw.append({"Timestamp": time.time_ns(), "Label": label,
                         "Operation": "READ", "Offset": f"0x{offset:04X}",
                         "Value": f"0x{value:08X}", "Result": "PASS"})
        return value

    def begin_trace_read_pass(self, pass_number: int) -> None:
        require(pass_number in (1, 2), "BT656_DIAG1_R1_TRACE_READ_PASS_INVALID")
        self.trace_read_pass = pass_number
        self.trace_read_next = 0

    def write(self, offset: int, value: int, purpose: str,
              precondition: str) -> int:
        intents = [row for row in self.ledger if row["Result"] == "INTENT"]
        count = lambda name: sum(row["Purpose"] == name for row in intents)
        if (offset, value, purpose) == (0x380C, 4, "RESET_STREAM_STATE"):
            require(count(purpose) == 0, "BT656_DIAG1_R1_RESET_WRITE_BUDGET")
        elif (offset, value, purpose) == (0x380C, 1, "STREAM_ENABLE"):
            require(count(purpose) == 0, "BT656_DIAG1_R1_ENABLE_WRITE_BUDGET")
        elif (offset, value, purpose) == (0x380C, 0, "NORMAL_DISABLE"):
            require(count(purpose) == 0, "BT656_DIAG1_R1_DISABLE_WRITE_BUDGET")
        elif (offset, value, purpose) == (0x380C, 0, "SAFETY_DISABLE"):
            require(count("STREAM_ENABLE") == 1 and count(purpose) == 0,
                    "BT656_DIAG1_R1_SAFETY_DISABLE_PRECONDITION")
        elif (offset, value, purpose) == (0x3844, 1, "COHERENT_SNAPSHOT"):
            require(count(purpose) < 3, "BT656_DIAG1_R1_SNAPSHOT_BUDGET")
        elif offset == 0x383C and purpose == "SESSION_NORMALIZATION_W1C":
            require(count(purpose) == 0 and self.last_error_read is not None and
                    value != 0 and value == (self.last_error_read & 0x3F),
                    "BT656_DIAG1_R1_W1C_NOT_IMMEDIATE_EXACT_MASK")
        elif (offset, value, purpose) == (0x3C0C, 1, "TRACE_CLEAR"):
            require(count(purpose) == 0, "BT656_DIAG1_R1_TRACE_CLEAR_BUDGET")
        elif (offset, value, purpose) == (0x3C0C, 2, "TRACE_ARM"):
            require(count(purpose) == 0, "BT656_DIAG1_R1_TRACE_ARM_BUDGET")
        elif (offset, value, purpose) == (0x3C0C, 4, "TRACE_ABORT_AND_FREEZE"):
            require(count(purpose) == 0 and precondition == "TRACE_TIMEOUT_OR_FAILURE",
                    "BT656_DIAG1_R1_TRACE_ABORT_PRECONDITION")
        elif offset == 0x3C38 and purpose == "TRACE_READ_INDEX":
            require(self.trace_read_pass in (1, 2) and value == self.trace_read_next,
                    "BT656_DIAG1_R1_TRACE_READ_INDEX_NOT_SEQUENTIAL")
            self.trace_read_next += 1
        else:
            raise GateError("BT656_DIAG1_R1_MMIO_WRITE_ALLOWLIST_VIOLATION")
        started = time.time_ns()
        base = {"Timestamp": started, "Operation": "WRITE",
                "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
                "Purpose": purpose, "Precondition": precondition,
                "Authorized": "YES", "TraceReadPass": self.trace_read_pass}
        self.ledger.append({**base, "Result": "INTENT"})
        written = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(written == 4, "BT656_DIAG1_R1_SHORT_MMIO_WRITE")
        completed = time.monotonic_ns()
        self.ledger.append({**base, "Result": "PASS",
                            "CompletionMonotonicNs": completed})
        self.raw.append({"Timestamp": started, "Label": purpose,
                         "Operation": "WRITE", "Offset": f"0x{offset:04X}",
                         "Value": f"0x{value:08X}", "Result": "PASS"})
        return completed

    def record_fast_disable(self, observation_ns: int, completion_ns: int) -> None:
        base = {"Timestamp": time.time_ns(), "Operation": "WRITE",
                "Offset": "0x380C", "Value": "0x00000000",
                "Purpose": "NORMAL_DISABLE", "Precondition": "TRACE_DONE_VISIBLE",
                "Authorized": "YES", "TraceReadPass": self.trace_read_pass}
        self.ledger.append({**base, "Result": "INTENT",
                            "DoneObservationMonotonicNs": observation_ns})
        self.ledger.append({**base, "Result": "PASS",
                            "CompletionMonotonicNs": completion_ns,
                            "DoneObservationMonotonicNs": observation_ns})
        self.raw.append({"Timestamp": base["Timestamp"], "Label": "NORMAL_DISABLE",
                         "Operation": "WRITE", "Offset": "0x380C",
                         "Value": "0x00000000", "Result": "PASS"})

    def counters(self, label: str) -> dict[str, int]:
        values = {name: self.read(offset, label)
                  for name, offset in COUNTER_OFFSETS.items()}
        values["beats"] = values["beats_low"] | (values["beats_high"] << 32)
        return values

    def checkpoint(self, name: str) -> dict[str, Any]:
        counters = self.counters(name)
        return {"Checkpoint": name, "Epoch": self.read(0x3838, name),
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
                "Timestamp": time.time_ns()}

    def snapshot(self, label: str) -> dict[str, Any]:
        epoch = self.read(0x3838, label)
        generation = self.read(0x384C, label)
        require((self.read(0x3810, label) & 0x300) == 0,
                "BT656_DIAG1_R1_SNAPSHOT_BUSY")
        self.write(0x3844, 1, "COHERENT_SNAPSHOT", label)
        expected = (generation + 1) & 0xFFFFFFFF
        deadline = time.monotonic() + 2.0
        while True:
            state = self.read(0x3848, label) & 3
            observed = self.read(0x384C, label)
            if state == 2 and observed == expected:
                break
            require(time.monotonic() < deadline,
                    "BT656_DIAG1_R1_COHERENT_SNAPSHOT_TIMEOUT")
            time.sleep(0.001)
        counters = self.counters(label)
        require(self.read(0x3838, label) == epoch,
                "BT656_DIAG1_R1_SNAPSHOT_EPOCH_CHANGED")
        return {"label": label, "epoch": epoch, "generation": expected, **counters}


def hardware_quiescent(control: int, status: int) -> bool:
    return control == 0 and (status & 0x10F) == 0x004


def prove_quiescence(mmio: Mmio, label: str) -> tuple[bool, list[dict[str, Any]]]:
    deadline = time.monotonic() + 10.0
    rows: list[dict[str, Any]] = []
    consecutive = 0
    first: float | None = None
    while time.monotonic() < deadline:
        started = time.monotonic()
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
        rows.append({"Timestamp": time.time_ns(), "Label": label,
                     "Sample": len(rows) + 1, "Control": f"0x{control:08X}",
                     "Status": f"0x{status:08X}", "Accepted": accepted,
                     "Consecutive": consecutive, "SpanMs": round(span * 1000, 3)})
        if consecutive >= 5 and span >= 0.400:
            return True, rows
        remainder = 0.100 - (time.monotonic() - started)
        if remainder > 0:
            time.sleep(remainder)
    return False, rows


def source_readiness(mmio: Mmio) -> dict[str, Any]:
    require(mmio.read(0x3800, "READINESS") == 0x43324831,
            "BT656_DIAG1_R1_G2B_C2H_MAGIC_ABSENT")
    require(mmio.read(0x3804, "READINESS") == 0x00010000,
            "BT656_DIAG1_R1_TRANSPORT_ABI_VERSION_NOT_1")
    require(mmio.read(0x3C00, "TRACE_IDENTITY") == TRACE_MAGIC,
            "BT656_DIAG1_R1_TRACE_MAGIC_MISMATCH")
    require(mmio.read(0x3C04, "TRACE_IDENTITY") == TRACE_VERSION,
            "BT656_DIAG1_R1_TRACE_VERSION_MISMATCH")
    capabilities = mmio.read(0x3C08, "TRACE_IDENTITY")
    before = {offset: mmio.read(offset, "READINESS_BEFORE")
              for offset in range(0x80, 0xB8, 4)}
    deadline = time.monotonic() + 30.0
    last: dict[str, Any] = {}
    while time.monotonic() < deadline:
        started = time.monotonic()
        time.sleep(3.0)
        after = {offset: mmio.read(offset, "READINESS_AFTER")
                 for offset in range(0x80, 0xB8, 4)}
        elapsed = time.monotonic() - started
        vclk = (after[0x80] - before[0x80]) & 0xFFFFFFFF
        sav = (after[0x84] - before[0x84]) & 0xFFFFFFFF
        ratio = vclk / max(1, sav)
        sav_rate = sav / elapsed
        status = mmio.read(0x3810, "READINESS_STATUS")
        last = {"vclk_delta": vclk, "sav_delta": sav,
                "vclk_per_sav": ratio, "sav_per_second": sav_rate,
                "g2b_status": status,
                "nvp_values": {f"0x{k:04X}": v for k, v in after.items()}}
        ready = ((after[0x8C] & 0x3F) == 0x39 and after[0x90] == 0 and
                 after[0x94] == 0 and not (after[0x9C] & 0x80000000) and
                 5200 <= ratio <= 5360 and 20000 <= sav_rate <= 35000 and
                 (status & 0xC0) == 0xC0 and not (status & 0x800))
        if ready:
            return {"result": "PASS", "trace_magic": TRACE_MAGIC,
                    "trace_version": TRACE_VERSION,
                    "trace_capabilities": capabilities,
                    "nack_count": 0, "init_error": 0,
                    "physical_input": 0, "source_ready": True,
                    "source_locked": True, **last}
        before = after
    raise GateError("BT656_DIAG1_R1_LIVE_SOURCE_NOT_READY:" +
                    json.dumps(last, sort_keys=True))


class EventReader:
    def __init__(self, process: subprocess.Popen[bytes]) -> None:
        require(process.stdout is not None, "BT656_DIAG1_R1_DRAIN_STDOUT_MISSING")
        self.process = process
        self.fd = process.stdout.fileno()
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.fd, selectors.EVENT_READ)
        self.buffer = bytearray()

    def close(self) -> None:
        self.selector.close()

    def read(self, deadline: float) -> dict[str, Any]:
        while time.monotonic() < deadline:
            line = self.buffer.find(b"\n")
            if line >= 0:
                raw = bytes(self.buffer[:line])
                del self.buffer[:line + 1]
                require(bool(raw), "BT656_DIAG1_R1_EMPTY_DRAIN_EVENT")
                try:
                    event = json.loads(raw.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                    raise GateError("BT656_DIAG1_R1_DRAIN_EVENT_INVALID") from exc
                require(isinstance(event, dict) and isinstance(event.get("type"), str),
                        "BT656_DIAG1_R1_DRAIN_EVENT_SCHEMA")
                require(all(isinstance(v, (str, int, float, bool, type(None)))
                            for v in event.values()),
                        "BT656_DIAG1_R1_DRAIN_EVENT_NOT_METADATA_ONLY")
                return event
            ready = self.selector.select(min(0.05, max(0.0, deadline - time.monotonic())))
            if ready:
                data = os.read(self.fd, 65536)
                if data:
                    self.buffer.extend(data)
                    continue
            if self.process.poll() is not None and not self.buffer:
                raise GateError("BT656_DIAG1_R1_DRAIN_EXITED_EARLY")
        raise GateError("BT656_DIAG1_R1_DRAIN_EVENT_TIMEOUT")


def read_trace(mmio: Mmio, valid_entries: int, pass_number: int) -> list[list[int]]:
    mmio.begin_trace_read_pass(pass_number)
    entries: list[list[int]] = []
    for index in range(valid_entries):
        mmio.write(0x3C38, index, "TRACE_READ_INDEX", "TRACE_FROZEN")
        deadline = time.monotonic() + 0.100
        while True:
            state = mmio.read(0x3C3C, f"TRACE_READ_P{pass_number}_{index}")
            if (state & 1) and ((state >> 1) & 0x1FF) == index:
                break
            require(time.monotonic() < deadline,
                    "BT656_DIAG1_R1_TRACE_READ_DATA_VALID_TIMEOUT")
        entries.append([mmio.read(0x3C40 + word * 4,
                                  f"TRACE_P{pass_number}_E{index}_W{word}")
                        for word in range(16)])
    return entries


def run(args: argparse.Namespace) -> dict[str, Any]:
    result: dict[str, Any] = {"task": TASK, "result": "FAIL", "blocker": None,
                              "events": [], "raw_payload_control_ipc": False,
                              "active_video_payload_persisted": False,
                              "trace_done_to_disable_limit_us": DONE_TO_DISABLE_LIMIT_US}
    mmio: Mmio | None = None
    helper: subprocess.Popen[bytes] | None = None
    reader: EventReader | None = None
    stream_enabled = False
    normal_disable = False
    parent_quiescent = False
    stop_sent = False
    parent_sent = False
    trace_frozen = False
    timeline: list[dict[str, Any]] = []
    samples: list[dict[str, Any]] = []
    quiescence_rows: list[dict[str, Any]] = []
    logs = Path(args.logs_dir)
    artifacts = Path(args.artifacts_dir)
    try:
        require(Path(args.linux_lock, "receipt.json").is_file(),
                "BT656_DIAG1_R1_LINUX_LOCK_NOT_HELD")
        require(Path(args.user_node).is_char_device(),
                "BT656_DIAG1_R1_USER_NODE_MISSING")
        require(Path(args.c2h_node).is_char_device(),
                "BT656_DIAG1_R1_C2H_NODE_MISSING")
        require(Path(args.drain_helper).is_file(),
                "BT656_DIAG1_R1_DRAIN_HELPER_MISSING")
        logs.mkdir(parents=True, exist_ok=True, mode=0o700)
        artifacts.mkdir(parents=True, exist_ok=True, mode=0o700)
        mmio = Mmio(args.user_node)
        result["runtime_identity"] = source_readiness(mmio)
        control = mmio.read(0x380C, "S0")
        status = mmio.read(0x3810, "S0")
        require(hardware_quiescent(control, status),
                "BT656_DIAG1_R1_S0_NOT_QUIESCENT")
        s0 = mmio.checkpoint("S0")
        timeline.append(s0); result["S0"] = s0

        mmio.write(0x380C, 4, "RESET_STREAM_STATE", "S0_QUIESCENT")
        deadline = time.monotonic() + 5.0
        while True:
            control = mmio.read(0x380C, "RESET_WAIT")
            status = mmio.read(0x3810, "RESET_WAIT")
            if hardware_quiescent(control, status):
                break
            require(time.monotonic() < deadline,
                    "BT656_DIAG1_R1_RESET_STREAM_STATE_TIMEOUT")
            time.sleep(0.001)
        s1 = mmio.checkpoint("S1")
        timeline.append(s1); result["S1"] = s1
        require(s1["Epoch"] == ((s0["Epoch"] + 1) & 0xFFFFFFFF),
                "BT656_DIAG1_R1_RESET_EPOCH_TRANSITION_FAILED")
        mask = mmio.read(0x383C, "S1_W1C_READ") & 0x3F
        result["session_normalization_w1c"] = mask
        if mask:
            mmio.write(0x383C, mask, "SESSION_NORMALIZATION_W1C",
                       "POST_RESET_QUIESCENT")
        require((mmio.read(0x383C, "S2") & 0x3F) == 0,
                "BT656_DIAG1_R1_SESSION_NORMALIZATION_DID_NOT_CLEAR")
        baseline = mmio.snapshot("S2_BASELINE")
        s2 = mmio.checkpoint("S2")
        timeline.append(s2); result["S2"] = s2
        result["baseline_snapshot"] = baseline

        mmio.write(0x3C0C, 1, "TRACE_CLEAR", "POST_RESET_QUIESCENT")
        deadline = time.monotonic() + 0.100
        while True:
            trace_status = mmio.read(0x3C10, "TRACE_CLEAR_WAIT")
            valid = mmio.read(0x3C14, "TRACE_CLEAR_WAIT")
            if (trace_status & 0x7) == 0 and valid == 0:
                break
            require(time.monotonic() < deadline,
                    "BT656_DIAG1_R1_TRACE_CLEAR_ACK_TIMEOUT")
        mmio.write(0x3C0C, 2, "TRACE_ARM", "TRACE_CLEAR_ACKNOWLEDGED")
        deadline = time.monotonic() + 0.100
        while True:
            trace_status = mmio.read(0x3C10, "TRACE_ARM_WAIT")
            if (trace_status & 1) and not (trace_status & 4):
                break
            require(time.monotonic() < deadline,
                    "BT656_DIAG1_R1_TRACE_ARM_TIMEOUT")

        helper = subprocess.Popen([args.drain_helper, args.c2h_node],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, bufsize=0, close_fds=True)
        reader = EventReader(helper)
        prequeue = reader.read(time.monotonic() + 15.0)
        result["events"].append(prequeue)
        require(prequeue.get("type") == "DRAIN_PREQUEUE_READY" and
                prequeue.get("record_bytes") == 4096 and
                prequeue.get("buffer_count") == BUFFER_COUNT and
                prequeue.get("initial_submitted") == BUFFER_COUNT and
                prequeue.get("current_outstanding") == BUFFER_COUNT and
                prequeue.get("maximum_outstanding") == BUFFER_COUNT and
                prequeue.get("alignment_remainder") == 0 and
                prequeue.get("prefaulted") is True,
                "BT656_DIAG1_R1_DRAIN_PREQUEUE_CONTRACT_FAILED")

        enable_ns = mmio.write(0x380C, 1, "STREAM_ENABLE", "DRAIN_PREQUEUE_READY")
        stream_enabled = True
        result["prequeue_ready_to_enable_us"] = round(
            (enable_ns - int(prequeue["monotonic_ns"])) / 1000.0, 3)

        poll_start = time.monotonic()
        done_observed_ns: int | None = None
        timeout = False
        while True:
            raw = os.pread(mmio.fd, 4, 0x3C10)
            require(len(raw) == 4, "BT656_DIAG1_R1_TRACE_STATUS_SHORT_READ")
            value = struct.unpack("<I", raw)[0]
            now_ns = time.monotonic_ns()
            samples.append({"MonotonicNs": now_ns, "Status": f"0x{value:08X}"})
            if value & 4:
                done_observed_ns = now_ns
                trace_frozen = True
                break
            if time.monotonic() - poll_start >= TRACE_DONE_LIMIT_SECONDS:
                timeout = True
                break
            time.sleep(TRACE_POLL_SECONDS)

        if timeout:
            mmio.write(0x380C, 0, "SAFETY_DISABLE",
                       "TRACE_TIMEOUT_STREAM_ENABLED")
            stream_enabled = False
            mmio.write(0x3C0C, 4, "TRACE_ABORT_AND_FREEZE",
                       "TRACE_TIMEOUT_OR_FAILURE")
            trace_frozen = True
            require(helper.stdin is not None, "BT656_DIAG1_R1_DRAIN_STDIN_MISSING")
            helper.stdin.write(b"STOP_RESUBMIT\n"); helper.stdin.flush(); stop_sent = True
            raise GateError("BT656_DIAG1_R1_TRACE_DID_NOT_COMPLETE_IN_BOUND")

        require(done_observed_ns is not None, "BT656_DIAG1_R1_TRACE_DONE_NOT_OBSERVED")
        written = os.pwrite(mmio.fd, struct.pack("<I", 0), 0x380C)
        disable_ns = time.monotonic_ns()
        require(written == 4, "BT656_DIAG1_R1_FAST_DISABLE_SHORT_WRITE")
        stream_enabled = False
        normal_disable = True
        mmio.record_fast_disable(done_observed_ns, disable_ns)
        result["trace_done_observed_ns"] = done_observed_ns
        result["normal_disable_completion_ns"] = disable_ns
        result["trace_done_to_disable_us"] = round(
            (disable_ns - done_observed_ns) / 1000.0, 3)
        require(result["trace_done_to_disable_us"] <= DONE_TO_DISABLE_LIMIT_US,
                "BT656_DIAG1_R1_TRACE_DONE_TO_DISABLE_LATENCY_EXCEEDED")
        require(helper.stdin is not None, "BT656_DIAG1_R1_DRAIN_STDIN_MISSING")
        helper.stdin.write(b"STOP_RESUBMIT\n"); helper.stdin.flush(); stop_sent = True

        # Durable evidence begins only after the stream-disable MMIO completion.
        sp = mmio.checkpoint("SP")
        timeline.append(sp); result["SP"] = sp
        parent_quiescent, quiescence_rows = prove_quiescence(mmio, "POST_DISABLE")
        require(parent_quiescent, "BT656_DIAG1_R1_PHYSICAL_QUIESCENCE_NOT_PROVEN")
        helper.stdin.write(b"PARENT_QUIESCENT\n"); helper.stdin.flush()
        helper.stdin.close(); parent_sent = True

        final_event = None
        helper_deadline = time.monotonic() + 15.0
        while final_event is None:
            event = reader.read(helper_deadline)
            result["events"].append(event)
            if event["type"] == "ERROR":
                raise GateError(str(event.get("blocker") or
                                    "BT656_DIAG1_R1_DRAIN_ERROR"))
            if event["type"] == "DRAIN_FINAL":
                final_event = event
        helper.wait(timeout=max(0.1, helper_deadline - time.monotonic()))
        stderr = helper.stderr.read().decode("utf-8", errors="replace") if helper.stderr else ""
        result["drain_final"] = final_event
        result["drain_helper_exit_code"] = helper.returncode
        result["drain_helper_stderr"] = stderr
        require(helper.returncode == 0 and not stderr.strip() and
                final_event.get("result") == "PASS" and
                final_event.get("final_pending") == 0 and
                final_event.get("maximum_outstanding", BUFFER_COUNT + 1) <= BUFFER_COUNT and
                final_event.get("buffer_reuse_violations") == 0 and
                final_event.get("descriptor_window_violations") == 0 and
                final_event.get("short_completions") == 0 and
                final_event.get("failed_completions") == 0 and
                final_event.get("stop_resubmit_seen") is True and
                final_event.get("parent_quiescent_seen") is True,
                "BT656_DIAG1_R1_DRAIN_FINAL_CONTRACT_FAILED")

        s3 = mmio.checkpoint("S3")
        timeline.append(s3); result["S3"] = s3
        final_snapshot = mmio.snapshot("S3_FINAL")
        result["final_snapshot"] = final_snapshot
        result["counter_deltas"] = {
            "attempted": delta32(final_snapshot["attempted"], baseline["attempted"]),
            "committed": delta32(final_snapshot["committed"], baseline["committed"]),
            "streamed": delta32(final_snapshot["streamed"], baseline["streamed"]),
            "dropped": delta32(final_snapshot["dropped"], baseline["dropped"]),
            "overflow": delta32(final_snapshot["overflow"], baseline["overflow"]),
            "discontinuity": delta32(final_snapshot["discontinuity"],
                                     baseline["discontinuity"]),
            "abandoned": delta32(final_snapshot["abandoned"], baseline["abandoned"]),
            "beats": delta64(final_snapshot["beats"], baseline["beats"]),
            "last_global": final_snapshot["last_global"],
            "last_attempt": final_snapshot["last_attempt"],
        }
        trace_status = mmio.read(0x3C10, "TRACE_METADATA")
        require((trace_status & 4) and not (trace_status & 8),
                "BT656_DIAG1_R1_TRACE_DONE_OR_OVERFLOW_INVALID")
        trace_meta = {"status": trace_status,
                      "valid_entries": mmio.read(0x3C14, "TRACE_METADATA"),
                      "pretrigger_entries": mmio.read(0x3C18, "TRACE_METADATA"),
                      "posttrigger_entries": mmio.read(0x3C1C, "TRACE_METADATA"),
                      "trigger_logical_index": mmio.read(0x3C20, "TRACE_METADATA"),
                      "stop_reason": mmio.read(0x3C24, "TRACE_METADATA"),
                      "trigger_frame": mmio.read(0x3C28, "TRACE_METADATA"),
                      "trigger_line": mmio.read(0x3C2C, "TRACE_METADATA"),
                      "clocks_since_trigger": (mmio.read(0x3C30, "TRACE_METADATA") |
                                               (mmio.read(0x3C34, "TRACE_METADATA") << 32))}
        require(0 < trace_meta["valid_entries"] <= 511,
                "BT656_DIAG1_R1_TRACE_VALID_ENTRY_COUNT_INVALID")
        first = read_trace(mmio, trace_meta["valid_entries"], 1)
        second = read_trace(mmio, trace_meta["valid_entries"], 2)
        require(first == second, "BT656_DIAG1_R1_TRACE_DOUBLE_READ_MISMATCH")
        result["trace_metadata"] = trace_meta
        result["trace_double_read_agreement"] = "PASS"
        result["trace_overflow"] = 0
        result["trace_sha256"] = hashlib.sha256(
            b"".join(struct.pack("<16I", *entry) for entry in first)).hexdigest()

        trace_bin = artifacts / "trace.bin"
        with trace_bin.open("xb") as handle:
            for entry in first:
                handle.write(struct.pack("<16I", *entry))
            handle.flush(); os.fsync(handle.fileno())
        write_json(artifacts / "trace.json", {
            "schema": "G2B_BT656_TRACE_ENTRY_V1", "metadata": trace_meta,
            "entries": [{"logical_index": i,
                         "words": [f"0x{word:08X}" for word in entry]}
                        for i, entry in enumerate(first)]})
        write_csv(artifacts / "trace.csv",
                  ["logical_index"] + [f"word{i}" for i in range(16)],
                  [{"logical_index": i, **{f"word{j}": f"0x{word:08X}"
                                           for j, word in enumerate(entry)}}
                   for i, entry in enumerate(first)])
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
                               "POST_ENABLE_FAILURE_STREAM_ACTIVE")
                    stream_enabled = False
                if not trace_frozen:
                    mmio.write(0x3C0C, 4, "TRACE_ABORT_AND_FREEZE",
                               "TRACE_TIMEOUT_OR_FAILURE")
                    trace_frozen = True
                if helper is not None and helper.poll() is None and helper.stdin is not None:
                    if not stop_sent:
                        helper.stdin.write(b"STOP_RESUBMIT\n"); helper.stdin.flush()
                        stop_sent = True
                if not parent_quiescent:
                    parent_quiescent, rows = prove_quiescence(mmio, "FAILURE_PATH")
                    quiescence_rows.extend(rows)
                if (parent_quiescent and helper is not None and helper.poll() is None and
                        helper.stdin is not None and not helper.stdin.closed and not parent_sent):
                    helper.stdin.write(b"PARENT_QUIESCENT\n"); helper.stdin.flush()
                    helper.stdin.close(); parent_sent = True
            except BaseException as cleanup_exc:
                result["cleanup_error"] = str(cleanup_exc)
        if helper is not None and helper.poll() is None and parent_sent:
            try:
                helper.wait(timeout=15.0)
            except subprocess.TimeoutExpired:
                result["aio_cleanup_unresolved"] = True
        if helper is not None:
            result["drain_helper_exit_code"] = helper.poll()
        return result
    finally:
        if reader is not None:
            reader.close()
        # All output below occurs after disable or on a safely disabled failure path.
        if logs.exists():
            if result["events"] and not (logs / "drain-events.jsonl").exists():
                with (logs / "drain-events.jsonl").open("x", encoding="utf-8") as handle:
                    for event in result["events"]:
                        handle.write(json.dumps(event, sort_keys=True) + "\n")
                    handle.flush(); os.fsync(handle.fileno())
            if samples and not (logs / "trace-status-samples.csv").exists():
                write_csv(logs / "trace-status-samples.csv",
                          ["MonotonicNs", "Status"], samples)
            if quiescence_rows and not (logs / "quiescence-samples.csv").exists():
                write_csv(logs / "quiescence-samples.csv",
                          ["Timestamp", "Label", "Sample", "Control", "Status",
                           "Accepted", "Consecutive", "SpanMs"], quiescence_rows)
            if timeline and not (logs / "error-timeline.csv").exists():
                write_csv(logs / "error-timeline.csv", list(timeline[0].keys()), timeline)
        if mmio is not None:
            intents = [row for row in mmio.ledger if row["Result"] == "INTENT"]
            result["mmio_write_counts"] = {
                purpose: sum(row["Purpose"] == purpose for row in intents)
                for purpose in ("RESET_STREAM_STATE", "STREAM_ENABLE", "NORMAL_DISABLE",
                                "SAFETY_DISABLE", "SESSION_NORMALIZATION_W1C",
                                "COHERENT_SNAPSHOT", "TRACE_CLEAR", "TRACE_ARM",
                                "TRACE_ABORT_AND_FREEZE", "TRACE_READ_INDEX")}
            result["unauthorized_mmio_writes"] = 0
            result["normal_disable_completed"] = normal_disable
            result["physical_quiescence"] = "PASS" if parent_quiescent else "FAIL"
            mmio.close()
            if logs.exists() and mmio.ledger and not (logs / "mmio-write-ledger.csv").exists():
                fields = sorted({key for row in mmio.ledger for key in row})
                write_csv(logs / "mmio-write-ledger.csv", fields, mmio.ledger)
            if logs.exists() and mmio.raw and not (logs / "mmio-raw.csv").exists():
                write_csv(logs / "mmio-raw.csv",
                          ["Timestamp", "Label", "Operation", "Offset", "Value", "Result"],
                          mmio.raw)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", required=True)
    parser.add_argument("--c2h-node", required=True)
    parser.add_argument("--drain-helper", required=True)
    parser.add_argument("--linux-lock", required=True)
    parser.add_argument("--logs-dir", required=True)
    parser.add_argument("--artifacts-dir", required=True)
    args = parser.parse_args()
    result = run(args)
    logs = Path(args.logs_dir)
    logs.mkdir(parents=True, exist_ok=True, mode=0o700)
    if not (logs / "controller-result.json").exists():
        write_json(logs / "controller-result.json", result)
    print(json.dumps({"task": TASK, "result": result["result"],
                      "blocker": result.get("blocker"),
                      "trace_done_to_disable_us": result.get("trace_done_to_disable_us"),
                      "trace_valid_entries": result.get("trace_metadata", {}).get("valid_entries"),
                      "trace_sha256": result.get("trace_sha256")}, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
