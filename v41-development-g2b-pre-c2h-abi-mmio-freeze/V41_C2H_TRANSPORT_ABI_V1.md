# AHD v41 C2H Transport ABI V1

## Status and identifiers

`CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B`

This document is the normative wire contract for the AHD v41 card-to-host video-record stream. Normative words such as **must**, **must not**, and **only** are implementation requirements.

| Item | Frozen value |
|---|---|
| ABI name | `AHD_C2H_TRANSPORT_ABI_V1` |
| ABI numeric version | `1` |
| MMIO ABI version word | `0x00010000` (`major=1`, `minor=0`) |
| Record family | `v41D` |
| Record version | `0x00004101` |
| Header scalar encoding | 16 little-endian unsigned 32-bit words |
| Record bytes | 4,096 |
| Header bytes | 64 |
| Useful payload bytes | 3,840 |
| Padding bytes | 192 |

The MMIO ABI version and the record version have different roles. MMIO negotiates compatibility. The record version selects the fixed record parser. A host must validate both.

## Record geometry

| Region | Inclusive byte range | Size | Contract |
|---|---:|---:|---|
| Header | `0..63` | 64 | Sixteen defined little-endian `u32` words |
| Payload | `64..3903` | 3,840 | One complete 1,920-pixel active UYVY line |
| Padding | `3904..4095` | 192 | Formatter-generated `0x00` bytes |

There are no bytes before, between, or after these regions in a record. Payload offset is exactly 64, the last payload byte is 3903, padding begins at 3904, and the last record byte is 4095.

## Header layout

Every field occupies one complete little-endian 32-bit word. Upper bits described as reserved must be written as zero. No unnamed gap exists.

| Offset | Size | Field | Type | Endianness | Reset/default value | Producer | Consumer | Semantics | Status |
|---:|---:|---|---|---|---|---|---|---|---|
| `0x00` | 4 | `magic` | `u32` | little | `0x4C444841` | C2H formatter | Host parser | Constant v41 record magic. On-wire bytes are `41 48 44 4C`. | FROZEN |
| `0x04` | 4 | `record_version` | `u32` | little | `0x00004101` | C2H formatter | Host parser | Selects the `v41D` fixed-layout parser. | FROZEN |
| `0x08` | 4 | `reset_epoch` | `u32` | little | FPGA configuration creates epoch `0` | Shared C2H reset/epoch manager, latched by formatter | Host parser | Per-card, shared-stream reset generation. It is not a build ID. | FROZEN |
| `0x0C` | 4 | `source_frame_sequence` | `u32` | little | Internal source state resets to `0`; first emitted frame is `1` | Source line formatter | Frame assembler | Source-frame number, modulo `2^32`. Transport reset does not reset it. | FROZEN |
| `0x10` | 4 | `source_line_sequence` | `u32` | little | First active line of a source frame is `0` | Source line formatter | Frame assembler | Zero-based active-line number; legal values are `0..1079`. | FROZEN |
| `0x14` | 4 | `source_capture_sequence` | `u32` | little | Internal source state resets to `0`; first emitted capture is `1` | Source line formatter | Host parser | Counts successfully completed valid source line records modulo `2^32`. It does not count ring-full or malformed attempts. Transport reset does not reset it. | FROZEN |
| `0x18` | 4 | `payload_length` | `u32` | little | `3840` | C2H formatter | Host parser | Useful bytes beginning at byte 64. V1 requires exactly `3840`. | FROZEN |
| `0x1C` | 4 | `flags` | `u32` bitset | little | Per-record composition; emitted valid records have bit 5 set | Source/transport context formatter | Host parser | Exact bit contract is defined below. | FROZEN |
| `0x20` | 4 | `active_logical_channel_count` | `u32` | little | `1` in G2B | Applied-channel control snapshot | Host parser | Count at record admission; legal emitted values are `1` and `2`. G2B emits `1`. | FROZEN |
| `0x24` | 4 | `source_slot_generation_and_slot` | packed `u32` | little | Per-slot generation state resets to `0`; first allocation uses generation `1` | Source record ring | Diagnostics/host parser | Bits `31:8` generation modulo `2^24`; bits `7:4` `RESERVED_ZERO`; bits `3:0` slot number. G2B slot numbers are `0..3`. | FROZEN |
| `0x28` | 4 | `source_malformed_count_snapshot` | `u32` | little | `0` after source formatter/configuration reset | Source formatter counter bank | Host diagnostics/parser | Wrapping snapshot including all malformed attempts preceding this committed record. Transport reset does not clear the source counter. | FROZEN |
| `0x2C` | 4 | `source_dropped_count_snapshot` | `u32` | little | `0` after source formatter/configuration reset | Source admission counter bank | Host diagnostics/parser | Wrapping snapshot including all noncommitted eligible attempts preceding this committed record. | FROZEN |
| `0x30` | 4 | `logical_channel_id` | semantic `u2` in `u32` | little | `0` in G2B | Applied mapping snapshot | Demultiplexer/parser | Bits `1:0`: legal `0,1`; `2` reserved; `3` invalid sentinel. Bits `31:2` are zero. | FROZEN |
| `0x34` | 4 | `physical_input_id` | semantic `u3` in `u32` | little | `0` in G2B | Applied mapping snapshot | Parser/frame assembler | Bits `2:0`: legal `0..3`; `4..6` reserved; `7` invalid sentinel. Bits `31:3` are zero. | FROZEN |
| `0x38` | 4 | `channel_attempt_sequence` | `u32` | little | Next value `0` at each transport epoch | Channel admission controller | Per-channel continuity checker | Sequence of eligible active-line attempts, including attempts that are later dropped, malformed, or aborted. | FROZEN |
| `0x3C` | 4 | `global_stream_sequence` | `u32` | little | Next value `0` at each transport epoch | Shared scheduler/C2H formatter | Global-order checker | Sequence of complete records in the single C2H stream. | FROZEN |

The G1-proposed firmware/build field at `0x08` is intentionally replaced by `reset_epoch`. Full source/build identity already has an authoritative MMIO representation and is not duplicated in every record.

The header counters at `0x28` and `0x2C` are source-local lifetime counters,
not aliases of the clearable G2B MMIO statistics. They reset only with FPGA
configuration or one of the explicitly defined source-sequence reset events.
`RESET_C2H_STATS`, ordinary transport enable/disable, and a transport-epoch
reset alone do not clear them. MMIO `RECORDS_DROPPED` and related counters are
separate logical counters even where an event increments both banks.

## Flags

Flags are per-record annotations. Pending producer context can be sticky until copied into a committed record, but the header bits themselves are not MMIO sticky state.

| Bit | Name | Meaning | Producer and assignment | Clear rule | Status |
|---:|---|---|---|---|---|
| 0 | `SOF` | This record is source line 0 and begins a source frame. It must be 1 if and only if `source_line_sequence==0`. | Source formatter | Recomputed for each record | FROZEN |
| 1 | `RESERVED_ZERO` | No V1.0 meaning. | Formatter writes 0 | Always 0 | FROZEN |
| 2 | `DISCONTINUITY` | Continuity from the prior emitted record on this logical channel cannot be assumed within the same epoch. Causes include one or more uncommitted attempts, source reset/loss/reconfiguration, or another source-boundary break. | Channel discontinuity-pending state, copied to the next committed record | Pending state clears when the annotated record commits | FROZEN |
| 3 | `OVERFLOW_OCCURRED` | At least one ring-full whole-record drop occurred since the previous committed record on this logical channel. | Channel overflow-pending state | Pending state clears when the annotated record commits | FROZEN |
| 4 | `MALFORMED_PRECEDING` | At least one source attempt failed marker/length/source validation since the previous committed record. | Source malformed-pending state | Pending state clears when the annotated record commits | FROZEN |
| 5 | `VALID` | Header and payload were produced from a completely validated active line. Every streamed G2B record must have this bit set. | Source formatter after successful line validation | Recomputed; records with 0 must not be streamed | FROZEN |
| 6 | `WINDOW_END` | Final record of a bounded legacy capture window. Continuous G2B DMA always writes 0. | Source formatter | Recomputed; constant 0 in continuous G2B | FROZEN |
| 7..31 | `RESERVED_ZERO` | No V1.0 meaning. | Formatter writes 0 | Always 0 | FROZEN |

V1.0 deliberately defines no `SOURCE_UNLOCKED`, `SOURCE_RECOVERED`, `RESET_BOUNDARY`, or `DROPPED_BEFORE_THIS_RECORD` bit. Source breaks use `DISCONTINUITY` and source/MMIO state. Reset boundaries use `reset_epoch`. Ring-full loss uses the attempt gap, `DISCONTINUITY`, `OVERFLOW_OCCURRED`, and counters.

FPGA configuration and every transport-epoch reset clear all pending
`DISCONTINUITY`, `OVERFLOW_OCCURRED`, and `MALFORMED_PRECEDING` producer state
after the reset's drop/abandon/error accounting is applied. Old-epoch pending
context must not annotate the first record of the new epoch; `reset_epoch`
itself is the boundary indication. A source reset/loss that does not create a
transport epoch retains or sets its defined pending context until the next
commit.

## Channel identity

The ABI is not one-channel-only. It supports logical channels 0 and 1 and four selectable physical inputs even though G2B implements only logical channel 0 mapped to physical input 0.

- `logical_channel_id` has a two-bit semantic namespace: 0 and 1 are legal, 2 is reserved, and 3 is the invalid sentinel.
- `physical_input_id` has a three-bit semantic namespace: 0 through 3 are legal, 4 through 6 are reserved, and 7 is the invalid sentinel.
- All container bits above the semantic width must be zero.
- `active_logical_channel_count` is 1 or 2 in every emitted record.
- G2B emits `logical_channel_id=0`, `physical_input_id=0`, and `active_logical_channel_count=1`.
- A later two-channel implementation can emit both logical IDs with count 2 without changing the ABI.
- Card identity is not encoded in the record. The host associates records with the opened XDMA device/BDF and its authoritative MMIO identity tuple.

## Payload contract

Each record contains exactly one validated 1,920-pixel active source line in packed UYVY 4:2:2 form. It contains no SAV/EAV marker, horizontal or vertical blanking byte, line padding, checksum, timestamp, or descriptor data.

For pixel pair `p` containing pixels `2p` and `2p+1`, where `p=0..959`, payload bytes are:

| Payload-relative byte | Meaning |
|---:|---|
| `4p+0` | `U0` / `Cb` shared by the pair |
| `4p+1` | `Y0` for pixel `2p` |
| `4p+2` | `V0` / `Cr` shared by the pair |
| `4p+3` | `Y1` for pixel `2p+1` |

Source active lines are numbered 0 through 1079. Line 0 carries `SOF=1`; every other line carries `SOF=0`. There is no EOF flag. A host reconstructs a complete frame by grouping records by card, logical channel, physical input, reset epoch, and `source_frame_sequence`, then requiring exactly one instance of every line `0..1079` in order. Receipt of line 1079 completes the frame only if all preceding lines are present and valid. A gap, duplicate, identity change, source-sequence break, or discontinuity makes the affected frame incomplete.

Records from two logical channels may be interleaved. They are never interleaved at beat granularity.

### Source sequence lifecycle

Source frame, line, and capture sequences are independent of transport sequences:

- FPGA configuration, an explicit source reset, source disable/re-enable, an
  applied physical-input remap, or an explicit source formatter/configuration
  reset initializes source frame and capture internal state to 0.
- The first valid emitted source record has frame sequence 1, line sequence 0, and capture sequence 1.
- Each new source frame increments frame sequence modulo `2^32` and restarts line sequence at 0.
- Each successfully completed valid source line record increments capture sequence modulo `2^32`.
- Ring-full, malformed, and aborted attempts consume `channel_attempt_sequence` but do not consume `source_capture_sequence`.
- PCIe, AXI, formatter-transport, or host stream reset does not reset source frame/line/capture state.
- Source loss without a source reset does not reset these source sequences.
- Every listed source-sequence reset event resets the source sequences, aborts
  any affected uncommitted record, and sets discontinuity pending for the next
  committed record, but it does not change the transport epoch or either
  transport sequence. NVP/I2C reset or initialization alone is not a source
  formatter reset and does not reset these sequences.

If a source reset event aborts an already assigned `FILLING` attempt, that
attempt still increments the MMIO transport dropped accounting and consumes
its transport attempt number. Reset of the source-local sequence/header-counter
bank is applied after that old-source-lifetime disposition, so the aborted
old-lifetime attempt is not carried into the new `0x2C` source drop snapshot;
the new source-local counters begin at zero. A coincident transport-epoch reset
also clears old-epoch pending flags after accounting, while the source-local
bank still restarts.

## Padding contract

Bytes `3904..4095` are part of every fixed 4,096-byte record and must all be zero. The C2H formatter must generate these bytes as constants; it must not expose unwritten or stale RAM content. `TKEEP` remains `0xFF` for their beats. A consumer verifies zero when validating the record and otherwise ignores the padding.

## AXI4-Stream mapping and backpressure

- Interface width is 64 bits, eight bytes per beat.
- Record beat indices are `0..511`.
- Record byte `8*n+k` maps to `TDATA[8*k +: 8]` on beat `n`, for `k=0..7`.
- `TKEEP` is `8'hFF` on every offered beat.
- `TLAST` is 0 on beats `0..510` and 1 only on beat 511.
- The first beat must not be offered until a complete committed record and matching descriptor are owned in the XDMA clock domain.
- After the first beat is offered, `TVALID` remains asserted through the final-beat handshake; no intentional intra-record bubble is allowed.
- While `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain stable.
- Beat index advances only on `TVALID && TREADY`.
- Channel, slot, slot generation, epoch, header metadata, and global sequence remain locked for the complete record.
- Slot release begins only after the beat-511 `TVALID && TREADY` handshake.
- Reset may abandon an in-flight record internally, but it must never publish a suffix as a new record. The next transfer begins at beat 0 of a complete record in the new epoch.

## Transport sequences

All arithmetic below is modulo `2^32`; `0xFFFFFFFF -> 0` is normal wrap and not a discontinuity.

### Per-channel attempt sequence (`0x38`)

Each logical channel owns a `channel_attempt_next` register.

1. FPGA configuration and every new transport epoch set `channel_attempt_next=0` for both logical channels.
2. When an enabled channel reaches the decision point for an eligible active-line attempt, before final length/marker validation can later accept or reject it, the attempt is assigned the current value.
3. The controller then increments `channel_attempt_next` exactly once, regardless of whether the attempt obtains a slot, later commits, is rejected because the ring is full, or is later abandoned as malformed or aborted.
4. Lines observed while the channel is disabled are not attempts and consume no number.
5. A streamed record carries the number assigned to its own attempt. Failed attempts therefore appear as gaps between streamed records.
6. Ordinary disable/enable, source loss/reset, and physical-input remapping do not reset this sequence. When they break source continuity, the next record carries `DISCONTINUITY`.

### Global stream sequence (`0x3C`)

The shared stream owns a `global_stream_next` register.

1. FPGA configuration and every new transport epoch set `global_stream_next=0`.
2. When the scheduler changes a slot from `COMMITTED` to `DMA_OWNED`, before offering beat 0, it assigns the current value to the output record and locks it.
3. `global_stream_next` increments exactly once only when beat 511 handshakes.
4. A reset-abandoned record does not consume a value in the new epoch.
5. Whole-record source/ring drops do not consume a global value.
6. Consequently, all complete records received in one epoch have a contiguous global sequence across both logical channels.

At most one slot across the shared stream may be `DMA_OWNED`. The scheduler
does not assign the next global sequence or perform the next
`COMMITTED -> DMA_OWNED` transition until the prior record's beat-511
handshake increments `global_stream_next`. Descriptor look-ahead may not
change ownership or allocate a sequence.

The attempt sequence describes source/admission order within a logical channel. The global sequence describes successful C2H completion order across the shared stream. Neither substitutes for the source frame/line/capture sequences.

## Reset epoch and reset behavior

`reset_epoch` is a per-card value shared by the single C2H stream and all logical channels. It is not per-channel.

- FPGA configuration initializes epoch 0.
- Each later PCIe/PERST or `axi_aresetn` reset episode increments the epoch exactly once, on synchronized reset release.
- A host `RESET_STREAM_STATE` command increments it exactly once.
- A standalone C2H formatter/transport reset increments it exactly once.
- Simultaneous or overlapping causes before a completed reset release coalesce into one epoch increment.
- Epoch increment wraps modulo `2^32`; software detects a new epoch by inequality, not by greater-than comparison.
- Ordinary stream enable/disable, statistics reset, source loss, source reset, source formatter/configuration reset, and NVP/I2C activity do not increment the transport epoch.

Each epoch-creating transport reset must:

1. disable admission and require explicit host re-enable;
2. reset both channel attempt-next registers and global stream-next to 0;
3. invalidate and flush every `FILLING`, `COMMITTED`, `DMA_OWNED`, and `RELEASABLE` slot/descriptor;
4. abandon any in-progress source or C2H record without exposing partial data;
5. hold admission disabled until all active clock domains acknowledge the new epoch; and
6. resume only with beat 0 of a newly committed complete record.

If the source continues during transport reset, source sequences continue. Records produced while admission is disabled are not admitted. The epoch transition and post-reset source metadata let the host discard any incomplete frame.

NVP/I2C initialization, reset, and telemetry are independent. A transport reset must not reset, start, gate, or replay NVP initialization. A source reset preserves transport epoch and transport sequences, aborts any affected uncommitted record, and sets pending discontinuity.

## Ring ownership model

G2B implements four slots for logical channel 0. Each future active logical channel owns its own four slots; slots are never borrowed across channels.

Each logical channel publishes committed descriptors into a depth-four FIFO
in commit order. The scheduler must select the oldest `COMMITTED` descriptor
for a chosen channel; it may never reorder records within a logical channel.
Which `WRITABLE` physical slot is allocated is an internal choice and does not
alter FIFO order. Across the shared stream there is at most one `DMA_OWNED`
slot at a time.

| State | Owner and permitted action |
|---|---|
| `WRITABLE` | Producer owns an empty slot and may allocate it for one attempt. No valid record is visible. |
| `FILLING` | Producer exclusively writes the selected slot and metadata. DMA must not read it. |
| `COMMITTED` | Complete validated payload/source metadata and a matching descriptor are immutable and visible to the scheduler. Producer must not write it. |
| `DMA_OWNED` | Scheduler/formatter exclusively owns the record from selection through beat 511. Before beat 0 it fixes the complete wire image, including global sequence and zero padding. |
| `RELEASABLE` | Final beat has handshaken and a release token is crossing back to the producer. Neither side may reuse the slot yet. |

The only normal transitions are:

1. `WRITABLE -> FILLING` at successful slot allocation. Slot generation increments modulo `2^24` and the attempt/channel/physical/epoch metadata is latched.
2. `FILLING -> COMMITTED` atomically after exactly 3,840 payload bytes and all source validation complete. This event increments committed-record accounting.
3. `FILLING -> WRITABLE` when the attempt becomes malformed or is aborted before commit. No descriptor is published; the failed attempt is counted once and discontinuity context is retained.
4. `COMMITTED -> DMA_OWNED` when the scheduler locks the matching channel, slot, generation, and epoch and assigns the global sequence before beat 0.
5. `DMA_OWNED -> RELEASABLE` only on the beat-511 handshake. This event increments streamed-record/global completion accounting.
6. `RELEASABLE -> WRITABLE` only after the producer receives and validates the matching release acknowledgement.

A transport reset invalidates all non-`WRITABLE` state and returns slots to `WRITABLE` only after the cross-domain epoch handshake completes. Any illegal transition or channel/slot/generation/epoch mismatch is a fatal ownership fault for the stream: new admission stops until stream-state reset. No partial overwrite is permitted.

FPGA configuration and every new transport epoch reset each slot-generation
counter to zero; the first later `WRITABLE -> FILLING` allocation uses one.
Source reset/loss without a transport-epoch change does not reset slot
generation. Generation wraps modulo `2^24`; the epoch match prevents a
pre-reset descriptor with the same wrapped generation from being accepted.

## Drop policy

Video input is not backpressured. At an eligible attempt boundary, if the channel has no `WRITABLE` slot:

1. the attempt receives and consumes its channel attempt sequence;
2. no byte is written and no C2H beat is offered;
3. already `COMMITTED`, `DMA_OWNED`, and `RELEASABLE` records remain unchanged;
4. attempted and dropped counters increment exactly once;
5. the ring-overflow counter increments exactly once;
6. `DISCONTINUITY` and `OVERFLOW_OCCURRED` become pending; and
7. the next successfully committed record on that channel carries those flags and snapshots that include the drop.

An admitted attempt that later becomes malformed or is aborted also consumes its attempt number and increments dropped accounting exactly once; malformed failure additionally increments malformed accounting and sets `MALFORMED_PRECEDING`. Drops never consume a global stream sequence. Partial-record drop, overwrite-oldest, silent repair, and cross-channel slot borrowing are forbidden.

## Firmware/build identity

There is no per-record firmware or build ID. The authoritative identity is the existing read-only MMIO tuple:

- `BLOCK_ID`;
- `PROTOCOL` and `BUILD_ID_SCHEMA`;
- `GIT_SHA_W0..GIT_SHA_W4` containing the full 40-hex source commit;
- `VIVADO_VERSION` and `VIVADO_SW_BUILD`; and
- `BUILD_FLAGS`.

The host snapshots this tuple before enabling C2H and after disabling/draining it. If any identity element or ABI capability changes while a stream is active, the host must stop, discard buffered/unassembled data, close and reopen the session, and renegotiate MMIO before accepting more records. Records from different identities must never be combined into one capture.

The legacy MMIO `PROTOCOL` word remains part of the immutable legacy identity
and is not reinterpreted as the C2H record version. C2H negotiation uses the new
MMIO ABI page plus header `record_version`.

## Host session-start rule

Every newly opened capture session, including recovery after process restart,
must negotiate MMIO while C2H is disabled, issue `RESET_STREAM_STATE`, wait
for reset completion and an empty/inactive ring, record the resulting
`RESET_EPOCH`, clear any fatal sticky errors only through the MMIO-defined
post-reset W1C sequence, and then explicitly enable C2H. The first record of
that session therefore belongs to the armed epoch and has
`global_stream_sequence=0`. Opening a reader and accepting records from the
middle of an existing epoch is not a conforming V1 session start.

## Host record classifications

The four parser classifications are precise and can be combined as noted:

- `VALID_RECORD`: the record is exactly 4,096 bytes at the expected boundary; constants, version, lengths, IDs, field constraints, flags, line number, and zero padding validate; `VALID=1`; and the payload can be extracted. A valid record may additionally be marked `NEW_EPOCH` or `DISCONTINUITY`.
- `CORRUPT_RECORD`: any structural validation fails, including bad magic/version, wrong size/length, illegal identity value, nonzero V1.0 reserved bit, `VALID=0`, `SOF`/line-0 disagreement, line above 1079, or nonzero padding. The parser stops the session at that fixed boundary. It must not scan forward for magic or invent a new boundary.
- `NEW_EPOCH`: the first valid record after the mandatory session-start
  `RESET_STREAM_STATE`, or a valid record whose `reset_epoch` differs from the
  prior record. The host discards partial frames, clears per-channel continuity
  baselines, and requires the first global sequence observed in the epoch to
  be 0. A channel's first observed attempt value need not be 0 because earlier
  attempts may have been dropped.
- `DISCONTINUITY`: a structurally valid record indicates or reveals a continuity break: the flag is set, a same-epoch channel attempt value is not the previous value plus one modulo `2^32`, the same-epoch global value is not the previous value plus one, source frame/line/capture progression is broken, identity/mapping changes, or relevant MMIO counter deltas report loss. The host marks the affected frame incomplete. A explained ring drop remains a discontinuity; it does not make the following record corrupt.

## Forward compatibility

V1.0 rules are:

1. MMIO major mismatch is unsupported. The host must not enable streaming.
2. Record version mismatch is unsupported unless a later negotiated ABI explicitly lists that record version as backward-compatible.
3. With MMIO version `1.0`, every reserved bit and reserved subfield must be zero. A nonzero value is corruption.
4. A newer minor version under major 1 may retain `record_version=0x00004101` only when the complete 64-byte base layout, geometry, required fields, and their semantics remain backward-compatible.
5. When MMIO advertises such a newer minor, an older major-1 parser ignores unknown flag bits or newly defined values in V1.0-reserved subfields rather than interpreting them. It still enforces all known fields and fixed geometry.
6. An old parser must not ignore unknown flags or nonzero reserved values when MMIO advertises minor 0.
7. There are no reserved/unnamed header bytes in V1.0. Header expansion, field movement, changed payload offset, changed record size, or changed mandatory semantics requires a new major ABI and a new record version.
8. Padding is not an extension area and must remain zero for every major-1 record using this record version.

## Frozen implementation invariants

- Header is exactly 64 bytes with no overlap or gap.
- Payload begins at 64 and ends at 3903.
- Padding begins at 3904 and ends at 4095.
- `64 + 3840 + 192 = 4096`.
- `512 * 8 = 4096`.
- One record equals one active line and one AXI packet.
- No complete host packet has any length other than 4,096 bytes.
- No source or transport reset can expose a partial record as valid.
- Dropped attempts consume per-channel attempt values but never global stream values.
- Complete streamed records are globally contiguous within an epoch.
- No per-record build identity exists; MMIO identity is authoritative.
