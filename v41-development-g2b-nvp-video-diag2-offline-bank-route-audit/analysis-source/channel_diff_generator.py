#!/usr/bin/env python3
"""Generate working/failing-cohort and parity comparisons."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from bank_normalizer import final_private_matrix, private_sequences


def cohort_diff_rows(package_path: Path) -> list[dict[str, Any]]:
    seq = private_sequences(package_path)
    rows: list[dict[str, Any]] = []
    for matrix in final_private_matrix(package_path):
        address = int(matrix["RelativePrivateAddress"], 16)
        rows.append(
            {
                "RelativePrivateAddress": matrix["RelativePrivateAddress"],
                "CH1_Working_Bank5": matrix["CH1_FinalValue"],
                "CH3_Working_Bank7": matrix["CH3_FinalValue"],
                "CH2_Failing_Bank6": matrix["CH2_FinalValue"],
                "CH4_Failing_Bank8": matrix["CH4_FinalValue"],
                "SequenceRelation": "BANK5_HAS_" + str(len(seq[0x05][address])) + "_WRITES; BANK6_7_8_HAVE_0",
                "FinalStateRelation": "UNRESOLVED_SYMBOLIC_FOR_BANK6_7_8",
                "ExactCH1CH3_vs_CH2CH4Pattern": "NO",
                "Why": "CH3 is in the working cohort but has the same no-write state as CH2 and CH4",
                "HighImpactClass": "NONE_PROVEN_VENDOR_FIELDS_UNPUBLISHED",
                "Confidence": "STRONG_CONFIGURATION_COMPLETENESS_CANDIDATE; NOT_CAUSAL_PROOF",
            }
        )
    return rows


def parity_findings() -> list[dict[str, str]]:
    return [
        {
            "Check": "private_bank_mapping",
            "Pattern": "5+zero_based_channel_index",
            "Source": "nvp6134c_diagnostics_pkg.vhd:552-563",
            "Finding": "PASS_EXACT_5_6_7_8_MAPPING",
            "HardwareParityMatch": "N/A_MAPPING_ONLY",
        },
        {
            "Check": "route_code_translation",
            "Pattern": "current_channel-1",
            "Source": "g2b_nvp_video_diag.sv:758-760",
            "Finding": "PASS_EXACT_0_1_2_3_MAPPING",
            "HardwareParityMatch": "NO_DEFECT",
        },
        {
            "Check": "public_all_channel_overlay",
            "Pattern": "CH1_CH2_CH3_CH4_explicit_contiguous",
            "Source": "nvp6134c_diagnostics_pkg.vhd:396-438",
            "Finding": "NO_ALTERNATING_MASK_OR_STEP",
            "HardwareParityMatch": "NO_DEFECT",
        },
        {
            "Check": "private_stage2_payload",
            "Pattern": "Bank5_only",
            "Source": "nvp6134c_diagnostics_pkg.vhd:244-343",
            "Finding": "CONFIGURATION_COMPLETENESS_GAP",
            "HardwareParityMatch": "INCOMPLETE_MATCH_BANK7_ALSO_UNWRITTEN_BUT_WORKS",
        },
        {
            "Check": "odd_even_operators_and_masks",
            "Pattern": "channel&1 channel%2 channel>>1 step2 0x5 0xA",
            "Source": "bounded active source search",
            "Finding": "NO_ACTIVE_CONFIGURATION_PATH_MATCH",
            "HardwareParityMatch": "NO_DEFECT",
        },
    ]


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    args = parser.parse_args()
    print(json.dumps(cohort_diff_rows(args.package), indent=2))
