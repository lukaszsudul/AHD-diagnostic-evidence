# AHD v41 G2B Timing Delta

## Result

`G2B_TIMING_ANALYSIS: NOT_RUN`

`G2B_TIMING_DELTA_VS_G2A: NOT_MEASURED`

No G2B RTL was authored and no synthesis, placement, routing, or timing report
was produced after the record-ABI preflight blocker.

## Accepted G2A timing baseline

The following values are inherited from the accepted G2A clean R2 routed
build and must not be presented as G2B closure:

| Metric | Accepted G2A value | G2B value | Delta |
|---|---:|---:|---:|
| WNS | +0.617 ns | NOT_RUN | N/A |
| TNS | 0.000 ns | NOT_RUN | N/A |
| WHS | +0.024 ns | NOT_RUN | N/A |
| THS | 0.000 ns | NOT_RUN | N/A |
| Failing setup paths | 0 | NOT_RUN | N/A |
| Failing hold paths | 0 | NOT_RUN | N/A |
| No-clock endpoints | 0 | NOT_RUN | N/A |
| Unconstrained internal endpoints | 0 | NOT_RUN | N/A |
| Effective user/AXI clock | 62.5 MHz | NOT_RUN | N/A |

G2A was classified `PASS_WITH_TIMING_RISK` because the positive hold margin
is only 0.024 ns (24 ps). Any G2B implementation must compare against this
same-stage baseline and independently satisfy the G1 development conditions:
`WNS >= 0`, `TNS = 0`, `WHS >= 0`, `THS = 0`, fully constrained functional
paths, dispositioned CDC/clock findings, and acceptable congestion.

## Reports not generated

| Evidence | Result |
|---|---|
| Post-synthesis timing summary | NOT_RUN |
| Routed timing summary | NOT_RUN |
| Setup detail | NOT_RUN |
| Hold detail | NOT_RUN |
| Clock summary/interactions | NOT_RUN |
| CDC and bus-skew reports | NOT_RUN |
| Congestion comparison | NOT_RUN |

Timing therefore cannot be classified PASS, FAIL, or `PASS_WITH_TIMING_RISK`
for G2B itself. It remains unresolved behind the ABI hard stop.

