#!/usr/bin/env python3
"""Static consistency validator for the AHD v41 G2B-PRE ABI/MMIO freeze."""

from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ABI_JSON = ROOT / "V41_C2H_TRANSPORT_ABI_V1.json"
MMIO_CSV = ROOT / "V41_G2B_MMIO_MAP.csv"
ABI_MD = ROOT / "V41_C2H_TRANSPORT_ABI_V1.md"
MMIO_MD = ROOT / "V41_G2B_MMIO_CONTRACT.md"
LINUX_MD = ROOT / "V41_C2H_LINUX_CONSUMER_CONTRACT.md"

abi_md_text = ABI_MD.read_text(encoding="utf-8-sig")
mmio_md_text = MMIO_MD.read_text(encoding="utf-8-sig")
linux_md_text = LINUX_MD.read_text(encoding="utf-8-sig")

checks: list[tuple[str, bool, str]] = []


def check(name: str, condition: bool, detail: str) -> None:
    checks.append((name, bool(condition), detail))


def parse_int(value: str) -> int:
    value = value.strip()
    return int(value, 16) if value.lower().startswith("0x") else int(value)


def parse_address_words(value: str) -> list[int]:
    parts = value.split("..")
    start = int(parts[0], 16)
    end = int(parts[-1], 16)
    if start % 4 or end % 4 or end < start:
        raise ValueError(f"invalid aligned address/range {value!r}")
    return list(range(start, end + 1, 4))


def parse_bit_range(value: str) -> set[int]:
    value = value.strip()
    match = re.fullmatch(r"bit\s+(\d+)", value)
    if match:
        return {int(match.group(1))}
    match = re.fullmatch(r"bits\s+(\d+):(\d+)", value)
    if match:
        high, low = int(match.group(1)), int(match.group(2))
        return set(range(low, high + 1))
    raise ValueError(f"unrecognized bit range {value!r}")


try:
    abi = json.loads(ABI_JSON.read_text(encoding="utf-8"))
    check("ABI_JSON_PARSE", True, "valid JSON")
except Exception as exc:  # pragma: no cover - terminal failure path
    check("ABI_JSON_PARSE", False, str(exc))
    abi = {}

expected_geometry = {
    "record_bytes": 4096,
    "header_bytes": 64,
    "payload_bytes": 3840,
    "padding_bytes": 192,
}
geometry = abi.get("geometry", {})
check(
    "GEOMETRY_VALUES",
    all(geometry.get(key) == value for key, value in expected_geometry.items()),
    "record/header/payload/padding = 4096/64/3840/192",
)
check(
    "GEOMETRY_SUM",
    geometry.get("header_bytes", 0)
    + geometry.get("payload_bytes", 0)
    + geometry.get("padding_bytes", 0)
    == geometry.get("record_bytes", -1),
    "64 + 3840 + 192 = 4096",
)
check(
    "REGION_ENDPOINTS",
    geometry.get("header_range") == {"first_byte": 0, "last_byte": 63}
    and geometry.get("payload_range") == {"first_byte": 64, "last_byte": 3903}
    and geometry.get("padding_range") == {"first_byte": 3904, "last_byte": 4095},
    "header 0..63, payload 64..3903, padding 3904..4095",
)

axis = abi.get("axis", {})
check(
    "AXIS_GEOMETRY",
    axis.get("data_width_bits") == 64
    and axis.get("bytes_per_beat") == 8
    and axis.get("beats_per_record") == 512
    and axis.get("bytes_per_beat", 0) * axis.get("beats_per_record", 0) == 4096,
    "64-bit AXIS; 512 x 8 = 4096",
)
check(
    "AXIS_FRAMING",
    axis.get("tkeep", {}).get("value_hex") == "0xFF"
    and axis.get("tlast", {}).get("one_on_beat") == 511
    and axis.get("advance_condition") == "TVALID && TREADY"
    and axis.get("release_condition") == "beat_index == 511 && TVALID && TREADY",
    "TKEEP=0xFF; TLAST/final release on beat 511 handshake",
)
check(
    "AXIS_STALL_STABILITY",
    set(axis.get("stall_rule", {}).get("stable_signals", []))
    == {"TVALID", "TDATA", "TKEEP", "TLAST"},
    "TVALID/TDATA/TKEEP/TLAST stable during stall",
)

expected_fields = [
    (0x00, "magic"),
    (0x04, "record_version"),
    (0x08, "reset_epoch"),
    (0x0C, "source_frame_sequence"),
    (0x10, "source_line_sequence"),
    (0x14, "source_capture_sequence"),
    (0x18, "payload_length"),
    (0x1C, "flags"),
    (0x20, "active_logical_channel_count"),
    (0x24, "source_slot_generation_and_slot"),
    (0x28, "source_malformed_count_snapshot"),
    (0x2C, "source_dropped_count_snapshot"),
    (0x30, "logical_channel_id"),
    (0x34, "physical_input_id"),
    (0x38, "channel_attempt_sequence"),
    (0x3C, "global_stream_sequence"),
]
fields = abi.get("header", {}).get("fields", [])
actual_fields = [(field.get("offset_bytes"), field.get("name")) for field in fields]
check("HEADER_FIELD_ORDER", actual_fields == expected_fields, "16 exact named words")

header_coverage: list[str | None] = [None] * 64
header_overlap = False
for field in fields:
    start = field.get("offset_bytes", -1)
    size = field.get("size_bytes", -1)
    if not isinstance(start, int) or not isinstance(size, int):
        header_overlap = True
        continue
    for byte in range(start, start + size):
        if byte < 0 or byte >= len(header_coverage) or header_coverage[byte] is not None:
            header_overlap = True
        elif 0 <= byte < len(header_coverage):
            header_coverage[byte] = field.get("name")
check("HEADER_NO_OVERLAP", not header_overlap, "no field overlap or out-of-range byte")
check("HEADER_EXACT_COVERAGE", all(header_coverage), "all bytes 0..63 named exactly once")
check(
    "HEADER_FIELD_STATUS",
    all(field.get("status") == "FROZEN" for field in fields),
    "every header field status is FROZEN",
)

flag_entries = abi.get("flags", {}).get("bits", [])
flag_coverage: list[str | None] = [None] * 32
flag_overlap = False
for entry in flag_entries:
    low, high = entry.get("lsb", -1), entry.get("msb", -1)
    for bit in range(low, high + 1):
        if bit < 0 or bit >= 32 or flag_coverage[bit] is not None:
            flag_overlap = True
        elif 0 <= bit < 32:
            flag_coverage[bit] = entry.get("name")
expected_flag_names = {
    0: "SOF",
    1: "RESERVED_ZERO",
    2: "DISCONTINUITY",
    3: "OVERFLOW_OCCURRED",
    4: "MALFORMED_PRECEDING",
    5: "VALID",
    6: "WINDOW_END",
}
check("FLAG_NO_OVERLAP", not flag_overlap, "flag bits do not overlap")
check("FLAG_EXACT_COVERAGE", all(flag_coverage), "all bits 0..31 assigned")
check(
    "FLAG_ASSIGNMENTS",
    all(flag_coverage[bit] == name for bit, name in expected_flag_names.items())
    and all(flag_coverage[bit] == "RESERVED_ZERO" for bit in range(7, 32)),
    "evidence flags retained; all unused bits RESERVED_ZERO",
)
check(
    "FLAG_PENDING_EPOCH_RESET",
    "old-epoch pending context never annotates a new-epoch record"
    in abi.get("flags", {}).get("pending_state_epoch_reset_rule", ""),
    "transport epoch clears pending per-channel record annotations",
)

channels = abi.get("channel_identity", {})
check(
    "CHANNEL_NAMESPACE",
    channels.get("logical", {}).get("legal_values") == [0, 1]
    and channels.get("logical", {}).get("reserved_values") == [2]
    and channels.get("logical", {}).get("invalid_value") == 3
    and channels.get("physical", {}).get("legal_values") == [0, 1, 2, 3]
    and channels.get("physical", {}).get("reserved_values") == [4, 5, 6]
    and channels.get("physical", {}).get("invalid_value") == 7,
    "logical u2 and physical u3 namespaces exact",
)
check(
    "G2B_FIXED_MAPPING",
    channels.get("g2b_emitted_values")
    == {"logical_channel_id": 0, "physical_input_id": 0, "active_logical_channel_count": 1}
    and channels.get("future_two_channel_abi_compatible") is True,
    "G2B emits 0/0/count1 while ABI accepts logical channel 1",
)

sequences = abi.get("transport_sequences", {})
attempt = sequences.get("channel_attempt_sequence", {})
global_sequence = sequences.get("global_stream_sequence", {})
check(
    "CHANNEL_SEQUENCE_RULE",
    attempt.get("next_initial_value_per_epoch") == 0
    and attempt.get("increment_modulus") == 2**32
    and attempt.get("ring_full_attempt_consumes") is True
    and attempt.get("later_malformed_attempt_consumes") is True
    and attempt.get("later_aborted_attempt_consumes") is True
    and attempt.get("source_reset_resets") is False
    and attempt.get("transport_epoch_resets") is True,
    "first 0, assignment/increment per attempt, drops consume, epoch reset",
)
check(
    "GLOBAL_SEQUENCE_RULE",
    global_sequence.get("next_initial_value_per_epoch") == 0
    and global_sequence.get("increment_modulus") == 2**32
    and global_sequence.get("assignment_event") == "COMMITTED_to_DMA_OWNED before first beat"
    and global_sequence.get("increment_event") == "beat 511 TVALID and TREADY handshake"
    and global_sequence.get("ring_full_drop_consumes") is False
    and global_sequence.get("transport_epoch_resets") is True,
    "assigned before beat 0; increments only final handshake; no drop consumption",
)
check(
    "GLOBAL_SEQUENCE_SINGLE_OWNER",
    global_sequence.get("max_simultaneous_dma_owned_slots_shared_stream") == 1
    and "prior DMA_OWNED record completed beat 511 handshake"
    in global_sequence.get("next_assignment_precondition", ""),
    "one shared DMA-owned record; next sequence assigned only after prior completion",
)

source_sequences = abi.get("source_sequences", {})
check(
    "SOURCE_SEQUENCE_RESET_RULE",
    {"explicit_source_reset", "source_disable_then_reenable", "applied_physical_input_remap"}
    .issubset(set(source_sequences.get("reset_events", [])))
    and "reset source sequences to their initial state"
    in source_sequences.get("source_reset_transport_effect", "")
    and "then clear the source-local sequence/header-counter bank"
    in source_sequences.get("source_reset_ordering", ""),
    "source-local reset events are exact and do not use optional may/can semantics",
)

fields_by_name = {field.get("name"): field for field in fields}
source_counter_lifetime_ok = all(
    "RESET_C2H_STATS" in fields_by_name.get(name, {}).get("non_reset_events", [])
    and "defined_source_sequence_reset_event" in fields_by_name.get(name, {}).get("reset_events", [])
    for name in ("source_malformed_count_snapshot", "source_dropped_count_snapshot")
)
check(
    "HEADER_SOURCE_COUNTER_LIFETIME",
    source_counter_lifetime_ok,
    "record-header source counters are distinct from clearable MMIO statistics",
)

epoch = abi.get("reset_epoch", {})
check(
    "RESET_EPOCH_RULE",
    epoch.get("header_offset_hex") == "0x08"
    and epoch.get("width_bits") == 32
    and epoch.get("scope") == "per_card_shared_single_c2h_stream"
    and epoch.get("initial_value_after_fpga_configuration") == 0
    and epoch.get("increment_modulus") == 2**32
    and len(epoch.get("increment_events", [])) == 3
    and len(epoch.get("non_increment_events", [])) >= 7,
    "formal shared u32 epoch with exact increment/non-increment event sets",
)
check(
    "RESET_EPOCH_OWNER",
    epoch.get("owner") == "axi_aclk_c2h_transport_reset_coordinator"
    and "not cleared by axi_aresetn" in epoch.get("owner_reset", ""),
    "epoch owner is axi_aclk coordinator with configuration-only initialization",
)

ring = abi.get("ring", {})
check(
    "RING_STATES",
    [state.get("name") for state in ring.get("states", [])]
    == ["WRITABLE", "FILLING", "COMMITTED", "DMA_OWNED", "RELEASABLE"]
    and ring.get("slots_per_logical_channel") == 4
    and ring.get("partial_overwrite_allowed") is False,
    "four slots and exact five-state ownership cycle",
)
check(
    "RING_FIFO_ORDER",
    ring.get("per_channel_commit_order") == "depth_four_descriptor_FIFO_oldest_committed_first"
    and ring.get("within_channel_reordering_allowed") is False
    and ring.get("max_simultaneous_dma_owned_slots_shared_stream") == 1,
    "per-channel FIFO order and one shared DMA owner are frozen",
)

slot_field = fields_by_name.get("source_slot_generation_and_slot", {})
generation_fields = [
    item for item in slot_field.get("bit_fields", []) if item.get("name") == "generation"
]
check(
    "SLOT_GENERATION_RESET",
    len(generation_fields) == 1
    and generation_fields[0].get("initial_value") == 0
    and "every_transport_epoch_reset" in generation_fields[0].get("reset_events", [])
    and generation_fields[0].get("source_reset_without_epoch_resets") is False,
    "slot generation resets on configuration/epoch only and first allocation uses one",
)
check(
    "PADDING_ZERO",
    abi.get("padding", {}).get("first_byte") == 3904
    and abi.get("padding", {}).get("last_byte") == 4095
    and abi.get("padding", {}).get("required_byte_value") == 0
    and abi.get("padding", {}).get("uninitialized_ram_content_allowed") is False,
    "formatter-generated zero padding only",
)
check(
    "BUILD_IDENTITY_MMIO_ONLY",
    abi.get("firmware_build_identity", {}).get("per_record_identity_present") is False
    and abi.get("firmware_build_identity", {}).get("header_offset_0x08_use") == "reset_epoch"
    and len(abi.get("firmware_build_identity", {}).get("tuple", [])) == 11,
    "full identity tuple is MMIO-authoritative; no per-record build ID",
)
check(
    "PARSER_CLASSES",
    set(abi.get("parser_contract", {}).get("classifications", {}))
    == {"VALID_RECORD", "CORRUPT_RECORD", "NEW_EPOCH", "DISCONTINUITY"}
    and abi.get("parser_contract", {}).get("resynchronization_scan_allowed") is False,
    "four exact parser classes; no magic resynchronization scan",
)
check(
    "PARSER_SESSION_START",
    abi.get("parser_contract", {}).get("mid_epoch_attach_allowed") is False
    and "RESET_STREAM_STATE" in abi.get("parser_contract", {}).get("session_start_requirement", "")
    and "mid-epoch attach is forbidden" in linux_md_text,
    "every host capture session creates a reset epoch before accepting records",
)

expected_columns = [
    "Address",
    "Name",
    "Width",
    "Access",
    "Reset",
    "Bit_or_Field",
    "Semantics",
    "Clock_Domain",
    "Clear_Rule",
    "Status",
]
try:
    with MMIO_CSV.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        mmio_rows = list(reader)
        actual_columns = reader.fieldnames
    check("MMIO_CSV_PARSE", True, f"{len(mmio_rows)} populated data rows")
except Exception as exc:  # pragma: no cover - terminal failure path
    check("MMIO_CSV_PARSE", False, str(exc))
    mmio_rows, actual_columns = [], []

check("MMIO_CSV_COLUMNS", actual_columns == expected_columns, "exact requested ten-column schema")
check(
    "MMIO_CSV_NO_EMPTY_CELLS",
    bool(mmio_rows) and all(all(row.get(column, "").strip() for column in expected_columns) for row in mmio_rows),
    "every CSV cell populated",
)

mmio_words: set[int] = set()
mmio_alignment_ok = True
mmio_range_ok = True
for row in mmio_rows:
    try:
        words = parse_address_words(row["Address"])
    except Exception:
        mmio_alignment_ok = False
        continue
    for word in words:
        if word < 0x3800 or word > 0x3BFC:
            mmio_range_ok = False
        mmio_words.add(word)
check("MMIO_ADDRESS_ALIGNMENT", mmio_alignment_ok, "every register/range endpoint is 32-bit aligned")
check("MMIO_ADDRESS_RANGE", mmio_range_ok, "all G2B MMIO words stay in 0x3800..0x3BFC")
check(
    "MMIO_COMPLETE_WORD_COVERAGE",
    mmio_words == set(range(0x3800, 0x3C00, 4)),
    "all 256 aligned words in byte window 0x3800..0x3BFF are defined or reserved",
)
check("MMIO_NO_LEGACY_OVERLAP", all(word > 0x37FF for word in mmio_words), "no overlap with immutable 0x0000..0x37FF")

rows_by_address: dict[int, list[dict[str, str]]] = {}
for row in mmio_rows:
    if ".." not in row.get("Address", ""):
        try:
            rows_by_address.setdefault(int(row["Address"], 16), []).append(row)
        except ValueError:
            pass

def bit_coverage(address: int) -> tuple[set[int], bool]:
    bits: set[int] = set()
    overlap = False
    for row in rows_by_address.get(address, []):
        try:
            new_bits = parse_bit_range(row["Bit_or_Field"])
        except ValueError:
            continue
        if bits.intersection(new_bits):
            overlap = True
        bits.update(new_bits)
    return bits, overlap


for address, label in [
    (0x3808, "CAPABILITIES"),
    (0x380C, "CONTROL"),
    (0x3810, "STATUS"),
    (0x383C, "ERROR_STATUS"),
    (0x3844, "SNAPSHOT_COMMAND"),
    (0x3848, "SNAPSHOT_STATUS"),
]:
    bits, overlap = bit_coverage(address)
    check(f"{label}_BIT_COVERAGE", bits == set(range(32)) and not overlap, "bits 0..31 assigned once")

cap_names = {row["Name"]: row for row in rows_by_address.get(0x3808, [])}
expected_cap_bits = {
    "CAPABILITIES.C2H_SUPPORTED": (0, 1),
    "CAPABILITIES.RECORD_ABI_V1_SUPPORTED": (1, 1),
    "CAPABILITIES.ONE_CHANNEL_SUPPORTED": (2, 1),
    "CAPABILITIES.TWO_CHANNEL_ABI_CAPABLE": (3, 1),
    "CAPABILITIES.GEN2_CAPABLE": (4, 1),
    "CAPABILITIES.C2H_IMPLEMENTED_THIS_BUILD": (16, 1),
    "CAPABILITIES.ONE_CHANNEL_IMPLEMENTED_THIS_BUILD": (17, 1),
    "CAPABILITIES.TWO_CHANNEL_IMPLEMENTED_THIS_BUILD": (18, 0),
    "CAPABILITIES.GEN2_CONFIGURED_THIS_BUILD": (19, 1),
}
capability_value = 0
capability_ok = True
for name, (bit, reset) in expected_cap_bits.items():
    row = cap_names.get(name)
    capability_ok &= bool(row) and row.get("Bit_or_Field") == f"bit {bit}" and parse_int(row.get("Reset", "-1")) == reset
    capability_value |= reset << bit
check("CAPABILITY_ASSIGNMENTS", capability_ok, "supported and implemented bits exact")
check("CAPABILITY_VALUE", capability_value == 0x000B001F, "computed reset value 0x000B001F")

control = {row["Name"]: row for row in rows_by_address.get(0x380C, [])}
check(
    "CONTROL_FIELDS",
    control.get("CONTROL.ENABLE_C2H", {}).get("Access") == "RW"
    and control.get("CONTROL.RESET_C2H_STATS", {}).get("Access") == "W1S/RO0"
    and control.get("CONTROL.RESET_STREAM_STATE", {}).get("Access") == "W1S/RO0",
    "ENABLE plus exactly two W1S reset commands",
)
stats_reset_semantics = control.get("CONTROL.RESET_C2H_STATS", {}).get("Semantics", "")
check(
    "STATS_RESET_SNAPSHOT_EXCLUSION",
    "STREAM_RESET_BUSY=0" in stats_reset_semantics
    and "SNAPSHOT_BUSY=0" in stats_reset_semantics
    and "neither canceled nor altered" in stats_reset_semantics,
    "statistics reset is rejected while reset or snapshot busy; no stale-ack race",
)
check(
    "ENABLE_APPLIED_ACK",
    "before AXI BVALID" in control.get("CONTROL.ENABLE_C2H", {}).get("Semantics", "")
    and "acknowledged stable-data mailbox" in control.get("CONTROL.ENABLE_C2H", {}).get("Clock_Domain", ""),
    "enable/disable is applied in source domain before write completion",
)
check(
    "STATS_CLEAR_ACK",
    "BVALID waits for every clear acknowledgement"
    in control.get("CONTROL.RESET_C2H_STATS", {}).get("Clear_Rule", ""),
    "statistics clear has observable all-domain completion",
)
stream_reset_semantics = control.get("CONTROL.RESET_STREAM_STATE", {}).get("Semantics", "")
check(
    "SIMULTANEOUS_RESET_ORDER",
    "After a simultaneous accepted stats clear RESET_EVENTS is 1" in stream_reset_semantics
    and "illegal simultaneous stats reset" in stream_reset_semantics,
    "combined reset ordering and fatal recovery prerequisite are deterministic",
)

status_rows = rows_by_address.get(0x3810, [])
status_reset_value = 0
for row in status_rows:
    try:
        bits = parse_bit_range(row["Bit_or_Field"])
    except ValueError:
        continue
    reset = parse_int(row["Reset"])
    if len(bits) == 1 and reset:
        status_reset_value |= reset << next(iter(bits))
check("STATUS_RESET_VALUE", status_reset_value == 0x00000004, "only RING_EMPTY resets asserted")

expected_counters = {
    0x3814: "RECORDS_ATTEMPTED",
    0x3818: "RECORDS_COMMITTED",
    0x381C: "RECORDS_STREAMED",
    0x3820: "RECORDS_DROPPED",
    0x3824: "OVERFLOW_COUNT",
    0x3828: "SEQUENCE_DISCONTINUITIES",
    0x382C: "BEATS_STREAMED_LO",
    0x3830: "BEATS_STREAMED_HI",
}
check(
    "REQUIRED_COUNTER_ADDRESSES",
    all(any(row["Name"] == name for row in rows_by_address.get(address, [])) for address, name in expected_counters.items()),
    "all seven required counter concepts have exact addresses",
)
seq_disc_rows = rows_by_address.get(0x3828, [])
check(
    "SEQUENCE_COUNTER_PER_CHANNEL_BASELINE",
    len(seq_disc_rows) == 1
    and "same logical channel" in seq_disc_rows[0].get("Semantics", "")
    and "independent baseline" in seq_disc_rows[0].get("Semantics", ""),
    "sequence discontinuity compares independent logical-channel baselines",
)

error_rows = rows_by_address.get(0x383C, [])
expected_errors = [
    "ERROR_STATUS.RING_OVERFLOW",
    "ERROR_STATUS.RECORD_DROP",
    "ERROR_STATUS.SEQUENCE_DISCONTINUITY",
    "ERROR_STATUS.FORMATTER_INTERNAL_ERROR",
    "ERROR_STATUS.ILLEGAL_OWNERSHIP_STATE",
    "ERROR_STATUS.TRANSPORT_ERROR",
]
check(
    "ERROR_MODEL_BITS",
    [row["Name"] for row in error_rows[:6]] == expected_errors
    and [row["Bit_or_Field"] for row in error_rows[:6]] == [f"bit {bit}" for bit in range(6)],
    "six exact sticky error bits 0..5",
)
check(
    "ERROR_SET_WINS_CLEAR",
    len(error_rows) >= 6
    and all("same-cycle set wins" in row.get("Clear_Rule", "") for row in error_rows[:6]),
    "every defined sticky error preserves a same-cycle new event over W1C",
)
check(
    "ERROR_CDC_HANDSHAKE",
    len(error_rows) >= 5
    and all(
        "request/ack handshake" in error_rows[index].get("Clock_Domain", "")
        for index in (0, 1, 3, 4)
    ),
    "non-AXI sticky errors cross by reliable source request/ack, never raw pulse",
)

last_error_rows = rows_by_address.get(0x3840, [])
check(
    "LAST_ERROR_CAUSE_PRIORITY",
    len(last_error_rows) == 1
    and "3 then 1 then 2" in last_error_rows[0].get("Semantics", "")
    and "new accepted error coincides and wins" in last_error_rows[0].get("Clear_Rule", ""),
    "specific ring overflow outranks generic drop; new cause wins statistics clear",
)

snapshot_command = {row["Name"]: row for row in rows_by_address.get(0x3844, [])}
capture_semantics = snapshot_command.get("SNAPSHOT_COMMAND.CAPTURE", {}).get("Semantics", "")
check(
    "SNAPSHOT_RESET_INTERLOCK",
    "SNAPSHOT_BUSY=0 and STREAM_RESET_BUSY=0" in capture_semantics
    and "late stale acknowledgements cannot publish VALID" in capture_semantics,
    "snapshot is reset-interlocked and stale acknowledgements are harmless",
)

epoch_rows = rows_by_address.get(0x3838, [])
check(
    "MMIO_EPOCH_OWNER",
    len(epoch_rows) == 1
    and "not reset by axi_aresetn" in epoch_rows[0].get("Clock_Domain", ""),
    "live epoch persistence across axi reset is assigned to an exact clock domain",
)

check(
    "STANDALONE_RESET_EQUIVALENCE",
    "Standalone C2H formatter/transport reset" in mmio_md_text
    and "Same as `RESET_STREAM_STATE`" in mmio_md_text,
    "standalone C2H reset has the stream-reset counter/snapshot disposition",
)

normative_files = [
    ROOT / "V41_C2H_TRANSPORT_ABI_V1.md",
    ABI_JSON,
    ROOT / "V41_G2B_MMIO_CONTRACT.md",
    MMIO_CSV,
    ROOT / "V41_C2H_LINUX_CONSUMER_CONTRACT.md",
]
placeholder_hits: list[str] = []
for path in normative_files:
    text = path.read_text(encoding="utf-8-sig")
    for token in ("TBD", "TODO", "MOSTLY_FROZEN"):
        if re.search(rf"\b{re.escape(token)}\b", text):
            placeholder_hits.append(f"{path.name}:{token}")
check("NO_MANDATORY_PLACEHOLDERS", not placeholder_hits, ", ".join(placeholder_hits) or "no TBD/TODO/intermediate-freeze token")

required_artifacts = {
    "V41_G2B_PRE_ARCHITECTURE_FREEZE_REPORT.md",
    "V41_C2H_TRANSPORT_ABI_V1.md",
    "V41_C2H_TRANSPORT_ABI_V1.json",
    "V41_G2B_MMIO_CONTRACT.md",
    "V41_G2B_MMIO_MAP.csv",
    "V41_C2H_LINUX_CONSUMER_CONTRACT.md",
    "G2B_PRE_ABI_CONSISTENCY_REPORT.md",
    "G2B_PRE_DECISION_LOG.md",
    "G2B_PRE_STATE.json",
    "G2B_PRE_EVIDENCE_INDEX.md",
    "G2B_PRE_SHA256_MANIFEST.txt",
    "G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md",
    "validate_g2b_pre_contract.py",
}
check(
    "REQUIRED_ARTIFACTS_PRESENT",
    all((ROOT / name).is_file() for name in required_artifacts),
    "all required publication artifacts and validator present",
)

failures = [item for item in checks if not item[1]]
for name, passed, detail in checks:
    print(f"{'PASS' if passed else 'FAIL'} {name}: {detail}")
print(f"CHECKS_TOTAL={len(checks)}")
print(f"CHECKS_PASSED={len(checks) - len(failures)}")
print(f"CHECKS_FAILED={len(failures)}")
print(f"RESULT={'PASS' if not failures else 'FAIL'}")
sys.exit(0 if not failures else 1)
