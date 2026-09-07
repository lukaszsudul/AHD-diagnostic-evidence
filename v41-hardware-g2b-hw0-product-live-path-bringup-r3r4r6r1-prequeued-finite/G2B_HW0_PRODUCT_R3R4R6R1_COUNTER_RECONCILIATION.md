
# Counter Reconciliation

| Metric | Baseline | Final | Delta |
|---|---:|---:|---:|
| Records attempted | 226 | 390 | 164 |
| Records committed | 154 | 317 | 163 |
| Records streamed | 154 | 317 | 163 |
| Records dropped | 72 | 73 | 1 |
| Overflow count | 71 | 72 | 1 |
| Discontinuity count | 21 | 22 | 1 |
| Records abandoned | 0 | 0 | 0 |
| Beats streamed | 78848 | 162304 | 83456 |

`RING_OVERFLOW_DROP_DELTA = 1`; `NON_OVERFLOW_DROP_DELTA = 0`.
The 163 streamed records equal 83,456 beats exactly, while only 157 complete
records were returned by the primary completion and the guard never completed.
