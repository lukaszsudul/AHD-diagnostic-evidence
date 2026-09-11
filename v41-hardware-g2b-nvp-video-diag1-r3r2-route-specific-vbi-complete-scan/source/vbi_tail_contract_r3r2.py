#!/usr/bin/env python3
"""Pure host-side R3R2 route-specific VBI-tail validation rules."""

from __future__ import annotations

from collections import Counter
from typing import Any, Iterable


PROFILE = "NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_V1"
LAST_ACTIVE_LINE = 1079
FIRST_BENIGN_VERTICAL_TAIL_LINE = 1080
LAST_BENIGN_VERTICAL_TAIL_LINE = 1100
MIN_VERTICAL_TAIL_INTERVALS = 0
MAX_VERTICAL_TAIL_INTERVALS = 21
MIN_FRAME_BOUNDARY_CAPTURE_DELTA = 1
MAX_FRAME_BOUNDARY_CAPTURE_DELTA = 22
NON_FRAME_BOUNDARY_CAPTURE_DELTA = 1


def delta32(after: int, before: int) -> int:
    return (int(after) - int(before)) & 0xFFFFFFFF


def validate_transition(
    *,
    previous_frame: int,
    previous_line: int,
    previous_capture: int,
    previous_attempt: int,
    previous_global: int,
    previous_malformed: int,
    previous_dropped: int,
    current_frame: int,
    current_line: int,
    current_capture: int,
    current_attempt: int,
    current_global: int,
    current_malformed: int,
    current_dropped: int,
    current_flags: int,
    next_frame: int | None,
    next_line: int | None,
    next_flags: int | None,
    valid_flag: int,
    sof_flag: int,
) -> dict[str, Any]:
    """Validate one active-record transition under the frozen R3R2 contract."""
    frame_boundary = previous_line == LAST_ACTIVE_LINE
    capture_delta = delta32(current_capture, previous_capture)
    attempt_delta = delta32(current_attempt, previous_attempt)
    global_delta = delta32(current_global, previous_global)
    malformed_delta = delta32(current_malformed, previous_malformed)
    dropped_delta = delta32(current_dropped, previous_dropped)
    expected_frame = ((previous_frame + 1) & 0xFFFFFFFF
                      if frame_boundary else previous_frame)
    expected_line = 0 if frame_boundary else previous_line + 1
    failures: list[str] = []

    if current_frame != expected_frame or current_line != expected_line:
        failures.append("FRAME_OR_LINE_PROGRESSION")
    if attempt_delta != 1:
        failures.append("ATTEMPT_SEQUENCE_DELTA")
    if global_delta != 1:
        failures.append("GLOBAL_SEQUENCE_DELTA")

    if frame_boundary:
        if not (MIN_FRAME_BOUNDARY_CAPTURE_DELTA <= capture_delta <=
                MAX_FRAME_BOUNDARY_CAPTURE_DELTA):
            failures.append("FRAME_BOUNDARY_CAPTURE_DELTA_OUT_OF_BOUNDS")
        if current_flags != (valid_flag | sof_flag):
            failures.append("LINE0_FLAGS")
        if (next_frame != current_frame or next_line != 1 or
                next_flags != valid_flag):
            failures.append("LINE1_MISSING_OR_INVALID")
        if malformed_delta != 0:
            failures.append("MALFORMED_DELTA")
        if dropped_delta != 0:
            failures.append("DROPPED_DELTA")
    elif capture_delta != NON_FRAME_BOUNDARY_CAPTURE_DELTA:
        failures.append("NON_BOUNDARY_CAPTURE_DELTA")

    return {
        "frame_boundary": frame_boundary,
        "capture_sequence_delta": capture_delta,
        "tail_intervals": capture_delta - 1 if frame_boundary else None,
        "attempt_sequence_delta": attempt_delta,
        "global_sequence_delta": global_delta,
        "malformed_delta": malformed_delta,
        "dropped_delta": dropped_delta,
        "result": "PASS" if not failures else "FAIL",
        "failures": failures,
    }


def classify_tail_fingerprint(deltas: Iterable[int]) -> str:
    values = [int(value) for value in deltas]
    if not values:
        return "NO_FRAME_BOUNDARY_OBSERVED"
    if any(value < MIN_FRAME_BOUNDARY_CAPTURE_DELTA or
           value > MAX_FRAME_BOUNDARY_CAPTURE_DELTA for value in values):
        return "OUT_OF_BOUNDS_ROUTE_TAIL"
    tails = [value - 1 for value in values]
    if len(set(tails)) == 1:
        return f"STABLE_ROUTE_TAIL_{tails[0]}"
    return "VARIABLE_BUT_BOUNDED_ROUTE_TAIL"


def summarize_tail_deltas(deltas: Iterable[int]) -> dict[str, Any]:
    values = [int(value) for value in deltas]
    tails = [value - 1 for value in values]
    counts = Counter(tails)
    mode = None
    if counts:
        highest = max(counts.values())
        mode = min(value for value, count in counts.items() if count == highest)
    return {
        "boundary_count": len(values),
        "capture_sequence_delta_values": values,
        "tail_interval_values": tails,
        "minimum_tail_intervals": min(tails) if tails else None,
        "maximum_tail_intervals": max(tails) if tails else None,
        "mode_tail_intervals": mode,
        "unique_tail_interval_count": len(set(tails)),
        "fingerprint_classification": classify_tail_fingerprint(values),
        "legacy_ch1_exact_21_tail_fingerprint": (
            "PASS" if values and all(value ==
                                     MAX_FRAME_BOUNDARY_CAPTURE_DELTA
                                     for value in values) else
            "FAIL" if values else "NOT_APPLICABLE"
        ),
    }
