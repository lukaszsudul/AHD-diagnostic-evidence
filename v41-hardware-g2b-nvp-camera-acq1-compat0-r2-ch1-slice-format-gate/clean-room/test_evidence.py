#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
required = json.loads((root / "G2B_NVP_ACQ1_COMPAT0_R2_STATE.json").read_text(encoding="utf-8"))
assert required["engineering_gate"] == "BLOCKED"
assert required["fresh_synthesis_gate"] == "FAIL"
assert required["operation_counts"]["SYNTH_DESIGN"] == "1"
for name in ("OPT_DESIGN", "PLACE_DESIGN", "PHYS_OPT_DESIGN", "ROUTE_DESIGN", "WRITE_BITSTREAM"):
    assert required["operation_counts"][name] == "0"
assert required["profile_receipt"]["NVP_CAMERA_ACQ1_COMPAT0_R2_WRAPPER_COUNT"] == "1"
assert required["profile_receipt"]["NVP_CAMERA_SCAN1_CORE_COUNT"] == "2"
assert required["functional_writes"] == 0
manifest = root / "G2B_NVP_ACQ1_COMPAT0_R2_SHA256_MANIFEST.txt"
for line in manifest.read_text(encoding="utf-8").splitlines():
    digest, rel = line.split("  ", 1)
    assert hashlib.sha256((root / rel).read_bytes()).hexdigest().upper() == digest
prohibited = {".bit", ".dcp", ".ltx", ".pdf", ".png", ".uyvy", ".exe", ".dll", ".sys"}
assert not [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in prohibited]
print("ACQ1_COMPAT0_R2_EVIDENCE_SELF_TEST=PASS")
