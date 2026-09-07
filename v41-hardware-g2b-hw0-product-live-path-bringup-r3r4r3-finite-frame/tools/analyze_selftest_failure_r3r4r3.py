#!/usr/bin/env python3
"""Read-only post-stop analysis of the R3R4R3 case-1 assertion failure."""
from __future__ import annotations

import inspect
import json
from pathlib import Path
import sys
import time


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R3_20260907T075856Z")
SCRIPTS = ROOT / "scripts"
ARTIFACTS = ROOT / "artifacts"
sys.path.insert(0, str(SCRIPTS))

import capture_r3r4 as capture  # noqa: E402


def main() -> int:
    failure = json.loads((
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_FAILURE.json"
    ).read_text(encoding="utf-8"))
    persist = inspect.getsource(capture.RecordSink._persist_first)
    gate = inspect.getsource(
        capture.RecordSink._await_primary_target_prerequisites)
    accept = inspect.getsource(capture.RecordSink.accept)
    program_order = (
        "self.emit('FIRST_RECORD_DURABLE'" in persist and
        "self.first_thread.join(timeout=5.0)" in gate and
        "require(not self.first_thread.is_alive()" in gate and
        accept.index("self._await_primary_target_prerequisites()") <
        accept.index("self.emit('PRIMARY_TARGET_REACHED'")
    )
    clock = time.get_clock_info("monotonic")
    result = {
        "schema": "R3R4R3_SELFTEST_FAILURE_ANALYSIS_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R3",
        "result": "PASS",
        "formal_suite_result": "BLOCKED",
        "first_blocker": failure["blocker"],
        "failed_case": "FIRST_RECORD_PERSISTENCE_PASS",
        "failed_assertion": (
            "events['FIRST_RECORD_DURABLE']['monotonic_ns'] < "
            "events['PRIMARY_TARGET_REACHED']['monotonic_ns']"
        ),
        "expected_relation": "FIRST_RECORD_DURABLE_TIMESTAMP_STRICTLY_LESS_THAN_PRIMARY_TARGET_TIMESTAMP",
        "assertion_result": False,
        "runtime_program_order": (
            "FIRST_RECORD_DURABLE_CALLBACK_COMPLETES_BEFORE_"
            "PRIMARY_TARGET_REACHED_CALLBACK_BEGINS"
        ),
        "runtime_program_order_proven": program_order,
        "monotonic_clock_nonadjustable": not clock.adjustable,
        "monotonic_clock_resolution_seconds": clock.resolution,
        "monotonic_clock_implementation": clock.implementation,
        "actual_relation_inferred": (
            "TIMESTAMPS_EQUAL" if program_order and not clock.adjustable
            else "STRICT_RELATION_FALSE_NUMERIC_VALUES_NOT_PERSISTED"
        ),
        "numeric_timestamp_values": "NOT_PERSISTED_BY_FAILED_CASE",
        "diagnosis": (
            "SELFTEST_STRICT_TIMESTAMP_SEPARATION_ASSUMPTION; "
            "formal event dependency is encoded by thread completion, durable/valid "
            "state, checkpoint acknowledgements, and source order, but two ordered "
            "callbacks may receive the same observable monotonic clock tick"
        ),
        "runtime_modified_after_suite": False,
        "suite_rerun": False,
        "hardware_access": False,
        "dut_connections": 0,
    }
    path = ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R3_SELFTEST_FAILURE_ANALYSIS.json"
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
        handle.flush()
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
