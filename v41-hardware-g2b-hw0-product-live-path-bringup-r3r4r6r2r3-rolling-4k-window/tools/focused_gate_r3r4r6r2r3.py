#!/usr/bin/env python3
"""Fourteen-check device-free gate for the 1024-descriptor rolling helper."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
from typing import Any


def execute(command: list[str], timeout: float = 30.0) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, text=True, capture_output=True,
                          timeout=timeout, check=False)


def check(name: str, passed: bool, detail: Any) -> dict[str, Any]:
    return {"case": name, "result": "PASS" if passed else "FAIL", "detail": detail}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--build-report", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    build = json.loads(args.build_report.read_text(encoding="utf-8"))
    file_text = json.dumps(build.get("inspections", {}).get("file", {}))
    smoke = execute([str(args.binary)]) if args.binary.is_file() else None
    synthetic_run = execute([str(args.binary), "--self-test"]) if args.binary.is_file() else None
    synthetic: dict[str, Any] = {}
    if synthetic_run and synthetic_run.stdout.strip():
        try:
            synthetic = json.loads(synthetic_run.stdout.strip().splitlines()[-1])
        except json.JSONDecodeError:
            synthetic = {}

    constants = {
        "record": bool(re.search(r"#define\s+RECORD_BYTES\s+4096U", source)),
        "primary_records": bool(re.search(r"#define\s+PRIMARY_RECORDS\s+2500U", source)),
        "guard_records": bool(re.search(r"#define\s+SHUTDOWN_GUARD_RECORDS\s+32U", source)),
        "max_outstanding": bool(re.search(r"#define\s+MAX_OUTSTANDING_IOCBS\s+1024U", source)),
        "context": bool(re.search(r"#define\s+AIO_CONTEXT_CAPACITY\s+1152U", source)),
        "batch": bool(re.search(r"#define\s+COMPLETION_BATCH_MAX\s+128U", source)),
        "progress": bool(re.search(r"#define\s+PROGRESS_INTERVAL_RECORDS\s+128U", source)),
        "no_progress": "NO_PROGRESS_TIMEOUT_NS UINT64_C(1000000000)" in source,
        "total_timeout": "TOTAL_CAPTURE_TIMEOUT_NS UINT64_C(5000000000)" in source,
        "request_geometry": ("requests[i].cb.aio_nbytes = RECORD_BYTES;" in source and
                             "requests[i].cb.aio_offset = 0;" in source and
                             "requests[i].cb.aio_data = i;" in source),
    }
    forbidden = {
        "SIGALRM": bool(re.search(r"\bSIGALRM\b", source)),
        "alarm": bool(re.search(r"\balarm\s*\(", source)),
        "setitimer": bool(re.search(r"\bsetitimer\s*\(", source)),
        "O_TRUNC": bool(re.search(r"\bO_TRUNC\b", source)),
        "eop_flush": bool(re.search(r"\beop_flush\b", source)),
    }

    rows = [
        check("NATIVE_SOURCE_COMPILES_PASS",
              build.get("result") == "PASS" and build.get("compile_return_code") == 0,
              {"return_code": build.get("compile_return_code"),
               "unsafe_warning": build.get("unsafe_warning")}),
        check("NATIVE_BINARY_X86_64_PASS",
              args.binary.is_file() and ("x86-64" in file_text or "x86_64" in file_text),
              file_text),
        check("NO_DEVICE_USAGE_SMOKE_PASS",
              smoke is not None and smoke.returncode == 64 and
              "usage:" in smoke.stderr.lower() and "/dev/xdma0_c2h_0" in smoke.stderr,
              {"return_code": None if smoke is None else smoke.returncode,
               "stderr": None if smoke is None else smoke.stderr.strip()}),
        check("FROZEN_CONSTANTS_EXACT_PASS", all(constants.values()), constants),
        check("INITIAL_PREQUEUE_EXACTLY_1024_PASS",
              synthetic.get("initial_submitted") == 1024 and
              synthetic.get("initial_outstanding") == 1024,
              {"submitted": synthetic.get("initial_submitted"),
               "outstanding": synthetic.get("initial_outstanding")}),
        check("MAX_OUTSTANDING_HARD_LIMIT_1024_PASS",
              synthetic.get("maximum_permitted_outstanding") == 1024 and
              isinstance(synthetic.get("maximum_outstanding"), int) and
              synthetic["maximum_outstanding"] <= 1024,
              {"permitted": synthetic.get("maximum_permitted_outstanding"),
               "observed": synthetic.get("maximum_outstanding")}),
        check("ROLLING_REFILL_REACHES_2532_PASS",
              synthetic.get("result") == "PASS" and
              synthetic.get("total_submitted") == 2532 and
              synthetic.get("descriptor_starvation_events") == 0,
              {"total_submitted": synthetic.get("total_submitted"),
               "starvation": synthetic.get("descriptor_starvation_events")}),
        check("CUMULATIVE_SUBMISSION_CROSSES_2048_PASS",
              synthetic.get("crossed_logical_index_2048") is True and
              isinstance(synthetic.get("cumulative_submissions_when_2048_crossed"), int) and
              2048 < synthetic["cumulative_submissions_when_2048_crossed"] <= 2532,
              synthetic.get("cumulative_submissions_when_2048_crossed")),
        check("PRIMARY_WINDOW_EVENT_AT_2500_PASS",
              synthetic.get("primary_event_at_2500") is True and
              synthetic.get("primary_completed_when_event_emitted") == 2500 and
              synthetic.get("primary_completed") == 2500,
              {"event": synthetic.get("primary_event_at_2500"),
               "at": synthetic.get("primary_completed_when_event_emitted")}),
        check("PRIMARY_PLACEMENT_BY_LOGICAL_INDEX_PASS",
              synthetic.get("placement_by_logical_index") is True and
              "primary + i * (size_t)RECORD_BYTES" in source,
              synthetic.get("placement_by_logical_index")),
        check("PRIMARY_PERSISTENCE_INDEPENDENT_OF_GUARD_PASS",
              synthetic.get("persistence_started_before_guard_completion") is True and
              "persist_primary_full(argv[2], primary, &m)" in source,
              synthetic.get("persistence_started_before_guard_completion")),
        check("PARENT_QUIESCENCE_GUARD_ONLY_CANCEL_PASS",
              synthetic.get("guard_cancel_targets_only") is True and
              "size_t cancel_start = failure ? 0 : PRIMARY_RECORDS;" in source,
              synthetic.get("guard_cancel_targets_only")),
        check("COMPLETED_DATA_SURVIVES_LATER_CLEANUP_FAILURE_PASS",
              synthetic.get("completed_data_preserved") is True and
              "primary-partial-by-index.bin" in source,
              synthetic.get("completed_data_preserved")),
        check("FORBIDDEN_ACTIVE_DMA_MECHANISMS_ABSENT_PASS",
              not any(forbidden.values()), forbidden),
    ]
    passed = sum(row["result"] == "PASS" for row in rows)
    report = {
        "schema": "R3R4R6R2R3_ROLLING_HOST_TOOL_GATE_V1",
        "result": "PASS" if passed == 14 else "FAIL",
        "passed": passed,
        "total": 14,
        "cases": rows,
        "synthetic_fixture": synthetic,
        "smoke_stdout": None if smoke is None else smoke.stdout,
        "smoke_stderr": None if smoke is None else smoke.stderr,
        "synthetic_stdout": None if synthetic_run is None else synthetic_run.stdout,
        "synthetic_stderr": None if synthetic_run is None else synthetic_run.stderr,
        "device_access": False,
    }
    with args.output.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    print(json.dumps({"result": report["result"], "passed": passed,
                      "total": 14}, sort_keys=True))
    return 0 if passed == 14 else 1


if __name__ == "__main__":
    raise SystemExit(main())
