#!/usr/bin/env python3
"""
Fail-closed, row-level CDC reconciliation for AHD v41 G2B DIAG1-R2.

This task-local tool never edits RTL, XDC, DCPs, reports, or prior evidence.
It reads the two physical CDC authorities and proof receipts, writes only below
the R2 task root containing this script, and emits semantic manifests only when
every required gate passes.

The DCP cone-evidence JSON is intentionally strict.  When it is missing or
incomplete, the tool still writes the two row reconciliation CSVs, a precise
cone-evidence requirements JSON, and a FAIL summary, but no semantic manifest.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import re
import sys
from collections import Counter, defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


SCHEMA = "NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_V1"
SUMMARY_SCHEMA = "NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY_V1"
CONE_SCHEMA = "NVP_VIDEO_DIAG1_R2_DCP_CONE_EVIDENCE_V1"
CONE_REQUIREMENTS_SCHEMA = "NVP_VIDEO_DIAG1_R2_DCP_CONE_EVIDENCE_REQUIREMENTS_V1"
CLASSIFICATION = "PROFILE_SPECIFIC_DIAGNOSTIC_CDC_MANIFEST"
PASS_DISPOSITION = "PASS_PROFILE_SPECIFIC_SEMANTIC_MANIFEST"

EXPECTED_DCP_SHA256 = "45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F"
EXPECTED_RTL_SHA256 = "EB4A79608F1954440FA957C4F2571F6430DBD5DC89955B9CEC98B11AB171A97A"
EXPECTED_XDC_SHA256 = "9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE"
EXPECTED_PRODUCT_REPORT_SHA256 = "E53EF11E9A2F5FB1B03B0349203E9D220B999B415EF59B183AD59B6E71025A7E"
EXPECTED_STRUCTURAL_RECEIPT_SHA256 = "1B985C40100033C8A7B1C0E885382CF79DA8DDD5D8A908BA898E724ADB0F349E"

EXPECTED_PRODUCT_CDC1_SHA256 = "A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D"
EXPECTED_DIAGNOSTIC_CDC1_SHA256 = "BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99"
EXPECTED_CDC10_SHA256 = "1299D9C60B923DDD13CA4F773393AEB34906D46A96AB0A7139EB6A499A4E9D39"
EXPECTED_CDC13_SHA256 = "CF8C6175F013504F041F12CD9C4F56D549998EEAAA340B4BEBD56D6F005A0B18"
EXPECTED_PRODUCT_CRITICAL_ALL_SHA256 = "47E141801B3DA3494DE70C3941B4113FFFF52000001BD3D42D8D1B9AA21E69E2"

EXPECTED_COUNTS = {
    ("Critical", "CDC-1"): 423,
    ("Critical", "CDC-10"): 2,
    ("Critical", "CDC-13"): 2,
    ("Warning", "CDC-6"): 13,
    ("Warning", "CDC-15"): 861,
}
EXPECTED_CRITICAL_TOTAL = 427
EXPECTED_WARNING_TOTAL = 874
EXPECTED_CHANGED_CRITICAL = 302
EXPECTED_CHANGED_WARNING = 220

CRITICAL_CSV_NAME = "G2B_NVP_VIDEO_DIAG1_R2_CDC_CRITICAL_RECONCILIATION.csv"
WARNING_CSV_NAME = "G2B_NVP_VIDEO_DIAG1_R2_CDC_WARNING_RECONCILIATION.csv"
DESTINATION_CSV_NAME = "G2B_NVP_VIDEO_DIAG1_R2_CDC_DESTINATION_COMPARISON.csv"
FAMILY_CSV_NAME = "G2B_NVP_VIDEO_DIAG1_R2_SOURCE_FAMILY_DEFINITIONS.csv"
SUMMARY_TXT_NAME = "G2B_NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY.txt"
SUMMARY_JSON_NAME = "G2B_NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY.json"
CONE_REQUIREMENTS_NAME = "G2B_NVP_VIDEO_DIAG1_R2_DCP_CONE_EVIDENCE_REQUIREMENTS.json"

SEMANTIC_STEM = "NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V1"
SEMANTIC_ALIAS_STEM = "G2B_NVP_VIDEO_DIAG1_R2_SEMANTIC_CDC_MANIFEST"

RECONCILIATION_COLUMNS = [
    "RowID",
    "Rule",
    "Severity",
    "ProductPhysicalSource",
    "DiagnosticPhysicalSource",
    "SourceClock",
    "DestinationClock",
    "DestinationEndpoint",
    "Exception",
    "SemanticFamily",
    "OldBitIndex",
    "NewBitIndex",
    "StablePayloadProof",
    "GoverningToken",
    "ProtocolProof",
    "EarliestUseBarrier",
    "FaninFamilyProof",
    "DiagnosticBypassAbsent",
    "ReplacementGroup",
    "Disposition",
    "EvidencePath",
]

MANIFEST_COLUMNS = [
    "RowID",
    "MultiplicityIndex",
    "Rule",
    "Severity",
    "Description",
    "Depth",
    "SourceClock",
    "DestinationClock",
    "DestinationEndpoint",
    "ExceptionType",
    "SourceSemanticFamily",
    "StableDataProtocol",
    "GoverningTokenFamily",
    "ReplacementGroupOrCDCDisposition",
    "DiagnosticPhysicalSource",
    "ProductPhysicalSource",
    "PhysicalSourcesIdentical",
    "Disposition",
    "EvidencePath",
    "SemanticKeySHA256",
]

DIAGNOSTIC_HIERARCHY_TOKENS = (
    "g2b_nvp_video_diag",
    "current_result_word",
    "current_result_valid",
    "current_result_generation",
    "current_result_session",
    "host_owned_snapshot",
    "host-owned snapshot",
    "nvp_diagnostic_mmio",
    "nvp diagnostic mmio",
    "scan_fsm",
)

HEX64_RE = re.compile(r"^[0-9A-F]{64}$")


@dataclass(frozen=True)
class CDCRow:
    rule: str
    severity: str
    description: str
    depth: int
    exception: str
    source: str
    destination: str
    source_clock: str
    destination_clock: str

    def physical_key(self) -> tuple[Any, ...]:
        return (
            self.rule,
            self.severity,
            self.description,
            self.depth,
            self.source_clock,
            self.destination_clock,
            self.exception,
            self.source,
            self.destination,
        )

    def non_source_key(self) -> tuple[Any, ...]:
        return (
            self.rule,
            self.severity,
            self.description,
            self.depth,
            self.source_clock,
            self.destination_clock,
            self.exception,
            self.destination,
        )

    def canonical_physical(self) -> str:
        return (
            f"{self.rule}|{self.source_clock}->{self.destination_clock}|"
            f"{self.exception}|{self.source}|{self.destination}"
        )


@dataclass(frozen=True)
class Pair:
    product: CDCRow
    diagnostic: CDCRow
    changed: bool


@dataclass(frozen=True)
class SourceMatch:
    family: str
    index: str
    base: str


@dataclass(frozen=True)
class Candidate:
    family: str
    old_index: str
    new_index: str


@dataclass
class ProofResult:
    passed: bool
    disposition: str
    stable_payload_proof: str
    governing_token: str
    protocol_proof: str
    earliest_use_barrier: str
    fanin_family_proof: str
    diagnostic_bypass_absent: str
    replacement_group: str
    evidence_path: str
    semantic_errors: int = 0
    protocol_errors: int = 0
    replacement_errors: int = 0


FAMILY_DEFINITIONS: dict[str, dict[str, str]] = {
    "RESET_COMMIT_STABLE_PAYLOAD": {
        "AllowedPhysicalSourceBase": "G2B_ONECH_C2H/reset_commit_phase_hold_source_reg",
        "AllowedBitIndices": "0..3",
        "SourceClock": "nvp_vclk1",
        "PayloadMeaning": "per-slot reset commit completion phase held stable for AXI-domain observation",
        "PayloadWidth": "4",
        "GoverningRequestOrCompletionToken": "commit_sync2_axi[3:0]_completion_barrier",
        "AcknowledgementOrCompletionProtocol": "transport request/ack plus synchronized four-slot commit equality",
        "EarliestSemanticUseBarrier": "GROUP_13_EARLIEST_USE_GE_32NS_AND_6NS_SETTLING_CAP",
        "ExistingReplacementGroup": "GROUP_13_CHECK_5_RESET_COMMIT_PHASE_COMPLETION_BARRIER",
        "ExistingAuthorityEvidence": (
            r"C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit"
            r"\G2B_G13A_RESET_SEMANTIC_PROOF.md"
        ),
    },
    "RESET_ABANDONED_COUNT_STABLE_PAYLOAD": {
        "AllowedPhysicalSourceBase": "G2B_ONECH_C2H/reset_abandoned_hold_source_reg",
        "AllowedBitIndices": "0..2",
        "SourceClock": "nvp_vclk1",
        "PayloadMeaning": "reset-overlap abandoned-record count held stable for AXI-domain accounting",
        "PayloadWidth": "3",
        "GoverningRequestOrCompletionToken": "transport_ack_sync2_axi_and_commit_sync2_axi_completion",
        "AcknowledgementOrCompletionProtocol": "transport request/ack plus synchronized commit completion",
        "EarliestSemanticUseBarrier": "GROUP_13_EARLIEST_USE_GE_32NS_AND_6NS_SETTLING_CAP",
        "ExistingReplacementGroup": "GROUP_13_CHECK_4_RESET_ABANDONED_COUNT_STABLE_PAYLOAD",
        "ExistingAuthorityEvidence": (
            r"C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit"
            r"\G2B_G13A_RESET_SEMANTIC_PROOF.md"
        ),
    },
    "OWNERSHIP_STABLE_PAYLOAD": {
        "AllowedPhysicalSourceBase": "G2B_ONECH_C2H/axis_slot_reg",
        "AllowedBitIndices": "0..1",
        "SourceClock": "userclk1",
        "PayloadMeaning": "ownership token slot field held with generation and epoch until returned acknowledgement",
        "PayloadWidth": "2_of_58_bit_ownership_token",
        "GoverningRequestOrCompletionToken": "own_req_toggle_axi_to_own_req_sync2_source",
        "AcknowledgementOrCompletionProtocol": "own_ack_toggle_source_to_own_ack_sync2_axi",
        "EarliestSemanticUseBarrier": "GROUP_9_EARLIEST_USE_13.468NS_AND_6NS_SETTLING_CAP",
        "ExistingReplacementGroup": "GROUP_9_CHECKS_1_TO_3_OWNERSHIP_MAILBOX",
        "ExistingAuthorityEvidence": (
            r"C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof"
            r"\G2B_BS3_STRUCTURAL_CDC_PROOF.md"
        ),
    },
    "DESCRIPTOR_EPOCH_STABLE_PAYLOAD": {
        "AllowedPhysicalSourceBase": "G2B_ONECH_C2H/desc_epoch_source_reg",
        "AllowedBitIndices": "slot=0..3,bit=0..31",
        "SourceClock": "nvp_vclk1",
        "PayloadMeaning": "per-slot descriptor epoch returned to the AXI domain under descriptor completion",
        "PayloadWidth": "32_per_slot",
        "GoverningRequestOrCompletionToken": "descriptor_commit_completion_token",
        "AcknowledgementOrCompletionProtocol": "source descriptor completion followed by AXI-domain capture",
        "EarliestSemanticUseBarrier": "ACTIVE_GROUP_12_3NS_BUS_SKEW_AND_EXISTING_PROTOCOL_BARRIER",
        "ExistingReplacementGroup": "ACTIVE_GROUP_12_DESCRIPTOR_EPOCH_SOURCE_TO_AXI",
        "ExistingAuthorityEvidence": (
            r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z\reports\vivado_full"
            r"\BUS_SKEW_GROUPS\12_DESCRIPTOR_EPOCH_SOURCE_TO_AXI_BUS_SKEW.rpt"
        ),
    },
    "RELEASE_SLOT_STABLE_PAYLOAD": {
        "AllowedPhysicalSourceBase": "G2B_ONECH_C2H/release_generation_axi_reg",
        "AllowedBitIndices": "slot=0..3,bit=0..23",
        "SourceClock": "userclk1",
        "PayloadMeaning": "per-slot release generation field held stable with release epoch",
        "PayloadWidth": "24_of_56_bit_release_token_per_slot",
        "GoverningRequestOrCompletionToken": "release_toggle_axi[slot]_to_release_sync2_source[slot]",
        "AcknowledgementOrCompletionProtocol": "per-slot release-toggle stable-data transfer",
        "EarliestSemanticUseBarrier": "GROUPS_14_TO_17_EARLIEST_USE_13.468NS_AND_6NS_SETTLING_CAP",
        "ExistingReplacementGroup": "GROUPS_14_TO_17_RELEASE_SLOT_CHECKS",
        "ExistingAuthorityEvidence": (
            r"C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g15-17-release-slot-equivalence-audit"
            r"\G2B_G15_17_EQ_STRUCTURAL_EQUIVALENCE_MATRIX.csv"
        ),
    },
    "RELEASE_EPOCH_STABLE_PAYLOAD": {
        "AllowedPhysicalSourceBase": "G2B_ONECH_C2H/release_epoch_axi_reg",
        "AllowedBitIndices": "slot=0..3,bit=0..31",
        "SourceClock": "userclk1",
        "PayloadMeaning": "per-slot release epoch field held stable with release generation",
        "PayloadWidth": "32_of_56_bit_release_token_per_slot",
        "GoverningRequestOrCompletionToken": "release_toggle_axi[slot]_to_release_sync2_source[slot]",
        "AcknowledgementOrCompletionProtocol": "per-slot release-toggle stable-data transfer",
        "EarliestSemanticUseBarrier": "GROUPS_14_TO_17_EARLIEST_USE_13.468NS_AND_6NS_SETTLING_CAP",
        "ExistingReplacementGroup": "GROUPS_14_TO_17_RELEASE_SLOT_CHECKS",
        "ExistingAuthorityEvidence": (
            r"C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g14a-release-slot0-signoff-audit"
            r"\G2B_G14A_CDC_PROTOCOL_PROOF.md"
        ),
    },
}


PROHIBITED_CRITICAL_CROSS_BASE_DESTINATIONS = frozenset(
    {
        "G2B_ONECH_C2H/enable_applied_source_reg/D",
        "G2B_ONECH_C2H/slot_state_source_reg[0][0]/D",
        "G2B_ONECH_C2H/slot_state_source_reg[0][1]/D",
        "G2B_ONECH_C2H/slot_state_source_reg[0][2]/D",
        "G2B_ONECH_C2H/source_ownership_fatal_deferred_reg/D",
        "G2B_ONECH_C2H/source_ownership_fatal_event_reg/D",
        "G2B_ONECH_C2H/source_ownership_fatal_reg/D",
    }
)

PROHIBITED_WARNING_CROSS_BASE_TUPLES = frozenset(
    {
        (
            "G2B_ONECH_C2H/release_generation_axi_reg[3][2]/C",
            "G2B_ONECH_C2H/release_epoch_axi_reg[2][8]/C",
            "G2B_ONECH_C2H/reset_abandoned_hold_source_reg[0]/D",
        ),
        (
            "G2B_ONECH_C2H/release_generation_axi_reg[0][0]/C",
            "G2B_ONECH_C2H/release_epoch_axi_reg[2][8]/C",
            "G2B_ONECH_C2H/reset_abandoned_hold_source_reg[1]/D",
        ),
        (
            "G2B_ONECH_C2H/release_generation_axi_reg[0][0]/C",
            "G2B_ONECH_C2H/release_epoch_axi_reg[2][8]/C",
            "G2B_ONECH_C2H/reset_abandoned_hold_source_reg[2]/D",
        ),
    }
)


EXPECTED_REPLACEMENT_ROWS: dict[int, tuple[str, ...]] = {
    1: ("9", "OWNERSHIP_SLOT_SETTLING", "2", "17", "6.000", "5.505", "0.528", "PASS",
        "FD736A33AE93614D66EE39A23902D56CB5741FE66ACBF43414882D0864122359",
        "B46DAE7B170E57500FE15C37EE984681FE91AABD6BC7BAFEC722B661F3903E73"),
    2: ("9", "OWNERSHIP_GENERATION_SETTLING", "24", "17", "6.000", "4.564", "1.469", "PASS",
        "7C10E2E7F859C1DF9488CDA2D2C25CE79FE73246B8E580AB87980A2F3C069EED",
        "EC5046ADE082619328E4B42C3247BEF6EA3A27E5A61ECE4646CFA06E84F002C5"),
    3: ("9", "OWNERSHIP_EPOCH_SETTLING", "32", "17", "6.000", "5.259", "0.774", "PASS",
        "965A99684AFC7C43E603AC71DF80064C1A51AB7388D20BFBD4D3E83403BF6690",
        "08B06DE34850B175DC2322EE0CF3F66111D06E40FBB35F7253CE323B4ECA0D26"),
    4: ("13", "RESET_ABANDONED_COUNT_STABLE_PAYLOAD", "3", "32", "6.000", "3.218", "2.883", "PASS",
        "6CD1F0356EE512A0F67EC3DF6D773B4BD3EF89A58DE89E7F24A18B814E4094D2",
        "D355108B0BC73440A53F84F7606EB3B944FD1EF705C776EF2282EF25549483FD"),
    5: ("13", "RESET_COMMIT_PHASE_COMPLETION_BARRIER", "4", "207", "6.000", "4.458", "1.572", "PASS",
        "1E444231AB9DD54E53C659AD28729F28021265C750E1AE5F6DE8B261CD6170E3",
        "A6141696B1DF179F6E6D826274049524330B75EC42FC697F40590737DAC8F4A7"),
    6: ("14", "RELEASE_SLOT0_NORMAL_STATE_TRANSITION", "56", "3", "6.000", "5.324", "0.706", "PASS",
        "8F0910869035E695E3A96F797C490C888AC0BF19315763E605BACC2635710686",
        "A289A2EF69ECF86321C50A4BB0E0051EC78038788DFCBB9BBFA2CC5981BC5468"),
    7: ("14", "RELEASE_SLOT0_MISMATCH_CONTAINMENT", "56", "4", "6.000", "5.120", "0.913", "PASS",
        "6B184A21E7D052E644E3A3DED42C741FFABA81D717E34219A16E55B9152A8C14",
        "7B608CEC5F8816ADEEFFAA92418706F02F5604F57821B7C08677AFCEF383CAA8"),
    8: ("14", "RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING", "56", "3", "6.000", "4.147", "1.883", "PASS",
        "68ECE7F544480FD478BB0025CAEAC40F9BAB0DDE2793A5C9D528004C92C86609",
        "0927E35A670FDA05E9F92A6F9CE70F03B368FB8B1CF75BB75B99E6D60670D9A0"),
    9: ("15", "RELEASE_SLOT1_NORMAL_STATE_TRANSITION", "56", "3", "6.000", "5.458", "0.574", "PASS",
        "233145619749C206E45F24C1D3FB47B64250E978CFD342110C5407B56B7FA6B3",
        "5F6EABCC85467F66426C31CDC1741E340C910F9EBBEE6C7CFA241FC005BBC0FA"),
    10: ("15", "RELEASE_SLOT1_MISMATCH_CONTAINMENT", "56", "4", "6.000", "5.453", "0.580", "PASS",
         "6F0A6EF3DA043888F9BB205E36BFB9BC1302CD7232D869365BCEB629D38BB5B2",
         "2B4D6DD69BB4E9F1CF7EEFF357C765149CAB89BB682EEC019A8EC7DBBF5262D7"),
    11: ("15", "RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING", "56", "3", "6.000", "4.415", "1.615", "PASS",
         "182A9DFC320BC7D553270F3C38A08347C38833B1CBFE286550025BE53D5219D4",
         "1A3D1370F97752C68386CE7A3567DF983A8B03CA94B8049C8DDA44C5275A4DB6"),
    12: ("16", "RELEASE_SLOT2_NORMAL_STATE_TRANSITION", "56", "3", "6.000", "5.537", "0.495", "PASS",
         "A7651DB1DE33A9E05003E2918F45C758AAC5B01619598C0FDAB64AC8933BF861",
         "1C80D4B5F79AA087B12DD96DE9A1C5FD61510CC56ACBD6383E16F3889849BE04"),
    13: ("16", "RELEASE_SLOT2_MISMATCH_CONTAINMENT", "56", "4", "6.000", "5.025", "1.008", "PASS",
         "B47A8EDEA180C83F330F87971379E001C9B57922D6132D2E4AEAE64F15BD2951",
         "C738C63A76AA82DBA468FD98144963B7A429D93FF2E49FF16BF8144F6F072527"),
    14: ("16", "RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING", "56", "3", "6.000", "4.582", "1.448", "PASS",
         "65050C082F277A8A1AE8B9C72CBF9A0E978432E3EF5A05D9907F221778B93694",
         "D8EB5975E2E81E51B6EAE0DD89B6158FBB0B7699165D420BF2500CC847FE876E"),
    15: ("17", "RELEASE_SLOT3_NORMAL_STATE_TRANSITION", "56", "3", "6.000", "5.558", "0.472", "PASS",
         "E613F0F893CC756A3A72B8666691FD8FD57FBB38E18A61FC943D62BB58AE0451",
         "7138853A997254595B85CD664E5178CEAFAE899C41EF1F033805C95729D149BD"),
    16: ("17", "RELEASE_SLOT3_MISMATCH_CONTAINMENT", "56", "4", "6.000", "5.280", "0.753", "PASS",
         "B4B66A735506FEC3C7600CEE7E48421CA3BA31FDAA8DEC098294AB694520804D",
         "757A4119D3F9DAA8BF6F22DBA3E3C647C2342D1250AFFC783F3A21EEC6EDC903"),
    17: ("17", "RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING", "56", "3", "6.000", "4.470", "1.560", "PASS",
         "EF8D6CC86328185F754F151735D157E9834B95EA71F233D09ED049C545296C41",
         "4F7ADEA75561E56E14EE5287CE9ED13767279D85C0D0DF5EA6E9AE07832D3C95"),
}

REPLACEMENT_FIELDS = (
    "Group",
    "Family",
    "SourceCount",
    "DestinationCount",
    "RequiredNs",
    "DatapathDelayNs",
    "SlackNs",
    "Result",
    "ReportSHA256",
    "ObjectsSHA256",
)

PROOF_BOOLEAN_FIELDS = (
    "SourceClockIdentityProven",
    "StablePayloadMembershipProven",
    "GoverningTokenEquivalent",
    "EarliestUseBarrierEquivalent",
    "CompleteFaninFamilyEquivalent",
    "DirectBypassAbsent",
    "DiagnosticHierarchyAbsent",
    "ReplacementOrStructuralCheckPass",
)

FIXED_EVIDENCE_ROLES = (
    "PRODUCT_CDC_AUTHORITY",
    "RTL_PROTOCOL",
    "XDC_CONSTRAINT",
    "STRUCTURAL_CDC",
    "REPLACEMENT_CHECK",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def canonical_sha(rows: Iterable[CDCRow]) -> str:
    lines = sorted(row.canonical_physical() for row in rows)
    return sha256_bytes(("".join(line + "\n" for line in lines)).encode("utf-8"))


def write_text(path: Path, text: str) -> str:
    data = text.replace("\r\n", "\n").replace("\r", "\n").encode("utf-8")
    if data and not data.endswith(b"\n"):
        data += b"\n"
    path.write_bytes(data)
    return sha256_bytes(data)


def csv_bytes(columns: Sequence[str], rows: Iterable[Mapping[str, Any]]) -> bytes:
    buffer = io.StringIO(newline="")
    writer = csv.DictWriter(buffer, fieldnames=list(columns), extrasaction="ignore", lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow({name: row.get(name, "") for name in columns})
    return buffer.getvalue().encode("utf-8")


def write_csv(path: Path, columns: Sequence[str], rows: Iterable[Mapping[str, Any]]) -> str:
    data = csv_bytes(columns, rows)
    path.write_bytes(data)
    return sha256_bytes(data)


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=True) + "\n").encode("utf-8")


def write_json(path: Path, value: Any) -> str:
    data = json_bytes(value)
    path.write_bytes(data)
    return sha256_bytes(data)


def normalize_path(path: Path) -> str:
    return os.path.normcase(str(path.resolve()))


def path_within(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def require_file(raw: str, label: str, errors: list[str]) -> Path:
    path = Path(raw).resolve()
    if not path.is_file():
        errors.append(f"{label} is not a readable file: {path}")
    return path


def parse_cdc_report(path: Path) -> tuple[list[CDCRow], str]:
    raw = path.read_bytes()
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise ValueError(f"CDC report is not UTF-8/ASCII: {path}: {exc}") from exc

    source_clock: str | None = None
    destination_clock: str | None = None
    rows: list[CDCRow] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if line.startswith("Source Clock:"):
            source_clock = line.split(":", 1)[1].strip()
            continue
        if line.startswith("Destination Clock:"):
            destination_clock = line.split(":", 1)[1].strip()
            continue
        stripped = line.strip()
        if not re.match(r"^\d+\s+CDC-\d+\s+", stripped):
            continue
        parts = re.split(r"\s{2,}", stripped)
        if len(parts) != 8:
            raise ValueError(
                f"unparsed CDC detail row at {path}:{line_number}; expected 8 columns, got {len(parts)}: {stripped}"
            )
        report_row, rule, severity, description, depth_text, exception, source, destination = parts
        if not report_row.isdigit() or not re.fullmatch(r"CDC-\d+", rule):
            raise ValueError(f"invalid CDC row identity at {path}:{line_number}: {stripped}")
        if severity not in {"Critical", "Warning", "Info", "Unknown", "Critical Warning"}:
            raise ValueError(f"unrecognized severity at {path}:{line_number}: {severity}")
        if not depth_text.isdigit():
            raise ValueError(f"invalid CDC depth at {path}:{line_number}: {depth_text}")
        if not source_clock or not destination_clock:
            raise ValueError(f"CDC row lacks clock context at {path}:{line_number}")
        if any(ch.isspace() for ch in source) or any(ch.isspace() for ch in destination):
            raise ValueError(f"endpoint contains whitespace at {path}:{line_number}")
        rows.append(
            CDCRow(
                rule=rule,
                severity=severity,
                description=description,
                depth=int(depth_text),
                exception=exception,
                source=source,
                destination=destination,
                source_clock=source_clock,
                destination_clock=destination_clock,
            )
        )
    if not rows:
        raise ValueError(f"no detailed CDC rows parsed from {path}")
    return rows, text


def pair_reports(product_rows: Sequence[CDCRow], diagnostic_rows: Sequence[CDCRow]) -> tuple[list[Pair], list[str]]:
    product_groups: dict[tuple[Any, ...], list[CDCRow]] = defaultdict(list)
    diagnostic_groups: dict[tuple[Any, ...], list[CDCRow]] = defaultdict(list)
    for row in product_rows:
        product_groups[row.non_source_key()].append(row)
    for row in diagnostic_rows:
        diagnostic_groups[row.non_source_key()].append(row)

    errors: list[str] = []
    pairs: list[Pair] = []
    for key in sorted(set(product_groups) | set(diagnostic_groups), key=repr):
        old = product_groups.get(key, [])
        new = diagnostic_groups.get(key, [])
        if len(old) != len(new):
            errors.append(
                "non-source row multiplicity drift for "
                f"{key!r}: product={len(old)} diagnostic={len(new)}"
            )
        old_by_source = Counter(row.source for row in old)
        new_by_source = Counter(row.source for row in new)
        exact = old_by_source & new_by_source
        old_template = {row.source: row for row in old}
        new_template = {row.source: row for row in new}
        for source in sorted(exact):
            for _ in range(exact[source]):
                pairs.append(Pair(old_template[source], new_template[source], False))
        old_remaining: list[CDCRow] = []
        new_remaining: list[CDCRow] = []
        for source, count in (old_by_source - exact).items():
            old_remaining.extend([old_template[source]] * count)
        for source, count in (new_by_source - exact).items():
            new_remaining.extend([new_template[source]] * count)
        old_remaining.sort(key=lambda row: row.source)
        new_remaining.sort(key=lambda row: row.source)
        for old_row, new_row in zip(old_remaining, new_remaining):
            pairs.append(Pair(old_row, new_row, True))
    pairs.sort(
        key=lambda pair: (
            pair.diagnostic.severity,
            pair.diagnostic.rule,
            pair.diagnostic.source_clock,
            pair.diagnostic.destination_clock,
            pair.diagnostic.destination,
            pair.product.source,
            pair.diagnostic.source,
            pair.diagnostic.description,
            pair.diagnostic.depth,
            pair.diagnostic.exception,
        )
    )
    return pairs, errors


SOURCE_PATTERNS: tuple[tuple[str, re.Pattern[str], Any], ...] = (
    (
        "RESET_COMMIT_STABLE_PAYLOAD",
        re.compile(r"^G2B_ONECH_C2H/reset_commit_phase_hold_source_reg\[(\d+)\]/C$"),
        lambda m: m.group(1),
    ),
    (
        "RESET_ABANDONED_COUNT_STABLE_PAYLOAD",
        re.compile(r"^G2B_ONECH_C2H/reset_abandoned_hold_source_reg\[(\d+)\]/C$"),
        lambda m: m.group(1),
    ),
    (
        "OWNERSHIP_STABLE_PAYLOAD",
        re.compile(r"^G2B_ONECH_C2H/axis_slot_reg\[(\d+)\]/C$"),
        lambda m: m.group(1),
    ),
    (
        "DESCRIPTOR_EPOCH_STABLE_PAYLOAD",
        re.compile(r"^G2B_ONECH_C2H/desc_epoch_source_reg\[(\d+)\]\[(\d+)\]/C$"),
        lambda m: f"slot={m.group(1)},bit={m.group(2)}",
    ),
    (
        "RELEASE_SLOT_STABLE_PAYLOAD",
        re.compile(r"^G2B_ONECH_C2H/release_generation_axi_reg\[(\d+)\]\[(\d+)\]/C$"),
        lambda m: f"slot={m.group(1)},bit={m.group(2)}",
    ),
    (
        "RELEASE_EPOCH_STABLE_PAYLOAD",
        re.compile(r"^G2B_ONECH_C2H/release_epoch_axi_reg\[(\d+)\]\[(\d+)\]/C$"),
        lambda m: f"slot={m.group(1)},bit={m.group(2)}",
    ),
)


def source_match(source: str) -> SourceMatch | None:
    for family, expression, formatter in SOURCE_PATTERNS:
        match = expression.fullmatch(source)
        if match:
            return SourceMatch(family=family, index=str(formatter(match)), base=expression.pattern)
    return None


def classify_changed(pair: Pair) -> Candidate | None:
    old_match = source_match(pair.product.source)
    new_match = source_match(pair.diagnostic.source)
    if old_match and new_match and old_match.family == new_match.family:
        return Candidate(old_match.family, old_match.index, new_match.index)
    return None


def prohibited_source_base_drift(pair: Pair) -> tuple[bool, str, str]:
    """Return exact cross-base drift classification; proof cannot override it."""
    old_match = source_match(pair.product.source)
    new_match = source_match(pair.diagnostic.source)
    old_family = old_match.family if old_match else "UNKNOWN_SOURCE_FAMILY"
    new_family = new_match.family if new_match else "UNKNOWN_SOURCE_FAMILY"
    if old_family != new_family:
        return True, old_family, new_family
    return False, old_family, new_family


def semantic_key_sha(record: Mapping[str, Any]) -> str:
    keys = (
        "Rule",
        "Severity",
        "SourceClock",
        "DestinationClock",
        "DestinationEndpoint",
        "ExceptionType",
        "SourceSemanticFamily",
        "StableDataProtocol",
        "GoverningTokenFamily",
        "ReplacementGroupOrCDCDisposition",
    )
    line = "|".join(str(record.get(key, "")) for key in keys) + "\n"
    return sha256_bytes(line.encode("utf-8"))


def validate_replacement_receipt(path: Path) -> list[str]:
    errors: list[str] = []
    expected_header = [
        "CheckIndex",
        "Group",
        "Family",
        "SourceCount",
        "DestinationCount",
        "RequiredNs",
        "DatapathDelayNs",
        "SlackNs",
        "RuntimeMs",
        "Result",
        "ReportSHA256",
        "ObjectsSHA256",
    ]
    try:
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if reader.fieldnames != expected_header:
                return [f"replacement receipt header drift: {reader.fieldnames!r}"]
            rows = list(reader)
    except Exception as exc:
        return [f"replacement receipt parse failure: {exc}"]
    if len(rows) != 17:
        errors.append(f"replacement check count drift: expected=17 actual={len(rows)}")
    seen: set[int] = set()
    for row in rows:
        try:
            index = int(row["CheckIndex"])
        except (TypeError, ValueError):
            errors.append(f"invalid replacement CheckIndex: {row.get('CheckIndex')!r}")
            continue
        if index in seen:
            errors.append(f"duplicate replacement CheckIndex: {index}")
            continue
        seen.add(index)
        expected = EXPECTED_REPLACEMENT_ROWS.get(index)
        if expected is None:
            errors.append(f"unexpected replacement CheckIndex: {index}")
            continue
        actual = tuple(row[field] for field in REPLACEMENT_FIELDS)
        if actual != expected:
            errors.append(
                f"replacement check {index} semantic/hash drift: expected={expected!r} actual={actual!r}"
            )
        if not str(row["RuntimeMs"]).isdigit():
            errors.append(f"replacement check {index} invalid RuntimeMs: {row['RuntimeMs']!r}")
    missing = sorted(set(EXPECTED_REPLACEMENT_ROWS) - seen)
    if missing:
        errors.append(f"missing replacement checks: {missing}")
    expected_groups = Counter({"9": 3, "13": 2, "14": 3, "15": 3, "16": 3, "17": 3})
    actual_groups = Counter(row.get("Group", "") for row in rows)
    if actual_groups != expected_groups:
        errors.append(f"replacement group distribution drift: expected={expected_groups} actual={actual_groups}")
    return errors


def validate_hash(label: str, actual: str, expected: str, errors: list[str]) -> None:
    if actual != expected:
        errors.append(f"{label} SHA256 drift: expected={expected} actual={actual}")


def counter_symdiff(left: Counter[Any], right: Counter[Any]) -> int:
    return sum((left - right).values()) + sum((right - left).values())


def rows_of(rows: Sequence[CDCRow], severity: str | None = None, rule: str | None = None) -> list[CDCRow]:
    return [
        row
        for row in rows
        if (severity is None or row.severity == severity) and (rule is None or row.rule == rule)
    ]


def physical_intersection_count(product: Sequence[CDCRow], diagnostic: Sequence[CDCRow]) -> int:
    return sum((Counter(row.physical_key() for row in product) & Counter(row.physical_key() for row in diagnostic)).values())


def make_row_id(prefix: str, index: int) -> str:
    return f"{prefix}-{index:04d}"


def proof_identity(pair: Pair, candidate: Candidate, row_id: str) -> dict[str, Any]:
    return {
        "RowID": row_id,
        "Rule": pair.diagnostic.rule,
        "Severity": pair.diagnostic.severity,
        "ProductPhysicalSource": pair.product.source,
        "DiagnosticPhysicalSource": pair.diagnostic.source,
        "SourceClock": pair.diagnostic.source_clock,
        "DestinationClock": pair.diagnostic.destination_clock,
        "DestinationEndpoint": pair.diagnostic.destination,
        "Exception": pair.diagnostic.exception,
        "SemanticFamily": candidate.family,
        "OldBitIndex": candidate.old_index,
        "NewBitIndex": candidate.new_index,
    }


def cone_requirement_record(pair: Pair, candidate: Candidate | None, row_id: str) -> dict[str, Any]:
    family = candidate.family if candidate else "UNRECONCILED_SOURCE_FAMILY"
    record: dict[str, Any] = {
        "RowID": row_id,
        "Rule": pair.diagnostic.rule,
        "Severity": pair.diagnostic.severity,
        "ProductPhysicalSource": pair.product.source,
        "DiagnosticPhysicalSource": pair.diagnostic.source,
        "SourceClock": pair.diagnostic.source_clock,
        "DestinationClock": pair.diagnostic.destination_clock,
        "DestinationEndpoint": pair.diagnostic.destination,
        "Exception": pair.diagnostic.exception,
        "SemanticFamily": family,
        "OldBitIndex": candidate.old_index if candidate else "",
        "NewBitIndex": candidate.new_index if candidate else "",
        "RequiredExactProofLiterals": {
            "StablePayloadProof": "PASS_EXACT_STABLE_PAYLOAD_MEMBERSHIP",
            "FaninFamilyProof": "PASS_COMPLETE_FANIN_FAMILY_EQUIVALENCE",
            "DiagnosticBypassAbsent": "PASS_NO_DIRECT_BYPASS_OR_DIAGNOSTIC_HIERARCHY",
            "Disposition": "PASS_RECONCILED",
        },
        "RequiredTrueFields": list(PROOF_BOOLEAN_FIELDS),
        "RequiredEvidenceRoles": list(FIXED_EVIDENCE_ROLES) + ["DIAGNOSTIC_DCP_CONE_QUERY"],
        "RequiredConeSignatures": [
            "ProductConeSHA256",
            "DiagnosticConeSHA256",
            "ProductNormalizedSemanticConeSHA256",
            "DiagnosticNormalizedSemanticConeSHA256",
        ],
    }
    if candidate:
        definition = FAMILY_DEFINITIONS[candidate.family]
        record["GoverningToken"] = definition["GoverningRequestOrCompletionToken"]
        record["ProtocolProof"] = definition["AcknowledgementOrCompletionProtocol"]
        record["EarliestUseBarrier"] = definition["EarliestSemanticUseBarrier"]
        record["ReplacementGroup"] = definition["ExistingReplacementGroup"]
    else:
        is_base_drift, old_family, new_family = prohibited_source_base_drift(pair)
        if is_base_drift:
            record["RequiredExactProofLiterals"] = {}
            record["RequiredTrueFields"] = []
            record["RequiredEvidenceRoles"] = []
            record["RequiredConeSignatures"] = []
            record["NonOverridableFailure"] = {
                "FailureLiteral": "NVP_DIAG1_R2_PROHIBITED_SOURCE_BASE_DRIFT",
                "ProductSourceFamily": old_family,
                "DiagnosticSourceFamily": new_family,
                "ProofCanOverride": False,
                "Contract": (
                    "PROMPT_SECTION_4_AND_13_DIFFERENT_SOURCE_BASE_NORMALIZATION_PROHIBITED"
                ),
            }
    return record


def load_cone_evidence(path: Path | None, errors: list[str]) -> tuple[dict[str, Any] | None, dict[str, dict[str, Any]]]:
    if path is None:
        errors.append("DCP cone evidence JSON was not supplied")
        return None, {}
    try:
        document = json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:
        errors.append(f"DCP cone evidence JSON parse failure: {exc}")
        return None, {}
    if not isinstance(document, dict):
        errors.append("DCP cone evidence top level is not an object")
        return None, {}
    rows = document.get("Rows")
    if not isinstance(rows, list):
        errors.append("DCP cone evidence Rows is not an array")
        return document, {}
    by_id: dict[str, dict[str, Any]] = {}
    for item in rows:
        if not isinstance(item, dict):
            errors.append("DCP cone evidence contains a non-object row")
            continue
        row_id = item.get("RowID")
        if not isinstance(row_id, str) or not row_id:
            errors.append("DCP cone evidence row lacks RowID")
            continue
        if row_id in by_id:
            errors.append(f"duplicate DCP cone evidence RowID: {row_id}")
            continue
        by_id[row_id] = item
    return document, by_id


def validate_evidence_files(
    proof: Mapping[str, Any],
    candidate: Candidate,
    fixed_paths: Mapping[str, tuple[Path, str]],
    task_root: Path,
) -> tuple[list[str], str]:
    errors: list[str] = []
    evidence = proof.get("Evidence")
    if not isinstance(evidence, list):
        return ["Evidence is not an array"], ""
    by_role: dict[str, dict[str, Any]] = {}
    rendered: list[str] = []
    for item in evidence:
        if not isinstance(item, dict):
            errors.append("Evidence contains a non-object entry")
            continue
        role = item.get("Role")
        raw_path = item.get("Path")
        expected_sha = item.get("SHA256")
        if not isinstance(role, str) or not role:
            errors.append("Evidence entry lacks Role")
            continue
        if role in by_role:
            errors.append(f"duplicate Evidence role: {role}")
            continue
        by_role[role] = item
        if not isinstance(raw_path, str) or not raw_path:
            errors.append(f"Evidence role {role} lacks Path")
            continue
        path = Path(raw_path).resolve()
        if not path.is_file():
            errors.append(f"Evidence role {role} path is not a file: {path}")
            continue
        actual_sha = sha256_file(path)
        if expected_sha != actual_sha:
            errors.append(
                f"Evidence role {role} SHA256 mismatch: declared={expected_sha!r} actual={actual_sha}"
            )
        rendered.append(f"{role}:{path}#{actual_sha}")
        if role == "DIAGNOSTIC_DCP_CONE_QUERY":
            if not path_within(path, task_root):
                errors.append(f"task-local Evidence role {role} is outside R2 task root: {path}")

    required_roles = set(FIXED_EVIDENCE_ROLES) | {"DIAGNOSTIC_DCP_CONE_QUERY"}
    missing = sorted(required_roles - set(by_role))
    extra = sorted(set(by_role) - required_roles)
    if missing:
        errors.append(f"missing Evidence roles: {missing}")
    if extra:
        errors.append(f"unexpected Evidence roles: {extra}")

    for role, (required_path, required_sha) in fixed_paths.items():
        item = by_role.get(role)
        if not item:
            continue
        raw_path = item.get("Path")
        if isinstance(raw_path, str) and normalize_path(Path(raw_path)) != normalize_path(required_path):
            errors.append(
                f"Evidence role {role} path drift: expected={required_path.resolve()} actual={Path(raw_path).resolve()}"
            )
        if item.get("SHA256") != required_sha:
            errors.append(
                f"Evidence role {role} input hash drift: expected={required_sha} actual={item.get('SHA256')!r}"
            )
    return errors, ";".join(sorted(rendered))


def validate_proof(
    pair: Pair,
    candidate: Candidate | None,
    row_id: str,
    proof: Mapping[str, Any] | None,
    fixed_paths: Mapping[str, tuple[Path, str]],
    task_root: Path,
) -> ProofResult:
    if candidate is None:
        is_base_drift, old_family, new_family = prohibited_source_base_drift(pair)
        return ProofResult(
            False,
            (
                f"FAIL_SOURCE_BASE_DRIFT_PROHIBITED:{old_family}->{new_family}"
                if is_base_drift
                else "FAIL_UNRECONCILED_SOURCE_FAMILY"
            ),
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            semantic_errors=1,
        )
    definition = FAMILY_DEFINITIONS[candidate.family]
    defaults = {
        "stable": "",
        "token": definition["GoverningRequestOrCompletionToken"],
        "protocol": definition["AcknowledgementOrCompletionProtocol"],
        "barrier": definition["EarliestSemanticUseBarrier"],
        "fanin": "",
        "bypass": "",
        "replacement": definition["ExistingReplacementGroup"],
        "evidence": "",
    }
    if proof is None:
        return ProofResult(
            False,
            "FAIL_MISSING_DCP_CONE_EVIDENCE",
            defaults["stable"],
            defaults["token"],
            defaults["protocol"],
            defaults["barrier"],
            defaults["fanin"],
            defaults["bypass"],
            defaults["replacement"],
            defaults["evidence"],
            semantic_errors=1,
            protocol_errors=1,
            replacement_errors=1,
        )

    semantic_errors: list[str] = []
    protocol_errors: list[str] = []
    replacement_errors: list[str] = []
    expected_identity = proof_identity(pair, candidate, row_id)
    for field, expected in expected_identity.items():
        if proof.get(field) != expected:
            semantic_errors.append(f"{field}: expected={expected!r} actual={proof.get(field)!r}")

    for field in PROOF_BOOLEAN_FIELDS:
        if proof.get(field) is not True:
            if field == "ReplacementOrStructuralCheckPass":
                replacement_errors.append(f"{field} is not literal true")
            elif field in {"GoverningTokenEquivalent", "EarliestUseBarrierEquivalent"}:
                protocol_errors.append(f"{field} is not literal true")
            else:
                semantic_errors.append(f"{field} is not literal true")

    required_literals = {
        "StablePayloadProof": "PASS_EXACT_STABLE_PAYLOAD_MEMBERSHIP",
        "FaninFamilyProof": "PASS_COMPLETE_FANIN_FAMILY_EQUIVALENCE",
        "DiagnosticBypassAbsent": "PASS_NO_DIRECT_BYPASS_OR_DIAGNOSTIC_HIERARCHY",
        "GoverningToken": definition["GoverningRequestOrCompletionToken"],
        "ProtocolProof": definition["AcknowledgementOrCompletionProtocol"],
        "EarliestUseBarrier": definition["EarliestSemanticUseBarrier"],
        "ReplacementGroup": definition["ExistingReplacementGroup"],
        "Disposition": "PASS_RECONCILED",
    }
    for field, expected in required_literals.items():
        if proof.get(field) != expected:
            target = replacement_errors if field == "ReplacementGroup" else (
                protocol_errors if field in {"GoverningToken", "ProtocolProof", "EarliestUseBarrier"} else semantic_errors
            )
            target.append(f"{field}: expected={expected!r} actual={proof.get(field)!r}")

    for field in (
        "ProductConeSHA256",
        "DiagnosticConeSHA256",
        "ProductNormalizedSemanticConeSHA256",
        "DiagnosticNormalizedSemanticConeSHA256",
    ):
        value = proof.get(field)
        if not isinstance(value, str) or not HEX64_RE.fullmatch(value):
            semantic_errors.append(f"{field} is not an uppercase SHA256")
    if proof.get("ProductNormalizedSemanticConeSHA256") != proof.get(
        "DiagnosticNormalizedSemanticConeSHA256"
    ):
        semantic_errors.append("normalized semantic cone signatures differ")

    evidence_errors, evidence_path = validate_evidence_files(proof, candidate, fixed_paths, task_root)
    semantic_errors.extend(evidence_errors)

    all_errors = semantic_errors + protocol_errors + replacement_errors
    disposition = "PASS_RECONCILED" if not all_errors else "FAIL_INVALID_DCP_CONE_EVIDENCE"
    return ProofResult(
        passed=not all_errors,
        disposition=disposition,
        stable_payload_proof=str(proof.get("StablePayloadProof", "")),
        governing_token=str(proof.get("GoverningToken", defaults["token"])),
        protocol_proof=str(proof.get("ProtocolProof", defaults["protocol"])),
        earliest_use_barrier=str(proof.get("EarliestUseBarrier", defaults["barrier"])),
        fanin_family_proof=str(proof.get("FaninFamilyProof", "")),
        diagnostic_bypass_absent=str(proof.get("DiagnosticBypassAbsent", "")),
        replacement_group=str(proof.get("ReplacementGroup", defaults["replacement"])),
        evidence_path=evidence_path,
        semantic_errors=len(semantic_errors),
        protocol_errors=len(protocol_errors),
        replacement_errors=len(replacement_errors),
    )


def reconciliation_record(
    pair: Pair,
    candidate: Candidate | None,
    row_id: str,
    result: ProofResult,
) -> dict[str, Any]:
    is_base_drift, old_family, new_family = prohibited_source_base_drift(pair)
    unresolved_family = (
        f"UNRECONCILED_SOURCE_BASE_DRIFT:{old_family}->{new_family}"
        if is_base_drift
        else "UNRECONCILED_SOURCE_FAMILY"
    )
    return {
        "RowID": row_id,
        "Rule": pair.diagnostic.rule,
        "Severity": pair.diagnostic.severity,
        "ProductPhysicalSource": pair.product.source,
        "DiagnosticPhysicalSource": pair.diagnostic.source,
        "SourceClock": pair.diagnostic.source_clock,
        "DestinationClock": pair.diagnostic.destination_clock,
        "DestinationEndpoint": pair.diagnostic.destination,
        "Exception": pair.diagnostic.exception,
        "SemanticFamily": candidate.family if candidate else unresolved_family,
        "OldBitIndex": candidate.old_index if candidate else "",
        "NewBitIndex": candidate.new_index if candidate else "",
        "StablePayloadProof": result.stable_payload_proof,
        "GoverningToken": result.governing_token,
        "ProtocolProof": result.protocol_proof,
        "EarliestUseBarrier": result.earliest_use_barrier,
        "FaninFamilyProof": result.fanin_family_proof,
        "DiagnosticBypassAbsent": result.diagnostic_bypass_absent,
        "ReplacementGroup": result.replacement_group,
        "Disposition": result.disposition,
        "EvidencePath": result.evidence_path,
    }


def source_family_rows() -> list[dict[str, str]]:
    columns = (
        "AllowedPhysicalSourceBase",
        "AllowedBitIndices",
        "SourceClock",
        "PayloadMeaning",
        "PayloadWidth",
        "GoverningRequestOrCompletionToken",
        "AcknowledgementOrCompletionProtocol",
        "EarliestSemanticUseBarrier",
        "ExistingReplacementGroup",
        "ExistingAuthorityEvidence",
    )
    result: list[dict[str, str]] = []
    for name in sorted(FAMILY_DEFINITIONS):
        record = {"SemanticFamilyName": name}
        record.update({column: FAMILY_DEFINITIONS[name][column] for column in columns})
        result.append(record)
    return result


def destination_comparison_rows(
    product: Sequence[CDCRow], diagnostic: Sequence[CDCRow]
) -> list[dict[str, Any]]:
    keys = sorted(
        set(row.non_source_key() for row in product) | set(row.non_source_key() for row in diagnostic),
        key=repr,
    )
    old = Counter(row.non_source_key() for row in product)
    new = Counter(row.non_source_key() for row in diagnostic)
    result: list[dict[str, Any]] = []
    for key in keys:
        rule, severity, description, depth, source_clock, destination_clock, exception, destination = key
        result.append(
            {
                "Rule": rule,
                "Severity": severity,
                "Description": description,
                "Depth": depth,
                "SourceClock": source_clock,
                "DestinationClock": destination_clock,
                "Exception": exception,
                "DestinationEndpoint": destination,
                "ProductMultiplicity": old[key],
                "DiagnosticMultiplicity": new[key],
                "Disposition": "IDENTICAL" if old[key] == new[key] else "DRIFT",
            }
        )
    return result


def build_semantic_manifest(
    all_pairs: Sequence[Pair],
    changed_records: Mapping[tuple[Any, ...], deque[dict[str, Any]]],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    multiplicity: Counter[tuple[Any, ...]] = Counter()
    for sequence, pair in enumerate(all_pairs, start=1):
        identity = (
            pair.product.physical_key(),
            pair.diagnostic.physical_key(),
        )
        changed_record: dict[str, Any] | None = None
        if pair.changed:
            queue = changed_records.get(identity)
            if queue:
                changed_record = queue.popleft()
        key_for_multiplicity = pair.diagnostic.physical_key()
        multiplicity[key_for_multiplicity] += 1
        if changed_record:
            definition = FAMILY_DEFINITIONS[changed_record["SemanticFamily"]]
            record = {
                "RowID": changed_record["RowID"],
                "MultiplicityIndex": multiplicity[key_for_multiplicity],
                "Rule": pair.diagnostic.rule,
                "Severity": pair.diagnostic.severity,
                "Description": pair.diagnostic.description,
                "Depth": pair.diagnostic.depth,
                "SourceClock": pair.diagnostic.source_clock,
                "DestinationClock": pair.diagnostic.destination_clock,
                "DestinationEndpoint": pair.diagnostic.destination,
                "ExceptionType": pair.diagnostic.exception,
                "SourceSemanticFamily": changed_record["SemanticFamily"],
                "StableDataProtocol": definition["AcknowledgementOrCompletionProtocol"],
                "GoverningTokenFamily": definition["GoverningRequestOrCompletionToken"],
                "ReplacementGroupOrCDCDisposition": changed_record["ReplacementGroup"],
                "DiagnosticPhysicalSource": pair.diagnostic.source,
                "ProductPhysicalSource": pair.product.source,
                "PhysicalSourcesIdentical": "NO",
                "Disposition": changed_record["Disposition"],
                "EvidencePath": changed_record["EvidencePath"],
            }
        else:
            record = {
                "RowID": f"CDC-ALL-{sequence:05d}",
                "MultiplicityIndex": multiplicity[key_for_multiplicity],
                "Rule": pair.diagnostic.rule,
                "Severity": pair.diagnostic.severity,
                "Description": pair.diagnostic.description,
                "Depth": pair.diagnostic.depth,
                "SourceClock": pair.diagnostic.source_clock,
                "DestinationClock": pair.diagnostic.destination_clock,
                "DestinationEndpoint": pair.diagnostic.destination,
                "ExceptionType": pair.diagnostic.exception,
                "SourceSemanticFamily": "UNCHANGED_PHYSICAL_SOURCE",
                "StableDataProtocol": "EXISTING_PHYSICAL_DISPOSITION_PRESERVED_NO_NORMALIZATION",
                "GoverningTokenFamily": "EXISTING_REPORT_DISPOSITION",
                "ReplacementGroupOrCDCDisposition": f"UNCHANGED_{pair.diagnostic.rule}_REPORT_DISPOSITION",
                "DiagnosticPhysicalSource": pair.diagnostic.source,
                "ProductPhysicalSource": pair.product.source,
                "PhysicalSourcesIdentical": "YES",
                "Disposition": "PASS_UNCHANGED_PHYSICAL_ROW",
                "EvidencePath": "",
            }
        record["SemanticKeySHA256"] = semantic_key_sha(record)
        records.append(record)
    return records


def summary_text(summary: Mapping[str, Any], errors: Sequence[str]) -> str:
    ordered_keys = [
        "SCHEMA",
        "RESULT",
        "FAILURE_LITERAL",
        "CDC_DISPOSITION",
        "CLASSIFICATION",
        "ROUTED_DCP_SHA256",
        "RTL_SHA256",
        "XDC_SHA256",
        "PRODUCT_CDC_REPORT_SHA256",
        "DIAGNOSTIC_CDC_REPORT_SHA256",
        "STRUCTURAL_RECEIPT_SHA256",
        "REPLACEMENT_RECEIPT_SHA256",
        "CONE_EVIDENCE_SHA256",
        "PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256",
        "DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256",
        "PRODUCT_CDC_10_PHYSICAL_MANIFEST_SHA256",
        "DIAGNOSTIC_CDC_10_PHYSICAL_MANIFEST_SHA256",
        "PRODUCT_CDC_13_PHYSICAL_MANIFEST_SHA256",
        "DIAGNOSTIC_CDC_13_PHYSICAL_MANIFEST_SHA256",
        "RAW_CRITICAL_COUNT",
        "RAW_WARNING_COUNT",
        "CDC_1_CRITICAL",
        "CDC_10_CRITICAL",
        "CDC_13_CRITICAL",
        "CDC_6_WARNING",
        "CDC_15_WARNING",
        "CDC_1_DESTINATION_ROWS_IDENTICAL",
        "NEW_CDC_1_DESTINATIONS",
        "MISSING_CDC_1_DESTINATIONS",
        "DESTINATION_MULTIPLICITY_DRIFT",
        "CDC_1_BYTE_IDENTICAL_ROWS",
        "CDC_10_BYTE_IDENTICAL_ROWS",
        "CDC_13_BYTE_IDENTICAL_ROWS",
        "CHANGED_CRITICAL_ROWS",
        "RECONCILED_CRITICAL_ROWS",
        "UNRECONCILED_CRITICAL_ROWS",
        "RESET_COMMIT_FAMILY_REPRESENTATIVE_CHANGES",
        "OWNERSHIP_AND_RELEASE_FAMILY_REPRESENTATIVE_CHANGES",
        "CROSS_BASE_CRITICAL_ROWS",
        "SOURCE_BASE_DRIFT_CRITICAL_ROWS",
        "CHANGED_WARNING_ROWS",
        "RECONCILED_WARNING_ROWS",
        "UNRECONCILED_WARNING_ROWS",
        "CROSS_BASE_WARNING_ROWS",
        "SOURCE_BASE_DRIFT_WARNING_ROWS",
        "SOURCE_BASE_DRIFT_TOTAL",
        "FIRST_SOURCE_BASE_DRIFT_ROWID",
        "FIRST_SOURCE_BASE_DRIFT_PRODUCT_SOURCE",
        "FIRST_SOURCE_BASE_DRIFT_DIAGNOSTIC_SOURCE",
        "FIRST_SOURCE_BASE_DRIFT_DESTINATION",
        "RULE_DRIFT",
        "SEVERITY_DRIFT",
        "CLOCK_PAIR_DRIFT",
        "EXCEPTION_DRIFT",
        "SEMANTIC_FAMILY_DRIFT",
        "PROTOCOL_DRIFT",
        "REPLACEMENT_GROUP_DRIFT",
        "DIAGNOSTIC_HIERARCHY_CDC_ROWS",
        "STRUCTURAL_CDC",
        "REPLACEMENT_CHECKS_PASS",
        "REPLACEMENT_CHECKS_TOTAL",
        "UNRESOLVED_REPLACEMENT_CHECKS",
        "SEMANTIC_MANIFEST_ROW_COUNT",
        "SEMANTIC_MANIFEST_CSV_SHA256",
        "SEMANTIC_MANIFEST_JSON_SHA256",
        "CRITICAL_RECONCILIATION_CSV_SHA256",
        "WARNING_RECONCILIATION_CSV_SHA256",
        "ERROR_COUNT",
    ]
    lines = [f"{key}={summary.get(key, 'N/A')}" for key in ordered_keys]
    for index, error in enumerate(errors, start=1):
        clean = " ".join(str(error).splitlines()).replace("=", ":")
        lines.append(f"ERROR_{index:04d}={clean}")
    return "\n".join(lines) + "\n"


def default_summary() -> dict[str, Any]:
    return {
        "SCHEMA": SUMMARY_SCHEMA,
        "RESULT": "FAIL",
        "FAILURE_LITERAL": "NVP_DIAG1_R2_SEMANTIC_RECONCILIATION_FAILED",
        "CDC_DISPOSITION": "FAIL_NO_SEMANTIC_MANIFEST",
        "CLASSIFICATION": CLASSIFICATION,
        "STRUCTURAL_CDC": "FAIL",
        "REPLACEMENT_CHECKS_PASS": 0,
        "REPLACEMENT_CHECKS_TOTAL": 17,
        "UNRESOLVED_REPLACEMENT_CHECKS": 17,
        "SEMANTIC_MANIFEST_ROW_COUNT": 0,
        "SEMANTIC_MANIFEST_CSV_SHA256": "NOT_EMITTED",
        "SEMANTIC_MANIFEST_JSON_SHA256": "NOT_EMITTED",
    }


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--product-report", required=True, help="immutable PRODUCT CDC.rpt")
    parser.add_argument("--diagnostic-report", required=True, help="fresh CDC.rpt from exact DIAG1-R1 DCP")
    parser.add_argument("--routed-dcp", required=True, help="exact DIAG1-R1 routed DCP")
    parser.add_argument("--rtl", required=True, help="exact v41_g2b_onech_c2h.sv")
    parser.add_argument("--xdc", required=True, help="exact g2b_cdc.xdc")
    parser.add_argument("--structural-receipt", required=True)
    parser.add_argument("--replacement-receipt", required=True)
    parser.add_argument(
        "--cone-evidence",
        help="task-local JSON conforming to NVP_VIDEO_DIAG1_R2_DCP_CONE_EVIDENCE_V1",
    )
    parser.add_argument("--output-dir", required=True, help="task-local output directory, normally R2\\cdc")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    task_root = Path(__file__).resolve().parents[1]
    output_dir = Path(args.output_dir).resolve()
    if not path_within(output_dir, task_root):
        print(f"FATAL: output directory is outside task root {task_root}: {output_dir}", file=sys.stderr)
        return 3
    output_dir.mkdir(parents=True, exist_ok=True)

    # Exact generated names only.  Removing stale semantic outputs is necessary
    # so a failed rerun can never leave a prior PASS manifest looking current.
    for stem in (SEMANTIC_STEM, SEMANTIC_ALIAS_STEM):
        for suffix in (".csv", ".json", ".sha256"):
            stale = output_dir / f"{stem}{suffix}"
            if stale.is_file():
                stale.unlink()

    errors: list[str] = []
    summary = default_summary()
    product_path = require_file(args.product_report, "PRODUCT CDC report", errors)
    diagnostic_path = require_file(args.diagnostic_report, "diagnostic CDC report", errors)
    dcp_path = require_file(args.routed_dcp, "routed DCP", errors)
    rtl_path = require_file(args.rtl, "RTL", errors)
    xdc_path = require_file(args.xdc, "XDC", errors)
    structural_path = require_file(args.structural_receipt, "structural CDC receipt", errors)
    replacement_path = require_file(args.replacement_receipt, "replacement receipt", errors)
    cone_path = Path(args.cone_evidence).resolve() if args.cone_evidence else None
    if cone_path is not None and not cone_path.is_file():
        errors.append(f"DCP cone evidence is not a file: {cone_path}")
        cone_path = None

    hashes: dict[str, str] = {}
    for label, path in (
        ("PRODUCT_CDC_REPORT_SHA256", product_path),
        ("DIAGNOSTIC_CDC_REPORT_SHA256", diagnostic_path),
        ("ROUTED_DCP_SHA256", dcp_path),
        ("RTL_SHA256", rtl_path),
        ("XDC_SHA256", xdc_path),
        ("STRUCTURAL_RECEIPT_SHA256", structural_path),
        ("REPLACEMENT_RECEIPT_SHA256", replacement_path),
    ):
        if path.is_file():
            hashes[label] = sha256_file(path)
            summary[label] = hashes[label]
    summary["CONE_EVIDENCE_SHA256"] = sha256_file(cone_path) if cone_path else "NOT_SUPPLIED"

    if "PRODUCT_CDC_REPORT_SHA256" in hashes:
        validate_hash(
            "PRODUCT CDC authority report",
            hashes["PRODUCT_CDC_REPORT_SHA256"],
            EXPECTED_PRODUCT_REPORT_SHA256,
            errors,
        )
    if "ROUTED_DCP_SHA256" in hashes:
        validate_hash("routed DCP", hashes["ROUTED_DCP_SHA256"], EXPECTED_DCP_SHA256, errors)
    if "RTL_SHA256" in hashes:
        validate_hash("RTL", hashes["RTL_SHA256"], EXPECTED_RTL_SHA256, errors)
    if "XDC_SHA256" in hashes:
        validate_hash("XDC", hashes["XDC_SHA256"], EXPECTED_XDC_SHA256, errors)
    if "STRUCTURAL_RECEIPT_SHA256" in hashes:
        validate_hash(
            "structural CDC receipt",
            hashes["STRUCTURAL_RECEIPT_SHA256"],
            EXPECTED_STRUCTURAL_RECEIPT_SHA256,
            errors,
        )
        if hashes["STRUCTURAL_RECEIPT_SHA256"] == EXPECTED_STRUCTURAL_RECEIPT_SHA256:
            summary["STRUCTURAL_CDC"] = "PASS"
    replacement_errors = validate_replacement_receipt(replacement_path) if replacement_path.is_file() else []
    errors.extend(replacement_errors)
    if not replacement_errors and replacement_path.is_file():
        summary["REPLACEMENT_CHECKS_PASS"] = 17
        summary["UNRESOLVED_REPLACEMENT_CHECKS"] = 0

    product_rows: list[CDCRow] = []
    diagnostic_rows: list[CDCRow] = []
    product_text = ""
    diagnostic_text = ""
    try:
        if product_path.is_file():
            product_rows, product_text = parse_cdc_report(product_path)
        if diagnostic_path.is_file():
            diagnostic_rows, diagnostic_text = parse_cdc_report(diagnostic_path)
    except Exception as exc:
        errors.append(str(exc))

    critical_records: list[dict[str, Any]] = []
    warning_records: list[dict[str, Any]] = []
    cone_requirements: list[dict[str, Any]] = []
    all_pairs: list[Pair] = []
    changed_record_queues: dict[tuple[Any, ...], deque[dict[str, Any]]] = defaultdict(deque)

    if product_rows and diagnostic_rows:
        critical_diag = rows_of(diagnostic_rows, "Critical")
        warning_diag = rows_of(diagnostic_rows, "Warning")
        summary["RAW_CRITICAL_COUNT"] = len(critical_diag)
        summary["RAW_WARNING_COUNT"] = len(warning_diag)
        if len(critical_diag) != EXPECTED_CRITICAL_TOTAL:
            errors.append(
                f"diagnostic critical total drift: expected={EXPECTED_CRITICAL_TOTAL} actual={len(critical_diag)}"
            )
        if len(warning_diag) != EXPECTED_WARNING_TOTAL:
            errors.append(
                f"diagnostic warning total drift: expected={EXPECTED_WARNING_TOTAL} actual={len(warning_diag)}"
            )
        for (severity, rule), expected in EXPECTED_COUNTS.items():
            actual = len(rows_of(diagnostic_rows, severity, rule))
            summary[rule.replace("-", "_") + f"_{severity.upper()}"] = actual
            if actual != expected:
                errors.append(
                    f"diagnostic {severity} {rule} count drift: expected={expected} actual={actual}"
                )
        allowed_critical_rules = {"CDC-1", "CDC-10", "CDC-13"}
        allowed_warning_rules = {"CDC-6", "CDC-15"}
        unexpected_critical = Counter(
            row.rule for row in critical_diag if row.rule not in allowed_critical_rules
        )
        unexpected_warning = Counter(
            row.rule for row in warning_diag if row.rule not in allowed_warning_rules
        )
        if unexpected_critical:
            errors.append(f"unexpected critical rules: {unexpected_critical}")
        if unexpected_warning:
            errors.append(f"unexpected warning rules: {unexpected_warning}")

        product_cdc1 = rows_of(product_rows, "Critical", "CDC-1")
        diagnostic_cdc1 = rows_of(diagnostic_rows, "Critical", "CDC-1")
        product_cdc10 = rows_of(product_rows, "Critical", "CDC-10")
        diagnostic_cdc10 = rows_of(diagnostic_rows, "Critical", "CDC-10")
        product_cdc13 = rows_of(product_rows, "Critical", "CDC-13")
        diagnostic_cdc13 = rows_of(diagnostic_rows, "Critical", "CDC-13")

        canonical_values = {
            "PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256": canonical_sha(product_cdc1),
            "DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256": canonical_sha(diagnostic_cdc1),
            "PRODUCT_CDC_10_PHYSICAL_MANIFEST_SHA256": canonical_sha(product_cdc10),
            "DIAGNOSTIC_CDC_10_PHYSICAL_MANIFEST_SHA256": canonical_sha(diagnostic_cdc10),
            "PRODUCT_CDC_13_PHYSICAL_MANIFEST_SHA256": canonical_sha(product_cdc13),
            "DIAGNOSTIC_CDC_13_PHYSICAL_MANIFEST_SHA256": canonical_sha(diagnostic_cdc13),
        }
        summary.update(canonical_values)
        for key, expected in (
            ("PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256", EXPECTED_PRODUCT_CDC1_SHA256),
            ("DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256", EXPECTED_DIAGNOSTIC_CDC1_SHA256),
            ("PRODUCT_CDC_10_PHYSICAL_MANIFEST_SHA256", EXPECTED_CDC10_SHA256),
            ("DIAGNOSTIC_CDC_10_PHYSICAL_MANIFEST_SHA256", EXPECTED_CDC10_SHA256),
            ("PRODUCT_CDC_13_PHYSICAL_MANIFEST_SHA256", EXPECTED_CDC13_SHA256),
            ("DIAGNOSTIC_CDC_13_PHYSICAL_MANIFEST_SHA256", EXPECTED_CDC13_SHA256),
        ):
            validate_hash(key, canonical_values[key], expected, errors)
        validate_hash(
            "PRODUCT critical-all canonical manifest",
            canonical_sha(critical_diag if False else rows_of(product_rows, "Critical")),
            EXPECTED_PRODUCT_CRITICAL_ALL_SHA256,
            errors,
        )

        if Counter(row.physical_key() for row in product_cdc10) != Counter(
            row.physical_key() for row in diagnostic_cdc10
        ):
            errors.append("CDC-10 rows are not byte/field identical")
        if Counter(row.physical_key() for row in product_cdc13) != Counter(
            row.physical_key() for row in diagnostic_cdc13
        ):
            errors.append("CDC-13 rows are not byte/field identical")
        product_cdc6 = rows_of(product_rows, "Warning", "CDC-6")
        diagnostic_cdc6 = rows_of(diagnostic_rows, "Warning", "CDC-6")
        if Counter(row.physical_key() for row in product_cdc6) != Counter(
            row.physical_key() for row in diagnostic_cdc6
        ):
            errors.append("CDC-6 rows are not byte/field identical")

        cdc1_old_dest = Counter(row.destination for row in product_cdc1)
        cdc1_new_dest = Counter(row.destination for row in diagnostic_cdc1)
        cdc1_identical_dest = sum((cdc1_old_dest & cdc1_new_dest).values())
        summary["CDC_1_DESTINATION_ROWS_IDENTICAL"] = cdc1_identical_dest
        summary["NEW_CDC_1_DESTINATIONS"] = sum((cdc1_new_dest - cdc1_old_dest).values())
        summary["MISSING_CDC_1_DESTINATIONS"] = sum((cdc1_old_dest - cdc1_new_dest).values())

        governed_product = [
            row for row in product_rows if row.severity in {"Critical", "Warning"}
        ]
        governed_diagnostic = [
            row for row in diagnostic_rows if row.severity in {"Critical", "Warning"}
        ]
        non_source_old = Counter(row.non_source_key() for row in governed_product)
        non_source_new = Counter(row.non_source_key() for row in governed_diagnostic)
        summary["DESTINATION_MULTIPLICITY_DRIFT"] = counter_symdiff(non_source_old, non_source_new)
        summary["RULE_DRIFT"] = counter_symdiff(
            Counter((row.destination, row.rule) for row in governed_product),
            Counter((row.destination, row.rule) for row in governed_diagnostic),
        )
        summary["SEVERITY_DRIFT"] = counter_symdiff(
            Counter((row.destination, row.severity) for row in governed_product),
            Counter((row.destination, row.severity) for row in governed_diagnostic),
        )
        summary["CLOCK_PAIR_DRIFT"] = counter_symdiff(
            Counter((row.destination, row.source_clock, row.destination_clock) for row in governed_product),
            Counter((row.destination, row.source_clock, row.destination_clock) for row in governed_diagnostic),
        )
        summary["EXCEPTION_DRIFT"] = counter_symdiff(
            Counter((row.destination, row.exception) for row in governed_product),
            Counter((row.destination, row.exception) for row in governed_diagnostic),
        )
        if non_source_old != non_source_new:
            errors.append("critical/warning non-source semantic multiset drift")

        summary["CDC_1_BYTE_IDENTICAL_ROWS"] = physical_intersection_count(
            product_cdc1, diagnostic_cdc1
        )
        summary["CDC_10_BYTE_IDENTICAL_ROWS"] = physical_intersection_count(
            product_cdc10, diagnostic_cdc10
        )
        summary["CDC_13_BYTE_IDENTICAL_ROWS"] = physical_intersection_count(
            product_cdc13, diagnostic_cdc13
        )

        all_pairs, all_pair_errors = pair_reports(product_rows, diagnostic_rows)
        errors.extend(all_pair_errors)
        nongoverned_product = [
            row for row in product_rows if row.severity not in {"Critical", "Warning"}
        ]
        nongoverned_diagnostic = [
            row for row in diagnostic_rows if row.severity not in {"Critical", "Warning"}
        ]
        if Counter(row.physical_key() for row in nongoverned_product) != Counter(
            row.physical_key() for row in nongoverned_diagnostic
        ):
            errors.append(
                "informational/unknown CDC rows are not physical-row identical; no normalization authority exists"
            )

        governed_pairs = [
            pair for pair in all_pairs if pair.diagnostic.severity in {"Critical", "Warning"}
        ]
        critical_changed = [
            pair
            for pair in governed_pairs
            if pair.changed and pair.diagnostic.severity == "Critical" and pair.diagnostic.rule == "CDC-1"
        ]
        warning_changed = [
            pair for pair in governed_pairs if pair.changed and pair.diagnostic.severity == "Warning"
        ]
        other_critical_changed = [
            pair
            for pair in governed_pairs
            if pair.changed
            and pair.diagnostic.severity == "Critical"
            and pair.diagnostic.rule != "CDC-1"
        ]
        if other_critical_changed:
            errors.append(f"non-CDC-1 critical source changes found: {len(other_critical_changed)}")
        summary["CHANGED_CRITICAL_ROWS"] = len(critical_changed)
        summary["CHANGED_WARNING_ROWS"] = len(warning_changed)
        if len(critical_changed) != EXPECTED_CHANGED_CRITICAL:
            errors.append(
                f"changed critical row count drift: expected={EXPECTED_CHANGED_CRITICAL} actual={len(critical_changed)}"
            )
        if len(warning_changed) != EXPECTED_CHANGED_WARNING:
            errors.append(
                f"changed warning row count drift: expected={EXPECTED_CHANGED_WARNING} actual={len(warning_changed)}"
            )

        cone_document, cone_by_id = load_cone_evidence(cone_path, errors)
        if cone_document is not None:
            expected_top = {
                "Schema": CONE_SCHEMA,
                "Classification": "TASK_LOCAL_READ_ONLY_ROUTED_DCP_CONE_PROOF",
                "RoutedDCPSHA256": hashes.get("ROUTED_DCP_SHA256", ""),
                "ProductCDCReportSHA256": hashes.get("PRODUCT_CDC_REPORT_SHA256", ""),
                "DiagnosticCDCReportSHA256": hashes.get("DIAGNOSTIC_CDC_REPORT_SHA256", ""),
                "RTLSHA256": hashes.get("RTL_SHA256", ""),
                "XDCSHA256": hashes.get("XDC_SHA256", ""),
                "StructuralReceiptSHA256": hashes.get("STRUCTURAL_RECEIPT_SHA256", ""),
                "ReplacementReceiptSHA256": hashes.get("REPLACEMENT_RECEIPT_SHA256", ""),
                "ProductCDC1PhysicalManifestSHA256": EXPECTED_PRODUCT_CDC1_SHA256,
                "DiagnosticCDC1PhysicalManifestSHA256": EXPECTED_DIAGNOSTIC_CDC1_SHA256,
                "ChangedCriticalRows": EXPECTED_CHANGED_CRITICAL,
                "ChangedWarningRows": EXPECTED_CHANGED_WARNING,
                "QueryCompleteness": "COMPLETE_522_ROW_MULTISET",
                "RoutedDCPReadOnly": True,
                "SourceOrConstraintModified": False,
                "DiagnosticHierarchyConeRows": 0,
                "DifferentSourceBaseNormalization": "PROHIBITED",
                "ProofMayOverrideSourceBaseDrift": False,
            }
            for field, expected in expected_top.items():
                if cone_document.get(field) != expected:
                    errors.append(
                        f"DCP cone evidence top-level {field} drift: expected={expected!r} "
                        f"actual={cone_document.get(field)!r}"
                    )

        fixed_paths = {
            "PRODUCT_CDC_AUTHORITY": (
                product_path,
                hashes.get("PRODUCT_CDC_REPORT_SHA256", ""),
            ),
            "RTL_PROTOCOL": (rtl_path, hashes.get("RTL_SHA256", "")),
            "XDC_CONSTRAINT": (xdc_path, hashes.get("XDC_SHA256", "")),
            "STRUCTURAL_CDC": (
                structural_path,
                hashes.get("STRUCTURAL_RECEIPT_SHA256", ""),
            ),
            "REPLACEMENT_CHECK": (
                replacement_path,
                hashes.get("REPLACEMENT_RECEIPT_SHA256", ""),
            ),
        }

        proof_semantic_errors = 0
        proof_protocol_errors = 0
        proof_replacement_errors = 0
        reconciled_critical = 0
        reconciled_warning = 0
        critical_candidates: Counter[str] = Counter()
        warning_candidates: Counter[str] = Counter()
        expected_row_ids: set[str] = set()
        critical_base_drift = [
            (index, pair, prohibited_source_base_drift(pair))
            for index, pair in enumerate(critical_changed, start=1)
            if prohibited_source_base_drift(pair)[0]
        ]
        warning_base_drift = [
            (index, pair, prohibited_source_base_drift(pair))
            for index, pair in enumerate(warning_changed, start=1)
            if prohibited_source_base_drift(pair)[0]
        ]
        summary["SOURCE_BASE_DRIFT_CRITICAL_ROWS"] = len(critical_base_drift)
        summary["SOURCE_BASE_DRIFT_WARNING_ROWS"] = len(warning_base_drift)
        summary["SOURCE_BASE_DRIFT_TOTAL"] = len(critical_base_drift) + len(warning_base_drift)
        if critical_base_drift:
            first_index, first_pair, first_families = critical_base_drift[0]
            summary["FIRST_SOURCE_BASE_DRIFT_ROWID"] = make_row_id("CDC1-CHG", first_index)
            summary["FIRST_SOURCE_BASE_DRIFT_PRODUCT_SOURCE"] = first_pair.product.source
            summary["FIRST_SOURCE_BASE_DRIFT_DIAGNOSTIC_SOURCE"] = first_pair.diagnostic.source
            summary["FIRST_SOURCE_BASE_DRIFT_DESTINATION"] = first_pair.diagnostic.destination
            errors.append(
                "prohibited critical source-base drift: "
                f"count={len(critical_base_drift)} first={make_row_id('CDC1-CHG', first_index)} "
                f"{first_families[1]}->{first_families[2]} "
                f"{first_pair.product.source}->{first_pair.diagnostic.source} "
                f"destination={first_pair.diagnostic.destination}"
            )
        if warning_base_drift:
            first_index, first_pair, first_families = warning_base_drift[0]
            errors.append(
                "prohibited warning source-base drift: "
                f"count={len(warning_base_drift)} first={make_row_id('WARN-CHG', first_index)} "
                f"{first_families[1]}->{first_families[2]} "
                f"{first_pair.product.source}->{first_pair.diagnostic.source} "
                f"destination={first_pair.diagnostic.destination}"
            )

        exact_critical_cross_base = {
            (
                pair.product.source,
                pair.diagnostic.source,
                pair.diagnostic.destination,
            )
            for _, pair, _ in critical_base_drift
        }
        expected_critical_cross_base = {
            (
                "G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C",
                "G2B_ONECH_C2H/axis_slot_reg[1]/C",
                destination,
            )
            for destination in PROHIBITED_CRITICAL_CROSS_BASE_DESTINATIONS
        }
        if exact_critical_cross_base != expected_critical_cross_base:
            errors.append(
                "critical prohibited source-base row set drifted from the exact seven-row observation"
            )
        exact_warning_cross_base = {
            (
                pair.product.source,
                pair.diagnostic.source,
                pair.diagnostic.destination,
            )
            for _, pair, _ in warning_base_drift
        }
        if exact_warning_cross_base != set(PROHIBITED_WARNING_CROSS_BASE_TUPLES):
            errors.append(
                "warning prohibited source-base row set drifted from the exact three-row observation"
            )

        for index, pair in enumerate(critical_changed, start=1):
            row_id = make_row_id("CDC1-CHG", index)
            expected_row_ids.add(row_id)
            candidate = classify_changed(pair)
            if candidate:
                critical_candidates[candidate.family] += 1
            cone_requirements.append(cone_requirement_record(pair, candidate, row_id))
            result = validate_proof(
                pair, candidate, row_id, cone_by_id.get(row_id), fixed_paths, task_root
            )
            record = reconciliation_record(pair, candidate, row_id, result)
            critical_records.append(record)
            if result.passed:
                reconciled_critical += 1
            proof_semantic_errors += result.semantic_errors
            proof_protocol_errors += result.protocol_errors
            proof_replacement_errors += result.replacement_errors
            changed_record_queues[(pair.product.physical_key(), pair.diagnostic.physical_key())].append(
                record
            )

        for index, pair in enumerate(warning_changed, start=1):
            row_id = make_row_id("WARN-CHG", index)
            expected_row_ids.add(row_id)
            candidate = classify_changed(pair)
            if candidate:
                warning_candidates[candidate.family] += 1
            cone_requirements.append(cone_requirement_record(pair, candidate, row_id))
            result = validate_proof(
                pair, candidate, row_id, cone_by_id.get(row_id), fixed_paths, task_root
            )
            record = reconciliation_record(pair, candidate, row_id, result)
            warning_records.append(record)
            if result.passed:
                reconciled_warning += 1
            proof_semantic_errors += result.semantic_errors
            proof_protocol_errors += result.protocol_errors
            proof_replacement_errors += result.replacement_errors
            changed_record_queues[(pair.product.physical_key(), pair.diagnostic.physical_key())].append(
                record
            )

        extra_proof_ids = sorted(set(cone_by_id) - expected_row_ids)
        missing_proof_ids = sorted(expected_row_ids - set(cone_by_id))
        if extra_proof_ids:
            errors.append(f"unexpected DCP cone proof RowIDs: {extra_proof_ids}")
        if missing_proof_ids:
            errors.append(f"missing DCP cone proof RowIDs: count={len(missing_proof_ids)}")
        if cone_document is not None and len(cone_by_id) != EXPECTED_CHANGED_CRITICAL + EXPECTED_CHANGED_WARNING:
            errors.append(
                "DCP cone proof row count drift: "
                f"expected={EXPECTED_CHANGED_CRITICAL + EXPECTED_CHANGED_WARNING} actual={len(cone_by_id)}"
            )

        expected_critical_candidates = Counter(
            {
                "RESET_COMMIT_STABLE_PAYLOAD": 285,
                "OWNERSHIP_STABLE_PAYLOAD": 10,
            }
        )
        expected_warning_candidates = Counter(
            {
                "RESET_COMMIT_STABLE_PAYLOAD": 163,
                "RESET_ABANDONED_COUNT_STABLE_PAYLOAD": 30,
                "DESCRIPTOR_EPOCH_STABLE_PAYLOAD": 24,
            }
        )
        if critical_candidates != expected_critical_candidates:
            errors.append(
                f"critical source-family distribution drift: expected={expected_critical_candidates} "
                f"actual={critical_candidates}"
            )
        if warning_candidates != expected_warning_candidates:
            errors.append(
                f"warning source-family distribution drift: expected={expected_warning_candidates} "
                f"actual={warning_candidates}"
            )
        summary["RESET_COMMIT_FAMILY_REPRESENTATIVE_CHANGES"] = critical_candidates[
            "RESET_COMMIT_STABLE_PAYLOAD"
        ]
        summary["OWNERSHIP_AND_RELEASE_FAMILY_REPRESENTATIVE_CHANGES"] = (
            critical_candidates["OWNERSHIP_STABLE_PAYLOAD"]
            + len(critical_base_drift)
        )
        summary["CROSS_BASE_CRITICAL_ROWS"] = len(critical_base_drift)
        summary["CROSS_BASE_WARNING_ROWS"] = len(warning_base_drift)
        summary["RECONCILED_CRITICAL_ROWS"] = reconciled_critical
        summary["UNRECONCILED_CRITICAL_ROWS"] = len(critical_changed) - reconciled_critical
        summary["RECONCILED_WARNING_ROWS"] = reconciled_warning
        summary["UNRECONCILED_WARNING_ROWS"] = len(warning_changed) - reconciled_warning
        summary["SEMANTIC_FAMILY_DRIFT"] = proof_semantic_errors
        summary["PROTOCOL_DRIFT"] = proof_protocol_errors
        summary["REPLACEMENT_GROUP_DRIFT"] = proof_replacement_errors

        endpoint_text = "\n".join(
            f"{row.source}|{row.destination}".lower() for row in diagnostic_rows
        )
        diagnostic_hierarchy_rows = sum(
            1
            for row in diagnostic_rows
            if any(
                token in f"{row.source}|{row.destination}".lower()
                for token in DIAGNOSTIC_HIERARCHY_TOKENS
            )
        )
        summary["DIAGNOSTIC_HIERARCHY_CDC_ROWS"] = diagnostic_hierarchy_rows
        if diagnostic_hierarchy_rows:
            errors.append(
                f"diagnostic hierarchy appears in CDC endpoints: rows={diagnostic_hierarchy_rows}"
            )
        if any(token in endpoint_text for token in DIAGNOSTIC_HIERARCHY_TOKENS):
            # Redundant explicit guard keeps future token-list edits fail closed.
            if diagnostic_hierarchy_rows == 0:
                errors.append("diagnostic hierarchy token found but row counter is zero")

    family_columns = ["SemanticFamilyName"] + [
        "AllowedPhysicalSourceBase",
        "AllowedBitIndices",
        "SourceClock",
        "PayloadMeaning",
        "PayloadWidth",
        "GoverningRequestOrCompletionToken",
        "AcknowledgementOrCompletionProtocol",
        "EarliestSemanticUseBarrier",
        "ExistingReplacementGroup",
        "ExistingAuthorityEvidence",
    ]
    write_csv(output_dir / FAMILY_CSV_NAME, family_columns, source_family_rows())
    critical_sha = write_csv(
        output_dir / CRITICAL_CSV_NAME, RECONCILIATION_COLUMNS, critical_records
    )
    warning_sha = write_csv(
        output_dir / WARNING_CSV_NAME, RECONCILIATION_COLUMNS, warning_records
    )
    summary["CRITICAL_RECONCILIATION_CSV_SHA256"] = critical_sha
    summary["WARNING_RECONCILIATION_CSV_SHA256"] = warning_sha
    if product_rows and diagnostic_rows:
        destination_columns = [
            "Rule",
            "Severity",
            "Description",
            "Depth",
            "SourceClock",
            "DestinationClock",
            "Exception",
            "DestinationEndpoint",
            "ProductMultiplicity",
            "DiagnosticMultiplicity",
            "Disposition",
        ]
        write_csv(
            output_dir / DESTINATION_CSV_NAME,
            destination_columns,
            destination_comparison_rows(product_rows, diagnostic_rows),
        )

    cone_requirements_document = {
        "Schema": CONE_REQUIREMENTS_SCHEMA,
        "RequiredInputSchema": CONE_SCHEMA,
        "Classification": "FAIL_CLOSED_PROOF_REQUIREMENTS_NOT_PROOF",
        "RoutedDCPSHA256": hashes.get("ROUTED_DCP_SHA256", ""),
        "ProductCDCReportSHA256": hashes.get("PRODUCT_CDC_REPORT_SHA256", ""),
        "DiagnosticCDCReportSHA256": hashes.get("DIAGNOSTIC_CDC_REPORT_SHA256", ""),
        "RTLSHA256": hashes.get("RTL_SHA256", ""),
        "XDCSHA256": hashes.get("XDC_SHA256", ""),
        "StructuralReceiptSHA256": hashes.get("STRUCTURAL_RECEIPT_SHA256", ""),
        "ReplacementReceiptSHA256": hashes.get("REPLACEMENT_RECEIPT_SHA256", ""),
        "ExpectedTopLevelLiterals": {
            "Classification": "TASK_LOCAL_READ_ONLY_ROUTED_DCP_CONE_PROOF",
            "ProductCDC1PhysicalManifestSHA256": EXPECTED_PRODUCT_CDC1_SHA256,
            "DiagnosticCDC1PhysicalManifestSHA256": EXPECTED_DIAGNOSTIC_CDC1_SHA256,
            "ChangedCriticalRows": EXPECTED_CHANGED_CRITICAL,
            "ChangedWarningRows": EXPECTED_CHANGED_WARNING,
            "QueryCompleteness": "COMPLETE_522_ROW_MULTISET",
            "RoutedDCPReadOnly": True,
            "SourceOrConstraintModified": False,
            "DiagnosticHierarchyConeRows": 0,
            "DifferentSourceBaseNormalization": "PROHIBITED",
            "ProofMayOverrideSourceBaseDrift": False,
        },
        "Rows": cone_requirements,
    }
    write_json(output_dir / CONE_REQUIREMENTS_NAME, cone_requirements_document)

    hard_gate_fields = {
        "RAW_CRITICAL_COUNT": EXPECTED_CRITICAL_TOTAL,
        "RAW_WARNING_COUNT": EXPECTED_WARNING_TOTAL,
        "CDC_1_CRITICAL": 423,
        "CDC_10_CRITICAL": 2,
        "CDC_13_CRITICAL": 2,
        "CDC_6_WARNING": 13,
        "CDC_15_WARNING": 861,
        "CDC_1_DESTINATION_ROWS_IDENTICAL": 423,
        "NEW_CDC_1_DESTINATIONS": 0,
        "MISSING_CDC_1_DESTINATIONS": 0,
        "DESTINATION_MULTIPLICITY_DRIFT": 0,
        "CDC_1_BYTE_IDENTICAL_ROWS": 121,
        "CDC_10_BYTE_IDENTICAL_ROWS": 2,
        "CDC_13_BYTE_IDENTICAL_ROWS": 2,
        "CHANGED_CRITICAL_ROWS": 302,
        "RECONCILED_CRITICAL_ROWS": 302,
        "UNRECONCILED_CRITICAL_ROWS": 0,
        "RESET_COMMIT_FAMILY_REPRESENTATIVE_CHANGES": 285,
        "OWNERSHIP_AND_RELEASE_FAMILY_REPRESENTATIVE_CHANGES": 17,
        "CROSS_BASE_CRITICAL_ROWS": 7,
        "SOURCE_BASE_DRIFT_CRITICAL_ROWS": 0,
        "CHANGED_WARNING_ROWS": 220,
        "RECONCILED_WARNING_ROWS": 220,
        "UNRECONCILED_WARNING_ROWS": 0,
        "CROSS_BASE_WARNING_ROWS": 3,
        "SOURCE_BASE_DRIFT_WARNING_ROWS": 0,
        "SOURCE_BASE_DRIFT_TOTAL": 0,
        "RULE_DRIFT": 0,
        "SEVERITY_DRIFT": 0,
        "CLOCK_PAIR_DRIFT": 0,
        "EXCEPTION_DRIFT": 0,
        "SEMANTIC_FAMILY_DRIFT": 0,
        "PROTOCOL_DRIFT": 0,
        "REPLACEMENT_GROUP_DRIFT": 0,
        "DIAGNOSTIC_HIERARCHY_CDC_ROWS": 0,
        "STRUCTURAL_CDC": "PASS",
        "REPLACEMENT_CHECKS_PASS": 17,
        "UNRESOLVED_REPLACEMENT_CHECKS": 0,
    }
    for field, expected in hard_gate_fields.items():
        actual = summary.get(field, "N/A")
        if actual != expected:
            errors.append(f"formal gate {field} failed: expected={expected!r} actual={actual!r}")

    if not errors:
        # All non-critical/warning rows were required to remain physically exact,
        # so this is a complete parsed-report manifest with no hidden normalization.
        semantic_records = build_semantic_manifest(
            all_pairs, {key: deque(value) for key, value in changed_record_queues.items()}
        )
        if len(semantic_records) != len(diagnostic_rows):
            errors.append(
                f"semantic manifest multiplicity drift: expected={len(diagnostic_rows)} "
                f"actual={len(semantic_records)}"
            )
        else:
            semantic_csv_data = csv_bytes(MANIFEST_COLUMNS, semantic_records)
            semantic_json_document = {
                "Schema": "NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V1",
                "Classification": CLASSIFICATION,
                "CDCDisposition": PASS_DISPOSITION,
                "SourceCommit": "fcab95726761a0666a67e31c283dbdfb9e775074",
                "SourceTree": "bbf1a5fee70a2eb68bb96305ed10934a1559ca6a",
                "RoutedDCPSHA256": EXPECTED_DCP_SHA256,
                "ProductCDC1PhysicalManifestSHA256": EXPECTED_PRODUCT_CDC1_SHA256,
                "DiagnosticCDC1PhysicalManifestSHA256": EXPECTED_DIAGNOSTIC_CDC1_SHA256,
                "ExactRowMultiplicity": len(semantic_records),
                "Rows": semantic_records,
            }
            semantic_json_data = json_bytes(semantic_json_document)
            semantic_csv_sha = sha256_bytes(semantic_csv_data)
            semantic_json_sha = sha256_bytes(semantic_json_data)
            for stem in (SEMANTIC_STEM, SEMANTIC_ALIAS_STEM):
                (output_dir / f"{stem}.csv").write_bytes(semantic_csv_data)
                (output_dir / f"{stem}.json").write_bytes(semantic_json_data)
                write_text(
                    output_dir / f"{stem}.sha256",
                    f"{semantic_csv_sha}  {stem}.csv\n{semantic_json_sha}  {stem}.json\n",
                )
            summary["RESULT"] = "PASS"
            summary["FAILURE_LITERAL"] = "NONE"
            summary["CDC_DISPOSITION"] = PASS_DISPOSITION
            summary["SEMANTIC_MANIFEST_ROW_COUNT"] = len(semantic_records)
            summary["SEMANTIC_MANIFEST_CSV_SHA256"] = semantic_csv_sha
            summary["SEMANTIC_MANIFEST_JSON_SHA256"] = semantic_json_sha

    if errors:
        # A missing or invalid family/cone proof is the most specific formal
        # blocker when the physical reproduction itself is otherwise exact.
        unresolved = summary.get("UNRECONCILED_CRITICAL_ROWS", 0) or summary.get(
            "UNRECONCILED_WARNING_ROWS", 0
        )
        if summary.get("SOURCE_BASE_DRIFT_TOTAL", 0):
            summary["FAILURE_LITERAL"] = "NVP_DIAG1_R2_PROHIBITED_SOURCE_BASE_DRIFT"
        elif unresolved:
            summary["FAILURE_LITERAL"] = "NVP_DIAG1_R2_UNRECONCILED_CDC_SOURCE_FAMILY"
        else:
            summary["FAILURE_LITERAL"] = "NVP_DIAG1_R2_SEMANTIC_RECONCILIATION_FAILED"
        summary["RESULT"] = "FAIL"
        summary["CDC_DISPOSITION"] = "FAIL_NO_SEMANTIC_MANIFEST"

    summary["ERROR_COUNT"] = len(errors)
    summary_json_document = dict(summary)
    summary_json_document["Errors"] = list(errors)
    write_json(output_dir / SUMMARY_JSON_NAME, summary_json_document)
    write_text(output_dir / SUMMARY_TXT_NAME, summary_text(summary, errors))

    print(f"RESULT={summary['RESULT']}")
    print(f"SUMMARY={output_dir / SUMMARY_TXT_NAME}")
    print(f"ERROR_COUNT={len(errors)}")
    return 0 if summary["RESULT"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
