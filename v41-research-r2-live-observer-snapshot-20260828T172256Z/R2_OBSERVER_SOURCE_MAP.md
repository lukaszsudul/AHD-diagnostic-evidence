# R2 observer source map

This map makes the passive snapshot reproducible. Local source artifacts were read only. Record timestamps are used where available; file creation/modification timestamps are noted for campaign identity. The snapshot cutoff is `2026-08-28T17:22:56.2017197Z` / local `2026-08-28T19:22:56.2017197+02:00`, with ledger tail index 182, eight completion rows, and nine raw-result rows.

## Root map

| Role | Path | Timestamp / identity |
|---|---|---|
| Active continuation | `C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\R2_OWNER_MEDIATED_CONTINUATION_STAGE` | Created `2026-08-28T10:09:14.7316760Z` |
| Active orchestrated campaign | `...\R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02` | Configuration created `2026-08-28T13:39:41.8412822Z`; ledger genesis `2026-08-28T13:39:42.4511452Z` |
| Referenced ASCII execution root | `C:\AHD_R2_OWNER_EXEC_20260828` | Created `2026-08-28T10:48:37.4907142Z` |
| Historical blocked package | `...\R2_PUBLISH_FINAL_STAGE\v41-research-r2-r1i-causal-hardware-executed` | Historical final evidence commit `e28d58cfdd266a0237840a0713ef4c71854e01c5` |

## Conclusion-to-source map

| Conclusion | Source file | Timestamp | Run / record | Relevant lines or records |
|---|---|---|---|---|
| Current campaign is the Owner-mediated continuation | `R2_OWNER_DUT_EXCLUSIVITY_RECEIPT.md` | Owner capture `2026-08-28T10:08:52.027Z` | continuation authority | lines 3–9, 17–23 |
| Owner exclusivity confirmation exists and passed | `R2_OWNER_INTERACTION_LOG.md` | capture `2026-08-28T10:08:52.027Z` | interaction 1 | lines 3–7, especially line 5 |
| Current campaign is distinct from old blocker | `R2_CONTINUATION_PROVENANCE.md` | file created `2026-08-28T10:24:28.0423739Z` | continuation provenance | lines 3–10 |
| Old attempt executed 0/32 and was blocked | historical `R2_CAUSAL_HARDWARE_REPORT.md` | before current continuation | historical attempt | lines 5–8, 91 |
| Frozen primary denominator is 32, eight per cell, warm protocol | `R2_PRIMARY_CAMPAIGN_CONFIGURATION.txt` | config creation `2026-08-28T13:39:41.8412822Z` | campaign | lines 6–11 |
| Frozen matrix order and canonical IDs | `R2_RUN_MATRIX.csv` | created `2026-08-28T10:30:29.7062254Z` | sequences 1–32 | lines 1–33 |
| Frozen R0 Williams/reverse order | `v41-research-r0-r1i-causal-isolation-design/R0_R1I_CAUSAL_ISOLATION_EXPERIMENT_PLAN.md` | frozen R0 authority commit `aff7e32edc1cf71bde95b6c19e54e6f307764237` | R0 protocol | lines 88–97 |
| Candidate identities and hashes | `R2_ARTIFACT_IDENTITY_RECEIPT.md` | before programming | Formal, C0–C3 | lines 3–13 |
| No candidate artifact was rebuilt or modified | `R2_ARTIFACT_IDENTITY_RECEIPT.md` | before programming | all candidates | line 13 |
| First sealed non-primary safe-baseline observation | `C:\AHD_R2_OWNER_EXEC_20260828\baseline\formal_capture_v3\R2_CANDIDATE_CAPTURE_RECEIPT.txt` and `controls\SAFE_FORMAL_BASELINE_BASELINE_FORMAL_001.txt` | capture `2026-08-28T11:43:54.604006705Z`; seal `2026-08-28T11:44:34.4852745Z` | `BASELINE_FORMAL_001` | capture lines 4–10, 57, 60–110; seal lines 1–22 |
| First two live arms were executed before orchestrator and hash-bound into the prefix | `tools/R2_PRIMARY_CAMPAIGN_ORCHESTRATOR.md`; imported commit receipts | captures `2026-08-28T12:04:42.615684466Z`, `2026-08-28T12:43:00.550135121Z` | sequences 1 and 2 | README lines 66–95; each imported receipt lines 1–22 |
| Eight completed valid primary arms at cutoff | `R2_PRIMARY_RUN_COMPLETIONS_APPEND_ONLY.csv` | last committed arm `2026-08-28T17:00:50.0950012Z` | sequences 1–8 | lines 1–9; ledger line 170 |
| Nine countable raw primary captures at cutoff | `R2_PRIMARY_RAW_RESULTS_APPEND_ONLY.csv` | sequence-9 receipt `2026-08-28T17:22:19.3319569Z` | sequences 1–9 | lines 1–10 |
| R01 and R02 are fully complete; R03 is active | completion CSV and ledger | sequence 8 commit `17:00:50.0950012Z`; sequence 9 start `17:01:31.8107860Z` | sequences 8–9 | completion lines 2–9; ledger lines 169–182 |
| No duplicate or extra primary run IDs | matrix, raw CSV, completion CSV | cutoff | sequences 1–9 | matrix lines 2–10; raw lines 2–10; completion lines 2–9 |
| R09_C2 maps to sequence 9, not round 9 | `R2_RUN_MATRIX.csv`; live run directory; ledger | start `2026-08-28T17:01:31.8107860Z` | `R2OM-R03-P1-C2` | matrix line 10; ledger lines 171–182 |
| R09_C2 is primary, warm, countable, and C2/R1i-b | sequence-9 candidate capture receipt | capture `2026-08-28T17:22:11.781192804Z`; receipt `17:22:19.3319569Z` | `R2OM-R03-P1-C2` | lines 4–10, 18, 25, 57, 60–86, 89–110 |
| R09_C2 was not a programming/campaign retry | sequence-9 program receipt | completion `2026-08-28T17:08:13.0763678Z` | `R2OM-R03-P1-C2` | lines 1–2, 9–19 (`PROGRAM_INVOCATIONS=1`, `PROGRAM_RETRIES=0`) |
| R09_C2 telemetry retry count is DUT transaction recovery | sequence-9 candidate capture receipt | receipt `17:22:19.3319569Z` | `R2OM-R03-P1-C2` | lines 63–74 and 86 |
| R09_C2 arm was uncommitted at cutoff | completion CSV plus ledger-tail capture | cutoff `17:22:56.2017197Z` | sequence 9 | completion file ended at line 9/sequence 8; ledger tail was line/index 182 `CANDIDATE_TELEMETRY:COMPLETE` |
| Cold-start operations in primary orchestrator are zero | `R2_PRIMARY_CAMPAIGN_CONFIGURATION.txt` | config creation | primary campaign | line 11 |
| Primary orchestrator excludes cold/timing phases | `tools/R2_PRIMARY_CAMPAIGN_ORCHESTRATOR.md` | pre-execution audited tool | primary campaign | lines 3–5 |
| Cold campaign is separate and not pooled | frozen R0 experiment plan | frozen R0 | later C3 phase | lines 250–256 |
| No current manual cold-reset request or confirmation | `R2_OWNER_INTERACTION_LOG.md`; active-root file inventory | cutoff | none | interaction log contains only line-5 exclusivity row; no reset-confirmation receipt or cold trial directory found |
| Cold trials would be distinguishable if later executed | `tools/R2_C3_COLD10X_OWNER_MEDIATED_HARNESS.md` | predeclared tooling | future `R2C3-COLD-Tnn-Ann` | lines 17–26, 34–46, 67, 92–103 |
| Campaign was still in progress and no final causal interpretation is valid | completion CSV; frozen R0 plan | cutoff | 8/32 committed | completion lines 1–9; R0 plan lines 88–101, 238–243 |

## Per-run chronology sources

| Execution order | Run ID | Start source | End source | Telemetry source |
|---:|---|---|---|---|
| 0 | `BASELINE_FORMAL_001` | `C:\AHD_R2_OWNER_EXEC_20260828\baseline\program\PROGRAM_STDOUT_STDERR.log:1` | safe-baseline seal line 22 | Formal capture receipt lines 4–110 |
| 1 | `R2OM-R01-P1-C0` | `C:\AHD_R2_OWNER_EXEC_20260828\primary\R01_C0\pre_program\PRE_PROGRAM_HOST_GATE.txt:1` | `SAFE_FORMAL_BASELINE_AFTER_R01_C0.txt:25` | raw CSV line 2 |
| 2 | `R2OM-R01-P2-C1` | `C:\AHD_R2_OWNER_EXEC_20260828\primary\R02_C1\pre_program\PRE_PROGRAM_HOST_GATE.txt:1` | `SAFE_FORMAL_BASELINE_AFTER_R02_C1.txt:25` | raw CSV line 3 |
| 3 | `R2OM-R01-P3-C3` | ledger line 3 | ledger line 30 | raw CSV line 4 |
| 4 | `R2OM-R01-P4-C2` | ledger line 31 | ledger line 58 | raw CSV line 5 |
| 5 | `R2OM-R02-P1-C1` | ledger line 59 | ledger line 86 | raw CSV line 6 |
| 6 | `R2OM-R02-P2-C2` | ledger line 87 | ledger line 114 | raw CSV line 7 |
| 7 | `R2OM-R02-P3-C0` | ledger line 115 | ledger line 142 | raw CSV line 8 |
| 8 | `R2OM-R02-P4-C3` | ledger line 143 | ledger line 170 | raw CSV line 9 |
| 9 | `R2OM-R03-P1-C2` | ledger line 171 | UNKNOWN at cutoff | raw CSV line 10; ledger lines 171–182 |

The active append-only files may contain later records when reread. Reproduction of this snapshot must apply the explicit cutoff of ledger index 182 and the first eight completion records / first nine raw records.
