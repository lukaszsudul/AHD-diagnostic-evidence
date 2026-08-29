# AHD Current Interfaces

`PROJECT_STATE_REV = 3`

> `CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B`

This document separates accepted/frozen compatibility surfaces and frozen
implementation-input contracts from implementation and hardware
qualification. Freezing an interface does not mean that its RTL, DMA path,
host frontend, or hardware behavior has been implemented or proven.

## Authoritative accepted/frozen interfaces

### XDMA user control identity

All values are little-endian 32-bit words in the current XDMA user AXI-Lite
aperture.

| Offset | Interface field | Accepted value | Status |
|---:|---|---:|---|
| `0x0000` | `BLOCK_ID` | `0xA40A0C07` | `FROZEN` |
| `0x0004` | `PROTOCOL` | `0x0000400B` (`v40B`) | `FROZEN` |
| `0x0008` | `CAPABILITIES` | `0x00031002` | `FROZEN` |
| `0x000C` | `BUILD_ID_SCHEMA` | `0x00010000` | `FROZEN` |
| `0x0010–0x0020` | `GIT_SHA_W0..W4` | exact 40-hex clean source commit | `FROZEN` |
| `0x002C` | `BUILD_FLAGS` | dirty and verified-clean provenance bits | `FROZEN` |
| `0x0030` | `TRANSPORT_SIGNATURE` | `0x58444D41` (`XDMA`) | `FROZEN` |
| `0x0034` | `SCRATCH_RW` | byte-enable-aware, no side effect | `FROZEN` |

The current `PROTOCOL` value describes the existing v40B/PIO record contract.
It must not be changed to advertise an unimplemented v41D transport.

### BAR structure

| Surface | Current donor mapping | Status | Compatibility rule |
|---|---|---|---|
| User AXI-Lite BAR | observed BAR0, 128 KiB aperture at local address 0 | `FROZEN` | Host tooling must discover BAR assignments; preserve the 128 KiB semantic aperture |
| XDMA configuration BAR | observed BAR1, 64 KiB aperture | `FROZEN` | Distinct from the user AXI-Lite aperture; use driver/device discovery |
| C2H device interface | one C2H channel, host node family `/dev/xdma*_c2h_0` | `FROZEN` | One engine per card; current application payload is inactive |
| H2C device interface | one mandatory donor H2C interface | `FROZEN` | Unsupported by application; application `TREADY=0` and host must not submit H2C |

BAR numbering is the verified donor observation, not permission for consumers
to hard-code enumeration order. The stable interface is the distinct
configuration/user-aperture structure discovered through the device/driver.

### Existing MMIO compatibility

| Address range | Current interface | Status | Rule |
|---|---|---|---|
| `0x0000–0x00FF` | XDMA-local identity, status, telemetry, scratch, and tied-zero placeholders | `FROZEN` | Preserve values, reset behavior, byte enables, unaligned/reserved behavior, and response timing |
| `0x00C0–0x00E0` | Named DMA/interrupt telemetry currently tied to zero | `FROZEN` | Do not activate, move, or repurpose silently; these addresses are inside protected legacy space |
| `0x0100–0x35FF` | Forwarded legacy PIO/capture/MMIO space | `FROZEN` | Preserve all existing semantics through inclusive `0x35FF` |
| `0x3600–0x367F` | R1i read-only 32-word causal telemetry page | `FROZEN` | Preserve addresses, meanings, read-only behavior, and read-service timing |
| `0x3680–0x37FF` | Reserved compatibility gap | `FROZEN` | Do not allocate without an accepted interface change |

Unlisted aligned local words read zero and ignore writes; unaligned local reads
return zero and writes are ignored. No new router may add a registered stage to
the protected R1i/legacy response path.

### C2H architecture and channel identity

| Interface decision | Current value | Status | Qualification boundary |
|---|---|---|---|
| XDMA C2H channel count | 1 per card | `ACCEPTED` | Donor interface exists; application data plane not accepted |
| Logical capture channels | IDs 0 and 1 | `ACCEPTED` | Two-channel hardware not qualified |
| Physical input IDs | 0 through 3 | `ACCEPTED` | Current evidence proves only the present VDO1 path |
| Mapping rule | two distinct physical IDs may map to logical 0/1 | `ACCEPTED` | Change only while affected channel disabled and drained |
| Scheduling | record-boundary work-conserving round-robin | `FROZEN` | No beat interleave; no implementation is accepted/offline-qualified and current G2B-IMPL is `BLOCKED_RESOURCE_HEADROOM` |
| Buffer ownership | private four-record ring per logical channel | `FROZEN` | Exact ownership contract is frozen; implementation and resources are not qualified |
| Host transport order | one global streamed order plus per-channel attempt order | `FROZEN` | Encoded fields are frozen by `AHD_C2H_TRANSPORT_ABI_V1`; hardware is `NOT_PROVEN` |

Channel identity semantics are authoritative at the architecture level:
logical channel identifies the consumer stream, physical input identifies the
selected connector/source, per-channel attempt sequence represents source
admission/drop order, and global sequence represents successful shared-C2H
transport order.

## Frozen G2B implementation-input interfaces

### `AHD_C2H_TRANSPORT_ABI_V1`

`INTERFACE STATUS = FROZEN_FOR_G2B`

| Property | Project truth |
|---|---|
| Lifecycle status | `FROZEN` |
| Interface status | `FROZEN_FOR_G2B` |
| ABI numeric version | `1` |
| MMIO ABI version | `0x00010000` (`major=1`, `minor=0`) |
| Record family / version | `v41D` / `0x00004101` |
| Accepted G2B implementation | none; current G2B-IMPL is `BLOCKED_RESOURCE_HEADROOM` and not offline-qualified |
| G2B hardware | `NOT_PROVEN` |
| Normative evidence | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |

#### Record geometry and header

Every record is exactly 4,096 bytes: a 64-byte header at bytes `0..63`, one
3,840-byte useful payload at bytes `64..3903`, and 192 padding bytes at
`3904..4095`. Header scalars are sixteen complete little-endian unsigned
32-bit words with no unnamed byte, gap, or overlap.

| Offset | Field | Reset/default | Frozen semantics |
|---:|---|---|---|
| `0x00` | `magic` | `0x4C444841` | Constant record magic; wire bytes are `41 48 44 4C` |
| `0x04` | `record_version` | `0x00004101` | Selects the fixed-layout `v41D` parser |
| `0x08` | `reset_epoch` | FPGA configuration creates epoch `0` | Per-card/shared-stream transport generation; not a build ID |
| `0x0C` | `source_frame_sequence` | internal `0`; first emitted frame `1` | Source-frame number modulo `2^32`; transport reset does not reset it |
| `0x10` | `source_line_sequence` | first active line `0` | Zero-based active line; legal values `0..1079` |
| `0x14` | `source_capture_sequence` | internal `0`; first emitted capture `1` | Counts completed valid source lines modulo `2^32`; failed attempts do not consume it |
| `0x18` | `payload_length` | `3840` | Useful bytes beginning at byte 64; V1 requires exactly 3,840 |
| `0x1C` | `flags` | per-record | Exact flag contract below |
| `0x20` | `active_logical_channel_count` | G2B value `1` | Legal emitted values `1` and `2`; G2B emits `1` |
| `0x24` | `source_slot_generation_and_slot` | generation `0`; first allocation `1` | Bits `31:8` generation modulo `2^24`; bits `7:4` zero; bits `3:0` slot, G2B `0..3` |
| `0x28` | `source_malformed_count_snapshot` | `0` after source reset | Source-local lifetime count preceding this commit; not clearable MMIO statistics |
| `0x2C` | `source_dropped_count_snapshot` | `0` after source reset | Source-local noncommitted-attempt count preceding this commit; not clearable MMIO statistics |
| `0x30` | `logical_channel_id` | G2B value `0` | Bits `1:0`: `0,1` legal, `2` reserved, `3` invalid; bits `31:2` zero |
| `0x34` | `physical_input_id` | G2B value `0` | Bits `2:0`: `0..3` legal, `4..6` reserved, `7` invalid; bits `31:3` zero |
| `0x38` | `channel_attempt_sequence` | next value `0` each epoch | Per-logical-channel eligible-attempt order, including later dropped, malformed, or aborted attempts |
| `0x3C` | `global_stream_sequence` | next value `0` each epoch | Complete-record order in the single shared C2H stream |

Flag bit 0 is `SOF`; bit 1 is zero; bits 2, 3, and 4 are respectively
`DISCONTINUITY`, `OVERFLOW_OCCURRED`, and `MALFORMED_PRECEDING`; bit 5 is
`VALID` and must be one in every streamed G2B record; bit 6 is `WINDOW_END`
and is zero for continuous G2B; bits `7..31` are zero. V1 defines no EOF,
source-unlocked, source-recovered, reset-boundary, or dropped-before flag.

#### Channel, payload, and source semantics

The ABI supports logical IDs 0 and 1 and physical IDs 0 through 3. G2B is
frozen to emit logical channel 0, physical input 0, and active count 1; this
namespace compatibility does not implement logical channel 1. Card/build
identity comes from the opened XDMA device/BDF and the authoritative MMIO
identity tuple, including full Git SHA, not from a record field.

Each payload is exactly one complete validated 1,920-pixel active line in
packed UYVY 4:2:2 order. For pixel pair `p=0..959`, bytes `4p+0..4p+3` are
`U0,Y0,V0,Y1`. SAV/EAV, blanking, checksum, timestamp, descriptor data, and
line padding are excluded. Line 0 has `SOF=1`; there is no EOF flag. A frame is
complete only after exactly one valid ordered instance of every line
`0..1079` under one card/channel/input/epoch/frame-sequence identity.

FPGA configuration, explicit source reset, source disable/re-enable, applied
input remap, or explicit source formatter/configuration reset restarts source
frame/capture state; the first record is frame 1, line 0, capture 1. Source
reset preserves the transport epoch and transport sequences, aborts an
affected uncommitted record, and makes discontinuity pending. PCIe, AXI, host
stream, or standalone transport reset does not reset source sequences.

All padding bytes `3904..4095` are formatter-generated `0x00`. They remain
part of the record with full `TKEEP` and may never expose stale or unwritten
RAM. A consumer validates them as zero and then ignores them.

#### AXI mapping, sequences, ownership, loss, and reset

- The stream is 64 bits and exactly 512 beats per record. Record byte
  `8*n+k` maps to `TDATA[8*k +: 8]`; `TKEEP=0xFF` on every beat; `TLAST` is
  one only on beat 511.
- Beat 0 is not offered until a complete committed record and matching
  descriptor are owned in the XDMA clock domain. After it is offered,
  `TVALID` remains asserted through the final handshake with no intentional
  intra-record bubble.
- While `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain
  stable. Beat state advances only on `TVALID && TREADY`; all record identity
  and metadata remain locked; slot release begins only after the beat-511
  handshake.
- Each channel assigns `channel_attempt_sequence` before incrementing at every
  eligible enabled attempt. Ring-full, later-malformed, and later-aborted
  attempts consume one value modulo `2^32`; disabled input observations do
  not. Only a new transport epoch resets the next value to zero.
- The shared scheduler assigns `global_stream_sequence` at
  `COMMITTED -> DMA_OWNED` before beat 0 and increments it only on the
  beat-511 handshake. Drops consume no global value. Complete records are
  contiguous across channels within one epoch, and at most one slot is
  `DMA_OWNED` across the shared stream.
- Each logical channel owns four nonborrowable slots with normal states
  `WRITABLE -> FILLING -> COMMITTED -> DMA_OWNED -> RELEASABLE -> WRITABLE`.
  Commit occurs only after all 3,840 payload bytes and source validation.
  Committed data and its descriptor are immutable; per-channel committed
  order is FIFO; illegal transition or channel/slot/generation/epoch mismatch
  is fatal. No committed record may be overwritten.
- Video input is not backpressured. With no `WRITABLE` slot, the complete new
  attempt is dropped before any byte is written, existing records remain
  unchanged, attempted/dropped/overflow counts increment exactly once, and
  discontinuity/overflow context annotates the next committed record. Partial
  drop, overwrite-oldest, silent repair, and cross-channel borrowing are
  forbidden.
- `reset_epoch` is shared per card. Configuration establishes zero; each later
  PCIe/PERST or `axi_aresetn` episode, accepted `RESET_STREAM_STATE`, or
  standalone formatter/transport reset increments it exactly once modulo
  `2^32`; overlapping causes coalesce. Consumers compare epochs by inequality.
  Enable/disable, statistics reset, source loss/reset, and NVP/I2C activity do
  not advance it.
- Every epoch reset disables admission and requires explicit host re-enable,
  resets both transport sequences, flushes all nonwritable ownership only
  through the cross-domain epoch handshake, abandons incomplete/in-flight
  transport state without exposing a suffix, and resumes only at beat 0 of a
  newly committed complete record. It must not reset or replay NVP/I2C
  initialization.

### Frozen G2B MMIO contract

`MMIO STATUS = FROZEN`

`AHD_V41_G2B_MMIO_V1` is lifecycle `FROZEN` at `0x3800..0x3BFF`, but no
implementation is accepted/offline-qualified; current G2B-IMPL is
`BLOCKED_RESOURCE_HEADROOM` and hardware status is `NOT_PROVEN`.
The router must claim exactly that range before legacy forwarding. Every
address through `0x37FF` retains its frozen accepted-base value, side effect,
byte-enable behavior, ordering, and response latency. `0x3C00..0x3FFF` is not
claimed by G2B. Reserved or unaligned extension reads return zero, writes have
no effect, and responses are `OKAY`.

| Address/range | Frozen register or disposition |
|---:|---|
| `0x3800` | `C2H_MAGIC = 0x43324831` |
| `0x3804` | `ABI_VERSION = 0x00010000` |
| `0x3808` | `CAPABILITIES = 0x000B001F` in a conforming future G2B build; support and implemented-this-build bits are distinct; two-channel implemented is zero |
| `0x380C` | `CONTROL`: bit 0 `ENABLE_C2H`, bit 1 `RESET_C2H_STATS`, bit 2 `RESET_STREAM_STATE` |
| `0x3810` | `STATUS`: enabled, active, empty/full, loss aliases, source ready/locked, reset/snapshot busy, snapshot valid, fatal error |
| `0x3814..0x3830` | Coherent snapshot counters for attempted, committed, streamed, dropped, overflow, discontinuity, and 64-bit beats streamed |
| `0x3834` | `LAST_GLOBAL_STREAM_SEQUENCE` |
| `0x3838` | live `RESET_EPOCH` |
| `0x383C` | RW1C `ERROR_STATUS`: ring overflow, record drop, sequence discontinuity, formatter error, ownership error, transport error |
| `0x3840` | `LAST_ERROR_CAUSE` |
| `0x3844..0x384C` | Snapshot command, status, and generation |
| `0x3850` | `RECORDS_ABANDONED` |
| `0x3854` | `RESET_EVENTS` |
| `0x3858` | `LAST_CHANNEL_ATTEMPT_SEQUENCE` |
| `0x385C..0x3BFF` | `RESERVED_ZERO`, read-as-zero/write-ignored; scheduler/channel-1/selection pages are not implemented |

Fatal errors clear enable and require stream-state-reset recovery before a
legal W1C. Statistics reset is legal only when disabled, inactive, empty, and
neither reset nor snapshot is busy. Counter reads use the frozen acknowledged
coherent-snapshot protocol, with `RESET_EPOCH` read before and after; live or
torn low/high reads are not conforming.

### Frozen Linux transport input contract

The Linux consumer contract is `FROZEN_INPUT_CONTRACT`. Before enable, a
consumer binds the XDMA node/BDF to the full legacy MMIO identity, validates
MMIO ABI major 1 and implementation capability bits, issues
`RESET_STREAM_STATE`, waits for reset idle/inactive/empty, legally clears any
fatal error, records the resulting epoch and a coherent snapshot, explicitly
enables C2H, and requires the first record to carry that epoch and global
sequence zero. Mid-epoch session attachment is not conforming.

The parser consumes only fixed 4,096-byte boundaries and never scans for
magic. It validates magic, record version, payload length, flags/reserved
bits, slot/channel/input identity, sequence and epoch coherence, SOF/line
agreement, `VALID`, and all zero padding before extracting bytes `64..3903`.
It classifies records as `VALID_RECORD`, `CORRUPT_RECORD`, `NEW_EPOCH`, and
`DISCONTINUITY`; epoch/sequence discontinuity invalidates an affected frame
without redefining the record boundary.

This frozen transport input does not freeze or implement a V4L2 frontend,
final V4L2 pixel format, timestamp architecture, vb2/mmap/DMABUF strategy,
stable multi-card identity policy, incomplete-frame presentation policy, or
LitePCIe backend. All remain later L-track/open decisions.

## Build-profile interface boundary

Build-profile selection must not alter any externally visible product
transport semantic. `PRODUCT` and `RESEARCH_DIAGNOSTIC` differences are
observability and resource-elaboration differences only.

Both profiles must preserve identical qualified R1i functional behavior,
XDMA configuration, NVP/I2C behavior, video-capture semantics, product
identity/capability semantics, legacy response behavior, and product MMIO
contract. Wherever G2B is included, both use the unchanged
`AHD_C2H_TRANSPORT_ABI_V1` and unchanged frozen MMIO range
`0x3800..0x3BFF`, including every defined status/counter/reset/error semantic
and reserved-zero behavior.

Research instrumentation may never be a prerequisite for a product interface
value or functional transition. If research-only observation structures are
not elaborated in PRODUCT, G2B-LUT1 must preserve the externally visible
contract and deterministic compatibility behavior without aliasing or stale
data. The source-level mechanism is deliberately not selected by META-3.

Both profiles are `AUTHORIZED_NOT_IMPLEMENTED`. No current
RESEARCH_DIAGNOSTIC post-G2B build/route, PRODUCT LUT qualification, G2B
bitstream, or hardware result is claimed.

## Interface change control

A future interface change requires `INTERFACE_CHANGE` authorization, an exact
Owner/Architect decision, immutable accepted evidence, the expected prior
revision, updates to this document and `COMPATIBILITY_MATRIX.csv`, a one-step
revision increment, changelog/evidence-map updates, non-force publication, and
remote read-back.
