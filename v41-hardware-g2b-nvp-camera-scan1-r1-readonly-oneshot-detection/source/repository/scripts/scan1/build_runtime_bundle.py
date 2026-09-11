#!/usr/bin/env python3
"""Build and locally qualify the closed SCAN1 runtime bundle."""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PACKAGE_SOURCE = ROOT / "host" / "scan1"
LAUNCHER_SOURCE = ROOT / "host" / "scan1_launcher.py"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def local_import_gate() -> dict[str, int]:
    modules = {path.stem: path for path in PACKAGE_SOURCE.glob("*.py")}
    unresolved: list[str] = []
    ambiguous: list[str] = []
    for path in modules.values():
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom) and node.level:
                name = (node.module or "").split(".", 1)[0]
                if name and name not in modules:
                    unresolved.append(f"{path.name}:{name}")
    names = [path.name.casefold() for path in modules.values()]
    if len(names) != len(set(names)):
        ambiguous.append("case-insensitive module collision")
    if unresolved or ambiguous:
        raise RuntimeError(f"LOCAL_IMPORT_GATE_FAILED:{unresolved}:{ambiguous}")
    return {"unresolved_local_imports": 0, "ambiguous_local_imports": 0}


def file_rows(root: Path) -> list[dict[str, object]]:
    rows = []
    for path in sorted(root.rglob("*")):
        if path.is_file() and path.name != "G2B_NVP_CAMERA_SCAN1_R1_RUNTIME_BUNDLE_MANIFEST.json":
            rows.append({
                "path": path.relative_to(root).as_posix(),
                "size": path.stat().st_size,
                "sha256": sha256(path),
            })
    return rows


def isolated_self_test(root: Path) -> subprocess.CompletedProcess[str]:
    root_literal = repr(str(root))
    code = (
        "import pathlib,sys;root=pathlib.Path(" + root_literal + ").resolve();"
        "sys.path.insert(0,str(root));"
        "import scan1,scan1.controller,scan1.decoder,scan1.evidence,scan1.manifest,scan1.mmio,scan1.state;"
        "mods=[scan1,scan1.controller,scan1.decoder,scan1.evidence,scan1.manifest,scan1.mmio,scan1.state];"
        "assert all(root==pathlib.Path(m.__file__).resolve() or root in pathlib.Path(m.__file__).resolve().parents for m in mods);"
        "scan1.controller.self_test()"
    )
    return subprocess.run([sys.executable, "-I", "-S", "-c", code], text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-tree", required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise SystemExit(f"runtime bundle output is not empty: {output}")
    if not PACKAGE_SOURCE.is_dir() or not LAUNCHER_SOURCE.is_file():
        raise SystemExit("runtime source closure missing")

    import_result = local_import_gate()
    shutil.copytree(PACKAGE_SOURCE, output / "scan1", ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    shutil.copy2(LAUNCHER_SOURCE, output / "scan1_launcher.py")
    rows = file_rows(output)
    missing_resources = 0
    required_resources = {
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.csv",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.json",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_MMIO_MAP.csv",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_PROHIBITED_READS.csv",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_REGISTER_AUTHORITY_MATRIX.csv",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_SCAN_SCHEMA.json",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_HOST_DETECTION_STATE_MACHINE.json",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_FORMAT_DETECTION_DECISION_TREE.json",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_FORMAT_DEBOUNCE_STATE_MACHINE.json",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_STATUS_ENCODING.md",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_MMIO_CONTRACT.md",
        "scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_SCIENTIFIC_OUTCOME_RULES.md",
    }
    actual = {row["path"] for row in rows}
    missing_resources = len(required_resources - actual)
    if missing_resources:
        raise RuntimeError(f"MISSING_RUNTIME_RESOURCES:{sorted(required_resources - actual)}")

    positive = isolated_self_test(output)
    if positive.returncode or "PASS SCAN1_RUNTIME_SELF_TEST" not in positive.stdout:
        raise RuntimeError(f"ISOLATED_LOCAL_IMPORT_GATE_FAILED:{positive.stdout}")

    with tempfile.TemporaryDirectory(prefix="scan1-negative-") as temp:
        negative_root = Path(temp) / "bundle"
        shutil.copytree(output, negative_root)
        (negative_root / "scan1" / "resources" / "G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.json").unlink()
        negative = isolated_self_test(negative_root)
        if negative.returncode == 0:
            raise RuntimeError("NEGATIVE_MISSING_DEPENDENCY_TEST_DID_NOT_FAIL")

    bundle_manifest = {
        "task": "AHD_V41_G2B_NVP_CAMERA_SCAN1_R1",
        "source_commit": args.source_commit,
        "source_tree": args.source_tree,
        "python": sys.version,
        "unresolved_local_imports": import_result["unresolved_local_imports"],
        "ambiguous_local_imports": import_result["ambiguous_local_imports"],
        "missing_runtime_resources": missing_resources,
        "local_isolated_import_gate": "PASS",
        "negative_missing_dependency_gate": "PASS",
        "files": rows,
    }
    manifest_path = output / "G2B_NVP_CAMERA_SCAN1_R1_RUNTIME_BUNDLE_MANIFEST.json"
    manifest_path.write_text(json.dumps(bundle_manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({
        "result": "PASS", "files": len(rows), "manifest": str(manifest_path),
        "manifest_sha256": sha256(manifest_path), "local_isolated_import_gate": "PASS",
        "negative_missing_dependency_gate": "PASS",
    }, sort_keys=True))


if __name__ == "__main__":
    main()
