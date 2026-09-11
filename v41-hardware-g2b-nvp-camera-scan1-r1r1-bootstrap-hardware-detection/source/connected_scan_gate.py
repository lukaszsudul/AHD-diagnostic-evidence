#!/usr/bin/env python3
# SANITIZED PUBLICATION COPY; executed-source SHA-256: 56CF75D843E312AE73734437DD092EA3CDEEE9A14D84D6DE13E923A4F515B5DC
"""Ten exact connected-camera SCAN1 scans at 1.0 s start intervals."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import struct
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

OWNER_REPLY = ROOT / "private/owner-reply-scan1-b.txt"
OWNER_REPLY_SHA256 = "F685D8609BE8F24C91186E6F1FD1325D9F8ECE408495541DA3277B0736CAEB29"
SUPPORT = ROOT / "private/repetition_scan_gate.py"
SUPPORT_SHA256 = "6E98B170DAB7A1A3608E8935C5EF044B45AB3A30CA5513D44547D1B346048381"
BASELINE_JSONL = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_SCANS.jsonl"
BASELINE_REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_GATE.json"
BASELINE_STATE = ROOT / "campaign/state-after-baseline.json"
BASELINE_PREFIX = ROOT / "scanner/baseline"
NONINTERFERENCE_REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_VIDEO_DMA_NONINTERFERENCE.json"
NONINTERFERENCE_REPORT_SHA256 = "D062FAAE1F1A1A928D6F8C5E1FA36CB57904F09C1D3A093225E14F5D6E3D6846"
NONINTERFERENCE_STATE = ROOT / "campaign/state-after-video-dma-noninterference.json"
NONINTERFERENCE_STATE_SHA256 = "A97A74B4579EBFA3DE8E7DD7061899BB8534A70BAD1967FD90FCC786F3E7D86A"

PREFIX_ROOT = ROOT / "scanner/connected"
CONNECTED_JSONL = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_SCANS.jsonl"
STATE_OUTPUT = ROOT / "campaign/state-after-connected.json"
OUTPUT = ROOT / "logs/connected-scan-gate.json"
REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_GATE.json"
SCAN_COUNT = 10
INITIAL_GENERATION = 263
INTERVAL_NS = 1_000_000_000
WAIT_NS = 2_000_000_000


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def sha256(path: P) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def canonical(value: object) -> object:
    return json.loads(json.dumps(value, sort_keys=True))


def write_json_new(path: P, value: object) -> None:
    with path.open("x") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def load_support() -> object:
    require(sha256(SUPPORT) == SUPPORT_SHA256, "CONNECTED_SUPPORT_SHA256_MISMATCH")
    spec = importlib.util.spec_from_file_location("scan1_r1r1_repetition_support", SUPPORT)
    require(spec is not None and spec.loader is not None, "CONNECTED_SUPPORT_IMPORT_SPEC")
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


def load_jsonl(path: P) -> list[dict]:
    rows: list[dict] = []
    for line in path.read_text().splitlines():
        require(bool(line), f"EMPTY_JSONL_LINE:{path}")
        rows.append(json.loads(line))
    return rows


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
        "stable_connected_tuple_candidate": decoded["raw_tuple"],
    }


def import_bundle() -> tuple[object, object, object, object, object]:
    sys.path.insert(0, str(BUNDLE))
    from scan1 import controller, evidence, manifest, mmio, state

    for module in (controller, evidence, manifest, mmio, state):
        origin = P(module.__file__).resolve(strict=True)
        require(origin.is_relative_to(BUNDLE.resolve(strict=True)), "BUNDLE_MODULE_ORIGIN_VIOLATION")
    return controller, evidence, manifest, mmio, state


def validate_phase_inputs(state_module: object) -> tuple[object, list[dict], dict]:
    require(sha256(OWNER_REPLY) == OWNER_REPLY_SHA256, "OWNER_REPLY_SHA256_MISMATCH")
    owner_fields = dict(line.split("=", 1) for line in OWNER_REPLY.read_text().splitlines())
    require(
        owner_fields.get("TASK") == TASK
        and owner_fields.get("HUMAN_GATE") == "SCAN1-B"
        and owner_fields.get("OWNER_REPLY") == "SCAN1_CAMERA_CONNECTED"
        and owner_fields.get("CONNECTOR_LABEL") == "UNKNOWN"
        and owner_fields.get("AUTHORIZED_NEXT_PHASE") == "TEN_CONNECTED_ONESHOT_SCANS"
        and owner_fields.get("STATE") == "ACCEPTED_EXACT_REPLY",
        "OWNER_REPLY_NOT_EXACT",
    )

    require(sha256(NONINTERFERENCE_REPORT) == NONINTERFERENCE_REPORT_SHA256,
            "NONINTERFERENCE_REPORT_SHA256_MISMATCH")
    require(sha256(NONINTERFERENCE_STATE) == NONINTERFERENCE_STATE_SHA256,
            "NONINTERFERENCE_STATE_SHA256_MISMATCH")
    noninterference = json.loads(NONINTERFERENCE_REPORT.read_text())
    noninterference_state = json.loads(NONINTERFERENCE_STATE.read_text())
    require(
        noninterference.get("task") == TASK
        and noninterference.get("result") == "PASS"
        and noninterference.get("VIDEO_DMA_NONINTERFERENCE") == "PASS"
        and noninterference.get("final_scanner_generation") == INITIAL_GENERATION,
        "NONINTERFERENCE_GATE_NOT_PASS",
    )
    require(
        noninterference_state.get("task") == TASK
        and noninterference_state.get("phase") == "PHASE_A_VIDEO_DMA_NONINTERFERENCE_COMPLETE"
        and noninterference_state.get("last_scanner_generation") == INITIAL_GENERATION
        and noninterference_state.get("human_gate") == "SCAN1-B"
        and noninterference_state.get("required_owner_reply") == "SCAN1_CAMERA_CONNECTED"
        and noninterference_state.get("result") == "PASS",
        "NONINTERFERENCE_STATE_NOT_AT_SCAN1_B",
    )

    baseline_report = json.loads(BASELINE_REPORT.read_text())
    baseline_rows = load_jsonl(BASELINE_JSONL)
    require(
        baseline_report.get("task") == TASK
        and baseline_report.get("result") == "PASS"
        and baseline_report.get("scans") == 5
        and baseline_report.get("last_generation") == 262
        and baseline_report.get("stable_baseline_channels") == 4
        and baseline_report.get("baseline_jsonl_sha256") == sha256(BASELINE_JSONL),
        "BASELINE_REPORT_NOT_PASS_OR_HASH_MISMATCH",
    )
    require(len(baseline_rows) == 5, "BASELINE_JSONL_COUNT_NOT_5")

    campaign = state_module.CampaignState(TASK)
    for scan_index, row in enumerate(baseline_rows, start=1):
        require(
            row.get("phase") == "BASELINE_DISCONNECTED"
            and row.get("scan") == scan_index
            and row.get("generation") == 257 + scan_index
            and row.get("result") == "PASS_ACKNOWLEDGED_IDLE",
            f"BASELINE_ROW_IDENTITY:{scan_index}",
        )
        snapshot_path = BASELINE_PREFIX / f"scan-{scan_index:04d}.json"
        raw_path = BASELINE_PREFIX / f"scan-{scan_index:04d}.bin"
        require(sha256(snapshot_path) == row["decoded_snapshot_sha256"],
                f"BASELINE_DECODED_HASH:{scan_index}")
        require(sha256(raw_path) == row["raw_snapshot_sha256"], f"BASELINE_RAW_HASH:{scan_index}")
        snapshot = json.loads(snapshot_path.read_text())
        require(snapshot.get("generation") == 257 + scan_index, f"BASELINE_SNAPSHOT_GENERATION:{scan_index}")
        campaign.update("BASELINE", snapshot)

    baseline_state = json.loads(BASELINE_STATE.read_text())
    replayed_channels = canonical({
        name: dataclasses.asdict(value) for name, value in campaign.channels.items()
    })
    require(
        baseline_state.get("task") == TASK
        and baseline_state.get("campaign_id") == TASK
        and baseline_state.get("phase") == "BASELINE_DISCONNECTED_COMPLETE"
        and baseline_state.get("last_generation") == 262
        and baseline_state.get("channels") == replayed_channels,
        "BASELINE_STATE_REPLAY_MISMATCH",
    )
    return campaign, baseline_rows, noninterference


def preflight(output_absence: bool = True) -> tuple[object, object, object, object, object, object, object]:
    if output_absence:
        for path in (PREFIX_ROOT, CONNECTED_JSONL, STATE_OUTPUT, OUTPUT, REPORT):
            require(not path.exists(), f"CONNECTED_OUTPUT_PREEXISTS:{path}")
    lock = load_lock()
    require(lock.get("TASK") == TASK and lock.get("RUN_ROOT") == str(ROOT) and lock.get("STATE") == "HELD",
            "DUT_LOCK_OWNER_MISMATCH")
    support = load_support()
    controller, evidence, manifest, mmio, state = import_bundle()
    entries, prohibited, raw_manifest = manifest.load_and_validate()
    require(len(entries) == 82 and len(prohibited) == 14, "FROZEN_MANIFEST_COUNT_MISMATCH")
    campaign, baseline_rows, noninterference = validate_phase_inputs(state)
    return support, controller, evidence, manifest, mmio, state, (
        entries, raw_manifest, campaign, baseline_rows, noninterference
    )


def self_check() -> int:
    _, _, _, _, _, _, details = preflight()
    entries, raw_manifest, campaign, baseline_rows, _ = details
    print(json.dumps({
        "task": TASK,
        "result": "PASS",
        "mode": "OFFLINE_SELF_CHECK",
        "owner_reply": "SCAN1_CAMERA_CONNECTED",
        "connector_label": "UNKNOWN",
        "baseline_rows_replayed": len(baseline_rows),
        "baseline_channels_replayed": len(campaign.channels),
        "manifest_entries": len(entries),
        "manifest_sha256": raw_manifest["manifest_sha256"],
        "planned_connected_scans": SCAN_COUNT,
        "planned_wait_seconds": 2.0,
        "planned_start_interval_seconds": 1.0,
        "device_opened": False,
        "scanner_operation": False,
        "nvp_operation": False,
    }, sort_keys=True))
    print("SCAN1_CONNECTED_OFFLINE_SELF_CHECK=PASS")
    return 0


def main() -> int:
    support, controller, evidence, manifest, mmio, state, details = preflight()
    entries, raw_manifest, campaign, baseline_rows, noninterference = details

    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
            "BOOT_ID_DRIFT_BEFORE_CONNECTED")
    require(P("/sys/module/xdma_ahd_pcie").is_dir(), "EXACT_DRIVER_NOT_RETAINED")
    require(ENDPOINT.is_dir() and (ENDPOINT / "driver").resolve().name == "xdma_ahd_pcie",
            "ENDPOINT_OR_DRIVER_MISMATCH")
    require(DEVICE.is_char_device(), "XDMA_USER_NODE_NOT_CHAR_DEVICE")
    require(not support.open_xdma_fds(), "PREEXISTING_XDMA_FD")
    require(int(P("/proc/sys/fs/aio-nr").read_text().strip()) == 0, "PENDING_AIO_BEFORE_CONNECTED")

    kernel_before = support.dmesg_bytes()
    aer_before = {"endpoint": support.aer(ENDPOINT), "root_port": support.aer(ROOT_PORT)}
    connected_phase = state.CampaignState(TASK + "-CONNECTED-PHASE")
    device = TimedDevice(support.BoundedDevice, DEVICE)
    immutable: dict[str, dict[str, object]] = {}
    original_persist = evidence.persist_snapshot
    scans: list[dict[str, object]] = []
    stable_observations: list[dict[str, object]] = []

    with CONNECTED_JSONL.open("x") as connected_handle:
        connected_handle.flush()
        os.fsync(connected_handle.fileno())
        with device:
            require(device.read32(mmio.STATUS) == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                    "SCANNER_NOT_IDLE_BEFORE_CONNECTED")
            require(device.read32(mmio.GENERATION) == INITIAL_GENERATION,
                    "CONNECTED_INITIAL_GENERATION_NOT_263")
            require(device.read32(0x1006C) & 0x3 == 0x1 and device.read32(0x10090) == 0,
                    "AUTOINIT_NOT_CLEAN_BEFORE_CONNECTED")
            require(device.read32(0x0380C) == 0 and device.read32(0x03810) & 0x10F == 0x004,
                    "TRANSPORT_NOT_QUIESCENT_BEFORE_CONNECTED")

            def persist_and_verify(prefix: P, snapshot: dict) -> dict[str, str | int]:
                expected_words = list(snapshot["_raw_words"])
                receipt = original_persist(prefix, snapshot)
                raw_path = P(str(receipt["raw_path"]))
                json_path = P(str(receipt["json_path"]))
                require(raw_path.read_bytes() == b"".join(struct.pack("<I", word) for word in expected_words),
                        "CONNECTED_PERSISTED_RAW_MISMATCH")
                generation0 = device.read32(mmio.GENERATION)
                header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
                reread = [device.read32(address) for address in header_addresses]
                reread += [device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
                reread += [device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(82)]
                generation1 = device.read32(mmio.GENERATION)
                require(generation0 == generation1 == snapshot["generation"],
                        "CONNECTED_GENERATION_MUTATED_BEFORE_ACK")
                require(reread == expected_words, "CONNECTED_SNAPSHOT_MUTATED_BEFORE_ACK")
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
            wait_start_ns = time.monotonic_ns()
            wait_target_ns = wait_start_ns + WAIT_NS
            time.sleep(WAIT_NS / 1_000_000_000.0)
            wait_end_ns = time.monotonic_ns()
            wait_elapsed_ms = (wait_end_ns - wait_start_ns) / 1_000_000.0
            require(wait_end_ns >= wait_target_ns and wait_elapsed_ms <= 2050.0,
                    f"CONNECTED_EXACT_TWO_SECOND_WAIT:{wait_elapsed_ms:.6f}")
            try:
                for scan_index in range(1, SCAN_COUNT + 1):
                    if previous_start_ns is not None:
                        target = previous_start_ns + INTERVAL_NS
                        remaining = target - time.monotonic_ns()
                        if remaining > 0:
                            time.sleep(remaining / 1_000_000_000.0)
                    require(device.read32(mmio.STATUS) == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                            f"CONNECTED_NOT_IDLE_AT_START:{scan_index}")
                    write_before = len(device.write_log)
                    snapshot, receipt = scanner.oneshot(
                        PREFIX_ROOT / f"scan-{scan_index:04d}", timeout_seconds=3.0
                    )
                    require(len(device.write_log) == write_before + 2,
                            f"CONNECTED_WRITE_COUNT:{scan_index}")
                    pair = device.write_log[write_before:write_before + 2]
                    require([(row["address"], row["value"]) for row in pair] == [
                        (mmio.CONTROL, mmio.CONTROL_ONESHOT),
                        (mmio.CONTROL, mmio.CONTROL_ACK_CLEAR),
                    ], f"CONNECTED_CONTROL_SEQUENCE:{scan_index}")
                    start_ns = pair[0]["start_monotonic_ns"]
                    require(start_ns >= wait_end_ns, f"CONNECTED_SCAN_STARTED_DURING_WAIT:{scan_index}")
                    interval_ms = None if previous_start_ns is None else (start_ns - previous_start_ns) / 1_000_000.0
                    if interval_ms is not None:
                        require(995.0 <= interval_ms <= 1010.0,
                                f"CONNECTED_START_INTERVAL:{scan_index}:{interval_ms:.6f}")
                    previous_start_ns = start_ns
                    iv = immutable[f"scan-{scan_index:04d}"]
                    require(int(iv["raw_mtime_ns"]) <= pair[1]["start_wall_ns"] and
                            int(iv["json_mtime_ns"]) <= pair[1]["start_wall_ns"],
                            f"CONNECTED_NOT_PERSISTED_BEFORE_ACK:{scan_index}")
                    require(snapshot["generation"] == INITIAL_GENERATION + scan_index,
                            f"CONNECTED_GENERATION_SEQUENCE:{scan_index}")
                    require(snapshot["entry_count"] == 82 and snapshot["bank_group_count"] == 10 and
                            snapshot["transaction_count"] == 105,
                            f"CONNECTED_COUNT_GATE:{scan_index}")
                    require(snapshot["entry_bank_restore"] == "PASS" and
                            snapshot["entry_bank"] == snapshot["exit_bank"],
                            f"CONNECTED_BANK_RESTORE:{scan_index}")
                    require(snapshot["consistency_attempt"] == 1 and
                            all(entry["status"] == 0x05 for entry in snapshot["raw_register_set"]),
                            f"CONNECTED_INTEGRITY:{scan_index}")
                    raw_words = list(struct.unpack("<146I", P(str(receipt["raw_path"])).read_bytes()))
                    support.validate_groups(raw_words[24:64], entries, manifest.GROUP_NAMES)
                    require(iv["raw_sha256"] == receipt["raw_sha256"] and
                            iv["json_sha256"] == receipt["json_sha256"],
                            f"CONNECTED_HASH_READBACK:{scan_index}")

                    campaign.update("CONNECTED_CAMERA", snapshot)
                    connected_phase.update("CONNECTED_CAMERA", snapshot)
                    channels = {
                        name: channel_record(snapshot, name, index)
                        for index, name in enumerate(("CH1", "CH2", "CH3", "CH4"))
                    }
                    scan_candidates: list[str] = []
                    for name in ("CH1", "CH2", "CH3", "CH4"):
                        global_state = campaign.channels[name]
                        phase_state = connected_phase.channels[name]
                        stable_candidate = (
                            phase_state.agreeing_sample_count >= 3
                            and phase_state.confirmed_format is not None
                        )
                        channels[name]["campaign_agreeing_stable_samples"] = global_state.agreeing_sample_count
                        channels[name]["campaign_confirmed_class"] = global_state.confirmed_format
                        channels[name]["connected_phase_agreeing_stable_samples"] = phase_state.agreeing_sample_count
                        channels[name]["connected_phase_confirmed_class"] = phase_state.confirmed_format
                        channels[name]["stable_connected_candidate"] = stable_candidate
                        if stable_candidate:
                            scan_candidates.append(name)
                            stable_observations.append({
                                "scan": scan_index,
                                "generation": snapshot["generation"],
                                "channel": name,
                                "classification": phase_state.confirmed_format,
                                "agreeing_stable_samples": phase_state.agreeing_sample_count,
                            })

                    record = {
                        "phase": "CONNECTED_CAMERA",
                        "connector_label": "UNKNOWN",
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
                        "functional_nvp_writes": 0,
                        "snapshot_mutation_before_ack": 0,
                        "raw_snapshot_sha256": receipt["raw_sha256"],
                        "decoded_snapshot_sha256": receipt["json_sha256"],
                        "stable_connected_candidate_channels": scan_candidates,
                        "channels": channels,
                        "raw_entries": snapshot["raw_register_set"],
                        "result": "PASS_ACKNOWLEDGED_IDLE",
                    }
                    connected_handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
                    connected_handle.flush()
                    os.fsync(connected_handle.fileno())
                    scans.append(record)
            finally:
                evidence.persist_snapshot = original_persist

            status_final = device.read32(mmio.STATUS)
            generation_final = device.read32(mmio.GENERATION)
            autoinit_final = device.read32(0x1006C)
            autoinit_detail_final = device.read32(0x10090)
            transport_control_final = device.read32(0x0380C)
            transport_status_final = device.read32(0x03810)

    require(len(scans) == SCAN_COUNT and generation_final == INITIAL_GENERATION + SCAN_COUNT,
            "CONNECTED_FINAL_COUNT_OR_GENERATION")
    require(status_final == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
            "SCANNER_NOT_IDLE_AFTER_CONNECTED")
    require(autoinit_final & 0x3 == 0x1 and autoinit_detail_final == 0,
            "AUTOINIT_NOT_CLEAN_AFTER_CONNECTED")
    require(transport_control_final == 0 and transport_status_final & 0x10F == 0x004,
            "TRANSPORT_NOT_QUIESCENT_AFTER_CONNECTED")
    require(len(device.write_log) == 2 * SCAN_COUNT and
            all(row["address"] == mmio.CONTROL for row in device.write_log),
            "CONNECTED_NON_CONTROL_WRITE_OR_WRITE_COUNT")
    require(device.timeout_count == 0 and device.short_read_count == 0 and device.short_write_count == 0,
            "CONNECTED_MMIO_OPERATION_ERROR")
    require(not support.open_xdma_fds(), "XDMA_FD_REMAINED_AFTER_CONNECTED")
    require(int(P("/proc/sys/fs/aio-nr").read_text().strip()) == 0,
            "PENDING_AIO_AFTER_CONNECTED")

    for observation in stable_observations:
        require(int(observation["agreeing_stable_samples"]) >= 3 and
                observation["classification"] is not None,
                "CONNECTED_CANDIDATE_WITHOUT_THREE_AGREEING_STABLE_SNAPSHOTS")

    kernel_after = support.dmesg_bytes()
    require(kernel_after.startswith(kernel_before), "KERNEL_LOG_CONTINUITY_LOST")
    delta = kernel_after[len(kernel_before):].decode("utf-8", "replace")
    kernel_matches = re.findall(
        r"(?im)^.*(?:\bDPC\b|AER:|PCIe Bus Error|malformed TLP|unsupported request|"
        r"surprise link|link[- ]down|completion timeout|IOMMU fault|xdma[^\n]*fatal).*$", delta,
    )
    aer_after = {"endpoint": support.aer(ENDPOINT), "root_port": support.aer(ROOT_PORT)}
    require(not kernel_matches and aer_after == aer_before, "KERNEL_PCIE_ERROR_DURING_CONNECTED")
    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
            "UNEXPECTED_REBOOT_DURING_CONNECTED")

    stable_channels = sorted({str(item["channel"]) for item in stable_observations})
    state_result = {
        "task": TASK,
        "campaign_id": campaign.campaign_id,
        "phase": "CONNECTED_CAMERA_COMPLETE",
        "connector_label": "UNKNOWN",
        "last_generation": INITIAL_GENERATION + SCAN_COUNT,
        "human_gate": "SCAN1-C",
        "required_owner_reply": "SCAN1_RETURN_CONTROL_READY",
        "channels": {name: dataclasses.asdict(value) for name, value in campaign.channels.items()},
        "connected_phase_channels": {
            name: dataclasses.asdict(value) for name, value in connected_phase.channels.items()
        },
    }
    result = {
        "task": TASK,
        "result": "PASS",
        "utc_ns": time.time_ns(),
        "owner_reply": "SCAN1_CAMERA_CONNECTED",
        "connector_label": "UNKNOWN",
        "scans": SCAN_COUNT,
        "first_generation": INITIAL_GENERATION + 1,
        "last_generation": INITIAL_GENERATION + SCAN_COUNT,
        "scanner_integrity_pass": SCAN_COUNT,
        "a8_bookend_stable_scans": sum(record["a8_bookend_stable"] for record in scans),
        "a8_bookend_changed_scans": sum(not record["a8_bookend_stable"] for record in scans),
        "host_start_intervals_ms": [record["host_start_interval_ms"] for record in scans[1:]],
        "host_interval_contract": "1.0_SECONDS",
        "pre_scan_wait_contract": "EXACT_2.0_SECONDS_NO_SCANNER_OR_NVP_OPERATION",
        "pre_scan_wait_elapsed_ms": wait_elapsed_ms,
        "stable_candidate_rule": "AT_LEAST_3_AGREEING_A8_BOOKEND_STABLE_CONNECTED_SNAPSHOTS",
        "stable_candidate_channels_observed": stable_channels,
        "stable_candidate_observations": stable_observations,
        "entry_bank_restore_pass": SCAN_COUNT,
        "prohibited_reads": 0,
        "nack": 0,
        "timeout": 0,
        "bank_mismatch": 0,
        "functional_nvp_writes": 0,
        "set_chnmode_calls": 0,
        "eq_sweep_calls": 0,
        "slice_sweep_calls": 0,
        "snapshot_mutation_before_ack": 0,
        "transport_disabled": True,
        "physical_quiescence": "PASS",
        "pending_aio": 0,
        "background_scanning": False,
        "boot_id": EXPECTED_BOOT,
        "kernel_delta": delta,
        "dpc_aer_events": 0,
        "bundle_manifest_identity": raw_manifest["manifest_sha256"],
        "baseline_rows_replayed": len(baseline_rows),
        "noninterference_report_sha256": sha256(NONINTERFERENCE_REPORT),
        "connected_jsonl": str(CONNECTED_JSONL),
        "connected_jsonl_sha256": sha256(CONNECTED_JSONL),
        "next_human_gate": "SCAN1-C",
        "required_owner_reply": "SCAN1_RETURN_CONTROL_READY",
    }
    write_json_new(STATE_OUTPUT, state_result)
    write_json_new(REPORT, result)
    write_json_new(OUTPUT, result)
    print(json.dumps({
        "task": TASK,
        "result": "PASS",
        "scans": SCAN_COUNT,
        "generations": "264..273",
        "a8_bookend_stable_scans": result["a8_bookend_stable_scans"],
        "stable_candidate_channels_observed": stable_channels,
        "host_start_intervals_ms": result["host_start_intervals_ms"],
        "pre_scan_wait_elapsed_ms": wait_elapsed_ms,
        "entry_bank_restore_pass": SCAN_COUNT,
        "pending_aio": 0,
        "transport_disabled": True,
        "next_human_gate": "SCAN1-C",
    }, sort_keys=True))
    print("SCAN1_CONNECTED_CAMERA_GATE=PASS_10/10")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args()
    raise SystemExit(self_check() if args.self_check else main())
