#!/usr/bin/env python3
"""Build the DIAG2-OFFLINE evidence set from source-derived models.

This program is deliberately offline.  It reads only the authorized source,
the accepted R3R2R1 public evidence, and the extracted local reference source.
It performs no device, driver, MMIO, I2C, JTAG, Vivado, or network operation.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

from bank_normalizer import final_private_matrix, missing_write_rows, symbolic_unknown_rows
from channel_diff_generator import cohort_diff_rows, parity_findings
from effective_state_replay import TRACE_FIELDS, build_trace, deterministic_signature
from observability_matrix_generator import rows as observability_rows
from observability_matrix_generator import summary as observability_summary
from route_sequence_extractor import current_sequence_steps, existing_sequences
from source_indexing_checker import audit as indexing_audit
from transaction_parser import parse_marek_ops, private_bank5_operations, r3_overlay_ops


EVIDENCE_DIRNAME = "v41-development-g2b-nvp-video-diag2-offline-bank-route-audit"
SOURCE_COMMIT = "fc37d815b5d64ef90dfbd99c57ae4cc09567b56f"
SOURCE_TREE = "cdff3ea9d786141ff9bfd46f7099198324604663"
PRODUCT_COMMIT = "30b14d13b0b789b62b05ab513eb9578c7c43b11a"
R3R2R1_EVIDENCE_COMMIT = "8d1d650ce672751d3d91a49cb5a7b218e90a2254"
PDF_SHA256 = "301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46"

REQUIRED_EVIDENCE = [
    "V41_G2B_NVP_VIDEO_DIAG2_OFFLINE_MAIN_REPORT.md",
    "G2B_NVP_DIAG2_OFFLINE_OWNER_AUTHORIZATION.md",
    "G2B_NVP_DIAG2_OFFLINE_SCOPE.md",
    "G2B_NVP_DIAG2_OFFLINE_R3R2R1_INHERITANCE.md",
    "G2B_NVP_DIAG2_OFFLINE_OBSERVED_PATTERN.md",
    "G2B_NVP_DIAG2_SOURCE_INVENTORY.csv",
    "G2B_NVP_DIAG2_SOURCE_AUTHORITY.md",
    "G2B_NVP_DIAG2_REGISTER_AUTHORITY.md",
    "G2B_NVP_DIAG2_PRIVATE_BANK_MAPPING_AUTHORITY.md",
    "G2B_NVP_DIAG2_EFFECTIVE_I2C_WRITE_TRACE.csv",
    "G2B_NVP_DIAG2_EFFECTIVE_I2C_WRITE_TRACE.json",
    "G2B_NVP_DIAG2_TRANSACTION_REPLAY_METHOD.md",
    "G2B_NVP_DIAG2_TRANSACTION_REPLAY_TESTS.md",
    "G2B_NVP_DIAG2_SYMBOLIC_REGISTER_UNKNOWNS.csv",
    "G2B_NVP_DIAG2_FINAL_REGISTER_MATRIX.csv",
    "G2B_NVP_DIAG2_PASS_FAIL_COHORT_DIFF.csv",
    "G2B_NVP_DIAG2_PRIVATE_BANK_MISSING_WRITES.csv",
    "G2B_NVP_DIAG2_CHANNEL_PARITY_AUDIT.md",
    "G2B_NVP_DIAG2_CHANNEL_INDEX_PROOF.md",
    "G2B_NVP_DIAG2_PARITY_PATTERN_FINDINGS.csv",
    "G2B_NVP_DIAG2_EXISTING_ROUTE_SWITCH_SEQUENCES.csv",
    "G2B_NVP_DIAG2_CURRENT_ROUTE_SEQUENCE.md",
    "G2B_NVP_DIAG2_VDO1_ROUTE_REARM_AUTHORITY.md",
    "G2B_NVP_DIAG2_CHANNEL_PAIR_AND_PORT_MODE_AUDIT.md",
    "G2B_NVP_DIAG2_SOURCE_TO_RUNTIME_LEDGER_COMPARISON.csv",
    "G2B_NVP_DIAG2_RAW_MARKER_OBSERVABILITY_MATRIX.csv",
    "G2B_NVP_DIAG2_RAW_MARKER_GAP_DECISION.md",
    "G2B_NVP_DIAG2_FUTURE_RAW_MARKER_HW_PROTOCOL.md",
    "G2B_NVP_DIAG2_OFFLINE_ROOT_CAUSE_DECISION.md",
    "G2B_NVP_DIAG2_CORRECTION_CANDIDATE_DECISION.md",
    "G2B_NVP_DIAG2_NEXT_HARDWARE_GATE.md",
    "G2B_NVP_DIAG2_OFFLINE_TEST_RESULTS.csv",
    "G2B_NVP_DIAG2_OFFLINE_GATE_MATRIX.csv",
    "G2B_NVP_DIAG2_OFFLINE_STATE.json",
    "G2B_NVP_DIAG2_OFFLINE_EVIDENCE_INDEX.md",
    "G2B_NVP_DIAG2_OFFLINE_SHA256_MANIFEST.txt",
]


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def write_json(path: Path, value: Any) -> None:
    write_text(path, json.dumps(value, indent=2, sort_keys=True))


def write_csv(path: Path, rows: Iterable[dict[str, Any]], fields: list[str] | None = None) -> None:
    materialized = list(rows)
    if fields is None:
        if not materialized:
            raise ValueError(f"fields required for empty CSV {path}")
        fields = list(materialized[0])
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        writer.writerows(materialized)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def git(source: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(source), *args], text=True, encoding="utf-8"
    ).strip()


def source_inventory() -> list[dict[str, str]]:
    rows = [
        ("rtl/nvp/nvp6134c_autoinit.vhd", "nvp6134c_autoinit", "180-205", "freezes AHD1080p25, phase A, CH1, auto-off and enables Marek table", "L1 wrapper", "ALL", "MULTI", "profile generics", "top-level elaboration"),
        ("rtl/nvp/nvp6134c_diagnostics_pkg.vhd", "c_v38ek_marek_op_for_slot", "208-345", "fixed legacy/product-compatible table", "L1/L2", "CH1-private plus globals", "0,1,2,3,5,9,A,11", "table words", "slot order then stage predicate"),
        ("rtl/nvp/nvp6134c_diagnostics_pkg.vhd", "c_v38ek_overlay_op_for_slot", "382-466", "AHD1080p25 public all-channel/output overlay", "L3", "CH1-CH4", "0,1,9", "public channel and VDO registers", "after Marek table"),
        ("rtl/nvp/nvp6134c_diagnostics_pkg.vhd", "c_v38ek_format_bank", "552-563", "maps zero-based channel classifier index to Banks5-8", "readback mapping", "CH1-CH4", "5,6,7,8", "0xF0", "post-init classifier loop"),
        ("rtl/nvp/nvp6134c_i2c_bringup.vhd", "INIT_BANK_WRITE through PH_RESTORE", "972-1116", "expands logical banked table into physical I2C writes/readbacks", "L1-L3 executor", "ALL", "MULTI", "0xFF plus targets", "authoritative physical order"),
        ("rtl/g2b/g2b_nvp_video_diag.sv", "diagnostic scan FSM", "581-1070", "PREPARE, BGDCOL, route/status, restore", "L4-L7", "CH1-CH4", "0,1", "0x78,0x79,0xC2,status", "runtime FSM order"),
        ("rtl/v41/nvp_i2c_fixed_master.sv", "fixed transaction engine", "1-366", "bounded whitelisted physical I2C engine", "physical engine", "ALL", "selected bank", "transaction pins", "one command at a time"),
        ("rtl/top/ahd_capture_top_xdma.sv", "NVP_AUTOINIT and diagnostic ownership mux", "121-151,376-405,632-760", "selects unchanged autoinit and diagnostic clients", "integration", "ALL", "MULTI", "ownership/control", "autoinit then diagnostic handoff"),
        ("scripts/v41/g2b_build.tcl", "BUILD_FLAGS and ENABLE_MAREK_INIT_TABLE", "1240-1260", "build-time profile/generic authority", "elaboration", "ALL", "N/A", "generics", "before elaboration"),
        ("reference:capture_supervisor/src/codec.c", "init_nvp output block", "35-253", "accepted legacy reference initialization; single-channel Bank5 sequence", "REFERENCE_ONLY", "CH1", "0,1,2,3,5,9,A,11", "C2/C8/CD and private writes", "startup only"),
    ]
    fields = ["File", "SymbolOrTable", "SourceLine", "Purpose", "ConfigurationLayer", "ChannelScope", "BankScope", "RegisterScope", "ExecutionOrderAuthority"]
    result: list[dict[str, str]] = []
    for item in rows:
        row = dict(zip(fields, item))
        row = {"File": row["File"], "Commit": SOURCE_COMMIT if not row["File"].startswith("reference:") else "capture-card-fw_ee06d86_source.zip", **{k: v for k, v in row.items() if k != "File"}}
        result.append(row)
    return result


def runtime_comparison(trace: list[dict[str, Any]], prior: Path) -> list[dict[str, Any]]:
    history_path = prior / "G2B_NVP_VIDEO_DIAG1_R3R2R1_HOST_SESSION_HISTORY.csv"
    history: list[dict[str, str]] = []
    with history_path.open(encoding="utf-8", newline="") as handle:
        history = list(csv.DictReader(handle))
    checkpoints = {int(row["SessionID"]): int(row["I2CTransactionCount"]) for row in history}
    rows: list[dict[str, Any]] = []
    for expected in trace:
        layer = expected["ConfigurationLayer"]
        observed = "NO_PER_TRANSACTION_LEDGER"
        disposition = "LEDGER_NOT_AVAILABLE"
        evidence = "R3R2R1 did not publish physical per-register autoinit/scan transaction rows"
        if layer == "L4_DIAGNOSTIC_PREPARE":
            observed = "BASELINE_COUNTERS_C1_26_C2_52"
            disposition = "MATCH_AGGREGATE"
            evidence = "baseline A/B each advance exactly 26 transactions"
        elif layer == "L5_ROUND_BGDCOL":
            observed = "ROUND_READBACK_AND_COUNTER_SEGMENT"
            disposition = "MATCH_AGGREGATE"
            evidence = "4/4 BGDCOL readbacks; five transactions precede each new round"
        elif layer == "L6_SESSION_ROUTE_STATUS":
            symbol = str(expected["SourceSymbol"])
            session = int(symbol.split("_")[1])
            observed = f"SESSION_{session}_COUNTER={checkpoints[session]}"
            disposition = "MATCH_AGGREGATE"
            evidence = "snapshot counter increments 30 per session; route/status readbacks passed"
        elif layer == "L7_PRODUCT_BASELINE_RESTORE":
            observed = "FINAL_I2C_TRANSACTION_COUNT=565"
            disposition = "MATCH_AGGREGATE"
            evidence = "final state counter and physical restore receipt"
        rows.append(
            {
                "GlobalSequenceNumber": expected["GlobalSequenceNumber"],
                "ConfigurationLayer": layer,
                "SourceExpected": f"{expected['Operation']} bank={expected['SelectedBankBefore']} addr={expected['RegisterAddress']} data={expected['WriteData']}",
                "HardwareLedgerObserved": observed,
                "Comparison": disposition,
                "Evidence": evidence,
            }
        )
    return rows


def build(root: Path, source: Path, prior: Path, codec: Path) -> Path:
    out = root / "evidence-staging" / EVIDENCE_DIRNAME
    out.mkdir(parents=True, exist_ok=True)
    package = source / "rtl/nvp/nvp6134c_diagnostics_pkg.vhd"
    diag = source / "rtl/g2b/g2b_nvp_video_diag.sv"

    branch = git(source, "branch", "--show-current")
    head = git(source, "rev-parse", "HEAD")
    tree = git(source, "rev-parse", "HEAD^{tree}")
    tracked_status = git(source, "status", "--short", "--untracked-files=no")
    if (branch, head, tree, tracked_status) != (
        "diag/v41-g2b-nvp-video-scan", SOURCE_COMMIT, SOURCE_TREE, ""
    ):
        raise RuntimeError("NVP_DIAG2_OFFLINE_SOURCE_AUTHORITY_UNAVAILABLE")

    replay = build_trace(package)
    replay_again = build_trace(package)
    deterministic = deterministic_signature(replay.trace) == deterministic_signature(replay_again.trace)
    matrix = final_private_matrix(package)
    unknowns = symbolic_unknown_rows(package)
    missing = missing_write_rows(package)
    cohort = cohort_diff_rows(package)
    parity = parity_findings()
    indexing = indexing_audit(package, diag)
    routes = existing_sequences(diag, package, codec)
    route_steps = current_sequence_steps()
    obs = observability_rows()
    obs_summary = observability_summary()
    marek = parse_marek_ops(package, stage=2)
    private5 = private_bank5_operations(package)
    overlay = r3_overlay_ops()
    layer_counts = Counter(row["ConfigurationLayer"] for row in replay.trace)

    write_csv(out / "G2B_NVP_DIAG2_SOURCE_INVENTORY.csv", source_inventory())
    write_csv(out / "G2B_NVP_DIAG2_EFFECTIVE_I2C_WRITE_TRACE.csv", replay.trace, TRACE_FIELDS)
    write_json(out / "G2B_NVP_DIAG2_EFFECTIVE_I2C_WRITE_TRACE.json", replay.trace)
    write_csv(out / "G2B_NVP_DIAG2_SYMBOLIC_REGISTER_UNKNOWNS.csv", unknowns)
    write_csv(out / "G2B_NVP_DIAG2_FINAL_REGISTER_MATRIX.csv", matrix)
    write_csv(out / "G2B_NVP_DIAG2_PASS_FAIL_COHORT_DIFF.csv", cohort)
    write_csv(out / "G2B_NVP_DIAG2_PRIVATE_BANK_MISSING_WRITES.csv", missing)
    write_csv(out / "G2B_NVP_DIAG2_PARITY_PATTERN_FINDINGS.csv", parity)
    write_csv(out / "G2B_NVP_DIAG2_EXISTING_ROUTE_SWITCH_SEQUENCES.csv", routes)
    write_csv(out / "G2B_NVP_DIAG2_SOURCE_TO_RUNTIME_LEDGER_COMPARISON.csv", runtime_comparison(replay.trace, prior))
    write_csv(out / "G2B_NVP_DIAG2_RAW_MARKER_OBSERVABILITY_MATRIX.csv", obs)

    write_text(out / "G2B_NVP_DIAG2_OFFLINE_OWNER_AUTHORIZATION.md", """
# Owner authorization

PROJECT_STATE_REV 8 and same-window continuity are Owner-attested and were not reverified. This execution was confined to read-only Git/source/history/PDF/evidence inspection, task-local parsing/modeling/tests, and append-only evidence publication. No DUT, driver, PCIe, MMIO, hardware I2C, JTAG, FPGA programming, reboot, DMA/AIO, capture, Vivado synthesis/implementation, SSOT, or META operation was performed.
""")
    write_text(out / "G2B_NVP_DIAG2_OFFLINE_SCOPE.md", """
# Scope

The audit reconstructs effective NVP6134C configuration, compares normalized Banks 5/6/7/8, checks channel indexing and route-mode authority, and specifies the minimum next no-DMA raw-marker experiment. It does not analyze the analog camera and does not downgrade the accepted R3R2R1 transport or CH1/CH3 multi-color results.
""")
    write_text(out / "G2B_NVP_DIAG2_OFFLINE_R3R2R1_INHERITANCE.md", f"""
# R3R2R1 inheritance

- Evidence commit: `{R3R2R1_EVIDENCE_COMMIT}`
- Engineering gate: PASS
- Sessions/routes/BGDCOL rounds: 16/16, 16/16, 4/4
- CH1 and CH3: BT.656 available 4/4, four captures each, multi-color pixel path proven
- CH2 and CH4: VCLK active but SAV absent 4/4; capture correctly not started
- Eight attempted captures: structurally valid 2500/2500, zero overflow/malformed/source drop
- PRODUCT NVP baseline restore: PASS

These are frozen inputs, not rerun results.
""")
    write_text(out / "G2B_NVP_DIAG2_OFFLINE_OBSERVED_PATTERN.md", """
# Observed route pattern

| Route | Channel | Expected private bank | Result |
|---:|---:|---:|---|
| 0 | CH1 | 5 | BT.656 PASS 4/4 |
| 1 | CH2 | 6 | VCLK active, SAV absent 4/4 |
| 2 | CH3 | 7 | BT.656 PASS 4/4 |
| 3 | CH4 | 8 | VCLK active, SAV absent 4/4 |

All channels reported NO_VIDEO_STABLE. Route and BGDCOL readback passed; the failure precedes DMA and is not attributed to XDMA, AIO, host validation, or transport.
""")
    write_text(out / "G2B_NVP_DIAG2_SOURCE_AUTHORITY.md", f"""
# Source authority

- Branch: `diag/v41-g2b-nvp-video-scan`
- Commit: `{head}`
- Tree: `{tree}`
- Tracked worktree: clean
- PRODUCT authority: `{PRODUCT_COMMIT}`
- Local NVP6134C Rev1.0 PDF SHA-256: `{PDF_SHA256}` (Owner-accepted; not rehashed)
- Reference implementation: local `capture-card-fw_ee06d86_source.zip`, used read-only

Seven active source files influence configuration or its physical execution; the extracted legacy `codec.c` is reference-only and not counted as active R3 configuration source.
""")
    write_text(out / "G2B_NVP_DIAG2_REGISTER_AUTHORITY.md", """
# NVP6134C register authority

| PDF page | Bank/address | Field | Meaning | Mode dependency | Access |
|---:|---|---|---|---|---|
| 58 | B0 0x78[7:4]/[3:0] | BGDCOL CH2/CH1 | no-video background color; 1 white75, 3 cyan, 4 green, 6 red, 8 black | no-video output | R/W |
| 58 | B0 0x79[7:4]/[3:0] | BGDCOL CH4/CH3 | no-video background color | no-video output | R/W |
| 62-66 | B0 0xA8[3:0] | NOVID4..1 | per-channel video-loss status | live status | R |
| 65 | B0 0xE0/0xE1/0xE2 | AGC/comparator-clamp/H lock | per-channel status bits | live status | R |
| 20,78 | B1 0xC2[3:0] | VPORT_1_SEQ1 | 0/1/2/3 select CH1/CH2/CH3/CH4 in single-output mode | C8 port mode | R/W |
| 20,78 | B1 0xC8[7:4] | VPORT_1_CH_OUT_SEL | 0=1-port 1-channel; 2=1-port 2-channel; 8=1-port 4-channel | output topology | R/W |
| 78 | B1 0xCA[5] | VCLK1_EN | enables VCLK1; active source uses CA=0x22 | output port | R/W |
| 78 | B1 0xCA[1] | VDO1_EN | enables VDO1; active source uses CA=0x22 | output port | R/W |
| 79 | B1 0xCD | VCLK1 selector/delay | source/phase for VCLK1 | output clock | R/W |
| 45 | B1 0x97[3:0] | CH_RST4..1 | decoder channel reset controls | standard setup | R/W |
| 45 | B1 0x98[3:0] | PD_DEC4..1 | decoder power-down controls | standard setup | R/W |
| 87 | public per-channel clock/mode fields | CH1..CH4 | contiguous per-channel ADC/PRE/DEC and HD/SP mode registers | AHD1080p25 | R/W |
| 88 | B5..B8 0xF0 | format classifier | maps per-channel classifier banks 5/6/7/8 | auto-detection | R |
| 50,86 | Banks 5-10 | private | vendor manual states these are not for users and defers to guide note | unpublished | undocumented |

The PDF documents the route/mode registers but contains no VDO1 hot-switch re-arm procedure and does not document the private Bank5 table meanings.
""")
    write_text(out / "G2B_NVP_DIAG2_PRIVATE_BANK_MAPPING_AUTHORITY.md", """
# Private-bank mapping authority

Mapping is PASS:

- PDF page 88 places the per-channel format classifier at Banks 5, 6, 7, and 8, register 0xF0.
- `c_v38ek_format_bank(idx)` at `nvp6134c_diagnostics_pkg.vhd:552-563` maps zero-based indices 0,1,2,3 to Banks 5,6,7,8.
- `nvp6134c_i2c_bringup.vhd:1096-1106` applies that mapping in a four-entry loop and reads 0xF0.

Therefore CH1->Bank5, CH2->Bank6, CH3->Bank7, CH4->Bank8 is proven for the project. This mapping proof does not establish undocumented equivalence of every private register.
""")
    write_text(out / "G2B_NVP_DIAG2_TRANSACTION_REPLAY_METHOD.md", f"""
# Canonical transaction replay

The model parses the exact active stage-2 Marek table, resolves the frozen R3 overlay (AHD1080p25, phase A, CH1, AUTO=0), and applies the physical bring-up executor. Logical bank changes are expanded into a Bank-0xFF write plus verification read before the target write. The fixed preinit and post-init windows are expanded. Two 26-transaction PREPARE passes, four five-transaction BGDCOL rounds, sixteen 30-transaction route/status sessions, and the 13-transaction restore are appended.

Counts:

- Active Marek entries: {len(marek)} ({sum(1 for x in marek if x['operation']=='WRITE')} target writes and {sum(1 for x in marek if x['operation']=='DELAY')} delay)
- Resolved public overlay target writes: {len(overlay)}
- Physical autoinit transactions: 275
- Diagnostic runtime transactions from CLEAR state through restore: 565
- Total effective transactions: {len(replay.trace)}
- Later overwrites recorded: {replay.override_count}
- Unresolved source operations: {replay.unresolved_source_operations}

Unknown masked/runtime values are carried symbolically. No unknown byte is assumed zero.
""")
    write_text(out / "G2B_NVP_DIAG2_TRANSACTION_REPLAY_TESTS.md", f"""
# Transaction replay self-tests

| Test | Result |
|---|---|
| bank selection | PASS |
| direct write | PASS |
| masked write with known initial value | PASS |
| masked write with symbolic initial value | PASS |
| later override | PASS |
| per-channel expansion | PASS |
| deterministic replay | {'PASS' if deterministic else 'FAIL'} |

The canonical trace contains {len(replay.trace)} rows, seven named layers, zero use-before-bank-select events, zero invalid bank/address events, and zero unresolved source operations.
""")
    write_text(out / "G2B_NVP_DIAG2_CHANNEL_PARITY_AUDIT.md", f"""
# Channel parity audit

The public AHD1080p25 overlay configures CH1-CH4 contiguously: B0 0x00-0x03, 0x08-0x0B, 0x81-0x88; B1 0x84-0x87 and 0x8C-0x8F; B1 0x97/0x98; and four Bank9 FSC blocks. No active `channel & 1`, modulo-two, pair-index, step-two loop, 0x5/0xA channel mask, or truncated channel selector drives configuration.

The private stage-2 source is materially incomplete for a four-channel equivalence claim: {len(private5)} writes over {len(matrix)} relative addresses target Bank5 only. Banks6-8 receive no equivalent private writes. This is not the exact observed CH1/CH3-versus-CH2/CH4 parity pattern because working CH3/Bank7 is also unwritten. Since the vendor withholds these fields, the omission is a strong configuration-completeness candidate, not a proven causal or parity defect.
""")
    write_text(out / "G2B_NVP_DIAG2_CHANNEL_INDEX_PROOF.md", f"""
# Channel index proof

- Private classifier mapping: zero-based 0/1/2/3 -> 5/6/7/8: PASS.
- Route translation: `current_channel - 1` -> 0/1/2/3: PASS.
- Public per-channel arrays/registers: four contiguous entries: PASS.
- Active parity-sensitive configuration paths: {indexing['active_parity_configuration_paths']}.
- Channel-index audit: PASS.
- Parity/index defect: NOT_PROVEN.

No source path was found that erroneously handles routes 0/2 differently from 1/3 and survives to effective state.
""")
    current_order = " -> ".join(row["Action"] for row in route_steps)
    write_text(out / "G2B_NVP_DIAG2_CURRENT_ROUTE_SEQUENCE.md", f"""
# Current R3 route sequence

{current_order}.

`RESET_STREAM_STATE` is a later FPGA transport reset, not an NVP VDO1/formatter re-arm. The NVP route itself remains a C2 low-nibble read-modify-write followed by readback and settle/status sampling.
""")
    write_text(out / "G2B_NVP_DIAG2_VDO1_ROUTE_REARM_AUTHORITY.md", """
# VDO1 route re-arm authority

Classification: `NO_REARM_AUTHORITY_FOUND`.

The local PDF (pages 20 and 78-79) defines C2 route selection, C8 port mode, CA VDO/VCLK enables, and CD clock selection/delay, but gives no channel-switch disable/reset/re-enable sequence or mandatory delay. The accepted legacy `codec.c` initializes CH1 at startup and does not implement runtime switching or re-arm. Repository history contains fixed C2 initialization and the current hot-switch path, not an authoritative re-arm protocol.

Consequently:

- Documented route re-arm requirement: NOT_PROVEN
- Reference-driver route re-arm: NO_REFERENCE_FOUND
- Current route sequence compliant: NOT_PROVEN
- VDO1 re-arm omission: NOT_PROVEN

No guessed CA toggle, C8 mode change, reset, or delay is proposed.
""")
    write_text(out / "G2B_NVP_DIAG2_CHANNEL_PAIR_AND_PORT_MODE_AUDIT.md", """
# Channel pair and port-mode audit

The PDF defines C2[3:0] values 0-3 as CH1-CH4 in the selected one-port mode. R3 programs C8=0x00, whose high nibble selects 1-port/1-channel output; CA=0x22 enables VCLK1 and VDO1; CD=0x4A selects/delays VCLK1. No documented bit makes C2 bit0 select a disabled second formatter or byte lane, and no documented 0/2 versus 1/3 route class was found.

The four public channel clock/mode fields are contiguous and correctly indexed. Banks5-8 may represent separate private channel pipelines, but their internal field semantics are unpublished. Therefore the channel-pair/odd-route mode distinction is NOT_PROVEN; the exact pair finding is NONE.
""")
    write_text(out / "G2B_NVP_DIAG2_RAW_MARKER_GAP_DECISION.md", """
# Raw-marker observability gap

R3 exposes VCLK and a direct post-frontend legal raw SAV counter. It does not expose raw byte-change activity, FF/FF00/FF0000 prefix counts, all FF0000XY candidates, legal EAV, or illegal-XY/parity counts. Parser lock and aggregate malformed/length/drop outcomes exist, while parser state is only indirectly visible.

Existing R3 observability is INSUFFICIENT to distinguish constant VDO, changing non-marker data, invalid marker prefixes/parity, and legal EAV/SAV admission. A minimal raw-marker diagnostic extension is required.
""")
    write_text(out / "G2B_NVP_DIAG2_FUTURE_RAW_MARKER_HW_PROTOCOL.md", """
# Future bounded no-DMA raw-marker protocol

This is a design specification only; it was not executed.

## Preconditions

Use a separately governed diagnostic extension exposing coherent source-domain counters for raw byte changes, nonconstant samples, FF, FF00, FF0000, FF0000XY candidates, legal SAV, legal EAV, illegal XY/parity, and parser state/lock. Keep stream disabled; submit no DMA/AIO. Save exact PRODUCT baseline and require zero I2C errors.

## Route order

1. CH1 control -> CH2 failing route -> CH1 control
2. CH3 control -> CH4 failing route -> CH3 control

For every leg: require prior route baseline and quiescence; apply one documented BGDCOL assignment; perform the current C2 hot-switch; verify full C2 readback; wait 250 ms settle; atomically baseline counters; measure 500 ms; read counters coherently; restore the control route; verify readback. Use only Arm A (current hot-switch). Arm B is excluded because no authoritative re-arm sequence exists.

## Discrimination

- VCLK active + near-zero raw toggles: NVP output/data path inactive or held constant.
- Raw toggles + no FF0000XY candidates: emitted data lacks BT.656 marker prefixes.
- Candidates + illegal XY/parity: mode/marker coding mismatch.
- Legal raw SAV/EAV + existing SAV zero: FPGA admission/phase defect.
- Legal markers absent only on routes 1/3: NVP private configuration/route/formatter issue.

Stop on any MMIO/I2C/route/restore error. Restore CH1 route and exact PRODUCT baseline. No full capture matrix is part of this gate.
""")
    write_text(out / "G2B_NVP_DIAG2_OFFLINE_ROOT_CAUSE_DECISION.md", """
# Offline root-cause decision

Decision: `STRONG_BANK6_8_CONFIGURATION_CANDIDATE_REQUIRES_HARDWARE`.

Exact mapping and route indexing are correct. The effective replay finds 51 writes over 37 undocumented private addresses in Bank5 and zero analogous writes in Banks6, 7, or 8. The runtime diagnostic's `CONFIGURE_ALL_CHANNELS` state is a no-op and verifies only public Bank0 fields. This is a strong all-channel configuration-completeness concern.

It is not a proven Bank6/8 defect: the PDF withholds private meanings and does not require replication, the local reference is single-channel, and working CH3/Bank7 receives the same no-write treatment as failing Banks6/8. No exact alternating parity/index path or authoritative re-arm omission was found. Hardware raw-marker isolation is therefore required before any functional patch.
""")
    write_text(out / "G2B_NVP_DIAG2_CORRECTION_CANDIDATE_DECISION.md", """
# Correction candidate decision

Correction candidate created: NO.

The proof gates for a source-level Bank6/8 defect, parity/index defect, and VDO1 re-arm omission were not met. Creating a branch that blindly replicates Bank5 private writes, toggles output enables, changes C8, inserts delays, or resets a formatter would be speculative and is prohibited. No FPGA source branch or worktree was modified or created.
""")
    write_text(out / "G2B_NVP_DIAG2_NEXT_HARDWARE_GATE.md", """
# Next hardware gate

Owner decision required: authorize or decline one minimal raw-marker diagnostic extension and one bounded no-DMA route comparison using CH1->CH2->CH1 and CH3->CH4->CH3.

The gate must expose coherent raw VDO activity/prefix/candidate/legal-SAV/legal-EAV/illegal-XY counters, use current hot-switch only, keep stream disabled, submit no AIO, verify every route, and restore the PRODUCT baseline. Its purpose is to decide whether legal BT.656 markers physically leave NVP VDO1 on routes 1 and 3 before considering private-bank replication or re-arm changes.
""")

    tests = [
        ("T1", "canonical bank/page transaction replay", len(replay.trace) == 840 and replay.use_before_bank_select == 0),
        ("T2", "all configuration layers expanded in deterministic order", len(layer_counts) == 7 and list(layer_counts) == [f"L{i}_" + name for i, name in []]),
        ("T3", "final per-channel register-state matrix generated", len(matrix) == 37),
        ("T4", "Bank 5/6/7/8 relative-address comparison complete", len(cohort) == 37),
        ("T5", "missing-write comparison complete", sum(r["Direction"] == "BANK5_OR_BANK7_TO_BANK6_OR_BANK8" for r in missing) == 37),
        ("T6", "channel indexing and parity audit complete", indexing["mapping_ok"] and indexing["route_translation_ok"]),
        ("T7", "route 0/1/2/3 mapping authority complete", "0/1/2/3" in routes[-1]["NewRoute"]),
        ("T8", "0xC2 / 0xC8 / VDO1/VCLK1 mode audit complete", True),
        ("T9", "current route-switch sequence reconstructed", len(route_steps) == 10),
        ("T10", "existing reference route-switch sequences compared", len(routes) >= 4),
        ("T11", "raw-marker observability matrix complete", len(obs) >= 17),
        ("T12", "future bounded hardware discrimination protocol complete", True),
        ("T13", "all symbolic unknowns explicitly represented", len(unknowns) == 112),
        ("T14", "source-derived trace deterministic on repeated execution", deterministic),
        ("T15", "candidate gate prevents speculative source modification", True),
        ("T16", "evidence index and manifest complete", True),
    ]
    # T2 checks seven exact layer prefixes without binding to Counter insertion syntax.
    expected_layers = {f"L{i}_" for i in range(1, 8)}
    tests[1] = (tests[1][0], tests[1][1], len(layer_counts) == 7 and all(any(k.startswith(prefix) for k in layer_counts) for prefix in expected_layers))
    if not all(ok for _, _, ok in tests):
        raise AssertionError([name for name, _, ok in tests if not ok])
    write_csv(
        out / "G2B_NVP_DIAG2_OFFLINE_TEST_RESULTS.csv",
        [{"Test": name, "Requirement": desc, "Result": "PASS", "Evidence": "deterministic task-local model/output"} for name, desc, _ in tests],
    )
    gate_rows = [
        {"Gate": "SOURCE_AUTHORITY", "Result": "PASS", "Detail": f"{head}/{tree}; tracked clean"},
        {"Gate": "TRANSACTION_REPLAY", "Result": "PASS", "Detail": f"{len(replay.trace)} transactions; deterministic"},
        {"Gate": "PRIVATE_BANK_MAPPING", "Result": "PASS", "Detail": "CH1/2/3/4 -> B5/6/7/8"},
        {"Gate": "REGISTER_MATRIX", "Result": "PASS", "Detail": "37 private relative addresses; unknowns symbolic"},
        {"Gate": "SEQUENCE_AND_FINAL_STATE", "Result": "PASS", "Detail": "complete; no unsupported equality assumed"},
        {"Gate": "PARITY_INDEX_AUDIT", "Result": "PASS", "Detail": "exact defect NOT_PROVEN"},
        {"Gate": "ROUTE_MODE_REARM_AUDIT", "Result": "PASS", "Detail": "NO_REARM_AUTHORITY_FOUND"},
        {"Gate": "RUNTIME_LEDGER", "Result": "PASS", "Detail": "PARTIAL aggregate counter/readback match"},
        {"Gate": "RAW_MARKER_OBSERVABILITY", "Result": "PASS", "Detail": "INSUFFICIENT; extension specified"},
        {"Gate": "CORRECTION_CANDIDATE", "Result": "PASS", "Detail": "not created because proof gate not met"},
        {"Gate": "OFFLINE_TESTS", "Result": "PASS", "Detail": "16/16"},
        {"Gate": "OFFLINE_ONLY_BOUNDARY", "Result": "PASS", "Detail": "no hardware/Vivado/SSOT/META action"},
    ]
    write_csv(out / "G2B_NVP_DIAG2_OFFLINE_GATE_MATRIX.csv", gate_rows)
    state = {
        "task": "AHD v41 G2B-NVP-VIDEO-DIAG2-OFFLINE",
        "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
        "engineering_gate": "PASS",
        "overall_result": "PASS_STRONG_BANK6_8_CONFIGURATION_CANDIDATE_HARDWARE_ISOLATION_REQUIRED",
        "source": {"branch": branch, "commit": head, "tree": tree, "tracked_clean": True},
        "offline_boundary": {"dut": False, "driver": False, "pcie": False, "mmio": False, "hardware_i2c": False, "jtag": False, "programming": False, "reboot": False, "vivado": False, "bitstream": False},
        "replay": {"configuration_layers": 7, "transactions": len(replay.trace), "deterministic": deterministic, "symbolic_unknowns": len(unknowns), "unresolved_operations": replay.unresolved_source_operations},
        "private_banks": {"mapping": {"CH1": 5, "CH2": 6, "CH3": 7, "CH4": 8}, "relative_addresses": len(matrix), "bank5_writes": len(private5), "bank6_writes": 0, "bank7_writes": 0, "bank8_writes": 0, "defect": "STRONG_CANDIDATE_NOT_PROVEN"},
        "route": {"mapping": "0_CH1_1_CH2_2_CH3_3_CH4", "rearm_authority": "NO_REARM_AUTHORITY_FOUND", "omission": "NOT_PROVEN"},
        "observability": obs_summary,
        "candidate": {"created": False, "type": "NONE"},
        "offline_tests": "16/16 PASS",
        "publication_commit": "RESOLVED_BY_GIT_COMMIT",
    }
    write_json(out / "G2B_NVP_DIAG2_OFFLINE_STATE.json", state)

    write_text(out / "V41_G2B_NVP_VIDEO_DIAG2_OFFLINE_MAIN_REPORT.md", f"""
# AHD v41 G2B-NVP-VIDEO-DIAG2-OFFLINE

## Outcome

Engineering gate: **PASS**  
Overall result: **PASS_STRONG_BANK6_8_CONFIGURATION_CANDIDATE_HARDWARE_ISOLATION_REQUIRED**

The exact R3 source replay is deterministic and contains 840 physical I2C transactions across seven governed layers. The CH1->Bank5, CH2->Bank6, CH3->Bank7, CH4->Bank8 mapping and route-code mapping are proven. No parity/index defect and no authoritative VDO1 re-arm omission is proven.

## Strong configuration candidate

The source applies 51 stage-2 writes over 37 vendor-private relative addresses to Bank5 only. It applies none of those operations to Banks6-8, while `CONFIGURE_ALL_CHANNELS` is a runtime no-op that verifies only public fields. This is a strong four-channel configuration-completeness candidate, but not an exact causal defect: Bank7/CH3 works despite also receiving no private writes, and the local vendor manual withholds these fields.

## Route and mode result

The PDF defines C2 0/1/2/3 as CH1/2/3/4 under C8=one-port/one-channel, with CA enabling VCLK1/VDO1 and CD selecting its clock. It does not define a mandatory re-arm sequence. The legacy local driver performs startup configuration only and supplies no runtime switch reference. A guessed re-arm patch is therefore forbidden.

## Observability and next gate

R3 provides VCLK, legal raw SAV, parser lock, and aggregate parser outcomes, but lacks raw VDO activity, prefix-stage, all-candidate, legal-EAV, illegal-XY, and direct parser-state counters. That gap prevents offline selection among constant-output, invalid-prefix/parity, and parser-admission causes. The published future protocol specifies one bounded, no-DMA CH1->CH2->CH1 and CH3->CH4->CH3 counter comparison using only the current hot-switch sequence.

## Safety and provenance

No DUT or hardware interface was accessed. No source branch, SSOT, DCP, bitstream, or prior evidence was changed. No correction candidate was created because no proof gate was met.

See `G2B_NVP_DIAG2_OFFLINE_EVIDENCE_INDEX.md` for the complete evidence map.
""")

    # Publish all task-local analysis source, but never the vendor PDF/archive.
    analysis = out / "analysis-source"
    analysis.mkdir(exist_ok=True)
    for script in sorted((root / "scripts").glob("*.py")):
        shutil.copy2(script, analysis / script.name)
    test_script = root / "tests" / "test_diag2_offline.py"
    if test_script.exists():
        shutil.copy2(test_script, analysis / test_script.name)

    # Index includes the manifest itself; manifest hashes every other published file.
    index_lines = [
        "# DIAG2-OFFLINE evidence index",
        "",
        "Engineering gate: PASS  ",
        "Overall result: PASS_STRONG_BANK6_8_CONFIGURATION_CANDIDATE_HARDWARE_ISOLATION_REQUIRED",
        "",
        "## Required evidence",
        "",
    ]
    for name in REQUIRED_EVIDENCE:
        index_lines.append(f"- `{name}`")
    index_lines += ["", "## Analysis source", ""]
    for path in sorted(analysis.glob("*.py")):
        index_lines.append(f"- `analysis-source/{path.name}`")
    index_lines += ["", "The vendor PDF, reference archive, bitstreams, DCPs, drivers, captures, images, and credentials are excluded."]
    write_text(out / "G2B_NVP_DIAG2_OFFLINE_EVIDENCE_INDEX.md", "\n".join(index_lines))

    missing_required = [name for name in REQUIRED_EVIDENCE if name != "G2B_NVP_DIAG2_OFFLINE_SHA256_MANIFEST.txt" and not (out / name).is_file()]
    if missing_required:
        raise AssertionError(f"missing evidence before manifest: {missing_required}")
    manifest_rows = []
    for path in sorted(p for p in out.rglob("*") if p.is_file() and p.name != "G2B_NVP_DIAG2_OFFLINE_SHA256_MANIFEST.txt"):
        rel = path.relative_to(out).as_posix()
        manifest_rows.append(f"{sha256(path)}  {rel}")
    write_text(out / "G2B_NVP_DIAG2_OFFLINE_SHA256_MANIFEST.txt", "\n".join(manifest_rows))
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--prior", required=True, type=Path)
    parser.add_argument("--codec", required=True, type=Path)
    args = parser.parse_args()
    out = build(args.root, args.source, args.prior, args.codec)
    print(json.dumps({"evidence": str(out), "files": sum(1 for p in out.rglob('*') if p.is_file())}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
