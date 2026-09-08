from __future__ import annotations

import csv
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


RUN_ROOT = Path(r"C:\FPGA\G2B_BT656_DIAG1_20260908T142811Z")
SOURCE_ROOT = Path(r"C:\FPGA\V41_G2B_BT656_DIAG1")
STAGING = RUN_ROOT / "evidence-staging" / "v41-development-g2b-bt656-diag1-raw-marker-frame-boundary-trace"
BUILD = RUN_ROOT / "artifacts" / "vivado_build_02"
SIM = RUN_ROOT / "build" / "sim_gate_final_02"

BASE = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_COMMIT = "08cb9f6f227766f3353dfc9ce6b0205d62f03639"
SOURCE_TREE = "dcd5f8e7da149c399ccad73fbf460ac18685a62d"
INITIAL_TRACE_COMMIT = "ef61546f5a75b48d9489378901431bfbbfe32ec8"
FIRST_BLOCKER = "BT656_DIAG1_FULL_BUILD_TIMING_GATE_FAILED:WNS=-4.675ns,TNS=-3545.498ns"


def write_text(name: str, text: str) -> None:
    path = STAGING / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def not_reached_report(title: str, gate: str) -> str:
    return f"""# {title}

- Result: NOT_REACHED
- Reason: hardware authorization required every diagnostic build gate to pass.
- First blocker: `{FIRST_BLOCKER}`
- Hardware accessed: NO
- DUT connections: 0
- FPGA SRAM programming operations: 0
- MMIO operations: 0
- DMA operations: 0
- `{gate}`: NOT_REACHED
"""


STAGING.mkdir(parents=True, exist_ok=True)
(STAGING / "source").mkdir(exist_ok=True)
(STAGING / "build-evidence").mkdir(exist_ok=True)
(STAGING / "simulation").mkdir(exist_ok=True)
(STAGING / "tools").mkdir(exist_ok=True)

source_files = [
    "rtl/g2b/v41_g2b_onech_c2h.sv",
    "rtl/diagnostic/g2b_bt656_boundary_trace.sv",
    "rtl/g2b/v41_g2b_mmio_router.sv",
    "rtl/top/ahd_capture_top_xdma.sv",
    "xdc/common/g2b_bt656_diag1_cdc.xdc",
    "tests/g2b/tb_g2b_bt656_diag1_trace.sv",
    "tests/g2b/tb_g2b_bt656_diag1_parser.sv",
    "tests/g2b/tb_g2b_bt656_diag1_noninterference.sv",
    "scripts/v41/run_g2b_bt656_diag1_simulation_gate.ps1",
    "scripts/v41/g2b_bt656_diag1_build.tcl",
]
for rel in source_files:
    src = SOURCE_ROOT / rel
    dst = STAGING / "source" / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

for name in (
    "decode_g2b_bt656_trace.py",
    "collect_failed_build_metrics.tcl",
    "build_failure_evidence.py",
):
    shutil.copy2(RUN_ROOT / "scripts" / name, STAGING / "tools" / name)

build_files = [
    "DIAG1_BUILD_RESULT.txt",
    "DIAG1_ROUTE_STATUS.rpt",
    "DIAG1_DRC.rpt",
    "DIAG1_CDC.rpt",
    "DIAG1_CHECK_TIMING.rpt",
    "DIAG1_METHODOLOGY.rpt",
    "DIAG1_SOURCE_MANIFEST_SHA256.txt",
    "DIAG1_XDMA_EFFECTIVE_CONFIG.txt",
    "DIAG1_ROUTED_UTILIZATION_FLAT.rpt",
    "DIAG1_TRACE_UTILIZATION.rpt",
    "DIAG1_FAILED_BUILD_METRICS.txt",
]
for name in build_files:
    shutil.copy2(BUILD / name, STAGING / "build-evidence" / name)
shutil.copy2(RUN_ROOT / "logs" / "vivado_full_02.console.log", STAGING / "build-evidence" / "DIAG1_VIVADO_CONSOLE.log")
shutil.copy2(SIM / "G2B_BT656_DIAG1_SIMULATION_GATE.json", STAGING / "simulation" / "G2B_BT656_DIAG1_SIMULATION_GATE.json")
for suite in ("trace", "parser", "noninterference", "affected_regression"):
    shutil.copy2(SIM / suite / "xsim.console.log", STAGING / "simulation" / f"{suite}_xsim.console.log")

setup_lines = (BUILD / "DIAG1_SETUP_TIMING.rpt").read_text(encoding="utf-8", errors="replace").splitlines()
first_path = "\n".join(setup_lines[:150])
write_text("build-evidence/DIAG1_SETUP_WORST_PATH_EXCERPT.rpt", first_path)

write_text(
    "V41_G2B_BT656_DIAG1_MAIN_REPORT.md",
    f"""# AHD v41 G2B-BT656-DIAG1 main report

## Outcome

- Engineering gate: FAIL
- Evidence publication: pending at report generation
- Overall result: FAIL
- First blocker: `{FIRST_BLOCKER}`
- Hardware accessed: NO

The final clean nonincremental Vivado 2025.2 build completed synthesis, optimization, placement, physical optimization and routing. The design is fully routed with zero unrouted or partially routed nets, but setup timing failed: WNS = -4.675 ns and TNS = -3545.498 ns. Hold timing passed with WHS = 0.031 ns and THS = 0.000 ns. Per the governing rule that a build or timing failure is FAIL, execution stopped before creation of a bitstream and before any DUT contact.

The worst setup path begins at `G2B_ONECH_C2H/transport_hard_hold_axi_reg` in `userclk1` and ends at `GEN_BT656_DIAG1_TRACE.BT656_BOUNDARY_TRACE/post_count_source_reg[0]` in `nvp_vclk1`. The path is introduced through the observational trace event qualifier. The generated CDC report independently contains 624 DIAG1 critical CDC rows with no disposition. This CDC issue is secondary evidence; the first failed gate remains setup timing.

## Passed work

- Accepted PRODUCT base: `{BASE}`
- Diagnostic source commit: `{SOURCE_COMMIT}`
- Diagnostic source tree: `{SOURCE_TREE}`
- Diagnostic branch push: PASS
- Simulation gate: 10/10 PASS
- Functional noninterference: PASS
- Synthesis: PASS
- Fully routed: YES
- Unrouted nets: 0
- DRC errors / critical warnings: 0 / 0
- Resource limits: PASS (LUT 88.48%, FF 49.60%, BRAM 60.00%)

## Not reached

No diagnostic bitstream was produced. FPGA programming, warm reboot, DUT connection, driver load, MMIO, DMA, trace acquisition, replay, root-cause decision and correction-candidate creation were not reached. The accepted PRODUCT image and running hardware were untouched.

## Exact corrective direction

Create a fresh governed DIAG1 corrective run that removes the new unqualified `userclk1` dependency from the source-clock trace event/write controls, or transfers the required observation through an explicit reviewed CDC protocol. Then repeat simulation, CDC, full timing sign-off and resource gates before any hardware access. A constraint-only waiver is not supported by this evidence.
""",
)

write_text(
    "G2B_BT656_DIAG1_OWNER_CONTINUITY_ATTESTATION.md",
    """# Owner continuity attestation

- PROJECT_STATE_REV: 8 — OWNER_ATTESTED_NOT_REVERIFIED
- Owner-confirmed unchanged environment: ACCEPTED
- Environment requalification: SKIPPED_BY_OWNER_DECISION
- Same Codex window: YES
- Product worktree and accepted artifact authority were used exactly as specified.
""",
)

write_text(
    "G2B_BT656_DIAG1_SCOPE_AND_AUTHORIZATION.md",
    f"""# Scope and authorization

- Task: G2B-BT656-DIAG1
- Fresh run root: `{RUN_ROOT}`
- Authorized diagnostic source branch only: `diag/v41-g2b-bt656-boundary-trace`
- PRODUCT source branch modified: NO
- Transport ABI changed: NO
- PRODUCT MMIO changed: NO
- Hardware authorization condition: all build gates PASS
- Hardware authorization condition satisfied: NO
- Hardware accessed: NO
- Flash programming: NO
- Power-cycle: NO
""",
)

write_text(
    "G2B_BT656_DIAG1_SOURCE_AUTHORITY.md",
    f"""# Diagnostic source authority

- PRODUCT base / merge base: `{BASE}`
- Initial trace commit: `{INITIAL_TRACE_COMMIT}`
- Final diagnostic source commit: `{SOURCE_COMMIT}`
- Final diagnostic source tree: `{SOURCE_TREE}`
- Branch: `diag/v41-g2b-bt656-boundary-trace`
- Branch publication: PASS
- Diagnostic worktree clean at build launch and completion: YES
- PRODUCT worktree commit: `{BASE}`
- PRODUCT worktree modified: NO
- Final build source identity: exact final diagnostic commit and tree above
""",
)

write_text(
    "G2B_BT656_DIAG1_TRACE_ARCHITECTURE.md",
    """# Trace architecture

- Profile: diagnostic-only `G2B_BT656_DIAG1`
- Trace format: `G2B_BT656_TRACE_ENTRY_V1`
- Logical entry: 16 little-endian 32-bit words / 512 bits
- Physical storage: 512 entries
- Logical capture: 32 pretrigger events plus up to 256 posttrigger events
- Trigger: successful valid EAV associated with source line 1079 in WAIT_EAV
- Stop: next-frame line-1 commit, 256 posttrigger events, or 300000 source clocks
- Data class: marker/control metadata only; no active camera-pixel payload
- PRODUCT functional consumer of trace outputs: none
- Simulation noninterference: PASS
- Hardware usability: NOT REACHED because build timing failed
""",
)

write_text(
    "G2B_BT656_DIAG1_TRACE_SCHEMA.md",
    """# G2B_BT656_TRACE_ENTRY_V1

Each entry is 16 little-endian 32-bit words.

| Word | Meaning |
|---:|---|
| 0 | absolute event sequence |
| 1 | source-clock delta from prior event |
| 2 | chronological parser marker bytes, `0xXY0000FF` for `FF 00 00 XY` |
| 3 | marker/decode/event/control/state flags; bit 31 reserved zero |
| 4 | source frame sequence |
| 5 | source line sequence |
| 6 | next source line |
| 7 | source capture sequence |
| 8 | pending frame |
| 9 | pending line |
| 10 | pending capture |
| 11 | pending/channel-attempt sequence |
| 12 | source lifetime malformed count before event |
| 13 | source lifetime dropped count before event |
| 14 | composed flags on commit, otherwise pending flags |
| 15 | payload count, post-payload count, marker fill, slot, malformed reason and drop reason |

Word 3 bits 0..24 are MARKER_EVENT, MARKER_VALID, F, V, H, XY_VALID, MALFORMED_INCREMENT, SOURCE_DROP_INCREMENT, COMMIT_PULSE, TRIGGER_PULSE, SOURCE_READY, ENABLE_APPLIED, PREVIOUS_SAV_V, SOURCE_LOCKED_BEFORE, SOURCE_LOCKED_AFTER, MONITOR_HAS_ATTEMPT, ALLOCATION_VALID, MONITOR_WRITES_SLOT, RING_FULL, RING_EMPTY, FORMATTER_FATAL, OWNERSHIP_FATAL, and the three stop reasons. Bits 27:25 and 30:28 hold canonical source state before/after.
""",
)

write_text(
    "G2B_BT656_DIAG1_MMIO_MAP.md",
    """# Diagnostic MMIO map

- Identity: `G2B_BT656_TRACE_MMIO_V1`
- Range: `0x3C00..0x3FFF`
- TRACE_MAGIC: `0x42543635`
- TRACE_VERSION: `0x00010000`
- PRODUCT MMIO: unchanged
- Hardware MMIO validation: NOT_REACHED
""",
)

write_text(
    "G2B_BT656_DIAG1_REASON_CODE_MAP.md",
    """# Reason code map

## MALFORMED_REASON

- 0: NONE
- 1: EARLY_MARKER_DURING_ACTIVE_CAPTURE
- 2: INVALID_OR_UNEXPECTED_EAV
- 3: EAV_NOT_FOUND_WITHIN_POST_PAYLOAD_WINDOW
- 4: UNEXPECTED_MARKER_OR_STATE_TRANSITION
- 5: LINE_LENGTH_OR_PAYLOAD_COUNT_MISMATCH
- 15: OTHER

## DROP_REASON

- 0: NONE
- 1: RING_FULL
- 2: MALFORMED_ACTIVE_LINE_ABORT
- 3: RESET_OR_READINESS_ABORT
- 4: FORMATTER_OR_TRANSPORT_ABORT
- 15: OTHER
""",
)

write_text(
    "G2B_BT656_DIAG1_NONINTERFERENCE_REPORT.md",
    """# Functional noninterference report

- Result: PASS
- Test: T9 side-by-side PRODUCT-equivalent versus armed trace
- Result evidence: byte-identical functional outputs
- Trace signals feed no functional parser/transport feedback path.
- Hardware noninterference: NOT_REACHED because no bitstream was produced.
""",
)

write_text(
    "G2B_BT656_DIAG1_SIMULATION_REPORT.md",
    """# Diagnostic trace simulation report

- Final canonical suite: 10/10 PASS
- T1 clear/arm/status: PASS
- T2 marker-byte alignment: PASS
- T3 pretrigger chronological order: PASS
- T4 line-1079 EAV through next-frame line-0/line-1 stop: PASS
- T5 malformed reasons 1/2/3 exact: PASS
- T6 ring-full and malformed drop independence: PASS
- T7 event-limit / clock-timeout freeze: PASS
- T8 dual-clock MMIO readback: PASS
- T9 functional noninterference: PASS
- T10 affected existing G2B regression: PASS
""",
)

build_report = f"""# Diagnostic build report

- Tool: Vivado 2025.2 build 6299465
- Source commit: `{SOURCE_COMMIT}`
- Source tree: `{SOURCE_TREE}`
- Full nonincremental final build: FAIL
- Synthesis: PASS
- opt_design: PASS
- place_design: PASS
- phys_opt_design: PASS
- route_design: completed
- Fully routed: YES
- Unrouted nets: 0
- Partially routed nets: 0
- WNS / TNS: -4.675 ns / -3545.498 ns
- WHS / THS: 0.031 ns / 0.000 ns
- Setup failing endpoints: 1415
- DRC errors / critical warnings: 0 / 0
- CDC disposition: FAIL (624 new DIAG1 critical rows have `None` disposition)
- Total LUT: 18404 / 20800 (88.48%)
- Total FF: 20633 / 41600 (49.60%)
- Total BRAM tiles: 30 / 50 (60.00%)
- Trace LUT / FF / BRAM tiles: 576 / 1195 / 7.5
- First blocker: `{FIRST_BLOCKER}`
- Bitstream generated: NO
- Routed DCP preserved privately: YES
- Routed DCP SHA-256: `548EB8D755BD3618D286FBA33ABA21868F63CD0DD012D668F8FB858302AF6AB3`
- Source manifest SHA-256: `7CFB9D8CC09BA07F4ABE9FFD3120BD9BFE2883F32B8B705FF55C7CDFA916EF43`
"""
write_text("G2B_BT656_DIAG1_BUILD_REPORT.md", build_report)

write_text(
    "G2B_BT656_DIAG1_TIMING_SUMMARY.md",
    f"""# Timing summary

- Gate: FAIL
- WNS: -4.675 ns
- TNS: -3545.498 ns
- Setup failing endpoints: 1415
- WHS: 0.031 ns
- THS: 0.000 ns
- Fully routed: YES
- Worst source: `G2B_ONECH_C2H/transport_hard_hold_axi_reg` (`userclk1`)
- Worst destination: `GEN_BT656_DIAG1_TRACE.BT656_BOUNDARY_TRACE/post_count_source_reg[0]` (`nvp_vclk1`)
- Path type: inter-clock setup
- Data path delay: 3.289 ns
- Requirement: 0.048 ns
- First blocker: `{FIRST_BLOCKER}`

The violating cone reaches the diagnostic trace event/write control. No timing exception or waiver was added after the failed build.
""",
)

write_text(
    "G2B_BT656_DIAG1_DRC_REPORT.md",
    """# DRC report

- Result: PASS
- Errors: 0
- Critical warnings: 0
- Warnings: 25 checks reported
- Design state: Fully Routed
- Full report: `build-evidence/DIAG1_DRC.rpt`
""",
)

write_text(
    "G2B_BT656_DIAG1_CDC_DISPOSITION.md",
    """# CDC disposition

- Result: FAIL
- Total critical CDC rows in generated report: 987
- Critical rows involving `BT656_BOUNDARY_TRACE`: 624
- DIAG1 critical rows with disposition `None`: 624
- Representative source: `G2B_ONECH_C2H/transport_hard_hold_axi_reg`
- Representative destinations: trace `armed_source`, `done_source`, event-sequence enables and RAM/write-control cone
- First failed build gate: setup timing (CDC audit would have failed subsequently)
- Broad CDC waiver: NO
""",
)

write_text(
    "G2B_BT656_DIAG1_RESOURCE_REPORT.md",
    """# Resource report

## Total diagnostic profile

| Resource | Used | Available | Utilization | Limit | Result |
|---|---:|---:|---:|---:|---|
| Slice LUT | 18404 | 20800 | 88.48% | 98% | PASS |
| Slice FF | 20633 | 41600 | 49.60% | 95% | PASS |
| BRAM tile | 30 | 50 | 60.00% | 90% | PASS |

## Trace hierarchy

| Resource | Used | Device percentage |
|---|---:|---:|
| Slice LUT | 576 | 2.77% |
| Slice FF | 1195 | 2.87% |
| BRAM tile | 7.5 | 15.00% |

These are post-route read-only measurements from the failed routed checkpoint. No bitstream was generated.
""",
)

build_report_hash = sha256(STAGING / "G2B_BT656_DIAG1_BUILD_REPORT.md")
write_text(
    "G2B_BT656_DIAG1_BITSTREAM_MANIFEST.md",
    f"""# Bitstream manifest

- Diagnostic classification: NOT_PRODUCED
- Diagnostic bitstream: NONE
- Diagnostic bitstream SHA-256: NONE
- Routed DCP: preserved privately and not published
- Routed DCP SHA-256: `548EB8D755BD3618D286FBA33ABA21868F63CD0DD012D668F8FB858302AF6AB3`
- Source manifest SHA-256: `7CFB9D8CC09BA07F4ABE9FFD3120BD9BFE2883F32B8B705FF55C7CDFA916EF43`
- Main build report SHA-256: `{build_report_hash}`
- LTX generated: NO
- Reason: setup timing gate failed before `write_bitstream`.
""",
)

for filename, title, field in [
    ("G2B_BT656_DIAG1_PROGRAMMING_RECEIPT.md", "Programming receipt", "FPGA_SRAM_PROGRAMMING"),
    ("G2B_BT656_DIAG1_REBOOT_RECEIPT.md", "Warm reboot receipt", "WARM_REBOOT"),
    ("G2B_BT656_DIAG1_DRIVER_LOAD_RECEIPT.md", "Driver load receipt", "DRIVER_LOAD"),
    ("G2B_BT656_DIAG1_RUNTIME_IDENTITY.md", "Runtime identity", "DIAGNOSTIC_RUNTIME_IDENTITY"),
    ("G2B_BT656_DIAG1_DRAIN_HELPER_REPORT.md", "Drain helper report", "DRAIN_HELPER_GATE"),
    ("G2B_BT656_DIAG1_TRACE_READBACK_REPORT.md", "Trace readback report", "TRACE_READBACK"),
    ("G2B_BT656_DIAG1_MARKER_SEQUENCE.md", "Marker sequence", "MARKER_SEQUENCE_ANALYSIS"),
    ("G2B_BT656_DIAG1_LINE0_SOF_ANALYSIS.md", "Line-0 SOF analysis", "LINE0_SOF_ANALYSIS"),
    ("G2B_BT656_DIAG1_TRACE_REPLAY_REPORT.md", "Trace replay report", "TRACE_REPLAY"),
]:
    write_text(filename, not_reached_report(title, field))

write_text(
    "G2B_BT656_DIAG1_MMIO_WRITE_LEDGER.csv",
    "Timestamp,Domain,Offset,Value,Purpose,Result\n",
)
write_text(
    "G2B_BT656_DIAG1_TRACE_STATUS_SAMPLES.csv",
    "Timestamp,Armed,Triggered,Done,Overflow,ValidEntries,StopReason\n",
)
write_text(
    "G2B_BT656_DIAG1_TRACE.csv",
    "EventSequence,SourceClockDelta,MarkerBytes,EventControl,Frame,Line,NextLine,Capture,PendingFrame,PendingLine,PendingCapture,PendingAttempt,MalformedBefore,DroppedBefore,Flags,Aux\n",
)
write_text(
    "G2B_BT656_DIAG1_TRACE.json",
    json.dumps({"result": "NOT_REACHED", "entries": [], "raw_trace_binary": "NOT_CAPTURED"}, indent=2),
)
write_text(
    "G2B_BT656_DIAG1_MALFORMED_EVENT_TIMELINE.csv",
    "EventSequence,Frame,Line,Reason,MalformedBefore,MalformedAfter\n",
)
write_text(
    "G2B_BT656_DIAG1_HYPOTHESIS_MATRIX.csv",
    "Hypothesis,Decision,Evidence\n"
    "H1_LOCK_ADMISSION,NOT_REACHED,Hardware trace not captured\n"
    "H2_VERTICAL_BLANKING,NOT_REACHED,Hardware trace not captured\n"
    "H3_LINE_COUNTER_OFF_BY_ONE,NOT_REACHED,Hardware trace not captured\n"
    "H4_NVP_MODE_MISMATCH,NOT_REACHED,Hardware trace not captured\n"
    "H5_TIMING_OR_PHASE,NOT_REACHED,Hardware trace not captured\n",
)
write_text(
    "G2B_BT656_DIAG1_ROOT_CAUSE_DECISION.md",
    f"""# BT.656 root-cause decision

- Result: NOT_REACHED
- Hardware trace captured: NO
- Trace replay: NOT_REACHED
- Parser/source root-cause claim: NONE
- Correction candidate created: NO
- Build first blocker: `{FIRST_BLOCKER}`

The implementation timing/CDC failure concerns the diagnostic instrument itself. It is not evidence for or against any BT.656 functional root-cause hypothesis.
""",
)
write_text(
    "G2B_BT656_DIAG1_NEXT_MINIMAL_OBSERVABILITY.md",
    """# Next minimal action

No additional hardware observability is authorized from this failed build. First perform one fresh governed diagnostic-source correction that prevents the AXI-domain `transport_hard_hold_axi` cone from directly driving source-domain trace event/write controls. Use an explicit reviewed CDC protocol or a purely source-domain event qualifier; do not add a broad timing waiver. Repeat 10/10 simulation, CDC audit, nonincremental route/timing/DRC/resource gates, and only then consider the same single boundary trace.
""",
)
write_text(
    "G2B_BT656_DIAG1_CLEANUP_RECEIPT.md",
    """# Cleanup receipt

- Hardware accessed: NO
- Stream enable writes: 0
- MMIO writes: 0
- DMA operations: 0
- Driver loaded: NO
- Linux hardware lock acquired: NO
- Controller task lock released: YES
- DUT state changed: NO
- Accepted PRODUCT profile left unchanged: YES
""",
)
write_text(
    "G2B_BT656_DIAG1_FINAL_STATE.md",
    f"""# Final state

- Engineering gate: FAIL
- First blocker: `{FIRST_BLOCKER}`
- Diagnostic bitstream produced: NO
- Hardware accessed: NO
- Final FPGA runtime profile: PRODUCT_PROFILE_UNCHANGED
- PRODUCT source worktree modified: NO
- PRODUCT bitstream changed: NO
- Diagnostic branch pushed: YES
- Correction branch: NONE
- SSOT update required: NO
""",
)
write_text(
    "G2B_BT656_DIAG1_GATE_MATRIX.csv",
    "Gate,Result,Detail\n"
    "OWNER_CONTINUITY,ACCEPTED,Owner-attested state used\n"
    "PRODUCT_WORKTREE_IMMUTABILITY,PASS,Clean at accepted commit\n"
    "DIAGNOSTIC_SOURCE_BRANCH,PASS,Final commit pushed\n"
    "SIMULATION,PASS,10/10\n"
    "FUNCTIONAL_NONINTERFERENCE,PASS,T9 byte-identical\n"
    "SYNTHESIS,PASS,Vivado completed\n"
    "FULLY_ROUTED,PASS,0 unrouted and 0 partial nets\n"
    "SETUP_TIMING,FAIL,WNS=-4.675ns TNS=-3545.498ns\n"
    "HOLD_TIMING,PASS,WHS=0.031ns THS=0.000ns\n"
    "DRC,PASS,0 errors 0 critical warnings\n"
    "CDC,FAIL,624 DIAG1 critical rows with no disposition\n"
    "RESOURCE_LIMITS,PASS,LUT=88.48% FF=49.60% BRAM=60.00%\n"
    "BITSTREAM,NOT_REACHED,Timing gate stopped write_bitstream\n"
    "HARDWARE,NOT_REACHED,Build gates not all PASS\n"
    "TRACE,NOT_REACHED,No hardware access\n"
    "ROOT_CAUSE,NOT_REACHED,No trace\n",
)

state = {
    "task": "G2B-BT656-DIAG1",
    "run_root": str(RUN_ROOT),
    "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
    "engineering_gate": "FAIL",
    "overall_result": "FAIL",
    "first_blocker": FIRST_BLOCKER,
    "source": {
        "base": BASE,
        "commit": SOURCE_COMMIT,
        "tree": SOURCE_TREE,
        "branch": "diag/v41-g2b-bt656-boundary-trace",
        "publication": "PASS",
    },
    "simulation": {"passed": 10, "total": 10, "functional_noninterference": "PASS"},
    "build": {
        "result": "FAIL",
        "fully_routed": True,
        "unrouted_nets": 0,
        "partial_nets": 0,
        "wns_ns": -4.675,
        "tns_ns": -3545.498,
        "whs_ns": 0.031,
        "ths_ns": 0.0,
        "drc": "PASS",
        "cdc": "FAIL",
        "diag1_unresolved_critical_cdc_rows": 624,
        "resources": {
            "lut": {"used": 18404, "available": 20800, "percent": 88.48},
            "ff": {"used": 20633, "available": 41600, "percent": 49.60},
            "bram_tiles": {"used": 30.0, "available": 50.0, "percent": 60.0},
        },
        "bitstream": None,
    },
    "hardware": {
        "accessed": False,
        "dut_connections": 0,
        "fpga_programming": 0,
        "warm_reboot": 0,
        "driver_loads": 0,
        "mmio_operations": 0,
        "dma_operations": 0,
    },
    "trace": {"captured": False, "binary": None, "replay": "NOT_REACHED"},
    "root_cause": "NOT_REACHED",
    "correction_candidate": False,
    "evidence_commit": "ASSIGNED_BY_ENCLOSING_GIT_COMMIT",
    "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
write_text("G2B_BT656_DIAG1_STATE.json", json.dumps(state, indent=2, ensure_ascii=False))

index_lines = [
    "# Evidence index",
    "",
    "This directory records the governed DIAG1 run through its first failed gate.",
    "",
    f"- First blocker: `{FIRST_BLOCKER}`",
    "- Engineering gate: FAIL",
    "- Hardware accessed: NO",
    "- Event trace captured: NO",
    "- `G2B_BT656_DIAG1_TRACE.bin` is intentionally absent: no hardware trace existed, and an empty/fabricated binary was not created.",
    "- The private routed DCP is intentionally not published.",
    "- No bitstream was produced.",
    "",
    "## Published groups",
    "",
    "- Governance, source authority and scope reports",
    "- Complete diagnostic RTL/XDC/test/build-script source subset under `source/`",
    "- Final simulation receipts under `simulation/`",
    "- Sanitized build result, route, DRC, CDC, utilization and worst-path evidence under `build-evidence/`",
    "- Explicit NOT_REACHED receipts for every hardware-dependent stage",
    "- State, gate matrix and SHA-256 manifest",
]
write_text("G2B_BT656_DIAG1_EVIDENCE_INDEX.md", "\n".join(index_lines))

manifest_path = STAGING / "G2B_BT656_DIAG1_SHA256_MANIFEST.txt"
manifest_lines = []
for path in sorted(p for p in STAGING.rglob("*") if p.is_file() and p != manifest_path):
    rel = path.relative_to(STAGING).as_posix()
    manifest_lines.append(f"{sha256(path)}  {rel}")
manifest_path.write_text("\n".join(manifest_lines) + "\n", encoding="ascii", newline="\n")

print(json.dumps({
    "staging": str(STAGING),
    "files": sum(1 for p in STAGING.rglob("*") if p.is_file()),
    "manifest_entries": len(manifest_lines),
    "manifest_sha256": sha256(manifest_path),
}, indent=2))
