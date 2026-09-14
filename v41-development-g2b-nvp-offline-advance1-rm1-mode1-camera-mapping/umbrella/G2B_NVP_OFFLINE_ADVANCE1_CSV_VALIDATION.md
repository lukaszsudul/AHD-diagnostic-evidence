# G2B-NVP-OFFLINE-ADVANCE1 CSV validation

The five requested CSV artifacts were imported independently with the bundled
spreadsheet runtime. Every file parsed into one rectangular data sheet with a
non-empty, unique header row.

| Artifact | Data rows | Columns | SHA-256 |
|---|---:|---:|---|
| `workstream-b-mode1/G2B_NVP_MODE1_CLEANROOM_NO_ACP_OPERATION_MANIFEST.csv` | 176 | 21 | `20E3AB5A78399184B2C56C59D0287E016DA827FBD57F43EB96F755FFA5B24926` |
| `workstream-b-mode1/G2B_NVP_MODE1_FAILURE_INJECTION_MATRIX.csv` | 1211 | 9 | `4BB59BACE5C4016F280EC74826596A784185C01DB3BE896A7A5BE51B77D3D7A2` |
| `workstream-b-mode1/G2B_NVP_MODE1_FOCUSED_24_TEST_RESULTS.csv` | 24 | 5 | `AFBB71B790DAD3C5232CFBA084D361619CF5EF0F241581B6A143A144959EE194` |
| `workstream-b-mode1/G2B_NVP_MODE1_TOUCHED_REGISTER_RECOVERY_MATRIX.csv` | 113 | 17 | `9E4364C011A189614819226656B32EA67F465BD235FFE92B93681A9C2D3AD750` |
| `workstream-c-camera-map/G2B_NVP_CAMERA_CONNECTOR_TO_VIN_MAP.csv` | 4 | 30 | `713A43E6ED599EFC6220CCCCBAD7358C0B4F0AA26FE4344C71E615344E79D4CB` |

`ARTIFACT_TOOL_CSV_IMPORT = PASS_5_OF_5`

`CSV_HEADER_UNIQUENESS = PASS_5_OF_5`

`CSV_EXPECTED_ROW_COUNTS = PASS_5_OF_5`

This receipt does not upgrade any engineering authority. In particular, the
MODE1 recovery and initial-EQ blockers and the physical connector-mapping gap
remain unchanged.
