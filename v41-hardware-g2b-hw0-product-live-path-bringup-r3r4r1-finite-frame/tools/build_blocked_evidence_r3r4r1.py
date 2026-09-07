#!/usr/bin/env python3
"""Build sanitized R3R4R1 evidence after the governed offline hard stop."""
from __future__ import annotations

import csv
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from typing import Iterable


TASK = "G2B-HW0-PRODUCT-R3R4R1"
ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R1_20260907T050126Z")
EVIDENCE_REPO = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
SOURCE_REPO = Path(r"C:\FPGA\V41_G2B")
EVIDENCE_DIR_NAME = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame"
)
STAGE = ROOT / "publication" / "sealed-attempt-3" / EVIDENCE_DIR_NAME
R3R3_DIR = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record"
)
R3R3_COMMIT = "6cff7ad374575df84bc7d8794565dbd7d9cd869f"
R3R4_DIR = "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4-finite-frame"
R3R4_COMMIT = "2bfcba2476a31a06bdf940881cd5d0a20614333e"
DRV_COMMIT = "9aacc157dab5fe604faf66501b0129613b98ae2d"
SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
BIT_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
DCP_SHA = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"
DRIVER_SHA = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"
ABI_SHA = "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6"
BLOCKER = "R3R4R1_CAPTURE_TOOL_HARD_GATE_FAILED"
FAILED_CASE = "PARENT_QUIESCENCE_HANDSHAKE_PASS"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def git_bytes(cwd: Path, *args: str) -> bytes:
    return subprocess.check_output(["git", *args], cwd=cwd)


def git_text(cwd: Path, *args: str) -> str:
    return git_bytes(cwd, *args).decode("utf-8").strip()


def git_json(cwd: Path, object_name: str) -> dict:
    return json.loads(git_bytes(cwd, "show", object_name).decode("utf-8"))


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text.rstrip() + "\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_json(path: Path, value: dict) -> None:
    write_text(path, json.dumps(value, indent=2))


def write_csv(path: Path, columns: Iterable[str], rows: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=list(columns), lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)
        handle.flush()
        os.fsync(handle.fileno())


def verify_authority() -> dict:
    local_main = git_text(EVIDENCE_REPO, "rev-parse", "HEAD")
    remote_main = git_text(
        EVIDENCE_REPO, "ls-remote", "origin", "refs/heads/main"
    ).split()[0]
    require(local_main == R3R4_COMMIT, "EVIDENCE_LOCAL_MAIN_NOT_R3R4")
    require(remote_main == R3R4_COMMIT, "EVIDENCE_REMOTE_MAIN_NOT_R3R4")
    require(
        not git_text(
            EVIDENCE_REPO, "status", "--porcelain", "--", "project-current-state"
        ),
        "PROJECT_CURRENT_STATE_DIRTY",
    )
    project = git_json(
        EVIDENCE_REPO, "HEAD:project-current-state/PROJECT_STATE.json"
    )
    require(project["project_state_revision"] == 8, "PROJECT_STATE_REV_NOT_8")
    require(
        project["tracks"]["meta"]["current_task"] == "META-8A",
        "META8A_NOT_AUTHORITATIVE",
    )
    product = project["tracks"]["product"]["g2b_hw0_product"]
    require(
        product["readiness"] == "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
        "CONTROLLED_HARDWARE_NOT_AUTHORIZED",
    )
    require(
        product["qualification_state"] == "NOT_PROVEN",
        "G2B_HW_QUALIFICATION_STATE_UNEXPECTED",
    )

    predecessor = json.loads(
        (ROOT / "artifacts/predecessor-manifest-verification.json").read_text(
            "utf-8"
        )
    )
    require(predecessor["overall"] == "PASS", "PREDECESSOR_MANIFEST_FAIL")
    require(
        predecessor["r3r3"]["entries"] == 98
        and predecessor["r3r4"]["entries"] == 40,
        "PREDECESSOR_MANIFEST_COUNT_MISMATCH",
    )
    r3r3 = git_json(
        EVIDENCE_REPO,
        f"{R3R3_COMMIT}:{R3R3_DIR}/G2B_HW0_PRODUCT_R3R3_STATE.json",
    )
    r3r3_expected = {
        "sram_programming_attempts": 1,
        "warm_reboots": 1,
        "final_done": 1,
        "T1": "PASS",
        "T2": "PASS",
        "reader_primary_records": 1,
        "reader_drain_records": 52,
        "reader_complete_records": 53,
        "reader_trailing_bytes": 0,
        "record_bytes_persisted": False,
        "header": "NOT_REACHED",
        "counter_reconciliation": "NOT_REACHED",
        "cleanup": "PASS",
        "endpoint_final": "PRESENT_UNBOUND",
        "nodes_final": "REMOVED",
        "candidate_left_in_volatile_sram": True,
        "post_boot_id": "614295f4-c62b-4430-ae67-06013bea7084",
    }
    for key, expected in r3r3_expected.items():
        require(r3r3.get(key) == expected, f"R3R3_FACT_MISMATCH:{key}")

    r3r4 = git_json(
        EVIDENCE_REPO,
        f"{R3R4_COMMIT}:{R3R4_DIR}/G2B_HW0_PRODUCT_R3R4_STATE.json",
    )
    r3r4_expected = {
        "engineering_gate": "BLOCKED",
        "first_blocker": "R3R4_CAPTURE_TOOL_HARD_GATE_FAILED",
        "hardware_accessed": False,
        "dut_connections": 0,
        "driver_load_attempts": 0,
        "combined_t34_sessions": 0,
        "prior_immutable_artifact_new_writes": 0,
    }
    for key, expected in r3r4_expected.items():
        require(r3r4.get(key) == expected, f"R3R4_FACT_MISMATCH:{key}")
    require(
        r3r4["capture_tool_offline_selftests"] == {"passed": 1, "total": 11},
        "R3R4_SELFTEST_FACT_MISMATCH",
    )

    require(
        git_text(SOURCE_REPO, "branch", "--show-current")
        == "integration/v41-g2b-onech-c2h",
        "SOURCE_BRANCH_MISMATCH",
    )
    require(
        git_text(SOURCE_REPO, "rev-parse", "HEAD") == SOURCE_COMMIT,
        "SOURCE_COMMIT_MISMATCH",
    )
    require(
        git_text(SOURCE_REPO, "rev-parse", "HEAD^{tree}") == SOURCE_TREE,
        "SOURCE_TREE_MISMATCH",
    )
    require(
        not git_text(
            SOURCE_REPO, "status", "--porcelain", "--untracked-files=all"
        ),
        "SOURCE_WORKTREE_DIRTY",
    )
    source_remote = git_text(
        SOURCE_REPO,
        "ls-remote",
        "origin",
        "refs/heads/integration/v41-g2b-onech-c2h",
    ).split()[0]
    require(source_remote == SOURCE_COMMIT, "SOURCE_REMOTE_MISMATCH")

    bitstream = Path(
        r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316"
        r"\G2B_PRODUCT_RECOVERY4.bit"
    )
    dcp = Path(
        r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316"
        r"\G2B_PRODUCT_SIGNED_OFF.dcp"
    )
    driver_path = Path(
        r"C:\FPGA\V41_G2B_DRIVER_ARTIFACTS"
        r"\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko"
    )
    require(sha(bitstream) == BIT_SHA, "BITSTREAM_HASH_MISMATCH")
    require(sha(dcp) == DCP_SHA, "DCP_HASH_MISMATCH")
    require(sha(driver_path) == DRIVER_SHA, "DRIVER_HASH_MISMATCH")
    require(
        sha(ROOT / "scripts/V41_C2H_TRANSPORT_ABI_V1.json") == ABI_SHA,
        "ABI_HASH_MISMATCH",
    )
    driver = git_json(
        EVIDENCE_REPO,
        f"{DRV_COMMIT}:v41-host-g2b-hw0-ahd-xdma-driver-build/"
        "G2B_HW0_DRV1_STATE.json",
    )
    require(driver["engineering_gate"] == "PASS", "DRIVER_AUTHORITY_NOT_PASS")
    require(
        driver["candidate"]["sha256"] == DRIVER_SHA
        and driver["candidate"]["internal_module_name"] == "xdma_ahd_pcie",
        "DRIVER_CANDIDATE_IDENTITY_MISMATCH",
    )
    require(
        driver["sealed_artifacts"]["remote_module_path"]
        == "/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/"
        "20260906T121539Z/xdma_ahd_pcie.ko",
        "DRIVER_REMOTE_PATH_MISMATCH",
    )
    return {
        "result": "PASS",
        "project_state_rev": 8,
        "meta8a_authoritative": True,
        "controlled_hardware_testing_authorized": True,
        "g2b_hw_qualified": False,
        "local_main_before_publication": local_main,
        "remote_main_before_publication": remote_main,
        "r3r3_evidence_commit": R3R3_COMMIT,
        "r3r3_manifest_entries_verified": 98,
        "r3r3_required_facts_verified": True,
        "failed_r3r4_evidence_commit": R3R4_COMMIT,
        "r3r4_manifest_entries_verified": 40,
        "failed_r3r4_required_facts_verified": True,
        "source_branch": "integration/v41-g2b-onech-c2h",
        "source_commit": SOURCE_COMMIT,
        "source_tree": SOURCE_TREE,
        "source_remote_match": True,
        "source_clean": True,
        "bitstream_bytes": bitstream.stat().st_size,
        "bitstream_sha256": BIT_SHA,
        "dcp_bytes": dcp.stat().st_size,
        "dcp_sha256": DCP_SHA,
        "driver_authority_commit": DRV_COMMIT,
        "driver_controller_copy_bytes": driver_path.stat().st_size,
        "driver_sha256": DRIVER_SHA,
        "abi_sha256": ABI_SHA,
    }


def stopped_gate() -> tuple[dict, dict]:
    failure = json.loads(
        (
            ROOT
            / "artifacts/G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE.json"
        ).read_text("utf-8")
    )
    analysis = json.loads(
        (
            ROOT
            / "artifacts/G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE_ANALYSIS.json"
        ).read_text("utf-8")
    )
    require(failure["blocker"] == BLOCKER, "FAILURE_BLOCKER_MISMATCH")
    require(
        failure["hardware_access"] is False and failure["dut_connections"] == 0,
        "FAILURE_HARDWARE_BOUNDARY_MISMATCH",
    )
    require(
        analysis["passed"] == 4
        and analysis["total"] == 11
        and analysis["cases"][FAILED_CASE] == "FAIL",
        "STOPPED_CASE_CLASSIFICATION_MISMATCH",
    )
    require(
        analysis["partial_read_semantic_result"] == "PASS"
        and all(analysis["partial_read_semantic_checks"].values()),
        "PARTIAL_READ_SEMANTIC_CHECKS_NOT_PASS",
    )
    require(
        analysis["actual_completions"]
        == [False, False, False, False, False, True, True],
        "QUIET_WINDOW_ACTUAL_MISMATCH",
    )
    require(
        analysis["coded_expected_completions"]
        == [False, False, False, False, False, False, True],
        "QUIET_WINDOW_CODED_EXPECTATION_MISMATCH",
    )
    return failure, analysis


def boundary_summary() -> dict:
    comparison = json.loads(
        (
            ROOT
            / "artifacts/immutable-boundary-after.comparison.json"
        ).read_text("utf-8")
    )
    require(comparison["result"] == "PASS", "IMMUTABLE_BOUNDARY_FAIL")
    require(
        comparison["prior_immutable_artifact_new_writes"] == 0
        and comparison["removed_files"] == 0
        and comparison["changed_files"] == 0,
        "IMMUTABLE_BOUNDARY_DELTA",
    )
    return {
        "result": "PASS",
        "prior_immutable_artifact_new_writes": 0,
        "removed_files": 0,
        "changed_files": 0,
        "snapshot_roots": 20,
        "snapshot_files": 8680,
        "product_source_head_unchanged":
            comparison["product_source_head_unchanged"],
        "product_source_tree_unchanged":
            comparison["product_source_tree_unchanged"],
        "product_source_status_unchanged":
            comparison["product_source_status_unchanged"],
        "project_state_changes": 0,
        "preexisting_untracked_work_areas_preserved": [
            ".diag0-work/",
            ".meta8a-work/",
        ],
    }


def not_reached(title: str, extra: str = "") -> str:
    suffix = ("\n" + extra.strip() + "\n") if extra.strip() else ""
    return f"""# {title}

Result: `NOT_REACHED`.

The mandatory offline suite stopped at `{FAILED_CASE}` with
`{BLOCKER}`. The governed order prohibited architecture-gate advancement and
the first DUT connection. No current DUT value is inferred from predecessor
evidence.{suffix}"""


def build() -> dict:
    require(not STAGE.exists(), "PUBLIC_STAGE_ALREADY_EXISTS")
    authority = verify_authority()
    failure, analysis = stopped_gate()
    boundary = boundary_summary()
    delta = json.loads(
        (ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.json").read_text(
            "utf-8"
        )
    )
    require(
        delta["result"] == "PASS"
        and delta["authorized_tool_delta"] == "SELFTEST_PLUS_RUN_IDENTITY",
        "TOOL_DELTA_NOT_AUTHORIZED",
    )
    helper_path = ROOT / "scripts/Invoke-R3R4R1DutConnection.ps1"
    helper_hash = sha(helper_path)
    credential_remnants = list(ROOT.rglob("*.credential.tmp"))
    require(not credential_remnants, "CREDENTIAL_REMNANT")
    connection_receipts = list((ROOT / "logs").glob("connection-*.json"))
    require(not connection_receipts, "UNEXPECTED_DUT_CONNECTION_RECEIPT")

    STAGE.mkdir(parents=True)
    (STAGE / "raw").mkdir()
    (STAGE / "tools").mkdir()

    selftest_public = {
        "task": TASK,
        "result": "FAIL",
        "engineering_disposition": "BLOCKED",
        "blocker": BLOCKER,
        "failed_case": FAILED_CASE,
        "passed": 4,
        "total": 11,
        "cases": analysis["cases"],
        "invalid_chunk_count_assertion_removed": True,
        "partial_read_semantic_checks":
            analysis["partial_read_semantic_checks"],
        "partial_read_semantic_result": "PASS",
        "actual_quiet_window_completions": analysis["actual_completions"],
        "coded_expected_quiet_window_completions":
            analysis["coded_expected_completions"],
        "diagnosed_failed_assertion": analysis["diagnosed_failed_assertion"],
        "exception_type": failure["exception_type"],
        "exception_repr": failure["exception_repr"],
        "traceback": failure["traceback"],
        "governed_suite_rerun": False,
        "capture_tool_or_selftest_modified_after_failure": False,
        "hardware_access": False,
        "dut_connections": 0,
        "real_camera_data": False,
        "synthetic_artifacts_contained_in_fresh_root": True,
        "abi_sha256": ABI_SHA,
        "raw_record_control_ipc": False,
        "primary_sha256": analysis["primary_sha256"],
        "drain_sha256": analysis["drain_sha256"],
        "first_record_sha256": analysis["first_record_sha256"],
        "first_payload_sha256": analysis["first_payload_sha256"],
    }

    state = {
        "task": TASK,
        "engineering_gate": "BLOCKED",
        "evidence_publication":
            "SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "failed_case": FAILED_CASE,
        "project_state_rev_at_start": 8,
        "project_state_rev_at_end": 8,
        "r3r3_evidence": "VERIFIED",
        "failed_r3r4_evidence": "VERIFIED",
        "run_root": str(ROOT),
        "prior_immutable_artifact_new_writes": 0,
        "tool_baseline": "VERIFIED",
        "authorized_tool_delta": "SELFTEST_PLUS_RUN_IDENTITY",
        "invalid_chunk_count_assertion_removed": True,
        "partial_read_semantic_checks": "PASS",
        "capture_tool_offline_selftests": {"passed": 4, "total": 11},
        "capture_tool_architecture_hard_gate":
            "FAIL_NOT_RUN_AFTER_PRIOR_HARD_GATE",
        "first_record_asynchronous_persistence_offline": "PASS",
        "raw_payload_control_ipc": False,
        "parent_owned_mmio_design": True,
        "parent_owned_quiescence_design": True,
        "credential_helper": str(helper_path),
        "credential_helper_sha256": helper_hash,
        "credential_helper_hard_gate":
            "FAIL_NOT_RUN_AFTER_PRIOR_HARD_GATE",
        "helper_identity_only_delta_verified": True,
        "credential_remnants": 0,
        "dut_connections": 0,
        "all_connections_local_helper": "NOT_REACHED",
        "owner_r3r4r1_authorization": "GRANTED",
        "dut_exclusivity": "NOT_REACHED",
        "parallel_hdmi_activity": "UNRESOLVED",
        "hardware_accessed": False,
        "current_boot_id": None,
        "recovery_path": "NOT_REACHED",
        "fpga_sram_programming": 0,
        "warm_reboots": 0,
        "power_cycles": 0,
        "flash_programming": 0,
        "driver_load_attempts": 0,
        "driver_module_loaded": "NOT_RUN",
        "endpoint_automatically_bound": "NOT_RUN",
        "unintended_endpoints_bound": 0,
        "node_to_bdf_mapping": "NOT_REACHED",
        "dual_layer_identity": "NOT_REACHED",
        "nvp_initialization": "NOT_REACHED",
        "fixed_live_source": "NOT_REACHED",
        "combined_t34_sessions": 0,
        "reset_stream_state_writes": 0,
        "snapshot_writes": 0,
        "error_status_w1c_writes": 0,
        "stream_enable_writes": 0,
        "normal_stream_disable_writes": 0,
        "safety_disable_writes": 0,
        "statistics_clear_writes": 0,
        "unauthorized_mmio_writes": 0,
        "persistent_first_record_hardware": "NOT_REACHED",
        "finite_capture": "NOT_REACHED",
        "primary_records_requested": 2500,
        "primary_records_received": None,
        "drain_records": None,
        "incomplete_trailing_bytes": None,
        "counter_reconciliation": "NOT_REACHED",
        "frame_reconstruction": "NOT_REACHED",
        "pcie_aer_kernel_health": "NOT_REACHED",
        "cleanup": "NOT_REQUIRED_NO_HARDWARE_ACCESS",
        "candidate_module_unloaded_end": "NOT_LOADED",
        "endpoint_automatically_unbound_end": "NOT_BOUND",
        "xdma_nodes_removed_end": "NOT_CREATED",
        "persistent_filesystem_state_modified": False,
        "candidate_left_in_volatile_sram": "UNRESOLVED",
        "raw_records_published": False,
        "raw_frame_published": False,
        "viewable_camera_image_published": False,
        "continuous_60_second_capture": "NOT_RUN",
        "throughput_288_MBps": "NOT_PROVEN",
        "four_input": "NOT_QUALIFIED",
        "two_channel": "NOT_QUALIFIED",
        "synthetic_generator": "NOT_TESTED",
        "v4l2": "NOT_TESTED",
        "full_g2b_hw": "NOT_YET_PROVEN",
        "ssot_update_required": False,
        "recommended_next_step":
            "One fresh corrective run may correct only the "
            "PARENT_QUIESCENCE_HANDSHAKE_PASS expected timeline, then must "
            "require 11/11 before any DUT connection.",
        "final_execution_point":
            "HARD STOP AFTER G2B-HW0-PRODUCT-R3R4R1 FINITE-FRAME "
            "QUALIFICATION",
    }

    write_text(
        STAGE / "V41_G2B_HW0_PRODUCT_R3R4R1_MAIN_REPORT.md",
        f"""# AHD v41 G2B-HW0-PRODUCT-R3R4R1

## Outcome

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `{BLOCKER}`
- Failed case: `{FAILED_CASE}`
- Hardware accessed: `NO`

## Exact stopped gate

The fresh run removed the invalid `part_count > len(records)` assertion and
the corrected partial-read case passed all required semantic checks. Cases 1
through 4 passed. The suite then failed case 5 because the coded expected
quiet-window completions were
`[false,false,false,false,false,false,true]`, while the unchanged runtime
function produced `[false,false,false,false,false,true,true]`.

At t=2.8 seconds, 1.4 seconds had elapsed since the last data event at t=1.4,
so the frozen 1.0-second quiet-window function correctly reported completion.
The test expectation at that position was invalid. Per the directive, the
self-test and capture tool were not patched after this failure, the suite was
not rerun, and no DUT connection occurred.

## Preserved boundaries

PROJECT_STATE_REV remained 8. R3R3 commit `{R3R3_COMMIT}` (98 manifest
entries) and failed R3R4 commit `{R3R4_COMMIT}` (40 entries) verified
byte-for-byte. The PRODUCT source, bitstream, DCP, driver authority, and ABI
matched their frozen identities. The immutable before/after snapshot covered
20 roots and 8,680 files with zero new, removed, or changed protected files.

No controller/Linux lock, SSH connection, JTAG, PCIe inventory, driver load,
bind, MMIO, DMA, stream operation, FPGA programming, reboot, power-cycle,
Flash operation, NVP access, or camera operation occurred. No raw camera or
synthetic raw-record files are published.

## Exact corrective action

Use a new governed run root. Correct only the case-5 expected quiet-window
timeline so it agrees with the frozen function, then require all 11/11 cases
before any DUT connection. Do not reinterpret this result as hardware proof.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_AUTHORIZATION_RECEIPT.md",
        f"""# R3R4R1 authorization receipt

Owner authorization: `GRANTED`. The fresh offline root, commit-pinned tool
recovery, authorized self-test correction, deterministic diagnostic analysis,
and evidence publication were within scope.

The ordered hard stop occurred at `{BLOCKER}` before the architecture,
credential-helper, exclusivity, continuity, driver, MMIO, DMA, and cleanup
gates. All conditional hardware permissions remained unused: SRAM programming
`0/1`, warm reboot `0/1`, driver load `0/1`, combined sessions `0/1`.
Flash programming and power-cycle remained `NO`.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_AUTHORITY_VERIFICATION.md",
        f"""# R3R4R1 authority verification

Result: `PASS` for the offline authority boundary.

- PROJECT_STATE_REV: `8`; META-8A remains authoritative; controlled
  hardware testing is authorized; G2B-HW remains `NOT_PROVEN`.
- Local and remote evidence `main` before publication:
  `{R3R4_COMMIT}`.
- R3R3: `VERIFIED` at `{R3R3_COMMIT}`; 98/98 manifest entries and required
  facts verified.
- Failed R3R4: `VERIFIED` at `{R3R4_COMMIT}`; 40/40 manifest entries,
  exact assertion blocker, zero DUT connections, and zero hardware operations
  verified.
- PRODUCT source: `integration/v41-g2b-onech-c2h` /
  `{SOURCE_COMMIT}` / `{SOURCE_TREE}`; clean and remote-matching.
- PRODUCT bitstream SHA-256: `{BIT_SHA}`.
- Signed-off DCP SHA-256: `{DCP_SHA}`.
- Driver authority commit: `{DRV_COMMIT}`; sealed controller SHA-256:
  `{DRIVER_SHA}`.
- Frozen ABI SHA-256: `{ABI_SHA}`.

Current DUT continuity was not checked after the offline hard stop.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_BOUNDARY_RECEIPT.md",
        f"""# R3R4R1 boundary receipt

- Fresh run root: `{ROOT}`
- Snapshot roots: `20`
- Snapshot files: `8680`
- Prior immutable artifact new writes: `0`
- Protected files removed: `0`
- Protected files changed: `0`
- PRODUCT source HEAD/tree/status unchanged: `PASS`
- project-current-state changes: `0`
- Prior R3R4 root executed or modified: `NO`
- Pre-existing `.diag0-work/` and `.meta8a-work/`: `PRESERVED`

All R3R4R1 writes stayed inside the fresh root until creation of this new
evidence directory.
""",
    )

    for filename in (
        "G2B_HW0_PRODUCT_R3R4R1_TOOL_BASELINE_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.md",
    ):
        shutil.copyfile(ROOT / "artifacts" / filename, STAGE / filename)
    shutil.copyfile(
        ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.patch",
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.patch",
    )

    write_json(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_SELFTEST.json",
        selftest_public,
    )
    case_lines = "\n".join(
        f"| `{name}` | `{value}` |"
        for name, value in analysis["cases"].items()
    )
    semantic_lines = "\n".join(
        f"| `{name}` | `{'PASS' if value else 'FAIL'}` |"
        for name, value in analysis["partial_read_semantic_checks"].items()
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_SELFTEST.md",
        f"""# R3R4R1 capture-tool offline self-test

- Result: `FAIL / BLOCKED`
- Completed PASS cases: `4/11`
- Failed case: `{FAILED_CASE}`
- First blocker: `{BLOCKER}`
- Governed rerun: `NO`
- Capture tool or self-test modified after failure: `NO`
- Hardware access: `NO`
- DUT connections: `0`

| Case | Result |
|---|---|
{case_lines}

## Corrected partial-read criterion

The invalid chunk-call-count assertion is absent and was not replaced by any
chunk-call versus record-count comparison.

| Semantic check | Result |
|---|---|
{semantic_lines}

## New exact failure

The actual completion vector was
`[false,false,false,false,false,true,true]`; the test expected
`[false,false,false,false,false,false,true]`. The mismatch occurs at t=2.8
seconds, already 1.4 seconds after the last data event. This is an offline test
expectation defect, not a hardware result.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_AUDIT.md",
        f"""# R3R4R1 capture-tool architecture audit

Ordered architecture hard gate: `FAIL (NOT RUN AFTER PRIOR HARD GATE)`.

The pre-suite delta audit verified that the capture and frame runtime normalize
exactly to R3R4 identity-only changes; the ABI files are byte-exact; parent-only
MMIO, no raw record IPC, direct private persistence, asynchronous first-record
persistence, primary target 2500, bounded drain, parent-owned quiescence,
cooperative quiet-window exit, failure persistence, and timeouts are unchanged.

The full architecture audit was not advanced because the mandatory self-test
suite stopped at `{FAILED_CASE}`. This conservative FAIL is a gate result,
not an adverse runtime-architecture finding.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_CREDENTIAL_HELPER_AUDIT.md",
        f"""# R3R4R1 credential-helper audit

Ordered credential-helper hard gate: `FAIL (NOT REACHED)`.

- Fresh helper: `Invoke-R3R4R1DutConnection.ps1`
- SHA-256: `{helper_hash}`
- Delta from published R3R4 helper: `IDENTITY_ONLY / PASS`
- Exact IP and pinned host key preserved: `YES`
- Plain credential process argument introduced: `NO`
- ACL-restricted temporary file and finally deletion preserved: `YES`
- Helper invocations: `0`
- Credential remnants: `0`

The separate ordered syntax/static hard gate was not advanced after the earlier
self-test failure. No DUT connection occurred.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_DUT_LOCK_RECEIPT.md",
        not_reached(
            "R3R4R1 DUT lock receipt",
            "Controller lock acquired: `NO`. Linux lock acquired: `NO`.",
        ),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_PRELOAD_INVENTORY.md",
        not_reached("R3R4R1 preload inventory"),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_RECOVERY_PATH_RECEIPT.md",
        not_reached(
            "R3R4R1 recovery path receipt",
            "Recovery path: `NOT_REACHED`. SRAM programs: `0/1`. "
            "Warm reboots: `0/1`.",
        ),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_DRIVER_VERIFICATION.md",
        f"""# R3R4R1 driver verification

Offline authority verification: `PASS`.

- Driver evidence commit: `{DRV_COMMIT}`
- Internal module name: `xdma_ahd_pcie`
- Required PCI identity: `10ee:7011 / 10ee:0007`
- Required DUT path:
  `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`
- Sealed controller-copy SHA-256: `{DRIVER_SHA}`

The DUT copy was not connected to or rehashed. Load attempts: `0`.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_DRIVER_LOAD_PROBE.md",
        not_reached(
            "R3R4R1 driver load and automatic probe",
            "Driver load attempts: `0`. Manual bind/unbind: `NO`.",
        ),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_NODE_TO_BDF_PROOF.md",
        not_reached("R3R4R1 node-to-BDF proof"),
    )
    write_csv(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_NODE_MAP.csv",
        ["Result", "Node", "BDF", "Reason"],
        [{"Result": "NOT_REACHED", "Node": "N/A", "BDF": "N/A",
          "Reason": BLOCKER}],
    )
    write_csv(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_MMIO_RAW.csv",
        ["Timestamp", "Session", "UserNode", "BDF", "Offset", "Operation",
         "Value", "Result"],
        [{"Timestamp": "N/A", "Session": "N/A", "UserNode": "N/A",
          "BDF": "N/A", "Offset": "N/A", "Operation": "NONE",
          "Value": "N/A", "Result": "NOT_REACHED"}],
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_MMIO_DECODED.md",
        not_reached(
            "R3R4R1 MMIO decoded evidence",
            "MMIO reads: `0`. MMIO writes: `0`.",
        ),
    )
    write_csv(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_MMIO_WRITE_LEDGER.csv",
        ["Timestamp", "Session", "UserNode", "BDF", "Offset", "Operation",
         "Value", "Purpose", "Authorized", "Precondition", "Result"],
        [{"Timestamp": "N/A", "Session": "N/A", "UserNode": "N/A",
          "BDF": "N/A", "Offset": "N/A", "Operation": "NONE",
          "Value": "N/A", "Purpose": "NONE", "Authorized": "N/A",
          "Precondition": "OFFLINE_HARD_GATE_FAILED",
          "Result": "NOT_REACHED"}],
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_SESSION_START_RECEIPT.md",
        not_reached(
            "R3R4R1 combined T3/T4 session start",
            "Combined sessions: `0`.",
        ),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_FIRST_RECORD_REPORT.md",
        not_reached(
            "R3R4R1 persistent first-record hardware report",
            "The offline synthetic first-record case passed, including fsync "
            "and ABI validation. It is not a hardware result. No raw bytes "
            "are published.",
        ),
    )
    write_csv(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_FIRST_RECORD_HEADER.csv",
        ["Result", "Field", "Value", "Reason"],
        [{"Result": "NOT_REACHED", "Field": "N/A", "Value": "N/A",
          "Reason": BLOCKER}],
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_RECORD_VALIDATION_SUMMARY.md",
        not_reached("R3R4R1 hardware record validation summary"),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_FINITE_CAPTURE_REPORT.md",
        not_reached("R3R4R1 finite 2500-record hardware capture"),
    )
    write_csv(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_FINITE_CAPTURE_METRICS.csv",
        ["Metric", "Value", "Result"],
        [
            {"Metric": "primary_records_requested", "Value": "2500",
             "Result": "NOT_REACHED"},
            {"Metric": "primary_records_received", "Value": "N/A",
             "Result": "NOT_REACHED"},
            {"Metric": "primary_bytes", "Value": "N/A",
             "Result": "NOT_REACHED"},
            {"Metric": "drain_records", "Value": "N/A",
             "Result": "NOT_REACHED"},
            {"Metric": "drain_bytes", "Value": "N/A",
             "Result": "NOT_REACHED"},
            {"Metric": "incomplete_trailing_bytes", "Value": "N/A",
             "Result": "NOT_REACHED"},
        ],
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_COUNTER_RECONCILIATION.md",
        not_reached("R3R4R1 hardware counter reconciliation"),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_FRAME_RECONSTRUCTION_REPORT.md",
        not_reached("R3R4R1 complete real-frame reconstruction"),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_PCIE_AER_KERNEL_REVIEW.md",
        not_reached("R3R4R1 PCIe, AER, driver, and kernel review"),
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_CLEANUP_RECEIPT.md",
        """# R3R4R1 cleanup receipt

Result: `NOT_REQUIRED_NO_HARDWARE_ACCESS`.

The run stopped before any lock or DUT connection. Task-loaded modules: `0`;
task-created nodes: `0`; stream enables: `0`; task-owned XDMA descriptors:
`0`. No hardware rollback or unload was required.
""",
    )
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_FINAL_HARDWARE_STATE.md",
        """# R3R4R1 final hardware state

Hardware accessed: `NO`. Boot ID, FPGA DONE, PCIe link, endpoint state,
driver state, DMA state, and kernel taint are `NOT_REACHED` and are not
inferred from R3R3. FPGA programming, reboot, power-cycle, Flash programming,
driver load, MMIO, DMA, and capture counts are all zero.

Candidate left in volatile SRAM: `UNRESOLVED` because no current DUT
observation occurred.
""",
    )
    write_csv(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_GATE_MATRIX.csv",
        ["Gate", "Result", "Blocker_or_basis"],
        [
            {"Gate": "Project and predecessor authority", "Result": "PASS",
             "Blocker_or_basis": "REV8_R3R3_R3R4_VERIFIED"},
            {"Gate": "Tool baseline", "Result": "PASS",
             "Blocker_or_basis": "COMMIT_PINNED_R3R4"},
            {"Gate": "Authorized tool delta", "Result": "PASS",
             "Blocker_or_basis": "SELFTEST_PLUS_RUN_IDENTITY"},
            {"Gate": "Partial-read semantic checks", "Result": "PASS",
             "Blocker_or_basis": "ALL_13_REQUIRED_PROPERTIES"},
            {"Gate": "Offline self-test suite", "Result": "FAIL_4_OF_11",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Architecture hard gate", "Result": "FAIL_NOT_RUN",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Credential-helper hard gate", "Result": "FAIL_NOT_REACHED",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "DUT exclusivity and continuity", "Result": "NOT_REACHED",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Driver, bind, and node-to-BDF", "Result": "NOT_REACHED",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Runtime identity and source", "Result": "NOT_REACHED",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Persistent first record", "Result": "NOT_REACHED",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Finite capture and real frame", "Result": "NOT_REACHED",
             "Blocker_or_basis": BLOCKER},
            {"Gate": "Cleanup", "Result": "NOT_REQUIRED",
             "Blocker_or_basis": "NO_HARDWARE_ACCESS"},
            {"Gate": "Engineering", "Result": "BLOCKED",
             "Blocker_or_basis": BLOCKER},
        ],
    )
    write_json(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_STATE.json",
        state,
    )

    raw_copies = {
        ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE.json":
            "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE.json",
        ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE_ANALYSIS.json":
            "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_FAILURE_ANALYSIS.json",
        ROOT / "artifacts/predecessor-manifest-verification.json":
            "G2B_HW0_PRODUCT_R3R4R1_PREDECESSOR_MANIFEST_VERIFICATION.json",
        ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.json":
            "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.json",
        ROOT / "artifacts/run-identity-update.json":
            "G2B_HW0_PRODUCT_R3R4R1_RUN_IDENTITY_UPDATE.json",
    }
    for source, name in raw_copies.items():
        shutil.copyfile(source, STAGE / "raw" / name)
    write_json(
        STAGE / "raw/G2B_HW0_PRODUCT_R3R4R1_AUTHORITY.json",
        authority,
    )
    write_json(
        STAGE / "raw/G2B_HW0_PRODUCT_R3R4R1_BOUNDARY.json",
        boundary,
    )

    tool_names = (
        "capture_r3r4.py",
        "capture_r3r4_selftest.py",
        "frame_reconstruct_r3r4.py",
        "abi_v1.py",
        "V41_C2H_TRANSPORT_ABI_V1.json",
        "Invoke-R3R4R1DutConnection.ps1",
        "Collect-ImmutableBoundary.ps1",
        "Verify-PredecessorManifests.ps1",
        "audit_tool_delta_r3r4r1.py",
        "analyze_failed_selftest_r3r4r1.py",
        "build_blocked_evidence_r3r4r1.py",
    )
    for name in tool_names:
        shutil.copyfile(ROOT / "scripts" / name, STAGE / "tools" / name)

    required = {
        "V41_G2B_HW0_PRODUCT_R3R4R1_MAIN_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R1_AUTHORIZATION_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_AUTHORITY_VERIFICATION.md",
        "G2B_HW0_PRODUCT_R3R4R1_BOUNDARY_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_TOOL_BASELINE_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_TOOL_DIFF.md",
        "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_SELFTEST.md",
        "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_SELFTEST.json",
        "G2B_HW0_PRODUCT_R3R4R1_CAPTURE_TOOL_AUDIT.md",
        "G2B_HW0_PRODUCT_R3R4R1_CREDENTIAL_HELPER_AUDIT.md",
        "G2B_HW0_PRODUCT_R3R4R1_DUT_LOCK_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_PRELOAD_INVENTORY.md",
        "G2B_HW0_PRODUCT_R3R4R1_RECOVERY_PATH_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_DRIVER_VERIFICATION.md",
        "G2B_HW0_PRODUCT_R3R4R1_DRIVER_LOAD_PROBE.md",
        "G2B_HW0_PRODUCT_R3R4R1_NODE_TO_BDF_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R1_NODE_MAP.csv",
        "G2B_HW0_PRODUCT_R3R4R1_MMIO_RAW.csv",
        "G2B_HW0_PRODUCT_R3R4R1_MMIO_DECODED.md",
        "G2B_HW0_PRODUCT_R3R4R1_MMIO_WRITE_LEDGER.csv",
        "G2B_HW0_PRODUCT_R3R4R1_SESSION_START_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_FIRST_RECORD_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R1_FIRST_RECORD_HEADER.csv",
        "G2B_HW0_PRODUCT_R3R4R1_RECORD_VALIDATION_SUMMARY.md",
        "G2B_HW0_PRODUCT_R3R4R1_FINITE_CAPTURE_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R1_FINITE_CAPTURE_METRICS.csv",
        "G2B_HW0_PRODUCT_R3R4R1_COUNTER_RECONCILIATION.md",
        "G2B_HW0_PRODUCT_R3R4R1_FRAME_RECONSTRUCTION_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R1_PCIE_AER_KERNEL_REVIEW.md",
        "G2B_HW0_PRODUCT_R3R4R1_CLEANUP_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R1_FINAL_HARDWARE_STATE.md",
        "G2B_HW0_PRODUCT_R3R4R1_GATE_MATRIX.csv",
        "G2B_HW0_PRODUCT_R3R4R1_STATE.json",
    }
    missing = sorted(name for name in required if not (STAGE / name).is_file())
    require(not missing, "REQUIRED_PUBLIC_FILES_MISSING:" + ",".join(missing))

    names_before_index = sorted(
        str(path.relative_to(STAGE)).replace("\\", "/")
        for path in STAGE.rglob("*") if path.is_file()
    )
    index_names = sorted(set(
        names_before_index
        + [
            "G2B_HW0_PRODUCT_R3R4R1_EVIDENCE_INDEX.md",
            "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt",
        ]
    ))
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_EVIDENCE_INDEX.md",
        "# R3R4R1 evidence index\n\n"
        + "\n".join(f"- `{name}`" for name in index_names)
        + "\n\nRaw camera records, raw frame, and viewable camera image "
          "published: `0`.",
    )
    manifest_lines = []
    for path in sorted(
        item for item in STAGE.rglob("*")
        if item.is_file()
        and item.name != "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt"
    ):
        relative = str(path.relative_to(STAGE)).replace("\\", "/")
        manifest_lines.append(f"{sha(path)}  {relative}")
    write_text(
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt",
        "\n".join(manifest_lines),
    )
    for line in (
        STAGE / "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt"
    ).read_text("utf-8").splitlines():
        expected, relative = line.split("  ", 1)
        require(
            sha(STAGE / relative) == expected,
            "LOCAL_MANIFEST_READBACK_FAILED:" + relative,
        )

    prohibited_suffixes = {".ko", ".bit", ".dcp", ".uyvy", ".png", ".bin"}
    prohibited = [
        str(path.relative_to(STAGE))
        for path in STAGE.rglob("*")
        if path.is_file() and path.suffix.lower() in prohibited_suffixes
    ]
    require(not prohibited, "PROHIBITED_BINARY_PUBLISHED:" + ",".join(prohibited))
    credential_source = Path(r"C:\FPGA\VCDE-DUT-1.txt")
    credential_bytes = credential_source.read_bytes()
    credential_text = credential_bytes.decode("utf-8", errors="ignore")
    secret_values = []
    secret_lines = []
    for line in credential_text.splitlines():
        if re.search(r"(?i)(password|haslo)\s*[:=]", line):
            secret_values.append(re.split(r"[:=]", line, maxsplit=1)[1].strip())
            secret_lines.append(line.strip().encode("utf-8"))
    public_login = b"vcdeagent1"
    for path in STAGE.rglob("*"):
        if not path.is_file():
            continue
        data = path.read_bytes()
        require(credential_bytes not in data, "CREDENTIAL_FILE_CONTENT_PUBLISHED")
        for secret_line in secret_lines:
            require(
                not secret_line or secret_line not in data,
                "CREDENTIAL_LINE_PUBLISHED",
            )
        for secret in secret_values:
            encoded = secret.encode("utf-8")
            if not encoded:
                continue
            if encoded == public_login:
                continue
            else:
                require(encoded not in data, "CREDENTIAL_VALUE_PUBLISHED")

    receipt = {
        "result": "PASS",
        "stage": str(STAGE),
        "files": len([path for path in STAGE.rglob("*") if path.is_file()]),
        "manifest_entries": len(manifest_lines),
        "required_files_present": len(required),
        "prohibited_binary_files": 0,
        "raw_camera_payload_files": 0,
        "credential_findings": 0,
        "engineering_gate": "BLOCKED",
        "first_blocker": BLOCKER,
    }
    write_json(ROOT / "logs/public-stage-seal.json", receipt)
    print(json.dumps(receipt, indent=2))
    return receipt


if __name__ == "__main__":
    build()
