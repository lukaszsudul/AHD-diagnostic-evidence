#!/usr/bin/env python3
"""Bounded C3 CH1 SCAN1/ACQ coordinator; no DMA, capture, or generic I2C.

The caller supplies the physical confirmation and separately audited ACQ and
readiness gates. This program never infers write authority from NOVID alone.
Every complete frozen SCAN1 and CONT1R3 telemetry image is fsynced before ACK.
An interrupted command is not repeated automatically.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import sys
import time


TASK = "CONT1R3R4R10-CAMERA-READY-CH1-C3"
SOURCE = "70266f0b90c6fc6a853495eba1d526b285fd7286"
SHA_WORDS = (0x70266F0B, 0x90C6FC6A, 0x853495EB, 0xA1D526B2, 0x85FD7286)
MAX_SCANS = 30
PHYSICAL = re.compile(r"^CAMERA_CH1_CONNECTED(?::[^:\r\n]{1,64}:[^\r\n]{1,128})?$")


def need(ok: bool, reason: str) -> None:
    if not ok:
        raise RuntimeError(reason)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def canonical(value: object) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode("ascii")


def write_once(path: Path, data: bytes) -> str:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(fd, "wb", closefd=False) as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        os.close(fd)
    return sha(data)


def save_state(path: Path, state: dict) -> None:
    temp = path.with_name(path.name + ".tmp")
    need(not temp.exists(), "STATE_TEMP_PREEXISTS_MANUAL_REVIEW_REQUIRED")
    write_once(temp, canonical(state))
    os.replace(temp, path)
    directory = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(directory)
    finally:
        os.close(directory)


def load_state(path: Path) -> dict:
    state = json.loads(path.read_bytes())
    need(state["task"] == TASK and state["source_commit"] == SOURCE,
         "STATE_TASK_OR_SOURCE_MISMATCH")
    need(0 <= state["scans_started"] <= MAX_SCANS and
         state["scans_completed"] <= state["scans_started"], "STATE_SCAN_BUDGET_INVALID")
    return state


def load_gate(path: Path, *, kind: str, state: dict) -> dict:
    gate = json.loads(path.read_bytes())
    need(gate.get("task") == TASK and gate.get("boot_id") == state["boot_id"] and
         gate.get("source_commit") == SOURCE and
         gate.get("physical_confirmation") == state["physical_confirmation"] and
         gate.get("kind") == kind, "GATE_SESSION_IDENTITY_MISMATCH")
    return gate


def modules():
    from acq1_compat0_r2.controller import Command, ExecutorController, ExecutorActionError
    from acq1_compat0_r2 import format_decision
    from cont1r3 import telemetry
    from cont1r3.characterizer import LiveScanner
    from scan1 import decoder, mmio
    from scan1.controller import ScannerController
    from w3a.controller import W3AController, OBSERVED
    from w3a.device import VerifiedMmioDevice
    return (Command, ExecutorController, ExecutorActionError,
            format_decision, telemetry, LiveScanner, decoder, mmio,
            ScannerController, W3AController, OBSERVED, VerifiedMmioDevice)


class Run:
    def __init__(self, device, root: Path, state: dict, api):
        (self.Command, self.ExecutorController, self.ExecutorActionError,
         self.format_decision, self.telemetry, self.LiveScanner,
         self.decoder, self.mmio, self.ScannerController,
         self.W3AController, self.OBSERVED, _) = api
        self.device, self.root, self.state = device, root, state
        self.state_path = root / "state.json"
        self.scanner = self.LiveScanner(device)
        self.executor = self.ExecutorController(device)
        self.w3a = self.W3AController(device)

    def persist(self) -> None:
        save_state(self.state_path, self.state)

    def identity(self) -> dict:
        d = self.device
        words = tuple(d.read32(a) for a in (0x10, 0x14, 0x18, 0x1C, 0x20))
        need(words == SHA_WORDS and d.read32(0x2C) == 0x00000802 and
             d.read32(0x08) == 0x00031002, "C3_RUNTIME_SOURCE_IDENTITY_MISMATCH")
        scan = self.ScannerController(d).identity()
        acq = self.executor.identity()
        telemetry = self.telemetry.read_identity(d)
        w3a = self.w3a.identity()
        return {"git_words": [f"{x:08X}" for x in words],
                "scan1": scan, "acq": acq, "telemetry": telemetry, "w3a": w3a}

    def idle(self) -> dict:
        d, m = self.device, self.mmio
        scan = d.read32(m.STATUS)
        acq = self.executor.snapshot()
        w3a = d.read32(0x13818)
        stream = d.read32(0x380C)
        need(scan == (m.STATUS_IDLE | m.STATUS_AUTOINIT_DONE),
             f"SCAN1_NOT_CLEAN_IDLE:{scan:#010x}")
        need(acq["idle"] and not acq["busy"] and not acq["hard_fail"] and
             not acq["bank_context_lockout"] and not acq["scanner_busy"] and
             acq["i2c_bus_idle"], "ACQ_EXECUTOR_OR_I2C_NOT_IDLE")
        need(w3a & ((1 << 1) | (1 << 3) | (1 << 7)) == 0,
             f"W3A_NOT_OFF_OR_LOCKOUT:{w3a:#010x}")
        need(stream == 0, f"TRANSPORT_STREAM_NOT_OFF:{stream:#010x}")
        return {"scan1_status": scan, "acq": acq, "w3a_status": w3a,
                "stream_enable": stream}

    def _best_effort_scan_stop(self, error: Exception) -> None:
        """Preserve readable frozen/sticky words; never ACK an uncertain scan."""
        inflight = self.state.get("inflight") or {}
        serial = inflight.get("serial", self.state["scans_started"])
        groups = {
            "scan_header": list(range(self.mmio.STATUS, self.mmio.DIGEST_BASE + 8 * 4, 4)),
            "scan_groups": [self.mmio.GROUP_BASE + 4 * i for i in range(40)],
            "scan_entries": [self.mmio.ENTRY_BASE + 4 * i for i in range(82)],
            "telemetry_header": list(range(0x12800, 0x12880, 4)),
            "telemetry_groups": [0x12880 + 4 * i for i in range(50)],
            "telemetry_entries": [0x12A00 + 4 * i for i in range(820)],
            "w3a_observed": list(self.OBSERVED),
            "acq_status": list(range(0x12410, 0x1244C, 4)),
        }
        raw = {}
        for name, addresses in groups.items():
            values = {}
            for address in addresses:
                try:
                    values[f"{address:#x}"] = self.device.read32(address)
                except Exception as failure:
                    values[f"{address:#x}"] = "UNAVAILABLE:" + type(failure).__name__
            raw[name] = values
        receipt = {"task": TASK, "kind": "SCAN_HARD_STOP", "serial": serial,
                   "error": str(error), "error_type": type(error).__name__,
                   "qualified_frozen_snapshot": False,
                   "raw_master_first_failure_proof": False,
                   "ack_clear_attempted": bool(inflight.get("ack_started")),
                   "utc_ns": time.time_ns(),
                   "raw_best_effort_noncoherent": raw}
        target = self.root / "hard-stop" / f"scan-{serial:02d}.json"
        if not target.exists():
            write_once(target, canonical(receipt))
        self.state["stage"] = "SCAN_HARD_STOP"
        self.state["stop_receipt"] = str(target)
        self.persist()

    def scan(self, label: str) -> dict:
        try:
            return self._scan_impl(label)
        except Exception as error:
            if (self.state.get("inflight") or {}).get("kind") == "SCAN":
                self._best_effort_scan_stop(error)
            raise

    def _scan_impl(self, label: str) -> dict:
        need(self.state["scans_started"] < MAX_SCANS, "SCAN_BUDGET_EXHAUSTED")
        self.identity()
        before = self.idle()
        generation_before = self.device.read32(self.mmio.GENERATION)
        self.state["scans_started"] += 1
        serial = self.state["scans_started"]
        self.state["inflight"] = {"kind": "SCAN", "serial": serial, "label": label}
        self.persist()
        self.scanner.start()
        snapshot = self.scanner.read_legacy_frozen()
        snapshot["channels"] = self.decoder.detector_tuples(
            snapshot["raw_register_set"], snapshot["a8_post"])
        snapshot["live_status_changed"] = snapshot["a8_pre"] != snapshot["a8_post"]
        sideband = self.telemetry.read_frozen(self.device, snapshot)
        w3a_raw = {f"{a:#x}": self.device.read32(a) for a in self.OBSERVED}
        after_acq = self.executor.snapshot()
        # Both frozen images and the complete decoded record precede ACK/CLEAR.
        raw = (struct.pack("<II", len(snapshot["_raw_words"]), len(sideband["_raw_words"])) +
               struct.pack(f"<{len(snapshot['_raw_words'])}I", *snapshot["_raw_words"]) +
               struct.pack(f"<{len(sideband['_raw_words'])}I", *sideband["_raw_words"]))
        prefix = self.root / "scans" / f"{serial:02d}-{label}"
        raw_sha = write_once(prefix.with_suffix(".bin"), raw)
        decoded = {key: val for key, val in snapshot.items() if key != "_raw_words"}
        tele = {key: val for key, val in sideband.items() if key != "_raw_words"}
        row = {"task": TASK, "serial": serial, "label": label,
               "boot_id": self.state["boot_id"], "source_commit": SOURCE,
               "collected_utc_ns": time.time_ns(), "generation_before": generation_before,
               "snapshot": decoded, "telemetry": tele, "w3a_raw": w3a_raw,
               "acq_before": before["acq"], "acq_after": after_acq,
               "raw_sha256": raw_sha, "raw_bytes": len(raw)}
        json_sha = write_once(prefix.with_suffix(".json"), canonical(row))
        need(snapshot["generation"] != generation_before,
             "SCAN_GENERATION_UNCHANGED_RAW_PRESERVED_NO_ACK")
        need(snapshot["entry_count"] == 82 and snapshot["valid_entry_count"] == 82 and
             snapshot["bank_group_count"] == 10 and snapshot["transaction_count"] == 105 and
             snapshot["retried_entry_count"] == 0 and not sideband["events"] and
             snapshot["entry_bank_restore"] == "PASS" and
             not snapshot["live_status_changed"],
             "SCAN_INCOMPLETE_RETRY_OR_A8_MUTATION_RAW_PRESERVED_NO_ACK")
        need(after_acq["nack_count"] == before["acq"]["nack_count"] and
             after_acq["timeout_count"] == before["acq"]["timeout_count"] and
             after_acq["bank_verify_failure_count"] ==
             before["acq"]["bank_verify_failure_count"],
             "NEW_ACQ_ERROR_DURING_SCAN_RAW_PRESERVED_NO_ACK")
        self.state["inflight"]["ack_started"] = True
        self.persist()
        self.scanner.acknowledge()
        self.idle()
        self.state["scans_completed"] += 1
        self.state["scans"].append({"serial": serial, "label": label,
                                    "raw_sha256": raw_sha, "json_sha256": json_sha,
                                    "novid": snapshot["channels"]["CH1"]["novid"],
                                    "a8_pre": snapshot["a8_pre"],
                                    "a8_post": snapshot["a8_post"],
                                    "raw_f0": snapshot["channels"]["CH1"]["raw_f0"]})
        self.state["inflight"] = None
        self.persist()
        return row

    def window(self, rows: list[dict]) -> int | None:
        if len(rows) < 3:
            return None
        last = rows[-3:]
        values = [int(row["snapshot"]["channels"]["CH1"]["novid"]) for row in last]
        return values[0] if len(set(values)) == 1 else None

    def action(self, command) -> dict:
        self.identity()
        self.idle()
        need(self.state["inflight"] is None, "INFLIGHT_OPERATION_REVIEW_REQUIRED")
        index = len(self.state["actions"]) + 1
        self.state["inflight"] = {"kind": "ACQ", "index": index,
                                   "command": command.name}
        self.persist()
        try:
            receipt = self.executor.issue(command)
        except self.ExecutorActionError as error:
            receipt = error.receipt
            receipt["failure"] = str(error)
            write_once(self.root / "actions" / f"{index:02d}-{command.name}.json",
                       canonical(receipt))
            raise
        receipt_sha = write_once(self.root / "actions" / f"{index:02d}-{command.name}.json",
                                 canonical(receipt))
        self.state["actions"].append({"command": command.name,
                                      "receipt_sha256": receipt_sha,
                                      "functional_write_delta": receipt["functional_write_delta"]})
        self.state["write_occurred"] |= receipt["functional_write_delta"] > 0
        self.state["inflight"] = None
        self.persist()
        need(receipt["nack_delta"] == 0 and receipt["timeout_delta"] == 0 and
             receipt["bank_verify_failure_delta"] == 0 and
             receipt["after"]["rejected_command_count"] ==
             receipt["before"]["rejected_command_count"],
             "ACQ_NEW_ERROR_AFTER_DURABLE_RECEIPT")
        return receipt

    def initial(self) -> dict:
        need(self.state["stage"] == "INITIAL", "INITIAL_STAGE_MISMATCH")
        need(self.state["inflight"] is None, "INFLIGHT_OPERATION_REVIEW_REQUIRED")
        rows = []
        for item in self.state["scans"]:
            if item["label"].startswith("initial-"):
                path = self.root / "scans" / f"{item['serial']:02d}-{item['label']}.json"
                rows.append(json.loads(path.read_bytes()))
        while len(rows) < 5:
            rows.append(self.scan(f"initial-{len(rows)+1}"))
            if len(rows) < 5:
                time.sleep(0.100)
        novid = self.window(rows)
        if novid is None:
            extra = []
            for count in range(3):
                extra.append(self.scan(f"stability-{count+1}"))
                if self.window(rows + extra) is not None:
                    break
            rows += extra
            novid = self.window(rows)
        self.state["initial_novid"] = novid
        self.state["format_decision_c3"] = self.format_decision.decide(
            [row["snapshot"] for row in rows[-3:]])
        self.state["stage"] = ("SIGNAL_UNSTABLE" if novid is None else
                               "PENDING_FORMAT_OUTPUT" if novid == 0 else
                               "NOVID1_PENDING_ACQ_AUTHORITY")
        self.persist()
        return {"stage": self.state["stage"], "novid": novid,
                "scans_completed": self.state["scans_completed"],
                "format_decision_c3": self.state["format_decision_c3"]}

    def acq_search(self, gate: dict) -> dict:
        try:
            return self._acq_search_impl(gate)
        except Exception as error:
            if self.state["stage"] == "ACQ_IN_PROGRESS":
                self.state["stage"] = "ACQ_INTERRUPTED"
                self.state["interrupted_reason"] = str(error)
                self.persist()
            raise

    def _acq_search_impl(self, gate: dict) -> dict:
        need(self.state["stage"] == "NOVID1_PENDING_ACQ_AUTHORITY" and
             self.state["inflight"] is None, "ACQ_SEARCH_STAGE_MISMATCH")
        need(all(gate.get(key) is True for key in
                 ("scope_authorized", "physical_camera_confirmed",
                  "connected_response_or_mapping_confirmed",
                  "compiled_ahd1080p25_no_video_context_confirmed")) and
             isinstance(gate.get("basis_files"), list) and gate["basis_files"],
             "ACQ_WRITE_AUTHORITY_NOT_ESTABLISHED")
        self.identity()
        idle = self.idle()
        acq = idle["acq"]
        need(acq["command_sequence"] == 0 and acq["completed_sequence"] == 0 and
             acq["functional_write_count"] == 0 and
             acq["unauthorized_write_count"] == 0 and
             acq["nack_count"] == 0 and acq["timeout_count"] == 0 and
             acq["bank_verify_failure_count"] == 0 and
             not acq["campaign_closed"] and not acq["baseline_valid"] and
             acq["baseline_pass_count"] == 0,
             "ACQ_NOT_FRESH_FOR_SINGLE_CAMPAIGN")
        self.state["acq_gate_sha256"] = sha(canonical(gate))
        self.state["acq_error_baseline"] = {
            name: acq[name] for name in
            ("nack_count", "timeout_count", "bank_verify_failure_count")}
        self.state["stage"] = "ACQ_IN_PROGRESS"
        self.persist()
        baselines = []
        for n in range(3):
            receipt = self.action(self.Command.ACQ_PREPARE_BASELINE)
            after = receipt["after"]
            baselines.append(after["baseline"])
            need(after["baseline"] == after["observed"] and
                 after["baseline_pass_count"] == n + 1 and
                 not after["baseline_mismatch"], "ACQ_BASELINE_MISMATCH")
        need(baselines[0] == baselines[1] == baselines[2] and
             self.executor.snapshot()["baseline_valid"],
             "ACQ_THREE_PREPARES_NOT_IDENTICAL")
        self.state["baseline"] = baselines[0]
        self.persist()
        dry = self.action(self.Command.ACQ_DRYRUN_REWRITE_BASELINE)
        need(dry["after"]["dryrun_pass"] and
             dry["after"]["observed"] == self.state["baseline"],
             "ACQ_DRYRUN_READBACK_MISMATCH")
        dryrows = [self.scan(f"dryrun-{n}") for n in range(1, 4)]
        dry_signal = self.window(dryrows)
        if dry_signal == 0:
            self.state["signal_after_dryrun"] = 0
            self.state["stage"] = "PENDING_FORMAT_OUTPUT"
            self.state["format_decision_c3"] = self.format_decision.decide(
                [row["snapshot"] for row in dryrows])
            self.persist()
            return {"stage": self.state["stage"],
                    "signal_after_dryrun": 0,
                    "format_decision_c3": self.state["format_decision_c3"]}
        if dry_signal is None:
            self.state["stage"] = "SIGNAL_UNSTABLE_AFTER_WRITE"
            self.persist()
            result = self.rollback()
            return {"scientific_stage": "SIGNAL_UNSTABLE_AFTER_WRITE",
                    "stage": self.state["stage"], "rollback": result}
        for level, command in ((0x50, self.Command.ACQ_APPLY_SLICE_50),
                               (0x40, self.Command.ACQ_APPLY_SLICE_40),
                               (0x60, self.Command.ACQ_APPLY_SLICE_60)):
            receipt = self.action(command)
            need(receipt["after"]["slice_stage"] ==
                 {0x50: 1, 0x40: 2, 0x60: 3}[level],
                 "ACQ_SLICE_STAGE_MISMATCH")
            rows = [self.scan(f"slice-{level:02X}-{n}") for n in range(1, 4)]
            signal = self.window(rows)
            if signal == 0:
                self.state["signal_recovered_at_level"] = f"0x{level:02X}"
                self.state["format_decision_c3"] = self.format_decision.decide(
                    [row["snapshot"] for row in rows])
                self.state["stage"] = "PENDING_FORMAT_OUTPUT"
                self.persist()
                return {"stage": self.state["stage"],
                        "signal_recovered_at_level": f"0x{level:02X}",
                        "format_decision_c3": self.state["format_decision_c3"],
                        "scans_completed": self.state["scans_completed"]}
            if signal is None:
                self.state["stage"] = "SIGNAL_UNSTABLE_AFTER_WRITE"
                self.persist()
                result = self.rollback()
                return {"scientific_stage": "SIGNAL_UNSTABLE_AFTER_WRITE",
                        "stage": self.state["stage"], "rollback": result}
        self.state["stage"] = "NO_VIDEO_AFTER_AVAILABLE_CH1_ACTIONS"
        self.persist()
        result = self.rollback()
        return {"scientific_stage": "NO_VIDEO_AFTER_AVAILABLE_CH1_ACTIONS",
                "stage": self.state["stage"], "rollback": result,
                "scans_completed": self.state["scans_completed"]}

    def rollback(self) -> dict:
        need(self.state["write_occurred"] and self.state["inflight"] is None,
             "ROLLBACK_NOT_SAFE_OR_NOT_NEEDED")
        before = self.executor.snapshot()
        baseline = self.state.get("acq_error_baseline")
        need(baseline is not None, "ROLLBACK_MISSING_PREWRITE_ERROR_BASELINE")
        if before["campaign_closed"]:
            need(before["rollback_pass"] and before["restored"] == self.state["baseline"],
                 "CAMPAIGN_CLOSED_WITHOUT_EXACT_ROLLBACK")
            receipt = {"automatic": True, "after": before}
        else:
            need(all(before[name] == baseline[name] for name in baseline),
                 "ROLLBACK_BLOCKED_BY_NEW_I2C_ERROR_NO_BLIND_COMMAND")
            need(not self.state["rollback_command_attempted"] and
                 before["idle"] and not before["busy"] and not before["hard_fail"] and
                 not before["bank_context_lockout"] and before["i2c_bus_idle"],
                 "ROLLBACK_NOT_EXECUTABLE_NO_SECOND_COMMAND")
            self.state["rollback_command_attempted"] = True
            self.persist()
            receipt = self.action(self.Command.ACQ_ROLLBACK)
            after = receipt["after"]
            need(after["rollback_pass"] and after["campaign_closed"] and
                 after["restored"] == self.state["baseline"],
                 "ROLLBACK_EXACT_READBACK_FAILED")
        self.state["rollback"] = receipt
        self.state["stage"] = "BASELINE_RESTORED"
        self.persist()
        rows = []
        if all(self.executor.snapshot()[name] == baseline[name] for name in baseline):
            for n in range(1, 4):
                if self.state["scans_started"] >= MAX_SCANS:
                    break
                rows.append(self.scan(f"post-rollback-{n}"))
        self.state["post_rollback_novid"] = self.window(rows)
        self.persist()
        return {"rollback": "PASS", "post_rollback_novid":
                self.state["post_rollback_novid"], "post_rollback_scans": len(rows)}

    def finish(self, gate: dict) -> dict:
        need(self.state["inflight"] is None, "INFLIGHT_OPERATION_REVIEW_REQUIRED")
        need(self.state["stage"] in
             ("PENDING_FORMAT_OUTPUT", "NO_VIDEO_AFTER_AVAILABLE_CH1_ACTIONS",
              "SIGNAL_UNSTABLE_AFTER_WRITE", "SIGNAL_UNSTABLE",
              "NOVID1_PENDING_ACQ_AUTHORITY", "BASELINE_RESTORED",
              "ACQ_INTERRUPTED"),
             "FINISH_STAGE_MISMATCH")
        full = gate.get("full_camera_ready") is True
        if full:
            need(self.state["stage"] == "PENDING_FORMAT_OUTPUT" and
                 (self.state["initial_novid"] == 0 or
                  self.state.get("signal_after_dryrun") == 0 or
                  self.state["signal_recovered_at_level"] is not None),
                 "RETENTION_WITHOUT_SIGNAL")
            need(gate.get("analog_standard") == "AHD" and
                 gate.get("width") == 1920 and gate.get("height") == 1080 and
                 gate.get("scan_mode") == "PROGRESSIVE" and gate.get("fps") == 25 and
                 gate.get("output_configuration") == "CONFIRMED" and
                 gate.get("live_source_selection") == "CONFIRMED" and
                 isinstance(gate.get("basis_files"), list) and gate["basis_files"],
                 "FULL_READY_BASIS_INCOMPLETE")
        if not full and self.state["write_occurred"] and self.state["stage"] != "BASELINE_RESTORED":
            self.rollback()
        final = self.idle()
        settings = ("BASELINE_RESTORED" if self.state["stage"] == "BASELINE_RESTORED" else
                    "SETTINGS_RETAINED_FOR_NEXT_STAGE" if self.state["write_occurred"] else
                    "BASELINE_UNCHANGED")
        handoff = {"task": TASK, "boot_id": self.state["boot_id"],
                   "source_commit": SOURCE, "bdf": self.state["bdf"],
                   "physical_confirmation": self.state["physical_confirmation"],
                   "utc_ns": time.time_ns(), "full_camera_ready": full,
                   "settings": settings,
                   "baseline": self.state["baseline"],
                   "current_acq": final["acq"],
                   "actions": self.state["actions"],
                   "rollback_condition": "Next owner must read this handoff and current ACQ; rollback only if idle, bus idle, not closed or hard-fail, and retained settings are no longer needed.",
                   "readiness_gate": gate,
                   "C2H_OPEN": 0, "FRAME_ACQUIRED": "NO",
                   "DMA_PROVEN_BY_THIS_TASK": "NO"}
        write_once(self.root / "CAMERA_HANDOFF.json", canonical(handoff))
        self.state["stage"] = "RETAINED" if full and self.state["write_occurred"] else "FINISHED"
        self.persist()
        return handoff


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--device", required=True)
    parser.add_argument("--bdf", required=True)
    parser.add_argument("--boot-id", required=True)
    parser.add_argument("--physical-confirmation", required=True)
    parser.add_argument("--phase", choices=("initial", "acq-search", "finish"), required=True)
    parser.add_argument("--gate-file", type=Path)
    args = parser.parse_args(argv)
    need(PHYSICAL.fullmatch(args.physical_confirmation) is not None,
         "PHYSICAL_CAMERA_CONFIRMATION_REQUIRED")
    need(args.bundle_root.is_dir() and args.output_root.is_dir() and
         not args.bundle_root.is_symlink() and not args.output_root.is_symlink(),
         "TASK_DIRECTORY_MISSING_OR_SYMLINK")
    sys.path.insert(0, str(args.bundle_root.resolve()))
    api = modules()
    bundle_resolved = args.bundle_root.resolve()
    for name, module in tuple(sys.modules.items()):
        if name.split(".", 1)[0] in ("scan1", "cont1r3", "w3a", "acq1_compat0_r2"):
            location = getattr(module, "__file__", None)
            need(location is not None and
                 Path(location).resolve().is_relative_to(bundle_resolved),
                 "IMPORT_OUTSIDE_PINNED_BUNDLE:" + name)
    VerifiedMmioDevice = api[-1]
    state_path = args.output_root / "state.json"
    boot_now = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
    need(boot_now == args.boot_id, "BOOT_ID_CHANGED")
    with VerifiedMmioDevice(node=args.device, bdf=args.bdf) as device:
        if state_path.exists():
            state = load_state(state_path)
            need(state["boot_id"] == boot_now and state["bdf"] == args.bdf and
                 state["user_node"] == args.device and
                 state["physical_confirmation"] == args.physical_confirmation,
                 "SESSION_CHANGED_NO_RESUME")
        else:
            need(args.phase == "initial", "NO_INITIAL_STATE")
            state = {"task": TASK, "source_commit": SOURCE,
                     "boot_id": boot_now, "bdf": args.bdf,
                     "user_node": args.device,
                     "physical_confirmation": args.physical_confirmation,
                     "created_utc_ns": time.time_ns(), "scans_started": 0,
                     "scans_completed": 0, "scans": [], "actions": [],
                     "write_occurred": False, "baseline": None,
                     "initial_novid": None, "signal_recovered_at_level": None,
                     "rollback_command_attempted": False, "inflight": None,
                     "stage": "INITIAL"}
            save_state(state_path, state)
        run = Run(device, args.output_root, state, api)
        run.identity()
        run.idle()
        if args.phase == "initial":
            result = run.initial()
        elif args.phase == "acq-search":
            need(args.gate_file is not None, "ACQ_GATE_FILE_REQUIRED")
            gate = load_gate(args.gate_file, kind="ACQ_WRITE_GATE", state=state)
            result = run.acq_search(gate)
        else:
            need(args.gate_file is not None, "READINESS_GATE_FILE_REQUIRED")
            gate = load_gate(args.gate_file, kind="READINESS_GATE", state=state)
            result = run.finish(gate)
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
