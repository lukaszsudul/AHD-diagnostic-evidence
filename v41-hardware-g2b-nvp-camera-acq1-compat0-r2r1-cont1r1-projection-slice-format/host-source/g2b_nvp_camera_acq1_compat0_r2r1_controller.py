"""Fail-closed R2R1 orchestration over the frozen SCAN1 and ACQ controllers.

The command line deliberately exposes no NVP bank, register, mask, value, or
slice-level argument.  Every functional action is one of the seven compiled
executor commands frozen in the R2 source contract.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


BUNDLE_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(BUNDLE_ROOT))


from scan1.controller import ScannerController, self_test as scan1_self_test
from scan1.mmio import MmioDevice

from acq1_compat0_r2 import contract, format_decision, policy
from acq1_compat0_r2.campaign import connected_response_reproduced
from acq1_compat0_r2.controller import (
    Command,
    ExecutorActionError,
    ExecutorController,
    self_test as acq_self_test,
)
from acq1_compat0_r2.evidence import write_json
from acq1_compat0_r2 import mmio as acq_mmio
from cont1r1_projection import (
    configuration_projection as project_configuration,
    manifest_preflight,
    raw_register_map as project_raw_register_map,
    required_projection_keys,
)


TASK_ID = "G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R1"
SOURCE_COMMIT = "dae2aff60141ecdbc0afac08fc0df9a3166f66c6"
SOURCE_TREE = "21e33d481ef637667756caa8015e7fa1b1dd8ebf"
BITSTREAM_SHA256 = "CFA58A46572094209997F6B1A3A5A033BF4E8C8A71EC261A5BBF1833B8BCF91B"

REQUIRED_OUTPUT_DIRECTORIES = (
    "logs",
    "baseline",
    "slice-campaign",
    "format-identification",
    "private",
    "artifacts",
)

HELPER_CONTEXT_EXPECTED = {
    (0x00, 0x81): 0x03,
    (0x00, 0x85): 0x00,
    (0x01, 0x84): 0x00,
    (0x01, 0x8C): 0x40,
}

SLICE_COMMANDS = {
    0x50: Command.ACQ_APPLY_SLICE_50,
    0x40: Command.ACQ_APPLY_SLICE_40,
    0x60: Command.ACQ_APPLY_SLICE_60,
}

SLICE_MASKS = {0x50: 0x1, 0x40: 0x3, 0x60: 0x7}


class R2R1GateError(RuntimeError):
    """A literal R2R1 gate failed."""


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise R2R1GateError(reason)


def canonical_hex(value: int) -> str:
    return f"0x{int(value):02X}"


def raw_register_map(snapshot: dict) -> dict[tuple[int, int], int]:
    return project_raw_register_map(snapshot)


def configuration_projection(snapshot: dict) -> dict[str, int]:
    return project_configuration(snapshot)


def helper_context_projection(snapshot: dict) -> dict[str, int]:
    values = raw_register_map(snapshot)
    require(
        set(HELPER_CONTEXT_EXPECTED).issubset(values),
        "REFERENCE_HELPER_CONTEXT_FIELDS_MISSING",
    )
    return {
        f"{bank:02X}:{register:02X}": values[(bank, register)]
        for bank, register in sorted(HELPER_CONTEXT_EXPECTED)
    }


def credible_ch1_signature(snapshots: list[dict]) -> bool:
    if not snapshots:
        return False
    for snapshot in snapshots:
        ch1 = snapshot["channels"]["CH1"]["private_detector"]
        if not (0xB8 <= int(ch1["F2"]) <= 0xC8 and int(ch1["F3"]) <= 0x0B):
            return False
        for channel in ("CH2", "CH3", "CH4"):
            private = snapshot["channels"][channel]["private_detector"]
            if (int(private["F2"]), int(private["F3"])) != (0, 0):
                return False
    return True


def validate_scan(snapshot: dict, previous_generation: int | None) -> None:
    require(snapshot.get("entry_count") == 82, "SCAN1_ENTRY_COUNT_NOT_82")
    require(snapshot.get("bank_group_count") == 10, "SCAN1_GROUP_COUNT_NOT_10")
    require(snapshot.get("transaction_count") == 105, "SCAN1_TRANSACTION_COUNT_NOT_105")
    require(snapshot.get("entry_bank_restore") == "PASS", "SCAN1_ENTRY_BANK_RESTORE_FAILED")
    require(snapshot.get("entry_bank") == snapshot.get("exit_bank"), "SCAN1_ENTRY_BANK_MISMATCH")
    require(snapshot.get("a8_pre") == snapshot.get("a8_post"), "SCAN1_A8_BOOKEND_MISMATCH")
    require(snapshot.get("live_status_changed") is False, "SCAN1_LIVE_STATUS_CHANGED")
    require(set(snapshot.get("channels", {})) == {"CH1", "CH2", "CH3", "CH4"},
            "SCAN1_CHANNEL_SET_MISMATCH")
    generation = int(snapshot.get("generation", -1))
    if previous_generation is not None:
        require(generation > previous_generation, "SCAN1_GENERATION_NOT_INCREASING")


def scan_summary(phase: str, snapshot: dict, receipt: dict) -> dict:
    channels: dict[str, dict] = {}
    for name, channel in snapshot["channels"].items():
        channels[name] = {
            "novid": int(channel["novid"]),
            "raw_f0": int(channel["raw_f0"]),
            "lock_tuple": {key: int(value) for key, value in channel["lock_tuple"].items()},
            "private_detector": {
                key: int(value) for key, value in channel["private_detector"].items()
            },
            "raw_tuple": [int(value) for value in channel["raw_tuple"]],
        }
    return {
        "phase": phase,
        "generation": int(snapshot["generation"]),
        "entry_count": int(snapshot["entry_count"]),
        "bank_group_count": int(snapshot["bank_group_count"]),
        "transaction_count": int(snapshot["transaction_count"]),
        "entry_bank": int(snapshot["entry_bank"]),
        "exit_bank": int(snapshot["exit_bank"]),
        "entry_bank_restore": snapshot["entry_bank_restore"],
        "a8_pre": int(snapshot["a8_pre"]),
        "a8_post": int(snapshot["a8_post"]),
        "live_status_changed": bool(snapshot["live_status_changed"]),
        "nack_count": 0,
        "timeout_count": 0,
        "bank_verify_failure_count": 0,
        "configuration_projection": configuration_projection(snapshot),
        "channels": channels,
        "snapshot_receipt": receipt,
    }


def validate_error_counters(state: dict, reason: str) -> None:
    require(state["unauthorized_write_count"] == 0, f"{reason}_UNAUTHORIZED_WRITE")
    require(state["nack_count"] == 0, f"{reason}_I2C_NACK")
    require(state["timeout_count"] == 0, f"{reason}_I2C_TIMEOUT")
    require(state["bank_verify_failure_count"] == 0, f"{reason}_BANK_VERIFY_FAILURE")
    require(state["rejected_command_count"] == 0, f"{reason}_REJECTED_COMMAND")


def validate_safe_idle(state: dict, reason: str, allow_closed: bool = False) -> None:
    require(state["idle"], f"{reason}_EXECUTOR_NOT_IDLE")
    require(not state["busy"], f"{reason}_EXECUTOR_BUSY")
    require(not state["hard_fail"], f"{reason}_EXECUTOR_HARD_FAIL")
    require(not state["bank_context_lockout"], f"{reason}_BANK_CONTEXT_LOCKOUT")
    require(not state["scanner_busy"], f"{reason}_SCANNER_BUSY")
    require(state["i2c_bus_idle"], f"{reason}_I2C_BUS_NOT_IDLE")
    if not allow_closed:
        require(not state["campaign_closed"], f"{reason}_CAMPAIGN_ALREADY_CLOSED")
    validate_error_counters(state, reason)


def validate_autoinit(state: dict) -> None:
    status = int(state["status"])
    require(bool(status & acq_mmio.STATUS_AUTOINIT_DONE), "AUTOINIT_DONE_NOT_ONE")
    require(not bool(status & acq_mmio.STATUS_AUTOINIT_BUSY), "AUTOINIT_STILL_BUSY")


def summarize_executor(state: dict) -> dict:
    keys = (
        "status",
        "idle",
        "busy",
        "done",
        "hard_fail",
        "bank_context_lockout",
        "scanner_busy",
        "i2c_bus_idle",
        "command_sequence",
        "completed_sequence",
        "last_result",
        "last_error",
        "last_command",
        "baseline_valid",
        "baseline_pass_count",
        "baseline_mismatch",
        "dryrun_pass",
        "rollback_invoked",
        "rollback_pass",
        "slice_stage",
        "baseline",
        "observed",
        "restored",
        "functional_write_count",
        "unauthorized_write_count",
        "nack_count",
        "timeout_count",
        "bank_verify_failure_count",
        "prior_failure_pending",
        "write_occurred_campaign",
        "slice_executed_mask",
        "campaign_closed",
        "rejected_command_count",
    )
    return {key: state[key] for key in keys}


class R2R1Controller:
    def __init__(self, device: MmioDevice, output_root: Path):
        self.device = device
        self.root = output_root.resolve(strict=True)
        for name in REQUIRED_OUTPUT_DIRECTORIES:
            path = (self.root / name).resolve(strict=True)
            require(path.is_dir(), f"OUTPUT_DIRECTORY_MISSING:{name}")
            require(path == self.root / name, f"OUTPUT_DIRECTORY_NOT_DIRECT_CHILD:{name}")
        self.scanner = ScannerController(device)
        self.executor = ExecutorController(device)
        self.scan_serial = 0
        self.previous_generation: int | None = None
        self.scan_ledger: list[dict] = []
        self.action_receipts: list[dict] = []
        self.rollback_attempts = 0

    def scan(self, phase: str, directory: Path) -> dict:
        resolved_directory = directory.resolve(strict=True)
        require(resolved_directory.is_dir(), f"SCAN_DIRECTORY_MISSING:{directory}")
        require(resolved_directory == self.root or self.root in resolved_directory.parents,
                "SCAN_DIRECTORY_OUTSIDE_OUTPUT_ROOT")
        self.scan_serial += 1
        safe_phase = "".join(character.lower() if character.isalnum() else "-"
                             for character in phase).strip("-")
        prefix = resolved_directory / f"{safe_phase}-{self.scan_serial:04d}"
        snapshot, receipt = self.scanner.oneshot(prefix)
        validate_scan(snapshot, self.previous_generation)
        self.previous_generation = int(snapshot["generation"])
        self.scan_ledger.append(scan_summary(phase, snapshot, receipt))
        return snapshot

    def issue(self, command: Command) -> dict:
        try:
            receipt = self.executor.issue(command)
        except ExecutorActionError as error:
            self.action_receipts.append(error.receipt)
            raise
        self.action_receipts.append(receipt)
        validate_error_counters(receipt["after"], command.name)
        return receipt

    def initial_runtime_gate(self) -> tuple[dict, dict, dict]:
        initial = self.executor.snapshot()
        validate_safe_idle(initial, "INITIAL_RUNTIME")
        validate_autoinit(initial)
        require(initial["functional_write_count"] == 0, "INITIAL_FUNCTIONAL_WRITE_COUNT_NONZERO")
        require(not initial["write_occurred_campaign"], "INITIAL_WRITE_OCCURRED_FLAG_SET")
        require(initial["slice_executed_mask"] == 0, "INITIAL_SLICE_MASK_NONZERO")
        require(initial["baseline_pass_count"] == 0, "INITIAL_BASELINE_PASS_COUNT_NONZERO")
        require(not initial["prior_failure_pending"], "INITIAL_PRIOR_FAILURE_PENDING")
        scan_identity = self.scanner.identity()
        acq_identity = self.executor.identity()
        require(scan_identity == {
            "magic": 0x4E565343,
            "version": 0x00010001,
            "capabilities": 0x0000000F,
            "entry_count": 82,
            "bank_group_count": 10,
            "manifest_sha256": scan_identity["manifest_sha256"],
            "mode": "READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT",
            "i2c_hz": 25_000,
        }, "SCAN1_RUNTIME_IDENTITY_LITERAL_GATE_FAILED")
        require(acq_identity["magic"] == 0x4E564143, "ACQ_MAGIC_MISMATCH")
        require(acq_identity["version"] == 0x00010000, "ACQ_VERSION_MISMATCH")
        require(acq_identity["capabilities_raw"] == 0x000000FF, "ACQ_CAPABILITIES_MISMATCH")
        require(all(acq_identity["capabilities"].values()), "ACQ_CAPABILITY_BIT_MISSING")
        require(not acq_identity["generic_i2c_capability"], "GENERIC_I2C_CAPABILITY_PRESENT")
        require(not acq_identity["mode_write_capability"], "MODE_CAPABILITY_PRESENT")
        require(not acq_identity["eq_write_capability"], "EQ_CAPABILITY_PRESENT")
        return scan_identity, acq_identity, initial

    def run_pre_camera(self) -> dict:
        scan_identity, acq_identity, initial = self.initial_runtime_gate()
        scan_sanity = self.scanner.mmio_sanity(16)
        acq_sanity = self.executor.mmio_sanity(16)
        require(len(scan_sanity) == 16, "SCAN1_MMIO_SANITY_NOT_16")
        require(len(acq_sanity) == 16, "ACQ_MMIO_SANITY_NOT_16")
        require(all(row["result"] == "PASS" for row in scan_sanity), "SCAN1_MMIO_SANITY_FAILED")
        require(all(row["result"] == "PASS" for row in acq_sanity), "ACQ_MMIO_SANITY_FAILED")
        after_sanity = self.executor.snapshot()
        validate_safe_idle(after_sanity, "POST_MMIO_SANITY")
        require(after_sanity["functional_write_count"] == 0,
                "FUNCTIONAL_WRITE_DURING_MMIO_SANITY")

        scan_dir = self.root / "artifacts" / "pre-camera"
        scan_dir.mkdir(mode=0o700)
        single = self.scan("SCAN1_SINGLE", scan_dir)
        repeated = [self.scan(f"SCAN1_REPEAT_{index:02d}", scan_dir)
                    for index in range(1, 33)]
        require(len(repeated) == 32, "SCAN1_REPEATED_REGRESSION_NOT_32")
        generations = [int(single["generation"]),
                       *(int(item["generation"]) for item in repeated)]
        require(len(generations) == len(set(generations)), "SCAN1_GENERATION_DUPLICATE")

        final = self.executor.snapshot()
        validate_safe_idle(final, "PRE_CAMERA_FINAL")
        require(final["functional_write_count"] == 0, "PRE_CAMERA_FUNCTIONAL_WRITE_OCCURRED")
        require(not final["write_occurred_campaign"], "PRE_CAMERA_WRITE_FLAG_SET")
        result = {
            "schema": f"{TASK_ID}_PRE_CAMERA_GATE_V1",
            "task": TASK_ID,
            "source_commit": SOURCE_COMMIT,
            "source_tree": SOURCE_TREE,
            "bitstream_sha256": BITSTREAM_SHA256,
            "engineering_gate": "PASS",
            "scan1_runtime_identity": scan_identity,
            "acq_runtime_identity": acq_identity,
            "additional_absent_capabilities": {
                "ACP": True,
                "ROUTE_WRITE": True,
                "BGDCOL_WRITE": True,
                "GENERIC_HOST_NVP_I2C": True,
                "MODE_WRITE": True,
                "EQ_WRITE": True,
            },
            "initial_executor_state": summarize_executor(initial),
            "scan1_mmio_sanity": scan_sanity,
            "acq_mmio_sanity": acq_sanity,
            "post_write_ffffffff_reads": 0,
            "mmio_timeouts": 0,
            "scan1_single_scan": "PASS",
            "scan1_repeated_regression": "32/32 PASS",
            "scan_ledger": self.scan_ledger,
            "final_executor_state": summarize_executor(final),
            "functional_nvp_writes": 0,
            "mode_actions": 0,
            "eq_actions": 0,
            "capture_actions": 0,
        }
        write_json(self.root / "logs" / f"{TASK_ID}_PRE_CAMERA_GATE.json", result)
        return result

    def reference_helper_context_gate(self, snapshots: list[dict]) -> dict:
        operation, _decision = contract.load_and_validate()
        require(len(snapshots) >= 3, "REFERENCE_HELPER_CONTEXT_NEEDS_THREE_SCANS")
        selected = snapshots[-3:]
        require(policy.stable_novid(selected) == 1,
                "REFERENCE_HELPER_CONTEXT_NOVID_NOT_STABLE_ONE")
        observed = [helper_context_projection(snapshot) for snapshot in selected]
        expected = {
            f"{bank:02X}:{register:02X}": value
            for (bank, register), value in sorted(HELPER_CONTEXT_EXPECTED.items())
        }
        require(all(item == expected for item in observed),
                "REFERENCE_HELPER_CONTEXT_REGISTER_MISMATCH")
        helper = operation["reference_helper"]
        require(helper["condition_result"] is False, "REFERENCE_HELPER_CONDITION_NOT_FALSE")
        require(helper["disposition"] == "PROVEN_NOT_EXECUTED",
                "REFERENCE_HELPER_DISPOSITION_NOT_PROVEN")
        return {
            "result": "PASS",
            "proof": "READ_ONLY_EXACT_PROFILE_STATE_PLUS_STABLE_NOVID_ONE",
            "profile": "NVP6134C_PROFILE2_AHD1080P25_STAGE2_CH1_PRODUCT_EQUIVALENT_AUTOINIT",
            "observed_registers": observed,
            "expected_registers": expected,
            "stable_novid": 1,
            "reference_condition": helper["condition"],
            "reference_condition_result": False,
            "reference_helper_disposition": "PROVEN_NOT_EXECUTED",
        }

    def collect_until_stable_novid(self, level: int) -> tuple[list[dict], int]:
        snapshots: list[dict] = []
        for attempt in range(1, 9):
            snapshot = self.scan(
                f"SLICE_{level:02X}_OBSERVATION_{attempt:02d}",
                self.root / "slice-campaign",
            )
            snapshots.append(snapshot)
            if len(snapshots) >= 3:
                decision = policy.stable_novid(snapshots)
                if decision in (0, 1):
                    return snapshots, int(decision)
            require(len(snapshots) < 5, "SLICE_NOVID_NOT_STABLE_WITHIN_FIVE_VALID_SCANS")
        raise R2R1GateError("SLICE_NOVID_DECISION_NOT_REACHED")

    def collect_format_snapshots(self) -> tuple[list[dict], dict]:
        snapshots: list[dict] = []
        for attempt in range(1, 9):
            snapshot = self.scan(
                f"FORMAT_OBSERVATION_{attempt:02d}",
                self.root / "format-identification",
            )
            snapshots.append(snapshot)
            if len(snapshots) >= 3:
                decision = format_decision.decide(snapshots[-3:])
                if decision["outcome"] != "SIGNAL_UNSTABLE":
                    require(policy.stable_novid(snapshots[-3:]) == 0,
                            "FORMAT_WINDOW_NOVID_NOT_STABLE_ZERO")
                    return snapshots[-3:], decision
        raise R2R1GateError("READ_ONLY_FORMAT_SNAPSHOTS_NOT_STABLE")

    def rollback_exact(self) -> dict:
        state = self.executor.snapshot()
        if state["campaign_closed"]:
            require(state["rollback_invoked"], "CLOSED_CAMPAIGN_ROLLBACK_NOT_INVOKED")
            require(state["rollback_pass"], "CLOSED_CAMPAIGN_ROLLBACK_NOT_PASS")
            require(state["restored"] == state["baseline"], "CLOSED_CAMPAIGN_RESTORE_MISMATCH")
            return {
                "result": "PASS",
                "automatic_or_prior": True,
                "attempts": self.rollback_attempts,
                "after": summarize_executor(state),
            }

        last_error: Exception | None = None
        for command in (Command.ACQ_ROLLBACK, Command.ACQ_ABORT_AND_ROLLBACK):
            if self.rollback_attempts >= 2:
                break
            current = self.executor.snapshot()
            if current["campaign_closed"]:
                break
            if (not current["idle"] or current["busy"] or current["bank_context_lockout"] or
                    not current["i2c_bus_idle"]):
                last_error = R2R1GateError("ROLLBACK_PRECONDITION_NOT_SAFE")
                break
            if current["hard_fail"] and command is not Command.ACQ_ABORT_AND_ROLLBACK:
                continue
            if current["hard_fail"]:
                last_error = R2R1GateError("ROLLBACK_EXECUTOR_HARD_FAIL")
                break
            self.rollback_attempts += 1
            try:
                self.issue(command)
            except Exception as error:  # exact state is checked immediately below
                last_error = error
            after = self.executor.snapshot()
            if (after["campaign_closed"] and after["rollback_invoked"] and
                    after["rollback_pass"] and after["restored"] == after["baseline"]):
                validate_error_counters(after, "ROLLBACK")
                return {
                    "result": "PASS",
                    "automatic_or_prior": False,
                    "attempts": self.rollback_attempts,
                    "after": summarize_executor(after),
                }
        after = self.executor.snapshot()
        if (after["campaign_closed"] and after["rollback_invoked"] and
                after["rollback_pass"] and after["restored"] == after["baseline"]):
            return {
                "result": "PASS",
                "automatic_or_prior": True,
                "attempts": self.rollback_attempts,
                "after": summarize_executor(after),
            }
        suffix = f":{type(last_error).__name__}:{last_error}" if last_error else ""
        raise R2R1GateError(f"EXACT_ROLLBACK_FAILED{suffix}")

    def post_rollback_gate(self, baseline_configuration: dict[str, int]) -> list[dict]:
        snapshots = [
            self.scan(f"POST_ROLLBACK_{index:02d}", self.root / "artifacts" / "post-rollback")
            for index in range(1, 4)
        ]
        require(all(configuration_projection(item) == baseline_configuration
                    for item in snapshots), "POST_ROLLBACK_CONFIGURATION_MISMATCH")
        state = self.executor.snapshot()
        require(state["rollback_pass"], "POST_ROLLBACK_STATUS_NOT_PASS")
        require(state["restored"] == state["baseline"], "POST_ROLLBACK_BYTES_NOT_BASELINE")
        validate_safe_idle(state, "POST_ROLLBACK", allow_closed=True)
        return snapshots

    def _terminal_format(self, decision: dict) -> tuple[str, str, str]:
        outcome = decision["outcome"]
        mapping = {
            "AHD1080P25_CANDIDATE_CONFIRMED": (
                "PASS_AHD1080P25_CANDIDATE_CONFIRMED_READY_FOR_MODE1",
                "AHD_1080P25",
                "AHD",
            ),
            "FORMAT_PRESENT_UNSUPPORTED": (
                "PASS_SIGNAL_PRESENT_UNSUPPORTED_FORMAT",
                "UNSUPPORTED",
                "NOT_APPLICABLE",
            ),
            "FORMAT_PRESENT_UNRESOLVED": (
                "PASS_SIGNAL_PRESENT_FORMAT_UNRESOLVED",
                "UNRESOLVED",
                "AMBIGUOUS",
            ),
        }
        require(outcome in mapping, f"FORMAT_OUTCOME_NOT_TERMINAL:{outcome}")
        return mapping[outcome]

    def run_connected_campaign(self) -> tuple[dict, int]:
        result_path = self.root / "logs" / f"{TASK_ID}_CONNECTED_CAMPAIGN_RESULT.json"
        failure_path = self.root / "logs" / f"{TASK_ID}_CONNECTED_CAMPAIGN_FAILED.json"
        baseline_configuration: dict[str, int] | None = None
        rollback_receipt: dict | None = None
        try:
            scan_identity, acq_identity, initial = self.initial_runtime_gate()
            connected = [
                self.scan(f"CONNECTED_BASELINE_{index:02d}", self.root / "baseline")
                for index in range(1, 6)
            ]
            projections = [configuration_projection(item) for item in connected]
            require(len({json.dumps(item, sort_keys=True) for item in projections}) == 1,
                    "CONNECTED_BASELINE_CONFIGURATION_NOT_STABLE")
            baseline_configuration = projections[-1]

            if not connected_response_reproduced(connected):
                final = self.executor.snapshot()
                validate_safe_idle(final, "NO_CONNECTED_RESPONSE_FINAL")
                require(final["functional_write_count"] == 0,
                        "FUNCTIONAL_WRITE_WITHOUT_CONNECTED_RESPONSE")
                result = {
                    "schema": f"{TASK_ID}_CONNECTED_CAMPAIGN_RESULT_V1",
                    "engineering_gate": "PASS",
                    "overall_result": "PASS_CONNECTED_CH1_RESPONSE_NOT_REPRODUCED_NO_WRITES",
                    "connected_response_reproduced": False,
                    "connected_baseline_scan_count": 5,
                    "functional_write_count": 0,
                    "unauthorized_functional_writes": 0,
                    "scan_ledger": self.scan_ledger,
                    "action_receipts": self.action_receipts,
                    "final_executor_state": summarize_executor(final),
                }
                write_json(result_path, result)
                return result, 0

            initial_novid = policy.stable_novid(connected)
            require(initial_novid in (0, 1), "CONNECTED_BASELINE_NOVID_NOT_STABLE")

            baseline_receipts: list[dict] = []
            read_side_effect_scans: list[dict] = []
            dryrun_scans: list[dict] = []
            helper_context: dict | None = None
            slice_results: list[dict] = []
            recovered_level: int | None = None
            format_snapshots: list[dict] = []
            format_result: dict | None = None
            post_rollback: list[dict] = []

            if initial_novid == 0:
                format_snapshots, format_result = self.collect_format_snapshots()
            else:
                pass_a = self.issue(Command.ACQ_PREPARE_BASELINE)
                require(pass_a["after"]["baseline_pass_count"] == 1,
                        "BASELINE_PASS_A_COUNT_NOT_ONE")
                require(pass_a["after"]["baseline"] == pass_a["after"]["observed"],
                        "BASELINE_PASS_A_READBACK_MISMATCH")
                pass_b = self.issue(Command.ACQ_PREPARE_BASELINE)
                require(pass_b["after"]["baseline_pass_count"] == 2,
                        "BASELINE_PASS_B_COUNT_NOT_TWO")
                require(pass_b["after"]["baseline"] == pass_b["after"]["observed"],
                        "BASELINE_PASS_B_READBACK_MISMATCH")
                require(pass_a["after"]["baseline"] == pass_b["after"]["baseline"],
                        "TWO_REGISTER_BASELINE_A_B_MISMATCH")
                baseline_receipts.extend((pass_a, pass_b))

                read_side_effect_scans = [
                    self.scan(f"READ_SIDE_EFFECT_{index:02d}", self.root / "baseline")
                    for index in range(1, 4)
                ]
                require(all(configuration_projection(item) == baseline_configuration
                            for item in read_side_effect_scans),
                        "READ_SIDE_EFFECT_CONFIGURATION_CHANGE")

                prewrite = self.issue(Command.ACQ_PREPARE_BASELINE)
                baseline_receipts.append(prewrite)
                prewrite_state = prewrite["after"]
                require(prewrite_state["baseline_pass_count"] == 3,
                        "PREWRITE_BASELINE_PASS_COUNT_NOT_THREE")
                require(prewrite_state["baseline_valid"], "PREWRITE_BASELINE_NOT_VALID")
                require(not prewrite_state["baseline_mismatch"], "PREWRITE_BASELINE_MISMATCH")
                require(prewrite_state["baseline"] == prewrite_state["observed"],
                        "PREWRITE_VALUES_NOT_BASELINE")
                require(prewrite_state["functional_write_count"] == 0,
                        "FUNCTIONAL_WRITE_BEFORE_IDEMPOTENT_REWRITE")

                dryrun = self.issue(Command.ACQ_DRYRUN_REWRITE_BASELINE)
                require(dryrun["functional_write_delta"] == 2,
                        "IDEMPOTENT_REWRITE_WRITE_COUNT_NOT_TWO")
                dryrun_state = dryrun["after"]
                require(dryrun_state["dryrun_pass"], "IDEMPOTENT_REWRITE_STATUS_NOT_PASS")
                require(dryrun_state["observed"] == dryrun_state["baseline"],
                        "IDEMPOTENT_REWRITE_READBACK_MISMATCH")

                dryrun_scans = [
                    self.scan(f"IDEMPOTENT_CONTROL_{index:02d}", self.root / "baseline")
                    for index in range(1, 4)
                ]
                require(all(configuration_projection(item) == baseline_configuration
                            for item in dryrun_scans),
                        "IDEMPOTENT_REWRITE_CONFIGURATION_DISCONTINUITY")
                require(policy.stable_novid(dryrun_scans) == 1,
                        "IDEMPOTENT_REWRITE_NOVID_DISCONTINUITY")
                require(credible_ch1_signature(dryrun_scans),
                        "IDEMPOTENT_REWRITE_DETECTOR_DISCONTINUITY")

                helper_context = self.reference_helper_context_gate(dryrun_scans)

                for level in policy.LEVELS:
                    action = self.issue(SLICE_COMMANDS[level])
                    after = action["after"]
                    require(action["functional_write_delta"] == 2,
                            f"SLICE_{level:02X}_WRITE_COUNT_NOT_TWO")
                    require(after["observed"]["reg08"] == level,
                            f"SLICE_{level:02X}_LEVEL_READBACK_FAILED")
                    require(after["observed"]["reg05"] == 0xA4,
                            f"SLICE_{level:02X}_COMPANION_READBACK_FAILED")
                    require(after["observed"]["entry_bank"] == after["baseline"]["entry_bank"],
                            f"SLICE_{level:02X}_ENTRY_BANK_RESTORE_FAILED")
                    require(after["slice_executed_mask"] == SLICE_MASKS[level],
                            f"SLICE_{level:02X}_EXECUTED_MASK_MISMATCH")
                    observations, novid = self.collect_until_stable_novid(level)
                    slice_results.append({
                        "level": canonical_hex(level),
                        "command": SLICE_COMMANDS[level].name,
                        "level_readback": "PASS",
                        "companion_readback": "PASS",
                        "observation_count": len(observations),
                        "stable_novid": novid,
                        "generations": [int(item["generation"]) for item in observations],
                    })
                    if novid == 0:
                        recovered_level = level
                        format_snapshots, format_result = self.collect_format_snapshots()
                        break
                if recovered_level is None:
                    require(len(slice_results) == 3,
                            "SLICE_SEARCH_DID_NOT_EXECUTE_THREE_LEVELS")
                    require(all(item["stable_novid"] == 1 for item in slice_results),
                            "SLICE_SEARCH_TERMINAL_STATE_NOT_STABLE_NOVID_ONE")

                rollback_receipt = self.rollback_exact()
                post_dir = self.root / "artifacts" / "post-rollback"
                post_dir.mkdir(mode=0o700)
                post_rollback = self.post_rollback_gate(baseline_configuration)

            if format_result is not None:
                overall_result, detected_format, discriminator = self._terminal_format(format_result)
            else:
                require(initial_novid == 1 and recovered_level is None,
                        "MISSING_FORMAT_RESULT_WITH_SIGNAL_PRESENT")
                overall_result = "PASS_NO_VALID_VIDEO_AFTER_REFERENCE_SLICE_SEARCH"
                detected_format = "NONE"
                discriminator = "NOT_APPLICABLE"

            final = self.executor.snapshot()
            validate_safe_idle(final, "CONNECTED_CAMPAIGN_FINAL",
                               allow_closed=bool(final["campaign_closed"]))
            validate_error_counters(final, "CONNECTED_CAMPAIGN_FINAL")
            if initial_novid == 0:
                require(final["functional_write_count"] == 0,
                        "FUNCTIONAL_WRITE_WHEN_BASELINE_NOVID_ZERO")
            else:
                require(final["rollback_pass"], "FINAL_ROLLBACK_NOT_PASS")
                require(final["restored"] == final["baseline"], "FINAL_RESTORE_NOT_BASELINE")

            result = {
                "schema": f"{TASK_ID}_CONNECTED_CAMPAIGN_RESULT_V1",
                "task": TASK_ID,
                "source_commit": SOURCE_COMMIT,
                "source_tree": SOURCE_TREE,
                "bitstream_sha256": BITSTREAM_SHA256,
                "engineering_gate": "PASS",
                "overall_result": overall_result,
                "scan1_runtime_identity": scan_identity,
                "acq_runtime_identity": acq_identity,
                "initial_executor_state": summarize_executor(initial),
                "connected_response_reproduced": True,
                "connected_baseline_scan_count": 5,
                "connected_baseline_novid": int(initial_novid),
                "connected_baseline_configuration": baseline_configuration,
                "two_register_baseline_receipts": baseline_receipts,
                "full_byte_baseline_authority": (
                    "PASS" if initial_novid == 1 else "NOT_REACHED_BY_BASELINE_NOVID_ZERO"
                ),
                "read_side_effect_check": (
                    "PASS" if initial_novid == 1 else "NOT_REACHED_BY_BASELINE_NOVID_ZERO"
                ),
                "idempotent_baseline_rewrite": (
                    "PASS" if initial_novid == 1 else "NOT_REACHED_BY_BASELINE_NOVID_ZERO"
                ),
                "read_side_effect_scan_count": len(read_side_effect_scans),
                "idempotent_control_scan_count": len(dryrun_scans),
                "reference_helper_context": helper_context,
                "slice_results": slice_results,
                "slice_actions_executed": len(slice_results),
                "novid_recovery_slice_level": (
                    canonical_hex(recovered_level) if recovered_level is not None
                    else ("BASELINE" if initial_novid == 0 else "NONE")
                ),
                "stable_novid_zero_achieved": bool(initial_novid == 0 or recovered_level is not None),
                "format_snapshot_count": len(format_snapshots),
                "format_decision": format_result,
                "detected_format": detected_format,
                "ahd_cvi_discriminator": discriminator,
                "mode_action_executed": False,
                "eq_action_executed": False,
                "capture_attempted": False,
                "exact_rollback": (
                    rollback_receipt if rollback_receipt is not None else "NOT_REQUIRED_NO_WRITE"
                ),
                "post_rollback_scan_count": len(post_rollback),
                "rollback_attempts": self.rollback_attempts,
                "functional_write_count": int(final["functional_write_count"]),
                "unauthorized_functional_writes": int(final["unauthorized_write_count"]),
                "i2c_nack_count": int(final["nack_count"]),
                "i2c_timeout_count": int(final["timeout_count"]),
                "bank_verify_failure_count": int(final["bank_verify_failure_count"]),
                "scan_ledger": self.scan_ledger,
                "action_receipts": self.action_receipts,
                "final_executor_state": summarize_executor(final),
            }
            write_json(result_path, result)
            return result, 0
        except Exception as error:
            rollback_error: str | None = None
            try:
                state = self.executor.snapshot()
                if state["functional_write_count"] > 0 or state["write_occurred_campaign"]:
                    rollback_receipt = self.rollback_exact()
            except Exception as recovery_error:
                rollback_error = f"{type(recovery_error).__name__}:{recovery_error}"
            try:
                final_state = summarize_executor(self.executor.snapshot())
            except Exception as state_error:
                final_state = {"unavailable": f"{type(state_error).__name__}:{state_error}"}
            failure = {
                "schema": f"{TASK_ID}_CONNECTED_CAMPAIGN_FAILED_V1",
                "engineering_gate": "FAIL",
                "overall_result": "FAIL",
                "first_failed_gate": f"{type(error).__name__}:{error}",
                "rollback_receipt": rollback_receipt,
                "rollback_error": rollback_error,
                "rollback_attempts": self.rollback_attempts,
                "scan_ledger": self.scan_ledger,
                "action_receipts": self.action_receipts,
                "final_executor_state": final_state,
            }
            write_json(failure_path, failure)
            return failure, 1

    def run_final_state(self) -> dict:
        scan_identity = self.scanner.identity()
        acq_identity = self.executor.identity()
        state = self.executor.snapshot()
        validate_safe_idle(state, "FINAL_STATE", allow_closed=bool(state["campaign_closed"]))
        result = {
            "schema": f"{TASK_ID}_FINAL_STATE_GATE_V1",
            "result": "PASS",
            "scan1_runtime_identity": scan_identity,
            "acq_runtime_identity": acq_identity,
            "executor_state": summarize_executor(state),
            "scanner_idle": not state["scanner_busy"],
            "executor_idle": not state["busy"],
            "i2c_bus_idle": state["i2c_bus_idle"],
            "stream_actions_requested": 0,
            "capture_actions_requested": 0,
        }
        write_json(self.root / "logs" / f"{TASK_ID}_FINAL_STATE_GATE.json", result)
        return result


def synthetic_snapshot(novid: int = 1) -> dict:
    required_addresses = set(required_projection_keys()) | set(HELPER_CONTEXT_EXPECTED)
    values = {address: 0 for address in required_addresses}
    values.update(HELPER_CONTEXT_EXPECTED)
    entries = [
        {"bank": bank, "register": register, "value": value}
        for (bank, register), value in sorted(values.items())
    ]
    channels = {}
    for index, name in enumerate(("CH1", "CH2", "CH3", "CH4")):
        private = {key: 0 for key in ("F0", "F2", "F3", "F4", "F5", "E2", "E3",
                                               "E8", "E9", "EA", "EB")}
        if name == "CH1":
            private.update({"F0": 0x31, "F2": 0xC0, "F3": 0x03})
        channels[name] = {
            "novid": novid if index == 0 else 1,
            "raw_f0": private["F0"],
            "lock_tuple": {key: 0 for key in ("E0", "E1", "E2", "7A", "7B")},
            "private_detector": private,
            "raw_tuple": [novid, *([0] * 5), *private.values()],
        }
    return {
        "generation": 1,
        "entry_count": 82,
        "bank_group_count": 10,
        "transaction_count": 105,
        "entry_bank": 0,
        "exit_bank": 0,
        "entry_bank_restore": "PASS",
        "a8_pre": novid,
        "a8_post": novid,
        "live_status_changed": False,
        "raw_register_set": entries,
        "channels": channels,
    }


def self_test() -> None:
    manifest_preflight()
    scan1_self_test()
    acq_self_test()
    operation, decision = contract.load_and_validate()
    require(tuple(SLICE_COMMANDS) == policy.LEVELS, "SELF_TEST_SLICE_ORDER_MISMATCH")
    require(tuple(item.name for item in Command) == contract.COMMANDS,
            "SELF_TEST_COMMAND_CLOSURE_MISMATCH")
    require(operation["forward_order"] == "BANK5_0x08_LEVEL_THEN_BANK5_0x05_A4",
            "SELF_TEST_FORWARD_ORDER_MISMATCH")
    require(decision["temporary_writes_allowed"] is False,
            "SELF_TEST_FORMAT_TEMPORARY_WRITES_ALLOWED")
    connected = [synthetic_snapshot(1) for _ in range(5)]
    require(connected_response_reproduced(connected), "SELF_TEST_CONNECTED_SIGNATURE_FAILED")
    require(policy.stable_novid(connected) == 1, "SELF_TEST_STABLE_NOVID_FAILED")
    expected = {
        f"{bank:02X}:{register:02X}": value
        for (bank, register), value in sorted(HELPER_CONTEXT_EXPECTED.items())
    }
    require(helper_context_projection(connected[0]) == expected,
            "SELF_TEST_HELPER_CONTEXT_FAILED")
    unresolved = format_decision.decide([synthetic_snapshot(0) for _ in range(3)])
    require(unresolved["outcome"] == "FORMAT_PRESENT_UNRESOLVED",
            "SELF_TEST_FORMAT_DECISION_FAILED")
    print(f"PASS {TASK_ID}_RUNTIME_CONTROLLER_SELF_TEST")


def write_failure_receipt(output_root: Path, phase: str, error: Exception) -> None:
    try:
        root = output_root.resolve(strict=True)
        path = root / "logs" / f"{TASK_ID}_{phase}_FAILED.json"
        if not path.exists():
            write_json(path, {
                "schema": f"{TASK_ID}_{phase}_FAILED_V1",
                "engineering_gate": "FAIL",
                "first_failed_gate": f"{type(error).__name__}:{error}",
            })
    except Exception:
        pass


def main(argv: list[str] | None = None) -> int:
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--pre-camera", action="store_true")
    mode.add_argument("--connected-campaign", action="store_true")
    mode.add_argument("--final-state", action="store_true")
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--output-root", type=Path)
    args = parser.parse_args(argv)

    if args.self_test:
        require(args.output_root is None, "SELF_TEST_OUTPUT_ROOT_NOT_ALLOWED")
        self_test()
        return 0
    require(args.output_root is not None, "OUTPUT_ROOT_REQUIRED")

    phase = "OFFLINE_MANIFEST_PREFLIGHT"
    try:
        manifest_preflight()
        with MmioDevice(args.device) as device:
            controller = R2R1Controller(device, args.output_root)
            if args.pre_camera:
                phase = "PRE_CAMERA_GATE"
                result = controller.run_pre_camera()
                exit_code = 0
            elif args.connected_campaign:
                phase = "CONNECTED_CAMPAIGN"
                result, exit_code = controller.run_connected_campaign()
            else:
                phase = "FINAL_STATE_GATE"
                result = controller.run_final_state()
                exit_code = 0
        print(json.dumps(result, sort_keys=True))
        return exit_code
    except Exception as error:
        write_failure_receipt(args.output_root, phase, error)
        print(json.dumps({
            "engineering_gate": "FAIL",
            "phase": phase,
            "first_failed_gate": f"{type(error).__name__}:{error}",
        }, sort_keys=True))
        return 1


if __name__ == "__main__":
    sys.exit(main())
