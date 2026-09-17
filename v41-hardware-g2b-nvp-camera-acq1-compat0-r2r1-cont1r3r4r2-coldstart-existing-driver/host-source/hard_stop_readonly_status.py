#!/usr/bin/env python3
"""Bounded read-only MMIO receipt after first campaign hard stop."""

from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import stat
import struct

BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
TARGET = "0000:01:00.0"
NODE = "/dev/xdma0_user"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
PCI = Path("/sys/bus/pci/devices") / TARGET
REGISTERS = {
    "scan_magic": 0x12000,
    "scan_version": 0x12004,
    "scan_capabilities": 0x12008,
    "scan_status": 0x12010,
    "scan_generation": 0x12014,
    "scan_entry_count": 0x12018,
    "scan_valid_entries": 0x1201C,
    "scan_failed_entries": 0x12020,
    "scan_retried_entries": 0x12024,
    "scan_first_error_index": 0x12028,
    "scan_first_error_detail": 0x1202C,
    "scan_entry_bank": 0x12030,
    "scan_exit_bank": 0x12034,
    "scan_a8_pre_post": 0x12038,
    "scan_flags": 0x1203C,
    "telemetry_magic": 0x12800,
    "telemetry_version": 0x12804,
    "telemetry_capabilities": 0x12808,
    "telemetry_status": 0x1280C,
    "telemetry_generation": 0x12810,
    "acq_magic": 0x12400,
    "acq_version": 0x12404,
    "acq_capabilities": 0x12408,
    "acq_status": 0x12410,
    "acq_functional_write_count": 0x1242C,
    "acq_unauthorized_write_count": 0x12430,
    "acq_error_counts": 0x12434,
}

if os.geteuid() != 0 or Path("/proc/sys/kernel/random/boot_id").read_text().strip() != BOOT:
    raise SystemExit("HARD_STOP_READONLY_ACCOUNT_OR_BOOT_MISMATCH")
if not LOCK.is_dir() or LOCK.is_symlink():
    raise SystemExit("HARD_STOP_READONLY_LOCK_MISSING")
receipt = json.loads((LOCK / "receipt.json").read_text())
if receipt.get("state") != "HELD" or receipt.get("boot_id") != BOOT or \
        receipt.get("ahd_bdf") != TARGET:
    raise SystemExit("HARD_STOP_READONLY_LOCK_MISMATCH")
if not (PCI / "driver").is_symlink() or (PCI / "driver").resolve().name != "xdma_ahd_pcie":
    raise SystemExit("HARD_STOP_READONLY_DRIVER_MISMATCH")
st = os.stat(NODE)
if not stat.S_ISCHR(st.st_mode) or \
        (os.major(st.st_rdev), os.minor(st.st_rdev)) != (511, 0) or \
        TARGET not in (Path("/sys/dev/char") / "511:0").resolve().parts:
    raise SystemExit("HARD_STOP_READONLY_NODE_MISMATCH")
fd = os.open(NODE, os.O_RDWR | getattr(os, "O_SYNC", 0))
try:
    opened = os.fstat(fd)
    if opened.st_rdev != st.st_rdev or not stat.S_ISCHR(opened.st_mode):
        raise SystemExit("HARD_STOP_READONLY_OPEN_FD_MISMATCH")
    values = {}
    for name, address in REGISTERS.items():
        data = os.pread(fd, 4, address)
        if len(data) != 4:
            raise SystemExit("HARD_STOP_READONLY_SHORT_MMIO_READ")
        values[name] = f"0x{struct.unpack('<I', data)[0]:08X}"
finally:
    os.close(fd)
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_HARD_STOP_READONLY_STATUS_V1",
    "result": "CAPTURED_NO_WRITE",
    "boot_id": BOOT,
    "bdf": TARGET,
    "node": NODE,
    "opened_fd_verified": True,
    "mmio_writes": 0,
    "values": values,
    "captured_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
