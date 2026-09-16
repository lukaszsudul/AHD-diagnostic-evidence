"""Single-run read-only control plus exactly 1,000 CONT1R3 scans.

The only MMIO writes in this module are the frozen SCAN1 ONESHOT and ACK
control words.  There is no ACQ, generic-I2C, mode, EQ, slice, or capture
interface.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import struct
import time
import uuid
from pathlib import Path
from typing import Mapping

from scan1 import manifest, mmio

from . import contract, projection, telemetry


CAMPAIGN_SCAN_COUNT = 1000
CHECKPOINT_INTERVAL = 100


class CharacterizationError(RuntimeError):
    pass


def _require(condition: bool, reason: str) -> None:
    if not condition:
        raise CharacterizationError(reason)


def _canonical(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


class LiveScanner:
    def __init__(self, device: mmio.MmioDevice):
        self.device = device
        self.entries, self.prohibited, _ = manifest.load_and_validate()

    def identity(self) -> dict:
        digest = "".join(
            f"{self.device.read32(mmio.DIGEST_BASE + 4 * index):08X}"
            for index in range(8)
        )
        result = {
            "magic": self.device.read32(mmio.MAGIC),
            "version": self.device.read32(mmio.VERSION),
            "capabilities": self.device.read32(mmio.CAPABILITIES),
            "entry_count": self.device.read32(mmio.ENTRY_COUNT),
            "manifest_sha256": digest,
        }
        expected = {
            "magic": 0x4E565343, "version": 0x00010001,
            "capabilities": 0x0000000F, "entry_count": 82,
            "manifest_sha256": contract.EXPECTED_MANIFEST_SHA256,
        }
        _require(result == expected, f"SCAN1_RUNTIME_IDENTITY_MISMATCH:{result!r}")
        result["telemetry"] = telemetry.read_identity(self.device)
        return result

    def start(self) -> None:
        status = self.device.read32(mmio.STATUS)
        _require(status & mmio.STATUS_IDLE != 0 and
                 status & (mmio.STATUS_BUSY | mmio.STATUS_DONE |
                           mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT) == 0,
                 f"SCANNER_NOT_CLEAN_IDLE:{status:#010x}")
        self.device.write32(mmio.CONTROL, mmio.CONTROL_ONESHOT)
        deadline = time.monotonic() + 3.0
        while time.monotonic() < deadline:
            status = self.device.read32(mmio.STATUS)
            if status & mmio.STATUS_DONE:
                return
            if status & (mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT):
                raise CharacterizationError(f"SCANNER_HARD_STOP:{status:#010x}")
            time.sleep(0.002)
        raise CharacterizationError("SCANNER_ONESHOT_TIMEOUT")

    def read_legacy_frozen(self) -> dict:
        header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
        for attempt in range(1, 4):
            generation0 = self.device.read32(mmio.GENERATION)
            header_words = [self.device.read32(address) for address in header_addresses]
            group_words = [self.device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
            entry_words = [self.device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(82)]
            generation1 = self.device.read32(mmio.GENERATION)
            values = dict(zip(header_addresses, header_words))
            if generation0 != generation1 or not values[mmio.STATUS] & mmio.STATUS_DONE:
                continue
            digest = "".join(f"{values[mmio.DIGEST_BASE + 4 * index]:08X}"
                             for index in range(8))
            _require(digest == contract.EXPECTED_MANIFEST_SHA256,
                     "FROZEN_MANIFEST_IDENTITY_MISMATCH")
            decoded = []
            retried = 0
            for expected, word in zip(self.entries, entry_words):
                item = {
                    "index": expected.index, "bank": (word >> 24) & 0xFF,
                    "register": (word >> 16) & 0xFF,
                    "value": (word >> 8) & 0xFF, "status": word & 0xFF,
                    "authority": expected.authority,
                }
                _require((item["bank"], item["register"]) ==
                         (expected.bank, expected.register),
                         f"ENTRY_IDENTITY_MISMATCH:{expected.index}")
                _require(item["status"] & 0x05 == 0x05 and
                         item["status"] & 0xF8 == 0,
                         f"ENTRY_STATUS_INVALID:{expected.index}:{item['status']:02X}")
                retried += bool(item["status"] & 0x02)
                decoded.append(item)
            scan_flags = int(values[mmio.SCAN_FLAGS])
            transaction_count = scan_flags >> 16
            _require(values[mmio.ENTRY_COUNT] == 82 and
                     values[mmio.VALID_ENTRY_COUNT] == 82 and
                     values[mmio.FAILED_ENTRY_COUNT] == 0 and
                     values[mmio.RETRIED_ENTRY_COUNT] == retried,
                     "LEGACY_ENTRY_COUNTER_RECONCILIATION")
            _require(scan_flags & 0x05 == 0x05 and
                     transaction_count == contract.CLEAN_TRANSACTION_COUNT + retried,
                     "LEGACY_TRANSACTION_OR_RESTORE_RECONCILIATION")
            entry_bank = int(values[mmio.ENTRY_BANK])
            exit_bank = int(values[mmio.EXIT_BANK])
            _require(entry_bank & 0x100 and exit_bank & 0x100 and
                     (entry_bank & 0xFF) == (exit_bank & 0xFF),
                     "ENTRY_BANK_RESTORE_GATE_FAILED")
            a8 = int(values[mmio.A8_PRE_POST])
            snapshot = {
                "generation": generation0, "consistency_attempt": attempt,
                "manifest_sha256": digest, "entry_count": 82,
                "valid_entry_count": 82, "failed_entry_count": 0,
                "retried_entry_count": retried, "bank_group_count": 10,
                "transaction_count": transaction_count,
                "entry_bank": entry_bank & 0xFF, "exit_bank": exit_bank & 0xFF,
                "entry_bank_restore": "PASS", "a8_pre": a8 & 0xFF,
                "a8_post": (a8 >> 8) & 0xFF,
                "start_ticks": int(values[mmio.START_TICKS_LO]) |
                               (int(values[mmio.START_TICKS_HI]) << 32),
                "end_ticks": int(values[mmio.END_TICKS_LO]) |
                             (int(values[mmio.END_TICKS_HI]) << 32),
                "raw_register_set": decoded,
                "projection": projection.configuration_projection(
                    {"raw_register_set": decoded}),
                "_raw_words": header_words + group_words + entry_words,
            }
            return snapshot
        raise CharacterizationError("SNAPSHOT_MUTATION_OR_PARTIAL_PUBLICATION")

    def acknowledge(self) -> None:
        self.device.write32(mmio.CONTROL, mmio.CONTROL_ACK_CLEAR)
        deadline = time.monotonic() + 1.0
        while time.monotonic() < deadline:
            status = self.device.read32(mmio.STATUS)
            if status & mmio.STATUS_IDLE and not status & (
                    mmio.STATUS_BUSY | mmio.STATUS_DONE | mmio.STATUS_ERROR |
                    mmio.STATUS_BANK_LOCKOUT):
                return
            time.sleep(0.001)
        raise CharacterizationError("SCANNER_ACK_DID_NOT_RETURN_CLEAN_IDLE")


class DurableRecorder:
    def __init__(self, root: Path, identity: Mapping):
        if root.exists():
            raise CharacterizationError("CONT1R3_CAMPAIGN_ROOT_PREEXISTS_NO_RESUME")
        root.mkdir(parents=True, mode=0o700)
        self.root = root
        self.private = root / "private"
        self.private.mkdir(mode=0o700)
        self.summary_stream = (root / "scan-summaries.jsonl").open(
            "x", encoding="utf-8", newline="\n")
        self.event_stream = (root / "events.jsonl").open(
            "x", encoding="utf-8", newline="\n")
        self.exposure_stream = (root / "exposures.jsonl").open(
            "x", encoding="utf-8", newline="\n")
        self.session_id = str(uuid.uuid4())
        self.rows: list[dict] = []
        self.events: list[dict] = []
        self.manifest_rows: list[dict] = []
        self.rolling = hashlib.sha256()
        session = {
            "schema": "AHD_V41_CONT1R3_CHARACTERIZATION_SESSION_V1",
            "session_id": self.session_id,
            "runtime_identity": dict(identity),
            "control_scan_count": 1,
            "campaign_scan_target": CAMPAIGN_SCAN_COUNT,
            "resume_permitted": False,
            "created_utc_ns": time.time_ns(),
        }
        self._write_atomic(root / "session.json", _canonical(session).encode() + b"\n")

    @staticmethod
    def _write_atomic(path: Path, data: bytes) -> None:
        temporary = path.with_suffix(path.suffix + ".tmp")
        with temporary.open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)

    @staticmethod
    def _flush(stream) -> None:
        stream.flush()
        os.fsync(stream.fileno())

    def persist_before_ack(self, label: str, summary: dict,
                           legacy_words: list[int], telemetry_words: list[int],
                           events: list[dict], exposures: list[dict]) -> None:
        legacy_bytes = struct.pack(f"<{len(legacy_words)}I", *legacy_words)
        telemetry_bytes = struct.pack(f"<{len(telemetry_words)}I", *telemetry_words)
        payload = (b"C1R3" + struct.pack("<III", len(legacy_words),
                                         len(telemetry_words), len(events)) +
                   legacy_bytes + telemetry_bytes)
        filename = f"scan-{label}.bin"
        path = self.private / filename
        self._write_atomic(path, payload)
        payload_sha = _sha256(payload)
        self.rolling.update(payload)
        summary.update({
            "private_raw_file": filename, "private_raw_size": len(payload),
            "private_raw_sha256": payload_sha,
            "rolling_raw_sha256": self.rolling.hexdigest().upper(),
        })
        for event in events:
            row = {"scan_label": label, "private_raw_sha256": payload_sha, **event}
            self.event_stream.write(_canonical(row) + "\n")
            self.events.append(row)
        for exposure in exposures:
            row = {"scan_label": label, **exposure}
            self.exposure_stream.write(_canonical(row) + "\n")
        self.summary_stream.write(_canonical(summary) + "\n")
        self._flush(self.event_stream)
        self._flush(self.exposure_stream)
        self._flush(self.summary_stream)
        self.rows.append(dict(summary))
        self.manifest_rows.append({"scan_label": label, "path": f"private/{filename}",
                                   "size": len(payload), "sha256": payload_sha})
        if len(self.rows) % CHECKPOINT_INTERVAL == 0:
            self.checkpoint()

    def checkpoint(self) -> None:
        value = {
            "schema": "AHD_V41_CONT1R3_PROGRESS_V1",
            "session_id": self.session_id,
            "recorded_scans_including_control": len(self.rows),
            "campaign_scans": max(0, len(self.rows) - 1),
            "event_count": len(self.events),
            "rolling_raw_sha256": self.rolling.hexdigest().upper(),
            "resume_permitted": False,
            "recorded_utc_ns": time.time_ns(),
        }
        self._write_atomic(self.root / "progress.json", _canonical(value).encode() + b"\n")

    def close(self) -> None:
        self.checkpoint()
        for stream in (self.summary_stream, self.event_stream, self.exposure_stream):
            self._flush(stream)
            stream.close()
        value = {"schema": "AHD_V41_CONT1R3_PRIVATE_RAW_MANIFEST_V1",
                 "session_id": self.session_id, "files": self.manifest_rows}
        self._write_atomic(self.root / "CONT1R3_PRIVATE_RAW_DATA_MANIFEST.json",
                           json.dumps(value, indent=2, sort_keys=True).encode() + b"\n")


def perform_scan(scanner: LiveScanner, recorder: DurableRecorder,
                 label: str, campaign_index: int | None,
                 previous_ack_ns: int | None) -> tuple[dict, int]:
    host_start_ns = time.monotonic_ns()
    utc_start_ns = time.time_ns()
    scanner.start()
    snapshot = scanner.read_legacy_frozen()
    sideband = telemetry.read_frozen(scanner.device, snapshot)
    host_collected_ns = time.monotonic_ns()
    events = sideband["events"]
    exposures = sideband["exposures"]
    summary = {
        "scan_label": label, "campaign_index": campaign_index,
        "generation": snapshot["generation"], "host_utc_start_ns": utc_start_ns,
        "host_duration_through_collection_ns": host_collected_ns - host_start_ns,
        "host_gap_from_previous_ack_ns": None if previous_ack_ns is None
                                         else host_start_ns - previous_ack_ns,
        "fpga_start_tick": snapshot["start_ticks"],
        "fpga_end_tick": snapshot["end_ticks"],
        "fpga_duration_ticks": (snapshot["end_ticks"] - snapshot["start_ticks"]) &
                               ((1 << 64) - 1),
        "entry_count": snapshot["entry_count"], "group_count": 10,
        "transaction_count": snapshot["transaction_count"],
        "expected_transaction_count": contract.CLEAN_TRANSACTION_COUNT + len(events),
        "valid_entry_count": snapshot["valid_entry_count"],
        "failed_entry_count": snapshot["failed_entry_count"],
        "retried_entry_count": snapshot["retried_entry_count"],
        "host_derived_nack_event_count": len(events),
        "timeout_count": 0, "bank_verify_failure_count": 0,
        "publication_coherent": True, "entry_bank_restore": "PASS",
        "a8_pre": snapshot["a8_pre"], "a8_post": snapshot["a8_post"],
        "projection": "PASS", "telemetry_event_count": sideband["event_count"],
        "telemetry_exposure_count": sideband["exposure_count"],
        "telemetry_overflow": sideband["overflow"],
        "legacy_snapshot_sha256": telemetry.words_sha256(snapshot["_raw_words"]),
        "telemetry_sha256": sideband["raw_sha256"],
    }
    _require(summary["transaction_count"] == summary["expected_transaction_count"] and
             summary["retried_entry_count"] == len(events),
             "CONT1R3_SCAN_TRANSACTION_EVENT_RECONCILIATION")
    recorder.persist_before_ack(
        label, summary, list(snapshot["_raw_words"]),
        list(sideband["_raw_words"]), events, exposures)
    scanner.acknowledge()
    return summary, time.monotonic_ns()


def _write_csv(path: Path, rows: list[dict]) -> None:
    fields = list(rows[0]) if rows else ["scan_label"]
    with path.open("x", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction="ignore",
                                lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def run_live(device_path: str, output_root: Path) -> dict:
    os.umask(0o077)
    with mmio.MmioDevice(device_path) as device:
        scanner = LiveScanner(device)
        identity = scanner.identity()
        recorder = DurableRecorder(output_root, identity)
        previous_ack_ns = None
        try:
            control, previous_ack_ns = perform_scan(
                scanner, recorder, "control", None, previous_ack_ns)
            campaign = []
            for index in range(1, CAMPAIGN_SCAN_COUNT + 1):
                row, previous_ack_ns = perform_scan(
                    scanner, recorder, f"campaign-{index:04d}", index,
                    previous_ack_ns)
                campaign.append(row)
        finally:
            recorder.close()
    _require(len(campaign) == CAMPAIGN_SCAN_COUNT and len(recorder.rows) == 1001,
             "CONT1R3_CAMPAIGN_COUNT_NOT_1000_PLUS_CONTROL")
    _write_csv(output_root / "CONT1R3_CAMPAIGN_PROGRESS.csv", campaign)
    result = {
        "schema": "AHD_V41_CONT1R3_CHARACTERIZATION_RESULT_V1",
        "session_id": recorder.session_id, "control_scan": control,
        "campaign_complete_scans": len(campaign),
        "all_recorded_scans_including_control": len(recorder.rows),
        "total_recovered_events": len(recorder.events),
        "hard_stop_events": 0, "experimental_functional_nvp_writes": 0,
        "generic_host_i2c": "ABSENT", "camera_work": "NOT_AUTHORIZED",
        "checkpoint_resume_used": False,
    }
    DurableRecorder._write_atomic(
        output_root / "CONT1R3_CHARACTERIZATION_RESULT.json",
        json.dumps(result, indent=2, sort_keys=True).encode() + b"\n")
    return result


def self_test() -> None:
    _require(CAMPAIGN_SCAN_COUNT == 1000 and CHECKPOINT_INTERVAL == 100,
             "CONT1R3_CAMPAIGN_CONSTANTS")
    _require(mmio.CONTROL_ONESHOT == 1 and mmio.CONTROL_ACK_CLEAR == 2,
             "CONT1R3_ONLY_LEGACY_CONTROL_WORDS")
    _require(projection.manifest_preflight()["result"] == "PASS",
             "CONT1R3_PROJECTION_PREFLIGHT")
    _require(telemetry.schema_sha256() == contract.EXPECTED_SCHEMA_SHA256,
             "CONT1R3_SCHEMA_IDENTITY")
    print("PASS CONT1R3_CHARACTERIZER_SELF_TEST")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--run", action="store_true")
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--output-root", type=Path)
    args = parser.parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    if args.output_root is None:
        parser.error("--output-root is required with --run")
    print(json.dumps(run_live(args.device, args.output_root), sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
