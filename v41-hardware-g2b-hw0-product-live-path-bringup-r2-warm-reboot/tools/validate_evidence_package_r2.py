from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
from collections.abc import Mapping
from pathlib import Path, PurePosixPath
from typing import Any


PACKAGE_DIRECTORY = "v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot"
DEFAULT_ROOT = Path(r"C:\FPGA\V41_G2B_EVIDENCE") / PACKAGE_DIRECTORY
MANIFEST_NAME = "G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt"
STATE_NAME = "G2B_HW0_PRODUCT_R2_STATE.json"
GATE_MATRIX_NAME = "G2B_HW0_PRODUCT_R2_GATE_MATRIX.csv"
MAIN_REPORT_NAME = "V41_G2B_HW0_PRODUCT_R2_MAIN_REPORT.md"
BLOCKER = "BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE"
PENDING_PUBLICATION = "AWAITING_POST_COMMIT_REMOTE_READBACK"
EXPECTED_TRANSPORT_ABI = "AHD_C2H_TRANSPORT_ABI_V1"

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

EXPECTED_GATES = {
    "T0": "PASS",
    "T1": "BLOCKED",
    "T2": "NOT_REACHED",
    "T3": "NOT_REACHED",
    "T4": "NOT_REACHED",
    "T5": "NOT_REACHED",
}
EXPECTED_MATRIX_GATES = {
    **EXPECTED_GATES,
    "WARM_REBOOT": "PASS",
    "CANDIDATE_RETENTION": "PASS",
    "AHD_ENDPOINT": "PASS",
    "JTAG_PCIE_CORRELATION": "PASS",
    "PCIE_GEN2_X1": "PASS",
    "SAFE_AHD_XDMA_BIND": "BLOCKED",
    "XDMA_NODE_MAPPING": "NOT_REACHED",
}

TEXT_SUFFIXES = {
    ".csv",
    ".json",
    ".log",
    ".md",
    ".ps1",
    ".py",
    ".rpt",
    ".sh",
    ".tcl",
    ".txt",
    ".xdc",
}
FORBIDDEN_COMPONENTS = {
    ".cache",
    ".git",
    ".pytest_cache",
    "__pycache__",
    "cache",
    "credential",
    "credentials",
    "remote-readback",
    "remote_readback",
    "secret",
    "secrets",
}
FORBIDDEN_BASENAMES = {
    ".env",
    "id_ed25519",
    "id_rsa",
    "invoke-g2br1plink.ps1",
    "invoke-g2br2plink.ps1",
}
FORBIDDEN_SUFFIXES = {
    ".bak",
    ".key",
    ".kdbx",
    ".p12",
    ".pem",
    ".pfx",
    ".pw",
    ".pyc",
    ".pyo",
    ".swp",
    ".tmp",
}
PLINK_PASSWORD_AUDIT_FAILURE = b"PLINK_PW_OPTION_USED=" + b"YES"
CREDENTIAL_RELATIONSHIP_MARKER = b"SANITIZED_CONTEXTUAL_" + b"EQUALITY"
CONTENT_SCAN_EXEMPT_VALIDATORS = {
    "remote_readback_r2.py",
    "validate_evidence_package_r2.py",
    "validate_staged_snapshot_r2.py",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def add_check(condition: bool, failure: str, failures: list[str]) -> None:
    if not condition:
        failures.append(failure)


def safe_relative_name(name: str) -> bool:
    if not name or "\\" in name or name.startswith("/") or "\x00" in name:
        return False
    path = PurePosixPath(name)
    return all(part not in {"", ".", ".."} for part in path.parts)


def is_text_path(name: str) -> bool:
    return PurePosixPath(name).suffix.lower() in TEXT_SUFFIXES


def decode_utf8(name: str, data: bytes, failures: list[str]) -> str | None:
    if not is_text_path(name):
        return None
    generated_top_level = "/" not in name
    if generated_top_level and b"\r" in data:
        failures.append(f"NON_LF_LINE_ENDING:{name}")
    if generated_top_level and data and not data.endswith(b"\n"):
        failures.append(f"TEXT_FILE_MISSING_FINAL_LF:{name}")
    if generated_top_level and data.startswith(b"\xef\xbb\xbf"):
        failures.append(f"UTF8_BOM_FORBIDDEN:{name}")
    if generated_top_level and b"\x00" in data:
        failures.append(f"NUL_IN_TEXT_FILE:{name}")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        if generated_top_level:
            failures.append(f"TEXT_NOT_UTF8:{name}")
        return None


def validate_paths(files: Mapping[str, bytes], failures: list[str]) -> None:
    names = list(files)
    add_check(len(names) == len(set(names)), "DUPLICATE_PACKAGE_PATH", failures)
    folded: dict[str, str] = {}
    for name in names:
        add_check(safe_relative_name(name), f"UNSAFE_PACKAGE_PATH:{name}", failures)
        folded_name = name.casefold()
        if folded_name in folded and folded[folded_name] != name:
            failures.append(f"CASE_COLLIDING_PACKAGE_PATH:{folded[folded_name]}:{name}")
        folded[folded_name] = name

        path = PurePosixPath(name)
        lowered_parts = {part.casefold() for part in path.parts}
        if lowered_parts & FORBIDDEN_COMPONENTS:
            failures.append(f"FORBIDDEN_DIRECTORY_OR_COMPONENT:{name}")
        basename = path.name.casefold()
        if basename in FORBIDDEN_BASENAMES or basename.startswith("pw-"):
            failures.append(f"SENSITIVE_HELPER_OR_SECRET_FILE:{name}")
        if path.suffix.casefold() in FORBIDDEN_SUFFIXES:
            failures.append(f"SENSITIVE_OR_CACHE_SUFFIX:{name}")

    top_level = {name for name in names if "/" not in name}
    required = set(REQUIRED_TOP_LEVEL)
    if top_level != required:
        missing = sorted(required - top_level)
        extra = sorted(top_level - required)
        failures.append(f"TOP_LEVEL_21_FILE_SET_MISMATCH:missing={missing}:extra={extra}")
    top_level_directories = {name.split("/", 1)[0] for name in names if "/" in name}
    if top_level_directories != {"locks", "raw", "tools"}:
        failures.append(
            "TOP_LEVEL_DIRECTORY_SET_MISMATCH:"
            f"{sorted(top_level_directories)}"
        )


def validate_text_and_secrets(
    files: Mapping[str, bytes], failures: list[str]
) -> dict[str, str]:
    decoded: dict[str, str] = {}
    for name, data in files.items():
        text = decode_utf8(name, data, failures)
        if text is not None:
            decoded[name] = text

    for name, data in files.items():
        path = PurePosixPath(name)
        if (
            len(path.parts) == 2
            and path.parts[0].casefold() == "tools"
            and path.name.casefold() in CONTENT_SCAN_EXEMPT_VALIDATORS
        ):
            continue
        upper = data.upper()
        if re.search(rb"-----BEGIN [A-Z0-9 ]+ PRIVATE KEY-----", upper):
            failures.append(f"PRIVATE_KEY_DISCLOSURE:{name}")
        if PLINK_PASSWORD_AUDIT_FAILURE in upper:
            failures.append(f"PLINK_PW_ARGUMENT_USED:{name}")
        if CREDENTIAL_RELATIONSHIP_MARKER in upper:
            failures.append(f"CREDENTIAL_RELATIONSHIP_DISCLOSURE:{name}")
    return decoded


def parse_manifest(data: bytes, failures: list[str]) -> dict[str, str]:
    if b"\r" in data:
        failures.append("MANIFEST_NON_LF_LINE_ENDING")
    if not data.endswith(b"\n"):
        failures.append("MANIFEST_MISSING_FINAL_LF")
    if data.startswith(b"\xef\xbb\xbf"):
        failures.append("MANIFEST_UTF8_BOM_FORBIDDEN")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        failures.append("MANIFEST_NOT_UTF8")
        return {}

    entries: dict[str, str] = {}
    for line_number, line in enumerate(text.splitlines(), start=1):
        match = re.fullmatch(r"([0-9A-F]{64})  ([^\r\n]+)", line)
        if not match:
            failures.append(f"MALFORMED_MANIFEST_LINE:{line_number}:{line}")
            continue
        digest, relative = match.groups()
        if not safe_relative_name(relative):
            failures.append(f"UNSAFE_MANIFEST_PATH:{line_number}:{relative}")
            continue
        if relative == MANIFEST_NAME:
            failures.append("MANIFEST_NOT_SELF_EXCLUDING")
        if relative in entries:
            failures.append(f"DUPLICATE_MANIFEST_PATH:{relative}")
        entries[relative] = digest
    return entries


def json_object(name: str, data: bytes, failures: list[str]) -> dict[str, Any] | None:
    try:
        value = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        failures.append(f"INVALID_JSON:{name}:{exc}")
        return None
    if not isinstance(value, dict):
        failures.append(f"JSON_ROOT_NOT_OBJECT:{name}")
        return None
    return value


def nested(value: Mapping[str, Any], *keys: str) -> Any:
    current: Any = value
    for key in keys:
        if not isinstance(current, Mapping) or key not in current:
            return None
        current = current[key]
    return current


def check_any_path(
    state: Mapping[str, Any],
    paths: tuple[tuple[str, ...], ...],
    expected: Any,
    label: str,
    failures: list[str],
) -> None:
    observed = [(path, nested(state, *path)) for path in paths]
    if not any(value == expected for _, value in observed):
        rendered = ",".join(f"{'.'.join(path)}={value!r}" for path, value in observed)
        failures.append(f"STATE_{label}_MISMATCH:{rendered}:expected={expected!r}")


def validate_state(
    state: Mapping[str, Any], expected_publication: str | None, failures: list[str]
) -> None:
    exact = {
        "task": "G2B-HW0-PRODUCT-R2",
        "engineering_gate": "BLOCKED",
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "project_state_rev_at_start": 8,
        "project_state_rev_at_end": 8,
        "meta_8a": "VERIFIED",
    }
    for key, expected in exact.items():
        add_check(state.get(key) == expected, f"STATE_{key}_MISMATCH", failures)

    add_check(
        state.get("transport_abi") == "NOT_REACHED",
        "STATE_OBSERVED_TRANSPORT_ABI_MISMATCH",
        failures,
    )
    add_check(
        state.get("abi_version") is None,
        "STATE_OBSERVED_ABI_VERSION_MISMATCH",
        failures,
    )

    expected_state_gates = {key.casefold(): value for key, value in EXPECTED_GATES.items()}
    add_check(state.get("gates") == expected_state_gates, "STATE_GATES_MISMATCH", failures)

    publication = state.get("evidence_publication")
    add_check(
        publication in {PENDING_PUBLICATION, "PASS"},
        f"STATE_evidence_publication_INVALID:{publication!r}",
        failures,
    )
    if expected_publication is not None:
        add_check(
            publication == expected_publication,
            f"STATE_evidence_publication_MISMATCH:{publication!r}:{expected_publication!r}",
            failures,
        )

    check_any_path(
        state,
        (("reboot", "warm_reboots_executed"), ("operation_counts", "warm_reboots"), ("operation_counts", "reboots")),
        1,
        "WARM_REBOOT_COUNT",
        failures,
    )

    authorizations = state.get("authorizations")
    expected_authorizations = {
        "owner_hardware": "GRANTED",
        "owner_warm_reboot": "GRANTED",
        "maximum_warm_reboots": 1,
        "power_cycle": "DENIED",
        "sram_reprogramming_in_r2": "DENIED",
        "flash_programming": "DENIED",
        "legacy_mmio_reads": "GRANTED",
        "legacy_mmio_writes": "DENIED",
    }
    if not isinstance(authorizations, Mapping):
        failures.append("STATE_AUTHORIZATIONS_NOT_OBJECT")
    else:
        for key, expected in expected_authorizations.items():
            add_check(
                authorizations.get(key) == expected,
                f"STATE_AUTHORIZATION_MISMATCH:{key}",
                failures,
            )
    check_any_path(
        state,
        (("reboot", "maximum_warm_reboots"), ("authorizations", "maximum_warm_reboots")),
        1,
        "MAXIMUM_WARM_REBOOTS",
        failures,
    )

    pcie = state.get("pcie")
    if isinstance(pcie, Mapping):
        add_check(pcie.get("driver") is None, "STATE_PCIE_DRIVER_MISMATCH", failures)
        add_check(pcie.get("rescans") == 0, "STATE_PCIE_RESCAN_COUNT_MISMATCH", failures)
        add_check(pcie.get("resets") == 0, "STATE_PCIE_RESET_COUNT_MISMATCH", failures)
    check_any_path(
        state,
        (
            ("jtag", "candidate_retention"),
            ("candidate", "retained_across_warm_reboot"),
            ("jtag", "candidate_retained_across_warm_reboot"),
            ("reboot", "candidate_retained_across_warm_reboot"),
        ),
        "PASS",
        "CANDIDATE_RETENTION",
        failures,
    )
    check_any_path(
        state,
        (
            ("jtag", "post_reboot_pcie_correlation"),
            ("jtag", "correlation"),
            ("pcie", "jtag_to_pcie_correlation"),
        ),
        "PASS",
        "JTAG_PCIE_CORRELATION",
        failures,
    )
    check_any_path(
        state,
        (("pcie", "endpoint_after_warm_reboot"), ("pcie", "endpoint"), ("pcie", "endpoint_gate")),
        "PASS",
        "PCIE_ENDPOINT",
        failures,
    )
    check_any_path(state, (("pcie", "endpoint_bdf"),), "0000:01:00.0", "PCIE_BDF", failures)
    check_any_path(state, (("pcie", "vendor_device"),), "10ee:7011", "PCIE_VENDOR_DEVICE", failures)
    check_any_path(
        state,
        (("pcie", "upstream_root_port"), ("pcie", "upstream_bdf")),
        "0000:00:01.1",
        "PCIE_UPSTREAM_BDF",
        failures,
    )
    check_any_path(
        state,
        (("pcie", "gen2_x1_hardware_gate"), ("pcie", "gen2_x1_gate")),
        "PASS",
        "PCIE_GEN2_X1",
        failures,
    )

    xdma = state.get("xdma")
    if not isinstance(xdma, Mapping):
        failures.append("STATE_XDMA_NOT_OBJECT")
    else:
        add_check(xdma.get("module_loaded") is False, "STATE_XDMA_MODULE_LOADED_MISMATCH", failures)
        add_check(xdma.get("node_count") == 0, "STATE_XDMA_NODE_COUNT_MISMATCH", failures)
        add_check(xdma.get("module_loads") == 0, "STATE_XDMA_LOAD_COUNT_MISMATCH", failures)
        add_check(xdma.get("binds") == 0, "STATE_XDMA_BIND_COUNT_MISMATCH", failures)
        add_check(xdma.get("unbinds") == 0, "STATE_XDMA_UNBIND_COUNT_MISMATCH", failures)
        add_check(
            xdma.get("gate") in {"FAIL", "BLOCKED", "SAFE_BIND_UNAVAILABLE"},
            "STATE_XDMA_GATE_MISMATCH",
            failures,
        )
        add_check(xdma.get("safe_ahd_bind") == "BLOCKED", "STATE_XDMA_SAFE_BIND_MISMATCH", failures)
        add_check(
            xdma.get("decision") == "DO_NOT_LOAD_OR_BIND",
            "STATE_XDMA_DECISION_MISMATCH",
            failures,
        )
        add_check(
            xdma.get("matches_exact_pci_modalias") is False,
            "STATE_XDMA_PCI_MODALIAS_MATCH_MISMATCH",
            failures,
        )
        add_check(
            xdma.get("installed_module_aliases") == ["platform:xdma"],
            "STATE_XDMA_MODULE_ALIASES_MISMATCH",
            failures,
        )
        add_check(
            xdma.get("matching_platform_devices") == 0,
            "STATE_XDMA_PLATFORM_DEVICE_COUNT_MISMATCH",
            failures,
        )
        add_check(
            xdma.get("node_to_bdf_mapping") == "NOT_REACHED",
            "STATE_XDMA_NODE_MAPPING_MISMATCH",
            failures,
        )

    operation_counts = state.get("operation_counts")
    if not isinstance(operation_counts, Mapping):
        failures.append("STATE_OPERATION_COUNTS_NOT_OBJECT")
    else:
        zero_names = {
            "dma_captures",
            "dma_operations",
            "driver_binds",
            "driver_unbinds",
            "flash_programming",
            "flash_programs",
            "g2b_mmio_reads",
            "g2b_mmio_writes",
            "legacy_mmio_reads",
            "legacy_mmio_writes",
            "module_loads",
            "pcie_config_writes",
            "pcie_rescans",
            "pcie_resets",
            "power_cycles",
            "sram_programming",
            "sram_programs_r2",
            "stream_enable_writes",
            "xdma_binds",
            "xdma_loads",
            "xdma_module_loads",
            "xdma_unbinds",
        }
        for name, value in operation_counts.items():
            if name in zero_names:
                add_check(value == 0, f"STATE_OPERATION_COUNT_NONZERO:{name}:{value!r}", failures)

        for semantic, alternatives in {
            "POWER_CYCLES": ("power_cycles",),
            "SRAM_PROGRAMMING": ("sram_programming", "fpga_programming", "sram_programs_r2"),
            "LEGACY_MMIO_READS": ("legacy_mmio_reads",),
            "LEGACY_MMIO_WRITES": ("legacy_mmio_writes",),
            "G2B_MMIO_READS": ("g2b_mmio_reads",),
            "G2B_MMIO_WRITES": ("g2b_mmio_writes",),
            "DMA_CAPTURES": ("dma_captures", "dma_operations"),
            "XDMA_LOADS": ("xdma_loads", "module_loads", "xdma_module_loads"),
            "XDMA_BINDS": ("xdma_binds", "driver_binds"),
        }.items():
            values = [operation_counts.get(name) for name in alternatives if name in operation_counts]
            if not values or not all(value == 0 for value in values):
                failures.append(f"STATE_OPERATION_{semantic}_MISMATCH:{values!r}")

    protected_state = state.get("protected_state")
    if not isinstance(protected_state, Mapping):
        failures.append("STATE_PROTECTED_STATE_NOT_OBJECT")
    else:
        for key in (
            "fpga_ahd_modified",
            "v41_g2b_tracked_source_modified",
            "active_xdc_modified",
            "ssot_modified",
            "flash_modified",
            "driver_files_modified",
            "package_state_modified",
        ):
            add_check(
                protected_state.get(key) is False,
                f"STATE_PROTECTED_BOUNDARY_MISMATCH:{key}",
                failures,
            )

    check_any_path(
        state,
        (
            ("ssot_update_required",),
            ("protected_state", "ssot_update_required"),
            ("publication", "ssot_update_required"),
            ("final_response_fields", "ssot_update_required"),
        ),
        "NO",
        "SSOT_UPDATE_REQUIRED",
        failures,
    )

    publication_state = state.get("publication")
    if not isinstance(publication_state, Mapping):
        failures.append("STATE_PUBLICATION_NOT_OBJECT")
    else:
        add_check(
            publication_state.get("repository") == "lukaszsudul/AHD-diagnostic-evidence",
            "STATE_PUBLICATION_REPOSITORY_MISMATCH",
            failures,
        )
        add_check(publication_state.get("branch") == "main", "STATE_PUBLICATION_BRANCH_MISMATCH", failures)
        add_check(
            publication_state.get("directory") == PACKAGE_DIRECTORY,
            "STATE_PUBLICATION_DIRECTORY_MISMATCH",
            failures,
        )
        remote = publication_state.get("remote_readback")
        expected_remote = "PASS" if publication == "PASS" else "NOT_RUN"
        add_check(remote == expected_remote, f"STATE_REMOTE_READBACK_MISMATCH:{remote!r}", failures)
        final_fields = state.get("final_response_fields")
        if publication == "PASS":
            initial_commit = publication_state.get("initial_evidence_commit")
            add_check(
                isinstance(initial_commit, str)
                and re.fullmatch(r"[0-9a-fA-F]{40}", initial_commit) is not None,
                "STATE_INITIAL_EVIDENCE_COMMIT_INVALID",
                failures,
            )
            add_check(
                publication_state.get("remote_readback_commit") == initial_commit,
                "STATE_INITIAL_REMOTE_READBACK_COMMIT_MISMATCH",
                failures,
            )
            add_check(
                isinstance(publication_state.get("remote_readback_files"), int)
                and publication_state.get("remote_readback_files") > 0,
                "STATE_INITIAL_REMOTE_READBACK_FILE_COUNT_INVALID",
                failures,
            )
            add_check(
                publication_state.get("remote_readback_mismatches") == 0,
                "STATE_INITIAL_REMOTE_READBACK_MISMATCH_COUNT_INVALID",
                failures,
            )
            add_check(
                publication_state.get("completion_commit") == "CONTAINING_GIT_COMMIT",
                "STATE_COMPLETION_COMMIT_PLACEHOLDER_MISMATCH",
                failures,
            )
            add_check(
                publication_state.get("external_final_commit_pinned_readback")
                == "REQUIRED_AFTER_FINAL_COMMIT_AND_RECORDED_OUTSIDE_THIS_SELF_REFERENTIAL_PACKAGE",
                "STATE_EXTERNAL_FINAL_READBACK_CONTRACT_MISMATCH",
                failures,
            )
            if isinstance(final_fields, Mapping):
                add_check(
                    final_fields.get("evidence_commit") == "CONTAINING_GIT_COMMIT",
                    "STATE_FINAL_RESPONSE_EVIDENCE_COMMIT_PLACEHOLDER_MISMATCH",
                    failures,
                )
        else:
            add_check(
                publication_state.get("initial_evidence_commit") == "PENDING_CONTAINING_GIT_COMMIT",
                "STATE_PENDING_INITIAL_COMMIT_MISMATCH",
                failures,
            )
            add_check(
                publication_state.get("external_final_commit_pinned_readback") == "NOT_REACHED",
                "STATE_PENDING_EXTERNAL_FINAL_READBACK_MISMATCH",
                failures,
            )


def validate_gate_matrix(data: bytes, failures: list[str]) -> None:
    try:
        text = data.decode("utf-8")
        rows = list(csv.DictReader(io.StringIO(text, newline="")))
    except (UnicodeDecodeError, csv.Error) as exc:
        failures.append(f"INVALID_GATE_MATRIX:{exc}")
        return
    if not rows or "gate" not in rows[0] or "result" not in rows[0]:
        failures.append("GATE_MATRIX_REQUIRED_COLUMNS_MISSING")
        return
    observed: dict[str, str] = {}
    for row in rows:
        gate = row.get("gate", "")
        if gate in observed:
            failures.append(f"DUPLICATE_GATE_MATRIX_ROW:{gate}")
        observed[gate] = row.get("result", "")
        if gate in {"SAFE_AHD_XDMA_BIND", "T1"}:
            row_text = " ".join(str(value) for value in row.values())
            add_check(BLOCKER in row_text, f"{gate}_ROW_MISSING_EXACT_BLOCKER", failures)
    for gate, expected in EXPECTED_MATRIX_GATES.items():
        add_check(observed.get(gate) == expected, f"GATE_{gate}_MISMATCH", failures)


def validate_literals(decoded: Mapping[str, str], failures: list[str]) -> None:
    main = decoded.get(MAIN_REPORT_NAME, "")
    for literal in (
        BLOCKER,
        "0000:01:00.0",
        "10ee:7011",
        "0000:00:01.1",
        "platform:xdma",
        "SSOT_UPDATE_REQUIRED = NO",
        "HARDWARE_THROUGHPUT_288_MB_S",
    ):
        add_check(literal.casefold() in main.casefold(), f"MAIN_MISSING_LITERAL:{literal}", failures)
    for gate, result in EXPECTED_GATES.items():
        add_check(
            re.search(rf"(?im)^.*\b{re.escape(gate)}\b.*\b{re.escape(result)}\b", main) is not None,
            f"MAIN_GATE_LITERAL_MISMATCH:{gate}:{result}",
            failures,
        )

    for name in (
        "G2B_HW0_PRODUCT_R2_RUNTIME_IDENTITY.md",
        "G2B_HW0_PRODUCT_R2_FIRST_RECORD_ANALYSIS.md",
        "G2B_HW0_PRODUCT_R2_FINITE_CAPTURE_SUMMARY.md",
        "G2B_HW0_PRODUCT_R2_FRAME_RECONSTRUCTION.md",
        "G2B_HW0_PRODUCT_R2_CONTINUOUS_CAPTURE_SUMMARY.md",
    ):
        add_check("NOT_REACHED" in decoded.get(name, ""), f"NOT_REACHED_LITERAL_MISSING:{name}", failures)

    for name in (
        "G2B_HW0_PRODUCT_R2_PCIE_XDMA_INVENTORY.md",
        "G2B_HW0_PRODUCT_R2_FINAL_HARDWARE_STATE.md",
    ):
        add_check(BLOCKER in decoded.get(name, ""), f"BLOCKER_LITERAL_MISSING:{name}", failures)

    index = decoded.get("G2B_HW0_PRODUCT_R2_EVIDENCE_INDEX.md", "")
    for name in REQUIRED_TOP_LEVEL:
        add_check(name in index, f"EVIDENCE_INDEX_MISSING_REQUIRED_NAME:{name}", failures)

    generated_top_level_text = "\n".join(
        text for name, text in decoded.items() if "/" not in name
    )
    add_check(
        EXPECTED_TRANSPORT_ABI in generated_top_level_text,
        f"EXPECTED_TRANSPORT_ABI_LITERAL_MISSING:{EXPECTED_TRANSPORT_ABI}",
        failures,
    )


def validate_not_reached_csv(name: str, data: bytes, failures: list[str]) -> None:
    try:
        rows = list(csv.DictReader(io.StringIO(data.decode("utf-8"), newline="")))
    except (UnicodeDecodeError, csv.Error) as exc:
        failures.append(f"INVALID_CSV:{name}:{exc}")
        return
    add_check(bool(rows), f"EMPTY_NOT_REACHED_CSV:{name}", failures)
    for row_number, row in enumerate(rows, start=2):
        add_check(
            row.get("status") == "NOT_REACHED",
            f"CSV_STATUS_MISMATCH:{name}:{row_number}:{row.get('status')!r}",
            failures,
        )


def validate_file_map(
    files: Mapping[str, bytes], expected_publication: str | None = None
) -> list[str]:
    failures: list[str] = []
    validate_paths(files, failures)
    decoded = validate_text_and_secrets(files, failures)

    manifest_data = files.get(MANIFEST_NAME)
    if manifest_data is None:
        failures.append("MANIFEST_MISSING")
    else:
        entries = parse_manifest(manifest_data, failures)
        actual = set(files) - {MANIFEST_NAME}
        if set(entries) != actual:
            missing = sorted(actual - set(entries))
            extra = sorted(set(entries) - actual)
            failures.append(f"MANIFEST_PATH_SET_MISMATCH:missing={missing}:extra={extra}")
        for name, expected in entries.items():
            if name in files:
                actual_digest = sha256(files[name])
                add_check(
                    actual_digest == expected,
                    f"MANIFEST_HASH_MISMATCH:{name}:{expected}:{actual_digest}",
                    failures,
                )

    state_data = files.get(STATE_NAME)
    if state_data is not None:
        state = json_object(STATE_NAME, state_data, failures)
        if state is not None:
            validate_state(state, expected_publication, failures)

    gate_data = files.get(GATE_MATRIX_NAME)
    if gate_data is not None:
        validate_gate_matrix(gate_data, failures)

    for name in (
        "G2B_HW0_PRODUCT_R2_LEGACY_MMIO_RAW.csv",
        "G2B_HW0_PRODUCT_R2_G2B_MMIO_BASELINE.csv",
    ):
        if name in files:
            validate_not_reached_csv(name, files[name], failures)

    validate_literals(decoded, failures)
    return failures


def package_files(root: Path, failures: list[str]) -> dict[str, bytes]:
    files: dict[str, bytes] = {}
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix()):
        relative = path.relative_to(root).as_posix()
        if path.is_symlink():
            failures.append(f"SYMLINK_FORBIDDEN:{relative}")
            continue
        if path.is_dir():
            lowered_parts = {part.casefold() for part in PurePosixPath(relative).parts}
            if lowered_parts & FORBIDDEN_COMPONENTS:
                failures.append(f"FORBIDDEN_DIRECTORY_OR_COMPONENT:{relative}")
            continue
        if path.is_file():
            files[relative] = path.read_bytes()
    return files


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate the exact R2 evidence package bytes.")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--expected-publication", choices=(PENDING_PUBLICATION, "PASS"))
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = args.root.resolve()
    failures: list[str] = []
    if not root.is_dir():
        failures.append(f"PACKAGE_DIRECTORY_MISSING:{root}")
        files: dict[str, bytes] = {}
    else:
        add_check(root.name == PACKAGE_DIRECTORY, f"PACKAGE_DIRECTORY_NAME_MISMATCH:{root.name}", failures)
        top_level_directories = {
            path.name for path in root.iterdir() if path.is_dir()
        }
        add_check(
            top_level_directories == {"locks", "raw", "tools"},
            f"TOP_LEVEL_DIRECTORY_SET_MISMATCH:{sorted(top_level_directories)}",
            failures,
        )
        files = package_files(root, failures)
        failures.extend(validate_file_map(files, args.expected_publication))

    if failures:
        print("R2_EVIDENCE_VALIDATION=FAIL")
        for failure in failures:
            print(f"R2_EVIDENCE_FAILURE={failure}")
        raise SystemExit(1)

    manifest_entries = len(files) - 1
    print("R2_EVIDENCE_VALIDATION=PASS")
    print(f"R2_REQUIRED_TOP_LEVEL_FILES={len(REQUIRED_TOP_LEVEL)}")
    print(f"R2_PACKAGE_FILES={len(files)}")
    print(f"R2_MANIFEST_ENTRIES={manifest_entries}")
    print("R2_MANIFEST_SELF_EXCLUDED=PASS")
    print("R2_MANIFEST_MISMATCHES=0")
    print("R2_GENERATED_TOP_LEVEL_LINE_ENDINGS=LF")
    print("R2_NESTED_EXECUTION_EVIDENCE_BYTES=PRESERVED")
    print("R2_SENSITIVE_PATHS=0")


if __name__ == "__main__":
    main()
