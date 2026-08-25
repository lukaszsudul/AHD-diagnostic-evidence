#!/usr/bin/env python3
"""Independent frozen R1h-R4 statistical analysis.

This driver does not contact hardware or mutate repositories.  It loads the
exact frozen R1f/R1h statistical module by absolute path after verifying its
published SHA-256, parses the six completed read-only telemetry receipts, and
writes deterministic analysis artifacts beneath final/analysis only.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import math
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any


TASK_ROOT = Path(r"C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST")
OUT = TASK_ROOT / "final" / "analysis"
HARDWARE = TASK_ROOT / "hardware"
FROZEN_STATS = Path(
    r"C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE"
    r"\scripts\v41\r1f_statistics.py"
)
FROZEN_STATS_SHA256 = "C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD"
PHASES3 = ("WADDR", "REGADDR", "DATA")
PHASES4 = (*PHASES3, "RADDR")
ARM_DIRS = {"A1": "02_A1", "A2": "04_A2", "A3": "06_A3"}
CONTROL_DIRS = {"B1": "03_B1", "B2": "05_B2", "B3": "07_B3"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def load_frozen_stats():
    observed = sha256(FROZEN_STATS)
    if observed != FROZEN_STATS_SHA256:
        raise RuntimeError(
            f"frozen statistics hash mismatch: {observed} != {FROZEN_STATS_SHA256}"
        )
    spec = importlib.util.spec_from_file_location("r1h_frozen_statistics", FROZEN_STATS)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load frozen statistical module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def extract_telemetry(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8-sig")
    if "RESULT=PASS" not in text or "EXIT_CODE=0" not in text:
        raise RuntimeError(f"telemetry wrapper did not pass: {path}")
    begin = text.index("STDOUT_BEGIN") + len("STDOUT_BEGIN")
    end = text.index("STDOUT_END", begin)
    stdout = text[begin:end]
    json_begin = stdout.index("{")
    json_end = stdout.rindex("}") + 1
    return json.loads(stdout[json_begin:json_end])


def clean_json(value: Any) -> Any:
    if isinstance(value, float) and not math.isfinite(value):
        return "+INF" if value > 0 else "-INF"
    if isinstance(value, dict):
        return {str(k): clean_json(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [clean_json(v) for v in value]
    return value


def category(value: Any) -> str:
    return "NULL" if value is None else str(value)


def record_compositions(records: list[dict[str, Any]]) -> dict[str, dict[str, int]]:
    fields: dict[str, list[str]] = {
        "HIGH_LEVEL_PHASE": [category(r["autoinit_phase"]) for r in records],
        "TRANSACTION_KIND": [category(r["transaction_kind"]) for r in records],
        "PHASE_NACK_BITMAP": [f"0x{int(r['phase_nack_bitmap']):X}" for r in records],
        "TABLE_SLOT": [category(r["table_slot_index_16"]) for r in records],
        "REQUESTED_BANK": [category(r["requested_bank"]) for r in records],
        "VALID_PHYSICAL_BANK_BEFORE": [
            category(r["physical_bank_before"])
            if r["valid_bits"]["physical_bank_before"]
            else "INVALID"
            for r in records
        ],
    }
    return {name: dict(sorted(Counter(values).items())) for name, values in fields.items()}


def classify_nvp_a(run: str, data: dict[str, Any]) -> str:
    audit_candidates = sorted((HARDWARE / ARM_DIRS[run]).glob("INDEPENDENT*AUDIT.md"))
    for path in audit_candidates:
        text = path.read_text(encoding="utf-8-sig")
        match = re.search(rf"^{run}_NVP_RESULT=(.+)$", text, flags=re.MULTILINE)
        if match:
            return match.group(1).strip()
    # Deterministic fallback mirrors the accepted audit classification.
    header = data["T0"]["header"]
    return (
        "R1H_NVP_FAIL_VALID_SCIENTIFIC_RESULT"
        if int(header.get("init_error", 0)) or int(data["T0"]["phase_counters"]["legacy_aggregate_nacks"])
        else "R1H_NVP_PASS_VALID_SCIENTIFIC_RESULT"
    )


def classify_nvp_b(run: str, data: dict[str, Any]) -> str:
    audit = HARDWARE / CONTROL_DIRS[run] / "INDEPENDENT_FORMAL_CONTROL_AUDIT.md"
    if audit.exists():
        text = audit.read_text(encoding="utf-8-sig")
        match = re.search(rf"^{run}_NVP_RESULT=(.+)$", text, flags=re.MULTILINE)
        if match:
            return match.group(1).strip()
    # B3 uses the same complete formal exposure and observed failing aggregate.
    return (
        "FORMAL_NVP_FAIL_VALID_SCIENTIFIC_RESULT"
        if int(data["T0"]["ordered_nack"]["nack_count"]) > 0
        else "FORMAL_NVP_PASS_VALID_SCIENTIFIC_RESULT"
    )


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    stats = load_frozen_stats()

    a_json = {
        run: extract_telemetry(HARDWARE / directory / "TELEMETRY_EVIDENCE.log")
        for run, directory in ARM_DIRS.items()
    }
    b_json = {
        run: extract_telemetry(HARDWARE / directory / "TELEMETRY_EVIDENCE.log")
        for run, directory in CONTROL_DIRS.items()
    }

    inputs: dict[str, dict[str, Any]] = {}
    for run, directory in {**ARM_DIRS, **CONTROL_DIRS}.items():
        phase_dir = HARDWARE / directory
        required = [phase_dir / "TELEMETRY_EVIDENCE.log"]
        if run.startswith("A"):
            required.append(phase_dir / "VALID_ARM_A_RECEIPT.txt")
            required.extend(sorted(phase_dir.glob("INDEPENDENT*AUDIT.md")))
        else:
            required.append(phase_dir / "FORMAL_READY_RECEIPT.txt")
            required.extend(sorted(phase_dir.glob("INDEPENDENT_FORMAL_CONTROL_AUDIT.md")))
        for path in required:
            if not path.exists():
                raise RuntimeError(f"required evidence missing: {path}")
            rel = path.relative_to(TASK_ROOT).as_posix()
            inputs[rel] = {"bytes": path.stat().st_size, "sha256": sha256(path)}

    panels: dict[str, dict[str, Any]] = {}
    arm_a: dict[str, dict[str, Any]] = {}
    context_input: dict[str, dict[str, dict[str, int]]] = {}
    autoinit_input: dict[str, dict[str, dict[str, int]]] = {}
    per_phase_rows: list[dict[str, Any]] = []
    autoinit_rows: list[dict[str, Any]] = []
    failed_rows: list[dict[str, Any]] = []

    for run in ("A1", "A2", "A3"):
        document = a_json[run]
        if document.get("READ_ONLY") != "YES" or document.get("STATIC_SNAPSHOTS_MATCH") != "YES":
            raise RuntimeError(f"{run} telemetry is not a coherent read-only pair")
        t0 = document["T0"]
        phase_counters = t0["phase_counters"]
        probe = t0["probe"]
        failed = t0["failed_transaction_log"]
        if int(t0["bank_invariants"]["error_count"]) != 0:
            raise RuntimeError(f"{run} bank-invariant contradiction")
        if int(failed["total"]) != int(failed["stored"]) or bool(failed["overflow"]):
            raise RuntimeError(f"{run} failed-log integrity failure")

        autoinit = {
            phase: {
                "nacks": int(phase_counters[phase]["nacks"]),
                "opportunities": int(phase_counters[phase]["opportunities"]),
            }
            for phase in PHASES4
        }
        for phase in PHASES4:
            item = autoinit[phase]
            item["acks"] = item["opportunities"] - item["nacks"]
            item["rate"] = item["nacks"] / item["opportunities"]
            item["ppm"] = 1_000_000 * item["rate"]
            item["wilson95"] = stats.wilson95(item["nacks"], item["opportunities"])
            autoinit_rows.append({
                "run": run,
                "phase": phase,
                "opportunities": item["opportunities"],
                "ACK": item["acks"],
                "NACK": item["nacks"],
                "rate": item["rate"],
                "ppm": item["ppm"],
                "wilson95_low": item["wilson95"][0],
                "wilson95_high": item["wilson95"][1],
            })
        probe_summary: dict[str, dict[str, int]] = {}
        context_input[run] = {}
        autoinit_input[run] = autoinit
        for phase in PHASES3:
            item = probe["phases"][phase]
            n = int(item["target_opportunities"])
            k = int(item["target_nacks"])
            timeouts = int(item["timeouts"])
            indices = [int(v) for v in item["nack_indices_raw_zero_based"]]
            block_nacks = [int(v) for v in item["block_nacks"]]
            panel = stats.analyze_probe_panel(
                indices,
                n,
                block_nacks=block_nacks,
                index_overflow=bool(item["index_overflow"]),
                aggregate_nacks=k,
            )
            panel["timeouts"] = timeouts
            panel["hardware_binary_run_count"] = int(item["binary_run_count"])
            panel["hardware_adjacent_nack_pairs"] = int(item["adjacent_nack_pairs"])
            panel["hardware_max_consecutive_nacks"] = int(item["max_consecutive_nacks"])
            if panel["run_count"] != panel["hardware_binary_run_count"]:
                raise RuntimeError(f"{run}/{phase} binary-run mismatch")
            if panel["adjacent_pairs"] != panel["hardware_adjacent_nack_pairs"]:
                raise RuntimeError(f"{run}/{phase} adjacent-pair mismatch")
            if panel["maximum_consecutive_nacks"] != panel["hardware_max_consecutive_nacks"]:
                raise RuntimeError(f"{run}/{phase} maximum-run mismatch")
            panels[f"{run}_{phase}"] = panel
            probe_summary[phase] = {"nacks": k, "opportunities": n, "timeouts": timeouts}
            context_input[run][phase] = {
                "autoinit_nacks": autoinit[phase]["nacks"],
                "autoinit_opportunities": autoinit[phase]["opportunities"],
                "probe_nacks": k,
                "probe_opportunities": n,
            }
            low, high = panel["wilson95"]
            per_phase_rows.append({
                "run": run,
                "phase": phase,
                "N": n,
                "ACK": int(panel["acks"]),
                "NACK": k,
                "timeout": timeouts,
                "rate": panel["rate"],
                "ppm": panel["ppm"],
                "wilson95_low": low,
                "wilson95_high": high,
                "first_nack_zero_based": panel["first_raw_zero_based"],
                "last_nack_zero_based": panel["last_raw_zero_based"],
                "adjacent_pairs": panel["adjacent_pairs"],
                "run_count": panel["run_count"],
                "max_consecutive_nacks": panel["maximum_consecutive_nacks"],
                "block_nacks": ";".join(str(v) for v in block_nacks),
                "block_rates": ";".join(str(v / 1000) for v in block_nacks),
            })

        compositions = record_compositions(failed["records"])
        for family, counts in compositions.items():
            for key, count in counts.items():
                failed_rows.append({"run": run, "family": family, "category": key, "count": count})
        arm_a[run] = {
            "autoinit": autoinit,
            "probe": probe_summary,
            "failed_transactions": int(phase_counters["transactions"]["failed"]),
            "transaction_starts": int(phase_counters["transactions"]["starts"]),
            "compositions": compositions,
            "bank_invariant_errors": int(t0["bank_invariants"]["error_count"]),
            "nvp_result": classify_nvp_a(run, document),
            "legacy_aggregate_nacks": int(phase_counters["legacy_aggregate_nacks"]),
            "failed_log_total": int(failed["total"]),
            "failed_log_stored": int(failed["stored"]),
            "failed_log_overflow": bool(failed["overflow"]),
        }

    b_summary: dict[str, dict[str, Any]] = {}
    for run in ("B1", "B2", "B3"):
        document = b_json[run]
        t0 = document["T0"]
        ordered = t0["ordered_nack"]
        r1e_values = list(t0["r1e_page"].values())
        b_summary[run] = {
            "nack_count": int(ordered["nack_count"]),
            "timeout_count": int(ordered["timeout_count"]),
            "operation_index": int(ordered["operation_index"]),
            "phase": int(ordered["phase"]),
            "table_length": int(ordered["table_length"]),
            "diagnostic_range_all_zero": all(int(v) == 0 for v in r1e_values),
            "nvp_result": classify_nvp_b(run, document),
        }

    stationarity = stats.classify_stationarity_panels(panels)
    for row in per_phase_rows:
        panel_name = f"{row['run']}_{row['phase']}"
        panel = panels[panel_name]
        row["block_homogeneity_raw_p"] = panel["raw_p"]["block_homogeneity"]
        row["runs_raw_p"] = panel["raw_p"]["runs"]
        row["adjacent_pairs_raw_p"] = panel["raw_p"]["adjacent_pairs"]
        row["block_homogeneity_holm_p"] = stationarity["adjusted_p"][
            f"{panel_name}:block_homogeneity"
        ]
        row["runs_holm_p"] = stationarity["adjusted_p"][f"{panel_name}:runs"]
        row["adjacent_pairs_holm_p"] = stationarity["adjusted_p"][
            f"{panel_name}:adjacent_pairs"
        ]
        row["stationarity_independence_classification"] = stationarity["panels"][panel_name]
    autoinit_heterogeneity = stats.analyze_autoinit_heterogeneity(autoinit_input)
    context_elevation = stats.analyze_context_elevation(context_input)
    b_counts = {run: item["nack_count"] for run, item in b_summary.items()}
    formal_exposure_equal = len({
        (item["operation_index"], item["phase"], item["table_length"], item["timeout_count"])
        for item in b_summary.values()
    }) == 1
    replicate_homogeneity = stats.analyze_replicate_homogeneity(
        arm_a, b_counts, formal_exposure_equal=formal_exposure_equal
    )
    paired = stats.paired_direction(
        [arm_a[run]["legacy_aggregate_nacks"] for run in ("A1", "A2", "A3")],
        [b_summary[run]["nack_count"] for run in ("B1", "B2", "B3")],
    )
    failed_distribution = stats.classify_failed_distribution(
        {run: arm_a[run]["compositions"]["TRANSACTION_KIND"] for run in ("A1", "A2", "A3")}
    )
    bank_coherence = stats.classify_bank_coherence(
        [arm_a[run]["bank_invariant_errors"] for run in ("A1", "A2", "A3")]
    )

    total_probe_opportunities = sum(
        arm_a[run]["probe"][phase]["opportunities"]
        for run in ("A1", "A2", "A3") for phase in PHASES3
    )
    total_probe_nacks = sum(
        arm_a[run]["probe"][phase]["nacks"]
        for run in ("A1", "A2", "A3") for phase in PHASES3
    )
    total_probe_timeouts = sum(
        arm_a[run]["probe"][phase]["timeouts"]
        for run in ("A1", "A2", "A3") for phase in PHASES3
    )
    if total_probe_opportunities != 90000:
        raise RuntimeError(f"target opportunity audit failed: {total_probe_opportunities}")
    if any(row["N"] != 10000 for row in per_phase_rows):
        raise RuntimeError("a planned probe panel does not have exactly N=10000")

    pooled_wilson = stats.wilson95(total_probe_nacks, total_probe_opportunities)
    phase_pooled: dict[str, Any] = {}
    for phase in PHASES3:
        k = sum(arm_a[run]["probe"][phase]["nacks"] for run in ("A1", "A2", "A3"))
        n = sum(arm_a[run]["probe"][phase]["opportunities"] for run in ("A1", "A2", "A3"))
        phase_pooled[phase] = {"nacks": k, "opportunities": n, "wilson95": stats.wilson95(k, n)}

    autoinit_totals = {
        phase: {
            "nacks": sum(arm_a[run]["autoinit"][phase]["nacks"] for run in ("A1", "A2", "A3")),
            "opportunities": sum(
                arm_a[run]["autoinit"][phase]["opportunities"] for run in ("A1", "A2", "A3")
            ),
        }
        for phase in PHASES4
    }
    for phase, item in autoinit_totals.items():
        item["rate"] = item["nacks"] / item["opportunities"]
        item["wilson95"] = stats.wilson95(item["nacks"], item["opportunities"])

    classifications = {
        "POSTINIT_WADDR_PROCESS": stationarity["final_by_phase"]["WADDR"],
        "POSTINIT_REGADDR_PROCESS": stationarity["final_by_phase"]["REGADDR"],
        "POSTINIT_DATA_PROCESS": stationarity["final_by_phase"]["DATA"],
        "AUTOINIT_PHASE_RATE_HETEROGENEITY": autoinit_heterogeneity["classification"],
        "AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR": context_elevation["classification_by_phase"]["WADDR"],
        "AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR": context_elevation["classification_by_phase"]["REGADDR"],
        "AUTOINIT_CONTEXT_RATE_ELEVATION_DATA": context_elevation["classification_by_phase"]["DATA"],
        "R1H_REPLICATE_HOMOGENEITY": replicate_homogeneity["classification"],
        "BANK_TRACKER_COHERENCE": bank_coherence,
        "FAILED_TRANSACTION_DISTRIBUTION": failed_distribution,
        "PAIRED_AB_RESULT": paired["label"],
        "ROOT_CAUSE_SOLELY_PROVEN": "NO",
        "BOARD_VCCO_DROOP_PROVEN": "NO",
        "GROUND_BOUNCE_PROVEN": "NO",
        "ANALOG_MARGIN_DIRECTLY_MEASURED": "NO",
    }

    result = {
        "schema": "R1H_R4_FROZEN_ANALYSIS_V1",
        "method": {
            "frozen_statistics_path": str(FROZEN_STATS),
            "frozen_statistics_sha256": FROZEN_STATS_SHA256,
            "context_support_rule": {
                "holm_adjusted_p_less_than": 0.01,
                "rate_ratio_lower_95_greater_than": 2.0,
                "same_direction_minimum_runs": 2,
            },
        },
        "input_evidence": inputs,
        "arm_a": arm_a,
        "arm_b": b_summary,
        "probe_panels": panels,
        "stationarity": stationarity,
        "autoinit_heterogeneity": autoinit_heterogeneity,
        "context_elevation": context_elevation,
        "replicate_homogeneity": replicate_homogeneity,
        "paired_direction": paired,
        "accounting": {
            "panel_count": len(per_phase_rows),
            "target_opportunities": total_probe_opportunities,
            "target_acks": total_probe_opportunities - total_probe_nacks,
            "target_nacks": total_probe_nacks,
            "target_timeouts": total_probe_timeouts,
            "pooled_wilson95": pooled_wilson,
            "phase_pooled": phase_pooled,
            "autoinit_totals": autoinit_totals,
            "failed_transactions_total": sum(
                arm_a[run]["failed_transactions"] for run in ("A1", "A2", "A3")
            ),
            "transaction_starts_total": sum(
                arm_a[run]["transaction_starts"] for run in ("A1", "A2", "A3")
            ),
            "formal_nacks_total": sum(b_counts.values()),
            "formal_exposure_equal": formal_exposure_equal,
            "opportunity_audit": "PASS_90000_OF_90000",
        },
        "classifications": classifications,
    }

    result_path = OUT / "R1H_R4_FROZEN_ANALYSIS.json"
    with result_path.open("w", encoding="utf-8", newline="\n") as stream:
        json.dump(clean_json(result), stream, indent=2, sort_keys=True)
        stream.write("\n")

    phase_csv = OUT / "R1H_R4_PER_PHASE_RESULTS.csv"
    with phase_csv.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(per_phase_rows[0]))
        writer.writeheader()
        writer.writerows(per_phase_rows)

    context_csv = OUT / "R1H_R4_AUTOINIT_CONTEXT_COMPARISONS.csv"
    context_rows: list[dict[str, Any]] = []
    for run in ("A1", "A2", "A3"):
        for phase in PHASES3:
            item = context_elevation["comparisons"][run][phase]
            rr = item["rate_ratio_profile_ci95"]
            diff_ci = item["difference_ci95_miettinen_nurminen"]
            context_rows.append({
                "run": run,
                "phase": phase,
                "autoinit_nacks": context_input[run][phase]["autoinit_nacks"],
                "autoinit_opportunities": context_input[run][phase]["autoinit_opportunities"],
                "probe_nacks": context_input[run][phase]["probe_nacks"],
                "probe_opportunities": context_input[run][phase]["probe_opportunities"],
                "autoinit_rate": item["autoinit_rate"],
                "probe_rate": item["probe_rate"],
                "rate_difference": item["rate_difference"],
                "difference_ci95_low": diff_ci[0],
                "difference_ci95_high": diff_ci[1],
                "rate_ratio": clean_json(rr["point"]),
                "rate_ratio_ci95_low": rr["lower"],
                "rate_ratio_ci95_high": clean_json(rr["upper"]),
                "fisher_exact_greater_p": item["raw_p_greater"],
                "holm_adjusted_p": item["holm_adjusted_p"],
                "run_support_rule": item["run_support_rule"],
            })
    with context_csv.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(context_rows[0]))
        writer.writeheader()
        writer.writerows(context_rows)

    autoinit_csv = OUT / "R1H_R4_AUTOINIT_PHASE_RESULTS.csv"
    with autoinit_csv.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(autoinit_rows[0]))
        writer.writeheader()
        writer.writerows(autoinit_rows)

    failed_csv = OUT / "R1H_R4_FAILED_TRANSACTION_COMPOSITIONS.csv"
    with failed_csv.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=("run", "family", "category", "count"))
        writer.writeheader()
        writer.writerows(failed_rows)

    output_paths = (result_path, phase_csv, autoinit_csv, context_csv, failed_csv)
    receipt_path = OUT / "R1H_R4_INDEPENDENT_ANALYSIS_RECEIPT.txt"
    lines = [
        "TASK=V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE",
        "ANALYSIS_RESULT=PASS_FROZEN_PLAN_COMPLETE",
        f"ANALYSIS_DRIVER_SHA256={sha256(Path(__file__))}",
        f"FROZEN_STATISTICS_SHA256={FROZEN_STATS_SHA256}",
        "FROZEN_STATISTICS_HASH_GATE=PASS",
        "ARM_A_VALID_RECEIPTS=PASS_3_OF_3",
        "ARM_B_FORMAL_READY_RECEIPTS=PASS_3_OF_3",
        f"TARGET_OPPORTUNITY_AUDIT={result['accounting']['opportunity_audit']}",
        f"TARGET_ACKS={result['accounting']['target_acks']}",
        f"TARGET_NACKS={result['accounting']['target_nacks']}",
        f"TARGET_TIMEOUTS={result['accounting']['target_timeouts']}",
        f"FAILED_TRANSACTIONS_TOTAL={result['accounting']['failed_transactions_total']}",
        f"FORMAL_NACKS_TOTAL={result['accounting']['formal_nacks_total']}",
    ]
    lines.extend(f"{key}={value}" for key, value in classifications.items())
    for path in output_paths:
        lines.append(f"OUTPUT_SHA256[{path.name}]={sha256(path)}")
    for rel, item in sorted(inputs.items()):
        lines.append(f"INPUT_SHA256[{rel}]={item['sha256']}")
    receipt_path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    print(json.dumps({
        "result": "PASS_FROZEN_PLAN_COMPLETE",
        "classifications": classifications,
        "accounting": result["accounting"],
        "outputs": {path.name: sha256(path) for path in (*output_paths, receipt_path)},
    }, indent=2, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
