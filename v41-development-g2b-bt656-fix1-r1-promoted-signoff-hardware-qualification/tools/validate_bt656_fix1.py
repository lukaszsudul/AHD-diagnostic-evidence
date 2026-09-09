#!/usr/bin/env python3
"""Disk-based fixed-boundary validation for the BT656 FIX1 primary window."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
from typing import Any

from abi_v1 import AbiContract, RecordValidationError, parse_record
from frame_reconstruct_bt656_fix1 import write_png_from_uyvy


RECORDS = 2500
RECORD_BYTES = 4096
PRIMARY_BYTES = RECORDS * RECORD_BYTES


def write_bytes(path: Path, data: bytes) -> str:
    with path.open("xb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    return hashlib.sha256(data).hexdigest().upper()


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


def delta32(after: int, before: int) -> int:
    return (after - before) & 0xFFFFFFFF


def classify_first(flags: int, contract: AbiContract) -> str:
    events = []
    if flags & contract.flags["DISCONTINUITY"]:
        events.append("DISCONTINUITY")
    if flags & contract.flags["OVERFLOW_OCCURRED"]:
        events.append("OVERFLOW")
    if flags & contract.flags["MALFORMED_PRECEDING"]:
        events.append("MALFORMED_PRECEDING")
    if not events:
        return "CLEAN"
    return events[0] if len(events) == 1 else "MULTIPLE_EVENTS"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--primary", required=True, type=Path)
    parser.add_argument("--controller-result", required=True, type=Path)
    parser.add_argument("--private-dir", required=True, type=Path)
    parser.add_argument("--logs-dir", required=True, type=Path)
    args = parser.parse_args()
    result: dict[str, Any] = {"result": "FAIL", "blocker": None}
    try:
        contract = AbiContract.load(args.abi)
        controller = json.loads(args.controller_result.read_text(encoding="utf-8"))
        armed_epoch = int(controller["S2"]["Epoch"])
        raw = args.primary.read_bytes()
        if len(raw) != PRIMARY_BYTES:
            raise RuntimeError(f"BT656_FIX1_PRIMARY_SIZE:{len(raw)}:{PRIMARY_BYTES}")
        primary_sha = hashlib.sha256(raw).hexdigest().upper()
        first_record = raw[:RECORD_BYTES]
        first_sha = write_bytes(args.private_dir / "first-record.bin", first_record)
        first_payload = first_record[64:3904]
        first_payload_sha = write_bytes(args.private_dir / "first-payload.bin",
                                        first_payload)

        records: list[Any] = []
        rows: list[dict[str, Any]] = []
        integrity_failures = 0
        structural_failures = 0
        payload_failures = 0
        padding_errors = 0
        discontinuity_indices: list[int] = []
        overflow_indices: list[int] = []
        malformed_indices: list[int] = []
        global_gaps = 0
        attempt_gaps = 0
        source_breaks = 0
        expected_vertical_tail_jumps = 0
        unexpected_capture_gaps = 0
        epoch_errors = 0
        previous = None
        for index in range(RECORDS):
            blob = raw[index * RECORD_BYTES:(index + 1) * RECORD_BYTES]
            errors: list[str] = []
            record = None
            try:
                record = parse_record(contract, blob)
            except RecordValidationError as exc:
                errors.extend(exc.errors)
            if record is not None and record.reset_epoch != armed_epoch:
                errors.append(f"epoch {record.reset_epoch} expected {armed_epoch}")
                epoch_errors += 1
            if errors:
                integrity_failures += 1
                if any("payload length" in item for item in errors):
                    payload_failures += 1
                if any("padding byte" in item for item in errors):
                    padding_errors += 1
                if any("payload length" not in item and "padding byte" not in item
                       for item in errors):
                    structural_failures += 1
                rows.append({"RecordIndex": index, "Integrity": "FAIL",
                             "Errors": "; ".join(errors)})
                records.append(None)
                previous = None
                continue

            assert record is not None
            records.append(record)
            flags = record.flags
            if flags & contract.flags["DISCONTINUITY"]:
                discontinuity_indices.append(index)
            if flags & contract.flags["OVERFLOW_OCCURRED"]:
                overflow_indices.append(index)
            if flags & contract.flags["MALFORMED_PRECEDING"]:
                malformed_indices.append(index)
            expected_global = index & 0xFFFFFFFF
            if record.global_stream_sequence != expected_global:
                global_gaps += 1
            if previous is not None:
                if record.channel_attempt_sequence != (
                        previous.channel_attempt_sequence + 1) & 0xFFFFFFFF:
                    attempt_gaps += 1
                expected_line = previous.source_line_sequence + 1
                expected_frame = previous.source_frame_sequence
                if expected_line == contract.lines_per_frame:
                    expected_line = 0
                    expected_frame = (expected_frame + 1) & 0xFFFFFFFF
                frame_boundary = (previous.source_line_sequence == 1079 and
                                  expected_line == 0)
                capture_delta = delta32(record.source_capture_sequence,
                                        previous.source_capture_sequence)
                expected_capture_delta = 22 if frame_boundary else 1
                if frame_boundary and capture_delta == 22:
                    expected_vertical_tail_jumps += 1
                if capture_delta != expected_capture_delta:
                    unexpected_capture_gaps += 1
                if (record.source_line_sequence != expected_line or
                        record.source_frame_sequence != expected_frame):
                    source_breaks += 1
            previous = record
            rows.append({
                "RecordIndex": index, "Integrity": "PASS",
                "Flags": f"0x{flags:08X}", "Epoch": record.reset_epoch,
                "Frame": record.source_frame_sequence,
                "Line": record.source_line_sequence,
                "CaptureSequence": record.source_capture_sequence,
                "AttemptSequence": record.channel_attempt_sequence,
                "GlobalSequence": record.global_stream_sequence,
                "SourceMalformedSnapshot": record.value(
                    "source_malformed_count_snapshot"),
                "SourceDroppedSnapshot": record.value(
                    "source_dropped_count_snapshot"), "Errors": "",
            })

        event_mask = (contract.flags["DISCONTINUITY"] |
                      contract.flags["OVERFLOW_OCCURRED"] |
                      contract.flags["MALFORMED_PRECEDING"])
        boundary_rows: list[dict[str, Any]] = []
        for index in range(1, RECORDS):
            previous_record = records[index - 1]
            current_record = records[index]
            next_record = records[index + 1] if index + 1 < RECORDS else None
            if (previous_record is None or current_record is None or
                    previous_record.source_line_sequence != 1079):
                continue
            capture_delta = delta32(current_record.source_capture_sequence,
                                    previous_record.source_capture_sequence)
            boundary_rows.append({
                "PreviousRecordIndex": index - 1,
                "Line0RecordIndex": index,
                "PreviousFrame": previous_record.source_frame_sequence,
                "Line0Frame": current_record.source_frame_sequence,
                "Line0Line": current_record.source_line_sequence,
                "Line0Flags": f"0x{current_record.flags:08X}",
                "Line1Follows": bool(next_record is not None and
                                      next_record.source_frame_sequence ==
                                      current_record.source_frame_sequence and
                                      next_record.source_line_sequence == 1),
                "Line1Flags": (f"0x{next_record.flags:08X}"
                               if next_record is not None else ""),
                "CaptureSequenceDelta": capture_delta,
                "ExpectedCaptureSequenceDelta": 22,
                "AttemptSequenceDelta": delta32(
                    current_record.channel_attempt_sequence,
                    previous_record.channel_attempt_sequence),
                "GlobalSequenceDelta": delta32(
                    current_record.global_stream_sequence,
                    previous_record.global_stream_sequence),
                "MalformedDelta": delta32(
                    current_record.value("source_malformed_count_snapshot"),
                    previous_record.value("source_malformed_count_snapshot")),
                "DroppedDelta": delta32(
                    current_record.value("source_dropped_count_snapshot"),
                    previous_record.value("source_dropped_count_snapshot")),
                "Result": "PASS" if (
                    current_record.source_line_sequence == 0 and
                    current_record.flags == (contract.flags["VALID"] |
                                             contract.flags["SOF"]) and
                    next_record is not None and
                    next_record.source_line_sequence == 1 and
                    next_record.flags == contract.flags["VALID"] and
                    capture_delta == 22 and
                    delta32(current_record.channel_attempt_sequence,
                            previous_record.channel_attempt_sequence) == 1 and
                    delta32(current_record.global_stream_sequence,
                            previous_record.global_stream_sequence) == 1 and
                    delta32(current_record.value("source_malformed_count_snapshot"),
                            previous_record.value("source_malformed_count_snapshot")) == 0 and
                    delta32(current_record.value("source_dropped_count_snapshot"),
                            previous_record.value("source_dropped_count_snapshot")) == 0
                ) else "FAIL",
            })
        first_clean_sof = None
        for index, record in enumerate(records):
            if (record is not None and record.source_line_sequence == 0 and
                    (record.flags & contract.flags["SOF"]) and
                    not (record.flags & event_mask)):
                first_clean_sof = index
                break

        frame_start = None
        frame_end = None
        selected = None
        if first_clean_sof is not None:
            for start in range(first_clean_sof, RECORDS):
                candidate = records[start]
                if (candidate is None or candidate.source_line_sequence != 0 or
                        not (candidate.flags & contract.flags["SOF"]) or
                        candidate.flags & event_mask):
                    continue
                if start + contract.lines_per_frame > RECORDS:
                    continue
                ok = True
                for line in range(contract.lines_per_frame):
                    record = records[start + line]
                    expected_flags = contract.flags["VALID"] | (
                        contract.flags["SOF"] if line == 0 else 0)
                    if (record is None or record.reset_epoch != candidate.reset_epoch or
                            record.source_frame_sequence != candidate.source_frame_sequence or
                            record.source_line_sequence != line or
                            record.flags != expected_flags):
                        ok = False
                        break
                if ok:
                    frame_start = start
                    frame_end = start + contract.lines_per_frame - 1
                    selected = candidate
                    break

        raw_frame_sha = None
        png_sha = None
        frame_sequence = None
        frame_epoch = None
        if frame_start is not None and frame_end is not None and selected is not None:
            frame = b"".join(records[index].payload
                             for index in range(frame_start, frame_end + 1))
            if len(frame) != 4_147_200:
                raise RuntimeError("BT656_FIX1_FRAME_SIZE_INVALID")
            raw_frame_sha = write_bytes(args.private_dir / "qualified-frame.uyvy", frame)
            png_sha = write_png_from_uyvy(args.private_dir / "qualified-frame.png", frame,
                                          contract.pixels_per_line,
                                          contract.lines_per_frame)
            frame_sequence = selected.source_frame_sequence
            frame_epoch = selected.reset_epoch

        first_integral = records[0] is not None
        first_flags = records[0].flags if first_integral else 0
        first_continuity = classify_first(first_flags, contract) if first_integral \
            else "NOT_REACHED"
        malformed_first_snapshot = (records[0].value("source_malformed_count_snapshot")
                                    if records[0] is not None else None)
        malformed_last_snapshot = (records[-1].value("source_malformed_count_snapshot")
                                   if records[-1] is not None else None)
        malformed_delta = (delta32(malformed_last_snapshot, malformed_first_snapshot)
                           if malformed_first_snapshot is not None and
                           malformed_last_snapshot is not None else None)
        dropped_first_snapshot = (records[0].value("source_dropped_count_snapshot")
                                  if records[0] is not None else None)
        dropped_last_snapshot = (records[-1].value("source_dropped_count_snapshot")
                                 if records[-1] is not None else None)
        dropped_delta = (delta32(dropped_last_snapshot, dropped_first_snapshot)
                         if dropped_first_snapshot is not None and
                         dropped_last_snapshot is not None else None)
        clean_snapshot = (records[first_clean_sof].value(
            "source_malformed_count_snapshot") if first_clean_sof is not None else None)
        post_clean_growth = (delta32(malformed_last_snapshot, clean_snapshot)
                             if clean_snapshot is not None and
                             malformed_last_snapshot is not None else None)
        recurring = (first_clean_sof is not None and
                     (any(index >= first_clean_sof for index in malformed_indices) or
                      (post_clean_growth is not None and post_clean_growth != 0)))
        if not malformed_indices and malformed_delta == 0:
            bt656 = "PASS"
        elif (malformed_indices and first_clean_sof is not None and
              all(index < first_clean_sof for index in malformed_indices) and
              post_clean_growth == 0 and frame_start is not None):
            bt656 = "PASS_WITH_INITIAL_TRANSITION"
        else:
            bt656 = "OPEN_RECURRING_BT656_QUALIFICATION_EVENT"

        malformed_rows = []
        for index in malformed_indices:
            record = records[index]
            assert record is not None
            malformed_rows.append({
                "RecordIndex": index, "Epoch": record.reset_epoch,
                "Frame": record.source_frame_sequence,
                "Line": record.source_line_sequence,
                "Flags": f"0x{record.flags:08X}",
                "SourceMalformedSnapshot": record.value(
                    "source_malformed_count_snapshot"),
                "SourceDroppedSnapshot": record.value(
                    "source_dropped_count_snapshot"),
                "GlobalSequence": record.global_stream_sequence,
                "AttemptSequence": record.channel_attempt_sequence,
                "BeforeFirstCleanSOF": (first_clean_sof is None or
                                        index < first_clean_sof),
                "InsideQualifiedFrame": (frame_start is not None and
                                         frame_start <= index <= frame_end),
            })

        controller_deltas = controller.get("counter_deltas", {})
        tail_present = bool(controller_deltas.get("dropped", 0) or
                            controller_deltas.get("overflow", 0) or
                            controller.get("S3", {}).get("ErrorStatus", 0))
        post_target_tail = ("PRESENT" if tail_present and not overflow_indices and
                            integrity_failures == 0 and global_gaps == 0 else
                            "NONE" if not tail_present else "UNRESOLVED")
        discont_after_first = [index for index in discontinuity_indices if index > 0]
        primary_pass = (integrity_failures == 0 and global_gaps == 0 and
                        attempt_gaps == 0 and source_breaks == 0 and
                        unexpected_capture_gaps == 0 and
                        expected_vertical_tail_jumps >= 1 and
                        bool(boundary_rows) and
                        all(row["Result"] == "PASS" for row in boundary_rows) and
                        records[0].global_stream_sequence == 0 and
                        records[-1].global_stream_sequence == 2499 and
                        not overflow_indices and not malformed_indices and
                        not discont_after_first and malformed_delta == 0 and
                        dropped_delta == 0)
        frame_pass = frame_start is not None
        stream_pass = global_gaps == 0 and frame_pass

        first_prediction = (
            "MATCH" if first_integral and
            not (first_flags & (contract.flags["OVERFLOW_OCCURRED"] |
                                contract.flags["MALFORMED_PRECEDING"])) else "DEVIATION")
        post_prediction = (
            "MATCH" if not overflow_indices and
            not [index for index in malformed_indices if index > 0] and
            not discont_after_first
            else "DEVIATION")

        result = {
            "result": "PASS" if primary_pass and frame_pass else "FAIL",
            "blocker": None if primary_pass and frame_pass else
                "BT656_FIX1_PRIMARY_RECORD_OR_FRAME_QUALIFICATION_FAILED",
            "primary_file_sha256": primary_sha,
            "primary_bytes": len(raw), "primary_records": RECORDS,
            "first_record_sha256": first_sha,
            "first_payload_sha256": first_payload_sha,
            "first_record_integrity": "PASS" if first_integral else "FAIL",
            "first_record_continuity": first_continuity,
            "first_record_flags": f"0x{first_flags:08X}" if first_integral else None,
            "record_integrity_failures": integrity_failures,
            "structural_header_failures": structural_failures,
            "payload_geometry_failures": payload_failures,
            "padding_errors": padding_errors,
            "epoch_errors": epoch_errors,
            "discontinuity_flag_records": len(discontinuity_indices),
            "overflow_flag_records": len(overflow_indices),
            "malformed_preceding_flag_records": len(malformed_indices),
            "first_malformed_preceding_record": (malformed_indices[0]
                                                  if malformed_indices else None),
            "last_malformed_preceding_record": (malformed_indices[-1]
                                                 if malformed_indices else None),
            "global_sequence_first": (records[0].global_stream_sequence
                                      if records[0] else None),
            "global_sequence_last": (records[-1].global_stream_sequence
                                     if records[-1] else None),
            "global_sequence_gaps": global_gaps,
            "attempt_sequence_gaps": attempt_gaps,
            "source_progression_breaks": source_breaks,
            "expected_vertical_tail_capture_sequence_jumps":
                expected_vertical_tail_jumps,
            "unexpected_source_capture_sequence_gaps": unexpected_capture_gaps,
            "source_malformed_snapshot_first": malformed_first_snapshot,
            "source_malformed_snapshot_last": malformed_last_snapshot,
            "source_malformed_snapshot_delta": malformed_delta,
            "source_dropped_snapshot_first": dropped_first_snapshot,
            "source_dropped_snapshot_last": dropped_last_snapshot,
            "source_dropped_snapshot_delta": dropped_delta,
            "post_clean_sof_malformed_snapshot_delta": post_clean_growth,
            "first_clean_sof_index": first_clean_sof,
            "bt656_source_qualification": bt656,
            "first_record_prediction": first_prediction,
            "post_first_record_prediction": post_prediction,
            "clean_frame_prediction": "MATCH" if frame_pass else "DEVIATION",
            "record_path_integrity": "PASS" if integrity_failures == 0 else "FAIL",
            "stream_continuity": "PASS" if stream_pass else "FAIL",
            "frame_reconstruction": "PASS" if frame_pass else "FAIL",
            "frame_source_sequence": frame_sequence,
            "frame_epoch": frame_epoch,
            "qualified_frame_record_first": frame_start,
            "qualified_frame_record_last": frame_end,
            "qualified_frame_missing_lines": 0 if frame_pass else None,
            "qualified_frame_duplicate_lines": 0 if frame_pass else None,
            "qualified_frame_synthetic_lines": 0 if frame_pass else None,
            "raw_frame_sha256": raw_frame_sha,
            "viewable_frame_sha256": png_sha,
            "post_target_shutdown_tail": post_target_tail,
            "line_0_present": any(record is not None and
                                  record.source_line_sequence == 0
                                  for record in records),
            "line_0_sof": any(record is not None and
                              record.source_line_sequence == 0 and
                              bool(record.flags & contract.flags["SOF"])
                              for record in records),
            "vertical_boundary_malformed_events": sum(
                1 for row in boundary_rows if row["MalformedDelta"] != 0),
            "vertical_boundary_source_drops": sum(
                1 for row in boundary_rows if row["DroppedDelta"] != 0),
            "frame_boundary_results": boundary_rows,
            "controller_counter_deltas": controller_deltas,
        }

        write_csv(args.logs_dir / "primary-record-metrics.csv",
                  ["RecordIndex", "Integrity", "Flags", "Epoch", "Frame", "Line",
                   "CaptureSequence", "AttemptSequence", "GlobalSequence",
                   "SourceMalformedSnapshot", "SourceDroppedSnapshot", "Errors"], rows)
        write_csv(args.logs_dir / "malformed-preceding-timeline.csv",
                  ["RecordIndex", "Epoch", "Frame", "Line", "Flags",
                   "SourceMalformedSnapshot", "SourceDroppedSnapshot",
                   "GlobalSequence", "AttemptSequence", "BeforeFirstCleanSOF",
                   "InsideQualifiedFrame"], malformed_rows)
        continuity_rows = [
            {"Metric": "DISCONTINUITY_FLAG_RECORDS", "Value": len(discontinuity_indices)},
            {"Metric": "OVERFLOW_OCCURRED_FLAG_RECORDS", "Value": len(overflow_indices)},
            {"Metric": "MALFORMED_PRECEDING_FLAG_RECORDS", "Value": len(malformed_indices)},
            {"Metric": "GLOBAL_SEQUENCE_GAPS", "Value": global_gaps},
            {"Metric": "ATTEMPT_SEQUENCE_GAPS", "Value": attempt_gaps},
            {"Metric": "SOURCE_PROGRESSION_BREAKS", "Value": source_breaks},
            {"Metric": "EXPECTED_VERTICAL_TAIL_CAPTURE_SEQUENCE_JUMPS",
             "Value": expected_vertical_tail_jumps},
            {"Metric": "UNEXPECTED_SOURCE_CAPTURE_SEQUENCE_GAPS",
             "Value": unexpected_capture_gaps},
            {"Metric": "SOURCE_MALFORMED_SNAPSHOT_DELTA", "Value": malformed_delta},
            {"Metric": "SOURCE_DROPPED_SNAPSHOT_DELTA", "Value": dropped_delta},
        ]
        write_csv(args.logs_dir / "stream-continuity-metrics.csv",
                  ["Metric", "Value"], continuity_rows)
        write_csv(args.logs_dir / "frame-boundary-analysis.csv",
                  ["PreviousRecordIndex", "Line0RecordIndex", "PreviousFrame",
                   "Line0Frame", "Line0Line", "Line0Flags", "Line1Follows",
                   "Line1Flags", "CaptureSequenceDelta",
                   "ExpectedCaptureSequenceDelta", "AttemptSequenceDelta",
                   "GlobalSequenceDelta", "MalformedDelta", "DroppedDelta",
                   "Result"], boundary_rows)
        write_csv(args.logs_dir / "capture-sequence-analysis.csv",
                  ["RecordIndex", "Frame", "Line", "CaptureSequence",
                   "AttemptSequence", "GlobalSequence"],
                  [{"RecordIndex": index, "Frame": record.source_frame_sequence,
                    "Line": record.source_line_sequence,
                    "CaptureSequence": record.source_capture_sequence,
                    "AttemptSequence": record.channel_attempt_sequence,
                    "GlobalSequence": record.global_stream_sequence}
                   for index, record in enumerate(records) if record is not None])
        first_header = contract.unpack_header(first_record)
        write_csv(args.logs_dir / "first-record-header.csv",
                  ["Field", "ValueDecimal", "ValueHex"],
                  [{"Field": key, "ValueDecimal": value,
                    "ValueHex": f"0x{value:08X}"}
                   for key, value in first_header.items()])
        write_json(args.logs_dir / "validation-result.json", result)
        return 0 if result["result"] == "PASS" else 1
    except BaseException as exc:
        result = {"result": "FAIL", "blocker": str(exc) or type(exc).__name__,
                  "exception_type": type(exc).__name__}
        if not (args.logs_dir / "validation-result.json").exists():
            write_json(args.logs_dir / "validation-result.json", result)
        print(json.dumps(result, sort_keys=True), flush=True)
        return 1
    finally:
        if result:
            print(json.dumps(result, sort_keys=True), flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
