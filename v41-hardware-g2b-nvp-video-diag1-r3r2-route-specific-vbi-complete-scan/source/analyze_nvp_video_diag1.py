#!/usr/bin/env python3
"""Private UYVY content analysis for one NVP VIDEO DIAG1 scan session."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import struct
import zlib


WIDTH = 1920
HEIGHT = 1080
FRAME_BYTES = WIDTH * HEIGHT * 2
BLACK_WORD = bytes((0x80, 0x10, 0x80, 0x10))
COLORS = {"RED", "GREEN", "CYAN", "WHITE_75_PERCENT"}


def clamp8(value: int) -> int:
    return 0 if value < 0 else 255 if value > 255 else value


def yuv_to_rgb(y: int, u: int, v: int) -> tuple[int, int, int]:
    c = max(0, y - 16)
    d = u - 128
    e = v - 128
    return (
        clamp8((298 * c + 409 * e + 128) >> 8),
        clamp8((298 * c - 100 * d - 208 * e + 128) >> 8),
        clamp8((298 * c + 516 * d + 128) >> 8),
    )


def variance(total: float, total_sq: float, count: int) -> float:
    if count == 0:
        return 0.0
    mean = total / count
    return max(0.0, total_sq / count - mean * mean)


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return (struct.pack(">I", len(payload)) + kind + payload +
            struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))


def write_thumbnail(path: Path, frame: bytes) -> str:
    out_width, out_height, step = 320, 180, 6
    rows = bytearray()
    view = memoryview(frame)
    for oy in range(out_height):
        y = oy * step
        rows.append(0)
        row_base = y * WIDTH * 2
        for ox in range(out_width):
            x = ox * step
            pair_base = row_base + (x // 2) * 4
            u = view[pair_base]
            yy = view[pair_base + (1 if x % 2 == 0 else 3)]
            v = view[pair_base + 2]
            rows.extend(yuv_to_rgb(yy, u, v))
    blob = (b"\x89PNG\r\n\x1a\n" +
            png_chunk(b"IHDR", struct.pack(">IIBBBBB", out_width, out_height,
                                            8, 2, 0, 0, 0)) +
            png_chunk(b"IDAT", zlib.compress(bytes(rows), level=6)) +
            png_chunk(b"IEND", b""))
    path.write_bytes(blob)
    return hashlib.sha256(blob).hexdigest().upper()


def color_matches(name: str, r: float, g: float, b: float,
                  y_mean: float) -> bool:
    if name == "RED":
        return r > g * 1.25 and r > b * 1.25 and r - max(g, b) > 20
    if name == "GREEN":
        return g > r * 1.25 and g > b * 1.25 and g - max(r, b) > 20
    if name == "CYAN":
        return g > r * 1.25 and b > r * 1.25 and min(g, b) - r > 20
    if name == "WHITE_75_PERCENT":
        return max(r, g, b) - min(r, g, b) <= 24 and y_mean >= 80
    return False


def classify(*, exact_black_fraction: float, dominant_fraction: float,
             status_class: str, assigned_color: str, color_match: bool,
             y_mean: float, y_stddev: float, unique_y: int,
             unique_scanlines: int, horizontal_energy: float,
             vertical_energy: float) -> str:
    if exact_black_fraction == 1.0:
        return "EXACT_DIGITAL_BLACK"
    if y_mean <= 22 and y_stddev <= 3.0:
        return "NEAR_BLACK_LOW_VARIANCE"
    if status_class == "NO_VIDEO_STABLE" and dominant_fraction >= 0.999:
        if color_match:
            suffix = "WHITE" if assigned_color == "WHITE_75_PERCENT" else assigned_color
            return f"UNIFORM_BGDCOL_{suffix}"
        return "UNIFORM_OTHER_COLOR"
    if (unique_y > 1 and unique_scanlines > 1 and
            (horizontal_energy > 0.5 or vertical_energy > 0.5 or y_stddev > 2.0)):
        return "NONBLACK_SPATIALLY_VARYING"
    return "NONBLACK_LOW_CONTRAST"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--frame", required=True, type=Path)
    parser.add_argument("--png", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--session-id", required=True, type=int)
    parser.add_argument("--round", required=True, type=int)
    parser.add_argument("--channel", required=True, type=int)
    parser.add_argument("--assigned-color", required=True, choices=sorted(COLORS))
    parser.add_argument("--status-class", required=True)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    frame = args.frame.read_bytes()
    if len(frame) != FRAME_BYTES:
        result = {
            "result": "FAIL", "classification": "INVALID_OR_CORRUPT",
            "blocker": f"UYVY_FRAME_SIZE_EXPECTED_{FRAME_BYTES}_GOT_{len(frame)}",
        }
        (args.output_dir / "pixel-statistics.json").write_text(
            json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, sort_keys=True), flush=True)
        return 1

    view = memoryview(frame)
    groups = len(frame) // 4
    pixels = WIDTH * HEIGHT
    exact_black_groups = 0
    word_counts: dict[int, int] = {}
    unique_y_values: set[int] = set()
    unique_u_values: set[int] = set()
    unique_v_values: set[int] = set()
    y_sum = y_sq = u_sum = u_sq = v_sum = v_sq = 0
    r_sum = g_sum = b_sum = 0

    for offset in range(0, len(frame), 4):
        u, y0, v, y1 = view[offset:offset + 4]
        word = int.from_bytes(view[offset:offset + 4], "little")
        word_counts[word] = word_counts.get(word, 0) + 1
        if u == 0x80 and y0 == 0x10 and v == 0x80 and y1 == 0x10:
            exact_black_groups += 1
        unique_u_values.add(u)
        unique_v_values.add(v)
        unique_y_values.add(y0)
        unique_y_values.add(y1)
        y_sum += y0 + y1
        y_sq += y0 * y0 + y1 * y1
        u_sum += u
        u_sq += u * u
        v_sum += v
        v_sq += v * v
        r0, g0, b0 = yuv_to_rgb(y0, u, v)
        r1, g1, b1 = yuv_to_rgb(y1, u, v)
        r_sum += r0 + r1
        g_sum += g0 + g1
        b_sum += b0 + b1

    scanline_rows: list[dict[str, object]] = []
    scanline_hashes: list[str] = []
    row_means: list[float] = []
    column_sums = [0] * WIDTH
    horizontal_total = 0
    horizontal_count = 0
    vertical_total = 0
    vertical_count = 0
    previous_y: bytearray | None = None
    for row_index in range(HEIGHT):
        raw_start = row_index * WIDTH * 2
        raw_line = frame[raw_start:raw_start + WIDTH * 2]
        digest = hashlib.sha256(raw_line).hexdigest().upper()
        scanline_hashes.append(digest)
        y_row = bytearray(WIDTH)
        for pair in range(WIDTH // 2):
            base = raw_start + pair * 4
            y_row[pair * 2] = view[base + 1]
            y_row[pair * 2 + 1] = view[base + 3]
        row_mean = sum(y_row) / WIDTH
        row_means.append(row_mean)
        for column, value in enumerate(y_row):
            column_sums[column] += value
            if column:
                horizontal_total += abs(value - y_row[column - 1])
                horizontal_count += 1
            if previous_y is not None:
                vertical_total += abs(value - previous_y[column])
                vertical_count += 1
        scanline_rows.append({
            "Row": row_index, "SHA256": digest, "YMean": round(row_mean, 6)
        })
        previous_y = y_row

    longest_run = 0
    current_run = 0
    prior_hash = None
    for digest in scanline_hashes:
        if digest == prior_hash:
            current_run += 1
        else:
            current_run = 1
            prior_hash = digest
        longest_run = max(longest_run, current_run)

    y_mean = y_sum / pixels
    y_variance = variance(y_sum, y_sq, pixels)
    u_mean = u_sum / groups
    u_variance = variance(u_sum, u_sq, groups)
    v_mean = v_sum / groups
    v_variance = variance(v_sum, v_sq, groups)
    rgb_mean = (r_sum / pixels, g_sum / pixels, b_sum / pixels)
    dominant_word, dominant_count = max(word_counts.items(), key=lambda item: item[1])
    dominant_bytes = dominant_word.to_bytes(4, "little")
    dominant_fraction = dominant_count / groups
    column_means = [value / HEIGHT for value in column_sums]
    row_mean_avg = sum(row_means) / HEIGHT
    column_mean_avg = sum(column_means) / WIDTH
    row_mean_variance = sum((value - row_mean_avg) ** 2 for value in row_means) / HEIGHT
    column_mean_variance = sum((value - column_mean_avg) ** 2
                               for value in column_means) / WIDTH
    assigned_color_match = color_matches(args.assigned_color, *rgb_mean, y_mean)
    content_class = classify(
        exact_black_fraction=exact_black_groups / groups,
        dominant_fraction=dominant_fraction,
        status_class=args.status_class,
        assigned_color=args.assigned_color,
        color_match=assigned_color_match,
        y_mean=y_mean,
        y_stddev=math.sqrt(y_variance),
        unique_y=len(unique_y_values),
        unique_scanlines=len(set(scanline_hashes)),
        horizontal_energy=horizontal_total / max(1, horizontal_count),
        vertical_energy=vertical_total / max(1, vertical_count),
    )

    thumbnail_path = args.output_dir / "thumbnail-320x180.png"
    thumbnail_sha = write_thumbnail(thumbnail_path, frame)
    png_sha = hashlib.sha256(args.png.read_bytes()).hexdigest().upper()
    result = {
        "result": "PASS" if content_class != "INVALID_OR_CORRUPT" else "FAIL",
        "session_id": args.session_id,
        "round": args.round,
        "channel": args.channel,
        "status_class": args.status_class,
        "assigned_color": args.assigned_color,
        "classification": content_class,
        "frame_sha256": hashlib.sha256(frame).hexdigest().upper(),
        "png_sha256": png_sha,
        "thumbnail_sha256": thumbnail_sha,
        "frame_bytes": len(frame),
        "geometry": "1920x1080 UYVY",
        "exact_black_fraction": exact_black_groups / groups,
        "unique_uyvy_words": len(word_counts),
        "unique_y_values": len(unique_y_values),
        "unique_u_values": len(unique_u_values),
        "unique_v_values": len(unique_v_values),
        "y_min": min(unique_y_values),
        "y_max": max(unique_y_values),
        "y_mean": y_mean,
        "y_stddev": math.sqrt(y_variance),
        "u_mean": u_mean,
        "u_variance": u_variance,
        "v_mean": v_mean,
        "v_variance": v_variance,
        "rgb_mean_r": rgb_mean[0],
        "rgb_mean_g": rgb_mean[1],
        "rgb_mean_b": rgb_mean[2],
        "unique_scanline_hashes": len(set(scanline_hashes)),
        "longest_identical_scanline_run": longest_run,
        "horizontal_edge_energy": horizontal_total / max(1, horizontal_count),
        "vertical_edge_energy": vertical_total / max(1, vertical_count),
        "row_mean_variance": row_mean_variance,
        "column_mean_variance": column_mean_variance,
        "dominant_uyvy_word_hex": dominant_bytes.hex().upper(),
        "dominant_uyvy_fraction": dominant_fraction,
        "assigned_bgcolor_pixel_match": assigned_color_match,
    }
    with (args.output_dir / "scanline-hashes.csv").open(
            "x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["Row", "SHA256", "YMean"])
        writer.writeheader()
        writer.writerows(scanline_rows)
    (args.output_dir / "pixel-statistics.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, sort_keys=True), flush=True)
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
