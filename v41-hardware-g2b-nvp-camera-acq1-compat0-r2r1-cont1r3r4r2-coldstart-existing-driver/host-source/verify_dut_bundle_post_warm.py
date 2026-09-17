#!/usr/bin/env python3
"""Read-only revalidation of the unchanged deployed bundle on the final boot."""

from __future__ import annotations

import datetime as dt
import hashlib
import importlib
import json
import os
from pathlib import Path
import sys

BASE = Path("/home/vcdeagent1/vcde_artifacts")
RUN = BASE / "g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart" / "20260917T063836Z"
DEST = RUN / "runtime-bundle"
PAYLOAD = DEST / "payload"
MANIFEST = DEST / "CONT1R3R4R2_CLOSED_RUNTIME_BUNDLE_MANIFEST.json"
VERIFIER = DEST / "verify_closed_bundle.py"
ARCHIVE = RUN / "private" / "CONT1R3R4R2_CLOSED_RUNTIME_BUNDLE.tar.gz"
LOCK = BASE / ".ahd_g2b_nvp_camera_acq1_compat0_r2r1_cont1r3r4r2_coldstart_20260917T063836Z.lock"
BOOT = "e9656f6c-dd41-4500-95cc-9dc90ef9b69d"
ARCHIVE_SHA = "1E17F681CEE13FAFB028DE9F75FDEB1B8B46F69C2B48A941CF5AB8A56B6263E3"
MANIFEST_SHA = "ABD3E857EDE3114F1AB1BE3C8389A502E6F9E8D996B34E9B019382E2415F7BEF"
VERIFIER_SHA = "ED9CB0AC4D8534F305F6B71EFB36C2DE3CAB188517B0C86400C5C4C9D3D116F3"
WRAPPER_SHA = "AEFF2027BEEDEC33A3D9C9E8BE67CC738BC328A893A48106D1E985B1FCBB7BC0"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def unique_by_path(rows: list[dict]) -> dict[str, dict]:
    mapping = {}
    for row in rows:
        name = row.get("path")
        if not isinstance(name, str) or name in mapping:
            raise RuntimeError("DUT_BUNDLE_DUPLICATE_OR_INVALID_PATH")
        mapping[name] = row
    return mapping


if os.geteuid() != 1000 or Path("/proc/sys/kernel/random/boot_id").read_text().strip() != BOOT:
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_OR_ACCOUNT_MISMATCH")
if not LOCK.is_dir() or LOCK.is_symlink() or \
        json.loads((LOCK / "receipt.json").read_text()).get("state") != "HELD":
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_LOCK_MISSING")
if sha(ARCHIVE) != ARCHIVE_SHA or sha(MANIFEST) != MANIFEST_SHA or \
        sha(VERIFIER) != VERIFIER_SHA or sha(PAYLOAD / "coldstart_admission.py") != WRAPPER_SHA:
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_ROOT_HASH_MISMATCH")
if any(path.is_symlink() for path in PAYLOAD.rglob("*")):
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_SYMLINK")

sys.dont_write_bytecode = True
sys.path.insert(0, str(DEST))
accepted = importlib.import_module("verify_closed_bundle")
if Path(accepted.__file__).resolve() != VERIFIER.resolve():
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_VERIFIER_ORIGIN_VIOLATION")
manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
expected = manifest.get("files")
actual = accepted.payload_rows(PAYLOAD)
if not isinstance(expected, list) or len(expected) != 34 or \
        len(actual) != 34 or unique_by_path(expected) != unique_by_path(actual):
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_SET_SIZE_OR_SHA_MISMATCH")
in_memory_manifest = dict(manifest)
in_memory_manifest["files"] = actual
gate = accepted.gate(PAYLOAD, in_memory_manifest)
if gate.get("result") != "PASS" or gate.get("file_count") != 34 or \
        gate.get("module_origin_violations") != 0 or gate.get("unresolved_imports") != 0 or \
        gate.get("missing_resources") != 0 or gate.get("campaign_scans") != 1000:
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_ACCEPTED_GATE_FAILED")
sys.path.insert(0, str(PAYLOAD))
wrapper = importlib.import_module("coldstart_admission")
if Path(wrapper.__file__).resolve() != (PAYLOAD / "coldstart_admission.py").resolve():
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_WRAPPER_ORIGIN_VIOLATION")
if wrapper.ENDPOINT != "10.132.1.111:22":
    raise SystemExit("DUT_BUNDLE_FINAL_BOOT_ENDPOINT_MISMATCH")
print(json.dumps({
    "schema": "AHD_V41_CONT1R3R4R2_FINAL_BOOT_BUNDLE_GATE_V1",
    "result": "PASS",
    "boot_id": BOOT,
    "archive_sha256": ARCHIVE_SHA,
    "manifest_sha256": MANIFEST_SHA,
    "payload_file_count": len(actual),
    "module_origin_violations": 0,
    "unresolved_imports": 0,
    "missing_resources": 0,
    "projection_preflight": gate["projection"]["result"],
    "campaign_scans": gate["campaign_scans"],
    "no_device_open_or_write": True,
    "verified_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
}, sort_keys=True, separators=(",", ":")))
