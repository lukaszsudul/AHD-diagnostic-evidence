# AHD v41 G2B-PRE ABI/MMIO Consistency Report

## Result

`ABI_CONSISTENCY = PASS`

Automated checks passed: `63 / 63`

Failures: `0`

The validator is `validate_g2b_pre_contract.py` in this directory. It uses
only the Python standard library and reads the sealed ABI JSON, MMIO CSV, and
normative Markdown artifacts. It neither imports nor executes FPGA source.

Executed command:

```powershell
& 'C:\Users\Łukasz Suduł\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .\validate_g2b_pre_contract.py
```

Execution directory:

`C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-pre-c2h-abi-mmio-freeze`

## Geometry proof

| Check | Expected | Observed | Result |
|---|---:|---:|---|
| Header bytes | 64 | 64 | PASS |
| Payload start | 64 | 64 | PASS |
| Payload end | 3903 | 3903 | PASS |
| Payload bytes | 3840 | 3840 | PASS |
| Padding start | 3904 | 3904 | PASS |
| Record end | 4095 | 4095 | PASS |
| Padding bytes | 192 | 192 | PASS |
| Total | `64 + 3840 + 192` | 4096 | PASS |
| AXIS total | `512 x 8` | 4096 | PASS |
| AXIS width | 64 bits | 64 bits | PASS |
| `TKEEP` | `0xFF` every beat | `0xFF` every beat | PASS |
| `TLAST` | only beat 511 | only beat 511 | PASS |

The three byte regions are adjacent and exhaustive:

```text
header  [   0,   63]  64 bytes
payload [  64, 3903] 3840 bytes
padding [3904, 4095]  192 bytes
```

## Header coverage proof

The machine-readable header has exactly 16 fields. Every field is four bytes,
every offset is four-byte aligned, and the fields cover bytes `0..63` exactly
once.

| Offset | Field | Byte range |
|---:|---|---:|
| `0x00` | `magic` | `0..3` |
| `0x04` | `record_version` | `4..7` |
| `0x08` | `reset_epoch` | `8..11` |
| `0x0C` | `source_frame_sequence` | `12..15` |
| `0x10` | `source_line_sequence` | `16..19` |
| `0x14` | `source_capture_sequence` | `20..23` |
| `0x18` | `payload_length` | `24..27` |
| `0x1C` | `flags` | `28..31` |
| `0x20` | `active_logical_channel_count` | `32..35` |
| `0x24` | `source_slot_generation_and_slot` | `36..39` |
| `0x28` | `source_malformed_count_snapshot` | `40..43` |
| `0x2C` | `source_dropped_count_snapshot` | `44..47` |
| `0x30` | `logical_channel_id` | `48..51` |
| `0x34` | `physical_input_id` | `52..55` |
| `0x38` | `channel_attempt_sequence` | `56..59` |
| `0x3C` | `global_stream_sequence` | `60..63` |

Results:

- header overlap: none;
- unnamed header gap: none;
- field outside header: none;
- non-frozen mandatory field: none; and
- unresolved mandatory field list in JSON: empty.

## Flags and identity proof

Flag entries cover bits `0..31` exactly once. Bits 0 and 2 through 6 have the
frozen evidence-supported meanings; bit 1 and bits 7 through 31 are explicitly
`RESERVED_ZERO`. No speculative source/reset/drop flag occupies a reserved bit.

Logical identity validates as semantic `u2`: legal `0,1`, reserved `2`,
invalid `3`. Physical identity validates as semantic `u3`: legal `0..3`,
reserved `4..6`, invalid `7`. The G2B emitted tuple is logical 0, physical 0,
active count 1, while the ABI remains compatible with future logical channel
1.

## Sequence, epoch, ownership, and parser proof

The validator confirmed the machine-readable contract contains all mandatory
rules:

- channel and global first values are 0 per epoch;
- both wrap modulo `2^32`;
- dropped/malformed/aborted attempts consume channel values;
- drops do not consume global values;
- global assignment precedes beat 0 and increment is the beat-511 handshake;
- formal 32-bit shared reset epoch has exact increment/non-increment events;
- the ring has four slots and the five exact ownership states;
- partial overwrite is forbidden;
- padding is formatter-generated zero with no uninitialized RAM allowance;
- build identity is MMIO-only; and
- parser classifications are exactly `VALID_RECORD`, `CORRUPT_RECORD`,
  `NEW_EPOCH`, and `DISCONTINUITY`, with no magic resynchronization scan.

## MMIO parsing and coverage

The CSV parsed with the exact requested columns:

```text
Address,Name,Width,Access,Reset,Bit_or_Field,Semantics,Clock_Domain,Clear_Rule,Status
```

It contains 67 populated data rows and no empty cell. Address/range expansion
covers all 256 aligned 32-bit words from `0x3800` through `0x3BFC`, equivalent
to the complete byte window `0x3800..0x3BFF`.

Results:

- address/range endpoint alignment: PASS;
- duplicate/overlapping bit definition in split registers: none;
- complete defined-or-reserved word coverage: PASS;
- out-of-range G2B word: none;
- overlap with immutable `0x0000..0x37FF`: none;
- capability/control/status/error/snapshot bit coverage: all bits `0..31`
  exactly once;
- computed capability reset value: `0x000B001F`;
- computed status reset value: `0x00000004`;
- required counter addresses: PASS; and
- six exact error bits at `0x383C`: PASS;
- statistics reset is excluded while snapshot capture is busy: PASS; and
- same-cycle sticky-error set wins over W1C for every defined error bit: PASS.

The range is statically safe at accepted source commit
`224d194e5f82c85bcb29297561c5d5e76d28063b`: existing local/R1i decoding owns
only the frozen lower ranges; the two-slot legacy target has no valid slot-3
read claimant at `0x3800`. A later router must claim the extension before
legacy forwarding so writes no longer reach legacy bad-address accounting.
Exhaustive simulation of that implementation remains a G2B implementation
obligation and was not run here.

## Placeholder and artifact checks

The normative ABI Markdown, ABI JSON, MMIO Markdown, MMIO CSV, and Linux
consumer contract contain no `TBD`, `TODO`, or intermediate
`MOSTLY_FROZEN` status. All required publication artifacts and the repeatable
validator were present.

## Complete validator receipt

```text
PASS ABI_JSON_PARSE
PASS GEOMETRY_VALUES
PASS GEOMETRY_SUM
PASS REGION_ENDPOINTS
PASS AXIS_GEOMETRY
PASS AXIS_FRAMING
PASS AXIS_STALL_STABILITY
PASS HEADER_FIELD_ORDER
PASS HEADER_NO_OVERLAP
PASS HEADER_EXACT_COVERAGE
PASS HEADER_FIELD_STATUS
PASS FLAG_NO_OVERLAP
PASS FLAG_EXACT_COVERAGE
PASS FLAG_ASSIGNMENTS
PASS FLAG_PENDING_EPOCH_RESET
PASS CHANNEL_NAMESPACE
PASS G2B_FIXED_MAPPING
PASS CHANNEL_SEQUENCE_RULE
PASS GLOBAL_SEQUENCE_RULE
PASS GLOBAL_SEQUENCE_SINGLE_OWNER
PASS SOURCE_SEQUENCE_RESET_RULE
PASS HEADER_SOURCE_COUNTER_LIFETIME
PASS RESET_EPOCH_RULE
PASS RESET_EPOCH_OWNER
PASS RING_STATES
PASS RING_FIFO_ORDER
PASS SLOT_GENERATION_RESET
PASS PADDING_ZERO
PASS BUILD_IDENTITY_MMIO_ONLY
PASS PARSER_CLASSES
PASS PARSER_SESSION_START
PASS MMIO_CSV_PARSE
PASS MMIO_CSV_COLUMNS
PASS MMIO_CSV_NO_EMPTY_CELLS
PASS MMIO_ADDRESS_ALIGNMENT
PASS MMIO_ADDRESS_RANGE
PASS MMIO_COMPLETE_WORD_COVERAGE
PASS MMIO_NO_LEGACY_OVERLAP
PASS CAPABILITIES_BIT_COVERAGE
PASS CONTROL_BIT_COVERAGE
PASS STATUS_BIT_COVERAGE
PASS ERROR_STATUS_BIT_COVERAGE
PASS SNAPSHOT_COMMAND_BIT_COVERAGE
PASS SNAPSHOT_STATUS_BIT_COVERAGE
PASS CAPABILITY_ASSIGNMENTS
PASS CAPABILITY_VALUE
PASS CONTROL_FIELDS
PASS STATS_RESET_SNAPSHOT_EXCLUSION
PASS ENABLE_APPLIED_ACK
PASS STATS_CLEAR_ACK
PASS SIMULTANEOUS_RESET_ORDER
PASS STATUS_RESET_VALUE
PASS REQUIRED_COUNTER_ADDRESSES
PASS SEQUENCE_COUNTER_PER_CHANNEL_BASELINE
PASS ERROR_MODEL_BITS
PASS ERROR_SET_WINS_CLEAR
PASS ERROR_CDC_HANDSHAKE
PASS LAST_ERROR_CAUSE_PRIORITY
PASS SNAPSHOT_RESET_INTERLOCK
PASS MMIO_EPOCH_OWNER
PASS STANDALONE_RESET_EQUIVALENCE
PASS NO_MANDATORY_PLACEHOLDERS
PASS REQUIRED_ARTIFACTS_PRESENT
CHECKS_TOTAL=63
CHECKS_PASSED=63
CHECKS_FAILED=0
RESULT=PASS
```

## Non-execution boundary

This validation was static. It did not invoke Vivado, elaborate or simulate
RTL, synthesize, implement, access a DUT, enumerate hardware, program an FPGA,
or run DMA.
