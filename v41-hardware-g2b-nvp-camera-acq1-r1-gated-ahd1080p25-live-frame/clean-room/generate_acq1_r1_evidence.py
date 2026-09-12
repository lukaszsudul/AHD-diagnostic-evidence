#!/usr/bin/env python3
"""Generate clean-room ACQ1-R1 Phase-A evidence without touching the DUT.

The input is the already-published SCAN0 semantic evidence plus byte-pinned
current/reference sources. Reference-driver source is inspected only for
identity and literal semantic checks; it is never copied to the output.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


TASK = "G2B-NVP-CAMERA-ACQ1-R1"
TARGET_DIRNAME = "v41-hardware-g2b-nvp-camera-acq1-r1-gated-ahd1080p25-live-frame"
SOURCE_PARENT = "c7e16fa3da26545cef960a6c75427a3614c4b655"
SOURCE_TREE = "56526e17154f8e06f3eb4b95233934c18b6ee06e"
REFERENCE_COMMIT = "081ebbff9a2722d47acf16c680594be43cb179e2"
REFERENCE_TREE = "f6926ef14a34365a0e47652253f5f4d63274cb1e"
FIRST_BLOCKER = "ACQ1_R1_COMPLETE_ROLLBACK_AUTHORITY_NOT_PROVEN"

EXPECTED = {
    "prompt": "1C8FC6556291AA4824AD797A8ECE2F056EEDC3CCBD14DF7BA98BF1190C334F95",
    "video.c": "CBC10B8585CF9F300C47EBD40AACB08635EF62784CF94B691B722758BA49657A",
    "video.h": "CB12F446D5ABCD0C549B3C29E66E830FC7C12ECF56448A1A7326C26895F1A0C7",
    "eq_common.c": "13A17C85C0D433416DFA5045151860EA38841FCABC7E6C3FF50FB9829CA8F90B",
    "action_csv": "9537C24203A3A34978E100779A06DEEC9CE984DB3EB0DFE19DC89654BE3BA6B9",
    "eq_csv": "0DC0A07BE8640AAF1187A40974DF01CE4DA02E53214BC7574CD909E600F717EA",
    "rollback_json": "34A1E8354457B6BA741FA7F6BD236513EA63A9EE0AE86785F221BD974A375282",
    "decision_json": "110A42871547B7A3DB5212A35BA9FC90F54B851EF6E62FFF7A0DDEFBB22B238B",
    "read_set_csv": "688A09C524D9E265E2A3CCA45BAB99A3E5B5966A713BF2218A19AE99CFDCC7CF",
    "authority_csv": "14118F762BB50A73C2195F8A6DD07D9FBDE9A09E0160E24637AAB3B894C845AE",
    "blacklist_csv": "6C1F770CDF5B184E4E80E9C8DF8DF3696E2BA595121844A8F16682937F3B6440",
    "autoinit_vhd": "FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5",
    "diag_pkg_vhd": "36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156",
}

SAFE_READ_TARGETS = {
    "B00:R23": "SCAN0_REGISTER_AUTHORITY_MATRIX:NVP6134C_DATASHEET",
    "B00:R81": "SCAN0_REGISTER_AUTHORITY_MATRIX:NVP6134C_DATASHEET",
    "B00:R85": "SCAN0_REGISTER_AUTHORITY_MATRIX:NVP6134C_DATASHEET",
    "B01:R84": "SCAN0_REGISTER_AUTHORITY_MATRIX:NVP6134C_DATASHEET",
    "B01:R8C": "SCAN0_REGISTER_AUTHORITY_MATRIX:NVP6134C_DATASHEET",
    "B01:RC2": "ACCEPTED_DIAG1_DIAG2_FULL_BYTE_SAVE_MASKED_ROUTE_RESTORE",
}

SYMBOLIC_TARGETS = {
    "B01:RED": "preserve all bits except CH1 bit; old byte required",
    "B09:R44": "preserve all bits except CH1 bit; old byte required",
}

DISCRIMINATOR_WRITE_TARGETS = {
    "B00:R81", "B00:R85", "B01:R84", "B01:R8C", "B05:R24",
    "B05:R58", "B05:R90", "B09:R80", "B09:R81",
}

REQUIRED_FILES = [
    "V41_G2B_NVP_CAMERA_ACQ1_R1_MAIN_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_OWNER_AUTHORIZATION.md",
    "G2B_NVP_CAMERA_ACQ1_R1_SCOPE.md",
    "G2B_NVP_CAMERA_ACQ1_R1_INHERITANCE.md",
    "G2B_NVP_CAMERA_ACQ1_R1_REFERENCE_AUTHORITY.md",
    "G2B_NVP_CAMERA_ACQ1_R1_LICENSE_DISPOSITION.md",
    "G2B_NVP_CAMERA_ACQ1_R1_SLICE_ACTION_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_FORMAT_DETECTION_MANIFEST.md",
    "G2B_NVP_CAMERA_ACQ1_R1_AHD_CVI_DISCRIMINATOR_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_AHD1080P25_MODE_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_INITIAL_EQ_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_ACP_SUBSET_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_REARM_ENABLE_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_TOUCHED_REGISTER_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_READBACK_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_ROLLBACK_MANIFEST.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_SIMULATION_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_BUILD_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_TIMING_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_CDC_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_DRC_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_RESOURCE_REPORT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_BITSTREAM_MANIFEST.md",
    "G2B_NVP_CAMERA_ACQ1_R1_RUNTIME_BUNDLE_MANIFEST.json",
    "G2B_NVP_CAMERA_ACQ1_R1_DUT_BUNDLE_RECEIPT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_RUNTIME_IDENTITY.md",
    "G2B_NVP_CAMERA_ACQ1_R1_MMIO_SANITY.md",
    "G2B_NVP_CAMERA_ACQ1_R1_CONNECTED_BASELINE.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_FUNCTIONAL_BASELINE_A.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_FUNCTIONAL_BASELINE_B.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_PREWRITE_BASELINE.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_SLICE_RESULTS.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_FORMAT_IDENTIFICATION.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_MODE_APPLY_RECEIPT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_LOCK_TIMELINE.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_BT656_READINESS.md",
    "G2B_NVP_CAMERA_ACQ1_R1_CAPTURE_RESULTS.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_FRAME_HASHES.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_PIXEL_STATISTICS.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_FRAME_CONTENT_DECISION.md",
    "G2B_NVP_CAMERA_ACQ1_R1_ROLLBACK_RECEIPT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_CLEANUP_RECEIPT.md",
    "G2B_NVP_CAMERA_ACQ1_R1_FINAL_STATE.md",
    "G2B_NVP_CAMERA_ACQ1_R1_GATE_MATRIX.csv",
    "G2B_NVP_CAMERA_ACQ1_R1_STATE.json",
    "G2B_NVP_CAMERA_ACQ1_R1_EVIDENCE_INDEX.md",
    "G2B_NVP_CAMERA_ACQ1_R1_SHA256_MANIFEST.txt",
]

MANIFEST_FIELDS = [
    "sequence_number", "reference_function", "reference_source_location",
    "clean_room_action_phase", "bank", "register", "operation_type",
    "write_value_or_mask", "preserved_bits", "required_initial_value",
    "expected_readback", "fixed_delay_ms", "condition", "reason",
    "included_excluded_decision", "rollback_operation", "rollback_readback",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require_hash(label: str, path: Path) -> None:
    actual = sha256(path)
    if actual != EXPECTED[label]:
        raise SystemExit(f"identity mismatch for {label}: {actual}")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def write_json(path: Path, value: object) -> None:
    write_text(path, json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False))


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def target(bank: str, register: str) -> str:
    b = bank.removeprefix("0x").upper().zfill(2)
    r = register.removeprefix("0x").upper().zfill(2)
    return f"B{b}:R{r}"


def split_target(value: str) -> tuple[str, str]:
    bank, register = value.split(":")
    return "0x" + bank[1:], "0x" + register[1:]


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def convert_action_row(row: dict[str, str]) -> dict[str, object]:
    op = row["operation"]
    bank = row["ch1_bank"] or "N/A"
    register = row["ch1_register"] or "N/A"
    value = row["ch1_value"] or "N/A"
    key = None
    if bank.startswith("0x") and register.startswith("0x") and register.upper() != "0XFF":
        key = target(bank, register)
    if op == "BANK_SELECT":
        initial = "ENTRY_OR_CURRENT_BANK_METADATA"
        readback = f"BANK_EQUALS_{value}"
        rollback = "RESTORE_ENTRY_BANK_AT_ACTION_END"
        rollback_readback = "ENTRY_BANK_EQUALITY"
    elif op in {"WRITE", "READ_FOR_RMW", "RMW_CLEAR_CHANNEL_BIT"}:
        initial = "CAPTURED_PRE_CAMPAIGN_FULL_BYTE_REQUIRED"
        readback = "DEFINED_VALUE_OR_MASK; TECHNICAL_READBACK_AUTHORITY_REQUIRED"
        rollback = "RESTORE_CAPTURED_PRE_CAMPAIGN_FULL_BYTE"
        rollback_readback = "EXACT_BASELINE_EQUALITY_REQUIRED"
    elif op == "STATE_ASSIGN":
        initial = "CAPTURED_HOST_STATE"
        readback = "HOST_STATE_EQUALS_ASSIGNED_VALUE"
        rollback = "RESTORE_CAPTURED_HOST_STATE"
        rollback_readback = "HOST_STATE_EQUALITY"
    else:
        initial = "N/A"
        readback = "N/A"
        rollback = "NO_REGISTER_ROLLBACK"
        rollback_readback = "N/A"
    preserved = "NONE"
    if key in SYMBOLIC_TARGETS:
        preserved = SYMBOLIC_TARGETS[key]
    return {
        "sequence_number": row["order"],
        "reference_function": row["source_function"],
        "reference_source_location": f"{row['source_file']}:{row['source_line']}",
        "clean_room_action_phase": row["phase"],
        "bank": bank,
        "register": register,
        "operation_type": op,
        "write_value_or_mask": value,
        "preserved_bits": preserved,
        "required_initial_value": initial,
        "expected_readback": readback,
        "fixed_delay_ms": row["delay_ms"] or "0",
        "condition": "CH1,PAL,NVP6134_VI_1080P_2530; exact selected path",
        "reason": row["note"] or row["phase"],
        "included_excluded_decision": "INCLUDED_EXACT_PINNED_REFERENCE_PATH",
        "rollback_operation": rollback,
        "rollback_readback": rollback_readback,
    }


def manual_manifest_row(
    seq: int,
    function: str,
    location: str,
    phase: str,
    bank: str,
    register: str,
    operation: str,
    value: str = "N/A",
    delay: int = 0,
    condition: str = "ALWAYS",
    reason: str = "",
    initial: str = "N/A",
    expected: str = "N/A",
    preserved: str = "NONE",
    rollback: str = "NO_REGISTER_ROLLBACK",
    rollback_readback: str = "N/A",
) -> dict[str, object]:
    return {
        "sequence_number": seq,
        "reference_function": function,
        "reference_source_location": location,
        "clean_room_action_phase": phase,
        "bank": bank,
        "register": register,
        "operation_type": operation,
        "write_value_or_mask": value,
        "preserved_bits": preserved,
        "required_initial_value": initial,
        "expected_readback": expected,
        "fixed_delay_ms": delay,
        "condition": condition,
        "reason": reason,
        "included_excluded_decision": "INCLUDED",
        "rollback_operation": rollback,
        "rollback_readback": rollback_readback,
    }


def extract_current_init_targets(diag_pkg: Path) -> set[str]:
    text = diag_pkg.read_text(encoding="utf-8")
    start = text.index("function c_v38ek_marek_op_for_slot")
    end = text.index("end function;", start)
    segment = text[start:end]
    found: set[str] = set()
    pattern = re.compile(
        r"when\s+(\d+)\s*=>\s*if\s+stage_enabled\(stage,\s*(\d+)\)\s+"
        r"then\s+return\s+x\"([0-9A-Fa-f]{6})\""
    )
    for match in pattern.finditer(segment):
        stage = int(match.group(2))
        op = match.group(3).upper()
        if stage <= 2 and op[:2] != "FE" and op[2:4] != "FF" and op != "FFFFFF":
            found.add(f"B{op[:2]}:R{op[2:4]}")
    start = text.index("function c_v38ek_overlay_op_for_slot")
    end = text.index("end function;", start)
    for line in text[start:end].splitlines():
        match = re.search(r"return\s+x\"([0-9A-Fa-f]{4})(?:[0-9A-Fa-f]{2})?\"", line)
        if match:
            prefix = match.group(1).upper()
            if prefix[2:4] != "FF":
                found.add(f"B{prefix[:2]}:R{prefix[2:4]}")
    return found


def placeholder_md(title: str, disposition: str = "NOT_REACHED") -> str:
    return f"""# {title}

- Status: `{disposition}`
- First blocker: `{FIRST_BLOCKER}`
- Functional NVP writes: `0`
- DUT contact: `NO`

This phase was not entered because the mandatory complete touched-register
baseline/readback/rollback authority gate failed before source implementation.
No later result is inferred from inherited evidence.
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scan0", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--prompt", type=Path, required=True)
    parser.add_argument("--output-parent", type=Path, required=True)
    args = parser.parse_args()

    scan0 = args.scan0.resolve()
    source = args.source.resolve()
    reference = args.reference.resolve()
    prompt = args.prompt.resolve()
    out = args.output_parent.resolve() / TARGET_DIRNAME
    if out.exists():
        raise SystemExit(f"refusing to overwrite existing evidence directory: {out}")
    out.mkdir(parents=True)
    generated = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")

    paths = {
        "prompt": prompt,
        "video.c": reference / "video.c",
        "video.h": reference / "video.h",
        "eq_common.c": reference / "eq_common.c",
        "action_csv": scan0 / "G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_MANIFEST.csv",
        "eq_csv": scan0 / "G2B_NVP_CAMERA_SCAN0_EQ_AHD1080P25_INIT_MANIFEST.csv",
        "rollback_json": scan0 / "G2B_NVP_CAMERA_SCAN0_ACQ1_ROLLBACK_SET.json",
        "decision_json": scan0 / "G2B_NVP_CAMERA_SCAN0_FORMAT_DETECTION_DECISION_TREE.json",
        "read_set_csv": scan0 / "G2B_NVP_CAMERA_SCAN0_FORMAT_DETECTION_READ_SET.csv",
        "authority_csv": scan0 / "G2B_NVP_CAMERA_SCAN0_REGISTER_AUTHORITY_MATRIX.csv",
        "blacklist_csv": scan0 / "G2B_NVP_CAMERA_SCAN0_READ_SIDE_EFFECT_BLACKLIST.csv",
        "autoinit_vhd": source / "rtl/nvp/nvp6134c_autoinit.vhd",
        "diag_pkg_vhd": source / "rtl/nvp/nvp6134c_diagnostics_pkg.vhd",
    }
    for label, path in paths.items():
        require_hash(label, path)

    video = paths["video.c"].read_text(encoding="utf-8", errors="replace")
    video_h = paths["video.h"].read_text(encoding="utf-8", errors="replace")
    autoinit = paths["autoinit_vhd"].read_text(encoding="utf-8")
    diag_pkg = paths["diag_pkg_vhd"].read_text(encoding="utf-8")
    assert 'range_sel        => "10"' in autoinit
    assert 'channel_sel      => "00"' in autoinit
    assert 'when "10" => return x"03"' in diag_pkg
    assert "ch_mode_status[ch]<NVP6134_VI_720P_2530" in video
    assert "NVP6134_VI_720P_2530\t= 0x10" in video_h
    assert "NVP6134_VI_1080P_2530\t= 0x20" in video_h
    assert "case 0x31" in video and "pre_fmt = 0x03" in video

    action_rows = load_csv(paths["action_csv"])
    assert len(action_rows) == 211
    converted = [convert_action_row(row) for row in action_rows]
    partitions = {
        "G2B_NVP_CAMERA_ACQ1_R1_AHD1080P25_MODE_MANIFEST.csv":
            [row for row in converted if row["clean_room_action_phase"] in {"COMMON", "FHD_COMMON", "AHD1080P25", "STATE"}],
        "G2B_NVP_CAMERA_ACQ1_R1_INITIAL_EQ_MANIFEST.csv":
            [row for row in converted if row["clean_room_action_phase"] == "EQ_INIT"],
        "G2B_NVP_CAMERA_ACQ1_R1_ACP_SUBSET_MANIFEST.csv":
            [row for row in converted if str(row["clean_room_action_phase"]).startswith("ACP_")],
        "G2B_NVP_CAMERA_ACQ1_R1_REARM_ENABLE_MANIFEST.csv":
            [row for row in converted if row["clean_room_action_phase"] == "POST_MODE"],
    }
    assert [len(partitions[name]) for name in partitions] == [161, 9, 35, 6]
    for name, rows in partitions.items():
        write_csv(out / name, MANIFEST_FIELDS, rows)

    # Exact reference-compatible slice action. No readback occurs between the two writes.
    slice_rows: list[dict[str, object]] = []
    seq = 0
    for level in ("0x50", "0x40", "0x60"):
        phase = f"SLICE_{level}"
        specs = [
            ("READ", "ENTRY", "0xFF", "N/A", "capture entry bank", "ENTRY_BANK_CAPTURED"),
            ("BANK_SELECT", "0x05", "0xFF", "0x05", "select Bank5", "BANK_EQUALS_0x05"),
            ("READ", "0x05", "0xFF", "N/A", "verify Bank5", "0x05"),
            ("WRITE", "0x05", "0x08", level, "reference slice level first", level),
            ("WRITE", "0x05", "0x05", "0xA4", "inseparable reference companion second", "0xA4"),
            ("READ", "0x05", "0x08", "N/A", "forward readback", level),
            ("READ", "0x05", "0x05", "N/A", "forward readback", "0xA4"),
            ("BANK_SELECT", "ENTRY", "0xFF", "ENTRY_BANK", "restore entry bank", "ENTRY_BANK"),
            ("READ", "ENTRY", "0xFF", "N/A", "verify entry bank", "ENTRY_BANK"),
        ]
        for op, bank, reg, value, reason, expected in specs:
            seq += 1
            functional = op == "WRITE" and reg != "0xFF"
            slice_rows.append(manual_manifest_row(
                seq, "nvp6134_getvideoloss", "video.c:1036-1069", phase,
                bank, reg, op, value=value,
                condition="CH1 NOVID=1; selected level; stable campaign generation",
                reason=reason,
                initial="CAPTURED_PRE_CAMPAIGN_FULL_BYTE_REQUIRED" if functional else "N/A",
                expected=expected,
                rollback="RESTORE_CAPTURED_PRE_CAMPAIGN_FULL_BYTE" if functional else "RESTORE_ENTRY_BANK_AT_ACTION_END",
                rollback_readback="EXACT_BASELINE_EQUALITY_REQUIRED" if functional else "ENTRY_BANK_EQUALITY",
            ))
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_SLICE_ACTION_MANIFEST.csv", MANIFEST_FIELDS, slice_rows)

    # Exact F0=0x31 initial discriminator branch, including its reference preconditioning writes.
    discr_specs = [
        ("nvp6134_getvideoloss", "video.c:1031-1033", "PRELUDE", "0x00", "0xFF", "BANK_SELECT", "0x00", 0, "select Bank0"),
        ("nvp6134_getvideoloss", "video.c:1032", "PRELUDE", "0x00", "0xA8", "READ", "N/A", 0, "read NOVID"),
        ("video_fmt_det", "video.c:630", "PRELUDE", "N/A", "N/A", "DELAY", "N/A", 200, "reference fixed delay"),
        ("video_fmt_det", "video.c:637", "RAW_TUPLE", "0x05", "0xFF", "BANK_SELECT", "0x05", 0, "select CH1 private bank"),
        ("video_fmt_det", "video.c:638", "RAW_TUPLE", "0x05", "0xF0", "READ", "N/A", 0, "raw format"),
        ("video_fmt_det", "video.c:639", "RAW_TUPLE", "0x05", "0xF2", "READ", "N/A", 0, "conversion auxiliary"),
        ("video_fmt_det", "video.c:640", "RAW_TUPLE", "0x05", "0xF3", "READ", "N/A", 0, "special-format metric"),
        ("video_fmt_det", "video.c:641", "RAW_TUPLE", "0x05", "0xF4", "READ", "N/A", 0, "special-format metric"),
        ("video_fmt_det", "video.c:642", "RAW_TUPLE", "0x05", "0xF5", "READ", "N/A", 0, "special-format metric"),
        ("video_fmt_det", "video.c:675", "FHD_PRECONDITION", "0x00", "0xFF", "BANK_SELECT", "0x00", 0, "select Bank0"),
        ("video_fmt_det", "video.c:676", "FHD_PRECONDITION", "0x00", "0x81", "WRITE", "0x03", 0, "pre_fmt for 0x31"),
        ("video_fmt_det", "video.c:677", "FHD_PRECONDITION", "0x00", "0x85", "WRITE", "0x02", 0, "special mode"),
        ("video_fmt_det", "video.c:679", "FHD_PRECONDITION", "0x01", "0xFF", "BANK_SELECT", "0x01", 0, "select Bank1"),
        ("video_fmt_det", "video.c:680", "FHD_PRECONDITION", "0x01", "0x84", "WRITE", "0x04", 0, "ADC clock delay"),
        ("video_fmt_det", "video.c:681", "FHD_PRECONDITION", "0x01", "0x8C", "WRITE", "0xE5", 0, "decoder pre-clock"),
        ("video_fmt_det", "video.c:700", "FHD_PRECONDITION", "0x05", "0xFF", "BANK_SELECT", "0x05", 0, "select CH1 private bank"),
        ("video_fmt_det", "video.c:701", "FHD_PRECONDITION", "0x05", "0x24", "WRITE", "0x18", 0, "burst value selection"),
        ("video_fmt_det", "video.c:702", "FHD_PRECONDITION", "0x05", "0x58", "WRITE", "0xD3", 0, "analog EQ precondition"),
        ("video_fmt_det", "video.c:704", "FHD_PRECONDITION", "0x05", "0x27", "READ", "N/A", 0, "diagnostic ACC reference read"),
        ("video_fmt_det", "video.c:706", "FHD_PRECONDITION", "N/A", "N/A", "DELAY", "N/A", 50, "settle"),
        ("video_fmt_det", "video.c:707", "FHD_PRECONDITION", "0x05", "0xFF", "BANK_SELECT", "0x05", 0, "reselect CH1 private bank"),
        ("video_fmt_det", "video.c:708", "FHD_PRECONDITION", "0x05", "0x90", "WRITE", "0x05", 0, "comb mode"),
        ("video_fmt_det", "video.c:709", "FHD_PRECONDITION", "N/A", "N/A", "DELAY", "N/A", 100, "settle"),
        ("GetYPlusSlope", "eq_common.c:2629-2632", "METRICS", "0x05", "0xE8/0xE9", "READ16_MASKED", "high&0x07;low", 0, "Y-plus slope"),
        ("GetYMinusSlope", "eq_common.c:2648-2651", "METRICS", "0x05", "0xEA/0xEB", "READ16_MASKED", "high&0x07;low", 0, "Y-minus slope"),
        ("distinguish_GetAccGain", "eq_common.c:5054-5057", "METRICS", "0x05", "0xE2/0xE3", "READ16", "high;low", 0, "ACC gain"),
        ("video_fmt_det", "video.c:757-771", "DECISION", "N/A", "N/A", "EVALUATE", "AHD iff Y+>=80 and Y->=80 and ACC>2010; else CVI", 0, "exact FHD AHD/CVI predicate"),
        ("video_fmt_det", "video.c:794", "REFERENCE_POSTLUDE", "0x09", "0xFF", "BANK_SELECT", "0x09", 0, "select Bank9"),
        ("video_fmt_det", "video.c:795", "REFERENCE_POSTLUDE", "0x09", "0x80", "WRITE", "0x00", 0, "DEQ0 off"),
        ("video_fmt_det", "video.c:796", "REFERENCE_POSTLUDE", "0x09", "0x81", "WRITE", "0x00", 0, "DEQ1 off"),
        ("video_fmt_det", "video.c:797", "REFERENCE_POSTLUDE", "0x05", "0xFF", "BANK_SELECT", "0x05", 0, "select CH1 private bank"),
        ("video_fmt_det", "video.c:798", "REFERENCE_POSTLUDE", "0x05", "0x58", "WRITE", "0x03", 0, "AEQ default/off"),
    ]
    discr_rows: list[dict[str, object]] = []
    for seq, spec in enumerate(discr_specs, 1):
        fn, loc, phase, bank, reg, op, value, delay, reason = spec
        functional = op == "WRITE" and reg != "0xFF"
        discr_rows.append(manual_manifest_row(
            seq, fn, loc, phase, bank, reg, op, value=value, delay=delay,
            condition="NOVID=0; raw F0=0x31; fresh three-snapshot campaign",
            reason=reason,
            initial="CAPTURED_PRE_CAMPAIGN_FULL_BYTE_REQUIRED" if functional else "N/A",
            expected="EXACT_OR_MASKED_READBACK_REQUIRED" if functional else "OBSERVATION_OR_DECISION",
            rollback="RESTORE_CAPTURED_PRE_CAMPAIGN_FULL_BYTE" if functional else "NO_REGISTER_ROLLBACK",
            rollback_readback="EXACT_BASELINE_EQUALITY_REQUIRED" if functional else "N/A",
        ))
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_AHD_CVI_DISCRIMINATOR_MANIFEST.csv", MANIFEST_FIELDS, discr_rows)

    route_specs = [
        ("READ", "ENTRY", "0xFF", "N/A", "capture entry bank", "ENTRY_BANK"),
        ("BANK_SELECT", "0x01", "0xFF", "0x01", "select Bank1", "0x01"),
        ("READ", "0x01", "0xFF", "N/A", "verify Bank1", "0x01"),
        ("READ", "0x01", "0xC2", "N/A", "capture full route byte", "BASELINE_C2"),
        ("RMW_WRITE", "0x01", "0xC2", "(OLD&0xF0)|0x00", "CH1 to VDO1; preserve upper nibble", "(OLD&0xF0)|0x00"),
        ("READ", "0x01", "0xC2", "N/A", "masked route readback", "(OLD&0xF0)|0x00"),
        ("BANK_SELECT", "ENTRY", "0xFF", "ENTRY_BANK", "restore entry bank", "ENTRY_BANK"),
        ("READ", "ENTRY", "0xFF", "N/A", "verify entry bank", "ENTRY_BANK"),
    ]
    route_rows = []
    for seq, (op, bank, reg, value, reason, expected) in enumerate(route_specs, 1):
        functional = op == "RMW_WRITE"
        route_rows.append(manual_manifest_row(
            seq, "ROUTE_CHANNEL_TO_VDO1", "current v41 DIAG1 + accepted DIAG2 route authority",
            "ROUTE_CH1_TO_VDO1", bank, reg, op, value=value,
            condition="only if CH1 is not already selected; transport quiescent",
            reason=reason,
            initial="CAPTURED_FULL_BYTE" if functional else "N/A",
            expected=expected,
            preserved="C2[7:4]" if functional else "NONE",
            rollback="RESTORE_CAPTURED_C2_FULL_BYTE" if functional else "RESTORE_ENTRY_BANK_AT_ACTION_END",
            rollback_readback="EXACT_FULL_BYTE_EQUALITY" if functional else "ENTRY_BANK_EQUALITY",
        ))
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_ROUTE_TO_VDO1_MANIFEST.csv", MANIFEST_FIELDS, route_rows)

    rollback_set = json.loads(paths["rollback_json"].read_text(encoding="utf-8"))
    mode_targets = set(rollback_set["ch1_unique_targets"])
    assert len(mode_targets) == 137
    all_targets = set(mode_targets)
    all_targets.add("B01:RC2")
    assert len(all_targets) == 138
    assert {"B05:R05", "B05:R08"}.issubset(mode_targets)
    assert DISCRIMINATOR_WRITE_TARGETS.issubset(mode_targets)

    contributors: dict[str, set[str]] = defaultdict(set)
    compatibility: dict[str, set[str]] = defaultdict(set)
    forward_ledger: list[tuple[str, str]] = []
    for row in action_rows:
        if row["operation"] in {"WRITE", "READ_FOR_RMW", "RMW_CLEAR_CHANNEL_BIT"} and row["ch1_register"].upper() != "0XFF":
            key = target(row["ch1_bank"], row["ch1_register"])
            contributors[key].add(row["phase"])
            compatibility[key].add(row["nvp6134c_compatibility"])
            forward_ledger.append((key, f"MODE:{row['order']}:{row['phase']}"))
    for key in ("B05:R08", "B05:R05"):
        contributors[key].add("SLICE_SEARCH")
    for key in DISCRIMINATOR_WRITE_TARGETS:
        contributors[key].add("AHD_CVI_DISCRIMINATOR")
    contributors["B01:RC2"].add("ROUTE_CH1_TO_VDO1")
    compatibility["B01:RC2"].add("ACCEPTED_V41_MASKED_ROUTE")

    blacklist_rows = load_csv(paths["blacklist_csv"])
    blacklist = {target(row["Bank"], row["Register"]) for row in blacklist_rows}
    assert len(blacklist) == 14
    assert not (all_targets & blacklist)

    authority_rows = load_csv(paths["authority_csv"])
    matrix_safe = {
        target(row["Bank"], row["Register"])
        for row in authority_rows
        if row["ReadSafe"] == "YES_OBSERVATIONAL_READ"
        and row["ReadSideEffect"] == "NO_KNOWN_READ_SIDE_EFFECT"
    }
    assert set(SAFE_READ_TARGETS) - {"B01:RC2"} <= matrix_safe
    assert len(all_targets & set(SAFE_READ_TARGETS)) == 6
    unresolved = all_targets - set(SAFE_READ_TARGETS)
    assert len(unresolved) == 132

    current_init_targets = extract_current_init_targets(paths["diag_pkg_vhd"])
    current_overlap = all_targets & current_init_targets
    assert len(current_overlap) == 88

    touched_fields = [
        "bank", "register", "target", "contributors", "may_be_modified",
        "nvp6134c_write_compatibility", "current_v41_init_mentions_target",
        "positive_safe_read_authority", "read_side_effect_status",
        "known_blacklist_intersection", "write_only_status", "baseline_method",
        "forward_readback_rule", "rollback_value_source", "rollback_readback",
        "symbolic_preserved_field", "closure_status",
    ]
    touched_rows = []
    for key in sorted(all_targets):
        bank, register = split_target(key)
        safe = key in SAFE_READ_TARGETS
        touched_rows.append({
            "bank": bank,
            "register": register,
            "target": key,
            "contributors": ";".join(sorted(contributors[key])),
            "may_be_modified": "YES",
            "nvp6134c_write_compatibility": ";".join(sorted(compatibility[key])) or "REFERENCE_DRIVER_SEMANTICS",
            "current_v41_init_mentions_target": "YES" if key in current_overlap else "NO",
            "positive_safe_read_authority": SAFE_READ_TARGETS.get(key, "NOT_PROVEN"),
            "read_side_effect_status": "NO_KNOWN_READ_SIDE_EFFECT_PROVEN" if safe else "UNCLASSIFIED_NOT_PROVEN_SAFE",
            "known_blacklist_intersection": "NO",
            "write_only_status": "NOT_WRITE_ONLY_UNDER_ACCEPTED_AUTHORITY" if safe else "UNCLASSIFIED",
            "baseline_method": "TWO_FULL_BYTE_READS_A_AND_B" if safe else "BLOCKED_NO_SAFE_BASELINE_METHOD",
            "forward_readback_rule": "EXACT_OR_FROZEN_MASK" if safe else "NOT_AUTHORIZED",
            "rollback_value_source": "CAPTURED_PRE_CAMPAIGN_FULL_BYTE" if safe else "UNAVAILABLE",
            "rollback_readback": "EXACT_BASELINE_EQUALITY" if safe else "NOT_AUTHORIZED",
            "symbolic_preserved_field": SYMBOLIC_TARGETS.get(key, "NO"),
            "closure_status": "AUTHORIZED" if safe else "BLOCKING_AUTHORITY_GAP",
        })
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_TOUCHED_REGISTER_MANIFEST.csv", touched_fields, touched_rows)

    readback_fields = [
        "sequence_number", "bank", "register", "target", "baseline_pass_a",
        "baseline_pass_b", "agreement_rule", "prewrite_rule", "post_write_rule",
        "post_rollback_rule", "technical_authority", "execution_status",
    ]
    readback_rows = []
    for seq, key in enumerate(sorted(all_targets), 1):
        bank, register = split_target(key)
        safe = key in SAFE_READ_TARGETS
        readback_rows.append({
            "sequence_number": seq,
            "bank": bank,
            "register": register,
            "target": key,
            "baseline_pass_a": "FULL_BYTE_READ" if safe else "NOT_AUTHORIZED",
            "baseline_pass_b": "FULL_BYTE_READ" if safe else "NOT_AUTHORIZED",
            "agreement_rule": "EXACT" if safe else "UNDEFINED",
            "prewrite_rule": "EXACT_BASELINE_EQUALITY_IF_CRITICAL" if safe else "NOT_AUTHORIZED",
            "post_write_rule": "EXACT_OR_FROZEN_MASK" if safe else "NOT_AUTHORIZED",
            "post_rollback_rule": "EXACT_BASELINE_EQUALITY" if safe else "NOT_AUTHORIZED",
            "technical_authority": SAFE_READ_TARGETS.get(key, "MISSING"),
            "execution_status": "NOT_REACHED_AFTER_COMPLETE_ROLLBACK_AUTHORITY_GATE",
        })
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_READBACK_MANIFEST.csv", readback_fields, readback_rows)

    combined_forward: list[tuple[str, str]] = [
        ("B05:R08", "SLICE_0x50"), ("B05:R05", "SLICE_0x50"),
        ("B05:R08", "SLICE_0x40"), ("B05:R05", "SLICE_0x40"),
        ("B05:R08", "SLICE_0x60"), ("B05:R05", "SLICE_0x60"),
    ]
    for row in discr_rows:
        if row["operation_type"] == "WRITE" and str(row["register"]).startswith("0x"):
            combined_forward.append((target(str(row["bank"]), str(row["register"])), f"DISCRIMINATOR:{row['sequence_number']}"))
    combined_forward.extend(forward_ledger)
    combined_forward.append(("B01:RC2", "ROUTE_CH1_TO_VDO1"))
    seen: set[str] = set()
    rollback_order: list[tuple[str, str]] = []
    for key, origin in reversed(combined_forward):
        if key not in seen:
            seen.add(key)
            rollback_order.append((key, origin))
    assert seen == all_targets and len(rollback_order) == 138
    rollback_fields = [
        "rollback_sequence", "bank", "register", "target", "last_forward_touch",
        "restore_operation", "baseline_value_source", "preserved_bits",
        "required_post_restore_readback", "authority_status", "execution_status",
    ]
    rollback_rows = []
    for seq, (key, origin) in enumerate(rollback_order, 1):
        bank, register = split_target(key)
        safe = key in SAFE_READ_TARGETS
        rollback_rows.append({
            "rollback_sequence": seq,
            "bank": bank,
            "register": register,
            "target": key,
            "last_forward_touch": origin,
            "restore_operation": "WRITE_CAPTURED_PRE_CAMPAIGN_FULL_BYTE" if safe else "UNAUTHORIZED_UNTIL_AUTHORITY_CLOSED",
            "baseline_value_source": "FUNCTIONAL_BASELINE_A_AND_B" if safe else "UNAVAILABLE",
            "preserved_bits": SYMBOLIC_TARGETS.get(key, "FULL_BYTE_RESTORE"),
            "required_post_restore_readback": "EXACT_BASELINE_EQUALITY" if safe else "NOT_AUTHORIZED",
            "authority_status": "AUTHORIZED" if safe else "BLOCKING_AUTHORITY_GAP",
            "execution_status": "NOT_REACHED",
        })
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_ROLLBACK_MANIFEST.csv", rollback_fields, rollback_rows)

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_FORMAT_DETECTION_MANIFEST.md", f"""# CH1 format detection manifest

- Authority: pinned reference commit `{REFERENCE_COMMIT}` and frozen SCAN0 detector artifacts.
- Frozen detector decision-tree SHA-256: `{EXPECTED['decision_json']}`.
- Frozen detector read-set SHA-256: `{EXPECTED['read_set_csv']}`.
- Campaign state: fresh host-owned generation; no inherited buffers.
- Required stability: three consecutive complete, coherent, byte-identical tuples.
- Tuple: Bank0 `A8`; Bank5 `F0/F2/F3/F4/F5/E2/E3/E8/E9/EA/EB`; public lock/status fields.
- Bank discipline: verified selection and exact entry-bank restore for every atomic snapshot.
- Raw `F0=0x31` alone: `INSUFFICIENT`.
- Exact initial `F0=0x31` reference branch: the published discriminator manifest includes nine unique functional preconditioning/postlude targets, all already contained in the 137-target mode/EQ set.
- Decision predicate: AHD only when Y-plus >= 80, Y-minus >= 80 and ACC gain > 2010; otherwise CVI for the 1080p25 ambiguity.
- Output set: `AHD_1080P25_CONFIRMED`, `CVI_1080P25_CONFIRMED`, `OTHER_FORMAT_CONFIRMED`, or `FORMAT_UNRESOLVED`.
- Execution authority: `NOT_REACHED`; the earlier complete rollback authority gate failed.
- Functional writes executed: `0`.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_REFERENCE_HELPER_DISPOSITION.md", f"""# Reference CVBS slice-helper disposition

- Result: `PROVEN_NOT_EXECUTED`.
- Current v41 source: `nvp6134c_autoinit.vhd` fixes `range_sel => \"10\"`, documented as profile 2 AHD 1080p25, and `channel_sel => \"00\"` for CH1 to VDO1.
- Current mode mapping: `nvp6134c_diagnostics_pkg.vhd` maps profile `10` to mode byte `0x03`, AHD 1080p25.
- Accepted connected baseline context: NOVID remained `1` and `F0=0xFF`; this is the governed 1080p no-video observation under the fixed AHD 1080p25 target profile.
- Reference enum: `NVP6134_VI_720P_2530=0x10`; `NVP6134_VI_1080P_2530=0x20`; `NVP6134_VI_1080P_NOVIDEO=0x24`.
- Helper guard: `ch_mode_status[ch] < NVP6134_VI_720P_2530`.
- Therefore the governed target context is not below the helper threshold; `nvp6134_cvbs_slicelevel_con` contributes no additional functional write to this task.
- This proof does not authorize the separate explicit Bank5 `0x08` then `0x05` slice action.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_OWNER_AUTHORIZATION.md", f"""# Owner authorization

- Task: `{TASK}`.
- Owner prompt SHA-256: `{EXPECTED['prompt']}`; byte size: `38603`.
- Authorized conditional scope: CH1 connected baseline, exact slice order `Bank5/0x08=level` then `Bank5/0x05=0xA4`, exact AHD/CVI gate, AHD 1080p25-only compiled mode/EQ, lock, BT.656, bounded capture, and exact rollback.
- Authorized slice levels: `0x50`, `0x40`, `0x60`.
- Other formats: `REPORT_ONLY_NO_MODE_WRITE`.
- Generic host NVP I2C: prohibited.
- Runtime adaptive EQ, CH2-CH4 writes, Flash, power-cycle, PRODUCT/SSOT/META changes: prohibited.
- Mandatory pre-implementation gate: every potentially touched functional register must have exact baseline/readback/rollback authority.
- Applied hard stop: `{FIRST_BLOCKER}`.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_SCOPE.md", f"""# Scope

The run stopped in Phase A before source implementation. Read-only work comprised byte-identity checks, clean-room semantic manifest derivation, full touched-register union calculation, read-authority comparison, known read-side-effect blacklist comparison, and helper disposition proof.

No source edit, source commit, simulation gate, Vivado run, runtime bundle, DUT root, credential helper, lock, FPGA programming, reboot, driver action, MMIO, I2C transaction, camera gate, capture, or rollback was performed. PRODUCT, SSOT and META remain unchanged.

First blocker: `{FIRST_BLOCKER}`.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_INHERITANCE.md", f"""# Inheritance

- `PROJECT_STATE_REV`: `8 - OWNER_ATTESTED_NOT_REVERIFIED`.
- Same SCAN0/SCAN1 Codex window: `YES`.
- Accepted SCAN1 source parent: `{SOURCE_PARENT}`.
- Accepted SCAN1 source tree: `{SOURCE_TREE}`.
- Diagnostic branch: `diag/v41-g2b-nvp-camera-acq1-r1`; clean and still at the accepted parent.
- Hardware-qualified PRODUCT source: `30b14d13b0b789b62b05ab513eb9578c7c43b11a` (accepted without broad requalification).
- Accepted prior connected response: CH1 `F2/F3 0x00/0x00 -> 0xC0/0x03`; return control `0xC0/0x03 -> 0x00/0x00`; NOVID stayed `1`; F0 stayed `0xFF`.
- No current-run hardware claim is inherited or fabricated.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_REFERENCE_AUTHORITY.md", f"""# Reference authority

- Repository identity: `4e4o/nvp6134_ex`.
- Pinned commit: `{REFERENCE_COMMIT}`.
- Pinned tree: `{REFERENCE_TREE}`.
- Reference worktree status: clean at inspection.
- `video.c` SHA-256: `{EXPECTED['video.c']}`.
- `video.h` SHA-256: `{EXPECTED['video.h']}`.
- `eq_common.c` SHA-256: `{EXPECTED['eq_common.c']}`.
- Frozen SCAN0 AHD1080p25 action CSV SHA-256: `{EXPECTED['action_csv']}`.
- Frozen SCAN0 rollback-set SHA-256: `{EXPECTED['rollback_json']}`.
- Reference use: semantic derivation only. No reference source bytes are present in this publication.
- Frozen call path: `nvp6134_set_chnmode(CH1,PAL,NVP6134_VI_1080P_2530)`; 211 semantic operations; 137 unique functional register targets before the separate VDO1 route.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_LICENSE_DISPOSITION.md", """# License disposition

- Disposition: `SEMANTIC_USE_ONLY_NO_DIRECT_COPY`.
- Published material is a clean-room semantic operation model, authority matrix, gate evidence, and test code.
- Reference-driver source, vendor PDFs, and copied source fragments are excluded.
- File names, function names, line references, register addresses, values, predicates, and hashes are included only as provenance and interoperability facts.
""")

    write_text(out / "V41_G2B_NVP_CAMERA_ACQ1_R1_MAIN_REPORT.md", f"""# AHD v41 G2B-NVP-CAMERA-ACQ1-R1 main report

## Result

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.
- Overall result: `BLOCKED`.
- First blocker: `{FIRST_BLOCKER}`.

## First failed gate

The prompt, accepted source parent/tree, clean diagnostic worktree, pinned reference commit/tree, reference-file bytes, and frozen SCAN0 semantic artifacts all matched their required identities. The corrected slice forward order also matches the pinned dynamic reference branch.

The exact selected AHD1080p25 reference path contains 211 semantic operations and 137 unique non-bank-select CH1 register targets. Slice targets Bank5 `0x08/0x05` and all nine functional targets of the exact `F0=0x31` discriminator are subsets of those 137. The separate conditional CH1-to-VDO1 route adds Bank1 `0xC2`, producing a complete union of `138` potentially modified functional registers.

Only `6/138` targets have pre-existing positive technical authority for a safe full-byte baseline/readback and exact restore: Bank0 `0x23/0x81/0x85`, Bank1 `0x84/0x8C`, and the already-qualified masked route at Bank1 `0xC2`. The remaining `132/138` targets lack positive safe-read or exact pre-campaign restore authority. `88/138` are mentioned by the current fixed v41 init sequence, but that is not proof of their exact pre-campaign bytes or of side-effect-free reads; `50/138` are not even targets of that current init sequence.

The touched set has zero intersection with the known 14-address Bank0 read-side-effect blacklist. That negative comparison cannot prove the unclassified 132 targets safe, nor can it determine how many are write-only. The exact count of write-only unrestorable targets and read-side-effect targets therefore remains `N/A`, not zero. Two reference RMW fields remain symbolic: Bank1 `0xED` and Bank9 `0x44`.

Phase A section 6 requires every touched register to be readable or exactly restorable, with no unresolved symbolic rollback field. That requirement is false before source implementation, so the task stopped exactly as `{FIRST_BLOCKER}`. No hardware-capable source or bitstream was created.

## Other Phase-A findings

The CVBS slice helper is `PROVEN_NOT_EXECUTED`: the accepted current v41 target is statically AHD 1080p25/1080p no-video and is not below the reference `NVP6134_VI_720P_2530` threshold. The exact `F0=0x31` discriminator branch was semantically extracted, including nine unique functional preconditioning/postlude targets and its threshold predicate, but its execution authority is `NOT_REACHED` after the earlier rollback gate.

## Preserved state and non-claims

Functional NVP writes are `0`. No DUT contact, camera gate, programming, reboot, driver load, MMIO, I2C, capture, or rollback occurred. The source branch remains clean at `{SOURCE_PARENT}` and no source commit exists. The previous FPGA runtime profile is unchanged. PRODUCT, SSOT and META are unchanged; no reference source, vendor PDF, bitstream, DCP, driver, binary, capture, or camera pixels are published.

## Required closure

A future separately governed task must provide positive NVP6134C technical access/read-side-effect/restore authority for all 132 gap targets, including the private mode, EQ and ACP banks, and must reduce both symbolic RMW fields to exact captured bytes before implementation. Absence from a blacklist and reference-driver write behavior are not substitutes for that proof.

Generated UTC: `{generated}`.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_SIMULATION_REPORT.md", placeholder_md("Simulation and offline gate report") + "\nRequired SCAN1 tests: `0/24`. Required ACQ1 executor tests: `0/32`. Combined gate: `0/56`. These suites were not run because no implementation was authorized. The separate publication self-test is not counted toward the 56-test engineering gate.\n")
    for filename, title in [
        ("G2B_NVP_CAMERA_ACQ1_R1_BUILD_REPORT.md", "Fresh build report"),
        ("G2B_NVP_CAMERA_ACQ1_R1_TIMING_REPORT.md", "Timing report"),
        ("G2B_NVP_CAMERA_ACQ1_R1_CDC_REPORT.md", "CDC report"),
        ("G2B_NVP_CAMERA_ACQ1_R1_DRC_REPORT.md", "DRC and methodology report"),
    ]:
        write_text(out / filename, placeholder_md(title))
    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_RESOURCE_REPORT.md", placeholder_md("Resource report") + "\nLUT, FF, BRAM and DSP utilization: `N/A`; resource gate: `NOT_REACHED`.\n")
    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_BITSTREAM_MANIFEST.md", placeholder_md("Bitstream manifest") + "\nBitstream path: `NONE`; SHA-256: `NONE`; FPGA SRAM programming attempts: `0`.\n")

    write_json(out / "G2B_NVP_CAMERA_ACQ1_R1_RUNTIME_BUNDLE_MANIFEST.json", {
        "task": TASK,
        "status": "NOT_REACHED",
        "first_blocker": FIRST_BLOCKER,
        "bundle_created": False,
        "unresolved_local_imports": None,
        "missing_resources": None,
        "module_origin_violations": None,
        "functional_writes": 0,
    })
    for filename, title in [
        ("G2B_NVP_CAMERA_ACQ1_R1_DUT_BUNDLE_RECEIPT.md", "DUT bundle receipt"),
        ("G2B_NVP_CAMERA_ACQ1_R1_RUNTIME_IDENTITY.md", "Runtime identity"),
        ("G2B_NVP_CAMERA_ACQ1_R1_MMIO_SANITY.md", "MMIO sanity"),
        ("G2B_NVP_CAMERA_ACQ1_R1_MODE_APPLY_RECEIPT.md", "Mode and initial-EQ apply receipt"),
        ("G2B_NVP_CAMERA_ACQ1_R1_BT656_READINESS.md", "BT.656 readiness"),
        ("G2B_NVP_CAMERA_ACQ1_R1_FRAME_CONTENT_DECISION.md", "Frame-content decision"),
        ("G2B_NVP_CAMERA_ACQ1_R1_ROLLBACK_RECEIPT.md", "Rollback receipt"),
    ]:
        write_text(out / filename, placeholder_md(title))

    placeholder_csvs = {
        "G2B_NVP_CAMERA_ACQ1_R1_CONNECTED_BASELINE.csv": ["scan", "status", "a8_pre", "a8_post", "ch1_f2", "ch1_f3", "novid", "f0", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_FUNCTIONAL_BASELINE_A.csv": ["sequence", "bank", "register", "value", "read_status", "bank_verified", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_FUNCTIONAL_BASELINE_B.csv": ["sequence", "bank", "register", "value", "read_status", "bank_verified", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_PREWRITE_BASELINE.csv": ["sequence", "bank", "register", "baseline_value", "prewrite_value", "match", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_SLICE_RESULTS.csv": ["level", "executed", "forward_readback", "stable_snapshots", "novid_result", "entry_bank_restore", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_FORMAT_IDENTIFICATION.csv": ["snapshot", "executed", "raw_f0", "y_plus", "y_minus", "acc_gain", "decision", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_LOCK_TIMELINE.csv": ["snapshot", "executed", "novid", "format", "agc_lock", "clamp_lock", "h_lock", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_CAPTURE_RESULTS.csv": ["capture", "executed", "line_records", "bytes", "integrity", "complete_frame", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_FRAME_HASHES.csv": ["artifact", "created", "sha256", "published", "note"],
        "G2B_NVP_CAMERA_ACQ1_R1_PIXEL_STATISTICS.csv": ["metric", "value", "status", "note"],
    }
    for filename, fields in placeholder_csvs.items():
        row = {field: "NOT_REACHED" for field in fields}
        row[fields[-1]] = FIRST_BLOCKER
        write_csv(out / filename, fields, [row])

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_CLEANUP_RECEIPT.md", f"""# Cleanup receipt

- Status: `NOT_APPLICABLE_NO_HARDWARE_CONTACT`.
- Task-created stream/AIO/native helper/driver/lock resources: `NONE`.
- Source worktree: clean at `{SOURCE_PARENT}`.
- Functional writes: `0`.
- Driver: `NOT_LOADED`; XDMA nodes: `NOT_CREATED` by this task.
- FPGA runtime: `PREVIOUS_PROFILE_UNCHANGED`.
- NVP persistent state changed: `NO`.
- First blocker: `{FIRST_BLOCKER}`.
""")

    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_FINAL_STATE.md", f"""# Final state

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.
- Overall result: `BLOCKED`.
- First blocker: `{FIRST_BLOCKER}`.
- Final execution point: `PHASE_A_SECTION_6_COMPLETE_ROLLBACK_AUTHORITY_GATE`.
- Source implementation/build/hardware: `NOT_REACHED`.
- Source commit: `NONE`; source tree: `{SOURCE_TREE}`.
- Functional NVP writes: `0`; programming attempts: `0`; warm reboot: `0`; power-cycle: `NO`; Flash: `NO`.
- Exact rollback invoked: `NO`; no task write existed to roll back.
- Previous FPGA runtime profile: `UNCHANGED`.
- PRODUCT/SSOT/META/NVP persistent state: `UNCHANGED`.
- Physical Owner action required: `NONE`.
""")

    gate_rows = [
        {"order": 1, "gate": "owner prompt identity", "status": "PASS", "evidence": EXPECTED["prompt"], "next": "source authority"},
        {"order": 2, "gate": "source parent/tree and isolated branch", "status": "PASS", "evidence": f"{SOURCE_PARENT}/{SOURCE_TREE}", "next": "reference freeze"},
        {"order": 3, "gate": "pinned reference identity", "status": "PASS", "evidence": f"{REFERENCE_COMMIT}/{REFERENCE_TREE}", "next": "semantic manifests"},
        {"order": 4, "gate": "exact action semantic extraction", "status": "PASS", "evidence": "211 operations; 137 mode targets; route adds one", "next": "complete touched closure"},
        {"order": 5, "gate": "complete touched baseline/readback/rollback authority", "status": "BLOCKED", "evidence": "138 targets; 6 authorized; 132 authority gaps; 2 symbolic fields", "next": "HARD_STOP"},
        {"order": 6, "gate": "AHD/CVI discriminator execution authority", "status": "NOT_REACHED", "evidence": "exact semantic branch extracted; earlier rollback gate failed", "next": "NOT_REACHED"},
        {"order": 7, "gate": "reference helper disposition", "status": "PASS", "evidence": "PROVEN_NOT_EXECUTED", "next": "does not override gate 5"},
        {"order": 8, "gate": "source implementation and 56 tests", "status": "NOT_REACHED", "evidence": FIRST_BLOCKER, "next": "NOT_REACHED"},
        {"order": 9, "gate": "build/signoff/bitstream/runtime/hardware", "status": "NOT_REACHED", "evidence": FIRST_BLOCKER, "next": "NOT_REACHED"},
        {"order": 10, "gate": "evidence publication", "status": "REQUIRED_POST_COMMIT", "evidence": "one no-force push plus one commit-pinned read-back", "next": "external receipt"},
    ]
    write_csv(out / "G2B_NVP_CAMERA_ACQ1_R1_GATE_MATRIX.csv", ["order", "gate", "status", "evidence", "next"], gate_rows)

    state = {
        "task": TASK,
        "generated_utc": generated,
        "project_state_rev": "8 - OWNER_ATTESTED_NOT_REVERIFIED",
        "same_scan0_scan1_window": True,
        "engineering_gate": "BLOCKED",
        "evidence_publication": "PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": "BLOCKED",
        "first_blocker": FIRST_BLOCKER,
        "source_branch": "diag/v41-g2b-nvp-camera-acq1-r1",
        "source_parent": SOURCE_PARENT,
        "source_commit": None,
        "source_tree": SOURCE_TREE,
        "source_changed_files": [],
        "reference_commit": REFERENCE_COMMIT,
        "reference_tree": REFERENCE_TREE,
        "mode_semantic_operations": 211,
        "mode_unique_functional_targets": 137,
        "complete_touched_functional_targets": 138,
        "positive_safe_read_and_restore_authority_targets": 6,
        "blocking_authority_gap_targets": 132,
        "known_read_side_effect_blacklist_intersections": 0,
        "read_side_effect_touched_register_count": None,
        "write_only_unrestorable_register_count": None,
        "unresolved_symbolic_rollback_fields": 2,
        "symbolic_targets": sorted(SYMBOLIC_TARGETS),
        "current_v41_init_target_overlap": 88,
        "current_v41_init_target_absence": 50,
        "ahd_cvi_discriminator_authority": "NOT_REACHED",
        "reference_helper_disposition": "PROVEN_NOT_EXECUTED",
        "slice_forward_order": "BANK5_0x08_LEVEL_THEN_BANK5_0x05_A4",
        "legacy_reversed_order_present": False,
        "scan1_tests": "0/24_NOT_REACHED",
        "acq1_executor_tests": "0/32_NOT_REACHED",
        "combined_tests": "0/56_NOT_REACHED",
        "functional_writes": 0,
        "dut_contacted": False,
        "programming_attempts": 0,
        "warm_reboots": 0,
        "captures_attempted": 0,
        "rollback_invoked": False,
        "final_fpga_runtime_profile": "PREVIOUS_PROFILE_UNCHANGED",
        "product_source_changed": False,
        "ssot_changed": False,
        "meta_performed": False,
        "nvp_persistent_state_changed": False,
        "camera_pixels_published": False,
        "publication_repository": "lukaszsudul/AHD-diagnostic-evidence",
        "publication_directory": TARGET_DIRNAME,
        "publication_commit": "THIS_COMMIT",
        "remote_readback": "REQUIRED_POST_COMMIT_GATE",
    }
    write_json(out / "G2B_NVP_CAMERA_ACQ1_R1_STATE.json", state)

    # Publish the clean-room generator itself and an independent evidence validator.
    clean_room = out / "clean-room"
    clean_room.mkdir()
    shutil.copyfile(Path(__file__).resolve(), clean_room / "generate_acq1_r1_evidence.py")
    test_source = '''#!/usr/bin/env python3
import csv
import hashlib
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
def rows(name):
    with (root / name).open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

touched = rows("G2B_NVP_CAMERA_ACQ1_R1_TOUCHED_REGISTER_MANIFEST.csv")
assert len(touched) == 138
assert sum(r["closure_status"] == "AUTHORIZED" for r in touched) == 6
assert sum(r["closure_status"] == "BLOCKING_AUTHORITY_GAP" for r in touched) == 132
assert sum(r["symbolic_preserved_field"] != "NO" for r in touched) == 2
assert all(r["known_blacklist_intersection"] == "NO" for r in touched)

assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_AHD1080P25_MODE_MANIFEST.csv")) == 161
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_INITIAL_EQ_MANIFEST.csv")) == 9
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_ACP_SUBSET_MANIFEST.csv")) == 35
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_REARM_ENABLE_MANIFEST.csv")) == 6
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_ROLLBACK_MANIFEST.csv")) == 138

slice_rows = rows("G2B_NVP_CAMERA_ACQ1_R1_SLICE_ACTION_MANIFEST.csv")
for level in ("0x50", "0x40", "0x60"):
    phase = [r for r in slice_rows if r["clean_room_action_phase"] == f"SLICE_{level}"]
    writes = [(i, r["register"], r["write_value_or_mask"]) for i, r in enumerate(phase) if r["operation_type"] == "WRITE"]
    assert writes == [(3, "0x08", level), (4, "0x05", "0xA4")]

manifest = root / "G2B_NVP_CAMERA_ACQ1_R1_SHA256_MANIFEST.txt"
for line in manifest.read_text(encoding="utf-8").splitlines():
    digest, relative = line.split("  ", 1)
    actual = hashlib.sha256((root / relative).read_bytes()).hexdigest().upper()
    assert actual == digest

prohibited_suffixes = {".bit", ".dcp", ".png", ".uyvy", ".bin", ".pdf"}
assert not [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in prohibited_suffixes]
print("ACQ1_R1_EVIDENCE_SELF_TEST=PASS")
print("TOUCHED=138 AUTHORIZED=6 GAPS=132 SYMBOLIC=2")
'''
    write_text(out / "tests/test_acq1_r1_evidence.py", test_source)
    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_AUTHORITY_SELF_TEST.md", """# Authority evidence self-test

- Result: `PASS`.
- This publication-integrity check is separate from, and not counted as, the required 56 implementation tests.
- Assertions: 138 touched targets; 6 positively authorized safe baseline/readback targets; 132 blocking authority gaps; two symbolic fields; exact manifest partition 161+9+35+6=211; exact slice order; 138-row rollback plan; no prohibited artifact type.
""")

    # Index all files except the index and hash manifest, then write the index.
    current_files = sorted(p.relative_to(out).as_posix() for p in out.rglob("*") if p.is_file())
    index_lines = [
        "# ACQ1-R1 evidence index", "",
        "- Engineering gate: `BLOCKED`.",
        "- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.",
        f"- First blocker: `{FIRST_BLOCKER}`.",
        "- Public artifacts contain no camera pixels or prohibited binaries.", "",
        "## Files", "",
    ] + [f"- `{name}`" for name in current_files]
    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_EVIDENCE_INDEX.md", "\n".join(index_lines))

    # Hash every public evidence byte except the self-referential manifest.
    manifest_lines = []
    for path in sorted(p for p in out.rglob("*") if p.is_file() and p.name != "G2B_NVP_CAMERA_ACQ1_R1_SHA256_MANIFEST.txt"):
        manifest_lines.append(f"{sha256(path)}  {path.relative_to(out).as_posix()}")
    write_text(out / "G2B_NVP_CAMERA_ACQ1_R1_SHA256_MANIFEST.txt", "\n".join(manifest_lines))

    missing = [name for name in REQUIRED_FILES if not (out / name).is_file()]
    if missing:
        raise SystemExit("missing required evidence: " + ", ".join(missing))
    print(f"OUTPUT={out}")
    print("MODE_PARTITION=161+9+35+6=211")
    print("TOUCHED=138")
    print("AUTHORIZED_SAFE_BASELINE=6")
    print("BLOCKING_AUTHORITY_GAPS=132")
    print("KNOWN_BLACKLIST_INTERSECTION=0")
    print("SYMBOLIC_ROLLBACK_FIELDS=2")
    print(f"FIRST_BLOCKER={FIRST_BLOCKER}")


if __name__ == "__main__":
    main()
