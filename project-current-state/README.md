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
| `PROJECT_STATE_REV` | `6` |
| Governance version | `1` |
| State type | `CURRENT_ACCEPTED_STATE` |
| Last update | `2026-09-03` |
| Acceptance authority | `OWNER_ARCHITECT` |
| SSOT writer | `META_UPDATE_AGENT_ONLY` |
| Creation authorization | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` |
| Revision-6 decision basis | Accepted G14-A release-slot CDC architecture and promoted Group-14 sign-off method |

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
| Product | G2B-PRE and G2B-LUT0 `ACCEPTED`; G2B-IMPL remains `BLOCKED`; G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; G2B-HW `BLOCKED` |
| Research | R-track state `HOLD`, not closed; R2/R3 remain resumable |
| Linux Video | L0 `PLANNED` |
| META | META-6 promotes the release-slot CDC Group-14 sign-off architecture while preserving META-4R2 Group-9 and META-5 Group-13 truth; no RTL or active-XDC implementation |
| Qualified FPGA baseline | R1i `ACCEPTED`; preservation identity `FROZEN` |
| PCIe product requirement | Gen2 x1 or better; sustained payload `>= 288 MB/s` per card |
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, `FROZEN_FOR_G2B` |
| G2B MMIO | `FROZEN`, `0x3800..0x3BFF` |
| Build profiles | `PRODUCT` and `RESEARCH_DIAGNOSTIC`: `AUTHORIZED_NOT_IMPLEMENTED` |
| PRODUCT LUT policy | hard gate `<= 90%`; preferred target `80–85%`; target not yet measured or achieved |
| Group-9 ownership sign-off | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` promoted; `GLOBAL_SET_BUS_SKEW_3NS` retired from required sign-off |
| Group-9 timing basis | 3 families (`slot`, `generation`, `epoch`); `6.000 ns` settling cap; `13.468 ns` minimum launch-to-use; `7.468 ns` gross reserve |
| Group-13 reset-return sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` retired from required sign-off |
| Group-13 timing basis | 2 families (`RESET_ABANDONED_COUNT_STABLE_PAYLOAD`, `RESET_COMMIT_PHASE_COMPLETION_BARRIER`); `6.000 ns` absolute settling cap; unchanged broad aggregate `6.000 ns` relation retained |
| Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` retired from required sign-off for the historical 56-source/20-destination scope |
| Group-14 timing basis | 3 families (`RELEASE_SLOT0_NORMAL_STATE_TRANSITION`, `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`); `6.000 ns` absolute settling cap for each family |
| G2B implementation | G2B-LUT1 readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-3` |
| Active XDC change | `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; Group-14 candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc`; active production XDC unchanged |
| G2B hardware qualification | lifecycle `BLOCKED`; `NOT_STARTED`; `NOT_PROVEN` |
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
`GROUPS_15_TO_17 = PENDING_UNCHANGED`. The retired global Group-9, Group-13,
and Group-14 `report_bus_skew` queries are not required again. The estimated
`PRODUCT` result of 17,512 LUT (84.192%) is still not qualification evidence.
No profile source implementation, active XDC change, final routed sign-off,
G2B bitstream, hardware capture, V4L2 implementation, Gen2 qualification, or
288 MB/s result is claimed. The R-track is on `HOLD`, not closed, cancelled,
or superseded.

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
