#!/usr/bin/env python3
# SANITIZED PUBLICATION COPY; executed-source SHA-256: B16155CB81CBDD6C82B4EDB5214E841A3A6315E1F1FF3AAFD40DD44B1979E9F4
"""Five exact disconnected SCAN1 baseline scans at 1.0 s start intervals."""

from __future__ import annotations

import dataclasses
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import struct
import subprocess
import sys
import time


P = pathlib.Path
TASK = "G2B-NVP-CAMERA-SCAN1-R1R1"
ROOT = P("/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1/20260911T202728Z")
BUNDLE = ROOT / "runtime-bundle"
LOCK = P("/home/DUT_USER_REDACTED/vcde_artifacts/.ahd_g2b_nvp_camera_scan1_r1_20260911T152909Z.lock/receipt")
DEVICE = P("/dev/xdma0_user")
ENDPOINT = P("/sys/bus/pci/devices/0000:01:00.0")
ROOT_PORT = P("/sys/bus/pci/devices/0000:00:01.1")
EXPECTED_BOOT = "cf1515d9-7238-4bf0-9c7d-7196efb2e762"
OWNER_REPLY = ROOT / "private/owner-reply-scan1-a.txt"
OWNER_REPLY_SHA256 = "66C41CBABD981C6E4EBF5F561CA4B9D61961BAD69B475FD2601B0A07C2C3E865"
SUPPORT = ROOT / "private/repetition_scan_gate.py"
SUPPORT_SHA256 = "6E98B170DAB7A1A3608E8935C5EF044B45AB3A30CA5513D44547D1B346048381"
ENGINEERING_GATE = ROOT / "logs/engineering-gate-waiting-state.json"
PREFIX_ROOT = ROOT / "scanner/baseline"
BASELINE_JSONL = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_SCANS.jsonl"
STATE_OUTPUT = ROOT / "campaign/state-after-baseline.json"
OUTPUT = ROOT / "logs/baseline-scan-gate.json"
REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_GATE.json"
SCAN_COUNT = 5
INTERVAL_NS = 1_000_000_000


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
    with path.open("x") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def load_support() -> object:
    require(sha256(SUPPORT) == SUPPORT_SHA256, "BASELINE_SUPPORT_SHA256_MISMATCH")
    spec = importlib.util.spec_from_file_location("scan1_r1r1_repetition_support", SUPPORT)
    require(spec is not None and spec.loader is not None, "BASELINE_SUPPORT_IMPORT_SPEC")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_lock() -> dict[str, str]:
    values: dict[str, str] = {}
    for line in LOCK.read_text().splitlines():
        key, value = line.split("=", 1)
        require(key not in values, "DUT_LOCK_DUPLICATE_KEY")
        values[key] = value
    return values


class TimedDevice:
    def __init__(self, base_class: type, path: P):
        self._base = base_class(path)

    def __enter__(self) -> "TimedDevice":
        self._base.__enter__()
        return self

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> None:
        self._base.__exit__(exc_type, exc, traceback)

    @property
    def read_count(self) -> int:
        return self._base.read_count

    @property
    def write_log(self) -> list[dict[str, int]]:
        return self._base.write_log

    @property
    def timeout_count(self) -> int:
        return self._base.timeout_count

    @property
    def short_read_count(self) -> int:
        return self._base.short_read_count

    @property
    def short_write_count(self) -> int:
        return self._base.short_write_count

    def read32(self, address: int) -> int:
        return self._base.read32(address)

    def write32(self, address: int, value: int) -> None:
        start_monotonic_ns = time.monotonic_ns()
        self._base.write32(address, value)
        self._base.write_log[-1]["start_monotonic_ns"] = start_monotonic_ns


def channel_record(snapshot: dict, channel: str, channel_index: int) -> dict[str, object]:
    decoded = snapshot["channels"][channel]
    by_address = {
        (entry["bank"], entry["register"]): entry
        for entry in snapshot["raw_register_set"]
    }
    private_bank = 5 + channel_index
    return {
        "channel": channel,
        "a8_pre_novid": (snapshot["a8_pre"] >> channel_index) & 1,
        "a8_post_novid": (snapshot["a8_post"] >> channel_index) & 1,
        "a8_bookend_stable": not snapshot["live_status_changed"],
        "agc_clamp_hlock_tuple": decoded["lock_tuple"],
        "e8_channel_status": by_address[(0, 0xE8 + channel_index)]["value"],
        "detector_f0_f2_f3_f4_f5": {
            key: decoded["private_detector"][key] for key in ("F0", "F2", "F3", "F4", "F5")
        },
        "private_e2_e3_e8_e9_ea_eb": {
            f"{register:02X}": by_address[(private_bank, register)]["value"]
            for register in (0xE2, 0xE3, 0xE8, 0xE9, 0xEA, 0xEB)
        },
        "stable_baseline_tuple_candidate": decoded["raw_tuple"],
    }


def main() -> int:
    for path in (PREFIX_ROOT, BASELINE_JSONL, STATE_OUTPUT, OUTPUT, REPORT):
        require(not path.exists(), f"BASELINE_OUTPUT_PREEXISTS:{path}")
    require(sha256(OWNER_REPLY) == OWNER_REPLY_SHA256, "OWNER_REPLY_SHA256_MISMATCH")
    owner_fields = dict(line.split("=", 1) for line in OWNER_REPLY.read_text().splitlines())
    require(owner_fields.get("TASK") == TASK and owner_fields.get("HUMAN_GATE") == "SCAN1-A" and
            owner_fields.get("OWNER_REPLY") == "SCAN1_BASELINE_READY" and
            owner_fields.get("STATE") == "ACCEPTED_EXACT_REPLY", "OWNER_REPLY_NOT_EXACT")
    engineering = json.loads(ENGINEERING_GATE.read_text())
    require(engineering.get("scan1_hardware_engineering_gate") == "PASS" and
            engineering.get("human_gate") == "SCAN1-A" and
            engineering.get("required_owner_reply") == "SCAN1_BASELINE_READY",
            "ENGINEERING_GATE_OR_HUMAN_GATE_NOT_READY")
    lock = load_lock()
    require(lock.get("TASK") == TASK and lock.get("RUN_ROOT") == str(ROOT) and lock.get("STATE") == "HELD",
            "DUT_LOCK_OWNER_MISMATCH")
    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
            "BOOT_ID_DRIFT_BEFORE_BASELINE")
    require(P("/sys/module/xdma_ahd_pcie").is_dir(), "EXACT_DRIVER_NOT_RETAINED")
    require(ENDPOINT.is_dir() and (ENDPOINT / "driver").resolve().name == "xdma_ahd_pcie",
            "ENDPOINT_OR_DRIVER_MISMATCH")
    require(DEVICE.is_char_device(), "XDMA_USER_NODE_NOT_CHAR_DEVICE")
    support = load_support()
    require(not support.open_xdma_fds(), "PREEXISTING_XDMA_FD")
    require(int(P("/proc/sys/fs/aio-nr").read_text().strip()) == 0, "PENDING_AIO_BEFORE_BASELINE")

    sys.path.insert(0, str(BUNDLE))
    from scan1 import controller, evidence, manifest, mmio, state

    for module in (controller, evidence, manifest, mmio, state):
        origin = P(module.__file__).resolve(strict=True)
        require(origin.is_relative_to(BUNDLE.resolve(strict=True)), "BUNDLE_MODULE_ORIGIN_VIOLATION")
    entries, prohibited, raw_manifest = manifest.load_and_validate()
    require(len(entries) == 82 and len(prohibited) == 14, "FROZEN_MANIFEST_COUNT_MISMATCH")

    kernel_before = support.dmesg_bytes()
    aer_before = {"endpoint": support.aer(ENDPOINT), "root_port": support.aer(ROOT_PORT)}
    campaign = state.CampaignState("G2B-NVP-CAMERA-SCAN1-R1R1")
    device = TimedDevice(support.BoundedDevice, DEVICE)
    immutable: dict[str, dict[str, object]] = {}
    original_persist = evidence.persist_snapshot
    scans: list[dict[str, object]] = []

    with BASELINE_JSONL.open("x") as baseline_handle:
        baseline_handle.flush()
        os.fsync(baseline_handle.fileno())
        with device:
            require(device.read32(mmio.STATUS) == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                    "SCANNER_NOT_IDLE_BEFORE_BASELINE")
            require(device.read32(mmio.GENERATION) == 257, "BASELINE_INITIAL_GENERATION_NOT_257")
            require(device.read32(0x1006C) & 0x3 == 0x1 and device.read32(0x10090) == 0,
                    "AUTOINIT_NOT_CLEAN_BEFORE_BASELINE")
            require(device.read32(0x0380C) == 0 and device.read32(0x03810) & 0x10F == 0x004,
                    "TRANSPORT_NOT_QUIESCENT_BEFORE_BASELINE")

            def persist_and_verify(prefix: P, snapshot: dict) -> dict[str, str | int]:
                expected_words = list(snapshot["_raw_words"])
                receipt = original_persist(prefix, snapshot)
                raw_path = P(str(receipt["raw_path"]))
                json_path = P(str(receipt["json_path"]))
                require(raw_path.read_bytes() == b"".join(struct.pack("<I", word) for word in expected_words),
                        "BASELINE_PERSISTED_RAW_MISMATCH")
                generation0 = device.read32(mmio.GENERATION)
                header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
                reread = [device.read32(address) for address in header_addresses]
                reread += [device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
                reread += [device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(82)]
                generation1 = device.read32(mmio.GENERATION)
                require(generation0 == generation1 == snapshot["generation"],
                        "BASELINE_GENERATION_MUTATED_BEFORE_ACK")
                require(reread == expected_words, "BASELINE_SNAPSHOT_MUTATED_BEFORE_ACK")
                immutable[prefix.name] = {
                    "raw_mtime_ns": raw_path.stat().st_mtime_ns,
                    "json_mtime_ns": json_path.stat().st_mtime_ns,
                    "raw_sha256": sha256(raw_path),
                    "json_sha256": sha256(json_path),
                }
                return receipt

            evidence.persist_snapshot = persist_and_verify
            scanner = controller.ScannerController(device)
            previous_start_ns: int | None = None
            try:
                for scan_index in range(1, SCAN_COUNT + 1):
                    if previous_start_ns is not None:
                        target = previous_start_ns + INTERVAL_NS
                        remaining = target - time.monotonic_ns()
                        if remaining > 0:
                            time.sleep(remaining / 1_000_000_000.0)
                    require(device.read32(mmio.STATUS) == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                            f"BASELINE_NOT_IDLE_AT_START:{scan_index}")
                    write_before = len(device.write_log)
                    snapshot, receipt = scanner.oneshot(
                        PREFIX_ROOT / f"scan-{scan_index:04d}", timeout_seconds=3.0
                    )
                    require(len(device.write_log) == write_before + 2, f"BASELINE_WRITE_COUNT:{scan_index}")
                    pair = device.write_log[write_before:write_before + 2]
                    require([(row["address"], row["value"]) for row in pair] == [
                        (mmio.CONTROL, mmio.CONTROL_ONESHOT),
                        (mmio.CONTROL, mmio.CONTROL_ACK_CLEAR),
                    ], f"BASELINE_CONTROL_SEQUENCE:{scan_index}")
                    start_ns = pair[0]["start_monotonic_ns"]
                    interval_ms = None if previous_start_ns is None else (start_ns - previous_start_ns) / 1_000_000.0
                    if interval_ms is not None:
                        require(995.0 <= interval_ms <= 1010.0,
                                f"BASELINE_START_INTERVAL:{scan_index}:{interval_ms:.6f}")
                    previous_start_ns = start_ns
                    iv = immutable[f"scan-{scan_index:04d}"]
                    require(int(iv["raw_mtime_ns"]) <= pair[1]["start_wall_ns"] and
                            int(iv["json_mtime_ns"]) <= pair[1]["start_wall_ns"],
                            f"BASELINE_NOT_PERSISTED_BEFORE_ACK:{scan_index}")
                    require(snapshot["generation"] == 257 + scan_index,
                            f"BASELINE_GENERATION_SEQUENCE:{scan_index}")
                    require(snapshot["entry_count"] == 82 and snapshot["bank_group_count"] == 10 and
                            snapshot["transaction_count"] == 105, f"BASELINE_COUNT_GATE:{scan_index}")
                    require(snapshot["entry_bank_restore"] == "PASS" and
                            snapshot["entry_bank"] == snapshot["exit_bank"],
                            f"BASELINE_BANK_RESTORE:{scan_index}")
                    require(snapshot["consistency_attempt"] == 1 and
                            all(entry["status"] == 0x05 for entry in snapshot["raw_register_set"]),
                            f"BASELINE_INTEGRITY:{scan_index}")
                    raw_words = list(struct.unpack("<146I", P(str(receipt["raw_path"])).read_bytes()))
                    support.validate_groups(raw_words[24:64], entries, manifest.GROUP_NAMES)
                    require(iv["raw_sha256"] == receipt["raw_sha256"] and
                            iv["json_sha256"] == receipt["json_sha256"],
                            f"BASELINE_HASH_READBACK:{scan_index}")
                    campaign.update("BASELINE", snapshot)
                    channels = {
                        name: channel_record(snapshot, name, index)
                        for index, name in enumerate(("CH1", "CH2", "CH3", "CH4"))
                    }
                    for name, channel_state in campaign.channels.items():
                        channels[name]["stable_baseline_tuple"] = (
                            list(channel_state.previous_raw_tuple)
                            if channel_state.confirmed_format is not None else None
                        )
                        channels[name]["agreeing_stable_samples"] = channel_state.agreeing_sample_count
                        channels[name]["confirmed_baseline_class"] = channel_state.confirmed_format
                    record = {
                        "phase": "BASELINE_DISCONNECTED",
                        "scan": scan_index,
                        "generation": snapshot["generation"],
                        "host_start_monotonic_ns": start_ns,
                        "host_start_interval_ms": interval_ms,
                        "a8_pre": snapshot["a8_pre"],
                        "a8_post": snapshot["a8_post"],
                        "a8_bookend_stable": not snapshot["live_status_changed"],
                        "entry_count": 82,
                        "bank_group_count": 10,
                        "transaction_count": 105,
                        "entry_bank": snapshot["entry_bank"],
                        "exit_bank": snapshot["exit_bank"],
                        "entry_bank_restore": "PASS",
                        "prohibited_reads": 0,
                        "nack": 0,
                        "timeout": 0,
                        "bank_mismatch": 0,
                        "snapshot_mutation_before_ack": 0,
                        "raw_snapshot_sha256": receipt["raw_sha256"],
                        "decoded_snapshot_sha256": receipt["json_sha256"],
                        "channels": channels,
                        "raw_entries": snapshot["raw_register_set"],
                        "result": "PASS_ACKNOWLEDGED_IDLE",
                    }
                    baseline_handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
                    baseline_handle.flush()
                    os.fsync(baseline_handle.fileno())
                    scans.append(record)
            finally:
                evidence.persist_snapshot = original_persist

            status_final = device.read32(mmio.STATUS)
            generation_final = device.read32(mmio.GENERATION)
            autoinit_final = device.read32(0x1006C)
            autoinit_detail_final = device.read32(0x10090)
            transport_control_final = device.read32(0x0380C)
            transport_status_final = device.read32(0x03810)

    require(len(scans) == 5 and generation_final == 262, "BASELINE_FINAL_COUNT_OR_GENERATION")
    require(status_final == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
            "SCANNER_NOT_IDLE_AFTER_BASELINE")
    require(autoinit_final & 0x3 == 0x1 and autoinit_detail_final == 0,
            "AUTOINIT_NOT_CLEAN_AFTER_BASELINE")
    require(transport_control_final == 0 and transport_status_final & 0x10F == 0x004,
            "TRANSPORT_NOT_QUIESCENT_AFTER_BASELINE")
    require(device.timeout_count == 0 and device.short_read_count == 0 and device.short_write_count == 0,
            "BASELINE_MMIO_OPERATION_ERROR")
    require(not support.open_xdma_fds(), "XDMA_FD_REMAINED_AFTER_BASELINE")
    require(int(P("/proc/sys/fs/aio-nr").read_text().strip()) == 0, "PENDING_AIO_AFTER_BASELINE")
    for channel_state in campaign.channels.values():
        require(channel_state.agreeing_sample_count >= 3 and channel_state.confirmed_format is not None,
                f"DISCONNECTED_BASELINE_NOT_STABLE:{channel_state.phase_id}")

    kernel_after = support.dmesg_bytes()
    require(kernel_after.startswith(kernel_before), "KERNEL_LOG_CONTINUITY_LOST")
    delta = kernel_after[len(kernel_before):].decode("utf-8", "replace")
    kernel_matches = re.findall(
        r"(?im)^.*(?:\bDPC\b|AER:|PCIe Bus Error|malformed TLP|unsupported request|"
        r"surprise link|link[- ]down|completion timeout|IOMMU fault|xdma[^\n]*fatal).*$", delta,
    )
    aer_after = {"endpoint": support.aer(ENDPOINT), "root_port": support.aer(ROOT_PORT)}
    require(not kernel_matches and aer_after == aer_before, "KERNEL_PCIE_ERROR_DURING_BASELINE")
    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
            "UNEXPECTED_REBOOT_DURING_BASELINE")

    state_result = {
        "task": TASK,
        "campaign_id": campaign.campaign_id,
        "phase": "BASELINE_DISCONNECTED_COMPLETE",
        "last_generation": 262,
        "channels": {name: dataclasses.asdict(value) for name, value in campaign.channels.items()},
    }
    result = {
        "task": TASK,
        "result": "PASS",
        "utc_ns": time.time_ns(),
        "owner_reply": "SCAN1_BASELINE_READY",
        "scans": 5,
        "first_generation": 258,
        "last_generation": 262,
        "scanner_integrity_pass": 5,
        "a8_bookend_stable_scans": sum(record["a8_bookend_stable"] for record in scans),
        "a8_bookend_changed_scans": sum(not record["a8_bookend_stable"] for record in scans),
        "host_start_intervals_ms": [record["host_start_interval_ms"] for record in scans[1:]],
        "host_interval_contract": "1.0_SECONDS",
        "stable_baseline_channels": 4,
        "channel_state": state_result["channels"],
        "entry_bank_restore_pass": 5,
        "prohibited_reads": 0,
        "nack": 0,
        "timeout": 0,
        "bank_mismatch": 0,
        "snapshot_mutation_before_ack": 0,
        "transport_disabled": True,
        "physical_quiescence": "PASS",
        "pending_aio": 0,
        "background_scanning": False,
        "boot_id": EXPECTED_BOOT,
        "kernel_delta": delta,
        "dpc_aer_events": 0,
        "bundle_manifest_identity": raw_manifest["manifest_sha256"],
        "baseline_jsonl": str(BASELINE_JSONL),
        "baseline_jsonl_sha256": sha256(BASELINE_JSONL),
    }
    write_json_new(STATE_OUTPUT, state_result)
    write_json_new(REPORT, result)
    write_json_new(OUTPUT, result)
    print(json.dumps({
        "task": TASK,
        "result": "PASS",
        "scans": 5,
        "generations": "258..262",
        "a8_bookend_stable_scans": result["a8_bookend_stable_scans"],
        "stable_baseline_channels": 4,
        "host_start_intervals_ms": result["host_start_intervals_ms"],
        "entry_bank_restore_pass": 5,
        "pending_aio": 0,
        "transport_disabled": True,
    }, sort_keys=True))
    print("SCAN1_DISCONNECTED_BASELINE_GATE=PASS_5/5")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
