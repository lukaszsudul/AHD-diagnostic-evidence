# AHD Current Requirements

`PROJECT_STATE_REV = 8`

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
| `REQ-PCIE-PAYLOAD` | Sustained application payload `>= 288 MB/s` per card | `FROZEN` | Efficient 4 KiB C2H records over Gen2 x1 or better | Offline analysis PASS; hardware NOT_PROVEN |
| `REQ-PCIE-MIN` | PCIe Gen2 x1 or better | `FROZEN` | Gen2 x1 is the minimum current target | Actual Gen2 training not qualified |
| `REQ-C2H-COUNT` | One XDMA C2H channel per card | `FROZEN` | Shared formatter/engine for up to two logical channels | Architecture accepted; one-channel PRODUCT offline-qualified; hardware NOT_PROVEN |
| `REQ-LINUX-FRONTEND` | Native Linux V4L2 integration | `FROZEN` | Standard `/dev/videoX` presentation through common capture core | `PLANNED`, not implemented |
| `REQ-TRANSPORT-ABSTRACTION` | Linux capture core must be transport-independent | `FROZEN` | XDMA first backend; future LitePCIe backend possible | `PLANNED`; final backend API is open |
| `REQ-CARD-IDENTITY` | Stable card and input identity for multi-card use | `FROZEN` | Persistent mapping independent of enumeration order | Architecture decision remains open |
| `REQ-STREAM-LIMIT` | Four logical inputs/card, maximum two `STREAMON`/card | `FROZEN` | V4L2 policy enforced per physical card | `PLANNED`, not implemented |
| `REQ-PRODUCT-LUT-GATE` | Routed PRODUCT LUT utilization `<= 90%` | `FROZEN` | Preferred target band `80–85%` | PASS: PRODUCT 17366/20800 LUT (83.490%); historical 84.192% remains an estimate |
| `REQ-BUILD-PROFILES` | Reversible `PRODUCT` and `RESEARCH_DIAGNOSTIC` profiles | `FROZEN` | One functional source architecture with explicit profile selection | PRODUCT offline-qualified; RESEARCH_DIAGNOSTIC qualification not promoted |

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

The architecture and FROZEN_FOR_G2B ABI remain unchanged. The exact
one-channel PRODUCT candidate is ACCEPTED offline. One-channel and
two-channel hardware DMA are NOT_PROVEN. G2B-HW is PLANNED and
AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION.

## Frozen transport implementation requirements

The following are normative requirements derived from the accepted G2B-PRE
contract. Their `FROZEN` status makes them implementation and parser inputs;
the exact PRODUCT implementation is separately accepted offline by META-8A;
no hardware result is claimed.

| ID | Frozen requirement | Status | Qualification state |
|---|---|---|---|
| `REQ-C2H-RECORD` | Every C2H record is exactly 4,096 bytes: 64-byte header, 3,840-byte useful payload, and 192-byte padding | `FROZEN` | Exact one-channel implementation accepted offline; G2B-HW PLANNED / NOT_PROVEN |
| `REQ-C2H-PAYLOAD` | Every valid record contains one complete validated 1,920-pixel active line in packed UYVY 4:2:2 byte order `U0,Y0,V0,Y1`; no SAV/EAV, blanking, timestamp, checksum, or descriptor bytes | `FROZEN` | No host DMA or frame-delivery qualification |
| `REQ-C2H-PADDING` | Record bytes `3904..4095` are formatter-generated zero; stale or unwritten RAM is forbidden; the consumer must validate zero | `FROZEN` | Formatter offline-qualified; hardware NOT_PROVEN |
| `REQ-C2H-IDENTITY` | Each record carries frozen logical channel, physical input, source frame/line/capture, reset epoch, per-channel attempt, and global stream identities with all reserved container bits zero | `FROZEN` | G2B emits logical 0, physical 0, active count 1; future channel 1 remains unimplemented |
| `REQ-C2H-SEQUENCE` | Sequence and epoch semantics must remain coherent: attempts consume per-channel numbers even when later dropped/malformed/aborted; only complete streamed records consume contiguous global order; a new transport epoch resets both transport next-values to zero | `FROZEN` | Offline functional regression PASS; hardware continuity NOT_PROVEN |
| `REQ-C2H-RESET` | A transport reset must disable admission, require host re-enable, atomically flush ownership/descriptors through acknowledged epoch coordination, expose no partial record, and resume only at beat 0; source and NVP/I2C lifecycles remain independent | `FROZEN` | Offline reset/CDC PASS; hardware reset NOT_PROVEN |
| `REQ-C2H-AXIS` | The 64-bit stream has exactly 512 beats, `TKEEP=0xFF` throughout, and `TLAST` only on beat 511; while `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain stable and record state advances only on handshake | `FROZEN` | Offline functional regression PASS; hardware DMA NOT_PROVEN |
| `REQ-C2H-OWNERSHIP` | A committed record and matching descriptor are immutable; slot release occurs only after the final-beat handshake and acknowledged return; overwrite of committed or in-flight records is forbidden | `FROZEN` | One-channel implementation accepted offline; hardware NOT_PROVEN |
| `REQ-G2B-GROUP9-OWNERSHIP-SIGNOFF` | Group-9 `OWNERSHIP_AXI_TO_SOURCE` requires `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`: two-stage request and acknowledgement synchronizers, held 58-bit payload, source hold until acknowledgement, reset/epoch coherency, and `6.000 ns` absolute settling checks for `slot`, `generation`, and `epoch` | `FROZEN` | Method promoted from BS3; authoritative result `PRESERVE_PASS`; `RTL_CHANGE_REQUIRED = NO` |
| `REQ-G2B-GROUP13-RESET-RETURN-SIGNOFF` | Group-13 `RESET_RETURN_SOURCE_TO_AXI` requires `SETTLING_PLUS_STRUCTURAL_CDC`: two exact semantic families, `6.000 ns` absolute datapath-only settling, retained broad aggregate `6.000 ns` coverage, stable-until-acknowledgement behavior, two-stage request/acknowledgement and live commit-phase synchronization, commit-phase equality, hard-episode qualification, reset-return coherency, destination-use sequencing, and atomic epoch/state publication | `FROZEN` | Method promoted from G13-A; recovery-2 result `PRESERVE_PASS`; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO` |
| `REQ-G2B-GROUP14-RELEASE-SLOT0-SIGNOFF` | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` requires `SETTLING_PLUS_STRUCTURAL_CDC`: exactly three semantic families with `6.000 ns` absolute datapath-only settling, held 56-bit generation/epoch token lifetime, same-edge token/toggle ordering, two-stage release-toggle synchronization for normal use, two-stage transport-request synchronization for reset accounting, fail-closed generation/epoch/ownership identity, captured release-phase retirement/completion barrier, destination-use ordering, and reset/release coherency | `FROZEN` | Method promoted from G14-A; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO`; HISTORICAL META-6 active-XDC boundary: authorized for recovery-3, not yet implemented at promotion; current Group-14 result `PRESERVE_PASS` |
| `REQ-C2H-LOSS` | Ring-full and other noncommitted attempts use whole-record drop; attempted/dropped and applicable overflow/malformed accounting increments exactly once; pending discontinuity/loss context reaches the next committed record; partial drop and silent sequence repair are forbidden | `FROZEN` | Offline functional regression PASS; hardware NOT_PROVEN |
| `REQ-LINUX-C2H-PARSER` | The Linux transport parser must negotiate MMIO ABI/capabilities, create a session epoch with `RESET_STREAM_STATE`, parse only fixed 4,096-byte boundaries, and validate ABI/version, identities, flags, source/attempt/global sequences, epoch, line/SOF, payload length, and zero padding | `FROZEN` | Linux consumer contract is frozen input; V4L2 remains `NOT_IMPLEMENTED` |
| `REQ-C2H-INPUT-SCALE` | The product exposes 4 physical input identities per card and permits at most 2 active logical inputs per card | `FROZEN` | Second ingress and two-channel DMA remain unqualified |
| `REQ-C2H-THROUGHPUT` | Sustained AHD application payload target remains `>= 288 MB/s` per card | `FROZEN` | Offline >=288 MB/s analysis PASS; hardware NOT_PROVEN; link, XDMA, host, drops and long-run behavior require measurement |

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
`G2B-LUT1-SIGNOFF-RECOVERY-4` unless later evidence invalidates it.

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
`G2B-LUT1-SIGNOFF-RECOVERY-4` must not repeat or alter Group 13 unless later
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

HISTORICAL META-6 promotion-time implementation boundary (SUPERSEDED
as a current work instruction by revision 7; accepted Group-14 method unchanged):

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

### Combined Groups 15–17 release-slot sign-off — revision 7

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


## Build-profile requirements

PRODUCT is implemented and offline-qualified. RESEARCH_DIAGNOSTIC
post-G2B qualification is not promoted.

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
band remain requirements, achieved by this exact offline PRODUCT candidate.

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
