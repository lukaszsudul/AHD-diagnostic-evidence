#!/usr/bin/env python3
"""Build the sanitized, append-only G2B-BT656-FIX1 evidence package."""

from __future__ import annotations

import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


ROOT = Path(r"C:\FPGA\G2B_BT656_FIX1_20260909T060432Z")
BUILD = ROOT / "artifacts" / "full-build-20260909T064549Z"
FIX = Path(r"C:\FPGA\V41_G2B_BT656_FIX")
EVIDENCE_REPO = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
EVIDENCE_NAME = "v41-development-g2b-bt656-fix1-build-hardware-qualification"
STAGE = ROOT / "evidence-staging" / EVIDENCE_NAME
DEST = EVIDENCE_REPO / EVIDENCE_NAME
PREFIX = "G2B_BT656_FIX1_"
GENERATED = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
FIRST_BLOCKER = "FIX1_FULL_PRODUCT_BUILD_BUS_SKEW_EXPORT_COUNT_FAILED:EXPECTED_17_FOUND_11"
INITIAL_COMMIT = "bf19702beca9bd85e950fa7ee59fd8ed08b1b2dc"
INITIAL_TREE = "2f72f4fa5dd756443c2d79eb7b75d75badefe921"
HARDENED_COMMIT = "30b14d13b0b789b62b05ab513eb9578c7c43b11a"
HARDENED_TREE = "bdbe39077a03f8945ebdd1ed9e52761fbe787696"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def sanitize(value: str) -> str:
    replacements = {
        "<GOVERNED_USER_REDACTED>": "<GOVERNED_USER_REDACTED>",
        "<CONTROLLER_USER_REDACTED>": "<CONTROLLER_USER_REDACTED>",
        "<CONTROLLER_USER_REDACTED>": "<CONTROLLER_USER_REDACTED>",
    }
    for old, new in replacements.items():
        value = value.replace(old, new)
    return value


def write_text(relative: str, value: str) -> None:
    target = STAGE / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(sanitize(value.rstrip()) + "\n", encoding="utf-8", newline="\n")


def write_json(relative: str, value: object) -> None:
    write_text(relative, json.dumps(value, indent=2, ensure_ascii=False))


def write_csv(relative: str, fields: list[str], rows: list[dict[str, object]]) -> None:
    target = STAGE / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: sanitize(str(row.get(field, ""))) for field in fields})


def copy_text(source: Path, relative: str) -> None:
    write_text(relative, source.read_text(encoding="utf-8-sig", errors="replace"))


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def parse_kv(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8-sig", errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


if STAGE.exists() or DEST.exists():
    raise SystemExit(f"fresh evidence output already exists: stage={STAGE.exists()} dest={DEST.exists()}")
STAGE.mkdir(parents=True)

build = parse_kv(BUILD / "G2B_BUILD_RESULT.txt")
host_gate = read_json(ROOT / "reports" / "host-tool-gate.json")
holder = read_json(ROOT / "logs" / "connection-old-holder-identity.json")
sigterm = read_json(ROOT / "logs" / "connection-old-helper-sigterm.json")
post_cleanup = read_json(ROOT / "logs" / "connection-post-cleanup-state-final.json")
lock_release = read_json(ROOT / "logs" / "connection-release_fresh_linux_lock.json")
native_compile = read_json(ROOT / "logs" / "connection-native-compile-01.json")
native_selftest = read_json(ROOT / "logs" / "connection-native-selftest-01.json")
native_smoke = read_json(ROOT / "logs" / "connection-native-smoke-01.json")

source_manifest_sha = sha256(BUILD / "G2B_BUILD_INPUT_SHA256.txt")
build_result_sha = sha256(BUILD / "G2B_BUILD_RESULT.txt")
helper_sha = sha256(ROOT / "scripts" / "Invoke-BT656Fix1DutConnection.ps1")
native_source_sha = sha256(ROOT / "scripts" / "xdma_c2h_rolling_4k_fix1.c")
controller_sha = sha256(ROOT / "scripts" / "controller_bt656_fix1.py")
validator_sha = sha256(ROOT / "scripts" / "validate_bt656_fix1.py")
frame_sha = sha256(ROOT / "scripts" / "frame_reconstruct_bt656_fix1.py")
build_harness_sha = sha256(ROOT / "scripts" / "g2b_build_fix1.tcl")

diff_result = subprocess.run(
    ["git", "-C", str(FIX), "diff", f"{INITIAL_COMMIT}..{HARDENED_COMMIT}", "--",
     "rtl/g2b/v41_g2b_onech_c2h.sv",
     "tests/g2b/tb_g2b_bt656_line0_sof_fix.sv",
     "tests/g2b/tb_g2b_bt656_vertical_tail_policy_fix1.sv"],
    check=True, capture_output=True, text=True, encoding="utf-8", errors="replace")

main_report = f"""# AHD v41 G2B-BT656-FIX1 main report

## Governed result

- Engineering gate: **FAIL**
- Evidence publication: **PASS** (commit identified by repository history)
- Overall result: **FAIL**
- First blocker: `{FIRST_BLOCKER}`

The retained DIAG1-R1 state was safely cleared, the append-only erratum was
created, and the correction hardening gate passed 9/9. The hardened child
commit `{HARDENED_COMMIT}` was pushed without force.

The fresh nonincremental Vivado 2025.2 PRODUCT build synthesized, optimized,
placed, physically optimized, and physically routed the design. The raw routed
report showed WNS 0.148 ns, TNS 0.000 ns, WHS 0.044 ns, THS 0.000 ns, with zero
unrouted or partially routed nets. The governed flow then stopped in
`ROUTED_REPORTS`: the exact bus-skew exporter required 17 constraints but found
11. No waiver, suppression, constraint change, or second build was used.

Consequently the timing/CDC/DRC/methodology sign-off sequence was not completed,
no bitstream was generated, and the FIX1 FPGA programming, post-program reboot,
driver load, MMIO, DMA capture, record validation, and frame reconstruction were
not reached. The FPGA remains on the inherited DIAG1-R1 volatile profile.

The primary-only rolling host path was nevertheless built and verified before
the build blocker: its focused gate passed 16/16, using 2500 logical 4096-byte
requests, a maximum outstanding window of 1024, no guard IOCBs, pending AIO zero
at `PRIMARY_WINDOW_COMPLETE`, and persistence only after `DISABLE_ISSUED`.

All fresh FIX1 locks were released. Credential remnants are zero. No raw camera
record, frame, PNG, bitstream, DCP, driver binary, native executable, or secret
is included in this evidence directory.
"""
write_text("V41_G2B_BT656_FIX1_MAIN_REPORT.md", main_report)

write_text(PREFIX + "OWNER_CONTINUITY_ATTESTATION.md", f"""# Owner continuity attestation

The Owner-confirmed starting state was accepted without broad requalification:
PROJECT_STATE_REV 8, same Codex window, clean PRODUCT worktree, DIAG1-R1 profile
retained in volatile SRAM, correction branch `fix/v41-g2b-bt656-line0-sof`,
initial candidate `{INITIAL_COMMIT}` / tree `{INITIAL_TREE}`, and retained
DIAG1-R1 helper/AIO/driver state. Prohibited historical, JTAG, boot, hash,
topology, and predecessor audits were not repeated.
""")

write_text(PREFIX + "SCOPE_AND_AUTHORIZATION.md", """# Scope and authorization

Authorized phases were exact retained-state cleanup; append-only erratum;
bounded vertical-tail hardening; one fresh nonincremental PRODUCT build; host
tool preparation; and, only after every offline/build gate passed, one FPGA
programming and one finite hardware capture. The build hard gate failed, so all
hardware qualification actions after the build were withheld. There was no
Flash access, power cycle, JTAG trace, NVP change, timing-phase sweep, 60-second
capture, release creation, broad waiver, message suppression, false path, XDC
change, ABI change, MMIO change, or XDMA change.
""")

write_text(PREFIX + "DIAG1_R1_CLEANUP.md", f"""# DIAG1-R1 retained-state cleanup

- Initial pending AIO: 1023 (Owner-confirmed)
- Exact C2H holder: PID 3522, expected DIAG1-R1 drain-helper lineage
- Initial module refcount: 1
- SIGTERM signals sent: exactly 1
- Result after 12 seconds: helper still present, C2H still held, refcount 1
- Authorized fallback: exactly one graceful warm reboot
- Forced signal/unload: none
- Post-reboot old helper: absent
- Post-reboot `xdma_ahd_pcie`: absent
- Post-reboot `/dev/xdma0_user` and `/dev/xdma0_c2h_0`: absent
- Exact DIAG1-R1 Linux/controller locks: released
- Cleanup result: **PASS**
- Cleanup method: `ONE_GRACEFUL_WARM_REBOOT`

The reboot was cleanup-only and occurred before any FIX1 bitstream existed.
""")

write_text("G2B_BT656_DIAG1_R1_EVIDENCE_ERRATUM.md", f"""# Append-only erratum for G2B-BT656-DIAG1-R1

This file does not rewrite or amend evidence commit
`1994e3a03ab41361f685b57f8e47e0d8349bfc93`.

1. `G2B_BT656_DIAG1_R1_ROOT_CAUSE_DECISION.md` contains a stale final sentence
   saying that no correction candidate was created.
2. Later work in the same governed DIAG1-R1 run did create and publish the
   candidate.
3. The authoritative candidate identity is branch
   `fix/v41-g2b-bt656-line0-sof`, commit `{INITIAL_COMMIT}`, tree
   `{INITIAL_TREE}`.
4. The DIAG1-R1 main report, correction-candidate report, and actual Git commit
   establish the candidate's existence.
5. DIAG1-R1 remained globally BLOCKED only because drain AIO cleanup was
   unresolved.
6. Functional result:
   `PASS_ROOT_CAUSE_PROVEN_CORRECTION_CANDIDATE_READY`.
7. Operational cleanup result: `BLOCKED`.

This FIX1 run resolved the retained operational cleanup separately before any
new build or hardware qualification.
""")

write_text(PREFIX + "SOURCE_AUTHORITY.md", f"""# Source authority

- Worktree: `C:\\FPGA\\V41_G2B_BT656_FIX`
- Branch: `fix/v41-g2b-bt656-line0-sof`
- Initial HEAD: `{INITIAL_COMMIT}`
- Initial tree: `{INITIAL_TREE}`
- Initial tracked state: clean
- Hardened HEAD: `{HARDENED_COMMIT}`
- Hardened tree: `{HARDENED_TREE}`
- Direct parent: `{INITIAL_COMMIT}`
- Final tracked state: clean
- PRODUCT worktree modified: NO
- Diagnostic branch modified: NO
""")

write_text(PREFIX + "VERTICAL_TAIL_POLICY.md", """# Bounded vertical-tail policy

- LAST_ACTIVE_LINE = 1079
- FIRST_VERTICAL_TAIL_LINE = 1080
- LAST_BENIGN_VERTICAL_TAIL_LINE = 1100
- MAX_BENIGN_VERTICAL_TAIL_LINES = 21

Active lines 0..1079 retain normal record behavior. A complete, parity-valid
V-low line-shaped interval 1080..1100 advances only the source-local capture
sequence once, creates no transport attempt, allocation, record, drop,
overflow, or malformed increment, preserves lock, and returns to SRC_IDLE. A
complete interval beyond 1100 is classified exactly once as an unexpected
format/boundary event, follows the existing bounded malformed behavior, and
never creates an active record. NVP configuration is unchanged.
""")

write_text(PREFIX + "CAPTURE_SEQUENCE_DECISION.md", """# Source-capture-sequence decision

Each complete benign tail interval advances source_capture_sequence once while
attempt and global transport sequences do not advance. With the captured
21-line tail, line 1079 sequence S is followed by line 0 at S+22 and line 1 at
S+23. Attempt/global sequences remain consecutive across 1079 to 0. The host
validator recognizes exactly this bounded boundary transition and continues to
reject unexpected source-capture jumps within active lines.
""")

hardening_rows = [
    ("H1", "exact captured 21-line tail", "PASS", "capture delta 22; line0=0x21; line1=0x20; malformed/drop/attempt/commit/overflow tail deltas 0"),
    ("H2", "short legal tails 0,1,20", "PASS", "frame restart and no false malformed"),
    ("H3", "overlong tail line 1101", "PASS", "exactly one malformed; no active record"),
    ("H4", "capture-sequence semantics", "PASS", "21 tail increments; boundary delta 22; attempt/global delta 1"),
    ("H5", "active-line malformed regression", "PASS", "full affected regression deliberate malformed path"),
    ("H6", "overflow independence", "PASS", "full affected regression ring-full path"),
    ("H7", "canonical project VBI fixture", "PASS", "captured and short-tail fixtures"),
    ("H8", "record ABI byte identity", "PASS", "fixed 4096-byte record regression"),
    ("H9", "full affected parser/transport regression", "PASS", "G2B_ONECH_C2H_XSIM_PASS"),
]
write_text(PREFIX + "HARDENING_TEST_REPORT.md", "# FIX1 hardening tests\n\nResult: **9/9 PASS**\n\n" +
           "\n".join(f"- {case} — {name}: **{result}** — {basis}" for case, name, result, basis in hardening_rows) +
           "\n\nThe first H2/H3 testbench observation ended before the final AXI record had drained. Only the testbench wait was corrected to wait on observable record completion; RTL policy was unchanged. The complete suite then passed.")

write_text(PREFIX + "REGRESSION_REPORT.md", """# Regression report

- Captured-pattern vertical-tail: PASS
- Short-tail 0/1/20 and overlong 1101: PASS
- Canonical VBI: PASS
- Deliberate malformed-line behavior: PASS
- Ring-full overflow independence: PASS
- Record ABI identity: PASS
- Full G2B parser/transport: `G2B_ONECH_C2H_XSIM_PASS records=16 bytes=65536 releases=16 expected_queue=16`
- PRODUCT profile: `G2B_PRODUCT_PROFILE_XSIM_PASS checks=37`
- MMIO router: `G2B_MMIO_ROUTER_XSIM_PASS addresses=131072 boundaries=9`
- R1i protected wire semantics: `PASS R1I_FOCUSED_WIRE_SEMANTIC_SUITE`
- R1i candidate/reference semantic SHA-256: `7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49`
""")

write_text(PREFIX + "SOURCE_COMMIT.md", f"""# Hardened source commit

- Parent: `{INITIAL_COMMIT}`
- Commit: `{HARDENED_COMMIT}`
- Tree: `{HARDENED_TREE}`
- Branch: `fix/v41-g2b-bt656-line0-sof`
- Message: `Harden AHD v41 BT656 vertical-tail qualification`
- Push: PASS, without force
- Changed files: `rtl/g2b/v41_g2b_onech_c2h.sv`,
  `tests/g2b/tb_g2b_bt656_line0_sof_fix.sv`, and
  `tests/g2b/tb_g2b_bt656_vertical_tail_policy_fix1.sv`
""")

write_text(PREFIX + "BUILD_REPORT.md", f"""# Fresh nonincremental PRODUCT build

- Vivado: 2025.2 build 6299465
- Exact source commit/tree: `{HARDENED_COMMIT}` / `{HARDENED_TREE}`
- Profile: PRODUCT; diagnostics disabled
- Checkpoint reuse: NO
- Project creation: PASS
- IP generation: PASS
- Synthesis: PASS
- opt_design: PASS
- place_design: PASS
- phys_opt_design: PASS
- route_design operation: completed; fully routed; 0 route errors; 0 unrouted; 0 partial
- Governed build result: **FAIL**
- Stop stage: `ROUTED_REPORTS`
- Exact error: `routed timing export must contain exactly 17 bus-skew constraints; found 11`
- First blocker: `{FIRST_BLOCKER}`
- Constraint waiver/suppression/edit after failure: NO
- Second build: NO
- write_bitstream calls: 0
- Source identity after failure: PASS
- Build-result SHA-256: `{build_result_sha}`
- Build-input-manifest SHA-256: `{source_manifest_sha}`
- Build-harness SHA-256: `{build_harness_sha}`
""")

write_text(PREFIX + "TIMING_SUMMARY.md", """# Routed timing summary

The raw routed timing report was generated before the bus-skew export hard
stop and reports WNS 0.148 ns, TNS 0.000 ns, WHS 0.044 ns, and THS 0.000 ns.
The design was fully routed with no unrouted or partially routed nets.

These values are informational only. The governed timing sign-off is
`NOT_RUN` because the exact bus-skew export prerequisite failed (11 found,
17 required). Timing is therefore not claimed PASS.
""")

write_text(PREFIX + "CDC_DISPOSITION.md", """# CDC disposition

Result: **NOT_REACHED**. A raw CDC report was emitted during routed-report
generation, but the governed critical/warning comparison and disposition gate
did not run because the prior exact bus-skew export gate stopped the build.
No CDC PASS claim is made.
""")

write_text(PREFIX + "DRC_REPORT.md", """# DRC report disposition

Result: **NOT_REACHED** for the governed gate. The raw fully-routed DRC report
contains 14 warnings (PDCN-1569 x1, REQP-1839 x12, RTSTAT-10 x1) and no listed
Error or Critical Warning. However, the scripted DRC gate evaluation did not
run after the earlier bus-skew export failure, so this evidence does not elevate
the DRC gate to PASS.
""")

write_text(PREFIX + "METHODOLOGY_REPORT.md", """# Methodology disposition

Result: **NOT_REACHED**. The methodology report/gate was not executed after the
bus-skew export hard stop. No methodology PASS claim is made.
""")

write_text(PREFIX + "RESOURCE_REPORT.md", """# Resource report

Post-opt resource hard gate: **PASS**.

- LUT: 17821 / 20800 (85.678%; limit 90%)
- FF: 19314 / 41600 (46.428%; task acceptance limit 95%)
- BRAM: 26.5 / 50 (53.000%; task acceptance limit 90%)
- DSP: 0 / 90 (0.000%)

The final routed resource gate was not reached after the bus-skew exporter
stopped the governed flow.
""")

write_text(PREFIX + "BITSTREAM_MANIFEST.md", f"""# FIX1 bitstream manifest

- Candidate classification: `NOT_PRODUCED`
- Bitstream generated: NO
- Bitstream path: NONE
- Bitstream SHA-256: NONE
- LTX generated: NO
- Synth DCP SHA-256: `{build['SYNTH_DCP_SHA256']}`
- Post-opt DCP SHA-256: `{build['POST_OPT_DCP_SHA256']}`
- Routed DCP SHA-256: `{build['ROUTED_DCP_SHA256']}`
- DCP files published: NO

Bitstream generation was correctly withheld after the routed bus-skew export
hard gate failed.
""")

not_reached_build = f"NOT_REACHED — stopped at `{FIRST_BLOCKER}` before hardware authorization."
write_text(PREFIX + "PROGRAMMING_RECEIPT.md", f"# FPGA programming receipt\n\n{not_reached_build}\n\nFPGA SRAM programming: NOT_REACHED. Flash programming: NO. Power-cycle: NO.")
write_text(PREFIX + "REBOOT_RECEIPT.md", f"""# Reboot receipt

- Cleanup fallback warm reboot: 1, PASS
- Post-program warm reboot: NOT_REACHED
- Final cleanup reboot: NO

No FIX1 bitstream was programmed, so the separately authorized post-program
reboot was not executed.
""")
write_text(PREFIX + "RUNTIME_IDENTITY.md", f"# Runtime identity\n\n{not_reached_build}\n\nExpected FIX1 identity was encoded from `{HARDENED_COMMIT}` with PRODUCT BUILD_FLAGS `0x00000102`, but no bitstream existed and no runtime identity was read.")
write_text(PREFIX + "SOURCE_READINESS.md", f"# Source readiness\n\n{not_reached_build}\n\nNo NVP/source-ready/source-lock measurement was performed for FIX1.")

copy_text(ROOT / "reports" / "G2B_BT656_FIX1_HOST_TOOL_GATE.md", PREFIX + "HOST_TOOL_GATE.md")
write_text(PREFIX + "PREQUEUE_RECEIPT.md", f"# Prequeue receipt\n\n{not_reached_build}\n\nOffline contract: primary-only rolling 1024, 2500 logical requests, guard 0, pending AIO zero at PRIMARY_WINDOW_COMPLETE.")
write_csv(PREFIX + "AIO_SUBMISSIONS.csv", ["Status", "Reason", "Submitted"], [{"Status": "NOT_REACHED", "Reason": FIRST_BLOCKER, "Submitted": 0}])
write_csv(PREFIX + "AIO_COMPLETIONS.csv", ["Status", "Reason", "Completed"], [{"Status": "NOT_REACHED", "Reason": FIRST_BLOCKER, "Completed": 0}])
write_text(PREFIX + "PROGRESS.jsonl", json.dumps({"status": "NOT_REACHED", "reason": FIRST_BLOCKER}, separators=(",", ":")))
write_csv(PREFIX + "MMIO_WRITE_LEDGER.csv", ["Timestamp", "Checkpoint", "Offset", "Value", "Purpose", "Result"], [{"Timestamp": "N/A", "Checkpoint": "BUILD_HARD_STOP", "Offset": "N/A", "Value": "N/A", "Purpose": "no FIX1 MMIO", "Result": "NOT_REACHED"}])
write_csv(PREFIX + "COUNTER_TIMELINE.csv", ["Checkpoint", "Epoch", "ErrorStatus", "LastErrorCause", "Attempted", "Committed", "Streamed", "Dropped", "Overflow", "Discontinuity", "Abandoned", "BeatsStreamed"], [{"Checkpoint": "NOT_REACHED_BUILD_HARD_GATE", "Epoch": "N/A", "ErrorStatus": "N/A", "LastErrorCause": "N/A", "Attempted": "N/A", "Committed": "N/A", "Streamed": "N/A", "Dropped": "N/A", "Overflow": "N/A", "Discontinuity": "N/A", "Abandoned": "N/A", "BeatsStreamed": "N/A"}])
write_text(PREFIX + "FIRST_RECORD_REPORT.md", f"# First-record report\n\n{not_reached_build}\n\nNo FIX1 record bytes were captured or published.")
write_csv(PREFIX + "RECORD_INTEGRITY.csv", ["Status", "RecordsRequested", "RecordsValidated", "Failures", "Reason"], [{"Status": "NOT_REACHED", "RecordsRequested": 2500, "RecordsValidated": 0, "Failures": "N/A", "Reason": FIRST_BLOCKER}])
write_csv(PREFIX + "STREAM_CONTINUITY.csv", ["Status", "GlobalFirst", "GlobalLast", "Gaps", "OverflowFlags", "MalformedFlags", "Reason"], [{"Status": "NOT_REACHED", "GlobalFirst": "N/A", "GlobalLast": "N/A", "Gaps": "N/A", "OverflowFlags": "N/A", "MalformedFlags": "N/A", "Reason": FIRST_BLOCKER}])
write_csv(PREFIX + "FRAME_BOUNDARY_ANALYSIS.csv", ["Status", "Line0Present", "Line0SOF", "VerticalBoundaryMalformed", "VerticalBoundaryDrops", "Reason"], [{"Status": "NOT_REACHED", "Line0Present": "N/A", "Line0SOF": "N/A", "VerticalBoundaryMalformed": "N/A", "VerticalBoundaryDrops": "N/A", "Reason": FIRST_BLOCKER}])
write_csv(PREFIX + "CAPTURE_SEQUENCE_ANALYSIS.csv", ["Status", "ExpectedTailJumps", "UnexpectedGaps", "ExpectedDelta", "Reason"], [{"Status": "NOT_REACHED", "ExpectedTailJumps": "N/A", "UnexpectedGaps": "N/A", "ExpectedDelta": 22, "Reason": FIRST_BLOCKER}])
write_text(PREFIX + "FRAME_RECONSTRUCTION_REPORT.md", f"# Frame reconstruction\n\n{not_reached_build}\n\nComplete real frame: NOT_REACHED. Synthetic lines: N/A. Raw frame/PNG: NONE.")
write_text(PREFIX + "POST_TARGET_TAIL_REPORT.md", f"# Post-target tail\n\n{not_reached_build}\n\nTail status and optional post-target reset flush were not reached.")
write_text(PREFIX + "PCIE_AER_KERNEL_REVIEW.md", f"# PCIe/AER/kernel review\n\n{not_reached_build}\n\nNo FIX1 driver load or capture occurred. The cleanup-only reboot completed without a recorded blocker; no FIX1 PCIe/AER/kernel qualification claim is made.")

write_text(PREFIX + "CLEANUP_RECEIPT.md", f"""# Cleanup receipt

## Inherited DIAG1-R1 state

- Exact drain-helper identity: PASS
- Exactly one SIGTERM: YES
- Helper exit within 12 seconds: NO
- Exactly one graceful cleanup reboot: YES
- Old helper/holder/module/nodes after reboot: absent
- Exact old task locks: released

## Fresh FIX1 state

- FIX1 driver loaded: NO
- FIX1 MMIO/DMA opened: NO
- Fresh Linux lock released: PASS
- Fresh controller lock released: PASS
- Credential remnants: 0
- Forced kill/unload: NO
- Final pending FIX1 AIO: N/A (capture not reached; no helper launched)
""")

write_text(PREFIX + "FINAL_STATE.md", f"""# Final state

- Engineering: FAIL at `{FIRST_BLOCKER}`
- Evidence package: prepared for append-only publication
- Hardened correction source: committed and pushed
- FIX1 bitstream: not produced
- FPGA runtime profile: inherited `G2B_BT656_DIAG1_R1_VOLATILE_SRAM`
- FIX1 driver/nodes: not loaded/created
- FIX1 MMIO/DMA/capture: not reached
- Old retained DIAG1-R1 helper/AIO/driver/nodes/locks: cleared
- Fresh FIX1 locks: released
- Credential remnants: 0
- PRODUCT worktree/diagnostic branch/SSOT: unchanged
""")

gate_rows = [
    {"Gate": "OWNER_CONTINUITY", "Result": "PASS", "FirstFailure": "NO", "Evidence": "accepted without broad requalification"},
    {"Gate": "DIAG1_R1_RETAINED_STATE_CLEANUP", "Result": "PASS", "FirstFailure": "NO", "Evidence": "one SIGTERM then one graceful reboot"},
    {"Gate": "APPEND_ONLY_ERRATUM", "Result": "PASS", "FirstFailure": "NO", "Evidence": "historical commit unchanged"},
    {"Gate": "SOURCE_AUTHORITY", "Result": "PASS", "FirstFailure": "NO", "Evidence": HARDENED_COMMIT},
    {"Gate": "BT656_FIX1_HARDENING_9", "Result": "PASS", "FirstFailure": "NO", "Evidence": "9/9"},
    {"Gate": "CORRECTION_BRANCH_PUBLICATION", "Result": "PASS", "FirstFailure": "NO", "Evidence": HARDENED_COMMIT},
    {"Gate": "HOST_TOOL_16", "Result": "PASS", "FirstFailure": "NO", "Evidence": "16/16"},
    {"Gate": "SYNTHESIS", "Result": "PASS", "FirstFailure": "NO", "Evidence": build["SYNTHESIS"]},
    {"Gate": "IMPLEMENTATION_THROUGH_ROUTE", "Result": "PASS", "FirstFailure": "NO", "Evidence": "fully routed; zero unrouted/partial"},
    {"Gate": "ROUTED_BUS_SKEW_EXPORT", "Result": "FAIL", "FirstFailure": "YES", "Evidence": "expected 17 found 11"},
    {"Gate": "TIMING_SIGNOFF", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "prior bus-skew hard stop"},
    {"Gate": "DRC_SIGNOFF", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "prior bus-skew hard stop"},
    {"Gate": "CDC_SIGNOFF", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "prior bus-skew hard stop"},
    {"Gate": "METHODOLOGY_SIGNOFF", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "prior bus-skew hard stop"},
    {"Gate": "BITSTREAM", "Result": "NOT_PRODUCED", "FirstFailure": "NO", "Evidence": "write_bitstream count 0"},
    {"Gate": "HARDWARE_QUALIFICATION", "Result": "NOT_REACHED", "FirstFailure": "NO", "Evidence": "withheld by build hard gate"},
    {"Gate": "FRESH_LOCK_RELEASE", "Result": "PASS", "FirstFailure": "NO", "Evidence": "Linux and controller released"},
    {"Gate": "EVIDENCE_STAGING", "Result": "PASS", "FirstFailure": "NO", "Evidence": EVIDENCE_NAME},
]
write_csv(PREFIX + "GATE_MATRIX.csv", ["Gate", "Result", "FirstFailure", "Evidence"], gate_rows)

state = {
    "schema": "AHD_V41_G2B_BT656_FIX1_STATE_V1",
    "generated_utc": GENERATED,
    "engineering_gate": "FAIL",
    "evidence_publication": "PASS",
    "overall_result": "FAIL",
    "first_blocker": FIRST_BLOCKER,
    "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
    "owner_continuity": "ACCEPTED",
    "cleanup": {"result": "PASS", "method": "ONE_GRACEFUL_WARM_REBOOT", "sigterm": 1, "cleanup_reboot": 1, "old_state_cleared": True},
    "erratum": "PASS",
    "source": {"initial_commit": INITIAL_COMMIT, "initial_tree": INITIAL_TREE, "hardened_commit": HARDENED_COMMIT, "hardened_tree": HARDENED_TREE, "push": "PASS"},
    "hardening_gate": "9/9 PASS",
    "host_tool_gate": "16/16 PASS",
    "build": {"result": "FAIL", "stop_stage": "ROUTED_REPORTS", "fully_routed": True, "unrouted": 0, "partial": 0, "raw_timing_ns": {"WNS": 0.148, "TNS": 0.0, "WHS": 0.044, "THS": 0.0}, "bus_skew_expected": 17, "bus_skew_found": 11, "bitstream_produced": False, "synth_dcp_sha256": build["SYNTH_DCP_SHA256"], "post_opt_dcp_sha256": build["POST_OPT_DCP_SHA256"], "routed_dcp_sha256": build["ROUTED_DCP_SHA256"]},
    "hardware": {"fix1_programming": "NOT_REACHED", "post_program_reboot": "NOT_REACHED", "driver_load": "NOT_REACHED", "mmio": "NOT_REACHED", "dma": "NOT_REACHED", "capture": "NOT_REACHED", "frame": "NOT_REACHED"},
    "locks_released": True,
    "credential_remnants": 0,
    "nonclaims": {"continuous_60_second_performance": "NOT_RUN", "hardware_throughput_288_mb_s": "NOT_PROVEN", "two_channel": "NOT_QUALIFIED", "four_input": "NOT_QUALIFIED", "v4l2": "NOT_TESTED", "release_v41_0_0": "NOT_CREATED"},
}
write_json(PREFIX + "STATE.json", state)

# Publish complete task-local source and the hardened RTL diff, never binaries or camera data.
source_map = {
    "source/hardened_rtl_and_tests.diff": None,
    "source/v41_g2b_onech_c2h.sv": FIX / "rtl" / "g2b" / "v41_g2b_onech_c2h.sv",
    "source/tb_g2b_bt656_line0_sof_fix.sv": FIX / "tests" / "g2b" / "tb_g2b_bt656_line0_sof_fix.sv",
    "source/tb_g2b_bt656_vertical_tail_policy_fix1.sv": FIX / "tests" / "g2b" / "tb_g2b_bt656_vertical_tail_policy_fix1.sv",
    "source/controller_bt656_fix1.py": ROOT / "scripts" / "controller_bt656_fix1.py",
    "source/xdma_c2h_rolling_4k_fix1.c": ROOT / "scripts" / "xdma_c2h_rolling_4k_fix1.c",
    "source/validate_bt656_fix1.py": ROOT / "scripts" / "validate_bt656_fix1.py",
    "source/frame_reconstruct_bt656_fix1.py": ROOT / "scripts" / "frame_reconstruct_bt656_fix1.py",
    "source/abi_v1.py": ROOT / "scripts" / "abi_v1.py",
    "source/V41_C2H_TRANSPORT_ABI_V1.json": ROOT / "scripts" / "V41_C2H_TRANSPORT_ABI_V1.json",
    "source/Invoke-BT656Fix1DutConnection.ps1": ROOT / "scripts" / "Invoke-BT656Fix1DutConnection.ps1",
    "source/host_tool_gate_bt656_fix1.py": ROOT / "scripts" / "host_tool_gate_bt656_fix1.py",
    "source/g2b_build_fix1.tcl": ROOT / "scripts" / "g2b_build_fix1.tcl",
    "source/build_fix1_evidence.py": ROOT / "scripts" / "build_fix1_evidence.py",
}
write_text("source/hardened_rtl_and_tests.diff", diff_result.stdout)
for relative, source in source_map.items():
    if source is not None:
        copy_text(source, relative)

source_hashes = []
for path in sorted((STAGE / "source").iterdir()):
    source_hashes.append({"File": path.name, "Bytes": path.stat().st_size, "SHA256": sha256(path)})
write_csv("source/SOURCE_SHA256.csv", ["File", "Bytes", "SHA256"], source_hashes)

# Compact support evidence; DCPs, bitstream, native executable, and raw media stay private.
support_files = {
    "support/G2B_BUILD_RESULT.txt": BUILD / "G2B_BUILD_RESULT.txt",
    "support/G2B_BUILD_PROVENANCE.txt": BUILD / "G2B_BUILD_PROVENANCE.txt",
    "support/G2B_EXPECTED_RUNTIME_PROVENANCE.txt": BUILD / "G2B_EXPECTED_RUNTIME_PROVENANCE.txt",
    "support/G2B_BUILD_INPUT_SHA256.txt": BUILD / "G2B_BUILD_INPUT_SHA256.txt",
    "support/G2B_OPERATION_COUNTS.txt": BUILD / "G2B_OPERATION_COUNTS.txt",
    "support/POST_OPT_RESOURCE_GATE.txt": BUILD / "POST_OPT_RESOURCE_GATE.txt",
    "support/ROUTE_STATUS.rpt": BUILD / "ROUTE_STATUS.rpt",
    "support/DRC.rpt": BUILD / "DRC.rpt",
    "support/HOST_TOOL_GATE.json": ROOT / "reports" / "host-tool-gate.json",
    "support/sim_h1_captured_tail.log": ROOT / "build" / "sim_h1_captured_tail" / "xsim.log",
    "support/sim_h2_h3_initial_testbench_observation.log": ROOT / "build" / "sim_h2_h3_tail_policy" / "xsim.log",
    "support/sim_h2_h3_corrected_wait.log": ROOT / "build" / "sim_h2_h3_tail_policy_r1" / "xsim.log",
    "support/sim_full_g2b_regression.log": ROOT / "build" / "sim_full_g2b_regression" / "xsim.log",
    "support/sim_product_profile.log": ROOT / "build" / "sim_product_profile" / "xsim.log",
    "support/sim_mmio_router.log": ROOT / "build" / "sim_mmio_router" / "router_xsim.log",
    "support/r1i_candidate_run.log": ROOT / "build" / "sim_r1i_protected" / "wire_focused" / "candidate_run.console.log",
    "support/connection-old-holder-identity.json": ROOT / "logs" / "connection-old-holder-identity.json",
    "support/connection-old-helper-sigterm.json": ROOT / "logs" / "connection-old-helper-sigterm.json",
    "support/connection-post-cleanup-state-final.json": ROOT / "logs" / "connection-post-cleanup-state-final.json",
    "support/connection-native-compile.json": ROOT / "logs" / "connection-native-compile-01.json",
    "support/connection-native-smoke.json": ROOT / "logs" / "connection-native-smoke-01.json",
    "support/connection-native-selftest.json": ROOT / "logs" / "connection-native-selftest-01.json",
    "support/connection-release-fresh-linux-lock.json": ROOT / "logs" / "connection-release_fresh_linux_lock.json",
}
for relative, source in support_files.items():
    copy_text(source, relative)

timing_lines = (BUILD / "TIMING_SUMMARY.rpt").read_text(encoding="utf-8", errors="replace").splitlines()
timing_excerpt = "\n".join(timing_lines[146:154])
write_text("support/TIMING_SUMMARY_EXCERPT.txt", timing_excerpt)
cdc_lines = (BUILD / "CDC.rpt").read_text(encoding="utf-8", errors="replace").splitlines()
write_text("support/CDC_SUMMARY_EXCERPT.txt", "\n".join(cdc_lines[:25]))

write_text(PREFIX + "PUBLICATION_SANITIZATION.md", """# Publication sanitization

Published content contains source, hashes, text reports, and non-image metadata
only. Governed/local account names are redacted in copied receipts and helper
source. Excluded by extension and content audit: credentials, native executable,
FPGA bitstream, DCP, XDMA module, raw records, UYVY frame, and camera PNG.
""")

# Final sanitization pass.
for path in STAGE.rglob("*"):
    if path.is_file():
        content = path.read_text(encoding="utf-8", errors="strict")
        cleaned = sanitize(content)
        if cleaned != content:
            path.write_text(cleaned, encoding="utf-8", newline="\n")

required = [
    "V41_G2B_BT656_FIX1_MAIN_REPORT.md",
    PREFIX + "OWNER_CONTINUITY_ATTESTATION.md", PREFIX + "SCOPE_AND_AUTHORIZATION.md",
    PREFIX + "DIAG1_R1_CLEANUP.md", "G2B_BT656_DIAG1_R1_EVIDENCE_ERRATUM.md",
    PREFIX + "SOURCE_AUTHORITY.md", PREFIX + "VERTICAL_TAIL_POLICY.md",
    PREFIX + "CAPTURE_SEQUENCE_DECISION.md", PREFIX + "HARDENING_TEST_REPORT.md",
    PREFIX + "REGRESSION_REPORT.md", PREFIX + "SOURCE_COMMIT.md",
    PREFIX + "BUILD_REPORT.md", PREFIX + "TIMING_SUMMARY.md",
    PREFIX + "CDC_DISPOSITION.md", PREFIX + "DRC_REPORT.md",
    PREFIX + "METHODOLOGY_REPORT.md", PREFIX + "RESOURCE_REPORT.md",
    PREFIX + "BITSTREAM_MANIFEST.md", PREFIX + "PROGRAMMING_RECEIPT.md",
    PREFIX + "REBOOT_RECEIPT.md", PREFIX + "RUNTIME_IDENTITY.md",
    PREFIX + "SOURCE_READINESS.md", PREFIX + "HOST_TOOL_GATE.md",
    PREFIX + "PREQUEUE_RECEIPT.md", PREFIX + "AIO_SUBMISSIONS.csv",
    PREFIX + "AIO_COMPLETIONS.csv", PREFIX + "PROGRESS.jsonl",
    PREFIX + "MMIO_WRITE_LEDGER.csv", PREFIX + "COUNTER_TIMELINE.csv",
    PREFIX + "FIRST_RECORD_REPORT.md", PREFIX + "RECORD_INTEGRITY.csv",
    PREFIX + "STREAM_CONTINUITY.csv", PREFIX + "FRAME_BOUNDARY_ANALYSIS.csv",
    PREFIX + "CAPTURE_SEQUENCE_ANALYSIS.csv", PREFIX + "FRAME_RECONSTRUCTION_REPORT.md",
    PREFIX + "POST_TARGET_TAIL_REPORT.md", PREFIX + "PCIE_AER_KERNEL_REVIEW.md",
    PREFIX + "CLEANUP_RECEIPT.md", PREFIX + "FINAL_STATE.md",
    PREFIX + "GATE_MATRIX.csv", PREFIX + "STATE.json",
]
missing = [name for name in required if not (STAGE / name).is_file()]
if missing:
    raise SystemExit("missing required evidence: " + ", ".join(missing))

for forbidden in ("*.bin", "*.bit", "*.dcp", "*.ko", "*.uyvy", "*.png", "*.exe", "*.wdb"):
    found = list(STAGE.rglob(forbidden))
    if found:
        raise SystemExit(f"forbidden publication artifact: {found[0]}")

index_name = PREFIX + "EVIDENCE_INDEX.md"
manifest_name = PREFIX + "SHA256_MANIFEST.txt"
indexed = sorted(path.relative_to(STAGE).as_posix() for path in STAGE.rglob("*") if path.is_file())
write_text(index_name, "# Evidence index\n\nAppend-only FIX1 evidence files:\n\n" +
           "\n".join(f"- `{name}`" for name in indexed) +
           f"\n- `{manifest_name}` (self-entry intentionally omitted)")
manifest_paths = sorted(path for path in STAGE.rglob("*") if path.is_file() and path.name != manifest_name)
write_text(manifest_name, "\n".join(f"{sha256(path)}  {path.relative_to(STAGE).as_posix()}" for path in manifest_paths))

# Validate the manifest before copying into the evidence worktree.
for line in (STAGE / manifest_name).read_text(encoding="utf-8").splitlines():
    expected, relative = line.split("  ", 1)
    actual = sha256(STAGE / relative)
    if actual != expected:
        raise SystemExit(f"manifest mismatch: {relative}")

shutil.copytree(STAGE, DEST)
print(json.dumps({
    "result": "PASS",
    "stage": str(STAGE),
    "destination": str(DEST),
    "files": sum(1 for path in DEST.rglob("*") if path.is_file()),
    "manifest_entries": len(manifest_paths),
    "first_blocker": FIRST_BLOCKER,
    "source_hashes": {"native": native_source_sha, "controller": controller_sha,
                      "validator": validator_sha, "frame": frame_sha,
                      "connection_helper": helper_sha},
}, indent=2))
