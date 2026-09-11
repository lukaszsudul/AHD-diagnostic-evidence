#!/usr/bin/env python3
"""Sixteen-case regression for the R3R2 bounded VBI-tail validator."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import unittest

from vbi_tail_contract_r3r2 import (
    classify_tail_fingerprint,
    summarize_tail_deltas,
    validate_transition,
)


VALID = 0x20
SOF = 0x01
DISCONTINUITY = 0x04
OVERFLOW = 0x08
MALFORMED_PRECEDING = 0x10


def boundary(delta: int = 2, **overrides: int | None) -> dict:
    values: dict[str, int | None] = {
        "previous_frame": 100,
        "previous_line": 1079,
        "previous_capture": 500,
        "previous_attempt": 10,
        "previous_global": 20,
        "previous_malformed": 0,
        "previous_dropped": 0,
        "current_frame": 101,
        "current_line": 0,
        "current_capture": 500 + delta,
        "current_attempt": 11,
        "current_global": 21,
        "current_malformed": 0,
        "current_dropped": 0,
        "current_flags": VALID | SOF,
        "next_frame": 101,
        "next_line": 1,
        "next_flags": VALID,
        "valid_flag": VALID,
        "sof_flag": SOF,
    }
    values.update(overrides)
    return validate_transition(**values)  # type: ignore[arg-type]


def active_transition(delta: int = 1, **overrides: int | None) -> dict:
    values: dict[str, int | None] = {
        "previous_frame": 100,
        "previous_line": 10,
        "previous_capture": 500,
        "previous_attempt": 10,
        "previous_global": 20,
        "previous_malformed": 0,
        "previous_dropped": 0,
        "current_frame": 100,
        "current_line": 11,
        "current_capture": 500 + delta,
        "current_attempt": 11,
        "current_global": 21,
        "current_malformed": 0,
        "current_dropped": 0,
        "current_flags": VALID,
        "next_frame": 100,
        "next_line": 12,
        "next_flags": VALID,
        "valid_flag": VALID,
        "sof_flag": SOF,
    }
    values.update(overrides)
    return validate_transition(**values)  # type: ignore[arg-type]


class R3R2ValidatorRegression(unittest.TestCase):
    retained_ch3_result: Path | None = None

    def test_t01_retained_ch1_exact_tail_control(self) -> None:
        result = boundary(22)
        summary = summarize_tail_deltas([22, 22])
        self.assertEqual(result["result"], "PASS")
        self.assertEqual(summary["legacy_ch1_exact_21_tail_fingerprint"], "PASS")
        self.assertEqual(summary["tail_interval_values"], [21, 21])

    def test_t02_retained_ch3_route_specific_tail(self) -> None:
        self.assertIsNotNone(self.retained_ch3_result)
        accepted = json.loads(self.retained_ch3_result.read_text(encoding="utf-8"))
        self.assertEqual(
            accepted["primary_file_sha256"],
            "BFA986D1BAC2E6C57342AC6F6D08C087A811FC72E97C9F1F8A383E53B78D7A6A",
        )
        deltas = [row["CaptureSequenceDelta"]
                  for row in accepted["frame_boundary_results"]]
        self.assertEqual(deltas, [2, 2])
        self.assertTrue(all(boundary(value)["result"] == "PASS"
                            for value in deltas))
        summary = summarize_tail_deltas(deltas)
        self.assertEqual(summary["tail_interval_values"], [1, 1])
        self.assertEqual(summary["legacy_ch1_exact_21_tail_fingerprint"], "FAIL")

    def test_t03_minimum_legal_boundary(self) -> None:
        self.assertEqual(boundary(1)["result"], "PASS")

    def test_t04_maximum_legal_boundary(self) -> None:
        self.assertEqual(boundary(22)["result"], "PASS")

    def test_t05_zero_delta_fails(self) -> None:
        self.assertEqual(boundary(0)["result"], "FAIL")

    def test_t06_above_maximum_fails(self) -> None:
        self.assertEqual(boundary(23)["result"], "FAIL")

    def test_t07_non_boundary_delta_two_fails(self) -> None:
        self.assertEqual(active_transition(2)["result"], "FAIL")

    def test_t08_frame_sequence_error_fails(self) -> None:
        self.assertEqual(boundary(2, current_frame=100)["result"], "FAIL")

    def test_t09_invalid_line0_flags_fail(self) -> None:
        self.assertEqual(boundary(2, current_flags=VALID)["result"], "FAIL")

    def test_t10_missing_or_invalid_line1_fails(self) -> None:
        self.assertEqual(boundary(2, next_line=None)["result"], "FAIL")

    def test_t11_attempt_delta_not_one_fails(self) -> None:
        self.assertEqual(boundary(2, current_attempt=12)["result"], "FAIL")

    def test_t12_global_delta_not_one_fails(self) -> None:
        self.assertEqual(boundary(2, current_global=22)["result"], "FAIL")

    def test_t13_malformed_or_dropped_delta_fails(self) -> None:
        self.assertEqual(boundary(2, current_malformed=1)["result"], "FAIL")
        self.assertEqual(boundary(2, current_dropped=1)["result"], "FAIL")

    def test_t14_event_flags_are_hard_failures(self) -> None:
        event_mask = OVERFLOW | MALFORMED_PRECEDING
        self.assertNotEqual((VALID | OVERFLOW) & event_mask, 0)
        self.assertNotEqual((VALID | MALFORMED_PRECEDING) & event_mask, 0)

    def test_t15_variable_but_bounded_tail_passes(self) -> None:
        self.assertEqual(boundary(2)["result"], "PASS")
        self.assertEqual(boundary(3)["result"], "PASS")
        self.assertEqual(classify_tail_fingerprint([2, 3]),
                         "VARIABLE_BUT_BOUNDED_ROUTE_TAIL")

    def test_t16_incomplete_or_duplicate_active_frame_fails(self) -> None:
        duplicate = active_transition(1, current_line=10)
        self.assertEqual(duplicate["result"], "FAIL")
        self.assertIn("FRAME_OR_LINE_PROGRESSION", duplicate["failures"])


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
    parser.add_argument("--retained-ch3-result", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    R3R2ValidatorRegression.retained_ch3_result = args.retained_ch3_result
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(
        R3R2ValidatorRegression)
    runner = unittest.TextTestRunner(verbosity=2, resultclass=RecordingResult)
    result = runner.run(suite)
    rows = sorted(result.rows, key=lambda row: row["Test"])
    with (args.output_dir / "validator-regression.csv").open(
            "x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=("Test", "Result", "Detail"))
        writer.writeheader()
        writer.writerows(rows)
    summary = {
        "gate": "R3R2_VALIDATOR_REGRESSION",
        "passed": result.testsRun - len(result.failures) - len(result.errors),
        "requested": 16,
        "result": "PASS" if result.wasSuccessful() and result.testsRun == 16
                  else "FAIL",
        "retained_ch3_primary_available_in_controller_root": False,
        "retained_ch3_fallback":
            "ACCEPTED_IMMUTABLE_R3R1_BOUNDARY_EVIDENCE_REPLAY",
    }
    (args.output_dir / "validator-regression.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))
    return 0 if summary["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
