#!/usr/bin/env python3
"""Generate the frozen SCAN1 SystemVerilog manifest package.

The input is the byte-exact SCAN0 manifest copied into this diagnostic branch.
Generation fails closed on any identity, count, ordering, grouping, or blacklist
drift.  No reference-driver source is consumed.
"""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESOURCE_ROOT = ROOT / "host" / "scan1" / "resources"
CSV_PATH = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.csv"
JSON_PATH = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.json"
BLACKLIST_PATH = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_PROHIBITED_READS.csv"
OUTPUT_PATH = ROOT / "rtl" / "g2b" / "g2b_nvp_camera_scan1_manifest_pkg.sv"

EXPECTED_CSV_SHA256 = "C7211D562F7B932CFF023331E34A0D3507A9904B73A85EC357FEF19B7136626C"
EXPECTED_JSON_SHA256 = "69C6C3518A737C33E5DBC654D20616D5FEC4B9A828EA5CE52061001D564112B5"
EXPECTED_BLACKLIST_SHA256 = "6C1F770CDF5B184E4E80E9C8DF8DF3696E2BA595121844A8F16682937F3B6440"
EXPECTED_SEMANTIC_SHA256 = "2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def hex8(value: str) -> int:
    result = int(value, 16)
    require(0 <= result <= 0xFF, f"8-bit value out of range: {value}")
    return result


def case_function(name: str, width: int, index_width: int, values: list[int]) -> list[str]:
    lines = [
        f"  function automatic logic [{width - 1}:0] {name}(input logic [{index_width - 1}:0] index);",
        "    begin",
        "      case (index)",
    ]
    digits = (width + 3) // 4
    for index, value in enumerate(values):
        lines.append(
            f"        {index_width}'d{index}: {name} = {width}'h{value:0{digits}X};"
        )
    lines.extend(
        [
            f"        default: {name} = {width}'h{'0' * digits};",
            "      endcase",
            "    end",
            "  endfunction",
            "",
        ]
    )
    return lines


def main() -> None:
    expected_hashes = (
        (CSV_PATH, EXPECTED_CSV_SHA256),
        (JSON_PATH, EXPECTED_JSON_SHA256),
        (BLACKLIST_PATH, EXPECTED_BLACKLIST_SHA256),
    )
    for path, expected in expected_hashes:
        require(path.is_file(), f"missing frozen authority: {path}")
        require(sha256(path) == expected, f"frozen authority SHA-256 mismatch: {path}")

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    with CSV_PATH.open(newline="", encoding="utf-8-sig") as handle:
        entries = list(csv.DictReader(handle))
    with BLACKLIST_PATH.open(newline="", encoding="utf-8-sig") as handle:
        blacklist = list(csv.DictReader(handle))

    require(data["entry_count"] == 82 and len(entries) == 82, "entry count must be 82")
    require(data["bank_groups"] == [
        "G0-PRE", "G0-ID", "G0-LOCK", "G0-CH", "G1",
        "G2", "G3", "G4", "G5", "G0-POST",
    ], "bank group identity/order mismatch")
    require(data["i2c_hz"] == 25_000, "I2C frequency mismatch")
    require(data["mode"] == "READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT", "mode mismatch")
    require(data["manifest_sha256"].upper() == EXPECTED_SEMANTIC_SHA256, "semantic digest mismatch")
    require(data["a8_pre_post"] is True, "A8 bookends missing")
    require(data["entry_bank_save_restore"] is True, "entry-bank restore missing")
    require(data["bank_select_readback"] is True, "bank readback missing")

    for index, (csv_entry, json_entry) in enumerate(zip(entries, data["entries"])):
        require(int(csv_entry["EntryIndex"]) == index, f"CSV index mismatch at {index}")
        require(int(json_entry["EntryIndex"]) == index, f"JSON index mismatch at {index}")
        for key in ("Group", "Bank", "Register", "ChannelScope", "AuthorityClass",
                    "InterpretationUnresolved", "Operation"):
            require(csv_entry[key] == str(json_entry[key]), f"CSV/JSON mismatch {index}:{key}")
        require(csv_entry["Operation"] == "READ_ONLY", f"non-read operation at {index}")

    prohibited = {(hex8(row["Bank"]), hex8(row["Register"])) for row in blacklist}
    require(len(blacklist) == 14 and len(prohibited) == 14, "prohibited-read count must be 14")
    active = {(hex8(row["Bank"]), hex8(row["Register"])) for row in entries}
    require(not (active & prohibited), "active manifest intersects prohibited reads")

    unresolved = [row["InterpretationUnresolved"] == "YES" for row in entries]
    require(sum(unresolved) == 40, "RAW_SEMANTICS_PARTIAL count must be 40")
    require(
        entries[0]["Group"] == "G0-PRE" and entries[0]["Bank"] == "0x00"
        and entries[0]["Register"] == "0xA8",
        "A8_PRE identity mismatch",
    )
    require(
        entries[-1]["Group"] == "G0-POST" and entries[-1]["Bank"] == "0x00"
        and entries[-1]["Register"] == "0xA8",
        "A8_POST identity mismatch",
    )

    group_names = data["bank_groups"]
    group_start: list[int] = []
    group_count: list[int] = []
    group_bank: list[int] = []
    for group in group_names:
        positions = [index for index, row in enumerate(entries) if row["Group"] == group]
        require(positions, f"empty group: {group}")
        require(positions == list(range(positions[0], positions[-1] + 1)), f"non-contiguous group: {group}")
        banks = {hex8(entries[index]["Bank"]) for index in positions}
        require(len(banks) == 1, f"multi-bank group: {group}")
        group_start.append(positions[0])
        group_count.append(len(positions))
        group_bank.append(next(iter(banks)))
    require(1 + sum(2 + count for count in group_count) + 2 == 105,
            "clean transaction count must be 105")

    banks = [hex8(row["Bank"]) for row in entries]
    registers = [hex8(row["Register"]) for row in entries]
    digest_words = [int(EXPECTED_SEMANTIC_SHA256[i:i + 8], 16) for i in range(0, 64, 8)]

    lines = [
        "`timescale 1ns/1ps",
        "",
        "// Generated only from the byte-exact frozen SCAN0 manifest.",
        f"// CSV_SHA256={EXPECTED_CSV_SHA256}",
        f"// JSON_SHA256={EXPECTED_JSON_SHA256}",
        f"// SEMANTIC_MANIFEST_SHA256={EXPECTED_SEMANTIC_SHA256}",
        "package g2b_nvp_camera_scan1_manifest_pkg;",
        "  localparam int unsigned SCAN1_ENTRY_COUNT = 82;",
        "  localparam int unsigned SCAN1_GROUP_COUNT = 10;",
        "  localparam int unsigned SCAN1_CLEAN_TRANSACTION_COUNT = 105;",
        "  localparam int unsigned SCAN1_RAW_SEMANTICS_PARTIAL_COUNT = 40;",
        "  localparam logic [31:0] SCAN1_MAGIC = 32'h4E565343;",
        "  localparam logic [31:0] SCAN1_VERSION = 32'h00010001;",
        "  localparam logic [31:0] SCAN1_CAPABILITIES = 32'h0000000F;",
        "",
    ]
    lines += case_function("scan1_entry_bank", 8, 7, banks)
    lines += case_function("scan1_entry_register", 8, 7, registers)
    lines += case_function("scan1_entry_raw_semantics_partial", 1, 7, [int(v) for v in unresolved])
    lines += case_function("scan1_group_bank", 8, 4, group_bank)
    lines += case_function("scan1_group_start", 7, 4, group_start)
    lines += case_function("scan1_group_count", 7, 4, group_count)
    lines += case_function("scan1_manifest_digest_word", 32, 3, digest_words)
    lines.extend(["endpackage", ""])
    OUTPUT_PATH.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"PASS SCAN1_MANIFEST_PACKAGE_GENERATED entries={len(entries)} groups={len(group_names)} transactions=105")


if __name__ == "__main__":
    main()
