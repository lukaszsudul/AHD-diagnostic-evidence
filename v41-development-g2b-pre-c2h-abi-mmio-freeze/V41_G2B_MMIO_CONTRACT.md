# AHD v41 G2B MMIO Contract

`G2B_MMIO_STATUS = FROZEN`

Contract name: `AHD_V41_G2B_MMIO_V1`

Contract version: `1.0` (`0x00010000`)

Register byte order: little-endian

Register access width: 32 bits

Implemented extension window for a conforming G2B build: `0x3800..0x3BFF`

This document freezes the MMIO interface that a later G2B implementation must
implement. It does not claim that the accepted G2A source already contains
these registers. The accepted G2A image has no G2B MMIO implementation.

## 1. Compatibility and decode rules

| Range | Frozen disposition |
|---:|---|
| `0x0000..0x35FF` | Immutable legacy identity, PIO, capture, and diagnostic behavior. |
| `0x3600..0x367F` | Immutable R1i read-only telemetry page, including its read-service timing. |
| `0x3680..0x37FF` | Immutable reserved compatibility gap. Reads and writes retain the accepted-base behavior. |
| `0x3800..0x3BFF` | G2B extension window defined by this contract. The extension router claims this range before legacy forwarding. |
| `0x3C00..0x3FFF` | Reserved for a future versioned product extension; not claimed by G2B. |
| Other addresses in the 128 KiB user aperture | Retain accepted-base behavior. |

The extension router must perform a full-address comparison. A request in
`0x3800..0x3BFF` must not be forwarded to the legacy target. Every request
outside that range must follow the accepted legacy/R1i path without a new
registered stage or any change in value, side effect, byte-enable behavior,
ordering, or response latency.

The following rules apply inside the G2B extension window:

- Registers are aligned 32-bit little-endian words.
- An aligned read of an unspecified or reserved word returns `0x00000000`.
- An unaligned read returns `0x00000000`.
- An unspecified, reserved, or unaligned write has no effect.
- AXI read and write responses are `OKAY`, including reserved and unaligned
  accesses.
- RW, W1S, and RW1C fields honor AXI byte strobes. A bit is acted upon only if
  the byte containing it is strobed.
- Reserved bits read zero and ignore writes.
- Only one AXI-Lite request is processed at a time and no command queue exists,
  matching the accepted host bridge.

AXI-Lite write-response timing is part of the contract. An `ENABLE_C2H` write
returns `BVALID` only after the desired admission gate is acknowledged as
applied in the source domain. An accepted `RESET_C2H_STATS` returns `BVALID`
only after its all-domain clear completes. `RESET_STREAM_STATE` and accepted
`SNAPSHOT_COMMAND.CAPTURE` return `BVALID` after the command is latched and the
corresponding BUSY state is asserted; software polls BUSY/VALID for operation
completion. An ignored/rejected command returns after that decision and its
defined error side effect is latched. RW1C writes return after AXI-domain clear
processing. Across a PCIe posted-write bridge, software performs an ordering
read of the relevant status/control page before relying on these effects.

## 2. Register map

| Address | Name | Access | Reset | Meaning |
|---:|---|:---:|---:|---|
| `0x3800` | `C2H_MAGIC` | RO | `0x43324831` | ASCII `C2H1` capability-page identity. |
| `0x3804` | `ABI_VERSION` | RO | `0x00010000` | Contract-negotiation ABI major 1, minor 0. |
| `0x3808` | `CAPABILITIES` | RO | `0x000B001F` | Supported-versus-implemented capability split. |
| `0x380C` | `CONTROL` | mixed | `0x00000000` | Enable and two W1S reset commands. |
| `0x3810` | `STATUS` | RO | `0x00000004` | Live and sticky-alias transport status. |
| `0x3814` | `RECORDS_ATTEMPTED` | RO snapshot | `0` | 32-bit record-attempt counter. |
| `0x3818` | `RECORDS_COMMITTED` | RO snapshot | `0` | 32-bit atomic-commit counter. |
| `0x381C` | `RECORDS_STREAMED` | RO snapshot | `0` | 32-bit final-beat-completion counter. |
| `0x3820` | `RECORDS_DROPPED` | RO snapshot | `0` | 32-bit whole-record drop counter. |
| `0x3824` | `OVERFLOW_COUNT` | RO snapshot | `0` | 32-bit ring-full drop subset. |
| `0x3828` | `SEQUENCE_DISCONTINUITIES` | RO snapshot | `0` | 32-bit detected sequence-gap event counter. |
| `0x382C` | `BEATS_STREAMED_LO` | RO snapshot | `0` | Bits `[31:0]` of the 64-bit accepted-beat counter. |
| `0x3830` | `BEATS_STREAMED_HI` | RO snapshot | `0` | Bits `[63:32]` of the same snapshot. |
| `0x3834` | `LAST_GLOBAL_STREAM_SEQUENCE` | RO snapshot | `0xFFFFFFFF` | Last completely streamed global sequence. |
| `0x3838` | `RESET_EPOCH` | RO live | `0` | Current transport reset epoch. |
| `0x383C` | `ERROR_STATUS` | RW1C | `0` | Sticky error bits. |
| `0x3840` | `LAST_ERROR_CAUSE` | RO | `0` | Most recently latched error cause. |
| `0x3844` | `SNAPSHOT_COMMAND` | WO | `0` | Counter snapshot request. |
| `0x3848` | `SNAPSHOT_STATUS` | RO | `0` | Snapshot busy/valid and sequence-valid state. |
| `0x384C` | `SNAPSHOT_GENERATION` | RO | `0` | Successful-snapshot generation. |
| `0x3850` | `RECORDS_ABANDONED` | RO snapshot | `0` | Records discarded after commit by a reset. |
| `0x3854` | `RESET_EVENTS` | RO snapshot | `0` | New-epoch event counter. |
| `0x3858` | `LAST_CHANNEL_ATTEMPT_SEQUENCE` | RO snapshot | `0xFFFFFFFF` | Last completely streamed channel-attempt sequence. |
| `0x385C..0x387F` | `RESERVED_ZERO` | RAZ/WI | `0` | Reserved global-page words. |
| `0x3880..0x3BFF` | `RESERVED_ZERO` | RAZ/WI | `0` | Scheduler, channel 1, and future expansion; not implemented in G2B. |

`ABI_VERSION` and header `record_version` are different constants with
different roles. `ABI_VERSION=0x00010000` negotiates MMIO/transport contract
compatibility; each record independently carries
`record_version=0x00004101` to select the fixed v41D parser. A host validates
both.

## 3. Capability register — `0x3808`

`CAPABILITIES` is exactly `0x000B001F` in a conforming completed G2B build.
The constant describes that build; this architecture-only freeze is not itself
an implementation claim.

| Bits | Name | Value | Semantics |
|---:|---|---:|---|
| `0` | `C2H_SUPPORTED` | `1` | The product architecture supports application C2H transport. |
| `1` | `RECORD_ABI_V1_SUPPORTED` | `1` | `AHD_C2H_TRANSPORT_ABI_V1` is understood. |
| `2` | `ONE_CHANNEL_SUPPORTED` | `1` | Logical channel 0 operation is supported. |
| `3` | `TWO_CHANNEL_ABI_CAPABLE` | `1` | The record ABI can represent logical channels 0 and 1. This is not an implementation bit. |
| `4` | `GEN2_CAPABLE` | `1` | The accepted endpoint configuration is Gen2-capable. |
| `15:5` | `RESERVED_ZERO` | `0` | Reserved. |
| `16` | `C2H_IMPLEMENTED_THIS_BUILD` | `1` | The conforming G2B build contains the C2H path. |
| `17` | `ONE_CHANNEL_IMPLEMENTED_THIS_BUILD` | `1` | Logical channel 0 is implemented. |
| `18` | `TWO_CHANNEL_IMPLEMENTED_THIS_BUILD` | `0` | Two-channel scheduling/data plane is not implemented. |
| `19` | `GEN2_CONFIGURED_THIS_BUILD` | `1` | This build uses the accepted Gen2 configuration. |
| `31:20` | `RESERVED_ZERO` | `0` | Reserved. |

A host must use the `*_IMPLEMENTED_THIS_BUILD` bits to decide what it may
activate. It must not interpret `TWO_CHANNEL_ABI_CAPABLE` as an active
two-channel implementation.

## 4. Control register — `0x380C`

| Bits | Name | Access | Reset | Semantics |
|---:|---|:---:|---:|---|
| `0` | `ENABLE_C2H` | RW | `0` | Stored desired-enable state. |
| `1` | `RESET_C2H_STATS` | W1S, reads 0 | `0` | Request an atomic statistics reset. |
| `2` | `RESET_STREAM_STATE` | W1S, reads 0 | `0` | Request a transport-state reset and new epoch. |
| `31:3` | `RESERVED_ZERO` | RAZ/WI | `0` | Reserved. |

### 4.1 Enable behavior

Writing `ENABLE_C2H=1` records an enable request. New record admission is
permitted only when all of the following are true:

1. `SOURCE_READY=1`;
2. `SOURCE_LOCKED=1`;
3. `STREAM_RESET_BUSY=0`;
4. `FATAL_ERROR=0`; and
5. at least one ring slot is writable.

The stored enable bit may therefore be one while `C2H_ACTIVE` is zero and the
transport is waiting for a source or a writable slot. Writing
`ENABLE_C2H=0` stops new admissions immediately, but already committed or
integrity-valid in-flight records drain normally. It does not reset sequences,
the epoch, counters, or sticky errors.

Latching any fatal error clears `ENABLE_C2H` in hardware. Fatal clear does not
restore it; the host must explicitly write one after recovery. An existing
fatal error prevents a zero-to-one enable transition: a write of one is
ignored and the stored enable bit remains zero.

The enable value crosses from `axi_aclk` to each participating source domain
through a stable-data request/acknowledge mailbox. The stored/readback bit is
updated and the AXI write completes only after the source admission gate has
applied the value. A disable acknowledgement guarantees that no later attempt
can allocate a slot under the old enable; a `FILLING` attempt that was already
allocated may finish and drain normally. The host must then wait for
`C2H_ACTIVE=0` and `RING_EMPTY=1` before statistics reset. This acknowledged
ordering is why no separate applied-enable status bit is required.

### 4.2 Statistics reset

`RESET_C2H_STATS` is accepted only if the state sampled immediately before the
write is all of:

- `ENABLE_C2H=0`;
- `C2H_ACTIVE=0`; and
- `RING_EMPTY=1`; and
- `STREAM_RESET_BUSY=0`; and
- `SNAPSHOT_BUSY=0`.

An accepted command atomically:

- clears all numeric counters exposed at `0x3814..0x3830` and
  `0x3850..0x3854`;
- resets both last-sequence values to `0xFFFFFFFF` and clears their valid
  indicators;
- invalidates the counter snapshot;
- clears `SNAPSHOT_GENERATION` to zero; and
- clears `LAST_ERROR_CAUSE` to `NONE`.

It does not change `RESET_EPOCH`, ring ownership, live enable state, or
`ERROR_STATUS`. Sticky errors are cleared only by their defined RW1C path or a
hard reset. In particular, a statistics reset cannot bypass fatal-error
recovery.

It also does not clear the source-local lifetime counters copied into record
header offsets `0x28` and `0x2C`; those counters have the source-reset lifetime
defined by the record ABI and are not aliases of MMIO statistics.

The statistics clear is an acknowledged all-domain operation. For an accepted
command, the AXI-Lite write response (`BVALID`) is not asserted until every
participating source/formatter domain has acknowledged its counter clear and
the AXI shadow/valid/generation state has been cleared on the same logical
transaction. After the host observes write completion (and, for a posted PCIe
path, performs the normal ordering read), a new snapshot cannot observe
pre-clear counter state. No additional statistics-reset busy bit exists.

An illegal command is ignored, sets `ERROR_STATUS.TRANSPORT_ERROR`, sets
`LAST_ERROR_CAUSE=STATS_RESET_REJECTED`, and therefore invokes fatal handling.
In particular, a command issued while a snapshot is pending is rejected; it
does not clear counters, cancel the request, change snapshot generation, or
allow a later acknowledgement to publish post-clear data. The already-pending
snapshot may complete under its original generation while the rejected
statistics-reset side effect is reported independently.

### 4.3 Stream-state reset

`RESET_STREAM_STATE` is legal in every state. It:

- clears `ENABLE_C2H`;
- asserts `STREAM_RESET_BUSY` until all reset actions and CDC acknowledgements
  complete;
- stops new admissions;
- aborts any `FILLING` slot, counting its already-consumed attempt as exactly
  one dropped record;
- discards committed and DMA-owned records whose final beat has not handshaken
  as abandoned records; an already-streamed `RELEASABLE` slot is not abandoned;
- prevents publication of a partial record suffix;
- restores all four ownership slots to `WRITABLE`;
- resets per-channel and global sequence state to the ABI-defined initial
  values;
- advances `RESET_EPOCH` modulo `2^32` exactly once at reset completion;
- increments `RESET_EVENTS` exactly once;
- invalidates the snapshot and both last-sequence-valid indicators; and
- retains all other statistics and sticky errors.

A second `RESET_STREAM_STATE` write while `STREAM_RESET_BUSY=1` coalesces into
the reset already in progress. It does not create a second epoch or increment
`RESET_EVENTS` again. An overlapping standalone formatter/transport reset or
PCIe reset cause follows the same one-episode coalescing rule.

After reset completes, a fatal error remains sticky. Fatal recovery is:

1. issue `RESET_STREAM_STATE`;
2. wait for `STREAM_RESET_BUSY=0`, `C2H_ACTIVE=0`, and `RING_EMPTY=1`;
3. clear the fatal RW1C bit or bits; and
4. explicitly re-enable C2H if desired.

### 4.4 Multiple fields in one write

Command bits are sampled only from strobed byte 0. Statistics-reset legality is
evaluated against the pre-write live state. `RESET_STREAM_STATE` dominates a
simultaneous write to `ENABLE_C2H`, so the resulting enable state is zero. The
two W1S commands are otherwise processed independently. Thus, if both reset
bits are one, stream reset always executes and statistics reset executes only
when its pre-write legality condition was true; an illegal statistics reset
still produces `STATS_RESET_REJECTED`.

When both commands are present and the statistics-reset precondition is true,
the acknowledged statistics clear is logically applied first and the
stream-reset accounting is applied second. The ring-empty/inactive precondition
means no drop or abandonment is created; the final counter state is otherwise
zero with `RESET_EVENTS=1`, `RESET_EPOCH` advanced once, snapshot invalid,
snapshot generation zero, and both last-sequence values invalid. If the
statistics command is illegal, none of its clear effects occur; stream reset
still executes and the rejection cause remains sticky.

For an illegal statistics command combined with `RESET_STREAM_STATE`, the
controller evaluates and latches `STATS_RESET_REJECTED` first, then executes
the stream reset. Completion of that same stream reset satisfies the
post-fatal-reset prerequisite for this newly latched rejection, so the host may
legally W1C the retained `TRANSPORT_ERROR` afterward. Any fatal event accepted
after that reset completion requires a later stream reset before it can clear.

A standalone non-hard transport-reset cause arriving while an accepted
statistics clear is awaiting acknowledgements is latched and serviced after
the clear, using the same clear-then-stream-reset accounting order. A
PCIe/`axi_aresetn` hard reset instead dominates and may abort the outstanding
AXI transaction; hard-reset counter/error rules and the new epoch on release
then apply, and the host must reopen the session.

## 5. Status register — `0x3810`

| Bits | Name | Kind | Reset | Semantics |
|---:|---|---|---:|---|
| `0` | `C2H_ENABLED` | live | `0` | Exact readback of stored `ENABLE_C2H`. |
| `1` | `C2H_ACTIVE` | live | `0` | One or more slots are not `WRITABLE` (`FILLING`, `COMMITTED`, `DMA_OWNED`, or `RELEASABLE`), or the formatter is presenting/holding an AXIS beat. |
| `2` | `RING_EMPTY` | live | `1` | All four slots are `WRITABLE`; no filling, committed, or DMA-owned record exists. |
| `3` | `RING_FULL` | live | `0` | No slot is `WRITABLE`. A DMA-owned or filling slot counts as occupied. |
| `4` | `OVERFLOW_SEEN` | sticky alias | `0` | Alias of `ERROR_STATUS.RING_OVERFLOW`. |
| `5` | `DROP_SEEN` | sticky alias | `0` | Alias of `ERROR_STATUS.RECORD_DROP`. |
| `6` | `SOURCE_READY` | synchronized live | `0` | Source initialization and local frontend release are complete. |
| `7` | `SOURCE_LOCKED` | synchronized live | `0` | A complete source line has passed marker and length validation since the last source clear event. |
| `8` | `STREAM_RESET_BUSY` | live | `0` | A stream-state reset or its CDC acknowledgement is in progress. |
| `9` | `SNAPSHOT_BUSY` | live | `0` | A snapshot request is outstanding. |
| `10` | `SNAPSHOT_VALID` | live | `0` | Counter shadows contain a completed coherent snapshot. |
| `11` | `FATAL_ERROR` | live alias | `0` | OR of fatal `ERROR_STATUS[5:3]`. |
| `31:12` | `RESERVED_ZERO` | constant | `0` | Reserved. |

The register reset value is therefore `0x00000004`.

`SOURCE_READY` is the two-flop AXI-domain synchronization of the source-domain
condition:

```text
init_done && !init_error && local_frontend_released
```

`local_frontend_released` means the local capture frontend is out of its
source reset/disable state and is permitted to validate input lines. It does
not mean that a valid line has already been observed.

`SOURCE_LOCKED` is a source-domain state bit. It is set only after successful
validation of one complete line, including both marker and expected-length
checks. It is cleared by source reset, source disable, a marker error, or a
length error. The state is synchronized into `axi_aclk` with two flops. NVP/I2C
initialization reset behavior is not coupled to a transport reset; a transport
reset neither restarts nor clears NVP/I2C initialization.

## 6. Counter semantics

All event/record counters are unsigned 32-bit modulo counters. They wrap from
`0xFFFFFFFF` to zero. `BEATS_STREAMED` is unsigned 64-bit modulo and wraps from
`0xFFFFFFFFFFFFFFFF` to zero. No counter saturates.

| Counter | Increment event |
|---|---|
| `RECORDS_ATTEMPTED` | Once at the same eligible active-line decision that assigns `channel_attempt_sequence`, before final marker/length validation, whether or not a slot is available or the attempt later commits. |
| `RECORDS_COMMITTED` | Once at the atomic record commit that changes a complete filled slot to `COMMITTED`. |
| `RECORDS_STREAMED` | Once on the handshake of beat 511 (`TVALID && TREADY && TLAST`) for a complete record. |
| `RECORDS_DROPPED` | Once for a consumed attempt that does not commit, including a ring-full drop and a `FILLING` attempt aborted by stream reset. |
| `OVERFLOW_COUNT` | Once for the ring-full subset of dropped attempts. One rejected record is one event, regardless of stall duration. |
| `SEQUENCE_DISCONTINUITIES` | Once when a streamed record's same-epoch channel-attempt sequence is not the previous streamed value for that same logical channel plus one modulo `2^32`. Each logical channel has an independent baseline. It increments once per observed discontinuous record, not once per missing number. The first streamed record for a channel in an epoch establishes that channel's baseline and is not discontinuous. |
| `BEATS_STREAMED` | Once for every `TVALID && TREADY` C2H beat handshake. |
| `RECORDS_ABANDONED` | Once for each already committed or DMA-owned complete record discarded by a stream reset before its final-beat handshake. A `FILLING` abort is dropped, not abandoned. |
| `RESET_EVENTS` | Once for each event that advances the reset epoch. Initial FPGA configuration establishes epoch zero and is not counted. After a PCIe/AXI hard reset clears statistics, release into the new transport epoch produces value one. |

`LAST_GLOBAL_STREAM_SEQUENCE` and
`LAST_CHANNEL_ATTEMPT_SEQUENCE` update only on the final beat handshake of a
complete record. A dropped or abandoned record does not update either value.
Their internal valid states reset at every new epoch. The snapshot value is
`0xFFFFFFFF` whenever the corresponding valid bit is zero; software must use
`SNAPSHOT_STATUS[3:2]`, not the sentinel alone, as validity.

Counter clear behavior is:

| Event | Counters | Sticky errors | Snapshot | Sequence/epoch state |
|---|---|---|---|---|
| FPGA configuration | Clear | Clear | Clear; generation 0 | Epoch 0; sequences initial |
| PCIe/`axi_aresetn` hard reset | Clear | Clear | Clear; generation 0 | New epoch on release; sequences initial; `RESET_EVENTS` becomes 1 after release |
| Accepted `RESET_C2H_STATS` | Clear | Retain | Invalid; generation 0 | Epoch and live sequence generators retain state; exposed last-sequence shadows become invalid |
| `RESET_STREAM_STATE` | Retain, with defined drop/abandon/reset-event increments | Retain | Invalid | Sequences initial; epoch increments |
| Standalone C2H formatter/transport reset | Same as `RESET_STREAM_STATE`: retain prior values and apply defined drop/abandon/reset-event increments | Retain | Invalid | Sequences initial; epoch increments once |
| Source reset/disable | Retain; a consumed `FILLING` attempt aborted by the event receives its normal one dropped-record increment | Retain | Retain unless a separate stream reset occurs | Transport epoch and sequences retain state; readiness/lock fall; discontinuity becomes pending |

## 7. Error model — `0x383C` and `0x3840`

### 7.1 `ERROR_STATUS` (`0x383C`)

| Bit | Name | Sticky/live | Severity | Producer and meaning | Clear rule |
|---:|---|---|---|---|---|
| `0` | `RING_OVERFLOW` | sticky | nonfatal | Ring manager: a complete new attempt was dropped because no slot was writable. | W1C at any time; hard reset. |
| `1` | `RECORD_DROP` | sticky | nonfatal | Formatter/ring manager: one whole record attempt was dropped for any defined drop reason. | W1C at any time; hard reset. |
| `2` | `SEQUENCE_DISCONTINUITY` | sticky | nonfatal | Stream sequence checker: a same-epoch channel-attempt discontinuity was observed. | W1C at any time; hard reset. |
| `3` | `FORMATTER_INTERNAL_ERROR` | sticky | fatal | Formatter invariant or internal state error; ordinary backpressure and defined drops are not errors. | W1C only while disabled, inactive, ring empty, and after stream reset; hard reset. |
| `4` | `ILLEGAL_OWNERSHIP_STATE` | sticky | fatal | Ring manager detected an illegal ownership encoding or transition. | W1C only while disabled, inactive, ring empty, and after stream reset; hard reset. |
| `5` | `TRANSPORT_ERROR` | sticky | fatal | AXIS/transport/reset/control protocol error, including rejected statistics reset. | W1C only while disabled, inactive, ring empty, and after stream reset; hard reset. |
| `31:6` | `RESERVED_ZERO` | constant | n/a | Reserved. | Writes ignored. |

For every defined `ERROR_STATUS` bit, a same-cycle new error set wins over an
otherwise legal W1C so the event is not lost. A write of one to a fatal bit
before the fatal-clear condition is met is ignored. The fatal-clear condition
includes completion of at least one
`RESET_STREAM_STATE` issued after the most recent fatal latch. Fatal errors
stop new admission, clear `ENABLE_C2H`, allow an
integrity-valid currently presented/in-flight record to complete, and block
the next record. If record integrity cannot be guaranteed, the current record
is abandoned through stream-reset recovery rather than publishing a suffix.

An error produced outside `axi_aclk` must not cross as a raw one-cycle pulse.
Each source domain owns a sticky request latch for each applicable error class;
an event sets the latch, the request level crosses through two synchronizer
stages, the AXI domain sets its sticky `ERROR_STATUS` bit and returns an
acknowledgement, and the source latch clears only after that acknowledgement.
A new source event coincident with acknowledgement wins and starts another
request. Repeated events while the request is already held need not create
additional sticky transitions because their exact multiplicity is carried by
the defined counters. `SEQUENCE_DISCONTINUITY` and `TRANSPORT_ERROR` are
AXI-domain-local.

FPGA configuration or the hard-reset epoch handshake deliberately clears both
the AXI sticky bank and any pre-reset source request latches. A source event
accepted after that clear wins and is reported normally. Ordinary
`RESET_STREAM_STATE` retains the sticky bank and does not discard an
unacknowledged source error request.

### 7.2 `LAST_ERROR_CAUSE` (`0x3840`)

| Value | Symbol | Meaning |
|---:|---|---|
| `0` | `NONE` | No retained cause. |
| `1` | `RING_OVERFLOW` | Ring-full drop. |
| `2` | `RECORD_DROP` | Whole-record drop. |
| `3` | `SEQUENCE_DISCONTINUITY` | Sequence-gap event. |
| `4` | `FORMATTER_INTERNAL_ERROR` | Formatter fatal error. |
| `5` | `ILLEGAL_OWNERSHIP_STATE` | Ring-ownership fatal error. |
| `6` | `TRANSPORT_ERROR` | General transport fatal error. |
| `7` | `STATS_RESET_REJECTED` | Illegal `RESET_C2H_STATS`; also sets `TRANSPORT_ERROR`. |

The most recently accepted error event replaces the prior cause. When several
events latch in the same clock, deterministic priority from highest to lowest
is `STATS_RESET_REJECTED`, `TRANSPORT_ERROR`,
`ILLEGAL_OWNERSHIP_STATE`, `FORMATTER_INTERNAL_ERROR`,
`SEQUENCE_DISCONTINUITY`, `RING_OVERFLOW`, then `RECORD_DROP`.
Individual RW1C writes do not clear this register. It clears only on an
accepted statistics reset or a hard reset. If a newly accepted error event
coincides with an accepted statistics-reset clear, the new event and its cause
win; FPGA configuration or hard reset still dominates all event sets.

## 8. Snapshot and read coherency

### 8.1 Snapshot registers

`SNAPSHOT_COMMAND` (`0x3844`) has one defined bit:

| Bit | Name | Access | Semantics |
|---:|---|:---:|---|
| `0` | `CAPTURE` | W1S, reads 0 | Begin a coherent counter snapshot. |
| `31:1` | `RESERVED_ZERO` | RAZ/WI | Reserved. |

A command is accepted only when both `SNAPSHOT_BUSY=0` and
`STREAM_RESET_BUSY=0`. Otherwise it is ignored without changing generation,
validity, errors, or any outstanding request.

`SNAPSHOT_STATUS` (`0x3848`) is:

| Bit | Name | Reset | Semantics |
|---:|---|---:|---|
| `0` | `BUSY` | `0` | Request/acknowledgement and shadow capture are in progress. |
| `1` | `VALID` | `0` | All exposed counter shadows belong to the completed generation. |
| `2` | `LAST_GLOBAL_VALID` | `0` | `LAST_GLOBAL_STREAM_SEQUENCE` is valid. |
| `3` | `LAST_CHANNEL_VALID` | `0` | `LAST_CHANNEL_ATTEMPT_SEQUENCE` is valid. |
| `31:4` | `RESERVED_ZERO` | `0` | Reserved. |

`SNAPSHOT_GENERATION` (`0x384C`) increments modulo `2^32` only when a complete
snapshot becomes valid. The first successful snapshot after FPGA
configuration, PCIe/AXI hard reset, or accepted `RESET_C2H_STATS` has
generation 1. Stream reset invalidates the snapshot but retains generation;
the next successful snapshot increments the retained value. Ignored commands
do not increment it.

### 8.2 Required CDC strategy

Counters are owned by the domain that produces their increment event. Each
non-AXI-domain counter is source-registered in binary and has a registered Gray
representation. Gray values cross into `axi_aclk` through two-flop
synchronizers. The snapshot transaction adds an explicit request/acknowledge
handshake:

1. The AXI domain sets `SNAPSHOT_BUSY`, invalidates `SNAPSHOT_VALID`, and
   toggles a snapshot request into every participating source domain.
2. On observing the request, each source domain atomically captures all of its
   owned binary counters and sequence-valid state into hold registers, exposes
   their Gray-coded values, and acknowledges the request. Hold registers remain
   stable until the AXI domain completes that generation.
3. Each acknowledgement returns through a two-flop synchronizer. After all
   acknowledgements and synchronized Gray hold values are stable, the AXI
   domain decodes them and captures them together with AXI-owned counters into
   the MMIO shadow registers on one AXI clock edge.
4. The AXI domain increments `SNAPSHOT_GENERATION`, sets `VALID`, clears
   `BUSY`, and releases the source holds.

All MMIO counter shadows, including both halves of `BEATS_STREAMED`, remain
bit-stable until the next completed snapshot, statistics reset, stream reset,
or hard reset. The 64-bit halves may be read in either order.

`RESET_EPOCH` is deliberately live rather than part of the counter shadow. A
consumer obtains a reset-coherent sample as follows:

1. read `RESET_EPOCH`;
2. request and wait for a valid snapshot;
3. read the required shadow registers in any order;
4. read `RESET_EPOCH` again; and
5. retry if the two epoch values differ or if `SNAPSHOT_VALID` cleared.

A stream reset invalidates an in-progress or completed snapshot, clears
`SNAPSHOT_BUSY`, releases local holds, and marks the outstanding request token
and epoch stale, so data from two epochs cannot be presented as one valid
generation. Every acknowledgement is qualified by the captured request token
and epoch; a late acknowledgement from an invalidated request is ignored and
cannot set `VALID` or increment `SNAPSHOT_GENERATION`.

## 9. Reset epoch rules visible through MMIO

`RESET_EPOCH` is per card/per shared C2H stream, not per logical channel. It is
an unsigned modulo-`2^32` value. FPGA configuration establishes epoch zero.
Each completed transport-state reset, including a host
`RESET_STREAM_STATE`, a later PCIe/AXI transport-reset release, and a standalone
C2H transport-formatter reset, creates exactly one new epoch. A source-line
formatter/configuration reset, source reset/disable, and NVP/I2C initialization
event do not advance the transport epoch unless a separate defined
transport-state reset occurs.

The exact owner is the `axi_aclk` C2H transport-reset coordinator. Its epoch
register is initialized only by FPGA configuration and is deliberately not
cleared by `axi_aresetn`; `axi_aresetn` is an epoch-creating event input, not
the register's reset pin. A later PCIe/PERST/`axi_aresetn` episode is latched,
its release is synchronized into `axi_aclk`, and one increment occurs on that
release. The configuration-associated initial release is masked so epoch zero
is retained. Host and standalone-reset causes reach the same coordinator by
local command or acknowledged toggle and coalesce while reset is busy.
`RESET_EVENTS` is owned by this coordinator too: a hard-reset episode clears
the statistics value and its release then increments it to one. The registered
epoch is read live in the same `axi_aclk` MMIO domain and is transferred to
source/video domains only through the explicit epoch request/acknowledge
handshake. This coordinator is application transport state and has no control
path into R1i/NVP/I2C reset or initialization.

The epoch value in this MMIO register and the epoch in every record header must
be identical for a given streamed record. Software treats any change as a new
stream epoch and resets its sequence expectations.

## 10. Reserved and future behavior

`0x385C..0x387F` and `0x3880..0x3BFF` are `RESERVED_ZERO` in G2B. This includes
all formerly proposed scheduler, channel-1, selection, and detailed diagnostic
pages. They are not aliases and do not advertise inactive functionality.
Aligned and unaligned reads return zero and writes are ignored.

Future use requires a versioned contract change. It may not change the meaning
of any defined address or reserved bit under ABI major version 1. The range
`0x3C00..0x3FFF` is outside the G2B router claim and remains reserved for a
future product extension.

## 11. Host access requirements

A host must:

1. validate `C2H_MAGIC` and the supported ABI major version;
2. distinguish support from implementation using `CAPABILITIES[19:16]`;
3. never enable two-channel operation when bit 18 is zero;
4. begin every new capture session by issuing `RESET_STREAM_STATE`, waiting for
   reset completion/empty/inactive state, recording the new epoch, clearing
   any fatal errors through the legal post-reset path, and explicitly enabling;
5. use `SNAPSHOT_COMMAND`/`SNAPSHOT_STATUS` for every coherent counter read;
6. use the reset-epoch read/retry sequence for cross-reset coherency;
7. use RW1C only for the exact error bits it intends to clear;
8. perform stream-reset recovery before clearing a fatal bit; and
9. ignore reserved bits and tolerate them remaining zero.

## 12. Implementation and verification boundary

This contract freezes architecture only. No RTL, driver, Vivado project, or
hardware state is changed by it. A later G2B implementation must prove:

- exact decode ownership of `0x3800..0x3BFF`;
- no alias or behavior change through `0x37FF`;
- exact reset values and byte-strobe behavior;
- command legality and fatal recovery;
- sticky-error set-versus-clear priority;
- source readiness/lock synchronization;
- coherent snapshot behavior under counter activity and reset; and
- deterministic zero behavior for every reserved and unaligned access.
