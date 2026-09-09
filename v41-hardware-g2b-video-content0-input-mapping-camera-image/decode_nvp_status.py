#!/usr/bin/env python3
"""Offline decoder for documented NVP6134C status bytes.

This utility does not access I2C, MMIO, XDMA, or hardware.  It decodes only
caller-supplied values whose bank/register identity is already proven.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


FORMAT_F0 = {
    0x31: "AHD_1080P25",
    0x30: "AHD_1080P30",
    0x20: "AHD_720P30",
    0x21: "AHD_720P25",
    0x22: "AHD_720P60",
    0x23: "AHD_720P50",
    0x00: "SD_480I60",
    0x10: "SD_576I50",
}


def bit(value: int, channel: int) -> bool:
    if not 0 <= channel < 4:
        raise ValueError("channel must be 0..3")
    return bool(value & (1 << channel))


def decode(values: dict[str, int], *, auto_detection_valid: bool) -> dict:
    """Decode Bank0 A8/E0/E1/E2 and optional bank(5+n) F0 values.

    Bank0 A8 bits 0..3 are NOVID (one means video loss).  E0/E1/E2 bits
    0..3 are AGC/clamp/horizontal lock.  The F0 classifier is reported only
    when its documented auto-detection prerequisite is explicitly true.
    """
    required = ("B0_A8", "B0_E0", "B0_E1", "B0_E2")
    missing = [name for name in required if name not in values]
    if missing:
        raise ValueError("missing proven register values: " + ",".join(missing))
    rows = []
    for channel in range(4):
        video_loss = bit(values["B0_A8"], channel)
        agc = bit(values["B0_E0"], channel)
        clamp = bit(values["B0_E1"], channel)
        hlock = bit(values["B0_E2"], channel)
        format_value = values.get(f"B{5 + channel}_F0")
        detected = (FORMAT_F0.get(format_value, f"UNKNOWN_0x{format_value:02X}")
                    if auto_detection_valid and format_value is not None
                    else "UNAVAILABLE_PREREQUISITE_NOT_PROVEN")
        rows.append({
            "channel": channel,
            "signal_present": not video_loss,
            "video_loss": video_loss,
            "agc_lock": agc,
            "clamp_lock": clamp,
            "horizontal_lock": hlock,
            "basic_decoder_lock": agc and clamp and hlock and not video_loss,
            "detected_standard": detected,
        })
    return {"channels": rows, "auto_detection_valid": auto_detection_valid}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path,
                        help="JSON containing proven bank/register byte values")
    parser.add_argument("--auto-detection-valid", action="store_true")
    args = parser.parse_args()
    values = json.loads(args.input.read_text(encoding="utf-8"))
    print(json.dumps(decode(values,
                            auto_detection_valid=args.auto_detection_valid),
                     indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
