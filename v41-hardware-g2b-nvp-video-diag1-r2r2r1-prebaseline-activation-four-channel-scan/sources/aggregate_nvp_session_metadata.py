#!/usr/bin/env python3
"""Create sanitized DIAG1-R1 public metadata projections from durable host files.

This helper never parses camera bytes and never invents I2C transactions,
individual status samples, or NVP register operations.  Runtime projections
are accepted only when their granularity and retained-data limitations are
explicit; a summary row is never promoted into a physical transaction row.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import sys
import uuid
from typing import Any, Iterable


PREFIX = "G2B_NVP_VIDEO_DIAG1_R1_"
EXPECTED_SESSIONS = 16
ORDERS = ((1, 2, 3, 4), (4, 3, 2, 1), (2, 3, 4, 1), (3, 4, 1, 2))
MAX_TEXT_BYTES = 64 * 1024 * 1024
REPARSE_ATTRIBUTE = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)

CANONICAL_INPUTS = {
    "status_csv": "session_status_history.csv",
    "status_jsonl": "session_status_history.jsonl",
    "capture_csv": "session_capture_history.csv",
    "pixel_csv": "session_pixel_history.csv",
    "coherence_csv": "snapshot_coherence.csv",
    "scan_results_csv": "scan-results.csv",
}

RUNTIME_PROJECTION_INPUTS = {
    "status": (
        PREFIX + "STATUS_SAMPLES.csv",
        (
            "SessionID", "Round", "Channel", "Classification",
            "StableSamples", "TotalStatusSamples", "RawNOVID", "RawAGCLock",
            "RawComparatorLock", "RawHLock", "RawChannelStatus",
            "EquivalentConsecutiveSamplesProven", "RetainedRawSignatureCount",
            "IndividualRawSampleHistoryRetained", "IndividualSampleTimestamps",
            "EvidenceGranularity", "EvidenceSource", "Limitation",
        ),
    ),
    "i2c": (
        PREFIX + "I2C_TRANSACTION_LOG.csv",
        (
            "CheckpointOrder", "SessionID", "Round", "Channel", "Checkpoint",
            "HostTimestampNs", "AcceptedTransactionCount", "PriorCount",
            "AcceptedTransactionDelta", "NackCountEvidence",
            "TimeoutCountEvidence", "BusRecoveryCountEvidence", "CountBaseline",
            "EvidenceGranularity",
            "PerTransactionSequenceIDsRetained", "PerTransactionCommandsRetained",
            "PerTransactionTimestampsRetained", "EvidenceSource", "Limitation",
        ),
    ),
    "write": (
        PREFIX + "NVP_WRITE_LEDGER.csv",
        (
            "Order", "SessionID", "Round", "Channel", "LogicalOperation",
            "Bank", "Register", "Field", "RequestedFieldValue",
            "RequestedFullByte", "ReadbackFullByte", "ReadbackMatch",
            "PhysicalTransactionRecordRetained", "EvidenceGranularity",
            "EvidenceSource", "Limitation",
        ),
    ),
    "readback": (
        PREFIX + "NVP_READBACK_LEDGER.csv",
        (
            "Order", "SessionID", "Round", "Channel", "LogicalReadback",
            "Bank", "Register", "Field", "ReadbackValue",
            "EquivalentConsecutiveReadsProven",
            "PhysicalTransactionIDsRetained", "EvidenceGranularity",
            "EvidenceSource", "Limitation",
        ),
    ),
}

SESSION_REQUIRED_FIELDS = {
    "SessionID", "SnapshotGeneration", "Round", "Channel",
    "RouteRequested", "RouteReadback", "AssignedBGDCOL", "BGDCOL78",
    "BGDCOL79", "RawNOVID", "RawAGCLock", "RawComparatorLock",
    "RawHLock", "Classification", "StableSamples", "I2CTransactionCount",
    "CaptureResult", "FrameSequence", "FrameSHA256", "PixelClassification",
    "CleanupResult",
}

SECRET_PATTERNS = (
    re.compile(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----"),
    re.compile(r"(?i)authorization\s*:\s*bearer\s+[A-Za-z0-9._~+/=-]{8,}"),
    re.compile(r"\b(?:ghp|github_pat|glpat)-?[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(
        r"(?i)\b(?:password|passwd|api[_-]?key|access[_-]?token)\b\s*[:=]\s*"
        r"(?:['\"])?(?!REDACTED|NOT_AVAILABLE|NONE)[^\s,'\"]{8,}"
    ),
)


class EvidenceError(RuntimeError):
    """A fail-closed evidence or provenance violation."""


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def absolute(path: Path) -> Path:
    return Path(os.path.abspath(os.fspath(path)))


def is_reparse(path: Path) -> bool:
    info = path.lstat()
    return path.is_symlink() or bool(
        getattr(info, "st_file_attributes", 0) & REPARSE_ATTRIBUTE
    )


def require_safe_chain(root: Path, candidate: Path, *, must_exist: bool) -> Path:
    """Reject escapes and every symlink/junction/reparse point in the path."""
    root = absolute(root)
    candidate = absolute(candidate)
    try:
        inside = os.path.commonpath((os.fspath(root), os.fspath(candidate)))
    except ValueError as exc:
        raise EvidenceError(f"PATH_VOLUME_MISMATCH:{candidate}") from exc
    if os.path.normcase(inside) != os.path.normcase(os.fspath(root)):
        raise EvidenceError(f"PATH_OUTSIDE_TASK_ROOT:{candidate}")
    if not root.exists() or not root.is_dir() or is_reparse(root):
        raise EvidenceError(f"TASK_ROOT_NOT_SAFE_DIRECTORY:{root}")
    relative = candidate.relative_to(root)
    current = root
    for part in relative.parts:
        current = current / part
        if current.exists() or current.is_symlink():
            if is_reparse(current):
                raise EvidenceError(f"REPARSE_POINT_REFUSED:{current}")
        else:
            break
    if must_exist and not candidate.exists():
        raise EvidenceError(f"INPUT_MISSING:{candidate}")
    return candidate


def read_public_text(task_root: Path, path: Path) -> tuple[str, bytes]:
    path = require_safe_chain(task_root, path, must_exist=True)
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise EvidenceError(f"INPUT_NOT_REGULAR_FILE:{path}")
    if info.st_size > MAX_TEXT_BYTES:
        raise EvidenceError(f"TEXT_INPUT_TOO_LARGE:{path}:{info.st_size}")
    data = path.read_bytes()
    if b"\x00" in data:
        raise EvidenceError(f"BINARY_INPUT_REFUSED:{path}")
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise EvidenceError(f"NON_UTF8_INPUT_REFUSED:{path}") from exc
    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            raise EvidenceError(f"CREDENTIAL_PATTERN_REFUSED:{path}:{pattern.pattern}")
    return text, data


def csv_document(fields: list[str], rows: Iterable[dict[str, Any]]) -> bytes:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow({field: row.get(field, "") for field in fields})
    return stream.getvalue().encode("utf-8")


def jsonl_document(rows: Iterable[dict[str, Any]]) -> bytes:
    return ("".join(
        json.dumps(row, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        + "\n" for row in rows
    )).encode("utf-8")


def read_csv(task_root: Path, path: Path) -> tuple[list[str], list[dict[str, str]]]:
    text, _ = read_public_text(task_root, path)
    with io.StringIO(text, newline="") as handle:
        reader = csv.DictReader(handle)
        fields = list(reader.fieldnames or [])
        if not fields or any(not field for field in fields):
            raise EvidenceError(f"CSV_HEADER_INVALID:{path}")
        rows = list(reader)
    return fields, rows


def read_jsonl(task_root: Path, path: Path) -> list[dict[str, Any]]:
    text, _ = read_public_text(task_root, path)
    rows: list[dict[str, Any]] = []
    for number, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            raise EvidenceError(f"JSONL_BLANK_LINE:{path}:{number}")
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise EvidenceError(f"JSONL_PARSE_ERROR:{path}:{number}") from exc
        if not isinstance(row, dict):
            raise EvidenceError(f"JSONL_ROW_NOT_OBJECT:{path}:{number}")
        rows.append(row)
    return rows


def session_id(row: dict[str, Any], source: str) -> int:
    value = row.get(
        "SessionID",
        row.get("SessionId", row.get("session_id", row.get("ExpectedSession"))),
    )
    try:
        parsed = int(value)
    except (TypeError, ValueError) as exc:
        raise EvidenceError(f"SESSION_ID_INVALID:{source}:{value!r}") from exc
    if not 1 <= parsed <= EXPECTED_SESSIONS:
        raise EvidenceError(f"SESSION_ID_OUT_OF_RANGE:{source}:{parsed}")
    return parsed


def validate_unique_sessions(rows: list[dict[str, Any]], source: str) -> list[int]:
    ids = [session_id(row, source) for row in rows]
    if len(ids) != len(set(ids)):
        raise EvidenceError(f"DUPLICATE_SESSION_ROWS:{source}")
    return ids


def normalize_scalar(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def row_projection_equal(left: dict[str, Any], right: dict[str, Any], fields: set[str]) -> bool:
    return all(normalize_scalar(left.get(field)) == normalize_scalar(right.get(field))
               for field in fields)


def validate_history_set(
    status_rows: list[dict[str, Any]], json_rows: list[dict[str, Any]],
    capture_rows: list[dict[str, Any]], pixel_rows: list[dict[str, Any]],
    *, allow_partial: bool,
) -> None:
    collections = {
        "session_status_history.csv": status_rows,
        "session_status_history.jsonl": json_rows,
        "session_capture_history.csv": capture_rows,
        "session_pixel_history.csv": pixel_rows,
    }
    ids_by_source = {
        name: validate_unique_sessions(rows, name) for name, rows in collections.items()
    }
    canonical_ids = ids_by_source["session_status_history.csv"]
    for name, ids in ids_by_source.items():
        if ids != canonical_ids:
            raise EvidenceError(f"HOST_HISTORY_SESSION_ORDER_MISMATCH:{name}")
    if not allow_partial and canonical_ids != list(range(1, EXPECTED_SESSIONS + 1)):
        raise EvidenceError(
            f"HOST_HISTORY_NOT_COMPLETE:EXPECTED_16_ACTUAL_{len(canonical_ids)}"
        )
    if allow_partial and canonical_ids != list(range(1, len(canonical_ids) + 1)):
        raise EvidenceError("PARTIAL_HOST_HISTORY_IS_NOT_A_CONTIGUOUS_DURABLE_PREFIX")
    for row in status_rows:
        missing = SESSION_REQUIRED_FIELDS - set(row)
        if missing:
            raise EvidenceError("HOST_HISTORY_SCHEMA_MISSING:" + ",".join(sorted(missing)))
    for csv_row, json_row in zip(status_rows, json_rows):
        if not row_projection_equal(csv_row, json_row, SESSION_REQUIRED_FIELDS):
            raise EvidenceError(
                f"HOST_HISTORY_CSV_JSONL_MISMATCH:SESSION_{session_id(csv_row, 'status')}"
            )
    generations: list[int] = []
    pairs: set[tuple[int, int]] = set()
    for row in status_rows:
        sid = session_id(row, "status")
        try:
            generation = int(row["SnapshotGeneration"])
            round_number = int(row["Round"])
            channel = int(row["Channel"])
        except (TypeError, ValueError) as exc:
            raise EvidenceError(f"HOST_HISTORY_NUMERIC_FIELD_INVALID:SESSION_{sid}") from exc
        if not (1 <= round_number <= 4 and 1 <= channel <= 4):
            raise EvidenceError(f"ROUND_CHANNEL_OUT_OF_RANGE:SESSION_{sid}")
        expected_round = (sid - 1) // 4 + 1
        expected_channel = ORDERS[expected_round - 1][(sid - 1) % 4]
        if (round_number, channel) != (expected_round, expected_channel):
            raise EvidenceError(f"ROUND_CHANNEL_ORDER_MISMATCH:SESSION_{sid}")
        if (round_number, channel) in pairs:
            raise EvidenceError(f"DUPLICATE_ROUND_CHANNEL:SESSION_{sid}")
        pairs.add((round_number, channel))
        generations.append(generation)
    if any(current <= previous for previous, current in zip(generations, generations[1:])):
        raise EvidenceError("SNAPSHOT_GENERATION_NOT_STRICTLY_MONOTONIC")


def require_session_alignment(
    rows: list[dict[str, Any]], expected_ids: list[int], source: str,
    *, allow_multiple: bool = False,
) -> None:
    ids = [session_id(row, source) for row in rows]
    if allow_multiple:
        if any(item not in expected_ids for item in ids):
            raise EvidenceError(f"UNMATCHED_SESSION_REFERENCE:{source}")
    elif ids != expected_ids:
        raise EvidenceError(f"SESSION_ALIGNMENT_MISMATCH:{source}")


def aggregate_documents(
    task_root: Path, logs_root: Path, runtime_projection_root: Path,
    projection_overrides: dict[str, Path | None],
    *, allow_partial: bool,
) -> tuple[dict[str, bytes], list[str], dict[str, Any]]:
    missing: list[str] = []
    csv_inputs: dict[str, tuple[list[str], list[dict[str, str]]]] = {}
    json_rows: list[dict[str, Any]] | None = None
    for key, name in CANONICAL_INPUTS.items():
        path = logs_root / name
        try:
            if key == "status_jsonl":
                json_rows = read_jsonl(task_root, path)
            else:
                csv_inputs[key] = read_csv(task_root, path)
        except EvidenceError as exc:
            if str(exc).startswith("INPUT_MISSING:"):
                missing.append(os.fspath(path))
            else:
                raise

    documents: dict[str, bytes] = {}
    session_count = 0
    expected_ids: list[int] = []
    if not missing:
        assert json_rows is not None
        status_fields, status_rows = csv_inputs["status_csv"]
        capture_fields, capture_rows = csv_inputs["capture_csv"]
        pixel_fields, pixel_rows = csv_inputs["pixel_csv"]
        coherence_fields, coherence_rows = csv_inputs["coherence_csv"]
        scan_fields, scan_rows = csv_inputs["scan_results_csv"]
        validate_history_set(status_rows, json_rows, capture_rows, pixel_rows,
                             allow_partial=allow_partial)
        expected_ids = [session_id(row, "status") for row in status_rows]
        require_session_alignment(scan_rows, expected_ids, "scan-results.csv")
        require_session_alignment(
            coherence_rows, expected_ids, "snapshot_coherence.csv", allow_multiple=True
        )
        session_count = len(expected_ids)

        documents[PREFIX + "HOST_SESSION_HISTORY.csv"] = csv_document(
            status_fields, status_rows
        )
        documents[PREFIX + "HOST_SESSION_HISTORY.jsonl"] = jsonl_document(json_rows)
        documents[PREFIX + "SNAPSHOT_COHERENCE.csv"] = csv_document(
            coherence_fields, coherence_rows
        )
        documents[PREFIX + "SCAN_RESULTS.csv"] = csv_document(scan_fields, scan_rows)
        documents[PREFIX + "CAPTURE_RESULTS.csv"] = csv_document(
            capture_fields, capture_rows
        )
        documents[PREFIX + "PIXEL_STATISTICS.csv"] = csv_document(
            pixel_fields, pixel_rows
        )

        capture_index_fields = [
            "SessionID", "Round", "Channel", "CaptureResult", "CaptureBlocker",
            "PrimaryBytes", "FrameReconstruction", "FrameSequence", "FrameSHA256",
            "PNG_SHA256", "PixelClassification", "CleanupResult",
        ]
        documents[PREFIX + "CAPTURE_INDEX.csv"] = csv_document(
            capture_index_fields, capture_rows
        )
        frame_fields = [
            "SessionID", "Round", "Channel", "FrameSequence", "FrameSHA256",
            "PNG_SHA256", "PixelClassification",
        ]
        documents[PREFIX + "FRAME_HASHES.csv"] = csv_document(frame_fields, pixel_rows)
        bgcolor_fields = [
            "SessionID", "Round", "Channel", "AssignedBGDCOL", "BGDCOLCode",
            "BGDCOL78", "BGDCOL79", "DominantUYVY", "DominantFraction",
            "PixelClassification", "AssignedColorPixelMatch", "FrameSHA256",
        ]
        documents[PREFIX + "BGDCOL_MATCH_RESULTS.csv"] = csv_document(
            bgcolor_fields, pixel_rows
        )

        repeatability_fields = [
            "Channel", "ObservedSessions", "ObservedRounds", "Classifications",
            "RouteReadbackPasses", "AssignedBGDCOLValues", "PixelClassifications",
            "DistinctFrameSHA256", "CapturePasses", "CleanupPasses",
        ]
        repeatability_rows: list[dict[str, Any]] = []
        for channel in range(1, 5):
            rows = [row for row in pixel_rows if int(row.get("Channel", 0)) == channel]
            def values(field: str) -> str:
                return ";".join(sorted({str(row.get(field, "")) for row in rows
                                        if str(row.get(field, ""))}))
            route_passes = sum(
                normalize_scalar(row.get("RouteRequested")) ==
                normalize_scalar(row.get("RouteReadback")) for row in rows
            )
            repeatability_rows.append({
                "Channel": channel,
                "ObservedSessions": len(rows),
                "ObservedRounds": values("Round"),
                "Classifications": values("Classification"),
                "RouteReadbackPasses": route_passes,
                "AssignedBGDCOLValues": values("AssignedBGDCOL"),
                "PixelClassifications": values("PixelClassification"),
                "DistinctFrameSHA256": len({str(row.get("FrameSHA256", ""))
                                             for row in rows
                                             if re.fullmatch(r"[0-9A-Fa-f]{64}",
                                                             str(row.get("FrameSHA256", "")))}),
                "CapturePasses": sum(row.get("CaptureResult") == "PASS" for row in rows),
                "CleanupPasses": sum(row.get("CleanupResult") == "PASS" for row in rows),
            })
        documents[PREFIX + "CHANNEL_REPEATABILITY.csv"] = csv_document(
            repeatability_fields, repeatability_rows
        )

    copied_projections: dict[str, int] = {}
    missing_projections: list[str] = []
    for key, (output_name, expected_fields) in RUNTIME_PROJECTION_INPUTS.items():
        source = projection_overrides.get(key) or (runtime_projection_root / output_name)
        try:
            fields, rows = read_csv(task_root, source)
        except EvidenceError as exc:
            if str(exc).startswith("INPUT_MISSING:"):
                missing_projections.append(output_name)
                continue
            raise
        if fields != list(expected_fields):
            absent = set(expected_fields) - set(fields)
            extra = set(fields) - set(expected_fields)
            raise EvidenceError(
                f"RUNTIME_PROJECTION_SCHEMA_MISMATCH:{source}:MISSING=" +
                ",".join(sorted(absent)) + ":EXTRA=" + ",".join(sorted(extra))
            )
        if not rows and not allow_partial:
            raise EvidenceError(f"RUNTIME_PROJECTION_HAS_NO_REAL_ROWS:{source}")
        for number, row in enumerate(rows, 1):
            if not row.get("EvidenceSource") or not row.get("Limitation"):
                raise EvidenceError(
                    f"RUNTIME_PROJECTION_GRANULARITY_DISCLOSURE_MISSING:{source}:{number}"
                )
            if key == "status":
                if (row.get("EvidenceGranularity") !=
                        "SESSION_FINAL_STABLE_SIGNATURE_SUMMARY" or
                        row.get("IndividualRawSampleHistoryRetained") != "NO" or
                        row.get("IndividualSampleTimestamps") != "NOT_AVAILABLE"):
                    raise EvidenceError(
                        f"STATUS_PROJECTION_OVERCLAIM_REFUSED:{source}:{number}"
                    )
            elif key == "i2c":
                if (row.get("EvidenceGranularity") !=
                        "CUMULATIVE_ACCEPTED_COMMAND_INTERVAL_SUMMARY" or
                        any(row.get(field) != "NO" for field in (
                            "PerTransactionSequenceIDsRetained",
                            "PerTransactionCommandsRetained",
                            "PerTransactionTimestampsRetained",
                        ))):
                    raise EvidenceError(
                        f"I2C_TRANSACTION_LEVEL_OVERCLAIM_REFUSED:{source}:{number}"
                    )
            elif key == "write":
                if (row.get("EvidenceGranularity") !=
                        "LOGICAL_OPERATION_WITH_READBACK_RECEIPT" or
                        row.get("PhysicalTransactionRecordRetained") != "NO"):
                    raise EvidenceError(
                        f"NVP_WRITE_TRANSACTION_LEVEL_OVERCLAIM_REFUSED:{source}:{number}"
                    )
            elif (row.get("PhysicalTransactionIDsRetained") != "NO" or
                  row.get("EvidenceGranularity") not in {
                      "FINAL_STABLE_VALUE_OR_READBACK_RECEIPT",
                      "FINAL_VALUE_PLUS_CONSECUTIVE_EQUIVALENCE_COUNT",
                  }):
                raise EvidenceError(
                    f"NVP_READBACK_TRANSACTION_LEVEL_OVERCLAIM_REFUSED:{source}:{number}"
                )
        if key == "status":
            require_session_alignment(rows, expected_ids, os.fspath(source))
        elif key == "i2c" and not allow_partial:
            if len(rows) != session_count + 1:
                raise EvidenceError(
                    f"I2C_INTERVAL_PROJECTION_COUNT_INVALID:{source}:"
                    f"EXPECTED_{session_count + 1}_ACTUAL_{len(rows)}"
                )
            interval_ids = [session_id(row, os.fspath(source))
                            for row in rows[:session_count]]
            if interval_ids != expected_ids or rows[-1].get("Checkpoint") != "FINAL_AFTER_RESTORE":
                raise EvidenceError(f"I2C_INTERVAL_PROJECTION_SEQUENCE_INVALID:{source}")
        elif key == "write" and not allow_partial and len(rows) != 27:
            raise EvidenceError(
                f"LOGICAL_WRITE_PROJECTION_COUNT_INVALID:{source}:EXPECTED_27_ACTUAL_{len(rows)}"
            )
        elif key == "readback" and not allow_partial and len(rows) != 107:
            raise EvidenceError(
                f"READBACK_PROJECTION_COUNT_INVALID:{source}:EXPECTED_107_ACTUAL_{len(rows)}"
            )
        documents[output_name] = csv_document(fields, rows)
        copied_projections[output_name] = len(rows)

    missing.extend(missing_projections)
    summary = {
        "session_count": session_count,
        "expected_sessions": EXPECTED_SESSIONS,
        "runtime_projections_copied": copied_projections,
        "runtime_projections_unavailable": missing_projections,
        "transaction_rows_synthesized": 0,
        "individual_status_sample_rows_synthesized": 0,
    }
    return documents, missing, summary


def write_documents(
    task_root: Path, output_root: Path, documents: dict[str, bytes], *, replace: bool,
) -> list[dict[str, Any]]:
    output_root = require_safe_chain(task_root, output_root, must_exist=False)
    output_root.mkdir(parents=True, exist_ok=True)
    require_safe_chain(task_root, output_root, must_exist=True)
    targets = [output_root / name for name in documents]
    existing = [path for path in targets if path.exists() or path.is_symlink()]
    if existing and not replace:
        raise EvidenceError(f"OUTPUT_EXISTS_REFUSED:{existing[0]}")
    temporary: list[tuple[Path, Path]] = []
    try:
        for target in targets:
            require_safe_chain(task_root, target, must_exist=False)
            temp = output_root / f".{target.name}.{uuid.uuid4().hex}.tmp"
            with temp.open("xb") as handle:
                handle.write(documents[target.name])
                handle.flush()
                os.fsync(handle.fileno())
            temporary.append((temp, target))
        for temp, target in temporary:
            os.replace(temp, target)
    finally:
        for temp, _ in temporary:
            if temp.exists() and not is_reparse(temp):
                temp.unlink()
    return [
        {"path": os.fspath(path), "bytes": len(documents[path.name]),
         "sha256": sha256_bytes(documents[path.name])}
        for path in sorted(targets, key=lambda item: item.name)
    ]


def main() -> int:
    script_root = Path(__file__).resolve().parent
    default_task_root = script_root.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task-root", type=Path, default=default_task_root)
    parser.add_argument("--logs-root", type=Path)
    parser.add_argument("--output-root", type=Path)
    parser.add_argument("--runtime-projection-root", type=Path,
                        help="output directory populated by extract_nvp_runtime_evidence.py")
    parser.add_argument("--status-samples-projection", type=Path)
    parser.add_argument("--i2c-transaction-log", type=Path)
    parser.add_argument("--nvp-write-ledger", type=Path)
    parser.add_argument("--nvp-readback-ledger", type=Path)
    parser.add_argument("--allow-partial", action="store_true",
                        help="preserve only durable rows after a failed/incomplete scan")
    parser.add_argument("--replace", action="store_true",
                        help="atomically replace only this helper's exact output files")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    task_root = absolute(args.task_root)
    logs_root = absolute(args.logs_root or (task_root / "logs"))
    output_root = absolute(args.output_root or
                           (task_root / "evidence-staging" / "required"))
    runtime_projection_root = absolute(
        args.runtime_projection_root or (task_root / "logs" / "runtime-evidence")
    )
    overrides = {
        "status": (absolute(args.status_samples_projection)
                   if args.status_samples_projection else None),
        "i2c": absolute(args.i2c_transaction_log) if args.i2c_transaction_log else None,
        "write": absolute(args.nvp_write_ledger) if args.nvp_write_ledger else None,
        "readback": absolute(args.nvp_readback_ledger) if args.nvp_readback_ledger else None,
    }
    try:
        require_safe_chain(task_root, logs_root, must_exist=True)
        require_safe_chain(task_root, output_root, must_exist=False)
        require_safe_chain(task_root, runtime_projection_root, must_exist=False)
        for override in overrides.values():
            if override is not None:
                require_safe_chain(task_root, override, must_exist=True)
        documents, missing, summary = aggregate_documents(
            task_root, logs_root, runtime_projection_root, overrides,
            allow_partial=args.allow_partial
        )
        if missing and not args.allow_partial and not args.dry_run:
            raise EvidenceError("REQUIRED_REAL_METADATA_UNAVAILABLE:" + "|".join(missing))
        written: list[dict[str, Any]] = []
        if not args.dry_run:
            written = write_documents(task_root, output_root, documents,
                                      replace=args.replace)
        result = {
            "result": ("PASS" if not missing else
                       "DRY_RUN_BLOCKED" if args.dry_run else "PARTIAL"),
            "dry_run": args.dry_run,
            "allow_partial": args.allow_partial,
            "task_root": os.fspath(task_root),
            "logs_root": os.fspath(logs_root),
            "output_root": os.fspath(output_root),
            "runtime_projection_root": os.fspath(runtime_projection_root),
            "documents_ready": sorted(documents),
            "missing_real_inputs_or_outputs": missing,
            "written": written,
            **summary,
        }
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0
    except EvidenceError as exc:
        print(json.dumps({"result": "FAIL", "error": str(exc)}, indent=2),
              file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
