#!/usr/bin/env python3
"""Capture only task-local kernel-health deltas for R3R4R6R1."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time


TASK = "G2B-HW0-PRODUCT-R3R4R6R1"
FAULT_PATTERNS = {
    "KERNEL_OOPS": re.compile(r"\bOops\b", re.IGNORECASE),
    "KERNEL_BUG": re.compile(r"\bBUG:\b", re.IGNORECASE),
    "CALL_TRACE": re.compile(r"Call Trace:", re.IGNORECASE),
    "HUNG_TASK": re.compile(r"hung task|blocked for more than", re.IGNORECASE),
    "DMA_API_FAULT": re.compile(r"DMA-API.*(?:error|fault)|DMA-API-DEBUG", re.IGNORECASE),
    "IOMMU_FAULT": re.compile(r"IOMMU.*(?:fault|error)", re.IGNORECASE),
    "PCIE_AER": re.compile(r"\bAER\b.*(?:fatal|nonfatal|error)|PCIe Bus Error", re.IGNORECASE),
    "COMPLETION_TIMEOUT": re.compile(r"completion timeout", re.IGNORECASE),
    "MALFORMED_TLP": re.compile(r"malformed TLP", re.IGNORECASE),
    "UNSUPPORTED_REQUEST": re.compile(r"unsupported request", re.IGNORECASE),
    "LINK_DOWN": re.compile(r"link[- ]down|link is down", re.IGNORECASE),
    "XDMA_FATAL": re.compile(r"xdma.*(?:fatal|engine timeout)", re.IGNORECASE),
}


def read_dmesg() -> str:
    completed = subprocess.run(
        ["dmesg", "--color=never"], check=False, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if completed.returncode != 0:
        raise RuntimeError(
            f"R3R4R6R1_DMESG_READ_FAILED:{completed.returncode}:"
            f"{completed.stderr.strip()}")
    return completed.stdout


def write_exclusive(path: Path, content: str) -> None:
    with path.open("x", encoding="utf-8", newline="\n") as handle:
        handle.write(content)
        handle.flush()
        os.fsync(handle.fileno())


def delta_from_baseline(baseline: str, current: str) -> tuple[str, str]:
    if current.startswith(baseline):
        return current[len(baseline):], "EXACT_PREFIX"
    before = baseline.splitlines()
    after = current.splitlines()
    maximum = min(len(before), len(after), 4096)
    overlap = 0
    for count in range(maximum, 0, -1):
        if before[-count:] == after[:count]:
            overlap = count
            break
    return "\n".join(after[overlap:]) + ("\n" if after[overlap:] else ""), \
        f"LINE_SUFFIX_OVERLAP:{overlap}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("baseline", "checkpoint"))
    parser.add_argument("--logs-dir", required=True)
    parser.add_argument("--label")
    args = parser.parse_args()
    logs = Path(args.logs_dir)
    logs.mkdir(parents=True, exist_ok=True, mode=0o700)
    taint = int(Path("/proc/sys/kernel/tainted").read_text().strip())
    current = read_dmesg()
    baseline_path = logs / "kernel-baseline.txt"

    if args.mode == "baseline":
        write_exclusive(baseline_path, current)
        result = {
            "schema": "R3R4R6R1_MINIMAL_HEALTH_BASELINE_V1",
            "task": TASK,
            "result": "PASS",
            "kernel_taint": taint,
            "dmesg_bytes": len(current.encode()),
            "dmesg_sha256": hashlib.sha256(current.encode()).hexdigest().upper(),
            "timestamp_ns": time.time_ns(),
        }
        output = logs / "health-baseline.json"
    else:
        if not args.label or not re.fullmatch(r"[a-z0-9-]+", args.label):
            raise RuntimeError("R3R4R6R1_HEALTH_LABEL_INVALID")
        baseline = baseline_path.read_text(encoding="utf-8")
        delta, relation = delta_from_baseline(baseline, current)
        matches = []
        for line_number, line in enumerate(delta.splitlines(), 1):
            categories = [name for name, pattern in FAULT_PATTERNS.items()
                          if pattern.search(line)]
            if categories:
                matches.append({
                    "delta_line": line_number,
                    "categories": categories,
                    "text": line,
                })
        write_exclusive(logs / f"kernel-delta-{args.label}.txt", delta)
        result = {
            "schema": "R3R4R6R1_MINIMAL_HEALTH_CHECKPOINT_V1",
            "task": TASK,
            "checkpoint": args.label,
            "result": "PASS" if not matches else "FAIL",
            "kernel_taint": taint,
            "baseline_relation": relation,
            "new_delta_bytes": len(delta.encode()),
            "new_faults": matches,
            "timestamp_ns": time.time_ns(),
        }
        output = logs / f"health-{args.label}.json"
    write_exclusive(output, json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
