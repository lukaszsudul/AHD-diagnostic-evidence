# SANITIZED PUBLICATION COPY; executed-source SHA-256: 9406245BE89D0765ABCFD3810D69ECBF28C1976731851BB076FB4B737B9FAACF
"""Frozen SCAN0 manifest loader and fail-closed validation."""

from __future__ import annotations

import csv
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path


RESOURCE_ROOT = Path(__file__).resolve().parent / "resources"
READ_CSV = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.csv"
READ_JSON = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.json"
BLACKLIST_CSV = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_PROHIBITED_READS.csv"
MMIO_CSV = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_MMIO_MAP.csv"
AUTHORITY_CSV = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_REGISTER_AUTHORITY_MATRIX.csv"
SCHEMA_JSON = RESOURCE_ROOT / "G2B_NVP_CAMERA_SCAN1_R1_SCAN_SCHEMA.json"

EXPECTED_HASHES = {
    READ_CSV.name: "C7211D562F7B932CFF023331E34A0D3507A9904B73A85EC357FEF19B7136626C",
    READ_JSON.name: "69C6C3518A737C33E5DBC654D20616D5FEC4B9A828EA5CE52061001D564112B5",
    BLACKLIST_CSV.name: "6C1F770CDF5B184E4E80E9C8DF8DF3696E2BA595121844A8F16682937F3B6440",
    MMIO_CSV.name: "42103EF8B9E5EEE01AD5CEEE80D4B3C3CB7C4E6F57A8307D6BC1F7E24523130A",
    AUTHORITY_CSV.name: "14118F762BB50A73C2195F8A6DD07D9FBDE9A09E0160E24637AAB3B894C845AE",
    SCHEMA_JSON.name: "C2B817FE31193471071B9232FAD8A9A1100B02AA688F7ACBE693D9CCB91F0074",
    "G2B_NVP_CAMERA_SCAN1_R1_HOST_DETECTION_STATE_MACHINE.json": "DCDD0DEEA3BD9427FECFE528EDB69BD768FE4418FA89686E2582ABF894D8A1DB",
    "G2B_NVP_CAMERA_SCAN1_R1_FORMAT_DETECTION_DECISION_TREE.json": "110A42871547B7A3DB5212A35BA9FC90F54B851EF6E62FFF7A0DDEFBB22B238B",
    "G2B_NVP_CAMERA_SCAN1_R1_FORMAT_DEBOUNCE_STATE_MACHINE.json": "7126569A27CEA10E2B61EF80D04834F54C30A0CE5C64AD845EE73EEEF03BA98E",
    "G2B_NVP_CAMERA_SCAN1_R1_SCIENTIFIC_OUTCOME_RULES.md": "94D206E100583E9FB6B9F2EA1DAB6381B2895DC6149639FFE2CF8FDC2D0A2D02",
    "G2B_NVP_CAMERA_SCAN1_R1_STATUS_ENCODING.md": "B1B4D9599B9D98EB852CAD686A62A095561E4D05CBBD99079B8A23AC7DF6DEBA",
    "G2B_NVP_CAMERA_SCAN1_R1_MMIO_CONTRACT.md": "16AA23D7E52F8255C37EE1832CBDD7CEA7B47F5DE985F821380A8EE3CFCC9D72",
}
SEMANTIC_SHA256 = "2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B"
GROUP_NAMES = ("G0-PRE", "G0-ID", "G0-LOCK", "G0-CH", "G1", "G2", "G3", "G4", "G5", "G0-POST")


@dataclass(frozen=True)
class ManifestEntry:
    index: int
    group: str
    bank: int
    register: int
    channel_scope: str
    meaning: str
    authority: str
    raw_semantics_partial: bool


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def load_and_validate() -> tuple[list[ManifestEntry], list[tuple[int, int]], dict]:
    for name, expected in EXPECTED_HASHES.items():
        path = RESOURCE_ROOT / name
        if not path.is_file() or _sha256(path) != expected:
            raise RuntimeError(f"FROZEN_RESOURCE_IDENTITY_MISMATCH:{name}")

    raw = json.loads(READ_JSON.read_text(encoding="utf-8"))
    rows = _rows(READ_CSV)
    prohibited_rows = _rows(BLACKLIST_CSV)
    if raw.get("entry_count") != 82 or len(rows) != 82:
        raise RuntimeError("READ_MANIFEST_ENTRY_COUNT_NOT_82")
    if tuple(raw.get("bank_groups", ())) != GROUP_NAMES:
        raise RuntimeError("BANK_GROUP_IDENTITY_NOT_10")
    if raw.get("manifest_sha256", "").upper() != SEMANTIC_SHA256:
        raise RuntimeError("READ_MANIFEST_SEMANTIC_IDENTITY_MISMATCH")
    if raw.get("mode") != "READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT":
        raise RuntimeError("SCAN_MODE_MISMATCH")
    if raw.get("i2c_hz") != 25_000:
        raise RuntimeError("I2C_FREQUENCY_MISMATCH")

    entries: list[ManifestEntry] = []
    for index, row in enumerate(rows):
        if int(row["EntryIndex"]) != index or row["Operation"] != "READ_ONLY":
            raise RuntimeError(f"READ_MANIFEST_ORDER_OR_OPERATION:{index}")
        partial = row["InterpretationUnresolved"] == "YES"
        entries.append(ManifestEntry(
            index=index,
            group=row["Group"],
            bank=int(row["Bank"], 16),
            register=int(row["Register"], 16),
            channel_scope=row["ChannelScope"],
            meaning=row["Meaning"],
            authority="RAW_SEMANTICS_PARTIAL" if partial else row["AuthorityClass"],
            raw_semantics_partial=partial,
        ))
    if sum(entry.raw_semantics_partial for entry in entries) != 40:
        raise RuntimeError("RAW_SEMANTICS_PARTIAL_COUNT_NOT_40")
    prohibited = [(int(row["Bank"], 16), int(row["Register"], 16)) for row in prohibited_rows]
    if len(prohibited) != 14 or set(prohibited) & {(e.bank, e.register) for e in entries}:
        raise RuntimeError("PROHIBITED_READ_GATE_FAILED")
    if (entries[0].bank, entries[0].register, entries[-1].bank, entries[-1].register) != (0, 0xA8, 0, 0xA8):
        raise RuntimeError("A8_BOOKEND_IDENTITY_FAILED")
    return entries, prohibited, raw
