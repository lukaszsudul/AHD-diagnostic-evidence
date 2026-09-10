#!/usr/bin/env python3
"""Assemble sanitized R2R2 evidence for the pre-hardware authorization stop."""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import shutil


RUN_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R2_20260910T174941Z")
EVIDENCE_NAME = (
    "v41-hardware-g2b-nvp-video-diag1-r2r2-double-prepare-four-channel-scan"
)
OUT = RUN_ROOT / "evidence-staging" / EVIDENCE_NAME
BLOCKER = (
    "BLOCKED — NVP_DIAG1_R2R2_OWNER_AUTHORIZATION_SEQUENCE_CONTRADICTION:"
    "SRAM_PROGRAMMING_IS_CONDITIONED_ON_DOUBLE_PREPARE_PASS_BUT_DIAGNOSTIC_"
    "PREPARE_REQUIRES_THE_NOT_YET_PROGRAMMED_IMAGE"
)
BITSTREAM = Path(
    r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z\artifacts"
    r"\G2B_NVP_VIDEO_DIAG1_R2R1_FOUR_CHANNEL_SCAN.bit"
)


def put_text(relative: str, text: str) -> None:
    target = OUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def put_json(relative: str, value: object) -> None:
    put_text(relative, json.dumps(value, indent=2, sort_keys=True))


def put_csv(relative: str, headers: list[str], rows: list[list[object]]) -> None:
    target = OUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(headers)
        writer.writerows(rows)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> int:
    if OUT.exists():
        raise RuntimeError(f"fresh evidence directory already exists: {OUT}")
    OUT.mkdir(parents=True)

    main_report = f"""
# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R2 main report

Engineering gate: **BLOCKED**

Evidence publication gate: evaluated after the immutable commit and remote
read-back; no self-referential commit hash is embedded in this report.

Overall result: **BLOCKED**

## Outcome

R2R2 stopped before its first hardware contact. The prompt places the exact
SRAM programming, warm reboot, and driver load in Phase B, followed by runtime
identity in Phase C and double-PREPARE in Phase D. However, Owner authorization
section 1.3 conditions those same programming, reboot, and driver operations on
the double-PREPARE baseline gate already having passed. The introduction repeats
that programming follows the baseline gate.

The currently active, Owner-attested runtime is the PRODUCT profile. It does not
instantiate the diagnostic controller or its 0x3C00..0x3FFF diagnostic MMIO.
Therefore PREPARE_A and PREPARE_B cannot execute until the exact R2R1 diagnostic
candidate has first been programmed, enumerated, and opened through the driver.
That programming operation is itself withheld until PREPARE has passed. No
authorized first transition exists.

First blocker:

`{BLOCKER}`

## Work completed without hardware

- Created fresh controller root `{RUN_ROOT}`.
- Prepared an unexecuted task-local double-PREPARE and scan controller from the
  accepted R1 host implementation in the fresh root only.
- Added the authorized task-local double-PREPARE controller logic, including
  immutable A/B ledgers, MMIO double reads, positive equal transaction deltas,
  full visible-baseline comparison, PRODUCT cross-check, and PREPARE_B restore
  authority.
- Preserved the firmware-private original-bank disposition without inventing a
  host-visible value.
- Performed a local Python import/argument syntax check of the task-local
  controller.
- Did not change RTL, XDC, IP, DCP, bitstream, PRODUCT source, diagnostic source,
  SSOT, or prior evidence.

## Hardware non-execution receipt

No DUT connection, controller or Linux hardware lock, JTAG access, FPGA
programming, bitstream hash-at-programming check, reboot, PCIe access, driver
load, device-node access, MMIO, NVP I2C, DMA, AIO, capture, frame reconstruction,
or pixel analysis occurred. The Owner-attested PRODUCT image and NVP baseline
remain unchanged.

## Required reconciliation

The Owner/Architect must explicitly authorize exactly one programming of the
accepted diagnostic bitstream, the one required warm reboot, exact driver load,
and read-only runtime identity **before** the double-PREPARE gate. The existing
double-PREPARE gate can then remain the hard prerequisite for all functional NVP
writes, START_4X4_SCAN, route changes, BGDCOL changes, and captures.

No RTL, DCP, or bitstream change is needed.
"""
    put_text("V41_G2B_NVP_VIDEO_DIAG1_R2R2_MAIN_REPORT.md", main_report)

    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_OWNER_AUTHORIZATION.md", f"""
# Owner authorization receipt

- Double-PREPARE reconciliation: GRANTED.
- Firmware-private original-bank disposition: GRANTED.
- Exact candidate programming: conditionally granted only after double-PREPARE.
- Four-channel scan: conditionally granted only after double-PREPARE.

The conditional programming clause is circular because PREPARE exists only in
the diagnostic image. Hardware execution therefore remained prohibited.

First blocker: `{BLOCKER}`
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_SCOPE.md", """
# Scope receipt

R2R2 accepted all R2R1 offline sign-off results. Only fresh task-local host
software preparation and append-only evidence publication were executed. No
offline sign-off was repeated and no hardware operation was attempted.
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_R2R1_INHERITANCE.md", """
# R2R1 inheritance

- Source commit: `fcab95726761a0666a67e31c283dbdfb9e775074`
- Source tree: `bbf1a5fee70a2eb68bb96305ed10934a1559ca6a`
- Signed DCP SHA-256: `6C37259220B310B7F86BEC5AE228474E6DB270E870FDDEF3EDC7642F368A6CB2`
- Diagnostic bitstream recorded SHA-256:
  `9D1491CB6709ED623C985B2C9AEA53E2C360A68A77DB4680BEE9B8935A82D12F`
- Offline sign-off: PASS.
- R2R1 evidence commit: `f615d8a01dc56157e22b3cb01245a56969a32a52`.

These values were inherited without repeating the offline work. The R2R2
programming-time bitstream hash gate was not reached.
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R1_PUBLICATION_RECEIPT.md", """
# R2R1 append-only publication receipt

R2R1 evidence commit:
`f615d8a01dc56157e22b3cb01245a56969a32a52`

R2R1 remote read-back: PASS

R2R1 offline sign-off: PASS

R2R1 bitstream: READY_FOR_EXACT_HARDWARE_ACTIVATION

No R2R1 evidence file was rewritten by R2R2.
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_EXACT_CANDIDATE_AUTHORITY.md", f"""
# Exact candidate authority

Candidate path: `{BITSTREAM}`

Recorded R2R1 SHA-256:
`9D1491CB6709ED623C985B2C9AEA53E2C360A68A77DB4680BEE9B8935A82D12F`

Classification: `G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_CDC_CANDIDATE`

R2R2 programming-time identity gate: NOT_REACHED. In accordance with the
prompt, R2R2 did not calculate the programming hash early after hardware
authorization was found to be circular.
""")

    not_reached_docs = {
        "G2B_NVP_VIDEO_DIAG1_R2R2_PROGRAMMING_RECEIPT.md":
            "FPGA SRAM programming: NOT_REACHED. Programming attempts: 0.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_REBOOT_RECEIPT.md":
            "Warm reboot: NOT_REACHED. Reboot count: 0.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_RUNTIME_IDENTITY.md":
            "Runtime diagnostic identity: NOT_REACHED.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_DRIVER_LOAD.md":
            "Driver load and XDMA nodes: NOT_REACHED / NOT_CREATED.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_DIGITAL_PATH_DECISION.md":
            "Downstream digital pixel path: NOT_REACHED.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_LOGICAL_CAMERA_CHANNEL_DECISION.md":
            "Logical active camera channel: UNRESOLVED; scan not reached.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_CAMERA_CONTENT_DECISION.md":
            "End-to-end camera image: UNRESOLVED; no capture occurred.",
        "G2B_NVP_VIDEO_DIAG1_R2R2_PRODUCT_RESTORE_RECEIPT.md":
            "PRODUCT restore operation: NOT_REACHED. The diagnostic image was not programmed and the Owner-attested PRODUCT baseline was not changed.",
    }
    for name, body in not_reached_docs.items():
        put_text(name, f"# {name.removesuffix('.md')}\n\n{body}\n")

    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_BASELINE_CONTRACT_DECISION.md", f"""
# Double-PREPARE baseline contract decision

The reconciled visible-baseline method is technically implementable by the
frozen diagnostic firmware after that firmware is active. The prompt does not,
however, authorize activation until the method has already passed. Since the
current PRODUCT image has no diagnostic PREPARE interface, the baseline gate
was NOT_REACHED.

Decision: BLOCKED

First blocker: `{BLOCKER}`
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_BASELINE_COMPARISON.md", f"""
# Baseline comparison

PREPARE_A: NOT_REACHED

PREPARE_B: NOT_REACHED

Double-PREPARE baseline gate: NOT_REACHED

Reason: `{BLOCKER}`
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_ORIGINAL_BANK_DISPOSITION.md", """
# Original-bank disposition

ORIGINAL_BANK_HOST_VISIBLE = NO

ORIGINAL_BANK_DOUBLE_HOST_COMPARISON = NOT_AVAILABLE_BY_DESIGN

ORIGINAL_BANK_AUTHORITY = SECOND_PREPARE_FIRMWARE_PRIVATE_VALUE

ORIGINAL_BANK_SAFETY_METHOD = EACH_PREPARE_READS_AND_RESTORES_BANK;
FINAL_VERIFY_RESTORE_PHYSICALLY_READS_AND_COMPARES_BANK

ORIGINAL_BANK_GOVERNANCE_DISPOSITION =
ACCEPTED_FIRMWARE_PRIVATE_OPERATIONAL_CONTEXT

Runtime final verification: NOT_REACHED.
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_PHYSICAL_INPUT_ACTION.md", """
# Physical Owner action

Owner/Architect: explicitly authorize the single exact diagnostic SRAM
programming, required warm reboot, exact driver load, and read-only runtime
identity before double-PREPARE. Keep double-PREPARE as the gate before every
functional NVP write and before the 4x4 scan.
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_CLEANUP_RECEIPT.md", """
# Cleanup receipt

No hardware resource was acquired. No DUT helper, AIO context, driver, XDMA
node, controller lock, or Linux lock was created. There was therefore no live
hardware state to clean up. Prior state remained Owner-attested: stream
disabled, no active DMA, driver unloaded, nodes absent, locks released.
""")
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_FINAL_STATE.md", f"""
# Final state

- Engineering gate: BLOCKED
- Hardware accessed: NO
- FPGA programming attempts: 0
- Warm reboots: 0
- Driver: NOT_LOADED
- XDMA nodes: NOT_CREATED
- NVP persistent state changed: NO
- FPGA source changed: NO
- SSOT changed: NO
- Owner-attested runtime profile: PRODUCT_PROFILE_UNCHANGED
- First blocker: `{BLOCKER}`
""")

    baseline_na = {
        "result": "NOT_REACHED",
        "reason": BLOCKER,
        "original_bank_host_visible": False,
    }
    for letter in ("A", "B"):
        put_json(f"G2B_NVP_VIDEO_DIAG1_R2R2_BASELINE_{letter}.json",
                 {**baseline_na, "baseline": letter})
        put_csv(f"G2B_NVP_VIDEO_DIAG1_R2R2_BASELINE_{letter}.csv",
                ["Baseline", "Result", "Reason"],
                [[letter, "NOT_REACHED", BLOCKER]])
    put_csv("G2B_NVP_VIDEO_DIAG1_R2R2_BASELINE_COMPARISON.csv",
            ["Gate", "Result", "Reason"],
            [["DOUBLE_PREPARE_BASELINE_GATE", "NOT_REACHED", BLOCKER]])

    empty_csvs = {
        "G2B_NVP_VIDEO_DIAG1_R2R2_SNAPSHOT_COHERENCE.csv":
            ["SessionID", "Attempt", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_HOST_SESSION_HISTORY.csv":
            ["SessionID", "Round", "Channel", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_SCAN_RESULTS.csv":
            ["SessionID", "Round", "Channel", "Classification"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_STATUS_SAMPLES.csv":
            ["SessionID", "Sample", "RawStatus"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_ROUTE_READBACKS.csv":
            ["SessionID", "Requested", "Readback", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_BGDCOL_ROUND_READBACKS.csv":
            ["Round", "BGDCOL78", "BGDCOL79", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_I2C_COUNTER_TIMELINE.csv":
            ["Checkpoint", "Transactions", "NACK", "Timeout", "Recovery"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_CAPTURE_INDEX.csv":
            ["SessionID", "Capture", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_CAPTURE_RESULTS.csv":
            ["SessionID", "ExactCompletions", "Bytes", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_AIO_SUMMARY.csv":
            ["SessionID", "Submitted", "Completed", "Pending", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_FRAME_HASHES.csv":
            ["SessionID", "RawSHA256", "PNGSHA256"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_PIXEL_STATISTICS.csv":
            ["SessionID", "Classification", "DominantUYVY"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_BGDCOL_MATCH_RESULTS.csv":
            ["SessionID", "Assigned", "Captured", "Result"],
        "G2B_NVP_VIDEO_DIAG1_R2R2_CHANNEL_REPEATABILITY.csv":
            ["Channel", "Rounds", "Result"],
    }
    for name, fields in empty_csvs.items():
        put_csv(name, fields, [])
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_HOST_SESSION_HISTORY.jsonl", "")

    put_csv("G2B_NVP_VIDEO_DIAG1_R2R2_GATE_MATRIX.csv",
            ["Gate", "Result", "Evidence"], [
                ["R2R1_OFFLINE_SIGNOFF", "PASS_INHERITED",
                 "f615d8a01dc56157e22b3cb01245a56969a32a52"],
                ["TASK_LOCAL_DOUBLE_PREPARE_SCAN_SOURCE_PREPARATION",
                 "PASS_UNEXECUTED",
                 "source/controller_nvp_video_diag1_r2r2.py"],
                ["HARDWARE_AUTHORIZATION_SEQUENCE", "BLOCKED", BLOCKER],
                ["EXACT_BITSTREAM_IDENTITY_AT_PROGRAMMING", "NOT_REACHED", ""],
                ["DOUBLE_PREPARE_BASELINE_GATE", "NOT_REACHED", ""],
                ["FOUR_CHANNEL_SCAN", "NOT_REACHED", ""],
                ["PRODUCT_BASELINE_RESTORE", "NOT_REACHED_UNCHANGED", ""],
                ["ENGINEERING_GATE", "BLOCKED", BLOCKER],
            ])

    state = {
        "task": "AHD v41 G2B-NVP-VIDEO-DIAG1-R2R2",
        "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
        "engineering_gate": "BLOCKED",
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "fresh_run_root": str(RUN_ROOT),
        "same_codex_window": True,
        "offline_signoff_inherited": "PASS",
        "hardware_accessed": False,
        "dut_connections": 0,
        "programming_attempts": 0,
        "warm_reboots": 0,
        "driver_load": "NOT_REACHED",
        "double_prepare_gate": "NOT_REACHED",
        "functional_nvp_writes_before_baseline_agreement": 0,
        "sessions_completed": 0,
        "source_changed": False,
        "rtl_changed": False,
        "xdc_changed": False,
        "ip_changed": False,
        "dcp_changed": False,
        "bitstream_regenerated": False,
        "nvp_persistent_state_changed": False,
        "ssot_changed": False,
        "raw_captures_published": False,
        "camera_images_published": False,
        "final_fpga_runtime_profile": "PRODUCT_PROFILE_UNCHANGED",
    }
    put_json("G2B_NVP_VIDEO_DIAG1_R2R2_STATE.json", state)

    source_files = [
        "controller_nvp_video_diag1_r2r2.py",
        "controller_nvp_capture.py",
        "xdma_c2h_rolling_4k_diag1.c",
        "validate_nvp_capture.py",
        "frame_reconstruct_nvp_capture.py",
        "analyze_nvp_video_diag1.py",
        "aggregate_nvp_session_metadata.py",
        "abi_v1.py",
        "V41_C2H_TRANSPORT_ABI_V1.json",
        "assemble_r2r2_blocked_evidence.py",
    ]
    source_hashes: list[tuple[str, str, int]] = []
    for name in source_files:
        source = RUN_ROOT / "scripts" / name
        destination = OUT / "source" / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        source_hashes.append((name, sha256(destination), destination.stat().st_size))
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_TASK_LOCAL_SCRIPT_SHA256.txt",
             "\n".join(f"{digest}  source/{name}" for name, digest, _ in source_hashes))

    files_before_index = sorted(
        path.relative_to(OUT).as_posix()
        for path in OUT.rglob("*") if path.is_file()
    )
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_EVIDENCE_INDEX.md", """
# Evidence index

This append-only package records the R2R2 pre-hardware governance stop. All
runtime baseline, scan, capture, frame, and pixel tables are empty by design
because the first hardware operation was not authorized. Task-local host source
is included for review, but it was not hardware-executed or hardware-qualified
in R2R2. Raw video, images, bitstreams, DCPs, drivers, executables, and
credentials are excluded.

## Files

""" + "\n".join(f"- `{name}`" for name in files_before_index))

    manifest_entries = []
    for path in sorted(OUT.rglob("*")):
        if path.is_file() and path.name != "G2B_NVP_VIDEO_DIAG1_R2R2_SHA256_MANIFEST.txt":
            manifest_entries.append(
                f"{sha256(path)}  {path.relative_to(OUT).as_posix()}"
            )
    put_text("G2B_NVP_VIDEO_DIAG1_R2R2_SHA256_MANIFEST.txt",
             "\n".join(manifest_entries))
    print(json.dumps({
        "result": "PASS",
        "evidence_root": str(OUT),
        "file_count": sum(1 for path in OUT.rglob("*") if path.is_file()),
        "manifest_entries": len(manifest_entries),
        "first_blocker": BLOCKER,
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
