# R09_C2 analysis

R09_C2 classification:
PRIMARY_CAUSAL_RUN
Part of frozen 32-run denominator:
YES
Protocol deviation:
NO
Reason R09 exists:
It is the predeclared ninth execution slot of the frozen 32-run matrix: canonical `R2OM-R03-P1-C2`, frozen round R03 position 1, candidate C2/R1i-b. The `09` is a sequence index, not a ninth frozen round.

## Identifier resolution

No active artifact searched contains the exact literal `R09_C2`. The evidence-exact match is unique:

- `R2_RUN_MATRIX.csv:10` records sequence index `9`, row `3`, position `1`, candidate `C2`, canonical run ID `R2OM-R03-P1-C2`.
- The live run directory is `runs/009_R2OM-R03-P1-C2`.
- Ledger events 171–182 bind sequence index 9 to that canonical ID.

Accordingly, the observed shorthand means “ninth sequential execution, C2.” It does not create round R09. It begins frozen round R03.

## C2 identity

C2 is R1i-b, SHA-256 `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D`. The artifact identity receipt, immutable campaign configuration, sequence-9 programming receipt, and sequence-9 telemetry receipt all agree.

The sequence-9 programming receipt records one programming invocation, zero programming retries, `DONE=1`, and `PASS_SAME_SESSION_DONE_1`. The telemetry receipt records `CAPTURE_PURPOSE=PRIMARY_R2_CANDIDATE_RUN`, `PRIMARY_R2_RUN_ROLE=YES`, warm epoch, `R0_PRIMARY_RUN_COUNTABLE=YES`, and `RECOVERED_PASS`.

## Chronology and denominator

Sequence 8, `R2OM-R02-P4-C3`, completed run commit at `2026-08-28T17:00:50.0950012Z`. Sequence 9 began at `2026-08-28T17:01:31.8107860Z`. Therefore it occurred after execution slots 1–8 were complete. Those slots constitute frozen rounds R01 and R02; it did not occur after all eight frozen rounds were complete.

At the snapshot cutoff, sequence 9 had a countable telemetry capture sealed at `2026-08-28T17:22:19.3319569Z`, but the append-only run-completion table still ended at sequence 8. Safe restoration and final run commit were pending. The campaign progress metric therefore remains eight completed valid arms out of 32, while the timeline separately exposes the ninth countable-but-uncommitted capture.

Sequence 9 occupies one already reserved denominator slot. It does not add a 33rd run, alter the per-cell target of eight, or expand the frozen denominator of 32.

## Retry and later-phase classification

This is not a campaign retry. The `RETRY_COUNT=2` in its telemetry describes two DUT transaction-level recovery attempts inside the single scheduled primary arm. It is not a repeated scientific run. Programming retries are explicitly zero.

It is not a cold-start, robustness, timing, diagnostic, recovery, or supplemental run. The primary orchestrator is restricted to the frozen 32 warm-start rows and records zero cold-start operations. Cold-start and INIT_DONE timing work is predeclared under separate tooling and had not started at the cutoff.

## Statistical effect

R09_C2 can contribute one planned C2 observation to later primary descriptive counts after its arm is safely committed. It does not change the denominator. Because the primary campaign was incomplete, this snapshot makes no final M1/M2/combined-effect causal declaration.

## Key evidence

- `R2_OWNER_MEDIATED_CONTINUATION_STAGE/R2_RUN_MATRIX.csv:10`
- `R2_OWNER_MEDIATED_CONTINUATION_STAGE/R2_ARTIFACT_IDENTITY_RECEIPT.md:10`
- `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_CAMPAIGN_CONFIGURATION.txt:6-11,35-36`
- `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_CAMPAIGN_LEDGER.jsonl:169-182`
- `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_RAW_RESULTS_APPEND_ONLY.csv:10`
- `runs/009_R2OM-R03-P1-C2/04_CANDIDATE_TELEMETRY/output/R2_CANDIDATE_CAPTURE_RECEIPT.txt:4-10,18,25,57,60-86,89-110`
- `C:\AHD_R2_OWNER_EXEC_20260828\orchestrated_after_R02\primary\009_R2OM-R03-P1-C2\01_candidate_program\PROGRAM_RECEIPT.txt:1-19`

This is a point-in-time observation at `2026-08-28T17:22:56.2017197Z`. The live campaign may continue after this snapshot.
