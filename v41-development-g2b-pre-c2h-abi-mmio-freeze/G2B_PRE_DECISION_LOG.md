# AHD v41 G2B-PRE Decision Log

## Status and decision authority

```text
CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B
G2B_MMIO_STATUS = FROZEN
PROJECT_STATE_REV_AT_START = 1
PROJECT_STATE_REV_AT_END = 1
```

This log closes every transport/MMIO decision that blocked the previous G2B
implementation attempt. The final decisions are task-local implementation
contracts authorized by the G2B-PRE architecture-freeze directive. They are
evidence truth, not a modification of accepted project truth. The revision-1
SSOT remains unchanged until an Owner/Architect accepts these exact decisions
and a separate authorized META task performs the transaction specified by
`G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md`.

The direct blocker evidence is:

- `../v41-development-g2b-one-channel-c2h-offline/G2B_BLOCKER_REPORT.md:5-18`
  for the four unresolved record semantics;
- `../v41-development-g2b-one-channel-c2h-offline/G2B_BLOCKER_REPORT.md:20-36`
  for the MMIO allocation/encoding blocker;
- `../v41-development-g2b-one-channel-c2h-offline/G2B_RECORD_CONTRACT_RECEIPT.md:76-104`
  for sequence, epoch, build-ID, and golden-contract requirements; and
- `../v41-development-g2b-one-channel-c2h-offline/G2B_MMIO_DELTA.md:38-70`
  for the proposed-only MMIO pages and missing bit-level semantics.

Revision-1 project truth explicitly marks the transport and G2 MMIO contracts
provisional in `../project-current-state/CURRENT_INTERFACES.md:77-117` and
retains `OD-06 / FINAL_C2H_ABI` as open in
`../project-current-state/OPEN_DECISIONS.md:10-21`.

## 1. ABI identity and version

- **Question:** What stable name and version identify the final transport ABI?
- **Previous status:** `PROVISIONAL`; G1 used the `v41D` record family and
  record word `0x00004101`, but revision-1 SSOT prohibited treating the plan as
  final.
- **Final decision:** The ABI is `AHD_C2H_TRANSPORT_ABI_V1`, numeric version
  `1`, MMIO version `0x00010000` (`major=1`, `minor=0`), record family `v41D`,
  and record version `0x00004101`. Header scalars are little-endian.
- **Rationale:** Separate MMIO negotiation from fixed-record parser selection
  while retaining the accepted v41D record discriminator.
- **Evidence source:** G1 geometry/version proposal at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:38-72`;
  final contract at `V41_C2H_TRANSPORT_ABI_V1.md` §Status and identifiers.
- **Downstream impact:** RTL, simulation vectors, MMIO tooling, Linux parsers,
  and future two-channel logic use one exact ABI name and two non-ambiguous
  version checks.

## 2. Record geometry and AXI mapping

- **Question:** Is the nominal 4 KiB geometry retained exactly?
- **Previous status:** Concrete in G1 but `PROVISIONAL` in SSOT.
- **Final decision:** Each record is exactly 4,096 bytes: header `0..63`
  (64 bytes), payload `64..3903` (3,840 bytes), and padding `3904..4095`
  (192 bytes). The stream is 64 bits, 512 beats, eight bytes per beat;
  `TKEEP=0xFF` on every beat and `TLAST=1` only on beat 511. Record byte
  `8*n+k` maps to `TDATA[8*k +: 8]`.
- **Rationale:** The geometry is aligned, has no partial final beat, retains the
  accepted useful-line payload, and isolates the host from storage details.
- **Evidence source:** G1 at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:38-47,74-84`;
  final contract at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Record geometry and §AXI4-Stream mapping and backpressure.
- **Downstream impact:** A consumer reads only integral 4,096-byte records and
  never scans for implicit boundaries. Formatter and AXIS tests must cover all
  512 beat positions.

## 3. Complete header and offset `0x08`

- **Question:** How are all 64 header bytes assigned, and where is reset epoch
  represented?
- **Previous status:** G1 assigned `0x08` to an unfrozen firmware/build ID and
  simultaneously required reset epoch in “MMIO/header context” without a
  header allocation.
- **Final decision:** The 16 little-endian `u32` words are:

  | Offset | Frozen field |
  |---:|---|
  | `0x00` | `magic = 0x4C444841` |
  | `0x04` | `record_version = 0x00004101` |
  | `0x08` | `reset_epoch` |
  | `0x0C` | `source_frame_sequence` |
  | `0x10` | `source_line_sequence` |
  | `0x14` | `source_capture_sequence` |
  | `0x18` | `payload_length = 3840` |
  | `0x1C` | `flags` |
  | `0x20` | `active_logical_channel_count` |
  | `0x24` | `source_slot_generation_and_slot` |
  | `0x28` | `source_malformed_count_snapshot` |
  | `0x2C` | `source_dropped_count_snapshot` |
  | `0x30` | `logical_channel_id` |
  | `0x34` | `physical_input_id` |
  | `0x38` | `channel_attempt_sequence` |
  | `0x3C` | `global_stream_sequence` |

  There are no unnamed bytes. Packed-word unused bits are `RESERVED_ZERO`.
  The `0x28`/`0x2C` source snapshots are source-local lifetime counters,
  distinct from clearable MMIO statistics; they reset on FPGA configuration or
  a defined source-sequence reset, not on `RESET_C2H_STATS` or a transport
  epoch reset alone.
- **Rationale:** Replacing redundant per-record build identity with the missing
  reset epoch resolves both blockers without expanding or moving the payload.
- **Evidence source:** Blocker report lines 13-16; complete final table at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Header layout.
- **Downstream impact:** The formatter and parser have a byte-complete header.
  Golden vectors can compare all 64 bytes without implementation inference.

## 4. Offset `0x38` — per-channel attempt sequence

- **Question:** What is the exact initial, assignment, increment, reset, wrap,
  and drop behavior for `0x38`?
- **Previous status:** The field was named but its initial/reset value, wrap,
  and pre/post-increment assignment were unresolved
  (`../v41-development-g2b-one-channel-c2h-offline/G2B_BLOCKER_REPORT.md:13`).
- **Final decision:** Each logical channel owns a 32-bit
  `channel_attempt_next`. FPGA configuration and every new transport epoch set
  it to `0`. At the decision point for every eligible active-line attempt while
  that channel is enabled, assign the current value to the attempt, then
  increment modulo `2^32`. The attempt consumes exactly one value whether it
  obtains a slot, is ring-full dropped, later proves malformed, or is aborted.
  Lines observed while disabled consume no value. Ordinary disable/enable,
  source loss/reset, and physical remapping do not reset the sequence. A
  streamed record carries the value assigned to its own attempt, so failed
  attempts appear as gaps.
- **Rationale:** Assignment-before-increment makes the first value exactly 0;
  numbering every eligible attempt makes losses externally observable and
  prevents silent sequence repair.
- **Evidence source:** G1 intended attempt/drop order at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:69,86-97`;
  unresolved details at
  `../v41-development-g2b-one-channel-c2h-offline/G2B_RECORD_CONTRACT_RECEIPT.md:76-84`;
  final rule at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Per-channel attempt sequence.
- **Downstream impact:** RTL increments once at admission decision; dropped,
  malformed, and aborted attempts consume sequence numbers. Host gaps are
  discontinuities and reconcile against drop/malformed counters.

## 5. Offset `0x3C` — global streamed sequence

- **Question:** How can the global value be present before transfer while G1
  described an increment on completion?
- **Previous status:** G1 called it scheduler-assigned and said increment on
  completion, leaving assignment point and first emitted value ambiguous
  (`../v41-development-g2b-one-channel-c2h-offline/G2B_BLOCKER_REPORT.md:14`).
- **Final decision:** The shared C2H stream owns 32-bit `global_stream_next`.
  FPGA configuration and every new transport epoch set it to `0`. At
  `COMMITTED -> DMA_OWNED`, before beat 0 is offered, the scheduler assigns and
  locks the current value in the record. The next-value register increments
  modulo `2^32` exactly once only on the beat-511
  `TVALID && TREADY && TLAST` handshake. Whole-record source/ring drops consume
  no value. A reset-abandoned record consumes no value in the new epoch.
  Completed records are contiguous across both logical channels. At most one
  shared-stream slot is `DMA_OWNED`; the next assignment cannot occur until
  the prior final handshake increments the next-value register.
- **Rationale:** Pre-stream assignment makes header bytes available, while
  final-handshake increment defines a sequence of records actually completed
  on C2H. Epoch reset eliminates ambiguity for a reset-abandoned assignment.
- **Evidence source:** Ambiguity at
  `../v41-development-g2b-one-channel-c2h-offline/G2B_RECORD_CONTRACT_RECEIPT.md:78-81`;
  shared scheduler context at
  `../v41-development-g1-integration-architecture/V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md:27-35`;
  final rule at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Global stream sequence.
- **Downstream impact:** The first completed record in each epoch is 0. Host
  global order is contiguous even when channel records interleave; drops affect
  only per-channel attempt order.

## 6. Reset epoch and sequence reset

- **Question:** Is epoch formal, what scope does it have, and which events
  advance it?
- **Previous status:** G1 required an epoch/flush but did not allocate the field
  or define sequence values across the transition.
- **Final decision:** `reset_epoch` at header `0x08` and MMIO `0x3838` is one
  per-card unsigned 32-bit value shared by the single C2H stream and all logical
  channels. FPGA configuration establishes epoch `0`. Each later PCIe/PERST or
  `axi_aresetn` reset episode advances it once on synchronized release; a host
  `RESET_STREAM_STATE` and a standalone formatter/transport reset each advance
  it once. Overlapping causes before completion coalesce. Wrap is modulo
  `2^32`, and hosts compare for inequality. Stream enable/disable,
  `RESET_C2H_STATS`, source loss/reset/reconfiguration, source formatter reset,
  and NVP/I2C activity do not advance it. Every new epoch resets both channel
  attempt-next values and global stream-next to 0.
  The exact owner is an `axi_aclk` transport-reset coordinator initialized only
  by FPGA configuration and not cleared by `axi_aresetn`; it treats
  `axi_aresetn` as an episode input and increments on synchronized release.
  Initial configuration release is masked. Repeated/overlapping causes while
  reset is busy coalesce into one increment. Source reset, source
  disable/re-enable, applied input remap, and source formatter/configuration
  reset reset source-local sequences but not epoch or transport sequences;
  source loss without reset does not reset source-local sequences.
  If such a source reset aborts `FILLING`, its transport attempt/drop accounting
  is applied, then the source-local sequence/header-counter bank clears; the
  old-lifetime abort is not reported in the new `0x2C` source snapshot.
- **Rationale:** A shared epoch disambiguates one shared transport and avoids
  coupling autonomous source/NVP lifecycle to PCIe transport lifecycle.
- **Evidence source:** G1 reset requirements at
  `../v41-development-g1-integration-architecture/V41_G1_CLOCK_RESET_CDC_PLAN.md:27-35,59-65`
  and prior gap at
  `../v41-development-g2b-one-channel-c2h-offline/G2B_CDC_RESET_REVIEW.md:49-68`;
  final contract at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Reset epoch and reset behavior and MMIO mirror
  at `V41_G2B_MMIO_CONTRACT.md` §Reset epoch rules visible through MMIO.
- **Downstream impact:** A host treats inequality as `NEW_EPOCH`, discards
  partial frames, clears continuity baselines, and requires global sequence 0.
  NVP/I2C initialization is never restarted by transport reset.

## 7. Firmware/build identity

- **Question:** What value belongs in the proposed per-record build-ID field,
  and what happens if identity changes during capture?
- **Previous status:** `0x08` was “Firmware/build ID” without a frozen value or
  inheritance rule
  (`../v41-development-g2b-one-channel-c2h-offline/G2B_BLOCKER_REPORT.md:16`).
- **Final decision:** There is no per-record build ID. Offset `0x08` carries
  reset epoch. Authoritative build identity is MMIO-only and is the complete
  existing read-only tuple: `BLOCK_ID`, `PROTOCOL`, `BUILD_ID_SCHEMA`,
  `GIT_SHA_W0..W4`, `VIVADO_VERSION`, `VIVADO_SW_BUILD`, and `BUILD_FLAGS`.
  The host snapshots the tuple before enable and after disable/drain. If any
  identity or ABI capability changes while active, it stops, discards buffered
  and unassembled data, closes/reopens the session, and renegotiates before
  accepting more records.
- **Rationale:** Full MMIO identity is authoritative and more complete than a
  truncated per-record value; duplication would waste bytes and create two
  identity authorities.
- **Evidence source:** Existing frozen identity in
  `../project-current-state/CURRENT_INTERFACES.md:13-30`; final decision at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Firmware/build identity.
- **Downstream impact:** The formatter needs no build-ID injection. Host tooling
  must not mix records from different identity tuples in one capture. Freezing
  the ABI does not change the current `PROTOCOL=0x0000400B` until implementation.

## 8. Flags

- **Question:** Which exact flags are assigned, and are new reset/source/drop
  flags added?
- **Previous status:** G1 inherited existing flags but the overall encoded ABI
  remained provisional.
- **Final decision:** Bit 0 `SOF`; bit 1 `RESERVED_ZERO`; bit 2
  `DISCONTINUITY`; bit 3 `OVERFLOW_OCCURRED`; bit 4
  `MALFORMED_PRECEDING`; bit 5 `VALID`; bit 6 `WINDOW_END` (always 0 for
  continuous G2B DMA); bits 7..31 `RESERVED_ZERO`. Header flags are per-record.
  Pending discontinuity/overflow/malformed context is sticky only until copied
  to the next committed record. FPGA configuration and every new transport
  epoch clear all three pending states after reset accounting, so old-epoch
  context never annotates a new-epoch record. No V1.0 `SOURCE_UNLOCKED`,
  `SOURCE_RECOVERED`, `RESET_BOUNDARY`, or `DROPPED_BEFORE_THIS_RECORD` bit is
  defined.
- **Rationale:** Retain evidence-supported legacy meanings. Epoch and attempt
  gaps already encode reset/drop boundaries, and MMIO exposes live source
  state, so new redundant bits are unnecessary.
- **Evidence source:** Donor meanings summarized at
  `../v41-development-g2b-one-channel-c2h-offline/G2B_RECORD_CONTRACT_RECEIPT.md:74`;
  final bit contract and clear rules at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Flags.
- **Downstream impact:** RTL writes every reserved bit as zero. V1.0 parsers
  reject nonzero reserved flags and use epoch/MMIO for concepts without a flag.

## 9. Channel identity

- **Question:** How can G2B be one-channel without freezing a one-channel-only
  wire format?
- **Previous status:** Architecture accepted logical IDs 0/1 and physical IDs
  0..3, but encoded record fields remained provisional
  (`CURRENT_INTERFACES.md:59-75`).
- **Final decision:** `logical_channel_id` is a semantic `u2` in a zero-extended
  `u32`: 0 and 1 legal, 2 reserved, 3 invalid sentinel. `physical_input_id` is
  a semantic `u3` in a zero-extended `u32`: 0..3 legal, 4..6 reserved, 7 invalid
  sentinel. `active_logical_channel_count` is 1 or 2. G2B emits logical 0,
  physical 0, count 1. A future two-channel build can emit IDs 0 and 1/count 2
  without changing ABI V1.
- **Rationale:** The namespace matches four physical inputs and at most two
  simultaneous logical channels while reserving explicit invalid encodings.
- **Evidence source:** Product architecture at
  `../v41-development-g1-integration-architecture/V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md:3-7,21-25`;
  final encoding at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Header layout and §Channel identity.
- **Downstream impact:** Host parser rejects sentinel/reserved/high-bit values.
  Capability bits, not record namespace alone, decide whether two channels are
  implemented.

## 10. Payload, line/frame association, and Linux handoff

- **Question:** What exactly are the 3,840 bytes, and how are frames rebuilt?
- **Previous status:** G1 stated UYVY from one validated active line but the
  transport ABI and Linux handoff were not frozen.
- **Final decision:** Every record holds exactly one complete 1,920-pixel active
  line of packed UYVY 4:2:2. For pair `p=0..959`, bytes are `U0,Y0,V0,Y1` at
  payload offsets `4p+0..4p+3`. SAV/EAV, blanking, checksum, timestamp,
  descriptor, and line padding are excluded. Active lines are 0..1079; line 0
  has `SOF=1`; there is no EOF flag. The host groups by card, logical channel,
  physical input, epoch, and source frame sequence, then requires exactly one
  ordered instance of lines 0..1079. Any gap, duplicate, identity change,
  source-sequence break, or discontinuity makes the frame incomplete.
- **Rationale:** One-line records match the existing validated source
  recordizer and make frame reconstruction deterministic without inferring
  boundaries from byte content.
- **Evidence source:** G1 source contract at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:38-45`
  and one-channel association at
  `../v41-development-g1-integration-architecture/V41_G1_ONE_CHANNEL_DMA_CONTRACT.md:34-46`;
  final contract at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Payload contract.
- **Downstream impact:** Linux extracts exactly bytes 64..3903 and assembles
  complete frames by metadata. UYVY transport ordering does not close `OD-07`
  or dictate the final V4L2 presentation format.

## 11. Padding

- **Question:** Are the 192 tail bytes defined, and may unwritten RAM be
  exposed?
- **Previous status:** G1 proposed zero padding, but the donor producer did not
  write the tail and the overall ABI was provisional.
- **Final decision:** Bytes 3904..4095 are exactly zero in every record. The
  formatter generates constants and must never expose stale/uninitialized RAM.
  Padding remains part of the fixed record; `TKEEP=0xFF`. The consumer verifies
  zero during structural validation and otherwise ignores it.
- **Rationale:** Deterministic bytes avoid information leakage and make golden
  records reproducible without increasing stream complexity.
- **Evidence source:** G1 proposal at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:42-47`;
  unwritten-tail risk at
  `../v41-development-g2b-one-channel-c2h-offline/V41_G2B_IMPLEMENTATION_REPORT.md:149-157`;
  final contract at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Padding contract.
- **Downstream impact:** Formatter must synthesize zero beats/bytes; parser marks
  any nonzero V1.0 padding as `CORRUPT_RECORD`.

## 12. Ring ownership

- **Question:** What exact state machine prevents partial overwrite?
- **Previous status:** G1 required a private four-record ring and complete-record
  ownership, but no G2B implementation existed.
- **Final decision:** Four channel-0 slots use
  `WRITABLE -> FILLING -> COMMITTED -> DMA_OWNED -> RELEASABLE -> WRITABLE`.
  `FILLING -> WRITABLE` is the only ordinary failure path. Allocation latches
  channel/input/attempt/epoch and increments a 24-bit slot generation. Commit is
  atomic only after 3,840 payload bytes and validation. Scheduler ownership
  locks descriptor/generation/epoch and assigns global sequence before beat 0.
  `DMA_OWNED -> RELEASABLE` occurs only on beat 511 handshake; reuse waits for a
  matching cross-domain release acknowledgement. Illegal state/transition or
  identity mismatch is fatal. Each channel's committed descriptors form a
  depth-four FIFO and the scheduler selects the oldest committed descriptor;
  within-channel reordering is forbidden. At most one shared-stream slot is
  `DMA_OWNED`; physical slot allocation order is internal. Slot generation
  resets to zero at FPGA configuration and every transport epoch, first
  allocation uses one, source reset without an epoch does not reset it, and
  wrap is modulo `2^24`. No slot borrowing or partial overwrite exists.
- **Rationale:** Explicit ownership is required because video writes and XDMA
  reads are in different domains and source input cannot be backpressured.
- **Evidence source:** G1 roles at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:23-36`;
  final state machine at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Ring ownership model.
- **Downstream impact:** RTL must prove transition legality, matching
  generation/epoch, and release CDC. Channel 1 later receives its own four
  slots and cannot borrow channel 0 storage.

## 13. Drop policy

- **Question:** What happens when all slots are full, and which sequences are
  consumed?
- **Previous status:** G1 selected whole-record drop but exact sequence
  assignment was blocked.
- **Final decision:** At an eligible attempt boundary with no `WRITABLE` slot,
  drop the complete new attempt before writing any byte or offering C2H. Preserve
  committed/in-flight/releasable data. Increment attempted, dropped, and
  ring-overflow counters once. Consume the per-channel attempt value but no
  global value. Set pending `DISCONTINUITY` and `OVERFLOW_OCCURRED` for the next
  committed record. A later malformed or aborted admitted attempt likewise
  consumes its attempt and increments dropped once; malformed also increments
  malformed accounting and sets `MALFORMED_PRECEDING`.
- **Rationale:** Never corrupt or overwrite accepted data; make every lost
  source opportunity visible and attributable.
- **Evidence source:** G1 policy at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:86-97`;
  final rule at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Drop policy.
- **Downstream impact:** Host sequence gaps remain discontinuities even when
  counters explain them. Partial drop, overwrite-oldest, and silent repair are
  prohibited.

## 14. Backpressure

- **Question:** What state may change while XDMA stalls?
- **Previous status:** Required architecturally but unimplemented and untested.
- **Final decision:** Once offered, `TVALID`, `TDATA`, `TKEEP`, and `TLAST`
  remain stable during `TVALID && !TREADY`; `TVALID` remains asserted through
  the final handshake, with no intentional intra-record bubble. Beat index
  advances only on `TVALID && TREADY`. Channel, slot, generation, epoch, header,
  and global sequence stay locked for all 512 beats. Slot release begins only
  after the beat-511 handshake.
- **Rationale:** This is the mandatory AXI ready/valid contract and preserves a
  complete record under arbitrary host stalls.
- **Evidence source:** G1 at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:74-84`;
  final contract at
  `V41_C2H_TRANSPORT_ABI_V1.md` §AXI4-Stream mapping and backpressure.
- **Downstream impact:** Backpressure simulation must compare every held signal
  on every stalled cycle and prove no early slot release.

## 15. Transport reset disposition

- **Question:** How do ownership, in-progress data, counters, and source
  production behave across reset?
- **Previous status:** G1 required flush/epoch/re-enable and R1i independence,
  but counter/sequence effects and record encoding were incomplete.
- **Final decision:** An epoch-creating reset disables admission, clears stored
  enable, flushes descriptors and all non-writable ownership after an explicit
  CDC epoch handshake, resets transport sequences to next value 0, invalidates
  snapshots, abandons committed/DMA-owned records, drops an aborted `FILLING`
  attempt, and resumes only at beat 0 after host re-enable. Source sequences
  continue when the source itself is not reset while transport is reset;
  non-admitted lines consume no transport attempt number. FPGA configuration
  and PCIe/AXI hard reset clear MMIO transport counters and sticky errors; an
  accepted host stream-state reset retains them while applying the defined
  drop/abandon/reset-event increments. Source reset or disable retains epoch,
  transport sequences, MMIO transport statistics, and MMIO errors, but resets
  the source-local header counters/sequences per §3/§6, drops readiness/lock,
  and sets discontinuity context. NVP/I2C is independent.
- **Rationale:** A reset cannot expose a record suffix or stale descriptor and
  must not replay the qualified autonomous NVP initialization lifecycle.
- **Evidence source:** G1 reset hierarchy at
  `../v41-development-g1-integration-architecture/V41_G1_CLOCK_RESET_CDC_PLAN.md:27-35,59-65`;
  final ABI reset at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Reset epoch and reset behavior and §Ring
  ownership model; MMIO clear matrix at `V41_G2B_MMIO_CONTRACT.md` §Counter semantics.
- **Downstream impact:** Reset-order tests must prove clean epoch crossing,
  correct drop/abandon accounting, explicit re-enable, and complete R1i/NVP
  independence.

## 16. MMIO allocation and reserved range

- **Question:** Which extension addresses are final for G2B?
- **Previous status:** All `0x3800..0x3BFF` pages were
  `PROPOSED_FOR_G2`; exact registers were not accepted.
- **Final decision:** The G2B extension router exclusively claims
  `0x3800..0x3BFF`. Defined G2B words occupy `0x3800..0x3858`.
  `0x385C..0x387F` and the entire former scheduler/channel/selection space
  `0x3880..0x3BFF` are `RESERVED_ZERO`/RAZ-WI in G2B. `0x3C00..0x3FFF` is
  outside the router claim and remains future-reserved. All existing behavior
  through `0x35FF`, R1i `0x3600..0x367F`, and compatibility gap
  `0x3680..0x37FF` is immutable.
- **Rationale:** Freeze only registers required by one-channel G2B and prevent
  inactive channel/scheduler proposals from being advertised.
- **Evidence source:** G1 proposed map at
  `../v41-development-g1-integration-architecture/V41_G1_MMIO_MAP_PLAN.md:3-10,12-100`;
  blocker at
  `../v41-development-g2b-one-channel-c2h-offline/G2B_MMIO_DELTA.md:38-70`;
  final allocation at
  `V41_G2B_MMIO_CONTRACT.md` §Compatibility and decode rules, §Register map,
  and §Reserved and future behavior.
- **Downstream impact:** Decode/no-alias tests cover the full 128 KiB aperture.
  Reserved reads return zero and writes have no effect; legacy response timing
  cannot gain a registered stage.

## 17. MMIO control register

- **Question:** What are the exact control bits, access types, reset values, and
  legal transitions?
- **Previous status:** Global control/reset/write semantics were unspecified.
- **Final decision:** `CONTROL` is at `0x380C`, reset `0`:

  | Bit | Name | Access | Frozen effect |
  |---:|---|---|---|
  | 0 | `ENABLE_C2H` | RW | Stored desired enable; 0 stops new admission and drains committed/in-flight records. |
  | 1 | `RESET_C2H_STATS` | W1S, reads 0 | Accepted only disabled, inactive, ring-empty, and with both reset/snapshot BUSY zero; atomically clears MMIO statistics/snapshot/last-sequence-valid state but not epoch, ownership, sticky errors, or record-header source lifetime counters. A command during a pending reset/snapshot is rejected without canceling or altering it. |
  | 2 | `RESET_STREAM_STATE` | W1S, reads 0 | Legal always; clears enable, performs flush/epoch/sequence reset and CDC acknowledgement. |
  | 31:3 | `RESERVED_ZERO` | RAZ/WI | No effect. |

  Enable admits only when source ready+locked, reset not busy, no fatal error,
  and a slot is writable. Stream reset dominates a simultaneous enable. An
  illegal statistics reset is ignored and latches fatal `TRANSPORT_ERROR` with
  cause `STATS_RESET_REJECTED`. Requiring `SNAPSHOT_BUSY=0` preserves the G1
  exclusion rule and prevents a pre-clear snapshot acknowledgement from
  republishing stale values after a counter clear.
  Enable uses a stable-data AXI-to-source request/ack mailbox and its AXI write
  completes only after the admission gate is applied. An accepted statistics
  reset holds `BVALID` until every counter-domain clear acknowledgement and
  atomic shadow clear complete. Stream-reset and snapshot writes complete at
  launch and expose completion through BUSY/VALID. If both reset commands are
  accepted, statistics clear occurs first and stream accounting second, ending
  with `RESET_EVENTS=1`; repeated stream resets while busy coalesce. If stats
  reset is illegal in a combined write, the reject latches first and the same
  stream-reset completion qualifies its later fatal W1C.
  A standalone non-hard reset arriving during an accepted statistics clear is
  serialized after the clear; hard reset dominates and may abort the write.
- **Rationale:** Three controls are sufficient for one-channel implementation;
  W1S commands avoid persistent command state and legality rules prevent torn
  counter resets.
- **Evidence source:** Final bit and transition contract at
  `V41_G2B_MMIO_CONTRACT.md` §Control register.
- **Downstream impact:** Host must disable/drain before statistics reset and
  follow stream-reset recovery before clearing fatal errors. Unsupported bits
  cannot become latent controls.

## 18. MMIO status register

- **Question:** Which live/sticky states can G2B actually expose?
- **Previous status:** Global/channel state bit encodings were unspecified.
- **Final decision:** `STATUS` is at `0x3810`, reset `0x00000004`:

  | Bit | Name | Kind |
  |---:|---|---|
  | 0 | `C2H_ENABLED` | stored-enable live readback |
  | 1 | `C2H_ACTIVE` | live filling/committed/DMA-owned/releasable/AXIS activity |
  | 2 | `RING_EMPTY` | live; reset 1 |
  | 3 | `RING_FULL` | live |
  | 4 | `OVERFLOW_SEEN` | sticky alias of error bit 0 |
  | 5 | `DROP_SEEN` | sticky alias of error bit 1 |
  | 6 | `SOURCE_READY` | synchronized live initialization/frontend readiness |
  | 7 | `SOURCE_LOCKED` | synchronized validated-line lock |
  | 8 | `STREAM_RESET_BUSY` | live |
  | 9 | `SNAPSHOT_BUSY` | live |
  | 10 | `SNAPSHOT_VALID` | live |
  | 11 | `FATAL_ERROR` | OR of fatal error bits 3..5 |
  | 31:12 | `RESERVED_ZERO` | constant 0 |

- **Rationale:** Every bit derives from an implementable ring, formatter,
  source synchronizer, snapshot, or sticky-error state; no speculative status
  is advertised.
- **Evidence source:** `V41_G2B_MMIO_CONTRACT.md` §Status register.
- **Downstream impact:** Host uses enable and active separately, waits on reset
  and snapshot state, and does not infer source lock from NVP/I2C telemetry.

## 19. Capability model

- **Question:** How are architectural support and current-build implementation
  separated?
- **Previous status:** Capability encoding was unspecified, risking advertising
  unimplemented two-channel functionality.
- **Final decision:** `CAPABILITIES` at `0x3808` is exactly `0x000B001F` for a
  conforming completed G2B build. Bits 0..4 are respectively
  `C2H_SUPPORTED`, `RECORD_ABI_V1_SUPPORTED`, `ONE_CHANNEL_SUPPORTED`,
  `TWO_CHANNEL_ABI_CAPABLE`, and `GEN2_CAPABLE`. Bits 16,17,18,19 are
  `C2H_IMPLEMENTED_THIS_BUILD=1`,
  `ONE_CHANNEL_IMPLEMENTED_THIS_BUILD=1`,
  `TWO_CHANNEL_IMPLEMENTED_THIS_BUILD=0`, and
  `GEN2_CONFIGURED_THIS_BUILD=1`. Bits 15:5 and 31:20 are zero.
- **Rationale:** ABI namespace support is not implementation. The exact split
  permits V1 to remain two-channel-capable without claiming channel-1 RTL.
- **Evidence source:** `V41_G2B_MMIO_CONTRACT.md` §Capability register.
- **Downstream impact:** Host activation is gated by bits 16..19, especially
  bit 18. This architecture-only package itself does not claim that the
  constant exists in the unchanged G2A build.

## 20. Counters and last-sequence registers

- **Question:** What counters are exposed, at which widths/addresses, and when
  do they increment or clear?
- **Previous status:** G1 listed desired counters but the final address,
  increment, width, clear, and coherent-read contract was not frozen.
- **Final decision:** Snapshot registers are:

  | Address | Field | Width | Owner clock domain | Increment/update event |
  |---:|---|---:|---|---|
  | `0x3814` | `RECORDS_ATTEMPTED` | 32 | source/video | Same eligible active-line decision that assigns the attempt sequence, before final validation |
  | `0x3818` | `RECORDS_COMMITTED` | 32 | source/video | Atomic `FILLING -> COMMITTED` |
  | `0x381C` | `RECORDS_STREAMED` | 32 | `axi_aclk` | Beat-511 final handshake |
  | `0x3820` | `RECORDS_DROPPED` | 32 | source/video | Each consumed attempt that does not commit |
  | `0x3824` | `OVERFLOW_COUNT` | 32 | source/video | Ring-full dropped-attempt subset |
  | `0x3828` | `SEQUENCE_DISCONTINUITIES` | 32 | `axi_aclk` | Once per streamed record revealing a same-epoch gap against the prior streamed attempt for that same logical channel; independent baseline per channel |
  | `0x382C/0x3830` | `BEATS_STREAMED` | 64 | `axi_aclk` | Every accepted C2H beat |
  | `0x3834` | `LAST_GLOBAL_STREAM_SEQUENCE` | 32 | `axi_aclk` | Final handshake of a complete record |
  | `0x3850` | `RECORDS_ABANDONED` | 32 | `axi_aclk` reset/ownership manager | Each committed/DMA-owned record reset-discarded before completion |
  | `0x3854` | `RESET_EVENTS` | 32 | `axi_aclk` epoch manager | Each post-configuration epoch advance |
  | `0x3858` | `LAST_CHANNEL_ATTEMPT_SEQUENCE` | 32 | `axi_aclk` | Final handshake of a complete record |

  All 32-bit counters wrap modulo `2^32`; beats wrap modulo `2^64`; none
  saturate. Last-sequence registers read `0xFFFFFFFF` while their separate valid
  bit is clear. FPGA configuration/hard reset clears counters. Accepted
  statistics reset clears them without changing epoch/live generators or
  sticky errors. Stream reset retains statistics and applies defined
  drop/abandon/reset-event increments. Counters are owned by the domain that
  generates their event.
- **Rationale:** Events map directly to the ownership/AXIS state transitions
  and allow host reconciliation without ambiguous saturation.
- **Evidence source:** G1 counter intent at
  `../v41-development-g1-integration-architecture/V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md:101-114`;
  final map and semantics at
  `V41_G2B_MMIO_CONTRACT.md` §Register map and §Counter semantics.
- **Downstream impact:** RTL and host use the same increment events and modulo
  arithmetic. A missing-number count is not inferred from the discontinuity
  event count.

## 21. Error model

- **Question:** Which error bits are sticky, fatal, and clearable?
- **Previous status:** Sticky error causes and reject semantics were
  unspecified.
- **Final decision:** `ERROR_STATUS` at `0x383C`, reset 0, is RW1C:

  | Bit | Name | Severity | Clear rule |
  |---:|---|---|---|
  | 0 | `RING_OVERFLOW` | nonfatal | W1C any time or hard reset |
  | 1 | `RECORD_DROP` | nonfatal | W1C any time or hard reset |
  | 2 | `SEQUENCE_DISCONTINUITY` | nonfatal | W1C any time or hard reset |
  | 3 | `FORMATTER_INTERNAL_ERROR` | fatal | W1C only disabled/inactive/ring-empty after stream reset, or hard reset |
  | 4 | `ILLEGAL_OWNERSHIP_STATE` | fatal | same fatal-clear rule |
  | 5 | `TRANSPORT_ERROR` | fatal | same fatal-clear rule |
  | 31:6 | `RESERVED_ZERO` | n/a | writes ignored |

  For every defined bit, a same-cycle new error set wins over an otherwise
  legal W1C. Fatal errors stop admission, clear enable, allow only an
  integrity-valid current record to finish, and require stream-reset recovery.
  `LAST_ERROR_CAUSE` at `0x3840` uses values
  0 `NONE`, 1..6 corresponding to the six bits, and 7
  `STATS_RESET_REJECTED`, with deterministic priority as frozen in the MMIO
  contract; specific `RING_OVERFLOW` outranks generic `RECORD_DROP` when both
  arise from one ring-full loss. Non-AXI errors cross through source sticky
  request latches and acknowledged two-flop handshakes, never raw pulses. A new
  error coincident with statistics-clear wins for `LAST_ERROR_CAUSE`; hard
  reset dominates.
- **Rationale:** Ordinary defined loss stays nonfatal and observable; internal,
  ownership, and transport integrity faults cannot be cleared into unsafe
  state.
- **Evidence source:** `V41_G2B_MMIO_CONTRACT.md` §Error model.
- **Downstream impact:** Host clears only intended bits and must perform the
  required fatal recovery sequence. Tests inject each cause and verify clear
  legality and priority.

## 22. Read coherency and snapshot protocol

- **Question:** How can software read multi-domain and 64-bit counters without
  torn values?
- **Previous status:** G1 required coherent snapshots, but command/status and
  exact CDC behavior were not final.
- **Final decision:** `SNAPSHOT_COMMAND` `0x3844` bit 0 `CAPTURE` is W1S.
  `SNAPSHOT_STATUS` `0x3848` bits 0..3 are `BUSY`, `VALID`,
  `LAST_GLOBAL_VALID`, and `LAST_CHANNEL_VALID`; remaining bits are zero.
  `SNAPSHOT_GENERATION` `0x384C` increments modulo `2^32` only when a full
  snapshot becomes valid. First success after configuration, hard reset, or
  statistics reset is 1; stream reset retains generation. Capture is accepted
  only when both snapshot and stream-reset BUSY are zero. Stream reset
  invalidates a pending token/epoch, clears BUSY, and ignores late stale acks.
  Source-owned binary counters are registered, Gray-encoded, two-flop
  synchronized, and captured through an explicit request/acknowledge hold
  handshake. All shadows become stable as one generation; 64-bit halves may be
  read in either order. `RESET_EPOCH` remains live, so host reads epoch,
  snapshots, reads shadows, rereads epoch, and retries if epoch changed or
  snapshot valid cleared.
- **Rationale:** Explicit acknowledgement provides CDC-safe atomicity; the
  epoch sandwich prevents combining counters across a reset.
- **Evidence source:** G1 CDC requirement at
  `../v41-development-g1-integration-architecture/V41_G1_CLOCK_RESET_CDC_PLAN.md:37-50`;
  final protocol at
  `V41_G2B_MMIO_CONTRACT.md` §Snapshot and read coherency.
- **Downstream impact:** No atomic-low/high folklore or unsynchronized live
  counter reads are permitted. Host tooling always uses the snapshot sequence.

## 23. Host parser classifications

- **Question:** What must Linux/userspace classify at a record boundary?
- **Previous status:** G1 required a validator but no complete frozen parser
  contract existed.
- **Final decision:** `VALID_RECORD` requires exact size/boundary, magic,
  version, length, IDs, reserved fields, flags, line/SOF agreement, zero
  padding, and `VALID=1`. `CORRUPT_RECORD` is any structural failure; parser
  stops the session and never scans for a later magic. Every session start must
  first negotiate while disabled, issue/wait for `RESET_STREAM_STATE`, record
  the armed epoch, legally clear fatal errors, and explicitly enable; mid-epoch
  attach is forbidden. `NEW_EPOCH` is the first valid post-reset session record
  or an observed epoch change; discard partial frames, clear
  continuity baselines, and require first observed global value 0.
  `DISCONTINUITY` is a valid record with the flag, same-epoch sequence gap,
  source progression break, mapping change, or MMIO loss delta; it invalidates
  the affected frame but is not itself corruption. Parser also validates MMIO
  identity/ABI before enable and extracts only bytes 64..3903.
- **Rationale:** Fixed-boundary fail-stop parsing prevents false resynchronizing
  on payload bytes and separates integrity corruption from explained loss.
- **Evidence source:** G1 host architecture at
  `../v41-development-g1-integration-architecture/V41_G1_HOST_DMA_TEST_ARCHITECTURE.md:9-27`;
  final classifications at
  `V41_C2H_TRANSPORT_ABI_V1.md` §Host session-start rule and §Host record
  classifications and the dedicated
  `V41_C2H_LINUX_CONSUMER_CONTRACT.md`.
- **Downstream impact:** Future Linux work has a transport-facing input without
  prematurely designing V4L2 policy, timestamps, identity persistence, or
  buffer APIs.

## 24. Forward compatibility

- **Question:** What may an older parser accept from future versions?
- **Previous status:** No final major/minor, reserved-field, or header-expansion
  rule existed.
- **Final decision:** MMIO major mismatch is unsupported and host must not
  enable. Record-version mismatch is unsupported unless a later negotiated ABI
  explicitly declares compatibility. At MMIO 1.0, every reserved bit/subfield
  must be zero or the record is corrupt. A newer major-1 minor may retain record
  version `0x00004101` only if the complete 64-byte layout, fixed geometry, all
  mandatory fields, and semantics remain backward-compatible. When such a
  newer minor is negotiated, an older major-1 parser ignores unknown flag bits
  or newly defined reserved-subfield values while enforcing known fields. With
  minor 0 it must not ignore them. Header expansion/movement, payload offset or
  record-size change, or mandatory semantic change requires a new major and
  record version. Padding is never an extension area.
- **Rationale:** Strict V1.0 validation detects corruption while negotiated
  minor evolution permits additive meanings without silently changing bytes.
- **Evidence source:** `V41_C2H_TRANSPORT_ABI_V1.md` §Forward compatibility and
  MMIO reserved rules at `V41_G2B_MMIO_CONTRACT.md` §Reserved and future behavior.
- **Downstream impact:** JSON schema, parser, golden vectors, and capability
  negotiation implement identical major/minor behavior; implementers cannot
  appropriate reserved space without a versioned contract change.

## Closure matrix

| Previously open item | Final status | Primary frozen artifact |
|---|---|---|
| Offset `0x38` semantics | FROZEN | ABI §Per-channel attempt sequence |
| Offset `0x3C` semantics | FROZEN | ABI §Global stream sequence |
| Reset epoch | FROZEN | ABI §Reset epoch and reset behavior |
| Sequence reset/wrap/drop behavior | FROZEN | ABI §Transport sequences |
| Build identity | FROZEN, MMIO-only | ABI §Firmware/build identity |
| Flags | FROZEN | ABI §Flags |
| Channel identity | FROZEN | ABI §Channel identity |
| Payload/frame reconstruction | FROZEN | ABI §Payload contract |
| Padding | FROZEN | ABI §Padding contract |
| Ownership/drop/backpressure/reset | FROZEN | ABI ownership/drop/AXIS/reset sections |
| MMIO base/range | FROZEN | MMIO §Compatibility and decode rules and §Register map |
| Control/status | FROZEN | MMIO §Control register and §Status register |
| Counters/capabilities/errors | FROZEN | MMIO capability/counter/error sections |
| Read coherency | FROZEN | MMIO §Snapshot and read coherency |
| Forward compatibility | FROZEN | ABI §Forward compatibility |

Every mandatory G2B transport and MMIO decision is fixed. This closure does not
implement G2B and does not close SSOT decisions `OD-07` through `OD-10`.
