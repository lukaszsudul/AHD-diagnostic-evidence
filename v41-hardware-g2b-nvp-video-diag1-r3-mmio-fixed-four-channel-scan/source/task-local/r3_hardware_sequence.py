#!/usr/bin/env python3
"""Pure host-side model of the governed R3 activation and scan sequence."""

from __future__ import annotations

SEQUENCE = (
    "OFFLINE_SIGNOFF_PASSED",
    "EXACT_R3_BITSTREAM_VERIFIED",
    "CONTROLLER_LOCK_ACQUIRED",
    "FPGA_SRAM_PROGRAMMED",
    "PRODUCT_EQUIVALENT_AUTOINIT_ALLOWED",
    "WARM_REBOOT_COMPLETED",
    "LINUX_LOCK_ACQUIRED",
    "EXACT_DRIVER_LOADED",
    "READ_ONLY_RUNTIME_IDENTITY_PASSED",
    "HARDWARE_MMIO_WRITE_READ_32_OF_32_PASSED",
    "BASELINE_CLEAR_PASSED",
    "PREPARE_A_PASSED",
    "PREPARE_B_PASSED",
    "DOUBLE_PREPARE_BASELINE_PASSED",
    "START_4X4_SCAN",
)


class SequenceViolation(RuntimeError):
    pass


class SequenceModel:
    def __init__(self) -> None:
        self.completed: list[str] = []

    def execute(self, action: str) -> None:
        if action not in SEQUENCE:
            raise SequenceViolation(f"UNKNOWN_ACTION:{action}")
        expected = SEQUENCE[len(self.completed)]
        if action != expected:
            raise SequenceViolation(f"EXPECTED_{expected}_BEFORE_{action}")
        self.completed.append(action)

    @property
    def scan_authorized(self) -> bool:
        return bool(self.completed and self.completed[-1] == "START_4X4_SCAN")

