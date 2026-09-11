#!/usr/bin/env python3
"""Canonical source-derived R3 NVP I2C replay.

The output is a physical transaction trace: bank-select writes and their
verification reads are expanded exactly as the bring-up sequencer performs
them.  Runtime diagnostic operations are then appended in their frozen 4x4
order.  No hardware is contacted.
"""

from __future__ import annotations

import copy
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from transaction_parser import load_r3_logical_table


TRACE_FIELDS = [
    "GlobalSequenceNumber",
    "ConfigurationLayer",
    "SourceFile",
    "SourceLine",
    "SourceSymbol",
    "Channel",
    "LogicalChannelIndex",
    "ExpectedPrivateBank",
    "SelectedBankBefore",
    "BankSelectWrite",
    "RegisterAddress",
    "Operation",
    "WriteData",
    "WriteMask",
    "ReadModifyWrite",
    "KnownInitialBits",
    "SymbolicUnknownBits",
    "ComputedFinalValue",
    "DelayBefore",
    "DelayAfter",
    "Condition",
    "Reason",
    "AuthorityReference",
]


CHANNEL_ORDERS = [
    [1, 2, 3, 4],
    [4, 3, 2, 1],
    [2, 3, 4, 1],
    [3, 4, 1, 2],
]

ROUND_BG = [
    (0x46, 0x13),  # CH1 red, CH2 green, CH3 cyan, CH4 white75
    (0x61, 0x34),
    (0x13, 0x46),
    (0x34, 0x61),
]

VERIFY_REGS = [
    0x80, 0x00, 0x01, 0x02, 0x03, 0x08, 0x09, 0x0A, 0x0B,
    0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88,
]


@dataclass
class SymbolicByte:
    name: str

    def __str__(self) -> str:
        return self.name


class Replay:
    def __init__(self) -> None:
        self.trace: list[dict[str, Any]] = []
        self.bank: int | SymbolicByte | None = None
        self.state: dict[tuple[int, int], int | SymbolicByte] = {}
        self.override_count = 0
        self.use_before_bank_select = 0
        self.invalid_bank_or_address = 0
        self.unresolved_source_operations = 0

    @staticmethod
    def _fmt(value: Any) -> str:
        if value is None:
            return "UNSELECTED"
        if isinstance(value, int):
            return f"0x{value:02X}"
        return str(value)

    def add(
        self,
        *,
        layer: str,
        source_file: str,
        source_line: int | str,
        source_symbol: str,
        operation: str,
        address: int,
        data: int | SymbolicByte | None = None,
        channel: int | None = None,
        selected_bank: int | SymbolicByte | None = None,
        bank_select_write: bool = False,
        read_modify_write: bool = False,
        write_mask: str = "0xFF",
        known_initial_bits: str = "N/A",
        symbolic_unknown_bits: str = "NONE",
        computed_final: str | None = None,
        delay_before: str = "0",
        delay_after: str = "0",
        condition: str = "ALWAYS",
        reason: str = "",
        authority: str = "",
    ) -> dict[str, Any]:
        before = self.bank if selected_bank is None else selected_bank
        expected_bank = 4 + channel if channel else "N/A"
        row = {
            "GlobalSequenceNumber": len(self.trace) + 1,
            "ConfigurationLayer": layer,
            "SourceFile": source_file,
            "SourceLine": source_line,
            "SourceSymbol": source_symbol,
            "Channel": f"CH{channel}" if channel else "GLOBAL",
            "LogicalChannelIndex": channel - 1 if channel else "N/A",
            "ExpectedPrivateBank": f"0x{expected_bank:02X}" if channel else "N/A",
            "SelectedBankBefore": self._fmt(before),
            "BankSelectWrite": "YES" if bank_select_write else "NO",
            "RegisterAddress": f"0x{address:02X}",
            "Operation": operation,
            "WriteData": self._fmt(data) if data is not None else "N/A",
            "WriteMask": write_mask if operation == "WRITE" else "N/A",
            "ReadModifyWrite": "YES" if read_modify_write else "NO",
            "KnownInitialBits": known_initial_bits,
            "SymbolicUnknownBits": symbolic_unknown_bits,
            "ComputedFinalValue": computed_final
            if computed_final is not None
            else (self._fmt(data) if operation == "WRITE" else "READBACK"),
            "DelayBefore": delay_before,
            "DelayAfter": delay_after,
            "Condition": condition,
            "Reason": reason,
            "AuthorityReference": authority,
        }
        self.trace.append(row)

        if operation == "WRITE":
            if address == 0xFF:
                self.bank = data
            else:
                if self.bank is None:
                    self.use_before_bank_select += 1
                if isinstance(self.bank, int) and isinstance(data, (int, SymbolicByte)):
                    key = (self.bank, address)
                    if key in self.state:
                        self.override_count += 1
                    self.state[key] = data
        return row

    def direct_write(
        self,
        *,
        bank: int,
        address: int,
        data: int,
        layer: str,
        source_line: int,
        symbol: str,
        delay_before: str = "0",
    ) -> None:
        if self.bank != bank:
            self.add(
                layer=layer,
                source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd",
                source_line=1035,
                source_symbol="INIT_BANK_WRITE",
                operation="WRITE",
                address=0xFF,
                data=bank,
                bank_select_write=True,
                reason=f"select physical bank 0x{bank:02X} for logical table target",
                authority="nvp6134c_i2c_bringup.vhd:1028-1069",
            )
            self.add(
                layer=layer,
                source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd",
                source_line=1056,
                source_symbol="INIT_BANK_VERIFY",
                operation="READ",
                address=0xFF,
                reason=f"verify physical bank 0x{bank:02X}",
                authority="nvp6134c_i2c_bringup.vhd:1056-1062",
            )
        self.add(
            layer=layer,
            source_file="rtl/nvp/nvp6134c_diagnostics_pkg.vhd",
            source_line=source_line,
            source_symbol=symbol,
            operation="WRITE",
            address=address,
            data=data,
            bank_select_write=address == 0xFF,
            delay_before=delay_before,
            reason="effective table target write",
            authority=f"nvp6134c_diagnostics_pkg.vhd:{source_line}; bringup:997-1070",
        )


def _runtime_op(
    replay: Replay,
    layer: str,
    line: int,
    symbol: str,
    operation: str,
    address: int,
    data: int | SymbolicByte | None = None,
    channel: int | None = None,
    rmw: bool = False,
    mask: str = "0xFF",
    symbolic: str = "NONE",
    computed: str | None = None,
    reason: str = "",
) -> None:
    replay.add(
        layer=layer,
        source_file="rtl/g2b/g2b_nvp_video_diag.sv",
        source_line=line,
        source_symbol=symbol,
        operation=operation,
        address=address,
        data=data,
        channel=channel,
        bank_select_write=address == 0xFF and operation == "WRITE",
        read_modify_write=rmw,
        write_mask=mask,
        known_initial_bits="upper nibble retained from preceding C2 read" if rmw else "N/A",
        symbolic_unknown_bits=symbolic,
        computed_final=computed,
        reason=reason,
        authority=f"g2b_nvp_video_diag.sv:{line}",
    )


def add_prepare(replay: Replay, label: str) -> None:
    layer = "L4_DIAGNOSTIC_PREPARE"
    sym = f"PREPARE_{label}"
    original = SymbolicByte("ORIGINAL_ENTRY_BANK")
    for line, op, addr, data, reason in [
        (600, "READ", 0xFF, None, "save original bank"),
        (601, "WRITE", 0xFF, 0x00, "select Bank0"),
        (602, "READ", 0x78, None, "save BGDCOL CH1/CH2"),
        (603, "READ", 0x79, None, "save BGDCOL CH3/CH4"),
        (604, "WRITE", 0xFF, 0x01, "select Bank1"),
        (605, "READ", 0xC2, None, "save full VDO1 route byte"),
        (606, "WRITE", 0xFF, original, "restore original bank"),
    ]:
        _runtime_op(replay, layer, line, sym, op, addr, data, reason=reason)
    _runtime_op(replay, layer, 646, sym, "WRITE", 0xFF, 0x00, reason="verification Bank0")
    for reg in VERIFY_REGS:
        _runtime_op(
            replay,
            layer,
            648,
            sym,
            "READ",
            reg,
            reason="verify all-channel public configuration",
        )
    _runtime_op(replay, layer, 650, sym, "WRITE", 0xFF, original, reason="release at original bank")


def add_round(replay: Replay, round_index: int) -> None:
    bg78, bg79 = ROUND_BG[round_index]
    layer = "L5_ROUND_BGDCOL"
    symbol = f"ROUND_{round_index + 1}_BGDCOL"
    for line, op, addr, data, reason in [
        (696, "WRITE", 0xFF, 0x00, "select Bank0"),
        (697, "WRITE", 0x78, bg78, "write Latin-square colors CH1/CH2"),
        (699, "WRITE", 0x79, bg79, "write Latin-square colors CH3/CH4"),
        (722, "READ", 0x78, None, "verify BGDCOL 0x78"),
        (724, "READ", 0x79, None, "verify BGDCOL 0x79"),
    ]:
        _runtime_op(replay, layer, line, symbol, op, addr, data, reason=reason)


def add_session(replay: Replay, session: int, channel: int) -> None:
    layer = "L6_SESSION_ROUTE_STATUS"
    symbol = f"SESSION_{session}_CH{channel}"
    _runtime_op(replay, layer, 756, symbol, "WRITE", 0xFF, 0x01, channel, reason="select Bank1")
    _runtime_op(replay, layer, 757, symbol, "READ", 0xC2, None, channel, reason="read route before RMW")
    _runtime_op(
        replay,
        layer,
        758,
        symbol,
        "WRITE",
        0xC2,
        channel - 1,
        channel,
        rmw=True,
        mask="0x0F",
        symbolic="C2[7:4] source-preserved; runtime ledger resolves to 0x0",
        computed=f"(C2_PRE[7:4]<<4)|0x{channel - 1:X}; observed 0x{channel - 1:02X}",
        reason="select channel while preserving unrelated upper nibble",
    )
    _runtime_op(replay, layer, 785, symbol, "READ", 0xC2, None, channel, reason="route readback")
    _runtime_op(replay, layer, 787, symbol, "WRITE", 0xFF, 0x00, channel, reason="return to Bank0")
    status_reg = 0xE7 + channel
    for sample in range(1, 6):
        for line, address, reason in [
            (846, 0xA8, "NOVID"),
            (847, 0xE0, "AGC lock"),
            (848, 0xE1, "comparator/clamp lock"),
            (849, 0xE2, "H lock"),
            (850, status_reg, f"CH{channel} status"),
        ]:
            _runtime_op(
                replay,
                layer,
                line,
                symbol,
                "READ",
                address,
                None,
                channel,
                reason=f"stable sample {sample}/5: {reason}",
            )


def add_restore(replay: Replay) -> None:
    layer = "L7_PRODUCT_BASELINE_RESTORE"
    symbol = "RESTORE_AND_VERIFY_PRODUCT_BASELINE"
    original = SymbolicByte("ORIGINAL_ENTRY_BANK")
    ops = [
        (1029, "WRITE", 0xFF, 0x00, "select Bank0"),
        (1030, "WRITE", 0x78, 0x88, "restore PREPARE_B BG78"),
        (1031, "WRITE", 0x79, 0x88, "restore PREPARE_B BG79"),
        (1032, "WRITE", 0xFF, 0x01, "select Bank1"),
        (1033, "WRITE", 0xC2, 0x00, "restore PREPARE_B full route"),
        (1034, "WRITE", 0xFF, original, "restore firmware-private bank"),
        (1059, "WRITE", 0xFF, 0x00, "verify: select Bank0"),
        (1060, "READ", 0x78, None, "verify restored BG78"),
        (1061, "READ", 0x79, None, "verify restored BG79"),
        (1062, "WRITE", 0xFF, 0x01, "verify: select Bank1"),
        (1063, "READ", 0xC2, None, "verify full route"),
        (1064, "WRITE", 0xFF, original, "verify: restore original bank"),
        (1065, "READ", 0xFF, None, "firmware-private physical bank readback"),
    ]
    for line, op, addr, data, reason in ops:
        _runtime_op(replay, layer, line, symbol, op, addr, data, reason=reason)


def build_trace(package_path: Path) -> Replay:
    replay = Replay()
    original = SymbolicByte("AUTOINIT_ENTRY_BANK")
    # Physical pre-initialization sequence.
    replay.add(
        layer="L1_PRODUCT_AUTOINIT_FIXED",
        source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd",
        source_line=974,
        source_symbol="PREINIT_READ_ORIGINAL",
        operation="READ",
        address=0xFF,
        symbolic_unknown_bits="AUTOINIT_ENTRY_BANK",
        reason="capture entry bank before fixed autoinit",
        authority="nvp6134c_i2c_bringup.vhd:972-995",
    )
    replay.add(
        layer="L1_PRODUCT_AUTOINIT_FIXED",
        source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd",
        source_line=979,
        source_symbol="PREINIT_FORCE_BANK0_WRITE",
        operation="WRITE",
        address=0xFF,
        data=0x00,
        bank_select_write=True,
        reason="force known physical Bank0",
        authority="nvp6134c_i2c_bringup.vhd:979-986",
    )
    replay.add(
        layer="L1_PRODUCT_AUTOINIT_FIXED",
        source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd",
        source_line=988,
        source_symbol="PREINIT_FORCE_BANK0_VERIFY",
        operation="READ",
        address=0xFF,
        reason="verify Bank0",
        authority="nvp6134c_i2c_bringup.vhd:988-995",
    )

    pending_delay = "0"
    for op in load_r3_logical_table(package_path):
        if op["operation"] == "DELAY":
            pending_delay = "10 ms (table word FE03E8)"
            continue
        if op["slot"] <= 26:
            layer = "L1_PRODUCT_AUTOINIT_FIXED"
        elif op["slot"] < 148:
            layer = "L2_V38_R1I_STAGE2_OVERLAY"
        else:
            layer = "L3_ALL_CHANNEL_PUBLIC_OVERLAY"
        replay.direct_write(
            bank=op["bank"],
            address=op["address"],
            data=op["data"],
            layer=layer,
            source_line=op["source_line"],
            symbol=op["source_symbol"],
            delay_before=pending_delay,
        )
        pending_delay = "0"

    # Fixed post-init readback and original-bank restore: 35 transactions.
    replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1072, source_symbol="PH_WIN_BANK", operation="WRITE", address=0xFF, data=0x00, bank_select_write=True, reason="post-init Bank0 window", authority="bringup:1072-1106")
    for reg in [0x08, 0x09, 0x0A, 0x0B, 0x81, 0x82, 0x83, 0x84, 0xA8, 0xE0, 0xE8, 0xE9, 0xEA, 0xEB, 0x54, 0x55]:
        replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1079, source_symbol="PH_WIN_READ", operation="READ", address=reg, reason="post-init Bank0 status window", authority="diagnostics_pkg:514-535; bringup:1079-1082")
    replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1084, source_symbol="PH_OUT_BANK", operation="WRITE", address=0xFF, data=0x01, bank_select_write=True, reason="post-init Bank1 output window", authority="bringup:1084-1094")
    for reg in [0xC2, 0xC3, 0xC4, 0xC5, 0xC8, 0xC9, 0xCA, 0xCD]:
        replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1091, source_symbol="PH_OUT_READ", operation="READ", address=reg, reason="post-init output readback", authority="diagnostics_pkg:538-549; bringup:1091-1094")
    for idx, bank in enumerate([5, 6, 7, 8]):
        replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1096, source_symbol="PH_AFE_BANK", operation="WRITE", address=0xFF, data=bank, channel=idx + 1, bank_select_write=True, reason=f"select CH{idx + 1} classifier bank", authority="diagnostics_pkg:552-563; bringup:1096-1106")
        replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1103, source_symbol="PH_AFE_READ", operation="READ", address=0xF0, channel=idx + 1, reason=f"read CH{idx + 1} format classifier", authority="NVP PDF p88; bringup:1103-1106")
    replay.add(layer="L3_ALL_CHANNEL_PUBLIC_OVERLAY", source_file="rtl/nvp/nvp6134c_i2c_bringup.vhd", source_line=1108, source_symbol="PH_RESTORE", operation="WRITE", address=0xFF, data=original, bank_select_write=True, symbolic_unknown_bits="AUTOINIT_ENTRY_BANK", reason="restore autoinit entry bank", authority="bringup:1108-1116")

    add_prepare(replay, "A")
    add_prepare(replay, "B")
    session = 0
    for round_index, channels in enumerate(CHANNEL_ORDERS):
        add_round(replay, round_index)
        for channel in channels:
            session += 1
            add_session(replay, session, channel)
    add_restore(replay)
    return replay


def deterministic_signature(trace: Iterable[dict[str, Any]]) -> tuple[tuple[Any, ...], ...]:
    return tuple(tuple(row[field] for field in TRACE_FIELDS) for row in trace)


def clone_replay(replay: Replay) -> Replay:
    return copy.deepcopy(replay)


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    args = parser.parse_args()
    model = build_trace(args.package)
    print(json.dumps({"transactions": len(model.trace), "overrides": model.override_count}, indent=2))
