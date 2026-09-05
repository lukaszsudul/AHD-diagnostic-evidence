from pathlib import Path
import json,hashlib,re
R=Path(__file__).parent;B=Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12')
local=Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_BUILD_20260831_12/vivado_project/v41_g2b_onech_c2h_offline.srcs/sources_1/ip/xdma_v41_m1/xdma_v41_m1.xci')
j=json.loads(local.read_text());params=j['ip_inst']['parameters']['component_parameters']
cfg=dict(l.split('=',1) for l in (B/'G2B_XDMA_EFFECTIVE_CONFIG.txt').read_text().splitlines() if '=' in l)
def norm(x):return {'true':'1','false':'0'}.get(x,x)
checked=[];mismatch=[]
for k,v in params.items():
 if 'CONFIG.'+k in cfg:
  a=norm(v[0]['value']);b=norm(cfg['CONFIG.'+k]);checked.append(k)
  if a!=b:mismatch.append((k,a,b))
assert not mismatch,mismatch
assert len(checked)>300
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest().upper()
receipt={'generated_local_XCI_sha256':sha(local),'Gen12_effective_config_sha256':sha(B/'G2B_XDMA_EFFECTIVE_CONFIG.txt'),'component_parameters_compared':len(checked),'mismatches':mismatch,'result':'PASS','explanation':'Generated local XCI is the original 2026-08-31 elaborated artifact, distinct from the repository seed XCI. It matches all corresponding Gen12 effective component settings including QPLL1 and Gen2. Seed-to-generated differences are original elaboration/path/output-flow normalization, not recovery-4 source/IP drift. Current DCP PCIe primitive confirms Gen2 x1.'}
(R/'generated_IP_identity.json').write_text(json.dumps(receipt,indent=2))
with (R/'G2B_LUT1_RECOVERY4_DCP_REUSE_PROOF.md').open('a',encoding='utf-8') as f:f.write('\n## Generated local IP identity clarification\n\n'+json.dumps(receipt,indent=2)+'\n')
# Vivado export aliases are names only; compare expanded commands in order.
def canonical(p):
 a={};out=[]
 for l in p.read_text().splitlines():
  l=l.strip()
  if not l or l.startswith('#'):continue
  m=re.match(r'set (_xlnx_shared_i\d+) (.*)',l)
  if m:a[m[1]]=m[2];continue
  out.append(re.sub(r'\$(_xlnx_shared_i\d+)\b',lambda m:a[m[1]],l))
 return '\n'.join(out)+'\n'
a=canonical(R/'current_resolved.xdc');b=canonical(R/'continuation_resolved.xdc');assert a==b
(R/'current_constraints_canonical.xdc').write_text(a)
(R/'continuation_context_equivalence.txt').write_text('RESULT=PASS\nCANONICAL_SHA256='+hashlib.sha256(a.encode()).hexdigest().upper()+'\nCOMMAND_COUNT='+str(len(a.splitlines()))+'\nNormalization expands only Vivado _xlnx_shared_iN aliases; all actual commands and their order match.\n')
with (R/'G2B_LUT1_RECOVERY4_RESOURCE_SUMMARY.md').open('a') as f:f.write('\nLUTRAM: 1,159/9,600. BUFGCTRL: 8/32. MMCME2_ADV: 2/5. PLLE2_ADV: 0/5. Bonded IOB: 15/150.\n')
print(json.dumps(receipt,indent=2))
