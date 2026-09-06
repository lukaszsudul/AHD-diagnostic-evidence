#!/usr/bin/env python3
"""Offline AHD v41 G2B C2H ABI-v1 records.

This module is deliberately stdlib-only and performs no device, MMIO, XDMA,
or hardware access.  The authoritative ABI JSON is supplied by the caller;
the loader rejects a contract that does not match the frozen ABI-v1 identity
and geometry before any record is generated or parsed.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import json
from pathlib import Path
import struct
from typing import Any, Iterable, Iterator, Mapping, Sequence


VALID_RECORD = "VALID_RECORD"
CORRUPT_RECORD = "CORRUPT_RECORD"
NEW_EPOCH = "NEW_EPOCH"
DISCONTINUITY = "DISCONTINUITY"

U32_MASK = 0xFFFFFFFF

FROZEN_HEADER_NAMES = (
    "magic",
    "record_version",
    "reset_epoch",
    "source_frame_sequence",
    "source_line_sequence",
    "source_capture_sequence",
    "payload_length",
    "flags",
    "active_logical_channel_count",
    "source_slot_generation_and_slot",
    "source_malformed_count_snapshot",
    "source_dropped_count_snapshot",
    "logical_channel_id",
    "physical_input_id",
    "channel_attempt_sequence",
    "global_stream_sequence",
)


class ContractError(ValueError):
    """The supplied JSON is not the frozen AHD C2H ABI-v1 contract."""


class RecordValidationError(ValueError):
    """One fixed-boundary record failed structural validation."""

    def __init__(self, errors: Sequence[str]):
        self.errors = tuple(errors)
        super().__init__("; ".join(self.errors))


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def _u32(value: int) -> int:
    return value & U32_MASK


@dataclass(frozen=True)
class HeaderField:
    name: str
    offset: int
    size: int
    definition: Mapping[str, Any]


@dataclass(frozen=True)
class AbiContract:
    """Validated values extracted from the normative ABI JSON."""

    source_path: Path
    raw: Mapping[str, Any]
    record_bytes: int
    header_bytes: int
    payload_bytes: int
    padding_bytes: int
    payload_first: int
    padding_first: int
    fields: tuple[HeaderField, ...]
    offsets: Mapping[str, int]
    magic: int
    record_version: int
    payload_length: int
    flags: Mapping[str, int]
    reserved_flag_mask: int
    logical_width: int
    logical_legal: tuple[int, ...]
    physical_width: int
    physical_legal: tuple[int, ...]
    active_count_legal: tuple[int, ...]
    g2b_logical: int
    g2b_physical: int
    g2b_active_count: int
    pixels_per_line: int
    lines_per_frame: int

    @classmethod
    def load(cls, path: str | Path) -> "AbiContract":
        source_path = Path(path).resolve()
        try:
            raw = json.loads(source_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise ContractError(f"cannot read ABI JSON {source_path}: {exc}") from exc

        document = raw.get("document", {})
        abi = raw.get("abi", {})
        geometry = raw.get("geometry", {})
        axis = raw.get("axis", {})
        header = raw.get("header", {})
        payload = raw.get("payload", {})
        identities = raw.get("channel_identity", {})

        _require(document.get("status") == "FROZEN_FOR_G2B",
                 "contract status is not FROZEN_FOR_G2B")
        _require(document.get("unresolved_mandatory_fields") == [],
                 "contract contains unresolved mandatory fields")
        _require(abi.get("name") == "AHD_C2H_TRANSPORT_ABI_V1",
                 "wrong ABI name")
        _require(abi.get("numeric_version") == 1, "wrong ABI numeric version")
        _require(abi.get("record_version_hex") == "0x00004101",
                 "wrong record version")
        _require(abi.get("endianness") == "little", "ABI is not little-endian")

        record_bytes = geometry.get("record_bytes")
        header_bytes = geometry.get("header_bytes")
        payload_bytes = geometry.get("payload_bytes")
        padding_bytes = geometry.get("padding_bytes")
        payload_first = geometry.get("payload_range", {}).get("first_byte")
        padding_first = geometry.get("padding_range", {}).get("first_byte")
        _require((record_bytes, header_bytes, payload_bytes, padding_bytes) ==
                 (4096, 64, 3840, 192), "wrong frozen record geometry")
        _require(payload_first == 64 and padding_first == 3904,
                 "wrong payload or padding offset")
        _require(header_bytes + payload_bytes + padding_bytes == record_bytes,
                 "record regions do not sum to record size")
        _require(axis.get("data_width_bits") == 64 and
                 axis.get("bytes_per_beat") == 8 and
                 axis.get("beats_per_record") == 512,
                 "wrong AXI geometry")
        _require(axis.get("tkeep", {}).get("value_hex") == "0xFF" and
                 axis.get("tlast", {}).get("one_on_beat") == 511,
                 "wrong AXI framing")

        field_defs = header.get("fields", [])
        _require(header.get("word_count") == 16 and len(field_defs) == 16,
                 "header does not contain sixteen words")
        _require(tuple(item.get("name") for item in field_defs) ==
                 FROZEN_HEADER_NAMES, "header names/order differ from ABI v1")

        fields: list[HeaderField] = []
        offsets: dict[str, int] = {}
        for index, item in enumerate(field_defs):
            offset = item.get("offset_bytes")
            size = item.get("size_bytes")
            _require(offset == index * 4 and size == 4,
                     f"header field {item.get('name')} has wrong geometry")
            _require(item.get("endianness") == "little",
                     f"header field {item.get('name')} is not little-endian")
            name = str(item["name"])
            fields.append(HeaderField(name, int(offset), int(size), item))
            offsets[name] = int(offset)

        flag_defs = raw.get("flags", {}).get("bits", [])
        flags: dict[str, int] = {}
        reserved_flag_mask = 0
        covered_flag_mask = 0
        for item in flag_defs:
            mask = int(item["mask_hex"], 16)
            _require((covered_flag_mask & mask) == 0, "overlapping flag masks")
            covered_flag_mask |= mask
            if item["name"] == "RESERVED_ZERO":
                reserved_flag_mask |= mask
            else:
                flags[str(item["name"])] = mask
        _require(covered_flag_mask == U32_MASK, "flags do not cover all 32 bits")
        _require(flags == {
            "SOF": 0x00000001,
            "DISCONTINUITY": 0x00000004,
            "OVERFLOW_OCCURRED": 0x00000008,
            "MALFORMED_PRECEDING": 0x00000010,
            "VALID": 0x00000020,
            "WINDOW_END": 0x00000040,
        }, "wrong frozen flag assignments")

        logical = identities.get("logical", {})
        physical = identities.get("physical", {})
        g2b = identities.get("g2b_emitted_values", {})
        active_legal = tuple(identities.get(
            "active_logical_channel_count_legal_values", []))
        _require(logical.get("semantic_width_bits") == 2 and
                 tuple(logical.get("legal_values", [])) == (0, 1),
                 "wrong logical-channel namespace")
        _require(physical.get("semantic_width_bits") == 3 and
                 tuple(physical.get("legal_values", [])) == (0, 1, 2, 3),
                 "wrong physical-input namespace")
        _require(active_legal == (1, 2), "wrong active-channel count namespace")
        _require(g2b == {
            "logical_channel_id": 0,
            "physical_input_id": 0,
            "active_logical_channel_count": 1,
        }, "wrong frozen G2B mapping")
        _require(payload.get("format") == "UYVY" and
                 payload.get("pixels_per_line") == 1920 and
                 payload.get("active_lines_per_frame") == 1080,
                 "wrong frozen payload format")

        magic_def = field_defs[0]
        record_version_def = field_defs[1]
        payload_length_def = field_defs[6]
        _require(magic_def.get("value_hex") == "0x4C444841", "wrong magic")
        _require(record_version_def.get("value_hex") == "0x00004101",
                 "wrong header record version")
        _require(payload_length_def.get("value_decimal") == 3840,
                 "wrong header payload length")

        return cls(
            source_path=source_path,
            raw=raw,
            record_bytes=record_bytes,
            header_bytes=header_bytes,
            payload_bytes=payload_bytes,
            padding_bytes=padding_bytes,
            payload_first=payload_first,
            padding_first=padding_first,
            fields=tuple(fields),
            offsets=offsets,
            magic=int(magic_def["value_hex"], 16),
            record_version=int(record_version_def["value_hex"], 16),
            payload_length=int(payload_length_def["value_decimal"]),
            flags=flags,
            reserved_flag_mask=reserved_flag_mask,
            logical_width=int(logical["semantic_width_bits"]),
            logical_legal=tuple(logical["legal_values"]),
            physical_width=int(physical["semantic_width_bits"]),
            physical_legal=tuple(physical["legal_values"]),
            active_count_legal=active_legal,
            g2b_logical=int(g2b["logical_channel_id"]),
            g2b_physical=int(g2b["physical_input_id"]),
            g2b_active_count=int(g2b["active_logical_channel_count"]),
            pixels_per_line=int(payload["pixels_per_line"]),
            lines_per_frame=int(payload["active_lines_per_frame"]),
        )

    def unpack_header(self, record: bytes) -> dict[str, int]:
        return {
            field.name: struct.unpack_from("<I", record, field.offset)[0]
            for field in self.fields
        }


@dataclass(frozen=True)
class RecordMetadata:
    reset_epoch: int
    source_frame_sequence: int
    source_line_sequence: int
    source_capture_sequence: int
    channel_attempt_sequence: int
    global_stream_sequence: int
    logical_channel_id: int = 0
    physical_input_id: int = 0
    active_logical_channel_count: int = 1
    slot: int = 0
    slot_generation: int = 1
    source_malformed_count_snapshot: int = 0
    source_dropped_count_snapshot: int = 0
    discontinuity: bool = False
    overflow_occurred: bool = False
    malformed_preceding: bool = False
    window_end: bool = False
    flags_override: int | None = None


@dataclass(frozen=True)
class ParsedRecord:
    header: Mapping[str, int]
    payload: bytes
    raw: bytes = field(repr=False)

    def value(self, name: str) -> int:
        return int(self.header[name])

    @property
    def reset_epoch(self) -> int:
        return self.value("reset_epoch")

    @property
    def logical_channel_id(self) -> int:
        return self.value("logical_channel_id")

    @property
    def physical_input_id(self) -> int:
        return self.value("physical_input_id")

    @property
    def source_frame_sequence(self) -> int:
        return self.value("source_frame_sequence")

    @property
    def source_line_sequence(self) -> int:
        return self.value("source_line_sequence")

    @property
    def source_capture_sequence(self) -> int:
        return self.value("source_capture_sequence")

    @property
    def channel_attempt_sequence(self) -> int:
        return self.value("channel_attempt_sequence")

    @property
    def global_stream_sequence(self) -> int:
        return self.value("global_stream_sequence")

    @property
    def flags(self) -> int:
        return self.value("flags")


@dataclass(frozen=True)
class RecordComparison:
    expected_bytes: int
    actual_bytes: int
    matching_bytes: int
    mismatch_count: int
    first_mismatch_offset: int | None

    @property
    def exact(self) -> bool:
        return self.mismatch_count == 0 and self.expected_bytes == self.actual_bytes


def compare_record_bytes(expected: bytes, actual: bytes) -> RecordComparison:
    """Compare two record images without resynchronizing or ignoring bytes."""
    common = min(len(expected), len(actual))
    mismatch_offsets = [
        offset for offset in range(common)
        if expected[offset] != actual[offset]
    ]
    length_delta = abs(len(expected) - len(actual))
    mismatch_count = len(mismatch_offsets) + length_delta
    first_mismatch = mismatch_offsets[0] if mismatch_offsets else (
        common if length_delta else None
    )
    return RecordComparison(
        expected_bytes=len(expected),
        actual_bytes=len(actual),
        matching_bytes=common - len(mismatch_offsets),
        mismatch_count=mismatch_count,
        first_mismatch_offset=first_mismatch,
    )


def record_flags(contract: AbiContract, metadata: RecordMetadata) -> int:
    """Construct the exact G2B flags word for one record."""
    if metadata.flags_override is not None:
        return _u32(metadata.flags_override)
    flags = contract.flags["VALID"]
    if metadata.source_line_sequence == 0:
        flags |= contract.flags["SOF"]
    if metadata.discontinuity:
        flags |= contract.flags["DISCONTINUITY"]
    if metadata.overflow_occurred:
        flags |= contract.flags["OVERFLOW_OCCURRED"]
    if metadata.malformed_preceding:
        flags |= contract.flags["MALFORMED_PRECEDING"]
    if metadata.window_end:
        flags |= contract.flags["WINDOW_END"]
    return flags


def deterministic_line_payload(
    contract: AbiContract,
    source_frame_sequence: int,
    source_line_sequence: int,
) -> bytes:
    """Return a deterministic left-to-right UYVY active-line test fixture."""
    if not 0 <= source_line_sequence < contract.lines_per_frame:
        raise ValueError("source line is outside 0..1079")
    payload = bytearray(contract.payload_bytes)
    pair_count = contract.pixels_per_line // 2
    for pair in range(pair_count):
        offset = 4 * pair
        payload[offset + 0] = (source_line_sequence + pair) & 0xFF
        payload[offset + 1] = (source_line_sequence + 2 * pair) & 0xFF
        payload[offset + 2] = (source_frame_sequence + 3 * pair) & 0xFF
        payload[offset + 3] = (source_line_sequence + 2 * pair + 1) & 0xFF
    return bytes(payload)


def build_record(
    contract: AbiContract,
    metadata: RecordMetadata,
    payload: bytes,
) -> bytes:
    """Build one exact 4096-byte ABI-v1 golden record."""
    if len(payload) != contract.payload_bytes:
        raise ValueError(
            f"payload is {len(payload)} bytes, expected {contract.payload_bytes}"
        )
    if not 0 <= metadata.source_line_sequence < contract.lines_per_frame:
        raise ValueError("source line is outside 0..1079")
    if not 0 <= metadata.slot <= 3:
        raise ValueError("slot is outside 0..3")
    if not 0 <= metadata.slot_generation < (1 << 24):
        raise ValueError("slot generation is outside u24")

    values = {
        "magic": contract.magic,
        "record_version": contract.record_version,
        "reset_epoch": metadata.reset_epoch,
        "source_frame_sequence": metadata.source_frame_sequence,
        "source_line_sequence": metadata.source_line_sequence,
        "source_capture_sequence": metadata.source_capture_sequence,
        "payload_length": contract.payload_length,
        "flags": record_flags(contract, metadata),
        "active_logical_channel_count": metadata.active_logical_channel_count,
        "source_slot_generation_and_slot":
            (metadata.slot_generation << 8) | metadata.slot,
        "source_malformed_count_snapshot":
            metadata.source_malformed_count_snapshot,
        "source_dropped_count_snapshot": metadata.source_dropped_count_snapshot,
        "logical_channel_id": metadata.logical_channel_id,
        "physical_input_id": metadata.physical_input_id,
        "channel_attempt_sequence": metadata.channel_attempt_sequence,
        "global_stream_sequence": metadata.global_stream_sequence,
    }
    record = bytearray(contract.record_bytes)
    for field_def in contract.fields:
        struct.pack_into(
            "<I", record, field_def.offset, _u32(int(values[field_def.name]))
        )
    payload_last = contract.payload_first + contract.payload_bytes
    record[contract.payload_first:payload_last] = payload
    # The bytearray is zero-initialized, making every padding byte deterministic.
    return bytes(record)


def generate_frame_records(
    contract: AbiContract,
    *,
    reset_epoch: int = 0,
    source_frame_sequence: int = 1,
    source_capture_first: int = 1,
    channel_attempt_first: int = 0,
    global_stream_first: int = 0,
) -> Iterator[bytes]:
    """Generate one complete deterministic 1080-line ABI-v1 frame stream."""
    for line in range(contract.lines_per_frame):
        metadata = RecordMetadata(
            reset_epoch=_u32(reset_epoch),
            source_frame_sequence=_u32(source_frame_sequence),
            source_line_sequence=line,
            source_capture_sequence=_u32(source_capture_first + line),
            channel_attempt_sequence=_u32(channel_attempt_first + line),
            global_stream_sequence=_u32(global_stream_first + line),
            slot=line % 4,
            slot_generation=(line // 4 + 1) & 0xFFFFFF,
        )
        payload = deterministic_line_payload(
            contract, source_frame_sequence, line
        )
        yield build_record(contract, metadata, payload)


def parse_record(contract: AbiContract, record: bytes) -> ParsedRecord:
    """Parse and structurally validate one fixed-boundary ABI-v1 record."""
    if len(record) != contract.record_bytes:
        raise RecordValidationError((
            f"record size {len(record)} is not {contract.record_bytes}",
        ))

    header = contract.unpack_header(record)
    errors: list[str] = []
    if header["magic"] != contract.magic:
        errors.append(f"bad magic 0x{header['magic']:08X}")
    if header["record_version"] != contract.record_version:
        errors.append(f"bad record version 0x{header['record_version']:08X}")
    if header["payload_length"] != contract.payload_length:
        errors.append(f"bad payload length {header['payload_length']}")

    line = header["source_line_sequence"]
    flags = header["flags"]
    if not 0 <= line < contract.lines_per_frame:
        errors.append(f"source line {line} is outside 0..1079")
    sof = bool(flags & contract.flags["SOF"])
    if sof != (line == 0):
        errors.append("SOF does not agree with source line zero")
    if not flags & contract.flags["VALID"]:
        errors.append("VALID flag is clear")
    if flags & contract.flags["WINDOW_END"]:
        errors.append("WINDOW_END is nonzero in continuous G2B")
    if flags & contract.reserved_flag_mask:
        errors.append("reserved flag bit is nonzero")

    active_count = header["active_logical_channel_count"]
    if active_count not in contract.active_count_legal:
        errors.append(f"illegal active logical channel count {active_count}")

    logical_container = header["logical_channel_id"]
    logical_mask = (1 << contract.logical_width) - 1
    logical = logical_container & logical_mask
    if logical_container & ~logical_mask:
        errors.append("logical channel upper bits are nonzero")
    elif logical not in contract.logical_legal:
        errors.append(f"illegal logical channel {logical}")

    physical_container = header["physical_input_id"]
    physical_mask = (1 << contract.physical_width) - 1
    physical = physical_container & physical_mask
    if physical_container & ~physical_mask:
        errors.append("physical input upper bits are nonzero")
    elif physical not in contract.physical_legal:
        errors.append(f"illegal physical input {physical}")

    slot_word = header["source_slot_generation_and_slot"]
    if slot_word & 0xF0:
        errors.append("source slot reserved bits 7:4 are nonzero")
    if (slot_word & 0xF) > 3:
        errors.append(f"source slot {slot_word & 0xF} is outside 0..3")

    padding = record[contract.padding_first:contract.record_bytes]
    if any(padding):
        first_nonzero = next(index for index, value in enumerate(padding) if value)
        errors.append(
            f"padding byte {contract.padding_first + first_nonzero} is nonzero"
        )
    if errors:
        raise RecordValidationError(errors)

    payload_last = contract.payload_first + contract.payload_bytes
    return ParsedRecord(
        header=header,
        payload=record[contract.payload_first:payload_last],
        raw=bytes(record),
    )


@dataclass(frozen=True)
class RecordAssessment:
    index: int
    classifications: tuple[str, ...]
    record: ParsedRecord | None
    discontinuity_reasons: tuple[str, ...] = ()
    errors: tuple[str, ...] = ()
    session_fatal: bool = False

    @property
    def structurally_valid(self) -> bool:
        return self.record is not None and VALID_RECORD in self.classifications

    def as_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "index": self.index,
            "classifications": list(self.classifications),
            "discontinuity_reasons": list(self.discontinuity_reasons),
            "errors": list(self.errors),
            "session_fatal": self.session_fatal,
        }
        if self.record is not None:
            result["header"] = dict(self.record.header)
        return result


class StreamValidator:
    """Stateful epoch, global, per-channel, source, and mapping checker."""

    def __init__(
        self,
        contract: AbiContract,
        *,
        armed_epoch: int | None = None,
        enforce_g2b_mapping: bool = True,
    ) -> None:
        self.contract = contract
        self.armed_epoch = None if armed_epoch is None else _u32(armed_epoch)
        self.enforce_g2b_mapping = enforce_g2b_mapping
        self.record_index = 0
        self.current_epoch: int | None = None
        self.last_global: int | None = None
        self.last_attempt: dict[int, int] = {}
        self.last_source: dict[int, tuple[int, int, int, int]] = {}

    def accept(self, blob: bytes) -> RecordAssessment:
        index = self.record_index
        self.record_index += 1
        try:
            record = parse_record(self.contract, blob)
        except RecordValidationError as exc:
            return RecordAssessment(
                index=index,
                classifications=(CORRUPT_RECORD,),
                record=None,
                errors=exc.errors,
                session_fatal=True,
            )

        classifications = [VALID_RECORD]
        reasons: list[str] = []
        session_fatal = False
        new_epoch = (self.current_epoch is None or
                     record.reset_epoch != self.current_epoch)
        if new_epoch:
            classifications.append(NEW_EPOCH)
            self.current_epoch = record.reset_epoch
            self.last_global = None
            self.last_attempt.clear()
            self.last_source.clear()
            if index == 0 and self.armed_epoch is not None and \
                    record.reset_epoch != self.armed_epoch:
                reasons.append(
                    f"first record epoch {record.reset_epoch} does not match "
                    f"armed epoch {self.armed_epoch}"
                )
                session_fatal = True
            if record.global_stream_sequence != 0:
                reasons.append(
                    "first observed global stream sequence in epoch is not zero"
                )
        elif self.last_global is not None:
            expected_global = _u32(self.last_global + 1)
            if record.global_stream_sequence != expected_global:
                reasons.append(
                    f"global sequence {record.global_stream_sequence} expected "
                    f"{expected_global}"
                )

        if self.enforce_g2b_mapping:
            observed_mapping = (
                record.logical_channel_id,
                record.physical_input_id,
                record.value("active_logical_channel_count"),
            )
            required_mapping = (
                self.contract.g2b_logical,
                self.contract.g2b_physical,
                self.contract.g2b_active_count,
            )
            if observed_mapping != required_mapping:
                reasons.append(
                    f"G2B mapping {observed_mapping} differs from "
                    f"{required_mapping}"
                )
                session_fatal = True

        channel = record.logical_channel_id
        if channel in self.last_attempt:
            expected_attempt = _u32(self.last_attempt[channel] + 1)
            if record.channel_attempt_sequence != expected_attempt:
                reasons.append(
                    f"channel {channel} attempt sequence "
                    f"{record.channel_attempt_sequence} expected {expected_attempt}"
                )

        if channel in self.last_source:
            previous_frame, previous_line, previous_capture, previous_physical = \
                self.last_source[channel]
            expected_capture = _u32(previous_capture + 1)
            if previous_line == self.contract.lines_per_frame - 1:
                expected_frame = _u32(previous_frame + 1)
                expected_line = 0
            else:
                expected_frame = previous_frame
                expected_line = previous_line + 1
            observed_source = (
                record.source_frame_sequence,
                record.source_line_sequence,
                record.source_capture_sequence,
                record.physical_input_id,
            )
            expected_source = (
                expected_frame,
                expected_line,
                expected_capture,
                previous_physical,
            )
            if observed_source != expected_source:
                reasons.append(
                    f"source progression {observed_source} expected {expected_source}"
                )

        flags = record.flags
        if flags & self.contract.flags["DISCONTINUITY"]:
            reasons.append("DISCONTINUITY flag is set")
        if flags & self.contract.flags["OVERFLOW_OCCURRED"]:
            reasons.append("OVERFLOW_OCCURRED flag is set")
        if flags & self.contract.flags["MALFORMED_PRECEDING"]:
            reasons.append("MALFORMED_PRECEDING flag is set")

        self.last_global = record.global_stream_sequence
        self.last_attempt[channel] = record.channel_attempt_sequence
        self.last_source[channel] = (
            record.source_frame_sequence,
            record.source_line_sequence,
            record.source_capture_sequence,
            record.physical_input_id,
        )
        if reasons:
            classifications.append(DISCONTINUITY)
        return RecordAssessment(
            index=index,
            classifications=tuple(classifications),
            record=record,
            discontinuity_reasons=tuple(reasons),
            session_fatal=session_fatal,
        )


@dataclass(frozen=True)
class CompletedFrame:
    key: tuple[str, int, int, int, int]
    raw_uyvy: bytes = field(repr=False)
    line_sequences: tuple[int, ...]


@dataclass
class _FrameInProgress:
    key: tuple[str, int, int, int, int]
    next_line: int
    data: bytearray
    lines: list[int]


class FrameAssembler:
    """Reconstruct complete 1080-line raw UYVY frames from valid records."""

    def __init__(self, contract: AbiContract, *, card_identity: str) -> None:
        self.contract = contract
        self.card_identity = card_identity
        self._active: dict[int, _FrameInProgress] = {}
        self.discarded_frames = 0
        self.ignored_records = 0

    def _discard_all(self) -> None:
        self.discarded_frames += len(self._active)
        self._active.clear()

    def _discard_channel(self, channel: int) -> None:
        if channel in self._active:
            self.discarded_frames += 1
            del self._active[channel]

    def push(self, assessment: RecordAssessment) -> CompletedFrame | None:
        if not assessment.structurally_valid or assessment.session_fatal:
            self.ignored_records += 1
            return None
        record = assessment.record
        assert record is not None
        channel = record.logical_channel_id

        if NEW_EPOCH in assessment.classifications:
            self._discard_all()
        if DISCONTINUITY in assessment.classifications:
            self._discard_channel(channel)

        line = record.source_line_sequence
        key = (
            self.card_identity,
            channel,
            record.physical_input_id,
            record.reset_epoch,
            record.source_frame_sequence,
        )
        if line == 0:
            self._discard_channel(channel)
            self._active[channel] = _FrameInProgress(
                key=key,
                next_line=0,
                data=bytearray(
                    self.contract.payload_bytes * self.contract.lines_per_frame
                ),
                lines=[],
            )
        active = self._active.get(channel)
        if active is None:
            self.ignored_records += 1
            return None
        if active.key != key or line != active.next_line:
            self._discard_channel(channel)
            self.ignored_records += 1
            return None

        start = line * self.contract.payload_bytes
        active.data[start:start + self.contract.payload_bytes] = record.payload
        active.lines.append(line)
        active.next_line += 1
        if line != self.contract.lines_per_frame - 1:
            return None

        required_lines = tuple(range(self.contract.lines_per_frame))
        if tuple(active.lines) != required_lines:
            self._discard_channel(channel)
            self.ignored_records += 1
            return None
        completed = CompletedFrame(
            key=active.key,
            raw_uyvy=bytes(active.data),
            line_sequences=tuple(active.lines),
        )
        del self._active[channel]
        return completed


def iter_fixed_records(data: bytes, record_bytes: int) -> Iterable[bytes]:
    if len(data) == 0 or len(data) % record_bytes:
        raise RecordValidationError((
            f"stream byte count {len(data)} is not a positive multiple of "
            f"{record_bytes}",
        ))
    for offset in range(0, len(data), record_bytes):
        yield data[offset:offset + record_bytes]
