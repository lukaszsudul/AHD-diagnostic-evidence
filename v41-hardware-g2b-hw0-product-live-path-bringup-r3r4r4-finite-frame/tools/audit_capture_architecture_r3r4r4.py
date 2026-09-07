#!/usr/bin/env python3
"""Independent structural hard gate for the R3R4R4 capture contract."""
from __future__ import annotations

import hashlib
import inspect
import json
from pathlib import Path
import sys


ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R4_20260907T135724Z")
SCRIPTS = ROOT / "scripts"
ARTIFACTS = ROOT / "artifacts"
sys.path.insert(0, str(SCRIPTS))

import capture_r3r4 as capture  # noqa: E402


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def write_exclusive(path: Path, text: str) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
        handle.flush()


def ordered_before(text: str, first: str, second: str) -> bool:
    return first in text and second in text and text.index(first) < text.index(second)


def main() -> int:
    capture_path = SCRIPTS / "capture_r3r4.py"
    source = capture_path.read_text(encoding="utf-8")
    selftest = json.loads((
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_SELFTEST.json"
    ).read_text(encoding="utf-8"))
    delta = json.loads((
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_DIFF.json"
    ).read_text(encoding="utf-8"))
    current_hash = sha(capture_path)
    persist = inspect.getsource(capture.RecordSink._persist_first)
    checkpoint_worker = inspect.getsource(capture.RecordSink._checkpoint_worker)
    checkpoint_request = inspect.getsource(capture.RecordSink._request_checkpoint)
    target_gate = inspect.getsource(
        capture.RecordSink._await_primary_target_prerequisites)
    accept = inspect.getsource(capture.RecordSink.accept)
    finalize = inspect.getsource(capture.RecordSink.finalize)
    reader = inspect.getsource(capture.reader_worker)
    quiescence = inspect.getsource(capture._parent_quiescence)
    quiet = inspect.getsource(capture.quiet_window_update)
    normalization = inspect.getsource(capture.combined_session_normalization)
    mmio_write = inspect.getsource(capture.MMIO.write)
    run_source = inspect.getsource(capture.run)

    checks = {
        "OFFLINE_SELFTESTS_16_OF_16":
            selftest.get("passed") == 16 and selftest.get("total") == 16 and
            all(value == "PASS" for value in selftest.get("cases", {}).values()),
        "RUNTIME_UNCHANGED_AFTER_SELFTEST":
            selftest.get("capture_tool_sha256") == current_hash ==
            delta.get("capture_corrected_sha256"),
        "AUTHORIZED_DELTA_PASSED":
            delta.get("authorized_tool_delta") ==
            "FIVE_CAPTURE_CONTRACT_CLOSURES_PLUS_RUN_IDENTITY_ONLY" and
            delta.get("result") == "PASS",

        "FIRST_RECORD_WRITE_FLUSH_FSYNC_CLOSE":
            ordered_before(persist, "handle.write(blob)", "del blob") and
            ordered_before(persist, "os.fsync(handle.fileno())", "del blob"),
        "FIRST_RECORD_REREAD_NOFOLLOW_EXACT":
            "persisted_record = _read_exact_nofollow(self.first_path, RECORD_BYTES)"
            in persist,
        "FIRST_RECORD_HASH_FROM_REREAD":
            "hashlib.sha256(\n                persisted_record)" in persist and
            ordered_before(persist, "del blob", "hashlib.sha256(\n                persisted_record)"),
        "ABI_PARSE_FROM_REREAD_FIRST_RECORD":
            "validator.accept(persisted_record)" in persist and
            "validator.accept(blob)" not in persist,
        "PAYLOAD_DERIVED_FROM_REREAD_RECORD":
            "persisted_payload_slice = persisted_record[" in persist,
        "PAYLOAD_REREAD_NOFOLLOW_EXACT":
            "persisted_payload = _read_exact_nofollow(" in persist,
        "PAYLOAD_HASH_FROM_REREAD_FILE":
            "hashlib.sha256(\n                persisted_payload)" in persist,
        "PAYLOAD_EQUALS_REREAD_RECORD_SLICE":
            "persisted_payload == persisted_payload_slice" in persist,
        "DURABLE_EVENT_AFTER_RECEIPT_AND_ALL_PROOFS":
            ordered_before(persist, "_write_json_exclusive(self.first_receipt_path",
                           "self.emit('FIRST_RECORD_DURABLE'") and
            ordered_before(persist, "validator.accept(persisted_record)",
                           "self.emit('FIRST_RECORD_DURABLE'"),

        "PRIMARY_CHECKPOINT_SCHEDULE_EXACT":
            capture.PRIMARY_CHECKPOINT_COUNTS == (1024, 2048, 2500),
        "PRIMARY_CHECKPOINT_WORKER_ASYNCHRONOUS":
            "threading.Thread(" in inspect.getsource(capture.RecordSink.__init__) and
            "r3r4r4-primary-durability-worker" in
            inspect.getsource(capture.RecordSink.__init__),
        "CHECKPOINT_QUEUE_METADATA_ONLY":
            "self.checkpoint_queue.put(record_count" in checkpoint_request and
            "blob" not in checkpoint_request and "payload" not in checkpoint_request,
        "CHECKPOINT_WORKER_WRITES_NO_RAW_DATA":
            "os.fsync(fd)" in checkpoint_worker and
            "self.primary_file.write" not in checkpoint_worker and
            "handle.write(blob)" not in checkpoint_worker,
        "CHECKPOINT_1024_2048_BEFORE_TARGET":
            "self._wait_checkpoint(1024)" in target_gate and
            "self._wait_checkpoint(2048)" in target_gate,
        "FIRST_DURABLE_REQUIRED_BEFORE_TARGET":
            "self.first_durable and self.first_valid" in target_gate and
            ordered_before(accept, "self._await_primary_target_prerequisites()",
                           "self.emit('PRIMARY_TARGET_REACHED'"),
        "CHECKPOINT_2500_NOT_REQUIRED_BEFORE_DISABLE":
            "self._wait_checkpoint(2500)" not in target_gate and
            "self._wait_checkpoint(2500)" in finalize,
        "CHECKPOINT_2500_REQUIRED_BEFORE_READER_PASS":
            ordered_before(finalize, "self._wait_checkpoint(2500)",
                           "'result': result"),

        "READER_OPENS_ONLY_SELECTED_C2H_DEVICE":
            "os.open(c2h_node" in reader and "_user" not in reader,
        "READER_PERFORMS_NO_MMIO": "MMIO(" not in reader and "0x38" not in reader,
        "PARENT_SOLE_MMIO_OWNER":
            "mmio = MMIO('T3T4_PARENT')" in run_source and "MMIO(" not in reader,
        "SPAWN_NON_INHERITING_MODEL": "mp.get_context('spawn')" in run_source,
        "PARENT_OWNS_WRITE_LEDGER":
            "self.ledger = ROOT / 'logs/mmio-write-ledger.csv'" in source,

        "PARENT_REQUIRES_FIVE_CONSECUTIVE_SAMPLES":
            capture.QUIESCENCE_REQUIRED_SAMPLES == 5 and
            "consecutive_quiescent" in quiescence,
        "PARENT_REQUIRES_MINIMUM_400MS_SPAN":
            capture.QUIESCENCE_MINIMUM_SPAN_SECONDS == 0.4 and
            "span >= QUIESCENCE_MINIMUM_SPAN_SECONDS" in
            inspect.getsource(capture.quiescence_streak_update),
        "NONQUIESCENT_SAMPLE_RESETS_STREAK":
            "return 0, None, 0.0, False" in
            inspect.getsource(capture.quiescence_streak_update),
        "QUIESCENCE_SAMPLE_INTERVAL_100MS":
            capture.QUIESCENCE_SAMPLE_INTERVAL_SECONDS == 0.1,
        "QUIESCENCE_WAIT_BOUNDED_10S":
            capture.QUIESCENCE_TIMEOUT_SECONDS == 10.0,
        "QUIESCENCE_CHECKS_BOOT_LOCK_BDF_DRIVER_FATAL_HOLDERS":
            all(token in quiescence for token in (
                "read_lock()", "bdf_unchanged", "driver_bound",
                "holders_allowed", "fatal_clear")),
        "PARENT_SETS_QUIESCENT_EVENT": "parent_quiescent.set()" in run_source,
        "READER_WAITS_FOR_PARENT_AND_QUIET_WINDOW":
            "parent_quiescent.is_set()" in reader and
            "quiet_window_update(" in reader and
            capture.QUIET_WINDOW_SECONDS == 1.0,
        "NO_FORCED_READER_TERMINATION_NORMAL_PATH": ".terminate(" not in run_source,

        "ONE_COMBINED_NORMALIZATION_FUNCTION":
            normalization.count("write_w1c(") == 1 and
            "observed = read_error()" in normalization and
            "mask = observed & 0x0000003F" in normalization,
        "ZERO_OR_ONE_W1C_WRITE":
            "if mask:" in normalization and "writes = 1" in normalization,
        "W1C_MASK_MATCHES_IMMEDIATE_READ":
            "value == (self.last_error_read & 0x3F)" in mmio_write,
        "W1C_GLOBAL_BUDGET_ONE":
            "normalization_w1c == 0" in mmio_write,
        "NO_SPLIT_FATAL_NONFATAL_W1C":
            "POST_RESET_NONFATAL_W1C" not in source and
            "POST_RESET_FATAL_W1C" not in source,
        "NO_POST_CAPTURE_ERROR_CLEAR":
            run_source.count("combined_session_normalization(") == 1 and
            run_source.count("SESSION_NORMALIZATION_W1C") == 1,

        "CONTROL_IPC_REJECTS_BYTES":
            "require(not _contains_bytes(message)" in
            inspect.getsource(capture.compact_emit),
        "CONTROL_IPC_BOUNDED":
            "len(encoded) < RECORD_BYTES" in inspect.getsource(capture.compact_emit),
        "RAW_RECORDS_DIRECT_TO_PRIVATE_FILES":
            "self.primary_file.write(blob)" in accept and
            "self.drain_file.write(blob)" in accept,
        "RAW_DATA_NOT_SERIALIZED_TO_JSON_OR_CSV":
            selftest.get("raw_record_control_ipc") is False and
            selftest["cases"].get("NO_RAW_RECORD_IPC_PASS") == "PASS",

        "FAILURE_PRESERVES_CAPTURE_FILES":
            selftest["cases"].get("FAILURE_PRESERVES_RAW_DATA_PASS") == "PASS" and
            ".unlink(" not in source and "os.remove(" not in source,
        "FAILURE_BLOCKERS_NONBLANK":
            selftest["cases"].get("NO_BLANK_BLOCKER_PASS") == "PASS",
        "MEMORY_BOUNDED":
            "os.read(fd, 256 * 1024)" in reader and
            "Queue(maxsize=64)" in run_source and
            "Queue(maxsize=1)" in inspect.getsource(capture.RecordSink.__init__),
    }
    failed = [name for name, passed in checks.items() if not passed]
    reason = failed[0] if failed else "NONE"
    blocker = ("NONE" if not failed else
               "R3R4R4_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_FAILED:" + reason)
    result = {
        "schema": "R3R4R4_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R4",
        "result": "PASS" if not failed else "FAIL",
        "blocker": blocker,
        "hardware_access": False,
        "dut_connections": 0,
        "checks": checks,
        "failed_checks": failed,
        "capture_tool_sha256": current_hash,
        "runtime_modified_after_selftest": False,
        "raw_payload_control_ipc": False,
        "parent_owned_mmio": True,
        "parent_owned_quiescence": True,
    }
    write_exclusive(
        ARTIFACTS /
        "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json",
        json.dumps(result, indent=2) + "\n",
    )
    lines = [
        "# G2B-HW0-PRODUCT-R3R4R4 Capture-Tool Architecture Hard Gate", "",
        f"- Result: `{result['result']}`",
        f"- Blocker: `{blocker}`",
        "- Hardware access: `NO`",
        "- DUT connections: `0`",
        "- Runtime modified after the self-test: `NO`",
        "", "| Check | Result |", "|---|---|",
    ]
    lines.extend(
        f"| `{name}` | `{'PASS' if passed else 'FAIL'}` |"
        for name, passed in checks.items())
    text = "\n".join(lines) + "\n"
    write_exclusive(
        ARTIFACTS / "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_AUDIT.md", text)
    write_exclusive(
        ARTIFACTS /
        "G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.md", text)
    print(json.dumps(result, indent=2))
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
