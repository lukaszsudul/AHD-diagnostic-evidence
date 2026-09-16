"""Synthetic mutation checks for the exact two-header report exclusion."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("report_comparator", HERE / "compare_report_bodies.py")
assert SPEC and SPEC.loader
comparator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(comparator)


def fixture(date: str, root: str, warning: str = "WARNING: TIMING-34") -> bytes:
    return (
        "Header\n"
        "| Tool Version : Vivado v.2025.2 Build 6299465\n"
        f"| Date         : {date}\n"
        f"| Command      : report_cdc -details -file {root}/report_cdc.rpt\n"
        "| Design       : ahd_capture_top_xdma\n"
        "Body\n"
        f"{warning}\n"
        "End\n"
    ).encode()


class ReportComparatorTests(unittest.TestCase):
    def test_only_date_and_output_path_differ(self) -> None:
        result = comparator.compare(fixture("T1", "one"), fixture("T2", "two"))
        self.assertFalse(result["raw_equal"])
        self.assertTrue(result["body_equal"])

    def test_warning_change_survives(self) -> None:
        result = comparator.compare(fixture("T1", "one"), fixture("T2", "two", "WARNING: TIMING-39"))
        self.assertFalse(result["body_equal"])

    def test_command_option_change_rejected(self) -> None:
        bad = fixture("T2", "two").replace(b"report_cdc -details", b"report_cdc -summary")
        with self.assertRaises(comparator.UnsafeReport):
            comparator.compare(fixture("T1", "one"), bad)

    def test_missing_or_duplicated_provenance_rejected(self) -> None:
        good = fixture("T1", "one")
        with self.assertRaises(comparator.UnsafeReport):
            comparator.body(good.replace(b"| Date         : T1\n", b""))
        with self.assertRaises(comparator.UnsafeReport):
            comparator.body(good.replace(b"| Date         : T1\n", b"| Date         : T1\n| Date         : T1\n"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
