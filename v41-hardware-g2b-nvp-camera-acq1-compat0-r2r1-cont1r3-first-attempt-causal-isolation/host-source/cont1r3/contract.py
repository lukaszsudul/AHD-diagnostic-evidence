"""Frozen CONT1R3 telemetry constants and actual execution-group authority."""

from __future__ import annotations

from dataclasses import dataclass


TELEMETRY_BASE = 0x12800
TELEMETRY_LAST = 0x137FF
TELEMETRY_MAGIC = 0x4E565433
TELEMETRY_VERSION = 0x00010000
TELEMETRY_CAPABILITIES = 0x0000007F
EXPECTED_SCHEMA_SHA256 = "438D630943B0D3A2BFCB2C23B9FB060FD0C347C16F331D008997DBB3B8B22F95"
EXPECTED_MANIFEST_SHA256 = "2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B"
COUNTER_FREQUENCY_HZ = 62_500_000
COUNTER_WIDTH_BITS = 64
ENTRY_COUNT = 82
GROUP_COUNT = 10
CLEAN_TRANSACTION_COUNT = 105
MAXIMUM_EVENTS = 82
GROUP_RECORD_BASE = 0x12880
GROUP_RECORD_WORDS = 5
ENTRY_RECORD_BASE = 0x12A00
ENTRY_RECORD_WORDS = 10

HEADER_ADDRESSES = tuple(range(0x12800, 0x12880, 4))
GROUP_ADDRESSES = tuple(
    GROUP_RECORD_BASE + 4 * index
    for index in range(GROUP_COUNT * GROUP_RECORD_WORDS)
)
ENTRY_ADDRESSES = tuple(
    ENTRY_RECORD_BASE + 4 * index
    for index in range(ENTRY_COUNT * ENTRY_RECORD_WORDS)
)


@dataclass(frozen=True)
class ExecutionGroup:
    index: int
    name: str
    bank: int
    start: int
    count: int

    @property
    def previous_bank_valid(self) -> bool:
        return self.index != 0

    @property
    def previous_bank(self) -> int:
        return 0 if self.index == 0 else EXECUTION_GROUPS[self.index - 1].bank

    @property
    def bank_changed(self) -> bool:
        return self.previous_bank_valid and self.bank != self.previous_bank

    @property
    def same_bank_reselection(self) -> bool:
        return self.previous_bank_valid and self.bank == self.previous_bank


EXECUTION_GROUPS = (
    ExecutionGroup(0, "G0-PRE", 0x00, 0, 1),
    ExecutionGroup(1, "G0-ID", 0x00, 1, 3),
    ExecutionGroup(2, "G0-LOCK", 0x00, 4, 7),
    ExecutionGroup(3, "G0-CH", 0x00, 11, 16),
    ExecutionGroup(4, "G1", 0x01, 27, 10),
    ExecutionGroup(5, "G2", 0x05, 37, 11),
    ExecutionGroup(6, "G3", 0x06, 48, 11),
    ExecutionGroup(7, "G4", 0x07, 59, 11),
    ExecutionGroup(8, "G5", 0x08, 70, 11),
    ExecutionGroup(9, "G0-POST", 0x00, 81, 1),
)

RAW_CAUSES = {
    0: "NONE",
    1: "WADDR_NACK",
    2: "REGADDR_NACK",
    3: "RADDR_NACK",
    4: "DATA_NACK",
    5: "SCL_TIMEOUT",
    6: "BUS_IDLE_TIMEOUT",
}

DECODED_CAUSES = {
    0: "NONE",
    1: "WADDR_NACK",
    2: "REGADDR_NACK",
    3: "RADDR_NACK",
    4: "SCL_TIMEOUT",
    5: "BUS_IDLE_TIMEOUT",
    6: "BANK_VERIFY_MISMATCH",
    7: "ENTRY_BANK_READ_FAILURE",
    8: "ENTRY_BANK_RESTORE_FAILURE",
    9: "AUTOINIT_PREEMPTED",
    10: "INTERNAL_PROTOCOL",
}


def ticks_to_ns(delta_ticks: int) -> int:
    if not 0 <= delta_ticks < 1 << COUNTER_WIDTH_BITS:
        raise ValueError("CONT1R3_DELTA_TICKS_OUT_OF_RANGE")
    return delta_ticks * 1_000_000_000 // COUNTER_FREQUENCY_HZ
