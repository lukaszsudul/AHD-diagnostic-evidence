#!/usr/bin/env python3
"""Build the sanitized, pre-hardware R3R4R6 evidence package."""

from __future__ import annotations

import csv
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


RUN_ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R6_20260907T174249Z")
STAGING = RUN_ROOT / "evidence-staging" / "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r6-prequeued-finite"
SCRIPTS = RUN_ROOT / "scripts"
ARTIFACTS = RUN_ROOT / "artifacts"
PREFIX = "G2B_HW0_PRODUCT_R3R4R6_"
BLOCKER = (
    "R3R4R6_FOCUSED_HOST_TOOL_GATE_FAILED:"
    "NATIVE_HELPER_COMPILES_PASS:NON_DUT_OFFLINE_COMPILER_UNREACHABLE"
)
NATIVE_SHA = "D9F4DA042A02BB55FE8B1BCC990BC2D2001D2F01F5DFB8987094042F9731CCD7"
HELPER_SHA = "677727ED53345BAB68B015714AE3638D45A0C553EF3B84E7B9C1909D742EC79A"
NOW = datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def write_text(name: str, text: str) -> None:
    (STAGING / name).write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def write_json(name: str, data: object) -> None:
    write_text(name, json.dumps(data, indent=2, sort_keys=False))


def write_csv(name: str, header: list[str], rows: list[list[object]]) -> None:
    path = STAGING / name
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def main() -> int:
    if STAGING.exists():
        raise RuntimeError(f"staging path already exists: {STAGING}")
    STAGING.mkdir(parents=True)
    (STAGING / "tools").mkdir()
    (STAGING / "raw").mkdir()

    gate = json.loads((ARTIFACTS / "focused-host-tool-gate.json").read_text(encoding="utf-8"))
    if gate["passed"] != 5 or gate["total"] != 6 or gate["dut_connection"]:
        raise RuntimeError("focused-gate input does not match the governed stop")

    write_text(
        "V41_G2B_HW0_PRODUCT_R3R4R6_MAIN_REPORT.md",
        f"""# AHD v41 G2B-HW0 PRODUCT R3R4R6 Main Report

Generated: `{NOW}`

## Result

- Engineering gate: `BLOCKED`
- Evidence package: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `{BLOCKER}`

The focused pre-DUT host-tool gate completed `5/6 PASS`. The native Linux AIO
helper could not be compiled because the available non-DUT Linux compilation
host at `10.132.1.227:22` timed out. No local Linux compiler/toolchain was
available. The source was not changed after this infrastructure failure, and
the permitted focused correction iteration was not consumed.

The hard gate therefore prevented the first DUT connection. Hardware access,
driver load attempts, MMIO operations, DMA operations, FPGA programming,
reboot, Flash access, and power cycling were all zero. No live capture result
or causal-model conclusion is claimed.

## Owner-attested inputs

- `PROJECT_STATE_REV = 8` (owner-attested, not reverified)
- DUT: `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`
- boot ID: `614295f4-c62b-4430-ae67-06013bea7084`
- endpoint: `0000:01:00.0`, `10ee:7011 / 10ee:0007`, Gen2 x1, unbound
- PRODUCT bitstream SHA-256: `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`
- driver SHA-256: `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`
- ABI SHA-256: `AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6`

These values were accepted exactly as instructed and were not re-audited.

## Focused gate

1. Native helper compiles: `FAIL` — non-DUT compiler host unreachable.
2. No signal interruption in active DMA path: `PASS`.
3. C2H open flags omit `O_TRUNC` and `eop_flush`: `PASS`.
4. Primary and guard requests precede `PREQUEUE_READY`: `PASS`.
5. Parent enable depends on `PREQUEUE_READY`: `PASS`.
6. Integrity/continuity/accounting fixture: `PASS`.

## Governed boundary

- Fresh run root: `{RUN_ROOT}`
- Prior run directories modified by R3R4R6: `NO`
- Fresh credential helper SHA-256: `{HELPER_SHA}`
- Credential remnants: `0`
- Hardware accessed: `NO`
- Raw camera bytes published: `NO`
- SSOT update required: `NO`
""",
    )

    write_text(
        PREFIX + "OWNER_CONTINUITY_ATTESTATION.md",
        """# R3R4R6 Owner Continuity Attestation

Status: `ACCEPTED`

The run accepted the Owner-attested R3R4R5 final state without rechecking
project state, predecessor evidence, hashes, boot ID, JTAG, DONE, PCIe
identity, candidate continuity, or parallel HDMI activity. This is an input
attestation, not a fresh observation. The focused pre-DUT gate stopped the run
before any operational contradiction could be tested.
""",
    )
    write_text(
        PREFIX + "AUTHORIZATION_RECEIPT.md",
        f"""# R3R4R6 Authorization Receipt

- Owner authorization: `GRANTED`
- Authorized correction: task-local prequeued finite host receive architecture
- Fresh run root: `{RUN_ROOT}`
- Maximum focused correction iterations: `1`
- Focused correction iterations used: `0`
- Hardware authorization prerequisite: `FOCUSED_HOST_TOOL_GATE = 6/6 PASS`
- Observed prerequisite: `5/6 PASS`
- Hardware authorization became exercisable: `NO`
- First blocker: `{BLOCKER}`
""",
    )
    details = "\n".join(
        f"- `{case['name']}`: `{case['result']}` — `{json.dumps(case['detail'], ensure_ascii=False)}`"
        for case in gate["cases"]
    )
    write_text(
        PREFIX + "HOST_TOOL_GATE.md",
        f"""# R3R4R6 Focused Host-Tool Gate

Result: `5/6 PASS — BLOCKED BEFORE DUT CONNECTION`

{details}

The compile check attempted a compile-only connection to the non-DUT host
alias `ahd-ubuntu` (`10.132.1.227`). TCP port 22 timed out. The authoritative
DUT address `10.132.1.111` was never contacted. No installed local Linux C
compiler or compatible Linux syscall-header toolchain was available, and
package installation was prohibited.

First blocker: `{BLOCKER}`
""",
    )
    write_text(
        PREFIX + "PREQUEUE_ARCHITECTURE.md",
        """# R3R4R6 Prequeue Architecture

The task-local source implements two 4096-byte-aligned, prefaulted buffers and
raw Linux AIO syscalls (`io_setup`, `io_submit`, `io_getevents`, `io_destroy`).
It orders a 10,240,000-byte primary request before a 4,194,304-byte guard
request and emits metadata-only `PREQUEUE_READY` only after both submissions.
The parent owns MMIO and requires that receipt before enable. Raw data is
persisted only after DMA completion/quiescence.

Static focused checks passed for ordering, MMIO dependency, absence of signal
interruption, absence of `O_TRUNC`/`eop_flush`, and separation of integrity,
continuity, source diagnostics, and byte accounting. Native compilation was
not established, so this architecture was not executed on hardware.
""",
    )
    write_text(
        PREFIX + "PREQUEUE_RECEIPT.md",
        """# R3R4R6 Prequeue Receipt

- Status: `NOT_REACHED`
- Primary requested bytes: `10240000`
- Guard requested bytes: `4194304`
- Total intended prequeue bytes: `14434304`
- Primary submitted before enable: `NO — NOT_EXECUTED`
- Guard submitted before enable: `NO — NOT_EXECUTED`
- PREQUEUE_READY: `NOT_REACHED`
- Stream enable writes: `0`
""",
    )
    write_csv(
        PREFIX + "AIO_COMPLETIONS.csv",
        ["Request", "RequestedBytes", "SubmittedBeforeEnable", "CompletionStatus", "ResultBytes", "FullRecords", "PartialBytes", "Timestamp"],
        [
            ["PRIMARY", 10240000, "NO_NOT_EXECUTED", "NOT_REACHED", 0, 0, 0, "N/A"],
            ["GUARD", 4194304, "NO_NOT_EXECUTED", "NOT_REACHED", 0, 0, 0, "N/A"],
        ],
    )
    shutil.copy2(ARTIFACTS / (PREFIX + "FLAG_PREDICTION.md"), STAGING / (PREFIX + "FLAG_PREDICTION.md"))
    write_text(
        PREFIX + "FLAG_PREDICTION_COMPARISON.md",
        """# R3R4R6 Flag Prediction Comparison

The prediction was frozen before any DUT connection. Comparison status is
`NOT_REACHED` because the focused host-tool gate failed before hardware access.

- First-record prediction: `NOT_REACHED`
- Post-first-record prediction: `NOT_REACHED`
- Clean-frame prediction: `NOT_REACHED`
""",
    )
    write_csv(
        PREFIX + "ERROR_TIMELINE.csv",
        ["Checkpoint", "Epoch", "ErrorStatus", "LastErrorCause", "Attempted", "Committed", "Streamed", "Dropped", "Overflow", "Discontinuity", "Timestamp"],
        [[label, "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "NOT_REACHED"] for label in ("S0", "S1", "S2", "S3")],
    )
    write_csv(
        PREFIX + "MMIO_WRITE_LEDGER.csv",
        ["Sequence", "IntentTimestamp", "CompletionTimestamp", "Offset", "Value", "Purpose", "Status"],
        [],
    )
    write_text(
        PREFIX + "FIRST_RECORD_REPORT.md",
        """# R3R4R6 First Record Report

Status: `NOT_REACHED`

No DUT connection, DMA operation, or capture occurred. No first record or
payload was created, parsed, hashed, or published.
""",
    )
    write_csv(PREFIX + "FIRST_RECORD_HEADER.csv", ["Field", "Value", "Validation"], [])
    write_csv(
        PREFIX + "RECORD_INTEGRITY_METRICS.csv",
        ["Metric", "Value", "Disposition"],
        [
            ["PRIMARY_RECORDS_REQUESTED", 2500, "CONTRACT"],
            ["PRIMARY_RECORDS_RECEIVED", 0, "NOT_REACHED"],
            ["RECORD_INTEGRITY_FAILURES", 0, "NO_RECORDS_OBSERVED"],
            ["STRUCTURAL_HEADER_FAILURES", 0, "NO_RECORDS_OBSERVED"],
            ["PAYLOAD_GEOMETRY_FAILURES", 0, "NO_RECORDS_OBSERVED"],
            ["PADDING_ERRORS", 0, "NO_RECORDS_OBSERVED"],
        ],
    )
    write_csv(
        PREFIX + "STREAM_CONTINUITY_METRICS.csv",
        ["Metric", "Value", "Disposition"],
        [
            ["DISCONTINUITY_FLAG_RECORDS", 0, "NO_RECORDS_OBSERVED"],
            ["OVERFLOW_OCCURRED_FLAG_RECORDS", 0, "NO_RECORDS_OBSERVED"],
            ["MALFORMED_PRECEDING_FLAG_RECORDS", 0, "NO_RECORDS_OBSERVED"],
            ["GLOBAL_SEQUENCE_GAPS", 0, "NO_RECORDS_OBSERVED"],
            ["ATTEMPT_SEQUENCE_GAPS", 0, "NO_RECORDS_OBSERVED"],
            ["SOURCE_PROGRESSION_BREAKS", 0, "NO_RECORDS_OBSERVED"],
        ],
    )
    write_csv(
        PREFIX + "MALFORMED_PRECEDING_TIMELINE.csv",
        ["RecordIndex", "Epoch", "Frame", "Line", "Flags", "SourceMalformedSnapshot", "SourceDroppedSnapshot", "GlobalSequence", "AttemptSequence", "BeforeCleanSOF", "InsideQualifiedFrame"],
        [],
    )
    write_text(
        PREFIX + "HOST_DMA_ACCOUNTING.md",
        """# R3R4R6 Host DMA Accounting

Status: `NOT_REACHED`

No DMA request was submitted and no host or FPGA transfer counters were
sampled. Consequently host returned bytes, partial bytes, streamed bytes, and
unreaped bytes are all `N/A`; no accounting classification is claimed.
""",
    )
    write_text(
        PREFIX + "COUNTER_RECONCILIATION.md",
        """# R3R4R6 Counter Reconciliation

Status: `NOT_REACHED`

Baseline and final coherent snapshots were not requested. All counter values
and deltas are `N/A`.
""",
    )
    write_text(
        PREFIX + "FRAME_RECONSTRUCTION_REPORT.md",
        """# R3R4R6 Frame Reconstruction Report

Status: `NOT_REACHED`

No camera records were captured. No UYVY frame or PNG was created or
published.
""",
    )
    write_text(
        PREFIX + "PCIE_AER_KERNEL_REVIEW.md",
        """# R3R4R6 PCIe, AER, and Kernel Review

Status: `NOT_REACHED`

The pre-DUT host-tool gate blocked the run. No driver load or hardware health
collection occurred. The initial kernel taint value `12288` remains an
Owner-attested input only; no final value was read.
""",
    )
    write_text(
        PREFIX + "CLEANUP_RECEIPT.md",
        """# R3R4R6 Cleanup Receipt

- Cleanup status: `NOT_REQUIRED_PRE_HARDWARE`
- Task-owned reader processes started: `0`
- AIO contexts created on DUT: `0`
- C2H descriptors opened on DUT: `0`
- MMIO descriptors opened on DUT: `0`
- Stream enable writes: `0`
- Driver load attempts: `0`
- Driver unload operations: `0`
- Linux locks acquired: `0`
- Controller hardware locks acquired: `0`
- Credential remnants: `0`
""",
    )
    write_text(
        PREFIX + "FINAL_STATE.md",
        f"""# R3R4R6 Final State

- Engineering gate: `BLOCKED`
- First blocker: `{BLOCKER}`
- Hardware accessed: `NO`
- Driver load attempts: `0`
- MMIO operations: `0`
- DMA operations: `0`
- FPGA programming: `NO`
- Warm reboot: `NO`
- Flash programming: `NO`
- Power-cycle: `NO`
- Prior run directories modified by R3R4R6: `NO`
- Persistent filesystem/system installation modified: `NO`
- Credential remnants: `0`
- Owner-attested volatile PRODUCT candidate disturbed: `NO`
""",
    )
    write_csv(
        PREFIX + "GATE_MATRIX.csv",
        ["Gate", "Result", "Evidence"],
        [
            ["OWNER_CONTINUITY_ATTESTATION", "PASS", "accepted without reverification"],
            ["FRESH_RUN_ROOT", "PASS", str(RUN_ROOT)],
            ["FRESH_CREDENTIAL_HELPER_MINIMAL_AUDIT", "PASS", HELPER_SHA],
            ["NATIVE_HELPER_COMPILES", "FAIL", "non-DUT compiler host TCP/22 timeout"],
            ["NO_ACTIVE_DMA_SIGNAL_INTERRUPTION", "PASS", "static source check"],
            ["C2H_OPEN_FLAGS", "PASS", "no O_TRUNC or eop_flush"],
            ["TWO_AIO_REQUESTS_PREQUEUED", "PASS", "static ordering proof"],
            ["PREQUEUE_READY_ENABLE_DEPENDENCY", "PASS", "static controller dependency"],
            ["METRIC_SPLIT_FIXTURE", "PASS", "record integrity kept independent"],
            ["FOCUSED_HOST_TOOL_GATE", "FAIL", "5/6"],
            ["DUT_CONNECTION", "NOT_REACHED", "hard gate stopped access"],
            ["DRIVER_LOAD", "NOT_REACHED", "0 attempts"],
            ["FINITE_PREQUEUED_CAPTURE", "NOT_REACHED", "no DMA"],
            ["RECORD_PATH_INTEGRITY", "NOT_REACHED", "no records"],
            ["STREAM_CONTINUITY", "NOT_REACHED", "no records"],
            ["BT656_SOURCE_QUALIFICATION", "NOT_REACHED", "no records"],
            ["HOST_DMA_ACCOUNTING", "NOT_REACHED", "no transfer"],
            ["COMPLETE_FRAME", "NOT_REACHED", "no capture"],
            ["ENGINEERING_GATE", "BLOCKED", BLOCKER],
            ["EVIDENCE_PUBLICATION", "PENDING", "commit-pinned readback pending"],
        ],
    )

    state = {
        "schema": "R3R4R6_STATE_V1",
        "task": "G2B-HW0-PRODUCT-R3R4R6",
        "generated_utc": NOW,
        "engineering_gate": "BLOCKED",
        "evidence_publication": "PENDING_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
        "owner_continuity_attestation": "ACCEPTED",
        "fresh_run_root": str(RUN_ROOT),
        "prior_run_directories_modified_by_r3r4r6": "NO",
        "focused_host_tool_gate": {"passed": 5, "total": 6, "result": "FAIL", "correction_iterations_used": 0},
        "native_helper": {"path": str(SCRIPTS / "prequeued_c2h_capture.c"), "sha256": NATIVE_SHA, "compiled": False},
        "credential_helper": {
            "path": str(SCRIPTS / "Invoke-R3R4R6DutConnection.ps1"),
            "sha256": HELPER_SHA,
            "syntax": "PASS",
            "exact_target_ip_only": True,
            "credentials_in_command_line_arguments": False,
            "credential_remnants": 0,
        },
        "hardware": {
            "accessed": False,
            "dut_connections": 0,
            "driver_load_attempts": 0,
            "mmio_operations": 0,
            "dma_operations": 0,
            "fpga_programming": False,
            "warm_reboot": False,
            "flash_programming": False,
            "power_cycle": False,
        },
        "requested_capture": {"primary_records": 2500, "primary_bytes": 10240000, "guard_bytes": 4194304, "total_bytes": 14434304},
        "capture": {"status": "NOT_REACHED", "primary_records": 0, "primary_bytes": 0},
        "working_causal_model": "NOT_REACHED",
        "ssot_update_required": "NO",
        "raw_camera_data_published": False,
    }
    write_json(PREFIX + "STATE.json", state)

    shutil.copy2(ARTIFACTS / "focused-host-tool-gate.json", STAGING / "raw" / "focused-host-tool-gate.json")
    write_json(
        "raw/credential-helper-focused-audit.json",
        {
            "schema": "R3R4R6_CREDENTIAL_HELPER_FOCUSED_AUDIT_V1",
            "syntax": "PASS",
            "exact_target_ip": "10.132.1.111",
            "exact_target_ip_only": True,
            "uses_pwfile": True,
            "direct_password_argument": False,
            "credential_remnants": 0,
            "sha256": HELPER_SHA,
        },
    )

    tool_names = [
        "prequeued_c2h_capture.c",
        "controller_r3r4r6.py",
        "validate_r3r4r6.py",
        "frame_reconstruct_r3r4.py",
        "focused_selftest_r3r4r6.py",
        "Invoke-R3R4R6DutConnection.ps1",
        "abi_v1.py",
        "V41_C2H_TRANSPORT_ABI_V1.json",
        "publish_evidence_r3r4r6.py",
    ]
    for tool_name in tool_names:
        shutil.copy2(SCRIPTS / tool_name, STAGING / "tools" / tool_name)

    tool_rows: list[list[object]] = []
    for path in sorted((STAGING / "tools").iterdir(), key=lambda item: item.name.lower()):
        tool_rows.append([path.name, path.stat().st_size, sha256(path)])
    write_csv(PREFIX + "TOOL_INVENTORY.csv", ["Tool", "Bytes", "SHA256"], tool_rows)

    files_for_index = sorted(
        p.relative_to(STAGING).as_posix()
        for p in STAGING.rglob("*")
        if p.is_file() and p.name not in {PREFIX + "EVIDENCE_INDEX.md", PREFIX + "SHA256_MANIFEST.txt"}
    )
    write_text(
        PREFIX + "EVIDENCE_INDEX.md",
        "# R3R4R6 Evidence Index\n\n"
        + "\n".join(f"- `{name}`" for name in files_for_index)
        + "\n\nRaw primary/guard bytes, partial bytes, UYVY frames, and camera PNG files published: `0`.\n",
    )

    manifest_paths = sorted(
        p for p in STAGING.rglob("*") if p.is_file() and p.name != PREFIX + "SHA256_MANIFEST.txt"
    )
    manifest = "\n".join(f"{sha256(path)}  {path.relative_to(STAGING).as_posix()}" for path in manifest_paths)
    write_text(PREFIX + "SHA256_MANIFEST.txt", manifest)

    print(json.dumps({"staging": str(STAGING), "files": sum(1 for p in STAGING.rglob('*') if p.is_file()), "blocker": BLOCKER}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
