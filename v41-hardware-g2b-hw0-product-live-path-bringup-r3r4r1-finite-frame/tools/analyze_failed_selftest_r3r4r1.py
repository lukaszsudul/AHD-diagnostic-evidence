#!/usr/bin/env python3
"""Evidence-only diagnosis of the stopped R3R4R1 offline self-test."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import capture_r3r4 as capture
from abi_v1 import AbiContract
from capture_r3r4_selftest import build_records


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R1_20260907T050126Z")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    failure_path = (
        ROOT / "artifacts" /
        "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE.json"
    )
    success = ROOT / "artifacts/offline-selftest/successful-capture"
    reader = json.loads((success / "T34-reader-result.json").read_text("utf-8"))
    failure = json.loads(failure_path.read_text("utf-8"))

    timeline = [
        (False, False, 0.0),
        (False, True, 0.2),
        (True, False, 1.0),
        (True, True, 1.4),
        (True, False, 2.0),
        (True, False, 2.8),
        (True, False, 3.01),
    ]
    quiet_since = None
    actual = []
    for parent_pass, data, now in timeline:
        quiet_since, done = capture.quiet_window_update(
            parent_pass, data, now, quiet_since, 1.0
        )
        actual.append(done)
    coded_expectation = [False, False, False, False, False, False, True]

    contract = AbiContract.load(
        ROOT / "scripts/V41_C2H_TRANSPORT_ABI_V1.json"
    )
    records = build_records(contract, capture.PRIMARY_TARGET + 7)
    expected_stream = b"".join(records)
    primary_path = success / "T34-primary-records.bin"
    drain_path = success / "T34-drain-records.bin"
    reconstructed = primary_path.read_bytes() + drain_path.read_bytes()

    sizes = (1, 7, 4095, 2, 8191, 31, 65537, 8192, 3, 131071)
    offset = 0
    actual_sizes = []
    boundaries = []
    spans = []
    while offset < len(expected_stream):
        end = min(offset + sizes[len(actual_sizes) % len(sizes)],
                  len(expected_stream))
        actual_sizes.append(end - offset)
        boundaries.append(end)
        spans.append(
            offset // capture.RECORD_BYTES !=
            (end - 1) // capture.RECORD_BYTES
        )
        offset = end

    partial_checks = {
        "chunk_smaller_than_4096":
            any(size < capture.RECORD_BYTES for size in actual_sizes),
        "chunk_larger_than_4096":
            any(size > capture.RECORD_BYTES for size in actual_sizes),
        "cumulative_boundary_unaligned":
            any(value % capture.RECORD_BYTES for value in boundaries[:-1]),
        "chunk_spans_multiple_records": any(spans),
        "more_than_one_chunk": len(actual_sizes) > 1,
        "complete_records_2507": reader["complete_records"] == 2507,
        "reconstructed_stream_byte_identical": reconstructed == expected_stream,
        "primary_records_2500": reader["primary_records"] == 2500,
        "primary_bytes_10240000": reader["primary_bytes"] == 10_240_000,
        "drain_records_7": reader["drain_records"] == 7,
        "drain_bytes_28672": reader["drain_bytes"] == 28_672,
        "trailing_bytes_zero": reader["incomplete_trailing_bytes"] == 0,
        "primary_hash_independently_matches":
            reader["primary_sha256"] == sha256(primary_path),
        "drain_hash_independently_matches":
            reader["drain_sha256"] == sha256(drain_path),
    }

    result = {
        "schema": "R3R4R1_STOPPED_SELFTEST_DIAGNOSIS_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R1",
        "governed_suite_rerun": False,
        "capture_tool_or_selftest_modified_after_failure": False,
        "hardware_access": False,
        "dut_connections": 0,
        "suite_result": "BLOCKED",
        "first_blocker": failure["blocker"],
        "exception_type": failure["exception_type"],
        "exception_repr": failure["exception_repr"],
        "traceback": failure["traceback"],
        "passed": 4,
        "total": 11,
        "cases": {
            "FIRST_RECORD_PERSISTENCE_PASS": "PASS",
            "PARTIAL_READ_ASSEMBLY_PASS": "PASS",
            "PRIMARY_2500_BOUNDARY_PASS": "PASS",
            "DRAIN_CAPTURE_PASS": "PASS",
            "PARENT_QUIESCENCE_HANDSHAKE_PASS": "FAIL",
            "FAILURE_PRESERVES_RAW_DATA_PASS": "NOT_REACHED",
            "EXCEPTION_DETAIL_PASS": "NOT_REACHED",
            "COMPLETE_FRAME_RECONSTRUCTION_PASS": "NOT_REACHED",
            "EXACT_CAPTURE_HASH_PASS": "NOT_REACHED",
            "NO_BLANK_BLOCKER_PASS": "NOT_REACHED",
            "NO_RAW_RECORD_IPC_PASS": "NOT_REACHED",
        },
        "partial_read_semantic_checks": partial_checks,
        "partial_read_semantic_result":
            "PASS" if all(partial_checks.values()) else "FAIL",
        "quiet_window_timeline": [
            {
                "parent_quiescent": parent,
                "data_received": data,
                "time_seconds": now,
                "actual_complete": done,
                "coded_expected_complete": expected,
            }
            for (parent, data, now), done, expected
            in zip(timeline, actual, coded_expectation)
        ],
        "actual_completions": actual,
        "coded_expected_completions": coded_expectation,
        "diagnosed_failed_assertion":
            "PARENT_QUIESCENCE_HANDSHAKE_EXPECTATION_MISMATCH",
        "diagnosis":
            "At t=2.8 seconds the frozen function correctly reports completion "
            "because 1.4 seconds elapsed since data at t=1.4; the self-test "
            "incorrectly expects False at that position.",
        "primary_sha256": sha256(primary_path),
        "drain_sha256": sha256(drain_path),
        "first_record_sha256": sha256(success / "T34-first-record.bin"),
        "first_payload_sha256": sha256(success / "T34-first-payload.bin"),
    }
    output = (
        ROOT / "artifacts" /
        "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE_ANALYSIS.json"
    )
    output.write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
