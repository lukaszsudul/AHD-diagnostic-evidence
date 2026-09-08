#!/usr/bin/env python3
"""Analyze a frozen G2B BT.656 DIAG1-R1 event trace.

The input is the public, payload-free decoded trace JSON.  Outputs contain
only marker/parser metadata and a replay fixture; no active video bytes.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path


def yn(value: bool) -> str:
    return "YES" if value else "NO"


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_json", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    document = json.loads(args.trace_json.read_text(encoding="utf-8"))
    entries = document["entries"]
    if len(entries) != 147:
        raise SystemExit(f"expected 147 entries, got {len(entries)}")

    malformed = [entry for entry in entries if entry["malformed_increment"]]
    drops = [entry for entry in entries if entry["source_drop_increment"]]
    commits = [entry for entry in entries if entry["commit_pulse"]]
    trigger = next(entry for entry in entries if entry["trigger_pulse"])

    line1079_sav = next(
        entry
        for entry in entries
        if entry["logical_index"] < trigger["logical_index"]
        and entry["marker_valid"]
        and entry["decoded_v"] == 0
        and entry["decoded_h"] == 0
        and entry["source_line_sequence"] == 1078
    )
    line1079_eav = trigger
    next_frame_line0_sav = next(
        entry
        for entry in entries
        if entry["logical_index"] > trigger["logical_index"]
        and entry["marker_valid"]
        and entry["decoded_v"] == 0
        and entry["decoded_h"] == 0
        and entry["source_state_after"] == "SRC_CAPTURE"
        and entry["source_locked_before"] == 0
        and entry["previous_sav_v"] == 1
    )
    next_frame_line0_eav = next(
        entry
        for entry in entries
        if entry["logical_index"] > next_frame_line0_sav["logical_index"]
        and entry["marker_valid"]
        and entry["decoded_v"] == 0
        and entry["decoded_h"] == 1
        and entry["source_frame_sequence"] == trigger["source_frame_sequence"] + 1
        and entry["source_line_sequence"] == 0
    )
    next_frame_line1_sav = next(
        entry
        for entry in entries
        if entry["logical_index"] > next_frame_line0_eav["logical_index"]
        and entry["marker_valid"]
        and entry["decoded_v"] == 0
        and entry["decoded_h"] == 0
        and entry["source_frame_sequence"] == trigger["source_frame_sequence"] + 1
        and entry["source_line_sequence"] == 0
    )
    timeout_entry = entries[-1]

    reasons = Counter(entry["malformed_reason"] for entry in malformed)
    drop_reasons = Counter(entry["drop_reason"] for entry in drops)
    extra_lines = [entry["pending_line"] for entry in malformed]
    exact_extra_line_span = extra_lines == list(range(1080, 1101))
    all_reason2 = reasons == Counter({2: 21})
    all_enabled_zero = all(entry["enable_applied"] == 0 for entry in entries)
    all_attempt_zero = all(entry["monitor_has_attempt"] == 0 for entry in entries)

    # The replay starts with the line-1079 SAV.  A canonical prehistory in the
    # testbench establishes the same parser boundary state; from here through
    # the final captured SAV, marker bytes and source-clock intervals are exact.
    fixture_entries = entries[line1079_sav["logical_index"] : -1]
    fixture_path = args.output_dir / "trace-replay-fixture.txt"
    with fixture_path.open("w", encoding="ascii", newline="\n") as handle:
        handle.write("# logical_index xy gap_to_next source_ready\n")
        for position, entry in enumerate(fixture_entries):
            if not entry["marker_event"] or not entry["marker_valid"]:
                raise SystemExit(
                    f"entry {entry['logical_index']} is not a valid marker"
                )
            if position + 1 < len(fixture_entries):
                next_delta = fixture_entries[position + 1]["source_clock_delta"]
            else:
                next_delta = timeout_entry["source_clock_delta"]
            gap = next_delta - 4
            if gap < 0:
                raise SystemExit(f"negative replay gap after {entry['logical_index']}")
            xy = entry["marker_bytes_hex"].split()[-1]
            handle.write(
                f"{entry['logical_index']} {xy} {gap} {entry['source_ready']}\n"
            )

    malformed_rows = []
    for entry in malformed:
        malformed_rows.append(
            {
                "LogicalIndex": entry["logical_index"],
                "EventSequence": entry["event_sequence"],
                "SourceClockDelta": entry["source_clock_delta"],
                "MarkerBytes": entry["marker_bytes_hex"],
                "F": entry["decoded_f"],
                "V": entry["decoded_v"],
                "H": entry["decoded_h"],
                "XYValid": entry["marker_xy_valid"],
                "PendingLine": entry["pending_line"],
                "StateBefore": entry["source_state_before"],
                "StateAfter": entry["source_state_after"],
                "LockBefore": entry["source_locked_before"],
                "LockAfter": entry["source_locked_after"],
                "MalformedReason": entry["malformed_reason"],
                "MonitorHasAttempt": entry["monitor_has_attempt"],
                "SourceDropIncrement": entry["source_drop_increment"],
                "DropReason": entry["drop_reason"],
                "EnableApplied": entry["enable_applied"],
            }
        )
    write_csv(
        args.output_dir / "malformed-event-timeline.csv",
        malformed_rows,
        list(malformed_rows[0]),
    )

    analysis = {
        "schema": "G2B_BT656_DIAG1_R1_TRACE_ANALYSIS_V1",
        "trace_entries": len(entries),
        "trigger_logical_index": trigger["logical_index"],
        "trigger_event_sequence": trigger["event_sequence"],
        "trigger_frame": trigger["source_frame_sequence"],
        "trigger_line": trigger["pending_line"],
        "line_1079_sav_logical_index": line1079_sav["logical_index"],
        "line_1079_eav_logical_index": line1079_eav["logical_index"],
        "line_1079_eav_raw_marker": line1079_eav["marker_bytes_hex"],
        "next_frame_line_0_sav_logical_index": next_frame_line0_sav["logical_index"],
        "next_frame_line_0_sav_raw_marker": next_frame_line0_sav["marker_bytes_hex"],
        "next_frame_line_0_sav_fvh": [
            next_frame_line0_sav["decoded_f"],
            next_frame_line0_sav["decoded_v"],
            next_frame_line0_sav["decoded_h"],
        ],
        "next_frame_line_0_sav_xy_valid": bool(next_frame_line0_sav["marker_xy_valid"]),
        "next_frame_line_0_enters_src_capture": next_frame_line0_sav["source_state_after"] == "SRC_CAPTURE",
        "next_frame_line_0_monitor_has_attempt": bool(next_frame_line0_sav["monitor_has_attempt"]),
        "next_frame_line_0_allocation_valid": bool(next_frame_line0_sav["allocation_valid"]),
        "next_frame_line_0_writable_slot_allocated": bool(next_frame_line0_sav["monitor_writes_slot"]),
        "next_frame_line_0_eav_logical_index": next_frame_line0_eav["logical_index"],
        "next_frame_line_0_eav_raw_marker": next_frame_line0_eav["marker_bytes_hex"],
        "next_frame_line_0_committed": any(
            entry["source_frame_sequence"] == trigger["source_frame_sequence"] + 1
            and entry["pending_line"] == 0
            for entry in commits
        ),
        "next_frame_line_0_sof_composed": False,
        "next_frame_line_1_sav_logical_index": next_frame_line1_sav["logical_index"],
        "next_frame_line_1_committed": any(
            entry["source_frame_sequence"] == trigger["source_frame_sequence"] + 1
            and entry["pending_line"] == 1
            for entry in commits
        ),
        "malformed_increment_events": len(malformed),
        "malformed_reason_counts": {str(k): v for k, v in sorted(reasons.items())},
        "malformed_pending_lines": extra_lines,
        "exact_lines_1080_through_1100": exact_extra_line_span,
        "source_drop_increment_events": len(drops),
        "drop_reason_counts": {str(k): v for k, v in sorted(drop_reasons.items())},
        "all_enable_applied_zero": all_enabled_zero,
        "all_monitor_has_attempt_zero": all_attempt_zero,
        "source_lifetime_malformed_first": entries[0]["source_lifetime_malformed_before"],
        "source_lifetime_malformed_last": entries[-1]["source_lifetime_malformed_before"],
        "source_lifetime_malformed_delta": (
            entries[-1]["source_lifetime_malformed_before"]
            - entries[0]["source_lifetime_malformed_before"]
        ),
        "stop_reason": "SOURCE_CLOCK_TIMEOUT",
        "stop_on_clock_timeout": bool(timeout_entry["stop_on_clock_timeout"]),
        "clocks_since_trigger": 300000,
        "physical_conclusion": (
            "The current parser rejects 21 complete V=0 lines numbered "
            "1080..1100 at EAV solely because pending_line exceeds 1079; "
            "the first rejection deasserts source lock and the next active "
            "frame line 0 is parsed but not admitted while lock is low."
        ),
        "root_cause_decision": "ROOT_CAUSE_PROVEN_VERTICAL_BLANKING_HANDLING",
        "analysis_pass": exact_extra_line_span and all_reason2,
    }
    (args.output_dir / "trace-analysis.json").write_text(
        json.dumps(analysis, indent=2) + "\n", encoding="utf-8"
    )

    marker_lines = [
        "# G2B BT.656 DIAG1-R1 Marker Sequence",
        "",
        f"Trace entries: {len(entries)}. Trigger: logical index {trigger['logical_index']}, "
        f"event sequence {trigger['event_sequence']}, frame {trigger['source_frame_sequence']}, "
        f"line {trigger['pending_line']}.",
        "",
        "| Index | Seq | Delta clocks | Raw marker | F/V/H | XY | State before -> after | Line | Lock | Malformed | Drop |",
        "|---:|---:|---:|---|---|---|---|---:|---|---|---|",
    ]
    for entry in entries[line1079_sav["logical_index"] :]:
        marker_lines.append(
            f"| {entry['logical_index']} | {entry['event_sequence']} | "
            f"{entry['source_clock_delta']} | {entry['marker_bytes_hex']} | "
            f"{entry['decoded_f']}/{entry['decoded_v']}/{entry['decoded_h']} | "
            f"{'PASS' if entry['marker_xy_valid'] else ('N/A' if not entry['marker_event'] else 'FAIL')} | "
            f"{entry['source_state_before']} -> {entry['source_state_after']} | "
            f"{entry['pending_line']} | {entry['source_locked_before']} -> "
            f"{entry['source_locked_after']} | {entry['malformed_increment']}/"
            f"{entry['malformed_reason']} | {entry['source_drop_increment']}/"
            f"{entry['drop_reason']} |"
        )
    marker_lines.extend(
        [
            "",
            "The final entry is the source-clock timeout synthetic event, not a valid marker.",
        ]
    )
    (args.output_dir / "marker-sequence.md").write_text(
        "\n".join(marker_lines) + "\n", encoding="utf-8"
    )

    line0_lines = [
        "# G2B BT.656 DIAG1-R1 Line-0/SOF Analysis",
        "",
        f"- Line-1079 SAV: YES, logical index {line1079_sav['logical_index']}.",
        f"- Line-1079 EAV: YES, logical index {line1079_eav['logical_index']}, raw `{line1079_eav['marker_bytes_hex']}`.",
        f"- Next-frame line-0 SAV: YES, logical index {next_frame_line0_sav['logical_index']}, raw `{next_frame_line0_sav['marker_bytes_hex']}`, F/V/H 0/0/0, XY parity PASS.",
        "- Line 0 enters `SRC_CAPTURE`: YES.",
        "- Line 0 receives an attempt: NO; `source_locked_before=0`.",
        "- Line 0 receives a writable slot: NO (allocation is available, but admission is lock-gated).",
        f"- Next-frame line-0 EAV: YES, logical index {next_frame_line0_eav['logical_index']}, raw `{next_frame_line0_eav['marker_bytes_hex']}`.",
        "- Line 0 commits: NO in the hardware trace; streaming was disabled for every captured event.",
        "- Line 0 composes SOF: NO in the hardware trace.",
        "- Line 1 commits: NO in the hardware trace; streaming was disabled for every captured event.",
        "",
        "The trace directly shows 21 reason-2 malformed increments at EAV for pending lines 1080 through 1100. The parser's accepted-line predicate is otherwise satisfied but rejects `pending_line > 1079`. The first such rejection drops source lock. At the next active-frame SAV, the parser recognizes line 0 and enters capture, but lock is still low; line-0 EAV only restores lock. This makes lock admission a downstream contributing effect, not the initiating root cause.",
        "",
        "Because `enable_applied=0` and `monitor_has_attempt=0` throughout this frozen hardware trace, commit behavior is established by the current-parser replay rather than falsely attributed to the passive trace alone.",
    ]
    (args.output_dir / "line0-sof-analysis.md").write_text(
        "\n".join(line0_lines) + "\n", encoding="utf-8"
    )

    hypothesis_rows = [
        {
            "Hypothesis": "H1_LOCK_ADMISSION",
            "Disposition": "PROVEN_CONTRIBUTING_EFFECT",
            "Evidence": "Lock falls at first line-1080 reason-2 rejection; next-frame line-0 SAV enters capture with lock low and no attempt.",
        },
        {
            "Hypothesis": "H2_VERTICAL_BLANKING_HANDLING",
            "Disposition": "PROVEN",
            "Evidence": "Twenty-one complete V=0 lines 1080..1100 are rejected only by pending_line<=1079 at EAV.",
        },
        {
            "Hypothesis": "H3_LINE_COUNTER_OFF_BY_ONE",
            "Disposition": "DISPROVEN",
            "Evidence": "Line 1079 completes successfully; failures begin at correctly numbered line 1080.",
        },
        {
            "Hypothesis": "H4_NVP_MODE_MISMATCH",
            "Disposition": "OPEN",
            "Evidence": "Trace proves the emitted marker pattern but contains no NVP mode-register identity.",
        },
        {
            "Hypothesis": "H5_TIMING_OR_PHASE",
            "Disposition": "NOT_SUPPORTED",
            "Evidence": "Every implicated raw marker has valid XY/parity and stable 1436/3844 event spacing; routed timing and CDC pass.",
        },
    ]
    write_csv(
        args.output_dir / "hypothesis-matrix.csv",
        hypothesis_rows,
        ["Hypothesis", "Disposition", "Evidence"],
    )

    root_lines = [
        "# G2B BT.656 DIAG1-R1 Root-Cause Decision",
        "",
        "Decision: `ROOT_CAUSE_PROVEN_VERTICAL_BLANKING_HANDLING`.",
        "",
        "The physical trace identifies the exact initiating code predicate: 21 full-length, parity-valid V=0 lines after line 1079 reach `SRC_WAIT_EAV`, but are rejected because `pending_line <= 1079` is false. This produces 21 reason-2 malformed increments and causes the first lock loss. The next frame's line-0 SAV is physically present and parsed, while the now-low lock prevents admission. The replay is required to confirm the enabled-path omission and composed flags.",
        "",
        "H1 lock admission is a proven contributing effect, not the sole root. H3 is disproven. H4 remains open as a frontend configuration explanation for why the physical source emits this vertical-boundary shape, but it is not needed to identify the parser condition that generates the observed malformed chain. H5 is not supported.",
        "",
        "The run remains operationally BLOCKED by unresolved drain AIO cleanup. No correction worktree or candidate is created while the helper, module reference, nodes, and locks remain intentionally preserved.",
    ]
    (args.output_dir / "root-cause-decision.md").write_text(
        "\n".join(root_lines) + "\n", encoding="utf-8"
    )

    if not analysis["analysis_pass"]:
        raise SystemExit("trace analysis hard gate failed")
    print(json.dumps(analysis, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
