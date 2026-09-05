# AHD Current Development Tracks

`PROJECT_STATE_REV = 8`

## Track summary

| Track | Purpose | Last accepted gate | Active gate | Next expected decision point | Track status |
|---|---|---|---|---|---|
| G-track | Product FPGA qualification | `G2B-LUT1-SIGNOFF-RECOVERY-4` | G2A separately active | `G2B-HW0-PRODUCT` | `ACTIVE`; exact PRODUCT offline candidate accepted |
| R-track | Isolate the R1i physical-SCL/ACK/recovery causal mechanism and characterize margin | R0 | none executing | Resume R2/R3 later through RESEARCH_DIAGNOSTIC | lifecycle `ACTIVE`; execution state `HOLD`, not closed |
| L-track | Native Linux/V4L2 product integration through a transport abstraction | none | none | Approve/launch L0 with final input assumptions and interfaces | `PLANNED` |
| META track | Accepted SSOT and auditability | META-8A | none | Next explicitly authorized state change | `ACCEPTED` |

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
- G2B-IMPL: ACCEPTED for exact one-channel offline implementation via G2B-LUT1; hardware NOT_PROVEN.
- G2B-LUT0: ACCEPTED — Plan B architecture retained.
- G2B-LUT1: ACCEPTED; OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE; accepted gate G2B-LUT1-SIGNOFF-RECOVERY-4.
- G2B-HW / G2B-HW0-PRODUCT: PLANNED, AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION, NOT_STARTED / NOT_PROVEN; hardware evidence absent.
- LAST_ACCEPTED_GATE: G2B-LUT1-SIGNOFF-RECOVERY-4.
- NEXT_ALLOWED_ENGINEERING_STEP: G2B-HW0-PRODUCT.

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

### Offline gate completion and next hardware decision

Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.

Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.

Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.


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
- No accepted or active Linux gate exists at revision 8.
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

META-7R promoted the combined Groups 15–17 architecture. META-8A now
accepts the exact completed offline PRODUCT candidate and separately plans
G2B-HW0-PRODUCT; no hardware operation is started.

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

After revision-8 publication, the next update begins only when a separate task
satisfies every field in `META_UPDATE_TEMPLATE.md`.

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
