"""R3R3 read-only runtime identity, live-source, and G2B baseline gate."""
import csv
import json
import os
import pathlib
import struct
import sys
import time

P = pathlib.Path
ROOT = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z')
LOCK = P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock/receipt.json')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


lock = json.loads(LOCK.read_text())
require(lock['task'] == 'G2B-HW0-PRODUCT-R3R3' and
        lock['phase'] == 'POST_REBOOT' and lock['state'] == 'HELD',
        'POST_REBOOT_LINUX_LOCK_REQUIRED')
require(P('/proc/sys/kernel/random/boot_id').read_text().strip() == lock['boot'],
        'UNEXPECTED_BOOT_TRANSITION_DURING_R3R3')
proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
require(proof['result'] == 'PASS', 'T1_NOT_PASS')
node = proof['user']
st = os.stat(node)
char_path = (P('/sys/dev/char') /
             f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}' / 'device').resolve()
require('0000:01:00.0' in str(char_path), 'USER_NODE_BDF_PROOF_CHANGED')
fd = os.open(node, os.O_RDONLY | os.O_NOFOLLOW)
log = (ROOT / 'logs/mmio-raw.csv').open('x', newline='')
writer = csv.writer(log)
writer.writerow(['Timestamp', 'Phase', 'Node', 'BDF', 'Offset', 'Value'])


def read(offset):
    require(P('/proc/sys/kernel/random/boot_id').read_text().strip() == lock['boot'],
            'UNEXPECTED_BOOT_TRANSITION_DURING_R3R3')
    require(offset % 4 == 0 and
            (0 <= offset <= 0x30 or 0x80 <= offset <= 0xB4 or
             0x3800 <= offset <= 0x3858), 'MMIO_READ_ALLOWLIST_VIOLATION')
    raw = os.pread(fd, 4, offset)
    require(len(raw) == 4, 'SHORT_MMIO_READ')
    value = struct.unpack('<I', raw)[0]
    writer.writerow([time.time_ns(), 'T2', node, proof['bdf'],
                     f'0x{offset:04X}', f'0x{value:08X}'])
    log.flush()
    os.fsync(log.fileno())
    return value


result = {'identity': 'NOT_REACHED', 'nvp': 'NOT_REACHED',
          'g2b': 'NOT_REACHED', 'result': 'BLOCKED'}
try:
    legacy = {f'0x{offset:04X}': read(offset) for offset in range(0, 0x34, 4)}
    expected = {
        0x00: 0xA40A0C07, 0x04: 0x0000400B, 0x08: 0x00031002,
        0x0C: 0x00010000, 0x24: 0x07E90002, 0x28: 6299465,
        0x2C: 0x00000103, 0x30: 0x58444D41,
    }
    for offset, value in expected.items():
        observed = legacy[f'0x{offset:04X}']
        require(observed == value,
                f'RUNTIME_PRODUCT_CANDIDATE_IDENTITY_MISMATCH:{offset:#x}:'
                f'{observed:#x}:{value:#x}')
    sha = ''.join(f'{legacy[f"0x{offset:04X}"]:08x}'
                  for offset in range(0x10, 0x24, 4))
    require(sha == '224d194e5f82c85bcb29297561c5d5e76d28063b',
            'RUNTIME_PRODUCT_CANDIDATE_IDENTITY_MISMATCH:' + sha)
    result.update(identity='PASS', embedded_git_sha=sha,
                  build_flags=legacy['0x002C'], legacy_values=legacy,
                  dual_layer_identity='PASS', product_profile='PASS')

    # Use three-second counter windows, bounded to 60 seconds total.
    readiness_start = time.monotonic()
    before = {f'0x{offset:04X}': read(offset)
              for offset in range(0x80, 0xB8, 4) if offset <= 0xB4}
    telemetry = None
    while time.monotonic() - readiness_start < 60.0:
        interval_start = time.monotonic()
        time.sleep(3.0)
        after = {f'0x{offset:04X}': read(offset)
                 for offset in range(0x80, 0xB8, 4) if offset <= 0xB4}
        seconds = time.monotonic() - interval_start
        delta = {key: (after[key] - before[key]) & 0xFFFFFFFF
                 for key in ('0x0080', '0x0084', '0x0088')}
        ratio = delta['0x0080'] / max(1, delta['0x0084'])
        sav_per_second = delta['0x0084'] / seconds
        telemetry = {'seconds': seconds, 'delta': delta,
                     'vclk_per_sav': ratio, 'sav_per_second': sav_per_second}
        ready = (after['0x008C'] & 0x3F == 0x39 and
                 after['0x0090'] == 0 and after['0x0094'] == 0 and
                 not (after['0x009C'] & 0x80000000) and
                 5200 <= ratio <= 5360 and 20000 <= sav_per_second <= 35000)
        if ready:
            result.update(nvp='PASS', nvp_values=after, telemetry=telemetry,
                          nack_count=after['0x0090'], init_error=after['0x0094'],
                          physical_source=0, fixed_live_source='PASS')
            break
        before = after
    require(result['nvp'] == 'PASS', 'FIXED_LIVE_AHD_SOURCE_NOT_READY')

    g2b = {f'0x{offset:04X}': read(offset)
           for offset in range(0x3800, 0x385C, 4)}
    require(g2b['0x3800'] == 0x43324831 and
            g2b['0x3804'] == 0x00010000 and
            g2b['0x3808'] == 0x000B001F, 'G2B_IDENTITY_MISMATCH')
    status = g2b['0x3810']
    require(g2b['0x380C'] == 0 and status & 0x10F == 0x004,
            'G2B_PRESESSION_STATE_NOT_QUIESCENT')
    require(status & 0xC0 == 0xC0 and not (status & 0x800),
            'FIXED_LIVE_AHD_SOURCE_NOT_READY')
    require(not (g2b['0x383C'] & 0x38), 'UNRESOLVED_ACTIVE_FATAL_STATE')
    result.update(g2b='PASS', g2b_values=g2b,
                  g2b_magic=g2b['0x3800'], abi_version=g2b['0x3804'],
                  capabilities=g2b['0x3808'], result='PASS')
except BaseException as exc:
    result['blocker'] = str(exc)
finally:
    os.close(fd)
    log.close()
    (ROOT / 'logs/t2-result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2), flush=True)

sys.exit(0 if result['result'] == 'PASS' else 1)
