#!/usr/bin/env python3
"""Prepare the exact R2R1 changed-destination extraction contract.

This is a mechanical projection of the accepted R2 critical/warning
reconciliation CSVs.  It does not infer or normalize any semantic family.
"""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


TASK_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z")
R2_ROOT = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2_20260910T064851Z")
CRITICAL = R2_ROOT / "cdc" / "G2B_NVP_VIDEO_DIAG1_R2_CDC_CRITICAL_RECONCILIATION.csv"
WARNING = R2_ROOT / "cdc" / "G2B_NVP_VIDEO_DIAG1_R2_CDC_WARNING_RECONCILIATION.csv"
OUT_TSV = TASK_ROOT / "cone-proof" / "changed_destinations.tsv"
OUT_JSON = TASK_ROOT / "cone-proof" / "changed_destination_contract.json"


FIELDS = [
    "RowID",
    "Rule",
    "Severity",
    "DestinationEndpoint",
    "ProductPhysicalSource",
    "DiagnosticPhysicalSource",
    "SourceClock",
    "DestinationClock",
    "Exception",
    "SemanticFamily",
    "GoverningToken",
    "ProtocolProof",
    "EarliestUseBarrier",
    "ReplacementGroup",
]

EXPECTED_CRITICAL_SHA256 = "7E60B4855BD2A1D578A8D03E49806A6BDC0806DAEAAB0A490A95F3C8714B4148"
EXPECTED_WARNING_SHA256 = "5A1B267ED3EDA48D0A8DB545DE47DF8E8C83634D4AE7674991F7EE69A078945E"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def load(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    missing = [field for field in FIELDS if field not in rows[0]]
    if missing:
        raise RuntimeError(f"missing columns in {path}: {missing}")
    return [{field: row[field] for field in FIELDS} for row in rows]


def main() -> None:
    actual_critical_sha = sha256(CRITICAL)
    actual_warning_sha = sha256(WARNING)
    if actual_critical_sha != EXPECTED_CRITICAL_SHA256:
        raise RuntimeError(
            f"critical row-registry identity drift: {actual_critical_sha}"
        )
    if actual_warning_sha != EXPECTED_WARNING_SHA256:
        raise RuntimeError(
            f"warning row-registry identity drift: {actual_warning_sha}"
        )
    critical = load(CRITICAL)
    warning = load(WARNING)
    if len(critical) != 302 or len(warning) != 220:
        raise RuntimeError(
            f"accepted R2 cardinality drift: critical={len(critical)} warning={len(warning)}"
        )
    rows = critical + warning
    row_ids = [row["RowID"] for row in rows]
    destinations = [row["DestinationEndpoint"] for row in rows]
    if len(set(row_ids)) != 522:
        raise RuntimeError("changed RowID uniqueness failed")
    if len(set(destinations)) != 522:
        raise RuntimeError("changed destination uniqueness failed")
    terminal_counts: dict[str, int] = {}
    pair_counts: dict[str, int] = {}
    for row in rows:
        terminal = row["DestinationEndpoint"].rsplit("/", 1)[-1]
        terminal_counts[terminal] = terminal_counts.get(terminal, 0) + 1
        pair = f"{row['SourceClock']}->{row['DestinationClock']}"
        pair_counts[pair] = pair_counts.get(pair, 0) + 1
        if not row["ProductPhysicalSource"].endswith("/C"):
            raise RuntimeError(f"PRODUCT representative terminal drift: {row['RowID']}")
        if not row["DiagnosticPhysicalSource"].endswith("/C"):
            raise RuntimeError(f"diagnostic representative terminal drift: {row['RowID']}")
    if terminal_counts != {"CE": 265, "D": 226, "R": 31}:
        raise RuntimeError(f"destination terminal distribution drift: {terminal_counts}")
    if pair_counts != {"nvp_vclk1->userclk1": 502, "userclk1->nvp_vclk1": 20}:
        raise RuntimeError(f"clock-pair distribution drift: {pair_counts}")

    OUT_TSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_TSV.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("\t".join(FIELDS) + "\n")
        for row in rows:
            values = []
            for field in FIELDS:
                value = row[field]
                if "\t" in value or "\r" in value or "\n" in value:
                    raise RuntimeError(f"non-TSV-safe value in {row['RowID']}:{field}")
                values.append(value)
            handle.write("\t".join(values) + "\n")

    contract = {
        "Classification": "R2R1_EXACT_CHANGED_DESTINATION_EXTRACTION_CONTRACT",
        "CriticalRows": len(critical),
        "WarningRows": len(warning),
        "TotalRows": len(rows),
        "UniqueDestinations": len(set(destinations)),
        "CriticalSourceSHA256": actual_critical_sha,
        "WarningSourceSHA256": actual_warning_sha,
        "DestinationTerminalCounts": terminal_counts,
        "ClockPairCounts": pair_counts,
        "OutputTSVSHA256": sha256(OUT_TSV),
        "Rows": rows,
    }
    OUT_JSON.write_text(
        json.dumps(contract, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n"
    )
    print(f"R2R1_DESTINATION_CONTRACT_PASS={OUT_TSV}")
    print(f"ROWS={len(rows)}")
    print(f"SHA256={sha256(OUT_TSV)}")


if __name__ == "__main__":
    main()
