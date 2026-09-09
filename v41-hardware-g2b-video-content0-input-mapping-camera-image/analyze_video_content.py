#!/usr/bin/env python3
"""Offline, fixed-boundary UYVY content analysis for VIDEO-CONTENT0."""

from __future__ import annotations

import argparse
import binascii
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import struct
import zlib

from abi_v1 import AbiContract, parse_record
from frame_reconstruct_bt656_fix1 import write_png_from_uyvy


RECORD_BYTES = 4096
PRIMARY_RECORDS = 2500
WIDTH = 1920
HEIGHT = 1080
BLACK_WORD = b"\x80\x10\x80\x10"
BLACK_SHA256 = "3B189674E4CBA4542AF800037704EF3A5DABAD5ACF43285C19082AB776B246B0"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def write_bytes(path: Path, data: bytes) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    return sha256(data)


def write_json(path: Path, value: object) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fields})
        handle.flush()
        os.fsync(handle.fileno())


def percentile(hist: list[int], percentile_value: float) -> int:
    total = sum(hist)
    target = max(1, math.ceil(percentile_value * total))
    cumulative = 0
    for value, count in enumerate(hist):
        cumulative += count
        if cumulative >= target:
            return value
    return 255


def mean_variance(hist: list[int]) -> tuple[float, float]:
    count = sum(hist)
    total = sum(value * amount for value, amount in enumerate(hist))
    total_sq = sum(value * value * amount for value, amount in enumerate(hist))
    mean = total / count
    variance = max(0.0, total_sq / count - mean * mean)
    return mean, variance


def clip(value: int) -> int:
    return 0 if value < 0 else 255 if value > 255 else value


def uyvy_pixel(raw: bytes, row: int, column: int) -> tuple[int, int, int, int]:
    pair_column = column & ~1
    offset = (row * WIDTH + pair_column) * 2
    u, y0, v, y1 = raw[offset:offset + 4]
    y = y0 if column == pair_column else y1
    d = u - 128
    e = v - 128
    c = max(0, y - 16)
    red = clip((298 * c + 409 * e + 128) >> 8)
    green = clip((298 * c - 100 * d - 208 * e + 128) >> 8)
    blue = clip((298 * c + 516 * d + 128) >> 8)
    return y, red, green, blue


def png_chunk(name: bytes, payload: bytes) -> bytes:
    return (struct.pack(">I", len(payload)) + name + payload +
            struct.pack(">I", binascii.crc32(name + payload) & 0xFFFFFFFF))


def write_thumbnail(path: Path, raw: bytes, width: int = 320,
                    height: int = 180) -> str:
    scanlines = bytearray()
    for target_row in range(height):
        source_row = min(HEIGHT - 1, target_row * HEIGHT // height)
        scanlines.append(0)
        for target_column in range(width):
            source_column = min(WIDTH - 1, target_column * WIDTH // width)
            _, red, green, blue = uyvy_pixel(raw, source_row, source_column)
            scanlines.extend((red, green, blue))
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height,
                                                8, 2, 0, 0, 0)))
    png.extend(png_chunk(b"IDAT", zlib.compress(bytes(scanlines), 6)))
    png.extend(png_chunk(b"IEND", b""))
    return write_bytes(path, bytes(png))


def extract_luma(raw: bytes) -> bytearray:
    luma = bytearray(WIDTH * HEIGHT)
    target = 0
    for offset in range(0, len(raw), 4):
        luma[target] = raw[offset + 1]
        luma[target + 1] = raw[offset + 3]
        target += 2
    return luma


def analyze_frame(raw: bytes) -> tuple[dict[str, object], list[dict[str, object]],
                                       list[dict[str, object]], str]:
    if len(raw) != WIDTH * HEIGHT * 2:
        raise RuntimeError(f"FRAME_SIZE:{len(raw)}")
    black = BLACK_WORD * (WIDTH * HEIGHT // 2)
    if sha256(black) != BLACK_SHA256:
        raise RuntimeError("BLACK_REFERENCE_SHA256_MISMATCH")

    word_unique: set[int] = set()
    black_words = 0
    lane_hist = [[0] * 256 for _ in range(4)]
    for offset in range(0, len(raw), 4):
        word = raw[offset:offset + 4]
        word_unique.add(int.from_bytes(word, "little"))
        if word == BLACK_WORD:
            black_words += 1
        for lane in range(4):
            lane_hist[lane][word[lane]] += 1

    y_hist = [0] * 256
    u_hist = [0] * 256
    v_hist = [0] * 256
    pixels_different = 0
    luma = extract_luma(raw)
    for offset in range(0, len(raw), 4):
        u, y0, v, y1 = raw[offset:offset + 4]
        u_hist[u] += 1
        v_hist[v] += 1
        y_hist[y0] += 1
        y_hist[y1] += 1
        if not (u == 128 and v == 128 and y0 == 16):
            pixels_different += 1
        if not (u == 128 and v == 128 and y1 == 16):
            pixels_different += 1

    y_mean, y_variance = mean_variance(y_hist)
    u_mean, u_variance = mean_variance(u_hist)
    v_mean, v_variance = mean_variance(v_hist)
    unique_y = sum(count > 0 for count in y_hist)
    unique_u = sum(count > 0 for count in u_hist)
    unique_v = sum(count > 0 for count in v_hist)
    y_min = next(index for index, count in enumerate(y_hist) if count)
    y_max = max(index for index, count in enumerate(y_hist) if count)

    scanline_rows: list[dict[str, object]] = []
    scanline_hashes: list[str] = []
    row_means: list[float] = []
    column_sums = [0] * WIDTH
    horizontal_sum = 0
    horizontal_count = HEIGHT * (WIDTH - 1)
    vertical_sum = 0
    vertical_count = (HEIGHT - 1) * WIDTH
    identical_adjacent = 0
    longest_run = 1
    current_run = 1
    prior_hash: str | None = None
    prior_line: memoryview | None = None
    view = memoryview(luma)
    for row in range(HEIGHT):
        line = view[row * WIDTH:(row + 1) * WIDTH]
        payload_line = raw[row * WIDTH * 2:(row + 1) * WIDTH * 2]
        line_hash = sha256(payload_line)
        scanline_hashes.append(line_hash)
        if prior_hash == line_hash:
            identical_adjacent += 1
            current_run += 1
        else:
            current_run = 1
        longest_run = max(longest_run, current_run)
        prior_hash = line_hash
        row_sum = sum(line)
        row_means.append(row_sum / WIDTH)
        for column, value in enumerate(line):
            column_sums[column] += value
            if column:
                horizontal_sum += abs(value - line[column - 1])
            if prior_line is not None:
                vertical_sum += abs(value - prior_line[column])
        scanline_rows.append({"Scanline": row, "PayloadSHA256": line_hash,
                              "LumaMean": f"{row_sum / WIDTH:.9f}"})
        prior_line = line

    column_means = [value / HEIGHT for value in column_sums]
    row_mean = sum(row_means) / len(row_means)
    col_mean = sum(column_means) / len(column_means)
    row_mean_variance = sum((value - row_mean) ** 2 for value in row_means) / len(row_means)
    column_mean_variance = sum((value - col_mean) ** 2 for value in column_means) / len(column_means)

    lane_rows: list[dict[str, object]] = []
    lane_names = ("U0", "Y0", "V0", "Y1")
    for lane, histogram in enumerate(lane_hist):
        lane_mean, lane_variance = mean_variance(histogram)
        values = [index for index, count in enumerate(histogram) if count]
        for bit in range(8):
            ones = sum(count for value, count in enumerate(histogram)
                       if value & (1 << bit))
            samples = sum(histogram)
            lane_rows.append({
                "BytePositionModulo4": lane,
                "Lane": lane_names[lane],
                "Bit": bit,
                "Samples": samples,
                "ZeroCount": samples - ones,
                "OneCount": ones,
                "Varied": "YES" if 0 < ones < samples else "NO",
                "UniqueByteValues": len(values),
                "ByteMinimum": min(values),
                "ByteMaximum": max(values),
                "ByteMean": f"{lane_mean:.9f}",
                "ByteVariance": f"{lane_variance:.9f}",
            })

    black_word_fraction = black_words / (WIDTH * HEIGHT // 2)
    horizontal_energy = horizontal_sum / horizontal_count
    vertical_energy = vertical_sum / vertical_count
    nonblack_gate = (
        sha256(raw) != BLACK_SHA256 and
        black_word_fraction < 0.999 and
        pixels_different / (WIDTH * HEIGHT) >= 0.001 and
        unique_y >= 4 and y_max - y_min >= 8 and
        len(set(scanline_hashes)) >= 4 and
        horizontal_sum > 0 and vertical_sum > 0
    )
    if sha256(raw) == BLACK_SHA256 and black_word_fraction == 1.0:
        classification = "EXACT_DIGITAL_BLACK"
    elif black_word_fraction >= 0.999 or (unique_y < 4 and y_max - y_min < 8):
        classification = "NEAR_BLACK_LOW_VARIANCE"
    elif horizontal_sum > 0 and vertical_sum > 0:
        classification = "NONBLACK_SPATIALLY_VARYING"
    else:
        classification = "NONBLACK_LOW_CONTRAST"

    result: dict[str, object] = {
        "raw_frame_sha256": sha256(raw),
        "frame_bytes": len(raw),
        "black_reference_sha256": BLACK_SHA256,
        "unique_4byte_uyvy_words": len(word_unique),
        "exact_black_uyvy_words": black_words,
        "exact_black_uyvy_word_fraction": black_word_fraction,
        "exact_black_uyvy_word_percent": black_word_fraction * 100.0,
        "pixels_differing_from_digital_black": pixels_different,
        "total_pixels": WIDTH * HEIGHT,
        "pixels_y_equal_16": y_hist[16],
        "pixels_y_equal_16_percent": y_hist[16] * 100.0 / (WIDTH * HEIGHT),
        "unique_y_values": unique_y,
        "unique_u_values": unique_u,
        "unique_v_values": unique_v,
        "y_minimum": y_min,
        "y_maximum": y_max,
        "y_mean": y_mean,
        "y_standard_deviation": math.sqrt(y_variance),
        "y_percentile_1": percentile(y_hist, 0.01),
        "y_percentile_5": percentile(y_hist, 0.05),
        "y_percentile_50": percentile(y_hist, 0.50),
        "y_percentile_95": percentile(y_hist, 0.95),
        "y_percentile_99": percentile(y_hist, 0.99),
        "u_mean": u_mean,
        "u_variance": u_variance,
        "v_mean": v_mean,
        "v_variance": v_variance,
        "unique_scanline_payload_hashes": len(set(scanline_hashes)),
        "consecutive_identical_scanline_pairs": identical_adjacent,
        "longest_identical_scanline_run": longest_run,
        "horizontal_edge_energy": horizontal_energy,
        "vertical_edge_energy": vertical_energy,
        "row_mean_variance": row_mean_variance,
        "column_mean_variance": column_mean_variance,
        "horizontal_spatial_transition": horizontal_sum > 0,
        "vertical_spatial_transition": vertical_sum > 0,
        "classification": classification,
        "nonblack_pixel_content_gate": "PASS" if nonblack_gate else "FAIL",
    }

    chars = " .:-=+*#%@"
    ascii_lines: list[str] = []
    for target_row in range(45):
        row_start = target_row * HEIGHT // 45
        row_end = (target_row + 1) * HEIGHT // 45
        line_chars = []
        for target_col in range(80):
            col_start = target_col * WIDTH // 80
            col_end = (target_col + 1) * WIDTH // 80
            total = 0
            samples = 0
            for row in range(row_start, row_end):
                start = row * WIDTH + col_start
                stop = row * WIDTH + col_end
                total += sum(luma[start:stop])
                samples += stop - start
            value = total / max(1, samples)
            normalized = min(1.0, max(0.0, (value - 16.0) / 219.0))
            line_chars.append(chars[min(len(chars) - 1,
                                        int(normalized * (len(chars) - 1)))])
        ascii_lines.append("".join(line_chars))
    return result, scanline_rows, lane_rows, "\n".join(ascii_lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--primary", required=True, type=Path)
    parser.add_argument("--validation", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--report-dir", required=True, type=Path)
    args = parser.parse_args()

    contract = AbiContract.load(args.abi)
    primary = args.primary.read_bytes()
    if len(primary) != PRIMARY_RECORDS * RECORD_BYTES:
        raise RuntimeError(f"PRIMARY_SIZE:{len(primary)}")
    validation = json.loads(args.validation.read_text(encoding="utf-8"))
    if validation.get("result") != "PASS":
        raise RuntimeError("STRUCTURAL_VALIDATION_NOT_PASS")

    args.output_dir.mkdir(parents=True, exist_ok=False)
    args.report_dir.mkdir(parents=True, exist_ok=True)
    records = [parse_record(contract, primary[index * RECORD_BYTES:
                                               (index + 1) * RECORD_BYTES])
               for index in range(PRIMARY_RECORDS)]
    total_payload_bytes = sum(len(record.payload) for record in records)

    frame_groups: dict[tuple[int, int], dict[int, tuple[int, bytes, int]]] = {}
    duplicates: set[tuple[int, int]] = set()
    for index, record in enumerate(records):
        key = (record.reset_epoch, record.source_frame_sequence)
        group = frame_groups.setdefault(key, {})
        line = record.source_line_sequence
        if line in group:
            duplicates.add(key)
        else:
            group[line] = (index, record.payload, record.flags)

    complete: list[tuple[int, int, int, int, bytes]] = []
    for (epoch, sequence), lines in sorted(frame_groups.items()):
        if (epoch, sequence) in duplicates or len(lines) != HEIGHT:
            continue
        if set(lines) != set(range(HEIGHT)):
            continue
        ordered = [lines[line] for line in range(HEIGHT)]
        complete.append((epoch, sequence, ordered[0][0], ordered[-1][0],
                         b"".join(item[1] for item in ordered)))
    if not complete:
        raise RuntimeError("NO_COMPLETE_FRAME")

    frame_results: list[dict[str, object]] = []
    frame_hash_rows: list[dict[str, object]] = []
    selected = None
    for ordinal, (epoch, sequence, first, last, raw) in enumerate(complete, 1):
        prefix = f"baseline-frame-{ordinal:02d}-seq-{sequence}"
        raw_path = args.output_dir / f"{prefix}.uyvy"
        png_path = args.output_dir / f"{prefix}.png"
        thumb_path = args.output_dir / f"{prefix}-320x180.png"
        stats_path = args.output_dir / f"{prefix}-pixel-statistics.json"
        scan_path = args.output_dir / f"{prefix}-scanline-hashes.csv"
        lane_path = args.output_dir / f"{prefix}-data-lane-variation.csv"
        ascii_path = args.output_dir / f"{prefix}-luminance-80x45.txt"
        raw_sha = write_bytes(raw_path, raw)
        png_sha = write_png_from_uyvy(png_path, raw, WIDTH, HEIGHT)
        thumbnail_sha = write_thumbnail(thumb_path, raw)
        stats, scan_rows, lane_rows, ascii_text = analyze_frame(raw)
        stats.update({
            "frame_ordinal": ordinal,
            "epoch": epoch,
            "source_frame_sequence": sequence,
            "primary_record_first": first,
            "primary_record_last": last,
            "png_sha256": png_sha,
            "thumbnail_sha256": thumbnail_sha,
        })
        write_json(stats_path, stats)
        write_csv(scan_path, ["Scanline", "PayloadSHA256", "LumaMean"], scan_rows)
        write_csv(lane_path, ["BytePositionModulo4", "Lane", "Bit", "Samples",
                              "ZeroCount", "OneCount", "Varied",
                              "UniqueByteValues", "ByteMinimum", "ByteMaximum",
                              "ByteMean", "ByteVariance"], lane_rows)
        with ascii_path.open("x", encoding="ascii", newline="\n") as handle:
            handle.write(ascii_text)
            handle.flush()
            os.fsync(handle.fileno())
        result = dict(stats)
        result.update({
            "raw_path": str(raw_path),
            "png_path": str(png_path),
            "thumbnail_path": str(thumb_path),
            "statistics_path": str(stats_path),
            "scanline_hash_path": str(scan_path),
            "data_lane_variation_path": str(lane_path),
            "ascii_preview_path": str(ascii_path),
        })
        frame_results.append(result)
        frame_hash_rows.append({
            "FrameOrdinal": ordinal, "Epoch": epoch,
            "SourceFrameSequence": sequence, "PrimaryRecordFirst": first,
            "PrimaryRecordLast": last, "RawFrameSHA256": raw_sha,
            "PNG_SHA256": png_sha, "ThumbnailSHA256": thumbnail_sha,
            "Classification": stats["classification"],
            "NonblackGate": stats["nonblack_pixel_content_gate"],
        })
        if selected is None or stats["nonblack_pixel_content_gate"] == "PASS":
            selected = result
        if stats["nonblack_pixel_content_gate"] == "PASS":
            break

    output = {
        "result": "PASS",
        "primary_records": PRIMARY_RECORDS,
        "primary_bytes": len(primary),
        "total_payload_bytes": total_payload_bytes,
        "complete_frames": len(complete),
        "analyzed_frames": len(frame_results),
        "all_complete_frames": frame_results,
        "selected_frame": selected,
        "baseline_nonblack": any(
            frame["nonblack_pixel_content_gate"] == "PASS"
            for frame in frame_results),
        "black_reference_sha256": BLACK_SHA256,
    }
    write_json(args.report_dir / "content-analysis-result.json", output)
    write_csv(args.report_dir / "frame-hashes.csv",
              ["FrameOrdinal", "Epoch", "SourceFrameSequence",
               "PrimaryRecordFirst", "PrimaryRecordLast", "RawFrameSHA256",
               "PNG_SHA256", "ThumbnailSHA256", "Classification", "NonblackGate"],
              frame_hash_rows)
    print(json.dumps({
        "result": output["result"],
        "complete_frames": output["complete_frames"],
        "baseline_nonblack": output["baseline_nonblack"],
        "selected_classification": selected["classification"],
        "selected_frame_sha256": selected["raw_frame_sha256"],
    }, sort_keys=True), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
