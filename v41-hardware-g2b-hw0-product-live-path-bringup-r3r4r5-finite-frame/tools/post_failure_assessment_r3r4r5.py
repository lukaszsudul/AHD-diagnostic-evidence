"""Post-failure, no-clear R3R4R5 status/counter and persisted-record assessment."""
import hashlib
import json
import pathlib
import sys
import time

from abi_v1 import AbiContract, StreamValidator
from capture_r3r4 import MMIO, RECORD_BYTES, read_lock, quiescent


P = pathlib.Path
TASK = "G2B-HW0-PRODUCT-R3R4R5"
ROOT = P("/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r5/20260907T151342Z")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def delta32(after, before, key):
    return (int(after[key]) - int(before[key])) & 0xFFFFFFFF


result = {"task": TASK, "result": "BLOCKED", "utc_ns": time.time_ns(),
          "post_capture_error_cleared": False, "statistics_cleared": False}
mmio = None
try:
    read_lock()
    capture = json.loads((ROOT / "logs/T3T4-result.json").read_text())
    require(capture.get("result") == "FAIL", "CAPTURE_RESULT_NOT_FAIL")
    require(capture.get("blocker") ==
            "R3R4R5_FIRST_RECORD_ABI_VALIDATION_FAILED:DISCONTINUITY flag is set;MALFORMED_PRECEDING flag is set",
            "CAPTURE_FIRST_BLOCKER_CHANGED")

    mmio = MMIO("POST_FAILURE_PARENT")
    control = mmio.read(0x380C)
    status = mmio.read(0x3810)
    error_status = mmio.read(0x383C)
    last_error_cause = mmio.read(0x3840)
    reset_epoch = mmio.read(0x3838)
    require(quiescent(control, status), "POST_FAILURE_HARDWARE_NOT_QUIESCENT")
    final_snapshot = mmio.snapshot("POST_FAILURE_FINAL_NO_CLEAR")
    final_control = mmio.read(0x380C)
    final_status = mmio.read(0x3810)
    final_error_status = mmio.read(0x383C)
    final_last_error_cause = mmio.read(0x3840)
    require(quiescent(final_control, final_status),
            "POST_FAILURE_FINAL_HARDWARE_NOT_QUIESCENT")
    mmio.close()
    mmio = None

    private = ROOT / "private"
    primary_path = private / "T3T4-primary-records.bin"
    drain_path = private / "T3T4-drain-records.bin"
    trailing_path = private / "T3T4-incomplete-trailing.bin"
    first_path = private / "T3T4-first-record.bin"
    payload_path = private / "T3T4-first-payload.bin"
    require(primary_path.is_file() and drain_path.is_file() and
            trailing_path.is_file() and first_path.is_file(),
            "PERSISTED_FAILURE_FILES_MISSING")
    primary = primary_path.read_bytes()
    drain = drain_path.read_bytes()
    trailing = trailing_path.read_bytes()
    first = first_path.read_bytes()
    require(len(primary) % RECORD_BYTES == 0 and len(drain) % RECORD_BYTES == 0,
            "COMPLETE_CAPTURE_FILE_GEOMETRY_INVALID")
    require(len(first) == RECORD_BYTES and first == primary[:RECORD_BYTES],
            "FIRST_RECORD_PERSISTENCE_MISMATCH")

    contract = AbiContract.load(ROOT / "scripts/V41_C2H_TRANSPORT_ABI_V1.json")
    validator = StreamValidator(contract, armed_epoch=reset_epoch)
    records = [primary[i:i + RECORD_BYTES]
               for i in range(0, len(primary), RECORD_BYTES)]
    records.extend(drain[i:i + RECORD_BYTES]
                   for i in range(0, len(drain), RECORD_BYTES))
    assessments = [validator.accept(blob) for blob in records]
    malformed = sum(not item.structurally_valid for item in assessments)
    padding_errors = sum(
        sum("padding byte" in error for error in item.errors)
        for item in assessments)
    session_fatal = sum(item.session_fatal for item in assessments)
    reason_rows = [
        {"index": item.index,
         "reasons": list(item.discontinuity_reasons),
         "errors": list(item.errors),
         "session_fatal": item.session_fatal}
        for item in assessments
        if item.discontinuity_reasons or item.errors or item.session_fatal
    ]
    sequence_gap_records = sum(
        any("global sequence" in reason or "attempt sequence" in reason or
            "source progression" in reason for reason in item.discontinuity_reasons)
        for item in assessments)
    discontinuity_flag_records = sum(
        item.record is not None and
        bool(item.record.flags & contract.flags["DISCONTINUITY"])
        for item in assessments)
    malformed_preceding_flag_records = sum(
        item.record is not None and
        bool(item.record.flags & contract.flags["MALFORMED_PRECEDING"])
        for item in assessments)
    overflow_flag_records = sum(
        item.record is not None and
        bool(item.record.flags & contract.flags["OVERFLOW_OCCURRED"])
        for item in assessments)
    first_assessment = assessments[0].as_dict() if assessments else None

    before = capture["snapshot_before"]
    after = final_snapshot
    beats = ((((int(after["0x3830"]) << 32) | int(after["0x382C"])) -
              ((int(before["0x3830"]) << 32) | int(before["0x382C"]))) &
             0xFFFFFFFFFFFFFFFF)
    counters = {
        "records_attempted_delta": delta32(after, before, "0x3814"),
        "records_committed_delta": delta32(after, before, "0x3818"),
        "records_streamed_delta": delta32(after, before, "0x381C"),
        "records_dropped_delta": delta32(after, before, "0x3820"),
        "overflow_count_delta": delta32(after, before, "0x3824"),
        "discontinuity_delta": delta32(after, before, "0x3828"),
        "beats_streamed_delta": beats,
        "records_abandoned_delta": delta32(after, before, "0x3850"),
        "reset_events_delta": delta32(after, before, "0x3854"),
        "last_global_observed": int(after["0x3834"]),
        "last_channel_observed": int(after["0x3858"]),
        "host_complete_records": len(records),
        "expected_host_complete_beats": len(records) * 512,
        "trailing_bytes": len(trailing),
    }

    payload_slice = first[contract.payload_first:contract.padding_first]
    result.update(
        result="PASS", blocker="NONE", capture_result="FAIL",
        capture_first_blocker=capture["blocker"],
        pre_snapshot=before, final_snapshot=final_snapshot,
        pre_snapshot_generation=before["generation"],
        final_snapshot_generation=after["generation"],
        control_before_snapshot=control, status_before_snapshot=status,
        error_status_before_snapshot=error_status,
        last_error_cause_before_snapshot=last_error_cause,
        final_control=final_control, final_status=final_status,
        final_error_status=final_error_status,
        final_last_error_cause=final_last_error_cause,
        reset_epoch=reset_epoch, hardware_quiescent=True,
        primary_records=len(primary) // RECORD_BYTES,
        primary_bytes=len(primary), drain_records=len(drain) // RECORD_BYTES,
        drain_bytes=len(drain), incomplete_trailing_bytes=len(trailing),
        primary_sha256=hashlib.sha256(primary).hexdigest().upper(),
        drain_sha256=hashlib.sha256(drain).hexdigest().upper(),
        trailing_sha256=hashlib.sha256(trailing).hexdigest().upper(),
        combined_complete_sha256=hashlib.sha256(primary + drain).hexdigest().upper(),
        first_record_reread_bytes=len(first),
        first_record_sha256=hashlib.sha256(first).hexdigest().upper(),
        first_record_equals_primary_offset_zero=True,
        payload_file_exists=payload_path.exists(),
        payload_slice_bytes=len(payload_slice),
        payload_slice_sha256=hashlib.sha256(payload_slice).hexdigest().upper(),
        record_assessment_source="REREAD_PERSISTED_FILES",
        complete_record_assessments=len(assessments), malformed_records=malformed,
        padding_errors=padding_errors, session_fatal_records=session_fatal,
        sequence_gap_records=sequence_gap_records,
        discontinuity_flag_records=discontinuity_flag_records,
        malformed_preceding_flag_records=malformed_preceding_flag_records,
        overflow_flag_records=overflow_flag_records,
        assessment_issues=reason_rows[:32], first_record_assessment=first_assessment,
        counters=counters, counter_reconciliation="FAIL_NOT_2500",
        frame_reconstruction="NOT_REACHED",
    )
except BaseException as exc:
    result["blocker"] = str(exc)
finally:
    if mmio is not None:
        mmio.close()
    (ROOT / "logs/post-failure-assessment.json").write_text(
        json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2), flush=True)

sys.exit(0 if result["result"] == "PASS" else 1)
