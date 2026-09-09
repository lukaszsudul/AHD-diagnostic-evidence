#!/usr/bin/env python3
"""Focused 16-case static/fixture gate for the BT656 FIX1 host path."""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
from typing import Any


class GateFailure(RuntimeError):
    pass


def require(condition: bool, detail: str) -> None:
    if not condition:
        raise GateFailure(detail)


def function_source(tree: ast.Module, text: str, name: str) -> str:
    for node in tree.body:
        if isinstance(node, ast.FunctionDef) and node.name == name:
            source = ast.get_source_segment(text, node)
            if source is not None:
                return source
    raise GateFailure(f"FUNCTION_MISSING:{name}")


def receipt(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"RECEIPT_SCHEMA:{path.name}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--controller", required=True, type=Path)
    parser.add_argument("--native", required=True, type=Path)
    parser.add_argument("--validator", required=True, type=Path)
    parser.add_argument("--compile-receipt", required=True, type=Path)
    parser.add_argument("--smoke-receipt", required=True, type=Path)
    parser.add_argument("--selftest-receipt", required=True, type=Path)
    parser.add_argument("--json-output", required=True, type=Path)
    parser.add_argument("--md-output", required=True, type=Path)
    args = parser.parse_args()

    controller = args.controller.read_text(encoding="utf-8")
    native = args.native.read_text(encoding="utf-8")
    validator = args.validator.read_text(encoding="utf-8")
    tree = ast.parse(controller)
    run_source = function_source(tree, controller, "run")
    fast_source = function_source(tree, controller, "fast_normal_disable")
    record_source = function_source(tree, controller, "record_event")
    compile_result = receipt(args.compile_receipt)
    smoke_result = receipt(args.smoke_receipt)
    selftest_result = receipt(args.selftest_receipt)
    lines = [line for line in selftest_result.get("stdout", "").splitlines()
             if line.startswith("{")]
    require(lines, "SELFTEST_JSON_MISSING")
    selftest = json.loads(lines[-1])

    cases: list[dict[str, str]] = []

    def gate(name: str, condition: bool, basis: str) -> None:
        cases.append({"case": name, "result": "PASS" if condition else "FAIL",
                      "basis": basis})

    compile_stdout = compile_result.get("stdout", "")
    gate("NATIVE_HELPER_COMPILES",
         compile_result.get("exit_code") == 0 and "COMPILE_RC=0" in compile_stdout and
         "STDERR_BEGIN\nSTDERR_END" in compile_stdout,
         "DUT-local gcc receipt")
    gate("NATIVE_HELPER_X86_64",
         "ELF 64-bit" in compile_stdout and "Machine:" in compile_stdout and
         "X86-64" in compile_stdout,
         "file/readelf receipt")
    gate("NO_DEVICE_SMOKE_TEST",
         smoke_result.get("exit_code") == 0 and
         "SMOKE_RC=64" in smoke_result.get("stdout", "") and
         "usage:" in smoke_result.get("stdout", ""),
         "no-argument DUT-local smoke receipt")
    gate("MAX_OUTSTANDING_1024",
         re.search(r"#define\s+MAX_OUTSTANDING_IOCBS\s+1024U", native) is not None and
         selftest.get("maximum_permitted_outstanding") == 1024 and
         selftest.get("maximum_outstanding") == 1024,
         "native constants and deterministic fixture")
    gate("TOTAL_LOGICAL_REQUESTS_2500",
         re.search(r"#define\s+TOTAL_LOGICAL_REQUESTS\s+PRIMARY_RECORDS", native) is not None and
         selftest.get("total_logical_requests") == 2500 and
         selftest.get("total_submitted") == 2500,
         "primary-only constant and fixture")
    gate("NO_GUARD_REQUESTS",
         re.search(r"#define\s+SHUTDOWN_GUARD_RECORDS\s+0U", native) is not None and
         re.search(r"^GUARD_RECORDS\s*=\s*0$", controller, re.MULTILINE) is not None and
         selftest.get("guard_records") == 0 and
         selftest.get("no_guard_requests") is True,
         "controller/native constants and fixture")
    gate("NO_REQUEST_AFTER_2499",
         selftest.get("total_submitted") == 2500 and
         "m->next_submit < TOTAL_LOGICAL_REQUESTS" in native and
         "pointers + m->next_submit" in native,
         "bounded next-submit loop and fixture")
    gate("PRIMARY_WINDOW_AT_2500_EXACT",
         selftest.get("primary_event_at_2500") is True and
         selftest.get("primary_completed_when_event_emitted") == 2500 and
         "m->primary_exact == PRIMARY_RECORDS" in native,
         "native event guard and fixture")
    gate("PENDING_AIO_ZERO_AT_PRIMARY_WINDOW",
         selftest.get("pending_at_primary_window_complete") == 0 and
         "pending_aio" in native and 'primary.get("pending_aio") == 0' in controller,
         "native event and parent acceptance guard")

    ordering = {
        "event": run_source.find("primary = wait_primary_window"),
        "disable": run_source.find("disable_ns = fast_normal_disable(mmio)"),
        "ack": run_source.find('process.stdin.write(b"DISABLE_ISSUED\\n")'),
        "buffer": run_source.find('record_event(primary, result["events"])'),
    }
    gate("IMMEDIATE_DISABLE_BEFORE_DURABLE_LOGGING",
         0 <= ordering["event"] < ordering["disable"] < ordering["ack"] < ordering["buffer"] and
         "os.pwrite(mmio.fd, DISABLE_WORD, 0x380C)" in fast_source and
         not any(token in fast_source for token in
                 ("write_json", "write_csv", "json.dumps", "fsync", "open(")),
         "controller AST/source ordering")
    gate("PRIMARY_PERSIST_AFTER_DISABLE_ISSUED",
         selftest.get("persistence_before_disable_issued") is False and
         selftest.get("persistence_after_disable_issued") is True and
         "if (!failure && disable_issued && !m.primary_durable)" in native,
         "native handshake fixture and source")
    gate("ACTIVE_EVENTS_BUFFERED_IN_RAM",
         "events.append(event)" in record_source and
         "write" not in record_source and "fsync" not in record_source and
         ordering["buffer"] > ordering["disable"],
         "record_event AST/source")
    gate("VERTICAL_TAIL_CAPTURE_SEQUENCE_RULE",
         "expected_capture_delta = 22 if frame_boundary else 1" in validator and
         "expected_vertical_tail_capture_sequence_jumps" in validator and
         "unexpected_source_capture_sequence_gaps" in validator,
         "validator bounded frame-boundary rule")
    gate("POST_TARGET_FLUSH_CANNOT_CHANGE_PRIMARY",
         run_source.find("primary = wait_primary_window") <
         run_source.find('mmio.write(0x380C, 4, "POST_TARGET_TAIL_FLUSH"') and
         run_source.find("disable_ns = fast_normal_disable(mmio)") <
         run_source.find('mmio.write(0x380C, 4, "POST_TARGET_TAIL_FLUSH"') and
         "persist_primary_full" in native,
         "tail flush is parent-side and strictly post-primary/post-disable")
    gate("NORMAL_PATH_NO_IO_CANCEL",
         selftest.get("io_cancel_calls") == 0 and
         "size_t cancel_start = failure ? 0 : PRIMARY_RECORDS" in native and
         selftest.get("pending_at_primary_window_complete") == 0,
         "primary-only deterministic normal path")
    forbidden = ("SIGALRM", "alarm(", "setitimer(", "O_TRUNC", "eop_flush")
    gate("FORBIDDEN_ACTIVE_RECEIVE_FEATURES_ABSENT",
         not any(token in native or token in controller for token in forbidden),
         "static source audit")

    passed = sum(case["result"] == "PASS" for case in cases)
    output = {
        "task": "AHD-v41-G2B-BT656-FIX1",
        "result": "PASS" if passed == 16 else "FAIL",
        "passed": passed,
        "total": 16,
        "cases": cases,
        "native_self_test": selftest,
        "critical_path_positions": ordering,
    }
    args.json_output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    report = [
        "# G2B BT656 FIX1 Host-Tool Gate", "",
        f"Result: **{passed}/16 {'PASS' if passed == 16 else 'FAIL'}**", "",
        "| Case | Result | Basis |", "|---|---|---|",
    ]
    report.extend(f"| {row['case']} | {row['result']} | {row['basis']} |"
                  for row in cases)
    args.md_output.write_text("\n".join(report) + "\n", encoding="utf-8")
    print(json.dumps({"result": output["result"], "passed": passed, "total": 16}))
    return 0 if passed == 16 else 1


if __name__ == "__main__":
    raise SystemExit(main())
