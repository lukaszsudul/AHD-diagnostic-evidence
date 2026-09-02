# META-4R2 Expected Affected Files

## Frozen-contract guard

- `EXECUTING_ROLE`: `META_UPDATE_AGENT`
- `PROJECT_STATE_REV_AT_START`: `3`
- `EXPECTED_PROJECT_STATE_REV`: `3`
- `REVISION_MATCH`: `YES`
- `AUTHORIZATION_LITERAL_PRESENT`: `YES`
- `OWNER_ARCHITECT_DECISION_VERIFIED`: `YES`
- `EVIDENCE_COMMIT_VERIFIED`: `YES`
- `EVIDENCE_DIRECTORY_VERIFIED`: `YES`
- `UPDATE_TYPE`: `ARCHITECTURE_CHANGE`
- `FROZEN_REISSUE_HEADER_SHA256`: `D7456D989F0D879B2E1FD8777876F5AE786947D789CE1D480CA720316AC7342B`

The following list is copied from the authoritative
`META4P_REISSUE_HEADER.txt`. It is the complete and minimal authorized SSOT
write set for this transaction. It was recorded before any SSOT file was
modified.

| Path | Exists before write | Authorized purpose |
|---|---:|---|
| `project-current-state/ACTIVE_BASELINES.md` | YES | Synchronize revision and accepted Group-9/G2B recovery baseline. |
| `project-current-state/CHANGELOG.md` | YES | Append the single revision-4 transaction record. |
| `project-current-state/COMPATIBILITY_MATRIX.csv` | YES | Synchronize only affected G2B implementation and hardware rows. |
| `project-current-state/CURRENT_ARCHITECTURE.md` | YES | Promote the accepted ownership CDC architecture and sign-off method. |
| `project-current-state/CURRENT_INTERFACES.md` | YES | Record the ownership mailbox interface/CDC contract. |
| `project-current-state/CURRENT_REQUIREMENTS.md` | YES | Replace the current Group-9 required sign-off method and preserve Groups 10-17. |
| `project-current-state/CURRENT_RESOURCE_STATE.md` | YES | Synchronize G2B-LUT1 recovery readiness without changing resource evidence. |
| `project-current-state/CURRENT_STATUS.md` | YES | Synchronize current G2B-LUT1 and G2B-HW governance states. |
| `project-current-state/CURRENT_TRACKS.md` | YES | Synchronize the Product and META track next gates. |
| `project-current-state/EVIDENCE_MAP.md` | YES | Add BS1R/BS2/BS3 provenance and revision-4 statement mappings. |
| `project-current-state/GOVERNANCE.md` | YES | Synchronize the governed project-state revision pointer only. |
| `project-current-state/OPEN_DECISIONS.md` | YES | Record the named unnumbered resolved Group-9 decision while preserving all OD-* entries. |
| `project-current-state/PROJECT_STATE.json` | YES | Update the authoritative machine-readable state and revision. |
| `project-current-state/README.md` | YES | Synchronize the SSOT summary and revision pointer. |
| `project-current-state/SHA256_MANIFEST.txt` | YES | Regenerate the frozen SSOT integrity manifest. |
| `project-current-state/TRACK_STATUS.json` | YES | Synchronize machine-readable track/gate state. |

No other SSOT path is authorized for modification.

Pre-write SHA-256 identities are recorded alongside their post-write
identities in `META4_EXACT_FILE_CHANGE_LEDGER.md`. They match the immutable
META-4P affected-file inventory at commit
`24be8a8c6eb227c548db130009ca495bfb472802`.
