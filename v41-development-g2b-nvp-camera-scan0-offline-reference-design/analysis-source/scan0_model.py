#!/usr/bin/env python3
"""Deterministic, offline-only evidence model for G2B-NVP-CAMERA-SCAN0.

This module reads only the pinned task-local reference checkout, the exact
current-v41 diagnostic checkout, and the Owner inputs.  It performs no device,
driver, PCIe, MMIO, JTAG, Vivado, or network access.
"""

from __future__ import annotations

import ast
import csv
import hashlib
import json
import operator
import re
import subprocess
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Iterable


REFERENCE_COMMIT = "081ebbff9a2722d47acf16c680594be43cb179e2"
CURRENT_COMMIT = "fc37d815b5d64ef90dfbd99c57ae4cc09567b56f"
CURRENT_TREE = "cdff3ea9d786141ff9bfd46f7099198324604663"
DRIVER_VERSION = "17.03.20.01"
I2C_HZ = 25_000
READ_SCL_PERIODS = 36
WRITE_SCL_PERIODS = 27

REFERENCE_FILES = [
    "nvp6134_drv.c",
    "video.c",
    "video.h",
    "eq.c",
    "eq.h",
    "eq_common.c",
    "eq_common.h",
    "eq_recovery.c",
    "eq_recovery.h",
    "common.h",
    "Makefile",
    "docs/nvp6134_datasheet_release_v03_161025.pdf",
    "acp.c",
    "acp.h",
]

REFERENCE_RELEVANCE = {
    "nvp6134_drv.c": "driver version, ioctl entry points, output routing integration",
    "video.c": "getvideoloss, video_fmt_det, debounce, reset, set_chnmode, output routing",
    "video.h": "mode enums, detector/output data structures and prototypes",
    "eq.c": "initial EQ and runtime EQ entry points",
    "eq.h": "EQ state and entry-point declarations",
    "eq_common.c": "format-discrimination metrics and adaptive EQ primitives",
    "eq_common.h": "EQ/discrimination declarations",
    "eq_recovery.c": "loss/mode recovery semantics",
    "eq_recovery.h": "recovery declarations",
    "common.h": "PAL/NTSC constants and shared types",
    "Makefile": "reference build composition only; never executed",
    "docs/nvp6134_datasheet_release_v03_161025.pdf": "secondary NVP6134 register authority; not published",
    "acp.c": "ACP setup called by set_chnmode",
    "acp.h": "ACP register constants",
}

CURRENT_FILES = [
    "rtl/nvp/nvp6134c_autoinit.vhd",
    "rtl/nvp/nvp6134c_i2c_bringup.vhd",
    "rtl/nvp/nvp6134c_diagnostics_pkg.vhd",
    "rtl/v41/nvp_i2c_fixed_master.sv",
    "rtl/g2b/g2b_nvp_video_diag.sv",
    "rtl/top/ahd_capture_top_xdma.sv",
    "rtl/g2b/v41_g2b_mmio_router.sv",
    "rtl/v41/control_status_regs.sv",
    "rtl/pio/pio_bar_target.sv",
]

CURRENT_RELEVANCE = {
    "rtl/nvp/nvp6134c_autoinit.vhd": "one-shot autoinit wrapper and fixed profile controls",
    "rtl/nvp/nvp6134c_i2c_bringup.vhd": "NVP reset, power sequencing and table executor",
    "rtl/nvp/nvp6134c_diagnostics_pkg.vhd": "existing static initialization operation tables",
    "rtl/v41/nvp_i2c_fixed_master.sv": "25-kHz register transaction engine and phase errors",
    "rtl/g2b/g2b_nvp_video_diag.sv": "current DIAG1 status reads, writes, restore and MMIO",
    "rtl/top/ahd_capture_top_xdma.sv": "clock, compile-time isolation and open-drain ownership",
    "rtl/g2b/v41_g2b_mmio_router.sv": "frozen G2B versus legacy address routing",
    "rtl/v41/control_status_regs.sv": "legacy/local/application MMIO decode",
    "rtl/pio/pio_bar_target.sv": "application BAR response behavior and unallocated range proof",
}


def sha256_path(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def git(repo: Path, *args: str) -> str:
    cp = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return cp.stdout.strip()


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")


def write_csv(path: Path, rows: Iterable[dict[str, Any]], fields: list[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, lineterminator="\n", extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def reference_manifest(ref_repo: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for rel in REFERENCE_FILES:
        path = ref_repo / rel
        if not path.is_file():
            raise AssertionError(f"missing reference file: {rel}")
        prefix = path.read_bytes()[:4096].decode("latin-1", errors="ignore").lower()
        copyright_present = "copyright" in prefix or rel.lower().endswith(".pdf")
        rows.append(
            {
                "Path": rel,
                "Size": path.stat().st_size,
                "SHA256": sha256_path(path),
                "GitBlobSHA": git(ref_repo, "rev-parse", f"{REFERENCE_COMMIT}:{rel}"),
                "LastModifyingCommit": git(ref_repo, "log", "-1", "--format=%H", REFERENCE_COMMIT, "--", rel),
                "FunctionSymbolRelevance": REFERENCE_RELEVANCE[rel],
                "CopyrightHeaderPresent": "YES" if copyright_present else "NO_EXPLICIT_HEADER_IN_FIRST_4K",
                "LicenseStatus": "NO_DECLARED_REPOSITORY_LICENSE_SEMANTIC_USE_ONLY",
            }
        )
    return rows


def current_inventory(current_repo: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for rel in CURRENT_FILES:
        path = current_repo / rel
        if not path.is_file():
            raise AssertionError(f"missing current-v41 source: {rel}")
        rows.append(
            {
                "Path": rel,
                "Size": path.stat().st_size,
                "SHA256": sha256_path(path),
                "GitBlobSHA": git(current_repo, "rev-parse", f"{CURRENT_COMMIT}:{rel}"),
                "Relevance": CURRENT_RELEVANCE[rel],
                "InspectionDisposition": "INSPECTED_READ_ONLY",
            }
        )
    return rows


def split_args(text: str) -> list[str]:
    out: list[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(text):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            out.append(text[start:i].strip())
            start = i + 1
    out.append(text[start:].strip())
    return out


OPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.FloorDiv: operator.floordiv,
    ast.Div: operator.floordiv,
    ast.Mod: operator.mod,
    ast.LShift: operator.lshift,
    ast.RShift: operator.rshift,
    ast.BitOr: operator.or_,
    ast.BitAnd: operator.and_,
    ast.BitXor: operator.xor,
    ast.Invert: operator.invert,
    ast.USub: operator.neg,
}


def _safe_eval_node(node: ast.AST) -> int:
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, bool)):
        return int(node.value)
    if isinstance(node, ast.UnaryOp) and type(node.op) in OPS:
        return OPS[type(node.op)](_safe_eval_node(node.operand))
    if isinstance(node, ast.BinOp) and type(node.op) in OPS:
        return OPS[type(node.op)](_safe_eval_node(node.left), _safe_eval_node(node.right))
    if isinstance(node, ast.Compare) and len(node.ops) == 1 and len(node.comparators) == 1:
        lhs = _safe_eval_node(node.left)
        rhs = _safe_eval_node(node.comparators[0])
        op = node.ops[0]
        if isinstance(op, ast.Eq): return int(lhs == rhs)
        if isinstance(op, ast.NotEq): return int(lhs != rhs)
        if isinstance(op, ast.Lt): return int(lhs < rhs)
        if isinstance(op, ast.LtE): return int(lhs <= rhs)
        if isinstance(op, ast.Gt): return int(lhs > rhs)
        if isinstance(op, ast.GtE): return int(lhs >= rhs)
    raise ValueError(f"unsupported expression node: {ast.dump(node)}")


MACROS = {
    "ACP_CLR_REG": "0x3A",
    "ACP_AHD2_FHD_BAUD": "0x00",
    "ACP_AHD2_FHD_LINE": "0x03",
    "ACP_AHD2_FHD_LINES": "0x05",
    "ACP_AHD2_FHD_BYTE": "0x0A",
    "ACP_AHD2_FHD_MODE": "0x0B",
    "ACP_AHD2_PEL_EVEN": "0x2F",
}


def _resolve_ternary(expr: str, ch: int) -> str:
    expr = expr.strip()
    # Every selected ternary is a simple C condition with scalar arms.
    q = expr.find("?")
    if q < 0:
        return expr
    cond = expr[:q].strip()
    # Remove one balanced outer pair around the condition.
    while cond.startswith("(") and cond.endswith(")"):
        cond = cond[1:-1].strip()
    rest = expr[q + 1 :]
    depth = 0
    colon = -1
    for i, char in enumerate(rest):
        if char == "(": depth += 1
        elif char == ")": depth -= 1
        elif char == ":" and depth == 0:
            colon = i
            break
    if colon < 0:
        raise ValueError(f"malformed ternary: {expr}")
    yes, no = rest[:colon].strip(), rest[colon + 1 :].strip()
    return yes if eval_c_expr(cond, ch) else no


def eval_c_expr(expr: str, ch: int) -> int:
    text = expr.strip()
    for name, value in MACROS.items():
        text = re.sub(rf"\b{re.escape(name)}\b", value, text)
    text = text.replace("ch_vfmt_status[ch]", "1").replace("vfmt", "1").replace("PAL", "1")
    text = re.sub(r"\bch\b", str(ch), text)
    text = _resolve_ternary(text, ch)
    text = text.strip()
    if not re.fullmatch(r"[0-9a-fA-FxX()\s+\-*/%<>=&|^~]+", text):
        raise ValueError(f"unresolved C expression: {expr!r} -> {text!r}")
    return _safe_eval_node(ast.parse(text, mode="eval").body) & 0xFFFFFFFF


@dataclass
class ActionOp:
    order: int
    phase: str
    operation: str
    bank_expression: str
    register_expression: str
    value_mask_expression: str
    delay_ms: int
    ch1_bank: str
    ch1_register: str
    ch1_value: str
    ch3_bank: str
    ch3_register: str
    ch3_value: str
    source_file: str
    source_function: str
    source_line: int
    authority_class: str
    nvp6134c_compatibility: str
    note: str


def _hex8(value: int) -> str:
    return f"0x{value & 0xFF:02X}"


def _selected_source_lines(ref_repo: Path) -> list[tuple[str, str, str, list[int]]]:
    return [
        ("COMMON", "video.c", "nvp6134_set_common_value", list(range(2070, 2134))),
        ("FHD_COMMON", "video.c", "nvp6134_setchn_common_fhd", list(range(3392, 3464))),
        ("AHD1080P25", "video.c", "nvp6134_setchn_ahd_1080p2530", list(range(3472, 3533))),
        ("ACP_COMMON", "acp.c", "acp_each_setting", list(range(452, 463))),
        ("ACP_BAUD", "acp.c", "acp_set_baudrate", list(range(233, 244))),
        ("ACP_RX", "acp.c", "acp_each_setting", [468, 470, 472, 481, 491, 492, 537, 538, 539]),
        ("ACP_RX_CLEAR", "acp.c", "acp_reg_rx_clear", list(range(121, 126))),
        ("EQ_INIT", "eq.c", "eq_init_each_format", [81, 82, 132, 133, 134, 135, 137, 138]),
        ("POST_MODE", "video.c", "nvp6134_set_chnmode", [1171, 1172, 1173, 1177, 1180, 1181]),
    ]


def _datasheet_proven(bank: int, reg: int, value: int | None) -> bool:
    if reg == 0xFF:
        return True
    # NVP6134C Rev1.0 guide-note values for AHD 1080p25 and FSC.
    proven = {
        (0x00, 0x81, 0x03), (0x00, 0x83, 0x03),
        (0x00, 0x85, 0x00), (0x00, 0x87, 0x00),
        (0x01, 0x84, 0x00), (0x01, 0x86, 0x00),
        (0x01, 0x8C, 0x40), (0x01, 0x8E, 0x40),
        (0x09, 0x50, 0xAB), (0x09, 0x51, 0x7D),
        (0x09, 0x52, 0xC3), (0x09, 0x53, 0x52),
        (0x09, 0x58, 0xAB), (0x09, 0x59, 0x7D),
        (0x09, 0x5A, 0xC3), (0x09, 0x5B, 0x52),
    }
    return value is not None and (bank, reg, value) in proven


def action_manifest(ref_repo: Path) -> list[ActionOp]:
    operations: list[ActionOp] = []
    bank_expr = "UNKNOWN_ENTRY_BANK"
    order = 0

    def add(
        phase: str,
        operation: str,
        reg_expr: str,
        val_expr: str,
        delay: int,
        file: str,
        func: str,
        line: int,
        note: str = "",
    ) -> None:
        nonlocal order, bank_expr
        order += 1
        chvals: dict[int, tuple[str, str, str]] = {}
        for channel in (0, 2):
            try:
                b = eval_c_expr(bank_expr, channel)
                btxt = _hex8(b)
            except ValueError:
                b, btxt = None, bank_expr
            try:
                r = eval_c_expr(reg_expr, channel)
                rtxt = _hex8(r)
            except ValueError:
                r, rtxt = None, reg_expr
            try:
                v = eval_c_expr(val_expr, channel) if val_expr else None
                vtxt = _hex8(v) if v is not None else "N/A"
            except ValueError:
                v, vtxt = None, val_expr
            chvals[channel] = (btxt, rtxt, vtxt)
        try:
            b0 = eval_c_expr(bank_expr, 0) if bank_expr != "UNKNOWN_ENTRY_BANK" else -1
        except ValueError:
            b0 = -1
        try:
            r0 = eval_c_expr(reg_expr, 0) if reg_expr else -1
        except ValueError:
            r0 = -1
        try:
            v0 = eval_c_expr(val_expr, 0) if val_expr else None
        except ValueError:
            v0 = None
        authority = "NVP6134C_DATASHEET" if b0 >= 0 and _datasheet_proven(b0, r0, v0) else "REFERENCE_DRIVER_SEMANTICS"
        compatibility = "PROVEN_REGISTER_VALUE" if authority == "NVP6134C_DATASHEET" else "CONTROLLED_NVP6134C_COMPATIBILITY_TEST_REQUIRED"
        operations.append(
            ActionOp(
                order, phase, operation, bank_expr, reg_expr, val_expr, delay,
                *chvals[0], *chvals[2], file, func, line, authority,
                compatibility, note,
            )
        )

    for phase, rel, func, selected in _selected_source_lines(ref_repo):
        lines = (ref_repo / rel).read_text(encoding="latin-1").splitlines()
        for line_no in selected:
            raw = lines[line_no - 1].split("//", 1)[0].strip()
            if not raw:
                continue
            wm = re.search(r"gpio_i2c_write\s*\((.*)\)\s*;", raw)
            rm = re.search(r"([A-Za-z_][A-Za-z0-9_]*)\s*=\s*gpio_i2c_read\s*\((.*)\)\s*;", raw)
            dm = re.search(r"msleep\s*\(([^)]+)\)\s*;", raw)
            if wm:
                args = split_args(wm.group(1))
                if len(args) != 3:
                    raise AssertionError(f"unexpected write signature {rel}:{line_no}")
                reg_expr, value_expr = args[1], args[2]
                if eval_c_expr(reg_expr, 0) == 0xFF:
                    add(phase, "BANK_SELECT", reg_expr, value_expr, 0, rel, func, line_no)
                    bank_expr = value_expr
                elif value_expr.strip() in {"YCmerge", "PN_set"}:
                    add(
                        phase,
                        "RMW_CLEAR_CHANNEL_BIT",
                        reg_expr,
                        f"OLD_VALUE & ~(1 << CH_LOCAL) [{value_expr}]",
                        0,
                        rel,
                        func,
                        line_no,
                        "All non-target bits are symbolic and preserved; zero is never assumed.",
                    )
                else:
                    add(phase, "WRITE", reg_expr, value_expr, 0, rel, func, line_no)
            elif rm:
                args = split_args(rm.group(2))
                add(
                    phase,
                    "READ_FOR_RMW",
                    args[1],
                    rm.group(1),
                    0,
                    rel,
                    func,
                    line_no,
                    "Captured old value supplies symbolic preserved bits.",
                )
            elif dm:
                add(phase, "DELAY", "N/A", "N/A", eval_c_expr(dm.group(1), 0), rel, func, line_no)

        if phase == "AHD1080P25":
            add("STATE", "STATE_ASSIGN", "ch_mode_status[CH_LOCAL]", "NVP6134_VI_1080P_2530", 0, "video.c", "nvp6134_set_chnmode", 1159)
            add("STATE", "STATE_ASSIGN", "ch_vfmt_status[CH_LOCAL]", "PAL", 0, "video.c", "nvp6134_set_chnmode", 1160)
        if phase == "EQ_INIT":
            add("EQ_INIT", "STATE_ASSIGN", "s_eq.ch_stage[CH_LOCAL]", "0", 0, "eq.c", "eq_init_each_format", 84)

    if not operations:
        raise AssertionError("empty action manifest")
    return operations


def action_rows(ops: list[ActionOp]) -> list[dict[str, Any]]:
    return [asdict(op) for op in ops]


def replay_actions(ops: list[ActionOp], channel: int) -> dict[str, Any]:
    if channel not in (0, 2):
        raise ValueError("first-target policy permits CH1 or CH3 only")
    bank: int | None = None
    symbolic: dict[tuple[int, int], str] = {}
    state: dict[str, str] = {}
    delay_ms = 0
    i2c_ops = 0
    for op in ops:
        if op.operation == "BANK_SELECT":
            bank = eval_c_expr(op.value_mask_expression, channel) & 0xFF
            i2c_ops += 1
        elif op.operation == "WRITE":
            assert bank is not None
            reg = eval_c_expr(op.register_expression, channel) & 0xFF
            value = eval_c_expr(op.value_mask_expression, channel) & 0xFF
            symbolic[(bank, reg)] = _hex8(value)
            i2c_ops += 1
        elif op.operation == "READ_FOR_RMW":
            assert bank is not None
            reg = eval_c_expr(op.register_expression, channel) & 0xFF
            symbolic.setdefault((bank, reg), f"OLD_B{bank:02X}_R{reg:02X}")
            i2c_ops += 1
        elif op.operation == "RMW_CLEAR_CHANNEL_BIT":
            assert bank is not None
            reg = eval_c_expr(op.register_expression, channel) & 0xFF
            old = symbolic.get((bank, reg), f"OLD_B{bank:02X}_R{reg:02X}")
            symbolic[(bank, reg)] = f"({old})&~0x{1 << channel:02X}"
            i2c_ops += 1
        elif op.operation == "DELAY":
            delay_ms += op.delay_ms
        elif op.operation == "STATE_ASSIGN":
            state[op.register_expression] = op.value_mask_expression
        else:
            raise AssertionError(op.operation)
    canonical = {
        "channel_local": channel,
        "final_bank": bank,
        "delay_ms": delay_ms,
        "i2c_operation_count": i2c_ops,
        "state": state,
        "register_state": {f"B{b:02X}_R{r:02X}": value for (b, r), value in sorted(symbolic.items())},
    }
    blob = json.dumps(canonical, sort_keys=True, separators=(",", ":")).encode()
    canonical["replay_sha256"] = hashlib.sha256(blob).hexdigest().upper()
    return canonical


def candidate_registers() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    def add(group: str, bank: int, reg: int, scope: str, meaning: str, page: str,
            ref_file: str, ref_func: str, current: str, authority: str,
            confidence: str, unresolved: bool = False) -> None:
        rows.append({
            "Group": group,
            "Bank": _hex8(bank),
            "Register": _hex8(reg),
            "ChannelScope": scope,
            "Meaning": meaning,
            "ReadSafe": "YES_OBSERVATIONAL_READ",
            "ReadSideEffect": "NO_KNOWN_READ_SIDE_EFFECT",
            "WriteUsedByReference": "YES" if (bank, reg) in {(0,0x80),(0,0x81),(0,0x82),(0,0x83),(0,0x84),(0,0x85),(0,0x86),(0,0x87),(0,0x88)} else "NO_OR_NOT_IN_DETECTION_PATH",
            "NVP6134CDataSheetPage": page,
            "NVP6134DataSheetPage": "corresponding Rev0.3 register table or private driver semantic",
            "ReferenceFile": ref_file,
            "ReferenceFunction": ref_func,
            "CurrentV41Use": current,
            "HardwareConfirmed": "NO_NEW_HARDWARE_CONTACT; ACCEPTED_CURRENT_USE_ONLY" if current != "NONE" else "NO",
            "AuthorityClass": authority,
            "Confidence": confidence,
            "SCAN1Disposition": "INCLUDE_READ_ONLY_INTERPRETATION_UNRESOLVED" if unresolved else "INCLUDE_READ_ONLY",
            "InterpretationUnresolved": "YES" if unresolved else "NO",
        })

    add("G0-PRE",0,0xA8,"ALL_CH_BITS","NOVID pre-bookend","42; detailed 63","video.c","nvp6134_getvideoloss","DIAG1_STATUS_READ","NVP6134C_DATASHEET","HIGH")
    add("G0-ID",0,0xF4,"CHIP","device ID","42; detailed 66","nvp6134_drv.c","chip identification","AUTOINIT/DIAG_ID","NVP6134C_DATASHEET","HIGH")
    add("G0-ID",0,0xF5,"CHIP","revision ID","42; detailed 66","nvp6134_drv.c","chip identification","AUTOINIT/DIAG_ID","NVP6134C_DATASHEET","HIGH")
    add("G0-ID",0,0x80,"CHIP","per-channel register control mask","41; detailed 60","video.c","set-channel functions","DIAG1_CONFIG_VERIFY","NVP6134C_DATASHEET","HIGH")
    lock_rows = [
        (0xA8,"NOVID live status","42;63","DIAG1_STATUS_READ"),
        (0xB0,"latched/held NOVID status; B0 itself is not a documented clear trigger","42;63-64","NONE"),
        (0xE0,"AGC lock bits","42;65","DIAG1_STATUS_READ"),
        (0xE1,"clamp/comparator lock bits","42;65","DIAG1_STATUS_READ"),
        (0xE2,"horizontal lock bits","42;65","DIAG1_STATUS_READ"),
        (0x7A,"channel 1/2 data-out mode","40;59","DIAG1_CONFIG_VERIFY"),
        (0x7B,"channel 3/4 data-out mode","40;59","DIAG1_CONFIG_VERIFY"),
    ]
    for reg, meaning, page, current in lock_rows:
        add("G0-LOCK",0,reg,"CHIP_OR_PACKED_CHANNELS",meaning,page,"video.c","status/output helpers",current,"NVP6134C_DATASHEET","HIGH")
    for ch in range(4):
        label = f"CH{ch+1}"
        add("G0-CH",0,0xE8+ch,label,"FSC change/color-kill/FSC-lock/NOVID packed status","42;66","video.c","status helpers","DIAG1_CHANNEL_STATUS_READ","NVP6134C_DATASHEET","HIGH")
        add("G0-CH",0,0x81+ch,label,"SD/AHD mode selection","41;60","video.c","set-channel functions","DIAG1_CONFIG_VERIFY","NVP6134C_DATASHEET","HIGH")
        add("G0-CH",0,0x85+ch,label,"special-mode selection","43;60","video.c","set-channel functions","DIAG1_CONFIG_VERIFY","NVP6134C_DATASHEET","HIGH")
        add("G0-CH",0,0x23+4*ch,label,"YC/color-kill configuration readback","38;58","video.c","set-channel functions","DIAG1_CONFIG_VERIFY","NVP6134C_DATASHEET","HIGH")
    for reg, meaning in ((0x97,"channel reset/power control"),(0x98,"channel reset/power control")):
        add("G1",1,reg,"PACKED_CHANNELS",meaning,"44","video.c","set-channel functions","AUTOINIT_CONFIG","NVP6134C_DATASHEET","HIGH")
    for ch in range(4):
        add("G1",1,0x84+ch,f"CH{ch+1}","ADC clock selection","44;87","video.c","video_fmt_det/set-channel","DIAG1_CONFIG_VERIFY","NVP6134C_DATASHEET","HIGH")
        add("G1",1,0x8C+ch,f"CH{ch+1}","pre/decoder clock selection","44;87","video.c","video_fmt_det/set-channel","DIAG1_CONFIG_VERIFY","NVP6134C_DATASHEET","HIGH")
    private = [
        (0xF0,"raw video-format classifier","88",False),
        (0xF2,"format conversion auxiliary","not public",True),
        (0xF3,"special-format discriminator","not public",True),
        (0xF4,"special-format vertical-count discriminator","not public",True),
        (0xF5,"special-format vertical-count discriminator","not public",True),
        (0xE2,"ACC gain high byte","not public",True),
        (0xE3,"ACC gain low byte","not public",True),
        (0xE8,"Y-plus slope high bits","not public",True),
        (0xE9,"Y-plus slope low byte","not public",True),
        (0xEA,"Y-minus slope high bits","not public",True),
        (0xEB,"Y-minus slope low byte","not public",True),
    ]
    for ch in range(4):
        bank = 5 + ch
        for reg, meaning, page, unresolved in private:
            authority = "NVP6134C_DATASHEET" if reg == 0xF0 else "REFERENCE_DRIVER_SEMANTICS"
            confidence = "HIGH" if reg == 0xF0 else "MEDIUM_READ_BEHAVIOR_LOW_NVP6134C_FIELD_MEANING"
            add(f"G{ch+2}",bank,reg,f"CH{ch+1}",meaning,page,"video.c/eq_common.c","video_fmt_det/metric helpers","NONE",authority,confidence,unresolved)
    add("G0-POST",0,0xA8,"ALL_CH_BITS","NOVID post-bookend","42;63","video.c","nvp6134_getvideoloss","DIAG1_STATUS_READ","NVP6134C_DATASHEET","HIGH")
    if len(rows) != 82:
        raise AssertionError(f"candidate register count {len(rows)} != 82")
    return rows


def side_effect_blacklist() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for reg in list(range(0xB8, 0xBF)) + list(range(0xC0, 0xC7)):
        rows.append({
            "Bank": "0x00",
            "Register": _hex8(reg),
            "Hazard": "INTERRUPT_OR_LATCH_CLEAR_ON_READ_ADDRESS_CLASS",
            "NVP6134CDataSheetPage": "64",
            "SCAN1Disposition": "PROHIBITED",
            "Rationale": "RD_STATE_CLR selects B8-BE or C0-C6 as clear-trigger range; SCAN1 has no CLR_LATCH.",
        })
    return rows


def scan_manifest(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for idx, item in enumerate(candidates):
        rows.append({
            "EntryIndex": idx,
            "Group": item["Group"],
            "Bank": item["Bank"],
            "Register": item["Register"],
            "ChannelScope": item["ChannelScope"],
            "Meaning": item["Meaning"],
            "AuthorityClass": item["AuthorityClass"],
            "InterpretationUnresolved": item["InterpretationUnresolved"],
            "Operation": "READ_ONLY",
        })
    return rows


def scan_time_rows(scan_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    group_order = ["G0-PRE","G0-ID","G0-LOCK","G0-CH","G1","G2","G3","G4","G5","G0-POST"]
    rows: list[dict[str, Any]] = []
    for group in group_order:
        entries = sum(1 for row in scan_rows if row["Group"] == group)
        reads = entries + 1  # bank-select readback
        writes = 1          # bank select
        periods = reads * READ_SCL_PERIODS + writes * WRITE_SCL_PERIODS
        rows.append({
            "Group": group,
            "DataEntries": entries,
            "ReadTransactions": reads,
            "WriteTransactions": writes,
            "TotalTransactions": reads + writes,
            "SCLPeriods": periods,
            "EstimatedTimeMsAt25000Hz": f"{periods * 1000 / I2C_HZ:.3f}",
            "MaximumOwnershipIntervalMs": f"{periods * 1000 / I2C_HZ:.3f}",
        })
    pre_periods = READ_SCL_PERIODS
    restore_periods = WRITE_SCL_PERIODS + READ_SCL_PERIODS
    rows.insert(0, {
        "Group":"ENTRY_BANK_CAPTURE","DataEntries":0,"ReadTransactions":1,"WriteTransactions":0,
        "TotalTransactions":1,"SCLPeriods":pre_periods,
        "EstimatedTimeMsAt25000Hz":f"{pre_periods*1000/I2C_HZ:.3f}",
        "MaximumOwnershipIntervalMs":f"{pre_periods*1000/I2C_HZ:.3f}",
    })
    rows.append({
        "Group":"ENTRY_BANK_RESTORE","DataEntries":0,"ReadTransactions":1,"WriteTransactions":1,
        "TotalTransactions":2,"SCLPeriods":restore_periods,
        "EstimatedTimeMsAt25000Hz":f"{restore_periods*1000/I2C_HZ:.3f}",
        "MaximumOwnershipIntervalMs":f"{restore_periods*1000/I2C_HZ:.3f}",
    })
    total_reads = sum(int(r["ReadTransactions"]) for r in rows)
    total_writes = sum(int(r["WriteTransactions"]) for r in rows)
    total_periods = sum(int(r["SCLPeriods"]) for r in rows)
    rows.append({
        "Group":"TOTAL","DataEntries":len(scan_rows),"ReadTransactions":total_reads,"WriteTransactions":total_writes,
        "TotalTransactions":total_reads+total_writes,"SCLPeriods":total_periods,
        "EstimatedTimeMsAt25000Hz":f"{total_periods*1000/I2C_HZ:.3f}",
        "MaximumOwnershipIntervalMs":max(float(r["MaximumOwnershipIntervalMs"]) for r in rows),
    })
    if total_reads + total_writes != 105 or total_periods != 3681:
        raise AssertionError((total_reads, total_writes, total_periods))
    return rows


def manifest_digest(rows: list[dict[str, Any]]) -> str:
    blob = json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(blob).hexdigest().upper()


def assert_authority_gates(ref_repo: Path, current_repo: Path) -> None:
    if git(ref_repo, "rev-parse", "HEAD") != REFERENCE_COMMIT:
        raise AssertionError("reference HEAD mismatch")
    if git(ref_repo, "status", "--short"):
        raise AssertionError("reference checkout is dirty")
    if git(current_repo, "rev-parse", "HEAD") != CURRENT_COMMIT:
        raise AssertionError("current source HEAD mismatch")
    if git(current_repo, "rev-parse", "HEAD^{tree}") != CURRENT_TREE:
        raise AssertionError("current source tree mismatch")


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--task-root", type=Path, required=True)
    p.add_argument("--current-repo", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    ref_repo = args.task_root / "reference-repo"
    assert_authority_gates(ref_repo, args.current_repo)
    refs = reference_manifest(ref_repo)
    current = current_inventory(args.current_repo)
    actions = action_manifest(ref_repo)
    candidates = candidate_registers()
    scan = scan_manifest(candidates)
    timing = scan_time_rows(scan)
    write_json(args.output / "model_summary.json", {
        "reference_files": len(refs), "current_files": len(current),
        "action_operations": len(actions), "symbolic_preserved_fields": 2,
        "candidate_entries": len(candidates), "scan_entries": len(scan),
        "unresolved_scanner_semantics": sum(r["InterpretationUnresolved"] == "YES" for r in candidates),
        "blacklisted_registers": len(side_effect_blacklist()),
        "scan_transactions": timing[-1]["TotalTransactions"],
        "scan_scl_periods": timing[-1]["SCLPeriods"],
        "scan_time_ms": timing[-1]["EstimatedTimeMsAt25000Hz"],
        "max_group_ownership_ms": timing[-1]["MaximumOwnershipIntervalMs"],
        "ch1_replay": replay_actions(actions, 0),
        "ch3_replay": replay_actions(actions, 2),
    })
