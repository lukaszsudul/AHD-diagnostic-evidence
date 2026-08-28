# R2 Evidence Index — Owner-Mediated Continuation

## Published evidence files

| File | Purpose | Status |
|---|---|---|
| `README.md` | Package overview and sealed outcome | COMPLETE |
| `R2_CAUSAL_HARDWARE_REPORT.md` | Engineering and scientific narrative | COMPLETE |
| `R2_RUN_MATRIX.csv` | Frozen 32-run order joined to 10 results and 22 explicit not-run rows | COMPLETE |
| `R2_RAW_RESULTS.csv` | Byte-identical copy of the ten append-only raw result rows | COMPLETE |
| `R2_STATISTICAL_SUMMARY.md` | Descriptive stopped-prefix summary and blocked scientific disposition | COMPLETE |
| `PRIMARY_CAMPAIGN_BLOCKER_SUMMARY.md` | Exact frozen halt and required disposition | COMPLETE |
| `R2_COLD_START_10X.csv` | Explicit 0/10 `NOT_RUN` cold-start ledger | COMPLETE |
| `R2_INIT_DONE_TIMING.csv` | Explicit timing `NOT_RUN` record | COMPLETE |
| `R2_HARDWARE_LOCK_RECEIPT.md` | Compatibility receipt documenting Owner authority in place of software lock | COMPLETE |
| `R2_COLD_RESET_BASELINE_RECEIPT.md` | Entry-state and initial/final Formal baseline evidence | COMPLETE |
| `R2_RUNTIME_IDENTITY_RECEIPT.md` | Exact C0/C1/C2/C3 and final Formal runtime identity | COMPLETE |
| `R2_STATE.json` | Machine-readable halted state | COMPLETE |
| `R2_OWNER_DUT_EXCLUSIVITY_RECEIPT.md` | Exact Owner exclusivity declaration | COMPLETE |
| `R2_OWNER_INTERACTION_LOG.md` | Owner authority and final release interactions | COMPLETE |
| `R2_OWNER_MEDIATED_CONTROL_REPORT.md` | Human authority and manual-reset control report | COMPLETE |
| `R2_PUBLICATION_AND_RELEASE_RECEIPT.md` | Initial remote publication proof and subsequent exclusivity release | COMPLETE |
| `R2_MANUAL_COLD_RESET_RECEIPTS/README.md` | Explicit zero-receipt statement | COMPLETE |
| `audit/` | Hash-bound campaign configuration, ledger, append-only tables, halt, final Formal receipts, and ten candidate-capture receipts | COMPLETE |
| `R2_SHA256_MANIFEST.txt` | SHA-256 for every other file in this directory | GENERATED LAST; excludes itself |

The manifest excludes itself to avoid a recursive self-hash.

## Immutable source evidence

The publication report was derived from the following sealed local evidence. Paths are relative to the continuation staging root unless otherwise stated.

| Source evidence | SHA-256 | Evidentiary role |
|---|---|---|
| `R2_OWNER_DUT_EXCLUSIVITY_RECEIPT.md` | `2DEC89DBC82EBE4361288BBC1557766C2225162BD86C63ADA56F38A5B06BE002` | Owner authority |
| `R2_OWNER_INTERACTION_LOG.md` | `2D50A6393174FE4D27C1084697069096630BDC1B7917426FEC78D256555976DF` | Original chat interaction log |
| `R2_CONTINUATION_ENTRY_STATE_RECEIPT.md` | `308E013E316902A554DD324949F8C986A82DD01A453CE9EA3749792C2F9D6DE5` | Cold-reset entry state |
| `R2_ARTIFACT_IDENTITY_RECEIPT.md` | `2833701B89BE55CE96B953705395CDB0429B022701493811A1E6426EC0C3C35D` | Frozen bitstream identity |
| `controls/SAFE_FORMAL_BASELINE_BASELINE_FORMAL_001.txt` | `F4A9252E2901A7B2CE943F85544B474F51D51BBBCE44EBBB639D9F3E4B8B7B67` | Initial safe baseline |
| `audit/R2_PRIMARY_CAMPAIGN_CONFIGURATION.txt` | `9470F8314BA040E29FDEC7AC48DAE6BE843488634CBE9539A978A5E9FCCA682F` | Campaign configuration |
| `R2_RUN_MATRIX.csv` | `019695FCC3A0AAD9B9E8A295428010A2C916C03DD5D378369DD032C6E8AA9B3A` | Normalized 32-run order and halted execution state |
| `audit/R2_PRIMARY_RUN_COMPLETIONS_APPEND_ONLY.csv` | `E3A2B5A52B10D4140FDBB0D5E620EEDE09A0698F402E354F3EBE45E70F9C9D7B` | Ten committed-run outcomes |
| `audit/R2_PRIMARY_RAW_RESULTS_APPEND_ONLY.csv` | `A4A55541D1457202D490C3F7855810B0C79049984FE991CDCF306D648F8189A0` | Raw tabular telemetry |
| `audit/R2_PRIMARY_CAMPAIGN_LEDGER.jsonl` | `AA110E907571C9C1CD6E1B454A5284315C816C7507AC02E0DFE512342ADB1914` | 227-event append-only hash chain |
| `audit/R2_PRIMARY_CAMPAIGN_HALT.txt` | `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B` | Frozen C3 suspension |
| `audit/SAFE_FORMAL_BASELINE_RECEIPT_SEQ10.txt` | `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF` | Final safe state after sequence 10 |
| `audit/FINAL_LIVE_FORMAL_READBACK_RECEIPT.txt` | `57D0BA961EE73C2B89574B04FF5ED19782F4EE0FA909A47C7DA005F181EAD49A` | Final pre-publication live Formal identity |
| `audit/run_capture_receipts/` | Per-file hashes in `R2_RAW_RESULTS.csv` and the package manifest | Ten exact candidate telemetry captures |

## Frozen artifact identities

| Role | SHA-256 |
|---|---|
| Formal Phase-2 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` |
| C0 exact R1h | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` |
| C1 R1i-a | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` |
| C2 R1i-b | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` |
| C3 exact R1i | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |

## Finalization sequence

The package is published under `v41-research-r2-r1i-causal-hardware-owner-mediated-continuation-halted-20260828`. Finalization followed this order:

1. assemble and validate the stopped-prefix package without changing source classifications;
2. reread SSOT read-only (`PROJECT_STATE_REV_AT_END=1`, staleness `NONE`);
3. create the manifest, commit, push, and remotely read back the initial package;
4. explicitly release Owner-mediated DUT exclusivity in chat;
5. record the release, regenerate the manifest, commit, push, and remotely read back the final package.
