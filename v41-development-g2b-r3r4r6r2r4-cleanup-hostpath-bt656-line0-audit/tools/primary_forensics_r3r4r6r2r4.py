#!/usr/bin/env python3
"""Read-only fixed-boundary forensic audit of preserved R3R4R6R2R3 primary.bin."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
from typing import Any

from abi_v1 import AbiContract, RecordValidationError, parse_record


RECORD_BYTES = 4096
PRIMARY_RECORDS = 2500
PRIMARY_BYTES = RECORD_BYTES * PRIMARY_RECORDS


def delta32(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFF


def write_json(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fields: list[str], rows: list[dict[str, Any]]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})
        handle.flush()
        os.fsync(handle.fileno())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--primary", required=True, type=Path)
    parser.add_argument("--csv", required=True, type=Path)
    parser.add_argument("--json", required=True, type=Path)
    args = parser.parse_args()

    if not args.primary.is_file() or args.primary.stat().st_size != PRIMARY_BYTES:
        raise RuntimeError("R3R4R6R2R4_PRIMARY_CAPTURE_NOT_AVAILABLE")
    contract = AbiContract.load(args.abi)
    records: list[Any] = []
    integrity_failures: list[dict[str, Any]] = []
    with args.primary.open("rb", buffering=0) as handle:
        for index in range(PRIMARY_RECORDS):
            blob = handle.read(RECORD_BYTES)
            if len(blob) != RECORD_BYTES:
                raise RuntimeError(f"R3R4R6R2R4_SHORT_PRIMARY_RECORD:{index}:{len(blob)}")
            try:
                records.append(parse_record(contract, blob))
            except RecordValidationError as exc:
                integrity_failures.append({"RecordIndex": index, "Errors": exc.errors})
                records.append(None)
        if handle.read(1) != b"":
            raise RuntimeError("R3R4R6R2R4_PRIMARY_HAS_TRAILING_BYTES")

    flags = contract.flags
    event_mask = (flags["DISCONTINUITY"] | flags["OVERFLOW_OCCURRED"] |
                  flags["MALFORMED_PRECEDING"])
    event_rows: list[dict[str, Any]] = []
    progression_breaks = 0
    global_sequence_errors = 0
    line_zero_indices: list[int] = []
    clean_sof_indices: list[int] = []
    for index, record in enumerate(records):
        if record is None:
            continue
        if record.global_stream_sequence != index:
            global_sequence_errors += 1
        if record.source_line_sequence == 0:
            line_zero_indices.append(index)
            if ((record.flags & flags["SOF"]) and not (record.flags & event_mask)):
                clean_sof_indices.append(index)
        previous = records[index - 1] if index > 0 else None
        following = records[index + 1] if index + 1 < len(records) else None
        if previous is not None:
            expected_line = previous.source_line_sequence + 1
            expected_frame = previous.source_frame_sequence
            if expected_line == contract.lines_per_frame:
                expected_line = 0
                expected_frame = (expected_frame + 1) & 0xFFFFFFFF
            if (record.source_line_sequence != expected_line or
                    record.source_frame_sequence != expected_frame or
                    record.source_capture_sequence !=
                    ((previous.source_capture_sequence + 1) & 0xFFFFFFFF)):
                progression_breaks += 1
        if not (record.flags & event_mask):
            continue
        if record.flags & flags["OVERFLOW_OCCURRED"]:
            classification = "PRIMARY_TRANSIENT_OVERFLOW_EVENT"
        elif (record.flags & flags["MALFORMED_PRECEDING"] and previous is not None and
              previous.source_line_sequence == contract.lines_per_frame - 1 and
              record.source_line_sequence == 1):
            classification = "BT656_FRAME_BOUNDARY_EVENT"
        elif index == 0 and record.flags & flags["DISCONTINUITY"]:
            classification = "INITIAL_TRANSITION_FRAGMENT"
        else:
            classification = "OTHER_CONTINUITY_EVENT"
        event_rows.append({
            "RecordIndex": index,
            "FrameSequence": record.source_frame_sequence,
            "LineSequence": record.source_line_sequence,
            "CaptureSequence": record.source_capture_sequence,
            "AttemptSequence": record.channel_attempt_sequence,
            "GlobalSequence": record.global_stream_sequence,
            "Flags": f"0x{record.flags:08X}",
            "SourceMalformedSnapshot": record.value("source_malformed_count_snapshot"),
            "SourceDroppedSnapshot": record.value("source_dropped_count_snapshot"),
            "PreviousFrame": "" if previous is None else previous.source_frame_sequence,
            "PreviousLine": "" if previous is None else previous.source_line_sequence,
            "PreviousAttemptSequence": "" if previous is None else previous.channel_attempt_sequence,
            "PreviousMalformedSnapshot": "" if previous is None else previous.value("source_malformed_count_snapshot"),
            "PreviousDroppedSnapshot": "" if previous is None else previous.value("source_dropped_count_snapshot"),
            "NextFrame": "" if following is None else following.source_frame_sequence,
            "NextLine": "" if following is None else following.source_line_sequence,
            "MalformedDeltaFromPrevious": "" if previous is None else delta32(
                record.value("source_malformed_count_snapshot"),
                previous.value("source_malformed_count_snapshot")),
            "DroppedDeltaFromPrevious": "" if previous is None else delta32(
                record.value("source_dropped_count_snapshot"),
                previous.value("source_dropped_count_snapshot")),
            "EventClassification": classification,
        })

    overflow_rows = [row for row in event_rows
                     if row["EventClassification"] == "PRIMARY_TRANSIENT_OVERFLOW_EVENT"]
    boundary_rows = [row for row in event_rows
                     if row["EventClassification"] == "BT656_FRAME_BOUNDARY_EVENT"]
    malformed_first = records[0].value("source_malformed_count_snapshot")
    malformed_last = records[-1].value("source_malformed_count_snapshot")
    total_malformed_delta = delta32(malformed_last, malformed_first)
    boundaries_identical = (
        len(boundary_rows) == 2 and
        all(row["PreviousLine"] == 1079 and row["LineSequence"] == 1 and
            row["MalformedDeltaFromPrevious"] == 21 and row["Flags"] == "0x00000034"
            for row in boundary_rows)
    )
    expected_overflow = (
        len(overflow_rows) == 1 and overflow_rows[0]["RecordIndex"] == 441 and
        overflow_rows[0]["PreviousLine"] == 943 and
        overflow_rows[0]["LineSequence"] == 946 and
        overflow_rows[0]["PreviousAttemptSequence"] == 440 and
        overflow_rows[0]["AttemptSequence"] == 443 and
        overflow_rows[0]["DroppedDeltaFromPrevious"] == 2 and
        overflow_rows[0]["Flags"] == "0x0000002C"
    )
    expected_boundaries = (
        len(boundary_rows) == 2 and
        boundary_rows[0]["PreviousFrame"] == 202797 and
        boundary_rows[0]["FrameSequence"] == 202798 and
        boundary_rows[1]["PreviousFrame"] == 202798 and
        boundary_rows[1]["FrameSequence"] == 202799 and
        boundaries_identical
    )
    result = {
        "task": "G2B-HW0-PRODUCT-R3R4R6R2R4",
        "result": "PASS" if (
            not integrity_failures and global_sequence_errors == 0 and
            records[0].global_stream_sequence == 0 and
            records[-1].global_stream_sequence == 2499 and
            progression_breaks == 3 and expected_overflow and expected_boundaries and
            total_malformed_delta == 42 and not line_zero_indices and
            not clean_sof_indices
        ) else "FAIL",
        "primary_records": PRIMARY_RECORDS,
        "primary_bytes": PRIMARY_BYTES,
        "record_integrity_failures": len(integrity_failures),
        "global_sequence_first": records[0].global_stream_sequence,
        "global_sequence_last": records[-1].global_stream_sequence,
        "global_sequence_errors": global_sequence_errors,
        "source_progression_breaks": progression_breaks,
        "primary_overflow_event_index": overflow_rows[0]["RecordIndex"] if overflow_rows else None,
        "primary_overflow_expected_details_confirmed": expected_overflow,
        "frame_boundary_event_1_confirmed": len(boundary_rows) >= 1,
        "frame_boundary_event_1_transition": (
            f"{boundary_rows[0]['PreviousFrame']}_LINE_{boundary_rows[0]['PreviousLine']}_TO_"
            f"{boundary_rows[0]['FrameSequence']}_LINE_{boundary_rows[0]['LineSequence']}"
            if len(boundary_rows) >= 1 else None),
        "frame_boundary_event_1_malformed_delta": (
            boundary_rows[0]["MalformedDeltaFromPrevious"] if len(boundary_rows) >= 1 else None),
        "frame_boundary_event_2_confirmed": len(boundary_rows) >= 2,
        "frame_boundary_event_2_transition": (
            f"{boundary_rows[1]['PreviousFrame']}_LINE_{boundary_rows[1]['PreviousLine']}_TO_"
            f"{boundary_rows[1]['FrameSequence']}_LINE_{boundary_rows[1]['LineSequence']}"
            if len(boundary_rows) >= 2 else None),
        "frame_boundary_event_2_malformed_delta": (
            boundary_rows[1]["MalformedDeltaFromPrevious"] if len(boundary_rows) >= 2 else None),
        "total_malformed_snapshot_delta": total_malformed_delta,
        "line_zero_present": bool(line_zero_indices),
        "clean_sof_present": bool(clean_sof_indices),
        "frame_boundary_events_structurally_identical": boundaries_identical,
        "every_observed_complete_frame_transition_loses_line_zero": boundaries_identical,
        "every_line_zero_loss_malformed_delta_21": boundaries_identical,
        "every_next_line_one_has_malformed_preceding": boundaries_identical,
        "event_count": len(event_rows),
        "integrity_failures": integrity_failures,
    }
    write_csv(args.csv, [
        "RecordIndex", "FrameSequence", "LineSequence", "CaptureSequence",
        "AttemptSequence", "GlobalSequence", "Flags", "SourceMalformedSnapshot",
        "SourceDroppedSnapshot", "PreviousFrame", "PreviousLine",
        "PreviousAttemptSequence", "PreviousMalformedSnapshot",
        "PreviousDroppedSnapshot", "NextFrame", "NextLine",
        "MalformedDeltaFromPrevious", "DroppedDeltaFromPrevious",
        "EventClassification",
    ], event_rows)
    write_json(args.json, result)
    print(json.dumps(result, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
