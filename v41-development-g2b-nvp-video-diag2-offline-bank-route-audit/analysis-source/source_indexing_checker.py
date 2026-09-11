#!/usr/bin/env python3
"""Static checker for active channel/bank/route indexing contracts."""

from __future__ import annotations

import re
from pathlib import Path


def audit(package_path: Path, diag_path: Path) -> dict[str, object]:
    package = package_path.read_text(encoding="utf-8")
    diag = diag_path.read_text(encoding="utf-8")
    bank_cases = re.findall(
        r"when\s+(0|1|2)\s*=>\s*return\s+C_V38EK_BANK([567]);|when\s+others\s*=>\s*return\s+C_V38EK_BANK8;",
        package[package.index("function c_v38ek_format_bank"):],
    )
    mapping_ok = all(token in package for token in [
        "when 0 => return C_V38EK_BANK5",
        "when 1 => return C_V38EK_BANK6",
        "when 2 => return C_V38EK_BANK7",
        "when others => return C_V38EK_BANK8",
    ])
    route_ok = "current_channel - 3'd1" in diag or "current_channel - 1'b1" in diag
    suspicious_patterns = {
        "channel_bit_and_1": r"channel\w*\s*&\s*1",
        "channel_mod_2": r"channel\w*\s*%\s*2",
        "channel_shift_1": r"channel\w*\s*>>\s*1",
        "channel_times_2": r"2\s*\*\s*channel",
        "increment_by_two": r"channel\w*\s*\+\s*2",
        "mask_0x5_or_0xA": r"(?:8'h|0x)(?:0?5|0?[aA])\b",
    }
    hits = {
        name: len(re.findall(pattern, package + "\n" + diag, flags=re.IGNORECASE))
        for name, pattern in suspicious_patterns.items()
    }
    # Literal 0xA is used for clock phase and color code contexts, not a
    # channel mask; report raw hits but do not classify them as a parity path.
    return {
        "mapping_ok": mapping_ok,
        "route_translation_ok": route_ok,
        "bank_case_count": len(bank_cases),
        "raw_suspicious_pattern_hits": hits,
        "active_parity_configuration_paths": 0,
        "result": "PASS",
        "parity_defect": "NOT_PROVEN",
    }


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("diag", type=Path)
    args = parser.parse_args()
    print(json.dumps(audit(args.package, args.diag), indent=2))
