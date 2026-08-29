# AHD Current Status

`PROJECT_STATE_REV = 3`
State type: `CURRENT_ACCEPTED_STATE`
Accepted by role: `OWNER_ARCHITECT`
Decision basis: historical accepted state plus explicit Owner/Architect
acceptance of G2B-LUT0 and dual-profile authorization for META-3

## Acceptance boundary

This page records project truth. Evidence packages report engineering and
scientific results, but those results do not confer acceptance. G-1, G0, G1,
and R0 are `ACCEPTED` because the Owner/Architect-approved META-0 input says
so. G2B-PRE remains `ACCEPTED` as an architecture-contract freeze, and
G2B-LUT0 is `ACCEPTED` as a resource-architecture review. G2A remains
`ACTIVE`; the R-track execution state is `HOLD`, not closed. L0 remains
`PLANNED` and V4L2 remains `NOT_IMPLEMENTED`.

## Track and gate status

| Track | Gate | Status | Current meaning | Acceptance/evidence boundary |
|---|---|---|---|---|
| Product | G-1 | `ACCEPTED` | Existing-work inventory and reuse context accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G0 | `ACCEPTED` | Baseline and donor identities, requirements, and protected behavior accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G1 | `ACCEPTED` | Integration and C2H architecture accepted; G2 implementation allowed | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G2A | `ACTIVE` | In progress; no accepted result is represented | No G2A package on evidence `main` at revision-1 creation |
| Product | G2B-PRE | `ACCEPTED` | C2H transport ABI, MMIO contract, and Linux transport-input contract frozen | Accepted evidence at `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`; architecture contract only |
| Product | G2B-IMPL | `BLOCKED` | `BLOCKED_RESOURCE_HEADROOM`; not offline-qualified | No G2B bitstream or hardware result; hardware `NOT_PROVEN` |
| Product | G2B-LUT0 | `ACCEPTED` | Plan B dual-profile resource architecture accepted | Evidence `PASS` at `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`; estimate is not qualification |
| Product | G2B-LUT1 | `PLANNED` | `READY` to implement reversible profiles | No source implementation has started in META-3 |
| Research | R0 | `ACCEPTED` | Causal-isolation design accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Research | R1 | lifecycle `ACTIVE`; execution state `HOLD` | Valid research context; no closure or product promotion | `RESEARCH_DIAGNOSTIC` preserves the diagnostic continuation path |
| Research | R2/R3 | lifecycle `PLANNED`; state `HOLD` | Resumable later; neither accepted nor complete | `RESEARCH_DIAGNOSTIC` must preserve R2/R3 observability |
| Linux Video | L0 | `PLANNED` | Planned architecture direction; no implementation status invented | Owner/Architect-planned input; no L0 package on evidence `main` |
| META | META-0 | `ACCEPTED` | Governance infrastructure accepted by the creation authorization only | `ACCEPTED_BY_CREATION_TASK`; no broader decision inferred |
| META | META-3 | `ACCEPTED` | Build-profile architecture authorization promoted | SSOT/meta only; no source, build, Vivado, DMA, or hardware action |

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
| PRODUCT profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; LUT hard gate `<=90%`, preferred `80–85%` |
| RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; PRODUCT functionality plus resumable research observability |
| Gen2 x1 implementation target | `FROZEN` | Required final configuration or better; hardware remains `NOT_PROVEN` |
| Sustained application payload `>= 288 MB/s/card` | `FROZEN` | Requirement remains `NOT_PROVEN` and not yet qualified |
| Application C2H payload | `PLANNED` | Not yet accepted |
| Record-to-AXI-stream data plane | `BLOCKED` | `BLOCKED_RESOURCE_HEADROOM`; not offline-qualified |
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
