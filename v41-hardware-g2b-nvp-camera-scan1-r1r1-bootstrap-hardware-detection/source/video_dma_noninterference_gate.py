#!/usr/bin/env python3
# SANITIZED PUBLICATION COPY; executed-source SHA-256: 62026C0B829C40C81F453F8C29569B4D8EC3AB080892843E28F7EC1328A7E7D5
"""One governed SCAN1 video/DMA noninterference sequence.

The capture controller, native rolling-AIO helper, ABI parser, frame validator,
and VBI-tail contract are byte-exact files from the accepted R3R2R1 closed
runtime bundle.  This task-local wrapper only binds that controller to the
current held lock and starts one SCAN1 ONESHOT immediately before the overlap
capture's STREAM_ENABLE write.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import selectors
import struct
import subprocess
import sys
import time
from types import ModuleType
from typing import Any


P = Path
TASK = "G2B-NVP-CAMERA-SCAN1-R1R1"
ROOT = P("/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1/20260911T202728Z")
PRIVATE = ROOT / "private"
BUNDLE = ROOT / "runtime-bundle"
LOCK = P("/home/DUT_USER_REDACTED/vcde_artifacts/.ahd_g2b_nvp_camera_scan1_r1_20260911T152909Z.lock/receipt")
DEVICE = P("/dev/xdma0_user")
C2H = P("/dev/xdma0_c2h_0")
ENDPOINT = P("/sys/bus/pci/devices/0000:01:00.0")
ROOT_PORT = P("/sys/bus/pci/devices/0000:00:01.1")
EXPECTED_BOOT = "cf1515d9-7238-4bf0-9c7d-7196efb2e762"
EXPECTED_GIT_SHA = "c7e16fa3da26545cef960a6c75427a3614c4b655"
EXPECTED_BUILD_FLAGS = 0x00000802
EXPECTED_CAPTURE_SOURCE_TASK = "G2B-NVP-VIDEO-DIAG1-R3R2"
ACCEPTED_CAPTURE_BUNDLE_MANIFEST_SHA256 = "0EC4B48D2C7665F71B8E99C0C0F766AFBE78E35AA89A4A52956D5CF400C9F787"
OWNER_REPLY = PRIVATE / "owner-reply-scan1-a.txt"
OWNER_REPLY_SHA256 = "66C41CBABD981C6E4EBF5F561CA4B9D61961BAD69B475FD2601B0A07C2C3E865"
BASELINE_REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_GATE.json"
SUPPORT = PRIVATE / "repetition_scan_gate.py"
SUPPORT_SHA256 = "6E98B170DAB7A1A3608E8935C5EF044B45AB3A30CA5513D44547D1B346048381"
ORCHESTRATOR = PRIVATE / "video_dma_noninterference_gate.py"
CAPTURE_PRIVATE_ROOT = PRIVATE / "video-dma-noninterference"
CAPTURE_LOG_ROOT = ROOT / "logs/video-dma-noninterference"
SCAN_PREFIX = ROOT / "scanner/noninterference/overlap-scan"
SCAN_RESULT = CAPTURE_LOG_ROOT / "overlap-scan-result.json"
LOCK_ADAPTER = PRIVATE / "video-dma-lock-adapter"
REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_VIDEO_DMA_NONINTERFERENCE.json"
STATE_OUTPUT = ROOT / "campaign/state-after-video-dma-noninterference.json"
LOG_OUTPUT = ROOT / "logs/video-dma-noninterference-gate.json"
CAPTURE_NAMES = ("reference", "overlap", "post")

CAPTURE_FILES = {
    "controller_nvp_capture_r3r2.py": "7AC6B0028DBC0B0BC89E464897994531CDB3E188D7C300170B0577C57DF33D88",
    "availability_classifier_r3r2.py": "87BE163DE189C95E7789BF15025F836E6E9012EFAD58973C8EE40FFE4D8E9E0A",
    "validate_nvp_capture_r3r2.py": "CBAEFF14DACA8237F52683743FA1BD4389E359EBD26B4034243310CE067B2D3D",
    "abi_v1.py": "2939FC522A2D9679BB720F287AC022FC48FF042CE06E20877F8E686F35909F1E",
    "abi_v1_r3r2.py": "B40345CED07ADFAD5E41D2C9CDAE3A3CF0FC016B3C9F4895552CEBBA60C6C7CA",
    "frame_reconstruct_nvp_capture.py": "C394C7A212FCE1EC5686878016F887DF02A68C209994A4A2A4681B54FDA89AEF",
    "vbi_tail_contract_r3r2.py": "A77824073D926989B1BF40273480E5E3584905C0869E3D799E7B737DAA24804F",
    "V41_C2H_TRANSPORT_ABI_V1.json": "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6",
    "V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json": "B9F88485DB38CE03EB05296E9CD3A136FCEE24D850C41B3D3A0DAABFAA72A36B",
    "xdma_c2h_rolling_4k_diag1": "FE50853C600098836548CF6C198012566A80E1C43A46F452B8B2965F806C5D52",
}


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def sha256(path: P) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def write_json_new(path: P, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def load_key_value_receipt(path: P) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        key, value = line.split("=", 1)
        require(key not in values, "DUT_LOCK_DUPLICATE_KEY")
        values[key] = value
    return values


def verify_capture_files() -> dict[str, dict[str, object]]:
    rows: dict[str, dict[str, object]] = {}
    for name, expected in CAPTURE_FILES.items():
        path = PRIVATE / name
        require(path.is_file(), f"ACCEPTED_CAPTURE_FILE_MISSING:{name}")
        actual = sha256(path)
        require(actual == expected, f"ACCEPTED_CAPTURE_FILE_SHA256:{name}")
        rows[name] = {"path": str(path), "bytes": path.stat().st_size,
                      "sha256": actual, "result": "PASS"}
    return rows


def load_module(name: str, path: P) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None,
            f"MODULE_IMPORT_SPEC_FAILED:{name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    require(P(module.__file__).resolve(strict=True) == path.resolve(strict=True),
            f"MODULE_ORIGIN_FAILED:{name}")
    return module


def load_support() -> ModuleType:
    require(sha256(SUPPORT) == SUPPORT_SHA256, "SCAN_SUPPORT_SHA256_MISMATCH")
    return load_module("scan1_noninterference_support", SUPPORT)


def verify_common_state(support: ModuleType, expected_generation: int,
                        label: str) -> dict[str, object]:
    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
            f"BOOT_ID_DRIFT:{label}")
    require(P("/sys/module/xdma_ahd_pcie").is_dir(),
            f"EXACT_DRIVER_NOT_RETAINED:{label}")
    require(ENDPOINT.is_dir() and (ENDPOINT / "driver").resolve().name == "xdma_ahd_pcie",
            f"ENDPOINT_DRIVER_MISMATCH:{label}")
    require(DEVICE.is_char_device() and C2H.is_char_device(),
            f"XDMA_NODE_NOT_CHAR_DEVICE:{label}")
    require(not support.open_xdma_fds(), f"PREEXISTING_XDMA_FD:{label}")
    aio = int(P("/proc/sys/fs/aio-nr").read_text().strip())
    require(aio == 0, f"PENDING_AIO:{label}:{aio}")
    fd = os.open(str(DEVICE), os.O_RDWR | getattr(os, "O_SYNC", 0))
    try:
        def read32(offset: int) -> int:
            raw = os.pread(fd, 4, offset)
            require(len(raw) == 4, f"SHORT_STATE_READ:{label}:{offset:#x}")
            return struct.unpack("<I", raw)[0]
        status = read32(0x12004)
        generation = read32(0x1201C)
        autoinit = read32(0x1006C)
        autoinit_detail = read32(0x10090)
        transport_control = read32(0x0380C)
        transport_status = read32(0x03810)
    finally:
        os.close(fd)
    require(status == 0x11, f"SCANNER_NOT_IDLE:{label}:{status:#x}")
    require(generation == expected_generation,
            f"SCANNER_GENERATION:{label}:{generation}:{expected_generation}")
    require(autoinit & 0x3 == 0x1 and autoinit_detail == 0,
            f"AUTOINIT_NOT_CLEAN:{label}")
    require(transport_control == 0 and transport_status & 0x10F == 0x004,
            f"TRANSPORT_NOT_QUIESCENT:{label}")
    return {"label": label, "scanner_status": status,
            "scanner_generation": generation, "autoinit_status": autoinit,
            "autoinit_detail": autoinit_detail,
            "transport_control": transport_control,
            "transport_status": transport_status, "pending_aio": aio,
            "open_xdma_fds": 0}


def await_json_line(stream: Any, timeout_seconds: float) -> dict[str, Any]:
    selector = selectors.DefaultSelector()
    selector.register(stream, selectors.EVENT_READ)
    deadline = time.monotonic() + timeout_seconds
    try:
        while time.monotonic() < deadline:
            events = selector.select(max(0.0, deadline - time.monotonic()))
            if not events:
                continue
            line = stream.readline()
            require(line, "OVERLAP_SCAN_WORKER_STDOUT_CLOSED")
            return json.loads(line)
    finally:
        selector.close()
    raise RuntimeError("OVERLAP_SCAN_WORKER_START_TIMEOUT")


def pixel_summary(path: P) -> dict[str, object]:
    raw = path.read_bytes()
    require(len(raw) == 1920 * 1080 * 2, "QUALIFIED_FRAME_GEOMETRY_BYTES")
    pairs = (raw[index:index + 4] for index in range(0, len(raw), 4))
    counts = Counter(pairs)
    dominant, dominant_count = counts.most_common(1)[0]
    uniform = len(counts) == 1
    return {
        "geometry": "1920x1080_UYVY",
        "bytes": len(raw),
        "sha256": sha256(path),
        "pixel_classification": (f"UNIFORM_UYVY_{dominant.hex().upper()}"
                                 if uniform else "NONUNIFORM_UYVY"),
        "dominant_pixel_class": dominant.hex().upper(),
        "dominant_pair_count": dominant_count,
        "pair_count": len(raw) // 4,
        "unique_pair_count": len(counts),
        "uniform": uniform,
    }


def validate_capture_contract(name: str, controller: dict[str, Any],
                              validation: dict[str, Any]) -> dict[str, Any]:
    primary = controller.get("primary_completion", {})
    rolling = controller.get("rolling_metrics", {})
    deltas = controller.get("counter_deltas", {})
    require(controller.get("result") == "PASS" and
            controller.get("capture_result") == "PASS" and
            controller.get("capture_records") == 2500 and
            controller.get("capture_bytes") == 10_240_000,
            f"CAPTURE_CONTROLLER_RESULT:{name}")
    require(primary.get("primary_exact_completions") == 2500 and
            primary.get("primary_short_completions") == 0 and
            primary.get("primary_failed_completions") == 0 and
            primary.get("primary_duplicate_completions") == 0 and
            primary.get("primary_pending") == 0 and
            primary.get("pending_aio") == 0 and
            primary.get("primary_bytes") == 10_240_000,
            f"CAPTURE_EXACT_COMPLETIONS:{name}")
    require(rolling.get("pending") == 0 and
            controller.get("final_pending_aio") == 0 and
            controller.get("physical_quiescence", {}).get("result") == "PASS" and
            controller.get("native_helper_absent") is True,
            f"CAPTURE_FINAL_QUIESCENCE:{name}")
    require(deltas.get("dropped") == 0 and deltas.get("overflow") == 0,
            f"CAPTURE_TRANSPORT_LOSS:{name}")
    require(validation.get("result") == "PASS" and
            validation.get("record_path_integrity") == "PASS" and
            validation.get("active_frame_and_transport_integrity") == "PASS" and
            validation.get("bounded_route_specific_vbi_tail") == "PASS" and
            validation.get("frame_reconstruction") == "PASS" and
            validation.get("qualified_frame_missing_lines") == 0 and
            validation.get("qualified_frame_duplicate_lines") == 0 and
            validation.get("qualified_frame_synthetic_lines") == 0 and
            validation.get("record_integrity_failures") == 0 and
            validation.get("overflow_flag_records") == 0 and
            validation.get("malformed_preceding_flag_records") == 0 and
            validation.get("source_malformed_snapshot_delta") == 0 and
            validation.get("source_dropped_snapshot_delta") == 0 and
            validation.get("vertical_boundary_malformed_events") == 0 and
            validation.get("vertical_boundary_source_drops") == 0 and
            validation.get("line_0_present") is True and
            validation.get("line_0_sof") is True,
            f"CAPTURE_VALIDATION_CONTRACT:{name}")
    frame = P(controller["primary_file"]).parent / "qualified-frame.uyvy"
    require(frame.is_file(), f"QUALIFIED_FRAME_MISSING:{name}")
    pixels = pixel_summary(frame)
    return {
        "name": name,
        "result": "PASS",
        "controller_result": str(CAPTURE_LOG_ROOT / name / "controller-result.json"),
        "controller_result_sha256": sha256(CAPTURE_LOG_ROOT / name / "controller-result.json"),
        "validation_result": str(CAPTURE_LOG_ROOT / name / "validation-result.json"),
        "validation_result_sha256": sha256(CAPTURE_LOG_ROOT / name / "validation-result.json"),
        "primary_file": controller["primary_file"],
        "primary_file_bytes": controller["primary_file_bytes"],
        "primary_file_sha256": controller["primary_file_sha256"],
        "exact_completions": 2500,
        "record_integrity": "PASS",
        "active_frame_integrity": "PASS",
        "bounded_route_specific_vbi": "PASS",
        "complete_frame_1920x1080": "PASS",
        "overflow": 0,
        "malformed_preceding": 0,
        "source_drop": 0,
        "pending_aio_final": 0,
        "physical_quiescence": "PASS",
        "counter_deltas": deltas,
        "frame": pixels,
        "frame_source_sequence": validation.get("frame_source_sequence"),
        "frame_epoch": validation.get("frame_epoch"),
        "capture_sequence_delta_values": validation.get("capture_sequence_delta_values"),
        "vertical_tail_interval_values": validation.get("vertical_tail_interval_values"),
        "primary_complete_to_disable_us": controller.get("primary_complete_to_disable_us"),
    }


def run_validator(name: str, private_dir: P, logs_dir: P) -> dict[str, Any]:
    command = [
        sys.executable, str(PRIVATE / "validate_nvp_capture_r3r2.py"),
        "--abi", str(PRIVATE / "V41_C2H_TRANSPORT_ABI_V1.json"),
        "--primary", str(private_dir / "primary.bin"),
        "--controller-result", str(logs_dir / "controller-result.json"),
        "--private-dir", str(private_dir),
        "--logs-dir", str(logs_dir),
    ]
    env = os.environ.copy()
    env["PYTHONPATH"] = str(PRIVATE)
    completed = subprocess.run(command, cwd=PRIVATE, env=env,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, timeout=60.0, check=False)
    require(completed.returncode == 0 and not completed.stderr.strip(),
            f"CAPTURE_VALIDATOR_EXIT:{name}:{completed.returncode}")
    result_path = logs_dir / "validation-result.json"
    require(result_path.is_file(), f"CAPTURE_VALIDATION_RESULT_MISSING:{name}")
    result = json.loads(result_path.read_text(encoding="utf-8"))
    result["validator_stdout"] = completed.stdout.strip()
    return result


def run_capture(capture_module: ModuleType, name: str,
                *, overlap: bool) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    private_dir = CAPTURE_PRIVATE_ROOT / name
    logs_dir = CAPTURE_LOG_ROOT / name
    require(not private_dir.exists() and not logs_dir.exists(),
            f"CAPTURE_OUTPUT_PREEXISTS:{name}")
    args = argparse.Namespace(
        user_node=str(DEVICE), c2h_node=str(C2H),
        native_helper=str(PRIVATE / "xdma_c2h_rolling_4k_diag1"),
        private_dir=str(private_dir), logs_dir=str(logs_dir),
        linux_lock=str(LOCK_ADAPTER), expected_git_sha=EXPECTED_GIT_SHA,
        expected_build_flags=EXPECTED_BUILD_FLAGS,
    )
    hook: dict[str, Any] = {"overlap_requested": overlap,
                            "scanner_worker_started": False}
    original_write = capture_module.Mmio.write
    worker: subprocess.Popen[str] | None = None

    if overlap:
        def overlap_write(mmio_self: Any, offset: int, value: int,
                          purpose: str, precondition: str) -> int:
            nonlocal worker
            if purpose != "STREAM_ENABLE":
                return original_write(mmio_self, offset, value, purpose, precondition)
            require(worker is None, "OVERLAP_SCANNER_STARTED_MORE_THAN_ONCE")
            worker = subprocess.Popen(
                [sys.executable, str(ORCHESTRATOR), "--scan-worker"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                bufsize=1, close_fds=True,
            )
            require(worker.stdout is not None, "OVERLAP_WORKER_STDOUT_MISSING")
            event = await_json_line(worker.stdout, 5.0)
            require(event.get("event") == "SCAN1_ONESHOT_STARTED" and
                    event.get("generation_before") == 262,
                    "OVERLAP_SCAN_START_EVENT_INVALID")
            hook["scanner_worker_started"] = True
            hook["scan_start_event"] = event
            hook["transport_enable_call_monotonic_ns"] = time.monotonic_ns()
            completed_ns = original_write(mmio_self, offset, value, purpose, precondition)
            hook["transport_enable_completed_monotonic_ns"] = completed_ns
            return completed_ns

        capture_module.Mmio.write = overlap_write

    try:
        controller = capture_module.run(args)
    finally:
        capture_module.Mmio.write = original_write

    if worker is not None:
        try:
            remainder, stderr = worker.communicate(timeout=8.0)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError("OVERLAP_SCAN_WORKER_COMPLETION_TIMEOUT") from exc
        hook["scanner_worker_exit_code"] = worker.returncode
        hook["scanner_worker_stdout_after_start"] = remainder.strip()
        hook["scanner_worker_stderr"] = stderr.strip()
        require(worker.returncode == 0 and not stderr.strip(),
                f"OVERLAP_SCAN_WORKER_EXIT:{worker.returncode}")
        require(SCAN_RESULT.is_file(), "OVERLAP_SCAN_RESULT_MISSING")
        scan_result = json.loads(SCAN_RESULT.read_text(encoding="utf-8"))
        require(scan_result.get("result") == "PASS", "OVERLAP_SCAN_RESULT_FAILED")
        hook["scan_result"] = scan_result
        hook["scan_result_sha256"] = sha256(SCAN_RESULT)
        require(int(hook["scan_start_event"]["start_completed_monotonic_ns"]) <=
                int(hook["transport_enable_completed_monotonic_ns"]) <
                int(scan_result["done_observed_monotonic_ns"]),
                "SCANNER_CAPTURE_ACTIVE_INTERVAL_DID_NOT_OVERLAP")
        hook["overlap_proof"] = "PASS_SCAN_STARTED_BEFORE_STREAM_ENABLE_AND_DONE_AFTER_STREAM_ENABLE"
    elif overlap:
        raise RuntimeError("OVERLAP_SCAN_WORKER_NOT_STARTED")

    logs_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    controller_path = logs_dir / "controller-result.json"
    if not controller_path.exists():
        capture_module.write_json(controller_path, controller)
    require(controller.get("result") == "PASS", f"CAPTURE_CONTROLLER_FAILED:{name}")
    validation = run_validator(name, private_dir, logs_dir)
    return controller, validation, hook


def scan_worker() -> int:
    support = load_support()
    lock = load_key_value_receipt(LOCK)
    require(lock.get("TASK") == TASK and lock.get("RUN_ROOT") == str(ROOT) and
            lock.get("STATE") == "HELD", "DUT_LOCK_OWNER_MISMATCH_SCAN_WORKER")
    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
            "BOOT_ID_DRIFT_SCAN_WORKER")
    require(not SCAN_RESULT.exists() and not SCAN_PREFIX.with_suffix(".bin").exists() and
            not SCAN_PREFIX.with_suffix(".json").exists(),
            "OVERLAP_SCAN_OUTPUT_PREEXISTS")
    sys.path.insert(0, str(BUNDLE))
    from scan1 import controller, evidence, manifest, mmio
    for module in (controller, evidence, manifest, mmio):
        origin = P(module.__file__).resolve(strict=True)
        require(origin.is_relative_to(BUNDLE.resolve(strict=True)),
                "SCAN_BUNDLE_MODULE_ORIGIN_VIOLATION")
    entries, prohibited, raw_manifest = manifest.load_and_validate()
    require(len(entries) == 82 and len(prohibited) == 14,
            "SCAN_FROZEN_MANIFEST_COUNT_MISMATCH")

    class NotifyingDevice:
        def __init__(self) -> None:
            self.base = support.BoundedDevice(DEVICE)
            self.start_completed_monotonic_ns: int | None = None
            self.done_observed_monotonic_ns: int | None = None

        def __enter__(self) -> "NotifyingDevice":
            self.base.__enter__()
            return self

        def __exit__(self, exc_type: object, exc: object, traceback: object) -> None:
            self.base.__exit__(exc_type, exc, traceback)

        def read32(self, address: int) -> int:
            value = self.base.read32(address)
            if address == mmio.STATUS and value & mmio.STATUS_DONE and \
                    self.done_observed_monotonic_ns is None:
                self.done_observed_monotonic_ns = time.monotonic_ns()
            return value

        def write32(self, address: int, value: int) -> None:
            started_ns = time.monotonic_ns()
            self.base.write32(address, value)
            self.base.write_log[-1]["start_monotonic_ns"] = started_ns
            self.base.write_log[-1]["completed_monotonic_ns"] = time.monotonic_ns()
            if address == mmio.CONTROL and value == mmio.CONTROL_ONESHOT:
                self.start_completed_monotonic_ns = self.base.write_log[-1]["completed_monotonic_ns"]
                print(json.dumps({
                    "event": "SCAN1_ONESHOT_STARTED",
                    "generation_before": 262,
                    "start_call_monotonic_ns": started_ns,
                    "start_completed_monotonic_ns": self.start_completed_monotonic_ns,
                }, sort_keys=True), flush=True)

        @property
        def write_log(self) -> list[dict[str, int]]:
            return self.base.write_log

        @property
        def timeout_count(self) -> int:
            return self.base.timeout_count

        @property
        def short_read_count(self) -> int:
            return self.base.short_read_count

        @property
        def short_write_count(self) -> int:
            return self.base.short_write_count

    device = NotifyingDevice()
    immutable: dict[str, object] = {}
    original_persist = evidence.persist_snapshot
    with device:
        status_before = device.read32(mmio.STATUS)
        generation_before = device.read32(mmio.GENERATION)
        require(status_before == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE and
                generation_before == 262, "OVERLAP_SCAN_INITIAL_STATE")
        require(device.read32(0x1006C) & 0x3 == 0x1 and
                device.read32(0x10090) == 0, "OVERLAP_SCAN_AUTOINIT_STATE")
        require(device.read32(0x0380C) == 0 and
                device.read32(0x03810) & 0x10F == 0x004,
                "OVERLAP_SCAN_TRANSPORT_NOT_DISABLED_AT_START")

        def persist_and_verify(prefix: P, snapshot: dict[str, Any]) -> dict[str, Any]:
            expected_words = list(snapshot["_raw_words"])
            receipt = original_persist(prefix, snapshot)
            raw_path = P(str(receipt["raw_path"]))
            json_path = P(str(receipt["json_path"]))
            expected_bytes = b"".join(struct.pack("<I", word) for word in expected_words)
            require(raw_path.read_bytes() == expected_bytes,
                    "OVERLAP_SCAN_PERSISTED_RAW_MISMATCH")
            generation0 = device.read32(mmio.GENERATION)
            header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
            reread = [device.read32(address) for address in header_addresses]
            reread += [device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
            reread += [device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(82)]
            generation1 = device.read32(mmio.GENERATION)
            require(generation0 == generation1 == snapshot["generation"],
                    "OVERLAP_SCAN_GENERATION_MUTATED_BEFORE_ACK")
            require(reread == expected_words,
                    "OVERLAP_SCAN_SNAPSHOT_MUTATED_BEFORE_ACK")
            immutable.update({
                "raw_mtime_ns": raw_path.stat().st_mtime_ns,
                "json_mtime_ns": json_path.stat().st_mtime_ns,
                "raw_sha256": sha256(raw_path),
                "json_sha256": sha256(json_path),
            })
            return receipt

        evidence.persist_snapshot = persist_and_verify
        try:
            scanner = controller.ScannerController(device)
            snapshot, receipt = scanner.oneshot(SCAN_PREFIX, timeout_seconds=3.0)
        finally:
            evidence.persist_snapshot = original_persist
        status_after = device.read32(mmio.STATUS)
        generation_after = device.read32(mmio.GENERATION)
        transport_control_after = device.read32(0x0380C)
        transport_status_after = device.read32(0x03810)

    require(device.start_completed_monotonic_ns is not None and
            device.done_observed_monotonic_ns is not None,
            "OVERLAP_SCAN_TIMESTAMPS_MISSING")
    require(len(device.write_log) == 2 and
            [(row["address"], row["value"]) for row in device.write_log] == [
                (mmio.CONTROL, mmio.CONTROL_ONESHOT),
                (mmio.CONTROL, mmio.CONTROL_ACK_CLEAR),
            ], "OVERLAP_SCAN_CONTROL_SEQUENCE")
    require(snapshot["generation"] == generation_after == generation_before + 1 == 263,
            "OVERLAP_SCAN_GENERATION_SEQUENCE")
    require(status_after == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
            "OVERLAP_SCAN_NOT_IDLE_AFTER_ACK")
    require(snapshot["entry_count"] == 82 and snapshot["bank_group_count"] == 10 and
            snapshot["transaction_count"] == 105 and
            snapshot["entry_bank_restore"] == "PASS" and
            snapshot["entry_bank"] == snapshot["exit_bank"] and
            snapshot["consistency_attempt"] == 1 and
            all(entry["status"] == 0x05 for entry in snapshot["raw_register_set"]),
            "OVERLAP_SCAN_INTEGRITY")
    raw_words = list(struct.unpack("<146I", P(str(receipt["raw_path"])).read_bytes()))
    support.validate_groups(raw_words[24:64], entries, manifest.GROUP_NAMES)
    require(sha256(P(str(receipt["raw_path"]))) == receipt["raw_sha256"] == immutable["raw_sha256"] and
            sha256(P(str(receipt["json_path"]))) == receipt["json_sha256"] == immutable["json_sha256"],
            "OVERLAP_SCAN_HASH_READBACK")
    require(int(immutable["raw_mtime_ns"]) <= device.write_log[1]["start_wall_ns"] and
            int(immutable["json_mtime_ns"]) <= device.write_log[1]["start_wall_ns"],
            "OVERLAP_SCAN_NOT_PERSISTED_BEFORE_ACK")
    require(device.timeout_count == 0 and device.short_read_count == 0 and
            device.short_write_count == 0, "OVERLAP_SCAN_MMIO_OPERATION_ERROR")

    result = {
        "task": TASK, "result": "PASS", "generation_before": generation_before,
        "generation": snapshot["generation"], "generation_after": generation_after,
        "start_completed_monotonic_ns": device.start_completed_monotonic_ns,
        "done_observed_monotonic_ns": device.done_observed_monotonic_ns,
        "ack_call_monotonic_ns": device.write_log[1]["start_monotonic_ns"],
        "return_monotonic_ns": time.monotonic_ns(),
        "entry_count": 82, "bank_group_count": 10, "transaction_count": 105,
        "entry_bank_restore": "PASS", "prohibited_reads": 0,
        "nack": 0, "timeout": 0, "bank_mismatch": 0,
        "snapshot_mutation_before_ack": 0,
        "duration_ticks": snapshot["end_ticks"] - snapshot["start_ticks"],
        "duration_ms": (snapshot["end_ticks"] - snapshot["start_ticks"]) * 1000.0 / 62_500_000,
        "a8_pre": snapshot["a8_pre"], "a8_post": snapshot["a8_post"],
        "a8_bookend_stable": not snapshot["live_status_changed"],
        "scanner_idle_after_ack": True,
        "transport_control_observed_after_scan": transport_control_after,
        "transport_status_observed_after_scan": transport_status_after,
        "raw_snapshot": receipt,
        "raw_snapshot_sha256_readback": immutable["raw_sha256"],
        "decoded_snapshot_sha256_readback": immutable["json_sha256"],
        "bundle_manifest_identity": raw_manifest["manifest_sha256"],
    }
    write_json_new(SCAN_RESULT, result)
    print(json.dumps({"event": "SCAN1_ONESHOT_COMPLETE", "result": "PASS",
                      "generation": 263,
                      "done_observed_monotonic_ns": device.done_observed_monotonic_ns},
                     sort_keys=True), flush=True)
    return 0


def self_check() -> int:
    provenance = verify_capture_files()
    sys.path.insert(0, str(PRIVATE))
    capture = load_module("accepted_capture_controller_selfcheck",
                          PRIVATE / "controller_nvp_capture_r3r2.py")
    require(capture.TASK == EXPECTED_CAPTURE_SOURCE_TASK,
            "ACCEPTED_CAPTURE_ORIGINAL_TASK_IDENTITY")
    require(capture.PRIMARY_RECORDS == 2500 and capture.RECORD_BYTES == 4096 and
            capture.PRIMARY_BYTES == 10_240_000 and capture.GUARD_RECORDS == 0,
            "ACCEPTED_CAPTURE_CONSTANTS")
    abi = json.loads((PRIVATE / "V41_C2H_TRANSPORT_ABI_V1.json").read_text())
    vbi = json.loads((PRIVATE / "V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json").read_text())
    require(abi.get("abi", {}).get("name") == "AHD_C2H_TRANSPORT_ABI_V1" and
            vbi.get("profile") == "NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_V1" and
            vbi.get("maximum_vertical_tail_intervals") == 21,
            "ACCEPTED_CAPTURE_CONTRACT_IDENTITY")
    print(json.dumps({"task": TASK, "result": "PASS",
                      "accepted_capture_files": len(provenance),
                      "accepted_manifest_sha256": ACCEPTED_CAPTURE_BUNDLE_MANIFEST_SHA256,
                      "mode": "SELF_CHECK_NO_HARDWARE"}, sort_keys=True))
    return 0


def main_gate() -> int:
    for path in (CAPTURE_PRIVATE_ROOT, CAPTURE_LOG_ROOT, SCAN_PREFIX.with_suffix(".bin"),
                 SCAN_PREFIX.with_suffix(".json"), REPORT, STATE_OUTPUT, LOG_OUTPUT,
                 LOCK_ADAPTER):
        require(not path.exists(), f"NONINTERFERENCE_OUTPUT_PREEXISTS:{path}")
    provenance = verify_capture_files()
    require(sha256(OWNER_REPLY) == OWNER_REPLY_SHA256, "OWNER_REPLY_SHA256_MISMATCH")
    owner_fields = dict(line.split("=", 1) for line in OWNER_REPLY.read_text().splitlines())
    require(owner_fields.get("TASK") == TASK and
            owner_fields.get("HUMAN_GATE") == "SCAN1-A" and
            owner_fields.get("OWNER_REPLY") == "SCAN1_BASELINE_READY" and
            owner_fields.get("STATE") == "ACCEPTED_EXACT_REPLY",
            "OWNER_REPLY_NOT_EXACT")
    baseline = json.loads(BASELINE_REPORT.read_text(encoding="utf-8"))
    require(baseline.get("result") == "PASS" and baseline.get("scans") == 5 and
            baseline.get("last_generation") == 262 and
            baseline.get("stable_baseline_channels") == 4 and
            baseline.get("transport_disabled") is True and
            baseline.get("pending_aio") == 0,
            "DISCONNECTED_BASELINE_NOT_PASS")
    lock = load_key_value_receipt(LOCK)
    require(lock.get("TASK") == TASK and lock.get("RUN_ROOT") == str(ROOT) and
            lock.get("STATE") == "HELD", "DUT_LOCK_OWNER_MISMATCH")
    support = load_support()
    initial_state = verify_common_state(support, 262, "BEFORE_REFERENCE")
    kernel_before = support.dmesg_bytes()
    aer_before = {"endpoint": support.aer(ENDPOINT),
                  "root_port": support.aer(ROOT_PORT)}

    LOCK_ADAPTER.mkdir(mode=0o700)
    adapter = {
        "schema": "SCAN1_CAPTURE_LOCK_ADAPTER_V1",
        "task": TASK, "state": "HELD",
        "authoritative_lock_receipt": str(LOCK),
        "authoritative_lock_receipt_sha256": sha256(LOCK),
        "purpose": "BIND_BYTE_EXACT_ACCEPTED_CAPTURE_CONTROLLER_TO_CURRENT_HELD_TASK_LOCK",
        "capture_controller_source_task": EXPECTED_CAPTURE_SOURCE_TASK,
        "capture_controller_task_binding": TASK,
    }
    write_json_new(LOCK_ADAPTER / "receipt.json", adapter)

    sys.path.insert(0, str(PRIVATE))
    capture = load_module("accepted_capture_controller_scan1",
                          PRIVATE / "controller_nvp_capture_r3r2.py")
    require(capture.TASK == EXPECTED_CAPTURE_SOURCE_TASK,
            "ACCEPTED_CAPTURE_SOURCE_TASK_MISMATCH")
    capture.TASK = TASK
    binding = {
        "result": "PASS",
        "method": "RUNTIME_TASK_ID_BINDING_ONLY",
        "source_file_byte_exact": True,
        "source_task_before_binding": EXPECTED_CAPTURE_SOURCE_TASK,
        "bound_task": TASK,
        "capture_control_flow_changes": 0,
        "capture_mmio_allowlist_changes": 0,
        "overlap_hook": "START_ONE_SCAN_IMMEDIATELY_BEFORE_ACCEPTED_STREAM_ENABLE_WRITE",
    }

    captures: dict[str, dict[str, Any]] = {}
    hooks: dict[str, dict[str, Any]] = {}
    state_checks: list[dict[str, object]] = [initial_state]
    controller, validation, hook = run_capture(capture, "reference", overlap=False)
    captures["reference"] = validate_capture_contract("reference", controller, validation)
    hooks["reference"] = hook
    state_checks.append(verify_common_state(support, 262, "AFTER_REFERENCE"))

    controller, validation, hook = run_capture(capture, "overlap", overlap=True)
    captures["overlap"] = validate_capture_contract("overlap", controller, validation)
    hooks["overlap"] = hook
    state_checks.append(verify_common_state(support, 263, "AFTER_OVERLAP"))

    controller, validation, hook = run_capture(capture, "post", overlap=False)
    captures["post"] = validate_capture_contract("post", controller, validation)
    hooks["post"] = hook
    state_checks.append(verify_common_state(support, 263, "AFTER_POST"))

    frame_hashes = {name: captures[name]["frame"]["sha256"] for name in CAPTURE_NAMES}
    pixel_classes = {name: captures[name]["frame"]["pixel_classification"] for name in CAPTURE_NAMES}
    dominant_classes = {name: captures[name]["frame"]["dominant_pixel_class"] for name in CAPTURE_NAMES}
    require(all(bool(captures[name]["frame"]["uniform"]) for name in CAPTURE_NAMES),
            "DISCONNECTED_FALLBACK_NOT_DETERMINISTIC_UNIFORM_CLASS")
    require(len(set(frame_hashes.values())) == 1,
            "DETERMINISTIC_FALLBACK_FRAME_BYTE_EQUALITY_FAILED")
    require(len(set(pixel_classes.values())) == 1 and
            len(set(dominant_classes.values())) == 1,
            "DETERMINISTIC_FALLBACK_PIXEL_CLASS_CHANGED")

    essential_counter_fields = ("streamed", "dropped", "overflow",
                                "discontinuity", "beats")
    counter_signatures = {
        name: {field: captures[name]["counter_deltas"].get(field)
               for field in essential_counter_fields}
        for name in CAPTURE_NAMES
    }
    require(len({json.dumps(value, sort_keys=True)
                 for value in counter_signatures.values()}) == 1,
            "SCANNER_INDUCED_TRANSPORT_COUNTER_CHANGE")

    kernel_after = support.dmesg_bytes()
    require(kernel_after.startswith(kernel_before), "KERNEL_LOG_CONTINUITY_LOST")
    kernel_delta = kernel_after[len(kernel_before):].decode("utf-8", "replace")
    kernel_matches = re.findall(
        r"(?im)^.*(?:\bDPC\b|AER:|PCIe Bus Error|malformed TLP|unsupported request|"
        r"surprise link|link[- ]down|completion timeout|IOMMU fault|xdma[^\n]*fatal).*$",
        kernel_delta,
    )
    aer_after = {"endpoint": support.aer(ENDPOINT),
                 "root_port": support.aer(ROOT_PORT)}
    require(not kernel_matches and aer_after == aer_before,
            "KERNEL_PCIE_ERROR_DURING_NONINTERFERENCE")
    final_state = verify_common_state(support, 263, "FINAL")

    result = {
        "schema": "G2B_NVP_CAMERA_SCAN1_R1R1_VIDEO_DMA_NONINTERFERENCE_V1",
        "task": TASK, "result": "PASS",
        "VIDEO_DMA_NONINTERFERENCE": "PASS",
        "camera_state": "DISCONNECTED_OR_POWERED_OFF_OWNER_ATTESTED_BY_GATE_A",
        "digital_route": "PREEXISTING_QUALIFIED_CH1_PATH_NO_NVP_ROUTE_WRITE",
        "nvp_route_changes": 0, "bgdcol_changes": 0,
        "scanner_operations": 1, "scanner_generations": "262->263",
        "sequence": ["reference_2500_scanner_idle",
                     "start_one_oneshot_then_enable_overlap_2500",
                     "post_scan_2500_scanner_idle"],
        "accepted_capture_bundle_manifest_sha256": ACCEPTED_CAPTURE_BUNDLE_MANIFEST_SHA256,
        "accepted_capture_file_provenance": provenance,
        "capture_task_binding": binding,
        "lock_adapter": adapter,
        "disconnected_baseline": "PASS",
        "captures": captures,
        "overlap": hooks["overlap"],
        "overlap_proof": hooks["overlap"]["overlap_proof"],
        "frame_comparison_mode": "DETERMINISTIC_FALLBACK_EXACT_BYTE_EQUALITY",
        "frame_sha256": frame_hashes,
        "frame_byte_exact_equality": "PASS",
        "pixel_classification": pixel_classes,
        "dominant_pixel_class": dominant_classes,
        "counter_signatures": counter_signatures,
        "scanner_induced_transport_counter_change": 0,
        "all_captures_exact_completions": "2500/2500",
        "all_record_integrity": "PASS",
        "all_active_frame_integrity": "PASS",
        "all_bounded_route_specific_vbi": "PASS",
        "all_complete_1920x1080_frame": "PASS",
        "all_overflow": 0, "all_malformed_preceding": 0,
        "all_source_drop": 0, "all_pending_aio_final": 0,
        "all_physical_quiescence": "PASS",
        "state_checks": state_checks + [final_state],
        "boot_id": EXPECTED_BOOT,
        "driver": "xdma_ahd_pcie",
        "controller_lock": "HELD",
        "dut_lock": "HELD",
        "kernel_delta": kernel_delta,
        "dpc_aer_events": 0,
        "final_scanner_idle": True,
        "final_scanner_generation": 263,
        "final_transport_disabled": True,
        "final_pending_aio": 0,
        "background_scanning": False,
        "next_human_gate": "SCAN1-B",
        "required_owner_reply": "SCAN1_CAMERA_CONNECTED",
        "utc_ns": time.time_ns(),
    }
    write_json_new(REPORT, result)
    write_json_new(STATE_OUTPUT, {
        "task": TASK, "phase": "PHASE_A_VIDEO_DMA_NONINTERFERENCE_COMPLETE",
        "result": "PASS", "video_dma_noninterference": "PASS",
        "last_scanner_generation": 263, "human_gate": "SCAN1-B",
        "required_owner_reply": "SCAN1_CAMERA_CONNECTED",
        "report": str(REPORT), "report_sha256": sha256(REPORT),
    })
    write_json_new(LOG_OUTPUT, result)
    print(json.dumps({
        "task": TASK, "result": "PASS", "captures": "3/3",
        "exact_completions_each": "2500/2500",
        "frame_byte_exact_equality": "PASS",
        "overlap_proof": result["overlap_proof"],
        "scanner_generation": 263, "pending_aio": 0,
        "transport_disabled": True,
    }, sort_keys=True))
    print("VIDEO_DMA_NONINTERFERENCE=PASS")
    print("HUMAN_GATE_SCAN1_B=READY")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-check", action="store_true")
    parser.add_argument("--scan-worker", action="store_true")
    args = parser.parse_args()
    selected = int(args.self_check) + int(args.scan_worker)
    require(selected <= 1, "MODE_SELECTION_INVALID")
    if args.self_check:
        return self_check()
    if args.scan_worker:
        return scan_worker()
    return main_gate()


if __name__ == "__main__":
    raise SystemExit(main())
