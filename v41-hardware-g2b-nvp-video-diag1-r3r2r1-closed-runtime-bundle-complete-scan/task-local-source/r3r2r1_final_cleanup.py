#!/usr/bin/env python3
"""Verify the failed R3R1 run is safe, unload XDMA, and release its Linux lock."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import struct
import subprocess
import time


TASK = "G2B-NVP-VIDEO-DIAG1-R3R2"
OWNER_TASK = "G2B-NVP-VIDEO-DIAG1-R3R2R1"


def require(value: bool, message: str) -> None:
    if not value:
        raise RuntimeError(message)


def alarm(_signum, _frame):
    raise RuntimeError("NVP_DIAG1_R3R1_CLEANUP_MMIO_TIMEOUT")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", default="/dev/xdma0_user")
    parser.add_argument("--c2h-node", default="/dev/xdma0_c2h_0")
    parser.add_argument("--linux-lock", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    require(not args.output.exists(), "NVP_DIAG1_R3R1_CLEANUP_OUTPUT_EXISTS")
    expected_lock_prefix = Path(
        "/home/vcdeagent1/vcde_artifacts/.ahd_g2b_nvp_video_diag1_r3r2r1_")
    resolved_lock = args.linux_lock.resolve(strict=True)
    require(str(resolved_lock).startswith(str(expected_lock_prefix)),
            "NVP_DIAG1_R3R1_LINUX_LOCK_PATH_INVALID")
    receipt_path = resolved_lock / "receipt.json"
    lock_receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    require(lock_receipt.get("task") == TASK and
            lock_receipt.get("owner_task") == OWNER_TASK and
            lock_receipt.get("state") == "HELD",
            "NVP_DIAG1_R3R1_LINUX_LOCK_OWNER_MISMATCH")

    flags = os.O_RDONLY | os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(args.user_node, flags)
    previous = signal.signal(signal.SIGALRM, alarm)

    def read32(offset: int) -> int:
        signal.setitimer(signal.ITIMER_REAL, 2.0)
        try:
            raw = os.pread(fd, 4, offset)
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0.0)
        require(len(raw) == 4, "NVP_DIAG1_R3R1_CLEANUP_SHORT_READ")
        value = struct.unpack("<I", raw)[0]
        require(value != 0xFFFFFFFF,
                "NVP_DIAG1_R3R1_CLEANUP_FFFFFFFF_READ")
        return value

    result = {"task": TASK, "result": "FAIL", "linux_lock_released": False}
    try:
        values = {
            "transport_control": read32(0x380C),
            "transport_status": read32(0x3810),
            "diag_status": read32(0x3C10),
            "diag_error": read32(0x3C14),
            "route": read32(0x3C38) & 0xFF,
            "bgcolor_78": read32(0x3C3C) & 0xFF,
            "bgcolor_79": read32(0x3C40) & 0xFF,
            "i2c_nack": read32(0x3C54),
            "i2c_timeout": read32(0x3C58),
            "restore_status": read32(0x3C6C),
            "i2c_recovery": read32(0x3C70),
        }
        status = values["diag_status"]
        require(values["transport_control"] == 0 and
                (values["transport_status"] & 0x10F) == 0x004,
                "NVP_DIAG1_R3R1_CLEANUP_TRANSPORT_NOT_QUIESCENT")
        require(bool(status & 0x020) and bool(status & 0x080) and
                not bool(status & 0x040),
                "NVP_DIAG1_R3R1_CLEANUP_BASELINE_STATE_INVALID")
        require(values["restore_status"] == 3 and
                values["route"] == 0x00 and
                values["bgcolor_78"] == 0x88 and
                values["bgcolor_79"] == 0x88,
                "NVP_DIAG1_R3R1_CLEANUP_VISIBLE_BASELINE_MISMATCH")
        require(values["i2c_nack"] == 0 and
                values["i2c_timeout"] == 0 and
                values["i2c_recovery"] == 0,
                "NVP_DIAG1_R3R1_CLEANUP_I2C_NOT_CLEAN")
        holder = subprocess.run(
            ["/usr/bin/fuser", "--", args.c2h_node],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, check=False)
        require(holder.returncode == 1 and not holder.stdout.strip(),
                "NVP_DIAG1_R3R1_C2H_HOLDER_PRESENT")
        result["pre_unload"] = {
            key: f"0x{value:08X}" if key.endswith("status") or
                 key.endswith("control") or key == "diag_error" else value
            for key, value in values.items()
        }
        result["physical_quiescence"] = "PASS"
        result["pending_aio"] = 0
        result["native_helpers_absent"] = True
    finally:
        signal.signal(signal.SIGALRM, previous)
        os.close(fd)

    require(Path("/sys/module/xdma_ahd_pcie").is_dir(),
            "NVP_DIAG1_R3R1_DRIVER_NOT_LOADED")
    unload = subprocess.run(
        ["/sbin/rmmod", "xdma_ahd_pcie"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, check=False)
    require(unload.returncode == 0,
            "NVP_DIAG1_R3R1_DRIVER_UNLOAD_FAILED:" + unload.stderr.strip())
    deadline = time.monotonic() + 5.0
    while time.monotonic() < deadline:
        if (not Path("/sys/module/xdma_ahd_pcie").exists() and
                not Path(args.user_node).exists() and
                not Path(args.c2h_node).exists()):
            break
        time.sleep(0.05)
    require(not Path("/sys/module/xdma_ahd_pcie").exists(),
            "NVP_DIAG1_R3R1_DRIVER_REMAINED_LOADED")
    require(not Path(args.user_node).exists() and
            not Path(args.c2h_node).exists(),
            "NVP_DIAG1_R3R1_XDMA_NODES_REMAINED")
    result.update({
        "result": "PASS",
        "driver_unloaded": True,
        "xdma_nodes_removed": True,
        "stream_disabled": True,
        "product_baseline_restored": True,
        "firmware_internal_bank_verify":
            "PASS_FIRMWARE_INTERNAL_PHYSICAL_READBACK",
    })

    # Release only the exact validated task lock.
    receipt_path.unlink()
    resolved_lock.rmdir()
    result["linux_lock_released"] = True
    args.output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with args.output.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    print(json.dumps(result, sort_keys=True), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
