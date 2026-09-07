#!/usr/bin/env python3
"""Six-case focused offline gate for the R3R4R6 host receive correction."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from abi_v1 import (AbiContract, RecordMetadata, RecordValidationError,  # noqa: E402
                    build_record, deterministic_line_payload, parse_record)
from validate_r3r4r6 import continuity_bits  # noqa: E402

TASK = "G2B-HW0-PRODUCT-R3R4R6"


def check(name: str, body) -> dict:
    try:
        detail = body()
        return {"name": name, "result": "PASS", "detail": detail}
    except BaseException as exc:
        return {"name": name, "result": "FAIL",
                "detail": f"{type(exc).__name__}:{exc}"}


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def compile_case(source: Path, host: str) -> dict:
    command = [
        "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", host,
        "cc", "-std=c11", "-O2", "-Wall", "-Wextra", "-Werror", "-c",
        "-x", "c", "-o", "/dev/null", "-",
    ]
    completed = subprocess.run(command, input=source.read_bytes(),
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, timeout=30)
    require(completed.returncode == 0,
            "offline Linux compilation failed: " +
            completed.stderr.decode("utf-8", "replace").strip())
    return {
        "compile_host": host,
        "compile_host_role": "NON_DUT_OFFLINE_COMPILER",
        "compiler": "cc",
        "returncode": completed.returncode,
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest().upper(),
        "persistent_remote_output": False,
    }


def no_active_signal_case(native_text: str, controller_text: str) -> dict:
    forbidden = [r"SIGALRM", r"\balarm\s*\(", r"setitimer\s*\(",
                 r"\bsignal\s*\("]
    hits = [pattern for pattern in forbidden
            if re.search(pattern, native_text, re.IGNORECASE)]
    require(not hits, "active DMA signal construct present: " + repr(hits))
    require(".terminate(" not in controller_text and ".kill(" not in controller_text,
            "controller contains process termination path")
    return {"forbidden_hits": hits, "controller_forced_termination": False}


def open_flags_case(native_text: str) -> dict:
    require("O_RDONLY | O_CLOEXEC" in native_text,
            "required C2H read and close-on-exec flags missing")
    require("open_flags |= O_NOFOLLOW" in native_text,
            "no-follow flag missing")
    require("O_TRUNC" not in native_text, "truncate flag present")
    require("eop_flush" not in native_text, "end-of-packet flush present")
    return {"read_only": True, "close_on_exec": True, "no_follow": True,
            "truncate": False, "eop_flush": False}


def submission_order_case(native_text: str) -> dict:
    primary = native_text.index("long primary_submit = raw_io_submit")
    guard = native_text.index("long guard_submit = raw_io_submit")
    ready = native_text.index("prequeue_ns = monotonic_ns()")
    require(primary < guard < ready,
            "primary/guard/PREQUEUE_READY program order invalid")
    require("primary_submit != 1" in native_text and
            "guard_submit != 1" in native_text,
            "submission acceptance guards missing")
    return {"program_order": ["PRIMARY_SUBMIT", "GUARD_SUBMIT",
                               "PREQUEUE_READY"],
            "both_submit_results_required": True}


def parent_dependency_case(controller_text: str) -> dict:
    start = controller_text.index("prequeue = wait_for_type(")
    ready = controller_text.index('"PREQUEUE_READY"', start)
    enable = controller_text.index("enable_completed_ns = mmio.write", ready)
    precondition = controller_text.index('"PREQUEUE_READY")', enable)
    require(start < ready < enable < precondition,
            "parent enable is not guarded by PREQUEUE_READY")
    return {"prequeue_ready_before_enable": True,
            "enable_precondition": "PREQUEUE_READY"}


def metric_fixture_case(abi_path: Path) -> dict:
    contract = AbiContract.load(abi_path)
    payload = deterministic_line_payload(contract, 10, 7)
    base = dict(reset_epoch=4, source_frame_sequence=10,
                source_line_sequence=7, source_capture_sequence=100,
                channel_attempt_sequence=200, global_stream_sequence=300,
                slot=3, slot_generation=2)
    discontinuity = build_record(
        contract, RecordMetadata(**base, discontinuity=True), payload)
    malformed = build_record(
        contract, RecordMetadata(**base, malformed_preceding=True), payload)
    parsed_discontinuity = parse_record(contract, discontinuity)
    parsed_malformed = parse_record(contract, malformed)
    discontinuity_bits = continuity_bits(contract,
                                          parsed_discontinuity.flags)
    malformed_bits = continuity_bits(contract, parsed_malformed.flags)
    require(discontinuity_bits["discontinuity"] and
            not malformed_bits["discontinuity"],
            "continuity separation fixture failed")
    require(malformed_bits["malformed_preceding"] and
            not discontinuity_bits["malformed_preceding"],
            "malformed-preceding separation fixture failed")

    bad_magic = bytearray(discontinuity)
    bad_magic[0] ^= 0x01
    try:
        parse_record(contract, bytes(bad_magic))
        raise AssertionError("bad magic passed integrity")
    except RecordValidationError:
        pass
    bad_padding = bytearray(discontinuity)
    bad_padding[3904] = 1
    try:
        parse_record(contract, bytes(bad_padding))
        raise AssertionError("nonzero padding passed integrity")
    except RecordValidationError:
        pass

    returned = discontinuity + b"P" * 3584
    complete_records = len(returned) // 4096
    partial_bytes = len(returned) % 4096
    integrity_failures = 0
    for index in range(complete_records):
        try:
            parse_record(contract, returned[index * 4096:(index + 1) * 4096])
        except RecordValidationError:
            integrity_failures += 1
    require((complete_records, partial_bytes, integrity_failures) == (1, 3584, 0),
            "partial returned bytes were misclassified as a record")
    return {
        "valid_discontinuity_record_integrity": "PASS",
        "valid_malformed_preceding_record_integrity": "PASS",
        "continuity_classification_separate": True,
        "bad_magic_integrity": "FAIL_EXPECTED",
        "nonzero_padding_integrity": "FAIL_EXPECTED",
        "partial_returned_bytes": 3584,
        "partial_counted_as_additional_malformed_record": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--compile-host", default="ahd-ubuntu")
    args = parser.parse_args()
    root = Path(args.root)
    scripts = root / "scripts"
    native = scripts / "prequeued_c2h_capture.c"
    controller = scripts / "controller_r3r4r6.py"
    native_text = native.read_text(encoding="utf-8")
    controller_text = controller.read_text(encoding="utf-8")
    cases = [
        check("NATIVE_HELPER_COMPILES_PASS",
              lambda: compile_case(native, args.compile_host)),
        check("NO_ACTIVE_DMA_SIGNAL_INTERRUPTION_PASS",
              lambda: no_active_signal_case(native_text, controller_text)),
        check("C2H_OPEN_FLAGS_PASS", lambda: open_flags_case(native_text)),
        check("TWO_AIO_REQUESTS_PREQUEUED_PASS",
              lambda: submission_order_case(native_text)),
        check("PREQUEUE_READY_ENABLE_DEPENDENCY_PASS",
              lambda: parent_dependency_case(controller_text)),
        check("METRIC_SPLIT_FIXTURE_PASS",
              lambda: metric_fixture_case(
                  scripts / "V41_C2H_TRANSPORT_ABI_V1.json")),
    ]
    passed = sum(case["result"] == "PASS" for case in cases)
    result = {
        "schema": "R3R4R6_FOCUSED_HOST_TOOL_GATE_V1", "task": TASK,
        "result": "PASS" if passed == 6 else "FAIL", "passed": passed,
        "total": 6, "correction_iterations_used": 0, "cases": cases,
        "dut_connection": False, "hardware_access": False,
    }
    output = root / "artifacts" / "focused-host-tool-gate.json"
    with output.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
    print(json.dumps(result, indent=2))
    return 0 if passed == 6 else 1


if __name__ == "__main__":
    raise SystemExit(main())
