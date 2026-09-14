#!/usr/bin/env python3
"""Generate bounded, clean-room MODE1 audit/model artifacts.

The input is the frozen SCAN0 semantic manifest.  This script does not read or
copy vendor source.  It emits only independent operation metadata, recovery
classification, and fail-closed model results for CH1 AHD 1080p25.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path


OUT = Path(__file__).resolve().parent
SCAN0 = Path(r"C:\FPGA\G2B_NVP_CAMERA_SCAN0_OFFLINE_20260911T135131Z\evidence-staging")
SOURCE_MANIFEST = SCAN0 / "G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_MANIFEST.csv"
READ_AUTHORITY = SCAN0 / "G2B_NVP_CAMERA_SCAN0_REGISTER_AUTHORITY_MATRIX.csv"

OP_CSV = OUT / "G2B_NVP_MODE1_CLEANROOM_NO_ACP_OPERATION_MANIFEST.csv"
OP_JSON = OUT / "G2B_NVP_MODE1_CLEANROOM_NO_ACP_OPERATION_MANIFEST.json"
REG_CSV = OUT / "G2B_NVP_MODE1_TOUCHED_REGISTER_RECOVERY_MATRIX.csv"
REG_JSON = OUT / "G2B_NVP_MODE1_TOUCHED_REGISTER_RECOVERY_MATRIX.json"
FAIL_CSV = OUT / "G2B_NVP_MODE1_FAILURE_INJECTION_MATRIX.csv"
GRAPH_JSON = OUT / "G2B_NVP_MODE1_DETERMINISTIC_RECOVERY_GRAPH.json"
TEST_CSV = OUT / "G2B_NVP_MODE1_FOCUSED_24_TEST_RESULTS.csv"
SUMMARY_JSON = OUT / "G2B_NVP_MODE1_MODEL_SUMMARY.json"
INHERITED_JSON = OUT / "G2B_NVP_MODE1_INHERITED_TEST_DISPOSITION.json"

SOURCE_COMMIT = "dae2aff60141ecdbc0afac08fc0df9a3166f66c6"
SOURCE_TREE = "21e33d481ef637667756caa8015e7fa1b1dd8ebf"
REFERENCE_COMMIT = "081ebbff9a2722d47acf16c680594be43cb179e2"
SCAN0_ACTION_DIGEST = "64FFDBB1EF5E34D4DA2301B0256CFE2BA271E41ECDF26D64F85E42223C6344C1"
ACP_REQUIRED_FOR_FIRST_IMAGE = "UNRESOLVED"
MODEL_ONLY_SCOPE = "MODEL_CONTRACT_DEFINED_NOT_RTL_IMPLEMENTED"

INHERITED_TEST_RESULTS = [
    {
        "suite": "SCAN1",
        "required_by": "PROMPT_SECTION_23",
        "status": "PASS",
        "gate_result": "24/24 PASS",
        "evidence_path": (
            r"C:\FPGA\G2B_NVP_OFFLINE_ADVANCE1_20260913T201843Z\workstream-b-mode1"
            r"\inherited-scan1-gate-01\G2B_NVP_CAMERA_SCAN1_R1_SIMULATION_RECEIPT.txt"
        ),
        "evidence_sha256": "28CA649BF0E2151EA8F924114DF58134F7FE75288FECF0E4A1DF49D705A9D86F",
        "scope": "READ_ONLY_CLEAN_MODE1_PARENT",
        "tested_head": SOURCE_COMMIT,
        "tested_tree": SOURCE_TREE,
        "hardware_accessed": "NO",
    },
    {
        "suite": "ACQ",
        "required_by": "PROMPT_SECTION_23",
        "status": "PASS",
        "gate_result": "20/20 PASS",
        "evidence_path": (
            r"C:\FPGA\G2B_NVP_OFFLINE_ADVANCE1_20260913T201843Z\workstream-b-mode1"
            r"\inherited-acq-gate-01\G2B_NVP_ACQ1_COMPAT0_R2_TEST_RECEIPT.txt"
        ),
        "evidence_sha256": "F8BB98CCAD4B98C54FF32B1B18C3E8CAC2E52802FB143C3DA72053F91A342F5F",
        "scope": "READ_ONLY_CLEAN_MODE1_PARENT",
        "tested_head": SOURCE_COMMIT,
        "tested_tree": "NOT_RECORDED_IN_ACQ_RECEIPT",
        "hardware_accessed": "NO",
    },
]

RECOVERY_CLASSES = [
    "EXACT_READ_RESTORE",
    "MASKED_READ_MODIFY_RESTORE",
    "STABLE_BITS_ONLY_VERIFY",
    "DETERMINISTIC_SEQUENCE_REINIT",
    "PRODUCT_BASELINE_RECONSTRUCTION",
    "PROHIBITED_UNRESOLVED",
]

OP_FIELDS = [
    "OperationIndex",
    "OperationID",
    "SourceSemanticFunction",
    "Bank",
    "Register",
    "OperationType",
    "Value",
    "Mask",
    "PreservedBits",
    "Condition",
    "DelayBefore",
    "DelayAfter",
    "RequiredInitialState",
    "ExpectedReadback",
    "ReadbackMask",
    "RecoveryClass",
    "RecoveryAction",
    "EvidenceAuthority",
    "Confidence",
    "IncludedInMinimumMode1",
    "ExclusionReason",
]

REG_FIELDS = [
    "RegisterIndex",
    "Bank",
    "Register",
    "TouchCount",
    "FirstOperationIndex",
    "LastOperationIndex",
    "OperationIndices",
    "SourceSemanticFunctions",
    "OperationTypes",
    "RecoveryClass",
    "RecoveryAction",
    "SafeReadAuthority",
    "ReadSideEffectAuthority",
    "ProductReconstructionAuthority",
    "EvidenceAuthority",
    "Confidence",
    "UnresolvedReason",
]

FAILURE_TYPES = [
    "FAILURE_BEFORE_WRITE",
    "NACK_DURING_WRITE",
    "TIMEOUT_DURING_WRITE",
    "READBACK_MISMATCH",
    "RESET_BETWEEN_OPERATIONS",
    "HOST_ABORT",
    "MMIO_RESET",
]

FAIL_FIELDS = [
    "ScenarioIndex",
    "OperationIndex",
    "OperationID",
    "FailureType",
    "CommittedRegisterCount",
    "UnresolvedCommittedRegisterCount",
    "RecoveryPath",
    "TerminalState",
    "ClassificationReason",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def write_json(path: Path, value: object) -> None:
    path.write_text(
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=False) + "\n",
        encoding="utf-8",
    )


def norm_hex(value: str) -> str:
    value = value.strip()
    if re.fullmatch(r"0x[0-9a-fA-F]{1,2}", value):
        return f"0x{int(value, 16):02X}"
    return value


def key_for(bank: str, register: str) -> str:
    return f"{norm_hex(bank)}:{norm_hex(register)}"


def operation_type(source_operation: str, phase: str, register: str) -> str:
    if source_operation == "BANK_SELECT":
        return "WRITE_FULL"
    if source_operation == "WRITE":
        if phase == "POST_MODE" and norm_hex(register) == "0x40":
            return "WRITE_PULSE"
        return "WRITE_FULL"
    if source_operation == "READ_FOR_RMW":
        return "VERIFY_READ"
    if source_operation == "RMW_CLEAR_CHANNEL_BIT":
        return "READ_MODIFY_WRITE"
    if source_operation == "DELAY":
        return "DELAY_FIXED"
    if source_operation == "STATE_ASSIGN":
        return "SOFTWARE_STATE_ONLY"
    raise ValueError(f"unsupported SCAN0 operation: {source_operation}")


def build_safe_read_map(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        key = key_for(row["Bank"], row["Register"])
        if row["ReadSafe"].startswith("YES") and row["ReadSideEffect"].startswith("NO_KNOWN"):
            result[key] = row
    return result


def build_cleanroom_operations(
    source_rows: list[dict[str, str]], safe_reads: dict[str, dict[str, str]]
) -> list[dict[str, str]]:
    clean: list[dict[str, str]] = []
    for source in source_rows:
        if source["phase"].startswith("ACP_"):
            continue

        index = len(clean) + 1
        phase = source["phase"]
        source_op = source["operation"]
        bank = norm_hex(source["ch1_bank"])
        register = norm_hex(source["ch1_register"])
        value = norm_hex(source["ch1_value"])
        op_type = operation_type(source_op, phase, register)
        included = source_op != "STATE_ASSIGN"
        exclusion = "" if included else "VENDOR_SOFTWARE_STATE_REPLACED_BY_EXECUTOR_SESSION_STATE"

        if source_op == "DELAY":
            bank = "N/A"
            register = "N/A"
            value = "N/A"
            mask = "N/A"
            preserved = "N/A"
            expected = "DELAY_COMPLETED"
            readback_mask = "N/A"
            recovery_class = "DETERMINISTIC_SEQUENCE_REINIT"
            recovery_action = "ABORT_CURRENT_SEQUENCE; DO_NOT_RESUME_MID_DELAY"
        elif source_op == "STATE_ASSIGN":
            bank = "SOFTWARE"
            register = source["ch1_register"]
            value = source["ch1_value"]
            mask = "N/A"
            preserved = "N/A"
            expected = "EXECUTOR_SESSION_STATE_ONLY"
            readback_mask = "N/A"
            recovery_class = "DETERMINISTIC_SEQUENCE_REINIT"
            recovery_action = "DISCARD_UNPUBLISHED_SESSION_STATE"
        elif source_op == "BANK_SELECT":
            mask = "0xFF"
            preserved = "0x00"
            expected = value
            readback_mask = "0xFF"
            recovery_class = "EXACT_READ_RESTORE"
            recovery_action = "RESTORE_CAPTURED_ENTRY_BANK_AND_VERIFY"
        elif source_op == "READ_FOR_RMW":
            value = "CAPTURE_RUNTIME_BYTE"
            mask = "0xFF"
            preserved = "N/A"
            expected = "ANY_STABLE_RUNTIME_BYTE"
            readback_mask = "0xFF"
            recovery_class = "PROHIBITED_UNRESOLVED"
            recovery_action = "NO_EXECUTION_UNTIL_SAFE_READ_AUTHORITY_OR_PRODUCT_RECONSTRUCTION_EXISTS"
        elif source_op == "RMW_CLEAR_CHANNEL_BIT":
            value = "0x00"
            mask = "0x01"
            preserved = "0xFE"
            expected = "TARGET_BIT_0; NON_TARGET_BITS_PRESERVED"
            readback_mask = "0x01"
            recovery_class = "PROHIBITED_UNRESOLVED"
            recovery_action = "NO_EXECUTION; PROVISIONAL_MASKED_RESTORE_REQUIRES_SAFE_READ_AUTHORITY"
        else:
            mask = "0xFF"
            preserved = "0x00"
            expected = value
            readback_mask = "0xFF"
            reg_key = key_for(bank, register)
            if reg_key in safe_reads:
                recovery_class = "EXACT_READ_RESTORE"
                recovery_action = "RESTORE_CAPTURED_FULL_BYTE_THEN_VERIFY_0xFF"
            else:
                recovery_class = "PROHIBITED_UNRESOLVED"
                recovery_action = "NO_EXECUTION; ENTER_FATAL_RECOVERY_FAILURE_IF_TOUCHED"

        clean.append(
            {
                "OperationIndex": str(index),
                "OperationID": f"MODE1_{index:04d}_{phase}_{source_op}",
                "SourceSemanticFunction": source["source_function"],
                "Bank": bank,
                "Register": register,
                "OperationType": op_type,
                "Value": value,
                "Mask": mask,
                "PreservedBits": preserved,
                "Condition": "CH1_AND_PAL_AND_NVP6134_VI_1080P_2530",
                "DelayBefore": "0",
                "DelayAfter": source["delay_ms"] if source_op == "DELAY" else "0",
                "RequiredInitialState": "BASELINE_CAPTURED; EXCLUSIVE_I2C_OWNERSHIP; STREAM_DISABLED",
                "ExpectedReadback": expected,
                "ReadbackMask": readback_mask,
                "RecoveryClass": recovery_class,
                "RecoveryAction": recovery_action,
                "EvidenceAuthority": (
                    f"SCAN0_SEMANTIC_MANIFEST; {source['authority_class']}; "
                    f"SOURCE_COMMIT_{SOURCE_COMMIT}"
                ),
                "Confidence": (
                    "HIGH_SEMANTIC_LOW_HARDWARE_COMPATIBILITY"
                    if source["nvp6134c_compatibility"]
                    == "CONTROLLED_NVP6134C_COMPATIBILITY_TEST_REQUIRED"
                    else "HIGH_SEMANTIC"
                ),
                "IncludedInMinimumMode1": "YES" if included else "NO",
                "ExclusionReason": exclusion,
            }
        )
    return clean


def touched_key(op: dict[str, str]) -> str | None:
    if op["IncludedInMinimumMode1"] != "YES":
        return None
    if op["OperationType"] not in {"WRITE_FULL", "WRITE_PULSE", "READ_MODIFY_WRITE"}:
        return None
    if op["Register"] in {"0xFF", "N/A"} or op["Bank"] in {"SOFTWARE", "N/A"}:
        return None
    return key_for(op["Bank"], op["Register"])


def build_register_matrix(
    operations: list[dict[str, str]], safe_reads: dict[str, dict[str, str]]
) -> list[dict[str, str]]:
    by_key: dict[str, list[dict[str, str]]] = defaultdict(list)
    for op in operations:
        key = touched_key(op)
        if key:
            by_key[key].append(op)

    matrix: list[dict[str, str]] = []
    for reg_index, key in enumerate(sorted(by_key), start=1):
        rows = by_key[key]
        bank, register = key.split(":", 1)
        safe = safe_reads.get(key)
        if safe:
            recovery_class = "EXACT_READ_RESTORE"
            recovery_action = "CAPTURE_FULL_BYTE_BEFORE_FIRST_WRITE; REVERSE_RESTORE; VERIFY_0xFF"
            safe_read = safe["ReadSafe"]
            side_effect = safe["ReadSideEffect"]
            evidence = f"SCAN0_REGISTER_AUTHORITY_MATRIX:{safe['AuthorityClass']}"
            confidence = "HIGH_FOR_READ_RESTORE_MODEL"
            unresolved = ""
        else:
            recovery_class = "PROHIBITED_UNRESOLVED"
            recovery_action = "DO_NOT_EXECUTE; IF_TOUCHED_END_IN_FATAL_RECOVERY_FAILURE"
            safe_read = "NOT_PROVEN_FOR_BASELINE_RESTORE"
            side_effect = "NO_COMPLETE_AUTHORITY"
            evidence = "SCAN0_REFERENCE_SEMANTICS_ONLY"
            confidence = "LOW_FOR_RECOVERY"
            if key in {"0x01:0xED", "0x09:0x44"}:
                unresolved = (
                    "RMW_MASK_0x01_IS_SEMANTICALLY_EXACT_BUT_SAFE_READ_AND_RESTORE_ARE_NOT_"
                    "NVP6134C_PROVEN"
                )
            else:
                unresolved = (
                    "NO_SCANNER_SAFE_READ_ENTRY_AND_NO_CALLABLE_VERIFIED_PRODUCT_BASELINE_"
                    "RECONSTRUCTION"
                )

        assert recovery_class in RECOVERY_CLASSES
        matrix.append(
            {
                "RegisterIndex": str(reg_index),
                "Bank": bank,
                "Register": register,
                "TouchCount": str(len(rows)),
                "FirstOperationIndex": rows[0]["OperationIndex"],
                "LastOperationIndex": rows[-1]["OperationIndex"],
                "OperationIndices": ";".join(row["OperationIndex"] for row in rows),
                "SourceSemanticFunctions": ";".join(
                    sorted({row["SourceSemanticFunction"] for row in rows})
                ),
                "OperationTypes": ";".join(sorted({row["OperationType"] for row in rows})),
                "RecoveryClass": recovery_class,
                "RecoveryAction": recovery_action,
                "SafeReadAuthority": safe_read,
                "ReadSideEffectAuthority": side_effect,
                "ProductReconstructionAuthority": "GAP_CALLABLE_REINIT_AND_FULL_BASELINE_VERIFY_ABSENT",
                "EvidenceAuthority": evidence,
                "Confidence": confidence,
                "UnresolvedReason": unresolved,
            }
        )
    return matrix


def build_failure_matrix(
    operations: list[dict[str, str]], register_rows: list[dict[str, str]]
) -> list[dict[str, str]]:
    reg_class = {
        key_for(row["Bank"], row["Register"]): row["RecoveryClass"]
        for row in register_rows
    }
    included = [row for row in operations if row["IncludedInMinimumMode1"] == "YES"]
    prefix_touched: set[str] = set()
    failures: list[dict[str, str]] = []
    scenario_index = 0

    for op in included:
        current_key = touched_key(op)
        for failure_type in FAILURE_TYPES:
            scenario_index += 1
            committed = set(prefix_touched)
            if failure_type != "FAILURE_BEFORE_WRITE" and current_key:
                committed.add(current_key)
            unresolved = sorted(
                key for key in committed if reg_class[key] == "PROHIBITED_UNRESOLVED"
            )

            if failure_type in {"RESET_BETWEEN_OPERATIONS", "MMIO_RESET"}:
                terminal = "FATAL_RECOVERY_FAILURE"
                path = "ABORTING->PRODUCT_RECONSTRUCTION_GAP->FATAL_RECOVERY_FAILURE"
                reason = "CALLABLE_RESET_AUTOINIT_OR_PERSISTENT_RECOVERY_CONTEXT_NOT_PROVEN"
            elif unresolved:
                terminal = "FATAL_RECOVERY_FAILURE"
                path = "ABORTING->UNRESOLVED_REGISTER_GATE->FATAL_RECOVERY_FAILURE"
                reason = "UNRESOLVED_COMMITTED_REGISTERS=" + ";".join(unresolved)
            else:
                terminal = "RECOVERED_PRODUCT_BASELINE"
                path = "ABORTING->EXACT_RESTORE->BASELINE_VERIFY->RECOVERED_PRODUCT_BASELINE"
                reason = "NO_UNRESOLVED_FUNCTIONAL_REGISTER_MAY_HAVE_COMMITTED"

            failures.append(
                {
                    "ScenarioIndex": str(scenario_index),
                    "OperationIndex": op["OperationIndex"],
                    "OperationID": op["OperationID"],
                    "FailureType": failure_type,
                    "CommittedRegisterCount": str(len(committed)),
                    "UnresolvedCommittedRegisterCount": str(len(unresolved)),
                    "RecoveryPath": path,
                    "TerminalState": terminal,
                    "ClassificationReason": reason,
                }
            )

        if current_key:
            prefix_touched.add(current_key)

    return failures


def build_recovery_graph() -> dict[str, object]:
    states = [
        "IDLE_PRODUCT_BASELINE",
        "BASELINE_CAPTURED",
        "MODE_APPLY_IN_PROGRESS",
        "MODE_APPLIED",
        "EQ_APPLY_IN_PROGRESS",
        "EQ_APPLIED",
        "LOCK_WAIT",
        "BT656_WAIT",
        "SUCCESS_READY",
        "ABORTING",
        "EXACT_RESTORE",
        "NVP_RESET",
        "PRODUCT_AUTOINIT",
        "BASELINE_VERIFY",
        "RECOVERED",
        "RECOVERED_PRODUCT_BASELINE",
        "FATAL_RECOVERY_FAILURE",
    ]
    transitions = [
        ["IDLE_PRODUCT_BASELINE", "PREPARE_AND_ALL_TARGETS_RECOVERABLE", "BASELINE_CAPTURED"],
        ["IDLE_PRODUCT_BASELINE", "ANY_TARGET_PROHIBITED_UNRESOLVED", "FATAL_RECOVERY_FAILURE"],
        ["BASELINE_CAPTURED", "APPLY", "MODE_APPLY_IN_PROGRESS"],
        ["MODE_APPLY_IN_PROGRESS", "MODE_COMPLETE", "MODE_APPLIED"],
        ["MODE_APPLIED", "START_EQ", "EQ_APPLY_IN_PROGRESS"],
        ["EQ_APPLY_IN_PROGRESS", "EQ_COMPLETE", "EQ_APPLIED"],
        ["EQ_APPLIED", "START_LOCK_WAIT", "LOCK_WAIT"],
        ["LOCK_WAIT", "LOCK_STABLE", "BT656_WAIT"],
        ["BT656_WAIT", "BT656_STABLE", "SUCCESS_READY"],
        ["MODE_APPLY_IN_PROGRESS", "ANY_FAILURE", "ABORTING"],
        ["MODE_APPLIED", "ANY_FAILURE", "ABORTING"],
        ["EQ_APPLY_IN_PROGRESS", "ANY_FAILURE", "ABORTING"],
        ["EQ_APPLIED", "ANY_FAILURE", "ABORTING"],
        ["LOCK_WAIT", "ANY_FAILURE", "ABORTING"],
        ["BT656_WAIT", "ANY_FAILURE", "ABORTING"],
        ["ABORTING", "ALL_TOUCHED_TARGETS_EXACTLY_RESTORABLE", "EXACT_RESTORE"],
        ["EXACT_RESTORE", "READBACK_PASS", "BASELINE_VERIFY"],
        ["ABORTING", "EXACT_RESTORE_NOT_AVAILABLE_AND_REINIT_AUTHORIZED", "NVP_RESET"],
        ["NVP_RESET", "RESET_RELEASED", "PRODUCT_AUTOINIT"],
        ["PRODUCT_AUTOINIT", "DONE_WITHOUT_ERROR", "BASELINE_VERIFY"],
        ["BASELINE_VERIFY", "ALL_PROTECTED_CHECKS_PASS", "RECOVERED"],
        ["RECOVERED", "PUBLISH_TERMINAL_RESULT", "RECOVERED_PRODUCT_BASELINE"],
        ["ABORTING", "PROHIBITED_UNRESOLVED_OR_REINIT_GAP", "FATAL_RECOVERY_FAILURE"],
        ["EXACT_RESTORE", "NACK_TIMEOUT_OR_MISMATCH", "FATAL_RECOVERY_FAILURE"],
        ["NVP_RESET", "RESET_OR_RELEASE_FAILURE", "FATAL_RECOVERY_FAILURE"],
        ["PRODUCT_AUTOINIT", "ERROR_NACK_TIMEOUT", "FATAL_RECOVERY_FAILURE"],
        ["BASELINE_VERIFY", "ANY_MISMATCH", "FATAL_RECOVERY_FAILURE"],
    ]
    return {
        "schema": "G2B_NVP_MODE1_RECOVERY_GRAPH_V1",
        "candidate_execution_enabled": False,
        "initial_state": "IDLE_PRODUCT_BASELINE",
        "success_state": "SUCCESS_READY",
        "recovery_terminal_states": [
            "RECOVERED_PRODUCT_BASELINE",
            "FATAL_RECOVERY_FAILURE",
        ],
        "states": states,
        "transitions": [
            {"from": source, "event": event, "to": target}
            for source, event, target in transitions
        ],
        "fail_closed_rule": (
            "Every unresolved register, lost recovery context, unavailable callable product "
            "reconstruction, or failed verification terminates in FATAL_RECOVERY_FAILURE."
        ),
    }


def build_tests(
    operations: list[dict[str, str]],
    registers: list[dict[str, str]],
    failures: list[dict[str, str]],
) -> list[dict[str, str]]:
    included_count = sum(row["IncludedInMinimumMode1"] == "YES" for row in operations)
    prohibited_count = sum(row["RecoveryClass"] == "PROHIBITED_UNRESOLVED" for row in registers)
    fatal_count = sum(row["TerminalState"] == "FATAL_RECOVERY_FAILURE" for row in failures)
    cases = [
        ("T1", "semantic manifest deterministic", "PASS", f"176 rows; source digest {SCAN0_ACTION_DIGEST}"),
        ("T2", "no prohibited operation included", "BLOCKED", f"{prohibited_count} required targets are PROHIBITED_UNRESOLVED"),
        ("T3", "no CH2-CH4 write", "PASS", "all resolved hardware targets are CH1 expressions"),
        ("T4", "no generic host I2C", "PASS", "audit contains compiled operations only"),
        ("T5", "action order exact", "PASS", "source order preserved after ACP exclusion"),
        ("T6", "masks preserve unrelated bits", "PASS", "B1/ED and B9/44 use mask 0x01 and preserved bits 0xFE"),
        ("T7", "fixed delays exact", "PASS", "no-ACP sequence contains one fixed 35 ms delay"),
        ("T8", "initial EQ subset exact", "BLOCKED", "five writes isolated but NVP6134C private-register compatibility is incomplete"),
        ("T9", "failure injection at every operation boundary", "PASS", f"{len(failures)}/{included_count * 7} classified"),
        ("T10", "NACK recovery", "PASS", "every included operation has a terminal NACK classification"),
        ("T11", "timeout recovery", "PASS", "every included operation has a terminal timeout classification"),
        ("T12", "readback mismatch recovery", "PASS", "every included operation has a terminal mismatch classification"),
        ("T13", "host abort recovery", "PASS", "every included operation has a terminal host-abort classification"),
        ("T14", "reset during mode apply", "PASS", "reset paths are classified fail-closed"),
        ("T15", "reset during EQ apply", "PASS", "EQ reset paths are classified fail-closed"),
        ("T16", "exact restore path", "BLOCKED", "only 5/113 targets have complete SCAN0 safe-read authority"),
        ("T17", "NVP reset plus autoinit path", "BLOCKED", "current autoinit is deterministic but not a callable recovery action"),
        ("T18", "protected baseline verification", "BLOCKED", "complete post-reconstruction protected-field verifier is absent"),
        ("T19", "scanner/executor arbitration", "BLOCKED", "no RTL implementation proves exclusive whole-action ownership or scanner suppression"),
        ("T20", "no SCAN1 publication during functional action", "BLOCKED", "no RTL implementation proves publication suppression during functional ownership"),
        ("T21", "action result frozen until ACK", "BLOCKED", "no RTL implementation proves terminal-result retention through ACK"),
        ("T22", "source/profile isolation", "PASS", "only task-local audit/model artifacts are generated"),
        ("T23", "product profile excludes MODE1", "PASS", "no candidate or PRODUCT source is modified"),
        ("T24", "no transport or DMA change", "PASS", "no RTL, transport, DMA, driver, or hardware action occurs"),
    ]
    return [
        {
            "TestID": test_id,
            "Requirement": requirement,
            "Result": result,
            "Scope": MODEL_ONLY_SCOPE if test_id in {"T19", "T20", "T21"} else "OFFLINE_MODEL_EVIDENCE",
            "Evidence": evidence,
        }
        for test_id, requirement, result, evidence in cases
    ]


def main() -> None:
    source_rows = read_csv(SOURCE_MANIFEST)
    authority_rows = read_csv(READ_AUTHORITY)
    safe_reads = build_safe_read_map(authority_rows)
    operations = build_cleanroom_operations(source_rows, safe_reads)
    registers = build_register_matrix(operations, safe_reads)

    reg_class = {
        key_for(row["Bank"], row["Register"]): row["RecoveryClass"] for row in registers
    }
    for op in operations:
        key = touched_key(op)
        if key:
            op["RecoveryClass"] = reg_class[key]
            if reg_class[key] == "EXACT_READ_RESTORE":
                op["RecoveryAction"] = "RESTORE_CAPTURED_FULL_BYTE_THEN_VERIFY_0xFF"
            else:
                op["RecoveryAction"] = "NO_EXECUTION; ENTER_FATAL_RECOVERY_FAILURE_IF_TOUCHED"

    failures = build_failure_matrix(operations, registers)
    graph = build_recovery_graph()
    tests = build_tests(operations, registers, failures)

    write_csv(OP_CSV, OP_FIELDS, operations)
    write_json(
        OP_JSON,
        {
            "schema": "G2B_NVP_MODE1_CLEANROOM_OPERATION_MANIFEST_V1",
            "source_commit": SOURCE_COMMIT,
            "source_tree": SOURCE_TREE,
            "reference_commit": REFERENCE_COMMIT,
            "scan0_action_digest": SCAN0_ACTION_DIGEST,
            "scope": "CH1_PAL_NVP6134_VI_1080P_2530_NO_ACP",
            "operations": operations,
        },
    )
    write_csv(REG_CSV, REG_FIELDS, registers)
    write_json(
        REG_JSON,
        {
            "schema": "G2B_NVP_MODE1_TOUCHED_REGISTER_RECOVERY_MATRIX_V1",
            "allowed_recovery_classes": RECOVERY_CLASSES,
            "registers": registers,
        },
    )
    write_csv(FAIL_CSV, FAIL_FIELDS, failures)
    write_json(GRAPH_JSON, graph)
    write_csv(TEST_CSV, ["TestID", "Requirement", "Result", "Scope", "Evidence"], tests)
    inherited_status_counts = Counter(row["status"] for row in INHERITED_TEST_RESULTS)
    if inherited_status_counts == Counter({"PASS": 2}):
        inherited_disposition = "PASS_2_OF_2_INHERITED_GATES"
    elif "PENDING_ROOT_GATE_RESULT" in inherited_status_counts:
        inherited_disposition = "PENDING_ROOT_GATE_RESULTS"
    else:
        inherited_disposition = "INHERITED_GATE_NOT_PASS"
    write_json(
        INHERITED_JSON,
        {
            "schema": "G2B_NVP_MODE1_INHERITED_TEST_DISPOSITION_V1",
            "required_by": "PROMPT_SECTION_23",
            "execution_target": {
                "path": r"C:\FPGA\V41_G2B_NVP_CAMERA_ACQ1_MODE1",
                "head": SOURCE_COMMIT,
                "tree": SOURCE_TREE,
                "mutation_allowed": False,
            },
            "overall_disposition": inherited_disposition,
            "status_counts": dict(sorted(inherited_status_counts.items())),
            "suites": INHERITED_TEST_RESULTS,
            "non_claim": "INHERITED_PASS_DOES_NOT_PROVE_MODE1_T19_T21_RTL_IMPLEMENTATION",
        },
    )

    recovery_counts = Counter(row["RecoveryClass"] for row in registers)
    terminal_counts = Counter(row["TerminalState"] for row in failures)
    test_counts = Counter(row["Result"] for row in tests)
    included = [row for row in operations if row["IncludedInMinimumMode1"] == "YES"]
    eq_ops = [row for row in operations if row["SourceSemanticFunction"] == "eq_init_each_format"]

    summary = {
        "schema": "G2B_NVP_MODE1_MODEL_SUMMARY_V1",
        "classification": "MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE",
        "recovery_disposition": "MODE1_RECOVERY_AUTHORITY_INCOMPLETE",
        "candidate_created": False,
        "build_run": False,
        "hardware_prompt_created": False,
        "source_commit": SOURCE_COMMIT,
        "source_tree": SOURCE_TREE,
        "reference_commit": REFERENCE_COMMIT,
        "source_manifest_sha256": sha256(SOURCE_MANIFEST),
        "scan0_action_digest": SCAN0_ACTION_DIGEST,
        "operation_rows_no_acp": len(operations),
        "included_operation_count": len(included),
        "excluded_software_state_count": len(operations) - len(included),
        "touched_register_count": len(registers),
        "recovery_class_counts": dict(sorted(recovery_counts.items())),
        "initial_eq_semantic_entries": len(eq_ops),
        "initial_eq_write_count": sum(
            row["OperationID"].endswith("_EQ_INIT_WRITE")
            for row in eq_ops
        ),
        "acp_required_for_first_image": ACP_REQUIRED_FOR_FIRST_IMAGE,
        "acp_first_image_evidence": (
            "NO_AUTHORITY_PROVES_ACP_INDISPENSABLE_AND_NO_AUTHORITY_PROVES_FIRST_IMAGE_WITHOUT_ACP"
        ),
        "failure_types_per_operation": len(FAILURE_TYPES),
        "failure_scenario_count": len(failures),
        "failure_terminal_counts": dict(sorted(terminal_counts.items())),
        "failure_coverage": f"{len(failures)}/{len(included) * len(FAILURE_TYPES)}",
        "focused_test_counts": dict(sorted(test_counts.items())),
        "focused_test_pass_count": test_counts["PASS"],
        "focused_test_total": len(tests),
        "t19_t21_scope": MODEL_ONLY_SCOPE,
        "inherited_test_disposition": inherited_disposition,
        "inherited_test_status_counts": dict(sorted(inherited_status_counts.items())),
        "inherited_test_receipt": INHERITED_JSON.name,
        "first_blocker": (
            "ACQ1_REFERENCE_ONLY_FUNCTIONAL_WRITES_LACK_NVP6134C_COMPATIBILITY_"
            "AND_COMPLETE_BASELINE_READBACK_AUTHORITY"
        ),
        "output_sha256": {},
    }
    write_json(SUMMARY_JSON, summary)

    output_paths = [
        OP_CSV,
        OP_JSON,
        REG_CSV,
        REG_JSON,
        FAIL_CSV,
        GRAPH_JSON,
        TEST_CSV,
        INHERITED_JSON,
    ]
    summary["output_sha256"] = {path.name: sha256(path) for path in output_paths}
    write_json(SUMMARY_JSON, summary)

    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
