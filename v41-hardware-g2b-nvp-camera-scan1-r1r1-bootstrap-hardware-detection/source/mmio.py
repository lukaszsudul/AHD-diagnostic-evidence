# SANITIZED PUBLICATION COPY; executed-source SHA-256: F229480995DBD688ECFE770AE56ADEDB43B6209504296BA19C02F808D18CF512
"""Exact XDMA user/BAR dword access for SCAN1."""

from __future__ import annotations

import os
import struct
from pathlib import Path


BASE = 0x12000
MAGIC = BASE + 0x00
VERSION = BASE + 0x04
CAPABILITIES = BASE + 0x08
CONTROL = BASE + 0x0C
STATUS = BASE + 0x10
GENERATION = BASE + 0x14
ENTRY_COUNT = BASE + 0x18
VALID_ENTRY_COUNT = BASE + 0x1C
FAILED_ENTRY_COUNT = BASE + 0x20
RETRIED_ENTRY_COUNT = BASE + 0x24
FIRST_ERROR_INDEX = BASE + 0x28
FIRST_ERROR_DETAIL = BASE + 0x2C
ENTRY_BANK = BASE + 0x30
EXIT_BANK = BASE + 0x34
A8_PRE_POST = BASE + 0x38
SCAN_FLAGS = BASE + 0x3C
START_TICKS_LO = BASE + 0x40
START_TICKS_HI = BASE + 0x44
END_TICKS_LO = BASE + 0x48
END_TICKS_HI = BASE + 0x4C
DIGEST_BASE = BASE + 0x50
GROUP_BASE = BASE + 0x80
ENTRY_BASE = BASE + 0x180

CONTROL_ONESHOT = 1
CONTROL_ACK_CLEAR = 2
CONTROL_ABORT = 4

STATUS_IDLE = 1 << 0
STATUS_BUSY = 1 << 1
STATUS_DONE = 1 << 2
STATUS_ERROR = 1 << 3
STATUS_AUTOINIT_DONE = 1 << 4
STATUS_AUTOINIT_BUSY = 1 << 5
STATUS_BANK_LOCKOUT = 1 << 6


class MmioDevice:
    def __init__(self, path: str | Path):
        self.path = str(path)
        self.fd: int | None = None

    def __enter__(self) -> "MmioDevice":
        self.fd = os.open(self.path, os.O_RDWR | getattr(os, "O_SYNC", 0))
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None

    def read32(self, address: int) -> int:
        if self.fd is None or address & 3:
            raise RuntimeError("MMIO_READ_PRECONDITION_FAILED")
        data = os.pread(self.fd, 4, address)
        if len(data) != 4:
            raise RuntimeError(f"MMIO_SHORT_READ:{address:#x}:{len(data)}")
        return struct.unpack("<I", data)[0]

    def write32(self, address: int, value: int) -> None:
        if self.fd is None or address & 3 or value < 0 or value > 0xFFFFFFFF:
            raise RuntimeError("MMIO_WRITE_PRECONDITION_FAILED")
        count = os.pwrite(self.fd, struct.pack("<I", value), address)
        if count != 4:
            raise RuntimeError(f"MMIO_SHORT_WRITE:{address:#x}:{count}")
