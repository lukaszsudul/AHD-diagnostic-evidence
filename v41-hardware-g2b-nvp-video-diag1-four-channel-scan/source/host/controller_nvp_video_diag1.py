#!/usr/bin/env python3
"""Governed 4x4 NVP scan orchestrator; all capture work remains DUT-local."""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import time
from typing import Any


TASK = "AHD-v41-G2B-NVP-VIDEO-DIAG1"
DIAG_MAGIC = 0x4E565034
DIAG_VERSION = 0x00010000
CONTROL = 0x3C0C
STATUS = 0x3C10
ERROR = 0x3C14
ROUND_CHANNEL = 0x3C1C
SESSION = 0x3C20
HOST_RESPONSE = 0x3C34
COLORS = {0x6: "RED", 0x4: "GREEN", 0x3: "CYAN", 0x1: "WHITE_75_PERCENT"}
CLASSES = {
    1: "ACTIVE_STABLE", 2: "NO_VIDEO_STABLE", 3: "LOCK_UNSTABLE",
    4: "STATUS_CONTRADICTORY", 5: "I2C_STATUS_ERROR",
}
ORDERS = ((1, 2, 3, 4), (4, 3, 2, 1), (2, 3, 4, 1), (3, 4, 1, 2))


class ScanError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ScanError(message)


def write_json(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fields: list[str], rows: list[dict[str, Any]]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows({field: row.get(field, "") for field in fields}
                         for row in rows)
        handle.flush()
        os.fsync(handle.fileno())


class DiagnosticMmio:
    def __init__(self, path: str, ledger: list[dict[str, Any]]) -> None:
        flags = os.O_RDWR | os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        self.fd = os.open(path, flags)
        self.ledger = ledger

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def read(self, offset: int, purpose: str) -> int:
        require(0x3C00 <= offset <= 0x3FFF and offset % 4 == 0,
                "NVP_DIAG1_DIAGNOSTIC_MMIO_READ_ALLOWLIST_VIOLATION")
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, "NVP_DIAG1_SHORT_DIAGNOSTIC_MMIO_READ")
        value = struct.unpack("<I", raw)[0]
        self.ledger.append({
            "TimestampNs": time.time_ns(), "Operation": "READ",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Result": "PASS",
        })
        return value

    def write_control(self, value: int, purpose: str) -> None:
        require(value in (1, 2, 4, 8, 16),
                "NVP_DIAG1_CONTROL_COMMAND_NOT_WHITELISTED")
        self._write(CONTROL, value, purpose)

    def write_capture_response(self, session_id: int, *, passed: bool,
                               abort: bool = False) -> None:
        require(1 <= session_id <= 16, "NVP_DIAG1_RESPONSE_SESSION_INVALID")
        low = 0x8 | (0x1 if passed else 0x2) | (0x4 if abort else 0)
        self._write(HOST_RESPONSE, (session_id << 16) | low,
                    "HOST_CAPTURE_RESPONSE")

    def _write(self, offset: int, value: int, purpose: str) -> None:
        written = os.pwrite(self.fd, struct.pack("<I", value), offset)
        require(written == 4, "NVP_DIAG1_SHORT_DIAGNOSTIC_MMIO_WRITE")
        self.ledger.append({
            "TimestampNs": time.time_ns(), "Operation": "WRITE",
            "Offset": f"0x{offset:04X}", "Value": f"0x{value:08X}",
            "Purpose": purpose, "Result": "PASS",
        })


def status_bits(value: int) -> dict[str, bool]:
    return {
        "busy": bool(value & 0x001), "prepared": bool(value & 0x002),
        "capture_ready": bool(value & 0x004), "done": bool(value & 0x008),
        "error": bool(value & 0x010), "baseline_restored": bool(value & 0x020),
        "i2c_owned": bool(value & 0x040), "i2c_bus_idle": bool(value & 0x080),
        "scan_active": bool(value & 0x100),
    }


def wait_for(mmio: DiagnosticMmio, predicate, timeout: float,
             purpose: str) -> tuple[int, dict[str, bool]]:
    deadline = time.monotonic() + timeout
    last = 0
    while time.monotonic() < deadline:
        last = mmio.read(STATUS, purpose)
        bits = status_bits(last)
        if bits["error"]:
            code = mmio.read(ERROR, purpose + "_ERROR")
            raise ScanError(f"NVP_DIAG1_FIRMWARE_ERROR:0x{code:08X}")
        if predicate(bits):
            return last, bits
        time.sleep(0.010)
    raise ScanError(f"NVP_DIAG1_WAIT_TIMEOUT:{purpose}:0x{last:08X}")


def run_checked(command: list[str], log: Path, label: str) -> None:
    completed = subprocess.run(command, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, check=False)
    log.write_bytes(completed.stdout)
    require(completed.returncode == 0,
            f"NVP_DIAG1_{label}_FAILED:RC={completed.returncode}")


def read_json(path: Path) -> dict[str, Any]:
    require(path.is_file(), f"NVP_DIAG1_REQUIRED_RESULT_MISSING:{path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"NVP_DIAG1_RESULT_SCHEMA_INVALID:{path}")
    return value


def capture_session(args: argparse.Namespace, session_id: int, round_number: int,
                    channel: int, color: str, status_class: str) -> dict[str, Any]:
    label = f"session-{session_id:02d}-r{round_number}-ch{channel}"
    private_dir = args.private_root / label
    logs_dir = args.logs_root / label
    image_dir = args.images_root / label
    private_dir.mkdir(parents=True, mode=0o700)
    logs_dir.mkdir(parents=True, mode=0o700)
    image_dir.mkdir(parents=True, mode=0o700)

    capture_command = [
        sys.executable, str(args.capture_controller),
        "--user-node", args.user_node, "--c2h-node", args.c2h_node,
        "--native-helper", str(args.native_helper),
        "--private-dir", str(private_dir), "--logs-dir", str(logs_dir),
        "--linux-lock", str(args.linux_lock),
        "--expected-git-sha", args.expected_git_sha,
        "--expected-build-flags", args.expected_build_flags,
    ]
    run_checked(capture_command, logs_dir / "capture-controller.console.log",
                f"SESSION_{session_id:02d}_CAPTURE")
    controller_result = read_json(logs_dir / "controller-result.json")
    require(controller_result.get("result") == "PASS",
            f"NVP_DIAG1_SESSION_{session_id:02d}_CAPTURE_CONTRACT_FAILED")

    validation_command = [
        sys.executable, str(args.validator), "--abi", str(args.abi),
        "--primary", str(private_dir / "primary.bin"),
        "--controller-result", str(logs_dir / "controller-result.json"),
        "--private-dir", str(private_dir), "--logs-dir", str(logs_dir),
    ]
    run_checked(validation_command, logs_dir / "validator.console.log",
                f"SESSION_{session_id:02d}_VALIDATION")
    validation = read_json(logs_dir / "validation-result.json")
    require(validation.get("result") == "PASS" and
            validation.get("record_integrity_failures") == 0 and
            validation.get("global_sequence_gaps") == 0 and
            validation.get("attempt_sequence_gaps") == 0 and
            validation.get("overflow_flag_records") == 0 and
            validation.get("malformed_preceding_flag_records") == 0 and
            validation.get("line_0_present") is True and
            validation.get("line_0_sof") is True and
            validation.get("frame_reconstruction") == "PASS",
            f"NVP_DIAG1_SESSION_{session_id:02d}_STRUCTURAL_CAPTURE_FAILED")

    analyzer_command = [
        sys.executable, str(args.pixel_analyzer),
        "--frame", str(private_dir / "qualified-frame.uyvy"),
        "--png", str(private_dir / "qualified-frame.png"),
        "--output-dir", str(image_dir), "--session-id", str(session_id),
        "--round", str(round_number), "--channel", str(channel),
        "--assigned-color", color, "--status-class", status_class,
    ]
    run_checked(analyzer_command, logs_dir / "pixel-analyzer.console.log",
                f"SESSION_{session_id:02d}_PIXEL_ANALYSIS")
    pixels = read_json(image_dir / "pixel-statistics.json")
    require(pixels.get("result") == "PASS" and
            pixels.get("classification") != "INVALID_OR_CORRUPT",
            f"NVP_DIAG1_SESSION_{session_id:02d}_PIXEL_ANALYSIS_INVALID")
    return {
        "session_id": session_id, "round": round_number, "channel": channel,
        "assigned_color": color, "status_class": status_class,
        "controller": controller_result, "validation": validation,
        "pixels": pixels, "private_dir": str(private_dir),
        "logs_dir": str(logs_dir), "images_dir": str(image_dir),
    }


def decode_result_entry(words: list[int]) -> dict[str, Any]:
    return {
        "session_id": (words[0] >> 16) & 0xFFFF,
        "round": (words[0] >> 11) & 0x7,
        "channel": (words[0] >> 8) & 0x7,
        "classification": words[0] & 0xFF,
        "route_requested": (words[1] >> 24) & 0xFF,
        "route_readback": (words[1] >> 16) & 0xFF,
        "bgcolor_code": (words[1] >> 8) & 0xFF,
        "stable_sample_count": words[1] & 0xFF,
        "raw_novid": (words[2] >> 24) & 0xFF,
        "raw_agc_lock": (words[2] >> 16) & 0xFF,
        "raw_cmp_lock": (words[2] >> 8) & 0xFF,
        "raw_h_lock": words[2] & 0xFF,
        "raw_channel_status": (words[3] >> 24) & 0xFF,
        "bgcolor_78": (words[3] >> 16) & 0xFF,
        "bgcolor_79": (words[3] >> 8) & 0xFF,
        "total_status_samples": words[3] & 0xFF,
        "i2c_transaction_count_at_store": words[5],
        "host_capture_response": words[6],
        "error": words[7] & 0xFFFF,
    }


def summarize(sessions: list[dict[str, Any]], firmware: list[dict[str, Any]]) -> dict[str, Any]:
    route_passes = sum(row["route_readback"] & 0xF == row["channel"] - 1
                       for row in firmware)
    no_video_rows = [row for row in sessions if row["status_class"] == "NO_VIDEO_STABLE"]
    bg_classes = {row["pixels"]["classification"] for row in no_video_rows
                  if row["pixels"]["classification"].startswith("UNIFORM_BGDCOL_")}
    stuck_black = any(row["pixels"]["classification"] == "EXACT_DIGITAL_BLACK"
                      for row in no_video_rows)
    channel_summary: dict[str, Any] = {}
    logical_camera = None
    camera_temporal = "NOT_TESTED"
    for channel in range(1, 5):
        rows = [row for row in sessions if row["channel"] == channel]
        active = [row for row in rows if row["status_class"] == "ACTIVE_STABLE"]
        no_video = [row for row in rows if row["status_class"] == "NO_VIDEO_STABLE"]
        live = [row for row in active if row["pixels"]["classification"] in
                ("NONBLACK_SPATIALLY_VARYING", "NONBLACK_LOW_CONTRAST") and
                not row["pixels"]["assigned_bgcolor_pixel_match"]]
        hashes = {row["pixels"]["frame_sha256"] for row in live}
        channel_summary[f"CH{channel}"] = {
            "active_rounds": len(active), "no_video_rounds": len(no_video),
            "unstable_or_contradictory_rounds": 4 - len(active) - len(no_video),
            "complete_captures": len(rows),
            "exact_black_captures": sum(row["pixels"]["classification"] ==
                                         "EXACT_DIGITAL_BLACK" for row in rows),
            "bgcolor_matched_captures": sum(row["pixels"]["classification"].startswith(
                                             "UNIFORM_BGDCOL_") for row in rows),
            "nonblack_live_captures": len(live),
            "frame_hashes": sorted({row["pixels"]["frame_sha256"] for row in rows}),
        }
        if len(active) >= 2 and len(live) >= 2 and logical_camera is None:
            logical_camera = channel
            camera_temporal = "PASS" if len(hashes) >= 2 else "STATIC"

    if stuck_black:
        digital_path = "FAIL_STUCK_DIGITAL_BLACK"
    elif len(bg_classes) >= 3:
        digital_path = "PASS_BGDCOL_MULTI_COLOR"
    elif logical_camera is not None:
        digital_path = "PASS_LIVE_NONBLACK"
    else:
        digital_path = "UNRESOLVED"

    all_no_video = len(no_video_rows) == 16
    contradictory = any(row["status_class"] in
                        ("LOCK_UNSTABLE", "STATUS_CONTRADICTORY") for row in sessions)
    if stuck_black or route_passes != 16:
        overall = "FAIL"
    elif logical_camera is not None:
        spatial = any(row["channel"] == logical_camera and
                      row["pixels"]["classification"] == "NONBLACK_SPATIALLY_VARYING"
                      for row in sessions)
        overall = ("PASS_END_TO_END_CAMERA_IMAGE_QUALIFIED" if
                   spatial and camera_temporal == "PASS" else
                   "PASS_END_TO_END_STATIC_CAMERA_IMAGE_QUALIFIED")
    elif all_no_video and digital_path == "PASS_BGDCOL_MULTI_COLOR":
        overall = "PASS_ALL_CHANNELS_NO_VIDEO_DIGITAL_PATH_PROVEN_BY_BGDCOL"
    elif contradictory:
        overall = "PASS_SCAN_COMPLETE_STATUS_CONTRADICTORY"
    elif digital_path in ("PASS_BGDCOL_MULTI_COLOR", "PASS_LIVE_NONBLACK"):
        overall = "PASS_DIGITAL_PATH_PROVEN_CAMERA_FORMAT_OR_ANALOG_INPUT_OPEN"
    else:
        overall = "FAIL"
    return {
        "route_readbacks_passed": route_passes,
        "bgcolor_classes_observed": sorted(bg_classes),
        "bgcolor_colors_captured_distinctly": len(bg_classes),
        "downstream_digital_pixel_path": digital_path,
        "logical_active_camera_channel": logical_camera,
        "camera_temporal_response": camera_temporal,
        "all_channels_no_video": all_no_video,
        "channel_summary": channel_summary,
        "overall_result": overall,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", default="/dev/xdma0_user")
    parser.add_argument("--c2h-node", default="/dev/xdma0_c2h_0")
    parser.add_argument("--native-helper", required=True, type=Path)
    parser.add_argument("--capture-controller", required=True, type=Path)
    parser.add_argument("--validator", required=True, type=Path)
    parser.add_argument("--pixel-analyzer", required=True, type=Path)
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--private-root", required=True, type=Path)
    parser.add_argument("--logs-root", required=True, type=Path)
    parser.add_argument("--images-root", required=True, type=Path)
    parser.add_argument("--linux-lock", required=True, type=Path)
    parser.add_argument("--expected-git-sha", required=True)
    parser.add_argument("--expected-build-flags", required=True)
    args = parser.parse_args()

    args.private_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    args.logs_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    args.images_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    ledger: list[dict[str, Any]] = []
    sessions: list[dict[str, Any]] = []
    status_rows: list[dict[str, Any]] = []
    firmware_rows: list[dict[str, Any]] = []
    result: dict[str, Any] = {"result": "FAIL", "blocker": None}
    mmio: DiagnosticMmio | None = None
    pending_response: tuple[int, bool] | None = None
    try:
        lock = read_json(args.linux_lock / "receipt.json")
        require(lock.get("task") == TASK and lock.get("state") == "HELD",
                "NVP_DIAG1_LINUX_TASK_LOCK_INVALID")
        mmio = DiagnosticMmio(args.user_node, ledger)
        require(mmio.read(0x3C00, "IDENTITY") == DIAG_MAGIC,
                "NVP_DIAG1_MAGIC_MISMATCH")
        require(mmio.read(0x3C04, "IDENTITY") == DIAG_VERSION,
                "NVP_DIAG1_VERSION_MISMATCH")
        mmio.write_control(1, "DIAG_CLEAR")
        mmio.write_control(2, "PREPARE_DIAGNOSTIC")
        wait_for(mmio, lambda bits: bits["prepared"] and bits["baseline_restored"],
                 10.0, "PREPARE_WAIT")
        original = {
            "route": mmio.read(0x3C44, "ORIGINAL_BASELINE"),
            "bgcolor_78": mmio.read(0x3C48, "ORIGINAL_BASELINE"),
            "bgcolor_79": mmio.read(0x3C4C, "ORIGINAL_BASELINE"),
        }
        mmio.write_control(4, "START_4X4_SCAN")

        for expected_session in range(1, 17):
            wait_for(mmio, lambda bits: bits["capture_ready"], 10.0,
                     f"SESSION_{expected_session:02d}_READY")
            session_id = mmio.read(SESSION, "CAPTURE_READY") & 0xFFFF
            rc = mmio.read(ROUND_CHANNEL, "CAPTURE_READY")
            round_number = ((rc >> 3) & 0x7) + 1
            channel = rc & 0x7
            route = mmio.read(0x3C38, "CAPTURE_READY") & 0xFF
            bg78 = mmio.read(0x3C3C, "CAPTURE_READY") & 0xFF
            bg79 = mmio.read(0x3C40, "CAPTURE_READY") & 0xFF
            class_code = mmio.read(0x3C74, "CAPTURE_READY") & 0xFF
            color_code = mmio.read(0x3C78, "CAPTURE_READY") & 0xF
            raw = {
                "raw_novid": mmio.read(0x3C7C, "CAPTURE_READY") & 0xFF,
                "raw_agc_lock": mmio.read(0x3C80, "CAPTURE_READY") & 0xFF,
                "raw_cmp_lock": mmio.read(0x3C84, "CAPTURE_READY") & 0xFF,
                "raw_h_lock": mmio.read(0x3C88, "CAPTURE_READY") & 0xFF,
                "raw_channel_status": mmio.read(0x3C8C, "CAPTURE_READY") & 0xFF,
            }
            counts = mmio.read(0x3C90, "CAPTURE_READY")
            require(session_id == expected_session and round_number ==
                    (expected_session - 1) // 4 + 1 and channel ==
                    ORDERS[round_number - 1][(expected_session - 1) % 4],
                    "NVP_DIAG1_SESSION_OR_ORDER_MISMATCH")
            require((route & 0xF) == channel - 1,
                    "NVP_DIAG1_ROUTE_READBACK_MISMATCH")
            require(class_code in CLASSES and color_code in COLORS,
                    "NVP_DIAG1_STATUS_OR_COLOR_CODE_INVALID")
            status_class = CLASSES[class_code]
            color = COLORS[color_code]
            status_rows.append({
                "SessionID": session_id, "Round": round_number,
                "Channel": channel, "Classification": status_class,
                "RouteReadback": f"0x{route:02X}", "BGDCOL": color,
                "BGDCOLCode": f"0x{color_code:X}",
                "BGDCOL78": f"0x{bg78:02X}", "BGDCOL79": f"0x{bg79:02X}",
                **{key: f"0x{value:02X}" for key, value in raw.items()},
                "StableSamples": counts & 0xFF,
                "TotalStatusSamples": (counts >> 8) & 0xFF,
            })
            mmio.close()
            mmio = None

            try:
                session_result = capture_session(args, session_id, round_number,
                                                 channel, color, status_class)
                passed = True
            except BaseException:
                passed = False
                raise
            finally:
                mmio = DiagnosticMmio(args.user_node, ledger)
                pending_response = (session_id, passed)
                mmio.write_capture_response(session_id, passed=passed)
                pending_response = None
            sessions.append(session_result)
            wait_for(mmio, lambda bits: not bits["capture_ready"], 2.0,
                     f"SESSION_{session_id:02d}_ACKNOWLEDGED")

        wait_for(mmio, lambda bits: bits["done"] and bits["baseline_restored"],
                 15.0, "SCAN_DONE_AND_RESTORE")
        for index in range(16):
            words = [mmio.read(0x3D00 + (index * 8 + word) * 4,
                               f"RESULT_{index + 1:02d}") for word in range(8)]
            row = decode_result_entry(words)
            require(row["session_id"] == index + 1 and row["error"] == 0,
                    "NVP_DIAG1_FIRMWARE_RESULT_TABLE_INVALID")
            firmware_rows.append(row)
        final_state = {
            "status": mmio.read(STATUS, "FINAL"),
            "error": mmio.read(ERROR, "FINAL"),
            "route": mmio.read(0x3C38, "FINAL") & 0xFF,
            "bgcolor_78": mmio.read(0x3C3C, "FINAL") & 0xFF,
            "bgcolor_79": mmio.read(0x3C40, "FINAL") & 0xFF,
            "i2c_transaction_count": mmio.read(0x3C50, "FINAL"),
            "i2c_nack_count": mmio.read(0x3C54, "FINAL"),
            "i2c_timeout_count": mmio.read(0x3C58, "FINAL"),
            "i2c_bus_recovery_count": mmio.read(0x3C70, "FINAL"),
            "completed_sessions": mmio.read(0x3C64, "FINAL"),
            "restore_status": mmio.read(0x3C6C, "FINAL"),
        }
        require(final_state["completed_sessions"] == 16 and
                final_state["error"] == 0 and final_state["restore_status"] == 3 and
                final_state["route"] == original["route"] and
                final_state["bgcolor_78"] == original["bgcolor_78"] and
                final_state["bgcolor_79"] == original["bgcolor_79"] and
                final_state["i2c_nack_count"] == 0 and
                final_state["i2c_timeout_count"] == 0,
                "NVP_VIDEO_DIAG1_PRODUCT_BASELINE_RESTORE_FAILED")

        summary = summarize(sessions, firmware_rows)
        require(summary["overall_result"] != "FAIL",
                "NVP_DIAG1_CONCLUSIVE_SCAN_ENGINEERING_FAILURE")
        result = {
            "result": "PASS", "blocker": None,
            "overall_result": summary["overall_result"],
            "diagnostic_identity": {"magic": f"0x{DIAG_MAGIC:08X}",
                                    "version": f"0x{DIAG_VERSION:08X}"},
            "original_baseline": original, "final_state": final_state,
            "summary": summary, "sessions": sessions,
            "firmware_results": firmware_rows,
        }
    except BaseException as exc:
        result = {"result": "FAIL", "blocker": str(exc) or type(exc).__name__,
                  "sessions_completed": len(sessions)}
        if mmio is not None and pending_response is not None:
            try:
                mmio.write_capture_response(pending_response[0], passed=False)
            except BaseException:
                pass
        if mmio is not None:
            try:
                state = status_bits(mmio.read(STATUS, "FAILURE_RESTORE_CHECK"))
                if not state["baseline_restored"]:
                    mmio.write_control(16, "FAILURE_RESTORE_PRODUCT_BASELINE")
                    wait_for(mmio, lambda bits: bits["baseline_restored"], 10.0,
                             "FAILURE_RESTORE_WAIT")
            except BaseException as restore_error:
                result["restore_failure"] = str(restore_error)
    finally:
        if mmio is not None:
            mmio.close()
        if ledger:
            write_csv(args.logs_root / "diagnostic-mmio-ledger.csv",
                      ["TimestampNs", "Operation", "Offset", "Value", "Purpose",
                       "Result"], ledger)
        if status_rows:
            write_csv(args.logs_root / "status-samples.csv", list(status_rows[0]),
                      status_rows)
        if firmware_rows:
            write_csv(args.logs_root / "scan-results.csv", list(firmware_rows[0]),
                      firmware_rows)
        write_json(args.logs_root / "scan-controller-result.json", result)

    print(json.dumps({"result": result["result"],
                      "overall_result": result.get("overall_result"),
                      "blocker": result.get("blocker")}, sort_keys=True), flush=True)
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
