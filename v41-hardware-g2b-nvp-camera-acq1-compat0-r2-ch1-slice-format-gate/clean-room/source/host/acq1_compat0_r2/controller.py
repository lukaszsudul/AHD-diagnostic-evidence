"""Bounded controller for the seven compiled ACQ1 executor commands."""

from __future__ import annotations

import argparse
import json
import sys
import time
from enum import IntEnum

from . import contract, mmio


EXPECTED_MAGIC = 0x4E564143
EXPECTED_VERSION = 0x00010000
EXPECTED_CAPABILITIES = 0x000000FF


class Command(IntEnum):
    ACQ_PREPARE_BASELINE = mmio.ACQ_PREPARE_BASELINE
    ACQ_DRYRUN_REWRITE_BASELINE = mmio.ACQ_DRYRUN_REWRITE_BASELINE
    ACQ_APPLY_SLICE_50 = mmio.ACQ_APPLY_SLICE_50
    ACQ_APPLY_SLICE_40 = mmio.ACQ_APPLY_SLICE_40
    ACQ_APPLY_SLICE_60 = mmio.ACQ_APPLY_SLICE_60
    ACQ_ROLLBACK = mmio.ACQ_ROLLBACK
    ACQ_ABORT_AND_ROLLBACK = mmio.ACQ_ABORT_AND_ROLLBACK


class ExecutorActionError(RuntimeError):
    def __init__(self, reason: str, receipt: dict):
        super().__init__(reason)
        self.receipt = receipt


def _bytes24(word: int) -> dict[str, int]:
    return {"reg08": word & 0xFF, "reg05": (word >> 8) & 0xFF, "entry_bank": (word >> 16) & 0xFF}


class ExecutorController:
    def __init__(self, device: mmio.MmioDevice):
        self.device = device
        contract.load_and_validate()

    def identity(self) -> dict:
        raw_capabilities = self.device.read32(mmio.CAPABILITIES)
        result = {
            "magic": self.device.read32(mmio.MAGIC),
            "version": self.device.read32(mmio.VERSION),
            "capabilities_raw": raw_capabilities,
            "capabilities": {name: bool(raw_capabilities & (1 << index))
                             for index, name in enumerate(mmio.CAPABILITY_NAMES)},
            "generic_i2c_capability": False,
            "mode_write_capability": False,
            "eq_write_capability": False,
        }
        if (result["magic"], result["version"], raw_capabilities) != (
                EXPECTED_MAGIC, EXPECTED_VERSION, EXPECTED_CAPABILITIES):
            raise RuntimeError(f"ACQ_RUNTIME_IDENTITY_MISMATCH:{result!r}")
        if not all(result["capabilities"].values()):
            raise RuntimeError("ACQ_CAPABILITY_VECTOR_INCOMPLETE")
        return result

    def mmio_sanity(self, cycles: int = 16) -> list[dict]:
        if cycles != 16:
            raise ValueError("ACQ_MMIO_SANITY_REQUIRES_EXACTLY_16_CYCLES")
        rows = []
        initial_count = self.device.read32(mmio.SANITY_COUNT)
        for index in range(cycles):
            values = (self.device.read32(mmio.MAGIC), self.device.read32(mmio.VERSION),
                      self.device.read32(mmio.STATUS))
            if 0xFFFFFFFF in values or values[:2] != (EXPECTED_MAGIC, EXPECTED_VERSION):
                raise RuntimeError(f"ACQ_MMIO_SANITY_IDENTITY_FAILED:{index + 1}")
            self.device.write32(mmio.SANITY, mmio.SANITY_TOKEN)
            readback = self.device.read32(mmio.SANITY)
            count = self.device.read32(mmio.SANITY_COUNT)
            if readback != mmio.SANITY_TOKEN or count != initial_count + index + 1:
                raise RuntimeError(f"ACQ_MMIO_SANITY_WRITE_READ_FAILED:{index + 1}")
            rows.append({"cycle": index + 1, "token": readback, "count": count, "result": "PASS"})
        return rows

    def snapshot(self) -> dict:
        status = self.device.read32(mmio.STATUS)
        last = self.device.read32(mmio.LAST_OUTCOME)
        baseline_state = self.device.read32(mmio.BASELINE_STATE)
        errors = self.device.read32(mmio.ERROR_COUNTS)
        campaign = self.device.read32(mmio.CAMPAIGN_STATE)
        return {
            "status": status,
            "idle": bool(status & mmio.STATUS_IDLE),
            "busy": bool(status & mmio.STATUS_BUSY),
            "done": bool(status & mmio.STATUS_DONE),
            "hard_fail": bool(status & mmio.STATUS_HARD_FAIL),
            "bank_context_lockout": bool(status & mmio.STATUS_BANK_LOCKOUT),
            "scanner_busy": bool(status & mmio.STATUS_SCANNER_BUSY),
            "i2c_bus_idle": bool(status & mmio.STATUS_I2C_BUS_IDLE),
            "command_sequence": self.device.read32(mmio.COMMAND_SEQUENCE),
            "completed_sequence": self.device.read32(mmio.COMPLETED_SEQUENCE),
            "last_result": last & 0xFF,
            "last_error": (last >> 8) & 0xFF,
            "last_command": (last >> 16) & 0x0F,
            "baseline_valid": bool(baseline_state & 0x1),
            "baseline_pass_count": (baseline_state >> 1) & 0x3,
            "baseline_mismatch": bool(baseline_state & (1 << 3)),
            "dryrun_pass": bool(baseline_state & (1 << 4)),
            "rollback_invoked": bool(baseline_state & (1 << 5)),
            "rollback_pass": bool(baseline_state & (1 << 6)),
            "slice_stage": (baseline_state >> 7) & 0x3,
            "baseline": _bytes24(self.device.read32(mmio.BASELINE_VALUES)),
            "observed": _bytes24(self.device.read32(mmio.OBSERVED_VALUES)),
            "restored": _bytes24(self.device.read32(mmio.RESTORED_VALUES)),
            "functional_write_count": self.device.read32(mmio.FUNCTIONAL_WRITE_COUNT),
            "unauthorized_write_count": self.device.read32(mmio.UNAUTHORIZED_WRITE_COUNT),
            "nack_count": errors & 0xFFFF,
            "timeout_count": (errors >> 16) & 0xFF,
            "bank_verify_failure_count": (errors >> 24) & 0xFF,
            "prior_failure_pending": bool(campaign & 0x1),
            "write_occurred_campaign": bool(campaign & 0x2),
            "slice_executed_mask": (campaign >> 7) & 0x7,
            "campaign_closed": bool(campaign & (1 << 10)),
            "rejected_command_count": self.device.read32(mmio.REJECTED_COMMAND_COUNT),
        }

    def issue(self, command: Command, timeout_seconds: float = 2.0) -> dict:
        if not isinstance(command, Command):
            raise TypeError("COMMAND_MUST_BE_FIXED_ENUM")
        before = self.snapshot()
        if not before["idle"] or before["busy"] or before["hard_fail"] or before["bank_context_lockout"]:
            raise RuntimeError(f"ACQ_NOT_SAFE_IDLE:{before!r}")
        self.device.write32(mmio.CONTROL, int(command))
        expected_sequence = before["command_sequence"] + 1
        deadline = time.monotonic() + timeout_seconds
        after = self.snapshot()
        while time.monotonic() < deadline:
            after = self.snapshot()
            if after["rejected_command_count"] != before["rejected_command_count"]:
                raise ExecutorActionError("ACQ_COMMAND_REJECTED", self._receipt(command, before, after))
            if after["command_sequence"] == expected_sequence and after["completed_sequence"] == expected_sequence:
                break
            if after["hard_fail"] and after["completed_sequence"] >= expected_sequence:
                break
            time.sleep(0.002)
        else:
            raise ExecutorActionError("ACQ_COMMAND_TIMEOUT", self._receipt(command, before, after))
        receipt = self._receipt(command, before, after)
        if after["unauthorized_write_count"] != 0:
            raise ExecutorActionError("ACQ_UNAUTHORIZED_WRITE_COUNT_NONZERO", receipt)
        if after["last_command"] != int(command):
            raise ExecutorActionError("ACQ_LAST_COMMAND_MISMATCH", receipt)
        allowed_results = ({mmio.RESULT_FAILED_ROLLBACK_PASS}
                           if command is Command.ACQ_ABORT_AND_ROLLBACK
                           else {mmio.RESULT_PASS})
        if after["last_result"] not in allowed_results:
            raise ExecutorActionError("ACQ_ACTION_NOT_PASS", receipt)
        expected_writes = 0 if command is Command.ACQ_PREPARE_BASELINE else 2
        if receipt["functional_write_delta"] != expected_writes:
            raise ExecutorActionError("ACQ_FUNCTIONAL_WRITE_DELTA_MISMATCH", receipt)
        return receipt

    @staticmethod
    def _receipt(command: Command, before: dict, after: dict) -> dict:
        return {
            "command": command.name,
            "command_value": int(command),
            "before": before,
            "after": after,
            "functional_write_delta": after["functional_write_count"] - before["functional_write_count"],
            "nack_delta": after["nack_count"] - before["nack_count"],
            "timeout_delta": after["timeout_count"] - before["timeout_count"],
            "bank_verify_failure_delta": (after["bank_verify_failure_count"] -
                                            before["bank_verify_failure_count"]),
        }


def self_test() -> None:
    operation, decision = contract.load_and_validate()
    if len(operation["forward_actions"]) != 3 or decision["temporary_writes_allowed"]:
        raise RuntimeError("ACQ_RUNTIME_SELF_TEST_FAILED")
    if tuple(item.value for item in Command) != tuple(range(1, 8)):
        raise RuntimeError("ACQ_COMMAND_ENUM_NOT_CLOSED")
    print("PASS ACQ1_COMPAT0_R2_RUNTIME_SELF_TEST")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--identity", action="store_true")
    parser.add_argument("--mmio-sanity", action="store_true")
    parser.add_argument("--command", choices=[item.name for item in Command])
    args = parser.parse_args(argv)
    if args.self_test:
        self_test()
        return 0
    with mmio.MmioDevice(args.device) as device:
        executor = ExecutorController(device)
        if args.identity:
            output = executor.identity()
        elif args.mmio_sanity:
            output = executor.mmio_sanity()
        elif args.command:
            output = executor.issue(Command[args.command])
        else:
            parser.error("select --self-test, --identity, --mmio-sanity, or --command")
        print(json.dumps(output, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
