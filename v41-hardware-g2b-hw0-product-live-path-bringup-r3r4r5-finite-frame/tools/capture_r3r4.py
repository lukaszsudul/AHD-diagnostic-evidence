#!/usr/bin/env python3
"""R3R4R5 persistent 2500-record capture with parent-only MMIO authority."""
from __future__ import annotations

import csv
import hashlib
import json
import multiprocessing as mp
import os
from pathlib import Path
import queue
import signal
import stat
import struct
import sys
import threading
import time
import traceback as traceback_module
from typing import Callable, Iterable, Iterator, Mapping

from abi_v1 import AbiContract, StreamValidator
from frame_reconstruct_r3r4 import reconstruct_first_frame


P = Path
ROOT = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r5/20260907T151342Z')
LOCK = P('/tmp/ahd-g2b-hw0-product-r3r4r5-20260907T151342Z.lock/receipt.json')
TASK = 'G2B-HW0-PRODUCT-R3R4R5'
EXPECTED_BOOT = '614295f4-c62b-4430-ae67-06013bea7084'
ABI_SHA256 = 'AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6'
RECORD_BYTES = 4096
PRIMARY_TARGET = 2500
PRIMARY_BYTES = PRIMARY_TARGET * RECORD_BYTES
DRAIN_LIMIT = 512
PRIMARY_TIMEOUT_SECONDS = 30.0
QUIESCENCE_TIMEOUT_SECONDS = 10.0
QUIET_WINDOW_SECONDS = 1.0
PRIMARY_CHECKPOINT_COUNTS = (1024, 2048, 2500)
QUIESCENCE_REQUIRED_SAMPLES = 5
QUIESCENCE_SAMPLE_INTERVAL_SECONDS = 0.1
QUIESCENCE_MINIMUM_SPAN_SECONDS = 0.4
CONTROL_EVENT_TYPES = frozenset({
    'READER_READY', 'FIRST_RECORD_ASSEMBLED', 'FIRST_RECORD_DURABLE',
    'FIRST_RECORD_VALID', 'PRIMARY_CHECKPOINT_DURABLE',
    'PRIMARY_TARGET_REACHED', 'READER_QUIET', 'READER_EXITED', 'ERROR',
})
MMIO_COLUMNS = [
    'Timestamp', 'Session', 'UserNode', 'BDF', 'Offset', 'Operation',
    'Value', 'Result',
]
LEDGER_COLUMNS = [
    'Timestamp', 'Session', 'UserNode', 'BDF', 'Offset', 'Operation',
    'Value', 'Purpose', 'Authorized', 'Precondition', 'Result',
]
QUIESCENCE_COLUMNS = [
    'Timestamp', 'MonotonicNs', 'Sample', 'Consecutive', 'SpanMs',
    'BootId', 'LockHeld', 'BDF', 'BDFUnchanged', 'DriverBound',
    'Control', 'Status', 'ErrorStatus', 'FatalClear', 'NodeHoldersAllowed',
    'Quiescent', 'Accepted',
]


class GateError(RuntimeError):
    pass


class FailureError(RuntimeError):
    pass


class ReadDeadline(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise GateError(message)


def _nonempty_problem(exc: BaseException) -> str:
    return str(exc).strip() or type(exc).__name__


def _write_json_exclusive(path: Path, value: Mapping) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8', newline='\n') as handle:
        json.dump(value, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())


def _replace_json(path: Path, value: Mapping) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp')
    with temporary.open('w', encoding='utf-8', newline='\n') as handle:
        json.dump(value, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def _read_exact_nofollow(path: Path, expected_bytes: int) -> bytes:
    flags = os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0) | getattr(os, 'O_BINARY', 0)
    fd = os.open(path, flags)
    try:
        chunks = []
        remaining = expected_bytes
        while remaining:
            chunk = os.read(fd, remaining)
            require(bool(chunk), 'R3R4R5_PERSISTED_FILE_SHORT_REREAD')
            chunks.append(chunk)
            remaining -= len(chunk)
        require(os.read(fd, 1) == b'', 'R3R4R5_PERSISTED_FILE_LONG_REREAD')
        return b''.join(chunks)
    finally:
        os.close(fd)


def _append_jsonl(path: Path, row: Mapping) -> None:
    require(not _contains_bytes(row), 'R3R4R5_JSONL_RAW_BYTES_FORBIDDEN')
    with path.open('a', encoding='utf-8', newline='\n') as handle:
        handle.write(json.dumps(row, sort_keys=True) + '\n')
        handle.flush()
        os.fsync(handle.fileno())


def _contains_bytes(value) -> bool:
    if isinstance(value, (bytes, bytearray, memoryview)):
        return True
    if isinstance(value, Mapping):
        return any(_contains_bytes(key) or _contains_bytes(item)
                   for key, item in value.items())
    if isinstance(value, (list, tuple, set, frozenset)):
        return any(_contains_bytes(item) for item in value)
    return False


def compact_emit(channel, event_type: str, **fields) -> None:
    require(event_type in CONTROL_EVENT_TYPES,
            'R3R4R5_CONTROL_IPC_EVENT_NOT_ALLOWED')
    message = {'type': event_type, 'monotonic_ns': time.monotonic_ns(), **fields}
    require(not _contains_bytes(message), 'R3R4R5_RAW_RECORD_CONTROL_IPC_FORBIDDEN')
    encoded = json.dumps(message, sort_keys=True)
    require(len(encoded) < RECORD_BYTES,
            'R3R4R5_CONTROL_IPC_MESSAGE_NOT_COMPACT')
    channel.put(message, timeout=0.5)


def read_lock() -> dict:
    require(LOCK.is_file(), 'R3R4R5_LINUX_LOCK_REQUIRED')
    lock = json.loads(LOCK.read_text(encoding='utf-8'))
    require(lock.get('task') == TASK and lock.get('state') == 'HELD',
            'R3R4R5_LINUX_LOCK_OWNER_MISMATCH')
    boot = P('/proc/sys/kernel/random/boot_id').read_text().strip()
    require(boot == EXPECTED_BOOT and boot == lock.get('boot_id'),
            'R3R4R5_BOOT_CONTINUITY_LOST')
    return lock


def quiescent(control: int, status: int) -> bool:
    # CONTROL disabled; reset not busy; C2H inactive; ring empty; ring not full.
    return control == 0 and status & 0x10F == 0x004


def combined_session_normalization(read_error: Callable[[], int],
                                   write_w1c: Callable[[int], None]) -> dict:
    """Use exactly one pre-write observation and zero or one combined W1C."""
    observed = read_error()
    mask = observed & 0x0000003F
    writes = 0
    post = observed
    if mask:
        write_w1c(mask)
        writes = 1
        post = read_error()
        require((post & 0x3F) == 0,
                'R3R4R5_SESSION_NORMALIZATION_DID_NOT_CLEAR')
    return {
        'observed_error_status': observed,
        'session_normalization_mask': mask,
        'w1c_writes': writes,
        'post_normalization_error_status': post,
    }


def quiescence_streak_update(sample_pass: bool, now: float,
                             consecutive: int, first_pass_time: float | None
                             ) -> tuple[int, float | None, float, bool]:
    """Pure five-sample state transition used by parent proof and self-test."""
    if not sample_pass:
        return 0, None, 0.0, False
    if consecutive == 0 or first_pass_time is None:
        first_pass_time = now
    consecutive += 1
    span = now - first_pass_time
    complete = (consecutive >= QUIESCENCE_REQUIRED_SAMPLES and
                span >= QUIESCENCE_MINIMUM_SPAN_SECONDS)
    return consecutive, first_pass_time, span, complete


def _append_csv(path: Path, columns: list[str], row: Mapping) -> None:
    fresh = not path.exists()
    with path.open('a', encoding='utf-8', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        if fresh:
            writer.writeheader()
        writer.writerow({key: row.get(key, '') for key in columns})
        handle.flush()


class MMIO:
    """Parent-owned, allowlisted, fully logged MMIO descriptor."""

    def __init__(self, session: str = 'T3T4') -> None:
        self.session = session
        read_lock()
        self.proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
        require(self.proof.get('result') == 'PASS', 'NODE_TO_BDF_PROOF_REQUIRED')
        self.node = self.proof['user']
        st = os.stat(self.node)
        require(stat.S_ISCHR(st.st_mode), 'USER_NODE_NOT_CHAR_DEVICE')
        device = (P('/sys/dev/char') /
                  f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}' /
                  'device').resolve()
        require(self.proof['bdf'] in str(device), 'USER_NODE_BDF_PROOF_CHANGED')
        self.fd = os.open(self.node, os.O_RDWR | os.O_NOFOLLOW)
        self.last_error_read: int | None = None
        self.raw_log = ROOT / 'logs/mmio-raw.csv'
        self.ledger = ROOT / 'logs/mmio-write-ledger.csv'

    def close(self) -> None:
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def _guard(self) -> None:
        read_lock()

    def read(self, offset: int) -> int:
        self._guard()
        require(offset % 4 == 0 and
                (0 <= offset <= 0x30 or 0x80 <= offset <= 0xB4 or
                 0x3800 <= offset <= 0x3858),
                'MMIO_READ_ALLOWLIST_VIOLATION')
        stamp = time.time_ns()
        try:
            raw = os.pread(self.fd, 4, offset)
            require(len(raw) == 4, 'SHORT_MMIO_READ')
            value = struct.unpack('<I', raw)[0]
            if offset == 0x383C:
                self.last_error_read = value
            _append_csv(self.raw_log, MMIO_COLUMNS, {
                'Timestamp': stamp, 'Session': self.session,
                'UserNode': self.node, 'BDF': self.proof['bdf'],
                'Offset': f'0x{offset:04X}', 'Operation': 'READ',
                'Value': f'0x{value:08X}', 'Result': 'PASS',
            })
            return value
        except BaseException as exc:
            _append_csv(self.raw_log, MMIO_COLUMNS, {
                'Timestamp': stamp, 'Session': self.session,
                'UserNode': self.node, 'BDF': self.proof['bdf'],
                'Offset': f'0x{offset:04X}', 'Operation': 'READ',
                'Value': 'N/A', 'Result': 'FAIL:' + type(exc).__name__,
            })
            raise

    def _intent_rows(self) -> list[dict]:
        if not self.ledger.exists():
            return []
        with self.ledger.open(encoding='utf-8', newline='') as handle:
            return [row for row in csv.DictReader(handle)
                    if row.get('Result') == 'INTENT']

    def write(self, offset: int, value: int, purpose: str,
              precondition: str) -> None:
        self._guard()
        intents = self._intent_rows()
        reset_count = sum(row['Offset'] == '0x380C' and
                          row['Value'] == '0x00000004' for row in intents)
        enable_count = sum(row['Offset'] == '0x380C' and
                           row['Value'] == '0x00000001' for row in intents)
        normal_disable = sum(row['Purpose'] == 'NORMAL_DISABLE' for row in intents)
        safety_disable = sum(row['Purpose'] == 'SAFETY_DISABLE' for row in intents)
        snapshots = sum(row['Offset'] == '0x3844' for row in intents)
        normalization_w1c = sum(
            row['Purpose'] == 'SESSION_NORMALIZATION_W1C' for row in intents)

        if offset == 0x380C and value == 0x00000004:
            require(purpose == 'RESET_STREAM_STATE' and reset_count == 0,
                    'RESET_STREAM_STATE_BUDGET_EXCEEDED')
        elif offset == 0x380C and value == 0x00000001:
            require(purpose == 'ENABLE_C2H' and enable_count == 0,
                    'STREAM_ENABLE_BUDGET_EXCEEDED')
        elif offset == 0x380C and value == 0x00000000:
            if purpose == 'NORMAL_DISABLE':
                require(normal_disable == 0, 'NORMAL_DISABLE_BUDGET_EXCEEDED')
            elif purpose == 'SAFETY_DISABLE':
                require(enable_count == 1 and safety_disable == 0,
                        'SAFETY_DISABLE_BUDGET_OR_PRECONDITION')
            else:
                raise GateError('DISABLE_PURPOSE_INVALID')
        elif offset == 0x3844 and value == 0x00000001:
            require(purpose == 'COHERENT_SNAPSHOT' and snapshots < 3,
                    'SNAPSHOT_WRITE_BUDGET_EXCEEDED')
        elif offset == 0x383C and 0 < value <= 0x3F:
            require(purpose == 'SESSION_NORMALIZATION_W1C' and
                    normalization_w1c == 0,
                    'SESSION_NORMALIZATION_W1C_BUDGET_EXCEEDED')
            require(self.last_error_read is not None and
                    value == (self.last_error_read & 0x3F),
                    'SESSION_NORMALIZATION_W1C_MASK_MISMATCH')
            require(precondition == 'POST_RESET_QUIESCENT',
                    'SESSION_NORMALIZATION_W1C_PRECONDITION')
        else:
            raise GateError('R3R4R5_MMIO_WRITE_ALLOWLIST_VIOLATION')

        stamp = time.time_ns()
        base = {
            'Timestamp': stamp, 'Session': self.session,
            'UserNode': self.node, 'BDF': self.proof['bdf'],
            'Offset': f'0x{offset:04X}', 'Operation': 'WRITE',
            'Value': f'0x{value:08X}', 'Purpose': purpose,
            'Authorized': 'YES', 'Precondition': precondition,
        }
        _append_csv(self.ledger, LEDGER_COLUMNS, {**base, 'Result': 'INTENT'})
        try:
            count = os.pwrite(self.fd, struct.pack('<I', value), offset)
            require(count == 4, 'SHORT_MMIO_WRITE')
            _append_csv(self.ledger, LEDGER_COLUMNS, {**base, 'Result': 'PASS'})
            _append_csv(self.raw_log, MMIO_COLUMNS, {
                'Timestamp': stamp, 'Session': self.session,
                'UserNode': self.node, 'BDF': self.proof['bdf'],
                'Offset': f'0x{offset:04X}', 'Operation': 'WRITE',
                'Value': f'0x{value:08X}', 'Result': 'PASS',
            })
            with (ROOT / 'logs/write-completions.jsonl').open(
                    'a', encoding='utf-8', newline='\n') as handle:
                handle.write(json.dumps({
                    'timestamp': stamp, 'session': self.session,
                    'offset': offset, 'value': value, 'purpose': purpose,
                    'bytes': count, 'result': 'PASS',
                }) + '\n')
                handle.flush()
                os.fsync(handle.fileno())
        except BaseException as exc:
            _append_csv(self.ledger, LEDGER_COLUMNS,
                        {**base, 'Result': 'FAIL:' + type(exc).__name__})
            _append_csv(self.raw_log, MMIO_COLUMNS, {
                'Timestamp': stamp, 'Session': self.session,
                'UserNode': self.node, 'BDF': self.proof['bdf'],
                'Offset': f'0x{offset:04X}', 'Operation': 'WRITE',
                'Value': f'0x{value:08X}',
                'Result': 'FAIL:' + type(exc).__name__,
            })
            raise

    def snapshot(self, label: str) -> dict:
        epoch = self.read(0x3838)
        generation = self.read(0x384C)
        require(not (self.read(0x3810) & 0x300), 'SNAPSHOT_OR_RESET_BUSY')
        self.write(0x3844, 1, 'COHERENT_SNAPSHOT', label)
        deadline = time.monotonic() + 2.0
        while (self.read(0x3848) & 3) != 2:
            require(time.monotonic() < deadline, 'COHERENT_SNAPSHOT_TIMEOUT')
            time.sleep(0.001)
        values = {f'0x{offset:04X}': self.read(offset)
                  for offset in list(range(0x3814, 0x3838, 4)) +
                  [0x3850, 0x3854, 0x3858]}
        require(self.read(0x3838) == epoch, 'SNAPSHOT_EPOCH_CHANGED')
        expected_generation = (generation + 1) & 0xFFFFFFFF
        require(self.read(0x384C) == expected_generation,
                'SNAPSHOT_GENERATION_INVALID')
        require((self.read(0x3848) & 3) == 2, 'SNAPSHOT_VALID_LOST')
        values.update(epoch=epoch, generation=expected_generation, label=label)
        return values


class RecordSink:
    """Direct-to-private-file record assembler used by hardware and self-test."""

    def __init__(self, private_dir: Path, contract: AbiContract,
                 armed_epoch: int, emit: Callable[..., None], *,
                 primary_target: int = PRIMARY_TARGET,
                 drain_limit: int = DRAIN_LIMIT,
                 first_persist_delay: float = 0.0) -> None:
        self.private_dir = private_dir
        self.private_dir.mkdir(parents=True, exist_ok=True)
        self.contract = contract
        self.armed_epoch = armed_epoch & 0xFFFFFFFF
        self.emit = emit
        self.primary_target = primary_target
        self.drain_limit = drain_limit
        self.first_persist_delay = first_persist_delay
        self.pending = bytearray()
        self.primary_count = 0
        self.drain_count = 0
        self.primary_hash = hashlib.sha256()
        self.drain_hash = hashlib.sha256()
        self.first_record_hash = None
        self.first_payload_hash = None
        self.first_header = None
        self.first_durable = False
        self.first_valid = False
        self.first_error = None
        self.last_completed_operation = 'RECORD_SINK_INITIALIZING'
        self.primary_path = private_dir / 'T3T4-primary-records.bin'
        self.drain_path = private_dir / 'T3T4-drain-records.bin'
        self.trailing_path = private_dir / 'T3T4-incomplete-trailing.bin'
        self.first_path = private_dir / 'T3T4-first-record.bin'
        self.payload_path = private_dir / 'T3T4-first-payload.bin'
        self.first_receipt_path = (
            private_dir /
            'G2B_HW0_PRODUCT_R3R4R5_PERSISTED_FIRST_RECORD_RECEIPT.json')
        self.checkpoint_receipt_path = (
            private_dir /
            'G2B_HW0_PRODUCT_R3R4R5_PRIMARY_DURABILITY_CHECKPOINTS.jsonl')
        self.journal_path = private_dir / 'T3T4-capture-journal.jsonl'
        self.result_path = private_dir / 'T3T4-reader-result.json'
        self.primary_file = self.primary_path.open('xb', buffering=0)
        self.drain_file = self.drain_path.open('xb', buffering=0)
        self.journal = self.journal_path.open('x', encoding='utf-8', newline='\n')
        self.journal_lock = threading.Lock()
        self.first_queue: queue.Queue = queue.Queue(maxsize=1)
        self.first_thread = threading.Thread(
            target=self._persist_first, name='r3r4r5-first-record-persister',
            daemon=False,
        )
        self.checkpoint_queue: queue.Queue = queue.Queue(
            maxsize=len(PRIMARY_CHECKPOINT_COUNTS) + 1)
        self.checkpoint_condition = threading.Condition()
        self.checkpoint_requested: list[int] = []
        self.checkpoint_results: dict[int, dict] = {}
        self.checkpoint_error: dict | None = None
        self.checkpoint_thread = threading.Thread(
            target=self._checkpoint_worker,
            name='r3r4r5-primary-durability-worker', daemon=False,
        )
        self.first_thread.start()
        self.checkpoint_thread.start()
        self.closed = False
        self.last_completed_operation = 'RECORD_SINK_READY'

    def _journal(self, event: str, **fields) -> None:
        row = {'event': event, 'utc_ns': time.time_ns(), **fields}
        require(not _contains_bytes(row), 'R3R4R5_PRIVATE_JOURNAL_RAW_BYTES_FORBIDDEN')
        with self.journal_lock:
            self.journal.write(json.dumps(row, sort_keys=True) + '\n')
            self.journal.flush()

    def _persist_first(self) -> None:
        try:
            blob = self.first_queue.get()
            if blob is None:
                return
            if self.first_persist_delay:
                time.sleep(self.first_persist_delay)
            with self.first_path.open('xb', buffering=0) as handle:
                written = handle.write(blob)
                require(written == RECORD_BYTES,
                        'R3R4R5_FIRST_RECORD_SHORT_PERSIST')
                handle.flush()
                os.fsync(handle.fileno())
            del blob
            persisted_record = _read_exact_nofollow(self.first_path, RECORD_BYTES)

            validator = StreamValidator(self.contract, armed_epoch=self.armed_epoch)
            assessment = validator.accept(persisted_record)
            errors = list(assessment.errors) + list(assessment.discontinuity_reasons)
            require(assessment.structurally_valid and not assessment.session_fatal and
                    not errors, 'R3R4R5_FIRST_RECORD_ABI_VALIDATION_FAILED:' +
                    ';'.join(errors[:8]))
            record = assessment.record
            require(record is not None, 'R3R4R5_FIRST_RECORD_PARSE_MISSING')
            require(record.reset_epoch == self.armed_epoch,
                    'R3R4R5_FIRST_RECORD_STALE_EPOCH')
            persisted_payload_slice = persisted_record[
                self.contract.payload_first:self.contract.padding_first]
            with self.payload_path.open('xb', buffering=0) as handle:
                written = handle.write(persisted_payload_slice)
                require(written == self.contract.payload_bytes,
                        'R3R4R5_FIRST_PAYLOAD_SHORT_PERSIST')
                handle.flush()
                os.fsync(handle.fileno())
            persisted_payload = _read_exact_nofollow(
                self.payload_path, self.contract.payload_bytes)
            require(persisted_payload == persisted_payload_slice,
                    'R3R4R5_REREAD_PAYLOAD_RECORD_SLICE_MISMATCH')

            self.first_record_hash = hashlib.sha256(
                persisted_record).hexdigest().upper()
            self.first_payload_hash = hashlib.sha256(
                persisted_payload).hexdigest().upper()
            self.first_header = dict(record.header)
            self.first_valid = True
            durable_utc_ns = time.time_ns()
            receipt = {
                'schema': 'R3R4R5_PERSISTED_FIRST_RECORD_RECEIPT_V1',
                'task': TASK,
                'first_record_path': str(self.first_path),
                'first_payload_path': str(self.payload_path),
                'first_record_written_bytes': RECORD_BYTES,
                'first_record_reread_bytes': len(persisted_record),
                'first_payload_written_bytes': self.contract.payload_bytes,
                'first_payload_reread_bytes': len(persisted_payload),
                'record_fsync_complete': True,
                'payload_fsync_complete': True,
                'record_sha256': self.first_record_hash,
                'payload_sha256': self.first_payload_hash,
                'record_hash_source': 'REREAD_PERSISTED_FILE',
                'payload_hash_source': 'REREAD_PERSISTED_FILE',
                'abi_parse_source': 'REREAD_PERSISTED_FIRST_RECORD',
                'payload_equals_record_slice': True,
                'abi_result': 'PASS',
                'first_record_durable_utc_ns': durable_utc_ns,
                'raw_payload_in_receipt': False,
            }
            _write_json_exclusive(self.first_receipt_path, receipt)
            self.emit('FIRST_RECORD_VALID', valid=True,
                      header=self.first_header, padding_zero=True)
            self.first_durable = True
            self.emit('FIRST_RECORD_DURABLE', bytes=RECORD_BYTES,
                      record_sha256=self.first_record_hash,
                      payload_sha256=self.first_payload_hash,
                      durable_utc_ns=durable_utc_ns,
                      receipt=self.first_receipt_path.name)
        except BaseException as exc:
            trace = traceback_module.format_exc()
            self.first_error = {
                'blocker': _nonempty_problem(exc),
                'exception_type': type(exc).__name__,
                'exception_repr': repr(exc),
                'traceback': trace,
            }
            try:
                self.emit('FIRST_RECORD_VALID', valid=False,
                          blocker=self.first_error['blocker'])
                self.emit('ERROR', source='FIRST_RECORD_PERSISTER',
                          **self.first_error)
            except BaseException:
                pass

    def _request_checkpoint(self, record_count: int) -> None:
        require(record_count in PRIMARY_CHECKPOINT_COUNTS,
                'R3R4R5_PRIMARY_CHECKPOINT_COUNT_NOT_ALLOWED')
        require(record_count not in self.checkpoint_requested,
                'R3R4R5_PRIMARY_CHECKPOINT_DUPLICATE_REQUEST')
        self.checkpoint_requested.append(record_count)
        self.checkpoint_queue.put(record_count, timeout=0.5)
        self._journal('PRIMARY_CHECKPOINT_REQUESTED', record_count=record_count,
                      communication='METADATA_ONLY_RECORD_COUNT')

    def _checkpoint_worker(self) -> None:
        try:
            while True:
                record_count = self.checkpoint_queue.get()
                if record_count is None:
                    return
                requested_utc_ns = time.time_ns()
                flags = (os.O_RDWR | getattr(os, 'O_NOFOLLOW', 0) |
                         getattr(os, 'O_BINARY', 0))
                fd = os.open(self.primary_path, flags)
                try:
                    os.fsync(fd)
                    persisted_size = os.fstat(fd).st_size
                finally:
                    os.close(fd)
                required_size = record_count * RECORD_BYTES
                require(persisted_size >= required_size,
                        'R3R4R5_PRIMARY_CHECKPOINT_FILE_TOO_SHORT')
                row = {
                    'schema': 'R3R4R5_PRIMARY_DURABILITY_CHECKPOINT_V1',
                    'task': TASK,
                    'record_count': record_count,
                    'required_size': required_size,
                    'persisted_size': persisted_size,
                    'fsync_complete': True,
                    'communication': 'METADATA_ONLY_RECORD_COUNT',
                    'requested_utc_ns': requested_utc_ns,
                    'completed_utc_ns': time.time_ns(),
                    'result': 'PASS',
                    'raw_payload_in_communication': False,
                }
                _append_jsonl(self.checkpoint_receipt_path, row)
                with self.checkpoint_condition:
                    self.checkpoint_results[record_count] = row
                    self.checkpoint_condition.notify_all()
                self.emit('PRIMARY_CHECKPOINT_DURABLE',
                          record_count=record_count,
                          persisted_size=persisted_size,
                          fsync_complete=True,
                          communication='METADATA_ONLY_RECORD_COUNT')
        except BaseException as exc:
            problem = {
                'blocker': 'R3R4R5_PRIMARY_CHECKPOINT_FAILED:' +
                           _nonempty_problem(exc),
                'exception_type': type(exc).__name__,
                'exception_repr': repr(exc),
                'traceback': traceback_module.format_exc(),
            }
            with self.checkpoint_condition:
                self.checkpoint_error = problem
                self.checkpoint_condition.notify_all()
            try:
                self.emit('ERROR', source='PRIMARY_DURABILITY_WORKER', **problem)
            except BaseException:
                pass

    def _wait_checkpoint(self, record_count: int, timeout: float = 5.0) -> dict:
        deadline = time.monotonic() + timeout
        with self.checkpoint_condition:
            while (record_count not in self.checkpoint_results and
                   self.checkpoint_error is None):
                remaining = deadline - time.monotonic()
                require(remaining > 0,
                        f'R3R4R5_PRIMARY_CHECKPOINT_TIMEOUT:{record_count}')
                self.checkpoint_condition.wait(remaining)
            require(self.checkpoint_error is None,
                    (self.checkpoint_error or {}).get(
                        'blocker', 'R3R4R5_PRIMARY_CHECKPOINT_FAILED'))
            return self.checkpoint_results[record_count]

    def _await_primary_target_prerequisites(self) -> None:
        self.first_thread.join(timeout=5.0)
        require(not self.first_thread.is_alive(),
                'R3R4R5_FIRST_RECORD_PERSISTER_EXIT_TIMEOUT')
        require(self.first_error is None and self.first_durable and self.first_valid,
                (self.first_error or {}).get(
                    'blocker', 'R3R4R5_FIRST_RECORD_DURABLE_BEFORE_PRIMARY_TARGET'))
        self._wait_checkpoint(1024)
        self._wait_checkpoint(2048)

    def accept(self, chunk: bytes) -> None:
        require(not self.closed, 'R3R4R5_RECORD_SINK_ALREADY_CLOSED')
        require(isinstance(chunk, bytes), 'R3R4R5_READER_CHUNK_NOT_BYTES')
        if not chunk:
            return
        self.pending.extend(chunk)
        self.last_completed_operation = 'C2H_CHUNK_BUFFERED'
        while len(self.pending) >= RECORD_BYTES:
            blob = bytes(self.pending[:RECORD_BYTES])
            del self.pending[:RECORD_BYTES]
            if self.primary_count < self.primary_target:
                written = self.primary_file.write(blob)
                require(written == RECORD_BYTES, 'R3R4R5_PRIMARY_SHORT_WRITE')
                self.primary_hash.update(blob)
                self.primary_count += 1
                self._journal('PRIMARY_RECORD_WRITTEN', count=self.primary_count)
                if self.primary_count == 1:
                    self.emit('FIRST_RECORD_ASSEMBLED', bytes=RECORD_BYTES,
                              primary_record=1)
                    self.first_queue.put(blob, timeout=0.5)
                if self.primary_count in PRIMARY_CHECKPOINT_COUNTS:
                    self._request_checkpoint(self.primary_count)
                if self.primary_count == self.primary_target:
                    self._await_primary_target_prerequisites()
                    self.emit('PRIMARY_TARGET_REACHED',
                              primary_records=self.primary_count,
                              primary_bytes=self.primary_count * RECORD_BYTES,
                              first_record_durable=True,
                              checkpoint_1024=True, checkpoint_2048=True,
                              final_checkpoint_pending=True)
            else:
                require(self.drain_count < self.drain_limit,
                        'R3R4R5_DRAIN_RECORD_LIMIT_EXCEEDED')
                written = self.drain_file.write(blob)
                require(written == RECORD_BYTES, 'R3R4R5_DRAIN_SHORT_WRITE')
                self.drain_hash.update(blob)
                self.drain_count += 1
                self._journal('DRAIN_RECORD_WRITTEN', count=self.drain_count)
            self.last_completed_operation = 'COMPLETE_RECORD_WRITTEN'

    def finalize(self, *, result: str, blocker: str,
                 exception_type: str | None = None,
                 exception_repr: str | None = None,
                 traceback_text: str | None = None) -> dict:
        if self.closed:
            return json.loads(self.result_path.read_text())
        self.closed = True
        if self.primary_count == 0:
            try:
                self.first_queue.put(None, timeout=0.5)
            except queue.Full:
                pass
        self.first_thread.join(timeout=5.0)
        if self.first_thread.is_alive():
            result = 'BLOCKED'
            blocker = 'R3R4R5_FIRST_RECORD_PERSISTER_EXIT_TIMEOUT'
        if 2500 in self.checkpoint_requested:
            try:
                self._wait_checkpoint(2500)
            except BaseException as exc:
                if result == 'PASS':
                    result = 'BLOCKED'
                    blocker = _nonempty_problem(exc)
                    exception_type = type(exc).__name__
                    exception_repr = repr(exc)
                    traceback_text = traceback_module.format_exc()
        try:
            self.checkpoint_queue.put(None, timeout=0.5)
        except queue.Full:
            pass
        self.checkpoint_thread.join(timeout=5.0)
        if self.checkpoint_thread.is_alive() and result == 'PASS':
            result = 'BLOCKED'
            blocker = 'R3R4R5_PRIMARY_CHECKPOINT_WORKER_EXIT_TIMEOUT'
        if self.checkpoint_error and result == 'PASS':
            result = 'BLOCKED'
            blocker = self.checkpoint_error['blocker']
            exception_type = self.checkpoint_error['exception_type']
            exception_repr = self.checkpoint_error['exception_repr']
            traceback_text = self.checkpoint_error['traceback']
        if self.first_error and result == 'PASS':
            result = 'FAIL'
            blocker = self.first_error['blocker']
            exception_type = self.first_error['exception_type']
            exception_repr = self.first_error['exception_repr']
            traceback_text = self.first_error['traceback']
        blocker = blocker.strip() if blocker else ''
        require(bool(blocker), 'R3R4R5_BLANK_BLOCKER_FORBIDDEN')
        try:
            for handle in (self.primary_file, self.drain_file):
                handle.flush()
                os.fsync(handle.fileno())
                handle.close()
            with self.trailing_path.open('xb', buffering=0) as handle:
                if self.pending:
                    handle.write(self.pending)
                handle.flush()
                os.fsync(handle.fileno())
            self.last_completed_operation = 'ALL_CAPTURE_FILES_DURABLE'
            self._journal('READER_FINALIZED', result=result, blocker=blocker,
                          primary_records=self.primary_count,
                          drain_records=self.drain_count,
                          trailing_bytes=len(self.pending))
            self.journal.flush()
            os.fsync(self.journal.fileno())
            self.journal.close()
            primary_sha256 = hashlib.sha256(
                self.primary_path.read_bytes()).hexdigest().upper()
            drain_sha256 = hashlib.sha256(
                self.drain_path.read_bytes()).hexdigest().upper()
        except BaseException as exc:
            primary_sha256 = self.primary_hash.hexdigest().upper()
            drain_sha256 = self.drain_hash.hexdigest().upper()
            if result == 'PASS':
                result = 'BLOCKED'
                blocker = 'R3R4R5_CAPTURE_FINAL_SYNC_FAILED:' + _nonempty_problem(exc)
                exception_type = type(exc).__name__
                exception_repr = repr(exc)
                traceback_text = traceback_module.format_exc()
        state = {
            'result': result,
            'blocker': blocker,
            'primary_records': self.primary_count,
            'primary_bytes': self.primary_count * RECORD_BYTES,
            'drain_records': self.drain_count,
            'drain_bytes': self.drain_count * RECORD_BYTES,
            'complete_records': self.primary_count + self.drain_count,
            'incomplete_trailing_bytes': len(self.pending),
            'primary_sha256': primary_sha256,
            'drain_sha256': drain_sha256,
            'capture_hash_source': 'REREAD_PERSISTED_FILES',
            'first_record_durable': self.first_durable,
            'first_record_valid': self.first_valid,
            'first_record_sha256': self.first_record_hash,
            'first_payload_sha256': self.first_payload_hash,
            'first_header': self.first_header,
            'first_record_hash_source': 'REREAD_PERSISTED_FILE',
            'first_payload_hash_source': 'REREAD_PERSISTED_FILE',
            'abi_parse_source': 'REREAD_PERSISTED_FIRST_RECORD',
            'checkpoint_schedule': list(PRIMARY_CHECKPOINT_COUNTS),
            'checkpoint_requested': list(self.checkpoint_requested),
            'checkpoint_passed': sorted(self.checkpoint_results),
            'checkpoint_communication': 'METADATA_ONLY_RECORD_COUNT',
            'exception_type': exception_type,
            'exception_repr': exception_repr,
            'traceback': traceback_text,
            'last_completed_operation': self.last_completed_operation,
            'raw_payload_control_ipc': False,
        }
        _replace_json(self.result_path, state)
        return state


def _alarm_handler(*_) -> None:
    raise ReadDeadline()


def quiet_window_update(parent_is_quiescent: bool, received_data: bool,
                        now: float, quiet_since: float | None,
                        quiet_seconds: float = QUIET_WINDOW_SECONDS
                        ) -> tuple[float | None, bool]:
    """Pure cooperative-exit state transition shared with the offline test."""
    if not parent_is_quiescent:
        return None, False
    if received_data or quiet_since is None:
        return now, False
    return quiet_since, (now - quiet_since) >= quiet_seconds


def reader_worker(c2h_node: str, private_dir: str, contract: AbiContract,
                  armed_epoch: int, parent_quiescent, messages) -> None:
    """Child owns only C2H plus private output/journal files; never MMIO."""
    fd = -1
    sink = None
    result = None
    blocker = 'R3R4R5_READER_UNFINISHED'
    exception_type = None
    exception_repr = None
    trace = None
    quiet_since = None
    try:
        st = os.stat(c2h_node)
        require(stat.S_ISCHR(st.st_mode), 'R3R4R5_C2H_NODE_NOT_CHAR_DEVICE')
        fd = os.open(c2h_node, os.O_RDONLY | os.O_NOFOLLOW)
        emit = lambda event_type, **fields: compact_emit(
            messages, event_type, **fields)
        sink = RecordSink(P(private_dir), contract, armed_epoch, emit)
        signal.signal(signal.SIGALRM, _alarm_handler)
        signal.siginterrupt(signal.SIGALRM, True)
        compact_emit(messages, 'READER_READY', pid=os.getpid(), node=c2h_node)
        while True:
            timeout = 0.1
            signal.setitimer(signal.ITIMER_REAL, timeout)
            chunk = None
            try:
                chunk = os.read(fd, 256 * 1024)
            except ReadDeadline:
                chunk = None
            finally:
                signal.setitimer(signal.ITIMER_REAL, 0)
            if chunk:
                sink.accept(chunk)
            now = time.monotonic()
            quiet_since, quiet_complete = quiet_window_update(
                parent_quiescent.is_set(), bool(chunk), now, quiet_since)
            if quiet_complete:
                compact_emit(messages, 'READER_QUIET',
                             quiet_seconds=QUIET_WINDOW_SECONDS,
                             complete_records=(sink.primary_count +
                                               sink.drain_count),
                             trailing_bytes=len(sink.pending))
                blocker = 'NONE'
                result = sink.finalize(result='PASS', blocker='NONE')
                break
            elif chunk == b'':
                time.sleep(0.01)
    except BaseException as exc:
        blocker = _nonempty_problem(exc)
        exception_type = type(exc).__name__
        exception_repr = repr(exc)
        trace = traceback_module.format_exc()
        try:
            compact_emit(messages, 'ERROR', source='C2H_READER',
                         blocker=blocker, exception_type=exception_type,
                         exception_repr=exception_repr, traceback=trace)
        except BaseException:
            pass
        if sink is not None:
            result = sink.finalize(
                result='BLOCKED', blocker=blocker,
                exception_type=exception_type,
                exception_repr=exception_repr,
                traceback_text=trace,
            )
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        if fd >= 0:
            os.close(fd)
        if result is None:
            result = {
                'result': 'BLOCKED', 'blocker': blocker,
                'primary_records': 0, 'drain_records': 0,
                'complete_records': 0, 'incomplete_trailing_bytes': 0,
                'exception_type': exception_type,
                'exception_repr': exception_repr, 'traceback': trace,
                'last_completed_operation': 'READER_SETUP',
                'raw_payload_control_ipc': False,
            }
        try:
            compact_emit(messages, 'READER_EXITED', reader_result=result)
        except BaseException:
            pass


def _open_holders(target: str) -> list[dict]:
    holders = []
    for proc in P('/proc').iterdir():
        if not proc.name.isdigit():
            continue
        try:
            comm = (proc / 'comm').read_text().strip()
            for descriptor in (proc / 'fd').iterdir():
                try:
                    linked = os.readlink(descriptor)
                except OSError:
                    continue
                if linked == target:
                    holders.append({'pid': int(proc.name), 'comm': comm,
                                    'target': linked})
        except (OSError, PermissionError):
            pass
    return holders


def _iter_file_records(path: Path) -> Iterator[bytes]:
    with path.open('rb', buffering=0) as handle:
        while True:
            blob = handle.read(RECORD_BYTES)
            if not blob:
                break
            if len(blob) != RECORD_BYTES:
                raise FailureError(
                    f'R3R4R5_CAPTURE_FILE_TRAILING_BYTES:{path.name}:{len(blob)}')
            yield blob


def validate_capture(contract: AbiContract, armed_epoch: int,
                     primary_path: Path, drain_path: Path,
                     trailing_path: Path) -> dict:
    require(primary_path.stat().st_size == PRIMARY_BYTES,
            'R3R4R5_PRIMARY_FILE_SIZE_INVALID')
    require(drain_path.stat().st_size % RECORD_BYTES == 0,
            'R3R4R5_DRAIN_FILE_SIZE_INVALID')
    require(trailing_path.stat().st_size == 0,
            'R3R4R5_INCOMPLETE_TRAILING_BYTES_NONZERO')
    validator = StreamValidator(contract, armed_epoch=armed_epoch)
    total = 0
    malformed = 0
    padding_errors = 0
    gaps = 0
    unexpected_epoch = 0
    duplicates = 0
    errors = []
    seen_global = set()
    seen_attempt = set()
    seen_lines = set()
    first_header = None
    last_header = None
    source_snapshot_first = None
    source_snapshot_changes = 0
    primary_hash = hashlib.sha256()
    drain_hash = hashlib.sha256()
    combined_hash = hashlib.sha256()
    first_primary_record = None
    for path in (primary_path, drain_path):
        for blob in _iter_file_records(path):
            if path == primary_path:
                primary_hash.update(blob)
                if first_primary_record is None:
                    first_primary_record = blob
            else:
                drain_hash.update(blob)
            combined_hash.update(blob)
            assessment = validator.accept(blob)
            total += 1
            if not assessment.structurally_valid:
                malformed += 1
                padding_errors += sum('padding byte' in item
                                      for item in assessment.errors)
                errors.extend(assessment.errors)
                continue
            record = assessment.record
            assert record is not None
            header = dict(record.header)
            if first_header is None:
                first_header = header
            last_header = header
            if record.reset_epoch != armed_epoch:
                unexpected_epoch += 1
            global_key = (record.reset_epoch, record.global_stream_sequence)
            attempt_key = (record.reset_epoch, record.logical_channel_id,
                           record.channel_attempt_sequence)
            line_key = (record.reset_epoch, record.logical_channel_id,
                        record.physical_input_id, record.source_frame_sequence,
                        record.source_line_sequence)
            if global_key in seen_global or attempt_key in seen_attempt or \
                    line_key in seen_lines:
                duplicates += 1
            seen_global.add(global_key)
            seen_attempt.add(attempt_key)
            seen_lines.add(line_key)
            snapshot = (header['source_malformed_count_snapshot'],
                        header['source_dropped_count_snapshot'])
            if source_snapshot_first is None:
                source_snapshot_first = snapshot
            elif snapshot != source_snapshot_first:
                source_snapshot_changes += 1
            if assessment.discontinuity_reasons:
                gaps += 1
                errors.extend(assessment.discontinuity_reasons)
            if assessment.session_fatal:
                errors.append('session_fatal')
    drain_records = drain_path.stat().st_size // RECORD_BYTES
    require(total == PRIMARY_TARGET + drain_records,
            'R3R4R5_HOST_RECORD_COUNT_FILE_MISMATCH')
    require(first_primary_record is not None, 'R3R4R5_FIRST_PRIMARY_RECORD_MISSING')
    first_path = primary_path.parent / 'T3T4-first-record.bin'
    payload_path = primary_path.parent / 'T3T4-first-payload.bin'
    persisted_first = _read_exact_nofollow(first_path, RECORD_BYTES)
    persisted_payload = _read_exact_nofollow(payload_path, contract.payload_bytes)
    require(persisted_first == first_primary_record,
            'R3R4R5_FIRST_RECORD_NOT_PRIMARY_OFFSET_ZERO')
    require(persisted_payload == persisted_first[
        contract.payload_first:contract.padding_first],
        'R3R4R5_FIRST_PAYLOAD_NOT_FIRST_RECORD_SLICE')
    if (malformed or padding_errors or gaps or unexpected_epoch or duplicates or
            source_snapshot_changes or errors):
        raise FailureError(
            'R3R4R5_FULL_RECORD_VALIDATION_FAILED:' +
            json.dumps({
                'malformed': malformed, 'padding_errors': padding_errors,
                'gaps': gaps, 'unexpected_epoch': unexpected_epoch,
                'duplicates': duplicates,
                'source_snapshot_changes': source_snapshot_changes,
                'errors': errors[:8],
            }, sort_keys=True)
        )
    require(first_header is not None and last_header is not None,
            'R3R4R5_NO_VALID_RECORDS')
    return {
        'result': 'PASS', 'total_complete_records': total,
        'primary_records': PRIMARY_TARGET, 'drain_records': drain_records,
        'sequence_gaps': gaps, 'unexplained_sequence_gaps': gaps,
        'sequence_duplicates': duplicates, 'malformed_records': malformed,
        'padding_errors': padding_errors,
        'unexpected_epoch_changes': unexpected_epoch,
        'stale_epoch_records': unexpected_epoch,
        'source_snapshot_changes': source_snapshot_changes,
        'source_snapshot_first': source_snapshot_first,
        'primary_sha256': primary_hash.hexdigest().upper(),
        'drain_sha256': drain_hash.hexdigest().upper(),
        'combined_complete_record_sha256': combined_hash.hexdigest().upper(),
        'first_record_sha256': hashlib.sha256(
            persisted_first).hexdigest().upper(),
        'first_payload_sha256': hashlib.sha256(
            persisted_payload).hexdigest().upper(),
        'hash_source': 'REREAD_PERSISTED_FILES',
        'first_record_equals_primary_offset_zero': True,
        'first_header': first_header, 'last_header': last_header,
        'last_global': last_header['global_stream_sequence'],
        'last_channel': last_header['channel_attempt_sequence'],
    }


def reconcile_counters(before: Mapping, after: Mapping, total: int,
                       last_global: int, last_channel: int) -> dict:
    def delta(key: str) -> int:
        return (int(after[key]) - int(before[key])) & 0xFFFFFFFF

    beats = ((((int(after['0x3830']) << 32) | int(after['0x382C'])) -
              ((int(before['0x3830']) << 32) | int(before['0x382C']))) &
             0xFFFFFFFFFFFFFFFF)
    values = {
        'records_attempted_delta': delta('0x3814'),
        'records_committed_delta': delta('0x3818'),
        'records_streamed_delta': delta('0x381C'),
        'records_dropped_delta': delta('0x3820'),
        'overflow_count_delta': delta('0x3824'),
        'discontinuity_delta': delta('0x3828'),
        'beats_streamed_delta': beats,
        'expected_beats': total * 512,
        'records_abandoned_delta': delta('0x3850'),
        'reset_events_delta': delta('0x3854'),
        'last_global_observed': int(after['0x3834']),
        'last_global_expected': last_global,
        'last_channel_observed': int(after['0x3858']),
        'last_channel_expected': last_channel,
    }
    checks = (
        values['records_attempted_delta'] == total,
        values['records_committed_delta'] == total,
        values['records_streamed_delta'] == total,
        values['beats_streamed_delta'] == total * 512,
        values['records_dropped_delta'] == 0,
        values['overflow_count_delta'] == 0,
        values['discontinuity_delta'] == 0,
        values['records_abandoned_delta'] == 0,
        values['reset_events_delta'] == 0,
        values['last_global_observed'] == last_global,
        values['last_channel_observed'] == last_channel,
    )
    if not all(checks):
        raise FailureError('R3R4R5_COUNTER_RECONCILIATION_FAILED:' +
                           json.dumps(values, sort_keys=True))
    return {'result': 'PASS', **values}


def _drain_messages(messages, state: dict, *, wait: float = 0.0) -> None:
    first = True
    while True:
        try:
            message = messages.get(timeout=wait if first else 0.0)
        except queue.Empty:
            return
        first = False
        event_type = message.get('type')
        require(event_type in CONTROL_EVENT_TYPES,
                'R3R4R5_CONTROL_IPC_EVENT_NOT_ALLOWED')
        require(not _contains_bytes(message),
                'R3R4R5_RAW_RECORD_CONTROL_IPC_FORBIDDEN')
        state.setdefault('events', []).append(message)
        state[event_type] = message


def _parent_quiescence(mmio: MMIO, timeout: float,
                       allowed_pids: set[int]) -> tuple[bool, list[dict]]:
    observations = []
    deadline = time.monotonic() + timeout
    consecutive_quiescent = 0
    first_quiescent_time = None
    expected_bdf = mmio.proof['bdf']
    sample_number = 0
    while True:
        sample_started = time.monotonic()
        lock = read_lock()
        bdf_path = P('/sys/bus/pci/devices') / expected_bdf
        bdf_unchanged = bdf_path.is_dir() and bdf_path.name == expected_bdf
        driver_link = bdf_path / 'driver'
        driver_bound = (driver_link.is_symlink() and
                        driver_link.resolve().name == 'xdma_ahd_pcie')
        holders = (_open_holders(mmio.proof['user']) +
                   _open_holders(mmio.proof['c2h']))
        holders_allowed = all(item['pid'] in allowed_pids for item in holders)
        control = mmio.read(0x380C)
        status = mmio.read(0x3810)
        error_status = mmio.read(0x383C)
        hardware_quiescent = quiescent(control, status)
        fatal_clear = (error_status & 0x38) == 0
        sample_pass = (bdf_unchanged and driver_bound and holders_allowed and
                       hardware_quiescent and fatal_clear)
        now = time.monotonic()
        consecutive_quiescent, first_quiescent_time, span, complete = (
            quiescence_streak_update(
                sample_pass, now, consecutive_quiescent,
                first_quiescent_time))
        sample_number += 1
        observation = {
            'utc_ns': time.time_ns(), 'monotonic_ns': time.monotonic_ns(),
            'sample': sample_number, 'consecutive': consecutive_quiescent,
            'span_ms': round(span * 1000.0, 3),
            'boot_id': lock['boot_id'], 'lock_held': True,
            'bdf': expected_bdf, 'bdf_unchanged': bdf_unchanged,
            'driver_bound': driver_bound, 'control': control,
            'status': status, 'error_status': error_status,
            'fatal_clear': fatal_clear, 'node_holders_allowed': holders_allowed,
            'holders': holders, 'hardware_quiescent': hardware_quiescent,
            'accepted': sample_pass,
        }
        observations.append(observation)
        _append_csv(ROOT / 'logs/quiescence-samples.csv', QUIESCENCE_COLUMNS, {
            'Timestamp': observation['utc_ns'],
            'MonotonicNs': observation['monotonic_ns'],
            'Sample': sample_number, 'Consecutive': consecutive_quiescent,
            'SpanMs': observation['span_ms'], 'BootId': lock['boot_id'],
            'LockHeld': 'YES', 'BDF': expected_bdf,
            'BDFUnchanged': 'YES' if bdf_unchanged else 'NO',
            'DriverBound': 'YES' if driver_bound else 'NO',
            'Control': f'0x{control:08X}', 'Status': f'0x{status:08X}',
            'ErrorStatus': f'0x{error_status:08X}',
            'FatalClear': 'YES' if fatal_clear else 'NO',
            'NodeHoldersAllowed': 'YES' if holders_allowed else 'NO',
            'Quiescent': 'YES' if hardware_quiescent else 'NO',
            'Accepted': 'YES' if sample_pass else 'NO',
        })
        if complete:
            return True, observations
        if time.monotonic() >= deadline:
            return False, observations
        sleep_for = (QUIESCENCE_SAMPLE_INTERVAL_SECONDS -
                     (time.monotonic() - sample_started))
        if sleep_for > 0:
            time.sleep(sleep_for)


def run() -> dict:
    read_lock()
    abi_path = ROOT / 'scripts/V41_C2H_TRANSPORT_ABI_V1.json'
    require(hashlib.sha256(abi_path.read_bytes()).hexdigest().upper() == ABI_SHA256,
            'FROZEN_ABI_HASH_DRIFT')
    contract = AbiContract.load(abi_path)
    proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
    t2 = json.loads((ROOT / 'logs/t2-result.json').read_text())
    require(proof.get('result') == 'PASS', 'T1_NOT_PASS')
    require(t2.get('result') == 'PASS', 'T2_NOT_PASS')
    _write_json_exclusive(ROOT / 'logs/T3T4-start-once.json', {
        'task': TASK, 'session': 'T3T4', 'started_utc_ns': time.time_ns(),
        'primary_target': PRIMARY_TARGET, 'no_retry': True,
    })

    result = {
        'task': TASK, 'session': 'T3T4', 'result': 'BLOCKED',
        'blocker': 'R3R4R5_CAPTURE_UNFINISHED', 'primary_target': PRIMARY_TARGET,
        'raw_payload_control_ipc': False, 'parent_owned_mmio': True,
        'parent_owned_quiescence': True,
        'last_completed_operation': 'CAPTURE_START_MARKER_CREATED',
        'exception_type': None, 'exception_repr': None, 'traceback': None,
        'events': [],
    }
    mmio = None
    child = None
    messages = None
    parent_quiescent = None
    stream_enabled = False
    normal_disabled = False
    reader_result = None
    try:
        require(not _open_holders(proof['c2h']),
                'R3R4R5_C2H_READER_ALREADY_ATTACHED')
        mmio = MMIO('T3T4_PARENT')
        control = mmio.read(0x380C)
        status = mmio.read(0x3810)
        require(control == 0 and not (status & 0x100),
                'R3R4R5_DISABLED_BASELINE_NOT_CLEAN')
        pre_reset = {f'0x{offset:04X}': mmio.read(offset)
                     for offset in range(0x3800, 0x385C, 4)}
        result['pre_reset'] = pre_reset
        result['last_completed_operation'] = 'PRE_RESET_MMIO_CAPTURED'

        mmio.write(0x380C, 0x00000004, 'RESET_STREAM_STATE',
                   'DISABLED_NO_READER_NOT_RESET_BUSY')
        deadline = time.monotonic() + 5.0
        while not quiescent(mmio.read(0x380C), mmio.read(0x3810)):
            require(time.monotonic() < deadline,
                    'R3R4R5_SESSION_RESET_TIMEOUT')
            time.sleep(0.001)
        epoch = mmio.read(0x3838)
        require(epoch == ((pre_reset['0x3838'] + 1) & 0xFFFFFFFF),
                'R3R4R5_SESSION_EPOCH_TRANSITION_INVALID')
        post_reset_cause = mmio.read(0x3840)
        require(quiescent(mmio.read(0x380C), mmio.read(0x3810)),
                'R3R4R5_POST_RESET_NOT_QUIESCENT')
        normalization = combined_session_normalization(
            lambda: mmio.read(0x383C),
            lambda mask: mmio.write(
                0x383C, mask, 'SESSION_NORMALIZATION_W1C',
                'POST_RESET_QUIESCENT'),
        )
        require((normalization['post_normalization_error_status'] & 0x3F) == 0,
                'R3R4R5_POST_NORMALIZATION_ERROR_STATUS_NONZERO')
        result.update(
            post_reset_epoch=epoch,
            post_reset_error_status_before_w1c=(
                normalization['observed_error_status']),
            post_reset_last_error_cause=post_reset_cause,
            session_normalization_w1c_mask=(
                normalization['session_normalization_mask']),
            session_normalization_w1c_writes=normalization['w1c_writes'],
            post_normalization_error_status=(
                normalization['post_normalization_error_status']),
        )
        result['last_completed_operation'] = 'POST_RESET_NORMALIZATION_PASS'

        status = mmio.read(0x3810)
        require(quiescent(mmio.read(0x380C), status) and
                status & 0xC0 == 0xC0 and not (status & 0x800),
                'R3R4R5_FINAL_PRE_ENABLE_BASELINE_FAILED')
        require(mmio.read(0x3838) == epoch, 'R3R4R5_UNEXPECTED_EPOCH_CHANGE')
        baseline = mmio.snapshot('PRE_CAPTURE_BASELINE')
        result['snapshot_before'] = baseline
        result['last_completed_operation'] = 'COHERENT_BASELINE_SNAPSHOT_PASS'

        ctx = mp.get_context('spawn')
        parent_quiescent = ctx.Event()
        messages = ctx.Queue(maxsize=64)
        child = ctx.Process(
            target=reader_worker,
            args=(proof['c2h'], str(ROOT / 'private'), contract, epoch,
                  parent_quiescent, messages),
            name='r3r4r5-c2h-reader',
        )
        child.start()
        ready_deadline = time.monotonic() + 5.0
        while 'READER_READY' not in result and time.monotonic() < ready_deadline:
            _drain_messages(messages, result, wait=0.1)
            require(child.is_alive() or 'READER_READY' in result,
                    'R3R4R5_READER_EXITED_BEFORE_READY')
        require('READER_READY' in result, 'R3R4R5_READER_READY_TIMEOUT')
        mmio.write(0x380C, 0x00000001, 'ENABLE_C2H',
                   'RESET_SNAPSHOT_PASS_READER_READY')
        stream_enabled = True
        enable_time = time.monotonic()
        result['enable_monotonic_ns'] = time.monotonic_ns()
        result['last_completed_operation'] = 'STREAM_ENABLED_ONCE'

        primary_deadline = enable_time + PRIMARY_TIMEOUT_SECONDS
        while 'PRIMARY_TARGET_REACHED' not in result:
            _drain_messages(messages, result, wait=0.05)
            if 'FIRST_RECORD_VALID' in result and not \
                    result['FIRST_RECORD_VALID'].get('valid'):
                raise FailureError(
                    result['FIRST_RECORD_VALID'].get(
                        'blocker', 'R3R4R5_FIRST_RECORD_ABI_VALIDATION_FAILED'))
            if 'ERROR' in result:
                raise GateError(result['ERROR'].get('blocker',
                                                    'R3R4R5_READER_ERROR'))
            require(child.is_alive(), 'R3R4R5_READER_EXITED_BEFORE_PRIMARY_TARGET')
            require(time.monotonic() < primary_deadline,
                    'R3R4R5_PRIMARY_2500_TIMEOUT')
        require(result['PRIMARY_TARGET_REACHED'].get('first_record_durable') and
                result['PRIMARY_TARGET_REACHED'].get('checkpoint_1024') and
                result['PRIMARY_TARGET_REACHED'].get('checkpoint_2048'),
                'R3R4R5_PRIMARY_TARGET_ORDERING_PROOF_MISSING')
        mmio.write(0x380C, 0x00000000, 'NORMAL_DISABLE',
                   'PRIMARY_2500_FULLY_ASSEMBLED_AND_WRITTEN')
        normal_disabled = True
        stream_enabled = False
        result['last_completed_operation'] = 'NORMAL_STREAM_DISABLE_WRITTEN'

        quiescence_pass, observations = _parent_quiescence(
            mmio, QUIESCENCE_TIMEOUT_SECONDS, {os.getpid(), child.pid})
        result['parent_quiescence_observations'] = observations
        result['parent_hardware_quiescence'] = 'PASS' if quiescence_pass else 'FAIL'
        result['parent_quiescence_samples_passed'] = (
            observations[-1]['consecutive'] if observations else 0)
        result['parent_quiescence_sample_span_ms'] = (
            observations[-1]['span_ms'] if observations else 0.0)
        require(quiescence_pass,
                'R3R4R5_POST_DISABLE_HARDWARE_NOT_QUIESCENT')
        parent_quiescent.set()
        result['last_completed_operation'] = 'PARENT_HARDWARE_QUIESCENCE_PASS'

        reader_deadline = time.monotonic() + 5.0
        while 'READER_EXITED' not in result and time.monotonic() < reader_deadline:
            _drain_messages(messages, result, wait=0.1)
            if not child.is_alive():
                _drain_messages(messages, result, wait=0.2)
                break
        child.join(timeout=0.5)
        require(not child.is_alive(), 'R3R4R5_READER_COOPERATIVE_EXIT_TIMEOUT')
        _drain_messages(messages, result, wait=0.2)
        require('READER_QUIET' in result, 'R3R4R5_READER_QUIET_WINDOW_MISSING')
        require('READER_EXITED' in result, 'R3R4R5_READER_RESULT_MISSING')
        reader_result = result['READER_EXITED']['reader_result']
        result['reader'] = reader_result
        require(reader_result.get('result') == 'PASS',
                reader_result.get('blocker') or 'R3R4R5_READER_FAILED')
        require(reader_result.get('primary_records') == PRIMARY_TARGET,
                'R3R4R5_PRIMARY_RECORD_COUNT_INVALID')
        require(reader_result.get('drain_records', DRAIN_LIMIT + 1) <= DRAIN_LIMIT,
                'R3R4R5_DRAIN_RECORD_LIMIT_EXCEEDED')
        require(reader_result.get('incomplete_trailing_bytes') == 0,
                'R3R4R5_INCOMPLETE_TRAILING_BYTES_NONZERO')
        require('FIRST_RECORD_DURABLE' in result and
                'FIRST_RECORD_VALID' in result and
                result['FIRST_RECORD_VALID'].get('valid'),
                'R3R4R5_FIRST_RECORD_PERSISTENCE_OR_VALIDATION_MISSING')
        result['last_completed_operation'] = 'READER_QUIET_EXIT_PASS'

        final_snapshot = mmio.snapshot('POST_DISABLE_POST_DRAIN_FINAL')
        final_control = mmio.read(0x380C)
        final_status = mmio.read(0x3810)
        final_error = mmio.read(0x383C)
        final_cause = mmio.read(0x3840)
        require(quiescent(final_control, final_status),
                'R3R4R5_FINAL_STREAM_OR_DMA_NOT_QUIESCENT')
        if final_error != 0:
            raise FailureError('R3R4R5_NEW_ERROR_STATUS_DURING_FINITE_CAPTURE')
        require(final_snapshot['epoch'] == epoch,
                'R3R4R5_UNEXPECTED_EPOCH_CHANGE')
        result.update(
            snapshot_after=final_snapshot, final_control=final_control,
            final_status=final_status, final_error_status=final_error,
            final_last_error_cause=final_cause,
        )

        private = ROOT / 'private'
        validation = validate_capture(
            contract, epoch, private / 'T3T4-primary-records.bin',
            private / 'T3T4-drain-records.bin',
            private / 'T3T4-incomplete-trailing.bin',
        )
        result['validation'] = validation
        reconciliation = reconcile_counters(
            baseline, final_snapshot, validation['total_complete_records'],
            validation['last_global'], validation['last_channel'],
        )
        result['counter_reconciliation'] = reconciliation
        result['last_completed_operation'] = 'COUNTER_RECONCILIATION_PASS'

        frame = reconstruct_first_frame(
            contract, [private / 'T3T4-primary-records.bin'],
            private / 'T3T4-frame-1920x1080.uyvy',
            private / 'T3T4-frame-1920x1080.png',
            armed_epoch=epoch, card_identity=proof['bdf'],
        )
        result['frame_reconstruction'] = frame
        _replace_json(ROOT / 'logs/frame-reconstruction.json', frame)
        result.update(result='PASS', blocker='NONE',
                      last_completed_operation='COMPLETE_FRAME_RECONSTRUCTED')
    except BaseException as exc:
        result['result'] = 'FAIL' if isinstance(exc, FailureError) else 'BLOCKED'
        result['blocker'] = _nonempty_problem(exc)
        result['exception_type'] = type(exc).__name__
        result['exception_repr'] = repr(exc)
        result['traceback'] = traceback_module.format_exc()
        if mmio is not None:
            try:
                current_control = mmio.read(0x380C)
                if current_control & 1:
                    mmio.write(0x380C, 0x00000000, 'SAFETY_DISABLE',
                               'POST_ENABLE_FAILURE_CONTROL_STILL_ENABLED')
                    stream_enabled = False
                passed, observations = _parent_quiescence(
                    mmio, QUIESCENCE_TIMEOUT_SECONDS,
                    ({os.getpid()} |
                     ({child.pid} if child is not None and child.pid else set())))
                result['failure_quiescence_observations'] = observations
                result['parent_hardware_quiescence'] = 'PASS' if passed else 'FAIL'
                if passed and parent_quiescent is not None:
                    parent_quiescent.set()
            except BaseException as cleanup_exc:
                result['capture_safety_error'] = _nonempty_problem(cleanup_exc)
        if child is not None and child.is_alive():
            if messages is not None:
                try:
                    _drain_messages(messages, result, wait=0.1)
                except BaseException:
                    pass
            child.join(timeout=3.0)
        if child is not None and child.is_alive():
            result['rollback'] = 'R3R4R5_ROLLBACK_UNSAFE_ACTIVE_DMA'
        elif messages is not None:
            try:
                _drain_messages(messages, result, wait=0.2)
            except BaseException:
                pass
    finally:
        if mmio is not None:
            mmio.close()
        require(bool(str(result.get('blocker', '')).strip()),
                'R3R4R5_BLANK_BLOCKER_FORBIDDEN')
        _replace_json(ROOT / 'logs/T3T4-result.json', result)
        print(json.dumps(result, indent=2), flush=True)
    return result


if __name__ == '__main__':
    mp.freeze_support()
    outcome = run()
    raise SystemExit(0 if outcome.get('result') == 'PASS' else 1)
