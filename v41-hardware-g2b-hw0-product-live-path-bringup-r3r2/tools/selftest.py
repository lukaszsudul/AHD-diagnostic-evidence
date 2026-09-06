import pathlib,tempfile,os,struct,json
import capture as c
from abi_v1 import AbiContract,RecordMetadata,build_record,StreamValidator
root=c.ROOT
contract=AbiContract.load(root/'scripts/V41_C2H_TRANSPORT_ABI_V1.json')
records=[build_record(contract,RecordMetadata(1,1,i,i+1,i,i),bytes([i])*3840) for i in range(3)]
whole=b''.join(records);pending=bytearray();out=[];position=0
for n in [1,63,97,3000,100,4099,4928]:
 pending.extend(whole[position:position+n]);position+=n
 while len(pending)>=4096:out.append(bytes(pending[:4096]));del pending[:4096]
assert position==len(whole) and not pending and out==records
validator=StreamValidator(contract,armed_epoch=1)
assert all(not validator.accept(r).discontinuity_reasons for r in records)
bad=bytearray(records[0]);bad[-1]=1
assert not StreamValidator(contract,armed_epoch=1).accept(bytes(bad)).structurally_valid
assert not c.quiescent(0,0xc6) and c.quiescent(0,0xc4)
assert not c.quiescent(0,0x1c4) and not c.quiescent(1,0xc4)
actual_pwrite=os.pwrite;calls=[]
os.pwrite=lambda fd,b,off:(calls.append((off,struct.unpack('<I',b)[0])) or 4)
temp=pathlib.Path(tempfile.mkdtemp(prefix='offline-write-tests-',dir=root/'artifacts'))
(temp/'logs').mkdir();c.ROOT=temp
m=c.MMIO.__new__(c.MMIO);m.session='T3';m.node='MOCK';m.proof={'bdf':'MOCK'};m.fd=-1;m.last_error_read=None
rejected=0
try:
 for off,val in [(0x380c,2),(0x380c,3),(0x380c,5),(0x380c,6),(0x380c,7),(0x383c,7),(0x383c,0x3f),(0x383c,0x40),(0x3844,0),(0x0,0),(0x385c,1)]:
  try:m.write(off,val,'TEST','TEST')
  except c.GateError:rejected+=1
  else:raise AssertionError('unauthorized accepted')
 assert not calls
 m.write(0x380c,4,'RESET','DISABLED');m.write(0x380c,1,'ENABLE','READY')
 for val in (4,1):
  try:m.write(0x380c,val,'RETRY','TEST')
  except c.GateError:rejected+=1
  else:raise AssertionError('retry accepted')
 m.last_error_read=8
 try:m.write(0x383c,0x38,'W1C','POST_RESET_QUIESCENT')
 except c.GateError:rejected+=1
 else:raise AssertionError('blanket mask accepted')
 m.write(0x383c,8,'W1C','POST_RESET_QUIESCENT')
 assert calls==[(0x380c,4),(0x380c,1),(0x383c,8)]
finally:os.pwrite=actual_pwrite;c.ROOT=root
result={'result':'PASS','hardware_access':False,'negative_policy_cases_rejected':rejected,'arbitrary_partial_boundaries':'PASS','corrupt_padding_detection':'PASS','frozen_parser':'PASS'}
(root/'logs/offline-selftest.json').write_text(json.dumps(result));print(json.dumps(result))
