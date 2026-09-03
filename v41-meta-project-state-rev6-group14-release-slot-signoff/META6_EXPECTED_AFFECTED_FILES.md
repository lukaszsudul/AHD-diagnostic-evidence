# META-6 Expected Affected Files

## Pre-write guard

- `EXECUTING_ROLE`: `META_UPDATE_AGENT`
- `PROJECT_STATE_REV_AT_START`: `5`
- `EXPECTED_PROJECT_STATE_REV`: `5`
- `REVISION_MATCH`: `YES`
- `AUTHORIZATION_LITERAL_PRESENT`: `YES`
- `OWNER_ARCHITECT_DECISION_VERIFIED`: `YES`
- `EVIDENCE_COMMIT_VERIFIED`: `YES`
- `EVIDENCE_DIRECTORY_VERIFIED`: `YES`
- `UPDATE_TYPE`: `ARCHITECTURE_CHANGE`
- `META5_PRECEDENT`: `VERIFIED`
- `META4R2_PRECEDENT`: `VERIFIED`
- `MINIMAL_AFFECTED_FILE_COUNT`: `16`

The frozen policy does not hard-code a 16-file count. It requires the
mandatory bookkeeping set plus only domain files actually affected by the
accepted decision. META-6 has the same governed architecture-change
propagation footprint as successful META-5 and META-4R2, and each path below
was individually validated before any SSOT edit.

| Path | Exists | Bytes | Current SHA-256 | Reason for change | Exact section/field expected to change |
|---|---:|---:|---|---|---|
| `project-current-state/ACTIVE_BASELINES.md` | YES | 10350 | `E9A61272556F4DC9AB607484D9817AD23448F2F3DAE314E211F7AB7ED810E9C2` | Mirror the accepted Group-14 method and recovery boundary. | Revision header; accepted G2B baselines table; Group-14 method/evidence; recovery-3 boundary. |
| `project-current-state/CHANGELOG.md` | YES | 18458 | `6E29FB857EEE01879B825C0DA4204F7CD81620F07F9B9764E65332A6BFDA2FAC` | Append the single revision-6 transaction record without rewriting history. | New `PROJECT_STATE_REV 6` entry only. |
| `project-current-state/COMPATIBILITY_MATRIX.csv` | YES | 11474 | `42869091AA09E375C7F91BFD4AAE596CAE6F0FC5693194F4D8EAEB19F40CF13B` | Synchronize affected G2B implementation and hardware consumer actions. | `Future G2B implementation` and `Future G2B hardware` rows only. |
| `project-current-state/CURRENT_ARCHITECTURE.md` | YES | 17464 | `BE75772E617A9AA3B4CD4ED4950144E365F4EA31631868B61486338AD3A195ED` | Promote release-slot architecture and Group-14 sign-off method. | Revision; lifecycle matrix; Group-14 subsection; invariants and next step. |
| `project-current-state/CURRENT_INTERFACES.md` | YES | 21876 | `4A4C6BC526E2CD4220A5BA90CD1DD65DB62E4850BF1DC5A11249162FED1C919F` | Record the held token, qualifier CDC, and release/reset use contract. | Revision; Group-14 release-slot CDC sign-off subsection. |
| `project-current-state/CURRENT_REQUIREMENTS.md` | YES | 16278 | `E90F12A8B8BF33FADAF907A57EC4D431821E6F418026F9EAB83DD81537FACCA8` | Make the accepted Group-14 conjunction current required sign-off. | Revision; hard-requirement matrix; governed Group-14 recipe and continuation. |
| `project-current-state/CURRENT_RESOURCE_STATE.md` | YES | 5794 | `7C1B671CE1B23CE8E08CB70076C7A890DD6362C28CA9B5188FF72EE6E586F6CE` | Synchronize recovery readiness without changing resource evidence. | Revision; profile/sign-off-recovery row; META-6 no-resource-change boundary. |
| `project-current-state/CURRENT_STATUS.md` | YES | 9114 | `FF5F6801EB841B67CCD9BC19CCC877D42BD29EC2242C60AF19095E6554C1742C` | Mirror current META, Group-14, G2B-LUT1, and G2B-HW state. | Revision; snapshot; track/gate table; Group-14 state and evidence boundaries. |
| `project-current-state/CURRENT_TRACKS.md` | YES | 7616 | `D98FF6D7CB0C234A331315944510B7074E4E7B4BC6CD3C793E9B4803A14297D7` | Advance only the governed Product/META continuation point. | Revision; track summary; G2B-LUT1/META state; recovery-3 recipe. |
| `project-current-state/EVIDENCE_MAP.md` | YES | 27114 | `FB0BBA27C74AED968923807A1F6663E8D9BBD28ED9CC062DA6657281C87E12BD` | Add immutable G14-A provenance and revision-6 statement mappings. | Revision/acceptance authority; G14-A package entry; Group-14/decision/continuation statements. |
| `project-current-state/GOVERNANCE.md` | YES | 8206 | `4C46A89982F0B2F1C2096AC9E4ACD0585C18AAE9DAD65F19E36518F349794A3E` | Synchronize the factual governed revision pointer only. | `Project-state revision governed` only. |
| `project-current-state/OPEN_DECISIONS.md` | YES | 11973 | `158886B22748888664114A350CDAAED5EFB6DE7AE709CFC98C774C90459C6609` | Record resolved Group-14 decision without inventing an OD number. | Revision; new unnumbered governed decision section; every existing OD row untouched. |
| `project-current-state/PROJECT_STATE.json` | YES | 50481 | `720E0B7DB54D7899B33F9829F2BA6CFDC19D8A1F9E0ED7F9694624CE2E37F2B8` | Apply the authoritative machine-state transaction. | Transaction metadata; Product/META continuation; Group-14 requirement/sign-off object; implementation/hardware provenance; decided decision; evidence reference. |
| `project-current-state/README.md` | YES | 6829 | `B6965D2DCB5A1FDA4619C7B457B8C680E1B98A508B3A2EE90A0B8935BC7BF1D7` | Synchronize SSOT index and current snapshot. | Revision metadata/decision basis; snapshot rows; META-6 summary. |
| `project-current-state/SHA256_MANIFEST.txt` | YES | 1530 | `6515CDC8553103D08CCFE7EE57301154198CBD4A8A24D62C10D6EA36F328CC6B` | Regenerate integrity identities for all 18 non-self SSOT files. | Entire sorted 18-entry manifest. |
| `project-current-state/TRACK_STATUS.json` | YES | 10280 | `D3D85AE591A92B3F2D760B12B4AA1785BD6BF2AB8FBD9B94ADF099B7554E3211` | Synchronize machine-readable Product/META and Group-14 state. | Transaction metadata; Product next gate; G2B-LUT1/G2B-HW; Group-14 sign-off object; META task. |

No other path under `project-current-state/` is authorized for modification.
The pre-write SHA-256 values above exactly match the post-META-5 state and the
current verified 18-entry SSOT manifest. In particular,
`UPDATE_POLICY.md`, `META_UPDATE_TEMPLATE.md`, and `STATE_SCHEMA.md` are not
authorized to change.
