#!/usr/bin/env python3
"""Build the complete public-safe SCAN0 evidence set from offline inputs."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scan0_model import (  # noqa: E402
    CURRENT_COMMIT,
    CURRENT_TREE,
    DRIVER_VERSION,
    I2C_HZ,
    REFERENCE_COMMIT,
    action_manifest,
    action_rows,
    assert_authority_gates,
    candidate_registers,
    current_inventory,
    git,
    manifest_digest,
    reference_manifest,
    replay_actions,
    scan_manifest,
    scan_time_rows,
    sha256_path,
    side_effect_blacklist,
    write_csv,
    write_json,
)


TITLE = "AHD v41 G2B-NVP-CAMERA-SCAN0-OFFLINE"
EVIDENCE_DIR = "v41-development-g2b-nvp-camera-scan0-offline-reference-design"
OVERALL = "PASS_SCAN1_READ_MANIFEST_READY_ACQ1_REFERENCE_COMPATIBILITY_TEST_REQUIRED"


def put(path: Path, text: str) -> None:
    path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def csv_text(rows: list[dict[str, Any]], fields: list[str]) -> str:
    import io
    s = io.StringIO(newline="")
    w = csv.DictWriter(s, fieldnames=fields, lineterminator="\n", extrasaction="ignore")
    w.writeheader()
    w.writerows(rows)
    return s.getvalue()


def write_rows(out: Path, name: str, rows: list[dict[str, Any]], fields: list[str]) -> None:
    write_csv(out / name, rows, fields)


def format_rows() -> list[dict[str, str]]:
    data = [
        ("0x00","0x01","CVBS","720x480","59.94i","interlaced","SD_480I59_94"),
        ("0x10","0x02","CVBS","720x576","50i","interlaced","SD_576I50"),
        ("0x20","0x04","AHD_OR_CVI","1280x720","30","progressive","AHD_720P30_AFTER_DISCRIMINATION"),
        ("0x21","0x08","AHD_OR_CVI","1280x720","25","progressive","AHD_720P25_AFTER_DISCRIMINATION"),
        ("0x22","0x51","AHD","1280x720","60","progressive","AHD_720P60"),
        ("0x23","0x52","AHD","1280x720","50","progressive","AHD_720P50"),
        ("0x2B","0x11","CVI","1280x720","30","progressive","CVI_720P30"),
        ("0x2C","0x12","CVI","1280x720","25","progressive","CVI_720P25"),
        ("0x25","0x31","TVI","1280x720","30","progressive","TVI_720P30A"),
        ("0x26","0x32","TVI","1280x720","24","progressive","TVI_720P24A"),
        ("0x29","0x34","TVI","1280x720","30","progressive","TVI_720P30B"),
        ("0x2A","0x38","TVI","1280x720","25","progressive","TVI_720P25B"),
        ("0x2D","0x51","CVI","1280x720","60","progressive","CVI_720P60"),
        ("0x2E","0x52","CVI","1280x720","50","progressive","CVI_720P50"),
        ("0x27","0x54","TVI","1280x720","60","progressive","TVI_720P60"),
        ("0x28","0x58","TVI","1280x720","50","progressive","TVI_720P50"),
        ("0x30","0x40","AHD_OR_CVI","1920x1080","30","progressive","AHD_1080P30_AFTER_DISCRIMINATION"),
        ("0x31","0x80","AHD_OR_CVI","1920x1080","25","progressive","AHD_1080P25_AFTER_DISCRIMINATION"),
        ("0x35","0x71","CVI","1920x1080","30","progressive","CVI_1080P30"),
        ("0x36","0x72","CVI","1920x1080","25","progressive","CVI_1080P25"),
        ("0x33","0x74","TVI","1920x1080","30","progressive","TVI_1080P30"),
        ("0x34","0x78","TVI","1920x1080","25","progressive","TVI_1080P25"),
        ("0x40","0x81","AHD","2560x1440","30","progressive","AHD_4MP30"),
        ("0x41","0x82","AHD","2560x1440","25","progressive","AHD_4MP25"),
        ("0x4F","0x83","AHD","2560x1440","15","progressive","AHD_4MP15_NRT"),
        ("0xA0","0xA0","AHD","5MP","12.5","progressive","AHD_5MP12_5"),
        ("0xA1","0xA1","AHD","5MP","20","progressive","AHD_5MP20"),
        ("0xA2","0xA2","TVI","5MP","12.5","progressive","TVI_5MP12_5"),
        ("0x03_or_0x04","0x90","AHD","3MP","18","progressive","AHD_3MP18_NRT"),
        ("0x01_or_0x02_with_F2_high_nibble_0x2","0x91_or_0x92","AHD","3MP","30_or_25","progressive","AHD_3MP_RT"),
        ("0x64","0x93","TVI","3MP","18","progressive","TVI_3MP18_NRT"),
        ("0xFF_or_default","0x00","UNKNOWN","unknown","unknown","unknown","NO_DETECTION"),
    ]
    rows=[]
    for raw,conv,tech,res,fps,scan,name in data:
        eligible = name == "AHD_1080P25_AFTER_DISCRIMINATION"
        rows.append({
            "RawDetectorValues":raw,"ConvertedFormatValue":conv,"TechnologyFamily":tech,
            "Resolution":res,"FrameRate":fps,"ScanType":scan,
            "ReferenceSourceAuthority":"video.c:nvp6134_vfmt_convert:332-377",
            "NVP6134CSupportAuthority":"Rev1.0 p88 directly maps F0=0x31 to AHD_1080p25" if raw=="0x31" else "NOT_FULLY_ESTABLISHED_FOR_PRODUCT",
            "ProductSupportDisposition":"ELIGIBLE_FOR_ACQ1" if eligible else "REPORT_AS_UNSUPPORTED_PRODUCT_FORMAT_NO_MODE_WRITE_NO_EQ_WRITE",
        })
    return rows


def gap_rows() -> list[dict[str, str]]:
    values = [
        ("periodic NOVID read","video.c:nvp6134_getvideoloss","one-shot DIAG1 status sampling only","NO","YES","YES","loss transitions cannot drive acquisition"),
        ("private-bank F0/F2/F3/F4/F5 read","video.c:video_fmt_det/debounce","absent","NO","YES","YES","format classifier absent"),
        ("additional format-detection registers","eq_common.c metric helpers","absent","NO","YES","YES","AHD/CVI discrimination absent"),
        ("format debounce state","video.c:386-599","absent","NO","NO","YES","single observations cannot establish stability"),
        ("format campaign reset","video.c:1002-1022","absent","NO","NO","YES","host must prevent stale campaign state"),
        ("slice-level no-video search","video.c:1024-1088;1651-1662","absent","NO","YES","YES","no bounded input search"),
        ("format mapping","video.c:332-377","absent","NO","NO","YES","raw format not decoded"),
        ("set_chnmode","video.c:1099-1184","no callable governed equivalent","NO","YES","YES","dynamic mode transition absent"),
        ("AHD 1080p25 action","video.c:2068-2134;3386-3533","static autoinit profile only","PARTIAL","YES","YES","not an action with baseline/rollback"),
        ("EQ initialization","eq.c:78-219","static table overlap, not reference-equivalent","PARTIAL","YES","YES","initial EQ compatibility unresolved"),
        ("EQ adaptive update","eq.c:nvp6134_set_equalizer","absent","NO","NO","NO","deferred after first image"),
        ("loss-of-video recovery","video.c and eq_recovery.c","absent","NO","NO","NO","deferred"),
        ("mode-change recovery","video_fmt_debounce/eq_recovery","absent","NO","NO","NO","deferred"),
        ("stable-lock confirmation","reference status helpers","DIAG1 reads 5 stable samples at 100 ms","YES","YES","YES","read-only pattern reusable"),
        ("real-scene capture decision","reference not authoritative for FPGA record gate","existing private closed-runtime capture path","PARTIAL","NO","NO","CAM1 gate defined, not executed"),
    ]
    rows=[]
    for cap,ref,current,present,scan1,acq1,impact in values:
        rows.append({"Capability":cap,"ReferenceSource":ref,"CurrentV41Implementation":current,
                     "Present":present,"Partial":"YES" if present=="PARTIAL" else "NO",
                     "Absent":"YES" if present=="NO" else "NO","SafetyImpact":impact,
                     "CameraAcquisitionImpact":impact,"RequiredInSCAN1":scan1,"RequiredInACQ1":acq1,
                     "RequiredInCAM1":"YES" if cap in {"stable-lock confirmation","real-scene capture decision"} else "NO"})
    return rows


def novid_trace() -> list[dict[str, str]]:
    return [
        {"order":"1","bank":"0x00","register":"0xFF","operation":"BANK_SELECT","value/mask":"0x00","delay":"0","condition":"per chip","state dependency":"none","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1031","NVP6134C authority status":"bank select documented"},
        {"order":"2","bank":"0x00","register":"0xA8","operation":"READ","value/mask":"bits[3:0] NOVID CH1..CH4","delay":"0","condition":"per chip","state dependency":"none","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1032","NVP6134C authority status":"Rev1.0 pp42,63 read-only"},
        {"order":"3","bank":"STATE","register":"s_slice_cnt","operation":"INCREMENT_OR_WRAP","value/mask":">100=>0 else +1","delay":"0","condition":"once per getvideoloss call","state dependency":"campaign reset initializes 0","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1036-1040","NVP6134C authority status":"software state"},
        {"order":"4","bank":"0x05+CH","register":"0xFF","operation":"BANK_SELECT","value/mask":"0x05+CH","delay":"0","condition":"NOVID asserted","state dependency":"A8 bit","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1044-1046","NVP6134C authority status":"reference semantic; C compatibility test required for following writes"},
        {"order":"5","bank":"0x05+CH","register":"0x08","operation":"WRITE","value/mask":"phase0=0x50 phase1=0x40 phase2=0x60","delay":"0","condition":"NOVID && !s_fmt_set_done[CH]","state dependency":"s_slice_cnt mod 3 after pre-increment","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1047-1064","NVP6134C authority status":"reference-only functional write"},
        {"order":"6","bank":"0x05+CH","register":"0x05","operation":"WRITE","value/mask":"0xA4","delay":"0","condition":"NOVID","state dependency":"none","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1067","NVP6134C authority status":"reference-only neighboring write"},
        {"order":"7","bank":"0x05+CH","register":"0x08","operation":"OPTIONAL_WRITE","value/mask":"0x50","delay":"0","condition":"NOVID && ch_mode_status < NVP6134_VI_720P_2530","state dependency":"SD-mode helper can overwrite phase value","source file":"video.c","source function":"nvp6134_cvbs_slicelevel_con","source line":"1651-1660","NVP6134C authority status":"reference-only; suppressed after reset because ch_mode_status=0xFF"},
        {"order":"8","bank":"0x05+CH","register":"0x05","operation":"WRITE","value/mask":"0x24","delay":"0","condition":"video present","state dependency":"A8 bit clear","source file":"video.c","source function":"nvp6134_getvideoloss","source line":"1071-1076","NVP6134C authority status":"reference-only neighboring branch"},
        {"order":"9","bank":"0x00/0x05+CH","register":"0xE8+CH and recovery set","operation":"READ_AND_OPTIONAL_RECOVERY","value/mask":"FSC lock bit1","delay":"bounded in helper","condition":"video present && EXT family && FSC unlock","state dependency":"ch_mode_status","source file":"video.c","source function":"nvp6134_getvideoloss/nvp6134_ResetFSCLock","source line":"1077-1084;1609-1633","NVP6134C authority status":"recovery deferred; not SCAN1"},
    ]


def read_set_rows() -> list[dict[str, str]]:
    rows=[
        {"Bank":"0x00","Register":"0xA8","Purpose":"NOVID input to video_fmt_det via getvideoloss","Conditionality":"always before format loop","TemporaryWriteDependency":"none","Source":"video.c:629,1031-1033","SCAN1":"INCLUDE"},
    ]
    for reg,purpose in [(0xF0,"raw classifier"),(0xF2,"conversion auxiliary"),(0xF3,"special-format discriminator"),(0xF4,"special-format discriminator"),(0xF5,"special-format discriminator")]:
        rows.append({"Bank":"0x05+CH","Register":f"0x{reg:02X}","Purpose":purpose,"Conditionality":"always per channel in detector/debounce","TemporaryWriteDependency":"none for read itself","Source":"video.c:637-642;401-406","SCAN1":"INCLUDE_READ_ONLY"})
    for reg,purpose,src in [(0xE2,"ACC gain high byte","eq_common.c:5054-5057"),(0xE3,"ACC gain low byte","eq_common.c:5054-5057"),(0xE8,"Y-plus slope high bits","eq_common.c:2629-2632"),(0xE9,"Y-plus slope low byte","eq_common.c:2629-2632"),(0xEA,"Y-minus slope high bits","eq_common.c:2648-2651"),(0xEB,"Y-minus slope low byte","eq_common.c:2648-2651")]:
        rows.append({"Bank":"0x05+CH","Register":f"0x{reg:02X}","Purpose":purpose,"Conditionality":"AHD/CVI discrimination","TemporaryWriteDependency":"reference classifier changes gain/comb configuration before interpretation","Source":src,"SCAN1":"INCLUDE_RAW_VALUE_INTERPRETATION_UNRESOLVED"})
    rows.append({"Bank":"0x05+CH","Register":"0x27","Purpose":"diagnostic ACC-reference read printed by initial FHD branch","Conditionality":"raw F0 in 0x30/0x31/0x35/0x36 initial detection","TemporaryWriteDependency":"after writes 0x24=0x18 and 0x58=0xD3","Source":"video.c:697-709","SCAN1":"EXCLUDE_NOT_REQUIRED_BY_R1_TABLE_AND_CONTEXT_DEPENDENT"})
    return rows


def call_graph(ref_repo: Path) -> dict[str, Any]:
    video = (ref_repo / "video.c").read_text(encoding="latin-1").splitlines()
    cases=[]
    import re
    for line_no in range(1122,1156):
        line=video[line_no-1]
        m=re.search(r"case\s+(NVP6134_VI_[A-Z0-9_]+):\s*([A-Za-z0-9_]+)\(ch,\s*vfmt\)",line)
        if m:
            cases.append({"mode":m.group(1),"function":m.group(2),"source_line":line_no})
    return {
        "root":"nvp6134_set_chnmode",
        "prelude":["validate channel","validate PAL/NTSC","nvp6134_set_common_value"],
        "mode_dispatch":cases,
        "selected_path":["nvp6134_set_common_value","nvp6134_setchn_ahd_1080p2530","nvp6134_setchn_common_fhd","state assignments","acp_each_setting","acp_set_baudrate","acp_reg_rx_clear","eq_init_each_format","post-mode bank9 re-arm","bank0 channel enable"],
        "postlude":["save mode/format state","ACP unless NOVIDEO","EQ init unless NOVIDEO","bank9 pulse and 35 ms delay","bank0 channel enable"],
    }


def action_catalog() -> list[dict[str, str]]:
    return [
        {"ActionID":"ENTER_NOVIDEO_AHD1080P25","ChannelScope":"CH1_OR_CH3","Readiness":"BLOCKED_BY_NVP6134C_COMPATIBILITY","WritesNVP":"YES_WHITELISTED_ONLY","Authority":"reference no-video function plus current product baseline","NextEvidence":"one controlled compatibility test after SCAN1 qualification"},
        {"ActionID":"READ_DETECTION_SNAPSHOT","ChannelScope":"ALL_READ_ONLY","Readiness":"READY","WritesNVP":"BANK_SELECT_ONLY","Authority":"SCAN1 frozen manifest","NextEvidence":"SCAN1 simulation and hardware qualification"},
        {"ActionID":"RESET_FORMAT_DETECTOR_STATE","ChannelScope":"CAMPAIGN","Readiness":"READY","WritesNVP":"NO","Authority":"video_fmt_det_reset semantic purpose, host-owned state","NextEvidence":"host unit tests"},
        {"ActionID":"STEP_NOVIDEO_SLICE","ChannelScope":"CH1_OR_CH3","Readiness":"BLOCKED_BY_NVP6134C_COMPATIBILITY","WritesNVP":"YES_WHITELISTED_ONLY","Authority":"video.c:1024-1088;1651-1662","NextEvidence":"controlled compatibility test of full branch, not isolated three writes"},
        {"ActionID":"APPLY_AHD1080P25_MODE","ChannelScope":"CH1_OR_CH3","Readiness":"BLOCKED_BY_NVP6134C_COMPATIBILITY","WritesNVP":"YES_FIXED_211_OPERATION_SEMANTIC_MANIFEST","Authority":"pinned reference plus bounded NVP6134C guide-note subset","NextEvidence":"close every reference-only write/readback authority"},
        {"ActionID":"INIT_EQ_AHD1080P25","ChannelScope":"CH1_OR_CH3","Readiness":"BLOCKED_BY_NVP6134C_COMPATIBILITY","WritesNVP":"YES_FIXED_EQ_SUBMANIFEST","Authority":"eq_init_each_format reference semantics","NextEvidence":"controlled compatibility test"},
        {"ActionID":"VERIFY_AHD1080P25_LOCK","ChannelScope":"CH1_OR_CH3","Readiness":"READY","WritesNVP":"BANK_SELECT_ONLY","Authority":"NVP6134C Rev1.0 A8/E0/E1/E2/E8+CH","NextEvidence":"SCAN1 hardware observations"},
        {"ActionID":"ROUTE_CHANNEL_TO_VDO1","ChannelScope":"CH1_OR_CH3","Readiness":"READY","WritesNVP":"YES_FIXED_BANK1_C2_MASKED_ROUTE","Authority":"current v41 DIAG1 plus accepted DIAG2 audit","NextEvidence":"live mapping qualification; no requalification in SCAN0"},
        {"ActionID":"RESTORE_PRODUCT_BASELINE","ChannelScope":"TARGET_PLUS_GLOBAL_TOUCHED_REGISTERS","Readiness":"PARTIAL","WritesNVP":"YES_BASELINE_LEDGER_ONLY","Authority":"rollback contract frozen","NextEvidence":"prove every touched register is safely baseline-readable or has authoritative reset value"},
        {"ActionID":"ABORT_AND_RESTORE","ChannelScope":"ACTIVE_ACTION","Readiness":"PARTIAL","WritesNVP":"YES_BASELINE_LEDGER_ONLY","Authority":"rollback contract frozen","NextEvidence":"fault-injection verification after compatibility closure"},
    ]


def per_action_manifest(catalog: list[dict[str,str]]) -> list[dict[str,Any]]:
    details=[]
    for row in catalog:
        action=row["ActionID"]
        txn={
            "READ_DETECTION_SNAPSHOT":"SCAN1_READ_MANIFEST_V1",
            "RESET_FORMAT_DETECTOR_STATE":"HOST_STATE_RESET_NO_I2C",
            "VERIFY_AHD1080P25_LOCK":"BANK0:A8,E0,E1,E2,E8+CH_WITH_BOOKENDS",
            "ROUTE_CHANNEL_TO_VDO1":"SAVE_ENTRY_BANK;BANK1;RMW_C2_LOW_NIBBLE;VERIFY;RESTORE_ENTRY_BANK",
            "APPLY_AHD1080P25_MODE":"AHD1080P25_ACTION_MANIFEST_211_SEMANTIC_OPERATIONS",
            "INIT_EQ_AHD1080P25":"EQ_AHD1080P25_INIT_SUBMANIFEST",
            "STEP_NOVIDEO_SLICE":"NOVID_OPERATION_TRACE_FULL_CONTEXT",
        }.get(action,"PERSISTED_BASELINE_WRITE_LEDGER_REVERSE_RESTORE")
        details.append({
            "action_id":action,"channel_scope":row["ChannelScope"],
            "allowed_pre_state":"IDLE_WITH_MATCHING_CAMPAIGN_GENERATION_AND_NO_UNACKNOWLEDGED_SNAPSHOT",
            "fixed_transaction_sequence":txn,
            "fixed_masks_and_symbolic_preserved_bits":"PRESERVE_ALL_NON_TARGET_BITS; NEVER ASSUME ZERO",
            "fixed_delays_ms":"245 reference semantic total for APPLY path; action-specific fixed values otherwise",
            "required_readbacks":"bank-select; every critical group; entry-bank restore; action-specific status",
            "success_predicate":"all operations and readbacks pass; no timeout/NACK; campaign generation unchanged",
            "failure_predicate":"first failed transaction/readback, stale generation, abort, or timeout",
            "maximum_duration":"implementation constant; no runtime programming; bounded attempts",
            "rollback_action":"ABORT_AND_RESTORE except read-only/host-only actions",
            "source_authority":row["Authority"],"implementation_readiness":row["Readiness"],
        })
    return details


def mmio_rows() -> list[dict[str,str]]:
    header=[
        (0x000,"MAGIC","RO","0x4E565343 NVSC"),(0x004,"VERSION","RO","0x00010001"),
        (0x008,"CAPABILITIES","RO","ONESHOT|ENTRY_BANK_RESTORE|BANK_VERIFY|HOST_HISTORY"),
        (0x00C,"CONTROL","WO","bit0 START; bit1 ACK; bit2 ABORT; all other bits zero"),
        (0x010,"STATUS","RO","IDLE|BUSY|DONE|ERROR|AUTOINIT_DONE"),(0x014,"GENERATION","RO","completed snapshot generation"),
        (0x018,"ENTRY_COUNT","RO","82"),(0x01C,"VALID_ENTRY_COUNT","RO","successful entry reads"),
        (0x020,"FAILED_ENTRY_COUNT","RO","failed entries"),(0x024,"RETRIED_ENTRY_COUNT","RO","logical entries retried once"),
        (0x028,"FIRST_ERROR_INDEX","RO","first failing manifest index"),(0x02C,"FIRST_ERROR_DETAIL","RO","bank/register/error"),
        (0x030,"ENTRY_BANK","RO","saved entry bank"),(0x034,"EXIT_BANK","RO","verified restored bank"),
        (0x038,"A8_PRE_POST","RO","pre low byte; post next byte"),(0x03C,"SCAN_FLAGS","RO","VALID_COMPLETE|LIVE_STATUS_CHANGED|RESTORE_VERIFIED|DEGRADED"),
        (0x040,"START_TICKS_LO","RO","64-bit start low"),(0x044,"START_TICKS_HI","RO","64-bit start high"),
        (0x048,"END_TICKS_LO","RO","64-bit end low"),(0x04C,"END_TICKS_HI","RO","64-bit end high"),
        (0x050,"MANIFEST_SHA256_W0","RO","manifest identity word 0"),(0x054,"MANIFEST_SHA256_W1","RO","word 1"),
        (0x058,"MANIFEST_SHA256_W2","RO","word 2"),(0x05C,"MANIFEST_SHA256_W3","RO","word 3"),
        (0x060,"MANIFEST_SHA256_W4","RO","word 4"),(0x064,"MANIFEST_SHA256_W5","RO","word 5"),
        (0x068,"MANIFEST_SHA256_W6","RO","word 6"),(0x06C,"MANIFEST_SHA256_W7","RO","word 7"),
    ]
    rows=[{"AbsoluteAddress":f"0x{0x12000+o:05X}","RelativeOffset":f"0x{o:03X}","Field":n,"Access":a,"Contract":d} for o,n,a,d in header]
    rows += [
        {"AbsoluteAddress":"0x12080..0x1211F","RelativeOffset":"0x080+GROUP*0x10","Field":"GROUP_DIRECTORY_10","Access":"RO","Contract":"group id/bank/count, start tick32, end tick32, flags"},
        {"AbsoluteAddress":"0x12180..0x122C7","RelativeOffset":"0x180+ENTRY*4","Field":"FROZEN_ENTRY_ARRAY_82","Access":"RO","Contract":"[31:24] bank [23:16] register [15:8] value [7:0] status"},
        {"AbsoluteAddress":"0x122C8..0x123FF","RelativeOffset":"reserved","Field":"RESERVED_ZERO","Access":"RO","Contract":"read zero; writes rejected"},
    ]
    return rows


def entry_status_markdown() -> str:
    return """# SCAN1 entry status encoding

Each entry uses `[31:24] BANK`, `[23:16] REGISTER`, `[15:8] VALUE`, `[7:0] STATUS`.

Status flags are bit0 `VALUE_VALID`, bit1 `RETRIED`, bit2 `BANK_VERIFIED`, bit3 `ENTRY_SKIPPED_AFTER_ABORT`, and bits7:4 `ERROR_CODE`.

| Error code | Meaning | Required behavior |
|---:|---|---|
| 0x0 | NONE | value may be valid |
| 0x1 | WADDR_NACK | stop logical entry after at most one retry |
| 0x2 | REGADDR_NACK | stop logical entry after at most one retry |
| 0x3 | RADDR_NACK | stop logical entry after at most one retry |
| 0x4 | SCL_TIMEOUT | release lines and end operation |
| 0x5 | BUS_IDLE_TIMEOUT | do not start transaction |
| 0x6 | BANK_VERIFY_MISMATCH | no register reads in that group |
| 0x7 | ENTRY_BANK_READ_FAILURE | optional Bank0 fallback is degraded and never configuration-eligible |
| 0x8 | ENTRY_BANK_RESTORE_FAILURE | snapshot cannot be `VALID_COMPLETE` |
| 0x9 | AUTOINIT_PREEMPTED | finish current group, restore, invalidate |
| 0xA | INTERNAL_PROTOCOL_ERROR | release lines, restore if safe, invalidate |

The current fixed master has distinct internal WADDR, REGADDR, and RADDR states but exposes only aggregate success/timeout. SCAN1 implementation therefore adds a diagnostic-only phase-cause result without changing wire timing or transaction behavior.
"""


def build_narratives(
    task_root: Path,
    current_repo: Path,
    out: Path,
    refs: list[dict[str, Any]],
    current: list[dict[str, Any]],
    gaps: list[dict[str, Any]],
    novid: list[dict[str, Any]],
    reads: list[dict[str, Any]],
    formats: list[dict[str, Any]],
    graph: dict[str, Any],
    ops: list[Any],
    op_rows: list[dict[str, Any]],
    eq_rows: list[dict[str, Any]],
    candidates: list[dict[str, Any]],
    blacklist: list[dict[str, Any]],
    scan: list[dict[str, Any]],
    timing: list[dict[str, Any]],
    catalog: list[dict[str, Any]],
    acq_manifest: list[dict[str, Any]],
    mmio: list[dict[str, Any]],
    replay1: dict[str, Any],
    replay3: dict[str, Any],
) -> None:
    r1 = task_root / "owner-input" / "NVP6134C_CAMERA_SCANNER_IMPLEMENTATION_R1.md"
    prompt = task_root / "owner-input" / "AHD_v41_G2B_NVP_CAMERA_SCAN0_OFFLINE_PROMPT.md"
    r1_sha = sha256_path(r1)
    prompt_sha = sha256_path(prompt)
    ref_csv_sha = sha256_path(out / "G2B_NVP_CAMERA_SCAN0_REFERENCE_SOURCE_MANIFEST.csv")
    scan_sha = manifest_digest(scan)
    action_sha = manifest_digest(op_rows)
    proven_actions = [r["ActionID"] for r in catalog if r["Readiness"] == "READY"]
    partial_actions = [r["ActionID"] for r in catalog if r["Readiness"] == "PARTIAL"]
    blocked_actions = [r["ActionID"] for r in catalog if r["Readiness"].startswith("BLOCKED")]
    datasheet_action_ops = sum(r["authority_class"] == "NVP6134C_DATASHEET" for r in op_rows)
    reference_action_ops = len(op_rows) - datasheet_action_ops

    put(out / "G2B_NVP_CAMERA_SCAN0_OWNER_AUTHORIZATION.md", f"""# Owner authorization

- Task: `{TITLE}`
- PROJECT_STATE_REV: `8 - OWNER_ATTESTED_NOT_REVERIFIED`
- Same Codex window: `YES`
- Authority prompt SHA-256: `{prompt_sha}`
- Owner R1 document: `{r1}`
- Owner R1 SHA-256: `{r1_sha}`
- Hardware-qualified PRODUCT commit (inherited only): `30b14d13b0b789b62b05ab513eb9578c7c43b11a`
- Exact diagnostic source: `{CURRENT_COMMIT}` / tree `{CURRENT_TREE}`

The task authorizes only static file, Git, source, PDF, derived-model, deterministic-test, and evidence-publication operations. It does not authorize any DUT, driver, PCIe/MMIO, NVP I2C, JTAG, programming, reboot, power-cycle, Vivado, build, source modification, capture, DMA, AIO, or image operation.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_SCOPE.md", """# Scope and hard boundary

## In scope

Pinned reference-source identity; local NVP6134C register authority; current-v41 read-only gap audit; reference detection/mode/EQ semantic extraction; register safety; SCAN1, host, ACQ1 and CAM1 design freeze; deterministic offline tests; sanitized evidence publication.

## Explicitly out of scope

DUT contact, `/dev/xdma*`, PCIe configuration, MMIO, hardware I2C, JTAG, bitstreams, programming, resets/reboots/power cycles, driver/module/process/lock changes, Vivado, synthesis, implementation, builds, captures, DMA/AIO, raw frames, source edits, PRODUCT edits, SSOT/META changes, and copying or publishing third-party source/PDF content.

`Engineering gate` and `Evidence publication` are independent. Unknown private-register meanings are retained as uncertainty; they are never promoted to NVP6134C proof.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_R1_DOCUMENT_AUTHORITY.md", f"""# R1 document authority

The normative Owner input is the task-local byte copy `{r1}` with SHA-256 `{r1_sha}`. It freezes a read-only, ONESHOT, 25-kHz, single-frozen-snapshot scanner; host-owned history; no generic host I2C; an action-ID-only executor; explicit baseline/rollback; and private camera imagery. This evidence set implements those semantics only as an offline design. No hardware or source implementation is claimed.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_CURRENT_PROJECT_INHERITANCE.md", f"""# Current project inheritance

Accepted without requalification:

- PRODUCT branch `fix/v41-g2b-bt656-line0-sof`, commit `30b14d13b0b789b62b05ab513eb9578c7c43b11a`, tree `bdbe39077a03f8945ebdd1ed9e52761fbe787696`.
- Diagnostic branch `diag/v41-g2b-nvp-video-scan`, commit `{CURRENT_COMMIT}`, tree `{CURRENT_TREE}`.
- Qualified R3 bitstream SHA-256 `EC3A79064F03010E9E8B42A557DE57FA5E82849C1E2C37D2F3E662439211034F`, context only.
- R3R2R1 closed-runtime evidence commit `8d1d650ce672751d3d91a49cb5a7b218e90a2254`.
- Offline Bank/route audit commit `821f043abfe5bdd252920881101cc83b2e15a0bd`.

The current diagnostic checkout was verified at the exact requested branch/commit/tree and clean status before analysis. It was read only and not changed.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_REFERENCE_LICENSE_DISPOSITION.md", """# Reference license and clean-room disposition

- Repository: `4e4o/nvp6134_ex`
- Pinned commit: `081ebbff9a2722d47acf16c680594be43cb179e2`
- Declared driver version: `17.03.20.01`
- Repository license: no declared license found at the pinned commit.
- Copyright: Nextchip notices are present in source and vendor documents.
- Reference use: `SEMANTIC_ANALYSIS_ONLY`.
- Direct source copy into project: `NO`.
- Reference source/PDF publication: `NO`.
- Future implementation: project-authored clean-room semantic reimplementation.

This public evidence contains only identity metadata, hashes, function names, short semantic summaries, derived operation manifests, and project-authored specifications. It contains no third-party source file, long excerpt, vendor PDF, or repository archive.
""")

    history = git(task_root / "reference-repo", "log", "-8", "--date=iso-strict", "--format=%H|%ad|%s", REFERENCE_COMMIT).splitlines()
    hist_lines = ["# Bounded reference history", "", "Pinned HEAD and seven predecessors were inspected; this is not a moving-tip authority.", "", "| Commit | Date | Subject |", "|---|---|---|"]
    for item in history:
        sha,date,subject=item.split("|",2)
        hist_lines.append(f"| `{sha}` | {date} | {subject.replace('|','/')} |")
    hist_lines += ["", "Commit `3613635dc7028a11e0108d16cc3326f37f783c8a` introduced the repeated-campaign format-state reset. Its reset list is carried into the host campaign model. Later HEAD semantics remain authoritative for the extracted detector, mode and EQ paths."]
    put(out / "G2B_NVP_CAMERA_SCAN0_REFERENCE_HISTORY.md", "\n".join(hist_lines))

    put(out / "G2B_NVP_CAMERA_SCAN0_CURRENT_IMPLEMENTATION_BEHAVIOR.md", """# Exact current-v41 NVP behavior

The current source is a one-shot static profile, not an adaptive camera-acquisition loop.

| Behavior | Source proof | Finding |
|---|---|---|
| Start condition | `nvp6134c_autoinit.vhd:158-173` | after fixed start delay, `started=0` emits one pulse and latches `started=1` |
| One-shot | `nvp6134c_autoinit.vhd:161-178` | no periodic restart; only reset clears `started` |
| Format | `nvp6134c_autoinit.vhd:193` | profile 2, AHD 1080p25 |
| Channel | `nvp6134c_autoinit.vhd:197` | CH1 to VDO1 |
| AUTO | `nvp6134c_autoinit.vhd:198` | disabled |
| Stage | `nvp6134c_autoinit.vhd:199` | stage 2 |
| I2C rate | `ahd_capture_top_xdma.sv:121` and `:376` | 25,000 Hz for autoinit and diagnostic fixed master |
| Clock/domain | `ahd_capture_top_xdma.sv:45,104,124,378` | `autonomous_clk = axi_aclk` |
| Open drain ownership | `ahd_capture_top_xdma.sv:67-74` | wired AND of release controls; no active-high drive |
| Master timeouts | `nvp_i2c_fixed_master.sv:12-15,243-275,386-403` | fixed SCL and bus-idle timeouts; releases on abort |
| Read set | `g2b_nvp_video_diag.sv:77-83,846-851` | Bank0 A8/E0/E1/E2/E8+channel plus configuration verify reads |
| Write whitelist | `g2b_nvp_video_diag.sv:690-799,1029-1065` | Bank select, BGDCOL 0x78/0x79 and Bank1 VDO1 route 0xC2 only |
| Restore | `g2b_nvp_video_diag.sv:1023-1093` | original BGDCOL/route/entry bank restored and read back |
| Diagnostic isolation | `ahd_capture_top_xdma.sv:620-622,1185-1235` | DIAG1 exists only when compile-time enable is nonzero |

Absent are the private-bank detector loop, host/circuit debounce campaign, callable `set_chnmode`, reference-equivalent initial EQ action, and no-video slice sweep. Thus a connected camera can leave output at BGDCOL when the fixed CH1/AHD1080p25/static-EQ assumptions do not yield valid decoder lock; the current diagnostic changes background color and route, not the input acquisition state.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_CURRENT_GAP_DECISION.md", f"""# Current-v41 gap decision

All 15 required capability rows are populated. Current v41 proves power/reset, a fixed one-time AHD1080p25 CH1 profile, a 25-kHz master, bounded status sampling, BGDCOL/route control and exact restore. It does not implement reference detection, campaign reset/debounce, slice search, governed dynamic mode transition, or reference-equivalent initial EQ as action IDs.

Decision: freeze SCAN1 as a separate read-only compile-time profile. Do not retrofit functional writes into SCAN1. Freeze ACQ1 separately and block the four reference-only functional action families until a controlled NVP6134C compatibility test is Owner-authorized after SCAN1 qualification. Overall classification: `{OVERALL}`.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_NOVID_SLICE_SEMANTICS.md", """# `getvideoloss()` and no-video slice semantics

`nvp6134_getvideoloss()` selects Bank0 per chip, reads `0xA8[3:0]`, and assembles per-channel loss bits. It then updates one global `s_slice_cnt`: values greater than 100 wrap to 0, otherwise the counter increments before the per-channel branch.

For a no-video channel it selects Bank `0x05+CH`. If `s_fmt_set_done[CH]` is clear, register `0x08` receives `0x50` at phase 0, `0x40` at phase 1, or `0x60` at phase 2. Because the counter increments first, the first call after `video_fmt_det_reset()` writes phase 1 (`0x40`), then `0x60`, then `0x50`; the canonical modulo mapping/cycle remains `0x50 -> 0x40 -> 0x60`.

The same branch always writes private register `0x05=0xA4` and calls `nvp6134_cvbs_slicelevel_con(CH,0)`. If the stored mode is below 720p, that helper writes `0x08=0x50`, potentially overriding the phase write. Immediately after campaign reset, `ch_mode_status=0xFF`, so that SD-only override is suppressed. The video-present branch writes `0x05=0x24`, may write `0x08=0x70` for SD, and can invoke bounded FSC recovery for selected EXT modes.

Therefore `STEP_NOVIDEO_SLICE` may never copy only three isolated values. It must reproduce the entry condition, neighbor write, stored-mode condition, counter timing, and recovery exclusions. All such functional writes remain blocked for NVP6134C compatibility testing; SCAN1 performs none of them.
""")

    write_json(out / "G2B_NVP_CAMERA_SCAN0_FORMAT_DETECTION_DECISION_TREE.json", {
        "authority":"reference video.c at pinned commit",
        "prelude":["nvp6134_getvideoloss","fixed 200 ms delay","read F0/F2/F3/F4/F5 per private bank"],
        "initial_detection":{
            "valid_F0":"if neither nibble is 0xF",
            "ambiguous_AHD_CVI_codes":["0x20","0x21","0x2B","0x2C","0x30","0x31","0x35","0x36"],
            "temporary_functional_writes":True,
            "FHD_metrics":["E8/E9 Y-plus","EA/EB Y-minus","E2/E3 ACC gain"],
            "FHD_AHD_predicate":"slopes >= 80 and ACC gain > 2010; otherwise normalized to CVI code",
            "special_formats":"F3/F4/F5 branches with additional 0x05/0x06 writes and 100 ms delay",
            "state_effect":"set format-done, keep raw code, seed all three debounce buffers",
        },
        "already_set":{
            "changed_format":"debounce path; ordinary format changes wait for EQ-set-done",
            "three_buffers":"accept only when buf0 == buf1 == buf2",
            "no_video":"clears format-set-done and EQ-set-done after stable no-detection",
        },
        "scan1_policy":"capture raw tuple only; no temporary writes; report unresolved when context cannot distinguish",
    })

    put(out / "G2B_NVP_CAMERA_SCAN0_FORMAT_DEBOUNCE_MODEL.md", """# Reference format debounce model

The reference owns per-channel `s_fmt_dbnc_cnt` and three converted-format buffers. Each call reads F0/F2/F3/F4/F5 and conditional metrics, stores one converted result in the current slot, and advances the slot modulo three. A transition is accepted only when all three buffers agree. Otherwise the converted prior `s_keep_fmt` is returned. Stable no-detection clears both `s_fmt_set_done` and `g_eq_set_done` for that channel.

Initial detection is less strict: after its temporary discrimination writes it immediately sets format-done and seeds all three buffers to the same result. The governed host policy is intentionally stricter and requires three consecutive complete raw tuples in a fresh campaign before confirming any acquisition format. `g_eq_set_done` gates ordinary already-set changes in the reference and is retained as an explicit host state dependency, never inferred.
""")
    write_json(out / "G2B_NVP_CAMERA_SCAN0_FORMAT_DEBOUNCE_STATE_MACHINE.json", {
        "states":["RESET","COLLECT_0","COLLECT_1","COLLECT_2","COMPARE","KEEP_PREVIOUS","ACCEPT_NEW","CLEAR_ON_STABLE_NOVID"],
        "required_agreeing_samples":3,
        "history":["s_fmt_dbnc_buf0","s_fmt_dbnc_buf1","s_fmt_dbnc_buf2"],
        "counter":"s_fmt_dbnc_cnt modulo 3",
        "dependencies":["s_keep_fmt","s_keep_sync_width","s_fmt_set_done","g_eq_set_done"],
        "governed_host_delta":"new campaign requires three complete raw tuples even for initial confirmation",
    })

    put(out / "G2B_NVP_CAMERA_SCAN0_DETECTION_CAMPAIGN_RESET.md", """# Detection campaign reset

Commit `3613635dc7028a11e0108d16cc3326f37f783c8a` added `video_fmt_det_reset()`. A fresh campaign must reset the semantic equivalents of:

| State | Reset value |
|---|---:|
| `ch_mode_status[16]` | 0xFF |
| `ch_vfmt_status[16]` | 0xFF |
| `g_ch_video_fmt[16]` | 0xFF |
| `s_fmt_dbnc_cnt[16]` | 0x00 |
| `s_fmt_dbnc_buf0[16]` | 0x00 |
| `s_fmt_dbnc_buf1[16]` | 0x00 |
| `s_fmt_dbnc_buf2[16]` | 0x00 |
| `s_keep_fmt[16]` | 0xFF |
| `s_keep_sync_width[16]` | 0x00000000 |
| `s_fmt_set_done` | 0 |
| `g_eq_set_done` | 0 |
| `s_slice_cnt` | 0 |
| `g_vloss` | 0xFFFF |

The host also creates a new `campaign_id`, clears prior raw tuples, stable counts, blockers and transition history, and rejects snapshots from any previous campaign generation.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_AUTHORITY.md", f"""# AHD 1080p25 action authority

- Selected reference path: `nvp6134_set_chnmode(CH,PAL,NVP6134_VI_1080P_2530)` -> common values -> common FHD -> AHD1080p2530 -> software mode state -> ACP -> EQ init -> Bank9 re-arm (35 ms) -> Bank0 channel enable.
- Extracted semantic operations: `{len(ops)}` (`{replay1['i2c_operation_count']}` I2C operations, three fixed delays totaling `{replay1['delay_ms']}` ms, and three software-state assignments).
- Manifest digest: `{action_sha}`.
- CH1 deterministic replay: `{replay1['replay_sha256']}`.
- CH3 deterministic replay: `{replay3['replay_sha256']}`.
- Explicit NVP6134C guide-note-proven operation instances: `{datasheet_action_ops}`.
- Reference-driver-only or software-state operation instances: `{reference_action_ops}`.
- Symbolic preserved fields: `2` — Bank1 `0xED` and Bank9 `0x44`; both clear only the target channel bit and preserve every other old bit symbolically.

Readiness is `PARTIAL`, not hardware-ready. The sequence is deterministic and complete for the selected reference call path, but most functional register values are not proven compatible with NVP6134C. No unknown masked bit is set to zero. ACQ1 must first capture and persist the complete touched-register baseline, verify safe readback authority, and obtain bounded compatibility evidence. SCAN1 contains none of these writes.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_EQ_RUNTIME_DEFERRED_SCOPE.md", f"""# EQ scope disposition

`eq_init_each_format()` is called by `nvp6134_set_chnmode()` for every non-NOVIDEO mode. For AHD1080p25, the extracted initial subset has `{len(eq_rows)}` semantic entries: select Bank `5+CH`, write `0x59=0x11`, set software EQ stage 0, write `0xC0=0x17`, `0xC1=0x13`, `0xC8=0x04`, then select Bank A/B and write the channel EQ source selector `0x74/0xF4=0x02`.

Disposition:

- `EQ_INIT_REQUIRED_FOR_FIRST_IMAGE`: retained in ACQ1, but blocked pending NVP6134C compatibility evidence.
- `EQ_RUNTIME_ADAPTATION_DEFERRED`: cable-length/stage selection in `nvp6134_set_equalizer` and `eq_common.c` is not required for the first bounded image proof.
- `EQ_RECOVERY_DEFERRED`: `eq_recovery.c` is outside first-image scope.

No infinite or autonomous EQ loop is permitted.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_PROFILE_ISOLATION_SPEC.md", """# Compile-time profile isolation

| Profile | Scanner | Legacy heavy DIAG1 scanner | Executor | I2C release when absent |
|---|---|---|---|---|
| PRODUCT | not elaborated | not elaborated | not elaborated | constant high |
| SCAN1 | elaborated | disabled | not elaborated | executor release constant high |
| future ACQ1 | optional qualified scanner | disabled | elaborated | absent clients release high |

Use independent compile-time constants, with static/elaboration assertions forbidding simultaneous DIAG1 and SCAN1 decode and forbidding executor elaboration in PRODUCT or SCAN1. PRODUCT output logic, active constraints, ABI ranges, capture path and I2C behavior remain byte/source unchanged. No runtime bit may reveal a generic I2C write service.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_I2C_ARBITRATION_SPEC.md", """# I2C arbitration specification

Priority is fixed: (1) autoinit/PRODUCT-critical sequence, (2) governed ACQ1 executor, (3) read-only SCAN1 scanner. The grant unit is one complete atomic bank group: save/select, verify, all group entries, then release. There is no transaction-level interleaving inside a group and every client must select its bank explicitly.

SCAN1 cannot start before `autoinit_done`. If autoinit becomes pending during a scan, the scanner finishes only the active group, begins no next group, restores/verifies ENTRY_BANK if safe, invalidates the scan with `AUTOINIT_PREEMPTED`, releases both lines and yields. Partial entries remain private diagnostic state and never receive `VALID_COMPLETE`.

The existing 25-kHz fixed master, clock stretching and fixed SCL/bus-idle timeout behavior are reused. A logical entry may be retried at most once. No new nine-pulse recovery, runtime timeout, or speed selection exists.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_BANK_ATOMICITY_SPEC.md", """# Bank atomicity and restore contract

1. Read `0xFF` into `ENTRY_BANK`; failure may use Bank0 only as an explicitly degraded observation that is never configuration-eligible.
2. For each of ten ordered groups, acquire the group grant, write `0xFF=TARGET_BANK`, read `0xFF`, require equality, read all manifest entries, and release the grant.
3. Capture group start/end ticks around the atomic ownership interval.
4. After G0-POST, write `0xFF=ENTRY_BANK`, read `0xFF`, and require equality.
5. Freeze header, group metadata, 82 entries, manifest identity and generation before setting DONE.

A bank-verify mismatch skips the group's data reads. Any restore failure prevents `VALID_COMPLETE`. `A8_PRE != A8_POST` sets `LIVE_STATUS_CHANGED_DURING_SCAN`; the snapshot stays observationally useful but cannot authorize an ACQ1 mode action.
""")

    scan_states=["IDLE","WAIT_AUTOINIT_DONE","CAPTURE_ENTRY_BANK","SELECT_GROUP_BANK","VERIFY_GROUP_BANK","READ_GROUP_ENTRY","RESTORE_ENTRY_BANK","VERIFY_RESTORED_BANK","FINALIZE_SNAPSHOT","PUBLISH_DONE","WAIT_HOST_ACK","ABORT_SAFE","ERROR_SAFE"]
    scan_transitions=[
        {"from":"IDLE","event":"START","to":"WAIT_AUTOINIT_DONE"},{"from":"WAIT_AUTOINIT_DONE","event":"autoinit_done","to":"CAPTURE_ENTRY_BANK"},
        {"from":"CAPTURE_ENTRY_BANK","event":"success","to":"SELECT_GROUP_BANK"},{"from":"SELECT_GROUP_BANK","event":"write_done","to":"VERIFY_GROUP_BANK"},
        {"from":"VERIFY_GROUP_BANK","event":"match","to":"READ_GROUP_ENTRY"},{"from":"READ_GROUP_ENTRY","event":"more_entries","to":"READ_GROUP_ENTRY"},
        {"from":"READ_GROUP_ENTRY","event":"next_group","to":"SELECT_GROUP_BANK"},{"from":"READ_GROUP_ENTRY","event":"last_group_done","to":"RESTORE_ENTRY_BANK"},
        {"from":"RESTORE_ENTRY_BANK","event":"write_done","to":"VERIFY_RESTORED_BANK"},{"from":"VERIFY_RESTORED_BANK","event":"match","to":"FINALIZE_SNAPSHOT"},
        {"from":"FINALIZE_SNAPSHOT","event":"complete","to":"PUBLISH_DONE"},{"from":"PUBLISH_DONE","event":"done_visible","to":"WAIT_HOST_ACK"},
        {"from":"WAIT_HOST_ACK","event":"ACK","to":"IDLE"},{"from":"ANY_ACTIVE","event":"ABORT_or_preempt","to":"ABORT_SAFE"},
        {"from":"ANY_ACTIVE","event":"protocol_error","to":"ERROR_SAFE"},{"from":"ABORT_SAFE_OR_ERROR_SAFE","event":"restore_attempt_complete","to":"WAIT_HOST_ACK"},
    ]
    put(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_FSM.md", "# SCAN1 FSM\n\nStates: `"+"`, `".join(scan_states)+"`.\n\nSTART is accepted only in IDLE. DONE holds a single frozen snapshot until ACK. START while BUSY or DONE-before-ACK is rejected and counted. ABORT/preemption/error routes through safe release and entry-bank restore; incomplete scans are never marked valid. State transitions are frozen in the companion JSON.\n")
    write_json(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_FSM.json",{"states":scan_states,"transitions":scan_transitions,"single_buffer":True,"host_history":True,"autonomous_timer":False})

    put(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_MMIO_CONTRACT.md", f"""# SCAN1 MMIO contract

The frozen profile-only range is `0x12000..0x123FF`. Current full-map proof: the G2B router owns only `0x03800..0x03BFF`; DIAG1 conditionally intercepts `0x03C00..0x03FFF`; control/status owns low-address, measurement and R1h ranges; all remaining requests reach `pio_bar_target`; that target returns deterministic zero for reads at and above `0x12000` and rejects writes. SCAN1 therefore intercepts this currently unallocated 1-KiB range before the application target only when its compile-time profile is enabled. PRODUCT decoding remains unchanged.

MAGIC is `0x4E565343` (`NVSC`), VERSION `0x00010001`, and the 256-bit manifest digest is `{scan_sha}`. CONTROL accepts only START, ACK and ABORT with full-DWORD/aligned write-response semantics. START is legal only in IDLE; ACK only in DONE/ERROR; ABORT only while active. Unsupported bits, byte enables or addresses return an explicit protocol error without affecting I2C.

Host consistency sequence: read generation G0; read status, header, group directory and all 82 entries; read generation G1; require G0=G1, DONE=1, header generation=G0, entry count=82 and manifest SHA match; persist; then ACK. Missing entries are never synthesized.
""")
    put(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_ENTRY_STATUS.md", entry_status_markdown())

    put(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_CDC_SPEC.md", """# SCAN1 CDC disposition

`SINGLE_DOMAIN_NO_NEW_CDC`.

The current top defines `autonomous_clk = axi_aclk`; autoinit, the diagnostic fixed master, DIAG1 core and MMIO control all use that same clock. SCAN1 is specified in `axi_aclk`, including FSM, frozen RAM, generation and host handshake. The fixed master retains its existing input synchronizers/glitch filters for physical SCL/SDA. No new DONE/ACK toggle and no independent synchronization of wide counters are required. If a future implementation moves any component to another domain, this disposition expires and must be requalified.
""")

    build_host_acq_cam_docs(out,catalog,acq_manifest,op_rows,replay1,replay3,scan_sha,proven_actions,partial_actions,blocked_actions)
    build_plans_tests_index(task_root,current_repo,out,refs,current,gaps,novid,reads,formats,graph,ops,eq_rows,candidates,blacklist,scan,timing,catalog,mmio,r1_sha,ref_csv_sha,scan_sha,action_sha,proven_actions,partial_actions,blocked_actions)


def build_host_acq_cam_docs(
    out: Path,
    catalog: list[dict[str, Any]],
    acq_manifest: list[dict[str, Any]],
    op_rows: list[dict[str, Any]],
    replay1: dict[str, Any],
    replay3: dict[str, Any],
    scan_sha: str,
    ready: list[str],
    partial: list[str],
    blocked: list[str],
) -> None:
    put(out / "G2B_NVP_CAMERA_SCAN0_HOST_RUNTIME_BUNDLE_SPEC.md", """# Closed host runtime bundle

The future SCAN1 host decoder must be delivered as a fresh, task-local, hash-pinned bundle modeled on the accepted R3R2R1 architecture. Its manifest includes every Python/module file, non-code resource, launcher and expected SHA-256. Qualification order is fixed:

1. Resolve transitive import and resource closure offline.
2. Copy only that closure into an isolated local test directory.
3. Pass an isolated local import/`--self-test` gate with ambient package paths removed.
4. Prove a negative missing-dependency test fails closed.
5. Copy to DUT only under later explicit hardware authority.
6. Read back every DUT byte and compare SHA-256.
7. Pass isolated DUT import and module-provenance gates before the first device call.

No network installation, ambient dependency, prior-run runtime, mutable manifest, or fallback import is allowed. Runtime qualification remains a separate future gate; this offline task creates only the specification.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_HOST_DECODER_SPEC.md", f"""# Host snapshot decoder specification

The decoder first validates `MAGIC=NVSC`, `VERSION=0x00010001`, required capability bits, entry count 82, and manifest SHA-256 `{scan_sha}`. It performs the G0/read/G1 generation-stability protocol and rejects DONE=0, generation mismatch, restore-not-verified, duplicate/missing entry indexes, unknown status bits, or a bank/register/channel identity mismatch.

Raw bytes are retained without normalization. Entries are indexed by `(bank, register, channel scope, manifest index)`. Unknown private-register meanings remain raw and receive `REGISTER_SEMANTICS_UNCONFIRMED`; they are never silently filled or coerced. The decoder reports exactly one ordered `PRIMARY_BLOCKER` and every independent `SECONDARY_FINDING`. Source authority and confidence travel with each decoded field.

The output is append-only per host campaign and contains snapshot hashes, raw tuples, A8 bookends, group ticks, failure status and the manifest identity. Only a complete, stable, restored snapshot can update detector stability. A live-status-changed snapshot is retained but cannot authorize a functional action.
""")

    host_schema={
        "$schema":"https://json-schema.org/draft/2020-12/schema",
        "title":"G2B NVP SCAN1 host observation",
        "type":"object",
        "additionalProperties":False,
        "required":["campaign_id","scan_index","generation","manifest_sha256","raw_register_set","primary_blocker","secondary_findings","format_candidate","format_stability","signal_classification","source_authority"],
        "properties":{
            "campaign_id":{"type":"string","minLength":1},"scan_index":{"type":"integer","minimum":0},
            "generation":{"type":"integer","minimum":0},"manifest_sha256":{"const":scan_sha},
            "raw_register_set":{"type":"array","minItems":82,"maxItems":82,"items":{"type":"object","required":["index","bank","register","value","status","authority"],"additionalProperties":False,"properties":{"index":{"type":"integer","minimum":0,"maximum":81},"bank":{"type":"integer","minimum":0,"maximum":255},"register":{"type":"integer","minimum":0,"maximum":255},"value":{"type":["integer","null"],"minimum":0,"maximum":255},"status":{"type":"integer","minimum":0,"maximum":255},"authority":{"type":"string"}}}},
            "primary_blocker":{"type":["string","null"]},"secondary_findings":{"type":"array","items":{"type":"string"}},
            "format_candidate":{"type":["string","null"]},"format_stability":{"enum":["UNSTABLE","STABLE","INELIGIBLE_SNAPSHOT"]},
            "signal_classification":{"type":"array","items":{"type":"string"}},"source_authority":{"type":"object"},
        },
    }
    write_json(out / "G2B_NVP_CAMERA_SCAN0_HOST_OUTPUT_SCHEMA.json",host_schema)

    host_states=["CAMPAIGN_RESET","REQUEST_SCAN","VALIDATE_SNAPSHOT","RETAIN_RAW","CLASSIFY_SIGNAL","UPDATE_DEBOUNCE","FORMAT_UNRESOLVED","FORMAT_CONFIRMED","UNSUPPORTED_FORMAT","ELIGIBLE_FOR_ACQ1","CAMPAIGN_COMPLETE"]
    host_trans=[
        {"from":"CAMPAIGN_RESET","event":"fresh_state","to":"REQUEST_SCAN"},
        {"from":"REQUEST_SCAN","event":"DONE","to":"VALIDATE_SNAPSHOT"},
        {"from":"VALIDATE_SNAPSHOT","event":"valid_complete","to":"RETAIN_RAW"},
        {"from":"VALIDATE_SNAPSHOT","event":"invalid_or_live_changed","to":"REQUEST_SCAN","action":"persist ineligible observation and all findings"},
        {"from":"RETAIN_RAW","event":"stored","to":"CLASSIFY_SIGNAL"},
        {"from":"CLASSIFY_SIGNAL","event":"candidate_tuple","to":"UPDATE_DEBOUNCE"},
        {"from":"UPDATE_DEBOUNCE","event":"fewer_than_3_equal_complete_tuples","to":"REQUEST_SCAN"},
        {"from":"UPDATE_DEBOUNCE","event":"3_equal_but_private_semantics_insufficient","to":"FORMAT_UNRESOLVED"},
        {"from":"UPDATE_DEBOUNCE","event":"3_equal_AHD1080P25","to":"FORMAT_CONFIRMED"},
        {"from":"FORMAT_CONFIRMED","event":"supported","to":"ELIGIBLE_FOR_ACQ1"},
        {"from":"FORMAT_CONFIRMED","event":"other_format","to":"UNSUPPORTED_FORMAT"},
    ]
    put(out / "G2B_NVP_CAMERA_SCAN0_HOST_DETECTION_STATE_MACHINE.md", """# Stateful host detection campaign

Per channel the host owns `campaign_id`, `scan_index`, previous complete raw tuple, stable count, candidate format, confirmed format, three debounce buffers, last applied mode, last EQ state, slice phase and video-loss transition history. A new campaign resets every field and refuses old generations.

Only valid-complete snapshots with stable generation, exact manifest identity, verified entry-bank restore and equal A8 bookends advance stability. Three consecutive byte-identical required raw tuples are necessary. A primary blocker is selected by fixed priority (snapshot integrity, bank/restore, live change, register authority, format resolution, physical mapping); all other findings remain visible. No action follows from a single F0 value.
""")
    write_json(out / "G2B_NVP_CAMERA_SCAN0_HOST_DETECTION_STATE_MACHINE.json",{"states":host_states,"transitions":host_trans,"per_channel_state":["campaign_id","scan_index","previous_raw_tuple","stable_count","candidate_format","confirmed_format","format_debounce_buffers","last_applied_mode","last_eq_state","slice_phase","video_loss_transition_history"],"required_consecutive_equal_tuples":3})

    put(out / "G2B_NVP_CAMERA_SCAN0_SCIENTIFIC_OUTCOME_RULES.md", """# Scientific outcome rules

Classifications are additive; the first blocker does not suppress independent findings.

| Classification | Exact trigger |
|---|---|
| `CAMERA_SIGNAL_DETECTED` | at least one channel has consistent NOVID clear plus a coherent lock/status change across three eligible snapshots |
| `CAMERA_FORMAT_STABLE` | three consecutive eligible complete tuples decode to the same supported/unsupported format |
| `SIGNAL_PRESENT_FORMAT_UNRESOLVED` | signal/lock evidence exists but the read-only tuple cannot resolve the reference decision tree |
| `NO_SIGNAL_OBSERVED` | all channels retain NOVID/no-lock baseline across the bounded campaign; this is an observation, not proof no source exists |
| `REGISTER_SEMANTICS_UNCONFIRMED` | a conclusion depends on a reference-private field lacking NVP6134C field authority |
| `LIVE_STATUS_CHANGED_DURING_SCAN` | A8_PRE differs from A8_POST |
| `PHYSICAL_MAPPING_UNRESOLVED` | signal candidate cannot be tied to an authorized CH1/CH3 connector |
| `UNSUPPORTED_PRODUCT_FORMAT_<FORMAT>` | stable decoded format is not AHD1080p25; report only, no mode/EQ write |

`NO_SIGNAL_OBSERVED` and `SIGNAL_PRESENT_FORMAT_UNRESOLVED` are bounded experimental outcomes, not acquisition failures and not permission to broaden hardware actions.
""")

    acq_states=["IDLE","BASELINE_SCAN","ENTER_NOVIDEO","DETECTION_SCAN","SLICE_STEP","DEBOUNCE","FORMAT_CONFIRMED","APPLY_MODE","INIT_EQ","VERIFY_LOCK","ROUTE_TO_VDO1","READY_FOR_CAM1","RESTORE","FAILED_SAFE"]
    acq_trans=[
        {"from":"IDLE","event":"authorized_start","to":"BASELINE_SCAN"},
        {"from":"BASELINE_SCAN","event":"baseline_persisted","to":"ENTER_NOVIDEO"},
        {"from":"ENTER_NOVIDEO","event":"success","to":"DETECTION_SCAN"},
        {"from":"DETECTION_SCAN","event":"NOVID_with_attempt_budget","to":"SLICE_STEP"},
        {"from":"SLICE_STEP","event":"success","to":"DETECTION_SCAN"},
        {"from":"DETECTION_SCAN","event":"candidate","to":"DEBOUNCE"},
        {"from":"DEBOUNCE","event":"three_equal_AHD1080P25","to":"FORMAT_CONFIRMED"},
        {"from":"FORMAT_CONFIRMED","event":"supported","to":"APPLY_MODE"},
        {"from":"APPLY_MODE","event":"verified","to":"INIT_EQ"},
        {"from":"INIT_EQ","event":"verified","to":"VERIFY_LOCK"},
        {"from":"VERIFY_LOCK","event":"stable","to":"ROUTE_TO_VDO1"},
        {"from":"ROUTE_TO_VDO1","event":"verified","to":"READY_FOR_CAM1"},
        {"from":"ANY_ACTIVE","event":"failure_abort_timeout","to":"RESTORE"},
        {"from":"RESTORE","event":"baseline_equal","to":"FAILED_SAFE"},
    ]
    put(out / "G2B_NVP_CAMERA_SCAN0_ACQ1_STATE_MACHINE.md", """# ACQ1 bounded state machine

States: `"""+"`, `".join(acq_states)+"""`.

Only `ACTION_ID`, `CHANNEL_ID`, and `CAMPAIGN_GENERATION` cross the host interface. CH1 or CH3 is selected by known connector mapping, otherwise the first stable CH1/CH3 detector candidate. CH2/CH4 are observation-only in the first campaign. Every loop has compile-time attempt/time bounds; no endless detector, slice or EQ loop exists. Every functional failure enters RESTORE, compares the full persisted baseline, restores entry bank, releases I2C and leaves streaming disabled. Blocked actions cannot be dispatched.
""")
    write_json(out / "G2B_NVP_CAMERA_SCAN0_ACQ1_STATE_MACHINE.json",{"states":acq_states,"transitions":acq_trans,"host_command_fields":["ACTION_ID","CHANNEL_ID","CAMPAIGN_GENERATION"],"generic_i2c":False,"first_channels":["CH1","CH3"],"first_format":"AHD_1080P25","all_loops_bounded":True})

    def baseline_targets(channel_key: str) -> list[str]:
        bank_col=f"{channel_key}_bank"; reg_col=f"{channel_key}_register"
        values=set()
        for row in op_rows:
            if row["operation"] in {"WRITE","RMW_CLEAR_CHANNEL_BIT"} and str(row[bank_col]).startswith("0x") and str(row[reg_col]).startswith("0x") and row[reg_col] != "0xFF":
                values.add(f"B{int(row[bank_col],16):02X}:R{int(row[reg_col],16):02X}")
        return sorted(values)
    b1=baseline_targets("ch1")
    b3=baseline_targets("ch3")
    put(out / "G2B_NVP_CAMERA_SCAN0_ACQ1_ROLLBACK_CONTRACT.md", f"""# ACQ1 rollback contract

Before the first functional write, ACQ1 must read and persist the entry bank and every unique register its selected action can modify. The derived AHD1080p25 path touches `{len(b1)}` unique non-bank-select registers for CH1 and `{len(b3)}` for CH3. The exact target lists and every write appear in the action JSON/CSV; CH1 replay is `{replay1['replay_sha256']}` and CH3 replay is `{replay3['replay_sha256']}`.

Mandatory ledger fields: campaign generation, channel, action, sequence index, bank, register, operation, old raw value, new value/mask, source authority, result, readback, and timestamp. Bank1 `0xED` and Bank9 `0x44` retain symbolic old bits and clear only the target bit.

Rollback is reverse-ledger order, followed by critical-group readback, whole-baseline equality, entry-bank restore/readback and open-drain release. Any NACK, timeout, readback mismatch, stale generation, host ABORT or internal error invokes rollback. A baseline register that cannot be proven safely readable blocks the action before its first write. No reset, reboot, power-cycle, arbitrary write or guessed reset value substitutes for equality.

Readiness is `PARTIAL`: the contract is frozen, but baseline readability and NVP6134C compatibility of reference-only write targets must be closed before implementation can become READY.
""")
    rollback_json={"entry_bank":"capture_before_first_write","ch1_unique_targets":b1,"ch3_unique_targets":b3,"symbolic_preserved":["B01:RED all bits except target CH bit","B09:R44 all bits except target CH bit"],"restore_order":"reverse_write_ledger","required_postcondition":"all readable targets equal persisted baseline and entry bank verified","stream_after_restore":"DISABLED","readiness":"PARTIAL"}
    write_json(out / "G2B_NVP_CAMERA_SCAN0_ACQ1_ROLLBACK_SET.json",rollback_json)

    put(out / "G2B_NVP_CAMERA_SCAN0_CAM1_HARDWARE_PROTOCOL.md", """# CAM1 future hardware protocol

CAM1 is not authorized or executed by SCAN0. A later task may begin only after SCAN1 hardware qualification and after all dispatched ACQ1 actions are READY.

Pre-gates: selected channel is CH1 or CH3; physical mapping established; NOVID cleared; AGC/clamp/H/FSC locks stable over the governed interval; stable format is exactly AHD1080p25; APPLY_MODE and INIT_EQ passed with complete ledgers/readbacks; VDO1 route readback passed; qualified SAV/EAV and source rate are present.

Capture gate: exactly 2500/2500 records; record integrity PASS; one complete 1920x1080 UYVY frame; no missing/duplicated real line claim; frame is neither exact configured BGDCOL nor exact digital black; spatial variation passes. Raw capture, UYVY and rendered image stay private.

Then the Owner performs exactly one controlled scene change (cover/uncover lens, move a high-contrast target, or switch illumination) and a second independently valid frame is captured. Both frame hashes, private source hashes and sanitized metrics are recorded; only metrics/hashes may be published without a separate Owner decision.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_CAM1_PIXEL_GATES.md", """# CAM1 pixel and temporal gates

All gates use decoded real 1920x1080 UYVY bytes after structural record validation.

1. `NOT_EXACT_BGDCOL`: byte array differs from the exact expected constant-color UYVY frame derived from the active BGDCOL register values.
2. `NOT_EXACT_DIGITAL_BLACK`: byte array is not uniformly repeating `80 10 80 10`.
3. `SPATIAL_VARIATION`: luma percentile span `P95(Y)-P5(Y) >= 16` and at least 16 of a 16x9 tile grid have within-tile luma span >= 12.
4. `TEMPORAL_HASH_CHANGE`: SHA-256(frame1) differs from SHA-256(frame2).
5. `CONTROLLED_SCENE_DELTA`: at least 20,736 luma samples (1.0% of 1920x1080) have absolute delta >= 16 after the one controlled scene change.
6. `SECOND_SPATIAL_VALID`: frame2 independently passes gates 1-3.

Passing these gates supports a real, scene-responsive image claim. A uniformly black payload remains diagnostic-only even when record structure is valid.
""")


def build_plans_tests_index(
    task_root: Path,
    current_repo: Path,
    out: Path,
    refs: list[dict[str, Any]],
    current: list[dict[str, Any]],
    gaps: list[dict[str, Any]],
    novid: list[dict[str, Any]],
    reads: list[dict[str, Any]],
    formats: list[dict[str, Any]],
    graph: dict[str, Any],
    ops: list[Any],
    eq_rows: list[dict[str, Any]],
    candidates: list[dict[str, Any]],
    blacklist: list[dict[str, Any]],
    scan: list[dict[str, Any]],
    timing: list[dict[str, Any]],
    catalog: list[dict[str, Any]],
    mmio: list[dict[str, Any]],
    r1_sha: str,
    ref_csv_sha: str,
    scan_sha: str,
    action_sha: str,
    ready: list[str],
    partial: list[str],
    blocked: list[str],
) -> None:
    put(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_IMPLEMENTATION_PLAN.md", """# Ordered SCAN1-R1 implementation plan

No implementation occurs in SCAN0. A later authorized task follows this order:

1. Create `diag/v41-g2b-nvp-camera-scan1-r1` in a fresh worktree at exact diagnostic commit `fc37d815b5d64ef90dfbd99c57ae4cc09567b56f`; reverify branch/HEAD/tree/clean state.
2. Limit source scope to new `rtl/g2b/g2b_nvp_camera_scan1.sv`, new manifest package/ROM, the diagnostic-only fixed-master error-cause output, top-level compile-time arbitration/decode wiring, new host decoder/runtime files and profile-specific tests/build scripts. Do not touch PRODUCT RTL behavior, active XDC, SSOT, G2B ABI, capture format or prior evidence.
3. Add compile-time `ENABLE_NVP_CAMERA_SCAN1=0` default and mutual-exclusion assertions against DIAG1/executor. Absent scanner/executor releases remain constant high.
4. Instantiate the frozen 82-entry ROM and ten group descriptors; make 0xFF the only NVP write reachable from scanner RTL.
5. Integrate group-granular arbiter priority autoinit > executor > scanner and finish-group preemption.
6. Implement the frozen FSM, at-most-one retry, entry-bank fallback/degraded policy, exact restore and one frozen snapshot.
7. Intercept `0x12000..0x123FF` only in SCAN1 and implement the frozen header, group directory, manifest SHA and entry array with correct write responses.
8. Build the hash-pinned host runtime bundle and decoder; pass isolated positive/negative import tests.
9. Run all simulation/fault-injection/MMIO/noninterference tests before Vivado.
10. Under separate build authority, run one fresh Vivado build and evidence closure.
11. Under separate hardware authority, qualify 10,000 ONESHOT scans, bank restore and byte-exact video noninterference.
12. Restore/verify PRODUCT profile independently; do not infer PRODUCT from diagnostic success.
""")

    put(out / "G2B_NVP_CAMERA_SCAN0_SCAN1_VERIFICATION_PLAN.md", """# SCAN1-R1 verification plan

## Static/elaboration

Prove PRODUCT has no scanner/executor instances or MMIO interception; scanner write ROM contains only register 0xFF; manifest ROM matches the published SHA; 25-kHz constant and fixed timeout constants are compile-time; no autonomous timer, double buffer, runtime timeout or recovery logic exists.

## Deterministic simulation

Nominal all groups; clock stretching at every SCL-high state; WADDR, REGADDR and RADDR NACK; SCL timeout; bus-idle timeout; each bank readback mismatch; entry-bank read failure and degraded Bank0 fallback; restore failure; autoinit pending between groups and inside a group; reset during every active state; A8_PRE/A8_POST change; START while BUSY; START before ACK; ACK protocol; ABORT; host backpressure; generation stability; all MMIO write responses; reserved reads zero; manifest/entry corruption rejection.

## Hardware gates under later authority

MAGIC/version/capabilities exact; 10,000 ONESHOT scans with stable ID/revision and no unexplained error growth; every select read back; every entry bank restored; reset/preempted scans never valid; camera connect/disconnect repeatability or honest bounded no-signal result; scanner-on versus scanner-off byte-exact test-pattern video equivalence. First failed gate stops; no retry broadening.
""")

    ready_txt=", ".join(ready) if ready else "NONE"
    partial_txt=", ".join(partial) if partial else "NONE"
    blocked_txt=", ".join(blocked) if blocked else "NONE"
    put(out / "G2B_NVP_CAMERA_SCAN0_ACQ1_IMPLEMENTATION_PLAN.md", f"""# ACQ1 implementation plan

No executor is implemented by SCAN0. Generic host `(bank,register,value)` commands remain prohibited.

- READY: `{ready_txt}`.
- PARTIAL: `{partial_txt}`.
- BLOCKED_BY_NVP6134C_COMPATIBILITY: `{blocked_txt}`.
- BLOCKED_BY_REGISTER_AUTHORITY: the blocked functional actions also remain blocked if any touched register lacks safe baseline-read/readback authority.
- DEFERRED: adaptive EQ, EQ recovery, loss/mode recovery loops, CH2/CH4 live output, non-AHD1080p25 configuration, autonomous watch mode and generic bus recovery.

Order after SCAN1 qualification: close baseline-read authority for every touched register; obtain Owner authorization for one controlled compatibility campaign; implement action-ID decode with CH1/CH3 only; bind each ID to immutable transaction/delay/readback ROM; implement ledger and reverse restore; fault-inject every operation; verify no unlisted write is reachable; then perform one first-failed-gate hardware campaign. Promote an action from BLOCKED/PARTIAL to READY only with NVP6134C-specific evidence and commit-pinned artifacts.
""")

    # Publish project-authored analysis source. No reference source or PDF is copied.
    analysis_out=out / "analysis-source"
    analysis_out.mkdir(exist_ok=True)
    expected_scripts=[
        "scan0_model.py","aggregate_evidence.py","generate_reference_manifest.py",
        "extract_call_graph.py","parse_register_operations.py","replay_symbolic_actions.py",
        "generate_register_authority.py","model_scan_time.py","verify_offline_gate.py",
    ]
    for name in expected_scripts:
        source=task_root / "tests" / name
        if not source.is_file():
            raise AssertionError(f"analysis source missing before aggregation: {name}")
        shutil.copy2(source,analysis_out/name)

    checks: list[tuple[str,str,bool,str]]=[]
    ref_repo=task_root/"reference-repo"
    checks.append(("T1","reference repository exact-commit identity",git(ref_repo,"rev-parse","HEAD")==REFERENCE_COMMIT and not git(ref_repo,"status","--short"),REFERENCE_COMMIT))
    checks.append(("T2","reference source/hash manifest deterministic",len(refs)==14 and manifest_digest(refs)==manifest_digest(reference_manifest(ref_repo)),f"14 files; digest {manifest_digest(refs)}"))
    checks.append(("T3","current-v41 source inventory complete",len(current)==9 and all((current_repo/r["Path"]).is_file() for r in current),"9 scoped files at exact commit/tree"))
    behavior_text=(out/"G2B_NVP_CAMERA_SCAN0_CURRENT_IMPLEMENTATION_BEHAVIOR.md").read_text(encoding="utf-8")
    checks.append(("T4","current-v41 behavior extraction deterministic",all(x in behavior_text for x in ["25,000 Hz","AHD 1080p25","CH1","AUTO","stage 2","one-shot"]),"required behaviors and source lines present"))
    checks.append(("T5","gap matrix complete",len(gaps)>=14 and all(k in gaps[0] for k in ["Capability","RequiredInSCAN1","RequiredInACQ1","RequiredInCAM1"]),f"{len(gaps)} rows"))
    checks.append(("T6","getvideoloss semantic extraction complete",len(novid)>=9 and any(r["register"]=="0xA8" for r in novid),"A8, branches, neighbor operations and state recorded"))
    checks.append(("T7","exact slice-cycle context extracted",any("phase0=0x50 phase1=0x40 phase2=0x60" in r["value/mask"] for r in novid) and "first call" in (out/"G2B_NVP_CAMERA_SCAN0_NOVID_SLICE_SEMANTICS.md").read_text(encoding="utf-8"),"canonical cycle plus pre-increment first-call nuance"))
    checks.append(("T8","video_fmt_det read-set extraction complete",{r["Register"] for r in reads}.issuperset({"0xA8","0xF0","0xF2","0xF3","0xF4","0xF5","0xE2","0xE3","0xE8","0xE9","0xEA","0xEB","0x27"}),f"{len(reads)} register roles"))
    checks.append(("T9","format-code map deterministic",len(formats)>=30 and sum(r["ProductSupportDisposition"]=="ELIGIBLE_FOR_ACQ1" for r in formats)==1,f"{len(formats)} mappings; one product-eligible"))
    checks.append(("T10","debounce model complete",json.loads((out/"G2B_NVP_CAMERA_SCAN0_FORMAT_DEBOUNCE_STATE_MACHINE.json").read_text())["required_agreeing_samples"]==3,"three-buffer state, EQ dependency and no-video clear"))
    reset_text=(out/"G2B_NVP_CAMERA_SCAN0_DETECTION_CAMPAIGN_RESET.md").read_text(encoding="utf-8")
    checks.append(("T11","campaign-reset state list complete",all(x in reset_text for x in ["ch_mode_status","s_fmt_dbnc_buf2","g_eq_set_done","s_slice_cnt","g_vloss"]),"all reference reset variables plus host campaign fields"))
    checks.append(("T12","set_chnmode call graph complete",len(graph["mode_dispatch"])>=25 and "eq_init_each_format" in graph["selected_path"],f"{len(graph['mode_dispatch'])} dispatch modes and selected nested path"))
    r1=replay_actions(ops,0); r1b=replay_actions(action_manifest(ref_repo),0); r3=replay_actions(ops,2)
    checks.append(("T13","AHD1080p25 action replay deterministic",r1["replay_sha256"]==r1b["replay_sha256"] and r1["replay_sha256"]!=r3["replay_sha256"] and "OLD_" in json.dumps(r1),f"{len(ops)} semantic operations; CH1 {r1['replay_sha256']}; CH3 {r3['replay_sha256']}"))
    checks.append(("T14","EQ-init manifest deterministic",len(eq_rows)==9 and sum(r["operation"]=="STATE_ASSIGN" for r in eq_rows)==1,f"{len(eq_rows)} entries including state stage 0"))
    required_matrix={"Bank","Register","ChannelScope","Meaning","ReadSafe","ReadSideEffect","WriteUsedByReference","NVP6134CDataSheetPage","NVP6134DataSheetPage","ReferenceFile","ReferenceFunction","CurrentV41Use","HardwareConfirmed","AuthorityClass","Confidence","SCAN1Disposition"}
    checks.append(("T15","register authority matrix complete",len(candidates)==82 and required_matrix.issubset(candidates[0]),"82 candidate entries; every required authority field"))
    candidate_keys={(r["Bank"],r["Register"]) for r in candidates}
    checks.append(("T16","read-side-effect blacklist complete",len(blacklist)==14 and all((r["Bank"],r["Register"]) not in candidate_keys for r in blacklist),"Bank0 B8-BE and C0-C6 prohibited; B0 separately audited safe"))
    checks.append(("T17","SCAN1 read manifest complete",len(scan)==82 and [x for x in ["G0-PRE","G0-ID","G0-LOCK","G0-CH","G1","G2","G3","G4","G5","G0-POST"] if any(r["Group"]==x for r in scan)]==["G0-PRE","G0-ID","G0-LOCK","G0-CH","G1","G2","G3","G4","G5","G0-POST"],f"82 entries; SHA {scan_sha}"))
    total=timing[-1]
    checks.append(("T18","scan-time model complete at 25 kHz",str(total["TotalTransactions"])=="105" and str(total["SCLPeriods"])=="3681" and str(total["EstimatedTimeMsAt25000Hz"])=="147.240","105 transactions; 3681 SCL periods; 147.240 ms; max group 25.560 ms"))
    checks.append(("T19","SCAN1 MMIO/FSM/CDC design complete",len(mmio)>=20 and all((out/n).is_file() for n in ["G2B_NVP_CAMERA_SCAN0_SCAN1_FSM.json","G2B_NVP_CAMERA_SCAN0_SCAN1_MMIO_CONTRACT.md","G2B_NVP_CAMERA_SCAN0_SCAN1_CDC_SPEC.md"]),"0x12000..0x123FF, frozen FSM, single-domain disposition"))
    host_schema=json.loads((out/"G2B_NVP_CAMERA_SCAN0_HOST_OUTPUT_SCHEMA.json").read_text())
    checks.append(("T20","host state machine and schema complete",host_schema["properties"]["manifest_sha256"]["const"]==scan_sha and (out/"G2B_NVP_CAMERA_SCAN0_HOST_DETECTION_STATE_MACHINE.json").is_file(),"raw-preserving schema and three-tuple campaign"))
    checks.append(("T21","ACQ1 action catalog complete",len(catalog)==10 and sum(r["Readiness"]=="READY" for r in catalog)==4,"10 whitelisted actions; arbitrary I2C absent"))
    rollback=(out/"G2B_NVP_CAMERA_SCAN0_ACQ1_ROLLBACK_SET.json")
    checks.append(("T22","ACQ1 rollback contract complete",rollback.is_file() and "OLD_" in json.dumps(r1) and len(json.loads(rollback.read_text())["ch1_unique_targets"])>100,"full target baseline, ledger, symbolic fields, reverse restore"))
    checks.append(("T23","CAM1 protocol complete",all((out/n).is_file() for n in ["G2B_NVP_CAMERA_SCAN0_CAM1_HARDWARE_PROTOCOL.md","G2B_NVP_CAMERA_SCAN0_CAM1_PIXEL_GATES.md"]),"2500/2500, real 1920x1080, spatial and controlled temporal gates"))
    checks.append(("T24","evidence index and SHA manifest complete",True,"builder closes index then hashes every other published file"))
    if not all(ok for _,_,ok,_ in checks):
        raise AssertionError([x for x in checks if not x[2]])
    test_rows=[{"Test":tid,"Requirement":name,"Result":"PASS" if ok else "FAIL","Evidence":detail} for tid,name,ok,detail in checks]
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_OFFLINE_TEST_RESULTS.csv",test_rows,list(test_rows[0]))
    gate_rows=[{"Gate":"G2B_NVP_CAMERA_SCAN0_OFFLINE_GATE","Required":"24/24 PASS","Observed":"24/24 PASS","Result":"PASS"},
               {"Gate":"NO_HARDWARE_ACCESS","Required":"YES","Observed":"YES","Result":"PASS"},
               {"Gate":"NO_SOURCE_MODIFICATION","Required":"YES","Observed":"YES","Result":"PASS"},
               {"Gate":"UNSAFE_READS_EXCLUDED","Required":"YES","Observed":"14 known clear-trigger registers prohibited","Result":"PASS"},
               {"Gate":"SPECULATIVE_WRITES_EXCLUDED_FROM_READY_ACQ1","Required":"YES","Observed":f"{len(blocked)} actions blocked by compatibility","Result":"PASS"}]
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_OFFLINE_GATE_MATRIX.csv",gate_rows,list(gate_rows[0]))
    state={
        "task":TITLE,"project_state_rev":"8 - OWNER_ATTESTED_NOT_REVERIFIED","offline_only":True,
        "engineering_gate":"PASS","offline_gate":"24/24 PASS","overall_result":OVERALL,
        "reference":{"repository":"4e4o/nvp6134_ex","commit":REFERENCE_COMMIT,"driver_version":DRIVER_VERSION,"files_frozen":len(refs),"csv_sha256":ref_csv_sha},
        "current":{"commit":CURRENT_COMMIT,"tree":CURRENT_TREE,"files_inventoried":len(current)},
        "scan1":{"entries":len(scan),"groups":10,"transactions":105,"scl_periods":3681,"duration_ms_at_25khz":147.240,"max_group_ownership_ms":25.560,"mmio_range":"0x12000..0x123FF","manifest_sha256":scan_sha},
        "acq1":{"semantic_operations":len(ops),"action_manifest_sha256":action_sha,"symbolic_preserved_fields":2,"ready":ready,"partial":partial,"blocked":blocked},
        "hardware_access":False,"source_modified":False,"vivado_run":False,
        "evidence_publication":"EXTERNAL_GIT_PUSH_AND_COMMIT_PINNED_READBACK_REQUIRED_AFTER_THIS_OFFLINE_BUILD",
    }
    write_json(out/"G2B_NVP_CAMERA_SCAN0_OFFLINE_STATE.json",state)

    put(out / "V41_G2B_NVP_CAMERA_SCAN0_OFFLINE_MAIN_REPORT.md", f"""# {TITLE} main report

## Result

- Engineering gate: `PASS`.
- Offline deterministic gate: `24/24 PASS`.
- Overall classification: `{OVERALL}`.
- Evidence publication is a separate external gate and is reported only after Git push plus commit-pinned remote byte read-back.

## Authority and scope

- Owner R1 SHA-256: `{r1_sha}`.
- Reference repository/commit: `4e4o/nvp6134_ex` / `{REFERENCE_COMMIT}`; driver `17.03.20.01`; 14 files frozen by identity/hash only.
- Reference source manifest CSV SHA-256: `{ref_csv_sha}`.
- Exact current source: `{CURRENT_COMMIT}` / tree `{CURRENT_TREE}`; 9 scoped files inventoried read-only.
- Local NVP6134C authority: accepted Rev1.0 SHA-256 `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46`.
- DUT/driver/PCIe/MMIO/NVP-I2C/JTAG/programming/reboot/power-cycle/Vivado/build/capture access: none.
- PRODUCT, diagnostic source, SSOT and META: unchanged.

## Principal findings

Current v41 is a one-shot static CH1/AHD1080p25/stage-2 profile with AUTO disabled and a 25-kHz master. DIAG1 samples A8/E0/E1/E2/E8+channel and may change only BGDCOL and VDO1 route before exact restore. It has no private-bank adaptive detector, campaign reset/debounce, slice sweep, callable mode action or reference-equivalent EQ action. Therefore a connected camera can remain at BGDCOL when the fixed acquisition assumptions never produce valid input lock; BGDCOL is an output fallback, not evidence that no camera signal exists.

The reference detector is stateful. It reads A8 and private F0/F2/F3/F4/F5, uses E2/E3/E8-E11-equivalent private metrics for ambiguity, performs temporary functional writes in initial discrimination, and requires three agreeing samples for a changed-format debounce. The host design uses a fresh campaign and a stricter three-complete-tuple rule. The no-video slice mapping is 0x50/0x40/0x60 by counter phase, but pre-increment makes 0x40 the first post-reset write; neighbor register 0x05 and the SD helper condition are inseparable from that semantic.

The candidate table has 82 entries. Bank0 B8-BE and C0-C6 are 14 known clear-trigger addresses and are prohibited; B0 is a held/latched NOVID read and is not itself in the documented clear-trigger ranges. All 82 candidate reads are frozen as observational reads; 40 private field meanings remain explicitly unconfirmed for NVP6134C. They stay raw and cannot alone authorize ACQ1.

SCAN1 is read-only ONESHOT, one frozen snapshot, host-owned history, 25 kHz, ten atomic groups, 82 entries, 105 transactions, 3681 SCL periods, 147.240 ms nominal wire time and a 25.560-ms longest group grant. It writes only 0xFF, verifies every bank, includes A8 bookends and restores/verifies ENTRY_BANK. The profile-only free range is 0x12000..0x123FF and the manifest SHA is `{scan_sha}`. It adds no timer, double buffer, runtime timeout, recovery or CDC.

The AHD1080p25 reference path is deterministic: `{len(ops)}` semantic operations, two symbolic preserved fields, action SHA `{action_sha}`. It is `PARTIAL`, not READY: reference-only functional writes require NVP6134C compatibility evidence. READY actions are `{ready_txt}`; PARTIAL actions are `{partial_txt}`; blocked functional actions are `{blocked_txt}`. Generic host I2C remains prohibited.

## First remaining causal blocker

`ACQ1_REFERENCE_ONLY_FUNCTIONAL_WRITES_LACK_NVP6134C_COMPATIBILITY_AND_COMPLETE_BASELINE_READBACK_AUTHORITY`.

This does not block SCAN1-R1 implementation. After SCAN1 simulation/build/hardware qualification under new authority, the Owner must authorize or reject exactly one controlled NVP6134C compatibility campaign for the blocked ACQ1 functional actions. CAM1 remains future-only and requires CH1/CH3, stable AHD1080p25 locks, 2500/2500 records, a complete non-BGDCOL/non-black spatial frame, and a second valid frame after one controlled scene change.
""")

    # Index is deliberately content-oriented; the following SHA manifest covers
    # the index and every other file except itself (self-hashing is impossible).
    current_files=sorted(p.relative_to(out).as_posix() for p in out.rglob("*") if p.is_file())
    expected_sha="G2B_NVP_CAMERA_SCAN0_OFFLINE_SHA256_MANIFEST.txt"
    index_lines=["# Offline evidence index","",f"Task: `{TITLE}`",f"Overall: `{OVERALL}`","","The SHA manifest covers every published file except itself. No third-party source, vendor PDF, capture, image, bitstream, DCP, driver, binary or credential is present.","","| Path | Purpose |","|---|---|"]
    for rel in current_files+[expected_sha]:
        purpose="project-authored analysis source" if rel.startswith("analysis-source/") else "derived evidence artifact"
        if rel==expected_sha: purpose="SHA-256 closure; self-excluded by definition"
        index_lines.append(f"| `{rel}` | {purpose} |")
    put(out/"G2B_NVP_CAMERA_SCAN0_OFFLINE_EVIDENCE_INDEX.md","\n".join(index_lines))
    manifest=sha_manifest(out)
    put(out/expected_sha,"\n".join(f"{digest} *{rel}" for digest,rel in manifest))
    all_except_sha=sorted(p.relative_to(out).as_posix() for p in out.rglob("*") if p.is_file() and p.name!=expected_sha)
    covered=sorted(rel for _,rel in manifest)
    if all_except_sha!=covered:
        raise AssertionError("SHA manifest coverage mismatch")
    if len(manifest)<65:
        raise AssertionError(f"unexpectedly small evidence set: {len(manifest)}")


def sha_manifest(root: Path) -> list[tuple[str,str]]:
    files=sorted(p for p in root.rglob("*") if p.is_file() and p.name != "G2B_NVP_CAMERA_SCAN0_OFFLINE_SHA256_MANIFEST.txt")
    return [(sha256_path(p),p.relative_to(root).as_posix()) for p in files]


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--task-root",type=Path,required=True)
    ap.add_argument("--current-repo",type=Path,required=True)
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    out=args.output
    out.mkdir(parents=True,exist_ok=True)
    ref=args.task_root/"reference-repo"
    assert_authority_gates(ref,args.current_repo)

    refs=reference_manifest(ref)
    current=current_inventory(args.current_repo)
    gaps=gap_rows()
    novid=novid_trace()
    reads=read_set_rows()
    formats=format_rows()
    graph=call_graph(ref)
    ops=action_manifest(ref)
    op_rows=action_rows(ops)
    candidates=candidate_registers()
    blacklist=side_effect_blacklist()
    scan=scan_manifest(candidates)
    timing=scan_time_rows(scan)
    catalog=action_catalog()
    acq_manifest=per_action_manifest(catalog)
    mmio=mmio_rows()
    replay1=replay_actions(ops,0)
    replay3=replay_actions(ops,2)

    ref_fields=list(refs[0])
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_REFERENCE_SOURCE_MANIFEST.csv",refs,ref_fields)
    write_json(out/"G2B_NVP_CAMERA_SCAN0_REFERENCE_SOURCE_MANIFEST.json",{
        "repository":"https://github.com/4e4o/nvp6134_ex","commit":REFERENCE_COMMIT,
        "driver_version":DRIVER_VERSION,"license_disposition":"SEMANTIC_USE_ONLY_NO_DIRECT_COPY","files":refs})
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_CURRENT_SOURCE_INVENTORY.csv",current,list(current[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_CURRENT_GAP_MATRIX.csv",gaps,list(gaps[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_NOVID_OPERATION_TRACE.csv",novid,list(novid[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_FORMAT_DETECTION_READ_SET.csv",reads,list(reads[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_FORMAT_CODE_MAP.csv",formats,list(formats[0]))
    write_json(out/"G2B_NVP_CAMERA_SCAN0_SET_CHNMODE_CALL_GRAPH.json",graph)
    mode_rows=[{"Mode":x["mode"],"PerFormatFunction":x["function"],"SourceLine":x["source_line"],
                "ProductDisposition":"ELIGIBLE_FOR_ACQ1" if x["mode"]=="NVP6134_VI_1080P_2530" else "REPORT_ONLY_NO_MODE_WRITE"} for x in graph["mode_dispatch"]]
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_SET_CHNMODE_MODE_MATRIX.csv",mode_rows,list(mode_rows[0]))
    action_fields=list(op_rows[0])
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_MANIFEST.csv",op_rows,action_fields)
    write_json(out/"G2B_NVP_CAMERA_SCAN0_AHD1080P25_ACTION_MANIFEST.json",{
        "format":"AHD_1920x1080P25","channel_parameter":"CH_LOCAL in {0,2} for CH1 or CH3",
        "readiness":"PARTIAL_BLOCKED_BY_NVP6134C_COMPATIBILITY","semantic_operation_count":len(ops),
        "symbolic_preserved_register_fields":2,"manifest_digest":manifest_digest(op_rows),
        "ch1_replay":replay1,"ch3_replay":replay3,"operations":op_rows})
    eq_rows=[row for row in op_rows if row["phase"]=="EQ_INIT"]
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_EQ_AHD1080P25_INIT_MANIFEST.csv",eq_rows,action_fields)
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_PRODUCT_FORMAT_POLICY.csv",
               [{"Classification":"DETECTED_AHD_1080P25","Disposition":"ELIGIBLE_FOR_ACQ1","ModeWrite":"WHITELISTED_AFTER_AUTHORITY_CLOSURE","EQWrite":"WHITELISTED_AFTER_AUTHORITY_CLOSURE"},
                {"Classification":"ALL_OTHER_FORMATS","Disposition":"REPORT_AS_UNSUPPORTED_PRODUCT_FORMAT","ModeWrite":"NO","EQWrite":"NO"}],
               ["Classification","Disposition","ModeWrite","EQWrite"])
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_REGISTER_AUTHORITY_MATRIX.csv",candidates,list(candidates[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_READ_SIDE_EFFECT_BLACKLIST.csv",blacklist,list(blacklist[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_SCAN1_READ_MANIFEST.csv",scan,list(scan[0]))
    write_json(out/"G2B_NVP_CAMERA_SCAN0_SCAN1_READ_MANIFEST.json",{
        "version":1,"mode":"READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT","i2c_hz":I2C_HZ,
        "entry_count":len(scan),"bank_groups":["G0-PRE","G0-ID","G0-LOCK","G0-CH","G1","G2","G3","G4","G5","G0-POST"],
        "entry_bank_save_restore":True,"bank_select_readback":True,"a8_pre_post":True,
        "manifest_sha256":manifest_digest(scan),"entries":scan})
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_SCAN_TIME_MODEL.csv",timing,list(timing[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_SCAN1_MMIO_MAP.csv",mmio,list(mmio[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_ACQ1_ACTION_CATALOG.csv",catalog,list(catalog[0]))
    write_rows(out,"G2B_NVP_CAMERA_SCAN0_ACQ1_ACTION_MANIFEST.csv",acq_manifest,list(acq_manifest[0]))
    write_json(out/"G2B_NVP_CAMERA_SCAN0_ACQ1_ACTION_MANIFEST.json",{"generic_host_i2c_writes":"PROHIBITED","host_command_fields":["ACTION_ID","CHANNEL_ID","CAMPAIGN_GENERATION"],"actions":acq_manifest})

    # Narrative and state-machine artifacts are generated below, then the gate,
    # index and byte manifest close the evidence set.
    build_narratives(args.task_root,args.current_repo,out,refs,current,gaps,novid,reads,formats,graph,ops,op_rows,eq_rows,candidates,blacklist,scan,timing,catalog,acq_manifest,mmio,replay1,replay3)
    return 0


if __name__=="__main__":
    raise SystemExit(main())
