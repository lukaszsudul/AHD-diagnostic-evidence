#!/usr/bin/env python3
"""Exact read-only runtime identity and bounded MMIO-sanity gate for CONT1R2."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

BUNDLE_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(BUNDLE_ROOT))

from scan1.controller import ScannerController
from scan1.mmio import MmioDevice
from acq1_compat0_r2.controller import ExecutorController
from g2b_nvp_camera_acq1_compat0_r2r1_controller import (
    summarize_executor,
    validate_autoinit,
    validate_safe_idle,
)


class RuntimeGateError(RuntimeError):
    pass


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeGateError(reason)


def run(device_path: str) -> dict[str, object]:
    with MmioDevice(device_path) as device:
        scanner = ScannerController(device)
        executor = ExecutorController(device)

        scan_identity = scanner.identity()
        acq_identity = executor.identity()
        initial = executor.snapshot()
        validate_safe_idle(initial, "CONT1R2_INITIAL_RUNTIME")
        validate_autoinit(initial)
        require(initial["functional_write_count"] == 0, "INITIAL_FUNCTIONAL_WRITE_COUNT_NONZERO")
        require(not initial["write_occurred_campaign"], "INITIAL_WRITE_OCCURRED_FLAG_SET")
        require(initial["slice_executed_mask"] == 0, "INITIAL_SLICE_MASK_NONZERO")
        require(initial["baseline_pass_count"] == 0, "INITIAL_BASELINE_PASS_COUNT_NONZERO")
        require(not initial["prior_failure_pending"], "INITIAL_PRIOR_FAILURE_PENDING")

        require(scan_identity["magic"] == 0x4E565343, "SCAN1_MAGIC_MISMATCH")
        require(scan_identity["version"] == 0x00010001, "SCAN1_VERSION_MISMATCH")
        require(scan_identity["capabilities"] == 0x0000000F, "SCAN1_CAPABILITIES_MISMATCH")
        require(scan_identity["entry_count"] == 82, "SCAN1_ENTRY_COUNT_MISMATCH")
        require(scan_identity["bank_group_count"] == 10, "SCAN1_BANK_GROUP_COUNT_MISMATCH")
        require(scan_identity["mode"] == "READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT", "SCAN1_MODE_MISMATCH")
        require(scan_identity["i2c_hz"] == 25_000, "SCAN1_I2C_FREQUENCY_MISMATCH")

        require(acq_identity["magic"] == 0x4E564143, "ACQ_MAGIC_MISMATCH")
        require(acq_identity["version"] == 0x00010000, "ACQ_VERSION_MISMATCH")
        require(acq_identity["capabilities_raw"] == 0x000000FF, "ACQ_CAPABILITIES_MISMATCH")
        require(all(acq_identity["capabilities"].values()), "ACQ_CAPABILITY_BIT_MISSING")
        require(not acq_identity["generic_i2c_capability"], "GENERIC_I2C_CAPABILITY_PRESENT")
        require(not acq_identity["mode_write_capability"], "MODE_CAPABILITY_PRESENT")
        require(not acq_identity["eq_write_capability"], "EQ_CAPABILITY_PRESENT")

        scan_sanity = scanner.mmio_sanity(16)
        acq_sanity = executor.mmio_sanity(16)
        require(len(scan_sanity) == 16 and all(row["result"] == "PASS" for row in scan_sanity),
                "SCAN1_MMIO_SANITY_FAILED")
        require(len(acq_sanity) == 16 and all(row["result"] == "PASS" for row in acq_sanity),
                "ACQ_MMIO_SANITY_FAILED")

        final = executor.snapshot()
        validate_safe_idle(final, "CONT1R2_POST_MMIO_SANITY")
        validate_autoinit(final)
        require(final["functional_write_count"] == 0, "FUNCTIONAL_WRITE_DURING_MMIO_SANITY")
        require(not final["write_occurred_campaign"], "WRITE_FLAG_DURING_MMIO_SANITY")

    return {
        "schema": "AHD_V41_CONT1R2_RUNTIME_IDENTITY_MMIO_GATE_V1",
        "result": "PASS",
        "scan1_runtime_identity": scan_identity,
        "acq_runtime_identity": acq_identity,
        "initial_executor_state": summarize_executor(initial),
        "scan1_mmio_sanity": scan_sanity,
        "acq_mmio_sanity": acq_sanity,
        "scan1_mmio_sanity_passes": 16,
        "acq_mmio_sanity_passes": 16,
        "post_write_ffffffff_reads": 0,
        "mmio_timeouts": 0,
        "generic_host_nvp_i2c": "ABSENT",
        "mode_capability": "ABSENT",
        "eq_capability": "ABSENT",
        "functional_nvp_writes": 0,
        "final_executor_state": summarize_executor(final),
    }


def main() -> int:
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        value = run(args.device)
        status = 0
    except Exception as exc:
        value = {
            "schema": "AHD_V41_CONT1R2_RUNTIME_IDENTITY_MMIO_GATE_V1",
            "result": "FAIL",
            "first_failed_gate": f"{type(exc).__name__}:{exc}",
        }
        status = 1
    rendered = json.dumps(value, indent=2, sort_keys=True) + "\n"
    args.output.write_text(rendered, encoding="utf-8")
    print(json.dumps(value, sort_keys=True))
    return status


if __name__ == "__main__":
    raise SystemExit(main())
