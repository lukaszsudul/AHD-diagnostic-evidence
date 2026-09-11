#!/usr/bin/env python3
"""Deterministic ten-case gate for the R3R1 host-only correction."""

from __future__ import annotations

from pathlib import Path
import unittest

from availability_classifier_r3r1 import (
    AvailabilityContractError,
    classify,
    firmware_advance_response,
    session_semantics,
    validate_complete_matrix,
)


def window(*, vclk: int, sav: int, ready: bool = True,
           locked: bool = True, sav_rate: float = 25_000.0,
           ratio: float = 5_280.0) -> dict:
    return {
        "vclk_delta": vclk,
        "sav_delta": sav,
        "vclk_rate": float(vclk) * 4.0,
        "sav_rate": sav_rate if sav else 0.0,
        "vclk_per_sav": ratio if sav else None,
        "source_ready": ready,
        "source_locked": locked,
        "source_fatal": False,
        "transport_fatal": False,
        "nvp_fatal": False,
        "mmio_counter_consistent": True,
    }


READY = window(vclk=33_000_000, sav=6_250)
NO_SAV = window(vclk=33_000_000, sav=0, locked=False)
NO_VCLK = window(vclk=0, sav=0, ready=True, locked=False)


class R3R1HostControllerGate(unittest.TestCase):
    def test_t1_ready_before_and_after_reset(self) -> None:
        result = classify(READY, READY, reset_attempted=True,
                          reset_acknowledged=True)
        self.assertEqual(result["availability_classification"],
                         "BT656_READY_PRE_RESET_AND_POST_RESET")
        self.assertTrue(result["capture_eligible"])

    def test_t2_reset_recovers_sav(self) -> None:
        result = classify(NO_SAV, READY, reset_attempted=True,
                          reset_acknowledged=True)
        self.assertEqual(result["availability_classification"],
                         "BT656_READY_ONLY_AFTER_RESET")
        self.assertTrue(result["capture_eligible"])

    def test_t3_clock_present_no_sav_continues_without_capture(self) -> None:
        result = classify(NO_SAV, NO_SAV, reset_attempted=True,
                          reset_acknowledged=True)
        self.assertEqual(result["availability_classification"],
                         "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET")
        self.assertFalse(result["capture_eligible"])

    def test_t4_no_vclk_skips_reset_and_capture(self) -> None:
        result = classify(NO_VCLK, None, reset_attempted=False,
                          reset_acknowledged=False)
        self.assertEqual(result["availability_classification"],
                         "NO_VCLK_RESET_NOT_ATTEMPTED")
        self.assertFalse(result["capture_eligible"])
        self.assertFalse(result["reset_attempted"])

    def test_t5_reset_regression_is_not_capture_eligible(self) -> None:
        result = classify(READY, NO_SAV, reset_attempted=True,
                          reset_acknowledged=True)
        self.assertEqual(result["availability_classification"],
                         "BT656_READY_PRE_RESET_BUT_LOST_AFTER_RESET")
        self.assertFalse(result["capture_eligible"])

    def test_t6_no_capture_ack_is_not_capture_pass(self) -> None:
        result = session_semantics(
            availability="CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET",
            capture_result="NOT_RUN", quiescent=True,
            helper_launched=False, aio_submitted=0,
            stream_enable_writes=0)
        self.assertEqual(result["firmware_advance_ack"], "PASS_AND_QUIESCENT")
        self.assertFalse(result["capture_pass"])
        self.assertEqual(result["capture_result"], "NOT_RUN")
        self.assertEqual(firmware_advance_response(2), 0x00020009)

    def test_t7_eligible_session_uses_frozen_finite_path(self) -> None:
        result = session_semantics(
            availability="BT656_READY_PRE_RESET_AND_POST_RESET",
            capture_result="PASS", quiescent=True,
            helper_launched=True, aio_submitted=2500,
            stream_enable_writes=1)
        self.assertTrue(result["capture_pass"])
        source = (Path(__file__).with_name(
            "controller_nvp_capture_r3r1.py").read_text(encoding="utf-8"))
        self.assertIn("PRIMARY_RECORDS = 2500", source)
        self.assertIn("MAX_OUTSTANDING_IOCBS = 1024", source)
        self.assertIn("PRIMARY_WINDOW_COMPLETE", source)

    def test_t8_started_capture_failure_remains_fatal(self) -> None:
        with self.assertRaisesRegex(
                AvailabilityContractError,
                "R3R1_STARTED_CAPTURE_FAILURE_IS_FATAL"):
            session_semantics(
                availability="BT656_READY_PRE_RESET_AND_POST_RESET",
                capture_result="FAIL", quiescent=True,
                helper_launched=True, aio_submitted=2500,
                stream_enable_writes=1)

    def test_t9_unsafe_quiescence_prevents_ack(self) -> None:
        with self.assertRaisesRegex(
                AvailabilityContractError,
                "R3R1_UNSAFE_QUIESCENCE_PREVENTS_SESSION_ACKNOWLEDGEMENT"):
            session_semantics(
                availability="CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET",
                capture_result="NOT_RUN", quiescent=False,
                helper_launched=False, aio_submitted=0,
                stream_enable_writes=0)

    def test_t10_complete_mixed_matrix_retains_unique_sessions(self) -> None:
        order = ((1, 2, 3, 4), (4, 3, 2, 1),
                 (2, 3, 4, 1), (3, 4, 1, 2))
        rows = []
        for index in range(16):
            round_number = index // 4 + 1
            channel = order[round_number - 1][index % 4]
            rows.append({
                "session_id": index + 1,
                "round": round_number,
                "channel": channel,
                "availability_classification": (
                    "BT656_READY_PRE_RESET_AND_POST_RESET"
                    if channel == 1 else
                    "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET"),
            })
        self.assertEqual(validate_complete_matrix(rows)["sessions"], 16)


if __name__ == "__main__":
    unittest.main(verbosity=2)
