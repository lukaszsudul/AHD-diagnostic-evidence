from pathlib import Path
import json,hashlib,subprocess,csv
R=Path(__file__).parent; S=Path('C:/FPGA/V41_G2B')
def git(*a): return subprocess.check_output(['git','-C',str(S),*a],text=True).strip()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest().upper()
assert (R/'SCOPE_PASS.marker').exists()
rows=list(csv.DictReader((R/'scope_resolved.csv').open()));assert len(rows)==9
assert all(x['Source_Count']=='56' and x['Destination_Count'] in ('3','4') for x in rows)
resolved=(R/'proposed_resolved.xdc').read_text()
bs=[l for l in resolved.splitlines() if l.startswith('set_bus_skew ')]
assert len(bs)==11, len(bs)
assert not any('release_generation_axi' in l or 'own_generation_hold_axi_reg[' in l and 'slot_state_source' in l for l in bs)
assert git('rev-parse','HEAD')=='bdae16e06fb5b8564763941f530e4ce9e28896c7'
assert not git('diff','--name-only') and not git('diff','--cached','--name-only')
old=(R/'original_g2b_cdc.xdc').read_bytes(); new=(R/'proposed_g2b_cdc.xdc').read_bytes(); target=S/'xdc/common/g2b_cdc.xdc'
assert target.read_bytes()==old
diff=(R/'scope.diff').read_text()
audit='# Active XDC scope audit — PASS\n\nOnly the three global release-slot 1–3 set_bus_skew commands are removed; the authoritative combined candidate is appended byte-for-byte. All other original bytes remain unchanged. Groups 1–8, 9, 10–12, 13 and 14, clocks, unrelated false paths and max delays, ABI/MMIO and R1i constraints are unchanged.\n\nThe fresh routed scope audit resolves nine checks: 56 source cells each and 3/4/3 destination cells per slot. The exported complete timing context retains exactly eleven current BUS_SKEW commands and no release-slot global relation. See scope_resolved.csv and proposed_resolved.xdc.\n\nComplete context reconstruction preserves base lines 1–54 and 85 onward and replaces exactly its G2B block (lines 55–84) with the proposed complete active g2b_cdc.xdc; all non-G2B timing commands remain byte-equivalent after newline normalization.\n\n```diff\n'+diff+'\n```\n'
(R/'G2B_LUT1_RECOVERY4_XDC_DIFF.md').write_text(audit)
target.write_bytes(new)
assert git('diff','--name-only')=='xdc/common/g2b_cdc.xdc'
subprocess.run(['git','-C',str(S),'diff','--check'],check=True)
subprocess.run(['git','-C',str(S),'add','--','xdc/common/g2b_cdc.xdc'],check=True)
subprocess.run(['git','-C',str(S),'commit','-m','Implement META-7 Groups 15-17 release-slot sign-off constraints'],check=True)
d={'branch':git('branch','--show-current'),'parent':git('rev-parse','HEAD^'),'commit':git('rev-parse','HEAD'),'tree':git('rev-parse','HEAD^{tree}'),'changed':git('diff-tree','--no-commit-id','--name-only','-r','HEAD'),'stat':git('show','--stat','--format=','HEAD'),'tracked':git('diff','--name-only'),'index':git('diff','--cached','--name-only'),'xdc_sha256':sha(target)}
assert not d['tracked'] and not d['index'];assert d['parent']=='bdae16e06fb5b8564763941f530e4ce9e28896c7'
(R/'source.json').write_text(json.dumps(d,indent=2));(R/'G2B_LUT1_RECOVERY4_SOURCE_CHANGE_RECEIPT.md').write_text('# Governed source commit\n\n```json\n'+json.dumps(d,indent=2)+'\n```\n')
(R/'commit_ready.marker').write_text(d['commit'])
print(json.dumps(d,indent=2))
