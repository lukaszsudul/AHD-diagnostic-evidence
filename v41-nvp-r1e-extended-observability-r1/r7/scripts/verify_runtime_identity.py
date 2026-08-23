#!/usr/bin/env python3
"""Fail-closed validation of the four immutable v41 runtime identity words."""

from __future__ import annotations

import argparse

EXPECTED = (0xA40A0C07, 0x0000400B, 0x00031002, 0x00000000)


def parse_word(text: str) -> int:
    value = int(text, 0)
    if not 0 <= value <= 0xFFFFFFFF:
        raise ValueError(f"word is outside unsigned 32-bit range: {text}")
    return value


def is_exact_formal(words: tuple[int, int, int, int]) -> bool:
    return words == EXPECTED


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block-id", required=True)
    parser.add_argument("--protocol", required=True)
    parser.add_argument("--capabilities", required=True)
    parser.add_argument("--diagnostic-magic", required=True)
    args = parser.parse_args()
    words = tuple(parse_word(value) for value in (
        args.block_id, args.protocol, args.capabilities, args.diagnostic_magic
    ))
    print(f"BLOCK_ID=0x{words[0]:08X}")
    print(f"PROTOCOL=0x{words[1]:08X}")
    print(f"CAPABILITIES=0x{words[2]:08X}")
    print(f"DIAGNOSTIC_MAGIC=0x{words[3]:08X}")
    print(f"ALL_ONES_IDENTITY_ACCEPTED={'YES' if words[0] == 0xFFFFFFFF else 'NO'}")
    if not is_exact_formal(words):
        print("FORMAL_RUNTIME_IDENTITY=FAIL")
        return 1
    print("FORMAL_RUNTIME_IDENTITY=PASS_EXACT")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
