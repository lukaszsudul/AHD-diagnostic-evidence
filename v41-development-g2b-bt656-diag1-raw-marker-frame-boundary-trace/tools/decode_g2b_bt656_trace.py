from __future__ import annotations

import argparse
import csv
import json
import struct
import sys
from pathlib import Path


ENTRY_WORDS = 16
ENTRY_BYTES = ENTRY_WORDS * 4
STATE_NAMES = {
    0: "SRC_IDLE",
    1: "SRC_CAPTURE",
    2: "SRC_WAIT_EAV",
    3: "SRC_HEADER",
    4: "SRC_COMMIT",
}


def decode_entry(raw: bytes, logical_index: int) -> dict[str, object]:
    if len(raw) != ENTRY_BYTES:
        raise ValueError(f"entry {logical_index}: expected {ENTRY_BYTES} bytes, got {len(raw)}")
    w = struct.unpack("<16I", raw)
    control = w[3]
    aux = w[15]
    marker = w[2]
    return {
        "logical_index": logical_index,
        "event_sequence": w[0],
        "source_clock_delta": w[1],
        "marker_bytes_hex": " ".join(f"{(marker >> shift) & 0xff:02X}" for shift in (0, 8, 16, 24)),
        "marker_word_hex": f"0x{marker:08X}",
        "marker_event": (control >> 0) & 1,
        "marker_valid": (control >> 1) & 1,
        "decoded_f": (control >> 2) & 1,
        "decoded_v": (control >> 3) & 1,
        "decoded_h": (control >> 4) & 1,
        "marker_xy_valid": (control >> 5) & 1,
        "malformed_increment": (control >> 6) & 1,
        "source_drop_increment": (control >> 7) & 1,
        "commit_pulse": (control >> 8) & 1,
        "trigger_pulse": (control >> 9) & 1,
        "source_ready": (control >> 10) & 1,
        "enable_applied": (control >> 11) & 1,
        "previous_sav_v": (control >> 12) & 1,
        "source_locked_before": (control >> 13) & 1,
        "source_locked_after": (control >> 14) & 1,
        "monitor_has_attempt": (control >> 15) & 1,
        "allocation_valid": (control >> 16) & 1,
        "monitor_writes_slot": (control >> 17) & 1,
        "ring_full": (control >> 18) & 1,
        "ring_empty": (control >> 19) & 1,
        "formatter_fatal": (control >> 20) & 1,
        "ownership_fatal": (control >> 21) & 1,
        "stop_on_next_frame_line1": (control >> 22) & 1,
        "stop_on_event_limit": (control >> 23) & 1,
        "stop_on_clock_timeout": (control >> 24) & 1,
        "source_state_before": STATE_NAMES.get((control >> 25) & 0x7, "RESERVED"),
        "source_state_after": STATE_NAMES.get((control >> 28) & 0x7, "RESERVED"),
        "reserved_control": (control >> 31) & 1,
        "source_frame_sequence": w[4],
        "source_line_sequence": w[5],
        "next_source_line": w[6],
        "source_capture_sequence": w[7],
        "pending_frame": w[8],
        "pending_line": w[9],
        "pending_capture": w[10],
        "pending_attempt": w[11],
        "source_lifetime_malformed_before": w[12],
        "source_lifetime_dropped_before": w[13],
        "record_or_pending_flags_hex": f"0x{w[14]:08X}",
        "payload_byte_count": aux & 0x1FFF,
        "post_payload_count": (aux >> 13) & 0x7,
        "marker_fill": (aux >> 16) & 0x7,
        "allocation_slot": (aux >> 19) & 0x3,
        "malformed_reason": (aux >> 21) & 0xF,
        "drop_reason": (aux >> 25) & 0xF,
        "reserved_aux": (aux >> 29) & 0x7,
    }


def self_test() -> None:
    words = [0] * ENTRY_WORDS
    words[0] = 17
    words[1] = 9
    words[2] = 0x9D0000FF
    words[3] = (1 << 0) | (1 << 1) | (1 << 4) | (2 << 25) | (3 << 28)
    words[5] = 1079
    words[15] = 3840 | (3 << 13) | (4 << 16) | (2 << 19) | (3 << 21) | (1 << 25)
    decoded = decode_entry(struct.pack("<16I", *words), 0)
    assert decoded["event_sequence"] == 17
    assert decoded["marker_bytes_hex"] == "FF 00 00 9D"
    assert decoded["source_state_before"] == "SRC_WAIT_EAV"
    assert decoded["source_state_after"] == "SRC_HEADER"
    assert decoded["payload_byte_count"] == 3840
    assert decoded["malformed_reason"] == 3
    assert decoded["drop_reason"] == 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Decode G2B_BT656_TRACE_ENTRY_V1 event-only records")
    parser.add_argument("trace", nargs="?", type=Path)
    parser.add_argument("--csv", dest="csv_path", type=Path)
    parser.add_argument("--json", dest="json_path", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        print("G2B_BT656_TRACE_DECODER_SELFTEST_PASS")
        return 0
    if args.trace is None or args.csv_path is None or args.json_path is None:
        parser.print_usage(sys.stderr)
        return 64
    data = args.trace.read_bytes()
    if len(data) % ENTRY_BYTES:
        raise SystemExit(f"trace size {len(data)} is not a multiple of {ENTRY_BYTES}")
    entries = [decode_entry(data[i:i + ENTRY_BYTES], i // ENTRY_BYTES) for i in range(0, len(data), ENTRY_BYTES)]
    args.csv_path.parent.mkdir(parents=True, exist_ok=True)
    with args.csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(entries[0]) if entries else ["logical_index"])
        writer.writeheader()
        writer.writerows(entries)
    args.json_path.write_text(json.dumps({"schema": "G2B_BT656_TRACE_ENTRY_V1", "entries": entries}, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
