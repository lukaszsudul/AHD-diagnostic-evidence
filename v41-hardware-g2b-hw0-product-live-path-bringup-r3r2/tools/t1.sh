set -eu
cd /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z
python3 - <<'PY'
import pathlib,subprocess,json,hashlib,os,time,stat
P=pathlib.Path
lock=json.loads(P('/tmp/ahd-g2b-hw0-product-r3r2-20260906T182010Z.lock/receipt.json').read_text())
assert lock['task']=='G2B-HW0-PRODUCT-R3R2' and lock['state']=='HELD'
assert P('/proc/sys/kernel/random/boot_id').read_text().strip()==lock['boot']
module=P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko')
def cmd(*args):return subprocess.check_output(args,text=True).rstrip('\n')
info={f:cmd('modinfo','-F',f,str(module)) for f in ('name','vermagic','alias','depends','srcversion','signer','sig_id')}
info.update(sha256=hashlib.sha256(module.read_bytes()).hexdigest().upper(),bytes=module.stat().st_size,secure_boot=cmd('mokutil','--sb-state'),elf=cmd('readelf','-h',str(module)),notes=cmd('readelf','-n',str(module)),taint_before=int(P('/proc/sys/kernel/tainted').read_text()))
P('logs/driver-verification.json').write_text(json.dumps(info,indent=2))
print(json.dumps(info,indent=2),flush=True)
assert module.is_file() and not module.is_symlink()
assert not(module.stat().st_mode & 0o222) and not(module.parent.stat().st_mode & 0o222)
assert info['bytes']==3296104 and info['sha256']=='E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77'
assert info['name']=='xdma_ahd_pcie' and info['vermagic']=='7.0.0-29-generic SMP preempt mod_unload modversions '
assert info['alias']=='pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*'
assert info['depends']=='' and info['signer']=='' and info['sig_id']==''
assert info['srcversion']=='EE8B149D1883AE8C6B1EE31' and '1471c3a284ec1cb26115fe9e9bd59890a034f83e' in info['notes']
assert 'Advanced Micro Devices X86-64' in info['elf'] and 'SecureBoot disabled' in info['secure_boot']
ep=P('/sys/bus/pci/devices/0000:01:00.0')
assert not (ep/'driver').exists() and (ep/'driver_override').read_text().strip() in ('','(null)')
assert not P('/sys/module/xdma').exists() and not P('/sys/module/xdma_ahd_pcie').exists()
assert not list(P('/dev').glob('xdma*'))
with P('logs/insmod-attempt.json').open('x') as f:json.dump({'attempt':1,'monotonic':time.monotonic()},f)
rc=subprocess.run(['insmod',str(module)],capture_output=True,text=True,timeout=20)
result={'insmod_returncode':rc.returncode,'stdout':rc.stdout,'stderr':rc.stderr,'taint_after_load':int(P('/proc/sys/kernel/tainted').read_text())}
P('logs/driver-load.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result),flush=True)
if rc.returncode:raise RuntimeError('EXACT_ALIAS_AUTOMATIC_BIND_FAILED')
subprocess.run(['udevadm','settle','--timeout=20'],timeout=21,check=True)
deadline=time.monotonic()+20
while not list(P('/dev').glob('xdma*_c2h_0')) and time.monotonic()<deadline:time.sleep(.1)
assert P('/sys/module/xdma_ahd_pcie').exists() and not P('/sys/module/xdma').exists()
driver=(ep/'driver').resolve();bound=[x.name for x in driver.iterdir() if x.name.startswith('0000:')]
assert bound==['0000:01:00.0'],('UNINTENDED_ENDPOINT_BOUND',bound)
rows=[]
for node in sorted(P('/dev').glob('xdma*')):
 st=node.stat(); char=P('/sys/dev/char')/f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}'
 cls=P('/sys/class/xdma')/node.name
 rows.append({'node':str(node),'major':os.major(st.st_rdev),'minor':os.minor(st.st_rdev),'char_path':str(char.resolve()),'class_path':str(cls.resolve()),'char_device':str((char/'device').resolve()),'class_device':str((cls/'device').resolve()),'mode':oct(st.st_mode)})
P('logs/node-map.json').write_text(json.dumps(rows,indent=2));print(json.dumps(rows,indent=2),flush=True)
users=[r for r in rows if r['node'].endswith('_user')];c2hs=[r for r in rows if r['node'].endswith('_c2h_0')]
assert len(users)==1 and len(c2hs)==1
for row in users+c2hs:
 assert '0000:01:00.0' in row['char_path'] or '0000:01:00.0' in row['char_device'], 'XDMA_NODE_TO_BDF_CORRELATION_UNPROVEN'
 assert '0000:01:00.0' in row['class_path'] or '0000:01:00.0' in row['class_device'], 'XDMA_NODE_TO_BDF_CORRELATION_UNPROVEN'
assert users[0]['node'].rsplit('_',1)[0]==c2hs[0]['node'].rsplit('_c2h_',1)[0]
assert ((result['taint_after_load'] ^ info['taint_before']) & ~((1<<12)|(1<<13)))==0
proof={'result':'PASS','bdf':'0000:01:00.0','user':users[0]['node'],'c2h':c2hs[0]['node'],'taint_before':info['taint_before'],'taint_after_load':result['taint_after_load']}
P('logs/t1-proof.json').write_text(json.dumps(proof));print('T1_GATE=PASS',flush=True)
P('logs/kernel-after-load.txt').write_bytes(subprocess.check_output(['dmesg','--color=never']))
PY
