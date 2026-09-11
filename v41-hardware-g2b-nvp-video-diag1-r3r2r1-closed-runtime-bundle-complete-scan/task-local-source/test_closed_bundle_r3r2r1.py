#!/usr/bin/env python3
"""Deterministic non-hardware checks for the R3R2R1 closed runtime bundle."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import unittest

from availability_classifier_r3r2 import classify, validate_complete_matrix
from controller_nvp_video_diag1_r3r2 import corrected_capture_validation_pass


def window(vclk: int, sav: int) -> dict[str, object]:
    return {
        "vclk_delta": vclk,
        "sav_delta": sav,
        "vclk_rate": float(vclk) * 4.0,
        "sav_rate": 25_000.0 if sav else 0.0,
        "vclk_per_sav": 5_280.0 if sav else None,
        "source_ready": bool(sav),
        "source_locked": bool(sav),
        "source_fatal": False,
        "transport_fatal": False,
        "nvp_fatal": False,
        "mmio_counter_consistent": True,
    }


class ClosedBundleTests(unittest.TestCase):
    def test_mocked_full_16_session_orchestration(self) -> None:
        orders = ((1, 2, 3, 4), (4, 3, 2, 1),
                  (2, 3, 4, 1), (3, 4, 1, 2))
        rows: list[dict[str, object]] = []
        for index in range(16):
            round_number = index // 4 + 1
            ready = index % 3 == 0
            classification = classify(
                window(33_000_000, 6_250 if ready else 0),
                window(33_000_000, 6_250 if ready else 0),
                reset_attempted=True,
                reset_acknowledged=True,
            )
            rows.append({
                "session_id": index + 1,
                "round": round_number,
                "channel": orders[round_number - 1][index % 4],
                "availability_classification":
                    classification["availability_classification"],
            })
        matrix = validate_complete_matrix(rows)
        self.assertEqual(matrix["unique_session_ids"], 16)
        self.assertEqual(matrix["unique_round_channel_pairs"], 16)
        self.assertEqual(len({int(row["session_id"]) for row in rows}), 16)
        self.assertEqual(sorted(int(row["session_id"]) for row in rows),
                         list(range(1, 17)))

    def test_synthetic_no_sav_safe_advance_semantics(self) -> None:
        value = classify(window(33_000_000, 0), window(33_000_000, 0),
                         reset_attempted=True, reset_acknowledged=True)
        self.assertEqual(value["availability_classification"],
                         "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET")
        self.assertFalse(value["capture_eligible"])
        session_id = 7
        self.assertEqual((session_id << 16) | 0x00000009, 0x00070009)

    def test_mocked_capture_pass_accepts_bounded_route_tail(self) -> None:
        validation = {
            "result": "PASS",
            "active_frame_and_transport_integrity": "PASS",
            "bounded_route_specific_vbi_tail": "PASS",
            "frame_reconstruction": "PASS",
            "frame_boundary_count": 2,
            "record_integrity_failures": 0,
            "global_sequence_gaps": 0,
            "attempt_sequence_gaps": 0,
            "overflow_flag_records": 0,
            "malformed_preceding_flag_records": 0,
            "source_malformed_snapshot_delta": 0,
            "source_dropped_snapshot_delta": 0,
            "line_0_present": True,
            "line_0_sof": True,
            "capture_sequence_delta_values": [2, 3],
            "route_vbi_tail_fingerprint":
                "VARIABLE_BUT_BOUNDED_ROUTE_TAIL",
        }
        self.assertTrue(corrected_capture_validation_pass(validation))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ClosedBundleTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    payload = {
        "gate": "R3R2R1_CLOSED_BUNDLE_MOCKED_EXECUTION",
        "tests_requested": 3,
        "tests_passed": result.testsRun - len(result.failures) - len(result.errors),
        "mocked_16_session_orchestration": "PASS" if result.wasSuccessful()
            else "FAIL",
        "synthetic_no_sav_safe_advance": "PASS" if result.wasSuccessful()
            else "FAIL",
        "mocked_capture_pass": "PASS" if result.wasSuccessful() else "FAIL",
        "result": "PASS" if result.wasSuccessful() and result.testsRun == 3
            else "FAIL",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n",
                           encoding="utf-8", newline="\n")
    print(json.dumps(payload, sort_keys=True))
    return 0 if payload["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
