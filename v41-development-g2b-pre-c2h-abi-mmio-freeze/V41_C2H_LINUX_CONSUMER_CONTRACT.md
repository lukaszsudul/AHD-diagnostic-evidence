# AHD v41 C2H Linux Consumer Contract

## Scope

This is the transport-facing contract for a future Linux/userspace consumer of `AHD_C2H_TRANSPORT_ABI_V1`. It defines identification, negotiation, fixed-record parsing, continuity detection, and UYVY extraction. It does not design a V4L2 driver or authorize host DMA testing.

Normative transport details are in `V41_C2H_TRANSPORT_ABI_V1.md` and `V41_C2H_TRANSPORT_ABI_V1.json`. MMIO addresses and bit definitions are in `V41_G2B_MMIO_CONTRACT.md` and `V41_G2B_MMIO_MAP.csv`.

## Frozen identifiers

| Item | Required value |
|---|---|
| ABI name | `AHD_C2H_TRANSPORT_ABI_V1` |
| ABI numeric version | `1` |
| MMIO ABI version | `0x00010000` (`major=1`, `minor=0`) |
| Record family | `v41D` |
| Record version | `0x00004101` |
| Record magic | `0x4C444841` |
| Record bytes | 4,096 |
| Payload bytes | 3,840 |
| Payload format | Packed UYVY 4:2:2, one 1,920-pixel active line per record |

## How Linux identifies the card and stream

A record intentionally contains no card serial, PCI BDF, or build ID. The consumer identifies the card by the opened XDMA device instance and PCI BDF, then binds that device to its read-only MMIO identity.

Before enabling C2H, the consumer must read and retain:

- legacy `BLOCK_ID`;
- legacy `PROTOCOL` and `BUILD_ID_SCHEMA`;
- `GIT_SHA_W0..GIT_SHA_W4`, reconstructing the full 40-hex source commit;
- `VIVADO_VERSION`, `VIVADO_SW_BUILD`, and `BUILD_FLAGS`;
- C2H MMIO magic and ABI major/minor;
- `RECORD_ABI_V1_SUPPORTED`, `C2H_IMPLEMENTED_THIS_BUILD`, and the applicable
  per-channel `*_IMPLEMENTED_THIS_BUILD` capability bits;
- the G2B implemented channel count implied by
  `ONE_CHANNEL_IMPLEMENTED_THIS_BUILD=1` and
  `TWO_CHANNEL_IMPLEMENTED_THIS_BUILD=0`;
- the fixed G2B mapping from this contract (logical channel 0 to physical
  input 0) and the record geometry selected by ABI version 1;
- current shared `reset_epoch`; and
- initial coherent counter/status snapshot.

The complete legacy identity tuple is the authoritative firmware/build identity. Offset `0x08` in a record is `reset_epoch`, not a truncated build identifier.

Legacy `PROTOCOL` remains an identity component for the protected legacy path;
Linux must not treat it as the C2H record version. The new C2H MMIO ABI page
and header `record_version` negotiate this transport.

The consumer must not enable C2H if the MMIO major is not 1,
`RECORD_ABI_V1_SUPPORTED` is zero, `C2H_IMPLEMENTED_THIS_BUILD` is zero, or the
requested logical channel's implementation bit is zero. Support and
implementation are separate facts; `TWO_CHANNEL_ABI_CAPABLE`, for example,
does not mean that channel 1 is implemented in the running build.

If any retained identity or ABI-capability value changes while streaming, the consumer must:

1. stop accepting records;
2. discard all buffered records and incomplete frames;
3. disable/drain or close the transport as available;
4. reopen/reprobe the device and MMIO contract; and
5. start a new capture session only after successful renegotiation.

Records from two firmware identities must never be combined into one capture.

## How Linux identifies channel and input

Each record carries both identities as little-endian `u32` containers:

- `logical_channel_id` at `0x30`: semantic width two bits; 0 and 1 are legal, 2 is reserved, 3 is invalid, and bits `31:2` must be zero.
- `physical_input_id` at `0x34`: semantic width three bits; 0 through 3 are legal, 4 through 6 are reserved, 7 is invalid, and bits `31:3` must be zero.
- `active_logical_channel_count` at `0x20`: legal emitted values are 1 and 2.

G2B emits logical channel 0, physical input 0, and active count 1. The parser must nevertheless accept the legal two-channel namespace so that a later channel-1 implementation does not require a record-ABI change.

G2B has no dynamic-selection or applied-mapping register: `0x3900..0x397F`
and `0x3A00..0x3A7F` are reserved zero. The consumer must therefore
cross-check every G2B record against the frozen mapping
`logical_channel_id=0`, `physical_input_id=0`, and
`active_logical_channel_count=1`. A legal namespace value that differs from
that G2B build contract is a configuration/identity discontinuity and stops
the session; an illegal or reserved field value is record corruption. A later
two-channel or dynamic-selection build must advertise its implemented bits and
define its applied mapping in a versioned MMIO extension before Linux uses it.

One reader drains the single C2H channel-0 stream. Future two-channel records are demultiplexed by `logical_channel_id`; they are not delivered by separate XDMA engines. `global_stream_sequence` preserves total record order across that demultiplexing.

## Required capture-session start

Opening a file descriptor in the middle of an existing transport epoch is not
a conforming V1 capture-session start. After identity/capability negotiation
and before accepting any record, Linux/userspace must:

1. ensure no local reader is accepting C2H data;
2. issue `RESET_STREAM_STATE` (it clears `ENABLE_C2H` itself);
3. wait for `STREAM_RESET_BUSY=0`, `C2H_ACTIVE=0`, and `RING_EMPTY=1`;
4. if fatal error bits remain, clear them only with their legal post-reset W1C
   sequence and verify `FATAL_ERROR=0`;
5. record the resulting live `RESET_EPOCH` and obtain a fresh coherent counter
   snapshot;
6. explicitly set `ENABLE_C2H=1`; and
7. require the first received record to carry that armed epoch and
   `global_stream_sequence=0`.

This rule applies to first open, process restart, corruption recovery, and
identity-change recovery. It is what makes the first session record a real
`NEW_EPOCH` rather than an arbitrary mid-epoch baseline.

## Receive-buffer and boundary rules

- Open only the product C2H channel-0 node associated with the selected card, conventionally `/dev/xdma*_c2h_0`.
- Request buffers whose sizes and starting alignment are multiples of 4,096 bytes.
- Treat the C2H result as a byte stream divided only at offsets `4096*n` from the beginning of the negotiated session.
- A consumer may accumulate an operating-system short read into the current fixed record, but a terminal or timed-out partial record is a transport failure.
- Gate tooling must report a completed DMA/read byte count that is not a multiple of 4,096 as failure.
- Do not scan forward for magic, skip bytes, or invent a replacement boundary after corruption.
- A bad record stops the parsing session at its known boundary. Recovery requires a deliberate stream restart and fresh MMIO negotiation.

## Required parser procedure

For each 4,096-byte record at the expected boundary, the consumer must perform these steps in order.

### 1. Decode the header

Read exactly sixteen little-endian `u32` words from bytes 0 through 63. Do not use native unaligned structure casts. Decode by explicit little-endian loads or an equivalent packed-copy procedure.

### 2. Validate fixed structure

Require:

- `magic == 0x4C444841`;
- `record_version == 0x00004101` under the negotiated compatibility rule;
- `payload_length == 3840`;
- legal active-channel count, logical channel, and physical input;
- zero upper/reserved bits for V1.0;
- `VALID` flag set;
- `SOF == 1` if and only if `source_line_sequence == 0`;
- source line in `0..1079`;
- slot field in `0..3` for G2B and source-slot reserved bits zero;
- all 192 padding bytes zero; and
- the record remains exactly 4,096 bytes.

Failure of any item produces `CORRUPT_RECORD` and stops fixed-boundary parsing. Header sequence gaps alone do not make the following structurally sound record corrupt; they produce `DISCONTINUITY`.

### 3. Process epoch

`reset_epoch` at `0x08` is a per-card value shared by the C2H stream and both logical channels.

- The first valid record after the mandatory session-start stream reset is classified `NEW_EPOCH` and must match the armed MMIO epoch.
- Any later record whose epoch differs from the previous valid record is `NEW_EPOCH`, including `0xFFFFFFFF -> 0` wrap.
- Compare epochs for inequality; never require numerical increase.
- On `NEW_EPOCH`, discard every incomplete frame and reset global/per-channel continuity baselines.
- The first complete record observed in an epoch must have `global_stream_sequence==0`.
- The first observed record for a logical channel may have a nonzero attempt value because attempts may have been dropped before that channel first reached C2H.
- Cross-check the record epoch with current MMIO status when taking a coherent status snapshot.

PCIe/PERST or AXI reset release, `RESET_STREAM_STATE`, and standalone C2H formatter/transport reset create epochs. Source reset/loss and ordinary enable/disable do not. NVP/I2C reset and initialization are independent of the transport epoch.

### 4. Check global stream sequence

Within one epoch, complete records from all logical channels must have:

```text
current_global == (previous_global + 1) modulo 2^32
```

The first complete record is 0. `0xFFFFFFFF -> 0` is normal wrap. A same-epoch mismatch means the host did not receive the complete globally ordered stream and produces `DISCONTINUITY`. It is not explained by FPGA whole-record source drops because those drops never consume global sequence values.

### 5. Check per-channel attempt sequence

Maintain independent state for logical channels 0 and 1. Within an epoch, successive streamed records for one logical channel normally satisfy:

```text
current_attempt == (previous_attempt + 1) modulo 2^32
```

A ring-full, later-malformed, or later-aborted eligible attempt consumes a value even though no record is streamed. A gap is therefore a device/source discontinuity and must be reconciled with:

- `DISCONTINUITY`;
- `OVERFLOW_OCCURRED` for ring-full loss;
- `MALFORMED_PRECEDING` for source-validation failure;
- header drop/malformed snapshots; and
- coherent MMIO counter deltas.

Lines seen while a channel is disabled consume no attempt number. Drops never consume a global stream sequence.

### 6. Check source sequence and frame structure

Source sequences are independent of transport reset:

- after FPGA configuration, explicit source reset, source disable/re-enable,
  applied physical-input remap, or explicit source formatter/configuration
  reset, the first emitted source record is frame 1, line 0, capture 1;
- frame sequence increments modulo `2^32` at each source-frame boundary;
- line sequence runs from 0 through 1079;
- source capture sequence increments for each successfully completed valid source line record; and
- PCIe/AXI/host transport reset does not reset these source fields;
- source loss without source reset does not reset them; and
- NVP/I2C reset or initialization alone is not a source formatter reset and
  does not reset them.

Every listed source reset event restarts source sequences without changing
transport epoch or transport attempt/global sequences. The next emitted record
must carry `DISCONTINUITY`; the consumer discards the partial frame and waits
for a coherent line-0/SOF boundary. Header source counters at `0x28`/`0x2C`
share this source-reset lifetime and are not cleared by `RESET_C2H_STATS`.

### 7. Extract payload and validate padding

Payload is the 3,840-byte slice:

```text
record[64..3903]
```

For pixel pair `p=0..959`, bytes are:

```text
payload[4*p+0] = U0 / Cb
payload[4*p+1] = Y0 for pixel 2*p
payload[4*p+2] = V0 / Cr
payload[4*p+3] = Y1 for pixel 2*p+1
```

There are no SAV/EAV markers, blanking bytes, per-line padding, timestamp, or checksum in the payload.

Bytes `3904..4095` are formatter-generated zeros. They are transported with `TKEEP=0xFF` as part of the fixed record. The consumer verifies they are zero for structural validation, then ignores them. Padding must never be exposed as pixels or passed to a frame consumer.

## Record classifications

Classifications have the following exact meanings. `NEW_EPOCH` and `DISCONTINUITY` are annotations on a structurally valid record; they are not alternatives to `VALID_RECORD`.

### `VALID_RECORD`

The record:

- begins at the expected fixed boundary;
- is exactly 4,096 bytes;
- passes all header/identity/reserved/padding validation;
- has `VALID=1`; and
- exposes exactly 3,840 extractable UYVY bytes.

A `VALID_RECORD` may also be `NEW_EPOCH`, `DISCONTINUITY`, or both.

### `CORRUPT_RECORD`

At least one structural rule fails: size/boundary, magic, version, payload length, identity namespace, reserved-zero rule, `VALID`, SOF/line agreement, line range, slot constraints, or zero padding. The current session stops. No resynchronization scan is permitted.

### `NEW_EPOCH`

This is the first valid record after the mandatory session-start stream reset
or its epoch differs from the previous record. The consumer clears sequence
baselines, discards partial frames, and starts a new transport session
segment. Epoch wrap is still a new epoch. A mid-epoch attach is forbidden.

### `DISCONTINUITY`

The record is structurally usable but one or more continuity rules fail or explicitly report a break:

- `DISCONTINUITY` flag set;
- per-channel attempt gap;
- global stream gap;
- source frame/line/capture progression break;
- mapping/identity inconsistency; or
- MMIO counters report loss/error.

The affected frame is incomplete. An explained whole-record drop does not make the next structurally valid record corrupt.

## Flags consumed by Linux

| Bit | Name | Linux action |
|---:|---|---|
| 0 | `SOF` | Require exactly on line 0; begin/restart frame assembly. |
| 1 | `RESERVED_ZERO` | Require zero for MMIO ABI 1.0. |
| 2 | `DISCONTINUITY` | Mark current/preceding frame continuity broken; reconcile counters and attempt gap. |
| 3 | `OVERFLOW_OCCURRED` | Record a ring-full loss event and reconcile drop/overflow counters. |
| 4 | `MALFORMED_PRECEDING` | Record source-validation loss and reconcile malformed/drop counters. |
| 5 | `VALID` | Require one; zero is structural corruption and must not normally be streamed. |
| 6 | `WINDOW_END` | Recognized legacy flag; continuous G2B must emit zero. It is not EOF. |
| 7..31 | `RESERVED_ZERO` | Require zero for MMIO ABI 1.0. |

There is no source-unlocked, source-recovered, reset-boundary, dropped-before, or EOF bit. Linux derives those conditions from epoch, sequences, defined flags, source/MMIO status, and counters.

## Frame reconstruction

Maintain one independent assembler per active logical channel. The frame key is:

```text
(card/MMIO identity,
 logical_channel_id,
 physical_input_id,
 reset_epoch,
 source_frame_sequence)
```

For each structurally valid record, copy its 3,840-byte payload to line offset:

```text
source_line_sequence * 3840
```

in a 4,147,200-byte UYVY frame buffer. A complete frame contains exactly one record for each line 0 through 1079. Line 0 must carry `SOF`; line 1079 is the inferred frame end only after all lines are present. There is no EOF flag.

On `NEW_EPOCH`, `DISCONTINUITY`, missing/duplicate line, unexpected mapping change, or source sequence restart, mark the affected frame incomplete and do not present it as a complete frame. Resume assembly at the next coherent line-0/SOF record under host policy.

Interleaved records for the other logical channel do not interrupt a channel's frame assembly. `global_stream_sequence` validates total transport order; per-channel attempt and source sequences validate each channel separately.

## What comes from records and what comes from MMIO

| Information | Record | MMIO |
|---|:---:|:---:|
| Magic and record parser version | Yes | ABI support/version also negotiated here |
| Reset epoch | Yes, per record | Current live epoch for cross-check |
| Logical channel and physical input | Yes, per record | G2B capability bits identify one-channel implementation; mapping is fixed by this contract, with no G2B mapping register |
| Source frame/line/capture sequence | Yes | No |
| Per-channel attempt sequence | Yes | Last/counter telemetry |
| Global stream sequence | Yes | Last/counter telemetry |
| Discontinuity/overflow/malformed context | Yes | Sticky/live errors and aggregate counters |
| UYVY active-line payload | Yes | No |
| Full source Git/build identity | No | Yes, authoritative legacy identity tuple |
| ABI support versus implementation | No | Yes |
| Ring occupancy/full/active state | No | Yes |
| Attempted/committed/streamed/dropped/beat/error counts | Snapshots only for source malformed/drop fields | Yes, coherent counter snapshot |
| Card/BDF identity | No | Device enumeration plus MMIO association |

The consumer must use the MMIO coherency mechanism defined by the G2B MMIO contract. It must not assemble a 64-bit counter from independently changing live low/high words.

## Forward compatibility

- Reject MMIO major mismatch before enabling streaming.
- Under MMIO ABI 1.0, reject any nonzero reserved flag or reserved subfield.
- Reject an unsupported record version.
- A newer major-1 minor may retain record version `0x00004101` only with the same 64-byte base layout, geometry, payload position, and mandatory meanings.
- Only when MMIO advertises a newer compatible minor may an older major-1 parser ignore newly defined flag bits or values occupying V1.0-reserved subfields. It must not interpret them.
- Header growth, field movement, record-size change, payload-offset change, or changed mandatory semantics requires a new major and record version.
- Padding is never an extension area and remains zero.

## Explicitly outside this transport contract

The following remain future Linux/V4L2 design decisions and are not inferred from the transport ABI:

- V4L2 device/node registration and ioctl surface;
- vb2 queue, mmap, dmabuf, or userspace-copy strategy;
- DMA descriptor construction and kernel/userspace ownership;
- frame timestamp source and clock domain;
- pixel colorimetry/range metadata beyond byte order;
- interlace/progressive negotiation, field handling, crop, scale, or format conversion;
- source-selection user policy and automatic failover;
- complete/incomplete-frame delivery policy above the mandatory classification;
- storage/file/container encoding;
- interrupt versus polling policy;
- NVP/I2C initialization and recovery control;
- PCIe recovery, driver reload, and device-node naming policy; and
- throughput qualification or hardware acceptance.

Those layers may consume this contract but must not reinterpret its bytes, sequences, epochs, identities, flags, or fixed record boundary.
