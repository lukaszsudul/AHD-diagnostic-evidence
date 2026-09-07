#!/usr/bin/env python3
"""Commit-pinned authority verification for the governed R3R4R4 run."""

from __future__ import annotations

import hashlib
import json
import pathlib
import re
import subprocess
import sys
import tarfile
import tempfile
from typing import Any


EVIDENCE = pathlib.Path(r"C:\FPGA\V41_G2B_EVIDENCE")
SOURCE = pathlib.Path(r"C:\FPGA\V41_G2B")
PROJECT = EVIDENCE / "project-current-state"
RECOVERY = pathlib.Path(r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316")

EXPECTED_SOURCE_BRANCH = "integration/v41-g2b-onech-c2h"
EXPECTED_SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
EXPECTED_SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
EXPECTED_BIT = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
EXPECTED_DCP = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"
EXPECTED_ABI = "AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6"
EXPECTED_DRIVER = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"

PREDECESSORS = {
    "r3r3": {
        "commit": "6cff7ad374575df84bc7d8794565dbd7d9cd869f",
        "directory": "v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record",
        "manifest": "G2B_HW0_PRODUCT_R3R3_SHA256_MANIFEST.txt",
        "state": "G2B_HW0_PRODUCT_R3R3_STATE.json",
    },
    "r3r4": {
        "commit": "2bfcba2476a31a06bdf940881cd5d0a20614333e",
        "directory": "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4-finite-frame",
        "manifest": "G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt",
        "state": "G2B_HW0_PRODUCT_R3R4_STATE.json",
    },
    "r3r4r1": {
        "commit": "9c1ff0473ca336e75c29a19208be17b407d8bf37",
        "directory": "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r1-finite-frame",
        "manifest": "G2B_HW0_PRODUCT_R3R4R1_SHA256_MANIFEST.txt",
        "state": "G2B_HW0_PRODUCT_R3R4R1_STATE.json",
    },
    "r3r4r2": {
        "commit": "3749e2eb484eb1ccff2b7c4ed86598d8f4cfbb81",
        "directory": "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r2-finite-frame",
        "manifest": "G2B_HW0_PRODUCT_R3R4R2_SHA256_MANIFEST.txt",
        "state": "G2B_HW0_PRODUCT_R3R4R2_STATE.json",
    },
    "r3r4r3": {
        "commit": "6676421dfb5e64b7271a2200fe950c1d223fc3d6",
        "directory": "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r3-finite-frame",
        "manifest": "G2B_HW0_PRODUCT_R3R4R3_SHA256_MANIFEST.txt",
        "state": "G2B_HW0_PRODUCT_R3R4R3_STATE.json",
    },
}

TREE_CACHE: dict[tuple[str, str], dict[str, bytes]] = {}
TEMP_ROOT: pathlib.Path | None = None


def run(*args: str, cwd: pathlib.Path | None = None) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True, encoding="utf-8").strip()


def git_bytes(spec: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(EVIDENCE), "show", spec])


def git_json(commit: str, directory: str, name: str) -> Any:
    return json.loads(tree_bytes(commit, directory, name).decode("utf-8-sig"))


def load_tree(commit: str, directory: str) -> dict[str, bytes]:
    key = (commit, directory)
    if key in TREE_CACHE:
        return TREE_CACHE[key]
    if TEMP_ROOT is None:
        raise RuntimeError("TEMP_ROOT_NOT_INITIALIZED")
    with tempfile.TemporaryDirectory(prefix=f"authority-{commit[:8]}-", dir=TEMP_ROOT) as temp_name:
        archive = pathlib.Path(temp_name) / "tree.tar"
        subprocess.check_call([
            "git", "-C", str(EVIDENCE), "archive", "--format=tar",
            f"--output={archive}", commit, directory,
        ])
        prefix = directory.rstrip("/") + "/"
        members: dict[str, bytes] = {}
        with tarfile.open(archive, "r:") as stream:
            for member in stream.getmembers():
                if not member.isfile() or not member.name.startswith(prefix):
                    continue
                extracted = stream.extractfile(member)
                if extracted is None:
                    raise RuntimeError(f"ARCHIVE_MEMBER_UNREADABLE:{member.name}")
                members[member.name[len(prefix):]] = extracted.read()
    TREE_CACHE[key] = members
    return members


def tree_bytes(commit: str, directory: str, relative: str) -> bytes:
    members = load_tree(commit, directory)
    if relative not in members:
        raise KeyError(f"MISSING_TREE_MEMBER:{commit}:{directory}:{relative}")
    return members[relative]


def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha_file(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def validate_git_manifest(commit: str, directory: str, manifest: str) -> tuple[int, list[str]]:
    members = load_tree(commit, directory)
    text = members[manifest].decode("utf-8-sig")
    failures: list[str] = []
    count = 0
    for line in text.splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r"([0-9A-Fa-f]{64})  (.+)", line)
        if not match:
            failures.append(f"MALFORMED:{line}")
            continue
        expected, relative = match.groups()
        count += 1
        try:
            actual = sha_bytes(members[relative])
        except KeyError:
            failures.append(f"MISSING:{relative}")
            continue
        if actual != expected.upper():
            failures.append(f"HASH:{relative}:{expected.upper()}:{actual}")
    return count, failures


def validate_local_manifest(root: pathlib.Path, manifest: str) -> tuple[int, list[str]]:
    failures: list[str] = []
    count = 0
    for line in (root / manifest).read_text(encoding="utf-8-sig").splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r"([0-9A-Fa-f]{64})  (.+)", line)
        if not match:
            failures.append(f"MALFORMED:{line}")
            continue
        expected, relative = match.groups()
        count += 1
        path = root / relative
        if not path.is_file():
            failures.append(f"MISSING:{relative}")
        elif sha_file(path) != expected.upper():
            failures.append(f"HASH:{relative}")
    return count, failures


def require(checks: dict[str, bool], name: str, value: bool) -> None:
    checks[name] = bool(value)


def main(output_path: pathlib.Path) -> int:
    global TEMP_ROOT
    TEMP_ROOT = output_path.parent
    checks: dict[str, bool] = {}
    project_entries, project_failures = validate_local_manifest(PROJECT, "SHA256_MANIFEST.txt")
    project_state = json.loads((PROJECT / "PROJECT_STATE.json").read_text(encoding="utf-8-sig"))
    current_status = (PROJECT / "CURRENT_STATUS.md").read_text(encoding="utf-8-sig")
    require(checks, "PROJECT_STATE_MANIFEST", project_entries == 18 and not project_failures)
    require(checks, "PROJECT_STATE_REV_8", project_state.get("project_state_revision") == 8)
    require(checks, "META8A_PROMOTED", "META-8A" in current_status and "ACCEPTED" in current_status)
    require(checks, "G2B_HW_NOT_QUALIFIED", "G2B-HW" in current_status and "NOT_STARTED / NOT_PROVEN" in current_status)

    predecessor_results: dict[str, Any] = {}
    states: dict[str, Any] = {}
    head = run("git", "rev-parse", "HEAD", cwd=EVIDENCE)
    remote = run("git", "rev-parse", "origin/main", cwd=EVIDENCE)
    for key, item in PREDECESSORS.items():
        commit = item["commit"]
        directory = item["directory"]
        run("git", "cat-file", "-e", f"{commit}^{{commit}}", cwd=EVIDENCE)
        pinned_tree = run("git", "rev-parse", f"{commit}:{directory}", cwd=EVIDENCE)
        head_tree = run("git", "rev-parse", f"HEAD:{directory}", cwd=EVIDENCE)
        entries, failures = validate_git_manifest(commit, directory, item["manifest"])
        states[key] = git_json(commit, directory, item["state"])
        predecessor_results[key] = {
            "commit": commit,
            "directory": directory,
            "tree_at_commit": pinned_tree,
            "tree_at_head": head_tree,
            "tree_unchanged": pinned_tree == head_tree,
            "manifest_entries": entries,
            "manifest_failures": failures,
            "result": "PASS" if pinned_tree == head_tree and entries > 0 and not failures else "FAIL",
        }
    require(checks, "EVIDENCE_HEAD_PINNED_R3R4R3", head == PREDECESSORS["r3r4r3"]["commit"])
    require(checks, "EVIDENCE_REMOTE_PINNED_R3R4R3", remote == head)
    require(checks, "ALL_PREDECESSORS", all(v["result"] == "PASS" for v in predecessor_results.values()))

    r3r3 = states["r3r3"]
    require(checks, "R3R3_ACCEPTED_FACTS",
            all(r3r3.get(k) == "PASS" for k in ("T0", "T1", "T2"))
            and r3r3.get("sram_programming_attempts") == 1
            and r3r3.get("warm_reboots") == 1
            and r3r3.get("final_done") == 1
            and r3r3.get("reader_complete_records") == 53
            and r3r3.get("post_reset_epoch") == 2
            and r3r3.get("cleanup") == "PASS"
            and r3r3.get("endpoint_final") == "PRESENT_UNBOUND")
    r3r4 = states["r3r4"]
    require(checks, "R3R4_EXPECTED_BLOCKER", r3r4.get("first_blocker") == "R3R4_CAPTURE_TOOL_HARD_GATE_FAILED" and not r3r4.get("hardware_accessed"))
    r3r4r1 = states["r3r4r1"]
    require(checks, "R3R4R1_EXPECTED_BLOCKER", r3r4r1.get("failed_case") == "PARENT_QUIESCENCE_HANDSHAKE_PASS" and r3r4r1.get("dut_connections") == 0)
    r3r4r2 = states["r3r4r2"]
    require(checks, "R3R4R2_EXPECTED_BLOCKER", r3r4r2.get("first_blocker", "").endswith("PERSISTED_FIRST_RECORD_REREAD_HASH_PROOF_ABSENT") and r3r4r2.get("capture_tool_offline_selftests") == {"passed": 11, "total": 11})
    r3r4r3 = states["r3r4r3"]
    analysis = git_json(PREDECESSORS["r3r4r3"]["commit"], PREDECESSORS["r3r4r3"]["directory"], "raw/G2B_HW0_PRODUCT_R3R4R3_SELFTEST_FAILURE_ANALYSIS.json")
    checkpoints_text = tree_bytes(PREDECESSORS["r3r4r3"]["commit"], PREDECESSORS["r3r4r3"]["directory"], "G2B_HW0_PRODUCT_R3R4R3_PRIMARY_DURABILITY_CHECKPOINTS.jsonl").decode("utf-8-sig")
    checkpoints = [json.loads(line) for line in checkpoints_text.splitlines() if line.strip()]
    require(checks, "R3R4R3_EXPECTED_BLOCKER",
            r3r4r3.get("failed_selftest") == "FIRST_RECORD_PERSISTENCE_PASS"
            and not r3r4r3.get("hardware_accessed")
            and r3r4r3.get("dut_connections") == 0
            and r3r4r3.get("driver_load_attempts") == 0
            and r3r4r3.get("prior_immutable_artifact_new_writes") == 0)
    require(checks, "R3R4R3_ORDER_DIAGNOSIS",
            analysis.get("actual_relation_inferred") == "TIMESTAMPS_EQUAL"
            and analysis.get("runtime_program_order_proven") is True
            and analysis.get("monotonic_clock_resolution_seconds") == 0.015625
            and analysis.get("runtime_modified_after_suite") is False
            and analysis.get("suite_rerun") is False)
    require(checks, "R3R4R3_SYNTHETIC_FIXTURE",
            [row.get("record_count") for row in checkpoints] == [1024, 2048, 2500]
            and r3r4r3.get("first_record_hash_source") == "REREAD_PERSISTED_FILE"
            and r3r4r3.get("first_payload_hash_source") == "REREAD_PERSISTED_FILE"
            and r3r4r3.get("abi_parse_source") == "REREAD_PERSISTED_FIRST_RECORD")

    source_branch = run("git", "branch", "--show-current", cwd=SOURCE)
    source_commit = run("git", "rev-parse", "HEAD", cwd=SOURCE)
    source_tree = run("git", "rev-parse", "HEAD^{tree}", cwd=SOURCE)
    source_status = run("git", "status", "--porcelain=v2", "--untracked-files=all", cwd=SOURCE)
    source_remote = run("git", "rev-parse", f"refs/remotes/origin/{EXPECTED_SOURCE_BRANCH}", cwd=SOURCE)
    require(checks, "PRODUCT_SOURCE_BRANCH", source_branch == EXPECTED_SOURCE_BRANCH)
    require(checks, "PRODUCT_SOURCE_COMMIT", source_commit == EXPECTED_SOURCE_COMMIT)
    require(checks, "PRODUCT_SOURCE_TREE", source_tree == EXPECTED_SOURCE_TREE)
    require(checks, "PRODUCT_SOURCE_CLEAN", source_status == "")
    require(checks, "PRODUCT_SOURCE_REMOTE", source_remote == EXPECTED_SOURCE_COMMIT)

    bit_hash = sha_file(RECOVERY / "G2B_PRODUCT_RECOVERY4.bit")
    dcp_hash = sha_file(RECOVERY / "G2B_PRODUCT_SIGNED_OFF.dcp")
    abi_hash = sha_file(EVIDENCE / PREDECESSORS["r3r4r3"]["directory"] / "tools" / "V41_C2H_TRANSPORT_ABI_V1.json")
    require(checks, "PRODUCT_BITSTREAM_SHA256", bit_hash == EXPECTED_BIT)
    require(checks, "SIGNED_DCP_SHA256", dcp_hash == EXPECTED_DCP)
    require(checks, "FROZEN_ABI_SHA256", abi_hash == EXPECTED_ABI)
    require(checks, "DRIVER_AUTHORITY_PRESERVED", EXPECTED_DRIVER in tree_bytes(PREDECESSORS["r3r3"]["commit"], PREDECESSORS["r3r3"]["directory"], "G2B_HW0_PRODUCT_R3R3_DRIVER_VERIFICATION.md").decode("utf-8-sig"))

    result = "PASS" if all(checks.values()) else "FAIL"
    receipt = {
        "schema": "R3R4R4_AUTHORITY_VERIFICATION_V1",
        "result": result,
        "project_state_rev": project_state.get("project_state_revision"),
        "project_state_manifest_entries": project_entries,
        "project_state_manifest_failures": project_failures,
        "checks": checks,
        "predecessors": predecessor_results,
        "source_branch": source_branch,
        "source_commit": source_commit,
        "source_tree": source_tree,
        "bitstream_sha256": bit_hash,
        "dcp_sha256": dcp_hash,
        "abi_sha256": abi_hash,
        "driver_sha256": EXPECTED_DRIVER,
    }
    output_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2))
    return 0 if result == "PASS" else 2


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_authority_r3r4r4.py OUTPUT.json")
    raise SystemExit(main(pathlib.Path(sys.argv[1])))
