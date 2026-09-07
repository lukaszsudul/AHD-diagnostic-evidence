#!/usr/bin/env python3
"""Fail-closed R3R4R1 to R3R4R2 normalized capture-tool delta audit."""
from __future__ import annotations

import difflib
import hashlib
import json
from pathlib import Path


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R2_20260907T071912Z")
BASE = ROOT / "artifacts" / "published-r3r4r1-baseline" / (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame"
) / "tools"
ACTIVE = ROOT / "scripts"
ARTIFACTS = ROOT / "artifacts"
OLD_EXPECTED = "[False, False, False, False, False, False, True]"
NEW_EXPECTED = "[False, False, False, False, False, True, True]"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalize(text: str, *, selftest: bool = False) -> str:
    replacements = (
        ("R3R4R1", "R3R4RX"),
        ("R3R4R2", "R3R4RX"),
        ("r3r4r1", "r3r4rx"),
        ("r3r4r2", "r3r4rx"),
        ("20260907T050126Z", "RUN_TIMESTAMP"),
        ("20260907T071912Z", "RUN_TIMESTAMP"),
        ("r3r4-c2h-reader", "r3r4rx-c2h-reader"),
        ("T3T4", "T3T4_SESSION"),
        ("T34", "T3T4_SESSION"),
    )
    for old, new in replacements:
        text = text.replace(old, new)
    if selftest:
        text = text.replace(OLD_EXPECTED, "QUIET_WINDOW_EXPECTED_VECTOR")
        text = text.replace(NEW_EXPECTED, "QUIET_WINDOW_EXPECTED_VECTOR")
    return text


def write_text_exclusive(path: Path, text: str) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
        handle.flush()


def main() -> int:
    mappings = (
        ("capture_r3r4.py", "capture_r3r4.py", False, "RUN_IDENTITY_ONLY"),
        ("capture_r3r4_selftest.py", "capture_r3r4_selftest.py", True,
         "QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY"),
        ("frame_reconstruct_r3r4.py", "frame_reconstruct_r3r4.py", False,
         "RUN_IDENTITY_ONLY"),
        ("abi_v1.py", "abi_v1.py", False, "BYTE_IDENTICAL"),
        ("V41_C2H_TRANSPORT_ABI_V1.json",
         "V41_C2H_TRANSPORT_ABI_V1.json", False, "BYTE_IDENTICAL"),
        ("Invoke-R3R4R1DutConnection.ps1",
         "Invoke-R3R4R2DutConnection.ps1", False, "RUN_IDENTITY_ONLY"),
    )
    rows = []
    raw_diffs = []
    overall = True
    for baseline_name, active_name, selftest, allowed in mappings:
        baseline = BASE / baseline_name
        active = ACTIVE / active_name
        baseline_text = baseline.read_text(encoding="utf-8")
        active_text = active.read_text(encoding="utf-8")
        normalized_equal = normalize(baseline_text, selftest=selftest) == normalize(
            active_text, selftest=selftest
        )
        byte_identical = baseline.read_bytes() == active.read_bytes()
        passed = byte_identical if allowed == "BYTE_IDENTICAL" else normalized_equal
        overall &= passed
        rows.append({
            "baseline": baseline_name,
            "active": active_name,
            "allowed_delta": allowed,
            "baseline_sha256": sha256(baseline),
            "active_sha256": sha256(active),
            "byte_identical": byte_identical,
            "normalized_equal": normalized_equal,
            "result": "PASS" if passed else "FAIL",
        })
        raw_diffs.extend(difflib.unified_diff(
            baseline_text.splitlines(keepends=True),
            active_text.splitlines(keepends=True),
            fromfile=f"R3R4R1/{baseline_name}",
            tofile=f"R3R4R2/{active_name}",
        ))

    baseline_selftest = (BASE / "capture_r3r4_selftest.py").read_text(
        encoding="utf-8"
    )
    active_selftest = (ACTIVE / "capture_r3r4_selftest.py").read_text(
        encoding="utf-8"
    )
    capture_baseline = (BASE / "capture_r3r4.py").read_text(encoding="utf-8")
    capture_active = (ACTIVE / "capture_r3r4.py").read_text(encoding="utf-8")
    semantic_checks = {
        "baseline_old_expected_vector_once": baseline_selftest.count(OLD_EXPECTED) == 1,
        "active_new_expected_vector_once": active_selftest.count(NEW_EXPECTED) == 1,
        "active_old_expected_vector_absent": OLD_EXPECTED not in active_selftest,
        "invalid_part_count_gt_records_absent":
            "part_count > len(records)" not in active_selftest,
        "invalid_part_count_lt_records_absent":
            "part_count < len(records)" not in active_selftest,
        "runtime_normalized_byte_equivalent":
            normalize(capture_baseline) == normalize(capture_active),
        "quiet_window_duration_unchanged":
            "QUIET_WINDOW_SECONDS = 1.0" in capture_active,
        "primary_target_unchanged": "PRIMARY_TARGET = 2500" in capture_active,
        "drain_limit_unchanged": "DRAIN_LIMIT = 512" in capture_active,
        "spawn_unchanged": "mp.get_context('spawn')" in capture_active,
        "parent_quiescence_function_present": "def _parent_quiescence(" in capture_active,
        "reader_opens_c2h_only": "os.open(c2h_node" in capture_active,
        "raw_ipc_guard_present": "RAW_RECORD_CONTROL_IPC_FORBIDDEN" in capture_active,
    }
    overall &= all(semantic_checks.values())
    result = {
        "schema": "R3R4R2_CAPTURE_TOOL_DELTA_AUDIT_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R2",
        "source_evidence_commit":
            "9c1ff0473ca336e75c29a19208be17b407d8bf37",
        "source_evidence_directory":
            "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame",
        "authorized_tool_delta": (
            "QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY_ONLY" if overall else "FAIL"
        ),
        "runtime_quiet_window_function_changed": False if overall else None,
        "quiet_window_expected_completions":
            [False, False, False, False, False, True, True],
        "files": rows,
        "semantic_checks": semantic_checks,
        "result": "PASS" if overall else "FAIL",
    }
    write_text_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.json",
        json.dumps(result, indent=2) + "\n",
    )
    write_text_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.patch",
        "".join(raw_diffs),
    )
    baseline_lines = [
        "# G2B-HW0-PRODUCT-R3R4R2 Tool Baseline Receipt",
        "",
        "- Source evidence commit: `9c1ff0473ca336e75c29a19208be17b407d8bf37`",
        "- Source path: `v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame/tools`",
        "- Baseline extraction: commit-pinned `git archive`",
        "- Baseline copy verification: `PASS`",
        "",
        "| Baseline file | Source SHA-256 | Copied/active SHA-256 |",
        "|---|---|---|",
    ]
    baseline_lines.extend(
        f"| `{row['baseline']}` | `{row['baseline_sha256']}` | "
        f"`{row['active_sha256']}` |" for row in rows
    )
    write_text_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_TOOL_BASELINE_RECEIPT.md",
        "\n".join(baseline_lines) + "\n",
    )
    correction_lines = [
        "# G2B-HW0-PRODUCT-R3R4R2 Quiet-Window Correction",
        "",
        "- Case: `PARENT_QUIESCENCE_HANDSHAKE_PASS`",
        "- Before: `[False, False, False, False, False, False, True]`",
        "- After: `[False, False, False, False, False, True, True]`",
        "- Runtime quiet-window function changed: `NO`",
        "- Quiet-window duration: `1.0 s` (unchanged)",
        "- Observation and data-event timestamps: unchanged",
        "- Result: `PASS`" if overall else "- Result: `FAIL`",
    ]
    write_text_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_QUIET_WINDOW_CORRECTION.md",
        "\n".join(correction_lines) + "\n",
    )
    diff_lines = [
        "# G2B-HW0-PRODUCT-R3R4R2 Capture-Tool Diff",
        "",
        f"- Result: `{result['result']}`",
        f"- Authorized tool delta: `{result['authorized_tool_delta']}`",
        "- Runtime quiet-window implementation changed: `NO`",
        "- Only semantic change: corrected case-5 expected completion vector",
        "",
        "| Active file | Allowed delta | Result |",
        "|---|---|---|",
    ]
    diff_lines.extend(
        f"| `{row['active']}` | `{row['allowed_delta']}` | `{row['result']}` |"
        for row in rows
    )
    write_text_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.md",
        "\n".join(diff_lines) + "\n",
    )
    print(json.dumps(result, indent=2))
    return 0 if overall else 1


if __name__ == "__main__":
    raise SystemExit(main())
