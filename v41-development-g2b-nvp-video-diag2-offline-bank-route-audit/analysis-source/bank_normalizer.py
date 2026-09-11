#!/usr/bin/env python3
"""Normalize the R3 private-bank writes into CH1..CH4 relative views."""

from __future__ import annotations

from collections import defaultdict
from pathlib import Path
from typing import Any

from transaction_parser import private_bank5_operations


PRIVATE_BANK_BY_CHANNEL = {1: 0x05, 2: 0x06, 3: 0x07, 4: 0x08}


def private_sequences(package_path: Path) -> dict[int, dict[int, list[int]]]:
    sequences: dict[int, dict[int, list[int]]] = {
        bank: defaultdict(list) for bank in PRIVATE_BANK_BY_CHANNEL.values()
    }
    for row in private_bank5_operations(package_path):
        sequences[0x05][row["address"]].append(row["data"])
    return sequences


def final_private_matrix(package_path: Path) -> list[dict[str, Any]]:
    sequences = private_sequences(package_path)
    addresses = sorted({address for bank in sequences.values() for address in bank})
    rows: list[dict[str, Any]] = []
    for address in addresses:
        values: dict[int, str] = {}
        for channel, bank in PRIVATE_BANK_BY_CHANNEL.items():
            if address in sequences[bank]:
                values[channel] = f"0x{sequences[bank][address][-1]:02X}"
            else:
                values[channel] = f"SYM_B{bank:02X}_{address:02X}_UNWRITTEN_RESET_DEFAULT"
        rows.append(
            {
                "RelativePrivateAddress": f"0x{address:02X}",
                "RegisterName": "VENDOR_PRIVATE_UNPUBLISHED",
                "DocumentedFunction": "Banks 5-10 not for users; exact field meaning unavailable",
                "CH1_Bank": "0x05",
                "CH1_FinalValue": values[1],
                "CH2_Bank": "0x06",
                "CH2_FinalValue": values[2],
                "CH3_Bank": "0x07",
                "CH3_FinalValue": values[3],
                "CH4_Bank": "0x08",
                "CH4_FinalValue": values[4],
                "ExpectedEquivalenceClass": "UNKNOWN_DOCUMENTATION",
                "ObservedRelation": "ONLY_BANK5_WRITTEN; BANK6_BANK7_BANK8_SYMBOLIC",
                "DifferenceClassification": "UNWRITTEN_RESET_DEFAULT_WITH_UNKNOWN_DOCUMENTATION",
                "SourceAuthority": "nvp6134c_diagnostics_pkg.vhd:244-343; final value is last Bank5 write",
                "PDFPage": "50,86 (private banks withheld); 88 (F0 channel mapping only)",
            }
        )
    return rows


def symbolic_unknown_rows(package_path: Path) -> list[dict[str, str]]:
    addresses = [int(row["RelativePrivateAddress"], 16) for row in final_private_matrix(package_path)]
    rows: list[dict[str, str]] = []
    for bank in (0x06, 0x07, 0x08):
        for address in addresses:
            rows.append(
                {
                    "Symbol": f"SYM_B{bank:02X}_{address:02X}_UNWRITTEN_RESET_DEFAULT",
                    "Bank": f"0x{bank:02X}",
                    "Address": f"0x{address:02X}",
                    "KnownMask": "0x00",
                    "UnknownMask": "0xFF",
                    "Reason": "no effective source write; reset/power-on value not established offline",
                    "Disposition": "PRESERVED_SYMBOLIC_NOT_ASSUMED_ZERO",
                }
            )
    rows.append(
        {
            "Symbol": "ORIGINAL_ENTRY_BANK",
            "Bank": "N/A",
            "Address": "0xFF",
            "KnownMask": "0x00",
            "UnknownMask": "0xFF",
            "Reason": "firmware-private operational context; not host-visible by frozen design",
            "Disposition": "PRESERVED_SYMBOLIC_AND_PHYSICALLY_RESTORED_BY_FIRMWARE",
        }
    )
    return rows


def missing_write_rows(package_path: Path) -> list[dict[str, str]]:
    sequences = private_sequences(package_path)
    rows: list[dict[str, str]] = []
    for address in sorted(sequences[0x05]):
        rows.append(
            {
                "Direction": "BANK5_OR_BANK7_TO_BANK6_OR_BANK8",
                "RelativePrivateAddress": f"0x{address:02X}",
                "Bank5Sequence": ";".join(f"0x{x:02X}" for x in sequences[0x05][address]),
                "Bank7Sequence": "UNWRITTEN_SYMBOLIC",
                "Bank6Sequence": "UNWRITTEN_SYMBOLIC",
                "Bank8Sequence": "UNWRITTEN_SYMBOLIC",
                "Pattern": "ONLY_BANK5_WRITTEN",
                "RequiredForEveryChannel": "NOT_PROVEN_VENDOR_PRIVATE",
                "CanAffectSAV": "UNKNOWN; source labels block AFE/EQ/geometry but fields unpublished",
                "CausalStatus": "CANDIDATE_NOT_PROVEN; Bank7 works while equally unwritten",
            }
        )
    rows.append(
        {
            "Direction": "BANK6_OR_BANK8_TO_BANK5_OR_BANK7",
            "RelativePrivateAddress": "NONE",
            "Bank5Sequence": "N/A",
            "Bank7Sequence": "N/A",
            "Bank6Sequence": "N/A",
            "Bank8Sequence": "N/A",
            "Pattern": "INVERSE_COUNT_0",
            "RequiredForEveryChannel": "N/A",
            "CanAffectSAV": "N/A",
            "CausalStatus": "NO_INVERSE_MISSING_WRITES",
        }
    )
    return rows


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    args = parser.parse_args()
    print(json.dumps(final_private_matrix(args.package), indent=2))
