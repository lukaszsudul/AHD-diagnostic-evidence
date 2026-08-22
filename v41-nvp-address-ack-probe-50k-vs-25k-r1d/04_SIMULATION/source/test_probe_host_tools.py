#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


control = load("probe_control", ROOT / "host/v41/nvp_address_probe_control.py")
reader = load("probe_reader", ROOT / "host/v41/nvp_address_probe_read.py")


class FakeOS:
    def __init__(self):
        self.writes = []
        self.reads = []

    def pwrite(self, fd, payload, offset):
        self.writes.append((fd, payload, offset))
        return len(payload)

    def pread(self, fd, size, offset):
        self.reads.append((fd, size, offset))
        return int(offset).to_bytes(4, "little")


def main() -> int:
    fake = FakeOS()
    control.write_once(7, control.COMMANDS["START_50KHZ"], fake)
    assert len(fake.writes) == 1
    assert fake.writes[0][2] == 0x2208
    assert fake.writes[0][1] == b"\x01\x00\x00\x00"
    snap = reader.snapshot(8, fake)
    assert len(fake.reads) == len(reader.REGISTERS)
    assert snap["PROBE_MAGIC"] == 0x2200
    assert 0x2208 not in reader.REGISTERS.values()
    print("ONE_SHOT_WRITER_FIXTURE=PASS")
    print("READ_ONLY_READER_FIXTURE=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
