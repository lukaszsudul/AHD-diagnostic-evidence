from pathlib import Path
import subprocess,hashlib,json,datetime,difflib
R=Path(__file__).parent; S=Path('C:/FPGA/V41_G2B'); E=Path('C:/FPGA/V41_G2B_EVIDENCE')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def git(p,*a): return subprocess.check_output(['git','-C',str(p),*a],text=True).strip()
def snap(p): return {k:git(p,*v) for k,v in {'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'tree':['rev-parse','HEAD^{tree}'],'status':['status','--porcelain=v1'],'tracked':['diff','--name-only'],'index':['diff','--cached','--name-only']}.items()}
state={'start':datetime.datetime.now().isoformat(),'source':snap(S),'primary':snap(Path('C:/FPGA/FPGA_AHD')),'worktrees':git(S,'worktree','list','--porcelain')}
assert state['source']['head']=='bdae16e06fb5b8564763941f530e4ce9e28896c7'
assert state['source']['tree']=='e18833d46f7672f851c3cb8239f2f29091378294'
assert not state['source']['tracked'] and not state['source']['index']
D=Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp')
assert D.stat().st_size==57900063 and sha(D)=='EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
state['dcp']={'path':str(D),'sha256':sha(D),'size':D.stat().st_size}
M=D.with_name('G2B_BUILD_INPUT_SHA256.txt'); rows=[]
for line in M.read_text().splitlines():
 p,h=line.split('|'); actual=sha(S/p); rows.append({'path':p,'sealed':h,'current':actual,'match':actual==h})
assert len(rows)==35 and all(x['match'] for x in rows if x['path']!='xdc/common/g2b_cdc.xdc')
state['build_inputs']=rows
state['ssot_hashes']={str(p.relative_to(E)):sha(p) for p in (E/'project-current-state').rglob('*') if p.is_file()}
(R/'start.json').write_text(json.dumps(state,indent=2))
(R/'G2B_LUT1_RECOVERY4_START_RECEIPT.md').write_text('# Recovery 4 start receipt\n\n'+json.dumps(state,indent=2)+'\n')
X=S/'xdc/common/g2b_cdc.xdc'; old=X.read_bytes(); candidate=(E/'v41-development-g2b-g15-17-release-slot-equivalence-audit/G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc').read_bytes()
assert sha(X)=='49CE028909F25303807E85E8835BD3379F1C6965EC302E08812105C280736C4A'
(R/'original_g2b_cdc.xdc').write_bytes(old)
new=old
for slot in range(1,4):
 line=f'set_bus_skew 3.000 -from $g2b_release{slot}_payload_src -to $g2b_release_payload_dst'.encode()
 assert new.count(line)==1
 new=new.replace(line+b'\n',b'') if line+b'\n' in new else new.replace(line+b'\r\n',b'')
new+=b'\n'+candidate
(R/'proposed_g2b_cdc.xdc').write_bytes(new)
assert new.endswith(candidate)
base=(E/'v41-development-g2b-g13a-reset-return-signoff-audit/raw/timing/G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc').read_text().splitlines(True)
assert base[54].startswith('set_false_path') and 'G2B_ONECH_C2H' in base[54]
assert base[83].startswith('set_bus_skew') and base[84].startswith('current_instance CAPTURE')
removed=base[54:84]; kept=base[:54]+base[84:]
assert not any('G2B_ONECH_C2H' in l for l in kept)
(R/'non_g2b_context.xdc').write_text(''.join(kept))
(R/'removed_legacy_g2b_context.xdc').write_text(''.join(removed))
(R/'scope.diff').write_text(''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile='original',tofile='proposed')))
print(json.dumps({'runtime':str(R),'dcp_verified':True,'build_rows':len(rows),'non_xdc_exact':34,'proposed_sha':sha(R/'proposed_g2b_cdc.xdc')}))
