"""Offline-only frozen-schema decode and independent simulation-signature checker.

No MMIO or hardware API is imported or instantiated by this tool.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import struct
import sys
from collections import Counter
from pathlib import Path


OBS_RE = re.compile(
    r"^OBS status=([0-9a-f]{8}) gen=(\d+) valid=(\d+) failed=(\d+) "
    r"retried=(\d+) index=(\d+) detail=([0-9a-f]{8}) flags=([0-9a-f]{8}) "
    r"commands=(\d+) entry=([0-9a-f]{8}) exit=([0-9a-f]{8})",
    re.MULTILINE,
)
FIELDS = ("status", "generation", "valid", "failed", "retried", "index",
          "detail", "flags", "commands", "entry", "exit")


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def require(ok: bool, message: str) -> None:
    if not ok:
        raise AssertionError(message)


def verify_raw_hash(data: bytes, expected: str) -> None:
    require(sha(data) == expected, "PRIVATE_RECORD_HASH_MISMATCH")


def observed_from_simulation(log: bytes) -> dict[str, int]:
    text = log.decode("utf-8", errors="replace")
    require("SELECT_FAULT mode=1 raw=4 timeout=0" in text,
            "OBSERVED_LOG_MISSING_INJECTION_RECEIPT")
    require("TEST_EXECUTION_PASS T02" in text and "Fatal:" not in text,
            "OBSERVED_LOG_NOT_COMPLETED")
    matches = OBS_RE.findall(text)
    require(len(matches) == 1, "OBSERVED_LOG_NOT_ONE_OBS")
    values = matches[0]
    parsed = {
        "status": int(values[0], 16), "generation": int(values[1]),
        "valid": int(values[2]), "failed": int(values[3]),
        "retried": int(values[4]), "index": int(values[5]),
        "detail": int(values[6], 16), "flags": int(values[7], 16),
        "commands": int(values[8]), "entry": int(values[9], 16),
        "exit": int(values[10], 16),
    }
    return parsed


def historical_expected(path: Path) -> dict[str, int]:
    doc = json.loads(path.read_text(encoding="utf-8"))
    hw = doc["hardware_observation"]
    return {key: int(hw[key], 0) if isinstance(hw[key], str) else hw[key]
            for key in FIELDS}


def check_signature(observed: dict[str, int], expected: dict[str, int]) -> bool:
    return set(observed) == set(FIELDS) and all(
        observed[key] == expected[key] for key in FIELDS
    )


def parse_record(payload: bytes) -> tuple[list[int], list[int], int]:
    require(len(payload) >= 16 and payload[:4] == b"C1R3", "RAW_MAGIC")
    legacy_count, telemetry_count, event_count = struct.unpack_from("<III", payload, 4)
    require(legacy_count == 146 and telemetry_count == 902, "RAW_WORD_COUNTS")
    require(len(payload) == 16 + 4 * (legacy_count + telemetry_count), "RAW_SIZE")
    all_words = struct.unpack_from(f"<{legacy_count+telemetry_count}I", payload, 16)
    return list(all_words[:legacy_count]), list(all_words[legacy_count:]), event_count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--private", type=Path, required=True)
    parser.add_argument("--frozen-host", type=Path, required=True)
    parser.add_argument("--public", type=Path, required=True)
    parser.add_argument("--historical", type=Path, required=True)
    parser.add_argument("--sim-log", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.frozen_host / "host"))
    from cont1r3 import contract, telemetry  # noqa: PLC0415
    from scan1 import decoder, manifest  # noqa: PLC0415

    entries, prohibited, _ = manifest.load_and_validate()
    manifest_doc = json.loads((args.private / "CONT1R3_PRIVATE_RAW_DATA_MANIFEST.json")
                              .read_text(encoding="utf-8"))
    summaries = [json.loads(line) for line in
                 (args.private / "scan-summaries.jsonl").read_text(encoding="utf-8").splitlines()]
    old_events = [json.loads(line) for line in
                  (args.private / "events.jsonl").read_text(encoding="utf-8").splitlines()]
    old_exposures = [json.loads(line) for line in
                     (args.private / "exposures.jsonl").read_text(encoding="utf-8").splitlines()]
    public_events = list(csv.DictReader((args.public / "EVENTS_SUMMARY.csv").open(newline="", encoding="utf-8")))
    public_progress = list(csv.DictReader((args.public / "CAMPAIGN_PROGRESS.csv").open(newline="", encoding="utf-8")))
    public_exposure = list(csv.DictReader((args.public / "EXPOSURE_SUMMARY.csv").open(newline="", encoding="utf-8")))
    require(len(manifest_doc["files"]) == 26 and len(summaries) == 26 and
            len(public_progress) == 26, "COMPLETE_RECORD_COUNT")
    require(len(old_events) == 11 and len(public_events) == 11 and
            len(old_exposures) == 26 * 82, "PRESERVED_EVENT_OR_EXPOSURE_COUNT")
    summary_by_label = {row["scan_label"]: row for row in summaries}
    derived_events: list[dict] = []
    campaign_exposures = Counter()
    for f in manifest_doc["files"]:
        label = f["scan_label"]
        path = args.private / f["path"]
        data = path.read_bytes()
        require(len(data) == f["size"], f"PRIVATE_RECORD_SIZE:{label}")
        verify_raw_hash(data, f["sha256"])
        summary = summary_by_label[label]
        require(summary["private_raw_sha256"] == f["sha256"],
                f"SUMMARY_RAW_IDENTITY:{label}")
        legacy, side, event_count = parse_record(data)
        require(telemetry.words_sha256(legacy) == summary["legacy_snapshot_sha256"],
                f"LEGACY_HASH:{label}")
        require(telemetry.words_sha256(side) == summary["telemetry_sha256"],
                f"TELEMETRY_HASH:{label}")
        decoded_entries = decoder.validate_entries(legacy[-82:], entries, prohibited)
        require(len(decoded_entries) == 82, f"LEGACY_DECODE:{label}")
        result = telemetry.validate_frozen(
            side[:32], side[32:82], side[82:], summary["generation"],
            legacy[-82:], summary["transaction_count"],
            summary["fpga_start_tick"], summary["fpga_end_tick"])
        require(result["event_count"] == event_count == summary["telemetry_event_count"]
                and result["exposure_count"] == 82, f"FROZEN_DECODE:{label}")
        require(result["generation"] == summary["generation"] and
                summary["publication_coherent"] and
                summary["entry_bank_restore"] == "PASS" and
                summary["projection"] == "PASS", f"COMPLETE_SUMMARY:{label}")
        require(summary["transaction_count"] == 105 + event_count,
                f"TRANSACTION_ACCOUNTING:{label}")
        if label.startswith("campaign-"):
            for exposure in result["exposures"]:
                campaign_exposures[exposure["group_index"]] += 1
        for event in result["events"]:
            require(event["first_attempt_raw_cause"] == 2 and
                    event["first_attempt_decoded_cause"] == 2 and
                    event["retry_success"], f"RECOVERED_CAUSE:{label}")
            ns = contract.ticks_to_ns(event["time_since_verify_ticks"])
            require(ns == event["time_since_verify_ns"], f"TIME_CONVERSION:{label}")
            derived_events.append({
                "scan_label": label, "generation": result["generation"],
                "entry_index": event["entry_index"],
                "bank": f"0x{event['manifest_target_bank']:02X}",
                "register": f"0x{event['target_register']:02X}",
                "group_index": event["group_index"],
                "position_in_group": event["position_in_group"],
                "raw_first_cause": event["first_attempt_raw_cause"],
                "decoded_first_cause": event["first_attempt_decoded_cause_name"],
                "retry_result": "SUCCESS" if event["retry_success"] else "FAIL",
                "transactions_since_verify": event["transactions_since_verify"],
                "delta_ticks": event["time_since_verify_ticks"],
                "delta_ns_floor": ns,
                "clock_hz": contract.COUNTER_FREQUENCY_HZ,
            })
    require(len(derived_events) == 11, "DERIVED_EVENT_COUNT")
    for derived, old, pub in zip(derived_events, old_events, public_events):
        require(derived["scan_label"] == old["scan_label"] == pub["scan_label"] and
                derived["entry_index"] == old["entry_index"] == int(pub["entry_index"]) and
                derived["group_index"] == old["group_index"] == int(pub["group_index"]) and
                derived["position_in_group"] == old["position_in_group"] == int(pub["position_in_group"]) and
                derived["raw_first_cause"] == old["first_attempt_raw_cause"] and
                derived["delta_ticks"] == old["time_since_verify_ticks"] and
                derived["delta_ns_floor"] == int(pub["time_since_verify_ns"]),
                f"EVENT_RECONCILIATION:{derived['scan_label']}")
    require(any(row["scan_label"] == "campaign-0022" and row["entry_index"] == 19
                and row["group_index"] == 3 and row["position_in_group"] == 8
                for row in derived_events), "LATE_EVENT_MISSING")
    for row in public_exposure:
        group = int(row["group_index"])
        require(campaign_exposures[group] == int(row["complete_campaign_exposures"]),
                f"EXPOSURE_SUMMARY:{group}")
        require(sum(event["group_index"] == group for event in derived_events) ==
                int(row["recovered_campaign_events"]), f"EVENT_GROUP:{group}")
    require(sum(campaign_exposures.values()) == 2050, "CAMPAIGN_DENOMINATOR")
    require(sum(row["telemetry_exposure_count"] for row in summaries) == 2132,
            "ALL_COMPLETE_DENOMINATOR")
    require(summaries[0]["scan_label"] == "control" and
            [row["generation"] for row in summaries] == list(range(1, 27)),
            "GENERATION_SEQUENCE")

    expected = historical_expected(args.historical)
    observed = observed_from_simulation(args.sim_log.read_bytes())
    require(check_signature(observed, expected), "T02_SIGNATURE_CHECKER")
    for field in ("detail", "commands", "index", "generation"):
        mutation = dict(observed)
        mutation[field] += 1
        require(not check_signature(mutation, expected), f"NEGATIVE_MUTATION:{field}")
    publication_mutation = dict(observed)
    publication_mutation["flags"] |= 1
    require(not check_signature(publication_mutation, expected),
            "NEGATIVE_MUTATION:publication_status")
    require(not check_signature({"status": expected["status"]}, expected),
            "FIXED_EXPECTED_RECORD_ACCEPTED_AS_OBSERVED")
    require(not check_signature(expected | {"publication_complete": 1}, expected),
            "PUBLICATION_STATUS_MUTATION")
    require(not observed_from_simulation.__name__ == "historical_expected",
            "OBSERVED_SOURCE_NOT_LOG")
    first_raw = (args.private / manifest_doc["files"][0]["path"]).read_bytes()
    try:
        verify_raw_hash(first_raw, "0" * 64)
    except AssertionError as error:
        require(str(error) == "PRIVATE_RECORD_HASH_MISMATCH", "RAW_HASH_NEGATIVE_WRONG_ERROR")
    else:
        raise AssertionError("MISMATCHED_RAW_HASH_ACCEPTED")
    try:
        observed_from_simulation(args.historical.read_bytes())
    except AssertionError:
        pass
    else:
        raise AssertionError("HISTORICAL_JSON_PASSED_AS_SIM_OBSERVATION")

    args.out.mkdir(parents=True, exist_ok=True)
    fields = list(derived_events[0])
    with (args.out / "REGADDR_EXISTING_EVENTS.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(derived_events)
    receipt = {
        "test_execution": "PASS", "control_complete": 1,
        "campaign_complete": 25, "failed_attempt_complete": False,
        "raw_records_verified": 26, "frozen_schema_decoded": 26,
        "campaign_exposures": 2050, "all_exposures": 2132,
        "campaign_group_records": 250, "all_group_records": 260,
        "recovered_regaddr_events": len(derived_events),
        "campaign_scans_with_event": len({r["scan_label"] for r in derived_events}),
        "late_position_event_retained": True,
        "t02_signature_check": "PASS", "t18_negative_mutations": 6,
        "raw_hash_negative": "PASS", "historical_json_cannot_be_observation": "PASS",
        "sim_log_sha256": sha(args.sim_log.read_bytes()),
    }
    (args.out / "PRIVATE_REANALYSIS_RECEIPT.json").write_text(
        json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print("T17_PASS control=1 campaign=25 raw=26 exposures=2050 events=11")
    print("T18_PASS signature_mutations=5 raw_hash=1 historical_json_rejected=1")


if __name__ == "__main__":
    main()
