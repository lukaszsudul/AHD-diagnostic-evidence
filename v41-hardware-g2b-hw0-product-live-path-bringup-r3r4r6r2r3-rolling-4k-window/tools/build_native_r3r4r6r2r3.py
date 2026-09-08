#!/usr/bin/env python3
"""Compile and identify the task-local rolling AIO helper without device access."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def run(command: list[str], timeout: float = 60.0) -> dict:
    completed = subprocess.run(command, text=True, capture_output=True,
                               timeout=timeout, check=False)
    return {
        "command": command,
        "return_code": completed.returncode,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--logs-dir", required=True, type=Path)
    args = parser.parse_args()

    args.logs_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    compiler = shutil.which("gcc") or shutil.which("cc")
    if compiler is None:
        report = {"result": "FAIL", "blocker": "DUT_COMPILER_UNAVAILABLE"}
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        return 1

    version = run([compiler, "--version"], timeout=10.0)
    command = [
        compiler, "-std=gnu11", "-O2", "-Wall", "-Wextra", "-Wformat=2",
        "-Werror=implicit-function-declaration", "-Werror=return-type",
        str(args.source), "-o", str(args.binary),
    ]
    compile_result = run(command)
    (args.logs_dir / "native-compile.stdout.txt").write_text(
        compile_result["stdout"], encoding="utf-8")
    (args.logs_dir / "native-compile.stderr.txt").write_text(
        compile_result["stderr"], encoding="utf-8")

    binary_exists = args.binary.is_file()
    inspections = {}
    if binary_exists:
        for name, command_line in (
            ("file", ["file", str(args.binary)]),
            ("readelf", ["readelf", "-l", str(args.binary)]),
            ("ldd", ["ldd", str(args.binary)]),
        ):
            if shutil.which(command_line[0]):
                inspections[name] = run(command_line, timeout=20.0)
            else:
                inspections[name] = {"available": False}

    forbidden_warning_fragments = (
        "implicit declaration", "return type defaults", "makes pointer from integer",
        "makes integer from pointer", "undefined reference", "unresolved symbol",
    )
    warning_text = (compile_result["stdout"] + compile_result["stderr"]).lower()
    unsafe_warning = next((item for item in forbidden_warning_fragments
                           if item in warning_text), None)
    result = "PASS" if (compile_result["return_code"] == 0 and binary_exists and
                        unsafe_warning is None) else "FAIL"
    report = {
        "schema": "R3R4R6R2R3_NATIVE_BUILD_V1",
        "result": result,
        "compiler": compiler,
        "compiler_version": version["stdout"].splitlines()[0] if version["stdout"] else "N/A",
        "compile_command": command,
        "compile_return_code": compile_result["return_code"],
        "compile_stdout_file": str(args.logs_dir / "native-compile.stdout.txt"),
        "compile_stderr_file": str(args.logs_dir / "native-compile.stderr.txt"),
        "unsafe_warning": unsafe_warning,
        "source": str(args.source),
        "source_sha256": sha256(args.source),
        "binary": str(args.binary),
        "binary_exists": binary_exists,
        "binary_size": args.binary.stat().st_size if binary_exists else None,
        "binary_sha256": sha256(args.binary) if binary_exists else None,
        "inspections": inspections,
        "device_access": False,
    }
    with args.report.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    print(json.dumps({"result": result, "compiler": compiler,
                      "binary_sha256": report["binary_sha256"]}, sort_keys=True))
    return 0 if result == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
