from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import io
import json
import re
import subprocess
from pathlib import Path, PurePosixPath


PACKAGE_DIRECTORY = "v41-hardware-g2b-hw0-product-live-path-bringup-r2-warm-reboot"
MANIFEST_NAME = "G2B_HW0_PRODUCT_R2_SHA256_MANIFEST.txt"
REMOTE_REF = "refs/heads/main"
RESULT_NAME = "R2_REMOTE_READBACK_RESULT.json"
CLONE_LOG_NAME = "R2_REMOTE_READBACK_CLONE.log"
CLONE_DIRECTORY_NAME = "r2-remote-no-checkout"

REQUIRED_TOP_LEVEL = {
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


class ReadbackError(RuntimeError):
    pass


def run(*args: str, cwd: Path | None = None) -> bytes:
    completed = subprocess.run(
        list(args),
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.decode("utf-8", errors="replace").strip()
        raise ReadbackError(
            f"COMMAND_FAILED:returncode={completed.returncode}:args={args!r}:stderr={stderr}"
        )
    return completed.stdout


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def safe_relative_name(name: str) -> bool:
    if not name or "\\" in name or name.startswith("/") or "\x00" in name:
        return False
    return all(part not in {"", ".", ".."} for part in PurePosixPath(name).parts)


def remote_head(remote_url: str) -> str:
    raw = run("git", "ls-remote", "--exit-code", remote_url, REMOTE_REF)
    lines = [line for line in raw.decode("ascii").splitlines() if line]
    if len(lines) != 1:
        raise ReadbackError(f"REMOTE_REF_RESOLUTION_COUNT_MISMATCH:{len(lines)}")
    fields = lines[0].split()
    if len(fields) != 2 or fields[1] != REMOTE_REF or not re.fullmatch(r"[0-9a-fA-F]{40}", fields[0]):
        raise ReadbackError(f"MALFORMED_REMOTE_REF_RESULT:{lines[0]!r}")
    return fields[0].lower()


def read_blobs_batch(repo: Path, object_ids: list[str]) -> dict[str, bytes]:
    unique_object_ids = list(dict.fromkeys(object_ids))
    for object_id in unique_object_ids:
        if len(object_id) not in {40, 64} or any(
            character not in "0123456789abcdefABCDEF" for character in object_id
        ):
            raise ReadbackError(f"INVALID_TREE_OBJECT_ID:{object_id!r}")

    query = b"".join(object_id.encode("ascii") + b"\n" for object_id in unique_object_ids)
    completed = subprocess.run(
        ["git", "cat-file", "--batch"],
        cwd=repo,
        input=query,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.decode("utf-8", errors="replace").strip()
        raise ReadbackError(
            f"GIT_CAT_FILE_BATCH_FAILED:returncode={completed.returncode}:stderr={stderr}"
        )

    stream = io.BytesIO(completed.stdout)
    by_object_id: dict[str, bytes] = {}
    for expected_object_id in unique_object_ids:
        header = stream.readline()
        if not header.endswith(b"\n"):
            raise ReadbackError(
                f"TRUNCATED_CAT_FILE_BATCH_HEADER:{expected_object_id}:{header!r}"
            )
        fields = header[:-1].split()
        if len(fields) == 2 and fields[1] == b"missing":
            raise ReadbackError(f"MISSING_TREE_BLOB:{expected_object_id}")
        if len(fields) != 3:
            raise ReadbackError(
                f"MALFORMED_CAT_FILE_BATCH_HEADER:{expected_object_id}:{header!r}"
            )
        actual_object_id_bytes, object_type, size_bytes = fields
        try:
            actual_object_id = actual_object_id_bytes.decode("ascii")
            size = int(size_bytes.decode("ascii"))
        except (UnicodeDecodeError, ValueError) as exc:
            raise ReadbackError(
                f"MALFORMED_CAT_FILE_BATCH_HEADER:{expected_object_id}:{header!r}"
            ) from exc
        if actual_object_id.casefold() != expected_object_id.casefold():
            raise ReadbackError(
                "CAT_FILE_BATCH_OBJECT_ID_MISMATCH:"
                f"expected={expected_object_id}:actual={actual_object_id}"
            )
        if object_type != b"blob":
            raise ReadbackError(
                f"CAT_FILE_BATCH_NON_BLOB:{expected_object_id}:{object_type!r}"
            )
        if size < 0:
            raise ReadbackError(f"CAT_FILE_BATCH_NEGATIVE_SIZE:{expected_object_id}:{size}")
        data = stream.read(size)
        if len(data) != size:
            raise ReadbackError(
                f"TRUNCATED_CAT_FILE_BATCH_BLOB:{expected_object_id}:"
                f"expected={size}:actual={len(data)}"
            )
        delimiter = stream.read(1)
        if delimiter != b"\n":
            raise ReadbackError(
                f"CAT_FILE_BATCH_DELIMITER_MISMATCH:{expected_object_id}:{delimiter!r}"
            )
        by_object_id[expected_object_id.casefold()] = data

    trailing = stream.read()
    if trailing:
        raise ReadbackError(f"UNEXPECTED_CAT_FILE_BATCH_TRAILING_BYTES:{len(trailing)}")
    return by_object_id


def read_commit_tree(
    repo: Path, commit: str
) -> tuple[dict[str, bytes], dict[str, tuple[str, str]]]:
    raw = run(
        "git",
        "ls-tree",
        "-r",
        "-z",
        "--full-tree",
        commit,
        "--",
        PACKAGE_DIRECTORY,
        cwd=repo,
    )
    metadata: dict[str, tuple[str, str]] = {}
    prefix = f"{PACKAGE_DIRECTORY}/"
    for record in raw.split(b"\0"):
        if not record:
            continue
        try:
            header, path_bytes = record.split(b"\t", 1)
            mode, object_type, object_id = header.decode("ascii").split()
            path = path_bytes.decode("utf-8")
        except (ValueError, UnicodeDecodeError) as exc:
            raise ReadbackError(f"MALFORMED_LS_TREE_RECORD:{record!r}") from exc
        if not path.startswith(prefix):
            raise ReadbackError(f"TREE_PATH_OUTSIDE_R2_PREFIX:{path}")
        relative = path[len(prefix) :]
        if not safe_relative_name(relative):
            raise ReadbackError(f"UNSAFE_TREE_PATH:{path}")
        if object_type != "blob" or mode not in {"100644", "100755"}:
            raise ReadbackError(f"NONREGULAR_TREE_ENTRY:{path}:{mode}:{object_type}")
        if relative in metadata:
            raise ReadbackError(f"DUPLICATE_TREE_PATH:{relative}")
        metadata[relative] = (mode, object_id.lower())
    blobs = read_blobs_batch(repo, [object_id for _mode, object_id in metadata.values()])
    files = {
        relative: blobs[object_id.casefold()]
        for relative, (_mode, object_id) in metadata.items()
    }
    return files, metadata


def validate_sensitive_path(name: str) -> None:
    path = PurePosixPath(name)
    folded_parts = {part.casefold() for part in path.parts}
    if folded_parts & FORBIDDEN_COMPONENTS:
        raise ReadbackError(f"FORBIDDEN_DIRECTORY_OR_COMPONENT:{name}")
    basename = path.name.casefold()
    if basename in FORBIDDEN_BASENAMES or basename.startswith("pw-"):
        raise ReadbackError(f"SENSITIVE_HELPER_OR_SECRET_FILE:{name}")
    if path.suffix.casefold() in FORBIDDEN_SUFFIXES:
        raise ReadbackError(f"SENSITIVE_OR_CACHE_SUFFIX:{name}")


def parse_manifest(data: bytes) -> dict[str, str]:
    if b"\r" in data or not data.endswith(b"\n") or data.startswith(b"\xef\xbb\xbf"):
        raise ReadbackError("REMOTE_MANIFEST_NOT_EXACT_LF_UTF8")
    try:
        lines = data.decode("utf-8").splitlines()
    except UnicodeDecodeError as exc:
        raise ReadbackError(f"REMOTE_MANIFEST_NOT_UTF8:{exc}") from exc
    entries: dict[str, str] = {}
    for line_number, line in enumerate(lines, start=1):
        match = re.fullmatch(r"([0-9A-F]{64})  ([^\r\n]+)", line)
        if not match:
            raise ReadbackError(f"MALFORMED_REMOTE_MANIFEST_LINE:{line_number}:{line}")
        digest, relative = match.groups()
        if not safe_relative_name(relative):
            raise ReadbackError(f"UNSAFE_REMOTE_MANIFEST_PATH:{relative}")
        if relative == MANIFEST_NAME:
            raise ReadbackError("REMOTE_MANIFEST_NOT_SELF_EXCLUDING")
        if relative in entries:
            raise ReadbackError(f"DUPLICATE_REMOTE_MANIFEST_PATH:{relative}")
        entries[relative] = digest
    return entries


def validate_package(files: dict[str, bytes], source: str) -> int:
    top_level = {name for name in files if "/" not in name}
    if top_level != REQUIRED_TOP_LEVEL:
        missing = sorted(REQUIRED_TOP_LEVEL - top_level)
        extra = sorted(top_level - REQUIRED_TOP_LEVEL)
        raise ReadbackError(
            f"{source}_TOP_LEVEL_21_FILE_SET_MISMATCH:missing={missing}:extra={extra}"
        )
    top_level_directories = {name.split("/", 1)[0] for name in files if "/" in name}
    if top_level_directories != {"locks", "raw", "tools"}:
        raise ReadbackError(
            f"{source}_TOP_LEVEL_DIRECTORY_SET_MISMATCH:{sorted(top_level_directories)}"
        )
    folded: dict[str, str] = {}
    for name, data in files.items():
        validate_sensitive_path(name)
        folded_name = name.casefold()
        if folded_name in folded and folded[folded_name] != name:
            raise ReadbackError(f"{source}_CASE_COLLIDING_PATH:{folded[folded_name]}:{name}")
        folded[folded_name] = name
        if "/" not in name and PurePosixPath(name).suffix.casefold() in TEXT_SUFFIXES:
            if b"\r" in data or (data and not data.endswith(b"\n")):
                raise ReadbackError(f"{source}_NON_LF_TEXT_BYTES:{name}")
            try:
                text = data.decode("utf-8")
            except UnicodeDecodeError as exc:
                raise ReadbackError(f"{source}_TEXT_NOT_UTF8:{name}:{exc}") from exc
        path = PurePosixPath(name)
        if (
            len(path.parts) == 2
            and path.parts[0].casefold() == "tools"
            and path.name.casefold() in CONTENT_SCAN_EXEMPT_VALIDATORS
        ):
            continue
        upper = data.upper()
        if (
            re.search(rb"-----BEGIN [A-Z0-9 ]+ PRIVATE KEY-----", upper)
            or PLINK_PASSWORD_AUDIT_FAILURE in upper
            or CREDENTIAL_RELATIONSHIP_MARKER in upper
        ):
            raise ReadbackError(f"{source}_SENSITIVE_CONTENT:{name}")

    if MANIFEST_NAME not in files:
        raise ReadbackError(f"{source}_MANIFEST_MISSING")
    entries = parse_manifest(files[MANIFEST_NAME])
    expected_names = set(files) - {MANIFEST_NAME}
    if set(entries) != expected_names:
        missing = sorted(expected_names - set(entries))
        extra = sorted(set(entries) - expected_names)
        raise ReadbackError(
            f"{source}_MANIFEST_FILE_SET_MISMATCH:missing={missing}:extra={extra}"
        )
    for name, expected in entries.items():
        actual = sha256(files[name])
        if actual != expected:
            raise ReadbackError(
                f"{source}_MANIFEST_HASH_MISMATCH:path={name}:expected={expected}:actual={actual}"
            )
    return len(entries)


def safe_output(args: argparse.Namespace) -> tuple[Path, Path]:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", args.label):
        raise ReadbackError(f"INVALID_UNIQUE_OUTPUT_LABEL:{args.label!r}")
    if args.label in {".", ".."}:
        raise ReadbackError(f"INVALID_UNIQUE_OUTPUT_LABEL:{args.label!r}")
    output_root = args.output_root.resolve()
    output = (output_root / args.label).resolve()
    if output.parent != output_root:
        raise ReadbackError(f"OUTPUT_LABEL_ESCAPES_ROOT:{args.label!r}")
    if output.exists():
        raise ReadbackError(f"R2_READBACK_OUTPUT_LABEL_ALREADY_EXISTS:{output}")
    return output_root, output


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Perform an external, commit-pinned R2 remote byte read-back without "
            "changing the published package."
        )
    )
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--remote-url", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--label", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not re.fullmatch(r"[0-9a-fA-F]{40}", args.commit):
        raise SystemExit(f"R2_REMOTE_READBACK_FAILURE=COMMIT_NOT_FULL_SHA:{args.commit!r}")
    commit = args.commit.lower()
    if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*://[^/]*@", args.remote_url):
        raise SystemExit("R2_REMOTE_READBACK_FAILURE=REMOTE_URL_CONTAINS_USERINFO")

    try:
        repo = args.repo_root.resolve(strict=True)
        if run("git", "rev-parse", "--is-inside-work-tree", cwd=repo).decode("ascii").strip() != "true":
            raise ReadbackError("REPO_ROOT_NOT_GIT_WORKTREE")
        local_commit = run(
            "git", "rev-parse", "--verify", f"{commit}^{{commit}}", cwd=repo
        ).decode("ascii").strip().lower()
        if local_commit != commit:
            raise ReadbackError(
                f"LOCAL_COMMIT_MISMATCH:expected={commit}:actual={local_commit}"
            )

        _output_root, output = safe_output(args)
        try:
            output.relative_to(repo)
        except ValueError:
            pass
        else:
            raise ReadbackError(f"READBACK_OUTPUT_MUST_BE_OUTSIDE_REPOSITORY:{output}")
        output.mkdir(parents=True, exist_ok=False)

        before = remote_head(args.remote_url)
        if before != commit:
            raise ReadbackError(
                f"REMOTE_HEAD_MISMATCH_BEFORE:expected={commit}:actual={before}"
            )

        clone = output / CLONE_DIRECTORY_NAME
        clone_result = subprocess.run(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--no-checkout",
                "--no-tags",
                "--single-branch",
                "--branch",
                "main",
                "--",
                args.remote_url,
                str(clone),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        (output / CLONE_LOG_NAME).write_bytes(clone_result.stdout + clone_result.stderr)
        if clone_result.returncode != 0:
            raise ReadbackError(f"FRESH_REMOTE_CLONE_FAILED:{clone_result.returncode}")

        clone_head = run("git", "rev-parse", "HEAD", cwd=clone).decode("ascii").strip().lower()
        if clone_head != commit:
            raise ReadbackError(
                f"FRESH_REMOTE_HEAD_MISMATCH:expected={commit}:actual={clone_head}"
            )

        local_files, local_metadata = read_commit_tree(repo, commit)
        remote_files, remote_metadata = read_commit_tree(clone, commit)
        local_manifest_entries = validate_package(local_files, "LOCAL_COMMIT")
        remote_manifest_entries = validate_package(remote_files, "FRESH_REMOTE_COMMIT")

        if set(local_files) != set(remote_files):
            missing = sorted(set(local_files) - set(remote_files))
            unexpected = sorted(set(remote_files) - set(local_files))
            raise ReadbackError(
                f"REMOTE_FILE_SET_MISMATCH:missing={missing}:unexpected={unexpected}"
            )

        comparisons: list[dict[str, object]] = []
        for name in sorted(local_files):
            local = local_files[name]
            remote = remote_files[name]
            if local != remote:
                raise ReadbackError(f"REMOTE_BYTE_MISMATCH:{name}")
            if local_metadata[name] != remote_metadata[name]:
                raise ReadbackError(
                    f"REMOTE_TREE_METADATA_MISMATCH:{name}:"
                    f"local={local_metadata[name]}:remote={remote_metadata[name]}"
                )
            mode, object_id = local_metadata[name]
            comparisons.append(
                {
                    "path": f"{PACKAGE_DIRECTORY}/{name}",
                    "mode": mode,
                    "git_blob_oid": object_id,
                    "bytes": len(local),
                    "local_sha256": sha256(local),
                    "remote_sha256": sha256(remote),
                    "result": "PASS",
                }
            )

        after = remote_head(args.remote_url)
        if after != commit:
            raise ReadbackError(
                f"REMOTE_MOVED_DURING_READBACK:expected={commit}:actual={after}"
            )

        checked_at = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
        result = {
            "r2_remote_readback": "PASS",
            "output_label": args.label,
            "remote_url": args.remote_url,
            "ref": REMOTE_REF,
            "commit": commit,
            "remote_head_before": before,
            "fresh_clone_head": clone_head,
            "remote_head_after": after,
            "directory": PACKAGE_DIRECTORY,
            "required_top_level_files": len(REQUIRED_TOP_LEVEL),
            "files_checked": len(comparisons),
            "local_manifest_entries_checked": local_manifest_entries,
            "remote_manifest_entries_checked": remote_manifest_entries,
            "manifest_self_excluded": True,
            "byte_for_byte_local_remote_equal": True,
            "generated_top_level_line_endings": "LF",
            "nested_execution_evidence_bytes_preserved": True,
            "package_mutated": False,
            "readback_method": (
                "fresh no-checkout shallow clone of refs/heads/main; exact commit-pinned "
                "Git tree and blob reads; compare every path, mode, byte length, byte "
                "sequence, SHA-256, and every self-excluding R2 manifest entry"
            ),
            "checked_at_utc": checked_at,
            "comparisons": comparisons,
        }
        result_path = output / RESULT_NAME
        result_path.write_text(
            json.dumps(result, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
            newline="\n",
        )
    except (OSError, ReadbackError, UnicodeDecodeError) as exc:
        print("R2_REMOTE_READBACK=FAIL")
        print(f"R2_REMOTE_READBACK_FAILURE={exc}")
        raise SystemExit(1) from exc

    print("R2_REMOTE_READBACK=PASS")
    print(f"R2_REMOTE_READBACK_COMMIT={commit}")
    print(f"R2_REMOTE_READBACK_FILES={len(comparisons)}")
    print(f"R2_REMOTE_READBACK_MANIFEST_ENTRIES={remote_manifest_entries}")
    print("R2_REMOTE_READBACK_BYTE_MISMATCHES=0")
    print("R2_REMOTE_READBACK_PACKAGE_MUTATIONS=0")
    print(f"R2_REMOTE_READBACK_RESULT_PATH={result_path}")


if __name__ == "__main__":
    main()
