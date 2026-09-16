#!/usr/bin/env python3
"""Bounded read-only PCI/driver survey; no device node is opened."""
import json
import pathlib
import subprocess
import os


def value(path):
    try:
        return pathlib.Path(path).read_text(encoding="ascii").strip()
    except (OSError, UnicodeError):
        return None


def safe_run(argv):
    try:
        result = subprocess.run(argv, capture_output=True, text=True, timeout=5, check=False)
        return {"rc": result.returncode, "stdout": result.stdout[:8192],
                "stderr": result.stderr[:2048]}
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"error": type(exc).__name__}


pci = []
for item in sorted(pathlib.Path("/sys/bus/pci/devices").glob("*")):
    vendor, device = value(item / "vendor"), value(item / "device")
    if vendor != "0x10ee" or device != "0x7011":
        continue
    driver = item / "driver"
    pci.append({
        "bdf": item.name, "vendor": vendor, "device": device,
        "subsystem_vendor": value(item / "subsystem_vendor"),
        "subsystem_device": value(item / "subsystem_device"),
        "current_link_speed": value(item / "current_link_speed"),
        "current_link_width": value(item / "current_link_width"),
        "driver": driver.resolve().name if driver.is_symlink() else None,
        "aer_dev_correctable": value(item / "aer_dev_correctable"),
        "aer_dev_nonfatal": value(item / "aer_dev_nonfatal"),
        "aer_dev_fatal": value(item / "aer_dev_fatal"),
    })

print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4_READONLY_PCI_SURVEY_V1",
    "read_only": True,
    "pci": pci,
    "xdma_modules": [line.split()[0] for line in
                     (value("/proc/modules") or "").splitlines()
                     if "xdma" in line.lower()],
    "xdma_module_line": [line for line in
                         (value("/proc/modules") or "").splitlines()
                         if line.startswith("xdma ")],
    "xdma_modinfo": {field: safe_run(["modinfo", "-F", field, "xdma"])
                     for field in ("filename", "name", "alias", "vermagic", "srcversion")},
    "xdma_class": [str(path) for path in sorted(pathlib.Path("/sys/class/xdma").glob("*"))],
    "xdma_driver_bound": [path.name for path in sorted(
        pathlib.Path("/sys/bus/pci/drivers/xdma").glob("0000:*"))],
    "node_sysfs": {name: os.path.realpath("/sys/dev/char/" +
                                         str(os.major(os.stat(name).st_rdev)) + ":" +
                                         str(os.minor(os.stat(name).st_rdev)))
                   for name in ("/dev/xdma0_user", "/dev/xdma0_c2h_0")
                   if pathlib.Path(name).exists()},
    "nodes": {name: safe_run(["stat", "-Lc", "%F %t:%T %u:%g", name])
              for name in ("/dev/xdma0_user", "/dev/xdma0_c2h_0")},
}, sort_keys=True))
