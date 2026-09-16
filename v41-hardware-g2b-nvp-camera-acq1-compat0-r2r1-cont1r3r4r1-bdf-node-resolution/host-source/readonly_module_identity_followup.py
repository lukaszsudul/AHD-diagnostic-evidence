#!/usr/bin/env python3
"""Read-only exact-file and live-module metadata follow-up; no device I/O."""
import datetime
import hashlib
import json
import pathlib
import subprocess


def run(argv):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=10, check=False)
        return {"rc": p.returncode, "stdout": p.stdout[:10000], "stderr": p.stderr[:1200]}
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"error": type(exc).__name__}


def file_identity(path):
    p = pathlib.Path(path)
    if not p.is_file():
        return {"path": path, "exists": False}
    h = hashlib.sha256()
    with p.open("rb") as stream:
        while block := stream.read(1024 * 1024):
            h.update(block)
    return {"path": path, "exists": True, "size": p.stat().st_size,
            "sha256": h.hexdigest(),
            "modinfo": {field: run(["modinfo", "-F", field, path])
                        for field in ("name", "srcversion", "vermagic", "alias")}}


sealed = "/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko"
installed = "/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst"
print(json.dumps({"schema": "AHD_V41_CONT1R3R4R1_READONLY_MODULE_FOLLOWUP_V1",
                  "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  "qualified_candidate": file_identity(sealed),
                  "installed_xdma_disk_file": file_identity(installed),
                  "current_boot_xdma_kernel_log": run(["journalctl", "-k", "-b", "--no-pager",
                                                       "--output=short-iso", "--grep=xdma"]),
                  "no_device_open": True}, sort_keys=True))
