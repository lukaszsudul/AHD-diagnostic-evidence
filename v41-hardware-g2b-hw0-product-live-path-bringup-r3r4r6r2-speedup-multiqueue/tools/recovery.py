import os,sys,time,json,pathlib,signal,subprocess
P=pathlib.Path
ROOT=P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r6r2/20260908T061945Z')
OLD='/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r6r1/20260907T202452Z'
LOCK=P('/tmp/ahd-g2b-hw0-product-r3r4r6r1-20260907T202452Z.lock')
os.umask(0o077)
def save(v):
 with (ROOT/'logs/recovery.json').open('w') as f:json.dump(v,f,indent=2);f.flush();os.fsync(f.fileno())
 print(json.dumps(v),flush=True)
def holders():
 out=[]
 for f in P('/proc').glob('[0-9]*/fd/*'):
  try:
   if os.readlink(f)=='/dev/xdma0_c2h_0':out.append(str(f))
  except (FileNotFoundError,PermissionError,ProcessLookupError):pass
 return out
def loaded():return P('/sys/module/xdma_ahd_pcie').exists()
def refcount():return int(P('/sys/module/xdma_ahd_pcie/refcnt').read_text()) if loaded() else 0
def release():
 if LOCK.exists():
  f=LOCK/'receipt.json';v=json.loads(f.read_text())
  if v.get('task')!='G2B-HW0-PRODUCT-R3R4R6R1' or v.get('remote_root')!=OLD:raise RuntimeError('OLD_LINUX_LOCK_OWNER_CONTRADICTION')
  f.unlink();LOCK.rmdir()
def main():
 after=sys.argv[1]=='after-reboot'
 if after:
  v=json.loads((ROOT/'logs/recovery.json').read_text())
  if v.get('warm_reboot')!=1:raise RuntimeError('REBOOT_RECEIPT_REQUIRED')
 else:
  with (ROOT/'logs/recovery-once').open('x') as f:f.write('START\n')
  v={'method':'BLOCKED','warm_reboot':0,'sigterm':0,'rmmod_attempts':0,'result':'BLOCKED'}
  try:cmd=P('/proc/25287/cmdline').read_bytes().split(b'\0')
  except FileNotFoundError:cmd=None
  if cmd is None:v['pid_identity']='ALREADY_EXITED'
  elif not any(b'prequeued_c2h_capture' in x and OLD.encode() in x for x in cmd):
   v.update(pid_identity='CONTRADICTION',blocker='R3R4R6R2_RECOVERY_PID_IDENTITY_CONTRADICTION');save(v);return
  else:
   v['pid_identity']='VERIFIED_FOR_SIGNAL_SAFETY';v['sigterm']=1;save(v);os.kill(25287,signal.SIGTERM)
  deadline=time.monotonic()+12
  while time.monotonic()<deadline:
   if not P('/proc/25287').exists() and not holders() and refcount()==0:break
   time.sleep(.2)
  stuck=P('/proc/25287').exists() or bool(holders()) or refcount()!=0
  if not stuck and loaded():
   v['rmmod_attempts']=1;save(v)
   result=subprocess.run(['rmmod','xdma_ahd_pcie'],capture_output=True,text=True)
   v['rmmod_returncode']=result.returncode;v['rmmod_stderr']=result.stderr
   if result.returncode:
    if refcount()!=0 or holders():stuck=True
    else:v['blocker']='R3R4R6R2_NORMAL_RMMOD_OPERATION_FAILED';save(v);return
  if stuck:
   v.update(method='ONE_GRACEFUL_WARM_REBOOT',warm_reboot=1,reason='OLD_AIO_REMAINS_AFTER_12_SECONDS');save(v)
   subprocess.run(['systemctl','reboot'],check=True);return
  v['method']='NO_ACTION_OLD_PROCESS_ALREADY_EXITED' if cmd is None else 'SIGTERM_NORMAL_EXIT_AND_RMMOD'
 deadline=time.monotonic()+12
 while time.monotonic()<deadline and any(P(x).exists() for x in ['/dev/xdma0_user','/dev/xdma0_c2h_0']):time.sleep(.2)
 v.update(old_helper_removed=not P('/proc/25287').exists(),old_holder_removed=not holders(),old_module_removed=not loaded(),old_nodes_removed=not any(P(x).exists() for x in ['/dev/xdma0_user','/dev/xdma0_c2h_0']))
 if not all(v[k] for k in ('old_helper_removed','old_holder_removed','old_module_removed','old_nodes_removed')):
  v['blocker']='R3R4R6R2_RECOVERY_CLEANUP_OPERATIONAL_CONTRADICTION';save(v);return
 release();v.update(old_linux_lock_released=True,result='PASS');save(v)
if __name__=='__main__':main()
