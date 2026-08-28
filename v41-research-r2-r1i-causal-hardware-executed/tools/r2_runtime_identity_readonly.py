#!/usr/bin/env python3
"""Read-only C0/C1/C2/C3 runtime identity gate for frozen AHD v41 R2."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import sys


CANDIDATES = {
    "C0": {
        "name": "exact R1h",
        "commit": "c4f4bfcf577c92c3021d1fe83c05878dd12e001c",
        "bitstream_sha256": "73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41",
    },
    "C1": {
        "name": "R1i-a",
        "commit": "8b8ec0fa9c22965e46d0421c25e63d83e7971597",
        "bitstream_sha256": "847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D",
    },
    "C2": {
        "name": "R1i-b",
        "commit": "e4d10bb8e85e3797d078144fd0965e9625ee727c",
        "bitstream_sha256": "2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D",
    },
    "C3": {
        "name": "exact qualified R1i",
        "commit": "20c3323d79d3896edc586d6db1df7deee60f9e41",
        "bitstream_sha256": "F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6",
    },
}

COMMON_IDENTITY = (0xA40A0C07, 0x0000400B, 0x00031002)


def sha256_file(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def pread_word(fd: int, offset: int) -> int:
    payload = os.pread(fd, 4, offset)
    if len(payload) != 4:
        raise RuntimeError(f"short MMIO read at 0x{offset:04X}")
    return struct.unpack("<I", payload)[0]


def self_test() -> int:
    commits = [entry["commit"] for entry in CANDIDATES.values()]
    hashes = [entry["bitstream_sha256"] for entry in CANDIDATES.values()]
    assert list(CANDIDATES) == ["C0", "C1", "C2", "C3"]
    assert len(set(commits)) == 4 and all(len(value) == 40 for value in commits)
    assert len(set(hashes)) == 4 and all(len(value) == 64 for value in hashes)
    print("R2_RUNTIME_IDENTITY_HARNESS_SELFTEST=PASS")
    print("CANDIDATES_RECOGNIZED=C0,C1,C2,C3")
    print("MMIO_MODE=O_RDONLY_PREAD_ONLY")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--candidate", choices=CANDIDATES)
    parser.add_argument("--node", default="/dev/xdma0_user")
    artifact = parser.add_mutually_exclusive_group()
    artifact.add_argument("--artifact-path")
    artifact.add_argument("--artifact-sha256")
    parser.add_argument("--run-id")
    parser.add_argument("--epoch")
    parser.add_argument("--epoch-kind", choices=("cold", "warm"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        return self_test()
    required = (args.candidate, args.run_id, args.epoch, args.epoch_kind)
    if any(value is None for value in required):
        raise SystemExit("candidate, run-id, epoch, and epoch-kind are required")
    if args.artifact_path:
        artifact_sha256 = sha256_file(args.artifact_path)
    elif args.artifact_sha256:
        artifact_sha256 = args.artifact_sha256.upper()
    else:
        raise SystemExit("artifact-path or artifact-sha256 is required")

    expected = CANDIDATES[args.candidate]
    if artifact_sha256 != expected["bitstream_sha256"]:
        raise RuntimeError("frozen bitstream SHA-256 mismatch")

    flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0)
    fd = os.open(args.node, flags)
    try:
        block_id = pread_word(fd, 0x0000)
        protocol = pread_word(fd, 0x0004)
        capabilities = pread_word(fd, 0x0008)
        source_words = [pread_word(fd, offset) for offset in range(0x0010, 0x0024, 4)]
        source_commit = "".join(f"{word:08x}" for word in source_words)
        build_flags = pread_word(fd, 0x002C)
        diagnostic_magic = pread_word(fd, 0x2000)
    finally:
        os.close(fd)

    if (block_id, protocol, capabilities) != COMMON_IDENTITY:
        raise RuntimeError("common runtime identity mismatch")
    if source_commit != expected["commit"]:
        raise RuntimeError("candidate runtime source mismatch")
    if build_flags != 2:
        raise RuntimeError("candidate build flags mismatch")

    receipt = {
        "gate": "PASS",
        "candidate": args.candidate,
        "candidate_name": expected["name"],
        "run_id": args.run_id,
        "epoch": args.epoch,
        "epoch_kind": args.epoch_kind,
        "bitstream_sha256": artifact_sha256,
        "runtime_source_commit": source_commit,
        "runtime_source_words": [f"0x{word:08X}" for word in source_words],
        "runtime_identity": {
            "block_id": f"0x{block_id:08X}",
            "protocol": f"0x{protocol:08X}",
            "capabilities": f"0x{capabilities:08X}",
            "build_flags": f"0x{build_flags:08X}",
            "diagnostic_magic": f"0x{diagnostic_magic:08X}",
        },
        "mmio_access": "O_RDONLY_PREAD_ONLY",
    }
    json.dump(receipt, sys.stdout, indent=2, sort_keys=True)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
