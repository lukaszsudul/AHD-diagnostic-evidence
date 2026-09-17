#!/usr/bin/env python3
"""Read-only target quiescence and holder gate before normal module unload."""

from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import re
import stat
import subprocess

BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
TARGET = "0000:01:00.0"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
PCI = Path("/sys/bus/pci/devices") / TARGET
ROLES = {"/dev/xdma0_user": (511, 0), "/dev/xdma0_c2h_0": (511, 36)}


def require(ok: bool, reason: str) -> None:
    if not ok:
        raise RuntimeError(reason)


require(os.geteuid() == 0 and
        Path("/proc/sys/kernel/random/boot_id").read_text().strip() == BOOT,
        "PRE_UNLOAD_ACCOUNT_OR_BOOT_MISMATCH")
require(LOCK.is_dir() and not LOCK.is_symlink(), "PRE_UNLOAD_DUT_LOCK_MISSING")
receipt = json.loads((LOCK / "receipt.json").read_text())
require(receipt.get("state") == "HELD" and receipt.get("boot_id") == BOOT and
        receipt.get("ahd_bdf") == TARGET, "PRE_UNLOAD_DUT_LOCK_MISMATCH")
require((PCI / "driver").is_symlink() and
        (PCI / "driver").resolve().name == "xdma_ahd_pcie" and
        (PCI / "driver/module").resolve().name == "xdma_ahd_pcie" and
        not Path("/sys/module/xdma").exists(), "PRE_UNLOAD_TARGET_DRIVER_MISMATCH")
lines = [line.split() for line in Path("/proc/modules").read_text().splitlines()
         if line.startswith("xdma_ahd_pcie ")]
require(len(lines) == 1 and len(lines[0]) >= 3 and lines[0][2] == "0",
        "PRE_UNLOAD_MODULE_REFCOUNT_NONZERO_OR_ABSENT")
for name, expected in ROLES.items():
    st = os.stat(name)
    require(stat.S_ISCHR(st.st_mode) and
            (os.major(st.st_rdev), os.minor(st.st_rdev)) == expected and
            TARGET in (Path("/sys/dev/char") / f"{expected[0]}:{expected[1]}").resolve().parts,
            "PRE_UNLOAD_NODE_ANCESTRY_MISMATCH")
targets = {os.makedev(*pair) for pair in ROLES.values()}
holders = []
for pid_dir in Path("/proc").iterdir():
    if not re.fullmatch(r"[0-9]+", pid_dir.name):
        continue
    try:
        fd_paths = list((pid_dir / "fd").iterdir())
    except FileNotFoundError:
        continue
    except PermissionError:
        raise SystemExit("PRE_UNLOAD_PROCESS_FD_VISIBILITY_INCOMPLETE")
    for fd in fd_paths:
        try:
            st = fd.stat()
        except FileNotFoundError:
            continue
        except PermissionError:
            raise SystemExit("PRE_UNLOAD_PROCESS_FD_VISIBILITY_INCOMPLETE")
        if stat.S_ISCHR(st.st_mode) and st.st_rdev in targets:
            holders.append({"pid": int(pid_dir.name), "fd": fd.name})
require(not holders, "PRE_UNLOAD_TARGET_NODE_HELD")
jobs = subprocess.run(["systemctl", "list-jobs", "--no-pager", "--no-legend"],
                      capture_output=True, text=True, timeout=10, check=False)
require(jobs.returncode == 0 and not jobs.stdout.strip(), "PRE_UNLOAD_SYSTEMD_JOB_PENDING")
vendor_functions = [p.name for p in Path("/sys/bus/pci/devices").iterdir()
                    if (p / "vendor").is_file() and
                    (p / "vendor").read_text().strip() == "0x10ee"]
require(vendor_functions == [TARGET], "PRE_UNLOAD_OTHER_XILINX_FUNCTION_PRESENT")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_PRE_UNLOAD_TARGET_SAFETY_V1",
    "result": "PASS_EXCLUSIVE_TARGET_QUIESCENT",
    "boot_id": BOOT,
    "bdf": TARGET,
    "driver": "xdma_ahd_pcie",
    "module_refcount": 0,
    "target_node_holders": holders,
    "systemd_jobs": 0,
    "vendor_functions": vendor_functions,
    "no_foreign_device_access": True,
    "verified_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
