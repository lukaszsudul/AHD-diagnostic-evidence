"""Read-only R3R3 PCIe, AER, kernel, link, and driver health snapshot."""
import json
import os
import pathlib
import re
import subprocess
import sys
import time

P = pathlib.Path
ROOT = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z')
LOCK = P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock/receipt.json')
ENDPOINT = P('/sys/bus/pci/devices/0000:01:00.0')
ROOT_PORT = P('/sys/bus/pci/devices/0000:00:01.1')
LABELS = {'after-t2', 'after-t3', 'before-unload', 'after-unload'}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def aer(path):
    values = {}
    for item in path.glob('aer_*'):
        try:
            values[item.name] = item.read_text().strip()
        except OSError:
            values[item.name] = 'UNAVAILABLE'
    return values


def open_xdma_fds():
    found = []
    for proc in P('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            comm = (proc / 'comm').read_text().strip()
            for desc in (proc / 'fd').iterdir():
                try:
                    target = os.readlink(desc)
                except OSError:
                    continue
                if target.startswith('/dev/xdma'):
                    found.append({'pid': int(proc.name), 'comm': comm,
                                  'target': target})
        except (OSError, PermissionError):
            pass
    return found


if len(sys.argv) != 2 or sys.argv[1] not in LABELS:
    raise SystemExit('USAGE: health-snapshot.py ' + '|'.join(sorted(LABELS)))
label = sys.argv[1]
result = {'task': 'G2B-HW0-PRODUCT-R3R3', 'label': label,
          'result': 'BLOCKED', 'utc_ns': time.time_ns()}
try:
    lock = json.loads(LOCK.read_text())
    boot = P('/proc/sys/kernel/random/boot_id').read_text().strip()
    require(lock['task'] == result['task'] and lock['state'] == 'HELD' and
            lock['phase'] == 'POST_REBOOT' and lock['boot'] == boot,
            'POST_REBOOT_LOCK_OR_BOOT_MISMATCH')
    require(ENDPOINT.is_dir() and ROOT_PORT.is_dir(), 'PCIE_PATH_MISSING')
    endpoint_link = {
        'speed': (ENDPOINT / 'current_link_speed').read_text().strip(),
        'width': (ENDPOINT / 'current_link_width').read_text().strip(),
    }
    root_link = {
        'speed': (ROOT_PORT / 'current_link_speed').read_text().strip(),
        'width': (ROOT_PORT / 'current_link_width').read_text().strip(),
    }
    require(endpoint_link['speed'].startswith('5.0') and
            endpoint_link['width'] == '1' and
            root_link['speed'].startswith('5.0') and root_link['width'] == '1',
            'PCIE_LINK_DOWNGRADE')

    current_aer = {'endpoint': aer(ENDPOINT), 'root_port': aer(ROOT_PORT)}
    baseline = json.loads((ROOT / 'logs/t1-proof.json').read_text())['aer_after']
    require(current_aer == baseline, 'NEW_AER_COUNTER_DELTA')

    kernel_before = (ROOT / 'logs/kernel-immediate-before-load.txt').read_bytes()
    kernel_now = subprocess.check_output(['dmesg', '--color=never'])
    require(kernel_now.startswith(kernel_before), 'KERNEL_BASELINE_CONTINUITY_LOST')
    delta = kernel_now[len(kernel_before):].decode('utf-8', 'replace')
    fatal = re.findall(
        r'(?im)^.*(?:\bOops\b|\bBUG:|Call Trace:|hung task|use-after-free|'
        r'IOMMU fault|DMA-API|completion timeout|malformed TLP|unsupported request|'
        r'surprise link|link[- ]down|xdma[^\n]*fatal).*$', delta)
    require(not fatal, 'NEW_KERNEL_OR_DRIVER_FATAL')

    driver = ((ENDPOINT / 'driver').resolve().name
              if (ENDPOINT / 'driver').exists() else None)
    nodes = sorted(str(item) for item in P('/dev').glob('xdma*'))
    lspci = {bdf: subprocess.check_output(['lspci', '-s', bdf, '-vvv'], text=True)
             for bdf in ('0000:01:00.0', '0000:00:01.1')}
    (ROOT / f'logs/kernel-{label}.txt').write_bytes(kernel_now)
    result.update(result='PASS', boot_id=boot, endpoint_link=endpoint_link,
                  root_port_link=root_link, aer=current_aer,
                  aer_delta_from_after_load='NONE', kernel_fatal_matches=fatal,
                  kernel_bytes=len(kernel_now), kernel_delta_bytes=len(delta.encode()),
                  taint=int(P('/proc/sys/kernel/tainted').read_text()),
                  driver=driver, platform_xdma=P('/sys/module/xdma').exists(),
                  nodes=nodes, open_xdma_fds=open_xdma_fds(), lspci=lspci)
except BaseException as exc:
    result['blocker'] = str(exc)

(ROOT / f'logs/health-{label}.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2), flush=True)
sys.exit(0 if result['result'] == 'PASS' else 1)
