set -eu
python3 - <<'PY'
import json, os, pathlib, platform, socket, subprocess
P = pathlib.Path

def text(path, default='UNAVAILABLE'):
    try:
        return P(path).read_text().strip()
    except (OSError, PermissionError):
        return default

ancestors = set()
pid = os.getpid()
while pid > 1 and pid not in ancestors:
    ancestors.add(pid)
    try:
        fields = (P('/proc') / str(pid) / 'stat').read_text().split()
        pid = int(fields[3])
    except (OSError, ValueError, IndexError):
        break

tokens = ('ahd', 'hdmi', 'fpga', 'jtag', 'xdma', 'dma_from', 'dma_to',
          'reg_rw', 'g2b_capture', 'g2b_mmio', 'vivado', 'hw_server',
          'xsdb', 'xicom', 'reboot', 'shutdown', 'poweroff')
processes = []
open_xdma_fds = []
for proc in P('/proc').iterdir():
    if not proc.name.isdigit() or int(proc.name) in ancestors:
        continue
    try:
        comm = (proc / 'comm').read_text().strip()
        cmd = (proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode('utf-8', 'replace')
        hits = sorted({t for t in tokens if t in (comm + ' ' + cmd).lower()})
        if hits:
            processes.append({'pid': int(proc.name), 'comm': comm, 'token_hits': hits})
        for fd in (proc / 'fd').iterdir():
            try:
                target = os.readlink(fd)
            except OSError:
                continue
            if target.startswith('/dev/xdma'):
                open_xdma_fds.append({'pid': int(proc.name), 'comm': comm, 'target': target})
    except (OSError, PermissionError, UnicodeError):
        pass

locks = []
for parent in ('/tmp', '/run/lock', '/var/lock'):
    try:
        entries = list(P(parent).iterdir())
    except OSError:
        continue
    for entry in entries:
        if any(t in entry.name.lower() for t in ('ahd', 'g2b', 'xdma', 'jtag', 'fpga', 'hdmi')):
            locks.append(str(entry))

endpoints = []
for dev in P('/sys/bus/pci/devices').iterdir():
    if text(dev / 'vendor') != '0x10ee':
        continue
    row = {'bdf': dev.name, 'realpath': str(dev.resolve())}
    for name in ('vendor', 'device', 'subsystem_vendor', 'subsystem_device', 'class',
                 'modalias', 'driver_override', 'current_link_speed', 'current_link_width',
                 'max_link_speed', 'max_link_width', 'iommu_group'):
        path = dev / name
        if name == 'iommu_group':
            row[name] = path.resolve().name if path.exists() else 'NONE'
        else:
            row[name] = text(path)
    row['driver'] = str((dev / 'driver').resolve()) if (dev / 'driver').exists() else None
    endpoints.append(row)

try:
    inhibitors = subprocess.check_output(
        ['systemd-inhibit', '--list', '--no-pager'], text=True, stderr=subprocess.STDOUT,
        timeout=10)
except Exception as exc:
    inhibitors = 'UNAVAILABLE:' + type(exc).__name__

out = {
    'hostname': socket.gethostname(),
    'machine_id': text('/etc/machine-id'),
    'boot_id': text('/proc/sys/kernel/random/boot_id'),
    'kernel': platform.uname().release,
    'architecture': platform.machine(),
    'modules': [line.split()[0] for line in text('/proc/modules', '').splitlines()
                if line.split() and line.split()[0] in ('xdma', 'xdma_ahd_pcie')],
    'nodes': sorted(str(p) for p in P('/dev').glob('xdma*')),
    'class_nodes': sorted(str(p) for p in P('/sys/class/xdma').glob('*')),
    'matching_processes': processes,
    'open_xdma_fds': open_xdma_fds,
    'matching_locks': locks,
    'xilinx_endpoints': endpoints,
    'inhibitors': inhibitors,
}
print(json.dumps(out, indent=2), flush=True)
assert out['hostname'] == 'VCDE-DUT-1'
assert out['machine_id'] == '0e90f50d9465492b80258da5658446f8'
assert out['kernel'] == '7.0.0-29-generic'
assert out['architecture'] == 'x86_64'
assert not out['modules']
assert not out['nodes'] and not out['class_nodes'] and not out['open_xdma_fds']
assert not out['matching_processes']
assert not out['matching_locks']
print('FRESH_DUT_IDENTITY_AND_EXCLUSIVITY=PASS')
PY
