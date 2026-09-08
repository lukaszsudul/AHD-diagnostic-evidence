#!/usr/bin/env python3
"""Read the already-frozen DIAG1-R1 trace twice without touching C2H state."""

import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import struct
import time


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def rd(fd, offset):
    raw = os.pread(fd, 4, offset)
    require(len(raw) == 4, "BT656_DIAG1_R1_FROZEN_TRACE_SHORT_READ")
    return struct.unpack("<I", raw)[0]


def read_pass(fd, count, pass_number, ledger):
    entries = []
    for index in range(count):
        before = time.monotonic_ns()
        written = os.pwrite(fd, struct.pack("<I", index), 0x3C38)
        after = time.monotonic_ns()
        require(written == 4, "BT656_DIAG1_R1_TRACE_INDEX_SHORT_WRITE")
        ledger.append({"pass": pass_number, "index": index,
                       "offset": "0x3C38", "value": index,
                       "purpose": "TRACE_READ_INDEX",
                       "before_monotonic_ns": before,
                       "after_monotonic_ns": after, "result": "PASS"})
        deadline = time.monotonic() + 0.100
        while True:
            state = rd(fd, 0x3C3C)
            if (state & 1) and ((state >> 1) & 0x1FF) == index:
                break
            require(time.monotonic() < deadline,
                    "BT656_DIAG1_R1_TRACE_READ_DATA_VALID_TIMEOUT")
        entries.append([rd(fd, 0x3C40 + word * 4) for word in range(16)])
    return entries


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-node", required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()
    output = Path(args.output_dir)
    output.mkdir(parents=True, exist_ok=True, mode=0o700)
    flags = os.O_RDWR | os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(args.user_node, flags)
    ledger = []
    try:
        magic = rd(fd, 0x3C00)
        version = rd(fd, 0x3C04)
        status = rd(fd, 0x3C10)
        meta = {
            "trace_magic": magic,
            "trace_version": version,
            "trace_status": status,
            "valid_entries": rd(fd, 0x3C14),
            "pretrigger_entries": rd(fd, 0x3C18),
            "posttrigger_entries": rd(fd, 0x3C1C),
            "trigger_logical_index": rd(fd, 0x3C20),
            "stop_reason": rd(fd, 0x3C24),
            "trigger_frame": rd(fd, 0x3C28),
            "trigger_line": rd(fd, 0x3C2C),
            "clocks_since_trigger": rd(fd, 0x3C30) | (rd(fd, 0x3C34) << 32),
        }
        require(magic == 0x42543635, "BT656_DIAG1_R1_TRACE_MAGIC_MISMATCH")
        require(version == 0x00010000, "BT656_DIAG1_R1_TRACE_VERSION_MISMATCH")
        require(status & 4, "BT656_DIAG1_R1_TRACE_NOT_DONE_OR_METADATA_NOT_VALID")
        require(not (status & 8), "BT656_DIAG1_R1_TRACE_OVERFLOW")
        count = meta["valid_entries"]
        require(0 < count <= 511, "BT656_DIAG1_R1_TRACE_COUNT_INVALID")
        first = read_pass(fd, count, 1, ledger)
        second = read_pass(fd, count, 2, ledger)
        require(first == second, "BT656_DIAG1_R1_TRACE_DOUBLE_READ_MISMATCH")
    finally:
        os.close(fd)

    packed = b"".join(struct.pack("<16I", *entry) for entry in first)
    trace_hash = hashlib.sha256(packed).hexdigest()
    with (output / "trace.bin").open("xb") as handle:
        handle.write(packed); handle.flush(); os.fsync(handle.fileno())
    with (output / "trace.json").open("x", encoding="utf-8") as handle:
        json.dump({"schema": "G2B_BT656_TRACE_ENTRY_V1", "metadata": meta,
                   "entries": [{"logical_index": index,
                                "words": [f"0x{word:08X}" for word in entry]}
                               for index, entry in enumerate(first)]}, handle, indent=2)
        handle.write("\n"); handle.flush(); os.fsync(handle.fileno())
    with (output / "trace.csv").open("x", encoding="utf-8", newline="") as handle:
        fields = ["logical_index"] + [f"word{i}" for i in range(16)]
        writer = csv.DictWriter(handle, fieldnames=fields); writer.writeheader()
        for index, entry in enumerate(first):
            writer.writerow({"logical_index": index,
                             **{f"word{i}": f"0x{word:08X}"
                                for i, word in enumerate(entry)}})
        handle.flush(); os.fsync(handle.fileno())
    with (output / "trace-read-index-ledger.csv").open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(ledger[0])); writer.writeheader()
        writer.writerows(ledger); handle.flush(); os.fsync(handle.fileno())
    result = {"result": "PASS", "metadata": meta,
              "trace_double_read_agreement": "PASS", "trace_overflow": 0,
              "trace_bytes": len(packed), "trace_sha256": trace_hash,
              "trace_read_index_writes": len(ledger),
              "other_mmio_writes": 0}
    with (output / "trace-readout-result.json").open("x", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2); handle.write("\n")
        handle.flush(); os.fsync(handle.fileno())
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
