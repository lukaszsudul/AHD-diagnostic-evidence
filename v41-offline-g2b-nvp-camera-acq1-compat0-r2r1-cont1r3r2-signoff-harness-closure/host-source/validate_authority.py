"""Fail-closed read-only authority gate for this exact offline checkpoint task."""

from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path


EXPECTED_SOURCE = Path(r"C:\FPGA\C1R3R1_SRC_20260916T105442Z")
EXPECTED_BRANCH = "diag/v41-g2b-nvp-camera-cont1r3r1-bram-recovery-20260916T105442Z"
EXPECTED_COMMIT = "09cd7cbb426027acaefd0cf3989579b80a451f3a"
EXPECTED_TREE = "c6be008ddc387c1f43eefa35d4fed0e2ccb968db"
EXPECTED_FINAL = (
    "C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2",
    17469233,
)
EXPECTED_REFERENCE = (
    "804CB25D89DF3729A65D2771B892738AC2D580E2921AF48CAE1C5C28D76BC208",
    62551027,
)
VIVADO = Path(r"C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat")
ROOT = Path(__file__).resolve().parents[1]
PRIOR = Path(r"C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R1_20260916T105442Z")


class AuthorityFailure(ValueError):
    pass


def require_bytes(data: bytes, expected_sha: str, expected_size: int) -> None:
    if not data or len(data) != expected_size:
        raise AuthorityFailure("missing, empty or wrong-size artifact")
    if hashlib.sha256(data).hexdigest().upper() != expected_sha:
        raise AuthorityFailure("wrong or stale artifact SHA-256")


def require_tool_version(output: str) -> None:
    if "vivado v2025.2 (64-bit)" not in output or "SW Build 6299465" not in output:
        raise AuthorityFailure("wrong or unavailable Vivado build")


def git_value(*args: str) -> str:
    result = subprocess.run(
        ["git", "--no-optional-locks", "-C", str(EXPECTED_SOURCE), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def main() -> None:
    final_original = PRIOR / "signoff" / "CONT1R3R1_SIGNED_OFF_ROUTED.dcp"
    reference_original = PRIOR / "build" / "CANDIDATE1_ROUTED_UNQUALIFIED.dcp"
    final_copy = ROOT / "inputs" / "CONT1R3R1_FINAL_PROVISIONAL_UNQUALIFIED_COPY.dcp"
    reference_copy = ROOT / "inputs" / "CONT1R3R1_ORIGINAL_ROUTED_REFERENCE_COPY.dcp"
    for path, (expected_sha, expected_size) in (
        (final_original, EXPECTED_FINAL),
        (reference_original, EXPECTED_REFERENCE),
        (final_copy, EXPECTED_FINAL),
        (reference_copy, EXPECTED_REFERENCE),
    ):
        if not path.is_file() or path.is_symlink():
            raise AuthorityFailure(f"missing or symlinked artifact: {path}")
        require_bytes(path.read_bytes(), expected_sha, expected_size)
    if not VIVADO.is_file():
        raise AuthorityFailure("qualified Vivado executable unavailable")
    result = subprocess.run([str(VIVADO), "-version"], capture_output=True, text=True)
    require_tool_version(result.stdout + result.stderr)
    if (
        git_value("rev-parse", "HEAD") != EXPECTED_COMMIT
        or git_value("rev-parse", "HEAD^{tree}") != EXPECTED_TREE
        or git_value("symbolic-ref", "--short", "HEAD") != EXPECTED_BRANCH
        or git_value("status", "--porcelain", "--untracked-files=no") != ""
    ):
        raise AuthorityFailure("source commit, tree, branch or tracked cleanliness mismatch")
    print(json.dumps({
        "result": "PASS",
        "source_commit": EXPECTED_COMMIT,
        "source_tree": EXPECTED_TREE,
        "tool": "Vivado 2025.2 SW Build 6299465",
        "final_dcp_sha256": EXPECTED_FINAL[0],
        "reference_dcp_sha256": EXPECTED_REFERENCE[0],
        "all_originals_and_copies_byte_identical_by_hash": True,
    }, indent=2))


if __name__ == "__main__":
    main()
