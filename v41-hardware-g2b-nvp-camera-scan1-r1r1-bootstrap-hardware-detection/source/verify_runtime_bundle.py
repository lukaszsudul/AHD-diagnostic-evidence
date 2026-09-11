#!/usr/bin/env python3
# SANITIZED PUBLICATION COPY; executed-source SHA-256: B3CF417B3C8F1A1E89FF6760086E8F4833DBF014F91AB73207D3A759B64C6333
"""Verify the accepted SCAN1-R1 closed bundle without hardware access."""

from __future__ import annotations

import hashlib
import importlib
import json
import os
import subprocess
import sys
from pathlib import Path


EXPECTED_MANIFEST_SHA256 = "E67B79AF5852A7D1AD021195AF0DA54216F647883393FC7D60A34EA5DC01CBDF"
MANIFEST_NAME = "G2B_NVP_CAMERA_SCAN1_R1_RUNTIME_BUNDLE_MANIFEST.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def contained(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=True).relative_to(root.resolve(strict=True))
        return True
    except ValueError:
        return False


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_runtime_bundle.py BUNDLE_ROOT")
    root = Path(sys.argv[1]).resolve(strict=True)
    manifest_path = root / MANIFEST_NAME
    if not manifest_path.is_file() or sha256(manifest_path) != EXPECTED_MANIFEST_SHA256:
        raise RuntimeError("RUNTIME_BUNDLE_MANIFEST_IDENTITY_MISMATCH")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    listed = manifest.get("files")
    if not isinstance(listed, list) or len(listed) != 20:
        raise RuntimeError("RUNTIME_BUNDLE_MANIFEST_FILE_COUNT_MISMATCH")
    expected_paths = {entry["path"] for entry in listed}
    if len(expected_paths) != len(listed):
        raise RuntimeError("RUNTIME_BUNDLE_MANIFEST_DUPLICATE_PATH")
    actual_paths = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file()
    }
    if actual_paths != expected_paths | {MANIFEST_NAME}:
        raise RuntimeError("RUNTIME_BUNDLE_RELATIVE_PATH_SET_MISMATCH")
    hash_rows = []
    for entry in listed:
        path = root / entry["path"]
        if not path.is_file() or not contained(path, root):
            raise RuntimeError(f"RUNTIME_BUNDLE_FILE_MISSING_OR_ESCAPED:{entry['path']}")
        size = path.stat().st_size
        digest = sha256(path)
        if size != entry["size"] or digest != entry["sha256"]:
            raise RuntimeError(f"RUNTIME_BUNDLE_FILE_IDENTITY_MISMATCH:{entry['path']}")
        hash_rows.append({"path": entry["path"], "size": size, "sha256": digest})
        if path.suffix == ".py":
            compile(path.read_bytes(), str(path), "exec", dont_inherit=True)

    sys.path.insert(0, str(root))
    modules = [
        "scan1", "scan1.controller", "scan1.decoder", "scan1.evidence",
        "scan1.manifest", "scan1.mmio", "scan1.state",
    ]
    origins = {}
    violations = 0
    for name in modules:
        module = importlib.import_module(name)
        origin = Path(module.__file__).resolve(strict=True)
        origins[name] = str(origin)
        if not contained(origin, root):
            violations += 1
    from scan1 import manifest as scan_manifest

    entries, prohibited, raw = scan_manifest.load_and_validate()
    if len(entries) != 82 or len(prohibited) != 14 or len(raw.get("bank_groups", [])) != 10:
        raise RuntimeError("RUNTIME_BUNDLE_CONTRACT_PARSE_FAILED")
    smoke = subprocess.run(
        [sys.executable, "-I", "-B", str(root / "scan1_launcher.py"), "--self-test"],
        cwd=root,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=30,
        check=False,
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if smoke.returncode != 0 or smoke.stdout.strip() != "PASS SCAN1_RUNTIME_SELF_TEST":
        raise RuntimeError("RUNTIME_BUNDLE_NON_HARDWARE_SMOKE_FAILED")
    help_smoke = subprocess.run(
        [sys.executable, "-I", "-B", str(root / "scan1_launcher.py"), "--help"],
        cwd=root,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=30,
        check=False,
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if help_smoke.returncode != 0 or "--self-test" not in help_smoke.stdout:
        raise RuntimeError("RUNTIME_BUNDLE_HELP_SMOKE_FAILED")
    if violations:
        raise RuntimeError("RUNTIME_BUNDLE_MODULE_ORIGIN_VIOLATION")
    result = {
        "result": "PASS",
        "bundle_root": str(root),
        "manifest_path": str(manifest_path),
        "manifest_sha256": sha256(manifest_path),
        "listed_file_count": len(listed),
        "total_file_count_including_manifest": len(actual_paths),
        "relative_path_set_matches": True,
        "all_sizes_match": True,
        "all_sha256_match": True,
        "python_compile_import_gate": "PASS",
        "entrypoint_non_hardware_gate": "PASS",
        "unresolved_local_imports": 0,
        "module_origin_violations": violations,
        "contract_manifest_parse_gate": "PASS",
        "entry_count": len(entries),
        "bank_group_count": len(raw["bank_groups"]),
        "hashes": hash_rows,
        "module_origins": origins,
    }
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
