#!/usr/bin/env python3
"""Fail-closed R3R4R2-to-R3R4R3 baseline and authorized-delta audit."""
from __future__ import annotations

import ast
import difflib
import hashlib
import json
from pathlib import Path
import re


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R3_20260907T075856Z")
BASELINE = ROOT / "artifacts" / "tool-baseline"
SCRIPTS = ROOT / "scripts"
ARTIFACTS = ROOT / "artifacts"
SOURCE_COMMIT = "3749e2eb484eb1ccff2b7c4ed86598d8f4cfbb81"
SOURCE_DIRECTORY = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r2-finite-frame/tools"
)
EXPECTED_BASELINE = {
    "capture_r3r4.py": "E86539308771B8763C5B6B367EB8B05F8DB1757DB4EE3357D090DD5B16E9465F",
    "capture_r3r4_selftest.py": "65F529F9E769FFE6131B01F163EDC8F467B59B52E09805F73F5202A162856082",
    "frame_reconstruct_r3r4.py": "5AABCA122B4E8D8A5E3E53560B33DFAD3A0681C624ED2F8859265F5645E66282",
    "abi_v1.py": "2939FC522A2D9679BB720F287AC022FC48FF042CE06E20877F8E686F35909F1E",
    "V41_C2H_TRANSPORT_ABI_V1.json": "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6",
    "Invoke-R3R4R2DutConnection.ps1": "9103B7E6C7F7590578B134F5C1CE528FFDA1EAAA2A7EE0C2E50FB0D916091874",
}
EXISTING_CASES = (
    "FIRST_RECORD_PERSISTENCE_PASS",
    "PARTIAL_READ_ASSEMBLY_PASS",
    "PRIMARY_2500_BOUNDARY_PASS",
    "DRAIN_CAPTURE_PASS",
    "PARENT_QUIESCENCE_HANDSHAKE_PASS",
    "FAILURE_PRESERVES_RAW_DATA_PASS",
    "EXCEPTION_DETAIL_PASS",
    "COMPLETE_FRAME_RECONSTRUCTION_PASS",
    "EXACT_CAPTURE_HASH_PASS",
    "NO_BLANK_BLOCKER_PASS",
    "NO_RAW_RECORD_IPC_PASS",
)
NEW_CASES = (
    "PERSISTED_FIRST_RECORD_REREAD_PROOF_PASS",
    "PRIMARY_PERIODIC_FSYNC_PASS",
    "FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET_PASS",
    "PARENT_MULTI_SAMPLE_QUIESCENCE_PASS",
    "SINGLE_COMBINED_SESSION_NORMALIZATION_W1C_PASS",
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalize(text: str) -> str:
    return (text.replace("R3R4R3", "R3R4R2")
                .replace("r3r4r3", "r3r4r2")
                .replace("20260907T075856Z", "20260907T071912Z"))


def source_node(text: str, name: str, method: str | None = None) -> str:
    lines = text.splitlines(keepends=True)
    tree = ast.parse(text)
    for node in tree.body:
        if method is None and isinstance(node, (ast.FunctionDef, ast.ClassDef)) \
                and node.name == name:
            return "".join(lines[node.lineno - 1:node.end_lineno])
        if method is not None and isinstance(node, ast.ClassDef) and node.name == name:
            for child in node.body:
                if isinstance(child, ast.FunctionDef) and child.name == method:
                    return "".join(lines[child.lineno - 1:child.end_lineno])
    raise RuntimeError(f"SOURCE_NODE_MISSING:{name}:{method}")


def case_names(text: str) -> tuple[str, ...]:
    tree = ast.parse(text)
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(
                isinstance(target, ast.Name) and target.id == "CASE_NAMES"
                for target in node.targets):
            value = ast.literal_eval(node.value)
            return tuple(value)
    raise RuntimeError("CASE_NAMES_MISSING")


def write_exclusive(path: Path, text: str) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
        handle.flush()


def main() -> int:
    inventory = []
    checks: dict[str, bool] = {}
    for name, expected in EXPECTED_BASELINE.items():
        baseline_path = BASELINE / name
        actual = sha(baseline_path)
        checks[f"BASELINE_HASH_{name}"] = actual == expected
        inventory.append({
            "source_commit": SOURCE_COMMIT,
            "source_path": f"{SOURCE_DIRECTORY}/{name}",
            "source_bytes": baseline_path.stat().st_size,
            "source_sha256": actual,
            "copied_path": str(baseline_path),
            "copied_sha256": actual,
        })

    base_capture = BASELINE.joinpath("capture_r3r4.py").read_text(encoding="utf-8")
    work_capture = SCRIPTS.joinpath("capture_r3r4.py").read_text(encoding="utf-8")
    normalized_capture = normalize(work_capture)
    base_selftest = BASELINE.joinpath("capture_r3r4_selftest.py").read_text(
        encoding="utf-8")
    work_selftest = SCRIPTS.joinpath("capture_r3r4_selftest.py").read_text(
        encoding="utf-8")

    untouched_functions = (
        "require", "_nonempty_problem", "_write_json_exclusive", "_replace_json",
        "_contains_bytes", "compact_emit", "read_lock", "quiescent", "_append_csv",
        "_alarm_handler", "quiet_window_update", "reader_worker", "_open_holders",
        "_iter_file_records", "reconcile_counters", "_drain_messages",
    )
    for name in untouched_functions:
        checks[f"UNCHANGED_RUNTIME_FUNCTION_{name}"] = (
            source_node(base_capture, name) == source_node(normalized_capture, name)
        )
    for method in ("__init__", "close", "_guard", "read", "_intent_rows", "snapshot"):
        checks[f"UNCHANGED_MMIO_METHOD_{method}"] = (
            source_node(base_capture, "MMIO", method) ==
            source_node(normalized_capture, "MMIO", method)
        )
    for name in ("Collector", "build_records", "feed_partial", "write_markdown"):
        checks[f"UNCHANGED_SELFTEST_HELPER_{name}"] = (
            source_node(base_selftest, name) ==
            source_node(normalize(work_selftest), name)
        )

    quiet_source = source_node(work_capture, "quiet_window_update")
    checks.update({
        "ABI_PARSER_BYTE_IDENTICAL":
            sha(BASELINE / "abi_v1.py") == sha(SCRIPTS / "abi_v1.py"),
        "ABI_JSON_BYTE_IDENTICAL":
            sha(BASELINE / "V41_C2H_TRANSPORT_ABI_V1.json") ==
            sha(SCRIPTS / "V41_C2H_TRANSPORT_ABI_V1.json"),
        "FRAME_TOOL_IDENTITY_ONLY":
            BASELINE.joinpath("frame_reconstruct_r3r4.py").read_text(encoding="utf-8") ==
            normalize(SCRIPTS.joinpath("frame_reconstruct_r3r4.py").read_text(
                encoding="utf-8")),
        "HELPER_IDENTITY_ONLY":
            BASELINE.joinpath("Invoke-R3R4R2DutConnection.ps1").read_text(
                encoding="utf-8") ==
            normalize(SCRIPTS.joinpath("Invoke-R3R4R3DutConnection.ps1").read_text(
                encoding="utf-8")),
        "RECORD_BYTES_UNCHANGED_4096": bool(re.search(
            r"^RECORD_BYTES = 4096$", work_capture, re.MULTILINE)),
        "PRIMARY_TARGET_UNCHANGED_2500": bool(re.search(
            r"^PRIMARY_TARGET = 2500$", work_capture, re.MULTILINE)),
        "DRAIN_LIMIT_UNCHANGED_512": bool(re.search(
            r"^DRAIN_LIMIT = 512$", work_capture, re.MULTILINE)),
        "QUIET_WINDOW_UNCHANGED_1_SECOND": bool(re.search(
            r"^QUIET_WINDOW_SECONDS = 1\.0$", work_capture, re.MULTILINE)),
        "RUNTIME_QUIET_WINDOW_BYTE_EQUIVALENT":
            quiet_source == source_node(normalized_capture, "quiet_window_update") and
            source_node(base_capture, "quiet_window_update") ==
            source_node(normalized_capture, "quiet_window_update"),
        "QUIET_WINDOW_EXPECTED_VECTOR_PRESERVED":
            "[False, False, False, False, False, True, True]" in work_selftest,
        "INVALID_CHUNK_COUNT_ASSERTION_ABSENT":
            "part_count > len(records)" not in work_selftest and
            "part_count < len(records)" not in work_selftest,
        "EXISTING_CASES_PRESERVED_IN_ORDER":
            case_names(work_selftest)[:11] == EXISTING_CASES,
        "FIVE_NEW_CASES_EXACT_IN_ORDER":
            case_names(work_selftest)[11:] == NEW_CASES,
        "PERSISTED_REREAD_CLOSURE_PRESENT":
            "persisted_record = _read_exact_nofollow" in work_capture and
            "persisted_payload = _read_exact_nofollow" in work_capture and
            "del blob" in source_node(work_capture, "RecordSink", "_persist_first"),
        "PRIMARY_CHECKPOINT_CLOSURE_PRESENT":
            "PRIMARY_CHECKPOINT_COUNTS = (1024, 2048, 2500)" in work_capture and
            "r3r4r3-primary-durability-worker" in work_capture,
        "ORDERING_CLOSURE_PRESENT":
            "_await_primary_target_prerequisites" in work_capture and
            "self._wait_checkpoint(1024)" in work_capture and
            "self._wait_checkpoint(2048)" in work_capture,
        "MULTI_SAMPLE_QUIESCENCE_CLOSURE_PRESENT":
            "QUIESCENCE_REQUIRED_SAMPLES = 5" in work_capture and
            "QUIESCENCE_MINIMUM_SPAN_SECONDS = 0.4" in work_capture and
            "consecutive_quiescent" in source_node(work_capture, "_parent_quiescence"),
        "SINGLE_COMBINED_W1C_CLOSURE_PRESENT":
            "combined_session_normalization" in work_capture and
            "SESSION_NORMALIZATION_W1C" in work_capture and
            "POST_RESET_NONFATAL_W1C" not in work_capture and
            "POST_RESET_FATAL_W1C" not in work_capture,
        "PARENT_ONLY_MMIO_PRESERVED":
            "MMIO(" not in source_node(work_capture, "reader_worker"),
        "NO_RAW_PAYLOAD_IPC_PRESERVED":
            "R3R4R3_RAW_RECORD_CONTROL_IPC_FORBIDDEN" in work_capture,
    })

    failed = sorted(name for name, passed in checks.items() if not passed)
    result = {
        "schema": "R3R4R3_AUTHORIZED_TOOL_DELTA_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R3",
        "result": "PASS" if not failed else "FAIL",
        "authorized_tool_delta": (
            "FIVE_CAPTURE_CONTRACT_CLOSURES_PLUS_RUN_IDENTITY_ONLY"
            if not failed else "FAIL"),
        "source_commit": SOURCE_COMMIT,
        "source_directory": SOURCE_DIRECTORY,
        "baseline_inventory": inventory,
        "checks": checks,
        "failed_checks": failed,
        "capture_baseline_sha256": sha(BASELINE / "capture_r3r4.py"),
        "capture_corrected_sha256": sha(SCRIPTS / "capture_r3r4.py"),
        "selftest_baseline_sha256": sha(BASELINE / "capture_r3r4_selftest.py"),
        "selftest_corrected_sha256": sha(SCRIPTS / "capture_r3r4_selftest.py"),
        "hardware_access": False,
        "dut_connections": 0,
    }
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_TOOL_BASELINE_RECEIPT.json",
        json.dumps({
            "schema": "R3R4R3_TOOL_BASELINE_RECEIPT_V1",
            "result": "PASS" if all(checks[name] for name in checks
                                      if name.startswith("BASELINE_HASH_")) else "FAIL",
            "source_commit": SOURCE_COMMIT,
            "source_directory": SOURCE_DIRECTORY,
            "tools": inventory,
        }, indent=2) + "\n",
    )
    baseline_lines = [
        "# G2B-HW0-PRODUCT-R3R4R3 Tool Baseline Receipt", "",
        f"- Source evidence commit: `{SOURCE_COMMIT}`",
        f"- Source directory: `{SOURCE_DIRECTORY}`",
        "- Result: `PASS`" if not any(
            name.startswith("BASELINE_HASH_") for name in failed) else "- Result: `FAIL`",
        "", "| Tool | Bytes | SHA-256 |", "|---|---:|---|",
    ]
    baseline_lines.extend(
        f"| `{Path(row['source_path']).name}` | `{row['source_bytes']}` | "
        f"`{row['source_sha256']}` |" for row in inventory)
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_TOOL_BASELINE_RECEIPT.md",
        "\n".join(baseline_lines) + "\n",
    )
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.json",
        json.dumps(result, indent=2) + "\n",
    )
    diff = "".join(difflib.unified_diff(
        base_capture.splitlines(keepends=True),
        work_capture.splitlines(keepends=True),
        fromfile="R3R4R2/tools/capture_r3r4.py",
        tofile="R3R4R3/scripts/capture_r3r4.py",
    )) + "".join(difflib.unified_diff(
        base_selftest.splitlines(keepends=True),
        work_selftest.splitlines(keepends=True),
        fromfile="R3R4R2/tools/capture_r3r4_selftest.py",
        tofile="R3R4R3/scripts/capture_r3r4_selftest.py",
    ))
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.patch", diff)
    report = [
        "# G2B-HW0-PRODUCT-R3R4R3 Capture-Tool Diff", "",
        f"- Result: `{result['result']}`",
        "- Authorized delta: "
        f"`{result['authorized_tool_delta']}`",
        "- Baseline: published R3R4R2 tools at commit "
        f"`{SOURCE_COMMIT}`",
        "- Runtime quiet-window function changed: `NO`",
        "- Quiet-window expected vector: "
        "`[False, False, False, False, False, True, True]`",
        "- Invalid chunk-count assertion present: `NO`",
        "", "| Check | Result |", "|---|---|",
    ]
    report.extend(
        f"| `{name}` | `{'PASS' if passed else 'FAIL'}` |"
        for name, passed in checks.items())
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.md",
        "\n".join(report) + "\n",
    )
    print(json.dumps(result, indent=2))
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
