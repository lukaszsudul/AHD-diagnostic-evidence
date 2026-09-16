#!/usr/bin/env python3
"""Post-decision read-only binding/node preservation check."""
import datetime
import json
import os
import pathlib
import stat


def read(path):
    try:
        return pathlib.Path(path).read_text(encoding="ascii", errors="replace").strip()
    except OSError:
        return None


def link(path):
    p = pathlib.Path(path)
    try:
        return str(p.resolve(strict=True)) if p.is_symlink() else None
    except OSError:
        return None


def node(path):
    p = pathlib.Path(path)
    try:
        s = p.stat()
    except OSError:
        return {"path": path, "exists": False}
    if not stat.S_ISCHR(s.st_mode):
        return {"path": path, "exists": True, "is_character": False}
    dev = f"{os.major(s.st_rdev)}:{os.minor(s.st_rdev)}"
    return {"path": path, "exists": True, "is_character": True,
            "major_minor": dev, "sysfs": link("/sys/dev/char/" + dev)}


protected = pathlib.Path("/sys/bus/pci/devices/0000:0b:00.0")
target = pathlib.Path("/sys/bus/pci/devices/0000:01:00.0")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R1_READONLY_PRESERVATION_V1",
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "boot_id": read("/proc/sys/kernel/random/boot_id"),
    "protected": {"bdf": protected.name, "vendor": read(protected / "vendor"),
                  "device": read(protected / "device"),
                  "subsystem_vendor": read(protected / "subsystem_vendor"),
                  "subsystem_device": read(protected / "subsystem_device"),
                  "driver": link(protected / "driver"),
                  "module": link(protected / "driver" / "module"),
                  "user_node": node("/dev/xdma0_user"),
                  "c2h_0_node": node("/dev/xdma0_c2h_0")},
    "target": {"bdf": target.name, "driver": link(target / "driver")},
    "xdma_class_exists": pathlib.Path("/sys/class/xdma").exists(),
    "qualified_ahd_module_loaded": pathlib.Path("/sys/module/xdma_ahd_pcie").exists(),
    "no_device_open": True,
}, sort_keys=True))
