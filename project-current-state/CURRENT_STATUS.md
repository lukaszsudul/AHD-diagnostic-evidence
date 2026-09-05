# AHD Current Status

`PROJECT_STATE_REV = 7`
State type: `CURRENT_ACCEPTED_STATE`
Accepted by role: `OWNER_ARCHITECT`
Decision basis: historical accepted state plus explicit Owner/Architect
promotion of the accepted combined Groups 15–17 release-slot CDC architecture
and sign-off methods through META-7R

## Acceptance boundary

This page records project truth. Evidence packages report engineering and
scientific results, but those results do not confer acceptance. G-1, G0, G1,
and R0 are `ACCEPTED` because the Owner/Architect-approved META-0 input says
so. G2B-PRE remains `ACCEPTED` as an architecture-contract freeze, and
G2B-LUT0 is `ACCEPTED` as a resource-architecture review. G2A remains
`ACTIVE`; the R-track execution state is `HOLD`, not closed. L0 remains
`PLANNED` and V4L2 remains `NOT_IMPLEMENTED`. META-4R2 preserves the promoted
Group-9 ownership sign-off architecture. META-5 promotes only the Group-13
reset-return sign-off architecture. META-6 promotes only the Group-14
release-slot sign-off architecture; none of these META updates changes RTL, active
XDC, offline qualification, bitstream, or hardware state.

## Track and gate status

| Track | Gate | Status | Current meaning | Acceptance/evidence boundary |
|---|---|---|---|---|
| Product | G-1 | `ACCEPTED` | Existing-work inventory and reuse context accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G0 | `ACCEPTED` | Baseline and donor identities, requirements, and protected behavior accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G1 | `ACCEPTED` | Integration and C2H architecture accepted; G2 implementation allowed | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G2A | `ACTIVE` | In progress; no accepted result is represented | No G2A package on evidence `main` at revision-1 creation |
| Product | G2B-PRE | `ACCEPTED` | C2H transport ABI, MMIO contract, and Linux transport-input contract frozen | Accepted evidence at `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`; architecture contract only |
| Product | G2B-IMPL | `BLOCKED` | Sign-off recovery pending; not offline-qualified | No G2B bitstream or hardware result; Groups 15–17 candidate XDC is authorized but not implemented; remaining routed hard gates are pending |
| Product | G2B-LUT0 | `ACCEPTED` | Plan B dual-profile resource architecture accepted | Evidence `PASS` at `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`; estimate is not qualification |
| Product | G2B-LUT1 | `PLANNED` | readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` | Preserve Groups 9–14 authoritative PASS; implement and validate all nine Groups 15–17 candidate checks, then continue remaining routed hard gates |
| Product | G2B-HW | `BLOCKED` | `NOT_STARTED / NOT_PROVEN` | Final offline sign-off, pre-bitstream hard gate, and a bitstream candidate do not exist |
| Research | R0 | `ACCEPTED` | Causal-isolation design accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Research | R1 | lifecycle `ACTIVE`; execution state `HOLD` | Valid research context; no closure or product promotion | `RESEARCH_DIAGNOSTIC` preserves the diagnostic continuation path |
| Research | R2/R3 | lifecycle `PLANNED`; state `HOLD` | Resumable later; neither accepted nor complete | `RESEARCH_DIAGNOSTIC` must preserve R2/R3 observability |
| Linux Video | L0 | `PLANNED` | Planned architecture direction; no implementation status invented | Owner/Architect-planned input; no L0 package on evidence `main` |
| META | META-0 | `ACCEPTED` | Governance infrastructure accepted by the creation authorization only | `ACCEPTED_BY_CREATION_TASK`; no broader decision inferred |
| META | META-3 | `ACCEPTED` | Build-profile architecture authorization promoted | SSOT/meta only; no source, build, Vivado, DMA, or hardware action |
| META | META-4R2 | `ACCEPTED` | Ownership CDC Group-9 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |
| META | META-5 | `ACCEPTED` | Reset-return CDC Group-13 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |
| META | META-6 | `ACCEPTED` | Release-slot CDC Group-14 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |

| META | META-7R | `ACCEPTED` | Combined Groups 15–17 release-slot methods promoted | SSOT only; no RTL, active XDC, bitstream or hardware action |

## META-7R combined release-slot promotion

Groups 15–17 each promote `SETTLING_PLUS_STRUCTURAL_CDC` with three
slot-specific semantic families, nine checks total, and a `6.000 ns` absolute
settling cap. The `13.468 ns` minimum launch-to-use window provides `7.468 ns`
gross reserve. `SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`,
`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`, and
`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`. Each former global
`GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is
`RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.

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

## Accepted product state

| Area | Status | Maturity / qualification |
|---|---|---|
| R1i NVP/I2C qualified PoC baseline | `ACCEPTED` | `PROVEN` within `QUALIFIED_POC_BASELINE`; not production qualification |
| R1i preservation identity | `FROZEN` | Exact branch, commit, tree, tag, and bitstream digest verified |
| XDMA endpoint and PCIe enumeration substrate | `ACCEPTED` | `PROVEN` at donor Gen1 x1 control-plane scope |
| BAR/MMIO and AXI-Lite | `ACCEPTED` | `PROVEN` within donor/R1i evidence |
| Existing MMIO through `0x35FF` | `FROZEN` | Must remain behaviorally and temporally compatible |
| R1i telemetry `0x3600–0x367F` | `FROZEN` | Read-only 32-word page |
| One-C2H/two-private-ring architecture | `ACCEPTED` | G1 architecture decision; not an implemented data-plane claim |
| `AHD_C2H_TRANSPORT_ABI_V1` version 1 | `FROZEN` | `FROZEN_FOR_G2B`; 4,096-byte record contract, not an implementation claim |
| G2B MMIO `0x3800–0x3BFF` | `FROZEN` | Contract frozen; registers are `NOT_IMPLEMENTED` in accepted hardware |
| Linux transport consumer contract | `FROZEN` | Frozen input contract only; V4L2 architecture/implementation is not promoted |
| Group-9 `OWNERSHIP_AXI_TO_SOURCE` sign-off | `ACCEPTED` | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; old `GLOBAL_SET_BUS_SKEW_3NS` retired from required sign-off |
| Group-13 `RESET_RETURN_SOURCE_TO_AXI` sign-off | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC`; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-13 `report_bus_skew` retired from required sign-off |
| Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off (active-XDC literal is HISTORICAL at META-6 promotion; current result `PRESERVE_PASS`) | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-14 `report_bus_skew` retired from required sign-off; `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` |
| PRODUCT profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; LUT hard gate `<=90%`, preferred `80–85%` |
| RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; PRODUCT functionality plus resumable research observability |
| Gen2 x1 implementation target | `FROZEN` | Required final configuration or better; hardware remains `NOT_PROVEN` |
| Sustained application payload `>= 288 MB/s/card` | `FROZEN` | Requirement remains `NOT_PROVEN` and not yet qualified |
| Application C2H payload | `PLANNED` | Not yet accepted |
| Record-to-AXI-stream data plane | `BLOCKED` | `READY_FOR_SIGNOFF_RECOVERY`; not offline-qualified |
| G2B-HW | `BLOCKED` | No final offline sign-off, pre-bitstream PASS, bitstream candidate, or hardware proof |
| One-channel application DMA | `PLANNED` | Not yet qualified |
| Two-channel application DMA | `PLANNED` | Not yet qualified |
| Two-card host topology | `PLANNED` | Architectural requirement, not two-card hardware qualification |

## R1i proven behavior

The accepted R1i hardware evidence establishes, within its qualified PoC scope:

| Observation | R1i | R1h control |
|---|---:|---:|
| Autonomous-init NACK count | 0 | 4 |
| `INIT_ERROR` | 0 | 1 |
| Video | present | absent |

The post-init campaign captured `60,000 / 60,000` selected-phase
observations. Scientific result is `THESIS_CONFIRMED` and frozen outcome is
`STRONG_PASS`. Production qualification is not claimed, and the exact causal
mechanism remains `INCONCLUSIVE`.

## Current product requirements

- Video: `1080p25`.
- Physical inputs per card: `4`.
- Maximum simultaneously active inputs per card: `2`.
- Planned cards per Linux host: `2`.
- Planned host topology: 8 physical inputs, maximum 4 active streams total,
  maximum 2 active per card.
- Sustained application payload: `>= 288 MB/s` per card.
- Final PCIe requirement: `PCIe Gen2 x1 or better`.
- PRODUCT routed LUT hard gate: `<= 90%`.
- Preferred PRODUCT routed LUT target: `80–85%`.
- Group-9 ownership settling cap: `6.000 ns` across the three semantic
  families `slot`, `generation`, and `epoch`.
- Group-9 minimum launch-to-use margin: `13.468 ns`; gross reserve:
  `7.468 ns`.
- Group-13 reset-return settling cap: `6.000 ns` for exactly two families,
  `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` and
  `RESET_COMMIT_PHASE_COMPLETION_BARRIER`, with the unchanged broad aggregate
  `6.000 ns` relation retained.
- Group-13 safety proof: stable data until acknowledgement, two-stage
  request/acknowledgement and live commit-phase synchronization, matching
  commit-phase completion barrier, hard-episode qualification, reset-return
  coherency, destination-use sequencing, and atomic epoch/state publication.
- Group-14 release-slot settling cap: `6.000 ns` for exactly three families,
  `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`,
  `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, and
  `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`.
- Group-14 safety proof: the 56-bit generation/epoch token remains stable until
  qualified use; ordinary use follows a two-stage release-toggle synchronizer;
  reset-overlap accounting follows a two-stage transport-request synchronizer
  and captured release-phase retirement; completion-barrier, token-identity,
  destination-use-ordering, and reset/release-coherency obligations remain
  required.

The current Gen1 x1 donor is a proven control-plane donor and is not the final
throughput configuration. G2B-LUT0 estimates PRODUCT at 17,512 LUT / 84.192%,
but that value is not measured qualification evidence and the target is not
marked achieved.

## Current Linux Video direction

Status is `PLANNED`: V4L2 frontend → AHD common video/capture core → transport
abstraction → XDMA first backend, with a possible later LitePCIe backend.
`AHD_C2H_TRANSPORT_ABI_V1` is frozen as the Linux consumer's transport input.
Standard `/dev/videoX` presentation, FFmpeg, GStreamer, OpenCV, multi-card
support, stable identity, and a future DMABUF/zero-copy path remain goals;
V4L2 is `NOT_IMPLEMENTED`.
