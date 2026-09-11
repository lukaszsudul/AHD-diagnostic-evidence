#!/usr/bin/env python3
"""Origin-checked, hardware-free gate for the R3R2R1 runtime bundle."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any


ENTRYPOINTS = (
    "controller_nvp_video_diag1_r3r2.py",
    "controller_nvp_capture_r3r2.py",
    "validate_nvp_capture_r3r2.py",
    "analyze_nvp_video_diag1.py",
    "frame_reconstruct_nvp_capture.py",
    "aggregate_nvp_session_metadata.py",
    "r3r2_mmio_sanity.py",
    "r3r2_final_cleanup.py",
    "generate_r3r2_synthetic_primary.py",
    "test_r3r2_validator.py",
    "test_r3r2_host_controllers.py",
    "test_closed_bundle_r3r2r1.py",
)

REQUIRED_LOCAL_MODULES = (
    "abi_v1",
    "abi_v1_r3r2",
    "availability_classifier_r3r2",
    "controller_nvp_capture_r3r2",
    "controller_nvp_video_diag1_r3r2",
    "frame_reconstruct_nvp_capture",
    "validate_nvp_capture_r3r2",
    "vbi_tail_contract_r3r2",
    "analyze_nvp_video_diag1",
    "aggregate_nvp_session_metadata",
)


def load_expected_modules() -> dict[str, Any]:
    import abi_v1
    import abi_v1_r3r2
    import aggregate_nvp_session_metadata
    import analyze_nvp_video_diag1
    import availability_classifier_r3r2
    import controller_nvp_capture_r3r2
    import controller_nvp_video_diag1_r3r2
    import frame_reconstruct_nvp_capture
    import validate_nvp_capture_r3r2
    import vbi_tail_contract_r3r2

    return {
        "abi_v1": abi_v1,
        "abi_v1_r3r2": abi_v1_r3r2,
        "aggregate_nvp_session_metadata": aggregate_nvp_session_metadata,
        "analyze_nvp_video_diag1": analyze_nvp_video_diag1,
        "availability_classifier_r3r2": availability_classifier_r3r2,
        "controller_nvp_capture_r3r2": controller_nvp_capture_r3r2,
        "controller_nvp_video_diag1_r3r2": controller_nvp_video_diag1_r3r2,
        "frame_reconstruct_nvp_capture": frame_reconstruct_nvp_capture,
        "validate_nvp_capture_r3r2": validate_nvp_capture_r3r2,
        "vbi_tail_contract_r3r2": vbi_tail_contract_r3r2,
    }

RUNNER = (
    "import runpy,sys;"
    "sys.dont_write_bytecode=True;"
    "root=sys.argv[1];script=sys.argv[2];rest=sys.argv[3:];"
    "sys.path.insert(0,root);sys.argv=[script,*rest];"
    "runpy.run_path(script,run_name='__main__')"
)


class GateFailure(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def contained(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=True).relative_to(root.resolve(strict=True))
        return True
    except (OSError, ValueError):
        return False


def run_isolated(root: Path, script: Path, arguments: list[str],
                 log: Path, timeout: int = 180) -> subprocess.CompletedProcess[str]:
    command = [sys.executable, "-I", "-c", RUNNER, str(root), str(script),
               *arguments]
    completed = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, timeout=timeout,
                               check=False, env={"PATH": os.environ.get("PATH", "")})
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(completed.stdout, encoding="utf-8", newline="\n")
    if completed.returncode != 0:
        raise GateFailure(
            f"ISOLATED_EXECUTION_FAILED:{script.name}:RC={completed.returncode}")
    return completed


def verify_manifest(bundle: Path, manifest_path: Path) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    rows = {row["relative_path"]: row for row in manifest["files"]}
    actual: set[str] = set()
    for path in bundle.rglob("*"):
        if path.is_symlink():
            raise GateFailure(f"SYMLINK_NOT_ALLOWED:{path}")
        if path.is_file():
            actual.add(path.relative_to(bundle).as_posix())
    expected = set(rows)
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing:
        raise GateFailure("MISSING_BUNDLE_FILE:" + ",".join(missing))
    if extra:
        raise GateFailure("UNMANIFESTED_BUNDLE_FILE:" + ",".join(extra))
    for relative, row in rows.items():
        path = bundle / relative
        if not path.is_file() or path.is_symlink():
            raise GateFailure(f"NONREGULAR_BUNDLE_FILE:{relative}")
        if path.stat().st_size != row["file_size"]:
            raise GateFailure(f"SIZE_MISMATCH:{relative}")
        if sha256(path) != row["sha256"]:
            raise GateFailure(f"HASH_MISMATCH:{relative}")
    return manifest, rows


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    fields = list(rows[0]) if rows else ["module", "result"]
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    bundle = args.bundle.resolve(strict=True)
    output = args.output_dir.resolve()
    if output.exists() and any(output.iterdir()):
        raise GateFailure("OUTPUT_DIRECTORY_NOT_EMPTY")
    output.mkdir(parents=True, exist_ok=True)
    sys.dont_write_bytecode = True
    if str(bundle) not in sys.path:
        sys.path.insert(0, str(bundle))

    result: dict[str, Any] = {
        "gate": "R3R2R1_CLOSED_RUNTIME_BUNDLE",
        "bundle": str(bundle),
        "manifest": str(args.manifest.resolve()),
        "result": "FAIL",
    }
    try:
        manifest, manifest_rows = verify_manifest(bundle, args.manifest)
        result["manifest_file_count"] = len(manifest_rows)

        provenance: list[dict[str, Any]] = []
        loaded_modules = load_expected_modules()
        for module_name in REQUIRED_LOCAL_MODULES:
            module = loaded_modules[module_name]
            resolved = Path(module.__file__).resolve(strict=True)
            relative = resolved.relative_to(bundle).as_posix() \
                if contained(resolved, bundle) else "OUTSIDE_BUNDLE"
            expected = manifest_rows.get(relative)
            origin_ok = (relative != "OUTSIDE_BUNDLE" and expected is not None and
                         sha256(resolved) == expected["sha256"])
            provenance.append({
                "module": module_name,
                "resolved_path": str(resolved),
                "bundle_relative_path": relative,
                "sha256": sha256(resolved),
                "manifest_sha256": expected["sha256"] if expected else "NONE",
                "contained_in_bundle": "YES" if contained(resolved, bundle) else "NO",
                "result": "PASS" if origin_ok else "FAIL",
            })
            if not origin_ok:
                raise GateFailure(f"LOCAL_MODULE_ORIGIN_VIOLATION:{module_name}")
        write_csv(output / "local-module-provenance.csv", provenance)
        result["local_module_origin_violations"] = 0

        pycache = output / "pycache"
        compile_command = [sys.executable, "-I", "-X",
                           f"pycache_prefix={pycache}", "-m", "compileall",
                           "-q", "-f", str(bundle)]
        compiled = subprocess.run(compile_command, text=True,
                                  stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, timeout=180,
                                  check=False,
                                  env={"PATH": os.environ.get("PATH", "")})
        (output / "compileall.log").write_text(
            compiled.stdout, encoding="utf-8", newline="\n")
        if compiled.returncode != 0:
            raise GateFailure(f"COMPILEALL_FAILED:RC={compiled.returncode}")
        result["compileall"] = "PASS"

        for name in ENTRYPOINTS:
            run_isolated(bundle, bundle / name, ["--help"],
                         output / "entrypoint-help" / f"{name}.log", 60)
        result["entrypoint_help"] = f"{len(ENTRYPOINTS)}/{len(ENTRYPOINTS)}"

        for resource in (
            "V41_C2H_TRANSPORT_ABI_V1.json",
            "V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json",
            "fixtures/retained-ch3-validation-result.json",
        ):
            json.loads((bundle / resource).read_text(encoding="utf-8"))
        result["contract_resource_parse"] = "PASS"

        run_isolated(
            bundle, bundle / "test_r3r2_validator.py",
            ["--retained-ch3-result",
             str(bundle / "fixtures/retained-ch3-validation-result.json"),
             "--output-dir", str(output / "validator-regression")],
            output / "validator-regression.console.log")
        validator = json.loads((output / "validator-regression" /
                                "validator-regression.json").read_text(
                                    encoding="utf-8"))
        if validator.get("passed") != 16 or validator.get("result") != "PASS":
            raise GateFailure("VALIDATOR_REGRESSION_NOT_16_OF_16")
        result["validator_regression"] = "16/16"

        run_isolated(
            bundle, bundle / "test_r3r2_host_controllers.py",
            ["--output-dir", str(output / "host-controller-regression")],
            output / "host-controller-regression.console.log")
        host = json.loads((output / "host-controller-regression" /
                           "host-controller-gate.json").read_text(encoding="utf-8"))
        if host.get("passed") != 10 or host.get("result") != "PASS":
            raise GateFailure("HOST_CONTROLLER_REGRESSION_NOT_10_OF_10")
        result["host_controller_regression"] = "10/10"

        run_isolated(
            bundle, bundle / "test_closed_bundle_r3r2r1.py",
            ["--output", str(output / "mocked-execution.json")],
            output / "mocked-execution.console.log")
        mocked = json.loads((output / "mocked-execution.json").read_text(
            encoding="utf-8"))
        if mocked.get("result") != "PASS":
            raise GateFailure("MOCKED_EXECUTION_FAILED")
        result["mocked_16_session_orchestration"] = "PASS"
        result["mocked_no_sav_safe_advance"] = "PASS"

        fixture = output / "synthetic-complete-frame"
        run_isolated(
            bundle, bundle / "generate_r3r2_synthetic_primary.py",
            ["--abi", str(bundle / "V41_C2H_TRANSPORT_ABI_V1.json"),
             "--output-dir", str(fixture)],
            output / "synthetic-generator.console.log", 180)
        private = output / "synthetic-private"
        logs = output / "synthetic-logs"
        private.mkdir(parents=True, exist_ok=False)
        logs.mkdir(parents=True, exist_ok=False)
        run_isolated(
            bundle, bundle / "validate_nvp_capture_r3r2.py",
            ["--abi", str(bundle / "V41_C2H_TRANSPORT_ABI_V1.json"),
             "--primary", str(fixture / "synthetic-delta2-primary.bin"),
             "--controller-result",
             str(fixture / "synthetic-controller-result.json"),
             "--private-dir", str(private), "--logs-dir", str(logs)],
            output / "synthetic-validator.console.log", 240)
        validation = json.loads((logs / "validation-result.json").read_text(
            encoding="utf-8"))
        if (validation.get("result") != "PASS" or
                validation.get("frame_reconstruction") != "PASS" or
                validation.get("bounded_route_specific_vbi_tail") != "PASS"):
            raise GateFailure("SYNTHETIC_COMPLETE_FRAME_VALIDATION_FAILED")
        pixel = output / "synthetic-pixel"
        run_isolated(
            bundle, bundle / "analyze_nvp_video_diag1.py",
            ["--frame", str(private / "qualified-frame.uyvy"),
             "--png", str(private / "qualified-frame.png"),
             "--output-dir", str(pixel), "--session-id", "1",
             "--round", "1", "--channel", "1", "--assigned-color", "RED",
             "--status-class", "NO_VIDEO_STABLE"],
            output / "synthetic-pixel.console.log", 180)
        pixel_result = json.loads((pixel / "pixel-statistics.json").read_text(
            encoding="utf-8"))
        if pixel_result.get("result") != "PASS":
            raise GateFailure("PIXEL_ANALYSIS_DRY_RUN_FAILED")
        result["synthetic_complete_frame_validation"] = "PASS"
        result["pixel_analysis_dry_run"] = "PASS"

        result["credential_remnants"] = manifest.get("security", {}).get(
            "credential_remnants", -1)
        result["absolute_old_task_path_dependencies"] = manifest.get(
            "security", {}).get("absolute_old_task_path_dependencies", -1)
        if result["credential_remnants"] != 0:
            raise GateFailure("CREDENTIAL_REMNANTS_PRESENT")
        if result["absolute_old_task_path_dependencies"] != 0:
            raise GateFailure("ABSOLUTE_OLD_TASK_PATH_DEPENDENCIES_PRESENT")
        result["result"] = "PASS"
        result["first_blocker"] = "NONE"
    except Exception as exc:
        result["first_blocker"] = f"{type(exc).__name__}:{exc}"
        (output / "bundle-gate-result.json").write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8", newline="\n")
        print(json.dumps(result, sort_keys=True))
        return 1

    (output / "bundle-gate-result.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8", newline="\n")
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
