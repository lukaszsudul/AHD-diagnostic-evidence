"""Read-only post-load guard before T2/T3 hardware access."""
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
OWN_LOCK = LOCK.parent


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


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


result = {'task': 'G2B-HW0-PRODUCT-R3R3', 'phase': 'POST_LOAD_GUARD',
          'result': 'BLOCKED', 'utc_ns': time.time_ns()}
try:
    lock = json.loads(LOCK.read_text())
    require(lock['task'] == result['task'] and lock['phase'] == 'POST_REBOOT' and
            lock['state'] == 'HELD', 'POST_REBOOT_LINUX_LOCK_REQUIRED')
    boot = P('/proc/sys/kernel/random/boot_id').read_text().strip()
    require(boot == lock['boot'], 'UNEXPECTED_BOOT_TRANSITION_DURING_R3R3')

    competing_locks = []
    for item in P('/tmp').glob('*ahd*lock*'):
        if item.resolve() != OWN_LOCK.resolve():
            competing_locks.append(str(item))
    require(not competing_locks, 'COMPETING_DUT_LOCK_PRESENT')

    process_rows = []
    process_pattern = re.compile(
        r'(?i)(capture|g2b|xdma|nvp|vcde|vivado|hw_server|program_hw)')
    for proc in P('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            cmdline = (proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode(
                'utf-8', 'replace').strip()
            if cmdline and process_pattern.search(cmdline):
                # Exclude this guard, its transport, and unrelated host/session
                # daemons whose hostname or login contains the token "vcde".
                transport_or_daemon = (
                    'postload-guard.py' in cmdline or
                    'ahd-g2b-hw0-product-r3r3' in cmdline or
                    cmdline.startswith('sshd-session:') or
                    cmdline.startswith('avahi-daemon:'))
                if not transport_or_daemon:
                    process_rows.append({'pid': int(proc.name), 'cmdline': cmdline})
        except (OSError, PermissionError):
            pass
    require(not process_rows, 'COMPETING_HARDWARE_PROCESS_PRESENT')

    require(P('/sys/module/xdma_ahd_pcie').is_dir(), 'DRIVER_MODULE_NOT_LOADED')
    require(not P('/sys/module/xdma').exists(), 'PLATFORM_XDMA_MODULE_PRESENT')
    require(ENDPOINT.is_dir() and ROOT_PORT.is_dir(), 'EXACT_ENDPOINT_NOT_PRESENT')
    require((ENDPOINT / 'vendor').read_text().strip() == '0x10ee' and
            (ENDPOINT / 'device').read_text().strip() == '0x7011' and
            (ENDPOINT / 'subsystem_vendor').read_text().strip() == '0x10ee' and
            (ENDPOINT / 'subsystem_device').read_text().strip() == '0x0007' and
            (ENDPOINT / 'class').read_text().strip() == '0x058000',
            'EXACT_ENDPOINT_IDENTITY_CHANGED')
    require((ENDPOINT / 'driver').resolve().name == 'xdma_ahd_pcie',
            'EXACT_ENDPOINT_BIND_CHANGED')
    bound = sorted(item.name for item in (ENDPOINT / 'driver').resolve().iterdir()
                   if item.name.startswith('0000:'))
    require(bound == ['0000:01:00.0'], 'UNINTENDED_ENDPOINT_BOUND')
    require((ENDPOINT / 'driver_override').read_text().strip() in ('', '(null)'),
            'DRIVER_OVERRIDE_NOT_EMPTY')
    require((ENDPOINT / 'current_link_speed').read_text().strip().startswith('5.0') and
            (ENDPOINT / 'current_link_width').read_text().strip() == '1' and
            (ROOT_PORT / 'current_link_speed').read_text().strip().startswith('5.0') and
            (ROOT_PORT / 'current_link_width').read_text().strip() == '1',
            'PCIE_LINK_NOT_GEN2_X1')

    proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
    require(proof['result'] == 'PASS' and proof['bdf'] == '0000:01:00.0',
            'T1_PROOF_NOT_PASS')
    for key in ('user', 'c2h'):
        node = P(proof[key])
        require(node.exists() and node.is_char_device(), 'REQUIRED_XDMA_NODE_MISSING')
        st = node.stat()
        ancestry = (P('/sys/dev/char') /
                    f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}' /
                    'device').resolve()
        require('0000:01:00.0' in str(ancestry), 'NODE_BDF_PROOF_CHANGED')
    holders = open_xdma_fds()
    require(not holders, 'XDMA_NODE_ALREADY_OPEN')

    result.update(result='PASS', boot_id=boot, competing_locks=competing_locks,
                  competing_processes=process_rows, bound_endpoints=bound,
                  open_xdma_fds=holders, user=proof['user'], c2h=proof['c2h'],
                  endpoint_link='Gen2 x1', root_port_link='Gen2 x1',
                  driver_override='EMPTY', platform_xdma='ABSENT')
except BaseException as exc:
    result['blocker'] = str(exc)

print(json.dumps(result, indent=2), flush=True)
sys.exit(0 if result['result'] == 'PASS' else 1)
