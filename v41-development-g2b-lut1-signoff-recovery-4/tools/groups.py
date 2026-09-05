from pathlib import Path
import csv,re,hashlib,shutil,subprocess,json
R=Path(__file__).parent; E=Path('C:/FPGA/V41_G2B_EVIDENCE');B=Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12/BUS_SKEW_GROUPS')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def commit(folder):return subprocess.check_output(['git','-C',str(E),'log','-1','--format=%H','--',folder],text=True).strip()
def read(p):return list(csv.DictReader(p.open(encoding='utf-8-sig')))
columns='Group Name Current_Governed_Method Result Result_Source Fresh_or_Preserved Evidence_Commit Required_Value Actual_Value Slack Runtime Disposition'.split()
rows=[];details=[];P=R/'preserved_groups';P.mkdir(exist_ok=True)
for g in range(1,9):
 p=next(B.glob(f'{g:02d}_*_BUS_SKEW.rpt'));t=p.read_text();m=re.search(r'\b(?:Slow|Fast)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(-?\d+\.\d+)',t);assert m,p
 req,actual,slack=m.groups(); assert float(slack)>=0
 obj=next(B.glob(f'{g:02d}_*_OBJECTS.txt')); lines=obj.read_text().splitlines()
 nsrc=sum(l.startswith('SOURCE=') for l in lines);ndst=sum(l.startswith('DESTINATION=') for l in lines)
 name=p.name[3:-len('_BUS_SKEW.rpt')]
 for f in (p,obj):shutil.copyfile(f,P/f.name)
 iso=next(B.glob(f'{g:02d}_*_ISOLATED.xdc'));shutil.copyfile(iso,P/iso.name)
 rows.append([g,name,'BUS_SKEW','PRESERVED_PASS',str(p),'PRESERVED',commit('v41-development-g2b-lut1-signoff-recovery'),req,actual,slack,'PRESERVED_RAW_REPORT','Accepted Gen12 physical result; exact raw artifact sealed in this package; recovery-1 preservation authority'])
 details.append({'group':g,'name':name,'src_count':nsrc,'dst_count':ndst,'report_sha256':sha(p),'objects_sha256':sha(obj),'constraint_sha256':sha(iso),'slack':slack})
for g,folder,file in [(9,'v41-development-g2b-lut1-signoff-recovery','G2B_LUT1_GROUP9_SIGNOFF_RESULTS.csv'),(13,'v41-development-g2b-lut1-signoff-recovery-2','G2B_LUT1_GROUP13_SIGNOFF_RESULTS.csv'),(14,'v41-development-g2b-lut1-signoff-recovery-3','G2B_LUT1_GROUP14_SIGNOFF_RESULTS.csv')]:
 p=E/folder/file;rr=read(p); assert all(x['Result']=='PASS' for x in rr)
 shutil.copyfile(p,P/p.name)
 actual=';'.join(x.get('Actual_Worst_ns',x.get('Worst_Actual_ns','')) for x in rr)
 rows.append([g,{9:'OWNERSHIP_AXI_TO_SOURCE',13:'RESET_RETURN_SOURCE_TO_AXI',14:'RELEASE_SLOT_0_AXI_TO_SOURCE'}[g],'PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC' if g==9 else 'SETTLING_PLUS_STRUCTURAL_CDC','PRESERVED_PASS',str(p),'PRESERVED',commit(folder),'6.000',actual,';'.join(x['Slack_ns'] for x in rr),';'.join(x.get('Runtime_s','PRESERVED') for x in rr),'All semantic families PASS; exact sealed routed DCP and unchanged collections'])
p=E/'v41-development-g2b-lut1-signoff-recovery/G2B_LUT1_GROUPS10_17_RESULTS.csv'
for x in read(p):
 g=int(x['Group_ID'])
 if g not in (10,11,12):continue
 assert x['Result']=='PASS';rows.append([g,x['Name'],'BUS_SKEW','PRESERVED_PASS',str(p),'PRESERVED',commit('v41-development-g2b-lut1-signoff-recovery'),x['Required_ns'],x.get('Actual_ns',x.get('Actual_Worst_ns','')),x['Slack_ns'],x.get('Runtime_s',''),'Current governed relation unchanged'])
 details.append({'group':g,'name':x['Name'],'src_count':int(x['Source_Count']),'dst_count':int(x['Destination_Count']),'slack':x['Slack_ns']})
fresh=R/'G2B_LUT1_RECOVERY4_GROUPS15_17_RESULTS.csv'; fr=read(fresh) if fresh.exists() else []
for g in (15,16,17):
 rr=[x for x in fr if int(x['Group'])==g];passed=len(rr)==3 and all(x['Result']=='PASS' for x in rr)
 rows.append([g,f'RELEASE_SLOT_{g-14}_AXI_TO_SOURCE','SETTLING_PLUS_STRUCTURAL_CDC','FRESH_PASS' if passed else 'NOT_REACHED',fresh.name,'FRESH','THIS_PACKAGE','6.000',';'.join(x['Actual_Worst_ns'] for x in rr),';'.join(x['Slack_ns'] for x in rr),';'.join(x['Runtime_s'] for x in rr),'Three slot-specific semantic families; physical symmetry not assumed'])
with (R/'G2B_LUT1_RECOVERY4_ALL_GROUPS_MATRIX.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(columns);w.writerows(sorted(rows,key=lambda x:x[0]))
(R/'preserved_group_details.json').write_text(json.dumps(details,indent=2))
print(json.dumps(details,indent=2))
