# R1i–R2 Statistical Interpretation

## Frozen endpoint

The frozen scientific plan did not predeclare a binding p-value or confidence-interval threshold. The authoritative outcome matrix classified a functional R1i pass with an exact R1h functional failure as `STRONG_PASS`. Statistics are reported descriptively and do not replace or retroactively redefine that endpoint.

## Post-init selected-target comparison

| Phase | R1i | R1h | Difference | Fisher one-sided p | Interpretation |
| --- | ---: | ---: | ---: | ---: | --- |
| WADDR | 0 / 10,000 | 0 / 10,000 | 0 | 1.0 | No separation |
| REGADDR | 0 / 10,000 | 0 / 10,000 | 0 | 1.0 | No separation |
| DATA | 0 / 10,000 | 0 / 10,000 | 0 | 1.0 | No separation |

For each zero-event arm/phase, the two-sided Clopper–Pearson 95% interval is `[0, 0.0003688199]`. Relative reduction and rate ratio are undefined for a 0/0 comparison.

Post-init counters did not separate A1 and B1 because both recorded zero NACKs in all three 10,000-opportunity phases.

## Autoinit comparison

| Phase | R1i | R1h | R1h−R1i absolute rate | Fisher one-sided p |
| --- | ---: | ---: | ---: | ---: |
| WADDR | 0 / 275 | 0 / 275 | 0 | 1.0 |
| REGADDR | 0 / 275 | 2 / 275 | 0.0072727273 | 0.2495446266 |
| DATA | 0 / 220 | 2 / 220 | 0.0090909091 | 0.2494305239 |

The two nonzero control counts directionally support R1i, but the counts are small and are not presented as statistically significant. No aggregate autoinit p-value was a frozen acceptance gate.

## Why the outcome was STRONG_PASS

The frozen `STRONG_PASS` conclusion came from the combined same-session functional outcome:

- R1i: successful initialization, zero autoinit NACKs, no `INIT_ERROR`, and video present.
- R1h: four autoinit NACKs, `INIT_ERROR` latched, and no video.

This is functional confirmation of the combined PoC implementation. It is not complete proof of the exact physical or RTL sub-mechanism.
