# AHD v41 Project Current State

> **THIS DIRECTORY DESCRIBES THE CURRENT ACCEPTED PROJECT STATE.**
>
> **READ GOVERNANCE.md AND UPDATE_POLICY.md BEFORE USING OR MODIFYING THIS STATE.**

`project-current-state/` is the authoritative current-state and architecture
single source of truth (SSOT) for AHD v41. It records project truth accepted by
the Owner/Architect, distinguishes that truth from execution evidence, and
identifies the exact evidence that supports each statement.

| Field | Value |
|---|---|
| Project | `AHD_v41` |
| `PROJECT_STATE_REV` | `8` |
| Governance version | `1` |
| State type | `CURRENT_ACCEPTED_STATE` |
| Last update | `2026-09-05` |
| Acceptance authority | `OWNER_ARCHITECT` |
| SSOT writer | `META_UPDATE_AGENT_ONLY` |
| Creation authorization | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` |
| Revision-8 decision basis | Exact offline PRODUCT candidate accepted; separate HW0-PRODUCT planned |

## Mandatory read before any work

Before starting any G-track, R-track, L-track, or META task, every agent must:

1. Read `README.md`.
2. Read `GOVERNANCE.md`.
3. Read `UPDATE_POLICY.md`.
4. Read `PROJECT_STATE.json`.
5. Read `TRACK_STATUS.json`.
6. Read `CURRENT_INTERFACES.md`.
7. Record `PROJECT_STATE_REV_AT_START` in its report.

At the end of the task, the agent must read the revision again, record
`PROJECT_STATE_REV_AT_END`, and apply the stale-state rule in
`GOVERNANCE.md`. A normal Gate Agent treats this directory as read-only.

## Current snapshot

| Area | Current project truth |
|---|---|
| Product | G2B-LUT1 `ACCEPTED`; `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`; G2B-HW `PLANNED / NOT_PROVEN` |
| Research | R-track state `HOLD`, not closed; R2/R3 remain resumable |
| Linux Video | L0 `PLANNED` |
| META | META-8A accepts the exact offline candidate and defines separate controlled hardware scope |
| Qualified FPGA baseline | R1i `ACCEPTED`; preservation identity `FROZEN` |
| PCIe product requirement | Gen2 x1 or better; sustained payload `>= 288 MB/s` per card |
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, `FROZEN_FOR_G2B` |
| G2B MMIO | `FROZEN`, `0x3800..0x3BFF` |
| Build profiles | PRODUCT offline-qualified; RESEARCH_DIAGNOSTIC post-G2B qualification not promoted |
| PRODUCT LUT policy | <=90% gate and 80–85% preferred target achieved offline: 83.490% |
| Group-9 ownership sign-off | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` promoted; `GLOBAL_SET_BUS_SKEW_3NS` retired from required sign-off |
| Group-9 timing basis | 3 families (`slot`, `generation`, `epoch`); `6.000 ns` settling cap; `13.468 ns` minimum launch-to-use; `7.468 ns` gross reserve |
| Group-13 reset-return sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` retired from required sign-off |
| Group-13 timing basis | 2 families (`RESET_ABANDONED_COUNT_STABLE_PAYLOAD`, `RESET_COMMIT_PHASE_COMPLETION_BARRIER`); `6.000 ns` absolute settling cap; unchanged broad aggregate `6.000 ns` relation retained |
| Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` retired from required sign-off for the historical 56-source/20-destination scope |
| Group-14 timing basis | 3 families (`RELEASE_SLOT0_NORMAL_STATE_TRANSITION`, `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`); `6.000 ns` absolute settling cap for each family |
| G2B implementation | Exact PRODUCT accepted offline; next gate `G2B-HW0-PRODUCT` |
| Active XDC change | Groups 15–17 implemented and signed off by Recovery-4; META-8A edits no XDC |
| G2B hardware qualification | `PLANNED`; `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; NOT_STARTED / NOT_PROVEN |
| Linux consumer contract | Frozen transport input; V4L2 remains `NOT_IMPLEMENTED` |

META-4R2 Group-9 and META-5 Group-13 truth remain promoted without regression.
META-6 promotes the G14-A Group-14 replacement as
`SAFER_AND_MORE_SEMANTICALLY_CORRECT`; this is not a relaxation of safety.
The method retains the held 56-bit generation/epoch release token, two-stage
release-toggle synchronization for ordinary use, two-stage transport-request
synchronization for reset-overlap accounting, stable-data lifetime, captured
release-phase retirement, destination-use ordering, and reset/release
coherency. `RTL_CHANGE_REQUIRED = NO`, Group 9 is `PRESERVE_PASS`,
`GROUPS_10_TO_12 = PRESERVE_PASS`, Group 13 is `PRESERVE_PASS`, and
`GROUPS_15_TO_17 = PROMOTED`. The retired global Group-9, Group-13,
and Group-14 `report_bus_skew` queries are not required again. The estimated
`PRODUCT` result of 17,512 LUT (84.192%) is still not qualification evidence.
Recovery-4 supplies the accepted exact PRODUCT source, active-XDC
implementation, final routed sign-off and bitstream. Hardware capture, V4L2,
Gen2 hardware qualification and measured 288 MB/s remain unproven. The R-track is on `HOLD`, not closed, cancelled,
or superseded.

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


## Truth model

- **EVIDENCE TRUTH** says what was executed, measured, built, or observed.
- **PROJECT TRUTH** says what the Owner/Architect explicitly accepted as the
  current project state.

The SSOT represents project truth. Evidence is cited as support, never treated
as automatic acceptance.

## Lifecycle labels

Only these project-state labels are valid:

`ACCEPTED`, `FROZEN`, `ACTIVE`, `PLANNED`, `PROVISIONAL`, `SUPERSEDED`,
`OPEN`, `BLOCKED`, `REJECTED`.

Evidence results and engineering maturity terms such as `PASS`, `STRONG_PASS`,
`THESIS_CONFIRMED`, `PROVEN`, `READY`, `NOT_IMPLEMENTED`, `NOT_STARTED`,
`NOT_PROVEN`, and `IMPLEMENTED_UNQUALIFIED` are separate classifications, not
lifecycle labels.

## Document map

| Document | Purpose |
|---|---|
| `GOVERNANCE.md` | Authority, roles, truth layers, revision control, staleness, and prohibitions |
| `UPDATE_POLICY.md` | Exact authorized update and publication procedure |
| `CURRENT_ARCHITECTURE.md` | End-to-end architecture with lifecycle and maturity boundaries |
| `CURRENT_STATUS.md` | Human-readable current gate and subsystem state |
| `ACTIVE_BASELINES.md` | Exact qualified, donor, integration, and research identities |
| `CURRENT_REQUIREMENTS.md` | Frozen requirements versus targets and qualification state |
| `CURRENT_INTERFACES.md` | Accepted/frozen interfaces, implementation boundaries, and later open contracts |
| `CURRENT_RESOURCE_STATE.md` | Qualified utilization and diagnostic-overhead interpretation |
| `CURRENT_TRACKS.md` | G, R, L, and META purposes, gates, decisions, and dependencies |
| `OPEN_DECISIONS.md` | Unresolved decisions that may not be invented by an agent |
| `COMPATIBILITY_MATRIX.csv` | Consumer-to-interface compatibility and action matrix |
| `TRACK_STATUS.json` | Machine-readable gate status |
| `PROJECT_STATE.json` | Main machine-readable project-state SSOT |
| `EVIDENCE_MAP.md` | Statement-to-evidence provenance |
| `STATE_SCHEMA.md` | Machine-readable field semantics and invariants |
| `META_UPDATE_TEMPLATE.md` | Required future META update authorization template |
| `CHANGELOG.md` | Append-only project-state revision history |
| `SHA256_MANIFEST.txt` | Integrity hashes for all other SSOT files |

## Modification warning

Only a META Update Agent may write this directory, and only when its task
contains the literal authorization `SSOT WRITE AUTHORIZED`, an explicit
Owner/Architect decision, an accepted evidence source, and the expected prior
`PROJECT_STATE_REV`. If any condition is absent, the agent must stop without
writing.

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
