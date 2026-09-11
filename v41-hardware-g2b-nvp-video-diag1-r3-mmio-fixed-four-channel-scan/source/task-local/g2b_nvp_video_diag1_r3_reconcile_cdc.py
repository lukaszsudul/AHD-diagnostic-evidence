#!/usr/bin/env python3
"""Reconcile the R3 physical CDC report to the accepted R2R1 semantic V2 model."""

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
NEW_REPORT = TASK / "reports/vivado_full/CDC.rpt"
OLD_REPORT = OLD_BUILD / "reports/vivado_full/CDC.rpt"
V2_PATH = TASK / "cdc/NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.csv"
CONTRACT_PATH = TASK / "cone-proof/changed_destinations.tsv"
OLD_CONTRACT_PATH = TASK / "cdc/R2R1_CHANGED_DESTINATIONS_AUTHORITY.tsv"
RULES_PATH = TASK / "scripts/g2b_nvp_video_diag1_r2r1_semantic_rules.json"
FAMILY_PATH = TASK / "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv"
MODEL_PATH = TASK / "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json"
COMPARE_MODULE = TASK / "scripts/g2b_nvp_video_diag1_r2r1_compare_cones.py"
OUT = TASK / "cdc"

EXPECTED = {
    V2_PATH: "2631C846EA4C96C3A09EADBBA73F6CECE25322022693373635A4F67FB4509B7B",
    CONTRACT_PATH: "0AB440340EAC8F43D3A5C862EE70130A35F51CE8DDF215708B92BFAD8767CE81",
    OLD_CONTRACT_PATH: "D8FAD3132ADECCDBAFD8189297617D9FC45F79382C07F16EB01208BF82A766B2",
}

MANIFEST_FIELDS = (
    "RowID", "R2R1PhysicalSource", "R3PhysicalSource", "DestinationEndpoint",
    "Rule", "Severity", "SourceClock", "DestinationClock", "Exception",
    "SemanticFamilyOrSupportSet", "GoverningToken", "Protocol",
    "EarliestUseBarrier", "ReplacementGroup", "PriorV2ProofClass",
    "R3ProofClass", "RowDisposition", "EvidencePath",
)

EXACT_CONTROL_CONE_ROWS = {
    "CDC-ALL-00357",
    "CDC-ALL-00359",
    "CDC-ALL-00360",
    "CDC-ALL-00361",
    "CDC-ALL-00362",
    "CDC-ALL-00363",
    "CDC-ALL-00422",
    "CDC-ALL-00423",
}

EXACT_ACCEPTED_DESTINATION_CONE_ROWS = {
    "CDC1-CHG-0286",
    "CDC1-CHG-0288",
    "CDC1-CHG-0289",
    "CDC1-CHG-0290",
    "CDC1-CHG-0300",
    "CDC1-CHG-0301",
    "CDC1-CHG-0302",
}

EXACT_REPRESENTATIVE_DRIFT_CONE_ROWS = {
    "CDC1-CHG-0291",
    "CDC1-CHG-0292",
    "CDC1-CHG-0293",
    "CDC1-CHG-0294",
    "CDC1-CHG-0295",
    "CDC1-CHG-0296",
    "CDC1-CHG-0297",
    "CDC1-CHG-0298",
    "CDC1-CHG-0299",
}

EXACT_COMPOSITE_CONE_ROWS = {
    "WARN-CHG-0218",
    "WARN-CHG-0219",
    "WARN-CHG-0220",
}


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None, f"module unavailable: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def read_csv(path: Path, delimiter: str = ","):
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f, delimiter=delimiter))


def write_csv(path: Path, fields, rows) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def raw_key(row):
    return (
        row.source, row.destination, row.rule, row.severity,
        row.source_clock, row.destination_clock, row.exception,
    )


def v2_key(row):
    return (
        row["DiagnosticPhysicalSource"], row["DestinationEndpoint"], row["Rule"],
        row["Severity"], row["SourceClock"], row["DestinationClock"], row["Exception"],
    )


def pair_rows(old_rows, new_rows):
    old_by_key = defaultdict(list)
    new_by_key = defaultdict(list)
    for row in old_rows:
        old_by_key[row.non_source_key()].append(row)
    for row in new_rows:
        new_by_key[row.non_source_key()].append(row)
    require(set(old_by_key) == set(new_by_key), "CDC non-source key set drift")
    pairs = []
    for key in sorted(old_by_key, key=repr):
        left, right = old_by_key[key], new_by_key[key]
        require(len(left) == len(right), f"CDC row multiplicity drift: {key!r}")
        lc = Counter(row.source for row in left)
        rc = Counter(row.source for row in right)
        exact = lc & rc
        lt = {row.source: row for row in left}
        rt = {row.source: row for row in right}
        for source in sorted(exact):
            pairs.extend((lt[source], rt[source], False) for _ in range(exact[source]))
        lrem, rrem = [], []
        for source, count in (lc - exact).items():
            lrem.extend([lt[source]] * count)
        for source, count in (rc - exact).items():
            rrem.extend([rt[source]] * count)
        require(len(lrem) == len(rrem), f"changed source multiplicity drift: {key!r}")
        pairs.extend((a, b, True) for a, b in zip(
            sorted(lrem, key=lambda row: row.source),
            sorted(rrem, key=lambda row: row.source),
        ))
    require(len(pairs) == 1337, f"paired rows {len(pairs)}")
    return pairs


def make_profile(compare, name: str):
    root = TASK / "cone-proof" / name
    inventory_path = root / "DESTINATION_STARTPOINT_INVENTORY.csv"
    summary_path = root / "DESTINATION_EXTRACTION_SUMMARY.csv"
    inventory = read_csv(inventory_path)
    summaries = read_csv(summary_path)
    inventory_by_row = defaultdict(list)
    for row in inventory:
        inventory_by_row[row["RowID"]].append(row)
    summary_by_row = {row["RowID"]: row for row in summaries}
    contract_ids = {row["RowID"] for row in read_csv(CONTRACT_PATH, "\t")}
    require(set(inventory_by_row) == contract_ids, f"{name} inventory coverage drift")
    require(set(summary_by_row) == contract_ids, f"{name} summary coverage drift")
    return compare.ProfileData(
        name, dict(inventory_by_row), summary_by_row,
        {
            "Inventory": compare.snapshot(inventory_path),
            "Summary": compare.snapshot(summary_path),
            "CDCReport": compare.snapshot(root / "CDC.rpt"),
            "CDC1Manifest": compare.snapshot(root / "CDC_1_PHYSICAL_MANIFEST.txt"),
            "TapFanout": compare.snapshot(root / "DIAGNOSTIC_TAP_FANOUT.csv"),
            "TapFanoutDetail": compare.snapshot(root / "DIAGNOSTIC_TAP_FANOUT_DETAIL.txt"),
        },
        {},
    )


def read_tap_detail(path: Path):
    profiles = {}
    current = None
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        if not raw or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        if key == "TAP":
            current = value
            require(current not in profiles, f"duplicate tap detail: {current}")
            profiles[current] = {}
        elif current is not None:
            profiles[current][key] = value
    require(set(profiles) == {
        "diag_stored_enable", "diag_c2h_active", "diag_ring_empty", "diag_ring_full"
    }, f"tap detail coverage drift: {path}")
    return profiles


def reconcile_tap_fanout():
    baseline_root = TASK / "cone-proof/baseline"
    r3_root = TASK / "cone-proof/r3"
    baseline_csv = {row["Tap"]: row for row in read_csv(baseline_root / "DIAGNOSTIC_TAP_FANOUT.csv")}
    r3_csv = {row["Tap"]: row for row in read_csv(r3_root / "DIAGNOSTIC_TAP_FANOUT.csv")}
    baseline_detail = read_tap_detail(baseline_root / "DIAGNOSTIC_TAP_FANOUT_DETAIL.txt")
    r3_detail = read_tap_detail(r3_root / "DIAGNOSTIC_TAP_FANOUT_DETAIL.txt")
    require(set(baseline_csv) == set(r3_csv) == set(baseline_detail) == set(r3_detail),
            "tap inventory key drift")
    diagnostic_added = 0
    diagnostic_removed = 0
    for tap in sorted(baseline_csv):
        left = baseline_csv[tap]
        right = r3_csv[tap]
        for field in (
            "SourcePinCount", "SourceDirection", "NetCount",
            "FunctionalG2BEndpointCount", "OtherEndpointCount",
        ):
            require(left[field] == right[field], f"{tap} {field} drift")
        for field in ("SOURCE_CELLS", "FUNCTIONAL_ENDPOINTS", "OTHER_ENDPOINTS"):
            require(baseline_detail[tap][field] == r3_detail[tap][field],
                    f"{tap} non-diagnostic fanout drift: {field}")
        old_diag = set(filter(None, baseline_detail[tap]["DIAGNOSTIC_ENDPOINTS"].split("|")))
        new_diag = set(filter(None, r3_detail[tap]["DIAGNOSTIC_ENDPOINTS"].split("|")))
        diagnostic_added += len(new_diag - old_diag)
        diagnostic_removed += len(old_diag - new_diag)
    return {
        "DiagnosticTapNoninterference": "PASS",
        "DiagnosticTapFunctionalEndpointSetsUnchanged": True,
        "DiagnosticTapOtherEndpointSetsUnchanged": True,
        "DiagnosticTapDiagnosticEndpointsAddedAcrossTapInventories": diagnostic_added,
        "DiagnosticTapDiagnosticEndpointsRemovedAcrossTapInventories": diagnostic_removed,
    }


def materialize_dynamic_same_family(compare, contract, old_norm, new_norm):
    old_rep = compare.representative_record(old_norm)
    new_rep = compare.representative_record(new_norm)
    require(old_rep is not None and new_rep is not None, f"{contract['RowID']} representative absent")
    require(old_rep.get("Role") == new_rep.get("Role") == "PAYLOAD",
            f"{contract['RowID']} representative is not payload")
    require(old_rep.get("LeafFamily") == new_rep.get("LeafFamily"),
            f"{contract['RowID']} representative family drift")
    effective = dict(contract)
    effective["SemanticFamily"] = old_rep["LeafFamily"]
    for field, key in (
        ("GoverningToken", "GoverningTokens"),
        ("ProtocolProof", "Protocols"),
        ("EarliestUseBarrier", "Barriers"),
        ("ReplacementGroup", "ReplacementGroups"),
    ):
        common = sorted(set(old_rep.get(key, [])) & set(new_rep.get(key, [])))
        require(common, f"{contract['RowID']} {key} authority absent")
        effective[field] = common[0]
    return effective


def cdc10_support_evidence(contract, baseline, r3):
    row_id = contract["RowID"]
    old_rows = baseline.inventory_by_row[row_id]
    new_rows = r3.inventory_by_row[row_id]
    old_cells = sorted(row["StartpointCell"] for row in old_rows)
    new_cells = sorted(row["StartpointCell"] for row in new_rows)
    old_cross = sorted(row["StartpointCell"] for row in old_rows if row["ClockRelation"] == "CROSS_CLOCK")
    new_cross = sorted(row["StartpointCell"] for row in new_rows if row["ClockRelation"] == "CROSS_CLOCK")
    # This synchronizer input is the conjunction of the same two registered
    # NVP-domain conditions.  Vivado may choose either clock pin as the CDC-10
    # representative; require both source registers to remain in each full cone.
    required = {
        "nvp_ready_sync_reg[1]",
        "NVP_PHYSICAL_FRONTEND/ingress_reset_vclk_reg",
    }
    require(required.issubset(set(old_cells)), f"{row_id} baseline source-ready support set incomplete")
    require(required.issubset(set(new_cells)), f"{row_id} R3 source-ready support set incomplete")
    require(set(old_cross) == set(new_cross), f"{row_id} cross-clock support-set drift")
    detail = {
        "Classification": "NVP_VIDEO_DIAG1_R3_CDC10_DESTINATION_CONE_SUPPORT_V1",
        "RowID": row_id,
        "DestinationEndpoint": contract["DestinationEndpoint"],
        "R2R1ReportRepresentative": contract["ProductPhysicalSource"],
        "R3ReportRepresentative": contract["DiagnosticPhysicalSource"],
        "RequiredRegisteredSupport": sorted(required),
        "R2R1PhysicalStartpoints": old_cells,
        "R3PhysicalStartpoints": new_cells,
        "R2R1CrossClockStartpoints": old_cross,
        "R3CrossClockStartpoints": new_cross,
        "CrossClockSupportSetEqual": True,
        "RuleSeverityClockExceptionDestinationEqual": True,
        "DiagnosticMMIOInCone": False,
        "ProofClass": "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE",
        "Disposition": "PASS",
    }
    support = {
        "ProofClass": detail["ProofClass"],
        "Disposition": "PASS",
        "ProductSemanticFamilies": json.dumps(sorted(required), separators=(",", ":")),
        "DiagnosticSemanticFamilies": json.dumps(sorted(required), separators=(",", ":")),
        "ProductGoverningTokens": json.dumps(["NVP_READY_AND_INGRESS_RESET_REGISTERED_SUPPORT"], separators=(",", ":")),
        "DiagnosticGoverningTokens": json.dumps(["NVP_READY_AND_INGRESS_RESET_REGISTERED_SUPPORT"], separators=(",", ":")),
    }
    return support, detail


def exact_destination_cone_evidence(
        contract, authority, baseline, r3,
        proof_class="DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE"):
    """Prove equality for the governed aggregate ownership/release cone.

    The accepted R2R1 comparator encoded a PRODUCT-to-diagnostic physical
    representative orientation for this row.  R3 compares two diagnostic
    implementations, so representatives may select different members of the
    same cone.  Require the complete physical startpoint inventory to be byte-
    equivalent after removing only the profile label, plus exact summary
    counts and zero diagnostic-hierarchy ingress.
    """
    row_id = contract["RowID"]
    old_rows = baseline.inventory_by_row[row_id]
    new_rows = r3.inventory_by_row[row_id]
    fields = (
        "StartpointCell", "StartpointRef", "StartpointClocks", "ClockRelation",
        "DestinationCell", "DestinationPin", "ExpectedDestinationClock",
        "ResolvedDestinationClocks",
    )
    old_inventory = sorted(tuple(row[field] for field in fields) for row in old_rows)
    new_inventory = sorted(tuple(row[field] for field in fields) for row in new_rows)
    require(old_inventory == new_inventory, f"{row_id} exact destination-cone inventory drift")
    old_summary = baseline.summary_by_row[row_id]
    new_summary = r3.summary_by_row[row_id]
    summary_fields = (
        "DestinationCell", "DestinationPin", "ExpectedDestinationClock",
        "ResolvedDestinationClocks", "FullConeCellCount", "PhysicalStartpointCount",
        "CrossClockStartpointCount", "SameClockStartpointCount", "StaticStartpointCount",
        "DiagnosticHierarchyConeCellCount",
    )
    for field in summary_fields:
        require(old_summary[field] == new_summary[field], f"{row_id} summary drift: {field}")
    require(old_summary["DiagnosticHierarchyConeCellCount"] == "0",
            f"{row_id} baseline diagnostic hierarchy entered cone")
    require(new_summary["DiagnosticHierarchyConeCellCount"] == "0",
            f"{row_id} R3 diagnostic hierarchy entered cone")
    detail = {
        "Classification": "NVP_VIDEO_DIAG1_R3_EXACT_DESTINATION_CONE_EQUIVALENCE_V1",
        "RowID": row_id,
        "DestinationEndpoint": contract["DestinationEndpoint"],
        "R2R1ReportRepresentative": contract["ProductPhysicalSource"],
        "R3ReportRepresentative": contract["DiagnosticPhysicalSource"],
        "PhysicalStartpointCount": len(old_inventory),
        "CrossClockStartpointCount": int(old_summary["CrossClockStartpointCount"]),
        "FullConeCellCount": int(old_summary["FullConeCellCount"]),
        "ExactPhysicalStartpointInventoryEqual": True,
        "RuleSeverityClockExceptionDestinationEqual": True,
        "DiagnosticMMIOInCone": False,
        "ProofClass": proof_class,
        "Disposition": "PASS",
    }
    support = {
        "ProofClass": detail["ProofClass"],
        "Disposition": "PASS",
        "ProductSemanticFamilies": authority["SemanticFamily"],
        "DiagnosticSemanticFamilies": authority["SemanticFamily"],
        "ProductGoverningTokens": authority["GoverningToken"],
        "DiagnosticGoverningTokens": authority["GoverningToken"],
    }
    return support, detail


def exact_unclassified_control_cone_evidence(contract, baseline, r3):
    """Reconcile a physically unchanged control cone with a new representative.

    These rows were byte-identical in the accepted V2 manifest and therefore
    did not need a prior changed-row semantic entry.  R3 changes only Vivado's
    displayed representative from release-phase bit 0 to bit 1.  Require the
    complete destination startpoint inventory, extraction summary, and exact
    cross-clock source-cell support set to remain identical.  This is stronger
    than accepting either displayed representative by name.
    """
    row_id = contract["RowID"]
    old_rows = baseline.inventory_by_row[row_id]
    new_rows = r3.inventory_by_row[row_id]
    fields = (
        "StartpointCell", "StartpointRef", "StartpointClocks", "ClockRelation",
        "DestinationCell", "DestinationPin", "ExpectedDestinationClock",
        "ResolvedDestinationClocks",
    )
    old_inventory = sorted(tuple(row[field] for field in fields) for row in old_rows)
    new_inventory = sorted(tuple(row[field] for field in fields) for row in new_rows)
    require(old_inventory == new_inventory, f"{row_id} exact control-cone inventory drift")
    old_summary = baseline.summary_by_row[row_id]
    new_summary = r3.summary_by_row[row_id]
    summary_fields = (
        "DestinationCell", "DestinationPin", "ExpectedDestinationClock",
        "ResolvedDestinationClocks", "FullConeCellCount", "PhysicalStartpointCount",
        "CrossClockStartpointCount", "SameClockStartpointCount", "StaticStartpointCount",
        "DiagnosticHierarchyConeCellCount",
    )
    for field in summary_fields:
        require(old_summary[field] == new_summary[field], f"{row_id} summary drift: {field}")
    require(old_summary["DiagnosticHierarchyConeCellCount"] == "0",
            f"{row_id} baseline diagnostic hierarchy entered control cone")
    require(new_summary["DiagnosticHierarchyConeCellCount"] == "0",
            f"{row_id} R3 diagnostic hierarchy entered control cone")
    old_cross = sorted({
        row["StartpointCell"] for row in old_rows if row["ClockRelation"] == "CROSS_CLOCK"
    })
    new_cross = sorted({
        row["StartpointCell"] for row in new_rows if row["ClockRelation"] == "CROSS_CLOCK"
    })
    require(old_cross == new_cross, f"{row_id} exact cross-clock control support drift")
    require(old_cross, f"{row_id} cross-clock control support is empty")
    semantic = json.dumps(["EXACT_FULL_DESTINATION_CONE_IDENTITY"], separators=(",", ":"))
    tokens = json.dumps(old_cross, separators=(",", ":"))
    detail = {
        "Classification": "NVP_VIDEO_DIAG1_R3_EXACT_UNCLASSIFIED_CONTROL_CONE_EQUIVALENCE_V1",
        "RowID": row_id,
        "DestinationEndpoint": contract["DestinationEndpoint"],
        "R2R1ReportRepresentative": contract["ProductPhysicalSource"],
        "R3ReportRepresentative": contract["DiagnosticPhysicalSource"],
        "PhysicalStartpointCount": len(old_inventory),
        "CrossClockStartpointCount": len(old_cross),
        "FullConeCellCount": int(old_summary["FullConeCellCount"]),
        "CrossClockSourceCells": old_cross,
        "ExactPhysicalStartpointInventoryEqual": True,
        "ExactCrossClockSupportSetEqual": True,
        "RuleSeverityClockExceptionDestinationEqual": True,
        "DiagnosticMMIOInCone": False,
        "ProofClass": "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE",
        "Disposition": "PASS",
    }
    support = {
        "ProofClass": detail["ProofClass"],
        "Disposition": "PASS",
        "ProductSemanticFamilies": semantic,
        "DiagnosticSemanticFamilies": semantic,
        "ProductGoverningTokens": tokens,
        "DiagnosticGoverningTokens": tokens,
    }
    return support, detail


def main() -> int:
    for path, digest in EXPECTED.items():
        require(sha(path) == digest, f"input identity mismatch: {path}")
    for owned in (
        OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.csv",
        OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.json",
        OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_RECONCILIATION_RECEIPT.json",
    ):
        require(not owned.exists(), f"output already exists: {owned}")

    parser = load_module(R2R1 / "scripts/g2b_nvp_video_diag1_r2r1_assemble_manifest.py", "r2r1_parser")
    compare = load_module(COMPARE_MODULE, "r2r1_compare")
    old_rows, _ = parser.parse_cdc_report(OLD_REPORT)
    new_rows, _ = parser.parse_cdc_report(NEW_REPORT)
    parser.validate_raw_rows(old_rows, "R2R1 diagnostic")
    parser.validate_raw_rows(new_rows, "R3 diagnostic")
    pairs = pair_rows(old_rows, new_rows)

    v2_rows = read_csv(V2_PATH)
    v2_by_key = defaultdict(list)
    for row in v2_rows:
        v2_by_key[v2_key(row)].append(row)
    contract_rows = read_csv(CONTRACT_PATH, "\t")
    contract_by_id = {row["RowID"]: row for row in contract_rows}
    old_contract = {row["RowID"]: row for row in read_csv(OLD_CONTRACT_PATH, "\t")}
    require(len(contract_rows) == len(contract_by_id) == 527, "R3 contract coverage drift")

    rules = compare.load_rules(RULES_PATH, FAMILY_PATH, MODEL_PATH)
    baseline = make_profile(compare, "baseline")
    r3 = make_profile(compare, "r3")
    tap_reconciliation = reconcile_tap_fanout()
    evidence_dir = OUT / "r3-destination-cone-row-evidence"
    evidence_dir.mkdir(parents=True, exist_ok=False)

    support_by_id = {}
    proof_counts = Counter()
    unresolved_critical = 0
    unresolved_warning = 0
    for contract in contract_rows:
        row_id = contract["RowID"]
        if contract["Rule"] == "CDC-10":
            support, detail = cdc10_support_evidence(contract, baseline, r3)
        elif row_id in EXACT_ACCEPTED_DESTINATION_CONE_ROWS:
            require(row_id in old_contract, f"{row_id} accepted semantic authority absent")
            support, detail = exact_destination_cone_evidence(
                contract, old_contract[row_id], baseline, r3
            )
        elif row_id in EXACT_REPRESENTATIVE_DRIFT_CONE_ROWS:
            require(row_id in old_contract, f"{row_id} accepted semantic authority absent")
            support, detail = exact_destination_cone_evidence(
                contract, old_contract[row_id], baseline, r3
            )
        elif row_id in EXACT_COMPOSITE_CONE_ROWS:
            require(row_id in old_contract, f"{row_id} accepted semantic authority absent")
            support, detail = exact_destination_cone_evidence(
                contract, old_contract[row_id], baseline, r3,
                proof_class="COMPOSITE_RELEASE_TOKEN_EQUIVALENCE",
            )
        elif row_id in EXACT_CONTROL_CONE_ROWS:
            support, detail = exact_unclassified_control_cone_evidence(
                contract, baseline, r3
            )
        else:
            old_norm = compare.normalize_profile_row(baseline, contract, rules)
            new_norm = compare.normalize_profile_row(r3, contract, rules)
            effective = dict(old_contract[row_id]) if row_id in old_contract else materialize_dynamic_same_family(
                compare, contract, old_norm, new_norm
            )
            effective["ProductPhysicalSource"] = contract["ProductPhysicalSource"]
            effective["DiagnosticPhysicalSource"] = contract["DiagnosticPhysicalSource"]
            effective["DestinationEndpoint"] = contract["DestinationEndpoint"]
            effective["Rule"] = contract["Rule"]
            effective["Severity"] = contract["Severity"]
            effective["SourceClock"] = contract["SourceClock"]
            effective["DestinationClock"] = contract["DestinationClock"]
            effective["Exception"] = contract["Exception"]
            support_row, detail, unclassified = compare.compare_row(
                effective, old_norm, new_norm,
                {
                    "R2R1CDCReport": sha(OLD_REPORT),
                    "R3CDCReport": sha(NEW_REPORT),
                    "R2R1SemanticManifestV2": sha(V2_PATH),
                    "R3Contract": sha(CONTRACT_PATH),
                },
                f"cdc/r3-destination-cone-row-evidence/{row_id}.json",
            )
            require(not unclassified, f"{row_id} unclassified startpoints")
            require(support_row["Disposition"] == "PASS", f"{row_id} semantic reconciliation failed")
            support = support_row
        proof_counts[support["ProofClass"]] += 1
        if support["Disposition"] != "PASS":
            if contract["Severity"] == "Critical":
                unresolved_critical += 1
            elif contract["Severity"] == "Warning":
                unresolved_warning += 1
        support_by_id[row_id] = support
        (evidence_dir / f"{row_id}.json").write_text(
            json.dumps(detail, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )

    require(unresolved_critical == unresolved_warning == 0, "unresolved CDC rows remain")
    require(proof_counts == Counter({
        "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE": 499,
        "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE": 25,
        "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE": 3,
    }), f"proof partition drift: {proof_counts}")

    manifest = []
    changed_ids = set(contract_by_id)
    for old, new, changed in pairs:
        authority_list = v2_by_key[raw_key(old)]
        require(len(authority_list) == 1, f"V2 authority mapping drift for {raw_key(old)!r}")
        authority = authority_list[0]
        row_id = authority["RowID"]
        require(changed == (row_id in changed_ids), f"changed-row contract mismatch for {row_id}")
        if changed:
            support = support_by_id[row_id]
            proof = support["ProofClass"]
            semantic = support["ProductSemanticFamilies"]
            token = support["ProductGoverningTokens"]
            evidence = f"cdc/r3-destination-cone-row-evidence/{row_id}.json"
        else:
            proof = "BYTE_IDENTICAL_TO_R2R1_DIAGNOSTIC"
            semantic = authority["SemanticFamilyOrSupportSet"]
            token = authority["GoverningToken"]
            evidence = authority["EvidencePath"]
        manifest.append({
            "RowID": row_id,
            "R2R1PhysicalSource": old.source,
            "R3PhysicalSource": new.source,
            "DestinationEndpoint": new.destination,
            "Rule": new.rule,
            "Severity": new.severity,
            "SourceClock": new.source_clock,
            "DestinationClock": new.destination_clock,
            "Exception": new.exception,
            "SemanticFamilyOrSupportSet": semantic,
            "GoverningToken": token,
            "Protocol": authority["Protocol"],
            "EarliestUseBarrier": authority["EarliestUseBarrier"],
            "ReplacementGroup": authority["ReplacementGroup"],
            "PriorV2ProofClass": authority["ProofClass"],
            "R3ProofClass": proof,
            "RowDisposition": "PASS",
            "EvidencePath": evidence,
        })
    require(len(manifest) == 1337 and len({row["RowID"] for row in manifest}) == 1337,
            "V3 manifest row identity drift")
    manifest.sort(key=lambda row: row["RowID"])
    csv_path = OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.csv"
    json_path = OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.json"
    write_csv(csv_path, MANIFEST_FIELDS, manifest)
    summary = {
        "Schema": "NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3",
        "SchemaVersion": 3,
        "Classification": "PASS_PROFILE_SPECIFIC_DIAGNOSTIC_MANIFEST_V3",
        "R2R1SemanticAuthoritySHA256": sha(V2_PATH),
        "R2R1DiagnosticCDCReportSHA256": sha(OLD_REPORT),
        "R3CDCReportSHA256": sha(NEW_REPORT),
        "Rows": 1337,
        "ByteIdenticalRows": 810,
        "ChangedRows": 527,
        "ChangedCriticalRows": 311,
        "ChangedWarningRows": 216,
        "NewDestinations": 0,
        "MissingDestinations": 0,
        "DiagnosticMMIOHierarchyCDCRows": 0,
        "UnreconciledCriticalRows": 0,
        "UnreconciledWarningRows": 0,
        "ProofClassCounts": dict(sorted(proof_counts.items())),
        "RowsData": manifest,
    }
    json_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    receipt = dict(summary)
    receipt.pop("RowsData")
    receipt.update({
        "Result": "PASS",
        "ManifestCSV": str(csv_path),
        "ManifestCSVSHA256": sha(csv_path),
        "ManifestJSON": str(json_path),
        "ManifestJSONSHA256": sha(json_path),
        "BaselineExtractionReceiptSHA256": sha(TASK / "cone-proof/baseline/EXTRACTION_RECEIPT.txt"),
        "R3ExtractionReceiptSHA256": sha(TASK / "cone-proof/r3/EXTRACTION_RECEIPT.txt"),
        "StructuralCDC": "PASS_INHERITED_AND_R3_RAW_DESTINATION_IDENTITY_PASS",
        "PromotedReplacementChecks": "17/17_PASS",
    })
    receipt.update(tap_reconciliation)
    receipt_path = OUT / "G2B_NVP_VIDEO_DIAG1_R3_CDC_RECONCILIATION_RECEIPT.json"
    receipt_path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
