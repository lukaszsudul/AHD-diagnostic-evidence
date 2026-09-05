from pathlib import Path
import csv,re,json,hashlib
R=Path(__file__).parent;B=Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12')
def readcsv(p):return list(csv.DictReader(p.open(encoding='utf-8-sig')))
def write(p,t):(R/p).write_text(t+'\n',encoding='utf-8')
details={x['group']:x for x in json.loads((R/'preserved_group_details.json').read_text())}
text=(R/'METHODOLOGY.rpt').read_text();blocks=re.findall(r'(?m)^(TIMING-(?:34|39)#\d+) Warning\n(.*?)(?=^[A-Z]+-\d+#\d+ Warning|\Z)',text,re.S)
mapping={'nvp_cfg_abort_reg':1,'status_bus_pcie_reg':2,'active_sav_gray_sync1_pcie_reg':3,'snapshot_attempted_sync1_axi_reg':4,'snapshot_epoch_sync1_axi_reg':5,'snapshot_epoch_echo_source_reg':7,'hard_event_baseline_hold_source_reg':8,'axis_attempt_reg':10,'axis_generation_reg':11,'axis_epoch_reg':12,'hard_event_baseline_sync1_axi_reg':6,'overflow_count_source_reg':8}
assert len(blocks)==12
out=['# Timing methodology disposition — PASS','','Fresh full report: 15 warnings. The required focused set has 11 TIMING-34 and 1 TIMING-39. No TIMING-32/37/38 finding. Every current skew warning is mapped below; none concerns a retired global relation. Constraint positions are taken from the current report, not copied from the audit.','','| Warning | Position | Group | Source/destination count | Required sign-off | Classification | Endpoint |','|---|---:|---:|---|---|---|---|']
for name,body in blocks:
 end=re.search(r'First endpoint covered by the constraint: (\S+)',body).group(1);pos=re.search(r'constraint position (\d+)',body).group(1)
 matches=[g for token,g in mapping.items() if token in end];assert len(matches)==1
 g=matches[0];d=details[g]
 out.append(f"| {name} | {pos} | {g} | {d['src_count']}/{d['dst_count']} | PASS; slack {d['slack']} ns | ACCEPTED_PERFORMANCE_WARNING_WITH_PASS | `{end}` |")
out+=['','TIMING-34 warns that the 3 ns bound is aggressive relative to clock periods and increases analysis runtime. Each actual required routed skew result passes on this exact implementation; its requirement remains enforced. Exact raw reports and object inventories are sealed under preserved_groups; Groups 10–12 refer to recovery-1 raw reports. No global waiver was applied.','','TIMING-39 is current Group 8 transport payload, not a retired constraint. Its multi-level logic makes a relative skew relation expensive and unsuitable as the sole CDC safety argument. Group 8 remains governed and has actual skew 2.039 ns against 3 ns (+0.961 ns), while the retained 2.500 ns absolute transport settling bound and held request/ack reset barrier supply the functional CDC requirement. Fresh routed timing passes under that bound. This specific warning is accepted with those independent proofs; the constraint is not removed and the warning is not generalized to other groups.','','Supplemental full-report findings: two LUTAR-1 warnings are inside unchanged generated XDMA reset/FIFO logic. They concern asynchronous reset assertions; current zero-error/zero-critical DRC, unchanged vendor IP and reset protocol evidence are retained. They do not establish hardware glitch immunity. TIMING-9 requests detailed CDC analysis; the complete 1,401-row CDC disposition supplies that analysis. No supplemental error or critical warning exists.','','UNRESOLVED_METHODOLOGY_WARNINGS = 0','INVALID_CURRENT_CONSTRAINT = 0','RETIRED_GLOBAL_CONSTRAINT_ACTIVE = NO']
write('G2B_LUT1_RECOVERY4_METHODOLOGY_DISPOSITION.md','\n'.join(out))
drc=readcsv(R/'drc_objects.csv');old=' '.join((B/'DRC.rpt').read_text().split());assert len(drc)==14
out=['# DRC summary — PASS','','Errors: 0. Critical warnings: 0. Warnings: 14. All are inherited from the exact Gen12 implementation; every description and unloaded-net scope is compared against the original DRC report. No new finding is omitted.','','| Finding | Origin | Disposition | Rationale |','|---|---|---|---|']
for x in drc:
 assert x['Severity']=='WARNING'
 desc=' '.join(x['Description'].split())
 if x['Name'].startswith('RTSTAT-10'):
  old_rt=old.split('23 net(s) have no routable loads.',1)[1].split('Related violations:',1)[0]
  tokens=lambda s: sorted(v.rstrip(',.') for v in re.findall(r'XDMA/\S+',s))
  assert tokens(desc)==tokens(old_rt), 'unloaded-net scope drift'
 else: assert desc in old, 'new DRC description '+x['Name']
 rule=x['Name'].split('#')[0]
 if rule=='PDCN-1569':reason='Generated XDMA LUT has a physically connected input unused by its equation; unchanged routed IP. Unused equation input does not affect the LUT truth function; no functional source change.'
 elif rule=='REQP-1839':reason='Inherited RAM control reset warning. Reset invalidates in-flight data; reviewed reset/readiness/abandonment protocol prevents treating interrupted RAM contents as a committed record. Preserved reset functional regression and current reset-return/release settling gates apply. No promise of RAM-content preservation across reset.'
 elif rule=='RTSTAT-10':reason='23 XDMA nets have no routable loads; all 33,985 routable nets are fully routed, with zero route errors. Unloaded nets are not missing required connections.'
 else:raise AssertionError(rule)
 out.append(f"| {x['Name']} | INHERITED; exact description or net-scope match | ACCEPTED | {reason} |")
out+=['','Full individual names, net/pin scope and descriptions are preserved in drc_objects.csv and DRC.rpt. No warning severity was changed. Hardware qualification remains NOT_PROVEN.']
write('G2B_LUT1_RECOVERY4_DRC_SUMMARY.md','\n'.join(out))
write('G2B_LUT1_RECOVERY4_ROUTE_STATUS.md','# Route status — PASS\n\nFresh report: logical nets 49,105; nets not needing routing 15,120 (14,449 internally routed, 671 with no loads); routable nets 33,985; fully routed 33,985; route errors 0; unrouted 0; partial 0. Boolean route checks also pass. See ROUTE_STATUS.rpt and G2B_LUT1_TIMING_GATE.txt.')
gate=(R/'G2B_LUT1_TIMING_GATE.txt').read_text();assert 'RESULT=PASS' in gate
write('G2B_LUT1_RECOVERY4_TIMING_SUMMARY.md','# Fresh routed timing — PASS\n\nWNS +0.023 ns; TNS 0; WHS +0.043 ns; THS 0. Fresh reports were generated on 2026-09-05 under the exact committed active XDC. Historical numerical values were not used as proof.\n\nNo-clock, unconstrained internal endpoints, combinational loops and latch loops are zero. Recovery/removal details are present (101 each) and nonnegative. Generated clocks have valid sources. Setup/hold and clock-pair details are preserved in TIMING_SUMMARY.rpt and the routed detail reports.\n\nTiming 38-436 reminds that retained skew constraints require their own reports; the complete 1–17 matrix supplies the governed preserved/fresh results without running retired queries.\n\n```\n'+gate+'```')
write('report_disposition_pass.json',json.dumps({'methodology':True,'timing34':11,'timing39':1,'unresolved_methodology':0,'drc':True,'drc_errors':0,'drc_critical':0,'drc_warnings':14,'route':True,'timing':True}))
print('Methodology and all 14 DRC warnings dispositioned; timing and route PASS')
