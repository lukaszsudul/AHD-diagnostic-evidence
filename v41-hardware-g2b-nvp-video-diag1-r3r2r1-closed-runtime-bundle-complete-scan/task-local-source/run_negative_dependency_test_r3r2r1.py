#!/usr/bin/env python3
"""Prove that the bundle gate detects the known transitive abi_v1 omission."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import stat
import subprocess
import sys


RUNNER = (
    "import runpy,sys;sys.dont_write_bytecode=True;"
    "root=sys.argv[1];script=sys.argv[2];rest=sys.argv[3:];"
    "sys.path.insert(0,root);sys.argv=[script,*rest];"
    "runpy.run_path(script,run_name='__main__')"
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--positive-bundle", required=True, type=Path)
    parser.add_argument("--negative-bundle", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    positive = args.positive_bundle.resolve(strict=True)
    negative = args.negative_bundle.resolve()
    if negative.exists() and any(negative.iterdir()):
        raise RuntimeError("NEGATIVE_BUNDLE_NOT_FRESH_EMPTY")
    if not negative.exists():
        negative.mkdir(parents=True)
    for source in positive.rglob("*"):
        relative = source.relative_to(positive)
        destination = negative / relative
        if source.is_symlink():
            raise RuntimeError("POSITIVE_BUNDLE_SYMLINK")
        if source.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
        elif source.is_file():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
    missing = (negative / "abi_v1.py").resolve(strict=True)
    if missing.parent != negative.resolve():
        raise RuntimeError("NEGATIVE_TARGET_CONTAINMENT_FAILURE")
    missing.chmod(stat.S_IWRITE)
    missing.unlink()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    gate = negative / "isolated_bundle_gate_r3r2r1.py"
    command = [sys.executable, "-I", "-c", RUNNER, str(negative), str(gate),
               "--bundle", str(negative), "--manifest", str(args.manifest),
               "--output-dir", str(output / "gate-output")]
    completed = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, timeout=180,
                               check=False)
    detected = (completed.returncode != 0 and
                "abi_v1.py" in completed.stdout and
                not (negative / "abi_v1.py").exists())
    result = {
        "negative_test_missing_file": "abi_v1.py",
        "negative_test_result": "EXPECTED_FAILURE" if detected else
            "FAIL_NOT_DETECTED",
        "failure_class": "MISSING_LOCAL_DEPENDENCY" if detected else "UNKNOWN",
        "failure_detected_before_hardware": "YES" if detected else "NO",
        "gate_exit_code": completed.returncode,
        "abi_v1_restored": "NO",
        "result": "PASS" if detected else "FAIL",
    }
    (output / "negative-gate.console.log").write_text(
        completed.stdout, encoding="utf-8", newline="\n")
    (output / "negative-dependency-result.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8", newline="\n")
    print(json.dumps(result, sort_keys=True))
    return 0 if detected else 1


if __name__ == "__main__":
    raise SystemExit(main())
