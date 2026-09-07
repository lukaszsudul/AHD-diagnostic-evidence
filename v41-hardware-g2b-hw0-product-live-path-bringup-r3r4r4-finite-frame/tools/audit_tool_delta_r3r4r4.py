#!/usr/bin/env python3
"""Fail-closed R3R4R3-to-R3R4R4 baseline and authorized-delta audit."""

from __future__ import annotations

import ast
import difflib
import hashlib
import json
import os
from pathlib import Path
import sys


SOURCE_COMMIT = "6676421dfb5e64b7271a2200fe950c1d223fc3d6"
SOURCE_DIRECTORY = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r3-finite-frame/tools")
OLD_STAMP = "20260907T075856Z"
NEW_STAMP = "20260907T135724Z"
EXPECTED_SELFTEST_SHA256 = (
    "22F4640B3D498ACB8B6C1F47C46495326866F92F93984C684E040A4A75C1B6E8")
EXPECTED_BASELINE_HASHES = {
    "capture_r3r4.py": "9CC527C43228AD60559DA734DF5305E4FABFBACA93A800DD3B5483F8E3D64E6B",
    "capture_r3r4_selftest.py": "498EDD9AA632D41DCC617E6DFA30798034C14D1CFF50565088DF74867C2A240C",
    "frame_reconstruct_r3r4.py": "C02D7F631F2BBA50805C7A8DC97E4596C5A4D8421641A6C14A7C4DC211166286",
    "abi_v1.py": "2939FC522A2D9679BB720F287AC022FC48FF042CE06E20877F8E686F35909F1E",
    "V41_C2H_TRANSPORT_ABI_V1.json": "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6",
    "Invoke-R3R4R3DutConnection.ps1": "EA01BC7FF3962FC2E3474850533889859934AEF23014CDD9893E16362FC17064",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalize_identity(text: str) -> str:
    return (text.replace("R3R4R4", "R3R4R3")
            .replace("r3r4r4", "r3r4r3")
            .replace(NEW_STAMP, OLD_STAMP))


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
        if expected is not None and value != expected:
            baseline_failures.append(f"HASH:{path.name}:{expected}:{value}")
        baseline_inventory.append({
            "source_evidence_commit": SOURCE_COMMIT,
            "source_path": f"{SOURCE_DIRECTORY}/{path.name}",
            "source_size": path.stat().st_size,
            "source_sha256": value,
            "copied_path": str(path),
            "copied_sha256": value,
        })

    base_capture = (baseline / "capture_r3r4.py").read_text(encoding="utf-8")
    work_capture = (scripts / "capture_r3r4.py").read_text(encoding="utf-8")
    base_frame = (baseline / "frame_reconstruct_r3r4.py").read_text(encoding="utf-8")
    work_frame = (scripts / "frame_reconstruct_r3r4.py").read_text(encoding="utf-8")
    base_helper = (baseline / "Invoke-R3R4R3DutConnection.ps1").read_text(
        encoding="utf-8")
    work_helper = (scripts / "Invoke-R3R4R4DutConnection.ps1").read_text(
        encoding="utf-8")
    base_selftest = (baseline / "capture_r3r4_selftest.py").read_text(
        encoding="utf-8")
    work_selftest_path = scripts / "capture_r3r4_selftest.py"
    work_selftest = work_selftest_path.read_text(encoding="utf-8")

    normalized_capture_equal = normalize_identity(work_capture) == base_capture
    normalized_frame_equal = normalize_identity(work_frame) == base_frame
    normalized_helper_equal = normalize_identity(work_helper) == base_helper
    strict_compare_present = strict_monotonic_order_compare_present(work_selftest)
    sleep_count_unchanged = (
        work_selftest.count("time.sleep(") == base_selftest.count("time.sleep("))

    checks = {
        "BASELINE_REQUIRED_HASHES_EXACT": not baseline_failures,
        "CAPTURE_RUNTIME_NORMALIZED_BYTE_EQUIVALENT": normalized_capture_equal,
        "FRAME_RECONSTRUCTION_NORMALIZED_BYTE_EQUIVALENT": normalized_frame_equal,
        "ABI_PARSER_BYTE_IDENTICAL": (
            sha(scripts / "abi_v1.py") == EXPECTED_BASELINE_HASHES["abi_v1.py"]),
        "ABI_JSON_BYTE_IDENTICAL": (
            sha(scripts / "V41_C2H_TRANSPORT_ABI_V1.json") ==
            EXPECTED_BASELINE_HASHES["V41_C2H_TRANSPORT_ABI_V1.json"]),
        "CREDENTIAL_HELPER_IDENTITY_ONLY": normalized_helper_equal,
        "SELFTEST_EXACT_AUTHORIZED_SOURCE_HASH": (
            sha(work_selftest_path) == EXPECTED_SELFTEST_SHA256),
        "STRICT_TIMESTAMP_ORDERING_ASSERTION_ABSENT": not strict_compare_present,
        "NO_ADDED_SLEEP": sleep_count_unchanged,
        "EVENT_SEQUENCE_PRESENT": (
            "'event_sequence': self._event_sequence" in work_selftest and
            "durable_event['event_sequence'] < target_event['event_sequence']" in
            work_selftest),
        "EXPLICIT_DEPENDENCY_GUARD_PRESENT": (
            "not self.first_record_durable_success" in work_selftest and
            "raise DependencyRejected(blocker)" in work_selftest and
            "'dependency_state': 'FIRST_RECORD_DURABLE_SUCCESS_FALSE'" in
            work_selftest),
        "DEPENDENCY_SUCCESS_AT_TARGET_REQUIRED": (
            "target_event['dependency_state'] == 'FIRST_RECORD_DURABLE_SUCCESS'" in
            work_selftest and
            "target_event['first_record_durable_success'] is True" in work_selftest),
        "EQUAL_TIMESTAMP_POSITIVE_CASE_PRESENT": (
            "durable_event['monotonic_ns'] == target_event['monotonic_ns']" in
            work_selftest and "equal_ordering_timestamp_ns" in work_selftest),
        "TARGET_BEFORE_DURABLE_NEGATIVE_CASE_PRESENT": (
            "PRIMARY_TARGET_REACHED_REJECTED:" in work_selftest and
            "FIRST_RECORD_DURABLE_SUCCESS_FALSE" in work_selftest and
            "target_before_durable_rejected" in work_selftest),
        "ORDERING_PROOF_RECEIPT_PRESENT": (
            "G2B_HW0_PRODUCT_R3R4R4_EVENT_ORDERING_PROOF.json" in work_selftest and
            "EVENT_SEQUENCE_PLUS_EXPLICIT_DEPENDENCY" in work_selftest),
        "QUIET_WINDOW_VECTOR_PRESERVED": (
            "[False, False, False, False, False, True, True]" in work_selftest),
        "INVALID_CHUNK_COUNT_ASSERTION_ABSENT": (
            "part_count > len(records)" not in work_selftest and
            "part_count < len(records)" not in work_selftest),
    }

    classification = (
        "EVENT_SEQUENCE_SELFTEST_PROOF_PLUS_RUN_IDENTITY_ONLY"
        if all(checks.values()) else "FAIL")
    receipt = {
        "schema": "R3R4R4_AUTHORIZED_TOOL_DELTA_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R4",
        "result": "PASS" if all(checks.values()) else "FAIL",
        "authorized_tool_delta": classification,
        "source_evidence_commit": SOURCE_COMMIT,
        "source_evidence_directory": SOURCE_DIRECTORY.rsplit("/tools", 1)[0],
        "runtime_capture_semantics_changed": not normalized_capture_equal,
        "strict_timestamp_ordering_assertion_present": strict_compare_present,
        "checks": checks,
        "baseline_failures": baseline_failures,
        "baseline_inventory": baseline_inventory,
        "working_hashes": {
            "capture_r3r4.py": sha(scripts / "capture_r3r4.py"),
            "capture_r3r4_selftest.py": sha(work_selftest_path),
            "frame_reconstruct_r3r4.py": sha(scripts / "frame_reconstruct_r3r4.py"),
            "abi_v1.py": sha(scripts / "abi_v1.py"),
            "V41_C2H_TRANSPORT_ABI_V1.json": sha(
                scripts / "V41_C2H_TRANSPORT_ABI_V1.json"),
            "Invoke-R3R4R4DutConnection.ps1": sha(
                scripts / "Invoke-R3R4R4DutConnection.ps1"),
        },
    }
    write_json(
        artifacts / "G2B_HW0_PRODUCT_R3R4R4_TOOL_BASELINE_RECEIPT.json",
        {
            "schema": "R3R4R4_TOOL_BASELINE_RECEIPT_V1",
            "result": "PASS" if not baseline_failures else "FAIL",
            "source_evidence_commit": SOURCE_COMMIT,
            "inventory": baseline_inventory,
            "failures": baseline_failures,
        })
    baseline_lines = [
        "# G2B-HW0-PRODUCT-R3R4R4 Tool Baseline Receipt", "",
        f"- Source evidence commit: `{SOURCE_COMMIT}`",
        f"- Source directory: `{SOURCE_DIRECTORY}`",
        f"- Result: `{'PASS' if not baseline_failures else 'FAIL'}`", "",
        "| Tool | Bytes | SHA-256 |", "|---|---:|---|",
    ]
    baseline_lines.extend(
        f"| `{Path(row['source_path']).name}` | {row['source_size']} | "
        f"`{row['source_sha256']}` |" for row in baseline_inventory)
    baseline_lines.append("")
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R4_TOOL_BASELINE_RECEIPT.md",
               "\n".join(baseline_lines))
    write_json(artifacts / "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_DIFF.json",
               receipt)

    patch = "".join(difflib.unified_diff(
        base_capture.splitlines(True), work_capture.splitlines(True),
        fromfile="R3R4R3/tools/capture_r3r4.py",
        tofile="R3R4R4/scripts/capture_r3r4.py"))
    patch += "".join(difflib.unified_diff(
        base_selftest.splitlines(True), work_selftest.splitlines(True),
        fromfile="R3R4R3/tools/capture_r3r4_selftest.py",
        tofile="R3R4R4/scripts/capture_r3r4_selftest.py"))
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_DIFF.patch",
               patch)
    diff_lines = [
        "# G2B-HW0-PRODUCT-R3R4R4 Capture-Tool Diff", "",
        f"- Result: `{receipt['result']}`",
        f"- Authorized delta: `{classification}`",
        f"- Runtime capture normalized byte-equivalent: `{normalized_capture_equal}`",
        f"- Strict timestamp ordering assertion present: `{strict_compare_present}`",
        f"- Self-test exact authorized SHA-256: `{sha(work_selftest_path)}`", "",
        "| Check | Result |", "|---|---|",
    ]
    diff_lines.extend(
        f"| `{name}` | `{'PASS' if value else 'FAIL'}` |"
        for name, value in checks.items())
    diff_lines.append("")
    write_text(artifacts / "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_DIFF.md",
               "\n".join(diff_lines))
    print(json.dumps(receipt, indent=2))
    return 0 if receipt["result"] == "PASS" else 2


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_tool_delta_r3r4r4.py RUN_ROOT")
    raise SystemExit(main(Path(sys.argv[1]).resolve()))
