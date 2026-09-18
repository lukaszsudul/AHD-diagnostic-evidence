#!/usr/bin/env python3
"""Bounded W4 control and one block per invocation; no camera or DMA action."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import time

from cont1r3 import contract as tcontract, projection, telemetry
from cont1r3.characterizer import LiveScanner
from cont1r3.runtime_preflight import (ACQ_MAGIC, ACQ_VERSION, ACQ_CAPABILITIES,
    ACQ_STATUS, ACQ_COMMAND_SEQUENCE, ACQ_COMPLETED_SEQUENCE,
    ACQ_FUNCTIONAL_WRITE_COUNT, ACQ_UNAUTHORIZED_WRITE_COUNT, ACQ_ERROR_COUNTS,
    ACQ_SANITY, ACQ_SANITY_COUNT, ACQ_SANITY_TOKEN)
from scan1 import mmio
from scan1.controller import ScannerController
from w3a import contract as wcontract
from w3a.controller import W3AController, OBSERVED
from w3a.device import VerifiedMmioDevice, DeviceSelectionError


TASK = 'CONT1R3R4R7-W4-C3-PNR1-AB'
BOOT_PATH = Path('/proc/sys/kernel/random/boot_id')
PLAN_PATH = Path(__file__).resolve().parent / 'W4_PLAN.json'
PLAN_SHA256 = '5FD3F3A27BFBEE24341FC7C095429A43541CB941F6B23C2E2C3F2FB84F8AE47D'
DRIVER = Path('/home/vcdeagent1/vcde_builds/g2b_hw0_drv1/20260906T121539Z/BUILD_A/source/XDMA/linux-kernel/xdma/xdma_ahd_pcie.ko')
DRIVER_SHA256 = 'E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77'
EXPECTED_SHA_WORDS = (0x70266F0B, 0x90C6FC6A, 0x853495EB, 0xA1D526B2, 0x85FD7286)
EXPECTED_AB = 'ABBA' + 'BAAB' + 'ABBA' + 'BAAB'


def need(ok: bool, reason: str) -> None:
    if not ok:
        raise RuntimeError(reason)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def canonical(value: object) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True) + '\n').encode('ascii')


def write_once(path: Path, data: bytes) -> str:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(fd, 'wb', closefd=False) as out:
            out.write(data)
            out.flush()
        os.fsync(fd)
    finally:
        os.close(fd)
    return sha(data)


def replace_state(path: Path, obj: dict) -> None:
    temp = path.with_suffix('.tmp')
    need(not temp.exists(), 'W4_STATE_TEMP_PREEXISTS')
    write_once(temp, canonical(obj))
    os.replace(temp, path)
    parent = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(parent)
    finally:
        os.close(parent)


def plan() -> dict:
    data = PLAN_PATH.read_bytes()
    need(sha(data) == PLAN_SHA256, 'W4_PLAN_BYTES_MISMATCH')
    p = json.loads(data)
    modes = ''.join(row['mode'] for row in p['blocks'])
    need(modes == EXPECTED_AB and len(p['blocks']) == 16 and
         all(row['block_index'] == i + 1 and row['max_scans'] == 16 and
             row['max_elapsed_seconds'] == 180 and
             row['replica'] == ('I' if i < 8 else 'II')
             for i, row in enumerate(p['blocks'])) and
         p['max_ab_scans'] == 256 and p['control_scans'] == 1,
         'W4_PLAN_SEMANTIC_MISMATCH')
    return p


def static_self_test() -> dict:
    p = plan()
    wcontract.load_and_validate()
    ScannerController.__module__ == 'scan1.controller' or need(False, 'SCAN1_MODULE_ORIGIN')
    try:
        VerifiedMmioDevice(node='/dev/xdma0_user', bdf='BAD')
    except DeviceSelectionError:
        pass
    else:
        need(False, 'INVALID_BDF_NOT_REJECTED')
    try:
        VerifiedMmioDevice(node='/dev/other_user', bdf='0000:01:00.0')
    except DeviceSelectionError:
        pass
    else:
        need(False, 'INVALID_NODE_NOT_REJECTED')
    from scan1.manifest import load_and_validate
    entries, _, _ = load_and_validate()
    need(len(entries) == 82 and tcontract.CLEAN_TRANSACTION_COUNT == 105 and
         projection.manifest_preflight()['result'] == 'PASS' and
         telemetry.schema_sha256() == tcontract.EXPECTED_SCHEMA_SHA256,
         'INHERITED_HOST_CONTRACT_GATE')
    need(p['recovered_nack_ceiling'] is None, 'RECOVERED_NACK_CEILING_NOT_NONE')
    need((0x00031002 & 0xFF) == 2, 'SLOT_COUNT_FIELD_INTERPRETATION')
    root = Path(__file__).resolve().parent
    for package in ('scan1', 'scan1.mmio', 'scan1.controller', 'cont1r3',
                    'cont1r3.telemetry', 'cont1r3.characterizer',
                    'cont1r3.runtime_preflight', 'w3a', 'w3a.controller',
                    'w3a.device'):
        loaded = sys.modules[package]
        need(Path(loaded.__file__).resolve().is_relative_to(root),
             'IMPORT_OUTSIDE_CLOSED_BUNDLE:' + package)
    class FakeDevice:
        bdf = '0000:01:00.0'
        def read32(self, address):
            return address
        def write32(self, address, value):
            need(False, 'SELF_TEST_UNEXPECTED_MMIO_WRITE')
    with tempfile.TemporaryDirectory() as temp:
        task_root = Path(temp)
        hard_stop(FakeDevice(), task_root, 'offline-test', RuntimeError('INCOMPLETE'))
        need((task_root / 'hard-stop' / 'W4_HARD_STOP_RECEIPT.json').is_file(),
             'INCOMPLETE_HARD_STOP_NOT_PERSISTED')
        state_path = task_root / 'campaign' / 'state.json'
        state_path.parent.mkdir()
        state_path.write_bytes(canonical({'hard_stop': True, 'blocks_completed': 0,
                                          'plan_sha256': PLAN_SHA256,
                                          'control': 'PASS_CLEAN'}))
        try:
            block(FakeDevice(), task_root, 1)
        except RuntimeError as ex:
            need(str(ex) == 'BLOCK_ORDER_OR_PRIOR_HARD_STOP',
                 'NEXT_BLOCK_WRONG_REJECTION')
        else:
            need(False, 'NEXT_BLOCK_AFTER_HARD_STOP_ACCEPTED')
    return {'result': 'PASS', 'device_opened': False, 'plan_sha256': PLAN_SHA256,
            'ab_scans': sum(row['max_scans'] for row in p['blocks']),
            'recovered_nack_ceiling': None, 'next_block_after_hard_stop': False,
            'incomplete_attempts_persisted_by_hard_stop': True}


def bound_os_gate(node: str, bdf: str, boot: str) -> dict:
    need(BOOT_PATH.read_text().strip() == boot, 'BOOT_ID_CHANGED')
    need(sha(DRIVER.read_bytes()) == DRIVER_SHA256, 'EXACT_DRIVER_BYTES_MISMATCH')
    need(not Path('/sys/module/xdma').exists(), 'FOREIGN_XDMA_NAMESPACE')
    pci = Path('/sys/bus/pci/devices') / bdf
    need(pci.is_dir() and (pci / 'driver').resolve().name == 'xdma_ahd_pcie' and
         (pci / 'driver/module').resolve().name == 'xdma_ahd_pcie',
         'TARGET_DRIVER_MAPPING_MISMATCH')
    need((pci / 'current_link_speed').read_text().strip() == '5.0 GT/s PCIe' and
         (pci / 'current_link_width').read_text().strip() == '1', 'AHD_LINK_NOT_GEN2_X1')
    need(node.startswith('/dev/xdma') and node.endswith('_user'), 'USER_NODE_EXPLICIT_REQUIRED')
    c2h = node[:-5] + '_c2h_0'
    st = os.stat(c2h)
    c2h_ancestry = (Path('/sys/dev/char') / f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}').resolve()
    need(bdf in c2h_ancestry.parts and c2h_ancestry.name == Path(c2h).name,
         'C2H_NODE_TARGET_ANCESTRY_MISMATCH')
    return {'boot_id': boot, 'bdf': bdf, 'user_node': node, 'c2h_node': c2h,
            'c2h_dev_t': f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}',
            'c2h_ancestry': str(c2h_ancestry), 'driver_sha256': DRIVER_SHA256}


def safe_idle(device, *, locked: bool) -> dict:
    scanner = device.read32(mmio.STATUS)
    acq = device.read32(ACQ_STATUS)
    wstatus = device.read32(0x13818)
    stream = device.read32(0x380C)
    need(scanner == (mmio.STATUS_IDLE | mmio.STATUS_AUTOINIT_DONE),
         f'SCAN1_NOT_CLEAN_IDLE:{scanner:#010x}')
    need(acq & ((1 << 0) | (1 << 4) | (1 << 23)) == ((1 << 0) | (1 << 4) | (1 << 23)) and
         acq & ((1 << 1) | (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) |
                (1 << 7) | (1 << 22)) == 0 and ((acq >> 8) & 0x3F) == 0,
         f'ACQ_EXECUTOR_I2C_NOT_IDLE:{acq:#010x}')
    need(stream == 0, f'TRANSPORT_STREAM_NOT_OFF:{stream:#010x}')
    need(wstatus & ((1 << 1) | (1 << 7)) == 0 and
         bool(wstatus & (1 << 3)) == locked,
         f'W3A_BLOCK_OR_LOCKOUT_STATE:{wstatus:#010x}')
    return {'scanner_status': scanner, 'acq_status': acq,
            'w3a_status': wstatus, 'stream_enable': stream}


def identity(device) -> dict:
    words = tuple(device.read32(a) for a in (0x10, 0x14, 0x18, 0x1C, 0x20))
    flags = device.read32(0x2C)
    capabilities = device.read32(0x08)
    need(words == EXPECTED_SHA_WORDS and flags == 0x00000802 and
         capabilities == 0x00031002, 'C3_RUNTIME_SOURCE_IDENTITY_MISMATCH')
    scanner = ScannerController(device).identity()
    inherited = telemetry.read_identity(device)
    acq = tuple(device.read32(a) for a in (ACQ_MAGIC, ACQ_VERSION, ACQ_CAPABILITIES))
    need(acq == (0x4E564143, 0x00010000, 0x000000FF), 'ACQ_IDENTITY_MISMATCH')
    w3a = W3AController(device).identity()
    return {'git_sha_words': [f'{v:08X}' for v in words], 'build_flags': flags,
            'slot_count': capabilities & 0xFF, 'scan1': scanner,
            'inherited_telemetry': inherited, 'acq': acq, 'w3a': w3a}


def preflight(device) -> dict:
    ids = identity(device)
    safe_idle(device, locked=False)
    initial = {f'{a:#x}': device.read32(a) for a in
               (ACQ_STATUS, ACQ_COMMAND_SEQUENCE, ACQ_COMPLETED_SEQUENCE,
                ACQ_FUNCTIONAL_WRITE_COUNT, ACQ_UNAUTHORIZED_WRITE_COUNT,
                ACQ_ERROR_COUNTS)}
    need(all(device.read32(a) == 0 for a in
             (ACQ_COMMAND_SEQUENCE, ACQ_COMPLETED_SEQUENCE,
              ACQ_FUNCTIONAL_WRITE_COUNT, ACQ_UNAUTHORIZED_WRITE_COUNT,
              ACQ_ERROR_COUNTS)), 'ACQ_PREEXISTING_ACTION_OR_ERROR')
    scan = ScannerController(device).mmio_sanity(16)
    sanity_start = device.read32(ACQ_SANITY_COUNT)
    for i in range(16):
        safe_idle(device, locked=False)
        device.write32(ACQ_SANITY, ACQ_SANITY_TOKEN)
        need(device.read32(ACQ_SANITY) == ACQ_SANITY_TOKEN and
             device.read32(ACQ_SANITY_COUNT) == sanity_start + i + 1,
             f'ACQ_INERT_SANITY_FAILED:{i + 1}')
    final = safe_idle(device, locked=False)
    need(device.read32(ACQ_FUNCTIONAL_WRITE_COUNT) == 0 and
         device.read32(ACQ_ERROR_COUNTS) == 0, 'ACQ_SANITY_SIDE_EFFECT')
    return {'result': 'PASS', 'identities': ids, 'initial_acq': initial,
            'scan1_mmio_sanity': len(scan), 'acq_mmio_sanity': 16,
            'final_idle': final, 'autoinit_nack_count': 'NOT_EXPOSED/NOT_INDEPENDENTLY_MEASURED'}


def raw_w3a(device) -> dict:
    first = {f'{a:#x}': device.read32(a) for a in OBSERVED}
    second = {f'{a:#x}': device.read32(a) for a in OBSERVED}
    need(first == second, 'W3A_RAW_RECORD_NONCOHERENT')
    return first


def hard_stop(device, root: Path, stage: str, error: Exception) -> dict:
    # Read only. In particular, do not ACK, CLEAR, CLOSE or switch mode here.
    record = {'schema': 'AHD_V41_W4_HARD_STOP_V1', 'task': TASK,
              'stage': stage, 'error_type': type(error).__name__,
              'error': str(error), 'utc_ns': time.time_ns(), 'raw': {}}
    addresses = tuple(range(0x12010, 0x12080, 4)) + tuple(OBSERVED) + (ACQ_STATUS, 0x380C)
    for a in addresses:
        try:
            record['raw'][f'{a:#x}'] = device.read32(a)
        except Exception as ex:
            record['raw'][f'{a:#x}'] = 'UNAVAILABLE:' + type(ex).__name__
    for name in ('aer_dev_correctable', 'aer_dev_nonfatal', 'aer_dev_fatal'):
        try:
            record[name] = (Path('/sys/bus/pci/devices') / getattr(device, 'bdf') / name).read_text().strip()
        except Exception:
            record[name] = 'UNAVAILABLE'
    first = root / 'hard-stop' / 'W4_HARD_STOP_RECEIPT.json'
    target = first if not first.exists() else root / 'hard-stop' / 'W4_HARD_STOP_RECEIPT_R1.json'
    record['sha256'] = write_once(target, canonical(record))
    return record


def scan_once(device, scanner: LiveScanner, w3a: W3AController, root: Path,
              label: str, mode: str, block_id: int, index: int | None) -> dict:
    safe_idle(device, locked=True)
    before_generation = device.read32(mmio.GENERATION)
    before_attempt = device.read32(0x1381C)
    host_start = time.time_ns()
    scanner.start()
    snapshot = scanner.read_legacy_frozen()
    sideband = telemetry.read_frozen(device, snapshot)
    retained = w3a.read_retained()
    wraw = raw_w3a(device)
    status = device.read32(0x13818)
    after_attempt = device.read32(0x1381C)
    need(bool(status & (1 << 4)) == (mode == 'B') and
         bool(status & (1 << 2)) == (mode == 'B') and
         bool(status & (1 << 3)) and device.read32(0x13814) == block_id and
         after_attempt == ((before_attempt + 1) & 0xFFFFFFFF),
         'W3A_EFFECTIVE_MODE_BLOCK_OR_ATTEMPT_MISMATCH')
    need(snapshot['generation'] != before_generation and
         retained['primary'] is None and retained['cleanup'] is None,
         'GENERATION_OR_BANK_FAILURE_RECORD')
    events = sideband['events']
    need(snapshot['retried_entry_count'] == len(events) and
         snapshot['transaction_count'] == 105 + len(events),
         'RETRY_TRANSACTION_RECONCILIATION')
    need(all(e['first_attempt_raw_cause_name'] in
             ('WADDR_NACK', 'REGADDR_NACK', 'RADDR_NACK') for e in events),
         'RECOVERED_CAUSE_CLASS_MISMATCH')
    summary = {'task': TASK, 'label': label, 'ab_index': index, 'mode': mode,
               'block_id': block_id, 'attempt_id': after_attempt,
               'generation_before': before_generation,
               'generation_after': snapshot['generation'],
               'complete': True, 'host_start_ns': host_start,
               'host_collected_ns': time.time_ns(),
               'fpga_start_tick': snapshot['start_ticks'],
               'fpga_end_tick': snapshot['end_ticks'],
               'entry_count': 82, 'group_count': 10,
               'transaction_count': snapshot['transaction_count'],
               'retried_entry_count': snapshot['retried_entry_count'],
               'regaddr_nack_events': sum(e['first_attempt_raw_cause_name'] == 'REGADDR_NACK'
                                          for e in events),
               'first_entry_read_opportunities': 82,
               'other_recovered_causes': [e['first_attempt_raw_cause_name']
                                          for e in events if e['first_attempt_raw_cause_name'] != 'REGADDR_NACK'],
               'a8_pre': snapshot['a8_pre'], 'a8_post': snapshot['a8_post'],
               'projection': snapshot['projection'],
               'bank_restore': snapshot['entry_bank_restore'],
               'w3a_status': status, 'w3a_raw': wraw,
               'w3a_retained': retained,
               'events': events, 'legacy_raw_sha256': telemetry.words_sha256(snapshot['_raw_words']),
               'telemetry_raw_sha256': telemetry.words_sha256(sideband['_raw_words'])}
    raw = (struct.pack('<II', len(snapshot['_raw_words']), len(sideband['_raw_words'])) +
           struct.pack(f"<{len(snapshot['_raw_words'])}I", *snapshot['_raw_words']) +
           struct.pack(f"<{len(sideband['_raw_words'])}I", *sideband['_raw_words']))
    prefix = root / 'campaign' / label
    summary['complete_raw_sha256'] = write_once(prefix.with_suffix('.bin'), raw)
    summary['complete_raw_bytes'] = len(raw)
    write_once(prefix.with_suffix('.json'), canonical(summary))
    scanner.acknowledge()
    safe_idle(device, locked=True)
    return summary


def control(device, root: Path) -> dict:
    state_path = root / 'campaign' / 'state.json'
    need(not state_path.exists() and not (root / 'campaign' / 'control.json').exists(),
         'CONTROL_ALREADY_STARTED_NO_REPEAT')
    p = plan()
    ids = identity(device)
    safe_idle(device, locked=False)
    w3a = W3AController(device)
    old = w3a.read_retained()
    old_raw = raw_w3a(device)
    old_sha = write_once(root / 'campaign' / 'precontrol_retained.json',
                         canonical({'decoded': old, 'raw': old_raw}))
    if old['primary'] is not None or old['cleanup'] is not None:
        w3a.clear_after_persisted(old_sha)
    safe_idle(device, locked=False)
    block_id = 0xC3000001
    w3a.arm(block_id, False)
    scanner = LiveScanner(device)
    row = scan_once(device, scanner, w3a, root, 'control', 'A', block_id, None)
    check = json.loads((root / 'campaign' / 'control.json').read_text())
    del check
    from scan1.manifest import load_and_validate
    entries, _, _ = load_and_validate()
    # The raw register set is already validated by inherited LiveScanner;
    # reconstruct only the two ID values from the persisted legacy words.
    raw = (root / 'campaign' / 'control.bin').read_bytes()
    legacy_count, _ = struct.unpack_from('<II', raw, 0)
    legacy = struct.unpack_from(f'<{legacy_count}I', raw, 8)
    header_count = legacy_count - 40 - 82
    entry_words = legacy[header_count + 40:]
    need(entries[1].bank == 0 and entries[1].register == 0xF4 and
         entries[2].bank == 0 and entries[2].register == 0xF5 and
         (entry_words[1] >> 8) & 0xFF == 0x90 and
         (entry_words[2] >> 8) & 0xFF == 0x01,
         'LIVE_CHIP_ID_OR_REVISION_MISMATCH')
    safe_idle(device, locked=True)
    w3a.close()
    safe_idle(device, locked=False)
    state = {'task': TASK, 'plan_sha256': PLAN_SHA256,
             'control': 'PASS_WITH_RECOVERED_NACK' if row['retried_entry_count'] else 'PASS_CLEAN',
             'control_regaddr_nack_events': row['regaddr_nack_events'],
             'control_other_recovered_causes': row['other_recovered_causes'],
             'live_chip_id': '0x90', 'live_revision': '0x01',
             'blocks_completed': 0, 'ab_attempted': 0, 'ab_complete': 0,
             'hard_stop': False, 'runtime_identity': ids,
             'plan_modes': ''.join(b['mode'] for b in p['blocks'])}
    replace_state(state_path, state)
    return state


def block(device, root: Path, index: int) -> dict:
    p = plan()
    need(1 <= index <= 16, 'BLOCK_INDEX_RANGE')
    state_path = root / 'campaign' / 'state.json'
    state = json.loads(state_path.read_text())
    need(not state['hard_stop'] and state['blocks_completed'] == index - 1 and
         state['plan_sha256'] == PLAN_SHA256 and state['control'].startswith('PASS'),
         'BLOCK_ORDER_OR_PRIOR_HARD_STOP')
    block_plan = p['blocks'][index - 1]
    mode = block_plan['mode']
    block_id = 0xC3000100 + index
    identity(device)
    safe_idle(device, locked=False)
    w3a = W3AController(device)
    w3a.arm(block_id, mode == 'B')
    scanner = LiveScanner(device)
    rows = []
    first_start = None
    for n in range(1, 17):
        if first_start is not None and time.monotonic() - first_start >= 180:
            break
        if first_start is None:
            first_start = time.monotonic()  # conservative bound before first admission
        label = f'block-{index:02d}-scan-{n:02d}'
        rows.append(scan_once(device, scanner, w3a, root, label, mode, block_id,
                              state['ab_attempted'] + n))
    safe_idle(device, locked=True)
    end_retained = w3a.read_retained()
    need(end_retained['primary'] is None and end_retained['cleanup'] is None,
         'BLOCK_END_BANK_FAILURE_RECORD')
    w3a.close()
    safe_idle(device, locked=False)
    complete = len(rows)
    result = {'block_index': index, 'mode': mode, 'replica': block_plan['replica'],
              'attempted': complete, 'complete': complete,
              'time_budget_incomplete': complete < 16,
              'regaddr_nack_events': sum(r['regaddr_nack_events'] for r in rows),
              'first_entry_read_opportunities': 82 * complete,
              'scans_with_retries': sum(r['retried_entry_count'] > 0 for r in rows),
              'other_recovered_causes': sum(len(r['other_recovered_causes']) for r in rows),
              'block_id': block_id, 'end_retained': end_retained}
    write_once(root / 'campaign' / f'block-{index:02d}-summary.json', canonical(result))
    state['blocks_completed'] = index
    state['ab_attempted'] += complete
    state['ab_complete'] += complete
    state.setdefault('blocks', []).append(result)
    replace_state(state_path, state)
    return result


def main() -> int:
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=('self-test', 'preflight', 'control', 'block'), required=True)
    parser.add_argument('--node')
    parser.add_argument('--bdf')
    parser.add_argument('--boot-id')
    parser.add_argument('--run-root', type=Path)
    parser.add_argument('--block-index', type=int)
    args = parser.parse_args()
    if args.mode == 'self-test':
        need(not any((args.node, args.bdf, args.boot_id, args.run_root, args.block_index)),
             'SELF_TEST_HARDWARE_ARGUMENT_FORBIDDEN')
        print(json.dumps(static_self_test(), sort_keys=True))
        return 0
    need(all((args.node, args.bdf, args.boot_id, args.run_root)),
         'EXPLICIT_NODE_BDF_BOOT_ROOT_REQUIRED')
    need(args.run_root.is_dir() and not args.run_root.is_symlink(), 'RUN_ROOT_NOT_PRIVATE_DIRECTORY')
    os_gate = bound_os_gate(args.node, args.bdf, args.boot_id)
    with VerifiedMmioDevice(node=args.node, bdf=args.bdf) as device:
        stage = args.mode if args.mode != 'block' else f'block-{args.block_index}'
        try:
            if args.mode == 'preflight':
                result = preflight(device)
                result['os_gate'] = os_gate
                write_once(args.run_root / 'deployment' / 'runtime_preflight.json', canonical(result))
            elif args.mode == 'control':
                need((args.run_root / 'deployment' / 'runtime_preflight.json').is_file(),
                     'RUNTIME_PREFLIGHT_RECEIPT_MISSING')
                result = control(device, args.run_root)
            else:
                need(args.block_index is not None, 'BLOCK_INDEX_REQUIRED')
                result = block(device, args.run_root, args.block_index)
            print(json.dumps({'result': 'PASS', 'stage': stage, 'data': result}, sort_keys=True))
            return 0
        except Exception as ex:
            record = hard_stop(device, args.run_root, stage, ex)
            print(json.dumps({'result': 'HARD_STOP', 'stage': stage,
                              'error': str(ex), 'hard_stop_sha256': record['sha256']}, sort_keys=True))
            return 2


if __name__ == '__main__':
    raise SystemExit(main())
