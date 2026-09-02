# AHD Current Development Tracks

`PROJECT_STATE_REV = 5`

## Track summary

| Track | Purpose | Last accepted gate | Active gate | Next expected decision point | Track status |
|---|---|---|---|---|---|
| G-track | Product FPGA integration, data plane, qualification, and release architecture | G2B-LUT0 resource architecture | G2A remains separately active | `G2B-LUT1-SIGNOFF-RECOVERY-2` and complete offline requalification | `ACTIVE`; G2B-IMPL sign-off recovery pending |
| R-track | Isolate the R1i physical-SCL/ACK/recovery causal mechanism and characterize margin | R0 | none executing | Resume R2/R3 later through RESEARCH_DIAGNOSTIC | lifecycle `ACTIVE`; execution state `HOLD`, not closed |
| L-track | Native Linux/V4L2 product integration through a transport abstraction | none | none | Approve/launch L0 with final input assumptions and interfaces | `PLANNED` |
| META track | Maintain current project truth, governance, provenance, revisions, and compatibility | META-5 | none | Next explicitly authorized accepted-state change | `ACCEPTED` |

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
  no bitstream exists.
- G2B-LUT0: `ACCEPTED` — Plan B resource architecture only.
- G2B-LUT1: lifecycle `PLANNED`, readiness
  `READY_FOR_SIGNOFF_RECOVERY`; exact next gate
  `G2B-LUT1-SIGNOFF-RECOVERY-2`.
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
  equality barrier, and coherent qualified epoch/state publication;
- `GROUPS_10_TO_12 = PRESERVE_PREVIOUS_RESULTS`; and
- `GROUPS_14_TO_17 = PENDING_UNCHANGED`.

### Next decision

`G2B-LUT1-SIGNOFF-RECOVERY-2` may implement the accepted
`G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` under the governed source-change
procedure. It must preserve Group 9 PASS and Groups 10–12 PASS, resume at
Group 13 with the promoted settling-plus-structural-CDC method, then continue
Groups 14, 15, 16, and 17, routed setup/hold timing, DRC, CDC disposition,
clocks, resources, and the pre-bitstream hard gate before any bitstream or
hardware step. The retired global Group-9 and Group-13 `report_bus_skew`
queries are not required. The PRODUCT hard gate remains routed LUT `<=90%`,
with a preferred `80–85%` target; the 84.192% planning estimate is not an
achieved result.

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
- No accepted or active Linux gate exists at revision 5.
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
modify RTL or active XDC and does not accept G2B offline qualification, a
bitstream, hardware, or V4L2.

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

After revision-5 publication, the next update begins only when a separate task
satisfies every field in `META_UPDATE_TEMPLATE.md`.
