"""Bounded SCAN1 identity, MMIO sanity, ONESHOT, and campaign controller."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

from . import decoder, evidence, manifest, mmio, state


EXPECTED_MAGIC = 0x4E565343
EXPECTED_VERSION = 0x00010001
EXPECTED_CAPABILITIES = 0x0000000F


class ScannerController:
    def __init__(self, device: mmio.MmioDevice):
        self.device = device
        self.entries, self.prohibited, self.raw_manifest = manifest.load_and_validate()

    def identity(self) -> dict:
        words = [self.device.read32(mmio.DIGEST_BASE + 4 * index) for index in range(8)]
        digest = "".join(f"{word:08X}" for word in words)
        result = {
            "magic": self.device.read32(mmio.MAGIC),
            "version": self.device.read32(mmio.VERSION),
            "capabilities": self.device.read32(mmio.CAPABILITIES),
            "entry_count": self.device.read32(mmio.ENTRY_COUNT),
            "bank_group_count": 10,
            "manifest_sha256": digest,
            "mode": "READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT",
            "i2c_hz": 25_000,
        }
        expected = (EXPECTED_MAGIC, EXPECTED_VERSION, EXPECTED_CAPABILITIES, 82, manifest.SEMANTIC_SHA256)
        actual = (result["magic"], result["version"], result["capabilities"], result["entry_count"], digest)
        if actual != expected:
            raise RuntimeError(f"RUNTIME_IDENTITY_MISMATCH:{actual!r}")
        return result

    def mmio_sanity(self, cycles: int = 16) -> list[dict]:
        rows = []
        for index in range(cycles):
            magic_value = self.device.read32(mmio.MAGIC)
            version_value = self.device.read32(mmio.VERSION)
            self.device.write32(mmio.CONTROL, mmio.CONTROL_ACK_CLEAR)
            status_value = self.device.read32(mmio.STATUS)
            generation_value = self.device.read32(mmio.GENERATION)
            values = (magic_value, version_value, status_value, generation_value)
            if 0xFFFFFFFF in values or magic_value != EXPECTED_MAGIC or version_value != EXPECTED_VERSION:
                raise RuntimeError(f"MMIO_SANITY_FAILED:{index}")
            rows.append({"cycle": index + 1, "magic": magic_value, "version": version_value,
                         "status": status_value, "generation": generation_value, "result": "PASS"})
        return rows

    def _wait_terminal(self, timeout_seconds: float) -> int:
        deadline = time.monotonic() + timeout_seconds
        while time.monotonic() < deadline:
            status_value = self.device.read32(mmio.STATUS)
            if status_value & mmio.STATUS_DONE:
                return status_value
            if status_value & (mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT):
                raise RuntimeError(f"SCANNER_TERMINAL_ERROR:{status_value:#010x}")
            time.sleep(0.005)
        raise TimeoutError("SCANNER_ONESHOT_TIMEOUT")

    def _read_frozen(self) -> dict:
        for attempt in range(1, 4):
            generation0 = self.device.read32(mmio.GENERATION)
            header_addresses = list(range(mmio.STATUS, mmio.DIGEST_BASE + 8 * 4, 4))
            header_words = [self.device.read32(address) for address in header_addresses]
            group_words = [self.device.read32(mmio.GROUP_BASE + 4 * index) for index in range(40)]
            entry_words = [self.device.read32(mmio.ENTRY_BASE + 4 * index) for index in range(82)]
            generation1 = self.device.read32(mmio.GENERATION)
            status_value = header_words[0]
            if generation0 != generation1 or not status_value & mmio.STATUS_DONE:
                continue
            values = {address: value for address, value in zip(header_addresses, header_words)}
            digest = "".join(f"{values[mmio.DIGEST_BASE + 4 * index]:08X}" for index in range(8))
            scan_flags = values[mmio.SCAN_FLAGS]
            if values[mmio.ENTRY_COUNT] != 82 or values[mmio.VALID_ENTRY_COUNT] != 82:
                raise RuntimeError("RUNTIME_ENTRY_COUNT_GATE_FAILED")
            if values[mmio.FAILED_ENTRY_COUNT] != 0 or digest != manifest.SEMANTIC_SHA256:
                raise RuntimeError("RUNTIME_SNAPSHOT_IDENTITY_OR_ERROR_GATE_FAILED")
            if scan_flags & 0x1 == 0 or scan_flags & 0x4 == 0 or scan_flags >> 16 != 105:
                raise RuntimeError(f"RUNTIME_SCAN_FLAGS_FAILED:{scan_flags:#010x}")
            entry_bank_word = values[mmio.ENTRY_BANK]
            exit_bank_word = values[mmio.EXIT_BANK]
            if entry_bank_word & 0x100 == 0 or exit_bank_word & 0x100 == 0 or (entry_bank_word & 0xFF) != (exit_bank_word & 0xFF):
                raise RuntimeError("ENTRY_BANK_RESTORE_GATE_FAILED")
            decoded_entries = decoder.validate_entries(entry_words, self.entries, self.prohibited)
            a8 = values[mmio.A8_PRE_POST]
            a8_pre, a8_post = a8 & 0xFF, (a8 >> 8) & 0xFF
            channels = decoder.detector_tuples(decoded_entries, a8_post)
            raw_words = header_words + group_words + entry_words
            return {
                "generation": generation0,
                "consistency_attempt": attempt,
                "manifest_sha256": digest,
                "entry_count": 82,
                "bank_group_count": 10,
                "transaction_count": scan_flags >> 16,
                "entry_bank": entry_bank_word & 0xFF,
                "exit_bank": exit_bank_word & 0xFF,
                "entry_bank_restore": "PASS",
                "a8_pre": a8_pre,
                "a8_post": a8_post,
                "live_status_changed": a8_pre != a8_post,
                "start_ticks": values[mmio.START_TICKS_LO] | (values[mmio.START_TICKS_HI] << 32),
                "end_ticks": values[mmio.END_TICKS_LO] | (values[mmio.END_TICKS_HI] << 32),
                "raw_register_set": decoded_entries,
                "channels": channels,
                "_raw_words": raw_words,
            }
        raise RuntimeError("SNAPSHOT_CONSISTENCY_RETRIES_EXHAUSTED")

    def oneshot(self, output_prefix: Path, timeout_seconds: float = 3.0) -> tuple[dict, dict]:
        status_before = self.device.read32(mmio.STATUS)
        if status_before & mmio.STATUS_IDLE == 0 or status_before & (mmio.STATUS_BUSY | mmio.STATUS_DONE | mmio.STATUS_ERROR):
            raise RuntimeError(f"SCANNER_NOT_IDLE:{status_before:#010x}")
        self.device.write32(mmio.CONTROL, mmio.CONTROL_ONESHOT)
        self._wait_terminal(timeout_seconds)
        snapshot = self._read_frozen()
        receipt = evidence.persist_snapshot(output_prefix, snapshot)
        self.device.write32(mmio.CONTROL, mmio.CONTROL_ACK_CLEAR)
        deadline = time.monotonic() + 1.0
        while time.monotonic() < deadline:
            if self.device.read32(mmio.STATUS) & mmio.STATUS_IDLE:
                return snapshot, receipt
            time.sleep(0.002)
        raise RuntimeError("SCANNER_ACK_DID_NOT_RETURN_IDLE")


def self_test() -> None:
    entries, prohibited, raw = manifest.load_and_validate()
    if len(entries) != 82 or len(prohibited) != 14 or raw["manifest_sha256"] != manifest.SEMANTIC_SHA256:
        raise RuntimeError("SELF_TEST_MANIFEST_FAILED")
    synthetic_words = [(entry.bank << 24) | (entry.register << 16) | (0x10 << 8) | 0x05 for entry in entries]
    synthetic_words[0] = (entries[0].bank << 24) | (entries[0].register << 16) | (0x0F << 8) | 0x05
    synthetic_words[81] = (entries[81].bank << 24) | (entries[81].register << 16) | (0x0F << 8) | 0x05
    decoded = decoder.validate_entries(synthetic_words, entries, prohibited)
    channels = decoder.detector_tuples(decoded, 0x0F)
    campaign = state.CampaignState("SELF_TEST")
    for generation in range(1, 4):
        campaign.update("BASELINE", {"generation": generation, "live_status_changed": False, "channels": channels})
    if any(channel.agreeing_sample_count != 3 or channel.confirmed_format != "NO_SIGNAL_OBSERVED" for channel in campaign.channels.values()):
        raise RuntimeError("SELF_TEST_DEBOUNCE_FAILED")
    campaign.update("BASELINE", {"generation": 4, "live_status_changed": True, "channels": channels})
    if any(channel.agreeing_sample_count != 3 for channel in campaign.channels.values()):
        raise RuntimeError("SELF_TEST_BOOKEND_EXCLUSION_FAILED")
    print("PASS SCAN1_RUNTIME_SELF_TEST")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--identity", action="store_true")
    parser.add_argument("--mmio-sanity", action="store_true")
    parser.add_argument("--oneshot-prefix", type=Path)
    args = parser.parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    with mmio.MmioDevice(args.device) as device:
        controller = ScannerController(device)
        output: object
        if args.identity:
            output = controller.identity()
        elif args.mmio_sanity:
            output = controller.mmio_sanity()
        elif args.oneshot_prefix:
            snapshot, receipt = controller.oneshot(args.oneshot_prefix)
            output = {"snapshot": snapshot, "receipt": receipt}
        else:
            parser.error("select --self-test, --identity, --mmio-sanity, or --oneshot-prefix")
        print(json.dumps(output, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
