# META-5 Expected Affected Files

## Pre-write guard

- `EXECUTING_ROLE`: `META_UPDATE_AGENT`
- `PROJECT_STATE_REV_AT_START`: `4`
- `EXPECTED_PROJECT_STATE_REV`: `4`
- `REVISION_MATCH`: `YES`
- `AUTHORIZATION_LITERAL_PRESENT`: `YES`
- `OWNER_ARCHITECT_DECISION_VERIFIED`: `YES`
- `EVIDENCE_COMMIT_VERIFIED`: `YES`
- `EVIDENCE_DIRECTORY_VERIFIED`: `YES`
- `UPDATE_TYPE`: `ARCHITECTURE_CHANGE`
- `META4R2_PRECEDENT`: `VERIFIED`
- `MINIMAL_AFFECTED_FILE_COUNT`: `16`

The current frozen policy does not hard-code a 16-file count. It requires the
mandatory bookkeeping set plus only domain files actually affected by the
accepted decision. META-5 has the same governed architecture-change
propagation footprint as successful META-4R2, and each path below was
individually validated before any SSOT edit.

| Path | Exists | Bytes | Current SHA-256 | Reason for change | Exact section/field expected to change |
|---|---:|---:|---|---|---|
| `project-current-state/ACTIVE_BASELINES.md` | YES | 8735 | `B39F9D0D97394A055A5A4CC6C8A5069DDEA8F6430243BA3CF242090A16D47102` | Mirror the accepted Group-13 method and recovery boundary. | Revision header; Accepted G2B baselines table; sign-off/recovery boundary. |
| `project-current-state/CHANGELOG.md` | YES | 13594 | `57347376C41A67CAA25CBF0F82FA48A1C5F943AEFE1A13A270945DC9BBF8A73B` | Append the single revision-5 transaction record without rewriting history. | New `PROJECT_STATE_REV 5` entry only. |
| `project-current-state/COMPATIBILITY_MATRIX.csv` | YES | 11031 | `71305EF08AB1176204996129B82223358C15F8E6CB8A775DFC2C4A98904EF355` | Synchronize the affected G2B implementation and hardware consumer actions. | `Future G2B implementation` and `Future G2B hardware` rows only. |
| `project-current-state/CURRENT_ARCHITECTURE.md` | YES | 13340 | `93DB72A21AF3A49EDCE05D88EC1B677A4FC8C679622CA8FAD2CD225D1E9715D8` | Promote the reset-return mailbox architecture and Group-13 sign-off method. | Revision; lifecycle matrix; Group-13 reset-return subsection; frozen invariants and next step. |
| `project-current-state/CURRENT_INTERFACES.md` | YES | 19230 | `7F617C35591CB9FD6F6B6FCA74F20E4274503025AF5099E82CA4E342FF15BA94` | Record the held reset-return interface/CDC contract and replacement boundary. | Revision; Group-13 reset-return CDC sign-off subsection. |
| `project-current-state/CURRENT_REQUIREMENTS.md` | YES | 13094 | `B147C590EF79F835570B84F70F26951B42EDFFA7B47A392C7196CDF5DA6D5E85` | Make the accepted Group-13 conjunction the current required sign-off. | Revision; hard-requirement matrix; governed Group-13 recipe and continuation. |
| `project-current-state/CURRENT_RESOURCE_STATE.md` | YES | 5567 | `1979C81C052D4D9C9DDB634416A301BCC1CAD065CE1445985C0D17A0BB6CD0EC` | Synchronize sign-off-recovery readiness without changing resource evidence. | Revision; profile/sign-off recovery row; META-5 non-resource-change boundary. |
| `project-current-state/CURRENT_STATUS.md` | YES | 8039 | `2605BE340220F196FCFE2AA6639F9783CFA763844E08E20B9AAA46C8A9A9D6F3` | Mirror current META, Group-13, G2B-LUT1, and G2B-HW state. | Revision; snapshot; track/gate table; Group-13 state and evidence boundaries. |
| `project-current-state/CURRENT_TRACKS.md` | YES | 6932 | `C66816642805C09B37578C70BAB347DFCFCBDF0692D8C249D6FAB7A724E7E374` | Advance only the governed Product/META continuation point. | Revision; track summary; G2B-LUT1/META state; recovery-2 continuation recipe. |
| `project-current-state/EVIDENCE_MAP.md` | YES | 24032 | `05E9C433670A65E9D8AD4A4BFDEE4434E579CA79195BF035B0D0C916328219ED` | Add immutable G13-A provenance and revision-5 statement mappings. | Revision/acceptance authority; G13-A package entry; Group-13/decision/continuation statements. |
| `project-current-state/GOVERNANCE.md` | YES | 8206 | `8AA0960BF846F497502EF1482BF0E63DB4C1CF4CA4D6CA3CAA2768A93A11E930` | Synchronize the factual governed revision pointer only. | `Project-state revision governed` only. |
| `project-current-state/OPEN_DECISIONS.md` | YES | 10540 | `A8BD141EB3C9FD49D61FD8B7C2394DE4FEDA0EDD57618C7CA44AE6697566FBEA` | Record the resolved Group-13 decision without inventing an OD number. | Revision; unnumbered governed decisions table and Group-13 explanation; existing OD rows untouched. |
| `project-current-state/PROJECT_STATE.json` | YES | 41486 | `37261A49F676773830EC1E890BF0A45CDEAD925F5291864E74952E2F56DE78BD` | Apply the authoritative machine-state transaction. | Transaction metadata; Product/META continuation; Group-13 requirement/sign-off object; implementation/hardware provenance; decided decision; evidence reference. |
| `project-current-state/README.md` | YES | 6230 | `EAB9DC736C2229088E762499DDA5F111ED901F2FEF55C1D68C59DDEFA1F66166` | Synchronize the SSOT index and current snapshot. | Revision metadata/decision basis; snapshot rows; META-5 summary. |
| `project-current-state/SHA256_MANIFEST.txt` | YES | 1530 | `BDA7C92947F212BB18AF60738F7AA5974C097AAFD93E90D8E8FBA9BA6F5C39A3` | Regenerate integrity identities for all 18 non-self SSOT files. | Entire sorted 18-entry manifest. |
| `project-current-state/TRACK_STATUS.json` | YES | 8243 | `F07477D398C0D3A926774A16C1CFC029A334771BF3326064F01822AC6A4C3C8E` | Synchronize the machine-readable Product/META and Group-13 state. | Transaction metadata; Product next gate; G2B-LUT1/G2B-HW; Group-13 sign-off object; META task. |

No other path under `project-current-state/` is authorized for modification.
The pre-write SHA-256 values above exactly match the post-META-4R2 state and
the current verified 18-entry SSOT manifest.
