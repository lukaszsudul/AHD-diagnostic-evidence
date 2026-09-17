#!/usr/bin/env python3
"""Run the accepted inert runtime preflight behind final-boot FD ancestry checks."""

from __future__ import annotations

import datetime as dt
import importlib
import json
import os
from pathlib import Path
import stat
import sys

BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
TARGET = "0000:01:00.0"
NODE = "/dev/xdma0_user"
RDEV = (511, 0)
BASE = Path("/home/vcdeagent1/vcde_artifacts")
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
PAYLOAD = BASE / "g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart" / "20260917T063836Z" / "runtime-bundle" / "payload"
PCI = Path("/sys/bus/pci/devices") / TARGET


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def verify_live_target() -> None:
    require(os.geteuid() == 0 and
            Path("/proc/sys/kernel/random/boot_id").read_text().strip() == BOOT,
            "RUNTIME_PREFLIGHT_ACCOUNT_OR_BOOT_MISMATCH")
    require(LOCK.is_dir() and not LOCK.is_symlink(), "RUNTIME_PREFLIGHT_LOCK_MISSING")
    receipt = json.loads((LOCK / "receipt.json").read_text())
    require(receipt.get("state") == "HELD" and receipt.get("boot_id") == BOOT and
            receipt.get("ahd_bdf") == TARGET, "RUNTIME_PREFLIGHT_LOCK_MISMATCH")
    require(PCI.is_dir() and (PCI / "driver").is_symlink() and
            (PCI / "driver").resolve().name == "xdma_ahd_pcie" and
            (PCI / "driver/module").resolve().name == "xdma_ahd_pcie" and
            not Path("/sys/module/xdma").exists(), "RUNTIME_PREFLIGHT_DRIVER_MISMATCH")
    st = os.stat(NODE)
    require(stat.S_ISCHR(st.st_mode) and
            (os.major(st.st_rdev), os.minor(st.st_rdev)) == RDEV,
            "RUNTIME_PREFLIGHT_NODE_CHANGED")
    sysfs = (Path("/sys/dev/char") / f"{RDEV[0]}:{RDEV[1]}").resolve()
    require(TARGET in sysfs.parts and sysfs.name == "xdma0_user",
            "RUNTIME_PREFLIGHT_NODE_ANCESTRY_MISMATCH")


verify_live_target()
os.environ["PYTHONNOUSERSITE"] = "1"
sys.dont_write_bytecode = True
sys.path.insert(0, str(PAYLOAD))
mmio = importlib.import_module("scan1.mmio")
preflight = importlib.import_module("cont1r3.runtime_preflight")
require(Path(mmio.__file__).resolve() == (PAYLOAD / "scan1/mmio.py").resolve() and
        Path(preflight.__file__).resolve() ==
        (PAYLOAD / "cont1r3/runtime_preflight.py").resolve(),
        "RUNTIME_PREFLIGHT_MODULE_ORIGIN_MISMATCH")
original_enter = mmio.MmioDevice.__enter__
verified_fd_opens = 0


def guarded_enter(self):
    global verified_fd_opens
    require(self.path == NODE, "RUNTIME_PREFLIGHT_UNSELECTED_NODE")
    verify_live_target()
    entered = original_enter(self)
    try:
        st = os.fstat(self.fd)
        require(stat.S_ISCHR(st.st_mode) and
                (os.major(st.st_rdev), os.minor(st.st_rdev)) == RDEV,
                "RUNTIME_PREFLIGHT_OPEN_FD_CHANGED")
        verified_fd_opens += 1
        return entered
    except Exception:
        self.__exit__(None, None, None)
        raise


mmio.MmioDevice.__enter__ = guarded_enter
result = preflight.run(NODE)
require(result.get("result") == "PASS" and verified_fd_opens == 1,
        "RUNTIME_PREFLIGHT_ACCEPTED_RESULT_MISMATCH")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_GUARDED_RUNTIME_PREFLIGHT_V1",
    "result": "PASS",
    "boot_id": BOOT,
    "bdf": TARGET,
    "selected_user_node": NODE,
    "selected_user_dev_t": f"{RDEV[0]}:{RDEV[1]}",
    "verified_fd_opens_before_mmio": verified_fd_opens,
    "accepted_result": result,
    "completed_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
