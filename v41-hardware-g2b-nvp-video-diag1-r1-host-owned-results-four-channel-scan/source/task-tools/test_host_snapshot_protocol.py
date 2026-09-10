#!/usr/bin/env python3
"""Deterministic offline tests for the DIAG1-R1 host snapshot protocol."""

from __future__ import annotations

import csv
import importlib.util
import json
from pathlib import Path
import tempfile


MODULE_PATH = Path(__file__).with_name("controller_nvp_video_diag1.py")
SPEC = importlib.util.spec_from_file_location("diag1_r1_controller", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
controller = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(controller)

CAPTURE_MODULE_PATH = Path(__file__).with_name("controller_nvp_capture.py")
CAPTURE_SPEC = importlib.util.spec_from_file_location(
    "diag1_r1_capture_controller", CAPTURE_MODULE_PATH)
assert CAPTURE_SPEC is not None and CAPTURE_SPEC.loader is not None
capture_controller = importlib.util.module_from_spec(CAPTURE_SPEC)
CAPTURE_SPEC.loader.exec_module(capture_controller)


def snapshot_words(session: int = 1, generation: int = 1,
                   round_number: int = 1, channel: int = 1) -> list[int]:
    del generation
    classification = 2
    position = (session - 1) % 4
    colors = controller.COLOR_CODES_BY_ROUND[round_number - 1]
    color = colors[channel - 1]
    bg78 = (colors[1] << 4) | colors[0]
    bg79 = (colors[3] << 4) | colors[2]
    word0 = ((classification << 24) | (channel << 21) |
             (round_number << 18) | session)
    word1 = ((channel - 1) << 24) | ((channel - 1) << 16) | (color << 8) | 5
    word2 = 0x0A010101
    word3 = (0x02 << 24) | (bg78 << 16) | (bg79 << 8) | 5
    word4 = ((classification << 16) | (position << 6) |
             ((round_number - 1) << 3) | channel)
    return [word0, word1, word2, word3, word4, 123, 0, 0]


def attempt_reads(valid0: int, generation0: int, session0: int,
                  words: list[int], generation1: int, session1: int,
                  valid1: int,
                  firmware_session: int | None = None) -> list[tuple[int, int]]:
    values = [
        (controller.CURRENT_RESULT_VALID, valid0),
        (controller.CURRENT_RESULT_GENERATION, generation0),
        (controller.CURRENT_RESULT_SESSION_ID, session0),
    ]
    values.extend((controller.CURRENT_RESULT_WORD_0 + index * 4, value)
                  for index, value in enumerate(words))
    values.extend([
        (controller.CURRENT_RESULT_GENERATION, generation1),
        (controller.CURRENT_RESULT_SESSION_ID, session1),
        (controller.CURRENT_RESULT_VALID, valid1),
        (controller.SESSION,
         session1 if firmware_session is None else firmware_session),
    ])
    return values


class FakeMmio:
    def __init__(self, values: list[tuple[int, int]]) -> None:
        self.values = list(values)

    def read(self, offset: int, purpose: str) -> int:
        del purpose
        if not self.values:
            raise AssertionError("unexpected MMIO read")
        expected_offset, value = self.values.pop(0)
        if offset != expected_offset:
            raise AssertionError(
                f"MMIO order mismatch expected=0x{expected_offset:04X} "
                f"actual=0x{offset:04X}"
            )
        return value


class ResponseRecorder(controller.DiagnosticMmio):
    def __init__(self) -> None:
        self.fd = -1
        self.ledger = []
        self.writes: list[tuple[int, int, str]] = []

    def _write(self, offset: int, value: int, purpose: str) -> None:
        self.writes.append((offset, value, purpose))


def main() -> int:
    words = snapshot_words()
    attempt_rows: list[dict[str, object]] = []
    normal = FakeMmio(attempt_reads(1, 1, 1, words, 1, 1, 1))
    decoded, retries = controller.read_coherent_snapshot(
        normal, 1, attempt_rows=attempt_rows)
    assert retries == 0 and decoded["session_id"] == 1
    assert decoded["reserved_bits_zero"]
    assert not normal.values
    assert len(attempt_rows) == 1 and attempt_rows[0]["Result"] == "PASS"
    assert attempt_rows[0]["FirmwareCurrentSession"] == 1

    torn = attempt_reads(1, 1, 1, words, 2, 1, 1)
    invalid = attempt_reads(0, 1, 1, words, 1, 1, 1)
    third = attempt_reads(1, 1, 1, words, 1, 1, 1)
    attempt_rows = []
    decoded, retries = controller.read_coherent_snapshot(
        FakeMmio(torn + invalid + third), 1, attempt_rows=attempt_rows
    )
    assert retries == 2 and decoded["snapshot_generation"] == 1
    assert [row["Result"] for row in attempt_rows] == ["RETRY", "RETRY", "PASS"]
    assert "GENERATION_CHANGED" in str(attempt_rows[0]["FailureReasons"])

    live_mismatch = attempt_reads(1, 1, 1, words, 1, 1, 1,
                                  firmware_session=2)
    attempt_rows = []
    decoded, retries = controller.read_coherent_snapshot(
        FakeMmio(live_mismatch + third), 1, attempt_rows=attempt_rows)
    assert retries == 1 and decoded["firmware_current_session"] == 1
    assert "FIRMWARE_SESSION_MISMATCH" in str(
        attempt_rows[0]["FailureReasons"])

    upper_bits = attempt_reads(1, 0x00010001, 1, words,
                               0x00010001, 1, 1)
    attempt_rows = []
    decoded, retries = controller.read_coherent_snapshot(
        FakeMmio(upper_bits + third), 1, attempt_rows=attempt_rows)
    assert retries == 1 and decoded["snapshot_generation"] == 1
    assert attempt_rows[0]["MetadataUpperBitsZero"] is False
    assert "METADATA_UPPER_BITS_NONZERO" in str(
        attempt_rows[0]["FailureReasons"])

    exhausted = FakeMmio(torn + invalid + torn + invalid)
    attempt_rows = []
    try:
        controller.read_coherent_snapshot(
            exhausted, 1, attempt_rows=attempt_rows)
    except controller.ScanError:
        pass
    else:
        raise AssertionError("exhausted coherence retries were accepted")
    assert not exhausted.values
    assert len(attempt_rows) == 4
    assert attempt_rows[-1]["Attempt"] == 4
    assert attempt_rows[-1]["Retry"] == 3
    assert attempt_rows[-1]["Result"] == "FAIL"

    full_scan_rows: list[dict[str, object]] = []
    full_scan_sessions: set[int] = set()
    full_scan_pairs: set[tuple[int, int]] = set()
    full_scan_generations: list[int] = []
    for expected_session in range(1, 17):
        round_number = (expected_session - 1) // 4 + 1
        position = (expected_session - 1) % 4
        channel = controller.ORDERS[round_number - 1][position]
        scan_words = snapshot_words(expected_session, expected_session,
                                    round_number, channel)
        decoded, retries = controller.read_coherent_snapshot(
            FakeMmio(attempt_reads(
                1, expected_session, expected_session, scan_words,
                expected_session, expected_session, 1)), expected_session)
        assert retries == 0
        assert decoded["round"] == round_number
        assert decoded["channel"] == channel
        assert decoded["round_position"] == position
        assert decoded["route_requested"] == channel - 1
        assert decoded["route_readback"] == channel - 1
        assert decoded["bgcolor_code"] == (
            controller.COLOR_CODES_BY_ROUND[round_number - 1][channel - 1])
        full_scan_sessions.add(decoded["session_id"])
        full_scan_pairs.add((decoded["round"], decoded["channel"]))
        full_scan_generations.append(decoded["snapshot_generation"])
        history_row = {field: "" for field in controller.HOST_HISTORY_FIELDS}
        history_row.update({
            "SessionID": decoded["session_id"],
            "SnapshotGeneration": decoded["snapshot_generation"],
            "SnapshotCoherenceRetries": retries,
            "Round": decoded["round"], "RoundPosition": position,
            "Channel": decoded["channel"],
            "RouteRequested": decoded["route_requested"],
            "RouteReadback": decoded["route_readback"],
            "AssignedBGDCOL": controller.COLORS[decoded["bgcolor_code"]],
            "BGDCOLCode": decoded["bgcolor_code"],
            "Classification": controller.CLASSES[decoded["classification"]],
            "CaptureResult": "NOT_STARTED", "CleanupResult": "NOT_REACHED",
            "FrameSequence": expected_session,
            "FrameSHA256": f"{expected_session:064X}",
            "PNG_SHA256": f"{expected_session + 16:064X}",
            "PixelClassification": "UNIFORM_BGDCOL_RED",
        })
        full_scan_rows.append(history_row)
    assert full_scan_sessions == set(range(1, 17))
    assert len(full_scan_pairs) == 16
    assert full_scan_generations == list(range(1, 17))

    packed = list(words)
    packed[6] = 0x07030201
    packed[7] = 0xABCD1234
    fields = controller.decode_result_entry(packed)
    assert fields["i2c_nack_count_low8"] == 1
    assert fields["i2c_timeout_count_low8"] == 2
    assert fields["i2c_bus_recovery_count_low8"] == 3
    assert fields["i2c_nack_count_overflow"] is True
    assert fields["i2c_timeout_count_overflow"] is True
    assert fields["i2c_bus_recovery_count_overflow"] is True
    assert fields["error"] == 0x1234
    assert fields["first_i2c_error_low8"] == 0xCD
    assert fields["last_i2c_error_low8"] == 0xAB
    assert fields["reserved_bits_zero"]

    recorder = ResponseRecorder()
    recorder.write_capture_response(1, "PASS")
    recorder.write_capture_response(2, "FAIL")
    recorder.write_capture_response(3, "ABORT")
    assert [value & 0xFFFF for _, value, _ in recorder.writes] == [0x9, 0xA, 0xC]
    assert [value >> 16 for _, value, _ in recorder.writes] == [1, 2, 3]
    assert all(offset == controller.HOST_RESPONSE
               for offset, _, _ in recorder.writes)

    assert set(controller.HOST_HISTORY_FIELDS).issubset(
        controller.CAPTURE_HISTORY_FIELDS)
    assert set(controller.HOST_HISTORY_FIELDS).issubset(
        controller.PIXEL_HISTORY_FIELDS)

    complete_session = {
        "assigned_color": "RED", "status_class": "NO_VIDEO_STABLE",
        "controller": {
            "primary_completion": {
                "primary_bytes": 10_240_000,
                "primary_exact_completions": 2500,
                "primary_short_completions": 0,
                "primary_failed_completions": 0,
                "primary_duplicate_completions": 0,
                "primary_pending": 0,
            },
            "native_finalization": {"final_pending": 0},
            "physical_quiescence": {"result": "PASS"},
            "native_helper_absent": True,
            "native_helper_exit_code": 0,
            "primary_complete_to_disable_us": 499.999,
        },
        "validation": {
            "record_integrity_failures": 0, "global_sequence_gaps": 0,
            "attempt_sequence_gaps": 0, "overflow_flag_records": 0,
            "malformed_preceding_flag_records": 0,
            "source_malformed_snapshot_delta": 0,
            "source_dropped_snapshot_delta": 0,
            "line_0_present": True, "line_0_sof": True,
            "frame_reconstruction": "PASS", "frame_source_sequence": 17,
            "raw_frame_sha256": "a" * 64,
            "viewable_frame_sha256": "b" * 64,
        },
        "pixels": {
            "frame_sha256": "a" * 64, "png_sha256": "b" * 64,
            "classification": "UNIFORM_BGDCOL_RED",
            "assigned_bgcolor_pixel_match": True,
        },
    }
    capture_fields, pixel_fields = controller.history_updates(
        complete_session, "PASS", None)
    assert capture_fields["PrimaryMissingCompletions"] == 0
    assert capture_fields["FinalPendingAIO"] == 0
    assert capture_fields["CleanupResult"] == "PASS"
    assert capture_fields["FrameSHA256"] == "a" * 64
    assert capture_fields["PNG_SHA256"] == "b" * 64
    assert pixel_fields["AssignedColorPixelMatch"] is True

    failed_session = {
        "assigned_color": "GREEN", "status_class": "LOCK_UNSTABLE",
        "controller": {
            "primary_completion": {
                "primary_exact_completions": 100,
                "primary_short_completions": 1,
                "primary_failed_completions": 0,
                "primary_duplicate_completions": 0,
            },
            "native_finalization": {"final_pending": 3},
            "failure_path_quiescence": "FAIL",
            "native_helper_absent": False,
        },
        "validation": {}, "pixels": {},
    }
    failed_capture, _ = controller.history_updates(
        failed_session, "FAIL", "CAPTURE_FAILED")
    assert failed_capture["PrimaryMissingCompletions"] == 2399
    assert failed_capture["FinalPendingAIO"] == 3
    assert failed_capture["CleanupResult"] == "FAIL"
    assert failed_capture["CaptureBlocker"] == "CAPTURE_FAILED"

    capture_controller.validate_disable_latency(0.0)
    capture_controller.validate_disable_latency(500.0)
    for invalid_latency in (-0.001, 500.001):
        try:
            capture_controller.validate_disable_latency(invalid_latency)
        except capture_controller.GateError:
            pass
        else:
            raise AssertionError("invalid disable latency was accepted")

    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        csv_path = root / "session_status_history.csv"
        jsonl_path = root / "session_status_history.jsonl"
        capture_path = root / "session_capture_history.csv"
        pixel_path = root / "session_pixel_history.csv"
        rows = [dict(row) for row in full_scan_rows]
        capture_rows = [dict(row) for row in rows]
        pixel_rows = [dict(row) for row in rows]
        controller.persist_host_histories(
            csv_path, jsonl_path, capture_path, pixel_path,
            rows, capture_rows, pixel_rows)
        for collection in (rows, capture_rows, pixel_rows):
            for row in collection:
                row["CaptureResult"] = "PASS"
                row["CleanupResult"] = "PASS"
        controller.persist_host_histories(
            csv_path, jsonl_path, capture_path, pixel_path,
            rows, capture_rows, pixel_rows)
        with csv_path.open(encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            persisted_csv = list(reader)
            assert set(reader.fieldnames or []) == set(
                controller.HOST_HISTORY_FIELDS)
        with capture_path.open(encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            persisted_capture = list(reader)
            assert set(reader.fieldnames or []) == set(
                controller.CAPTURE_HISTORY_FIELDS)
        with pixel_path.open(encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            persisted_pixel = list(reader)
            assert set(reader.fieldnames or []) == set(
                controller.PIXEL_HISTORY_FIELDS)
        persisted_json = [json.loads(line) for line in
                          jsonl_path.read_text(encoding="utf-8").splitlines()]
        assert (len(persisted_csv) == len(persisted_capture) ==
                len(persisted_pixel) == len(persisted_json) == 16)
        assert all(row["CaptureResult"] == "PASS" for row in persisted_csv)
        assert all(row["CaptureResult"] == "PASS" for row in persisted_capture)
        assert all(row["CaptureResult"] == "PASS" for row in persisted_pixel)
        assert all(row["CaptureResult"] == "PASS" for row in persisted_json)
        assert {int(row["SessionID"]) for row in persisted_json} == set(
            range(1, 17))
        receipt = controller.verify_persisted_host_histories(
            csv_path, jsonl_path, capture_path, pixel_path)
        assert receipt["status_csv_rows"] == 16
        assert receipt["unique_round_channel_pairs"] == 16
        assert receipt["generations_monotonic"] is True
        assert set(receipt["sha256"]) == {
            csv_path.name, jsonl_path.name, capture_path.name, pixel_path.name,
        }

    def summary_session(session: int, status_class: str, pixel_class: str,
                        pixel_match: bool, frame_hash: str) -> dict[str, object]:
        round_number = (session - 1) // 4 + 1
        position = (session - 1) % 4
        channel = controller.ORDERS[round_number - 1][position]
        assigned = controller.COLORS[
            controller.COLOR_CODES_BY_ROUND[round_number - 1][channel - 1]
        ]
        return {
            "session_id": session, "round": round_number, "channel": channel,
            "assigned_color": assigned, "status_class": status_class,
            "controller": {"result": "PASS"},
            "validation": {
                "result": "PASS", "record_integrity_failures": 0,
                "global_sequence_gaps": 0, "attempt_sequence_gaps": 0,
                "overflow_flag_records": 0,
                "malformed_preceding_flag_records": 0,
                "source_dropped_snapshot_delta": 0,
                "frame_reconstruction": "PASS",
            },
            "pixels": {
                "classification": pixel_class,
                "assigned_bgcolor_pixel_match": pixel_match,
                "frame_sha256": frame_hash,
                "dominant_uyvy_word_hex": frame_hash[:8],
            },
        }

    def firmware_rows_for(sessions: list[dict[str, object]]) -> list[dict[str, int]]:
        return [{"channel": int(row["channel"]),
                 "route_readback": int(row["channel"]) - 1}
                for row in sessions]

    color_class = {
        "RED": "UNIFORM_BGDCOL_RED",
        "GREEN": "UNIFORM_BGDCOL_GREEN",
        "CYAN": "UNIFORM_BGDCOL_CYAN",
        "WHITE_75_PERCENT": "UNIFORM_BGDCOL_WHITE",
    }
    all_bg = []
    for session in range(1, 17):
        round_number = (session - 1) // 4 + 1
        channel = controller.ORDERS[round_number - 1][(session - 1) % 4]
        assigned = controller.COLORS[
            controller.COLOR_CODES_BY_ROUND[round_number - 1][channel - 1]
        ]
        color_nibble = (
            f"{controller.COLOR_CODES_BY_ROUND[round_number - 1][channel - 1]:X}"
        )
        all_bg.append(summary_session(
            session, "NO_VIDEO_STABLE", color_class[assigned], True,
            color_nibble * 64))
    summary = controller.summarize(all_bg, firmware_rows_for(all_bg))
    assert summary["overall_result"] == (
        "PASS_ALL_CHANNELS_NO_VIDEO_DIGITAL_PATH_PROVEN_BY_BGDCOL")

    # A mixed-status channel must not allow one wrong-color NO_VIDEO result to
    # hide behind the old only-when-four-no-video per-channel check.
    mixed = [dict(row) for row in all_bg]
    ch1_indices = [index for index, row in enumerate(mixed) if row["channel"] == 1]
    active_index = ch1_indices[0]
    mismatch_index = ch1_indices[1]
    mixed[active_index] = summary_session(
        active_index + 1, "ACTIVE_STABLE", "NONBLACK_LOW_CONTRAST", False,
        "A" * 64)
    mixed[mismatch_index] = summary_session(
        mismatch_index + 1, "NO_VIDEO_STABLE", "UNIFORM_OTHER_COLOR", False,
        "B" * 64)
    summary = controller.summarize(mixed, firmware_rows_for(mixed))
    assert summary["overall_result"] == "FAIL"
    assert summary["channel_summary"]["CH1"]["bgcolor_gate"] == "FAIL"

    # Repeated low-contrast non-black content proves a logical VIN, but does
    # not satisfy the stronger spatial image qualification.
    low_contrast = [dict(row) for row in all_bg]
    for ordinal, index in enumerate(ch1_indices):
        low_contrast[index] = summary_session(
            index + 1, "ACTIVE_STABLE", "NONBLACK_LOW_CONTRAST", False,
            f"{0xA0 + ordinal:064X}")
    summary = controller.summarize(low_contrast, firmware_rows_for(low_contrast))
    assert summary["logical_active_camera_channel"] == 1
    assert summary["overall_result"] == (
        "PASS_LOGICAL_CAMERA_CHANNEL_IDENTIFIED_PHYSICAL_CONNECTOR_OPEN")

    print("PASS DIAG1_R1_HOST_SNAPSHOT_COHERENCE_AND_DURABILITY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
