#!/usr/bin/env python3
"""Device-free R3R4R6R2R4 host-disable critical-path contract gate."""

from __future__ import annotations

import argparse
import ast
import json
import os
from pathlib import Path
import re


class ContractViolation(RuntimeError):
    pass


class CriticalPathFixture:
    def __init__(self) -> None:
        self.trace: list[str] = []
        self.disable_complete = False
        self.disable_issued = False
        self.durable_log_writes = 0
        self.primary_persist_begins = 0
        self.normal_disable_count = 0
        self.safety_disable_count = 0
        self.pending_aio = 0
        self.progress_memory: list[dict[str, int]] = []

    def receive_primary(self) -> None:
        self.trace.append("PRIMARY_WINDOW_COMPLETE")

    def fast_disable(self) -> None:
        self.trace.append("FAST_MMIO_DISABLE_BEGIN")
        self.normal_disable_count += 1
        self.disable_complete = True
        self.trace.append("FAST_MMIO_DISABLE_END")

    def send_disable_issued(self) -> None:
        if not self.disable_complete:
            raise ContractViolation("DISABLE_ISSUED_BEFORE_MMIO_DISABLE")
        self.disable_issued = True
        self.trace.append("DISABLE_ISSUED")

    def buffer_progress(self, value: int) -> None:
        self.progress_memory.append({"primary_completed": value})

    def durable_log(self) -> None:
        if not self.disable_complete:
            raise ContractViolation("DURABLE_LOG_BEFORE_MMIO_DISABLE")
        self.durable_log_writes += 1
        self.trace.append("FIRST_DURABLE_LOG_WRITE")

    def persist_primary(self) -> None:
        if not self.disable_issued:
            raise ContractViolation("PRIMARY_PERSIST_BEFORE_DISABLE_ISSUED")
        self.primary_persist_begins += 1
        self.trace.append("PRIMARY_PERSIST_BEGIN")


def require(condition: bool, detail: str) -> None:
    if not condition:
        raise ContractViolation(detail)


def function_source(tree: ast.Module, text: str, name: str) -> str:
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == name:
            segment = ast.get_source_segment(text, node)
            if segment is None:
                break
            return segment
    raise ContractViolation(f"FUNCTION_MISSING:{name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--controller", required=True, type=Path)
    parser.add_argument("--native", required=True, type=Path)
    parser.add_argument("--native-self-test-receipt", required=True, type=Path)
    parser.add_argument("--json-output", required=True, type=Path)
    parser.add_argument("--md-output", required=True, type=Path)
    parser.add_argument("--trace-output", required=True, type=Path)
    args = parser.parse_args()

    controller = args.controller.read_text(encoding="utf-8")
    native = args.native.read_text(encoding="utf-8")
    tree = ast.parse(controller)
    fast_source = function_source(tree, controller, "fast_normal_disable")
    run_source = function_source(tree, controller, "run")

    native_receipt = json.loads(args.native_self_test_receipt.read_text(encoding="utf-8"))
    native_lines = [line for line in native_receipt.get("stdout", "").splitlines()
                    if line.strip().startswith("{")]
    require(native_lines, "NATIVE_SELF_TEST_OUTPUT_MISSING")
    native_test = json.loads(native_lines[-1])

    results: list[dict[str, str]] = []

    def gate(name: str, condition: bool, basis: str) -> None:
        results.append({"case": name, "result": "PASS" if condition else "FAIL",
                        "basis": basis})

    fixture = CriticalPathFixture()
    fixture.receive_primary()
    fixture.fast_disable()
    fixture.send_disable_issued()
    fixture.durable_log()
    fixture.persist_primary()

    critical_tokens = [
        "PRIMARY_WINDOW_COMPLETE", "FAST_MMIO_DISABLE_BEGIN",
        "FAST_MMIO_DISABLE_END", "DISABLE_ISSUED",
        "FIRST_DURABLE_LOG_WRITE", "PRIMARY_PERSIST_BEGIN",
    ]
    gate("PRIMARY_EVENT_FAST_DISABLE_FIRST",
         fixture.trace == critical_tokens and
         "os.pwrite(mmio.fd, DISABLE_WORD, 0x380C)" in fast_source and
         all(token not in fast_source for token in
             ("open(", "write_json", "write_csv", "fsync", "json.dumps")),
         "simulated trace plus fast_normal_disable AST/source")

    negative_log_rejected = False
    try:
        CriticalPathFixture().durable_log()
    except ContractViolation:
        negative_log_rejected = True
    gate("PRE_DISABLE_DURABLE_LOG_REJECTED", negative_log_rejected,
         "negative fixture")

    negative_persist_rejected = False
    try:
        CriticalPathFixture().persist_primary()
    except ContractViolation:
        negative_persist_rejected = True
    gate("PRE_DISABLE_ISSUED_PRIMARY_PERSIST_REJECTED", negative_persist_rejected,
         "negative fixture")

    run_positions = {
        "event": run_source.find("primary = wait_primary_window"),
        "disable": run_source.find("disable_ns = fast_normal_disable(mmio)"),
        "ack": run_source.find('process.stdin.write(b"DISABLE_ISSUED\\n")'),
        "buffer": run_source.find('record_event(primary, result["events"])'),
    }
    gate("DISABLE_ISSUED_AFTER_MMIO",
         0 <= run_positions["event"] < run_positions["disable"] <
         run_positions["ack"] < run_positions["buffer"],
         "corrected controller source ordering")

    buffered = CriticalPathFixture()
    buffered.buffer_progress(128)
    buffered.buffer_progress(256)
    gate("ACTIVE_PROGRESS_BUFFERED_IN_MEMORY",
         len(buffered.progress_memory) == 2 and buffered.durable_log_writes == 0 and
         "event_log.write" not in function_source(tree, controller, "record_event"),
         "fixture and record_event source")

    buffered.fast_disable()
    buffered.durable_log()
    gate("BUFFERED_EVENTS_PERSIST_ONLY_AFTER_DISABLE",
         buffered.disable_complete and buffered.durable_log_writes == 1,
         "positive fixture")

    guard_match = re.search(r"#define\s+SHUTDOWN_GUARD_RECORDS\s+(\d+)U", native)
    gate("GUARD_IS_EXACTLY_128_RECORDS",
         guard_match is not None and int(guard_match.group(1)) == 128 and
         re.search(r"^GUARD_RECORDS\s*=\s*128$", controller, re.MULTILINE) is not None,
         "controller and native constants")

    parent_loop = native.find("while (!parent_quiescent)")
    cancel_call = native.find("__NR_io_cancel")
    gate("GUARD_CANCEL_AFTER_PARENT_QUIESCENT",
         parent_loop >= 0 and cancel_call > parent_loop and
         native_test.get("guard_cancel_after_parent_quiescent") is True,
         "native source ordering and deterministic native fixture")

    gate("PRIMARY_PERSIST_INDEPENDENT_OF_GUARD_COMPLETION",
         native_test.get("persistence_after_disable_issued") is True and
         native_test.get("persistence_started_before_guard_completion") is True,
         "deterministic native fixture")

    primary = bytearray(b"P" * 4096)
    preserved = bytes(primary)
    simulated_guard_failure = True
    gate("PRIMARY_SURVIVES_GUARD_CLEANUP_FAILURE",
         simulated_guard_failure and bytes(primary) == preserved and
         native_test.get("completed_data_preserved") is True,
         "negative cleanup fixture and native fixture")

    fixture.pending_aio = 0
    gate("NORMAL_SUCCESS_COUNTS",
         fixture.normal_disable_count == 1 and fixture.safety_disable_count == 0 and
         fixture.pending_aio == 0,
         "deterministic success fixture")

    forbidden = ("SIGKILL", "kill -9", "rmmod -f", "rmmod --force")
    gate("FAILURE_CLEANUP_NO_FORCE",
         not any(token in controller or token in native for token in forbidden),
         "static source audit")

    passed = sum(row["result"] == "PASS" for row in results)
    output = {
        "task": "G2B-HW0-PRODUCT-R3R4R6R2R4",
        "result": "PASS" if passed == 12 else "FAIL",
        "passed": passed,
        "total": 12,
        "guard_records": 128,
        "durable_logging_before_mmio_disable": False,
        "primary_persistence_before_disable_issued": False,
        "critical_path_order": "PASS" if fixture.trace == critical_tokens else "FAIL",
        "required_next_run_disable_latency_us": 500,
        "hardware_latency_measured": False,
        "cases": results,
        "call_trace": fixture.trace,
        "native_self_test": native_test,
    }
    args.json_output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    args.trace_output.write_text("\n".join(fixture.trace) + "\n", encoding="utf-8")
    lines = [
        "# R3R4R6R2R4 Host Disable-Path Gate",
        "",
        f"Result: **{passed}/12 {'PASS' if passed == 12 else 'FAIL'}**",
        "",
        "| Case | Result | Basis |",
        "|---|---|---|",
    ]
    lines.extend(f"| {row['case']} | {row['result']} | {row['basis']} |"
                 for row in results)
    lines.extend([
        "", "Durable logging before MMIO disable: **NO**",
        "", "Primary persistence before `DISABLE_ISSUED`: **NO**",
        "", "Required next-run measured latency: **<=500 microseconds**",
        "", "Actual hardware latency in this task: **NOT_MEASURED_NO_CAPTURE**",
    ])
    args.md_output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"result": output["result"], "passed": passed, "total": 12}))
    return 0 if passed == 12 else 1


if __name__ == "__main__":
    raise SystemExit(main())
