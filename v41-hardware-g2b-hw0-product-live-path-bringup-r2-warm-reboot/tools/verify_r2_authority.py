from __future__ import annotations

import datetime as dt
import hashlib
import json
from pathlib import Path
import subprocess


EVIDENCE = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
SOURCE = Path(r"C:\FPGA\V41_G2B")
R1_DIR = EVIDENCE / "v41-hardware-g2b-hw0-product-live-path-bringup-r1"
SSOT = EVIDENCE / "project-current-state"
BIT = Path(r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit")
DCP = Path(r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp")
OUT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R2_20260906\raw\LOCAL_AUTHORITY_VERIFICATION.json")

R1_COMMIT = "eb3a75c09925574c6947d67cdefb8e2a723add9e"
SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
BIT_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
DCP_SHA = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"


def git(*args: str, cwd: Path) -> str:
    return subprocess.check_output(["git", *args], cwd=cwd).decode("utf-8").strip()


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def verify_manifest(root: Path, manifest_name: str) -> dict[str, object]:
    manifest = root / manifest_name
    entries: dict[str, str] = {}
    for line in manifest.read_text(encoding="utf-8").splitlines():
        expected, relative = line.split("  ", 1)
        entries[relative] = expected
    actual_files = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file() and path != manifest
    }
    assert set(entries) == actual_files, (
        "MANIFEST_FILE_SET_MISMATCH",
        sorted(actual_files - set(entries)),
        sorted(set(entries) - actual_files),
    )
    mismatches = []
    for relative, expected in entries.items():
        actual = sha(root / relative)
        if actual != expected:
            mismatches.append({"path": relative, "expected": expected, "actual": actual})
    assert not mismatches, ("MANIFEST_HASH_MISMATCH", mismatches)
    return {
        "result": "PASS",
        "entries": len(entries),
        "manifest_sha256": sha(manifest),
        "mismatches": 0,
    }


def check(name: str, actual: object, expected: object, checks: list[dict[str, object]]) -> None:
    passed = actual == expected
    checks.append({"name": name, "actual": actual, "expected": expected, "result": "PASS" if passed else "FAIL"})
    assert passed, f"{name}: expected={expected!r} actual={actual!r}"


def main() -> None:
    checks: list[dict[str, object]] = []
    r1 = json.loads((R1_DIR / "G2B_HW0_PRODUCT_R1_STATE.json").read_text(encoding="utf-8"))
    ssot = json.loads((SSOT / "PROJECT_STATE.json").read_text(encoding="utf-8"))

    evidence_head = git("rev-parse", "HEAD", cwd=EVIDENCE)
    evidence_tracking = git("rev-parse", "origin/main", cwd=EVIDENCE)
    evidence_remote = git("ls-remote", "origin", "refs/heads/main", cwd=EVIDENCE).split()[0]
    check("R1_EVIDENCE_HEAD", evidence_head, R1_COMMIT, checks)
    check("R1_EVIDENCE_ORIGIN_TRACKING", evidence_tracking, R1_COMMIT, checks)
    check("R1_EVIDENCE_REMOTE", evidence_remote, R1_COMMIT, checks)
    check("EVIDENCE_TRACKED_CLEAN", git("status", "--porcelain=v1", "--untracked-files=no", cwd=EVIDENCE), "", checks)

    r1_manifest = verify_manifest(R1_DIR, "G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt")
    check("R1_PUBLICATION", r1["evidence_publication"], "PASS", checks)
    check("R1_REMOTE_READBACK", r1["publication"]["remote_readback"], "PASS", checks)
    check("R1_FINAL_CANDIDATE", r1["final_hardware_state"]["candidate"], "STILL_LOADED_VOLATILE_SRAM_BY_UNBROKEN_CHAIN", checks)
    check("R1_FINAL_DONE", r1["final_hardware_state"]["done"], 1, checks)
    check("R1_FINAL_ENDPOINT", r1["final_hardware_state"]["endpoint"], "ABSENT", checks)
    check("R1_FINAL_DRIVER", r1["final_hardware_state"]["driver"], "NOT_LOADED", checks)
    check("R1_FINAL_NODES", r1["final_hardware_state"]["device_nodes"], [], checks)
    check("R1_FLASH", r1["programming"]["flash"], "NO", checks)
    check("R1_REBOOTS", r1["operation_counts"]["reboots"], 0, checks)
    check("R1_POWER_CYCLES", r1["operation_counts"]["power_cycles"], 0, checks)

    ssot_manifest = verify_manifest(SSOT, "SHA256_MANIFEST.txt")
    check("PROJECT_STATE_REV", ssot["project_state_revision"], 8, checks)
    g2b_lut1 = ssot["tracks"]["product"]["g2b_lut1"]
    g2b_hw0 = ssot["tracks"]["product"]["g2b_hw0_product"]
    check("G2B_LUT1_STATUS", g2b_lut1["status"], "ACCEPTED", checks)
    check("G2B_LUT1_READINESS", g2b_lut1["readiness"], "OFFLINE_QUALIFIED", checks)
    check("CANDIDATE_MATURITY", g2b_lut1["qualification_maturity"], "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE", checks)
    check("G2B_HW0_READINESS", g2b_hw0["readiness"], "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION", checks)
    check("G2B_HW0_SCOPE", g2b_hw0["scope"], "ONE_CHANNEL_FIXED_LIVE_AHD_PATH", checks)

    source_branch = git("branch", "--show-current", cwd=SOURCE)
    source_head = git("rev-parse", "HEAD", cwd=SOURCE)
    source_tree = git("show", "-s", "--format=%T", "HEAD", cwd=SOURCE)
    source_remote = git("rev-parse", "origin/integration/v41-g2b-onech-c2h", cwd=SOURCE)
    check("SOURCE_BRANCH", source_branch, "integration/v41-g2b-onech-c2h", checks)
    check("SOURCE_HEAD", source_head, SOURCE_COMMIT, checks)
    check("SOURCE_TREE", source_tree, SOURCE_TREE, checks)
    check("SOURCE_REMOTE", source_remote, SOURCE_COMMIT, checks)
    check("SOURCE_TRACKED_CLEAN", git("status", "--porcelain=v1", "--untracked-files=no", cwd=SOURCE), "", checks)

    check("BIT_BYTES", BIT.stat().st_size, 2_192_144, checks)
    check("BIT_SHA256", sha(BIT), BIT_SHA, checks)
    check("DCP_SHA256", sha(DCP), DCP_SHA, checks)

    result = {
        "task": "G2B-HW0-PRODUCT-R2",
        "result": "PASS",
        "checked_at_utc": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "r1_evidence_commit": R1_COMMIT,
        "r1_manifest": r1_manifest,
        "ssot_manifest": ssot_manifest,
        "checks": checks,
        "owner_hardware_authorization": "GRANTED",
        "owner_warm_reboot_authorization": "GRANTED",
        "maximum_warm_reboots": 1,
        "power_cycle_authorization": "DENIED",
        "sram_reprogramming_authorization_in_r2": "DENIED",
        "flash_programming_authorization": "DENIED",
        "legacy_mmio_read_authorization": "GRANTED",
        "legacy_mmio_write_authorization": "DENIED",
    }
    OUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"AUTHORITY_VERIFICATION=PASS checks={len(checks)}")
    print(f"R1_MANIFEST_ENTRIES={r1_manifest['entries']}")
    print(f"SSOT_MANIFEST_ENTRIES={ssot_manifest['entries']}")


if __name__ == "__main__":
    main()
