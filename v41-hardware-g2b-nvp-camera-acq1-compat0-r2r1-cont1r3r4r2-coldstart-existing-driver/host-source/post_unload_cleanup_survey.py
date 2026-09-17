#!/usr/bin/env python3
"""Read-only final AHD cleanup survey before releasing the task-owned DUT lock."""

from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import subprocess

BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
TARGET = "0000:01:00.0"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
RUN = BASE / "g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart" / "20260917T063836Z"
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
ARCHIVE = RUN / "private" / "characterization-hardstop.tar.gz"
PCI = Path("/sys/bus/pci/devices") / TARGET


def require(ok: bool, reason: str) -> None:
    if not ok:
        raise RuntimeError(reason)


require(os.geteuid() == 1000 and
        Path("/proc/sys/kernel/random/boot_id").read_text().strip() == BOOT and
        Path("/etc/hostname").read_text().strip() == "VCDE-DUT-1" and
        Path("/etc/machine-id").read_text().strip() ==
        "0e90f50d9465492b80258da5658446f8", "FINAL_CLEANUP_DUT_IDENTITY_MISMATCH")
require(LOCK.is_dir() and not LOCK.is_symlink(), "FINAL_CLEANUP_DUT_LOCK_MISSING")
receipt = json.loads((LOCK / "receipt.json").read_text())
require(receipt.get("state") == "HELD" and receipt.get("boot_id") == BOOT and
        receipt.get("ahd_bdf") == TARGET, "FINAL_CLEANUP_DUT_LOCK_MISMATCH")
require(PCI.is_dir() and (PCI / "vendor").read_text().strip() == "0x10ee" and
        (PCI / "device").read_text().strip() == "0x7011" and
        (PCI / "subsystem_device").read_text().strip() == "0x0007" and
        not (PCI / "driver").exists(), "FINAL_CLEANUP_TARGET_BINDING_MISMATCH")
require(not Path("/sys/module/xdma_ahd_pcie").exists() and
        not Path("/sys/module/xdma").exists() and
        not Path("/sys/class/xdma").exists() and
        not list(Path("/dev").glob("xdma*")), "FINAL_CLEANUP_XDMA_NAMESPACE_NOT_FREE")
vendor_functions = [p.name for p in Path("/sys/bus/pci/devices").iterdir()
                    if (p / "vendor").is_file() and
                    (p / "vendor").read_text().strip() == "0x10ee"]
require(vendor_functions == [TARGET], "FINAL_CLEANUP_PROTECTED_FUNCTION_STATE_CHANGED")
jobs = subprocess.run(["systemctl", "list-jobs", "--no-pager", "--no-legend"],
                      capture_output=True, text=True, timeout=10, check=False)
require(jobs.returncode == 0 and not jobs.stdout.strip(), "FINAL_CLEANUP_JOBS_PENDING")
require(ARCHIVE.is_file() and ARCHIVE.stat().st_size == 108145,
        "FINAL_CLEANUP_PRIVATE_ARCHIVE_SIZE_MISMATCH")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_POST_UNLOAD_CLEANUP_SURVEY_V1",
    "result": "PASS_TARGET_UNBOUND_NAMESPACE_FREE",
    "boot_id": BOOT,
    "ahd_bdf": TARGET,
    "xdma_ahd_pcie_loaded": False,
    "target_nodes_present": False,
    "protected_function_present": False,
    "vendor_functions": vendor_functions,
    "systemd_jobs": 0,
    "private_archive_size": 108145,
    "private_archive_sha256_previously_verified": "96080348A26E00ECF8B4DBA58F6E691EBAD48F2D8B0C3DDC2EC474A316E6A0CB",
    "no_device_open_or_write": True,
    "verified_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
