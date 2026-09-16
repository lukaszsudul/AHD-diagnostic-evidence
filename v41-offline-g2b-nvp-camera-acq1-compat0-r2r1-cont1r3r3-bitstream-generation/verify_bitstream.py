"""Read-only, bounded Xilinx .bit container and integrity check for CONT1R3R3.

The common .bit container uses a big-endian length-prefixed preamble, a
two-byte 0x0001 separator, a/b/c/d text fields, then e plus a four-byte
big-endian configuration payload length. This checks container integrity and
the 7-series sync word, not configuration or circuit functionality.
"""

import argparse
import datetime as dt
import hashlib
import json
import os
import stat
import struct
from pathlib import Path


EXPECTED_PART_BASE = "7a35tcsg325"
SYNC = bytes.fromhex("AA995566")


def read_exact(handle, count):
    data = handle.read(count)
    if len(data) != count:
        raise ValueError(f"truncated .bit header: expected {count} bytes")
    return data


def be16(handle):
    return struct.unpack(">H", read_exact(handle, 2))[0]


def be32(handle):
    return struct.unpack(">I", read_exact(handle, 4))[0]


def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest().upper()


def parse_bit(path):
    st = path.lstat()
    if not stat.S_ISREG(st.st_mode) or path.is_symlink() or st.st_size == 0:
        raise ValueError("bitstream must be a nonempty ordinary non-link file")

    with path.open("rb") as handle:
        preamble_length = be16(handle)
        if preamble_length != 9:
            raise ValueError(f"unexpected preamble length: {preamble_length}")
        preamble = read_exact(handle, preamble_length)
        if preamble != bytes.fromhex("0FF00FF00FF00FF000"):
            raise ValueError("unexpected Xilinx .bit preamble")
        if be16(handle) != 1:
            raise ValueError("missing .bit 0x0001 separator")

        fields = {}
        for key in (b"a", b"b", b"c", b"d"):
            if read_exact(handle, 1) != key:
                raise ValueError(f"missing or out-of-order .bit field {key!r}")
            length = be16(handle)
            if length < 2 or length > 4096:
                raise ValueError(f"invalid .bit field length for {key!r}: {length}")
            data = read_exact(handle, length)
            if data[-1] != 0:
                raise ValueError(f"field {key!r} missing NUL terminator")
            fields[key.decode("ascii")] = data[:-1].decode("ascii", errors="strict")

        if read_exact(handle, 1) != b"e":
            raise ValueError("missing .bit payload field e")
        declared_payload_length = be32(handle)
        payload_offset = handle.tell()
        actual_payload_length = st.st_size - payload_offset
        if declared_payload_length != actual_payload_length:
            raise ValueError(
                f"payload length mismatch: declared {declared_payload_length}, "
                f"actual {actual_payload_length}"
            )
        if declared_payload_length < 1024:
            raise ValueError("configuration payload implausibly short")
        payload_prefix = read_exact(handle, min(4096, declared_payload_length))
        sync_offset = payload_prefix.find(SYNC)
        if sync_offset < 0 or sync_offset % 4 != 0:
            raise ValueError("aligned 7-series configuration sync word absent")

    header_part = fields["b"].lower()
    normalized_part = header_part.removeprefix("xc").split("-", 1)[0]
    if normalized_part != EXPECTED_PART_BASE:
        raise ValueError(f".bit header part mismatch: {header_part}")

    first_hash = sha256_file(path)
    second_hash = sha256_file(path)  # Independent reopen/read of the final file.
    if first_hash != second_hash:
        raise ValueError("independent second SHA-256 read differs")

    return {
        "container_format": "Xilinx length-prefixed .bit",
        "container_header_pass": True,
        "firmware_filename": path.name,
        "firmware_size_bytes": st.st_size,
        "firmware_sha256_first_read": first_hash,
        "firmware_sha256_second_read": second_hash,
        "header_design": fields["a"],
        "header_part": fields["b"],
        "header_date": fields["c"],
        "header_time": fields["d"],
        "payload_offset_bytes": payload_offset,
        "declared_payload_length_bytes": declared_payload_length,
        "actual_payload_length_bytes": actual_payload_length,
        "config_sync_word_offset_within_payload": sync_offset,
        "source_speed_grade_from_header": "NOT_ENCODED_OR_NOT_VERIFIED",
        "verification_limit": "container, declared length, part family/package and sync only; not hardware functionality",
        "verified_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("bitstream", type=Path)
    parser.add_argument("--json-output", type=Path, required=True)
    args = parser.parse_args()
    result = parse_bit(args.bitstream)
    if args.json_output.exists():
        raise ValueError("refusing to overwrite existing validation output")
    args.json_output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
