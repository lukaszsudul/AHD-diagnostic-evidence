from __future__ import annotations

import csv
import hashlib
import re
from collections import Counter
from pathlib import Path

ROOT = Path(r"C:\FPGA\CONT1R3R4R5_W1W2_20260917T151605Z\w2")
PKG = ROOT / "private/fpga/rtl/nvp/nvp6134c_diagnostics_pkg.vhd"
text = PKG.read_text(encoding="utf-8")

start = text.index("function c_v38ek_marek_op_for_slot(slot : natural; stage : std_logic_vector(1 downto 0)) return t_v38ek_op is")
end = text.index("function c_v38ek_overlay_op_for_slot", start)
marek = text[start:end]
pat = re.compile(r'when\s+(\d+)\s*=>\s*if stage_enabled\(stage,\s*(\d+)\) then return x"([0-9A-F]{6})";', re.I)
rows = []
for m in pat.finditer(marek):
    slot, minimum, word = int(m[1]), int(m[2]), m[3].upper()
    rows.append(dict(slot=slot, minimum_stage=minimum, enabled_stage2=minimum <= 2,
                     bank=word[:2], register=word[2:4], value=word[4:],
                     source_line=marek[:m.start()].count("\n") + text[:start].count("\n") + 1))
assert len(rows) == 148 and [r["slot"] for r in rows] == list(range(148))

with (ROOT / "private/MAREK_STAGE2_LEDGER.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader(); w.writerows(rows)

enabled = [r for r in rows if r["enabled_stage2"]]
bank5 = [r for r in enabled if r["bank"] == "05" and r["register"] != "FF"]
delays = [r for r in enabled if r["bank"] == "FE"]
all_delays = [r for r in rows if r["bank"] == "FE"]
print("marek rows", len(rows), "enabled stage2", len(enabled), "disabled stage3", len(rows)-len(enabled))
print("stage2 bank5 functional rows", len(bank5), "unique full keys", len({(r['bank'],r['register']) for r in bank5}))
print("bank5 slots", ','.join(str(r['slot']) for r in bank5))
print("stage2 delays", [(r['slot'],r['value']) for r in delays], "all stage1-3 delays", [(r['slot'],r['minimum_stage'],r['value']) for r in all_delays])
print("repeated bank5 registers", {k:v for k,v in Counter(r['register'] for r in bank5).items() if v>1})

overlay_start = text.index("function c_v38ek_overlay_op_for_slot(slot : natural; profile : std_logic_vector(1 downto 0); phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic) return t_v38ek_op is")
overlay_end = text.index("function c_v38ek_patch_op_for_slot", overlay_start)
overlay_text = text[overlay_start:overlay_end]
overlay_pat = re.compile(r'when\s+(\d+)\s*=>\s*return x"([0-9A-F]{4,6})"([^;]*);', re.I)
overlay = []
for m in overlay_pat.finditer(overlay_text):
    slot, prefix, tail = int(m[1]), m[2].upper(), m[3].strip()
    overlay.append(dict(slot=148+slot, minimum_stage=1, enabled_stage2=True,
                        bank=prefix[:2], register=prefix[2:4],
                        value=prefix[4:] if len(prefix)==6 else "SYMBOLIC:"+tail,
                        source_line=overlay_text[:m.start()].count("\n") + text[:overlay_start].count("\n") + 1))
assert len(overlay)==66 and [r['slot'] for r in overlay]==list(range(148,214))
all_slots = rows+overlay
active = [r for r in all_slots if r['enabled_stage2']]
functional = [r for r in active if r['bank'] not in ('FD','FE') and r['register']!='FF']
explicit_bank_selects = [r for r in active if r['register']=='FF']
assert len(all_slots)==214
with (ROOT / "private/ACTIVE_STAGE2_LEDGER.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=all_slots[0].keys())
    w.writeheader(); w.writerows(all_slots)
print("all slots", len(all_slots), "active", len(active), "functional rows", len(functional), "explicit bank-select rows", len(explicit_bank_selects), "NOP", len(all_slots)-len(active))
print("explicit bank select slots", [r['slot'] for r in explicit_bank_selects])

physical_bank = '00'  # successful preinit force-Bank0 write/readback
generated_bank_selects = []
for r in active:
    if r['bank'] == 'FE':
        continue
    if r['bank'] != physical_bank:
        generated_bank_selects.append((r['slot'], physical_bank, r['bank']))
        physical_bank = r['bank']
    if r['register'] == 'FF':
        assert r['value'] == r['bank'], (r['slot'], r['value'], r['bank'])
        physical_bank = r['value']
print("generated selects on clean preverified path", len(generated_bank_selects), generated_bank_selects)

# This ledger is deliberately scoped to the reference CH0/PAL common and
# conditional 1080P2530 source blocks. It records source operations, never
# claims that hardware followed the conditional path.
refdir = ROOT / "private/reference"
ref_blocks = [
    ("common_value", "video.c", 2068, 2136),
    ("common_fhd", "video.c", 3386, 3465),
    ("conditional_1080p2530", "video.c", 3466, 3535),
    ("conditional_eq_preamble", "eq.c", 78, 83),
    ("conditional_eq_1080p2530", "eq.c", 127, 139),
]
ref_ops = []
ref_bank = None
for phase, file, lo, hi in ref_blocks:
    lines = (refdir/file).read_text(encoding='latin-1').splitlines()
    for lineno in range(lo, hi+1):
        code = lines[lineno-1].split('//',1)[0].strip()
        m = re.search(r'gpio_i2c_(write|read)\([^,]+,\s*([^,]+)(?:,\s*(.*?))?\s*\);',code,re.I)
        if m:
            op, regexpr, valexpr = m[1].upper(), m[2].strip(), (m[3] or '').strip()
            def simple(expr):
                expr = expr.strip()
                if 'vfmt==PAL?' in expr:
                    expr = expr.split('?',1)[1].split(':',1)[0]
                expr = expr.replace('ch%4','0').replace('ch/4','0')
                if re.fullmatch(r'[0-9a-fA-FxX+*()\s-]+',expr):
                    try: return int(eval(expr, {'__builtins__':{}},{})) & 255
                    except Exception: pass
                return None
            regnum = simple(regexpr)
            valnum = simple(valexpr) if op=='WRITE' else None
            if regnum == 255 and op=='WRITE' and valnum is not None:
                ref_bank = valnum
            ref_ops.append(dict(phase=phase, file=file, line=lineno, operation=op,
                                bank=f'{ref_bank:02X}' if ref_bank is not None else 'UNKNOWN',
                                register=f'{regnum:02X}' if regnum is not None else 'SYMBOLIC:'+regexpr,
                                value=f'{valnum:02X}' if valnum is not None else ('SYMBOLIC:'+valexpr if op=='WRITE' else ''),
                                condition='CH0_PAL_1080P2530_CONDITIONAL_PATH'))
        m2 = re.search(r'\b(msleep|udelay)\((\d+)\)',code)
        if m2:
            ref_ops.append(dict(phase=phase,file=file,line=lineno,operation=m2[1].upper(),bank='',register='',value=m2[2],condition='CH0_PAL_1080P2530_CONDITIONAL_PATH'))

with (ROOT / 'private/REFERENCE_SCOPED_CORE_LEDGER.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=ref_ops[0].keys()); w.writeheader(); w.writerows(ref_ops)
ref_bank5 = [r for r in ref_ops if r['operation']=='WRITE' and r['bank']=='05' and r['register']!='FF']
ref_by_reg = {}
for r in ref_bank5: ref_by_reg.setdefault(r['register'],[]).append(r)
print('reference scoped core ops',len(ref_ops),'bank5 writes',len(ref_bank5),'unique bank5 keys',len(ref_by_reg))

event_in = Path(r'C:\FPGA\V41_G2B_EVIDENCE\v41-hardware-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3r4r2-coldstart-existing-driver\EVENTS_SUMMARY.csv')
manifest_lines = (ROOT/'private/fpga/rtl/g2b/g2b_nvp_camera_scan1_manifest_pkg.sv').read_text().splitlines()
entry_lines = {}
for i,line in enumerate(manifest_lines,1):
    m=re.search(r"7'd(\d+):\s+scan1_entry_register",line)
    if m: entry_lines[int(m[1])]=i
events=list(csv.DictReader(event_in.open(newline='',encoding='utf-8-sig')))
assert len(events)==11
event_rows=[]
for n,e in enumerate(events,1):
    bank=int(e['bank']); reg=int(e['register_decimal'])
    if bank in (5,6,7,8) and reg in (0xF2,0xF4,0xF5):
        ref_site='video.c:401-406;video.c:637-642'
        ref_context='CONDITIONAL_DETECTOR_READ_AFTER_SINGLE_0xFF_SELECT_FOR_F0_F2_F3_F4_F5'
    elif (bank,reg)==(1,0x84):
        ref_site='video.c:3542-3544;video.c:3471-3474;video.c:153-154'
        ref_context='MODULE_INIT_NOVIDEO_CH0_WRITE;CONDITIONAL_1080P2530_CH0_WRITE;OPTIONAL_ADC_HELPER_READ_ONLY_IF_CALLED'
    elif (bank,reg)==(1,0x98):
        ref_site='NOT_FOUND_IN_REVIEWED_PATH'
        ref_context='SEARCH_HITS_0x98_ARE_OTHER_BANK_VALUE_OR_INACTIVE_MODE;NO_ACTIVE_BANK1_READ_PROVEN'
    elif (bank,reg)==(0,0xEA):
        ref_site='NOT_FOUND_IN_REVIEWED_PATH'
        ref_context='NO_BANK0_EA_READ_IN_SCOPED_REFERENCE_INIT_OR_DETECTOR_PATH'
    else: raise AssertionError((bank,reg))
    event_rows.append(dict(event_ordinal=n,**e,bank_hex=f'{bank:02X}',register_hex=f'{reg:02X}',
                           scanner_manifest_site=f'g2b_nvp_camera_scan1_manifest_pkg.sv:{entry_lines[int(e["entry_index"])]}',
                           reference_site=ref_site,reference_path_context=ref_context,
                           classification='HISTORICAL_REGADDR_NACK_RECOVERED_FIRST_ATTEMPT',
                           causal_inference='NONE_FROM_CODE_COMPARISON'))
with (ROOT/'outputs/W2_CURRENT_EVENT_REVIEW.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=event_rows[0].keys()); w.writeheader();w.writerows(event_rows)
print('events',len(event_rows),'unique targets',len({(r['bank_hex'],r['register_hex']) for r in event_rows}))

private_ledger_hash=hashlib.sha256((ROOT/'private/ACTIVE_STAGE2_LEDGER.csv').read_bytes()).hexdigest().upper()
diff=[]
our_reg_occurrence=Counter()
for r in bank5:
    our_reg_occurrence[r['register']]+=1
    occurrence=our_reg_occurrence[r['register']]
    refs=ref_by_reg.get(r['register'],[])
    peer=refs[occurrence-1] if occurrence<=len(refs) else None
    if peer is None: outcome='NO_COMPARABLE_STEP'
    elif peer['value']==r['value']: outcome='MATCH_VALUE;ORDER_DIFF_GLOBAL'
    else: outcome='DIFF_VALUE;ORDER_DIFF_GLOBAL'
    refsites=f"{peer['file']}:{peer['line']}" if peer else 'NOT_FOUND_AT_SAME_REGISTER_OCCURRENCE_IN_SCOPED_CORE_PATH'
    diff.append(dict(comparison_item=f"MAREK_STAGE2_SLOT_{r['slot']:03d}",
                     our_active_path_and_condition='MAREK_ENABLED_STAGE2_PROFILE10_CH0',
                     reference_path_and_condition='CONDITIONAL_CH0_PAL_1080P2530_CORE_SUBPATH_ONLY;MODULE_INIT_NOVIDEO_EXCLUDED_FROM_OCCURRENCE_ALIGNMENT',
                     channel_or_port='OUR_CH1_REF_CH0',bank='05',register=r['register'],
                     our_order_value_delay=f"slot={r['slot']};value=PRIVATE_LEDGER_SHA256_{private_ledger_hash};no_local_postwrite_delay",
                     reference_order_value_delay=f"same_register_occurrence={occurrence}/{len(refs)};{refsites};value_in_private_reference_ledger;postwrite_helper_wait_200us_or_300us_if_selected",
                     match_or_difference=outcome,
                     provenance=f"nvp6134c_diagnostics_pkg.vhd:{r['source_line']};{refsites}",
                     applicability='FPGA_ACTIVE;REFERENCE_1080P2530_CONDITIONAL',
                     causal_relevance='CONFIGURATION_OR_ORDER_CANDIDATE_NOT_PHYSICAL_CAUSE_PROOF',
                     disposition='NO_CHANGE_W1W2;PRESERVE_FOR_W3_INTERPRETATION'))

extras=[
('INIT_ORDER','AUTOINIT_MAREK_COMMON_THEN_CH1_PRIVATE_THEN_OVERLAY','MODULE_INIT_COMMON_EACH_CH_THEN_NOVIDEO_EACH_CH_THEN_CHIP_ID_PORT_BRANCH','ALL','','','our stage2 fixed profile; no equivalent no-video default','reference driver module init is NOVIDEO; 1080P2530 only conditional','DIFFERENT_ACTIVE_DEFAULT','autoinit.vhd:193-199;diagnostics_pkg.vhd:230-510;nvp6134_drv.c:835-861','REFERENCE_CHIP_ID_UNKNOWN','BASELINE_SEQUENCE_DIFFERENCE','NO_CHANGE_W1W2'),
('GROUP_BANK_SELECT_VERIFY','SCAN1_SUCCESSFUL_FF_WRITE_THEN_FF_VERIFY','REFERENCE_HELPER_WRITE_WAIT_THEN_SELECTED_READS;NO_GENERAL_FF_VERIFY','ALL','FF','FF','verify is explicit scanner operation','200us HI_I2C or 300us I2C_INTERNAL after write; returns ignored','DIFFERENT_TRANSACTION_PATTERN','g2b_nvp_camera_scan1.sv;nvp6134_drv.c:92-126','REFERENCE_TRANSPORT_CONDITIONAL','DIRECT_TIMING_HYPOTHESIS','W3_NARROW_DELAY_CANDIDATE'),
('MODE_BANK0_81','OVERLAY_SLOT159_00_81_03','CONDITIONAL_1080P2530_PAL_CH0','CH1','00','81','slot159 value03','video.c:3480 PAL value03','MATCH_VALUE_CONDITIONAL_ORDER_DIFF','diagnostics_pkg.vhd:399-406;video.c:3480','CONDITIONAL_PATH','FORMAT_TARGET_ONLY','NO_CHANGE_W1W2'),
('MODE_BANK1_84','OVERLAY_SLOT172_01_84_00','CONDITIONAL_1080P2530_PAL_CH0','CH1','01','84','slot172 value00','video.c:3473 value00','MATCH_VALUE_CONDITIONAL_ORDER_DIFF','diagnostics_pkg.vhd:421;video.c:3473','CONDITIONAL_PATH','CURRENT_EVENT_TARGET','NO_CHANGE_W1W2'),
('MODE_BANK1_98','OVERLAY_SLOT181_01_98_00','NO_BANK1_98_READ_IN_REVIEWED_REFERENCE_PATH','CH1','01','98','slot181 value00','NOT_FOUND_IN_REVIEWED_PATH','REFERENCE_ACCESS_NOT_FOUND','diagnostics_pkg.vhd:430;video.c scoped path','SCOPED_REVIEW','CURRENT_EVENT_TARGET','NO_CHANGE_W1W2'),
('PORT_CA','OVERLAY_SLOT188_01_CA_22','SYSTEM_INIT_CHIP_ID_CONDITIONAL_CA66_OR_CAFF;PORTMODE_SEPARATE','VDO1','01','CA','slot188 value22','video.c:200-205 value66 if ID90 else FF; port mode later','VALUE_AND_ORDER_DIFFER','diagnostics_pkg.vhd:437;video.c:200-205;video.c:1205-1252','CHIP_ID_UNKNOWN','PORT_INTERPRETATION_LIMIT','NO_CHANGE_W1W2'),
('EQ_REACHED','STAGE2_TABLE_51_BANK5_WRITES','REFERENCE_EQ_INIT_ONLY_FOR_NON_NOVIDEO_SET_CHNMODE','CH1','05','GROUP','fixed stage2 writes; final 58=00 59=00','eq.c:78-139 conditional 1080P2530 ends 59=11 and C0/C1/C8 writes','DIFFERENT_FINAL_VALUES_AND_CONDITION','diagnostics_pkg.vhd:230-383;eq.c:78-139','CONDITIONAL_PATH','PRIVATE_BANK_CONFIGURATION_DIFFERENCE','NO_CHANGE_W1W2'),
('READ_DETECTORS','SCAN1_GROUPS5_TO8_F0_F2_F3_F4_F5','VIDEO_FMT_DEBOUNCE_OR_VIDEO_FMT_DET_ON_EXPLICIT_CALL','CH1_TO4','05-08','F0-F5','FF write verify; entries read individually','one FF select then successive F0 F2 F3 F4 F5 reads; helper wait only after FF write','ACCESS_OVERLAP_TRANSACTION_PATTERN_DIFF','manifest_pkg.sv:145-188;video.c:400-406;video.c:636-642','DETECTION_CALL_CONDITIONAL','CURRENT_EVENT_TARGETS','NO_CHANGE_W1W2'),
('TABLE_DELAY','MAREK_SLOT4_FE03E8_STAGE2','NO_DIRECT_COUNTERPART_POST_EACH_WRITE','ALL','FE','03','one active opcode 1000 ticks nominal20.016ms','helper wait after each write if selected','DIFFERENT_WAIT_PLACEMENT','diagnostics_pkg.vhd:237,368;bringup.vhd:1004-1010,2090-2100','ACTIVE_FPGA_CONDITIONAL_TRANSPORT','POSTWRITE_HYPOTHESIS','NO_CHANGE_W1W2'),
]
for t in extras:
    diff.append(dict(zip(diff[0].keys(),t)))
with (ROOT/'outputs/W2_SEQUENCE_DIFF.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=diff[0].keys());w.writeheader();w.writerows(diff)
print('sequence diff rows',len(diff),'private ledger sha',private_ledger_hash)
print('bank5 ordered comparison status',dict(Counter(x['match_or_difference'] for x in diff[:51])))

# Call-order ledger complements the per-operation CH0 core ledger. Unknown
# chip-ID and detector read branches stay symbolic; no mock value is selected.
calls=[]
def call(path,order,operation,site,condition,scope='',delay_ms='',read_dependency='',note=''):
    calls.append(dict(path=path,order=order,operation=operation,site=site,
                      condition=condition,scope_or_count=scope,delay_ms=delay_ms,
                      read_dependency=read_dependency,note=note))
call('MODULE_INIT',1,'READ_ID_REV','nvp6134_drv.c:801-806;175-203','FOR_EACH_4_CANDIDATE_ADDRESSES','check_id and check_rev each write Bank0 then read F4/F5','','READ_VALUES_UNKNOWN','accepted chip count symbolic')
call('MODULE_INIT',2,'CALL_COMMON_INIT','nvp6134_drv.c:834-836;video.c:195-232','FOR_EACH_ACCEPTED_CHIP','system_init then 4 channel common writes and init_acp')
call('MODULE_INIT',3,'SYSTEM_INIT_CA_BRANCH','video.c:195-206','CHIP_ID_0x90_OR_0x91','CA=66 for 0x90; CA=FF otherwise','','CHIP_ID_UNKNOWN','mutually exclusive')
for ch in range(4):
    base=10+ch*10
    call('MODULE_INIT',base,'COMMON_CHANNEL_CONTROL','video.c:222-228',f'ACCEPTED_CHIP_CH{ch}','Bank3/4 paired channel write')
    call('MODULE_INIT',base+1,'ACP_CLEAR_ASSERT','acp.c:119-123',f'ACCEPTED_CHIP_CH{ch}','Bank3/4 clear pulse')
    call('MODULE_INIT',base+2,'LOCAL_WAIT','acp.c:123',f'ACCEPTED_CHIP_CH{ch}','after ACP clear assert',10)
    call('MODULE_INIT',base+3,'ACP_CLEAR_RELEASE','acp.c:124-125',f'ACCEPTED_CHIP_CH{ch}','Bank3/4 clear pulse')
    call('MODULE_INIT',base+4,'LOCAL_WAIT','acp.c:125',f'ACCEPTED_CHIP_CH{ch}','after ACP clear release',200)
for ch in range(4):
    base=100+ch*10
    call('MODULE_INIT',base,'CALL_SET_CHNMODE_NOVIDEO','nvp6134_drv.c:839-845;video.c:1099-1183',f'ACCEPTED_CHIP_CH{ch}','PAL default NOVIDEO')
    call('MODULE_INIT',base+1,'COMMON_VALUE_WRITES','video.c:2068-2136',f'ACCEPTED_CHIP_CH{ch}','ordered bank0/private/9/0A writes; repeats retained')
    call('MODULE_INIT',base+2,'COMMON_FHD_WRITES_AND_RMW_READS','video.c:3386-3465',f'ACCEPTED_CHIP_CH{ch}','read-dependent Bank1 ED and Bank9 44 symbolic','','BANK1_ED_AND_BANK9_44_UNKNOWN')
    call('MODULE_INIT',base+3,'NOVIDEO_WRITES','video.c:3536-3596',f'ACCEPTED_CHIP_CH{ch}','includes Bank1 84 write and private bank')
    call('MODULE_INIT',base+4,'LOCAL_WAIT','video.c:1173',f'ACCEPTED_CHIP_CH{ch}','after Bank9 post-mode write',35)
    call('MODULE_INIT',base+5,'FINAL_BANK0_WRITE','video.c:1180-1181',f'ACCEPTED_CHIP_CH{ch}','Bank0 channel normal')
call('MODULE_INIT',200,'PORT_BRANCH_0x91','nvp6134_drv.c:848-855;video.c:1240-1253','CHIP_ID_0x91','four 1MUX_FHD port calls','','CHIP_ID_UNKNOWN','Bank1 C8 read-modify-write in each')
call('MODULE_INIT',201,'PORT_BRANCH_0x90','nvp6134_drv.c:856-861;video.c:1326-1390','CHIP_ID_0x90','two 2MUX_FHD port calls','','CHIP_ID_UNKNOWN','Bank0 81-88 and Bank1 C8 reads influence values')
call('MODULE_INIT',202,'KTHREAD_BODY_INACTIVE','nvp6134_drv.c:728-753','COMPILED_#IF_0','detector/EQ body not executed')
call('CONDITIONAL_1080P2530',1,'IOCTL_CALL','nvp6134_drv.c:431-438','ONLY_IF_USER_CALLS_IOC_VDEC_SET_CHNMODE','CH0 PAL 1080P2530 comparison branch')
call('CONDITIONAL_1080P2530',2,'COMMON_VALUE_WRITES','video.c:2068-2136','CH0_PAL_1080P2530','ordered CH0 common writes in private core ledger')
call('CONDITIONAL_1080P2530',3,'COMMON_FHD_WRITES_AND_RMW_READS','video.c:3386-3465','CH0_PAL_1080P2530','private core ledger','','BANK1_ED_AND_BANK9_44_UNKNOWN')
call('CONDITIONAL_1080P2530',4,'MODE_WRITES','video.c:3466-3535','CH0_PAL_1080P2530','private core ledger')
call('CONDITIONAL_1080P2530',5,'ACP_EACH_SETTING','acp.c:446-550','CH0_PAL_1080P2530','includes Bank5 2F/30/31/32/7C/7D and Bank3 writes')
call('CONDITIONAL_1080P2530',6,'ACP_BAUDRATE_BRANCH','acp.c:237-253','CH0_PAL_1080P2530','Bank5 7C then Bank3 configuration')
call('CONDITIONAL_1080P2530',7,'LOCAL_WAIT','acp.c:123','CH0_PAL_1080P2530','ACP clear assert',10)
call('CONDITIONAL_1080P2530',8,'LOCAL_WAIT','acp.c:125','CH0_PAL_1080P2530','ACP clear release',200)
call('CONDITIONAL_1080P2530',9,'EQ_INIT_WRITES','eq.c:78-139','CH0_PAL_1080P2530','Bank5 59 and C0/C1/C8; Bank0A 74')
call('CONDITIONAL_1080P2530',10,'LOCAL_WAIT','video.c:1173','CH0_PAL_1080P2530','after Bank9 post-mode write',35)
call('CONDITIONAL_1080P2530',11,'FINAL_BANK0_WRITE','video.c:1180-1181','CH0_PAL_1080P2530','Bank0 channel normal')
call('DETECTOR_IF_CALLED',1,'IOCTL_CALL','nvp6134_drv.c:405-414','ONLY_IF_USER_CALLS_IOC_VDEC_GET_INPUT_VIDEO_FMT','video_fmt_det; no hardware result assigned')
call('DETECTOR_IF_CALLED',2,'BANK_SELECT_THEN_READ_F_SERIES','video.c:400-406;636-642','DETECTOR_CALL_PATH','one 0xFF=05+ch select followed by F0 F2 F3 F4 F5 reads','','F_SERIES_VALUES_UNKNOWN','no new helper wait before each read')
video_lines=(refdir/'video.c').read_text(encoding='latin-1').splitlines()
for lineno in range(616,906):
    code=video_lines[lineno-1].split('//',1)[0]
    m=re.search(r'\bmsleep\((\d+)\)',code)
    if m:
        cond='DETECTOR_CALL_UNCONDITIONAL' if lineno==630 else 'READ_DEPENDENT_BRANCH_SYMBOLIC'
        call('DETECTOR_IF_CALLED',100+lineno,'LOCAL_WAIT',f'video.c:{lineno}',cond,'detector internal wait',int(m[1]),'DETECTOR_REGISTERS_UNKNOWN')
call('TRANSPORT_BRANCH',1,'PER_WRITE_HELPER_WAIT','nvp6134_drv.c:98-102','HI_I2C_SELECTED','after each write helper call; external write body unknown',0.2,'','microseconds represented here as 0.2 ms')
call('TRANSPORT_BRANCH',2,'PER_WRITE_HELPER_WAIT','nvp6134_drv.c:105-119','I2C_INTERNAL_SELECTED','after each write helper call; result ignored',0.3,'','microseconds represented here as 0.3 ms')
call('TRANSPORT_BRANCH',3,'MISSING_HELPER','common.h:18-39;Makefile:8-43','HI_GPIO_I2C_SELECTED','implementation outside pinned repository','','','wait unknown')
with (ROOT/'private/REFERENCE_CALL_ORDER_AND_WAITS.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=calls[0].keys());w.writeheader();w.writerows(calls)
print('reference call-order rows',len(calls),'direct path waits',sum(1 for x in calls if x['operation']=='LOCAL_WAIT'))
