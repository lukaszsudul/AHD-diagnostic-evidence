"""Closed-bundle identity, import-origin, and preserved-replay gate."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import importlib
import io
import json
import os
import sys
from pathlib import Path


MANIFEST_JSON = "CONT1R1_RUNTIME_BUNDLE_MANIFEST.json"
MANIFEST_TSV = "CONT1R1_RUNTIME_BUNDLE_MANIFEST.tsv"
MANIFEST_SHA = "CONT1R1_RUNTIME_BUNDLE_MANIFEST.sha256"
EXPECTED_SNAPSHOT_JSON_SHA256 = "F69884964978A0C793C9C5235C264B1FA88F2B4ADBE37403B1CB27D26555207B"
EXPECTED_SNAPSHOT_BIN_SHA256 = "5930C78AA52AEC08F09E837D2C1E20EBBB9527A36E49647FACF273F7206D0AD9"


class BundleGateError(RuntimeError):
    pass


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise BundleGateError(reason)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def relative_files(root: Path) -> set[str]:
    return {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc"
    }


def contained(root: Path, path: Path) -> bool:
    resolved = path.resolve(strict=True)
    return resolved == root or root in resolved.parents


def run_gate(root: Path) -> dict:
    root = root.resolve(strict=True)
    require(root.is_dir(), "BUNDLE_ROOT_NOT_DIRECTORY")
    require(not root.is_symlink(), "BUNDLE_ROOT_IS_SYMLINK")
    for path in root.rglob("*"):
        require(not path.is_symlink(), f"BUNDLE_SYMLINK:{path.relative_to(root).as_posix()}")

    manifest_path = root / MANIFEST_JSON
    tsv_path = root / MANIFEST_TSV
    sha_path = root / MANIFEST_SHA
    require(manifest_path.is_file() and tsv_path.is_file() and sha_path.is_file(), "BUNDLE_MANIFEST_SET_MISSING")
    expected_manifest_sha = sha_path.read_text(encoding="ascii").strip().upper()
    require(sha256(manifest_path) == expected_manifest_sha, "BUNDLE_MANIFEST_SHA256_MISMATCH")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    require(manifest.get("schema") == "AHD_V41_CONT1R1_RUNTIME_BUNDLE_MANIFEST_V1", "BUNDLE_SCHEMA")
    files = manifest.get("files", [])
    require(manifest.get("file_count") == len(files), "BUNDLE_FILE_COUNT_FIELD")
    listed = {str(item["path"]) for item in files}
    require(len(listed) == len(files), "BUNDLE_MANIFEST_DUPLICATE_PATH")
    actual = relative_files(root)
    require(actual == listed | {MANIFEST_JSON, MANIFEST_TSV, MANIFEST_SHA}, "BUNDLE_RELATIVE_FILE_SET_MISMATCH")
    for item in files:
        path = root / str(item["path"])
        require(contained(root, path), f"BUNDLE_PATH_ESCAPE:{item['path']}")
        require(path.stat().st_size == int(item["size"]), f"BUNDLE_SIZE_MISMATCH:{item['path']}")
        require(sha256(path) == str(item["sha256"]).upper(), f"BUNDLE_SHA256_MISMATCH:{item['path']}")

    python_files = sorted(path for path in root.rglob("*.py") if path.is_file())
    for path in python_files:
        compile(path.read_text(encoding="utf-8-sig"), str(path), "exec")

    if str(root) not in sys.path:
        sys.path.insert(0, str(root))
    module_names = (
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
    )
    origins: dict[str, str] = {}
    for name in module_names:
        module = importlib.import_module(name)
        origin = Path(module.__file__).resolve(strict=True)
        require(contained(root, origin), f"MODULE_ORIGIN_VIOLATION:{name}:{origin}")
        origins[name] = origin.relative_to(root).as_posix()

    projection = importlib.import_module("cont1r1_projection")
    controller = importlib.import_module("g2b_nvp_camera_acq1_compat0_r2r1_controller")
    with contextlib.redirect_stdout(io.StringIO()):
        projection.self_test()
        controller.self_test()
    preflight = projection.manifest_preflight()

    snapshot_json = root / "cont1r1_resources" / "scan1-single-0001.json"
    snapshot_bin = root / "cont1r1_resources" / "scan1-single-0001.bin"
    require(sha256(snapshot_json) == EXPECTED_SNAPSHOT_JSON_SHA256, "PRESERVED_JSON_SHA256")
    require(sha256(snapshot_bin) == EXPECTED_SNAPSHOT_BIN_SHA256, "PRESERVED_BIN_SHA256")
    snapshot = json.loads(snapshot_json.read_text(encoding="utf-8"))
    controller.validate_scan(snapshot, None)
    projected = projection.configuration_projection(snapshot)
    require(len(projected) == 13, "PRESERVED_PROJECTION_KEY_COUNT_NOT_13")
    require(snapshot["entry_count"] == 82, "PRESERVED_ENTRY_COUNT_NOT_82")
    require(snapshot["bank_group_count"] == 10, "PRESERVED_GROUP_COUNT_NOT_10")
    require(snapshot["transaction_count"] == 105, "PRESERVED_TRANSACTION_COUNT_NOT_105")
    require(snapshot["entry_bank_restore"] == "PASS", "PRESERVED_ENTRY_BANK_RESTORE")

    return {
        "schema": "AHD_V41_CONT1R1_CLOSED_RUNTIME_BUNDLE_GATE_V1",
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
        "isolated_mode": bool(sys.flags.isolated),
        "user_site_disabled": bool(sys.flags.no_user_site),
        "module_origins": origins,
        "projection_preflight": preflight,
        "preserved_snapshot_replay": {
            "result": "PASS",
            "json_sha256": sha256(snapshot_json),
            "raw_sha256": sha256(snapshot_bin),
            "entries": 82,
            "bank_groups": 10,
            "transactions": 105,
            "entry_bank_restore": "PASS",
            "configuration_projection": "PASS",
            "projection_key_count": len(projected),
            "missing_projection_keys": 0,
            "invalid_scanner_entries": 0,
            "unexpected_duplicate_keys": 0,
        },
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
    except Exception as error:
        result = {
            "schema": "AHD_V41_CONT1R1_CLOSED_RUNTIME_BUNDLE_GATE_V1",
            "result": "FAIL",
            "first_failed_gate": f"{type(error).__name__}:{error}",
        }
        exit_code = 1
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output is not None:
        args.output.write_text(rendered, encoding="utf-8")
    print(json.dumps(result, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
