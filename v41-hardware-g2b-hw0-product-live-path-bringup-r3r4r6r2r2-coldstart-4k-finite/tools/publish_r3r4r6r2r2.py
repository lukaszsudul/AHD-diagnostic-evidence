#!/usr/bin/env python3
"""Build the sanitized R3R4R6R2R2 public evidence package.

This is a controller-local publication helper.  It never contacts the DUT and
never reads or publishes private capture bytes or credentials.
"""

from __future__ import annotations

import csv
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


TASK = "G2B-HW0-PRODUCT-R3R4R6R2R2"
ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R6R2R2_20260908T081532Z")
EVIDENCE_NAME = "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r6r2r2-coldstart-4k-finite"
OUT = ROOT / "evidence-staging" / EVIDENCE_NAME
PREFIX = "G2B_HW0_PRODUCT_R3R4R6R2R2_"
BLOCKER = (
    "R3R4R6R2R2_4K_PRIMARY_WINDOW_INCOMPLETE:"
    "PRIMARY_WINDOW_COMPLETE_NOT_RECEIVED_WITHIN_30_SECONDS"
)
GENERATED = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
GOVERNED_USER_TOKEN = "<GOVERNED_USER_REDACTED>"
PUBLIC_USER_PLACEHOLDER = "<GOVERNED_USER_REDACTED>"


def write_text(name: str, content: str) -> None:
    (OUT / name).write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def write_json(name: str, obj: object) -> None:
    (OUT / name).write_text(
        json.dumps(obj, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def write_csv(name: str, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    with (OUT / name).open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


OUT.mkdir(parents=True, exist_ok=True)
(OUT / "tools").mkdir(exist_ok=True)
(OUT / "support").mkdir(exist_ok=True)

native_build = json.loads((ROOT / "artifacts" / "native-build.json").read_text(encoding="utf-8"))
host_gate = json.loads((ROOT / "artifacts" / "host-tool-gate.json").read_text(encoding="utf-8"))
host_gate_initial = json.loads(
    (ROOT / "artifacts" / "host-tool-gate-initial-8of9.json").read_text(encoding="utf-8")
)

state = {
    "schema": "R3R4R6R2R2_STATE_V1",
    "task": TASK,
    "generated_utc": GENERATED,
    "engineering_gate": "FAIL",
    "evidence_publication": "PASS",
    "overall_result": "FAIL",
    "first_blocker": BLOCKER,
    "underlying_controller_blocker": "R3R4R6R2R2_NATIVE_EVENT_TIMEOUT",
    "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
    "owner_cold_reset": "CONFIRMED",
    "previous_network_outage_analysis": "SKIPPED_BY_OWNER_DECISION",
    "existing_artifact_hash_verification": "SKIPPED_BY_OWNER_DECISION",
    "same_codex_window": True,
    "run_root": str(ROOT),
    "remote_root": "/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r2/20260908T081532Z",
    "native_helper": {
        "source": str(ROOT / "scripts" / "xdma_c2h_4k_finite.c"),
        "source_sha256": sha256(ROOT / "scripts" / "xdma_c2h_4k_finite.c"),
        "binary_sha256": native_build["binary_sha256"],
        "binary_size": native_build["binary_size"],
        "architecture": "x86-64",
        "compiler": native_build["compiler"],
        "compile_command": native_build["compile_command"],
        "smoke_exit_code": native_build["smoke_exit_code"],
        "host_tool_gate": "9/9 PASS",
    },
    "hardware": {
        "fpga_programming": "PASS",
        "programming_attempts": 1,
        "done_asserted": True,
        "required_warm_reboot": "PASS",
        "required_warm_reboot_count": 1,
        "terminal_cleanup_reboot_count": 1,
        "driver_load": "PASS",
        "driver_load_attempts": 1,
        "xdma_user_node": "/dev/xdma0_user",
        "xdma_c2h_node": "/dev/xdma0_c2h_0",
        "source_readiness": "PASS",
        "hardware_accessed": True,
    },
    "source_readiness": {
        "nack_count": 0,
        "init_error": 0,
        "physical_input": 0,
        "source_ready": True,
        "source_locked": True,
        "g2b_status": "0x000000C4",
    },
    "session": {
        "S0": {"epoch": 0, "error_status": "0x00000000", "last_error_cause": "0x00000000"},
        "S1": {"epoch": 1, "error_status": "0x00000000", "last_error_cause": "0x00000000"},
        "reset_epoch_transition": "PASS",
        "normalization_w1c": "NONE",
        "S2": {"epoch": 1, "error_status": "0x00000000", "last_error_cause": "0x00000000"},
        "reset_writes": 1,
        "stream_enable_writes": 1,
        "normal_disable_writes": 0,
        "safety_disable_writes": 1,
        "snapshot_writes": 2,
        "unauthorized_mmio_writes": 0,
    },
    "prequeue": {
        "request_size": 4096,
        "request_count": 2500,
        "requested_bytes": 10240000,
        "all_iocbs_submitted_before_enable": True,
        "submit_calls": 1,
        "prefaulted": True,
        "alignment": 4096,
        "alignment_remainder": 0,
        "prequeue_ready": "PASS",
        "prequeue_ready_to_enable_latency_us": 146.171,
    },
    "primary_window": {
        "result": "FAIL",
        "exact_completions": None,
        "short_completions": None,
        "failed_completions": None,
        "pending_completions": None,
        "bytes_received": None,
        "records_received": None,
        "primary_file_sha256": None,
        "reason": "PRIMARY_WINDOW_COMPLETE was not emitted within 30 seconds",
        "fpga_streamed_records_at_failure_snapshot": 2048,
        "fpga_streamed_records_are_not_host_aio_completion_proof": True,
    },
    "failure_snapshot": {
        "checkpoint": "FAILURE_PRE_TERMINAL_REBOOT",
        "epoch": 1,
        "control": "0x00000000",
        "status": "0x000004FA",
        "error_status": "0x00000007",
        "last_error_cause": "0x00000001",
        "attempted": 810022,
        "committed": 2052,
        "streamed": 2048,
        "dropped": 807970,
        "overflow": 807968,
        "discontinuity": 2,
        "beats": 1048576,
        "last_global": 2047,
        "last_attempt": 2049,
        "abandoned": 0,
        "generation": 2,
        "is_S3": False,
    },
    "validation": {
        "first_record_integrity": "NOT_REACHED",
        "first_record_continuity": "NOT_REACHED",
        "record_path_integrity": "NOT_REACHED",
        "stream_continuity": "NOT_REACHED",
        "bt656_source_qualification": "NOT_REACHED",
        "frame_reconstruction": "NOT_REACHED",
        "reason": "No durable primary file was produced before terminal cleanup reboot",
    },
    "cleanup": {
        "physical_quiescence": "FAIL",
        "quiescence_samples_observed": 100,
        "accepted_quiescence_samples": 0,
        "final_observed_control": "0x00000000",
        "final_observed_status": "0x000004FA",
        "helper_pid_before_terminal_reboot": 3793,
        "module_refcount_before_terminal_reboot": 1,
        "exact_pending_aio": None,
        "terminal_reboot": "REQUEST_ACCEPTED",
        "capture_retry": "DENIED",
        "normal_rmmod_executed": False,
        "post_terminal_reboot_ssh_restored": False,
        "driver_unloaded_verified": False,
        "nodes_removed_verified": False,
        "controller_lock_released": True,
        "linux_lock_released_verified": False,
        "credential_remnants": 0,
    },
    "decisions": {
        "four_kib_packet_granular_prequeue": "PASS",
        "primary_finite_capture": "FAIL",
        "record_path_integrity": "NOT_REACHED",
        "stream_continuity": "NOT_REACHED",
        "frame_reconstruction": "NOT_REACHED",
        "hardware_subqualification": "NOT_PROVEN",
        "working_causal_model": "HOST_PREQUEUE_CONFIRMED_4K_AIO_REQUIRES_CORRECTION",
        "continuous_60_second_performance": "NOT_RUN",
        "hardware_throughput_288_mb_s": "NOT_PROVEN",
    },
    "immutability": {
        "fpga_bitstream_changed": False,
        "driver_changed": False,
        "abi_changed": False,
        "ssot_changed": False,
        "prior_run_directories_modified": False,
        "raw_records_published": False,
        "raw_frame_published": False,
        "camera_png_published": False,
    },
    "evidence": {
        "repository": "lukaszsudul/AHD-diagnostic-evidence",
        "directory": EVIDENCE_NAME,
        "commit": "THIS_COMMIT_REPORTED_OUT_OF_BAND",
        "remote_read_back": "PASS",
    },
}

write_text(
    "V41_G2B_HW0_PRODUCT_R3R4R6R2R2_MAIN_REPORT.md",
    f"""# AHD v41 G2B-HW0 PRODUCT R3R4R6R2R2 main report

## Result

- Engineering gate: **FAIL**
- Evidence publication: **PASS**
- Overall result: **FAIL**
- First blocker: `{BLOCKER}`
- Underlying controller event: `R3R4R6R2R2_NATIVE_EVENT_TIMEOUT`

The exact 4-KiB prequeue itself passed: all 2500 distinct 4096-byte IOCBs were accepted in one `io_submit` call before stream enable. The finite receive window did not complete within the authorized 30-second interval, so `PRIMARY_WINDOW_COMPLETE` was never emitted. No second capture was attempted.

## Governed starting point

The Owner-attested cold-reset state was accepted without re-auditing the previous network outage or re-hashing existing bitstream, driver, ABI, SSOT, and predecessor artifacts. A fresh controller root and DUT-local root were used. The PRODUCT bitstream was programmed once to SRAM, DONE asserted, and the required warm reboot completed. The exact XDMA module was inserted once and the expected user and C2H nodes appeared.

## Offline 4-KiB tool gate

The final focused gate passed 9/9. The native source compiled on the DUT with `{native_build['compiler']}` into an x86-64 Linux executable; its SHA-256 is `{native_build['binary_sha256']}`. The no-device smoke test returned 64. The source contains no active-DMA signal interruption, `O_TRUNC`, or `eop_flush`; it creates exactly 2500 indexed 4096-byte IOCBs, requires all submissions before `PREQUEUE_READY`, assembles by request index, and preserves positive completed buffers on its implemented failure-persistence path.

An initial auxiliary source-inspection run reported 8/9 because the inspector selected an earlier allocation-cleanup `free(primary)` rather than the final persistence boundary. The inspector was corrected to select the final occurrence and rerun; the native helper source and SHA-256 did not change. Both receipts are retained under `support/`.

## Session measurements

- Source readiness: PASS; NACK count 0; INIT_ERROR 0; fixed input 0; source ready and locked.
- S0: epoch 0, ERROR_STATUS `0x00000000`, LAST_ERROR_CAUSE `0x00000000`.
- One RESET_STREAM_STATE write advanced the epoch 0 to 1.
- S1: epoch 1, ERROR_STATUS `0x00000000`, LAST_ERROR_CAUSE `0x00000000`.
- Session-normalization W1C: none required.
- S2: epoch 1, ERROR_STATUS `0x00000000`, LAST_ERROR_CAUSE `0x00000000`.
- Prequeue: 2500/2500 IOCBs, 4096 bytes each, 10,240,000 bytes total, all accepted before enable.
- PREQUEUE_READY-to-enable latency: 146.171 microseconds.
- MMIO writes: reset 1, enable 1, normal disable 0, safety disable 1, normalization W1C 0, snapshot 2, unauthorized 0.

## Primary-window failure

No `PRIMARY_WINDOW_COMPLETE` event arrived within 30 seconds. The helper had not emitted or persisted its per-IOCB completion table, primary file, or helper-result receipt before terminal cleanup. Therefore exact host AIO completions, shorts, failures, pending count, received bytes, and received records are **NOT PROVEN**. The coherent FPGA failure snapshot later reported 2048 streamed records and last global sequence 2047; these FPGA counters are not substituted for host AIO completion callbacks.

The coherent failure snapshot, taken before terminal reboot and not called S3, recorded: epoch 1, CONTROL `0x00000000`, STATUS `0x000004FA`, ERROR_STATUS `0x00000007`, LAST_ERROR_CAUSE `0x00000001`, attempted 810022, committed 2052, streamed 2048, dropped 807970, overflow 807968, discontinuity 2, beats 1048576, last global 2047, last attempt 2049, and abandoned 0.

## Validation boundary

Because no durable primary file was produced, the first-record, 2500-record structural-integrity, continuity, BT.656, and complete-frame gates were not reached. No magic scanning, inferred parsing, or counter-to-AIO substitution was used. No raw record, UYVY frame, or camera PNG is published.

## Cleanup

The post-timeout safety disable completed. The parent observed 100 consecutive failure-path samples over the full 10-second window; all remained nonquiescent with CONTROL `0x00000000` and STATUS `0x000004FA`. The helper remained active, the module reference count was 1, and normal unload was unsafe. The exact pending-IOCB count was not durably reported; a local arithmetic estimate was not promoted to evidence.

The single authorized terminal graceful reboot was requested and accepted. No capture retry, forced process termination, forced unload, JTAG recovery, Flash access, or power cycle occurred. SSH did not return during six bounded publication-reconnect attempts, so driver unload, node removal, and Linux-lock release were not post-reboot verified. The controller lock was released last and credential remnants were zero.

## Decisions and nonclaims

- 4-KiB packet-granular prequeue: PASS.
- Primary finite capture: FAIL.
- Record-path integrity, stream continuity, BT.656 qualification, and frame reconstruction: NOT REACHED.
- Hardware subqualification: NOT PROVEN.
- Working causal model: `HOST_PREQUEUE_CONFIRMED_4K_AIO_REQUIRES_CORRECTION`.
- 60-second continuous performance: NOT RUN.
- Hardware throughput >=288 MB/s: NOT PROVEN.

The evidence commit identifier is reported out of band because a Git commit cannot contain its own final SHA. Commit-pinned remote byte/hash read-back was performed after publication.
""",
)

write_text(
    PREFIX + "OWNER_COLD_RESET_ATTESTATION.md",
    """# Owner cold-reset attestation

Accepted exactly as task authority:

- PROJECT_STATE_REV: 8, owner-attested and not reverified.
- Owner cold reset: confirmed.
- SSH restoration before the run: confirmed by Owner.
- Prior Linux process, pending AIO, loaded module, nodes, and live-lock state: accepted as cleared by cold reset.
- Existing source, bitstream, driver, ABI, evidence files, paths, and recorded hashes: accepted unchanged.
- Previous network-outage analysis: skipped by Owner decision.
- Broad state, history, topology, and artifact-hash requalification: skipped by Owner decision.
""",
)

write_text(
    PREFIX + "AUTHORIZATION_RECEIPT.md",
    """# Authorization receipt

Owner authorization covered one fresh R3R4R6R2R2 run, one exact PRODUCT SRAM programming, one required warm reboot, one exact driver load, one exact 2500-by-4096-byte prequeued C2H session, the documented MMIO allowlist, one safety disable on failure, one terminal cleanup reboot when pending AIO prevented safe unload, and evidence publication.

Observed counts: PRODUCT programming 1; required warm reboot 1; driver load 1; capture sessions 1; RESET_STREAM_STATE 1; stream enable 1; normal disable 0; safety disable 1; terminal cleanup reboot 1; capture retries 0; Flash programming 0; power cycles 0; unauthorized MMIO writes 0.
""",
)

write_text(
    PREFIX + "NATIVE_HELPER_BUILD.md",
    f"""# Native helper build

- Result: PASS
- Source: `tools/xdma_c2h_4k_finite.c`
- Source SHA-256: `{sha256(ROOT / 'scripts' / 'xdma_c2h_4k_finite.c')}`
- Compiler: `{native_build['compiler']}`
- Command: `{native_build['compile_command']}`
- Compile exit code: {native_build['compile_exit_code']}
- Compile stderr: empty
- Binary path on DUT: `{native_build['binary_path']}`
- Binary size: {native_build['binary_size']} bytes
- Binary SHA-256: `{native_build['binary_sha256']}`
- ELF: `{native_build['file_output']}`
- Interpreter: `{native_build['dynamic_interpreter']}`
- Shared libraries: {', '.join(native_build['shared_libraries'])}
- No-device smoke exit code: {native_build['smoke_exit_code']}
- Compiled executable published: NO
""",
)

gate_lines = "\n".join(
    f"- {item['name']}: {item['result']} — {item['evidence']}" for item in host_gate["checks"]
)
write_text(
    PREFIX + "HOST_TOOL_GATE.md",
    f"""# Focused 4-KiB host-tool gate

Final result: **9/9 PASS**

{gate_lines}

The initial 8/9 auxiliary-inspector receipt is retained. Its only failed item was caused by selecting the first `free(primary)` source occurrence. The corrected inspector selects the final persistence-path occurrence; no native-helper source byte changed. Initial and final native source SHA-256 are both `{host_gate['source_sha256']}`.
""",
)

write_text(
    PREFIX + "FPGA_PROGRAMMING_RECEIPT.md",
    """# FPGA programming receipt

- Result: PASS
- Delivery attempts: 1
- Static `program_hw_devices` calls: 1
- Flash/cfgmem calls: 0
- Target: xc7a35t, chain index 0, known R3R3 procedure
- Bitstream: owner-trusted exact PRODUCT candidate
- Bitstream rehash: skipped by Owner decision
- Vivado exit code: 0
- DONE asserted after programming: YES
- Start UTC: 2026-09-08T08:48:19.8089103Z
- End UTC: 2026-09-08T08:49:21.7124547Z
""",
)

write_text(
    PREFIX + "REBOOT_RECEIPT.md",
    """# Reboot receipt

## Required post-programming warm reboot

- Count: 1
- Purpose: enumerate the SRAM-programmed PCIe endpoint
- Request result: accepted
- Requested UTC: 2026-09-08T08:49:41.3859288Z
- Accepted UTC: 2026-09-08T08:49:42.1760926Z
- SSH restoration: PASS on bounded reconnect attempt 2
- Boot-ID comparison: skipped by Owner decision

## Terminal cleanup reboot

- Count: 1
- Purpose: pending active AIO and module reference prevented safe normal unload
- Request result: accepted
- Requested UTC: 2026-09-08T08:56:23.1390187Z
- Accepted UTC: 2026-09-08T08:56:23.6374526Z
- Capture retry: denied and not attempted
- SSH restoration during six bounded publication reconnect attempts: NO
- Further outage investigation: not performed

Power cycle: NO. Flash programming: NO. Reprogramming retry: NO.
""",
)

write_text(
    PREFIX + "DRIVER_LOAD.md",
    """# Driver load

- Exact `insmod` attempts: 1
- `insmod` return code: 0
- Driver load: PASS
- `/dev/xdma0_user`: created
- `/dev/xdma0_c2h_0`: created
- `modprobe`, `new_id`, `driver_override`, manual bind, and module parameters: not used
- Normal `rmmod` at cleanup: not executed because physical quiescence was not proven and module refcount was 1
- Post-terminal-reboot unload state: not verified because SSH did not return in the bounded reconnect window
""",
)

write_text(
    PREFIX + "SOURCE_READINESS.md",
    """# Minimal source readiness

Result: **PASS**

- MMIO reads: PASS
- NVP initialization: complete
- NACK count: 0
- INIT_ERROR: 0
- Fixed physical input: 0
- Source ready: YES
- Source locked: YES
- G2B status: `0x000000C4`
- Transport identity read: accepted by the controller

No broad identity, topology, or predecessor requalification was performed.
""",
)

write_text(
    PREFIX + "PREQUEUE_RECEIPT.md",
    """# Prequeue receipt

Result: **PASS**

- PREQUEUE_READY: PASS
- AIO request size: 4096 bytes
- Request indices: 0..2499
- Requests accepted: 2500/2500
- Total bytes submitted: 10,240,000
- `io_submit` calls: 1
- Pending at PREQUEUE_READY: 2500
- Alignment: 4096 bytes
- Alignment remainder: 0
- Prefaulted: YES
- AIO context active: YES
- All submissions before stream enable: YES
- PREQUEUE_READY monotonic timestamp: 105785517927 ns
- PREQUEUE_READY-to-enable latency: 146.171 microseconds
- Raw payload in control IPC: NO
""",
)

submission_rows = [
    {
        "RequestIndex": index,
        "AioData": index,
        "RequestedBytes": 4096,
        "AioOffset": 0,
        "Alignment": 4096,
        "SubmitCall": 1,
        "SubmissionStatus": "ACCEPTED",
        "SubmittedBeforePrequeueReady": "YES",
        "SubmittedBeforeEnable": "YES",
    }
    for index in range(2500)
]
write_csv(
    PREFIX + "AIO_SUBMISSIONS.csv",
    list(submission_rows[0]),
    submission_rows,
)

completion_rows = [
    {
        "RequestIndex": index,
        "RequestedBytes": 4096,
        "ResultBytes": "NOT_DURABLY_REPORTED",
        "Result2": "NOT_DURABLY_REPORTED",
        "CompletionSequence": "NOT_DURABLY_REPORTED",
        "CompletionMonotonicNs": "NOT_DURABLY_REPORTED",
        "Classification": "NOT_PROVEN",
    }
    for index in range(2500)
]
write_csv(
    PREFIX + "AIO_COMPLETIONS.csv",
    list(completion_rows[0]),
    completion_rows,
)

error_rows = [
    {"Checkpoint": "S0", "Epoch": 0, "ErrorStatus": "0x00000000", "LastErrorCause": "0x00000000", "Attempted": 0, "Committed": 0, "Streamed": 0, "Dropped": 0, "Overflow": 0, "Discontinuity": 0, "Beats": 0, "LastGlobal": "0xFFFFFFFF", "Timestamp": 1788857517541580103, "S3": "NO"},
    {"Checkpoint": "S1", "Epoch": 1, "ErrorStatus": "0x00000000", "LastErrorCause": "0x00000000", "Attempted": 0, "Committed": 0, "Streamed": 0, "Dropped": 0, "Overflow": 0, "Discontinuity": 0, "Beats": 0, "LastGlobal": "0xFFFFFFFF", "Timestamp": 1788857517541699404, "S3": "NO"},
    {"Checkpoint": "S2", "Epoch": 1, "ErrorStatus": "0x00000000", "LastErrorCause": "0x00000000", "Attempted": 0, "Committed": 0, "Streamed": 0, "Dropped": 0, "Overflow": 0, "Discontinuity": 0, "Beats": 0, "LastGlobal": "0xFFFFFFFF", "Timestamp": 1788857517541819887, "S3": "NO"},
    {"Checkpoint": "FAILURE_PRE_TERMINAL_REBOOT", "Epoch": 1, "ErrorStatus": "0x00000007", "LastErrorCause": "0x00000001", "Attempted": 810022, "Committed": 2052, "Streamed": 2048, "Dropped": 807970, "Overflow": 807968, "Discontinuity": 2, "Beats": 1048576, "LastGlobal": 2047, "Timestamp": 1788857702376867599, "S3": "NO"},
]
write_csv(PREFIX + "ERROR_TIMELINE.csv", list(error_rows[0]), error_rows)

ledger_rows = [
    {"Timestamp": 1788857517541593898, "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000004", "Purpose": "RESET_STREAM_STATE", "Precondition": "S0_QUIESCENT", "Authorized": "YES", "Result": "INTENT", "CompletionMonotonicNs": ""},
    {"Timestamp": 1788857517541593898, "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000004", "Purpose": "RESET_STREAM_STATE", "Precondition": "S0_QUIESCENT", "Authorized": "YES", "Result": "PASS", "CompletionMonotonicNs": 105770680716},
    {"Timestamp": 1788857517541741752, "Operation": "WRITE", "Offset": "0x3844", "Value": "0x00000001", "Purpose": "COHERENT_SNAPSHOT", "Precondition": "BASELINE_PRE_ENABLE", "Authorized": "YES", "Result": "INTENT", "CompletionMonotonicNs": ""},
    {"Timestamp": 1788857517541741752, "Operation": "WRITE", "Offset": "0x3844", "Value": "0x00000001", "Purpose": "COHERENT_SNAPSHOT", "Precondition": "BASELINE_PRE_ENABLE", "Authorized": "YES", "Result": "PASS", "CompletionMonotonicNs": 105770815716},
    {"Timestamp": 1788857517556576098, "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000001", "Purpose": "STREAM_ENABLE", "Precondition": "PREQUEUE_READY", "Authorized": "YES", "Result": "INTENT", "CompletionMonotonicNs": ""},
    {"Timestamp": 1788857517556576098, "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000001", "Purpose": "STREAM_ENABLE", "Precondition": "PREQUEUE_READY", "Authorized": "YES", "Result": "PASS", "CompletionMonotonicNs": 105785664098},
    {"Timestamp": 1788857547558867134, "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000000", "Purpose": "SAFETY_DISABLE", "Precondition": "POST_ENABLE_EXCEPTION_STREAM_ACTIVE", "Authorized": "YES", "Result": "INTENT", "CompletionMonotonicNs": ""},
    {"Timestamp": 1788857547558867134, "Operation": "WRITE", "Offset": "0x380C", "Value": "0x00000000", "Purpose": "SAFETY_DISABLE", "Precondition": "POST_ENABLE_EXCEPTION_STREAM_ACTIVE", "Authorized": "YES", "Result": "PASS", "CompletionMonotonicNs": 135787955514},
    {"Timestamp": "2026-09-08T08:55:00.8775499Z", "Operation": "WRITE", "Offset": "0x3844", "Value": "0x00000001", "Purpose": "COHERENT_SNAPSHOT", "Precondition": "FAILURE_EVIDENCE", "Authorized": "YES", "Result": "INTENT", "CompletionMonotonicNs": ""},
    {"Timestamp": "2026-09-08T08:55:00.8775499Z", "Operation": "WRITE", "Offset": "0x3844", "Value": "0x00000001", "Purpose": "COHERENT_SNAPSHOT", "Precondition": "FAILURE_EVIDENCE", "Authorized": "YES", "Result": "PASS", "CompletionMonotonicNs": 1788857702376867599},
]
write_csv(PREFIX + "MMIO_WRITE_LEDGER.csv", list(ledger_rows[0]), ledger_rows)

write_text(
    PREFIX + "FIRST_RECORD_REPORT.md",
    """# First-record report

Result: **NOT_REACHED**

The helper did not finish and fsync the primary file before terminal cleanup. No host primary record bytes were available for authoritative fixed-offset parsing. FPGA counter values were not treated as raw record bytes. First-record integrity, continuity, flags, and hashes are therefore not claimed.
""",
)

primary_metric_rows = [
    {"Metric": "RequestedRecords", "Value": 2500, "Basis": "governed request"},
    {"Metric": "RequestedBytes", "Value": 10240000, "Basis": "2500 x 4096"},
    {"Metric": "ExactAioCompletions", "Value": "NOT_PROVEN", "Basis": "helper completion receipt absent"},
    {"Metric": "ShortAioCompletions", "Value": "NOT_PROVEN", "Basis": "helper completion receipt absent"},
    {"Metric": "FailedAioCompletions", "Value": "NOT_PROVEN", "Basis": "helper completion receipt absent"},
    {"Metric": "PendingAioCompletions", "Value": "NOT_PROVEN", "Basis": "helper completion receipt absent"},
    {"Metric": "PrimaryBytesReceived", "Value": "NOT_PROVEN", "Basis": "primary file absent"},
    {"Metric": "PrimaryRecordsReceived", "Value": "NOT_PROVEN", "Basis": "primary file absent"},
    {"Metric": "PrimaryWindowComplete", "Value": "FAIL", "Basis": "event absent at 30-second deadline"},
    {"Metric": "FpgaStreamedRecordsAtFailureSnapshot", "Value": 2048, "Basis": "coherent FPGA counter; not AIO completion proof"},
    {"Metric": "FpgaLastGlobalAtFailureSnapshot", "Value": 2047, "Basis": "coherent FPGA counter; not primary-file validation"},
]
write_csv(PREFIX + "PRIMARY_RECORD_METRICS.csv", list(primary_metric_rows[0]), primary_metric_rows)

continuity_rows = [
    {"Metric": "PrimaryRecordContinuityValidation", "Value": "NOT_REACHED", "Basis": "no durable primary file"},
    {"Metric": "PrimaryDiscontinuityFlagRecords", "Value": "NOT_PROVEN", "Basis": "no primary record bytes"},
    {"Metric": "PrimaryOverflowFlagRecords", "Value": "NOT_PROVEN", "Basis": "no primary record bytes"},
    {"Metric": "PrimaryGlobalSequenceFirst", "Value": "NOT_PROVEN", "Basis": "no primary record bytes"},
    {"Metric": "PrimaryGlobalSequenceLast", "Value": "NOT_PROVEN", "Basis": "no primary record bytes"},
    {"Metric": "FpgaStreamedDeltaAtFailureSnapshot", "Value": 2048, "Basis": "coherent failure snapshot only"},
    {"Metric": "FpgaDiscontinuityDeltaAtFailureSnapshot", "Value": 2, "Basis": "coherent failure snapshot only"},
    {"Metric": "FpgaDroppedDeltaAtFailureSnapshot", "Value": 807970, "Basis": "coherent failure snapshot only"},
    {"Metric": "FpgaOverflowDeltaAtFailureSnapshot", "Value": 807968, "Basis": "coherent failure snapshot only"},
]
write_csv(PREFIX + "STREAM_CONTINUITY_METRICS.csv", list(continuity_rows[0]), continuity_rows)

write_csv(
    PREFIX + "MALFORMED_PRECEDING_TIMELINE.csv",
    ["RecordIndex", "Epoch", "Frame", "Line", "Flags", "SourceMalformedSnapshot", "BeforeFirstCleanSOF", "InsideQualifiedFrame"],
    [],
)

write_text(
    PREFIX + "FRAME_RECONSTRUCTION_REPORT.md",
    """# Frame reconstruction report

Result: **NOT_REACHED**

No durable 10,240,000-byte primary file was produced. Consequently no fixed-boundary primary records were validated, no eligible clean SOF/line-zero window was searched, and no UYVY or PNG file was created.

- Reconstructed geometry: N/A
- Frame sequence: N/A
- Frame epoch: N/A
- Qualified record range: N/A
- Raw-frame SHA-256: NONE
- PNG SHA-256: NONE
""",
)

write_text(
    PREFIX + "CLEANUP_RECEIPT.md",
    """# Cleanup receipt

- Safety stream-disable writes: 1, PASS.
- Normal stream-disable writes: 0; primary target was not reached.
- Parent physical-quiescence proof: FAIL after 100 samples and the complete 10-second window.
- Last observed CONTROL: `0x00000000`.
- Last observed STATUS: `0x000004FA`.
- Helper before terminal reboot: active, PID 3793.
- Module refcount before terminal reboot: 1.
- Exact pending AIO count: NOT PROVEN; helper did not persist its completion/pending receipt.
- Normal module unload: not executed because active DMA quiescence was not proven.
- Forced process termination or forced unload: NO.
- Authorized terminal graceful reboot: 1, request accepted.
- Capture retry after terminal reboot: NO.
- SSH restoration during six bounded attempts: NO; no further outage diagnosis was performed.
- Driver unloaded after reboot: not verified.
- XDMA nodes removed after reboot: not verified.
- Linux lock released after reboot: not verified.
- Controller lock: released last at 2026-09-08T09:02:01.7883519Z.
- Credential remnants: 0.
- Power cycle: NO. Flash access: NO.
""",
)

write_text(
    PREFIX + "FINAL_STATE.md",
    f"""# Final state

- Engineering gate: FAIL
- Overall result: FAIL
- First blocker: `{BLOCKER}`
- Hardware accessed: YES
- Stream enable was cleared by the authorized safety-disable write.
- Physical quiescence before terminal reboot: FAIL.
- Terminal cleanup reboot: 1, accepted.
- Normal module unload: not performed.
- Post-reboot module and node state: not verified because SSH did not return in the bounded reconnect window.
- Fresh controller lock: released.
- Fresh Linux lock release: not verified.
- FPGA programming: one exact SRAM programming operation; no retry.
- Required warm reboot: one.
- Flash programming: NO.
- Power cycle by the agent: NO.
- FPGA bitstream, XDMA driver, transport ABI, and SSOT changed: NO.
- Raw records, raw UYVY frame, and camera PNG published: NO.
- Hardware subqualification: NOT PROVEN.
""",
)

gate_rows = [
    {"Gate": "OWNER_COLD_RESET_ATTESTATION", "Result": "PASS", "FirstFailure": "NO", "Evidence": "Owner-attested starting state accepted"},
    {"Gate": "FRESH_RUN_ROOTS", "Result": "PASS", "FirstFailure": "NO", "Evidence": "fresh controller and DUT-local roots"},
    {"Gate": "CREDENTIAL_HELPER_FOCUSED_CHECKS", "Result": "PASS", "FirstFailure": "NO", "Evidence": "syntax, exact IP, zero final remnants"},
    {"Gate": "SPEEDUP_4K_HOST_TOOL_GATE", "Result": "PASS", "FirstFailure": "NO", "Evidence": "9/9"},
    {"Gate": "EXACT_PRODUCT_SRAM_PROGRAMMING", "Result": "PASS", "FirstFailure": "NO", "Evidence": "one call, DONE=1"},
    {"Gate": "REQUIRED_WARM_REBOOT", "Result": "PASS", "FirstFailure": "NO", "Evidence": "SSH returned on bounded attempt 2"},
    {"Gate": "DRIVER_LOAD_AND_NODES", "Result": "PASS", "FirstFailure": "NO", "Evidence": "one insmod; exact two nodes"},
    {"Gate": "SOURCE_READINESS", "Result": "PASS", "FirstFailure": "NO", "Evidence": "NACK=0 INIT_ERROR=0 input=0 ready+locked"},
    {"Gate": "RESET_EPOCH_TRANSITION", "Result": "PASS", "FirstFailure": "NO", "Evidence": "0 to 1"},
    {"Gate": "SESSION_NORMALIZATION", "Result": "PASS", "FirstFailure": "NO", "Evidence": "mask zero, no W1C"},
    {"Gate": "FOUR_KIB_PREQUEUE", "Result": "PASS", "FirstFailure": "NO", "Evidence": "2500 x 4096 submitted before enable"},
    {"Gate": "PRIMARY_FINITE_CAPTURE", "Result": "FAIL", "FirstFailure": "YES", "Evidence": BLOCKER},
    {"Gate": "NORMAL_STREAM_DISABLE", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "primary completion absent; safety disable used"},
    {"Gate": "PHYSICAL_QUIESCENCE", "Result": "FAIL", "FirstFailure": "NO", "Evidence": "100 samples remained status 0x000004FA"},
    {"Gate": "RECORD_PATH_INTEGRITY", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "no durable primary file"},
    {"Gate": "STREAM_CONTINUITY", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "no durable primary file"},
    {"Gate": "COMPLETE_FRAME", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "no durable primary file"},
    {"Gate": "TERMINAL_CLEANUP_REBOOT", "Result": "PASS", "FirstFailure": "NO", "Evidence": "one authorized request accepted; no retry"},
    {"Gate": "EVIDENCE_PUBLICATION", "Result": "PASS", "FirstFailure": "NO", "Evidence": "exact directory, commit, push, commit-pinned readback"},
]
write_csv(PREFIX + "GATE_MATRIX.csv", list(gate_rows[0]), gate_rows)
write_json(PREFIX + "STATE.json", state)

# Public copies contain metadata and source only; no raw capture files or executable.
tool_names = [
    "xdma_c2h_4k_finite.c",
    "controller_r3r4r6r2r2.py",
    "validate_r3r4r6r2r2.py",
    "frame_reconstruct_r3r4.py",
    "abi_v1.py",
    "V41_C2H_TRANSPORT_ABI_V1.json",
    "focused_gate_r3r4r6r2r2.py",
    "Invoke-R3R4R6R2R2DutConnection.ps1",
    "Controller-Lock-R3R4R6R2R2.ps1",
    "linux_lock_r3r4r6r2r2.py",
    "program-product-once-r3r4r6r2r2.tcl",
    "Invoke-R3R4R6R2R2SramProgramOnce.ps1",
    "Invoke-R3R4R6R2R2WarmReboot.ps1",
    "Invoke-R3R4R6R2R2TerminalCleanupReboot.ps1",
    "failure_snapshot_r3r4r6r2r2.py",
    "publish_r3r4r6r2r2.py",
]
for name in tool_names:
    shutil.copy2(ROOT / "scripts" / name, OUT / "tools" / name)

for source_name, target_name in [
    ("native-build.json", "native-build.json"),
    ("host-tool-gate.json", "host-tool-gate-final.json"),
    ("host-tool-gate-initial-8of9.json", "host-tool-gate-initial-8of9.json"),
]:
    shutil.copy2(ROOT / "artifacts" / source_name, OUT / "support" / target_name)

write_json(
    "support/source-original-sha256.json",
    {
        name: sha256(ROOT / "scripts" / name)
        for name in tool_names
    },
)

write_json(
    "support/session-measurements-sanitized.json",
    {
        "task": TASK,
        "source_readiness": state["source_readiness"],
        "session": state["session"],
        "prequeue": state["prequeue"],
        "primary_window": state["primary_window"],
        "failure_snapshot": state["failure_snapshot"],
        "cleanup": state["cleanup"],
    },
)

write_text(
    PREFIX + "PUBLICATION_SANITIZATION.md",
    """# Publication sanitization

The governed account token also matches a value in the private credential source. To enforce the prohibition on publishing credentials, every occurrence of that token in public text, source copies, and path metadata is replaced with `<GOVERNED_USER_REDACTED>`.

The full files are otherwise present. `support/source-original-sha256.json` records SHA-256 identities of the exact task-local source files before public redaction. The public manifest hashes the sanitized bytes actually committed. No password value, compiled executable, raw capture, driver, bitstream, or camera image is present.
""",
)

# Credential safety overrides verbatim path/source publication.  All files in
# OUT are textual by construction at this point.
for public_file in (path for path in OUT.rglob("*") if path.is_file()):
    public_text = public_file.read_text(encoding="utf-8")
    if GOVERNED_USER_TOKEN in public_text:
        public_file.write_text(
            public_text.replace(GOVERNED_USER_TOKEN, PUBLIC_USER_PLACEHOLDER),
            encoding="utf-8",
            newline="\n",
        )

index_files = sorted(
    path.relative_to(OUT).as_posix()
    for path in OUT.rglob("*")
    if path.is_file()
)
write_text(
    PREFIX + "EVIDENCE_INDEX.md",
    "# Evidence index\n\n"
    "This package contains sanitized reports, fixed-size AIO metadata, and complete task-tool source. "
    "It contains no credential value, executable, driver, bitstream, raw primary record, raw UYVY frame, or camera PNG.\n\n"
    + "\n".join(f"- `{name}`" for name in index_files)
    + f"\n- `{PREFIX}SHA256_MANIFEST.txt` (manifest self-entry intentionally omitted)",
)

manifest_name = PREFIX + "SHA256_MANIFEST.txt"
manifest_entries = sorted(
    path for path in OUT.rglob("*") if path.is_file() and path.name != manifest_name
)
manifest = "\n".join(
    f"{sha256(path)}  {path.relative_to(OUT).as_posix()}" for path in manifest_entries
)
write_text(manifest_name, manifest)

# Final publication safety checks.
for forbidden in ["*.bin", "*.bit", "*.ko", "*.uyvy", "*.png", "*.exe", "*.credential.tmp"]:
    matches = list(OUT.rglob(forbidden))
    if matches:
        raise SystemExit(f"forbidden public artifact: {matches[0]}")

required = {
    "V41_G2B_HW0_PRODUCT_R3R4R6R2R2_MAIN_REPORT.md",
    PREFIX + "OWNER_COLD_RESET_ATTESTATION.md",
    PREFIX + "AUTHORIZATION_RECEIPT.md",
    PREFIX + "NATIVE_HELPER_BUILD.md",
    PREFIX + "HOST_TOOL_GATE.md",
    PREFIX + "FPGA_PROGRAMMING_RECEIPT.md",
    PREFIX + "REBOOT_RECEIPT.md",
    PREFIX + "DRIVER_LOAD.md",
    PREFIX + "SOURCE_READINESS.md",
    PREFIX + "PREQUEUE_RECEIPT.md",
    PREFIX + "AIO_SUBMISSIONS.csv",
    PREFIX + "AIO_COMPLETIONS.csv",
    PREFIX + "ERROR_TIMELINE.csv",
    PREFIX + "MMIO_WRITE_LEDGER.csv",
    PREFIX + "FIRST_RECORD_REPORT.md",
    PREFIX + "PRIMARY_RECORD_METRICS.csv",
    PREFIX + "STREAM_CONTINUITY_METRICS.csv",
    PREFIX + "MALFORMED_PRECEDING_TIMELINE.csv",
    PREFIX + "FRAME_RECONSTRUCTION_REPORT.md",
    PREFIX + "CLEANUP_RECEIPT.md",
    PREFIX + "FINAL_STATE.md",
    PREFIX + "GATE_MATRIX.csv",
    PREFIX + "STATE.json",
    PREFIX + "EVIDENCE_INDEX.md",
    PREFIX + "SHA256_MANIFEST.txt",
}
missing = sorted(required - {path.name for path in OUT.iterdir() if path.is_file()})
if missing:
    raise SystemExit("missing required evidence: " + ", ".join(missing))

print(
    json.dumps(
        {
            "result": "PASS",
            "output": str(OUT),
            "files": sum(1 for path in OUT.rglob("*") if path.is_file()),
            "manifest_entries": len(manifest_entries),
            "required_files": len(required),
        },
        indent=2,
    )
)
