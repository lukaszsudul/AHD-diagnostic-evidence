set -eu
python3 - <<'PY'
import pathlib,os,json,subprocess,socket
P=pathlib.Path
out={'hostname':socket.gethostname(),'machine_id':P('/etc/machine-id').read_text().strip(),'boot':P('/proc/sys/kernel/random/boot_id').read_text().strip(),'kernel':os.uname().release,'taint':P('/proc/sys/kernel/tainted').read_text().strip()}
out['modules']=[x.split()[0] for x in P('/proc/modules').read_text().splitlines() if x.split()[0] in ('xdma','xdma_ahd_pcie')]
out['nodes']=[str(p) for p in P('/dev').glob('xdma*')]
out['class']=[str(p) for p in P('/sys/class/xdma').glob('*')]
out['processes']=[];out['open_device_fds']=[]
names=('vivado','hw_server','xsdb','xicom','ffmpeg','gst-launch','dma_from','dma_to','reg_rw','g2b_capture','g2b_mmio','insmod','rmmod','modprobe')
for p in P('/proc').iterdir():
 if not p.name.isdigit(): continue
 try:
  comm=(p/'comm').read_text().strip()
  if any(n in comm for n in names):out['processes'].append({'pid':p.name,'comm':comm})
  for fd in (p/'fd').iterdir():
   try:
    target=os.readlink(fd)
    if target.startswith('/dev/xdma'):out['open_device_fds'].append({'pid':p.name,'target':target})
   except OSError:pass
 except (OSError,PermissionError):pass
out['locks']=[]
for parent in ('/tmp','/run/lock','/var/lock'):
 for p in P(parent).glob('*'):
  if any(x in p.name.lower() for x in ('ahd','g2b','xdma','jtag','fpga')):out['locks'].append(str(p))
out['endpoints']=[]
for p in P('/sys/bus/pci/devices').iterdir():
 if (p/'vendor').read_text().strip()=='0x10ee' and (p/'device').read_text().strip()=='0x7011':
  d={'bdf':p.name,'realpath':str(p.resolve()),'driver':str((p/'driver').resolve()) if (p/'driver').exists() else None}
  for f in ('vendor','device','subsystem_vendor','subsystem_device','class','modalias','driver_override','current_link_speed','current_link_width','max_link_speed','max_link_width','resource'):
   try:d[f]=(p/f).read_text().strip()
   except OSError:d[f]='UNAVAILABLE'
  out['endpoints'].append(d)
print(json.dumps(out,indent=2))
assert out['hostname']=='VCDE-DUT-1' and out['machine_id']=='0e90f50d9465492b80258da5658446f8'
assert out['boot']=='52b0bf13-e9d1-4558-ae13-d08f4ecc8dac'
assert not any(out[k] for k in ('modules','nodes','class','processes','open_device_fds','locks'))
assert len(out['endpoints'])==1
e=out['endpoints'][0]
assert e['bdf']=='0000:01:00.0' and e['driver'] is None and e['driver_override'] in ('','(null)')
assert e['subsystem_vendor']=='0x10ee' and e['subsystem_device']=='0x0007'
assert e['current_link_speed'].startswith('5.0') and e['current_link_width']=='1'
assert '/0000:00:01.1/' in e['realpath']
print('PRELOCK_GATE=PASS')
PY
