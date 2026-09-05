# AHD Current Development Tracks

`PROJECT_STATE_REV = 7`

## Track summary

| Track | Purpose | Last accepted gate | Active gate | Next expected decision point | Track status |
|---|---|---|---|---|---|
| G-track | Product FPGA integration, data plane, qualification, and release architecture | G2B-LUT0 resource architecture | G2A remains separately active | `G2B-LUT1-SIGNOFF-RECOVERY-4` and complete offline requalification | `ACTIVE`; G2B-IMPL sign-off recovery pending |
| R-track | Isolate the R1i physical-SCL/ACK/recovery causal mechanism and characterize margin | R0 | none executing | Resume R2/R3 later through RESEARCH_DIAGNOSTIC | lifecycle `ACTIVE`; execution state `HOLD`, not closed |
| L-track | Native Linux/V4L2 product integration through a transport abstraction | none | none | Approve/launch L0 with final input assumptions and interfaces | `PLANNED` |
| META track | Maintain current project truth, governance, provenance, revisions, and compatibility | META-7R | none | Next explicitly authorized accepted-state change | `ACCEPTED` |

## G-track — product development

**Purpose:** preserve the qualified R1i product behavior while integrating the
accepted XDMA/Gen2/C2H architecture and later proving correctness, resource
closure, and throughput.

### Gate state

- G-1: `ACCEPTED` — existing-work inventory and reuse context.
- G0: `ACCEPTED` — R1i and donor baseline freeze, protected behavior, Gen2 and
  288 MB/s requirements.
- G1: `ACCEPTED` — exact integration architecture and
  `G2_IMPLEMENTATION_ALLOWED` classification.
- G2A: lifecycle `ACTIVE`; progress `IN_PROGRESS`; not accepted.
- G2B-PRE: `ACCEPTED` — architecture-contract freeze only;
  `AHD_C2H_TRANSPORT_ABI_V1` is `FROZEN_FOR_G2B`, G2B MMIO is `FROZEN` at
  `0x3800..0x3BFF`, and the Linux consumer contract is a frozen transport
  input.
- G2B-IMPL: lifecycle `BLOCKED`; implementation state
  `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; not offline-qualified and
  no bitstream exists; Groups 15–17 candidate implementation and validation remain
  pending.
- G2B-LUT0: `ACCEPTED` — Plan B resource architecture only.
- G2B-LUT1: lifecycle `PLANNED`, readiness
  `READY_FOR_SIGNOFF_RECOVERY`; exact next gate
  `G2B-LUT1-SIGNOFF-RECOVERY-4`.
- G2B-HW: lifecycle `BLOCKED`; final offline sign-off, pre-bitstream hard gate,
  and a bitstream candidate do not exist.

### Current dependencies

- exact R1i branch/commit/tree/tag and protected behavior;
- primary XDMA donor identity and G1 inheritance conclusion;
- frozen Gen2 x1 or better and 288 MB/s/card requirements;
- effective `user_clk` proof and resource/timing closure;
- R-track state `HOLD`, with R2/R3 resumability preserved; and
- frozen `AHD_C2H_TRANSPORT_ABI_V1` and G2B MMIO contracts must be implemented
  without semantic changes;
- promoted Group-9 method `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`, with
  `6.000 ns` per-family settling for `slot`, `generation`, and `epoch`, based
  on `13.468 ns` minimum launch-to-use and `7.468 ns` gross reserve; Group 9
  PASS is authoritative and must not be repeated;
- promoted Group-13 method `SETTLING_PLUS_STRUCTURAL_CDC`, with exactly two
  `6.000 ns` settling families, retained broad aggregate coverage, stable hold,
  synchronized request/acknowledgement and live commit phase, the commit-phase
  equality barrier, and coherent qualified epoch/state publication; Group 13
  PASS is authoritative and must not be repeated;
- promoted Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` method
  `SETTLING_PLUS_STRUCTURAL_CDC`, with exactly three
  `6.000 ns` absolute datapath-only settling families:
  `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`,
  `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, and
  `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`; the held 56-bit generation/epoch
  token, two-stage release-toggle and transport-request synchronization,
  stable-data lifetime, captured release-phase retirement, destination-use
  ordering, and reset/release coherency remain mandatory; the old
  `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is retired from required
  sign-off and `RTL_CHANGE_REQUIRED = NO`; its HISTORICAL META-6 active-XDC
  authorization remains recorded; current Group-14 PASS is preserved;
- `GROUPS_10_TO_12 = PRESERVE_PASS`; and
- `GROUPS_15_TO_17 = PROMOTED`.

### Next decision

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

The PRODUCT hard gate remains routed LUT `<=90%`, with a preferred
`80–85%` target; the 84.192% planning estimate is not an achieved result.

## R-track — causal research

**Purpose:** investigate physical SCL qualification versus ACK sampling point,
their combined effect, and supporting recovery/readiness behavior while
preserving the product baseline.

### Gate state

- R0: `ACCEPTED` — causal-isolation design, variants, protocols, outcome
  matrix, and margin trigger.
- R1: lifecycle context `ACTIVE`; execution state `HOLD`.
- R1i-a and R1i-b: `PROVISIONAL` research candidates only.
- R-track execution state: `HOLD`.
- R2 and R3: `HOLD`, not accepted, complete, closed, cancelled, or superseded.

### Current research question

Discriminate among:

1. physical SCL qualification;
2. ACK sampling point;
3. their combined effect; and
4. supporting recovery/readiness behavior.

### Current dependencies

- immutable qualified R1i control;
- same-session/controlled comparison discipline;
- cold-start and init-done timing protocols;
- explicit outcome matrix and margin trigger;
- reproducible retention through the RESEARCH_DIAGNOSTIC profile; and
- no change to product truth without Owner/Architect promotion.

### Next decision

Resume R2/R3 only under separate authority. Research evidence and branch
identities remain valid; no scientific closure is inferred from the PRODUCT
profile authorization.

## L-track — Linux Video / V4L2

**Purpose:** expose stable Linux video devices while keeping the common
capture/video layer independent of the PCIe transport backend.

### Gate state

- L0: `PLANNED`.
- No accepted or active Linux gate exists at revision 7.
- The Linux transport consumer input contract is frozen; V4L2 remains
  `NOT_IMPLEMENTED`.

### Planned architecture

```text
V4L2 frontend
  ↓
AHD common video/capture core
  ↓
transport abstraction
  ↓
XDMA backend first
  ↓
LitePCIe backend potentially later
```

### Current dependencies

- consume the frozen `AHD_C2H_TRANSPORT_ABI_V1` transport input without
  redefining it;
- one-channel and later two-channel DMA qualification;
- V4L2 pixel-format decision;
- timestamp architecture;
- persistent card/input identity;
- four logical inputs/card and maximum two `STREAMON`/card policy;
- multi-card behavior; and
- future buffer/DMABUF policy.

### Next decision

Define and authorize L0 without inventing implementation state. L0 must begin
by reading this SSOT and recording revision-at-start.

## META track — configuration management

**Purpose:** mechanically maintain the accepted project-state SSOT and its
auditability.

### Gate state

META-0 remains the accepted creation basis. META-2 promoted only the accepted
G2B-PRE interface contract. META-3 promoted G2B-LUT0 acceptance, R-track
`HOLD`, and dual-profile architecture authority. META-4R2 promotes the
ownership CDC Group-9 sign-off architecture and named unnumbered decision; it
does not modify RTL or active XDC. META-5 promotes the reset-return CDC
Group-13 sign-off architecture and named unnumbered decision; it also does not
modify RTL or active XDC. META-6 promotes the release-slot CDC Group-14
sign-off architecture and named unnumbered decision; it also does not modify
RTL or active XDC and does not accept G2B offline qualification, a bitstream,
hardware, or V4L2.

META-7R promotes the combined Groups 15–17 architecture through one
unnumbered governed decision while preserving Groups 9–14 PASS.

### Current dependencies

- explicit Owner/Architect decision;
- literal `SSOT WRITE AUTHORIZED`;
- immutable accepted evidence source;
- expected prior revision;
- minimal change scope;
- one-step revision increment;
- append-only changelog;
- non-force publication; and
- remote read-back.

### Next decision

After revision-7 publication, the next update begins only when a separate task
satisfies every field in `META_UPDATE_TEMPLATE.md`.
