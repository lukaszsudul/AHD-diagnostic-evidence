#!/usr/bin/env python3
"""Fail-closed structural verifier for the task-local MODE1 audit/model."""

from __future__ import annotations

import csv
import hashlib
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CANDIDATE = Path(r"C:\FPGA\V41_G2B_NVP_CAMERA_ACQ1_MODE1")
REFERENCE = Path(r"C:\FPGA\G2B_NVP_CAMERA_SCAN0_OFFLINE_20260911T135131Z\reference-repo")
SCAN0 = Path(r"C:\FPGA\G2B_NVP_CAMERA_SCAN0_OFFLINE_20260911T135131Z\evidence-staging")
PDF = Path(
    r"C:\FPGA\V41_G2A_EVIDENCE_REPO\v41-nvp-r1f-phase-complete-observability"
    r"\03_SAFE_PROBE_TARGET\AUTHORITATIVE_REFERENCES\NVP6134C_Rev1_0.pdf"
)
OUT = ROOT / "G2B_NVP_MODE1_VERIFICATION.json"

SOURCE_COMMIT = "dae2aff60141ecdbc0afac08fc0df9a3166f66c6"
SOURCE_TREE = "21e33d481ef637667756caa8015e7fa1b1dd8ebf"
REFERENCE_COMMIT = "081ebbff9a2722d47acf16c680594be43cb179e2"
SOURCE_MANIFEST_SHA = "9537C24203A3A34978E100779A06DEEC9CE984DB3EB0DFE19DC89654BE3BA6B9"
PDF_SHA = "301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46"
SCAN1_RECEIPT = (
    ROOT
    / "inherited-scan1-gate-01"
    / "G2B_NVP_CAMERA_SCAN1_R1_SIMULATION_RECEIPT.txt"
)
SCAN1_RECEIPT_SHA = "28CA649BF0E2151EA8F924114DF58134F7FE75288FECF0E4A1DF49D705A9D86F"
ACQ_RECEIPT = (
    ROOT
    / "inherited-acq-gate-01"
    / "G2B_NVP_ACQ1_COMPAT0_R2_TEST_RECEIPT.txt"
)
ACQ_RECEIPT_SHA = "F8BB98CCAD4B98C54FF32B1B18C3E8CAC2E52802FB143C3DA72053F91A342F5F"

OP_CSV = ROOT / "G2B_NVP_MODE1_CLEANROOM_NO_ACP_OPERATION_MANIFEST.csv"
OP_JSON = ROOT / "G2B_NVP_MODE1_CLEANROOM_NO_ACP_OPERATION_MANIFEST.json"
REG_CSV = ROOT / "G2B_NVP_MODE1_TOUCHED_REGISTER_RECOVERY_MATRIX.csv"
REG_JSON = ROOT / "G2B_NVP_MODE1_TOUCHED_REGISTER_RECOVERY_MATRIX.json"
FAIL_CSV = ROOT / "G2B_NVP_MODE1_FAILURE_INJECTION_MATRIX.csv"
GRAPH_JSON = ROOT / "G2B_NVP_MODE1_DETERMINISTIC_RECOVERY_GRAPH.json"
TEST_CSV = ROOT / "G2B_NVP_MODE1_FOCUSED_24_TEST_RESULTS.csv"
SUMMARY_JSON = ROOT / "G2B_NVP_MODE1_MODEL_SUMMARY.json"
INHERITED_JSON = ROOT / "G2B_NVP_MODE1_INHERITED_TEST_DISPOSITION.json"

ALLOWED_OPERATION_TYPES = {
    "WRITE_FULL",
    "READ_MODIFY_WRITE",
    "WRITE_PULSE",
    "DELAY_FIXED",
    "SOFTWARE_STATE_ONLY",
    "VERIFY_READ",
}
ALLOWED_RECOVERY_CLASSES = {
    "EXACT_READ_RESTORE",
    "MASKED_READ_MODIFY_RESTORE",
    "STABLE_BITS_ONLY_VERIFY",
    "DETERMINISTIC_SEQUENCE_REINIT",
    "PRODUCT_BASELINE_RECONSTRUCTION",
    "PROHIBITED_UNRESOLVED",
}
ORDERED_RECOVERY_CLASSES = [
    "EXACT_READ_RESTORE",
    "MASKED_READ_MODIFY_RESTORE",
    "STABLE_BITS_ONLY_VERIFY",
    "DETERMINISTIC_SEQUENCE_REINIT",
    "PRODUCT_BASELINE_RECONSTRUCTION",
    "PROHIBITED_UNRESOLVED",
]
FAILURE_TYPES = {
    "FAILURE_BEFORE_WRITE",
    "NACK_DURING_WRITE",
    "TIMEOUT_DURING_WRITE",
    "READBACK_MISMATCH",
    "RESET_BETWEEN_OPERATIONS",
    "HOST_ABORT",
    "MMIO_RESET",
}
REQUIRED_STATES = {
    "IDLE_PRODUCT_BASELINE",
    "BASELINE_CAPTURED",
    "MODE_APPLY_IN_PROGRESS",
    "MODE_APPLIED",
    "EQ_APPLY_IN_PROGRESS",
    "EQ_APPLIED",
    "LOCK_WAIT",
    "BT656_WAIT",
    "SUCCESS_READY",
    "ABORTING",
    "EXACT_RESTORE",
    "NVP_RESET",
    "PRODUCT_AUTOINIT",
    "BASELINE_VERIFY",
    "RECOVERED",
    "FATAL_RECOVERY_FAILURE",
}
EXPECTED_DOCS = {
    "G2B_NVP_MODE1_BANK1_ED_DISPOSITION.md",
    "G2B_NVP_MODE1_BANK9_44_DISPOSITION.md",
    "G2B_NVP_MODE1_INITIAL_EQ_AUDIT.md",
    "G2B_NVP_MODE1_DETERMINISTIC_RECOVERY_GRAPH.md",
    "G2B_NVP_MODE1_PRODUCT_BASELINE_RECONSTRUCTION_GAP.md",
    "G2B_NVP_MODE1_WORKSTREAM_REPORT.md",
}


def csv_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def git(repo: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(repo), *args], text=True, encoding="utf-8"
    ).strip()


checks: list[dict[str, object]] = []


def check(name: str, condition: bool, evidence: object) -> None:
    checks.append({"check": name, "result": "PASS" if condition else "FAIL", "evidence": evidence})


def main() -> int:
    required_files = {
        OP_CSV.name,
        OP_JSON.name,
        REG_CSV.name,
        REG_JSON.name,
        FAIL_CSV.name,
        GRAPH_JSON.name,
        TEST_CSV.name,
        SUMMARY_JSON.name,
        INHERITED_JSON.name,
        *EXPECTED_DOCS,
    }
    check("required artifacts present", all((ROOT / name).is_file() for name in required_files), sorted(required_files))

    op_fields, operations = csv_rows(OP_CSV)
    reg_fields, registers = csv_rows(REG_CSV)
    _, failures = csv_rows(FAIL_CSV)
    test_fields, tests = csv_rows(TEST_CSV)
    op_json = json.loads(OP_JSON.read_text(encoding="utf-8"))
    reg_json = json.loads(REG_JSON.read_text(encoding="utf-8"))
    graph = json.loads(GRAPH_JSON.read_text(encoding="utf-8"))
    summary = json.loads(SUMMARY_JSON.read_text(encoding="utf-8"))
    inherited = json.loads(INHERITED_JSON.read_text(encoding="utf-8"))

    expected_op_fields = [
        "OperationIndex", "OperationID", "SourceSemanticFunction", "Bank", "Register",
        "OperationType", "Value", "Mask", "PreservedBits", "Condition", "DelayBefore",
        "DelayAfter", "RequiredInitialState", "ExpectedReadback", "ReadbackMask",
        "RecoveryClass", "RecoveryAction", "EvidenceAuthority", "Confidence",
        "IncludedInMinimumMode1", "ExclusionReason",
    ]
    check("operation schema exact", op_fields == expected_op_fields, op_fields)
    check("operation count", len(operations) == 176, len(operations))
    check("operation indices contiguous", [int(x["OperationIndex"]) for x in operations] == list(range(1, 177)), "1..176")
    check("operation types allowed", {x["OperationType"] for x in operations} <= ALLOWED_OPERATION_TYPES, sorted({x["OperationType"] for x in operations}))
    check("ACP absent", not any("ACP" in x["OperationID"] or "acp" in x["SourceSemanticFunction"].lower() for x in operations), "no ACP row")
    included = [x for x in operations if x["IncludedInMinimumMode1"] == "YES"]
    excluded = [x for x in operations if x["IncludedInMinimumMode1"] == "NO"]
    check("included and excluded counts", len(included) == 173 and len(excluded) == 3, {"included": len(included), "excluded": len(excluded)})
    check("only software state excluded", all(x["OperationType"] == "SOFTWARE_STATE_ONLY" for x in excluded), [x["OperationID"] for x in excluded])
    delays = [x for x in included if x["OperationType"] == "DELAY_FIXED"]
    check("fixed no-ACP delay", len(delays) == 1 and delays[0]["DelayAfter"] == "35", [(x["OperationIndex"], x["DelayAfter"]) for x in delays])
    check("operation JSON equals CSV", op_json["operations"] == operations, len(op_json["operations"]))

    reg_keys = [(x["Bank"], x["Register"]) for x in registers]
    reg_counts = Counter(x["RecoveryClass"] for x in registers)
    check("register count and uniqueness", len(registers) == 113 and len(set(reg_keys)) == 113, {"rows": len(registers), "unique": len(set(reg_keys))})
    check("one allowed class per register", all(x["RecoveryClass"] in ALLOWED_RECOVERY_CLASSES for x in registers), dict(reg_counts))
    check("conservative recovery counts", reg_counts == Counter({"PROHIBITED_UNRESOLVED": 108, "EXACT_READ_RESTORE": 5}), dict(reg_counts))
    exact_keys = {f'{x["Bank"]}:{x["Register"]}' for x in registers if x["RecoveryClass"] == "EXACT_READ_RESTORE"}
    check("exact safe-read set", exact_keys == {"0x00:0x23", "0x00:0x81", "0x00:0x85", "0x01:0x84", "0x01:0x8C"}, sorted(exact_keys))
    by_key = {f'{x["Bank"]}:{x["Register"]}': x for x in registers}
    check("Bank1/ED prohibited", by_key["0x01:0xED"]["RecoveryClass"] == "PROHIBITED_UNRESOLVED", by_key["0x01:0xED"])
    check("Bank9/44 prohibited", by_key["0x09:0x44"]["RecoveryClass"] == "PROHIBITED_UNRESOLVED", by_key["0x09:0x44"])
    check("register JSON equals CSV", reg_json["registers"] == registers, len(reg_json["registers"]))
    check("recovery class authority order", reg_json["allowed_recovery_classes"] == ORDERED_RECOVERY_CLASSES, reg_json["allowed_recovery_classes"])

    eq = [x for x in operations if "_EQ_INIT_" in x["OperationID"]]
    eq_writes = [x for x in eq if x["OperationID"].endswith("_EQ_INIT_WRITE")]
    eq_values = {(x["Bank"], x["Register"], x["Value"]) for x in eq_writes}
    expected_eq = {
        ("0x05", "0x59", "0x11"), ("0x05", "0xC0", "0x17"),
        ("0x05", "0xC1", "0x13"), ("0x05", "0xC8", "0x04"),
        ("0x0A", "0x74", "0x02"),
    }
    check("initial EQ semantic shape", len(eq) == 9 and len(eq_writes) == 5, {"entries": len(eq), "writes": len(eq_writes)})
    check("initial EQ exact values", eq_values == expected_eq, sorted(eq_values))
    check("initial EQ functional writes unresolved", all(x["RecoveryClass"] == "PROHIBITED_UNRESOLVED" for x in eq_writes), [x["RecoveryClass"] for x in eq_writes])

    per_op: dict[str, set[str]] = defaultdict(set)
    for row in failures:
        per_op[row["OperationIndex"]].add(row["FailureType"])
    terminals = Counter(x["TerminalState"] for x in failures)
    check("failure scenario count", len(failures) == 1211, len(failures))
    check("seven failure types per included op", len(per_op) == 173 and all(v == FAILURE_TYPES for v in per_op.values()), {"operations": len(per_op), "types": sorted(FAILURE_TYPES)})
    check("failure scenario indices contiguous", [int(x["ScenarioIndex"]) for x in failures] == list(range(1, 1212)), "1..1211")
    check("terminal counts exact", terminals == Counter({"FATAL_RECOVERY_FAILURE": 1205, "RECOVERED_PRODUCT_BASELINE": 6}), dict(terminals))
    check("unresolved paths fatal", all(x["TerminalState"] == "FATAL_RECOVERY_FAILURE" for x in failures if int(x["UnresolvedCommittedRegisterCount"]) > 0), "all unresolved committed paths")
    check("reset paths fatal", all(x["TerminalState"] == "FATAL_RECOVERY_FAILURE" for x in failures if x["FailureType"] in {"RESET_BETWEEN_OPERATIONS", "MMIO_RESET"}), "all reset/MMIO-reset paths")

    check("required graph states", REQUIRED_STATES <= set(graph["states"]), sorted(set(graph["states"])))
    check("terminal graph states", set(graph["recovery_terminal_states"]) == {"RECOVERED_PRODUCT_BASELINE", "FATAL_RECOVERY_FAILURE"}, graph["recovery_terminal_states"])
    test_counts = Counter(x["Result"] for x in tests)
    blocked_ids = {x["TestID"] for x in tests if x["Result"] == "BLOCKED"}
    check(
        "focused test count and IDs",
        test_fields == ["TestID", "Requirement", "Result", "Scope", "Evidence"]
        and len(tests) == 24
        and {x["TestID"] for x in tests} == {f"T{i}" for i in range(1, 25)},
        {"fields": test_fields, "count": len(tests)},
    )
    t19_t21 = [row for row in tests if row["TestID"] in {"T19", "T20", "T21"}]
    check(
        "focused test outcomes",
        test_counts == Counter({"PASS": 16, "BLOCKED": 8})
        and blocked_ids == {"T2", "T8", "T16", "T17", "T18", "T19", "T20", "T21"}
        and len(t19_t21) == 3
        and all(row["Result"] == "BLOCKED" for row in t19_t21)
        and all(row.get("Scope") == "MODEL_CONTRACT_DEFINED_NOT_RTL_IMPLEMENTED" for row in t19_t21),
        {"counts": dict(test_counts), "blocked": sorted(blocked_ids), "T19-T21": t19_t21},
    )

    check(
        "summary classification",
        summary["classification"] == "MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE"
        and summary["recovery_disposition"] == "MODE1_RECOVERY_AUTHORITY_INCOMPLETE"
        and summary.get("t19_t21_scope") == "MODEL_CONTRACT_DEFINED_NOT_RTL_IMPLEMENTED"
        and summary.get("focused_test_counts") == {"BLOCKED": 8, "PASS": 16}
        and summary.get("inherited_test_disposition") == "PASS_2_OF_2_INHERITED_GATES"
        and summary.get("inherited_test_status_counts") == {"PASS": 2}
        and summary.get("inherited_test_receipt") == INHERITED_JSON.name,
        {
            "classification": summary["classification"],
            "recovery": summary["recovery_disposition"],
            "T19-T21": summary.get("t19_t21_scope"),
            "focused": summary.get("focused_test_counts"),
            "inherited": summary.get("inherited_test_disposition"),
        },
    )
    check(
        "ACP first-image disposition and non-claim",
        summary.get("acp_required_for_first_image") == "UNRESOLVED"
        and summary.get("acp_first_image_evidence")
        == "NO_AUTHORITY_PROVES_ACP_INDISPENSABLE_AND_NO_AUTHORITY_PROVES_FIRST_IMAGE_WITHOUT_ACP"
        and "ACP required for first image: `UNRESOLVED`"
        in (ROOT / "G2B_NVP_MODE1_WORKSTREAM_REPORT.md").read_text(encoding="utf-8"),
        {
            "summary": summary.get("acp_required_for_first_image"),
            "expected": "UNRESOLVED",
            "evidence": summary.get("acp_first_image_evidence"),
        },
    )
    inherited_by_suite = {row.get("suite"): row for row in inherited.get("suites", [])}
    check(
        "inherited test receipt identity and disposition",
        inherited.get("schema") == "G2B_NVP_MODE1_INHERITED_TEST_DISPOSITION_V1"
        and inherited.get("overall_disposition") == "PASS_2_OF_2_INHERITED_GATES"
        and inherited.get("status_counts") == {"PASS": 2}
        and inherited.get("non_claim")
        == "INHERITED_PASS_DOES_NOT_PROVE_MODE1_T19_T21_RTL_IMPLEMENTATION"
        and set(inherited_by_suite) == {"SCAN1", "ACQ"}
        and inherited_by_suite["SCAN1"].get("status") == "PASS"
        and inherited_by_suite["SCAN1"].get("gate_result") == "24/24 PASS"
        and inherited_by_suite["SCAN1"].get("evidence_path") == str(SCAN1_RECEIPT)
        and inherited_by_suite["SCAN1"].get("evidence_sha256") == SCAN1_RECEIPT_SHA
        and inherited_by_suite["ACQ"].get("status") == "PASS"
        and inherited_by_suite["ACQ"].get("gate_result") == "20/20 PASS"
        and inherited_by_suite["ACQ"].get("evidence_path") == str(ACQ_RECEIPT)
        and inherited_by_suite["ACQ"].get("evidence_sha256") == ACQ_RECEIPT_SHA
        and SCAN1_RECEIPT.is_file()
        and digest(SCAN1_RECEIPT) == SCAN1_RECEIPT_SHA
        and ACQ_RECEIPT.is_file()
        and digest(ACQ_RECEIPT) == ACQ_RECEIPT_SHA,
        {
            "disposition": inherited.get("overall_disposition"),
            "SCAN1": inherited_by_suite.get("SCAN1"),
            "SCAN1_actual_sha256": digest(SCAN1_RECEIPT) if SCAN1_RECEIPT.is_file() else "MISSING",
            "ACQ": inherited_by_suite.get("ACQ"),
            "ACQ_actual_sha256": digest(ACQ_RECEIPT) if ACQ_RECEIPT.is_file() else "MISSING",
        },
    )
    check("summary counts", summary["operation_rows_no_acp"] == 176 and summary["included_operation_count"] == 173 and summary["touched_register_count"] == 113 and summary["initial_eq_write_count"] == 5 and summary["failure_scenario_count"] == 1211, "all exact")
    hash_checks = {name: digest(ROOT / name) for name in summary["output_sha256"]}
    check("summary output hashes", hash_checks == summary["output_sha256"], hash_checks)

    source_manifest = SCAN0 / "G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_MANIFEST.csv"
    check("SCAN0 source manifest identity", digest(source_manifest) == SOURCE_MANIFEST_SHA, digest(source_manifest))
    check("NVP6134C PDF identity", PDF.is_file() and digest(PDF) == PDF_SHA, digest(PDF) if PDF.is_file() else "missing")
    check("candidate source identity", git(CANDIDATE, "rev-parse", "HEAD") == SOURCE_COMMIT and git(CANDIDATE, "rev-parse", "HEAD^{tree}") == SOURCE_TREE, {"head": git(CANDIDATE, "rev-parse", "HEAD"), "tree": git(CANDIDATE, "rev-parse", "HEAD^{tree}")})
    check("candidate worktree untouched", git(CANDIDATE, "status", "--porcelain") == "", git(CANDIDATE, "status", "--porcelain") or "clean")
    check("reference identity", git(REFERENCE, "rev-parse", "HEAD") == REFERENCE_COMMIT and git(REFERENCE, "status", "--porcelain") == "", {"head": git(REFERENCE, "rev-parse", "HEAD"), "status": git(REFERENCE, "status", "--porcelain") or "clean"})

    forbidden_suffixes = {".bit", ".bin", ".dcp", ".ltx", ".rpt", ".jou", ".log"}
    forbidden = sorted(p.name for p in ROOT.iterdir() if p.is_file() and p.suffix.lower() in forbidden_suffixes)
    check("no build bitstream or hardware output", not forbidden, forbidden or "none")

    artifact_hashes = {
        p.name: digest(p)
        for p in sorted(ROOT.iterdir(), key=lambda x: x.name)
        if p.is_file() and p != OUT
    }
    passed = sum(item["result"] == "PASS" for item in checks)
    report = {
        "schema": "G2B_NVP_MODE1_VERIFICATION_V1",
        "result": "PASS" if passed == len(checks) else "FAIL",
        "checks_passed": passed,
        "checks_total": len(checks),
        "operation_rows_no_acp": len(operations),
        "included_operations": len(included),
        "touched_registers": len(registers),
        "recovery_class_counts": dict(sorted(reg_counts.items())),
        "failure_scenarios": len(failures),
        "failure_terminal_counts": dict(sorted(terminals.items())),
        "focused_test_counts": dict(sorted(test_counts.items())),
        "checks": checks,
        "artifact_sha256": artifact_hashes,
    }
    OUT.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({k: report[k] for k in list(report)[:10]}, indent=2))
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
