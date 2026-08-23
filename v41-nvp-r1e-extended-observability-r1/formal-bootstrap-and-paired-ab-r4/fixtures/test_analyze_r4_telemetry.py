#!/usr/bin/env python3
"""Offline unit fixtures for analyze_r4_telemetry.py."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "analyze_r4_telemetry.py"
SPEC = importlib.util.spec_from_file_location("r4_analysis", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
ANALYSIS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ANALYSIS)


def k(offset: int) -> str:
    return f"0x{offset:05X}"


def record(index: int, phase: int, operation: int) -> dict:
    names = {1: "WRITE_ADDRESS_ACK", 2: "REGISTER_ADDRESS_ACK",
             3: "DATA_ACK", 4: "READ_ADDRESS_ACK"}
    return {
        "index": index, "raw": "0x0001000000000000",
        "operation_index": operation, "phase_code": phase,
        "phase_name": names[phase], "register": 0x20 + operation,
        "data": 0x40 + operation, "physical_bank": 1,
        "metadata_bank": 1, "valid": 1, "physical_bank_valid": 1,
        "reserved": 0,
    }


def ordered(records: list[dict], aggregate: int | None = None,
            overflow: int = 0) -> dict:
    aggregate = len(records) if aggregate is None else aggregate
    first = records[0] if records else None
    return {
        "phase": 0, "operation_index": 0, "table_length": 0,
        "first_error_valid": 1 if first else 0,
        "first_error_code": first["phase_code"] if first else 0,
        "first_error_step": first["operation_index"] if first else 0,
        "first_error_metadata_bank": first["metadata_bank"] if first else 0,
        "first_error_register": first["register"] if first else 0,
        "first_error_data": first["data"] if first else 0,
        "first_error_physical_bank": first["physical_bank"] if first else 0,
        "nack_count": aggregate, "timeout_count": 0,
        "i2c_state": 0, "original_ff": 0, "restored_ff": 0,
        "log_count": len(records), "log_overflow": overflow,
        "physical_bank_valid": 1, "current_metadata_bank": 1,
        "current_physical_bank": 1, "log_capacity": 8,
        "header_consistency": "PASS",
        "control_flow_replay_scope": (
            "PARTIAL_FIRST_8_RECORDS_ONLY" if overflow else "COMPLETE_LOG_AVAILABLE"),
        "records": records,
    }


def make_snapshot(image: str, records: list[dict], probe_nacks: int = 0,
                  aggregate: int | None = None, overflow: int = 0,
                  activity_delta: int = 0, shortening: int = 1_251) -> dict:
    local = {k(offset): 0 for offset in range(0, 0xE4, 4)}
    local[k(0x60)] = 100 + activity_delta
    local[k(0x80)] = 200 + activity_delta
    local[k(0x84)] = 300 + activity_delta
    local[k(0x8C)] = 0x39 if not records else 0x3B
    local[k(0x90)] = len(records) if aggregate is None else aggregate
    page = {k(offset): 0 for offset in range(0x2000, 0x2100, 4)}
    lifecycle = None
    probe_stats = None
    if image == "arm_a":
        page.update({
            k(0x2000): ANALYSIS.R1E_MAGIC, k(0x2004): 1,
            k(0x2040): ANALYSIS.R1E_EXTENSION_MAGIC, k(0x2044): 1,
            k(0x204C): 25_000, k(0x2050): ANALYSIS.TICK_CYCLES,
            k(0x2054): ANALYSIS.EXPECTED_COUNT, k(0x2058): 0,
            k(0x2064): ANALYSIS.PROBE_TARGET,
            k(0x2068): ANALYSIS.PROBE_TARGET,
            k(0x206C): ANALYSIS.PROBE_TARGET - probe_nacks,
            k(0x2070): probe_nacks, k(0x2074): 0, k(0x2078): 1,
            k(0x207C): 0xFFFFFFFF if probe_nacks == 0 else 7,
            k(0x2080): 0xFFFFFFFF if probe_nacks == 0 else 9000,
            k(0x2084): 0 if probe_nacks == 0 else 1,
        })
        actual = ANALYSIS.EXPECTED_COUNT - shortening
        lifecycle = {
            "actual": actual, "expected": ANALYSIS.EXPECTED_COUNT,
            "signed_error_cycles": -shortening,
            "shortening_cycles": shortening, "extension_cycles": 0,
            "shortening_ticks_exact": shortening / ANALYSIS.TICK_CYCLES,
            "shortening_ticks_nearest": round(shortening / ANALYSIS.TICK_CYCLES),
            "shortening_residual_cycles": (
                shortening - round(shortening / ANALYSIS.TICK_CYCLES) *
                ANALYSIS.TICK_CYCLES),
        }
        low, high = ANALYSIS.wilson95(probe_nacks, ANALYSIS.PROBE_TARGET)
        probe_stats = {"rate": probe_nacks / ANALYSIS.PROBE_TARGET,
                       "rate_ppm": 100 * probe_nacks,
                       "wilson95_lower": low, "wilson95_upper": high,
                       "rule_of_three_upper_approx": (
                           3 / ANALYSIS.PROBE_TARGET if probe_nacks == 0 else None)}
    detail = ordered(records, aggregate, overflow)
    return {
        "local": local, "r1e_page": page,
        "legacy_nack_raw_17_words": ["0x00000000"] * 17,
        "ordered_nack": detail, "lifecycle": lifecycle,
        "probe_statistics": probe_stats, "coherent_freerun": 12345,
    }


def pair(image: str, records: list[dict], **kwargs) -> dict:
    first = make_snapshot(image, records, activity_delta=0, **kwargs)
    second = make_snapshot(image, records, activity_delta=1, **kwargs)
    return {"T0": first, "T1": second}


class R4AnalysisFixtures(unittest.TestCase):
    def test_zero_probe_with_autoinit_address_nack_is_context_dependent(self) -> None:
        arm_a = pair("arm_a", [record(0, 1, 10)], probe_nacks=0)
        arm_b = pair("arm_b", [record(0, 2, 20)])
        result = ANALYSIS.analyze(arm_a, arm_b)
        self.assertEqual(result["classifications"][
            "post_init_versus_autoinit_context_dependence"], "SUPPORTED")
        self.assertEqual(result["arm_a"]["probe"]["nack_count"], 0)
        self.assertEqual(result["classifications"]["root_cause_solely_proven"], "NO")

    def test_nonzero_probe_and_dispersed_log_supports_stochastic_margin(self) -> None:
        arm_a = pair("arm_a", [record(0, 1, 10), record(1, 3, 20)],
                     probe_nacks=2)
        arm_b = pair("arm_b", [])
        result = ANALYSIS.analyze(arm_a, arm_b)
        self.assertEqual(result["classifications"][
            "stochastic_address_or_bus_margin"], "STRONGLY_SUPPORTED")

    def test_overflow_forces_partial_control_flow_classification(self) -> None:
        records = [record(index, 2, index) for index in range(8)]
        arm_a = pair("arm_a", records, aggregate=12, overflow=1)
        arm_b = pair("arm_b", [])
        result = ANALYSIS.analyze(arm_a, arm_b)
        self.assertEqual(result["classifications"][
            "control_flow_shortening_explained_by_log"], "PARTIAL_FIRST_8_ONLY")
        with self.assertRaises(ANALYSIS.AnalysisError):
            ANALYSIS.analyze(arm_a, arm_b, "YES")

    def test_probe_invariant_failure_is_rejected(self) -> None:
        arm_a = pair("arm_a", [], probe_nacks=0)
        arm_a["T0"]["r1e_page"][k(0x2068)] = 9999
        arm_a["T1"]["r1e_page"][k(0x2068)] = 9999
        arm_b = pair("arm_b", [])
        with self.assertRaises(ANALYSIS.AnalysisError):
            ANALYSIS.analyze(arm_a, arm_b)

    def test_reader_document_extraction_from_command_log(self) -> None:
        document = pair("arm_b", [])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.log"
            path.write_text("PREFIX\n" + json.dumps(document) +
                            "\nREAD_ONLY=YES\nSTATIC_SNAPSHOTS_MATCH=YES\n",
                            encoding="utf-8")
            extracted = ANALYSIS.extract_reader_document(path)
        self.assertEqual(extracted, document)


if __name__ == "__main__":
    unittest.main(verbosity=2)
