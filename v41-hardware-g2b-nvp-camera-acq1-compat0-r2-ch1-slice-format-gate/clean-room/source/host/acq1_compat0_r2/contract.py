"""Fail-closed loader for the two frozen ACQ1-COMPAT0-R2 manifests."""

from __future__ import annotations

import json
from pathlib import Path


RESOURCE_ROOT = Path(__file__).resolve().parent / "resources"
OPERATION_MANIFEST = RESOURCE_ROOT / "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json"
FORMAT_MANIFEST = RESOURCE_ROOT / "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json"
PROFILE_MANIFEST = RESOURCE_ROOT / "G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json"

COMMANDS = (
    "ACQ_PREPARE_BASELINE",
    "ACQ_DRYRUN_REWRITE_BASELINE",
    "ACQ_APPLY_SLICE_50",
    "ACQ_APPLY_SLICE_40",
    "ACQ_APPLY_SLICE_60",
    "ACQ_ROLLBACK",
    "ACQ_ABORT_AND_ROLLBACK",
)
LEVELS = (0x50, 0x40, 0x60)
OUTCOMES = (
    "AHD1080P25_CANDIDATE_CONFIRMED",
    "FORMAT_PRESENT_UNSUPPORTED",
    "FORMAT_PRESENT_UNRESOLVED",
    "NO_FORMAT_CODE",
    "SIGNAL_UNSTABLE",
)


def _load(path: Path) -> dict:
    if not path.is_file():
        raise RuntimeError(f"FROZEN_RESOURCE_MISSING:{path.name}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"FROZEN_RESOURCE_NOT_OBJECT:{path.name}")
    return value


def load_and_validate() -> tuple[dict, dict]:
    operation = _load(OPERATION_MANIFEST)
    decision = _load(FORMAT_MANIFEST)
    profile = _load(PROFILE_MANIFEST)
    if operation.get("schema") != "G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST_V1":
        raise RuntimeError("OPERATION_SCHEMA_MISMATCH")
    if operation.get("channel") != "CH1" or operation.get("private_bank") != "0x05":
        raise RuntimeError("OPERATION_SCOPE_MISMATCH")
    if operation.get("forward_order") != "BANK5_0x08_LEVEL_THEN_BANK5_0x05_A4":
        raise RuntimeError("FORWARD_ORDER_MISMATCH")
    actions = operation.get("forward_actions")
    if not isinstance(actions, list) or len(actions) != 3:
        raise RuntimeError("FORWARD_ACTION_COUNT_MISMATCH")
    for action, level in zip(actions, LEVELS):
        expected = [
            {"bank": "0x05", "register": "0x08", "value": f"0x{level:02X}"},
            {"bank": "0x05", "register": "0x05", "value": "0xA4"},
        ]
        if action.get("level") != f"0x{level:02X}" or action.get("writes") != expected:
            raise RuntimeError(f"FORWARD_ACTION_MISMATCH:{level:02X}")
    helper = operation.get("reference_helper", {})
    if helper.get("condition_result") is not False or helper.get("disposition") != "PROVEN_NOT_EXECUTED":
        raise RuntimeError("REFERENCE_HELPER_DISPOSITION_MISMATCH")
    if decision.get("schema") != "G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST_V1":
        raise RuntimeError("FORMAT_SCHEMA_MISMATCH")
    if decision.get("policy") != "READ_ONLY_SCAN1_FIELDS_ONLY":
        raise RuntimeError("FORMAT_POLICY_MISMATCH")
    if decision.get("required_consecutive_equal_snapshots") != 3:
        raise RuntimeError("FORMAT_DEBOUNCE_MISMATCH")
    if tuple(decision.get("outcomes", ())) != OUTCOMES:
        raise RuntimeError("FORMAT_OUTCOMES_MISMATCH")
    if decision.get("temporary_writes_allowed") is not False or decision.get("single_f0_sufficient") is not False:
        raise RuntimeError("FORMAT_READ_ONLY_GATE_FAILED")
    if profile.get("schema") != "G2B_NVP_ACQ1_COMPAT0_R2_PROFILE_V1" or profile.get("parameters") != {
            "ENABLE_NVP_VIDEO_DIAGNOSTIC": 0,
            "ENABLE_NVP_CAMERA_SCAN1": 1,
            "ENABLE_NVP_ACQ1_EXECUTOR": 1,
    } or profile.get("product_defaults_unchanged") is not True:
        raise RuntimeError("DIAGNOSTIC_PROFILE_MISMATCH")
    return operation, decision
