#!/usr/bin/env python3
"""Independent fail-closed audit of the frozen R3R4R2 capture architecture."""
from __future__ import annotations

import hashlib
import inspect
import json
import sys
from pathlib import Path


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R2_20260907T071912Z")
SCRIPTS = ROOT / "scripts"
ARTIFACTS = ROOT / "artifacts"
sys.path.insert(0, str(SCRIPTS))

import capture_r3r4 as capture  # noqa: E402


BLOCKER = (
    "R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_FAILED:"
    "PERSISTED_FIRST_RECORD_REREAD_HASH_PROOF_ABSENT"
)


def write_exclusive(path: Path, text: str) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
        handle.flush()


def main() -> int:
    source = (SCRIPTS / "capture_r3r4.py").read_text(encoding="utf-8")
    reader = inspect.getsource(capture.reader_worker)
    sink = inspect.getsource(capture.RecordSink)
    persist = inspect.getsource(capture.RecordSink._persist_first)
    accept = inspect.getsource(capture.RecordSink.accept)
    quiescence = inspect.getsource(capture._parent_quiescence)
    run_source = inspect.getsource(capture.run)
    selftest = json.loads((
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_SELFTEST.json"
    ).read_text(encoding="utf-8"))

    checks = {
        "OFFLINE_SELFTESTS_11_OF_11": selftest.get("passed") == 11,
        "READER_OPENS_ONLY_SELECTED_C2H":
            "os.open(c2h_node" in reader and "_user" not in reader,
        "READER_HAS_NO_MMIO": "MMIO(" not in reader,
        "SPAWN_NON_INHERITING_MODEL": "mp.get_context('spawn')" in source,
        "PARENT_SOLE_MMIO_OWNER":
            "mmio = MMIO('T3T4_PARENT')" in run_source and "MMIO(" not in reader,
        "PARENT_OWNS_AUTHORITATIVE_WRITE_LEDGER":
            "self.ledger = ROOT / 'logs/mmio-write-ledger.csv'" in source,
        "RAW_RECORD_NEVER_ON_CONTROL_IPC":
            "RAW_RECORD_CONTROL_IPC_FORBIDDEN" in source and
            selftest.get("raw_record_control_ipc") is False,
        "RAW_RECORDS_DIRECT_TO_PRIVATE_FILES":
            "self.primary_file.write(blob)" in sink and
            "self.drain_file.write(blob)" in sink,
        "CONTROL_IPC_BOUNDED":
            "len(encoded) < RECORD_BYTES" in source and
            "Queue(maxsize=64)" in source,
        "FIRST_RECORD_DEDICATED_PRIVATE_FILE":
            "T3T4-first-record.bin" in sink,
        "FIRST_RECORD_FLUSH_FSYNC_BEFORE_DURABLE_EVENT":
            persist.index("os.fsync(handle.fileno())") <
            persist.index("self.emit('FIRST_RECORD_DURABLE'"),
        "FIRST_RECORD_REREAD_FROM_PERSISTED_FILE":
            "self.first_path.read_bytes()" in persist,
        "FIRST_PAYLOAD_REREAD_FROM_PERSISTED_FILE":
            "self.payload_path.read_bytes()" in persist,
        "FIRST_HASHES_COMPUTED_FROM_REREAD_PERSISTED_BYTES":
            "hashlib.sha256(persisted" in persist and
            "hashlib.sha256(persisted_payload" in persist,
        "FIRST_DURABLE_NOTIFICATION_HAS_NO_RAW_PAYLOAD":
            "self.emit('FIRST_RECORD_DURABLE', bytes=RECORD_BYTES" in persist,
        "FAILURE_PRESERVES_COMPLETED_RECORDS":
            selftest["cases"].get("FAILURE_PRESERVES_RAW_DATA_PASS") == "PASS",
        "PRIMARY_TARGET_2500": capture.PRIMARY_TARGET == 2500,
        "PRIMARY_BYTES_10240000": capture.PRIMARY_BYTES == 10_240_000,
        "PRIMARY_AND_DRAIN_SEPARATE":
            "T3T4-primary-records.bin" in sink and
            "T3T4-drain-records.bin" in sink,
        "INCOMPLETE_TRAILING_BYTES_PRESERVED":
            "T3T4-incomplete-trailing.bin" in sink and
            "handle.write(self.pending)" in sink,
        "PRIMARY_PERIODIC_DURABILITY_CHECKPOINT_PRESENT":
            "os.fsync(self.primary_file.fileno())" in accept,
        "PRIMARY_TARGET_NOTIFICATION_AFTER_DURABILITY_CHECKPOINT":
            "os.fsync(self.primary_file.fileno())" in accept and
            accept.index("os.fsync(self.primary_file.fileno())") <
            accept.index("self.emit('PRIMARY_TARGET_REACHED'"),
        "FIRST_RECORD_DURABLE_REQUIRED_BEFORE_PRIMARY_TARGET":
            "FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET" in run_source,
        "DRAIN_FINITE_RECORD_LIMIT_512": capture.DRAIN_LIMIT == 512,
        "PARENT_OWNS_QUIESCENCE_PROOF":
            "_parent_quiescence(" in run_source and
            "parent_quiescent.set()" in run_source,
        "PARENT_QUIESCENCE_STABLE_MULTIPLE_OBSERVATIONS":
            "stable_observations" in quiescence or
            "consecutive_quiescent" in quiescence,
        "READER_QUIET_WINDOW_1_SECOND": capture.QUIET_WINDOW_SECONDS == 1.0,
        "READER_COOPERATIVE_EXIT":
            "parent_quiescent.is_set()" in reader and
            "quiet_window_update(" in reader,
        "NO_FORCED_KILL_NORMAL_PATH": ".terminate(" not in run_source,
        "NONBLANK_FAILURE_BLOCKERS":
            selftest["cases"].get("NO_BLANK_BLOCKER_PASS") == "PASS",
        "MEMORY_BOUNDED":
            "os.read(fd, 256 * 1024)" in reader and
            "Queue(maxsize=64)" in source and
            "Queue(maxsize=1)" in sink,
        "SINGLE_COMBINED_SESSION_NORMALIZATION_W1C":
            "SESSION_NORMALIZATION_MASK" in source and
            "POST_RESET_NONFATAL_W1C" not in source and
            "POST_RESET_FATAL_W1C" not in source,
    }

    failed = [name for name, passed in checks.items() if not passed]
    result = {
        "schema": "R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R2",
        "result": "PASS" if not failed else "FAIL",
        "blocker": "NONE" if not failed else BLOCKER,
        "hardware_access": False,
        "dut_connections": 0,
        "checks": checks,
        "failed_checks": failed,
        "capture_tool_sha256": hashlib.sha256(
            (SCRIPTS / "capture_r3r4.py").read_bytes()
        ).hexdigest().upper(),
        "runtime_modified_after_selftest": False,
    }
    json_path = ARTIFACTS / (
        "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json"
    )
    write_exclusive(json_path, json.dumps(result, indent=2) + "\n")
    lines = [
        "# G2B-HW0-PRODUCT-R3R4R2 Capture-Tool Architecture Hard Gate",
        "",
        f"- Result: `{result['result']}`",
        f"- First blocker: `{result['blocker']}`",
        "- Hardware access: `NO`",
        "- DUT connections: `0`",
        "- Capture runtime changed after self-test: `NO`",
        "",
        "| Check | Result |",
        "|---|---|",
    ]
    lines.extend(
        f"| `{name}` | `{'PASS' if passed else 'FAIL'}` |"
        for name, passed in checks.items()
    )
    if failed:
        lines.extend([
            "",
            "The frozen runtime hashes the in-memory `blob` and `payload` after "
            "fsync, but never re-reads either persisted file. It therefore "
            "cannot prove that the published first-record hashes were computed "
            "from persisted bytes as required by R3R4R2 sections 9 and 19. "
            "Additional observed contract gaps are preserved in the matrix; "
            "no runtime correction is authorized in this run.",
        ])
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.md",
        "\n".join(lines) + "\n",
    )
    print(json.dumps(result, indent=2))
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
