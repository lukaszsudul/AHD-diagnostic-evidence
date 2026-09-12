#!/usr/bin/env python3
"""Generate sanitized ACQ1-COMPAT0-R2 blocker evidence without DUT access."""

from __future__ import annotations

import csv
import hashlib
import json
import os
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path


TASK = "AHD_V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2"
SOURCE_BRANCH = "diag/v41-g2b-nvp-camera-acq1-compat0"
SOURCE_PARENT = "c7e16fa3da26545cef960a6c75427a3614c4b655"
SOURCE_COMMIT = "dae2aff60141ecdbc0afac08fc0df9a3166f66c6"
SOURCE_TREE = "21e33d481ef637667756caa8015e7fa1b1dd8ebf"
REFERENCE_COMMIT = "081ebbff9a2722d47acf16c680594be43cb179e2"
REFERENCE_TREE = "f6926ef14a34365a0e47652253f5f4d63274cb1e"
FIRST_BLOCKER = "ACQ1_COMPAT0_R2_BUILD_PROFILE_COUNTER_PREFIX_COLLISION"
RAW_BUILD_ERROR = "build-profile elaboration content mismatch"
COMBINED_RECEIPT_SHA256 = "5ADE100B1C1EC4ED40CDD231E9CA8EA0D94CF8B11855F9B3E15F89A3EE8381FF"
EXECUTOR_RECEIPT_SHA256 = "0DDC355A5AF1A6C31A9E9A378C8A94BF543DA1055CD498E7A570B513E799C42C"
SCAN1_RECEIPT_SHA256 = "EC2B5CAEBEB1B237F32C1B64A4F9D993ADA941657587B2B254EA7A9E12A8CBB5"


REQUIRED_FILES = [
    "V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2_MAIN_REPORT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_OWNER_AUTHORIZATION.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_SCOPE.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_PRIOR_TASK_INHERITANCE.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_REFERENCE_ORDER_AUTHORITY.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_REFERENCE_HELPER_DISPOSITION.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_REGISTER_SAFETY_AUDIT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_SOURCE_DIFF.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_TEST_RESULTS.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_BUILD_REPORT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_TIMING_REPORT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_CDC_REPORT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_DRC_REPORT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_METHODOLOGY_REPORT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_BITSTREAM_MANIFEST.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_RUNTIME_BUNDLE_MANIFEST.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_DUT_BUNDLE_GATE.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_PROGRAMMING_RECEIPT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_RUNTIME_IDENTITY.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_MMIO_SANITY.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_SCAN1_REGRESSION.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_CONNECTED_BASELINE_SCANS.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_FUNCTIONAL_BASELINE_A.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_FUNCTIONAL_BASELINE_B.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_PREWRITE_BASELINE.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_BASELINE_COMPARISON.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_DRYRUN_REWRITE_RECEIPT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_SLICE_ACTIONS.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_SLICE_READBACKS.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_DETECTOR_SNAPSHOTS.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_NOVID_DECISION.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_IDENTIFICATION.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_ROLLBACK_RECEIPT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_POST_ROLLBACK_SCANS.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_CLEANUP_RECEIPT.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_FINAL_STATE.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_GATE_MATRIX.csv",
    "G2B_NVP_ACQ1_COMPAT0_R2_STATE.json",
    "G2B_NVP_ACQ1_COMPAT0_R2_EVIDENCE_INDEX.md",
    "G2B_NVP_ACQ1_COMPAT0_R2_SHA256_MANIFEST.txt",
]


CHANGED_FILES = [
    "host/acq1_compat0_r2_campaign_launcher.py",
    "host/acq1_compat0_r2_launcher.py",
    "host/acq1_compat0_r2/__init__.py",
    "host/acq1_compat0_r2/campaign.py",
    "host/acq1_compat0_r2/contract.py",
    "host/acq1_compat0_r2/controller.py",
    "host/acq1_compat0_r2/evidence.py",
    "host/acq1_compat0_r2/format_decision.py",
    "host/acq1_compat0_r2/mmio.py",
    "host/acq1_compat0_r2/policy.py",
    "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json",
    "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.md",
    "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json",
    "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.md",
    "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json",
    "host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_REGISTER_SAFETY_AUDIT.md",
    "rtl/g2b/g2b_nvp_acq1_compat0_r2.sv",
    "rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv",
    "rtl/top/ahd_capture_top_xdma.sv",
    "scripts/acq1_compat0_r2/build_runtime_bundle.py",
    "tests/acq1_compat0_r2/check_static_contract.py",
    "tests/acq1_compat0_r2/run_acq1_compat0_r2_gate.ps1",
    "tests/acq1_compat0_r2/tb_g2b_nvp_acq1_compat0_r2.sv",
    "tests/acq1_compat0_r2/test_host_policy.py",
]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def write_new(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        offset = 0
        while offset < len(data):
            offset += os.write(fd, data[offset:])
        os.fsync(fd)
    finally:
        os.close(fd)


def write_text(path: Path, text: str) -> None:
    write_new(path, (text.rstrip() + "\n").encode("utf-8"))


def write_json(path: Path, value: object) -> None:
    write_text(path, json.dumps(value, indent=2, sort_keys=True, ensure_ascii=True))


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    import io

    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow({field: row.get(field, "") for field in fields})
    write_new(path, stream.getvalue().encode("utf-8"))


def copy_new(source: Path, destination: Path) -> None:
    if destination.exists():
        raise SystemExit(f"refusing to overwrite {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)


def git(source: Path, *args: str, binary: bool = False):
    result = subprocess.run(
        ["git", "-C", str(source), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout if binary else result.stdout.decode("utf-8", errors="strict").strip()


def parse_kv(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def placeholder(title: str, status: str = "NOT_REACHED") -> str:
    return f"""# {title}

- Status: `{status}`.
- First blocker: `{FIRST_BLOCKER}`.
- DUT accessed: `NO`.
- Functional NVP writes: `0`.

This phase was not entered because the governed fresh-build/sign-off prerequisite
stopped at the post-synthesis profile-elaboration evidence gate. No result is
inferred from earlier tasks.
"""


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--task-root", type=Path, required=True)
    parser.add_argument("--prompt", type=Path, required=True)
    args = parser.parse_args()

    source = args.source.resolve()
    task_root = args.task_root.resolve()
    prompt = args.prompt.resolve()
    out = Path(__file__).resolve().parents[1]
    generated = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")

    if git(source, "branch", "--show-current") != SOURCE_BRANCH:
        raise SystemExit("source branch mismatch")
    if git(source, "rev-parse", "HEAD") != SOURCE_COMMIT:
        raise SystemExit("source commit mismatch")
    if git(source, "rev-parse", "HEAD^{tree}") != SOURCE_TREE:
        raise SystemExit("source tree mismatch")
    if git(source, "status", "--porcelain"):
        raise SystemExit("source worktree is not clean")
    if git(source, "rev-parse", "HEAD^") != SOURCE_PARENT:
        raise SystemExit("source parent mismatch")

    build_dir = task_root / "reports" / "vivado_full"
    build_result_path = build_dir / "G2B_BUILD_RESULT.txt"
    profile_path = build_dir / "G2B_PROFILE_ELABORATION_RECEIPT.txt"
    counts_path = build_dir / "G2B_OPERATION_COUNTS.txt"
    build = parse_kv(build_result_path)
    profile = parse_kv(profile_path)
    counts = parse_kv(counts_path)
    required_build = {
        "BUILD": "FAIL",
        "STAGE": "SYNTHESIS",
        "SYNTH_DESIGN": "1",
        "OPT_DESIGN": "0",
        "PLACE_DESIGN": "0",
        "PHYS_OPT_DESIGN": "0",
        "ROUTE_DESIGN": "0",
        "WRITE_BITSTREAM": "0",
        "HARDWARE_ACCESSED": "NO",
        "BITSTREAM_PRODUCED": "NO",
        "ERROR": RAW_BUILD_ERROR,
    }
    for key, expected in required_build.items():
        if build.get(key) != expected:
            raise SystemExit(f"build receipt mismatch {key}: {build.get(key)!r}")
    if counts != {
        "STAGE": "SYNTHESIS", "SYNTH_DESIGN": "1", "OPT_DESIGN": "0",
        "PLACE_DESIGN": "0", "PHYS_OPT_DESIGN": "0", "ROUTE_DESIGN": "0",
        "WRITE_BITSTREAM": "0", "WRITE_DEBUG_PROBES": "0",
    }:
        raise SystemExit("operation counts mismatch")
    for key, expected in {
        "NVP_CAMERA_ACQ1_COMPAT0_R2_WRAPPER_COUNT": "1",
        "NVP_CAMERA_SCAN1_CORE_COUNT": "2",
        "NVP_DIAGNOSTIC_I2C_MASTER_COUNT": "1",
        "LEGACY_NVP_VIDEO_DIAG_CORE_COUNT": "0",
        "ACQ1_EXECUTOR_COUNT": "1",
        "PROFILE_ELABORATION_GATE": "FAIL",
    }.items():
        if profile.get(key) != expected:
            raise SystemExit(f"profile receipt mismatch {key}")

    harness = task_root / "source" / "task-local" / "g2b_nvp_camera_acq1_compat0_r2_build.tcl"
    harness_text = harness.read_text(encoding="utf-8")
    if '[string match "${ref_name}*" $cell_ref]' not in harness_text:
        raise SystemExit("prefix matcher evidence absent")
    if "g2b_nvp_camera_scan1_acq1_compat0_r2" not in harness_text:
        raise SystemExit("wrapper reference evidence absent")
    if "g2b_nvp_camera_scan1" not in harness_text:
        raise SystemExit("core reference evidence absent")

    executor_receipt = task_root / "tests" / "executor-gate-postcommit" / "G2B_NVP_ACQ1_COMPAT0_R2_TEST_RECEIPT.txt"
    scan1_receipt = task_root / "tests" / "scan1-inherited-postcommit" / "G2B_NVP_CAMERA_SCAN1_R1_SIMULATION_RECEIPT.txt"
    combined_receipt = task_root / "tests" / "G2B_NVP_ACQ1_COMPAT0_R2_COMBINED_TEST_RECEIPT.txt"
    if sha256(executor_receipt) != EXECUTOR_RECEIPT_SHA256:
        raise SystemExit("executor receipt identity mismatch")
    if sha256(scan1_receipt) != SCAN1_RECEIPT_SHA256:
        raise SystemExit("SCAN1 receipt identity mismatch")
    if sha256(combined_receipt) != COMBINED_RECEIPT_SHA256:
        raise SystemExit("combined receipt identity mismatch")

    patch_bytes = git(source, "diff", "--binary", SOURCE_PARENT, SOURCE_COMMIT, "--", binary=True)
    patch_sha = sha256_bytes(patch_bytes)
    changed = git(source, "diff-tree", "--no-commit-id", "--name-only", "-r", SOURCE_COMMIT).splitlines()
    if sorted(changed) != sorted(CHANGED_FILES):
        raise SystemExit("changed-file set mismatch")
    diff_stat = git(source, "diff", "--stat", SOURCE_PARENT, SOURCE_COMMIT)
    prompt_sha = sha256(prompt)

    resources = source / "host" / "acq1_compat0_r2" / "resources"
    for name in [
        "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json",
        "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.md",
        "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json",
        "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.md",
        "G2B_NVP_ACQ1_COMPAT0_R2_REGISTER_SAFETY_AUDIT.md",
    ]:
        copy_new(resources / name, out / name)

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_OWNER_AUTHORIZATION.md", f"""# Owner authorization

- Task: `{TASK}`.
- Prompt SHA-256: `{prompt_sha}`.
- `PROJECT_STATE_REV`: `8 - OWNER_ATTESTED_NOT_REVERIFIED`.
- Same SCAN0/SCAN1 Codex window: `YES`.
- Authorized hardware campaign was conditional on fresh build/sign-off PASS.
- The build prerequisite did not pass; therefore the physical camera gate and DUT campaign were not reached.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_SCOPE.md", f"""# Scope

The implemented diagnostic source is limited to CH1, Bank `0x05`, registers
`0x08` and `0x05`, slice levels `0x50/0x40/0x60`, exact full-byte baseline and
rollback, SCAN1 read-only observation, and read-only format decision.

Source inspection and 44/44 tests found no generic host NVP I2C, mode, EQ, ACP,
Bank9 re-arm, route, channel-enable, BGDCOL, CH2-CH4 functional-write, Flash,
capture, or second-programming path. Hardware execution was not reached.

First blocker: `{FIRST_BLOCKER}`.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_PRIOR_TASK_INHERITANCE.md", """# Prior-task inheritance

- Accepted SCAN1 source parent: `c7e16fa3da26545cef960a6c75427a3614c4b655`.
- Accepted SCAN1 source tree: `56526e17154f8e06f3eb4b95233934c18b6ee06e`.
- Hardware-qualified SCAN1 bitstream SHA-256: `6DACBFFF9B6DA0A904B2A49B18C9BA59695DBA04B834A8A758AD44184769443E`.
- Previous camera-connected response is context only; it is not claimed as a current-run result.
- No prior bitstream, checkpoint, runtime bundle, credential root, or hardware artifact was reused.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_REFERENCE_ORDER_AUTHORITY.md", f"""# Reference order authority

- Pinned reference commit: `{REFERENCE_COMMIT}`.
- Pinned reference tree: `{REFERENCE_TREE}`.
- License disposition: `SEMANTIC_USE_ONLY_NO_DIRECT_COPY`.
- Proven forward order: `BANK5_0x08_LEVEL_THEN_BANK5_0x05_A4`.
- Levels: `0x50`, `0x40`, `0x60`.
- No read is permitted between the two writes.
- Legacy reversed order present in the implementation: `NO`.
- Reference source bytes are not published.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_REFERENCE_HELPER_DISPOSITION.md", """# Reference helper disposition

- Result: `PROVEN_NOT_EXECUTED`.
- Governed target context: AHD 1080p25 / 1080p no-video.
- Reference CVBS helper condition is limited to mode values below `NVP6134_VI_720P_2530`.
- Post-companion `0x08` rewrite: `NOT_IMPLEMENTED`.
- No SD-mode/CVBS helper branch is present in this executor.
""")

    changed_md = "\n".join(f"- `{name}`" for name in CHANGED_FILES)
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_SOURCE_DIFF.md", f"""# Source diff

- Branch: `{SOURCE_BRANCH}`.
- Parent: `{SOURCE_PARENT}`.
- Commit: `{SOURCE_COMMIT}`.
- Tree: `{SOURCE_TREE}`.
- Changed files: `24`.
- Canonical `git diff --binary parent commit` SHA-256: `{patch_sha}`.
- PRODUCT branch/source changed: `NO`.
- Transport ABI changed: `NO`.

## Diff stat

```text
{diff_stat}
```

## Changed paths

{changed_md}
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_TEST_RESULTS.md", f"""# Test results

- Inherited SCAN1 simulation/host gate: `24/24 PASS`.
- Executor/integration gate: `20/20 PASS`.
- Combined offline gate: `44/44 PASS`.
- Unauthorized functional writes in tests: `0`.
- Credential remnants: `0`.
- Raw payload through controller IPC: `NO`.
- Hardware accessed by tests: `NO`.
- SCAN1 receipt SHA-256: `{SCAN1_RECEIPT_SHA256}`.
- Executor receipt SHA-256: `{EXECUTOR_RECEIPT_SHA256}`.
- Combined receipt SHA-256: `{COMBINED_RECEIPT_SHA256}`.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_BUILD_REPORT.md", f"""# Fresh build report

## Governed result

- Vivado: `2025.2`, SW build `6299465`.
- Fresh nonincremental build attempt: `1`.
- `synth_design` invocations: `1`.
- Vivado command result for `synth_design`: completed successfully with `0` errors and `0` critical warnings.
- Governed fresh-synthesis gate: `FAIL`.
- `opt_design/place_design/phys_opt_design/route_design`: `0/0/0/0` invocations.
- Bitstream writes: `0`.
- Checkpoint reuse: `NO`.
- Hardware accessed: `NO`.
- Raw build error: `{RAW_BUILD_ERROR}`.
- First blocker: `{FIRST_BLOCKER}`.

## Root cause

The post-synthesis profile counter intentionally accepts either a terminal
instance-name match or a reference-name match. Its reference-name clause uses
the prefix expression `string match \"${{ref_name}}*\"`. The query for
`g2b_nvp_camera_scan1` therefore counts both the wrapper reference
`g2b_nvp_camera_scan1_acq1_compat0_r2` and the one nested scanner reference
`g2b_nvp_camera_scan1`. The receipt is consequently `wrapper=1`,
`SCAN1_CORE_COUNT=2`, `ACQ1_EXECUTOR_COUNT=1`, `I2C_MASTER_COUNT=1`, while the
source generate chain is mutually exclusive and the wrapper contains one
scanner core. This proves a profile-evidence counter prefix collision; it does
not authorize overriding the failed gate.

The build exited before writing the synthesis checkpoint. No retry, harness
patch, implementation continuation, DCP, bitstream, or DUT action was performed.

- Build-result SHA-256: `{sha256(build_result_path)}`.
- Profile-receipt SHA-256: `{sha256(profile_path)}`.
- Operation-count SHA-256: `{sha256(counts_path)}`.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_TIMING_REPORT.md", placeholder("Timing report") + "\nWNS/TNS/WHS/THS and internal unconstrained endpoints: `N/A`; route was not reached.\n")
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_CDC_REPORT.md", placeholder("CDC report") + "\nCDC, new unresolved critical CDC, new unresolved warning CDC, active bus-skew 11/11, and promoted replacement checks 17/17: `NOT_REACHED`.\n")
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_DRC_REPORT.md", placeholder("DRC report"))
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_METHODOLOGY_REPORT.md", placeholder("Methodology report"))
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_BITSTREAM_MANIFEST.md", placeholder("Bitstream manifest") + "\nCandidate path: `NONE`; SHA-256: `NONE`; size: `0`; LTX: `NONE`; FPGA programming attempts: `0`.\n")

    write_json(out / "G2B_NVP_ACQ1_COMPAT0_R2_RUNTIME_BUNDLE_MANIFEST.json", {
        "task": TASK,
        "status": "NOT_REACHED",
        "first_blocker": FIRST_BLOCKER,
        "bundle_created": False,
        "hardware_accessed": False,
        "functional_writes": 0,
    })
    for filename, title in [
        ("G2B_NVP_ACQ1_COMPAT0_R2_DUT_BUNDLE_GATE.md", "DUT runtime-bundle gate"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_PROGRAMMING_RECEIPT.md", "Programming receipt"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_RUNTIME_IDENTITY.md", "Runtime identity"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_MMIO_SANITY.md", "SCAN1 and ACQ MMIO sanity"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_SCAN1_REGRESSION.md", "SCAN1 hardware regression"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_BASELINE_COMPARISON.md", "Two-register baseline comparison"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_DRYRUN_REWRITE_RECEIPT.md", "Idempotent dry-run rewrite"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_NOVID_DECISION.md", "NOVID decision"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION.md", "Format decision"),
        ("G2B_NVP_ACQ1_COMPAT0_R2_ROLLBACK_RECEIPT.md", "Exact rollback receipt"),
    ]:
        write_text(out / filename, placeholder(title))

    for filename in [
        "G2B_NVP_ACQ1_COMPAT0_R2_FUNCTIONAL_BASELINE_A.json",
        "G2B_NVP_ACQ1_COMPAT0_R2_FUNCTIONAL_BASELINE_B.json",
        "G2B_NVP_ACQ1_COMPAT0_R2_PREWRITE_BASELINE.json",
    ]:
        write_json(out / filename, {
            "status": "NOT_REACHED", "first_blocker": FIRST_BLOCKER,
            "entry_bank": None, "bank5_reg05": None, "bank5_reg08": None,
            "hardware_accessed": False, "functional_writes": 0,
        })

    placeholder_csvs = {
        "G2B_NVP_ACQ1_COMPAT0_R2_CONNECTED_BASELINE_SCANS.csv": ["scan", "status", "novid", "f0", "f2", "f3", "note"],
        "G2B_NVP_ACQ1_COMPAT0_R2_SLICE_ACTIONS.csv": ["order", "level", "executed", "write_count", "status", "note"],
        "G2B_NVP_ACQ1_COMPAT0_R2_SLICE_READBACKS.csv": ["level", "companion_readback", "level_readback", "entry_bank_restore", "status", "note"],
        "G2B_NVP_ACQ1_COMPAT0_R2_DETECTOR_SNAPSHOTS.csv": ["snapshot", "level", "novid", "f0", "f2", "f3", "status", "note"],
        "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_IDENTIFICATION.csv": ["snapshot", "raw_f0", "f2", "f3", "discriminator", "detected_format", "status", "note"],
        "G2B_NVP_ACQ1_COMPAT0_R2_POST_ROLLBACK_SCANS.csv": ["snapshot", "entry_bank", "bank5_reg05", "bank5_reg08", "status", "note"],
    }
    for filename, fields in placeholder_csvs.items():
        row = {field: "NOT_REACHED" for field in fields}
        row[fields[-1]] = FIRST_BLOCKER
        write_csv(out / filename, fields, [row])

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_CLEANUP_RECEIPT.md", f"""# Cleanup receipt

- Status: `NOT_APPLICABLE_NO_HARDWARE_CONTACT`.
- DUT root/credentials/locks created: `NO`.
- Driver loaded by task: `NO`; XDMA nodes created by task: `NO`.
- Stream/AIO/native helper processes created by task: `NO`.
- Functional NVP writes: `0`; rollback required: `NO`.
- Programming attempts: `0`; warm reboot: `0`; power-cycle: `NO`; Flash: `NO`.
- Source worktree remains clean at `{SOURCE_COMMIT}`.
- NVP persistent state changed: `NO`.
""")

    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_FINAL_STATE.md", f"""# Final state

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.
- Overall result: `BLOCKED`.
- First blocker: `{FIRST_BLOCKER}`.
- Final execution point: `PHASE_E_POST_SYNTHESIS_PROFILE_ELABORATION_GATE`.
- Source branch publication: `PASS` at `{SOURCE_COMMIT}` / `{SOURCE_TREE}`.
- Offline tests: `44/44 PASS`.
- Fresh synthesis gate: `FAIL`; implementation/sign-off/bitstream/runtime/hardware: `NOT_REACHED`.
- Functional NVP writes: `0`; rollback invoked: `NO`; programming attempts: `0`.
- PRODUCT/SSOT/META/NVP persistent state: `UNCHANGED`.
- Physical Owner action required: `NONE`.
""")

    gate_rows = [
        {"order": 1, "gate": "source/reference authority", "status": "PASS", "evidence": f"{SOURCE_PARENT};{REFERENCE_COMMIT}", "next": "implementation"},
        {"order": 2, "gate": "authorized source scope and isolation", "status": "PASS", "evidence": "24 changed files; PRODUCT exclusion PASS", "next": "offline tests"},
        {"order": 3, "gate": "SCAN1 inherited tests", "status": "PASS", "evidence": "24/24", "next": "executor tests"},
        {"order": 4, "gate": "executor/integration tests", "status": "PASS", "evidence": "20/20", "next": "fresh build"},
        {"order": 5, "gate": "fresh synthesis and profile elaboration", "status": "BLOCKED", "evidence": FIRST_BLOCKER, "next": "HARD_STOP"},
        {"order": 6, "gate": "implementation/sign-off/bitstream", "status": "NOT_REACHED", "evidence": RAW_BUILD_ERROR, "next": "NOT_REACHED"},
        {"order": 7, "gate": "runtime bundle/programming/runtime identity", "status": "NOT_REACHED", "evidence": FIRST_BLOCKER, "next": "NOT_REACHED"},
        {"order": 8, "gate": "camera/baseline/slice/format/rollback", "status": "NOT_REACHED", "evidence": FIRST_BLOCKER, "next": "NOT_REACHED"},
        {"order": 9, "gate": "evidence publication", "status": "REQUIRED_POST_COMMIT", "evidence": "no-force push and commit-pinned raw-byte read-back", "next": "external receipt"},
    ]
    write_csv(out / "G2B_NVP_ACQ1_COMPAT0_R2_GATE_MATRIX.csv", ["order", "gate", "status", "evidence", "next"], gate_rows)

    state = {
        "task": TASK,
        "generated_utc": generated,
        "project_state_rev": "8 - OWNER_ATTESTED_NOT_REVERIFIED",
        "same_scan0_scan1_window": True,
        "engineering_gate": "BLOCKED",
        "evidence_publication": "PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": "BLOCKED",
        "first_blocker": FIRST_BLOCKER,
        "raw_build_error": RAW_BUILD_ERROR,
        "source_branch": SOURCE_BRANCH,
        "source_parent": SOURCE_PARENT,
        "source_commit": SOURCE_COMMIT,
        "source_tree": SOURCE_TREE,
        "source_diff_sha256": patch_sha,
        "source_changed_file_count": len(CHANGED_FILES),
        "source_branch_publication": "PASS",
        "reference_commit": REFERENCE_COMMIT,
        "reference_tree": REFERENCE_TREE,
        "reference_license_disposition": "SEMANTIC_USE_ONLY_NO_DIRECT_COPY",
        "reference_forward_order": "BANK5_0x08_LEVEL_THEN_BANK5_0x05_A4",
        "reference_helper_disposition": "PROVEN_NOT_EXECUTED",
        "scan1_tests": "24/24_PASS",
        "executor_tests": "20/20_PASS",
        "combined_tests": "44/44_PASS",
        "synth_design_command": "PASS_0_ERRORS_0_CRITICAL_WARNINGS",
        "fresh_synthesis_gate": "FAIL",
        "profile_receipt": profile,
        "operation_counts": counts,
        "implementation": "NOT_REACHED",
        "bitstream": None,
        "runtime_bundle": "NOT_REACHED",
        "dut_contacted": False,
        "camera_gate": "NOT_REACHED",
        "functional_writes": 0,
        "unauthorized_functional_writes": 0,
        "programming_attempts": 0,
        "warm_reboots": 0,
        "power_cycle": False,
        "rollback_invoked": False,
        "product_source_changed": False,
        "ssot_changed": False,
        "meta_performed": False,
        "nvp_persistent_state_changed": False,
        "reference_source_published": False,
        "vendor_pdf_published": False,
        "camera_pixels_published": False,
        "publication_repository": "lukaszsudul/AHD-diagnostic-evidence",
        "publication_directory": out.name,
        "publication_commit": "THIS_COMMIT",
        "remote_readback": "REQUIRED_POST_COMMIT_GATE",
    }
    write_json(out / "G2B_NVP_ACQ1_COMPAT0_R2_STATE.json", state)

    write_text(out / "V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2_MAIN_REPORT.md", f"""# AHD v41 G2B-NVP-CAMERA-ACQ1-COMPAT0-R2 main report

## Result

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.
- Overall result: `BLOCKED`.
- First blocker: `{FIRST_BLOCKER}`.

## Completed gates

The pinned reference order and helper disposition passed. Diagnostic source was
committed and published as `{SOURCE_COMMIT}` with tree `{SOURCE_TREE}`. PRODUCT
exclusion passed. Inherited SCAN1 tests passed `24/24`; executor/integration
tests passed `20/20`; the combined offline gate passed `44/44`.

## First blocked gate

One fresh Vivado 2025.2 run invoked `synth_design` exactly once. The command
completed with zero errors and zero critical warnings. The immediately following
profile-elaboration evidence gate failed with `{RAW_BUILD_ERROR}` before
`opt_design`.

The failure is a proven counter-prefix collision in the task-local evidence
harness. The query for reference name `g2b_nvp_camera_scan1` uses a trailing
wildcard and therefore counts both `g2b_nvp_camera_scan1` and its wrapper
`g2b_nvp_camera_scan1_acq1_compat0_r2`. This yields the receipt values
`wrapper=1`, `SCAN1 core count=2`, `executor=1`, and `I2C master=1`. The source
generate chain is mutually exclusive and the wrapper contains one scanner core,
but the failed governed gate was not overridden.

No retry or continuation was made. `opt_design`, placement, physical
optimization, route, CDC reconciliation, timing, DRC, methodology, resource
sign-off, bitstream generation, runtime bundle construction, DUT access,
programming, camera gate, I2C action, capture, and rollback were not reached.

## Preserved state and non-claims

Functional NVP writes are `0`; programming attempts and reboots are `0`; no
task-local hardware root, credential helper, or lock was created. PRODUCT,
SSOT, META, and NVP persistent state are unchanged. The publication contains no
reference source, vendor PDF, bitstream, DCP, XDMA driver, native binary, camera
image, or pixel payload.

## Required closure

A separate Owner-authorized continuation may correct the task-local profile
counter so that its reference-name test is exact rather than prefix-based, then
perform a new fresh build/sign-off. This task cannot reuse or reinterpret the
consumed failed build as PASS.

Generated UTC: `{generated}`.
""")

    raw_files = {
        build_result_path: "raw/G2B_BUILD_RESULT.txt",
        profile_path: "raw/G2B_PROFILE_ELABORATION_RECEIPT.txt",
        counts_path: "raw/G2B_OPERATION_COUNTS.txt",
        build_dir / "G2B_NVP_CAMERA_ACQ1_COMPAT0_R2_PRODUCT_EXCLUSION_ELABORATION.txt": "raw/G2B_PRODUCT_EXCLUSION_ELABORATION.txt",
        build_dir / "G2B_NVP_CAMERA_ACQ1_COMPAT0_R2_SOURCE_ARCHITECTURE_GATE.txt": "raw/G2B_SOURCE_ARCHITECTURE_GATE.txt",
        build_dir / "G2B_MMIO_ROUTER_SOURCE_INCLUSION.txt": "raw/G2B_MMIO_ROUTER_SOURCE_INCLUSION.txt",
        build_dir / "G2B_BUILD_PROVENANCE.txt": "raw/G2B_BUILD_PROVENANCE.txt",
        combined_receipt: "raw/G2B_COMBINED_TEST_RECEIPT.txt",
        executor_receipt: "raw/G2B_EXECUTOR_TEST_RECEIPT.txt",
        scan1_receipt: "raw/G2B_SCAN1_TEST_RECEIPT.txt",
    }
    for src, rel in raw_files.items():
        copy_new(src, out / rel)

    clean_source = out / "clean-room" / "source"
    for rel in CHANGED_FILES:
        copy_new(source / rel, clean_source / rel)
    copy_new(harness, clean_source / "task-local" / harness.name)
    write_text(out / "clean-room" / "README.md", """# Clean-room source map

- Fixed executor: `source/rtl/g2b/g2b_nvp_acq1_compat0_r2.sv`.
- SCAN1/executor arbitration and MMIO integration: `source/rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` and `source/rtl/top/ahd_capture_top_xdma.sv`.
- Operation checker: `source/tests/acq1_compat0_r2/check_static_contract.py`.
- Format decision: `source/host/acq1_compat0_r2/format_decision.py`.
- Host controller and baseline/rollback policy: `source/host/acq1_compat0_r2/controller.py`, `campaign.py`, and `policy.py`.
- Runtime bundle builder: `source/scripts/acq1_compat0_r2/build_runtime_bundle.py` (not executed after the blocker).
- Evidence helpers/aggregator: `source/host/acq1_compat0_r2/evidence.py` and `generate_acq1_compat0_r2_evidence.py`.
- Failed evidence harness: `source/task-local/g2b_nvp_camera_acq1_compat0_r2_build.tcl`.

No pinned reference-driver source is included.
""")

    self_test = '''#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
required = json.loads((root / "G2B_NVP_ACQ1_COMPAT0_R2_STATE.json").read_text(encoding="utf-8"))
assert required["engineering_gate"] == "BLOCKED"
assert required["fresh_synthesis_gate"] == "FAIL"
assert required["operation_counts"]["SYNTH_DESIGN"] == "1"
for name in ("OPT_DESIGN", "PLACE_DESIGN", "PHYS_OPT_DESIGN", "ROUTE_DESIGN", "WRITE_BITSTREAM"):
    assert required["operation_counts"][name] == "0"
assert required["profile_receipt"]["NVP_CAMERA_ACQ1_COMPAT0_R2_WRAPPER_COUNT"] == "1"
assert required["profile_receipt"]["NVP_CAMERA_SCAN1_CORE_COUNT"] == "2"
assert required["functional_writes"] == 0
manifest = root / "G2B_NVP_ACQ1_COMPAT0_R2_SHA256_MANIFEST.txt"
for line in manifest.read_text(encoding="utf-8").splitlines():
    digest, rel = line.split("  ", 1)
    assert hashlib.sha256((root / rel).read_bytes()).hexdigest().upper() == digest
prohibited = {".bit", ".dcp", ".ltx", ".pdf", ".png", ".uyvy", ".exe", ".dll", ".sys"}
assert not [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in prohibited]
print("ACQ1_COMPAT0_R2_EVIDENCE_SELF_TEST=PASS")
'''
    write_text(out / "clean-room" / "test_evidence.py", self_test)

    current_files = sorted(p.relative_to(out).as_posix() for p in out.rglob("*") if p.is_file())
    index_lines = [
        "# ACQ1-COMPAT0-R2 evidence index", "",
        "- Engineering gate: `BLOCKED`.",
        "- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.",
        f"- First blocker: `{FIRST_BLOCKER}`.",
        "- Hardware accessed: `NO`; functional writes: `0`.",
        "- Prohibited binary/reference/pixel artifacts: `ABSENT`.", "", "## Files", "",
    ] + [f"- `{name}`" for name in current_files] + ["- `G2B_NVP_ACQ1_COMPAT0_R2_SHA256_MANIFEST.txt`"]
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_EVIDENCE_INDEX.md", "\n".join(index_lines))

    manifest_lines = []
    for path in sorted(p for p in out.rglob("*") if p.is_file() and p.name != "G2B_NVP_ACQ1_COMPAT0_R2_SHA256_MANIFEST.txt"):
        manifest_lines.append(f"{sha256(path)}  {path.relative_to(out).as_posix()}")
    write_text(out / "G2B_NVP_ACQ1_COMPAT0_R2_SHA256_MANIFEST.txt", "\n".join(manifest_lines))

    missing = [name for name in REQUIRED_FILES if not (out / name).is_file()]
    if missing:
        raise SystemExit("missing required evidence: " + ", ".join(missing))
    print(f"OUTPUT={out}")
    print(f"REQUIRED_FILES={len(REQUIRED_FILES)}/{len(REQUIRED_FILES)}")
    print("SCAN1_TESTS=24/24_PASS")
    print("EXECUTOR_TESTS=20/20_PASS")
    print("COMBINED_TESTS=44/44_PASS")
    print("FRESH_SYNTHESIS_GATE=FAIL")
    print(f"FIRST_BLOCKER={FIRST_BLOCKER}")
    print(f"SOURCE_DIFF_SHA256={patch_sha}")


if __name__ == "__main__":
    main()
