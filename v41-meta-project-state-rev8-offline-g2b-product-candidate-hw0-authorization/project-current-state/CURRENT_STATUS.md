# AHD Current Status

`PROJECT_STATE_REV = 8`
State type: `CURRENT_ACCEPTED_STATE`
Accepted by role: `OWNER_ARCHITECT`
Decision basis: historical accepted state plus explicit Owner/Architect
acceptance of exact Recovery-4 offline PRODUCT and separately planned
HW0-PRODUCT through META-8A

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
| Product | G2B-IMPL | `ACCEPTED` | Exact one-channel offline implementation via G2B-LUT1 | `G2B-LUT1-SIGNOFF-RECOVERY-4`; hardware NOT_PROVEN |
| Product | G2B-LUT0 | `ACCEPTED` | Plan B dual-profile resource architecture accepted | Evidence `PASS` at `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`; estimate is not qualification |
| Product | G2B-LUT1 | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` | All offline gates PASS; exact candidate only |
| Product | G2B-HW | `PLANNED` | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION` | NOT_STARTED / NOT_PROVEN; next `G2B-HW0-PRODUCT` |
| Research | R0 | `ACCEPTED` | Causal-isolation design accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
| Research | R1 | lifecycle `ACTIVE`; execution state `HOLD` | Valid research context; no closure or product promotion | `RESEARCH_DIAGNOSTIC` preserves the diagnostic continuation path |
| Research | R2/R3 | lifecycle `PLANNED`; state `HOLD` | Resumable later; neither accepted nor complete | `RESEARCH_DIAGNOSTIC` must preserve R2/R3 observability |
| Linux Video | L0 | `PLANNED` | Planned architecture direction; no implementation status invented | Owner/Architect-planned input; no L0 package on evidence `main` |
| META | META-0 | `ACCEPTED` | Governance infrastructure accepted by the creation authorization only | `ACCEPTED_BY_CREATION_TASK`; no broader decision inferred |
| META | META-3 | `ACCEPTED` | Build-profile architecture authorization promoted | SSOT/meta only; no source, build, Vivado, DMA, or hardware action |
| META | META-4R2 | `ACCEPTED` | Ownership CDC Group-9 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |
| META | META-5 | `ACCEPTED` | Reset-return CDC Group-13 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |
| META | META-6 | `ACCEPTED` | Release-slot CDC Group-14 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |

| META | META-7R | `ACCEPTED` | Combined Groups 15–17 release-slot methods promoted | Historical architecture promotion |
| META | META-8A | `ACCEPTED` | Exact PRODUCT offline candidate and separate HW0 scope accepted | SSOT only; hardware NOT_STARTED / NOT_PROVEN |

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

Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.

Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.

Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.


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
| G2B MMIO `0x3800–0x3BFF` | `FROZEN` | Contract frozen; exact PRODUCT registers accepted offline; hardware NOT_PROVEN |
| Linux transport consumer contract | `FROZEN` | Frozen input contract only; V4L2 architecture/implementation is not promoted |
| Group-9 `OWNERSHIP_AXI_TO_SOURCE` sign-off | `ACCEPTED` | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; old `GLOBAL_SET_BUS_SKEW_3NS` retired from required sign-off |
| Group-13 `RESET_RETURN_SOURCE_TO_AXI` sign-off | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC`; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-13 `report_bus_skew` retired from required sign-off |
| Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off (active-XDC literal is HISTORICAL at META-6 promotion; current result `PRESERVE_PASS`) | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-14 `report_bus_skew` retired from required sign-off; `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` |
| PRODUCT profile | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`; LUT 83.490% meets hard gate/preferred band |
| RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; PRODUCT functionality plus resumable research observability |
| Gen2 x1 implementation target | `FROZEN` | Required final configuration or better; hardware remains `NOT_PROVEN` |
| Sustained application payload `>= 288 MB/s/card` | `FROZEN` | Requirement remains `NOT_PROVEN` and not yet qualified |
| Application C2H payload | `ACCEPTED` | Exact one-channel candidate offline only; hardware NOT_PROVEN |
| Record-to-AXI-stream data plane | `ACCEPTED` | One-channel PRODUCT offline-qualified; hardware NOT_PROVEN |
| G2B-HW | `PLANNED` | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; NOT_STARTED / NOT_PROVEN |
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
as a historical estimate. Actual Recovery-4 PRODUCT is 17,366 LUT / 83.490%;
the hard gate and preferred target are achieved offline.

## Current Linux Video direction

Status is `PLANNED`: V4L2 frontend → AHD common video/capture core → transport
abstraction → XDMA first backend, with a possible later LitePCIe backend.
`AHD_C2H_TRANSPORT_ABI_V1` is frozen as the Linux consumer's transport input.
Standard `/dev/videoX` presentation, FFmpeg, GStreamer, OpenCV, multi-card
support, stable identity, and a future DMABUF/zero-copy path remain goals;
V4L2 is `NOT_IMPLEMENTED`.

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
