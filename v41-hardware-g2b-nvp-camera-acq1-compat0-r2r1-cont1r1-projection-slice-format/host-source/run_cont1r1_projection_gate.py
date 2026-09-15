"""Sixteen-test CONT1R1 host projection and preserved-snapshot gate."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path


EXPECTED_JSON_SHA256 = "F69884964978A0C793C9C5235C264B1FA88F2B4ADBE37403B1CB27D26555207B"
EXPECTED_BIN_SHA256 = "5930C78AA52AEC08F09E837D2C1E20EBBB9527A36E49647FACF273F7206D0AD9"
EXPECTED_OLD_CONTROLLER_SHA256 = "33C47010ECF0349FB25220DC063F3C6C997F86378F4BD0F62DEA163FD84269C4"
EXPECTED_MANIFEST_SHA256 = "2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise AssertionError(reason)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle-root", type=Path, required=True)
    parser.add_argument("--prior-bundle-root", type=Path, required=True)
    parser.add_argument("--snapshot-json", type=Path, required=True)
    parser.add_argument("--snapshot-bin", type=Path, required=True)
    parser.add_argument("--output-json", type=Path, required=True)
    args = parser.parse_args()

    bundle = args.bundle_root.resolve(strict=True)
    prior = args.prior_bundle_root.resolve(strict=True)
    snapshot_json = args.snapshot_json.resolve(strict=True)
    snapshot_bin = args.snapshot_bin.resolve(strict=True)
    sys.path.insert(0, str(bundle))

    import cont1r1_projection as projection
    from scan1.manifest import load_and_validate
    import g2b_nvp_camera_acq1_compat0_r2r1_controller as controller

    entries, _prohibited, manifest = load_and_validate()
    manifest_keys = {(item.bank, item.register) for item in entries}
    snapshot = json.loads(snapshot_json.read_text(encoding="utf-8"))
    results: list[dict] = []

    def test(test_id: str, requirement: str, function) -> None:
        try:
            detail = function()
            results.append({
                "test": test_id,
                "requirement": requirement,
                "result": "PASS",
                "detail": detail or "PASS",
            })
        except Exception as error:
            results.append({
                "test": test_id,
                "requirement": requirement,
                "result": "FAIL",
                "detail": f"{type(error).__name__}:{error}",
            })

    def t1():
        receipt = projection.manifest_preflight()
        require(receipt["manifest_entry_count"] == 82, "ENTRY_COUNT")
        require(receipt["manifest_bank_group_count"] == 10, "GROUP_COUNT")
        require(receipt["missing_projection_keys"] == [], "MISSING_KEYS")
        return "exact 82-entry manifest projection preflight PASS"

    def t2():
        stale = copy.deepcopy(projection.load_schema())
        stale["channel_families"].append({
            "semantic_family": "old_wrong_family",
            "bank": 1,
            "base_register": 0x88,
            "channel_range": [0, 3],
            "register_rule": "base_register_plus_channel",
            "read_safe_authority": "NONE",
        })
        try:
            projection.projection_key_preflight(manifest_keys, stale)
        except projection.ProjectionGateError as error:
            text = str(error)
            require(text.startswith("HOST_PROJECTION_KEY_NOT_IN_SCANNER_MANIFEST:"), "WRONG_REASON")
            for register in range(0x88, 0x8C):
                require(f"(0x01,0x{register:02X})" in text, f"MISSING_0x{register:02X}")
            return text
        raise AssertionError("OLD_0x88_REQUIREMENT_UNEXPECTEDLY_PASSED")

    def t3():
        expanded = projection.expand_schema()
        keys = {(item["bank"], item["register"]) for item in expanded if item["semantic_family"] == "adc_clock_delay"}
        expected = {(1, register) for register in range(0x84, 0x88)}
        require(keys == expected, "ADC_KEYS")
        require(keys <= manifest_keys, "ADC_NOT_IN_MANIFEST")
        return "Bank1/0x84-0x87 present and mapped to ADC clock delay"

    def t4():
        expanded = projection.expand_schema()
        keys = {(item["bank"], item["register"]) for item in expanded if item["semantic_family"] == "pre_clock"}
        expected = {(1, register) for register in range(0x8C, 0x90)}
        require(keys == expected, "PRECLOCK_KEYS")
        require(keys <= manifest_keys, "PRECLOCK_NOT_IN_MANIFEST")
        return "Bank1/0x8C-0x8F present and mapped to pre-clock"

    def t5():
        wrong_bank = (manifest_keys - {(1, 0x84)}) | {(0, 0x84)}
        try:
            projection.projection_key_preflight(wrong_bank)
        except projection.ProjectionGateError as error:
            require("(0x01,0x84)" in str(error), "FULL_KEY_NOT_ENFORCED")
            return "same register in Bank0 does not satisfy Bank1/0x84"
        raise AssertionError("WRONG_BANK_SATISFIED_REQUIREMENT")

    def t6():
        reduced = manifest_keys - {(1, 0x8F)}
        try:
            projection.projection_key_preflight(reduced)
        except projection.ProjectionGateError as error:
            require("(0x01,0x8F)" in str(error), "REMOVED_KEY_NOT_REPORTED")
            return str(error)
        raise AssertionError("REMOVED_REQUIRED_KEY_UNEXPECTEDLY_PASSED")

    def t7():
        receipt = projection.projection_key_preflight(manifest_keys | {(0xFE, 0xED)})
        require(receipt["result"] == "PASS", "EXTRA_KEY_FAILED")
        return "unused extra manifest key does not alter projection compatibility"

    def t8():
        controller.validate_scan(snapshot, None)
        projected = projection.configuration_projection(snapshot)
        require(len(projected) == 13, "PROJECTION_COUNT")
        return "exact preserved CONT1 snapshot host qualification PASS"

    def t9():
        require(sha256(snapshot_json) == EXPECTED_JSON_SHA256, "JSON_BYTE_IDENTITY")
        require(sha256(snapshot_bin) == EXPECTED_BIN_SHA256, "BIN_BYTE_IDENTITY")
        require(snapshot["raw_snapshot_sha256"] == EXPECTED_BIN_SHA256, "EMBEDDED_BIN_IDENTITY")
        require(snapshot["raw_snapshot_size"] == snapshot_bin.stat().st_size == 584, "BIN_SIZE")
        return "JSON and 584-byte raw snapshot remain byte-identical"

    def t10():
        require(snapshot["entry_count"] == 82, "ENTRY_RECEIPT")
        require(snapshot["bank_group_count"] == 10, "GROUP_RECEIPT")
        require(snapshot["transaction_count"] == 105, "TRANSACTION_RECEIPT")
        require(snapshot["entry_bank_restore"] == "PASS", "BANK_RESTORE")
        require(snapshot["entry_bank"] == snapshot["exit_bank"], "ENTRY_EXIT_BANK")
        return "82/82 entries, 10/10 groups, 105/105 transactions, restore PASS"

    def t11():
        new_source = (bundle / "cont1r1_projection.py").read_text(encoding="utf-8")
        forbidden = ("ExecutorController", "Command.", ".issue(", "MmioDevice")
        require(all(token not in new_source for token in forbidden), "WRITE_PATH_TOKEN_IN_PROJECTION")
        for path in (prior / "acq1_compat0_r2").rglob("*"):
            if path.is_file():
                relative = path.relative_to(prior)
                current = bundle / relative
                require(current.is_file() and sha256(current) == sha256(path), f"ACQ_CHANGED:{relative}")
        return "no functional NVP write path added; ACQ controller subtree byte-identical"

    def t12():
        for relative in (Path("scan1"), Path("scan1_launcher.py")):
            old_path = prior / relative
            paths = [old_path] if old_path.is_file() else list(old_path.rglob("*"))
            for path in paths:
                if path.is_file():
                    rel = path.relative_to(prior)
                    current = bundle / rel
                    require(current.is_file() and sha256(current) == sha256(path), f"SCAN1_CHANGED:{rel}")
        require(manifest["manifest_sha256"] == EXPECTED_MANIFEST_SHA256, "MANIFEST_IDENTITY")
        return "SCAN1 source/resources/manifest/MMIO files byte-identical"

    def t13():
        summary = controller.scan_summary("PRESERVED_REPLAY", snapshot, {"source": "preserved"})
        physical = (summary["entry_count"], summary["bank_group_count"], summary["transaction_count"], summary["entry_bank_restore"])
        require(physical == (82, 10, 105, "PASS"), "PHYSICAL_RECEIPT")
        require(len(summary["configuration_projection"]) == 13, "PROJECTION_RECEIPT")
        return "physical scanner receipt and host projection receipt are separate fields"

    def t14():
        expanded = projection.expand_schema()
        channels = {
            family: sorted(item["channel"] for item in expanded if item["semantic_family"] == family)
            for family in ("adc_clock_delay", "pre_clock")
        }
        require(channels == {"adc_clock_delay": [0, 1, 2, 3], "pre_clock": [0, 1, 2, 3]}, "CHANNEL_EXPANSION")
        return "both channel families expand exactly for ch=0..3"

    def t15():
        old_controller = prior / "g2b_nvp_camera_acq1_compat0_r2r1_controller.py"
        require(sha256(old_controller) == EXPECTED_OLD_CONTROLLER_SHA256, "OLD_CONTROLLER_IDENTITY")
        old_required = {
            (0x00, 0xF4), (0x00, 0xF5), (0x00, 0x80),
            (0x01, 0x97), (0x01, 0x98),
            *((0x01, register) for register in range(0x84, 0x90)),
        }
        values = {(int(item["bank"]), int(item["register"])) for item in snapshot["raw_register_set"]}
        old_missing = sorted(old_required - values)
        require(old_missing == [(1, 0x88), (1, 0x89), (1, 0x8A), (1, 0x8B)], "OLD_RESULT")
        require(len(projection.configuration_projection(snapshot)) == 13, "CORRECTED_RESULT")
        return "old FAIL on 0x88-0x8B; corrected projection PASS on same bytes"

    def t16():
        first = projection.configuration_projection(snapshot)
        second_snapshot = copy.deepcopy(snapshot)
        second_snapshot["raw_register_set"] = list(reversed(second_snapshot["raw_register_set"]))
        second = projection.configuration_projection(second_snapshot)
        first_bytes = json.dumps(first, sort_keys=True, separators=(",", ":")).encode()
        second_bytes = json.dumps(second, sort_keys=True, separators=(",", ":")).encode()
        require(first_bytes == second_bytes, "NONDETERMINISTIC_PROJECTION")
        return hashlib.sha256(first_bytes).hexdigest().upper()

    tests = [
        ("T1", "exact 82-entry manifest preflight", t1),
        ("T2", "old Bank1/0x88 family fails preflight", t2),
        ("T3", "ADC delay family 0x84-0x87", t3),
        ("T4", "pre-clock family 0x8C-0x8F", t4),
        ("T5", "wrong bank cannot satisfy full key", t5),
        ("T6", "missing real key fails preflight", t6),
        ("T7", "unused extra key is tolerated", t7),
        ("T8", "preserved snapshot qualification", t8),
        ("T9", "preserved bytes unchanged", t9),
        ("T10", "physical scanner receipt", t10),
        ("T11", "no NVP write path added", t11),
        ("T12", "no FPGA/SCAN1 manifest/MMIO change", t12),
        ("T13", "physical and projection receipts separate", t13),
        ("T14", "channel expansion exact", t14),
        ("T15", "old/new expected result difference", t15),
        ("T16", "deterministic projection output", t16),
    ]
    for test_id, requirement, function in tests:
        test(test_id, requirement, function)

    passed = sum(item["result"] == "PASS" for item in results)
    report = {
        "schema": "AHD_V41_CONT1R1_HOST_PROJECTION_GATE_V1",
        "gate": "CONT1R1_HOST_PROJECTION_GATE",
        "result": "PASS" if passed == 16 else "FAIL",
        "passed": passed,
        "total": 16,
        "preserved_snapshot_json_sha256": sha256(snapshot_json),
        "preserved_snapshot_bin_sha256": sha256(snapshot_bin),
        "tests": results,
    }
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0 if passed == 16 else 1


if __name__ == "__main__":
    raise SystemExit(main())
