#!/usr/bin/env python3
"""Pure host-side model of the governed R2R2R1 activation sequence."""

from __future__ import annotations

SEQUENCE = (
    "OFFLINE_SIGNOFF_INHERITED",
    "EXACT_BITSTREAM_VERIFIED",
    "CONTROLLER_LOCK_ACQUIRED",
    "FPGA_SRAM_PROGRAMMED",
    "PRODUCT_EQUIVALENT_AUTOINIT_ALLOWED",
    "WARM_REBOOT_COMPLETED",
    "LINUX_LOCK_ACQUIRED",
    "EXACT_DRIVER_LOADED",
    "RUNTIME_IDENTITY_PASSED",
    "DIAG_CLEAR_PASSED",
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
            raise SequenceViolation(
                f"EXPECTED_{expected}_BEFORE_{action}")
        self.completed.append(action)

    @property
    def scan_authorized(self) -> bool:
        return bool(self.completed and self.completed[-1] == "START_4X4_SCAN")


def nominal_trace() -> list[str]:
    model = SequenceModel()
    for action in SEQUENCE:
        model.execute(action)
    if not model.scan_authorized:
        raise SequenceViolation("NOMINAL_TRACE_DID_NOT_AUTHORIZE_SCAN")
    return model.completed

