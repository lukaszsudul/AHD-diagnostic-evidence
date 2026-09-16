"""Focused non-hardware regression for the frozen A/B comparison contract."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("comparator", HERE / "compare_xdc_views.py")
assert SPEC and SPEC.loader
comparator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(comparator)

PRIOR = Path(
    r"C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R1_20260916T105442Z"
    r"\signoff\finalization_attempt3_reports"
)
A = PRIOR / "SEMANTIC_REPLAY_PASS_2_CANONICAL.xdc"
B = PRIOR / "TIMING_CONSTRAINT_SIGNATURE_SIGNED_REOPEN_CANONICAL.xdc"


class ComparatorContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.a = A.read_bytes()
        cls.b = B.read_bytes()

    def test_c1_old_raw_hash_defect_reproduced(self) -> None:
        self.assertNotEqual(comparator.digest(self.a), comparator.digest(self.b))
        self.assertEqual(comparator.digest(self.a), "4EDC4305DFD5B6A0F2EEA9E45CEABDDF4DC74B30A2CD9B394ED22E7500FC1B44")
        self.assertEqual(comparator.digest(self.b), "820331804ABA905FDBC1AA70578CCF8CFFE2D723DAEA08D861A85CDD3B7BE224")

    def test_c2_real_ordered_command_equivalence_and_lineage(self) -> None:
        result = comparator.compare(self.a, self.b)
        self.assertTrue(result["exact_ordered_commands_equal"])
        self.assertEqual(result["a_commands"], 97)
        self.assertEqual(result["b_commands"], 97)
        self.assertEqual(result["a_aliases"], 11)
        self.assertEqual(result["b_aliases"], 5)
        self.assertEqual(result["a_expanded_sha256"], result["b_expanded_sha256"])

    def test_c3_changed_numeric_value_rejected(self) -> None:
        changed = self.b.replace(b"set_bus_skew", b"set_bus_skew", 1).replace(b" 3.000", b" 3.001", 1)
        self.assertFalse(comparator.compare(self.b, changed)["exact_ordered_commands_equal"])

    def test_c4_same_count_changed_target_rejected(self) -> None:
        changed = self.b.replace(b"snapshot_epoch", b"snapshot_other", 1)
        self.assertFalse(comparator.compare(self.b, changed)["exact_ordered_commands_equal"])

    def test_c5_missing_or_added_statement_rejected(self) -> None:
        lines = self.b.splitlines()
        index = next(i for i, line in enumerate(lines) if line.startswith(b"set_bus_skew "))
        self.assertFalse(comparator.compare(self.b, b"\n".join(lines[:index] + lines[index + 1 :]) + b"\n")["exact_ordered_commands_equal"])
        self.assertFalse(comparator.compare(self.b, self.b + lines[index] + b"\n")["exact_ordered_commands_equal"])

    def test_c6_order_sensitive_swap_rejected(self) -> None:
        lines = self.b.splitlines()
        indices = [i for i, line in enumerate(lines) if line.startswith(b"set_bus_skew ")]
        lines[indices[-2]], lines[indices[-1]] = lines[indices[-1]], lines[indices[-2]]
        changed = b"\n".join(lines) + b"\n"
        try:
            self.assertFalse(comparator.compare(self.b, changed)["exact_ordered_commands_equal"])
        except comparator.UnsafeView:
            # Moving a command across an alias definition is also a rejection.
            pass

    def test_c7_no_metadata_exclusion_is_declared(self) -> None:
        self.assertFalse(comparator.compare(self.b, b"# changed header\n" + self.b)["exact_ordered_commands_equal"])

    def test_c8_unsafe_or_empty_input_fails_closed(self) -> None:
        for bad in (b"", b"set _xlnx_shared_i0 [set_property X Y]\n", b"set_bus_skew -from $_xlnx_shared_i9\n", b"bad\r\n"):
            with self.assertRaises(comparator.UnsafeView):
                comparator.expand_export(bad)

    def test_c9_no_candidate_mutation_in_comparator(self) -> None:
        code = (HERE / "compare_xdc_views.py").read_text(encoding="utf-8")
        for token in ("open_checkpoint", "read_xdc", "reset_timing", "write_bitstream", "route_design", "write_checkpoint"):
            self.assertNotIn(token + "(", code)

    def test_c10_deterministic_and_preserved_raw_inputs(self) -> None:
        before = (comparator.digest(self.a), comparator.digest(self.b))
        self.assertEqual(comparator.compare(self.a, self.b), comparator.compare(self.a, self.b))
        self.assertEqual(before, (comparator.digest(A.read_bytes()), comparator.digest(B.read_bytes())))


if __name__ == "__main__":
    unittest.main(verbosity=2)
