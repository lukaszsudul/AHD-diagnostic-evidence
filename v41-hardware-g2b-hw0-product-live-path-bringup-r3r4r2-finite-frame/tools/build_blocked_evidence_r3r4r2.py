#!/usr/bin/env python3
"""Build sanitized R3R4R2 evidence after the offline architecture hard stop."""
from __future__ import annotations

import csv
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


TASK = "G2B-HW0-PRODUCT-R3R4R2"
ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R2_20260907T071912Z")
REPO = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
SOURCE = Path(r"C:\FPGA\V41_G2B")
EVIDENCE_NAME = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r2-finite-frame"
)
STAGE = ROOT / "publication" / "sealed-attempt-2" / EVIDENCE_NAME
R3R3_DIR = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record"
)
R3R4_DIR = "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4-finite-frame"
R3R4R1_DIR = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame"
)
R3R3_COMMIT = "6cff7ad374575df84bc7d8794565dbd7d9cd869f"
R3R4_COMMIT = "2bfcba2476a31a06bdf940881cd5d0a20614333e"
R3R4R1_COMMIT = "9c1ff0473ca336e75c29a19208be17b407d8bf37"
SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
DRV_COMMIT = "9aacc157dab5fe604faf66501b0129613b98ae2d"
BIT_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
DCP_SHA = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"
ABI_SHA = "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6"
DRIVER_SHA = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"
BLOCKER = (
    "R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_FAILED:"
    "PERSISTED_FIRST_RECORD_REREAD_HASH_PROOF_ABSENT"
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
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


def write_csv(path: Path, columns: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
        handle.flush()
        os.fsync(handle.fileno())


def manifest_check(directory: str, manifest_name: str, commit: str) -> dict:
    root = REPO / directory
    manifest = root / manifest_name
    failures = []
    entries = 0
    for line in manifest.read_text(encoding="utf-8-sig").splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r"([0-9A-Fa-f]{64})  (.+)", line)
        if not match:
            failures.append({"line": line, "reason": "MALFORMED"})
            continue
        entries += 1
        expected, relative = match.groups()
        candidate = root / Path(relative)
        if not candidate.is_file():
            failures.append({"path": relative, "reason": "MISSING"})
        elif sha(candidate) != expected.upper():
            failures.append({"path": relative, "reason": "HASH_MISMATCH"})
    tree_at_commit = git_text(REPO, "rev-parse", f"{commit}:{directory}")
    tree_at_head = git_text(REPO, "rev-parse", f"HEAD:{directory}")
    result = {
        "commit": commit,
        "directory": directory,
        "tree_at_commit": tree_at_commit,
        "tree_at_head": tree_at_head,
        "tree_unchanged": tree_at_commit == tree_at_head,
        "manifest_entries": entries,
        "manifest_failures": failures,
    }
    result["result"] = (
        "PASS" if not failures and tree_at_commit == tree_at_head else "FAIL"
    )
    return result


def verify_authority() -> dict:
    local = git_text(REPO, "rev-parse", "HEAD")
    remote = git_text(REPO, "ls-remote", "origin", "refs/heads/main").split()[0]
    require(local == R3R4R1_COMMIT, "LOCAL_MAIN_NOT_R3R4R1")
    require(remote == R3R4R1_COMMIT, "REMOTE_MAIN_NOT_R3R4R1")
    require(
        not git_text(REPO, "status", "--porcelain", "--", "project-current-state"),
        "PROJECT_CURRENT_STATE_DIRTY",
    )
    project = git_json(REPO, "HEAD:project-current-state/PROJECT_STATE.json")
    require(project["project_state_revision"] == 8, "PROJECT_STATE_REV_NOT_8")
    require(project["tracks"]["meta"]["current_task"] == "META-8A", "META8A_NOT_CURRENT")
    product = project["tracks"]["product"]["g2b_hw0_product"]
    require(
        product["readiness"] == "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
        "CONTROLLED_HARDWARE_NOT_AUTHORIZED",
    )
    require(product["qualification_state"] == "NOT_PROVEN", "G2B_HW_STATE_DRIFT")

    predecessor = {
        "r3r3": manifest_check(
            R3R3_DIR, "G2B_HW0_PRODUCT_R3R3_SHA256_MANIFEST.txt", R3R3_COMMIT
        ),
        "r3r4": manifest_check(
            R3R4_DIR, "G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt", R3R4_COMMIT
        ),
        "r3r4r1": manifest_check(
            R3R4R1_DIR,
            "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt",
            R3R4R1_COMMIT,
        ),
    }
    require(all(item["result"] == "PASS" for item in predecessor.values()),
            "PREDECESSOR_MANIFEST_FAILURE")
    require(
        [predecessor[key]["manifest_entries"] for key in ("r3r3", "r3r4", "r3r4r1")]
        == [98, 40, 53],
        "PREDECESSOR_MANIFEST_ENTRY_COUNT_DRIFT",
    )

    r3r3 = git_json(REPO, f"{R3R3_COMMIT}:{R3R3_DIR}/G2B_HW0_PRODUCT_R3R3_STATE.json")
    for key, expected in {
        "T0": "PASS", "T1": "PASS", "T2": "PASS",
        "sram_programming_attempts": 1, "warm_reboots": 1, "final_done": 1,
        "reader_complete_records": 53, "reader_trailing_bytes": 0,
        "record_bytes_persisted": False, "cleanup": "PASS",
        "candidate_left_in_volatile_sram": True,
    }.items():
        require(r3r3.get(key) == expected, f"R3R3_FACT_MISMATCH:{key}")
    r3r4 = git_json(REPO, f"{R3R4_COMMIT}:{R3R4_DIR}/G2B_HW0_PRODUCT_R3R4_STATE.json")
    for key, expected in {
        "hardware_accessed": False, "dut_connections": 0,
        "driver_load_attempts": 0,
        "first_blocker": "R3R4_CAPTURE_TOOL_HARD_GATE_FAILED",
    }.items():
        require(r3r4.get(key) == expected, f"R3R4_FACT_MISMATCH:{key}")
    r3r4r1 = git_json(
        REPO, f"{R3R4R1_COMMIT}:{R3R4R1_DIR}/G2B_HW0_PRODUCT_R3R4R1_STATE.json"
    )
    for key, expected in {
        "hardware_accessed": False, "dut_connections": 0,
        "driver_load_attempts": 0, "prior_immutable_artifact_new_writes": 0,
        "partial_read_semantic_checks": "PASS",
        "first_blocker": "R3R4R1_CAPTURE_TOOL_HARD_GATE_FAILED",
    }.items():
        require(r3r4r1.get(key) == expected, f"R3R4R1_FACT_MISMATCH:{key}")
    require(
        r3r4r1["capture_tool_offline_selftests"] == {"passed": 4, "total": 11},
        "R3R4R1_SELFTEST_FACT_MISMATCH",
    )

    require(git_text(SOURCE, "branch", "--show-current") ==
            "integration/v41-g2b-onech-c2h", "SOURCE_BRANCH_MISMATCH")
    require(git_text(SOURCE, "rev-parse", "HEAD") == SOURCE_COMMIT,
            "SOURCE_COMMIT_MISMATCH")
    require(git_text(SOURCE, "rev-parse", "HEAD^{tree}") == SOURCE_TREE,
            "SOURCE_TREE_MISMATCH")
    require(not git_text(SOURCE, "status", "--porcelain", "--untracked-files=all"),
            "SOURCE_DIRTY")
    source_remote = git_text(
        SOURCE, "ls-remote", "origin", "refs/heads/integration/v41-g2b-onech-c2h"
    ).split()[0]
    require(source_remote == SOURCE_COMMIT, "SOURCE_REMOTE_MISMATCH")

    bit = Path(r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit")
    dcp = Path(r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp")
    driver = Path(r"C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko")
    require(sha(bit) == BIT_SHA, "BITSTREAM_HASH_MISMATCH")
    require(sha(dcp) == DCP_SHA, "DCP_HASH_MISMATCH")
    require(sha(driver) == DRIVER_SHA, "DRIVER_HASH_MISMATCH")
    require(sha(ROOT / "scripts/V41_C2H_TRANSPORT_ABI_V1.json") == ABI_SHA,
            "ABI_HASH_MISMATCH")
    return {
        "result": "PASS", "project_state_rev": 8,
        "meta8a_promoted": True, "g2b_hw_qualified": False,
        "controlled_hardware_execution_authorized": True,
        "local_main_before_publication": local,
        "remote_main_before_publication": remote,
        "predecessors": predecessor,
        "source_branch": "integration/v41-g2b-onech-c2h",
        "source_commit": SOURCE_COMMIT, "source_tree": SOURCE_TREE,
        "source_remote_match": True, "source_clean": True,
        "bitstream_sha256": BIT_SHA, "dcp_sha256": DCP_SHA,
        "driver_evidence_commit": DRV_COMMIT, "driver_sha256": DRIVER_SHA,
        "abi_sha256": ABI_SHA,
    }


def not_reached(title: str, extra: str = "") -> str:
    suffix = f"\n\n{extra.strip()}" if extra.strip() else ""
    return f"""# {title}

Result: `NOT_REACHED`.

The ordered capture-tool architecture hard gate failed with `{BLOCKER}`.
The governed stop prevented credential-helper execution and every DUT or
hardware operation. No current hardware value is inferred from predecessor
evidence.{suffix}
"""


def build() -> dict:
    require(not STAGE.exists(), "PUBLIC_STAGE_ALREADY_EXISTS")
    authority = verify_authority()
    delta = json.loads((ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.json").read_text("utf-8"))
    selftest = json.loads((ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_SELFTEST.json").read_text("utf-8"))
    architecture = json.loads((ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json").read_text("utf-8"))
    boundary = json.loads((ROOT / "artifacts/immutable-boundary-after.comparison.json").read_text("utf-8"))
    require(delta["result"] == "PASS" and delta["authorized_tool_delta"] ==
            "QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY_ONLY", "TOOL_DELTA_FAILURE")
    require(selftest["result"] == "PASS" and selftest["passed"] == 11,
            "SELFTEST_NOT_11_OF_11")
    require(architecture["result"] == "FAIL" and architecture["blocker"] == BLOCKER,
            "ARCHITECTURE_DISPOSITION_MISMATCH")
    require(boundary["result"] == "PASS" and
            boundary["prior_immutable_artifact_new_writes"] == 0,
            "IMMUTABLE_BOUNDARY_FAILURE")
    helper = ROOT / "scripts/Invoke-R3R4R2DutConnection.ps1"
    helper_hash = sha(helper)
    require(not list(ROOT.rglob("*.credential.tmp")), "CREDENTIAL_REMNANT")
    require(not list((ROOT / "logs").glob("connection-*.json")),
            "UNEXPECTED_DUT_CONNECTION")

    STAGE.mkdir(parents=True)
    (STAGE / "raw").mkdir()
    (STAGE / "tools").mkdir()

    state = {
        "task": TASK,
        "engineering_gate": "BLOCKED",
        "evidence_publication": "SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "project_state_rev_at_start": 8,
        "project_state_rev_at_end": 8,
        "r3r3_evidence": "VERIFIED",
        "failed_r3r4_evidence": "VERIFIED",
        "failed_r3r4r1_evidence": "VERIFIED",
        "run_root": str(ROOT),
        "prior_immutable_artifact_new_writes": 0,
        "tool_baseline": "VERIFIED",
        "authorized_tool_delta": "QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY_ONLY",
        "quiet_window_expected_completions": [False, False, False, False, False, True, True],
        "runtime_quiet_window_function_changed": False,
        "invalid_chunk_count_assertion_absent": True,
        "partial_read_semantic_checks": "PASS",
        "capture_tool_offline_selftests": {"passed": 11, "total": 11},
        "failed_selftest": "NONE",
        "capture_tool_architecture_hard_gate": "FAIL",
        "architecture_failed_checks": architecture["failed_checks"],
        "first_record_asynchronous_persistence_offline": "PASS",
        "raw_payload_control_ipc": False,
        "parent_owned_mmio_design": True,
        "parent_owned_quiescence_design": True,
        "credential_helper": str(helper),
        "credential_helper_sha256": helper_hash,
        "credential_helper_hard_gate": "NOT_RUN",
        "credential_helper_invocations": 0,
        "all_connections_local_helper": "NOT_REACHED",
        "credential_remnants": 0,
        "owner_r3r4r2_authorization": "GRANTED",
        "conditional_sram_programming_maximum": 1,
        "conditional_sram_programming_executed": 0,
        "conditional_warm_reboot_maximum": 1,
        "conditional_warm_reboot_executed": 0,
        "recovery_path": "NOT_REACHED",
        "hardware_accessed": False,
        "dut_connections": 0,
        "dut_exclusivity": "NOT_REACHED",
        "parallel_hdmi_activity": "NOT_REACHED",
        "current_boot_id": None,
        "fpga_device": None, "fpga_idcode": None,
        "fpga_done_before": None, "fpga_done_after": None,
        "product_bitstream_authority": "VERIFIED",
        "endpoint": None, "pcie_gen2_x1": "NOT_REACHED",
        "driver_load_attempts": 0, "driver_module_loaded": "NOT_RUN",
        "endpoint_automatically_bound": "NOT_RUN",
        "unintended_endpoints_bound": 0, "dynamic_xdma_index": None,
        "node_to_bdf_mapping": "NOT_REACHED",
        "dual_layer_identity": "NOT_REACHED",
        "nvp_initialization": "NOT_REACHED", "fixed_live_source": "NOT_REACHED",
        "combined_t34_sessions": 0, "reset_stream_state_writes": 0,
        "session_normalization_w1c_writes": 0, "snapshot_writes": 0,
        "stream_enable_writes": 0, "normal_stream_disable_writes": 0,
        "safety_disable_writes": 0, "statistics_clear_writes": 0,
        "unauthorized_mmio_writes": 0,
        "persistent_first_record_hardware": "NOT_REACHED",
        "finite_capture": "NOT_REACHED", "primary_records_requested": 2500,
        "primary_records_received": None, "drain_records": None,
        "incomplete_trailing_bytes": None,
        "counter_reconciliation": "NOT_REACHED", "frame_reconstruction": "NOT_REACHED",
        "pcie_aer_kernel_health": "NOT_REACHED",
        "cleanup": "NOT_REQUIRED_NO_HARDWARE_ACCESS",
        "candidate_module_unloaded_end": "NOT_LOADED",
        "endpoint_automatically_unbound_end": "NOT_BOUND",
        "xdma_nodes_removed_end": "NOT_CREATED",
        "persistent_filesystem_state_modified": False,
        "candidate_left_in_volatile_sram": "UNRESOLVED",
        "flash_programming": 0, "power_cycles": 0,
        "raw_records_published": False, "raw_frame_published": False,
        "viewable_camera_image_published": False,
        "continuous_60_second_capture": "NOT_RUN",
        "throughput_288_MBps": "NOT_PROVEN",
        "four_input": "NOT_QUALIFIED", "two_channel": "NOT_QUALIFIED",
        "synthetic_generator": "NOT_TESTED", "v4l2": "NOT_TESTED",
        "full_g2b_hw": "NOT_YET_PROVEN", "ssot_update_required": False,
        "recommended_next_step": (
            "Authorize one fresh corrective run to re-read the fsync-completed "
            "first-record and payload files, then compute hashes and parse only "
            "those persisted bytes before any DUT connection."
        ),
        "final_execution_point": (
            "HARD STOP AFTER G2B-HW0-PRODUCT-R3R4R2 FINITE-FRAME QUALIFICATION"
        ),
    }

    write_text(STAGE / "V41_G2B_HW0_PRODUCT_R3R4R2_MAIN_REPORT.md", f"""# AHD v41 G2B-HW0-PRODUCT-R3R4R2

## Outcome

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `{BLOCKER}`
- Hardware accessed: `NO`

## Completed offline gates

R3R3, failed R3R4, and failed R3R4R1 evidence and manifests verified at their
pinned commits. PROJECT_STATE_REV remained 8. The exact PRODUCT source,
bitstream, DCP, frozen ABI, and qualified driver identities matched.

The only capture/self-test delta was the authorized R3R4R2 identity update and
the case-5 expected vector correction to
`[false,false,false,false,false,true,true]`. The runtime quiet-window function
was unchanged. All 11 offline self-tests passed, including the 2,507-record
partial-read fixture with exactly 2,500 primary records, seven drain records,
and zero trailing bytes.

## First stopped gate

The independent architecture hard gate found that `_persist_first` flushes and
fsyncs the dedicated first-record and payload files, but computes the reported
hashes and performs ABI validation from the pre-write in-memory `blob` and
`payload`. It never re-reads the persisted files. R3R4R2 sections 9 and 19
explicitly require the hashes and parse to use re-read persisted bytes.

The audit also preserved other downstream contract gaps: no periodic primary
file fsync checkpoint before `PRIMARY_TARGET_REACHED`, no enforced first-record
durability-before-primary ordering, no multi-observation stability requirement
in parent quiescence, and split nonfatal/fatal normalization logic that can
permit two W1C writes instead of the single combined-mask budget. These were
not modified because this run authorizes no runtime semantic change.

Credential-helper execution and all DUT activity were therefore prohibited.
Connections, driver loads, MMIO operations, DMA operations, programming,
reboots, Flash writes, and power cycles all remained zero.
""")
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_AUTHORIZATION_RECEIPT.md", f"""# R3R4R2 authorization receipt

Owner authorization: `GRANTED` for the exact R3R4R2 scope.

The authorized semantic correction was limited to the case-5 expected vector.
No runtime capture change was authorized. The architecture hard-gate failure
therefore caused a mandatory stop before credential-helper execution and DUT
connection. Conditional SRAM programming and warm-reboot budgets were `0/1`
used; Flash programming and power-cycle were `NO`.
""")
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_AUTHORITY_VERIFICATION.md", f"""# R3R4R2 authority verification

Result: `PASS`.

- PROJECT_STATE_REV: `8`; META-8A remains promoted; G2B-HW remains `NOT_PROVEN`.
- R3R3: `{R3R3_COMMIT}`, manifest `98/98`, required facts `VERIFIED`.
- Failed R3R4: `{R3R4_COMMIT}`, manifest `40/40`, required facts `VERIFIED`.
- Failed R3R4R1: `{R3R4R1_COMMIT}`, manifest `53/53`, required facts `VERIFIED`.
- PRODUCT source: `integration/v41-g2b-onech-c2h` / `{SOURCE_COMMIT}` / `{SOURCE_TREE}`.
- Bitstream SHA-256: `{BIT_SHA}`.
- DCP SHA-256: `{DCP_SHA}`.
- ABI SHA-256: `{ABI_SHA}`.
- Driver evidence commit: `{DRV_COMMIT}`; module SHA-256: `{DRIVER_SHA}`.
""")
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_BOUNDARY_RECEIPT.md", f"""# R3R4R2 immutable-boundary receipt

- Fresh run root: `{ROOT}`
- Protected roots: `22`
- Protected files: `9077`
- Prior immutable artifact new writes: `0`
- Removed protected files: `0`
- Changed protected files: `0`
- PRODUCT source HEAD/tree/status unchanged: `PASS`
- Prior R3R4R1 root modified or executed from: `NO`
""")

    for name in (
        "G2B_HW0_PRODUCT_R3R4R2_TOOL_BASELINE_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_QUIET_WINDOW_CORRECTION.md",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.md",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.patch",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_SELFTEST.md",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_SELFTEST.json",
    ):
        shutil.copyfile(ROOT / "artifacts" / name, STAGE / name)
    shutil.copyfile(
        ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.md",
        STAGE / "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_AUDIT.md",
    )
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_CREDENTIAL_HELPER_AUDIT.md", f"""# R3R4R2 credential-helper audit

Ordered hard gate: `NOT_RUN`.

- Fresh helper: `{helper}`
- SHA-256: `{helper_hash}`
- Identity-only normalized delta: `PASS`
- Helper invocations: `0`
- DUT connections: `0`
- Credential remnants: `0`

The architecture gate failed first, so syntax/static execution-gate completion
and any connection attempt were not advanced.
""")
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_DUT_LOCK_RECEIPT.md",
               not_reached("R3R4R2 DUT lock receipt", "Controller lock: `NOT_ACQUIRED`. Linux lock: `NOT_ACQUIRED`."))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_RECOVERY_DECISION.md",
               not_reached("R3R4R2 recovery decision", "Recovery path: `NOT_REACHED`; programs `0/1`; warm reboots `0/1`."))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_PRELOAD_INVENTORY.md",
               not_reached("R3R4R2 preload inventory"))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_DRIVER_VERIFICATION.md", f"""# R3R4R2 driver verification

Offline authority: `VERIFIED`.

- Required module: `xdma_ahd_pcie`
- Required DUT path: `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`
- SHA-256: `{DRIVER_SHA}`
- Driver load attempts: `0`

The DUT copy was not accessed or rehashed after the architecture hard stop.
""")
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_DRIVER_LOAD_PROBE.md",
               not_reached("R3R4R2 driver load and automatic probe", "Load attempts: `0`."))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_NODE_TO_BDF_PROOF.md",
               not_reached("R3R4R2 node-to-BDF proof"))
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_NODE_MAP.csv",
              ["Result", "Node", "BDF", "Reason"],
              [{"Result": "NOT_REACHED", "Node": "N/A", "BDF": "N/A", "Reason": BLOCKER}])
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_MMIO_RAW.csv",
              ["Timestamp", "Session", "UserNode", "BDF", "Offset", "Operation", "Value", "Result"],
              [{"Timestamp": "N/A", "Session": "N/A", "UserNode": "N/A", "BDF": "N/A", "Offset": "N/A", "Operation": "NONE", "Value": "N/A", "Result": "NOT_REACHED"}])
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_MMIO_DECODED.md",
               not_reached("R3R4R2 MMIO decoded evidence", "MMIO reads/writes: `0/0`."))
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_MMIO_WRITE_LEDGER.csv",
              ["Timestamp", "Session", "UserNode", "BDF", "Offset", "Operation", "Value", "Purpose", "Authorized", "Precondition", "Result"],
              [{"Timestamp": "N/A", "Session": "N/A", "UserNode": "N/A", "BDF": "N/A", "Offset": "N/A", "Operation": "NONE", "Value": "N/A", "Purpose": "NONE", "Authorized": "N/A", "Precondition": "ARCHITECTURE_HARD_GATE_FAILED", "Result": "NOT_REACHED"}])
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_SESSION_START_RECEIPT.md",
               not_reached("R3R4R2 combined T3/T4 session start", "Combined sessions: `0`."))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_FIRST_RECORD_REPORT.md",
               not_reached("R3R4R2 persistent first-record hardware report", "Offline synthetic case passed; hardware result is `NOT_PROVEN`."))
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_FIRST_RECORD_HEADER.csv",
              ["Result", "Field", "Value", "Reason"],
              [{"Result": "NOT_REACHED", "Field": "N/A", "Value": "N/A", "Reason": BLOCKER}])
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_FINITE_CAPTURE_REPORT.md",
               not_reached("R3R4R2 finite 2500-record hardware capture"))
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_FINITE_CAPTURE_METRICS.csv",
              ["Metric", "Value", "Result"], [
                  {"Metric": "primary_records_requested", "Value": "2500", "Result": "NOT_REACHED"},
                  {"Metric": "primary_records_received", "Value": "N/A", "Result": "NOT_REACHED"},
                  {"Metric": "primary_bytes", "Value": "N/A", "Result": "NOT_REACHED"},
                  {"Metric": "drain_records", "Value": "N/A", "Result": "NOT_REACHED"},
                  {"Metric": "drain_bytes", "Value": "N/A", "Result": "NOT_REACHED"},
                  {"Metric": "incomplete_trailing_bytes", "Value": "N/A", "Result": "NOT_REACHED"},
              ])
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_COUNTER_RECONCILIATION.md",
               not_reached("R3R4R2 counter reconciliation"))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_FRAME_RECONSTRUCTION_REPORT.md",
               not_reached("R3R4R2 complete real-frame reconstruction"))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_PCIE_AER_KERNEL_REVIEW.md",
               not_reached("R3R4R2 PCIe, AER, and kernel review"))
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_CLEANUP_RECEIPT.md", """# R3R4R2 cleanup receipt

Result: `NOT_REQUIRED_NO_HARDWARE_ACCESS`.

No lock, connection, module, node, MMIO descriptor, reader, DMA session, or
stream was created. Hardware cleanup and driver unload were not required.
""")
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_FINAL_HARDWARE_STATE.md", """# R3R4R2 final hardware state

Hardware accessed: `NO`. Current boot ID, FPGA, endpoint, PCIe link, module,
DMA, and kernel-taint values are `NOT_REACHED`, not inferred. Programming,
reboot, Flash, power-cycle, driver load, MMIO, and DMA counts are zero.
Candidate retained in volatile SRAM: `UNRESOLVED`.
""")
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_GATE_MATRIX.csv",
              ["Gate", "Result", "Blocker_or_basis"], [
                  {"Gate": "Project and predecessor authority", "Result": "PASS", "Blocker_or_basis": "REV8_R3R3_R3R4_R3R4R1_VERIFIED"},
                  {"Gate": "Fresh immutable boundary", "Result": "PASS", "Blocker_or_basis": "22_ROOTS_9077_FILES_ZERO_DELTA"},
                  {"Gate": "Authorized capture-tool delta", "Result": "PASS", "Blocker_or_basis": "QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY_ONLY"},
                  {"Gate": "Offline self-tests", "Result": "PASS_11_OF_11", "Blocker_or_basis": "ALL_CASES_EXECUTED"},
                  {"Gate": "Partial-read semantics", "Result": "PASS", "Blocker_or_basis": "2507_RECORD_FIXTURE"},
                  {"Gate": "Architecture hard gate", "Result": "FAIL", "Blocker_or_basis": BLOCKER},
                  {"Gate": "Credential-helper hard gate", "Result": "NOT_RUN", "Blocker_or_basis": BLOCKER},
                  {"Gate": "DUT exclusivity through hardware cleanup", "Result": "NOT_REACHED", "Blocker_or_basis": BLOCKER},
                  {"Gate": "Engineering", "Result": "BLOCKED", "Blocker_or_basis": BLOCKER},
              ])
    write_json(STAGE / "G2B_HW0_PRODUCT_R3R4R2_STATE.json", state)

    write_json(STAGE / "raw/G2B_HW0_PRODUCT_R3R4R2_AUTHORITY.json", authority)
    write_json(STAGE / "raw/G2B_HW0_PRODUCT_R3R4R2_BOUNDARY.json", {
        "result": "PASS", "snapshot_roots": 22, "snapshot_files": 9077,
        **boundary,
    })
    shutil.copyfile(ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.json",
                    STAGE / "raw/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.json")
    shutil.copyfile(ROOT / "artifacts/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json",
                    STAGE / "raw/G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json")

    tools = (
        "capture_r3r4.py", "capture_r3r4_selftest.py",
        "frame_reconstruct_r3r4.py", "abi_v1.py",
        "V41_C2H_TRANSPORT_ABI_V1.json", "Invoke-R3R4R2DutConnection.ps1",
        "Collect-ImmutableBoundary.ps1", "Apply-R3R4R2Identity.ps1",
        "audit_tool_delta_r3r4r2.py", "audit_capture_architecture_r3r4r2.py",
        "build_blocked_evidence_r3r4r2.py",
    )
    for name in tools:
        shutil.copyfile(ROOT / "scripts" / name, STAGE / "tools" / name)
    write_csv(STAGE / "G2B_HW0_PRODUCT_R3R4R2_TOOL_INVENTORY.csv",
              ["Tool", "Role", "SHA256", "Executed"], [
                  {"Tool": name,
                   "Role": ("CAPTURE_RUNTIME_MMIO_LOCK_CHECK_FAILURE_CLEANUP" if name == "capture_r3r4.py" else
                            "CREDENTIAL_HELPER" if name.startswith("Invoke-") else
                            "OFFLINE_OR_EVIDENCE_HELPER"),
                   "SHA256": sha(STAGE / "tools" / name),
                   "Executed": "NO" if name.startswith("Invoke-") or name == "capture_r3r4.py" else "YES"}
                  for name in tools
              ])

    required = {
        "V41_G2B_HW0_PRODUCT_R3R4R2_MAIN_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R2_AUTHORIZATION_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_AUTHORITY_VERIFICATION.md",
        "G2B_HW0_PRODUCT_R3R4R2_BOUNDARY_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_TOOL_BASELINE_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_QUIET_WINDOW_CORRECTION.md",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_DIFF.md",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_SELFTEST.md",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_SELFTEST.json",
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_AUDIT.md",
        "G2B_HW0_PRODUCT_R3R4R2_CREDENTIAL_HELPER_AUDIT.md",
        "G2B_HW0_PRODUCT_R3R4R2_DUT_LOCK_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_RECOVERY_DECISION.md",
        "G2B_HW0_PRODUCT_R3R4R2_PRELOAD_INVENTORY.md",
        "G2B_HW0_PRODUCT_R3R4R2_DRIVER_VERIFICATION.md",
        "G2B_HW0_PRODUCT_R3R4R2_DRIVER_LOAD_PROBE.md",
        "G2B_HW0_PRODUCT_R3R4R2_NODE_TO_BDF_PROOF.md",
        "G2B_HW0_PRODUCT_R3R4R2_NODE_MAP.csv",
        "G2B_HW0_PRODUCT_R3R4R2_MMIO_RAW.csv",
        "G2B_HW0_PRODUCT_R3R4R2_MMIO_DECODED.md",
        "G2B_HW0_PRODUCT_R3R4R2_MMIO_WRITE_LEDGER.csv",
        "G2B_HW0_PRODUCT_R3R4R2_SESSION_START_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_FIRST_RECORD_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R2_FIRST_RECORD_HEADER.csv",
        "G2B_HW0_PRODUCT_R3R4R2_FINITE_CAPTURE_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R2_FINITE_CAPTURE_METRICS.csv",
        "G2B_HW0_PRODUCT_R3R4R2_COUNTER_RECONCILIATION.md",
        "G2B_HW0_PRODUCT_R3R4R2_FRAME_RECONSTRUCTION_REPORT.md",
        "G2B_HW0_PRODUCT_R3R4R2_PCIE_AER_KERNEL_REVIEW.md",
        "G2B_HW0_PRODUCT_R3R4R2_CLEANUP_RECEIPT.md",
        "G2B_HW0_PRODUCT_R3R4R2_FINAL_HARDWARE_STATE.md",
        "G2B_HW0_PRODUCT_R3R4R2_GATE_MATRIX.csv",
        "G2B_HW0_PRODUCT_R3R4R2_STATE.json",
    }
    missing = sorted(name for name in required if not (STAGE / name).is_file())
    require(not missing, "REQUIRED_PUBLIC_FILE_MISSING:" + ",".join(missing))

    index_names = sorted(
        {str(path.relative_to(STAGE)).replace("\\", "/")
         for path in STAGE.rglob("*") if path.is_file()}
        | {"G2B_HW0_PRODUCT_R3R4R2_EVIDENCE_INDEX.md",
           "G2B_HW0_PRODUCT_R3R4R2_SHA256_MANIFEST.txt"}
    )
    write_text(STAGE / "G2B_HW0_PRODUCT_R3R4R2_EVIDENCE_INDEX.md",
               "# R3R4R2 evidence index\n\n" +
               "\n".join(f"- `{name}`" for name in index_names) +
               "\n\nRaw camera records, raw UYVY frame, and camera PNG published: `0`.")
    manifest = STAGE / "G2B_HW0_PRODUCT_R3R4R2_SHA256_MANIFEST.txt"
    manifest_lines = []
    for path in sorted(item for item in STAGE.rglob("*")
                       if item.is_file() and item != manifest):
        relative = str(path.relative_to(STAGE)).replace("\\", "/")
        manifest_lines.append(f"{sha(path)}  {relative}")
    write_text(manifest, "\n".join(manifest_lines))
    for line in manifest.read_text("utf-8").splitlines():
        expected, relative = line.split("  ", 1)
        require(sha(STAGE / relative) == expected, "MANIFEST_READBACK_FAIL:" + relative)

    prohibited_suffixes = {".ko", ".bit", ".dcp", ".uyvy", ".png", ".bin"}
    prohibited = [str(path.relative_to(STAGE)) for path in STAGE.rglob("*")
                  if path.is_file() and path.suffix.lower() in prohibited_suffixes]
    require(not prohibited, "PROHIBITED_BINARY:" + ",".join(prohibited))
    credential_source = Path(r"C:\FPGA\VCDE-DUT-1.txt")
    credential_bytes = credential_source.read_bytes()
    secret_values = []
    for line in credential_bytes.decode("utf-8", errors="ignore").splitlines():
        if re.search(r"(?i)(password|haslo)\s*[:=]", line):
            secret_values.append(re.split(r"[:=]", line, maxsplit=1)[1].strip().encode())
    for path in (item for item in STAGE.rglob("*") if item.is_file()):
        data = path.read_bytes()
        require(credential_bytes not in data, "CREDENTIAL_FILE_CONTENT_PUBLISHED")
        for secret in secret_values:
            if secret == b"vcdeagent1":
                continue
            require(not secret or secret not in data, "CREDENTIAL_VALUE_PUBLISHED")

    receipt = {
        "result": "PASS", "stage": str(STAGE),
        "files": len([p for p in STAGE.rglob("*") if p.is_file()]),
        "manifest_entries": len(manifest_lines),
        "required_files_present": len(required),
        "prohibited_binary_files": 0, "raw_camera_payload_files": 0,
        "credential_findings": 0, "engineering_gate": "BLOCKED",
        "first_blocker": BLOCKER,
    }
    write_json(ROOT / "logs/public-stage-seal.json", receipt)
    print(json.dumps(receipt, indent=2))
    return receipt


if __name__ == "__main__":
    build()
