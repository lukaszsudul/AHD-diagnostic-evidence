#!/usr/bin/env python3
"""Verify the deployed DUT bundle against the controller-authored manifest."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import sys


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--expected-manifest-sha256", required=True)
    parser.add_argument("--output-csv", required=True, type=Path)
    parser.add_argument("--output-json", required=True, type=Path)
    args = parser.parse_args()
    bundle = args.bundle.resolve(strict=True)
    manifest_path = args.manifest.resolve(strict=True)
    manifest_hash = sha256(manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    expected = {row["relative_path"]: row for row in manifest["files"]}
    actual: dict[str, Path] = {}
    symlinks: list[str] = []
    for path in bundle.rglob("*"):
        relative = path.relative_to(bundle).as_posix()
        if path.is_symlink():
            symlinks.append(relative)
        elif path.is_file():
            actual[relative] = path
    rows = []
    for relative in sorted(set(expected) | set(actual)):
        row = expected.get(relative)
        path = actual.get(relative)
        actual_size = path.stat().st_size if path else None
        actual_hash = sha256(path) if path else "NONE"
        status = "PASS" if row and path and \
            actual_size == row["file_size"] and actual_hash == row["sha256"] \
            else "FAIL"
        rows.append({
            "relative_path": relative,
            "expected_size": row["file_size"] if row else "NONE",
            "actual_size": actual_size if actual_size is not None else "NONE",
            "expected_sha256": row["sha256"] if row else "NONE",
            "actual_sha256": actual_hash,
            "regular_file": "YES" if path and path.is_file() and
                not path.is_symlink() else "NO",
            "result": status,
        })
    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.output_csv.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]),
                                lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    result = {
        "gate": "R3R2R1_DUT_FILE_HASH_VERIFICATION",
        "python": sys.version,
        "manifest_sha256": manifest_hash,
        "expected_manifest_sha256": args.expected_manifest_sha256.upper(),
        "expected_file_count": len(expected),
        "actual_file_count": len(actual),
        "missing_files": sorted(set(expected) - set(actual)),
        "extra_files": sorted(set(actual) - set(expected)),
        "hash_or_size_failures": sum(row["result"] != "PASS" for row in rows),
        "symlinks": symlinks,
        "abi_v1_present": (bundle / "abi_v1.py").is_file(),
        "abi_v1_sha256": sha256(bundle / "abi_v1.py")
            if (bundle / "abi_v1.py").is_file() else "NONE",
    }
    result["result"] = "PASS" if (
        manifest_hash == args.expected_manifest_sha256.upper() and
        len(expected) == len(actual) and not result["missing_files"] and
        not result["extra_files"] and not result["hash_or_size_failures"] and
        not symlinks and result["abi_v1_present"]
    ) else "FAIL"
    args.output_json.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                                encoding="utf-8", newline="\n")
    print(json.dumps(result, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
