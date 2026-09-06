"""R3R3 bounded safe drain and exactly-one normal driver unload."""
import json
import os
import pathlib
import re
import signal
import subprocess
import sys
import time

from capture import MMIO, quiescent

P = pathlib.Path
ROOT = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z')
LOCK = P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock/receipt.json')
ENDPOINT = P('/sys/bus/pci/devices/0000:01:00.0')
ROOT_PORT = P('/sys/bus/pci/devices/0000:00:01.1')


class ReadDeadline(Exception):
    pass


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def alarm_handler(*_):
    raise ReadDeadline()


def open_xdma_fds():
    found = []
    for proc in P('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            comm = (proc / 'comm').read_text().strip()
            cmdline = (proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode(
                'utf-8', 'replace').strip()
            for desc in (proc / 'fd').iterdir():
                try:
                    target = os.readlink(desc)
                except OSError:
                    continue
                if target.startswith('/dev/xdma'):
                    found.append({'pid': int(proc.name), 'comm': comm,
                                  'cmdline': cmdline, 'target': target})
        except (OSError, PermissionError):
            pass
    return found


def aer(path):
    values = {}
    for item in path.glob('aer_*'):
        try:
            values[item.name] = item.read_text().strip()
        except OSError:
            values[item.name] = 'UNAVAILABLE'
    return values


def stop_receipted_reader(result):
    receipt_path = ROOT / 'logs/T3-reader-ready.json'
    if not receipt_path.exists():
        result['receipted_reader'] = 'NOT_CREATED'
        return
    receipt = json.loads(receipt_path.read_text())
    pid = int(receipt['pid'])
    proc = P('/proc') / str(pid)
    if not proc.exists():
        result['receipted_reader'] = 'ALREADY_EXITED'
        return
    fd_targets = []
    try:
        for desc in (proc / 'fd').iterdir():
            try:
                fd_targets.append(os.readlink(desc))
            except OSError:
                pass
    except OSError:
        pass
    require(receipt.get('node') in fd_targets,
            'RECEIPTED_PID_REUSE_OR_READER_IDENTITY_LOST')
    os.kill(pid, signal.SIGTERM)
    deadline = time.monotonic() + 3.0
    while proc.exists() and time.monotonic() < deadline:
        time.sleep(0.05)
    require(not proc.exists(), 'R3R3_OWNED_READER_DID_NOT_STOP')
    result['receipted_reader'] = 'STOPPED_BY_CLEANUP'


def bounded_drain(mmio, c2h, result):
    control = mmio.read(0x380C)
    status = mmio.read(0x3810)
    if control & 1:
        mmio.write(0x380C, 0, 'SAFETY_DISABLE',
                   'POST_ENABLE_FAILURE_CLEANUP')
        result['safety_disable_written'] = True
    else:
        result['safety_disable_written'] = False
    control = mmio.read(0x380C)
    status = mmio.read(0x3810)
    records = []
    pending = bytearray()
    if not quiescent(control, status):
        fd = os.open(c2h, os.O_RDONLY | os.O_NOFOLLOW)
        signal.signal(signal.SIGALRM, alarm_handler)
        signal.siginterrupt(signal.SIGALRM, True)
        deadline = time.monotonic() + 10.0
        try:
            while True:
                control = mmio.read(0x380C)
                status = mmio.read(0x3810)
                if quiescent(control, status):
                    break
                require(time.monotonic() < deadline, 'CLEANUP_BOUNDED_DRAIN_TIMEOUT')
                require(len(records) <= 64, 'CLEANUP_DRAIN_RECORD_LIMIT_EXCEEDED')
                signal.setitimer(signal.ITIMER_REAL,
                                 min(0.5, max(0.001, deadline - time.monotonic())))
                try:
                    chunk = os.read(fd, max(1, 4096 - len(pending)))
                except ReadDeadline:
                    continue
                finally:
                    signal.setitimer(signal.ITIMER_REAL, 0)
                require(chunk, 'EMPTY_C2H_READ_DURING_CLEANUP')
                pending.extend(chunk)
                while len(pending) >= 4096:
                    require(len(records) < 64,
                            'CLEANUP_DRAIN_RECORD_LIMIT_EXCEEDED')
                    records.append(bytes(pending[:4096]))
                    del pending[:4096]
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)
            os.close(fd)
    (ROOT / 'artifacts/cleanup-drained-complete-records.bin').write_bytes(
        b''.join(records))
    (ROOT / 'artifacts/cleanup-trailing-incomplete.bin').write_bytes(bytes(pending))
    result.update(cleanup_drain_records=len(records),
                  cleanup_trailing_bytes=len(pending),
                  final_preunload_control=mmio.read(0x380C),
                  final_preunload_status=mmio.read(0x3810),
                  final_preunload_error_status=mmio.read(0x383C))
    require(quiescent(result['final_preunload_control'],
                      result['final_preunload_status']),
            'R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA')


result = {'task': 'G2B-HW0-PRODUCT-R3R3', 'result': 'BLOCKED',
          'rmmod_attempts': 0, 'forced_unloads': 0,
          'reader_stop_scope': 'R3R3_ONLY', 'utc_ns': time.time_ns()}
mmio = None
try:
    with (ROOT / 'logs/cleanup-start-once.json').open('x') as handle:
        json.dump({'task': result['task'], 'utc_ns': time.time_ns()}, handle)
    lock = json.loads(LOCK.read_text())
    boot = P('/proc/sys/kernel/random/boot_id').read_text().strip()
    require(lock['task'] == result['task'] and lock['phase'] == 'POST_REBOOT' and
            lock['state'] == 'HELD' and lock['boot'] == boot,
            'POST_REBOOT_LOCK_OR_BOOT_MISMATCH')
    require(P('/sys/module/xdma_ahd_pcie').is_dir(), 'TASK_MODULE_NOT_LOADED')
    require(not P('/sys/module/xdma').exists(), 'PLATFORM_XDMA_MODULE_PRESENT')
    proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())

    # A capture-time rollback classification is historical evidence, not a
    # substitute for this cleanup's fresh descriptor and MMIO proof.  Unload
    # remains forbidden unless bounded_drain independently proves quiescence.
    t3_path = ROOT / 'logs/T3-result.json'
    if t3_path.exists():
        result['capture_time_rollback'] = json.loads(t3_path.read_text()).get(
            'rollback')
    stop_receipted_reader(result)

    holders = open_xdma_fds()
    require(not holders, 'NONCLEAN_XDMA_DESCRIPTOR_BEFORE_CLEANUP')
    mmio = MMIO('CLEANUP')
    bounded_drain(mmio, proof['c2h'], result)
    mmio.close()
    mmio = None
    holders = open_xdma_fds()
    result['open_xdma_fds_before_unload'] = holders
    require(not holders, 'XDMA_DESCRIPTOR_REMAINS_OPEN')

    attempt = ROOT / 'logs/cleanup-normal-unload-attempt.json'
    with attempt.open('x') as handle:
        json.dump({'attempt': 1, 'module': 'xdma_ahd_pcie',
                   'forced': False, 'utc_ns': time.time_ns()}, handle)
    unload = subprocess.run(['rmmod', 'xdma_ahd_pcie'], capture_output=True,
                            text=True, timeout=20)
    result.update(rmmod_attempts=1, rmmod_returncode=unload.returncode,
                  rmmod_stdout=unload.stdout, rmmod_stderr=unload.stderr)
    require(unload.returncode == 0, 'NORMAL_DRIVER_UNLOAD_FAILED')
    subprocess.run(['udevadm', 'settle', '--timeout=20'], check=True, timeout=21)

    require(not P('/sys/module/xdma_ahd_pcie').exists(),
            'TASK_MODULE_REMAINS_LOADED')
    require(not P('/sys/module/xdma').exists(), 'PLATFORM_XDMA_MODULE_PRESENT')
    for row in proof['all_nodes']:
        require(not P(row['node']).exists(), 'R3R3_XDMA_NODE_REMAINS')
    require(ENDPOINT.is_dir() and ROOT_PORT.is_dir(), 'EXACT_ENDPOINT_MISSING')
    require(not (ENDPOINT / 'driver').exists(), 'ENDPOINT_NOT_AUTOMATICALLY_UNBOUND')
    require((ENDPOINT / 'driver_override').read_text().strip() in ('', '(null)'),
            'DRIVER_OVERRIDE_NOT_EMPTY')
    require((ENDPOINT / 'current_link_speed').read_text().strip().startswith('5.0') and
            (ENDPOINT / 'current_link_width').read_text().strip() == '1' and
            (ROOT_PORT / 'current_link_speed').read_text().strip().startswith('5.0') and
            (ROOT_PORT / 'current_link_width').read_text().strip() == '1',
            'PCIE_LINK_NOT_GEN2_X1_AFTER_UNLOAD')
    require(P('/proc/sys/kernel/random/boot_id').read_text().strip() == boot,
            'ADDITIONAL_REBOOT_DETECTED')

    current_aer = {'endpoint': aer(ENDPOINT), 'root_port': aer(ROOT_PORT)}
    baseline_aer = json.loads((ROOT / 'logs/t1-proof.json').read_text())['aer_after']
    require(current_aer == baseline_aer, 'NEW_AER_COUNTER_DELTA')
    kernel_before = (ROOT / 'logs/kernel-immediate-before-load.txt').read_bytes()
    kernel_now = subprocess.check_output(['dmesg', '--color=never'])
    (ROOT / 'logs/kernel-after-unload.txt').write_bytes(kernel_now)
    require(kernel_now.startswith(kernel_before), 'KERNEL_BASELINE_CONTINUITY_LOST')
    delta = kernel_now[len(kernel_before):].decode('utf-8', 'replace')
    fatal = re.findall(
        r'(?im)^.*(?:\bOops\b|\bBUG:|Call Trace:|hung task|use-after-free|'
        r'IOMMU fault|DMA-API|completion timeout|malformed TLP|unsupported request|'
        r'surprise link|link[- ]down|xdma[^\n]*fatal).*$', delta)
    require(not fatal, 'NEW_KERNEL_OR_DRIVER_FATAL')

    result.update(result='PASS', boot_id=boot, module='ABSENT', nodes='REMOVED',
                  endpoint='PRESENT_UNBOUND', automatic_unbind='PASS',
                  platform_xdma='ABSENT', driver_override='EMPTY',
                  endpoint_link='Gen2 x1', root_port_link='Gen2 x1',
                  open_xdma_fds_after_unload=open_xdma_fds(), aer=current_aer,
                  aer_delta='NONE', kernel_fatal_matches=fatal,
                  taint_after_unload=int(P('/proc/sys/kernel/tainted').read_text()),
                  additional_reboots=0, power_cycles=0, flash_programming=0)
except BaseException as exc:
    result['blocker'] = str(exc)
finally:
    if mmio is not None:
        mmio.close()
    (ROOT / 'logs/cleanup-result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2), flush=True)

sys.exit(0 if result['result'] == 'PASS' else 1)
