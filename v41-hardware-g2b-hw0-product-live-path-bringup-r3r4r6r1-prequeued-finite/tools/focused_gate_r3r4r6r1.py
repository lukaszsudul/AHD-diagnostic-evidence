#!/usr/bin/env python3
"""Close the R3R4R6R1 focused gate from the DUT-local build receipt."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R1_20260907T202452Z")
EXPECTED_SOURCE_SHA256 = (
    "D9F4DA042A02BB55FE8B1BCC990BC2D2001D2F01F5DFB8987094042F9731CCD7"
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def main() -> int:
    prior = json.loads(
        (ROOT / "artifacts/r3r4r6-focused-host-tool-gate.json").read_text(
            encoding="utf-8"
        )
    )
    compile_receipt = json.loads(
        (ROOT / "logs/connection-build_native_compile_1.json").read_text(
            encoding="utf-8"
        )
    )
    smoke_receipt = json.loads(
        (ROOT / "logs/connection-build_native_smoke.json").read_text(
            encoding="utf-8"
        )
    )
    source = ROOT / "scripts/prequeued_c2h_capture.c"
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest().upper()
    require(source_hash == EXPECTED_SOURCE_SHA256, "ACCEPTED_SOURCE_HASH_CHANGED")

    compile_text = compile_receipt.get("stdout", "")
    compile_ok = all(
        (
            compile_receipt.get("exit_code") == 0,
            compile_receipt.get("problem") is None,
            "GCC_PATH=/usr/bin/gcc" in compile_text,
            "COMPILE_RETURN_CODE=0" in compile_text,
            "COMPILE_STDERR_BEGIN\nCOMPILE_STDERR_END" in compile_text,
            "ELF 64-bit LSB pie executable, x86-64" in compile_text,
            "Machine:                           Advanced Micro Devices X86-64"
            in compile_text,
            "BINARY_SHA256=FF57965546A4AC86DB46558BFD9787903070D9B1399D595AF5068E98D46A853D"
            in compile_text,
        )
    )
    require(compile_ok, "DUT_LOCAL_NATIVE_COMPILE_RECEIPT_INVALID")
    smoke_text = smoke_receipt.get("stdout", "")
    require(
        smoke_receipt.get("exit_code") == 0
        and smoke_receipt.get("problem") is None
        and "SMOKE_RETURN_CODE=64" in smoke_text
        and "NO_DEVICE_ARGUMENT_SUPPLIED=true" in smoke_text
        and "SMOKE_TEST=PASS" in smoke_text,
        "DUT_LOCAL_NO_DEVICE_SMOKE_RECEIPT_INVALID",
    )

    accepted_names = {
        "NO_ACTIVE_DMA_SIGNAL_INTERRUPTION_PASS",
        "C2H_OPEN_FLAGS_PASS",
        "TWO_AIO_REQUESTS_PREQUEUED_PASS",
        "PREQUEUE_READY_ENABLE_DEPENDENCY_PASS",
        "METRIC_SPLIT_FIXTURE_PASS",
    }
    carried = [
        case
        for case in prior["cases"]
        if case["name"] in accepted_names and case["result"] == "PASS"
    ]
    require(len(carried) == 5, "R3R4R6_ACCEPTED_FIVE_CASES_NOT_PRESENT")
    cases = [
        {
            "name": "NATIVE_HELPER_COMPILES_PASS",
            "result": "PASS",
            "detail": {
                "compile_location": "AUTHORITATIVE_DUT_BUILD_ONLY",
                "compiler": "/usr/bin/gcc 15.2.0",
                "source_sha256": source_hash,
                "binary_sha256": "FF57965546A4AC86DB46558BFD9787903070D9B1399D595AF5068E98D46A853D",
                "architecture": "x86-64",
                "compile_return_code": 0,
                "warnings": [],
                "smoke_exit_code": 64,
                "smoke_test": "PASS",
                "hardware_accessed_during_build_phase": False,
            },
        },
        *carried,
    ]
    result = {
        "schema": "R3R4R6R1_FOCUSED_HOST_TOOL_GATE_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R6R1",
        "result": "PASS",
        "passed": 6,
        "total": 6,
        "source_lineage": "R3R4R6_SOURCE_REUSED_UNCHANGED",
        "compiler_correction_iterations": 0,
        "non_dut_compiler_host_10_132_1_227_used": False,
        "dut_build_only_connection": "PASS",
        "hardware_accessed_during_build_phase": False,
        "cases": cases,
    }
    output = ROOT / "artifacts/focused-host-tool-gate.json"
    with output.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
