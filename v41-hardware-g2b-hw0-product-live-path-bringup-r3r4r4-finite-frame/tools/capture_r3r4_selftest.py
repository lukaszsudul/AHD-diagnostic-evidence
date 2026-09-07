#!/usr/bin/env python3
"""Offline hard-gate suite for the R3R4R4 capture architecture."""
from __future__ import annotations

import argparse
import hashlib
import inspect
import json
import os
from pathlib import Path
import shutil
import sys
import threading
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
    'PERSISTED_FIRST_RECORD_REREAD_PROOF_PASS',
    'PRIMARY_PERIODIC_FSYNC_PASS',
    'FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET_PASS',
    'PARENT_MULTI_SAMPLE_QUIESCENCE_PASS',
    'SINGLE_COMBINED_SESSION_NORMALIZATION_W1C_PASS',
)
CURRENT_CASE = 'SUITE_SETUP'


class DependencyRejected(RuntimeError):
    pass


class Collector:
    def __init__(self, *, ordering_timestamp_ns: int | None = None) -> None:
        self.events = []
        self.rejections = []
        self.ordering_timestamp_ns = ordering_timestamp_ns
        self.first_record_durable_success = False
        self._callback_sequence = 0
        self._event_sequence = 0
        self._lock = threading.Lock()

    def __call__(self, event_type: str, **fields) -> None:
        assert event_type in capture.CONTROL_EVENT_TYPES
        with self._lock:
            self._callback_sequence += 1
            timestamp_ns = (
                self.ordering_timestamp_ns
                if (self.ordering_timestamp_ns is not None and event_type in {
                    'FIRST_RECORD_DURABLE', 'PRIMARY_TARGET_REACHED'})
                else time.monotonic_ns()
            )
            if (event_type == 'PRIMARY_TARGET_REACHED' and
                    not self.first_record_durable_success):
                blocker = (
                    'PRIMARY_TARGET_REACHED_REJECTED:'
                    'FIRST_RECORD_DURABLE_SUCCESS_FALSE')
                rejection = {
                    'type': event_type,
                    'callback_sequence': self._callback_sequence,
                    'monotonic_ns': timestamp_ns,
                    'accepted': False,
                    'dependency_state': 'FIRST_RECORD_DURABLE_SUCCESS_FALSE',
                    'first_record_durable_success': False,
                    'blocker': blocker,
                }
                assert not capture._contains_bytes(rejection)
                self.rejections.append(rejection)
                raise DependencyRejected(blocker)
            if event_type == 'FIRST_RECORD_DURABLE':
                self.first_record_durable_success = True
            self._event_sequence += 1
            dependency_state = (
                'FIRST_RECORD_DURABLE_SUCCESS'
                if self.first_record_durable_success
                else 'FIRST_RECORD_DURABLE_NOT_YET_SUCCESSFUL')
            message = {
                'type': event_type,
                'callback_sequence': self._callback_sequence,
                'event_sequence': self._event_sequence,
                'monotonic_ns': timestamp_ns,
                'dependency_state': dependency_state,
                'first_record_durable_success': (
                    self.first_record_durable_success),
                **fields,
            }
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


def feed_partial(sink: capture.RecordSink, stream: bytes) -> dict:
    sizes = (1, 7, 4095, 2, 8191, 31, 65537, 8192, 3, 131071)
    offset = 0
    chunk_sizes = []
    cumulative_boundaries = []
    multi_record_spans = []
    while offset < len(stream):
        requested = sizes[len(chunk_sizes) % len(sizes)]
        end = min(offset + requested, len(stream))
        actual = end - offset
        sink.accept(stream[offset:end])
        chunk_sizes.append(actual)
        cumulative_boundaries.append(end)
        multi_record_spans.append(
            actual > 0 and
            offset // capture.RECORD_BYTES !=
            (end - 1) // capture.RECORD_BYTES)
        offset = end
    return {
        'chunk_count': len(chunk_sizes),
        'chunk_sizes': chunk_sizes,
        'cumulative_boundaries': cumulative_boundaries,
        'multi_record_spans': multi_record_spans,
    }


def write_markdown(path: Path, title: str, rows: list[tuple[str, str]]) -> None:
    lines = [f'# {title}', '', '| Check | Result |', '|---|---|']
    lines.extend(f'| `{name}` | `{value}` |' for name, value in rows)
    lines.append('')
    with path.open('x', encoding='utf-8', newline='\n') as handle:
        handle.write('\n'.join(lines))
        handle.flush()
        os.fsync(handle.fileno())


def write_json_exclusive(path: Path, value: dict) -> None:
    assert not capture._contains_bytes(value)
    with path.open('x', encoding='utf-8', newline='\n') as handle:
        json.dump(value, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())


def run_suite(root: Path, abi_path: Path) -> dict:
    global CURRENT_CASE
    expected_scripts = root / 'scripts'
    if Path(__file__).resolve().parent != expected_scripts.resolve():
        raise RuntimeError('R3R4R4_SELFTEST_LOCATION_INVALID')
    abi_bytes = abi_path.read_bytes()
    abi_hash = hashlib.sha256(abi_bytes).hexdigest().upper()
    if abi_hash != ABI_SHA256:
        raise RuntimeError('R3R4R4_FROZEN_ABI_HASH_DRIFT')
    contract = AbiContract.load(abi_path)
    suite_root = root / 'artifacts' / 'offline-selftest'
    suite_root.mkdir(parents=True, exist_ok=False)
    cases = {name: 'FAIL' for name in CASE_NAMES}
    details = {}

    records = build_records(contract, capture.PRIMARY_TARGET + 7)
    complete_stream = b''.join(records)
    equal_ordering_timestamp_ns = 1_234_567_890_000_000
    collector = Collector(ordering_timestamp_ns=equal_ordering_timestamp_ns)
    success_dir = suite_root / 'successful-capture'
    sink = capture.RecordSink(
        success_dir, contract, 77, collector,
        primary_target=capture.PRIMARY_TARGET,
        drain_limit=capture.DRAIN_LIMIT,
        first_persist_delay=1.0,
    )
    part_metrics = feed_partial(sink, complete_stream)
    success = sink.finalize(result='PASS', blocker='NONE')
    events = {item['type']: item for item in collector.events}

    CURRENT_CASE = 'FIRST_RECORD_PERSISTENCE_PASS'
    first_blob = records[0]
    first_payload = first_blob[contract.payload_first:contract.padding_first]
    assert success['first_record_durable'] and success['first_record_valid']
    assert (success_dir / 'T3T4-first-record.bin').read_bytes() == first_blob
    assert (success_dir / 'T3T4-first-payload.bin').read_bytes() == first_payload
    assert success['first_record_sha256'] == hashlib.sha256(first_blob).hexdigest().upper()
    assert success['first_payload_sha256'] == hashlib.sha256(first_payload).hexdigest().upper()
    durable_event = events['FIRST_RECORD_DURABLE']
    target_event = events['PRIMARY_TARGET_REACHED']
    assert durable_event['event_sequence'] < target_event['event_sequence']
    assert target_event['dependency_state'] == 'FIRST_RECORD_DURABLE_SUCCESS'
    assert target_event['first_record_durable_success'] is True
    assert collector.first_record_durable_success is True
    assert durable_event['monotonic_ns'] == target_event['monotonic_ns']
    cases['FIRST_RECORD_PERSISTENCE_PASS'] = 'PASS'
    details['first_record_async'] = True
    details['first_record_durable_before_primary_target'] = True
    details['equal_timestamp_event_sequence_proof'] = {
        'first_record_durable_event_sequence': durable_event['event_sequence'],
        'primary_target_reached_event_sequence': target_event['event_sequence'],
        'timestamp_relation': 'EQUAL',
        'dependency_state_at_target': target_event['dependency_state'],
        'timestamp_used_as_causal_proof': False,
    }

    primary = success_dir / 'T3T4-primary-records.bin'
    drain = success_dir / 'T3T4-drain-records.bin'
    primary_bytes = primary.read_bytes()
    drain_bytes = drain.read_bytes()
    expected_primary_hash = hashlib.sha256(
        complete_stream[:capture.PRIMARY_BYTES]).hexdigest().upper()
    expected_drain_hash = hashlib.sha256(
        complete_stream[capture.PRIMARY_BYTES:]).hexdigest().upper()

    CURRENT_CASE = 'PARTIAL_READ_ASSEMBLY_PASS'
    assert any(size < capture.RECORD_BYTES
               for size in part_metrics['chunk_sizes'])
    assert any(size > capture.RECORD_BYTES
               for size in part_metrics['chunk_sizes'])
    assert any(boundary % capture.RECORD_BYTES != 0
               for boundary in part_metrics['cumulative_boundaries'][:-1])
    assert any(part_metrics['multi_record_spans'])
    assert part_metrics['chunk_count'] > 1
    assert success['complete_records'] == len(records)
    assert primary_bytes + drain_bytes == complete_stream
    assert success['primary_records'] == 2500
    assert success['primary_bytes'] == 10_240_000
    assert success['drain_records'] == 7
    assert success['drain_bytes'] == 28_672
    assert success['incomplete_trailing_bytes'] == 0
    assert (success_dir / 'T3T4-incomplete-trailing.bin').stat().st_size == 0
    assert success['primary_sha256'] == expected_primary_hash
    assert success['drain_sha256'] == expected_drain_hash
    assert hashlib.sha256(primary_bytes).hexdigest().upper() == \
        expected_primary_hash
    assert hashlib.sha256(drain_bytes).hexdigest().upper() == \
        expected_drain_hash
    cases['PARTIAL_READ_ASSEMBLY_PASS'] = 'PASS'
    details['arbitrary_partial_chunks'] = part_metrics['chunk_count']
    details['partial_read_semantics'] = {
        'chunk_sizes': part_metrics['chunk_sizes'],
        'cumulative_boundaries': part_metrics['cumulative_boundaries'],
        'has_chunk_smaller_than_record': True,
        'has_chunk_larger_than_record': True,
        'has_unaligned_cumulative_boundary': True,
        'has_chunk_spanning_multiple_records': True,
        'uses_more_than_one_chunk': True,
        'reconstructed_stream_byte_identical': True,
        'supplied_records': len(records),
        'primary_records': success['primary_records'],
        'primary_bytes': success['primary_bytes'],
        'drain_records': success['drain_records'],
        'drain_bytes': success['drain_bytes'],
        'incomplete_trailing_bytes': success['incomplete_trailing_bytes'],
        'primary_expected_sha256': expected_primary_hash,
        'drain_expected_sha256': expected_drain_hash,
    }

    CURRENT_CASE = 'PRIMARY_2500_BOUNDARY_PASS'
    assert success['primary_records'] == 2500
    assert success['primary_bytes'] == 10_240_000
    assert primary.stat().st_size == 10_240_000
    cases['PRIMARY_2500_BOUNDARY_PASS'] = 'PASS'

    CURRENT_CASE = 'DRAIN_CAPTURE_PASS'
    assert success['drain_records'] == 7
    assert success['drain_bytes'] == 7 * 4096
    assert drain.read_bytes() == b''.join(records[2500:])
    cases['DRAIN_CAPTURE_PASS'] = 'PASS'

    CURRENT_CASE = 'PARENT_QUIESCENCE_HANDSHAKE_PASS'
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
    assert completions == [False, False, False, False, False, True, True]
    cases['PARENT_QUIESCENCE_HANDSHAKE_PASS'] = 'PASS'
    details['timed_no_data_reads_emulated'] = 4
    details['delayed_parent_quiescence_emulated'] = True

    CURRENT_CASE = 'FAILURE_PRESERVES_RAW_DATA_PASS'
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
    assert (failure_dir / 'T3T4-primary-records.bin').stat().st_size == 7 * 4096
    assert (failure_dir / 'T3T4-incomplete-trailing.bin').stat().st_size == 333
    assert failure_state['primary_records'] == 7
    assert failure_state['incomplete_trailing_bytes'] == 333
    cases['FAILURE_PRESERVES_RAW_DATA_PASS'] = 'PASS'

    CURRENT_CASE = 'EXCEPTION_DETAIL_PASS'
    assert failure_state['exception_type'] == 'ValueError'
    assert failure_state['exception_repr'] == \
        "ValueError('SELFTEST_EXCEPTION_AFTER_PERSISTED_RECORDS')"
    assert 'Traceback (most recent call last)' in failure_state['traceback']
    assert failure_state['last_completed_operation'] == 'ALL_CAPTURE_FILES_DURABLE'
    cases['EXCEPTION_DETAIL_PASS'] = 'PASS'

    CURRENT_CASE = 'COMPLETE_FRAME_RECONSTRUCTION_PASS'
    frame = reconstruct_first_frame(
        contract, [primary],
        suite_root / 'T3T4-frame-1920x1080.uyvy',
        suite_root / 'T3T4-frame-1920x1080.png',
        armed_epoch=77, card_identity='SELFTEST',
    )
    assert frame['result'] == 'PASS'
    assert frame['raw_frame_bytes'] == 4_147_200
    assert frame['width'] == 1920 and frame['height'] == 1080
    assert (suite_root / 'T3T4-frame-1920x1080.png').read_bytes()[:8] == \
        b'\x89PNG\r\n\x1a\n'
    cases['COMPLETE_FRAME_RECONSTRUCTION_PASS'] = 'PASS'
    details['frame'] = frame

    CURRENT_CASE = 'EXACT_CAPTURE_HASH_PASS'
    assert success['primary_sha256'] == expected_primary_hash
    assert success['drain_sha256'] == expected_drain_hash
    assert hashlib.sha256(primary.read_bytes()).hexdigest().upper() == expected_primary_hash
    assert hashlib.sha256(drain.read_bytes()).hexdigest().upper() == expected_drain_hash
    cases['EXACT_CAPTURE_HASH_PASS'] = 'PASS'

    CURRENT_CASE = 'NO_BLANK_BLOCKER_PASS'
    assert success['blocker'] == 'NONE'
    assert failure_state['blocker'].strip()
    assert all(item.get('blocker', 'NONE').strip()
               for item in (success, failure_state))
    cases['NO_BLANK_BLOCKER_PASS'] = 'PASS'

    CURRENT_CASE = 'NO_RAW_RECORD_IPC_PASS'
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

    # Contract test 12: authoritative first-record results survive invalidation
    # of the caller's original mutable buffer because all results come from disk.
    CURRENT_CASE = 'PERSISTED_FIRST_RECORD_REREAD_PROOF_PASS'
    reread_dir = suite_root / 'persisted-reread-proof'
    reread_collector = Collector()
    original_buffer = bytearray(first_blob)
    original_hash = hashlib.sha256(original_buffer).hexdigest().upper()
    reread_sink = capture.RecordSink(
        reread_dir, contract, 77, reread_collector,
        primary_target=capture.PRIMARY_TARGET,
    )
    reread_sink.accept(bytes(original_buffer))
    reread_sink.first_thread.join(timeout=5.0)
    assert not reread_sink.first_thread.is_alive()
    original_buffer[:] = b'\xA5' * len(original_buffer)
    assert hashlib.sha256(original_buffer).hexdigest().upper() != original_hash
    reread_state = reread_sink.finalize(
        result='BLOCKED', blocker='SELFTEST_SINGLE_RECORD_COMPLETE')
    persisted_receipt = json.loads((
        reread_dir /
        'G2B_HW0_PRODUCT_R3R4R4_PERSISTED_FIRST_RECORD_RECEIPT.json'
    ).read_text(encoding='utf-8'))
    reread_record = (reread_dir / 'T3T4-first-record.bin').read_bytes()
    reread_payload = (reread_dir / 'T3T4-first-payload.bin').read_bytes()
    persist_source = inspect.getsource(capture.RecordSink._persist_first)
    assert persist_source.index('del blob') < \
        persist_source.index('hashlib.sha256(\n                persisted_record)')
    assert persisted_receipt['first_record_reread_bytes'] == 4096
    assert persisted_receipt['first_payload_reread_bytes'] == 3840
    assert persisted_receipt['record_hash_source'] == 'REREAD_PERSISTED_FILE'
    assert persisted_receipt['payload_hash_source'] == 'REREAD_PERSISTED_FILE'
    assert persisted_receipt['abi_parse_source'] == \
        'REREAD_PERSISTED_FIRST_RECORD'
    assert persisted_receipt['payload_equals_record_slice'] is True
    assert persisted_receipt['abi_result'] == 'PASS'
    assert reread_payload == reread_record[
        contract.payload_first:contract.padding_first]
    assert reread_state['first_record_sha256'] == \
        hashlib.sha256(reread_record).hexdigest().upper() == original_hash
    assert reread_state['first_payload_sha256'] == \
        hashlib.sha256(reread_payload).hexdigest().upper()
    cases['PERSISTED_FIRST_RECORD_REREAD_PROOF_PASS'] = 'PASS'
    details['persisted_first_record_reread_proof'] = {
        'original_mutable_buffer_invalidated': True,
        'record_hash_source': persisted_receipt['record_hash_source'],
        'payload_hash_source': persisted_receipt['payload_hash_source'],
        'abi_parse_source': persisted_receipt['abi_parse_source'],
        'payload_equals_record_slice': True,
    }

    # Contract test 13: the dedicated worker receives record counts only and
    # completes all required persisted-size/fsync checkpoints.
    CURRENT_CASE = 'PRIMARY_PERIODIC_FSYNC_PASS'
    checkpoint_rows = [json.loads(line) for line in (
        success_dir /
        'G2B_HW0_PRODUCT_R3R4R4_PRIMARY_DURABILITY_CHECKPOINTS.jsonl'
    ).read_text(encoding='utf-8').splitlines() if line.strip()]
    assert [row['record_count'] for row in checkpoint_rows] == [1024, 2048, 2500]
    assert all(row['result'] == 'PASS' and row['fsync_complete']
               for row in checkpoint_rows)
    assert all(row['persisted_size'] >= row['record_count'] * 4096
               for row in checkpoint_rows)
    assert all(row['communication'] == 'METADATA_ONLY_RECORD_COUNT' and
               row['raw_payload_in_communication'] is False
               for row in checkpoint_rows)
    checkpoint_events = [item for item in collector.events
                         if item['type'] == 'PRIMARY_CHECKPOINT_DURABLE']
    assert len(checkpoint_events) == 3
    assert all(not capture._contains_bytes(item) for item in checkpoint_events)
    assert success['checkpoint_passed'] == [1024, 2048, 2500]
    checkpoint_source = inspect.getsource(capture.RecordSink._checkpoint_worker)
    request_source = inspect.getsource(capture.RecordSink._request_checkpoint)
    assert 'self.checkpoint_queue.put(record_count' in request_source
    assert 'os.fsync(fd)' in checkpoint_source
    assert 'self.primary_file.write' not in checkpoint_source
    cases['PRIMARY_PERIODIC_FSYNC_PASS'] = 'PASS'
    details['primary_durability_checkpoints'] = checkpoint_rows

    # Contract test 14: reaching count 2500 while persistence is deliberately
    # delayed does not permit the target event until durability is complete.
    CURRENT_CASE = 'FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET_PASS'
    ordering_dir = suite_root / 'ordering-proof'
    ordering_collector = Collector(
        ordering_timestamp_ns=equal_ordering_timestamp_ns)
    ordering_sink = capture.RecordSink(
        ordering_dir, contract, 77, ordering_collector,
        primary_target=capture.PRIMARY_TARGET,
        first_persist_delay=5.0,
    )
    feeder_error = []

    def feed_ordering_capture() -> None:
        try:
            ordering_sink.accept(complete_stream[:capture.PRIMARY_BYTES])
        except BaseException as exc:
            feeder_error.append(exc)

    feeder = threading.Thread(target=feed_ordering_capture,
                              name='r3r4r4-selftest-ordering-feeder')
    feeder.start()
    count_deadline = time.monotonic() + 4.0
    while ordering_sink.primary_count < capture.PRIMARY_TARGET:
        assert time.monotonic() < count_deadline
        time.sleep(0.005)
    assert feeder.is_alive()
    assert not any(item['type'] == 'PRIMARY_TARGET_REACHED'
                   for item in ordering_collector.events)
    assert not ordering_sink.first_durable
    dependency_blocker = None
    try:
        ordering_collector(
            'PRIMARY_TARGET_REACHED', dependency_probe=True,
            first_record_durable=False, checkpoint_1024=True,
            checkpoint_2048=True)
    except DependencyRejected as exc:
        dependency_blocker = str(exc)
    assert dependency_blocker == (
        'PRIMARY_TARGET_REACHED_REJECTED:'
        'FIRST_RECORD_DURABLE_SUCCESS_FALSE')
    assert not any(item['type'] == 'PRIMARY_TARGET_REACHED'
                   for item in ordering_collector.events)
    assert len(ordering_collector.rejections) == 1
    assert ordering_collector.rejections[0]['accepted'] is False
    assert ordering_collector.rejections[0]['dependency_state'] == \
        'FIRST_RECORD_DURABLE_SUCCESS_FALSE'
    assert ordering_collector.rejections[0]['blocker'].strip()
    feeder.join(timeout=8.0)
    assert not feeder.is_alive() and not feeder_error
    ordering_events = {item['type']: item for item in ordering_collector.events}
    ordering_durable = ordering_events['FIRST_RECORD_DURABLE']
    ordering_target = ordering_events['PRIMARY_TARGET_REACHED']
    assert ordering_durable['event_sequence'] < \
        ordering_target['event_sequence']
    assert ordering_durable['monotonic_ns'] == \
        ordering_target['monotonic_ns']
    assert ordering_target['dependency_state'] == \
        'FIRST_RECORD_DURABLE_SUCCESS'
    assert ordering_target['first_record_durable_success'] is True
    assert ordering_target['checkpoint_1024']
    assert ordering_target['checkpoint_2048']
    ordering_state = ordering_sink.finalize(result='PASS', blocker='NONE')
    assert ordering_state['result'] == 'PASS'
    cases['FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET_PASS'] = 'PASS'
    details['ordering_proof'] = {
        'count_2500_observed_while_target_withheld': True,
        'first_record_durable_precedes_primary_target': True,
        'checkpoint_1024_precedes_target': True,
        'checkpoint_2048_precedes_target': True,
        'target_before_durable_rejected': True,
        'dependency_rejection_blocker': dependency_blocker,
        'equal_timestamp_accepted': True,
        'first_record_durable_event_sequence': (
            ordering_durable['event_sequence']),
        'primary_target_reached_event_sequence': (
            ordering_target['event_sequence']),
        'dependency_state_at_target': ordering_target['dependency_state'],
    }
    ordering_proof = {
        'schema': 'R3R4R4_EVENT_ORDERING_PROOF_V1',
        'task': capture.TASK,
        'result': 'PASS',
        'ORDERING_PROOF_BASIS': 'EVENT_SEQUENCE_PLUS_EXPLICIT_DEPENDENCY',
        'MONOTONIC_TIMESTAMP_USED_AS_CAUSAL_PROOF': 'NO',
        'EQUAL_TIMESTAMP_CASE': 'PASS',
        'RUNTIME_CAPTURE_SEMANTICS_CHANGED': 'NO',
        'events': [
            {
                'name': durable_event['type'],
                'event_sequence': durable_event['event_sequence'],
                'monotonic_ns': durable_event['monotonic_ns'],
                'dependency_state': durable_event['dependency_state'],
                'first_record_durable_success': (
                    durable_event['first_record_durable_success']),
            },
            {
                'name': target_event['type'],
                'event_sequence': target_event['event_sequence'],
                'monotonic_ns': target_event['monotonic_ns'],
                'dependency_state': target_event['dependency_state'],
                'first_record_durable_success': (
                    target_event['first_record_durable_success']),
            },
        ],
        'timestamp_relation': 'EQUAL',
        'equal_timestamps_used': True,
        'target_before_durable_rejected': True,
        'target_before_durable_rejection': (
            ordering_collector.rejections[0]),
        'delayed_durability_proof': {
            'primary_count_reached': capture.PRIMARY_TARGET,
            'target_withheld_before_durable': True,
            'first_record_durable_event_sequence': (
                ordering_durable['event_sequence']),
            'primary_target_reached_event_sequence': (
                ordering_target['event_sequence']),
            'timestamps_equal': (
                ordering_durable['monotonic_ns'] ==
                ordering_target['monotonic_ns']),
            'dependency_state_at_target': ordering_target['dependency_state'],
            'first_record_durable_success_at_target': (
                ordering_target['first_record_durable_success']),
        },
        'runtime_capture_code_changed': False,
        'raw_payload_in_receipt': False,
    }
    write_json_exclusive(
        root / 'artifacts' /
        'G2B_HW0_PRODUCT_R3R4R4_EVENT_ORDERING_PROOF.json',
        ordering_proof)
    details['event_ordering_proof'] = ordering_proof

    # Contract test 15: an isolated sample cannot pass and any failed sample
    # resets the streak. Completion requires five consecutive samples and 0.4s.
    CURRENT_CASE = 'PARENT_MULTI_SAMPLE_QUIESCENCE_PASS'
    streak = 0
    first_time = None
    q_results = []
    q_timeline = [
        (True, 0.0), (False, 0.1),
        (True, 0.2), (True, 0.3), (False, 0.4),
        (True, 1.0), (True, 1.1), (True, 1.2), (True, 1.3), (True, 1.4),
    ]
    for sample_pass, now in q_timeline:
        streak, first_time, span, complete = capture.quiescence_streak_update(
            sample_pass, now, streak, first_time)
        q_results.append({
            'sample_pass': sample_pass, 'now': now, 'streak': streak,
            'span': span, 'complete': complete,
        })
    assert q_results[0]['complete'] is False
    assert q_results[1]['streak'] == 0
    assert q_results[4]['streak'] == 0
    assert all(not row['complete'] for row in q_results[:-1])
    assert q_results[-1]['complete'] is True
    assert q_results[-1]['streak'] == 5
    assert q_results[-1]['span'] >= 0.4
    cases['PARENT_MULTI_SAMPLE_QUIESCENCE_PASS'] = 'PASS'
    details['parent_multi_sample_quiescence'] = q_results

    # Contract test 16: one observed mask produces zero or one exact combined
    # W1C. A residual active bit blocks and can never trigger a second write.
    CURRENT_CASE = 'SINGLE_COMBINED_SESSION_NORMALIZATION_W1C_PASS'
    normalization_results = {}
    for initial in (0x00, 0x07, 0x38, 0x3F):
        writes = []

        def read_status(initial=initial, writes=writes) -> int:
            return initial if not writes else 0

        normalized = capture.combined_session_normalization(
            read_status, lambda mask, writes=writes: writes.append(mask))
        expected_writes = [] if initial == 0 else [initial]
        assert writes == expected_writes
        assert normalized['w1c_writes'] == len(expected_writes)
        assert normalized['session_normalization_mask'] == initial
        normalization_results[f'0x{initial:02X}'] = {
            'writes': writes, 'result': 'PASS',
        }
    residual_writes = []

    def residual_read() -> int:
        return 0x07 if not residual_writes else 0x01

    residual_blocker = None
    try:
        capture.combined_session_normalization(
            residual_read, lambda mask: residual_writes.append(mask))
    except capture.GateError as exc:
        residual_blocker = str(exc)
    assert residual_writes == [0x07]
    assert residual_blocker == 'R3R4R4_SESSION_NORMALIZATION_DID_NOT_CLEAR'
    normalization_source = inspect.getsource(
        capture.combined_session_normalization)
    mmio_write_source = inspect.getsource(capture.MMIO.write)
    capture_path_source = Path(capture.__file__).read_text(encoding='utf-8')
    assert 'POST_RESET_NONFATAL_W1C' not in capture_path_source
    assert 'POST_RESET_FATAL_W1C' not in capture_path_source
    assert "purpose == 'SESSION_NORMALIZATION_W1C'" in mmio_write_source
    assert 'write_w1c(mask)' in normalization_source
    assert normalization_source.count('write_w1c(') == 1
    cases['SINGLE_COMBINED_SESSION_NORMALIZATION_W1C_PASS'] = 'PASS'
    details['single_combined_session_normalization'] = {
        'cases': normalization_results,
        'residual_writes': residual_writes,
        'residual_blocker': residual_blocker,
        'maximum_writes': 1,
    }

    if tuple(cases) != CASE_NAMES or any(value != 'PASS' for value in cases.values()):
        raise RuntimeError('R3R4R4_CAPTURE_TOOL_HARD_GATE_FAILED')
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
        'capture_tool_sha256': hashlib.sha256(
            (root / 'scripts' / 'capture_r3r4.py').read_bytes()).hexdigest().upper(),
        'selftest_tool_sha256': hashlib.sha256(
            Path(__file__).read_bytes()).hexdigest().upper(),
    }
    output = root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_SELFTEST.json'
    with output.open('x', encoding='utf-8', newline='\n') as handle:
        json.dump(result, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    write_markdown(
        root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_SELFTEST.md',
        'G2B-HW0-PRODUCT-R3R4R4 capture-tool offline self-test',
        [(name, cases[name]) for name in CASE_NAMES] +
        [('Hardware access', 'NO'), ('DUT connections', '0')],
    )
    return result


def architecture_audit(root: Path, result: dict) -> dict:
    capture_path = root / 'scripts' / 'capture_r3r4.py'
    frame_path = root / 'scripts' / 'frame_reconstruct_r3r4.py'
    helper_path = root / 'scripts' / 'Invoke-R3R4R4DutConnection.ps1'
    source = capture_path.read_text(encoding='utf-8')
    reader_source = inspect.getsource(capture.reader_worker)
    sink_source = inspect.getsource(capture.RecordSink)
    persist_source = inspect.getsource(capture.RecordSink._persist_first)
    target_source = inspect.getsource(
        capture.RecordSink._await_primary_target_prerequisites)
    quiescence_source = inspect.getsource(capture._parent_quiescence)
    normalization_source = inspect.getsource(
        capture.combined_session_normalization)
    checks = {
        'OFFLINE_SELFTESTS_16_OF_16': result['passed'] == 16,
        'PARENT_SOLE_MMIO_OWNER': 'MMIO(' not in reader_source,
        'READER_ONLY_EXPLICIT_DEVICE_OPEN_IS_C2H':
            'os.open(c2h_node' in reader_source and '_user' not in reader_source,
        'SPAWN_PREVENTS_MMIO_FD_INHERITANCE': "mp.get_context('spawn')" in source,
        'ZERO_RAW_RECORD_CONTROL_IPC': result['raw_record_control_ipc'] is False,
        'ASYNC_FIRST_RECORD_PERSISTER':
            'r3r4r4-first-record-persister' in source and 'threading.Thread' in source,
        'FIRST_RECORD_RESULTS_FROM_REREAD_FILES':
            'persisted_record = _read_exact_nofollow' in persist_source and
            'persisted_payload = _read_exact_nofollow' in persist_source and
            'del blob' in persist_source,
        'PRIMARY_CHECKPOINT_WORKER_ASYNCHRONOUS':
            'r3r4r4-primary-durability-worker' in sink_source and
            'self.checkpoint_queue' in sink_source,
        'PRIMARY_CHECKPOINTS_EXACT':
            capture.PRIMARY_CHECKPOINT_COUNTS == (1024, 2048, 2500),
        'PRIMARY_TARGET_ORDERING_DEPENDENCIES':
            'self.first_durable and self.first_valid' in target_source and
            'self._wait_checkpoint(1024)' in target_source and
            'self._wait_checkpoint(2048)' in target_source,
        'PRIMARY_TARGET_2500': capture.PRIMARY_TARGET == 2500,
        'PRIMARY_BYTES_10240000': capture.PRIMARY_BYTES == 10_240_000,
        'DRAIN_LIMIT_512': capture.DRAIN_LIMIT == 512,
        'PARENT_QUIESCENCE_TIMEOUT_10S': capture.QUIESCENCE_TIMEOUT_SECONDS == 10.0,
        'PARENT_QUIESCENCE_FIVE_SAMPLES':
            capture.QUIESCENCE_REQUIRED_SAMPLES == 5 and
            'consecutive_quiescent' in quiescence_source,
        'PARENT_QUIESCENCE_MINIMUM_400MS':
            capture.QUIESCENCE_MINIMUM_SPAN_SECONDS == 0.4,
        'QUIET_WINDOW_1S': capture.QUIET_WINDOW_SECONDS == 1.0,
        'SINGLE_COMBINED_NORMALIZATION_W1C':
            normalization_source.count('write_w1c(') == 1 and
            'POST_RESET_NONFATAL_W1C' not in source and
            'POST_RESET_FATAL_W1C' not in source,
        'NO_BLANK_BLOCKER': result['cases']['NO_BLANK_BLOCKER_PASS'] == 'PASS',
        'FROZEN_ABI_HASH': result['abi_sha256'] == ABI_SHA256,
    }
    if not all(checks.values()):
        raise RuntimeError('R3R4R4_CAPTURE_TOOL_HARD_GATE_FAILED:' +
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
    with (root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_AUDIT.json').open(
            'x', encoding='utf-8', newline='\n') as handle:
        json.dump(audit, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    write_markdown(
        root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_AUDIT.md',
        'G2B-HW0-PRODUCT-R3R4R4 capture-tool architecture audit',
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
        print(json.dumps({'selftest': result}, indent=2))
        return 0
    except BaseException as exc:
        failure = {
            'task': capture.TASK, 'result': 'BLOCKED',
            'blocker': 'R3R4R4_CAPTURE_TOOL_SELFTEST_FAILED:' + CURRENT_CASE,
            'exception_type': type(exc).__name__,
            'exception_repr': repr(exc),
            'traceback': traceback.format_exc(),
            'hardware_access': False, 'dut_connections': 0,
        }
        path = root / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4R4_CAPTURE_TOOL_FAILURE.json'
        path.write_text(json.dumps(failure, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(failure, indent=2))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
