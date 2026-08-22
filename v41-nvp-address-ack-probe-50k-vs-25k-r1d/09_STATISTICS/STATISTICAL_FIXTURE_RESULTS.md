# Statistical and host-tool fixture results

All fixtures were rerun from sealed commit
`1beb70536d8e57305813f377a9e2c0e810b0bfc0` after the build. No source was
changed.

- One-shot writer fixture: PASS; exactly one aligned 32-bit write.
- Read-only reader fixture: PASS; only the declared probe offsets were read.

| X50/N50 | X25/N25 | Classification | Fisher two-sided | Key interval/result |
|---:|---:|---|---:|---|
| 0/10000 | 0/10000 | BOTH_RATES_BELOW_DETECTION_LIMIT | 1 | Wilson 95% upper 0.000383998371; exact one-sided 95% upper 0.000299528360 |
| 100/10000 | 50/10000 | STRONGLY_SUPPORTED_SINGLE_PAIRED_SAMPLE | 5.110347e-05 | RR 0.5; RR 95% [0.356476, 0.701310] |
| 100/10000 | 100/10000 | INCONCLUSIVE_SINGLE_PAIRED_SAMPLE | approximately 1 | RR 1; RR 95% [0.758971, 1.317573] |
| 10/10000 | 20/10000 | INCONCLUSIVE_SINGLE_PAIRED_SAMPLE | 0.0984853 | difference 0.001; RR 2; RR 95% [0.936658, 4.270504] |
| 10000/10000 | 10000/10000 | NO_MATERIAL_EFFECT_WITHIN_PREDECLARED_EQUIVALENCE_MARGIN | 1 | absolute and relative 90% equivalence both YES |

The script labels Haldane–Anscombe rate-ratio intervals as secondary when a
zero cell occurs. Binomial intervals are nominal conditional on independent
Bernoulli probes; serial correlation is not measured by aggregate counters.

