#!/usr/bin/env python3
"""E01-E08 fail-closed source and pinned-reference contract gate."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference-root", type=Path, required=True)
    args = parser.parse_args()
    top = (ROOT / "rtl/top/ahd_capture_top_xdma.sv").read_text(encoding="utf-8")
    executor = (ROOT / "rtl/g2b/g2b_nvp_acq1_compat0_r2.sv").read_text(encoding="utf-8")
    wrapper = (ROOT / "rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv").read_text(encoding="utf-8")
    host = (ROOT / "host/acq1_compat0_r2/controller.py").read_text(encoding="utf-8")
    profile = json.loads((ROOT / "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json").read_text())
    operation = json.loads((ROOT / "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json").read_text())

    require("parameter integer ENABLE_NVP_CAMERA_SCAN1 = 0" in top and
            "parameter integer ENABLE_NVP_ACQ1_EXECUTOR = 0" in top and
            profile["product_defaults_unchanged"] is True,
            "E01_PRODUCT_DEFAULT_NOT_EXCLUDED")
    print("PASS E01 PRODUCT profile excludes scanner and executor")

    require(profile["parameters"] == {
                "ENABLE_NVP_VIDEO_DIAGNOSTIC": 0,
                "ENABLE_NVP_CAMERA_SCAN1": 1,
                "ENABLE_NVP_ACQ1_EXECUTOR": 1,
            } and "GEN_NVP_CAMERA_ACQ1_COMPAT0_R2_CORE" in top and
            "g2b_nvp_camera_scan1 SCAN1_CORE" in wrapper and
            "g2b_nvp_acq1_compat0_r2 ACQ_EXECUTOR" in wrapper,
            "E02_DIAGNOSTIC_PROFILE_NOT_EXACT")
    print("PASS E02 diagnostic profile includes SCAN1 and fixed executor only")

    ranges = {
        "LEGACY_DIAGNOSTIC": (0x03C00, 0x03FFF),
        "PRODUCT_AND_XDMA": (0x00000, 0x11FFF),
        "SCAN1": (0x12000, 0x123FF),
        "ACQ1": (0x12400, 0x127FF),
    }
    acq = ranges["ACQ1"]
    require(all(acq[1] < low or acq[0] > high
                for name, (low, high) in ranges.items() if name != "ACQ1"),
            "E03_NUMERIC_RANGE_ALIAS")
    require("legacy_host_req_addr >= 17'h12400" in top and
            "legacy_host_req_addr <= 17'h127ff" in top and
            "mmio_req_addr >= 17'h12400" in wrapper and
            "mmio_req_addr <= 17'h127FF" in wrapper,
            "E03_SOURCE_DECODE_NOT_EXACT")
    print("PASS E03 ACQ MMIO has zero aliases")

    require(all(token not in host for token in (
        'add_argument("--bank"', 'add_argument("--register"',
        'add_argument("--value"', 'add_argument("--mask"',
        'add_argument("--channel"')) and
        'choices=[item.name for item in Command]' in host,
        "E04_GENERIC_HOST_I2C_SURFACE_PRESENT")
    print("PASS E04 generic host I2C interface is absent")

    require("localparam logic [7:0] BANK5 = 8'h05;" in executor and
            "localparam logic [7:0] REG_LEVEL = 8'h08;" in executor and
            "localparam logic [7:0] REG_COMPANION = 8'h05;" in executor and
            "i2c_cmd_reg = REG_LEVEL;" in executor and
            "i2c_cmd_reg = REG_COMPANION;" in executor and
            operation["channel"] == "CH1" and operation["private_bank"] == "0x05",
            "E05_WRITABLE_SCOPE_NOT_EXACT")
    functional_write_states = re.findall(
        r"(ST_(?:RB_)?WRITE(?:08|05)):\s*begin.*?i2c_cmd_write = 1'b1;.*?i2c_cmd_reg = (REG_LEVEL|REG_COMPANION);",
        executor, re.S)
    require(set(functional_write_states) == {
                ("ST_WRITE08", "REG_LEVEL"), ("ST_WRITE05", "REG_COMPANION"),
                ("ST_RB_WRITE08", "REG_LEVEL"), ("ST_RB_WRITE05", "REG_COMPANION")},
            f"E05_FUNCTIONAL_WRITE_STATE_SET:{functional_write_states!r}")
    print("PASS E05 only CH1, Bank5, registers 0x08 and 0x05 are writable")

    require("ST_WRITE08" in executor and
            re.search(r"ST_WRITE08:.*?state <= ST_WRITE05;.*?ST_WRITE05:.*?state <= ST_READBACK08;",
                      executor, re.S) is not None and
            operation["forward_order"] == "BANK5_0x08_LEVEL_THEN_BANK5_0x05_A4",
            "E06_FORWARD_ORDER_NOT_EXACT")
    print("PASS E06 forward order is exactly 0x08 then 0x05")

    write05_blocks = re.findall(
        r"(?ms)^\s*ST_WRITE05:\s*begin(.*?)(?=^\s*ST_[A-Z0-9_]+(?:,\s*ST_[A-Z0-9_]+)*:\s*begin)",
        executor)
    require(len(write05_blocks) == 2 and
            all("state <= ST_WRITE08;" not in block for block in write05_blocks),
            "E07_LEGACY_REVERSED_ORDER_FOUND")
    print("PASS E07 legacy reversed order is absent")

    reference_root = args.reference_root.resolve()
    video_c = (reference_root / "video.c").read_text(encoding="utf-8", errors="replace")
    video_h = (reference_root / "video.h").read_text(encoding="utf-8", errors="replace")
    autoinit = (ROOT / "rtl/nvp/nvp6134c_autoinit.vhd").read_text(encoding="utf-8")
    first_08 = video_c.index("gpio_i2c_write(nvp6134_iic_addr[ch/4], 0x08, 0x50);")
    companion = video_c.index("gpio_i2c_write(nvp6134_iic_addr[ch/4], 0x05, 0xA4);")
    helper_call = video_c.index("nvp6134_cvbs_slicelevel_con(ch, 0);")
    require(first_08 < companion < helper_call and
            "if(ch_mode_status[ch]<NVP6134_VI_720P_2530)" in video_c and
            "NVP6134_VI_720P_2530\t= 0x10" in video_h and
            "NVP6134_VI_1080P_2530\t= 0x20" in video_h and
            'range_sel        => "10"' in autoinit and
            operation["reference_helper"]["condition_result"] is False,
            "E08_REFERENCE_HELPER_FALSE_NOT_PROVEN")
    print("PASS E08 reference helper condition is proven false for governed context")


if __name__ == "__main__":
    main()
