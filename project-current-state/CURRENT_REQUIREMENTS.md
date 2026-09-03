# AHD Current Requirements

`PROJECT_STATE_REV = 6`

This document separates a frozen requirement from its implementation target
and from actual qualification. A requirement is not evidence that the product
currently meets it.

## Product requirements

| ID | Requirement | Status | Implementation target | Qualification state |
|---|---|---|---|---|
| `REQ-VIDEO-FORMAT` | Video format `1080p25` | `FROZEN` | Preserve through capture and host presentation | R1i video presence proven; end-to-end V4L2 not qualified |
| `REQ-INPUTS-CARD` | 4 physical inputs per card | `FROZEN` | Four selectable Linux/V4L2 input identities; at most two FPGA capture channels active | Only the current VDO1 path is proven; second physical ingress remains open |
| `REQ-ACTIVE-CARD` | Maximum 2 simultaneously active inputs per card | `FROZEN` | Two logical capture channels with enforced selection limit | Two-channel DMA not qualified |
| `REQ-CARDS-HOST` | Planned 2 cards per Linux host | `FROZEN` | Multi-card-capable driver/core and stable identity | Two-card hardware operation not qualified |
| `REQ-PCIE-PAYLOAD` | Sustained application payload `>= 288 MB/s` per card | `FROZEN` | Efficient 4 KiB C2H records over Gen2 x1 or better | Not yet qualified |
| `REQ-PCIE-MIN` | PCIe Gen2 x1 or better | `FROZEN` | Gen2 x1 is the minimum current target | Actual Gen2 training not qualified |
| `REQ-C2H-COUNT` | One XDMA C2H channel per card | `FROZEN` | Shared formatter/engine for up to two logical channels | Architecture accepted; application data plane not qualified |
| `REQ-LINUX-FRONTEND` | Native Linux V4L2 integration | `FROZEN` | Standard `/dev/videoX` presentation through common capture core | `PLANNED`, not implemented |
| `REQ-TRANSPORT-ABSTRACTION` | Linux capture core must be transport-independent | `FROZEN` | XDMA first backend; future LitePCIe backend possible | `PLANNED`; final backend API is open |
| `REQ-CARD-IDENTITY` | Stable card and input identity for multi-card use | `FROZEN` | Persistent mapping independent of enumeration order | Architecture decision remains open |
| `REQ-STREAM-LIMIT` | Four logical inputs/card, maximum two `STREAMON`/card | `FROZEN` | V4L2 policy enforced per physical card | `PLANNED`, not implemented |
| `REQ-PRODUCT-LUT-GATE` | Routed PRODUCT LUT utilization `<= 90%` | `FROZEN` | Preferred target band `80–85%` | Not yet measured or achieved; 84.192% is an estimate only |
| `REQ-BUILD-PROFILES` | Reversible `PRODUCT` and `RESEARCH_DIAGNOSTIC` profiles | `FROZEN` | One functional source architecture with explicit profile selection | `AUTHORIZED_NOT_IMPLEMENTED`; G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY` |

## Derived host topology

From the frozen card requirements:

- physical inputs: `4/card × 2 cards = 8 total`;
- maximum active streams: `2/card × 2 cards = 4 total`; and
- per-card concurrency limit remains 2.

This is an architectural requirement, not current two-card hardware
qualification.

## PCIe throughput interpretation

The current donor is PCIe Gen1 x1. Its raw post-8b/10b ceiling is 250 MB/s
before protocol overhead, so it cannot satisfy `>= 288 MB/s` sustained
application payload. It is therefore a `PROVEN` control-plane donor and
`NOT_FINAL_THROUGHPUT_CONFIGURATION`.

Gen2 x1 has a 500 MB/s post-encoding line-rate ceiling. The line-rate ceiling
is not an application-throughput promise. G1's 4,096-byte record with 3,840
useful bytes requires approximately 307.2 MB/s transported record bytes to
deliver 288 MB/s useful payload. Actual link, XDMA, AXI-stream, host, drop, and
long-run measurements remain mandatory.

## C2H implementation target

The accepted architecture target and frozen G2B implementation input are:

- one XDMA C2H channel per card;
- two private per-logical-channel rings;
- four 4,096-byte records per ring;
- one shared formatter/engine;
- work-conserving round-robin at complete-record boundaries;
- channel-tagged records; and
- exactly 3,840 useful bytes per record under
  `AHD_C2H_TRANSPORT_ABI_V1`.

The architecture decision is accepted and the named transport ABI is
`FROZEN_FOR_G2B` with lifecycle status `FROZEN`. No application C2H
implementation is accepted/offline-qualified; current G2B-IMPL is
`ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; one-channel and two-channel
DMA qualification has not occurred; G2B-HW remains lifecycle `BLOCKED` and
`NOT_PROVEN`.

## Frozen transport implementation requirements

The following are normative requirements derived from the accepted G2B-PRE
contract. Their `FROZEN` status makes them implementation and parser inputs;
it does not claim that any data plane or hardware result exists.

| ID | Frozen requirement | Status | Qualification state |
|---|---|---|---|
| `REQ-C2H-RECORD` | Every C2H record is exactly 4,096 bytes: 64-byte header, 3,840-byte useful payload, and 192-byte padding | `FROZEN` | No accepted/offline-qualified G2B implementation; sign-off recovery pending; G2B-HW `BLOCKED` and `NOT_PROVEN` |
| `REQ-C2H-PAYLOAD` | Every valid record contains one complete validated 1,920-pixel active line in packed UYVY 4:2:2 byte order `U0,Y0,V0,Y1`; no SAV/EAV, blanking, timestamp, checksum, or descriptor bytes | `FROZEN` | No host DMA or frame-delivery qualification |
| `REQ-C2H-PADDING` | Record bytes `3904..4095` are formatter-generated zero; stale or unwritten RAM is forbidden; the consumer must validate zero | `FROZEN` | Formatter not implemented or proven |
| `REQ-C2H-IDENTITY` | Each record carries frozen logical channel, physical input, source frame/line/capture, reset epoch, per-channel attempt, and global stream identities with all reserved container bits zero | `FROZEN` | G2B emits logical 0, physical 0, active count 1; future channel 1 remains unimplemented |
| `REQ-C2H-SEQUENCE` | Sequence and epoch semantics must remain coherent: attempts consume per-channel numbers even when later dropped/malformed/aborted; only complete streamed records consume contiguous global order; a new transport epoch resets both transport next-values to zero | `FROZEN` | No RTL or hardware continuity proof |
| `REQ-C2H-RESET` | A transport reset must disable admission, require host re-enable, atomically flush ownership/descriptors through acknowledged epoch coordination, expose no partial record, and resume only at beat 0; source and NVP/I2C lifecycles remain independent | `FROZEN` | Reset implementation and CDC behavior not proven |
| `REQ-C2H-AXIS` | The 64-bit stream has exactly 512 beats, `TKEEP=0xFF` throughout, and `TLAST` only on beat 511; while `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain stable and record state advances only on handshake | `FROZEN` | Backpressure simulation and hardware DMA not performed |
| `REQ-C2H-OWNERSHIP` | A committed record and matching descriptor are immutable; slot release occurs only after the final-beat handshake and acknowledged return; overwrite of committed or in-flight records is forbidden | `FROZEN` | Ring/data-plane implementation not accepted |
| `REQ-G2B-GROUP9-OWNERSHIP-SIGNOFF` | Group-9 `OWNERSHIP_AXI_TO_SOURCE` requires `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`: two-stage request and acknowledgement synchronizers, held 58-bit payload, source hold until acknowledgement, reset/epoch coherency, and `6.000 ns` absolute settling checks for `slot`, `generation`, and `epoch` | `FROZEN` | Method promoted from BS3; authoritative result `PRESERVE_PASS`; `RTL_CHANGE_REQUIRED = NO` |
| `REQ-G2B-GROUP13-RESET-RETURN-SIGNOFF` | Group-13 `RESET_RETURN_SOURCE_TO_AXI` requires `SETTLING_PLUS_STRUCTURAL_CDC`: two exact semantic families, `6.000 ns` absolute datapath-only settling, retained broad aggregate `6.000 ns` coverage, stable-until-acknowledgement behavior, two-stage request/acknowledgement and live commit-phase synchronization, commit-phase equality, hard-episode qualification, reset-return coherency, destination-use sequencing, and atomic epoch/state publication | `FROZEN` | Method promoted from G13-A; recovery-2 result `PRESERVE_PASS`; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO` |
| `REQ-G2B-GROUP14-RELEASE-SLOT0-SIGNOFF` | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` requires `SETTLING_PLUS_STRUCTURAL_CDC`: exactly three semantic families with `6.000 ns` absolute datapath-only settling, held 56-bit generation/epoch token lifetime, same-edge token/toggle ordering, two-stage release-toggle synchronization for normal use, two-stage transport-request synchronization for reset accounting, fail-closed generation/epoch/ownership identity, captured release-phase retirement/completion barrier, destination-use ordering, and reset/release coherency | `FROZEN` | Method promoted from G14-A; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO`; active XDC update is authorized for `G2B-LUT1-SIGNOFF-RECOVERY-3` but not yet implemented |
| `REQ-C2H-LOSS` | Ring-full and other noncommitted attempts use whole-record drop; attempted/dropped and applicable overflow/malformed accounting increments exactly once; pending discontinuity/loss context reaches the next committed record; partial drop and silent sequence repair are forbidden | `FROZEN` | Drop/overflow behavior not implemented or measured |
| `REQ-LINUX-C2H-PARSER` | The Linux transport parser must negotiate MMIO ABI/capabilities, create a session epoch with `RESET_STREAM_STATE`, parse only fixed 4,096-byte boundaries, and validate ABI/version, identities, flags, source/attempt/global sequences, epoch, line/SOF, payload length, and zero padding | `FROZEN` | Linux consumer contract is frozen input; V4L2 remains `NOT_IMPLEMENTED` |
| `REQ-C2H-INPUT-SCALE` | The product exposes 4 physical input identities per card and permits at most 2 active logical inputs per card | `FROZEN` | Second ingress and two-channel DMA remain unqualified |
| `REQ-C2H-THROUGHPUT` | Sustained AHD application payload target remains `>= 288 MB/s` per card | `FROZEN` | Target is not achieved or hardware-qualified; transport overhead, link, XDMA, host, drops, and long-run behavior still require measurement |

The normative evidence is
`v41-development-g2b-pre-c2h-abi-mmio-freeze` at commit
`e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`, including the ABI Markdown/JSON,
MMIO contract/map, Linux consumer contract, and 63/63 consistency receipt.
No requirement above promotes one-channel C2H RTL, one-channel hardware DMA,
two-channel DMA, `>= 288 MB/s` qualification, V4L2, DMABUF, multi-card Linux
policy, runtime Gen2 negotiation, a G2B bitstream, or G2B host capture.

### Governed Group-9 sign-off recipe

The Group-9 replacement method is based on a `13.468 ns` minimum
launch-to-use margin, a `6.000 ns` maximum settling bound, and `7.468 ns`
gross reserve. It is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` than the retired
global check and is not a relaxation of safety.

The governed Group-9 method consists of:

1. ownership structural CDC proof;
2. request synchronizer validation;
3. acknowledgement synchronizer validation;
4. stable-data hold proof;
5. per-family settling checks;
6. reset/epoch coherency proof;
7. normal routed timing;
8. CDC disposition;
9. DRC;
10. clocks/resources; and
11. the pre-bitstream hard gate.

`GLOBAL_SET_BUS_SKEW_3NS` and the global Group-9 `report_bus_skew` execution
are `RETIRED_FROM_REQUIRED_SIGNOFF` and are excluded from this current recipe.
The authoritative Group-9 PASS is preserved and shall not be repeated by
`G2B-LUT1-SIGNOFF-RECOVERY-3` unless later evidence invalidates it.

### Governed Group-13 sign-off recipe

The Group-13 replacement retires the global `set_bus_skew 3.000` relation over
seven sources and 207 destinations. The old path set is
`INVALID_FOR_SKEW_COMPARISON`; the global Group-13 `report_bus_skew` is
`RETIRED_FROM_REQUIRED_SIGNOFF` and must not be rerun as a current hard gate.

The exact two semantic families are:

1. `RESET_ABANDONED_COUNT_STABLE_PAYLOAD`: three sources, the 32-cell
   abandoned-accounting cone, `SETTLING_BEFORE_VALID`, and
   `STABLE_UNTIL_ACK`; and
2. `RESET_COMMIT_PHASE_COMPLETION_BARRIER`: four sources, the original
   207-cell completion cone, `SETTLING_BEFORE_VALID`, `STABLE_UNTIL_ACK`, and
   synchronized live-phase equality before completion.

Both families require `6.000 ns` absolute datapath-only settling to all timing
endpoint roles on the selected destination cells. The unchanged broad
source-mailbox `6.000 ns` max-delay relation is also required and must retain
the validated 79-cell supplemental coverage of the second family. That
supplemental fanout is not a third family; changing or removing the aggregate
relation invalidates the accepted equivalence and requires Group-13
revalidation.

The structural half of the requirement is inseparable from the timing half:

1. capture both held payloads on one accepted source request edge;
2. hold them stable while acknowledgement is outstanding;
3. validate two-stage request and acknowledgement synchronization;
4. validate the two-stage live commit-phase synchronizer;
5. require matching acknowledgement/request phase, live/held commit-phase
   equality, and hard-episode qualification before semantic use;
6. preserve reset-return coherency and destination-use sequencing;
7. exclude commit-phase parity alias through exclusive reset handling,
   disabled admission, and suppressed commit enqueue/scheduler progress while
   reset is busy;
8. publish the reset epoch/state atomically only on the qualified completion
   edge; and
9. retain fresh global CDC disposition as a later routed hard gate.

The promoted Group-13 conjunction and its recovery-2 PASS are preserved.
`G2B-LUT1-SIGNOFF-RECOVERY-3` must not repeat or alter Group 13 unless later
evidence invalidates it.

### Governed Group-14 sign-off recipe

The Group-14 replacement retires this exact global relation:

```tcl
set_bus_skew 3.000 \
  -from $g2b_release0_payload_src \
  -to $g2b_release_payload_dst
```

The historical scope contains 56 sources—24 generation bits plus 32 epoch
bits—and 20 destinations. It is `INVALID_FOR_SKEW_COMPARISON`; the verified
full Group-14 `report_bus_skew` timeout remains historical evidence. The old
`GLOBAL_SET_BUS_SKEW_3NS` method is `RETIRED_FROM_REQUIRED_SIGNOFF` and must
not be rerun as a current hard gate.

The exact three semantic families are:

1. `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`: 56 token sources to three slot-0
   state bits, `6.000 ns` absolute datapath-only settling, worst actual
   `5.467 ns`, slack `0.563 ns`, `PASS`;
2. `RELEASE_SLOT0_MISMATCH_CONTAINMENT`: 56 token sources to four
   fault/admission registers, `6.000 ns` absolute datapath-only settling,
   worst actual `5.554 ns`, slack `0.478 ns`, `PASS`; and
3. `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`: 56 token sources to three
   reset-abandoned counter bits, `6.000 ns` absolute datapath-only settling,
   worst actual `4.191 ns`, slack `1.839 ns`, `PASS`.

The structural half of the requirement is inseparable from these timing
checks:

1. launch generation, epoch, and the slot-0 release toggle together on the
   final accepted AXI-stream beat;
2. hold the 56-bit token stable until the relevant synchronized event is
   consumed, using the slot lifecycle to prevent premature overwrite;
3. for ordinary release, validate the two-stage `ASYNC_REG` release-toggle
   synchronizer and permit destination use only on a new synchronized phase;
4. require generation equality, descriptor/current-reset epoch equality, and
   `DMA_OWNED` state before normal release, with any mismatch failing closed
   through ownership-fatal containment and disabled admission;
5. for reset overlap, capture the same-edge release phase and use the separate
   two-stage `ASYNC_REG` transport-request synchronizer to authorize abandoned-
   record accounting;
6. compute reset accounting from the same-episode generation/epoch token and
   preserve reset-lifetime identity so an old token cannot qualify a newer
   owner;
7. block transport acknowledgement until the independently synchronized
   release vector equals the captured phase, then record the consumed or
   reset-retired phase;
8. preserve destination-use ordering, captured release-phase retirement, and
   reset/release coherency; and
9. retain fresh global CDC disposition as a later routed hard gate.

These requirements implement the exact invariant conjunction
`ABSOLUTE_SETTLING`, `STABLE_DATA_UNTIL_EVENT_CONSUMPTION`, `EVENT_ORDERING`,
`SYNCHRONIZER_STRUCTURE`, `COMPLETION_BARRIER`, and `TOKEN_IDENTITY`.

`RTL_CHANGE_REQUIRED = NO`. Active production XDC is unchanged by META-6.
`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate
authority is `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from evidence commit
`9e91315968453e859006077191cd5fc711fc6b96`.

`G2B-LUT1-SIGNOFF-RECOVERY-3` may implement that candidate under governed
source-change authority, validate the promoted Group-14 conjunction, then
continue Groups 15–17, routed setup/hold timing, DRC, CDC disposition, clocks,
PRODUCT resources, and the pre-bitstream hard gate. It must preserve
`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`; and
`GROUP13 = PRESERVE_PASS`. `GROUPS_15_TO_17 = PENDING_UNCHANGED`. Bitstream
generation is allowed only after every preceding hard gate passes.

## Build-profile requirements

The dual-profile architecture is authorized but not implemented.

### PRODUCT

PRODUCT must retain:

- the complete qualified R1i functional correction, including physical SCL
  qualification, ACK sampling, required synchronizers, readiness, recovery,
  initialization, I2C, and bank-safety behavior;
- minimum production observability: firmware/runtime identity, `INIT_DONE`,
  `INIT_ERROR`, basic NACK/error status and counters, video-present state,
  transport status, DMA drop/error counters, reset epoch, and capabilities;
- XDMA Gen2 configuration and G2B transport; and
- frozen `AHD_C2H_TRANSPORT_ABI_V1` and MMIO `0x3800..0x3BFF` semantics.

G2B-LUT0-classified research-only tri-phase probing, deep diagnostic
histories, lifecycle observation, research-only MMIO cones/counters, and other
heavy observation structures may be excluded from PRODUCT only when their
removal does not alter functional correctness or any protected interface.

### RESEARCH_DIAGNOSTIC

RESEARCH_DIAGNOSTIC must have the same qualified R1i functional behavior,
XDMA configuration, product interface semantics, and frozen G2B ABI/MMIO as
PRODUCT, plus enough R-track observability to resume R2/R3 reproducibly. It is
not required to meet PRODUCT resource-headroom targets. No current
post-G2B build or route success is claimed for this profile.

### Cross-profile invariants

Research instrumentation must never be required for functional correctness.
Profile selection must not change NVP initialization, I2C protocol behavior,
video capture semantics, C2H transport ABI, externally visible MMIO contract,
or XDMA configuration. Actual PRODUCT routed LUT utilization and timing must
be requalified by G2B-LUT1/G2B-IMPL; the `<=90%` gate and preferred `80–85%`
band are requirements, not achieved results.

## Linux Video product direction

The frozen direction is:

```text
V4L2 frontend
  ↓
AHD common video/capture core
  ↓
transport abstraction
  ↓
XDMA backend first
  ↓
possible future LitePCIe backend
```

Planned compatibility goals are FFmpeg, GStreamer, OpenCV, multi-card support,
stable card/input identity, and a future zero-copy/DMABUF path. These are
product requirements or goals, not current implementation claims.

## Protected product behavior

Every future implementation must preserve, with status `FROZEN`:

- NVP initialization behavior;
- I2C 25 kHz semantics;
- physical/filtered SCL qualification;
- qualified ACK timing;
- first qualified NACK abort;
- legal STOP;
- BUS_FREE confirmation;
- bounded retry/backoff;
- timeout handling;
- recovered-versus-terminal error distinction;
- bank safety/invalidation;
- existing MMIO semantics; and
- the R1i telemetry page.

META-3 authorizes reversible PRODUCT exclusion of research-only
instrumentation classified by G2B-LUT0. The instrumentation must remain
recoverable and reproducibly buildable through RESEARCH_DIAGNOSTIC; R-track
state is `HOLD`, not closed, and no research evidence may be deleted.
