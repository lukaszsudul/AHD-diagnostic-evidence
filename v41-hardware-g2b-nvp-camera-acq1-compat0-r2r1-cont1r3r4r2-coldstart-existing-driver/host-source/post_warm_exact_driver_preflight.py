#!/usr/bin/env python3
"""Read-only exact existing-driver identity and target-only admission."""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess


BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
BASE = Path("/home/vcdeagent1/vcde_artifacts")
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
MODULE = Path("/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_A/source/XDMA/linux-kernel/xdma/xdma_ahd_pcie.ko")
SHA = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"
ALIAS = "pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*"


def run(*args: str) -> str:
    proc = subprocess.run(args, capture_output=True, text=True, timeout=10, check=False)
    if proc.returncode != 0:
        raise SystemExit("EXACT_DRIVER_PREFLIGHT_COMMAND_FAILED:" + args[0])
    return proc.stdout.strip()


if os.geteuid() != 1000 or Path("/proc/sys/kernel/random/boot_id").read_text().strip() != BOOT:
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_ACCOUNT_OR_BOOT_MISMATCH")
if not LOCK.is_dir() or LOCK.is_symlink():
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_DUT_LOCK_MISSING")
lock = json.loads((LOCK / "receipt.json").read_text())
if lock.get("state") != "HELD" or lock.get("boot_id") != BOOT or \
        lock.get("ahd_bdf") != "0000:01:00.0":
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_LOCK_IDENTITY_MISMATCH")
if Path("/sys/class/xdma").exists() or Path("/sys/module/xdma").exists() or \
        Path("/sys/module/xdma_ahd_pcie").exists() or list(Path("/dev").glob("xdma*")):
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_NAMESPACE_OCCUPIED")
if not MODULE.is_file() or MODULE.is_symlink():
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_MODULE_PATH_INVALID")
raw = MODULE.read_bytes()
if len(raw) != 3296104 or hashlib.sha256(raw).hexdigest().upper() != SHA:
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_MODULE_BYTES_MISMATCH")
kernel = platform.release()
arch = platform.machine()
if kernel != "7.0.0-29-generic" or arch != "x86_64":
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_KERNEL_ARCH_MISMATCH")
modinfo = {field: run("modinfo", "-F", field, str(MODULE))
           for field in ("name", "version", "srcversion", "vermagic", "alias", "depends", "signer")}
if modinfo["name"] != "xdma_ahd_pcie" or modinfo["version"] != "2025.2.0" or \
        modinfo["srcversion"] != "EE8B149D1883AE8C6B1EE31" or \
        modinfo["vermagic"] != "7.0.0-29-generic SMP preempt mod_unload modversions" or \
        modinfo["alias"] != ALIAS or modinfo["depends"] != "":
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_MODINFO_MISMATCH")
signature_enforce_path = Path("/proc/sys/kernel/module_sig_enforce")
signature_enforce = signature_enforce_path.read_text().strip() if signature_enforce_path.is_file() else None
lockdown_path = Path("/sys/kernel/security/lockdown")
lockdown = lockdown_path.read_text().strip() if lockdown_path.is_file() else None
if signature_enforce == "1" and not modinfo["signer"]:
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_UNSIGNED_MODULE_SIGNATURE_ENFORCED")
if lockdown and ("[integrity]" in lockdown or "[confidentiality]" in lockdown) and not modinfo["signer"]:
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_UNSIGNED_MODULE_LOCKDOWN")
devices = []
for path in Path("/sys/bus/pci/devices").iterdir():
    vendor = path / "vendor"
    if vendor.is_file() and vendor.read_text().strip() == "0x10ee":
        devices.append(path)
if len(devices) != 1 or devices[0].name != "0000:01:00.0":
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_NOT_SINGLE_TARGET")
ahd = devices[0]
if ((ahd / "device").read_text().strip() != "0x7011" or
        (ahd / "subsystem_vendor").read_text().strip() != "0x10ee" or
        (ahd / "subsystem_device").read_text().strip() != "0x0007" or
        (ahd / "modalias").read_text().strip() !=
        "pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00" or
        (ahd / "driver").exists()):
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_TARGET_IDENTITY_MISMATCH")
jobs = run("systemctl", "list-jobs", "--no-pager", "--no-legend")
if jobs:
    raise SystemExit("EXACT_DRIVER_PREFLIGHT_SYSTEMD_JOB_PENDING")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_EXACT_DRIVER_PREFLIGHT_V1",
    "result": "PASS",
    "timestamp_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    "boot_id": BOOT,
    "module_path": str(MODULE),
    "module_size": len(raw),
    "module_sha256": SHA,
    "module_name": modinfo["name"],
    "module_version": modinfo["version"],
    "module_srcversion": modinfo["srcversion"],
    "module_vermagic": modinfo["vermagic"],
    "module_alias": modinfo["alias"],
    "module_signer": modinfo["signer"],
    "signature_enforce": signature_enforce,
    "lockdown": lockdown,
    "kernel": kernel,
    "architecture": arch,
    "eligible_pci_functions": [ahd.name],
    "non_target_alias_matches": 0,
    "namespace_free": True,
    "no_device_open_or_write": True,
}, sort_keys=True, separators=(",", ":")))
