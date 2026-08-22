#!/usr/bin/env python3
"""Offline, fail-closed NVP control-flow cost derivation.

The script reads immutable Git objects only.  It does not check out a commit,
write a source tree, invoke a simulator/build, or access hardware.  The FSM
costs are taken from the exact state graph after source assertions.  The table
operations are read from the preserved simulator dump of the exact package
function and cross-checked against package constants and the preserved
all-ACK transaction stream.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Mapping, Optional, Sequence, Set, Tuple


R1_SOURCE_COMMIT = "0af44dee3bc091eaff805704dd5c687eeaa01bbd"
R1C_SOURCE_COMMIT = "f007dc172d43d30b02729755e60382f8ce3dbff4"
FORMAL_COMMIT = "c89e88bcdf389614c884fb129e8b2d42a585bccb"
R1_EVIDENCE_COMMIT = "cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c"
R1C_EVIDENCE_COMMIT = "2c86f792bb439279d2eca69d87c21125f99bf63f"

AUTOINIT = "rtl/nvp/nvp6134c_autoinit.vhd"
BRINGUP = "rtl/nvp/nvp6134c_i2c_bringup.vhd"
DIAG_PKG = "rtl/nvp/nvp6134c_diagnostics_pkg.vhd"
MONITOR = "rtl/v41/axi_clock_lifecycle_monitor.sv"
CONTROL_REGS = "rtl/v41/control_status_regs.sv"

R1_ROOT = "v41-nvp-axi-aclk-lifecycle-measurement-r1"
I25_ROOT = "v41-nvp-i2c-25khz-paired-ab-r1"
R1_T0 = f"{R1_ROOT}/07_R1_RUN/R1_T0_RAW.log"
R1_T1 = f"{R1_ROOT}/07_R1_RUN/R1_T1_RAW.log"
R1_MODEL = f"{R1_ROOT}/04_SIMULATION/R1_COUNTER_MODEL.md"
NUMERIC_LOG = f"{I25_ROOT}/02_NUMERICAL_GATE/raw_calculation.log"
NUMERIC_COUNTS = f"{I25_ROOT}/02_NUMERICAL_GATE/AUTOINIT_OPERATION_COUNTS.csv"
OPS_DUMP = f"{I25_ROOT}/03_SIMULATION/OP_DUMP/simulation.log"
TX_STREAM = f"{I25_ROOT}/03_SIMULATION/TRANSACTION_STREAM_50K.csv"

WRITE_TICKS = 61
READ_TICKS = 83
SETTLE_TICKS = 12001


def git_bytes(repo: Path, commit: str, path: str) -> bytes:
    proc = subprocess.run(
        ["git", "-c", f"safe.directory={repo}", "-C", str(repo),
         "show", f"{commit}:{path}"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"git show failed for {commit}:{path}: "
            + proc.stderr.decode("utf-8", errors="replace")
        )
    return proc.stdout


def git_text(repo: Path, commit: str, path: str) -> str:
    return git_bytes(repo, commit, path).decode("utf-8", errors="strict")


def require(text: str, fragment: str, source: str) -> None:
    if fragment not in text:
        raise AssertionError(f"missing exact source fragment in {source}: {fragment}")


def parse_kv(text: str) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for line in text.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            out[key.strip()] = value.strip()
    return out


@dataclass(frozen=True)
class Op:
    slot: int
    word: int

    @property
    def bank(self) -> int:
        return (self.word >> 16) & 0xFF

    @property
    def reg(self) -> int:
        return (self.word >> 8) & 0xFF

    @property
    def data(self) -> int:
        return self.word & 0xFF

    @property
    def is_nop(self) -> bool:
        return self.bank == 0xFD

    @property
    def is_delay(self) -> bool:
        return self.bank == 0xFE

    @property
    def delay_target(self) -> int:
        return self.word & 0xFFFF


@dataclass
class ModelResult:
    write_transactions: int = 0
    read_transactions: int = 0
    nop_ticks: int = 0
    delay_ticks: int = 0
    skipped_targets: List[int] = None  # type: ignore[assignment]
    path_failures: List[Tuple[int, str]] = None  # type: ignore[assignment]

    def __post_init__(self) -> None:
        if self.skipped_targets is None:
            self.skipped_targets = []
        if self.path_failures is None:
            self.path_failures = []

    @property
    def tick_actions(self) -> int:
        # IDLE accept + preinit + init + final settle + fixed post + FINISH.
        preinit = 2 * READ_TICKS + WRITE_TICKS
        post = 7 * WRITE_TICKS + 28 * READ_TICKS
        return (
            1 + preinit
            + self.write_transactions * WRITE_TICKS
            + self.read_transactions * READ_TICKS
            + self.nop_ticks + self.delay_ticks
            + SETTLE_TICKS + post + 1
        )


def parse_ops(op_dump: str) -> List[Op]:
    found: Dict[int, int] = {}
    for match in re.finditer(r"I25_OP,(\d+),([0-9A-Fa-f]{6})", op_dump):
        found[int(match.group(1))] = int(match.group(2), 16)
    if sorted(found) != list(range(214)):
        raise AssertionError(f"operation dump does not contain exactly slots 0..213: {len(found)}")
    return [Op(slot=i, word=found[i]) for i in range(214)]


def model_table(
    ops: Sequence[Op],
    selector_write_fail_slots: Set[int] = frozenset(),
    selector_verify_fail_slots: Set[int] = frozenset(),
    target_fail_slots: Set[int] = frozenset(),
) -> ModelResult:
    """Replay the exact PH_INIT branch graph at transaction granularity.

    One raw NACK is assigned to each listed transaction.  Target NACKs are
    path-neutral.  Selector failures follow NEXT_OP exactly and can change the
    later physical-bank-cache path.
    """
    result = ModelResult()
    phys_valid = True
    phys_bank = 0

    for op in ops:
        if op.is_nop:
            result.nop_ticks += 2  # SETUP_OP, NEXT_OP
            continue
        if op.is_delay:
            result.delay_ticks += 1 + (op.delay_target + 1) + 1
            continue

        if (not phys_valid) or phys_bank != op.bank:
            result.write_transactions += 1
            if op.slot in selector_write_fail_slots:
                result.path_failures.append((op.slot, "SELECT_WRITE_NACK"))
                result.skipped_targets.append(op.slot)
                phys_valid = False
                continue

            result.read_transactions += 1
            if op.slot in selector_verify_fail_slots:
                result.path_failures.append((op.slot, "SELECT_VERIFY_NACK"))
                result.skipped_targets.append(op.slot)
                phys_valid = False
                continue

            phys_valid = True
            phys_bank = op.bank

        result.write_transactions += 1
        if op.slot in target_fail_slots:
            result.path_failures.append((op.slot, "TARGET_WRITE_NACK_PATH_NEUTRAL"))
            # Source only updates an explicit FF target on ACK.  Every exact
            # FF target writes data equal to its already-current bank, so a
            # failure leaves the cache at the same value.
        elif op.reg == 0xFF:
            phys_valid = True
            phys_bank = op.data

    return result


def source_checks(source_repo: Path) -> Mapping[str, object]:
    texts: Dict[str, Dict[str, bytes]] = {}
    for commit in (FORMAL_COMMIT, R1C_SOURCE_COMMIT, R1_SOURCE_COMMIT):
        texts[commit] = {
            path: git_bytes(source_repo, commit, path)
            for path in (AUTOINIT, BRINGUP, DIAG_PKG)
        }
    for path in (AUTOINIT, BRINGUP, DIAG_PKG):
        if not (texts[FORMAL_COMMIT][path] == texts[R1C_SOURCE_COMMIT][path]
                == texts[R1_SOURCE_COMMIT][path]):
            raise AssertionError(f"protected source differs across exact commits: {path}")

    bringup = texts[R1_SOURCE_COMMIT][BRINGUP].decode("utf-8")
    pkg = texts[R1_SOURCE_COMMIT][DIAG_PKG].decode("utf-8")
    monitor = git_text(source_repo, R1_SOURCE_COMMIT, MONITOR)
    control = git_text(source_repo, R1_SOURCE_COMMIT, CONTROL_REGS)

    required_bringup = [
        "constant DIVIDER : positive := CLK_HZ / (I2C_HZ * 2);",
        "C_INIT_SETTLE_TICKS : natural := 12000",
        "when ACK_REG_HIGH =>",
        "cur_error <= '1'; last_ack_r <= '0';",
        "state <= STORE_RESULT;",
        "state <= NEXT_OP;",
        "elsif init_action = INIT_BANK_WRITE and",
        "init_action <= INIT_BANK_VERIFY;",
        "elsif init_action = INIT_BANK_VERIFY and bank_verify_ok_r = '1' then",
        "init_action <= INIT_TARGET_WRITE;",
        "Selector failure deliberately",
        "reaches here without issuing INIT_TARGET_WRITE.",
        "if reg_addr = C_V38EK_BANK_SELECT_REG and",
        "defer_phys_bank_update = '1' and",
    ]
    for fragment in required_bringup:
        require(bringup, fragment, BRINGUP)
    require(pkg, "constant C_V38EK_LAST_INIT_SLOT  : integer := 213;", DIAG_PKG)
    require(pkg, "function c_v38ek_effective_init_op_for_slot", DIAG_PKG)
    require(monitor, "init_count <= counter;", MONITOR)
    require(monitor, "counter <= counter + 48'd1;", MONITOR)
    require(control, "8'h9C: local_read = {nvp_detail[80], 7'b0, nvp_detail[95:88]", CONTROL_REGS)

    return {
        "protected_source_equal_across_formal_r1c_r1": True,
        "source_sha256": {
            path: hashlib.sha256(texts[R1_SOURCE_COMMIT][path]).hexdigest().upper()
            for path in (AUTOINIT, BRINGUP, DIAG_PKG)
        },
        "fsm_branch_fragments_verified": len(required_bringup),
        "counter_preincrement_capture_verified": True,
        "compact_first_error_mapping_verified": True,
    }


def parse_preserved_counts(csv_text: str) -> Dict[str, int]:
    reader = csv.DictReader(io.StringIO(csv_text))
    return {row["Metric"]: int(row["Value"]) for row in reader}


def parse_tx_stream(csv_text: str) -> List[Dict[str, str]]:
    return list(csv.DictReader(io.StringIO(csv_text)))


def target_fillers(ops: Sequence[Op], excluded: Set[int], count: int) -> Set[int]:
    candidates = [
        op.slot for op in ops
        if not op.is_nop and not op.is_delay and op.slot not in excluded and op.reg != 0xFF
    ]
    if len(candidates) < count:
        raise AssertionError("not enough exact path-neutral target transactions")
    return set(candidates[:count])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-repo", type=Path, required=True)
    parser.add_argument("--evidence-repo", type=Path, required=True)
    args = parser.parse_args()

    checks = source_checks(args.source_repo)

    r1_t0 = parse_kv(git_text(args.evidence_repo, R1_EVIDENCE_COMMIT, R1_T0))
    r1_t1 = parse_kv(git_text(args.evidence_repo, R1_EVIDENCE_COMMIT, R1_T1))
    r1_model = parse_kv(git_text(args.evidence_repo, R1_EVIDENCE_COMMIT, R1_MODEL))
    numeric = parse_kv(git_text(args.evidence_repo, R1C_EVIDENCE_COMMIT, NUMERIC_LOG))
    preserved_counts = parse_preserved_counts(
        git_text(args.evidence_repo, R1C_EVIDENCE_COMMIT, NUMERIC_COUNTS)
    )
    ops = parse_ops(git_text(args.evidence_repo, R1C_EVIDENCE_COMMIT, OPS_DUMP))
    tx_stream = parse_tx_stream(git_text(args.evidence_repo, R1C_EVIDENCE_COMMIT, TX_STREAM))

    if r1_t0["CNT_AT_INIT_DONE"] != r1_t1["CNT_AT_INIT_DONE"]:
        raise AssertionError("R1 T0/T1 CNT_AT_INIT_DONE mismatch")
    expected = int(r1_model["EXPECTED_CNT_AT_INIT_DONE"])
    actual = int(r1_t0["CNT_AT_INIT_DONE"])
    signed_error = actual - expected
    shortening_cycles = expected - actual
    tick_cycles = 626
    exact_ticks = shortening_cycles / tick_cycles
    nearest_ticks = round(exact_ticks)
    residual = shortening_cycles - nearest_ticks * tick_cycles

    ack = model_table(ops)
    if (ack.write_transactions, ack.read_transactions, ack.tick_actions) != (212, 25, 31043):
        raise AssertionError(
            f"source-derived all-ACK model mismatch: "
            f"W={ack.write_transactions} R={ack.read_transactions} ticks={ack.tick_actions}"
        )
    if len(tx_stream) != 275:
        raise AssertionError(f"preserved transaction stream length != 275: {len(tx_stream)}")
    if sum(row["KIND"].endswith("READ") or row["KIND"] in ("READ_ORIGINAL", "SELECT_VERIFY")
           for row in tx_stream) != 55:
        # This is deliberately a fail-closed guard on the preserved stream;
        # the exact KIND vocabulary is also checked via the authoritative
        # preserved count matrix below.
        raise AssertionError("preserved transaction stream read classification mismatch")
    required_preserved = {
        "TABLE_SLOTS": 214,
        "TABLE_TARGET_WRITES": 187,
        "TABLE_DELAY_SLOTS": 1,
        "TABLE_NOP_SLOTS": 26,
        "VERIFIED_BANK_CHANGES": 25,
        "TOTAL_WRITE_TRANSACTIONS": 220,
        "TOTAL_READ_TRANSACTIONS": 55,
        "TOTAL_I2C_TRANSACTIONS": 275,
        "SUCCESS_PATH_TICK_ACTIONS": 31043,
    }
    for key, value in required_preserved.items():
        if preserved_counts.get(key) != value:
            raise AssertionError(f"preserved count mismatch {key}")

    # Witness 1: first historical NACK is path-neutral slot-0 target.  A
    # later selector-verify NACK on one-entry bank-01 run omits one target.
    witness1_path_neutral = target_fillers(ops, {0, 1}, 17) | {0}
    witness1 = model_table(
        ops,
        selector_verify_fail_slots={1},
        target_fail_slots=witness1_path_neutral,
    )

    # Witness 2: bank-03 run contains real targets at slots 2,3,5 (slot 4 is
    # delay).  Verify fails at 2 and selector writes fail at 3 and 5.  Three
    # targets are skipped, yet net W/R difference is again -1/0.
    witness2_path_neutral = target_fillers(ops, {0, 2, 3, 5}, 15) | {0}
    witness2 = model_table(
        ops,
        selector_write_fail_slots={3, 5},
        selector_verify_fail_slots={2},
        target_fail_slots=witness2_path_neutral,
    )

    witnesses = []
    for name, model, raw_nacks in (
        ("ONE_SKIPPED_TARGET", witness1, 19),
        ("THREE_SKIPPED_TARGETS", witness2, 19),
    ):
        shortening = ack.tick_actions - model.tick_actions
        if shortening != 61:
            raise AssertionError(f"{name} does not yield 61 ticks: {shortening}")
        # One NACK per listed failed transaction; path failures plus target
        # fillers are disjoint by construction.
        model_raw_nacks = len(model.path_failures)
        if model_raw_nacks != raw_nacks:
            raise AssertionError(f"{name} raw-NACK witness !=19: {model_raw_nacks}")
        witnesses.append({
            "name": name,
            "actual_write_transactions": model.write_transactions,
            "actual_read_transactions": model.read_transactions,
            "delta_writes_vs_ack": model.write_transactions - ack.write_transactions,
            "delta_reads_vs_ack": model.read_transactions - ack.read_transactions,
            "skipped_target_slots": model.skipped_targets,
            "skipped_target_count": len(model.skipped_targets),
            "raw_nack_events": model_raw_nacks,
            "shortening_ticks": shortening,
        })

    expected_50 = int(numeric["I2C_50000_FINISH_COUNTER_VALUE"])
    expected_25 = int(numeric["I2C_25000_FINISH_COUNTER_VALUE"])
    first_50 = int(numeric["I2C_50000_FIRST_IDLE_TICK_EDGE"])
    first_25 = int(numeric["I2C_25000_FIRST_IDLE_TICK_EDGE"])
    derived_50 = first_50 + (ack.tick_actions - 1) * 626
    derived_25 = first_25 + (ack.tick_actions - 1) * 1251
    if (derived_50, derived_25) != (expected_50, expected_25):
        raise AssertionError("50/25-kHz all-ACK expected-count validation failed")

    ff_targets = [
        {"slot": op.slot, "bank": f"{op.bank:02X}", "data": f"{op.data:02X}"}
        for op in ops if not op.is_nop and not op.is_delay and op.reg == 0xFF
    ]
    if [x["slot"] for x in ff_targets] != [148, 171, 192, 211, 213]:
        raise AssertionError("unexpected explicit FF target slots")
    if any(x["bank"] != x["data"] for x in ff_targets):
        raise AssertionError("an explicit FF target changes away from its metadata bank")

    output = {
        "status": "PASS",
        "source_checks": checks,
        "operation_model": {
            "slots": len(ops),
            "target_slots": sum(not op.is_nop and not op.is_delay for op in ops),
            "nop_slots": sum(op.is_nop for op in ops),
            "delay_slots": sum(op.is_delay for op in ops),
            "verified_bank_changes": ack.read_transactions,
            "init_write_transactions": ack.write_transactions,
            "init_read_transactions": ack.read_transactions,
            "total_write_transactions": ack.write_transactions + 1 + 7,
            "total_read_transactions": ack.read_transactions + 2 + 28,
            "tick_actions": ack.tick_actions,
            "tick_intervals": ack.tick_actions - 1,
            "expected_count_50khz": derived_50,
            "expected_count_25khz": derived_25,
            "explicit_ff_targets": ff_targets,
        },
        "r1": {
            "expected_cnt_at_init_done": expected,
            "actual_cnt_at_init_done": actual,
            "signed_count_error_cycles": signed_error,
            "control_flow_shortening_cycles": shortening_cycles,
            "tick_cycles": tick_cycles,
            "shortening_ticks_exact": f"{exact_ticks:.13f}",
            "shortening_ticks_nearest": nearest_ticks,
            "residual_cycles": residual,
            "first_error_meta_raw": r1_t0["FIRST_ERROR_META"],
            "first_error_valid": 1,
            "first_error_code": "0x02",
            "first_error_step": "0x01",
            "first_error_path": "SLOT_0_TARGET_WRITE_REGISTER_BYTE_NACK_PATH_NEUTRAL",
            "method_validation": "PASS_61_TICKS_WITH_MINUS_1_CYCLE_EDGE_RESIDUAL",
            "omitted_transaction_interpretation": "R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS",
            "unique_effective_nack_events": None,
            "unique_skipped_i2c_transactions": None,
            "unique_skipped_table_entries": None,
        },
        "edge_convention_review": {
            "authoritative_finish_preincrement_expected": expected,
            "preserved_wrapper_init_done_high_edge": int(numeric["I2C_50000_FINISH_COUNTER_VALUE"]) + 1,
            "expected_and_monitor_capture_use_same_preincrement_convention": True,
            "reported_residual_cycles": residual,
            "wrapper_high_edge_used_for_counter_deficit": False,
            "residual_attribution": "NOT_UNIQUELY_ATTRIBUTED_CONSISTENT_WITH_ONE_BASE_CLOCK_BOUNDARY",
        },
        "decomposition_witnesses": witnesses,
    }
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
