"""R3R3 one-record capture with exact MMIO budgets and bounded safe drain."""
import csv
import hashlib
import json
import multiprocessing as mp
import os
import pathlib
import queue
import signal
import stat
import struct
import sys
import time

from abi_v1 import AbiContract, StreamValidator

P = pathlib.Path
ROOT = P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z')
LOCK = P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock/receipt.json')
ABI_SHA256 = 'AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6'
LEDGER_COLUMNS = ['Timestamp', 'Session', 'Node', 'BDF', 'Offset', 'Value',
                  'Purpose', 'Authorized', 'Precondition', 'Result']


class GateError(Exception):
    pass


class ReadDeadline(Exception):
    pass


def require(condition, message):
    if not condition:
        raise GateError(message)


def save_json(name, value):
    path = ROOT / 'logs' / name
    path.write_text(json.dumps(value, indent=2) + '\n')


def read_lock():
    require(LOCK.is_file(), 'POST_REBOOT_LINUX_LOCK_REQUIRED')
    lock = json.loads(LOCK.read_text())
    require(lock.get('task') == 'G2B-HW0-PRODUCT-R3R3', 'LINUX_LOCK_OWNER_MISMATCH')
    require(lock.get('phase') == 'POST_REBOOT' and lock.get('state') == 'HELD',
            'POST_REBOOT_LINUX_LOCK_NOT_HELD')
    require(P('/proc/sys/kernel/random/boot_id').read_text().strip() == lock['boot'],
            'UNEXPECTED_BOOT_TRANSITION_DURING_R3R3')
    return lock


def quiescent(control, status):
    # CONTROL disabled; reset not busy; C2H inactive; ring empty; ring not full.
    return control == 0 and status & 0x10F == 0x004


class MMIO:
    def __init__(self, session='T3'):
        self.session = session
        read_lock()
        self.proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
        require(self.proof.get('result') == 'PASS', 'NODE_TO_BDF_PROOF_REQUIRED')
        self.node = self.proof['user']
        st = os.stat(self.node)
        require(stat.S_ISCHR(st.st_mode), 'USER_NODE_NOT_CHAR_DEVICE')
        dev_path = (P('/sys/dev/char') /
                    f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}' / 'device').resolve()
        require(self.proof['bdf'] in str(dev_path), 'USER_NODE_BDF_PROOF_CHANGED')
        self.fd = os.open(self.node, os.O_RDWR | os.O_NOFOLLOW)
        self.last_error_read = None

    def close(self):
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def _boot_guard(self):
        read_lock()

    def read(self, offset):
        self._boot_guard()
        require(offset % 4 == 0 and
                (0 <= offset <= 0x30 or 0x80 <= offset <= 0xB4 or
                 0x3800 <= offset <= 0x3858), 'MMIO_READ_ALLOWLIST_VIOLATION')
        raw = os.pread(self.fd, 4, offset)
        require(len(raw) == 4, 'SHORT_MMIO_READ')
        value = struct.unpack('<I', raw)[0]
        if offset == 0x383C:
            self.last_error_read = value
        path = ROOT / 'logs/mmio-raw.csv'
        with path.open('a', newline='') as handle:
            writer = csv.writer(handle)
            writer.writerow([time.time_ns(), self.session, self.node,
                             self.proof['bdf'], f'0x{offset:04X}',
                             f'0x{value:08X}'])
            handle.flush()
            os.fsync(handle.fileno())
        return value

    def write(self, offset, value, purpose, precondition):
        self._boot_guard()
        ledger = ROOT / 'logs/mmio-write-ledger.csv'
        rows = list(csv.DictReader(ledger.open())) if ledger.exists() else []
        attempts = [row for row in rows if row['Result'] == 'INTENT']
        reset_count = sum(row['Offset'] == '0x380C' and row['Value'] == '0x00000004'
                          for row in attempts)
        enable_count = sum(row['Offset'] == '0x380C' and row['Value'] == '0x00000001'
                           for row in attempts)
        normal_disable_count = sum(row['Purpose'] == 'NORMAL_DISABLE' for row in attempts)
        safety_disable_count = sum(row['Purpose'] == 'SAFETY_DISABLE' for row in attempts)
        snapshot_count = sum(row['Offset'] == '0x3844' for row in attempts)
        w1c_count = sum(row['Offset'] == '0x383C' for row in attempts)

        if offset == 0x380C and value == 4:
            require(purpose == 'RESET_STREAM_STATE' and reset_count == 0,
                    'RESET_STREAM_STATE_BUDGET_EXCEEDED')
        elif offset == 0x380C and value == 1:
            require(purpose == 'ENABLE_C2H' and enable_count == 0,
                    'STREAM_ENABLE_BUDGET_EXCEEDED')
        elif offset == 0x380C and value == 0:
            if purpose == 'NORMAL_DISABLE':
                require(normal_disable_count == 0, 'NORMAL_DISABLE_BUDGET_EXCEEDED')
            elif purpose == 'SAFETY_DISABLE':
                require(enable_count == 1 and safety_disable_count == 0,
                        'SAFETY_DISABLE_BUDGET_OR_PRECONDITION')
            else:
                raise GateError('DISABLE_PURPOSE_INVALID')
        elif offset == 0x3844 and value == 1:
            require(purpose == 'COHERENT_SNAPSHOT' and snapshot_count < 3,
                    'SNAPSHOT_WRITE_BUDGET_EXCEEDED')
        elif offset == 0x383C and value in (8, 16, 24, 32, 40, 48, 56):
            require(purpose == 'POST_RESET_FATAL_W1C' and w1c_count == 0,
                    'FATAL_W1C_BUDGET_EXCEEDED')
            require(self.last_error_read is not None and
                    value == (self.last_error_read & 0x38), 'FATAL_W1C_MASK_MISMATCH')
            require(precondition == 'POST_RESET_QUIESCENT', 'FATAL_W1C_PRECONDITION')
        else:
            raise GateError('R3R3_MMIO_WRITE_ALLOWLIST_VIOLATION')

        row = [time.time_ns(), self.session, self.node, self.proof['bdf'],
               f'0x{offset:04X}', f'0x{value:08X}', purpose, 'YES',
               precondition, 'INTENT']
        fresh = not ledger.exists()
        with ledger.open('a', newline='') as handle:
            writer = csv.writer(handle)
            if fresh:
                writer.writerow(LEDGER_COLUMNS)
            writer.writerow(row)
            handle.flush()
            os.fsync(handle.fileno())
        count = os.pwrite(self.fd, struct.pack('<I', value), offset)
        require(count == 4, 'SHORT_MMIO_WRITE')
        completion = ROOT / 'logs/write-completions.jsonl'
        with completion.open('a') as handle:
            handle.write(json.dumps({'timestamp': time.time_ns(),
                                     'session': self.session,
                                     'offset': offset, 'value': value,
                                     'purpose': purpose, 'bytes': count,
                                     'result': 'PASS'}) + '\n')
            handle.flush()
            os.fsync(handle.fileno())

    def snapshot(self, label):
        epoch = self.read(0x3838)
        generation = self.read(0x384C)
        require(not (self.read(0x3810) & 0x300), 'SNAPSHOT_OR_RESET_BUSY')
        self.write(0x3844, 1, 'COHERENT_SNAPSHOT', label)
        deadline = time.monotonic() + 2.0
        while self.read(0x3848) & 3 != 2:
            require(time.monotonic() < deadline, 'COHERENT_SNAPSHOT_TIMEOUT')
            time.sleep(0.001)
        values = {f'0x{offset:04X}': self.read(offset)
                  for offset in list(range(0x3814, 0x3838, 4)) +
                  [0x3850, 0x3854, 0x3858]}
        require(self.read(0x3838) == epoch, 'SNAPSHOT_EPOCH_CHANGED')
        require(self.read(0x384C) == ((generation + 1) & 0xFFFFFFFF),
                'SNAPSHOT_GENERATION_INVALID')
        require(self.read(0x3848) & 3 == 2, 'SNAPSHOT_VALID_LOST')
        values.update(epoch=epoch, generation=(generation + 1) & 0xFFFFFFFF,
                      label=label)
        return values


def alarm_handler(*_):
    raise ReadDeadline()


def reader_worker(c2h_node, ready, disabled, stop, messages):
    fd = -1
    mmio = None
    pending = bytearray()
    complete = 0
    result = {'result': 'BLOCKED', 'complete_records': 0,
              'primary_records': 0, 'drain_records': 0,
              'trailing_bytes': 0, 'quiescent': False}
    try:
        read_lock()
        proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
        require(proof['c2h'] == c2h_node, 'C2H_SELECTION_CHANGED')
        st = os.stat(c2h_node)
        require(stat.S_ISCHR(st.st_mode), 'C2H_NODE_NOT_CHAR_DEVICE')
        dev_path = (P('/sys/dev/char') /
                    f'{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}' / 'device').resolve()
        require(proof['bdf'] in str(dev_path), 'C2H_NODE_BDF_PROOF_CHANGED')
        fd = os.open(c2h_node, os.O_RDONLY | os.O_NOFOLLOW)
        mmio = MMIO('T3_READER')
        ready_receipt = {'ready': True, 'pid': os.getpid(), 'node': c2h_node,
                         'utc_ns': time.time_ns()}
        save_json('T3-reader-ready.json', ready_receipt)
        ready.set()
        signal.signal(signal.SIGALRM, alarm_handler)
        signal.siginterrupt(signal.SIGALRM, True)
        drain_deadline = None
        while True:
            if disabled.is_set() and drain_deadline is None:
                drain_deadline = time.monotonic() + 10.0
            if disabled.is_set():
                control = mmio.read(0x380C)
                status = mmio.read(0x3810)
                if quiescent(control, status):
                    result['quiescent'] = True
                    break
                require(time.monotonic() < drain_deadline, 'BOUNDED_DRAIN_TIMEOUT')
                require(max(0, complete - 1) <= 64, 'DRAIN_RECORD_LIMIT_EXCEEDED')
            if stop.is_set() and not disabled.is_set():
                time.sleep(0.001)
                continue
            requested = max(1, 4096 - len(pending))
            timeout = 0.5
            if drain_deadline is not None:
                timeout = min(timeout, max(0.001, drain_deadline - time.monotonic()))
            signal.setitimer(signal.ITIMER_REAL, timeout)
            try:
                chunk = os.read(fd, requested)
            except ReadDeadline:
                continue
            finally:
                signal.setitimer(signal.ITIMER_REAL, 0)
            require(chunk, 'EMPTY_C2H_READ')
            pending.extend(chunk)
            while len(pending) >= 4096:
                blob = bytes(pending[:4096])
                del pending[:4096]
                complete += 1
                messages.put(('record', time.monotonic(), blob), timeout=0.2)
                require(max(0, complete - 1) <= 64, 'DRAIN_RECORD_LIMIT_EXCEEDED')
        result.update(result='PASS', complete_records=complete,
                      primary_records=min(1, complete),
                      drain_records=max(0, complete - 1),
                      trailing_bytes=len(pending))
    except BaseException as exc:
        result['blocker'] = str(exc)
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        if pending:
            (ROOT / 'artifacts/T3-trailing-incomplete.bin').write_bytes(bytes(pending))
        else:
            (ROOT / 'artifacts/T3-trailing-incomplete.bin').write_bytes(b'')
        if fd >= 0:
            os.close(fd)
        if mmio is not None:
            mmio.close()
        result['complete_records'] = complete
        result['primary_records'] = min(1, complete)
        result['drain_records'] = max(0, complete - 1)
        result['trailing_bytes'] = len(pending)
        save_json('T3-reader-result.json', result)
        messages.put(('done', time.monotonic(), result), timeout=0.2)


def run():
    read_lock()
    require(json.loads((ROOT / 'logs/t2-result.json').read_text())['result'] == 'PASS',
            'T2_NOT_PASS')
    start_once = ROOT / 'logs/T3-start-once.json'
    with start_once.open('x') as handle:
        json.dump({'task': 'G2B-HW0-PRODUCT-R3R3', 'session': 'T3',
                   'started_ns': time.time_ns()}, handle)
    abi_path = ROOT / 'scripts/V41_C2H_TRANSPORT_ABI_V1.json'
    require(hashlib.sha256(abi_path.read_bytes()).hexdigest().upper() == ABI_SHA256,
            'FROZEN_ABI_HASH_DRIFT')
    contract = AbiContract.load(abi_path)
    proof = json.loads((ROOT / 'logs/t1-proof.json').read_text())
    result = {'task': 'G2B-HW0-PRODUCT-R3R3', 'session': 'T3',
              'result': 'BLOCKED', 'host_complete_records': 0,
              'direct_tkeep_tlast_hardware_observation': 'NOT_PERFORMED'}
    mmio = MMIO('T3')
    child = None
    stop = None
    disabled = None
    records = []
    reader_result = None
    try:
        # Step A: exact disabled baseline with no existing C2H reader.
        for proc in P('/proc').iterdir():
            if not proc.name.isdigit():
                continue
            try:
                for desc in (proc / 'fd').iterdir():
                    try:
                        require(os.readlink(desc) != proof['c2h'],
                                'C2H_READER_ALREADY_ATTACHED')
                    except FileNotFoundError:
                        pass
            except (FileNotFoundError, PermissionError):
                pass
        control = mmio.read(0x380C)
        status = mmio.read(0x3810)
        require(control == 0 and not (status & 0x100),
                'DISABLED_BASELINE_NOT_CLEAN')
        pre = {'control': control, 'status': status,
               'epoch': mmio.read(0x3838),
               'error_status': mmio.read(0x383C),
               'last_error_cause': mmio.read(0x3840)}
        result['pre_reset'] = pre

        # Steps B/C: exactly one reset and exact epoch transition.
        mmio.write(0x380C, 4, 'RESET_STREAM_STATE',
                   'DISABLED_NO_READER_NOT_RESET_BUSY')
        deadline = time.monotonic() + 5.0
        while not quiescent(mmio.read(0x380C), mmio.read(0x3810)):
            require(time.monotonic() < deadline, 'R3R3_SESSION_RESET_TIMEOUT')
            time.sleep(0.001)
        epoch = mmio.read(0x3838)
        require(epoch == ((pre['epoch'] + 1) & 0xFFFFFFFF),
                'R3R3_SESSION_EPOCH_TRANSITION_INVALID')
        result['post_reset_epoch'] = epoch

        # Step D: conditional fatal-only W1C.
        error_status = mmio.read(0x383C)
        fatal_mask = error_status & 0x38
        result['post_reset_error_status'] = error_status
        result['fatal_w1c_mask'] = fatal_mask
        result['fatal_w1c_written'] = None
        if fatal_mask:
            require(quiescent(mmio.read(0x380C), mmio.read(0x3810)),
                    'POST_RESET_NOT_QUIESCENT')
            error_status = mmio.read(0x383C)
            fatal_mask = error_status & 0x38
            if fatal_mask:
                mmio.write(0x383C, fatal_mask, 'POST_RESET_FATAL_W1C',
                           'POST_RESET_QUIESCENT')
                result['fatal_w1c_written'] = fatal_mask
            error_status = mmio.read(0x383C)
            require(not (error_status & 0x38),
                    'POST_RESET_FATAL_W1C_DID_NOT_CLEAR')
        require(not (error_status & 0x7),
                'NONCLEAN_NONFATAL_ERROR_STATUS_AFTER_RESET')

        # Step E: coherent baseline snapshot.
        status = mmio.read(0x3810)
        require(quiescent(mmio.read(0x380C), status) and
                status & 0xC0 == 0xC0 and not (status & 0x800),
                'FINAL_PRE_ENABLE_BASELINE_FAILED')
        require(mmio.read(0x3838) == epoch, 'UNEXPECTED_EPOCH_CHANGE')
        baseline = mmio.snapshot('PRE_CAPTURE')
        result['snapshot_before'] = baseline

        # Steps F/G: attach one reader, then enable once.
        ctx = mp.get_context('spawn')
        ready = ctx.Event()
        disabled = ctx.Event()
        stop = ctx.Event()
        messages = ctx.Queue(maxsize=72)
        child = ctx.Process(target=reader_worker,
                            args=(proof['c2h'], ready, disabled, stop, messages))
        child.start()
        require(ready.wait(5.0), 'READER_READY_TIMEOUT')
        mmio.write(0x380C, 1, 'ENABLE_C2H',
                   'RESET_EPOCH_SNAPSHOT_PASS_READER_READY')
        enable_time = time.monotonic()
        result['enable_monotonic'] = enable_time

        # First complete record must arrive within ten seconds.
        first_deadline = enable_time + 10.0
        first_received = False
        while not first_received and time.monotonic() < first_deadline:
            timeout = min(0.25, max(0.001, first_deadline - time.monotonic()))
            try:
                kind, timestamp, payload = messages.get(timeout=timeout)
            except queue.Empty:
                require(child.is_alive(), 'C2H_READER_EXITED_BEFORE_FIRST_RECORD')
                continue
            if kind == 'record':
                records.append(payload)
                first_received = True
                result['first_record_receive_monotonic'] = timestamp
            elif kind == 'done':
                reader_result = payload
                break

        if first_received:
            mmio.write(0x380C, 0, 'NORMAL_DISABLE',
                       'FIRST_COMPLETE_4096_BYTE_RECORD_ASSEMBLED')
        else:
            if mmio.read(0x380C) & 1:
                mmio.write(0x380C, 0, 'SAFETY_DISABLE',
                           'FIRST_RECORD_TIMEOUT_AFTER_ENABLE')
            result['blocker'] = 'FIRST_LIVE_C2H_RECORD_TIMEOUT'
            stop.set()
        disabled.set()

        # Bounded drain: at most ten seconds and at most 64 accepted records.
        drain_deadline = time.monotonic() + 11.0
        while reader_result is None and time.monotonic() < drain_deadline:
            try:
                kind, _, payload = messages.get(timeout=0.25)
            except queue.Empty:
                if not child.is_alive():
                    break
                continue
            if kind == 'record':
                records.append(payload)
                require(max(0, len(records) - 1) <= 64,
                        'DRAIN_RECORD_LIMIT_EXCEEDED')
            elif kind == 'done':
                reader_result = payload
        child.join(1.0)
        require(not child.is_alive(), 'R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA')
        require(reader_result is not None, 'READER_RESULT_MISSING')
        result['reader'] = reader_result
        require(reader_result.get('quiescent'), 'R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA')
        require(reader_result.get('result') == 'PASS',
                reader_result.get('blocker', 'READER_FAILED'))

        raw_path = ROOT / 'artifacts/T3-complete-records.bin'
        raw_path.write_bytes(b''.join(records))
        with raw_path.open('rb') as handle:
            os.fsync(handle.fileno())
        result['host_complete_records'] = len(records)
        result['primary_records'] = 1 if records else 0
        result['drain_records'] = max(0, len(records) - 1)
        result['incomplete_trailing_bytes'] = reader_result['trailing_bytes']

        if not first_received:
            raise GateError('FIRST_LIVE_C2H_RECORD_TIMEOUT')

        # First record and all drain records are structurally checked.
        validator = StreamValidator(contract, armed_epoch=epoch)
        assessments = [validator.accept(blob) for blob in records]
        errors = []
        for assessment in assessments:
            if not assessment.structurally_valid or assessment.session_fatal:
                errors.extend(assessment.errors)
            errors.extend(assessment.discontinuity_reasons)
        require(not errors, 'FIRST_RECORD_ABI_VALIDATION_FAILED:' + ';'.join(errors[:6]))
        first = assessments[0].record
        require(first is not None, 'FIRST_RECORD_PARSE_MISSING')
        require(first.reset_epoch == epoch, 'FIRST_RECORD_STALE_EPOCH')
        require(first.logical_channel_id == 0 and first.physical_input_id == 0 and
                first.value('active_logical_channel_count') == 1,
                'FIRST_RECORD_CHANNEL_MAPPING_INVALID')
        first_blob = records[0]
        first_payload = first_blob[64:3904]
        (ROOT / 'artifacts/T3-first-record.bin').write_bytes(first_blob)
        (ROOT / 'artifacts/T3-first-payload.bin').write_bytes(first_payload)
        result.update(
            first_record_bytes=len(first_blob),
            first_record_sha256=hashlib.sha256(first_blob).hexdigest().upper(),
            first_payload_sha256=hashlib.sha256(first_payload).hexdigest().upper(),
            first_header=dict(first.header),
            first_payload_prefix_hex=first_payload[:32].hex().upper(),
            first_payload_suffix_hex=first_payload[-32:].hex().upper(),
            padding_zero=not any(first_blob[3904:4096]),
            host_observed_record_boundary='PASS')

        # Final coherent snapshot and exact counter reconciliation.
        after = mmio.snapshot('POST_DISABLE_DRAIN')
        control = mmio.read(0x380C)
        status = mmio.read(0x3810)
        final_error = mmio.read(0x383C)
        require(quiescent(control, status), 'FINAL_STREAM_OR_DMA_NOT_QUIESCENT')
        require(final_error == 0, 'FINAL_ERROR_STATUS_NONZERO')
        require(after['epoch'] == epoch, 'UNEXPECTED_EPOCH_CHANGE')
        deltas = {key: (after[key] - baseline[key]) & 0xFFFFFFFF
                  for key in baseline if key.startswith('0x')}
        beats = ((((after['0x3830'] << 32) | after['0x382C']) -
                  ((baseline['0x3830'] << 32) | baseline['0x382C'])) &
                 0xFFFFFFFFFFFFFFFF)
        count = len(records)
        require(deltas['0x381C'] == count, 'FIRST_RECORD_COUNTER_RECONCILIATION_MISMATCH')
        require(beats == count * 512, 'FIRST_RECORD_COUNTER_RECONCILIATION_MISMATCH')
        require(deltas['0x3814'] == count and deltas['0x3818'] == count,
                'SOURCE_COUNTER_RECONCILIATION_MISMATCH')
        require(all(deltas[key] == 0 for key in
                    ('0x3820', '0x3824', '0x3828', '0x3850', '0x3854')),
                'CAPTURE_ERROR_COUNTER_NONZERO')
        result.update(snapshot_after=after, counter_deltas=deltas,
                      records_streamed_delta=deltas['0x381C'],
                      beats_streamed_delta=beats,
                      expected_beats=count * 512,
                      final_control=control, final_status=status,
                      final_error_status=final_error,
                      counter_reconciliation='PASS', result='PASS')
    except BaseException as exc:
        if 'blocker' not in result:
            result['blocker'] = str(exc)
        if stop is not None:
            stop.set()
        try:
            if mmio.read(0x380C) & 1:
                mmio.write(0x380C, 0, 'SAFETY_DISABLE',
                           'POST_ENABLE_FAILURE_CLEANUP')
            if disabled is not None:
                disabled.set()
        except BaseException as cleanup_exc:
            result['cleanup_error'] = str(cleanup_exc)
        if child is not None and child.is_alive():
            child.join(10.5)
        if child is not None and child.is_alive():
            result['rollback'] = 'R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA'
    finally:
        mmio.close()
        save_json('T3-result.json', result)
        print(json.dumps(result, indent=2), flush=True)
    return result


if __name__ == '__main__':
    mp.freeze_support()
    outcome = run()
    sys.exit(0 if outcome.get('result') == 'PASS' else 1)
