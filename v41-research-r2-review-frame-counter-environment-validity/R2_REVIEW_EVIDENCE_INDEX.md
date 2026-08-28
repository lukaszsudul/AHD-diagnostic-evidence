# R2-REVIEW Evidence Index

## Required review artifacts

| File | Purpose |
|---|---|
| `README.md` | Scope, decision, and governance boundary |
| `R2_REVIEW_MAIN_REPORT.md` | Integrated engineering and scientific review |
| `R2_REVIEW_FRAME_RATE_MEASUREMENT_CHAIN.md` | Physical event through frozen classification, including source hashes |
| `R2_REVIEW_FRAME_RATE_RECALCULATION.csv` | Exact raw-monotonic recalculation for all ten observations |
| `R2_REVIEW_RUN_COMPARISON.csv` | Identity, environment, telemetry, reset, restore, and rate comparison |
| `R2_REVIEW_C3_DIRECT_COMPARISON.md` | Exact C3 sequences 3/8/10 comparison |
| `R2_REVIEW_ENVIRONMENT_CORRELATION.md` | Candidate/order/session/reset/recovery/window correlations |
| `R2_REVIEW_COUNTER_CDC_AUDIT.md` | Source-level frame-counter CDC/coherency audit |
| `R2_REVIEW_MEASUREMENT_MODEL.md` | Offline integer-event/window model and competing hypotheses |
| `R2_REVIEW_PROTOCOL_IMPACT.md` | Immutable-history and campaign-continuation impact |
| `R2_REVIEW_DECISION.md` | Formal review classification |
| `R2_REVIEW_STATE.json` | Machine-readable state at package seal |
| `R2_MEASUREMENT_PROTOCOL_AMENDMENT_PROPOSAL.md` | Candidate-neutral proposal marked `PROPOSED — NOT AUTHORIZED` |
| `R2_REVIEW_SHA256_MANIFEST.txt` | SHA-256 integrity manifest for all other package files |

## Audit support artifacts

| Path | Purpose |
|---|---|
| `audit/linked_raw_captures/*.json` | Exact copies of all ten aggregate raw T0/T1 telemetry captures |
| `audit/build_review_csvs.mjs` | Offline deterministic CSV/model builder |
| `audit_artifact_tool_csv_validation.json` | Spreadsheet Artifact Tool parse/inspect validation receipt |

The audit builder is analysis-only and was never executed against the DUT.

## Frozen source package

- repository: `lukaszsudul/AHD-diagnostic-evidence`
- directory: `v41-research-r2-r1i-causal-hardware-owner-mediated-continuation-halted-20260828`
- evidence commit: `a9461192e887db154bef911e2bcbae679cf7dd51`

| Source | SHA-256 | Role |
|---|---|---|
| `R2_SHA256_MANIFEST.txt` | `D6D8FA70973A9A1DFC8406A90A93B527341BAF2A36C0B0F0E104C15A24822002` | Source integrity root |
| `R2_STATE.json` | `FA3E9C1FC08A89F64729A4146E5049C4D80435D5829FB417B63686BDD4833EE4` | Halted R2 state |
| `R2_RAW_RESULTS.csv` | `A4A55541D1457202D490C3F7855810B0C79049984FE991CDCF306D648F8189A0` | Ten historical run rows |
| `audit/R2_PRIMARY_RUN_COMPLETIONS_APPEND_ONLY.csv` | `E3A2B5A52B10D4140FDBB0D5E620EEDE09A0698F402E354F3EBE45E70F9C9D7B` | Historical classifications |
| `audit/R2_PRIMARY_CAMPAIGN_LEDGER.jsonl` | `AA110E907571C9C1CD6E1B454A5284315C816C7507AC02E0DFE512342ADB1914` | 227-event append-only chain |
| `audit/R2_PRIMARY_CAMPAIGN_HALT.txt` | `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B` | Historical halt |
| `audit/SAFE_FORMAL_BASELINE_RECEIPT_SEQ10.txt` | `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF` | Final safe restoration |

The frozen package manifest verified before analysis. No frozen-package file was changed.

## Historical cadence sources

| Evidence path | Commit / status | SHA-256 | Use |
|---|---|---|---|
| `t1-v40.1.0-rca-putty-contextual-exception-2026-08-20/08_COMPARISON/RCA_CURRENT_VS_HISTORICAL_AND_V41.csv` | `5a885fd39378eab6608d92c895dc3270910e2bd5` | `AAD7B3474D54B03DBD0451BA6D8103302C32A7F9A53603D3AA411CFFF67CFA3D` | 11 known-good 25-count samples |
| `v41-nvp-i2c-25khz-paired-ab-r1/05_HARDWARE_PRECHECK/RATE_CLASSIFICATION_POLICY.md` | `5a81f5b115dddcdddd809a655fced115e113585e` | `F6886A865E7753CA41C834ED74667EA2A479BA4E6258BCDC61FD6BF8E46A4690` | Historical positive-delta policy |
| `v41-nvp-r1i-r2-qualified-poc-hardware-evidence/final/R1I_R2_MEASUREMENTS.md` | payload `c1c552fa4fc693d6c375db9478abecd7960ec3ce`; provenance `955ba0cd2462f4dec9dcb086175ab6eca57365bb` | `B20D129D33BA0C08538D679F8B104B360044026E159D67D0B24A527B69D0B869` | Qualified-R1i 25-count reference and SAV/VCLK cadence |
| `v41-nvp-r1h-r4-super-fast-implementation-and-large-sample/final/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md` | `aad5e9cb1ae88fdd3b6ac71de02a2fb08a2c79a2` | `3E0D487A1EBDDAB63CABD829E2868ADF26BDFF9FC23AFEBC20A13A397298D6D8` | R1h/R1h-R4 negative-video context |
| local pre-Git `V40_FINAL_NVP_VIDEO.md` | `LOCAL_UNCOMMITTED_CONTEXT_ONLY` | `B8E7AB051BB3C3E455328C57E08B3BAB71F5A375A69288068578ACE65E828E60` | Earlier known-good delta/SAV/VCLK context |

## Raw-capture binding

The prior committed per-run capture receipts contain `RAW_CAPTURE_SHA256`. Each local aggregate `RAW_CAPTURE_TRANSPORT.json` was hashed independently; all ten hashes match those receipt values exactly. Therefore the linked raw captures are cryptographically tied to the historical evidence commit even though the aggregate JSON files were not themselves stored in that historical directory.

| Seq. | Run | Historical capture receipt SHA-256 | Aggregate raw SHA-256 |
|---:|---|---|---|
| 1 | `R2OM-R01-P1-C0` | `82D3800DD852EC9EE37EA88386C17FA996426AF9B47B19E6E9182AC11A2F4178` | `FBFA2A398F38E896280523EF31F5BA41E0AC5AF9330BFAFC091E33D4325DA2DE` |
| 2 | `R2OM-R01-P2-C1` | `70C53E2FB33CCA79A1988FF50B8394815FDE43BDD647E884F4465193FA730C7F` | `0C11C01B3954539D7CF320D76723DAC02878D7CF6227C41637EC89D0F66C472F` |
| 3 | `R2OM-R01-P3-C3` | `AF8CC44448E89C65889FF017C409F6C7A7246D3DEF7FF6D47D44E3BDEF6C814B` | `0E2F02B7551620E60C45C752946257966F09ED6A82098A6C5FBFAB4F08906C1D` |
| 4 | `R2OM-R01-P4-C2` | `2B89054AB633DC6E5510031B6B45A2D0DD4E55FDC37242DD87D3AC2044E6C063` | `0AEC029F7EFB94B66DDB0C2EEAE3F783B89FD494FA49B8BF037F21E30ED6CEAB` |
| 5 | `R2OM-R02-P1-C1` | `B20D418E0AB1B3A5F3BEA3C9EA30D28A3B62130CE44A9C005A2ABAE0973EC06A` | `83AF6F834A363368C7FF6E9E3DC718E64B79B33B0D43E8EE951095D833A76364` |
| 6 | `R2OM-R02-P2-C2` | `F1FC99C5CB94BD551986B40D3834DB04089D5C0ABA4EDAE603476D6EFDF7CC05` | `02CAA01799AAFA231C997FE8EF61530076F4F0B419920AC78CC1CD27A5A951E6` |
| 7 | `R2OM-R02-P3-C0` | `82DF4E88B209C1B73FC85D024A1F278EF5AB2578B2546B267CD3129800C7EFCF` | `3EC6E3E4C5F6B79934E3C06A051BC9DD9F17BF28DBE6AA6C299293771D093D42` |
| 8 | `R2OM-R02-P4-C3` | `51E1B316D87C0F8C5F38387F261D9D0CFB955807EB0046AB55F53D4AE258373C` | `0C6C633F97F44810D4F8AF9AA82C551C39BC9CA256007C3DAF2851CD55A54976` |
| 9 | `R2OM-R03-P1-C2` | `D9383C4A87B1D1196206A5003E2B07D3F99D2D93DA422D0A7AA4DDDDE33C94D1` | `CC159157A892D8D46F2BBE59F372A8D93FA066DABE230361FC267CC1700A635C` |
| 10 | `R2OM-R03-P2-C3` | `C911525528E125CE382024BA0D56B845564C94ADD1CE61FF009C5B308910E010` | `601486A11377BE6C6581C82C29BA0BD5B304FC5A64FB20F7560DDD44A316C777` |

The per-run aggregate hash comparisons are also columns in both review CSVs.

## Spreadsheet validation

The spreadsheet skill's Artifact Tool parsed and inspected both CSVs:

- recalculation: range `A1:AH11`, 10 data rows;
- run comparison: range `A1:BA11`, 10 data rows.

The validation receipt is `audit_artifact_tool_csv_validation.json`.

## Review conclusion index

- primary result: `MEASUREMENT_ARTIFACT_PROBABLE`
- confidence: `HIGH`
- integer quantization: `CONFIRMED`
- exact C3 identity drift: `NO`
- recorded independent C3 sequence-10 abnormality: `NONE`
- existing ten observations: `KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID`
- campaign decision: `NEW_CONTROL_EXPERIMENT_REQUIRED`
- R3: `STILL_REQUIRED`
- amendment: `PROPOSED — NOT AUTHORIZED`
- new primary runs: `0`
- DUT access: `0`
- firmware/SSOT modification: `0`
