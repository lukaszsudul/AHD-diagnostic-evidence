#!/usr/bin/env python3
"""Ten-case offline gate for the R3R2 task-local host controllers."""

from __future__ import annotations

import argparse
import csv
import inspect
import json
from pathlib import Path
import re
import unittest

from availability_classifier_r3r2 import classify, validate_complete_matrix
from controller_nvp_video_diag1_r3r2 import corrected_capture_validation_pass
from vbi_tail_contract_r3r2 import classify_tail_fingerprint


def window(vclk: int, sav: int, *, ready: bool = True,
           locked: bool = True) -> dict:
    return {
        "vclk_delta": vclk,
        "sav_delta": sav,
        "vclk_rate": float(vclk) * 4.0,
        "sav_rate": 25_000.0 if sav else 0.0,
        "vclk_per_sav": 5_280.0 if sav else None,
        "source_ready": ready,
        "source_locked": locked,
        "source_fatal": False,
        "transport_fatal": False,
        "nvp_fatal": False,
        "mmio_counter_consistent": True,
    }


def passing_validation() -> dict:
    return {
        "result": "PASS",
        "active_frame_and_transport_integrity": "PASS",
        "bounded_route_specific_vbi_tail": "PASS",
        "legacy_ch1_exact_21_tail_fingerprint": "FAIL",
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
        "frame_reconstruction": "PASS",
        "capture_sequence_delta_values": [2, 2],
        "route_vbi_tail_fingerprint": "STABLE_ROUTE_TAIL_1",
    }


class R3R2HostControllerGate(unittest.TestCase):
    scripts_dir: Path | None = None

    def test_t01_retained_ch3_now_returns_capture_pass(self) -> None:
        self.assertTrue(corrected_capture_validation_pass(passing_validation()))

    def test_t02_retained_ch3_legacy_mismatch_is_independent(self) -> None:
        value = passing_validation()
        self.assertEqual(value["legacy_ch1_exact_21_tail_fingerprint"], "FAIL")
        self.assertTrue(corrected_capture_validation_pass(value))

    def test_t03_no_sav_returns_not_run_and_safe_advance(self) -> None:
        no_sav = window(33_000_000, 0, locked=False)
        result = classify(no_sav, no_sav, reset_attempted=True,
                          reset_acknowledged=True)
        self.assertEqual(result["availability_classification"],
                         "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET")
        self.assertFalse(result["capture_eligible"])

    def test_t04_legal_variable_tail_continues_scan(self) -> None:
        value = passing_validation()
        value["capture_sequence_delta_values"] = [2, 3]
        value["route_vbi_tail_fingerprint"] = classify_tail_fingerprint([2, 3])
        self.assertEqual(value["route_vbi_tail_fingerprint"],
                         "VARIABLE_BUT_BOUNDED_ROUTE_TAIL")
        self.assertTrue(corrected_capture_validation_pass(value))

    def test_t05_out_of_range_tail_stops_scan(self) -> None:
        value = passing_validation()
        value["result"] = "FAIL"
        value["bounded_route_specific_vbi_tail"] = "FAIL"
        value["route_vbi_tail_fingerprint"] = "OUT_OF_BOUNDS_ROUTE_TAIL"
        self.assertFalse(corrected_capture_validation_pass(value))

    def test_t06_actual_integrity_failure_stops_scan(self) -> None:
        value = passing_validation()
        value["result"] = "FAIL"
        value["record_integrity_failures"] = 1
        self.assertFalse(corrected_capture_validation_pass(value))

    def test_t07_pixel_analysis_runs_after_bounded_vbi_pass(self) -> None:
        source = (self.scripts_dir / "controller_nvp_video_diag1_r3r2.py").read_text(
            encoding="utf-8")
        self.assertLess(source.index("corrected_capture_validation_pass(validation)"),
                        source.index("SESSION_{session_id:02d}_PIXEL_ANALYSIS"))

    def test_t08_firmware_ledger_drives_public_projections(self) -> None:
        import controller_nvp_video_diag1_r3r2 as controller
        source = inspect.getsource(controller.persist_r3r2_availability)
        self.assertIn("firmware_ack_ledger", source)
        self.assertIn("acknowledgement[\"FirmwareResponseRaw\"]", source)
        self.assertNotIn("firmware_advance_response(session", source)

    def test_t09_mixed_16_session_simulation_retains_unique_ids(self) -> None:
        order = ((1, 2, 3, 4), (4, 3, 2, 1),
                 (2, 3, 4, 1), (3, 4, 1, 2))
        rows = []
        for index in range(16):
            round_number = index // 4 + 1
            rows.append({
                "session_id": index + 1,
                "round": round_number,
                "channel": order[round_number - 1][index % 4],
                "availability_classification": (
                    "BT656_READY_PRE_RESET_AND_POST_RESET"
                    if index % 2 == 0 else
                    "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET"),
            })
        self.assertEqual(validate_complete_matrix(rows)["unique_session_ids"], 16)

    def test_t10_product_restore_path_remains_unchanged(self) -> None:
        old = (self.scripts_dir / "controller_nvp_video_diag1_r3r1.py").read_text(
            encoding="utf-8")
        new = (self.scripts_dir / "controller_nvp_video_diag1_r3r2.py").read_text(
            encoding="utf-8")
        pattern = re.compile(
            r"def wait_for_baseline_restore\(.*?(?=\ndef [a-zA-Z_])", re.S)
        self.assertEqual(pattern.search(old).group(0), pattern.search(new).group(0))


class RecordingResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.rows: list[dict[str, str]] = []

    def addSuccess(self, test):  # noqa: N802
        super().addSuccess(test)
        self.rows.append({"Test": test._testMethodName, "Result": "PASS",
                          "Detail": ""})

    def addFailure(self, test, err):  # noqa: N802
        super().addFailure(test, err)
        self.rows.append({"Test": test._testMethodName, "Result": "FAIL",
                          "Detail": self._exc_info_to_string(err, test)})

    def addError(self, test, err):  # noqa: N802
        super().addError(test, err)
        self.rows.append({"Test": test._testMethodName, "Result": "ERROR",
                          "Detail": self._exc_info_to_string(err, test)})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    R3R2HostControllerGate.scripts_dir = Path(__file__).resolve().parent
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(R3R2HostControllerGate)
    runner = unittest.TextTestRunner(verbosity=2, resultclass=RecordingResult)
    result = runner.run(suite)
    rows = sorted(result.rows, key=lambda row: row["Test"])
    with (args.output_dir / "host-controller-gate.csv").open(
            "x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=("Test", "Result", "Detail"))
        writer.writeheader()
        writer.writerows(rows)
    summary = {
        "gate": "R3R2_HOST_CONTROLLER_GATE",
        "passed": result.testsRun - len(result.failures) - len(result.errors),
        "requested": 10,
        "result": "PASS" if result.wasSuccessful() and result.testsRun == 10
                  else "FAIL",
    }
    (args.output_dir / "host-controller-gate.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))
    return 0 if summary["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
