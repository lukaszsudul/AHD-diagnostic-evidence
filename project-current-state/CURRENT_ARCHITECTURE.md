# AHD Current Architecture

`PROJECT_STATE_REV = 7`

This architecture separates accepted/proven substrate, accepted but not yet
implemented architecture, active work, planned product layers, and open
decisions. Lifecycle status and engineering maturity are independent.

## End-to-end view

```text
Four physical AHD inputs per card
  → NVP6134C bring-up and selected digital video ingress
  → explicit PRODUCT or RESEARCH_DIAGNOSTIC observability profile
  → AHD video frontend / BT.656 validation / record production
  → up to two logical capture channels per card
  → two private four-record rings
  → one shared record formatter and record-boundary round-robin scheduler
  → one XDMA C2H channel per card over PCIe Gen2 x1 or better
  → Linux transport abstraction (XDMA first; LitePCIe possible later)
  → AHD common capture core
  → V4L2 /dev/videoX frontend
  → FFmpeg / GStreamer / OpenCV applications

Planned host: two cards
  → eight physical inputs total
  → maximum four simultaneous streams total
  → maximum two simultaneous streams per card
```

The topology is an architectural requirement. It is not a claim of two-card,
two-channel, Gen2, throughput, or Linux hardware qualification.

## State and maturity matrix

| Component or decision | Lifecycle status | Maturity marker | What is established |
|---|---|---|---|
| R1i NVP/I2C bring-up and one video-presence path | `ACCEPTED` | `PROVEN` | Qualified PoC behavior and exact identity |
| XDMA endpoint, BAR/MMIO, AXI-Lite control plane | `ACCEPTED` | `PROVEN` | Enumeration, driver, BAR discovery, identity/status/scratch scope |
| Current Gen1 x1 donor link configuration | `FROZEN` | `PROVEN` | Control-plane donor only; inadequate for final 288 MB/s target |
| G1 one-C2H/two-ring architecture | `ACCEPTED` | `PLANNED` | Architecture decision accepted; data plane not implemented/qualified |
| Local R1i-a/R1i-b research candidate commits | `PROVISIONAL` | `IMPLEMENTED_UNQUALIFIED` | Research-only source candidates; no product-baseline authority |
| G2A | `ACTIVE` | `ACTIVE` | Work in progress; no accepted execution result represented |
| G2B-PRE architecture contract | `ACCEPTED` | `FROZEN_FOR_G2B` | `AHD_C2H_TRANSPORT_ABI_V1`, G2B MMIO, and Linux transport-input contract are frozen |
| G2B-LUT0 resource architecture | `ACCEPTED` | `PASS / IMPLEMENTATION_PENDING` | Dual-profile Plan B accepted; estimate is not qualification evidence |
| PRODUCT profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED` | Qualified R1i behavior, production observability, XDMA Gen2, G2B and frozen ABI/MMIO retained |
| RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED` | PRODUCT functional behavior plus reproducible R-track observability for R2/R3 resumability |
| Application record-to-C2H plane | `BLOCKED` | `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` | Groups 15–17 candidate-XDC implementation and complete final routed sign-off remain pending; no offline-qualified implementation |
| G2B-LUT1 | `PLANNED` | `READY_FOR_SIGNOFF_RECOVERY / SIGNOFF_RECOVERY_PENDING` | Authorized next gate is `G2B-LUT1-SIGNOFF-RECOVERY-4`; active XDC is not changed by META-6 |
| G2B-HW | `BLOCKED` | `NOT_STARTED / NOT_PROVEN` | Final offline sign-off, pre-bitstream hard gate, and a bitstream candidate do not exist |
| Linux/V4L2 product layer | `PLANNED` | `NOT_IMPLEMENTED` | Transport input is frozen; frontend, buffer, identity, and policy work remain later L-track scope |
| Gen2 training, actual `user_clk`, and throughput | `OPEN` | `NOT_PROVEN` | Require later qualification |

## Per-card accepted architecture

### Control and initialization plane

The qualified R1i tree is the composition authority. It already inherits the
required XDMA endpoint, AXI-Lite, BAR, capture/record, constraints, and build
substrate from the primary donor. Future integration starts from R1i and must
not merge an older donor over it.

R1i is whole-file/behavior authority for NVP bring-up and autonomous
initialization. The protected behavior includes 25 kHz I2C semantics,
physical/filtered SCL qualification, qualified ACK timing, first qualified
NACK abort, legal STOP, BUS_FREE confirmation, bounded retry/backoff, timeout,
recovered-versus-terminal classification, bank safety/invalidation, existing
MMIO behavior, and R1i telemetry.

### PCIe and MMIO plane

The accepted donor substrate has one XDMA C2H interface, one mandatory unused
H2C interface, a 64-bit AXI4-Stream application interface, AXI-Lite master, and
the existing BAR/control-plane structure. Its Gen1 x1 configuration is retained
as a provenance/control-plane oracle only.

The final product requirement is Gen2 x1 or better. Changing to Gen2 does not
itself prove link training, effective user clock, application DMA correctness,
or 288 MB/s payload.

All behavior through `0x35FF` and the R1i read-only page
`0x3600–0x367F` is frozen. New DMA pages must be disjoint and must pass
exhaustive no-alias and response-equivalence validation.

G2B-PRE freezes the new G2B MMIO contract at `0x3800..0x3BFF`. This is an
accepted interface allocation and semantic contract, not a claim that the
registers exist in the current build. All protected behavior through
`0x37FF` remains compatible and unchanged.

### Capture and record plane

The accepted G1 target has four physical inputs and at most two active logical
channels per card. Two selectors map distinct physical IDs 0–3 to logical
channels 0 and 1. Selection changes require the affected channel disabled and
drained. The second physical digital ingress remains unproven.

Each logical channel owns a private four-record ring. A shared formatter and
work-conserving round-robin scheduler select only at record boundaries and
never interleave record beats. Channel-local backpressure fills only that
channel's ring; overflow drops a whole record and is explicitly counted. A
shared formatter/link fault affects both channels.

The accepted `AHD_C2H_TRANSPORT_ABI_V1` record is exactly 4,096 bytes: a
64-byte header, a 3,840-byte payload containing one complete 1,920-active-pixel
UYVY 4:2:2 line, and 192 bytes of zero padding, with explicit
logical/physical channel identity. Its interface status is `FROZEN_FOR_G2B`.
The freeze makes the interface contract implementation-ready; the complete
G2B implementation remains in sign-off recovery and not offline-qualified. It
does not mean the formatter, rings, scheduler, or application C2H data plane
is accepted or hardware-qualified.

### Ownership mailbox CDC and Group-9 sign-off

The current required sign-off method for Group 9
`OWNERSHIP_AXI_TO_SOURCE` is
`PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`. It replaces the historical
`GLOBAL_SET_BUS_SKEW_3NS`, which is
`RETIRED_FROM_REQUIRED_SIGNOFF`. The 58-source ownership set is not a
homogeneous skew-comparison bundle: slot, generation, and epoch signals feed
selector/equality logic and reconverge on ownership-result logic. BS1R
reproduced pathological `report_bus_skew` behavior even on the exact 58-to-1
scope, and BS2 established that the path set is invalid for global skew
comparison.

The accepted ownership CDC model is a request/acknowledgement toggle mailbox
with a held 58-bit `{slot,generation,epoch}` bundled payload. Required
structural proof covers a two-stage request synchronizer, a two-stage
acknowledgement synchronizer, stable-data hold, source hold until
acknowledgement, and reset/epoch coherency. Required timing proof applies
absolute settling checks independently to the three semantic payload
families: `slot`, `generation`, and `epoch`.

The governed maximum settling bound is `6.000 ns`, based on the `13.468 ns`
minimum launch-to-use margin and `7.468 ns` gross reserve established by BS3.
The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT`. **This is not a
relaxation of safety:** the retired global metric compared structurally
heterogeneous paths, while the replacement checks match the actual
stable-data request/acknowledgement protocol.

`RTL_CHANGE_REQUIRED = NO`. The accepted candidate authority is
`G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc`; the authoritative Group-9
result is `PRESERVE_PASS`, and META-6 does not reopen or alter this method.

The promoted Group-9 method was accepted with these components:

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
11. pre-bitstream hard gate.

The authoritative Group-9 PASS is preserved, so these accepted components are
not required to be repeated by `G2B-LUT1-SIGNOFF-RECOVERY-4`. The retired
global Group-9 `report_bus_skew` execution is not part of the method and is not
required again.

### Reset-return mailbox CDC and Group-13 sign-off

The current required sign-off method for Group 13
`RESET_RETURN_SOURCE_TO_AXI` is `SETTLING_PLUS_STRUCTURAL_CDC`. It replaces
the historical `GLOBAL_SET_BUS_SKEW_3NS`, which is
`RETIRED_FROM_REQUIRED_SIGNOFF`. The retired relation covered seven
`nvp_vclk1` source registers and 207 heterogeneous `userclk1` destination
registers. Its path set is `INVALID_FOR_SKEW_COMPARISON`, and the historical
full Group-13 `report_bus_skew` query timed out; it is not required again.

Group 13 is a stable-data return mailbox qualified by the transport
request/acknowledgement protocol, not an asynchronous-reset-release crossing,
Gray bus, or seven independent synchronized controls. Its exact CDC
classification is `STABLE_DATA + HANDSHAKE +
COMMIT_PHASE_COMPLETION_BARRIER + COMBINATIONAL_AGGREGATION`.

The two semantic families are:

1. `RESET_ABANDONED_COUNT_STABLE_PAYLOAD`: the three-bit abandoned-record
   snapshot, consumed through the 32-cell `records_abandoned_axi` accounting
   cone after qualified completion; and
2. `RESET_COMMIT_PHASE_COMPLETION_BARRIER`: the four-bit per-slot commit-toggle
   phase snapshot, covering the original 207-cell Group-13 completion cone.

Each family requires a `6.000 ns` absolute datapath-only settling check to all
timing endpoint roles on the selected destination cells. The unchanged broad
source-mailbox `6.000 ns` max-delay relation is also mandatory: it contains all
7/207 Group-13 members and provides the validated 79-cell supplemental fanout
coverage for the second family. That supplemental coverage is not a third
semantic family. Removing or changing the broad aggregate relation invalidates
the accepted equivalence and requires Group-13 revalidation.

The timing constraints are necessary but not sufficient. Required structural
proof covers single-edge payload capture; stable hold while acknowledgement is
outstanding; two-stage request and acknowledgement synchronizers; the
two-stage live commit-phase synchronizer; completion only when acknowledgement
matches request and the synchronized live phase equals the held commit phase;
hard-episode qualification; reset-return coherency; destination-use
sequencing; and atomic reset epoch/state publication on the qualified
completion edge. Commit-phase parity alias is excluded by protocol sequencing:
reset handling is exclusive of ordinary source processing, admission is
disabled, and commit enqueue/scheduler progress is suppressed while reset is
busy. Reset assertion and deassertion are synchronously observed by the two
processes; they are not treated as an async-assert/sync-release Group-13
mechanism.

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a
relaxation of safety. `RTL_CHANGE_REQUIRED = NO`. The Group-13 candidate
authority is `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc`; its recovery-2 result is
`PRESERVE_PASS` and META-6 does not reopen or change this method.

The authoritative Group-9 PASS, Groups 10–12 PASS, and Group-13 PASS results
are preserved without rerun.

### Release-slot CDC and Group-14 sign-off

The current required sign-off method for Group 14
`RELEASE_SLOT_0_AXI_TO_SOURCE` is `SETTLING_PLUS_STRUCTURAL_CDC`. It replaces
the historical `GLOBAL_SET_BUS_SKEW_3NS` relation:

```tcl
set_bus_skew 3.000 \
  -from $g2b_release0_payload_src \
  -to $g2b_release_payload_dst
```

The old relation covered 56 `userclk1` sources—24 generation bits and 32 epoch
bits—and 20 heterogeneous `nvp_vclk1` destinations. The path set is
`INVALID_FOR_SKEW_COMPARISON`; the bounded historical Group-14
`report_bus_skew` timeout remains provenance only. The global query is
`RETIRED_FROM_REQUIRED_SIGNOFF` and is not a current hard gate.

Group 14 carries a held 56-bit generation/epoch stable-data release token. On
an ordinary release, generation, epoch, and `release_toggle_axi[0]` launch on
the same final accepted AXI-stream beat. The release toggle crosses
`release_sync1_source[0]` and `release_sync2_source[0]`, both `ASYNC_REG`, and
normal destination use occurs only when the synchronized phase differs from
`release_seen_source[0]`. On reset overlap, the AXI reset request captures the
same-episode release phase—including a same-edge final-beat release—and
launches `transport_req_toggle_axi`; accounting is authorized only after the
two-stage `transport_req_sync1_source` / `transport_req_sync2_source` chain.

The three exact semantic families are:

| Family | Semantic endpoint set | Governed physical requirement | Validated routed result |
|---|---|---|---|
| `RELEASE_SLOT0_NORMAL_STATE_TRANSITION` | 56 token sources to 3 slot-0 state bits | `6.000 ns` absolute datapath-only settling | worst actual `5.467 ns`; slack `0.563 ns`; `PASS` |
| `RELEASE_SLOT0_MISMATCH_CONTAINMENT` | 56 token sources to 4 fault/admission registers | `6.000 ns` absolute datapath-only settling | worst actual `5.554 ns`; slack `0.478 ns`; `PASS` |
| `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING` | 56 token sources to 3 reset-abandoned counter bits | `6.000 ns` absolute datapath-only settling | worst actual `4.191 ns`; slack `1.839 ns`; `PASS` |

The `6.000 ns` cap is inherited from the existing governed aggregate
AXI-to-source mailbox relation. Two complete `6.734 ns` destination periods
provide a `13.468 ns` gross earliest-use window and retain `7.468 ns` gross
protocol margin at that cap. `GROUP14_CDC_STRUCTURE = PASS_WITH_DISPOSITION`
and the bounded replacement workload is `PRACTICAL`.

The timing half is inseparable from the accepted structural proof. The token
must remain stable until its relevant synchronized event is consumed; the slot
lifecycle prevents another token launch until refill, commit, AXI ownership,
and another complete 512-beat record. Normal use requires matching slot
generation, descriptor epoch, current reset epoch, and `DMA_OWNED` state. A
mismatch fails closed through the ownership-fatal path and disables admission,
so a stale token cannot silently release a newer owner.

Reset accounting follows the synchronized transport request rather than a
release-toggle mismatch. It uses the same-episode token to compute abandoned
ownership and force slots writable, while transport acknowledgement waits
until the independently synchronized release vector equals the captured phase.
`release_seen_source[0]` records the consumed or reset-retired phase. Required
proof therefore preserves `ABSOLUTE_SETTLING`,
`STABLE_DATA_UNTIL_EVENT_CONSUMPTION`, `EVENT_ORDERING`,
`SYNCHRONIZER_STRUCTURE`, `COMPLETION_BARRIER`, and `TOKEN_IDENTITY`, including
destination-use ordering, captured release-phase retirement, and coherent
generation/epoch separation across reset lifetimes.

HISTORICAL META-6 promotion-time implementation boundary (SUPERSEDED
as a current work instruction by revision 7; accepted Group-14 method unchanged):

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a safety
relaxation. `RTL_CHANGE_REQUIRED = NO`. Active production XDC is unchanged by
META-6 and `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`.
The accepted future candidate is `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from
evidence commit `9e91315968453e859006077191cd5fc711fc6b96`, to be implemented
only by `G2B-LUT1-SIGNOFF-RECOVERY-3` under governed source-change authority.

`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`; and
`GROUP13 = PRESERVE_PASS`. `GROUPS_15_TO_17 = PENDING_UNCHANGED`.

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

`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.

`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
promotion evidence and promotion-time active-XDC dispositions are preserved.
The Group-14 pending-XDC statements at META-6 are historical promotion-time
boundaries; the authoritative audit now preserves its PASS. They do not
instruct recovery-4 to reimplement Group 14.

`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
global Groups 15–17 bus-skew constraints with the nine candidate checks,
preserving every unrelated active constraint and Groups 9–14 PASS. It must
validate all nine checks, then continue final routed timing, DRC, CDC
disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
Bitstream generation is a later engineering action allowed only after those
gates pass; it is not performed or claimed by META-7R.

`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
complete; no G2B bitstream exists and hardware has not been tested. No final
timing sign-off, qualification, release, hardware readiness, DMA operation,
or hardware proof is promoted.

### Build-profile boundary

`PRODUCT` and `RESEARCH_DIAGNOSTIC` are two elaborations of one functional
product architecture. Both must have identical qualified R1i functional
behavior, XDMA configuration, video-capture semantics, frozen transport ABI,
and externally visible MMIO contract. Research instrumentation is never a
functional dependency.

`PRODUCT` retains the full qualified R1i correction, physical SCL and ACK
behavior, required synchronizers/readiness/recovery, minimum production NVP
and video observability, runtime identity, XDMA Gen2 configuration, G2B
transport/status/counters/reset epoch/capabilities, and the frozen
`AHD_C2H_TRANSPORT_ABI_V1` / `0x3800..0x3BFF` interface. G2B-LUT0-classified
research-only probes, deep histories, lifecycle observers, counters, MMIO
cones, and observation structures may be absent only when their removal
cannot alter any functional or externally visible product semantic.

`RESEARCH_DIAGNOSTIC` is PRODUCT functional behavior plus the observability
needed to resume R2/R3. It may exceed PRODUCT resource targets, but it must
remain reproducibly buildable. No claim is made that the research profile
currently builds or routes after G2B.

G2B-LUT1 may select a reversible repository-supported mechanism such as
generics, Tcl profile selection/defines, generate blocks, or source sets. The
implementation agent, not META-3, must choose the least invasive method.

### Application DMA qualification boundary

Current accepted state:

- PCIe endpoint: `PROVEN`.
- BAR/MMIO: `PROVEN`.
- AXI-Lite: `PROVEN`.
- G2B-PRE transport/MMIO architecture contract: `ACCEPTED` and
  `FROZEN_FOR_G2B`.
- Application C2H payload: not accepted.
- Record-to-AXI-stream/G2B implementation:
  `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` and not offline-qualified.
- Group-9 ownership sign-off method:
  `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; the promoted method and
  authoritative PASS are preserved.
- Group-13 reset-return sign-off method: `SETTLING_PLUS_STRUCTURAL_CDC`; the
  old global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is retired from
  required sign-off; its promoted method and recovery-2 PASS are preserved.
- Group-14 release-slot sign-off method: `SETTLING_PLUS_STRUCTURAL_CDC`; the
  old global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is retired from
  required sign-off; its authoritative PASS is preserved. Groups 15–17
  candidate implementation and validation are the next governed work.
- G2B-LUT1 readiness: `READY_FOR_SIGNOFF_RECOVERY`; next gate
  `G2B-LUT1-SIGNOFF-RECOVERY-4`.
- One-channel DMA: not yet qualified.
- Two-channel DMA: not yet qualified.
- Sustained 288 MB/s: not yet qualified.
- G2B-HW: lifecycle `BLOCKED`, `NOT_STARTED`, and `NOT_PROVEN` until final
  offline sign-off, the pre-bitstream hard gate, and a bitstream candidate
  exist.

Enumeration, driver load, or a nonzero byte count alone is not C2H correctness
or throughput evidence.

## Linux and multi-card architecture

The planned software layering is:

```text
V4L2 frontend
  ↓
AHD common video/capture core
  ↓
transport abstraction
  ↓
XDMA backend initially
  ↓
possible future LitePCIe backend
```

Goals are stable `/dev/videoX` presentation, FFmpeg/GStreamer/OpenCV
compatibility, four logical inputs per card, no more than two `STREAMON`
instances per card, stable card/input identity, multi-card operation, and a
future zero-copy/DMABUF path. `AHD_C2H_TRANSPORT_ABI_V1` and its Linux consumer
contract are frozen transport inputs. Every V4L2, identity, multi-card, and
DMABUF item remains `PLANNED` and `NOT_IMPLEMENTED`.

## Architectural invariants

- R-track state is `HOLD`, not closed; research work remains valid and
  resumable through `RESEARCH_DIAGNOSTIC`.
- PRODUCT and RESEARCH_DIAGNOSTIC have identical qualified R1i functional
  behavior; research instrumentation is never required for correctness.
- Removing research instrumentation from PRODUCT must not change NVP
  initialization, I2C protocol behavior, video capture semantics,
  `AHD_C2H_TRANSPORT_ABI_V1`, MMIO contracts, or XDMA configuration.
- NVP autoinit must not become dependent on PCIe link state or application
  stream reset.
- PCIe/reset events may reset or flush the application stream plane but must
  not restart or gate qualified NVP initialization.
- Video-to-XDMA payload crosses through proper dual-clock storage and
  descriptor/release CDC; independent synchronizers are not used for payload.
- Group-9 ownership correctness is signed off by structural CDC proof plus
  per-family absolute settling checks for slot, generation, and epoch; the
  heterogeneous global bus-skew metric is historical and retired.
- Group-13 reset-return correctness is signed off by the conjunction of two
  family-specific `6.000 ns` absolute settling checks, the unchanged broad
  aggregate `6.000 ns` relation, stable-until-acknowledgement proof,
  synchronized request/acknowledgement and live commit phase, the commit-phase
  completion barrier, and atomic coherent epoch/state publication; the old
  global Group-13 skew metric is historical and retired.
- Group-14 release-slot correctness is signed off by three family-specific
  `6.000 ns` absolute datapath-only settling checks plus stable token lifetime,
  same-edge release event ordering, two-stage release-toggle and transport-
  request synchronization, fail-closed generation/epoch identity, captured
  release-phase retirement, destination-use ordering, and reset/release
  coherency; the old global Group-14 skew metric is historical and retired.
- Legacy PIO/v40B compatibility and DMA `AHD_C2H_TRANSPORT_ABI_V1` storage are
  separate.
- One physical PCIe lane has one shared failure/bandwidth domain even when two
  logical video channels are active.
- Research instrumentation excluded from PRODUCT remains recoverable through
  the reproducible RESEARCH_DIAGNOSTIC profile; evidence and R-track branches
  are not deleted or modified by META-3.
