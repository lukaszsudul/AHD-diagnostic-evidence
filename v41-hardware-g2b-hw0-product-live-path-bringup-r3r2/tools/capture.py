"""R3R2 bounded capture: exact session reset, audited MMIO, frozen ABI parser."""
import os,sys,json,time,struct,csv,pathlib,hashlib,mmap,signal,multiprocessing as mp,queue,stat,traceback
from abi_v1 import AbiContract,StreamValidator,FrameAssembler
P=pathlib.Path
ROOT=P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z')
ABI_SHA='AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6'
COLS=['Timestamp','Session','Node','BDF','Offset','Value','Purpose','Authorized','Precondition','Result']
class GateError(Exception):pass
def require(test,msg):
 if not test:raise GateError(msg)
def save(name,value):
 (ROOT/'logs'/name).write_text(json.dumps(value,indent=2)+'\n')
def quiescent(control,status):return control==0 and status&0x10f==4
class MMIO:
 def __init__(self,session):
  self.session=session;self.proof=json.loads((ROOT/'logs/t1-proof.json').read_text());require(self.proof['result']=='PASS','NODE_PROOF_REQUIRED')
  lock=json.loads(P('/tmp/ahd-g2b-hw0-product-r3r2-20260906T182010Z.lock/receipt.json').read_text());require(lock['state']=='HELD','LOCK_REQUIRED')
  require(P('/proc/sys/kernel/random/boot_id').read_text().strip()==lock['boot'],'BOOT_CHANGED')
  self.node=self.proof['user'];st=os.stat(self.node);require(stat.S_ISCHR(st.st_mode),'USER_NOT_CHAR')
  require(self.proof['bdf'] in str((P('/sys/dev/char')/f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}'/'device').resolve()),'NODE_PROOF_CHANGED')
  self.fd=os.open(self.node,os.O_RDWR|os.O_NOFOLLOW);self.last_error_read=None
 def close(self):
  if self.fd>=0:os.close(self.fd);self.fd=-1
 def read(self,off):
  require(off%4==0 and (0<=off<=0x30 or 0x80<=off<=0xb4 or 0x3800<=off<=0x3858),'READ_ALLOWLIST')
  b=os.pread(self.fd,4,off);require(len(b)==4,'SHORT_MMIO_READ');v=struct.unpack('<I',b)[0]
  if off==0x383c:self.last_error_read=v
  with (ROOT/'logs/mmio-raw.csv').open('a',newline='') as f:csv.writer(f).writerow([time.time_ns(),self.session,self.node,self.proof['bdf'],hex(off),hex(v)])
  return v
 def write(self,off,val,purpose,precondition):
  allowed=(off==0x380c and val in (0,1,4)) or (off==0x3844 and val==1) or (off==0x383c and val in (8,16,24,32,40,48,56))
  require(allowed,'MMIO_WRITE_ALLOWLIST_VIOLATION')
  ledger=ROOT/'logs/mmio-write-ledger.csv'
  rows=list(csv.DictReader(ledger.open())) if ledger.exists() else []
  prior=[r for r in rows if r['Result'] in ('INTENT','PASS')]
  if off==0x380c and val in (1,4):
   matching=[r for r in prior if int(r['Offset'],16)==off and int(r['Value'],16)==val]
   require(len(matching)<3 and not any(r['Session']==self.session for r in matching),'SESSION_WRITE_BUDGET_EXCEEDED')
  if off==0x383c:
   matching=[r for r in prior if int(r['Offset'],16)==off]
   require(len(matching)<3 and not any(r['Session']==self.session for r in matching),'W1C_BUDGET_EXCEEDED')
   require(self.last_error_read is not None and val==(self.last_error_read&0x38),'W1C_MASK_MISMATCH')
   require(precondition=='POST_RESET_QUIESCENT','W1C_PRECONDITION')
  row=[time.time_ns(),self.session,self.node,self.proof['bdf'],f'0x{off:04X}',f'0x{val:08X}',purpose,'YES',precondition,'INTENT']
  fresh=not ledger.exists()
  with ledger.open('a',newline='') as f:
   w=csv.writer(f)
   if fresh:w.writerow(COLS)
   w.writerow(row);f.flush()
   n=os.pwrite(self.fd,struct.pack('<I',val),off)
   require(n==4,'SHORT_MMIO_WRITE')
  # One ledger row per attempt; separate completion journal avoids double counting.
  with (ROOT/'logs/write-completions.jsonl').open('a') as f:f.write(json.dumps({'timestamp':time.time_ns(),'session':self.session,'offset':off,'value':val,'bytes':n,'result':'PASS'})+'\n')
 def snapshot(self):
  epoch=self.read(0x3838);gen=self.read(0x384c)
  require(not(self.read(0x3810)&0x300),'SNAPSHOT_BUSY')
  self.write(0x3844,1,'COHERENT_SNAPSHOT','RESET_AND_SNAPSHOT_NOT_BUSY')
  deadline=time.monotonic()+2
  while self.read(0x3848)&3!=2:
   require(time.monotonic()<deadline,'SNAPSHOT_TIMEOUT');time.sleep(.001)
  data={hex(o):self.read(o) for o in list(range(0x3814,0x3838,4))+[0x3850,0x3854,0x3858]}
  require(self.read(0x3838)==epoch and self.read(0x384c)==((gen+1)&0xffffffff) and self.read(0x3848)&3==2,'SNAPSHOT_COHERENCY')
  data.update(epoch=epoch,generation=(gen+1)&0xffffffff);return data
class ReadTimeout(Exception):pass
def alarm(*_):raise ReadTimeout('C2H_READ_DEADLINE')
def reader_worker(session,node,ready,enabled,stop,q):
 mm=None;fd=-1;buffer=None;pending=bytearray();count=0;result={'session':session,'result':'BLOCKED','records':0,'quiescent':False};t_enable=None
 try:
  mm=MMIO(session);st=os.stat(node);require(stat.S_ISCHR(st.st_mode),'C2H_NOT_CHAR')
  require(mm.proof['bdf'] in str((P('/sys/dev/char')/f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}'/'device').resolve()),'C2H_PROOF_CHANGED')
  fd=os.open(node,os.O_RDONLY|os.O_NOFOLLOW);buffer=mmap.mmap(-1,64*4096)
  signal.signal(signal.SIGALRM,alarm);signal.siginterrupt(signal.SIGALRM,True)
  # All allocation and receipt I/O precedes READER_READY. The next action is
  # the blocking read; the parent supplies the actual enable-completion clock.
  t_enable=time.monotonic()
  save(session+'-reader-ready.json',{'ready':True,'pid':os.getpid(),'node':node,'armed_monotonic':t_enable})
  ready.set()
  target={'T3':1,'T4':2500,'T5':None}[session];limit={'T3':10,'T4':30,'T5':66}[session]
  primary=True;drain_deadline=None
  while True:
   now=time.monotonic()
   if enabled.value>0:t_enable=enabled.value
   if primary and (stop.is_set() or (target is not None and count>=target) or (session=='T5' and now-t_enable>=65)):
    mm.write(0x380c,0,'NORMAL_DISABLE' if not stop.is_set() else 'SAFETY_DISABLE','SESSION_ENABLED')
    primary=False;drain_deadline=time.monotonic()+5
    result['disable_monotonic']=time.monotonic()
   if not primary:
    ctrl=mm.read(0x380c);status=mm.read(0x3810)
    if quiescent(ctrl,status):
     require(not pending,'PARTIAL_RECORD_AT_QUIESCENCE');result['quiescent']=True;break
    require(time.monotonic()<drain_deadline,'DRAIN_TIMEOUT')
   else:require(now-t_enable<limit,'PRIMARY_CAPTURE_TIMEOUT')
   nr=min(64,target-count) if primary and target is not None else (64 if primary else 1)
   view=memoryview(buffer)[:nr*4096]
   signal.setitimer(signal.ITIMER_REAL,min(2.0,max(.001,(t_enable+limit-time.monotonic()) if primary else drain_deadline-time.monotonic())))
   try:n=os.readv(fd,[view])
   finally:signal.setitimer(signal.ITIMER_REAL,0);view.release()
   require(n>0,'EMPTY_C2H_READ')
   pending.extend(buffer[:n]);complete=len(pending)//4096;chunk=bytes(pending[:complete*4096]);del pending[:complete*4096]
   ts=time.monotonic()
   if complete:
    count+=complete
    if primary and target is not None and count>=target:
     mm.write(0x380c,0,'NORMAL_DISABLE','PRIMARY_RECORD_COUNT_REACHED');primary=False;drain_deadline=time.monotonic()+5;result['disable_monotonic']=time.monotonic()
    try:q.put(('data',ts,chunk),timeout=.1)
    except queue.Full:raise GateError('BOUNDED_VALIDATOR_QUEUE_FULL')
  result.update(result='PASS',records=count,origin=t_enable)
 except BaseException as e:
  result['blocker']=str(e)
  if mm:
   try:
    if mm.read(0x380c)&1:mm.write(0x380c,0,'SAFETY_DISABLE','POST_ENABLE_FAILURE')
    result['quiescent']=quiescent(mm.read(0x380c),mm.read(0x3810))
   except Exception as cleanup:result['cleanup_error']=str(cleanup)
 finally:
  signal.setitimer(signal.ITIMER_REAL,0)
  if fd>=0:os.close(fd)
  if buffer is not None:buffer.close()
  if mm:mm.close()
  result['records']=count;save(session+'-reader-result.json',result)
  q.put(('done',time.monotonic(),result))

def START_C2H_CAPTURE_SESSION(session,selected_user,selected_c2h):
 require(session in ('T3','T4','T5'),'SESSION_NAME')
 with (ROOT/'logs'/f'{session}-start-once.json').open('x') as f:json.dump({'session':session,'started':time.time_ns()},f)
 mm=MMIO(session);receipt={'session':session,'fatal_w1c':None,'reader_attached':False,'result':'BLOCKED'}
 try:
  require(mm.node==selected_user and mm.proof['c2h']==selected_c2h,'NODE_SELECTION_CHANGED')
  for proc in P('/proc').iterdir():
   if not proc.name.isdigit():continue
   try:
    for f in (proc/'fd').iterdir():
     try:require(os.readlink(f)!=selected_c2h,'C2H_READER_ALREADY_ATTACHED')
     except FileNotFoundError:pass
   except (PermissionError,FileNotFoundError):pass
  ctrl=mm.read(0x380c);status=mm.read(0x3810);require(not(status&0x100),'RESET_ALREADY_BUSY')
  if ctrl&1:mm.write(0x380c,0,'SAFETY_DISABLE','UNEXPECTED_PRESESSION_ENABLE');receipt['unexpected_enable']=True
  deadline=time.monotonic()+5
  while mm.read(0x380c)&1:require(time.monotonic()<deadline,'DISABLE_TIMEOUT');time.sleep(.001)
  receipt['pre']={hex(o):mm.read(o) for o in (0x380c,0x3810,0x3838,0x383c,0x3840)}
  save(session+'-session-start.json',receipt)
  mm.write(0x380c,4,'RESET_STREAM_STATE','DISABLED_NO_READER_NOT_RESET_BUSY')
  deadline=time.monotonic()+5
  while not quiescent(mm.read(0x380c),mm.read(0x3810)):
   require(time.monotonic()<deadline,'C2H_SESSION_RESET_TIMEOUT');time.sleep(.001)
  epoch=mm.read(0x3838);receipt['post_epoch']=epoch
  require(epoch==((receipt['pre']['0x3838']+1)&0xffffffff),'C2H_SESSION_EPOCH_TRANSITION_INVALID')
  err=mm.read(0x383c);receipt['post_error']=err;receipt['fatal_mask']=err&0x38
  if err&0x38:
   require(quiescent(mm.read(0x380c),mm.read(0x3810)),'POST_RESET_NOT_QUIESCENT')
   err=mm.read(0x383c);receipt['fatal_mask']=err&0x38
   if err&0x38:
    mm.write(0x383c,err&0x38,'POST_RESET_FATAL_W1C','POST_RESET_QUIESCENT');receipt['fatal_w1c']=err&0x38
   err=mm.read(0x383c);require(not(err&0x38),'POST_RESET_FATAL_W1C_DID_NOT_CLEAR')
  require(not(err&7),'NONCLEAN_NONFATAL_ERROR_STATUS_AFTER_RESET')
  status=mm.read(0x3810)
  require(quiescent(mm.read(0x380c),status) and status&0xc0==0xc0 and not(status&0x800),'FINAL_PRE_ENABLE_BASELINE_FAILED')
  require(mm.read(0x3838)==epoch,'UNEXPECTED_EPOCH_CHANGE')
  baseline=mm.snapshot();receipt['baseline']=baseline
  ctx=mp.get_context('spawn');ready=ctx.Event();enabled=ctx.Value('d',0.0);stop=ctx.Event();q=ctx.Queue(maxsize=32)
  child=ctx.Process(target=reader_worker,args=(session,selected_c2h,ready,enabled,stop,q));child.start()
  require(ready.wait(5),'READER_READY_TIMEOUT');receipt['reader_attached']=True
  mm.write(0x380c,1,'ENABLE_C2H','RESET_EPOCH_BASELINE_PASS_READER_READY');receipt['enable_monotonic']=time.monotonic();enabled.value=receipt['enable_monotonic']
  receipt['result']='PASS';save(session+'-session-start.json',receipt)
  return epoch,baseline,child,q,stop,receipt
 except Exception as e:receipt['blocker']=str(e);save(session+'-session-start.json',receipt);raise
 finally:mm.close()

def run(session):
 require(json.loads((ROOT/'logs/t2-result.json').read_text())['result']=='PASS','T2_NOT_PASS')
 if session!='T3':require(json.loads((ROOT/'logs'/({'T4':'T3','T5':'T4'}[session]+'-result.json')).read_text())['result']=='PASS','PREVIOUS_GATE_NOT_PASS')
 abi=ROOT/'scripts/V41_C2H_TRANSPORT_ABI_V1.json';require(hashlib.sha256(abi.read_bytes()).hexdigest().upper()==ABI_SHA,'ABI_HASH_DRIFT')
 contract=AbiContract.load(abi);proof=json.loads((ROOT/'logs/t1-proof.json').read_text())
 result={'session':session,'result':'BLOCKED','records':0,'malformed_records':0,'padding_errors':0,'unexplained_gaps':0,'duplicates':0,'frames':0,'measured_records':0,'measured_frames':0}
 child=None;stop=None;raw=None;first=None;frame=None;roll=hashlib.sha256();start_info=None;end_info=None;origin=None
 try:
  epoch,baseline,child,q,stop,start_info=START_C2H_CAPTURE_SESSION(session,proof['user'],proof['c2h'])
  origin=start_info['enable_monotonic']
  validator=StreamValidator(contract,armed_epoch=epoch);assembler=FrameAssembler(contract,card_identity=proof['bdf'])
  if session in ('T3','T4'):raw=(ROOT/'artifacts'/f'{session}-records.bin').open('xb')
  errors=[];deadline=time.monotonic()+90
  while True:
   require(time.monotonic()<deadline,'CAPTURE_WORKER_TIMEOUT')
   try:kind,ts,data=q.get(timeout=1)
   except queue.Empty:
    require(child.is_alive(),'CAPTURE_WORKER_DIED');continue
   if kind=='done':end_info=data;break
   if raw:raw.write(data)
   roll.update(data)
   for i in range(0,len(data),contract.record_bytes):
    blob=data[i:i+contract.record_bytes];a=validator.accept(blob);result['records']+=1
    measured=session=='T5' and origin is not None and origin+5<=ts<origin+65
    if measured:result['measured_records']+=1
    if first is None:first=blob;result['first_record_sha256']=hashlib.sha256(blob).hexdigest().upper();result['first_header']=dict(a.record.header) if a.record else None
    if not a.structurally_valid or a.session_fatal:
     result['malformed_records']+=1
     if any('padding' in e.lower() for e in a.errors):result['padding_errors']+=1
     errors.extend(a.errors[:2]);stop.set()
    if a.discontinuity_reasons:
     result['unexplained_gaps']+=1;errors.extend(a.discontinuity_reasons[:2]);stop.set()
    if a.record and a.record.reset_epoch!=epoch:errors.append('UNEXPECTED_EPOCH_CHANGE');stop.set()
    completed=assembler.push(a)
    if completed:
     result['frames']+=1
     if measured:result['measured_frames']+=1
     if frame is None:frame=completed.raw_uyvy
  child.join(5);require(not child.is_alive(),'READER_DID_NOT_EXIT')
  result['reader']=end_info;result['session_epoch']=epoch;result['rolling_sha256']=roll.hexdigest().upper()
  require(end_info['quiescent'],'R3R2_ROLLBACK_UNSAFE_ACTIVE_DMA')
  mm=MMIO(session)
  try:after=mm.snapshot();status=mm.read(0x3810);err=mm.read(0x383c);ctrl=mm.read(0x380c)
  finally:mm.close()
  delta={k:(after[k]-baseline[k])&0xffffffff for k in baseline if k.startswith('0x')}
  beats=(((after['0x3830']<<32)|after['0x382c'])-((baseline['0x3830']<<32)|baseline['0x382c']))&0xffffffffffffffff
  result.update(snapshot_before=baseline,snapshot_after=after,counter_deltas=delta,beats_delta=beats,final_control=ctrl,final_status=status,final_error=err,errors=errors[:12])
  require(end_info['result']=='PASS',end_info.get('blocker','READER_FAILED'))
  require(not errors,'RECORD_VALIDATION_FAILED')
  require(quiescent(ctrl,status),'FINAL_NOT_QUIESCENT')
  require(err==0,'CAPTURE_ERROR_STATUS_NONZERO')
  require(after['epoch']==epoch,'UNEXPECTED_EPOCH_CHANGE')
  require(all(delta[k]==result['records'] for k in ('0x3814','0x3818','0x381c')) and beats==result['records']*512,'CAPTURE_COUNTER_MISMATCH')
  require(all(delta[k]==0 for k in ('0x3820','0x3824','0x3828','0x3850','0x3854')),'CAPTURE_ERROR_COUNTER_NONZERO')
  result['counter_reconciliation']='PASS'
  if session=='T4':require(result['records']>=2500 and frame is not None,'FINITE_FRAME_MISSING')
  if session=='T5':
   result.update(measured_seconds=60.0,records_per_second=result['measured_records']/60,frames_per_second=result['measured_frames']/60,payload_MBps=result['measured_records']*3840/60/1e6,transport_MBps=result['measured_records']*4096/60/1e6)
  result['result']='PASS'
 except Exception as e:
  result['blocker']=str(e)
  if stop:stop.set()
  if child and child.is_alive():child.join(8)
  if child and child.is_alive():result['rollback']='R3R2_ROLLBACK_UNSAFE_ACTIVE_DMA'
 finally:
  if raw:raw.flush();os.fsync(raw.fileno());raw.close()
  if first:
   (ROOT/'artifacts'/f'{session}-first-record.bin').write_bytes(first)
   result['first_payload_sha256']=hashlib.sha256(first[64:3904]).hexdigest().upper()
  if frame and session=='T4':
   (ROOT/'artifacts/frame.uyvy').write_bytes(frame);result['frame_sha256']=hashlib.sha256(frame).hexdigest().upper();result['frame_geometry']='1920x1080 UYVY'
  save(session+'-result.json',result);print(json.dumps(result,indent=2),flush=True)
 return result

if __name__=='__main__':
 mp.freeze_support()
 run(sys.argv[1])
