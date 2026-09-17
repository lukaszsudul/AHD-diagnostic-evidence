#!/usr/bin/env python3
"""Read-only BDF-bound mapping of dynamically named XDMA device roles."""

from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import re
import stat

BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
TARGET = "0000:01:00.0"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
PCI = Path("/sys/bus/pci/devices") / TARGET

if os.geteuid() != 1000 or Path("/proc/sys/kernel/random/boot_id").read_text().strip() != BOOT:
    raise SystemExit("TARGET_NODE_MAPPING_ACCOUNT_OR_BOOT_MISMATCH")
if not LOCK.is_dir() or LOCK.is_symlink():
    raise SystemExit("TARGET_NODE_MAPPING_LOCK_MISSING")
lock = json.loads((LOCK / "receipt.json").read_text())
if lock.get("state") != "HELD" or lock.get("boot_id") != BOOT or lock.get("ahd_bdf") != TARGET:
    raise SystemExit("TARGET_NODE_MAPPING_LOCK_IDENTITY_MISMATCH")
if not PCI.is_dir() or (PCI / "vendor").read_text().strip() != "0x10ee" or \
        (PCI / "device").read_text().strip() != "0x7011" or \
        (PCI / "subsystem_vendor").read_text().strip() != "0x10ee" or \
        (PCI / "subsystem_device").read_text().strip() != "0x0007":
    raise SystemExit("TARGET_NODE_MAPPING_PCI_IDENTITY_MISMATCH")
driver = PCI / "driver"
module = driver / "module"
if not driver.is_symlink() or driver.resolve().name != "xdma_ahd_pcie" or \
        not module.is_symlink() or module.resolve().name != "xdma_ahd_pcie" or \
        not Path("/sys/module/xdma_ahd_pcie").is_dir() or Path("/sys/module/xdma").exists():
    raise SystemExit("TARGET_NODE_MAPPING_DRIVER_IDENTITY_MISMATCH")
if (PCI / "current_link_speed").read_text().strip() != "5.0 GT/s PCIe" or \
        (PCI / "current_link_width").read_text().strip() != "1":
    raise SystemExit("TARGET_NODE_MAPPING_PCIE_LINK_MISMATCH")
nodes = {}
for path in sorted(Path("/dev").glob("xdma*")):
    name = path.name
    match = re.fullmatch(r"xdma([0-9]+)_(user|c2h_0)", name)
    if match is None:
        continue
    st = path.stat()
    if not stat.S_ISCHR(st.st_mode):
        raise SystemExit("TARGET_NODE_MAPPING_NON_CHAR_NODE")
    major, minor = os.major(st.st_rdev), os.minor(st.st_rdev)
    char_path = Path("/sys/dev/char") / f"{major}:{minor}"
    if not char_path.is_symlink():
        raise SystemExit("TARGET_NODE_MAPPING_SYSFS_CHAR_LINK_MISSING")
    resolved = char_path.resolve()
    if TARGET not in resolved.parts:
        raise SystemExit("TARGET_NODE_MAPPING_NODE_ANCESTRY_MISMATCH")
    nodes.setdefault(match.group(1), {})[match.group(2)] = {
        "path": str(path),
        "major": major,
        "minor": minor,
        "rdev": st.st_rdev,
        "sysfs": str(resolved),
    }
eligible = {n: roles for n, roles in nodes.items() if set(roles) == {"user", "c2h_0"}}
if len(eligible) != 1:
    raise SystemExit("TARGET_NODE_MAPPING_NO_UNIQUE_ROLE_PAIR")
n, roles = next(iter(eligible.items()))
if any(n2 != n for n2 in nodes):
    raise SystemExit("TARGET_NODE_MAPPING_SECOND_XDMA_INDEX")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_TARGET_NODE_MAPPING_V1",
    "result": "PASS",
    "boot_id": BOOT,
    "bdf": TARGET,
    "vendor_device": "10ee:7011",
    "subsystem": "10ee:0007",
    "pcie": "Gen2 x1",
    "driver": "xdma_ahd_pcie",
    "module": "xdma_ahd_pcie",
    "dynamic_index": int(n),
    "user": roles["user"],
    "c2h_0": roles["c2h_0"],
    "node_opened": False,
    "foreign_node_access": False,
    "verified_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
