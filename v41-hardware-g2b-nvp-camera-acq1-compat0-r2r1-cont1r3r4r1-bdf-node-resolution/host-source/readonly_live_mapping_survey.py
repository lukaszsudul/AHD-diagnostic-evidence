#!/usr/bin/env python3
"""CONT1R3R4R1: bounded metadata-only survey. Never open /dev/xdma nodes."""
import datetime
import json
import os
import pathlib
import re
import stat
import subprocess


def read(path, limit=8192):
    try:
        return pathlib.Path(path).read_text(encoding="utf-8", errors="replace")[:limit].strip()
    except OSError:
        return None


def link(path):
    p = pathlib.Path(path)
    try:
        return str(p.resolve(strict=True)) if p.is_symlink() else None
    except OSError:
        return None


def run(argv):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=7, check=False)
        return {"rc": p.returncode, "stdout": p.stdout[:8192], "stderr": p.stderr[:1024]}
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"error": type(exc).__name__}


def names(path):
    try:
        return sorted(x.name for x in pathlib.Path(path).iterdir())
    except OSError:
        return []


def pci_ancestor(path):
    for component in pathlib.Path(path).parts[::-1]:
        if re.fullmatch(r"[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-7]", component):
            return component
    return None


def pci_record(item):
    fields = ("vendor", "device", "subsystem_vendor", "subsystem_device", "class",
              "current_link_speed", "current_link_width", "physical_slot", "driver_override",
              "modalias")
    d = {field: read(item / field) for field in fields}
    driver = link(item / "driver")
    module = link(item / "driver" / "module")
    d.update({"bdf": item.name, "sysfs_path": str(item.resolve()),
              "parent_path": str(item.resolve().parent),
              "iommu_group": link(item / "iommu_group"),
              "driver_path": driver, "driver": pathlib.Path(driver).name if driver else None,
              "driver_module_path": module,
              "driver_module": pathlib.Path(module).name if module else None})
    return d


def node_record(item):
    d = {"path": str(item), "symlink": item.is_symlink(), "link_target": link(item)}
    try:
        st = item.stat()
    except OSError as exc:
        d["stat_error"] = type(exc).__name__
        return d
    d.update({"is_character": stat.S_ISCHR(st.st_mode), "mode_octal": oct(st.st_mode & 0o777),
              "uid": st.st_uid, "gid": st.st_gid})
    if not stat.S_ISCHR(st.st_mode):
        return d
    major, minor = os.major(st.st_rdev), os.minor(st.st_rdev)
    sysfs = pathlib.Path(f"/sys/dev/char/{major}:{minor}")
    resolved = link(sysfs)
    d.update({"major": major, "minor": minor, "sysfs_dev_char": str(sysfs),
              "sysfs_resolved": resolved, "nearest_pci_function": pci_ancestor(resolved) if resolved else None,
              "class_path": link(sysfs / "subsystem"),
              "device_driver": link(sysfs / "device" / "driver"),
              "device_driver_module": link(sysfs / "device" / "driver" / "module")})
    return d


def module_record(name):
    base = pathlib.Path("/sys/module") / name
    if not base.exists():
        return {"name": name, "loaded_sysfs": False}
    notes = base / "notes"
    note_hashes = {}
    for item in notes.iterdir() if notes.is_dir() else []:
        if item.is_file() and item.stat().st_size <= 4096:
            import hashlib
            note_hashes[item.name] = hashlib.sha256(item.read_bytes()).hexdigest()
    return {"name": name, "loaded_sysfs": True,
            "version": read(base / "version"), "srcversion": read(base / "srcversion"),
            "taint": read(base / "taint"), "refcnt": read(base / "refcnt"),
            "holders": names(base / "holders"), "parameters": names(base / "parameters"),
            "note_sha256": note_hashes}


def relevant_processes():
    result = []
    pat = re.compile(r"xdma|vivado|hw_server|vcde|g2b|nvp|jtag", re.I)
    for item in pathlib.Path("/proc").iterdir():
        if not item.name.isdigit():
            continue
        comm = read(item / "comm", 256)
        if comm and pat.search(comm):
            try:
                uid = item.stat().st_uid
            except OSError:
                continue
            result.append({"pid": int(item.name), "uid": uid, "comm": comm})
    return sorted(result, key=lambda x: x["pid"])[:256]


def node_holders(nodes):
    targets = {n["path"] for n in nodes if n.get("is_character")}
    holders = []
    for item in pathlib.Path("/proc").iterdir():
        if not item.name.isdigit():
            continue
        fd_dir = item / "fd"
        try:
            fds = list(fd_dir.iterdir())
        except OSError:
            continue
        for fd in fds:
            try:
                target = os.readlink(fd)
            except OSError:
                continue
            if target in targets:
                holders.append({"pid": int(item.name), "uid": item.stat().st_uid,
                                "comm": read(item / "comm", 256), "node": target})
    return holders[:256]


all_pci = []
for item in sorted(pathlib.Path("/sys/bus/pci/devices").glob("*")):
    if read(item / "vendor") == "0x10ee" or item.name in ("0000:01:00.0", "0000:0b:00.0"):
        all_pci.append(pci_record(item))

nodes = [node_record(x) for x in sorted(pathlib.Path("/dev").glob("xdma*"))]
loaded = [line.split()[0] for line in (read("/proc/modules", 65536) or "").splitlines()
          if "xdma" in line.lower()]
class_path = pathlib.Path("/sys/class/xdma")
classes = {"exists": class_path.exists(), "path": str(class_path),
           "realpath": str(class_path.resolve()) if class_path.exists() else None,
           "members": names(class_path)}
home = pathlib.Path.home()
project_parent = home / "vcde_artifacts"
locks = []
if project_parent.is_dir():
    for item in project_parent.iterdir():
        if "lock" in item.name.lower() and ("g2b" in item.name.lower() or "ahd" in item.name.lower()):
            locks.append({"path": str(item), "type": "directory" if item.is_dir() else "file",
                          "uid": item.stat().st_uid})

print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R1_READONLY_LIVE_MAPPING_SURVEY_V1",
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "no_device_open": True,
    "identity": {"hostname": run(["hostname"]), "user": run(["id", "-un"]),
                 "machine_id": read("/etc/machine-id"),
                 "boot_id": read("/proc/sys/kernel/random/boot_id"),
                 "kernel": run(["uname", "-r"]), "time_utc": run(["date", "-u", "+%FT%TZ"])},
    "pci": all_pci,
    "xdma_nodes": nodes,
    "xdma_class": classes,
    "loaded_xdma_modules": [module_record(name) for name in loaded],
    "proc_modules_lines": [line for line in (read("/proc/modules", 65536) or "").splitlines()
                           if "xdma" in line.lower()],
    "installed_xdma_modinfo_name_lookup": {field: run(["modinfo", "-F", field, "xdma"])
                                            for field in ("filename", "name", "alias", "vermagic", "srcversion")},
    "relevant_processes": relevant_processes(),
    "node_holders": node_holders(nodes),
    "project_lock_candidates": locks,
}, sort_keys=True))
