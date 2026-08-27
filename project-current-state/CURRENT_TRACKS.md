# AHD Current Development Tracks

`PROJECT_STATE_REV = 1`

## Track summary

| Track | Purpose | Last accepted gate | Active gate | Next expected decision point | Track status |
|---|---|---|---|---|---|
| G-track | Product FPGA integration, data plane, qualification, and release architecture | G1 | G2A | Owner/Architect decision on G2A evidence; only then may a META update accept it | `ACTIVE` |
| R-track | Isolate the R1i physical-SCL/ACK/recovery causal mechanism and characterize margin | R0 | R1 | Owner/Architect decision on R1 results; candidates remain research-only until promotion | `ACTIVE` |
| L-track | Native Linux/V4L2 product integration through a transport abstraction | none | none | Approve/launch L0 with final input assumptions and interfaces | `PLANNED` |
| META track | Maintain current project truth, governance, provenance, revisions, and compatibility | META-0 | none after creation | Next explicitly authorized accepted-state change | `ACCEPTED` for META-0 infrastructure only |

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
- G2B: `PLANNED` and dependent on accepted G2A.

### Current dependencies

- exact R1i branch/commit/tree/tag and protected behavior;
- primary XDMA donor identity and G1 inheritance conclusion;
- frozen Gen2 x1 or better and 288 MB/s/card requirements;
- effective `user_clk` proof and resource/timing closure;
- no R-track candidate promotion without a separate decision; and
- transport ABI remains `PROVISIONAL`.

### Next decision

A Gate Agent may publish G2A execution evidence. The Owner/Architect must then
explicitly decide `ACCEPTED`, `REJECTED`, or `BLOCKED`. G2A evidence `PASS`
alone does not change this track.

## R-track — causal research

**Purpose:** investigate physical SCL qualification versus ACK sampling point,
their combined effect, and supporting recovery/readiness behavior while
preserving the product baseline.

### Gate state

- R0: `ACCEPTED` — causal-isolation design, variants, protocols, outcome
  matrix, and margin trigger.
- R1: lifecycle `ACTIVE`; progress `IN_PROGRESS`.
- R1i-a and R1i-b: `PROVISIONAL` research candidates only.

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
- continued diagnostic retention; and
- no change to product truth without Owner/Architect promotion.

### Next decision

Review R1 evidence and decide whether the mechanism remains open, a research
result is accepted, more revalidation is required, or a specific finding is
promoted. Even accepted research does not enter product architecture unless
the decision explicitly says so and a META update applies it.

## L-track — Linux Video / V4L2

**Purpose:** expose stable Linux video devices while keeping the common
capture/video layer independent of the PCIe transport backend.

### Gate state

- L0: `PLANNED`.
- No accepted or active Linux gate exists at revision 1.
- No implementation status is claimed.

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

- final C2H/record ABI;
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

META-0 is `ACCEPTED` solely as `ACCEPTED_BY_CREATION_TASK` for revision-1
governance infrastructure. This does not accept any G2A, R1, or L0 result.

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

No META update is active after revision-1 publication. The next update begins
only when a separate task satisfies every field in
`META_UPDATE_TEMPLATE.md`.
