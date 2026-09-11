#!/usr/bin/env python3
"""Fail-closed preflight for the R3 routed-DCP final sign-off.

This script performs only file, Git, and receipt validation.  It does not open
Vivado and cannot generate a checkpoint or bitstream.  The Vivado finalizer
requires the PASS receipt emitted here before it can create either output.
"""

from __future__ import annotations

import csv
import hashlib
import json
import pathlib
import subprocess
import sys


TASK_ROOT = pathlib.Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3_20260910T200154Z")
SOURCE_ROOT = pathlib.Path(r"C:\FPGA\V41_G2B_NVP_VIDEO_DIAG1")
REPORT_ROOT = TASK_ROOT / "reports" / "vivado_full"
CDC_ROOT = TASK_ROOT / "cdc"
SIM_RECEIPT = (
    TASK_ROOT
    / "sim"
    / "r3-complete-iteration2"
    / "NVP_VIDEO_DIAG1_R3_SIMULATION_RECEIPT.txt"
)
ROUTED_DCP = REPORT_ROOT / "G2B_NVP_VIDEO_DIAG1_R3_ROUTED.dcp"
RECEIPT = TASK_ROOT / "reports" / "G2B_NVP_VIDEO_DIAG1_R3_FINALIZER_PREFLIGHT.json"

EXPECTED_BRANCH = "diag/v41-g2b-nvp-video-scan"
EXPECTED_COMMIT = "fc37d815b5d64ef90dfbd99c57ae4cc09567b56f"
EXPECTED_TREE = "cdff3ea9d786141ff9bfd46f7099198324604663"
EXPECTED_DCP_SHA = "5E7791F4A72F7901842B9104C3CA2A5ED71EBFB5C27D0362B8259BA20EA54879"
EXPECTED_SIM_SHA = "737BD2A3B08C627A1252E8E690614FF5E1A1BEF62410DD308DF4D1020602B3A9"
EXPECTED_V3_CSV_SHA = "68CC9892D5423A1F98F65A03A9B9FA9E6FF4795CAB77189BB02A7AD099A0F644"
EXPECTED_V3_JSON_SHA = "A41AB8D0020622D6B3F82A2BF7ED7ABCA64BDC8CB87CACA8A68C7547EF26C9C3"
EXPECTED_RAW_CDC_SHA = "9FF77CF33ED1533868DA60607B655031760B52860E12312D5F09771BD2019E0A"

AUTHORIZED_CHANGED = {
    "rtl/g2b/g2b_nvp_video_diag.sv",
    "tests/nvp_video_diag/check_nvp_video_diag_r3_contract.ps1",
    "tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1",
    "tests/nvp_video_diag/run_nvp_video_diag_r3_sim.ps1",
    "tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv",
    "tests/nvp_video_diag/tb_g2b_nvp_video_diag_axi_integration.sv",
    "tests/nvp_video_diag/tb_g2b_nvp_video_diag_mmio_protocol.sv",
}


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256(path: pathlib.Path) -> str:
    if not path.is_file() or path.stat().st_size == 0:
        fail(f"required file missing or empty: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def require_hash(path: pathlib.Path, expected: str) -> str:
    actual = sha256(path)
    if actual != expected:
        fail(f"SHA-256 mismatch for {path}: expected={expected} actual={actual}")
    return actual


def read_kv(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        result[key.strip()] = value.strip()
    return result


def require_kv(values: dict[str, str], expected: dict[str, str], label: str) -> None:
    for key, wanted in expected.items():
        actual = values.get(key)
        if actual != wanted:
            fail(f"{label} mismatch for {key}: expected={wanted!r} actual={actual!r}")


def git(*args: str) -> str:
    completed = subprocess.run(
        ["git", "--no-optional-locks", "-C", str(SOURCE_ROOT), *args],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def main() -> int:
    if git("branch", "--show-current") != EXPECTED_BRANCH:
        fail("R3 source branch authority mismatch")
    if git("rev-parse", "HEAD") != EXPECTED_COMMIT:
        fail("R3 source commit authority mismatch")
    if git("rev-parse", "HEAD^{tree}") != EXPECTED_TREE:
        fail("R3 source tree authority mismatch")
    if git("status", "--short", "--untracked-files=no"):
        fail("R3 tracked worktree is not clean")

    changed = set(git("diff", "--name-only", "fcab95726761a0666a67e31c283dbdfb9e775074..HEAD").splitlines())
    if changed != AUTHORIZED_CHANGED:
        fail(f"authorized changed-file set mismatch: {sorted(changed)}")

    require_hash(ROUTED_DCP, EXPECTED_DCP_SHA)
    require_hash(SIM_RECEIPT, EXPECTED_SIM_SHA)

    sim = read_kv(SIM_RECEIPT)
    require_kv(
        sim,
        {
            "INHERITED_DIAGNOSTIC_SIMULATION_GATE": "PASS_19_OF_19",
            "NEW_MMIO_AXI_LITE_SIMULATION_GATE": "PASS_6_OF_6",
            "COMPLETE_R3_SIMULATION_GATE": "PASS_25_OF_25",
            "T23_1000_CYCLE_STRESS": "PASS",
            "RESULT": "PASS",
        },
        "simulation receipt",
    )

    provenance = read_kv(REPORT_ROOT / "G2B_BUILD_PROVENANCE.txt")
    require_kv(
        provenance,
        {
            "BUILD_PROFILE": "NVP_VIDEO_DIAGNOSTIC",
            "ENABLE_RTRACK_DIAGNOSTICS": "0",
            "ENABLE_NVP_VIDEO_DIAGNOSTIC": "1",
            "REPOSITORY_HEAD": EXPECTED_COMMIT,
            "REPOSITORY_HEAD_TREE": EXPECTED_TREE,
            "SOURCE_BRANCH": EXPECTED_BRANCH,
            "SOURCE_CLEAN": "PASS",
            "BUILD_FLAGS": "32'h00000402",
            "PART": "xc7a35tcsg325-2",
            "TOP": "ahd_capture_top_xdma",
            "CHECKPOINT_REUSE": "NO",
        },
        "build provenance",
    )

    profile = read_kv(REPORT_ROOT / "G2B_PROFILE_ELABORATION_RECEIPT.txt")
    require_kv(
        profile,
        {
            "BUILD_PROFILE": "NVP_VIDEO_DIAGNOSTIC",
            "PRODUCT_R1I_READ_SERVICE_COUNT": "1",
            "NVP_VIDEO_DIAG_CORE_COUNT": "1",
            "NVP_VIDEO_DIAG_I2C_MASTER_COUNT": "1",
            "PROFILE_ELABORATION_GATE": "PASS",
        },
        "profile receipt",
    )

    architecture = read_kv(REPORT_ROOT / "G2B_NVP_VIDEO_DIAG1_R1_SOURCE_ARCHITECTURE_GATE.txt")
    require_kv(
        architecture,
        {
            "RESULT_STORAGE_ARCHITECTURE_GATE": "PASS",
            "RESULT_WORDS_ARRAY_REFERENCES": "0",
            "BULK_RESULT_TABLE_RESET_LOOPS": "0",
            "ASYNC_128_WORD_MMIO_READ_MUX": "0",
            "ONCHIP_SESSION_HISTORY_ENTRIES": "0",
            "ONCHIP_CURRENT_RESULT_WORDS": "8",
            "ONCHIP_CURRENT_SNAPSHOT_DATA_BITS": "256",
            "DIAG_VERSION": "0x00010002",
            "DIAG_CAPABILITIES": "0x00000BFF",
        },
        "source architecture receipt",
    )

    build = read_kv(REPORT_ROOT / "G2B_BUILD_RESULT.txt")
    require_kv(
        build,
        {
            "SOURCE_COMMIT": EXPECTED_COMMIT,
            "REPOSITORY_HEAD_TREE": EXPECTED_TREE,
            "SYNTHESIS": "PASS",
            "OPTIMIZATION": "PASS",
            "PLACEMENT": "PASS",
            "PHYSICAL_OPTIMIZATION": "PASS",
            "ROUTING": "PASS",
            "FULLY_ROUTED": "1",
            "ERRORS_IN_ROUTES": "0",
            "UNROUTED_NETS": "0",
            "PARTIAL_NETS": "0",
            "TIMING_GATE": "PASS",
            "WNS": "0.192",
            "TNS": "0.0",
            "WHS": "0.015",
            "THS": "0.0",
            "NO_CLOCK_COUNT": "0",
            "UNCONSTRAINED_INTERNAL_ENDPOINTS": "0",
            "DRC_GATE": "PASS",
            "DRC_ERRORS": "0",
            "DRC_CRITICAL_WARNINGS": "0",
            "METHODOLOGY_GATE": "PASS",
            "METHODOLOGY_ERRORS": "0",
            "METHODOLOGY_CRITICAL_WARNINGS": "0",
            "POST_OPT_RESOURCE_GATE": "PASS",
            "POST_OPT_LUT_USED": "19086",
            "ROUTED_LUT_USED": "18674",
            "ROUTED_FF_USED": "20179",
            "ROUTED_BRAM_USED": "26.5",
            "ROUTED_DSP_USED": "0",
            "ROUTED_DCP_SHA256": EXPECTED_DCP_SHA,
            "WRITE_BITSTREAM": "0",
            "HARDWARE_ACCESSED": "NO",
        },
        "fresh build receipt",
    )

    bus = read_kv(REPORT_ROOT / "BUS_SKEW.rpt")
    bus_expected = {
        "ROUTED_DCP_SHA256": EXPECTED_DCP_SHA,
        "FULL_RAW_BUS_SKEW_CONSTRAINTS": "11",
        "BASE_RAW_BUS_SKEW_CONSTRAINTS": "0",
        "FULL_BUS_SKEW_CONSTRAINTS": "11",
        "BASE_BUS_SKEW_CONSTRAINTS": "0",
        "BASE_MAX_DELAY_CONSTRAINTS": "26",
        "BASE_FALSE_PATH_CONSTRAINTS": "30",
        "BASE_CLOCK_GROUP_CONSTRAINTS": "1",
        "RESTORED_BUS_SKEW_CONSTRAINTS": "11",
        "PRE_SETUP_WNS": "0.192",
        "PRE_HOLD_WHS": "0.015",
        "POST_SETUP_WNS": "0.192",
        "POST_HOLD_WHS": "0.015",
        "CLOCK_SIGNATURE_RESTORED": "YES",
        "ROUTE_SIGNATURE_UNCHANGED": "YES",
        "BUS_SKEW_OPERATION_RESULT": "PASS",
        "FULL_TIMING_RESTORATION": "PASS",
        "BUS_SKEW_MET_CONSTRAINTS": "11",
        "BUS_SKEW_VIOLATIONS": "0",
        "BUS_SKEW_GATE": "PASS",
    }
    for group in (1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12):
        bus_expected[f"GROUP_{group}_RESULT"] = "PASS"
        bus_expected[f"GROUP_{group}_NEGATIVE_DISPLAY"] = "0"
        bus_expected[f"GROUP_{group}_VIOLATION_MARKER"] = "0"
    require_kv(bus, bus_expected, "active bus-skew receipt")

    retired = read_kv(REPORT_ROOT / "G2B_FIX1_R1_RETIRED_BUS_SKEW_ABSENCE.txt")
    retired_expected = {f"GROUP_{group}_RETIRED_SET_BUS_SKEW_PRESENT": "NO" for group in (9, 13, 14, 15, 16, 17)}
    retired_expected.update({"RETIRED_RELATIONS_PRESENT": "0", "RESULT": "PASS"})
    require_kv(retired, retired_expected, "retired bus-skew absence")

    promoted_csv = REPORT_ROOT / "G2B_FIX1_R1_PROMOTED_REPLACEMENT_RESULTS.csv"
    with promoted_csv.open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 17 or [int(row["CheckIndex"]) for row in rows] != list(range(1, 18)):
        fail("promoted replacement result cardinality/index mismatch")
    group_counts: dict[int, int] = {}
    promoted_root = REPORT_ROOT / "PROMOTED_REPLACEMENTS"
    for row in rows:
        if row["Result"] != "PASS" or row["RequiredNs"] != "6.000":
            fail(f"promoted replacement check failed: {row}")
        index = int(row["CheckIndex"])
        group = int(row["Group"])
        family = row["Family"]
        group_counts[group] = group_counts.get(group, 0) + 1
        prefix = f"{index:02d}_G{group:02d}_{family}"
        require_hash(promoted_root / f"{prefix}_TIMING.rpt", row["ReportSHA256"])
        require_hash(promoted_root / f"{prefix}_OBJECTS.txt", row["ObjectsSHA256"])
    if group_counts != {9: 3, 13: 2, 14: 3, 15: 3, 16: 3, 17: 3}:
        fail(f"promoted replacement group partition mismatch: {group_counts}")

    matrix_path = REPORT_ROOT / "G2B_FIX1_R1_ALL_GROUPS_1_17_MATRIX.csv"
    with matrix_path.open(newline="", encoding="utf-8-sig") as handle:
        matrix = list(csv.DictReader(handle))
    if len(matrix) != 17 or [int(row["Group"]) for row in matrix] != list(range(1, 18)):
        fail("governed group matrix cardinality mismatch")
    promoted_groups = {9, 13, 14, 15, 16, 17}
    for row in matrix:
        group = int(row["Group"])
        wanted = "PASS_PROMOTED_REPLACEMENT" if group in promoted_groups else "PASS_ACTIVE_BUS_SKEW"
        if row["Result"] != wanted:
            fail(f"governed group {group} did not pass its required method")

    structural = read_kv(REPORT_ROOT / "G2B_FIX1_R1_STRUCTURAL_CDC.txt")
    require_kv(
        structural,
        {
            "OWNERSHIP_CDC": "PASS",
            "RESET_RETURN_CDC": "PASS",
            "RELEASE_SLOT_CDC": "PASS",
            "RESULT": "PASS",
        },
        "structural CDC receipt",
    )

    v3_csv = CDC_ROOT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.csv"
    v3_json = CDC_ROOT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.json"
    require_hash(v3_csv, EXPECTED_V3_CSV_SHA)
    require_hash(v3_json, EXPECTED_V3_JSON_SHA)
    cdc_receipt_path = CDC_ROOT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_RECONCILIATION_RECEIPT.json"
    cdc_receipt = json.loads(cdc_receipt_path.read_text(encoding="utf-8"))
    expected_cdc = {
        "Classification": "PASS_PROFILE_SPECIFIC_DIAGNOSTIC_MANIFEST_V3",
        "Result": "PASS",
        "Rows": 1337,
        "ByteIdenticalRows": 810,
        "ChangedRows": 527,
        "ChangedCriticalRows": 311,
        "ChangedWarningRows": 216,
        "NewDestinations": 0,
        "MissingDestinations": 0,
        "DiagnosticMMIOHierarchyCDCRows": 0,
        "UnreconciledCriticalRows": 0,
        "UnreconciledWarningRows": 0,
        "ManifestCSVSHA256": EXPECTED_V3_CSV_SHA,
        "ManifestJSONSHA256": EXPECTED_V3_JSON_SHA,
        "R3CDCReportSHA256": EXPECTED_RAW_CDC_SHA,
        "PromotedReplacementChecks": "17/17_PASS",
        "DiagnosticTapNoninterference": "PASS",
    }
    for key, wanted in expected_cdc.items():
        if cdc_receipt.get(key) != wanted:
            fail(f"CDC V3 receipt mismatch for {key}: expected={wanted!r} actual={cdc_receipt.get(key)!r}")
    if cdc_receipt.get("ProofClassCounts") != {
        "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE": 3,
        "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE": 25,
        "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE": 499,
    }:
        fail("CDC V3 proof-class counts mismatch")

    signed_dcp = TASK_ROOT / "artifacts" / "G2B_NVP_VIDEO_DIAG1_R3_SIGNED_OFF_ROUTED.dcp"
    bitstream = TASK_ROOT / "artifacts" / "G2B_NVP_VIDEO_DIAG1_R3_MMIO_FIXED_FOUR_CHANNEL_SCAN.bit"
    if signed_dcp.exists() or bitstream.exists():
        fail("R3 signed-off output authority is not fresh")
    if list((TASK_ROOT / "artifacts").glob("*.ltx")):
        fail("unexpected LTX already exists in R3 artifact root")

    result = {
        "Result": "PASS",
        "SourceBranch": EXPECTED_BRANCH,
        "SourceCommit": EXPECTED_COMMIT,
        "SourceTree": EXPECTED_TREE,
        "AuthorizedChangedFiles": sorted(changed),
        "SimulationGate": "25/25_PASS",
        "RoutedDCP": str(ROUTED_DCP),
        "RoutedDCPSHA256": EXPECTED_DCP_SHA,
        "ActiveBusSkewGroups": "11/11_PASS",
        "RetiredGlobalBusSkewRelationsPresent": 0,
        "PromotedReplacementChecks": "17/17_PASS",
        "AllGovernedGroups": "1_TO_17_PASS",
        "CDCDisposition": "PASS_PROFILE_SPECIFIC_DIAGNOSTIC_MANIFEST_V3",
        "SemanticCDCManifestV3SHA256": EXPECTED_V3_CSV_SHA,
        "UnreconciledCriticalCDCRows": 0,
        "UnreconciledWarningCDCRows": 0,
        "DiagnosticMMIOHierarchyCDCRows": 0,
        "CheckpointReuse": "NO",
        "BitstreamAlreadyPresent": False,
        "HardwareAccessed": "NO",
    }
    RECEIPT.parent.mkdir(parents=True, exist_ok=True)
    RECEIPT.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # fail closed with one concise terminal reason
        print(f"R3_FINALIZER_PREFLIGHT_FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
