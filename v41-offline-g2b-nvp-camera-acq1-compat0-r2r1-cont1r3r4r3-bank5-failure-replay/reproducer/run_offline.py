"""Re-run only frozen-RTL offline simulations and private-record checks.

Requires an exact git-archive source copy, the private sealed input and the
Vivado 2025.2 simulator. It contains no DUT transport or hardware operation.
"""

from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from pathlib import Path


COMMIT = "09cd7cbb426027acaefd0cf3989579b80a451f3a"
TREE = "c6be008ddc387c1f43eefa35d4fed0e2ccb968db"
BITS = (
    "rtl/g2b/g2b_nvp_camera_scan1_manifest_pkg.sv",
    "rtl/g2b/g2b_nvp_camera_scan1.sv",
    "rtl/v41/nvp_i2c_fixed_master.sv",
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def run(command: list[str], cwd: Path, timeout: int, log: Path) -> str:
    try:
        result = subprocess.run(command, cwd=cwd, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=timeout, check=False)
    except subprocess.TimeoutExpired as error:
        log.write_text(f"HOST_PROCESS_LIMIT_EXPIRED:{timeout}s\n{error}",
                       encoding="utf-8")
        raise RuntimeError(f"HOST_PROCESS_LIMIT_EXPIRED:{log.name}") from error
    log.write_text(result.stdout, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"TOOL_EXIT:{result.returncode}:{log.name}")
    if "Fatal:" in result.stdout or "Error:" in result.stdout:
        raise RuntimeError(f"SIMULATOR_ASSERTION:{log.name}")
    return result.stdout


def git(repo: Path, *args: str) -> str:
    value = subprocess.check_output(["git", "-C", str(repo), *args],
                                    text=True, stderr=subprocess.STDOUT)
    return value.strip()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, required=True)
    ap.add_argument("--source-repo", type=Path, required=True)
    ap.add_argument("--evidence-repo", type=Path, required=True)
    ap.add_argument("--vivado-bin", type=Path, required=True)
    args = ap.parse_args()
    root = args.root.resolve()
    sim = root / "simulation"
    logs = root / "logs"
    cone = root / "source-audit" / "frozen-cone"
    assert git(args.source_repo, "rev-parse", f"{COMMIT}^{{tree}}") == TREE
    initial_hashes = {}
    for rel in BITS:
        path = cone / rel
        assert git(args.source_repo, "hash-object", "--", str(path)) == git(
            args.source_repo, "rev-parse", f"{COMMIT}:{rel}")
        initial_hashes[rel] = sha(path)
    xvl = str(args.vivado_bin / "xvlog.bat")
    xel = str(args.vivado_bin / "xelab.bat")
    xsi = str(args.vivado_bin / "xsim.bat")
    pkg, scanner, master = (str(cone / rel) for rel in BITS)
    mock = str(root / "tests" / "tb_bank5_mock.sv")
    pin = str(root / "tests" / "tb_bank5_pin.sv")
    run([xvl, "-sv", "-work", "work", pkg, scanner, master, mock, pin],
        sim, 120, logs / "repro_compile.log")
    for top, snap in (("tb_bank5_mock", "bank5_mock_repro"),
                      ("tb_bank5_pin", "bank5_pin_repro")):
        run([xel, f"work.{top}", "-s", snap], sim, 120,
            logs / f"repro_elaborate_{top}.log")
    for number in range(1, 15):
        marker = f"TEST_EXECUTION_PASS T{number:02d}"
        output = run([xsi, "bank5_mock_repro", "-R", "-testplusarg",
                      f"CASE_{number}", "-onerror", "quit"], sim, 120,
                     logs / f"repro_T{number:02d}.log")
        if marker not in output:
            raise RuntimeError(f"MISSING_COMPLETION_MARKER:T{number:02d}")
    for phase, marker in (("DATA", "T15"), ("WADDR", "T16"),
                          ("REGADDR", "T16"), ("RADDR", "T16")):
        output = run([xsi, "bank5_pin_repro", "-R", "-testplusarg",
                      f"PIN_{phase}", "-onerror", "quit"], sim, 180,
                     logs / f"repro_{marker}_{phase}.log")
        if f"TEST_EXECUTION_PASS {marker}" not in output:
            raise RuntimeError(f"MISSING_COMPLETION_MARKER:{marker}_{phase}")
    private = root / "input-private" / "characterization"
    public = args.evidence_repo / (
        "v41-hardware-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3r4r2-"
        "coldstart-existing-driver")
    output = run([sys.executable, str(root / "tests" / "replay_private.py"),
                  "--private", str(private),
                  "--frozen-host", str(root / "source-audit" / "frozen-host"),
                  "--public", str(public),
                  "--historical", str(root / "evidence-staging" /
                                      "HISTORICAL_SIGNATURE.json"),
                  "--sim-log", str(logs / "repro_T02.log"),
                  "--out", str(root / "analysis")], root, 120,
                 logs / "repro_T17_T18.log")
    assert "T17_PASS" in output and "T18_PASS" in output
    for rel in BITS:
        assert sha(cone / rel) == initial_hashes[rel], f"SOURCE_CHANGED:{rel}"
    print("OFFLINE_REPRODUCTION_18_OF_18_PASS")


if __name__ == "__main__":
    main()
