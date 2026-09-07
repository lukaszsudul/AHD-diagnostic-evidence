"""Build the sanitized public R3R4R5 evidence package from task-local receipts."""
from __future__ import annotations

import csv
import hashlib
import json
import pathlib
import shutil
from datetime import datetime, timezone


P = pathlib.Path
TASK = "G2B-HW0-PRODUCT-R3R4R5"
PREFIX = "G2B_HW0_PRODUCT_R3R4R5"
RUN = P(r"C:\FPGA\G2B_HW0_PRODUCT_R3R4R5_20260907T151342Z")
REMOTE = RUN / "artifacts" / "remote-sanitized"
STAGING = RUN / "evidence-staging" / (
    "v41-hardware-g2b-hw0-product-live-path-bringup-r3r4r5-finite-frame")
FIRST_BLOCKER = (
    "R3R4R5_FIRST_RECORD_ABI_VALIDATION_FAILED:"
    "DISCONTINUITY flag is set;MALFORMED_PRECEDING flag is set")
UTF8 = "utf-8"


def load(path: P):
    return json.loads(path.read_text(encoding=UTF8))


def write(name: str, text: str):
    path = STAGING / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding=UTF8, newline="\n")


def write_json(name: str, value):
    write(name, json.dumps(value, indent=2, sort_keys=False))


def copy(source: P, destination: str):
    path = STAGING / destination
    path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, path)


def sha256(path: P):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def md_bool(value):
    return "YES" if value else "NO"


if STAGING.exists():
    if STAGING.parent != RUN / "evidence-staging":
        raise RuntimeError("R3R4R5_STAGING_BOUNDARY_INVALID")
else:
    STAGING.mkdir(parents=True)

authority = load(RUN / "artifacts" / "authority" /
                 f"{PREFIX}_AUTHORITY.json")
selftest = load(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_SELFTEST.json")
delta = load(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_DIFF.json")
architecture = load(RUN / "artifacts" /
                    f"{PREFIX}_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json")
credential = load(RUN / "artifacts" /
                  f"{PREFIX}_CREDENTIAL_HELPER_HARD_GATE.json")
boundary = load(RUN / "artifacts" / "protected-after.comparison.json")
preload = load(REMOTE / "logs" / "preload-inventory.json")
driver_verification = load(REMOTE / "logs" / "driver-verification.json")
t1 = load(REMOTE / "logs" / "t1-result.json")
t1_proof = load(REMOTE / "logs" / "t1-proof.json")
t2 = load(REMOTE / "logs" / "t2-result.json")
capture = load(REMOTE / "logs" / "T3T4-result.json")
assessment = load(REMOTE / "logs" / "post-failure-assessment.json")
cleanup = load(REMOTE / "logs" / "cleanup-result.json")
health = {name: load(REMOTE / "logs" / f"health-{name}.json")
          for name in ("after-bind", "before-capture", "after-capture",
                       "before-unload", "after-unload")}
reader = load(REMOTE / "private" / "T3T4-reader-result.json")

required_facts = (
    authority["result"] == "PASS",
    selftest["result"] == "PASS" and selftest["passed"] == 16,
    delta["result"] == "PASS",
    architecture["result"] == "PASS",
    credential["result"] == "PASS",
    boundary["result"] == "PASS",
    preload["result"] == "PASS",
    t1["result"] == "PASS",
    t2["result"] == "PASS",
    capture["result"] == "FAIL" and capture["blocker"] == FIRST_BLOCKER,
    assessment["result"] == "PASS",
    cleanup["result"] == "PASS",
    all(item["result"] == "PASS" for item in health.values()),
)
if not all(required_facts):
    raise RuntimeError("R3R4R5_PUBLICATION_INPUT_GATE_FAILED")

write_rows = []
with (REMOTE / "logs" / "mmio-write-ledger.csv").open(
        encoding=UTF8, newline="") as handle:
    write_rows = list(csv.DictReader(handle))
completed_writes = [row for row in write_rows if row["Result"] == "PASS"]
write_counts = {}
for row in completed_writes:
    write_counts[row["Purpose"]] = write_counts.get(row["Purpose"], 0) + 1
unauthorized_writes = sum(row["Authorized"] != "YES" for row in completed_writes)
statistics_clear_writes = sum("STAT" in row["Purpose"].upper()
                              and "CLEAR" in row["Purpose"].upper()
                              for row in completed_writes)

connection_receipts = sorted((RUN / "logs").glob("connection-*.json"))
connection_ledger = []
for path in connection_receipts:
    item = load(path)
    connection_ledger.append({
        "receipt": path.name,
        "mode": item.get("mode"),
        "start_utc": item.get("start_utc"),
        "end_utc": item.get("end_utc"),
        "helper_sha256": item.get("helper_sha256"),
        "host_key_pinned": item.get("host_key_pinned"),
        "credential_in_process_arguments": item.get(
            "credential_in_process_arguments"),
        "credential_temp_remaining": item.get("credential_temp_remaining"),
        "exit_code": item.get("exit_code"),
        "problem": item.get("problem"),
    })
helper_sha = "8988139C2F2CFFC4F5F04A6BB1A61314AAF4A5779B2021709BF35A9A625F5F84"
all_helper = all(row["helper_sha256"] == helper_sha for row in connection_ledger)
credential_remnants = max(row["credential_temp_remaining"]
                          for row in connection_ledger)

first_header = assessment["first_record_assessment"]["header"]
counters = assessment["counters"]
capture_quiescence = capture["failure_quiescence_observations"]
capture_quiescence_last = capture_quiescence[-1]
generated = datetime.now(timezone.utc).isoformat()

state = {
    "schema": "R3R4R5_FINAL_STATE_V1",
    "task": TASK,
    "generated_utc": generated,
    "engineering_gate": "FAIL",
    "evidence_publication": "SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK",
    "overall_result": "FAIL",
    "project_state_rev_at_start": 8,
    "project_state_rev_at_end": 8,
    "predecessor_evidence": {name: "VERIFIED" for name in
                             ("R3R3", "R3R4", "R3R4R1", "R3R4R2",
                              "R3R4R3", "R3R4R4")},
    "fresh_run_root": str(RUN),
    "prior_immutable_artifact_new_writes": 0,
    "authorized_tool_delta":
        "QUIESCENCE_FIXTURE_1_400_TO_1_401_PLUS_RUN_IDENTITY_ONLY",
    "runtime_quiescence_implementation_changed": False,
    "synthetic_final_quiescence_observation_seconds": 1.401,
    "synthetic_evaluated_quiescence_span_seconds": 0.401,
    "offline_selftests": {"existing": "11/11 PASS", "contract": "5/5 PASS",
                          "total": "16/16 PASS", "failed": "NONE"},
    "capture_tool_architecture_hard_gate": "PASS",
    "credential_helper_hard_gate": "PASS",
    "credential_helper_sha256": helper_sha,
    "dut_connections": len(connection_ledger),
    "all_dut_connections_used_r3r4r5_helper": all_helper,
    "credential_remnants": credential_remnants,
    "dut_exclusivity": "PASS",
    "parallel_hdmi_hardware_activity": "NONE",
    "recovery_path": "NOT_REQUIRED",
    "sram_programming_executed": 0,
    "warm_reboot_executed": 0,
    "boot_id": preload["boot_id"],
    "fpga": {"device": "xc7a35t", "idcode": "0362D093",
             "done_before": 1, "done_after": 1},
    "pcie": {"bdf": "0000:01:00.0", "vendor_device": "10ee:7011",
             "subsystem": "10ee:0007", "link": "Gen2 x1"},
    "driver": {"sha256": authority["driver_sha256"], "load_attempts": 1,
               "load": "PASS", "automatic_bind": "PASS",
               "unintended_endpoints_bound": 0,
               "dynamic_xdma_index": t1_proof["dynamic_index"],
               "user_node": t1_proof["user"], "c2h_node": t1_proof["c2h"],
               "node_to_bdf": "PASS"},
    "runtime": {"dual_layer_identity": "PASS", "nvp_initialization": "PASS",
                "nack_count": 0, "init_error": 0,
                "fixed_physical_source": "INPUT_0", "fixed_live_source": "PASS",
                "transport_abi": "AHD_C2H_TRANSPORT_ABI_V1"},
    "session": {
        "sessions": 1, "inherited_error_status": "0x00000007",
        "inherited_last_error_cause": "0x00000002", "reset_writes": 1,
        "pre_reset_epoch": 2, "post_reset_epoch": 3,
        "normalization_mask": "0x00000007", "normalization_writes": 1,
        "post_normalization_error_status": "0x00000000",
        "snapshot_writes": write_counts.get("COHERENT_SNAPSHOT", 0),
        "enable_writes": write_counts.get("ENABLE_C2H", 0),
        "normal_disable_writes": write_counts.get("NORMAL_DISABLE", 0),
        "safety_disable_writes": write_counts.get("SAFETY_DISABLE", 0),
        "statistics_clear_writes": statistics_clear_writes,
        "unauthorized_mmio_writes": unauthorized_writes,
    },
    "first_record": {
        "gate": "FAIL", "bytes": 4096, "reread_bytes": 4096,
        "record_file_fsync_completed_before_validation": True,
        "first_record_durable_event": False,
        "first_record_sha256": assessment["first_record_sha256"],
        "payload_file_exists": assessment["payload_file_exists"],
        "payload_slice_sha256": assessment["payload_slice_sha256"],
        "epoch": first_header["reset_epoch"], "header_structural_parse": "PASS",
        "flags_hex": f"0x{first_header['flags']:08X}",
        "disqualifying_flags": ["DISCONTINUITY", "MALFORMED_PRECEDING"],
        "payload_geometry": "PASS", "padding": "PASS",
    },
    "capture": {
        "gate": "FAIL", "primary_requested": 2500,
        "primary_received": assessment["primary_records"],
        "primary_bytes": assessment["primary_bytes"],
        "primary_sha256": assessment["primary_sha256"],
        "drain_records": assessment["drain_records"],
        "drain_bytes": assessment["drain_bytes"],
        "drain_sha256": assessment["drain_sha256"],
        "incomplete_trailing_bytes": assessment["incomplete_trailing_bytes"],
        "total_complete_records": assessment["primary_records"] +
                                  assessment["drain_records"],
        "malformed_records": assessment["malformed_records"],
        "padding_errors": assessment["padding_errors"],
        "discontinuity_flag_records": assessment["discontinuity_flag_records"],
        "parent_quiescence": "PASS",
        "parent_quiescence_samples": capture_quiescence_last["consecutive"],
        "parent_quiescence_span_ms": capture_quiescence_last["span_ms"],
        "reader_quiet_window_exit": "FAIL",
        "reader_blocker": reader["blocker"],
    },
    "post_capture": {
        "control": f"0x{assessment['final_control']:08X}",
        "status": f"0x{assessment['final_status']:08X}",
        "error_status": f"0x{assessment['final_error_status']:08X}",
        "last_error_cause": f"0x{assessment['final_last_error_cause']:08X}",
        "counter_reconciliation": "FAIL",
        **counters,
    },
    "frame_reconstruction": "NOT_REACHED",
    "pcie_aer_kernel_health": "PASS",
    "cleanup": {"result": "PASS", "stream_disabled": True,
                "dma_quiescent": True, "module_unloaded": True,
                "endpoint_automatically_unbound": True, "nodes_removed": True,
                "taint_before": t1_proof["taint_before"],
                "taint_after_load": t1_proof["taint_after_load"],
                "taint_final": cleanup["taint_after_unload"],
                "taint_disposition": "UNCHANGED"},
    "raw_records_published_publicly": False,
    "raw_frame_published_publicly": False,
    "viewable_camera_image_published_publicly": False,
    "flash_programming": False,
    "power_cycle": False,
    "hardware_accessed": True,
    "hardware_subqualification": "NOT_PROVEN",
    "full_g2b_hw_qualification": "NOT_YET_PROVEN",
    "ssot_update_required": False,
    "first_blocker": FIRST_BLOCKER,
}

write(f"V41_{PREFIX}_MAIN_REPORT.md", f"""
# {TASK} Floating-Point Boundary Correction and Finite-Frame Gate

## Result

- Engineering gate: `FAIL`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `FAIL`
- First blocker: `{FIRST_BLOCKER}`

The fresh R3R4R5 run passed predecessor authority, immutable-boundary, exact
R3R4R4 baseline, authorized-delta, all 16 offline self-tests, independent
architecture, credential-helper, exclusivity, continuity, driver, node-map,
runtime identity, NVP, and fixed-input gates. The sole authorized synthetic
change was `1.400 s -> 1.401 s`; its evaluated span was `0.401 s`. Runtime
quiescence remained five consecutive observations spanning at least 400 ms.

Exactly one hardware session was executed. Reset advanced epoch `2 -> 3`.
Inherited `ERROR_STATUS=0x00000007` was normalized by one exact combined W1C
`0x00000007`, after which the status was zero. The reader was started and the
stream enabled once.

The first persisted 4096-byte record parsed structurally, but carried both
`DISCONTINUITY` and `MALFORMED_PRECEDING`. This violates the frozen capture
acceptance contract, so the run failed immediately and no retry was made. The
record file had already been flushed, fsynced, closed, reopened, and read back;
its disk-derived SHA-256 is
`{assessment['first_record_sha256']}`. The payload file and
`FIRST_RECORD_DURABLE` event were correctly withheld because ABI validation
failed.

The failure path preserved `{assessment['primary_records']}` complete chunks
(`{assessment['primary_bytes']}` bytes), plus
`{assessment['incomplete_trailing_bytes']}` trailing bytes. Disk-based analysis
found `{assessment['malformed_records']}` later malformed chunks and
`{assessment['padding_errors']}` padding errors. The post-failure coherent
snapshot recorded `ERROR_STATUS=0x{assessment['final_error_status']:08X}` and
`LAST_ERROR_CAUSE=0x{assessment['final_last_error_cause']:08X}` without clearing
either. Counter reconciliation and frame reconstruction therefore failed or
were not reached.

The safety-disable path completed, parent quiescence passed with five samples
over `{capture_quiescence_last['span_ms']}` ms, and cleanup passed. The exact
module was normally unloaded once; the endpoint automatically unbound, nodes
were removed, PCIe remained Gen2 x1, AER/kernel health remained clean, and
FPGA `DONE` remained 1.

No raw record, raw UYVY frame, or camera PNG is present in this public package.

## Nonclaims

R3R4R5 does not prove durable first-record hardware PASS, the 2500-record finite
capture, a complete real frame, 60-second capture, 288 MB/s throughput,
two-channel operation, four-input selection, synthetic generation, or V4L2.

## Corrective action

Investigate why the first new-epoch record retained `DISCONTINUITY` and
`MALFORMED_PRECEDING`, and why subsequent captured chunks lost record geometry,
under a new explicit governed authorization. Do not retry this R3R4R5 session.
""")

write(f"{PREFIX}_AUTHORIZATION_RECEIPT.md", """
# R3R4R5 Authorization Receipt

- Owner authorization: `GRANTED`
- Authorized hardware sessions: `1`
- Executed hardware sessions: `1`
- Capture retries: `0`
- Conditional SRAM programming maximum/executed: `1 / 0`
- Conditional warm reboot maximum/executed: `1 / 0`
- Driver load maximum/executed: `1 / 1`
- Flash programming: `NO`
- Power-cycle: `NO`
- 60-second capture: `NOT_RUN`
""")

pred_lines = "\n".join(
    f"- {name.upper()}: commit `{row['commit']}`, manifest entries "
    f"`{row['manifest_entries']}`, result `VERIFIED`"
    for name, row in authority["predecessors"].items())
write(f"{PREFIX}_AUTHORITY_VERIFICATION.md", f"""
# R3R4R5 Authority Verification

- Result: `PASS`
- PROJECT_STATE_REV: `8`
- META-8A: `PROMOTED`
- G2B-HW: `NOT_YET_QUALIFIED`
- PRODUCT branch/commit/tree: `{authority['source_branch']}` /
  `{authority['source_commit']}` / `{authority['source_tree']}`
- Bitstream SHA-256: `{authority['bitstream_sha256']}`
- DCP SHA-256: `{authority['dcp_sha256']}`
- ABI SHA-256: `{authority['abi_sha256']}`
- Driver SHA-256: `{authority['driver_sha256']}`

## Predecessors

{pred_lines}
""")

write(f"{PREFIX}_BOUNDARY_RECEIPT.md", f"""
# R3R4R5 Immutable Boundary Receipt

- Result: `{boundary['result']}`
- Prior immutable artifact new writes: `{boundary['prior_immutable_artifact_new_writes']}`
- Removed protected files: `{boundary['removed_files']}`
- Changed protected files: `{boundary['changed_files']}`
- PRODUCT source HEAD/tree/status unchanged: `YES / YES / YES`
""")

copy(RUN / "artifacts" / f"{PREFIX}_TOOL_BASELINE_RECEIPT.md",
     f"{PREFIX}_TOOL_BASELINE_RECEIPT.md")
copy(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_DIFF.md",
     f"{PREFIX}_CAPTURE_TOOL_DIFF.md")
copy(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_DIFF.patch",
     f"{PREFIX}_CAPTURE_TOOL_DIFF.patch")
copy(RUN / "artifacts" / f"{PREFIX}_FLOAT_BOUNDARY_CORRECTION.md",
     f"{PREFIX}_FLOAT_BOUNDARY_CORRECTION.md")
copy(RUN / "artifacts" / f"{PREFIX}_EVENT_ORDERING_PROOF.json",
     f"{PREFIX}_EVENT_ORDERING_PROOF.json")

ordering = selftest["details"]["event_ordering_proof"]
ordering_events = {event["name"]: event for event in ordering["events"]}
write(f"{PREFIX}_EVENT_ORDERING_PROOF.md", f"""
# R3R4R5 Event Ordering Proof

- Result: `PASS`
- Basis: `EVENT_SEQUENCE_PLUS_EXPLICIT_DEPENDENCY`
- Monotonic timestamps used as causal proof: `NO`
- Equal-timestamp case: `PASS`
- Target-before-durable negative case: `PASS`
- FIRST_RECORD_DURABLE event sequence: `{ordering_events['FIRST_RECORD_DURABLE']['event_sequence']}`
- PRIMARY_TARGET_REACHED event sequence: `{ordering_events['PRIMARY_TARGET_REACHED']['event_sequence']}`
- Durable dependency at target acceptance: `PASS`
- Runtime capture semantics changed: `NO`
""")

copy(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_SELFTEST.md",
     f"{PREFIX}_CAPTURE_TOOL_SELFTEST.md")
copy(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_SELFTEST.json",
     f"{PREFIX}_CAPTURE_TOOL_SELFTEST.json")
copy(RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_AUDIT.md",
     f"{PREFIX}_CAPTURE_TOOL_AUDIT.md")
copy(RUN / "artifacts" / f"{PREFIX}_CREDENTIAL_HELPER_AUDIT.md",
     f"{PREFIX}_CREDENTIAL_HELPER_AUDIT.md")

write(f"{PREFIX}_DUT_LOCK_RECEIPT.md", f"""
# R3R4R5 DUT Lock Receipt

- Controller lock: `ACQUIRED`, then `RELEASED LAST`
- Linux lock: `ACQUIRED`, then `RELEASED FIRST`
- Lock boot ID: `{preload['boot_id']}`
- DUT exclusivity: `PASS`
- Parallel HDMI hardware activity: `NONE`
- Helper invocations: `{len(connection_ledger)}`
- Every DUT connection used helper SHA-256 `{helper_sha}`: `{md_bool(all_helper)}`
- Credential remnants after invocations: `{credential_remnants}`

One preliminary task-local process-name detector matched the unrelated CUPS
service because of an unbounded `ups` substring. Read-only resolution proved
no competing hardware process; the detector was narrowed to a word-bounded UPS
pattern before any hardware mutation. Both receipts are retained locally.
""")

write(f"{PREFIX}_RECOVERY_DECISION.md", f"""
# R3R4R5 Recovery Decision

- Recovery path: `NOT_REQUIRED`
- Current boot ID: `{preload['boot_id']}`
- FPGA device / IDCODE / DONE: `xc7a35t / 0362D093 / 1`
- Endpoint: `0000:01:00.0`, `10ee:7011 / 10ee:0007`
- Endpoint and root-port link: `Gen2 x1`
- SRAM programming executed: `0`
- Warm reboot executed: `0`
""")

write(f"{PREFIX}_PRELOAD_INVENTORY.md", f"""
# R3R4R5 Preload Inventory

- Result: `PASS`
- DUT: `VCDE-DUT-HOST-01 / {preload['hostname']} / 10.132.1.111`
- Machine ID: `{preload['machine_id']}`
- Boot ID: `{preload['boot_id']}`
- Kernel / architecture: `{preload['kernel']} / {preload['architecture']}`
- Endpoint / root port: `{preload['endpoint_bdf']} / {preload['root_port_bdf']}`
- PCI identity: `10ee:7011 / 10ee:0007`, class `058000`
- PCIe: `Gen2 x1`
- Endpoint driver before load: `UNBOUND`
- driver_override: `EMPTY`
- platform xdma / xdma_ahd_pcie: `UNLOADED / UNLOADED`
- stale XDMA nodes / holders: `0 / 0`
- parallel hardware processes: `0`
- kernel taint baseline: `{preload['kernel_taint']}`
""")

write(f"{PREFIX}_DRIVER_VERIFICATION.md", f"""
# R3R4R5 Driver Verification

- Result: `PASS`
- Path: `/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`
- Bytes: `{driver_verification['bytes']}`
- SHA-256: `{driver_verification['sha256']}`
- Internal name: `{driver_verification['name']}`
- Alias: `{driver_verification['alias']}`
- Vermagic: `{driver_verification['vermagic']}`
- Secure Boot: `{driver_verification['secure_boot']}`
- Module binary published: `NO`
""")

write(f"{PREFIX}_DRIVER_LOAD_PROBE.md", f"""
# R3R4R5 Driver Load Probe

- Result: `PASS`
- insmod attempts: `{t1['insmod_attempts']}`
- Parameters: `NONE`
- Return code: `{t1['insmod_returncode']}`
- Automatic exact-alias bind: `PASS`
- Bound endpoints: `{', '.join(t1_proof['bound_endpoints'])}`
- Unintended endpoints bound: `{t1_proof['unintended_endpoints_bound']}`
- Kernel/AER fatal delta after load: `NONE`
""")

write(f"{PREFIX}_NODE_TO_BDF_PROOF.md", f"""
# R3R4R5 Node-to-BDF Proof

- Result: `PASS`
- Dynamic XDMA index: `{t1_proof['dynamic_index']}`
- User node: `{t1_proof['user']}`
- C2H node: `{t1_proof['c2h']}`
- Exact BDF: `{t1_proof['bdf']}`
- Independent sysfs char/class correlations: `PASS`
""")

with (STAGING / f"{PREFIX}_NODE_MAP.csv").open("w", encoding=UTF8,
                                                newline="") as handle:
    columns = ["node", "major", "minor", "char_path", "char_device",
               "class_path", "class_device", "bdf"]
    writer = csv.DictWriter(handle, fieldnames=columns)
    writer.writeheader()
    for row in t1_proof["all_nodes"]:
        writer.writerow({**{key: row.get(key, "") for key in columns},
                         "bdf": t1_proof["bdf"]})

copy(REMOTE / "logs" / "mmio-raw.csv", f"{PREFIX}_MMIO_RAW.csv")
copy(REMOTE / "logs" / "mmio-write-ledger.csv",
     f"{PREFIX}_MMIO_WRITE_LEDGER.csv")
write(f"{PREFIX}_MMIO_DECODED.md", f"""
# R3R4R5 MMIO Decode

## Pre-session

- CONTROL: `0x{t2['inherited_control']:08X}`
- STATUS: `0x{t2['inherited_status']:08X}`
- ERROR_STATUS: `0x{t2['inherited_error_status']:08X}`
- LAST_ERROR_CAUSE: `0x{t2['inherited_last_error_cause']:08X}`
- reset epoch: `{t2['inherited_reset_epoch']}`

## Session

- RESET_STREAM_STATE writes: `{write_counts.get('RESET_STREAM_STATE', 0)}`
- reset epoch: `{t2['inherited_reset_epoch']} -> {capture['post_reset_epoch']}`
- normalization W1C mask/writes: `0x{capture['session_normalization_w1c_mask']:08X} / {capture['session_normalization_w1c_writes']}`
- post-normalization ERROR_STATUS: `0x{capture['post_normalization_error_status']:08X}`
- coherent snapshot writes: `{write_counts.get('COHERENT_SNAPSHOT', 0)}`
- stream enable writes: `{write_counts.get('ENABLE_C2H', 0)}`
- normal disable writes: `{write_counts.get('NORMAL_DISABLE', 0)}`
- safety disable writes: `{write_counts.get('SAFETY_DISABLE', 0)}`
- statistics-clear writes: `{statistics_clear_writes}`
- unauthorized writes: `{unauthorized_writes}`

## Post-failure (not cleared)

- CONTROL: `0x{assessment['final_control']:08X}`
- STATUS: `0x{assessment['final_status']:08X}`
- ERROR_STATUS: `0x{assessment['final_error_status']:08X}`
- LAST_ERROR_CAUSE: `0x{assessment['final_last_error_cause']:08X}`
""")

write(f"{PREFIX}_SESSION_START_RECEIPT.md", f"""
# R3R4R5 Session Start Receipt

- Combined T3/T4 sessions: `1`
- Reader ready: `PASS`
- Reset writes: `1`
- Epoch transition: `{t2['inherited_reset_epoch']} -> {capture['post_reset_epoch']} (PASS)`
- Pre-normalization ERROR_STATUS: `0x{capture['post_reset_error_status_before_w1c']:08X}`
- Combined W1C: `0x{capture['session_normalization_w1c_mask']:08X}` exactly once
- Post-normalization ERROR_STATUS: `0x{capture['post_normalization_error_status']:08X}`
- Baseline snapshot generation: `{capture['snapshot_before']['generation']}`
- Enable writes: `1`
- Retry: `NO`
""")

write(f"{PREFIX}_FIRST_RECORD_REPORT.md", f"""
# R3R4R5 First Record Report

- Persistent first-record gate: `FAIL`
- First blocker: `{FIRST_BLOCKER}`
- Persisted bytes: `{assessment['first_record_reread_bytes']}`
- Record file flush/fsync/close/reopen boundary: `COMPLETED`
- Hash source: `REREAD_PERSISTED_FILE`
- Record SHA-256: `{assessment['first_record_sha256']}`
- First record equals primary offset zero: `YES`
- Structural header parse: `PASS`
- Flags: `0x{first_header['flags']:08X}` (`VALID`, `DISCONTINUITY`, `MALFORMED_PRECEDING`)
- Disqualifying continuity flags: `DISCONTINUITY; MALFORMED_PRECEDING`
- Payload geometry in record: `3840 bytes (PASS)`
- Padding: `192 zero bytes (PASS)`
- Dedicated payload file: `NOT_CREATED` because validation failed before payload persistence
- FIRST_RECORD_DURABLE event: `WITHHELD`
- Raw first record published: `NO`
""")

with (STAGING / f"{PREFIX}_FIRST_RECORD_HEADER.csv").open(
        "w", encoding=UTF8, newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["field", "decimal", "hex"])
    for key, value in first_header.items():
        writer.writerow([key, value, f"0x{value:08X}"])

write(f"{PREFIX}_PRIMARY_DURABILITY_CHECKPOINTS.jsonl", json.dumps({
    "task": TASK, "scope": "HARDWARE_SESSION", "result": "NOT_REACHED",
    "checkpoint_schedule": [1024, 2048, 2500], "checkpoint_requested": [],
    "checkpoint_passed": [], "reason": FIRST_BLOCKER,
    "offline_contract_selftest": "PASS",
    "communication": "METADATA_ONLY_RECORD_COUNT",
}, sort_keys=True))

write(f"{PREFIX}_FINITE_CAPTURE_REPORT.md", f"""
# R3R4R5 Finite Capture Report

- Gate: `FAIL`
- Requested primary records: `2500`
- Persisted complete primary chunks: `{assessment['primary_records']}`
- Primary bytes: `{assessment['primary_bytes']}`
- Drain records / bytes: `{assessment['drain_records']} / {assessment['drain_bytes']}`
- Incomplete trailing bytes: `{assessment['incomplete_trailing_bytes']}`
- First-record disqualifying flags: `DISCONTINUITY; MALFORMED_PRECEDING`
- Malformed later chunks: `{assessment['malformed_records']}`
- Padding errors: `{assessment['padding_errors']}`
- Reader terminal blocker: `{reader['blocker']}`
- Capture retry: `0`

All raw files remain private on the task host. Their public evidence is limited
to sizes, hashes, structural counts, and headers.
""")

metrics = [
    ("primary_records_requested", 2500),
    ("primary_records_received", assessment["primary_records"]),
    ("primary_bytes", assessment["primary_bytes"]),
    ("drain_records", assessment["drain_records"]),
    ("drain_bytes", assessment["drain_bytes"]),
    ("incomplete_trailing_bytes", assessment["incomplete_trailing_bytes"]),
    ("total_complete_records", counters["host_complete_records"]),
    ("malformed_records", assessment["malformed_records"]),
    ("padding_errors", assessment["padding_errors"]),
    ("discontinuity_flag_records", assessment["discontinuity_flag_records"]),
    ("primary_sha256", assessment["primary_sha256"]),
    ("drain_sha256", assessment["drain_sha256"]),
    ("trailing_sha256", assessment["trailing_sha256"]),
]
with (STAGING / f"{PREFIX}_FINITE_CAPTURE_METRICS.csv").open(
        "w", encoding=UTF8, newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["metric", "value"])
    writer.writerows(metrics)

copy(REMOTE / "logs" / "quiescence-samples.csv",
     f"{PREFIX}_QUIESCENCE_SAMPLES.csv")

write(f"{PREFIX}_COUNTER_RECONCILIATION.md", f"""
# R3R4R5 Counter Reconciliation

- Result: `FAIL`
- Host complete records: `{counters['host_complete_records']}`
- Host trailing bytes: `{counters['trailing_bytes']}`
- records attempted delta: `{counters['records_attempted_delta']}`
- records committed delta: `{counters['records_committed_delta']}`
- records streamed delta: `{counters['records_streamed_delta']}`
- beats streamed delta: `{counters['beats_streamed_delta']}`
- Expected beats for host complete records: `{counters['expected_host_complete_beats']}`
- records dropped delta: `{counters['records_dropped_delta']}`
- overflow-count delta: `{counters['overflow_count_delta']}`
- discontinuity delta: `{counters['discontinuity_delta']}`
- records abandoned delta: `{counters['records_abandoned_delta']}`
- last global / channel: `{counters['last_global_observed']} / {counters['last_channel_observed']}`

The captured session terminated at the first-record validation failure; the
2500-record equality contract was not reached. No reconciliation PASS is claimed.
""")

write(f"{PREFIX}_FRAME_RECONSTRUCTION_REPORT.md", """
# R3R4R5 Frame Reconstruction Report

- Result: `NOT_REACHED`
- Required geometry: `1920x1080 UYVY`, 4,147,200 bytes
- Reason: first-record validation failed and only 100 complete chunks were preserved
- Raw frame SHA-256: `NONE`
- Viewable frame SHA-256: `NONE`
- Raw UYVY published: `NO`
- Camera PNG published: `NO`
""")

kernel_rows = []
for label, item in health.items():
    source = REMOTE / "logs" / f"kernel-{label}.txt"
    kernel_rows.append(
        f"| {label} | {item['result']} | {item['taint']} | "
        f"{len(item['kernel_fatal_matches'])} | {sha256(source)} |")
write(f"{PREFIX}_PCIE_AER_KERNEL_REVIEW.md", f"""
# R3R4R5 PCIe, AER, and Kernel Review

- Overall result: `PASS`
- PCIe endpoint/root port stayed Gen2 x1: `PASS`
- New AER counter delta: `NONE`
- New Oops/BUG/call trace/hung task/DMA-API/IOMMU/AER/link/engine fatal: `NONE`
- Kernel taint before/after/final: `{t1_proof['taint_before']} / {t1_proof['taint_after_load']} / {cleanup['taint_after_unload']}`
- Taint disposition: `UNCHANGED`

| Phase | Gate | Taint | Fatal matches | Kernel-log SHA-256 |
|---|---:|---:|---:|---|
{chr(10).join(kernel_rows)}

Kernel-log bytes are retained privately; public evidence records only hashes
and the reviewed health summaries.
""")

write(f"{PREFIX}_CLEANUP_RECEIPT.md", f"""
# R3R4R5 Cleanup Receipt

- Result: `{cleanup['result']}`
- Capture result entering cleanup: `{cleanup['capture_result']}`
- Safety-disable writes during cleanup: `{cleanup['safety_disable_writes']}`
- Cleanup quiescence samples/span: `{cleanup['cleanup_quiescence_samples_passed']} / {cleanup['cleanup_quiescence_span_ms']} ms`
- Task reader: `{cleanup['task_reader_cleanup']}`
- XDMA holders before unload: `{len(cleanup['open_xdma_fds_before_unload'])}`
- Normal rmmod attempts/return code: `{cleanup['rmmod_attempts']} / {cleanup['rmmod_returncode']}`
- Forced unloads: `{cleanup['forced_unloads']}`
- Endpoint automatic unbind: `{cleanup['automatic_unbind']}`
- Nodes: `{cleanup['nodes']}`
- PCIe endpoint/root port: `Gen2 x1 / Gen2 x1`
- Linux lock: `RELEASED FIRST`
- Controller lock: `RELEASED LAST`
""")

write(f"{PREFIX}_FINAL_HARDWARE_STATE.md", f"""
# R3R4R5 Final Hardware State

- Boot ID: `{cleanup['boot_id']}`
- Stream disabled: `YES`
- DMA quiescent: `YES`
- xdma_ahd_pcie module: `UNLOADED`
- platform xdma module: `UNLOADED`
- Endpoint: `PRESENT, AUTOMATICALLY UNBOUND`
- XDMA nodes: `REMOVED`
- PCIe endpoint/root port: `Gen2 x1 / Gen2 x1`
- driver_override: `EMPTY`
- FPGA device / IDCODE / DONE: `xc7a35t / 0362D093 / 1`
- Candidate retained in volatile SRAM: `YES`
- Flash programming: `NO`
- Power-cycle: `NO`
- New AER/kernel fatal state: `NONE`
""")

gate_rows = [
    ("PROJECT_STATE_REV_8", "PASS", "8"),
    ("PREDECESSOR_AUTHORITY", "PASS", "R3R3 through R3R4R4"),
    ("IMMUTABLE_BOUNDARY", "PASS", "0 new/removed/changed"),
    ("AUTHORIZED_TOOL_DELTA", "PASS", delta["authorized_tool_delta"]),
    ("OFFLINE_SELFTESTS", "PASS", "16/16"),
    ("CAPTURE_TOOL_ARCHITECTURE", "PASS", "independent audit"),
    ("CREDENTIAL_HELPER", "PASS", helper_sha),
    ("DUT_EXCLUSIVITY", "PASS", "parallel HDMI none"),
    ("CANDIDATE_CONTINUITY", "PASS", "recovery not required"),
    ("DRIVER_LOAD_AND_BIND", "PASS", "one attempt"),
    ("NODE_TO_BDF", "PASS", "0000:01:00.0"),
    ("RUNTIME_IDENTITY_AND_SOURCE", "PASS", "input 0 live"),
    ("RESET_EPOCH_NORMALIZATION", "PASS", "2 to 3; W1C 0x07"),
    ("FIRST_RECORD", "FAIL", FIRST_BLOCKER),
    ("FINITE_2500_CAPTURE", "FAIL", "100/2500; trailing 3584"),
    ("COUNTER_RECONCILIATION", "FAIL", "session stopped early"),
    ("FRAME_RECONSTRUCTION", "NOT_REACHED", "insufficient valid records"),
    ("PCIE_AER_KERNEL_HEALTH", "PASS", "no new fault"),
    ("CLEANUP", "PASS", "normal unload and automatic unbind"),
    ("ENGINEERING_GATE", "FAIL", FIRST_BLOCKER),
    ("EVIDENCE_PUBLICATION", "PENDING", "commit-pinned readback pending"),
]
with (STAGING / f"{PREFIX}_GATE_MATRIX.csv").open(
        "w", encoding=UTF8, newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["gate", "result", "evidence"])
    writer.writerows(gate_rows)

write_json(f"{PREFIX}_STATE.json", state)

# Sanitized raw evidence: no camera bytes, credentials, bitstream, DCP, or module.
raw_sources = {
    RUN / "artifacts" / "authority" / f"{PREFIX}_AUTHORITY.json":
        f"raw/{PREFIX}_AUTHORITY.json",
    RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_DIFF.json":
        f"raw/{PREFIX}_CAPTURE_TOOL_DIFF.json",
    RUN / "artifacts" / f"{PREFIX}_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json":
        f"raw/{PREFIX}_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE.json",
    RUN / "artifacts" / f"{PREFIX}_CREDENTIAL_HELPER_HARD_GATE.json":
        f"raw/{PREFIX}_CREDENTIAL_HELPER_HARD_GATE.json",
    RUN / "artifacts" / "protected-after.comparison.json":
        f"raw/{PREFIX}_BOUNDARY_COMPARISON.json",
    REMOTE / "logs" / "preload-inventory.json":
        f"raw/{PREFIX}_PRELOAD_INVENTORY.json",
    REMOTE / "logs" / "driver-verification.json":
        f"raw/{PREFIX}_DRIVER_VERIFICATION.json",
    REMOTE / "logs" / "t1-result.json": f"raw/{PREFIX}_T1_RESULT.json",
    REMOTE / "logs" / "t1-proof.json": f"raw/{PREFIX}_T1_PROOF.json",
    REMOTE / "logs" / "t2-result.json": f"raw/{PREFIX}_T2_RESULT.json",
    REMOTE / "logs" / "T3T4-result.json": f"raw/{PREFIX}_T3T4_RESULT.json",
    REMOTE / "logs" / "post-failure-assessment.json":
        f"raw/{PREFIX}_POST_FAILURE_ASSESSMENT.json",
    REMOTE / "logs" / "cleanup-result.json": f"raw/{PREFIX}_CLEANUP_RESULT.json",
    REMOTE / "private" / "T3T4-reader-result.json":
        f"raw/{PREFIX}_READER_RESULT.json",
    REMOTE / "private" / "T3T4-capture-journal.jsonl":
        f"raw/{PREFIX}_CAPTURE_JOURNAL.jsonl",
    RUN / "logs" / "jtag-continuity.csv": f"raw/{PREFIX}_JTAG_CONTINUITY.csv",
    RUN / "logs" / "jtag-final.csv": f"raw/{PREFIX}_JTAG_FINAL.csv",
}
for source, destination in raw_sources.items():
    copy(source, destination)
for label in health:
    copy(REMOTE / "logs" / f"health-{label}.json",
         f"raw/{PREFIX}_HEALTH_{label.upper().replace('-', '_')}.json")
write_json(f"raw/{PREFIX}_CONNECTION_LEDGER.json", {
    "task": TASK, "connections": connection_ledger,
    "all_used_exact_helper": all_helper,
    "credential_remnants": credential_remnants,
})
write_json(f"raw/{PREFIX}_PRIVATE_FILE_HASHES.json", {
    "task": TASK,
    "raw_files_published": False,
    "first_record": {"bytes": assessment["first_record_reread_bytes"],
                     "sha256": assessment["first_record_sha256"]},
    "primary": {"bytes": assessment["primary_bytes"],
                "sha256": assessment["primary_sha256"]},
    "drain": {"bytes": assessment["drain_bytes"],
              "sha256": assessment["drain_sha256"]},
    "trailing": {"bytes": assessment["incomplete_trailing_bytes"],
                 "sha256": assessment["trailing_sha256"]},
    "payload_slice": {"bytes": assessment["payload_slice_bytes"],
                      "sha256": assessment["payload_slice_sha256"],
                      "dedicated_payload_file_exists": False},
})

# Publish complete task source, but never compiled bytecode or sealed artifacts.
tool_names = [
    "abi_v1.py", "audit_capture_architecture_r3r4r5.py",
    "audit_tool_delta_r3r4r5.py", "Audit-R3R4R5CredentialHelper.ps1",
    "build_evidence_r3r4r5.py", "capture_r3r4.py",
    "capture_r3r4_selftest.py", "cleanup_r3r4r5.py",
    "Collect-ImmutableBoundary.ps1", "Controller-Lock-R3R4R5.ps1",
    "driver_load_r3r4r5.py", "frame_reconstruct_r3r4.py",
    "health_snapshot_r3r4r5.py", "Invoke-R3R4R5DutConnection.ps1",
    "jtag-read-r3r4r5.tcl", "post_failure_assessment_r3r4r5.py",
    "preload_inventory_r3r4r5.py", "publish_evidence_r3r4r5.py",
    "release_linux_lock_r3r4r5.py", "runtime_identity_r3r4r5.py",
    "V41_C2H_TRANSPORT_ABI_V1.json", "verify_authority_r3r4r5.py",
]
for name in tool_names:
    copy(RUN / "scripts" / name, f"tools/{name}")

with (STAGING / f"{PREFIX}_TOOL_INVENTORY.csv").open(
        "w", encoding=UTF8, newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["path", "bytes", "sha256"])
    for path in sorted((STAGING / "tools").iterdir(), key=lambda item: item.name):
        writer.writerow([f"tools/{path.name}", path.stat().st_size, sha256(path)])

files_before_index = sorted(
    str(path.relative_to(STAGING)).replace("\\", "/")
    for path in STAGING.rglob("*") if path.is_file() and
    path.name not in {f"{PREFIX}_EVIDENCE_INDEX.md",
                      f"{PREFIX}_SHA256_MANIFEST.txt"})
write(f"{PREFIX}_EVIDENCE_INDEX.md", "# R3R4R5 Evidence Index\n\n" +
      "\n".join(f"- `{name}`" for name in files_before_index) +
      "\n\nRaw camera records, raw UYVY frames, and camera PNGs published: `0`.\n")

manifest_path = STAGING / f"{PREFIX}_SHA256_MANIFEST.txt"
manifest_files = sorted(path for path in STAGING.rglob("*") if path.is_file()
                        and path != manifest_path)
manifest_path.write_text("".join(
    f"{sha256(path)}  {str(path.relative_to(STAGING)).replace(chr(92), '/')}\n"
    for path in manifest_files), encoding=UTF8, newline="\n")

forbidden_suffixes = {".bin", ".uyvy", ".png", ".ko", ".bit", ".dcp",
                      ".pyc", ".gz", ".zip"}
forbidden = [str(path.relative_to(STAGING)) for path in STAGING.rglob("*")
             if path.is_file() and path.suffix.lower() in forbidden_suffixes]
if forbidden:
    raise RuntimeError("R3R4R5_PROHIBITED_PUBLIC_BINARY:" + repr(forbidden))

print(json.dumps({
    "result": "PASS", "staging": str(STAGING),
    "files": sum(path.is_file() for path in STAGING.rglob("*")),
    "manifest_entries": len(manifest_files),
    "forbidden_public_binaries": 0,
    "raw_records_published": False,
    "raw_frame_published": False,
    "camera_png_published": False,
}, indent=2))
