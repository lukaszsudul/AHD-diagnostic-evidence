#!/usr/bin/env python3
"""Offline-only fixtures for the R1f decoder and frozen statistics."""

from __future__ import annotations

import itertools
import contextlib
import io
import json
import math
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[1]
TOOLS = REPOSITORY / "scripts" / "v41"
sys.path.insert(0, str(TOOLS))

import r1f_statistics as stats  # noqa: E402
import read_nvp_r1f as reader  # noqa: E402


SCENARIO = json.loads((HERE / "fixtures" / "r1f_valid_scenario.json").read_text(
    encoding="utf-8"))


def set_field(value: int, low: int, width: int, field: int) -> int:
    mask = ((1 << width) - 1) << low
    return (value & ~mask) | ((field << low) & mask)


def make_legacy_detail(events: list[dict[str, int]]) -> dict[int, int]:
    value = 0
    value = set_field(value, 128, 16, len(events))
    value = set_field(value, 192, 4, min(len(events), 8))
    value = set_field(value, 196, 1, int(len(events) > 8))
    value = set_field(value, 216, 8, 8)
    for index, event in enumerate(events[:8]):
        raw = (
            event["operation"] |
            (event["phase"] << 8) |
            (event["register"] << 16) |
            (event["data"] << 24) |
            (event["physical_bank"] << 32) |
            (event["metadata_bank"] << 40) |
            (1 << 48) | (1 << 49)
        )
        value = set_field(value, 224 + index * 64, 64, raw)
    return {offset: (value >> (32 * index)) & 0xFFFFFFFF
            for index, offset in enumerate(reader.LEGACY_DETAIL_OFFSETS)}


def sequence_metrics(indices: list[int], n: int = 10000) -> tuple[int, int, int]:
    event_set = set(indices)
    adjacent = sum(index - 1 in event_set for index in indices if index)
    runs = 1 + sum(((index in event_set) != (index - 1 in event_set))
                   for index in range(1, n))
    maximum = 0
    current = 0
    for index in range(n):
        if index in event_set:
            current += 1
            maximum = max(maximum, current)
        else:
            current = 0
    return maximum, adjacent, runs


def set_index_log(words: dict[int, int], base: int, indices: list[int]) -> None:
    for ordinal, value in enumerate(indices):
        address = base + 4 * (ordinal // 2)
        words[address] = words.get(address, 0) | (value << (16 * (ordinal & 1)))


def set_probe_block(words: dict[int, int], name: str, base: int, index_base: int,
                    indices: list[int]) -> None:
    nacks = len(indices)
    words[base] = 0x1F if nacks else 0x07
    if name == "WADDR":
        attempts = 10000
    elif name == "REGADDR":
        attempts = 10002
        words[base + 0x08] = attempts
        words[base + 0x0C] = 10000
        words[base + 0x10] = 2
    else:
        attempts = 10000
        words[base + 0x08] = 10000
        words[base + 0x0C] = 10000
        words[base + 0x14] = 10000
        words[base + 0x18] = 10000
    words[base + 0x04] = attempts
    words[base + 0x20] = 10000
    words[base + 0x24] = 10000 - nacks
    words[base + 0x28] = nacks
    words[base + 0x30] = indices[0] if indices else 0
    words[base + 0x34] = indices[-1] if indices else 0
    maximum, adjacent, runs = sequence_metrics(indices)
    words[base + 0x38] = maximum
    words[base + 0x3C] = adjacent
    words[base + 0x40] = runs
    words[base + 0x44] = nacks
    for index in indices:
        block = index // 1000
        words[base + 0x4C + 4 * block] = words.get(base + 0x4C + 4 * block, 0) + 1
    set_index_log(words, index_base, indices)


def make_valid_words() -> dict[int, int]:
    words: dict[int, int] = dict(reader.EXPECTED_HEADER)
    # Preserved R1e lifecycle/probe page.
    words.update({
        0x2000: 0x314B4C43, 0x2004: 1,
        0x2014: 132584734, 0x2018: 0,
        0x2040: 0x31453152, 0x2044: 1,
        0x204C: 25000, 0x2050: 1251,
        0x2054: 132584734, 0x2058: 0,
        0x2064: 10000, 0x2068: 10000,
        0x206C: 9999, 0x2070: 1, 0x2074: 0, 0x2078: 1,
    })
    events = [
        {"operation": 5, "phase": phase, "register": 0x10, "data": 0x20,
         "physical_bank": 0, "metadata_bank": 0}
        for phase in (1, 2, 3)
    ]
    words.update(make_legacy_detail(events))
    words.update({
        0x20E0: 6, 0x20E4: 1,
        0x20E8: 5, 0x20EC: 1,
        0x20F0: 4, 0x20F4: 1,
        0x20F8: 2, 0x20FC: 0,
        0x2100: 4, 0x2104: 4, 0x2108: 1, 0x210C: 0,
        0x2110: 0xF, 0x2114: 3, 0x2118: 3, 0x211C: 0x7,
        0x2120: 1, 0x2124: 1, 0x2128: 0,
        0x212C: 10, 0x2130: 10, 0x2134: 0x7B, 0x2138: 11,
        0x213C: 100, 0x2140: 0, 0x2144: 0, 0x2148: 0x100,
        0x214C: 0x3FB, 0x2150: 0, 0x2154: 0x7FF,
        0x2158: 0x100, 0x215C: 0x100,
        0x2160: 0x109, 0x2164: 0x309,
        0x2168: 100, 0x216C: 0, 0x2170: 200, 0x2174: 0,
    })
    # One failed INIT_TARGET_WRITE transaction with W/R/D NACK events.
    record = [
        10 | (1 << 16),
        5 | (1 << 8) | (6 << 12) | (7 << 16) | (7 << 20) |
        (3 << 24) | (1 << 28) | (1 << 29),
        0x10 | (0x20 << 8) | (0x1B << 24),
        0,
        (1 << 16) | (10 << 24),
        1,
    ]
    for index, value in enumerate(record):
        words[0x2400 + 4 * index] = value
    probes = SCENARIO["probe_nack_indices_zero_based"]
    for name, (base, index_base) in reader.PROBE_PHASES.items():
        set_probe_block(words, name, base, index_base, list(probes[name]))
    words.update({
        0x2380: 0x3FB, 0x2384: 10002,
        0x2388: sum(words[base + 0x04] for base, _ in reader.PROBE_PHASES.values()),
        0x238C: 0, 0x2390: 0, 0x2394: 0,
        0x2398: 0x109, 0x239C: 0x300,
        0x23A0: 0x300, 0x23A4: 0x700, 0x23A8: 0x309,
        0x23AC: 0x1F, 0x23B0: 0x7, 0x23B4: 3,
        0x23B8: 0, 0x23BC: 0,
    })
    return words


class R1FDecoderTests(unittest.TestCase):
    def test_valid_complete_sample_and_nullable_fields(self) -> None:
        decoded = reader.decode_word_map(make_valid_words())
        self.assertEqual(decoded["image"], "r1f")
        self.assertEqual(decoded["legacy_reconciliation"]["result"], "PASS")
        self.assertEqual(decoded["failed_transaction_log"]["records"][0]
                         ["transaction_index_16"], 10)
        self.assertIsNone(decoded["failed_transaction_log"]["records"][0]["read_data"])
        self.assertEqual(decoded["probe"]["phases"]["REGADDR"]
                         ["nack_indices_analysis_one_based"], [11, 12])

    def test_version_gate_and_all_ones_identity_rejected(self) -> None:
        words = make_valid_words()
        words[0x20A4] = 2
        with self.assertRaisesRegex(reader.R1FDecodeError, "header"):
            reader.decode_word_map(words)
        words = make_valid_words()
        for address in reader.EXPECTED_HEADER:
            words[address] = 0xFFFFFFFF
        with self.assertRaisesRegex(reader.R1FDecodeError, "all-ones"):
            reader.decode_word_map(words)

    def test_record_valid_bits_reserved_and_unused_zero_enforced(self) -> None:
        words = make_valid_words()
        words[0x2408] |= 1 << 26  # read_data_valid on write kind
        with self.assertRaisesRegex(reader.R1FDecodeError, "write kind"):
            reader.decode_word_map(words)
        words = make_valid_words()
        words[0x2418] = 1
        with self.assertRaisesRegex(reader.R1FDecodeError, "unused"):
            reader.decode_word_map(words)

    def test_count_overflow_contract_and_legacy_reconciliation_enforced(self) -> None:
        words = make_valid_words()
        words[0x2120] = 2
        with self.assertRaisesRegex(reader.R1FDecodeError, "failed-transaction total"):
            reader.decode_word_map(words)
        words = make_valid_words()
        # Change the first inherited register byte only.
        value = sum(words.get(offset, 0) << (32 * index)
                    for index, offset in enumerate(reader.LEGACY_DETAIL_OFFSETS))
        value = set_field(value, 224 + 16, 8, 0x11)
        words.update({offset: (value >> (32 * index)) & 0xFFFFFFFF
                      for index, offset in enumerate(reader.LEGACY_DETAIL_OFFSETS)})
        with self.assertRaisesRegex(reader.R1FDecodeError, "reconciliation"):
            reader.decode_word_map(words)

    def test_consistent_65_failure_overflow_decodes_but_is_scientifically_invalid(self) -> None:
        words = make_valid_words()
        events = [{"operation": index, "phase": 1, "register": 0x10,
                   "data": 0x20, "physical_bank": 0, "metadata_bank": 0}
                  for index in range(65)]
        words.update(make_legacy_detail(events))
        words.update({
            0x20E0: 65, 0x20E4: 65,
            0x20E8: 0, 0x20EC: 0, 0x20F0: 0, 0x20F4: 0,
            0x20F8: 0, 0x20FC: 0,
            0x2100: 65, 0x2104: 65, 0x2108: 65,
            0x2114: 65, 0x2118: 65,
            0x2120: 65, 0x2124: 64, 0x2128: 1,
            0x212C: 0, 0x2130: 64, 0x2134: 0x7F, 0x2138: 65,
        })
        for entry in range(64):
            record = [
                entry | (entry << 16),
                entry | (1 << 8) | (6 << 12) | (1 << 16) | (1 << 20) |
                (1 << 24) | (1 << 28) | (1 << 29),
                0x10 | (0x20 << 8) | (0x1B << 24),
                0,
                (1 << 16) | (10 << 24),
                entry & 0xFF,
            ]
            for word_index, value in enumerate(record):
                words[0x2400 + entry * 0x18 + word_index * 4] = value
        decoded = reader.decode_word_map(words, require_scientific_valid=False)
        self.assertTrue(decoded["failed_transaction_log"]["overflow"])
        self.assertEqual(decoded["legacy_reconciliation"]["result"], "PASS")
        with self.assertRaisesRegex(reader.R1FDecodeError, "overflow"):
            reader.validate_scientific_sample(decoded)

    def test_probe_index_and_block_reconciliation_enforced(self) -> None:
        words = make_valid_words()
        words[0x2A00] = 3
        with self.assertRaisesRegex(reader.R1FDecodeError, "first/last"):
            reader.decode_word_map(words)
        words = make_valid_words()
        words[0x2200 + 0x4C] = 2
        with self.assertRaisesRegex(reader.R1FDecodeError, "block NACK sum"):
            reader.decode_word_map(words)

    def test_formal_complete_r1f_range_must_be_zero(self) -> None:
        decoded = reader.decode_word_map({}, expect="formal")
        self.assertTrue(decoded["r1f_reserved_range_zero"])
        with self.assertRaisesRegex(reader.R1FDecodeError, "deterministic zero"):
            reader.decode_word_map({0x35FC: 1}, expect="formal")

    def test_output_set_and_no_mmio_write_primitive(self) -> None:
        words = make_valid_words()
        decoded = reader.decode_word_map(words)
        with tempfile.TemporaryDirectory() as directory:
            reader.write_outputs(decoded, words, Path(directory))
            required = {
                "decoded.json", "raw_mmio_inventory.csv", "decoded_flat.csv",
                "failed_transactions.csv", "phase_opportunities.csv",
                "probe_per_phase.csv", "probe_blocks.csv", "probe_nack_indices.csv",
                "bank_invariant_report.json", "lifecycle_calculation.json",
            }
            self.assertEqual(required, {path.name for path in Path(directory).iterdir()})
        source = (TOOLS / "read_nvp_r1f.py").read_text(encoding="utf-8")
        for forbidden in ("os.pwrite", "os.write(", "O_RDWR", "O_WRONLY"):
            self.assertNotIn(forbidden, source)

    def test_offline_cli_sparse_word_map(self) -> None:
        words = make_valid_words()
        payload = {"words": {f"0x{address:X}": f"0x{value:08X}"
                             for address, value in words.items()}}
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "words.json"
            fixture.write_text(json.dumps(payload), encoding="utf-8")
            output = Path(directory) / "decoded"
            with contextlib.redirect_stdout(io.StringIO()) as captured:
                result = reader.main(("--input-json", str(fixture), "--expect", "r1f",
                                      "--twice", "--output-dir", str(output)))
            self.assertEqual(result, 0)
            self.assertIn("READ_ONLY=YES", captured.getvalue())
            self.assertTrue((output / "decoded.json").is_file())


class R1FStatisticsTests(unittest.TestCase):
    def test_wilson_and_holm(self) -> None:
        low, high = stats.wilson95(0, 10000)
        self.assertEqual(low, 0.0)
        self.assertGreater(high, 0)
        adjusted = stats.holm_adjust({"a": 0.01, "b": 0.04, "c": 0.03})
        self.assertAlmostEqual(adjusted["a"], 0.03)
        self.assertAlmostEqual(adjusted["b"], 0.06)
        self.assertAlmostEqual(adjusted["c"], 0.06)

    @staticmethod
    def brute_binary_distribution(n: int, k: int) -> list[tuple[int, int]]:
        result = []
        for selected in itertools.combinations(range(n), k):
            values = [int(index in selected) for index in range(n)]
            runs = 1 + sum(values[index] != values[index - 1]
                           for index in range(1, n))
            adjacent = sum(values[index] and values[index - 1]
                           for index in range(1, n))
            result.append((runs, adjacent))
        return result

    def test_runs_and_adjacent_exact_match_bruteforce(self) -> None:
        n, k, observed_runs, observed_adjacent = 7, 3, 4, 1
        distribution = self.brute_binary_distribution(n, k)
        expected_runs = 1 + 2 * k * (n - k) / n
        runs_p = sum(abs(r - expected_runs) >= abs(observed_runs - expected_runs)
                     for r, _ in distribution) / len(distribution)
        expected_adjacent = k * (k - 1) / n
        adjacent_p = sum(abs(j - expected_adjacent) >=
                         abs(observed_adjacent - expected_adjacent)
                         for _, j in distribution) / len(distribution)
        self.assertAlmostEqual(stats.exact_runs_test(n, k, observed_runs), runs_p)
        self.assertAlmostEqual(
            stats.exact_adjacent_pair_test(n, k, observed_adjacent), adjacent_p)

    def test_equal_block_exact_matches_bruteforce(self) -> None:
        observed = [2, 0]
        pvalue = stats.exact_equal_block_homogeneity(observed, block_size=2)
        allocations = []
        for selected in itertools.combinations(range(4), 2):
            counts = [sum(index < 2 for index in selected),
                      sum(index >= 2 for index in selected)]
            allocations.append(sum(value * value for value in counts))
        expected = sum(value >= sum(x * x for x in observed)
                       for value in allocations) / len(allocations)
        self.assertAlmostEqual(pvalue, expected)

    def test_fisher_and_ffh_exact(self) -> None:
        self.assertAlmostEqual(stats.fisher_exact_greater(2, 4, 0, 4), 3 / 14)
        two_row = stats.exact_rx2_probability_ordering([2, 0], [4, 4])
        rxc = stats.exact_rxc_probability_ordering([[2, 2], [0, 4]])
        self.assertAlmostEqual(two_row, rxc)

    def test_primary_confidence_intervals_and_zero_rules(self) -> None:
        difference = 10 / 100 - 2 / 100
        low, high = stats.miettinen_nurminen_difference_ci(10, 100, 2, 100)
        self.assertLess(low, difference)
        self.assertGreater(high, difference)
        rr = stats.profile_rate_ratio_ci(10, 100, 2, 100)
        self.assertAlmostEqual(rr["point"], 5.0)
        self.assertLess(rr["lower"], 5.0)
        self.assertGreater(rr["upper"], 5.0)
        zero = stats.profile_rate_ratio_ci(0, 100, 0, 100)
        self.assertEqual(zero["point_label"], "NOT_IDENTIFIABLE_0_OVER_0")
        self.assertTrue(math.isinf(zero["upper"]))

    def test_global_27_holm_and_paired_direction(self) -> None:
        panels = {}
        for run in range(1, 4):
            for phase in stats.PHASES3:
                panels[f"A{run}_{phase}"] = {
                    "raw_p": {"block_homogeneity": 1.0,
                              "runs": 1.0, "adjacent_pairs": 1.0},
                    "informative": True,
                }
        result = stats.classify_stationarity_panels(panels)
        self.assertEqual(result["planned_test_count"], 27)
        self.assertTrue(all(value == "COMPATIBLE_WITH_STATIONARY_MEMORYLESS_PROCESS"
                            for value in result["final_by_phase"].values()))
        paired = stats.paired_direction([13, 14, 12], [15, 16, 18])
        self.assertEqual(paired["label"], "DIRECTION_REPEATABLE_3_OF_3")
        self.assertEqual(paired["one_sided_sign_p"], 0.125)
        self.assertEqual(paired["two_sided_sign_p"], 0.25)

    def test_probe_index_overflow_keeps_block_rate_but_disables_sequence_tests(self) -> None:
        partial = list(range(5))
        blocks = [1] * 6 + [0] * 4
        panel = stats.analyze_probe_panel(
            partial, 10, blocks, index_overflow=True, aggregate_nacks=6)
        self.assertEqual(panel["nacks"], 6)
        self.assertEqual(panel["raw_p"]["runs"], 1.0)
        self.assertEqual(panel["raw_p"]["adjacent_pairs"], 1.0)
        self.assertFalse(panel["sequence_complete"])
        self.assertFalse(panel["informative"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
