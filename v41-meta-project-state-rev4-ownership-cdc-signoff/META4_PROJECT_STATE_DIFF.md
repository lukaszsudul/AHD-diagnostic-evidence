# META-4R2 Project-State Difference

## Semantic transition

| State element | Revision 3 | Revision 4 |
|---|---|---|
| `PROJECT_STATE_REV` | `3` | `4` |
| Group-9 required method | Global `GLOBAL_SET_BUS_SKEW_3NS` history had not been dispositioned in SSOT | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` promoted |
| Global Group-9 bus-skew method | Undispositioned current-history reference | `RETIRED_FROM_REQUIRED_SIGNOFF` |
| Ownership decision record | No registered OD and no decided record | Named `UNNUMBERED_GOVERNED_DECISION`, `RESOLVED` |
| G2B-LUT1 readiness | `READY` | `READY_FOR_SIGNOFF_RECOVERY` |
| Product next gate | `G2B-LUT1` | `G2B-LUT1-SIGNOFF-RECOVERY` |
| G2B-HW lifecycle | `PLANNED` | `BLOCKED` |
| Active XDC | Unchanged | Unchanged; update authorized for next step only |
| Groups 10–17 | Existing requirements | `UNCHANGED` |

## Authorized file effects

| Path | Scoped effect |
|---|---|
| `project-current-state/ACTIVE_BASELINES.md` | Revision and live G2B/Group-9 baseline summary. |
| `project-current-state/CHANGELOG.md` | One append-only revision-4 entry. |
| `project-current-state/COMPATIBILITY_MATRIX.csv` | Two affected G2B rows only. |
| `project-current-state/CURRENT_ARCHITECTURE.md` | Ownership CDC architecture and Group-9 recipe. |
| `project-current-state/CURRENT_INTERFACES.md` | Stable-data mailbox interface/sign-off contract. |
| `project-current-state/CURRENT_REQUIREMENTS.md` | Frozen Group-9 requirement and recovery recipe. |
| `project-current-state/CURRENT_RESOURCE_STATE.md` | Readiness mirror; no resource result changed. |
| `project-current-state/CURRENT_STATUS.md` | Current readiness, Group-9, META, and hardware state. |
| `project-current-state/CURRENT_TRACKS.md` | Product/META next gates; R-track preserved. |
| `project-current-state/EVIDENCE_MAP.md` | BS1R/BS2/BS3 and statement provenance. |
| `project-current-state/GOVERNANCE.md` | Revision pointer only. |
| `project-current-state/OPEN_DECISIONS.md` | Named unnumbered decided record; all OD entries preserved. |
| `project-current-state/PROJECT_STATE.json` | Authoritative machine-state update. |
| `project-current-state/README.md` | Current snapshot and revision mirror. |
| `project-current-state/SHA256_MANIFEST.txt` | 18-entry integrity regeneration. |
| `project-current-state/TRACK_STATUS.json` | Machine-readable track/gate mirror. |

The frozen `UPDATE_POLICY.md`, `META_UPDATE_TEMPLATE.md`, and
`STATE_SCHEMA.md` are unchanged. FPGA_AHD source, RTL, active XDC, branch
refs, R-track, Vivado state, bitstream state, and hardware state are not
modified.
