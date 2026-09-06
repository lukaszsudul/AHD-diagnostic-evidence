set -eu
cd /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z
python3 - <<'PY'
import hashlib, json, os, pathlib, re, subprocess, time
P = pathlib.Path
root = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z')
lock_path = P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock/receipt.json')
module = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko')
endpoint = P('/sys/bus/pci/devices/0000:01:00.0')
root_port = P('/sys/bus/pci/devices/0000:00:01.1')
result = {'task': 'G2B-HW0-PRODUCT-R3R3', 'result': 'BLOCKED',
          'insmod_attempts': 0, 'normal_unload_attempts': 0}
loaded = False

def cmd(*args):
    return subprocess.check_output(args, text=True).rstrip('\n')

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
                    found.append({'pid': int(proc.name), 'comm': comm, 'target': target})
        except (OSError, PermissionError):
            pass
    return found

try:
    lock = json.loads(lock_path.read_text())
    assert lock['task'] == 'G2B-HW0-PRODUCT-R3R3'
    assert lock['phase'] == 'POST_REBOOT' and lock['state'] == 'HELD'
    assert P('/proc/sys/kernel/random/boot_id').read_text().strip() == lock['boot']
    assert module.is_file() and not module.is_symlink()
    assert not (module.stat().st_mode & 0o222)
    assert not (module.parent.stat().st_mode & 0o222)

    fields = ('name', 'vermagic', 'alias', 'depends', 'srcversion', 'signer', 'sig_id')
    info = {field: cmd('modinfo', '-F', field, str(module)) for field in fields}
    info.update(
        sha256=hashlib.sha256(module.read_bytes()).hexdigest().upper(),
        bytes=module.stat().st_size,
        secure_boot=cmd('mokutil', '--sb-state'),
        elf=cmd('readelf', '-h', str(module)),
        notes=cmd('readelf', '-n', str(module)),
        taint_before=int(P('/proc/sys/kernel/tainted').read_text()),
    )
    (root / 'logs/driver-verification.json').write_text(json.dumps(info, indent=2) + '\n')
    assert info['bytes'] == 3296104
    assert info['sha256'] == 'E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77'
    assert info['name'] == 'xdma_ahd_pcie'
    assert info['vermagic'] == '7.0.0-29-generic SMP preempt mod_unload modversions '
    assert info['alias'] == 'pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*'
    assert info['depends'] == '' and info['signer'] == '' and info['sig_id'] == ''
    assert info['srcversion'] == 'EE8B149D1883AE8C6B1EE31'
    assert '1471c3a284ec1cb26115fe9e9bd59890a034f83e' in info['notes']
    assert 'Advanced Micro Devices X86-64' in info['elf']
    assert 'SecureBoot disabled' in info['secure_boot']

    assert endpoint.is_dir() and root_port.is_dir()
    assert (endpoint / 'vendor').read_text().strip() == '0x10ee'
    assert (endpoint / 'device').read_text().strip() == '0x7011'
    assert (endpoint / 'subsystem_vendor').read_text().strip() == '0x10ee'
    assert (endpoint / 'subsystem_device').read_text().strip() == '0x0007'
    assert (endpoint / 'class').read_text().strip() == '0x058000'
    assert not (endpoint / 'driver').exists()
    assert (endpoint / 'driver_override').read_text().strip() in ('', '(null)')
    assert not P('/sys/module/xdma').exists()
    assert not P('/sys/module/xdma_ahd_pcie').exists()
    assert not list(P('/dev').glob('xdma*'))
    assert not open_xdma_fds()
    assert (endpoint / 'current_link_speed').read_text().strip().startswith('5.0')
    assert (endpoint / 'current_link_width').read_text().strip() == '1'
    assert (root_port / 'current_link_speed').read_text().strip().startswith('5.0')
    assert (root_port / 'current_link_width').read_text().strip() == '1'

    kernel_before = subprocess.check_output(['dmesg', '--color=never'])
    (root / 'logs/kernel-immediate-before-load.txt').write_bytes(kernel_before)
    aer_before = {'endpoint': aer(endpoint), 'root_port': aer(root_port)}
    lspci_before = {bdf: subprocess.check_output(['lspci', '-s', bdf, '-vvv'], text=True)
                    for bdf in ('0000:01:00.0', '0000:00:01.1')}
    (root / 'logs/pcie-health-before-load.json').write_text(
        json.dumps({'aer': aer_before, 'lspci': lspci_before}, indent=2) + '\n')

    with (root / 'logs/insmod-attempt.json').open('x') as handle:
        json.dump({'attempt': 1, 'utc_ns': time.time_ns(), 'module': str(module)}, handle)
    result['insmod_attempts'] = 1
    load = subprocess.run(['insmod', str(module)], capture_output=True, text=True,
                          timeout=20)
    loaded = P('/sys/module/xdma_ahd_pcie').exists()
    result.update(insmod_returncode=load.returncode,
                  insmod_stdout=load.stdout, insmod_stderr=load.stderr,
                  taint_after_load=int(P('/proc/sys/kernel/tainted').read_text()))
    (root / 'logs/driver-load.json').write_text(json.dumps(result, indent=2) + '\n')
    if load.returncode:
        raise RuntimeError('EXACT_ALIAS_AUTOMATIC_BIND_FAILED')
    subprocess.run(['udevadm', 'settle', '--timeout=20'], timeout=21, check=True)
    deadline = time.monotonic() + 20.0
    while not list(P('/dev').glob('xdma*_c2h_0')) and time.monotonic() < deadline:
        time.sleep(0.1)

    assert P('/sys/module/xdma_ahd_pcie').exists()
    assert not P('/sys/module/xdma').exists()
    driver = (endpoint / 'driver').resolve()
    assert driver.name == 'xdma_ahd_pcie'
    bound = sorted(item.name for item in driver.iterdir() if item.name.startswith('0000:'))
    assert bound == ['0000:01:00.0'], ('UNINTENDED_ENDPOINT_BOUND', bound)

    rows = []
    for node in sorted(P('/dev').glob('xdma*')):
        st = node.stat()
        char = P('/sys/dev/char') / f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}'
        cls = P('/sys/class/xdma') / node.name
        rows.append({
            'node': str(node), 'major': os.major(st.st_rdev),
            'minor': os.minor(st.st_rdev), 'mode': oct(st.st_mode),
            'char_path': str(char.resolve()),
            'char_device': str((char / 'device').resolve()),
            'class_path': str(cls.resolve()),
            'class_device': str((cls / 'device').resolve()),
        })
    (root / 'logs/node-map.json').write_text(json.dumps(rows, indent=2) + '\n')
    users = [row for row in rows if re.fullmatch(r'/dev/xdma\d+_user', row['node'])]
    c2hs = [row for row in rows if re.fullmatch(r'/dev/xdma\d+_c2h_0', row['node'])]
    assert len(users) == 1 and len(c2hs) == 1
    for row in users + c2hs:
        assert '0000:01:00.0' in row['char_path'] or '0000:01:00.0' in row['char_device']
        assert '0000:01:00.0' in row['class_path'] or '0000:01:00.0' in row['class_device']
    user_index = re.fullmatch(r'/dev/xdma(\d+)_user', users[0]['node']).group(1)
    c2h_index = re.fullmatch(r'/dev/xdma(\d+)_c2h_0', c2hs[0]['node']).group(1)
    assert user_index == c2h_index
    assert not open_xdma_fds()

    kernel_after = subprocess.check_output(['dmesg', '--color=never'])
    (root / 'logs/kernel-after-load.txt').write_bytes(kernel_after)
    assert kernel_after.startswith(kernel_before), 'KERNEL_BASELINE_CONTINUITY_LOST'
    kernel_delta = kernel_after[len(kernel_before):].decode('utf-8', 'replace')
    (root / 'logs/kernel-load-delta.txt').write_text(kernel_delta)
    fatal = re.findall(
        r'(?im)^.*(?:\bOops\b|\bBUG:|Call Trace:|hung task|use-after-free|'
        r'IOMMU fault|DMA-API|completion timeout|malformed TLP|unsupported request|'
        r'surprise link|link[- ]down|xdma[^\n]*fatal).*$', kernel_delta)
    assert not fatal, ('NEW_KERNEL_OR_DRIVER_FATAL', fatal[:4])
    aer_after = {'endpoint': aer(endpoint), 'root_port': aer(root_port)}
    assert aer_after == aer_before, ('NEW_AER_COUNTER_DELTA', aer_before, aer_after)
    assert (endpoint / 'current_link_speed').read_text().strip().startswith('5.0')
    assert (endpoint / 'current_link_width').read_text().strip() == '1'
    assert (root_port / 'current_link_speed').read_text().strip().startswith('5.0')
    assert (root_port / 'current_link_width').read_text().strip() == '1'
    taint_delta = result['taint_after_load'] ^ info['taint_before']
    assert not (taint_delta & ~((1 << 12) | (1 << 13))), ('UNEXPECTED_TAINT_DELTA', taint_delta)

    proof = {
        'result': 'PASS', 'bdf': '0000:01:00.0',
        'user': users[0]['node'], 'c2h': c2hs[0]['node'],
        'dynamic_index': int(user_index), 'all_nodes': rows,
        'bound_endpoints': bound, 'unintended_endpoints_bound': 0,
        'taint_before': info['taint_before'],
        'taint_after_load': result['taint_after_load'],
        'kernel_fatal_matches': fatal, 'aer_before': aer_before,
        'aer_after': aer_after,
    }
    (root / 'logs/t1-proof.json').write_text(json.dumps(proof, indent=2) + '\n')
    result.update(result='PASS', node_proof=proof)
    print(json.dumps(result, indent=2), flush=True)
    print('T1_GATE=PASS', flush=True)
except BaseException as exc:
    result['blocker'] = str(exc)
    if loaded or P('/sys/module/xdma_ahd_pcie').exists():
        holders = open_xdma_fds()
        result['cleanup_open_xdma_fds'] = holders
        if not holders:
            with (root / 'logs/normal-unload-attempt.json').open('x') as handle:
                json.dump({'reason': 'T1_FAILURE_BEFORE_MMIO_OR_DMA', 'attempt': 1}, handle)
            unload = subprocess.run(['rmmod', 'xdma_ahd_pcie'], capture_output=True,
                                    text=True, timeout=20)
            result['normal_unload_attempts'] = 1
            result['cleanup_unload_returncode'] = unload.returncode
            result['cleanup_unload_stdout'] = unload.stdout
            result['cleanup_unload_stderr'] = unload.stderr
            subprocess.run(['udevadm', 'settle', '--timeout=20'], timeout=21)
    (root / 'logs/t1-failure.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2), flush=True)
    raise
finally:
    (root / 'logs/t1-result.json').write_text(json.dumps(result, indent=2) + '\n')
PY
