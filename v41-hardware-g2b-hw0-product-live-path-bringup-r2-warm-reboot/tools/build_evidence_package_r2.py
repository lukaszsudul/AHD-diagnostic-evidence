from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
from pathlib import Path


TASK_ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R2_20260906")
REPO_ROOT = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
DIR_NAME = "v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot"
OUT = REPO_ROOT / DIR_NAME

TASK = "G2B-HW0-PRODUCT-R2"
BLOCKER = "BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE"
REQUIRED_COMMIT_MESSAGE = (
    "Run AHD v41 G2B-HW0 PRODUCT warm-reboot live-path bring-up R2"
)

R1_EVIDENCE_COMMIT = "eb3a75c09925574c6947d67cdefb8e2a723add9e"
SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
BIT_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
DCP_SHA = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"
RUNTIME_SHA = "224d194e5f82c85bcb29297561c5d5e76d28063b"
BUILD_FLAGS = "0x00000103"

PRE_BOOT_ID = "37131b8d-0e38-4b4e-b77a-b3bda55b4e97"
POST_BOOT_ID = "52b0bf13-e9d1-4558-ae13-d08f4ecc8dac"
JTAG_TARGET = "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01"
FPGA_PART = "xc7a35t"
FPGA_IDCODE = "0362D093"

ENDPOINT_BDF = "0000:01:00.0"
VENDOR_DEVICE = "10ee:7011"
SUBSYSTEM = "10ee:0007"
PCI_CLASS = "058000"
UPSTREAM_BDF = "0000:00:01.1"
LNKCAP = "Speed 5GT/s, Width x1"
LNKSTA = "Speed 5GT/s, Width x1"
XDMA_MODULE_PATH = (
    "/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst"
)
XDMA_MODULE_SHA = "523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490"
EXTERNAL_HELPER_SHA = "274DB6DDB1D3CDEAB0578275BABAEBFAA70DFCADC3F1FF35E717CACFED8119C0"

REQUIRED_TOP_LEVEL = (
    "V41_G2B_HW0_PRODUCT_R2_MAIN_REPORT.md",
    "G2B_HW0_PRODUCT_R2_AUTHORIZATION_RECEIPT.md",
    "G2B_HW0_PRODUCT_R2_R1_STATE_VERIFICATION.md",
    "G2B_HW0_PRODUCT_R2_LOCK_RECEIPT.md",
    "G2B_HW0_PRODUCT_R2_PRE_REBOOT_STATE.md",
    "G2B_HW0_PRODUCT_R2_WARM_REBOOT_RECEIPT.md",
    "G2B_HW0_PRODUCT_R2_POST_REBOOT_STATE.md",
    "G2B_HW0_PRODUCT_R2_JTAG_PCIE_CORRELATION.md",
    "G2B_HW0_PRODUCT_R2_PCIE_XDMA_INVENTORY.md",
    "G2B_HW0_PRODUCT_R2_LEGACY_MMIO_RAW.csv",
    "G2B_HW0_PRODUCT_R2_RUNTIME_IDENTITY.md",
    "G2B_HW0_PRODUCT_R2_G2B_MMIO_BASELINE.csv",
    "G2B_HW0_PRODUCT_R2_FIRST_RECORD_ANALYSIS.md",
    "G2B_HW0_PRODUCT_R2_FINITE_CAPTURE_SUMMARY.md",
    "G2B_HW0_PRODUCT_R2_FRAME_RECONSTRUCTION.md",
    "G2B_HW0_PRODUCT_R2_CONTINUOUS_CAPTURE_SUMMARY.md",
    "G2B_HW0_PRODUCT_R2_GATE_MATRIX.csv",
    "G2B_HW0_PRODUCT_R2_FINAL_HARDWARE_STATE.md",
    "G2B_HW0_PRODUCT_R2_STATE.json",
    "G2B_HW0_PRODUCT_R2_EVIDENCE_INDEX.md",
    "G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt",
)

REQUIRED_RAW_JSON = (
    "LOCAL_AUTHORITY_VERIFICATION.json",
    "PRE_REBOOT_AUTHORITY_RECEIPT.json",
    "LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json",
    "CONTROLLER_LOCK_BOOKKEEPING_CORRECTION.json",
    "WARM_REBOOT_REMOTE_DELIVERY_SUPERVISOR.json",
    "EXACT_IP_RECONNECT_SUMMARY.json",
    "WARM_REBOOT_EXECUTION_CONFIRMATION.json",
    "LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_CLASSIFICATION.json",
    "POST_REBOOT_COMBINED_LOCK_VERIFICATION.json",
    "POST_REBOOT_JTAG_RETENTION_GATE.json",
    "POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json",
    "T1_DRIVER_GATE_DECISION.json",
    "FINAL_STATE_VALIDATION.json",
    "CONTROLLER_LOCK_RELEASE_RECEIPT.json",
    "CONTROLLER_LOCK_RELEASE_OPERATION.json",
)

REQUIRED_RAW_FILES = REQUIRED_RAW_JSON + (
    "OWNER_R2_CONTRACT.txt",
    "DUT_IDENTITY_PRELOCK_PASS.log",
    "JTAG_PRE_REBOOT_SESSION.csv",
    "PRE_REBOOT_LINUX_SNAPSHOT.log",
    "WARM_REBOOT_COMMAND_DELIVERED.log",
    "POST_REBOOT_AUTHENTICATED_IDENTITY.log",
    "POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK.log",
    "LINUX_LOCK_POST_REBOOT_ACQUIRE_CORRECTED.log",
    "POST_REBOOT_PCIE_XDMA_INVENTORY.log",
    "XDMA_BINDING_FEASIBILITY_READONLY.log",
    "FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log",
    "JTAG_FINAL_SESSION.csv",
    "LINUX_LOCK_POST_REBOOT_RELEASE.log",
)

REQUIRED_LOCK_FILES = (
    "CONTROLLER_LOCK_ACQUIRE_RECEIPT.json",
    "CONTROLLER_LOCK_AFTER_LINUX_RELEASE.json",
    "CONTROLLER_LOCK_AFTER_LOCAL_REJECTION_CORRECTION.json",
    "CONTROLLER_LOCK_BEFORE_LINUX_RELEASE.json",
    "CONTROLLER_LOCK_POST_LINUX_RELOCK.json",
    "CONTROLLER_LOCK_POST_REBOOT_CONFIRMATION.json",
    "LINUX_LOCK_POST_REBOOT_RECEIPT.json",
    "LINUX_LOCK_POST_REBOOT_RELEASE_RECEIPT.json",
)

EXCLUDED_DIR_NAMES = {
    ".git",
    ".cache",
    ".pytest_cache",
    "__pycache__",
    "cache",
    "remote-readback",
    "remote_readback",
    "secret",
    "secrets",
}
EXCLUDED_FILE_NAMES = {
    "invoke-g2br1plink.ps1",
}
EXCLUDED_FILE_SUFFIXES = {
    ".bak",
    ".key",
    ".pem",
    ".pfx",
    ".pw",
    ".pyc",
    ".pyo",
    ".swp",
    ".tmp",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def write_text(name: str, content: str) -> None:
    (OUT / name).write_text(
        content.strip() + "\n", encoding="utf-8", newline="\n"
    )


def write_csv(name: str, header: list[str], rows: list[tuple[object, ...]]) -> None:
    with (OUT / name).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def load_raw_json(name: str) -> dict[str, object]:
    return json.loads((TASK_ROOT / "raw" / name).read_text(encoding="utf-8-sig"))


def require_equal(label: str, actual: object, expected: object) -> None:
    if actual != expected:
        raise SystemExit(
            f"RAW_AUTHORITY_MISMATCH:{label}:expected={expected!r}:actual={actual!r}"
        )


def checks_by_name(authority: dict[str, object]) -> dict[str, dict[str, object]]:
    checks = authority.get("checks")
    if not isinstance(checks, list):
        raise SystemExit("RAW_AUTHORITY_MISMATCH:checks")
    return {
        str(item["name"]): item
        for item in checks
        if isinstance(item, dict) and "name" in item
    }


def validate_authoritative_raw() -> None:
    for name in REQUIRED_RAW_FILES:
        path = TASK_ROOT / "raw" / name
        if not path.is_file():
            raise SystemExit(f"MISSING_REQUIRED_RAW:{name}")
    for name in REQUIRED_LOCK_FILES:
        path = TASK_ROOT / "locks" / name
        if not path.is_file():
            raise SystemExit(f"MISSING_REQUIRED_LOCK_RECEIPT:{name}")

    authority = load_raw_json("LOCAL_AUTHORITY_VERIFICATION.json")
    require_equal("authority.task", authority.get("task"), TASK)
    require_equal("authority.result", authority.get("result"), "PASS")
    require_equal(
        "authority.r1_evidence_commit",
        authority.get("r1_evidence_commit"),
        R1_EVIDENCE_COMMIT,
    )
    checks = checks_by_name(authority)
    expected_checks = {
        "R1_EVIDENCE_HEAD": R1_EVIDENCE_COMMIT,
        "R1_EVIDENCE_REMOTE": R1_EVIDENCE_COMMIT,
        "PROJECT_STATE_REV": 8,
        "G2B_LUT1_STATUS": "ACCEPTED",
        "G2B_LUT1_READINESS": "OFFLINE_QUALIFIED",
        "CANDIDATE_MATURITY": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
        "G2B_HW0_READINESS": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
        "G2B_HW0_SCOPE": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
        "SOURCE_HEAD": SOURCE_COMMIT,
        "SOURCE_TREE": SOURCE_TREE,
        "BIT_BYTES": 2_192_144,
        "BIT_SHA256": BIT_SHA,
        "DCP_SHA256": DCP_SHA,
    }
    for name, expected in expected_checks.items():
        if name not in checks:
            raise SystemExit(f"RAW_AUTHORITY_MISMATCH:missing_check:{name}")
        require_equal(f"check.{name}.result", checks[name].get("result"), "PASS")
        require_equal(f"check.{name}.actual", checks[name].get("actual"), expected)

    pre = load_raw_json("PRE_REBOOT_AUTHORITY_RECEIPT.json")
    require_equal("pre.task", pre.get("task"), TASK)
    require_equal("pre.result", pre.get("result"), "PASS")
    require_equal("pre.boot_id", pre.get("pre_reboot_boot_id"), PRE_BOOT_ID)
    require_equal("pre.endpoint", pre.get("pre_reboot_ahd_endpoint"), "ABSENT")
    require_equal("pre.xdma", pre.get("pre_reboot_xdma_module"), "UNLOADED")
    require_equal("pre.nodes", pre.get("pre_reboot_xdma_nodes"), 0)

    rejection = load_raw_json("LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json")
    require_equal("rejection.task", rejection.get("task"), TASK)
    require_equal("rejection.result", rejection.get("result"), "PASS")
    require_equal(
        "rejection.determination",
        rejection.get("determination"),
        "LOCAL_PRE_EXECUTION_ARGUMENT_REJECTION",
    )
    require_equal("rejection.remote_commands", rejection.get("remote_reboot_commands_issued"), 0)
    require_equal("rejection.reboots", rejection.get("warm_reboots_executed"), 0)
    require_equal("rejection.child", rejection.get("child_process_started"), False)
    require_equal("rejection.ssh", rejection.get("ssh_connection_attempted"), False)
    correction = load_raw_json("CONTROLLER_LOCK_BOOKKEEPING_CORRECTION.json")
    require_equal("correction.task", correction.get("task"), TASK)
    require_equal("correction.result", correction.get("result"), "PASS")
    require_equal(
        "correction.scope",
        correction.get("correction_scope"),
        "LIVE_CONTROLLER_LOCK_BOOKKEEPING_ONLY",
    )
    corrected = correction.get("corrected_bookkeeping")
    if not isinstance(corrected, dict):
        raise SystemExit("RAW_AUTHORITY_MISMATCH:correction.corrected_bookkeeping")
    require_equal("correction.remote_deliveries", corrected.get("remote_reboot_command_deliveries"), 0)
    require_equal("correction.reboots", corrected.get("warm_reboots_executed"), 0)
    require_equal("correction.remaining", corrected.get("authorized_reboot_budget_remaining"), 1)

    delivery = load_raw_json("WARM_REBOOT_REMOTE_DELIVERY_SUPERVISOR.json")
    require_equal("delivery.task", delivery.get("task"), TASK)
    require_equal("delivery.exit", delivery.get("helper_exit_code"), 0)
    require_equal("delivery.attempts", delivery.get("remote_reboot_command_delivery_attempts"), 1)
    require_equal("delivery.deliveries", delivery.get("remote_reboot_command_deliveries"), 1)
    require_equal("delivery.ack", delivery.get("reboot_schedule_acknowledged"), True)
    require_equal("delivery.remaining", delivery.get("authorized_reboot_budget_remaining"), 0)
    reconnect = load_raw_json("EXACT_IP_RECONNECT_SUMMARY.json")
    require_equal("reconnect.task", reconnect.get("task"), TASK)
    require_equal("reconnect.result", reconnect.get("result"), "PASS")
    require_equal("reconnect.ip", reconnect.get("exact_ip"), "10.132.1.111")
    require_equal("reconnect.max", reconnect.get("maximum_seconds"), 895)
    require_equal("reconnect.disconnect", reconnect.get("ssh_disconnect_observed"), True)
    require_equal("reconnect.up", reconnect.get("tcp_reconnect_observed"), True)

    reboot = load_raw_json("WARM_REBOOT_EXECUTION_CONFIRMATION.json")
    require_equal("reboot.task", reboot.get("task"), TASK)
    require_equal("reboot.result", reboot.get("result"), "PASS")
    require_equal("reboot.pre_boot_id", reboot.get("pre_reboot_boot_id"), PRE_BOOT_ID)
    require_equal("reboot.post_boot_id", reboot.get("post_reboot_boot_id"), POST_BOOT_ID)
    require_equal("reboot.deliveries", reboot.get("remote_reboot_command_deliveries"), 1)
    require_equal("reboot.executed", reboot.get("warm_reboots_executed"), 1)
    require_equal("reboot.boot_change", reboot.get("authenticated_boot_id_change"), True)
    require_equal("reboot.reconnect", reboot.get("exact_ip_disconnect_and_reconnect"), True)
    require_equal("reboot.controller_lock", reboot.get("controller_lock_held_through_transition"), True)
    require_equal("reboot.second", reboot.get("second_reboot_attempted"), False)
    require_equal("reboot.power", reboot.get("power_cycle_attempted"), False)

    locks = load_raw_json("POST_REBOOT_COMBINED_LOCK_VERIFICATION.json")
    require_equal("locks.task", locks.get("task"), TASK)
    require_equal("locks.result", locks.get("result"), "PASS")
    require_equal("locks.controller", locks.get("controller_lock"), "HELD")
    require_equal("locks.linux", locks.get("linux_post_reboot_lock"), "HELD")
    require_equal("locks.endpoint_count", locks.get("exact_ahd_endpoint_count"), 1)

    relock_failure = load_raw_json(
        "LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_CLASSIFICATION.json"
    )
    require_equal("relock_failure.task", relock_failure.get("task"), TASK)
    require_equal("relock_failure.result", relock_failure.get("result"), "PASS")
    require_equal(
        "relock_failure.determination",
        relock_failure.get("determination"),
        "PRE_MUTATION_TASK_LOCK_GUARD_PIPELINE_REJECTION",
    )
    require_equal("relock_failure.mutations", relock_failure.get("post_reboot_linux_lock_mutations_completed"), 0)
    require_equal("relock_failure.hardware", relock_failure.get("hardware_mutations"), 0)

    retention = load_raw_json("POST_REBOOT_JTAG_RETENTION_GATE.json")
    require_equal("retention.task", retention.get("task"), TASK)
    require_equal("retention.result", retention.get("result"), "PASS")
    require_equal("retention.part", retention.get("part"), FPGA_PART)
    require_equal("retention.idcode", retention.get("idcode"), FPGA_IDCODE)
    require_equal("retention.index", retention.get("chain_index"), 0)
    require_equal("retention.done", retention.get("done_samples"), [1, 1, 1, 1, 1])
    require_equal(
        "retention.candidate",
        retention.get("candidate_retained_across_warm_reboot"),
        "PASS",
    )
    require_equal("retention.sram_programs", retention.get("sram_program_operations_in_r2"), 0)
    require_equal("retention.flash_programs", retention.get("flash_program_operations"), 0)

    correlation = load_raw_json("POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json")
    require_equal("correlation.task", correlation.get("task"), TASK)
    require_equal("correlation.result", correlation.get("result"), "PASS")
    require_equal(
        "correlation.gate",
        correlation.get("post_reboot_jtag_to_pcie_correlation"),
        "PASS",
    )
    require_equal("correlation.gen2", correlation.get("pcie_gen2_x1_hardware_gate"), "PASS")
    pcie = correlation.get("pcie")
    if not isinstance(pcie, dict):
        raise SystemExit("RAW_AUTHORITY_MISMATCH:correlation.pcie")
    require_equal("pcie.bdf", pcie.get("endpoint_bdf"), ENDPOINT_BDF)
    require_equal("pcie.vendor_device", pcie.get("vendor_device"), VENDOR_DEVICE)
    require_equal("pcie.subsystem", pcie.get("subsystem"), SUBSYSTEM)
    require_equal("pcie.class", pcie.get("class"), PCI_CLASS)
    require_equal("pcie.upstream", pcie.get("upstream_bdf"), UPSTREAM_BDF)
    require_equal("pcie.lnkcap", pcie.get("endpoint_lnkcap"), LNKCAP)
    require_equal("pcie.lnksta", pcie.get("endpoint_lnksta"), LNKSTA)
    require_equal("pcie.driver", pcie.get("driver"), "NONE")

    t1 = load_raw_json("T1_DRIVER_GATE_DECISION.json")
    require_equal("t1.task", t1.get("task"), TASK)
    require_equal("t1.result", t1.get("result"), "BLOCKED")
    require_equal("t1.gate", t1.get("t1_warm_reboot_endpoint_gate"), "BLOCKED")
    require_equal("t1.blocker", t1.get("first_blocker"), BLOCKER)
    require_equal("t1.decision", t1.get("decision"), "DO_NOT_LOAD_OR_BIND")
    require_equal("t1.module_loaded", t1.get("xdma_module_loaded_during_r2"), False)
    require_equal("t1.binds", t1.get("driver_bind_operations"), 0)
    require_equal("t1.mmio_reads", t1.get("mmio_reads"), 0)
    require_equal("t1.mmio_writes", t1.get("mmio_writes"), 0)
    require_equal("t1.dma", t1.get("dma_operations"), 0)
    module = t1.get("installed_module")
    if not isinstance(module, dict):
        raise SystemExit("RAW_AUTHORITY_MISMATCH:t1.installed_module")
    require_equal("module.path", module.get("path"), XDMA_MODULE_PATH)
    require_equal("module.sha256", str(module.get("sha256", "")).upper(), XDMA_MODULE_SHA)
    require_equal("module.aliases", module.get("bus_aliases"), ["platform:xdma"])
    require_equal("module.platform_devices", module.get("matching_platform_devices"), 0)
    require_equal("module.matches", module.get("matches_ahd_pci_modalias"), False)

    final = load_raw_json("FINAL_STATE_VALIDATION.json")
    require_equal("final.task", final.get("task"), TASK)
    require_equal("final.result", final.get("result"), "PASS")
    require_equal("final.engineering", final.get("engineering_gate"), "BLOCKED")
    require_equal("final.blocker", final.get("first_blocker"), BLOCKER)
    counts = final.get("operation_counts")
    if not isinstance(counts, dict):
        raise SystemExit("RAW_AUTHORITY_MISMATCH:final.operation_counts")
    expected_counts = {
        "warm_reboots": 1,
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
    for name, expected in expected_counts.items():
        require_equal(f"final.counts.{name}", counts.get(name), expected)

    release = load_raw_json("CONTROLLER_LOCK_RELEASE_RECEIPT.json")
    require_equal("release.task", release.get("task"), TASK)
    require_equal("release.state", release.get("state"), "RELEASED")
    require_equal(
        "release.release_state",
        release.get("release_state"),
        "RELEASED_AFTER_FINAL_STATE_CAPTURE",
    )
    require_equal("release.reboots", release.get("warm_reboots_executed"), 1)
    require_equal("release.module_loads", release.get("xdma_module_loads_in_r2"), 0)
    require_equal("release.binds", release.get("driver_binds_in_r2"), 0)
    require_equal("release.mmio_reads", release.get("mmio_reads"), 0)
    require_equal("release.mmio_writes", release.get("mmio_writes"), 0)
    require_equal("release.dma", release.get("dma_operations"), 0)
    operation = load_raw_json("CONTROLLER_LOCK_RELEASE_OPERATION.json")
    require_equal("release_operation.result", operation.get("result"), "PASS")
    require_equal("release_operation.linux_first", operation.get("linux_lock_released_first"), True)
    require_equal("release_operation.controller_last", operation.get("controller_lock_released_last"), True)


def excluded(relative: Path) -> bool:
    lowered_parts = {part.lower() for part in relative.parts}
    if lowered_parts & EXCLUDED_DIR_NAMES:
        return True
    name = relative.name.lower()
    if name in EXCLUDED_FILE_NAMES:
        return True
    if relative.suffix.lower() in EXCLUDED_FILE_SUFFIXES:
        return True
    if any(marker in name for marker in ("pwfile", "private_key", "credential_cache")):
        return True
    return False


def safe_reset_auxiliary(destination: Path) -> None:
    resolved_out = OUT.resolve()
    resolved_destination = destination.resolve(strict=False)
    if resolved_destination.parent != resolved_out:
        raise SystemExit(f"UNSAFE_AUXILIARY_DESTINATION:{destination}")
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir()


def sync_tree(source: Path, destination: Path) -> None:
    if not source.is_dir():
        raise SystemExit(f"MISSING_PUBLISH_SOURCE:{source}")
    safe_reset_auxiliary(destination)
    for item in sorted(source.rglob("*"), key=lambda p: p.as_posix()):
        relative = item.relative_to(source)
        if excluded(relative):
            continue
        if item.is_symlink():
            raise SystemExit(f"REFUSE_SYMLINK:{item}")
        target = destination / relative
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        elif item.is_file():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)


def prepare_output(mode: str) -> None:
    if OUT.resolve(strict=False).parent != REPO_ROOT.resolve():
        raise SystemExit(f"UNSAFE_OUTPUT:{OUT}")
    if OUT.is_symlink():
        raise SystemExit(f"REFUSE_SYMLINK_OUTPUT:{OUT}")
    if mode == "pending":
        if OUT.exists():
            raise SystemExit(f"REFUSE_OVERWRITE:{OUT}")
        OUT.mkdir()
    elif not OUT.is_dir():
        raise SystemExit("MISSING_INITIAL_PACKAGE")

    unknown_files = {
        item.name for item in OUT.iterdir() if item.is_file()
    } - set(REQUIRED_TOP_LEVEL)
    unknown_dirs = {
        item.name for item in OUT.iterdir() if item.is_dir()
    } - {"raw", "tools", "locks"}
    if unknown_files or unknown_dirs:
        raise SystemExit(
            "UNEXPECTED_EXISTING_PUBLICATION_PATHS:"
            f"files={sorted(unknown_files)}:dirs={sorted(unknown_dirs)}"
        )

    sync_tree(TASK_ROOT / "raw", OUT / "raw")
    sync_tree(TASK_ROOT / "tools", OUT / "tools")
    sync_tree(TASK_ROOT / "locks", OUT / "locks")


def publication_values(mode: str) -> tuple[str, str]:
    if mode == "final":
        return "PASS", "PASS"
    return "AWAITING_POST_COMMIT_REMOTE_READBACK", "NOT_RUN"


def main_report(
    publication: str,
    remote: str,
    initial_commit: str | None,
    readback_files: int | None,
    readback_utc: str | None,
) -> str:
    publication_detail = (
        f"Commit-pinned remote byte read-back is PASS for initial evidence commit "
        f"`{initial_commit}`, covering `{readback_files}` files at `{readback_utc}` "
        "with zero missing paths, size mismatches, or SHA-256 mismatches."
        if publication == "PASS"
        else "The complete package awaits its containing commit, ordinary non-force push, and commit-pinned byte read-back."
    )
    return rf"""
# AHD v41 G2B-HW0-PRODUCT-R2 Warm-Reboot PCIe Re-enumeration and Live-Path Bring-Up

## Result

| Field | Result |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `{publication}` |
| Overall result | `BLOCKED` |
| T0 pre-reboot authority/exclusivity gate | `PASS` |
| T1 warm-reboot/endpoint gate | `BLOCKED` |
| T2 runtime/MMIO gate | `NOT_REACHED` |
| T3 one-record gate | `NOT_REACHED` |
| T4 finite-capture gate | `NOT_REACHED` |
| T5 continuous-capture gate | `NOT_REACHED` |
| Remote read-back | `{remote}` |
| First blocker | `{BLOCKER}` |
| Final execution point | `HARD STOP AFTER G2B-HW0-PRODUCT-R2 WARM-REBOOT LIVE-PATH BRING-UP` |

The one authorized graceful warm reboot succeeded. The exact DUT disconnected,
reconnected at the same IP, and returned with one new authenticated boot ID.
The exact PRODUCT candidate remained configured in volatile SRAM with five
post-reboot and five final `DONE=1` samples. The exact AHD endpoint enumerated
at `{ENDPOINT_BDF}` behind `{UPSTREAM_BDF}`, correlation passed, and the live
link negotiated PCIe Gen2 x1.

Execution stopped at the XDMA portion of T1. The only installed module named
`xdma` is a platform-bus driver with only alias `platform:xdma`; zero matching
platform devices exist, and no installed module resolves the endpoint's exact
PCI modalias for `{VENDOR_DEVICE}`. Loading that module could not bind the AHD
PCI function or create the required user/C2H nodes. The governed decision was
`DO_NOT_LOAD_OR_BIND`, producing `{BLOCKER}`. No module load, bind, MMIO access,
stream operation, or DMA capture followed.

## Authority and immutable inputs

- R1 evidence commit: `{R1_EVIDENCE_COMMIT}`; package and final state verified.
- `PROJECT_STATE_REV_AT_START = 8`.
- `PROJECT_STATE_REV_AT_END = 8`.
- META-8A: `VERIFIED / PROMOTED`.
- G2B-LUT1: `ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- G2B-HW0-PRODUCT readiness: `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`.
- Scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`.
- Source worktree: `C:\FPGA\V41_G2B`.
- Source branch: `integration/v41-g2b-onech-c2h`.
- Source commit/tree: `{SOURCE_COMMIT}` / `{SOURCE_TREE}`.
- PRODUCT bitstream: 2,192,144 bytes, SHA-256 `{BIT_SHA}`.
- Signed-off DCP: 15,726,324 bytes, SHA-256 `{DCP_SHA}`.
- Owner warm-reboot authorization: `GRANTED`; maximum warm reboots: `1`.
- Power cycle, R2 SRAM reprogramming, and Flash programming: `DENIED`.
- Legacy MMIO reads: `GRANTED`; legacy MMIO writes: `DENIED`.

## Pre-reboot authority and locks

The authoritative DUT was `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`,
authenticated as `vcdeagent1`, machine ID
`0e90f50d9465492b80258da5658446f8`. Its pre-reboot boot ID was
`{PRE_BOOT_ID}`. The inherited R1 state was confirmed: exact candidate retained
by operation continuity, `DONE=1`, AHD endpoint absent, XDMA unloaded, zero
XDMA nodes, Flash unchanged, and no R1 reboot.

Fresh controller and Linux exclusivity checks passed. The controller lock was
acquired at `2026-09-06T06:44:21.3498081Z`, remained held across the reboot and
all post-reboot work, and was released last after final-state capture. The
pre-reboot Linux lock was held before delivery. After reconnect and fresh
exclusivity, the post-reboot Linux lock was acquired and later released before
the controller lock.

## One controlled warm reboot

The first local wrapper invocation was rejected during controller-local
argument validation before a password file, child process, Plink, SSH session,
remote command, acknowledgement, or reboot existed. Its evidence was preserved,
and bookkeeping was corrected from one local wrapper rejection to zero remote
deliveries and zero warm reboots. This was not a reboot attempt.

The guarded delivery then consumed the only remote-delivery budget before
launch. Exactly one remote `systemd-run` timer scheduled unforced
`systemctl reboot`; the schedule acknowledgement passed. SSH disconnect was
observed at `2026-09-06T07:07:54.9070207Z`, and TCP reconnect on only
`10.132.1.111:22` was observed at `2026-09-06T07:08:25.1682075Z`, within
30.280 seconds of the bounded 895-second monitor. Authenticated post-reboot
identity returned boot ID `{POST_BOOT_ID}`, proving exactly one boot transition.
No second reboot and no power cycle occurred.

## T1 passed subgates and blocker

- Candidate retained across warm reboot: `PASS`.
- FPGA: `{FPGA_PART}`, IDCODE `{FPGA_IDCODE}`, chain index 0, `DONE=1`.
- AHD endpoint after reboot: `PASS`, BDF `{ENDPOINT_BDF}`.
- Identity: `{VENDOR_DEVICE}`, subsystem `{SUBSYSTEM}`, class `{PCI_CLASS}`.
- Upstream/root port: `{UPSTREAM_BDF}`.
- Post-reboot JTAG-to-PCIe correlation: `PASS`.
- Endpoint `LnkCap`: `{LNKCAP}`.
- Endpoint `LnkSta`: `{LNKSTA}`.
- PCIe Gen2 x1 hardware gate: `PASS`.
- Endpoint driver: none; XDMA module unloaded; XDMA nodes: zero.
- Installed module: `{XDMA_MODULE_PATH}`.
- Installed module SHA-256: `{XDMA_MODULE_SHA}`.
- Installed module aliases: only `platform:xdma`; matching platform devices: 0.
- Exact AHD PCI modalias resolution: no installed module.
- Safe AHD XDMA bind: `BLOCKED`.
- XDMA node-to-BDF mapping: `NOT_REACHED`.

T1 therefore remains `BLOCKED` at `{BLOCKER}` even though the warm reboot,
retention, endpoint, correlation, and link-negotiation subgates passed.

## Downstream disposition

T2 through T5 are `NOT_REACHED`. Expected runtime identity remains embedded
Git SHA `{RUNTIME_SHA}` and `BUILD_FLAGS={BUILD_FLAGS}`, but neither value was
read. Legacy identity MMIO, NVP/video telemetry MMIO, G2B MMIO, ABI/profile,
first record, 2500-record capture, frame reconstruction, and 60-second capture
were not attempted. First-record and frame hashes are `NONE`.

The offline expected transport contract remains
`AHD_C2H_TRANSPORT_ABI_V1`, version `1`, with record/header/payload/padding
geometry `4096/64/3840/192` bytes. It was not observed in R2 because T2 was
not reached.

## Final state and protected boundaries

Final JTAG evidence shows the candidate retained in volatile SRAM and five of
five `DONE=1` samples. Endpoint `{ENDPOINT_BDF}` remains present, Gen2 x1,
unbound, with XDMA unloaded and zero nodes. The stream was never enabled.

R2 operation counts were exactly: one warm reboot; zero power cycles; zero
SRAM or Flash programs; zero module loads; zero binds or unbinds; zero PCIe
rescans or resets; zero MMIO reads or writes; zero stream-control writes; and
zero DMA operations. `C:\FPGA\FPGA_AHD`, tracked source in
`C:\FPGA\V41_G2B`, active XDC, SSOT, Flash, driver files, and package state
were not modified. `HARDWARE_THROUGHPUT_288_MB_S = NOT_PROVEN`.
Four-input and two-channel operation are `NOT_QUALIFIED`; synthetic and V4L2
tests were not run; `release/v41.0.0` was not created. G2B-HW qualification is
`NOT_PROVEN`, and `SSOT_UPDATE_REQUIRED = NO`.

## Evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Directory: `{DIR_NAME}`.
- Required initial commit message: `{REQUIRED_COMMIT_MESSAGE}`.
- Push mode: ordinary non-force.
- Evidence publication: `{publication}`.
- Remote read-back: `{remote}`.

{publication_detail}
"""


def authorization_receipt() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Authorization Receipt

| Authorization or boundary | Contract | Actual |
|---|---|---|
| Owner hardware authorization | `GRANTED` | `HONORED` |
| Owner warm-reboot authorization | `GRANTED` | `HONORED` |
| Maximum warm reboots | `1` | `1` |
| Power-cycle authorization | `DENIED` | `0` |
| SRAM reprogramming in R2 | `DENIED` | `0` |
| Flash programming | `DENIED` | `0` |
| Legacy MMIO reads | `GRANTED` | `0`, because T2 was not reached |
| Legacy MMIO writes | `DENIED` | `0` |
| Documented G2B control writes | only `0x3800..0x3BFF` after T1 | `0` |
| XDMA module load | at most one only if safe and relevant | `0` |
| Exact AHD bind | at most one only if safe | `0` |
| Second reboot | not authorized | `0` |
| PCIe rescan/reset | not authorized | `0` |
| Power cycle | not authorized | `0` |

The only remote reboot command was a normal graceful operating-system warm
reboot. The earlier controller-local wrapper rejection launched no child
process and delivered no remote command, so it did not consume a warm reboot.
The one successful remote delivery exhausted the authorized reboot budget.

The installed platform-only `xdma` module was not loaded because it could not
bind `{ENDPOINT_BDF}`. No driver override, `new_id`, compilation, installation,
module replacement, global unload, or unrelated-device operation occurred.
First blocker: `{BLOCKER}`.
"""


def r1_state_verification() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 R1 State Verification

Result: `PASS`

- R1 evidence directory:
  `v41-hardware-g2b-hw0-product-live-path-bringup-r1`.
- R1 final evidence commit: `{R1_EVIDENCE_COMMIT}`.
- R1 package manifest: `57/57 PASS`, zero mismatches.
- R1 publication and commit-pinned remote read-back: `PASS`.
- R1 final candidate: exact Recovery-4 PRODUCT image remained in volatile SRAM
  by unbroken operation accounting.
- R1 final `DONE`: `1`.
- R1 final AHD endpoint: `ABSENT`.
- R1 final XDMA state: module unloaded, driver sysfs absent, zero nodes.
- R1 Flash operations: `0`.
- R1 reboot and power-cycle counts: `0 / 0`.

The rev8 SSOT manifest passed with zero mismatches. It records META-8A as the
accepted current meta task, G2B-LUT1 `ACCEPTED / OFFLINE_QUALIFIED`, candidate
maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`, G2B-HW0-PRODUCT
`AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, scope
`ONE_CHANNEL_FIXED_LIVE_AHD_PATH`, and persistent Flash programming not
authorized.

The exact source commit/tree, bitstream size/hash, and signed-off DCP hash were
rehash-verified before hardware work. Fresh pre-reboot JTAG found the same
target, `{FPGA_PART}`, IDCODE `{FPGA_IDCODE}`, index 0, and five `DONE=1`
samples. There were zero known intervening SRAM programs, Flash operations, or
power cycles. This establishes operation continuity plus configured state; it
does not claim live JTAG read-back of the bitstream hash.
"""


def lock_receipt() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Lock Receipt

Result: `PASS`

| Event | Result |
|---|---|
| Fresh controller exclusivity | `PASS` |
| Controller lock acquired | `2026-09-06T06:44:21.3498081Z` |
| Pre-reboot Linux lock | `HELD` |
| Controller lock through disconnect/reconnect | `HELD` |
| Post-reboot fresh exclusivity | `PASS` |
| Post-reboot Linux lock | `HELD` |
| Final state captured with both locks held | `PASS` |
| Linux lock released first | `PASS` |
| Controller lock released last | `PASS` |
| Controller lock release | `2026-09-06T07:34:55.6004821Z` |

The durable controller receipt bound task `{TASK}`, candidate SHA-256
`{BIT_SHA}`, controller `NBLSUDUL`, authoritative DUT
`VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`, pre-reboot boot ID
`{PRE_BOOT_ID}`, session owner, timestamps, and final release state.

One initial post-reboot lock-acquisition helper stopped before `mkdir` because
its read-only namespace pipeline encountered unreadable systemd-private
directories under `pipefail`. The failure was classified as
`PRE_MUTATION_TASK_LOCK_GUARD_PIPELINE_REJECTION`; zero lock or hardware
mutations occurred. The corrected depth-one inventory retained all guards,
found zero competing processes/locks/users, and acquired the post-reboot lock.
Both the failed attempt and its correction remain in `raw/`.
"""


def pre_reboot_state() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Pre-Reboot State

Result: `PASS`

- DUT: `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`.
- Authenticated user: `vcdeagent1`.
- Machine ID: `0e90f50d9465492b80258da5658446f8`.
- Kernel: `7.0.0-29-generic`.
- Boot ID: `{PRE_BOOT_ID}`.
- AHD endpoint: `ABSENT`.
- XDMA module: `UNLOADED`.
- XDMA driver sysfs: absent.
- XDMA nodes: `0`.
- FPGA: `{FPGA_PART}`, IDCODE `{FPGA_IDCODE}`, chain index 0.
- JTAG target: `{JTAG_TARGET}`.
- Five pre-reboot samples: `DONE=1`.
- R2 program operations before reboot: `0`.
- Controller and Linux locks: `HELD`.

The snapshot preserved PCIe topology, relevant root-port state, AER data,
kernel logs, users, device owners, uptime, and reboot inhibitors. The listed
inhibitors covered sleep or physical-key handling; no evidence showed an
unresolved shutdown/reboot inhibitor. The recovery plan limited reconnect
polling to exact IP `10.132.1.111`, denied network scanning and all second
reboots, and set the maximum reconnect window to 900 seconds.
"""


def warm_reboot_receipt() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Warm-Reboot Receipt

Result: `PASS`

| Field | Value |
|---|---|
| Authorized maximum | `1` |
| Warm reboots executed | `1` |
| Pre-reboot boot ID | `{PRE_BOOT_ID}` |
| Post-reboot boot ID | `{POST_BOOT_ID}` |
| Remote command deliveries | `1` |
| Schedule acknowledgements | `1` |
| SSH disconnect observed | `YES` |
| Exact-IP TCP reconnect | `PASS` |
| Authenticated boot-ID change | `PASS` |
| Exactly one boot transition | `PASS` |
| Second reboot attempted | `NO` |
| Power cycle attempted | `NO` |
| Controller lock held throughout | `YES` |

The first local wrapper was rejected before password-file creation, child
process launch, Plink, SSH, remote command delivery, or acknowledgement. Its
original log and supervisor are preserved. A classification receipt proved the
same pre-reboot boot ID and corrected the live lock to zero deliveries and zero
reboots before the authorized delivery.

The only delivered reboot used one transient `systemd-run` timer invoking
unforced `/usr/bin/systemctl reboot`. The helper passed argument auditing and
host-key pinning. Disconnect occurred at
`2026-09-06T07:07:54.9070207Z`; reconnect at exact IP occurred at
`2026-09-06T07:08:25.1682075Z`. Authentication then proved boot ID
`{POST_BOOT_ID}` and recent uptime. The one-reboot budget remained consumed and
no retry was attempted.
"""


def post_reboot_state() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Post-Reboot State

Result: `PASS THROUGH THE XDMA INVENTORY POINT`

- Hostname/user/machine identity: exact authoritative DUT, `PASS`.
- Post-reboot boot ID: `{POST_BOOT_ID}`.
- Exactly one authenticated boot transition: `PASS`.
- Post-reboot exclusivity and Linux relock: `PASS`.
- Candidate retention: `PASS` by operation continuity and configured state.
- FPGA: `{FPGA_PART}`, IDCODE `{FPGA_IDCODE}`, index 0, five `DONE=1` samples.
- Exact AHD endpoint: `{ENDPOINT_BDF}`.
- Endpoint identity: `{VENDOR_DEVICE}`, subsystem `{SUBSYSTEM}`, class `{PCI_CLASS}`.
- Upstream/root port: `{UPSTREAM_BDF}`.
- Endpoint link: Gen2 x1 (`LnkCap` and `LnkSta` both `{LNKSTA}`).
- Endpoint driver: none.
- XDMA module: unloaded.
- XDMA driver sysfs: absent.
- XDMA nodes: zero.

The endpoint reappeared only after the single authorized warm reboot. No PCIe
rescan or reset was used. The final read-only capture preserved PCIe topology,
AER/kernel context, endpoint properties, module state, and node state before
the locks were released.
"""


def correlation_report() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Post-Reboot JTAG-to-PCIe Correlation

Result: `PASS`

The correlation binds:

`{JTAG_TARGET}` / `{FPGA_PART}` / IDCODE `{FPGA_IDCODE}` / index 0

to the physical AHD board and current endpoint:

`{ENDPOINT_BDF}` / `{VENDOR_DEVICE}` / subsystem `{SUBSYSTEM}` / class `{PCI_CLASS}`

behind upstream/root port `{UPSTREAM_BDF}`.

The decision combines the hash-verified R1 accepted physical binding, the same
authoritative DUT and uninterrupted controller lock, the same exact JTAG
target/part/IDCODE/index, reappearance of the historical endpoint identity and
parent, an exact `{VENDOR_DEVICE}` endpoint count of one, and explicit
discrimination from the other Xilinx device, which has a different ID, class,
and root path. Vendor/device ID alone was not treated as sufficient.

Endpoint `LnkCap` is `{LNKCAP}` and `LnkSta` is `{LNKSTA}`. The measured PCIe
Gen2 x1 hardware gate is `PASS`.
"""


def pcie_xdma_inventory() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 PCIe and XDMA Inventory

## PCIe

| Field | Value |
|---|---|
| Exact endpoint | `{ENDPOINT_BDF}` |
| Vendor/device | `{VENDOR_DEVICE}` |
| Subsystem | `{SUBSYSTEM}` |
| Class | `{PCI_CLASS}` |
| Upstream/root port | `{UPSTREAM_BDF}` |
| LnkCap | `{LNKCAP}` |
| LnkSta | `{LNKSTA}` |
| Current speed/width | `5.0 GT/s PCIe / x1` |
| PCIe Gen2 x1 gate | `PASS` |
| Current endpoint driver | `NONE` |

## Installed module feasibility

| Field | Value |
|---|---|
| Installed module name | `xdma` |
| Path | `{XDMA_MODULE_PATH}` |
| Module version | `N/A (modinfo version field absent)` |
| SHA-256 | `{XDMA_MODULE_SHA}` |
| Module alias | `platform:xdma` only |
| Matching platform devices | `0` |
| HDMI/unrelated endpoints matching installed module | `0` |
| Exact `{VENDOR_DEVICE}` PCI modalias resolution | `NO MODULE` |
| PCI XDMA driver sysfs | `ABSENT` |
| XDMA nodes | `0` |
| Module loads in R2 | `0` |
| Driver binds/unbinds in R2 | `0 / 0` |

The exact endpoint is a PCI device, while the installed module registers only
a platform-bus alias. It cannot bind this BDF or produce the required user and
C2H nodes. The conditional authorization to load an already installed module
did not require an irrelevant load. The governed decision was
`DO_NOT_LOAD_OR_BIND` and the exact blocker is `{BLOCKER}`.

No `driver_override`, `new_id`, module load/unload, compilation, installation,
PCIe rescan/reset, MMIO access, or DMA operation occurred.
"""


def legacy_mmio_csv() -> None:
    write_csv(
        "G2B_HW0_PRODUCT_R2_LEGACY_MMIO_RAW.csv",
        [
            "status",
            "read_timestamp_utc",
            "offset",
            "width_bits",
            "raw_value",
            "byte_order",
            "register",
            "decoded_value",
            "authorized_range",
            "access",
            "provenance",
        ],
        [
            (
                "NOT_REACHED",
                "N/A",
                "N/A",
                "N/A",
                "N/A",
                "N/A",
                "N/A",
                "T1 blocked before exact XDMA user-node mapping",
                "0x0000..0x0030;0x0080..0x00B4",
                "READ_ONLY_NOT_EXECUTED",
                "No legacy MMIO read or write occurred",
            )
        ],
    )


def runtime_identity() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Runtime Identity

T2 result: `NOT_REACHED`

| Layer | Expected | Observed | Result |
|---|---|---|---|
| Governed source commit | `{SOURCE_COMMIT}` | offline authority only | `VERIFIED` |
| Governed source tree | `{SOURCE_TREE}` | offline authority only | `VERIFIED` |
| Bitstream SHA-256 | `{BIT_SHA}` | offline authority only | `VERIFIED` |
| Signed-off DCP SHA-256 | `{DCP_SHA}` | offline authority only | `VERIFIED` |
| SSOT revision | `8` | `8` | `PASS` |
| Embedded runtime GIT_SHA | `{RUNTIME_SHA}` | `N/A` | `NOT_REACHED` |
| Embedded BUILD_FLAGS | `{BUILD_FLAGS}` | `N/A` | `NOT_REACHED` |
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version `1` | `N/A` | `NOT_REACHED` |
| Record geometry | `4096/64/3840/192` bytes | `N/A` | `NOT_REACHED` |
| Dual-layer identity | both layers agree | `N/A` | `NOT_REACHED` |

The older embedded runtime SHA remains expected because Recovery-4 reused
sealed routed logic and added constraints-only sign-off changes. No exact XDMA
user node existed, so no runtime identity register was read. No claim is made
about runtime identity, PRODUCT profile, transport signature, or ABI.
"""


def g2b_mmio_csv() -> None:
    write_csv(
        "G2B_HW0_PRODUCT_R2_G2B_MMIO_BASELINE.csv",
        [
            "status",
            "timestamp_utc",
            "offset",
            "register",
            "raw_value",
            "decoded_value",
            "access",
            "expected_geometry",
            "provenance",
        ],
        [
            (
                "NOT_REACHED",
                "N/A",
                "N/A",
                "N/A",
                "N/A",
                "T1 blocked before exact XDMA user-node mapping",
                "NO_READ_OR_WRITE",
                "AHD_C2H_TRANSPORT_ABI_V1;version=1;record=4096;header=64;payload=3840;padding=192",
                "No G2B MMIO access; stream never enabled",
            )
        ],
    )


def first_record_analysis() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 First Record Analysis

T3 result: `NOT_REACHED`

- First record bytes: `N/A`.
- First record SHA-256: `NONE`.
- Header: `NOT_REACHED`.
- Payload: `NOT_REACHED`.
- Padding: `NOT_REACHED`.
- Raw artifact: not produced.

T1 stopped at `{BLOCKER}` before any user/C2H node mapping, stream-control
write, or DMA operation. There is no claim about record magic, ABI version,
header size, payload size, padding, channel/input identity, sequence, epoch,
flags, reserved fields, or internal `TKEEP`/`TLAST`.
"""


def finite_capture_summary() -> str:
    return f"""
# G2B-HW0-PRODUCT-R2 Finite Capture Summary

T4 result: `NOT_REACHED`

| Field | Value |
|---|---|
| Requested records | `2500` |
| Received records | `N/A` |
| Sequence gaps | `N/A` |
| Sequence duplicates | `N/A` |
| Padding errors | `N/A` |
| Epoch changes | `N/A` |
| Malformed records | `N/A` |

T3 did not run, so the prerequisite for T4 was absent. No finite capture or
bounded capture sample was created.
"""


def frame_reconstruction() -> str:
    return """
# G2B-HW0-PRODUCT-R2 Frame Reconstruction

Result: `NOT_REACHED`

- Reconstructed frame SHA-256: `NONE`.
- Lossless artifact: not produced.
- Frame identity, epoch, line count, ordering, missing lines, duplicate lines,
  payload size, and stale-slot mixing: `NOT_REACHED`.

No records were captured, so no frame reconstruction was possible or claimed.
"""


def continuous_capture_summary() -> str:
    return """
# G2B-HW0-PRODUCT-R2 Continuous Capture Summary

T5 result: `NOT_REACHED`

| Metric | Value |
|---|---|
| Requested duration | `60 seconds after T0-T4 PASS` |
| Measured duration | `N/A` |
| Complete records | `N/A` |
| Records per second | `N/A` |
| Complete frames | `N/A` |
| Estimated frame rate | `N/A` |
| Application payload | `N/A` |
| Transport throughput | `N/A` |
| Sequence gaps/duplicates | `N/A / N/A` |
| Malformed records/padding errors | `N/A / N/A` |
| Epoch changes | `N/A` |
| Formatter fatal/ownership fatal | `N/A / N/A` |

T0-T4 did not all pass, so no continuous capture ran. The one-channel nominal
expectations of 27,000 records/s, 103.68 MB/s application payload, and 110.592
MB/s transport were not measured. `HARDWARE_THROUGHPUT_288_MB_S` remains
`NOT_PROVEN`.
"""


def gate_matrix(publication: str, remote: str) -> None:
    rows = [
        ("R1_EVIDENCE", "exact R1 package and final state", "PASS", "G2B_HW0_PRODUCT_R2_R1_STATE_VERIFICATION.md", "VERIFIED"),
        ("SSOT_META8A", "rev8 and promoted META-8A", "PASS", "raw/LOCAL_AUTHORITY_VERIFICATION.json", "SSOT unchanged"),
        ("CANDIDATE", "source/bitstream/DCP exact", "PASS", "raw/LOCAL_AUTHORITY_VERIFICATION.json", "no R2 programming"),
        ("DUT_AUTH_PRE", "exact authenticated DUT", "PASS", "raw/DUT_IDENTITY_PRELOCK_PASS.log", PRE_BOOT_ID),
        ("EXCLUSIVITY_PRE", "fresh inventory and two locks", "PASS", "G2B_HW0_PRODUCT_R2_LOCK_RECEIPT.md", "controller lock held through reboot"),
        ("JTAG_PRE", "exact FPGA and DONE=1", "PASS", "raw/JTAG_PRE_REBOOT_SESSION.csv", "five of five DONE=1"),
        ("T0", "pre-reboot authority/exclusivity", "PASS", "raw/PRE_REBOOT_AUTHORITY_RECEIPT.json", "warm reboot authorized to proceed"),
        ("LOCAL_WRAPPER_REJECTION", "prove no remote effect", "PASS", "raw/LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json", "zero remote deliveries/reboots"),
        ("WARM_REBOOT", "one graceful OS reboot", "PASS", "raw/WARM_REBOOT_EXECUTION_CONFIRMATION.json", "one authenticated boot transition"),
        ("EXACT_IP_RECONNECT", "disconnect and bounded exact-IP reconnect", "PASS", "raw/EXACT_IP_RECONNECT_SUMMARY.json", "30.280 s within 895 s"),
        ("EXCLUSIVITY_POST", "fresh inventory and Linux relock", "PASS", "raw/POST_REBOOT_COMBINED_LOCK_VERIFICATION.json", "no competing owner"),
        ("CANDIDATE_RETENTION", "same JTAG device and DONE=1", "PASS", "raw/POST_REBOOT_JTAG_RETENTION_GATE.json", "zero R2 programs"),
        ("AHD_ENDPOINT", "exact endpoint enumerated", "PASS", "raw/POST_REBOOT_PCIE_XDMA_INVENTORY.log", ENDPOINT_BDF),
        ("JTAG_PCIE_CORRELATION", "physical board to current endpoint/root", "PASS", "raw/POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json", "not vendor-ID-only"),
        ("PCIE_GEN2_X1", "measured LnkCap/LnkSta", "PASS", "raw/POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json", "5 GT/s x1"),
        ("SAFE_AHD_XDMA_BIND", "installed module must support exact PCI modalias", "BLOCKED", "raw/T1_DRIVER_GATE_DECISION.json", BLOCKER),
        ("XDMA_NODE_MAPPING", "exact user/C2H nodes to BDF", "NOT_REACHED", "raw/T1_DRIVER_GATE_DECISION.json", "stopped before load/bind"),
        ("T1", "reboot + endpoint + link + XDMA + nodes", "BLOCKED", "G2B_HW0_PRODUCT_R2_PCIE_XDMA_INVENTORY.md", BLOCKER),
        ("T2", "runtime/MMIO", "NOT_REACHED", "G2B_HW0_PRODUCT_R2_RUNTIME_IDENTITY.md", "blocked by T1"),
        ("T3", "one 4096-byte record", "NOT_REACHED", "G2B_HW0_PRODUCT_R2_FIRST_RECORD_ANALYSIS.md", "blocked by T1"),
        ("T4", "2500 records and frame", "NOT_REACHED", "G2B_HW0_PRODUCT_R2_FINITE_CAPTURE_SUMMARY.md", "blocked by T1"),
        ("T5", "60-second capture", "NOT_REACHED", "G2B_HW0_PRODUCT_R2_CONTINUOUS_CAPTURE_SUMMARY.md", "blocked by T1"),
        ("FINAL_STATE", "capture and ordered lock release", "PASS", "raw/FINAL_STATE_VALIDATION.json", "candidate retained; endpoint unbound"),
        ("PERSISTENT_PROTECTION", "source/XDC/SSOT/Flash/driver/package unchanged", "PASS", "G2B_HW0_PRODUCT_R2_FINAL_HARDWARE_STATE.md", "no persistent mutation"),
        ("EVIDENCE_PUBLICATION", "new directory and non-force push", publication, "G2B_HW0_PRODUCT_R2_EVIDENCE_INDEX.md", "separate publication field"),
        ("REMOTE_READBACK", "commit-pinned byte verification", remote, "G2B_HW0_PRODUCT_R2_STATE.json", "zero mismatches" if remote == "PASS" else "pending"),
    ]
    write_csv(
        "G2B_HW0_PRODUCT_R2_GATE_MATRIX.csv",
        ["gate", "prerequisite", "result", "evidence", "blocker_or_note"],
        rows,
    )


def final_hardware_state() -> str:
    return rf"""
# G2B-HW0-PRODUCT-R2 Final Hardware State

Final-state validation: `PASS`

## FPGA

- Exact candidate remained in volatile SRAM: `YES`.
- FPGA: `{FPGA_PART}`, IDCODE `{FPGA_IDCODE}`, chain index 0.
- Final JTAG samples: five of five `DONE=1`.
- R2 SRAM programs: `0`.
- Flash programs: `0`.

## PCIe and driver

- Endpoint: `{ENDPOINT_BDF}`, `{VENDOR_DEVICE}`, subsystem `{SUBSYSTEM}`, class `{PCI_CLASS}`.
- Upstream/root port: `{UPSTREAM_BDF}`.
- Link: PCIe Gen2 x1.
- Endpoint binding: `UNBOUND`.
- XDMA module: `UNLOADED`.
- XDMA nodes: `0`.
- Module loads, binds, and unbinds: `0 / 0 / 0`.

## Runtime operations

- Legacy MMIO reads/writes: `0 / 0`.
- G2B MMIO reads/writes: `0 / 0`.
- Stream enable writes: `0`.
- DMA operations: `0`.
- PCIe rescans/resets: `0 / 0`.
- Warm reboots: `1`.
- Power cycles: `0`.

The final Linux and JTAG captures were taken while both locks were held. The
post-reboot Linux lock was released first; the controller lock was released
last at `2026-09-06T07:34:55.6004821Z`. The candidate was intentionally left
in volatile SRAM. No previous image was restored.

## Protected state

| Protected item | Modified |
|---|---|
| `C:\FPGA\FPGA_AHD` | `NO` |
| `C:\FPGA\V41_G2B` tracked source | `NO` |
| Active XDC | `NO` |
| Project SSOT | `NO` |
| Persistent Flash | `NO` |
| Driver files | `NO` |
| Package state | `NO` |
| Unrelated endpoint configuration | `NO` |

Engineering first blocker: `{BLOCKER}`.
"""


def state_payload(
    publication: str,
    remote: str,
    initial_commit: str | None,
    readback_files: int | None,
    readback_utc: str | None,
) -> dict[str, object]:
    evidence_commit = "CONTAINING_GIT_COMMIT" if publication == "PASS" else "PENDING"
    return {
        "task": TASK,
        "title": "Controlled Warm-Reboot PCIe Re-enumeration and Live-Path Continuation",
        "engineering_gate": "BLOCKED",
        "evidence_publication": publication,
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "project_state_rev_at_start": 8,
        "project_state_rev_at_end": 8,
        "meta_8a": "VERIFIED",
        "r1_evidence": "VERIFIED",
        "authoritative_project_state": {
            "meta_8a": "PROMOTED / VERIFIED",
            "g2b_lut1": "ACCEPTED / OFFLINE_QUALIFIED",
            "candidate_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
            "g2b_hw0_product_readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
            "scope": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
            "persistent_flash_programming": "NOT_AUTHORIZED",
        },
        "authorizations": {
            "owner_hardware": "GRANTED",
            "owner_warm_reboot": "GRANTED",
            "maximum_warm_reboots": 1,
            "power_cycle": "DENIED",
            "sram_reprogramming_in_r2": "DENIED",
            "flash_programming": "DENIED",
            "legacy_mmio_reads": "GRANTED",
            "legacy_mmio_writes": "DENIED",
        },
        "authoritative_dut": {
            "logical": "VCDE-DUT-HOST-01",
            "hostname": "VCDE-DUT-1",
            "ip": "10.132.1.111",
            "user": "vcdeagent1",
            "machine_id": "0e90f50d9465492b80258da5658446f8",
            "kernel": "7.0.0-29-generic",
            "authenticated_before_reboot": "PASS",
            "pre_reboot_boot_id": PRE_BOOT_ID,
            "post_reboot_boot_id": POST_BOOT_ID,
            "exactly_one_boot_transition": "PASS",
            "post_reboot_exclusivity": "PASS",
        },
        "candidate": {
            "source_worktree": r"C:\FPGA\V41_G2B",
            "source_branch": "integration/v41-g2b-onech-c2h",
            "source_commit": SOURCE_COMMIT,
            "source_tree": SOURCE_TREE,
            "bitstream_path": r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit",
            "bitstream_bytes": 2_192_144,
            "bitstream_sha256": BIT_SHA,
            "dcp_path": r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp",
            "dcp_bytes": 15_726_324,
            "dcp_sha256": DCP_SHA,
            "retained_across_warm_reboot": "PASS",
            "left_in_volatile_sram": True,
        },
        "reboot": {
            "type": "GRACEFUL_OPERATING_SYSTEM_WARM_REBOOT",
            "local_preexecution_wrapper_rejections": 1,
            "remote_delivery_attempts": 1,
            "remote_deliveries": 1,
            "schedule_acknowledgements": 1,
            "warm_reboots_executed": 1,
            "maximum_warm_reboots": 1,
            "limit_respected": True,
            "ssh_disconnect_observed": True,
            "dut_reconnect": "PASS",
            "reconnect_exact_ip": "10.132.1.111",
            "reconnect_elapsed_seconds": 30.280,
            "second_reboot_attempted": False,
            "power_cycle": False,
            "controller_lock_held_through_reboot": True,
        },
        "jtag": {
            "target": JTAG_TARGET,
            "part": FPGA_PART,
            "idcode": FPGA_IDCODE,
            "chain_index": 0,
            "pre_reboot_done_samples": [1, 1, 1, 1, 1],
            "post_reboot_done_samples": [1, 1, 1, 1, 1],
            "final_done_samples": [1, 1, 1, 1, 1],
            "candidate_retention": "PASS",
            "post_reboot_pcie_correlation": "PASS",
        },
        "pcie": {
            "endpoint_after_warm_reboot": "PASS",
            "endpoint_bdf": ENDPOINT_BDF,
            "vendor_device": VENDOR_DEVICE,
            "subsystem": SUBSYSTEM,
            "class": PCI_CLASS,
            "upstream_root_port": UPSTREAM_BDF,
            "lnkcap": LNKCAP,
            "lnksta": LNKSTA,
            "current_speed": "5.0 GT/s PCIe",
            "current_width": 1,
            "gen2_x1_hardware_gate": "PASS",
            "driver": None,
            "rescans": 0,
            "resets": 0,
        },
        "xdma": {
            "gate": "FAIL",
            "safe_ahd_bind": "BLOCKED",
            "decision": "DO_NOT_LOAD_OR_BIND",
            "installed_module_name": "xdma",
            "installed_module_path": XDMA_MODULE_PATH,
            "installed_module_sha256": XDMA_MODULE_SHA,
            "installed_module_aliases": ["platform:xdma"],
            "matching_platform_devices": 0,
            "matches_exact_pci_modalias": False,
            "module_loaded": False,
            "module_loads": 0,
            "driver_sysfs_present": False,
            "binds": 0,
            "unbinds": 0,
            "user_device": None,
            "c2h_device": None,
            "node_count": 0,
            "node_to_bdf_mapping": "NOT_REACHED",
        },
        "expected_runtime_identity": {
            "git_sha": RUNTIME_SHA,
            "build_flags": BUILD_FLAGS,
        },
        "expected_transport": {
            "abi_name": "AHD_C2H_TRANSPORT_ABI_V1",
            "abi_version": 1,
            "record_bytes": 4096,
            "header_bytes": 64,
            "payload_bytes": 3840,
            "padding_bytes": 192,
        },
        "observed_runtime_identity": None,
        "dual_layer_identity": "NOT_REACHED",
        "transport_abi": "NOT_REACHED",
        "abi_version": None,
        "product_profile": "NOT_REACHED",
        "legacy_identity_mmio": "NOT_REACHED",
        "nvp_video_telemetry_mmio": "NOT_REACHED",
        "g2b_mmio_baseline": "NOT_REACHED",
        "nvp_initialization": "NOT_REACHED",
        "fixed_live_source": "NOT_REACHED",
        "gates": {
            "t0": "PASS",
            "t1": "BLOCKED",
            "t2": "NOT_REACHED",
            "t3": "NOT_REACHED",
            "t4": "NOT_REACHED",
            "t5": "NOT_REACHED",
        },
        "capture": {
            "first_record_bytes": None,
            "first_record_sha256": None,
            "finite_records_requested": 2500,
            "finite_records_received": None,
            "sequence_gaps": None,
            "sequence_duplicates": None,
            "padding_errors": None,
            "epoch_changes": None,
            "frame_sha256": None,
            "continuous_duration_seconds": None,
            "complete_records": None,
            "complete_frames": None,
        },
        "final_hardware_state": {
            "fpga": f"{FPGA_PART} IDCODE {FPGA_IDCODE} index 0; five final DONE=1 samples; candidate retained in volatile SRAM",
            "candidate_left_in_volatile_sram": True,
            "done": 1,
            "pcie_driver": f"{ENDPOINT_BDF} {VENDOR_DEVICE} behind {UPSTREAM_BDF}; Gen2 x1; unbound; xdma unloaded; zero nodes",
            "stream": "NEVER_ENABLED",
            "linux_lock": "RELEASED_AFTER_FINAL_STATE_CAPTURE",
            "controller_lock": "RELEASED_LAST_AFTER_FINAL_STATE_CAPTURE",
        },
        "operation_counts": {
            "warm_reboots": 1,
            "power_cycles": 0,
            "sram_programs_r2": 0,
            "flash_programs": 0,
            "xdma_module_loads": 0,
            "driver_binds": 0,
            "driver_unbinds": 0,
            "legacy_mmio_reads": 0,
            "legacy_mmio_writes": 0,
            "g2b_mmio_reads": 0,
            "g2b_mmio_writes": 0,
            "stream_enable_writes": 0,
            "dma_operations": 0,
            "pcie_rescans": 0,
            "pcie_resets": 0,
        },
        "protected_state": {
            "fpga_ahd_modified": False,
            "v41_g2b_tracked_source_modified": False,
            "active_xdc_modified": False,
            "ssot_modified": False,
            "flash_modified": False,
            "driver_files_modified": False,
            "package_state_modified": False,
        },
        "hardware_accessed": True,
        "hardware_throughput_288_mb_s": "NOT_PROVEN",
        "four_input_selection": "NOT_QUALIFIED",
        "two_channel_capture": "NOT_QUALIFIED",
        "synthetic_generator": "NOT_TESTED",
        "v4l2": "NOT_TESTED",
        "release_v41_0_0": "NOT_CREATED",
        "g2b_hw0_product_r2": "BLOCKED",
        "g2b_hw_qualification": "NOT_PROVEN",
        "ssot_update_required": "NO",
        "publication": {
            "repository": "lukaszsudul/AHD-diagnostic-evidence",
            "branch": "main",
            "directory": DIR_NAME,
            "required_initial_commit_message": REQUIRED_COMMIT_MESSAGE,
            "initial_evidence_commit": initial_commit or "PENDING_CONTAINING_GIT_COMMIT",
            "remote_readback": remote,
            "remote_readback_commit": initial_commit if remote == "PASS" else None,
            "remote_readback_files": readback_files,
            "remote_readback_utc": readback_utc,
            "remote_readback_mismatches": 0 if remote == "PASS" else None,
            "completion_commit": "CONTAINING_GIT_COMMIT" if publication == "PASS" else None,
            "external_final_commit_pinned_readback": (
                "REQUIRED_AFTER_FINAL_COMMIT_AND_RECORDED_OUTSIDE_THIS_SELF_REFERENTIAL_PACKAGE"
                if publication == "PASS"
                else "NOT_REACHED"
            ),
        },
        "final_response_fields": {
            "engineering_gate": "BLOCKED",
            "evidence_publication": publication,
            "overall_result": "BLOCKED",
            "project_state_rev_at_start": 8,
            "project_state_rev_at_end": 8,
            "meta_8a": "VERIFIED",
            "r1_evidence": "VERIFIED",
            "owner_warm_reboot_authorization": "GRANTED",
            "maximum_warm_reboots": 1,
            "warm_reboots_executed": 1,
            "power_cycle_authorization": "DENIED",
            "sram_reprogramming_authorization_in_r2": "DENIED",
            "legacy_mmio_read_authorization": "GRANTED",
            "legacy_mmio_write_authorization": "DENIED",
            "authoritative_linux_dut": "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111",
            "authenticated_dut_connection_before_reboot": "PASS",
            "pre_reboot_boot_id": PRE_BOOT_ID,
            "pre_reboot_candidate_present": "PASS",
            "pre_reboot_done": 1,
            "pre_reboot_ahd_endpoint": "ABSENT",
            "controller_lock_held_through_reboot": "YES",
            "warm_reboot": "PASS",
            "ssh_disconnect_observed": "YES",
            "dut_reconnect": "PASS",
            "post_reboot_boot_id": POST_BOOT_ID,
            "exactly_one_boot_transition": "PASS",
            "post_reboot_dut_exclusivity": "PASS",
            "post_reboot_fpga_device": f"{FPGA_PART} / IDCODE {FPGA_IDCODE} / chain index 0",
            "post_reboot_done": 1,
            "candidate_retained_across_warm_reboot": "PASS",
            "product_bitstream_sha256": BIT_SHA,
            "sram_programming_in_r2": "NO",
            "flash_programming": "NO",
            "ahd_endpoint_after_warm_reboot": "PASS",
            "endpoint_bdf": ENDPOINT_BDF,
            "pcie_vendor_device": VENDOR_DEVICE,
            "upstream_root_port": UPSTREAM_BDF,
            "pcie_lnkcap": LNKCAP,
            "pcie_lnksta": LNKSTA,
            "pcie_gen2_x1_hardware_gate": "PASS",
            "post_reboot_jtag_to_pcie_correlation": "PASS",
            "xdma_module": "FAIL",
            "xdma_module_loaded_during_r2": "NO",
            "xdma_driver_version_hash": f"version=N/A; SHA-256={XDMA_MODULE_SHA}; installed platform-only module",
            "xdma_user_device": "N/A",
            "xdma_c2h_device": "N/A",
            "xdma_node_to_bdf_mapping": "NOT_REACHED",
            "runtime_embedded_git_sha": "N/A",
            "expected_runtime_embedded_git_sha": RUNTIME_SHA,
            "runtime_build_flags": "N/A",
            "expected_runtime_build_flags": BUILD_FLAGS,
            "dual_layer_identity": "NOT_REACHED",
            "transport_abi": "NOT_REACHED",
            "abi_version": "N/A",
            "product_profile": "NOT_REACHED",
            "legacy_identity_mmio": "NOT_REACHED",
            "nvp_video_telemetry_mmio": "NOT_REACHED",
            "g2b_mmio_baseline": "NOT_REACHED",
            "nvp_initialization": "NOT_REACHED",
            "nack_count": "N/A",
            "init_error": "N/A",
            "fixed_live_source": "NOT_REACHED",
            "t0": "PASS",
            "t1": "BLOCKED",
            "t2": "NOT_REACHED",
            "t3": "NOT_REACHED",
            "first_record_bytes": "N/A",
            "first_record_sha256": "NONE",
            "header": "NOT_REACHED",
            "payload": "NOT_REACHED",
            "padding": "NOT_REACHED",
            "t4": "NOT_REACHED",
            "finite_records_requested": 2500,
            "finite_records_received": "N/A",
            "sequence_gaps": "N/A",
            "sequence_duplicates": "N/A",
            "padding_errors": "N/A",
            "epoch_changes": "N/A",
            "frame_reconstruction": "NOT_REACHED",
            "reconstructed_frame_sha256": "NONE",
            "t5": "NOT_REACHED",
            "continuous_measured_duration": "N/A",
            "complete_records": "N/A",
            "records_per_second": "N/A",
            "complete_frames": "N/A",
            "estimated_frame_rate": "N/A",
            "application_payload": "N/A",
            "transport_throughput": "N/A",
            "malformed_records": "N/A",
            "unexplained_drops_gaps": "N/A",
            "formatter_fatal": "N/A",
            "ownership_fatal": "N/A",
            "one_channel_live_ahd_path": "NOT_REACHED",
            "hardware_throughput_ge_288_mb_s": "NOT_PROVEN",
            "four_input_selection": "NOT_QUALIFIED",
            "two_channel_capture": "NOT_QUALIFIED",
            "synthetic_generator": "NOT_TESTED",
            "v4l2": "NOT_TESTED",
            "release_v41_0_0": "NOT_CREATED",
            "final_fpga_state": f"{FPGA_PART} IDCODE {FPGA_IDCODE} index 0; exact candidate retained in volatile SRAM; five final DONE=1 samples; zero R2 programs",
            "final_pcie_driver_state": f"{ENDPOINT_BDF} {VENDOR_DEVICE} subsystem {SUBSYSTEM} class {PCI_CLASS} behind {UPSTREAM_BDF}; Gen2 x1; unbound; xdma unloaded; zero nodes",
            "candidate_left_in_volatile_sram": "YES",
            "persistent_state_modified": "NO",
            "warm_reboots": 1,
            "reboot_limit_respected": "YES",
            "power_cycle": "NO",
            "hardware_accessed": "YES",
            "g2b_hw0_product_r2": "BLOCKED",
            "g2b_hw_qualification": "NOT_PROVEN",
            "ssot_update_required": "NO",
            "evidence_repository": "lukaszsudul/AHD-diagnostic-evidence",
            "evidence_directory": DIR_NAME,
            "evidence_commit": evidence_commit,
            "remote_readback": remote,
            "main_report": rf"C:\FPGA\V41_G2B_EVIDENCE\{DIR_NAME}\V41_G2B_HW0_PRODUCT_R2_MAIN_REPORT.md",
            "first_blocker": BLOCKER,
            "recommended_next_step": "Owner-authorize provisioning of an exact PCI-capable XDMA driver matching 10ee:7011 in a new governed run.",
            "final_execution_point": "HARD STOP AFTER G2B-HW0-PRODUCT-R2 WARM-REBOOT LIVE-PATH BRING-UP",
        },
        "recommended_next_step": "Owner-authorize provisioning of an exact PCI-capable XDMA driver matching 10ee:7011 in a new governed run.",
        "final_execution_point": "HARD STOP AFTER G2B-HW0-PRODUCT-R2 WARM-REBOOT LIVE-PATH BRING-UP",
    }


def evidence_index(
    publication: str,
    remote: str,
    initial_commit: str | None,
    readback_files: int | None,
    readback_utc: str | None,
) -> str:
    purposes = {
        "V41_G2B_HW0_PRODUCT_R2_MAIN_REPORT.md": "overall result and decision",
        "G2B_HW0_PRODUCT_R2_AUTHORIZATION_RECEIPT.md": "grants, denials, and actual operation counts",
        "G2B_HW0_PRODUCT_R2_R1_STATE_VERIFICATION.md": "R1, SSOT, source, bitstream, and DCP authority",
        "G2B_HW0_PRODUCT_R2_LOCK_RECEIPT.md": "controller/Linux lock lifecycle and correction receipts",
        "G2B_HW0_PRODUCT_R2_PRE_REBOOT_STATE.md": "pre-reboot DUT, PCIe, XDMA, and JTAG state",
        "G2B_HW0_PRODUCT_R2_WARM_REBOOT_RECEIPT.md": "one reboot delivery, disconnect, reconnect, and boot-ID proof",
        "G2B_HW0_PRODUCT_R2_POST_REBOOT_STATE.md": "post-reboot retained candidate and enumerated endpoint",
        "G2B_HW0_PRODUCT_R2_JTAG_PCIE_CORRELATION.md": "physical/JTAG/current endpoint correlation and link gate",
        "G2B_HW0_PRODUCT_R2_PCIE_XDMA_INVENTORY.md": "platform-only module mismatch and T1 blocker",
        "G2B_HW0_PRODUCT_R2_LEGACY_MMIO_RAW.csv": "explicit NOT_REACHED legacy-MMIO ledger",
        "G2B_HW0_PRODUCT_R2_RUNTIME_IDENTITY.md": "expected identity and unobserved runtime layer",
        "G2B_HW0_PRODUCT_R2_G2B_MMIO_BASELINE.csv": "explicit NOT_REACHED G2B-MMIO ledger",
        "G2B_HW0_PRODUCT_R2_FIRST_RECORD_ANALYSIS.md": "T3 NOT_REACHED and no record",
        "G2B_HW0_PRODUCT_R2_FINITE_CAPTURE_SUMMARY.md": "T4 NOT_REACHED",
        "G2B_HW0_PRODUCT_R2_FRAME_RECONSTRUCTION.md": "frame reconstruction NOT_REACHED",
        "G2B_HW0_PRODUCT_R2_CONTINUOUS_CAPTURE_SUMMARY.md": "T5 NOT_REACHED",
        "G2B_HW0_PRODUCT_R2_GATE_MATRIX.csv": "all gate and publication dispositions",
        "G2B_HW0_PRODUCT_R2_FINAL_HARDWARE_STATE.md": "final state and protected boundaries",
        "G2B_HW0_PRODUCT_R2_STATE.json": "machine-readable authoritative state",
        "G2B_HW0_PRODUCT_R2_EVIDENCE_INDEX.md": "this index",
        "G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt": "all other published bytes; self-excluded",
    }
    required_rows = "\n".join(
        f"| `{name}` | {purposes[name]} |" for name in REQUIRED_TOP_LEVEL
    )
    aux_rows: list[str] = []
    for root_name in ("raw", "locks", "tools"):
        root = OUT / root_name
        for path in sorted(root.rglob("*"), key=lambda p: p.as_posix()):
            if path.is_file():
                relative = path.relative_to(OUT).as_posix()
                aux_rows.append(
                    f"| `{relative}` | `{path.stat().st_size}` | `{sha256(path)}` |"
                )
    auxiliary_table = "\n".join(aux_rows)
    readback_detail = (
        f"Initial commit `{initial_commit}` was read back at `{readback_utc}`; "
        f"`{readback_files}` files matched byte-for-byte with zero mismatches."
        if remote == "PASS"
        else "Commit-pinned remote byte read-back has not yet run."
    )
    return f"""
# G2B-HW0-PRODUCT-R2 Evidence Index

- Publication status: `{publication}`.
- Remote read-back: `{remote}`.
- Repository/branch: `lukaszsudul/AHD-diagnostic-evidence` / `main`.
- Directory: `{DIR_NAME}`.
- Required initial commit message: `{REQUIRED_COMMIT_MESSAGE}`.

{readback_detail}

## Required top-level artifacts

| File | Purpose |
|---|---|
{required_rows}

All 21 and only the 21 contract-required top-level filenames are generated.
T2 through T5 artifacts remain present and explicitly record `NOT_REACHED`,
`N/A`, or `NONE`.

## Raw receipts and publish-safe tooling

| Relative path | Bytes | SHA-256 |
|---|---:|---|
{auxiliary_table}

The `raw/` tree preserves sanitized task receipts and immutable command output.
The `locks/` tree preserves the task-local acquisition, verification, and
release source receipts. The `tools/` tree contains only task-local,
publishable scripts. Secret/cache and `remote-readback/` directories,
transient password files, private keys, compiled caches, and the external
authenticated-command helper source are excluded. The external helper used by
the task remains local and is identified only by SHA-256
`{EXTERNAL_HELPER_SHA}`.

The bitstream and DCP remain local-only and are represented by exact paths,
sizes, and hashes. No first-record or reconstructed-frame payload exists.

The SHA-256 manifest hashes every published file except itself using exact
relative paths and byte content.
"""


def manifest() -> None:
    path = OUT / "G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt"
    if path.exists():
        path.unlink()
    entries = []
    for item in sorted(OUT.rglob("*"), key=lambda p: p.as_posix()):
        if item.is_file() and item != path:
            entries.append(f"{sha256(item)}  {item.relative_to(OUT).as_posix()}")
    path.write_text("\n".join(entries) + "\n", encoding="utf-8", newline="\n")


def assert_package_surface() -> None:
    actual_files = {item.name for item in OUT.iterdir() if item.is_file()}
    actual_dirs = {item.name for item in OUT.iterdir() if item.is_dir()}
    expected_files = set(REQUIRED_TOP_LEVEL)
    if actual_files != expected_files:
        raise SystemExit(
            "TOP_LEVEL_FILE_SET_MISMATCH:"
            f"missing={sorted(expected_files - actual_files)}:"
            f"extra={sorted(actual_files - expected_files)}"
        )
    if actual_dirs != {"raw", "locks", "tools"}:
        raise SystemExit(
            f"TOP_LEVEL_DIRECTORY_SET_MISMATCH:{sorted(actual_dirs)}"
        )


def build(
    mode: str,
    initial_commit: str | None,
    readback_files: int | None,
    readback_utc: str | None,
) -> None:
    if mode == "final":
        if not initial_commit or readback_files is None or not readback_utc:
            raise SystemExit("FINAL_MODE_REQUIRES_READBACK_FIELDS")
        if len(initial_commit) != 40 or any(c not in "0123456789abcdefABCDEF" for c in initial_commit):
            raise SystemExit("INVALID_INITIAL_COMMIT")
        if readback_files <= 0:
            raise SystemExit("INVALID_READBACK_FILE_COUNT")
    elif any(value is not None for value in (initial_commit, readback_files, readback_utc)):
        raise SystemExit("READBACK_FIELDS_ALLOWED_ONLY_IN_FINAL_MODE")

    validate_authoritative_raw()
    prepare_output(mode)
    publication, remote = publication_values(mode)

    write_text(
        "V41_G2B_HW0_PRODUCT_R2_MAIN_REPORT.md",
        main_report(publication, remote, initial_commit, readback_files, readback_utc),
    )
    write_text("G2B_HW0_PRODUCT_R2_AUTHORIZATION_RECEIPT.md", authorization_receipt())
    write_text("G2B_HW0_PRODUCT_R2_R1_STATE_VERIFICATION.md", r1_state_verification())
    write_text("G2B_HW0_PRODUCT_R2_LOCK_RECEIPT.md", lock_receipt())
    write_text("G2B_HW0_PRODUCT_R2_PRE_REBOOT_STATE.md", pre_reboot_state())
    write_text("G2B_HW0_PRODUCT_R2_WARM_REBOOT_RECEIPT.md", warm_reboot_receipt())
    write_text("G2B_HW0_PRODUCT_R2_POST_REBOOT_STATE.md", post_reboot_state())
    write_text("G2B_HW0_PRODUCT_R2_JTAG_PCIE_CORRELATION.md", correlation_report())
    write_text("G2B_HW0_PRODUCT_R2_PCIE_XDMA_INVENTORY.md", pcie_xdma_inventory())
    legacy_mmio_csv()
    write_text("G2B_HW0_PRODUCT_R2_RUNTIME_IDENTITY.md", runtime_identity())
    g2b_mmio_csv()
    write_text("G2B_HW0_PRODUCT_R2_FIRST_RECORD_ANALYSIS.md", first_record_analysis())
    write_text("G2B_HW0_PRODUCT_R2_FINITE_CAPTURE_SUMMARY.md", finite_capture_summary())
    write_text("G2B_HW0_PRODUCT_R2_FRAME_RECONSTRUCTION.md", frame_reconstruction())
    write_text("G2B_HW0_PRODUCT_R2_CONTINUOUS_CAPTURE_SUMMARY.md", continuous_capture_summary())
    gate_matrix(publication, remote)
    write_text("G2B_HW0_PRODUCT_R2_FINAL_HARDWARE_STATE.md", final_hardware_state())
    payload = state_payload(publication, remote, initial_commit, readback_files, readback_utc)
    write_text(
        "G2B_HW0_PRODUCT_R2_STATE.json",
        json.dumps(payload, indent=2, ensure_ascii=False),
    )
    write_text(
        "G2B_HW0_PRODUCT_R2_EVIDENCE_INDEX.md",
        evidence_index(publication, remote, initial_commit, readback_files, readback_utc),
    )
    manifest()
    assert_package_surface()

    manifest_entries = sum(
        1
        for line in (OUT / "G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt").read_text(
            encoding="utf-8"
        ).splitlines()
        if line
    )
    print(f"PACKAGE_MODE={mode}")
    print(f"PACKAGE_DIRECTORY={OUT}")
    print("TOP_LEVEL_REQUIRED_FILES=21")
    print(f"MANIFEST_ENTRIES={manifest_entries}")
    print(f"ENGINEERING_GATE=BLOCKED")
    print(f"FIRST_BLOCKER={BLOCKER}")
    print(f"EVIDENCE_PUBLICATION={publication}")
    print(f"REMOTE_READBACK={remote}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build the governed G2B-HW0-PRODUCT-R2 evidence package."
    )
    parser.add_argument("--mode", choices=("pending", "refresh", "final"), required=True)
    parser.add_argument("--initial-commit")
    parser.add_argument("--readback-files", type=int)
    parser.add_argument("--readback-utc")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    build(args.mode, args.initial_commit, args.readback_files, args.readback_utc)
