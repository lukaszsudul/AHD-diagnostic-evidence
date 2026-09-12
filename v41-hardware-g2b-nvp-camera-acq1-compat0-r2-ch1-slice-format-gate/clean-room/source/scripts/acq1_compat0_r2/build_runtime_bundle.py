#!/usr/bin/env python3
"""Build and locally qualify the closed SCAN1 plus ACQ1-R2 runtime bundle."""

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
PACKAGES = {
    "scan1": ROOT / "host" / "scan1",
    "acq1_compat0_r2": ROOT / "host" / "acq1_compat0_r2",
}
LAUNCHERS = (
    ROOT / "host" / "scan1_launcher.py",
    ROOT / "host" / "acq1_compat0_r2_launcher.py",
    ROOT / "host" / "acq1_compat0_r2_campaign_launcher.py",
)
MANIFEST_NAME = "G2B_NVP_ACQ1_COMPAT0_R2_RUNTIME_BUNDLE_MANIFEST.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def local_import_gate() -> dict[str, int]:
    unresolved: list[str] = []
    ambiguous: list[str] = []
    for package_name, package_root in PACKAGES.items():
        modules = {path.stem for path in package_root.glob("*.py")}
        names = [path.name.casefold() for path in package_root.glob("*.py")]
        if len(names) != len(set(names)):
            ambiguous.append(f"{package_name}:case-insensitive module collision")
        for path in package_root.glob("*.py"):
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
            for node in ast.walk(tree):
                if isinstance(node, ast.ImportFrom) and node.level:
                    local_name = (node.module or "").split(".", 1)[0]
                    if local_name and local_name not in modules:
                        unresolved.append(f"{package_name}/{path.name}:{local_name}")
                elif isinstance(node, ast.ImportFrom) and node.module:
                    absolute = node.module.split(".", 1)[0]
                    if absolute in PACKAGES and not PACKAGES[absolute].is_dir():
                        unresolved.append(f"{package_name}/{path.name}:{absolute}")
    if unresolved or ambiguous:
        raise RuntimeError(f"LOCAL_IMPORT_GATE_FAILED:{unresolved}:{ambiguous}")
    return {"unresolved_local_imports": 0, "ambiguous_local_imports": 0}


def file_rows(root: Path) -> list[dict[str, object]]:
    return [{"path": path.relative_to(root).as_posix(), "size": path.stat().st_size,
             "sha256": sha256(path)}
            for path in sorted(root.rglob("*"))
            if path.is_file() and path.name != MANIFEST_NAME]


def isolated_gate(root: Path) -> subprocess.CompletedProcess[str]:
    code = (
        "import pathlib,sys;root=pathlib.Path(" + repr(str(root)) + ").resolve();"
        "sys.path.insert(0,str(root));"
        "import scan1,scan1.controller,scan1.decoder,scan1.evidence,scan1.manifest,scan1.mmio,scan1.state;"
        "import acq1_compat0_r2,acq1_compat0_r2.campaign,acq1_compat0_r2.contract,"
        "acq1_compat0_r2.controller,acq1_compat0_r2.evidence,acq1_compat0_r2.format_decision,"
        "acq1_compat0_r2.mmio,acq1_compat0_r2.policy;"
        "mods=[m for n,m in list(sys.modules.items()) if n=='scan1' or n.startswith('scan1.') or "
        "n=='acq1_compat0_r2' or n.startswith('acq1_compat0_r2.')];"
        "assert all(root==pathlib.Path(m.__file__).resolve() or root in pathlib.Path(m.__file__).resolve().parents for m in mods);"
        "scan1.controller.self_test();acq1_compat0_r2.controller.self_test()"
    )
    return subprocess.run([sys.executable, "-I", "-S", "-c", code], text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)


def launcher_gate(root: Path, launcher: str, arguments: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, "-I", "-S", str(root / launcher), *arguments], text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False, cwd=root)


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
    if any(not path.is_dir() for path in PACKAGES.values()) or any(not path.is_file() for path in LAUNCHERS):
        raise SystemExit("runtime source closure missing")

    import_result = local_import_gate()
    for name, source in PACKAGES.items():
        shutil.copytree(source, output / name, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    for launcher in LAUNCHERS:
        shutil.copy2(launcher, output / launcher.name)

    required = {
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
        "acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json",
        "acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.md",
        "acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json",
        "acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.md",
        "acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_REGISTER_SAFETY_AUDIT.md",
        "acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json",
    }
    rows = file_rows(output)
    actual = {str(row["path"]) for row in rows}
    missing = sorted(required - actual)
    if missing:
        raise RuntimeError(f"MISSING_RUNTIME_RESOURCES:{missing}")

    isolated = isolated_gate(output)
    if (isolated.returncode or "PASS SCAN1_RUNTIME_SELF_TEST" not in isolated.stdout or
            "PASS ACQ1_COMPAT0_R2_RUNTIME_SELF_TEST" not in isolated.stdout):
        raise RuntimeError(f"ISOLATED_IMPORT_OR_CONTRACT_GATE_FAILED:{isolated.stdout}")
    entrypoint = launcher_gate(output, "acq1_compat0_r2_launcher.py", ["--self-test"])
    campaign_help = launcher_gate(output, "acq1_compat0_r2_campaign_launcher.py", ["--help"])
    if (entrypoint.returncode or "PASS ACQ1_COMPAT0_R2_RUNTIME_SELF_TEST" not in entrypoint.stdout or
            campaign_help.returncode or "--output-root" not in campaign_help.stdout):
        raise RuntimeError(f"ENTRYPOINT_GATE_FAILED:{entrypoint.stdout}:{campaign_help.stdout}")

    with tempfile.TemporaryDirectory(prefix="acq1-r2-negative-") as temporary:
        negative_root = Path(temporary) / "bundle"
        shutil.copytree(output, negative_root)
        (negative_root / "acq1_compat0_r2" / "resources" /
         "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json").unlink()
        negative = isolated_gate(negative_root)
        if negative.returncode == 0:
            raise RuntimeError("NEGATIVE_MISSING_RESOURCE_GATE_DID_NOT_FAIL")

    manifest = {
        "task": "AHD_V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2",
        "source_commit": args.source_commit,
        "source_tree": args.source_tree,
        "python": sys.version,
        "unresolved_local_imports": import_result["unresolved_local_imports"],
        "ambiguous_local_imports": import_result["ambiguous_local_imports"],
        "missing_runtime_resources": 0,
        "module_origin_violations": 0,
        "local_isolated_import_gate": "PASS",
        "entrypoint_gate": "PASS",
        "contract_parse_gate": "PASS",
        "negative_missing_dependency_gate": "PASS",
        "files": rows,
    }
    manifest_path = output / MANIFEST_NAME
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n",
                             encoding="utf-8", newline="\n")
    print(json.dumps({
        "result": "PASS", "files": len(rows), "manifest": str(manifest_path),
        "manifest_sha256": sha256(manifest_path), "unresolved_local_imports": 0,
        "ambiguous_local_imports": 0, "missing_runtime_resources": 0,
        "module_origin_violations": 0, "local_isolated_import_gate": "PASS",
        "entrypoint_gate": "PASS", "contract_parse_gate": "PASS",
    }, sort_keys=True))


if __name__ == "__main__":
    main()
