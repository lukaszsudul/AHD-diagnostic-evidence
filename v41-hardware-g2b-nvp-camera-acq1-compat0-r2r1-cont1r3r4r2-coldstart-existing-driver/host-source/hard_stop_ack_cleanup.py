#!/usr/bin/env python3
"""One qualified SCAN1 ACK_CLEAR after persisted hard-stop diagnosis."""

from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import stat
import struct
import time

BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
TARGET = "0000:01:00.0"
NODE = "/dev/xdma0_user"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
PCI = Path("/sys/bus/pci/devices") / TARGET


def require(ok: bool, reason: str) -> None:
    if not ok:
        raise RuntimeError(reason)


require(os.geteuid() == 0 and
        Path("/proc/sys/kernel/random/boot_id").read_text().strip() == BOOT,
        "HARD_STOP_ACK_ACCOUNT_OR_BOOT_MISMATCH")
require(LOCK.is_dir() and not LOCK.is_symlink(), "HARD_STOP_ACK_LOCK_MISSING")
receipt = json.loads((LOCK / "receipt.json").read_text())
require(receipt.get("state") == "HELD" and receipt.get("boot_id") == BOOT and
        receipt.get("ahd_bdf") == TARGET, "HARD_STOP_ACK_LOCK_MISMATCH")
require((PCI / "driver").is_symlink() and
        (PCI / "driver").resolve().name == "xdma_ahd_pcie",
        "HARD_STOP_ACK_DRIVER_MISMATCH")
st = os.stat(NODE)
require(stat.S_ISCHR(st.st_mode) and
        (os.major(st.st_rdev), os.minor(st.st_rdev)) == (511, 0) and
        TARGET in (Path("/sys/dev/char") / "511:0").resolve().parts,
        "HARD_STOP_ACK_NODE_MISMATCH")
fd = os.open(NODE, os.O_RDWR | getattr(os, "O_SYNC", 0))
try:
    require(os.fstat(fd).st_rdev == st.st_rdev, "HARD_STOP_ACK_FD_MISMATCH")

    def read32(addr: int) -> int:
        raw = os.pread(fd, 4, addr)
        require(len(raw) == 4, "HARD_STOP_ACK_SHORT_READ")
        return struct.unpack("<I", raw)[0]

    before = {
        "status": read32(0x12010),
        "generation": read32(0x12014),
        "first_error_index": read32(0x12028),
        "first_error_detail": read32(0x1202C),
        "entry_bank": read32(0x12030),
        "exit_bank": read32(0x12034),
        "scan_flags": read32(0x1203C),
        "acq_status": read32(0x12410),
        "acq_functional_writes": read32(0x1242C),
    }
    require(before["status"] == 0x00000C18 and before["generation"] == 26 and
            before["first_error_index"] == 36 and
            before["first_error_detail"] == 0x0005FF0A and
            before["entry_bank"] == before["exit_bank"] == 0x00000100 and
            before["scan_flags"] & 0x4 and not before["status"] & 0x2 and
            before["acq_status"] & 1 and before["acq_functional_writes"] == 0,
            "HARD_STOP_ACK_PRECONDITION_FAILED")
    written = os.pwrite(fd, struct.pack("<I", 2), 0x1200C)
    require(written == 4, "HARD_STOP_ACK_SHORT_WRITE")
    deadline = time.monotonic() + 1.0
    after = None
    while time.monotonic() < deadline:
        after = read32(0x12010)
        if after & 1 and not after & (2 | 4 | 8 | 64):
            break
        time.sleep(0.001)
    require(after is not None and after & 1 and not after & (2 | 4 | 8 | 64),
            "HARD_STOP_ACK_DID_NOT_RETURN_IDLE")
    acq_after = read32(0x12410)
    require(acq_after & 1 and not acq_after & (2 | 4 | 8 | 64 | 128) and
            read32(0x1242C) == 0 and read32(0x12430) == 0,
            "HARD_STOP_ACK_ACQ_NOT_IDLE_OR_FUNCTIONAL_WRITE")
finally:
    os.close(fd)
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_HARD_STOP_ACK_CLEANUP_V1",
    "result": "PASS_IDLE",
    "boot_id": BOOT,
    "bdf": TARGET,
    "selected_node": NODE,
    "before": {key: f"0x{value:08X}" for key, value in before.items()},
    "after_scan_status": f"0x{after:08X}",
    "after_acq_status": f"0x{acq_after:08X}",
    "mmio_writes": 1,
    "only_write": "SCAN1_ACK_CLEAR_0x1200C_0x00000002",
    "no_new_scan": True,
    "completed_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
