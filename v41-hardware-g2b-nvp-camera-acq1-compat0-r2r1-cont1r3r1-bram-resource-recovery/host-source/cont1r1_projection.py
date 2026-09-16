"""CONT1R1 manifest-derived, full-key SCAN1 configuration projection.

This module is deliberately host-only. It consumes the frozen SCAN1 manifest
and never exposes an NVP write interface.
"""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable, Mapping

BUNDLE_ROOT = Path(__file__).resolve().parent
if str(BUNDLE_ROOT) not in sys.path:
    sys.path.insert(0, str(BUNDLE_ROOT))

from scan1.manifest import GROUP_NAMES, ManifestEntry, load_and_validate


SCHEMA_PATH = BUNDLE_ROOT / "CONT1R1_CONFIGURATION_PROJECTION_SCHEMA.json"
EXPECTED_SCHEMA = "AHD_V41_CONT1R1_CONFIGURATION_PROJECTION_SCHEMA_V1"
EXPECTED_KEY_TYPE = "BANK_AND_REGISTER_PAIR"
EXPECTED_MANIFEST_SHA256 = (
    "2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B"
)
EXPECTED_REPEATED_SCAN_KEYS = {(0x00, 0xA8): (0, 4, 81)}
REJECTED_LEGACY_KEYS = {(0x01, register) for register in range(0x88, 0x8C)}


class ProjectionGateError(RuntimeError):
    """A closed host projection gate failed."""


def key_text(key: tuple[int, int]) -> str:
    return f"(0x{key[0]:02X},0x{key[1]:02X})"


def _require(condition: bool, reason: str) -> None:
    if not condition:
        raise ProjectionGateError(reason)


def load_schema() -> dict:
    _require(SCHEMA_PATH.is_file(), "CONT1R1_PROJECTION_SCHEMA_MISSING")
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    _require(schema.get("schema") == EXPECTED_SCHEMA, "CONT1R1_PROJECTION_SCHEMA_IDENTITY")
    _require(schema.get("key_type") == EXPECTED_KEY_TYPE, "CONT1R1_PROJECTION_KEY_TYPE")
    return schema


def expand_schema(schema: Mapping | None = None) -> list[dict]:
    source = dict(schema or load_schema())
    expanded: list[dict] = []
    for item in source.get("fixed_requirements", []):
        expanded.append({
            "bank": int(item["bank"]),
            "register": int(item["register"]),
            "semantic_family": str(item["semantic_family"]),
            "channel": item.get("channel"),
            "read_safe_authority": str(item["read_safe_authority"]),
            "derivation": "fixed_exact_key",
        })
    for family in source.get("channel_families", []):
        _require(
            family.get("register_rule") == "base_register_plus_channel",
            "CONT1R1_PROJECTION_CHANNEL_RULE_UNSUPPORTED",
        )
        first, last = (int(value) for value in family["channel_range"])
        _require((first, last) == (0, 3), "CONT1R1_PROJECTION_CHANNEL_RANGE_NOT_0_TO_3")
        for channel in range(first, last + 1):
            expanded.append({
                "bank": int(family["bank"]),
                "register": int(family["base_register"]) + channel,
                "semantic_family": str(family["semantic_family"]),
                "channel": channel,
                "read_safe_authority": str(family["read_safe_authority"]),
                "derivation": "base_register_plus_channel",
            })
    keys = [(item["bank"], item["register"]) for item in expanded]
    _require(len(keys) == len(set(keys)), "CONT1R1_PROJECTION_SCHEMA_DUPLICATE_FULL_KEY")
    return sorted(expanded, key=lambda item: (item["bank"], item["register"]))


def required_projection_keys(schema: Mapping | None = None) -> frozenset[tuple[int, int]]:
    return frozenset((item["bank"], item["register"]) for item in expand_schema(schema))


def projection_key_preflight(
    manifest_keys: Iterable[tuple[int, int]],
    schema: Mapping | None = None,
) -> dict:
    available = {(int(bank), int(register)) for bank, register in manifest_keys}
    required = required_projection_keys(schema)
    missing = sorted(required - available)
    if missing:
        raise ProjectionGateError(
            "HOST_PROJECTION_KEY_NOT_IN_SCANNER_MANIFEST:"
            + ",".join(key_text(key) for key in missing)
        )
    return {
        "result": "PASS",
        "key_type": EXPECTED_KEY_TYPE,
        "required_projection_key_count": len(required),
        "available_manifest_key_count": len(available),
        "missing_projection_keys": [],
    }


def manifest_preflight(
    entries: Iterable[ManifestEntry] | None = None,
    schema: Mapping | None = None,
) -> dict:
    if entries is None:
        loaded_entries, prohibited, manifest = load_and_validate()
    else:
        loaded_entries = list(entries)
        prohibited = []
        manifest = {
            "entry_count": len(loaded_entries),
            "bank_groups": list(GROUP_NAMES),
            "manifest_sha256": EXPECTED_MANIFEST_SHA256,
        }

    entry_list = list(loaded_entries)
    keys = [(int(item.bank), int(item.register)) for item in entry_list]
    key_set = set(keys)
    required = required_projection_keys(schema)
    projection_key_preflight(key_set, schema)

    indices_by_key: dict[tuple[int, int], list[int]] = defaultdict(list)
    for item in entry_list:
        indices_by_key[(int(item.bank), int(item.register))].append(int(item.index))
    repeated = {
        key: tuple(indices)
        for key, indices in indices_by_key.items()
        if len(indices) > 1
    }
    unexpected_repeated = {
        key: indices
        for key, indices in repeated.items()
        if EXPECTED_REPEATED_SCAN_KEYS.get(key) != indices
    }
    _require(not unexpected_repeated, "UNEXPECTED_DUPLICATE_FULL_MANIFEST_KEY")
    _require(repeated == EXPECTED_REPEATED_SCAN_KEYS, "GOVERNED_A8_SCAN_SAMPLING_IDENTITY_MISMATCH")

    projection_counts = Counter(required)
    duplicate_projection_keys = sorted(key for key, count in projection_counts.items() if count > 1)
    _require(not duplicate_projection_keys, "DUPLICATE_FULL_PROJECTION_KEY")
    _require(len(entry_list) == 82, "SCAN1_MANIFEST_ENTRY_COUNT_NOT_82")
    _require(tuple(manifest.get("bank_groups", ())) == GROUP_NAMES, "SCAN1_MANIFEST_GROUP_COUNT_NOT_10")
    _require(
        str(manifest.get("manifest_sha256", "")).upper() == EXPECTED_MANIFEST_SHA256,
        "SCAN1_MANIFEST_SHA256_IDENTITY_MISMATCH",
    )
    _require(not (REJECTED_LEGACY_KEYS & required), "LEGACY_0x88_FAMILY_REQUIRED")

    return {
        "result": "PASS",
        "key_type": EXPECTED_KEY_TYPE,
        "manifest_entry_count": len(entry_list),
        "manifest_bank_group_count": len(GROUP_NAMES),
        "manifest_unique_full_key_count": len(key_set),
        "governed_repeated_scan_keys": {
            key_text(key): list(indices) for key, indices in sorted(repeated.items())
        },
        "governed_repeated_scan_key_count": len(repeated),
        "governed_repeated_scan_key_extra_occurrences": sum(len(indices) - 1 for indices in repeated.values()),
        "unexpected_duplicate_full_manifest_keys": 0,
        "duplicate_full_projection_keys": 0,
        "required_projection_key_count": len(required),
        "missing_projection_keys": [],
        "rejected_legacy_keys_present_in_manifest": sorted(
            key_text(key) for key in REJECTED_LEGACY_KEYS & key_set
        ),
        "prohibited_read_count": len(prohibited),
    }


def raw_register_map(snapshot: Mapping) -> dict[tuple[int, int], int]:
    values: dict[tuple[int, int], int] = {}
    observations: dict[tuple[int, int], list[int]] = defaultdict(list)
    for item in snapshot["raw_register_set"]:
        key = (int(item["bank"]), int(item["register"]))
        value = int(item["value"])
        observations[key].append(value)
        values[key] = value
    for key, observed in observations.items():
        if key in EXPECTED_REPEATED_SCAN_KEYS:
            _require(len(observed) == 3, "A8_SCAN_SAMPLE_COUNT_NOT_THREE")
            _require(observed[0] == observed[-1], "A8_PRE_POST_VALUE_MISMATCH")
        else:
            _require(len(observed) == 1, "SNAPSHOT_UNEXPECTED_DUPLICATE_FULL_KEY")
    return values


def configuration_projection(snapshot: Mapping, schema: Mapping | None = None) -> dict[str, int]:
    manifest_preflight(schema=schema)
    values = raw_register_map(snapshot)
    required = required_projection_keys(schema)
    missing = sorted(required - set(values))
    if missing:
        raise ProjectionGateError(
            "SCAN1_CONFIGURATION_PROJECTION_INCOMPLETE:"
            + ",".join(key_text(key) for key in missing)
        )
    return {
        f"{bank:02X}:{register:02X}": values[(bank, register)]
        for bank, register in sorted(required)
    }


def self_test() -> None:
    receipt = manifest_preflight()
    _require(receipt["required_projection_key_count"] == 13, "PROJECTION_KEY_COUNT_NOT_13")
    expanded = expand_schema()
    adc = {(item["bank"], item["register"]) for item in expanded if item["semantic_family"] == "adc_clock_delay"}
    pre = {(item["bank"], item["register"]) for item in expanded if item["semantic_family"] == "pre_clock"}
    _require(adc == {(1, value) for value in range(0x84, 0x88)}, "ADC_DELAY_EXPANSION_MISMATCH")
    _require(pre == {(1, value) for value in range(0x8C, 0x90)}, "PRE_CLOCK_EXPANSION_MISMATCH")
    print("PASS CONT1R1_PROJECTION_SELF_TEST")


if __name__ == "__main__":
    self_test()
