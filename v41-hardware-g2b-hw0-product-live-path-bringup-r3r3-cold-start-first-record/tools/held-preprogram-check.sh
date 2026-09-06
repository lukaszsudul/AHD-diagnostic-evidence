set -eu
python3 - <<'PY'
import json, os, pathlib, platform, socket
P=pathlib.Path
boot='9fec7547-fd31-4592-a9ce-89ea082d2484'
own=P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-pre.lock')
receipt=json.loads((own/'receipt.json').read_text())
assert receipt=={'task':'G2B-HW0-PRODUCT-R3R3','phase':'PRE_REBOOT','state':'HELD','boot':boot,'utc':receipt['utc']}
assert socket.gethostname()=='VCDE-DUT-1'
assert P('/etc/machine-id').read_text().strip()=='0e90f50d9465492b80258da5658446f8'
assert platform.uname().release=='7.0.0-29-generic' and platform.machine()=='x86_64'
assert P('/proc/sys/kernel/random/boot_id').read_text().strip()==boot
assert not any(line.split()[0] in ('xdma','xdma_ahd_pcie') for line in P('/proc/modules').read_text().splitlines())
assert not list(P('/dev').glob('xdma*')) and not list(P('/sys/class/xdma').glob('*'))

ancestors=set();pid=os.getpid()
while pid>1 and pid not in ancestors:
    ancestors.add(pid)
    try:pid=int((P('/proc')/str(pid)/'stat').read_text().split()[3])
    except (OSError,ValueError,IndexError):break
tokens=('ahd','hdmi','fpga','jtag','xdma','dma_from','dma_to','reg_rw','g2b_capture','g2b_mmio','vivado','hw_server','xsdb','xicom','reboot','shutdown','poweroff')
processes=[];fds=[]
for proc in P('/proc').iterdir():
    if not proc.name.isdigit() or int(proc.name) in ancestors:continue
    try:
        comm=(proc/'comm').read_text().strip();cmd=(proc/'cmdline').read_bytes().replace(b'\0',b' ').decode('utf-8','replace')
        hits=sorted({token for token in tokens if token in (comm+' '+cmd).lower()})
        if hits:processes.append({'pid':int(proc.name),'comm':comm,'token_hits':hits})
        for desc in (proc/'fd').iterdir():
            try:target=os.readlink(desc)
            except OSError:continue
            if target.startswith('/dev/xdma'):fds.append({'pid':int(proc.name),'target':target})
    except (OSError,PermissionError):pass
locks=[]
for parent in ('/tmp','/run/lock','/var/lock'):
    try:entries=list(P(parent).iterdir())
    except OSError:continue
    for entry in entries:
        if entry==own:continue
        if any(token in entry.name.lower() for token in ('ahd','g2b','xdma','jtag','fpga','hdmi')):locks.append(str(entry))
ep=P('/sys/bus/pci/devices/0000:01:00.0');rp=P('/sys/bus/pci/devices/0000:00:01.1')
endpoint={'bdf':ep.name,'realpath':str(ep.resolve()),'vendor':(ep/'vendor').read_text().strip(),'device':(ep/'device').read_text().strip(),'subsystem_vendor':(ep/'subsystem_vendor').read_text().strip(),'subsystem_device':(ep/'subsystem_device').read_text().strip(),'class':(ep/'class').read_text().strip(),'driver':str((ep/'driver').resolve()) if (ep/'driver').exists() else None,'driver_override':(ep/'driver_override').read_text().strip(),'link_speed':(ep/'current_link_speed').read_text().strip(),'link_width':(ep/'current_link_width').read_text().strip(),'root_port':rp.name,'root_speed':(rp/'current_link_speed').read_text().strip(),'root_width':(rp/'current_link_width').read_text().strip()}
assert not processes and not fds and not locks
assert endpoint['realpath'].find('/0000:00:01.1/')>=0 and endpoint['vendor']=='0x10ee' and endpoint['device']=='0x7011'
assert endpoint['subsystem_vendor']=='0x10ee' and endpoint['subsystem_device']=='0x0007' and endpoint['class']=='0x058000'
assert endpoint['driver'] is None and endpoint['driver_override'] in ('','(null)')
assert endpoint['link_speed'].startswith('5.0') and endpoint['link_width']=='1'
assert endpoint['root_speed'].startswith('5.0') and endpoint['root_width']=='1'
out={'task':'G2B-HW0-PRODUCT-R3R3','boot_id':boot,'own_linux_lock':'HELD','matching_competing_processes':processes,'other_matching_locks':locks,'open_xdma_fds':fds,'endpoint':endpoint,'result':'PASS'}
print(json.dumps(out,indent=2))
PY
