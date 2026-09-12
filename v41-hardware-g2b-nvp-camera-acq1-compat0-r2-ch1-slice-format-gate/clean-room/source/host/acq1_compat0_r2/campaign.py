"""One bounded CH1 baseline, slice, read-only format, and rollback campaign."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from scan1.controller import ScannerController
from scan1.mmio import MmioDevice

from . import evidence, format_decision, policy
from .controller import Command, ExecutorActionError, ExecutorController


SLICE_COMMANDS = {
    0x50: Command.ACQ_APPLY_SLICE_50,
    0x40: Command.ACQ_APPLY_SLICE_40,
    0x60: Command.ACQ_APPLY_SLICE_60,
}
CONFIG_STABLE_ADDRESSES = {
    (0x00, 0xF4), (0x00, 0xF5), (0x00, 0x80),
    (0x01, 0x97), (0x01, 0x98),
    *((0x01, register) for register in range(0x84, 0x90)),
}


def _private(snapshot: dict, register: str) -> int:
    return int(snapshot["channels"]["CH1"]["private_detector"][register])


def connected_response_reproduced(snapshots: list[dict]) -> bool:
    if len(snapshots) != 5:
        return False
    if any(item.get("live_status_changed") or item.get("entry_bank_restore") != "PASS"
           for item in snapshots):
        return False
    ch1_pairs = [(_private(item, "F2"), _private(item, "F3")) for item in snapshots]
    # SCAN1-R1R1 observed C0/03 on CH1 and 00/00 on CH2-CH4.  Permit only the
    # explicitly allowed small dynamic variation around that CH1 marker.
    if not all(0xB8 <= f2 <= 0xC8 and f3 <= 0x0B for f2, f3 in ch1_pairs):
        return False
    for snapshot in snapshots:
        for name in ("CH2", "CH3", "CH4"):
            private = snapshot["channels"][name]["private_detector"]
            if (int(private["F2"]), int(private["F3"])) != (0, 0):
                return False
    return True


def _config_projection(snapshot: dict) -> dict[str, int]:
    by_address = {(int(item["bank"]), int(item["register"])): int(item["value"])
                  for item in snapshot["raw_register_set"]}
    return {f"{bank:02X}:{register:02X}": by_address[(bank, register)]
            for bank, register in sorted(CONFIG_STABLE_ADDRESSES)}


class CampaignRunner:
    def __init__(self, device: MmioDevice, output_root: Path):
        self.device = device
        self.root = output_root.resolve()
        self.scanner = ScannerController(device)
        self.executor = ExecutorController(device)
        self.scan_serial = 0
        self.functional_write_occurred = False
        self.action_receipts: list[dict] = []
        for name in ("baseline", "slice-search", "format-identification", "rollback", "logs"):
            path = self.root / name
            if not path.is_dir():
                raise RuntimeError(f"CAMPAIGN_OUTPUT_DIRECTORY_MISSING:{name}")

    def _scan(self, phase: str, directory: str) -> dict:
        self.scan_serial += 1
        prefix = self.root / directory / f"{phase.lower()}-{self.scan_serial:04d}"
        snapshot, _receipt = self.scanner.oneshot(prefix)
        return snapshot

    def _issue(self, command: Command) -> dict:
        receipt = self.executor.issue(command)
        self.action_receipts.append(receipt)
        if receipt["functional_write_delta"]:
            self.functional_write_occurred = True
        return receipt

    def _accepted_until_decision(self, level: int) -> tuple[list[dict], str]:
        accepted: list[dict] = []
        total = 0
        while len(accepted) < 5 and total < 8:
            total += 1
            snapshot = self._scan(f"SLICE_{level:02X}", "slice-search")
            if not snapshot["live_status_changed"] and snapshot["entry_bank_restore"] == "PASS":
                accepted.append(snapshot)
            decision = policy.post_level_decision(level, accepted)
            if decision != "COLLECT_ANOTHER_ACCEPTED_SNAPSHOT":
                return accepted, decision
        return accepted, "STOP_SIGNAL_UNSTABLE_AND_ROLLBACK"

    def _format_snapshots(self) -> tuple[list[dict], dict]:
        accepted: list[dict] = []
        for _attempt in range(8):
            snapshot = self._scan("FORMAT", "format-identification")
            if not snapshot["live_status_changed"] and snapshot["entry_bank_restore"] == "PASS":
                accepted.append(snapshot)
                if len(accepted) >= 3:
                    decision = format_decision.decide(accepted[-3:])
                    if decision["outcome"] != "SIGNAL_UNSTABLE":
                        return accepted, decision
        return accepted, {"outcome": "SIGNAL_UNSTABLE", "reason": "FORMAT_WINDOW_NOT_STABLE",
                          "read_only": True}

    def _rollback(self) -> dict | None:
        if not self.functional_write_occurred:
            return None
        state = self.executor.snapshot()
        if state["campaign_closed"]:
            if not state["rollback_pass"]:
                raise RuntimeError("CAMPAIGN_ALREADY_CLOSED_WITHOUT_EXACT_ROLLBACK")
            return {"automatic": True, "after": state}
        receipt = self._issue(Command.ACQ_ROLLBACK)
        after = receipt["after"]
        if not after["rollback_pass"] or not after["campaign_closed"] or after["restored"] != after["baseline"]:
            raise RuntimeError("EXACT_ROLLBACK_VERIFICATION_FAILED")
        return receipt

    def _safe_abort_if_needed(self) -> None:
        state = self.executor.snapshot()
        if (self.functional_write_occurred and not state["campaign_closed"] and
                state["idle"] and not state["hard_fail"] and not state["bank_context_lockout"]):
            try:
                receipt = self.executor.issue(Command.ACQ_ABORT_AND_ROLLBACK)
                self.action_receipts.append(receipt)
            except ExecutorActionError as error:
                self.action_receipts.append(error.receipt)

    def run(self) -> dict:
        result: dict = {"engineering_gate": "FAIL", "overall_result": "FAIL"}
        try:
            connected = [self._scan("CONNECTED_BASELINE", "baseline") for _ in range(5)]
            if not connected_response_reproduced(connected):
                result = {"engineering_gate": "PASS",
                          "overall_result": "PASS_CAMERA_CONNECTED_RESPONSE_NOT_REPRODUCED",
                          "connected_response_reproduced": False,
                          "functional_write_occurred": False}
                return self._finish(result)
            initial_novid = policy.stable_novid(connected)
            if initial_novid is None:
                result = {"engineering_gate": "PASS",
                          "overall_result": "PASS_SIGNAL_UNSTABLE_DURING_SLICE_SEARCH",
                          "connected_response_reproduced": True,
                          "functional_write_occurred": False}
                return self._finish(result)

            prewrite_config = _config_projection(connected[-1])
            recovered_level: int | None = None
            format_result: dict | None = None
            scientific_stop: str | None = None

            if initial_novid == 0:
                _format_scans, format_result = self._format_snapshots()
            else:
                baseline_receipts = [self._issue(Command.ACQ_PREPARE_BASELINE) for _ in range(3)]
                baseline = baseline_receipts[-1]["after"]
                if (baseline["baseline_pass_count"] != 3 or not baseline["baseline_valid"] or
                        baseline["baseline_mismatch"] or baseline["baseline"] != baseline["observed"]):
                    raise RuntimeError("ACQ1_COMPAT0_R2_TWO_REGISTER_BASELINE_UNSTABLE")
                self._issue(Command.ACQ_DRYRUN_REWRITE_BASELINE)
                dryrun_scan = self._scan("DRYRUN", "baseline")
                if dryrun_scan["live_status_changed"] or dryrun_scan["entry_bank_restore"] != "PASS":
                    scientific_stop = "TWO_REGISTER_WRITE_READBACK_AUTHORITY_FAILED"
                else:
                    for level in policy.LEVELS:
                        self._issue(SLICE_COMMANDS[level])
                        _level_scans, action = self._accepted_until_decision(level)
                        if action == "STOP_AND_IDENTIFY_FORMAT":
                            recovered_level = level
                            _format_scans, format_result = self._format_snapshots()
                            break
                        if action == "CONTINUE_TO_NEXT_LEVEL":
                            continue
                        scientific_stop = action
                        break

            rollback_receipt = self._rollback()
            post = [self._scan("POST_ROLLBACK", "rollback") for _ in range(3)]
            if self.functional_write_occurred:
                if rollback_receipt is None or any(_config_projection(item) != prewrite_config for item in post):
                    raise RuntimeError("POST_ROLLBACK_CONFIGURATION_PROOF_FAILED")

            if format_result is not None:
                policy_result = format_decision.terminal_policy(
                    format_result["outcome"], self.functional_write_occurred)
                mapping = {
                    "AHD1080P25_CANDIDATE_CONFIRMED": "PASS_AHD1080P25_CANDIDATE_CONFIRMED_READY_FOR_MODE1",
                    "FORMAT_PRESENT_UNSUPPORTED": "PASS_SIGNAL_PRESENT_UNSUPPORTED_FORMAT",
                    "FORMAT_PRESENT_UNRESOLVED": "PASS_SIGNAL_PRESENT_FORMAT_UNRESOLVED",
                    "NO_FORMAT_CODE": "PASS_SIGNAL_PRESENT_FORMAT_UNRESOLVED",
                    "SIGNAL_UNSTABLE": "PASS_SIGNAL_UNSTABLE_DURING_SLICE_SEARCH",
                }
                overall = mapping[format_result["outcome"]]
            elif scientific_stop == "STOP_NO_VALID_VIDEO_AND_ROLLBACK":
                policy_result = None
                overall = "PASS_NO_VALID_VIDEO_AFTER_REFERENCE_SLICE_SEARCH"
            else:
                policy_result = None
                overall = "PASS_SIGNAL_UNSTABLE_DURING_SLICE_SEARCH"
            result = {
                "engineering_gate": "PASS",
                "overall_result": overall,
                "connected_response_reproduced": True,
                "initial_novid": initial_novid,
                "recovered_level": recovered_level,
                "format_decision": format_result,
                "format_terminal_policy": policy_result,
                "scientific_stop": scientific_stop,
                "functional_write_occurred": self.functional_write_occurred,
                "exact_rollback": "PASS" if self.functional_write_occurred else "NOT_REQUIRED",
                "post_rollback_scan_count": len(post),
            }
            return self._finish(result)
        except Exception:
            self._safe_abort_if_needed()
            raise

    def _finish(self, result: dict) -> dict:
        result["action_receipts"] = self.action_receipts
        final_state = self.executor.snapshot()
        result["scanner_idle"] = not final_state["scanner_busy"]
        result["executor_idle"] = not final_state["busy"]
        evidence.write_json(self.root / "logs" / "G2B_NVP_ACQ1_COMPAT0_R2_CAMPAIGN_RESULT.json", result)
        return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", default="/dev/xdma0_user")
    parser.add_argument("--output-root", type=Path, required=True)
    args = parser.parse_args(argv)
    with MmioDevice(args.device) as device:
        result = CampaignRunner(device, args.output_root).run()
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
