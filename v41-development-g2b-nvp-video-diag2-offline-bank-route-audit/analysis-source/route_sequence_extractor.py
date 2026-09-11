#!/usr/bin/env python3
"""Extract the bounded local VDO1 route sequences and their authority."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def assert_current_sequence(diag_path: Path) -> None:
    text = diag_path.read_text(encoding="utf-8")
    required = [
        "launch_i2c(1'b1, BANK_SELECT, BANK1)",
        "launch_i2c(1'b0, REG_VDO1_ROUTE, 8'b0)",
        "current_channel - 3'd1",
        "state <= VERIFY_ROUTE",
        "state <= WAIT_SETTLE",
        "state <= SAMPLE_STATUS",
    ]
    missing = [token for token in required if token not in text]
    if missing:
        raise AssertionError(f"current route sequence tokens missing: {missing}")


def existing_sequences(diag_path: Path, package_path: Path, codec_path: Path) -> list[dict[str, Any]]:
    assert_current_sequence(diag_path)
    codec = codec_path.read_text(encoding="utf-8", errors="replace")
    package = package_path.read_text(encoding="utf-8")
    if "x\"01C2\" & out_c2(channel_sel)" not in package:
        raise AssertionError("historical patch route operation unavailable")
    if "0xc2" not in codec.lower():
        raise AssertionError("reference codec C2 initialization unavailable")
    return [
        {
            "Source": "rtl/g2b/g2b_nvp_video_diag.sv:750-807",
            "VersionOrBranch": "fc37d815b5d64ef90dfbd99c57ae4cc09567b56f",
            "UseCase": "active 4x4 diagnostic route switch",
            "OldRoute": "runtime readback",
            "NewRoute": "0/1/2/3",
            "RegisterSequence": "B1 select; C2 read; C2 RMW low nibble; C2 readback; B0 select; settle; status sample",
            "Delays": ">=200 ms after route verify",
            "Readback": "full C2, low nibble required",
            "ReArmUsed": "NO",
            "Authority": "exact active R3 source",
        },
        {
            "Source": "rtl/nvp/nvp6134c_diagnostics_pkg.vhd:470-487",
            "VersionOrBranch": "historical/current package stage-0 patch path",
            "UseCase": "fixed runtime patch table, not used by R3 scan core",
            "OldRoute": "not read",
            "NewRoute": "channel_sel",
            "RegisterSequence": "B0 select; AUTO writes; B1 select; C2 write; CD write; B0 select",
            "Delays": "NONE",
            "Readback": "NONE in table",
            "ReArmUsed": "NO",
            "Authority": "local source; not an accepted reference-driver switch protocol",
        },
        {
            "Source": "authoritative reference capture_supervisor/src/codec.c:237-245",
            "VersionOrBranch": "capture-card-fw_ee06d86_source.zip",
            "UseCase": "startup output initialization only",
            "OldRoute": "N/A",
            "NewRoute": "CH1 / 0",
            "RegisterSequence": "B0 0x56=0x10; B1 C2=0; C3=0; C8 read then clear upper nibble; CD=0x86; B0",
            "Delays": "NONE at route block",
            "Readback": "C8 only for RMW",
            "ReArmUsed": "NO",
            "Authority": "accepted local reference source; no runtime channel-switch routine found",
        },
        {
            "Source": "NVP6134C_Rev1_0.pdf pages 20,78-79",
            "VersionOrBranch": "vendor Rev1.0",
            "UseCase": "register and mode definition",
            "OldRoute": "N/A",
            "NewRoute": "0/1/2/3 maps CH1/CH2/CH3/CH4",
            "RegisterSequence": "C2 source select; C8 one-port mode; CA output enables; CD clock select/delay",
            "Delays": "NO switch delay specified",
            "Readback": "register semantics only",
            "ReArmUsed": "NOT_DOCUMENTED",
            "Authority": "local primary vendor PDF; no re-arm sequence located",
        },
    ]


def current_sequence_steps() -> list[dict[str, str]]:
    return [
        {"Order": "1", "Action": "require transport_quiescent", "Source": "g2b_nvp_video_diag.sv:751-753", "ReArm": "NO"},
        {"Order": "2", "Action": "write Bank0 0xFF=0x01", "Source": "g2b_nvp_video_diag.sv:756", "ReArm": "NO"},
        {"Order": "3", "Action": "read Bank1 0xC2", "Source": "g2b_nvp_video_diag.sv:757", "ReArm": "NO"},
        {"Order": "4", "Action": "write C2={old[7:4],0,channel-1}", "Source": "g2b_nvp_video_diag.sv:758-760", "ReArm": "NO"},
        {"Order": "5", "Action": "read C2 and require low nibble", "Source": "g2b_nvp_video_diag.sv:782-800", "ReArm": "NO"},
        {"Order": "6", "Action": "write Bank0 0xFF=0x00", "Source": "g2b_nvp_video_diag.sv:787", "ReArm": "NO"},
        {"Order": "7", "Action": "wait >=200 ms", "Source": "g2b_nvp_video_diag.sv:809-823", "ReArm": "NO"},
        {"Order": "8", "Action": "five stable NVP status samples", "Source": "g2b_nvp_video_diag.sv:825-910", "ReArm": "NO"},
        {"Order": "9", "Action": "host RESET_STREAM_STATE after snapshot, if VCLK active", "Source": "R3R2R1 host contract; FPGA transport reset", "ReArm": "NOT_NVP_REARM"},
        {"Order": "10", "Action": "host source readiness measurement", "Source": "R3R2R1 host contract", "ReArm": "NO"},
    ]


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("diag", type=Path)
    parser.add_argument("package", type=Path)
    parser.add_argument("codec", type=Path)
    args = parser.parse_args()
    print(json.dumps(existing_sequences(args.diag, args.package, args.codec), indent=2))
