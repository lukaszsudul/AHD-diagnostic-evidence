from __future__ import annotations

import argparse
import io
import subprocess
import sys
from pathlib import Path


sys.dont_write_bytecode = True

from validate_evidence_package_r2 import (  # noqa: E402
    PACKAGE_DIRECTORY,
    PENDING_PUBLICATION,
    REQUIRED_TOP_LEVEL,
    validate_file_map,
)


DEFAULT_REPO_ROOT = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
PREFIX = f"{PACKAGE_DIRECTORY}/"


def git(repo: Path, *args: str) -> bytes:
    completed = subprocess.run(
        ["git", *args],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(
            f"GIT_COMMAND_FAILED:returncode={completed.returncode}:args={args!r}:stderr={stderr}"
        )
    return completed.stdout


def decode_z_paths(data: bytes, label: str) -> list[str]:
    try:
        values = data.decode("utf-8").split("\0")
    except UnicodeDecodeError as exc:
        raise RuntimeError(f"{label}_NOT_UTF8:{exc}") from exc
    return [value for value in values if value]


def indexed_modes(repo: Path) -> dict[str, tuple[str, str, str]]:
    records = git(repo, "ls-files", "--stage", "-z", "--", PREFIX).split(b"\0")
    result: dict[str, tuple[str, str, str]] = {}
    for record in records:
        if not record:
            continue
        try:
            metadata, path_bytes = record.split(b"\t", 1)
            mode, object_id, stage = metadata.decode("ascii").split()
            path = path_bytes.decode("utf-8")
        except (ValueError, UnicodeDecodeError) as exc:
            raise RuntimeError(f"MALFORMED_INDEX_RECORD:{record!r}") from exc
        if path in result:
            raise RuntimeError(f"UNMERGED_OR_DUPLICATE_INDEX_PATH:{path}")
        result[path] = (mode, object_id, stage)
    return result


def index_blobs(repo: Path, path_to_object_id: dict[str, str]) -> dict[str, bytes]:
    unique_object_ids = list(dict.fromkeys(path_to_object_id.values()))
    for object_id in unique_object_ids:
        if len(object_id) not in {40, 64} or any(
            character not in "0123456789abcdefABCDEF" for character in object_id
        ):
            raise RuntimeError(f"INVALID_INDEX_OBJECT_ID:{object_id!r}")

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
        raise RuntimeError(
            f"GIT_CAT_FILE_BATCH_FAILED:returncode={completed.returncode}:stderr={stderr}"
        )

    stream = io.BytesIO(completed.stdout)
    by_object_id: dict[str, bytes] = {}
    for expected_object_id in unique_object_ids:
        header = stream.readline()
        if not header.endswith(b"\n"):
            raise RuntimeError(
                f"TRUNCATED_CAT_FILE_BATCH_HEADER:{expected_object_id}:{header!r}"
            )
        fields = header[:-1].split()
        if len(fields) == 2 and fields[1] == b"missing":
            raise RuntimeError(f"MISSING_INDEX_BLOB:{expected_object_id}")
        if len(fields) != 3:
            raise RuntimeError(
                f"MALFORMED_CAT_FILE_BATCH_HEADER:{expected_object_id}:{header!r}"
            )
        actual_object_id_bytes, object_type, size_bytes = fields
        try:
            actual_object_id = actual_object_id_bytes.decode("ascii")
            size = int(size_bytes.decode("ascii"))
        except (UnicodeDecodeError, ValueError) as exc:
            raise RuntimeError(
                f"MALFORMED_CAT_FILE_BATCH_HEADER:{expected_object_id}:{header!r}"
            ) from exc
        if actual_object_id.casefold() != expected_object_id.casefold():
            raise RuntimeError(
                "CAT_FILE_BATCH_OBJECT_ID_MISMATCH:"
                f"expected={expected_object_id}:actual={actual_object_id}"
            )
        if object_type != b"blob":
            raise RuntimeError(
                f"CAT_FILE_BATCH_NON_BLOB:{expected_object_id}:{object_type!r}"
            )
        if size < 0:
            raise RuntimeError(f"CAT_FILE_BATCH_NEGATIVE_SIZE:{expected_object_id}:{size}")
        data = stream.read(size)
        if len(data) != size:
            raise RuntimeError(
                f"TRUNCATED_CAT_FILE_BATCH_BLOB:{expected_object_id}:"
                f"expected={size}:actual={len(data)}"
            )
        delimiter = stream.read(1)
        if delimiter != b"\n":
            raise RuntimeError(
                f"CAT_FILE_BATCH_DELIMITER_MISMATCH:{expected_object_id}:{delimiter!r}"
            )
        by_object_id[expected_object_id.casefold()] = data

    trailing = stream.read()
    if trailing:
        raise RuntimeError(f"UNEXPECTED_CAT_FILE_BATCH_TRAILING_BYTES:{len(trailing)}")

    return {
        path: by_object_id[object_id.casefold()]
        for path, object_id in path_to_object_id.items()
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate the exact R2 package as stored in the Git index."
    )
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    parser.add_argument(
        "--full-index",
        action="store_true",
        help=(
            "Validate every indexed R2 package file while still requiring all staged "
            "changes to remain under the authorized R2 prefix."
        ),
    )
    parser.add_argument("--expected-publication", choices=(PENDING_PUBLICATION, "PASS"))
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo = args.repo_root.resolve()
    failures: list[str] = []
    try:
        inside = git(repo, "rev-parse", "--is-inside-work-tree").decode("ascii").strip()
        if inside != "true":
            failures.append("REPO_ROOT_NOT_GIT_WORKTREE")

        changed = decode_z_paths(
            git(repo, "diff", "--cached", "--name-only", "-z"),
            "STAGED_PATHS",
        )
        if not changed:
            failures.append("NO_STAGED_CHANGES")
        outside = sorted(name for name in changed if not name.startswith(PREFIX))
        if outside:
            failures.append(f"STAGED_OUTSIDE_AUTHORIZED_DIRECTORY:{outside}")

        modes = indexed_modes(repo)
        for path, (mode, _object_id, stage) in modes.items():
            if stage != "0":
                failures.append(f"NONZERO_INDEX_STAGE:{path}:{stage}")
            if mode not in {"100644", "100755"}:
                failures.append(f"NONREGULAR_INDEX_MODE:{path}:{mode}")

        if args.full_index:
            selected = sorted(modes)
        else:
            selected = sorted(name for name in changed if name.startswith(PREFIX))

        selected_object_ids: dict[str, str] = {}
        for path in selected:
            if not path.startswith(PREFIX):
                continue
            relative = path[len(PREFIX) :]
            if not relative:
                failures.append("EMPTY_PACKAGE_RELATIVE_PATH")
                continue
            if path not in modes:
                failures.append(f"STAGED_PATH_HAS_NO_INDEX_BLOB:{path}")
                continue
            selected_object_ids[path] = modes[path][1]

        try:
            indexed_bytes = index_blobs(repo, selected_object_ids)
        except RuntimeError as exc:
            failures.append(f"INDEX_BLOB_BATCH_READ_FAILED:{exc}")
            indexed_bytes = {}
        package_files = {
            path[len(PREFIX) :]: data for path, data in indexed_bytes.items()
        }

        failures.extend(validate_file_map(package_files, args.expected_publication))

        if not args.full_index:
            indexed_package = set(modes)
            selected_set = set(selected)
            if selected_set != indexed_package:
                missing = sorted(indexed_package - selected_set)
                extra = sorted(selected_set - indexed_package)
                failures.append(
                    f"STAGED_PACKAGE_NOT_COMPLETE_USE_FULL_INDEX_FOR_INCREMENTAL_COMMIT:"
                    f"missing={missing}:extra={extra}"
                )
    except (OSError, RuntimeError, UnicodeDecodeError) as exc:
        failures.append(str(exc))

    if failures:
        print("R2_STAGED_VALIDATION=FAIL")
        for failure in failures:
            print(f"R2_STAGED_FAILURE={failure}")
        raise SystemExit(1)

    print("R2_STAGED_VALIDATION=PASS")
    print(f"R2_STAGED_CHANGED_FILES={len(changed)}")
    print(f"R2_INDEXED_PACKAGE_FILES={len(package_files)}")
    print(f"R2_REQUIRED_TOP_LEVEL_FILES={len(REQUIRED_TOP_LEVEL)}")
    print("R2_STAGED_OUTSIDE_AUTHORIZED_DIRECTORY=0")
    print("R2_STAGED_MANIFEST_SELF_EXCLUDED=PASS")
    print("R2_STAGED_HASH_MISMATCHES=0")
    print("R2_STAGED_GENERATED_TOP_LEVEL_LINE_ENDINGS=LF")
    print("R2_STAGED_NESTED_EXECUTION_EVIDENCE_BYTES=PRESERVED")
    print("R2_STAGED_SENSITIVE_PATHS=0")


if __name__ == "__main__":
    main()
