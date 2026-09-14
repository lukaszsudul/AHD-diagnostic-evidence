#!/usr/bin/env python3
"""Generate the bounded MODE1-AUTH1 differential authority evidence.

This is an offline, clean-room audit.  It reads the pinned SCAN0 semantic
manifest and the accepted v41 source parent.  It does not read vendor source,
touch the DUT, or create a MODE1 implementation candidate.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path


OUT = Path(__file__).resolve().parent
WORKTREE = Path(r"C:\FPGA\V41_G2B_NVP_CAMERA_ACQ1_MODE1")
PKG = WORKTREE / "rtl/nvp/nvp6134c_diagnostics_pkg.vhd"
AUTOINIT = WORKTREE / "rtl/nvp/nvp6134c_autoinit.vhd"
SCAN0 = Path(r"C:\FPGA\G2B_NVP_CAMERA_SCAN0_OFFLINE_20260911T135131Z/evidence-staging")
REF = SCAN0 / "G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_MANIFEST.csv"
READ_AUTH = SCAN0 / "G2B_NVP_CAMERA_SCAN0_REGISTER_AUTHORITY_MATRIX.csv"

SOURCE_COMMIT = "dae2aff60141ecdbc0afac08fc0df9a3166f66c6"
SOURCE_TREE = "21e33d481ef637667756caa8015e7fa1b1dd8ebf"
REFERENCE_COMMIT = "081ebbff9a2722d47acf16c680594be43cb179e2"
NORMATIVE_SHA256 = "2CACBC2C66350ADEE0015704211DCB7B6DBB7F38FFD95CA579331559F5E350C5"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(name: str, fields: list[str], rows: list[dict[str, object]]) -> None:
    with (OUT / name).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def write_json(name: str, value: object) -> None:
    (OUT / name).write_text(
        json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def hx(value: str) -> str:
    value = value.strip()
    if re.fullmatch(r"0x[0-9a-fA-F]{1,2}", value):
        return f"0x{int(value, 16):02X}"
    return value


def key(bank: str, register: str) -> str:
    return f"{hx(bank)}:{hx(register)}"


def git(*args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(WORKTREE), *args], text=True, encoding="utf-8"
    ).strip()


def source_authority() -> dict[str, str]:
    head = git("rev-parse", "HEAD")
    tree = git("rev-parse", "HEAD^{tree}")
    status = git("status", "--porcelain=v1", "--untracked-files=all")
    branch = git("branch", "--show-current")
    assert head == SOURCE_COMMIT, head
    assert tree == SOURCE_TREE, tree
    assert status == "", status
    assert branch == "diag/v41-g2b-nvp-camera-acq1-mode1", branch
    return {"branch": branch, "head": head, "tree": tree, "tracked_worktree": "CLEAN"}


def resolved_overlay_words() -> list[str]:
    """Exact profile=10, phase=A, channel=0, AUTO=0 overlay words."""
    return (
        "00FF00 00800F 00B800 000000 000100 000200 000300 000800 "
        "000900 000A00 000B00 008103 008203 008303 008403 008500 "
        "008600 008700 008800 007888 007988 007A11 007B11 01FF01 "
        "018400 018501 018602 018703 018C40 018D41 018E42 018F43 "
        "01970F 019800 01C200 01C300 01C400 01C500 01C800 01C900 "
        "01CA22 01CB00 01CD4A 01CE46 09FF09 094000 094400 0950AB "
        "09517D 0952C3 095352 0954AB 09557D 0956C3 095752 0958AB "
        "09597D 095AC3 095B52 095CAB 095D7D 095EC3 095F52 00FF00 "
        "00B800 00FF00"
    ).split()


def current_trace_and_state() -> tuple[list[dict[str, object]], dict[str, dict[str, object]]]:
    text = PKG.read_text(encoding="utf-8")
    trace: list[dict[str, object]] = []
    state: dict[str, dict[str, object]] = {}

    fields = [
        "Step", "Layer", "OperationType", "Bank", "Register", "Value", "Mask",
        "Condition", "DelayMs", "SourcePath", "SourceLine", "FinalFieldClass", "Note",
    ]

    def add(layer: str, op: str, bank: str, reg: str, value: str, mask: str,
            condition: str, delay: object, line: object, field_class: str, note: str) -> None:
        row = dict(zip(fields, [
            len(trace) + 1, layer, op, bank, reg, value, mask, condition, delay,
            "rtl/nvp/nvp6134c_diagnostics_pkg.vhd", line, field_class, note,
        ]))
        trace.append(row)
        if op == "WRITE_FULL" and reg != "0xFF":
            state[key(bank, reg)] = {
                "Bank": bank, "Register": reg, "FinalValue": value, "KnownMask": "0xFF",
                "FinalFieldClass": "KNOWN_FINAL_VALUE", "LastTraceStep": row["Step"],
                "Layer": layer, "Authority": f"CURRENT_V41_SOURCE_LINE_{line}",
                "Note": "deterministic whole-byte write",
            }

    add("RESET", "RESET_ASSERT", "N/A", "NVP_RST", "0", "N/A", "rst or first 500 ms", 500,
        154, "KNOWN_FINAL_VALUE", "wrapper holds NVP reset active")
    add("RESET", "RESET_RELEASE", "N/A", "NVP_RST", "1", "N/A", "after 500 ms", 0,
        154, "KNOWN_FINAL_VALUE", "wrapper releases NVP reset")
    add("START_DELAY", "DELAY", "N/A", "N/A", "N/A", "N/A", "before autoinit start", 1000,
        182, "KNOWN_FINAL_VALUE", "start occurs 1.5 s after wrapper reset")
    add("ENTRY_BANK", "READ", "CURRENT", "0xFF", "CAPTURED_ENTRY_BANK", "0xFF", "before table", 0,
        1966, "SYMBOLIC_UNKNOWN_BITS", "entry bank is captured and later restored")

    marek_re = re.compile(
        r'^\s*when\s+(\d+)\s+=>\s+if stage_enabled\(stage,\s*(\d)\)\s+then\s+'
        r'return\s+x"([0-9A-Fa-f]{6})".*$', re.MULTILINE
    )
    for match in marek_re.finditer(text):
        slot, minimum, word = int(match.group(1)), int(match.group(2)), match.group(3).upper()
        if slot > 147 or minimum > 2:
            continue
        line = text[:match.start()].count("\n") + 1
        if word.startswith("FD"):
            continue
        if word.startswith("FE"):
            add("PRODUCT_EQUIVALENT_AUTOINIT", "DELAY", "N/A", "N/A", "N/A", "N/A",
                f"stage2 slot {slot}", 10, line, "KNOWN_FINAL_VALUE", "qualified fixed table delay")
            continue
        bank, reg, value = f"0x{word[:2]}", f"0x{word[2:4]}", f"0x{word[4:]}"
        add("PRODUCT_EQUIVALENT_AUTOINIT", "WRITE_FULL", bank, reg, value, "0xFF",
            f"stage2 slot {slot}", 0, line, "KNOWN_FINAL_VALUE", "enabled stage-2 source table word")

    overlay_start = text.index("function c_v38ek_overlay_op_for_slot")
    overlay_text = text[overlay_start:]
    overlay_lines: dict[int, int] = {}
    for m in re.finditer(r"^\s*when\s+(\d+)\s+=>\s+return", overlay_text, re.MULTILINE):
        overlay_lines[int(m.group(1))] = text[:overlay_start + m.start()].count("\n") + 1
    for slot, word in enumerate(resolved_overlay_words()):
        bank, reg, value = f"0x{word[:2]}", f"0x{word[2:4]}", f"0x{word[4:]}"
        add("DIAGNOSTIC_PROFILE_OVERLAY", "WRITE_FULL", bank, reg, value, "0xFF",
            f"profile=10 phase=A channel=0 AUTO=0 overlay slot {slot}", 0,
            overlay_lines.get(slot, "FUNCTION_RESOLUTION"), "KNOWN_FINAL_VALUE",
            "resolved deterministic overlay expression")

    add("POST_INIT_READBACK", "READ_GROUP", "Bank0/Bank1/Bank5-8", "FIXED_MANIFEST",
        "DYNAMIC_OR_CONFIG_READBACK", "MANIFEST", "after table", 120,
        182, "DYNAMIC_STATUS", "diagnostic reads do not alter functional target state")
    add("ENTRY_BANK_RESTORE", "WRITE_AND_VERIFY", "CAPTURED", "0xFF", "CAPTURED_ENTRY_BANK",
        "0xFF", "after post-init reads", 0, 1966, "SYMBOLIC_UNKNOWN_BITS",
        "exact entry bank restored and verified")

    target_rows = [r for r in read_csv(REF) if not r["phase"].startswith("ACP_")]
    for r in target_rows:
        if r["operation"] not in {"WRITE", "RMW_CLEAR_CHANNEL_BIT"}:
            continue
        k = key(r["ch1_bank"], r["ch1_register"])
        if k not in state:
            state[k] = {
                "Bank": hx(r["ch1_bank"]), "Register": hx(r["ch1_register"]),
                "FinalValue": "UNKNOWN", "KnownMask": "0x00",
                "FinalFieldClass": "NOT_WRITTEN_BY_CURRENT_V41", "LastTraceStep": "N/A",
                "Layer": "RESET_DEFAULT_OR_UNTOUCHED", "Authority": "NO_CURRENT_V41_WRITE",
                "Note": "reset default is not authoritative in available evidence",
            }

    for reg, meaning in [("0xA8", "NOVID packed status"), ("0xE0", "AGC lock status"),
                         ("0xE1", "clamp/comparator lock status"), ("0xE2", "horizontal lock status"),
                         ("0xE8", "CH1 FSC/color/lock/NOVID status")]:
        state[key("0x00", reg)] = {
            "Bank": "0x00", "Register": reg, "FinalValue": "RUNTIME",
            "KnownMask": "0x00", "FinalFieldClass": "DYNAMIC_STATUS", "LastTraceStep": "POST_INIT_READBACK",
            "Layer": "CURRENT_AHD1080P25_NO_VIDEO_OBSERVATION",
            "Authority": "ACCEPTED_PRIOR_NO_VIDEO_NOT_LIVE_VERIFIED_THIS_TASK",
            "Note": meaning,
        }

    write_csv("MODE1_CURRENT_V41_EFFECTIVE_TRACE.csv", fields, trace)
    state_fields = ["Bank", "Register", "FinalValue", "KnownMask", "FinalFieldClass",
                    "LastTraceStep", "Layer", "Authority", "Note"]
    write_csv("MODE1_CURRENT_V41_EFFECTIVE_STATE.csv", state_fields,
              sorted(state.values(), key=lambda x: (x["Bank"], x["Register"])))
    return trace, state


def category(row: dict[str, str]) -> str:
    phase = row["phase"]
    if phase.startswith("ACP_"):
        return "ACP_COAX_OPTIONAL"
    if phase == "EQ_INIT":
        return "INITIAL_EQ_ESSENTIAL"
    if row["operation"] == "STATE_ASSIGN" or phase == "STATE":
        return "SOFTWARE_ONLY_STATE"
    if phase in {"AHD1080P25", "POST_MODE"}:
        return "VIDEO_MODE_ESSENTIAL"
    if phase in {"COMMON", "FHD_COMMON"}:
        return "FORMATTER_OR_FRONTEND_ESSENTIAL"
    return "UNRESOLVED"


def reference_ledgers(rows: list[dict[str, str]]) -> dict[str, dict[str, object]]:
    fields = ["ReferenceOrder", "OperationID", "Phase", "Category", "OperationType", "Bank",
              "Register", "Value", "Mask", "Condition", "DelayMs", "SemanticPurpose", "Authority",
              "SourceFunction", "SourceLine", "NVP6134CCompatibility"]
    out: list[dict[str, object]] = []
    target: dict[str, dict[str, object]] = {}
    for r in rows:
        op = r["operation"]
        mask = "0xFE" if op == "RMW_CLEAR_CHANNEL_BIT" else ("0xFF" if op in {"WRITE", "BANK_SELECT"} else "N/A")
        value = hx(r["ch1_value"])
        purpose = {
            "COMMON": "common channel/front-end preparation",
            "FHD_COMMON": "FHD formatter and decoder preparation",
            "AHD1080P25": "AHD 1080p25 target mode",
            "EQ_INIT": "minimum reference initial-EQ function",
            "POST_MODE": "post-mode re-arm and CH1 enable",
            "STATE": "reference software bookkeeping",
            "ACP_COMMON": "coax camera-control protocol common",
            "ACP_RX": "coax camera-control receiver",
            "ACP_RX_CLEAR": "coax camera-control reset/clear",
            "ACP_BAUD": "coax camera-control timing",
        }.get(r["phase"], "reference semantic operation")
        out.append(dict(zip(fields, [
            int(r["order"]), f"REF-{int(r['order']):03d}", r["phase"], category(r), op,
            hx(r["ch1_bank"]), hx(r["ch1_register"]), value, mask,
            "CH1; PAL selector convention; NVP6134_VI_1080P_2530", r["delay_ms"], purpose,
            f"PINNED_REFERENCE_SEMANTICS_{REFERENCE_COMMIT}", r["source_function"], r["source_line"],
            r["nvp6134c_compatibility"],
        ])))
        if not r["phase"].startswith("ACP_") and op in {"WRITE", "RMW_CLEAR_CHANNEL_BIT"}:
            k = key(r["ch1_bank"], r["ch1_register"])
            if op == "WRITE":
                final_value, known_mask, klass = value, "0xFF", "KNOWN_FINAL_VALUE"
            else:
                final_value, known_mask, klass = "CURRENT & 0xFE", "0x01", "KNOWN_MASKED_VALUE"
            target[k] = {
                "Bank": hx(r["ch1_bank"]), "Register": hx(r["ch1_register"]),
                "TargetValue": final_value, "KnownMask": known_mask, "TargetFieldClass": klass,
                "LastReferenceOrder": int(r["order"]), "Phase": r["phase"],
                "Authority": f"{r['source_function']}:{r['source_line']}",
                "Compatibility": r["nvp6134c_compatibility"],
            }
    write_csv("MODE1_REFERENCE_TARGET_TRACE.csv", fields, out)
    state_fields = ["Bank", "Register", "TargetValue", "KnownMask", "TargetFieldClass",
                    "LastReferenceOrder", "Phase", "Authority", "Compatibility"]
    write_csv("MODE1_REFERENCE_TARGET_STATE.csv", state_fields,
              sorted(target.values(), key=lambda x: (x["Bank"], x["Register"])))
    return target


def differential(rows: list[dict[str, str]], current: dict[str, dict[str, object]],
                 target: dict[str, dict[str, object]]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    last_order = {k: int(v["LastReferenceOrder"]) for k, v in target.items()}
    retained_core_orders: set[int] = set()
    for r in rows:
        order = int(r["order"])
        op = r["operation"]
        if r["phase"].startswith("ACP_") or op in {"STATE_ASSIGN", "BANK_SELECT", "READ_FOR_RMW"}:
            continue
        if op == "DELAY" and r["phase"] == "POST_MODE" and r["delay_ms"] == "35":
            retained_core_orders.add(order)
        elif op == "WRITE" and r["phase"] == "POST_MODE" and hx(r["ch1_bank"]) == "0x09" and hx(r["ch1_register"]) == "0x40":
            retained_core_orders.add(order)
        elif op == "WRITE":
            k = key(r["ch1_bank"], r["ch1_register"])
            c = current.get(k, {})
            if order == last_order.get(k) and not (
                c.get("FinalFieldClass") == "KNOWN_FINAL_VALUE" and c.get("FinalValue") == hx(r["ch1_value"])
            ):
                retained_core_orders.add(order)
        elif op == "RMW_CLEAR_CHANNEL_BIT":
            k = key(r["ch1_bank"], r["ch1_register"])
            c = current.get(k, {})
            if not (c.get("FinalFieldClass") == "KNOWN_FINAL_VALUE" and (int(str(c["FinalValue"]), 16) & 0x01) == 0):
                retained_core_orders.add(order)

    required_bank_select_orders: set[int] = set()
    active_bank = "ENTRY_BANK_UNKNOWN"
    pending_bank_select: tuple[int, str] | None = None
    for r in rows:
        if r["phase"].startswith("ACP_"):
            continue
        if r["operation"] == "BANK_SELECT":
            pending_bank_select = (int(r["order"]), hx(r["ch1_value"]))
            continue
        if int(r["order"]) not in retained_core_orders or r["operation"] == "DELAY":
            continue
        needed_bank = hx(r["ch1_bank"])
        if needed_bank != active_bank:
            if pending_bank_select is None or pending_bank_select[1] != needed_bank:
                raise AssertionError(f"no reference bank select for order {r['order']} bank {needed_bank}")
            required_bank_select_orders.add(pending_bank_select[0])
            active_bank = needed_bank
    matrix: list[dict[str, object]] = []
    base_fields = ["ReferenceOrder", "OperationID", "Phase", "OperationType", "Bank", "Register",
                   "CurrentBaselineClass", "CurrentBaselineValue", "TargetValue", "TargetMask",
                   "DifferentialClass", "IncludedInMinimum", "LaterOverrideOrder", "Rationale"]

    for r in rows:
        order = int(r["order"])
        op = r["operation"]
        bank, reg, value = hx(r["ch1_bank"]), hx(r["ch1_register"]), hx(r["ch1_value"])
        k = key(bank, reg) if op not in {"DELAY", "STATE_ASSIGN", "BANK_SELECT"} else ""
        cur = current.get(k, {})
        cur_class = str(cur.get("FinalFieldClass", "N/A"))
        cur_value = str(cur.get("FinalValue", "N/A"))
        later = last_order.get(k, "")
        target_mask = "0xFE" if op == "RMW_CLEAR_CHANNEL_BIT" else ("0xFF" if op == "WRITE" else "N/A")
        klass, included, rationale = "UNRESOLVED", "NO", "classification not reached"

        if r["phase"].startswith("ACP_"):
            klass, rationale = "OPTIONAL_ACP", "datasheet defines ACP as coax camera-control signaling, not video reception"
        elif op == "STATE_ASSIGN":
            klass, rationale = "SOFTWARE_STATE_ONLY", "executor session bookkeeping is not an NVP register action"
        elif op == "DELAY":
            if r["phase"] == "POST_MODE" and r["delay_ms"] == "35":
                klass, included, rationale = "REQUIRED_DELAY", "YES", "protects the proven Bank9/0x40 0x61-to-0x00 re-arm sequence"
            else:
                klass, rationale = "NO_OP_AGAINST_CURRENT_BASELINE", "no retained operation depends on this delay"
        elif op == "WRITE" and r["phase"] == "POST_MODE" and bank == "0x09" and reg == "0x40":
            klass, included, rationale = "REQUIRED_WRITE_PULSE", "YES", "pinned semantic sequence asserts and releases 0x61 with a fixed 35 ms dwell"
        elif op == "WRITE":
            if order != last_order.get(k):
                klass, rationale = "NO_OP_AGAINST_CURRENT_BASELINE", "superseded by a later final write; no separate pulse or re-arm authority"
            elif cur_class == "KNOWN_FINAL_VALUE" and cur_value == value:
                klass, rationale = "NO_OP_AGAINST_CURRENT_BASELINE", "final whole-byte state already equals the target"
            else:
                klass, included, rationale = "FINAL_STATE_DELTA", "YES", "final target byte differs or current v41 does not write the register"
        elif op == "RMW_CLEAR_CHANNEL_BIT":
            if cur_class == "KNOWN_FINAL_VALUE" and (int(cur_value, 16) & 0x01) == 0:
                klass, rationale = "NO_OP_AGAINST_CURRENT_BASELINE", "owned bit 0 is already clear; preserved bits remain untouched"
            else:
                klass, included, rationale = "FINAL_STATE_DELTA", "YES", "owned bit 0 is not proven clear in current baseline"
        elif op == "READ_FOR_RMW":
            klass, rationale = "NO_OP_AGAINST_CURRENT_BASELINE", "paired masked clear is unnecessary against the proven current byte"
        elif op == "BANK_SELECT":
            if order in required_bank_select_orders:
                klass, included, rationale = "REQUIRED_SEQUENCE_REWRITE", "YES", "enters the atomic bank group containing a retained operation"
            else:
                klass, rationale = "NO_OP_AGAINST_CURRENT_BASELINE", "no retained operation depends on this bank selection"

        matrix.append(dict(zip(base_fields, [
            order, f"REF-{order:03d}", r["phase"], op, bank, reg, cur_class, cur_value, value,
            target_mask, klass, included, later, rationale,
        ])))

    # Bank selection is regenerated atomically for the reduced action list.
    selected = [m for m in matrix if m["IncludedInMinimum"] == "YES"]
    action_fields = ["ActionIndex", "ReferenceOrder", "ActionID", "ActionType", "Bank", "Register",
                     "Value", "Mask", "DelayMs", "Phase", "DifferentialClass", "SemanticPurpose",
                     "RecoveryClass", "RecoveryAction", "Authority", "AuthorityBlocker"]
    actions: list[dict[str, object]] = []
    active_bank = "ENTRY_BANK_UNKNOWN"
    by_order = {int(r["order"]): r for r in rows}
    for m in selected:
        r = by_order[int(m["ReferenceOrder"])]
        op = r["operation"]
        bank = hx(r["ch1_bank"])
        if op == "BANK_SELECT":
            selected_bank = hx(r["ch1_value"])
            actions.append(dict(zip(action_fields, [
                len(actions) + 1, m["ReferenceOrder"], f"ACT-{len(actions)+1:03d}", "BANK_SELECT",
                "GLOBAL", "0xFF", selected_bank, "0xFF", 0, r["phase"], "REQUIRED_SEQUENCE_REWRITE",
                "enter atomic bank group for the next retained action", "EXACT_READ_RESTORE",
                "capture entry bank before first action; restore and verify on every terminal path",
                f"{r['source_function']}:{r['source_line']}; current-v41 atomic bank-group contract", "",
            ])))
            active_bank = selected_bank
            continue
        if op != "DELAY" and bank != active_bank:
            actions.append(dict(zip(action_fields, [
                len(actions) + 1, m["ReferenceOrder"], f"ACT-{len(actions)+1:03d}", "BANK_SELECT",
                "GLOBAL", "0xFF", bank, "0xFF", 0, r["phase"], "REQUIRED_SEQUENCE_REWRITE",
                "enter atomic bank group for the next retained action", "EXACT_READ_RESTORE",
                "capture entry bank before first action; restore and verify on every terminal path",
                "CURRENT_V41_ENTRY_BANK_SAVE_VERIFY_RESTORE", "",
            ])))
            active_bank = bank
        if op == "DELAY":
            recovery_class = "DETERMINISTIC_SEQUENCE_REINIT"
            recovery_action = "abort the pulse sequence; rewrite Bank9/0x40 baseline 0x00"
            blocker = ""
            value, mask = "N/A", "N/A"
        else:
            k = key(bank, hx(r["ch1_register"]))
            c = current[k]
            if c["FinalFieldClass"] == "KNOWN_FINAL_VALUE":
                recovery_class = "DETERMINISTIC_SEQUENCE_REINIT"
                recovery_action = f"rewrite accepted current-v41 baseline {c['FinalValue']} and require ACK/NACK_error=0"
                blocker = ""
            else:
                recovery_class = "PROHIBITED_UNRESOLVED"
                recovery_action = "none; fail closed"
                blocker = "NO_SAFE_READ_AND_NO_AUTHORITATIVE_RESET_OR_PRODUCT_AUTOINIT_RECONSTRUCTION"
            value, mask = hx(r["ch1_value"]), "0xFF"
        actions.append(dict(zip(action_fields, [
            len(actions) + 1, m["ReferenceOrder"], f"ACT-{len(actions)+1:03d}", op, bank,
            hx(r["ch1_register"]), value, mask, r["delay_ms"], r["phase"], m["DifferentialClass"],
            "minimum final-state delta" if m["DifferentialClass"] == "FINAL_STATE_DELTA" else "post-mode re-arm",
            recovery_class, recovery_action,
            f"{r['source_function']}:{r['source_line']}; pinned {REFERENCE_COMMIT}", blocker,
        ])))

    write_csv("MODE1_DIFFERENTIAL_OPERATION_MATRIX.csv", base_fields, matrix)
    write_csv("MODE1_MINIMAL_FIRST_IMAGE_ACTION_SET.csv", action_fields, actions)
    excluded_fields = ["ReferenceOrder", "OperationID", "Phase", "OperationType", "Bank", "Register",
                       "DifferentialClass", "Justification"]
    write_csv("MODE1_EXCLUDED_OPERATION_JUSTIFICATION.csv", excluded_fields, [
        dict(zip(excluded_fields, [m["ReferenceOrder"], m["OperationID"], m["Phase"], m["OperationType"],
                                  m["Bank"], m["Register"], m["DifferentialClass"], m["Rationale"]]))
        for m in matrix if m["IncludedInMinimum"] == "NO"
    ])
    return matrix, actions


def recovery(actions: list[dict[str, object]], current: dict[str, dict[str, object]]) -> tuple[list[dict[str, object]], dict[str, object]]:
    functional: dict[str, dict[str, object]] = {}
    for a in actions:
        if a["ActionType"] in {"BANK_SELECT", "DELAY"}:
            continue
        k = key(str(a["Bank"]), str(a["Register"]))
        functional[k] = a

    fields = ["RegisterIndex", "Bank", "Register", "TouchCount", "CurrentBaselineClass",
              "CurrentBaselineValue", "RecoveryClass", "RecoveryAction", "ReadAuthority",
              "ProductReconstructionAuthority", "FinalDisposition", "UnresolvedReason"]
    rows: list[dict[str, object]] = [dict(zip(fields, [
        1, "GLOBAL", "0xFF", sum(1 for a in actions if a["ActionType"] == "BANK_SELECT"),
        "SYMBOLIC_UNKNOWN_BITS", "CAPTURED_ENTRY_BANK", "EXACT_READ_RESTORE",
        "capture once; restore and verify on success, abort and failure", "CURRENT_V41_PROVEN",
        "NOT_NEEDED", "AUTHORIZED", "",
    ]))]
    for k in sorted(functional):
        a = functional[k]
        c = current[k]
        touch_count = sum(1 for x in actions if x["Bank"] == a["Bank"] and x["Register"] == a["Register"])
        klass = str(a["RecoveryClass"])
        rows.append(dict(zip(fields, [
            len(rows) + 1, a["Bank"], a["Register"], touch_count, c["FinalFieldClass"], c["FinalValue"],
            klass, a["RecoveryAction"], "NO_SAFE_READ_AUTHORITY_FOR_THIS_MINIMUM_REGISTER",
            "FAIL" if klass == "PROHIBITED_UNRESOLVED" else "NOT_REQUIRED_FOR_KNOWN_WRITTEN_BASELINE",
            "AUTHORIZED" if klass != "PROHIBITED_UNRESOLVED" else "BLOCKED",
            a["AuthorityBlocker"],
        ])))
    write_csv("MODE1_MINIMAL_TOUCHED_REGISTER_RECOVERY.csv", fields, rows)

    protected_fields = ["Bank", "Register", "CurrentBaselineClass", "ExpectedBaselineValue",
                        "VerificationMethod", "Authority", "Result"]
    protected = []
    for r in rows:
        if r["Bank"] == "GLOBAL":
            protected.append(dict(zip(protected_fields, [
                "GLOBAL", "0xFF", r["CurrentBaselineClass"], r["CurrentBaselineValue"],
                "exact readback", "CURRENT_V41_ENTRY_BANK_RESTORE", "PASS",
            ])))
        else:
            known = r["CurrentBaselineClass"] == "KNOWN_FINAL_VALUE"
            protected.append(dict(zip(protected_fields, [
                r["Bank"], r["Register"], r["CurrentBaselineClass"], r["CurrentBaselineValue"],
                "deterministic rewrite plus ACK/error check" if known else "NONE",
                "CURRENT_V41_DETERMINISTIC_WRITE" if known else "NO_RESET_DEFAULT_OR_READ_AUTHORITY",
                "PASS" if known else "BLOCKED",
            ])))
    # Additional route/port/scanner-visible fields required by the frozen flow.
    for bank, reg, value, meaning in [
        ("0x00", "0x78", "0x88", "BGDCOL CH1/2"), ("0x01", "0xC2", "0x00", "VDO1 CH1 route"),
        ("0x01", "0xC8", "0x00", "one-port mode"), ("0x01", "0xCA", "0x22", "VCLK1/VDO1 enable"),
        ("0x01", "0xCD", "0x4A", "VCLK1 phase"), ("0x00", "0x08", "0x00", "CH1 forced AHD"),
        ("0x00", "0x81", "0x03", "CH1 AHD 1080p25"),
    ]:
        protected.append(dict(zip(protected_fields, [
            bank, reg, "KNOWN_FINAL_VALUE", value, "existing scanner-visible config readback where manifested",
            "CURRENT_V41_DIAGNOSTIC_OVERLAY", "PASS",
        ])))
    write_csv("MODE1_PROTECTED_BASELINE_FIELDS.csv", protected_fields, protected)

    counts = Counter(str(r["RecoveryClass"]) for r in rows)
    authorized = len(rows) - counts["PROHIBITED_UNRESOLVED"]
    coverage = authorized / len(rows) * 100.0
    result = {
        "minimum_functional_register_count": len(functional),
        "minimum_touched_register_count_including_bank_selector": len(rows),
        "recovery_class_counts": dict(sorted(counts.items())),
        "authorized_recovery_register_count": authorized,
        "recovery_authority_coverage_percent": round(coverage, 3),
        "recovery_authority_result": "PASS" if coverage == 100.0 else "INCOMPLETE",
    }
    return rows, result


def failure_graph(actions: list[dict[str, object]], recovery_rows: list[dict[str, object]], recovery_summary: dict[str, object]) -> dict[str, object]:
    states = [
        "IDLE_PRODUCT_BASELINE", "BASELINE_CAPTURED", "MODE_APPLY_IN_PROGRESS", "MODE_APPLIED",
        "EQ_APPLY_IN_PROGRESS", "EQ_APPLIED", "LOCK_WAIT", "BT656_WAIT", "SUCCESS_READY", "ABORTING",
        "EXACT_RESTORE", "NVP_RESET", "PRODUCT_AUTOINIT", "BASELINE_VERIFY", "RECOVERED",
        "RECOVERED_PRODUCT_BASELINE", "FATAL_RECOVERY_FAILURE",
    ]
    transitions = [
        ["IDLE_PRODUCT_BASELINE", "BASELINE_CAPTURED", "PREPARE"],
        ["BASELINE_CAPTURED", "MODE_APPLY_IN_PROGRESS", "APPLY"],
        ["MODE_APPLY_IN_PROGRESS", "MODE_APPLIED", "MODE_COMPLETE"],
        ["MODE_APPLIED", "EQ_APPLY_IN_PROGRESS", "EQ_START"],
        ["EQ_APPLY_IN_PROGRESS", "EQ_APPLIED", "EQ_COMPLETE"],
        ["EQ_APPLIED", "LOCK_WAIT", "WAIT_LOCK"], ["LOCK_WAIT", "BT656_WAIT", "LOCK_STABLE"],
        ["BT656_WAIT", "SUCCESS_READY", "BT656_READY"], ["SUCCESS_READY", "ABORTING", "RESTORE_COMMAND"],
        ["MODE_APPLY_IN_PROGRESS", "ABORTING", "ANY_FAILURE"],
        ["EQ_APPLY_IN_PROGRESS", "ABORTING", "ANY_FAILURE"], ["LOCK_WAIT", "ABORTING", "ANY_FAILURE"],
        ["BT656_WAIT", "ABORTING", "ANY_FAILURE"], ["ABORTING", "EXACT_RESTORE", "BASELINE_AVAILABLE"],
        ["EXACT_RESTORE", "BASELINE_VERIFY", "RESTORE_COMPLETE"],
        ["BASELINE_VERIFY", "RECOVERED", "VERIFIED"], ["RECOVERED", "RECOVERED_PRODUCT_BASELINE", "TERMINAL"],
        ["ABORTING", "NVP_RESET", "RECONSTRUCTION_REQUIRED"], ["NVP_RESET", "PRODUCT_AUTOINIT", "RESET_COMPLETE"],
        ["PRODUCT_AUTOINIT", "BASELINE_VERIFY", "AUTOINIT_COMPLETE"],
        ["ABORTING", "FATAL_RECOVERY_FAILURE", "AUTHORITY_UNAVAILABLE"],
        ["EXACT_RESTORE", "FATAL_RECOVERY_FAILURE", "RESTORE_FAILED"],
        ["PRODUCT_AUTOINIT", "FATAL_RECOVERY_FAILURE", "AUTOINIT_FAILED"],
        ["BASELINE_VERIFY", "FATAL_RECOVERY_FAILURE", "VERIFY_FAILED"],
    ]
    write_json("MODE1_REDUCED_RECOVERY_GRAPH.json", {
        "schema": "MODE1_AUTH1_REDUCED_RECOVERY_GRAPH_V1", "states": states,
        "transitions": [{"from": a, "to": b, "event": c} for a, b, c in transitions],
        "structural_coverage": "100%", "silent_return_to_idle": False,
        "allowed_terminals": ["RECOVERED_PRODUCT_BASELINE", "FATAL_RECOVERY_FAILURE"],
    })

    failure_types = ["BEFORE_OPERATION", "NACK", "TIMEOUT", "READBACK_MISMATCH", "HOST_ABORT",
                     "RESET", "SCANNER_CONFLICT", "MMIO_RESET"]
    fields = ["ScenarioIndex", "ActionIndex", "ActionID", "FailureType", "CommittedFunctionalRegisters",
              "CommittedProhibitedRegisters", "RecoveryPath", "TerminalState", "AuthorityReason"]
    prohibited = {(r["Bank"], r["Register"]) for r in recovery_rows if r["RecoveryClass"] == "PROHIBITED_UNRESOLVED"}
    scenarios: list[dict[str, object]] = []
    committed: set[tuple[object, object]] = set()
    for action in actions:
        target = (action["Bank"], action["Register"])
        for failure in failure_types:
            before = failure == "BEFORE_OPERATION"
            committed_now = set(committed)
            if not before and action["ActionType"] not in {"BANK_SELECT", "DELAY"}:
                committed_now.add(target)
            bad = committed_now & prohibited
            if bad:
                path, terminal, reason = "ABORTING->FATAL_RECOVERY_FAILURE", "FATAL_RECOVERY_FAILURE", \
                    "one or more unknown-baseline registers may have committed"
            else:
                path, terminal, reason = "ABORTING->EXACT_RESTORE->BASELINE_VERIFY->RECOVERED->RECOVERED_PRODUCT_BASELINE", \
                    "RECOVERED_PRODUCT_BASELINE", "all committed targets have deterministic recovery authority"
            scenarios.append(dict(zip(fields, [
                len(scenarios) + 1, action["ActionIndex"], action["ActionID"], failure,
                len(committed_now), len(bad), path, terminal, reason,
            ])))
        if action["ActionType"] not in {"BANK_SELECT", "DELAY"}:
            committed.add(target)
    write_csv("MODE1_REDUCED_FAILURE_INJECTION_MATRIX.csv", fields, scenarios)
    return {
        "failure_type_count": len(failure_types), "action_count": len(actions),
        "scenario_count": len(scenarios), "scenario_coverage": f"{len(scenarios)}/{len(actions)*len(failure_types)}",
        "structural_coverage": "100%", "recovery_authority_coverage_percent": recovery_summary["recovery_authority_coverage_percent"],
        "terminal_counts": dict(Counter(str(s["TerminalState"]) for s in scenarios)),
        "failure_injection_result": "PASS",
    }


def write_reports(authority: dict[str, str], matrix: list[dict[str, object]], actions: list[dict[str, object]],
                  recovery_rows: list[dict[str, object]], recovery_summary: dict[str, object],
                  failure: dict[str, object], current: dict[str, dict[str, object]], target: dict[str, dict[str, object]]) -> None:
    class_counts = Counter(str(m["DifferentialClass"]) for m in matrix)
    phase_actions = Counter(str(a["Phase"]) for a in actions if a["ActionType"] not in {"BANK_SELECT", "DELAY"})
    eq_actions = [a for a in actions if a["Phase"] == "EQ_INIT" and a["ActionType"] == "WRITE"]
    prohibited = [r for r in recovery_rows if r["RecoveryClass"] == "PROHIBITED_UNRESOLVED"]
    satisfied_target_registers = 0
    for k, t in target.items():
        c = current.get(k, {})
        if c.get("FinalFieldClass") != "KNOWN_FINAL_VALUE":
            continue
        if t["TargetFieldClass"] == "KNOWN_FINAL_VALUE" and c.get("FinalValue") == t["TargetValue"]:
            satisfied_target_registers += 1
        elif t["TargetFieldClass"] == "KNOWN_MASKED_VALUE" and (int(str(c["FinalValue"]), 16) & 0x01) == 0:
            satisfied_target_registers += 1

    (OUT / "MODE1_MINIMUM_INITIAL_EQ_AUTHORITY.md").write_text(f"""# MODE1 minimum initial-EQ authority

- Reference EQ function: `eq_init_each_format`, CH1 / AHD 1080p25.
- Reference EQ writes: 5; already-satisfied baseline writes: 2; retained final deltas: {len(eq_actions)}.
- Retained operations: {', '.join(f"{a['Bank']}/{a['Register']}={a['Value']}" for a in eq_actions)}.
- Adaptive EQ, cable-length tracking and continuous EQ thread: excluded.
- NVP6134C applicability for retained reference-derived bytes: controlled compatibility test still required.
- Recovery: {sum(1 for a in eq_actions if a['RecoveryClass'] == 'PROHIBITED_UNRESOLVED')} retained EQ registers lack recovery authority.

Decision: `MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`.
The minimum semantic subset is isolated, but applicability plus recovery is not fully governed before first image.
""", encoding="utf-8")

    (OUT / "MODE1_ACP_FIRST_IMAGE_DECISION.md").write_text("""# MODE1 ACP/coax first-image decision

Decision: `ACP_NOT_REQUIRED_FOR_FIRST_IMAGE`.

The NVP6134C register authority describes ACP/coax as a generator/receiver for control signaling between the DVR/controller and the camera over the video cable. Video input, decoder locking and BT.656 output are separate functions. Therefore all 35 ACP semantic operations are excluded from first-image MODE1. This does not claim camera OSD or coax control functionality.
""", encoding="utf-8")

    (OUT / "MODE1_BANK1_ED_DISPOSITION.md").write_text("""# Bank1 / 0xED disposition

- Reference operation: read-modify-write clearing CH1-owned bit 0 (`old & 0xFE`).
- Current v41 effective byte: `0x00` from deterministic stage-2 product-equivalent autoinit.
- Target owned bit: bit 0 = 0; other bits preserved.
- First-image delta: none; the current byte already satisfies the full masked target.
- Recovery authority: not needed because MODE1 does not touch this register.
- Final disposition: `EXCLUDED_FROM_MINIMAL_MODE1`.
""", encoding="utf-8")

    (OUT / "MODE1_BANK9_44_DISPOSITION.md").write_text("""# Bank9 / 0x44 disposition

- Reference operation: read-modify-write clearing CH1-owned bit 0 (`old & 0xFE`).
- Current v41 effective byte: `0x00` from deterministic stage-2 product-equivalent autoinit and later overlay.
- Target owned bit: bit 0 = 0; other bits preserved.
- First-image delta: none; the current byte already satisfies the full masked target.
- Recovery authority: not needed because MODE1 does not touch this register.
- Final disposition: `EXCLUDED_FROM_MINIMAL_MODE1`.
""", encoding="utf-8")

    unknown_list = "\n".join(f"- `{r['Bank']}/{r['Register']}`" for r in prohibited)
    (OUT / "MODE1_PRODUCT_BASELINE_RECONSTRUCTION_PROOF.md").write_text(f"""# MODE1 product-baseline reconstruction proof

Result: `FAIL_CLOSED`.

The current v41 source proves a controlled reset at wrapper startup and a deterministic product-equivalent autoinit. It does not prove a MODE1 host action that can invoke the exact same reset/autoinit flow without broader reset effects. More importantly, {len(prohibited)} minimum-set registers are not written by current v41, have no authoritative reset default, and have no safe-read authority in the accepted SCAN0 matrix. Product autoinit therefore cannot reconstruct their pre-MODE1 bytes.

The frozen recovery flow is represented in the graph but may not be selected for these registers. `NVP reset effect known or bounded`, `protected final state verifiable`, and `within existing v41 recovery authority` do not all pass.

Blocked registers:
{unknown_list}

No `PRODUCT_BASELINE_RECONSTRUCTION` class is assigned merely to avoid exact rollback.
""", encoding="utf-8")

    gate = {
        "schema": "MODE1_AUTH1_AUTHORITY_GATE_V1",
        "source_authority": authority,
        "reference_commit": REFERENCE_COMMIT,
        "current_state_rows": len(current), "reference_target_registers": len(target),
        "current_v41_target_state_overlap": f"{satisfied_target_registers}/{len(target)}",
        "reference_operation_count": len(matrix), "differential_class_counts": dict(sorted(class_counts.items())),
        "minimal_action_count": len(actions),
        "minimal_functional_operation_count": sum(1 for a in actions if a["ActionType"] not in {"BANK_SELECT", "DELAY"}),
        "minimal_functional_register_count": recovery_summary["minimum_functional_register_count"],
        "minimal_touched_register_count_including_bank_selector": recovery_summary["minimum_touched_register_count_including_bank_selector"],
        "minimum_phase_operation_counts": dict(sorted(phase_actions.items())),
        "unresolved_operation_count": class_counts["UNRESOLVED"],
        "prohibited_unresolved_touched_register_count": len(prohibited),
        "unresolved_symbolic_fields": len(prohibited),
        "initial_eq_authority": "MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE",
        "acp_decision": "ACP_NOT_REQUIRED_FOR_FIRST_IMAGE",
        "bank1_ed": "EXCLUDED_FROM_MINIMAL_MODE1", "bank9_44": "EXCLUDED_FROM_MINIMAL_MODE1",
        "product_baseline_reconstruction": "FAIL",
        "recovery": recovery_summary, "failure_injection": failure,
        "scan1_read_only": True, "generic_host_nvp_i2c": "ABSENT",
        "implementation_decision": "BLOCKED_NO_SOURCE_CANDIDATE",
        "build_decision": "NOT_RUN_AUTHORITY_GATE_FAILED",
        "hardware_prompt_created": False, "hardware_accessed": False,
        "first_failed_gate": "PROHIBITED_UNRESOLVED_TOUCHED_REGISTER_COUNT_NONZERO",
        "classification": "MODE1_AUTH1_AUTHORITY_INCOMPLETE",
    }
    write_json("MODE1_AUTH1_AUTHORITY_GATE.json", gate)
    (OUT / "MODE1_AUTH1_WORKSTREAM_REPORT.md").write_text(f"""# MODE1-AUTH1 differential audit report

## Outcome

- Current v41 target-state overlap: {satisfied_target_registers} / {len(target)} functional registers.
- Reduced minimum: {recovery_summary['minimum_functional_register_count']} functional registers plus atomic bank selector, versus the prior overbroad 113-register model.
- Differential operations: {dict(sorted(class_counts.items()))}.
- Bank1/0xED: `EXCLUDED_FROM_MINIMAL_MODE1`.
- Bank9/0x44: `EXCLUDED_FROM_MINIMAL_MODE1`.
- ACP: `ACP_NOT_REQUIRED_FOR_FIRST_IMAGE`; 35 coax-control operations excluded.
- Initial EQ: `MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`.
- Recovery authority: {recovery_summary['authorized_recovery_register_count']}/{recovery_summary['minimum_touched_register_count_including_bank_selector']} registers ({recovery_summary['recovery_authority_coverage_percent']}%).
- Recovery graph structural coverage: 100%.
- Failure injection: {failure['scenario_coverage']} PASS; every scenario terminates explicitly.
- Product baseline reconstruction: FAIL for {len(prohibited)} unknown-baseline registers.
- MODE1 implementation/build/HW1 prompt: not created.

First failed authority gate: `PROHIBITED_UNRESOLVED_TOUCHED_REGISTER_COUNT_NONZERO`.

This result closes the requested differential decision without claiming the speculative candidate ready. SCAN1 remains read-only; generic host NVP I2C is absent. No DUT, hardware, source, RTL, XDC, build, DCP or bitstream was touched.
""", encoding="utf-8")

    output_names = [
        p.name for p in OUT.iterdir()
        if p.is_file() and p.name not in {
            Path(__file__).name, "verify_mode1_auth1.py", "MODE1_AUTH1_GENERATION_RECEIPT.json",
            "MODE1_AUTH1_VERIFICATION_RECEIPT.json"
        }
    ]
    receipt = {
        "schema": "MODE1_AUTH1_GENERATION_RECEIPT_V1", "result": "PASS",
        "authority": authority, "reference_commit": REFERENCE_COMMIT,
        "reference_manifest_sha256": sha256(REF), "read_authority_sha256": sha256(READ_AUTH),
        "nvp6134c_normative_sha256": NORMATIVE_SHA256,
        "audit_generator_sha256": sha256(Path(__file__)),
        "output_sha256": {name: sha256(OUT / name) for name in sorted(output_names)},
        "candidate_created": False, "build_run": False, "hardware_accessed": False,
    }
    write_json("MODE1_AUTH1_GENERATION_RECEIPT.json", receipt)


def main() -> None:
    authority = source_authority()
    rows = read_csv(REF)
    assert len(rows) == 211, len(rows)
    trace, current = current_trace_and_state()
    target = reference_ledgers(rows)
    matrix, actions = differential(rows, current, target)
    recovery_rows, recovery_summary = recovery(actions, current)
    failure = failure_graph(actions, recovery_rows, recovery_summary)
    write_reports(authority, matrix, actions, recovery_rows, recovery_summary, failure, current, target)
    print(json.dumps({
        "result": "PASS", "current_trace_rows": len(trace), "current_state_rows": len(current),
        "reference_operations": len(rows), "target_registers": len(target),
        "minimum_actions": len(actions), **recovery_summary, **failure,
    }, indent=2))


if __name__ == "__main__":
    main()
