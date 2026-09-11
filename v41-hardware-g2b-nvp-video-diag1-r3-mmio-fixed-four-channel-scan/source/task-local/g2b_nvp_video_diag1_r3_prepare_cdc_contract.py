#!/usr/bin/env python3
"""Create the fail-closed R2R1-diagnostic to R3 CDC comparison contract."""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path


TASK = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3_20260910T200154Z")
R2R1 = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z")
OLD_BUILD = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z")
OLD_DCP = OLD_BUILD / "reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp"
NEW_DCP = TASK / "reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R3_ROUTED.dcp"
OLD_CDC = OLD_BUILD / "reports/vivado_full/CDC.rpt"
NEW_CDC = TASK / "reports/vivado_full/CDC.rpt"
V2 = R2R1 / "cdc/NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.csv"
ASSEMBLER = R2R1 / "scripts/g2b_nvp_video_diag1_r2r1_assemble_manifest.py"
OUT = TASK / "cdc"
CONTRACT = OUT / "changed_destinations.tsv"

EXPECTED_OLD_DCP = "45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F"
EXPECTED_NEW_DCP = "5E7791F4A72F7901842B9104C3CA2A5ED71EBFB5C27D0362B8259BA20EA54879"
EXPECTED_V2 = "2631C846EA4C96C3A09EADBBA73F6CECE25322022693373635A4F67FB4509B7B"

FIELDS = (
    "RowID", "Rule", "Severity", "DestinationEndpoint",
    "ProductPhysicalSource", "DiagnosticPhysicalSource", "SourceClock",
    "DestinationClock", "Exception", "SemanticFamily", "GoverningToken",
    "ProtocolProof", "EarliestUseBarrier", "ReplacementGroup",
)


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_parser():
    spec = importlib.util.spec_from_file_location("r2r1_assembler", ASSEMBLER)
    require(spec is not None and spec.loader is not None, "R2R1 parser unavailable")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def pair(old_rows, new_rows):
    old_by_key = defaultdict(list)
    new_by_key = defaultdict(list)
    for row in old_rows:
        old_by_key[row.non_source_key()].append(row)
    for row in new_rows:
        new_by_key[row.non_source_key()].append(row)
    require(Counter({k: len(v) for k, v in old_by_key.items()}) ==
            Counter({k: len(v) for k, v in new_by_key.items()}),
            "rule/severity/clock/exception/destination key drift")
    pairs = []
    for key in sorted(old_by_key, key=repr):
        left = old_by_key[key]
        right = new_by_key[key]
        lc = Counter(row.source for row in left)
        rc = Counter(row.source for row in right)
        exact = lc & rc
        lt = {row.source: row for row in left}
        rt = {row.source: row for row in right}
        for source in sorted(exact):
            pairs.extend((lt[source], rt[source], False) for _ in range(exact[source]))
        lrem = []
        rrem = []
        for source, count in (lc - exact).items():
            lrem.extend([lt[source]] * count)
        for source, count in (rc - exact).items():
            rrem.extend([rt[source]] * count)
        require(len(lrem) == len(rrem), f"source multiplicity drift for {key!r}")
        pairs.extend((a, b, True) for a, b in zip(
            sorted(lrem, key=lambda row: row.source),
            sorted(rrem, key=lambda row: row.source),
        ))
    require(len(pairs) == 1337, f"paired row count {len(pairs)}")
    return pairs


def manifest_key(row):
    return (
        row["DiagnosticPhysicalSource"], row["DestinationEndpoint"],
        row["Rule"], row["Severity"], row["SourceClock"],
        row["DestinationClock"], row["Exception"],
    )


def raw_key(row):
    return (
        row.source, row.destination, row.rule, row.severity,
        row.source_clock, row.destination_clock, row.exception,
    )


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    require(not CONTRACT.exists(), f"contract already exists: {CONTRACT}")
    require(sha(OLD_DCP) == EXPECTED_OLD_DCP, "R2R1 diagnostic DCP identity mismatch")
    require(sha(NEW_DCP) == EXPECTED_NEW_DCP, "R3 routed DCP identity mismatch")
    require(sha(V2) == EXPECTED_V2, "semantic manifest V2 identity mismatch")
    parser = load_parser()
    old_rows, _ = parser.parse_cdc_report(OLD_CDC)
    new_rows, _ = parser.parse_cdc_report(NEW_CDC)
    parser.validate_raw_rows(old_rows, "R2R1 diagnostic")
    parser.validate_raw_rows(new_rows, "R3 diagnostic")
    pairs = pair(old_rows, new_rows)
    with V2.open("r", encoding="utf-8-sig", newline="") as f:
        v2_rows = list(csv.DictReader(f))
    require(len(v2_rows) == 1337, "V2 row count drift")
    by_key = defaultdict(list)
    for row in v2_rows:
        by_key[manifest_key(row)].append(row)
    changed = []
    comparison = []
    used_ids = set()
    for old, new, is_changed in pairs:
        candidates = by_key[raw_key(old)]
        require(len(candidates) == 1, f"V2 mapping multiplicity {len(candidates)} for {raw_key(old)!r}")
        authority = candidates[0]
        require(authority["RowID"] not in used_ids, f"duplicate V2 RowID {authority['RowID']}")
        used_ids.add(authority["RowID"])
        comparison.append({
            "RowID": authority["RowID"], "Rule": old.rule,
            "Severity": old.severity, "DestinationEndpoint": old.destination,
            "R2R1PhysicalSource": old.source, "R3PhysicalSource": new.source,
            "SourceClock": old.source_clock, "DestinationClock": old.destination_clock,
            "Exception": old.exception, "PhysicalSourceChanged": "YES" if is_changed else "NO",
            "PriorProofClass": authority["ProofClass"],
        })
        if not is_changed:
            continue
        changed.append({
            "RowID": authority["RowID"], "Rule": old.rule,
            "Severity": old.severity, "DestinationEndpoint": old.destination,
            "ProductPhysicalSource": old.source,
            "DiagnosticPhysicalSource": new.source,
            "SourceClock": old.source_clock,
            "DestinationClock": old.destination_clock,
            "Exception": old.exception,
            "SemanticFamily": authority["SemanticFamilyOrSupportSet"],
            "GoverningToken": authority["GoverningToken"],
            "ProtocolProof": authority["Protocol"],
            "EarliestUseBarrier": authority["EarliestUseBarrier"],
            "ReplacementGroup": authority["ReplacementGroup"],
        })
    require(len(used_ids) == 1337, "V2 row coverage is not complete")
    require(len(changed) == 527, f"changed row count {len(changed)}")
    require(Counter((r["Rule"], r["Severity"]) for r in changed) == Counter({
        ("CDC-1", "Critical"): 310,
        ("CDC-10", "Critical"): 1,
        ("CDC-15", "Warning"): 216,
    }), "changed rule/severity partition drift")
    with CONTRACT.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(changed)
    cmp_path = OUT / "G2B_NVP_VIDEO_DIAG1_R3_PHYSICAL_ROW_COMPARISON.csv"
    with cmp_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=tuple(comparison[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(comparison)
    receipt = {
        "Classification": "NVP_VIDEO_DIAG1_R3_CDC_CONTRACT_PREPARATION_V1",
        "Result": "PASS",
        "R2R1DiagnosticRoutedDCPSHA256": sha(OLD_DCP),
        "R3RoutedDCPSHA256": sha(NEW_DCP),
        "SemanticManifestV2SHA256": sha(V2),
        "Rows": 1337,
        "DestinationsPresentInBothProfiles": 1337,
        "NewDestinations": 0,
        "MissingDestinations": 0,
        "RuleSeverityClockExceptionDrift": 0,
        "ByteIdenticalPhysicalRows": 810,
        "ChangedPhysicalRows": 527,
        "ChangedCriticalRows": 311,
        "ChangedWarningRows": 216,
        "DiagnosticMMIOHierarchyCDCRows": 0,
        "ContractSHA256": sha(CONTRACT),
        "PhysicalComparisonSHA256": sha(cmp_path),
    }
    (OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_CONTRACT_RECEIPT.json").write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps(receipt, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
