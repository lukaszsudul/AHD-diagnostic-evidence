#!/usr/bin/env python3
# SANITIZED PUBLICATION COPY; executed-source SHA-256: B637DB356B319277F6EE3DB74C2762CF80AF64C44F9B650126EF50ED0AB219E8
"""Five exact disconnected return-control SCAN1 scans at 1.0 s intervals."""

from __future__ import annotations

import argparse
import dataclasses
import importlib.util
import json
import os
import pathlib
import re
import struct
import time


P = pathlib.Path
TASK = "G2B-NVP-CAMERA-SCAN1-R1R1"
ROOT = P("/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1/20260911T202728Z")
BUNDLE = ROOT / "runtime-bundle"
DEVICE = P("/dev/xdma0_user")
ENDPOINT = P("/sys/bus/pci/devices/0000:01:00.0")
ROOT_PORT = P("/sys/bus/pci/devices/0000:00:01.1")
EXPECTED_BOOT = "cf1515d9-7238-4bf0-9c7d-7196efb2e762"

CONNECTED_SUPPORT = ROOT / "private/connected_scan_gate.py"
CONNECTED_SUPPORT_SHA256 = "56CF75D843E312AE73734437DD092EA3CDEEE9A14D84D6DE13E923A4F515B5DC"
OWNER_REPLY = ROOT / "private/owner-reply-scan1-c.txt"
OWNER_REPLY_SHA256 = "6431F6B75B99127FD127D7E5B77B82279C399F6C8BB2EC522EFFBF11179DC85F"
CONNECTED_REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_GATE.json"
CONNECTED_REPORT_SHA256 = "6020C81862B09319F2AAE34C20225A56C43FFBFC094301D4D6E4203AF977997A"
CONNECTED_STATE = ROOT / "campaign/state-after-connected.json"
CONNECTED_STATE_SHA256 = "12BF1A888B3CD3EEE79B9C681B7FE8ACA92935382FE830E32F8FA339A9B0D38F"
CONNECTED_JSONL = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_SCANS.jsonl"
CONNECTED_JSONL_SHA256 = "752C92C3CBD52237EAFFAA0BA15CE727ECCFA9C06836E822CE54B2BF58F328C1"
CONNECTED_PREFIX = ROOT / "scanner/connected"

PREFIX_ROOT = ROOT / "scanner/return-control"
RETURN_JSONL = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_RETURN_CONTROL_SCANS.jsonl"
STATE_OUTPUT = ROOT / "campaign/state-after-return-control.json"
OUTPUT = ROOT / "logs/return-control-scan-gate.json"
REPORT = ROOT / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_RETURN_CONTROL_GATE.json"
SCAN_COUNT = 5
INITIAL_GENERATION = 273
INTERVAL_NS = 1_000_000_000


def load_connected_support() -> object:
    digest = __import__("hashlib").sha256(CONNECTED_SUPPORT.read_bytes()).hexdigest().upper()
    if digest != CONNECTED_SUPPORT_SHA256:
        raise RuntimeError("CONNECTED_SUPPORT_SHA256_MISMATCH")
    spec = importlib.util.spec_from_file_location("scan1_r1r1_connected_support", CONNECTED_SUPPORT)
    if spec is None or spec.loader is None:
        raise RuntimeError("CONNECTED_SUPPORT_IMPORT_SPEC")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_phase_inputs(common: object, state_module: object) -> tuple[object, object, list[dict], list[dict]]:
    common.require(common.sha256(OWNER_REPLY) == OWNER_REPLY_SHA256, "OWNER_REPLY_SHA256_MISMATCH")
    owner_fields = dict(line.split("=", 1) for line in OWNER_REPLY.read_text().splitlines())
    common.require(
        owner_fields.get("TASK") == TASK
        and owner_fields.get("HUMAN_GATE") == "SCAN1-C"
        and owner_fields.get("OWNER_REPLY") == "SCAN1_RETURN_CONTROL_READY"
        and owner_fields.get("AUTHORIZED_NEXT_PHASE") == "FIVE_RETURN_CONTROL_ONESHOT_SCANS"
        and owner_fields.get("STATE") == "ACCEPTED_EXACT_REPLY",
        "OWNER_REPLY_NOT_EXACT",
    )

    common.require(common.sha256(CONNECTED_REPORT) == CONNECTED_REPORT_SHA256,
                   "CONNECTED_REPORT_SHA256_MISMATCH")
    common.require(common.sha256(CONNECTED_STATE) == CONNECTED_STATE_SHA256,
                   "CONNECTED_STATE_SHA256_MISMATCH")
    common.require(common.sha256(CONNECTED_JSONL) == CONNECTED_JSONL_SHA256,
                   "CONNECTED_JSONL_SHA256_MISMATCH")
    connected_report = json.loads(CONNECTED_REPORT.read_text())
    connected_state = json.loads(CONNECTED_STATE.read_text())
    connected_rows = common.load_jsonl(CONNECTED_JSONL)
    common.require(
        connected_report.get("task") == TASK
        and connected_report.get("result") == "PASS"
        and connected_report.get("scans") == 10
        and connected_report.get("scanner_integrity_pass") == 10
        and connected_report.get("last_generation") == INITIAL_GENERATION
        and connected_report.get("next_human_gate") == "SCAN1-C"
        and connected_report.get("required_owner_reply") == "SCAN1_RETURN_CONTROL_READY",
        "CONNECTED_REPORT_NOT_PASS",
    )
    common.require(
        connected_state.get("task") == TASK
        and connected_state.get("phase") == "CONNECTED_CAMERA_COMPLETE"
        and connected_state.get("last_generation") == INITIAL_GENERATION
        and connected_state.get("human_gate") == "SCAN1-C"
        and connected_state.get("required_owner_reply") == "SCAN1_RETURN_CONTROL_READY",
        "CONNECTED_STATE_NOT_AT_SCAN1_C",
    )
    common.require(len(connected_rows) == 10, "CONNECTED_JSONL_COUNT_NOT_10")

    campaign, baseline_rows, _ = common.validate_phase_inputs(state_module)
    connected_phase = state_module.CampaignState(TASK + "-CONNECTED-PHASE")
    for scan_index, row in enumerate(connected_rows, start=1):
        common.require(
            row.get("phase") == "CONNECTED_CAMERA"
            and row.get("scan") == scan_index
            and row.get("generation") == 263 + scan_index
            and row.get("result") == "PASS_ACKNOWLEDGED_IDLE",
            f"CONNECTED_ROW_IDENTITY:{scan_index}",
        )
        snapshot_path = CONNECTED_PREFIX / f"scan-{scan_index:04d}.json"
        raw_path = CONNECTED_PREFIX / f"scan-{scan_index:04d}.bin"
        common.require(common.sha256(snapshot_path) == row["decoded_snapshot_sha256"],
                       f"CONNECTED_DECODED_HASH:{scan_index}")
        common.require(common.sha256(raw_path) == row["raw_snapshot_sha256"],
                       f"CONNECTED_RAW_HASH:{scan_index}")
        snapshot = json.loads(snapshot_path.read_text())
        common.require(snapshot.get("generation") == 263 + scan_index,
                       f"CONNECTED_SNAPSHOT_GENERATION:{scan_index}")
        campaign.update("CONNECTED_CAMERA", snapshot)
        connected_phase.update("CONNECTED_CAMERA", snapshot)

    replayed_campaign = common.canonical({
        name: dataclasses.asdict(value) for name, value in campaign.channels.items()
    })
    replayed_connected = common.canonical({
        name: dataclasses.asdict(value) for name, value in connected_phase.channels.items()
    })
    common.require(connected_state.get("channels") == replayed_campaign,
                   "CONNECTED_CAMPAIGN_STATE_REPLAY_MISMATCH")
    common.require(connected_state.get("connected_phase_channels") == replayed_connected,
                   "CONNECTED_PHASE_STATE_REPLAY_MISMATCH")
    return campaign, connected_phase, baseline_rows, connected_rows


def preflight() -> tuple[object, object, object, object, object, object, object]:
    common = load_connected_support()
    for path in (PREFIX_ROOT, RETURN_JSONL, STATE_OUTPUT, OUTPUT, REPORT):
        common.require(not path.exists(), f"RETURN_CONTROL_OUTPUT_PREEXISTS:{path}")
    lock = common.load_lock()
    common.require(lock.get("TASK") == TASK and lock.get("RUN_ROOT") == str(ROOT) and lock.get("STATE") == "HELD",
                   "DUT_LOCK_OWNER_MISMATCH")
    support = common.load_support()
    controller, evidence, manifest, mmio, state = common.import_bundle()
    entries, prohibited, raw_manifest = manifest.load_and_validate()
    common.require(len(entries) == 82 and len(prohibited) == 14, "FROZEN_MANIFEST_COUNT_MISMATCH")
    campaign, connected_phase, baseline_rows, connected_rows = validate_phase_inputs(common, state)
    return common, support, controller, evidence, manifest, mmio, (
        state, entries, raw_manifest, campaign, connected_phase, baseline_rows, connected_rows
    )


def self_check() -> int:
    _, _, _, _, _, _, details = preflight()
    _, entries, raw_manifest, campaign, connected_phase, baseline_rows, connected_rows = details
    print(json.dumps({
        "task": TASK,
        "result": "PASS",
        "mode": "OFFLINE_SELF_CHECK",
        "owner_reply": "SCAN1_RETURN_CONTROL_READY",
        "baseline_rows_replayed": len(baseline_rows),
        "connected_rows_replayed": len(connected_rows),
        "campaign_channels_replayed": len(campaign.channels),
        "connected_phase_channels_replayed": len(connected_phase.channels),
        "manifest_entries": len(entries),
        "manifest_sha256": raw_manifest["manifest_sha256"],
        "planned_return_control_scans": SCAN_COUNT,
        "planned_start_interval_seconds": 1.0,
        "device_opened": False,
        "scanner_operation": False,
        "nvp_operation": False,
    }, sort_keys=True))
    print("SCAN1_RETURN_CONTROL_OFFLINE_SELF_CHECK=PASS")
    return 0


def main() -> int:
    common, support, controller, evidence, manifest, mmio, details = preflight()
    state, entries, raw_manifest, campaign, connected_phase, baseline_rows, connected_rows = details

    common.require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
                   "BOOT_ID_DRIFT_BEFORE_RETURN_CONTROL")
    common.require(P("/sys/module/xdma_ahd_pcie").is_dir(), "EXACT_DRIVER_NOT_RETAINED")
    common.require(ENDPOINT.is_dir() and (ENDPOINT / "driver").resolve().name == "xdma_ahd_pcie",
                   "ENDPOINT_OR_DRIVER_MISMATCH")
    common.require(DEVICE.is_char_device(), "XDMA_USER_NODE_NOT_CHAR_DEVICE")
    common.require(not support.open_xdma_fds(), "PREEXISTING_XDMA_FD")
    common.require(int(P("/proc/sys/fs/aio-nr").read_text().strip()) == 0,
                   "PENDING_AIO_BEFORE_RETURN_CONTROL")

    kernel_before = support.dmesg_bytes()
    aer_before = {"endpoint": support.aer(ENDPOINT), "root_port": support.aer(ROOT_PORT)}
    return_phase = state.CampaignState(TASK + "-RETURN-CONTROL-PHASE")
    device = common.TimedDevice(support.BoundedDevice, DEVICE)
    immutable: dict[str, dict[str, object]] = {}
    original_persist = evidence.persist_snapshot
    scans: list[dict[str, object]] = []
    stable_observations: list[dict[str, object]] = []

    with RETURN_JSONL.open("x") as return_handle:
        return_handle.flush()
        os.fsync(return_handle.fileno())
        with device:
            common.require(device.read32(mmio.STATUS) == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                           "SCANNER_NOT_IDLE_BEFORE_RETURN_CONTROL")
            common.require(device.read32(mmio.GENERATION) == INITIAL_GENERATION,
                           "RETURN_CONTROL_INITIAL_GENERATION_NOT_273")
            common.require(device.read32(0x1006C) & 0x3 == 0x1 and device.read32(0x10090) == 0,
                           "AUTOINIT_NOT_CLEAN_BEFORE_RETURN_CONTROL")
            common.require(device.read32(0x0380C) == 0 and device.read32(0x03810) & 0x10F == 0x004,
                           "TRANSPORT_NOT_QUIESCENT_BEFORE_RETURN_CONTROL")

            def persist_and_verify(prefix: P, snapshot: dict) -> dict[str, str | int]:
                expected_words = list(snapshot["_raw_words"])
                receipt = original_persist(prefix, snapshot)
                raw_path = P(str(receipt["raw_path"]))
                json_path = P(str(receipt["json_path"]))
                common.require(
                    raw_path.read_bytes() == b"".join(struct.pack("<I", word) for word in expected_words),
                    "RETURN_CONTROL_PERSISTED_RAW_MISMATCH",
                )
                generation0 = device.read32(mmio.GENERATION)
                header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
                reread = [device.read32(address) for address in header_addresses]
                reread += [device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
                reread += [device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(82)]
                generation1 = device.read32(mmio.GENERATION)
                common.require(generation0 == generation1 == snapshot["generation"],
                               "RETURN_CONTROL_GENERATION_MUTATED_BEFORE_ACK")
                common.require(reread == expected_words, "RETURN_CONTROL_SNAPSHOT_MUTATED_BEFORE_ACK")
                immutable[prefix.name] = {
                    "raw_mtime_ns": raw_path.stat().st_mtime_ns,
                    "json_mtime_ns": json_path.stat().st_mtime_ns,
                    "raw_sha256": common.sha256(raw_path),
                    "json_sha256": common.sha256(json_path),
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
                    common.require(device.read32(mmio.STATUS) == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                                   f"RETURN_CONTROL_NOT_IDLE_AT_START:{scan_index}")
                    write_before = len(device.write_log)
                    snapshot, receipt = scanner.oneshot(
                        PREFIX_ROOT / f"scan-{scan_index:04d}", timeout_seconds=3.0
                    )
                    common.require(len(device.write_log) == write_before + 2,
                                   f"RETURN_CONTROL_WRITE_COUNT:{scan_index}")
                    pair = device.write_log[write_before:write_before + 2]
                    common.require([(row["address"], row["value"]) for row in pair] == [
                        (mmio.CONTROL, mmio.CONTROL_ONESHOT),
                        (mmio.CONTROL, mmio.CONTROL_ACK_CLEAR),
                    ], f"RETURN_CONTROL_SEQUENCE:{scan_index}")
                    start_ns = pair[0]["start_monotonic_ns"]
                    interval_ms = None if previous_start_ns is None else (start_ns - previous_start_ns) / 1_000_000.0
                    if interval_ms is not None:
                        common.require(995.0 <= interval_ms <= 1010.0,
                                       f"RETURN_CONTROL_START_INTERVAL:{scan_index}:{interval_ms:.6f}")
                    previous_start_ns = start_ns
                    iv = immutable[f"scan-{scan_index:04d}"]
                    common.require(int(iv["raw_mtime_ns"]) <= pair[1]["start_wall_ns"] and
                                   int(iv["json_mtime_ns"]) <= pair[1]["start_wall_ns"],
                                   f"RETURN_CONTROL_NOT_PERSISTED_BEFORE_ACK:{scan_index}")
                    common.require(snapshot["generation"] == INITIAL_GENERATION + scan_index,
                                   f"RETURN_CONTROL_GENERATION_SEQUENCE:{scan_index}")
                    common.require(snapshot["entry_count"] == 82 and snapshot["bank_group_count"] == 10 and
                                   snapshot["transaction_count"] == 105,
                                   f"RETURN_CONTROL_COUNT_GATE:{scan_index}")
                    common.require(snapshot["entry_bank_restore"] == "PASS" and
                                   snapshot["entry_bank"] == snapshot["exit_bank"],
                                   f"RETURN_CONTROL_BANK_RESTORE:{scan_index}")
                    common.require(snapshot["consistency_attempt"] == 1 and
                                   all(entry["status"] == 0x05 for entry in snapshot["raw_register_set"]),
                                   f"RETURN_CONTROL_INTEGRITY:{scan_index}")
                    raw_words = list(struct.unpack("<146I", P(str(receipt["raw_path"])).read_bytes()))
                    support.validate_groups(raw_words[24:64], entries, manifest.GROUP_NAMES)
                    common.require(iv["raw_sha256"] == receipt["raw_sha256"] and
                                   iv["json_sha256"] == receipt["json_sha256"],
                                   f"RETURN_CONTROL_HASH_READBACK:{scan_index}")

                    campaign.update("RETURN_CONTROL_DISCONNECTED", snapshot)
                    return_phase.update("RETURN_CONTROL_DISCONNECTED", snapshot)
                    channels = {
                        name: common.channel_record(snapshot, name, index)
                        for index, name in enumerate(("CH1", "CH2", "CH3", "CH4"))
                    }
                    scan_candidates: list[str] = []
                    for name in ("CH1", "CH2", "CH3", "CH4"):
                        global_state = campaign.channels[name]
                        phase_state = return_phase.channels[name]
                        stable_candidate = (
                            phase_state.agreeing_sample_count >= 3
                            and phase_state.confirmed_format is not None
                        )
                        channels[name]["campaign_agreeing_stable_samples"] = global_state.agreeing_sample_count
                        channels[name]["campaign_confirmed_class"] = global_state.confirmed_format
                        channels[name]["return_phase_agreeing_stable_samples"] = phase_state.agreeing_sample_count
                        channels[name]["return_phase_confirmed_class"] = phase_state.confirmed_format
                        channels[name]["stable_return_control_candidate"] = stable_candidate
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
                        "phase": "RETURN_CONTROL_DISCONNECTED",
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
                        "stable_return_control_candidate_channels": scan_candidates,
                        "channels": channels,
                        "raw_entries": snapshot["raw_register_set"],
                        "result": "PASS_ACKNOWLEDGED_IDLE",
                    }
                    return_handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
                    return_handle.flush()
                    os.fsync(return_handle.fileno())
                    scans.append(record)
            finally:
                evidence.persist_snapshot = original_persist

            status_final = device.read32(mmio.STATUS)
            generation_final = device.read32(mmio.GENERATION)
            autoinit_final = device.read32(0x1006C)
            autoinit_detail_final = device.read32(0x10090)
            transport_control_final = device.read32(0x0380C)
            transport_status_final = device.read32(0x03810)

    common.require(len(scans) == SCAN_COUNT and generation_final == INITIAL_GENERATION + SCAN_COUNT,
                   "RETURN_CONTROL_FINAL_COUNT_OR_GENERATION")
    common.require(status_final == mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE,
                   "SCANNER_NOT_IDLE_AFTER_RETURN_CONTROL")
    common.require(autoinit_final & 0x3 == 0x1 and autoinit_detail_final == 0,
                   "AUTOINIT_NOT_CLEAN_AFTER_RETURN_CONTROL")
    common.require(transport_control_final == 0 and transport_status_final & 0x10F == 0x004,
                   "TRANSPORT_NOT_QUIESCENT_AFTER_RETURN_CONTROL")
    common.require(len(device.write_log) == 2 * SCAN_COUNT and
                   all(row["address"] == mmio.CONTROL for row in device.write_log),
                   "RETURN_CONTROL_NON_CONTROL_WRITE_OR_WRITE_COUNT")
    common.require(device.timeout_count == 0 and device.short_read_count == 0 and
                   device.short_write_count == 0, "RETURN_CONTROL_MMIO_OPERATION_ERROR")
    common.require(not support.open_xdma_fds(), "XDMA_FD_REMAINED_AFTER_RETURN_CONTROL")
    common.require(int(P("/proc/sys/fs/aio-nr").read_text().strip()) == 0,
                   "PENDING_AIO_AFTER_RETURN_CONTROL")

    kernel_after = support.dmesg_bytes()
    common.require(kernel_after.startswith(kernel_before), "KERNEL_LOG_CONTINUITY_LOST")
    delta = kernel_after[len(kernel_before):].decode("utf-8", "replace")
    kernel_matches = re.findall(
        r"(?im)^.*(?:\bDPC\b|AER:|PCIe Bus Error|malformed TLP|unsupported request|"
        r"surprise link|link[- ]down|completion timeout|IOMMU fault|xdma[^\n]*fatal).*$", delta,
    )
    aer_after = {"endpoint": support.aer(ENDPOINT), "root_port": support.aer(ROOT_PORT)}
    common.require(not kernel_matches and aer_after == aer_before,
                   "KERNEL_PCIE_ERROR_DURING_RETURN_CONTROL")
    common.require(P("/proc/sys/kernel/random/boot_id").read_text().strip() == EXPECTED_BOOT,
                   "UNEXPECTED_REBOOT_DURING_RETURN_CONTROL")

    stable_channels = sorted({str(item["channel"]) for item in stable_observations})
    state_result = {
        "task": TASK,
        "campaign_id": campaign.campaign_id,
        "phase": "PHYSICAL_CAMPAIGN_OFF_ON_OFF_COMPLETE",
        "connector_label": "UNKNOWN",
        "last_generation": INITIAL_GENERATION + SCAN_COUNT,
        "accepted_campaign_scans": 20,
        "human_gate": "NONE",
        "required_owner_reply": "NONE",
        "channels": {name: dataclasses.asdict(value) for name, value in campaign.channels.items()},
        "connected_phase_channels": {
            name: dataclasses.asdict(value) for name, value in connected_phase.channels.items()
        },
        "return_phase_channels": {
            name: dataclasses.asdict(value) for name, value in return_phase.channels.items()
        },
    }
    result = {
        "task": TASK,
        "result": "PASS",
        "utc_ns": time.time_ns(),
        "owner_reply": "SCAN1_RETURN_CONTROL_READY",
        "connector_label": "UNKNOWN",
        "baseline_scans": len(baseline_rows),
        "connected_scans": len(connected_rows),
        "return_control_scans": SCAN_COUNT,
        "accepted_campaign_scans": 20,
        "first_generation": INITIAL_GENERATION + 1,
        "last_generation": INITIAL_GENERATION + SCAN_COUNT,
        "scanner_integrity_pass": SCAN_COUNT,
        "a8_bookend_stable_scans": sum(record["a8_bookend_stable"] for record in scans),
        "a8_bookend_changed_scans": sum(not record["a8_bookend_stable"] for record in scans),
        "host_start_intervals_ms": [record["host_start_interval_ms"] for record in scans[1:]],
        "host_interval_contract": "1.0_SECONDS",
        "stable_candidate_rule": "AT_LEAST_3_AGREEING_A8_BOOKEND_STABLE_RETURN_CONTROL_SNAPSHOTS",
        "stable_candidate_channels_observed": stable_channels,
        "stable_candidate_observations": stable_observations,
        "entry_bank_restore_pass": SCAN_COUNT,
        "prohibited_reads": 0,
        "nack": 0,
        "timeout": 0,
        "bank_mismatch": 0,
        "functional_nvp_writes": 0,
        "snapshot_mutation_before_ack": 0,
        "transport_disabled": True,
        "physical_quiescence": "PASS",
        "pending_aio": 0,
        "background_scanning": False,
        "boot_id": EXPECTED_BOOT,
        "kernel_delta": delta,
        "dpc_aer_events": 0,
        "bundle_manifest_identity": raw_manifest["manifest_sha256"],
        "connected_jsonl_sha256": common.sha256(CONNECTED_JSONL),
        "return_control_jsonl": str(RETURN_JSONL),
        "return_control_jsonl_sha256": common.sha256(RETURN_JSONL),
        "physical_campaign": "PASS_OFF_ON_OFF_20/20",
    }
    common.write_json_new(STATE_OUTPUT, state_result)
    common.write_json_new(REPORT, result)
    common.write_json_new(OUTPUT, result)
    print(json.dumps({
        "task": TASK,
        "result": "PASS",
        "scans": SCAN_COUNT,
        "generations": "274..278",
        "accepted_campaign_scans": "20/20",
        "a8_bookend_stable_scans": result["a8_bookend_stable_scans"],
        "stable_candidate_channels_observed": stable_channels,
        "host_start_intervals_ms": result["host_start_intervals_ms"],
        "entry_bank_restore_pass": SCAN_COUNT,
        "pending_aio": 0,
        "transport_disabled": True,
        "physical_campaign": "PASS_OFF_ON_OFF",
    }, sort_keys=True))
    print("SCAN1_RETURN_CONTROL_GATE=PASS_5/5")
    print("SCAN1_PHYSICAL_CAMPAIGN=PASS_20/20")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args()
    raise SystemExit(self_check() if args.self_check else main())
