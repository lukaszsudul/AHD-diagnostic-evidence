set -eu
python3 - <<'PY'
import json,os,pathlib,platform,socket
P=pathlib.Path
boot='9fec7547-fd31-4592-a9ce-89ea082d2484'
own=P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-pre.lock')
receipt=json.loads((own/'receipt.json').read_text())
assert receipt['task']=='G2B-HW0-PRODUCT-R3R3' and receipt['phase']=='PRE_REBOOT' and receipt['state']=='HELD' and receipt['boot']==boot
assert socket.gethostname()=='VCDE-DUT-1' and P('/etc/machine-id').read_text().strip()=='0e90f50d9465492b80258da5658446f8'
assert platform.uname().release=='7.0.0-29-generic' and platform.machine()=='x86_64'
assert P('/proc/sys/kernel/random/boot_id').read_text().strip()==boot
modules=[line.split()[0] for line in P('/proc/modules').read_text().splitlines() if line.split()[0] in ('xdma','xdma_ahd_pcie')]
nodes=sorted(str(path) for path in P('/dev').glob('xdma*'))
fds=[]
for proc in P('/proc').iterdir():
    if not proc.name.isdigit():continue
    try:
        for desc in (proc/'fd').iterdir():
            try:target=os.readlink(desc)
            except OSError:continue
            if target.startswith('/dev/xdma'):fds.append({'pid':int(proc.name),'target':target})
    except (OSError,PermissionError):pass
others=[]
for parent in ('/tmp','/run/lock','/var/lock'):
    try:entries=list(P(parent).iterdir())
    except OSError:continue
    for entry in entries:
        if entry==own:continue
        if any(token in entry.name.lower() for token in ('ahd','g2b','xdma','jtag','fpga','hdmi')):others.append(str(entry))
assert not modules and not nodes and not fds and not others
print(json.dumps({'task':'G2B-HW0-PRODUCT-R3R3','boot_id':boot,'pre_reboot_linux_lock':'HELD','driver_modules':modules,'xdma_nodes':nodes,'open_xdma_fds':fds,'other_hardware_locks':others,'mmio_active':'NO','dma_active':'NO','result':'PASS'},indent=2))
PY
