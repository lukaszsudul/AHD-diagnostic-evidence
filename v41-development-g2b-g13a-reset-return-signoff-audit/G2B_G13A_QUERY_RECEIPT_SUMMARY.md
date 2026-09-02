# AHD v41 G2B-G13-A — Deterministic Query Receipt Summary

## Receipt rule

Query status and runtime below are derived from the worker-written completion
markers, result summaries/CSVs, and final watchdog receipts. The external
`*_QUERY_TIMELINE.log` files are supervisor polling samples and are not treated
as exhaustive event logs; a short query can start and complete between polls.

## Attempt 1 — required alternatives

| Query | Completion evidence | Result | Runtime | Bound |
|---|---|---|---:|---:|
| Exact-scope `report_timing` | `raw/timing/QUERY_COMPLETED_PRIMARY_REPORT_TIMING.marker`; `G2B_G13A_REPORT_TIMING_SUMMARY.txt` | PASS | 56.827 s | 300 s |
| Bounded primary `get_timing_paths` | `raw/timing/QUERY_COMPLETED_PRIMARY_GET_TIMING_PATHS.marker`; `G2B_G13A_GET_TIMING_PATHS_SUMMARY.txt` | PASS | 0.185 s | 300 s |

Attempt 1 then stopped before any candidate query with
`HARNESS_OBJECT_TYPING_ERROR_BEFORE_CANDIDATE_QUERY`. Its watchdog records no
timeout and zero full Group-13 bus-skew retries.

## Candidate-only continuation

| Query | Completion evidence | Result | Runtime | Required / result |
|---|---|---|---:|---|
| Abandoned-count family | `raw/timing/candidate_continuation/QUERY_COMPLETED_CANDIDATE_RESET_ABANDONED_HOLD.marker`; root candidate-results CSV | PASS | 76.881 s | 6.000 ns; actual 2.634 ns; slack 3.467 ns |
| Commit-phase family | `raw/timing/candidate_continuation/QUERY_COMPLETED_CANDIDATE_RESET_COMMIT_PHASE_HOLD.marker`; root candidate-results CSV | PASS | 4.809 s | 6.000 ns; actual 3.756 ns; slack 1.723 ns |
| Supplemental aggregate cone | `raw/timing/candidate_continuation/QUERY_COMPLETED_SUPPLEMENTAL_AGGREGATE_COVERAGE.marker`; supplemental-results CSV | PASS | 0.137 s | 6.000 ns; actual 4.681 ns; slack 0.967 ns |
| Focused methodology | `raw/timing/candidate_continuation/QUERY_COMPLETED_FOCUSED_METHODOLOGY.marker`; methodology summary/report | PASS | 23.694 s | 20 total design findings; zero Group-13 object mentions |

Candidate family plus supplemental timing workload is `81.827 s`. Including
focused methodology, replacement-specific active workload is `105.521 s`.
All active queries completed below 77 seconds and below their 300-second
external bound.

## Applied-context and coverage gate

- Authoritative candidate-continuation applied context SHA-256:
  `5BE4471486CC09C04E22FAD5A9A26030EB521D1235628ACEAE6664C87A2D72ED`.
- Applied `set_bus_skew` count: 15.
- Applied `set_max_delay` count: 14.
- Applied Group-13 `set_bus_skew` count: 0.
- Aggregate source names/resolved objects: 212/212.
- Aggregate destination names/resolved objects: 457/457.
- Group-13 source membership: 7/7.
- Group-13 destination membership: 207/207.
- Supplemental cells: 79 = 7 transport + 7 commit-FIFO + 65 shadow state.

The same-basename root artifact at
`raw/timing/G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc` has SHA-256
`8CB3B5A21912803E4E02D92ED2B6E444B93474EE739734FE54E1294E2AA0C493`.
It was emitted by attempt 1 before the harness typing stop and before any
candidate query. It is non-authoritative for timing validation and is retained
only to make the stopped attempt auditable.

## Process receipts

| Metric | Value | Interpretation |
|---|---:|---|
| Attempt-1 process elapsed | 1,135.069 s | Includes A/B, cold setup, second context load, and pre-candidate harness stop |
| Candidate-continuation elapsed | 998.405 s | Cold DCP/full-context candidate-only session |
| Combined process runtime | 2,133.474 s | Sum of the two process runtimes; development/audit disclosure |
| Raw `CORRECTED_END_TO_END_SECONDS` | 2,563.711 s | Misnamed runner field; actually cross-attempt audit wall-clock span including human repair gap |

`CORRECTED_END_TO_END_SECONDS` is not used for runtime classification. The
governed continuation resumes inside an existing routed sign-off session, so
the replacement-sign-off workload is the bounded `105.521 s` active workload.

`SIGNOFF_RUNTIME = PRACTICAL`

An isolated fresh-process invocation including common DCP/XDC reconstruction
would be cold-session `MARGINAL`; that overhead is disclosed and is not a
combinatorial query pathology moved from `report_bus_skew`.

## Protection

Both watchdogs report `TIMED_OUT=FALSE`, no post-existing Vivado process, no
full Group-13 bus-skew retry, no bitstream, and no hardware access. Primary A/B
were not repeated in the continuation.
