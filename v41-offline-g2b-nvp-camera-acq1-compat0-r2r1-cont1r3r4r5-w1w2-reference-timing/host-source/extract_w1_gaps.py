"""Extract and check resolved-pin gaps from one unchanged SCAN1 XSim run."""

from __future__ import annotations

import csv
import hashlib
import re
from collections import Counter
from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOG = ROOT / "simulation" / "xsim.log"
CSV = ROOT / "reports" / "W1_TRANSACTION_GAPS.csv"
CHECK = ROOT / "reports" / "W1_CHECKER_PROOF.txt"
PUBLIC_PROOF = ROOT / "reports" / "W1_PUBLIC_PROOF_LOG.txt"
PERIOD_NS = Decimal(16)
DERIVED_CYCLES = 3755
DERIVED_NS = Decimal(DERIVED_CYCLES) * PERIOD_NS

ACCEPT = re.compile(
    r"^W1_ACCEPT t_ns=(\d+\.\d+) seq=(\d+) scanner_state=(\d+) "
    r"group=(\d+) entry=(\d+) write=(\d+) reg=([0-9a-f]+) data=([0-9a-f]+)$"
)
EDGE = re.compile(
    r"^W1_EDGE t_ns=(\d+\.\d+) edge=(START|STOP) seq=(\d+) "
    r"(?:repeated=(\d+) )?scanner_state=(\d+) group=(\d+) entry=(\d+)$"
)


@dataclass(frozen=True)
class Command:
    seq: int
    accept_ns: Decimal
    state: int
    group: int
    entry: int
    write: bool
    reg: int
    data: int


@dataclass(frozen=True)
class PinEdge:
    ns: Decimal
    kind: str
    seq: int
    repeated: bool
    state: int
    group: int
    entry: int


def parse():
    commands: dict[int, Command] = {}
    edges: dict[int, list[PinEdge]] = {}
    log = LOG.read_text(encoding="utf-8", errors="replace")
    assert "W1_CLEAN_PASS gen=1 valid=82 tx=105 accepted=105 stretch=0" in log
    assert "ERROR:" not in log and "Fatal:" not in log
    for line in log.splitlines():
        a = ACCEPT.match(line)
        if a:
            t, seq, state, group, entry, write, reg, data = a.groups()
            cmd = Command(int(seq), Decimal(t), int(state), int(group),
                          int(entry), bool(int(write)), int(reg, 16), int(data, 16))
            assert cmd.seq not in commands
            commands[cmd.seq] = cmd
            continue
        e = EDGE.match(line)
        if e:
            t, kind, seq, repeat, state, group, entry = e.groups()
            edge = PinEdge(Decimal(t), kind, int(seq), bool(int(repeat or "0")),
                           int(state), int(group), int(entry))
            edges.setdefault(edge.seq, []).append(edge)
    assert len(commands) == 105, len(commands)
    assert sorted(commands) == list(range(1, 106))
    assert sorted(edges) == list(range(1, 106))
    assert Counter(c.state for c in commands.values()) == {
        3: 1, 4: 10, 5: 10, 6: 82, 7: 1, 8: 1
    }
    for seq, cmd in commands.items():
        got = edges[seq]
        assert got[0].kind == "START" and not got[0].repeated
        assert got[-1].kind == "STOP" and not got[-1].repeated
        assert len(got) == (2 if cmd.write else 3), (seq, cmd, got)
        if not cmd.write:
            assert got[1].kind == "START" and got[1].repeated
        assert all(e.state == cmd.state and e.group == cmd.group for e in got)
        assert cmd.accept_ns < got[0].ns < got[-1].ns
    return commands, edges


def gap_cycles(stop: PinEdge, start: PinEdge) -> int:
    if stop.kind != "STOP" or start.kind != "START":
        raise ValueError("STOP and START endpoints required")
    if start.repeated:
        raise ValueError("internal repeated START is not next transaction")
    if start.seq != stop.seq + 1:
        raise ValueError("nonadjacent transaction sequence")
    elapsed = start.ns - stop.ns
    if elapsed != DERIVED_NS:
        raise ValueError(f"source/model gap disagreement: {elapsed} ns")
    if elapsed % PERIOD_NS:
        raise ValueError("nonintegral FPGA cycles")
    return int(elapsed / PERIOD_NS)


def make_row(kind: str, previous_bank: int, target_bank: int, same: bool,
             cmd: Command, nxt: Command, edges: dict[int, list[PinEdge]],
             applicable: bool) -> dict[str, object]:
    stop = edges[cmd.seq][-1]
    start = edges[nxt.seq][0]
    cycles = gap_cycles(stop, start)
    assert cycles == DERIVED_CYCLES
    us = (start.ns - stop.ns) / Decimal(1000)
    return {
        "boundary_kind": kind,
        "group_index": cmd.group,
        "previous_bank": f"{previous_bank:02X}",
        "target_bank": f"{target_bank:02X}",
        "same_bank_reselection": "YES" if same else "NO",
        "command_kind": {4: "SELECT_GROUP_BANK", 5: "VERIFY_GROUP_BANK", 7: "RESTORE_ENTRY_BANK"}[cmd.state],
        "command_sequence": cmd.seq,
        "next_command_sequence": nxt.seq,
        "stop_time_ns": f"{stop.ns:.3f}",
        "next_start_time_ns": f"{start.ns:.3f}",
        "gap_ns": f"{start.ns - stop.ns:.3f}",
        "gap_fpga_cycles": cycles,
        "gap_us": f"{us:.3f}",
        "source_derived_cycles": DERIVED_CYCLES,
        "agreement": "PASS",
        "model_assumptions": "digital immediate open-drain rise; no extra stretch; valid ACK; no other client; 62.5MHz",
        "source_or_trace_reference": "W1/simulation/xsim.log W1_ACCEPT/W1_EDGE; W1_TIMING_DERIVATION.md",
        "reference_comparison_applicable": "POST_WRITE_WAIT_CONTEXT" if applicable else "NOT_APPLICABLE",
        "delta_vs_200us": f"{us - Decimal(200):.3f}" if applicable else "NOT_APPLICABLE",
        "delta_vs_300us": f"{us - Decimal(300):.3f}" if applicable else "NOT_APPLICABLE",
    }


def main():
    commands, edges = parse()
    for seq in range(1, 105):
        assert gap_cycles(edges[seq][-1], edges[seq + 1][0]) == DERIVED_CYCLES
    rows = []
    banks: dict[int, int] = {}
    for cmd in commands.values():
        if cmd.state == 4:
            assert cmd.write and cmd.reg == 0xFF
            assert cmd.group not in banks
            banks[cmd.group] = cmd.data
            prev = 0 if cmd.group == 0 else banks[cmd.group - 1]
            nxt = commands[cmd.seq + 1]
            assert nxt.state == 5 and nxt.group == cmd.group and not nxt.write
            rows.append(make_row("SELECT_WRITE_STOP_TO_VERIFY_INITIAL_START", prev,
                                 cmd.data, cmd.group > 0 and prev == cmd.data,
                                 cmd, nxt, edges, True))
        elif cmd.state == 5:
            nxt = commands[cmd.seq + 1]
            assert nxt.state == 6 and nxt.group == cmd.group and not nxt.write
            bank = banks[cmd.group]
            prev = 0 if cmd.group == 0 else banks[cmd.group - 1]
            rows.append(make_row("VERIFY_READ_STOP_TO_FIRST_ENTRY_INITIAL_START", prev,
                                 bank, cmd.group > 0 and prev == bank,
                                 cmd, nxt, edges, False))
        elif cmd.state == 7:
            nxt = commands[cmd.seq + 1]
            assert nxt.state == 8 and not nxt.write and cmd.reg == 0xFF
            rows.append(make_row("RESTORE_WRITE_STOP_TO_VERIFY_INITIAL_START", banks[9],
                                 cmd.data, banks[9] == cmd.data, cmd, nxt, edges, False))
    assert sorted(banks) == list(range(10))
    assert len(rows) == 21
    CSV.parent.mkdir(parents=True, exist_ok=True)
    with CSV.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    first_select = next(c for c in commands.values() if c.state == 4)
    stop = edges[first_select.seq][-1]
    next_start = edges[first_select.seq + 1][0]
    shifted_rejected = False
    try:
        gap_cycles(PinEdge(stop.ns + PERIOD_NS, stop.kind, stop.seq, stop.repeated,
                           stop.state, stop.group, stop.entry), next_start)
    except ValueError as exc:
        shifted_rejected = "disagreement" in str(exc)
    assert shifted_rejected
    repeated = edges[first_select.seq + 1][1]
    repeated_rejected = False
    try:
        gap_cycles(stop, repeated)
    except ValueError as exc:
        repeated_rejected = "repeated START" in str(exc)
    assert repeated_rejected
    kinds = Counter(r["boundary_kind"] for r in rows)
    same = sum(r["same_bank_reselection"] == "YES" and
               r["boundary_kind"].startswith("SELECT") for r in rows)
    CHECK.write_text(
        f"XSim log: {LOG}\n"
        f"Complete scan: 105 accepted, 82 entry reads, 10 group selects, "
        f"10 group verifies, one entry-bank restore and verify.\n"
        f"All 105 commands: one resolved initial START, one STOP; "
        f"all 94 reads: one internal repeated START.\n"
        f"All 104 adjacent resolved STOP-to-initial-START gaps: "
        f"{DERIVED_CYCLES} cycles = {DERIVED_NS} ns.\n"
        f"W1 CSV rows: {len(rows)}; kinds={dict(kinds)}; "
        f"same-bank group reselections={same}; banks={banks}.\n"
        "Negative test 1: shift first select STOP by +16 ns: REJECTED (source/model gap disagreement).\n"
        "Negative test 2: substitute verify-read internal repeated START: REJECTED (not next transaction).\n",
        encoding="utf-8",
    )
    log_sha = hashlib.sha256(LOG.read_bytes()).hexdigest().upper()
    source_lines = []
    for filename in ("g2b_nvp_camera_scan1_manifest_pkg.sv",
                     "nvp_i2c_fixed_master.sv", "g2b_nvp_camera_scan1.sv"):
        source = ROOT / "inputs" / filename
        source_lines.append(
            f"COMPILED_INPUT {filename} SHA256={hashlib.sha256(source.read_bytes()).hexdigest().upper()}"
        )
    proof_lines = [
        "W1 PUBLIC RESOLVED-LINE TIMING PROOF",
        "AUTHORITY_COMMIT 09cd7cbb426027acaefd0cf3989579b80a451f3a",
        "AUTHORITY_TREE c6be008ddc387c1f43eefa35d4fed0e2ccb968db",
        "SIMULATOR XSim 2025.2 SW Build 6299465; time resolution 1 ps",
        *source_lines,
        f"PRIVATE_FULL_TRACE_SHA256 {log_sha}",
        "MODEL 62.5MHz, DIVIDER=1250, TICK_CYCLES=1251, immediate digital open-drain rise, valid ACK, no extra stretch, no other client",
        "SCAN_PASS gen=1 valid_entries=82 transactions=105 accepted=105 restored_bank=00",
        "EDGE_CHECK_PASS 105 initial STARTs, 105 STOPs, 94 internal repeated STARTs; all 104 adjacent gaps=3755 cycles=60080 ns",
        "BOUNDARIES group kind prior_seq stop_ns next_seq accept_ns initial_start_ns cycles",
    ]
    for row in rows:
        nxt = commands[int(row["next_command_sequence"])]
        proof_lines.append(
            f"BOUNDARY {row['group_index']} {row['boundary_kind']} "
            f"{row['command_sequence']} {row['stop_time_ns']} "
            f"{nxt.seq} {nxt.accept_ns:.3f} {row['next_start_time_ns']} "
            f"{row['gap_fpga_cycles']}"
        )
    proof_lines.extend([
        "NEGATIVE_SHIFTED_STOP_PLUS_16NS REJECTED_SOURCE_MODEL_GAP_DISAGREEMENT",
        "NEGATIVE_SUBSTITUTED_INTERNAL_REPEATED_START REJECTED_NOT_NEXT_TRANSACTION",
        "W1_PUBLIC_PROOF_PASS",
    ])
    PUBLIC_PROOF.write_text("\n".join(proof_lines) + "\n", encoding="utf-8")
    print(CHECK.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
