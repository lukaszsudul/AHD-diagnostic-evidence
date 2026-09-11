#!/usr/bin/env python3
"""Generate a complete 2500-record delta-2 boundary integration fixture."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from abi_v1_r3r2 import (
    AbiContract,
    RecordMetadata,
    build_record,
    deterministic_line_payload,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--abi", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    primary = args.output_dir / "synthetic-delta2-primary.bin"
    controller = args.output_dir / "synthetic-controller-result.json"
    if primary.exists() or controller.exists():
        raise RuntimeError("R3R2_SYNTHETIC_OUTPUT_EXISTS")
    contract = AbiContract.load(args.abi)
    line = 88
    frame = 100
    capture_sequence = 1000
    with primary.open("xb") as handle:
        for index in range(2500):
            if index:
                previous_line = (line - 1) % contract.lines_per_frame
                capture_sequence += 2 if previous_line == 1079 else 1
            metadata = RecordMetadata(
                reset_epoch=7,
                source_frame_sequence=frame,
                source_line_sequence=line,
                source_capture_sequence=capture_sequence,
                channel_attempt_sequence=500 + index,
                global_stream_sequence=index,
                discontinuity=index == 0,
                slot=index % 4,
                slot_generation=index // 4 + 1,
            )
            handle.write(build_record(
                contract, metadata,
                deterministic_line_payload(contract, frame, line)))
            if line == contract.lines_per_frame - 1:
                line = 0
                frame = (frame + 1) & 0xFFFFFFFF
            else:
                line += 1
    controller.write_text(json.dumps({
        "S2": {"Epoch": 7},
        "S3": {"ErrorStatus": 0},
        "counter_deltas": {"dropped": 0, "overflow": 0},
    }, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
