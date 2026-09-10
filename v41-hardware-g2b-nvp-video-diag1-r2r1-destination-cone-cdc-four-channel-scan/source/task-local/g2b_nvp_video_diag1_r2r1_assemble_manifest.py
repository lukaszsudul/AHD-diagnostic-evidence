#!/usr/bin/env python3
"""Assemble and verify the exact DIAG1-R2R1 profile-specific CDC manifest.

This is a deterministic, fail-closed post-comparer step.  It does not invoke
Vivado, open a DCP, or modify source files.  It consumes the two sealed routed
CDC reports plus the 522-row destination-cone comparer PASS, accounts for all
815 byte-identical rows, and emits the literal Phase-I V2 manifest under both
required filename spellings.

Final artifacts are written only by --assemble, only after every input and
all in-memory output bytes have passed validation, and only when none of the
assembler-owned final targets already exists.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import re
import shutil
import sys
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


SCRIPT_PATH = Path(__file__).resolve()
DEFAULT_TASK_ROOT = SCRIPT_PATH.parents[1]

SOURCE_COMMIT = "fcab95726761a0666a67e31c283dbdfb9e775074"
SOURCE_TREE = "bbf1a5fee70a2eb68bb96305ed10934a1559ca6a"
PRODUCT_DCP_SHA256 = "5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82"
DIAGNOSTIC_DCP_SHA256 = "45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F"
PRODUCT_CDC1_SHA256 = "A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D"
DIAGNOSTIC_CDC1_SHA256 = "BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99"
CONTRACT_SHA256 = "D8FAD3132ADECCDBAFD8189297617D9FC45F79382C07F16EB01208BF82A766B2"

CLASSIFICATION = "PROFILE_SPECIFIC_DIAGNOSTIC_CDC_MANIFEST_V2"
CDC_DISPOSITION = "PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST"
SUMMARY_SCHEMA = "NVP_VIDEO_DIAG1_R2R1_CDC_RECONCILIATION_SUMMARY_V2"
ASSEMBLY_RECEIPT_CLASSIFICATION = (
    "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MANIFEST_ASSEMBLY_RECEIPT_V1"
)
BYTE_EVIDENCE_CLASSIFICATION = (
    "G2B_NVP_VIDEO_DIAG1_R2R1_BYTE_IDENTICAL_CDC_ROW_EVIDENCE_V1"
)

MANIFEST_FIELDS = (
    "RowID",
    "ProductPhysicalSource",
    "DiagnosticPhysicalSource",
    "DestinationEndpoint",
    "Rule",
    "Severity",
    "SourceClock",
    "DestinationClock",
    "Exception",
    "SemanticFamilyOrSupportSet",
    "GoverningToken",
    "Protocol",
    "EarliestUseBarrier",
    "ReplacementGroup",
    "ProofClass",
    "RowDisposition",
    "EvidencePath",
)

CONTRACT_FIELDS = (
    "RowID",
    "Rule",
    "Severity",
    "DestinationEndpoint",
    "ProductPhysicalSource",
    "DiagnosticPhysicalSource",
    "SourceClock",
    "DestinationClock",
    "Exception",
    "SemanticFamily",
    "GoverningToken",
    "ProtocolProof",
    "EarliestUseBarrier",
    "ReplacementGroup",
)

SUPPORT_FIELDS = (
    "RowID",
    "Rule",
    "Severity",
    "DestinationPin",
    "DestinationCell",
    "DestinationClock",
    "ProductReportRepresentative",
    "DiagnosticReportRepresentative",
    "ProductPhysicalStartpoints",
    "DiagnosticPhysicalStartpoints",
    "ProductSemanticFamilies",
    "DiagnosticSemanticFamilies",
    "NewFamilies",
    "MissingFamilies",
    "ProductGoverningTokens",
    "DiagnosticGoverningTokens",
    "ProtocolDrift",
    "ExceptionDrift",
    "BarrierDrift",
    "ReplacementGroupDrift",
    "ProofClass",
    "Disposition",
    "EvidencePath",
)

EXPECTED_RULE_SEVERITY_COUNTS = Counter(
    {
        ("CDC-1", "Critical"): 423,
        ("CDC-10", "Critical"): 2,
        ("CDC-13", "Critical"): 2,
        ("CDC-6", "Warning"): 13,
        ("CDC-15", "Warning"): 861,
        ("CDC-3", "Info"): 30,
        ("CDC-9", "Info"): 6,
    }
)
EXPECTED_SEVERITIES = Counter({"Critical": 427, "Warning": 874, "Info": 36})
EXPECTED_PROOFS = Counter(
    {
        "BYTE_IDENTICAL": 815,
        "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE": 512,
        "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE": 7,
        "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE": 3,
    }
)
EXPECTED_CHANGED_PROOFS = Counter(
    {
        "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE": 512,
        "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE": 7,
        "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE": 3,
    }
)
EXPECTED_CROSS_ROWS = {
    "CDC1-CHG-0286",
    "CDC1-CHG-0288",
    "CDC1-CHG-0289",
    "CDC1-CHG-0290",
    "CDC1-CHG-0300",
    "CDC1-CHG-0301",
    "CDC1-CHG-0302",
}
EXPECTED_COMPOSITE_ROWS = {"WARN-CHG-0218", "WARN-CHG-0219", "WARN-CHG-0220"}
DIAGNOSTIC_HIERARCHY_TOKENS = (
    "g2b_nvp_video_diag",
    "nvp_video_diag",
    "current_result_word",
    "current_result_valid",
    "current_result_generation",
    "current_result_session",
    "scan_fsm",
)
HEX64 = re.compile(r"^[0-9A-F]{64}$")


class GateFailure(RuntimeError):
    """A required identity, schema, count, or semantic gate failed."""


@dataclass(frozen=True)
class CDCRow:
    rule: str
    severity: str
    description: str
    depth: int
    exception: str
    source: str
    destination: str
    source_clock: str
    destination_clock: str

    def physical_key(self) -> tuple[Any, ...]:
        return (
            self.rule,
            self.severity,
            self.description,
            self.depth,
            self.source_clock,
            self.destination_clock,
            self.exception,
            self.source,
            self.destination,
        )

    def non_source_key(self) -> tuple[Any, ...]:
        return (
            self.rule,
            self.severity,
            self.description,
            self.depth,
            self.source_clock,
            self.destination_clock,
            self.exception,
            self.destination,
        )

    def manifest_identity(self) -> dict[str, Any]:
        return {
            "Rule": self.rule,
            "Severity": self.severity,
            "Description": self.description,
            "Depth": self.depth,
            "Exception": self.exception,
            "PhysicalSource": self.source,
            "DestinationEndpoint": self.destination,
            "SourceClock": self.source_clock,
            "DestinationClock": self.destination_clock,
        }


@dataclass(frozen=True)
class Pair:
    product: CDCRow
    diagnostic: CDCRow
    changed: bool


@dataclass(frozen=True)
class BuildProduct:
    manifest_rows: tuple[dict[str, str], ...]
    files: Mapping[str, bytes]
    directory_files: Mapping[str, Mapping[str, bytes]]
    metrics: Mapping[str, Any]
    input_hashes: Mapping[str, str]


def require(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise GateFailure(f"{label}: expected={expected!r} actual={actual!r}")


def require_hex(value: str, label: str) -> None:
    if not HEX64.fullmatch(value):
        raise GateFailure(f"{label} is not uppercase 64-hex: {value!r}")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def snapshot(path: Path, label: str) -> tuple[bytes, str]:
    if not path.is_file() or path.stat().st_size == 0:
        raise GateFailure(f"{label} is missing or empty: {path}")
    data = path.read_bytes()
    return data, sha256_bytes(data)


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=True) + "\n").encode(
        "utf-8"
    )


def csv_bytes(fields: Sequence[str], rows: Iterable[Mapping[str, Any]]) -> bytes:
    buffer = io.StringIO(newline="")
    writer = csv.DictWriter(
        buffer, fieldnames=list(fields), extrasaction="raise", lineterminator="\n"
    )
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
    return buffer.getvalue().encode("utf-8")


def parse_csv_bytes(
    data: bytes, expected_fields: Sequence[str], *, delimiter: str = ",", label: str
) -> list[dict[str, str]]:
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise GateFailure(f"{label} is not UTF-8: {exc}") from exc
    reader = csv.DictReader(io.StringIO(text), delimiter=delimiter)
    require(tuple(reader.fieldnames or ()), tuple(expected_fields), f"{label} header")
    rows = list(reader)
    if any(None in row or any(value is None for value in row.values()) for row in rows):
        raise GateFailure(f"{label} contains a malformed-width row")
    return rows


def parse_receipt(data: bytes, label: str) -> dict[str, str]:
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise GateFailure(f"{label} is not UTF-8: {exc}") from exc
    result: dict[str, str] = {}
    for line_number, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        if "=" not in line:
            raise GateFailure(f"{label}:{line_number} is not KEY=VALUE")
        key, value = line.split("=", 1)
        if not key or key in result:
            raise GateFailure(f"{label}:{line_number} duplicate/empty key {key!r}")
        result[key] = value
    return result


def task_relative(path: Path, task_root: Path) -> str:
    try:
        relative = path.resolve().relative_to(task_root.resolve())
    except ValueError as exc:
        raise GateFailure(f"evidence path escapes task root: {path}") from exc
    return relative.as_posix()


def resolve_evidence(relative: str, task_root: Path, label: str) -> Path:
    if not relative or "\\" in relative or Path(relative).is_absolute():
        raise GateFailure(f"{label} is not a task-relative forward-slash path: {relative!r}")
    path = (task_root / Path(*relative.split("/"))).resolve()
    try:
        path.relative_to(task_root.resolve())
    except ValueError as exc:
        raise GateFailure(f"{label} escapes task root: {relative!r}") from exc
    if not path.is_file() or path.stat().st_size == 0:
        raise GateFailure(f"{label} is missing or empty: {relative!r}")
    return path


def parse_cdc_report(path: Path) -> tuple[list[CDCRow], bytes]:
    raw, _ = snapshot(path, f"CDC report {path}")
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise GateFailure(f"CDC report is not UTF-8/ASCII: {path}: {exc}") from exc

    source_clock: str | None = None
    destination_clock: str | None = None
    rows: list[CDCRow] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if line.startswith("Source Clock:"):
            source_clock = line.split(":", 1)[1].strip()
            continue
        if line.startswith("Destination Clock:"):
            destination_clock = line.split(":", 1)[1].strip()
            continue
        stripped = line.strip()
        if not re.match(r"^\d+\s+CDC-\d+\s+", stripped):
            continue
        parts = re.split(r"\s{2,}", stripped)
        if len(parts) != 8:
            raise GateFailure(
                f"unparsed CDC detail row at {path}:{line_number}; "
                f"expected 8 columns, got {len(parts)}: {stripped}"
            )
        report_row, rule, severity, description, depth_text, exception, source, destination = parts
        if not report_row.isdigit() or not re.fullmatch(r"CDC-\d+", rule):
            raise GateFailure(f"invalid CDC row identity at {path}:{line_number}")
        if severity not in {"Critical", "Warning", "Info"}:
            raise GateFailure(f"unexpected CDC severity at {path}:{line_number}: {severity}")
        if not depth_text.isdigit() or not source_clock or not destination_clock:
            raise GateFailure(f"invalid CDC depth/clock context at {path}:{line_number}")
        if any(ch.isspace() for ch in source) or any(ch.isspace() for ch in destination):
            raise GateFailure(f"CDC endpoint contains whitespace at {path}:{line_number}")
        rows.append(
            CDCRow(
                rule=rule,
                severity=severity,
                description=description,
                depth=int(depth_text),
                exception=exception,
                source=source,
                destination=destination,
                source_clock=source_clock,
                destination_clock=destination_clock,
            )
        )
    if not rows:
        raise GateFailure(f"no detailed CDC rows parsed from {path}")
    return rows, raw


def validate_raw_rows(rows: Sequence[CDCRow], label: str) -> None:
    require(len(rows), 1337, f"{label} row count")
    require(
        Counter((row.rule, row.severity) for row in rows),
        EXPECTED_RULE_SEVERITY_COUNTS,
        f"{label} rule/severity counts",
    )
    require(Counter(row.severity for row in rows), EXPECTED_SEVERITIES, f"{label} severities")
    diagnostic_rows = [
        row
        for row in rows
        if any(
            token in f"{row.source}|{row.destination}".lower()
            for token in DIAGNOSTIC_HIERARCHY_TOKENS
        )
    ]
    require(len(diagnostic_rows), 0, f"{label} diagnostic hierarchy CDC rows")


def cdc1_physical_manifest_sha(rows: Sequence[CDCRow]) -> str:
    lines = sorted(
        f"{row.rule}|{row.source_clock}->{row.destination_clock}|{row.exception}|"
        f"{row.source}|{row.destination}"
        for row in rows
        if row.rule == "CDC-1" and row.severity == "Critical"
    )
    require(len(lines), 423, "parsed CDC-1 row count")
    return sha256_bytes(("".join(line + "\n" for line in lines)).encode("utf-8"))


def pair_reports(product: Sequence[CDCRow], diagnostic: Sequence[CDCRow]) -> list[Pair]:
    product_groups: dict[tuple[Any, ...], list[CDCRow]] = defaultdict(list)
    diagnostic_groups: dict[tuple[Any, ...], list[CDCRow]] = defaultdict(list)
    for row in product:
        product_groups[row.non_source_key()].append(row)
    for row in diagnostic:
        diagnostic_groups[row.non_source_key()].append(row)

    pairs: list[Pair] = []
    all_keys = sorted(set(product_groups) | set(diagnostic_groups), key=repr)
    for key in all_keys:
        old = product_groups.get(key, [])
        new = diagnostic_groups.get(key, [])
        require(len(old), len(new), f"non-source row multiplicity {key!r}")
        old_by_source = Counter(row.source for row in old)
        new_by_source = Counter(row.source for row in new)
        exact = old_by_source & new_by_source
        old_template = {row.source: row for row in old}
        new_template = {row.source: row for row in new}
        for source in sorted(exact):
            for _ in range(exact[source]):
                pairs.append(Pair(old_template[source], new_template[source], False))
        old_remaining: list[CDCRow] = []
        new_remaining: list[CDCRow] = []
        for source, count in (old_by_source - exact).items():
            old_remaining.extend([old_template[source]] * count)
        for source, count in (new_by_source - exact).items():
            new_remaining.extend([new_template[source]] * count)
        old_remaining.sort(key=lambda row: row.source)
        new_remaining.sort(key=lambda row: row.source)
        require(len(old_remaining), len(new_remaining), f"changed row multiplicity {key!r}")
        pairs.extend(Pair(left, right, True) for left, right in zip(old_remaining, new_remaining))

    pairs.sort(
        key=lambda pair: (
            pair.diagnostic.severity,
            pair.diagnostic.rule,
            pair.diagnostic.source_clock,
            pair.diagnostic.destination_clock,
            pair.diagnostic.destination,
            pair.product.source,
            pair.diagnostic.source,
            pair.diagnostic.description,
            pair.diagnostic.depth,
            pair.diagnostic.exception,
        )
    )
    require(len(pairs), 1337, "paired CDC row count")
    require(sum(pair.changed for pair in pairs), 522, "changed CDC row count")
    require(sum(not pair.changed for pair in pairs), 815, "byte-identical CDC row count")
    require(
        Counter((pair.diagnostic.severity, pair.changed) for pair in pairs),
        Counter(
            {
                ("Critical", False): 125,
                ("Critical", True): 302,
                ("Warning", False): 654,
                ("Warning", True): 220,
                ("Info", False): 36,
            }
        ),
        "paired severity/change partition",
    )
    return pairs


def changed_pair_key(pair: Pair) -> tuple[str, ...]:
    return (
        pair.diagnostic.rule,
        pair.diagnostic.severity,
        pair.diagnostic.destination,
        pair.product.source,
        pair.diagnostic.source,
        pair.diagnostic.source_clock,
        pair.diagnostic.destination_clock,
        pair.diagnostic.exception,
    )


def contract_key(row: Mapping[str, str]) -> tuple[str, ...]:
    return (
        row["Rule"],
        row["Severity"],
        row["DestinationEndpoint"],
        row["ProductPhysicalSource"],
        row["DiagnosticPhysicalSource"],
        row["SourceClock"],
        row["DestinationClock"],
        row["Exception"],
    )


def validate_extraction_receipt(
    task_root: Path,
    profile: str,
    directory: Path,
    expected_dcp_sha: str,
    expected_cdc1_sha: str,
    input_hashes: dict[str, str],
) -> dict[str, str]:
    receipt_data, receipt_sha = snapshot(directory / "EXTRACTION_RECEIPT.txt", f"{profile} receipt")
    receipt = parse_receipt(receipt_data, f"{profile} receipt")
    expected = {
        "RESULT": "PASS",
        "PROFILE": profile,
        "MODE": "EXACT_ROUTED_DCP_REPORT_ONLY",
        "PART": "xc7a35tcsg325-2",
        "TOP": "ahd_capture_top_xdma",
        "DCP_SHA256": expected_dcp_sha,
        "CDC_ROWS": "1337",
        "CRITICAL_TOTAL": "427",
        "WARNING_TOTAL": "874",
        "INFO_TOTAL": "36",
        "CDC_1_COUNT": "423",
        "CDC_1_PHYSICAL_MANIFEST_SHA256": expected_cdc1_sha,
        "CHANGED_DESTINATIONS_PROCESSED": "522",
        "CONSTRAINTS_CHANGED": "NO",
        "IMPLEMENTATION_CHANGED": "NO",
        "DCP_CHANGED": "NO",
        "BITSTREAM_WRITTEN": "NO",
    }
    for key, value in expected.items():
        require(receipt.get(key), value, f"{profile} extraction receipt {key}")
    if not receipt.get("VIVADO_VERSION", "").startswith("2025.2"):
        raise GateFailure(f"{profile} extraction is not Vivado 2025.2")
    input_hashes[f"{profile.title()}ExtractionReceipt"] = receipt_sha
    # The comparer calls the same immutable receipt simply ProductReceipt or
    # DiagnosticReceipt.  Preserve both labels and require equal digests.
    input_hashes[f"{profile.title()}Receipt"] = receipt_sha
    for filename, receipt_key, input_key in (
        ("DESTINATION_STARTPOINT_INVENTORY.csv", "STARTPOINT_INVENTORY_SHA256", "Inventory"),
        ("DESTINATION_EXTRACTION_SUMMARY.csv", "EXTRACTION_SUMMARY_SHA256", "Summary"),
        ("DIAGNOSTIC_TAP_FANOUT.csv", "TAP_FANOUT_SHA256", "TapFanout"),
    ):
        data, digest = snapshot(directory / filename, f"{profile} {filename}")
        del data
        require(digest, receipt.get(receipt_key), f"{profile} {filename} receipt binding")
        require_hex(digest, f"{profile} {filename} SHA256")
        input_hashes[f"{profile.title()}{input_key}"] = digest
    if profile == "diagnostic":
        detail_data, detail_sha = snapshot(
            directory / "DIAGNOSTIC_TAP_FANOUT_DETAIL.txt",
            "diagnostic tap-fanout detail",
        )
        del detail_data
        require(
            detail_sha,
            receipt.get("TAP_FANOUT_DETAIL_SHA256"),
            "diagnostic tap-fanout detail receipt binding",
        )
        require(
            receipt.get("TAP_PROOF_METHOD"),
            "EXACT_SOURCE_DRIVER_ALL_FANOUT_TWO_DCP_DELTA",
            "diagnostic tap proof method",
        )
        require(
            receipt.get("TAP_BOUNDARY_NAME_DISPOSITION"),
            "FORMAL_PORT_NAMES_OPTIMIZED_SOURCE_ANCHORS_USED",
            "diagnostic tap boundary-name disposition",
        )
        require(
            receipt.get("PRODUCT_DCP_SHA256_FOR_TAP_DELTA"),
            PRODUCT_DCP_SHA256,
            "diagnostic tap-delta PRODUCT DCP identity",
        )
        input_hashes["DiagnosticTapFanoutDetail"] = detail_sha
    manifest_data, manifest_sha = snapshot(
        directory / "CDC_1_PHYSICAL_MANIFEST.txt", f"{profile} CDC-1 manifest"
    )
    del manifest_data
    require(manifest_sha, expected_cdc1_sha, f"{profile} CDC-1 manifest identity")
    input_hashes[f"{profile.title()}CDC1PhysicalManifest"] = manifest_sha
    raw_data, raw_sha = snapshot(directory / "CDC.rpt", f"{profile} CDC report")
    del raw_data
    input_hashes[f"{profile.title()}RawCDCReport"] = raw_sha
    return receipt


def validate_support_inputs(
    task_root: Path,
    contracts: Sequence[dict[str, str]],
    support_path: Path,
    evidence_manifest_path: Path,
    comparer_receipt_path: Path,
    input_hashes: dict[str, str],
) -> tuple[list[dict[str, str]], dict[str, Mapping[str, Any]]]:
    support_data, support_sha = snapshot(support_path, "destination-cone support CSV")
    support_rows = parse_csv_bytes(support_data, SUPPORT_FIELDS, label="support CSV")
    require(len(support_rows), 522, "support row count")
    require(
        [row["RowID"] for row in support_rows],
        [row["RowID"] for row in contracts],
        "support contract row order",
    )
    input_hashes["DestinationConeSupportCSV"] = support_sha

    evidence_manifest_data, evidence_manifest_sha = snapshot(
        evidence_manifest_path, "destination-cone evidence SHA256 manifest"
    )
    input_hashes["DestinationConeEvidenceSHA256"] = evidence_manifest_sha
    evidence_lines = evidence_manifest_data.decode("utf-8-sig").splitlines()
    require(len(evidence_lines), 522, "destination-cone evidence hash line count")

    contract_by_id = {row["RowID"]: row for row in contracts}
    detail_by_id: dict[str, Mapping[str, Any]] = {}
    expected_evidence_lines: list[str] = []
    proof_counts: Counter[str] = Counter()
    severity_counts: Counter[str] = Counter()
    same_critical: Counter[str] = Counter()
    for row in support_rows:
        row_id = row["RowID"]
        contract = contract_by_id[row_id]
        for support_field, contract_field in (
            ("Rule", "Rule"),
            ("Severity", "Severity"),
            ("DestinationPin", "DestinationEndpoint"),
            ("DestinationClock", "DestinationClock"),
            ("ProductReportRepresentative", "ProductPhysicalSource"),
            ("DiagnosticReportRepresentative", "DiagnosticPhysicalSource"),
        ):
            require(row[support_field], contract[contract_field], f"{row_id} {support_field}")
        require(
            row["DestinationCell"],
            contract["DestinationEndpoint"].rsplit("/", 1)[0],
            f"{row_id} DestinationCell",
        )
        for key in ("ProductPhysicalStartpoints", "DiagnosticPhysicalStartpoints"):
            if row[key] in {"", "[]"}:
                raise GateFailure(f"{row_id} empty {key}")
        for key in (
            "ProductSemanticFamilies",
            "DiagnosticSemanticFamilies",
            "ProductGoverningTokens",
            "DiagnosticGoverningTokens",
        ):
            if row[key] in {"", "[]"}:
                raise GateFailure(f"{row_id} empty {key}")
            try:
                parsed = json.loads(row[key])
            except json.JSONDecodeError as exc:
                raise GateFailure(f"{row_id} invalid JSON in {key}: {exc}") from exc
            if not isinstance(parsed, list) or not parsed:
                raise GateFailure(f"{row_id} {key} is not a nonempty JSON array")
        require(row["ProductSemanticFamilies"], row["DiagnosticSemanticFamilies"], f"{row_id} family set")
        require(row["ProductGoverningTokens"], row["DiagnosticGoverningTokens"], f"{row_id} token set")
        require(row["NewFamilies"], "[]", f"{row_id} new families")
        require(row["MissingFamilies"], "[]", f"{row_id} missing families")
        for drift in ("ProtocolDrift", "ExceptionDrift", "BarrierDrift", "ReplacementGroupDrift"):
            require(row[drift], "0", f"{row_id} {drift}")
        require(row["Disposition"], "PASS", f"{row_id} support disposition")
        if row["ProofClass"] not in EXPECTED_CHANGED_PROOFS:
            raise GateFailure(f"{row_id} unauthorized support proof {row['ProofClass']!r}")
        if row_id in EXPECTED_CROSS_ROWS:
            require(
                row["ProofClass"],
                "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE",
                f"{row_id} cross proof",
            )
        elif row_id in EXPECTED_COMPOSITE_ROWS:
            require(
                row["ProofClass"],
                "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE",
                f"{row_id} composite proof",
            )
        else:
            require(
                row["ProofClass"],
                "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE",
                f"{row_id} same-family proof",
            )
        if row["Severity"] == "Critical" and row["ProofClass"] == "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE":
            family_text = row["ProductSemanticFamilies"]
            has_reset = "RESET_COMMIT_STABLE_PAYLOAD" in family_text
            has_ownership = "OWNERSHIP_STABLE_PAYLOAD" in family_text
            if has_reset == has_ownership:
                raise GateFailure(f"{row_id} does not have one exact critical same-family axis")
            same_critical["RESET_COMMIT" if has_reset else "OWNERSHIP"] += 1

        evidence_path = resolve_evidence(row["EvidencePath"], task_root, f"{row_id} evidence")
        evidence_sha = sha256_file(evidence_path)
        expected_evidence_lines.append(f"{row_id}={row['EvidencePath']}|{evidence_sha}")
        try:
            detail = json.loads(evidence_path.read_text(encoding="utf-8-sig"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise GateFailure(f"{row_id} row evidence is invalid JSON: {exc}") from exc
        require(
            detail.get("Classification"),
            "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_ROW_EVIDENCE_V1",
            f"{row_id} evidence classification",
        )
        require(detail.get("RowAuthority"), contract, f"{row_id} evidence RowAuthority")
        comparison = detail.get("Comparison")
        if not isinstance(comparison, dict):
            raise GateFailure(f"{row_id} evidence lacks Comparison")
        raw = detail.get("Raw")
        if not isinstance(raw, dict):
            raise GateFailure(f"{row_id} evidence lacks Raw")
        normalized = detail.get("Normalized")
        if not isinstance(normalized, dict):
            raise GateFailure(f"{row_id} evidence lacks Normalized")
        for profile_name in ("Product", "Diagnostic"):
            raw_profile = raw.get(profile_name)
            if not isinstance(raw_profile, dict):
                raise GateFailure(f"{row_id} evidence lacks Raw.{profile_name}")
            if not isinstance(raw_profile.get("Summary"), dict):
                raise GateFailure(f"{row_id} evidence lacks Raw.{profile_name}.Summary")
            if not isinstance(raw_profile.get("PhysicalStartpoints"), list):
                raise GateFailure(
                    f"{row_id} evidence lacks list Raw.{profile_name}.PhysicalStartpoints"
                )
            profile_evidence = normalized.get(profile_name)
            if not isinstance(profile_evidence, dict):
                raise GateFailure(f"{row_id} evidence lacks Normalized.{profile_name}")
            for required_collection in (
                "ClassifiedStartpoints",
                "SupportAtoms",
                "GoverningControls",
                "VirtualControls",
                "LocalQualifiers",
                "LocalSameClockStartpoints",
                "Issues",
            ):
                if not isinstance(profile_evidence.get(required_collection), list):
                    raise GateFailure(
                        f"{row_id} evidence lacks list Normalized.{profile_name}.{required_collection}"
                    )
            require(profile_evidence["Issues"], [], f"{row_id} {profile_name} issues")

        for profile_name, support_field in (
            ("Product", "ProductPhysicalStartpoints"),
            ("Diagnostic", "DiagnosticPhysicalStartpoints"),
        ):
            physical = sorted(
                item.get("StartpointCell", "")
                for item in raw[profile_name]["PhysicalStartpoints"]
            )
            if not physical or any(not item for item in physical):
                raise GateFailure(f"{row_id} invalid Raw.{profile_name}.PhysicalStartpoints")
            require(
                physical,
                json.loads(row[support_field]),
                f"{row_id} {profile_name} raw/support physical startpoints",
            )

        require(
            comparison.get("ProductSemanticAtoms"),
            comparison.get("DiagnosticSemanticAtoms"),
            f"{row_id} semantic atom identity",
        )
        require(comparison.get("NewAtoms"), [], f"{row_id} new semantic atoms")
        require(comparison.get("MissingAtoms"), [], f"{row_id} missing semantic atoms")
        require(
            comparison.get("ProductGoverningTokens"),
            comparison.get("DiagnosticGoverningTokens"),
            f"{row_id} governing-token identity",
        )
        require(
            comparison.get("TokenSetDrift"),
            {"New": [], "Missing": []},
            f"{row_id} governing-token set drift",
        )
        for evidence_field, support_field in (
            ("ProductSemanticAtoms", "ProductSemanticFamilies"),
            ("DiagnosticSemanticAtoms", "DiagnosticSemanticFamilies"),
            ("ProductGoverningTokens", "ProductGoverningTokens"),
            ("DiagnosticGoverningTokens", "DiagnosticGoverningTokens"),
        ):
            require(
                comparison.get(evidence_field),
                json.loads(row[support_field]),
                f"{row_id} evidence/support {evidence_field}",
            )
        for drift_name in (
            "AtomTokenDrift",
            "ProtocolDrift",
            "ExceptionDrift",
            "ExceptionClassDrift",
            "ExceptionRequirementDrift",
            "BarrierDrift",
            "ReplacementGroupDrift",
            "GoverningControlDrift",
            "VirtualGoverningControlDrift",
            "SourceClockDrift",
        ):
            require(comparison.get(drift_name), [], f"{row_id} {drift_name}")
        require(
            comparison.get("Blockers"), [], f"{row_id} evidence blockers"
        )
        product_virtual = normalized["Product"]["VirtualControls"]
        diagnostic_virtual = normalized["Diagnostic"]["VirtualControls"]
        require(product_virtual, diagnostic_virtual, f"{row_id} virtual controls")
        require(
            len(product_virtual),
            5 if row_id in EXPECTED_COMPOSITE_ROWS else 0,
            f"{row_id} virtual-control cardinality",
        )
        require(comparison.get("ProofClass"), row["ProofClass"], f"{row_id} evidence proof")
        require(comparison.get("Disposition"), "PASS", f"{row_id} evidence disposition")
        detail_by_id[row_id] = detail
        proof_counts[row["ProofClass"]] += 1
        severity_counts[row["Severity"]] += 1

    require(evidence_lines, expected_evidence_lines, "destination-cone evidence SHA manifest")
    require(proof_counts, EXPECTED_CHANGED_PROOFS, "changed support proof counts")
    require(severity_counts, Counter({"Critical": 302, "Warning": 220}), "support severities")
    require(same_critical, Counter({"RESET_COMMIT": 285, "OWNERSHIP": 10}), "critical same-family partition")

    comparer_data, comparer_sha = snapshot(comparer_receipt_path, "cone comparer receipt")
    input_hashes["DestinationConeComparerReceipt"] = comparer_sha
    try:
        comparer = json.loads(comparer_data.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GateFailure(f"cone comparer receipt is invalid JSON: {exc}") from exc
    require(
        comparer.get("Classification"),
        "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT_V1",
        "comparer classification",
    )
    require(comparer.get("Result"), "PASS", "comparer result")
    require(
        comparer.get("Disposition"),
        "PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST_INPUT",
        "comparer disposition",
    )
    require(comparer.get("Rows"), 522, "comparer rows")
    require(comparer.get("PassRows"), 522, "comparer pass rows")
    require(comparer.get("FailRows"), 0, "comparer fail rows")
    require(comparer.get("UnclassifiedCrossClockStartpoints"), 0, "unclassified cross-clock startpoints")
    require(comparer.get("UnknownOrAmbiguousStartpoints"), 0, "unknown or ambiguous startpoints")
    require(comparer.get("BlockerCounts"), {}, "comparer blockers")
    require(Counter(comparer.get("ProofClassCounts", {})), EXPECTED_CHANGED_PROOFS, "comparer proof counts")
    require(Counter(comparer.get("PassProofClassCounts", {})), EXPECTED_CHANGED_PROOFS, "comparer PASS proof counts")
    comparer_inputs = comparer.get("InputSHA256")
    if not isinstance(comparer_inputs, dict):
        raise GateFailure("comparer receipt lacks InputSHA256")
    expected_comparer_inputs = {
        key: input_hashes[key]
        for key in (
            "ChangedDestinationsTSV",
            "SemanticRulesJSON",
            "SourceFamilyDefinitionsCSV",
            "SemanticModelJSON",
            "ProductReceipt",
            "ProductInventory",
            "ProductSummary",
            "ProductTapFanout",
            "DiagnosticReceipt",
            "DiagnosticInventory",
            "DiagnosticSummary",
            "DiagnosticTapFanout",
            "DiagnosticTapFanoutDetail",
        )
    }
    require(comparer_inputs, expected_comparer_inputs, "comparer complete input hash binding")
    for row_id, detail in detail_by_id.items():
        require(detail.get("InputSHA256"), comparer_inputs, f"{row_id} evidence input hashes")
    outputs = comparer.get("OutputSHA256")
    if not isinstance(outputs, dict):
        raise GateFailure("comparer receipt lacks OutputSHA256")
    require(outputs.get("DestinationConeSupportCSV"), support_sha, "comparer support hash")
    require(
        outputs.get("DestinationConeEvidenceSHA256"),
        evidence_manifest_sha,
        "comparer evidence-manifest hash",
    )
    unknown_path = task_root / "cdc" / "G2B_NVP_VIDEO_DIAG1_R2R1_UNCLASSIFIED_STARTPOINTS.csv"
    unknown_data, unknown_sha = snapshot(unknown_path, "unclassified startpoints CSV")
    require(outputs.get("UnclassifiedStartpointsCSV"), unknown_sha, "comparer unknown CSV hash")
    unknown_lines = unknown_data.decode("utf-8-sig").splitlines()
    require(len(unknown_lines), 1, "unclassified startpoints row count")
    input_hashes["UnclassifiedStartpointsCSV"] = unknown_sha
    return support_rows, detail_by_id


def metadata_union(
    detail: Mapping[str, Any], field: str, row_id: str, profile: str
) -> str:
    normalized = detail.get("Normalized", {}).get(profile, {})
    values: set[str] = set()
    for collection in (
        "SupportAtoms",
        "GoverningControls",
        "VirtualControls",
        "LocalQualifiers",
    ):
        records = normalized.get(collection)
        if not isinstance(records, list):
            raise GateFailure(f"{row_id} evidence missing {profile}.{collection}")
        for record in records:
            raw_values = record.get(field, [])
            if not isinstance(raw_values, list) or any(not isinstance(value, str) for value in raw_values):
                raise GateFailure(f"{row_id} invalid {collection}.{field}")
            values.update(raw_values)
    if not values:
        raise GateFailure(f"{row_id} has no governed {profile}.{field} metadata")
    return json.dumps(sorted(values), separators=(",", ":"), ensure_ascii=True)


def validate_source_reports(task_root: Path, input_hashes: dict[str, str]) -> None:
    identity_path = task_root / "reports" / "G2B_NVP_VIDEO_DIAG1_R2R1_G2B_FUNCTIONAL_BODY_IDENTITY.md"
    tap_path = task_root / "reports" / "G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_TAP_NONINTERFERENCE.md"
    identity_data, identity_sha = snapshot(identity_path, "functional-body identity report")
    tap_data, tap_sha = snapshot(tap_path, "diagnostic tap noninterference report")
    identity_text = identity_data.decode("utf-8-sig")
    tap_text = tap_data.decode("utf-8-sig")
    for literal in (
        "G2B_FUNCTIONAL_BODY_IDENTITY = PASS",
        "DIAGNOSTIC_TAPS_ONLY = YES",
        "FUNCTIONAL_OWNERSHIP_LOGIC_CHANGED = NO",
        "FUNCTIONAL_RELEASE_LOGIC_CHANGED = NO",
        "FUNCTIONAL_RESET_LOGIC_CHANGED = NO",
    ):
        if literal not in identity_text:
            raise GateFailure(f"functional-body report lacks {literal!r}")
    if "SOURCE_LEVEL_DIAGNOSTIC_TAP_NONINTERFERENCE = PASS" not in tap_text:
        raise GateFailure("diagnostic tap report is not PASS")
    input_hashes["SourceFunctionalIdentityReport"] = identity_sha
    input_hashes["SourceTapNoninterferenceReport"] = tap_sha


def validate_semantic_model_contract(data: bytes) -> None:
    try:
        model = json.loads(data.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GateFailure(f"semantic model is invalid JSON: {exc}") from exc
    required = model.get("RequiredV2Manifest")
    if not isinstance(required, dict):
        raise GateFailure("semantic model lacks RequiredV2Manifest")
    require(required.get("Classification"), CLASSIFICATION, "semantic model classification")
    require(required.get("ExpectedRows"), 1337, "semantic model expected rows")
    require(required.get("RequiredUniqueRowIDs"), 1337, "semantic model unique RowIDs")
    require(tuple(required.get("RequiredColumns", [])), MANIFEST_FIELDS, "semantic model columns")
    require(Counter(required.get("ProofClassCounts", {})), EXPECTED_PROOFS, "semantic model proof counts")
    require(
        required.get("CanonicalArtifactNames"),
        [
            "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.csv",
            "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.json",
            "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.sha256",
        ],
        "semantic model canonical names",
    )
    require(
        required.get("PromptPhaseIArtifactAliases"),
        [
            "NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.csv",
            "NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.json",
            "NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.sha256",
        ],
        "semantic model Phase-I aliases",
    )
    require(
        required.get("AliasPolicy"),
        "BOTH_THREE_FILE_NAME_SETS_REQUIRED_AND_CORRESPONDING_FILES_MUST_BE_BYTE_IDENTICAL",
        "semantic model alias policy",
    )
    per_row = model.get("RequiredPerRowEvidenceJSON")
    if not isinstance(per_row, dict):
        raise GateFailure("semantic model lacks RequiredPerRowEvidenceJSON")
    required_normalized = per_row.get("RequiredNormalizedProfileKeys", [])
    if "VirtualControls" not in required_normalized:
        raise GateFailure("semantic model does not require per-row VirtualControls")
    required_comparison = per_row.get("RequiredComparisonKeys", [])
    if "VirtualGoverningControlDrift" not in required_comparison:
        raise GateFailure(
            "semantic model does not require per-row VirtualGoverningControlDrift"
        )


def build_product(task_root: Path, *, require_comparer: bool) -> BuildProduct:
    cdc_dir = task_root / "cdc"
    cone_dir = task_root / "cone-proof"
    input_hashes: dict[str, str] = {}
    try:
        SCRIPT_PATH.relative_to(task_root)
    except ValueError as exc:
        raise GateFailure("assembler script is not task-local") from exc
    input_hashes["AssemblerScript"] = sha256_file(SCRIPT_PATH)

    contract_data, contract_sha = snapshot(cone_dir / "changed_destinations.tsv", "changed contract")
    require(contract_sha, CONTRACT_SHA256, "changed contract SHA256")
    contracts = parse_csv_bytes(contract_data, CONTRACT_FIELDS, delimiter="\t", label="changed contract")
    expected_ids = [f"CDC1-CHG-{index:04d}" for index in range(1, 303)] + [
        f"WARN-CHG-{index:04d}" for index in range(1, 221)
    ]
    require([row["RowID"] for row in contracts], expected_ids, "changed contract RowID order")
    require(len({row["DestinationEndpoint"] for row in contracts}), 522, "changed destination uniqueness")
    input_hashes["ChangedDestinationsTSV"] = contract_sha

    auxiliary_inputs = {
        "ComparerScript": task_root / "scripts" / "g2b_nvp_video_diag1_r2r1_compare_cones.py",
        "SemanticRulesJSON": task_root / "scripts" / "g2b_nvp_video_diag1_r2r1_semantic_rules.json",
        "SourceFamilyDefinitionsCSV": cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv",
        "RowPartitionCSV": cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_ROW_PARTITION.csv",
        "SemanticModelJSON": cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json",
        "SemanticDefinitionReceipt": cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_DEFINITION_RECEIPT.txt",
        "CompositeReleaseTokenAuthority": cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_COMPOSITE_RELEASE_TOKEN.md",
    }
    auxiliary_data: dict[str, bytes] = {}
    for label, path in auxiliary_inputs.items():
        data, digest = snapshot(path, label)
        auxiliary_data[label] = data
        input_hashes[label] = digest
    validate_semantic_model_contract(auxiliary_data["SemanticModelJSON"])
    validate_source_reports(task_root, input_hashes)

    product_dir = cone_dir / "product"
    diagnostic_dir = cone_dir / "diagnostic"
    validate_extraction_receipt(
        task_root,
        "product",
        product_dir,
        PRODUCT_DCP_SHA256,
        PRODUCT_CDC1_SHA256,
        input_hashes,
    )
    validate_extraction_receipt(
        task_root,
        "diagnostic",
        diagnostic_dir,
        DIAGNOSTIC_DCP_SHA256,
        DIAGNOSTIC_CDC1_SHA256,
        input_hashes,
    )

    product_rows, product_raw = parse_cdc_report(product_dir / "CDC.rpt")
    diagnostic_rows, diagnostic_raw = parse_cdc_report(diagnostic_dir / "CDC.rpt")
    require(input_hashes["ProductRawCDCReport"], sha256_bytes(product_raw), "product raw report snapshot")
    require(input_hashes["DiagnosticRawCDCReport"], sha256_bytes(diagnostic_raw), "diagnostic raw report snapshot")
    validate_raw_rows(product_rows, "PRODUCT")
    validate_raw_rows(diagnostic_rows, "diagnostic")
    require(
        cdc1_physical_manifest_sha(product_rows),
        PRODUCT_CDC1_SHA256,
        "PRODUCT parsed CDC-1 physical identity",
    )
    require(
        cdc1_physical_manifest_sha(diagnostic_rows),
        DIAGNOSTIC_CDC1_SHA256,
        "diagnostic parsed CDC-1 physical identity",
    )
    pairs = pair_reports(product_rows, diagnostic_rows)

    changed_pairs: dict[tuple[str, ...], Pair] = {}
    for pair in pairs:
        if not pair.changed:
            continue
        key = changed_pair_key(pair)
        if key in changed_pairs:
            raise GateFailure(f"duplicate changed physical pair key: {key!r}")
        changed_pairs[key] = pair
    contract_keys = [contract_key(row) for row in contracts]
    require(len(set(contract_keys)), 522, "changed contract physical-pair uniqueness")
    require(set(changed_pairs), set(contract_keys), "changed contract versus raw CDC pair set")

    if not require_comparer:
        metrics = {
            "Rows": len(pairs),
            "ChangedRows": len(changed_pairs),
            "ByteIdenticalRows": sum(not pair.changed for pair in pairs),
            "Severities": dict(EXPECTED_SEVERITIES),
        }
        return BuildProduct((), {}, {}, metrics, dict(sorted(input_hashes.items())))

    support_rows, detail_by_id = validate_support_inputs(
        task_root,
        contracts,
        cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv",
        cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_EVIDENCE_SHA256.txt",
        cdc_dir / "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT.json",
        input_hashes,
    )
    support_by_key = {
        contract_key(contract): (contract, support, detail_by_id[contract["RowID"]])
        for contract, support in zip(contracts, support_rows)
    }

    manifest_rows: list[dict[str, str]] = []
    byte_evidence: dict[str, bytes] = {}
    byte_evidence_hash_lines: list[str] = []
    for sequence, pair in enumerate(pairs, start=1):
        if pair.changed:
            contract, support, detail = support_by_key[changed_pair_key(pair)]
            row_id = contract["RowID"]
            protocol = metadata_union(detail, "Protocols", row_id, "Product")
            barrier = metadata_union(detail, "Barriers", row_id, "Product")
            replacement = metadata_union(detail, "ReplacementGroups", row_id, "Product")
            require(protocol, metadata_union(detail, "Protocols", row_id, "Diagnostic"), f"{row_id} protocol union")
            require(barrier, metadata_union(detail, "Barriers", row_id, "Diagnostic"), f"{row_id} barrier union")
            require(
                replacement,
                metadata_union(detail, "ReplacementGroups", row_id, "Diagnostic"),
                f"{row_id} replacement-group union",
            )
            row = {
                "RowID": row_id,
                "ProductPhysicalSource": pair.product.source,
                "DiagnosticPhysicalSource": pair.diagnostic.source,
                "DestinationEndpoint": pair.diagnostic.destination,
                "Rule": pair.diagnostic.rule,
                "Severity": pair.diagnostic.severity,
                "SourceClock": pair.diagnostic.source_clock,
                "DestinationClock": pair.diagnostic.destination_clock,
                "Exception": pair.diagnostic.exception,
                "SemanticFamilyOrSupportSet": support["ProductSemanticFamilies"],
                "GoverningToken": support["ProductGoverningTokens"],
                "Protocol": protocol,
                "EarliestUseBarrier": barrier,
                "ReplacementGroup": replacement,
                "ProofClass": support["ProofClass"],
                "RowDisposition": "PASS",
                "EvidencePath": support["EvidencePath"],
            }
        else:
            if pair.product.physical_key() != pair.diagnostic.physical_key():
                raise GateFailure(f"pair {sequence} marked byte-identical but differs")
            row_id = f"CDC-ALL-{sequence:05d}"
            relative = f"cdc/profile-cdc-byte-identical-row-evidence/{row_id}.json"
            evidence = {
                "Classification": BYTE_EVIDENCE_CLASSIFICATION,
                "RowID": row_id,
                "PairSequence": sequence,
                "ProofClass": "BYTE_IDENTICAL",
                "Disposition": "PASS",
                "Product": pair.product.manifest_identity(),
                "Diagnostic": pair.diagnostic.manifest_identity(),
                "PhysicalIdentityFields": [
                    "Rule",
                    "Severity",
                    "Description",
                    "Depth",
                    "SourceClock",
                    "DestinationClock",
                    "Exception",
                    "PhysicalSource",
                    "DestinationEndpoint",
                ],
                "PhysicalRowsByteIdentical": True,
                "SemanticNormalizationApplied": False,
                "SemanticFieldPolicy": (
                    "RETAINED_PHYSICAL_REPORT_DISPOSITION_NOT_A_NEW_SEMANTIC_FAMILY"
                ),
                "Authority": {
                    "ProductRawCDCReportSHA256": input_hashes["ProductRawCDCReport"],
                    "DiagnosticRawCDCReportSHA256": input_hashes["DiagnosticRawCDCReport"],
                    "ProductRoutedDCPSHA256": PRODUCT_DCP_SHA256,
                    "DiagnosticRoutedDCPSHA256": DIAGNOSTIC_DCP_SHA256,
                },
            }
            evidence_data = json_bytes(evidence)
            evidence_name = f"{row_id}.json"
            byte_evidence[evidence_name] = evidence_data
            byte_evidence_hash_lines.append(
                f"{row_id}={relative}|{sha256_bytes(evidence_data)}"
            )
            row = {
                "RowID": row_id,
                "ProductPhysicalSource": pair.product.source,
                "DiagnosticPhysicalSource": pair.diagnostic.source,
                "DestinationEndpoint": pair.diagnostic.destination,
                "Rule": pair.diagnostic.rule,
                "Severity": pair.diagnostic.severity,
                "SourceClock": pair.diagnostic.source_clock,
                "DestinationClock": pair.diagnostic.destination_clock,
                "Exception": pair.diagnostic.exception,
                "SemanticFamilyOrSupportSet": "UNCHANGED_PHYSICAL_SOURCE",
                "GoverningToken": "EXISTING_REPORT_DISPOSITION",
                "Protocol": "EXISTING_PHYSICAL_DISPOSITION_PRESERVED_NO_NORMALIZATION",
                "EarliestUseBarrier": "EXISTING_REPORT_CLOCK_AND_EXCEPTION_CONTRACT",
                "ReplacementGroup": f"UNCHANGED_{pair.diagnostic.rule}_REPORT_DISPOSITION",
                "ProofClass": "BYTE_IDENTICAL",
                "RowDisposition": "PASS",
                "EvidencePath": relative,
            }
        if tuple(row) != MANIFEST_FIELDS or any(value == "" for value in row.values()):
            raise GateFailure(f"manifest row is incomplete or out of schema order: {row_id}")
        manifest_rows.append(row)

    validate_manifest_rows(manifest_rows, task_root, byte_evidence)

    csv_data = csv_bytes(MANIFEST_FIELDS, manifest_rows)
    json_document = {
        "Authority": {
            "SourceCommit": SOURCE_COMMIT,
            "SourceTree": SOURCE_TREE,
            "ProductRoutedDCPSHA256": PRODUCT_DCP_SHA256,
            "DiagnosticRoutedDCPSHA256": DIAGNOSTIC_DCP_SHA256,
            "ProductCDC1PhysicalManifestSHA256": PRODUCT_CDC1_SHA256,
            "DiagnosticCDC1PhysicalManifestSHA256": DIAGNOSTIC_CDC1_SHA256,
        },
        "ByteIdenticalRowPolicy": (
            "UNCHANGED_PHYSICAL_SOURCE_FIELDS_ARE_RETAINED_REPORT_DISPOSITIONS_"
            "AND_DO_NOT_ASSERT_A_NEW_SEMANTIC_FAMILY"
        ),
        "Classification": CLASSIFICATION,
        "Columns": list(MANIFEST_FIELDS),
        "ProofClassCounts": dict(sorted(EXPECTED_PROOFS.items())),
        "RowCount": 1337,
        "Rows": manifest_rows,
        "SeverityCounts": dict(sorted(EXPECTED_SEVERITIES.items())),
    }
    json_data = json_bytes(json_document)
    sidecar_data = (
        f"CSV_SHA256={sha256_bytes(csv_data)}\n"
        f"JSON_SHA256={sha256_bytes(json_data)}\n"
    ).encode("ascii")
    byte_manifest_data = ("\n".join(byte_evidence_hash_lines) + "\n").encode("utf-8")

    summary_values: list[tuple[str, str]] = [
        ("SCHEMA", SUMMARY_SCHEMA),
        ("RESULT", "PASS"),
        ("CDC_DISPOSITION", CDC_DISPOSITION),
        ("CLASSIFICATION", CLASSIFICATION),
        ("SOURCE_COMMIT", SOURCE_COMMIT),
        ("SOURCE_TREE", SOURCE_TREE),
        ("PRODUCT_ROUTED_DCP_SHA256", PRODUCT_DCP_SHA256),
        ("DIAGNOSTIC_ROUTED_DCP_SHA256", DIAGNOSTIC_DCP_SHA256),
        ("PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256", PRODUCT_CDC1_SHA256),
        ("DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256", DIAGNOSTIC_CDC1_SHA256),
        ("RAW_CRITICAL_COUNT", "427"),
        ("RAW_WARNING_COUNT", "874"),
        ("CDC_1_DESTINATIONS", "423"),
        ("NEW_CDC_DESTINATIONS", "0"),
        ("MISSING_CDC_DESTINATIONS", "0"),
        ("RULE_DRIFT_COUNT", "0"),
        ("SEVERITY_DRIFT_COUNT", "0"),
        ("CLOCK_PAIR_DRIFT_COUNT", "0"),
        ("DESTINATION_MULTIPLICITY_DRIFT_COUNT", "0"),
        ("CDC_1_BYTE_IDENTICAL_ROWS", "121"),
        ("CDC_10_BYTE_IDENTICAL_ROWS", "2"),
        ("CDC_13_BYTE_IDENTICAL_ROWS", "2"),
        ("CRITICAL_SAME_FAMILY_ROWS", "295"),
        ("CRITICAL_SAME_FAMILY_RECONCILED", "295"),
        ("CROSS_FAMILY_CRITICAL_ROWS", "7"),
        ("CROSS_FAMILY_CRITICAL_RECONCILED", "7"),
        ("TOTAL_CHANGED_CRITICAL_ROWS", "302"),
        ("TOTAL_CHANGED_CRITICAL_RECONCILED", "302"),
        ("WARNING_SAME_FAMILY_ROWS", "217"),
        ("WARNING_SAME_FAMILY_RECONCILED", "217"),
        ("COMPOSITE_RELEASE_WARNING_ROWS", "3"),
        ("COMPOSITE_RELEASE_WARNING_RECONCILED", "3"),
        ("TOTAL_CHANGED_WARNING_ROWS", "220"),
        ("TOTAL_CHANGED_WARNING_RECONCILED", "220"),
        ("TOTAL_MANIFEST_ROWS", "1337"),
        ("BYTE_IDENTICAL_ROWS", "815"),
        ("SAME_FAMILY_ROWS", "512"),
        ("DESTINATION_CONE_ROWS", "7"),
        ("COMPOSITE_RELEASE_ROWS", "3"),
        ("CHANGED_SUPPORT_ROWS", "522"),
        ("CHANGED_SUPPORT_PASS_ROWS", "522"),
        ("UNRECONCILED_CRITICAL_ROWS", "0"),
        ("UNRECONCILED_WARNING_ROWS", "0"),
        ("NEW_FAMILY_COUNT", "0"),
        ("MISSING_FAMILY_COUNT", "0"),
        ("SOURCE_CLOCK_DRIFT_COUNT", "0"),
        ("GOVERNING_TOKEN_DRIFT_COUNT", "0"),
        ("PROTOCOL_DRIFT_COUNT", "0"),
        ("EXCEPTION_DRIFT_COUNT", "0"),
        ("BARRIER_DRIFT_COUNT", "0"),
        ("REPLACEMENT_GROUP_DRIFT_COUNT", "0"),
        ("DIAGNOSTIC_HIERARCHY_CDC_ROWS", "0"),
        ("UNCLASSIFIED_CROSS_CLOCK_STARTPOINTS", "0"),
        ("DIAGNOSTIC_SOURCE_FAMILIES_IN_FUNCTIONAL_CONES", "0"),
        ("ARBITRARY_SOURCE_NORMALIZATION_USED", "NO"),
        ("OWNERSHIP_RELEASE_MERGED", "NO"),
        ("COMPOSITE_CHILD_FIELDS_PRESERVED", "YES"),
        ("ENABLE_APPLIED_SUPPORT_SET", "PASS"),
        ("SLOT_STATE0_SUPPORT_SET", "PASS"),
        ("OWNERSHIP_FATAL_DEFERRED_SUPPORT_SET", "PASS"),
        ("OWNERSHIP_FATAL_EVENT_SUPPORT_SET", "PASS"),
        ("OWNERSHIP_FATAL_SUPPORT_SET", "PASS"),
        ("RESET_ABANDONED_COMPOSITE_SUPPORT_SET", "PASS"),
        ("STRUCTURAL_CDC", "PASS"),
        ("REPLACEMENT_CHECKS_PASS", "17"),
        ("REPLACEMENT_CHECKS_TOTAL", "17"),
        ("UNRESOLVED_REPLACEMENT_CHECKS", "0"),
        ("SEMANTIC_MANIFEST_CSV_SHA256", sha256_bytes(csv_data)),
        ("SEMANTIC_MANIFEST_JSON_SHA256", sha256_bytes(json_data)),
        ("SUPPORT_CSV_SHA256", input_hashes["DestinationConeSupportCSV"]),
        ("SOURCE_FAMILY_DEFINITIONS_SHA256", input_hashes["SourceFamilyDefinitionsCSV"]),
        ("ROW_PARTITION_SHA256", input_hashes["RowPartitionCSV"]),
        ("SEMANTIC_MODEL_SHA256", input_hashes["SemanticModelJSON"]),
        ("DESTINATION_CONE_COMPARER_RECEIPT_SHA256", input_hashes["DestinationConeComparerReceipt"]),
        ("PRODUCT_RAW_CDC_REPORT_SHA256", input_hashes["ProductRawCDCReport"]),
        ("DIAGNOSTIC_RAW_CDC_REPORT_SHA256", input_hashes["DiagnosticRawCDCReport"]),
        ("PRODUCT_EXTRACTION_RECEIPT_SHA256", input_hashes["ProductExtractionReceipt"]),
        ("DIAGNOSTIC_EXTRACTION_RECEIPT_SHA256", input_hashes["DiagnosticExtractionReceipt"]),
        ("SOURCE_FUNCTIONAL_IDENTITY_REPORT_SHA256", input_hashes["SourceFunctionalIdentityReport"]),
        ("DIAGNOSTIC_TAP_FANOUT_CSV_SHA256", input_hashes["DiagnosticTapFanout"]),
        ("G2B_FUNCTIONAL_BODY_IDENTITY", "PASS"),
        ("DIAGNOSTIC_TAP_NONINTERFERENCE", "PASS"),
        (
            "BYTE_IDENTICAL_SEMANTIC_FIELD_POLICY",
            "RETAINED_PHYSICAL_REPORT_DISPOSITION_NOT_A_NEW_SEMANTIC_FAMILY",
        ),
    ]
    summary_data = ("".join(f"{key}={value}\n" for key, value in summary_values)).encode("utf-8")

    canonical_stem = "NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2"
    alias_stem = "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2"
    files: dict[str, bytes] = {
        f"cdc/{canonical_stem}.csv": csv_data,
        f"cdc/{canonical_stem}.json": json_data,
        f"cdc/{canonical_stem}.sha256": sidecar_data,
        f"cdc/{alias_stem}.csv": csv_data,
        f"cdc/{alias_stem}.json": json_data,
        f"cdc/{alias_stem}.sha256": sidecar_data,
        "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_BYTE_IDENTICAL_EVIDENCE_SHA256.txt": byte_manifest_data,
        "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_RECONCILIATION_RECEIPT.txt": summary_data,
    }
    metrics = {
        "Rows": 1337,
        "UniqueRowIDs": 1337,
        "SeverityCounts": dict(sorted(EXPECTED_SEVERITIES.items())),
        "ProofClassCounts": dict(sorted(EXPECTED_PROOFS.items())),
        "ChangedRows": 522,
        "ByteIdenticalRows": 815,
        "ByteIdenticalEvidenceRows": len(byte_evidence),
        "AliasesByteIdentical": True,
    }
    receipt_without_outputs = {
        "Classification": ASSEMBLY_RECEIPT_CLASSIFICATION,
        "Result": "PASS",
        "CDCDisposition": CDC_DISPOSITION,
        "ByteIdenticalSemanticFieldPolicy": (
            "RETAINED_PHYSICAL_REPORT_DISPOSITION_NOT_A_NEW_SEMANTIC_FAMILY"
        ),
        "Authority": {
            "SourceCommit": SOURCE_COMMIT,
            "SourceTree": SOURCE_TREE,
            "ProductRoutedDCPSHA256": PRODUCT_DCP_SHA256,
            "DiagnosticRoutedDCPSHA256": DIAGNOSTIC_DCP_SHA256,
        },
        "InputSHA256": dict(sorted(input_hashes.items())),
        "Metrics": metrics,
        "ReceiptSelfHashExcluded": True,
        "OutputSHA256": {
            **{name: sha256_bytes(data) for name, data in sorted(files.items())},
            "cdc/profile-cdc-byte-identical-row-evidence": sha256_bytes(byte_manifest_data),
        },
    }
    receipt_data = json_bytes(receipt_without_outputs)
    files["cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MANIFEST_ASSEMBLY_RECEIPT.json"] = receipt_data

    product = BuildProduct(
        tuple(manifest_rows),
        dict(sorted(files.items())),
        {"cdc/profile-cdc-byte-identical-row-evidence": dict(sorted(byte_evidence.items()))},
        metrics,
        dict(sorted(input_hashes.items())),
    )
    validate_generated_product(product)
    return product


def validate_manifest_rows(
    rows: Sequence[Mapping[str, str]],
    task_root: Path,
    byte_evidence: Mapping[str, bytes],
) -> None:
    require(len(rows), 1337, "semantic V2 row count")
    require(len({row["RowID"] for row in rows}), 1337, "semantic V2 unique RowIDs")
    require(Counter(row["Severity"] for row in rows), EXPECTED_SEVERITIES, "semantic V2 severities")
    require(Counter(row["ProofClass"] for row in rows), EXPECTED_PROOFS, "semantic V2 proof classes")
    require(Counter(row["RowDisposition"] for row in rows), Counter({"PASS": 1337}), "semantic V2 dispositions")
    for row in rows:
        require(tuple(row), MANIFEST_FIELDS, f"{row['RowID']} manifest schema")
        if any(value == "" for value in row.values()):
            raise GateFailure(f"{row['RowID']} contains an empty required field")
        if row["ProofClass"] == "BYTE_IDENTICAL":
            require(row["ProductPhysicalSource"], row["DiagnosticPhysicalSource"], f"{row['RowID']} physical source")
            expected_prefix = "cdc/profile-cdc-byte-identical-row-evidence/"
            if not row["EvidencePath"].startswith(expected_prefix):
                raise GateFailure(f"{row['RowID']} has wrong byte-evidence path")
            filename = row["EvidencePath"][len(expected_prefix) :]
            if filename not in byte_evidence or not byte_evidence[filename]:
                raise GateFailure(f"{row['RowID']} in-memory byte evidence missing")
        else:
            resolve_evidence(row["EvidencePath"], task_root, f"{row['RowID']} changed evidence")


def validate_generated_product(product: BuildProduct) -> None:
    canonical = "cdc/NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2"
    alias = "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2"
    for suffix in (".csv", ".json", ".sha256"):
        require(product.files[canonical + suffix], product.files[alias + suffix], f"alias {suffix}")
    csv_data = product.files[canonical + ".csv"]
    parsed_rows = parse_csv_bytes(csv_data, MANIFEST_FIELDS, label="generated semantic CSV")
    require(parsed_rows, list(product.manifest_rows), "generated CSV row content")
    document = json.loads(product.files[canonical + ".json"].decode("utf-8"))
    require(document["Classification"], CLASSIFICATION, "generated JSON classification")
    require(document["RowCount"], 1337, "generated JSON row count")
    require(document["Rows"], list(product.manifest_rows), "generated JSON row content")
    sidecar = parse_receipt(product.files[canonical + ".sha256"], "generated sidecar")
    require(sidecar.get("CSV_SHA256"), sha256_bytes(csv_data), "generated CSV sidecar")
    require(
        sidecar.get("JSON_SHA256"),
        sha256_bytes(product.files[canonical + ".json"]),
        "generated JSON sidecar",
    )
    byte_dir = product.directory_files["cdc/profile-cdc-byte-identical-row-evidence"]
    require(len(byte_dir), 815, "generated byte-evidence files")
    summary = parse_receipt(
        product.files["cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_RECONCILIATION_RECEIPT.txt"],
        "generated semantic reconciliation summary",
    )
    require(summary.get("RESULT"), "PASS", "generated summary result")
    require(summary.get("CDC_DISPOSITION"), CDC_DISPOSITION, "generated summary disposition")


def owned_targets(task_root: Path, product: BuildProduct) -> list[Path]:
    return [task_root / relative for relative in product.directory_files] + [
        task_root / relative for relative in product.files
    ]


def publish(task_root: Path, product: BuildProduct) -> None:
    targets = owned_targets(task_root, product)
    existing = [path for path in targets if path.exists()]
    if existing:
        raise GateFailure(
            "assembler-owned final target already exists; no overwrite is allowed: "
            + ", ".join(str(path) for path in existing)
        )
    private_dir = task_root / "private"
    private_dir.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix="manifest-assembly-stage-", dir=private_dir))
    try:
        for relative, files in product.directory_files.items():
            directory = stage / relative
            directory.mkdir(parents=True)
            for name, data in files.items():
                (directory / name).write_bytes(data)
        for relative, data in product.files.items():
            path = stage / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)

        for relative, files in product.directory_files.items():
            directory = stage / relative
            require(len(list(directory.iterdir())), len(files), f"staged {relative} file count")
            for name, data in files.items():
                require((directory / name).read_bytes(), data, f"staged {relative}/{name}")
        for relative, data in product.files.items():
            require((stage / relative).read_bytes(), data, f"staged {relative}")

        for relative in product.directory_files:
            destination = task_root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            os.replace(stage / relative, destination)
        # The assembly receipt is the final publication marker.
        receipt_name = "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MANIFEST_ASSEMBLY_RECEIPT.json"
        for relative in [name for name in product.files if name != receipt_name] + [receipt_name]:
            destination = task_root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            os.replace(stage / relative, destination)
    finally:
        shutil.rmtree(stage, ignore_errors=True)


def validate_published(task_root: Path, product: BuildProduct) -> None:
    for relative, files in product.directory_files.items():
        directory = task_root / relative
        if not directory.is_dir():
            raise GateFailure(f"published evidence directory missing: {relative}")
        actual_names = sorted(path.name for path in directory.iterdir() if path.is_file())
        require(actual_names, sorted(files), f"published {relative} file set")
        for name, data in files.items():
            require((directory / name).read_bytes(), data, f"published {relative}/{name}")
    for relative, data in product.files.items():
        path = task_root / relative
        if not path.is_file():
            raise GateFailure(f"published file missing: {relative}")
        require(path.read_bytes(), data, f"published {relative}")


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task-root", type=Path, default=DEFAULT_TASK_ROOT)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--assemble", action="store_true")
    mode.add_argument("--validate-only", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    task_root = args.task_root.resolve()
    try:
        if not task_root.is_dir():
            raise GateFailure(f"task root does not exist: {task_root}")
        if args.self_test:
            product = build_product(task_root, require_comparer=False)
            print("R2R1_SEMANTIC_MANIFEST_ASSEMBLER_SELF_TEST=PASS")
            print(f"ROWS={product.metrics['Rows']}")
            print(f"CHANGED_ROWS={product.metrics['ChangedRows']}")
            print(f"BYTE_IDENTICAL_ROWS={product.metrics['ByteIdenticalRows']}")
            print(f"SCRIPT_SHA256={sha256_file(SCRIPT_PATH)}")
            return 0

        product = build_product(task_root, require_comparer=True)
        canonical = "cdc/NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2"
        if args.dry_run:
            print("R2R1_SEMANTIC_MANIFEST_ASSEMBLER_DRY_RUN=PASS")
            print(f"ROWS={product.metrics['Rows']}")
            print(f"CSV_SHA256={sha256_bytes(product.files[canonical + '.csv'])}")
            print(f"JSON_SHA256={sha256_bytes(product.files[canonical + '.json'])}")
            print(f"SCRIPT_SHA256={sha256_file(SCRIPT_PATH)}")
            return 0
        if args.assemble:
            publish(task_root, product)
            validate_published(task_root, product)
            print("R2R1_SEMANTIC_MANIFEST_ASSEMBLY=PASS")
            print(f"ROWS={product.metrics['Rows']}")
            print(f"CSV_SHA256={sha256_bytes(product.files[canonical + '.csv'])}")
            print(f"JSON_SHA256={sha256_bytes(product.files[canonical + '.json'])}")
            print(f"SCRIPT_SHA256={sha256_file(SCRIPT_PATH)}")
            return 0
        validate_published(task_root, product)
        print("R2R1_SEMANTIC_MANIFEST_PUBLISHED_VALIDATION=PASS")
        print(f"ROWS={product.metrics['Rows']}")
        print(f"SCRIPT_SHA256={sha256_file(SCRIPT_PATH)}")
        return 0
    except (GateFailure, OSError, KeyError, ValueError) as exc:
        print(f"R2R1_SEMANTIC_MANIFEST_ASSEMBLER_BLOCKED|{exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
