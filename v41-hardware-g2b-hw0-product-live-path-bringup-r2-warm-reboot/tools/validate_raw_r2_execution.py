#!/usr/bin/env python3
"""Fail-closed validation of the completed G2B-HW0-PRODUCT-R2 raw run.

This program reads only the locally preserved R2 evidence package.  It neither
connects to the DUT nor reads the source/evidence repositories.  A successful
validator result means that the raw package is internally complete and agrees
with the exact, controlled-stop outcome; it does not turn the blocked
engineering gate into a pass.
"""

from __future__ import annotations

import csv
import hashlib
import io
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


TASK = "G2B-HW0-PRODUCT-R2"
TASK_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_REL = "raw/RAW_EXECUTION_VALIDATION.json"
OUTPUT = TASK_ROOT / OUTPUT_REL

PRE_BOOT_ID = "37131b8d-0e38-4b4e-b77a-b3bda55b4e97"
POST_BOOT_ID = "52b0bf13-e9d1-4558-ae13-d08f4ecc8dac"
DUT_IDENTITY = "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111"
DUT_HOSTNAME = "VCDE-DUT-1"
DUT_IP = "10.132.1.111"
CANDIDATE_SHA256 = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
R1_COMMIT = "eb3a75c09925574c6947d67cdefb8e2a723add9e"
R1_MANIFEST_SHA256 = "D2AD5C4D265E4FDD23E41C294A935DECF1059E166E9B9A146A5B9ED9EAEC19CB"
SSOT_MANIFEST_SHA256 = "B935E05F75AC1357D29ACB91E08978BD9A6701CD06024F9E6E2C6EB071993EC6"
SOURCE_HEAD = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
DCP_SHA256 = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"

JTAG_TARGET = "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01"
JTAG_CANONICAL_ID = "Xilinx/80802026a98b01"
JTAG_PART = "xc7a35t"
JTAG_IDCODE = "0362D093"
ENDPOINT_BDF = "0000:01:00.0"
ENDPOINT_VENDOR_DEVICE = "10ee:7011"
ENDPOINT_SUBSYSTEM = "10ee:0007"
ENDPOINT_CLASS = "058000"
UPSTREAM_BDF = "0000:00:01.1"

XDMA_MODULE_PATH = "/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst"
XDMA_MODULE_SHA256 = "523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490"
FIRST_BLOCKER = "BLOCKED \u2014 SAFE_AHD_XDMA_BIND_UNAVAILABLE"


REQUIRED_SOURCES = [
    "raw/OWNER_R2_CONTRACT.txt",
    "raw/LOCAL_AUTHORITY_VERIFICATION.json",
    "raw/CONTROLLER_EXCLUSIVITY_PRELOCK_REFINED.json",
    "locks/CONTROLLER_LOCK_ACQUIRE_RECEIPT.json",
    "raw/PRE_REBOOT_LINUX_SNAPSHOT.log",
    "raw/LOCKS_PRE_REBOOT_VERIFY.log",
    "raw/JTAG_PRE_REBOOT_SESSION.csv",
    "raw/JTAG_PRE_REBOOT_TARGET_PROPERTIES.tsv",
    "raw/JTAG_PRE_REBOOT_DEVICE_PROPERTIES.tsv",
    "raw/JTAG_PRE_REBOOT_VIVADO.log",
    "raw/PRE_REBOOT_AUTHORITY_RECEIPT.json",
    "raw/WARM_REBOOT_COMMAND.log",
    "raw/WARM_REBOOT_ISSUANCE_SUPERVISOR.json",
    "raw/AFTER_LOCAL_REJECTION_NO_REBOOT_VERIFY.log",
    "raw/LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json",
    "raw/CONTROLLER_LOCK_BOOKKEEPING_CORRECTION.json",
    "locks/CONTROLLER_LOCK_AFTER_LOCAL_REJECTION_CORRECTION.json",
    "raw/WARM_REBOOT_REMOTE_DELIVERY_ARMING_RECEIPT.json",
    "raw/WARM_REBOOT_COMMAND_DELIVERED.log",
    "raw/WARM_REBOOT_REMOTE_DELIVERY_SUPERVISOR.json",
    "raw/EXACT_IP_RECONNECT_SUMMARY.json",
    "raw/POST_REBOOT_AUTHENTICATED_IDENTITY.log",
    "raw/WARM_REBOOT_EXECUTION_CONFIRMATION.json",
    "locks/CONTROLLER_LOCK_POST_REBOOT_CONFIRMATION.json",
    "raw/POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK.log",
    "raw/LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_CLASSIFICATION.json",
    "raw/LINUX_LOCK_POST_REBOOT_ACQUIRE_CORRECTED.log",
    "locks/LINUX_LOCK_POST_REBOOT_RECEIPT.json",
    "locks/CONTROLLER_LOCK_POST_LINUX_RELOCK.json",
    "raw/POST_REBOOT_LOCKS_REMOTE_VERIFY.log",
    "raw/POST_REBOOT_COMBINED_LOCK_VERIFICATION.json",
    "raw/JTAG_POST_REBOOT_SESSION.csv",
    "raw/JTAG_POST_REBOOT_TARGET_PROPERTIES.tsv",
    "raw/JTAG_POST_REBOOT_DEVICE_PROPERTIES.tsv",
    "raw/JTAG_POST_REBOOT_VIVADO.log",
    "raw/JTAG_POST_REBOOT_VIVADO.jou",
    "raw/POST_REBOOT_JTAG_RETENTION_GATE.json",
    "raw/POST_REBOOT_PCIE_XDMA_INVENTORY.log",
    "raw/POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json",
    "raw/XDMA_BINDING_FEASIBILITY_READONLY.log",
    "raw/T1_DRIVER_GATE_DECISION.json",
    "raw/JTAG_FINAL_SESSION.csv",
    "raw/JTAG_FINAL_TARGET_PROPERTIES.tsv",
    "raw/JTAG_FINAL_DEVICE_PROPERTIES.tsv",
    "raw/JTAG_FINAL_VIVADO.log",
    "raw/JTAG_FINAL_VIVADO.jou",
    "raw/FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log",
    "raw/FINAL_STATE_VALIDATION.json",
    "locks/CONTROLLER_LOCK_BEFORE_LINUX_RELEASE.json",
    "raw/LINUX_LOCK_POST_REBOOT_RELEASE.log",
    "locks/LINUX_LOCK_POST_REBOOT_RELEASE_RECEIPT.json",
    "locks/CONTROLLER_LOCK_AFTER_LINUX_RELEASE.json",
    "raw/CONTROLLER_LOCK_RELEASE_RECEIPT.json",
    "raw/CONTROLLER_LOCK_RELEASE_OPERATION.json",
]

JSON_SOURCES = {
    rel for rel in REQUIRED_SOURCES if rel.lower().endswith(".json")
}

checks: list[dict[str, Any]] = []
source_bytes: dict[str, bytes] = {}
source_hashes: dict[str, dict[str, Any]] = {}
documents: dict[str, Any] = {}
texts: dict[str, str] = {}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def add_check(
    name: str,
    passed: bool,
    actual: Any,
    expected: Any,
    sources: str | list[str],
) -> None:
    checks.append(
        {
            "name": name,
            "result": "PASS" if bool(passed) else "FAIL",
            "expected": expected,
            "actual": actual,
            "sources": [sources] if isinstance(sources, str) else list(sources),
        }
    )


def dig(document: Any, *keys: str) -> Any:
    value = document
    for key in keys:
        if not isinstance(value, dict) or key not in value:
            return None
        value = value[key]
    return value


def exact(
    name: str,
    document: Any,
    keys: tuple[str, ...],
    expected: Any,
    source: str,
) -> None:
    actual = dig(document, *keys)
    add_check(name, actual == expected, actual, expected, source)


def require_markers(
    name: str,
    rel: str,
    markers: list[str],
    *,
    ignore_blank_lines: bool = False,
) -> None:
    text = texts.get(rel)
    if text is not None and ignore_blank_lines:
        text = "\n".join(line for line in text.splitlines() if line.strip())
    missing = markers if text is None else [marker for marker in markers if marker not in text]
    add_check(
        name,
        text is not None and not missing,
        {"missing_markers": missing, "marker_count": len(markers)},
        {"missing_markers": [], "marker_count": len(markers)},
        rel,
    )


def require_hash_link(name: str, declared: Any, target_rel: str, declaring_rel: str) -> None:
    actual_hash = dig(source_hashes.get(target_rel), "sha256")
    normalized_declared = declared.upper() if isinstance(declared, str) else declared
    add_check(
        name,
        normalized_declared is not None and normalized_declared == actual_hash,
        {"declared": normalized_declared, "computed": actual_hash},
        "declared SHA-256 equals computed source SHA-256",
        [declaring_rel, target_rel],
    )


def check_jtag_csv(rel: str, session_index: int) -> None:
    expected_header = [
        "session_index",
        "sample_index",
        "monotonic_ms",
        "utc",
        "target_count",
        "device_count",
        "target_path",
        "canonical_id",
        "server_endpoint",
        "transport_class",
        "part",
        "idcode",
        "done",
        "refresh_result",
    ]
    text = texts.get(rel)
    rows: list[dict[str, str]] = []
    header: list[str] | None = None
    error: str | None = None
    if text is not None:
        try:
            reader = csv.DictReader(io.StringIO(text, newline=""))
            header = reader.fieldnames
            rows = list(reader)
        except Exception as exc:  # pragma: no cover - fail-closed evidence path
            error = f"{type(exc).__name__}: {exc}"

    add_check(
        f"jtag_session_{session_index}_csv_shape",
        error is None and header == expected_header and len(rows) == 5,
        {"header": header, "rows": len(rows), "error": error},
        {"header": expected_header, "rows": 5, "error": None},
        rel,
    )

    expected_rows = []
    for sample_index in range(1, 6):
        expected_rows.append(
            {
                "session_index": str(session_index),
                "sample_index": str(sample_index),
                "target_count": "1",
                "device_count": "1",
                "target_path": JTAG_TARGET,
                "canonical_id": JTAG_CANONICAL_ID,
                "server_endpoint": "localhost:3121",
                "transport_class": "xilinx_tcf",
                "part": JTAG_PART,
                "idcode": JTAG_IDCODE,
                "done": "1",
                "refresh_result": "PASS",
            }
        )
    actual_rows = [
        {key: row.get(key) for key in expected_rows[0]}
        for row in rows
    ] if rows else []
    add_check(
        f"jtag_session_{session_index}_exact_identity_done_samples",
        actual_rows == expected_rows,
        actual_rows,
        expected_rows,
        rel,
    )

    monotonic_values: list[int] = []
    try:
        monotonic_values = [int(row["monotonic_ms"]) for row in rows]
    except (KeyError, TypeError, ValueError):
        monotonic_values = []
    add_check(
        f"jtag_session_{session_index}_strictly_increasing_samples",
        len(monotonic_values) == 5
        and all(a < b for a, b in zip(monotonic_values, monotonic_values[1:])),
        monotonic_values,
        "five strictly increasing monotonic_ms values",
        rel,
    )


def same_exact_blocker(value: Any) -> bool:
    return value == FIRST_BLOCKER


# Read every required source exactly once. Missing, unreadable, empty, or
# undecodable evidence remains a recorded validation failure.
for rel in REQUIRED_SOURCES:
    path = TASK_ROOT / Path(rel)
    try:
        data = path.read_bytes()
        source_bytes[rel] = data
        source_hashes[rel] = {"sha256": sha256_bytes(data), "bytes": len(data)}
        add_check(f"source_available::{rel}", len(data) > 0, len(data), "> 0 bytes", rel)
        try:
            decoded = data.decode("utf-8-sig")
            source_hashes[rel]["text_encoding"] = "UTF-8"
        except UnicodeDecodeError:
            try:
                # Vivado controller logs are emitted in the Windows ANSI code
                # page and legitimately contain bytes such as 0xA3.  This is
                # an explicit, deterministic fallback; hashes remain over the
                # original bytes.
                decoded = data.decode("cp1252")
                source_hashes[rel]["text_encoding"] = "Windows-1252"
            except UnicodeDecodeError as exc:
                add_check(
                    f"source_text_decode::{rel}",
                    False,
                    f"{type(exc).__name__}: {exc}",
                    "valid UTF-8/UTF-8-BOM or Windows-1252",
                    rel,
                )
                continue
        texts[rel] = decoded.replace("\r\n", "\n").replace("\r", "\n")
    except OSError as exc:
        source_hashes[rel] = {"sha256": None, "bytes": None, "error": f"{type(exc).__name__}: {exc}"}
        add_check(
            f"source_available::{rel}",
            False,
            source_hashes[rel]["error"],
            "> 0 bytes",
            rel,
        )

for rel in sorted(JSON_SOURCES):
    text = texts.get(rel)
    try:
        document = json.loads(text) if text is not None else None
        if not isinstance(document, dict):
            raise ValueError("top-level JSON value is not an object")
        documents[rel] = document
        add_check(f"json_parse::{rel}", True, "JSON object", "JSON object", rel)
    except Exception as exc:
        add_check(
            f"json_parse::{rel}",
            False,
            f"{type(exc).__name__}: {exc}",
            "JSON object",
            rel,
        )
        documents[rel] = {}


# Literal owner contract and authority/R1 receipt.
contract_rel = "raw/OWNER_R2_CONTRACT.txt"
require_markers(
    "owner_contract_exact_authority_and_stop_policy",
    contract_rel,
    [
        "OWNER_HARDWARE_AUTHORIZATION:\nGRANTED",
        "OWNER_WARM_REBOOT_AUTHORIZATION:\nGRANTED",
        "MAXIMUM_WARM_REBOOTS:\n1",
        "POWER_CYCLE_AUTHORIZATION:\nDENIED",
        "SRAM_REPROGRAMMING_AUTHORIZATION_IN_R2:\nDENIED",
        "FLASH_PROGRAMMING_AUTHORIZATION:\nDENIED",
        "0x0000..0x0030",
        "0x0080..0x00B4",
        "LEGACY_MMIO_WRITE_AUTHORIZATION:\nDENIED",
        "0x3800..0x3BFF",
        "- a second reboot;",
        "- global PCIe rescan;",
        "- broad root-port reset;",
        "- global XDMA module unload;",
        "BLOCKED \u2014 SAFE_AHD_XDMA_BIND_UNAVAILABLE",
        "- release the Linux-side lock;",
        "- release the controller-side lock last.",
    ],
    ignore_blank_lines=True,
)

authority_rel = "raw/LOCAL_AUTHORITY_VERIFICATION.json"
authority = documents[authority_rel]
for name, keys, expected in [
    ("authority_task", ("task",), TASK),
    ("authority_result", ("result",), "PASS"),
    ("authority_r1_commit", ("r1_evidence_commit",), R1_COMMIT),
    ("authority_r1_manifest_result", ("r1_manifest", "result"), "PASS"),
    ("authority_r1_manifest_entries", ("r1_manifest", "entries"), 57),
    ("authority_r1_manifest_mismatches", ("r1_manifest", "mismatches"), 0),
    ("authority_r1_manifest_sha256", ("r1_manifest", "manifest_sha256"), R1_MANIFEST_SHA256),
    ("authority_ssot_manifest_result", ("ssot_manifest", "result"), "PASS"),
    ("authority_ssot_manifest_entries", ("ssot_manifest", "entries"), 18),
    ("authority_ssot_manifest_mismatches", ("ssot_manifest", "mismatches"), 0),
    ("authority_ssot_manifest_sha256", ("ssot_manifest", "manifest_sha256"), SSOT_MANIFEST_SHA256),
    ("authority_owner_hardware", ("owner_hardware_authorization",), "GRANTED"),
    ("authority_owner_warm_reboot", ("owner_warm_reboot_authorization",), "GRANTED"),
    ("authority_maximum_warm_reboots", ("maximum_warm_reboots",), 1),
    ("authority_power_cycle", ("power_cycle_authorization",), "DENIED"),
    ("authority_sram_reprogramming", ("sram_reprogramming_authorization_in_r2",), "DENIED"),
    ("authority_flash_programming", ("flash_programming_authorization",), "DENIED"),
    ("authority_legacy_mmio_read", ("legacy_mmio_read_authorization",), "GRANTED"),
    ("authority_legacy_mmio_write", ("legacy_mmio_write_authorization",), "DENIED"),
]:
    exact(name, authority, keys, expected, authority_rel)

expected_authority_checks: dict[str, Any] = {
    "R1_EVIDENCE_HEAD": R1_COMMIT,
    "R1_EVIDENCE_ORIGIN_TRACKING": R1_COMMIT,
    "R1_EVIDENCE_REMOTE": R1_COMMIT,
    "EVIDENCE_TRACKED_CLEAN": "",
    "R1_PUBLICATION": "PASS",
    "R1_REMOTE_READBACK": "PASS",
    "R1_FINAL_CANDIDATE": "STILL_LOADED_VOLATILE_SRAM_BY_UNBROKEN_CHAIN",
    "R1_FINAL_DONE": 1,
    "R1_FINAL_ENDPOINT": "ABSENT",
    "R1_FINAL_DRIVER": "NOT_LOADED",
    "R1_FINAL_NODES": [],
    "R1_FLASH": "NO",
    "R1_REBOOTS": 0,
    "R1_POWER_CYCLES": 0,
    "PROJECT_STATE_REV": 8,
    "G2B_LUT1_STATUS": "ACCEPTED",
    "G2B_LUT1_READINESS": "OFFLINE_QUALIFIED",
    "CANDIDATE_MATURITY": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
    "G2B_HW0_READINESS": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
    "G2B_HW0_SCOPE": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
    "SOURCE_BRANCH": "integration/v41-g2b-onech-c2h",
    "SOURCE_HEAD": SOURCE_HEAD,
    "SOURCE_TREE": SOURCE_TREE,
    "SOURCE_REMOTE": SOURCE_HEAD,
    "SOURCE_TRACKED_CLEAN": "",
    "BIT_BYTES": 2192144,
    "BIT_SHA256": CANDIDATE_SHA256,
    "DCP_SHA256": DCP_SHA256,
}
authority_checks = dig(authority, "checks")
authority_by_name: dict[str, Any] = {}
if isinstance(authority_checks, list):
    authority_by_name = {
        item.get("name"): item
        for item in authority_checks
        if isinstance(item, dict) and isinstance(item.get("name"), str)
    }
add_check(
    "authority_exact_check_set",
    set(authority_by_name) == set(expected_authority_checks),
    sorted(authority_by_name),
    sorted(expected_authority_checks),
    authority_rel,
)
for check_name, expected_value in expected_authority_checks.items():
    item = authority_by_name.get(check_name, {})
    actual = {
        "actual": item.get("actual"),
        "expected": item.get("expected"),
        "result": item.get("result"),
    }
    expected = {"actual": expected_value, "expected": expected_value, "result": "PASS"}
    add_check(f"authority_check::{check_name}", actual == expected, actual, expected, authority_rel)


# Pre-reboot exclusivity, Linux state, exact JTAG identity, and candidate chain.
prelock_rel = "raw/CONTROLLER_EXCLUSIVITY_PRELOCK_REFINED.json"
prelock = documents[prelock_rel]
for name, keys, expected in [
    ("prelock_task", ("task",), TASK),
    ("prelock_exclusivity", ("exclusivity",), "PASS"),
    ("prelock_relevant_processes", ("relevant_process_count",), 0),
    ("prelock_active_lock_directories", ("active_named_lock_directory_count",), 0),
    ("prelock_current_task_only", ("codex_current_task_only_active",), True),
]:
    exact(name, prelock, keys, expected, prelock_rel)

controller_acquire_rel = "locks/CONTROLLER_LOCK_ACQUIRE_RECEIPT.json"
controller_acquire = documents[controller_acquire_rel]
for name, keys, expected in [
    ("controller_lock_acquire_task", ("task",), TASK),
    ("controller_lock_acquire_candidate", ("candidate_sha256",), CANDIDATE_SHA256),
    ("controller_lock_acquire_dut", ("dut_identity",), DUT_IDENTITY),
    ("controller_lock_acquire_boot", ("pre_reboot_boot_id",), PRE_BOOT_ID),
    ("controller_lock_acquire_max_reboots", ("maximum_warm_reboots",), 1),
    ("controller_lock_acquire_warm_reboots", ("warm_reboots_executed",), 0),
    ("controller_lock_acquire_state", ("state",), "HELD"),
]:
    exact(name, controller_acquire, keys, expected, controller_acquire_rel)

require_markers(
    "pre_reboot_linux_exact_safe_state",
    "raw/PRE_REBOOT_LINUX_SNAPSHOT.log",
    [
        "RESULT=PASS",
        f"HOSTNAME={DUT_HOSTNAME}",
        f"BOOT_ID={PRE_BOOT_ID}",
        "CONTROLLER_LOCK_EXPECTED=HELD",
        "MAXIMUM_WARM_REBOOTS=1",
        "WARM_REBOOT_COMMANDS_ISSUED=0",
        "SRAM_PROGRAMS_R2=0",
        "FLASH_OPERATIONS_R2=0",
        "POWER_CYCLES_R2=0",
        "LINUX_LOCK=HELD",
        "XDMA_NODE_COUNT=0",
    ],
)
require_markers(
    "pre_reboot_locks_remote_readback",
    "raw/LOCKS_PRE_REBOOT_VERIFY.log",
    ["RESULT=PASS", f"BOOT_ID={PRE_BOOT_ID}", "LINUX_LOCK=HELD", '"warm_reboots_executed": 0'],
)
check_jtag_csv("raw/JTAG_PRE_REBOOT_SESSION.csv", 1)
require_markers(
    "pre_reboot_jtag_zero_programming",
    "raw/JTAG_PRE_REBOOT_VIVADO.log",
    [
        "SAMPLE_1_DONE=1",
        "SAMPLE_2_DONE=1",
        "SAMPLE_3_DONE=1",
        "SAMPLE_4_DONE=1",
        "SAMPLE_5_DONE=1",
        "FPGA_PROGRAM_OPERATIONS_THIS_SESSION=0",
    ],
)

pre_receipt_rel = "raw/PRE_REBOOT_AUTHORITY_RECEIPT.json"
pre_receipt = documents[pre_receipt_rel]
for name, keys, expected in [
    ("pre_receipt_task", ("task",), TASK),
    ("pre_receipt_result", ("result",), "PASS"),
    ("pre_receipt_boot", ("pre_reboot_boot_id",), PRE_BOOT_ID),
    ("pre_receipt_dut", ("authoritative_dut",), DUT_IDENTITY),
    ("pre_receipt_authority", ("authority_verification",), "PASS"),
    ("pre_receipt_exclusivity", ("fresh_exclusivity",), "PASS"),
    ("pre_receipt_controller_lock", ("controller_lock",), "HELD"),
    ("pre_receipt_linux_lock", ("linux_lock",), "HELD"),
    ("pre_receipt_endpoint", ("pre_reboot_ahd_endpoint",), "ABSENT"),
    ("pre_receipt_xdma", ("pre_reboot_xdma_module",), "UNLOADED"),
    ("pre_receipt_xdma_nodes", ("pre_reboot_xdma_nodes",), 0),
    ("pre_receipt_jtag_target", ("pre_reboot_jtag", "target"), JTAG_TARGET),
    ("pre_receipt_jtag_id", ("pre_reboot_jtag", "canonical_id"), JTAG_CANONICAL_ID),
    ("pre_receipt_jtag_part", ("pre_reboot_jtag", "part"), JTAG_PART),
    ("pre_receipt_jtag_idcode", ("pre_reboot_jtag", "idcode"), JTAG_IDCODE),
    ("pre_receipt_jtag_index", ("pre_reboot_jtag", "chain_index"), 0),
    ("pre_receipt_jtag_done", ("pre_reboot_jtag", "done_samples"), [1, 1, 1, 1, 1]),
    ("pre_receipt_jtag_programs", ("pre_reboot_jtag", "program_operations"), 0),
    ("pre_receipt_candidate_commit", ("candidate_continuity_basis", "r1_final_evidence_commit"), R1_COMMIT),
    ("pre_receipt_candidate_hash", ("candidate_continuity_basis", "r1_candidate_sha256"), CANDIDATE_SHA256),
    ("pre_receipt_intervening_sram", ("candidate_continuity_basis", "known_intervening_sram_programs"), 0),
    ("pre_receipt_intervening_flash", ("candidate_continuity_basis", "known_intervening_flash_operations"), 0),
    ("pre_receipt_intervening_power", ("candidate_continuity_basis", "known_intervening_power_cycles"), 0),
    ("pre_receipt_other_tasks", ("candidate_continuity_basis", "other_active_ahd_hardware_tasks"), 0),
]:
    exact(name, pre_receipt, keys, expected, pre_receipt_rel)
for link_name, declared_key, target in [
    ("pre_receipt_hash_local_authority", "local_authority", authority_rel),
    ("pre_receipt_hash_controller_exclusivity", "controller_exclusivity", prelock_rel),
    ("pre_receipt_hash_linux_snapshot", "linux_pre_reboot", "raw/PRE_REBOOT_LINUX_SNAPSHOT.log"),
    ("pre_receipt_hash_jtag_csv", "jtag_session", "raw/JTAG_PRE_REBOOT_SESSION.csv"),
    ("pre_receipt_hash_locks_verify", "locks_verify", "raw/LOCKS_PRE_REBOOT_VERIFY.log"),
]:
    require_hash_link(link_name, dig(pre_receipt, "evidence_sha256", declared_key), target, pre_receipt_rel)


# The first wrapper call was conclusively rejected before dispatch.  Its false
# live-lock bookkeeping was corrected while the actual reboot budget stayed at 1.
rejection_rel = "raw/LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json"
rejection = documents[rejection_rel]
for name, keys, expected in [
    ("local_rejection_task", ("task",), TASK),
    ("local_rejection_result", ("result",), "PASS"),
    ("local_rejection_class", ("determination",), "LOCAL_PRE_EXECUTION_ARGUMENT_REJECTION"),
    ("local_rejection_argument_audit", ("argument_token_audit",), "NOT_RUN"),
    ("local_rejection_pwfile", ("password_file_created",), False),
    ("local_rejection_child", ("child_process_started",), False),
    ("local_rejection_plink", ("plink_started",), False),
    ("local_rejection_ssh", ("ssh_connection_attempted",), False),
    ("local_rejection_stdout", ("remote_stdout_bytes",), 0),
    ("local_rejection_stderr", ("remote_stderr_bytes",), 0),
    ("local_rejection_remote_commands", ("remote_reboot_commands_issued",), 0),
    ("local_rejection_acknowledgements", ("reboot_schedule_acknowledgements",), 0),
    ("local_rejection_warm_reboots", ("warm_reboots_executed",), 0),
    ("local_rejection_budget", ("authorized_reboot_budget_remaining",), 1),
    ("local_rejection_same_boot", ("verified_post_rejection_boot_id",), PRE_BOOT_ID),
    ("local_rejection_boot_unchanged", ("pre_reboot_boot_id_unchanged",), True),
    ("local_rejection_linux_lock", ("linux_lock_still_held",), True),
    ("local_rejection_originals_preserved", ("original_evidence_preserved",), True),
    ("local_rejection_supervisor_preserved", ("original_supervisor_preserved",), True),
]:
    exact(name, rejection, keys, expected, rejection_rel)
require_markers(
    "rejected_wrapper_raw_pre_dispatch_facts",
    "raw/WARM_REBOOT_COMMAND.log",
    [
        "RESULT=SANITIZED_ARGUMENT_STRUCTURE",
        "EXIT_CODE=99",
        "ARGUMENT_TOKEN_AUDIT=NOT_RUN",
        "PWFILE_CREATED=NO",
        "PWFILE_DELETED=YES",
        "STDOUT_BEGIN\n\nSTDOUT_END",
        "STDERR_BEGIN\n\nSTDERR_END",
    ],
)
require_markers(
    "same_boot_after_local_rejection",
    "raw/AFTER_LOCAL_REJECTION_NO_REBOOT_VERIFY.log",
    [
        "RESULT=PASS",
        f"BOOT_ID={PRE_BOOT_ID}",
        "LINUX_LOCK=HELD",
    ],
)
for link_name, declared_key, target in [
    ("rejection_hash_original_wrapper", "rejected_wrapper_evidence_sha256", "raw/WARM_REBOOT_COMMAND.log"),
    ("rejection_hash_original_supervisor", "rejected_wrapper_supervisor_sha256", "raw/WARM_REBOOT_ISSUANCE_SUPERVISOR.json"),
    ("rejection_hash_same_boot", "same_boot_verification_sha256", "raw/AFTER_LOCAL_REJECTION_NO_REBOOT_VERIFY.log"),
]:
    require_hash_link(link_name, dig(rejection, "source_sha256", declared_key), target, rejection_rel)

correction_rel = "raw/CONTROLLER_LOCK_BOOKKEEPING_CORRECTION.json"
correction = documents[correction_rel]
for name, keys, expected in [
    ("correction_task", ("task",), TASK),
    ("correction_result", ("result",), "PASS"),
    ("correction_scope", ("correction_scope",), "LIVE_CONTROLLER_LOCK_BOOKKEEPING_ONLY"),
    ("correction_prior_warm_count", ("prior_bookkeeping", "warm_reboots_executed"), 1),
    ("correction_prior_consumed", ("prior_bookkeeping", "reboot_budget_consumed"), True),
    ("correction_remote_attempts", ("corrected_bookkeeping", "remote_reboot_command_delivery_attempts"), 0),
    ("correction_remote_deliveries", ("corrected_bookkeeping", "remote_reboot_command_deliveries"), 0),
    ("correction_actual_warm_count", ("corrected_bookkeeping", "warm_reboots_executed"), 0),
    ("correction_budget_consumed", ("corrected_bookkeeping", "reboot_budget_consumed"), False),
    ("correction_budget_remaining", ("corrected_bookkeeping", "authorized_reboot_budget_remaining"), 1),
    ("correction_remote_status", ("corrected_bookkeeping", "remote_reboot_command_status"), "NOT_ISSUED"),
]:
    exact(name, correction, keys, expected, correction_rel)
require_hash_link(
    "correction_hash_rejection_classification",
    dig(correction, "classification_sha256"),
    rejection_rel,
    correction_rel,
)

corrected_lock_rel = "locks/CONTROLLER_LOCK_AFTER_LOCAL_REJECTION_CORRECTION.json"
corrected_lock = documents[corrected_lock_rel]
for name, keys, expected in [
    ("corrected_lock_state", ("state",), "HELD"),
    ("corrected_lock_remote_attempts", ("remote_reboot_command_delivery_attempts",), 0),
    ("corrected_lock_remote_deliveries", ("remote_reboot_command_deliveries",), 0),
    ("corrected_lock_warm_reboots", ("warm_reboots_executed",), 0),
    ("corrected_lock_budget_remaining", ("authorized_reboot_budget_remaining",), 1),
    ("corrected_lock_command_status", ("remote_reboot_command_status",), "NOT_ISSUED"),
]:
    exact(name, corrected_lock, keys, expected, corrected_lock_rel)


# First and only actual remote reboot delivery, bounded exact-IP reconnect, and
# authenticated single boot-ID transition.
arming_rel = "raw/WARM_REBOOT_REMOTE_DELIVERY_ARMING_RECEIPT.json"
arming = documents[arming_rel]
for name, keys, expected in [
    ("reboot_arming_task", ("task",), TASK),
    ("reboot_arming_result", ("result",), "ARMED"),
    ("reboot_arming_authorization", ("authorization",), "OWNER_WARM_REBOOT_AUTHORIZATION=GRANTED"),
    ("reboot_arming_maximum", ("maximum_warm_reboots",), 1),
    ("reboot_arming_prior_attempts", ("remote_reboot_command_delivery_attempts_before_arming",), 0),
    ("reboot_arming_prior_deliveries", ("remote_reboot_command_deliveries_before_arming",), 0),
    ("reboot_arming_prior_warm", ("warm_reboots_executed_before_arming",), 0),
    ("reboot_arming_budget", ("authorized_reboot_budget_before_arming",), 1),
    ("reboot_arming_no_retry", ("no_retry_after_process_launch",), True),
    ("reboot_arming_controller_lock", ("controller_lock_continues_held",), True),
]:
    exact(name, arming, keys, expected, arming_rel)

delivery_rel = "raw/WARM_REBOOT_COMMAND_DELIVERED.log"
require_markers(
    "reboot_delivery_exact_first_and_only_acknowledged",
    delivery_rel,
    [
        "RESULT=PASS",
        "EXIT_CODE=0",
        "ARGUMENT_TOKEN_AUDIT=PASS",
        "PWFILE_CREATED=YES",
        "PWFILE_DELETED=YES",
        "REMOTE_COMMAND_SHARED_LITERAL=NO",
        f"PRE_REBOOT_BOOT_ID={PRE_BOOT_ID}",
        "LINUX_LOCK_PRE_REBOOT=HELD",
        "MAXIMUM_WARM_REBOOTS=1",
        "REMOTE_REBOOT_COMMAND_NUMBER=1",
        "SYSTEMD_RUN_EXIT_CODE=0",
        "REBOOT_SCHEDULE_ACKNOWLEDGED=YES",
        "Running timer as unit: ahd-g2b-hw0-product-r2-warm-reboot.timer",
        "Will run service as unit: ahd-g2b-hw0-product-r2-warm-reboot.service",
    ],
)

delivery_supervisor_rel = "raw/WARM_REBOOT_REMOTE_DELIVERY_SUPERVISOR.json"
delivery_supervisor = documents[delivery_supervisor_rel]
for name, keys, expected in [
    ("delivery_supervisor_task", ("task",), TASK),
    ("delivery_supervisor_helper_exit", ("helper_exit_code",), 0),
    ("delivery_supervisor_argument_audit", ("argument_token_audit_passed",), True),
    ("delivery_supervisor_pwfile", ("password_file_created",), True),
    ("delivery_supervisor_remote_attempts", ("remote_reboot_command_delivery_attempts",), 1),
    ("delivery_supervisor_remote_deliveries", ("remote_reboot_command_deliveries",), 1),
    ("delivery_supervisor_ack", ("reboot_schedule_acknowledged",), True),
    ("delivery_supervisor_budget_consumed", ("reboot_budget_consumed",), True),
    ("delivery_supervisor_budget_remaining", ("authorized_reboot_budget_remaining",), 0),
    ("delivery_supervisor_maximum", ("maximum_warm_reboots",), 1),
    ("delivery_supervisor_second_authorized", ("second_reboot_authorized",), False),
    ("delivery_supervisor_lock", ("controller_lock_continues_held",), True),
    ("delivery_supervisor_disposition", ("disposition",), "MONITOR_EXACT_IP_NO_RETRY"),
]:
    exact(name, delivery_supervisor, keys, expected, delivery_supervisor_rel)

reconnect_rel = "raw/EXACT_IP_RECONNECT_SUMMARY.json"
reconnect = documents[reconnect_rel]
for name, keys, expected in [
    ("reconnect_task", ("task",), TASK),
    ("reconnect_result", ("result",), "PASS"),
    ("reconnect_exact_ip", ("exact_ip",), DUT_IP),
    ("reconnect_port", ("port",), 22),
    ("reconnect_disconnect", ("ssh_disconnect_observed",), True),
    ("reconnect_reconnect", ("tcp_reconnect_observed",), True),
    ("reconnect_lock", ("controller_lock_held_through_monitor",), True),
    ("reconnect_remote_attempts", ("remote_reboot_command_delivery_attempts",), 1),
    ("reconnect_remote_deliveries", ("remote_reboot_command_deliveries",), 1),
    ("reconnect_second_attempted", ("second_reboot_attempted",), False),
]:
    exact(name, reconnect, keys, expected, reconnect_rel)
max_seconds = dig(reconnect, "maximum_seconds")
elapsed_seconds = dig(reconnect, "elapsed_seconds")
add_check(
    "reconnect_bounded_within_contract",
    isinstance(max_seconds, (int, float))
    and isinstance(elapsed_seconds, (int, float))
    and 0 <= elapsed_seconds <= max_seconds <= 900,
    {"elapsed_seconds": elapsed_seconds, "maximum_seconds": max_seconds},
    "0 <= elapsed_seconds <= maximum_seconds <= 900",
    reconnect_rel,
)

identity_rel = "raw/POST_REBOOT_AUTHENTICATED_IDENTITY.log"
require_markers(
    "post_reboot_authenticated_identity_exact",
    identity_rel,
    [
        "RESULT=PASS",
        f"HOSTNAME={DUT_HOSTNAME}",
        "REMOTE_USER=vcdeagent1",
        "MACHINE_ID=0e90f50d9465492b80258da5658446f8",
        f"PRE_REBOOT_BOOT_ID={PRE_BOOT_ID}",
        f"POST_REBOOT_BOOT_ID={POST_BOOT_ID}",
    ],
)

confirmation_rel = "raw/WARM_REBOOT_EXECUTION_CONFIRMATION.json"
confirmation = documents[confirmation_rel]
for name, keys, expected in [
    ("reboot_confirmation_task", ("task",), TASK),
    ("reboot_confirmation_result", ("result",), "PASS"),
    ("reboot_confirmation_type", ("reboot_type",), "GRACEFUL_OPERATING_SYSTEM_WARM_REBOOT"),
    ("reboot_confirmation_maximum", ("maximum_warm_reboots",), 1),
    ("reboot_confirmation_remote_attempts", ("remote_reboot_command_delivery_attempts",), 1),
    ("reboot_confirmation_remote_deliveries", ("remote_reboot_command_deliveries",), 1),
    ("reboot_confirmation_acks", ("reboot_schedule_acknowledgements",), 1),
    ("reboot_confirmation_warm_reboots", ("warm_reboots_executed",), 1),
    ("reboot_confirmation_second_attempted", ("second_reboot_attempted",), False),
    ("reboot_confirmation_second_authorized", ("second_reboot_authorized",), False),
    ("reboot_confirmation_power_attempted", ("power_cycle_attempted",), False),
    ("reboot_confirmation_pre_boot", ("pre_reboot_boot_id",), PRE_BOOT_ID),
    ("reboot_confirmation_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
    ("reboot_confirmation_boot_change", ("authenticated_boot_id_change",), True),
    ("reboot_confirmation_ip_transition", ("exact_ip_disconnect_and_reconnect",), True),
    ("reboot_confirmation_lock", ("controller_lock_held_through_transition",), True),
]:
    exact(name, confirmation, keys, expected, confirmation_rel)
add_check(
    "reboot_boot_ids_are_distinct",
    dig(confirmation, "pre_reboot_boot_id") != dig(confirmation, "post_reboot_boot_id")
    and dig(confirmation, "pre_reboot_boot_id") is not None
    and dig(confirmation, "post_reboot_boot_id") is not None,
    {"pre": dig(confirmation, "pre_reboot_boot_id"), "post": dig(confirmation, "post_reboot_boot_id")},
    {"pre": PRE_BOOT_ID, "post": POST_BOOT_ID, "distinct": True},
    confirmation_rel,
)
for link_name, declared_key, target in [
    ("confirmation_hash_delivery", "delivery", delivery_rel),
    ("confirmation_hash_delivery_supervisor", "delivery_supervisor", delivery_supervisor_rel),
    ("confirmation_hash_reconnect", "reconnect_summary", reconnect_rel),
    ("confirmation_hash_identity", "authenticated_identity", identity_rel),
]:
    require_hash_link(link_name, dig(confirmation, "evidence_sha256", declared_key), target, confirmation_rel)


# Controller lock continuity, safe post-reboot Linux relock, and exclusivity.
controller_confirm_rel = "locks/CONTROLLER_LOCK_POST_REBOOT_CONFIRMATION.json"
controller_confirm = documents[controller_confirm_rel]
for name, keys, expected in [
    ("controller_confirm_state", ("state",), "HELD"),
    ("controller_confirm_revision", ("controller_lock_revision",), 5),
    ("controller_confirm_remote_attempts", ("remote_reboot_command_delivery_attempts",), 1),
    ("controller_confirm_remote_deliveries", ("remote_reboot_command_deliveries",), 1),
    ("controller_confirm_warm_reboots", ("warm_reboots_executed",), 1),
    ("controller_confirm_budget", ("authorized_reboot_budget_remaining",), 0),
    ("controller_confirm_status", ("remote_reboot_command_status",), "EXECUTION_CONFIRMED_NO_RETRY"),
    ("controller_confirm_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
]:
    exact(name, controller_confirm, keys, expected, controller_confirm_rel)

require_markers(
    "post_reboot_exclusivity_before_relock",
    "raw/POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK.log",
    [
        "RESULT=PASS",
        f"HOSTNAME={DUT_HOSTNAME}",
        f"BOOT_ID={POST_BOOT_ID}",
        "XDMA_MODULE_COUNT=0",
        "XDMA_DEVICE_NODE_COUNT=0",
        "PRE_REBOOT_LINUX_LOCK=ABSENT_AFTER_REBOOT",
        "POST_REBOOT_LINUX_LOCK=ABSENT_READY_TO_ACQUIRE",
        "EXACT_AHD_ENDPOINT_COUNT=1",
    ],
)

lock_failure_rel = "raw/LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_CLASSIFICATION.json"
lock_failure = documents[lock_failure_rel]
for name, keys, expected in [
    ("linux_relock_rejection_result", ("result",), "PASS"),
    ("linux_relock_rejection_class", ("determination",), "PRE_MUTATION_TASK_LOCK_GUARD_PIPELINE_REJECTION"),
    ("linux_relock_rejection_mutations", ("post_reboot_linux_lock_mutations_completed",), 0),
    ("linux_relock_rejection_created", ("post_reboot_linux_lock_created",), False),
    ("linux_relock_rejection_hardware_mutations", ("hardware_mutations",), 0),
    ("linux_relock_corrected_authorized", ("corrected_acquisition_authorized",), True),
    ("linux_relock_original_preserved", ("original_evidence_preserved",), True),
]:
    exact(name, lock_failure, keys, expected, lock_failure_rel)

require_markers(
    "post_reboot_linux_lock_correctly_acquired",
    "raw/LINUX_LOCK_POST_REBOOT_ACQUIRE_CORRECTED.log",
    [
        "RESULT=PASS",
        "LINUX_POST_REBOOT_LOCK=HELD",
        "RELEVANT_PROCESS_COUNT_BEFORE_LOCK=0",
        "XDMA_MODULE_COUNT_BEFORE_LOCK=0",
        "XDMA_DEVICE_NODE_COUNT_BEFORE_LOCK=0",
        "OTHER_TASK_LOCK_COUNT_BEFORE_LOCK=0",
        '"warm_reboots_executed": 1',
        '"power_cycles_executed": 0',
        '"sram_program_operations_in_r2": 0',
        '"flash_program_operations": 0',
        '"controller_lock_state": "HELD"',
    ],
)

linux_lock_rel = "locks/LINUX_LOCK_POST_REBOOT_RECEIPT.json"
linux_lock = documents[linux_lock_rel]
for name, keys, expected in [
    ("linux_lock_task", ("task_id",), TASK),
    ("linux_lock_candidate", ("candidate_bitstream_sha256",), CANDIDATE_SHA256),
    ("linux_lock_dut", ("linux_dut_identity",), DUT_IDENTITY),
    ("linux_lock_hostname", ("hostname",), DUT_HOSTNAME),
    ("linux_lock_pre_boot", ("pre_reboot_boot_id",), PRE_BOOT_ID),
    ("linux_lock_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
    ("linux_lock_phase", ("lock_phase",), "POST_REBOOT"),
    ("linux_lock_max_reboots", ("maximum_warm_reboots",), 1),
    ("linux_lock_warm_reboots", ("warm_reboots_executed",), 1),
    ("linux_lock_budget", ("authorized_reboot_budget_remaining",), 0),
    ("linux_lock_power", ("power_cycles_executed",), 0),
    ("linux_lock_sram", ("sram_program_operations_in_r2",), 0),
    ("linux_lock_flash", ("flash_program_operations",), 0),
    ("linux_lock_processes", ("relevant_process_count_before_lock",), 0),
    ("linux_lock_xdma", ("xdma_module_count_before_lock",), 0),
    ("linux_lock_nodes", ("xdma_device_node_count_before_lock",), 0),
    ("linux_lock_other_locks", ("other_task_lock_count_before_lock",), 0),
    ("linux_lock_controller", ("controller_lock_state",), "HELD"),
    ("linux_lock_state", ("lock_release_state",), "HELD"),
]:
    exact(name, linux_lock, keys, expected, linux_lock_rel)

post_linux_controller_rel = "locks/CONTROLLER_LOCK_POST_LINUX_RELOCK.json"
post_linux_controller = documents[post_linux_controller_rel]
for name, keys, expected in [
    ("post_linux_controller_state", ("state",), "HELD"),
    ("post_linux_controller_revision", ("controller_lock_revision",), 6),
    ("post_linux_controller_linux_state", ("linux_post_reboot_lock_state",), "HELD"),
    ("post_linux_controller_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
    ("post_linux_controller_warm", ("warm_reboots_executed",), 1),
    ("post_linux_controller_budget", ("authorized_reboot_budget_remaining",), 0),
]:
    exact(name, post_linux_controller, keys, expected, post_linux_controller_rel)
require_hash_link(
    "post_linux_controller_hash_linux_receipt",
    dig(post_linux_controller, "linux_post_reboot_lock_receipt_sha256"),
    linux_lock_rel,
    post_linux_controller_rel,
)

combined_rel = "raw/POST_REBOOT_COMBINED_LOCK_VERIFICATION.json"
combined = documents[combined_rel]
for name, keys, expected in [
    ("combined_lock_task", ("task",), TASK),
    ("combined_lock_result", ("result",), "PASS"),
    ("combined_controller_lock", ("controller_lock",), "HELD"),
    ("combined_controller_revision", ("controller_lock_revision",), 6),
    ("combined_linux_lock", ("linux_post_reboot_lock",), "HELD"),
    ("combined_linux_readback", ("linux_lock_receipt_remote_readback",), "PASS"),
    ("combined_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
    ("combined_processes", ("relevant_process_count",), 0),
    ("combined_xdma", ("xdma_module_count",), 0),
    ("combined_nodes", ("xdma_device_node_count",), 0),
    ("combined_endpoint_count", ("exact_ahd_endpoint_count",), 1),
    ("combined_warm_reboots", ("warm_reboots_executed",), 1),
    ("combined_budget", ("authorized_reboot_budget_remaining",), 0),
]:
    exact(name, combined, keys, expected, combined_rel)
require_hash_link(
    "combined_lock_hash_linux_receipt",
    dig(combined, "linux_lock_receipt_sha256"),
    linux_lock_rel,
    combined_rel,
)
require_markers(
    "combined_lock_remote_readback_log",
    "raw/POST_REBOOT_LOCKS_REMOTE_VERIFY.log",
    [
        "RESULT=PASS",
        "LINUX_LOCK_RECEIPT_SEMANTICS=PASS",
        "XDMA_MODULE_COUNT=0",
        "XDMA_DEVICE_NODE_COUNT=0",
        "EXACT_AHD_ENDPOINT_COUNT=1",
        "LINUX_POST_REBOOT_LOCK=HELD",
    ],
)


# Fresh post-reboot JTAG retention and exact PCIe correlation/Gen2 x1.
check_jtag_csv("raw/JTAG_POST_REBOOT_SESSION.csv", 2)
require_markers(
    "post_reboot_jtag_zero_programming",
    "raw/JTAG_POST_REBOOT_VIVADO.log",
    [
        "SAMPLE_1_DONE=1",
        "SAMPLE_2_DONE=1",
        "SAMPLE_3_DONE=1",
        "SAMPLE_4_DONE=1",
        "SAMPLE_5_DONE=1",
        "FPGA_PROGRAM_OPERATIONS_THIS_SESSION=0",
    ],
)

retention_rel = "raw/POST_REBOOT_JTAG_RETENTION_GATE.json"
retention = documents[retention_rel]
for name, keys, expected in [
    ("retention_task", ("task",), TASK),
    ("retention_result", ("result",), "PASS"),
    ("retention_gate", ("gate",), "POST_REBOOT_CANDIDATE_RETENTION"),
    ("retention_target_count", ("jtag_target_count",), 1),
    ("retention_device_count", ("jtag_device_count",), 1),
    ("retention_target", ("target_path",), JTAG_TARGET),
    ("retention_canonical", ("canonical_id",), JTAG_CANONICAL_ID),
    ("retention_part", ("part",), JTAG_PART),
    ("retention_idcode", ("idcode",), JTAG_IDCODE),
    ("retention_index", ("chain_index",), 0),
    ("retention_done", ("done_samples",), [1, 1, 1, 1, 1]),
    ("retention_done_stable", ("done_stable",), True),
    ("retention_crc_error", ("configuration_crc_error",), 0),
    ("retention_idcode_error", ("configuration_idcode_error",), 0),
    ("retention_security_error", ("configuration_security_error",), 0),
    ("retention_hmac_error", ("configuration_hmac_error",), 0),
    ("retention_bad_packet", ("configuration_bad_packet_error",), 0),
    ("retention_jtag_programs", ("fpga_program_operations_this_session",), 0),
    ("retention_r2_sram_programs", ("sram_program_operations_in_r2",), 0),
    ("retention_flash_programs", ("flash_program_operations",), 0),
    ("retention_candidate", ("candidate_bitstream_sha256",), CANDIDATE_SHA256),
    ("retention_outcome", ("candidate_retained_across_warm_reboot",), "PASS"),
    ("retention_qualification", ("qualification",), "JTAG_DOES_NOT_READ_BACK_BITSTREAM_HASH"),
]:
    exact(name, retention, keys, expected, retention_rel)
for source_name in [
    "JTAG_POST_REBOOT_SESSION.csv",
    "JTAG_POST_REBOOT_TARGET_PROPERTIES.tsv",
    "JTAG_POST_REBOOT_DEVICE_PROPERTIES.tsv",
    "JTAG_POST_REBOOT_VIVADO.log",
    "JTAG_POST_REBOOT_VIVADO.jou",
]:
    require_hash_link(
        f"retention_hash::{source_name}",
        dig(retention, "source_sha256", source_name),
        f"raw/{source_name}",
        retention_rel,
    )

inventory_rel = "raw/POST_REBOOT_PCIE_XDMA_INVENTORY.log"
require_markers(
    "post_reboot_exact_endpoint_inventory",
    inventory_rel,
    [
        "RESULT=PASS",
        f"HOSTNAME={DUT_HOSTNAME}",
        f"BOOT_ID={POST_BOOT_ID}",
        "LINUX_POST_REBOOT_LOCK=HELD",
        "EXACT_AHD_ENDPOINT_COUNT=1",
        f"ENDPOINT_BDF={ENDPOINT_BDF}",
        f"ENDPOINT_VENDOR_DEVICE={ENDPOINT_VENDOR_DEVICE}",
        f"UPSTREAM_BDF={UPSTREAM_BDF}",
        "CURRENT_LINK_SPEED=5.0 GT/s PCIe",
        "CURRENT_LINK_WIDTH=1",
        "LnkCap:\tPort #0, Speed 5GT/s, Width x1",
        "LnkSta:\tSpeed 5GT/s, Width x1",
        "XDMA_MODULE_LOADED_COUNT=0",
        f"XDMA_MODULE_PATH={XDMA_MODULE_PATH}",
        f"XDMA_MODULE_SHA256={XDMA_MODULE_SHA256.lower()}",
        "XDMA_DRIVER_SYSFS=ABSENT",
        "XDMA_DEVICE_NODE_COUNT=0",
        "MMIO_READS=0",
        "MMIO_WRITES=0",
        "DMA_OPERATIONS=0",
        "DRIVER_CHANGES=0",
        "PCI_RESCANS=0",
        "PCI_RESETS=0",
    ],
)

correlation_rel = "raw/POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json"
correlation = documents[correlation_rel]
for name, keys, expected in [
    ("correlation_task", ("task",), TASK),
    ("correlation_result", ("result",), "PASS"),
    ("correlation_gate", ("post_reboot_jtag_to_pcie_correlation",), "PASS"),
    ("correlation_jtag_target", ("jtag", "target"), JTAG_TARGET),
    ("correlation_jtag_part", ("jtag", "part"), JTAG_PART),
    ("correlation_jtag_idcode", ("jtag", "idcode"), JTAG_IDCODE),
    ("correlation_jtag_index", ("jtag", "chain_index"), 0),
    ("correlation_jtag_done", ("jtag", "done"), 1),
    ("correlation_endpoint_bdf", ("pcie", "endpoint_bdf"), ENDPOINT_BDF),
    ("correlation_vendor_device", ("pcie", "vendor_device"), ENDPOINT_VENDOR_DEVICE),
    ("correlation_subsystem", ("pcie", "subsystem"), ENDPOINT_SUBSYSTEM),
    ("correlation_class", ("pcie", "class"), ENDPOINT_CLASS),
    ("correlation_upstream", ("pcie", "upstream_bdf"), UPSTREAM_BDF),
    ("correlation_lnkcap", ("pcie", "endpoint_lnkcap"), "Speed 5GT/s, Width x1"),
    ("correlation_lnksta", ("pcie", "endpoint_lnksta"), "Speed 5GT/s, Width x1"),
    ("correlation_sysfs_speed", ("pcie", "sysfs_current_link_speed"), "5.0 GT/s PCIe"),
    ("correlation_sysfs_width", ("pcie", "sysfs_current_link_width"), 1),
    ("correlation_driver", ("pcie", "driver"), "NONE"),
    ("correlation_gen2_x1", ("pcie_gen2_x1_hardware_gate",), "PASS"),
    ("correlation_r1_binding_hash", ("r1_binding_sha256",), "961D435339A94A5DA3F225EFD589D7E1D549398EF855BF77455E246DBC2AB765"),
]:
    exact(name, correlation, keys, expected, correlation_rel)
require_hash_link(
    "correlation_hash_retention",
    dig(correlation, "source_sha256", "POST_REBOOT_JTAG_RETENTION_GATE.json"),
    retention_rel,
    correlation_rel,
)
require_hash_link(
    "correlation_hash_inventory",
    dig(correlation, "source_sha256", "POST_REBOOT_PCIE_XDMA_INVENTORY.log"),
    inventory_rel,
    correlation_rel,
)
exact(
    "correlation_embedded_historical_binding_hash",
    correlation,
    ("source_sha256", "HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log"),
    "961D435339A94A5DA3F225EFD589D7E1D549398EF855BF77455E246DBC2AB765",
    correlation_rel,
)
exact(
    "correlation_embedded_r1_manifest_hash",
    correlation,
    ("source_sha256", "G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt"),
    R1_MANIFEST_SHA256,
    correlation_rel,
)


# The only installed xdma module is platform-only and cannot bind this PCI
# modalias.  The required behavior is the first controlled stop, with no load,
# bind, node/MMIO access, or DMA experiment.
feasibility_rel = "raw/XDMA_BINDING_FEASIBILITY_READONLY.log"
require_markers(
    "xdma_platform_only_readonly_feasibility",
    feasibility_rel,
    [
        "RESULT=PASS",
        f"BOOT_ID={POST_BOOT_ID}",
        "LINUX_POST_REBOOT_LOCK=HELD",
        f"ENDPOINT_BDF={ENDPOINT_BDF}",
        "ENDPOINT_MODALIAS=pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00",
        "ENDPOINT_DRIVER=NONE",
        "EXACT_MODALIAS_RESOLUTION_EXIT_CODE=1",
        f"XDMA_MODULE_PATH={XDMA_MODULE_PATH}",
        f"XDMA_MODULE_SHA256={XDMA_MODULE_SHA256.lower()}",
        "alias:          platform:xdma",
        "XDMA_MODULE_ALIASES_BEGIN\nplatform:xdma\nXDMA_MODULE_ALIASES_END",
        "PLATFORM_XDMA_MATCHING_DEVICE_COUNT=0",
        "XDMA_LOADED_COUNT=0",
        "XDMA_DRIVER_SYSFS_PCI=ABSENT",
        "XDMA_DRIVER_SYSFS_PLATFORM=ABSENT",
        "XDMA_DEVICE_NODE_COUNT=0",
        "MODULE_LOADS=0",
        "DRIVER_BINDS=0",
        "DRIVER_UNBINDS=0",
        "MMIO_READS=0",
        "MMIO_WRITES=0",
        "DMA_OPERATIONS=0",
    ],
)

t1_rel = "raw/T1_DRIVER_GATE_DECISION.json"
t1 = documents[t1_rel]
for name, keys, expected in [
    ("t1_task", ("task",), TASK),
    ("t1_result", ("result",), "BLOCKED"),
    ("t1_gate", ("t1_warm_reboot_endpoint_gate",), "BLOCKED"),
    ("t1_first_blocker", ("first_blocker",), FIRST_BLOCKER),
    ("t1_warm_reboot", ("passed_subgates", "warm_reboot"), "PASS"),
    ("t1_reconnect", ("passed_subgates", "exact_ip_reconnect"), "PASS"),
    ("t1_boot_transition", ("passed_subgates", "exactly_one_boot_transition"), "PASS"),
    ("t1_exclusivity", ("passed_subgates", "post_reboot_exclusivity"), "PASS"),
    ("t1_retention", ("passed_subgates", "candidate_retention"), "PASS"),
    ("t1_endpoint", ("passed_subgates", "endpoint_enumeration"), "PASS"),
    ("t1_correlation", ("passed_subgates", "jtag_to_pcie_correlation"), "PASS"),
    ("t1_gen2", ("passed_subgates", "pcie_gen2_x1"), "PASS"),
    ("t1_safe_bind", ("blocked_subgates", "safe_ahd_xdma_bind"), "BLOCKED"),
    ("t1_node_map", ("blocked_subgates", "xdma_node_to_bdf_mapping"), "NOT_REACHED"),
    ("t1_module_path", ("installed_module", "path"), XDMA_MODULE_PATH),
    ("t1_module_hash", ("installed_module", "sha256"), XDMA_MODULE_SHA256),
    ("t1_module_name", ("installed_module", "name"), "xdma"),
    ("t1_module_aliases", ("installed_module", "bus_aliases"), ["platform:xdma"]),
    ("t1_platform_devices", ("installed_module", "matching_platform_devices"), 0),
    ("t1_pci_modalias_match", ("installed_module", "matches_ahd_pci_modalias"), False),
    ("t1_modalias_resolution", ("installed_module", "exact_pci_modalias_resolution_exit_code"), 1),
    ("t1_decision", ("decision",), "DO_NOT_LOAD_OR_BIND"),
    ("t1_module_loaded", ("xdma_module_loaded_during_r2",), False),
    ("t1_binds", ("driver_bind_operations",), 0),
    ("t1_unbinds", ("driver_unbind_operations",), 0),
    ("t1_mmio_reads", ("mmio_reads",), 0),
    ("t1_mmio_writes", ("mmio_writes",), 0),
    ("t1_dma", ("dma_operations",), 0),
    ("t2_not_reached", ("downstream_gates", "T2"), "NOT_REACHED"),
    ("t3_not_reached", ("downstream_gates", "T3"), "NOT_REACHED"),
    ("t4_not_reached", ("downstream_gates", "T4"), "NOT_REACHED"),
    ("t5_not_reached", ("downstream_gates", "T5"), "NOT_REACHED"),
]:
    exact(name, t1, keys, expected, t1_rel)
require_hash_link(
    "t1_hash_correlation",
    dig(t1, "source_sha256", "POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json"),
    correlation_rel,
    t1_rel,
)
require_hash_link(
    "t1_hash_feasibility",
    dig(t1, "source_sha256", "XDMA_BINDING_FEASIBILITY_READONLY.log"),
    feasibility_rel,
    t1_rel,
)


# Final JTAG/Linux state and required Linux-then-controller lock release order.
check_jtag_csv("raw/JTAG_FINAL_SESSION.csv", 3)
require_markers(
    "final_jtag_zero_programming",
    "raw/JTAG_FINAL_VIVADO.log",
    [
        "SAMPLE_1_DONE=1",
        "SAMPLE_2_DONE=1",
        "SAMPLE_3_DONE=1",
        "SAMPLE_4_DONE=1",
        "SAMPLE_5_DONE=1",
        "FPGA_PROGRAM_OPERATIONS_THIS_SESSION=0",
    ],
)

final_log_rel = "raw/FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log"
require_markers(
    "final_dut_exact_controlled_stop_state",
    final_log_rel,
    [
        "RESULT=PASS",
        f"HOSTNAME={DUT_HOSTNAME}",
        f"BOOT_ID={POST_BOOT_ID}",
        "EXACT_AHD_ENDPOINT_COUNT=1",
        f"ENDPOINT_BDF={ENDPOINT_BDF}",
        "ENDPOINT_VENDOR_DEVICE=0x10ee:0x7011",
        "ENDPOINT_SUBSYSTEM=0x10ee:0x0007",
        "ENDPOINT_CLASS=0x058000",
        f"UPSTREAM_BDF={UPSTREAM_BDF}",
        "ENDPOINT_CURRENT_LINK_SPEED=5.0 GT/s PCIe",
        "ENDPOINT_CURRENT_LINK_WIDTH=1",
        f"XDMA_MODULE_PATH={XDMA_MODULE_PATH}",
        f"XDMA_MODULE_SHA256={XDMA_MODULE_SHA256.lower()}",
        "XDMA_LOADED_COUNT=0",
        "XDMA_PCI_DRIVER_SYSFS=ABSENT",
        "XDMA_PLATFORM_DRIVER_SYSFS=ABSENT",
        "XDMA_DEVICE_NODE_COUNT=0",
        f"FIRST_BLOCKER={FIRST_BLOCKER}",
        "CANDIDATE_RETAINED_ACROSS_WARM_REBOOT=PASS",
        "FINAL_JTAG_DONE=1",
        "WARM_REBOOTS_EXECUTED=1",
        "SECOND_REBOOT_ATTEMPTED=NO",
        "POWER_CYCLES_EXECUTED=0",
        "SRAM_PROGRAM_OPERATIONS_IN_R2=0",
        "FLASH_PROGRAM_OPERATIONS=0",
        "XDMA_MODULE_LOADS_IN_R2=0",
        "DRIVER_BINDS_IN_R2=0",
        "DRIVER_UNBINDS_IN_R2=0",
        "MMIO_READS=0",
        "MMIO_WRITES=0",
        "DMA_OPERATIONS=0",
        "STREAM_ENABLE_WRITES=0",
        "PCI_RESCANS=0",
        "PCI_RESETS=0",
    ],
)

final_rel = "raw/FINAL_STATE_VALIDATION.json"
final_state = documents[final_rel]
expected_final_fpga = (
    "xc7a35t IDCODE 0362D093 index 0; five final DONE=1 samples; "
    "candidate retained in volatile SRAM; zero R2 programming operations"
)
expected_final_pcie = (
    "0000:01:00.0 10ee:7011 subsystem 10ee:0007 class 058000 behind "
    "0000:00:01.1; Gen2 x1; unbound; xdma unloaded; zero xdma nodes"
)
for name, keys, expected in [
    ("final_validation_task", ("task",), TASK),
    ("final_validation_result", ("result",), "PASS"),
    ("final_engineering_gate", ("engineering_gate",), "BLOCKED"),
    ("final_first_blocker", ("first_blocker",), FIRST_BLOCKER),
    ("final_fpga_state", ("final_fpga_state",), expected_final_fpga),
    ("final_pcie_state", ("final_pcie_driver_state",), expected_final_pcie),
    ("final_jtag_gate", ("final_jtag_gate",), "PASS"),
    ("final_linux_gate", ("final_linux_state_gate",), "PASS"),
    ("final_linux_lock_pre_release", ("linux_lock",), "HELD_PENDING_RELEASE"),
    ("final_controller_lock_pre_release", ("controller_lock",), "HELD_PENDING_LAST_RELEASE"),
]:
    exact(name, final_state, keys, expected, final_rel)

zero_final_counts = {
    "power_cycles": 0,
    "sram_programs_r2": 0,
    "flash_programs": 0,
    "xdma_module_loads": 0,
    "driver_binds": 0,
    "driver_unbinds": 0,
    "mmio_reads": 0,
    "mmio_writes": 0,
    "dma_operations": 0,
    "stream_enable_writes": 0,
    "pcie_rescans": 0,
    "pcie_resets": 0,
}
exact("final_count_warm_reboots", final_state, ("operation_counts", "warm_reboots"), 1, final_rel)
for count_name, expected_value in zero_final_counts.items():
    exact(
        f"final_zero_operation::{count_name}",
        final_state,
        ("operation_counts", count_name),
        expected_value,
        final_rel,
    )
for link_name, declared_key, target in [
    ("final_hash_linux_state", "final_linux_state", final_log_rel),
    ("final_hash_jtag_csv", "final_jtag_csv", "raw/JTAG_FINAL_SESSION.csv"),
    ("final_hash_jtag_device", "final_jtag_device", "raw/JTAG_FINAL_DEVICE_PROPERTIES.tsv"),
    ("final_hash_t1", "t1_decision", t1_rel),
]:
    require_hash_link(link_name, dig(final_state, "source_sha256", declared_key), target, final_rel)

before_release_rel = "locks/CONTROLLER_LOCK_BEFORE_LINUX_RELEASE.json"
before_release = documents[before_release_rel]
for name, keys, expected in [
    ("release_precondition_controller_state", ("state",), "HELD"),
    ("release_precondition_state", ("release_state",), "READY_FOR_LINUX_LOCK_RELEASE"),
    ("release_precondition_revision", ("controller_lock_revision",), 7),
    ("release_precondition_linux_lock", ("linux_post_reboot_lock_state",), "HELD"),
    ("release_precondition_engineering", ("engineering_gate",), "BLOCKED"),
    ("release_precondition_blocker", ("first_blocker",), FIRST_BLOCKER),
    ("release_precondition_validation", ("final_state_validation",), "PASS"),
    ("release_precondition_module_loads", ("xdma_module_loads_in_r2",), 0),
    ("release_precondition_binds", ("driver_binds_in_r2",), 0),
    ("release_precondition_mmio_reads", ("mmio_reads",), 0),
    ("release_precondition_mmio_writes", ("mmio_writes",), 0),
    ("release_precondition_dma", ("dma_operations",), 0),
]:
    exact(name, before_release, keys, expected, before_release_rel)

linux_release_receipt_rel = "locks/LINUX_LOCK_POST_REBOOT_RELEASE_RECEIPT.json"
linux_release = documents[linux_release_receipt_rel]
for name, keys, expected in [
    ("linux_release_task", ("task_id",), TASK),
    ("linux_release_candidate", ("candidate_bitstream_sha256",), CANDIDATE_SHA256),
    ("linux_release_pre_boot", ("pre_reboot_boot_id",), PRE_BOOT_ID),
    ("linux_release_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
    ("linux_release_warm", ("warm_reboots_executed",), 1),
    ("linux_release_budget", ("authorized_reboot_budget_remaining",), 0),
    ("linux_release_power", ("power_cycles_executed",), 0),
    ("linux_release_sram", ("sram_program_operations_in_r2",), 0),
    ("linux_release_flash", ("flash_program_operations",), 0),
    ("linux_release_controller_held", ("controller_lock_state",), "HELD"),
    ("linux_release_state", ("lock_release_state",), "RELEASED_AFTER_FINAL_STATE_CAPTURE"),
    ("linux_release_bdf", ("exact_ahd_endpoint_bdf",), ENDPOINT_BDF),
    ("linux_release_endpoint", ("final_endpoint_state",), "10ee:7011 Gen2 x1 UNBOUND"),
    ("linux_release_xdma", ("final_xdma_state",), "MODULE_UNLOADED; PCI_DRIVER_ABSENT; DEVICE_NODES_0"),
    ("linux_release_jtag", ("final_jtag_state",), "xc7a35t 0362D093 index0 DONE1"),
    ("linux_release_blocker", ("first_blocker",), FIRST_BLOCKER),
]:
    exact(name, linux_release, keys, expected, linux_release_receipt_rel)
require_markers(
    "linux_lock_release_operation",
    "raw/LINUX_LOCK_POST_REBOOT_RELEASE.log",
    [
        "RESULT=PASS",
        '"lock_release_state": "RELEASED_AFTER_FINAL_STATE_CAPTURE"',
        f'"first_blocker": "{FIRST_BLOCKER}"',
        "LINUX_LOCK_PRESENT_AFTER_RELEASE=NO",
        "LINUX_LOCK_RELEASE_RESULT=PASS",
    ],
)

after_linux_release_rel = "locks/CONTROLLER_LOCK_AFTER_LINUX_RELEASE.json"
after_linux_release = documents[after_linux_release_rel]
for name, keys, expected in [
    ("after_linux_release_controller_state", ("state",), "HELD"),
    ("after_linux_release_state", ("release_state",), "READY_FOR_CONTROLLER_LOCK_RELEASE"),
    ("after_linux_release_revision", ("controller_lock_revision",), 8),
    ("after_linux_release_linux_state", ("linux_post_reboot_lock_state",), "RELEASED_AFTER_FINAL_STATE_CAPTURE"),
    ("after_linux_release_engineering", ("engineering_gate",), "BLOCKED"),
    ("after_linux_release_blocker", ("first_blocker",), FIRST_BLOCKER),
]:
    exact(name, after_linux_release, keys, expected, after_linux_release_rel)
require_hash_link(
    "after_linux_release_hash_receipt",
    dig(after_linux_release, "linux_post_reboot_lock_release_receipt_sha256"),
    linux_release_receipt_rel,
    after_linux_release_rel,
)

controller_release_receipt_rel = "raw/CONTROLLER_LOCK_RELEASE_RECEIPT.json"
controller_release = documents[controller_release_receipt_rel]
for name, keys, expected in [
    ("controller_release_task", ("task",), TASK),
    ("controller_release_candidate", ("candidate_sha256",), CANDIDATE_SHA256),
    ("controller_release_pre_boot", ("pre_reboot_boot_id",), PRE_BOOT_ID),
    ("controller_release_post_boot", ("post_reboot_boot_id",), POST_BOOT_ID),
    ("controller_release_maximum", ("maximum_warm_reboots",), 1),
    ("controller_release_remote_attempts", ("remote_reboot_command_delivery_attempts",), 1),
    ("controller_release_remote_deliveries", ("remote_reboot_command_deliveries",), 1),
    ("controller_release_warm", ("warm_reboots_executed",), 1),
    ("controller_release_budget_consumed", ("reboot_budget_consumed",), True),
    ("controller_release_budget", ("authorized_reboot_budget_remaining",), 0),
    ("controller_release_status", ("remote_reboot_command_status",), "EXECUTION_CONFIRMED_NO_RETRY"),
    ("controller_release_state", ("state",), "RELEASED"),
    ("controller_release_release_state", ("release_state",), "RELEASED_AFTER_FINAL_STATE_CAPTURE"),
    ("controller_release_revision", ("controller_lock_revision",), 9),
    ("controller_release_linux_state", ("linux_post_reboot_lock_state",), "RELEASED_AFTER_FINAL_STATE_CAPTURE"),
    ("controller_release_engineering", ("engineering_gate",), "BLOCKED"),
    ("controller_release_blocker", ("first_blocker",), FIRST_BLOCKER),
    ("controller_release_module_loads", ("xdma_module_loads_in_r2",), 0),
    ("controller_release_binds", ("driver_binds_in_r2",), 0),
    ("controller_release_mmio_reads", ("mmio_reads",), 0),
    ("controller_release_mmio_writes", ("mmio_writes",), 0),
    ("controller_release_dma", ("dma_operations",), 0),
    ("controller_release_absent", ("final_controller_lock_present_after_release",), False),
]:
    exact(name, controller_release, keys, expected, controller_release_receipt_rel)
require_hash_link(
    "controller_release_hash_linux_receipt",
    dig(controller_release, "linux_post_reboot_lock_release_receipt_sha256"),
    linux_release_receipt_rel,
    controller_release_receipt_rel,
)

release_operation_rel = "raw/CONTROLLER_LOCK_RELEASE_OPERATION.json"
release_operation = documents[release_operation_rel]
for name, keys, expected in [
    ("controller_release_operation_task", ("task",), TASK),
    ("controller_release_operation_result", ("result",), "PASS"),
    ("controller_release_operation_directory", ("resolved_lock_directory",), r"C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK"),
    ("controller_release_operation_recursive", ("recursive_delete_used",), False),
    ("controller_release_operation_receipt", ("receipt_removed_exactly",), True),
    ("controller_release_operation_empty_dir", ("empty_directory_removed_exactly",), True),
    ("controller_release_operation_absent", ("controller_lock_present_after_release",), False),
    ("controller_release_operation_linux_first", ("linux_lock_released_first",), True),
    ("controller_release_operation_controller_last", ("controller_lock_released_last",), True),
]:
    exact(name, release_operation, keys, expected, release_operation_rel)
require_hash_link(
    "controller_release_operation_hash_receipt",
    dig(release_operation, "release_receipt_sha256"),
    controller_release_receipt_rel,
    release_operation_rel,
)
controller_lock_path = Path(r"C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK")
add_check(
    "controller_lock_currently_absent_after_recorded_release",
    not controller_lock_path.exists(),
    {"path": str(controller_lock_path), "exists": controller_lock_path.exists()},
    {"path": str(controller_lock_path), "exists": False},
    release_operation_rel,
)


# Cross-document count and identity consensus.  These checks make later edits to
# one receipt fail even if that receipt remains individually well-formed.
warm_reboot_consensus = {
    "confirmation": dig(confirmation, "warm_reboots_executed"),
    "controller_confirmation": dig(controller_confirm, "warm_reboots_executed"),
    "linux_lock": dig(linux_lock, "warm_reboots_executed"),
    "combined_lock": dig(combined, "warm_reboots_executed"),
    "final_state": dig(final_state, "operation_counts", "warm_reboots"),
    "linux_release": dig(linux_release, "warm_reboots_executed"),
    "controller_release": dig(controller_release, "warm_reboots_executed"),
}
add_check(
    "one_warm_reboot_consensus",
    set(warm_reboot_consensus.values()) == {1},
    warm_reboot_consensus,
    "all authoritative receipts equal 1",
    [confirmation_rel, controller_confirm_rel, linux_lock_rel, combined_rel, final_rel, linux_release_receipt_rel, controller_release_receipt_rel],
)

post_boot_consensus = {
    "confirmation": dig(confirmation, "post_reboot_boot_id"),
    "controller_confirmation": dig(controller_confirm, "post_reboot_boot_id"),
    "linux_lock": dig(linux_lock, "post_reboot_boot_id"),
    "combined_lock": dig(combined, "post_reboot_boot_id"),
    "linux_release": dig(linux_release, "post_reboot_boot_id"),
    "controller_release": dig(controller_release, "post_reboot_boot_id"),
}
add_check(
    "post_boot_id_consensus",
    set(post_boot_consensus.values()) == {POST_BOOT_ID},
    post_boot_consensus,
    POST_BOOT_ID,
    [confirmation_rel, controller_confirm_rel, linux_lock_rel, combined_rel, linux_release_receipt_rel, controller_release_receipt_rel],
)

blocker_consensus = {
    "t1": dig(t1, "first_blocker"),
    "final_state": dig(final_state, "first_blocker"),
    "linux_release": dig(linux_release, "first_blocker"),
    "controller_release": dig(controller_release, "first_blocker"),
}
add_check(
    "first_blocker_consensus",
    all(same_exact_blocker(value) for value in blocker_consensus.values()),
    blocker_consensus,
    FIRST_BLOCKER,
    [t1_rel, final_rel, linux_release_receipt_rel, controller_release_receipt_rel],
)


failed_checks = [item for item in checks if item["result"] != "PASS"]
validation_result = "PASS" if not failed_checks else "FAIL"
validator_bytes = Path(__file__).read_bytes()

exact_final_outcomes = {
    "task": TASK,
    "project_state_rev_at_start": 8,
    "raw_execution_validation": validation_result,
    "engineering_gate": "BLOCKED",
    "overall_result": "BLOCKED",
    "first_blocker": FIRST_BLOCKER,
    "T0_pre_reboot_authority_exclusivity_gate": "PASS",
    "T1_warm_reboot_endpoint_gate": "BLOCKED",
    "T2_runtime_mmio_gate": "NOT_REACHED",
    "T3_one_record_gate": "NOT_REACHED",
    "T4_finite_capture_gate": "NOT_REACHED",
    "T5_continuous_capture_gate": "NOT_REACHED",
    "warm_reboots_executed": 1,
    "maximum_warm_reboots": 1,
    "authorized_reboot_budget_remaining": 0,
    "pre_reboot_boot_id": PRE_BOOT_ID,
    "post_reboot_boot_id": POST_BOOT_ID,
    "authenticated_boot_id_change": "PASS",
    "candidate_retained_across_warm_reboot": "PASS",
    "final_jtag_state": "xc7a35t 0362D093 index0 DONE1",
    "endpoint": {
        "bdf": ENDPOINT_BDF,
        "vendor_device": ENDPOINT_VENDOR_DEVICE,
        "subsystem": ENDPOINT_SUBSYSTEM,
        "class": ENDPOINT_CLASS,
        "upstream_bdf": UPSTREAM_BDF,
        "actual_link": "Gen2 x1",
        "jtag_to_pcie_correlation": "PASS",
        "driver": "UNBOUND",
    },
    "xdma": {
        "module_path": XDMA_MODULE_PATH,
        "module_sha256": XDMA_MODULE_SHA256,
        "bus_aliases": ["platform:xdma"],
        "matching_platform_devices": 0,
        "exact_pci_modalias_resolution_exit_code": 1,
        "safe_bind_gate": "BLOCKED",
        "decision": "DO_NOT_LOAD_OR_BIND",
        "module_loaded_during_r2": False,
        "device_node_count": 0,
    },
    "operation_counts": {
        "power_cycles": 0,
        "sram_programs_r2": 0,
        "flash_programs": 0,
        "xdma_module_loads": 0,
        "driver_binds": 0,
        "driver_unbinds": 0,
        "mmio_reads": 0,
        "mmio_writes": 0,
        "dma_operations": 0,
        "stream_enable_writes": 0,
        "pcie_rescans": 0,
        "pcie_resets": 0,
    },
    "final_candidate_state": "RETAINED_IN_VOLATILE_SRAM",
    "linux_lock_release": "PASS_AFTER_FINAL_STATE_CAPTURE",
    "controller_lock_release": "PASS_LAST",
}

report = {
    "schema": "AHD_V41_G2B_HW0_PRODUCT_R2_RAW_EXECUTION_VALIDATION_V1",
    "task": TASK,
    "generated_at_utc": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
    "validation_scope": "LOCAL_PRESERVED_R2_RAW_EVIDENCE_ONLY; NO_DUT_OR_REPOSITORY_ACCESS",
    "result": validation_result,
    "engineering_gate": "BLOCKED",
    "first_blocker": FIRST_BLOCKER,
    "validator": {
        "path": "tools/validate_raw_r2_execution.py",
        "sha256": sha256_bytes(validator_bytes),
        "bytes": len(validator_bytes),
        "fail_closed": True,
    },
    "summary": {
        "checks_total": len(checks),
        "checks_passed": len(checks) - len(failed_checks),
        "checks_failed": len(failed_checks),
        "required_sources": len(REQUIRED_SOURCES),
        "source_hashes_recorded": sum(1 for value in source_hashes.values() if value.get("sha256")),
    },
    "exact_final_outcomes": exact_final_outcomes,
    "source_hashes": source_hashes,
    "checks": checks,
    "failed_check_names": [item["name"] for item in failed_checks],
}

OUTPUT.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"result": validation_result, **report["summary"], "output": str(OUTPUT)}, ensure_ascii=False))
sys.exit(0 if validation_result == "PASS" else 1)
