# G2B-BS0 Recovery Progress Matrix

This matrix describes the interrupted attempt only. `COMPLETE` means that the named stage has a reusable artifact-supported result; it does not imply that G2B-BS0 as a whole completed.

| # | Stage | State | Evidence and boundary |
|---:|---|---|---|
| 1 | sealed DCP identity verification | COMPLETE | Two 57,900,063-byte DCP copies hash identically to `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`. |
| 2 | group-9 object identity verification | COMPLETE | Preserved list contains exactly 58 source objects and 19 destination objects; SHA-256 `CE4E8A35CB82CCD0A85AEBF340B997D74FEF9250C86BA76C61769E332079F4DB`. |
| 3 | semantic decomposition | COMPLETE | Static decomposition maps 58 source bits to slot/generation/epoch fields and 19 destinations to five roles. Dynamic cross-check remains outside this completed static stage. |
| 4 | bounded worker framework creation | COMPLETE | The final preserved runner, Tcl worker, minimal clock XDC, set generator, ledger builder source, and set manifest were created. The manifest has 94 data rows; 98 list files exist, including four unmanifested candidates. Historical worker bodies cited by EXP000-EXP002 are not preserved, and the ledger builder was not run. |
| 5 | full group-9 bounded reproduction | STARTED | EXP005 launched, but timed out during initialization. `Command_Start_UTC=NONE`; `report_bus_skew` never started. |
| 6 | semantic subset tests | STARTED | EXP003/EXP004 1x1 timing workers launched, but both timed out during initialization before a query result. No completed subset timing exists. |
| 7 | binary bisect | NOT_STARTED | Candidate lists/scaffolding exist, but no bisect experiment or result CSV exists. |
| 8 | `report_timing` control | PARTIAL | EXP002 opened the DCP, applied/resolved the exact scope, and entered the timing operation before a 600 s timeout. No `report_timing.rpt` exists. EXP006 never passed initialization. |
| 9 | `report_methodology` review | PARTIAL | Older Gen7B antecedent reviewed; no current Gen12 methodology worker/result exists. TIMING-32/34/37/38/39 are unresolved for Gen12. |
| 10 | logic-depth/reconvergence analysis | PARTIAL | Historical broad setup timing/static evidence was extracted, including a relevant 5.939 ns, 8-level, fanout-142 path. No dedicated topology worker/result exists. |
| 11 | constraint validity classification | PARTIAL | `VALID_WITH_NARROWER_ENDPOINT_SCOPE` is a provisional static classification, not a final dynamic decision. |
| 12 | CDC correlation | COMPLETE | Gen12 raw CDC counts and exact Group-9 overlap were correlated; no CDC-10/13 overlap was found. |
| 13 | minimal reproducer | PARTIAL | A reproducibility recipe, worker, set files, and minimal clock XDC exist; the smallest subset was not established and no minimal package was executed. |
| 14 | evidence packaging | PARTIAL | Seven expected draft documents and a static summary exist; ledger, bisect CSV, state JSON, and SHA-256 manifest are absent. |
| 15 | GitHub publication | NOT_STARTED | No prior BS0 directory or commit existed in the evidence repository before this recovery publication. |

## Experiment-level reconstruction

| ID | Target | Last proven phase | Target command completed | Usable result |
|---|---|---|---|---|
| EXP000 | initial launch | argument/locale validation | NO | NO |
| EXP001 | worker/DCP control | DCP open, invalid route-status call | NO | NO |
| EXP002 | exact 58x19 timing | timing update/operation entered | NO | PARTIAL CONTROL TRACE ONLY |
| EXP003 | 1x1 semantic timing | initialization timeout | NO | NO |
| EXP004 | 1x1 semantic timing | initialization timeout | NO | NO |
| EXP005 | full 58x19 BUS_SKEW | initialization timeout | NO | NO |
| EXP006 | full 58x19 timing | initialization timeout | NO | NO |
| EXP007 | methodology | planned metadata | NO | NO |
| EXP008 | topology | planned metadata | NO | NO |
| EXP009 | minimal follow-up | planned metadata | NO | NO |

No dynamic stage marked incomplete may be inferred from a generated set list or planned metadata. Every missing result requires a future G2B-BS0 continuation; none was re-executed during recovery.
