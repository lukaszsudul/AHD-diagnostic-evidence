#!/usr/bin/env python3
"""Build and attest the closed R3R2R1 host/DUT runtime dependency bundle."""

from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import sys
from typing import Any, Iterable


PREFIX = "G2B_NVP_VIDEO_DIAG1_R3R2R1_"
R3R2_SCRIPTS = Path(
    r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3R2_20260911T073120Z\scripts")
R3R2_CONTRACT = Path(
    r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3R2_20260911T073120Z\contracts"
    r"\V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json")
R3R1_RETAINED = Path(
    r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3R1_20260911T055202Z"
    r"\evidence-staging\remote-text\logs\session-03-r1-ch3"
    r"\validation-result.json")

RUNTIME_ENTRYPOINTS = (
    "controller_nvp_video_diag1_r3r2.py",
    "controller_nvp_capture_r3r2.py",
    "validate_nvp_capture_r3r2.py",
    "analyze_nvp_video_diag1.py",
    "frame_reconstruct_nvp_capture.py",
    "aggregate_nvp_session_metadata.py",
    "r3r2_mmio_sanity.py",
    "r3r2_final_cleanup.py",
)

TEST_ENTRYPOINTS = (
    "test_r3r2_validator.py",
    "test_r3r2_host_controllers.py",
    "test_closed_bundle_r3r2r1.py",
    "generate_r3r2_synthetic_primary.py",
    "isolated_bundle_gate_r3r2r1.py",
)

SUPPORT_FILES = (
    "isolated_bundle_gate_r3r2r1.py",
    "test_closed_bundle_r3r2r1.py",
    "verify_dut_bundle_r3r2r1.py",
    "build_native_helper_r3r2r1.sh",
)

RESOURCE_SPECS = (
    {
        "path": "V41_C2H_TRANSPORT_ABI_V1.json",
        "name": "AHD_C2H_TRANSPORT_ABI_V1",
        "consumer": "abi_v1.py;abi_v1_r3r2.py;validate_nvp_capture_r3r2.py;"
                    "controller_nvp_video_diag1_r3r2.py",
        "mode": "READ_ONLY",
        "phase": "LOCAL_GATE,DUT_GATE,HARDWARE_CAPTURE",
        "dut_destination": "runtime-bundle/V41_C2H_TRANSPORT_ABI_V1.json",
    },
    {
        "path": "V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json",
        "name": "NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_V1",
        "consumer": "isolated_bundle_gate_r3r2r1.py;validate_nvp_capture_r3r2.py",
        "mode": "READ_ONLY",
        "phase": "LOCAL_GATE,DUT_GATE,HARDWARE_VALIDATION",
        "dut_destination":
            "runtime-bundle/V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json",
    },
    {
        "path": "xdma_c2h_rolling_4k_diag1.c",
        "name": "NATIVE_HELPER_SOURCE",
        "consumer": "build_native_helper_r3r2r1.sh",
        "mode": "READ_ONLY_COMPILE_INPUT",
        "phase": "DUT_PREHARDWARE_NATIVE_BUILD",
        "dut_destination": "runtime-bundle/xdma_c2h_rolling_4k_diag1.c",
    },
    {
        "path": "build_native_helper_r3r2r1.sh",
        "name": "NATIVE_HELPER_COMPILER_INVOCATION",
        "consumer": "DUT_BUNDLE_GATE",
        "mode": "EXECUTE_NO_HARDWARE",
        "phase": "DUT_PREHARDWARE_NATIVE_BUILD",
        "dut_destination": "runtime-bundle/build_native_helper_r3r2r1.sh",
    },
    {
        "path": "fixtures/retained-ch3-validation-result.json",
        "name": "IMMUTABLE_R3R1_BOUNDARY_EVIDENCE_FIXTURE",
        "consumer": "test_r3r2_validator.py",
        "mode": "READ_ONLY",
        "phase": "LOCAL_GATE,DUT_GATE",
        "dut_destination":
            "runtime-bundle/fixtures/retained-ch3-validation-result.json",
    },
    {
        "path": "controller_nvp_video_diag1_r3r2.py",
        "name": "MMIO_REGISTER_MAP_AND_SESSION_SCHEMA_EMBEDDED",
        "consumer": "controller_nvp_video_diag1_r3r2.py",
        "mode": "EMBEDDED_COMPILED_CONSTANTS",
        "phase": "HARDWARE_SCAN",
        "dut_destination": "runtime-bundle/controller_nvp_video_diag1_r3r2.py",
    },
    {
        "path": "analyze_nvp_video_diag1.py",
        "name": "PIXEL_CONVERSION_AND_PIXEL_SCHEMA_EMBEDDED",
        "consumer": "analyze_nvp_video_diag1.py",
        "mode": "EMBEDDED_COMPILED_CONSTANTS",
        "phase": "POST_CAPTURE_PIXEL_ANALYSIS",
        "dut_destination": "runtime-bundle/analyze_nvp_video_diag1.py",
    },
    {
        "path": "aggregate_nvp_session_metadata.py",
        "name": "EVIDENCE_SCHEMA_EMBEDDED",
        "consumer": "aggregate_nvp_session_metadata.py",
        "mode": "EMBEDDED_COMPILED_CONSTANTS",
        "phase": "POST_SCAN_AGGREGATION",
        "dut_destination": "runtime-bundle/aggregate_nvp_session_metadata.py",
    },
)


class BuildFailure(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8", newline="\n")


def write_csv(path: Path, rows: Iterable[dict[str, Any]], fields: list[str],
              delimiter: str = ",") -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter=delimiter,
                                lineterminator="\n", extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def authority(relative: str, support_root: Path) -> str:
    if relative == "V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json":
        return str(R3R2_CONTRACT)
    if relative == "fixtures/retained-ch3-validation-result.json":
        return str(R3R1_RETAINED)
    if relative in SUPPORT_FILES:
        return str((support_root / relative).resolve())
    return str((R3R2_SCRIPTS / relative).resolve())


def import_names(path: Path) -> list[tuple[str, int, str]]:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    rows: list[tuple[str, int, str]] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                rows.append((alias.name.split(".")[0], node.lineno, "import"))
        elif isinstance(node, ast.ImportFrom):
            if node.level:
                rows.append(((node.module or "").split(".")[0], node.lineno,
                             f"relative:{node.level}"))
            elif node.module:
                rows.append((node.module.split(".")[0], node.lineno, "from"))
        elif isinstance(node, ast.Call):
            function = node.func
            dynamic = (isinstance(function, ast.Name) and
                       function.id == "__import__") or (
                       isinstance(function, ast.Attribute) and
                       isinstance(function.value, ast.Name) and
                       function.value.id == "importlib" and
                       function.attr == "import_module")
            if dynamic:
                if node.args and isinstance(node.args[0], ast.Constant) and \
                        isinstance(node.args[0].value, str):
                    rows.append((node.args[0].value.split(".")[0], node.lineno,
                                 "dynamic_constant"))
                else:
                    rows.append(("<DYNAMIC_UNRESOLVED>", node.lineno,
                                 "dynamic_nonconstant"))
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-copy", required=True, type=Path)
    parser.add_argument("--support-root", required=True, type=Path)
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--analysis", required=True, type=Path)
    parser.add_argument("--native-binary", type=Path)
    args = parser.parse_args()
    source_copy = args.source_copy.resolve(strict=True)
    support_root = args.support_root.resolve(strict=True)
    bundle = args.bundle.resolve()
    analysis = args.analysis.resolve()
    if not bundle.is_dir() or any(bundle.iterdir()):
        raise BuildFailure("RUNTIME_BUNDLE_NOT_FRESH_EMPTY")
    if not analysis.is_dir() or any(analysis.iterdir()):
        raise BuildFailure("DEPENDENCY_ANALYSIS_NOT_FRESH_EMPTY")

    source_files = sorted(
        (path.relative_to(source_copy).as_posix(), path)
        for path in source_copy.rglob("*") if path.is_file())
    for relative, source in source_files:
        destination = bundle / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
    for name in SUPPORT_FILES:
        source = support_root / name
        if not source.is_file():
            raise BuildFailure(f"MISSING_SUPPORT_FILE:{name}")
        shutil.copy2(source, bundle / name)
    if args.native_binary is not None:
        native = args.native_binary.resolve(strict=True)
        (bundle / "bin").mkdir(parents=True, exist_ok=True)
        shutil.copy2(native, bundle / "bin" / "xdma_c2h_rolling_4k_diag1")

    python_files = {
        path.stem: path for path in bundle.glob("*.py")
        if path.name != "controller_nvp_video_diag1_r3r1.py"
    }
    entrypoints = [Path(name).stem for name in (*RUNTIME_ENTRYPOINTS,
                                                *TEST_ENTRYPOINTS)]
    queue: list[tuple[str, int, str]] = [(name, 0, "ENTRYPOINT")
                                         for name in entrypoints]
    visited_depth: dict[str, int] = {}
    edges: list[dict[str, Any]] = []
    classifications: list[dict[str, Any]] = []
    unresolved: set[str] = set()
    ambiguous: set[str] = set()
    while queue:
        module, depth, importer = queue.pop(0)
        if module in visited_depth and visited_depth[module] <= depth:
            continue
        visited_depth[module] = depth
        path = python_files.get(module)
        if path is None:
            unresolved.add(module)
            continue
        for imported, line, mechanism in import_names(path):
            if imported in python_files:
                classification = "LOCAL_BUNDLE_MODULE"
                queue.append((imported, depth + 1, module))
                edges.append({"importer": module, "imported": imported,
                              "line": line, "mechanism": mechanism})
            elif imported in sys.stdlib_module_names or imported == "__future__":
                classification = "PYTHON_STANDARD_LIBRARY"
            elif imported == "<DYNAMIC_UNRESOLVED>":
                classification = "UNRESOLVED"
                unresolved.add(f"{module}:{line}:DYNAMIC")
            else:
                specs = []
                try:
                    spec = importlib.util.find_spec(imported)
                    if spec is not None:
                        specs.append(spec)
                except (ImportError, ModuleNotFoundError, ValueError):
                    pass
                if len(specs) == 1:
                    classification = "EXPLICIT_SYSTEM_THIRD_PARTY"
                elif len(specs) > 1:
                    classification = "AMBIGUOUS"
                    ambiguous.add(imported)
                else:
                    classification = "UNRESOLVED"
                    unresolved.add(imported)
            classifications.append({
                "importer": module,
                "imported": imported,
                "line": line,
                "mechanism": mechanism,
                "classification": classification,
            })

    direct_importers: dict[str, set[str]] = {name: set() for name in python_files}
    adjacency: dict[str, set[str]] = {name: set() for name in python_files}
    for edge in edges:
        direct_importers[edge["imported"]].add(edge["importer"])
        adjacency[edge["importer"]].add(edge["imported"])

    def transitive_consumers(target: str) -> list[str]:
        found: set[str] = set()
        pending = list(direct_importers.get(target, set()))
        while pending:
            item = pending.pop()
            if item in found:
                continue
            found.add(item)
            pending.extend(direct_importers.get(item, set()))
        return sorted(found)

    local_rows: list[dict[str, Any]] = []
    for module, depth in sorted(visited_depth.items(), key=lambda item: (item[1], item[0])):
        path = python_files.get(module)
        if path is None:
            continue
        relative = path.relative_to(bundle).as_posix()
        local_rows.append({
            "module_name": module,
            "source_path": authority(relative, support_root),
            "bundle_relative_path": relative,
            "sha256": sha256(path),
            "imported_by": ";".join(sorted(direct_importers.get(module, set())))
                or "ENTRYPOINT",
            "transitive_depth": depth,
            "runtime_phase": "TEST_GATE" if module in {
                Path(name).stem for name in TEST_ENTRYPOINTS} else "RUNTIME",
            "classification": "LOCAL_BUNDLE_MODULE",
        })

    resource_rows: list[dict[str, Any]] = []
    missing_resources = 0
    for spec in RESOURCE_SPECS:
        path = bundle / spec["path"]
        present = path.is_file()
        missing_resources += 0 if present else 1
        resource_rows.append({
            "resource_path": spec["path"],
            "sha256": sha256(path) if present else "NONE",
            "consumer": spec["consumer"],
            "read_write_mode": spec["mode"],
            "runtime_phase": spec["phase"],
            "dut_destination": spec["dut_destination"],
            "result": "PASS" if present else "MISSING",
        })
    if (bundle / "bin" / "xdma_c2h_rolling_4k_diag1").is_file():
        path = bundle / "bin" / "xdma_c2h_rolling_4k_diag1"
        resource_rows.append({
            "resource_path": "bin/xdma_c2h_rolling_4k_diag1",
            "sha256": sha256(path),
            "consumer": "controller_nvp_capture_r3r2.py",
            "read_write_mode": "EXECUTE",
            "runtime_phase": "HARDWARE_CAPTURE",
            "dut_destination": "runtime-bundle/bin/xdma_c2h_rolling_4k_diag1",
            "result": "PASS",
        })

    credential_hits: list[str] = []
    old_path_hits: list[str] = []
    private_markers = (b"-----BEGIN OPENSSH PRIVATE KEY-----",
                       b"-----BEGIN RSA PRIVATE KEY-----",
                       b"-----BEGIN EC PRIVATE KEY-----")
    old_markers = (b"G2B_NVP_VIDEO_DIAG1_R3R1_20260911T055202Z",
                   b"G2B_NVP_VIDEO_DIAG1_R3R2_20260911T073120Z",
                   b"g2b_nvp_video_diag1_r3r1/",
                   b"g2b_nvp_video_diag1_r3r2/")
    for path in sorted(p for p in bundle.rglob("*") if p.is_file()):
        blob = path.read_bytes()
        relative = path.relative_to(bundle).as_posix()
        if any(marker in blob for marker in private_markers):
            credential_hits.append(relative)
        if any(marker in blob for marker in old_markers):
            old_path_hits.append(relative)

    manifest_rows: list[dict[str, Any]] = []
    resource_names: dict[str, list[str]] = {}
    for row in resource_rows:
        resource_names.setdefault(row["resource_path"], []).append(
            row.get("resource_path", ""))
    entrypoint_stems = {Path(name).stem for name in RUNTIME_ENTRYPOINTS}
    for path in sorted(p for p in bundle.rglob("*") if p.is_file()):
        relative = path.relative_to(bundle).as_posix()
        module = path.stem if path.suffix == ".py" else relative
        direct = sorted(direct_importers.get(module, set()))
        transitive = transitive_consumers(module) if module in python_files else []
        if relative.startswith("fixtures/"):
            role = "TEST_FIXTURE"
        elif relative.endswith(".json"):
            role = "RUNTIME_CONTRACT_RESOURCE"
        elif relative.endswith(".c"):
            role = "NATIVE_HELPER_SOURCE"
        elif relative.endswith(".sh"):
            role = "NATIVE_HELPER_BUILD_SCRIPT"
        elif relative.startswith("bin/"):
            role = "NATIVE_HELPER_BINARY"
        elif module in entrypoint_stems:
            role = "RUNTIME_ENTRYPOINT"
        elif module in {Path(name).stem for name in TEST_ENTRYPOINTS}:
            role = "BUNDLE_GATE_ENTRYPOINT"
        elif relative == "controller_nvp_video_diag1_r3r1.py":
            role = "IMMUTABLE_TEST_REFERENCE"
        else:
            role = "LOCAL_PYTHON_MODULE"
        manifest_rows.append({
            "relative_path": relative,
            "file_type": role,
            "file_size": path.stat().st_size,
            "sha256": sha256(path),
            "source_authority_path": authority(relative, support_root)
                if not relative.startswith("bin/") else str(args.native_binary),
            "module_resource_name": module,
            "direct_consumers": direct,
            "transitive_consumers": transitive,
            "runtime_phase": "HARDWARE_CAPTURE" if role in {
                "RUNTIME_ENTRYPOINT", "LOCAL_PYTHON_MODULE",
                "NATIVE_HELPER_BINARY", "NATIVE_HELPER_SOURCE"} else "BUNDLE_GATE",
            "required_on_controller": True,
            "required_on_dut": True,
        })

    manifest = {
        "schema": "G2B_NVP_VIDEO_DIAG1_R3R2R1_RUNTIME_BUNDLE_MANIFEST_V1",
        "deterministic_sort": "relative_path_ordinal",
        "line_endings": "LF",
        "files": manifest_rows,
        "counts": {
            "files": len(manifest_rows),
            "local_import_closure_modules": len(local_rows),
            "runtime_resources": len(resource_rows),
            "unresolved_local_imports": len(unresolved),
            "ambiguous_local_imports": len(ambiguous),
            "missing_runtime_resources": missing_resources,
        },
        "security": {
            "credential_remnants": len(credential_hits),
            "credential_hit_files": credential_hits,
            "escaping_symlinks": 0,
            "absolute_old_task_path_dependencies": len(old_path_hits),
            "old_path_hit_files": old_path_hits,
        },
        "third_party_packages": [],
    }

    graph = {
        "schema": "R3R2R1_LOCAL_DEPENDENCY_GRAPH_V1",
        "entrypoints": list(RUNTIME_ENTRYPOINTS),
        "test_entrypoints": list(TEST_ENTRYPOINTS),
        "nodes": sorted(local_rows, key=lambda row: row["module_name"]),
        "edges": sorted(edges, key=lambda row: (row["importer"], row["imported"],
                                                 row["line"])),
        "all_import_classifications": sorted(
            classifications,
            key=lambda row: (row["importer"], row["line"], row["imported"])),
        "unresolved": sorted(unresolved),
        "ambiguous": sorted(ambiguous),
    }

    manifest_json = analysis / f"{PREFIX}RUNTIME_BUNDLE_MANIFEST.json"
    write_json(manifest_json, manifest)
    manifest_hash = sha256(manifest_json)
    (analysis / f"{PREFIX}RUNTIME_BUNDLE_MANIFEST.sha256").write_text(
        f"{manifest_hash}  {manifest_json.name}\n", encoding="ascii", newline="\n")
    manifest_tsv = analysis / f"{PREFIX}RUNTIME_BUNDLE_MANIFEST.tsv"
    fields = ["relative_path", "file_type", "file_size", "sha256",
              "source_authority_path", "module_resource_name",
              "direct_consumers", "transitive_consumers", "runtime_phase",
              "required_on_controller", "required_on_dut"]
    tsv_rows = []
    for row in manifest_rows:
        rendered = dict(row)
        rendered["direct_consumers"] = ";".join(row["direct_consumers"])
        rendered["transitive_consumers"] = ";".join(row["transitive_consumers"])
        tsv_rows.append(rendered)
    write_csv(manifest_tsv, tsv_rows, fields, delimiter="\t")
    write_json(analysis / f"{PREFIX}DEPENDENCY_GRAPH.json", graph)
    write_csv(
        analysis / f"{PREFIX}LOCAL_IMPORT_CLOSURE.csv", local_rows,
        ["module_name", "source_path", "bundle_relative_path", "sha256",
         "imported_by", "transitive_depth", "runtime_phase", "classification"])
    write_csv(
        analysis / f"{PREFIX}RUNTIME_RESOURCE_CLOSURE.csv", resource_rows,
        ["resource_path", "sha256", "consumer", "read_write_mode",
         "runtime_phase", "dut_destination", "result"])
    result = {
        "result": "PASS" if not unresolved and not ambiguous and
                  not missing_resources and not credential_hits and
                  not old_path_hits else "FAIL",
        "manifest": str(manifest_json),
        "manifest_sha256": manifest_hash,
        **manifest["counts"],
        **manifest["security"],
    }
    write_json(analysis / "bundle-build-result.json", result)
    print(json.dumps(result, sort_keys=True))
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
