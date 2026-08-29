# AHD v41 G2B-PRE — Final C2H Transport ABI and MMIO Freeze

## 1. Executive result

Engineering gate: **PASS**.

`CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B`

`G2B_MMIO_STATUS = FROZEN`

The task converts the accepted G1/G2B concepts into two complete,
implementation-facing contracts without implementing them:

1. `AHD_C2H_TRANSPORT_ABI_V1`, numeric version 1; and
2. the AHD v41 G2B MMIO contract at `0x3800..0x3BFF`.

Every blocker reported by the preceding one-channel G2B attempt has a final
answer. There is no mandatory `TBD`, no unassigned header byte, and no MMIO
register whose implemented G2B behavior is left for an RTL or host agent to
choose. The machine-readable representations and static consistency checks
are part of this package.

This is an architecture/contract freeze only. No FPGA source, RTL, XCI, XDC,
Vivado project, host driver, G2B branch, R1i content, R-track content, HDMI
project, or `project-current-state/` file was modified. Vivado, synthesis,
implementation, hardware discovery, DUT access, FPGA programming, and DMA
were not run.

## 2. Authority and start state

| Item | Verified value |
|---|---|
| Source repository | `lukaszsudul/FPGA_AHD` |
| Accepted product base branch | `integration/v41-r1i-gen2-g2a` |
| Accepted base commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Accepted base tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Accepted base parent | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Previous G2B branch | `integration/v41-g2b-onech-c2h` |
| Previous G2B branch head | exact accepted base commit; no implementation commit |
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Evidence main at inspection start | `c9a12188714fbf3a5dd271052143370d3b32ba87` |
| `PROJECT_STATE_REV_AT_START` | `1` |

The required G1 architecture, accepted G2A build, blocked G2B attempt, and
complete revision-1 `project-current-state/` inputs were inspected read-only.
`G2B_PRE_EVIDENCE_INDEX.md` binds the exact path commits and source files.

## 3. Direct blocker closure

| Prior blocker | Final decision |
|---|---|
| Header `0x38` | `channel_attempt_sequence`, unsigned 32-bit little-endian. The first attempt in an epoch is 0. The current value is assigned before increment at every eligible active-line attempt decision. A ring-full drop or a later malformed/aborted attempt consumes its number. Increment and comparison are modulo `2^32`. Transport epoch reset restores next value 0; source reset does not. |
| Header `0x3C` | `global_stream_sequence`, unsigned 32-bit little-endian. The first streamed record in an epoch is 0. The scheduler assigns the current value before offering beat 0 and increments it only on the beat-511 handshake. It is contiguous across both logical channels modulo `2^32` and resets to 0 on a new transport epoch. |
| Reset epoch absent | Header `0x08` is now `reset_epoch`, unsigned 32-bit little-endian, per card/shared C2H stream. Configuration creates epoch 0. Each later transport-reset episode creates exactly one new modulo-`2^32` epoch. |
| Ambiguous record build ID | There is no per-record build ID in V1. The full legacy MMIO identity tuple is authoritative. A record uses `0x08` for reset epoch. A host treats an identity change during streaming as a device-session change and re-probes before accepting more records. |
| MMIO allocation provisional | `0x3800..0x3BFF` is frozen as the G2B extension. Exact registers, bits, reset/access/clear behavior, counters, snapshot CDC, capabilities, error behavior, and all reserved space are specified. |

## 4. Frozen transport record

| Property | Frozen value |
|---|---:|
| ABI name | `AHD_C2H_TRANSPORT_ABI_V1` |
| Numeric version | `1` |
| ABI major/minor | `1.0` (`0x00010000` in MMIO) |
| Record family/version | `v41D` / `0x00004101` |
| Record bytes | 4096 |
| Header bytes | 64 |
| Payload bytes | 3840 |
| Padding bytes | 192 |
| Payload range | `64..3903` |
| Padding range | `3904..4095` |
| Header integer order | little-endian |
| AXI4-Stream | 64 bits, 512 accepted beats, eight bytes per beat |
| `TKEEP` | `0xFF` on every beat |
| `TLAST` | 1 only on beat 511 |

The 64-byte header consists of exactly sixteen named 32-bit words. The full
byte-level table, defaults, producers, consumers, flags, sequence rules,
compatibility rules, and AXI mapping are normative in
`V41_C2H_TRANSPORT_ABI_V1.md` and
`V41_C2H_TRANSPORT_ABI_V1.json`.

## 5. Payload and frame contract

Each record contains one complete validated 1920-pixel active line. Payload
byte order is the UYVY 4:2:2 tuple `U0,Y0,V0,Y1`, repeated for 960 pixel pairs
without blanking bytes or BT.656 SAV/EAV markers. Record payload order is
source left-to-right order; 64-bit AXI packing never reverses bytes.

`source_line_sequence=0` and `SOF=1` identify the first active line of a
source frame. Host reconstruction groups by physical input and source frame
sequence, places records by line sequence, and regards a 1080p frame as
complete only when lines `0..1079` occur exactly once. A missing line, attempt
gap, discontinuity flag, or epoch change makes the affected frame incomplete.
There is no V1 end-of-frame flag; `WINDOW_END` retains its donor capture-window
meaning and is zero in continuous G2B DMA mode.

The formatter generates every padding byte as zero. Padding is transported as
the final 24 full beats, remains part of the 4096-byte record, and is ignored
by the consumer after it verifies zero. Uninitialized RAM content may never
appear there.

## 6. Ownership, loss, and backpressure

The one-channel G2B ring has four private 4096-byte slots. Each slot follows
only this ownership cycle:

`WRITABLE -> FILLING -> COMMITTED -> DMA_OWNED -> RELEASABLE -> WRITABLE`.

A malformed/aborted `FILLING` slot returns to `WRITABLE` without commit. A
commit is atomic only after complete payload validation, all header fields,
and the deterministic-padding obligation are established. A committed slot is
immutable. `DMA_OWNED` begins when the AXI-domain scheduler accepts its exact
channel/slot/generation/epoch descriptor. `RELEASABLE` begins only after the
final-beat handshake and returns to `WRITABLE` only after the synchronized
release acknowledgement.

Committed descriptors are FIFO-ordered per logical channel; the scheduler
always selects that channel's oldest committed record. At most one slot across
the shared stream is `DMA_OWNED`, so the next global sequence is not assigned
until the prior record's final handshake. Slot generation resets to zero on
configuration/new epoch and wraps modulo `2^24`; source reset alone does not
reset it.

When all slots are unavailable, the complete next eligible record is dropped
before any byte is written. Committed data is preserved, no oldest-record
overwrite occurs, the attempt/drop/overflow counters increment, and the next
committed record carries discontinuity and overflow context. Dropped attempts
consume channel sequence values; global sequence values are consumed only by
complete streamed records.

During `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain
stable. Beat, address, and prefetch state advance only on
`TVALID && TREADY`. Slot release occurs only after the beat-511 handshake. No
partial overwrite, partial drop, beat interleave, or backpressure-dependent
data change is permitted.

## 7. Reset contract

FPGA configuration creates reset epoch 0, initializes both next transport
sequences to 0, clears the ring and transport statistics, and leaves C2H
disabled. The initial PCIe/user-reset release associated with configuration is
part of epoch 0. Every later PCIe/`axi_aresetn` reset episode, host
`RESET_STREAM_STATE`, or standalone C2H formatter reset performs one full
stream reset and increments the shared epoch exactly once when reset
coordination completes. Overlapping causes coalesce.

The epoch owner is an `axi_aclk` transport-reset coordinator initialized only
by FPGA configuration and deliberately not reset by `axi_aresetn`; later AXI
reset release is an increment event. It is independent of R1i/NVP/I2C state.

A full stream reset disables admission, flushes descriptor and scheduler
state, abandons committed/in-flight records, aborts a `FILLING` attempt,
restores slot ownership only through the cross-domain reset handshake, resets
both next transport sequences to 0, and invalidates the MMIO snapshot. The
first later output begins at beat 0 of a new complete record. Host-controlled
and standalone C2H stream reset retain statistics while applying defined
drop/abandon/reset-event accounting; PCIe/user hard reset clears statistics.
All old-epoch pending header annotations are cleared after reset accounting.

Ordinary enable/disable and source/NVP reset or loss do not create a transport
epoch. A defined source reset/disable-reenable/remap resets the source-local
frame/capture sequences, aborts only an affected uncommitted attempt, preserves
transport sequence state, and causes discontinuity context on the next record;
source loss without reset does not reset source-local sequences.
PCIe/application transport reset never starts, gates, pulses, or replays NVP
or I2C initialization. If the source continues during transport reset, its
bytes are ignored for admission until the epoch handshake completes and the
host re-enables C2H.

## 8. Frozen MMIO contract

The final G2B MMIO base is `0x3800`; the claimed extension ends at `0x3BFF`.
The router must claim that range before legacy forwarding. All behavior
through `0x37FF`, including tied-zero `0x00C0..0x00E0`, the legacy capture
space, the R1i page, and the `0x3680..0x37FF` compatibility gap, remains
byte- and timing-compatible. `0x3C00..0x3FFF` remains future-reserved.

The implemented word set is compact and complete:

- identity/version/capabilities at `0x3800..0x3808`;
- control and live status at `0x380C..0x3810`;
- coherent snapshot counters at `0x3814..0x3834` and `0x3850..0x3858`;
- live reset epoch at `0x3838`;
- sticky errors and last cause at `0x383C..0x3840`; and
- snapshot command/status/generation at `0x3844..0x384C`.

All remaining words through `0x3BFF` are `RESERVED_ZERO`/read-as-zero,
write-ignored. The exact register and bit table is in
`V41_G2B_MMIO_CONTRACT.md` and `V41_G2B_MMIO_MAP.csv`.

Capabilities read `0x000B001F` in a conforming one-channel G2B build. ABI and
architectural capability bits are distinct from implemented-this-build bits.
The two-channel ABI-capable bit is set; the two-channel-implemented bit is
zero. Gen2 configured means build configuration, not proof of negotiated
runtime link speed.

## 9. Counters and coherency

Record/event counters are wrapping unsigned 32-bit values. `beats_streamed`
is wrapping unsigned 64-bit. Source-domain counters cross as source-registered
Gray values through two synchronizer stages. Software explicitly requests a
request/ack snapshot; the returned shadow words remain stable until the next
successful snapshot or clear. The two beat-counter halves may be read in any
order. Software reads reset epoch before and after a snapshot transaction and
retries if it changed.

Statistics reset is accepted only with both `STREAM_RESET_BUSY=0` and
`SNAPSHOT_BUSY=0`, and its AXI write completes only after acknowledged
all-domain clear, so a counter clear cannot race reset/snapshot accounting.
Enable/disable writes likewise complete only after the source admission gate
is applied. Every sticky error uses
set-wins-clear priority if a new event coincides with an otherwise legal W1C.

The required counter events are final: attempt allocation, atomic commit,
beat-511 stream completion, consumed attempt without commit, ring-full
overflow subset, observed same-epoch attempt gap, every accepted beat,
reset-abandoned committed/in-flight records, and epoch-creating reset events.
The MMIO contract fixes clear and reset behavior for each.

## 10. Error model

`ERROR_STATUS` freezes bits for ring overflow, record drop, sequence
discontinuity, formatter internal error, illegal ownership state, and
transport error. The first three are sticky nonfatal indications. The last
three are sticky fatal indications: they stop new admission and block the next
record while allowing an integrity-valid in-flight record to finish. Fatal
recovery is `RESET_STREAM_STATE`, followed by W1C clearing while disabled,
inactive, and empty. W1C never clears the corresponding counters.

## 11. Linux/host handoff

The transport-facing Linux consumer contract is complete without designing a
V4L2 driver. A consumer binds the C2H node to the discovered user MMIO BAR,
reads legacy full build identity plus the G2B capability/version words,
starts every capture session with a mandatory `RESET_STREAM_STATE` handshake
(mid-epoch attach is forbidden), validates fixed 4096-byte boundaries, rejects
corruption without scanning for magic, tracks reset epoch and both sequences,
verifies zero padding, and extracts exactly 3840 UYVY bytes.

The four normative parser outcomes are `VALID_RECORD`, `CORRUPT_RECORD`,
`DISCONTINUITY`, and `NEW_EPOCH`. Persistent card naming, final V4L2 pixel
format enumeration, timestamping, queue/DMABUF design, incomplete-frame
delivery policy, and multi-card policy remain outside this transport ABI and
remain future L-track decisions.

## 12. Static consistency and integrity

`G2B_PRE_ABI_CONSISTENCY_REPORT.md` records the automated result for:

- exact 64-byte header coverage with no overlap or unnamed gap;
- payload/padding/record endpoints and byte totals;
- `512 x 8 = 4096` AXI geometry;
- ABI JSON and MMIO CSV parsing;
- required field, flag, counter, and register presence;
- aligned, unique MMIO addresses in `0x3800..0x3BFF`;
- no overlap with immutable `0x0000..0x37FF`; and
- reserved-region coverage.

ABI consistency: **PASS** (`63/63` automated checks).

## 13. Acceptance matrix

| Criterion | Result |
|---|---|
| Named/versioned transport ABI | PASS |
| Header complete; no mandatory field TBD | PASS |
| `0x38` / `0x3C` exact semantics | PASS |
| Sequence/reset epoch/build identity | PASS |
| Flags/channel/payload/padding | PASS |
| Ring ownership/drop/backpressure/reset | PASS |
| MMIO control/status/counters/capabilities/errors | PASS |
| CDC-safe read coherency | PASS |
| Linux consumer contract | PASS |
| Machine-readable ABI/MMIO | PASS |
| Static consistency | PASS |
| Source repository unchanged | PASS |
| G2B branch unchanged | PASS |
| SSOT unchanged | PASS |
| Vivado/hardware/DMA not run | PASS |
| Evidence publication/read-back | PASS |

## 14. SSOT boundary

Revision-1 SSOT was read-only and remains authoritative until a separate META
update. `G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md` specifies the exact revision-2
interface transaction, including lifecycle-schema handling: keys named
`status` become `FROZEN`, while the domain-specific value is
`current_transport_abi_status = FROZEN_FOR_G2B`. No application C2H
implementation, G2B qualification, two-channel implementation, or V4L2
implementation is promoted by this freeze.

## 15. Publication and final stop

Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`

Evidence directory: `v41-development-g2b-pre-c2h-abi-mmio-freeze`

Evidence publication: **PASS**

Payload commit: `9fdcca4e3a40b931f07db01ad404b4a3cfc24b10`

Remote read-back: **PASS** — remote `main` resolved to the payload commit and
its tree matched exactly before this evidence-only closure. The exact final
closure commit is the remote HEAD containing this report and is supplied by
the final remote read-back and task response, avoiding impossible Git
self-reference.

Recommended next step: META update of transport ABI and MMIO, then G2B
implementation from the unchanged accepted G2A base.

`HARD STOP AFTER G2B-PRE ARCHITECTURE FREEZE`
