# R2 observer protocol check

Snapshot cutoff: `2026-08-28T17:22:56.2017197Z`, append-only ledger index 182.

## Verdict

- Frozen primary denominator: **32**
- Frozen denominator changed: **NO**
- More than 32 primary runs executed: **NO**
- Extra primary runs: **0**
- Duplicate primary runs: **0**
- Protocol deviation: **NO**
- Scientific result: **NOT_FINAL_CAMPAIGN_IN_PROGRESS**

One non-primary Formal safe-baseline observation preceded the matrix. It was explicitly `PRIMARY_R2_RUN_ROLE=NO` and `R0_PRIMARY_RUN_COUNTABLE=NO`; it is not denominator expansion.

## Expected versus actual frozen order

| Frozen round | Expected order | Actual at cutoff | Status |
|---|---|---|---|
| R01 | C0 C1 C3 C2 | C0 C1 C3 C2 | COMPLETE, four committed arms |
| R02 | C1 C2 C0 C3 | C1 C2 C0 C3 | COMPLETE, four committed arms |
| R03 | C2 C3 C1 C0 | C2 capture present; no sequence-9 run commit | ACTIVE; first arm uncommitted |
| R04 | C3 C0 C2 C1 | none | NOT STARTED |
| R05 | C3 C0 C2 C1 | none | NOT STARTED |
| R06 | C2 C3 C1 C0 | none | NOT STARTED |
| R07 | C1 C2 C0 C3 | none | NOT STARTED |
| R08 | C0 C1 C3 C2 | none | NOT STARTED |

## Accounting

- Completed valid primary arms: `8/32` (`25%`).
- Countable primary telemetry rows present: `9`, of which sequence 9 was not yet a completed arm.
- Missing primary completions: `24` (sequence 9 in progress plus sequences 10–32 not started).
- Fully completed rounds: `2/8`.
- Per-cell completed denominator: C0 `2/8`, C1 `2/8`, C2 `2/8`, C3 `2/8`.
- Supplemental runs: `0`.
- Campaign/scientific retries: `0`.
- Cold-start trials: `0`.
- Timing runs: `0`.
- Robustness runs: `0`.
- Diagnostic runs: `0`.
- Pre-probe/safe-baseline observations: `1`.

Transaction-level retry/recovery counters within sequence 6 and sequence 9 are scientific telemetry, not repeated campaign runs. Operational parser/harness recovery attempts during baseline establishment did not create additional scientific run rows.

## Classification and binding checks

The eight completion rows form the exact frozen prefix, with unique sequence and run IDs. Each completion row says `r0_primary_run_countable=YES` and `safe_formal_baseline_restored=YES`. Raw rows 1–9 match the frozen matrix candidate at the same sequence. No classification relabeling, duplicate ID, extra primary ID, or denominator field change was observed at the cutoff.

The active sequence 9 is predeclared by matrix line 10. It is therefore legitimate primary execution inside the fixed denominator, not supplemental execution and not unauthorized primary-denominator expansion.

## Later phases

The frozen R0 plan declares the exact-C3 10-cold-start campaign separately and prohibits pooling it with primary factorial runs. The live primary orchestrator likewise states it executes only the frozen 32 primary rows and performs no cold starts. No current Owner cold-reset confirmation receipt or formal cold-start trial directory existed at the cutoff.

The live campaign may continue after this point-in-time report.
