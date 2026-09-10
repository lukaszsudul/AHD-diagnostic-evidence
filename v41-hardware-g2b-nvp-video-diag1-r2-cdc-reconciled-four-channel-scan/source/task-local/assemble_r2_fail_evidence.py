#!/usr/bin/env python3
"""Assemble the local DIAG1-R2 semantic-CDC hard-fail evidence package.

This is intentionally an offline-only assembler.  It does not contact the DUT,
program hardware, write a bitstream, modify either source repository, commit,
push, or perform a remote read-back.  It creates a fresh sanitized package and
fails closed if the authoritative routed-DCP, CDC manifests, raw counts, or
the prohibited cross-base rows do not match the governed R2 contract.
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
from typing import Iterable


TASK_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2_20260910T064851Z")
PACKAGE_NAME = "v41-hardware-g2b-nvp-video-diag1-r2-cdc-reconciled-four-channel-scan"
OUTPUT = TASK_ROOT / "evidence-staging" / PACKAGE_NAME
SOURCE_REPO = Path(r"C:\FPGA\V41_G2B_NVP_VIDEO_DIAG1")
R1_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z")
R1_REPORTS = R1_ROOT / "reports" / "vivado_full"
PRODUCT_SIGNOFF = Path(r"C:\FPGA\G2B_BT656_FIX1_R1_20260909T090813Z\signoff")
ROUTED_DCP = R1_REPORTS / "G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp"

SOURCE_BRANCH = "diag/v41-g2b-nvp-video-scan"
SOURCE_COMMIT = "fcab95726761a0666a67e31c283dbdfb9e775074"
SOURCE_TREE = "bbf1a5fee70a2eb68bb96305ed10934a1559ca6a"
PRODUCT_BASE_COMMIT = "30b14d13b0b789b62b05ab513eb9578c7c43b11a"
PRODUCT_BASE_TREE = "bdbe39077a03f8945ebdd1ed9e52761fbe787696"
ROUTED_DCP_SHA256 = "45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F"
PRODUCT_CDC1_SHA256 = "A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D"
DIAG_CDC1_SHA256 = "BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99"
R1_EVIDENCE_COMMIT = "2c505d5a198c89c99caefa8215ce9ddee4046216"
FIRST_GATE = "NVP_DIAG1_R2_UNRECONCILED_CDC_SOURCE_FAMILY"
MECHANICAL_REASON = "NVP_DIAG1_R2_PROHIBITED_SOURCE_BASE_DRIFT"

CONTRACT = TASK_ROOT / "scripts" / "g2b_nvp_video_diag1_r2_contract.json"
CDC_DIR = TASK_ROOT / "cdc"
RAW = CDC_DIR / "raw-extraction"
SUMMARY_JSON = CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY.json"
SUMMARY_TXT = CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY.txt"
CRITICAL_CSV = CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_CDC_CRITICAL_RECONCILIATION.csv"
WARNING_CSV = CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_CDC_WARNING_RECONCILIATION.csv"
DESTINATION_CSV = CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_CDC_DESTINATION_COMPARISON.csv"
FAMILY_CSV = CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_SOURCE_FAMILY_DEFINITIONS.csv"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def require_file(path: Path) -> Path:
    if not path.is_file() or path.is_symlink():
        raise RuntimeError(f"REQUIRED_REGULAR_FILE_MISSING:{path}")
    return path


def require_hash(path: Path, expected: str) -> None:
    actual = sha256_file(require_file(path))
    if actual != expected:
        raise RuntimeError(f"SHA256_MISMATCH:{path}:{expected}:{actual}")


def read_csv(path: Path) -> list[dict[str, str]]:
    with require_file(path).open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def git_text(*args: str) -> str:
    result = subprocess.run(
        ["git", "-C", os.fspath(SOURCE_REPO), *args],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if result.returncode:
        raise RuntimeError(f"GIT_IDENTITY_CHECK_FAILED:{args}:{result.returncode}:{result.stderr.strip()}")
    return result.stdout.strip()


def validate_authority(summary: dict[str, object]) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    require_hash(ROUTED_DCP, ROUTED_DCP_SHA256)
    require_hash(
        PRODUCT_SIGNOFF / "G2B_CDC_CRITICAL_CDC_1_CANONICAL.txt",
        PRODUCT_CDC1_SHA256,
    )
    require_hash(
        RAW / "G2B_NVP_VIDEO_DIAG1_R2_CDC_1_PHYSICAL_MANIFEST.txt",
        DIAG_CDC1_SHA256,
    )
    if git_text("branch", "--show-current") != SOURCE_BRANCH:
        raise RuntimeError("SOURCE_BRANCH_MISMATCH")
    if git_text("rev-parse", "HEAD") != SOURCE_COMMIT:
        raise RuntimeError("SOURCE_COMMIT_MISMATCH")
    if git_text("rev-parse", "HEAD^{tree}") != SOURCE_TREE:
        raise RuntimeError("SOURCE_TREE_MISMATCH")
    if git_text("diff", "--name-only") or git_text("diff", "--cached", "--name-only"):
        raise RuntimeError("TRACKED_SOURCE_WORKTREE_NOT_CLEAN")

    expected = {
        "RESULT": "FAIL",
        "FAILURE_LITERAL": MECHANICAL_REASON,
        "CDC_DISPOSITION": "FAIL_NO_SEMANTIC_MANIFEST",
        "ROUTED_DCP_SHA256": ROUTED_DCP_SHA256,
        "PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256": PRODUCT_CDC1_SHA256,
        "DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256": DIAG_CDC1_SHA256,
        "RAW_CRITICAL_COUNT": 427,
        "RAW_WARNING_COUNT": 874,
        "CDC_1_CRITICAL": 423,
        "CDC_10_CRITICAL": 2,
        "CDC_13_CRITICAL": 2,
        "CDC_6_WARNING": 13,
        "CDC_15_WARNING": 861,
        "CDC_1_DESTINATION_ROWS_IDENTICAL": 423,
        "NEW_CDC_1_DESTINATIONS": 0,
        "MISSING_CDC_1_DESTINATIONS": 0,
        "DESTINATION_MULTIPLICITY_DRIFT": 0,
        "CDC_1_BYTE_IDENTICAL_ROWS": 121,
        "CHANGED_CRITICAL_ROWS": 302,
        "CROSS_BASE_CRITICAL_ROWS": 7,
        "SOURCE_BASE_DRIFT_CRITICAL_ROWS": 7,
        "CHANGED_WARNING_ROWS": 220,
        "CROSS_BASE_WARNING_ROWS": 3,
        "SOURCE_BASE_DRIFT_WARNING_ROWS": 3,
        "SOURCE_BASE_DRIFT_TOTAL": 10,
        "FIRST_SOURCE_BASE_DRIFT_ROWID": "CDC1-CHG-0286",
        "DIAGNOSTIC_HIERARCHY_CDC_ROWS": 0,
        "SEMANTIC_MANIFEST_ROW_COUNT": 0,
        "SEMANTIC_MANIFEST_CSV_SHA256": "NOT_EMITTED",
        "SEMANTIC_MANIFEST_JSON_SHA256": "NOT_EMITTED",
    }
    for key, value in expected.items():
        if summary.get(key) != value:
            raise RuntimeError(f"RECONCILIATION_SUMMARY_MISMATCH:{key}:{value!r}:{summary.get(key)!r}")

    critical = read_csv(CRITICAL_CSV)
    warning = read_csv(WARNING_CSV)
    if len(critical) != 302 or len(warning) != 220:
        raise RuntimeError(f"RECONCILIATION_ROW_COUNT_MISMATCH:{len(critical)}:{len(warning)}")
    cross_critical = [
        row for row in critical
        if row["Disposition"].startswith("FAIL_SOURCE_BASE_DRIFT_PROHIBITED:")
    ]
    cross_warning = [
        row for row in warning
        if row["Disposition"].startswith("FAIL_SOURCE_BASE_DRIFT_PROHIBITED:")
    ]
    if len(cross_critical) != 7 or len(cross_warning) != 3:
        raise RuntimeError(f"PROHIBITED_CROSS_BASE_COUNT_MISMATCH:{len(cross_critical)}:{len(cross_warning)}")
    first = cross_critical[0]
    first_expected = {
        "RowID": "CDC1-CHG-0286",
        "ProductPhysicalSource": "G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C",
        "DiagnosticPhysicalSource": "G2B_ONECH_C2H/axis_slot_reg[1]/C",
        "DestinationEndpoint": "G2B_ONECH_C2H/enable_applied_source_reg/D",
    }
    for key, value in first_expected.items():
        if first.get(key) != value:
            raise RuntimeError(f"FIRST_PROHIBITED_ROW_MISMATCH:{key}:{value}:{first.get(key)}")
    return cross_critical, cross_warning


def write_text(relative: str, text: str) -> None:
    target = OUTPUT.joinpath(*PurePosixPath(relative).parts)
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() or target.is_symlink():
        raise RuntimeError(f"FRESH_OUTPUT_REQUIRED:{target}")
    with target.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text.rstrip() + "\n")


def write_json(relative: str, data: object) -> None:
    write_text(relative, json.dumps(data, indent=2, ensure_ascii=False))


def copy_text(source: Path, relative: str) -> None:
    source = require_file(source)
    data = source.read_bytes()
    if b"\x00" in data:
        raise RuntimeError(f"BINARY_PUBLICATION_REFUSED:{source}")
    try:
        data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise RuntimeError(f"NON_UTF8_PUBLICATION_REFUSED:{source}") from exc
    target = OUTPUT.joinpath(*PurePosixPath(relative).parts)
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() or target.is_symlink():
        raise RuntimeError(f"FRESH_OUTPUT_REQUIRED:{target}")
    with source.open("rb") as read_handle, target.open("xb") as write_handle:
        shutil.copyfileobj(read_handle, write_handle, 1024 * 1024)


def csv_not_reached(header: Iterable[str], reason: str) -> str:
    fields = list(header)
    values = ["NOT_REACHED"] + [reason] + ["" for _ in fields[2:]]
    rows = [fields, values]
    return "\n".join(",".join('"' + value.replace('"', '""') + '"' for value in row) for row in rows)


def cross_base_table(rows: list[dict[str, str]]) -> str:
    lines = [
        "| Row | Product physical source | Diagnostic physical source | Destination | Disposition |",
        "|---|---|---|---|---|",
    ]
    for row in rows:
        lines.append(
            f"| `{row['RowID']}` | `{row['ProductPhysicalSource']}` | "
            f"`{row['DiagnosticPhysicalSource']}` | `{row['DestinationEndpoint']}` | "
            f"`{row['Disposition']}` |"
        )
    return "\n".join(lines)


def create_required(summary: dict[str, object], cross_critical: list[dict[str, str]], cross_warning: list[dict[str, str]]) -> None:
    first_detail = (
        "CDC1-CHG-0286: PRODUCT release_epoch_axi_reg[0][9]/C -> diagnostic "
        "axis_slot_reg[1]/C at G2B_ONECH_C2H/enable_applied_source_reg/D"
    )
    main = f"""# AHD v41 G2B NVP VIDEO DIAG1-R2 main report

Engineering gate: **FAIL**

Overall result: **FAIL**

Evidence publication: **PENDING — local package prepared, no commit or push performed by this assembler**

The exact source branch, commit and tree passed the minimal authority check. The
exact routed DCP passed SHA-256 identity and reopened read-only in Vivado 2025.2.
The complete raw CDC report reproduced the governed counts: 427 Critical rows
(423 CDC-1, 2 CDC-10, 2 CDC-13) and 874 Warning rows (13 CDC-6, 861 CDC-15).
All 423 CDC-1 destinations and their multiplicities were preserved; CDC-10 and
CDC-13 remained byte-identical; rule, severity, clock-pair, exception and
destination drift were zero.

The semantic reconciliation then encountered a governed hard failure. Seven
changed CDC-1 rows replace a `release_epoch_axi_reg` physical source with an
`axis_slot_reg` physical source, and three changed CDC-15 rows replace a
`release_generation_axi_reg` source with a `release_epoch_axi_reg` source.
These are different signal base names and different declared semantic source
families. R2 explicitly forbids normalizing different bus base names. The first
failed row is `{first_detail}`.

First failed gate: `FAIL — {FIRST_GATE}`.

Mechanical reason: `{MECHANICAL_REASON}`.

No profile-specific semantic manifest was created. The remaining R2 sign-off,
signed-off DCP write, bitstream generation, hardware eligibility, DUT contact,
JTAG, FPGA programming, reboot, driver load, NVP I2C, MMIO, DMA/AIO, capture,
baseline restore and hardware cleanup were not reached. The Owner-attested
PRODUCT runtime state therefore remains unchanged.
"""
    write_text("V41_G2B_NVP_VIDEO_DIAG1_R2_MAIN_REPORT.md", main)

    write_text("G2B_NVP_VIDEO_DIAG1_R2_OWNER_AUTHORIZATION.md", f"""# Owner authorization

PROJECT_STATE_REV: 8 — OWNER_ATTESTED_NOT_REVERIFIED

The Owner granted profile-specific semantic CDC reconciliation, exact routed-DCP
reopen authority, and hardware authority only after complete offline sign-off.
The environment was not broadly requalified. The authority expressly prohibited
general source-name normalization, normalization across different bus base names,
waivers, suppression, RTL/XDC/IP changes, or rebuilding for a different physical
representative selection.

Hardware authorization state: **GRANTED_AFTER_OFFLINE_SIGNOFF; NOT ACTIVATED**.
Offline sign-off failed at `{FIRST_GATE}` before hardware eligibility.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_SCOPE.md", """# Scope and execution boundary

R2 performed only minimal source identity, exact routed-DCP identity, read-only
raw CDC extraction and fail-closed semantic reconciliation. Source, RTL, XDC,
IP, ABI and PRODUCT MMIO were unchanged. No synthesis, optimization, placement,
routing, constraint mutation, seed change, bitstream write, DUT contact or
hardware operation occurred.

The execution stopped at the first semantic CDC hard failure. Later sign-off and
all hardware phases are recorded as NOT_REACHED rather than inferred.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_PREVIOUS_R1_INHERITANCE.md", f"""# DIAG1-R1 inheritance

- R1 evidence commit: `{R1_EVIDENCE_COMMIT}`
- Diagnostic source commit: `{SOURCE_COMMIT}`
- Diagnostic source tree: `{SOURCE_TREE}`
- R1 simulation: 19/19 PASS (inherited)
- R1 fully routed: YES (inherited)
- R1 WNS/TNS: +0.109 ns / 0.000 ns (inherited)
- R1 WHS/THS: +0.036 ns / 0.000 ns (inherited)
- R1 routed resources: LUT 18677/20800, FF 20173/41600, BRAM 26.5/50, DSP 0/90 (inherited)
- R1 active bus skew: 11/11 PASS (inherited)
- R1 promoted replacement methods: 17/17 PASS (inherited)
- R1 structural CDC: PASS (inherited)

These inherited results were not downgraded. R2's required post-reconciliation
re-execution was not reached because semantic reconciliation failed first.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_ROUTED_DCP_AUTHORITY.md", f"""# Routed DCP authority

- Path: `{ROUTED_DCP}`
- Size: {ROUTED_DCP.stat().st_size} bytes
- SHA-256: `{ROUTED_DCP_SHA256}`
- Identity: PASS
- Opened with: Vivado 2025.2, read-only extraction harness
- Routable nets: 36180
- Fully routed nets: 36180
- Unrouted nets: 0
- Partially routed nets: 0
- Report-only clock signature unchanged: YES
- Report-only netlist signature unchanged: YES
- Report-only route signature unchanged: YES
- Synthesis/opt/place/phys-opt/route operations: 0
- Constraint or in-memory netlist modification: NO

The multi-gigabyte pre/post route-signature text expansions are intentionally
excluded from publication. Their local paths and sizes are recorded in
`raw-cdc/SIGNATURE_EXCLUSION_RECEIPT.json`; the authoritative DCP hash is the
identity gate used by this stopped run.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_RAW_CDC_REPRODUCTION.md", f"""# Raw CDC reproduction

Result: **PASS**

| Severity/rule | Count |
|---|---:|
| Critical total | 427 |
| CDC-1 Critical | 423 |
| CDC-10 Critical | 2 |
| CDC-13 Critical | 2 |
| Warning total | 874 |
| CDC-6 Warning | 13 |
| CDC-15 Warning | 861 |

Raw CDC report SHA-256: `{summary['DIAGNOSTIC_CDC_REPORT_SHA256']}`.
Diagnostic CDC-1 physical manifest SHA-256: `{DIAG_CDC1_SHA256}`.
All expected counts and hashes reproduced exactly.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_PRODUCT_PHYSICAL_CDC_MANIFEST.md", f"""# PRODUCT physical CDC authority

- Profile: PRODUCT
- CDC-1 physical manifest source: `{PRODUCT_SIGNOFF / 'G2B_CDC_CRITICAL_CDC_1_CANONICAL.txt'}`
- CDC-1 physical manifest SHA-256: `{PRODUCT_CDC1_SHA256}`

This authority remains unchanged and was not overwritten by the diagnostic
manifest.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_DIAGNOSTIC_PHYSICAL_CDC_MANIFEST.md", f"""# Diagnostic physical CDC authority

- Profile: NVP_VIDEO_DIAGNOSTIC_R1
- Source commit: `{SOURCE_COMMIT}`
- Source tree: `{SOURCE_TREE}`
- Routed DCP SHA-256: `{ROUTED_DCP_SHA256}`
- CDC-1 physical manifest SHA-256: `{DIAG_CDC1_SHA256}`

This physical manifest is bound only to the exact source and routed DCP above.
It was reproduced exactly. It was **not** promoted to a semantic manifest
because the source-family gate failed.
""")

    copy_text(FAMILY_CSV, "G2B_NVP_VIDEO_DIAG1_R2_SOURCE_FAMILY_DEFINITIONS.csv")
    copy_text(CRITICAL_CSV, "G2B_NVP_VIDEO_DIAG1_R2_CDC_CRITICAL_RECONCILIATION.csv")
    copy_text(WARNING_CSV, "G2B_NVP_VIDEO_DIAG1_R2_CDC_WARNING_RECONCILIATION.csv")
    copy_text(DESTINATION_CSV, "G2B_NVP_VIDEO_DIAG1_R2_CDC_DESTINATION_COMPARISON.csv")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_CDC_PROTOCOL_PROOF.md", f"""# CDC protocol and semantic source-family disposition

Destination/rule/severity/clock/exception preservation: PASS.

Changed critical rows: 302. Changed warning rows: 220. The run stopped before a
522-row cone proof could establish the same-base candidates. Accordingly, zero
changed rows are represented as formally reconciled in the fail-closed CSVs.

## Prohibited Critical cross-base rows (7)

{cross_base_table(cross_critical)}

## Prohibited Warning cross-base rows (3)

{cross_base_table(cross_warning)}

The 7 Critical rows cross `RELEASE_EPOCH_STABLE_PAYLOAD` to
`OWNERSHIP_STABLE_PAYLOAD`. The 3 Warning rows cross
`RELEASE_SLOT_STABLE_PAYLOAD` to `RELEASE_EPOCH_STABLE_PAYLOAD`. R2 section 4
explicitly prohibits normalization of different bus base names and section 13
forbids acceptance when the semantic source base differs. No composite family
was authorized. These ten rows are therefore deterministically unreconcilable
under the R2 contract, independent of whether the remaining same-base rows could
have passed a later cone proof.

Formal result: **FAIL — {FIRST_GATE}**.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_DIAGNOSTIC_HIERARCHY_EXCLUSION.md", """# Diagnostic hierarchy exclusion

Complete raw CDC report search: PASS, 0 diagnostic-hierarchy CDC rows.

The later row-by-row fan-in/fan-out cone campaign was not reached after the
prohibited cross-base source-family failure. No claim is made that a report-only
name search substitutes for that unexecuted cone proof.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_STRUCTURAL_CDC_REPORT.md", f"""# Structural CDC report

- Accepted R1 structural CDC receipt: PASS
- Receipt SHA-256: `{summary['STRUCTURAL_RECEIPT_SHA256']}`
- R2 post-semantic-reconciliation rerun: NOT_REACHED

The inherited PASS remains valid, but it cannot cure or waive the R2 source-base
semantic discrepancy.
""")
    copy_text(
        R1_REPORTS / "G2B_FIX1_R1_PROMOTED_REPLACEMENT_RESULTS.csv",
        "G2B_NVP_VIDEO_DIAG1_R2_PROMOTED_REPLACEMENT_RESULTS.csv",
    )

    write_text("G2B_NVP_VIDEO_DIAG1_R2_SEMANTIC_CDC_MANIFEST.csv", "status,reason,row_count\nNOT_CREATED,NVP_DIAG1_R2_UNRECONCILED_CDC_SOURCE_FAMILY,0")
    write_json("G2B_NVP_VIDEO_DIAG1_R2_SEMANTIC_CDC_MANIFEST.json", {
        "artifact_status": "NOT_CREATED",
        "is_governed_semantic_manifest": False,
        "reason": FIRST_GATE,
        "mechanical_reason": MECHANICAL_REASON,
        "row_count": 0,
        "first_failed_row": "CDC1-CHG-0286",
    })
    write_text("G2B_NVP_VIDEO_DIAG1_R2_CDC_DISPOSITION.md", f"""# Formal CDC disposition

CDC disposition: **FAIL**

Profile-specific semantic manifest: **NOT_CREATED**

Changed Critical reconciliation: 0/302 formally completed; 7 rows are
prohibited cross-base drift. Changed Warning reconciliation: 0/220 formally
completed; 3 rows are prohibited cross-base drift. The remaining changed rows
were not advanced to PASS after the first hard failure.

First failed gate: `FAIL — {FIRST_GATE}`.
First row: `{first_detail}`.
""")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_TIMING_REPORT.md", """# Timing report

R2 complete routed timing after semantic reconciliation: **NOT_REACHED**.

Accepted inherited R1 observations: WNS +0.109 ns, TNS 0.000 ns, WHS +0.036 ns,
THS 0.000 ns, fully routed. These observations do not substitute for the R2
ordered gate that was intentionally stopped before execution.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_BUS_SKEW_REPORT.md", """# Bus-skew report

R2 active-group execution: **NOT_REACHED (0/11)**.

Accepted inherited R1 authority: 11 active relative bus-skew groups passed
11/11 and 6 retired groups were governed by 17/17 promoted replacement checks.
No retired global bus-skew relation was reconstructed in R2.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_DRC_REPORT.md", """# DRC report

R2 formal DRC after semantic reconciliation: **NOT_REACHED**.

Accepted inherited R1 DRC: PASS, errors 0, critical warnings 0.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_METHODOLOGY_REPORT.md", """# Methodology report

R2 formal methodology gate after semantic reconciliation: **NOT_REACHED**.

Accepted inherited R1 methodology: PASS, errors 0, critical warnings 0.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_RESOURCE_REPORT.md", """# Resource report

R2 ordered resource recheck: **NOT_REACHED**.

Accepted inherited R1 routed resources:

- LUT: 18677 / 20800 (89.793%)
- FF: 20173 / 41600 (48.493%)
- BRAM: 26.5 / 50 (53.000%)
- DSP: 0 / 90 (0.000%)

These inherited figures passed their R1 limits. No R2 implementation changed
the netlist.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_SIGNED_OFF_DCP_MANIFEST.md", f"""# Signed-off DCP manifest

Classification: **NOT_PRODUCED**.

Source routed DCP SHA-256: `{ROUTED_DCP_SHA256}`.
No new signed-off DCP was written because the semantic CDC gate failed. No DCP
binary is included in this evidence package.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_BITSTREAM_MANIFEST.md", """# Bitstream manifest

Diagnostic classification: **NOT_PRODUCED**.

`write_bitstream` calls: 0. Bitstream files: 0. LTX files: 0. Hardware
eligibility was not reached. No bitstream binary is included.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_PROGRAMMING_RECEIPT.md", """# Programming receipt

FPGA SRAM programming: NOT_REACHED. Programming attempts: 0. JTAG access: NO.
Flash programming: NO. Power-cycle: NO.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_REBOOT_RECEIPT.md", """# Reboot receipt

Post-program warm reboot: NOT_REACHED. Warm reboot count: 0. Power-cycle: NO.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_RUNTIME_IDENTITY.md", """# Runtime identity

Runtime diagnostic identity: NOT_REACHED. DIAG_MAGIC and DIAG_VERSION were not
read. No DUT connection was made. Owner-attested final runtime profile remains
the pre-existing BT656_FIX1_R1 PRODUCT candidate in volatile SRAM.
""")

    empty_tables = {
        "G2B_NVP_VIDEO_DIAG1_R2_I2C_TRANSACTION_LOG.csv": (["status", "reason", "transaction_id"], "OFFLINE_SEMANTIC_CDC_FAILURE"),
        "G2B_NVP_VIDEO_DIAG1_R2_NVP_WRITE_LEDGER.csv": (["status", "reason", "bank", "address", "value"], "NO_NVP_WRITE_EXECUTED"),
        "G2B_NVP_VIDEO_DIAG1_R2_NVP_READBACK_LEDGER.csv": (["status", "reason", "bank", "address", "value"], "NO_NVP_READ_EXECUTED"),
        "G2B_NVP_VIDEO_DIAG1_R2_STATUS_SAMPLES.csv": (["status", "reason", "session_id", "sample"], "HARDWARE_SCAN_NOT_REACHED"),
        "G2B_NVP_VIDEO_DIAG1_R2_SNAPSHOT_COHERENCE.csv": (["status", "reason", "session_id", "generation"], "HARDWARE_SCAN_NOT_REACHED"),
        "G2B_NVP_VIDEO_DIAG1_R2_HOST_SESSION_HISTORY.csv": (["status", "reason", "session_id", "round", "channel"], "HARDWARE_SCAN_NOT_REACHED"),
        "G2B_NVP_VIDEO_DIAG1_R2_SCAN_RESULTS.csv": (["status", "reason", "session_id", "classification"], "HARDWARE_SCAN_NOT_REACHED"),
        "G2B_NVP_VIDEO_DIAG1_R2_CAPTURE_INDEX.csv": (["status", "reason", "session_id", "capture_path"], "NO_CAPTURE_EXECUTED"),
        "G2B_NVP_VIDEO_DIAG1_R2_CAPTURE_RESULTS.csv": (["status", "reason", "session_id", "bytes"], "NO_CAPTURE_EXECUTED"),
        "G2B_NVP_VIDEO_DIAG1_R2_FRAME_HASHES.csv": (["status", "reason", "session_id", "raw_sha256", "png_sha256"], "NO_FRAME_RECONSTRUCTED"),
        "G2B_NVP_VIDEO_DIAG1_R2_PIXEL_STATISTICS.csv": (["status", "reason", "session_id", "classification"], "NO_PIXEL_ANALYSIS_EXECUTED"),
        "G2B_NVP_VIDEO_DIAG1_R2_BGDCOL_MATCH_RESULTS.csv": (["status", "reason", "session_id", "assigned", "observed"], "HARDWARE_SCAN_NOT_REACHED"),
        "G2B_NVP_VIDEO_DIAG1_R2_CHANNEL_REPEATABILITY.csv": (["status", "reason", "channel", "rounds"], "HARDWARE_SCAN_NOT_REACHED"),
    }
    for name, (header, reason) in empty_tables.items():
        write_text(name, csv_not_reached(header, reason))
    write_text("G2B_NVP_VIDEO_DIAG1_R2_HOST_SESSION_HISTORY.jsonl", json.dumps({
        "status": "NOT_REACHED",
        "reason": "HARDWARE_SCAN_NOT_REACHED_AFTER_SEMANTIC_CDC_FAILURE",
        "sessions": 0,
    }, separators=(",", ":")))

    for name, title in (
        ("G2B_NVP_VIDEO_DIAG1_R2_INPUT_MAPPING_DECISION.md", "Input mapping decision"),
        ("G2B_NVP_VIDEO_DIAG1_R2_DIGITAL_PATH_DECISION.md", "Digital path decision"),
        ("G2B_NVP_VIDEO_DIAG1_R2_CAMERA_CONTENT_DECISION.md", "Camera content decision"),
    ):
        write_text(name, f"# {title}\n\nResult: **NOT_REACHED**. The 4x4 hardware scan did not become eligible after the semantic CDC hard failure. No camera, route, BGDCOL or pixel-content claim is made.")

    write_text("G2B_NVP_VIDEO_DIAG1_R2_PRODUCT_RESTORE_RECEIPT.md", """# PRODUCT baseline restore receipt

Hardware restore operation: NOT_REACHED / NOT_REQUIRED.

No DUT connection and no NVP I2C read or write occurred. By the accepted owner
continuity, PRODUCT NVP state was never changed by R2 and therefore required no
active restoration.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_CLEANUP_RECEIPT.md", """# Cleanup receipt

Hardware cleanup: NOT_REACHED / NO ACTION REQUIRED.

R2 acquired no hardware locks, opened no XDMA nodes, created no AIO context,
loaded no driver and enabled no stream. Consequently there was no R2 hardware
resource to clean up. No prior lock or process was modified.
""")
    write_text("G2B_NVP_VIDEO_DIAG1_R2_FINAL_STATE.md", f"""# Final state

- Engineering gate: FAIL
- Overall result: FAIL
- First failed gate: `{FIRST_GATE}`
- First failed row: `{first_detail}`
- Semantic manifest: NOT_CREATED
- Signed-off DCP: NOT_PRODUCED
- Diagnostic bitstream: NOT_PRODUCED
- Hardware accessed: NO
- DUT connection: NO
- Programming/reboot/driver/NVP/MMIO/DMA/AIO/capture: NOT_REACHED
- Source, RTL, XDC, IP, ABI, PRODUCT MMIO, PRODUCT source, SSOT: UNCHANGED
- Owner-attested FPGA runtime profile: PRODUCT_PROFILE_UNCHANGED
- Evidence publication: PENDING; local package only
""")

    gates = [
        ("SOURCE_AUTHORITY", "PASS", f"{SOURCE_BRANCH}@{SOURCE_COMMIT}; tree {SOURCE_TREE}; tracked clean"),
        ("ROUTED_DCP_AUTHORITY", "PASS", ROUTED_DCP_SHA256),
        ("RAW_CDC_REPRODUCTION", "PASS", "427 Critical; 874 Warning; exact rule counts and CDC-1 physical hash"),
        ("CDC_DESTINATION_IDENTITY", "PASS", "423/423 CDC-1 destinations; multiplicity drift 0"),
        ("CDC_RULE_SEVERITY_CLOCK_EXCEPTION", "PASS", "all drift counts 0"),
        ("CDC_SOURCE_FAMILY", "FAIL", "7 Critical plus 3 Warning prohibited cross-base source-family changes; first CDC1-CHG-0286"),
        ("CDC_CRITICAL_RECONCILIATION", "FAIL", "0/302 formally reconciled; 7 prohibited; remaining proof stopped"),
        ("CDC_WARNING_RECONCILIATION", "FAIL", "0/220 formally reconciled; 3 prohibited; remaining proof stopped"),
        ("SEMANTIC_CDC_MANIFEST", "NOT_CREATED", FIRST_GATE),
        ("STRUCTURAL_CDC_R2_RERUN", "NOT_REACHED", "R1 inherited receipt PASS"),
        ("PROMOTED_REPLACEMENTS_R2_RERUN", "NOT_REACHED", "R1 inherited 17/17 PASS"),
        ("ACTIVE_BUS_SKEW_R2", "NOT_REACHED", "R1 inherited 11/11 PASS"),
        ("TIMING_DRC_METHODOLOGY_RESOURCE_R2", "NOT_REACHED", "ordered after semantic CDC PASS"),
        ("SIGNED_OFF_DCP", "NOT_REACHED", "not produced"),
        ("BITSTREAM", "NOT_REACHED", "write_bitstream count 0"),
        ("HARDWARE_SCAN", "NOT_REACHED", "offline eligibility not reached"),
        ("ENGINEERING", "FAIL", FIRST_GATE),
        ("EVIDENCE_PUBLICATION", "PENDING_LOCAL_PACKAGE", "no commit, push or remote read-back performed"),
    ]
    gate_lines = ["gate,result,detail"]
    for gate, result, detail in gates:
        gate_lines.append(",".join('"' + value.replace('"', '""') + '"' for value in (gate, result, detail)))
    write_text("G2B_NVP_VIDEO_DIAG1_R2_GATE_MATRIX.csv", "\n".join(gate_lines))

    state = {
        "task": "AHD_V41_G2B_NVP_VIDEO_DIAG1_R2",
        "project_state_rev": 8,
        "owner_attested_not_reverified": True,
        "engineering_gate": "FAIL",
        "overall_result": "FAIL",
        "evidence_publication": "PENDING_LOCAL_PACKAGE_NOT_COMMITTED_OR_PUSHED",
        "first_failed_gate": FIRST_GATE,
        "mechanical_reason": MECHANICAL_REASON,
        "first_failed_row": {
            "row_id": "CDC1-CHG-0286",
            "product_source": "G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C",
            "diagnostic_source": "G2B_ONECH_C2H/axis_slot_reg[1]/C",
            "destination": "G2B_ONECH_C2H/enable_applied_source_reg/D",
        },
        "source": {"branch": SOURCE_BRANCH, "commit": SOURCE_COMMIT, "tree": SOURCE_TREE, "changed_in_r2": False},
        "routed_dcp": {"path": os.fspath(ROUTED_DCP), "sha256": ROUTED_DCP_SHA256, "identity": "PASS"},
        "raw_cdc": {
            "reproduced": "PASS", "critical": 427, "warning": 874,
            "cdc_1_critical": 423, "cdc_10_critical": 2, "cdc_13_critical": 2,
            "cdc_6_warning": 13, "cdc_15_warning": 861,
            "product_cdc1_sha256": PRODUCT_CDC1_SHA256,
            "diagnostic_cdc1_sha256": DIAG_CDC1_SHA256,
        },
        "reconciliation": {
            "cdc1_destinations_identical": 423, "new_destinations": 0, "missing_destinations": 0,
            "destination_multiplicity_drift": 0, "rule_drift": 0, "severity_drift": 0,
            "clock_pair_drift": 0, "exception_drift": 0,
            "changed_critical": 302, "formally_reconciled_critical": 0,
            "prohibited_cross_base_critical": 7,
            "changed_warning": 220, "formally_reconciled_warning": 0,
            "prohibited_cross_base_warning": 3,
            "semantic_manifest": "NOT_CREATED",
        },
        "later_offline_signoff": "NOT_REACHED_AFTER_SEMANTIC_CDC_FAILURE",
        "hardware": {"accessed": False, "dut_contacted": False, "programming_attempts": 0, "warm_reboots": 0, "driver_loads": 0, "captures": 0},
        "persistent_changes": {"nvp": False, "product_source": False, "ssot": False, "meta": False},
    }
    write_json("G2B_NVP_VIDEO_DIAG1_R2_STATE.json", state)


def collect_supporting_evidence() -> None:
    raw_names = [
        "CDC.rpt", "CDC_ROWS_ALL.csv", "CDC_ROWS_CRITICAL.csv", "CDC_ROWS_WARNING.csv",
        "CDC_RULE_COUNTS.csv", "CDC_CLOCK_PAIR_COUNTS.csv", "CDC_EXCEPTION_COUNTS.csv",
        "CDC_VIOLATION_OBJECTS.csv", "CDC_VIOLATION_PROPERTIES_LONG.csv",
        "G2B_NVP_VIDEO_DIAG1_R2_CDC_1_DESTINATION_MANIFEST.txt",
        "G2B_NVP_VIDEO_DIAG1_R2_CDC_1_PHYSICAL_MANIFEST.txt",
        "G2B_NVP_VIDEO_DIAG1_R2_CDC_PHYSICAL_SOURCE_MANIFEST.txt",
        "G2B_NVP_VIDEO_DIAG1_R2_DCP_CDC_EXTRACTION_RECEIPT.txt",
        "ROUTE_STATUS.rpt", "CLOCK_INVENTORY_PRE_CDC.csv", "CLOCK_INVENTORY_POST_CDC.csv",
        "CLOCK_SIGNATURE_PRE_CDC.txt", "CLOCK_SIGNATURE_POST_CDC.txt",
    ]
    for name in raw_names:
        copy_text(RAW / name, f"raw-cdc/diagnostic/{name}")
    copy_text(PRODUCT_SIGNOFF / "CDC.rpt", "raw-cdc/product/CDC.rpt")
    copy_text(PRODUCT_SIGNOFF / "G2B_CDC_CRITICAL_CDC_1_CANONICAL.txt", "raw-cdc/product/G2B_CDC_CRITICAL_CDC_1_CANONICAL.txt")

    for source in (SUMMARY_JSON, SUMMARY_TXT, CDC_DIR / "G2B_NVP_VIDEO_DIAG1_R2_DCP_CONE_EVIDENCE_REQUIREMENTS.json"):
        copy_text(source, f"reconciliation/{source.name}")
    for source in (FAMILY_CSV, CRITICAL_CSV, WARNING_CSV, DESTINATION_CSV):
        copy_text(source, f"reconciliation/{source.name}")
    write_text("reconciliation/INDEPENDENT_SEMANTIC_AUDIT_RECEIPT.md", f"""# Independent semantic CDC audit receipt

Verdict: **FAIL — {FIRST_GATE}**.

An independent parse reproduced 423 CDC-1 Critical, 2 CDC-10 Critical,
2 CDC-13 Critical, 13 CDC-6 Warning and 861 CDC-15 Warning rows. It confirmed
302 changed CDC-1 physical sources, 220 changed Warning physical sources,
identical destination/non-source multisets, 7 cross-base Critical rows and
3 cross-base Warning rows.

The first cross-base Critical row is `CDC1-CHG-0286`:
`release_epoch_axi_reg[0][9]/C` to `axis_slot_reg[1]/C`, destination
`G2B_ONECH_C2H/enable_applied_source_reg/D`.

The categorical R2 prohibitions against different bus-base normalization and
different semantic source bases apply before any optional cone argument. The
audit therefore confirms that cone evidence cannot override this hard failure.

- PRODUCT CDC report SHA-256: `{sha256_file(PRODUCT_SIGNOFF / 'CDC.rpt')}`
- Diagnostic CDC report SHA-256: `{sha256_file(RAW / 'CDC.rpt')}`
- PRODUCT CDC-1 manifest SHA-256: `{PRODUCT_CDC1_SHA256}`
- Diagnostic CDC-1 manifest SHA-256: `{DIAG_CDC1_SHA256}`
""")

    authority_names = [
        "G2B_FIX1_R1_STRUCTURAL_CDC.txt",
        "G2B_FIX1_R1_PROMOTED_REPLACEMENT_RESULTS.csv",
        "G2B_FIX1_R1_ALL_GROUPS_1_17_MATRIX.csv",
        "G2B_FIX1_R1_RETIRED_BUS_SKEW_ABSENCE.txt",
        "BUS_SKEW.rpt", "DRC.rpt", "METHODOLOGY.rpt", "ROUTED_UTILIZATION_FLAT.rpt",
    ]
    for name in authority_names:
        copy_text(R1_REPORTS / name, f"inherited-r1-authority/{name}")

    task_sources = [
        "g2b_nvp_video_diag1_r2_contract.json",
        "validate_g2b_nvp_video_diag1_r2_contract.py",
        "g2b_nvp_video_diag1_r2_extract.tcl",
        "g2b_nvp_video_diag1_r2_signoff.tcl",
        "reconcile_cdc_semantic.py",
        "assemble_r2_fail_evidence.py",
    ]
    for name in task_sources:
        copy_text(TASK_ROOT / "scripts" / name, f"source/task-local/{name}")
    host_sources = [
        "controller_nvp_video_diag1.py",
        "controller_nvp_capture.py",
        "extract_nvp_runtime_evidence.py",
        "aggregate_nvp_session_metadata.py",
        "analyze_nvp_video_diag1.py",
        "frame_reconstruct_nvp_capture.py",
        "validate_nvp_capture.py",
        "xdma_c2h_rolling_4k_diag1.c",
    ]
    for name in host_sources:
        copy_text(R1_ROOT / "scripts" / name, f"source/inherited-host-tools/{name}")

    route_files = [RAW / "ROUTE_SIGNATURE_PRE_CDC.txt", RAW / "ROUTE_SIGNATURE_POST_CDC.txt"]
    exclusion = {
        "classification": "PUBLICATION_SIZE_EXCLUSION_NO_LOSS_OF_GOVERNED_DCP_IDENTITY",
        "reason": "multi-gigabyte expanded route signatures excluded by task direction",
        "authoritative_routed_dcp_sha256": ROUTED_DCP_SHA256,
        "excluded": [
            {"path": os.fspath(path), "bytes": require_file(path).stat().st_size}
            for path in route_files
        ],
        "not_in_package": True,
    }
    write_json("raw-cdc/SIGNATURE_EXCLUSION_RECEIPT.json", exclusion)


def write_index_and_manifest(mandatory: list[str]) -> dict[str, object]:
    anticipated = sorted(
        [path.relative_to(OUTPUT).as_posix() for path in OUTPUT.rglob("*") if path.is_file()]
        + ["G2B_NVP_VIDEO_DIAG1_R2_EVIDENCE_INDEX.md", "G2B_NVP_VIDEO_DIAG1_R2_SHA256_MANIFEST.txt"],
        key=str.casefold,
    )
    index_lines = [
        "# AHD v41 G2B NVP VIDEO DIAG1-R2 evidence index",
        "",
        "Engineering gate: **FAIL**.",
        "",
        f"First failed gate: `{FIRST_GATE}`.",
        "",
        "This is a local, sanitized, publication-ready package. It has not been committed, pushed, or remotely read back. The two multi-gigabyte route-signature expansion files, DCPs, bitstreams, native binaries, credentials and camera data are excluded.",
        "",
        f"Mandatory top-level files: {len(mandatory)}/53 present by exact name.",
        "",
        "Files:",
        "",
    ]
    index_lines.extend(f"- `{name}`" for name in anticipated)
    write_text("G2B_NVP_VIDEO_DIAG1_R2_EVIDENCE_INDEX.md", "\n".join(index_lines))

    files = sorted(
        [path for path in OUTPUT.rglob("*") if path.is_file()],
        key=lambda path: path.relative_to(OUTPUT).as_posix().casefold(),
    )
    manifest_lines = [
        f"{sha256_file(path)}  {path.relative_to(OUTPUT).as_posix()}" for path in files
    ]
    write_text("G2B_NVP_VIDEO_DIAG1_R2_SHA256_MANIFEST.txt", "\n".join(manifest_lines))
    return {
        "package": os.fspath(OUTPUT),
        "files_including_manifest": sum(1 for path in OUTPUT.rglob("*") if path.is_file()),
        "manifest_entries": len(manifest_lines),
        "manifest_sha256": sha256_file(OUTPUT / "G2B_NVP_VIDEO_DIAG1_R2_SHA256_MANIFEST.txt"),
    }


def main() -> int:
    if OUTPUT.exists() or OUTPUT.is_symlink():
        raise RuntimeError(f"FRESH_OUTPUT_DIRECTORY_REQUIRED:{OUTPUT}")
    contract = json.loads(require_file(CONTRACT).read_text(encoding="utf-8"))
    mandatory = contract["mandatory_evidence_files"]
    if len(mandatory) != 53 or len(set(mandatory)) != 53:
        raise RuntimeError("MANDATORY_EVIDENCE_CONTRACT_NOT_53_UNIQUE_FILES")
    summary = json.loads(require_file(SUMMARY_JSON).read_text(encoding="utf-8"))
    cross_critical, cross_warning = validate_authority(summary)

    OUTPUT.mkdir(parents=True)
    create_required(summary, cross_critical, cross_warning)
    collect_supporting_evidence()
    package_summary = write_index_and_manifest(mandatory)

    missing = [name for name in mandatory if not (OUTPUT / name).is_file()]
    if missing:
        raise RuntimeError("MANDATORY_FILES_MISSING:" + "|".join(missing))
    prohibited_suffixes = {".bit", ".dcp", ".ko", ".exe", ".dll", ".png", ".uyvy", ".bin"}
    prohibited = [
        path.relative_to(OUTPUT).as_posix() for path in OUTPUT.rglob("*")
        if path.is_file() and path.suffix.casefold() in prohibited_suffixes
    ]
    if prohibited:
        raise RuntimeError("PROHIBITED_PUBLIC_ARTIFACT:" + "|".join(prohibited))
    package_summary.update({
        "engineering_gate": "FAIL",
        "overall_result": "FAIL",
        "evidence_publication": "NOT_RUN",
        "mandatory_top_level_files": len(mandatory),
        "missing_mandatory_files": missing,
        "cross_base_critical_rows": len(cross_critical),
        "cross_base_warning_rows": len(cross_warning),
        "first_failed_row": cross_critical[0]["RowID"],
        "first_failed_gate": FIRST_GATE,
        "hardware_accessed": False,
    })
    print(json.dumps(package_summary, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(json.dumps({"result": "FAIL", "error": f"{type(exc).__name__}:{exc}"}, indent=2), file=sys.stderr)
        raise SystemExit(2)
