#!/usr/bin/env python3
"""Disk-based R3R4R6 integrity, continuity, source, DMA and frame validator."""

from __future__ import annotations

import argparse
import binascii
import csv
import hashlib
import json
import os
from pathlib import Path
import struct
import sys
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parent))
from abi_v1 import AbiContract, RecordValidationError, parse_record  # noqa: E402

TASK = "G2B-HW0-PRODUCT-R3R4R6"
RECORD_BYTES = 4096
PRIMARY_RECORDS = 2500
PRIMARY_BYTES = 10_240_000
PAYLOAD_FIRST = 64
PAYLOAD_BYTES = 3840
PADDING_FIRST = 3904
LINES_PER_FRAME = 1080
U32_MASK = 0xFFFFFFFF


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def persist_exclusive(path: Path, data: bytes) -> None:
    with path.open("xb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())


def write_json(path: Path, value: object) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({name: row.get(name, "") for name in fields})
        handle.flush()
        os.fsync(handle.fileno())


def u32_next(value: int) -> int:
    return (value + 1) & U32_MASK


def u32_delta(after: int, before: int) -> int:
    return (after - before) & U32_MASK


def continuity_bits(contract: AbiContract, flags: int) -> dict[str, bool]:
    return {
        "discontinuity": bool(flags & contract.flags["DISCONTINUITY"]),
        "overflow": bool(flags & contract.flags["OVERFLOW_OCCURRED"]),
        "malformed_preceding": bool(
            flags & contract.flags["MALFORMED_PRECEDING"]),
    }


def first_continuity_class(bits: dict[str, bool]) -> str:
    active = [name for name, value in bits.items() if value]
    if not active:
        return "CLEAN"
    if len(active) > 1:
        return "MULTIPLE_EVENTS"
    return {
        "discontinuity": "DISCONTINUITY",
        "overflow": "OVERFLOW",
        "malformed_preceding": "MALFORMED_PRECEDING",
    }[active[0]]


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return (struct.pack(">I", len(payload)) + kind + payload +
            struct.pack(">I", binascii.crc32(kind + payload) & U32_MASK))


def uyvy_to_png(uyvy: bytes, width: int, height: int, path: Path) -> None:
    expected = width * height * 2
    if len(uyvy) != expected:
        raise ValueError(f"UYVY size {len(uyvy)} is not {expected}")
    scanlines = bytearray()

    def clamp(value: int) -> int:
        return 0 if value < 0 else 255 if value > 255 else value

    for line in range(height):
        scanlines.append(0)
        row = uyvy[line * width * 2:(line + 1) * width * 2]
        for offset in range(0, len(row), 4):
            u, y0, v, y1 = row[offset:offset + 4]
            for y in (y0, y1):
                c = max(0, y - 16)
                d = u - 128
                e = v - 128
                scanlines.extend((
                    clamp((298 * c + 409 * e + 128) >> 8),
                    clamp((298 * c - 100 * d - 208 * e + 128) >> 8),
                    clamp((298 * c + 516 * d + 128) >> 8),
                ))
    png = (b"\x89PNG\r\n\x1a\n" +
           png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height,
                                           8, 2, 0, 0, 0)) +
           png_chunk(b"IDAT", zlib.compress(bytes(scanlines), 9)) +
           png_chunk(b"IEND", b""))
    persist_exclusive(path, png)


def clean_flags(bits: dict[str, bool]) -> bool:
    return not any(bits.values())


def transition_ok(previous: dict, current: dict) -> bool:
    if current["epoch"] != previous["epoch"]:
        return False
    if current["global_sequence"] != u32_next(previous["global_sequence"]):
        return False
    if current["attempt_sequence"] != u32_next(previous["attempt_sequence"]):
        return False
    if current["capture_sequence"] != u32_next(previous["capture_sequence"]):
        return False
    if previous["line"] == LINES_PER_FRAME - 1:
        return (current["line"] == 0 and
                current["frame"] == u32_next(previous["frame"]))
    return (current["line"] == previous["line"] + 1 and
            current["frame"] == previous["frame"])


def find_qualified_frame(records: list[dict]) -> tuple[int, int] | None:
    for start in range(0, len(records) - LINES_PER_FRAME + 1):
        first = records[start]
        if (not first["integrity"] or first["line"] != 0 or
                not first["sof"] or not clean_flags(first["continuity"])):
            continue
        epoch = first["epoch"]
        frame = first["frame"]
        good = True
        for relative in range(LINES_PER_FRAME):
            item = records[start + relative]
            if (not item["integrity"] or item["epoch"] != epoch or
                    item["frame"] != frame or item["line"] != relative or
                    not clean_flags(item["continuity"])):
                good = False
                break
            if relative and not transition_ok(records[start + relative - 1], item):
                good = False
                break
        if good:
            return start, start + LINES_PER_FRAME - 1
    return None


def run(args: argparse.Namespace) -> dict:
    primary_path = Path(args.primary)
    guard_path = Path(args.guard)
    private = Path(args.private_dir)
    logs = Path(args.logs_dir)
    controller = json.loads(Path(args.controller_result).read_text())
    native = json.loads(Path(args.native_metadata).read_text())
    contract = AbiContract.load(Path(args.abi))
    primary_size = primary_path.stat().st_size
    guard_size = guard_path.stat().st_size
    primary = primary_path.read_bytes()
    if primary_size != len(primary):
        raise RuntimeError("R3R4R6_PRIMARY_REREAD_SIZE_CHANGED")

    records: list[dict] = []
    metadata_rows: list[dict] = []
    integrity_failures = 0
    structural_header_failures = 0
    payload_geometry_failures = 0
    padding_errors = 0
    discontinuity_indices: list[int] = []
    overflow_indices: list[int] = []
    malformed_indices: list[int] = []

    record_count = primary_size // RECORD_BYTES
    for index in range(record_count):
        blob = primary[index * RECORD_BYTES:(index + 1) * RECORD_BYTES]
        header = contract.unpack_header(blob)
        errors: list[str] = []
        try:
            parsed = parse_record(contract, blob)
        except RecordValidationError as exc:
            parsed = None
            errors.extend(exc.errors)
        if header["logical_channel_id"] != 0:
            errors.append("logical channel is not 0")
        if header["physical_input_id"] != 0:
            errors.append("physical input is not 0")
        if header["active_logical_channel_count"] != 1:
            errors.append("active logical channel count is not 1")
        errors = list(dict.fromkeys(errors))
        integrity = not errors and parsed is not None
        if not integrity:
            integrity_failures += 1
        payload_failed = any("payload" in error for error in errors)
        padding_failed = any("padding" in error for error in errors)
        header_failed = any("padding" not in error and "payload" not in error
                            for error in errors)
        payload_geometry_failures += int(payload_failed)
        padding_errors += int(padding_failed)
        structural_header_failures += int(header_failed)
        flags = header["flags"]
        bits = continuity_bits(contract, flags)
        if bits["discontinuity"]:
            discontinuity_indices.append(index)
        if bits["overflow"]:
            overflow_indices.append(index)
        if bits["malformed_preceding"]:
            malformed_indices.append(index)
        item = {
            "index": index,
            "integrity": integrity,
            "errors": errors,
            "flags": flags,
            "sof": bool(flags & contract.flags["SOF"]),
            "continuity": bits,
            "epoch": header["reset_epoch"],
            "frame": header["source_frame_sequence"],
            "line": header["source_line_sequence"],
            "capture_sequence": header["source_capture_sequence"],
            "attempt_sequence": header["channel_attempt_sequence"],
            "global_sequence": header["global_stream_sequence"],
            "source_malformed_snapshot":
                header["source_malformed_count_snapshot"],
            "source_dropped_snapshot": header["source_dropped_count_snapshot"],
        }
        records.append(item)
        metadata_rows.append({
            "RecordIndex": index,
            "Integrity": "PASS" if integrity else "FAIL",
            "Flags": f"0x{flags:08X}", "Epoch": item["epoch"],
            "Frame": item["frame"], "Line": item["line"],
            "CaptureSequence": item["capture_sequence"],
            "AttemptSequence": item["attempt_sequence"],
            "GlobalSequence": item["global_sequence"],
            "SourceMalformedSnapshot": item["source_malformed_snapshot"],
            "SourceDroppedSnapshot": item["source_dropped_snapshot"],
            "Errors": ";".join(errors),
        })

    integral = [item for item in records if item["integrity"]]
    global_gaps = 0
    attempt_gaps = 0
    source_breaks = 0
    for previous, current in zip(integral, integral[1:]):
        global_gaps += int(current["global_sequence"] !=
                           u32_next(previous["global_sequence"]))
        attempt_gaps += int(current["attempt_sequence"] !=
                            u32_next(previous["attempt_sequence"]))
        expected_source = (
            current["capture_sequence"] == u32_next(previous["capture_sequence"])
            and current["epoch"] == previous["epoch"])
        if previous["line"] == LINES_PER_FRAME - 1:
            expected_source &= (current["line"] == 0 and
                                current["frame"] == u32_next(previous["frame"]))
        else:
            expected_source &= (current["line"] == previous["line"] + 1 and
                                current["frame"] == previous["frame"])
        source_breaks += int(not expected_source)

    frame_range = find_qualified_frame(records)
    clean_sof_indices = [item["index"] for item in records
                         if item["integrity"] and item["line"] == 0 and
                         item["sof"] and clean_flags(item["continuity"])]
    first_clean_sof = clean_sof_indices[0] if clean_sof_indices else None

    first_integral = integral[0] if integral else None
    last_integral = integral[-1] if integral else None
    malformed_first_snapshot = (first_integral["source_malformed_snapshot"]
                                if first_integral else None)
    malformed_last_snapshot = (last_integral["source_malformed_snapshot"]
                               if last_integral else None)
    malformed_delta = (u32_delta(malformed_last_snapshot,
                                 malformed_first_snapshot)
                       if first_integral and last_integral else None)
    if not malformed_indices and malformed_delta == 0:
        source_classification = "PASS"
    else:
        post_clean_occurrence = (first_clean_sof is None or
                                 any(index >= first_clean_sof
                                     for index in malformed_indices))
        if first_clean_sof is not None:
            clean_snapshot = records[first_clean_sof]["source_malformed_snapshot"]
            post_clean_delta = u32_delta(malformed_last_snapshot, clean_snapshot)
        else:
            post_clean_delta = None
        if (malformed_indices and not post_clean_occurrence and
                post_clean_delta == 0):
            source_classification = "PASS_WITH_INITIAL_TRANSITION"
        else:
            source_classification = "OPEN_RECURRING_BT656_QUALIFICATION_EVENT"

    malformed_rows = []
    for index in malformed_indices:
        item = records[index]
        malformed_rows.append({
            "RecordIndex": index, "Epoch": item["epoch"],
            "Frame": item["frame"], "Line": item["line"],
            "Flags": f"0x{item['flags']:08X}",
            "SourceMalformedSnapshot": item["source_malformed_snapshot"],
            "SourceDroppedSnapshot": item["source_dropped_snapshot"],
            "GlobalSequence": item["global_sequence"],
            "AttemptSequence": item["attempt_sequence"],
            "BeforeCleanSOF": (first_clean_sof is None or index < first_clean_sof),
            "InsideQualifiedFrame": (frame_range is not None and
                                      frame_range[0] <= index <= frame_range[1]),
        })

    first_blob = primary[:RECORD_BYTES] if primary_size >= RECORD_BYTES else b""
    first_payload = first_blob[PAYLOAD_FIRST:PAYLOAD_FIRST + PAYLOAD_BYTES]
    first_record_path = private / "first-record.bin"
    first_payload_path = private / "first-payload.bin"
    if first_blob:
        persist_exclusive(first_record_path, first_blob)
        persist_exclusive(first_payload_path, first_payload)
    first = records[0] if records else None

    frame_result: dict = {"result": "NOT_REACHED"}
    if frame_range is not None:
        first_index, last_index = frame_range
        uyvy = b"".join(
            primary[index * RECORD_BYTES + PAYLOAD_FIRST:
                    index * RECORD_BYTES + PAYLOAD_FIRST + PAYLOAD_BYTES]
            for index in range(first_index, last_index + 1))
        raw_frame = private / "qualified-frame.uyvy"
        png_frame = private / "qualified-frame.png"
        persist_exclusive(raw_frame, uyvy)
        uyvy_to_png(uyvy, 1920, 1080, png_frame)
        frame_result = {
            "result": "PASS", "epoch": records[first_index]["epoch"],
            "frame_sequence": records[first_index]["frame"],
            "first_record": first_index, "last_record": last_index,
            "raw_bytes": len(uyvy), "geometry": "1920x1080 UYVY",
            "raw_sha256": sha256_file(raw_frame),
            "png_sha256": sha256_file(png_frame),
        }

    primary_result = int(native["primary_result_bytes"])
    guard_result = int(native["guard_result"])
    primary_returned = max(0, primary_result)
    guard_returned = max(0, guard_result)
    host_complete_records = (primary_returned // RECORD_BYTES +
                             guard_returned // RECORD_BYTES)
    host_complete_record_bytes = host_complete_records * RECORD_BYTES
    host_partial_bytes = (primary_returned % RECORD_BYTES +
                          guard_returned % RECORD_BYTES)
    host_returned_bytes = host_complete_record_bytes + host_partial_bytes
    host_returned_beats = (host_returned_bytes + 7) // 8
    deltas = controller["counter_deltas"]
    fpga_streamed_beats = int(deltas["beats"])
    fpga_streamed_bytes = fpga_streamed_beats * 8
    unreaped_dma_bytes = fpga_streamed_bytes - host_returned_bytes
    unreaped_dma_beats = ((unreaped_dma_bytes + 7) // 8
                          if unreaped_dma_bytes >= 0 else None)
    if unreaped_dma_bytes < 0 or unreaped_dma_bytes >= RECORD_BYTES:
        dma_accounting = "FAIL"
    elif unreaped_dma_bytes == 0:
        dma_accounting = "CLEAN"
    else:
        dma_accounting = "BOUNDED_SHUTDOWN_REMAINDER"

    first_prediction = "NOT_REACHED"
    if first is not None:
        first_prediction = (
            "MATCH" if (first["integrity"] and not first["continuity"]["overflow"]
                        and not first["continuity"]["malformed_preceding"])
            else "DEVIATION")
    post_first_prediction = "NOT_REACHED" if len(records) < 2 else (
        "MATCH" if all(clean_flags(item["continuity"])
                       for item in records[1:]) else "DEVIATION")
    clean_frame_prediction = "MATCH" if frame_range else "DEVIATION"

    record_path_integrity = (
        "PASS" if record_count == PRIMARY_RECORDS and integrity_failures == 0
        else "FAIL")
    finite_prequeued = (
        "PASS" if (primary_result == PRIMARY_BYTES and
                   record_count == PRIMARY_RECORDS and integrity_failures == 0 and
                   deltas["dropped"] == 0 and deltas["overflow"] == 0 and
                   not overflow_indices and
                   controller.get("prequeue_ready") and
                   controller["prequeue_ready"]["monotonic_ns"] <
                   controller["primary_completion"]["monotonic_ns"])
        else "FAIL")
    stream_continuity = "PASS" if frame_range is not None else "FAIL"
    complete_frame = "PASS" if frame_range is not None else "FAIL"
    s3_error = int(controller["S3"]["ErrorStatus"])
    all_core = (record_path_integrity == "PASS" and finite_prequeued == "PASS" and
                stream_continuity == "PASS" and complete_frame == "PASS" and
                s3_error == 0 and dma_accounting != "FAIL")
    if not all_core:
        overall = "FAIL"
    elif source_classification == "OPEN_RECURRING_BT656_QUALIFICATION_EVENT":
        overall = "PASS_WITH_BT656_DIAGNOSTIC_OPEN"
    elif dma_accounting == "BOUNDED_SHUTDOWN_REMAINDER":
        overall = "PASS_WITH_BOUNDED_SHUTDOWN_REMAINDER"
    else:
        overall = "PASS"

    result = {
        "schema": "R3R4R6_VALIDATION_RESULT_V1", "task": TASK,
        "result": overall,
        "primary_records": record_count, "primary_bytes": primary_size,
        "primary_sha256": sha256_file(primary_path),
        "guard_returned_bytes": guard_size,
        "guard_returned_sha256": sha256_file(guard_path),
        "first_record_bytes": len(first_blob),
        "first_record_sha256": (sha256_file(first_record_path)
                                if first_blob else None),
        "first_payload_sha256": (sha256_file(first_payload_path)
                                 if first_blob else None),
        "first_record_integrity": ("PASS" if first and first["integrity"]
                                   else "FAIL" if first else "NOT_REACHED"),
        "first_record_continuity": (first_continuity_class(first["continuity"])
                                    if first else "NOT_REACHED"),
        "first_record_flags": (f"0x{first['flags']:08X}" if first else None),
        "record_integrity_failures": integrity_failures,
        "structural_header_failures": structural_header_failures,
        "payload_geometry_failures": payload_geometry_failures,
        "padding_errors": padding_errors,
        "discontinuity_flag_records": len(discontinuity_indices),
        "discontinuity_indices": discontinuity_indices,
        "overflow_flag_records": len(overflow_indices),
        "overflow_indices": overflow_indices,
        "malformed_preceding_flag_records": len(malformed_indices),
        "malformed_preceding_indices": malformed_indices,
        "first_malformed_preceding_record": (malformed_indices[0]
                                             if malformed_indices else None),
        "last_malformed_preceding_record": (malformed_indices[-1]
                                            if malformed_indices else None),
        "source_malformed_snapshot_first": malformed_first_snapshot,
        "source_malformed_snapshot_last": malformed_last_snapshot,
        "source_malformed_snapshot_delta": malformed_delta,
        "bt656_source_qualification": source_classification,
        "first_clean_sof_index": first_clean_sof,
        "first_record_prediction": first_prediction,
        "post_first_record_prediction": post_first_prediction,
        "clean_frame_prediction": clean_frame_prediction,
        "global_sequence_gaps": global_gaps,
        "attempt_sequence_gaps": attempt_gaps,
        "source_progression_breaks": source_breaks,
        "frame": frame_result,
        "record_path_integrity": record_path_integrity,
        "finite_prequeued_capture": finite_prequeued,
        "stream_continuity": stream_continuity,
        "complete_frame": complete_frame,
        "host_dma_accounting": {
            "primary_returned_bytes": primary_returned,
            "guard_returned_bytes": guard_returned,
            "host_complete_records": host_complete_records,
            "host_complete_record_bytes": host_complete_record_bytes,
            "host_partial_bytes": host_partial_bytes,
            "host_returned_bytes": host_returned_bytes,
            "host_returned_beats": host_returned_beats,
            "fpga_streamed_beats": fpga_streamed_beats,
            "fpga_streamed_bytes": fpga_streamed_bytes,
            "unreaped_dma_bytes": unreaped_dma_bytes,
            "unreaped_dma_beats": unreaped_dma_beats,
            "classification": dma_accounting,
        },
        "s3_error_status": s3_error,
        "s3_last_error_cause": controller["S3"]["LastErrorCause"],
    }
    write_csv(logs / "record-metadata.csv",
              ["RecordIndex", "Integrity", "Flags", "Epoch", "Frame", "Line",
               "CaptureSequence", "AttemptSequence", "GlobalSequence",
               "SourceMalformedSnapshot", "SourceDroppedSnapshot", "Errors"],
              metadata_rows)
    write_csv(logs / "malformed-preceding-timeline.csv",
              ["RecordIndex", "Epoch", "Frame", "Line", "Flags",
               "SourceMalformedSnapshot", "SourceDroppedSnapshot",
               "GlobalSequence", "AttemptSequence", "BeforeCleanSOF",
               "InsideQualifiedFrame"], malformed_rows)
    if first:
        header = contract.unpack_header(first_blob)
        write_csv(logs / "first-record-header.csv", ["Field", "Value"],
                  [{"Field": key, "Value": f"0x{value:08X}"}
                   for key, value in header.items()])
    write_json(logs / "validation-result.json", result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--primary", required=True)
    parser.add_argument("--guard", required=True)
    parser.add_argument("--private-dir", required=True)
    parser.add_argument("--logs-dir", required=True)
    parser.add_argument("--controller-result", required=True)
    parser.add_argument("--native-metadata", required=True)
    parser.add_argument("--abi", required=True)
    args = parser.parse_args()
    result = run(args)
    print(json.dumps({
        "task": TASK, "result": result["result"],
        "primary_records": result["primary_records"],
        "record_integrity_failures": result["record_integrity_failures"],
        "finite_prequeued_capture": result["finite_prequeued_capture"],
        "frame": result["frame"]["result"],
    }, sort_keys=True))
    return 0 if result["result"].startswith("PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
