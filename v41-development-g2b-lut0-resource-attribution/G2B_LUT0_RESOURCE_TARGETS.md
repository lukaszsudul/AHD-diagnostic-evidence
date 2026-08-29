# G2B-LUT0 Resource Targets

Device: `xc7a35tcsg325-2`; LUT capacity: `20,800`.

The current G2B post-opt result is `21,412 LUT`, or `102.9423077%`. It is 612 LUT over physical capacity. “Free LUT” below means capacity minus the target ceiling after the required recovery; it is not a placement guarantee.

| Ceiling | Maximum LUT | Recovery from 21,412 | Free LUT at ceiling | Exact utilization |
|---|---:|---:|---:|---:|
| 100% | 20,800 | 612 | 0 | 100.000% |
| 95% | 19,760 | 1,652 | 1,040 | 95.000% |
| 90% | 18,720 | 2,692 | 2,080 | 90.000% |
| 85% | 17,680 | 3,732 | 3,120 | 85.000% |
| 80% | 16,640 | 4,772 | 4,160 | 80.000% |

The continuation acceptance target is `<=90%`. The preferred target is `80–85%`.

## Stage-normalization warning

The accepted G2A headline (`18,178`) is routed; the current G2B headline (`21,412`) is post-opt. Their requested arithmetic delta, `+3,234`, is valid as a blocked-current-versus-accepted-reference comparison but is not a like-for-like RTL cost.

| Comparable stage | G2A LUT | G2B LUT | Delta |
|---|---:|---:|---:|
| Post-opt | 18,569 | 21,412 | +2,843 |
| Accepted/reference headline (mixed stage) | 18,178 routed | 21,412 post-opt | +3,234 |

The 391-LUT difference is the G2A post-opt-to-routed reduction. It is not new G2B logic and cannot be assumed as a future G2B routing saving. A purely illustrative subtraction would leave G2B at 21,021 LUT, still 221 LUT over capacity; this is not a prediction or qualification result.

## Recommended-plan point estimate

The evidence-backed planning estimate for the `PRODUCT` profile is a `3,900 LUT` recovery (`3,500–4,300` planning range), yielding a point estimate of:

- `21,412 - 3,900 = 17,512 LUT`
- `17,512 / 20,800 = 84.192%`
- `3,288 LUT` free at the point estimate

This estimate is deliberately not presented as a measured result. Only a controlled same-tool, same-stage G2B-LUT1 A/B build can establish the recovered amount.

