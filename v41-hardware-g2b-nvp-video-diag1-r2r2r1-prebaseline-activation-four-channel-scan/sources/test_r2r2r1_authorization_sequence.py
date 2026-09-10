#!/usr/bin/env python3
"""Mocked sequence gate; this file performs no hardware access."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from r2r2r1_authorization_sequence import SEQUENCE, SequenceModel, SequenceViolation


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

    source = (args.scripts / "controller_nvp_video_diag1_r2r2r1.py").read_text(
        encoding="utf-8")
    program = (args.scripts /
               "Invoke-NvpVideoDiag1R2R2R1SramProgramOnce.ps1").read_text(
                   encoding="utf-8")
    connection = (args.scripts /
                  "Invoke-NvpVideoDiag1R2R2R1DutConnection.ps1").read_text(
                      encoding="utf-8")
    tcl = (args.scripts /
           "program-nvp-video-diag1-r2r2r1-once.tcl").read_text(
               encoding="utf-8")

    prebaseline = SequenceModel()
    denied_before_identity = denied(prebaseline, "DIAG_CLEAR_PASSED")
    for action in SEQUENCE[:4]:
        prebaseline.execute(action)
    require(prebaseline.completed[-1] == "FPGA_SRAM_PROGRAMMED",
            "PROGRAMMING_DID_NOT_PRECEDE_PREPARE")
    denied_scan_before_baseline = denied(prebaseline, "START_4X4_SCAN")

    nominal = SequenceModel()
    for action in SEQUENCE:
        nominal.execute(action)
    require(nominal.scan_authorized, "SCAN_NOT_AUTHORIZED_AFTER_BASELINE")
    require(SEQUENCE.index("FPGA_SRAM_PROGRAMMED") <
            SEQUENCE.index("PREPARE_A_PASSED") <
            SEQUENCE.index("PREPARE_B_PASSED") <
            SEQUENCE.index("DOUBLE_PREPARE_BASELINE_PASSED") <
            SEQUENCE.index("START_4X4_SCAN"),
            "NORMATIVE_ORDER_INVALID")
    require(source.index('execute_prepare(\n            mmio, args.baseline_root, "A"') <
            source.index('execute_prepare(\n            mmio, args.baseline_root, "B"') <
            source.index('baseline_gate_passed = True') <
            source.index('mmio.write_control(4, "START_4X4_SCAN")'),
            "IMPLEMENTED_BASELINE_TO_SCAN_ORDER_INVALID")
    require(program.count("G2B_NVP_VIDEO_DIAG1_R2R1_FOUR_CHANNEL_SCAN.bit") >= 2,
            "EXACT_BITSTREAM_NOT_PINNED")
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

    output = {
        "task": "G2B-NVP-VIDEO-DIAG1-R2R2R1",
        "result": "PASS",
        "hardware_accessed": False,
        "nominal_sequence": list(SEQUENCE),
        "programming_before_prepare": True,
        "scan_denied_before_baseline": True,
        "denied_before_identity": denied_before_identity,
        "denied_scan_before_baseline": denied_scan_before_baseline,
        "single_program_call": True,
        "flash_operations": 0,
        "target_ip": "10.132.1.111",
        "forbidden_ip_present": False,
        "sources": {
            path.name: hashlib.sha256(path.read_bytes()).hexdigest().upper()
            for path in (
                args.scripts / "controller_nvp_video_diag1_r2r2r1.py",
                args.scripts / "controller_nvp_capture_r2r2r1.py",
                args.scripts / "Invoke-NvpVideoDiag1R2R2R1SramProgramOnce.ps1",
                args.scripts / "Invoke-NvpVideoDiag1R2R2R1DutConnection.ps1",
                args.scripts / "program-nvp-video-diag1-r2r2r1-once.tcl",
            )
        },
    }
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print("R2R2R1_HOST_CONTROLLER_GATE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
