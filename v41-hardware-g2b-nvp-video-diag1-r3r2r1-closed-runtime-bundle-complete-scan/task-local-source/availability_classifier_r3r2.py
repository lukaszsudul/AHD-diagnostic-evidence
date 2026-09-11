#!/usr/bin/env python3
"""Pure R3R2 VDO1/BT.656 availability and session-ledger rules."""

from __future__ import annotations

from typing import Any, Iterable


SAV_RATE_MIN = 20_000.0
SAV_RATE_MAX = 35_000.0
VCLK_PER_SAV_MIN = 5_200.0
VCLK_PER_SAV_MAX = 5_360.0

AVAILABILITY_CLASSES = {
    "BT656_READY_PRE_RESET_AND_POST_RESET",
    "BT656_READY_ONLY_AFTER_RESET",
    "BT656_READY_PRE_RESET_BUT_LOST_AFTER_RESET",
    "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET",
    "CLOCK_PRESENT_SAV_PRESENT_RATE_UNQUALIFIED",
    "NO_VCLK_RESET_NOT_ATTEMPTED",
    "RESET_ACK_TIMEOUT_WITH_VCLK",
    "SOURCE_FATAL_STATUS",
    "MMIO_COUNTER_INCONSISTENT",
}

CAPTURE_ELIGIBLE_CLASSES = {
    "BT656_READY_PRE_RESET_AND_POST_RESET",
    "BT656_READY_ONLY_AFTER_RESET",
}


class AvailabilityContractError(RuntimeError):
    pass


def qualified(window: dict[str, Any] | None) -> bool:
    """Apply the frozen R3 source-readiness predicates to one measured window."""
    if not window:
        return False
    ratio = window.get("vclk_per_sav")
    sav_rate = window.get("sav_rate")
    return bool(
        window.get("mmio_counter_consistent", True)
        and int(window.get("vclk_delta", 0)) > 0
        and int(window.get("sav_delta", 0)) > 0
        and isinstance(ratio, (int, float))
        and VCLK_PER_SAV_MIN <= float(ratio) <= VCLK_PER_SAV_MAX
        and isinstance(sav_rate, (int, float))
        and SAV_RATE_MIN <= float(sav_rate) <= SAV_RATE_MAX
        and window.get("source_ready") is True
        and window.get("source_locked") is True
        and not window.get("source_fatal", False)
        and not window.get("transport_fatal", False)
        and not window.get("nvp_fatal", False)
    )


def choose_post_window(short: dict[str, Any],
                       extended: dict[str, Any] | None) -> dict[str, Any]:
    """Use the short window when qualified, otherwise the authorized extension."""
    if qualified(short) or extended is None:
        return short
    return extended


def classify(pre: dict[str, Any], post: dict[str, Any] | None,
             *, reset_attempted: bool, reset_acknowledged: bool) -> dict[str, Any]:
    """Return exactly one governed R3R1 primary availability class."""
    windows = [pre] + ([post] if post is not None else [])
    if any(window.get("source_fatal", False) or
           window.get("transport_fatal", False) or
           window.get("nvp_fatal", False) for window in windows):
        availability = "SOURCE_FATAL_STATUS"
    elif any(not window.get("mmio_counter_consistent", True)
             for window in windows):
        availability = "MMIO_COUNTER_INCONSISTENT"
    elif int(pre.get("vclk_delta", 0)) == 0 and not reset_attempted:
        availability = "NO_VCLK_RESET_NOT_ATTEMPTED"
    elif reset_attempted and not reset_acknowledged:
        availability = "RESET_ACK_TIMEOUT_WITH_VCLK"
    else:
        pre_ready = qualified(pre)
        post_ready = qualified(post)
        if pre_ready and post_ready:
            availability = "BT656_READY_PRE_RESET_AND_POST_RESET"
        elif not pre_ready and post_ready:
            availability = "BT656_READY_ONLY_AFTER_RESET"
        elif pre_ready and not post_ready:
            availability = "BT656_READY_PRE_RESET_BUT_LOST_AFTER_RESET"
        elif any(int(window.get("sav_delta", 0)) > 0 for window in windows):
            availability = "CLOCK_PRESENT_SAV_PRESENT_RATE_UNQUALIFIED"
        else:
            availability = "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET"
    if availability not in AVAILABILITY_CLASSES:
        raise AvailabilityContractError("R3R1_UNKNOWN_AVAILABILITY_CLASS")
    return {
        "availability_classification": availability,
        "capture_eligible": availability in CAPTURE_ELIGIBLE_CLASSES,
        "pre_reset_qualified": qualified(pre),
        "post_reset_qualified": qualified(post),
        "reset_attempted": reset_attempted,
        "reset_acknowledged": reset_acknowledged,
    }


def no_capture_classification(availability: str) -> str:
    mapping = {
        "NO_VCLK_RESET_NOT_ATTEMPTED": "NOT_RUN_NO_VCLK",
        "CLOCK_PRESENT_NO_SAV_PRE_AND_POST_RESET":
            "NOT_RUN_CLOCK_PRESENT_NO_SAV",
        "CLOCK_PRESENT_SAV_PRESENT_RATE_UNQUALIFIED":
            "NOT_RUN_SAV_RATE_UNQUALIFIED",
        "BT656_READY_PRE_RESET_BUT_LOST_AFTER_RESET":
            "NOT_RUN_RESET_REGRESSION",
    }
    if availability not in mapping:
        raise AvailabilityContractError(
            f"R3R1_NO_CAPTURE_CLASS_NOT_ALLOWED:{availability}")
    return mapping[availability]


def firmware_advance_response(session_id: int) -> int:
    if not 1 <= session_id <= 16:
        raise AvailabilityContractError("R3R1_SESSION_ID_OUT_OF_RANGE")
    return (session_id << 16) | 0x0009


def session_semantics(*, availability: str, capture_result: str,
                      quiescent: bool, helper_launched: bool,
                      aio_submitted: int, stream_enable_writes: int) -> dict[str, Any]:
    """Keep firmware advancement separate from the host capture result."""
    if not quiescent:
        raise AvailabilityContractError(
            "R3R1_UNSAFE_QUIESCENCE_PREVENTS_SESSION_ACKNOWLEDGEMENT")
    if capture_result == "FAIL":
        raise AvailabilityContractError("R3R1_STARTED_CAPTURE_FAILURE_IS_FATAL")
    if capture_result == "PASS":
        return {
            "session_observation_result": "PASS_CAPTURE_COMPLETED",
            "capture_result": "PASS", "capture_pass": True,
            "firmware_advance_ack": "PASS_AND_QUIESCENT",
        }
    if capture_result != "NOT_RUN":
        raise AvailabilityContractError("R3R1_CAPTURE_RESULT_INVALID")
    if helper_launched or aio_submitted != 0 or stream_enable_writes != 0:
        raise AvailabilityContractError(
            "R3R1_NO_CAPTURE_SESSION_STARTED_TRANSPORT")
    no_capture_classification(availability)
    return {
        "session_observation_result": "PASS_NO_BT656_CAPTURE_NOT_RUN",
        "capture_result": "NOT_RUN", "capture_pass": False,
        "firmware_advance_ack": "PASS_AND_QUIESCENT",
    }


def validate_complete_matrix(rows: Iterable[dict[str, Any]]) -> dict[str, int]:
    rows = list(rows)
    session_ids = [int(row["session_id"]) for row in rows]
    pairs = {(int(row["round"]), int(row["channel"])) for row in rows}
    if len(rows) != 16 or sorted(session_ids) != list(range(1, 17)):
        raise AvailabilityContractError("R3R1_MATRIX_SESSION_SET_INVALID")
    if len(pairs) != 16:
        raise AvailabilityContractError("R3R1_MATRIX_ROUND_CHANNEL_SET_INVALID")
    if any(row.get("availability_classification") not in AVAILABILITY_CLASSES
           for row in rows):
        raise AvailabilityContractError("R3R1_MATRIX_AVAILABILITY_MISSING")
    return {
        "sessions": 16,
        "unique_session_ids": 16,
        "unique_round_channel_pairs": 16,
    }
