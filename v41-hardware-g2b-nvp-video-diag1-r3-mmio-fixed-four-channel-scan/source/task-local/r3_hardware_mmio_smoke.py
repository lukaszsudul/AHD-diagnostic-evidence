#!/usr/bin/env python3
"""Bounded read-only identity plus exact 32-cycle R3 write/read smoke test."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import signal
import struct
import time
from typing import Any


TASK = "G2B-NVP-VIDEO-DIAG1-R3"
MAGIC = 0x4E565034
VERSION = 0x00010002
CAPABILITIES = 0x00000BFF
BUILD_FLAGS = 0x00000402
EXPECTED_GIT_SHA = "fc37d815b5d64ef90dfbd99c57ae4cc09567b56f"


class GateError(RuntimeError):
    pass


def require(value: bool, message: str) -> None:
    if not value:
        raise GateError(message)


class MmioTimeout(GateError):
    pass


class BoundedMmio:
    def __init__(self, path: str, timeout_seconds: float = 2.0) -> None:
        flags = os.O_RDWR | os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        self.fd = os.open(path, flags)
        self.timeout_seconds = timeout_seconds
        self.rows: list[dict[str, Any]] = []
        self.sequence = 0

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def _handler(self, _signum: int, _frame: Any) -> None:
        raise MmioTimeout("NVP_DIAG1_R3_MMIO_OPERATION_TIMEOUT")

    def _bounded(self, function):
        previous = signal.signal(signal.SIGALRM, self._handler)
        signal.setitimer(signal.ITIMER_REAL, self.timeout_seconds)
        try:
            return function()
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0.0)
            signal.signal(signal.SIGALRM, previous)

    def read(self, offset: int, iteration: int, phase: str) -> int:
        started = time.monotonic_ns()
        self.sequence += 1
        try:
            raw = self._bounded(lambda: os.pread(self.fd, 4, offset))
            require(len(raw) == 4, "NVP_DIAG1_R3_SHORT_MMIO_READ")
            value = struct.unpack("<I", raw)[0]
            require(value != 0xFFFFFFFF,
                    "NVP_DIAG1_R3_POST_WRITE_FFFFFFFF_READ")
            result = "PASS"
            return value
        except BaseException as exc:
            value = None
            result = f"FAIL:{type(exc).__name__}:{exc}"
            raise
        finally:
            self.rows.append({
                "Sequence": self.sequence,
                "Iteration": iteration,
                "Phase": phase,
                "Operation": "READ",
                "Offset": f"0x{offset:04X}",
                "Value": "" if value is None else f"0x{value:08X}",
                "DurationUs": round((time.monotonic_ns() - started) / 1000.0, 3),
                "Result": result,
            })

    def write(self, offset: int, value: int, iteration: int, phase: str) -> None:
        started = time.monotonic_ns()
        self.sequence += 1
        try:
            count = self._bounded(
                lambda: os.pwrite(self.fd, struct.pack("<I", value), offset))
            require(count == 4, "NVP_DIAG1_R3_SHORT_MMIO_WRITE")
            result = "PASS"
        except BaseException as exc:
            result = f"FAIL:{type(exc).__name__}:{exc}"
            raise
        finally:
            self.rows.append({
                "Sequence": self.sequence,
                "Iteration": iteration,
                "Phase": phase,
                "Operation": "WRITE",
                "Offset": f"0x{offset:04X}",
                "Value": f"0x{value:08X}",
                "DurationUs": round((time.monotonic_ns() - started) / 1000.0, 3),
                "Result": result,
            })


def write_json_new(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv_new(path: Path, rows: list[dict[str, Any]]) -> None:
    fields = ("Sequence", "Iteration", "Phase", "Operation", "Offset",
              "Value", "DurationUs", "Result")
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
        handle.flush()
        os.fsync(handle.fileno())


def read_boot_id() -> str:
    return Path("/proc/sys/kernel/random/boot_id").read_text(
        encoding="ascii").strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", default="/dev/xdma0_user")
    parser.add_argument("--output-root", required=True, type=Path)
    args = parser.parse_args()
    args.output_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    identity_path = args.output_root / "runtime-identity.json"
    csv_path = args.output_root / "hardware-mmio-write-read.csv"
    result_path = args.output_root / "hardware-mmio-write-read-result.json"
    require(not any(path.exists() for path in (identity_path, csv_path, result_path)),
            "NVP_DIAG1_R3_SMOKE_OUTPUT_ALREADY_EXISTS")

    mmio = BoundedMmio(args.user_node)
    result: dict[str, Any] = {
        "task": TASK, "result": "FAIL", "iterations_requested": 32,
        "iterations_passed": 0,
    }
    try:
        boot_before = read_boot_id()
        product_words = {
            offset: mmio.read(offset, 0, "READ_ONLY_RUNTIME_IDENTITY")
            for offset in range(0x0000, 0x0034, 4)
        }
        observed_git_sha = "".join(
            f"{product_words[offset]:08x}" for offset in range(0x0010, 0x0024, 4)
        )
        transport_magic = mmio.read(0x3800, 0, "READ_ONLY_RUNTIME_IDENTITY")
        transport_abi = mmio.read(0x3804, 0, "READ_ONLY_RUNTIME_IDENTITY")
        control = mmio.read(0x380C, 0, "READ_ONLY_RUNTIME_IDENTITY")
        transport_status = mmio.read(0x3810, 0, "READ_ONLY_RUNTIME_IDENTITY")
        diag_magic = mmio.read(0x3C00, 0, "READ_ONLY_RUNTIME_IDENTITY")
        diag_version = mmio.read(0x3C04, 0, "READ_ONLY_RUNTIME_IDENTITY")
        diag_caps = mmio.read(0x3C08, 0, "READ_ONLY_RUNTIME_IDENTITY")
        autoinit_status = mmio.read(0x008C, 0, "READ_ONLY_RUNTIME_IDENTITY")
        autoinit_nack = mmio.read(0x0090, 0, "READ_ONLY_RUNTIME_IDENTITY")
        autoinit_timeout = mmio.read(0x0094, 0, "READ_ONLY_RUNTIME_IDENTITY")
        i2c_before = mmio.read(0x3C50, 0, "PRE_SMOKE_I2C_COUNT")

        require(product_words[0x0000] == 0xA40A0C07,
                "NVP_DIAG1_R3_RUNTIME_BLOCK_ID_MISMATCH")
        require(product_words[0x0004] == 0x0000400B,
                "NVP_DIAG1_R3_RUNTIME_PROTOCOL_MISMATCH")
        require(product_words[0x0008] == 0x00031002,
                "NVP_DIAG1_R3_RUNTIME_PRODUCT_CAPABILITIES_MISMATCH")
        require(product_words[0x000C] == 0x00010000,
                "NVP_DIAG1_R3_RUNTIME_BUILD_SCHEMA_MISMATCH")
        require(observed_git_sha == EXPECTED_GIT_SHA,
                "NVP_DIAG1_R3_RUNTIME_GIT_SHA_MISMATCH")
        require(product_words[0x0024] == 0x07E90002,
                "NVP_DIAG1_R3_RUNTIME_VIVADO_VERSION_MISMATCH")
        require(product_words[0x002C] == BUILD_FLAGS,
                "NVP_DIAG1_R3_RUNTIME_BUILD_FLAGS_MISMATCH")
        require(product_words[0x0030] == 0x58444D41,
                "NVP_DIAG1_R3_RUNTIME_TRANSPORT_SIGNATURE_MISMATCH")
        require(transport_magic == 0x43324831 and transport_abi == 0x00010000,
                "NVP_DIAG1_R3_TRANSPORT_IDENTITY_MISMATCH")
        require(control == 0 and (transport_status & 0x10F) == 0x004,
                "NVP_DIAG1_R3_PRE_SMOKE_NOT_QUIESCENT")
        require(diag_magic == MAGIC and diag_version == VERSION and
                diag_caps == CAPABILITIES and (diag_caps & (1 << 11)),
                "NVP_DIAG1_R3_DIAGNOSTIC_IDENTITY_MISMATCH")
        require((autoinit_status & 0xF) == 0x9 and autoinit_nack == 0 and
                autoinit_timeout == 0,
                "NVP_DIAG1_R3_AUTOINIT_IDENTITY_MISMATCH")

        identity = {
            "task": TASK, "result": "PASS", "read_only": True,
            "git_sha": observed_git_sha,
            "build_flags": f"0x{product_words[0x002C]:08X}",
            "transport_magic": f"0x{transport_magic:08X}",
            "transport_abi_version": f"0x{transport_abi:08X}",
            "diag_magic": f"0x{diag_magic:08X}",
            "diag_version": f"0x{diag_version:08X}",
            "diag_capabilities": f"0x{diag_caps:08X}",
            "mmio_write_response_protocol_fixed": True,
            "current_session_snapshot": True,
            "host_owned_session_history": True,
            "onchip_16_session_history": False,
            "autoinit_status": f"0x{autoinit_status:08X}",
            "autoinit_nack_count": autoinit_nack,
            "autoinit_timeout_count": autoinit_timeout,
            "boot_id_sha256": hashlib.sha256(
                boot_before.encode("ascii")).hexdigest().upper(),
        }
        write_json_new(identity_path, identity)

        for iteration in range(1, 33):
            require(mmio.read(0x3C00, iteration, "PRE_CLEAR_MAGIC") == MAGIC,
                    "NVP_DIAG1_R3_MAGIC_CHANGED")
            require(mmio.read(0x3C04, iteration, "PRE_CLEAR_VERSION") == VERSION,
                    "NVP_DIAG1_R3_VERSION_CHANGED")
            mmio.read(0x3C10, iteration, "PRE_CLEAR_STATUS")
            mmio.read(0x3C18, iteration, "PRE_CLEAR_STATE")
            mmio.read(0x3C14, iteration, "PRE_CLEAR_ERROR")
            mmio.write(0x3C0C, 0x00000001, iteration, "DIAG_CLEAR")
            status = mmio.read(0x3C10, iteration, "POST_CLEAR_STATUS")
            state = mmio.read(0x3C18, iteration, "POST_CLEAR_STATE")
            error = mmio.read(0x3C14, iteration, "POST_CLEAR_ERROR")
            require(mmio.read(0x3C00, iteration, "POST_CLEAR_MAGIC") == MAGIC,
                    "NVP_DIAG1_R3_POST_CLEAR_MAGIC_CHANGED")
            require(mmio.read(0x3C04, iteration, "POST_CLEAR_VERSION") == VERSION,
                    "NVP_DIAG1_R3_POST_CLEAR_VERSION_CHANGED")
            valid = mmio.read(0x3D20, iteration, "POST_CLEAR_RESULT_VALID")
            require(state == 0 and error == 0 and valid == 0,
                    "NVP_DIAG1_R3_POST_CLEAR_STATE_INVALID")
            require((status & (0x002 | 0x004 | 0x010 | 0x100)) == 0,
                    "NVP_DIAG1_R3_POST_CLEAR_STATUS_INVALID")
            result["iterations_passed"] = iteration

        i2c_after = mmio.read(0x3C50, 0, "POST_SMOKE_I2C_COUNT")
        boot_after = read_boot_id()
        require(i2c_after == i2c_before,
                "NVP_DIAG1_R3_CLEAR_CHANGED_I2C_TRANSACTION_COUNT")
        require(boot_after == boot_before,
                "NVP_DIAG1_R3_UNEXPECTED_REBOOT_DURING_MMIO_TEST")
        result.update({
            "result": "PASS",
            "i2c_transaction_count_before": i2c_before,
            "i2c_transaction_count_after": i2c_after,
            "post_write_ffffffff_reads": 0,
            "post_write_mmio_timeouts": 0,
            "short_reads": 0,
            "short_writes": 0,
            "unexpected_reboot": False,
            "boot_id_unchanged": True,
        })
    except BaseException as exc:
        result["blocker"] = f"{type(exc).__name__}:{exc}"
    finally:
        mmio.close()
        write_csv_new(csv_path, mmio.rows)
        write_json_new(result_path, result)

    print(json.dumps({
        "result": result["result"],
        "iterations_passed": result["iterations_passed"],
        "blocker": result.get("blocker"),
    }, sort_keys=True), flush=True)
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())

