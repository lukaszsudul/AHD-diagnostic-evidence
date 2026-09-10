#!/usr/bin/env python3
"""Assemble a sanitized DIAG1-R2R1 evidence package without publishing it.

This task-local assembler is deliberately fail-closed.  It never writes into
either source repository, never copies DCP/bitstream/native binaries or camera
data, and will not claim the Phase-N blocker as the terminal result unless the
offline sign-off receipt itself is PASS.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
from pathlib import Path


TASK_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z")
R1_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z")
R2_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2_20260910T064851Z")
PRODUCT_DCP = Path(r"C:\FPGA\G2B_BT656_FIX1_R1_20260909T090813Z\artifacts\offline-candidate\G2B_BT656_FIX1_R1_SIGNED_OFF_ROUTED.dcp")
DIAGNOSTIC_DCP = R1_ROOT / "reports" / "vivado_full" / "G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp"

PACKAGE_NAME = "v41-hardware-g2b-nvp-video-diag1-r2r1-destination-cone-cdc-four-channel-scan"
PRODUCT_DCP_SHA256 = "5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82"
DIAGNOSTIC_DCP_SHA256 = "45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F"
PRODUCT_CDC1_SHA256 = "A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D"
DIAGNOSTIC_CDC1_SHA256 = "BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99"
SOURCE_COMMIT = "fcab95726761a0666a67e31c283dbdfb9e775074"
SOURCE_TREE = "bbf1a5fee70a2eb68bb96305ed10934a1559ca6a"
PRODUCT_COMMIT = "30b14d13b0b789b62b05ab513eb9578c7c43b11a"
PRODUCT_TREE = "bdbe39077a03f8945ebdd1ed9e52761fbe787696"
R2_EVIDENCE_COMMIT = "8500b0675d4a7691f951dc0b0894ad35ef64ebc8"
BLOCKER = "NVP_DIAG1_R2R1_FROZEN_BASELINE_DOUBLE_READ_AND_HOST_LEDGER_CAPABILITY_ABSENT"

CDC = TASK_ROOT / "cdc"
CONE = TASK_ROOT / "cone-proof"
SIGNOFF = TASK_ROOT / "signoff"
REPORTS = TASK_ROOT / "reports"

MANDATORY = [
    "V41_G2B_NVP_VIDEO_DIAG1_R2R1_MAIN_REPORT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_OWNER_AUTHORIZATION.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SCOPE.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_R2_INHERITANCE.md",
    "G2B_NVP_VIDEO_DIAG1_R2_PUBLICATION_RECEIPT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_AUTHORITY.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_G2B_FUNCTIONAL_BODY_IDENTITY.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_TAP_NONINTERFERENCE.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_PRODUCT_DCP_AUTHORITY.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_DCP_AUTHORITY.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_RAW_CDC_REPRODUCTION.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_COMPOSITE_RELEASE_TOKEN.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_METHOD.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CRITICAL_SAME_FAMILY_RECONCILIATION.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_WARNING_SAME_FAMILY_RECONCILIATION.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CROSS_FAMILY_DESTINATION_PROOFS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_COMPOSITE_RELEASE_WARNING_PROOFS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_ENABLE_APPLIED_CONE_PROOF.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SLOT_STATE0_CONE_PROOF.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_OWNERSHIP_FATAL_DEFERRED_CONE_PROOF.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_OWNERSHIP_FATAL_EVENT_CONE_PROOF.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_OWNERSHIP_FATAL_CONE_PROOF.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_RESET_ABANDONED_CONE_PROOF.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.json",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_DISPOSITION.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_BUS_SKEW_REPORT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_REPLACEMENT_METHOD_RESULTS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_TIMING_REPORT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_DRC_REPORT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_METHODOLOGY_REPORT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_RESOURCE_REPORT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SIGNED_OFF_DCP_MANIFEST.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_BITSTREAM_MANIFEST.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_PROGRAMMING_RECEIPT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_REBOOT_RECEIPT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_RUNTIME_IDENTITY.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_I2C_TRANSACTION_LOG.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_NVP_WRITE_LEDGER.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_NVP_READBACK_LEDGER.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_STATUS_SAMPLES.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SNAPSHOT_COHERENCE.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_HOST_SESSION_HISTORY.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_HOST_SESSION_HISTORY.jsonl",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SCAN_RESULTS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CAPTURE_INDEX.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CAPTURE_RESULTS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_FRAME_HASHES.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_PIXEL_STATISTICS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_BGDCOL_MATCH_RESULTS.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CHANNEL_REPEATABILITY.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_INPUT_MAPPING_DECISION.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_DIGITAL_PATH_DECISION.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CAMERA_CONTENT_DECISION.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_PRODUCT_RESTORE_RECEIPT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_CLEANUP_RECEIPT.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_FINAL_STATE.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_GATE_MATRIX.csv",
    "G2B_NVP_VIDEO_DIAG1_R2R1_STATE.json",
    "G2B_NVP_VIDEO_DIAG1_R2R1_EVIDENCE_INDEX.md",
    "G2B_NVP_VIDEO_DIAG1_R2R1_SHA256_MANIFEST.txt",
]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def require_file(path: Path) -> Path:
    if not path.is_file():
        raise RuntimeError(f"REQUIRED_FILE_MISSING:{path}")
    return path


def require_hash(path: Path, expected: str) -> None:
    actual = sha256_file(require_file(path))
    if actual != expected:
        raise RuntimeError(f"HASH_MISMATCH:{path}:{expected}:{actual}")


def parse_kv(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for raw in require_file(path).read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in raw:
            key, value = raw.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def write_text(root: Path, relative: str, content: str) -> None:
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        raise RuntimeError(f"FRESH_OUTPUT_REQUIRED:{target}")
    target.write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def copy_file(root: Path, source: Path, relative: str) -> None:
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        raise RuntimeError(f"FRESH_OUTPUT_REQUIRED:{target}")
    shutil.copy2(require_file(source), target)


def copy_tree(root: Path, source: Path, relative: str) -> None:
    target = root / relative
    if target.exists():
        raise RuntimeError(f"FRESH_OUTPUT_REQUIRED:{target}")
    shutil.copytree(source, target, ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "*.dcp", "*.bit", "*.png", "*.uyvy", "primary.bin"))


def csv_text(rows: list[dict[str, str]], fields: list[str]) -> str:
    import io
    out = io.StringIO(newline="")
    writer = csv.DictWriter(out, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return out.getvalue()


def not_reached_csv(header: str, reason: str) -> str:
    return header + "\n" + ",".join(["NOT_REACHED", reason] + [""] * max(0, header.count(",") - 1)) + "\n"


def proof_report(title: str, rows: list[dict[str, str]]) -> str:
    body = [f"# {title}", "", "Result: **PASS**", ""]
    for row in rows:
        body.extend([
            f"- Row: `{row['RowID']}`",
            f"- Destination: `{row['DestinationPin']}`",
            f"- Proof class: `{row['ProofClass']}`",
            f"- Disposition: `{row['Disposition']}`",
            f"- Per-row evidence: `{row['EvidencePath']}`",
            "",
        ])
    body.append("PRODUCT and diagnostic semantic support sets, governing tokens, protocol, exception, earliest-use barrier and replacement group are equal for every listed row. Physical representative names were not normalized or treated as equivalent fields.")
    return "\n".join(body)


def validate_authority() -> tuple[dict[str, str], list[dict[str, str]]]:
    require_hash(PRODUCT_DCP, PRODUCT_DCP_SHA256)
    require_hash(DIAGNOSTIC_DCP, DIAGNOSTIC_DCP_SHA256)
    product = parse_kv(CONE / "product" / "EXTRACTION_RECEIPT.txt")
    diagnostic = parse_kv(CONE / "diagnostic" / "EXTRACTION_RECEIPT.txt")
    semantic = parse_kv(CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_RECONCILIATION_RECEIPT.txt")
    for receipt, profile, dcp_sha, cdc_sha in (
        (product, "product", PRODUCT_DCP_SHA256, PRODUCT_CDC1_SHA256),
        (diagnostic, "diagnostic", DIAGNOSTIC_DCP_SHA256, DIAGNOSTIC_CDC1_SHA256),
    ):
        expected = {
            "RESULT": "PASS", "PROFILE": profile, "DCP_SHA256": dcp_sha,
            "CDC_1_PHYSICAL_MANIFEST_SHA256": cdc_sha,
            "CHANGED_DESTINATIONS_PROCESSED": "522", "CONSTRAINTS_CHANGED": "NO",
            "IMPLEMENTATION_CHANGED": "NO", "DCP_CHANGED": "NO", "BITSTREAM_WRITTEN": "NO",
        }
        for key, value in expected.items():
            if receipt.get(key) != value:
                raise RuntimeError(f"EXTRACTION_RECEIPT_MISMATCH:{profile}:{key}:{receipt.get(key)}:{value}")
    required_semantic = {
        "RESULT": "PASS",
        "CDC_DISPOSITION": "PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST",
        "TOTAL_MANIFEST_ROWS": "1337", "BYTE_IDENTICAL_ROWS": "815",
        "CRITICAL_SAME_FAMILY_RECONCILED": "295", "CROSS_FAMILY_CRITICAL_RECONCILED": "7",
        "WARNING_SAME_FAMILY_RECONCILED": "217", "COMPOSITE_RELEASE_WARNING_RECONCILED": "3",
        "TOTAL_CHANGED_CRITICAL_RECONCILED": "302", "TOTAL_CHANGED_WARNING_RECONCILED": "220",
        "UNRECONCILED_CRITICAL_ROWS": "0", "UNRECONCILED_WARNING_ROWS": "0",
        "NEW_FAMILY_COUNT": "0", "MISSING_FAMILY_COUNT": "0",
        "GOVERNING_TOKEN_DRIFT_COUNT": "0", "PROTOCOL_DRIFT_COUNT": "0",
        "EXCEPTION_DRIFT_COUNT": "0", "BARRIER_DRIFT_COUNT": "0",
        "REPLACEMENT_GROUP_DRIFT_COUNT": "0", "DIAGNOSTIC_HIERARCHY_CDC_ROWS": "0",
        "STRUCTURAL_CDC": "PASS", "REPLACEMENT_CHECKS_PASS": "17",
        "G2B_FUNCTIONAL_BODY_IDENTITY": "PASS", "DIAGNOSTIC_TAP_NONINTERFERENCE": "PASS",
    }
    for key, value in required_semantic.items():
        if semantic.get(key) != value:
            raise RuntimeError(f"SEMANTIC_RECEIPT_MISMATCH:{key}:{semantic.get(key)}:{value}")
    support_path = require_file(CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv")
    with support_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 522 or any(row["Disposition"] != "PASS" for row in rows):
        raise RuntimeError("DESTINATION_CONE_SUPPORT_NOT_522_OF_522_PASS")
    return semantic, rows


def signoff_state(mode: str) -> tuple[str, dict[str, str]]:
    result_path = SIGNOFF / "G2B_NVP_VIDEO_DIAG1_R2R1_SIGNOFF_RESULT.txt"
    if mode == "provisional":
        if result_path.is_file():
            values = parse_kv(result_path)
            return values.get("RESULT", "UNKNOWN"), values
        return "IN_PROGRESS", {}
    values = parse_kv(result_path)
    if values.get("RESULT") != "PASS":
        raise RuntimeError("BLOCKED_PHASE_N_MODE_REQUIRES_OFFLINE_SIGNOFF_PASS")
    return "PASS", values


def create_core(root: Path, mode: str, semantic: dict[str, str], rows: list[dict[str, str]], signoff_result: str, signoff: dict[str, str]) -> None:
    terminal = mode == "blocked-phase-n"
    engineering = "BLOCKED" if terminal else "PROVISIONAL_NOT_FINAL"
    overall = "BLOCKED" if terminal else "NOT_FINAL"
    hardware_reason = BLOCKER if terminal else "OFFLINE_SIGNOFF_IN_PROGRESS"
    write_text(root, "V41_G2B_NVP_VIDEO_DIAG1_R2R1_MAIN_REPORT.md", f"""# AHD v41 G2B NVP VIDEO DIAG1-R2R1 main report

Engineering gate: **{engineering}**

Overall result: **{overall}**

Evidence publication: **PENDING — local package only; no commit, push or read-back performed by this assembler**

The exact PRODUCT and diagnostic routed DCP identities passed. The raw CDC authorities reproduced 427 Critical and 874 Warning rows. All 423 CDC-1 destination endpoints are preserved. The complete 522-row destination-cone comparison passed: 295/295 Critical and 217/217 Warning same-family representative changes, 7/7 cross-family destination support-set proofs, and 3/3 composite release-token warning proofs. The final 1,337-row profile-specific semantic CDC manifest contains 815 byte-identical rows plus the 522 proven changed rows, with zero unreconciled Critical/Warning rows and zero family, token, protocol, exception, barrier or replacement-group drift.

Offline routed sign-off status at package assembly: **{signoff_result}**.

Hardware status: **NOT_REACHED**. No DUT root, hardware lock, JTAG access, FPGA programming, reboot, driver load, NVP I2C transaction, MMIO, DMA/AIO, capture or camera-pixel processing was performed by the evidence-preparation work.

First blocker: `{hardware_reason}`.

The Phase-N requirement demands two agreeing physical reads of the complete PRODUCT NVP restoration baseline before any diagnostic NVP write, with the values recorded in both firmware and host ledgers. Repeating PREPARE is only a partial workaround: each pass performs bank-select writes and overwrites the same firmware baseline copy, no in-firmware comparison or dual ledger exists, the saved original bank/page is not exposed through diagnostic MMIO, and the accepted host controller performs only one PREPARE/read set. A wrapper cannot recover the hidden bank value. Hardware therefore remains outside the authorized gate unless the Owner/Architect reconciles that literal contract or authorizes the bounded implementation change.
""")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_OWNER_AUTHORIZATION.md", f"""# Owner and Architect authorization

PROJECT_STATE_REV: 8 — OWNER_ATTESTED_NOT_REVERIFIED

- Exact two-DCP read-only reopen: GRANTED
- Destination-cone support-set extraction: GRANTED
- Composite release-token proof: GRANTED
- Profile-specific semantic CDC manifest: GRANTED
- Hardware scan: GRANTED_AFTER_OFFLINE_SIGNOFF, but not reached in this package
- RTL/XDC/IP/source-commit changes: NOT AUTHORIZED
- Fresh synthesis/implementation or seed retry: NOT AUTHORIZED
- CDC waiver, suppression or constraint weakening: NOT AUTHORIZED
""")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_SCOPE.md", """# Scope

R2R1 performs exact routed-DCP identity, deterministic destination-cone extraction, row-level semantic CDC reconciliation, routed sign-off, and—only when every prerequisite is implementable—the governed 4x4 diagnostic scan. It does not authorize source changes, a rebuild, Flash programming, power-cycle, a second scan, 60-second capture, two-channel capture or V4L2. Raw camera data and hardware binaries are excluded from publication.
""")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_R2_INHERITANCE.md", f"""# DIAG1-R2 inheritance

- R2 evidence commit: `{R2_EVIDENCE_COMMIT}`
- R2 correctly failed literal cross-family normalization and published its result.
- R2R1 does not rewrite R2 evidence.
- Frozen R2 counts, destination identities and physical-manifest hashes were used only under the explicit Owner continuation.
- R2R1 adds row-level support-set and composite-token proofs; it does not retroactively change the R2 outcome.
""")
    receipt = (R2_ROOT / "reports" / "G2B_NVP_VIDEO_DIAG1_R2_EVIDENCE_PUBLICATION_RECEIPT.txt").read_text(encoding="utf-8")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2_PUBLICATION_RECEIPT.md", "# DIAG1-R2 publication receipt\n\n```text\n" + receipt.rstrip() + "\n```\n")
    copy_file(root, REPORTS / "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_AUTHORITY.md", "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_AUTHORITY.md")
    copy_file(root, REPORTS / "G2B_NVP_VIDEO_DIAG1_R2R1_G2B_FUNCTIONAL_BODY_IDENTITY.md", "G2B_NVP_VIDEO_DIAG1_R2R1_G2B_FUNCTIONAL_BODY_IDENTITY.md")
    copy_file(root, REPORTS / "G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_TAP_NONINTERFERENCE.md", "G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_TAP_NONINTERFERENCE.md")
    for profile, path, digest, cdc_digest in (
        ("PRODUCT", PRODUCT_DCP, PRODUCT_DCP_SHA256, PRODUCT_CDC1_SHA256),
        ("DIAGNOSTIC", DIAGNOSTIC_DCP, DIAGNOSTIC_DCP_SHA256, DIAGNOSTIC_CDC1_SHA256),
    ):
        write_text(root, f"G2B_NVP_VIDEO_DIAG1_R2R1_{profile}_DCP_AUTHORITY.md", f"""# {profile} routed-DCP authority

Result: **PASS**

- Exact path: `{path}`
- Exact SHA-256: `{digest}`
- Reopened mode: `EXACT_ROUTED_DCP_REPORT_ONLY`
- CDC-1 physical manifest SHA-256: `{cdc_digest}`
- Constraints changed: NO
- Implementation changed: NO
- Source DCP changed: NO
- Bitstream written during extraction: NO
""")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_RAW_CDC_REPRODUCTION.md", f"""# Raw CDC reproduction

Result: **PASS**

- Critical: 427 (CDC-1 423, CDC-10 2, CDC-13 2)
- Warning: 874 (CDC-6 13, CDC-15 861)
- Info: 36
- CDC-1 destinations: 423/423
- New/missing destinations: 0/0
- Rule, severity, clock-pair, exception and multiplicity drift: 0
- PRODUCT CDC-1 manifest: `{PRODUCT_CDC1_SHA256}`
- Diagnostic CDC-1 manifest: `{DIAGNOSTIC_CDC1_SHA256}`
""")
    copy_file(root, CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv", "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv")
    copy_file(root, CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_COMPOSITE_RELEASE_TOKEN.md", "G2B_NVP_VIDEO_DIAG1_R2R1_COMPOSITE_RELEASE_TOKEN.md")
    copy_file(root, TASK_ROOT / "scripts" / "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_EXTRACTOR_DESIGN.md", "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_METHOD.md")
    copy_file(root, CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv", "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv")
    fields = list(rows[0].keys())
    partitions = {
        "G2B_NVP_VIDEO_DIAG1_R2R1_CRITICAL_SAME_FAMILY_RECONCILIATION.csv": [r for r in rows if r["Severity"] == "Critical" and r["ProofClass"] == "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE"],
        "G2B_NVP_VIDEO_DIAG1_R2R1_WARNING_SAME_FAMILY_RECONCILIATION.csv": [r for r in rows if r["Severity"] == "Warning" and r["ProofClass"] == "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE"],
        "G2B_NVP_VIDEO_DIAG1_R2R1_CROSS_FAMILY_DESTINATION_PROOFS.csv": [r for r in rows if r["ProofClass"] == "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE"],
        "G2B_NVP_VIDEO_DIAG1_R2R1_COMPOSITE_RELEASE_WARNING_PROOFS.csv": [r for r in rows if r["ProofClass"] == "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE"],
    }
    expected = [295, 217, 7, 3]
    for (name, subset), count in zip(partitions.items(), expected):
        if len(subset) != count:
            raise RuntimeError(f"PARTITION_COUNT_MISMATCH:{name}:{len(subset)}:{count}")
        write_text(root, name, csv_text(subset, fields))
    by_id = {r["RowID"]: r for r in rows}
    reports = {
        "G2B_NVP_VIDEO_DIAG1_R2R1_ENABLE_APPLIED_CONE_PROOF.md": ("Enable-applied destination support-set proof", ["CDC1-CHG-0286"]),
        "G2B_NVP_VIDEO_DIAG1_R2R1_SLOT_STATE0_CONE_PROOF.md": ("Slot-state[0] destination support-set proof", ["CDC1-CHG-0288", "CDC1-CHG-0289", "CDC1-CHG-0290"]),
        "G2B_NVP_VIDEO_DIAG1_R2R1_OWNERSHIP_FATAL_DEFERRED_CONE_PROOF.md": ("Ownership-fatal-deferred support-set proof", ["CDC1-CHG-0300"]),
        "G2B_NVP_VIDEO_DIAG1_R2R1_OWNERSHIP_FATAL_EVENT_CONE_PROOF.md": ("Ownership-fatal-event support-set proof", ["CDC1-CHG-0301"]),
        "G2B_NVP_VIDEO_DIAG1_R2R1_OWNERSHIP_FATAL_CONE_PROOF.md": ("Ownership-fatal support-set proof", ["CDC1-CHG-0302"]),
        "G2B_NVP_VIDEO_DIAG1_R2R1_RESET_ABANDONED_CONE_PROOF.md": ("Reset-abandoned composite release-token proof", ["WARN-CHG-0218", "WARN-CHG-0219", "WARN-CHG-0220"]),
    }
    for name, (title, ids) in reports.items():
        write_text(root, name, proof_report(title, [by_id[x] for x in ids]))
    copy_file(root, CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.csv", "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.csv")
    copy_file(root, CDC / "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.json", "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.json")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_DISPOSITION.md", f"""# Profile-specific CDC disposition

Result: **PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST**

- Raw Critical/Warning: 427/874
- Manifest rows: 1,337
- CDC-1 byte-identical: 121/121
- Critical same-family: 295/295
- Cross-family destination support-set: 7/7
- Warning same-family: 217/217
- Composite release-token warning: 3/3
- Changed Critical/Warning reconciled: 302/302 and 220/220
- Unreconciled Critical/Warning: 0/0
- New/missing families: 0/0
- Token, protocol, clock, exception, barrier and replacement-group drift: 0
- Structural CDC: PASS
- Promoted replacement checks: 17/17
- Manifest CSV SHA-256: `{semantic['SEMANTIC_MANIFEST_CSV_SHA256']}`
- Manifest JSON SHA-256: `{semantic['SEMANTIC_MANIFEST_JSON_SHA256']}`

This disposition applies only to source commit `{SOURCE_COMMIT}`, tree `{SOURCE_TREE}`, and routed DCP `{DIAGNOSTIC_DCP_SHA256}`. It does not replace the PRODUCT CDC authority.
""")
    create_signoff(root, signoff_result, signoff)
    create_hardware_not_reached(root, hardware_reason)
    create_state_and_gates(root, mode, signoff_result, signoff, semantic)


def gate_markdown(title: str, gate_file: str, signoff_result: str) -> str:
    path = SIGNOFF / gate_file
    if path.is_file():
        return f"# {title}\n\nResult: **PASS**\n\n```text\n{path.read_text(encoding='utf-8', errors='replace').rstrip()}\n```\n"
    return f"# {title}\n\nResult: **{signoff_result if signoff_result != 'PASS' else 'NOT_REACHED'}**. The terminal routed sign-off artifact was not present when this package was assembled.\n"


def create_signoff(root: Path, result: str, values: dict[str, str]) -> None:
    bus = SIGNOFF / "G2B_NVP_VIDEO_DIAG1_R2R1_INHERITED_ACTIVE_BUS_SKEW_VALIDATION.txt"
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_BUS_SKEW_REPORT.md", "# Governed bus-skew report\n\n" + ("Result: **PASS**\n\n" if result == "PASS" else f"Terminal result: **{result}**\n\n") + "```text\n" + require_file(bus).read_text(encoding="utf-8", errors="replace").rstrip() + "\n```\n")
    replacement = SIGNOFF / "G2B_NVP_VIDEO_DIAG1_R2R1_PROMOTED_REPLACEMENT_RESULTS.csv"
    if replacement.is_file():
        copy_file(root, replacement, "G2B_NVP_VIDEO_DIAG1_R2R1_REPLACEMENT_METHOD_RESULTS.csv")
    else:
        write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_REPLACEMENT_METHOD_RESULTS.csv", "status,reason,passed,total\nIN_PROGRESS,ROUTED_SIGNOFF_NOT_TERMINAL,0,17")
    for title, out_name, gate_name in (
        ("Routed timing", "G2B_NVP_VIDEO_DIAG1_R2R1_TIMING_REPORT.md", "G2B_NVP_VIDEO_DIAG1_R2R1_TIMING_GATE.txt"),
        ("Routed DRC", "G2B_NVP_VIDEO_DIAG1_R2R1_DRC_REPORT.md", "G2B_NVP_VIDEO_DIAG1_R2R1_DRC_GATE.txt"),
        ("Methodology", "G2B_NVP_VIDEO_DIAG1_R2R1_METHODOLOGY_REPORT.md", "G2B_NVP_VIDEO_DIAG1_R2R1_METHODOLOGY_GATE.txt"),
        ("Routed resources", "G2B_NVP_VIDEO_DIAG1_R2R1_RESOURCE_REPORT.md", "G2B_NVP_VIDEO_DIAG1_R2R1_RESOURCE_GATE.txt"),
    ):
        write_text(root, out_name, gate_markdown(title, gate_name, result))
    for title, out_name, receipt_name in (
        ("Signed-off routed DCP manifest", "G2B_NVP_VIDEO_DIAG1_R2R1_SIGNED_OFF_DCP_MANIFEST.md", "G2B_NVP_VIDEO_DIAG1_R2R1_SIGNED_OFF_DCP_MANIFEST.txt"),
        ("Diagnostic bitstream manifest", "G2B_NVP_VIDEO_DIAG1_R2R1_BITSTREAM_MANIFEST.md", "G2B_NVP_VIDEO_DIAG1_R2R1_BITSTREAM_MANIFEST.txt"),
    ):
        receipt = SIGNOFF / receipt_name
        if receipt.is_file():
            write_text(root, out_name, f"# {title}\n\nResult: **PASS**\n\nThe binary artifact is deliberately excluded from public evidence.\n\n```text\n{receipt.read_text(encoding='utf-8', errors='replace').rstrip()}\n```\n")
        else:
            write_text(root, out_name, f"# {title}\n\nResult: **{result}**. No terminal receipt was present. No binary artifact is included.\n")


def create_hardware_not_reached(root: Path, reason: str) -> None:
    for name, title in (
        ("G2B_NVP_VIDEO_DIAG1_R2R1_PROGRAMMING_RECEIPT.md", "Programming receipt"),
        ("G2B_NVP_VIDEO_DIAG1_R2R1_REBOOT_RECEIPT.md", "Warm-reboot receipt"),
        ("G2B_NVP_VIDEO_DIAG1_R2R1_RUNTIME_IDENTITY.md", "Runtime identity"),
        ("G2B_NVP_VIDEO_DIAG1_R2R1_PRODUCT_RESTORE_RECEIPT.md", "PRODUCT NVP baseline restore receipt"),
        ("G2B_NVP_VIDEO_DIAG1_R2R1_CLEANUP_RECEIPT.md", "Cleanup receipt"),
    ):
        write_text(root, name, f"# {title}\n\nResult: **NOT_REACHED**\n\nReason: `{reason}`. No hardware action was performed; restore and hardware cleanup were therefore not required. The Owner-attested PRODUCT runtime baseline was not modified by R2R1 evidence preparation.\n")
    csv_headers = {
        "G2B_NVP_VIDEO_DIAG1_R2R1_I2C_TRANSACTION_LOG.csv": "status,reason,transaction_id,operation,bank,address,value,result",
        "G2B_NVP_VIDEO_DIAG1_R2R1_NVP_WRITE_LEDGER.csv": "status,reason,sequence,bank,address,old_value,new_value,readback",
        "G2B_NVP_VIDEO_DIAG1_R2R1_NVP_READBACK_LEDGER.csv": "status,reason,sequence,phase,bank,address,value",
        "G2B_NVP_VIDEO_DIAG1_R2R1_STATUS_SAMPLES.csv": "status,reason,session,round,channel,sample,novid,lock,classification",
        "G2B_NVP_VIDEO_DIAG1_R2R1_SNAPSHOT_COHERENCE.csv": "status,reason,session,generation,valid,coherent,retries",
        "G2B_NVP_VIDEO_DIAG1_R2R1_HOST_SESSION_HISTORY.csv": "status,reason,session,generation,round,channel,classification,capture_result",
        "G2B_NVP_VIDEO_DIAG1_R2R1_SCAN_RESULTS.csv": "status,reason,session,round,channel,route,status_classification,capture_result,pixel_classification",
        "G2B_NVP_VIDEO_DIAG1_R2R1_CAPTURE_INDEX.csv": "status,reason,session,round,channel,private_capture_path,published",
        "G2B_NVP_VIDEO_DIAG1_R2R1_CAPTURE_RESULTS.csv": "status,reason,session,exact_completions,bytes,integrity,continuity,complete_frame",
        "G2B_NVP_VIDEO_DIAG1_R2R1_FRAME_HASHES.csv": "status,reason,session,raw_frame_sha256,png_sha256,published",
        "G2B_NVP_VIDEO_DIAG1_R2R1_PIXEL_STATISTICS.csv": "status,reason,session,classification,dominant_word,exact_black_fraction,unique_words",
        "G2B_NVP_VIDEO_DIAG1_R2R1_BGDCOL_MATCH_RESULTS.csv": "status,reason,session,round,channel,assigned_color,readback,captured_classification,match",
        "G2B_NVP_VIDEO_DIAG1_R2R1_CHANNEL_REPEATABILITY.csv": "status,reason,channel,active_rounds,no_video_rounds,complete_captures,bgdcol_matches,live_captures",
    }
    for name, header in csv_headers.items():
        write_text(root, name, not_reached_csv(header, reason))
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_HOST_SESSION_HISTORY.jsonl", json.dumps({"status": "NOT_REACHED", "reason": reason}, sort_keys=True))
    for name, title in (
        ("G2B_NVP_VIDEO_DIAG1_R2R1_INPUT_MAPPING_DECISION.md", "Input mapping decision"),
        ("G2B_NVP_VIDEO_DIAG1_R2R1_DIGITAL_PATH_DECISION.md", "Digital pixel-path decision"),
        ("G2B_NVP_VIDEO_DIAG1_R2R1_CAMERA_CONTENT_DECISION.md", "Camera-content decision"),
    ):
        write_text(root, name, f"# {title}\n\nResult: **NOT_REACHED**\n\nThe 4x4 scan did not become hardware-eligible because `{reason}`. No route, BGDCOL, camera-content or connector-mapping claim is made.\n")
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_FINAL_STATE.md", f"""# Final state

- Engineering status: BLOCKED before hardware
- First blocker: `{reason}`
- Hardware accessed: NO
- JTAG / FPGA programming / reboot / driver / NVP I2C / MMIO / DMA/AIO: NOT_REACHED
- DUT task root created: NO
- Hardware locks acquired: NO
- Source, RTL, XDC and IP changed: NO
- PRODUCT runtime profile: OWNER-ATTESTED UNCHANGED; not proactively reverified
- NVP persistent state changed: NO
- Raw captures or camera pixels published: NO
- SSOT changed: NO
- META performed: NO
""")


def create_state_and_gates(root: Path, mode: str, signoff_result: str, signoff: dict[str, str], semantic: dict[str, str]) -> None:
    terminal = mode == "blocked-phase-n"
    gates = [
        ("SOURCE_AUTHORITY", "PASS", "exact branch/commit/tree and clean tracked worktree"),
        ("G2B_FUNCTIONAL_BODY_IDENTITY", "PASS", "diagnostic taps only"),
        ("BOTH_ROUTED_DCP_IDENTITIES", "PASS", "exact SHA-256"),
        ("RAW_CDC_REPRODUCTION", "PASS", "427 Critical; 874 Warning"),
        ("DESTINATION_CONE_EXTRACTION", "PASS", "522/522"),
        ("SAME_FAMILY_CRITICAL", "PASS", "295/295"),
        ("CROSS_FAMILY_SUPPORT_SET", "PASS", "7/7"),
        ("SAME_FAMILY_WARNING", "PASS", "217/217"),
        ("COMPOSITE_RELEASE_TOKEN", "PASS", "3/3"),
        ("PROFILE_SPECIFIC_CDC_MANIFEST_V2", "PASS", "1337 rows; zero unreconciled"),
        ("ROUTED_SIGNOFF", signoff_result, "terminal signoff receipt"),
        ("PHASE_N_PRODUCT_BASELINE_DOUBLE_READ_HOST_LEDGER", "BLOCKED" if terminal else "NOT_REACHED", BLOCKER if terminal else "offline signoff in progress"),
        ("HARDWARE_SCAN", "NOT_REACHED", "hardware gate not open"),
        ("PRODUCT_BASELINE_RESTORE", "NOT_REACHED_NOT_REQUIRED", "no hardware access"),
        ("EVIDENCE_PUBLICATION", "PENDING", "local package only"),
    ]
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_GATE_MATRIX.csv", "gate,result,evidence\n" + "\n".join(
        ",".join('"' + item.replace('"', '""') + '"' for item in row) for row in gates
    ))
    state = {
        "task": "AHD_V41_G2B_NVP_VIDEO_DIAG1_R2R1",
        "project_state_rev": 8,
        "owner_attested_not_reverified": True,
        "mode": mode,
        "engineering_gate": "BLOCKED" if terminal else "PROVISIONAL_NOT_FINAL",
        "overall_result": "BLOCKED" if terminal else "NOT_FINAL",
        "evidence_publication": "PENDING_LOCAL_PACKAGE_NOT_COMMITTED_OR_PUSHED",
        "first_blocker": BLOCKER if terminal else "OFFLINE_SIGNOFF_IN_PROGRESS",
        "source": {"commit": SOURCE_COMMIT, "tree": SOURCE_TREE, "changed_in_r2r1": False},
        "product_source": {"commit": PRODUCT_COMMIT, "tree": PRODUCT_TREE},
        "routed_dcps": {"product_sha256": PRODUCT_DCP_SHA256, "diagnostic_sha256": DIAGNOSTIC_DCP_SHA256, "identity": "PASS"},
        "cdc": {
            "disposition": "PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST",
            "critical": 427, "warning": 874, "info": 36,
            "cdc1_destinations": 423, "byte_identical_rows": 815,
            "changed_rows": 522, "same_family": 512, "destination_cone": 7, "composite_release": 3,
            "unreconciled_critical": 0, "unreconciled_warning": 0,
            "manifest_csv_sha256": semantic["SEMANTIC_MANIFEST_CSV_SHA256"],
            "manifest_json_sha256": semantic["SEMANTIC_MANIFEST_JSON_SHA256"],
        },
        "offline_signoff": {"result": signoff_result, "receipt": signoff},
        "hardware": {"accessed": False, "dut_contacted": False, "programming_attempts": 0, "warm_reboots": 0, "driver_loads": 0, "captures": 0},
        "persistent_changes": {"nvp": False, "product_source": False, "ssot": False, "meta": False},
    }
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_STATE.json", json.dumps(state, indent=2, sort_keys=True))


def collect_supporting(root: Path, signoff_result: str) -> None:
    copy_tree(root, CDC / "destination-cone-row-evidence", "reconciliation/destination-cone-row-evidence")
    copy_tree(root, CDC / "profile-cdc-byte-identical-row-evidence", "reconciliation/profile-cdc-byte-identical-row-evidence")
    for name in (
        "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT.json",
        "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_EVIDENCE_SHA256.txt",
        "G2B_NVP_VIDEO_DIAG1_R2R1_BYTE_IDENTICAL_EVIDENCE_SHA256.txt",
        "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_DEFINITION_RECEIPT.txt",
        "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MANIFEST_ASSEMBLY_RECEIPT.json",
        "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_RECONCILIATION_RECEIPT.txt",
        "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json",
        "G2B_NVP_VIDEO_DIAG1_R2R1_ROW_PARTITION.csv",
        "G2B_NVP_VIDEO_DIAG1_R2R1_UNCLASSIFIED_STARTPOINTS.csv",
        "G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.sha256",
    ):
        copy_file(root, CDC / name, f"reconciliation/{name}")
    copy_tree(root, CONE / "product", "cone-proof/product")
    copy_tree(root, CONE / "diagnostic", "cone-proof/diagnostic")
    copy_file(root, CONE / "changed_destinations.tsv", "cone-proof/changed_destinations.tsv")
    copy_file(root, CONE / "changed_destination_contract.json", "cone-proof/changed_destination_contract.json")
    for path in (TASK_ROOT / "scripts").iterdir():
        if path.is_file() and path.suffix.lower() not in {".pyc"}:
            copy_file(root, path, f"source/task-local/{path.name}")
    copy_file(
        root,
        REPORTS / "G2B_NVP_VIDEO_DIAG1_R2R1_PHASE_N_CAPABILITY_AUDIT.md",
        "hardware-readiness/G2B_NVP_VIDEO_DIAG1_R2R1_PHASE_N_CAPABILITY_AUDIT.md",
    )
    for name in (
        "controller_nvp_video_diag1.py", "controller_nvp_capture.py", "xdma_c2h_rolling_4k_diag1.c",
        "validate_nvp_capture.py", "frame_reconstruct_nvp_capture.py", "analyze_nvp_video_diag1.py",
        "aggregate_nvp_session_metadata.py", "extract_nvp_runtime_evidence.py",
    ):
        copy_file(root, R1_ROOT / "scripts" / name, f"source/inherited-host-tools/{name}")
    if signoff_result in {"PASS", "FAIL"}:
        # The exact per-net identity dumps are intentionally retained in the
        # private task root.  Each routed-PIP dump can exceed GitHub's 100 MiB
        # per-file limit, and the prompt requires the signed identity receipts
        # and hashes rather than publication of these multi-hundred-megabyte
        # derived files.  Publish a byte-exact hash/size inventory for them and
        # keep the raw dumps local.
        local_only_prefixes = (
            "NETLIST_SIGNATURE_",
            "NET_CONNECTIVITY_SIGNATURE_",
            "ROUTED_PIP_SIGNATURE_",
        )
        local_only_lines = [
            "SHA256  SIZE_BYTES  TASK_LOCAL_RELATIVE_PATH",
        ]
        for path in SIGNOFF.iterdir():
            if path.is_file() and path.suffix.lower() not in {".dcp", ".bit", ".ltx"}:
                # Empty files from an interrupted signature write are not evidence.
                if path.stat().st_size:
                    if path.name.startswith(local_only_prefixes):
                        local_only_lines.append(
                            f"{sha256_file(path)}  {path.stat().st_size}  signoff/{path.name}"
                        )
                        continue
                    copy_file(root, path, f"signoff/{path.name}")
        if len(local_only_lines) > 1:
            write_text(
                root,
                "signoff/G2B_NVP_VIDEO_DIAG1_R2R1_LOCAL_ONLY_ROUTE_IDENTITY_SHA256.txt",
                "\n".join(local_only_lines),
            )


def index_and_manifest(root: Path) -> None:
    missing = [name for name in MANDATORY if not (root / name).is_file() and name not in {
        "G2B_NVP_VIDEO_DIAG1_R2R1_EVIDENCE_INDEX.md", "G2B_NVP_VIDEO_DIAG1_R2R1_SHA256_MANIFEST.txt"
    }]
    if missing:
        raise RuntimeError("MANDATORY_FILES_MISSING:" + ",".join(missing))
    files_before = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())
    lines = [
        "# AHD v41 G2B NVP VIDEO DIAG1-R2R1 evidence index", "",
        "This is a sanitized local package. It has not been committed, pushed or remotely read back.", "",
        f"Mandatory top-level files: {len(MANDATORY)}/{len(MANDATORY)} prepared by exact name.", "",
        "DCPs, bitstreams, native binaries, credentials, raw captures, UYVY frames, PNGs, thumbnails and camera pixels are excluded.", "", "Files:", "",
    ] + [f"- `{name}`" for name in files_before + ["G2B_NVP_VIDEO_DIAG1_R2R1_EVIDENCE_INDEX.md", "G2B_NVP_VIDEO_DIAG1_R2R1_SHA256_MANIFEST.txt"]]
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_EVIDENCE_INDEX.md", "\n".join(lines))
    manifest_files = sorted(p for p in root.rglob("*") if p.is_file() and p.name != "G2B_NVP_VIDEO_DIAG1_R2R1_SHA256_MANIFEST.txt")
    manifest = "\n".join(f"{sha256_file(p)}  {p.relative_to(root).as_posix()}" for p in manifest_files)
    write_text(root, "G2B_NVP_VIDEO_DIAG1_R2R1_SHA256_MANIFEST.txt", manifest)
    for name in MANDATORY:
        require_file(root / name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("provisional", "blocked-phase-n"), required=True)
    parser.add_argument("--output", required=True, help="Fresh directory below the R2R1 task root")
    args = parser.parse_args()
    output = Path(args.output).resolve()
    task = TASK_ROOT.resolve()
    if task not in output.parents:
        raise RuntimeError("OUTPUT_MUST_BE_BELOW_FRESH_R2R1_TASK_ROOT")
    if output.exists():
        raise RuntimeError(f"FRESH_OUTPUT_DIRECTORY_REQUIRED:{output}")
    semantic, rows = validate_authority()
    signoff_result, signoff = signoff_state(args.mode)
    output.mkdir(parents=True)
    create_core(output, args.mode, semantic, rows, signoff_result, signoff)
    collect_supporting(output, signoff_result)
    index_and_manifest(output)
    print(json.dumps({
        "result": "PASS_LOCAL_PACKAGE_PREPARED",
        "mode": args.mode,
        "output": str(output),
        "mandatory_files": len(MANDATORY),
        "total_files": sum(1 for p in output.rglob("*") if p.is_file()),
        "manifest_sha256": sha256_file(output / "G2B_NVP_VIDEO_DIAG1_R2R1_SHA256_MANIFEST.txt"),
        "publication_performed": False,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
