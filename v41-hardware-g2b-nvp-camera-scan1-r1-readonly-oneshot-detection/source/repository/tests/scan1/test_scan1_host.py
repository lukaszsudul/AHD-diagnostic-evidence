from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "host"))

from scan1 import controller, decoder, manifest, state  # noqa: E402


class Scan1HostTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.entries, cls.prohibited, cls.raw = manifest.load_and_validate()

    def test_frozen_manifest(self) -> None:
        self.assertEqual(len(self.entries), 82)
        self.assertEqual(len(self.prohibited), 14)
        self.assertEqual(sum(item.raw_semantics_partial for item in self.entries), 40)
        self.assertEqual(self.raw["manifest_sha256"], manifest.SEMANTIC_SHA256)

    def make_words(self, a8: int, f0: int = 0xFF) -> list[int]:
        words = []
        for entry in self.entries:
            value = 0x10
            if entry.bank == 0 and entry.register == 0xA8:
                value = a8
            if entry.bank in (5, 6, 7, 8) and entry.register == 0xF0:
                value = f0
            words.append((entry.bank << 24) | (entry.register << 16) | (value << 8) | 0x05)
        return words

    def test_three_sample_debounce_and_bookend_exclusion(self) -> None:
        decoded_entries = decoder.validate_entries(self.make_words(0x0F), self.entries, self.prohibited)
        channels = decoder.detector_tuples(decoded_entries, 0x0F)
        campaign = state.CampaignState("T24")
        for generation in range(1, 4):
            campaign.update("A", {"generation": generation, "live_status_changed": False, "channels": channels})
        self.assertTrue(all(item.agreeing_sample_count == 3 for item in campaign.channels.values()))
        campaign.update("A", {"generation": 4, "live_status_changed": True, "channels": channels})
        self.assertTrue(all(item.agreeing_sample_count == 3 for item in campaign.channels.values()))

    def test_0x31_remains_compatibility_required(self) -> None:
        entries = decoder.validate_entries(self.make_words(0x0E, 0x31), self.entries, self.prohibited)
        channel = decoder.detector_tuples(entries, 0x0E)["CH1"]
        self.assertEqual(decoder.classify_stable_tuple(channel),
                         "FORMAT_0x31_AHD_OR_CVI_COMPATIBILITY_REQUIRED")

    def test_unresolved_entries_cannot_establish_format(self) -> None:
        self.assertTrue(all(entry.authority == "RAW_SEMANTICS_PARTIAL"
                            for entry in self.entries if entry.raw_semantics_partial))

    def test_runtime_self_test(self) -> None:
        controller.self_test()


if __name__ == "__main__":
    unittest.main(verbosity=2)
