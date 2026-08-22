#!/usr/bin/env python3
"""Exact R1d 23-state-tick campaign timing model."""

from __future__ import annotations

import argparse
import csv
from decimal import Decimal, getcontext
from pathlib import Path

CLK_HZ = 62_500_000
TARGET = 10_000
TICKS_PER_PROBE = 23
PREAMBLE_TICKS = 2
MODES = (("50KHZ", 625), ("25KHZ", 1250))


def rows():
    getcontext().prec = 30
    for name, divider in MODES:
        tick_cycles = divider + 1
        tick_us = Decimal(tick_cycles) * Decimal(1_000_000) / Decimal(CLK_HZ)
        scl_hz = Decimal(CLK_HZ) / (Decimal(2) * Decimal(tick_cycles))
        total_ticks = PREAMBLE_TICKS + TARGET * TICKS_PER_PROBE
        seconds = Decimal(total_ticks * tick_cycles) / Decimal(CLK_HZ)
        yield {
            "mode": name,
            "divider": divider,
            "tick_cycles": tick_cycles,
            "tick_us": tick_us,
            "actual_scl_hz": scl_hz,
            "ticks_per_probe": TICKS_PER_PROBE,
            "preamble_ticks": PREAMBLE_TICKS,
            "target_count": TARGET,
            "expected_seconds": seconds,
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    model = list(rows())
    if args.output_dir:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        csv_path = args.output_dir / "PROBE_TIMING_50K_25K.csv"
        with csv_path.open("w", newline="", encoding="ascii") as handle:
            writer = csv.DictWriter(handle, fieldnames=model[0].keys())
            writer.writeheader()
            writer.writerows(model)
        md = ["# R1d probe runtime model", "", "The final FSM uses 23 selected state ticks per completed address probe:", "", "- BUS_FREE: 1", "- START: 2", "- eight address bits: 16", "- ACK: 2", "- STOP: 2", "", "Each campaign has a two-tick stable-bus preamble.", ""]
        for row in model:
            md.append(f"- {row['mode']}: {row['expected_seconds']} s, actual SCL {row['actual_scl_hz']} Hz")
        (args.output_dir / "PROBE_RUNTIME_MODEL.md").write_text("\n".join(md) + "\n", encoding="ascii")
        (args.output_dir / "raw_calculation.log").write_text(
            "\n".join(str(row) for row in model) + "\n", encoding="ascii")
    for row in model:
        print(" ".join(f"{key}={value}" for key, value in row.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
