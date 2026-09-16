"""Order-preserving audit of Vivado write_xdc shared-object aliases.

This is a representation comparator, not an effective-constraint evaluator.
It never executes Tcl, touches a DCP, or discards a constraint command.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


ALIAS = re.compile(r"\$(_xlnx_shared_i\d+)\b")
ASSIGNMENT = re.compile(r"^set (_xlnx_shared_i\d+) (.+)$")
SAFE_SELECTOR = re.compile(r"^(?:\[(?:get_cells|get_pins|filter)\b|\{)")


class UnsafeView(ValueError):
    pass


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def expand_export(data: bytes) -> tuple[list[str], dict[str, int]]:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise UnsafeView("non-UTF8 export") from exc
    if "\r" in text:
        raise UnsafeView("line endings must be identified before comparison")
    aliases: dict[str, str] = {}
    uses: dict[str, int] = {}
    commands: list[str] = []
    for line in text.splitlines():
        match = ASSIGNMENT.fullmatch(line)
        if match:
            name, value = match.groups()
            if name in aliases:
                raise UnsafeView(f"redefined alias: {name}")
            if not SAFE_SELECTOR.match(value):
                raise UnsafeView(f"non-selector alias: {name}")
            if ALIAS.search(value) or ";" in value or "\n" in value:
                raise UnsafeView(f"recursive or multi-command alias: {name}")
            aliases[name] = value
            uses[name] = 0
            continue

        def replace(found: re.Match[str]) -> str:
            name = found.group(1)
            if name not in aliases:
                raise UnsafeView(f"undefined alias: {name}")
            uses[name] += 1
            return aliases[name]

        commands.append(ALIAS.sub(replace, line))
    if not commands:
        raise UnsafeView("empty command stream")
    unused = [name for name, count in uses.items() if count == 0]
    if unused:
        raise UnsafeView(f"unused aliases: {','.join(unused)}")
    return commands, uses


def compare(a: bytes, b: bytes) -> dict[str, object]:
    left, left_aliases = expand_export(a)
    right, right_aliases = expand_export(b)
    left_stream = ("\n".join(left) + "\n").encode("utf-8")
    right_stream = ("\n".join(right) + "\n").encode("utf-8")
    first_difference = next(
        (index for index, (x, y) in enumerate(zip(left, right)) if x != y),
        min(len(left), len(right)) if len(left) != len(right) else None,
    )
    return {
        "raw_a_sha256": digest(a),
        "raw_b_sha256": digest(b),
        "a_aliases": len(left_aliases),
        "b_aliases": len(right_aliases),
        "a_commands": len(left),
        "b_commands": len(right),
        "a_expanded_sha256": digest(left_stream),
        "b_expanded_sha256": digest(right_stream),
        "exact_ordered_commands_equal": left == right,
        "first_difference_index": first_difference,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("a", type=Path)
    parser.add_argument("b", type=Path)
    args = parser.parse_args()
    result = compare(args.a.read_bytes(), args.b.read_bytes())
    print(json.dumps(result, indent=2, sort_keys=True))
    if not result["exact_ordered_commands_equal"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
