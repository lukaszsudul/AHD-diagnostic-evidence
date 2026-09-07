#!/usr/bin/env python3
"""Strict stdlib-only reconstruction of a complete ABI-v1 UYVY frame."""
from __future__ import annotations

import argparse
import binascii
import hashlib
import json
import os
from pathlib import Path
import struct
import tempfile
from typing import Iterable, Iterator
import zlib

from abi_v1 import AbiContract, FrameAssembler, StreamValidator


RECORD_BYTES = 4096


class ReconstructionError(RuntimeError):
    pass


def _fsync_file(path: Path, data: bytes) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    return hashlib.sha256(data).hexdigest().upper()


def iter_record_files(paths: Iterable[Path]) -> Iterator[bytes]:
    for path in paths:
        with path.open("rb", buffering=0) as handle:
            while True:
                blob = handle.read(RECORD_BYTES)
                if not blob:
                    break
                if len(blob) != RECORD_BYTES:
                    raise ReconstructionError(
                        f"R3R4R1_FRAME_INPUT_TRAILING_BYTES:{path}:{len(blob)}"
                    )
                yield blob


def _clip(value: int) -> int:
    return 0 if value < 0 else 255 if value > 255 else value


def uyvy_to_rgb_scanlines(raw: bytes, width: int, height: int) -> Iterator[bytes]:
    expected = width * height * 2
    if len(raw) != expected:
        raise ReconstructionError(
            f"R3R4R1_UYVY_SIZE_INVALID:{len(raw)}:{expected}"
        )
    stride = width * 2
    for line in range(height):
        source = memoryview(raw)[line * stride:(line + 1) * stride]
        rgb = bytearray(width * 3)
        target = 0
        for offset in range(0, stride, 4):
            u, y0, v, y1 = source[offset:offset + 4]
            d = int(u) - 128
            e = int(v) - 128
            for y in (int(y0), int(y1)):
                c = max(0, y - 16)
                rgb[target] = _clip((298 * c + 409 * e + 128) >> 8)
                rgb[target + 1] = _clip((298 * c - 100 * d - 208 * e + 128) >> 8)
                rgb[target + 2] = _clip((298 * c + 516 * d + 128) >> 8)
                target += 3
        yield b"\x00" + bytes(rgb)


def _png_chunk(name: bytes, payload: bytes) -> bytes:
    return (struct.pack(">I", len(payload)) + name + payload +
            struct.pack(">I", binascii.crc32(name + payload) & 0xFFFFFFFF))


def write_png_from_uyvy(path: Path, raw: bytes, width: int, height: int) -> str:
    compressor = zlib.compressobj(level=6)
    compressed = bytearray()
    for scanline in uyvy_to_rgb_scanlines(raw, width, height):
        compressed.extend(compressor.compress(scanline))
    compressed.extend(compressor.flush())
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(_png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
    png.extend(_png_chunk(b"IDAT", bytes(compressed)))
    png.extend(_png_chunk(b"IEND", b""))
    return _fsync_file(path, bytes(png))


def reconstruct_first_frame(
    contract: AbiContract,
    input_paths: Iterable[Path],
    raw_output: Path,
    png_output: Path,
    *,
    armed_epoch: int,
    card_identity: str = "0000:01:00.0",
) -> dict:
    validator = StreamValidator(contract, armed_epoch=armed_epoch)
    assembler = FrameAssembler(contract, card_identity=card_identity)
    completed = None
    records_examined = 0
    for blob in iter_record_files(input_paths):
        assessment = validator.accept(blob)
        records_examined += 1
        if not assessment.structurally_valid or assessment.session_fatal:
            raise ReconstructionError(
                "R3R4R1_FRAME_RECORD_INVALID:" +
                ";".join(assessment.errors + assessment.discontinuity_reasons)
            )
        if assessment.discontinuity_reasons:
            raise ReconstructionError(
                "R3R4R1_FRAME_DISCONTINUITY:" +
                ";".join(assessment.discontinuity_reasons)
            )
        completed = assembler.push(assessment)
        if completed is not None:
            break
    if completed is None:
        raise ReconstructionError("R3R4R1_COMPLETE_FRAME_NOT_FOUND")

    expected_size = contract.pixels_per_line * contract.lines_per_frame * 2
    if len(completed.raw_uyvy) != expected_size:
        raise ReconstructionError(
            f"R3R4R1_FRAME_SIZE_INVALID:{len(completed.raw_uyvy)}:{expected_size}"
        )
    if completed.line_sequences != tuple(range(contract.lines_per_frame)):
        raise ReconstructionError("R3R4R1_FRAME_LINE_SET_INVALID")

    raw_sha = _fsync_file(raw_output, completed.raw_uyvy)
    png_sha = write_png_from_uyvy(
        png_output, completed.raw_uyvy,
        contract.pixels_per_line, contract.lines_per_frame,
    )
    _, logical, physical, epoch, frame_sequence = completed.key
    return {
        "result": "PASS",
        "records_examined": records_examined,
        "source_frame_sequence": frame_sequence,
        "reset_epoch": epoch,
        "logical_channel": logical,
        "physical_input": physical,
        "first_line": 0,
        "final_line": contract.lines_per_frame - 1,
        "width": contract.pixels_per_line,
        "height": contract.lines_per_frame,
        "pixel_format": "UYVY",
        "raw_frame_bytes": expected_size,
        "raw_frame_sha256": raw_sha,
        "viewable_image_bytes": png_output.stat().st_size,
        "viewable_image_sha256": png_sha,
        "viewable_format": "PNG_RGB8_BT601_INTEGER",
        "discarded_incomplete_frames": assembler.discarded_frames,
        "ignored_records": assembler.ignored_records,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--input", required=True, action="append", type=Path)
    parser.add_argument("--raw-output", required=True, type=Path)
    parser.add_argument("--png-output", required=True, type=Path)
    parser.add_argument("--epoch", required=True, type=lambda value: int(value, 0))
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    try:
        contract = AbiContract.load(args.abi)
        result = reconstruct_first_frame(
            contract, args.input, args.raw_output, args.png_output,
            armed_epoch=args.epoch,
        )
    except BaseException as exc:
        result = {
            "result": "FAIL",
            "blocker": str(exc) or type(exc).__name__,
            "exception_type": type(exc).__name__,
            "exception_repr": repr(exc),
        }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    print(json.dumps(result, indent=2), flush=True)
    return 0 if result.get("result") == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
