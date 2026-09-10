#!/usr/bin/env python3
"""Create truthful host-side NVP diagnostic evidence projections.

The DIAG1-R1 firmware exposes a coherent per-session summary, not an event
FIFO.  This tool deliberately preserves that distinction: it emits stable
window summaries, cumulative I2C-count intervals, and logical write/readback
receipts.  It never manufactures per-transaction timestamps, sequence IDs, or
individual raw status-sample rows that the FPGA did not retain.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
from typing import Any


ORDERS = ((1, 2, 3, 4), (4, 3, 2, 1), (2, 3, 4, 1), (3, 4, 1, 2))
COLOR_CODES_BY_ROUND = (
    (0x6, 0x4, 0x3, 0x1),
    (0x1, 0x6, 0x4, 0x3),
    (0x3, 0x1, 0x6, 0x4),
    (0x4, 0x3, 0x1, 0x6),
)
STABILITY_CLASSIFICATIONS = {
    "ACTIVE_STABLE", "NO_VIDEO_STABLE", "STATUS_CONTRADICTORY",
}

STATUS_FIELDS = [
    "SessionID", "Round", "Channel", "Classification",
    "StableSamples", "TotalStatusSamples", "RawNOVID", "RawAGCLock",
    "RawComparatorLock", "RawHLock", "RawChannelStatus",
    "EquivalentConsecutiveSamplesProven", "RetainedRawSignatureCount",
    "IndividualRawSampleHistoryRetained", "IndividualSampleTimestamps",
    "EvidenceGranularity", "EvidenceSource", "Limitation",
]
I2C_FIELDS = [
    "CheckpointOrder", "SessionID", "Round", "Channel", "Checkpoint",
    "HostTimestampNs", "AcceptedTransactionCount", "PriorCount",
    "AcceptedTransactionDelta", "NackCountEvidence",
    "TimeoutCountEvidence", "BusRecoveryCountEvidence", "CountBaseline",
    "EvidenceGranularity", "PerTransactionSequenceIDsRetained",
    "PerTransactionCommandsRetained", "PerTransactionTimestampsRetained",
    "EvidenceSource", "Limitation",
]
WRITE_FIELDS = [
    "Order", "SessionID", "Round", "Channel", "LogicalOperation",
    "Bank", "Register", "Field", "RequestedFieldValue",
    "RequestedFullByte", "ReadbackFullByte", "ReadbackMatch",
    "PhysicalTransactionRecordRetained", "EvidenceGranularity",
    "EvidenceSource", "Limitation",
]
READBACK_FIELDS = [
    "Order", "SessionID", "Round", "Channel", "LogicalReadback",
    "Bank", "Register", "Field", "ReadbackValue",
    "EquivalentConsecutiveReadsProven", "PhysicalTransactionIDsRetained",
    "EvidenceGranularity", "EvidenceSource", "Limitation",
]


class EvidenceError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def parse_int(value: Any) -> int:
    if isinstance(value, int):
        return value
    text = str(value).strip()
    return int(text, 0)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv_atomic(path: Path, fields: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows({field: row.get(field, "") for field in fields}
                         for row in rows)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def write_json_atomic(path: Path, value: Any) -> None:
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def session_timestamps(path: Path | None) -> dict[int, int]:
    if path is None or not path.is_file():
        return {}
    rows = read_csv(path)
    timestamps: dict[int, int] = {}
    for row in rows:
        if (row.get("Phase") == "PRE_CAPTURE" and
                row.get("Result") == "PASS"):
            session = parse_int(row["ExpectedSession"])
            timestamps.setdefault(session, parse_int(row["TimestampNs"]))
    return timestamps


def validate_sessions(rows: list[dict[str, str]], expected: int,
                      allow_partial: bool) -> list[dict[str, str]]:
    ordered = sorted(rows, key=lambda row: parse_int(row["SessionID"]))
    ids = [parse_int(row["SessionID"]) for row in ordered]
    require(len(ids) == len(set(ids)), "DUPLICATE_SESSION_STATUS_ROWS")
    if allow_partial:
        require(ids == list(range(1, len(ids) + 1)),
                "PARTIAL_SESSION_SEQUENCE_NOT_CONTIGUOUS")
    else:
        require(ids == list(range(1, expected + 1)),
                "SESSION_STATUS_HISTORY_NOT_COMPLETE")
    for row in ordered:
        session = parse_int(row["SessionID"])
        round_number = parse_int(row["Round"])
        channel = parse_int(row["Channel"])
        require(1 <= round_number <= 4 and 1 <= channel <= 4,
                "SESSION_ROUND_CHANNEL_OUT_OF_RANGE")
        require(channel == ORDERS[round_number - 1][(session - 1) % 4],
                "SESSION_ORDER_MISMATCH")
    return ordered


def status_summaries(rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output: list[dict[str, Any]] = []
    for row in rows:
        classification = row["Classification"]
        stable = parse_int(row["StableSamples"])
        equivalent = stable if classification in STABILITY_CLASSIFICATIONS else 0
        output.append({
            "SessionID": row["SessionID"], "Round": row["Round"],
            "Channel": row["Channel"], "Classification": classification,
            "StableSamples": stable,
            "TotalStatusSamples": parse_int(row["TotalStatusSamples"]),
            "RawNOVID": row["RawNOVID"], "RawAGCLock": row["RawAGCLock"],
            "RawComparatorLock": row["RawComparatorLock"],
            "RawHLock": row["RawHLock"],
            "RawChannelStatus": row["RawChannelStatus"],
            "EquivalentConsecutiveSamplesProven": equivalent,
            "RetainedRawSignatureCount": 1,
            "IndividualRawSampleHistoryRetained": "NO",
            "IndividualSampleTimestamps": "NOT_AVAILABLE",
            "EvidenceGranularity": "SESSION_FINAL_STABLE_SIGNATURE_SUMMARY",
            "EvidenceSource": "COHERENT_CURRENT_SESSION_SNAPSHOT_AND_RTL_STABILITY_INVARIANT",
            "Limitation": (
                "FPGA retained the final raw signature and consecutive-stability count; "
                "it did not retain five individually timestamped sample records"
            ),
        })
    return output


def count_evidence(value: str, overflow: str) -> str:
    parsed = parse_int(value)
    return (f">={parsed}" if str(overflow).strip().lower() in
            {"true", "1", "yes"} else str(parsed))


def i2c_intervals(rows: list[dict[str, str]], scan_result: dict[str, Any],
                  timestamps: dict[int, int]) -> list[dict[str, Any]]:
    output: list[dict[str, Any]] = []
    prior = 0
    for order, row in enumerate(rows, 1):
        current = parse_int(row["I2CTransactionCount"])
        require(current >= prior, "I2C_TRANSACTION_COUNT_NOT_MONOTONIC")
        output.append({
            "CheckpointOrder": order, "SessionID": row["SessionID"],
            "Round": row["Round"], "Channel": row["Channel"],
            "Checkpoint": "COHERENT_SESSION_SNAPSHOT",
            "HostTimestampNs": timestamps.get(parse_int(row["SessionID"]), ""),
            "AcceptedTransactionCount": current, "PriorCount": prior,
            "AcceptedTransactionDelta": current - prior,
            "NackCountEvidence": count_evidence(
                row["I2CNackCountLow8"], row["I2CNackOverflow"]),
            "TimeoutCountEvidence": count_evidence(
                row["I2CTimeoutCountLow8"], row["I2CTimeoutOverflow"]),
            "BusRecoveryCountEvidence": count_evidence(
                row["I2CBusRecoveryCountLow8"],
                row["I2CBusRecoveryOverflow"]),
            "CountBaseline": ("DIAG_CLEAR_SEMANTIC_ZERO" if order == 1
                              else "PRIOR_COHERENT_SNAPSHOT"),
            "EvidenceGranularity": "CUMULATIVE_ACCEPTED_COMMAND_INTERVAL_SUMMARY",
            "PerTransactionSequenceIDsRetained": "NO",
            "PerTransactionCommandsRetained": "NO",
            "PerTransactionTimestampsRetained": "NO",
            "EvidenceSource": "COHERENT_CURRENT_SESSION_SNAPSHOT_WORDS_5_6",
            "Limitation": (
                "Delta counts accepted commands only; internal command/register/result "
                "events were not mapped to host MMIO"
            ),
        })
        prior = current

    final = scan_result.get("final_state") or {}
    if "i2c_transaction_count" in final:
        current = parse_int(final["i2c_transaction_count"])
        require(current >= prior, "FINAL_I2C_TRANSACTION_COUNT_REGRESSED")
        output.append({
            "CheckpointOrder": len(output) + 1, "SessionID": "",
            "Round": "", "Channel": "", "Checkpoint": "FINAL_AFTER_RESTORE",
            "HostTimestampNs": "", "AcceptedTransactionCount": current,
            "PriorCount": prior, "AcceptedTransactionDelta": current - prior,
            "NackCountEvidence": final.get("i2c_nack_count", ""),
            "TimeoutCountEvidence": final.get("i2c_timeout_count", ""),
            "BusRecoveryCountEvidence": final.get("i2c_bus_recovery_count", ""),
            "CountBaseline": "LAST_COHERENT_SESSION_SNAPSHOT",
            "EvidenceGranularity": "CUMULATIVE_ACCEPTED_COMMAND_INTERVAL_SUMMARY",
            "PerTransactionSequenceIDsRetained": "NO",
            "PerTransactionCommandsRetained": "NO",
            "PerTransactionTimestampsRetained": "NO",
            "EvidenceSource": "FINAL_DIAGNOSTIC_COUNTER_MMIO_READS",
            "Limitation": "Final restore interval count; no internal event records retained",
        })
    return output


def write_ledgers(rows: list[dict[str, str]], scan_result: dict[str, Any]
                  ) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    writes: list[dict[str, Any]] = []
    reads: list[dict[str, Any]] = []

    def add_write(**values: Any) -> None:
        values.setdefault("Order", len(writes) + 1)
        values.setdefault("PhysicalTransactionRecordRetained", "NO")
        values.setdefault("EvidenceGranularity", "LOGICAL_OPERATION_WITH_READBACK_RECEIPT")
        values.setdefault("EvidenceSource", "COHERENT_SESSION_SNAPSHOT")
        values.setdefault("Limitation", "No physical I2C transaction event or timestamp retained")
        writes.append(values)

    def add_read(**values: Any) -> None:
        values.setdefault("Order", len(reads) + 1)
        values.setdefault("PhysicalTransactionIDsRetained", "NO")
        values.setdefault("EvidenceGranularity", "FINAL_STABLE_VALUE_OR_READBACK_RECEIPT")
        values.setdefault("EvidenceSource", "COHERENT_SESSION_SNAPSHOT")
        values.setdefault("Limitation", "No physical I2C transaction event or timestamp retained")
        reads.append(values)

    seen_rounds: set[int] = set()
    for row in rows:
        session = parse_int(row["SessionID"])
        round_number = parse_int(row["Round"])
        channel = parse_int(row["Channel"])
        common = {"SessionID": session, "Round": round_number,
                  "Channel": channel}
        if round_number not in seen_rounds:
            seen_rounds.add(round_number)
            colors = COLOR_CODES_BY_ROUND[round_number - 1]
            for register, requested, readback in (
                    (0x78, (colors[1] << 4) | colors[0], row["BGDCOL78"]),
                    (0x79, (colors[3] << 4) | colors[2], row["BGDCOL79"])):
                add_write(**common, LogicalOperation="PROGRAM_ROUND_BGDCOL",
                          Bank="0x00", Register=f"0x{register:02X}",
                          Field="CH1_CH2_NIBBLES" if register == 0x78 else
                                "CH3_CH4_NIBBLES",
                          RequestedFieldValue=f"0x{requested:02X}",
                          RequestedFullByte=f"0x{requested:02X}",
                          ReadbackFullByte=row[f"BGDCOL{register:02X}"],
                          ReadbackMatch=(parse_int(readback) == requested))
                add_read(**common, LogicalReadback="VERIFY_ROUND_BGDCOL",
                         Bank="0x00", Register=f"0x{register:02X}",
                         Field="FULL_BYTE", ReadbackValue=readback,
                         EquivalentConsecutiveReadsProven=1)

        requested_route = channel - 1
        route_readback = parse_int(row["RouteReadback"])
        add_write(**common, LogicalOperation="SELECT_VDO1_ROUTE",
                  Bank="0x01", Register="0xC2", Field="bits[3:0]",
                  RequestedFieldValue=f"0x{requested_route:X}",
                  RequestedFullByte="NOT_RETAINED_RMW_PRESERVES_BITS_7_4",
                  ReadbackFullByte=row["RouteReadback"],
                  ReadbackMatch=((route_readback & 0xF) == requested_route))
        add_read(**common, LogicalReadback="VERIFY_VDO1_ROUTE",
                 Bank="0x01", Register="0xC2", Field="FULL_BYTE",
                 ReadbackValue=row["RouteReadback"],
                 EquivalentConsecutiveReadsProven=1)

        stable = (parse_int(row["StableSamples"])
                  if row["Classification"] in STABILITY_CLASSIFICATIONS else 0)
        for register, field, key in (
                ("0xA8", "NOVID[3:0]", "RawNOVID"),
                ("0xE0", "AGC_LOCK[3:0]", "RawAGCLock"),
                ("0xE1", "COMPARATOR_CLAMP_LOCK[3:0]", "RawComparatorLock"),
                ("0xE2", "H_LOCK[3:0]", "RawHLock"),
                (f"0x{0xE8 + channel - 1:02X}", "CHANNEL_STATUS",
                 "RawChannelStatus")):
            add_read(**common, LogicalReadback="STATUS_STABILITY_WINDOW",
                     Bank="0x00", Register=register, Field=field,
                     ReadbackValue=row[key],
                     EquivalentConsecutiveReadsProven=stable,
                     EvidenceGranularity="FINAL_VALUE_PLUS_CONSECUTIVE_EQUIVALENCE_COUNT",
                     Limitation=(
                         "Individual status-read events/timestamps were not retained; "
                         "equivalence follows from the verified firmware stability counter"
                     ))

    original = scan_result.get("original_baseline") or {}
    final = scan_result.get("final_state") or {}
    if original and final:
        for register, key, bank, field in (
                ("0xC2", "route", "0x01", "bits[3:0]"),
                ("0x78", "bgcolor_78", "0x00", "FULL_BYTE"),
                ("0x79", "bgcolor_79", "0x00", "FULL_BYTE")):
            requested = parse_int(original[key])
            readback = parse_int(final[key])
            add_write(SessionID="", Round="", Channel="",
                      LogicalOperation="RESTORE_PRODUCT_BASELINE", Bank=bank,
                      Register=register, Field=field,
                      RequestedFieldValue=f"0x{requested:02X}",
                      RequestedFullByte=(f"0x{requested:02X}" if field == "FULL_BYTE"
                                         else "NOT_RETAINED_RMW_PRESERVES_BITS_7_4"),
                      ReadbackFullByte=f"0x{readback:02X}",
                      ReadbackMatch=(readback == requested),
                      EvidenceSource="SAVED_BASELINE_AND_FINAL_MMIO_READBACK")
            add_read(SessionID="", Round="", Channel="",
                     LogicalReadback="VERIFY_PRODUCT_BASELINE_RESTORE", Bank=bank,
                     Register=register, Field="FULL_BYTE",
                     ReadbackValue=f"0x{readback:02X}",
                     EquivalentConsecutiveReadsProven=1,
                     EvidenceSource="FINAL_DIAGNOSTIC_MMIO_READBACK")
    return writes, reads


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--status-history", required=True, type=Path)
    parser.add_argument("--scan-result", required=True, type=Path)
    parser.add_argument("--snapshot-coherence", type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--expected-sessions", type=int, default=16)
    parser.add_argument("--allow-partial", action="store_true")
    args = parser.parse_args()

    rows = validate_sessions(read_csv(args.status_history),
                             args.expected_sessions, args.allow_partial)
    scan_result = json.loads(args.scan_result.read_text(encoding="utf-8"))
    timestamps = session_timestamps(args.snapshot_coherence)
    status = status_summaries(rows)
    transactions = i2c_intervals(rows, scan_result, timestamps)
    writes, readbacks = write_ledgers(rows, scan_result)

    outputs = {
        "G2B_NVP_VIDEO_DIAG1_R1_STATUS_SAMPLES.csv": (STATUS_FIELDS, status),
        "G2B_NVP_VIDEO_DIAG1_R1_I2C_TRANSACTION_LOG.csv":
            (I2C_FIELDS, transactions),
        "G2B_NVP_VIDEO_DIAG1_R1_NVP_WRITE_LEDGER.csv":
            (WRITE_FIELDS, writes),
        "G2B_NVP_VIDEO_DIAG1_R1_NVP_READBACK_LEDGER.csv":
            (READBACK_FIELDS, readbacks),
    }
    for name, (fields, data) in outputs.items():
        write_csv_atomic(args.output_root / name, fields, data)

    receipt = {
        "result": "PASS",
        "session_rows": len(rows),
        "status_evidence_granularity": "SESSION_FINAL_STABLE_SIGNATURE_SUMMARY",
        "individual_raw_status_sample_history_retained": False,
        "i2c_evidence_granularity": "CUMULATIVE_ACCEPTED_COMMAND_INTERVAL_SUMMARY",
        "per_transaction_event_history_retained": False,
        "logical_write_rows": len(writes),
        "readback_rows": len(readbacks),
        "transaction_interval_rows": len(transactions),
        "outputs": sorted(outputs),
        "engineering_use": (
            "Supports runtime status stability, route/BGDCOL readback, and aggregate "
            "I2C health gates; does not prove byte-exact per-transaction event history"
        ),
    }
    write_json_atomic(args.output_root /
                      "G2B_NVP_VIDEO_DIAG1_R1_RUNTIME_EVIDENCE_SCOPE.json",
                      receipt)
    print(json.dumps(receipt, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
