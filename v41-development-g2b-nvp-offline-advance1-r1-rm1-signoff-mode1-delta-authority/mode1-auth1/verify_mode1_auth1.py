#!/usr/bin/env python3
"""Fail-closed verification of the generated MODE1-AUTH1 evidence set."""

from __future__ import annotations

import csv
import hashlib
import json
import subprocess
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parent
WORKTREE = Path(r"C:\FPGA\V41_G2B_NVP_CAMERA_ACQ1_MODE1")
HEAD = "dae2aff60141ecdbc0afac08fc0df9a3166f66c6"
TREE = "21e33d481ef637667756caa8015e7fa1b1dd8ebf"


def rows(name: str) -> list[dict[str, str]]:
    with (ROOT / name).open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def git(*args: str) -> str:
    return subprocess.check_output(["git", "-C", str(WORKTREE), *args], text=True, encoding="utf-8").strip()


def main() -> None:
    gate = json.loads((ROOT / "MODE1_AUTH1_AUTHORITY_GATE.json").read_text(encoding="utf-8"))
    receipt = json.loads((ROOT / "MODE1_AUTH1_GENERATION_RECEIPT.json").read_text(encoding="utf-8"))
    matrix = rows("MODE1_DIFFERENTIAL_OPERATION_MATRIX.csv")
    actions = rows("MODE1_MINIMAL_FIRST_IMAGE_ACTION_SET.csv")
    recovery = rows("MODE1_MINIMAL_TOUCHED_REGISTER_RECOVERY.csv")
    failure = rows("MODE1_REDUCED_FAILURE_INJECTION_MATRIX.csv")
    allowed_diff = {
        "FINAL_STATE_DELTA", "REQUIRED_WRITE_PULSE", "REQUIRED_SEQUENCE_REWRITE", "REQUIRED_DELAY",
        "SOFTWARE_STATE_ONLY", "OPTIONAL_ACP", "OPTIONAL_ADAPTIVE_EQ",
        "NO_OP_AGAINST_CURRENT_BASELINE", "UNRESOLVED",
    }
    allowed_recovery = {
        "EXACT_READ_RESTORE", "MASKED_READ_MODIFY_RESTORE", "STABLE_BITS_ONLY_VERIFY",
        "DETERMINISTIC_SEQUENCE_REINIT", "PRODUCT_BASELINE_RECONSTRUCTION", "PROHIBITED_UNRESOLVED",
    }
    tests: list[dict[str, object]] = []

    def check(name: str, condition: bool, detail: str) -> None:
        tests.append({"test": name, "result": "PASS" if condition else "FAIL", "detail": detail})

    check("T01_SOURCE_HEAD", git("rev-parse", "HEAD") == HEAD, git("rev-parse", "HEAD"))
    check("T02_SOURCE_TREE", git("rev-parse", "HEAD^{tree}") == TREE, git("rev-parse", "HEAD^{tree}"))
    status = git("status", "--porcelain=v1", "--untracked-files=all")
    check("T03_SOURCE_CLEAN", status == "", status or "CLEAN")
    check("T04_REFERENCE_OPERATION_ROWS", len(matrix) == 211, str(len(matrix)))
    check("T05_EXACTLY_ONE_DIFF_CLASS", all(r["DifferentialClass"] in allowed_diff for r in matrix), "all classes valid")
    diff_counts = Counter(r["DifferentialClass"] for r in matrix)
    check("T06_DIFF_TOTAL", sum(diff_counts.values()) == 211, str(dict(diff_counts)))
    check("T07_FINAL_DELTA_COUNT", diff_counts["FINAL_STATE_DELTA"] == 61, str(diff_counts["FINAL_STATE_DELTA"]))
    check("T08_UNRESOLVED_OPERATION_ZERO", diff_counts["UNRESOLVED"] == 0, str(diff_counts["UNRESOLVED"]))
    check("T09_ACP_EXCLUDED", diff_counts["OPTIONAL_ACP"] == 35, str(diff_counts["OPTIONAL_ACP"]))
    check("T10_ACTION_COUNT", len(actions) == 74, str(len(actions)))
    functional = {(r["Bank"], r["Register"]) for r in actions if r["ActionType"] not in {"BANK_SELECT", "DELAY"}}
    check("T11_FUNCTIONAL_REGISTER_COUNT", len(functional) == 62, str(len(functional)))
    check("T12_TOUCHED_INCLUDING_SELECTOR", len(recovery) == 63, str(len(recovery)))
    check("T13_RECOVERY_CLASSES_VALID", all(r["RecoveryClass"] in allowed_recovery for r in recovery), "all classes valid")
    rec_counts = Counter(r["RecoveryClass"] for r in recovery)
    check("T14_RECOVERY_COUNTS", rec_counts == Counter({"DETERMINISTIC_SEQUENCE_REINIT": 35, "EXACT_READ_RESTORE": 1, "PROHIBITED_UNRESOLVED": 27}), str(dict(rec_counts)))
    check("T15_RECOVERY_COVERAGE", gate["recovery"]["recovery_authority_coverage_percent"] == 57.143, str(gate["recovery"]["recovery_authority_coverage_percent"]))
    check("T16_FAILURE_SCENARIO_COUNT", len(failure) == 592, str(len(failure)))
    per_action = Counter(r["ActionID"] for r in failure)
    check("T17_FAILURE_EIGHT_PER_ACTION", len(per_action) == 74 and set(per_action.values()) == {8}, f"actions={len(per_action)} counts={set(per_action.values())}")
    check("T18_FAILURE_TERMINALS", set(r["TerminalState"] for r in failure) <= {"RECOVERED_PRODUCT_BASELINE", "FATAL_RECOVERY_FAILURE"}, "explicit terminals only")
    check("T19_STRUCTURAL_COVERAGE", gate["failure_injection"]["structural_coverage"] == "100%", gate["failure_injection"]["structural_coverage"])
    check("T20_BANK1_ED", gate["bank1_ed"] == "EXCLUDED_FROM_MINIMAL_MODE1", gate["bank1_ed"])
    check("T21_BANK9_44", gate["bank9_44"] == "EXCLUDED_FROM_MINIMAL_MODE1", gate["bank9_44"])
    check("T22_ACP_DECISION", gate["acp_decision"] == "ACP_NOT_REQUIRED_FOR_FIRST_IMAGE", gate["acp_decision"])
    check("T23_INITIAL_EQ_FAIL_CLOSED", gate["initial_eq_authority"] == "MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE", gate["initial_eq_authority"])
    check("T24_NO_CANDIDATE_BUILD_HARDWARE", gate["implementation_decision"] == "BLOCKED_NO_SOURCE_CANDIDATE" and gate["build_decision"] == "NOT_RUN_AUTHORITY_GATE_FAILED" and not gate["hardware_accessed"], "no candidate/build/hardware")
    check("T25_SCAN1_GENERIC_I2C_BOUNDARY", gate["scan1_read_only"] and gate["generic_host_nvp_i2c"] == "ABSENT", "SCAN1 read-only; generic host I2C absent")
    hash_ok = all((ROOT / name).is_file() and sha(ROOT / name) == expected for name, expected in receipt["output_sha256"].items())
    check("T26_GENERATION_OUTPUT_HASHES", hash_ok, f"{len(receipt['output_sha256'])} output hashes")
    check("T27_GENERATOR_DETERMINISM", sha(ROOT / "MODE1_AUTH1_GENERATION_RECEIPT.json") == "3108121DADD9D996F02182F395FB8F7C441F436F2EE4F12EF1B29762BE29F7F0", "two identical consecutive generation receipts")

    passed = sum(t["result"] == "PASS" for t in tests)
    result = {
        "schema": "MODE1_AUTH1_VERIFICATION_RECEIPT_V1", "result": "PASS" if passed == len(tests) else "FAIL",
        "gate": f"{passed}/{len(tests)} PASS", "tests": tests,
        "source_commit": HEAD, "source_tree": TREE, "candidate_created": False,
        "build_run": False, "hardware_accessed": False,
    }
    (ROOT / "MODE1_AUTH1_VERIFICATION_RECEIPT.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"result": result["result"], "gate": result["gate"]}, indent=2))
    if result["result"] != "PASS":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
