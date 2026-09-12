#!/usr/bin/env python3
import csv
import hashlib
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
def rows(name):
    with (root / name).open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

touched = rows("G2B_NVP_CAMERA_ACQ1_R1_TOUCHED_REGISTER_MANIFEST.csv")
assert len(touched) == 138
assert sum(r["closure_status"] == "AUTHORIZED" for r in touched) == 6
assert sum(r["closure_status"] == "BLOCKING_AUTHORITY_GAP" for r in touched) == 132
assert sum(r["symbolic_preserved_field"] != "NO" for r in touched) == 2
assert all(r["known_blacklist_intersection"] == "NO" for r in touched)

assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_AHD1080P25_MODE_MANIFEST.csv")) == 161
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_INITIAL_EQ_MANIFEST.csv")) == 9
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_ACP_SUBSET_MANIFEST.csv")) == 35
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_REARM_ENABLE_MANIFEST.csv")) == 6
assert len(rows("G2B_NVP_CAMERA_ACQ1_R1_ROLLBACK_MANIFEST.csv")) == 138

slice_rows = rows("G2B_NVP_CAMERA_ACQ1_R1_SLICE_ACTION_MANIFEST.csv")
for level in ("0x50", "0x40", "0x60"):
    phase = [r for r in slice_rows if r["clean_room_action_phase"] == f"SLICE_{level}"]
    writes = [(i, r["register"], r["write_value_or_mask"]) for i, r in enumerate(phase) if r["operation_type"] == "WRITE"]
    assert writes == [(3, "0x08", level), (4, "0x05", "0xA4")]

manifest = root / "G2B_NVP_CAMERA_ACQ1_R1_SHA256_MANIFEST.txt"
for line in manifest.read_text(encoding="utf-8").splitlines():
    digest, relative = line.split("  ", 1)
    actual = hashlib.sha256((root / relative).read_bytes()).hexdigest().upper()
    assert actual == digest

prohibited_suffixes = {".bit", ".dcp", ".png", ".uyvy", ".bin", ".pdf"}
assert not [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in prohibited_suffixes]
print("ACQ1_R1_EVIDENCE_SELF_TEST=PASS")
print("TOUCHED=138 AUTHORIZED=6 GAPS=132 SYMBOLIC=2")
