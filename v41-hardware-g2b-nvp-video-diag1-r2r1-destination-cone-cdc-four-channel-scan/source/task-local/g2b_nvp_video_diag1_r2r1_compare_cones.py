#!/usr/bin/env python3
"""Fail-closed offline comparison of the two R2R1 destination-cone extracts.

The Vivado workers deliberately emit physical facts only.  This program is the
separate, reviewable semantic layer.  It never opens a DCP and never invokes
Vivado.  Cross-clock payload names are admitted only by anchored full-name
rules in the governed source-family CSV plus semantic model; explicit control
rules remain in the companion JSON.  A missing or ambiguous rule is evidence,
not a name-normalization opportunity, and makes the affected row fail.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import string
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


TASK_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_SHA256 = "D8FAD3132ADECCDBAFD8189297617D9FC45F79382C07F16EB01208BF82A766B2"

CONTRACT_FIELDS = (
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
)

INVENTORY_FIELDS = (
    "Profile",
    "RowID",
    "DestinationPin",
    "DestinationCell",
    "ExpectedDestinationClock",
    "ResolvedDestinationClocks",
    "StartpointCell",
    "StartpointRef",
    "StartpointClocks",
    "ClockRelation",
)

SUMMARY_FIELDS = (
    "Profile",
    "RowID",
    "DestinationPin",
    "DestinationCell",
    "ExpectedDestinationClock",
    "ResolvedDestinationClocks",
    "ReportRepresentative",
    "ReportRepresentativeCell",
    "RepresentativeInStartpoints",
    "PhysicalStartpointCount",
    "FullConeCellCount",
    "CrossClockStartpointCount",
    "SameClockStartpointCount",
    "StaticStartpointCount",
    "DiagnosticHierarchyConeCellCount",
)

TAP_FIELDS = (
    "Tap",
    "PinCount",
    "Direction",
    "NetCount",
    "AllFanoutEndpointCellCount",
    "FunctionalG2BEndpointCount",
    "DiagnosticEndpointCount",
    "Disposition",
)

FAMILY_DEFINITION_FIELDS = (
    "RuleID",
    "CanonicalLeafFamily",
    "LegacyR2FamilyAlias",
    "ParentFamily",
    "Field",
    "AllowedPhysicalSourceBase",
    "PhysicalCellFullmatchRegex",
    "AllowedIndices",
    "SourceClock",
    "DestinationClock",
    "StartpointRole",
    "AllowedUseRoles",
    "GoverningToken",
    "Protocol",
    "EarliestUseBarrier",
    "ExceptionClass",
    "ExceptionRequirementNs",
    "ReplacementGroup",
    "AuthorityStatus",
    "AuthorityEvidence",
)

SUPPORT_FIELDS = (
    "RowID",
    "Rule",
    "Severity",
    "DestinationPin",
    "DestinationCell",
    "DestinationClock",
    "ProductReportRepresentative",
    "DiagnosticReportRepresentative",
    "ProductPhysicalStartpoints",
    "DiagnosticPhysicalStartpoints",
    "ProductSemanticFamilies",
    "DiagnosticSemanticFamilies",
    "NewFamilies",
    "MissingFamilies",
    "ProductGoverningTokens",
    "DiagnosticGoverningTokens",
    "ProtocolDrift",
    "ExceptionDrift",
    "BarrierDrift",
    "ReplacementGroupDrift",
    "ProofClass",
    "Disposition",
    "EvidencePath",
)

UNKNOWN_FIELDS = (
    "Profile",
    "RowID",
    "DestinationPin",
    "ClockRelation",
    "StartpointCell",
    "StartpointClocks",
    "Reason",
    "MatchedRuleIDs",
)

ATOM_ID_FIELDS = (
    "LeafFamily",
    "ParentFamily",
    "Slot",
    "Field",
    "SourceClock",
    "UseRole",
)

CONTROL_ID_FIELDS = (
    "ControlKind",
    "Slot",
    "Field",
    "SourceClock",
    "UseRole",
)

METADATA_FIELDS = (
    "GoverningTokens",
    "Protocols",
    "Exceptions",
    "ExceptionRequirementsNs",
    "Barriers",
    "ReplacementGroups",
)

CROSS_CRITICAL_ROWS = frozenset(
    {
        "CDC1-CHG-0286",
        "CDC1-CHG-0288",
        "CDC1-CHG-0289",
        "CDC1-CHG-0290",
        "CDC1-CHG-0300",
        "CDC1-CHG-0301",
        "CDC1-CHG-0302",
    }
)
COMPOSITE_WARNING_ROWS = frozenset(
    {"WARN-CHG-0218", "WARN-CHG-0219", "WARN-CHG-0220"}
)
TRANSPORT_REQUEST_SYNC2_SOURCE_CELL = "G2B_ONECH_C2H/transport_req_sync2_source_reg"

EXPECTED_PROOF_CLASS_COUNTS = {
    "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE": 512,
    "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE": 7,
    "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE": 3,
}

EXPECTED_PROFILE_AUTHORITY = {
    "product": {
        "DCP_SHA256": "5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82",
        "CDC_1_PHYSICAL_MANIFEST_SHA256": "A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D",
    },
    "diagnostic": {
        "DCP_SHA256": "45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F",
        "CDC_1_PHYSICAL_MANIFEST_SHA256": "BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99",
    },
}


class GateFailure(RuntimeError):
    """A deterministic input/configuration gate failed."""


@dataclass(frozen=True)
class Snapshot:
    path: Path
    data: bytes
    sha256: str


@dataclass(frozen=True)
class UseSpec:
    destination_text: str
    destination_pattern: re.Pattern[str] | None
    use_role: str
    governing_tokens: tuple[str, ...]
    protocols: tuple[str, ...]
    barriers: tuple[str, ...]
    replacement_groups: tuple[str, ...]


@dataclass(frozen=True)
class RuleSpec:
    rule_id: str
    pattern_text: str
    pattern: re.Pattern[str]
    expected_source_clock: str
    expected_destination_clock: str | None
    role: str
    leaf_family: str | None
    parent_family: str | None
    control_kind: str | None
    field: str
    slot_group: str | None
    bit_group: str | None
    legacy_r2_family: str | None
    exception_class: str | None
    exception_requirement_ns: str | None
    authority_status: str | None
    authority_evidence: str | None
    uses: tuple[UseSpec, ...]


@dataclass(frozen=True)
class RuleSet:
    snapshot: Snapshot
    authority_snapshots: tuple[Snapshot, ...]
    family_rules: tuple[RuleSpec, ...]
    control_rules: tuple[RuleSpec, ...]
    static_refs: frozenset[str]


@dataclass
class ProfileData:
    profile: str
    inventory_by_row: dict[str, list[dict[str, str]]]
    summary_by_row: dict[str, dict[str, str]]
    snapshots: dict[str, Snapshot]
    receipt: dict[str, str]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def snapshot(path: Path) -> Snapshot:
    try:
        data = path.read_bytes()
    except OSError as exc:
        raise GateFailure(f"required input unavailable: {path}: {exc}") from exc
    return Snapshot(path=path.resolve(), data=data, sha256=sha256_bytes(data))


def compact_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def pretty_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def parse_csv(
    snap: Snapshot, expected_fields: Sequence[str], *, delimiter: str = ","
) -> list[dict[str, str]]:
    try:
        text = snap.data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise GateFailure(f"input is not UTF-8: {snap.path}: {exc}") from exc
    reader = csv.DictReader(io.StringIO(text, newline=""), delimiter=delimiter)
    if tuple(reader.fieldnames or ()) != tuple(expected_fields):
        raise GateFailure(
            f"header mismatch: {snap.path}: expected={list(expected_fields)!r} "
            f"actual={reader.fieldnames!r}"
        )
    rows: list[dict[str, str]] = []
    for line_number, row in enumerate(reader, 2):
        if None in row or any(value is None for value in row.values()):
            raise GateFailure(f"malformed CSV row: {snap.path}:{line_number}")
        rows.append({field: row[field] for field in expected_fields})
    return rows


def parse_receipt(snap: Snapshot) -> dict[str, str]:
    try:
        lines = snap.data.decode("utf-8-sig").splitlines()
    except UnicodeDecodeError as exc:
        raise GateFailure(f"receipt is not UTF-8: {snap.path}: {exc}") from exc
    result: dict[str, str] = {}
    for line_number, line in enumerate(lines, 1):
        if not line:
            continue
        if "=" not in line:
            raise GateFailure(f"malformed receipt line: {snap.path}:{line_number}")
        key, value = line.split("=", 1)
        if not key or key in result:
            raise GateFailure(f"duplicate/empty receipt key: {snap.path}:{line_number}")
        result[key] = value
    return result


def require_equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise GateFailure(f"{label}: expected={expected!r} actual={actual!r}")


def parse_nonnegative_int(value: str, label: str) -> int:
    if not re.fullmatch(r"0|[1-9][0-9]*", value):
        raise GateFailure(f"{label} is not a canonical nonnegative integer: {value!r}")
    return int(value)


def compile_anchored_pattern(text: str, label: str, *, source: bool) -> re.Pattern[str]:
    if not isinstance(text, str) or not text.startswith("^") or not text.endswith("$"):
        raise GateFailure(f"{label} must be explicitly ^...$ anchored")
    if source:
        if not text.startswith("^G2B_ONECH_C2H/"):
            raise GateFailure(f"{label} must retain the exact G2B hierarchy")
        if ".*" in text or ".+" in text:
            raise GateFailure(f"{label} contains a prohibited unbounded wildcard")
    try:
        return re.compile(text, flags=re.ASCII)
    except re.error as exc:
        raise GateFailure(f"invalid regular expression in {label}: {exc}") from exc


def exact_string_list(value: Any, label: str) -> tuple[str, ...]:
    if not isinstance(value, list) or any(not isinstance(item, str) or not item for item in value):
        if value == []:
            return ()
        raise GateFailure(f"{label} must be a list of nonempty strings")
    if len(value) != len(set(value)):
        raise GateFailure(f"{label} contains duplicate values")
    return tuple(sorted(value))


def compile_uses(raw_uses: Any, label: str) -> tuple[UseSpec, ...]:
    if not isinstance(raw_uses, list) or not raw_uses:
        raise GateFailure(f"{label}.Uses must be a nonempty list")
    uses: list[UseSpec] = []
    defaults = 0
    for index, raw in enumerate(raw_uses):
        if not isinstance(raw, dict):
            raise GateFailure(f"{label}.Uses[{index}] is not an object")
        destination_text = raw.get("DestinationPattern")
        if destination_text == "*":
            destination_pattern = None
            defaults += 1
        else:
            destination_pattern = compile_anchored_pattern(
                destination_text, f"{label}.Uses[{index}].DestinationPattern", source=False
            )
        use_role = raw.get("UseRole")
        if not isinstance(use_role, str) or not use_role:
            raise GateFailure(f"{label}.Uses[{index}].UseRole is empty")
        uses.append(
            UseSpec(
                destination_text=destination_text,
                destination_pattern=destination_pattern,
                use_role=use_role,
                governing_tokens=exact_string_list(
                    raw.get("GoverningTokens"), f"{label}.Uses[{index}].GoverningTokens"
                ),
                protocols=exact_string_list(
                    raw.get("Protocols"), f"{label}.Uses[{index}].Protocols"
                ),
                barriers=exact_string_list(
                    raw.get("Barriers"), f"{label}.Uses[{index}].Barriers"
                ),
                replacement_groups=exact_string_list(
                    raw.get("ReplacementGroups"),
                    f"{label}.Uses[{index}].ReplacementGroups",
                ),
            )
        )
    if defaults > 1 or (defaults and len(uses) != 1):
        raise GateFailure(f"{label}.Uses has an overlapping default mapping")
    return tuple(uses)


def compile_rule(raw: Any, label: str, *, family: bool) -> RuleSpec:
    if not isinstance(raw, dict):
        raise GateFailure(f"{label} is not an object")
    rule_id = raw.get("RuleID")
    if not isinstance(rule_id, str) or not rule_id:
        raise GateFailure(f"{label}.RuleID is empty")
    pattern_text = raw.get("Pattern")
    pattern = compile_anchored_pattern(pattern_text, f"{label}.Pattern", source=True)
    expected_clock = raw.get("ExpectedSourceClock")
    if expected_clock not in {"userclk1", "nvp_vclk1"}:
        raise GateFailure(f"{label}.ExpectedSourceClock is not an admitted clock")
    role = "PAYLOAD" if family else raw.get("Role")
    if role not in {"PAYLOAD", "GOVERNING_TOKEN_CONTROL", "LOCAL_SAME_CLOCK"}:
        raise GateFailure(f"{label}.Role is not admitted: {role!r}")
    leaf_family = raw.get("LeafFamily") if family else None
    parent_family = raw.get("ParentFamily") if family else None
    control_kind = None if family else raw.get("ControlKind")
    if family and (not isinstance(leaf_family, str) or not leaf_family):
        raise GateFailure(f"{label}.LeafFamily is empty")
    if parent_family is not None and (not isinstance(parent_family, str) or not parent_family):
        raise GateFailure(f"{label}.ParentFamily is invalid")
    if not family and (not isinstance(control_kind, str) or not control_kind):
        raise GateFailure(f"{label}.ControlKind is empty")
    field = raw.get("Field")
    if not isinstance(field, str) or not field:
        raise GateFailure(f"{label}.Field is empty")
    slot_group = raw.get("SlotGroup")
    bit_group = raw.get("BitGroup")
    for group_name, group_label in ((slot_group, "SlotGroup"), (bit_group, "BitGroup")):
        if group_name is not None:
            if not isinstance(group_name, str) or group_name not in pattern.groupindex:
                raise GateFailure(f"{label}.{group_label} is absent from the source pattern")
    return RuleSpec(
        rule_id=rule_id,
        pattern_text=pattern_text,
        pattern=pattern,
        expected_source_clock=expected_clock,
        expected_destination_clock=None,
        role=role,
        leaf_family=leaf_family,
        parent_family=parent_family,
        control_kind=control_kind,
        field=field,
        slot_group=slot_group,
        bit_group=bit_group,
        legacy_r2_family=raw.get("LegacyR2Family") if family else None,
        exception_class=None,
        exception_requirement_ns=None,
        authority_status=None,
        authority_evidence=None,
        uses=compile_uses(raw.get("Uses"), label),
    )


def destination_patterns(raw: Mapping[str, Any], label: str) -> list[str]:
    singular = raw.get("DestinationFullmatchRegex")
    plural = raw.get("DestinationFullmatchRegexes")
    if singular is not None and plural is not None:
        raise GateFailure(f"{label} has both singular and plural destination patterns")
    values = [singular] if singular is not None else plural
    if not isinstance(values, list) or not values or any(not isinstance(x, str) for x in values):
        raise GateFailure(f"{label} has no exact destination pattern")
    for index, value in enumerate(values):
        compile_anchored_pattern(value, f"{label}[{index}]", source=False)
    return values


def semantic_use(
    destination_text: str,
    use_role: str,
    *,
    governing_token: str,
    protocol: str,
    barriers: Iterable[str],
    replacement_group: str,
) -> UseSpec:
    destination_pattern = (
        None
        if destination_text == "*"
        else compile_anchored_pattern(destination_text, f"use role {use_role}", source=False)
    )
    values = {
        "GoverningToken": governing_token,
        "Protocol": protocol,
        "ReplacementGroup": replacement_group,
    }
    for label, value in values.items():
        if not isinstance(value, str) or not value:
            raise GateFailure(f"semantic {use_role} {label} is empty")
    barrier_values = tuple(sorted(set(barriers)))
    if not barrier_values or any(not isinstance(value, str) or not value for value in barrier_values):
        raise GateFailure(f"semantic {use_role} barrier is empty")
    return UseSpec(
        destination_text=destination_text,
        destination_pattern=destination_pattern,
        use_role=use_role,
        governing_tokens=(governing_token.replace("[slot]", "[{slot}]"),),
        protocols=(protocol,),
        barriers=barrier_values,
        replacement_groups=(replacement_group,),
    )


def family_uses_from_model(
    row: Mapping[str, str], model: Mapping[str, Any]
) -> tuple[UseSpec, ...]:
    family = row["CanonicalLeafFamily"]
    allowed = set(row["AllowedUseRoles"].split("|"))
    fixed = model["UseRoleResolution"]["FixedLeafFamilyRoles"]
    uses: list[UseSpec] = []
    if family in fixed:
        role = fixed[family]
        uses.append(
            semantic_use(
                "*",
                role,
                governing_token=row["GoverningToken"],
                protocol=row["Protocol"],
                barriers=(row["EarliestUseBarrier"],),
                replacement_group=row["ReplacementGroup"],
            )
        )
    elif family == "OWNERSHIP_STABLE_PAYLOAD":
        for role, definition in model["OwnershipUseRoles"].items():
            for pattern in destination_patterns(definition, f"OwnershipUseRoles.{role}"):
                uses.append(
                    semantic_use(
                        pattern,
                        role,
                        governing_token=row["GoverningToken"],
                        protocol=row["Protocol"],
                        barriers=(row["EarliestUseBarrier"],),
                        replacement_group=row["ReplacementGroup"],
                    )
                )
    elif family == "TRANSPORT_RESET_STABLE_PAYLOAD":
        role_map = model["UseRoleResolution"]["DestinationDependentLeafFamilyRoles"][family]
        for role, patterns in role_map.items():
            # The canonical family contains several distinct physical fields.
            # AllowedUseRoles is field authority, not merely documentation:
            # EPOCH/HARD/OWNERSHIP_PHASE are request payload, while
            # RELEASE_PHASE is additionally admitted for reset-overlap use.
            if role not in allowed:
                continue
            values = [patterns] if isinstance(patterns, str) else patterns
            if not isinstance(values, list):
                raise GateFailure(f"transport use role {role} patterns are invalid")
            for pattern in values:
                compile_anchored_pattern(pattern, f"transport use role {role}", source=False)
                uses.append(
                    semantic_use(
                        pattern,
                        role,
                        governing_token=row["GoverningToken"],
                        protocol=row["Protocol"],
                        barriers=(row["EarliestUseBarrier"],),
                        replacement_group=row["ReplacementGroup"],
                    )
                )
    elif family in {"RELEASE_GENERATION_FIELD", "RELEASE_EPOCH_FIELD"}:
        for role, definition in model["ReleaseUseRoles"].items():
            barriers = [definition["EarliestUseBarrier"]]
            if definition.get("RetirementBarrier"):
                barriers.append(definition["RetirementBarrier"])
            for pattern in destination_patterns(definition, f"ReleaseUseRoles.{role}"):
                uses.append(
                    semantic_use(
                        pattern,
                        role,
                        governing_token=definition["GoverningToken"],
                        protocol=definition["Protocol"],
                        barriers=barriers,
                        replacement_group=definition["ReplacementGroup"],
                    )
                )
    else:
        raise GateFailure(f"no use-role resolver for canonical family {family}")
    actual = {use.use_role for use in uses}
    if actual != allowed:
        raise GateFailure(
            f"use-role authority mismatch for {family}: allowed={sorted(allowed)} actual={sorted(actual)}"
        )
    return tuple(uses)


def load_authoritative_family_rules(
    definitions_path: Path, semantic_model_path: Path
) -> tuple[tuple[Snapshot, Snapshot], tuple[RuleSpec, ...]]:
    definitions_snap = snapshot(definitions_path)
    definition_rows = parse_csv(definitions_snap, FAMILY_DEFINITION_FIELDS)
    require_equal(
        [row["RuleID"] for row in definition_rows],
        [f"SF{index:03d}" for index in range(1, 21)],
        "source-family RuleID order",
    )
    semantic_snap = snapshot(semantic_model_path)
    try:
        model = json.loads(semantic_snap.data.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GateFailure(f"invalid semantic model JSON: {semantic_model_path}: {exc}") from exc
    require_equal(model.get("Schema"), "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL", "semantic model schema")
    require_equal(model.get("SchemaVersion"), 1, "semantic model version")
    require_equal(model.get("SupportAtomKey"), list(ATOM_ID_FIELDS), "semantic model atom key")
    require_equal(
        model.get("RequiredSupportCSVColumns"), list(SUPPORT_FIELDS), "semantic model support columns"
    )
    rules: list[RuleSpec] = []
    for row in definition_rows:
        pattern = compile_anchored_pattern(
            row["PhysicalCellFullmatchRegex"], f"{row['RuleID']} PhysicalCellFullmatchRegex", source=True
        )
        if row["StartpointRole"] != "PAYLOAD":
            raise GateFailure(f"{row['RuleID']} is not a PAYLOAD family rule")
        if row["SourceClock"] not in {"userclk1", "nvp_vclk1"}:
            raise GateFailure(f"{row['RuleID']} has an unadmitted source clock")
        if row["DestinationClock"] not in {"userclk1", "nvp_vclk1"}:
            raise GateFailure(f"{row['RuleID']} has an unadmitted destination clock")
        if not re.fullmatch(r"[0-9]+\.[0-9]{3}", row["ExceptionRequirementNs"]):
            raise GateFailure(f"{row['RuleID']} has a noncanonical exception requirement")
        slot_group: str | None = "slot" if "slot" in pattern.groupindex else None
        if row["RuleID"] == "SF001":
            slot_group = "bit"
        bit_group = "bit" if "bit" in pattern.groupindex else None
        rules.append(
            RuleSpec(
                rule_id=row["RuleID"],
                pattern_text=row["PhysicalCellFullmatchRegex"],
                pattern=pattern,
                expected_source_clock=row["SourceClock"],
                expected_destination_clock=row["DestinationClock"],
                role="PAYLOAD",
                leaf_family=row["CanonicalLeafFamily"],
                parent_family=None if row["ParentFamily"] == "NONE" else row["ParentFamily"],
                control_kind=None,
                field=row["Field"],
                slot_group=slot_group,
                bit_group=bit_group,
                legacy_r2_family=row["LegacyR2FamilyAlias"] or None,
                exception_class=row["ExceptionClass"],
                exception_requirement_ns=row["ExceptionRequirementNs"],
                authority_status=row["AuthorityStatus"],
                authority_evidence=row["AuthorityEvidence"],
                uses=family_uses_from_model(row, model),
            )
        )
    return (definitions_snap, semantic_snap), tuple(rules)


def load_rules(
    path: Path, definitions_path: Path, semantic_model_path: Path
) -> RuleSet:
    snap = snapshot(path)
    try:
        raw = json.loads(snap.data.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GateFailure(f"invalid semantic-rule JSON: {path}: {exc}") from exc
    if not isinstance(raw, dict):
        raise GateFailure("semantic-rule root is not an object")
    require_equal(
        raw.get("Schema"),
        "G2B_NVP_VIDEO_DIAG1_R2R1_EXPLICIT_SEMANTIC_RULES_V1",
        "semantic-rule schema",
    )
    policy = raw.get("Policy")
    if not isinstance(policy, dict):
        raise GateFailure("semantic-rule Policy is absent")
    require_equal(policy.get("CrossClockDefault"), "FAIL_UNCLASSIFIED", "cross-clock policy")
    require_equal(policy.get("SameClockDefault"), "LOCAL_SAME_CLOCK", "same-clock policy")
    static_refs = frozenset(exact_string_list(policy.get("StaticRefs"), "Policy.StaticRefs"))
    require_equal(static_refs, frozenset({"GND", "VCC"}), "static reference whitelist")
    if "FamilyRules" in raw:
        raise GateFailure("embedded FamilyRules are prohibited; canonical family authority is external")
    family_authority = raw.get("FamilyAuthority")
    require_equal(
        family_authority,
        {
            "Definitions": "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv",
            "SemanticModel": "cdc/G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json",
            "Disposition": "AUTHORITATIVE_FILES_REQUIRED_AND_HASH_BOUND",
        },
        "semantic-rule family authority declaration",
    )
    raw_controls = raw.get("ControlRules")
    if not isinstance(raw_controls, list):
        raise GateFailure("ControlRules must be a list")
    authority_snapshots, families = load_authoritative_family_rules(
        definitions_path, semantic_model_path
    )
    controls = tuple(
        compile_rule(item, f"ControlRules[{index}]", family=False)
        for index, item in enumerate(raw_controls)
    )
    ids = [rule.rule_id for rule in families + controls]
    if len(ids) != len(set(ids)):
        raise GateFailure("semantic RuleID values are not unique")
    return RuleSet(snap, authority_snapshots, families, controls, static_refs)


def load_contract(path: Path) -> tuple[Snapshot, list[dict[str, str]]]:
    snap = snapshot(path)
    require_equal(snap.sha256, CONTRACT_SHA256, "changed-destination contract SHA-256")
    rows = parse_csv(snap, CONTRACT_FIELDS, delimiter="\t")
    expected_ids = [f"CDC1-CHG-{index:04d}" for index in range(1, 303)] + [
        f"WARN-CHG-{index:04d}" for index in range(1, 221)
    ]
    require_equal([row["RowID"] for row in rows], expected_ids, "contract RowID order")
    if len({row["DestinationEndpoint"] for row in rows}) != 522:
        raise GateFailure("contract destination pins are not unique")
    require_equal(
        Counter((row["Rule"], row["Severity"]) for row in rows),
        Counter({("CDC-1", "Critical"): 302, ("CDC-15", "Warning"): 220}),
        "contract rule/severity partition",
    )
    terminal_counts = Counter(row["DestinationEndpoint"].rsplit("/", 1)[-1] for row in rows)
    require_equal(terminal_counts, Counter({"CE": 265, "D": 226, "R": 31}), "terminal counts")
    pair_counts = Counter(
        (row["SourceClock"], row["DestinationClock"]) for row in rows
    )
    require_equal(
        pair_counts,
        Counter({("nvp_vclk1", "userclk1"): 502, ("userclk1", "nvp_vclk1"): 20}),
        "clock-pair counts",
    )
    for row in rows:
        if row["Rule"] not in {"CDC-1", "CDC-15"}:
            raise GateFailure(f"{row['RowID']} unexpected rule {row['Rule']!r}")
        if row["Severity"] not in {"Critical", "Warning"}:
            raise GateFailure(f"{row['RowID']} unexpected severity {row['Severity']!r}")
        if not row["ProductPhysicalSource"].endswith("/C"):
            raise GateFailure(f"{row['RowID']} PRODUCT representative is not /C")
        if not row["DiagnosticPhysicalSource"].endswith("/C"):
            raise GateFailure(f"{row['RowID']} diagnostic representative is not /C")
        require_equal(row["Exception"], "Max Delay Datapath Only", f"{row['RowID']} exception")
    return snap, rows


def validate_receipt(receipt: Mapping[str, str], profile: str) -> None:
    fixed = {
        "RESULT": "PASS",
        "PROFILE": profile,
        "MODE": "EXACT_ROUTED_DCP_REPORT_ONLY",
        "PART": "xc7a35tcsg325-2",
        "TOP": "ahd_capture_top_xdma",
        "CDC_ROWS": "1337",
        "CRITICAL_TOTAL": "427",
        "WARNING_TOTAL": "874",
        "INFO_TOTAL": "36",
        "CDC_1_COUNT": "423",
        "CHANGED_DESTINATIONS_PROCESSED": "522",
        "CONSTRAINTS_CHANGED": "NO",
        "IMPLEMENTATION_CHANGED": "NO",
        "DCP_CHANGED": "NO",
        "BITSTREAM_WRITTEN": "NO",
    }
    fixed.update(EXPECTED_PROFILE_AUTHORITY[profile])
    for key, expected in fixed.items():
        require_equal(receipt.get(key), expected, f"{profile} receipt {key}")
    if not receipt.get("VIVADO_VERSION", "").startswith("2025.2"):
        raise GateFailure(f"{profile} receipt Vivado version is not 2025.2")
    for key in (
        "STARTPOINT_INVENTORY_SHA256",
        "EXTRACTION_SUMMARY_SHA256",
        "TAP_FANOUT_SHA256",
    ):
        value = receipt.get(key, "")
        if not re.fullmatch(r"[0-9A-F]{64}", value):
            raise GateFailure(f"{profile} receipt has invalid {key}")
    if profile == "diagnostic":
        require_equal(
            receipt.get("TAP_PROOF_METHOD"),
            "EXACT_SOURCE_DRIVER_ALL_FANOUT_TWO_DCP_DELTA",
            "diagnostic tap proof method",
        )
        require_equal(
            receipt.get("TAP_BOUNDARY_NAME_DISPOSITION"),
            "FORMAL_PORT_NAMES_OPTIMIZED_SOURCE_ANCHORS_USED",
            "diagnostic tap boundary disposition",
        )
        for key in ("TAP_FANOUT_DETAIL_SHA256", "PRODUCT_DCP_SHA256_FOR_TAP_DELTA"):
            if not re.fullmatch(r"[0-9A-F]{64}", receipt.get(key, "")):
                raise GateFailure(f"diagnostic receipt has invalid {key}")


def validate_taps(profile: str, rows: list[dict[str, str]]) -> None:
    require_equal(
        [row["Tap"] for row in rows],
        ["diag_stored_enable", "diag_c2h_active", "diag_ring_empty", "diag_ring_full"],
        f"{profile} tap order",
    )
    for row in rows:
        require_equal(row["FunctionalG2BEndpointCount"], "0", f"{profile} {row['Tap']} feedback")
        if profile == "product":
            expected = {
                "PinCount": "0",
                "Direction": "ABSENT",
                "NetCount": "0",
                "AllFanoutEndpointCellCount": "0",
                "DiagnosticEndpointCount": "0",
                "Disposition": "PRODUCT_ABSENT_EXPECTED",
            }
        else:
            expected = {
                "PinCount": "7" if row["Tap"] == "diag_c2h_active" else "1",
                "Direction": "OUT",
                "Disposition": "PASS_SOURCE_DRIVER_DELTA_DIAGNOSTIC_ONLY_PORT_NAMES_OPTIMIZED",
            }
            if parse_nonnegative_int(
                row["AllFanoutEndpointCellCount"], f"{profile} {row['Tap']} fanout"
            ) < 1:
                raise GateFailure(f"{profile} {row['Tap']} has no endpoint")
            if parse_nonnegative_int(
                row["DiagnosticEndpointCount"], f"{profile} {row['Tap']} diagnostic fanout"
            ) < 1:
                raise GateFailure(f"{profile} {row['Tap']} has no diagnostic endpoint")
        for key, value in expected.items():
            require_equal(row[key], value, f"{profile} {row['Tap']} {key}")


def load_profile(
    profile: str, directory: Path, contract_rows: Sequence[Mapping[str, str]]
) -> ProfileData:
    receipt_snap = snapshot(directory / "EXTRACTION_RECEIPT.txt")
    receipt = parse_receipt(receipt_snap)
    validate_receipt(receipt, profile)
    inventory_snap = snapshot(directory / "DESTINATION_STARTPOINT_INVENTORY.csv")
    summary_snap = snapshot(directory / "DESTINATION_EXTRACTION_SUMMARY.csv")
    tap_snap = snapshot(directory / "DIAGNOSTIC_TAP_FANOUT.csv")
    tap_detail_snap = (
        snapshot(directory / "DIAGNOSTIC_TAP_FANOUT_DETAIL.txt")
        if profile == "diagnostic"
        else None
    )
    require_equal(
        inventory_snap.sha256,
        receipt["STARTPOINT_INVENTORY_SHA256"],
        f"{profile} inventory receipt hash",
    )
    require_equal(
        summary_snap.sha256,
        receipt["EXTRACTION_SUMMARY_SHA256"],
        f"{profile} summary receipt hash",
    )
    require_equal(tap_snap.sha256, receipt["TAP_FANOUT_SHA256"], f"{profile} tap receipt hash")
    if tap_detail_snap is not None:
        require_equal(
            tap_detail_snap.sha256,
            receipt["TAP_FANOUT_DETAIL_SHA256"],
            "diagnostic tap-detail receipt hash",
        )
    inventory = parse_csv(inventory_snap, INVENTORY_FIELDS)
    summaries = parse_csv(summary_snap, SUMMARY_FIELDS)
    tap_rows = parse_csv(tap_snap, TAP_FIELDS)
    validate_taps(profile, tap_rows)

    contract_by_id = {row["RowID"]: row for row in contract_rows}
    expected_order = [row["RowID"] for row in contract_rows]
    require_equal(len(summaries), 522, f"{profile} summary row count")
    require_equal([row["RowID"] for row in summaries], expected_order, f"{profile} summary order")
    summary_by_row: dict[str, dict[str, str]] = {}
    for summary in summaries:
        row_id = summary["RowID"]
        if row_id in summary_by_row:
            raise GateFailure(f"{profile} duplicate summary row {row_id}")
        contract = contract_by_id[row_id]
        require_equal(summary["Profile"], profile, f"{profile} {row_id} summary Profile")
        require_equal(
            summary["DestinationPin"], contract["DestinationEndpoint"], f"{profile} {row_id} pin"
        )
        expected_cell = contract["DestinationEndpoint"].rsplit("/", 1)[0]
        require_equal(summary["DestinationCell"], expected_cell, f"{profile} {row_id} cell")
        require_equal(
            summary["ExpectedDestinationClock"],
            contract["DestinationClock"],
            f"{profile} {row_id} expected clock",
        )
        require_equal(
            summary["ResolvedDestinationClocks"],
            contract["DestinationClock"],
            f"{profile} {row_id} resolved clock",
        )
        representative = (
            contract["ProductPhysicalSource"]
            if profile == "product"
            else contract["DiagnosticPhysicalSource"]
        )
        require_equal(
            summary["ReportRepresentative"], representative, f"{profile} {row_id} representative"
        )
        require_equal(
            summary["ReportRepresentativeCell"],
            representative[:-2],
            f"{profile} {row_id} representative cell",
        )
        require_equal(
            summary["RepresentativeInStartpoints"], "YES", f"{profile} {row_id} representative membership"
        )
        require_equal(
            summary["DiagnosticHierarchyConeCellCount"],
            "0",
            f"{profile} {row_id} diagnostic hierarchy cone count",
        )
        startpoint_count = parse_nonnegative_int(
            summary["PhysicalStartpointCount"], f"{profile} {row_id} startpoint count"
        )
        full_count = parse_nonnegative_int(
            summary["FullConeCellCount"], f"{profile} {row_id} full-cone count"
        )
        if startpoint_count < 1 or full_count < startpoint_count:
            raise GateFailure(
                f"{profile} {row_id} invalid startpoint/full-cone counts: "
                f"{startpoint_count}/{full_count}"
            )
        for key in (
            "CrossClockStartpointCount",
            "SameClockStartpointCount",
            "StaticStartpointCount",
        ):
            parse_nonnegative_int(summary[key], f"{profile} {row_id} {key}")
        summary_by_row[row_id] = summary

    inventory_by_row: dict[str, list[dict[str, str]]] = defaultdict(list)
    collapsed_order: list[str] = []
    closed_rows: set[str] = set()
    previous: str | None = None
    for item in inventory:
        row_id = item["RowID"]
        if row_id not in contract_by_id:
            raise GateFailure(f"{profile} inventory has unknown RowID {row_id!r}")
        if row_id != previous:
            if row_id in closed_rows:
                raise GateFailure(f"{profile} inventory RowID is non-contiguous: {row_id}")
            if previous is not None:
                closed_rows.add(previous)
            collapsed_order.append(row_id)
            previous = row_id
        contract = contract_by_id[row_id]
        summary = summary_by_row[row_id]
        require_equal(item["Profile"], profile, f"{profile} {row_id} inventory Profile")
        for key in (
            "DestinationPin",
            "DestinationCell",
            "ExpectedDestinationClock",
            "ResolvedDestinationClocks",
        ):
            require_equal(item[key], summary[key], f"{profile} {row_id} inventory {key}")
        relation = item["ClockRelation"]
        if relation not in {"CROSS_CLOCK", "SAME_CLOCK", "STATIC"}:
            raise GateFailure(f"{profile} {row_id} invalid relation {relation!r}")
        clocks = item["StartpointClocks"].split(";") if item["StartpointClocks"] else []
        if relation == "STATIC":
            require_equal(clocks, [], f"{profile} {row_id} static clocks")
            if item["StartpointRef"] not in {"GND", "VCC"}:
                raise GateFailure(f"{profile} {row_id} non-whitelisted static {item['StartpointCell']}")
        else:
            if len(clocks) != 1:
                raise GateFailure(f"{profile} {row_id} non-single-clock startpoint {item['StartpointCell']}")
            expected = contract["DestinationClock"] if relation == "SAME_CLOCK" else contract["SourceClock"]
            require_equal(clocks[0], expected, f"{profile} {row_id} {item['StartpointCell']} clock")
            if relation == "CROSS_CLOCK" and clocks[0] == contract["DestinationClock"]:
                raise GateFailure(f"{profile} {row_id} CROSS_CLOCK equals destination clock")
        inventory_by_row[row_id].append(item)

    require_equal(collapsed_order, expected_order, f"{profile} inventory RowID order")
    for row_id in expected_order:
        items = inventory_by_row[row_id]
        summary = summary_by_row[row_id]
        names = [item["StartpointCell"] for item in items]
        if len(names) != len(set(names)):
            raise GateFailure(f"{profile} {row_id} duplicate physical startpoint cell")
        require_equal(
            len(items),
            int(summary["PhysicalStartpointCount"]),
            f"{profile} {row_id} inventory cardinality",
        )
        counts = Counter(item["ClockRelation"] for item in items)
        require_equal(
            counts["CROSS_CLOCK"],
            int(summary["CrossClockStartpointCount"]),
            f"{profile} {row_id} cross-clock count",
        )
        require_equal(
            counts["SAME_CLOCK"],
            int(summary["SameClockStartpointCount"]),
            f"{profile} {row_id} same-clock count",
        )
        require_equal(
            counts["STATIC"],
            int(summary["StaticStartpointCount"]),
            f"{profile} {row_id} static count",
        )
        if summary["ReportRepresentativeCell"] not in names:
            raise GateFailure(f"{profile} {row_id} representative cell absent from inventory")

    return ProfileData(
        profile=profile,
        inventory_by_row=dict(inventory_by_row),
        summary_by_row=summary_by_row,
        snapshots={
            "Receipt": receipt_snap,
            "Inventory": inventory_snap,
            "Summary": summary_snap,
            "TapFanout": tap_snap,
            **({"TapFanoutDetail": tap_detail_snap} if tap_detail_snap is not None else {}),
        },
        receipt=receipt,
    )


def render_templates(values: Iterable[str], groups: Mapping[str, str], label: str) -> list[str]:
    result: list[str] = []
    formatter = string.Formatter()
    for value in values:
        for _, field_name, _, _ in formatter.parse(value):
            if field_name and field_name not in groups:
                raise GateFailure(f"{label} uses unavailable template field {field_name!r}")
        result.append(value.format_map(groups))
    return sorted(set(result))


def applicable_use(rule: RuleSpec, destination: str) -> tuple[UseSpec | None, str | None]:
    matches = [
        use
        for use in rule.uses
        if use.destination_pattern is None or use.destination_pattern.fullmatch(destination)
    ]
    if len(matches) == 1:
        return matches[0], None
    if not matches:
        return None, "NO_EXPLICIT_DESTINATION_USE_MAPPING"
    return None, "AMBIGUOUS_DESTINATION_USE_MAPPING"


def materialize_rule(
    rule: RuleSpec,
    match: re.Match[str],
    use: UseSpec,
    item: Mapping[str, str],
    exception: str,
) -> dict[str, Any]:
    groups = {key: value for key, value in match.groupdict().items() if value is not None}
    if "slot" in groups:
        groups["14_PLUS_SLOT"] = str(14 + int(groups["slot"]))
    slot = groups.get(rule.slot_group) if rule.slot_group else None
    bit = groups.get(rule.bit_group) if rule.bit_group else None
    exception_class = rule.exception_class or exception
    if exception_class != exception:
        raise GateFailure(
            f"{rule.rule_id} exception authority mismatch: contract={exception!r} rule={exception_class!r}"
        )
    return {
        "PhysicalStartpoint": item["StartpointCell"],
        "PhysicalRef": item["StartpointRef"],
        "ClockRelation": item["ClockRelation"],
        "Role": rule.role,
        "RuleID": rule.rule_id,
        "LeafFamily": rule.leaf_family,
        "ParentFamily": rule.parent_family,
        "ControlKind": rule.control_kind,
        "Slot": slot,
        "Field": rule.field,
        "Bit": bit,
        "SourceClock": item["StartpointClocks"],
        "UseRole": use.use_role,
        "LegacyR2Family": rule.legacy_r2_family,
        "GoverningTokens": render_templates(
            use.governing_tokens, groups, f"{rule.rule_id}.GoverningTokens"
        ),
        "Protocols": render_templates(use.protocols, groups, f"{rule.rule_id}.Protocols"),
        "Exceptions": [exception_class],
        "ExceptionRequirementsNs": (
            [rule.exception_requirement_ns] if rule.exception_requirement_ns is not None else []
        ),
        "Barriers": render_templates(use.barriers, groups, f"{rule.rule_id}.Barriers"),
        "ReplacementGroups": render_templates(
            use.replacement_groups, groups, f"{rule.rule_id}.ReplacementGroups"
        ),
        "AuthorityStatus": rule.authority_status,
        "AuthorityEvidence": rule.authority_evidence,
        "ClassificationStatus": "CLASSIFIED",
    }


def issue_record(
    item: Mapping[str, str], reason: str, matched_rules: Iterable[str]
) -> dict[str, Any]:
    return {
        "PhysicalStartpoint": item["StartpointCell"],
        "PhysicalRef": item["StartpointRef"],
        "ClockRelation": item["ClockRelation"],
        "Role": "UNCLASSIFIED",
        "RuleID": None,
        "LeafFamily": None,
        "ParentFamily": None,
        "ControlKind": None,
        "Slot": None,
        "Field": None,
        "Bit": None,
        "SourceClock": item["StartpointClocks"] or None,
        "UseRole": None,
        "LegacyR2Family": None,
        "GoverningTokens": [],
        "Protocols": [],
        "Exceptions": [],
        "ExceptionRequirementsNs": [],
        "Barriers": [],
        "ReplacementGroups": [],
        "ClassificationStatus": reason,
        "MatchedRuleIDs": sorted(set(matched_rules)),
    }


def local_record(item: Mapping[str, str], *, static: bool = False) -> dict[str, Any]:
    return {
        "PhysicalStartpoint": item["StartpointCell"],
        "PhysicalRef": item["StartpointRef"],
        "ClockRelation": item["ClockRelation"],
        "Role": "LOCAL_SAME_CLOCK",
        "RuleID": "STATIC_LOCAL" if static else "DEFAULT_LOCAL_SAME_CLOCK",
        "LeafFamily": None,
        "ParentFamily": None,
        "ControlKind": "STATIC" if static else "UNQUALIFIED_LOCAL_CONTROL",
        "Slot": None,
        "Field": "STATIC" if static else "LOCAL",
        "Bit": None,
        "SourceClock": item["StartpointClocks"] or None,
        "UseRole": "STATIC_LOCAL" if static else "LOCAL_SAME_CLOCK",
        "LegacyR2Family": None,
        "GoverningTokens": [],
        "Protocols": [],
        "Exceptions": [],
        "ExceptionRequirementsNs": [],
        "Barriers": [],
        "ReplacementGroups": [],
        "ClassificationStatus": "CLASSIFIED",
    }


def classify_startpoint(
    item: Mapping[str, str], destination: str, exception: str, rules: RuleSet
) -> dict[str, Any]:
    relation = item["ClockRelation"]
    if relation == "STATIC":
        return local_record(item, static=True)

    source_name = item["StartpointCell"]
    if relation == "SAME_CLOCK":
        applicable: list[tuple[RuleSpec, re.Match[str], UseSpec]] = []
        matched_but_inactive: list[str] = []
        for rule in rules.control_rules:
            match = rule.pattern.fullmatch(source_name)
            if not match:
                continue
            use, problem = applicable_use(rule, destination)
            if problem:
                matched_but_inactive.append(rule.rule_id)
            else:
                assert use is not None
                applicable.append((rule, match, use))
        if len(applicable) > 1:
            return issue_record(item, "AMBIGUOUS_SAME_CLOCK_CONTROL_RULE", [x[0].rule_id for x in applicable])
        if len(applicable) == 1:
            rule, match, use = applicable[0]
            if item["StartpointClocks"] != rule.expected_source_clock:
                return issue_record(item, "CONTROL_SOURCE_CLOCK_MISMATCH", [rule.rule_id])
            return materialize_rule(rule, match, use, item, exception)
        record = local_record(item)
        if matched_but_inactive:
            record["InactiveExplicitRuleIDs"] = sorted(matched_but_inactive)
        return record

    source_matches: list[tuple[RuleSpec, re.Match[str]]] = []
    for rule in rules.family_rules + rules.control_rules:
        match = rule.pattern.fullmatch(source_name)
        if match:
            source_matches.append((rule, match))
    if not source_matches:
        return issue_record(item, "UNCLASSIFIED_CROSS_CLOCK_SOURCE", [])
    if len(source_matches) > 1:
        return issue_record(
            item, "AMBIGUOUS_CROSS_CLOCK_SOURCE_RULE", [rule.rule_id for rule, _ in source_matches]
        )
    rule, match = source_matches[0]
    use, problem = applicable_use(rule, destination)
    if problem:
        return issue_record(item, problem, [rule.rule_id])
    assert use is not None
    if rule.role == "LOCAL_SAME_CLOCK":
        return issue_record(item, "LOCAL_RULE_MATCHED_CROSS_CLOCK_SOURCE", [rule.rule_id])
    if item["StartpointClocks"] != rule.expected_source_clock:
        return issue_record(item, "CROSS_CLOCK_SOURCE_CLOCK_MISMATCH", [rule.rule_id])
    if (
        rule.expected_destination_clock is not None
        and item["ExpectedDestinationClock"] != rule.expected_destination_clock
    ):
        return issue_record(item, "CROSS_CLOCK_DESTINATION_CLOCK_MISMATCH", [rule.rule_id])
    return materialize_rule(rule, match, use, item, exception)


def required_virtual_controls(
    contract: Mapping[str, str], rules: RuleSet
) -> list[dict[str, Any]]:
    """Materialize protocol-required controls that are not `/D` startpoints.

    This is deliberately marked virtual: it binds an exact governed source cell
    and semantic-use rule without claiming that the cell appeared in the
    startpoints-only inventory.  The composite gate consumes this record as the
    explicit transport-request use trigger.
    """
    if contract["RowID"] not in COMPOSITE_WARNING_ROWS:
        return []
    requested = [("TRANSPORT_REQUEST_SYNC2", TRANSPORT_REQUEST_SYNC2_SOURCE_CELL)] + [
        ("RELEASE_REQUEST_SYNC2", f"G2B_ONECH_C2H/release_sync2_source_reg[{slot}]")
        for slot in range(4)
    ]
    result: list[dict[str, Any]] = []
    for rule_id, source_cell in requested:
        candidates = [rule for rule in rules.control_rules if rule.rule_id == rule_id]
        if len(candidates) != 1:
            raise GateFailure(f"composite virtual control requires exactly one {rule_id} rule")
        rule = candidates[0]
        match = rule.pattern.fullmatch(source_cell)
        if match is None or rule.role != "GOVERNING_TOKEN_CONTROL" or rule.expected_source_clock != "nvp_vclk1":
            raise GateFailure(f"{rule_id} virtual-control authority mismatch")
        use, problem = applicable_use(rule, contract["DestinationEndpoint"])
        if problem or use is None:
            raise GateFailure(f"{rule_id} virtual-control use mapping failed: {problem}")
        materialized = materialize_rule(rule, match, use, {
            "StartpointCell": source_cell,
            "StartpointRef": "SOURCE_BOUND_VIRTUAL_CONTROL",
            "ClockRelation": "SEMANTIC_VIRTUAL_CONTROL",
            "StartpointClocks": "nvp_vclk1",
        }, contract["Exception"])
        result.append({
            **record_identity(materialized, CONTROL_ID_FIELDS),
            **{field: materialized[field] for field in METADATA_FIELDS},
            "EvidenceKind": "SOURCE_BOUND_VIRTUAL_CONTROL",
            "SourceBinding": source_cell,
            "SourceRuleID": rule.rule_id,
            "SourceRulePattern": rule.pattern_text,
            "PhysicalDStartpointClaimed": False,
            "Authority": "CANONICAL_PROTOCOL_CONTROL_NOT_REQUIRED_TO_APPEAR_IN_STARTPOINTS_ONLY_D_PIN_INVENTORY",
        })
    return result


def record_identity(record: Mapping[str, Any], fields: Sequence[str]) -> dict[str, Any]:
    return {field: record.get(field) for field in fields}


def identity_key(record: Mapping[str, Any], fields: Sequence[str]) -> tuple[str, ...]:
    return tuple("" if record.get(field) is None else str(record.get(field)) for field in fields)


def aggregate_records(
    records: Iterable[Mapping[str, Any]], role: str, identity_fields: Sequence[str]
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    aggregated: dict[tuple[str, ...], dict[str, Any]] = {}
    issues: list[dict[str, Any]] = []
    for record in records:
        if record.get("Role") != role or record.get("ClassificationStatus") != "CLASSIFIED":
            continue
        key = identity_key(record, identity_fields)
        metadata = {field: list(record.get(field, [])) for field in METADATA_FIELDS}
        if key not in aggregated:
            aggregated[key] = {
                **record_identity(record, identity_fields),
                **metadata,
                "PhysicalMembers": [record["PhysicalStartpoint"]],
                "RuleIDs": [record["RuleID"]],
            }
            continue
        current = aggregated[key]
        for field in METADATA_FIELDS:
            if current[field] != metadata[field]:
                issues.append(
                    {
                        "Reason": "INTRA_PROFILE_ATOM_METADATA_CONFLICT",
                        "Identity": record_identity(record, identity_fields),
                        "Field": field,
                        "Existing": current[field],
                        "New": metadata[field],
                    }
                )
        current["PhysicalMembers"].append(record["PhysicalStartpoint"])
        current["RuleIDs"].append(record["RuleID"])
    values = []
    for key in sorted(aggregated):
        item = aggregated[key]
        item["PhysicalMembers"] = sorted(set(item["PhysicalMembers"]))
        item["RuleIDs"] = sorted(set(item["RuleIDs"]))
        values.append(item)
    return values, issues


def normalize_profile_row(
    profile: ProfileData,
    contract: Mapping[str, str],
    rules: RuleSet,
) -> dict[str, Any]:
    row_id = contract["RowID"]
    inventory = sorted(profile.inventory_by_row[row_id], key=lambda row: row["StartpointCell"])
    classified = [
        classify_startpoint(item, contract["DestinationEndpoint"], contract["Exception"], rules)
        for item in inventory
    ]
    atoms, atom_issues = aggregate_records(classified, "PAYLOAD", ATOM_ID_FIELDS)
    controls, control_issues = aggregate_records(
        classified, "GOVERNING_TOKEN_CONTROL", CONTROL_ID_FIELDS
    )
    explicit_locals = [
        record
        for record in classified
        if record.get("Role") == "LOCAL_SAME_CLOCK"
        and record.get("RuleID") not in {"DEFAULT_LOCAL_SAME_CLOCK", "STATIC_LOCAL"}
    ]
    local_qualifiers, local_issues = aggregate_records(
        explicit_locals, "LOCAL_SAME_CLOCK", CONTROL_ID_FIELDS
    )
    virtual_controls = required_virtual_controls(contract, rules)
    issues = [
        {
            "Reason": record["ClassificationStatus"],
            "PhysicalStartpoint": record["PhysicalStartpoint"],
            "ClockRelation": record["ClockRelation"],
            "StartpointClocks": record["SourceClock"],
            "MatchedRuleIDs": record.get("MatchedRuleIDs", []),
        }
        for record in classified
        if record.get("ClassificationStatus") != "CLASSIFIED"
    ]
    issues.extend(atom_issues)
    issues.extend(control_issues)
    issues.extend(local_issues)
    return {
        "Summary": profile.summary_by_row[row_id],
        "PhysicalStartpoints": inventory,
        "ClassifiedStartpoints": classified,
        "SupportAtoms": atoms,
        "GoverningControls": controls,
        "VirtualControls": virtual_controls,
        "LocalQualifiers": local_qualifiers,
        "LocalSameClockStartpoints": [
            record for record in classified if record.get("Role") == "LOCAL_SAME_CLOCK"
        ],
        "Issues": sorted(issues, key=compact_json),
    }


def index_records(
    records: Iterable[Mapping[str, Any]], fields: Sequence[str]
) -> dict[tuple[str, ...], Mapping[str, Any]]:
    return {identity_key(record, fields): record for record in records}


def identities(
    records: Iterable[Mapping[str, Any]], fields: Sequence[str]
) -> list[dict[str, Any]]:
    return [record_identity(record, fields) for record in records]


def metadata_drift(
    product: Mapping[tuple[str, ...], Mapping[str, Any]],
    diagnostic: Mapping[tuple[str, ...], Mapping[str, Any]],
    identity_fields: Sequence[str],
    metadata_field: str,
) -> list[dict[str, Any]]:
    result = []
    for key in sorted(set(product) & set(diagnostic)):
        left = product[key].get(metadata_field, [])
        right = diagnostic[key].get(metadata_field, [])
        if left != right:
            result.append(
                {
                    "Identity": record_identity(product[key], identity_fields),
                    "Product": left,
                    "Diagnostic": right,
                }
            )
    return result


def union_metadata(records: Iterable[Mapping[str, Any]], field: str) -> list[str]:
    return sorted({value for record in records for value in record.get(field, [])})


def proof_class(row_id: str) -> str:
    if row_id in CROSS_CRITICAL_ROWS:
        return "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE"
    if row_id in COMPOSITE_WARNING_ROWS:
        return "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE"
    return "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE"


def add_blocker(blockers: list[dict[str, Any]], code: str, detail: Any) -> None:
    blockers.append({"Code": code, "Detail": detail})


def representative_record(normalized: Mapping[str, Any]) -> Mapping[str, Any] | None:
    target = normalized["Summary"]["ReportRepresentativeCell"]
    matches = [
        record
        for record in normalized["ClassifiedStartpoints"]
        if record["PhysicalStartpoint"] == target
    ]
    if len(matches) != 1:
        return None
    return matches[0]


def require_same_family_contract(
    contract: Mapping[str, str],
    product: Mapping[str, Any],
    diagnostic: Mapping[str, Any],
    blockers: list[dict[str, Any]],
) -> None:
    expected = contract["SemanticFamily"]
    if expected.startswith("UNRECONCILED_"):
        add_blocker(blockers, "LEGACY_UNRECONCILED_LABEL_ON_SAME_FAMILY_ROW", expected)
        return
    for profile_name, normalized in (("product", product), ("diagnostic", diagnostic)):
        representative = representative_record(normalized)
        if representative is None or representative.get("Role") != "PAYLOAD":
            add_blocker(blockers, "REPORT_REPRESENTATIVE_NOT_CLASSIFIED_PAYLOAD", profile_name)
            continue
        if representative.get("LeafFamily") != expected:
            add_blocker(
                blockers,
                "REPORT_REPRESENTATIVE_FAMILY_MISMATCH",
                {
                    "Profile": profile_name,
                    "Expected": expected,
                    "Actual": representative.get("LeafFamily"),
                },
            )
        required_metadata = {
            "GoverningTokens": contract["GoverningToken"],
            "Protocols": contract["ProtocolProof"],
            "Barriers": contract["EarliestUseBarrier"],
            "ReplacementGroups": contract["ReplacementGroup"],
        }
        for field, required in required_metadata.items():
            if not required or required not in representative.get(field, []):
                add_blocker(
                    blockers,
                    "REPORT_REPRESENTATIVE_AUTHORITY_METADATA_MISMATCH",
                    {"Profile": profile_name, "Field": field, "Required": required},
                )
        if not any(atom["LeafFamily"] == expected for atom in normalized["SupportAtoms"]):
            add_blocker(
                blockers,
                "EXPECTED_SAME_FAMILY_ABSENT_FROM_SUPPORT_SET",
                {"Profile": profile_name, "Family": expected},
            )


def fields_for_family(normalized: Mapping[str, Any], family: str) -> set[str]:
    return {
        atom["Field"] for atom in normalized["SupportAtoms"] if atom["LeafFamily"] == family
    }


def release_fields_by_slot(normalized: Mapping[str, Any]) -> dict[str, set[str]]:
    result: dict[str, set[str]] = defaultdict(set)
    for atom in normalized["SupportAtoms"]:
        if atom["ParentFamily"] == "RELEASE_TOKEN_STABLE_PAYLOAD":
            result[str(atom["Slot"])].add(atom["Field"])
    return dict(result)


def slots_for_control(normalized: Mapping[str, Any], control_kind: str) -> set[str]:
    return {
        str(control["Slot"])
        for control in list(normalized["GoverningControls"]) + list(normalized["VirtualControls"])
        if control["ControlKind"] == control_kind and control["Slot"] is not None
    }


def slots_for_local(normalized: Mapping[str, Any], control_kind: str) -> set[str]:
    return {
        str(control["Slot"])
        for control in normalized["LocalQualifiers"]
        if control["ControlKind"] == control_kind and control["Slot"] is not None
    }


def has_control(normalized: Mapping[str, Any], control_kind: str) -> bool:
    return any(
        control["ControlKind"] == control_kind for control in normalized["GoverningControls"]
    )


def require_release_shape(
    profile_name: str,
    normalized: Mapping[str, Any],
    blockers: list[dict[str, Any]],
    *,
    exact_slots: set[str] | None,
) -> set[str]:
    by_slot = release_fields_by_slot(normalized)
    slots = set(by_slot)
    if exact_slots is None:
        if not slots:
            add_blocker(blockers, "RELEASE_TOKEN_FAMILY_ABSENT", profile_name)
    elif slots != exact_slots:
        add_blocker(
            blockers,
            "RELEASE_TOKEN_SLOT_COVERAGE_MISMATCH",
            {"Profile": profile_name, "Expected": sorted(exact_slots), "Actual": sorted(slots)},
        )
    for slot in sorted(slots):
        if by_slot[slot] != {"GENERATION", "EPOCH"}:
            add_blocker(
                blockers,
                "RELEASE_TOKEN_CHILD_FIELD_COVERAGE_MISMATCH",
                {"Profile": profile_name, "Slot": slot, "Fields": sorted(by_slot[slot])},
            )
    return slots


def canonical_atom_key(
    leaf: str,
    parent: str | None,
    slot: str | None,
    field: str,
    source_clock: str,
    use_role: str,
) -> tuple[str, ...]:
    return tuple(
        "" if value is None else value
        for value in (leaf, parent, slot, field, source_clock, use_role)
    )


def expected_cross_critical_atoms(destination: str) -> set[tuple[str, ...]]:
    slot_match = re.fullmatch(
        r"G2B_ONECH_C2H/slot_state_source_reg\[(?P<slot>[0-3])\]\[[0-2]\]/D",
        destination,
        flags=re.ASCII,
    )
    if slot_match:
        ownership_role = "OWNERSHIP_NORMAL"
        release_role = "ORDINARY_RELEASE_NORMAL"
        release_slots = {slot_match.group("slot")}
    elif re.fullmatch(
        r"G2B_ONECH_C2H/(?:enable_applied_source|source_ownership_fatal_deferred|"
        r"source_ownership_fatal_event|source_ownership_fatal)_reg/D",
        destination,
        flags=re.ASCII,
    ):
        ownership_role = "OWNERSHIP_MISMATCH"
        release_role = "ORDINARY_RELEASE_MISMATCH"
        release_slots = {"0", "1", "2", "3"}
    else:
        raise GateFailure(f"cross-critical destination has no canonical shape: {destination}")

    expected = {
        canonical_atom_key(
            "OWNERSHIP_STABLE_PAYLOAD", None, None, field, "userclk1", ownership_role
        )
        for field in ("SLOT", "GENERATION", "EPOCH")
    }
    for slot in release_slots:
        expected.add(
            canonical_atom_key(
                "RELEASE_GENERATION_FIELD",
                "RELEASE_TOKEN_STABLE_PAYLOAD",
                slot,
                "GENERATION",
                "userclk1",
                release_role,
            )
        )
        expected.add(
            canonical_atom_key(
                "RELEASE_EPOCH_FIELD",
                "RELEASE_TOKEN_STABLE_PAYLOAD",
                slot,
                "EPOCH",
                "userclk1",
                release_role,
            )
        )
    if destination == "G2B_ONECH_C2H/enable_applied_source_reg/D":
        expected.add(
            canonical_atom_key(
                "ENABLE_VALUE_STABLE_PAYLOAD", None, None, "VALUE", "userclk1", "ENABLE_REQUEST"
            )
        )
    if destination in {
        "G2B_ONECH_C2H/source_ownership_fatal_event_reg/D",
        "G2B_ONECH_C2H/source_ownership_fatal_reg/D",
    }:
        expected.add(
            canonical_atom_key(
                "TRANSPORT_RESET_STABLE_PAYLOAD",
                None,
                None,
                "HARD",
                "userclk1",
                "TRANSPORT_RESET_REQUEST",
            )
        )
    return expected


def require_cross_critical(
    destination: str,
    product: Mapping[str, Any],
    diagnostic: Mapping[str, Any],
    blockers: list[dict[str, Any]],
) -> None:
    expected_atoms = expected_cross_critical_atoms(destination)
    for profile_name, normalized in (("product", product), ("diagnostic", diagnostic)):
        actual_atoms = {
            identity_key(atom, ATOM_ID_FIELDS) for atom in normalized["SupportAtoms"]
        }
        if actual_atoms != expected_atoms:
            add_blocker(
                blockers,
                "CROSS_CRITICAL_CANONICAL_SUPPORT_SHAPE_MISMATCH",
                {
                    "Profile": profile_name,
                    "New": [list(key) for key in sorted(actual_atoms - expected_atoms)],
                    "Missing": [list(key) for key in sorted(expected_atoms - actual_atoms)],
                },
            )
        ownership_fields = fields_for_family(normalized, "OWNERSHIP_STABLE_PAYLOAD")
        if ownership_fields != {"SLOT", "GENERATION", "EPOCH"}:
            add_blocker(
                blockers,
                "OWNERSHIP_CHILD_FIELD_COVERAGE_MISMATCH",
                {"Profile": profile_name, "Fields": sorted(ownership_fields)},
            )
        release_slots = require_release_shape(
            profile_name, normalized, blockers, exact_slots=None
        )
        if not has_control(normalized, "OWNERSHIP_REQUEST_SYNC2"):
            add_blocker(blockers, "OWNERSHIP_REQUEST_SYNC2_CONTROL_ABSENT", profile_name)
        release_control_slots = slots_for_control(normalized, "RELEASE_REQUEST_SYNC2")
        if release_control_slots != release_slots:
            add_blocker(
                blockers,
                "RELEASE_REQUEST_SYNC2_SLOT_COVERAGE_MISMATCH",
                {
                    "Profile": profile_name,
                    "PayloadSlots": sorted(release_slots),
                    "ControlSlots": sorted(release_control_slots),
                },
            )
        release_seen_slots = slots_for_control(normalized, "RELEASE_SEEN_STATE")
        if release_seen_slots != release_slots:
            add_blocker(
                blockers,
                "RELEASE_SEEN_SLOT_COVERAGE_MISMATCH",
                {
                    "Profile": profile_name,
                    "PayloadSlots": sorted(release_slots),
                    "ReleaseSeenSlots": sorted(release_seen_slots),
                },
            )
    product_rep = representative_record(product)
    diagnostic_rep = representative_record(diagnostic)
    if not product_rep or product_rep.get("LeafFamily") != "RELEASE_EPOCH_FIELD":
        add_blocker(blockers, "PRODUCT_CROSS_REPRESENTATIVE_NOT_RELEASE_EPOCH", None)
    if not diagnostic_rep or diagnostic_rep.get("LeafFamily") != "OWNERSHIP_STABLE_PAYLOAD":
        add_blocker(blockers, "DIAGNOSTIC_CROSS_REPRESENTATIVE_NOT_OWNERSHIP", None)


def require_composite_warning(
    product: Mapping[str, Any],
    diagnostic: Mapping[str, Any],
    blockers: list[dict[str, Any]],
) -> None:
    expected_slots = {"0", "1", "2", "3"}
    expected_atoms = {
        canonical_atom_key(
            leaf,
            parent,
            slot,
            field,
            "userclk1",
            "RESET_OVERLAP_ACCOUNTING",
        )
        for slot in expected_slots
        for leaf, parent, field in (
            ("RELEASE_GENERATION_FIELD", "RELEASE_TOKEN_STABLE_PAYLOAD", "GENERATION"),
            ("RELEASE_EPOCH_FIELD", "RELEASE_TOKEN_STABLE_PAYLOAD", "EPOCH"),
            ("TRANSPORT_RESET_STABLE_PAYLOAD", None, "RELEASE_PHASE"),
        )
    }
    for profile_name, normalized in (("product", product), ("diagnostic", diagnostic)):
        actual_atoms = {
            identity_key(atom, ATOM_ID_FIELDS) for atom in normalized["SupportAtoms"]
        }
        if actual_atoms != expected_atoms:
            add_blocker(
                blockers,
                "COMPOSITE_CANONICAL_SUPPORT_SHAPE_MISMATCH",
                {
                    "Profile": profile_name,
                    "New": [list(key) for key in sorted(actual_atoms - expected_atoms)],
                    "Missing": [list(key) for key in sorted(expected_atoms - actual_atoms)],
                },
            )
        require_release_shape(profile_name, normalized, blockers, exact_slots=expected_slots)
        if fields_for_family(normalized, "OWNERSHIP_STABLE_PAYLOAD"):
            add_blocker(blockers, "OWNERSHIP_SUBSTITUTED_IN_COMPOSITE_RELEASE_CONE", profile_name)
        release_protocol_slots = slots_for_control(normalized, "RELEASE_REQUEST_SYNC2")
        if release_protocol_slots != expected_slots:
            add_blocker(
                blockers,
                "COMPOSITE_RELEASE_REQUEST_SYNC2_SLOT_COVERAGE_MISMATCH",
                {"Profile": profile_name, "Actual": sorted(release_protocol_slots)},
            )
        # The destination here is /D.  In the routed cone, the synchronized
        # phase is represented by release_seen_source; transport_req_sync2 is
        # the branch/use trigger and is retained in semantic metadata even
        # when it is not a /D startpoint (it commonly controls CE instead).
        actual_release_seen = slots_for_control(normalized, "RELEASE_SEEN_STATE")
        if actual_release_seen != expected_slots:
            add_blocker(
                blockers,
                "COMPOSITE_CONTROL_SLOT_COVERAGE_MISMATCH",
                {
                    "Profile": profile_name,
                    "ControlKind": "RELEASE_SEEN_STATE",
                    "Actual": sorted(actual_release_seen),
                },
            )
        transport_phase_slots = {
            str(atom["Slot"])
            for atom in normalized["SupportAtoms"]
            if atom["LeafFamily"] == "TRANSPORT_RESET_STABLE_PAYLOAD"
            and atom["Field"] == "RELEASE_PHASE"
            and atom["UseRole"] == "RESET_OVERLAP_ACCOUNTING"
            and atom["Slot"] is not None
        }
        if transport_phase_slots != expected_slots:
            add_blocker(
                blockers,
                "COMPOSITE_TRANSPORT_RELEASE_PHASE_SLOT_COVERAGE_MISMATCH",
                {"Profile": profile_name, "Actual": sorted(transport_phase_slots)},
            )
        local_slots = slots_for_local(normalized, "SLOT_STATE_QUALIFIER")
        if local_slots != expected_slots:
            add_blocker(
                blockers,
                "COMPOSITE_SLOT_STATE_QUALIFIER_COVERAGE_MISMATCH",
                {"Profile": profile_name, "Actual": sorted(local_slots)},
            )
        virtual_triggers = [
            control
            for control in normalized["VirtualControls"]
            if control["ControlKind"] == "TRANSPORT_REQUEST_SYNC2"
        ]
        if len(virtual_triggers) != 1:
            add_blocker(
                blockers,
                "COMPOSITE_TRANSPORT_REQUEST_SYNC2_VIRTUAL_CONTROL_MISSING",
                {"Profile": profile_name, "Count": len(virtual_triggers)},
            )
        else:
            trigger = virtual_triggers[0]
            required_barriers = {
                "GROUPS_14_TO_17_EARLIEST_USE_13.468NS_AND_6NS_SETTLING_CAP_VIA_TRANSPORT_REQUEST",
                "transport_release_phase_hold_axi[3:0] captured phase equals release_sync2_source[3:0] before transport acknowledgement",
            }
            if (
                trigger["SourceBinding"] != TRANSPORT_REQUEST_SYNC2_SOURCE_CELL
                or trigger["SourceClock"] != "nvp_vclk1"
                or trigger["UseRole"] != "RESET_OVERLAP_ACCOUNTING"
                or trigger["GoverningTokens"]
                != ["transport_req_toggle_axi_to_transport_req_sync2_source"]
                or set(trigger["Barriers"]) != required_barriers
                or trigger["PhysicalDStartpointClaimed"] is not False
            ):
                add_blocker(
                    blockers,
                    "COMPOSITE_TRANSPORT_REQUEST_SYNC2_VIRTUAL_CONTROL_AUTHORITY_MISMATCH",
                    {"Profile": profile_name, "Trigger": trigger},
                )
        for atom in normalized["SupportAtoms"]:
            if atom["ParentFamily"] != "RELEASE_TOKEN_STABLE_PAYLOAD":
                continue
            slot = atom["Slot"]
            expected_group = (
                f"GROUP_{14 + int(slot)}_RESET_OVERLAP_ACCOUNTING_PLUS_GROUP_13_RESET_RETURN"
                if slot is not None
                else ""
            )
            if (
                atom["UseRole"] != "RESET_OVERLAP_ACCOUNTING"
                or atom["GoverningTokens"]
                != ["transport_req_toggle_axi_to_transport_req_sync2_source"]
                or expected_group not in atom["ReplacementGroups"]
            ):
                add_blocker(
                    blockers,
                    "COMPOSITE_RELEASE_AUTHORITY_MISMATCH",
                    {
                        "Profile": profile_name,
                        "Atom": record_identity(atom, ATOM_ID_FIELDS),
                        "GoverningTokens": atom["GoverningTokens"],
                        "Groups": atom["ReplacementGroups"],
                    },
                )
    product_rep = representative_record(product)
    diagnostic_rep = representative_record(diagnostic)
    if not product_rep or product_rep.get("LeafFamily") != "RELEASE_GENERATION_FIELD":
        add_blocker(blockers, "PRODUCT_COMPOSITE_REPRESENTATIVE_NOT_RELEASE_GENERATION", None)
    if not diagnostic_rep or diagnostic_rep.get("LeafFamily") != "RELEASE_EPOCH_FIELD":
        add_blocker(blockers, "DIAGNOSTIC_COMPOSITE_REPRESENTATIVE_NOT_RELEASE_EPOCH", None)


def require_slot_state_release_alignment(
    destination: str,
    product: Mapping[str, Any],
    diagnostic: Mapping[str, Any],
    blockers: list[dict[str, Any]],
) -> None:
    match = re.fullmatch(
        r"G2B_ONECH_C2H/slot_state_source_reg\[(?P<slot>[0-3])\]\[[0-2]\]/D",
        destination,
        flags=re.ASCII,
    )
    if not match:
        return
    expected = {match.group("slot")}
    for profile_name, normalized in (("product", product), ("diagnostic", diagnostic)):
        payload_slots = set(release_fields_by_slot(normalized))
        if payload_slots and payload_slots != expected:
            add_blocker(
                blockers,
                "SLOT_STATE_RELEASE_PAYLOAD_SLOT_MISMATCH",
                {
                    "Profile": profile_name,
                    "Expected": sorted(expected),
                    "Actual": sorted(payload_slots),
                },
            )
        control_slots = slots_for_control(normalized, "RELEASE_REQUEST_SYNC2")
        if control_slots and control_slots != expected:
            add_blocker(
                blockers,
                "SLOT_STATE_RELEASE_CONTROL_SLOT_MISMATCH",
                {
                    "Profile": profile_name,
                    "Expected": sorted(expected),
                    "Actual": sorted(control_slots),
                },
            )


def compare_row(
    contract: Mapping[str, str],
    product: Mapping[str, Any],
    diagnostic: Mapping[str, Any],
    input_hashes: Mapping[str, str],
    evidence_path: str,
) -> tuple[dict[str, str], dict[str, Any], list[dict[str, str]]]:
    blockers: list[dict[str, Any]] = []
    for profile_name, normalized in (("product", product), ("diagnostic", diagnostic)):
        for issue in normalized["Issues"]:
            add_blocker(
                blockers,
                "STARTPOINT_CLASSIFICATION_FAILURE",
                {"Profile": profile_name, **issue},
            )

    product_atoms = index_records(product["SupportAtoms"], ATOM_ID_FIELDS)
    diagnostic_atoms = index_records(diagnostic["SupportAtoms"], ATOM_ID_FIELDS)
    new_keys = sorted(set(diagnostic_atoms) - set(product_atoms))
    missing_keys = sorted(set(product_atoms) - set(diagnostic_atoms))
    new_atoms = [record_identity(diagnostic_atoms[key], ATOM_ID_FIELDS) for key in new_keys]
    missing_atoms = [record_identity(product_atoms[key], ATOM_ID_FIELDS) for key in missing_keys]
    if new_atoms or missing_atoms:
        add_blocker(
            blockers,
            "SEMANTIC_SUPPORT_SET_MISMATCH",
            {"New": new_atoms, "Missing": missing_atoms},
        )

    protocol_drift = metadata_drift(
        product_atoms, diagnostic_atoms, ATOM_ID_FIELDS, "Protocols"
    )
    exception_class_drift = metadata_drift(
        product_atoms, diagnostic_atoms, ATOM_ID_FIELDS, "Exceptions"
    )
    exception_requirement_drift = metadata_drift(
        product_atoms, diagnostic_atoms, ATOM_ID_FIELDS, "ExceptionRequirementsNs"
    )
    exception_drift: list[dict[str, Any]] = []
    if exception_class_drift:
        exception_drift.append({"Field": "ExceptionClass", "Drift": exception_class_drift})
    if exception_requirement_drift:
        exception_drift.append(
            {"Field": "ExceptionRequirementNs", "Drift": exception_requirement_drift}
        )
    barrier_drift = metadata_drift(product_atoms, diagnostic_atoms, ATOM_ID_FIELDS, "Barriers")
    group_drift = metadata_drift(
        product_atoms, diagnostic_atoms, ATOM_ID_FIELDS, "ReplacementGroups"
    )
    atom_token_drift = metadata_drift(
        product_atoms, diagnostic_atoms, ATOM_ID_FIELDS, "GoverningTokens"
    )
    for code, drift in (
        ("PROTOCOL_DRIFT", protocol_drift),
        ("EXCEPTION_DRIFT", exception_drift),
        ("BARRIER_DRIFT", barrier_drift),
        ("REPLACEMENT_GROUP_DRIFT", group_drift),
        ("GOVERNING_TOKEN_DRIFT", atom_token_drift),
    ):
        if drift:
            add_blocker(blockers, code, drift)

    product_controls = index_records(product["GoverningControls"], CONTROL_ID_FIELDS)
    diagnostic_controls = index_records(diagnostic["GoverningControls"], CONTROL_ID_FIELDS)
    new_control_keys = sorted(set(diagnostic_controls) - set(product_controls))
    missing_control_keys = sorted(set(product_controls) - set(diagnostic_controls))
    control_drift: list[dict[str, Any]] = []
    if new_control_keys or missing_control_keys:
        control_drift.append(
            {
                "New": [
                    record_identity(diagnostic_controls[key], CONTROL_ID_FIELDS)
                    for key in new_control_keys
                ],
                "Missing": [
                    record_identity(product_controls[key], CONTROL_ID_FIELDS)
                    for key in missing_control_keys
                ],
            }
        )
    for field in ("GoverningTokens", "Protocols", "Barriers", "ReplacementGroups"):
        drift = metadata_drift(
            product_controls, diagnostic_controls, CONTROL_ID_FIELDS, field
        )
        if drift:
            control_drift.append({"Field": field, "Drift": drift})
    if control_drift:
        add_blocker(blockers, "GOVERNING_CONTROL_DRIFT", control_drift)

    product_virtual = index_records(product["VirtualControls"], CONTROL_ID_FIELDS)
    diagnostic_virtual = index_records(diagnostic["VirtualControls"], CONTROL_ID_FIELDS)
    virtual_control_drift: list[dict[str, Any]] = []
    new_virtual_keys = sorted(set(diagnostic_virtual) - set(product_virtual))
    missing_virtual_keys = sorted(set(product_virtual) - set(diagnostic_virtual))
    if new_virtual_keys or missing_virtual_keys:
        virtual_control_drift.append(
            {
                "New": [
                    record_identity(diagnostic_virtual[key], CONTROL_ID_FIELDS)
                    for key in new_virtual_keys
                ],
                "Missing": [
                    record_identity(product_virtual[key], CONTROL_ID_FIELDS)
                    for key in missing_virtual_keys
                ],
            }
        )
    for field in METADATA_FIELDS:
        drift = metadata_drift(
            product_virtual, diagnostic_virtual, CONTROL_ID_FIELDS, field
        )
        if drift:
            virtual_control_drift.append({"Field": field, "Drift": drift})
    if virtual_control_drift:
        add_blocker(blockers, "VIRTUAL_GOVERNING_CONTROL_DRIFT", virtual_control_drift)

    product_tokens = union_metadata(
        list(product["SupportAtoms"])
        + list(product["GoverningControls"])
        + list(product["VirtualControls"]),
        "GoverningTokens",
    )
    diagnostic_tokens = union_metadata(
        list(diagnostic["SupportAtoms"])
        + list(diagnostic["GoverningControls"])
        + list(diagnostic["VirtualControls"]),
        "GoverningTokens",
    )
    token_set_drift = {
        "New": sorted(set(diagnostic_tokens) - set(product_tokens)),
        "Missing": sorted(set(product_tokens) - set(diagnostic_tokens)),
    }
    if token_set_drift["New"] or token_set_drift["Missing"]:
        add_blocker(blockers, "GOVERNING_TOKEN_SET_DRIFT", token_set_drift)

    # Source-clock is part of the canonical atom key.  Keep an explicit
    # projection too because the mandatory 23-column CSV has no clock-drift column.
    def without_clock(atom: Mapping[str, Any]) -> tuple[str, ...]:
        return tuple(
            "" if atom.get(field) is None else str(atom.get(field))
            for field in ATOM_ID_FIELDS
            if field != "SourceClock"
        )

    product_clock_map: dict[tuple[str, ...], set[str]] = defaultdict(set)
    diagnostic_clock_map: dict[tuple[str, ...], set[str]] = defaultdict(set)
    for atom in product["SupportAtoms"]:
        product_clock_map[without_clock(atom)].add(atom["SourceClock"])
    for atom in diagnostic["SupportAtoms"]:
        diagnostic_clock_map[without_clock(atom)].add(atom["SourceClock"])
    source_clock_drift = []
    for key in sorted(set(product_clock_map) | set(diagnostic_clock_map)):
        if product_clock_map[key] != diagnostic_clock_map[key]:
            source_clock_drift.append(
                {
                    "IdentityWithoutSourceClock": list(key),
                    "Product": sorted(product_clock_map[key]),
                    "Diagnostic": sorted(diagnostic_clock_map[key]),
                }
            )
    if source_clock_drift:
        add_blocker(blockers, "SOURCE_CLOCK_DRIFT", source_clock_drift)

    row_proof_class = proof_class(contract["RowID"])
    if row_proof_class == "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE":
        require_same_family_contract(contract, product, diagnostic, blockers)
    elif row_proof_class == "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE":
        require_cross_critical(contract["DestinationEndpoint"], product, diagnostic, blockers)
    else:
        require_composite_warning(product, diagnostic, blockers)
        product_locals = index_records(product["LocalQualifiers"], CONTROL_ID_FIELDS)
        diagnostic_locals = index_records(diagnostic["LocalQualifiers"], CONTROL_ID_FIELDS)
        if set(product_locals) != set(diagnostic_locals):
            add_blocker(
                blockers,
                "COMPOSITE_LOCAL_QUALIFIER_DRIFT",
                {
                    "Product": identities(product["LocalQualifiers"], CONTROL_ID_FIELDS),
                    "Diagnostic": identities(diagnostic["LocalQualifiers"], CONTROL_ID_FIELDS),
                },
            )

    require_slot_state_release_alignment(
        contract["DestinationEndpoint"], product, diagnostic, blockers
    )

    blockers = sorted({compact_json(item): item for item in blockers}.values(), key=compact_json)
    unclassified = []
    for profile_name, normalized in (("product", product), ("diagnostic", diagnostic)):
        for record in normalized["ClassifiedStartpoints"]:
            if record["ClassificationStatus"] == "CLASSIFIED":
                continue
            unclassified.append(
                {
                    "Profile": profile_name,
                    "RowID": contract["RowID"],
                    "DestinationPin": contract["DestinationEndpoint"],
                    "ClockRelation": record["ClockRelation"],
                    "StartpointCell": record["PhysicalStartpoint"],
                    "StartpointClocks": record.get("SourceClock") or "",
                    "Reason": record["ClassificationStatus"],
                    "MatchedRuleIDs": compact_json(record.get("MatchedRuleIDs", [])),
                }
            )

    has_unclassified_cross = any(
        item["ClockRelation"] == "CROSS_CLOCK" for item in unclassified
    )
    if not blockers:
        disposition = "PASS"
    elif has_unclassified_cross:
        disposition = "FAIL — NVP_DIAG1_R2R1_UNCLASSIFIED_CROSS_CLOCK_SOURCE"
    else:
        disposition = "FAIL — NVP_DIAG1_R2R1_DESTINATION_SUPPORT_SET_MISMATCH"

    product_atom_identities = identities(product["SupportAtoms"], ATOM_ID_FIELDS)
    diagnostic_atom_identities = identities(diagnostic["SupportAtoms"], ATOM_ID_FIELDS)
    csv_row = {
        "RowID": contract["RowID"],
        "Rule": contract["Rule"],
        "Severity": contract["Severity"],
        "DestinationPin": contract["DestinationEndpoint"],
        "DestinationCell": product["Summary"]["DestinationCell"],
        "DestinationClock": contract["DestinationClock"],
        "ProductReportRepresentative": product["Summary"]["ReportRepresentative"],
        "DiagnosticReportRepresentative": diagnostic["Summary"]["ReportRepresentative"],
        "ProductPhysicalStartpoints": compact_json(
            sorted(row["StartpointCell"] for row in product["PhysicalStartpoints"])
        ),
        "DiagnosticPhysicalStartpoints": compact_json(
            sorted(row["StartpointCell"] for row in diagnostic["PhysicalStartpoints"])
        ),
        "ProductSemanticFamilies": compact_json(product_atom_identities),
        "DiagnosticSemanticFamilies": compact_json(diagnostic_atom_identities),
        "NewFamilies": compact_json(new_atoms),
        "MissingFamilies": compact_json(missing_atoms),
        "ProductGoverningTokens": compact_json(product_tokens),
        "DiagnosticGoverningTokens": compact_json(diagnostic_tokens),
        "ProtocolDrift": compact_json(protocol_drift) if protocol_drift else "0",
        "ExceptionDrift": compact_json(exception_drift) if exception_drift else "0",
        "BarrierDrift": compact_json(barrier_drift) if barrier_drift else "0",
        "ReplacementGroupDrift": compact_json(group_drift) if group_drift else "0",
        "ProofClass": row_proof_class,
        "Disposition": disposition,
        "EvidencePath": evidence_path,
    }
    detail = {
        "Classification": "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_ROW_EVIDENCE_V1",
        "RowAuthority": dict(contract),
        "InputSHA256": dict(input_hashes),
        "Raw": {
            "Product": {
                "Summary": product["Summary"],
                "PhysicalStartpoints": product["PhysicalStartpoints"],
            },
            "Diagnostic": {
                "Summary": diagnostic["Summary"],
                "PhysicalStartpoints": diagnostic["PhysicalStartpoints"],
            },
        },
        "Normalized": {
            "Product": {
                "ClassifiedStartpoints": product["ClassifiedStartpoints"],
                "SupportAtoms": product["SupportAtoms"],
                "GoverningControls": product["GoverningControls"],
                "VirtualControls": product["VirtualControls"],
                "LocalQualifiers": product["LocalQualifiers"],
                "LocalSameClockStartpoints": product["LocalSameClockStartpoints"],
                "Issues": product["Issues"],
            },
            "Diagnostic": {
                "ClassifiedStartpoints": diagnostic["ClassifiedStartpoints"],
                "SupportAtoms": diagnostic["SupportAtoms"],
                "GoverningControls": diagnostic["GoverningControls"],
                "VirtualControls": diagnostic["VirtualControls"],
                "LocalQualifiers": diagnostic["LocalQualifiers"],
                "LocalSameClockStartpoints": diagnostic["LocalSameClockStartpoints"],
                "Issues": diagnostic["Issues"],
            },
        },
        "Comparison": {
            "ProductSemanticAtoms": product_atom_identities,
            "DiagnosticSemanticAtoms": diagnostic_atom_identities,
            "NewAtoms": new_atoms,
            "MissingAtoms": missing_atoms,
            "ProductGoverningTokens": product_tokens,
            "DiagnosticGoverningTokens": diagnostic_tokens,
            "TokenSetDrift": token_set_drift,
            "AtomTokenDrift": atom_token_drift,
            "ProtocolDrift": protocol_drift,
            "ExceptionDrift": exception_drift,
            "ExceptionClassDrift": exception_class_drift,
            "ExceptionRequirementDrift": exception_requirement_drift,
            "BarrierDrift": barrier_drift,
            "ReplacementGroupDrift": group_drift,
            "GoverningControlDrift": control_drift,
            "VirtualGoverningControlDrift": virtual_control_drift,
            "SourceClockDrift": source_clock_drift,
            "ProofClass": row_proof_class,
            "Disposition": disposition,
            "Blockers": blockers,
        },
    }
    return csv_row, detail, unclassified


def write_csv(path: Path, fields: Sequence[str], rows: Iterable[Mapping[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="raise", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def output_relative(path: Path, task_root: Path) -> str:
    try:
        return path.resolve().relative_to(task_root.resolve()).as_posix()
    except ValueError as exc:
        raise GateFailure(f"output must remain below task root: {path}") from exc


def run(args: argparse.Namespace) -> int:
    task_root = args.task_root.resolve()
    contract_snap, contract_rows = load_contract(args.contract)
    rules = load_rules(args.rules, args.family_definitions, args.semantic_model)
    product = load_profile("product", args.product_dir, contract_rows)
    diagnostic = load_profile("diagnostic", args.diagnostic_dir, contract_rows)

    support_name = "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv"
    unknown_name = "G2B_NVP_VIDEO_DIAG1_R2R1_UNCLASSIFIED_STARTPOINTS.csv"
    evidence_manifest_name = "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_EVIDENCE_SHA256.txt"
    receipt_name = "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT.json"
    row_dir_name = "destination-cone-row-evidence"

    output_dir = args.output_dir.resolve()
    try:
        output_dir.relative_to(task_root)
    except ValueError as exc:
        raise GateFailure(f"output directory is outside the task root: {output_dir}") from exc
    if output_dir == task_root:
        raise GateFailure("output directory must be a child of the task root")
    owned_targets = [
        output_dir / support_name,
        output_dir / unknown_name,
        output_dir / evidence_manifest_name,
        output_dir / receipt_name,
        output_dir / row_dir_name,
    ]
    existing_targets = [str(path) for path in owned_targets if path.exists()]
    if existing_targets:
        raise GateFailure(f"comparer-owned output target already exists: {existing_targets}")

    input_hashes: dict[str, str] = {
        "ChangedDestinationsTSV": contract_snap.sha256,
        "SemanticRulesJSON": rules.snapshot.sha256,
        "SourceFamilyDefinitionsCSV": rules.authority_snapshots[0].sha256,
        "SemanticModelJSON": rules.authority_snapshots[1].sha256,
    }
    for prefix, profile in (("Product", product), ("Diagnostic", diagnostic)):
        for label, snap in profile.snapshots.items():
            input_hashes[f"{prefix}{label}"] = snap.sha256

    support_rows: list[dict[str, str]] = []
    details: list[tuple[str, dict[str, Any]]] = []
    unknown_rows: list[dict[str, str]] = []
    contract_by_id = {row["RowID"]: row for row in contract_rows}
    for row_id in [row["RowID"] for row in contract_rows]:
        contract = contract_by_id[row_id]
        product_normalized = normalize_profile_row(product, contract, rules)
        diagnostic_normalized = normalize_profile_row(diagnostic, contract, rules)
        evidence_file = output_dir / row_dir_name / f"{row_id}.json"
        evidence_path = output_relative(evidence_file, task_root)
        support_row, detail, row_unknowns = compare_row(
            contract,
            product_normalized,
            diagnostic_normalized,
            input_hashes,
            evidence_path,
        )
        support_rows.append(support_row)
        details.append((row_id, detail))
        unknown_rows.extend(row_unknowns)

    require_equal(len(support_rows), 522, "support output row count")
    proof_counts = Counter(row["ProofClass"] for row in support_rows)
    require_equal(dict(proof_counts), EXPECTED_PROOF_CLASS_COUNTS, "proof-class assignment counts")
    pass_rows = sum(row["Disposition"] == "PASS" for row in support_rows)
    pass_proof_counts = Counter(
        row["ProofClass"] for row in support_rows if row["Disposition"] == "PASS"
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    row_dir = output_dir / row_dir_name
    row_dir.mkdir()
    evidence_manifest_rows: list[dict[str, str]] = []
    for row_id, detail in details:
        path = row_dir / f"{row_id}.json"
        path.write_text(pretty_json(detail), encoding="utf-8", newline="\n")
        evidence_manifest_rows.append(
            {
                "RowID": row_id,
                "EvidencePath": output_relative(path, task_root),
                "SHA256": sha256_bytes(path.read_bytes()),
            }
        )

    support_path = output_dir / support_name
    unknown_path = output_dir / unknown_name
    evidence_manifest_path = output_dir / evidence_manifest_name
    write_csv(support_path, SUPPORT_FIELDS, support_rows)
    write_csv(unknown_path, UNKNOWN_FIELDS, sorted(unknown_rows, key=compact_json))
    evidence_manifest_path.write_text(
        "".join(
            f"{row['RowID']}={row['EvidencePath']}|{row['SHA256']}\n"
            for row in sorted(evidence_manifest_rows, key=lambda item: item["RowID"])
        ),
        encoding="utf-8",
        newline="\n",
    )

    result = "PASS" if pass_rows == 522 else "FAIL"
    aggregate_disposition = (
        "PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST_INPUT"
        if result == "PASS"
        else "FAIL — NVP_DIAG1_R2R1_DESTINATION_SUPPORT_SET_MISMATCH"
    )
    blocker_counts = Counter(
        blocker["Code"]
        for _, detail in details
        for blocker in detail["Comparison"]["Blockers"]
    )
    unclassified_cross = sum(
        row["ClockRelation"] == "CROSS_CLOCK" for row in unknown_rows
    )
    receipt = {
        "Classification": "G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT_V1",
        "Result": result,
        "Disposition": aggregate_disposition,
        "Rows": 522,
        "PassRows": pass_rows,
        "FailRows": 522 - pass_rows,
        "ProofClassCounts": dict(sorted(proof_counts.items())),
        "PassProofClassCounts": dict(sorted(pass_proof_counts.items())),
        "UnclassifiedCrossClockStartpoints": unclassified_cross,
        "UnknownOrAmbiguousStartpoints": len(unknown_rows),
        "BlockerCounts": dict(sorted(blocker_counts.items())),
        "InputSHA256": dict(sorted(input_hashes.items())),
        "OutputSHA256": {
            "DestinationConeSupportCSV": sha256_bytes(support_path.read_bytes()),
            "DestinationConeEvidenceSHA256": sha256_bytes(evidence_manifest_path.read_bytes()),
            "UnclassifiedStartpointsCSV": sha256_bytes(unknown_path.read_bytes()),
        },
        "PhysicalStartpointNamesComparedForEquivalence": False,
        "PhysicalStartpointMultiplicityComparedForEquivalence": False,
    }
    receipt_path = output_dir / receipt_name
    receipt_path.write_text(pretty_json(receipt), encoding="utf-8", newline="\n")

    if result == "PASS":
        print(f"R2R1_CONE_COMPARER_PASS={support_path}")
        print("ROWS=522")
        print("PROOF_CLASSES=512/7/3")
        return 0
    print(f"R2R1_CONE_COMPARER_FAIL={support_path}", file=sys.stderr)
    print(f"PASS_ROWS={pass_rows}", file=sys.stderr)
    print(f"FAIL_ROWS={522 - pass_rows}", file=sys.stderr)
    print(f"UNCLASSIFIED_CROSS_CLOCK_STARTPOINTS={unclassified_cross}", file=sys.stderr)
    return 2


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task-root", type=Path, default=TASK_ROOT)
    parser.add_argument(
        "--contract", type=Path, default=TASK_ROOT / "cone-proof" / "changed_destinations.tsv"
    )
    parser.add_argument(
        "--product-dir", type=Path, default=TASK_ROOT / "cone-proof" / "product"
    )
    parser.add_argument(
        "--diagnostic-dir", type=Path, default=TASK_ROOT / "cone-proof" / "diagnostic"
    )
    parser.add_argument(
        "--rules",
        type=Path,
        default=TASK_ROOT / "scripts" / "g2b_nvp_video_diag1_r2r1_semantic_rules.json",
    )
    parser.add_argument(
        "--family-definitions",
        type=Path,
        default=TASK_ROOT / "cdc" / "G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv",
    )
    parser.add_argument(
        "--semantic-model",
        type=Path,
        default=TASK_ROOT / "cdc" / "G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json",
    )
    parser.add_argument("--output-dir", type=Path, default=TASK_ROOT / "cdc")
    parser.add_argument(
        "--self-test-rules",
        action="store_true",
        help="validate only the explicit rule file; do not read extraction outputs",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        if args.self_test_rules:
            rules = load_rules(args.rules, args.family_definitions, args.semantic_model)
            print("R2R1_SEMANTIC_RULES_PASS")
            print(f"SHA256={rules.snapshot.sha256}")
            for authority in rules.authority_snapshots:
                print(f"AUTHORITY_SHA256={authority.path.name}:{authority.sha256}")
            print(f"FAMILY_RULES={len(rules.family_rules)}")
            print(f"CONTROL_RULES={len(rules.control_rules)}")
            return 0
        return run(args)
    except GateFailure as exc:
        print(f"R2R1_CONE_COMPARER_BLOCKED|{exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
