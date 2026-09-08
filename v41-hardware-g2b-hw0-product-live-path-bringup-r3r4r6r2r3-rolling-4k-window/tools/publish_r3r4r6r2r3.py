#!/usr/bin/env python3
"""Create the sanitized R3R4R6R2R3 evidence package without raw camera data."""

from __future__ import annotations

import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R3"
ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R3_20260908T102555Z")
EVIDENCE_NAME = (
    "v41-hardware-g2b-hw0-product-live-path-bringup-"
    "r3r4r6r2r3-rolling-4k-window"
)
OUT = ROOT / "evidence-staging" / EVIDENCE_NAME
PREFIX = "G2B_HW0_PRODUCT_R3R4R6R2R3_"
REMOTE = "/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r3/20260908T102555Z"
GOVERNED_USER_TOKEN = "<GOVERNED_USER_REDACTED>"
PUBLIC_USER_PLACEHOLDER = "<GOVERNED_USER_REDACTED>"
FIRST_BLOCKER = "R3R4R6R2R3_PHYSICAL_QUIESCENCE_NOT_PROVEN"
CLEANUP_BLOCKER = "R3R4R6R2R3_GUARD_AIO_CLEANUP_UNRESOLVED"
GENERATED = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def clean(text: str) -> str:
    return text.replace(GOVERNED_USER_TOKEN, PUBLIC_USER_PLACEHOLDER)


def write_text(name: str, value: str) -> None:
    (OUT / name).write_text(clean(value.rstrip()) + "\n", encoding="utf-8", newline="\n")


def write_json(name: str, value: object) -> None:
    write_text(name, json.dumps(value, indent=2, ensure_ascii=False))


def write_csv(name: str, fields: list[str], rows: list[dict[str, object]]) -> None:
    with (OUT / name).open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: clean(str(row.get(field, ""))) for field in fields})


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def copy_text(source: Path, target: str) -> None:
    write_text(target, source.read_text(encoding="utf-8-sig"))


if OUT.exists():
    raise SystemExit(f"fresh evidence directory already exists: {OUT}")
OUT.mkdir(parents=True)
(OUT / "tools").mkdir()
(OUT / "support").mkdir()

build = read_json(ROOT / "artifacts" / "native-build.json")
host_gate = read_json(ROOT / "artifacts" / "host-tool-gate.json")
controller = read_json(ROOT / "logs" / "controller-result.json")
validation = read_json(ROOT / "logs" / "validation-result.json")
health_receipt = read_json(ROOT / "logs" / "connection-minimal-kernel-health.json")
driver_receipt = read_json(ROOT / "logs" / "connection-driver-operational-branch.json")
pending_receipt = read_json(ROOT / "logs" / "connection-pending-helper-targeted-state.json")

with (ROOT / "logs" / "primary-record-metrics.csv").open(
        encoding="utf-8-sig", newline="") as handle:
    record_rows = list(csv.DictReader(handle))
with (ROOT / "logs" / "malformed-preceding-timeline.csv").open(
        encoding="utf-8-sig", newline="") as handle:
    malformed_rows = list(csv.DictReader(handle))
with (ROOT / "logs" / "error-timeline.csv").open(
        encoding="utf-8-sig", newline="") as handle:
    checkpoint_rows = list(csv.DictReader(handle))
with (ROOT / "logs" / "quiescence-samples.csv").open(
        encoding="utf-8-sig", newline="") as handle:
    quiescence_rows = list(csv.DictReader(handle))

events = controller["events"]
progress = [event for event in events if event.get("type") == "ROLLING_PROGRESS"]
prequeue = controller["rolling_prequeue_ready"]
primary = controller["primary_completion"]
sp = controller["SP"]
mmio_counts = controller["mmio_write_counts"]

primary_duration_ms = float(primary["elapsed_capture_seconds"]) * 1000.0
primary_records_per_second = 2500.0 / float(primary["elapsed_capture_seconds"])
primary_bytes_per_second = 10240000.0 / float(primary["elapsed_capture_seconds"])
max_refill_us = max(float(item["maximum_completion_to_refill_latency_us"])
                    for item in progress)
last_progress = max(int(item["primary_completed"]) for item in progress)
overflow_indices = [int(row["RecordIndex"]) for row in record_rows
                    if row.get("Flags") and int(row["Flags"], 16) & 0x08]
discontinuity_indices = [int(row["RecordIndex"]) for row in record_rows
                         if row.get("Flags") and int(row["Flags"], 16) & 0x04]
malformed_indices = [int(row["RecordIndex"]) for row in record_rows
                     if row.get("Flags") and int(row["Flags"], 16) & 0x10]

state = {
    "schema": "R3R4R6R2R3_STATE_V1",
    "task": TASK,
    "generated_utc": GENERATED,
    "engineering_gate": "FAIL",
    "evidence_publication": "PASS",
    "overall_result": "FAIL",
    "first_blocker": FIRST_BLOCKER,
    "cleanup_blocker": CLEANUP_BLOCKER,
    "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
    "owner_confirmed_unchanged_environment": "ACCEPTED",
    "environment_prechecks": "SKIPPED_BY_OWNER_DECISION",
    "same_codex_window": True,
    "fresh_run_root": str(ROOT),
    "remote_run_root": REMOTE,
    "prior_run_directories_modified": False,
    "artifact_reverification": {"bitstream": False, "driver": False, "abi": False},
    "hardware_changes": {
        "fpga_programming": False, "warm_reboot": False, "cold_reset": False,
        "power_cycle": False, "bitstream_changed": False,
        "driver_changed": False, "abi_changed": False, "ssot_changed": False,
    },
    "connection": {"direct_ssh": "PASS", "attempts": 1},
    "locks": {"controller": "HELD", "linux": "HELD", "released": False},
    "native_helper": {
        "source": str(ROOT / "scripts" / "xdma_c2h_rolling_4k.c"),
        "source_sha256": build["source_sha256"],
        "binary_sha256": build["binary_sha256"],
        "binary_size": build["binary_size"],
        "architecture": "x86-64",
        "compiler": build["compiler"],
        "compiler_version": build["compiler_version"],
        "host_tool_gate": "14/14 PASS",
        "process_id": 6055,
        "normal_exit": False,
    },
    "driver": {
        "state": "LOADED_ONCE", "user_node": "/dev/xdma0_user",
        "c2h_node": "/dev/xdma0_c2h_0", "unloaded": False,
        "nodes_removed": False,
    },
    "source_readiness": controller["source_readiness"],
    "session": {
        "S0": controller["S0"], "S1": controller["S1"],
        "S2": controller["S2"], "SP": sp, "S3": None,
        "reset_epoch_transition": "PASS",
        "normalization_w1c": (f"0x{controller['session_normalization_w1c_mask']:08X}"
                               if controller["session_normalization_w1c_mask"] else "NONE"),
        "write_counts": mmio_counts,
        "unauthorized_mmio_writes": 0,
    },
    "rolling_window": {
        "initial_submitted": prequeue["initial_submitted_requests"],
        "total_submitted": progress[-1]["total_submitted"],
        "primary_submitted": 2500, "guard_submitted": 32,
        "max_permitted_outstanding": 1024,
        "max_outstanding_observed": primary["maximum_outstanding"],
        "min_outstanding_after_enable": primary["minimum_outstanding_after_enable"],
        "descriptor_window_violations": 0,
        "descriptor_starvation_events": 0,
        "logical_index_2048_crossed_safely": True,
        "io_submit_calls": progress[-1]["io_submit_call_count"],
        "io_getevents_calls": None,
        "temporary_eagain": progress[-1]["temporary_eagain_count"],
        "max_completion_batch": None,
        "max_refill_latency_us": max_refill_us,
        "average_refill_latency_us": None,
        "result": "PASS",
    },
    "primary": {
        "result": "PASS", "records": 2500, "bytes": 10240000,
        "exact_completions": 2500, "short_completions": 0,
        "failed_completions": 0, "pending": 0,
        "durable": True,
        "sha256": validation["primary_file_sha256"],
        "capture_duration_ms": primary_duration_ms,
        "records_per_second": primary_records_per_second,
        "bytes_per_second": primary_bytes_per_second,
        "prequeue_to_enable_us": controller["prequeue_ready_to_enable_latency_us"],
        "primary_complete_to_disable_us": controller["primary_complete_to_disable_us"],
    },
    "validation": validation,
    "primary_overflow_indices": overflow_indices,
    "primary_discontinuity_indices": discontinuity_indices,
    "primary_malformed_preceding_indices": malformed_indices,
    "guard": {
        "exact_completions": None, "canceled": None,
        "positive_short": None, "failed": None, "pending": None,
        "result": "NOT_REACHED",
    },
    "post_target_shutdown_tail": "UNRESOLVED",
    "physical_quiescence": {
        "result": "FAIL", "sample_count": len(quiescence_rows),
        "last_control": quiescence_rows[-1]["Control"],
        "last_status": quiescence_rows[-1]["Status"],
    },
    "cleanup": {
        "result": "BLOCKED", "helper_left_running": True,
        "driver_unloaded": False, "nodes_removed": False,
        "locks_released": False, "forced_action": False,
    },
    "decisions": {
        "rolling_descriptor_window": "PASS",
        "primary_aio_capture": "PASS",
        "primary_record_integrity": "PASS",
        "primary_stream_continuity": "FAIL",
        "bt656_source_qualification": validation["bt656_source_qualification"],
        "complete_frame": "FAIL",
        "shutdown_guard": "NOT_REACHED",
        "hardware_subqualification": "NOT_PROVEN",
        "working_causal_model": "HOST_PREQUEUE_CONFIRMED_ROLLING_WINDOW_REQUIRES_CORRECTION",
    },
    "nonclaims": {
        "continuous_60_second_performance": "NOT_RUN",
        "hardware_throughput_288_mb_s": "NOT_PROVEN",
        "two_channel": "NOT_QUALIFIED", "four_input": "NOT_QUALIFIED",
        "synthetic_generator": "NOT_TESTED", "v4l2": "NOT_TESTED",
    },
}

write_text(
    "V41_G2B_HW0_PRODUCT_R3R4R6R2R3_MAIN_REPORT.md",
    f"""# AHD v41 G2B-HW0 PRODUCT R3R4R6R2R3 main report

## Result

- Engineering gate: **FAIL**
- Evidence package: **PASS** (commit identifier reported out of band)
- Overall result: **FAIL**
- First blocker: `{FIRST_BLOCKER}`
- Cleanup blocker: `{CLEANUP_BLOCKER}`

## Governed scope

Owner continuity was accepted. No boot, artifact-hash, JTAG, PCIe-topology,
node-to-BDF, SSOT, Git, or predecessor requalification was repeated. No FPGA
programming, reboot, power-cycle, Flash access, package installation, driver
change, ABI change, bitstream change, SSOT change, capture retry, forced process
termination, or forced unload occurred.

## Host receive result

The device-free rolling-host gate passed 14/14. The new x86-64 helper initially
submitted 1024 4096-byte IOCBs, never observed more than 1024 outstanding, safely
crossed cumulative submission 2048, and submitted all 2532 logical requests.
`PRIMARY_WINDOW_COMPLETE` reported 2500 exact primary completions, zero short,
zero failed, zero pending, and 10,240,000 bytes. Capture duration from helper
start was {primary_duration_ms:.6f} ms. The primary file was durably preserved
with SHA-256 `{validation['primary_file_sha256']}`.

## Independent record and stream results

All 2500 fixed-boundary records passed structural integrity. Global sequence was
exactly 0..2499 with zero gaps. Record 441 carried both DISCONTINUITY and
OVERFLOW_OCCURRED, so primary zero-overflow continuity failed. Records 575 and
1654 carried MALFORMED_PRECEDING; the source malformed snapshot increased by
{validation['source_malformed_snapshot_delta']}. No clean SOF/line-zero record
was present, so a complete clean 1920x1080 frame could not be reconstructed.

## Disable, tail, and retained safe state

The normal disable was issued {controller['primary_complete_to_disable_us']:.3f}
microseconds after the primary event. At SP, CONTROL was zero but STATUS was
`0x{sp['Status']:08X}`; counters were attempted {sp['Attempted']}, committed
{sp['Committed']}, streamed {sp['Streamed']}, dropped {sp['Dropped']}, overflow
{sp['Overflow']}, discontinuity {sp['Discontinuity']}, and beats
{sp['BeatsStreamed']}. The four committed-but-not-streamed records explain the
nonempty ring state. Five-sample quiescence never began because every sample was
nonquiescent; the last status remained `{quiescence_rows[-1]['Status']}`.

The helper PID 6055, exact module, XDMA nodes, and both fresh locks are retained.
No PARENT_QUIESCENT command, signal, forced unload, reset, or reboot was used.
Raw primary bytes, first-record bytes, frame bytes, and camera images are private
and are not in this package.
""",
)

copy_text(ROOT / "artifacts" / f"{PREFIX}OWNER_CONTINUITY_ATTESTATION.md",
          PREFIX + "OWNER_CONTINUITY_ATTESTATION.md")
write_text(PREFIX + "AUTHORIZATION_RECEIPT.md", f"""# Authorization receipt

Owner authorization was applied only to the fresh `{TASK}` root, DUT-local
build, 14-case device-free gate, one exact hardware session, documented MMIO,
post-failure read-only validation, safe evidence preservation, and publication.
Capture attempts: 1. FPGA programming: 0. Reboots: 0. Power cycles: 0. JTAG
accesses: 0. Unauthorized MMIO writes: 0.
""")
write_text(PREFIX + "REUSE_RECEIPT.md", f"""# Tool reuse receipt

The R3R4R6R2R2 controller, ABI parser, record validator, stream analysis, frame
tool, connection helper, and publication architecture were copied into the fresh
root. Changes were limited to task identity, fresh paths, rolling-AIO metadata,
the 1024-outstanding refill controller, and bounded guard-cleanup fields. Existing
bitstream, driver, and ABI hashes were accepted and were not recomputed.

Accepted baseline native source SHA-256: `7C13B835DCC037EF529BC915EF045B661BA4166AF6F5B002ED63E7787890A0FB`

New rolling native source SHA-256: `{build['source_sha256']}`
""")
write_text(PREFIX + "NATIVE_HELPER_BUILD.md", f"""# Native helper build

- Result: PASS
- Compiler: `{build['compiler']}`
- Version: `{build['compiler_version']}`
- Command: `{' '.join(build['compile_command'])}`
- Source SHA-256: `{build['source_sha256']}`
- Binary SHA-256: `{build['binary_sha256']}`
- Binary size: {build['binary_size']}
- ELF architecture: x86-64
- Compile correction iterations: 0
- Compiled executable published: NO
""")
write_text(PREFIX + "HOST_TOOL_GATE.md", "# Rolling 4-KiB host-tool gate\n\n" +
           f"Result: **{host_gate['passed']}/{host_gate['total']} {host_gate['result']}**\n\n" +
           "\n".join(f"- {item['case']}: {item['result']}" for item in host_gate["cases"]))
copy_text(ROOT / "artifacts" / f"{PREFIX}ROLLING_WINDOW_DESIGN.md",
          PREFIX + "ROLLING_WINDOW_DESIGN.md")
write_text(PREFIX + "PREQUEUE_RECEIPT.md", f"""# Rolling prequeue receipt

- Event: ROLLING_PREQUEUE_READY
- Initial submitted: {prequeue['initial_submitted_requests']}
- Initial outstanding: {prequeue['current_outstanding']}
- Maximum permitted outstanding: {prequeue['maximum_permitted_outstanding']}
- Next logical index: {prequeue['next_logical_request_index']}
- Primary requests: {prequeue['primary_total']}
- Guard requests: {prequeue['guard_total']}
- Context capacity: {prequeue['aio_context_capacity']}
- Allocated bytes: {prequeue['total_allocated_bytes']}
- Alignment: {prequeue['buffer_alignment']}
- Prefault: PASS
- PREQUEUE_READY-to-enable: {controller['prequeue_ready_to_enable_latency_us']} us
""")
copy_text(ROOT / "logs" / "rolling-progress.jsonl", PREFIX + "ROLLING_PROGRESS.jsonl")

submission_rows = [{
    "Event": "ROLLING_PREQUEUE_READY", "PrimaryCompleted": 0,
    "TotalSubmitted": prequeue["initial_submitted_requests"],
    "CurrentOutstanding": prequeue["current_outstanding"],
    "NextLogicalIndex": prequeue["next_logical_request_index"],
    "MonotonicNs": prequeue["monotonic_ns"],
}] + [{
    "Event": item["type"], "PrimaryCompleted": item["primary_completed"],
    "TotalSubmitted": item["total_submitted"],
    "CurrentOutstanding": item["current_outstanding"],
    "NextLogicalIndex": item["next_logical_request_index"],
    "MonotonicNs": item["monotonic_ns"],
} for item in progress]
write_csv(PREFIX + "AIO_SUBMISSIONS.csv",
          ["Event", "PrimaryCompleted", "TotalSubmitted", "CurrentOutstanding",
           "NextLogicalIndex", "MonotonicNs"], submission_rows)
completion_rows = [{
    "PrimaryCompleted": item["primary_completed"],
    "LastLogicalIndex": item["last_completed_logical_index"],
    "LastResultBytes": item["last_completion_result"],
    "TotalCompleted": item["total_completed"],
    "CurrentOutstanding": item["current_outstanding"],
    "MonotonicNs": item["monotonic_ns"],
    "EvidenceClass": "DURABLE_PROGRESS_MILESTONE",
} for item in progress]
write_csv(PREFIX + "AIO_COMPLETIONS.csv",
          ["PrimaryCompleted", "LastLogicalIndex", "LastResultBytes",
           "TotalCompleted", "CurrentOutstanding", "MonotonicNs", "EvidenceClass"],
          completion_rows)
descriptor_rows = [
    {"Metric": "INITIAL_PREQUEUE", "Value": 1024, "Basis": "ROLLING_PREQUEUE_READY"},
    {"Metric": "TOTAL_LOGICAL_SUBMITTED", "Value": 2532, "Basis": "ROLLING_PROGRESS"},
    {"Metric": "MAX_OUTSTANDING", "Value": 1024, "Basis": "PRIMARY_WINDOW_COMPLETE"},
    {"Metric": "MIN_OUTSTANDING_PRIMARY_WINDOW", "Value": 32, "Basis": "PRIMARY_WINDOW_COMPLETE"},
    {"Metric": "DESCRIPTOR_WINDOW_VIOLATIONS", "Value": 0, "Basis": "event invariant"},
    {"Metric": "DESCRIPTOR_STARVATION_EVENTS", "Value": 0, "Basis": "rolling progress"},
    {"Metric": "INDEX_2048_CROSSED_SAFELY", "Value": "YES", "Basis": "cumulative submissions"},
    {"Metric": "IO_SUBMIT_CALLS", "Value": progress[-1]["io_submit_call_count"], "Basis": "rolling progress"},
    {"Metric": "IO_GETEVENTS_CALLS", "Value": "N/A", "Basis": "helper cleanup unresolved"},
    {"Metric": "TEMPORARY_EAGAIN", "Value": 0, "Basis": "rolling progress"},
    {"Metric": "MAX_REFILL_LATENCY_US", "Value": max_refill_us, "Basis": "rolling progress"},
]
write_csv(PREFIX + "DESCRIPTOR_WINDOW_METRICS.csv",
          ["Metric", "Value", "Basis"], descriptor_rows)
write_csv(PREFIX + "GUARD_COMPLETIONS.csv",
          ["Status", "ExactCompletions", "PositiveShort", "Failed", "Pending"],
          [{"Status": "NOT_DURABLY_AVAILABLE_GUARD_CLEANUP_UNRESOLVED",
            "ExactCompletions": "N/A", "PositiveShort": "N/A",
            "Failed": "N/A", "Pending": "N/A"}])
write_csv(PREFIX + "GUARD_CANCELLATIONS.csv",
          ["Status", "Canceled", "Pending"],
          [{"Status": "NOT_REACHED_PHYSICAL_QUIESCENCE_FAILED",
            "Canceled": "N/A", "Pending": "N/A"}])
copy_text(ROOT / "artifacts" / f"{PREFIX}FLAG_PREDICTION.md",
          PREFIX + "FLAG_PREDICTION.md")
write_text(PREFIX + "FLAG_PREDICTION_COMPARISON.md", f"""# Flag prediction comparison

- First-record prediction: {validation['first_record_prediction']}
- Post-first-record prediction: {validation['post_first_record_prediction']}
- Clean-frame prediction: {validation['clean_frame_prediction']}
- Primary OVERFLOW_OCCURRED records: {validation['overflow_flag_records']} at {overflow_indices}
- Primary MALFORMED_PRECEDING records: {validation['malformed_preceding_flag_records']} at {malformed_indices}

The prediction was frozen before stream enable and was not modified after data
became available.
""")
copy_text(ROOT / "logs" / "error-timeline.csv", PREFIX + "ERROR_TIMELINE.csv")
copy_text(ROOT / "logs" / "error-timeline.csv", PREFIX + "COUNTER_CHECKPOINTS.csv")
copy_text(ROOT / "logs" / "mmio-write-ledger.csv", PREFIX + "MMIO_WRITE_LEDGER.csv")
write_text(PREFIX + "FIRST_RECORD_REPORT.md", f"""# First primary record

- Bytes: 4096
- SHA-256: `{validation['first_record_sha256']}`
- Payload SHA-256: `{validation['first_payload_sha256']}`
- Integrity: {validation['first_record_integrity']}
- Continuity: {validation['first_record_continuity']}
- Flags: `{validation['first_record_flags']}`

The first record is structurally integral. Its DISCONTINUITY flag is classified
as startup continuity metadata, not header corruption.
""")
copy_text(ROOT / "logs" / "first-record-header.csv", PREFIX + "FIRST_RECORD_HEADER.csv")

published_record_rows = []
for row in record_rows:
    published_record_rows.append({
        "LogicalRequestIndex": row["RecordIndex"],
        "CompletionOrder": "NOT_DURABLY_AVAILABLE",
        **row,
    })
record_fields = ["LogicalRequestIndex", "CompletionOrder"] + list(record_rows[0].keys())
write_csv(PREFIX + "PRIMARY_RECORD_METRICS.csv", record_fields, published_record_rows)
write_csv(PREFIX + "GUARD_RECORD_METRICS.csv",
          ["Status", "Reason"],
          [{"Status": "NOT_REACHED",
            "Reason": "physical quiescence failed; guard table not finalized"}])
copy_text(ROOT / "logs" / "stream-continuity-metrics.csv",
          PREFIX + "STREAM_CONTINUITY_METRICS.csv")
published_malformed = [{
    "Window": "PRIMARY", "LogicalIndex": row["RecordIndex"], **row,
} for row in malformed_rows]
malformed_fields = ["Window", "LogicalIndex"] + list(malformed_rows[0].keys())
write_csv(PREFIX + "MALFORMED_PRECEDING_TIMELINE.csv",
          malformed_fields, published_malformed)
write_text(PREFIX + "WINDOW_CLASSIFICATION.md", f"""# Primary and shutdown-window classification

- Rolling descriptor window: PASS
- Primary AIO capture: PASS
- Primary record integrity: PASS
- Primary stream continuity: FAIL
- Primary global sequence: {validation['global_sequence_first']}..{validation['global_sequence_last']}
- Primary global gaps: {validation['global_sequence_gaps']}
- Primary overflow records: {overflow_indices}
- BT.656 source qualification: {validation['bt656_source_qualification']}
- Post-target shutdown tail: UNRESOLVED

The primary window is not classified clean because an OVERFLOW_OCCURRED flag is
already present at primary record 441. Later SP drop/overflow evidence therefore
cannot be used to retroactively relabel the entire failure as guard-only.
""")
write_text(PREFIX + "FRAME_RECONSTRUCTION_REPORT.md", f"""# Frame reconstruction

- Result: FAIL
- First clean SOF index: {validation['first_clean_sof_index']}
- Qualified primary range: N/A
- Geometry: N/A
- Raw-frame SHA-256: NONE
- Viewable-frame SHA-256: NONE

No clean SOF/line-zero record was present. The source advanced from line 1079 to
line 1 with MALFORMED_PRECEDING at primary records 575 and 1654, so no eligible
1080-line frame could be selected.
""")
write_text(PREFIX + "PCIE_AER_KERNEL_REVIEW.md", f"""# Minimal PCIe/AER/kernel review

The active-session kernel health sample contains the expected out-of-tree and
unsigned-module taint messages and normal XDMA probe messages. It contains no new
AHD-related Oops, BUG, call trace, DMA-API fault, IOMMU fault, AER fatal/nonfatal
event, malformed TLP, unsupported request, or engine fatal error.

Active-session health: PASS. Post-unload checkpoint: NOT_REACHED because unload
was prohibited while quiescence and guard cleanup were unresolved.

Sanitized captured output:

```text
{health_receipt['stdout'].strip()}
```
""")
write_text(PREFIX + "CLEANUP_RECEIPT.md", f"""# Cleanup receipt

- Normal stream-disable writes: {mmio_counts['NORMAL_DISABLE']}
- Safety-disable writes: {mmio_counts['SAFETY_DISABLE']}
- Physical quiescence: FAIL
- Last observed CONTROL: {quiescence_rows[-1]['Control']}
- Last observed STATUS: {quiescence_rows[-1]['Status']}
- PARENT_QUIESCENT sent: NO
- Guard cancellation: NOT_REACHED
- Final pending AIO: N/A
- Helper normal exit: NO
- Task helper PID retained: 6055
- Driver unload: NOT PERFORMED
- XDMA nodes removed: NO
- Linux lock released: NO
- Controller lock released: NO
- Forced signal, forced unload, reset, reboot, JTAG, or power cycle: NO

Safe cleanup is blocked by `{CLEANUP_BLOCKER}`. The retained state is intentional
and requires a new Owner-authorized corrective task.
""")
write_text(PREFIX + "FINAL_STATE.md", f"""# Final state

CONTROL was last observed as zero, but physical DMA quiescence was not proven:
STATUS remained `{quiescence_rows[-1]['Status']}` for all bounded samples. The
task-owned helper remains active, the exact XDMA module remains loaded, expected
nodes remain present, and both fresh locks remain held. Private primary data is
preserved. No automatic recovery action was authorized or taken.
""")

gate_rows = [
    {"Gate": "OWNER_CONTINUITY", "Result": "PASS", "FirstFailure": "NO", "Evidence": "accepted"},
    {"Gate": "DIRECT_SSH", "Result": "PASS", "FirstFailure": "NO", "Evidence": "one direct attempt"},
    {"Gate": "FRESH_LOCKS", "Result": "PASS", "FirstFailure": "NO", "Evidence": "controller and Linux held"},
    {"Gate": "ROLLING_HOST_TOOL_14", "Result": "PASS", "FirstFailure": "NO", "Evidence": "14/14"},
    {"Gate": "DRIVER_AND_NODES", "Result": "PASS", "FirstFailure": "NO", "Evidence": "LOADED_ONCE"},
    {"Gate": "SOURCE_READINESS", "Result": "PASS", "FirstFailure": "NO", "Evidence": "NVP ready and locked"},
    {"Gate": "ROLLING_DESCRIPTOR_WINDOW", "Result": "PASS", "FirstFailure": "NO", "Evidence": "2532 submitted max 1024"},
    {"Gate": "PRIMARY_AIO_CAPTURE", "Result": "PASS", "FirstFailure": "NO", "Evidence": "2500 exact 10,240,000 bytes"},
    {"Gate": "PHYSICAL_QUIESCENCE", "Result": "FAIL", "FirstFailure": "YES", "Evidence": FIRST_BLOCKER},
    {"Gate": "PRIMARY_RECORD_INTEGRITY", "Result": "PASS", "FirstFailure": "NO", "Evidence": "0 structural failures"},
    {"Gate": "PRIMARY_STREAM_CONTINUITY", "Result": "FAIL", "FirstFailure": "NO", "Evidence": "primary overflow at 441"},
    {"Gate": "BT656_SOURCE_QUALIFICATION", "Result": "OPEN", "FirstFailure": "NO", "Evidence": "recurring malformed preceding"},
    {"Gate": "COMPLETE_FRAME", "Result": "FAIL", "FirstFailure": "NO", "Evidence": "no clean SOF"},
    {"Gate": "SHUTDOWN_GUARD", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": CLEANUP_BLOCKER},
    {"Gate": "NORMAL_CLEANUP", "Result": "BLOCKED", "FirstFailure": "NO", "Evidence": "retained safe state"},
    {"Gate": "EVIDENCE_STAGING", "Result": "PASS", "FirstFailure": "NO", "Evidence": EVIDENCE_NAME},
]
write_csv(PREFIX + "GATE_MATRIX.csv",
          ["Gate", "Result", "FirstFailure", "Evidence"], gate_rows)
write_json(PREFIX + "STATE.json", state)

# Complete, sanitized task-tool source. Original hashes are separately recorded.
tool_names = [
    "xdma_c2h_rolling_4k.c", "controller_r3r4r6r2r3.py", "abi_v1.py",
    "V41_C2H_TRANSPORT_ABI_V1.json", "validate_r3r4r6r2r3.py",
    "frame_reconstruct_r3r4.py", "Invoke-R3R4R6R2R3DutConnection.ps1",
    "Controller-Lock-R3R4R6R2R3.ps1", "linux_lock_r3r4r6r2r3.py",
    "build_native_r3r4r6r2r3.py", "focused_gate_r3r4r6r2r3.py",
    "Extract-R3R4R6R2R3MetadataBundle.ps1", "publish_r3r4r6r2r3.py",
]
original_hashes = {}
for name in tool_names:
    source = ROOT / "scripts" / name
    original_hashes[name] = {"sha256": sha256(source), "bytes": source.stat().st_size}
    write_text(f"tools/{name}", source.read_text(encoding="utf-8-sig"))
write_json("support/source-original-sha256.json", original_hashes)
write_json("support/native-build-sanitized.json", build)
write_json("support/host-tool-gate.json", host_gate)
write_json("support/controller-result-sanitized.json", controller)
write_json("support/validation-result.json", validation)
write_json("support/retained-helper-targeted-state.json", {
    "stdout": pending_receipt["stdout"], "exit_code": pending_receipt["exit_code"]})
write_json("support/driver-operational-branch.json", {
    "stdout": driver_receipt["stdout"], "exit_code": driver_receipt["exit_code"]})
write_text(PREFIX + "PUBLICATION_SANITIZATION.md", """# Publication sanitization

All occurrences of the governed account token are replaced with
`<GOVERNED_USER_REDACTED>`. Original task-tool hashes are recorded separately.
No credential, executable, raw primary/guard bytes, first-record/payload bytes,
raw UYVY frame, camera PNG, driver, bitstream, or metadata transfer archive is
included.
""")

# Re-sanitize all text after structured writes.
for path in OUT.rglob("*"):
    if path.is_file():
        content = path.read_text(encoding="utf-8")
        cleaned = clean(content)
        if cleaned != content:
            path.write_text(cleaned, encoding="utf-8", newline="\n")

manifest_name = PREFIX + "SHA256_MANIFEST.txt"
index_name = PREFIX + "EVIDENCE_INDEX.md"
current_files = sorted(path.relative_to(OUT).as_posix()
                       for path in OUT.rglob("*") if path.is_file())
write_text(index_name,
           "# Evidence index\n\nSanitized R3R4R6R2R3 evidence files:\n\n" +
           "\n".join(f"- `{name}`" for name in current_files) +
           f"\n- `{manifest_name}` (manifest self-entry intentionally omitted)")
manifest_paths = sorted(path for path in OUT.rglob("*")
                        if path.is_file() and path.name != manifest_name)
write_text(manifest_name, "\n".join(
    f"{sha256(path)}  {path.relative_to(OUT).as_posix()}" for path in manifest_paths))

for pattern in ("*.bin", "*.bit", "*.ko", "*.uyvy", "*.png", "*.exe", "*.tgz"):
    found = list(OUT.rglob(pattern))
    if found:
        raise SystemExit(f"forbidden public artifact: {found[0]}")
for path in OUT.rglob("*"):
    if path.is_file() and GOVERNED_USER_TOKEN in path.read_text(encoding="utf-8"):
        raise SystemExit(f"governed user token remains: {path}")

required = {
    "V41_G2B_HW0_PRODUCT_R3R4R6R2R3_MAIN_REPORT.md",
    PREFIX + "OWNER_CONTINUITY_ATTESTATION.md",
    PREFIX + "AUTHORIZATION_RECEIPT.md", PREFIX + "REUSE_RECEIPT.md",
    PREFIX + "NATIVE_HELPER_BUILD.md", PREFIX + "HOST_TOOL_GATE.md",
    PREFIX + "ROLLING_WINDOW_DESIGN.md", PREFIX + "PREQUEUE_RECEIPT.md",
    PREFIX + "ROLLING_PROGRESS.jsonl", PREFIX + "AIO_SUBMISSIONS.csv",
    PREFIX + "AIO_COMPLETIONS.csv", PREFIX + "DESCRIPTOR_WINDOW_METRICS.csv",
    PREFIX + "GUARD_COMPLETIONS.csv", PREFIX + "GUARD_CANCELLATIONS.csv",
    PREFIX + "FLAG_PREDICTION.md", PREFIX + "FLAG_PREDICTION_COMPARISON.md",
    PREFIX + "ERROR_TIMELINE.csv", PREFIX + "COUNTER_CHECKPOINTS.csv",
    PREFIX + "MMIO_WRITE_LEDGER.csv", PREFIX + "FIRST_RECORD_REPORT.md",
    PREFIX + "FIRST_RECORD_HEADER.csv", PREFIX + "PRIMARY_RECORD_METRICS.csv",
    PREFIX + "GUARD_RECORD_METRICS.csv", PREFIX + "STREAM_CONTINUITY_METRICS.csv",
    PREFIX + "MALFORMED_PRECEDING_TIMELINE.csv",
    PREFIX + "WINDOW_CLASSIFICATION.md", PREFIX + "FRAME_RECONSTRUCTION_REPORT.md",
    PREFIX + "PCIE_AER_KERNEL_REVIEW.md", PREFIX + "CLEANUP_RECEIPT.md",
    PREFIX + "FINAL_STATE.md", PREFIX + "GATE_MATRIX.csv", PREFIX + "STATE.json",
    PREFIX + "EVIDENCE_INDEX.md", PREFIX + "SHA256_MANIFEST.txt",
}
present = {path.name for path in OUT.iterdir() if path.is_file()}
missing = sorted(required - present)
if missing:
    raise SystemExit("missing required evidence: " + ", ".join(missing))

print(json.dumps({
    "result": "PASS", "output": str(OUT),
    "files": sum(1 for path in OUT.rglob("*") if path.is_file()),
    "required": len(required), "manifest_entries": len(manifest_paths),
}, indent=2))
