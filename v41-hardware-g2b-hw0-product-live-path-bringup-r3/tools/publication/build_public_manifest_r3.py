from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path, PurePosixPath


PACKAGE_NAME = "v41-hardware-g2b-hw0-product-live-path-bringup-r3"
MANIFEST_NAME = "G2B_HW0_PRODUCT_R3_SHA256_MANIFEST.txt"
REQUIRED = {
    "V41_G2B_HW0_PRODUCT_R3_MAIN_REPORT.md",
    "G2B_HW0_PRODUCT_R3_AUTHORIZATION_RECEIPT.md",
    "G2B_HW0_PRODUCT_R3_AUTHORITY_VERIFICATION.md",
    "G2B_HW0_PRODUCT_R3_DUT_LOCK_RECEIPT.md",
    "G2B_HW0_PRODUCT_R3_PRELOAD_INVENTORY.md",
    "G2B_HW0_PRODUCT_R3_DRIVER_VERIFICATION.md",
    "G2B_HW0_PRODUCT_R3_DRIVER_LOAD_PROBE.md",
    "G2B_HW0_PRODUCT_R3_NODE_TO_BDF_PROOF.md",
    "G2B_HW0_PRODUCT_R3_NODE_MAP.csv",
    "G2B_HW0_PRODUCT_R3_MMIO_RAW.csv",
    "G2B_HW0_PRODUCT_R3_MMIO_DECODED.md",
    "G2B_HW0_PRODUCT_R3_NVP_VIDEO_READINESS.md",
    "G2B_HW0_PRODUCT_R3_FIRST_RECORD_REPORT.md",
    "G2B_HW0_PRODUCT_R3_FIRST_RECORD_HEADER.csv",
    "G2B_HW0_PRODUCT_R3_FINITE_CAPTURE_REPORT.md",
    "G2B_HW0_PRODUCT_R3_FINITE_CAPTURE_METRICS.csv",
    "G2B_HW0_PRODUCT_R3_FRAME_RECONSTRUCTION_REPORT.md",
    "G2B_HW0_PRODUCT_R3_CONTINUOUS_CAPTURE_REPORT.md",
    "G2B_HW0_PRODUCT_R3_CONTINUOUS_METRICS.csv",
    "G2B_HW0_PRODUCT_R3_COUNTER_RECONCILIATION.md",
    "G2B_HW0_PRODUCT_R3_PCIE_AER_KERNEL_LOG_REVIEW.md",
    "G2B_HW0_PRODUCT_R3_CLEANUP_RECEIPT.md",
    "G2B_HW0_PRODUCT_R3_FINAL_HARDWARE_STATE.md",
    "G2B_HW0_PRODUCT_R3_GATE_MATRIX.csv",
    "G2B_HW0_PRODUCT_R3_STATE.json",
    "G2B_HW0_PRODUCT_R3_EVIDENCE_INDEX.md",
    MANIFEST_NAME,
}
FORBIDDEN_SUFFIXES = {
    ".bit", ".dcp", ".ko", ".bin", ".raw", ".uyvy", ".png", ".jpg",
    ".jpeg", ".bmp", ".tiff", ".p12", ".pfx", ".pem", ".key", ".tmp",
}
FORBIDDEN_BASENAMES = {
    "Invoke-G2BR1Plink.ps1",
    "Invoke-G2BR3Plink.ps1",
    "Invoke-G2BR3Plink_proven.ps1",
}
FORBIDDEN_UNSAFE_DRAFT_NAMES = {
    "t1_exact_module_load_probe.sh",
    "publish_t1_tool_to_dut.ps1",
    "run_t1_exact_module_load_probe.ps1",
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def collect(package: Path) -> dict[str, bytes]:
    result: dict[str, bytes] = {}
    for path in sorted(package.rglob("*")):
        if path.is_symlink():
            raise SystemExit(f"SYMLINK_FORBIDDEN:{path}")
        if not path.is_file() or path.name == MANIFEST_NAME:
            continue
        rel = path.relative_to(package).as_posix()
        if PurePosixPath(rel).suffix.lower() in FORBIDDEN_SUFFIXES:
            raise SystemExit(f"FORBIDDEN_SUFFIX:{rel}")
        if path.name in FORBIDDEN_BASENAMES:
            raise SystemExit(f"CREDENTIAL_INFERENCE_SOURCE_FORBIDDEN:{rel}")
        if any(path.name.startswith(name) for name in FORBIDDEN_UNSAFE_DRAFT_NAMES):
            raise SystemExit(f"UNSAFE_T1_DRAFT_SOURCE_FORBIDDEN:{rel}")
        if rel.startswith("tools/DO_NOT_RUN/") and path.suffix.lower() not in {".md", ".txt"}:
            raise SystemExit(f"RUNNABLE_QUARANTINED_SOURCE_FORBIDDEN:{rel}")
        result[rel] = path.read_bytes()
    return result


def validate_public_content(files: dict[str, bytes]) -> None:
    forbidden = [
        re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
        re.compile(rb"(?im)^\s*(password|haslo)\s*[:=]"),
        re.compile(rb"(?i)PLINK_" + rb"PW_OPTION_USED=YES"),
    ]
    for rel, data in files.items():
        if b"\x00" in data:
            raise SystemExit(f"BINARY_PUBLIC_FILE_FORBIDDEN:{rel}")
        for pattern in forbidden:
            if pattern.search(data):
                raise SystemExit(f"CREDENTIAL_PATTERN_FORBIDDEN:{rel}:{pattern.pattern!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--allow-staging-name", action="store_true")
    args = parser.parse_args()
    package = args.package.resolve()
    valid_names = {PACKAGE_NAME}
    if args.allow_staging_name:
        valid_names.add("public-staging")
    if package.name not in valid_names or not package.is_dir():
        raise SystemExit(f"PACKAGE_PATH_INVALID:{package}")
    top = {p.name for p in package.iterdir() if p.is_file()}
    required_now = REQUIRED if args.check else REQUIRED - {MANIFEST_NAME}
    missing = sorted(required_now - top)
    if missing:
        raise SystemExit("REQUIRED_FILES_MISSING:" + ",".join(missing))
    files = collect(package)
    validate_public_content(files)
    manifest = package / MANIFEST_NAME
    expected = "".join(f"{digest(data)}  {rel}\n" for rel, data in files.items()).encode("utf-8")
    if args.check:
        if not manifest.is_file() or manifest.read_bytes() != expected:
            raise SystemExit("MANIFEST_CHECK_FAILED")
    else:
        if manifest.exists():
            raise SystemExit("MANIFEST_ALREADY_EXISTS")
        manifest.write_bytes(expected)
    print(f"PUBLIC_PACKAGE_RESULT=PASS")
    print(f"PUBLIC_PACKAGE_FILE_COUNT={len(files) + 1}")
    print(f"PUBLIC_MANIFEST_ENTRY_COUNT={len(files)}")
    print(f"PUBLIC_MANIFEST_SHA256={digest(expected)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
