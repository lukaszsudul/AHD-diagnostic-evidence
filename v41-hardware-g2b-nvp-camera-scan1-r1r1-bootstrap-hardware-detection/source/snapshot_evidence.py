# SANITIZED PUBLICATION COPY; executed-source SHA-256: EB5B006F97E71519B55FBA0E1754C8987C229B89FEBB476D919C3DA5AB2DFC95
"""Durable task-local snapshot persistence helpers."""

from __future__ import annotations

import hashlib
import json
import os
import struct
from pathlib import Path


def canonical_json_bytes(value: object) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode("ascii")


def durable_write(path: Path, data: bytes) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    fd = os.open(path, flags, 0o600)
    try:
        offset = 0
        while offset < len(data):
            offset += os.write(fd, data[offset:])
        os.fsync(fd)
    finally:
        os.close(fd)
    return hashlib.sha256(data).hexdigest().upper()


def persist_snapshot(prefix: Path, snapshot: dict) -> dict[str, str | int]:
    words = snapshot.pop("_raw_words")
    raw = b"".join(struct.pack("<I", word) for word in words)
    raw_path = prefix.with_suffix(".bin")
    json_path = prefix.with_suffix(".json")
    raw_sha = durable_write(raw_path, raw)
    snapshot["raw_snapshot_sha256"] = raw_sha
    snapshot["raw_snapshot_size"] = len(raw)
    json_data = canonical_json_bytes(snapshot)
    json_sha = durable_write(json_path, json_data)
    return {
        "raw_path": str(raw_path), "raw_sha256": raw_sha, "raw_size": len(raw),
        "json_path": str(json_path), "json_sha256": json_sha, "json_size": len(json_data),
    }
