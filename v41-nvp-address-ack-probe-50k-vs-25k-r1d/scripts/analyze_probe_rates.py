#!/usr/bin/env python3
"""Self-contained aggregate-binomial analysis for the R1d probe pair."""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass

Z95 = 1.959963984540054
Z90 = 1.6448536269514722
ABS_MARGIN = 0.0025
RR_LOW_MARGIN = 0.80
RR_HIGH_MARGIN = 1.25


def wilson(x: int, n: int, z: float) -> tuple[float, float]:
    if n <= 0:
        raise ValueError("n must be positive")
    p = x / n
    z2 = z * z
    den = 1 + z2 / n
    center = (p + z2 / (2 * n)) / den
    half = z * math.sqrt(p * (1 - p) / n + z2 / (4 * n * n)) / den
    return max(0.0, center - half), min(1.0, center + half)


def newcombe_difference(x25: int, n25: int, x50: int, n50: int,
                        z: float) -> tuple[float, float]:
    l25, u25 = wilson(x25, n25, z)
    l50, u50 = wilson(x50, n50, z)
    return l25 - u50, u25 - l50


def katz_rr(x25: float, n25: float, x50: float, n50: float,
            z: float) -> tuple[float, float, float]:
    p25 = x25 / n25
    p50 = x50 / n50
    rr = p25 / p50
    variance = 1 / x25 - 1 / n25 + 1 / x50 - 1 / n50
    half = z * math.sqrt(max(0.0, variance))
    return rr, math.exp(math.log(rr) - half), math.exp(math.log(rr) + half)


def log_choose(n: int, k: int) -> float:
    if k < 0 or k > n:
        return float("-inf")
    return math.lgamma(n + 1) - math.lgamma(k + 1) - math.lgamma(n - k + 1)


def fisher(x25: int, n25: int, x50: int, n50: int) -> tuple[float, float]:
    total_x = x25 + x50
    total_n = n25 + n50
    lo = max(0, total_x - n50)
    hi = min(n25, total_x)
    base = log_choose(total_n, total_x)

    def probability(k: int) -> float:
        return math.exp(log_choose(n25, k) + log_choose(n50, total_x - k) - base)

    observed = probability(x25)
    probs = [(k, probability(k)) for k in range(lo, hi + 1)]
    two_sided = sum(p for _, p in probs if p <= observed * (1 + 1e-12))
    one_sided_less = sum(p for k, p in probs if k <= x25)
    return min(1.0, two_sided), min(1.0, one_sided_less)


@dataclass
class Analysis:
    values: dict[str, object]


def analyze(n50: int, x50: int, n25: int, x25: int) -> Analysis:
    if n50 <= 0 or n25 <= 0 or not (0 <= x50 <= n50) or not (0 <= x25 <= n25):
        raise ValueError("require positive N and 0 <= X <= N")
    p50, p25 = x50 / n50, x25 / n25
    w50 = wilson(x50, n50, Z95)
    w25 = wilson(x25, n25, Z95)
    diff95 = newcombe_difference(x25, n25, x50, n50, Z95)
    diff90 = newcombe_difference(x25, n25, x50, n50, Z90)
    fisher_two, fisher_less = fisher(x25, n25, x50, n50)

    rr_method = "KATZ_LOG"
    rr_secondary = False
    if x50 > 0 and x25 > 0:
        rr, rr95_lo, rr95_hi = katz_rr(x25, n25, x50, n50, Z95)
        _, rr90_lo, rr90_hi = katz_rr(x25, n25, x50, n50, Z90)
    else:
        rr = (float("nan") if x50 == 0 and x25 == 0
              else float("inf") if x50 == 0 else 0.0)
        rr_cc, rr95_lo, rr95_hi = katz_rr(x25 + 0.5, n25 + 1,
                                           x50 + 0.5, n50 + 1, Z95)
        _, rr90_lo, rr90_hi = katz_rr(x25 + 0.5, n25 + 1,
                                      x50 + 0.5, n50 + 1, Z90)
        rr_method = "HALDANE_ANSCOMBE_CONTINUITY_CORRECTED_SECONDARY"
        rr_secondary = True

    abs_equiv = diff90[0] > -ABS_MARGIN and diff90[1] < ABS_MARGIN
    rel_equiv = x50 > 0 and x25 > 0 and rr90_lo > RR_LOW_MARGIN and rr90_hi < RR_HIGH_MARGIN
    equivalence = abs_equiv and rel_equiv

    if x50 == 0 and x25 == 0:
        classification = "BOTH_RATES_BELOW_DETECTION_LIMIT"
    elif x50 > 0 and rr <= 0.50 and rr95_hi < 1.0:
        classification = "STRONGLY_SUPPORTED_SINGLE_PAIRED_SAMPLE"
    elif x50 > 0 and rr > 0.50 and rr95_hi < 1.0:
        classification = "SUPPORTED_SINGLE_PAIRED_SAMPLE_LESS_THAN_TWOFOLD"
    elif x50 > 0 and x25 > 0 and rr95_lo > 1.0:
        classification = "CONTRADICTORY_25KHZ_WORSE"
    elif equivalence:
        classification = "NO_MATERIAL_EFFECT_WITHIN_PREDECLARED_EQUIVALENCE_MARGIN"
    else:
        classification = "INCONCLUSIVE_SINGLE_PAIRED_SAMPLE"

    values: dict[str, object] = {
        "N50": n50, "X50": x50, "N25": n25, "X25": x25,
        "P50": p50, "P25": p25,
        "P50_PERCENT": 100 * p50, "P25_PERCENT": 100 * p25,
        "P50_PER_1000": 1000 * p50, "P25_PER_1000": 1000 * p25,
        "P50_WILSON_95_LOW": w50[0], "P50_WILSON_95_HIGH": w50[1],
        "P25_WILSON_95_LOW": w25[0], "P25_WILSON_95_HIGH": w25[1],
        "P25_MINUS_P50": p25 - p50,
        "DIFF_NEWCOMBE_95_LOW": diff95[0], "DIFF_NEWCOMBE_95_HIGH": diff95[1],
        "DIFF_NEWCOMBE_90_LOW": diff90[0], "DIFF_NEWCOMBE_90_HIGH": diff90[1],
        "RATE_RATIO_P25_OVER_P50": rr,
        "RATE_RATIO_95_LOW": rr95_lo, "RATE_RATIO_95_HIGH": rr95_hi,
        "RATE_RATIO_90_LOW": rr90_lo, "RATE_RATIO_90_HIGH": rr90_hi,
        "RATE_RATIO_INTERVAL_METHOD": rr_method,
        "RATE_RATIO_INTERVAL_SECONDARY": rr_secondary,
        "FISHER_EXACT_TWO_SIDED_P": fisher_two,
        "ONE_SIDED_P25_LESS_THAN_P50_P": fisher_less,
        "ZERO_50_EXACT_ONE_SIDED_95_UPPER": 1 - 0.05 ** (1 / n50) if x50 == 0 else "NA",
        "ZERO_25_EXACT_ONE_SIDED_95_UPPER": 1 - 0.05 ** (1 / n25) if x25 == 0 else "NA",
        "EQUIVALENCE_ABSOLUTE_90": abs_equiv,
        "EQUIVALENCE_RELATIVE_90": rel_equiv,
        "EQUIVALENCE_RESULT": equivalence,
        "ABSOLUTE_RATE_DIFFERENCE_MARGIN": ABS_MARGIN,
        "RELATIVE_RATE_RATIO_MARGIN": "0.80_TO_1.25",
        "SERIAL_CORRELATION_MEASURED": "NO",
        "BINOMIAL_CONFIDENCE_INTERVALS": "NOMINAL_CONDITIONAL_ON_INDEPENDENCE",
        "ADDRESS_ACK_FREQUENCY_EFFECT": classification,
    }
    return Analysis(values)


def format_value(value: object) -> str:
    if isinstance(value, float):
        if math.isnan(value):
            return "UNDEFINED"
        if math.isinf(value):
            return "INFINITY"
        return f"{value:.12g}"
    if isinstance(value, bool):
        return "YES" if value else "NO"
    return str(value)


def self_test() -> None:
    fixtures = [
        (10000, 0, 10000, 0),
        (10000, 100, 10000, 50),
        (10000, 100, 10000, 100),
        (10000, 10, 10000, 20),
        (10000, 10000, 10000, 10000),
    ]
    for fixture in fixtures:
        result = analyze(*fixture)
        assert result.values["P50"] == fixture[1] / fixture[0]
        assert result.values["P25"] == fixture[3] / fixture[2]
        assert 0 <= result.values["FISHER_EXACT_TWO_SIDED_P"] <= 1
        print("FIXTURE_PASS", fixture, result.values["ADDRESS_ACK_FREQUENCY_EFFECT"])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("N50", type=int, nargs="?")
    parser.add_argument("X50", type=int, nargs="?")
    parser.add_argument("N25", type=int, nargs="?")
    parser.add_argument("X25", type=int, nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if None in (args.N50, args.X50, args.N25, args.X25):
        parser.error("N50 X50 N25 X25 are required unless --self-test is used")
    result = analyze(args.N50, args.X50, args.N25, args.X25)
    for key, value in result.values.items():
        print(f"{key}={format_value(value)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
