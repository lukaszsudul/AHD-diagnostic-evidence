#!/usr/bin/env python3
"""Run one accepted control and 1,000 scans with target-bound opened-FD gate."""

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
RUN = BASE / "g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart" / "20260917T063836Z"
PAYLOAD = RUN / "runtime-bundle" / "payload"
OUTPUT = RUN / "characterization"
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
PCI = Path("/sys/bus/pci/devices") / TARGET


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def verify_target() -> None:
    require(os.geteuid() == 0 and
            Path("/proc/sys/kernel/random/boot_id").read_text().strip() == BOOT,
            "CHARACTERIZATION_ACCOUNT_OR_BOOT_MISMATCH")
    require(LOCK.is_dir() and not LOCK.is_symlink(), "CHARACTERIZATION_LOCK_MISSING")
    receipt = json.loads((LOCK / "receipt.json").read_text())
    require(receipt.get("state") == "HELD" and receipt.get("boot_id") == BOOT and
            receipt.get("ahd_bdf") == TARGET, "CHARACTERIZATION_LOCK_MISMATCH")
    require(PCI.is_dir() and (PCI / "driver").is_symlink() and
            (PCI / "driver").resolve().name == "xdma_ahd_pcie" and
            (PCI / "driver/module").resolve().name == "xdma_ahd_pcie" and
            not Path("/sys/module/xdma").exists(), "CHARACTERIZATION_DRIVER_MISMATCH")
    st = os.stat(NODE)
    require(stat.S_ISCHR(st.st_mode) and
            (os.major(st.st_rdev), os.minor(st.st_rdev)) == RDEV,
            "CHARACTERIZATION_NODE_CHANGED")
    sysfs = (Path("/sys/dev/char") / f"{RDEV[0]}:{RDEV[1]}").resolve()
    require(TARGET in sysfs.parts and sysfs.name == "xdma0_user",
            "CHARACTERIZATION_NODE_ANCESTRY_MISMATCH")


def aer_snapshot() -> dict[str, str | None]:
    return {name: (PCI / name).read_text().strip() if (PCI / name).is_file() else None
            for name in ("aer_dev_correctable", "aer_dev_nonfatal", "aer_dev_fatal")}


verify_target()
require(not OUTPUT.exists(), "CHARACTERIZATION_OUTPUT_ROOT_ALREADY_EXISTS_NO_RESUME")
os.environ["PYTHONNOUSERSITE"] = "1"
sys.dont_write_bytecode = True
sys.path.insert(0, str(PAYLOAD))
mmio = importlib.import_module("scan1.mmio")
characterizer = importlib.import_module("cont1r3.characterizer")
require(Path(mmio.__file__).resolve() == (PAYLOAD / "scan1/mmio.py").resolve() and
        Path(characterizer.__file__).resolve() ==
        (PAYLOAD / "cont1r3/characterizer.py").resolve(),
        "CHARACTERIZATION_MODULE_ORIGIN_MISMATCH")
require(characterizer.CAMPAIGN_SCAN_COUNT == 1000 and
        characterizer.CHECKPOINT_INTERVAL == 100,
        "CHARACTERIZATION_FROZEN_COUNT_MISMATCH")
original_enter = mmio.MmioDevice.__enter__
verified_fd_opens = 0


def guarded_enter(self):
    global verified_fd_opens
    require(self.path == NODE, "CHARACTERIZATION_UNSELECTED_NODE")
    verify_target()
    entered = original_enter(self)
    try:
        st = os.fstat(self.fd)
        require(stat.S_ISCHR(st.st_mode) and
                (os.major(st.st_rdev), os.minor(st.st_rdev)) == RDEV,
                "CHARACTERIZATION_OPEN_FD_CHANGED")
        verified_fd_opens += 1
        return entered
    except Exception:
        self.__exit__(None, None, None)
        raise


mmio.MmioDevice.__enter__ = guarded_enter
aer_before = aer_snapshot()
result = characterizer.run_live(NODE, OUTPUT)
verify_target()
aer_after = aer_snapshot()
require(aer_after == aer_before, "CHARACTERIZATION_AER_COUNTER_CHANGED")
require(result.get("campaign_complete_scans") == 1000 and
        result.get("all_recorded_scans_including_control") == 1001 and
        result.get("hard_stop_events") == 0 and verified_fd_opens == 1,
        "CHARACTERIZATION_ACCEPTED_RESULT_MISMATCH")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_GUARDED_CHARACTERIZATION_V1",
    "result": "PASS",
    "boot_id": BOOT,
    "bdf": TARGET,
    "selected_user_node": NODE,
    "selected_user_dev_t": f"{RDEV[0]}:{RDEV[1]}",
    "verified_fd_opens_before_mmio": verified_fd_opens,
    "aer_before": aer_before,
    "aer_after": aer_after,
    "accepted_result": result,
    "completed_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
