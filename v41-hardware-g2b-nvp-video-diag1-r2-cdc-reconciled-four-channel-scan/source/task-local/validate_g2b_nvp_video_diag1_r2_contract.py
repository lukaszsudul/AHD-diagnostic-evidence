#!/usr/bin/env python3
"""Read-only validator for the DIAG1-R2 response and evidence-file contract.

This tool checks only contract shape: the exact final heading, the required
label multiplicity/order, and the 53 mandatory top-level evidence filenames.
It does not validate engineering values and does not create evidence receipts.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
from typing import Any


CONTRACT_PATH = Path(__file__).with_name(
    "g2b_nvp_video_diag1_r2_contract.json"
)


def load_contract() -> dict[str, Any]:
    with CONTRACT_PATH.open("r", encoding="utf-8") as handle:
        contract = json.load(handle)
    labels = contract.get("final_response_labels")
    files = contract.get("mandatory_evidence_files")
    if not isinstance(labels, list) or not all(isinstance(x, str) for x in labels):
        raise ValueError("CONTRACT_FINAL_RESPONSE_LABELS_INVALID")
    if not isinstance(files, list) or not all(isinstance(x, str) for x in files):
        raise ValueError("CONTRACT_MANDATORY_EVIDENCE_FILES_INVALID")
    if len(labels) != contract.get("final_response_label_count"):
        raise ValueError("CONTRACT_FINAL_RESPONSE_LABEL_COUNT_MISMATCH")
    if len(files) != contract.get("mandatory_evidence_file_count"):
        raise ValueError("CONTRACT_MANDATORY_EVIDENCE_FILE_COUNT_MISMATCH")
    if len(labels) != len(set(labels)):
        raise ValueError("CONTRACT_DUPLICATE_FINAL_RESPONSE_LABEL")
    if len(files) != len(set(files)):
        raise ValueError("CONTRACT_DUPLICATE_MANDATORY_EVIDENCE_FILE")
    return contract


def validate_final_response(path: Path, contract: dict[str, Any]) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8-sig")
    lines = [line.rstrip("\r") for line in text.splitlines()]
    nonempty = [line for line in lines if line.strip()]
    heading = contract["exact_final_heading"]
    heading_ok = bool(nonempty) and nonempty[0] == heading

    expected: list[str] = contract["final_response_labels"]
    positions: dict[str, list[int]] = {
        label: [index + 1 for index, line in enumerate(lines) if line == label]
        for label in expected
    }
    missing = [label for label in expected if not positions[label]]
    duplicated = {
        label: found for label, found in positions.items() if len(found) > 1
    }
    first_positions = [positions[label][0] for label in expected if positions[label]]
    order_ok = (
        not missing
        and not duplicated
        and first_positions == sorted(first_positions)
    )
    reordered: list[dict[str, Any]] = []
    if not missing and not duplicated and not order_ok:
        previous_position = -1
        previous_label = ""
        for label in expected:
            current_position = positions[label][0]
            if current_position <= previous_position:
                reordered.append({
                    "label": label,
                    "line": current_position,
                    "must_follow": previous_label,
                    "must_follow_line": previous_position,
                })
            previous_position = current_position
            previous_label = label

    return {
        "path": os.fspath(path.resolve()),
        "heading_ok": heading_ok,
        "expected_heading": heading,
        "observed_first_nonempty_line": nonempty[0] if nonempty else None,
        "expected_label_count": len(expected),
        "labels_found_once": sum(len(value) == 1 for value in positions.values()),
        "missing_labels": missing,
        "duplicate_labels": duplicated,
        "label_order_ok": order_ok,
        "reordered_labels": reordered,
        "pass": heading_ok and not missing and not duplicated and order_ok,
    }


def validate_evidence_dir(path: Path, contract: dict[str, Any]) -> dict[str, Any]:
    expected: list[str] = contract["mandatory_evidence_files"]
    if not path.is_dir():
        return {
            "path": os.fspath(path.resolve()),
            "directory_exists": False,
            "expected_file_count": len(expected),
            "missing_files": expected,
            "case_mismatches": [],
            "non_regular_entries": [],
            "pass": False,
        }

    entries = {entry.name: entry for entry in os.scandir(path)}
    folded: dict[str, list[str]] = {}
    for name in entries:
        folded.setdefault(name.casefold(), []).append(name)

    missing: list[str] = []
    case_mismatches: list[dict[str, Any]] = []
    non_regular: list[str] = []
    for name in expected:
        entry = entries.get(name)
        if entry is None:
            variants = folded.get(name.casefold(), [])
            if variants:
                case_mismatches.append({"expected": name, "observed": variants})
            else:
                missing.append(name)
            continue
        if entry.is_symlink() or not entry.is_file(follow_symlinks=False):
            non_regular.append(name)

    return {
        "path": os.fspath(path.resolve()),
        "directory_exists": True,
        "expected_file_count": len(expected),
        "required_files_present_exactly": (
            len(expected) - len(missing) - len(case_mismatches) - len(non_regular)
        ),
        "missing_files": missing,
        "case_mismatches": case_mismatches,
        "non_regular_entries": non_regular,
        "pass": not missing and not case_mismatches and not non_regular,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--final-response",
        type=Path,
        help="UTF-8 text file containing the proposed exact Phase R response",
    )
    parser.add_argument(
        "--evidence-dir",
        type=Path,
        help="directory whose top level must contain the 53 mandatory files",
    )
    parser.add_argument(
        "--contract-only",
        action="store_true",
        help="validate the checklist JSON itself without checking artifacts",
    )
    args = parser.parse_args()
    if not (args.final_response or args.evidence_dir or args.contract_only):
        parser.error(
            "provide --final-response, --evidence-dir, or --contract-only"
        )
    return args


def main() -> int:
    args = parse_args()
    try:
        contract = load_contract()
        report: dict[str, Any] = {
            "contract": os.fspath(CONTRACT_PATH.resolve()),
            "contract_valid": True,
            "checks": {},
        }
        passed = True
        if args.final_response:
            result = validate_final_response(args.final_response, contract)
            report["checks"]["final_response"] = result
            passed = passed and result["pass"]
        if args.evidence_dir:
            result = validate_evidence_dir(args.evidence_dir, contract)
            report["checks"]["evidence_dir"] = result
            passed = passed and result["pass"]
        report["pass"] = passed
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0 if passed else 1
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(
            json.dumps(
                {
                    "contract": os.fspath(CONTRACT_PATH.resolve()),
                    "contract_valid": False,
                    "error": f"{type(exc).__name__}:{exc}",
                    "pass": False,
                },
                indent=2,
                ensure_ascii=False,
            )
        )
        return 2


if __name__ == "__main__":
    sys.exit(main())
