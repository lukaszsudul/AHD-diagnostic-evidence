"""Snapshot validation and read-only detector tuple extraction."""

from __future__ import annotations

from .manifest import ManifestEntry, SEMANTIC_SHA256


PRIVATE_BANK = {"CH1": 0x05, "CH2": 0x06, "CH3": 0x07, "CH4": 0x08}


def validate_entries(words: list[int], manifest: list[ManifestEntry], prohibited: list[tuple[int, int]]) -> list[dict]:
    if len(words) != 82:
        raise RuntimeError("SNAPSHOT_ENTRY_COUNT_NOT_82")
    prohibited_set = set(prohibited)
    result: list[dict] = []
    for expected, word in zip(manifest, words):
        bank = (word >> 24) & 0xFF
        register = (word >> 16) & 0xFF
        value = (word >> 8) & 0xFF
        status = word & 0xFF
        if (bank, register) != (expected.bank, expected.register):
            raise RuntimeError(f"ENTRY_IDENTITY_MISMATCH:{expected.index}")
        if (bank, register) in prohibited_set:
            raise RuntimeError(f"PROHIBITED_READ_OBSERVED:{bank:02X}:{register:02X}")
        if status & 0x01 == 0 or status & 0x04 == 0 or status >> 4:
            raise RuntimeError(f"ENTRY_STATUS_INVALID:{expected.index}:{status:02X}")
        result.append({
            "index": expected.index,
            "bank": bank,
            "register": register,
            "value": value,
            "status": status,
            "authority": expected.authority,
        })
    return result


def detector_tuples(entries: list[dict], a8_value: int) -> dict[str, dict]:
    by_address = {(entry["bank"], entry["register"]): entry["value"] for entry in entries}
    result: dict[str, dict] = {}
    for channel_index, channel in enumerate(("CH1", "CH2", "CH3", "CH4")):
        bank = PRIVATE_BANK[channel]
        private = {f"{register:02X}": by_address[(bank, register)] for register in (0xF0, 0xF2, 0xF3, 0xF4, 0xF5, 0xE2, 0xE3, 0xE8, 0xE9, 0xEA, 0xEB)}
        lock = {
            "E0": by_address[(0, 0xE0)], "E1": by_address[(0, 0xE1)],
            "E2": by_address[(0, 0xE2)], "7A": by_address[(0, 0x7A)],
            "7B": by_address[(0, 0x7B)],
        }
        raw_tuple = [a8_value, *lock.values(), *private.values()]
        result[channel] = {
            "novid": (a8_value >> channel_index) & 1,
            "lock_tuple": lock,
            "private_detector": private,
            "raw_tuple": raw_tuple,
            "raw_f0": private["F0"],
        }
    return result


def classify_stable_tuple(channel: dict) -> str:
    f0 = channel["raw_f0"]
    if channel["novid"]:
        return "NO_SIGNAL_OBSERVED"
    if f0 == 0x31:
        return "FORMAT_0x31_AHD_OR_CVI_COMPATIBILITY_REQUIRED"
    if (f0 & 0x0F) == 0x0F or (f0 >> 4) == 0x0F:
        return "SIGNAL_RESPONSE_PRESENT_FORMAT_UNRESOLVED"
    return "SIGNAL_PRESENT_UNSUPPORTED_PRODUCT_FORMAT"


def schema_identity() -> str:
    return SEMANTIC_SHA256

