#!/usr/bin/env python3
"""Assemble, validate, publish, and commit-pin read back DIAG1-R1 evidence.

The default invocation is intentionally non-publishing.  `assemble --dry-run`
reports every missing required input.  Publication is a separate, explicitly
confirmed action and always uses one exact sparse path, a normal non-force push,
and a fresh commit-pinned blob read-back.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import uuid
from typing import Any, Iterable


TASK = "AHD_V41_G2B_NVP_VIDEO_DIAG1_R1"
TARGET_DIRECTORY = (
    "v41-hardware-g2b-nvp-video-diag1-r1-host-owned-results-four-channel-scan"
)
REPOSITORY_SLUG = "lukaszsudul/AHD-diagnostic-evidence"
BRANCH = "main"
COMMIT_MESSAGE = "Run AHD v41 NVP video DIAG1 R1 host-owned four-channel scan"
PUBLISH_CONFIRMATION = "PUBLISH_G2B_NVP_VIDEO_DIAG1_R1"
PREFIX = "G2B_NVP_VIDEO_DIAG1_R1_"
MANIFEST_NAME = PREFIX + "SHA256_MANIFEST.txt"
INDEX_NAME = PREFIX + "EVIDENCE_INDEX.md"
EXPECTED_SOURCE_BRANCH = "diag/v41-g2b-nvp-video-scan"
EXPECTED_SOURCE_COMMIT = "fcab95726761a0666a67e31c283dbdfb9e775074"
EXPECTED_SOURCE_TREE = "bbf1a5fee70a2eb68bb96305ed10934a1559ca6a"
EXPECTED_SIMULATION_RECEIPT_SHA256 = (
    "7A72A2E95B677884630C00AE6DB299F33844ADC8DAE48F9AB73372FAD7B6B47E"
)
MAX_TEXT_BYTES = 64 * 1024 * 1024
MAX_RAW_REPORT_BYTES = 16 * 1024 * 1024
REPARSE_ATTRIBUTE = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)

REQUIRED_FILES = (
    "V41_G2B_NVP_VIDEO_DIAG1_R1_MAIN_REPORT.md",
    PREFIX + "OWNER_CONTINUITY.md",
    PREFIX + "SCOPE_AND_AUTHORIZATION.md",
    PREFIX + "PREVIOUS_FAILURE_INHERITANCE.md",
    PREFIX + "RESULT_STORAGE_ARCHITECTURE.md",
    PREFIX + "CURRENT_SNAPSHOT_SCHEMA.md",
    PREFIX + "HOST_HISTORY_PROTOCOL.md",
    PREFIX + "MMIO_MAP.md",
    PREFIX + "SOURCE_DELTA.md",
    PREFIX + "SIMULATION_REPORT.md",
    PREFIX + "RESOURCE_RECOVERY_REPORT.md",
    PREFIX + "HIERARCHICAL_UTILIZATION.md",
    PREFIX + "BUILD_REPORT.md",
    PREFIX + "TIMING_REPORT.md",
    PREFIX + "CDC_REPORT.md",
    PREFIX + "DRC_REPORT.md",
    PREFIX + "METHODOLOGY_REPORT.md",
    PREFIX + "BITSTREAM_MANIFEST.md",
    PREFIX + "PROGRAMMING_RECEIPT.md",
    PREFIX + "REBOOT_RECEIPT.md",
    PREFIX + "RUNTIME_IDENTITY.md",
    PREFIX + "I2C_TRANSACTION_LOG.csv",
    PREFIX + "NVP_WRITE_LEDGER.csv",
    PREFIX + "NVP_READBACK_LEDGER.csv",
    PREFIX + "STATUS_SAMPLES.csv",
    PREFIX + "HOST_SESSION_HISTORY.csv",
    PREFIX + "HOST_SESSION_HISTORY.jsonl",
    PREFIX + "SNAPSHOT_COHERENCE.csv",
    PREFIX + "SCAN_RESULTS.csv",
    PREFIX + "CAPTURE_INDEX.csv",
    PREFIX + "CAPTURE_RESULTS.csv",
    PREFIX + "FRAME_HASHES.csv",
    PREFIX + "PIXEL_STATISTICS.csv",
    PREFIX + "BGDCOL_MATCH_RESULTS.csv",
    PREFIX + "CHANNEL_REPEATABILITY.csv",
    PREFIX + "INPUT_MAPPING_DECISION.md",
    PREFIX + "DIGITAL_PATH_DECISION.md",
    PREFIX + "CAMERA_CONTENT_DECISION.md",
    PREFIX + "PRODUCT_RESTORE_RECEIPT.md",
    PREFIX + "CLEANUP_RECEIPT.md",
    PREFIX + "FINAL_STATE.md",
    PREFIX + "GATE_MATRIX.csv",
    PREFIX + "STATE.json",
    INDEX_NAME,
    MANIFEST_NAME,
)

GENERATED_REQUIRED = {INDEX_NAME, MANIFEST_NAME}

TASK_TOOL_FILES = (
    "scripts/abi_v1.py",
    "scripts/Export-NvpVideoDiag1SanitizedCommandLedger.ps1",
    "scripts/analyze_nvp_video_diag1.py",
    "scripts/assemble_publish_nvp_diag1_r1_evidence.py",
    "scripts/aggregate_nvp_session_metadata.py",
    "scripts/controller_nvp_capture.py",
    "scripts/controller_nvp_video_diag1.py",
    "scripts/extract_nvp_runtime_evidence.py",
    "scripts/frame_reconstruct_nvp_capture.py",
    "scripts/g2b_nvp_video_diag1_build.tcl",
    "scripts/Invoke-NvpVideoDiag1ControllerLock.ps1",
    "scripts/Invoke-NvpVideoDiag1DutConnection.ps1",
    "scripts/Invoke-NvpVideoDiag1R1SramProgramOnce.ps1",
    "scripts/Invoke-NvpVideoDiag1WarmRebootAndReconnectOnce.ps1",
    "scripts/program-nvp-video-diag1-r1-once.tcl",
    "scripts/test_evidence_helpers.py",
    "scripts/test_host_snapshot_protocol.py",
    "scripts/test_nvp_runtime_evidence.py",
    "scripts/V41_C2H_TRANSPORT_ABI_V1.json",
    "scripts/validate_nvp_capture.py",
    "scripts/xdma_c2h_rolling_4k_diag1.c",
)

TASK_SUPPORT_FILES = (
    "reports/G2B_NVP_VIDEO_DIAG1_R1_RUNTIME_EVIDENCE_CAPABILITY_AUDIT.md",
)

DIAGNOSTIC_SOURCE_FILES = (
    "rtl/g2b/g2b_nvp_video_diag.sv",
    "rtl/g2b/v41_g2b_onech_c2h.sv",
    "rtl/top/ahd_capture_top_xdma.sv",
    "rtl/v41/nvp_i2c_fixed_master.sv",
    "tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1",
    "tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv",
    "tests/nvp_video_diag/tb_nvp_i2c_fixed_master.sv",
)

ALLOWED_TEXT_SUFFIXES = {
    ".c", ".csv", ".json", ".jsonl", ".jou", ".log", ".md", ".ps1",
    ".py", ".rpt", ".sv", ".tcl", ".txt", ".v", ".vh", ".xdc",
}
PROHIBITED_SUFFIXES = {
    ".7z", ".a", ".avi", ".bin", ".bit", ".bmp", ".crt", ".dcp",
    ".dll", ".elf", ".exe", ".gif", ".gz", ".jpeg", ".jpg", ".key",
    ".ko", ".ltx", ".mov", ".mp4", ".o", ".pb", ".pem", ".pfx",
    ".png", ".pyc", ".sdb", ".so", ".tar", ".tgz", ".tif", ".tiff",
    ".uyvy", ".wdb", ".webp", ".zip",
}
PROHIBITED_COMPONENTS = {
    ".git", ".xil", "__pycache__", "credentials", "images", "private",
    "secret", "secrets",
}
PROHIBITED_NAMES = {
    "completion-bitmap.bin", "first-payload.bin", "first-record.bin",
    "primary-partial-by-index.bin", "primary.bin", "qualified-frame.png",
    "qualified-frame.uyvy", "thumbnail-320x180.png",
}
SENSITIVE_NAME_FRAGMENTS = (
    "authorized_keys", "credential", "id_ed25519", "id_rsa", "password",
    "passwd", "private_key", "secret", "sshpass", "token",
)

SECRET_PATTERNS = (
    re.compile(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----"),
    re.compile(r"(?i)authorization\s*:\s*bearer\s+[A-Za-z0-9._~+/=-]{8,}"),
    re.compile(r"\b(?:ghp|github_pat|glpat)-?[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(
        r"(?i)\b(?:password|passwd|api[_-]?key|access[_-]?token)\b\s*[:=]\s*"
        r"(?:['\"])?(?!REDACTED|NOT_AVAILABLE|NONE)[^\s,'\"]{8,}"
    ),
)


class EvidenceError(RuntimeError):
    """A fail-closed evidence, scope, or provenance violation."""


def absolute(path: Path) -> Path:
    return Path(os.path.abspath(os.fspath(path)))


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def is_reparse(path: Path) -> bool:
    info = path.lstat()
    return path.is_symlink() or bool(
        getattr(info, "st_file_attributes", 0) & REPARSE_ATTRIBUTE
    )


def require_safe_chain(root: Path, candidate: Path, *, must_exist: bool) -> Path:
    root = absolute(root)
    candidate = absolute(candidate)
    try:
        common = os.path.commonpath((os.fspath(root), os.fspath(candidate)))
    except ValueError as exc:
        raise EvidenceError(f"PATH_VOLUME_MISMATCH:{candidate}") from exc
    if os.path.normcase(common) != os.path.normcase(os.fspath(root)):
        raise EvidenceError(f"PATH_OUTSIDE_AUTHORIZED_ROOT:{candidate}")
    if not root.exists() or not root.is_dir() or is_reparse(root):
        raise EvidenceError(f"UNSAFE_AUTHORIZED_ROOT:{root}")
    current = root
    for component in candidate.relative_to(root).parts:
        current = current / component
        if current.exists() or current.is_symlink():
            if is_reparse(current):
                raise EvidenceError(f"REPARSE_POINT_REFUSED:{current}")
        else:
            break
    if must_exist and not candidate.exists():
        raise EvidenceError(f"PATH_MISSING:{candidate}")
    return candidate


def validate_relative_name(relative: str) -> str:
    if "\\" in relative or "\x00" in relative:
        raise EvidenceError(f"NON_CANONICAL_PACKAGE_PATH:{relative!r}")
    path = PurePosixPath(relative)
    if path.is_absolute() or not path.parts or any(part in ("", ".", "..")
                                                  for part in path.parts):
        raise EvidenceError(f"UNSAFE_PACKAGE_PATH:{relative!r}")
    if any(any(ord(character) < 32 or character in ':*?"<>|'
               for character in part) or part.endswith((" ", "."))
           for part in path.parts):
        raise EvidenceError(f"NON_PORTABLE_PACKAGE_PATH:{relative!r}")
    lowered_parts = {part.casefold() for part in path.parts}
    if lowered_parts & PROHIBITED_COMPONENTS:
        raise EvidenceError(f"PROHIBITED_PACKAGE_COMPONENT:{relative}")
    name = path.name.casefold()
    if name in PROHIBITED_NAMES:
        raise EvidenceError(f"PROHIBITED_ARTIFACT_NAME:{relative}")
    if any(fragment in name for fragment in SENSITIVE_NAME_FRAGMENTS):
        raise EvidenceError(f"SENSITIVE_ARTIFACT_NAME:{relative}")
    suffix = path.suffix.casefold()
    if suffix in PROHIBITED_SUFFIXES:
        raise EvidenceError(f"PROHIBITED_ARTIFACT_TYPE:{relative}")
    if suffix not in ALLOWED_TEXT_SUFFIXES:
        raise EvidenceError(f"NON_ALLOWLISTED_ARTIFACT_TYPE:{relative}")
    return path.as_posix()


def validate_public_bytes(relative: str, data: bytes) -> str:
    relative = validate_relative_name(relative)
    if len(data) > MAX_TEXT_BYTES:
        raise EvidenceError(f"PUBLIC_TEXT_TOO_LARGE:{relative}:{len(data)}")
    if b"\x00" in data:
        raise EvidenceError(f"BINARY_CONTENT_REFUSED:{relative}")
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise EvidenceError(f"NON_UTF8_CONTENT_REFUSED:{relative}") from exc
    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            raise EvidenceError(f"CREDENTIAL_PATTERN_REFUSED:{relative}")
    suffix = PurePosixPath(relative).suffix.casefold()
    try:
        if suffix == ".json":
            json.loads(text)
        elif suffix == ".jsonl":
            for number, line in enumerate(text.splitlines(), 1):
                if not line.strip() or not isinstance(json.loads(line), dict):
                    raise EvidenceError(f"JSONL_ROW_INVALID:{relative}:{number}")
        elif suffix == ".csv":
            reader = csv.reader(io.StringIO(text, newline=""))
            header = next(reader, None)
            if not header or any(not field for field in header):
                raise EvidenceError(f"CSV_HEADER_INVALID:{relative}")
            list(reader)
    except (json.JSONDecodeError, csv.Error) as exc:
        raise EvidenceError(f"STRUCTURED_TEXT_PARSE_FAILED:{relative}") from exc
    return text


def read_task_text(task_root: Path, path: Path, relative: str) -> bytes:
    path = require_safe_chain(task_root, path, must_exist=True)
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise EvidenceError(f"INPUT_NOT_REGULAR_FILE:{path}")
    data = path.read_bytes()
    validate_public_bytes(relative, data)
    return data


def run(
    command: list[str], *, cwd: Path | None = None, text: bool = False,
    check: bool = True, input_data: bytes | str | None = None,
) -> subprocess.CompletedProcess:
    environment = os.environ.copy()
    environment["GIT_TERMINAL_PROMPT"] = "0"
    result = subprocess.run(
        command, cwd=cwd, input=input_data, capture_output=True, text=text,
        check=False, env=environment,
    )
    if check and result.returncode != 0:
        stderr = result.stderr if text else result.stderr.decode("utf-8", "replace")
        raise EvidenceError(
            f"COMMAND_FAILED:{command[0]}:{result.returncode}:{stderr.strip()}"
        )
    return result


def git_text(repo: Path, *arguments: str) -> str:
    return run(["git", "-C", os.fspath(repo), *arguments], text=True).stdout.strip()


def add_entry(
    entries: dict[str, bytes], origins: dict[str, str], relative: str, data: bytes,
    origin: str,
) -> None:
    relative = validate_relative_name(relative)
    validate_public_bytes(relative, data)
    folded = relative.casefold()
    if any(existing.casefold() == folded for existing in entries):
        raise EvidenceError(f"PACKAGE_PATH_COLLISION:{relative}")
    entries[relative] = data
    origins[relative] = origin


def collect_required(
    task_root: Path, required_root: Path, entries: dict[str, bytes],
    origins: dict[str, str], gaps: list[str],
) -> None:
    required_root = absolute(required_root)
    if not required_root.exists():
        gaps.extend(os.fspath(required_root / name)
                    for name in REQUIRED_FILES if name not in GENERATED_REQUIRED)
        return
    require_safe_chain(task_root, required_root, must_exist=True)
    for child in required_root.iterdir():
        require_safe_chain(task_root, child, must_exist=True)
        if child.is_dir():
            raise EvidenceError(f"REQUIRED_ROOT_SUBDIRECTORY_REFUSED:{child}")
        if child.name not in set(REQUIRED_FILES) - GENERATED_REQUIRED:
            raise EvidenceError(f"UNEXPECTED_REQUIRED_ROOT_FILE:{child}")
    for name in REQUIRED_FILES:
        if name in GENERATED_REQUIRED:
            continue
        source = required_root / name
        if not source.is_file():
            gaps.append(os.fspath(source))
            continue
        add_entry(entries, origins, name,
                  read_task_text(task_root, source, name), os.fspath(source))


def collect_task_tools(
    task_root: Path, entries: dict[str, bytes], origins: dict[str, str],
    gaps: list[str],
) -> None:
    for relative in TASK_TOOL_FILES:
        source = task_root / Path(relative)
        destination = "source/task-tools/" + PurePosixPath(relative).name
        if not source.is_file():
            gaps.append(os.fspath(source))
            continue
        add_entry(entries, origins, destination,
                  read_task_text(task_root, source, destination), os.fspath(source))


def collect_task_support(
    task_root: Path, entries: dict[str, bytes], origins: dict[str, str],
    gaps: list[str],
) -> None:
    for relative in TASK_SUPPORT_FILES:
        source = task_root / Path(relative)
        destination = "support/" + PurePosixPath(relative).name
        if not source.is_file():
            gaps.append(os.fspath(source))
            continue
        add_entry(entries, origins, destination,
                  read_task_text(task_root, source, destination), os.fspath(source))


def git_blob(repo: Path, commit: str, relative: str) -> bytes:
    listing = run(
        ["git", "-C", os.fspath(repo), "ls-tree", "-z", commit, "--", relative]
    ).stdout
    records = [record for record in listing.split(b"\x00") if record]
    if len(records) != 1:
        raise EvidenceError(f"SOURCE_PATH_NOT_SINGLE_BLOB:{relative}")
    metadata, listed_path = records[0].split(b"\t", 1)
    mode, object_type, _oid = metadata.decode("ascii").split(" ", 2)
    if object_type != "blob" or mode == "120000":
        raise EvidenceError(f"SOURCE_REPARSE_OR_NON_BLOB_REFUSED:{relative}")
    if listed_path.decode("utf-8") != relative:
        raise EvidenceError(f"SOURCE_PATH_IDENTITY_MISMATCH:{relative}")
    return run(["git", "-C", os.fspath(repo), "show", f"{commit}:{relative}"]).stdout


def collect_diagnostic_source(
    source_repo: Path, source_commit: str, source_tree: str,
    entries: dict[str, bytes], origins: dict[str, str],
) -> dict[str, Any]:
    if not re.fullmatch(r"[0-9a-fA-F]{40}", source_commit):
        raise EvidenceError(f"SOURCE_COMMIT_FORMAT_INVALID:{source_commit}")
    if not re.fullmatch(r"[0-9a-fA-F]{40}", source_tree):
        raise EvidenceError(f"SOURCE_TREE_FORMAT_INVALID:{source_tree}")
    source_repo = absolute(source_repo)
    if not source_repo.is_dir() or is_reparse(source_repo):
        raise EvidenceError(f"SOURCE_REPOSITORY_UNSAFE:{source_repo}")
    branch = git_text(source_repo, "branch", "--show-current")
    head = git_text(source_repo, "rev-parse", "HEAD")
    resolved_commit = git_text(source_repo, "rev-parse", f"{source_commit}^{{commit}}")
    resolved_tree = git_text(source_repo, "rev-parse", f"{source_commit}^{{tree}}")
    if branch != EXPECTED_SOURCE_BRANCH:
        raise EvidenceError(f"SOURCE_BRANCH_MISMATCH:{branch}")
    if head.lower() != resolved_commit.lower() or resolved_commit.lower() != source_commit.lower():
        raise EvidenceError(f"SOURCE_COMMIT_MISMATCH:{head}:{resolved_commit}:{source_commit}")
    if resolved_tree.lower() != source_tree.lower():
        raise EvidenceError(f"SOURCE_TREE_MISMATCH:{resolved_tree}:{source_tree}")
    for relative in DIAGNOSTIC_SOURCE_FILES:
        data = git_blob(source_repo, resolved_commit, relative)
        destination = "source/diagnostic-repository/" + relative
        add_entry(entries, origins, destination, data,
                  f"git:{resolved_commit}:{relative}")
    return {"branch": branch, "commit": resolved_commit, "tree": resolved_tree}


def iter_regular_tree(root: Path) -> Iterable[Path]:
    stack = [root]
    while stack:
        directory = stack.pop()
        if is_reparse(directory):
            raise EvidenceError(f"REPARSE_DIRECTORY_REFUSED:{directory}")
        with os.scandir(directory) as iterator:
            children = sorted(iterator, key=lambda item: item.name.casefold(), reverse=True)
        for child in children:
            path = Path(child.path)
            if child.is_symlink() or is_reparse(path):
                raise EvidenceError(f"REPARSE_POINT_REFUSED:{path}")
            if child.is_dir(follow_symlinks=False):
                stack.append(path)
            elif child.is_file(follow_symlinks=False):
                yield path
            else:
                raise EvidenceError(f"NON_REGULAR_BUILD_ENTRY_REFUSED:{path}")


def collect_build_reports(
    task_root: Path, build_report_root: Path, entries: dict[str, bytes],
    origins: dict[str, str], gaps: list[str], exclusions: list[str],
) -> None:
    build_report_root = absolute(build_report_root)
    if not build_report_root.exists():
        gaps.append(os.fspath(build_report_root))
        return
    require_safe_chain(task_root, build_report_root, must_exist=True)
    terminal = build_report_root / "G2B_BUILD_RESULT.txt"
    if not terminal.is_file():
        gaps.append(os.fspath(terminal))
    for source in iter_regular_tree(build_report_root):
        relative = source.relative_to(build_report_root).as_posix()
        suffix = source.suffix.casefold()
        destination = "raw-build/" + relative
        if suffix in PROHIBITED_SUFFIXES or suffix not in ALLOWED_TEXT_SUFFIXES:
            exclusions.append(os.fspath(source))
            continue
        if source.stat().st_size > MAX_RAW_REPORT_BYTES:
            exclusions.append(
                f"{source}::TEXT_REPORT_OVER_{MAX_RAW_REPORT_BYTES}_BYTES_REFUSED"
            )
            continue
        add_entry(entries, origins, destination,
                  read_task_text(task_root, source, destination), os.fspath(source))


def key_value_document(data: bytes, source: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for number, line in enumerate(data.decode("utf-8-sig").splitlines(), 1):
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if not key or key in values:
            raise EvidenceError(f"KEY_VALUE_DOCUMENT_INVALID:{source}:{number}:{key}")
        values[key] = value
    return values


def validate_build_inputs(
    task_root: Path, build_report_root: Path, simulation_root: Path,
    source_commit: str, source_tree: str, gaps: list[str],
) -> dict[str, Any]:
    checks: dict[str, Any] = {}
    provenance_path = build_report_root / "G2B_BUILD_PROVENANCE.txt"
    runtime_path = build_report_root / "G2B_EXPECTED_RUNTIME_PROVENANCE.txt"
    for label, path in (("build_provenance", provenance_path),
                        ("runtime_provenance", runtime_path)):
        if not path.is_file():
            gaps.append(os.fspath(path))
            continue
        data = read_task_text(task_root, path, "raw-build/" + path.name)
        values = key_value_document(data, path)
        expected = {
            "build_provenance": {
                "BUILD_PROFILE": "NVP_VIDEO_DIAGNOSTIC",
                "ENABLE_NVP_VIDEO_DIAGNOSTIC": "1",
                "SOURCE_IDENTITY_KIND": "CLEAN_EXACT_GIT_COMMIT",
                "REPOSITORY_HEAD": source_commit,
                "REPOSITORY_HEAD_TREE": source_tree,
                "SOURCE_BRANCH": EXPECTED_SOURCE_BRANCH,
                "SOURCE_CLEAN": "PASS",
                "CHECKPOINT_REUSE": "NO",
            },
            "runtime_provenance": {
                "TASK": TASK,
                "BUILD_PROFILE": "NVP_VIDEO_DIAGNOSTIC",
                "EXECUTION_MODE": "POSTCOMMIT_FULL_BUILD",
                "COMMITTED_IMPLEMENTATION_SOURCE": source_commit,
                "SOURCE_TREE_REQUESTED": source_tree,
                "SOURCE_BRANCH_ACTUAL": EXPECTED_SOURCE_BRANCH,
                "SOURCE_CLEAN": "PASS",
                "NVP_VIDEO_DIAG1_R1_SIMULATION_GATE": "19/19_PASS",
                "SIMULATION_RECEIPT_SHA256": EXPECTED_SIMULATION_RECEIPT_SHA256,
            },
        }[label]
        mismatches = {
            key: {"expected": value, "actual": values.get(key)}
            for key, value in expected.items() if values.get(key) != value
        }
        if mismatches:
            raise EvidenceError(
                f"{label.upper()}_MISMATCH:" + json.dumps(mismatches, sort_keys=True)
            )
        checks[label] = "PASS"
    simulation_receipt = simulation_root / "NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt"
    if not simulation_receipt.is_file():
        gaps.append(os.fspath(simulation_receipt))
    else:
        receipt_data = read_task_text(
            task_root, simulation_receipt,
            "raw-simulation/NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt",
        )
        actual_sha = sha256_bytes(receipt_data)
        if actual_sha != EXPECTED_SIMULATION_RECEIPT_SHA256:
            raise EvidenceError(
                "SIMULATION_RECEIPT_SHA256_MISMATCH:"
                f"{actual_sha}:{EXPECTED_SIMULATION_RECEIPT_SHA256}"
            )
        checks["simulation_receipt_sha256"] = actual_sha
    return checks


def collect_simulation_reports(
    task_root: Path, simulation_root: Path, entries: dict[str, bytes],
    origins: dict[str, str], gaps: list[str], exclusions: list[str],
) -> None:
    simulation_root = absolute(simulation_root)
    if not simulation_root.exists():
        gaps.append(os.fspath(simulation_root))
        return
    require_safe_chain(task_root, simulation_root, must_exist=True)
    receipt = simulation_root / "NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt"
    if not receipt.is_file():
        gaps.append(os.fspath(receipt))
    for source in sorted(simulation_root.iterdir(), key=lambda item: item.name.casefold()):
        require_safe_chain(task_root, source, must_exist=True)
        if source.is_dir():
            if is_reparse(source):
                raise EvidenceError(f"REPARSE_DIRECTORY_REFUSED:{source}")
            exclusions.append(os.fspath(source))
            continue
        destination = "raw-simulation/" + source.name
        if source.suffix.casefold() not in ALLOWED_TEXT_SUFFIXES:
            exclusions.append(os.fspath(source))
            continue
        add_entry(entries, origins, destination,
                  read_task_text(task_root, source, destination), os.fspath(source))


def build_index(entries: dict[str, bytes]) -> bytes:
    lines = [
        "# AHD v41 G2B NVP VIDEO DIAG1-R1 evidence index",
        "",
        "This sanitized package contains the exact required Phase L evidence files,",
        "commit-bound diagnostic/source tooling, and text-only build/simulation metadata.",
        "No bitstream, DCP, driver/helper binary, raw capture, UYVY/PNG/image content,",
        "camera pixels, credential, symlink, junction, or other reparse point is included.",
        "",
        "Files:",
        "",
    ]
    lines.extend(f"- `{name}`" for name in sorted(entries, key=str.casefold))
    lines.append(f"- `{INDEX_NAME}`")
    lines.append(f"- `{MANIFEST_NAME}` (manifest self-entry intentionally omitted)")
    return ("\n".join(lines) + "\n").encode("utf-8")


def build_manifest(entries: dict[str, bytes]) -> bytes:
    if MANIFEST_NAME in entries:
        raise EvidenceError("MANIFEST_SELF_ENTRY_PREEXISTS")
    return ("\n".join(
        f"{sha256_bytes(entries[name])}  {name}"
        for name in sorted(entries, key=str.casefold)
    ) + "\n").encode("utf-8")


def create_plan(
    task_root: Path, required_root: Path, source_repo: Path,
    source_commit: str, source_tree: str, build_report_root: Path,
    simulation_root: Path,
) -> tuple[dict[str, bytes], dict[str, Any]]:
    entries: dict[str, bytes] = {}
    origins: dict[str, str] = {}
    gaps: list[str] = []
    exclusions: list[str] = []
    collect_required(task_root, required_root, entries, origins, gaps)
    collect_task_tools(task_root, entries, origins, gaps)
    collect_task_support(task_root, entries, origins, gaps)
    source_identity = collect_diagnostic_source(
        source_repo, source_commit, source_tree, entries, origins
    )
    build_input_checks = validate_build_inputs(
        task_root, build_report_root, simulation_root, source_commit, source_tree, gaps
    )
    collect_build_reports(task_root, build_report_root, entries, origins, gaps,
                          exclusions)
    collect_simulation_reports(task_root, simulation_root, entries, origins, gaps,
                               exclusions)
    if not gaps:
        add_entry(entries, origins, INDEX_NAME, build_index(entries), "generated:index")
        manifest = build_manifest(entries)
        validate_public_bytes(MANIFEST_NAME, manifest)
        entries[MANIFEST_NAME] = manifest
        origins[MANIFEST_NAME] = "generated:manifest"
    summary = {
        "task": TASK,
        "target_directory": TARGET_DIRECTORY,
        "required_file_count": len(REQUIRED_FILES),
        "required_files_present": len(set(entries) & set(REQUIRED_FILES)),
        "planned_file_count": len(entries),
        "planned_bytes": sum(len(value) for value in entries.values()),
        "gaps": sorted(set(gaps), key=str.casefold),
        "excluded_prohibited_or_non_allowlisted_inputs": sorted(
            set(exclusions), key=str.casefold
        ),
        "source_identity": source_identity,
        "build_input_checks": build_input_checks,
        "origins": origins,
    }
    return entries, summary


def write_package(task_root: Path, output: Path, entries: dict[str, bytes]) -> None:
    output = require_safe_chain(task_root, output, must_exist=False)
    if output.exists() or output.is_symlink():
        raise EvidenceError(f"FRESH_PACKAGE_PATH_REQUIRED:{output}")
    parent = require_safe_chain(task_root, output.parent, must_exist=False)
    parent.mkdir(parents=True, exist_ok=True)
    parent = require_safe_chain(task_root, parent, must_exist=True)
    # Keep the temporary component short enough for Windows MAX_PATH while the
    # final package still retains the exact governed directory name.
    temporary = parent / f".a-{uuid.uuid4().hex[:12]}"
    temporary.mkdir()
    try:
        for relative, data in sorted(entries.items(), key=lambda item: item[0].casefold()):
            destination = temporary.joinpath(*PurePosixPath(relative).parts)
            destination.parent.mkdir(parents=True, exist_ok=True)
            with destination.open("xb") as handle:
                handle.write(data)
                handle.flush()
                os.fsync(handle.fileno())
        os.replace(temporary, output)
    finally:
        if temporary.exists() and not is_reparse(temporary):
            shutil.rmtree(temporary)


def walk_package(package: Path) -> dict[str, Path]:
    package = absolute(package)
    if not package.is_dir() or is_reparse(package):
        raise EvidenceError(f"PACKAGE_ROOT_UNSAFE:{package}")
    result: dict[str, Path] = {}
    for path in iter_regular_tree(package):
        relative = path.relative_to(package).as_posix()
        validate_relative_name(relative)
        if any(existing.casefold() == relative.casefold() for existing in result):
            raise EvidenceError(f"CASE_COLLIDING_PACKAGE_PATH:{relative}")
        validate_public_bytes(relative, path.read_bytes())
        result[relative] = path
    return result


def parse_manifest(data: bytes) -> dict[str, str]:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise EvidenceError("MANIFEST_NOT_UTF8") from exc
    expected: dict[str, str] = {}
    for number, line in enumerate(text.splitlines(), 1):
        match = re.fullmatch(r"([0-9A-F]{64})  (.+)", line)
        if not match:
            raise EvidenceError(f"MANIFEST_LINE_INVALID:{number}")
        digest, relative = match.groups()
        relative = validate_relative_name(relative)
        if relative == MANIFEST_NAME:
            raise EvidenceError("MANIFEST_SELF_ENTRY_REFUSED")
        if any(existing.casefold() == relative.casefold() for existing in expected):
            raise EvidenceError(f"MANIFEST_DUPLICATE_PATH:{relative}")
        expected[relative] = digest
    return expected


def verify_package(package: Path) -> dict[str, Any]:
    package = absolute(package)
    files = walk_package(package)
    missing_required = sorted(set(REQUIRED_FILES) - set(files), key=str.casefold)
    if missing_required:
        raise EvidenceError("PACKAGE_REQUIRED_FILES_MISSING:" + "|".join(missing_required))
    manifest_path = files[MANIFEST_NAME]
    manifest = parse_manifest(manifest_path.read_bytes())
    actual_without_manifest = set(files) - {MANIFEST_NAME}
    if set(manifest) != actual_without_manifest:
        missing = sorted(actual_without_manifest - set(manifest), key=str.casefold)
        extra = sorted(set(manifest) - actual_without_manifest, key=str.casefold)
        raise EvidenceError(
            "MANIFEST_SCOPE_MISMATCH:MISSING=" + "|".join(missing) +
            ":EXTRA=" + "|".join(extra)
        )
    mismatches = [relative for relative, digest in manifest.items()
                  if sha256_file(files[relative]) != digest]
    if mismatches:
        raise EvidenceError("MANIFEST_HASH_MISMATCH:" + "|".join(mismatches))
    return {
        "result": "PASS",
        "package": os.fspath(package),
        "files_including_manifest": len(files),
        "manifest_entries": len(manifest),
        "manifest_excludes_itself": MANIFEST_NAME not in manifest,
        "manifest_sha256": sha256_file(manifest_path),
        "total_bytes": sum(path.stat().st_size for path in files.values()),
        "files": {
            relative: {"bytes": path.stat().st_size, "sha256": sha256_file(path)}
            for relative, path in sorted(files.items(), key=lambda item: item[0].casefold())
        },
    }


def copy_package_to_repo(package: Path, destination: Path) -> None:
    if destination.exists() or destination.is_symlink():
        raise EvidenceError(f"EVIDENCE_TARGET_ALREADY_EXISTS:{destination}")
    files = walk_package(package)
    destination.mkdir()
    try:
        for relative, source in sorted(files.items(), key=lambda item: item[0].casefold()):
            target = destination.joinpath(*PurePosixPath(relative).parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with source.open("rb") as read_handle, target.open("xb") as write_handle:
                shutil.copyfileobj(read_handle, write_handle, 1024 * 1024)
                write_handle.flush()
                os.fsync(write_handle.fileno())
    except BaseException:
        # Only the fresh destination created by this call is eligible for cleanup.
        if destination.exists() and not is_reparse(destination):
            shutil.rmtree(destination)
        raise


def remote_url_is_expected(url: str) -> bool:
    normalized = url.strip().replace("\\", "/").casefold()
    patterns = (
        r"https://github\.com/lukaszsudul/ahd-diagnostic-evidence(?:\.git)?",
        r"git@github\.com:lukaszsudul/ahd-diagnostic-evidence(?:\.git)?",
        r"ssh://git@github\.com/lukaszsudul/ahd-diagnostic-evidence(?:\.git)?",
    )
    return any(re.fullmatch(pattern, normalized) for pattern in patterns)


def nul_paths(data: bytes) -> list[str]:
    return [item.decode("utf-8") for item in data.split(b"\x00") if item]


def verify_commit_scope(repo: Path, commit: str, package: Path) -> dict[str, Any]:
    package_files = walk_package(package)
    expected = {f"{TARGET_DIRECTORY}/{relative}" for relative in package_files}
    changed = set(nul_paths(run([
        "git", "-C", os.fspath(repo), "diff-tree", "--no-commit-id",
        "--root", "--name-only", "-r", "-z", commit,
    ]).stdout))
    if changed != expected:
        raise EvidenceError(
            "COMMIT_SCOPE_MISMATCH:MISSING=" + "|".join(sorted(expected - changed)) +
            ":EXTRA=" + "|".join(sorted(changed - expected))
        )
    for relative, local_path in package_files.items():
        remote_path = f"{TARGET_DIRECTORY}/{relative}"
        blob = run(["git", "-C", os.fspath(repo), "show", f"{commit}:{remote_path}"]).stdout
        if blob != local_path.read_bytes():
            raise EvidenceError(f"LOCAL_COMMIT_BLOB_MISMATCH:{remote_path}")
    return {"changed_files": len(changed), "scope": TARGET_DIRECTORY}


def read_cat_file_batch(repo: Path, object_ids: list[str]) -> dict[str, bytes]:
    process = subprocess.Popen(
        ["git", "-C", os.fspath(repo), "cat-file", "--batch"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    assert process.stdin is not None and process.stdout is not None
    blobs: dict[str, bytes] = {}
    try:
        for object_id in object_ids:
            process.stdin.write(object_id.encode("ascii") + b"\n")
            process.stdin.flush()
            header = process.stdout.readline().rstrip(b"\n").decode("ascii")
            parts = header.split(" ")
            if len(parts) != 3 or parts[1] != "blob":
                raise EvidenceError(f"REMOTE_OBJECT_NOT_BLOB:{object_id}:{header}")
            size = int(parts[2])
            data = process.stdout.read(size)
            terminator = process.stdout.read(1)
            if len(data) != size or terminator != b"\n":
                raise EvidenceError(f"REMOTE_BLOB_SHORT_READ:{object_id}")
            blobs[object_id] = data
        process.stdin.close()
        stderr = process.stderr.read().decode("utf-8", "replace") if process.stderr else ""
        code = process.wait()
        if code != 0:
            raise EvidenceError(f"CAT_FILE_BATCH_FAILED:{code}:{stderr.strip()}")
        return blobs
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()


def commit_pinned_sparse_readback(
    remote_url: str, commit: str, package: Path,
) -> dict[str, Any]:
    if not remote_url_is_expected(remote_url):
        raise EvidenceError(f"REMOTE_REPOSITORY_MISMATCH:{remote_url}")
    local = verify_package(package)
    local_files = walk_package(package)
    with tempfile.TemporaryDirectory(prefix="g2b-nvp-diag1-r1-readback-") as temp:
        clone = Path(temp) / "repo"
        run([
            "git", "clone", "--no-checkout", "--filter=blob:none", "--sparse",
            "--single-branch", "--branch", BRANCH, "--", remote_url, os.fspath(clone),
        ])
        run(["git", "-C", os.fspath(clone), "sparse-checkout", "set", "--no-cone",
             "--", TARGET_DIRECTORY])
        resolved = git_text(clone, "rev-parse", f"{commit}^{{commit}}")
        if resolved.lower() != commit.lower():
            raise EvidenceError(f"READBACK_COMMIT_IDENTITY_MISMATCH:{resolved}:{commit}")
        listing = run([
            "git", "-C", os.fspath(clone), "ls-tree", "-r", "-z", "-l",
            "--full-tree", commit,
            "--", TARGET_DIRECTORY,
        ]).stdout
        remote_entries: dict[str, tuple[str, int]] = {}
        prefix = TARGET_DIRECTORY + "/"
        for record in (item for item in listing.split(b"\x00") if item):
            metadata, path_bytes = record.split(b"\t", 1)
            mode, object_type, object_id, size_text = metadata.decode("ascii").split()
            full_path = path_bytes.decode("utf-8")
            if object_type != "blob" or mode == "120000" or not full_path.startswith(prefix):
                raise EvidenceError(f"REMOTE_TREE_ENTRY_REFUSED:{full_path}:{mode}:{object_type}")
            relative = validate_relative_name(full_path[len(prefix):])
            if any(existing.casefold() == relative.casefold()
                   for existing in remote_entries):
                raise EvidenceError(f"REMOTE_CASE_COLLIDING_PATH:{relative}")
            remote_entries[relative] = (object_id, int(size_text))
        if set(remote_entries) != set(local_files):
            raise EvidenceError(
                "REMOTE_DIRECTORY_SCOPE_MISMATCH:MISSING=" +
                "|".join(sorted(set(local_files) - set(remote_entries))) + ":EXTRA=" +
                "|".join(sorted(set(remote_entries) - set(local_files)))
            )
        blobs = read_cat_file_batch(clone, [item[0] for item in remote_entries.values()])
        verified: list[dict[str, Any]] = []
        for relative, (object_id, declared_size) in sorted(remote_entries.items()):
            remote_bytes = blobs[object_id]
            local_bytes = local_files[relative].read_bytes()
            if len(remote_bytes) != declared_size or remote_bytes != local_bytes:
                raise EvidenceError(f"COMMIT_PINNED_BYTE_READBACK_MISMATCH:{relative}")
            verified.append({
                "path": relative,
                "bytes": len(remote_bytes),
                "sha256": sha256_bytes(remote_bytes),
                "git_blob": object_id,
            })
    return {
        "result": "PASS",
        "remote": remote_url,
        "branch": BRANCH,
        "commit": commit,
        "directory": TARGET_DIRECTORY,
        "sparse_no_checkout_clone": True,
        "byte_for_byte_files_verified": len(verified),
        "manifest_entries_verified": local["manifest_entries"],
        "manifest_sha256": local["manifest_sha256"],
        "verified": verified,
    }


def write_receipt(path: Path, receipt: dict[str, Any]) -> None:
    path = absolute(path)
    if path.exists() or path.is_symlink():
        raise EvidenceError(f"FRESH_RECEIPT_PATH_REQUIRED:{path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(receipt, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def publish(
    package: Path, evidence_repo: Path, receipt_path: Path, confirmation: str,
) -> dict[str, Any]:
    if confirmation != PUBLISH_CONFIRMATION:
        raise EvidenceError("EXPLICIT_PUBLICATION_CONFIRMATION_REQUIRED")
    verify_package(package)
    evidence_repo = absolute(evidence_repo)
    if not evidence_repo.is_dir() or is_reparse(evidence_repo):
        raise EvidenceError(f"EVIDENCE_REPOSITORY_UNSAFE:{evidence_repo}")
    if git_text(evidence_repo, "branch", "--show-current") != BRANCH:
        raise EvidenceError("EVIDENCE_BRANCH_MUST_BE_MAIN")
    remote_url = git_text(evidence_repo, "remote", "get-url", "origin")
    if not remote_url_is_expected(remote_url):
        raise EvidenceError(f"REMOTE_REPOSITORY_MISMATCH:{remote_url}")
    if run(["git", "-C", os.fspath(evidence_repo), "diff", "--quiet"], check=False).returncode:
        raise EvidenceError("EVIDENCE_REPOSITORY_TRACKED_WORKTREE_NOT_CLEAN")
    if run(["git", "-C", os.fspath(evidence_repo), "diff", "--cached", "--quiet"],
           check=False).returncode:
        raise EvidenceError("PREEXISTING_STAGED_CHANGES_REFUSED")
    run(["git", "-C", os.fspath(evidence_repo), "fetch", "--no-tags", "origin",
         f"refs/heads/{BRANCH}:refs/remotes/origin/{BRANCH}"])
    parent = git_text(evidence_repo, "rev-parse", "HEAD")
    remote_head = git_text(evidence_repo, "rev-parse", f"refs/remotes/origin/{BRANCH}")
    if parent.lower() != remote_head.lower():
        raise EvidenceError(f"LOCAL_MAIN_NOT_AT_REMOTE_HEAD:{parent}:{remote_head}")
    destination = require_safe_chain(
        evidence_repo, evidence_repo / TARGET_DIRECTORY, must_exist=False
    )
    copy_package_to_repo(package, destination)
    run(["git", "-C", os.fspath(evidence_repo), "add", "--sparse", "--",
         TARGET_DIRECTORY])
    staged = set(nul_paths(run([
        "git", "-C", os.fspath(evidence_repo), "diff", "--cached", "--name-only",
        "--diff-filter=ACMRTUXB", "-z", "--", TARGET_DIRECTORY,
    ]).stdout))
    package_files = walk_package(package)
    expected = {f"{TARGET_DIRECTORY}/{relative}" for relative in package_files}
    all_staged = set(nul_paths(run([
        "git", "-C", os.fspath(evidence_repo), "diff", "--cached", "--name-only", "-z",
    ]).stdout))
    if staged != expected or all_staged != expected:
        raise EvidenceError("STAGED_SCOPE_NOT_EXACT_TARGET_PACKAGE")
    # Catch Git clean/smudge or line-ending normalization before creating a
    # local commit.  The index itself must already contain the exact package
    # bytes that will later be checked from the commit and remote clone.
    for relative, local_path in package_files.items():
        staged_path = f"{TARGET_DIRECTORY}/{relative}"
        staged_blob = run([
            "git", "-C", os.fspath(evidence_repo), "show", f":{staged_path}",
        ]).stdout
        if staged_blob != local_path.read_bytes():
            raise EvidenceError(f"STAGED_BLOB_BYTE_MISMATCH:{staged_path}")
    status = run([
        "git", "-C", os.fspath(evidence_repo), "diff", "--cached", "--name-status",
        "--", TARGET_DIRECTORY,
    ], text=True).stdout.splitlines()
    if not status or any(not line.startswith("A\t") for line in status):
        raise EvidenceError("TARGET_MUST_BE_NEW_ADDITIONS_ONLY")
    run(["git", "-C", os.fspath(evidence_repo), "commit", "-m", COMMIT_MESSAGE,
         "--", TARGET_DIRECTORY])
    commit = git_text(evidence_repo, "rev-parse", "HEAD")
    commit_parent = git_text(evidence_repo, "rev-parse", "HEAD^")
    if commit_parent.lower() != parent.lower():
        raise EvidenceError(f"COMMIT_PARENT_MISMATCH:{commit_parent}:{parent}")
    committed_message = run([
        "git", "-C", os.fspath(evidence_repo), "log", "-1", "--format=%B", commit,
    ], text=True).stdout.rstrip("\r\n")
    if committed_message != COMMIT_MESSAGE:
        raise EvidenceError(f"COMMIT_MESSAGE_MISMATCH:{committed_message!r}")
    scope = verify_commit_scope(evidence_repo, commit, package)
    # This command deliberately contains no force, force-with-lease, or ref deletion.
    run(["git", "-C", os.fspath(evidence_repo), "push", "origin",
         f"HEAD:refs/heads/{BRANCH}"])
    advertised = run([
        "git", "-C", os.fspath(evidence_repo), "ls-remote", "--heads", "origin",
        f"refs/heads/{BRANCH}",
    ], text=True).stdout.split()
    if not advertised or advertised[0].lower() != commit.lower():
        raise EvidenceError("PUSHED_REMOTE_HEAD_IDENTITY_NOT_CONFIRMED")
    receipt = commit_pinned_sparse_readback(remote_url, commit, package)
    receipt["commit_scope"] = scope
    receipt["push_mode"] = "NORMAL_NON_FORCE"
    receipt["commit_message"] = COMMIT_MESSAGE
    write_receipt(receipt_path, receipt)
    return receipt


def add_assemble_arguments(parser: argparse.ArgumentParser, task_root: Path) -> None:
    parser.add_argument("--task-root", type=Path, default=task_root)
    parser.add_argument("--required-root", type=Path)
    parser.add_argument("--source-repo", type=Path,
                        default=Path(r"C:\FPGA\V41_G2B_NVP_VIDEO_DIAG1"))
    parser.add_argument("--source-commit", default=EXPECTED_SOURCE_COMMIT)
    parser.add_argument("--source-tree", default=EXPECTED_SOURCE_TREE)
    parser.add_argument("--build-report-root", type=Path)
    parser.add_argument("--simulation-root", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--dry-run", action="store_true")


def main() -> int:
    default_task_root = absolute(Path(__file__).parent.parent)
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="action", required=True)
    assemble_parser = subparsers.add_parser("assemble")
    add_assemble_arguments(assemble_parser, default_task_root)
    validate_parser = subparsers.add_parser("validate")
    validate_parser.add_argument("--package", required=True, type=Path)
    publish_parser = subparsers.add_parser("publish")
    publish_parser.add_argument("--package", required=True, type=Path)
    publish_parser.add_argument("--evidence-repo", required=True, type=Path)
    publish_parser.add_argument("--receipt", required=True, type=Path)
    publish_parser.add_argument("--confirm", required=True)
    readback_parser = subparsers.add_parser("readback")
    readback_parser.add_argument("--remote", required=True)
    readback_parser.add_argument("--commit", required=True)
    readback_parser.add_argument("--package", required=True, type=Path)
    readback_parser.add_argument("--receipt", type=Path)
    args = parser.parse_args()

    try:
        if args.action == "assemble":
            task_root = absolute(args.task_root)
            require_safe_chain(task_root, task_root, must_exist=True)
            required_root = absolute(args.required_root or
                                     (task_root / "evidence-staging" / "required"))
            build_root = absolute(args.build_report_root or
                                  (task_root / "reports" / "vivado_full"))
            simulation_root = absolute(args.simulation_root or
                                       (task_root / "build" /
                                        "simulation_gate_committed_final"))
            output = absolute(args.output or
                              (task_root / "evidence-staging" / TARGET_DIRECTORY))
            require_safe_chain(task_root, required_root, must_exist=False)
            require_safe_chain(task_root, build_root, must_exist=False)
            require_safe_chain(task_root, simulation_root, must_exist=False)
            require_safe_chain(task_root, output, must_exist=False)
            entries, summary = create_plan(
                task_root, required_root, absolute(args.source_repo),
                args.source_commit, args.source_tree, build_root, simulation_root,
            )
            summary["result"] = "PASS" if not summary["gaps"] else "BLOCKED"
            summary["dry_run"] = args.dry_run
            summary["output"] = os.fspath(output)
            if not args.dry_run:
                if summary["gaps"]:
                    raise EvidenceError(
                        "ASSEMBLY_INPUTS_INCOMPLETE:" + "|".join(summary["gaps"])
                    )
                write_package(task_root, output, entries)
                summary["validation"] = verify_package(output)
            print(json.dumps(summary, indent=2, ensure_ascii=False))
            return 0
        if args.action == "validate":
            print(json.dumps(verify_package(args.package), indent=2, ensure_ascii=False))
            return 0
        if args.action == "publish":
            receipt = publish(args.package, args.evidence_repo, args.receipt,
                              args.confirm)
            print(json.dumps({key: value for key, value in receipt.items()
                              if key != "verified"}, indent=2, ensure_ascii=False))
            return 0
        if not re.fullmatch(r"[0-9a-fA-F]{40,64}", args.commit):
            raise EvidenceError("COMMIT_FORMAT_INVALID")
        receipt = commit_pinned_sparse_readback(args.remote, args.commit, args.package)
        if args.receipt:
            write_receipt(args.receipt, receipt)
        print(json.dumps({key: value for key, value in receipt.items()
                          if key != "verified"}, indent=2, ensure_ascii=False))
        return 0
    except EvidenceError as exc:
        print(json.dumps({"result": "FAIL", "error": str(exc)}, indent=2),
              file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
