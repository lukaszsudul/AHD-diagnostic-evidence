#!/usr/bin/env python3
"""One authorized failure-evidence snapshot before terminal cleanup reboot."""
import csv
import json
import os
from pathlib import Path
import struct
import time

ROOT = Path("/home/<GOVERNED_USER_REDACTED>/vcde_artifacts/g2b_hw0_product_r3r4r6r2r2/20260908T081532Z")
NODE = "/dev/xdma0_user"
OFFSETS = {
    "attempted": 0x3814, "committed": 0x3818, "streamed": 0x381C,
    "dropped": 0x3820, "overflow": 0x3824, "discontinuity": 0x3828,
    "beats_low": 0x382C, "beats_high": 0x3830, "last_global": 0x3834,
    "epoch": 0x3838, "error": 0x383C, "cause": 0x3840,
    "snapshot_status": 0x3848, "generation": 0x384C,
    "abandoned": 0x3850, "last_attempt": 0x3858,
}

flags = os.O_RDWR | os.O_CLOEXEC
if hasattr(os, "O_NOFOLLOW"):
    flags |= os.O_NOFOLLOW
fd = os.open(NODE, flags)

def read(offset):
    raw = os.pread(fd, 4, offset)
    if len(raw) != 4:
        raise RuntimeError("R3R4R6R2R2_FAILURE_SNAPSHOT_SHORT_READ")
    return struct.unpack("<I", raw)[0]

try:
    control = read(0x380C)
    status = read(0x3810)
    if control != 0:
        raise RuntimeError("R3R4R6R2R2_FAILURE_SNAPSHOT_STREAM_NOT_DISABLED")
    generation = read(0x384C)
    expected = (generation + 1) & 0xFFFFFFFF
    stamp = time.time_ns()
    ledger = ROOT / "logs/mmio-write-ledger.csv"
    with ledger.open("a", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow([stamp, "WRITE", "0x3844", "0x00000001",
                         "COHERENT_SNAPSHOT", "FAILURE_EVIDENCE", "YES", "INTENT", ""])
        handle.flush(); os.fsync(handle.fileno())
        if os.pwrite(fd, struct.pack("<I", 1), 0x3844) != 4:
            raise RuntimeError("R3R4R6R2R2_FAILURE_SNAPSHOT_SHORT_WRITE")
        writer.writerow([stamp, "WRITE", "0x3844", "0x00000001",
                         "COHERENT_SNAPSHOT", "FAILURE_EVIDENCE", "YES", "PASS",
                         time.monotonic_ns()])
        handle.flush(); os.fsync(handle.fileno())
    deadline = time.monotonic() + 2.0
    while True:
        if (read(0x3848) & 3) == 2 and read(0x384C) == expected:
            break
        if time.monotonic() >= deadline:
            raise RuntimeError("R3R4R6R2R2_FAILURE_SNAPSHOT_TIMEOUT")
        time.sleep(0.001)
    values = {name: read(offset) for name, offset in OFFSETS.items()}
    values["beats"] = values["beats_low"] | (values["beats_high"] << 32)
    result = {"result": "PASS", "checkpoint": "FAILURE_PRE_TERMINAL_REBOOT",
              "control": control, "status": status, "values": values,
              "timestamp": time.time_ns()}
    path = ROOT / "logs/failure-snapshot.json"
    with path.open("x", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2); handle.write("\n")
        handle.flush(); os.fsync(handle.fileno())
    print(json.dumps(result, sort_keys=True))
finally:
    os.close(fd)
