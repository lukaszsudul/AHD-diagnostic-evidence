"""Exclusive, durable JSON/CSV evidence helpers."""

from __future__ import annotations

import csv
import hashlib
import io
import json
import os
from pathlib import Path


def _write_new(path: Path, data: bytes) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        offset = 0
        while offset < len(data):
            offset += os.write(fd, data[offset:])
        os.fsync(fd)
    finally:
        os.close(fd)
    return hashlib.sha256(data).hexdigest().upper()


def write_json(path: Path, value: object) -> str:
    data = (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=True) + "\n").encode("ascii")
    return _write_new(path, data)


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> str:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fieldnames, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return _write_new(path, stream.getvalue().encode("ascii"))

