from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "host"))

from acq1_compat0_r2 import contract, format_decision, policy  # noqa: E402


def snapshot(novid: int, f0: int = 0x31, tuple_tag: int = 0) -> dict:
    raw_tuple = [novid, f0, tuple_tag]
    return {
        "live_status_changed": False,
        "entry_bank_restore": "PASS",
        "entry_count": 82,
        "channels": {"CH1": {"novid": novid, "raw_f0": f0, "raw_tuple": raw_tuple}},
    }


class HostPolicyTests(unittest.TestCase):
    def test_e18_stable_novid_zero_stops_immediately(self) -> None:
        observations = [snapshot(0) for _ in range(3)]
        self.assertEqual(policy.post_level_decision(0x50, observations),
                         "STOP_AND_IDENTIFY_FORMAT")
        self.assertNotEqual(policy.post_level_decision(0x50, observations),
                            "CONTINUE_TO_NEXT_LEVEL")

    def test_e19_final_level_novid_one_is_terminal_without_broader_action(self) -> None:
        observations = [snapshot(1, 0xFF) for _ in range(3)]
        self.assertEqual(policy.post_level_decision(0x60, observations),
                         "STOP_NO_VALID_VIDEO_AND_ROLLBACK")
        terminal = format_decision.terminal_policy("NO_FORMAT_CODE", True)
        self.assertFalse(terminal["mode_write"])
        self.assertFalse(terminal["eq_write"])
        self.assertFalse(terminal["capture"])
        self.assertTrue(terminal["rollback_required"])

    def test_e20_all_format_paths_are_read_only_and_rollback(self) -> None:
        unresolved = format_decision.decide([snapshot(0, 0x31) for _ in range(3)])
        self.assertEqual(unresolved["outcome"], "FORMAT_PRESENT_UNRESOLVED")
        for outcome in ("FORMAT_PRESENT_UNRESOLVED", "FORMAT_PRESENT_UNSUPPORTED",
                        "AHD1080P25_CANDIDATE_CONFIRMED"):
            terminal = format_decision.terminal_policy(outcome, True)
            self.assertTrue(terminal["read_only"] if "read_only" in terminal else
                            not (terminal["mode_write"] or terminal["eq_write"] or terminal["capture"]))
            self.assertTrue(terminal["rollback_required"])

    def test_frozen_contract(self) -> None:
        operation, decision = contract.load_and_validate()
        self.assertEqual(len(operation["forward_actions"]), 3)
        self.assertFalse(decision["temporary_writes_allowed"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
