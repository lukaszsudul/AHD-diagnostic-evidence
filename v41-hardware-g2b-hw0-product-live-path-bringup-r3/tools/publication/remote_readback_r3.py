from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import subprocess
from pathlib import Path, PurePosixPath


PACKAGE = "v41-hardware-g2b-hw0-product-live-path-bringup-r3"
MANIFEST = "G2B_HW0_PRODUCT_R3_SHA256_MANIFEST.txt"
REMOTE_REF = "refs/heads/main"
REQUIRED = {
    "V41_G2B_HW0_PRODUCT_R3_MAIN_REPORT.md",
    "G2B_HW0_PRODUCT_R3_AUTHORIZATION_RECEIPT.md",
    "G2B_HW0_PRODUCT_R3_AUTHORITY_VERIFICATION.md",
    "G2B_HW0_PRODUCT_R3_DUT_LOCK_RECEIPT.md",
    "G2B_HW0_PRODUCT_R3_PRELOAD_INVENTORY.md",
    "G2B_HW0_PRODUCT_R3_DRIVER_VERIFICATION.md",
    "G2B_HW0_PRODUCT_R3_DRIVER_LOAD_PROBE.md",
    "G2B_HW0_PRODUCT_R3_NODE_TO_BDF_PROOF.md",
    "G2B_HW0_PRODUCT_R3_NODE_MAP.csv",
    "G2B_HW0_PRODUCT_R3_MMIO_RAW.csv",
    "G2B_HW0_PRODUCT_R3_MMIO_DECODED.md",
    "G2B_HW0_PRODUCT_R3_NVP_VIDEO_READINESS.md",
    "G2B_HW0_PRODUCT_R3_FIRST_RECORD_REPORT.md",
    "G2B_HW0_PRODUCT_R3_FIRST_RECORD_HEADER.csv",
    "G2B_HW0_PRODUCT_R3_FINITE_CAPTURE_REPORT.md",
    "G2B_HW0_PRODUCT_R3_FINITE_CAPTURE_METRICS.csv",
    "G2B_HW0_PRODUCT_R3_FRAME_RECONSTRUCTION_REPORT.md",
    "G2B_HW0_PRODUCT_R3_CONTINUOUS_CAPTURE_REPORT.md",
    "G2B_HW0_PRODUCT_R3_CONTINUOUS_METRICS.csv",
    "G2B_HW0_PRODUCT_R3_COUNTER_RECONCILIATION.md",
    "G2B_HW0_PRODUCT_R3_PCIE_AER_KERNEL_LOG_REVIEW.md",
    "G2B_HW0_PRODUCT_R3_CLEANUP_RECEIPT.md",
    "G2B_HW0_PRODUCT_R3_FINAL_HARDWARE_STATE.md",
    "G2B_HW0_PRODUCT_R3_GATE_MATRIX.csv",
    "G2B_HW0_PRODUCT_R3_STATE.json",
    "G2B_HW0_PRODUCT_R3_EVIDENCE_INDEX.md",
    MANIFEST,
}
FORBIDDEN_SUFFIXES = {
    ".bit", ".dcp", ".ko", ".bin", ".raw", ".uyvy", ".png", ".jpg",
    ".jpeg", ".bmp", ".tiff", ".p12", ".pfx", ".pem", ".key", ".tmp",
}
FORBIDDEN_BASENAMES = {
    "Invoke-G2BR1Plink.ps1",
    "Invoke-G2BR3Plink.ps1",
    "Invoke-G2BR3Plink_proven.ps1",
}
FORBIDDEN_UNSAFE_DRAFT_NAMES = {
    "t1_exact_module_load_probe.sh",
    "publish_t1_tool_to_dut.ps1",
    "run_t1_exact_module_load_probe.ps1",
}


class Failure(RuntimeError):
    pass


def run(args: list[str], cwd: Path | None = None) -> bytes:
    result = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if result.returncode:
        raise Failure(f"COMMAND_FAILED:{args!r}:{result.returncode}:{result.stderr.decode('utf-8','replace')}")
    return result.stdout


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def read_blob(repo: Path, commit: str, rel: str) -> bytes:
    return run(["git", "cat-file", "blob", f"{commit}:{PACKAGE}/{rel}"], cwd=repo)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--remote", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--result", type=Path, required=True)
    args = parser.parse_args()
    commit = args.commit.lower()
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise Failure("INVALID_COMMIT")
    work = args.work.resolve()
    result_path = args.result.resolve()
    if work.exists() or result_path.exists():
        raise Failure("OUTPUT_ALREADY_EXISTS")
    work.mkdir(parents=True)
    bare = work / "remote.git"
    run(["git", "init", "--bare", str(bare)])
    run(["git", "-C", str(bare), "remote", "add", "origin", args.remote])
    fetch = subprocess.run(
        ["git", "-C", str(bare), "fetch", "--no-tags", "origin", f"{REMOTE_REF}:refs/remotes/origin/main"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
    )
    (work / "fetch.log").write_bytes(fetch.stdout)
    if fetch.returncode:
        raise Failure(f"REMOTE_FETCH_FAILED:{fetch.returncode}")
    remote_commit = run(["git", "-C", str(bare), "rev-parse", "refs/remotes/origin/main"]).decode().strip().lower()
    if remote_commit != commit:
        raise Failure(f"REMOTE_HEAD_MISMATCH:{remote_commit}:{commit}")
    raw = run(["git", "-C", str(bare), "ls-tree", "-r", "-z", "--full-tree", commit, "--", PACKAGE])
    files: dict[str, bytes] = {}
    prefix = PACKAGE + "/"
    for record in raw.split(b"\0"):
        if not record:
            continue
        header, path_raw = record.split(b"\t", 1)
        mode, obj_type, _obj_id = header.decode("ascii").split()
        path = path_raw.decode("utf-8")
        if obj_type != "blob" or mode not in {"100644", "100755"} or not path.startswith(prefix):
            raise Failure(f"UNEXPECTED_TREE_ENTRY:{path}:{mode}:{obj_type}")
        rel = path[len(prefix):]
        if not rel or any(p in {"", ".", ".."} for p in PurePosixPath(rel).parts):
            raise Failure(f"UNSAFE_PATH:{rel}")
        if PurePosixPath(rel).suffix.lower() in FORBIDDEN_SUFFIXES:
            raise Failure(f"FORBIDDEN_PUBLIC_SUFFIX:{rel}")
        if PurePosixPath(rel).name in FORBIDDEN_BASENAMES:
            raise Failure(f"CREDENTIAL_INFERENCE_SOURCE:{rel}")
        if any(PurePosixPath(rel).name.startswith(name) for name in FORBIDDEN_UNSAFE_DRAFT_NAMES):
            raise Failure(f"UNSAFE_T1_DRAFT_SOURCE:{rel}")
        if rel.startswith("tools/DO_NOT_RUN/") and PurePosixPath(rel).suffix.lower() not in {".md", ".txt"}:
            raise Failure(f"RUNNABLE_QUARANTINED_SOURCE:{rel}")
        files[rel] = read_blob(bare, commit, rel)
    missing = sorted(REQUIRED - {p for p in files if "/" not in p})
    if missing:
        raise Failure("REQUIRED_FILES_MISSING:" + ",".join(missing))
    manifest_bytes = files.get(MANIFEST)
    if manifest_bytes is None:
        raise Failure("MANIFEST_MISSING")
    try:
        manifest_text = manifest_bytes.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise Failure("MANIFEST_NOT_UTF8") from exc
    entries: dict[str, str] = {}
    for line in manifest_text.splitlines():
        match = re.fullmatch(r"([0-9A-F]{64})  (.+)", line)
        if not match:
            raise Failure(f"MALFORMED_MANIFEST_LINE:{line!r}")
        digest, rel = match.groups()
        if rel in entries:
            raise Failure(f"DUPLICATE_MANIFEST_PATH:{rel}")
        entries[rel] = digest
    expected_paths = set(files) - {MANIFEST}
    if set(entries) != expected_paths:
        raise Failure(f"MANIFEST_COVERAGE_MISMATCH:missing={sorted(expected_paths-set(entries))}:extra={sorted(set(entries)-expected_paths)}")
    mismatches = []
    for rel, expected in entries.items():
        actual = sha(files[rel])
        if actual != expected:
            mismatches.append({"path": rel, "expected": expected, "actual": actual})
    if mismatches:
        raise Failure("BLOB_HASH_MISMATCH:" + json.dumps(mismatches, sort_keys=True))
    scans = [
        re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
        re.compile(rb"(?im)^\s*(password|haslo)\s*[:=]"),
        re.compile(rb"(?i)PLINK_" + rb"PW_OPTION_USED=YES"),
    ]
    for rel, data in files.items():
        if b"\0" in data:
            raise Failure(f"BINARY_PUBLIC_CONTENT:{rel}")
        for pattern in scans:
            if pattern.search(data):
                raise Failure(f"CREDENTIAL_PATTERN:{rel}:{pattern.pattern!r}")
    result = {
        "task": "G2B-HW0-PRODUCT-R3",
        "result": "PASS",
        "checked_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "remote": args.remote,
        "remote_ref": REMOTE_REF,
        "commit": commit,
        "package": PACKAGE,
        "file_count": len(files),
        "manifest_entry_count": len(entries),
        "manifest_sha256": sha(manifest_bytes),
        "missing_required": [],
        "size_mismatches": 0,
        "sha256_mismatches": 0,
        "forbidden_payload_files": 0,
        "credential_findings": 0,
    }
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    print("REMOTE_READBACK=PASS")
    print(f"REMOTE_COMMIT={commit}")
    print(f"REMOTE_FILE_COUNT={len(files)}")
    print(f"REMOTE_MANIFEST_ENTRY_COUNT={len(entries)}")
    print(f"REMOTE_MANIFEST_SHA256={sha(manifest_bytes)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Failure as exc:
        print(f"REMOTE_READBACK=FAIL")
        print(f"FIRST_ERROR={exc}")
        raise SystemExit(1)
