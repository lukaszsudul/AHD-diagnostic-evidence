#!/usr/bin/env python3
"""Closed-bundle hash, import-origin, projection, and integrity smoke gate."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import importlib
import io
import json
import os
import struct
import subprocess
import sys
from pathlib import Path


MANIFEST_JSON = "CONT1R2_RUNTIME_BUNDLE_MANIFEST.json"
MANIFEST_TSV = "CONT1R2_RUNTIME_BUNDLE_MANIFEST.tsv"
MANIFEST_SHA = "CONT1R2_RUNTIME_BUNDLE_MANIFEST.sha256"
EXPECTED_PRIOR_RAW_SHA256 = "671D570715F53E6E1EEB74ADCB7BF08D18C24223FFB191CDE9B8436D89509C6D"
EXPECTED_PRIOR_JSON_SHA256 = "D529C28F64CD1880085BA68B97B9142325AFFA79C75E1E66472F1DA86AE43F69"
EXPECTED_PROJECTION_SHA256 = "46DD0D28658190FC7DDF66D60DEB525F187B23DAAAB35C4FB24EC405E0B5D1C9"


class BundleGateError(RuntimeError):
    pass


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise BundleGateError(reason)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def contained(root: Path, path: Path) -> bool:
    resolved = path.resolve(strict=True)
    return resolved == root or root in resolved.parents


def relative_files(root: Path) -> set[str]:
    return {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc"
    }


def prior_snapshot(path: Path) -> dict[str, object]:
    value = json.loads(path.read_text(encoding="utf-8"))
    value["raw_register_set"] = [dict(row) for row in value["entry_words"]]
    value["bank_group_count"] = 10
    return value


def run_gate(root: Path) -> dict[str, object]:
    root = root.resolve(strict=True)
    require(root.is_dir() and not root.is_symlink(), "BUNDLE_ROOT_INVALID")
    for path in root.rglob("*"):
        require(not path.is_symlink(), f"BUNDLE_SYMLINK:{path.relative_to(root).as_posix()}")

    manifest_path = root / MANIFEST_JSON
    tsv_path = root / MANIFEST_TSV
    sha_path = root / MANIFEST_SHA
    require(manifest_path.is_file() and tsv_path.is_file() and sha_path.is_file(), "MANIFEST_SET_MISSING")
    expected_manifest_sha = sha_path.read_text(encoding="ascii").strip().upper()
    require(sha256(manifest_path) == expected_manifest_sha, "MANIFEST_SHA256_MISMATCH")
    manifest_value = json.loads(manifest_path.read_text(encoding="utf-8"))
    require(manifest_value.get("schema") == "AHD_V41_CONT1R2_RUNTIME_BUNDLE_MANIFEST_V1", "MANIFEST_SCHEMA")
    files = list(manifest_value.get("files", []))
    require(manifest_value.get("file_count") == len(files), "MANIFEST_FILE_COUNT")
    listed = {str(item["path"]) for item in files}
    require(len(listed) == len(files), "MANIFEST_DUPLICATE_PATH")
    actual = relative_files(root)
    require(actual == listed | {MANIFEST_JSON, MANIFEST_TSV, MANIFEST_SHA}, "RELATIVE_FILE_SET_MISMATCH")
    for item in files:
        path = root / str(item["path"])
        require(contained(root, path), f"PATH_ESCAPE:{item['path']}")
        require(path.stat().st_size == int(item["size"]), f"SIZE_MISMATCH:{item['path']}")
        require(sha256(path) == str(item["sha256"]).upper(), f"SHA256_MISMATCH:{item['path']}")

    python_files = sorted(path for path in root.rglob("*.py") if path.is_file())
    for path in python_files:
        compile(path.read_text(encoding="utf-8-sig"), str(path), "exec")

    sys.path.insert(0, str(root))
    names = (
        "scan1.manifest",
        "scan1.mmio",
        "scan1.decoder",
        "scan1.controller",
        "acq1_compat0_r2.contract",
        "acq1_compat0_r2.mmio",
        "acq1_compat0_r2.controller",
        "acq1_compat0_r2.policy",
        "acq1_compat0_r2.format_decision",
        "acq1_compat0_r2.campaign",
        "cont1r1_projection",
        "g2b_nvp_camera_acq1_compat0_r2r1_controller",
        "cont1r2_integrity",
        "cont1r2_runtime_gate",
    )
    origins: dict[str, str] = {}
    modules = {}
    for name in names:
        module = importlib.import_module(name)
        origin = Path(module.__file__).resolve(strict=True)
        require(contained(root, origin), f"MODULE_ORIGIN_VIOLATION:{name}:{origin}")
        origins[name] = origin.relative_to(root).as_posix()
        modules[name] = module

    projection = modules["cont1r1_projection"]
    controller = modules["g2b_nvp_camera_acq1_compat0_r2r1_controller"]
    integrity = modules["cont1r2_integrity"]
    require(sha256(root / "cont1r1_projection.py") == EXPECTED_PROJECTION_SHA256, "FROZEN_PROJECTION_SHA256")
    with contextlib.redirect_stdout(io.StringIO()):
        projection.self_test()
        controller.self_test()
        integrity.self_test()
    integrity_smoke = subprocess.run(
        [sys.executable, "-I", "-S", str(root / "cont1r2_integrity_launcher.py"), "--self-test"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    require(integrity_smoke.returncode == 0, f"INTEGRITY_ENTRYPOINT_SMOKE:{integrity_smoke.stderr}")
    runtime_smoke = subprocess.run(
        [sys.executable, "-I", "-S", str(root / "cont1r2_runtime_gate.py"), "--help"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    require(runtime_smoke.returncode == 0, f"RUNTIME_ENTRYPOINT_SMOKE:{runtime_smoke.stderr}")
    preflight = projection.manifest_preflight()
    require(preflight["result"] == "PASS", "PROJECTION_PREFLIGHT")

    tests = json.loads((root / "cont1r2_resources/CONT1R2_HOST_INTEGRITY_TEST_RESULTS.json").read_text(encoding="utf-8"))
    require(tests.get("result") == "PASS" and tests.get("passed") == 18 and tests.get("total") == 18, "HOST_INTEGRITY_TESTS_NOT_18_OF_18")

    prior_raw = root / "cont1r2_resources/prior-failed-scan.bin"
    prior_json = root / "cont1r2_resources/prior-failed-scan.json"
    require(sha256(prior_raw) == EXPECTED_PRIOR_RAW_SHA256, "PRIOR_RAW_SHA256")
    require(sha256(prior_json) == EXPECTED_PRIOR_JSON_SHA256, "PRIOR_JSON_SHA256")
    frozen = prior_snapshot(prior_json)
    analysis = integrity.analyze_snapshot(frozen, 1, "PRIOR_EVENT_REPLAY")
    require(not analysis["hard_stop"], f"PRIOR_EVENT_HARD_STOP:{analysis['hard_stop_reasons']!r}")
    require(analysis["recovered_nack_count"] == 1, "PRIOR_EVENT_RETRY_COUNT")
    require(analysis["transaction_count"] == 106, "PRIOR_EVENT_TRANSACTION_COUNT")
    require(analysis["events"][0]["exact_encoded_error_category_or_phase"] == "NOT_ENCODED", "PRIOR_EVENT_PHASE_DISPOSITION")
    require(analysis["projection"] == "PASS", "PRIOR_EVENT_PROJECTION")
    raw = prior_raw.read_bytes()
    words = struct.unpack(f"<{len(raw) // 4}I", raw)
    require(words[-82 + 62] == 0x07F40007, "PRIOR_EVENT_RAW_WORD")

    return {
        "schema": "AHD_V41_CONT1R2_CLOSED_RUNTIME_BUNDLE_GATE_V1",
        "result": "PASS",
        "bundle_root": str(root),
        "bundle_manifest_sha256": expected_manifest_sha,
        "payload_file_count": len(files),
        "deployed_file_count": len(actual),
        "unresolved_local_imports": 0,
        "missing_runtime_resources": 0,
        "module_origin_violations": 0,
        "compile_import_gate": "PASS",
        "entrypoint_smoke_tests": "PASS",
        "projection_tests": "PASS",
        "integrity_controller_tests": "18/18 PASS",
        "prior_event_replay": "PASS",
        "prior_event_exact_phase": "NOT_ENCODED",
        "isolated_mode": bool(sys.flags.isolated),
        "user_site_disabled": bool(sys.flags.no_user_site),
        "module_origins": origins,
    }


def main() -> int:
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle-root", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        result = run_gate(args.bundle_root)
        exit_code = 0
    except Exception as exc:
        result = {
            "schema": "AHD_V41_CONT1R2_CLOSED_RUNTIME_BUNDLE_GATE_V1",
            "result": "FAIL",
            "first_failed_gate": f"{type(exc).__name__}:{exc}",
        }
        exit_code = 1
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output is not None:
        args.output.write_text(rendered, encoding="utf-8")
    print(json.dumps(result, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
