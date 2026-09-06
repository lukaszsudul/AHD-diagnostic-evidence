import os,pathlib,json,struct,time,csv
P=pathlib.Path
root=P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z')
proof=json.loads((root/'logs/t1-proof.json').read_text());assert proof['result']=='PASS'
node=proof['user'];s=os.stat(node)
assert '0000:01:00.0' in str((P('/sys/dev/char')/f'{os.major(s.st_rdev)}:{os.minor(s.st_rdev)}'/'device').resolve())
fd=os.open(node,os.O_RDONLY|os.O_NOFOLLOW)
log=(root/'logs/mmio-raw.csv').open('x',newline='');writer=csv.writer(log);writer.writerow(['Timestamp','Phase','Node','BDF','Offset','Value'])
def read(offset):
 assert offset%4==0 and (0<=offset<=0x30 or 0x80<=offset<=0xb4 or 0x3800<=offset<=0x3858)
 raw=os.pread(fd,4,offset);assert len(raw)==4
 value=struct.unpack('<I',raw)[0];writer.writerow([time.time_ns(),'T2',node,proof['bdf'],hex(offset),hex(value)]);log.flush();return value
result={'identity':'NOT_REACHED','nvp':'NOT_REACHED','g2b':'NOT_REACHED','result':'BLOCKED'}
try:
 legacy={hex(x):read(x) for x in range(0,0x34,4)};result['legacy']=legacy
 expected={0:0xA40A0C07,4:0x400B,8:0x31002,12:0x10000,0x24:0x07E90002,0x28:6299465,0x2c:0x103,0x30:0x58444D41}
 for off,val in expected.items():assert legacy[hex(off)]==val,('RUNTIME_CANDIDATE_IDENTITY_MISMATCH',hex(off),hex(legacy[hex(off)]),hex(val))
 sha=''.join(f'{legacy[hex(x)]:08x}' for x in range(0x10,0x24,4));result['embedded_sha_words']=sha
 assert sha=='224d194e5f82c85bcb29297561c5d5e76d28063b',('RUNTIME_CANDIDATE_IDENTITY_MISMATCH',sha)
 result['identity']='PASS'
 t0=time.monotonic();before={hex(x):read(x) for x in range(0x80,0xb8,4) if x<=0xb4}
 time.sleep(3)
 after={hex(x):read(x) for x in (0x80,0x84,0x88)};dt=time.monotonic()-t0
 delta={x:(after[x]-before[x])&0xffffffff for x in after};ratio=delta['0x80']/max(1,delta['0x84'])
 result['nvp_values']=before;result['telemetry']={'seconds':dt,'delta':delta,'vclk_per_sav':ratio,'sav_per_second':delta['0x84']/dt}
 assert before['0x8c']&0x3f==0x39 and before['0x90']==0 and before['0x94']==0 and not(before['0x9c']&0x80000000),'FIXED_LIVE_AHD_SOURCE_NOT_READY'
 assert 5200<=ratio<=5360 and 20000<=delta['0x84']/dt<=35000,'FIXED_LIVE_AHD_SOURCE_NOT_READY'
 result['nvp']='PASS'
 g={hex(x):read(x) for x in range(0x3800,0x385c,4)};result['g2b_values']=g
 assert g['0x3800']==0x43324831 and g['0x3804']==0x10000 and g['0x3808']==0xb001f,'G2B_IDENTITY_MISMATCH'
 assert g['0x380c']==0 and not(g['0x3810']&0x100),'G2B_PRESESSION_STATE_NOT_READY'
 assert g['0x3810']&0xc0==0xc0,'FIXED_LIVE_AHD_SOURCE_NOT_READY'
 result['g2b']='PASS';result['result']='PASS'
except Exception as e:result['blocker']=str(e)
finally:
 os.close(fd);log.close();(root/'logs/t2-result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
