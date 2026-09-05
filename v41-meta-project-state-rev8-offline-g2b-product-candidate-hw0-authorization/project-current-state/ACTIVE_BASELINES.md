# AHD Active Baselines and Working Identities

`PROJECT_STATE_REV = 8`

This page distinguishes accepted/frozen baselines from active or provisional
working branches. Branch existence is provenance; it does not confer
acceptance.

## Qualified FPGA baseline — R1i

| Field | Verified value |
|---|---|
| Name | `R1i` |
| Lifecycle status | `ACCEPTED` |
| Preservation status | `FROZEN` |
| Scope | `QUALIFIED_POC_BASELINE` |
| Source repository | `lukaszsudul/FPGA_AHD` |
| Preservation branch | `baseline/v41-r1i-qualified-poc` |
| Historical commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Qualified tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Annotated tag | `v41-r1i-qualified-poc-20260827` |
| Tag object | `f7847a259dbe43bf99fa6d6515ed85131fafffc0` |
| Qualified bitstream SHA-256 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| LFS object size | `2,192,144 bytes` |
| Scientific result | `THESIS_CONFIRMED` |
| Frozen outcome | `STRONG_PASS` |
| Exact causal mechanism | `INCONCLUSIVE` |
| Production qualification | `NOT_CLAIMED` |
| Accepted by role | `OWNER_ARCHITECT` |

Verification at META-0 execution established that the remote preservation
branch and peeled annotated tag resolve to the historical commit, and that the
commit's tree is the qualified tree. The public evidence LFS pointer identifies
the bitstream by the exact SHA-256 above. The source commit itself does not
contain the bitstream bytes.

Authoritative evidence path:
`v41-nvp-r1i-r2-qualified-poc-hardware-evidence` at final path commit
`955ba0cd2462f4dec9dcb086175ab6eca57365bb`.

### Proven behavior

- R1i: autonomous-init NACK = 0, `INIT_ERROR = 0`, video present.
- R1h control: autonomous-init NACK = 4, `INIT_ERROR = 1`, video absent.
- Post-init: 60,000 of 60,000 selected-phase observations captured.
- Scope remains qualified PoC; exact causality and production qualification
  are not claimed.

## Primary XDMA donor

| Field | Verified value |
|---|---|
| Lifecycle status | `FROZEN` |
| Role | `PRIMARY_XDMA_DONOR` |
| Branch | `v41/xdma-v40.1.0-base` |
| HEAD | `c89e88bcdf389614c884fb129e8b2d42a585bccb` |
| Tree | `417820c69c134161fcafae0947dc5976919814d1` |
| Annotated tag | `v41-xdma-primary-donor-g0-20260827` |
| Tag object | `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` |
| Current link | `PCIe Gen1 x1` |
| Accepted role | Proven endpoint/control-plane donor |
| Final throughput role | Not the final v41 throughput configuration |

The donor proves endpoint enumeration, XDMA driver load, BAR discovery,
AXI-Lite identity/status/scratch behavior, one C2H interface, and the
control-plane substrate. Application C2H is tied inactive and is not proven.

G1 establishes that qualified R1i already inherits the required donor
endpoint/control-plane substrate; future integration starts from R1i rather
than merging this donor over it.

Evidence:
`v41-development-g0-baseline-freeze` at
`b5efb25082d7d18c8e022142e2303fd8a7bc3c6d` and
`v41-development-g1-integration-architecture` at
`f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd`.

## Secondary XDMA donor

| Field | Verified value |
|---|---|
| Lifecycle status | `FROZEN` for provenance identity |
| Branch | `dev/v41-xdma-offline-next` |
| HEAD | `8464af66611f7c22b8a36a4aab915d598eedda3f` |
| Tree | `4bf1988785baf4bae46bdfaf5bb12d0d25f26e68` |
| Role | `PROVENANCE_HARDENING_ONLY` |
| Adoption state | `PROVISIONAL`; review required before adoption |

This branch is not an alternative functional baseline. No separate hardware
run qualifies it.

## Active integration context

| Branch / work context | HEAD at META-0 audit | Status | Authority boundary |
|---|---|---|---|
| `integration/v41-r1i-gen2-g2a` | `22f15a6befe911172073e46a95d50b53afe1fc33` | `ACTIVE` | Local linked-worktree branch; no upstream or matching advertised remote ref; not accepted |
| G2A evidence package | none on evidence `main` at `f1258ba...` | `ACTIVE` | Absence of package does not negate Owner-declared in-progress state; no result promoted |

The observed integration head is a direct child of R1i with subject
`Integrate qualified R1i with Gen2 x1 for G2A offline build`. Its presence
does not establish a build result or acceptance. META-0 did not inspect,
modify, build, or otherwise interfere with the active G2A worktree.

## Accepted G2B contract and resource-architecture baselines

| Field | Current accepted value |
|---|---|
| Lifecycle status | `ACCEPTED` |
| Scope | `ARCHITECTURE_CONTRACT_FREEZE_ONLY` |
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, `FROZEN_FOR_G2B` |
| G2B MMIO contract | `FROZEN`, `0x3800..0x3BFF` |
| Linux consumer contract | `FROZEN_INPUT_CONTRACT` for transport parsing only |
| G2B-PRE contract-input readiness | `READY`; this is historical interface readiness, not current G2B-IMPL readiness |
| G2B-HW | `PLANNED`; `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; candidate available; hardware NOT_PROVEN |
| Evidence | `v41-development-g2b-pre-c2h-abi-mmio-freeze` at `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| G2B-LUT0 | `ACCEPTED`; resource-architecture review only |
| Build profiles | PRODUCT offline-qualified; RESEARCH_DIAGNOSTIC post-G2B qualification not promoted |
| PRODUCT resource policy | LUT hard gate `<= 90%`; preferred target `80–85%`; estimated 84.192% is not qualification evidence |
| G2B-IMPL | Exact one-channel PRODUCT implementation accepted through `G2B-LUT1-SIGNOFF-RECOVERY-4`; hardware NOT_PROVEN |
| G2B-LUT1 | `ACCEPTED`; `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`; next gate `G2B-HW0-PRODUCT` |
| Retired Group-9 method | `GLOBAL_SET_BUS_SKEW_3NS`; `RETIRED_FROM_REQUIRED_SIGNOFF` for `OWNERSHIP_AXI_TO_SOURCE` |
| Current Group-9 method | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; `PROMOTED` |
| Ownership CDC basis | Two-stage request and acknowledgement synchronizers; held 58-bit stable-data payload; source hold until acknowledgement; reset/epoch coherency |
| Payload families and timing | 3 families: `slot`, `generation`, `epoch`; settling cap `6.000 ns`; minimum launch-to-use margin `13.468 ns`; gross reserve `7.468 ns` |
| Safety equivalence | `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; this is not a relaxation of safety |
| Group-9 disposition | Method remains `PROMOTED`; authoritative current result `PRESERVE_PASS`; do not repeat; `RTL_CHANGE_REQUIRED = NO`; the promotion-time boundary was `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`, with candidate `G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc` |
| Retired Group-13 method | `GLOBAL_SET_BUS_SKEW_3NS`; `RETIRED_FROM_REQUIRED_SIGNOFF` for `RESET_RETURN_SOURCE_TO_AXI`; historical scope 7 sources / 207 destinations |
| Current Group-13 method | `SETTLING_PLUS_STRUCTURAL_CDC`; `PROMOTED`; `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC` |
| Group-13 semantic families | 2: `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` and `RESET_COMMIT_PHASE_COMPLETION_BARRIER` |
| Group-13 timing requirement | `6.000 ns` absolute datapath-only settling for each family; retain the unchanged broad aggregate `6.000 ns` source-mailbox relation and its 79-cell supplemental commit-family coverage |
| Group-13 structural basis | Single-edge capture, stable until acknowledgement, two-stage request/acknowledgement synchronization, two-stage live commit-phase synchronization, commit-phase equality barrier, hard-episode qualification, and atomic reset epoch/state publication |
| Group-13 disposition | Method remains `PROMOTED`; authoritative recovery-2 result `PRESERVE_PASS`; do not repeat; `RTL_CHANGE_REQUIRED = NO`; the promotion-time boundary was `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`, with candidate `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` |
| Retired Group-14 method | `GLOBAL_SET_BUS_SKEW_3NS`; exact relation `set_bus_skew 3.000 -from $g2b_release0_payload_src -to $g2b_release_payload_dst`; `RETIRED_FROM_REQUIRED_SIGNOFF` for `RELEASE_SLOT_0_AXI_TO_SOURCE`; historical scope 56 sources / 20 destinations |
| Current Group-14 method | `SETTLING_PLUS_STRUCTURAL_CDC`; `PROMOTED`; `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC` |
| Group-14 semantic families | 3: `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`, `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, and `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING` |
| Group-14 timing requirement | `6.000 ns` absolute datapath-only settling for each family; validated worst actual/slack: `5.467/0.563 ns`, `5.554/0.478 ns`, and `4.191/1.839 ns`, respectively |
| Group-14 structural basis | Held 56-bit generation/epoch release token; same-edge token/toggle launch; two-stage release-toggle synchronization for normal use; two-stage transport-request synchronization for reset accounting; stable-data lifetime; fail-closed generation/epoch/ownership identity; captured release-phase retirement/completion barrier; destination-use ordering; reset/release coherency |
| Group-14 evidence disposition | `GROUP14_CDC_STRUCTURE = PASS_WITH_DISPOSITION`; `SIGNOFF_RUNTIME = PRACTICAL`; replacement `SAFER_AND_MORE_SEMANTICALLY_CORRECT` |
| HISTORICAL Group-14 promotion-time RTL/XDC disposition | `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from evidence commit `9e91315968453e859006077191cd5fc711fc6b96` |
| Offline sign-off completion | Groups 1–17 and final routed/pre-bitstream gates PASS; hardware separate |
| Ownership evidence | BS1R `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62`; BS2 `4699632c591238fee46ada3b0de37532fddd0b6f`; BS3 `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` |
| Reset-return evidence | `v41-development-g2b-g13a-reset-return-signoff-audit` at `10c7c2898d162af8e2262b3f99861c7d560c4557` |
| Release-slot evidence | `v41-development-g2b-g14a-release-slot0-signoff-audit` at `9e91315968453e859006077191cd5fc711fc6b96` |
| Resource evidence | `v41-development-g2b-lut0-resource-attribution` at `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` |

Earlier architecture-only boundaries remain historical. META-8A accepts the
exact source-bound offline PRODUCT candidate below. Hardware DMA, Gen2,
throughput and Linux/V4L2 are not qualified.

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



## Held research context

The R-track execution state is `HOLD`, not closed, cancelled, or superseded.
The branch identities below are unchanged historical working identities; this
META task does not move or modify them. R2/R3 resumability must be preserved by
the `RESEARCH_DIAGNOSTIC` profile.

| Branch / work context | HEAD at META-0 audit | Status | Authority boundary |
|---|---|---|---|
| `research/v41-r1i-causal-isolation` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `ACTIVE` | Local R1 umbrella branch; no upstream; research only |
| `research/v41-r1i-a` | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `PROVISIONAL` | Local implemented-unqualified candidate; not product baseline |
| `research/v41-r1i-b` | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | `PROVISIONAL` | Local implemented-unqualified candidate; not product baseline |
| R1 evidence package | none on evidence `main` at `f1258ba...` | `ACTIVE` | No execution result is represented or accepted |

The candidate branches are local-only at the audit point and have no matching
advertised remote refs. R1i-a/R1i-b are research-only. They may not replace or
modify the accepted product baseline without explicit Owner/Architect
promotion and a separate authorized META update.

## Source-repository audit anchor

The read-only primary source worktree was clean on `main` at
`be94f88ee8d179f12928ab791bdae27c22cd1762`, tree
`e128ff47a5e21e8131971f5e5caa7657e2eccc7f`. This is an audit context, not the
qualified v41 baseline.

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
