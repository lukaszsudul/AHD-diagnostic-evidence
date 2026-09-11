#!/usr/bin/env python3
"""Parse the active NVP6134C initialization tables without executing HDL.

The parser is intentionally narrow: it accepts the exact `when N => ...
return x"HHHHHH"` form used by nvp6134c_diagnostics_pkg.vhd.  Dynamic overlay
values are resolved from the frozen R3 generics (1080p25, phase A, CH1,
AUTO=0) by :func:`r3_overlay_ops`.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any


MAREK_RE = re.compile(
    r"when\s+(?P<slot>\d+)\s*=>\s*if\s+stage_enabled\(stage,\s*"
    r"(?P<minimum>\d+)\)\s+then\s+return\s+x\"(?P<word>[0-9A-Fa-f]{6})\""
)


def decode_word(word: str) -> dict[str, Any]:
    word = word.upper()
    bank = int(word[0:2], 16)
    address = int(word[2:4], 16)
    data = int(word[4:6], 16)
    if bank == 0xFD:
        operation = "NOP"
    elif bank == 0xFE:
        operation = "DELAY"
    else:
        operation = "WRITE"
    return {
        "word": word,
        "bank": bank,
        "address": address,
        "data": data,
        "operation": operation,
    }


def parse_marek_ops(path: Path, stage: int = 2) -> list[dict[str, Any]]:
    text = path.read_text(encoding="utf-8")
    begin = text.index("function c_v38ek_marek_op_for_slot")
    end = text.index("function c_v38ek_overlay_op_for_slot")
    body = text[begin:end]
    first_line = text[:begin].count("\n") + 1
    operations: list[dict[str, Any]] = []
    for match in MAREK_RE.finditer(body):
        minimum = int(match.group("minimum"))
        if minimum > stage:
            continue
        decoded = decode_word(match.group("word"))
        decoded.update(
            {
                "slot": int(match.group("slot")),
                "minimum_stage": minimum,
                "source_line": first_line + body[: match.start()].count("\n"),
                "source_symbol": "c_v38ek_marek_op_for_slot",
            }
        )
        operations.append(decoded)
    return operations


def r3_overlay_ops() -> list[dict[str, Any]]:
    """Return overlay slots 0..65 for the frozen R3 autoinit generics.

    profile="10" -> AHD1080p25, phase=A, channel=CH1, AUTO=0.
    Source lines are the defining case-arm lines in the R3 package.
    """

    words = [
        "00FF00", "00800F", "00B800", "000000", "000100", "000200",
        "000300", "000800", "000900", "000A00", "000B00", "008103",
        "008203", "008303", "008403", "008500", "008600", "008700",
        "008800", "007888", "007988", "007A11", "007B11", "01FF01",
        "018400", "018501", "018602", "018703", "018C40", "018D41",
        "018E42", "018F43", "01970F", "019800", "01C200", "01C300",
        "01C400", "01C500", "01C800", "01C900", "01CA22", "01CB00",
        "01CD4A", "01CE46", "09FF09", "094000", "094400", "0950AB",
        "09517D", "0952C3", "095352", "0954AB", "09557D", "0956C3",
        "095752", "0958AB", "09597D", "095AC3", "095B52", "095CAB",
        "095D7D", "095EC3", "095F52", "00FF00", "00B800", "00FF00",
    ]
    if len(words) != 66:
        raise AssertionError("R3 overlay must contain exactly 66 slots")
    result: list[dict[str, Any]] = []
    for slot, word in enumerate(words):
        decoded = decode_word(word)
        decoded.update(
            {
                "slot": 148 + slot,
                "overlay_slot": slot,
                "minimum_stage": 0,
                "source_line": 393 + slot,
                "source_symbol": "c_v38ek_overlay_op_for_slot",
            }
        )
        result.append(decoded)
    # Case arms 23..65 are shifted by comments/blank lines in the source.
    explicit_lines = {
        **{slot: 393 + slot for slot in range(0, 23)},
        **{slot: 418 + (slot - 23) for slot in range(23, 44)},
        **{slot: 441 + (slot - 44) for slot in range(44, 63)},
        63: 462,
        64: 463,
        65: 464,
    }
    for row in result:
        row["source_line"] = explicit_lines[row["overlay_slot"]]
    return result


def load_r3_logical_table(package_path: Path) -> list[dict[str, Any]]:
    marek = parse_marek_ops(package_path, stage=2)
    overlay = r3_overlay_ops()
    operations = marek + overlay
    slots = [row["slot"] for row in operations]
    if slots != sorted(slots) or len(slots) != len(set(slots)):
        raise AssertionError("active logical slots are not unique and ordered")
    return operations


def private_bank5_operations(package_path: Path) -> list[dict[str, Any]]:
    return [
        row
        for row in parse_marek_ops(package_path, stage=2)
        if row["operation"] == "WRITE" and row["bank"] == 0x05
    ]


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    args = parser.parse_args()
    print(json.dumps(load_r3_logical_table(args.package), indent=2))
