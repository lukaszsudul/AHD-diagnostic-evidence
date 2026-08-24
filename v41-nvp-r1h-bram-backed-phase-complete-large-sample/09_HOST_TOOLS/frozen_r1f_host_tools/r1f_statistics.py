#!/usr/bin/env python3
"""Frozen primary statistical methods for v41 R1f.

Only Python's standard library is used.  Exact tests are deterministic full-
probability tests (never mid-p, Monte Carlo, or asymptotic substitutions).
The public functions preserve integer numerators/denominators until the final
reported floating-point probability.
"""

from __future__ import annotations

import math
from fractions import Fraction
from itertools import product
from typing import Any, Iterable, Mapping, Sequence


Z95 = 1.959963984540054
CHI2_1_95 = Z95 * Z95
STATIONARITY_ALPHA = 0.05
CONTEXT_ALPHA = 0.01
PHASES3 = ("WADDR", "REGADDR", "DATA")
PHASES4 = ("WADDR", "REGADDR", "DATA", "RADDR")


class ExactTestResourceError(RuntimeError):
    """An exact enumeration exceeded its declared deterministic state cap."""


def _comb(n: int, k: int) -> int:
    return math.comb(n, k) if 0 <= k <= n else 0


def _validate_binomial(k: int, n: int) -> None:
    if n < 0 or k < 0 or k > n:
        raise ValueError(f"invalid binomial count {k}/{n}")


def wilson95(k: int, n: int) -> tuple[float, float]:
    _validate_binomial(k, n)
    if n == 0:
        raise ValueError("Wilson interval requires a positive denominator")
    p = k / n
    denominator = 1 + Z95 * Z95 / n
    center = (p + Z95 * Z95 / (2 * n)) / denominator
    half = (Z95 / denominator) * math.sqrt(
        p * (1 - p) / n + Z95 * Z95 / (4 * n * n))
    lower = max(0.0, center - half)
    upper = min(1.0, center + half)
    # Preserve the exact boundary implied by the frozen formula despite a
    # sub-ulp cancellation residue in binary floating point.
    if abs(lower) < 1e-15:
        lower = 0.0
    if abs(upper - 1.0) < 1e-15:
        upper = 1.0
    return lower, upper


def holm_adjust(raw: Mapping[str, float], planned: Iterable[str] | None = None) -> dict[str, float]:
    """Holm adjusted p-values; missing planned hypotheses receive raw p=1."""
    keys = list(dict.fromkeys(planned if planned is not None else raw.keys()))
    values: dict[str, float] = {}
    for key in keys:
        value = float(raw.get(key, 1.0))
        if not math.isfinite(value) or value < 0 or value > 1:
            raise ValueError(f"invalid p-value for {key}: {value}")
        values[key] = value
    ordered = sorted(keys, key=lambda key: (values[key], key))
    adjusted: dict[str, float] = {}
    running = 0.0
    m = len(ordered)
    for rank, key in enumerate(ordered):
        running = max(running, (m - rank) * values[key])
        adjusted[key] = min(1.0, running)
    return {key: adjusted[key] for key in keys}


def sequence_metrics(indices_zero_based: Sequence[int], n: int = 10000) -> dict[str, Any]:
    indices = [int(value) for value in indices_zero_based]
    if n < 0 or any(value < 0 or value >= n for value in indices):
        raise ValueError("sequence index outside the fixed target opportunity range")
    if any(left >= right for left, right in zip(indices, indices[1:])):
        raise ValueError("sequence indices must be strictly increasing")
    event_set = set(indices)
    maximum = 0
    streak = 0
    adjacent = 0
    for position in range(n):
        if position in event_set:
            streak += 1
            maximum = max(maximum, streak)
            if position > 0 and position - 1 in event_set:
                adjacent += 1
        else:
            streak = 0
    runs = 0 if n == 0 else 1 + sum(
        ((position in event_set) != (position - 1 in event_set))
        for position in range(1, n))
    blocks = [0] * 10
    if n == 10000:
        for position in indices:
            blocks[position // 1000] += 1
    return {
        "n": n, "nacks": len(indices), "acks": n - len(indices),
        "rate": len(indices) / n if n else None,
        "ppm": 1_000_000 * len(indices) / n if n else None,
        "wilson95": wilson95(len(indices), n) if n else None,
        "first_raw_zero_based": indices[0] if indices else None,
        "last_raw_zero_based": indices[-1] if indices else None,
        "first_analysis_one_based": indices[0] + 1 if indices else None,
        "last_analysis_one_based": indices[-1] + 1 if indices else None,
        "adjacent_pairs": adjacent, "run_count": runs,
        "maximum_consecutive_nacks": maximum, "block_nacks": blocks,
    }


def exact_runs_test(n: int, k: int, observed_runs: int) -> float:
    _validate_binomial(k, n)
    if n == 0:
        raise ValueError("runs test requires positive N")
    z = n - k
    if k == 0 or z == 0:
        return 1.0 if observed_runs == 1 else 0.0
    denominator = _comb(n, k)
    center_numerator = n + 2 * k * z  # n * E[R]
    observed_distance = abs(observed_runs * n - center_numerator)
    tail = 0
    total = 0
    for runs in range(1, n + 1):
        if runs % 2 == 0:
            u = runs // 2
            mass = 2 * _comb(k - 1, u - 1) * _comb(z - 1, u - 1)
        else:
            u = (runs - 1) // 2
            mass = (_comb(k - 1, u) * _comb(z - 1, u - 1) +
                    _comb(k - 1, u - 1) * _comb(z - 1, u))
        if not mass:
            continue
        total += mass
        if abs(runs * n - center_numerator) >= observed_distance:
            tail += mass
    if total != denominator:
        raise ArithmeticError("runs mass did not sum to C(N,K)")
    return tail / denominator


def exact_adjacent_pair_test(n: int, k: int, observed_adjacent_pairs: int) -> float:
    _validate_binomial(k, n)
    if n == 0:
        raise ValueError("adjacent-pair test requires positive N")
    if k == 0:
        return 1.0 if observed_adjacent_pairs == 0 else 0.0
    z = n - k
    denominator = _comb(n, k)
    center_numerator = k * (k - 1)  # n * E[J]
    observed_distance = abs(observed_adjacent_pairs * n - center_numerator)
    tail = 0
    total = 0
    for nack_runs in range(1, min(k, z + 1) + 1):
        mass = _comb(k - 1, nack_runs - 1) * _comb(z + 1, nack_runs)
        adjacent = k - nack_runs
        total += mass
        if abs(adjacent * n - center_numerator) >= observed_distance:
            tail += mass
    if total != denominator:
        raise ArithmeticError("adjacent-pair mass did not sum to C(N,K)")
    return tail / denominator


def exact_equal_block_homogeneity(block_nacks: Sequence[int], block_size: int = 1000,
                                  max_states: int = 2_000_000) -> float:
    """Exact fixed-total equal-block 2-column Pearson tail via integer DP."""
    counts = [int(value) for value in block_nacks]
    if not counts or block_size <= 0:
        raise ValueError("positive equal blocks are required")
    if any(value < 0 or value > block_size for value in counts):
        raise ValueError("block count outside 0..block_size")
    blocks = len(counts)
    n = blocks * block_size
    k = sum(counts)
    if k == 0 or k == n:
        return 1.0
    # Complementing all cells retains the Pearson statistic and keeps the DP
    # dimension on the rarer outcome.
    if k > n // 2:
        counts = [block_size - value for value in counts]
        k = n - k
    observed_sumsq = sum(value * value for value in counts)
    states: dict[tuple[int, int], int] = {(0, 0): 1}
    for completed in range(blocks):
        remaining_blocks = blocks - completed - 1
        updated: dict[tuple[int, int], int] = {}
        for (allocated, sumsq), weight in states.items():
            low = max(0, k - allocated - remaining_blocks * block_size)
            high = min(block_size, k - allocated)
            for value in range(low, high + 1):
                key = (allocated + value, sumsq + value * value)
                updated[key] = updated.get(key, 0) + weight * _comb(block_size, value)
        if len(updated) > max_states:
            raise ExactTestResourceError(
                f"equal-block exact DP exceeded {max_states} states")
        states = updated
    denominator = _comb(n, k)
    total = sum(weight for (allocated, _), weight in states.items() if allocated == k)
    if total != denominator:
        raise ArithmeticError("block-allocation mass did not sum to C(N,K)")
    tail = sum(weight for (allocated, sumsq), weight in states.items()
               if allocated == k and sumsq >= observed_sumsq)
    return tail / denominator


def order_statistic_context(n: int, k: int, alpha: float = 0.05) -> dict[str, Any]:
    _validate_binomial(k, n)
    if k == 0:
        return {"estimable": False, "reason": "NO_EVENTS"}
    denominator = _comb(n, k)

    def min_cdf(m: int) -> float:
        return 1.0 - _comb(n - m, k) / denominator

    def max_cdf(m: int) -> float:
        return _comb(m, k) / denominator

    def quantile(cdf, probability: float, low: int, high: int) -> int:
        while low < high:
            middle = (low + high) // 2
            if cdf(middle) >= probability:
                high = middle
            else:
                low = middle + 1
        return low

    lower_p = alpha / 2
    upper_p = 1 - alpha / 2
    return {
        "estimable": True,
        "expected_min": (n + 1) / (k + 1),
        "expected_max": k * (n + 1) / (k + 1),
        "min_central95": (quantile(min_cdf, lower_p, 1, n - k + 1),
                          quantile(min_cdf, upper_p, 1, n - k + 1)),
        "max_central95": (quantile(max_cdf, lower_p, k, n),
                          quantile(max_cdf, upper_p, k, n)),
    }


def fisher_exact_greater(k1: int, n1: int, k0: int, n0: int) -> float:
    """One-sided Fisher exact p for rate1 > rate0."""
    _validate_binomial(k1, n1)
    _validate_binomial(k0, n0)
    if n1 == 0 or n0 == 0:
        raise ValueError("Fisher comparison requires two positive denominators")
    total_events = k1 + k0
    denominator = _comb(n1 + n0, total_events)
    low = max(0, total_events - n0)
    high = min(n1, total_events)
    tail = sum(_comb(n1, value) * _comb(n0, total_events - value)
               for value in range(max(k1, low), high + 1))
    return tail / denominator


def exact_rx2_probability_ordering(events: Sequence[int], totals: Sequence[int],
                                   max_tables: int = 2_000_000) -> float:
    """Exact Fisher-Freeman-Halton probability-ordering test for Rx2."""
    ks = [int(value) for value in events]
    ns = [int(value) for value in totals]
    if len(ks) != len(ns) or len(ks) < 2:
        raise ValueError("Rx2 test requires equally sized vectors with R>=2")
    for k, n in zip(ks, ns):
        _validate_binomial(k, n)
        if n == 0:
            raise ValueError("zero row denominator makes Rx2 test unestimable")
    total_events = sum(ks)
    denominator = _comb(sum(ns), total_events)
    observed_weight = math.prod(_comb(n, k) for n, k in zip(ns, ks))
    tail = 0
    total = 0
    table_count = 0

    def visit(row: int, remaining: int, weight: int) -> None:
        nonlocal tail, total, table_count
        if row == len(ns) - 1:
            value = remaining
            if 0 <= value <= ns[row]:
                final_weight = weight * _comb(ns[row], value)
                table_count += 1
                if table_count > max_tables:
                    raise ExactTestResourceError(
                        f"Rx2 exact enumeration exceeded {max_tables} tables")
                total += final_weight
                if final_weight <= observed_weight:
                    tail += final_weight
            return
        low = max(0, remaining - sum(ns[row + 1:]))
        high = min(ns[row], remaining)
        for value in range(low, high + 1):
            visit(row + 1, remaining - value, weight * _comb(ns[row], value))

    visit(0, total_events, 1)
    if total != denominator:
        raise ArithmeticError("Rx2 table mass did not sum to fixed-margin denominator")
    return tail / denominator


def _binomial_loglik(k: int, n: int, p: float) -> float:
    if p < 0 or p > 1:
        return -math.inf
    if p == 0:
        return 0.0 if k == 0 else -math.inf
    if p == 1:
        return 0.0 if k == n else -math.inf
    return k * math.log(p) + (n - k) * math.log1p(-p)


def _golden_max(function, low: float, high: float) -> tuple[float, float]:
    if high < low:
        return low, -math.inf
    if high == low:
        return low, function(low)
    ratio = (math.sqrt(5) - 1) / 2
    left = high - ratio * (high - low)
    right = low + ratio * (high - low)
    f_left = function(left)
    f_right = function(right)
    for _ in range(160):
        if f_left < f_right:
            low, left, f_left = left, right, f_right
            right = low + ratio * (high - low)
            f_right = function(right)
        else:
            high, right, f_right = right, left, f_left
            left = high - ratio * (high - low)
            f_left = function(left)
    candidates = ((low, function(low)), (high, function(high)),
                  (left, f_left), (right, f_right))
    return max(candidates, key=lambda item: item[1])


def _constrained_difference_mle(k1: int, n1: int, k0: int, n0: int,
                                difference: float) -> tuple[float, float]:
    low = max(0.0, -difference)
    high = min(1.0, 1.0 - difference)
    if high < low:
        return math.nan, math.nan

    def objective(p0: float) -> float:
        return (_binomial_loglik(k1, n1, p0 + difference) +
                _binomial_loglik(k0, n0, p0))

    p0, _ = _golden_max(objective, low, high)
    return p0 + difference, p0


def _mn_score_statistic(k1: int, n1: int, k0: int, n0: int,
                        difference: float) -> float:
    p1, p0 = _constrained_difference_mle(k1, n1, k0, n0, difference)
    if math.isnan(p0):
        return math.inf
    observed_difference = k1 / n1 - k0 / n0
    correction = (n1 + n0) / (n1 + n0 - 1)
    variance = correction * (p1 * (1 - p1) / n1 + p0 * (1 - p0) / n0)
    numerator = observed_difference - difference
    if variance <= 0:
        return 0.0 if abs(numerator) < 1e-14 else math.inf
    return numerator * numerator / variance


def miettinen_nurminen_difference_ci(k1: int, n1: int, k0: int, n0: int,
                                     confidence: float = 0.95) -> tuple[float, float]:
    """Two-sample MN score interval with the N/(N-1) variance correction."""
    _validate_binomial(k1, n1)
    _validate_binomial(k0, n0)
    if n1 == 0 or n0 == 0:
        raise ValueError("difference interval requires positive denominators")
    if confidence != 0.95:
        raise ValueError("the frozen R1f primary interval is exactly 95%")
    estimate = k1 / n1 - k0 / n0

    def objective(value: float) -> float:
        return _mn_score_statistic(k1, n1, k0, n0, value) - CHI2_1_95

    if objective(-1.0) <= 0:
        lower = -1.0
    else:
        left, right = -1.0, estimate
        for _ in range(100):
            middle = (left + right) / 2
            if objective(middle) > 0:
                left = middle
            else:
                right = middle
        lower = right
    if objective(1.0) <= 0:
        upper = 1.0
    else:
        left, right = estimate, 1.0
        for _ in range(100):
            middle = (left + right) / 2
            if objective(middle) <= 0:
                left = middle
            else:
                right = middle
        upper = left
    return max(-1.0, lower), min(1.0, upper)


def _profile_rr_loglik(k1: int, n1: int, k0: int, n0: int,
                       log_ratio: float) -> float:
    ratio = math.exp(max(-745.0, min(709.0, log_ratio)))
    if ratio >= 1:
        def objective(p1: float) -> float:
            return (_binomial_loglik(k1, n1, p1) +
                    _binomial_loglik(k0, n0, p1 / ratio))
        return _golden_max(objective, 0.0, 1.0)[1]

    def objective(p0: float) -> float:
        return (_binomial_loglik(k1, n1, ratio * p0) +
                _binomial_loglik(k0, n0, p0))
    return _golden_max(objective, 0.0, 1.0)[1]


def profile_rate_ratio_ci(k1: int, n1: int, k0: int, n0: int,
                          confidence: float = 0.95) -> dict[str, Any]:
    _validate_binomial(k1, n1)
    _validate_binomial(k0, n0)
    if n1 == 0 or n0 == 0:
        raise ValueError("rate-ratio interval requires positive denominators")
    if confidence != 0.95:
        raise ValueError("the frozen R1f primary interval is exactly 95%")
    if k1 == 0 and k0 == 0:
        return {"point": None, "point_label": "NOT_IDENTIFIABLE_0_OVER_0",
                "lower": 0.0, "upper": math.inf}
    p1 = k1 / n1
    p0 = k0 / n0
    if p0 == 0:
        point = math.inf
        point_label = "+INF"
    else:
        point = p1 / p0
        point_label = None
    maximum = _binomial_loglik(k1, n1, p1) + _binomial_loglik(k0, n0, p0)

    def g(log_ratio: float) -> float:
        profile = _profile_rr_loglik(k1, n1, k0, n0, log_ratio)
        return 2 * (maximum - profile) - CHI2_1_95

    grid = [float(value) for value in range(-80, 81)]
    accepted = [value for value in grid if g(value) <= 0]
    if not accepted:
        raise ArithmeticError("profile-rate-ratio acceptance region was not found")
    first = min(accepted)
    last = max(accepted)
    if first <= -80:
        lower = 0.0
    else:
        left, right = first - 1, first
        for _ in range(100):
            middle = (left + right) / 2
            if g(middle) > 0:
                left = middle
            else:
                right = middle
        lower = math.exp(right)
    if last >= 80:
        upper = math.inf
    else:
        left, right = last, last + 1
        for _ in range(100):
            middle = (left + right) / 2
            if g(middle) <= 0:
                left = middle
            else:
                right = middle
        upper = math.exp(left)
    return {"point": point, "point_label": point_label,
            "lower": lower, "upper": upper}


def analyze_probe_panel(indices_zero_based: Sequence[int], n: int,
                        block_nacks: Sequence[int] | None = None,
                        index_overflow: bool = False,
                        aggregate_nacks: int | None = None) -> dict[str, Any]:
    complete_metrics = sequence_metrics(indices_zero_based, n)
    k = (int(aggregate_nacks) if aggregate_nacks is not None
         else complete_metrics["nacks"])
    _validate_binomial(k, n)
    if block_nacks is None:
        if n != 10000:
            raise ValueError("explicit block counts required when N is not 10000")
        block_nacks = complete_metrics["block_nacks"]
    if sum(int(value) for value in block_nacks) != k:
        raise ValueError("probe block counts do not equal aggregate NACK count")
    block_p = exact_equal_block_homogeneity(block_nacks, n // len(block_nacks))
    sequence_complete = not index_overflow and len(indices_zero_based) == k
    if sequence_complete:
        runs_p = exact_runs_test(n, k, complete_metrics["run_count"])
        adjacent_p = exact_adjacent_pair_test(n, k, complete_metrics["adjacent_pairs"])
        order_context = order_statistic_context(n, k)
    else:
        # These are fixed planned hypotheses, so an unavailable complete
        # sequence receives p=1 for global Holm bookkeeping.
        runs_p = 1.0
        adjacent_p = 1.0
        order_context = {"estimable": False, "reason": "INDEX_LOG_INCOMPLETE"}
    informative = (5 <= k <= n - 5 and not index_overflow and
                   len(indices_zero_based) == k)
    return {
        **complete_metrics,
        "nacks": k, "acks": n - k,
        "rate": k / n if n else None,
        "ppm": 1_000_000 * k / n if n else None,
        "wilson95": wilson95(k, n) if n else None,
        "sequence_complete": sequence_complete,
        "index_overflow": index_overflow,
        "raw_p": {"block_homogeneity": block_p, "runs": runs_p,
                  "adjacent_pairs": adjacent_p},
        "order_statistic_context": order_context,
        "informative": informative,
        "classification_before_global_holm":
            "PENDING_GLOBAL_27_TEST_HOLM" if informative else "INSUFFICIENT_EVENTS",
    }


def classify_stationarity_panels(panels: Mapping[str, Mapping[str, Any]]) -> dict[str, Any]:
    """Apply the one global Holm family across exactly nine x three tests."""
    planned_panels = [f"A{run}_{phase}" for run in range(1, 4) for phase in PHASES3]
    planned = [f"{panel}:{test}" for panel in planned_panels
               for test in ("block_homogeneity", "runs", "adjacent_pairs")]
    raw: dict[str, float] = {}
    for panel in planned_panels:
        item = panels.get(panel)
        if item:
            for test, pvalue in item["raw_p"].items():
                raw[f"{panel}:{test}"] = float(pvalue)
    adjusted = holm_adjust(raw, planned)
    panel_results: dict[str, str] = {}
    for panel in planned_panels:
        item = panels.get(panel)
        rejects = any(adjusted[f"{panel}:{test}"] < STATIONARITY_ALPHA
                      for test in ("block_homogeneity", "runs", "adjacent_pairs"))
        if rejects:
            panel_results[panel] = "EVIDENCE_AGAINST_STATIONARITY_OR_INDEPENDENCE"
        elif item and item.get("informative"):
            panel_results[panel] = "COMPATIBLE_WITH_STATIONARY_MEMORYLESS_PROCESS"
        else:
            panel_results[panel] = "INSUFFICIENT_EVENTS"
    final: dict[str, str] = {}
    for phase in PHASES3:
        values = [panel_results[f"A{run}_{phase}"] for run in range(1, 4)]
        if "EVIDENCE_AGAINST_STATIONARITY_OR_INDEPENDENCE" in values:
            final[phase] = "EVIDENCE_AGAINST_STATIONARITY_OR_INDEPENDENCE"
        elif all(value == "COMPATIBLE_WITH_STATIONARY_MEMORYLESS_PROCESS"
                 for value in values):
            final[phase] = "COMPATIBLE_WITH_STATIONARY_MEMORYLESS_PROCESS"
        else:
            final[phase] = "INSUFFICIENT_EVENTS"
    return {"planned_test_count": 27, "adjusted_p": adjusted,
            "panels": panel_results, "final_by_phase": final}


def analyze_autoinit_heterogeneity(
        runs: Mapping[str, Mapping[str, Mapping[str, int]]]) -> dict[str, Any]:
    planned = ("A1", "A2", "A3")
    raw: dict[str, float] = {}
    maximum_sets: dict[str, list[str]] = {}
    estimable: dict[str, bool] = {}
    for run in planned:
        data = runs.get(run)
        if not data or any(int(data[phase]["opportunities"]) == 0 for phase in PHASES4):
            estimable[run] = False
            continue
        events = [int(data[phase]["nacks"]) for phase in PHASES4]
        totals = [int(data[phase]["opportunities"]) for phase in PHASES4]
        raw[run] = exact_rx2_probability_ordering(events, totals)
        rates = {phase: data[phase]["nacks"] / data[phase]["opportunities"]
                 for phase in PHASES4}
        maximum = max(rates.values())
        maximum_sets[run] = [phase for phase, rate in rates.items() if rate == maximum]
        estimable[run] = True
    adjusted = holm_adjust(raw, planned)
    rejecting = [run for run in planned if estimable.get(run) and adjusted[run] < 0.05]
    if len(rejecting) >= 2:
        intersection = set(maximum_sets[rejecting[0]])
        for run in rejecting[1:]:
            intersection &= set(maximum_sets[run])
        classification = ("SUPPORTED_REPEATABLE" if intersection
                          else "MIXED_OR_RUN_SPECIFIC")
    elif len(rejecting) == 1:
        classification = "MIXED_OR_RUN_SPECIFIC"
    elif all(estimable.get(run) for run in planned):
        classification = "NOT_DETECTED_NOT_EQUALITY_PROOF"
    else:
        classification = "INSUFFICIENT_VALID_DENOMINATORS"
    return {"raw_p": raw, "adjusted_p": adjusted, "maximum_phase_sets": maximum_sets,
            "classification": classification}


def compare_autoinit_to_probe(k_auto: int, n_auto: int,
                              k_probe: int, n_probe: int) -> dict[str, Any]:
    _validate_binomial(k_auto, n_auto)
    _validate_binomial(k_probe, n_probe)
    if n_auto == 0 or n_probe == 0:
        return {"estimable": False, "raw_p_greater": 1.0,
                "reason": "ZERO_DENOMINATOR"}
    rate_auto = k_auto / n_auto
    rate_probe = k_probe / n_probe
    rr = profile_rate_ratio_ci(k_auto, n_auto, k_probe, n_probe)
    identifiable_rr = not (k_auto == 0 and k_probe == 0)
    return {
        "estimable": True, "identifiable_rate_ratio": identifiable_rr,
        "autoinit_rate": rate_auto, "probe_rate": rate_probe,
        "rate_difference": rate_auto - rate_probe,
        "difference_ci95_miettinen_nurminen":
            miettinen_nurminen_difference_ci(k_auto, n_auto, k_probe, n_probe),
        "rate_ratio_profile_ci95": rr,
        "raw_p_greater": fisher_exact_greater(k_auto, n_auto, k_probe, n_probe),
    }


def analyze_context_elevation(
        runs: Mapping[str, Mapping[str, Mapping[str, int]]]) -> dict[str, Any]:
    planned_runs = ("A1", "A2", "A3")
    comparisons: dict[str, dict[str, Any]] = {}
    supports: dict[str, list[str]] = {phase: [] for phase in PHASES3}
    signs: dict[str, list[int]] = {phase: [] for phase in PHASES3}
    identifiable: dict[str, int] = {phase: 0 for phase in PHASES3}
    for run in planned_runs:
        run_result: dict[str, Any] = {}
        raw: dict[str, float] = {}
        for phase in PHASES3:
            data = runs.get(run, {}).get(phase)
            if data:
                item = compare_autoinit_to_probe(
                    int(data["autoinit_nacks"]), int(data["autoinit_opportunities"]),
                    int(data["probe_nacks"]), int(data["probe_opportunities"]))
            else:
                item = {"estimable": False, "raw_p_greater": 1.0,
                        "reason": "MISSING_PLANNED_COMPARISON"}
            run_result[phase] = item
            raw[phase] = float(item["raw_p_greater"])
        adjusted = holm_adjust(raw, PHASES3)
        for phase in PHASES3:
            item = run_result[phase]
            item["holm_adjusted_p"] = adjusted[phase]
            if item.get("estimable"):
                difference = item["rate_difference"]
                signs[phase].append(1 if difference > 0 else -1 if difference < 0 else 0)
                identifiable[phase] += int(item.get("identifiable_rate_ratio", False))
                lower = item["rate_ratio_profile_ci95"]["lower"]
                supported = (difference > 0 and adjusted[phase] < CONTEXT_ALPHA
                             and lower > 2.0)
            else:
                supported = False
            item["run_support_rule"] = supported
            if supported:
                supports[phase].append(run)
        comparisons[run] = run_result
    final: dict[str, str] = {}
    for phase in PHASES3:
        sign_set = set(signs[phase])
        mixed_sign = 1 in sign_set and -1 in sign_set
        if len(supports[phase]) >= 2:
            final[phase] = "SUPPORTED"
        elif len(supports[phase]) == 1 or mixed_sign:
            final[phase] = "MIXED"
        elif identifiable[phase] >= 2 and len(signs[phase]) == 3:
            final[phase] = "NOT_SUPPORTED"
        else:
            final[phase] = "INSUFFICIENT_EVENTS"
    return {"comparisons": comparisons, "supporting_runs": supports,
            "classification_by_phase": final}


def exact_equal_multinomial_probability_ordering(counts: Sequence[int]) -> float:
    values = [int(value) for value in counts]
    if len(values) < 2 or any(value < 0 for value in values):
        raise ValueError("nonnegative multinomial counts with >=2 cells required")
    total_events = sum(values)
    if total_events == 0:
        return 1.0
    observed = math.factorial(total_events) // math.prod(math.factorial(v) for v in values)
    tail = 0
    total_weight = len(values) ** total_events

    def visit(cell: int, remaining: int, prefix: list[int]) -> None:
        nonlocal tail
        if cell == len(values) - 1:
            candidate = prefix + [remaining]
            weight = math.factorial(total_events) // math.prod(
                math.factorial(v) for v in candidate)
            if weight <= observed:
                tail += weight
            return
        for value in range(remaining + 1):
            visit(cell + 1, remaining - value, prefix + [value])

    visit(0, total_events, [])
    return tail / total_weight


def _bounded_compositions(total: int, limits: Sequence[int]) -> Iterable[tuple[int, ...]]:
    if len(limits) == 1:
        if 0 <= total <= limits[0]:
            yield (total,)
        return
    low = max(0, total - sum(limits[1:]))
    high = min(limits[0], total)
    for value in range(low, high + 1):
        for suffix in _bounded_compositions(total - value, limits[1:]):
            yield (value,) + suffix


def exact_rxc_probability_ordering(table: Sequence[Sequence[int]],
                                   max_tables: int = 250_000) -> float:
    """Exact fixed-row/fixed-column Fisher-Freeman-Halton RxC tail."""
    rows = [[int(value) for value in row] for row in table]
    if len(rows) < 2 or not rows or len(rows[0]) < 2:
        raise ValueError("RxC table requires at least 2x2 cells")
    columns = len(rows[0])
    if any(len(row) != columns for row in rows) or any(value < 0 for row in rows for value in row):
        raise ValueError("RxC table must be rectangular and nonnegative")
    row_sums = [sum(row) for row in rows]
    col_sums = [sum(rows[row][column] for row in range(len(rows)))
                for column in range(columns)]
    if any(value == 0 for value in row_sums):
        raise ValueError("zero row makes the planned comparison unestimable")
    # With margins fixed, probability is a common constant times
    # 1/product(cell!).  Fraction retains the full exact tail.
    observed_denominator = math.prod(math.factorial(value)
                                     for row in rows for value in row)
    total_weight = Fraction(0, 1)
    tail_weight = Fraction(0, 1)
    table_count = 0

    def visit(row_index: int, remaining_columns: tuple[int, ...],
              denominator_product: int) -> None:
        nonlocal total_weight, tail_weight, table_count
        if row_index == len(rows) - 1:
            if sum(remaining_columns) != row_sums[row_index]:
                return
            denominator = denominator_product * math.prod(
                math.factorial(value) for value in remaining_columns)
            table_count += 1
            if table_count > max_tables:
                raise ExactTestResourceError(
                    f"RxC exact enumeration exceeded {max_tables} tables")
            weight = Fraction(1, denominator)
            total_weight += weight
            if denominator >= observed_denominator:
                tail_weight += weight
            return
        for allocation in _bounded_compositions(row_sums[row_index], remaining_columns):
            remaining = tuple(value - used for value, used in zip(remaining_columns, allocation))
            visit(row_index + 1, remaining,
                  denominator_product * math.prod(math.factorial(value)
                                                   for value in allocation))

    visit(0, tuple(col_sums), 1)
    return float(tail_weight / total_weight)


def analyze_replicate_homogeneity(
        arm_a: Mapping[str, Mapping[str, Any]],
        arm_b_counts: Mapping[str, int] | None = None,
        formal_exposure_equal: bool = False) -> dict[str, Any]:
    """Apply the frozen Arm-A replicate families and optional Arm-B count test."""
    planned_runs = ("A1", "A2", "A3")
    estimable_all = True
    families: dict[str, Any] = {}

    for family_name, field_name, phase_names in (
            ("autoinit_rates", "autoinit", PHASES4),
            ("probe_rates", "probe", PHASES3)):
        raw: dict[str, float] = {}
        for phase in phase_names:
            try:
                events = [int(arm_a[run][field_name][phase]["nacks"])
                          for run in planned_runs]
                totals = [int(arm_a[run][field_name][phase]["opportunities"])
                          for run in planned_runs]
                raw[phase] = exact_rx2_probability_ordering(events, totals)
            except (KeyError, ValueError):
                estimable_all = False
        families[family_name] = {
            "raw_p": raw, "adjusted_p": holm_adjust(raw, phase_names)}

    try:
        events = [int(arm_a[run]["failed_transactions"]) for run in planned_runs]
        totals = [int(arm_a[run]["transaction_starts"]) for run in planned_runs]
        failed_rate_p = exact_rx2_probability_ordering(events, totals)
    except (KeyError, ValueError):
        failed_rate_p = None
        estimable_all = False
    families["failed_transaction_rate"] = {"raw_p": failed_rate_p}

    composition_names = (
        "HIGH_LEVEL_PHASE", "TRANSACTION_KIND", "PHASE_NACK_BITMAP",
        "TABLE_SLOT", "REQUESTED_BANK", "VALID_PHYSICAL_BANK_BEFORE")
    composition_raw: dict[str, float] = {}
    for category in composition_names:
        try:
            category_keys = sorted(set().union(*(
                arm_a[run]["compositions"][category].keys() for run in planned_runs)))
            category_keys = [key for key in category_keys if any(
                arm_a[run]["compositions"][category].get(key, 0)
                for run in planned_runs)]
            if len(category_keys) < 2:
                raise ValueError("fewer than two nonzero composition categories")
            table = [[int(arm_a[run]["compositions"][category].get(key, 0))
                      for key in category_keys] for run in planned_runs]
            composition_raw[category] = exact_rxc_probability_ordering(table)
        except (KeyError, ValueError, ExactTestResourceError):
            estimable_all = False
    families["failed_composition"] = {
        "raw_p": composition_raw,
        "adjusted_p": holm_adjust(composition_raw, composition_names),
    }
    rejections = []
    for family in ("autoinit_rates", "probe_rates", "failed_composition"):
        rejections.extend((family, key) for key, value in
                          families[family]["adjusted_p"].items() if value < 0.05)
    if failed_rate_p is not None and failed_rate_p < 0.05:
        rejections.append(("failed_transaction_rate", "overall"))
    b_result: dict[str, Any]
    if arm_b_counts is not None and formal_exposure_equal and all(
            key in arm_b_counts for key in ("B1", "B2", "B3")):
        counts = [int(arm_b_counts[key]) for key in ("B1", "B2", "B3")]
        b_result = {"estimable": True, "exact_multinomial_p":
                    exact_equal_multinomial_probability_ordering(counts)}
        if b_result["exact_multinomial_p"] < 0.05:
            rejections.append(("arm_b_aggregate_nacks", "overall"))
    else:
        b_result = {"estimable": False, "reason": "FORMAL_EXPOSURE_NOT_PROVEN_EQUAL"}
        estimable_all = False
    if rejections:
        classification = "EVIDENCE_AGAINST_HOMOGENEITY"
    elif estimable_all:
        classification = "NO_HETEROGENEITY_DETECTED_NOT_EQUIVALENCE"
    else:
        classification = "INSUFFICIENT_VALID_DATA"
    return {"families": families, "arm_b": b_result,
            "rejections": rejections, "classification": classification}


def paired_direction(a_nacks: Sequence[int | None],
                     b_nacks: Sequence[int | None]) -> dict[str, Any]:
    if len(a_nacks) != 3 or len(b_nacks) != 3:
        raise ValueError("the frozen paired plan requires exactly three pairs")
    if any(value is None for value in tuple(a_nacks) + tuple(b_nacks)):
        return {"label": "INSUFFICIENT_VALID_PAIRS", "differences": None,
                "one_sided_sign_p": None, "two_sided_sign_p": None}
    differences = [int(a) - int(b) for a, b in zip(a_nacks, b_nacks)]
    positive = sum(value > 0 for value in differences)
    negative = sum(value < 0 for value in differences)
    non_tied = positive + negative
    if non_tied:
        dominant = max(positive, negative)
        one_sided = sum(_comb(non_tied, value) for value in range(dominant, non_tied + 1)) / 2 ** non_tied
        two_sided = min(1.0, 2 * one_sided)
    else:
        one_sided = two_sided = 1.0
    if positive == 3 or negative == 3:
        label = "DIRECTION_REPEATABLE_3_OF_3"
    elif max(positive, negative) == 2:
        label = "DIRECTION_MAJORITY_2_OF_3"
    else:
        label = "NO_REPEATABLE_DIRECTION"
    return {"label": label, "differences": differences,
            "one_sided_sign_p": one_sided, "two_sided_sign_p": two_sided}


def classify_failed_distribution(run_compositions: Mapping[str, Mapping[str, int]],
                                 opportunity_normalized_repeatable: bool = False) -> str:
    """Frozen descriptive fallback when category opportunity denominators lack."""
    runs = ("A1", "A2", "A3")
    available = {run: run_compositions.get(run, {}) for run in runs}
    if opportunity_normalized_repeatable:
        return "REPEATABLE_OPPORTUNITY_NORMALIZED_CONCENTRATION"
    supporting_modes: list[str] = []
    for run in runs:
        counts = available[run]
        total = sum(int(value) for value in counts.values())
        if total < 5 or not counts:
            continue
        maximum = max(int(value) for value in counts.values())
        modes = [str(key) for key, value in counts.items() if int(value) == maximum]
        if maximum / total >= 0.5:
            supporting_modes.extend(modes)
    if any(supporting_modes.count(mode) >= 2 for mode in set(supporting_modes)):
        return "REPEATABLE_FAILURE_COMPOSITION_CONCENTRATION_DENOMINATORS_LIMIT_RATE_CLAIM"
    valid_runs = sum(bool(available[run]) for run in runs)
    total_failures = sum(sum(int(value) for value in available[run].values()) for run in runs)
    if total_failures < 5:
        return "INSUFFICIENT_FAILED_TRANSACTIONS"
    if valid_runs < 3:
        return "RUN_VARIABLE_DISTRIBUTION"
    return "NO_REPEATABLE_CONCENTRATION_DETECTED"


def classify_bank_coherence(error_counts: Sequence[int] | None) -> str:
    if not error_counts:
        return "INCONCLUSIVE_INFRASTRUCTURE"
    if any(int(value) != 0 for value in error_counts):
        return "CONTRADICTION_MEASURED"
    return "PASS_ZERO_INVARIANT_ERRORS"


def classify_r7_operation86(comparable_event_observed: bool,
                            coherent_explicit_fields: bool,
                            invariant_contradiction: bool) -> str:
    if invariant_contradiction:
        return "TRUE_TRACKER_CONTRADICTION_REPRODUCED"
    if comparable_event_observed and coherent_explicit_fields:
        return "EXPLAINED_BY_R1F_FIELDS"
    return "REMAINS_INCONCLUSIVE"
