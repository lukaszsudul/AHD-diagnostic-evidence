"""Exact ordered report comparison with two audited volatile header fields."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


class UnsafeReport(ValueError):
    pass


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def body(data: bytes) -> tuple[bytes, dict[str, str]]:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise UnsafeReport("non-UTF8 report") from exc
    lines = text.splitlines(keepends=True)
    removed: dict[str, str] = {}
    kept: list[str] = []
    for line in lines:
        if line.startswith("| Date         :"):
            label = "Date"
        elif line.startswith("| Command      :"):
            label = "Command"
        else:
            kept.append(line)
            continue
        if label in removed:
            raise UnsafeReport(f"duplicate {label} header")
        removed[label] = line.rstrip("\r\n")
    if set(removed) != {"Date", "Command"}:
        raise UnsafeReport("required provenance header missing")
    if not kept or len(kept) < 5:
        raise UnsafeReport("empty or truncated report body")
    return "".join(kept).encode("utf-8"), removed


def compare(a: bytes, b: bytes) -> dict[str, object]:
    body_a, header_a = body(a)
    body_b, header_b = body(b)
    command_a = header_a["Command"].split(" -file ", 1)
    command_b = header_b["Command"].split(" -file ", 1)
    if len(command_a) != 2 or len(command_b) != 2:
        raise UnsafeReport("command output path not isolated")
    if command_a[0] != command_b[0]:
        raise UnsafeReport("report command or options differ")
    if Path(command_a[1].strip()).name != Path(command_b[1].strip()).name:
        raise UnsafeReport("report output basenames differ")
    return {
        "raw_a_sha256": sha(a),
        "raw_b_sha256": sha(b),
        "raw_equal": a == b,
        "body_a_sha256": sha(body_a),
        "body_b_sha256": sha(body_b),
        "body_equal": body_a == body_b,
        "excluded_a": header_a,
        "excluded_b": header_b,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("a", type=Path)
    parser.add_argument("b", type=Path)
    args = parser.parse_args()
    result = compare(args.a.read_bytes(), args.b.read_bytes())
    print(json.dumps(result, indent=2, sort_keys=True))
    if not result["body_equal"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
