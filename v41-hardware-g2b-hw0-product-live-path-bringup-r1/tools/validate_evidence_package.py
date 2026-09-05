from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(r"C:\FPGA\V41_G2B_EVIDENCE\v41-hardware-g2b-hw0-product-live-path-bringup-r1")
MANIFEST = ROOT / "G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt"
REQUIRED = {
    "V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md",
    "G2B_HW0_PRODUCT_R1_AUTHORIZATION_RECEIPT.md",
    "G2B_HW0_PRODUCT_R1_CANDIDATE_VERIFICATION.md",
    "G2B_HW0_PRODUCT_R1_DUT_AUTHORITY_AND_LOCK_RECEIPT.md",
    "G2B_HW0_PRODUCT_R1_PREPROGRAM_INVENTORY.md",
    "G2B_HW0_PRODUCT_R1_JTAG_PCIE_CORRELATION.md",
    "G2B_HW0_PRODUCT_R1_PROGRAMMING_RECEIPT.md",
    "G2B_HW0_PRODUCT_R1_PCIE_XDMA_INVENTORY.md",
    "G2B_HW0_PRODUCT_R1_LEGACY_MMIO_RAW.csv",
    "G2B_HW0_PRODUCT_R1_RUNTIME_IDENTITY.md",
    "G2B_HW0_PRODUCT_R1_G2B_MMIO_BASELINE.csv",
    "G2B_HW0_PRODUCT_R1_FIRST_RECORD_ANALYSIS.md",
    "G2B_HW0_PRODUCT_R1_FINITE_CAPTURE_SUMMARY.md",
    "G2B_HW0_PRODUCT_R1_FRAME_RECONSTRUCTION.md",
    "G2B_HW0_PRODUCT_R1_CONTINUOUS_CAPTURE_SUMMARY.md",
    "G2B_HW0_PRODUCT_R1_GATE_MATRIX.csv",
    "G2B_HW0_PRODUCT_R1_FINAL_HARDWARE_STATE.md",
    "G2B_HW0_PRODUCT_R1_STATE.json",
    "G2B_HW0_PRODUCT_R1_EVIDENCE_INDEX.md",
    "G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def check(condition: bool, name: str, failures: list[str]) -> None:
    if not condition:
        failures.append(name)


def main() -> None:
    failures: list[str] = []
    check(ROOT.is_dir(), "PACKAGE_DIRECTORY_MISSING", failures)
    top = {path.name for path in ROOT.iterdir() if path.is_file()}
    check(REQUIRED <= top, f"MISSING_REQUIRED:{sorted(REQUIRED - top)}", failures)
    check(not any(ROOT.glob("*FIRST_RECORD.bin")), "UNEXPECTED_FIRST_RECORD_BINARY", failures)
    check(not any(ROOT.glob("*.png")), "UNEXPECTED_FRAME_PAYLOAD", failures)
    check(not (ROOT / "tools" / "Invoke-G2BR1Plink.ps1").exists(), "SENSITIVE_HELPER_PUBLISHED", failures)

    state = json.loads((ROOT / "G2B_HW0_PRODUCT_R1_STATE.json").read_text(encoding="utf-8"))
    expected_state = {
        "engineering_gate": "BLOCKED",
        "overall_result": "BLOCKED",
        "first_blocker": "BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE",
        "project_state_rev_at_start": 8,
        "project_state_rev_at_end": 8,
        "meta_8a": "VERIFIED",
        "additional_legacy_mmio_read_authorization": "GRANTED",
        "legacy_mmio_write_authorization": "DENIED",
        "hardware_accessed": True,
        "hardware_throughput_288_mb_s": "NOT_PROVEN",
        "g2b_hw_qualification": "NOT_PROVEN",
        "ssot_update_required": "NO",
    }
    for key, expected in expected_state.items():
        check(state.get(key) == expected, f"STATE_{key}_MISMATCH", failures)
    check(state["gates"] == {"t0": "PASS", "t1": "BLOCKED", "t2": "NOT_REACHED", "t3": "NOT_REACHED", "t4": "NOT_REACHED", "t5": "NOT_REACHED"}, "STATE_GATES_MISMATCH", failures)
    check(state["programming"]["invocations"] == 1, "PROGRAM_COUNT_MISMATCH", failures)
    check(state["programming"]["done"] == 1, "DONE_MISMATCH", failures)
    check(state["pcie"]["targeted_recovery_operations"] == 0, "RECOVERY_COUNT_MISMATCH", failures)
    check(state["xdma"]["node_count"] == 0, "XDMA_NODE_COUNT_MISMATCH", failures)
    check(all(value == 0 for value in state["operation_counts"].values()), "MUTATION_COUNT_NONZERO", failures)
    check(state["authoritative_project_state"] == {
        "g2b_lut1": "ACCEPTED / OFFLINE_QUALIFIED",
        "candidate_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
        "g2b_hw0_product_readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
        "initial_source": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
        "meta_8a": "PROMOTED / VERIFIED",
    }, "AUTHORITATIVE_PROJECT_STATE_MISMATCH", failures)

    with (ROOT / "G2B_HW0_PRODUCT_R1_GATE_MATRIX.csv").open(encoding="utf-8", newline="") as handle:
        gates = {row["gate"]: row["result"] for row in csv.DictReader(handle)}
    expected_gates = {"T0": "PASS", "T1": "BLOCKED", "T2": "NOT_REACHED", "T3": "NOT_REACHED", "T4": "NOT_REACHED", "T5": "NOT_REACHED", "AHD_ENDPOINT": "FAIL"}
    for gate, expected in expected_gates.items():
        check(gates.get(gate) == expected, f"GATE_{gate}_MISMATCH", failures)

    for name in ("G2B_HW0_PRODUCT_R1_LEGACY_MMIO_RAW.csv", "G2B_HW0_PRODUCT_R1_G2B_MMIO_BASELINE.csv"):
        with (ROOT / name).open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        check(len(rows) == 1 and rows[0]["status"] == "NOT_REACHED", f"{name}_NOT_REACHED_MISMATCH", failures)

    main_text = (ROOT / "V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md").read_text(encoding="utf-8")
    for literal in (
        "BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE",
        "AUTO_RECOVERY_FOUND=0",
        "DONE=1",
        "T0 passed",
        "T1 is `BLOCKED`",
        "0x0000..0x0030",
        "0x0080..0x00B4",
        "Legacy-MMIO write authorization: `DENIED`",
        "G2B-LUT1 = ACCEPTED / OFFLINE_QUALIFIED",
        "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
        "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
        "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
        "HARDWARE_THROUGHPUT_288_MB_S",
        "G2B-HW qualification = NOT_PROVEN",
        "SSOT_UPDATE_REQUIRED = NO",
    ):
        check(literal in main_text, f"MAIN_MISSING_LITERAL:{literal}", failures)

    all_text = "\n".join(
        path.read_text(encoding="utf-8", errors="replace")
        for path in ROOT.rglob("*")
        if path.is_file()
        and path.name != "validate_evidence_package.py"
        and path.suffix.lower() in {".md", ".csv", ".json", ".txt", ".log", ".ps1", ".sh", ".tcl", ".py"}
    )
    check("PRIVATE KEY" not in all_text, "PRIVATE_KEY_DISCLOSURE", failures)
    check(not re.search(r"PLINK_PW_OPTION_USED=YES", all_text), "PLINK_PW_ARGUMENT_USED", failures)
    check("SANITIZED_CONTEXTUAL_EQUALITY" not in all_text, "CREDENTIAL_RELATIONSHIP_DISCLOSURE", failures)
    check(not any(path.name.startswith("pw-") for path in ROOT.rglob("*")), "TRANSIENT_PWFILE_PUBLISHED", failures)

    expected_manifest: dict[str, str] = {}
    for line in MANIFEST.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9A-F]{64})  (.+)", line)
        check(match is not None, f"MALFORMED_MANIFEST_LINE:{line}", failures)
        if match:
            expected_manifest[match.group(2)] = match.group(1)
    actual_paths = {
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file() and path != MANIFEST
    }
    check(set(expected_manifest) == actual_paths, "MANIFEST_PATH_SET_MISMATCH", failures)
    for relative, expected in expected_manifest.items():
        check(digest(ROOT / relative) == expected, f"MANIFEST_HASH_MISMATCH:{relative}", failures)

    if failures:
        print("VALIDATION=FAIL")
        for failure in failures:
            print(f"FAILURE={failure}")
        raise SystemExit(1)
    print("VALIDATION=PASS")
    print(f"REQUIRED_FILES={len(REQUIRED)}")
    print(f"MANIFEST_ENTRIES={len(expected_manifest)}")
    print("MANIFEST_MISMATCHES=0")
    print(f"PUBLICATION_STATUS={state['evidence_publication']}")


if __name__ == "__main__":
    main()
