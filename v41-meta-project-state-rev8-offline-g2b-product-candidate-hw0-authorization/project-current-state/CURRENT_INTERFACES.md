# AHD Current Interfaces

`PROJECT_STATE_REV = 8`

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
| `0x0010–0x0020` | `GIT_SHA_W0..W4` | Runtime fingerprint `224d194e5f82c85bcb29297561c5d5e76d28063b` for this candidate; dual identity binding below | `FROZEN` |
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
| C2H device interface | one C2H channel, host node family `/dev/xdma*_c2h_0` | `FROZEN` | One engine per card; donor application payload is inactive; exact PRODUCT data plane offline-qualified, hardware NOT_PROVEN |
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
| XDMA C2H channel count | 1 per card | `ACCEPTED` | One-channel plane offline-qualified; hardware NOT_PROVEN |
| Logical capture channels | IDs 0 and 1 | `ACCEPTED` | Two-channel hardware not qualified |
| Physical input IDs | 0 through 3 | `ACCEPTED` | Current evidence proves only the present VDO1 path |
| Mapping rule | two distinct physical IDs may map to logical 0/1 | `ACCEPTED` | Change only while affected channel disabled and drained |
| Scheduling | record-boundary work-conserving round-robin | `FROZEN` | No beat interleave; one-channel offline candidate accepted; two-channel target unqualified |
| Buffer ownership | private four-record ring per logical channel | `FROZEN` | One-channel offline qualification; two-channel and hardware unqualified |
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
| Accepted G2B implementation | Exact one-channel `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` via `G2B-LUT1-SIGNOFF-RECOVERY-4` |
| G2B-HW | `PLANNED`; `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; hardware NOT_PROVEN |
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

#### Group-9 ownership CDC sign-off

For `OWNERSHIP_AXI_TO_SOURCE`, the current required method is
`PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`. Structural validation covers the
two-stage request synchronizer, two-stage acknowledgement synchronizer, held
58-bit stable-data payload, source hold until acknowledgement, and
reset/epoch coherency. The coherent payload is partitioned into exactly three
semantic families: 2-bit `slot`, 24-bit `generation`, and 32-bit `epoch`.

Each family requires an absolute settling check with a `6.000 ns` maximum.
The basis is the `13.468 ns` minimum launch-to-use margin and `7.468 ns` gross
reserve. The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not
a relaxation of safety; it directly verifies the stable-data mailbox
protocol.

The former `GLOBAL_SET_BUS_SKEW_3NS` and its global Group-9
`report_bus_skew` invocation are `RETIRED_FROM_REQUIRED_SIGNOFF` because the
58-source set is structurally heterogeneous and invalid for a global skew
comparison. Historical diagnostic references remain provenance only and do
not mandate another run.

`RTL_CHANGE_REQUIRED = NO`. The candidate authority is
`G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc`; the authoritative Group-9
result is `PRESERVE_PASS`, and META-6 does not reopen or alter this method.

#### Group-13 reset-return CDC sign-off

For `RESET_RETURN_SOURCE_TO_AXI`, the current required method is
`SETTLING_PLUS_STRUCTURAL_CDC`. The former global relation

```tcl
set_bus_skew 3.000 \
  -from $g2b_reset_return_src \
  -to $g2b_reset_return_dst
```

is `RETIRED_FROM_REQUIRED_SIGNOFF`. Its seven source registers and 207
destination registers form a stable-data, handshake-qualified, reconvergent
completion interface and are `INVALID_FOR_SKEW_COMPARISON`. The historical
full Group-13 `report_bus_skew` timeout remains provenance only and is not a
current required-signoff query.

The returned interface contains exactly two semantic families:

| Family | Source payload | Governed physical requirement | Structural/use requirement |
|---|---|---|---|
| `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` | Three-bit abandoned-record snapshot | `6.000 ns` absolute datapath-only settling to the 32-cell accounting cone | Single-edge capture, stable until acknowledgement, and no AXI consumption before synchronized request/acknowledgement qualification |
| `RESET_COMMIT_PHASE_COMPLETION_BARRIER` | Four-bit per-slot commit-toggle phase snapshot | `6.000 ns` absolute datapath-only settling to the original 207-cell completion cone | Stable until acknowledgement; two-stage live commit-phase synchronization; equality with the held phase before qualified completion |

The family constraints target destination cells so all timing endpoint roles,
including `D`, `CE`, `S`, and `R`, remain covered. The unchanged broad
source-mailbox `6.000 ns` max-delay relation must also remain in force. It
contains every Group-13 member and supplies the separately validated 79-cell
supplemental fanout coverage for
`RESET_COMMIT_PHASE_COMPLETION_BARRIER`; this is not a third family.

The interface proof additionally requires two-stage request and acknowledgement
synchronizers, hard-episode qualification, reset-return coherency,
destination-use sequencing, and atomic reset epoch/state publication only on
the qualified completion edge. Commit-phase parity alias is excluded by
exclusive reset handling with admission disabled and commit enqueue/scheduler
progress suppressed while reset is busy. Reset observations are synchronous
process conditions, not an async-reset-release interface.

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT`.
`RTL_CHANGE_REQUIRED = NO`. The Group-13 candidate authority is
`G2B_G13A_CANDIDATE_CONSTRAINTS.xdc`; the recovery-2 result is
`PRESERVE_PASS`, and META-6 does not reopen or alter this method.

#### Group-14 release-slot CDC sign-off

For `RELEASE_SLOT_0_AXI_TO_SOURCE`, the current required method is
`SETTLING_PLUS_STRUCTURAL_CDC`. The former global relation

```tcl
set_bus_skew 3.000 \
  -from $g2b_release0_payload_src \
  -to $g2b_release_payload_dst
```

is `RETIRED_FROM_REQUIRED_SIGNOFF`. Its 56 source registers—24 slot-0
generation bits and 32 slot-0 epoch bits—and 20 heterogeneous destination
registers are `INVALID_FOR_SKEW_COMPARISON`. The verified historical full
Group-14 `report_bus_skew` timeout remains provenance only and is not a current
required-signoff query.

The interface contains exactly three semantic families:

| Family | Semantic use | Governed physical requirement | Validated routed result |
|---|---|---|---|
| `RELEASE_SLOT0_NORMAL_STATE_TRANSITION` | Matching slot-0 token authorizes `DMA_OWNED -> RELEASABLE`; 56 sources to 3 state bits | `6.000 ns` absolute datapath-only settling | worst actual `5.467 ns`; slack `0.563 ns`; `PASS` |
| `RELEASE_SLOT0_MISMATCH_CONTAINMENT` | Generation, epoch, reset-epoch, or ownership mismatch fails closed; 56 sources to 4 fault/admission registers | `6.000 ns` absolute datapath-only settling | worst actual `5.554 ns`; slack `0.478 ns`; `PASS` |
| `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING` | Synchronized transport request uses the same-episode token before captured-phase retirement; 56 sources to 3 reset-abandoned counter bits | `6.000 ns` absolute datapath-only settling | worst actual `4.191 ns`; slack `1.839 ns`; `PASS` |

Generation, epoch, and `release_toggle_axi[0]` launch together on the final
accepted AXI-stream beat. Ordinary use follows the two-stage `ASYNC_REG`
release-toggle chain and occurs only after the synchronized phase differs from
`release_seen_source[0]`. This is a one-way event plus stable data, not an
ordinary request/acknowledgement mailbox. The slot lifecycle holds the 56-bit
token through event consumption and prevents overwrite until the slot is
refilled, committed, returned to AXI ownership, and streams another complete
512-beat record.

Normal consumption requires generation equality with the slot, epoch equality
with both the descriptor and current reset epoch, and `DMA_OWNED` ownership.
Any mismatch latches ownership-fatal containment and disables admission. This
fail-closed identity check prevents a stale token from releasing a newer owner.

For a same-edge reset/release overlap, the AXI reset request captures the
updated release phase and launches the transport request. Reset accounting is
authorized by the separate two-stage `ASYNC_REG` transport-request chain, not
by a release-toggle mismatch. It uses generation and epoch for
`release_matches`, computes `reset_abandoned_hold_source`, and forces slots
writable. Transport acknowledgement remains blocked until the independently
synchronized release vector equals the captured phase; the consumed or
reset-retired phase is recorded in `release_seen_source[0]`.

The interface contract therefore requires `ABSOLUTE_SETTLING`,
`STABLE_DATA_UNTIL_EVENT_CONSUMPTION`, `EVENT_ORDERING`,
`SYNCHRONIZER_STRUCTURE`, `COMPLETION_BARRIER`, and `TOKEN_IDENTITY`, including
destination-use ordering and reset/release coherency. The timing constraints
and these structural requirements form one inseparable sign-off method.

HISTORICAL META-6 promotion-time implementation boundary (SUPERSEDED
as a current work instruction by revision 7; accepted Group-14 method unchanged):

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT`.
`RTL_CHANGE_REQUIRED = NO`. `ACTIVE_XDC_CHANGE =
AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; active production XDC is unchanged
by META-6. Candidate authority is `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from
evidence commit `9e91315968453e859006077191cd5fc711fc6b96`.

`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`; and
`GROUP13 = PRESERVE_PASS`. `GROUPS_15_TO_17 = PENDING_UNCHANGED`. The next
governed source task is `G2B-LUT1-SIGNOFF-RECOVERY-3`; G2B-HW remains lifecycle
`BLOCKED` and `NOT_PROVEN`.

#### Combined Groups 15–17 release-slot sign-off — revision 7

Owner/Architect decision `META-7R_TASK_DIRECTIVE` promotes
`PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` from `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
`COMBINED_PROMOTION_SCOPE = GROUPS_15_16_17`.

Group 15 `RELEASE_SLOT_1_AXI_TO_SOURCE`, Group 16
`RELEASE_SLOT_2_AXI_TO_SOURCE`, and Group 17 `RELEASE_SLOT_3_AXI_TO_SOURCE`
each retire `GLOBAL_SET_BUS_SKEW_3NS` as `RETIRED_FROM_REQUIRED_SIGNOFF`.
The historical scope of each was 56 sources / 20 destinations. Group 15 mixed
normal-state, fault/history and other-slot roles and omitted reset-overlap
accounting endpoints. Group 16 mixed semantically different destination
roles. Group 17 likewise did not describe one coherent relative-skew bus.
All three path sets are `INVALID_FOR_SKEW_COMPARISON`; their global
`report_bus_skew` queries are retired from every current required recipe.

Each replacement is `SETTLING_PLUS_STRUCTURAL_CDC`, state `PROMOTED`:

| Group | Slot | Semantic family | Permanent settling cap | Validated collection |
|---|---|---|---|---|
| 15 | 1 | `RELEASE_SLOT1_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 15 | 1 | `RELEASE_SLOT1_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
| 15 | 1 | `RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 16 | 2 | `RELEASE_SLOT2_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 16 | 2 | `RELEASE_SLOT2_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
| 16 | 2 | `RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 17 | 3 | `RELEASE_SLOT3_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 17 | 3 | `RELEASE_SLOT3_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
| 17 | 3 | `RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |

One architecture covers three independently validated slot implementations,
three families each, and nine independent timing checks. All nine candidate
checks passed; runtime is `PRACTICAL`; replacement equivalence is
`SAFER_AND_MORE_SEMANTICALLY_CORRECT`.

`SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`;
`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`;
`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`.
Routed cones are not exact copies of slot 0 or one another: mapped depths,
LUT input pins and placement differ. Source and destination collections must
be resolved independently for each slot and each routed cone validated.
Shared containment/reset destination cells do not merge the independently
scoped source-to-destination relations.

The permanent requirement is `SETTLING_CAP = 6.000 ns` absolute datapath-only
for each family. The basis is a `6.734 ns` destination clock period, at least
two qualifying destination periods (`13.468 ns` launch-to-use window), and
`7.468 ns` gross protocol reserve. This common cap is retained only after
independent proof of each slot's clock period, qualifying synchronization
depth, destination-use phase, stable-data lifetime and mismatch/reset/
retirement semantics. Route-specific actual delays and slacks remain evidence,
not permanent architectural bounds.

The structural proof is inseparable from timing: hold the 56-bit token
(24 generation bits and 32 epoch bits), launch token and release toggle on
the same accepted final AXI beat, retain two direct `ASYNC_REG` release-toggle
stages, and permit normal destination use only after the synchronized event.
Hold the payload through consumption and prohibit premature overwrite or
slot reuse. Generation/epoch/current-reset-epoch and ownership mismatch must
fail closed, latch containment and disable admission.

Reset-overlap accounting uses its separate two-stage transport-request
synchronizer and the same-episode token. Capture the same-edge release phase,
prevent stale release across reset, and require the independently synchronized
release vector and ownership phase to match their captures before coherent
retirement and acknowledgement. Each slot retains all eight proven safety
invariants; its CDC disposition is `PASS_WITH_DISPOSITION`.

The candidate creates no release-slot bus-skew relation. Remaining focused
TIMING-34/TIMING-39 warnings arise from other preserved relations and remain
subject to normal final sign-off disposition, outside this architecture
decision. Project-wide warning closure is not claimed.

Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.

Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.

Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.


### Frozen G2B MMIO contract

`MMIO STATUS = FROZEN`

`AHD_V41_G2B_MMIO_V1` is lifecycle `FROZEN` at `0x3800..0x3BFF`, and implemented unchanged in the exact offline PRODUCT candidate.
G2B-HW is lifecycle PLANNED and NOT_PROVEN.
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

PRODUCT is the accepted exact offline-qualified candidate, with actual LUT
qualification and bitstream bound below. RESEARCH_DIAGNOSTIC post-G2B
build/route is not promoted. No hardware result is claimed.

## Interface change control

A future interface change requires `INTERFACE_CHANGE` authorization, an exact
Owner/Architect decision, immutable accepted evidence, the expected prior
revision, updates to this document and `COMPATIBILITY_MATRIX.csv`, a one-step
revision increment, changelog/evidence-map updates, non-force publication, and
remote read-back.

## Accepted offline G2B PRODUCT test candidate — META-8A

G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.

| Candidate binding | Exact value |
|---|---|
| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Runtime BUILD_FLAGS | `0x00000103` |
| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |

The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.

R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.

G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).

Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
