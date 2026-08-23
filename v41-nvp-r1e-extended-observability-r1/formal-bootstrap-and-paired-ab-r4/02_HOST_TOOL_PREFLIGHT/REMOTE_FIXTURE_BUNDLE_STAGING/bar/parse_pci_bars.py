#!/usr/bin/env python3
"""Read BAR0/BAR1 geometry from a Linux PCI resource table."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


_BDF_RE = re.compile(r"^[0-9A-Fa-f]{4}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}\.[0-7]$")


class BarParseError(ValueError):
    """Raised when a resource-table BAR row is malformed."""


@dataclass(frozen=True)
class Bar:
    start: int
    end: int
    flags: int
    size: int


def parse_bar_line(line: str, bar_number: int) -> Bar:
    tokens = line.split()
    if len(tokens) != 3:
        raise BarParseError(
            f"BAR{bar_number}: expected exactly 3 tokens (start end flags), got {len(tokens)}"
        )

    try:
        start = int(tokens[0], 0)
        end = int(tokens[1], 0)
        flags = int(tokens[2], 0)
    except ValueError as exc:
        raise BarParseError(f"BAR{bar_number}: invalid integer token: {exc}") from exc

    if start < 0 or end < 0 or flags < 0:
        raise BarParseError(f"BAR{bar_number}: negative values are not valid resource entries")

    if start == 0 and end == 0:
        size = 0
    elif end < start:
        raise BarParseError(
            f"BAR{bar_number}: end 0x{end:x} is smaller than start 0x{start:x}"
        )
    else:
        size = end - start + 1

    return Bar(start=start, end=end, flags=flags, size=size)


def parse_resource(path: Path) -> tuple[Bar, Bar]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        raise BarParseError(f"cannot read resource table {path}: {exc}") from exc

    if len(lines) < 2:
        raise BarParseError(f"resource table has {len(lines)} line(s); BAR0 and BAR1 require 2")

    return parse_bar_line(lines[0], 0), parse_bar_line(lines[1], 1)


def _hex64(value: int) -> str:
    return f"0x{value:016x}"


def emit(bar0: Bar, bar1: Bar) -> None:
    for number, bar in ((0, bar0), (1, bar1)):
        print(f"BAR{number}_START={_hex64(bar.start)}")
        print(f"BAR{number}_END={_hex64(bar.end)}")
        print(f"BAR{number}_FLAGS={_hex64(bar.flags)}")
        print(f"BAR{number}_BYTES={bar.size}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Parse BAR0 and BAR1 from /sys/bus/pci/devices/<BDF>/resource"
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--bdf",
        help="PCI BDF in dddd:bb:ss.f form; reads /sys/bus/pci/devices/<BDF>/resource",
    )
    source.add_argument(
        "--resource-file",
        type=Path,
        help="Explicit resource-table file (offline fixtures only)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.bdf is not None:
        if _BDF_RE.fullmatch(args.bdf) is None:
            print("BAR_PARSER_ERROR=invalid BDF; expected dddd:bb:ss.f", file=sys.stderr)
            return 2
        path = Path("/sys/bus/pci/devices") / args.bdf / "resource"
    else:
        path = args.resource_file

    try:
        bar0, bar1 = parse_resource(path)
    except BarParseError as exc:
        print(f"BAR_PARSER_ERROR={exc}", file=sys.stderr)
        return 2

    emit(bar0, bar1)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
