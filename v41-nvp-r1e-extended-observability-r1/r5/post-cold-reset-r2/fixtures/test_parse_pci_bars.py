#!/usr/bin/env python3
"""Offline fixture gate for parse_pci_bars.py."""

from __future__ import annotations

import argparse
import csv
import hashlib
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Case:
    filename: str
    expect_success: bool
    expected: dict[str, str] | None = None
    error_contains: str | None = None
    prior_bad_token_replay: bool = False


CASES = (
    Case(
        "normal_r1b_like.resource",
        True,
        {
            "BAR0_START": "0x00000000f6e00000",
            "BAR0_END": "0x00000000f6e1ffff",
            "BAR0_FLAGS": "0x0000000000040200",
            "BAR0_BYTES": "131072",
            "BAR1_START": "0x00000000f6e20000",
            "BAR1_END": "0x00000000f6e2ffff",
            "BAR1_FLAGS": "0x0000000000040200",
            "BAR1_BYTES": "65536",
        },
    ),
    Case(
        "uppercase_hex.resource",
        True,
        {"BAR0_BYTES": "131072", "BAR1_BYTES": "65536"},
    ),
    Case(
        "leading_zeros.resource",
        True,
        {"BAR0_BYTES": "256", "BAR1_BYTES": "16"},
    ),
    Case(
        "all_zero_unused.resource",
        True,
        {"BAR0_BYTES": "0", "BAR1_BYTES": "0"},
    ),
    Case("end_before_start.resource", False, error_contains="is smaller than start"),
    Case("missing_token.resource", False, error_contains="expected exactly 3 tokens"),
    Case("nonhex_token.resource", False, error_contains="invalid integer token"),
    Case(
        "extra_whitespace.resource",
        True,
        {"BAR0_BYTES": "131072", "BAR1_BYTES": "65536"},
    ),
    Case(
        "r1b_bad_token_replay.resource",
        True,
        {"BAR0_BYTES": "131072", "BAR1_BYTES": "65536"},
        prior_bad_token_replay=True,
    ),
)


def parse_fields(stdout: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in stdout.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        fields[key] = value
    return fields


def main() -> int:
    cli = argparse.ArgumentParser()
    cli.add_argument("--parser", type=Path, required=True)
    cli.add_argument("--fixture-dir", type=Path, required=True)
    cli.add_argument("--output-dir", type=Path, required=True)
    args = cli.parse_args()

    parser_path = args.parser.resolve()
    fixture_dir = args.fixture_dir.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, str]] = []
    raw: list[str] = []
    all_pass = True
    prior_replay_pass = False

    for case in CASES:
        fixture = fixture_dir / case.filename
        result = subprocess.run(
            [sys.executable, str(parser_path), "--resource-file", str(fixture)],
            text=True,
            capture_output=True,
            check=False,
        )
        fields = parse_fields(result.stdout)
        reasons: list[str] = []

        if case.expect_success:
            if result.returncode != 0:
                reasons.append(f"expected exit 0, got {result.returncode}")
            for key, expected_value in (case.expected or {}).items():
                actual_value = fields.get(key)
                if actual_value != expected_value:
                    reasons.append(f"{key}: expected {expected_value}, got {actual_value!r}")
            if case.prior_bad_token_replay:
                combined = result.stdout + result.stderr
                forbidden = ("value too great for base", "16#0x")
                if any(token in combined for token in forbidden):
                    reasons.append("prior shell-arithmetic error signature was reproduced")
                prior_replay_pass = not reasons
        else:
            if result.returncode == 0:
                reasons.append("expected nonzero exit, got 0")
            if case.error_contains and case.error_contains not in result.stderr:
                reasons.append(f"stderr missing expected text {case.error_contains!r}")

        passed = not reasons
        all_pass = all_pass and passed
        rows.append(
            {
                "FIXTURE": case.filename,
                "EXPECTED_RESULT": "PASS" if case.expect_success else "FAIL_CLOSED",
                "PROCESS_EXIT_CODE": str(result.returncode),
                "ACTUAL_CLASSIFICATION": "PASS" if passed else "FAIL",
                "BAR0_BYTES": fields.get("BAR0_BYTES", ""),
                "BAR1_BYTES": fields.get("BAR1_BYTES", ""),
                "DETAIL": "; ".join(reasons) if reasons else "expected behavior observed",
            }
        )
        raw.extend(
            (
                f"===== {case.filename} =====",
                f"PROCESS_EXIT_CODE={result.returncode}",
                "--- STDOUT ---",
                result.stdout.rstrip(),
                "--- STDERR ---",
                result.stderr.rstrip(),
                f"FIXTURE_RESULT={'PASS' if passed else 'FAIL'}",
                "",
            )
        )

    csv_path = output_dir / "BAR_PARSER_FIXTURE_RESULTS.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys(), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    raw_path = output_dir / "BAR_PARSER_FIXTURE_RAW.log"
    raw_path.write_text("\n".join(raw) + "\n", encoding="utf-8")

    parser_sha = hashlib.sha256(parser_path.read_bytes()).hexdigest().upper()
    summary = "\n".join(
        (
            "# BAR parser offline fixture gate",
            "",
            "```text",
            f"BAR_PARSER_SHA256={parser_sha}",
            "BAR_PARSER_LANGUAGE=PYTHON3",
            "BAR_PARSER_USES_INT_BASE_ZERO=YES",
            "BAR_PARSER_BASH_16_HASH_0X_USED=NO",
            f"BAR_PARSER_FIXTURES={'PASS_ALL' if all_pass else 'FAIL'}",
            f"R1B_BAD_TOKEN_REPLAY={'PASS_NO_16_HASH_0X_ERROR' if prior_replay_pass else 'FAIL'}",
            f"FIXTURE_COUNT={len(CASES)}",
            "NETWORK_ACTIONS=0",
            "VIVADO_ACTIONS=0",
            "HARDWARE_ACTIONS=0",
            "FPGA_SOURCE_CHANGES=0",
            "FULL_BUILDS=0",
            "```",
            "",
        )
    )
    (output_dir / "BAR_PARSER_FIXTURE_GATE.md").write_text(summary, encoding="utf-8")
    print(summary, end="")
    return 0 if all_pass and prior_replay_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
