#!/usr/bin/env python3
"""Analyze the two saved R4 R1e/formal read-only telemetry captures.

This program consumes the JSON object emitted by the frozen R3
``read_nvp_r1e.py`` reader.  The input may be either a bare JSON document or a
captured command log containing the JSON followed by the reader's
``READ_ONLY=YES`` receipt.  It performs no I/O other than reading the two
specified files and writing the explicitly requested analysis files.

The classifications are intentionally conservative.  In particular, this
tool never treats an ordered log with overflow as complete, never equates the
post-init address probe with the mixed-phase autoinit transaction stream, and
never claims a solely proven electrical root cause.
"""

from __future__ import annotations

import argparse
import json
import math
from collections import Counter
from pathlib import Path
from typing import Any


EXPECTED_COUNT = 132_584_734
TICK_CYCLES = 1_251
PROBE_TARGET = 10_000
R1E_MAGIC = 0x314B4C43
R1E_EXTENSION_MAGIC = 0x31453152

STATIC_LOCAL = tuple(range(0x8C, 0xB8, 4))
STATIC_R1E = tuple(range(0x2014, 0x2098, 4))


class AnalysisError(RuntimeError):
    """Raised when a saved capture is structurally or scientifically invalid."""


def key(offset: int) -> str:
    return f"0x{offset:05X}"


def extract_reader_document(path: Path) -> dict[str, Any]:
    """Extract the first R1e reader document from a bare JSON file or log."""
    text = path.read_text(encoding="utf-8-sig", errors="strict")
    decoder = json.JSONDecoder()
    for index, character in enumerate(text):
        if character != "{":
            continue
        try:
            candidate, _ = decoder.raw_decode(text[index:])
        except json.JSONDecodeError:
            continue
        if (isinstance(candidate, dict) and "T0" in candidate and
                "T1" in candidate and isinstance(candidate["T0"], dict)):
            return candidate
    raise AnalysisError(f"no read_nvp_r1e.py JSON document found in {path}")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AnalysisError(message)


def static_projection(snapshot: dict[str, Any]) -> dict[str, Any]:
    return {
        "local": {key(offset): snapshot["local"][key(offset)]
                  for offset in STATIC_LOCAL},
        "r1e": {key(offset): snapshot["r1e_page"][key(offset)]
                for offset in STATIC_R1E},
        "legacy": snapshot["legacy_nack_raw_17_words"],
    }


def counter_advanced(before: int, after: int) -> bool:
    return ((after - before) & 0xFFFFFFFF) != 0


def validate_reader_pair(document: dict[str, Any], image: str) -> tuple[dict[str, Any], dict[str, Any]]:
    t0 = document.get("T0")
    t1 = document.get("T1")
    require(isinstance(t0, dict) and isinstance(t1, dict),
            f"{image}: two snapshots are required")
    for label, snapshot in (("T0", t0), ("T1", t1)):
        for field in ("local", "r1e_page", "legacy_nack_raw_17_words",
                      "ordered_nack"):
            require(field in snapshot, f"{image} {label}: missing {field}")
        require(snapshot["ordered_nack"].get("header_consistency") == "PASS",
                f"{image} {label}: ordered-log consistency failed")
    require(static_projection(t0) == static_projection(t1),
            f"{image}: T0/T1 static telemetry mismatch")

    page = t0["r1e_page"]
    if image == "arm_a":
        required = {
            key(0x2000): R1E_MAGIC,
            key(0x2004): 1,
            key(0x2040): R1E_EXTENSION_MAGIC,
            key(0x2044): 1,
            key(0x204C): 25_000,
            key(0x2050): TICK_CYCLES,
            key(0x2054): EXPECTED_COUNT,
            key(0x2064): PROBE_TARGET,
            key(0x2068): PROBE_TARGET,
            key(0x2074): 0,
        }
        for register, value in required.items():
            require(page.get(register) == value,
                    f"Arm A {register}: expected {value}, got {page.get(register)}")
        status = page[key(0x2078)]
        require(bool(status & 1), "Arm A: PROBE_DONE is not set")
        require(not bool(status & 2), "Arm A: PROBE_ABORTED is set")
        require(not bool(status & 4), "Arm A: PROBE_ACTIVE remains set")
        require(page[key(0x206C)] + page[key(0x2070)] == page[key(0x2068)],
                "Arm A: probe ACK+NACK does not equal PROBE_COUNT")
    elif image == "arm_b":
        require(all(value == 0 for value in page.values()),
                "Arm B: formal 0x2000..0x20FF page is not all zero")
    else:
        raise AnalysisError(f"unknown image role: {image}")
    return t0, t1


def wilson95(successes: int, total: int) -> tuple[float, float]:
    require(total > 0, "Wilson interval requires a positive denominator")
    require(0 <= successes <= total, "Wilson numerator is outside [0,N]")
    z = 1.959963984540054
    proportion = successes / total
    denominator = 1 + z * z / total
    centre = (proportion + z * z / (2 * total)) / denominator
    half = z * math.sqrt(
        proportion * (1 - proportion) / total + z * z / (4 * total * total)
    ) / denominator
    return centre - half, centre + half


def nvp_functional_result(t0: dict[str, Any], t1: dict[str, Any], prefix: str) -> dict[str, Any]:
    local0 = t0["local"]
    local1 = t1["local"]
    status = local0[key(0x8C)]
    status_fields = {
        "init_done": bool(status & 0x01),
        "init_error": bool(status & 0x02),
        "init_busy": bool(status & 0x04),
        "reset_released": bool(status & 0x08),
        "vdd1x_active": bool(status & 0x10),
        "vdd3x_active": bool(status & 0x20),
        "scl_sample": bool(status & 0x40),
        "sda_sample": bool(status & 0x80),
    }
    activity = {
        "vclk_advanced": counter_advanced(local0[key(0x80)], local1[key(0x80)]),
        "sav_advanced": counter_advanced(local0[key(0x84)], local1[key(0x84)]),
        "frame_advanced": counter_advanced(local0[key(0x60)], local1[key(0x60)]),
    }
    nack_count = local0[key(0x90)]
    timeout_count = local0[key(0x94)]
    passed = (status_fields["init_done"] and not status_fields["init_busy"] and
              not status_fields["init_error"] and nack_count == 0 and
              timeout_count == 0 and all(activity.values()))
    return {
        "status_raw": f"0x{status:08X}",
        **status_fields,
        "nack_count": nack_count,
        "timeout_count": timeout_count,
        "vclk_t0": local0[key(0x80)], "vclk_t1": local1[key(0x80)],
        "sav_t0": local0[key(0x84)], "sav_t1": local1[key(0x84)],
        "frame_t0": local0[key(0x60)], "frame_t1": local1[key(0x60)],
        **activity,
        "result": f"{prefix}_NVP_PASS" if passed else f"{prefix}_NVP_FAIL",
    }


def first_error_consistency(log: dict[str, Any]) -> str:
    records = log.get("records", [])
    if log.get("nack_count", 0) == 0:
        return "NOT_APPLICABLE_NO_NACK"
    if not records:
        return "FAIL_NACK_WITHOUT_LOG_RECORD"
    first = records[0]
    comparisons = (
        log.get("first_error_valid") == 1,
        log.get("first_error_code") == first.get("phase_code"),
        log.get("first_error_step") == first.get("operation_index"),
        log.get("first_error_metadata_bank") == first.get("metadata_bank"),
        log.get("first_error_register") == first.get("register"),
        log.get("first_error_data") == first.get("data"),
        log.get("first_error_physical_bank") == first.get("physical_bank"),
    )
    return "PASS" if all(comparisons) else "FAIL"


def summarize_log(log: dict[str, Any]) -> dict[str, Any]:
    records = list(log.get("records", []))
    phases = Counter(record["phase_name"] for record in records)
    operations = Counter(str(record["operation_index"]) for record in records)
    banks_registers = Counter(
        f"phys=0x{record['physical_bank']:02X}/meta=0x{record['metadata_bank']:02X}/"
        f"reg=0x{record['register']:02X}" for record in records
    )
    phase_codes = {record["phase_code"] for record in records}
    operation_ids = {record["operation_index"] for record in records}
    if not records:
        concentration = "NO_LOGGED_NACKS"
    elif len(phase_codes) == 1 and len(operation_ids) == 1:
        concentration = "CONCENTRATED_SINGLE_PHASE_AND_OPERATION"
    elif len(phase_codes) == 1:
        concentration = "CONCENTRATED_SINGLE_PHASE_MULTIPLE_OPERATIONS"
    elif len(operation_ids) == 1:
        concentration = "MULTIPLE_PHASES_SINGLE_OPERATION"
    else:
        concentration = "DISPERSED_ACROSS_PHASES_AND_OPERATIONS"
    if log.get("log_overflow"):
        concentration += "_FIRST_8_ONLY"
    return {
        "aggregate_nack_count": log.get("nack_count"),
        "timeout_count": log.get("timeout_count"),
        "log_count": log.get("log_count"),
        "log_overflow": log.get("log_overflow"),
        "log_capacity": log.get("log_capacity"),
        "completeness": ("FIRST_8_RECORDS_ONLY" if log.get("log_overflow")
                         else "COMPLETE_NON_OVERFLOWING_BOUNDED_LOG"),
        "header_consistency": log.get("header_consistency"),
        "first_error_consistency": first_error_consistency(log),
        "phase_distribution": dict(sorted(phases.items())),
        "operation_distribution": dict(sorted(operations.items(), key=lambda item: int(item[0]))),
        "bank_register_distribution": dict(sorted(banks_registers.items())),
        "concentration": concentration,
        "address_phase_nack_observed": any(record["phase_code"] == 1 for record in records),
        "non_address_phase_nack_observed": any(record["phase_code"] in (2, 3, 4)
                                                for record in records),
        "records": records,
    }


def lifecycle_summary(snapshot: dict[str, Any]) -> dict[str, Any]:
    lifecycle = snapshot.get("lifecycle")
    require(isinstance(lifecycle, dict), "Arm A lifecycle record is absent")
    actual = int(lifecycle["actual"])
    expected = int(lifecycle["expected"])
    require(expected == EXPECTED_COUNT,
            f"Arm A expected lifecycle count is {expected}, not {EXPECTED_COUNT}")
    signed = actual - expected
    shortening = max(expected - actual, 0)
    extension = max(actual - expected, 0)
    nearest = round(shortening / TICK_CYCLES)
    result = {
        "actual": actual,
        "expected": expected,
        "signed_error_cycles": signed,
        "shortening_cycles": shortening,
        "extension_cycles": extension,
        "shortening_ticks_exact": shortening / TICK_CYCLES,
        "shortening_ticks_nearest": nearest,
        "shortening_residual_cycles": shortening - nearest * TICK_CYCLES,
    }
    for field in ("actual", "expected", "signed_error_cycles", "shortening_cycles",
                  "extension_cycles", "shortening_ticks_nearest",
                  "shortening_residual_cycles"):
        require(lifecycle.get(field) == result[field],
                f"reader lifecycle field {field} disagrees with independent analysis")
    require(math.isclose(float(lifecycle.get("shortening_ticks_exact")),
                         result["shortening_ticks_exact"], rel_tol=0, abs_tol=1e-12),
            "reader shortening_ticks_exact disagrees with independent analysis")
    return result


def probe_summary(snapshot: dict[str, Any]) -> dict[str, Any]:
    page = snapshot["r1e_page"]
    count = page[key(0x2068)]
    ack = page[key(0x206C)]
    nack = page[key(0x2070)]
    timeout = page[key(0x2074)]
    status = page[key(0x2078)]
    valid = (bool(status & 1) and not bool(status & 2) and not bool(status & 4)
             and count == PROBE_TARGET and ack + nack == count and timeout == 0)
    require(valid, "Arm A probe invariants failed")
    lower, upper = wilson95(nack, count)
    return {
        "done": bool(status & 1), "aborted": bool(status & 2),
        "active": bool(status & 4), "status_raw": f"0x{status:08X}",
        "count": count, "ack_count": ack, "nack_count": nack,
        "timeout_count": timeout,
        "nack_rate": nack / count,
        "nack_rate_ppm": 1_000_000 * nack / count,
        "wilson95_lower": lower, "wilson95_upper": upper,
        "exact_zero_count_upper95": 1 - 0.05 ** (1 / count) if nack == 0 else None,
        "rule_of_three_upper_approx": 3 / count if nack == 0 else None,
        "first_nack_index": page[key(0x207C)],
        "last_nack_index": page[key(0x2080)],
        "max_consecutive_nacks": page[key(0x2084)],
        "valid": True,
    }


def auto_control_flow(lifecycle: dict[str, Any], arm_a_log: dict[str, Any]) -> str:
    if lifecycle["shortening_cycles"] == 0:
        return "NOT_APPLICABLE"
    if arm_a_log["log_overflow"]:
        return "PARTIAL_FIRST_8_ONLY"
    # The aggregate telemetry does not encode taken/not-taken branch history.
    # Without a separate exact FSM replay artifact, multiple decompositions
    # must remain explicit rather than being forced to YES.
    return "NON_UNIQUE"


def combined_classification(probe: dict[str, Any], log: dict[str, Any]) -> dict[str, str]:
    records = log["records"]
    phase_count = len({record["phase_code"] for record in records})
    operation_count = len({record["operation_index"] for record in records})
    dispersed = phase_count > 1 and operation_count > 1
    concentrated_non_address = (bool(records) and
                                not log["address_phase_nack_observed"] and
                                (phase_count == 1 or operation_count == 1))

    if probe["nack_count"] > 0 and dispersed:
        stochastic = "STRONGLY_SUPPORTED"
        operation_context = "WEAKENED_AS_OPERATION_SPECIFIC_ONLY"
    elif probe["nack_count"] > 0 and concentrated_non_address:
        stochastic = "POSSIBLE_MIXED_WITH_OPERATION_CONTEXT"
        operation_context = "POSSIBLE_MIXED_WITH_STOCHASTIC_COMPONENT"
    elif probe["nack_count"] > 0:
        stochastic = "SUPPORTED_BY_POST_INIT_ADDRESS_PROBE"
        operation_context = "UNRESOLVED"
    elif concentrated_non_address:
        stochastic = "NOT_SUPPORTED_BY_ZERO_OF_10000_POST_INIT_ADDRESS_PROBES"
        operation_context = "SUPPORTED"
    elif log["address_phase_nack_observed"]:
        stochastic = "STATIC_POST_INIT_ADDRESS_PATH_FAILURE_WEAKENED"
        operation_context = "SUPPORTED_AS_CONTEXT_DEPENDENT"
    else:
        stochastic = "NOT_SUPPORTED_BY_ZERO_OF_10000_POST_INIT_ADDRESS_PROBES"
        operation_context = "UNRESOLVED"

    if probe["nack_count"] == 0 and log["address_phase_nack_observed"]:
        context_dependence = "SUPPORTED"
    elif probe["nack_count"] == 0 and not records:
        context_dependence = "NOT_DEMONSTRATED"
    else:
        context_dependence = "UNRESOLVED"

    return {
        "stochastic_address_or_bus_margin": stochastic,
        "autoinit_operation_or_phase_context": operation_context,
        "post_init_versus_autoinit_context_dependence": context_dependence,
        "post_init_address_reliability": (
            "STRONGLY_SUPPORTED_IN_THIS_SAMPLE_ZERO_OF_10000"
            if probe["nack_count"] == 0 else "NOT_SUPPORTED_NONZERO_NACK_RATE"
        ),
    }


def analyze(arm_a_document: dict[str, Any], arm_b_document: dict[str, Any],
            control_flow_override: str = "AUTO") -> dict[str, Any]:
    arm_a_t0, arm_a_t1 = validate_reader_pair(arm_a_document, "arm_a")
    arm_b_t0, arm_b_t1 = validate_reader_pair(arm_b_document, "arm_b")
    lifecycle = lifecycle_summary(arm_a_t0)
    probe = probe_summary(arm_a_t0)
    arm_a_log = summarize_log(arm_a_t0["ordered_nack"])
    arm_b_log = summarize_log(arm_b_t0["ordered_nack"])
    arm_a_nvp = nvp_functional_result(arm_a_t0, arm_a_t1, "R1E")
    arm_b_nvp = nvp_functional_result(arm_b_t0, arm_b_t1, "FORMAL")

    auto = auto_control_flow(lifecycle, arm_a_log)
    if control_flow_override == "AUTO":
        control_flow = auto
    else:
        control_flow = control_flow_override
        if arm_a_log["log_overflow"]:
            require(control_flow == "PARTIAL_FIRST_8_ONLY",
                    "overflowing log permits only PARTIAL_FIRST_8_ONLY")
        if lifecycle["shortening_cycles"] == 0:
            require(control_flow == "NOT_APPLICABLE",
                    "zero shortening permits only NOT_APPLICABLE")

    classifications = combined_classification(probe, arm_a_log)
    classifications.update({
        "paired_ab_result": "COMPLETE_VALID_PAIRED_SAMPLE",
        "control_flow_shortening_explained_by_log": control_flow,
        "root_cause_solely_proven": "NO",
        "board_vcco_droop_proven": "NO",
        "ground_bounce_proven": "NO",
        "analog_margin_directly_measured": "NO",
    })
    return {
        "schema": "V41_NVP_R1E_R4_ANALYSIS_V1",
        "arm_a": {
            "instrumentation_valid": True,
            "lifecycle": lifecycle,
            "ordered_nack": arm_a_log,
            "probe": probe,
            "nvp": arm_a_nvp,
        },
        "arm_b": {
            "instrumentation_valid": True,
            "ordered_nack": arm_b_log,
            "nvp": arm_b_nvp,
            "r1e_page_zero": True,
            "formal_lifecycle_counter": "NOT_IMPLEMENTED",
        },
        "classifications": classifications,
        "limitations": {
            "ordered_log_capacity_records": 8,
            "overflow_means": "FIRST_8_RECORDS_ONLY",
            "probe_scope": "POST_AUTOINIT_WRITE_ADDRESS_ACK_AT_25KHZ_ONLY",
            "probe_is_active": True,
            "probe_writes_nvp_register_or_data": False,
            "implementation_placement_change_possible": True,
            "analog_voltage_or_rise_time_measured": False,
        },
    }


def format_distribution(distribution: dict[str, int]) -> str:
    if not distribution:
        return "NONE"
    return ", ".join(f"{name}:{count}" for name, count in distribution.items())


def markdown_report(result: dict[str, Any]) -> str:
    arm_a = result["arm_a"]
    arm_b = result["arm_b"]
    lifecycle = arm_a["lifecycle"]
    probe = arm_a["probe"]
    classifications = result["classifications"]
    lines = [
        "# R4 telemetry analysis", "",
        "This output is derived only from the two saved read-only T0/T1 reader captures.", "",
        "## Arm A lifecycle", "",
        f"- Actual `CNT_AT_INIT_DONE`: {lifecycle['actual']}",
        f"- Expected count: {lifecycle['expected']}",
        f"- Signed error: {lifecycle['signed_error_cycles']} cycles",
        f"- Shortening: {lifecycle['shortening_cycles']} cycles "
        f"({lifecycle['shortening_ticks_exact']:.12g} ticks; nearest "
        f"{lifecycle['shortening_ticks_nearest']}, residual "
        f"{lifecycle['shortening_residual_cycles']} cycles)",
        f"- Extension: {lifecycle['extension_cycles']} cycles", "",
        "## Ordered NACK evidence", "",
        "| Arm | Aggregate | Logged | Overflow | Completeness | Phase distribution | Operation distribution |",
        "|---|---:|---:|---:|---|---|---|",
    ]
    for label, arm in (("A", arm_a), ("B", arm_b)):
        log = arm["ordered_nack"]
        lines.append(
            f"| {label} | {log['aggregate_nack_count']} | {log['log_count']} | "
            f"{log['log_overflow']} | {log['completeness']} | "
            f"{format_distribution(log['phase_distribution'])} | "
            f"{format_distribution(log['operation_distribution'])} |"
        )
    lines.extend([
        "", "## Arm A address probe", "",
        f"- N/ACK/NACK/timeout: {probe['count']} / {probe['ack_count']} / "
        f"{probe['nack_count']} / {probe['timeout_count']}",
        f"- NACK rate: {probe['nack_rate']:.12g} ({probe['nack_rate_ppm']:.12g} ppm)",
        f"- Wilson 95% interval: [{probe['wilson95_lower']:.12g}, "
        f"{probe['wilson95_upper']:.12g}]",
        f"- First/last/max consecutive NACK: {probe['first_nack_index']} / "
        f"{probe['last_nack_index']} / {probe['max_consecutive_nacks']}", "",
        "## Functional and combined classifications", "",
        f"- Arm A NVP result: `{arm_a['nvp']['result']}`",
        f"- Arm B NVP result: `{arm_b['nvp']['result']}`",
    ])
    for name, value in classifications.items():
        lines.append(f"- `{name.upper()}={value}`")
    lines.extend([
        "", "## Required limitations", "",
        "The ordered log holds at most eight records; overflow exposes only the first eight. "
        "The active, non-register-writing probe measures only post-autoinit 25-kHz "
        "write-address ACK behavior. It does not measure register/data/read-address phases "
        "or analog voltage/rise time. The added implementation may affect placement/routing.", "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--arm-a", type=Path, required=True,
                        help="saved Arm-A read_nvp_r1e.py JSON or command log")
    parser.add_argument("--arm-b", type=Path, required=True,
                        help="saved Arm-B read_nvp_r1e.py JSON or command log")
    parser.add_argument("--output-json", type=Path, required=True)
    parser.add_argument("--output-markdown", type=Path, required=True)
    parser.add_argument(
        "--control-flow-reconciliation",
        choices=("AUTO", "YES", "PARTIAL_FIRST_8_ONLY", "NON_UNIQUE",
                 "CONTRADICTION", "NOT_APPLICABLE"),
        default="AUTO",
        help="exact FSM replay result; AUTO is conservative and never asserts YES",
    )
    args = parser.parse_args()
    result = analyze(extract_reader_document(args.arm_a),
                     extract_reader_document(args.arm_b),
                     args.control_flow_reconciliation)
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_markdown.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                                encoding="utf-8", newline="\n")
    args.output_markdown.write_text(markdown_report(result),
                                    encoding="utf-8", newline="\n")
    print(f"ANALYSIS_JSON={args.output_json}")
    print(f"ANALYSIS_MARKDOWN={args.output_markdown}")
    print("ANALYSIS_GATE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
