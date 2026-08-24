"""Offline-only R1g runtime, capability, and formal-zero contract fixtures."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
import unittest


TASK = Path(r"C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY")
READER_PATH = TASK / "09_HOST_TOOLS" / "frozen_r1f_host_tools" / "read_nvp_r1f.py"
RUNTIME_LEAF = TASK / "scripts" / "r1g_runtime_provenance_readonly.sh"
TEMPLATE = TASK / "09_HOST_TOOLS" / "R1G_HARDWARE_BINDINGS.template.json"


def load_reader():
    sys.path.insert(0, str(READER_PATH.parent))
    spec = importlib.util.spec_from_file_location("r1g_exact_r1f_reader", READER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("unable to load exact inherited R1f reader")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class R1gHardwareBindingContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.reader = load_reader()

    def test_r1g_runtime_source_commit_fixture(self) -> None:
        text = RUNTIME_LEAF.read_text(encoding="utf-8")
        self.assertIn("expected_r1g_commit=${2:?expected R1g commit required}", text)
        self.assertIn("git_sha != expected_commit", text)
        self.assertIn("build_flags != 0x00000002", text)
        self.assertIn("R1g source-commit provenance mismatch", text)
        self.assertIn("os.open(node, os.O_RDONLY | os.O_CLOEXEC)", text)
        self.assertNotIn("os.pwrite", text)

    def test_r1g_bit_capability_fixture(self) -> None:
        expected = self.reader.EXPECTED_HEADER
        self.assertEqual(expected[0x20A0], 0x31463152)
        self.assertEqual(expected[0x20A4], 1)
        self.assertEqual(expected[0x20A8], 0x000007FF)
        self.assertEqual(expected[0x20AC], 1)
        self.assertEqual(expected[0x20B0], 192)
        self.assertEqual(expected[0x20B4], 6)
        self.assertEqual(expected[0x20B8], 64)
        self.assertEqual(expected[0x20BC], 7)
        self.assertEqual(expected[0x20C0], 0x80008500)
        self.assertEqual(expected[0x20CC], 10000)
        binding = json.loads(TEMPLATE.read_text(encoding="utf-8"))
        self.assertEqual(binding["status"], "PENDING_R1G_BUILD")
        self.assertEqual(binding["r1gBit"]["bytes"], 0)
        self.assertEqual(binding["r1gBit"]["requiredWaitSeconds"], 33.536673744)
        self.assertEqual(
            binding["r1gBit"]["filename"],
            "ahd_capture_v41_i2c_25khz_r1g_phase_complete_observability.bit",
        )

    def test_formal_complete_r1f_range_zero_fixture(self) -> None:
        words = {
            0x0000: 0xA40A0C07,
            0x0004: 0x0000400B,
            0x0008: 0x00031002,
        }
        decoded = self.reader.decode_word_map(words, expect="formal")
        self.assertTrue(decoded["r1f_reserved_range_zero"])
        self.assertEqual(self.reader.R1F_FIRST, 0x20A0)
        self.assertEqual(self.reader.R1F_END_EXCLUSIVE, 0x3600)
        words[0x35FC] = 1
        with self.assertRaisesRegex(self.reader.R1FDecodeError, "deterministic zero"):
            self.reader.decode_word_map(words, expect="formal")


if __name__ == "__main__":
    unittest.main()
