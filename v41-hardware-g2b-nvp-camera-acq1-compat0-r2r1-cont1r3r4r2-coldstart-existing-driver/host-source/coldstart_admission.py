"""Pure, fail-closed cold-start admission and dynamic-node selection rules.

No import or function in this module opens a device, changes a driver, reboots,
programs an FPGA, or alters a startup setting. Live collection is separate.
"""

from __future__ import annotations

import fnmatch
from typing import Any


ENDPOINT = "10.132.1.111:22"
HOST_KEY = "SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8"
HOSTNAME = "VCDE-DUT-1"
MACHINE_ID = "0e90f50d9465492b80258da5658446f8"
AHDSLICE = ("0x10ee", "0x7011", "0x10ee", "0x0007")
PROTECTED = ("0x10ee", "0x7021", "0x10ee", "0xf0a1")
ALIAS = "pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*"


def _ids(device: dict[str, Any]) -> tuple[str, str, str, str]:
    return tuple(str(device.get(key, "")).lower() for key in (
        "vendor", "device", "subsystem_vendor", "subsystem_device"))


def _blocked(reason: str) -> dict[str, str]:
    return {"result": "BLOCKED", "reason": reason}


def admit_postboot(state: dict[str, Any], survey: dict[str, Any]) -> dict[str, str]:
    """Classify one observed boot before driver insertion or FPGA action."""
    if state.get("phase") != "POST_COLD_ADMISSION_IN_PROGRESS":
        return _blocked("LIFECYCLE_PHASE_NOT_POST_COLD")
    if state.get("owner_attestation_token") != "DUT_COLD_START_COMPLETE" or \
            state.get("owner_attested_cold_cycles") != 1 or \
            state.get("programming_attempts") != 0:
        return _blocked("COLD_CYCLE_OR_PROGRAMMING_ATTEMPT_ALREADY_CONSUMED")
    if survey.get("endpoint") != ENDPOINT or survey.get("host_key") != HOST_KEY or \
            survey.get("hostname") != HOSTNAME or survey.get("machine_id") != MACHINE_ID:
        return _blocked("DUT_IDENTITY_CONTRADICTION")
    if not survey.get("boot_id") or survey.get("boot_id") == state.get("pre_cold_boot_id"):
        return _blocked("POST_COLD_BOOT_NOT_DISTINCT")
    if survey.get("xdma_class_exists") or survey.get("foreign_xdma_loaded"):
        return _blocked("CLASS_COLLISION_RECREATED_AFTER_ONE_COLD_START")
    if survey.get("known_pending_loader"):
        return _blocked("PENDING_FOREIGN_LOADER_RACE")
    if survey.get("project_lock_conflict") or survey.get("active_competing_task"):
        return _blocked("PARALLEL_HARDWARE_ACTIVITY")
    if not survey.get("readiness_complete"):
        return _blocked("POST_BOOT_READINESS_UNPROVEN")

    all_devices = survey.get("pci")
    if not isinstance(all_devices, list):
        return _blocked("PCI_INVENTORY_UNAVAILABLE")
    matches = [d for d in all_devices if fnmatch.fnmatchcase(str(d.get("modalias", "")), ALIAS)]
    if any(_ids(d) != AHDSLICE for d in matches):
        return _blocked("NON_TARGET_DRIVER_ALIAS_MATCH")
    if len(matches) > 1:
        return _blocked("MULTIPLE_AHD_ALIAS_MATCHES")
    if len(matches) == 0:
        return {"result": "READ_ONLY_JTAG_REQUIRED", "reason": "AHD_PCI_FUNCTION_ABSENT"}
    target = matches[0]
    if target.get("driver") not in (None, "", "/sys/bus/pci/drivers/xdma_ahd_pcie"):
        return _blocked("AHD_PCI_ALREADY_BOUND_TO_UNEXPECTED_DRIVER")
    return {"result": "TARGET_PCI_PRESENT", "reason": "EXACT_SINGLE_AHD_ALIAS_MATCH",
            "bdf": str(target.get("bdf", ""))}


def select_target_nodes(nodes: list[dict[str, Any]], target_bdf: str,
                        boot_id: str) -> dict[str, str]:
    """Select a coherent dynamic xdmaN pair from pre-collected stat/sysfs data."""
    candidates: dict[str, dict[str, str]] = {}
    for node in nodes:
        if node.get("boot_id") != boot_id or node.get("nearest_pci") != target_bdf or \
                node.get("driver_module") != "xdma_ahd_pcie" or \
                node.get("is_character") is not True or not node.get("major_minor") or \
                node.get("sysfs_dev_t") != node.get("major_minor"):
            continue
        role = node.get("role")
        index = node.get("index")
        if role not in ("user", "c2h_0") or not isinstance(index, int) or index < 0:
            continue
        slot = candidates.setdefault(str(index), {})
        if role in slot:
            raise ValueError("DUPLICATE_NODE_ROLE")
        slot[role] = str(node.get("path", ""))
    full = [(index, roles) for index, roles in candidates.items()
            if roles.get("user", "").startswith("/dev/xdma") and
            roles.get("c2h_0", "").startswith("/dev/xdma")]
    if len(full) != 1:
        raise ValueError("TARGET_NODE_PAIR_NOT_UNIQUE_OR_INCOMPLETE")
    index, roles = full[0]
    if roles["user"] != f"/dev/xdma{index}_user" or \
            roles["c2h_0"] != f"/dev/xdma{index}_c2h_0":
        raise ValueError("TARGET_NODE_NAME_ROLE_MISMATCH")
    return {"user": roles["user"], "c2h_0": roles["c2h_0"],
            "bdf": target_bdf, "boot_id": boot_id, "index": index}


def scan_receipt_valid(receipt: dict[str, Any]) -> bool:
    """Recovered entry NACK is permitted only with a valid final retry."""
    retries = receipt.get("retried_entry_count")
    if not isinstance(retries, int) or not 0 <= retries <= 82:
        return False
    return all(receipt.get(key) is True for key in (
        "complete", "coherent", "entry_bank_restored", "telemetry_complete")) and \
        receipt.get("entries") == 82 and receipt.get("groups") == 10 and \
        receipt.get("transactions") == 105 + retries and \
        receipt.get("hard_error") is False
