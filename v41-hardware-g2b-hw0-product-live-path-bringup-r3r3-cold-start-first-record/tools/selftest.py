"""Offline-only R3R3 parser, partial-read, and MMIO-policy tests."""
import hashlib
import json
import os
import pathlib
import struct
import tempfile

import capture
from abi_v1 import AbiContract, RecordMetadata, StreamValidator, build_record

original_root = capture.ROOT
contract = AbiContract.load(original_root / 'scripts/V41_C2H_TRANSPORT_ABI_V1.json')
records = [build_record(contract,
                        RecordMetadata(7, 19, index, 100 + index, index, index),
                        bytes([index + 1]) * 3840)
           for index in range(3)]
stream = b''.join(records)
pending = bytearray()
assembled = []
position = 0
for length in (1, 63, 97, 3000, 100, 4099, 4928):
    pending.extend(stream[position:position + length])
    position += length
    while len(pending) >= 4096:
        assembled.append(bytes(pending[:4096]))
        del pending[:4096]
assert position == len(stream) and not pending and assembled == records
validator = StreamValidator(contract, armed_epoch=7)
assert all(not validator.accept(record).discontinuity_reasons for record in records)
bad = bytearray(records[0])
bad[-1] = 1
assert not StreamValidator(contract, armed_epoch=7).accept(bytes(bad)).structurally_valid
assert capture.quiescent(0, 0xC4)
assert not capture.quiescent(1, 0xC4)
assert not capture.quiescent(0, 0x1C4)

temp = pathlib.Path(tempfile.mkdtemp(prefix='offline-policy-',
                                    dir=original_root / 'artifacts'))
(temp / 'logs').mkdir()
capture.ROOT = temp
actual_pwrite = os.pwrite
calls = []
os.pwrite = lambda fd, blob, offset: (calls.append(
    (offset, struct.unpack('<I', blob)[0])) or 4)
rejected = 0
try:
    mmio = capture.MMIO.__new__(capture.MMIO)
    mmio.session = 'OFFLINE'
    mmio.node = 'MOCK'
    mmio.proof = {'bdf': 'MOCK'}
    mmio.fd = -1
    mmio.last_error_read = None
    mmio._boot_guard = lambda: None
    for offset, value, purpose in (
            (0x380C, 2, 'BAD'), (0x380C, 3, 'BAD'),
            (0x383C, 7, 'BAD'), (0x383C, 0x38, 'POST_RESET_FATAL_W1C'),
            (0x3844, 0, 'BAD'), (0x0000, 1, 'BAD')):
        try:
            mmio.write(offset, value, purpose, 'POST_RESET_QUIESCENT')
        except capture.GateError:
            rejected += 1
        else:
            raise AssertionError('unauthorized write accepted')
    assert not calls
    mmio.write(0x380C, 4, 'RESET_STREAM_STATE',
               'DISABLED_NO_READER_NOT_RESET_BUSY')
    try:
        mmio.write(0x380C, 4, 'RESET_STREAM_STATE',
                   'DISABLED_NO_READER_NOT_RESET_BUSY')
    except capture.GateError:
        rejected += 1
    else:
        raise AssertionError('second reset accepted')
    mmio.last_error_read = 0x18
    mmio.write(0x383C, 0x18, 'POST_RESET_FATAL_W1C',
               'POST_RESET_QUIESCENT')
    mmio.write(0x3844, 1, 'COHERENT_SNAPSHOT', 'TEST1')
    mmio.write(0x3844, 1, 'COHERENT_SNAPSHOT', 'TEST2')
    mmio.write(0x3844, 1, 'COHERENT_SNAPSHOT', 'TEST3')
    try:
        mmio.write(0x3844, 1, 'COHERENT_SNAPSHOT', 'TEST4')
    except capture.GateError:
        rejected += 1
    else:
        raise AssertionError('fourth snapshot accepted')
    mmio.write(0x380C, 1, 'ENABLE_C2H',
               'RESET_EPOCH_SNAPSHOT_PASS_READER_READY')
    mmio.write(0x380C, 0, 'NORMAL_DISABLE',
               'FIRST_COMPLETE_4096_BYTE_RECORD_ASSEMBLED')
    mmio.write(0x380C, 0, 'SAFETY_DISABLE', 'POST_ENABLE_FAILURE')
    try:
        mmio.write(0x380C, 0, 'SAFETY_DISABLE', 'POST_ENABLE_FAILURE')
    except capture.GateError:
        rejected += 1
    else:
        raise AssertionError('second safety disable accepted')
finally:
    os.pwrite = actual_pwrite
    capture.ROOT = original_root

result = {
    'result': 'PASS',
    'hardware_access': False,
    'abi_sha256': hashlib.sha256(
        (original_root / 'scripts/V41_C2H_TRANSPORT_ABI_V1.json').read_bytes()
    ).hexdigest().upper(),
    'partial_read_reassembly': 'PASS',
    'corrupt_padding_detection': 'PASS',
    'negative_policy_cases_rejected': rejected,
    'mock_authorized_write_calls': len(calls),
}
(original_root / 'logs/offline-selftest.json').write_text(
    json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
