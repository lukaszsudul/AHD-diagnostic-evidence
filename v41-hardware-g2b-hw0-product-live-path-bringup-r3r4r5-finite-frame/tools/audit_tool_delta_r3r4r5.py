#!/usr/bin/env python3
"""Fail-closed R3R4R4-to-R3R4R5 baseline and authorized-delta audit."""

from __future__ import annotations

import ast
import difflib
import hashlib
import json
import os
from pathlib import Path
import sys


SOURCE_COMMIT = "4b4346e1def6dce0bbeffe227e2731f9c7cfd314"
SOURCE_DIRECTORY = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r4-finite-frame/tools")
OLD_STAMP = "20260907T135724Z"
NEW_STAMP = "20260907T151342Z"
EXPECTED_BASELINE_HASHES = {
    "abi_v1.py": "2939FC522A2D9679BB720F287AC022FC48FF042CE06E20877F8E686F35909F1E",
    "audit_capture_architecture_r3r4r4.py": "CA3FF6289014592AAC22D83943AEA5CAE764CF2DA7224B9AAA170E6B9EF81F30",
    "audit_tool_delta_r3r4r4.py": "7662771E46B9413CAD8C0F4646DE7432F1E6E39BD4781D35173796E6373E9ECB",
    "build_evidence_r3r4r4.py": "7484AC47EC84EC1A76D8919653B7A30A737E4E3DB53609399DCFE082099C3500",
    "capture_r3r4.py": "577CF50C59C363B1CEE760D2DBA656F8BE862ACE4C972D3999F8DEBCBF4242C6",
    "capture_r3r4_selftest.py": "22F4640B3D498ACB8B6C1F47C46495326866F92F93984C684E040A4A75C1B6E8",
    "Collect-ImmutableBoundary.ps1": "DF2C23E82FB9066E4B28D396C9AAE1089E3B6492B9FCA78052B2DA4A2290EFBC",
    "frame_reconstruct_r3r4.py": "0DC2382F56E21D7717E9B05B0F52B9A399C51A2D922E6B50350A95F2621258E5",
    "Invoke-R3R4R4DutConnection.ps1": "A1C58D8E43FCBD65AD7836FE0A1CCC00914C070A27606F37D915E9AD573DD418",
    "V41_C2H_TRANSPORT_ABI_V1.json": "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6",
    "verify_authority_r3r4r4.py": "251692F91EFF66A313C2C2E5D63B8FA8B60E035E5BD5F5933E94902F28972DDE",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def sha_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest().upper()


def normalize_identity(text: str) -> str:
    return (text.replace("R3R4R5", "R3R4R4")
            .replace("r3r4r5", "r3r4r4")
            .replace(NEW_STAMP, OLD_STAMP))


def function_source(source: str, name: str) -> str:
    tree = ast.parse(source)
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == name:
            segment = ast.get_source_segment(source, node)
            if segment is None:
                raise RuntimeError(f"SOURCE_SEGMENT_MISSING:{name}")
            return segment
    raise RuntimeError(f"FUNCTION_MISSING:{name}")


def write_json(path: Path, value: dict) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_text(path: Path, value: str) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(value)
        handle.flush()
        os.fsync(handle.fileno())


def strict_monotonic_order_compare_present(source: str) -> bool:
    tree = ast.parse(source)
    for node in ast.walk(tree):
        if not isinstance(node, ast.Compare) or not any(
                isinstance(op, (ast.Lt, ast.LtE, ast.Gt, ast.GtE))
                for op in node.ops):
            continue
        segment = ast.get_source_segment(source, node) or ""
        if ("monotonic_ns" in segment and
                "FIRST_RECORD_DURABLE" in segment and
                "PRIMARY_TARGET_REACHED" in segment):
            return True
    return False


def main(root: Path) -> int:
    baseline = root / "artifacts" / "tool-baseline"
    scripts = root / "scripts"
    artifacts = root / "artifacts"

    baseline_inventory = []
    baseline_failures = []
    for path in sorted(baseline.iterdir(), key=lambda item: item.name.lower()):
        if not path.is_file():
            continue
        value = sha(path)
        expected = EXPECTED_BASELINE_HASHES.get(path.name)
        if expected is None:
            baseline_failures.append(f"UNEXPECTED_BASELINE_FILE:{path.name}")
        elif value != expected:
            baseline_failures.append(f"HASH:{path.name}:{expected}:{value}")
        baseline_inventory.append({
            "source_evidence_commit": SOURCE_COMMIT,
            "source_path": f"{SOURCE_DIRECTORY}/{path.name}",
            "source_size": path.stat().st_size,
            "source_sha256": value,
            "copied_path": str(path),
            "copied_sha256": value,
        })
    present = {Path(row["source_path"]).name for row in baseline_inventory}
    baseline_failures.extend(
        f"MISSING_BASELINE_FILE:{name}"
        for name in sorted(set(EXPECTED_BASELINE_HASHES) - present))

    base_capture = (baseline / "capture_r3r4.py").read_text(encoding="utf-8")
    work_capture = (scripts / "capture_r3r4.py").read_text(encoding="utf-8")
    base_frame = (baseline / "frame_reconstruct_r3r4.py").read_text(encoding="utf-8")
    work_frame = (scripts / "frame_reconstruct_r3r4.py").read_text(encoding="utf-8")
    base_helper = (baseline / "Invoke-R3R4R4DutConnection.ps1").read_text(
        encoding="utf-8")
    work_helper = (scripts / "Invoke-R3R4R5DutConnection.ps1").read_text(
        encoding="utf-8")
    base_selftest = (baseline / "capture_r3r4_selftest.py").read_text(
        encoding="utf-8")
    work_selftest_path = scripts / "capture_r3r4_selftest.py"
    work_selftest = work_selftest_path.read_text(encoding="utf-8")

    normalized_capture = normalize_identity(work_capture)
    normalized_frame = normalize_identity(work_frame)
    normalized_helper = normalize_identity(work_helper)
    normalized_selftest = normalize_identity(work_selftest)
    old_fixture = (
        "(True, 1.0), (True, 1.1), (True, 1.2), (True, 1.3), (True, 1.4),")
    new_fixture = (
        "(True, 1.0), (True, 1.1), (True, 1.2), (True, 1.3), (True, 1.401),")
    expected_selftest = base_selftest.replace(old_fixture, new_fixture, 1)
    fixture_replacement_exact = (
        base_selftest.count(old_fixture) == 1 and
        normalized_selftest == expected_selftest and
        normalized_selftest.count(new_fixture) == 1)

    base_quiescence = function_source(base_capture, "quiescence_streak_update")
    work_quiescence = function_source(normalized_capture, "quiescence_streak_update")
    strict_compare_present = strict_monotonic_order_compare_present(work_selftest)
    calculated_span = 1.401 - 1.0

    checks = {
        "BASELINE_REQUIRED_HASHES_EXACT": not baseline_failures,
        "CAPTURE_RUNTIME_NORMALIZED_BYTE_EQUIVALENT": normalized_capture == base_capture,
        "FRAME_RECONSTRUCTION_NORMALIZED_BYTE_EQUIVALENT": normalized_frame == base_frame,
        "ABI_PARSER_BYTE_IDENTICAL": sha(scripts / "abi_v1.py") == EXPECTED_BASELINE_HASHES["abi_v1.py"],
        "ABI_JSON_BYTE_IDENTICAL": sha(scripts / "V41_C2H_TRANSPORT_ABI_V1.json") == EXPECTED_BASELINE_HASHES["V41_C2H_TRANSPORT_ABI_V1.json"],
        "CREDENTIAL_HELPER_IDENTITY_ONLY": normalized_helper == base_helper,
        "SELFTEST_ONLY_EXACT_FIXTURE_DELTA": fixture_replacement_exact,
        "SYNTHETIC_FINAL_OBSERVATION_1_401": new_fixture in normalized_selftest,
        "SYNTHETIC_SPAN_STRICTLY_GREATER_THAN_0_400": calculated_span > 0.4,
        "RUNTIME_QUIESCENCE_FUNCTION_BYTE_EQUIVALENT": work_quiescence == base_quiescence,
        "RUNTIME_QUIESCENCE_THRESHOLD_0_400_PRESERVED": "QUIESCENCE_MINIMUM_SPAN_SECONDS = 0.4" in work_capture,
        "RUNTIME_QUIESCENCE_SAMPLE_COUNT_5_PRESERVED": "QUIESCENCE_REQUIRED_SAMPLES = 5" in work_capture,
        "STRICT_TIMESTAMP_ORDERING_ASSERTION_ABSENT": not strict_compare_present,
        "EVENT_SEQUENCE_PROOF_PRESERVED": "EVENT_SEQUENCE_PLUS_EXPLICIT_DEPENDENCY" in work_selftest,
        "QUIET_WINDOW_VECTOR_PRESERVED": "[False, False, False, False, False, True, True]" in work_selftest,
        "INVALID_CHUNK_COUNT_ASSERTION_ABSENT": "part_count > len(records)" not in work_selftest and "part_count < len(records)" not in work_selftest,
    }

    classification = (
        "QUIESCENCE_FIXTURE_1_400_TO_1_401_PLUS_RUN_IDENTITY_ONLY"
        if all(checks.values()) else "FAIL")
    receipt = {
        "schema": "R3R4R5_AUTHORIZED_TOOL_DELTA_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R5",
        "result": "PASS" if all(checks.values()) else "FAIL",
        "authorized_tool_delta": classification,
        "source_evidence_commit": SOURCE_COMMIT,
        "source_evidence_directory": SOURCE_DIRECTORY.rsplit("/tools", 1)[0],
        "runtime_capture_semantics_changed": normalized_capture != base_capture,
        "runtime_quiescence_implementation_changed": work_quiescence != base_quiescence,
        "synthetic_final_observation_seconds": 1.401,
        "synthetic_evaluated_span_seconds": calculated_span,
        "checks": checks,
        "baseline_failures": baseline_failures,
        "baseline_inventory": baseline_inventory,
        "working_hashes": {
            "capture_r3r4.py": sha(scripts / "capture_r3r4.py"),
            "capture_r3r4_selftest.py": sha(work_selftest_path),
            "frame_reconstruct_r3r4.py": sha(scripts / "frame_reconstruct_r3r4.py"),
            "abi_v1.py": sha(scripts / "abi_v1.py"),
            "V41_C2H_TRANSPORT_ABI_V1.json": sha(scripts / "V41_C2H_TRANSPORT_ABI_V1.json"),
            "Invoke-R3R4R5DutConnection.ps1": sha(scripts / "Invoke-R3R4R5DutConnection.ps1"),
        },
    }
    write_json(artifacts / "G2B_HW0_PRODUCT_R3R4R5_TOOL_BASELINE_RECEIPT.json", {
        "schema": "R3R4R5_TOOL_BASELINE_RECEIPT_V1",
        "result": "PASS" if not baseline_failures else "FAIL",
        "source_evidence_commit": SOURCE_COMMIT,
        "inventory": baseline_inventory,
        "failures": baseline_failures,
    })
    baseline_lines = [
        "# G2B-HW0-PRODUCT-R3R4R5 Tool Baseline Receipt", "",
        f"- Source evidence commit: `{SOURCE_COMMIT}`",
        f"- Source directory: `{SOURCE_DIRECTORY}`",
        f"- Result: `{'PASS' if not baseline_failures else 'FAIL'}`", "",
        "| Tool | Bytes | SHA-256 |", "|---|---:|---|",
    ]
    baseline_lines.extend(
        f"| `{Path(row['source_path']).name}` | {row['source_size']} | `{row['source_sha256']}` |"
        for row in baseline_inventory)
    baseline_lines.append("")
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R5_TOOL_BASELINE_RECEIPT.md",
               "\n".join(baseline_lines))
    write_json(artifacts / "G2B_HW0_PRODUCT_R3R4R5_CAPTURE_TOOL_DIFF.json", receipt)

    diff = "".join(difflib.unified_diff(
        base_capture.splitlines(True), work_capture.splitlines(True),
        fromfile="R3R4R4/tools/capture_r3r4.py",
        tofile="R3R4R5/scripts/capture_r3r4.py"))
    diff += "".join(difflib.unified_diff(
        base_selftest.splitlines(True), work_selftest.splitlines(True),
        fromfile="R3R4R4/tools/capture_r3r4_selftest.py",
        tofile="R3R4R5/scripts/capture_r3r4_selftest.py"))
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R5_CAPTURE_TOOL_DIFF.patch", diff)
    diff_lines = [
        "# G2B-HW0-PRODUCT-R3R4R5 Capture-Tool Diff", "",
        f"- Result: `{receipt['result']}`",
        f"- Authorized delta: `{classification}`",
        f"- Runtime capture normalized byte-equivalent: `{normalized_capture == base_capture}`",
        f"- Runtime quiescence function unchanged: `{work_quiescence == base_quiescence}`",
        "- Synthetic final observation: `1.401 seconds`",
        f"- Evaluated span: `{calculated_span!r} seconds`", "",
        "| Check | Result |", "|---|---|",
    ]
    diff_lines.extend(
        f"| `{name}` | `{'PASS' if value else 'FAIL'}` |"
        for name, value in checks.items())
    diff_lines.append("")
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R5_CAPTURE_TOOL_DIFF.md",
               "\n".join(diff_lines))

    correction = {
        "schema": "R3R4R5_FLOAT_BOUNDARY_CORRECTION_V1",
        "result": "PASS" if fixture_replacement_exact and calculated_span > 0.4 else "FAIL",
        "source_line_before": old_fixture,
        "source_line_after": new_fixture,
        "old_selftest_sha256": sha(baseline / "capture_r3r4_selftest.py"),
        "new_selftest_sha256": sha(work_selftest_path),
        "first_observation_seconds": 1.0,
        "final_observation_seconds": 1.401,
        "calculated_span_seconds": calculated_span,
        "required_span_seconds": 0.4,
        "runtime_function_hash_before": sha_text(base_quiescence),
        "runtime_function_hash_after_normalization": sha_text(work_quiescence),
        "runtime_function_unchanged": work_quiescence == base_quiescence,
    }
    write_json(artifacts / "G2B_HW0_PRODUCT_R3R4R5_FLOAT_BOUNDARY_CORRECTION.json", correction)
    correction_lines = [
        "# G2B-HW0-PRODUCT-R3R4R5 Float Boundary Correction", "",
        f"- Result: `{correction['result']}`",
        f"- Before: `{old_fixture}`",
        f"- After: `{new_fixture}`",
        f"- Old self-test SHA-256: `{correction['old_selftest_sha256']}`",
        f"- New self-test SHA-256: `{correction['new_selftest_sha256']}`",
        f"- Calculated test span: `{calculated_span!r} seconds`",
        "- Required runtime span: `0.4 seconds`",
        f"- Runtime function hash before: `{correction['runtime_function_hash_before']}`",
        f"- Runtime function hash after normalization: `{correction['runtime_function_hash_after_normalization']}`",
        f"- Runtime quiescence function unchanged: `{correction['runtime_function_unchanged']}`", "",
    ]
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R5_FLOAT_BOUNDARY_CORRECTION.md",
               "\n".join(correction_lines))
    print(json.dumps(receipt, indent=2))
    return 0 if receipt["result"] == "PASS" else 2


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_tool_delta_r3r4r5.py RUN_ROOT")
    raise SystemExit(main(Path(sys.argv[1]).resolve()))
