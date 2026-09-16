"""Create the CONT1R3R3 public SHA-256 manifest from an explicit allowlist."""

import argparse
import hashlib
from pathlib import Path


FILES = (
    "V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_MAIN_REPORT.md",
    "CONT1R3R3_OWNER_AUTHORIZATION_AND_DUT_UPDATE.md",
    "CONT1R3R3_INPUT_AUTHORITY.json",
    "CONT1R3R3_BITSTREAM_RECEIPT.md",
    "CONT1R3R3_FIRMWARE_MANIFEST_PUBLIC.json",
    "CONT1R3R3_GATE_MATRIX.csv",
    "CONT1R3R3_STATE.json",
    "NEXT_HARDWARE_HANDOFF.md",
    "CONT1R3R3_GENERATION_LOG_EXCERPT.md",
    "generate_exact_dcp_bitstream.tcl",
    "launch_generation.ps1",
    "verify_bitstream.py",
    "build_public_manifest.py",
    "verify_commit_readback.py",
)
MANIFEST = "CONT1R3R3_SHA256_MANIFEST.txt"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("stage", type=Path)
    args = parser.parse_args()
    stage = args.stage
    actual = {p.name for p in stage.iterdir() if p.is_file()}
    expected = set(FILES)
    if actual != expected:
        raise ValueError(f"public allowlist mismatch: missing={expected-actual}, extra={actual-expected}")
    for path in stage.iterdir():
        if path.is_symlink() or not path.is_file():
            raise ValueError(f"nonregular public path: {path}")
    lines = []
    for name in FILES:
        data = (stage / name).read_bytes()
        if b"\x00" in data:
            raise ValueError(f"NUL/binary data in public file: {name}")
        data.decode("utf-8")
        lines.append(f"{hashlib.sha256(data).hexdigest().upper()}  {len(data)}  {name}")
    target = stage / MANIFEST
    if target.exists():
        raise ValueError("refusing to overwrite public manifest")
    target.write_bytes(("\n".join(lines) + "\n").encode("utf-8"))
    print(f"PUBLIC_MANIFEST_CREATED={target}|{len(lines)} files")


if __name__ == "__main__":
    main()
