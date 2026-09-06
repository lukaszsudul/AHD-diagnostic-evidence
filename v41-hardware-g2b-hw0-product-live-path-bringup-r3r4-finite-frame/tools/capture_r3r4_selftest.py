#!/usr/bin/env python3
"""Offline hard-gate suite for the R3R4 capture architecture."""
from __future__ import annotations

import argparse
import hashlib
import inspect
import json
import os
from pathlib import Path
import shutil
import sys
import time
import traceback

from abi_v1 import (
    AbiContract, RecordMetadata, build_record, deterministic_line_payload,
)
import capture_r3r4 as capture
from frame_reconstruct_r3r4 import reconstruct_first_frame


ABI_SHA256 = 'AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6'
CASE_NAMES = (
    'FIRST_RECORD_PERSISTENCE_PASS',
    'PARTIAL_READ_ASSEMBLY_PASS',
    'PRIMARY_2500_BOUNDARY_PASS',
    'DRAIN_CAPTURE_PASS',
    'PARENT_QUIESCENCE_HANDSHAKE_PASS',
    'FAILURE_PRESERVES_RAW_DATA_PASS',
    'EXCEPTION_DETAIL_PASS',
    'COMPLETE_FRAME_RECONSTRUCTION_PASS',
    'EXACT_CAPTURE_HASH_PASS',
    'NO_BLANK_BLOCKER_PASS',
    'NO_RAW_RECORD_IPC_PASS',
)


class Collector:
    def __init__(self) -> None:
        self.events = []

    def __call__(self, event_type: str, **fields) -> None:
        assert event_type in capture.CONTROL_EVENT_TYPES
        message = {'type': event_type, 'monotonic_ns': time.monotonic_ns(),
                   **fields}
        assert not capture._contains_bytes(message)
        assert len(json.dumps(message, sort_keys=True)) < capture.RECORD_BYTES
        self.events.append(message)


def build_records(contract: AbiContract, count: int, *, epoch: int = 77,
                  first_frame: int = 100, first_capture: int = 1) -> list[bytes]:
    records = []
    for index in range(count):
        line = index % contract.lines_per_frame
        frame = (first_frame + index // contract.lines_per_frame) & 0xFFFFFFFF
        metadata = RecordMetadata(
            reset_epoch=epoch,
            source_frame_sequence=frame,
            source_line_sequence=line,
            source_capture_sequence=(first_capture + index) & 0xFFFFFFFF,
            channel_attempt_sequence=index & 0xFFFFFFFF,
            global_stream_sequence=index & 0xFFFFFFFF,
            slot=index % 4,
            slot_generation=(index // 4 + 1) & 0xFFFFFF,
        )
        payload = deterministic_line_payload(contract, frame, line)
        records.append(build_record(contract, metadata, payload))
    return records


def feed_partial(sink: capture.RecordSink, stream: bytes) -> int:
    sizes = (1, 7, 4095, 2, 8191, 31, 65537, 8192, 3, 131071)
    offset = 0
    parts = 0
    while offset < len(stream):
        size = sizes[parts % len(sizes)]
        sink.accept(stream[offset:offset + size])
        offset += size
        parts += 1
    return parts


def write_markdown(path: Path, title: str, rows: list[tuple[str, str]]) -> None:
    lines = [f'# {title}', '', '| Check | Result |', '|---|---|']
    lines.extend(f'| `{name}` | `{value}` |' for name, value in rows)
    lines.append('')
    with path.open('x', encoding='utf-8', newline='\n') as handle:
        handle.write('\n'.join(lines))
        handle.flush()
        os.fsync(handle.fileno())


def run_suite(root: Path, abi_path: Path) -> dict:
    expected_scripts = root / 'scripts'
    if Path(__file__).resolve().parent != expected_scripts.resolve():
        raise RuntimeError('R3R4_SELFTEST_LOCATION_INVALID')
    abi_bytes = abi_path.read_bytes()
    abi_hash = hashlib.sha256(abi_bytes).hexdigest().upper()
    if abi_hash != ABI_SHA256:
        raise RuntimeError('R3R4_FROZEN_ABI_HASH_DRIFT')
    contract = AbiContract.load(abi_path)
    suite_root = root / 'artifacts' / 'offline-selftest'
    suite_root.mkdir(parents=True, exist_ok=False)
    cases = {name: 'FAIL' for name in CASE_NAMES}
    details = {}

    records = build_records(contract, capture.PRIMARY_TARGET + 7)
    complete_stream = b''.join(records)
    collector = Collector()
    success_dir = suite_root / 'successful-capture'
    sink = capture.RecordSink(
        success_dir, contract, 77, collector,
        primary_target=capture.PRIMARY_TARGET,
        drain_limit=capture.DRAIN_LIMIT,
        first_persist_delay=1.0,
    )
    part_count = feed_partial(sink, complete_stream)
    success = sink.finalize(result='PASS', blocker='NONE')
    events = {item['type']: item for item in collector.events}

    first_blob = records[0]
    first_payload = first_blob[contract.payload_first:contract.padding_first]
    assert success['first_record_durable'] and success['first_record_valid']
    assert (success_dir / 'T34-first-record.bin').read_bytes() == first_blob
    assert (success_dir / 'T34-first-payload.bin').read_bytes() == first_payload
    assert success['first_record_sha256'] == hashlib.sha256(first_blob).hexdigest().upper()
    assert success['first_payload_sha256'] == hashlib.sha256(first_payload).hexdigest().upper()
    assert events['PRIMARY_TARGET_REACHED']['monotonic_ns'] < \
        events['FIRST_RECORD_DURABLE']['monotonic_ns']
    cases['FIRST_RECORD_PERSISTENCE_PASS'] = 'PASS'
    details['first_record_async'] = True

    assert part_count > len(records)
    assert success['complete_records'] == len(records)
    assert success['incomplete_trailing_bytes'] == 0
    assert (success_dir / 'T34-incomplete-trailing.bin').stat().st_size == 0
    cases['PARTIAL_READ_ASSEMBLY_PASS'] = 'PASS'
    details['arbitrary_partial_chunks'] = part_count

    primary = success_dir / 'T34-primary-records.bin'
    drain = success_dir / 'T34-drain-records.bin'
    assert success['primary_records'] == 2500
    assert success['primary_bytes'] == 10_240_000
    assert primary.stat().st_size == 10_240_000
    cases['PRIMARY_2500_BOUNDARY_PASS'] = 'PASS'

    assert success['drain_records'] == 7
    assert success['drain_bytes'] == 7 * 4096
    assert drain.read_bytes() == b''.join(records[2500:])
    cases['DRAIN_CAPTURE_PASS'] = 'PASS'

    quiet_since = None
    timeline = [
        (False, False, 0.0),
        (False, True, 0.2),
        (True, False, 1.0),
        (True, True, 1.4),
        (True, False, 2.0),
        (True, False, 2.8),
        (True, False, 3.01),
    ]
    completions = []
    for parent_pass, data, now in timeline:
        quiet_since, done = capture.quiet_window_update(
            parent_pass, data, now, quiet_since, 1.0)
        completions.append(done)
    assert completions == [False, False, False, False, False, False, True]
    cases['PARENT_QUIESCENCE_HANDSHAKE_PASS'] = 'PASS'
    details['timed_no_data_reads_emulated'] = 4
    details['delayed_parent_quiescence_emulated'] = True

    failure_dir = suite_root / 'failure-preservation'
    failure_collector = Collector()
    failure_sink = capture.RecordSink(
        failure_dir, contract, 77, failure_collector,
        primary_target=capture.PRIMARY_TARGET,
    )
    failure_state = None
    try:
        feed_partial(failure_sink, b''.join(records[:7]) + records[7][:333])
        raise ValueError('SELFTEST_EXCEPTION_AFTER_PERSISTED_RECORDS')
    except BaseException as exc:
        failure_state = failure_sink.finalize(
            result='BLOCKED', blocker=str(exc),
            exception_type=type(exc).__name__, exception_repr=repr(exc),
            traceback_text=traceback.format_exc(),
        )
    assert failure_state is not None
    assert (failure_dir / 'T34-primary-records.bin').stat().st_size == 7 * 4096
    assert (failure_dir / 'T34-incomplete-trailing.bin').stat().st_size == 333
    assert failure_state['primary_records'] == 7
    assert failure_state['incomplete_trailing_bytes'] == 333
    cases['FAILURE_PRESERVES_RAW_DATA_PASS'] = 'PASS'

    assert failure_state['exception_type'] == 'ValueError'
    assert failure_state['exception_repr'] == \
        "ValueError('SELFTEST_EXCEPTION_AFTER_PERSISTED_RECORDS')"
    assert 'Traceback (most recent call last)' in failure_state['traceback']
    assert failure_state['last_completed_operation'] == 'ALL_CAPTURE_FILES_DURABLE'
    cases['EXCEPTION_DETAIL_PASS'] = 'PASS'

    frame = reconstruct_first_frame(
        contract, [primary],
        suite_root / 'T34-frame-1920x1080.uyvy',
        suite_root / 'T34-frame-1920x1080.png',
        armed_epoch=77, card_identity='SELFTEST',
    )
    assert frame['result'] == 'PASS'
    assert frame['raw_frame_bytes'] == 4_147_200
    assert frame['width'] == 1920 and frame['height'] == 1080
    assert (suite_root / 'T34-frame-1920x1080.png').read_bytes()[:8] == \
        b'\x89PNG\r\n\x1a\n'
    cases['COMPLETE_FRAME_RECONSTRUCTION_PASS'] = 'PASS'
    details['frame'] = frame

    expected_primary_hash = hashlib.sha256(b''.join(records[:2500])).hexdigest().upper()
    expected_drain_hash = hashlib.sha256(b''.join(records[2500:])).hexdigest().upper()
    assert success['primary_sha256'] == expected_primary_hash
    assert success['drain_sha256'] == expected_drain_hash
    assert hashlib.sha256(primary.read_bytes()).hexdigest().upper() == expected_primary_hash
    assert hashlib.sha256(drain.read_bytes()).hexdigest().upper() == expected_drain_hash
    cases['EXACT_CAPTURE_HASH_PASS'] = 'PASS'

    assert success['blocker'] == 'NONE'
    assert failure_state['blocker'].strip()
    assert all(item.get('blocker', 'NONE').strip()
               for item in (success, failure_state))
    cases['NO_BLANK_BLOCKER_PASS'] = 'PASS'

    all_events = collector.events + failure_collector.events
    assert all(not capture._contains_bytes(item) for item in all_events)
    assert all(item['type'] in capture.CONTROL_EVENT_TYPES for item in all_events)
    assert all(len(json.dumps(item, sort_keys=True)) < capture.RECORD_BYTES
               for item in all_events)
    reader_source = inspect.getsource(capture.reader_worker)
    assert 'MMIO(' not in reader_source
    assert '_user' not in reader_source
    assert 'os.open(c2h_node' in reader_source
    assert "mp.get_context('spawn')" in inspect.getsource(capture.run)
    cases['NO_RAW_RECORD_IPC_PASS'] = 'PASS'
    details['control_event_count'] = len(all_events)

    if tuple(cases) != CASE_NAMES or any(value != 'PASS' for value in cases.values()):
        raise RuntimeError('R3R4_CAPTURE_TOOL_HARD_GATE_FAILED')
    result = {
        'task': capture.TASK,
        'result': 'PASS',
        'hardware_access': False,
        'dut_connections': 0,
        'abi_sha256': abi_hash,
        'passed': len(cases),
        'total': len(CASE_NAMES),
        'cases': cases,
        'details': details,
        'raw_record_control_ipc': False,
        'parent_owned_mmio': True,
        'parent_owned_quiescence': True,
    }
    output = root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_SELFTEST.json'
    with output.open('x', encoding='utf-8', newline='\n') as handle:
        json.dump(result, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    write_markdown(
        root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_SELFTEST.md',
        'G2B-HW0-PRODUCT-R3R4 capture-tool offline self-test',
        [(name, cases[name]) for name in CASE_NAMES] +
        [('Hardware access', 'NO'), ('DUT connections', '0')],
    )
    return result


def architecture_audit(root: Path, result: dict) -> dict:
    capture_path = root / 'scripts' / 'capture_r3r4.py'
    frame_path = root / 'scripts' / 'frame_reconstruct_r3r4.py'
    helper_path = root / 'scripts' / 'Invoke-R3R4DutConnection.ps1'
    source = capture_path.read_text(encoding='utf-8')
    reader_source = inspect.getsource(capture.reader_worker)
    checks = {
        'PARENT_SOLE_MMIO_OWNER': 'MMIO(' not in reader_source,
        'READER_ONLY_EXPLICIT_DEVICE_OPEN_IS_C2H':
            'os.open(c2h_node' in reader_source and '_user' not in reader_source,
        'SPAWN_PREVENTS_MMIO_FD_INHERITANCE': "mp.get_context('spawn')" in source,
        'ZERO_RAW_RECORD_CONTROL_IPC': result['raw_record_control_ipc'] is False,
        'ASYNC_FIRST_RECORD_PERSISTER':
            'r3r4-first-record-persister' in source and 'threading.Thread' in source,
        'PRIMARY_TARGET_2500': capture.PRIMARY_TARGET == 2500,
        'PRIMARY_BYTES_10240000': capture.PRIMARY_BYTES == 10_240_000,
        'DRAIN_LIMIT_512': capture.DRAIN_LIMIT == 512,
        'PARENT_QUIESCENCE_TIMEOUT_10S': capture.QUIESCENCE_TIMEOUT_SECONDS == 10.0,
        'QUIET_WINDOW_1S': capture.QUIET_WINDOW_SECONDS == 1.0,
        'NO_BLANK_BLOCKER': result['cases']['NO_BLANK_BLOCKER_PASS'] == 'PASS',
        'FROZEN_ABI_HASH': result['abi_sha256'] == ABI_SHA256,
    }
    if not all(checks.values()):
        raise RuntimeError('R3R4_CAPTURE_TOOL_HARD_GATE_FAILED:' +
                           json.dumps(checks, sort_keys=True))
    hashes = {}
    for path in (capture_path, frame_path, helper_path,
                 root / 'scripts' / 'capture_r3r4_selftest.py',
                 root / 'scripts' / 'abi_v1.py',
                 root / 'scripts' / 'V41_C2H_TRANSPORT_ABI_V1.json'):
        hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest().upper()
    audit = {
        'task': capture.TASK,
        'result': 'PASS',
        'hardware_access': False,
        'checks': checks,
        'tool_sha256': hashes,
        'selftests_passed': result['passed'],
        'selftests_total': result['total'],
    }
    with (root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_AUDIT.json').open(
            'x', encoding='utf-8', newline='\n') as handle:
        json.dump(audit, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    write_markdown(
        root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_AUDIT.md',
        'G2B-HW0-PRODUCT-R3R4 capture-tool architecture audit',
        [(name, 'PASS' if value else 'FAIL') for name, value in checks.items()] +
        [('Offline self-tests', f"{result['passed']}/{result['total']}")],
    )
    return audit


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        result = run_suite(root, root / 'scripts' / 'V41_C2H_TRANSPORT_ABI_V1.json')
        audit = architecture_audit(root, result)
        print(json.dumps({'selftest': result, 'audit': audit}, indent=2))
        return 0
    except BaseException as exc:
        failure = {
            'task': capture.TASK, 'result': 'BLOCKED',
            'blocker': 'R3R4_CAPTURE_TOOL_HARD_GATE_FAILED',
            'exception_type': type(exc).__name__,
            'exception_repr': repr(exc),
            'traceback': traceback.format_exc(),
            'hardware_access': False, 'dut_connections': 0,
        }
        path = root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_FAILURE.json'
        path.write_text(json.dumps(failure, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(failure, indent=2))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
