# AHD Current Status

`PROJECT_STATE_REV = 1`
State type: `CURRENT_ACCEPTED_STATE`
Accepted by role: `OWNER_ARCHITECT`
Decision basis: `META-0_TASK_DIRECTIVE`

## Acceptance boundary

This page records project truth. Evidence packages report engineering and
scientific results, but those results do not confer acceptance. G-1, G0, G1,
and R0 are `ACCEPTED` because the Owner/Architect-approved META-0 input says
so. G2A and R1 remain `ACTIVE` even if execution evidence later reports
`PASS`. L0 remains `PLANNED`.

## Track and gate status

| Track | Gate | Status | Current meaning | Acceptance/evidence boundary |
|---|---|---|---|---|
| Product | G-1 | `ACCEPTED` | Existing-work inventory and reuse context accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G0 | `ACCEPTED` | Baseline and donor identities, requirements, and protected behavior accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G1 | `ACCEPTED` | Integration and C2H architecture accepted; G2 implementation allowed | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Product | G2A | `ACTIVE` | In progress; no accepted result is represented | No G2A package on evidence `main` at revision-1 creation |
| Research | R0 | `ACCEPTED` | Causal-isolation design accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Research | R1 | `ACTIVE` | In progress; research-only candidates do not alter product truth | No R1 package on evidence `main` at revision-1 creation |
| Linux Video | L0 | `PLANNED` | Planned architecture direction; no implementation status invented | Owner/Architect-planned input; no L0 package on evidence `main` |
| META | META-0 | `ACCEPTED` | Governance infrastructure accepted by the creation authorization only | `ACCEPTED_BY_CREATION_TASK`; no broader decision inferred |

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
| v41D transport ABI | `PROVISIONAL` | 4 KiB record plan exists; ABI not fully implementation-frozen |
| Gen2 x1 implementation target | `FROZEN` | Required final configuration or better; hardware not qualified |
| Sustained application payload `>= 288 MB/s/card` | `FROZEN` | Requirement; not yet qualified |
| Application C2H payload | `PLANNED` | Not yet accepted |
| Record-to-AXI-stream data plane | `PLANNED` | G2B scope; not yet accepted |
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

The current Gen1 x1 donor is a proven control-plane donor and is not the final
throughput configuration.

## Current Linux Video direction

Status is `PLANNED`: V4L2 frontend → AHD common video/capture core → transport
abstraction → XDMA first backend, with a possible later LitePCIe backend.
Standard `/dev/videoX` presentation, FFmpeg, GStreamer, OpenCV, multi-card
support, stable identity, and a future DMABUF/zero-copy path are goals, not
implemented product state.
