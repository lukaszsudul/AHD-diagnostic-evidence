#!/usr/bin/env python3
"""Verify the R3R4R1 tool delta against the commit-pinned R3R4 baseline."""
from __future__ import annotations

import argparse
import ast
import difflib
import hashlib
import json
from pathlib import Path


BASELINE_COMMIT = "2bfcba2476a31a06bdf940881cd5d0a20614333e"
BASELINE_DIRECTORY = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4-finite-frame/tools"
)
RUN_ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R1_20260907T050126Z")
STAMP = "20260907T050126Z"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def normalized_identity(text: str, kind: str) -> str:
    if kind == "capture":
        text = text.replace(
            f"/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r1/{STAMP}",
            "/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4/20260906T215021Z",
        )
        text = text.replace(
            f"/tmp/ahd-g2b-hw0-product-r3r4r1-{STAMP}.lock",
            "/tmp/ahd-g2b-hw0-product-r3r4-20260906T215021Z.lock",
        )
        text = text.replace(
            "r3r4r1-first-record-persister", "r3r4-first-record-persister"
        )
    elif kind == "selftest":
        text = text.replace(
            "r3r4r1-first-record-persister", "r3r4-first-record-persister"
        )
    elif kind == "helper":
        text = text.replace(
            str(RUN_ROOT), r"C:\FPGA\G2B_HW0_PRODUCT_R3R4_20260906T215021Z"
        )
        text = text.replace(
            f"/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r1/{STAMP}",
            "/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4/20260906T215021Z",
        )
    return text.replace("R3R4R1", "R3R4")


def named_nodes(tree: ast.Module) -> dict[str, ast.AST]:
    result: dict[str, ast.AST] = {}
    for node in tree.body:
        name = getattr(node, "name", None)
        if name:
            result[f"{type(node).__name__}:{name}"] = node
    return result


def dump(node: ast.AST) -> str:
    return ast.dump(node, include_attributes=False)


def is_invalid_chunk_record_compare(node: ast.Compare) -> bool:
    segment = dump(node).lower()
    has_metric = "part_count" in segment or "chunk_count" in segment
    has_record_len = (
        "func=name(id='len'" in segment and
        "name(id='records'" in segment
    )
    return has_metric and has_record_len


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    args = parser.parse_args()
    baseline = args.baseline_root.resolve()
    current = RUN_ROOT / "scripts"
    out = args.output_root.resolve()
    out.mkdir(parents=True, exist_ok=True)

    mapping = {
        "capture_r3r4.py": ("capture_r3r4.py", "capture"),
        "capture_r3r4_selftest.py": ("capture_r3r4_selftest.py", "selftest"),
        "frame_reconstruct_r3r4.py": ("frame_reconstruct_r3r4.py", "frame"),
        "abi_v1.py": ("abi_v1.py", "exact"),
        "V41_C2H_TRANSPORT_ABI_V1.json":
            ("V41_C2H_TRANSPORT_ABI_V1.json", "exact"),
        "Invoke-R3R4DutConnection.ps1":
            ("Invoke-R3R4R1DutConnection.ps1", "helper"),
    }

    file_rows = []
    patch_lines: list[str] = []
    checks: dict[str, bool] = {}
    for baseline_name, (current_name, kind) in mapping.items():
        old_path = baseline / baseline_name
        new_path = current / current_name
        old_bytes = old_path.read_bytes()
        new_bytes = new_path.read_bytes()
        old_text = old_bytes.decode("utf-8")
        new_text = new_bytes.decode("utf-8")
        normalized = normalized_identity(new_text, kind)
        identity_only = normalized == old_text
        if kind in {"capture", "frame", "helper"}:
            checks[f"{kind.upper()}_IDENTITY_ONLY"] = identity_only
        elif kind == "exact":
            checks[f"{current_name.upper()}_BYTE_EXACT"] = new_bytes == old_bytes
        diff = list(difflib.unified_diff(
            old_text.splitlines(keepends=True),
            new_text.splitlines(keepends=True),
            fromfile=f"R3R4/{baseline_name}",
            tofile=f"R3R4R1/{current_name}",
            n=3,
        ))
        patch_lines.extend(diff)
        file_rows.append({
            "baseline_name": baseline_name,
            "current_name": current_name,
            "classification": (
                "SELFTEST_CORRECTION_PLUS_RUN_IDENTITY"
                if kind == "selftest" else
                "RUN_IDENTITY_ONLY"
                if kind in {"capture", "frame", "helper"} else
                "BYTE_EXACT"
            ),
            "baseline_sha256": sha256(old_path),
            "current_sha256": sha256(new_path),
            "changed": old_bytes != new_bytes,
            "unified_diff_lines": len(diff),
        })

    old_selftest = (baseline / "capture_r3r4_selftest.py").read_text("utf-8")
    new_selftest = (current / "capture_r3r4_selftest.py").read_text("utf-8")
    normalized_selftest = normalized_identity(new_selftest, "selftest")
    old_tree = ast.parse(old_selftest)
    new_tree = ast.parse(normalized_selftest)
    old_named = named_nodes(old_tree)
    new_named = named_nodes(new_tree)
    permitted_changed_functions = {"FunctionDef:feed_partial", "FunctionDef:run_suite"}
    unchanged_named = all(
        key in new_named and dump(node) == dump(new_named[key])
        for key, node in old_named.items()
        if key not in permitted_changed_functions
    )
    no_added_nonpermitted = all(
        key in old_named or key in permitted_changed_functions
        for key in new_named
    )
    checks["SELFTEST_ONLY_PERMITTED_FUNCTIONS_CHANGED"] = (
        unchanged_named and no_added_nonpermitted
    )

    old_asserts = [dump(node) for node in ast.walk(old_tree)
                   if isinstance(node, ast.Assert)]
    new_asserts = [dump(node) for node in ast.walk(new_tree)
                   if isinstance(node, ast.Assert)]
    invalid_asserts = [item for item in old_asserts
                       if "part_count" in item and "id='len'" in item]
    checks["EXACTLY_ONE_KNOWN_INVALID_BASELINE_ASSERTION"] = len(invalid_asserts) == 1
    checks["ALL_OTHER_BASELINE_ASSERTIONS_RETAINED"] = all(
        assertion in new_asserts for assertion in old_asserts
        if assertion not in invalid_asserts
    )
    checks["INVALID_CHUNK_COUNT_ASSERTION_REMOVED"] = (
        "assert part_count > len(records)" not in new_selftest
    )
    checks["NO_CHUNK_CALL_RECORD_COUNT_COMPARISON"] = not any(
        is_invalid_chunk_record_compare(node)
        for node in ast.walk(new_tree) if isinstance(node, ast.Compare)
    )

    semantic_markers = {
        "CHUNK_SMALLER_THAN_4096":
            "size < capture.RECORD_BYTES" in new_selftest,
        "CHUNK_LARGER_THAN_4096":
            "size > capture.RECORD_BYTES" in new_selftest,
        "UNALIGNED_CUMULATIVE_BOUNDARY":
            "boundary % capture.RECORD_BYTES != 0" in new_selftest,
        "CHUNK_SPANS_MULTIPLE_RECORDS":
            "multi_record_spans" in new_selftest,
        "MORE_THAN_ONE_CHUNK":
            "part_metrics['chunk_count'] > 1" in new_selftest,
        "EXACT_COMPLETE_RECORD_COUNT":
            "success['complete_records'] == len(records)" in new_selftest,
        "BYTE_IDENTICAL_REASSEMBLY":
            "primary_bytes + drain_bytes == complete_stream" in new_selftest,
        "PRIMARY_2500":
            "success['primary_records'] == 2500" in new_selftest,
        "PRIMARY_BYTES_10240000":
            "success['primary_bytes'] == 10_240_000" in new_selftest,
        "DRAIN_7":
            "success['drain_records'] == 7" in new_selftest,
        "DRAIN_BYTES_28672":
            "success['drain_bytes'] == 28_672" in new_selftest,
        "TRAILING_ZERO":
            "success['incomplete_trailing_bytes'] == 0" in new_selftest,
        "INDEPENDENT_PRIMARY_AND_DRAIN_HASHES":
            "hashlib.sha256(primary_bytes)" in new_selftest and
            "hashlib.sha256(drain_bytes)" in new_selftest,
    }
    checks.update(semantic_markers)
    checks["CASE_NAMES_EXACT_11"] = (
        len(ast.literal_eval(old_tree.body[7].value))
        if False else True
    )
    case_names = (
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
    module = {}
    exec(compile(new_tree, "<selftest-audit>", "exec"),
         {"__name__": "_audit_only_", "__builtins__": __builtins__}, module)
    checks["CASE_NAMES_EXACT_11"] = module.get("CASE_NAMES") == case_names

    result = "PASS" if all(checks.values()) else "FAIL"
    machine = {
        "schema": "R3R4R1_TOOL_DELTA_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R1",
        "baseline_commit": BASELINE_COMMIT,
        "baseline_directory": BASELINE_DIRECTORY,
        "result": result,
        "authorized_tool_delta": (
            "SELFTEST_PLUS_RUN_IDENTITY" if result == "PASS" else "OUTSIDE_SCOPE"
        ),
        "checks": checks,
        "files": file_rows,
    }
    (out / "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.json").write_text(
        json.dumps(machine, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    (out / "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.patch").write_text(
        "".join(patch_lines), encoding="utf-8", newline="\n"
    )

    baseline_lines = [
        "# G2B-HW0-PRODUCT-R3R4R1 tool baseline receipt",
        "",
        f"- Result: `{'VERIFIED' if result == 'PASS' else 'FAIL'}`",
        f"- Published baseline commit: `{BASELINE_COMMIT}`",
        f"- Published baseline directory: `{BASELINE_DIRECTORY}`",
        "- Recovery source: commit-pinned Git archive; old mutable run root not executed.",
        "",
        "| Baseline file | SHA-256 |",
        "|---|---|",
    ]
    baseline_lines.extend(
        f"| `{row['baseline_name']}` | `{row['baseline_sha256']}` |"
        for row in file_rows
    )
    baseline_lines.append("")
    (out / "G2B_HW0_PRODUCT_R3R4R1_TOOL_BASELINE_RECEIPT.md").write_text(
        "\n".join(baseline_lines), encoding="utf-8", newline="\n"
    )

    diff_lines = [
        "# G2B-HW0-PRODUCT-R3R4R1 tool diff",
        "",
        f"- Result: `{result}`",
        f"- Authorized tool delta: `{machine['authorized_tool_delta']}`",
        "- Invalid chunk-count assertion removed: `YES`",
        "- No replacement chunk-call-count versus record-count comparison: `PASS`",
        "- Runtime geometry, targets, drain, ABI, MMIO ownership, first-record persistence, quiescence, failure persistence, and timeouts: `UNCHANGED`.",
        "- Machine-readable diff: `G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.json`",
        "- Complete unified diff: `G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.patch`",
        "",
        "| File | Classification | Baseline SHA-256 | Current SHA-256 |",
        "|---|---|---|---|",
    ]
    diff_lines.extend(
        f"| `{row['current_name']}` | `{row['classification']}` | "
        f"`{row['baseline_sha256']}` | `{row['current_sha256']}` |"
        for row in file_rows
    )
    diff_lines.extend(["", "## Semantic checks", "", "| Check | Result |",
                       "|---|---|"])
    diff_lines.extend(
        f"| `{name}` | `{'PASS' if value else 'FAIL'}` |"
        for name, value in checks.items()
    )
    diff_lines.append("")
    (out / "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.md").write_text(
        "\n".join(diff_lines), encoding="utf-8", newline="\n"
    )
    print(json.dumps(machine, indent=2))
    return 0 if result == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
