#!/usr/bin/env python3
"""Sixteen deterministic offline gates for DIAG2-OFFLINE."""

from __future__ import annotations

import csv
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))

from bank_normalizer import final_private_matrix, missing_write_rows, symbolic_unknown_rows  # noqa: E402
from channel_diff_generator import cohort_diff_rows  # noqa: E402
from effective_state_replay import TRACE_FIELDS, build_trace, deterministic_signature  # noqa: E402
from observability_matrix_generator import rows as observability_rows  # noqa: E402
from route_sequence_extractor import current_sequence_steps, existing_sequences  # noqa: E402
from source_indexing_checker import audit as indexing_audit  # noqa: E402


SOURCE = Path(r"C:\FPGA\V41_G2B_NVP_VIDEO_DIAG1")
PRIOR = Path(r"C:\FPGA\V41_G2B_EVIDENCE\v41-hardware-g2b-nvp-video-diag1-r3r2r1-closed-runtime-bundle-complete-scan")
PACKAGE = SOURCE / "rtl/nvp/nvp6134c_diagnostics_pkg.vhd"
DIAG = SOURCE / "rtl/g2b/g2b_nvp_video_diag.sv"
CODEC = ROOT / "evidence-input/capture-card-fw/capture_supervisor/src/codec.c"
OUT = ROOT / "evidence-staging/v41-development-g2b-nvp-video-diag2-offline-bank-route-audit"


class Diag2OfflineGate(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.replay = build_trace(PACKAGE)
        cls.matrix = final_private_matrix(PACKAGE)

    def test_t01_canonical_bank_page_transaction_replay(self) -> None:
        self.assertEqual(len(self.replay.trace), 840)
        self.assertEqual(self.replay.use_before_bank_select, 0)
        self.assertEqual(self.replay.invalid_bank_or_address, 0)
        self.assertEqual(list(self.replay.trace[0]), TRACE_FIELDS)

    def test_t02_all_layers_deterministic_order(self) -> None:
        layers = list(dict.fromkeys(row["ConfigurationLayer"] for row in self.replay.trace))
        self.assertEqual(len(layers), 7)
        self.assertEqual([int(layer[1]) for layer in layers], list(range(1, 8)))

    def test_t03_final_per_channel_matrix(self) -> None:
        self.assertEqual(len(self.matrix), 37)
        self.assertTrue(all(row["CH1_Bank"] == "0x05" for row in self.matrix))
        self.assertTrue(all(row["CH4_Bank"] == "0x08" for row in self.matrix))

    def test_t04_private_bank_relative_comparison(self) -> None:
        rows = cohort_diff_rows(PACKAGE)
        self.assertEqual(len(rows), 37)
        self.assertTrue(all(row["ExactCH1CH3_vs_CH2CH4Pattern"] == "NO" for row in rows))

    def test_t05_missing_write_comparison(self) -> None:
        rows = missing_write_rows(PACKAGE)
        forward = [row for row in rows if row["Direction"] == "BANK5_OR_BANK7_TO_BANK6_OR_BANK8"]
        inverse = [row for row in rows if row["Direction"] == "BANK6_OR_BANK8_TO_BANK5_OR_BANK7" and row["RelativePrivateAddress"] != "NONE"]
        self.assertEqual((len(forward), len(inverse)), (37, 0))

    def test_t06_channel_index_and_parity(self) -> None:
        result = indexing_audit(PACKAGE, DIAG)
        self.assertTrue(result["mapping_ok"])
        self.assertTrue(result["route_translation_ok"])
        self.assertEqual(result["active_parity_configuration_paths"], 0)

    def test_t07_route_mapping_authority(self) -> None:
        sequences = existing_sequences(DIAG, PACKAGE, CODEC)
        self.assertEqual(sequences[-1]["NewRoute"], "0/1/2/3 maps CH1/CH2/CH3/CH4")

    def test_t08_c2_c8_enable_mode_audit(self) -> None:
        text = (OUT / "G2B_NVP_DIAG2_REGISTER_AUTHORITY.md").read_text(encoding="utf-8")
        for token in ("0xC2[3:0]", "0xC8[7:4]", "VCLK1_EN", "VDO1_EN", "0xCD"):
            self.assertIn(token, text)

    def test_t09_current_route_sequence(self) -> None:
        steps = current_sequence_steps()
        self.assertEqual(len(steps), 10)
        self.assertEqual(steps[0]["Action"], "require transport_quiescent")

    def test_t10_reference_route_sequences(self) -> None:
        sequences = existing_sequences(DIAG, PACKAGE, CODEC)
        self.assertGreaterEqual(len(sequences), 4)
        self.assertEqual(sequences[2]["ReArmUsed"], "NO")
        self.assertEqual(sequences[3]["ReArmUsed"], "NOT_DOCUMENTED")

    def test_t11_raw_marker_observability_matrix(self) -> None:
        rows = observability_rows()
        self.assertGreaterEqual(len(rows), 17)
        legal_sav = next(row for row in rows if row["Observation"] == "legal raw SAV count")
        raw_toggle = next(row for row in rows if row["Observation"] == "raw VDO byte-change count")
        self.assertEqual(legal_sav["R3Available"], "YES")
        self.assertEqual(raw_toggle["R3Available"], "NO")

    def test_t12_future_hardware_protocol(self) -> None:
        text = (OUT / "G2B_NVP_DIAG2_FUTURE_RAW_MARKER_HW_PROTOCOL.md").read_text(encoding="utf-8")
        self.assertIn("CH1 control -> CH2 failing route -> CH1 control", text)
        self.assertIn("no dma/aio", text.lower())
        self.assertIn("Arm B is excluded", text)

    def test_t13_symbolic_unknowns(self) -> None:
        rows = symbolic_unknown_rows(PACKAGE)
        self.assertEqual(len(rows), 112)
        self.assertTrue(all(not row["Disposition"].startswith("ASSUMED_ZERO") for row in rows))

    def test_t14_repeated_trace_determinism(self) -> None:
        second = build_trace(PACKAGE)
        self.assertEqual(deterministic_signature(self.replay.trace), deterministic_signature(second.trace))

    def test_t15_candidate_gate(self) -> None:
        decision = (OUT / "G2B_NVP_DIAG2_CORRECTION_CANDIDATE_DECISION.md").read_text(encoding="utf-8")
        self.assertIn("Correction candidate created: NO", decision)
        self.assertIn("proof gates", decision)
        self.assertFalse(any((ROOT / "candidate").glob("*")))

    def test_t16_evidence_index_and_manifest(self) -> None:
        index = (OUT / "G2B_NVP_DIAG2_OFFLINE_EVIDENCE_INDEX.md").read_text(encoding="utf-8")
        manifest_path = OUT / "G2B_NVP_DIAG2_OFFLINE_SHA256_MANIFEST.txt"
        manifest = manifest_path.read_text(encoding="utf-8")
        required = [line[3:-1] for line in index.splitlines() if line.startswith("- `")]
        self.assertTrue(all((OUT / rel).is_file() for rel in required))
        listed = {line.split("  ", 1)[1] for line in manifest.splitlines() if "  " in line}
        actual = {path.relative_to(OUT).as_posix() for path in OUT.rglob("*") if path.is_file() and path != manifest_path}
        self.assertEqual(listed, actual)


if __name__ == "__main__":
    unittest.main(verbosity=2)
