#!/usr/bin/env python3
"""Static profile, write-surface, manifest, and noninterference gate."""

from __future__ import annotations

import csv
import re
import subprocess
import sys
from pathlib import Path


BASE_COMMIT = "fc37d815b5d64ef90dfbd99c57ae4cc09567b56f"
EXPECTED_TREE = "cdff3ea9d786141ff9bfd46f7099198324604663"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def git(root: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), *args], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode:
        raise RuntimeError(f"git {' '.join(args)} failed: {result.stderr}")
    return result.stdout.strip()


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    top = (root / "rtl/top/ahd_capture_top_xdma.sv").read_text(encoding="utf-8")
    core = (root / "rtl/g2b/g2b_nvp_camera_scan1.sv").read_text(encoding="utf-8")
    master = (root / "rtl/v41/nvp_i2c_fixed_master.sv").read_text(encoding="utf-8")
    require(git(root, "show", "-s", "--format=%T", BASE_COMMIT) == EXPECTED_TREE,
            "accepted base tree mismatch")

    for literal in (
        "parameter integer ENABLE_NVP_CAMERA_SCAN1 = 0",
        "parameter integer ENABLE_NVP_ACQ1_EXECUTOR = 0",
        "if (ENABLE_NVP_VIDEO_DIAGNOSTIC != 0 ||",
        "ENABLE_NVP_CAMERA_SCAN1 != 0) begin : GEN_NVP_DIAGNOSTIC_I2C",
        "else if (ENABLE_NVP_CAMERA_SCAN1 != 0) begin : GEN_NVP_CAMERA_SCAN1_CORE",
        "GEN_NO_NVP_DIAGNOSTIC_I2C",
    ):
        require(literal in top, f"profile literal missing: {literal}")
    require("g2b_nvp_camera_scan1 NVP_CAMERA_SCAN1_CORE" in top,
            "SCAN1 instance missing")
    require("g2b_nvp_video_diag NVP_VIDEO_DIAG_CORE" in top,
            "legacy DIAG1 explicit branch missing")
    require("ACQ1 executor is not implemented or authorized in SCAN1-R1" in top,
            "ACQ1 exclusion assertion missing")
    print("PASS T01 PRODUCT_PROFILE_EXCLUDES_SCAN1_AND_ACQ1")
    print("PASS T02 SCAN1_PROFILE_EXCLUDES_LEGACY_DIAG1_AND_ACQ1")

    require(core.count("i2c_cmd_write = 1'b1;") == 2,
            "scanner must have exactly two compiled write states")
    require(core.count("i2c_cmd_reg = BANK_SELECT;") == 5,
            "unexpected scanner bank-select command structure")
    require("i2c_cmd_wdata = mmio" not in core and
            not re.search(r"i2c_cmd_reg\s*=.*mmio", core),
            "generic host-to-I2C operand path found")
    require("localparam logic [7:0] BANK_SELECT = 8'hFF" in core,
            "only-write register constant missing")
    require("CAUSE_WADDR_NACK" in master and "CAUSE_REGADDR_NACK" in master and
            "CAUSE_RADDR_NACK" in master,
            "diagnostic-only phase cause missing")
    print("PASS T22 NO_GENERIC_HOST_I2C_BANK_REGISTER_VALUE_PATH")

    protected = (
        "rtl/g2b/v41_g2b_onech_c2h.sv",
        "rtl/g2b/v41_g2b_mmio_router.sv",
        "rtl/record/bt656_record_producer.sv",
        "rtl/record/capture_mailbox.sv",
        "rtl/video/video_capture.sv",
        "rtl/video/physical_frontend.sv",
        "ip/v41/xdma_v41_m1.xci",
        "xdc/common/g2b_cdc.xdc",
        "xdc/common/cdc.xdc",
    )
    for relative in protected:
        expected_blob = git(root, "rev-parse", f"{BASE_COMMIT}:{relative}")
        actual_blob = git(root, "hash-object", str(root / relative))
        require(actual_blob == expected_blob, f"protected noninterference source changed: {relative}")
    forbidden_ports = ("transport_", "vdo", "vclk", "bt656", "c2h", "xdma",
                       "bgdcol", "route_channel", "stream_enable")
    module_header = core[:core.index(");")]
    require(not any(token in module_header.casefold() for token in forbidden_ports),
            "scanner port fanout reaches protected functional plane")

    manifest_path = root / "host/scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.csv"
    blacklist_path = root / "host/scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_PROHIBITED_READS.csv"
    with manifest_path.open(newline="", encoding="utf-8-sig") as handle:
        entries = list(csv.DictReader(handle))
    with blacklist_path.open(newline="", encoding="utf-8-sig") as handle:
        blacklist = list(csv.DictReader(handle))
    active = {(row["Bank"].upper(), row["Register"].upper()) for row in entries}
    prohibited = {(row["Bank"].upper(), row["Register"].upper()) for row in blacklist}
    require(len(entries) == 82 and len(blacklist) == 14 and not active & prohibited,
            "manifest noninterference gate failed")
    print("PASS T23 NO_FUNCTIONAL_FANOUT_TO_VIDEO_PARSER_OR_DMA")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"FAIL STATIC_SCAN1_CONTRACT:{exc}", file=sys.stderr)
        raise
