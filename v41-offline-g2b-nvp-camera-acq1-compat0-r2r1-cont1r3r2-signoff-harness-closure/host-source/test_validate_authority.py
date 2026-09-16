"""Synthetic wrong-artifact and wrong-tool fail-closed checks."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("authority", HERE / "validate_authority.py")
assert SPEC and SPEC.loader
authority = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(authority)


class AuthorityTests(unittest.TestCase):
    def test_missing_empty_wrong_size_and_wrong_hash_rejected(self) -> None:
        for data in (b"", b"A", b"B" * 32):
            with self.assertRaises(authority.AuthorityFailure):
                authority.require_bytes(data, "0" * 64, 32)

    def test_wrong_tool_build_rejected(self) -> None:
        for text in ("", "vivado v2025.2 (64-bit)\nSW Build 1", "vivado v2024.2 (64-bit)\nSW Build 6299465"):
            with self.assertRaises(authority.AuthorityFailure):
                authority.require_tool_version(text)

    def test_exact_tool_header_accepted(self) -> None:
        authority.require_tool_version("vivado v2025.2 (64-bit)\nSW Build 6299465")


if __name__ == "__main__":
    unittest.main(verbosity=2)
