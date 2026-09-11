#!/usr/bin/env python3
"""Mocked R3 hardware-order gate. This file performs no hardware access."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from r3_hardware_sequence import SEQUENCE, SequenceModel, SequenceViolation


def require(value: bool, message: str) -> None:
    if not value:
        raise RuntimeError(message)


def denied(model: SequenceModel, action: str) -> str:
    try:
        model.execute(action)
    except SequenceViolation as exc:
        return str(exc)
    raise RuntimeError(f"UNEXPECTEDLY_ALLOWED:{action}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scripts", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    controller_path = args.scripts / "controller_nvp_video_diag1_r3.py"
    program_path = args.scripts / "Invoke-NvpVideoDiag1R3SramProgramOnce.ps1"
    connection_path = args.scripts / "Invoke-NvpVideoDiag1R3DutConnection.ps1"
    tcl_path = args.scripts / "program-nvp-video-diag1-r3-once.tcl"
    controller = controller_path.read_text(encoding="utf-8")
    program = program_path.read_text(encoding="utf-8")
    connection = connection_path.read_text(encoding="utf-8")
    tcl = tcl_path.read_text(encoding="utf-8")

    before_smoke = SequenceModel()
    for action in SEQUENCE[:9]:
        before_smoke.execute(action)
    smoke_denial = denied(before_smoke, "START_4X4_SCAN")

    before_baseline = SequenceModel()
    for action in SEQUENCE[:13]:
        before_baseline.execute(action)
    baseline_denial = denied(before_baseline, "START_4X4_SCAN")

    nominal = SequenceModel()
    for action in SEQUENCE:
        nominal.execute(action)
    require(nominal.scan_authorized, "SCAN_NOT_AUTHORIZED_AFTER_ALL_GATES")
    require(
        SEQUENCE.index("FPGA_SRAM_PROGRAMMED")
        < SEQUENCE.index("READ_ONLY_RUNTIME_IDENTITY_PASSED")
        < SEQUENCE.index("HARDWARE_MMIO_WRITE_READ_32_OF_32_PASSED")
        < SEQUENCE.index("PREPARE_A_PASSED")
        < SEQUENCE.index("PREPARE_B_PASSED")
        < SEQUENCE.index("DOUBLE_PREPARE_BASELINE_PASSED")
        < SEQUENCE.index("START_4X4_SCAN"),
        "NORMATIVE_ORDER_INVALID",
    )
    require(
        controller.index('execute_prepare(\n            mmio, args.baseline_root, "A"')
        < controller.index('execute_prepare(\n            mmio, args.baseline_root, "B"')
        < controller.index("baseline_gate_passed = True")
        < controller.index('mmio.write_control(4, "START_4X4_SCAN")'),
        "CONTROLLER_BASELINE_TO_SCAN_ORDER_INVALID",
    )
    require("DIAG_VERSION = 0x00010002" in controller,
            "R3_DIAG_VERSION_NOT_PINNED")
    require("capabilities == 0x00000BFF" in controller,
            "R3_CAPABILITIES_NOT_PINNED")
    require("EC3A79064F03010E9E8B42A557DE57FA5E82849C1E2C37D2F3E662439211034F"
            in program, "R3_BITSTREAM_HASH_NOT_PINNED")
    require(tcl.count("program_hw_devices $device") == 1,
            "PROGRAM_CALL_COUNT_NOT_ONE")
    require(not any(token in tcl.lower() for token in
                    ("program_hw_cfgmem", "create_hw_cfgmem", "write_cfgmem")),
            "FLASH_OPERATION_PRESENT")
    forbidden_ip = "10.132.1." + "227"
    require("10.132.1.111" in connection and forbidden_ip not in connection,
            "TARGET_IP_CONTRACT_FAILED")
    require("-pwfile" in connection and "'-pw'," not in connection,
            "CREDENTIAL_ARGUMENT_CONTRACT_FAILED")

    sources = (controller_path, program_path, connection_path, tcl_path)
    result = {
        "task": "G2B-NVP-VIDEO-DIAG1-R3",
        "result": "PASS",
        "hardware_accessed": False,
        "nominal_sequence": list(SEQUENCE),
        "smoke_required_before_scan": True,
        "double_prepare_required_before_scan": True,
        "scan_denial_before_smoke": smoke_denial,
        "scan_denial_before_double_prepare": baseline_denial,
        "single_program_call": True,
        "flash_operations": 0,
        "target_ip": "10.132.1.111",
        "forbidden_ip_present": False,
        "sources": {
            path.name: hashlib.sha256(path.read_bytes()).hexdigest().upper()
            for path in sources
        },
    }
    with args.output.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
    print("R3_HOST_CONTROLLER_SEQUENCE_GATE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

