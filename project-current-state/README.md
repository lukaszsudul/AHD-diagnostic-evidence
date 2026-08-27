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
| `PROJECT_STATE_REV` | `1` |
| Governance version | `1` |
| State type | `CURRENT_ACCEPTED_STATE` |
| Last update | `2026-08-28` |
| Acceptance authority | `OWNER_ARCHITECT` |
| SSOT writer | `META_UPDATE_AGENT_ONLY` |
| Creation authorization | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` |

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
| Product | G-1 `ACCEPTED`; G0 `ACCEPTED`; G1 `ACCEPTED`; G2A `ACTIVE` |
| Research | R0 `ACCEPTED`; R1 `ACTIVE` |
| Linux Video | L0 `PLANNED` |
| META | META-0 governance infrastructure `ACCEPTED`, solely by this creation task |
| Qualified FPGA baseline | R1i `ACCEPTED`; preservation identity `FROZEN` |
| PCIe product requirement | Gen2 x1 or better; sustained payload `>= 288 MB/s` per card |
| Transport ABI | `PROVISIONAL` |

G2A, R1, and L0 are not accepted implementation results. No execution `PASS`,
`THESIS_CONFIRMED`, or `BUILD_COMPLETE` result modifies this snapshot by
itself.

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
`THESIS_CONFIRMED`, `PROVEN`, and `IMPLEMENTED_UNQUALIFIED` are separate
classifications, not lifecycle labels.

## Document map

| Document | Purpose |
|---|---|
| `GOVERNANCE.md` | Authority, roles, truth layers, revision control, staleness, and prohibitions |
| `UPDATE_POLICY.md` | Exact authorized update and publication procedure |
| `CURRENT_ARCHITECTURE.md` | End-to-end architecture with lifecycle and maturity boundaries |
| `CURRENT_STATUS.md` | Human-readable current gate and subsystem state |
| `ACTIVE_BASELINES.md` | Exact qualified, donor, integration, and research identities |
| `CURRENT_REQUIREMENTS.md` | Frozen requirements versus targets and qualification state |
| `CURRENT_INTERFACES.md` | Accepted/frozen interfaces and explicitly provisional contracts |
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
