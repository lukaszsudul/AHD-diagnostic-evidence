#!/usr/bin/env python3
"""Static source-freeze and architecture gates for R1d."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

PROTECTED = {
    "rtl/nvp/nvp6134c_autoinit.vhd": "5dc0230cd569f03d68452055db6b10c5fcade751",
    "rtl/nvp/nvp6134c_i2c_bringup.vhd": "cfe33464d8e75c514462786593b278d90b4059a4",
    "rtl/nvp/nvp6134c_diagnostics_pkg.vhd": "7ddd60fc86da49cda1adcd7af7b772b337c95df6",
    "xdc/boards/current/nvp_control.xdc": "2e4a6f56d5dfa227a968492fe4476d25721f09f9",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"STATIC_GATE_FAIL: {message}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", type=Path)
    args = parser.parse_args()
    repo = args.repo.resolve()
    for relative, expected in PROTECTED.items():
        actual = subprocess.check_output(
            ["git", "-c", f"safe.directory={repo.as_posix()}", "-C", str(repo),
             "hash-object", relative], text=True).strip()
        require(actual == expected, f"protected blob {relative}: {actual}")

    top = (repo / "rtl/top/ahd_capture_top_xdma.sv").read_text(encoding="utf-8")
    engine = (repo / "rtl/v41/nvp_i2c_address_probe.sv").read_text(encoding="utf-8")
    regs = (repo / "rtl/v41/nvp_address_probe_regs.sv").read_text(encoding="utf-8")
    require(".I2C_HZ(50000)" in top, "formal autoinit I2C_HZ changed")
    require("probe_owns_bus ? probe_scl_oen : nvp_init_scl_oen" in top,
            "SCL ownership mux mismatch")
    require("probe_owns_bus ? probe_sda_oen : nvp_init_sda_oen" in top,
            "SDA ownership mux mismatch")
    require("localparam logic [7:0] ADDRESS_BYTE = 8'h60" in engine,
            "probe address byte mismatch")
    require("8'h61" not in engine, "read address present in probe engine")
    uncommented = re.sub(r"//.*", "", engine, flags=re.MULTILINE).lower()
    require("reg_addr" not in uncommented and "write_data" not in uncommented,
            "register/data byte datapath unexpectedly present")
    require("17'h02200" in regs and "17'h00028" in regs,
            "probe register range mismatch")
    require("TARGET_COUNT(10000)" in top, "probe target mismatch")
    require("DIVIDER_50KHZ(625)" in top and "DIVIDER_25KHZ(1250)" in top,
            "probe divider mismatch")
    require("scl_sync[0] <= raw_scl_i" in engine, "raw SCL fanout gate failed")
    require("sda_sync[0] <= raw_sda_i" in engine, "raw SDA fanout gate failed")
    print("PROTECTED_NVP_BLOBS_UNCHANGED=YES")
    print("FORMAL_AUTOINIT_I2C_HZ=50000")
    print("PROBE_ADDRESS_BYTE=0x60")
    print("PROBE_REGISTER_BYTES_SENT=0")
    print("PROBE_DATA_BYTES_SENT=0")
    print("PROBE_READ_ADDRESS_BYTES_SENT=0")
    print("PROBE_STATIC_ARCHITECTURE_GATE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
