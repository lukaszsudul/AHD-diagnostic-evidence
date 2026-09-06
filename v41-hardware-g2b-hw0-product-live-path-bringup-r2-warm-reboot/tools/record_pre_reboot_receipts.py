from __future__ import annotations

import csv
import datetime as dt
import hashlib
import json
from pathlib import Path
import re


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R2_20260906")
RAW = ROOT / "raw"
CONTROLLER_LOCK = Path(r"C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json")
EXPECTED_BOOT = "37131b8d-0e38-4b4e-b77a-b3bda55b4e97"
EXPECTED_TARGET = "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01"
EXPECTED_CANONICAL = "Xilinx/80802026a98b01"
EXPECTED_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def marker(text: str, key: str) -> str:
    matches = re.findall(rf"(?m)^{re.escape(key)}=(.*)$", text)
    if not matches:
        raise AssertionError(f"MISSING_MARKER={key}")
    return matches[-1].strip()


def main() -> None:
    authority = json.loads((RAW / "LOCAL_AUTHORITY_VERIFICATION.json").read_text(encoding="utf-8"))
    controller = json.loads(CONTROLLER_LOCK.read_text(encoding="utf-8-sig"))
    local_exclusivity = json.loads((RAW / "CONTROLLER_EXCLUSIVITY_PRELOCK_REFINED.json").read_text(encoding="utf-8-sig"))
    linux = (RAW / "PRE_REBOOT_LINUX_SNAPSHOT.log").read_text(encoding="utf-8")
    lock_verify = (RAW / "LOCKS_PRE_REBOOT_VERIFY.log").read_text(encoding="utf-8")
    with (RAW / "JTAG_PRE_REBOOT_SESSION.csv").open(newline="", encoding="utf-8-sig") as handle:
        jtag = list(csv.DictReader(handle))

    assert authority["result"] == "PASS"
    assert local_exclusivity["exclusivity"] == "PASS"
    assert controller["task"] == "G2B-HW0-PRODUCT-R2"
    assert controller["state"] == "HELD"
    assert controller["warm_reboots_executed"] == 0
    assert marker(linux, "BOOT_ID") == EXPECTED_BOOT
    assert marker(linux, "AHD_ENDPOINT") == "ABSENT"
    assert marker(linux, "XDMA_DRIVER_SYSFS") == "ABSENT"
    assert marker(linux, "XDMA_NODE_COUNT") == "0"
    assert "LINUX_LOCK=HELD" in lock_verify
    assert len(jtag) == 5
    for index, row in enumerate(jtag, 1):
        assert row["sample_index"] == str(index)
        assert row["target_count"] == "1"
        assert row["device_count"] == "1"
        assert row["target_path"] == EXPECTED_TARGET
        assert row["canonical_id"] == EXPECTED_CANONICAL
        assert row["part"].lower() == "xc7a35t"
        assert row["idcode"].upper() == "0362D093"
        assert row["done"] == "1"
        assert row["refresh_result"] == "PASS"

    recorded = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
    receipt = {
        "task": "G2B-HW0-PRODUCT-R2",
        "result": "PASS",
        "recorded_at_utc": recorded,
        "pre_reboot_boot_id": EXPECTED_BOOT,
        "authoritative_dut": "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111",
        "authority_verification": "PASS",
        "fresh_exclusivity": "PASS",
        "controller_lock": "HELD",
        "linux_lock": "HELD",
        "pre_reboot_ahd_endpoint": "ABSENT",
        "pre_reboot_xdma_module": "UNLOADED",
        "pre_reboot_xdma_nodes": 0,
        "pre_reboot_jtag": {
            "target": EXPECTED_TARGET,
            "canonical_id": EXPECTED_CANONICAL,
            "part": "xc7a35t",
            "idcode": "0362D093",
            "chain_index": 0,
            "done_samples": [1, 1, 1, 1, 1],
            "program_operations": 0,
        },
        "candidate_continuity_basis": {
            "r1_final_evidence_commit": "eb3a75c09925574c6947d67cdefb8e2a723add9e",
            "r1_candidate_sha256": EXPECTED_SHA,
            "same_codex_window": True,
            "known_intervening_sram_programs": 0,
            "known_intervening_flash_operations": 0,
            "known_intervening_power_cycles": 0,
            "other_active_ahd_hardware_tasks": 0,
            "fresh_exact_jtag_identity": "PASS",
            "fresh_done": 1,
            "qualification": "OPERATION_CONTINUITY_PLUS_JTAG_CONFIGURED_STATE; JTAG_DOES_NOT_READ_BACK_BITSTREAM_HASH",
        },
        "evidence_sha256": {
            "local_authority": sha(RAW / "LOCAL_AUTHORITY_VERIFICATION.json"),
            "controller_exclusivity": sha(RAW / "CONTROLLER_EXCLUSIVITY_PRELOCK_REFINED.json"),
            "linux_pre_reboot": sha(RAW / "PRE_REBOOT_LINUX_SNAPSHOT.log"),
            "jtag_session": sha(RAW / "JTAG_PRE_REBOOT_SESSION.csv"),
            "locks_verify": sha(RAW / "LOCKS_PRE_REBOOT_VERIFY.log"),
        },
    }
    (RAW / "PRE_REBOOT_AUTHORITY_RECEIPT.json").write_text(
        json.dumps(receipt, indent=2) + "\n", encoding="utf-8", newline="\n"
    )

    plan = {
        "task": "G2B-HW0-PRODUCT-R2",
        "recorded_at_utc": recorded,
        "authorization": "OWNER_WARM_REBOOT_AUTHORIZATION=GRANTED",
        "maximum_warm_reboots": 1,
        "warm_reboots_executed_before_plan": 0,
        "reboot_type": "GRACEFUL_OPERATING_SYSTEM_WARM_REBOOT",
        "command": "sudo -S -p '' /usr/bin/systemd-run --unit=ahd-g2b-hw0-product-r2-warm-reboot --on-active=3s --collect /usr/bin/systemctl reboot",
        "command_count": 1,
        "controller_lock_path": r"C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK",
        "controller_lock_continuity_required": True,
        "pre_reboot_boot_id": EXPECTED_BOOT,
        "disconnect_required": True,
        "reconnect_ip": "10.132.1.111",
        "reconnect_port": 22,
        "reconnect_window_seconds": 900,
        "network_scan": "DENIED",
        "second_reboot": "DENIED",
        "power_cycle": "DENIED",
        "sram_reprogramming": "DENIED",
        "on_ambiguous_acknowledgement": "STOP_WITHOUT_RETRY",
        "on_reconnect_timeout": "BLOCKED — WARM_REBOOT_RECONNECT_TIMEOUT",
        "on_candidate_loss": "CANDIDATE_NOT_RETAINED_ACROSS_WARM_REBOOT",
        "on_endpoint_absent": "BLOCKED — AHD_ENDPOINT_ABSENT_AFTER_AUTHORIZED_WARM_REBOOT",
        "recovery_sequence": [
            "record single scheduled reboot acknowledgement",
            "confirm exact-IP SSH transition from reachable to unreachable",
            "poll only 10.132.1.111:22 for at most 900 seconds",
            "authenticate exact DUT after TCP return",
            "verify changed boot ID and recent uptime",
            "repeat exclusivity and reacquire Linux task lock",
            "perform post-reboot read-only JTAG retention gate",
            "perform post-reboot read-only PCIe inventory",
        ],
    }
    (RAW / "REBOOT_RECOVERY_PLAN.json").write_text(
        json.dumps(plan, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print("PRE_REBOOT_AUTHORITY_RECEIPT=PASS")
    print("REBOOT_RECOVERY_PLAN=RECORDED")
    print("WARM_REBOOTS_EXECUTED=0")


if __name__ == "__main__":
    main()
