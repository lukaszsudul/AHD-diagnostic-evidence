#!/usr/bin/env python3
"""Build the sanitized, fail-closed R3R4R3 blocked evidence package."""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


RUN = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R3_20260907T075856Z")
REPO = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
SOURCE = Path(r"C:\FPGA\V41_G2B")
RECOVERY = Path(r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316")
EVIDENCE_NAME = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r3-finite-frame"
)
OUT = RUN / "evidence-staging" / EVIDENCE_NAME
TASK = "G2B-HW0-PRODUCT-R3R4R3"
BLOCKER = "R3R4R3_CAPTURE_TOOL_SELFTEST_FAILED:FIRST_RECORD_PERSISTENCE_PASS"
PRODUCT_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
DCP_SHA = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"
ABI_SHA = "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6"
DRIVER_SHA = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"
SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
PREDECESSORS = (
    ("r3r3", "6cff7ad374575df84bc7d8794565dbd7d9cd869f",
     "v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record",
     "G2B_HW0_PRODUCT_R3R3_SHA256_MANIFEST.txt"),
    ("r3r4", "2bfcba2476a31a06bdf940881cd5d0a20614333e",
     "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4-finite-frame",
     "G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt"),
    ("r3r4r1", "9c1ff0473ca336e75c29a19208be17b407d8bf37",
     "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame",
     "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt"),
    ("r3r4r2", "3749e2eb484eb1ccff2b7c4ed86598d8f4cfbb81",
     "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r2-finite-frame",
     "G2B_HW0_PRODUCT_R3R4R2_SHA256_MANIFEST.txt"),
)
EXISTING_CASES = (
    "FIRST_RECORD_PERSISTENCE_PASS", "PARTIAL_READ_ASSEMBLY_PASS",
    "PRIMARY_2500_BOUNDARY_PASS", "DRAIN_CAPTURE_PASS",
    "PARENT_QUIESCENCE_HANDSHAKE_PASS", "FAILURE_PRESERVES_RAW_DATA_PASS",
    "EXCEPTION_DETAIL_PASS", "COMPLETE_FRAME_RECONSTRUCTION_PASS",
    "EXACT_CAPTURE_HASH_PASS", "NO_BLANK_BLOCKER_PASS",
    "NO_RAW_RECORD_IPC_PASS",
)
NEW_CASES = (
    "PERSISTED_FIRST_RECORD_REREAD_PROOF_PASS",
    "PRIMARY_PERIODIC_FSYNC_PASS",
    "FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET_PASS",
    "PARENT_MULTI_SAMPLE_QUIESCENCE_PASS",
    "SINGLE_COMBINED_SESSION_NORMALIZATION_W1C_PASS",
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def git(cwd: Path, *args: str) -> str:
    proc = subprocess.run(
        ["git", "-C", str(cwd), *args], check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    return proc.stdout.strip()


def verify_manifest(root: Path, name: str) -> tuple[int, list[dict]]:
    failures = []
    count = 0
    prefix = root.resolve()
    for line in (root / name).read_text(encoding="utf-8-sig").splitlines():
        if not line.strip():
            continue
        parts = line.split("  ", 1)
        if len(parts) != 2 or len(parts[0]) != 64:
            failures.append({"line": line, "reason": "MALFORMED"})
            continue
        count += 1
        candidate = (root / parts[1].replace("/", "\\")).resolve()
        try:
            candidate.relative_to(prefix)
        except ValueError:
            failures.append({"path": parts[1], "reason": "PATH_ESCAPE"})
            continue
        if not candidate.is_file():
            failures.append({"path": parts[1], "reason": "MISSING"})
        elif sha(candidate) != parts[0].upper():
            failures.append({"path": parts[1], "reason": "HASH_MISMATCH"})
    return count, failures


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def write_json(path: Path, value) -> None:
    write(path, json.dumps(value, indent=2) + "\n")


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def report(title: str, rows: list[tuple[str, str]], note: str = "") -> str:
    lines = [f"# {title}", "", "| Field | Result |", "|---|---|"]
    lines.extend(f"| {key} | `{value}` |" for key, value in rows)
    if note:
        lines.extend(["", note])
    return "\n".join(lines) + "\n"


def main() -> int:
    if OUT.exists():
        raise RuntimeError(f"EVIDENCE_STAGING_ALREADY_EXISTS:{OUT}")
    OUT.mkdir(parents=True)
    (OUT / "tools").mkdir()
    (OUT / "raw").mkdir()

    project_root = REPO / "project-current-state"
    project_count, project_failures = verify_manifest(
        project_root, "SHA256_MANIFEST.txt")
    project = json.loads((project_root / "PROJECT_STATE.json").read_text(
        encoding="utf-8"))
    predecessor_rows = {}
    for key, commit, directory, manifest in PREDECESSORS:
        root = REPO / directory
        count, failures = verify_manifest(root, manifest)
        tree_commit = git(REPO, "rev-parse", f"{commit}:{directory}")
        tree_head = git(REPO, "rev-parse", f"HEAD:{directory}")
        predecessor_rows[key] = {
            "commit": commit, "directory": directory,
            "tree_at_commit": tree_commit, "tree_at_head": tree_head,
            "tree_unchanged": tree_commit == tree_head,
            "manifest_entries": count, "manifest_failures": failures,
            "result": "PASS" if not failures and tree_commit == tree_head else "FAIL",
        }
    r3r4r2_state = json.loads((
        REPO / PREDECESSORS[-1][2] / "G2B_HW0_PRODUCT_R3R4R2_STATE.json"
    ).read_text(encoding="utf-8"))
    r3r4r2_authority = json.loads((
        REPO / PREDECESSORS[-1][2] / "raw" /
        "G2B_HW0_PRODUCT_R3R4R2_AUTHORITY.json"
    ).read_text(encoding="utf-8"))
    source_status = git(SOURCE, "status", "--porcelain=v2", "--untracked-files=all")
    remote_source = git(SOURCE, "ls-remote", "origin",
                        "refs/heads/integration/v41-g2b-onech-c2h").split()[0]
    authority_checks = {
        "PROJECT_STATE_MANIFEST": not project_failures,
        "PROJECT_STATE_REV_8": project.get("project_state_revision") == 8,
        "META8A_PROMOTED": project.get("current_meta_task", "META-8A") == "META-8A" or
            "META-8A" in (project_root / "README.md").read_text(encoding="utf-8"),
        "G2B_HW_NOT_QUALIFIED": "NOT_PROVEN" in json.dumps(
            project.get("g2b_hardware", {})),
        "ALL_PREDECESSORS": all(
            row["result"] == "PASS" for row in predecessor_rows.values()),
        "R3R4R2_EXPECTED_BLOCKER":
            r3r4r2_state.get("first_blocker") ==
            "R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_FAILED:"
            "PERSISTED_FIRST_RECORD_REREAD_HASH_PROOF_ABSENT",
        "R3R4R2_NO_HARDWARE":
            r3r4r2_state.get("hardware_accessed") is False and
            r3r4r2_state.get("dut_connections") == 0 and
            r3r4r2_state.get("driver_load_attempts") == 0,
        "PRODUCT_SOURCE_BRANCH":
            git(SOURCE, "branch", "--show-current") ==
            "integration/v41-g2b-onech-c2h",
        "PRODUCT_SOURCE_COMMIT": git(SOURCE, "rev-parse", "HEAD") == SOURCE_COMMIT,
        "PRODUCT_SOURCE_TREE":
            git(SOURCE, "rev-parse", "HEAD^{tree}") == SOURCE_TREE,
        "PRODUCT_SOURCE_CLEAN": not source_status,
        "PRODUCT_SOURCE_REMOTE": remote_source == SOURCE_COMMIT,
        "PRODUCT_BITSTREAM_SHA256":
            sha(RECOVERY / "G2B_PRODUCT_RECOVERY4.bit") == PRODUCT_SHA,
        "SIGNED_DCP_SHA256":
            sha(RECOVERY / "G2B_PRODUCT_SIGNED_OFF.dcp") == DCP_SHA,
        "FROZEN_ABI_SHA256":
            sha(RUN / "scripts" / "V41_C2H_TRANSPORT_ABI_V1.json") == ABI_SHA,
        "DRIVER_AUTHORITY_PRESERVED":
            r3r4r2_authority.get("driver_sha256") == DRIVER_SHA,
    }
    if not all(authority_checks.values()):
        raise RuntimeError("R3R4R3_PREDECESSOR_AUTHORITY_FAILURE:" +
                           json.dumps(authority_checks, sort_keys=True))
    authority = {
        "schema": "R3R4R3_AUTHORITY_VERIFICATION_V1",
        "result": "PASS", "project_state_rev": 8,
        "project_state_manifest_entries": project_count,
        "project_state_manifest_failures": project_failures,
        "checks": authority_checks, "predecessors": predecessor_rows,
        "source_branch": "integration/v41-g2b-onech-c2h",
        "source_commit": SOURCE_COMMIT, "source_tree": SOURCE_TREE,
        "bitstream_sha256": PRODUCT_SHA, "dcp_sha256": DCP_SHA,
        "abi_sha256": ABI_SHA, "driver_sha256": DRIVER_SHA,
    }

    boundary = json.loads((
        RUN / "artifacts" / "protected-after.comparison.json"
    ).read_text(encoding="utf-8"))
    if boundary.get("result") != "PASS":
        raise RuntimeError("R3R4R3_IMMUTABLE_BOUNDARY_FAILED")
    failure = json.loads((RUN / "artifacts" /
                          "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_FAILURE.json").read_text(
                              encoding="utf-8"))
    analysis = json.loads((RUN / "artifacts" /
                           "G2B_HW0_PRODUCT_R3R4R3_SELFTEST_FAILURE_ANALYSIS.json").read_text(
                               encoding="utf-8"))
    delta = json.loads((RUN / "artifacts" /
                        "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.json").read_text(
                            encoding="utf-8"))
    synthetic_state = json.loads((RUN / "artifacts" / "offline-selftest" /
                                  "successful-capture" /
                                  "T3T4-reader-result.json").read_text(
                                      encoding="utf-8"))
    synthetic_first = json.loads((RUN / "artifacts" / "offline-selftest" /
                                  "successful-capture" /
                                  "G2B_HW0_PRODUCT_R3R4R3_PERSISTED_FIRST_RECORD_RECEIPT.json"
                                  ).read_text(encoding="utf-8"))
    checkpoint_rows = [json.loads(line) for line in (
        RUN / "artifacts" / "offline-selftest" / "successful-capture" /
        "G2B_HW0_PRODUCT_R3R4R3_PRIMARY_DURABILITY_CHECKPOINTS.jsonl"
    ).read_text(encoding="utf-8").splitlines() if line.strip()]
    helper = RUN / "scripts" / "Invoke-R3R4R3DutConnection.ps1"
    credential_remnants = list(RUN.rglob("*.credential.tmp"))

    selftest_cases = {name: ("FAIL" if name == EXISTING_CASES[0]
                             else "NOT_REACHED") for name in EXISTING_CASES}
    selftest_cases.update({name: "NOT_REACHED" for name in NEW_CASES})
    selftest_public = {
        "schema": "R3R4R3_CAPTURE_TOOL_SELFTEST_RESULT_V1",
        "task": TASK, "result": "BLOCKED", "blocker": BLOCKER,
        "passed": 0, "total": 16, "existing_passed": 0,
        "existing_total": 11, "new_passed": 0, "new_total": 5,
        "failed_case": "FIRST_RECORD_PERSISTENCE_PASS",
        "cases": selftest_cases,
        "failed_assertion": analysis["failed_assertion"],
        "expected_relation": analysis["expected_relation"],
        "actual_relation": analysis["actual_relation_inferred"],
        "numeric_timestamp_values": analysis["numeric_timestamp_values"],
        "monotonic_clock_resolution_seconds":
            analysis["monotonic_clock_resolution_seconds"],
        "runtime_program_order_proven": analysis["runtime_program_order_proven"],
        "runtime_modified_after_suite": False, "suite_rerun": False,
        "hardware_access": False, "dut_connections": 0,
        "synthetic_setup_before_assertion": {
            "primary_records": synthetic_state["primary_records"],
            "primary_bytes": synthetic_state["primary_bytes"],
            "drain_records": synthetic_state["drain_records"],
            "trailing_bytes": synthetic_state["incomplete_trailing_bytes"],
            "first_record_hash_source": synthetic_state["first_record_hash_source"],
            "first_payload_hash_source": synthetic_state["first_payload_hash_source"],
            "abi_parse_source": synthetic_state["abi_parse_source"],
            "checkpoint_passed": synthetic_state["checkpoint_passed"],
        },
    }

    state = {
        "task": TASK, "engineering_gate": "BLOCKED",
        "evidence_publication": "SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": "BLOCKED", "first_blocker": BLOCKER,
        "project_state_rev_at_start": 8, "project_state_rev_at_end": 8,
        "r3r3_evidence": "VERIFIED", "failed_r3r4_evidence": "VERIFIED",
        "failed_r3r4r1_evidence": "VERIFIED",
        "failed_r3r4r2_evidence": "VERIFIED", "run_root": str(RUN),
        "prior_immutable_artifact_new_writes": 0,
        "tool_baseline": "VERIFIED",
        "authorized_tool_delta":
            "FIVE_CAPTURE_CONTRACT_CLOSURES_PLUS_RUN_IDENTITY_ONLY",
        "existing_offline_selftests": {"passed": 0, "total": 11},
        "new_contract_selftests": {"passed": 0, "total": 5},
        "total_offline_selftests": {"passed": 0, "total": 16},
        "failed_selftest": "FIRST_RECORD_PERSISTENCE_PASS",
        "persisted_first_record_reread_proof": "NOT_RUN",
        "first_record_hash_source": "REREAD_PERSISTED_FILE",
        "first_payload_hash_source": "REREAD_PERSISTED_FILE",
        "abi_parse_source": "REREAD_PERSISTED_FIRST_RECORD",
        "primary_durability_checkpoints": "NOT_RUN",
        "first_record_durable_before_primary_target": "FAIL",
        "parent_multi_sample_quiescence_implementation": "NOT_RUN",
        "single_combined_normalization_w1c_implementation": "NOT_RUN",
        "capture_tool_architecture_hard_gate": "NOT_RUN",
        "raw_payload_control_ipc": False, "parent_owned_mmio": True,
        "parent_owned_quiescence": True, "runtime_quiet_window_changed": False,
        "quiet_window_expected_completions":
            [False, False, False, False, False, True, True],
        "credential_helper": str(helper), "credential_helper_sha256": sha(helper),
        "credential_helper_hard_gate": "NOT_RUN",
        "all_connections_used_r3r4r3_helper": "NOT_REACHED",
        "credential_remnants": len(credential_remnants),
        "owner_authorization": "GRANTED", "conditional_sram_maximum": 1,
        "conditional_sram_executed": 0, "conditional_reboot_maximum": 1,
        "conditional_reboot_executed": 0, "recovery_path": "NOT_REACHED",
        "hardware_accessed": False, "dut_connections": 0,
        "dut_exclusivity": "NOT_REACHED", "parallel_hdmi": "NOT_REACHED",
        "driver_load_attempts": 0, "combined_sessions": 0,
        "reset_stream_state_writes": 0, "normalization_w1c_writes": 0,
        "snapshot_writes": 0, "stream_enable_writes": 0,
        "normal_disable_writes": 0, "safety_disable_writes": 0,
        "statistics_clear_writes": 0, "unauthorized_mmio_writes": 0,
        "persistent_first_record_hardware": "NOT_REACHED",
        "finite_capture": "NOT_REACHED", "counter_reconciliation": "NOT_REACHED",
        "frame_reconstruction": "NOT_REACHED", "pcie_aer_kernel": "NOT_REACHED",
        "cleanup": "NOT_REQUIRED_NO_HARDWARE_ACCESS",
        "raw_records_published": False, "raw_frame_published": False,
        "viewable_camera_image_published": False,
        "continuous_60_second_capture": "NOT_RUN",
        "throughput_288_MBps": "NOT_PROVEN", "four_input": "NOT_QUALIFIED",
        "two_channel": "NOT_QUALIFIED", "synthetic_generator": "NOT_TESTED",
        "v4l2": "NOT_TESTED", "persistent_filesystem_state_modified": False,
        "flash_programming": 0, "power_cycles": 0,
        "full_g2b_hw": "NOT_YET_PROVEN", "ssot_update_required": False,
        "recommended_next_step": (
            "Authorize one fresh corrective run that tests the formal dependency "
            "using recorded event sequence/order rather than requiring distinct "
            "15.625-ms monotonic clock ticks; preserve the unchanged runtime."
        ),
        "final_execution_point":
            "HARD STOP AFTER G2B-HW0-PRODUCT-R3R4R3 FINITE-FRAME QUALIFICATION",
    }

    write_json(OUT / "raw" / "G2B_HW0_PRODUCT_R3R4R3_AUTHORITY.json", authority)
    write_json(OUT / "raw" / "G2B_HW0_PRODUCT_R3R4R3_BOUNDARY.json", boundary)
    write_json(OUT / "raw" /
               "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_SELFTEST_FAILURE.json", failure)
    write_json(OUT / "raw" /
               "G2B_HW0_PRODUCT_R3R4R3_SELFTEST_FAILURE_ANALYSIS.json", analysis)
    write_json(OUT / "raw" /
               "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.json", delta)

    shutil.copy2(RUN / "artifacts" /
                 "G2B_HW0_PRODUCT_R3R4R3_TOOL_BASELINE_RECEIPT.md",
                 OUT / "G2B_HW0_PRODUCT_R3R4R3_TOOL_BASELINE_RECEIPT.md")
    shutil.copy2(RUN / "artifacts" /
                 "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.md",
                 OUT / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.md")
    shutil.copy2(RUN / "artifacts" /
                 "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.patch",
                 OUT / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.patch")

    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_AUTHORIZATION_RECEIPT.md", report(
        f"{TASK} Authorization Receipt", [
            ("Owner authorization", "GRANTED"),
            ("Correction scope", "FIVE_CAPTURE_CONTRACT_CLOSURES"),
            ("Capture retries authorized", "0"),
            ("Conditional SRAM maximum", "1"),
            ("Conditional warm reboot maximum", "1"),
            ("60-second capture", "NOT_AUTHORIZED"),
            ("SSOT modification", "NOT_AUTHORIZED"),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_AUTHORITY_VERIFICATION.md", report(
        f"{TASK} Authority Verification", [
            ("Result", "PASS"), ("PROJECT_STATE_REV", "8"),
            ("R3R3 evidence", "VERIFIED"), ("R3R4 evidence", "VERIFIED"),
            ("R3R4R1 evidence", "VERIFIED"), ("R3R4R2 evidence", "VERIFIED"),
            ("PRODUCT source commit", SOURCE_COMMIT),
            ("PRODUCT source tree", SOURCE_TREE),
            ("PRODUCT bitstream SHA-256", PRODUCT_SHA),
            ("DCP SHA-256", DCP_SHA), ("ABI SHA-256", ABI_SHA),
            ("Driver SHA-256 authority", DRIVER_SHA),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_BOUNDARY_RECEIPT.md", report(
        f"{TASK} Immutable Boundary Receipt", [
            ("Result", "PASS"), ("Protected roots", "26"),
            ("Protected files", "9451"), ("New files", "0"),
            ("Removed files", "0"), ("Changed files", "0"),
            ("Prior immutable artifact new writes", "0"),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_PERSISTED_BYTES_PROOF.md", report(
        f"{TASK} Persisted-Bytes Proof", [
            ("Formal contract case", "NOT_RUN"),
            ("Reason", "CASE_1_HARD_STOP"),
            ("Synthetic setup record reread bytes", "4096"),
            ("Synthetic setup payload reread bytes", "3840"),
            ("Record hash source", synthetic_first["record_hash_source"]),
            ("Payload hash source", synthetic_first["payload_hash_source"]),
            ("ABI parse source", synthetic_first["abi_parse_source"]),
            ("Payload equals reread record slice", "YES"),
        ], "These are pre-assertion offline synthetic setup observations, not a formal case PASS and not hardware evidence."))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_PRIMARY_DURABILITY_REPORT.md", report(
        f"{TASK} Primary Durability Report", [
            ("Formal contract case", "NOT_RUN"),
            ("Synthetic checkpoint 1024", "OBSERVED_PASS"),
            ("Synthetic checkpoint 2048", "OBSERVED_PASS"),
            ("Synthetic checkpoint 2500", "OBSERVED_PASS"),
            ("Raw payload in checkpoint communication", "NO"),
        ], "The suite stopped in case 1 before PRIMARY_PERIODIC_FSYNC_PASS could be credited."))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_ORDERING_PROOF.md", report(
        f"{TASK} Ordering Proof", [
            ("Formal result", "FAIL"),
            ("Failed case", "FIRST_RECORD_PERSISTENCE_PASS"),
            ("Expected", "DURABLE_MONOTONIC_NS_LT_TARGET_MONOTONIC_NS"),
            ("Actual relation", analysis["actual_relation_inferred"]),
            ("Numeric event timestamps", "NOT_PERSISTED"),
            ("Clock implementation", analysis["monotonic_clock_implementation"]),
            ("Clock resolution", "15.625_ms"),
            ("Program-order dependency", "PROVEN"),
            ("Suite rerun", "NO"),
        ], "The strict distinct-tick assertion is not a valid proof requirement on this clock. No correction was made in this governed run."))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_QUIESCENCE_PROOF.md", report(
        f"{TASK} Quiescence Proof", [
            ("Source-delta presence", "PASS"),
            ("Formal contract case", "NOT_RUN"),
            ("Independent architecture gate", "NOT_RUN"),
            ("Hardware proof", "NOT_REACHED"),
            ("Required consecutive samples", "5"),
            ("Required span", ">=400_ms"),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_W1C_PROOF.md", report(
        f"{TASK} W1C Proof", [
            ("Source-delta presence", "PASS"),
            ("Formal contract case", "NOT_RUN"),
            ("Independent architecture gate", "NOT_RUN"),
            ("Hardware writes", "0"),
            ("Maximum combined normalization W1C", "1"),
            ("Split paths used", "NO"),
        ]))

    write_json(OUT / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_SELFTEST.json",
               selftest_public)
    selftest_rows = [(name, selftest_cases[name]) for name in
                     EXISTING_CASES + NEW_CASES]
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_SELFTEST.md", report(
        f"{TASK} Capture-Tool Self-Test", [
            ("Result", "BLOCKED"), ("Passed", "0/16"),
            ("Failed case", "FIRST_RECORD_PERSISTENCE_PASS"),
            ("First blocker", BLOCKER), ("Hardware access", "NO"),
            ("DUT connections", "0"), ("Suite rerun", "NO"),
        ] + selftest_rows, "The assertion required distinct monotonic ticks; ordered callbacks received the same 15.625-ms tick."))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_AUDIT.md", report(
        f"{TASK} Capture-Tool Architecture Audit", [
            ("Result", "NOT_RUN"), ("Reason", "OFFLINE_SELFTEST_HARD_STOP"),
            ("Required predecessor", "16_OF_16_PASS"),
            ("Observed predecessor", "0_OF_16_BLOCKED"),
            ("Hardware access", "NO"),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_CREDENTIAL_HELPER_AUDIT.md", report(
        f"{TASK} Credential Helper Audit", [
            ("Fresh helper", str(helper)), ("SHA-256", sha(helper)),
            ("Hard gate", "NOT_RUN"), ("Reason", "OFFLINE_SELFTEST_HARD_STOP"),
            ("Invocations", "0"), ("Credential remnants", str(len(credential_remnants))),
        ]))

    placeholders = {
        "G2B_HW0_PRODUCT_R3R4R3_DUT_LOCK_RECEIPT.md": "DUT Lock Receipt",
        "G2B_HW0_PRODUCT_R3R4R3_RECOVERY_DECISION.md": "Recovery Decision",
        "G2B_HW0_PRODUCT_R3R4R3_PRELOAD_INVENTORY.md": "Preload Inventory",
        "G2B_HW0_PRODUCT_R3R4R3_DRIVER_VERIFICATION.md": "Driver Verification",
        "G2B_HW0_PRODUCT_R3R4R3_DRIVER_LOAD_PROBE.md": "Driver Load Probe",
        "G2B_HW0_PRODUCT_R3R4R3_NODE_TO_BDF_PROOF.md": "Node-to-BDF Proof",
        "G2B_HW0_PRODUCT_R3R4R3_MMIO_DECODED.md": "MMIO Decoded",
        "G2B_HW0_PRODUCT_R3R4R3_SESSION_START_RECEIPT.md": "Session Start Receipt",
        "G2B_HW0_PRODUCT_R3R4R3_FIRST_RECORD_REPORT.md": "First-Record Report",
        "G2B_HW0_PRODUCT_R3R4R3_FINITE_CAPTURE_REPORT.md": "Finite Capture Report",
        "G2B_HW0_PRODUCT_R3R4R3_COUNTER_RECONCILIATION.md": "Counter Reconciliation",
        "G2B_HW0_PRODUCT_R3R4R3_FRAME_RECONSTRUCTION_REPORT.md": "Frame Reconstruction",
        "G2B_HW0_PRODUCT_R3R4R3_PCIE_AER_KERNEL_REVIEW.md": "PCIe, AER and Kernel Review",
    }
    for filename, title in placeholders.items():
        write(OUT / filename, report(f"{TASK} {title}", [
            ("Result", "NOT_REACHED"),
            ("Reason", "OFFLINE_SELFTEST_HARD_STOP"),
            ("Hardware access", "NO"), ("DUT connections", "0"),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_CLEANUP_RECEIPT.md", report(
        f"{TASK} Cleanup Receipt", [
            ("Result", "NOT_REQUIRED_NO_HARDWARE_ACCESS"),
            ("Task-owned reader processes", "0"), ("Driver loaded", "NO"),
            ("XDMA nodes created", "NO"), ("Locks acquired", "NO"),
            ("Credential remnants", str(len(credential_remnants))),
        ]))
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_FINAL_HARDWARE_STATE.md", report(
        f"{TASK} Final Hardware State", [
            ("Hardware accessed", "NO"), ("DUT connections", "0"),
            ("Driver load attempts", "0"), ("MMIO reads/writes", "0/0"),
            ("DMA operations", "0"), ("FPGA programming", "0"),
            ("Warm reboots", "0"), ("Flash programming", "NO"),
            ("Power-cycle", "NO"), ("Candidate SRAM state", "UNRESOLVED"),
        ]))

    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_NODE_MAP.csv",
              ["DynamicIndex", "Node", "BDF", "Result"], [])
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_MMIO_RAW.csv",
              ["Timestamp", "Session", "UserNode", "BDF", "Offset",
               "Operation", "Value", "Result"], [])
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_MMIO_WRITE_LEDGER.csv",
              ["Timestamp", "Session", "UserNode", "BDF", "Offset",
               "Operation", "Value", "Purpose", "Authorized", "Precondition",
               "Result"], [])
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_FIRST_RECORD_HEADER.csv",
              ["Field", "Value", "Result"], [])
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_FINITE_CAPTURE_METRICS.csv",
              ["Metric", "Value", "Result"], [
                  {"Metric": "PrimaryRecordsRequested", "Value": 2500,
                   "Result": "NOT_REACHED"},
                  {"Metric": "HardwareAccess", "Value": "NO",
                   "Result": "PASS"},
              ])
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_QUIESCENCE_SAMPLES.csv",
              ["Timestamp", "Sample", "Consecutive", "SpanMs", "Result"], [])
    with (OUT / "G2B_HW0_PRODUCT_R3R4R3_PRIMARY_DURABILITY_CHECKPOINTS.jsonl").open(
            "x", encoding="utf-8", newline="\n") as handle:
        for row in checkpoint_rows:
            public_row = {
                "scope": "OFFLINE_SYNTHETIC_PRE_FAILURE_SETUP",
                "formal_contract_case": "NOT_RUN",
                "record_count": row["record_count"],
                "required_size": row["required_size"],
                "persisted_size": row["persisted_size"],
                "fsync_complete": row["fsync_complete"],
                "communication": row["communication"],
                "raw_payload_in_communication": False,
                "result": row["result"],
            }
            handle.write(json.dumps(public_row, sort_keys=True) + "\n")

    gates = [
        ("PREDECESSOR_AUTHORITY", "PASS"), ("IMMUTABLE_BOUNDARY", "PASS"),
        ("TOOL_BASELINE", "PASS"), ("AUTHORIZED_TOOL_DELTA", "PASS"),
        ("OFFLINE_SELFTEST_01_FIRST_RECORD_PERSISTENCE", "FAIL"),
    ] + [(f"OFFLINE_SELFTEST_{index:02d}_{name}", "NOT_REACHED")
         for index, name in enumerate(EXISTING_CASES[1:] + NEW_CASES, start=2)] + [
        ("CAPTURE_TOOL_ARCHITECTURE_HARD_GATE", "NOT_RUN"),
        ("CREDENTIAL_HELPER_HARD_GATE", "NOT_RUN"),
        ("DUT_EXCLUSIVITY", "NOT_REACHED"), ("HARDWARE_SESSION", "NOT_REACHED"),
        ("ENGINEERING_GATE", "BLOCKED"),
    ]
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_GATE_MATRIX.csv",
              ["Gate", "Result"], [{"Gate": gate, "Result": value}
                                    for gate, value in gates])
    write_json(OUT / "G2B_HW0_PRODUCT_R3R4R3_STATE.json", state)

    tool_names = (
        "capture_r3r4.py", "capture_r3r4_selftest.py",
        "frame_reconstruct_r3r4.py", "abi_v1.py",
        "V41_C2H_TRANSPORT_ABI_V1.json", "Invoke-R3R4R3DutConnection.ps1",
        "Collect-ImmutableBoundary.ps1", "audit_tool_delta_r3r4r3.py",
        "audit_capture_architecture_r3r4r3.py",
        "analyze_selftest_failure_r3r4r3.py", "build_blocked_evidence_r3r4r3.py",
    )
    for name in tool_names:
        shutil.copy2(RUN / "scripts" / name, OUT / "tools" / name)
    write_csv(OUT / "G2B_HW0_PRODUCT_R3R4R3_TOOL_INVENTORY.csv",
              ["Tool", "SHA256", "Executed"], [
                  {"Tool": name, "SHA256": sha(OUT / "tools" / name),
                   "Executed": "YES" if name in {
                       "capture_r3r4_selftest.py", "capture_r3r4.py", "abi_v1.py",
                       "audit_tool_delta_r3r4r3.py", "Collect-ImmutableBoundary.ps1",
                       "analyze_selftest_failure_r3r4r3.py",
                       "build_blocked_evidence_r3r4r3.py"} else "NO"}
                  for name in tool_names
              ])

    write(OUT / "V41_G2B_HW0_PRODUCT_R3R4R3_MAIN_REPORT.md",
          "\n".join([
              f"# {TASK} Persisted-Bytes Proof and Capture-Contract Closure", "",
              "## Result", "", "- Engineering gate: `BLOCKED`",
              "- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`",
              "- Overall result: `BLOCKED`", f"- First blocker: `{BLOCKER}`", "",
              "The fresh run passed predecessor authority, immutable-boundary, exact "
              "baseline, and authorized-delta gates. The single 16-case suite stopped "
              "in case 1 on a strict timestamp-separation assertion. The callbacks were "
              "program-ordered, but both received the same 15.625-ms GetTickCount64 tick. "
              "The suite was not patched or rerun.", "",
              "No credential helper was executed. No DUT connection, JTAG, PCIe inventory, "
              "driver load, MMIO, DMA, FPGA programming, reboot, Flash programming, or "
              "power-cycle occurred. No camera bytes are present in this package.", "",
              "Offline synthetic files remain private in the run root. Only hashes, "
              "structural metadata, source, and sanitized receipts are public.", "",
              "## Nonclaims", "",
              "R3R4R3 does not prove persistent first-record hardware capture, a finite "
              "2500-record live capture, complete real-frame reconstruction, 60-second "
              "capture, or 288 MB/s throughput.", "",
              "## Corrective action", "",
              "Authorize a fresh governed run that proves the formal ordering with an "
              "event sequence/index or explicit dependency receipt, without requiring "
              "two ordered callbacks to occupy distinct monotonic clock ticks. Preserve "
              "the runtime implementation unchanged.", "",
          ]))

    required = [
        "V41_G2B_HW0_PRODUCT_R3R4R3_MAIN_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R3_AUTHORIZATION_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R3_AUTHORITY_VERIFICATION.md",
        "G2B_HW0_PRODUCT_R3R4R3_BOUNDARY_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R3_TOOL_BASELINE_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_DIFF.md",
        "G2B_HW0_PRODUCT_R3R4R3_PERSISTED_BYTES_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R3_PRIMARY_DURABILITY_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R3_ORDERING_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R3_QUIESCENCE_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R3_W1C_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_SELFTEST.md",
        "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_SELFTEST.json",
        "G2B_HW0_PRODUCT_R3R4R3_CAPTURE_TOOL_AUDIT.md",
        "G2B_HW0_PRODUCT_R3R4R3_CREDENTIAL_HELPER_AUDIT.md",
        "G2B_HW0_PRODUCT_R3R4R3_DUT_LOCK_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R3_RECOVERY_DECISION.md",
        "G2B_HW0_PRODUCT_R3R4R3_PRELOAD_INVENTORY.md",
        "G2B_HW0_PRODUCT_R3R4R3_DRIVER_VERIFICATION.md",
        "G2B_HW0_PRODUCT_R3R4R3_DRIVER_LOAD_PROBE.md",
        "G2B_HW0_PRODUCT_R3R4R3_NODE_TO_BDF_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R3_NODE_MAP.csv",
        "G2B_HW0_PRODUCT_R3R4R3_MMIO_RAW.csv",
        "G2B_HW0_PRODUCT_R3R4R3_MMIO_DECODED.md",
        "G2B_HW0_PRODUCT_R3R4R3_MMIO_WRITE_LEDGER.csv",
        "G2B_HW0_PRODUCT_R3R4R3_SESSION_START_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R3_FIRST_RECORD_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R3_FIRST_RECORD_HEADER.csv",
        "G2B_HW0_PRODUCT_R3R4R3_PRIMARY_DURABILITY_CHECKPOINTS.jsonl",
        "G2B_HW0_PRODUCT_R3R4R3_FINITE_CAPTURE_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R3_FINITE_CAPTURE_METRICS.csv",
        "G2B_HW0_PRODUCT_R3R4R3_QUIESCENCE_SAMPLES.csv",
        "G2B_HW0_PRODUCT_R3R4R3_COUNTER_RECONCILIATION.md",
        "G2B_HW0_PRODUCT_R3R4R3_FRAME_RECONSTRUCTION_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R3_PCIE_AER_KERNEL_REVIEW.md",
        "G2B_HW0_PRODUCT_R3R4R3_CLEANUP_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R3_FINAL_HARDWARE_STATE.md",
        "G2B_HW0_PRODUCT_R3R4R3_GATE_MATRIX.csv",
        "G2B_HW0_PRODUCT_R3R4R3_STATE.json",
    ]
    missing = [name for name in required if not (OUT / name).is_file()]
    if missing:
        raise RuntimeError("R3R4R3_REQUIRED_PUBLIC_FILE_MISSING:" + ",".join(missing))
    forbidden_suffixes = {".bin", ".bit", ".dcp", ".ko", ".uyvy", ".png"}
    forbidden = [str(path.relative_to(OUT)) for path in OUT.rglob("*")
                 if path.is_file() and path.suffix.lower() in forbidden_suffixes]
    if forbidden:
        raise RuntimeError("R3R4R3_PROHIBITED_PUBLIC_BINARY:" + ",".join(forbidden))

    index_lines = ["# R3R4R3 Evidence Index", ""]
    index_lines.extend(f"- `{path.relative_to(OUT).as_posix()}`"
                       for path in sorted(OUT.rglob("*")) if path.is_file())
    index_lines.extend(["", "Raw camera records, raw UYVY frames, and camera PNGs published: `0`.", ""])
    write(OUT / "G2B_HW0_PRODUCT_R3R4R3_EVIDENCE_INDEX.md",
          "\n".join(index_lines))
    manifest_path = OUT / "G2B_HW0_PRODUCT_R3R4R3_SHA256_MANIFEST.txt"
    manifest_lines = []
    for path in sorted(OUT.rglob("*")):
        if path.is_file() and path != manifest_path:
            manifest_lines.append(f"{sha(path)}  {path.relative_to(OUT).as_posix()}")
    write(manifest_path, "\n".join(manifest_lines) + "\n")
    print(json.dumps({
        "result": "PASS", "staging": str(OUT),
        "manifest_entries": len(manifest_lines), "required_files": len(required),
        "forbidden_public_files": forbidden, "credential_remnants": len(credential_remnants),
        "hardware_access": False, "dut_connections": 0,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
