#!/usr/bin/env python3
"""AHD v41 G2B-HW0-PRODUCT-R3 one-reader live C2H qualification.

This task-local, standard-library-only tool implements the exact R3 T2-T5
sequence without RESET_STREAM_STATE.  It opens one C2H descriptor once, keeps
one persistent fixed-boundary framer and sequence validator across T3/T4/T5,
and delegates every MMIO access to the fail-closed r3_mmio helper.

It intentionally performs no module, PCI, JTAG, network, reset, error-clear,
statistics-clear, H2C, NVP-control, or FPGA-programming operation.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import errno
import hashlib
import json
import mmap
import os
from pathlib import Path
import re
import shutil
import signal
import stat
import struct
import subprocess
import sys
import threading
import time
from typing import BinaryIO, Callable, Iterable
import zlib


RECORD_BYTES = 4096
HEADER_BYTES = 64
PAYLOAD_BYTES = 3840
PADDING_FIRST = 3904
LINES_PER_FRAME = 1080
PIXELS_PER_LINE = 1920
FRAME_BYTES = PAYLOAD_BYTES * LINES_PER_FRAME
BEATS_PER_RECORD = 512
MAGIC = 0x4C444841
RECORD_VERSION = 0x00004101

FLAG_SOF = 1 << 0
FLAG_DISCONTINUITY = 1 << 2
FLAG_OVERFLOW = 1 << 3
FLAG_MALFORMED_PRECEDING = 1 << 4
FLAG_VALID = 1 << 5
FLAG_WINDOW_END = 1 << 6
ALLOWED_FLAG_MASK = (
    FLAG_SOF | FLAG_DISCONTINUITY | FLAG_OVERFLOW |
    FLAG_MALFORMED_PRECEDING | FLAG_VALID
)

FINITE_RECORDS = 2500
FIRST_RECORD_TIMEOUT_SECONDS = 10.0
FINITE_TIMEOUT_SECONDS = 30.0
DRAIN_TIMEOUT_SECONDS = 10.0
SNAPSHOT_TIMEOUT_SECONDS = 2.0
NVP_SAMPLE_SECONDS = 5.0
WARMUP_SECONDS = 5.0
MEASURE_SECONDS = 60.0
READ_REQUEST_RECORDS = 128
BOUNDARY_FINE_SECONDS = 0.250
BOUNDED_SAMPLE_BYTES = 256
MAX_ANOMALY_RECORDS = 8
MIN_FREE_BYTES_T5 = 1_000_000_000

USER_NODE_RE = re.compile(r"^/dev/xdma([0-9]+)_user$")
C2H_NODE_RE = re.compile(r"^/dev/xdma([0-9]+)_c2h_0$")
BDF_RE = re.compile(r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F]$")
VALUE_RE = re.compile(r"^R3_MMIO_VALUE=0x([0-9A-F]{8})$", re.MULTILINE)

HEADER_NAMES = (
    "magic",
    "record_version",
    "reset_epoch",
    "source_frame_sequence",
    "source_line_sequence",
    "source_capture_sequence",
    "payload_length",
    "flags",
    "active_logical_channel_count",
    "source_slot_generation_and_slot",
    "source_malformed_count_snapshot",
    "source_dropped_count_snapshot",
    "logical_channel_id",
    "physical_input_id",
    "channel_attempt_sequence",
    "global_stream_sequence",
)
HEADER_STRUCT = struct.Struct("<16I")

EXPECTED_LEGACY = {
    0x0000: 0xA40A0C07,
    0x0004: 0x0000400B,
    0x0008: 0x00031002,
    0x000C: 0x00010000,
    0x0010: 0x224D194E,
    0x0014: 0x5F82C85B,
    0x0018: 0xCB292975,
    0x001C: 0x61C5D5E7,
    0x0020: 0x6D28063B,
    0x0024: 0x07E90002,
    0x0028: 6299465,
    0x002C: 0x00000103,
    0x0030: 0x58444D41,
}

SNAPSHOT_OFFSETS = {
    "records_attempted": 0x3814,
    "records_committed": 0x3818,
    "records_streamed": 0x381C,
    "records_dropped": 0x3820,
    "overflow_count": 0x3824,
    "sequence_discontinuities": 0x3828,
    "beats_streamed_lo": 0x382C,
    "beats_streamed_hi": 0x3830,
    "last_global_stream_sequence": 0x3834,
    "records_abandoned": 0x3850,
    "reset_events": 0x3854,
    "last_channel_attempt_sequence": 0x3858,
}


def u32(value: int) -> int:
    return value & 0xFFFFFFFF


def delta32(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFF


def delta64(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFFFFFFFFFF


def utc_now() -> str:
    now_ns = time.time_ns()
    whole, fraction = divmod(now_ns, 1_000_000_000)
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(whole)) + \
        f".{fraction:09d}Z"


def sha256_bytes(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest().upper()


class GateFailure(RuntimeError):
    def __init__(self, code: str, detail: str):
        super().__init__(f"{code}: {detail}")
        self.code = code
        self.detail = detail


class RecordFailure(GateFailure):
    def __init__(self, errors: Iterable[str], blob: bytes):
        self.errors = tuple(errors)
        self.blob = bytes(blob)
        super().__init__("CORRUPT_OR_DISCONTINUOUS_RECORD", "; ".join(self.errors))


def ensure_private_directory(path: Path) -> None:
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.is_symlink() or not path.is_dir():
        raise GateFailure("ARTIFACT_PATH_UNSAFE", f"{path} is not a real directory")
    try:
        path.chmod(0o700)
    except OSError:
        pass


def open_exclusive_binary(path: Path) -> BinaryIO:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    flags |= getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path, flags, 0o600)
    return os.fdopen(descriptor, "wb", buffering=0)


def write_exclusive_bytes(path: Path, blob: bytes) -> None:
    with open_exclusive_binary(path) as output:
        output.write(blob)
        output.flush()
        os.fsync(output.fileno())


def write_exclusive_json(path: Path, value: object) -> None:
    payload = (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")
    write_exclusive_bytes(path, payload)


class EvidenceLedger:
    def __init__(self, path: Path):
        self._stream = open_exclusive_binary(path)

    def emit(self, event: str, **fields: object) -> None:
        record = {
            "timestamp_utc": utc_now(),
            "monotonic_ns": time.monotonic_ns(),
            "event": event,
            **fields,
        }
        self._stream.write(
            (json.dumps(record, sort_keys=True) + "\n").encode("utf-8")
        )
        self._stream.flush()
        os.fsync(self._stream.fileno())
        print(event, flush=True)

    def close(self) -> None:
        self._stream.close()


class MMIOClient:
    def __init__(
        self,
        executable: Path,
        user_node: str,
        bdf: str,
        audit_log: Path,
        ledger: EvidenceLedger,
    ):
        self.executable = str(executable)
        self.user_node = user_node
        self.bdf = bdf.lower()
        self.audit_log = str(audit_log)
        self.ledger = ledger

    def _invoke(self, operation: str, offset: int, value: int | None = None) -> str:
        command = [
            self.executable,
            "--node", self.user_node,
            "--bdf", self.bdf,
            "--log", self.audit_log,
            operation,
            f"0x{offset:08X}",
        ]
        if value is not None:
            command.append(f"0x{value:08X}")
        started = time.monotonic_ns()
        try:
            result = subprocess.run(
                command,
                check=False,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=5.0,
            )
        except subprocess.TimeoutExpired as exc:
            raise GateFailure(
                "MMIO_TOOL_TIMEOUT", f"{operation} 0x{offset:04X}"
            ) from exc
        self.ledger.emit(
            "MMIO_TOOL_RETURN",
            operation=operation,
            offset=f"0x{offset:08X}",
            requested_value=None if value is None else f"0x{value:08X}",
            returncode=result.returncode,
            duration_ns=time.monotonic_ns() - started,
        )
        if result.returncode != 0 or "R3_MMIO_RESULT=PASS" not in result.stdout:
            detail = result.stderr.strip().replace("\n", " ")[:500]
            raise GateFailure(
                "MMIO_ACCESS_FAILED",
                f"{operation} 0x{offset:04X}, rc={result.returncode}, {detail}",
            )
        return result.stdout

    def read(self, offset: int) -> int:
        output = self._invoke("read", offset)
        match = VALUE_RE.search(output)
        if not match:
            raise GateFailure(
                "MMIO_OUTPUT_UNPARSEABLE", f"read 0x{offset:04X}"
            )
        return int(match.group(1), 16)

    def write(self, offset: int, value: int) -> None:
        self._invoke("write", offset, value)

    def snapshot(self, label: str) -> dict[str, object]:
        status_before = self.read(0x3810)
        snapshot_before = self.read(0x3848)
        if status_before & (1 << 8):
            raise GateFailure("G2B_SNAPSHOT_BLOCKED", "stream reset busy")
        if snapshot_before & 1:
            raise GateFailure("G2B_SNAPSHOT_BLOCKED", "snapshot already busy")
        epoch_before = self.read(0x3838)
        generation_before = self.read(0x384C)
        self.write(0x3844, 1)
        deadline = time.monotonic() + SNAPSHOT_TIMEOUT_SECONDS
        snapshot_status = 0
        while time.monotonic() < deadline:
            snapshot_status = self.read(0x3848)
            if not (snapshot_status & 1) and (snapshot_status & 2):
                break
            time.sleep(0.002)
        else:
            raise GateFailure("G2B_SNAPSHOT_TIMEOUT", label)
        generation_after = self.read(0x384C)
        values = {name: self.read(offset)
                  for name, offset in SNAPSHOT_OFFSETS.items()}
        epoch_after = self.read(0x3838)
        status_after = self.read(0x3848)
        if epoch_after != epoch_before:
            raise GateFailure("UNEXPECTED_EPOCH_CHANGE", label)
        if not (status_after & 2) or status_after & 1:
            raise GateFailure("G2B_SNAPSHOT_INVALIDATED", label)
        if generation_after != u32(generation_before + 1):
            raise GateFailure(
                "G2B_SNAPSHOT_GENERATION_MISMATCH",
                f"{label}: {generation_before} -> {generation_after}",
            )
        values["beats_streamed"] = (
            (int(values["beats_streamed_hi"]) << 32) |
            int(values["beats_streamed_lo"])
        )
        values["epoch"] = epoch_after
        values["generation"] = generation_after
        values["snapshot_status"] = status_after
        values["last_global_valid"] = bool(status_after & (1 << 2))
        values["last_channel_valid"] = bool(status_after & (1 << 3))
        values["label"] = label
        return values


def require_idle_clean(mmio: MMIOClient, label: str) -> dict[str, int]:
    control = mmio.read(0x380C)
    status = mmio.read(0x3810)
    errors = mmio.read(0x383C)
    cause = mmio.read(0x3840)
    failures: list[str] = []
    if control != 0 or status & 1:
        failures.append("stream enabled")
    if status & (1 << 1):
        failures.append("C2H active")
    if not status & (1 << 2):
        failures.append("ring not empty")
    if status & (1 << 3):
        failures.append("ring full")
    if status & (1 << 8):
        failures.append("stream reset busy")
    if status & (1 << 9):
        failures.append("snapshot busy")
    if status & (1 << 11):
        failures.append("fatal status")
    if not status & (1 << 6):
        failures.append("source not ready")
    if not status & (1 << 7):
        failures.append("source not locked")
    if errors:
        failures.append(f"ERROR_STATUS=0x{errors:08X}")
    if cause:
        failures.append(f"LAST_ERROR_CAUSE=0x{cause:08X}")
    if status & 0xFFFFF000:
        failures.append(f"reserved status bits=0x{status & 0xFFFFF000:08X}")
    if failures:
        raise GateFailure("NONCLEAN_G2B_STATE", f"{label}: {', '.join(failures)}")
    return {
        "control": control,
        "status": status,
        "error_status": errors,
        "last_error_cause": cause,
    }


def t2_identity_and_readiness(mmio: MMIOClient, ledger: EvidenceLedger) -> dict[str, object]:
    ledger.emit("T2_BEGIN")
    legacy = {f"0x{offset:04X}": mmio.read(offset)
              for offset in EXPECTED_LEGACY}
    mismatches = [
        f"0x{offset:04X}=0x{legacy[f'0x{offset:04X}']:08X}, "
        f"expected 0x{expected:08X}"
        for offset, expected in EXPECTED_LEGACY.items()
        if legacy[f"0x{offset:04X}"] != expected
    ]
    if mismatches:
        raise GateFailure("RUNTIME_CANDIDATE_IDENTITY_MISMATCH", "; ".join(mismatches))

    nvp_before_ns = time.monotonic_ns()
    vclk_before = mmio.read(0x0080)
    sav_before = mmio.read(0x0084)
    legacy_commit_before = mmio.read(0x0088)
    nvp_status = mmio.read(0x008C)
    nack_count = mmio.read(0x0090)
    timeout_count = mmio.read(0x0094)
    current_op = mmio.read(0x0098)
    first_error = mmio.read(0x009C)
    detail_words = [mmio.read(offset) for offset in range(0x00A0, 0x00B5, 4)]
    if nvp_status & 0xFFFFFF00:
        raise GateFailure("NVP_STATUS_RESERVED_NONZERO", f"0x{nvp_status:08X}")
    if (nvp_status & 0x3F) != 0x39:
        raise GateFailure("FIXED_LIVE_AHD_SOURCE_NOT_READY",
                          f"NVP_STATUS=0x{nvp_status:08X}")
    if nack_count != 0 or timeout_count != 0 or first_error & 0x80000000:
        raise GateFailure(
            "FIXED_LIVE_AHD_SOURCE_NOT_READY",
            f"NACK={nack_count}, TIMEOUT={timeout_count}, "
            f"FIRST_ERROR=0x{first_error:08X}",
        )
    time.sleep(NVP_SAMPLE_SECONDS)
    vclk_after = mmio.read(0x0080)
    sav_after = mmio.read(0x0084)
    legacy_commit_after = mmio.read(0x0088)
    nvp_after_ns = time.monotonic_ns()
    sample_seconds = (nvp_after_ns - nvp_before_ns) / 1_000_000_000
    delta_vclk = delta32(vclk_after, vclk_before)
    delta_sav = delta32(sav_after, sav_before)
    if not delta_vclk or not delta_sav:
        raise GateFailure("FIXED_LIVE_AHD_SOURCE_NOT_READY", "video counters did not move")
    vclk_hz = delta_vclk / sample_seconds
    sav_hz = delta_sav / sample_seconds
    clocks_per_sav = delta_vclk / delta_sav
    if not 5200.0 <= clocks_per_sav <= 5360.0:
        raise GateFailure(
            "FIXED_LIVE_AHD_SOURCE_NOT_READY",
            f"VCLK/SAV ratio {clocks_per_sav:.6f} outside 5200..5360",
        )
    if not 20_000.0 <= sav_hz <= 35_000.0:
        raise GateFailure(
            "FIXED_LIVE_AHD_SOURCE_NOT_READY",
            f"SAV rate {sav_hz:.6f}/s outside guarded live range",
        )

    g2b_identity = {
        "magic": mmio.read(0x3800),
        "abi_version": mmio.read(0x3804),
        "capabilities": mmio.read(0x3808),
    }
    if g2b_identity != {
        "magic": 0x43324831,
        "abi_version": 0x00010000,
        "capabilities": 0x000B001F,
    }:
        raise GateFailure("G2B_ABI_IDENTITY_MISMATCH", repr(g2b_identity))
    idle = require_idle_clean(mmio, "T2")
    baseline = mmio.snapshot("T2_BASELINE")
    pristine_names = (
        "records_attempted", "records_committed", "records_streamed",
        "records_dropped", "overflow_count", "sequence_discontinuities",
        "beats_streamed", "records_abandoned",
    )
    nonzero = {name: baseline[name] for name in pristine_names if baseline[name]}
    if nonzero or baseline["last_global_valid"] or baseline["last_channel_valid"]:
        raise GateFailure(
            "NONCLEAN_RETAINED_TRANSPORT_EPOCH",
            f"counters={nonzero}, global_valid={baseline['last_global_valid']}, "
            f"channel_valid={baseline['last_channel_valid']}",
        )
    report = {
        "gate": "PASS",
        "dual_layer_identity": "PASS",
        "runtime_git_sha": "224d194e5f82c85bcb29297561c5d5e76d28063b",
        "build_flags": "0x00000103",
        "legacy": {key: f"0x{value:08X}" for key, value in legacy.items()},
        "nvp": {
            "status": f"0x{nvp_status:08X}",
            "sda": (nvp_status >> 7) & 1,
            "scl": (nvp_status >> 6) & 1,
            "nack_count": nack_count,
            "timeout_count": timeout_count,
            "current_op": f"0x{current_op:08X}",
            "first_error": f"0x{first_error:08X}",
            "detail_words": [f"0x{word:08X}" for word in detail_words],
            "sample_seconds": sample_seconds,
            "vclk_delta": delta_vclk,
            "sav_delta": delta_sav,
            "vclk_hz": vclk_hz,
            "sav_hz": sav_hz,
            "vclk_per_sav": clocks_per_sav,
            "legacy_record_commit_before": legacy_commit_before,
            "legacy_record_commit_after": legacy_commit_after,
            "frame_rate_method": "LONG_WINDOW_C2H_SOURCE_FRAME_AND_SOF_SEQUENCES",
        },
        "g2b": {
            **{key: f"0x{value:08X}" for key, value in g2b_identity.items()},
            "idle": {key: f"0x{value:08X}" for key, value in idle.items()},
            "baseline_snapshot": baseline,
        },
        "reset_stream_state_used": False,
    }
    ledger.emit("T2_PASS", epoch=baseline["epoch"])
    return report


@dataclass(frozen=True)
class Header:
    words: tuple[int, ...]

    def value(self, name: str) -> int:
        return self.words[HEADER_NAMES.index(name)]

    def as_dict(self) -> dict[str, object]:
        result: dict[str, object] = {}
        for name, value in zip(HEADER_NAMES, self.words):
            result[name] = value
            result[f"{name}_hex"] = f"0x{value:08X}"
        result["slot"] = self.value("source_slot_generation_and_slot") & 0xF
        result["slot_generation"] = (
            self.value("source_slot_generation_and_slot") >> 8
        )
        return result


@dataclass(frozen=True)
class ParsedRecord:
    blob: bytes
    header: Header
    payload: bytes
    boundary_discontinuity: bool


def structural_parse(blob: bytes) -> tuple[Header, bytes]:
    errors: list[str] = []
    if len(blob) != RECORD_BYTES:
        raise RecordFailure((f"record size {len(blob)}",), blob)
    words = HEADER_STRUCT.unpack_from(blob, 0)
    header = Header(tuple(words))
    if header.value("magic") != MAGIC:
        errors.append(f"magic 0x{header.value('magic'):08X}")
    if header.value("record_version") != RECORD_VERSION:
        errors.append(f"version 0x{header.value('record_version'):08X}")
    if header.value("payload_length") != PAYLOAD_BYTES:
        errors.append(f"payload length {header.value('payload_length')}")
    line = header.value("source_line_sequence")
    if line >= LINES_PER_FRAME:
        errors.append(f"line {line} outside 0..1079")
    flags = header.value("flags")
    if flags & ~ALLOWED_FLAG_MASK:
        errors.append(f"reserved/window flag bits 0x{flags & ~ALLOWED_FLAG_MASK:08X}")
    if not flags & FLAG_VALID:
        errors.append("VALID clear")
    if bool(flags & FLAG_SOF) != (line == 0):
        errors.append("SOF/line disagreement")
    if flags & FLAG_WINDOW_END:
        errors.append("WINDOW_END set")
    if header.value("active_logical_channel_count") != 1:
        errors.append("active logical channel count is not 1")
    slot_word = header.value("source_slot_generation_and_slot")
    if slot_word & 0xF0 or (slot_word & 0xF) > 3:
        errors.append(f"invalid slot word 0x{slot_word:08X}")
    if header.value("logical_channel_id") != 0:
        errors.append("logical channel is not exact 0")
    if header.value("physical_input_id") != 0:
        errors.append("physical input is not exact 0")
    padding = blob[PADDING_FIRST:]
    if any(padding):
        first = next(index for index, value in enumerate(padding) if value)
        errors.append(f"nonzero padding at byte {PADDING_FIRST + first}")
    if errors:
        raise RecordFailure(errors, blob)
    return header, blob[HEADER_BYTES:PADDING_FIRST]


class PersistentValidator:
    """One retained-epoch state machine shared across all R3 phases."""

    def __init__(self, armed_epoch: int):
        self.armed_epoch = armed_epoch
        self.last_global: int | None = None
        self.last_attempt: int | None = None
        self.last_source: tuple[int, int, int] | None = None
        self.last_slot_generation: dict[int, int] = {}
        self.boundary_expected = True
        self.total_records = 0
        self.global_gaps = 0
        self.attempt_gaps = 0
        self.duplicates = 0
        self.epoch_changes = 0
        self.unexpected_discontinuities = 0

    def mark_disabled_interval(self) -> None:
        self.boundary_expected = True

    def accept(self, blob: bytes) -> ParsedRecord:
        header, payload = structural_parse(blob)
        errors: list[str] = []
        epoch = header.value("reset_epoch")
        global_sequence = header.value("global_stream_sequence")
        attempt = header.value("channel_attempt_sequence")
        frame = header.value("source_frame_sequence")
        line = header.value("source_line_sequence")
        capture = header.value("source_capture_sequence")
        flags = header.value("flags")
        if epoch != self.armed_epoch:
            self.epoch_changes += 1
            errors.append(f"epoch {epoch} differs from armed {self.armed_epoch}")
        if self.last_global is None:
            if global_sequence != 0:
                errors.append(f"first global {global_sequence} is not 0")
            if attempt != 0:
                errors.append(f"first attempt {attempt} is not 0")
        else:
            expected_global = u32(self.last_global + 1)
            expected_attempt = u32(self.last_attempt + 1)  # type: ignore[arg-type]
            if global_sequence != expected_global:
                self.global_gaps += 1
                if global_sequence == self.last_global:
                    self.duplicates += 1
                errors.append(
                    f"global {global_sequence}, expected {expected_global}"
                )
            if attempt != expected_attempt:
                self.attempt_gaps += 1
                if attempt == self.last_attempt:
                    self.duplicates += 1
                errors.append(f"attempt {attempt}, expected {expected_attempt}")
        boundary_flag = bool(flags & FLAG_DISCONTINUITY)
        if self.boundary_expected:
            if not boundary_flag:
                errors.append("expected post-disabled DISCONTINUITY flag absent")
            if self.last_source is not None:
                capture_delta = delta32(capture, self.last_source[2])
                if capture_delta == 0:
                    errors.append("source capture did not advance across boundary")
        else:
            if boundary_flag:
                self.unexpected_discontinuities += 1
                errors.append("unexpected DISCONTINUITY flag")
            if self.last_source is not None:
                previous_frame, previous_line, previous_capture = self.last_source
                expected_line = 0 if previous_line == LINES_PER_FRAME - 1 \
                    else previous_line + 1
                expected_frame = u32(previous_frame + 1) \
                    if previous_line == LINES_PER_FRAME - 1 else previous_frame
                expected_capture = u32(previous_capture + 1)
                if (frame, line, capture) != (
                    expected_frame, expected_line, expected_capture
                ):
                    errors.append(
                        "source progression "
                        f"{(frame, line, capture)} expected "
                        f"{(expected_frame, expected_line, expected_capture)}"
                    )
        if flags & FLAG_OVERFLOW:
            errors.append("OVERFLOW_OCCURRED flag set")
        if flags & FLAG_MALFORMED_PRECEDING:
            errors.append("MALFORMED_PRECEDING flag set")
        if header.value("source_malformed_count_snapshot") != 0:
            errors.append("source malformed lifetime snapshot nonzero")
        if header.value("source_dropped_count_snapshot") != 0:
            errors.append("source dropped lifetime snapshot nonzero")
        slot_word = header.value("source_slot_generation_and_slot")
        slot = slot_word & 0xF
        generation = slot_word >> 8
        if slot in self.last_slot_generation:
            expected_generation = (self.last_slot_generation[slot] + 1) & 0xFFFFFF
            if generation != expected_generation:
                errors.append(
                    f"slot {slot} generation {generation}, "
                    f"expected {expected_generation}"
                )
        if errors:
            raise RecordFailure(errors, blob)
        parsed = ParsedRecord(
            blob=blob,
            header=header,
            payload=payload,
            boundary_discontinuity=self.boundary_expected,
        )
        self.last_global = global_sequence
        self.last_attempt = attempt
        self.last_source = (frame, line, capture)
        self.last_slot_generation[slot] = generation
        self.boundary_expected = False
        self.total_records += 1
        return parsed


class FixedBoundaryFramer:
    def __init__(self):
        self.pending = bytearray()
        self.bytes_received = 0

    def feed(self, chunk: bytes) -> list[bytes]:
        self.bytes_received += len(chunk)
        combined = self.pending + chunk
        complete_bytes = len(combined) // RECORD_BYTES * RECORD_BYTES
        records = [
            bytes(combined[offset:offset + RECORD_BYTES])
            for offset in range(0, complete_bytes, RECORD_BYTES)
        ]
        self.pending = bytearray(combined[complete_bytes:])
        return records


class ReadDeadline(TimeoutError):
    pass


class AlignedC2HReader:
    """One fd and one page-aligned readv buffer for the complete R3 session."""

    def __init__(self, node: str):
        if os.name != "posix":
            raise GateFailure("LINUX_REQUIRED", "live C2H reader is POSIX-only")
        self.node = node
        self.buffer_bytes = READ_REQUEST_RECORDS * RECORD_BYTES
        self.fd = -1
        self.buffer: mmap.mmap | None = None
        self.syscalls = 0
        self.short_reads = 0
        self.timeouts = 0
        self.total_bytes = 0
        self._old_handler: object | None = None

    def open(self) -> None:
        flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | \
            getattr(os, "O_NOFOLLOW", 0)
        self.fd = os.open(self.node, flags)
        metadata = os.fstat(self.fd)
        if not stat.S_ISCHR(metadata.st_mode):
            os.close(self.fd)
            self.fd = -1
            raise GateFailure("C2H_NODE_NOT_CHAR_DEVICE", self.node)
        self.buffer = mmap.mmap(
            -1,
            self.buffer_bytes,
            flags=mmap.MAP_PRIVATE | mmap.MAP_ANONYMOUS,
            prot=mmap.PROT_READ | mmap.PROT_WRITE,
        )
        self._old_handler = signal.getsignal(signal.SIGALRM)
        signal.signal(signal.SIGALRM, self._alarm)
        signal.siginterrupt(signal.SIGALRM, True)

    @staticmethod
    def _alarm(_signum: int, _frame: object) -> None:
        raise ReadDeadline("bounded C2H read timed out")

    def read(self, request_bytes: int, timeout_seconds: float) -> bytes:
        if self.fd < 0 or self.buffer is None:
            raise GateFailure("C2H_READER_NOT_OPEN", self.node)
        if request_bytes <= 0 or request_bytes > self.buffer_bytes or \
                request_bytes % RECORD_BYTES:
            raise GateFailure(
                "C2H_READ_POLICY_REJECTED",
                f"request {request_bytes} is not an allowed aligned size",
            )
        view = memoryview(self.buffer)[:request_bytes]
        signal.setitimer(signal.ITIMER_REAL, max(0.001, timeout_seconds))
        try:
            self.syscalls += 1
            count = os.readv(self.fd, [view])
        except ReadDeadline:
            self.timeouts += 1
            raise
        except InterruptedError as exc:
            self.timeouts += 1
            raise ReadDeadline("C2H read interrupted by deadline") from exc
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0.0)
        if count <= 0:
            view.release()
            raise GateFailure("C2H_READ_TERMINATED", f"read returned {count}")
        if count != request_bytes:
            self.short_reads += 1
        result = bytes(view[:count])
        view.release()
        self.total_bytes += count
        return result

    def close(self) -> None:
        signal.setitimer(signal.ITIMER_REAL, 0.0)
        if self._old_handler is not None:
            signal.signal(signal.SIGALRM, self._old_handler)
        if self.buffer is not None:
            self.buffer.close()
            self.buffer = None
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1


@dataclass
class PhaseMetrics:
    name: str
    records: int = 0
    bytes: int = 0
    parser_ns: int = 0
    first_header: dict[str, object] | None = None
    last_header: dict[str, object] | None = None
    first_record_sha256: str | None = None
    last_record_sha256: str | None = None
    first_payload_sample: bytes | None = field(default=None, repr=False)
    last_payload_sample: bytes | None = field(default=None, repr=False)
    record_hasher: object = field(default_factory=hashlib.sha256, repr=False)
    payload_hasher: object = field(default_factory=hashlib.sha256, repr=False)

    def add(self, parsed: ParsedRecord, parser_ns: int) -> None:
        record_hash = sha256_bytes(parsed.blob)
        self.records += 1
        self.bytes += len(parsed.blob)
        self.parser_ns += parser_ns
        self.record_hasher.update(parsed.blob)  # type: ignore[attr-defined]
        self.payload_hasher.update(parsed.payload)  # type: ignore[attr-defined]
        header = parsed.header.as_dict()
        if self.first_header is None:
            self.first_header = header
            self.first_record_sha256 = record_hash
            self.first_payload_sample = parsed.payload[:BOUNDED_SAMPLE_BYTES]
        self.last_header = header
        self.last_record_sha256 = record_hash
        self.last_payload_sample = parsed.payload[-BOUNDED_SAMPLE_BYTES:]

    def summary(self, duration_seconds: float | None = None) -> dict[str, object]:
        parser_seconds = self.parser_ns / 1_000_000_000
        result: dict[str, object] = {
            "name": self.name,
            "complete_records": self.records,
            "transport_bytes": self.bytes,
            "application_payload_bytes": self.records * PAYLOAD_BYTES,
            "rolling_record_sha256": self.record_hasher.hexdigest().upper(),  # type: ignore[attr-defined]
            "rolling_payload_sha256": self.payload_hasher.hexdigest().upper(),  # type: ignore[attr-defined]
            "first_record_sha256": self.first_record_sha256,
            "last_record_sha256": self.last_record_sha256,
            "first_header": self.first_header,
            "last_header": self.last_header,
            "first_payload_sample_sha256": None if self.first_payload_sample is None
            else sha256_bytes(self.first_payload_sample),
            "last_payload_sample_sha256": None if self.last_payload_sample is None
            else sha256_bytes(self.last_payload_sample),
            "parser_seconds": parser_seconds,
            "parser_transport_MB_s_decimal": None if parser_seconds == 0 else
            self.bytes / parser_seconds / 1_000_000,
        }
        if duration_seconds is not None:
            result.update({
                "duration_seconds": duration_seconds,
                "records_per_second": self.records / duration_seconds,
                "application_payload_MB_s_decimal":
                    self.records * PAYLOAD_BYTES / duration_seconds / 1_000_000,
                "transport_MB_s_decimal":
                    self.bytes / duration_seconds / 1_000_000,
            })
        return result


class FrameCollector:
    def __init__(self):
        self.active_key: tuple[int, int, int, int] | None = None
        self.next_line = 0
        self.data: bytearray | None = None
        self.complete_frames = 0
        self.discarded_frames = 0
        self.leading_fragments = 0
        self.first_hash: str | None = None
        self.last_hash: str | None = None
        self.first_frame: bytes | None = None
        self._in_leading_fragment = False

    def push(self, parsed: ParsedRecord) -> bytes | None:
        header = parsed.header
        line = header.value("source_line_sequence")
        if parsed.boundary_discontinuity or header.value("flags") & FLAG_DISCONTINUITY:
            if self.active_key is not None:
                self.discarded_frames += 1
            self.active_key = None
            self.data = None
            self._in_leading_fragment = True
            return None
        key = (
            header.value("logical_channel_id"),
            header.value("physical_input_id"),
            header.value("reset_epoch"),
            header.value("source_frame_sequence"),
        )
        if line == 0:
            if self.active_key is not None:
                self.discarded_frames += 1
            self.active_key = key
            self.next_line = 0
            self.data = bytearray(FRAME_BYTES)
            self._in_leading_fragment = False
        elif self.active_key is None:
            if not self._in_leading_fragment:
                self.leading_fragments += 1
                self._in_leading_fragment = True
            return None
        if self.active_key != key or self.data is None or line != self.next_line:
            raise GateFailure(
                "FRAME_RECONSTRUCTION_SEQUENCE_ERROR",
                f"key={key}, line={line}, expected key={self.active_key}, "
                f"line={self.next_line}",
            )
        start = line * PAYLOAD_BYTES
        self.data[start:start + PAYLOAD_BYTES] = parsed.payload
        self.next_line += 1
        if line != LINES_PER_FRAME - 1:
            return None
        frame = bytes(self.data)
        digest = sha256_bytes(frame)
        self.complete_frames += 1
        if self.first_hash is None:
            self.first_hash = digest
            self.first_frame = frame
        self.last_hash = digest
        self.active_key = None
        self.data = None
        self.next_line = 0
        return frame

    def summary(self) -> dict[str, object]:
        return {
            "complete_frames": self.complete_frames,
            "discarded_frames": self.discarded_frames,
            "incomplete_leading_fragments": self.leading_fragments,
            "incomplete_trailing_fragments": int(self.active_key is not None),
            "first_complete_frame_sha256": self.first_hash,
            "last_complete_frame_sha256": self.last_hash,
        }


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    body = kind + payload
    return struct.pack(">I", len(payload)) + body + \
        struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def uyvy_to_png(raw: bytes) -> bytes:
    if len(raw) != FRAME_BYTES:
        raise GateFailure("FRAME_GEOMETRY_ERROR", f"raw frame is {len(raw)} bytes")
    scanlines = bytearray((PIXELS_PER_LINE * 3 + 1) * LINES_PER_FRAME)
    source = memoryview(raw)
    destination = 0

    def clamp(value: int) -> int:
        return 0 if value < 0 else 255 if value > 255 else value

    for line in range(LINES_PER_FRAME):
        scanlines[destination] = 0
        destination += 1
        source_offset = line * PAYLOAD_BYTES
        for pair in range(PIXELS_PER_LINE // 2):
            base = source_offset + pair * 4
            u = int(source[base]) - 128
            y0 = int(source[base + 1]) - 16
            v = int(source[base + 2]) - 128
            y1 = int(source[base + 3]) - 16
            for y_value in (y0, y1):
                c = max(0, y_value)
                scanlines[destination] = clamp((298 * c + 409 * v + 128) >> 8)
                scanlines[destination + 1] = clamp(
                    (298 * c - 100 * u - 208 * v + 128) >> 8
                )
                scanlines[destination + 2] = clamp(
                    (298 * c + 516 * u + 128) >> 8
                )
                destination += 3
    header = struct.pack(
        ">IIBBBBB", PIXELS_PER_LINE, LINES_PER_FRAME, 8, 2, 0, 0, 0
    )
    return (
        b"\x89PNG\r\n\x1a\n" +
        png_chunk(b"IHDR", header) +
        png_chunk(b"IDAT", zlib.compress(bytes(scanlines), 6)) +
        png_chunk(b"IEND", b"")
    )


def snapshot_delta(before: dict[str, object], after: dict[str, object], name: str) -> int:
    if name == "beats_streamed":
        return delta64(int(after[name]), int(before[name]))
    return delta32(int(after[name]), int(before[name]))


def reconcile(
    before: dict[str, object],
    after: dict[str, object],
    host_records: int,
    validator: PersistentValidator,
    label: str,
) -> dict[str, object]:
    deltas = {
        name: snapshot_delta(before, after, name)
        for name in (
            "records_attempted", "records_committed", "records_streamed",
            "records_dropped", "overflow_count", "sequence_discontinuities",
            "beats_streamed", "records_abandoned", "reset_events",
        )
    }
    failures: list[str] = []
    for name in ("records_attempted", "records_committed", "records_streamed"):
        if deltas[name] != host_records:
            failures.append(f"{name} delta {deltas[name]} != host {host_records}")
    if deltas["beats_streamed"] != host_records * BEATS_PER_RECORD:
        failures.append(
            f"beats delta {deltas['beats_streamed']} != {host_records * BEATS_PER_RECORD}"
        )
    for name in (
        "records_dropped", "overflow_count", "sequence_discontinuities",
        "records_abandoned", "reset_events",
    ):
        if deltas[name] != 0:
            failures.append(f"{name} delta {deltas[name]} is nonzero")
    if before["epoch"] != after["epoch"]:
        failures.append("epoch changed")
    if host_records:
        if not after["last_global_valid"] or not after["last_channel_valid"]:
            failures.append("last-sequence valid bits not set")
        if int(after["last_global_stream_sequence"]) != validator.last_global:
            failures.append("MMIO last global differs from host")
        if int(after["last_channel_attempt_sequence"]) != validator.last_attempt:
            failures.append("MMIO last channel attempt differs from host")
    if failures:
        raise GateFailure(
            "CAPTURE_COUNTER_OR_SEQUENCE_MISMATCH",
            f"{label}: {'; '.join(failures)}",
        )
    return {"result": "PASS", "host_complete_records": host_records, "deltas": deltas}


class SessionRunner:
    def __init__(self, args: argparse.Namespace):
        root = Path(args.artifact_root).resolve(strict=True)
        if not root.is_dir() or root.is_symlink():
            raise GateFailure("ARTIFACT_ROOT_UNSAFE", str(root))
        self.root = root
        self.private = root / "private-video"
        self.public = root / "public-staging"
        self.raw = root / "raw"
        ensure_private_directory(self.private)
        ensure_private_directory(self.public)
        ensure_private_directory(self.raw)
        self.ledger = EvidenceLedger(self.raw / "R3_C2H_TOOL_EVENTS.jsonl")
        self.mmio = MMIOClient(
            Path(args.mmio_tool).resolve(strict=True),
            args.user_node,
            args.bdf,
            Path(args.mmio_log).resolve(),
            self.ledger,
        )
        self.reader = AlignedC2HReader(args.c2h_node)
        self.framer = FixedBoundaryFramer()
        self.validator: PersistentValidator | None = None
        self.stream_enabled = False
        self.anomaly_count = 0
        self.disable_cancel: threading.Event | None = None
        self.disable_done: threading.Event | None = None
        self.disable_error: BaseException | None = None
        self.disable_started_ns: int | None = None
        self.disable_completed_ns: int | None = None

    def preserve_anomaly(self, blob: bytes, label: str) -> None:
        if self.anomaly_count >= MAX_ANOMALY_RECORDS:
            return
        path = self.private / (
            f"R3_ANOMALY_{self.anomaly_count:02d}_{label}.bin"
        )
        write_exclusive_bytes(path, blob)
        self.anomaly_count += 1

    def validate_record(
        self,
        blob: bytes,
        metrics: PhaseMetrics,
        collector: FrameCollector | None,
    ) -> ParsedRecord:
        assert self.validator is not None
        started = time.process_time_ns()
        try:
            parsed = self.validator.accept(blob)
            if collector is not None:
                collector.push(parsed)
        except RecordFailure as exc:
            self.preserve_anomaly(exc.blob, metrics.name)
            raise
        elapsed = time.process_time_ns() - started
        metrics.add(parsed, elapsed)
        return parsed

    def read_and_route(
        self,
        request_records: int,
        timeout_seconds: float,
        route: Callable[[bytes], None],
    ) -> int:
        chunk = self.reader.read(request_records * RECORD_BYTES, timeout_seconds)
        records = self.framer.feed(chunk)
        for blob in records:
            route(blob)
        return len(records)

    def enable(self, label: str) -> int:
        self.ledger.emit("READER_READY", phase=label)
        self.mmio.write(0x380C, 1)
        self.stream_enabled = True
        enabled_ns = time.monotonic_ns()
        control = self.mmio.read(0x380C)
        if control != 1:
            raise GateFailure("STREAM_ENABLE_READBACK_FAILED", label)
        self.ledger.emit("STREAM_ENABLED", phase=label, monotonic_ns=enabled_ns)
        return enabled_ns

    def disable(self, label: str) -> int:
        if self.stream_enabled:
            self.mmio.write(0x380C, 0)
            self.stream_enabled = False
        disabled_ns = time.monotonic_ns()
        control = self.mmio.read(0x380C)
        if control != 0:
            raise GateFailure("STREAM_DISABLE_READBACK_FAILED", label)
        self.ledger.emit("STREAM_DISABLED", phase=label, monotonic_ns=disabled_ns)
        return disabled_ns

    def drain(
        self,
        label: str,
        metrics: PhaseMetrics,
        output: BinaryIO | None,
        collector: FrameCollector | None,
    ) -> None:
        deadline = time.monotonic() + DRAIN_TIMEOUT_SECONDS
        while True:
            status = self.mmio.read(0x3810)
            need_data = bool(self.framer.pending) or bool(status & (1 << 1)) or \
                not bool(status & (1 << 2))
            if not need_data:
                break
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise GateFailure("C2H_DRAIN_TIMEOUT", label)

            def route(blob: bytes) -> None:
                parsed = self.validate_record(blob, metrics, collector)
                if output is not None:
                    output.write(parsed.blob)

            try:
                self.read_and_route(1, min(1.0, remaining), route)
            except ReadDeadline as exc:
                if self.framer.pending:
                    raise GateFailure(
                        "TERMINAL_PARTIAL_RECORD",
                        f"{label}: {len(self.framer.pending)} bytes",
                    ) from exc
                raise GateFailure("C2H_DRAIN_READ_TIMEOUT", label) from exc
        if self.framer.pending:
            raise GateFailure(
                "TERMINAL_PARTIAL_RECORD",
                f"{label}: {len(self.framer.pending)} bytes",
            )
        require_idle_clean(self.mmio, f"{label}_POST_DRAIN")

    def save_samples(self, metrics: PhaseMetrics) -> dict[str, object]:
        paths: dict[str, object] = {}
        for kind, sample in (
            ("first", metrics.first_payload_sample),
            ("last", metrics.last_payload_sample),
        ):
            if sample is None:
                continue
            path = self.private / f"{metrics.name}_{kind}_payload_sample.bin"
            write_exclusive_bytes(path, sample)
            paths[f"{kind}_sample_local_path"] = str(path)
            paths[f"{kind}_sample_sha256"] = sha256_bytes(sample)
        return paths

    def run_fixed(
        self,
        label: str,
        target_records: int,
        primary_path: Path,
        drain_path: Path,
        timeout_seconds: float,
        collector: FrameCollector | None = None,
    ) -> tuple[dict[str, object], PhaseMetrics, PhaseMetrics]:
        require_idle_clean(self.mmio, f"{label}_PREFLIGHT")
        before = self.mmio.snapshot(f"{label}_BEFORE")
        primary = PhaseMetrics(f"{label}_PRIMARY")
        drained = PhaseMetrics(f"{label}_DRAIN")
        with open_exclusive_binary(primary_path) as primary_output, \
                open_exclusive_binary(drain_path) as drain_output:
            enabled_ns = self.enable(label)
            deadline = time.monotonic() + timeout_seconds
            try:
                while primary.records < target_records:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        raise GateFailure(f"{label}_PRIMARY_TIMEOUT", label)
                    request_records = min(
                        READ_REQUEST_RECORDS,
                        max(1, target_records - primary.records),
                    )

                    def route(blob: bytes) -> None:
                        destination = primary if primary.records < target_records \
                            else drained
                        parsed = self.validate_record(blob, destination, collector)
                        if destination is primary:
                            primary_output.write(parsed.blob)
                        else:
                            drain_output.write(parsed.blob)

                    self.read_and_route(request_records, min(1.0, remaining), route)
            except ReadDeadline as exc:
                raise GateFailure(f"{label}_PRIMARY_TIMEOUT", label) from exc
            disabled_ns = self.disable(label)
            self.drain(label, drained, drain_output, collector)
            primary_output.flush()
            os.fsync(primary_output.fileno())
            drain_output.flush()
            os.fsync(drain_output.fileno())
        after = self.mmio.snapshot(f"{label}_AFTER")
        reconciliation = reconcile(
            before, after, primary.records + drained.records,
            self.validator, label,  # type: ignore[arg-type]
        )
        report = {
            "gate": "PASS",
            "target_primary_records": target_records,
            "primary": primary.summary(),
            "drain": drained.summary(),
            "enabled_monotonic_ns": enabled_ns,
            "disabled_monotonic_ns": disabled_ns,
            "counter_reconciliation": reconciliation,
            "before_snapshot": before,
            "after_snapshot": after,
            "reset_stream_state_used": False,
        }
        report["private_samples"] = {
            "primary": self.save_samples(primary),
            "drain": self.save_samples(drained),
        }
        self.ledger.emit(
            f"{label}_PASS",
            primary_records=primary.records,
            drain_records=drained.records,
        )
        return report, primary, drained

    def _timed_disable(self, deadline_ns: int, label: str) -> None:
        assert self.disable_cancel is not None
        assert self.disable_done is not None
        remaining = (deadline_ns - time.monotonic_ns()) / 1_000_000_000
        if remaining > 0 and self.disable_cancel.wait(remaining):
            return
        if self.disable_cancel.is_set():
            return
        try:
            self.disable_started_ns = time.monotonic_ns()
            self.mmio.write(0x380C, 0)
            self.disable_completed_ns = time.monotonic_ns()
            self.stream_enabled = False
        except BaseException as exc:  # propagated on the reader thread
            self.disable_error = exc
        finally:
            self.disable_done.set()

    def run_continuous(self) -> dict[str, object]:
        label = "T5"
        require_idle_clean(self.mmio, "T5_PREFLIGHT")
        free_bytes = shutil.disk_usage(self.root).free
        if free_bytes < MIN_FREE_BYTES_T5:
            raise GateFailure(
                "INSUFFICIENT_FREE_DISK",
                f"{free_bytes} < {MIN_FREE_BYTES_T5}",
            )
        before = self.mmio.snapshot("T5_BEFORE")
        warmup = PhaseMetrics("T5_WARMUP")
        measured = PhaseMetrics("T5_MEASURED")
        drained = PhaseMetrics("T5_DRAIN")
        measured_frames = FrameCollector()
        enabled_ns = self.enable(label)
        warmup_end_ns = enabled_ns + int(WARMUP_SECONDS * 1_000_000_000)
        measurement_end_ns = warmup_end_ns + int(MEASURE_SECONDS * 1_000_000_000)
        self.disable_cancel = threading.Event()
        self.disable_done = threading.Event()
        disable_thread = threading.Thread(
            target=self._timed_disable,
            args=(measurement_end_ns, label),
            name="r3-exact-t5-disable",
            daemon=False,
        )
        disable_thread.start()
        try:
            while not self.disable_done.is_set():
                now_ns = time.monotonic_ns()
                nearest_boundary = min(
                    abs(warmup_end_ns - now_ns),
                    abs(measurement_end_ns - now_ns),
                ) / 1_000_000_000
                request_records = 1 if nearest_boundary <= BOUNDARY_FINE_SECONDS \
                    else READ_REQUEST_RECORDS

                def route(blob: bytes) -> None:
                    completed_ns = time.monotonic_ns()
                    if completed_ns < warmup_end_ns:
                        destination = warmup
                        collector = None
                    elif completed_ns < measurement_end_ns:
                        destination = measured
                        collector = measured_frames
                    else:
                        destination = drained
                        collector = None
                    self.validate_record(blob, destination, collector)

                try:
                    self.read_and_route(request_records, 1.0, route)
                except ReadDeadline as exc:
                    if not self.disable_done.is_set():
                        raise GateFailure("T5_HOST_READ_TIMEOUT", "stream active") from exc
            disable_thread.join(timeout=5.0)
            if disable_thread.is_alive():
                raise GateFailure("T5_DISABLE_THREAD_STUCK", label)
            if self.disable_error is not None:
                raise GateFailure("T5_DISABLE_FAILED", repr(self.disable_error))
            self.stream_enabled = False
            self.ledger.emit(
                "STREAM_DISABLED",
                phase=label,
                request_monotonic_ns=self.disable_started_ns,
                completed_monotonic_ns=self.disable_completed_ns,
            )
            self.drain(label, drained, None, None)
        except BaseException:
            self.disable_cancel.set()
            disable_thread.join(timeout=5.0)
            raise
        after = self.mmio.snapshot("T5_AFTER")
        total_records = warmup.records + measured.records + drained.records
        reconciliation = reconcile(
            before, after, total_records, self.validator, label  # type: ignore[arg-type]
        )
        frame_summary = measured_frames.summary()
        if measured_frames.complete_frames == 0:
            raise GateFailure("T5_NO_COMPLETE_FRAME", label)
        report = {
            "gate": "PASS",
            "warmup": warmup.summary(WARMUP_SECONDS),
            "measured": measured.summary(MEASURE_SECONDS),
            "drain": drained.summary(),
            "frame_metrics": frame_summary,
            "warmup_duration_seconds": WARMUP_SECONDS,
            "measured_duration_seconds": MEASURE_SECONDS,
            "measurement_interval_semantics":
                "record-validation completion monotonic timestamps in exact "
                "[warmup_end,warmup_end+60s) interval",
            "enable_monotonic_ns": enabled_ns,
            "warmup_end_monotonic_ns": warmup_end_ns,
            "measurement_end_monotonic_ns": measurement_end_ns,
            "disable_request_monotonic_ns": self.disable_started_ns,
            "disable_complete_monotonic_ns": self.disable_completed_ns,
            "free_disk_bytes_preflight": free_bytes,
            "counter_reconciliation": reconciliation,
            "before_snapshot": before,
            "after_snapshot": after,
            "reader": {
                "read_syscalls_session_total": self.reader.syscalls,
                "short_read_events_session_total": self.reader.short_reads,
                "host_read_timeouts_session_total": self.reader.timeouts,
                "total_bytes_session": self.reader.total_bytes,
                "request_buffer_alignment": RECORD_BYTES,
                "request_size_granularity": RECORD_BYTES,
            },
            "validator": {
                "global_sequence_gaps": self.validator.global_gaps,  # type: ignore[union-attr]
                "channel_attempt_gaps": self.validator.attempt_gaps,  # type: ignore[union-attr]
                "duplicates": self.validator.duplicates,  # type: ignore[union-attr]
                "unexpected_epoch_changes": self.validator.epoch_changes,  # type: ignore[union-attr]
                "unexpected_discontinuities":
                    self.validator.unexpected_discontinuities,  # type: ignore[union-attr]
            },
            "reset_stream_state_used": False,
            "network_operations_performed": False,
            "full_continuous_payload_retained": False,
        }
        report["private_samples"] = {
            "warmup": self.save_samples(warmup),
            "measured": self.save_samples(measured),
            "drain": self.save_samples(drained),
        }
        self.ledger.emit(
            "T5_PASS",
            warmup_records=warmup.records,
            measured_records=measured.records,
            drain_records=drained.records,
            complete_frames=measured_frames.complete_frames,
        )
        return report

    def emergency_disable_and_drain(self) -> dict[str, object]:
        result: dict[str, object] = {"disable_attempted": False, "quiescent": False}
        if self.disable_cancel is not None:
            self.disable_cancel.set()
        try:
            if self.stream_enabled:
                result["disable_attempted"] = True
                self.disable("EMERGENCY")
        except BaseException as exc:
            result["disable_error"] = repr(exc)
            return result
        emergency_path = self.private / "R3_EMERGENCY_DRAIN.bin"
        try:
            with open_exclusive_binary(emergency_path) as output:
                deadline = time.monotonic() + DRAIN_TIMEOUT_SECONDS
                while True:
                    status = self.mmio.read(0x3810)
                    need_data = bool(self.framer.pending) or \
                        bool(status & (1 << 1)) or not bool(status & (1 << 2))
                    if not need_data:
                        result["quiescent"] = True
                        break
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        result["drain_error"] = "timeout"
                        break
                    chunk = self.reader.read(RECORD_BYTES, min(1.0, remaining))
                    for blob in self.framer.feed(chunk):
                        output.write(blob)
                output.flush()
                os.fsync(output.fileno())
            result["terminal_partial_bytes"] = len(self.framer.pending)
            if self.framer.pending:
                result["quiescent"] = False
        except BaseException as exc:
            result["drain_error"] = repr(exc)
        return result

    def run(self) -> int:
        failure: dict[str, object] | None = None
        try:
            t2 = t2_identity_and_readiness(self.mmio, self.ledger)
            write_exclusive_json(
                self.public / "G2B_R3_T2_TOOL_REPORT.json", t2
            )
            epoch = int(t2["g2b"]["baseline_snapshot"]["epoch"])  # type: ignore[index]
            self.validator = PersistentValidator(epoch)
            self.reader.open()
            self.ledger.emit(
                "C2H_SESSION_OPENED",
                node=self.reader.node,
                epoch=epoch,
                retained_single_descriptor=True,
            )

            t3, t3_primary, _ = self.run_fixed(
                "T3",
                1,
                self.private / "G2B_R3_T3_FIRST_RECORD.bin",
                self.private / "G2B_R3_T3_DRAIN_RECORDS.bin",
                FIRST_RECORD_TIMEOUT_SECONDS,
            )
            first_payload_hash = None
            if t3_primary.first_header is not None:
                first_payload_hash = t3_primary.payload_hasher.hexdigest().upper()  # type: ignore[attr-defined]
            t3["first_record_bytes"] = RECORD_BYTES
            t3["first_payload_sha256"] = first_payload_hash
            write_exclusive_json(
                self.public / "G2B_R3_T3_TOOL_REPORT.json", t3
            )
            self.validator.mark_disabled_interval()

            finite_frames = FrameCollector()
            t4, _, _ = self.run_fixed(
                "T4",
                FINITE_RECORDS,
                self.private / "G2B_R3_T4_PRIMARY_2500_RECORDS.bin",
                self.private / "G2B_R3_T4_DRAIN_RECORDS.bin",
                FINITE_TIMEOUT_SECONDS,
                finite_frames,
            )
            if finite_frames.complete_frames == 0 or finite_frames.first_frame is None:
                raise GateFailure("T4_COMPLETE_FRAME_NOT_RECONSTRUCTED", "no frame")
            raw_frame = finite_frames.first_frame
            png_frame = uyvy_to_png(raw_frame)
            raw_path = self.private / "G2B_R3_T4_FIRST_COMPLETE_1920x1080_UYVY.raw"
            png_path = self.private / "G2B_R3_T4_FIRST_COMPLETE_1920x1080.png"
            write_exclusive_bytes(raw_path, raw_frame)
            write_exclusive_bytes(png_path, png_frame)
            t4["frame_reconstruction"] = {
                **finite_frames.summary(),
                "geometry": "1920x1080 UYVY",
                "raw_bytes": len(raw_frame),
                "raw_sha256": sha256_bytes(raw_frame),
                "png_bytes": len(png_frame),
                "png_sha256": sha256_bytes(png_frame),
                "conversion": "BT.601 limited-range integer UYVY-to-RGB; "
                              "lossless PNG encoding of converted RGB",
                "raw_publicly_publishable": False,
                "png_publicly_publishable": False,
            }
            write_exclusive_json(
                self.public / "G2B_R3_T4_TOOL_REPORT.json", t4
            )
            self.validator.mark_disabled_interval()

            t5 = self.run_continuous()
            write_exclusive_json(
                self.public / "G2B_R3_T5_TOOL_REPORT.json", t5
            )
            final_idle = require_idle_clean(self.mmio, "FINAL")
            final_snapshot = self.mmio.snapshot("FINAL")
            final = {
                "result": "PASS",
                "one_channel_fixed_live_ahd_path": "PASS",
                "transport_abi": "AHD_C2H_TRANSPORT_ABI_V1",
                "persistent_single_c2h_descriptor": True,
                "reset_stream_state_used": False,
                "stream_disabled": True,
                "dma_quiescent": True,
                "pending_partial_bytes": len(self.framer.pending),
                "final_idle": final_idle,
                "final_snapshot": final_snapshot,
                "hardware_throughput_288_MB_s": "NOT_PROVEN",
                "raw_video_published": False,
            }
            write_exclusive_json(
                self.public / "G2B_R3_CAPTURE_TOOL_FINAL.json", final
            )
            self.ledger.emit("R3_CAPTURE_TOOL_PASS")
            return 0
        except BaseException as exc:
            rollback = self.emergency_disable_and_drain() if self.reader.fd >= 0 else {
                "disable_attempted": False,
                "quiescent": False,
                "reason": "C2H reader not opened",
            }
            failure = {
                "result": "FAIL",
                "exception_type": type(exc).__name__,
                "first_blocker": exc.code if isinstance(exc, GateFailure)
                else "TOOL_INTERNAL_EXCEPTION",
                "detail": exc.detail if isinstance(exc, GateFailure) else repr(exc),
                "safe_rollback": rollback,
                "reset_stream_state_used": False,
                "raw_video_published": False,
            }
            try:
                write_exclusive_json(
                    self.public / "G2B_R3_CAPTURE_TOOL_FAILURE.json", failure
                )
            except BaseException:
                pass
            self.ledger.emit(
                "R3_CAPTURE_TOOL_FAIL",
                first_blocker=failure["first_blocker"],
            )
            print(json.dumps(failure, sort_keys=True), file=sys.stderr)
            return 2
        finally:
            self.reader.close()
            self.ledger.emit("C2H_SESSION_CLOSED")
            self.ledger.close()


def build_test_record(
    *,
    epoch: int,
    frame: int,
    line: int,
    capture: int,
    attempt: int,
    global_sequence: int,
    slot: int,
    generation: int,
    discontinuity: bool = False,
    payload: bytes | None = None,
) -> bytes:
    if payload is None:
        payload = bytes(
            (line + offset) & 0xFF for offset in range(PAYLOAD_BYTES)
        )
    flags = FLAG_VALID | (FLAG_SOF if line == 0 else 0)
    if discontinuity:
        flags |= FLAG_DISCONTINUITY
    words = (
        MAGIC, RECORD_VERSION, epoch, frame, line, capture, PAYLOAD_BYTES,
        flags, 1, ((generation & 0xFFFFFF) << 8) | slot,
        0, 0, 0, 0, attempt, global_sequence,
    )
    blob = bytearray(RECORD_BYTES)
    HEADER_STRUCT.pack_into(blob, 0, *words)
    blob[HEADER_BYTES:PADDING_FIRST] = payload
    return bytes(blob)


def self_test() -> int:
    epoch = 7
    validator = PersistentValidator(epoch)
    framer = FixedBoundaryFramer()
    collector = FrameCollector()
    records: list[bytes] = []
    records.append(build_test_record(
        epoch=epoch, frame=1, line=500, capture=500,
        attempt=0, global_sequence=0, slot=0, generation=1,
        discontinuity=True,
    ))
    records.append(build_test_record(
        epoch=epoch, frame=2, line=1079, capture=1135,
        attempt=1, global_sequence=1, slot=1, generation=1,
        discontinuity=True,
    ))
    capture = 1136
    attempt = 2
    global_sequence = 2
    for line in range(LINES_PER_FRAME):
        records.append(build_test_record(
            epoch=epoch,
            frame=3,
            line=line,
            capture=capture,
            attempt=attempt,
            global_sequence=global_sequence,
            slot=global_sequence % 4,
            generation=1 + global_sequence // 4,
        ))
        capture = u32(capture + 1)
        attempt = u32(attempt + 1)
        global_sequence = u32(global_sequence + 1)
    stream = b"".join(records)
    split_pattern = (1, 7, 4093, 8192, 13, 65536, 5, 32768)
    offset = 0
    split_index = 0
    parsed_count = 0
    while offset < len(stream):
        length = min(split_pattern[split_index % len(split_pattern)],
                     len(stream) - offset)
        for blob in framer.feed(stream[offset:offset + length]):
            if parsed_count == 1:
                validator.mark_disabled_interval()
            parsed = validator.accept(blob)
            collector.push(parsed)
            parsed_count += 1
        offset += length
        split_index += 1
    if framer.pending or parsed_count != len(records) or \
            collector.complete_frames != 1 or collector.first_frame is None:
        raise AssertionError("framer/validator/frame self-test failed")
    png = uyvy_to_png(collector.first_frame)
    if not png.startswith(b"\x89PNG\r\n\x1a\n"):
        raise AssertionError("PNG signature")
    ihdr_width, ihdr_height = struct.unpack_from(">II", png, 16)
    if (ihdr_width, ihdr_height) != (PIXELS_PER_LINE, LINES_PER_FRAME):
        raise AssertionError("PNG geometry")
    corrupted = bytearray(records[-1])
    corrupted[-1] = 1
    try:
        structural_parse(bytes(corrupted))
    except RecordFailure:
        pass
    else:
        raise AssertionError("nonzero padding accepted")
    print(json.dumps({
        "R3_C2H_SELF_TEST": "PASS",
        "partial_read_chunks": split_index,
        "records_validated": parsed_count,
        "frame_bytes": len(collector.first_frame),
        "png_bytes": len(png),
        "record_boundary_bytes": RECORD_BYTES,
    }, sort_keys=True))
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("self-test")
    run = subparsers.add_parser("run-all")
    run.add_argument("--user-node", required=True)
    run.add_argument("--c2h-node", required=True)
    run.add_argument("--bdf", required=True)
    run.add_argument("--mmio-tool", required=True)
    run.add_argument("--mmio-log", required=True)
    run.add_argument("--artifact-root", required=True)
    args = parser.parse_args(argv)
    if args.command == "run-all":
        user = USER_NODE_RE.fullmatch(args.user_node)
        c2h = C2H_NODE_RE.fullmatch(args.c2h_node)
        if not user or not c2h or user.group(1) != c2h.group(1):
            parser.error("user and C2H nodes must share exact dynamic xdmaN")
        if not BDF_RE.fullmatch(args.bdf):
            parser.error("BDF must be DDDD:BB:SS.F")
        if args.bdf.lower() != "0000:01:00.0":
            parser.error("R3 exact AHD BDF must be 0000:01:00.0")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.command == "self-test":
        return self_test()
    return SessionRunner(args).run()


if __name__ == "__main__":
    raise SystemExit(main())
