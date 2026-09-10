#!/usr/bin/env python3
"""Device-free tests for the DIAG1-R1 metadata and evidence helpers."""

from __future__ import annotations

import csv
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent


def load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, HERE / filename)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


aggregate = load("aggregate_nvp_session_metadata", "aggregate_nvp_session_metadata.py")
evidence = load(
    "assemble_publish_nvp_diag1_r1_evidence",
    "assemble_publish_nvp_diag1_r1_evidence.py",
)
runtime_extract = load(
    "extract_nvp_runtime_evidence", "extract_nvp_runtime_evidence.py"
)


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    path.write_text(stream.getvalue(), encoding="utf-8", newline="")


def history_row(session: int) -> dict[str, object]:
    round_number = (session - 1) // 4 + 1
    channel = aggregate.ORDERS[round_number - 1][(session - 1) % 4]
    frame_hash = f"{session:064X}"
    return {
        "SessionID": session,
        "SnapshotGeneration": session,
        "SnapshotCoherenceRetries": 0,
        "Round": round_number,
        "RoundPosition": (session - 1) % 4,
        "Channel": channel,
        "RouteRequested": f"0x{channel - 1:02X}",
        "RouteReadback": f"0x{channel - 1:02X}",
        "AssignedBGDCOL": "RED",
        "BGDCOLCode": "0x6",
        "BGDCOL78": "0x66",
        "BGDCOL79": "0x66",
        "RawNOVID": "0x0F",
        "RawAGCLock": "0x00",
        "RawComparatorLock": "0x00",
        "RawHLock": "0x00",
        "RawChannelStatus": "0x00",
        "Classification": "NO_VIDEO_STABLE",
        "ClassificationCode": 2,
        "StableSamples": 5,
        "TotalStatusSamples": 5,
        "I2CTransactionCount": session * 10,
        "I2CNackCountLow8": 0,
        "I2CTimeoutCountLow8": 0,
        "I2CBusRecoveryCountLow8": 0,
        "I2CNackOverflow": False,
        "I2CTimeoutOverflow": False,
        "I2CBusRecoveryOverflow": False,
        "CaptureResult": "PASS",
        "CaptureBlocker": "",
        "PrimaryBytes": 10_240_000,
        "FrameReconstruction": "PASS",
        "FrameSequence": session,
        "FrameSHA256": frame_hash,
        "PNG_SHA256": f"{session + 16:064X}",
        "PixelClassification": "UNIFORM_BGDCOL_RED",
        "DominantUYVY": "0x80808080",
        "DominantFraction": "1.0",
        "AssignedColorPixelMatch": "PASS",
        "CleanupResult": "PASS",
    }


def test_aggregate_real_rows_without_fabricated_transactions(root: Path) -> None:
    logs = root / "logs"
    logs.mkdir(parents=True)
    rows = [history_row(session) for session in range(1, 17)]
    fields = list(rows[0])
    write_csv(logs / "session_status_history.csv", fields, rows)
    (logs / "session_status_history.jsonl").write_text(
        "".join(json.dumps(row, separators=(",", ":")) + "\n" for row in rows),
        encoding="utf-8", newline="\n",
    )
    write_csv(logs / "session_capture_history.csv", fields, rows)
    write_csv(logs / "session_pixel_history.csv", fields, rows)
    coherence = [{"ExpectedSession": session, "Attempt": 1, "Result": "PASS"}
                 for session in range(1, 17)]
    write_csv(logs / "snapshot_coherence.csv", list(coherence[0]), coherence)
    scan_rows = [{"session_id": row["SessionID"], "round": row["Round"],
                  "channel": row["Channel"]} for row in rows]
    write_csv(logs / "scan-results.csv", list(scan_rows[0]), scan_rows)

    documents, missing, summary = aggregate.aggregate_documents(
        root, logs, logs,
        {"status": None, "i2c": None, "write": None, "readback": None},
        allow_partial=True,
    )
    assert summary["session_count"] == 16
    assert summary["transaction_rows_synthesized"] == 0
    assert len(missing) == 4
    assert not any(name in documents for name in (
        aggregate.PREFIX + "STATUS_SAMPLES.csv",
        aggregate.PREFIX + "I2C_TRANSACTION_LOG.csv",
        aggregate.PREFIX + "NVP_WRITE_LEDGER.csv",
        aggregate.PREFIX + "NVP_READBACK_LEDGER.csv",
    ))
    assert len(documents) == 10

    string_rows = [{key: str(value) for key, value in row.items()} for row in rows]
    scan_result = {
        "original_baseline": {"route": 0, "bgcolor_78": 0x88, "bgcolor_79": 0x88},
        "final_state": {
            "route": 0, "bgcolor_78": 0x88, "bgcolor_79": 0x88,
            "i2c_transaction_count": 165, "i2c_nack_count": 0,
            "i2c_timeout_count": 0, "i2c_bus_recovery_count": 0,
        },
    }
    status_projection = runtime_extract.status_summaries(string_rows)
    i2c_projection = runtime_extract.i2c_intervals(string_rows, scan_result, {})
    write_projection, readback_projection = runtime_extract.write_ledgers(
        string_rows, scan_result
    )
    projection_specs = {
        aggregate.PREFIX + "STATUS_SAMPLES.csv":
            (runtime_extract.STATUS_FIELDS, status_projection),
        aggregate.PREFIX + "I2C_TRANSACTION_LOG.csv":
            (runtime_extract.I2C_FIELDS, i2c_projection),
        aggregate.PREFIX + "NVP_WRITE_LEDGER.csv":
            (runtime_extract.WRITE_FIELDS, write_projection),
        aggregate.PREFIX + "NVP_READBACK_LEDGER.csv":
            (runtime_extract.READBACK_FIELDS, readback_projection),
    }
    for filename, (projection_fields, projection_rows) in projection_specs.items():
        write_csv(logs / filename, projection_fields, projection_rows)
    documents, missing, summary = aggregate.aggregate_documents(
        root, logs, logs,
        {"status": None, "i2c": None, "write": None, "readback": None},
        allow_partial=False,
    )
    assert not missing
    assert len(documents) == 14
    assert len(summary["runtime_projections_copied"]) == 4
    assert summary["runtime_projections_copied"][
        aggregate.PREFIX + "I2C_TRANSACTION_LOG.csv"] == 17
    assert summary["runtime_projections_copied"][
        aggregate.PREFIX + "NVP_WRITE_LEDGER.csv"] == 27
    assert summary["runtime_projections_copied"][
        aggregate.PREFIX + "NVP_READBACK_LEDGER.csv"] == 107
    assert summary["transaction_rows_synthesized"] == 0


def minimal_required_entries() -> dict[str, bytes]:
    entries: dict[str, bytes] = {}
    for name in evidence.REQUIRED_FILES:
        if name in evidence.GENERATED_REQUIRED:
            continue
        suffix = Path(name).suffix.casefold()
        if suffix == ".json":
            entries[name] = b"{}\n"
        elif suffix == ".jsonl":
            entries[name] = b'{"SessionID":1}\n'
        elif suffix == ".csv":
            entries[name] = b"EvidenceStatus\nNOT_AVAILABLE\n"
        else:
            entries[name] = (f"# {name}\n\nTest evidence.\n").encode("utf-8")
    entries[evidence.INDEX_NAME] = evidence.build_index(entries)
    entries[evidence.MANIFEST_NAME] = evidence.build_manifest(entries)
    return entries


def test_manifest_excludes_itself_and_refuses_binary(root: Path) -> None:
    entries = minimal_required_entries()
    assert evidence.MANIFEST_NAME not in evidence.parse_manifest(
        entries[evidence.MANIFEST_NAME]
    )
    staging = root / "evidence-staging"
    package = staging / evidence.TARGET_DIRECTORY
    evidence.write_package(root, package, entries)
    receipt = evidence.verify_package(package)
    assert receipt["result"] == "PASS"
    assert receipt["files_including_manifest"] == len(evidence.REQUIRED_FILES)
    prohibited_names = (
        "source/raw-frame.bit",
        "source/checkpoint.dcp",
        "source/frame.png",
        "source/primary.bin",
    )
    for prohibited in prohibited_names:
        try:
            evidence.validate_relative_name(prohibited)
        except evidence.EvidenceError:
            pass
        else:
            raise AssertionError(f"prohibited path must be refused: {prohibited}")
    for relative, data in (
        ("source/nul.txt", b"public\x00binary\n"),
        ("source/secret.txt", b"access_" + b"token=" + b"github_pat-" + b"A" * 22),
    ):
        try:
            evidence.validate_public_bytes(relative, data)
        except evidence.EvidenceError:
            pass
        else:
            raise AssertionError(f"prohibited content must be refused: {relative}")


def test_commit_pinned_sparse_blob_readback(root: Path) -> None:
    entries = minimal_required_entries()
    staging = root / "evidence-staging"
    staging.mkdir(parents=True)
    package = staging / evidence.TARGET_DIRECTORY
    evidence.write_package(root, package, entries)
    repository = root / "repository"
    repository.mkdir()
    subprocess.run(["git", "init", "-b", "main", str(repository)], check=True,
                   capture_output=True)
    subprocess.run(["git", "-C", str(repository), "config", "user.name", "Evidence Test"],
                   check=True, capture_output=True)
    subprocess.run(["git", "-C", str(repository), "config", "user.email",
                    "evidence-test@example.invalid"], check=True, capture_output=True)
    evidence.copy_package_to_repo(package, repository / evidence.TARGET_DIRECTORY)
    subprocess.run(["git", "-C", str(repository), "add", "--",
                    evidence.TARGET_DIRECTORY], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(repository), "commit", "-m", "test evidence"],
                   check=True, capture_output=True)
    commit = subprocess.run(
        ["git", "-C", str(repository), "rev-parse", "HEAD"], check=True,
        capture_output=True, text=True,
    ).stdout.strip()
    scope = evidence.verify_commit_scope(repository, commit, package)
    assert scope["scope"] == evidence.TARGET_DIRECTORY
    assert scope["changed_files"] == len(entries)
    original_policy = evidence.remote_url_is_expected
    evidence.remote_url_is_expected = lambda _url: True
    try:
        receipt = evidence.commit_pinned_sparse_readback(
            str(repository), commit, package
        )
    finally:
        evidence.remote_url_is_expected = original_policy
    assert receipt["result"] == "PASS"
    assert receipt["commit"] == commit
    assert receipt["sparse_no_checkout_clone"] is True
    assert receipt["byte_for_byte_files_verified"] == len(entries)


def test_publication_requires_literal_confirmation(root: Path) -> None:
    receipt = root / "publication-receipt.json"
    try:
        evidence.publish(
            root / "nonexistent-package", root / "nonexistent-repository",
            receipt, "NOT_AUTHORIZED",
        )
    except evidence.EvidenceError as exc:
        assert str(exc) == "EXPLICIT_PUBLICATION_CONFIRMATION_REQUIRED"
    else:
        raise AssertionError("publication without the literal confirmation was accepted")
    assert not receipt.exists()


def main() -> int:
    short_temp_parent = HERE.parents[1]
    with tempfile.TemporaryDirectory(prefix="_eh1-", dir=short_temp_parent) as temp:
        root = Path(temp) / "task"
        root.mkdir()
        test_aggregate_real_rows_without_fabricated_transactions(root)
    with tempfile.TemporaryDirectory(prefix="_eh2-", dir=short_temp_parent) as temp:
        root = Path(temp) / "task"
        root.mkdir()
        test_manifest_excludes_itself_and_refuses_binary(root)
    with tempfile.TemporaryDirectory(prefix="_eh3-", dir=short_temp_parent) as temp:
        root = Path(temp) / "task"
        root.mkdir()
        test_commit_pinned_sparse_blob_readback(root)
    with tempfile.TemporaryDirectory(prefix="_eh4-", dir=short_temp_parent) as temp:
        root = Path(temp) / "task"
        root.mkdir()
        test_publication_requires_literal_confirmation(root)
    print(json.dumps({
        "result": "PASS",
        "tests": 4,
        "transaction_rows_synthesized": 0,
        "manifest_self_entry": "ABSENT",
        "prohibited_raw_binary_bit_dcp_image_credential": "REFUSED",
        "unauthorized_publication": "REFUSED",
        "commit_pinned_sparse_byte_readback": "PASS",
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
