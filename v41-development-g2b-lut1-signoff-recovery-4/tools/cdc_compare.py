from pathlib import Path
import re,hashlib,json,collections
R=Path(__file__).parent
def parse(p):
 rows=[];src=dst=''
 for l in p.read_text().splitlines():
  if l.startswith('Source Clock:'):src=l.split(':',1)[1].strip()
  if l.startswith('Destination Clock:'):dst=l.split(':',1)[1].strip()
  m=re.match(r'^\s*\d+\s+(CDC-\d+)\s+(Critical|Warning|Info)\s+(.+?)\s{2,}(\d+)\s{2,}(.+?)\s{2,}(\S+)\s+(\S+)\s*$',l)
  if m:
   rule,sev,description,depth,exception,start,end=m.groups();rows.append((rule,src+'->'+dst,exception,start,end,sev,depth,description))
 return rows
old=parse(Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12/CDC.rpt'));new=parse(R/'CDC.rpt')
def canon(rows,rule):return sorted('|'.join(x[:5]) for x in rows if x[0]==rule)
diff={}
for rule in ['CDC-1','CDC-3','CDC-6','CDC-9','CDC-10','CDC-13','CDC-15']:
 a=canon(old,rule);b=canon(new,rule)
 diff[rule]={'old_count':len(a),'new_count':len(b),'old_hash':hashlib.sha256(('\n'.join(a)+'\n').encode()).hexdigest().upper(),'new_hash':hashlib.sha256(('\n'.join(b)+'\n').encode()).hexdigest().upper(),'removed':sorted(set(a)-set(b)),'added':sorted(set(b)-set(a))}
(R/'cdc_comparison.json').write_text(json.dumps(diff,indent=2));(R/'cdc_rows.json').write_text(json.dumps(new,indent=2))
print(json.dumps(diff,indent=2))
