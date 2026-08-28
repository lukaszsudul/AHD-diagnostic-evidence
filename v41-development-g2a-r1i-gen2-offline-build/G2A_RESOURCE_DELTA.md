# AHD v41 G2A Resource Delta

## Gate status

`QUALIFIED R1i BASELINE: RECORDED`

`FIRST CLEAN ATTEMPT: DIAGNOSTIC ONLY`

`FINAL CLEAN R2 RESOURCE GATE: PASS`

`FINAL CLEAN R2 TIMING GATE: PASS`

`FINAL ENGINEERING CLASSIFICATION: PASS_WITH_TIMING_RISK`

The authoritative final G2A source is commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`. Clean R2 completed every implementation stage once, produced a fully routed design, passed the resource and congestion hard gates, and closed timing at WNS `+0.617 ns`, TNS `0.000 ns`, WHS `+0.024 ns`, and THS `0.000 ns`.

Both setup and hold satisfy the strict G2A requirement of positive slack. The `+0.024 ns` hold margin is nevertheless extremely small, so the timing result is explicitly classified `PASS_WITH_TIMING_RISK`; this risk label does not convert the passing timing/resource gates into a failure or waiver.

## Qualified R1i routed reference

The frozen qualified-R1i routed reference is:

| Resource | Qualified R1i used | Device total | Utilization |
|---|---:|---:|---:|
| LUT | 18,181 | 20,800 | 87.409% |
| FF | 20,083 | 41,600 | 48.276% |
| BRAM tile equivalents | 26 | 50 | 52.000% |

This reference is authoritative for the routed G2A delta. No same-stage qualified value is asserted here for DSP, BUFG, MMCM, PLL, post-opt resources, timing, or congestion where the frozen input did not provide one.

## Frozen G1 limits

G2A is a development build. The applicable frozen limits from `V41_G1_RESOURCE_HEADROOM_POLICY.md:13-24,28-33` are:

| Metric | G1 development requirement |
|---|---|
| LUT | preferred `<=85%`; hard stop only when post-opt or routed utilization is `>90%` |
| FF | `<=80%` post-opt and routed |
| BRAM tile equivalents | `<=80%` post-opt and routed |
| DSP | `<=85%` |
| Routing congestion | fully routable; no unresolved global or local hotspot at tool level `>=5` |
| Setup timing | `WNS >= 0`, `TNS = 0`, no unconstrained functional path |
| Hold timing | `WHS >= 0`, `THS = 0` |
| DRC/clock/CDC | zero errors; each critical finding dispositioned; generated clocks and CDC exceptions resolve to their intended objects |

A result between 85% and 90% LUT can inform development planning but is above the preferred development target and cannot authorize a release candidate. Passing utilization cannot compensate for failed timing, congestion, DRC, clock, or unresolved CDC evidence.

## First clean attempt — diagnostic measurements

The first attempt completed routing and produced the following measurements before its then-current CDC harness stopped the flow. Sources include `<SOURCE_ROOT>_BUILD_EVIDENCE\G2A_BUILD_RESULT.txt`, `POST_OPT_RESOURCE_GATE.txt`, `ROUTED_UTILIZATION_FLAT.rpt`, `CLOCK_UTILIZATION.rpt`, `TIMING_SUMMARY.rpt`, and `CONGESTION.rpt`.

| Metric | First clean attempt | G1 development reading |
|---|---:|---|
| Post-opt LUT | 18,579 / 20,800 (89.322%) | below the `>90%` hard stop; above preferred 85%; only 141 LUT below 90% |
| Routed LUT | 18,181 / 20,800 (87.409%) | below the `>90%` hard stop; above preferred 85% |
| Routed FF | 20,137 / 41,600 (48.406%) | below 80% |
| Routed BRAM | 26 / 50 (52.000%) | below 80% |
| Routed DSP | 0 / 90 (0.000%) | below 85% |
| BUFG | 8 | diagnostic count; final R2 also uses 8 |
| MMCM | 2 | diagnostic count; final R2 also uses 2 |
| PLL | 0 | diagnostic count; final R2 also uses 0 |
| WNS | +0.364 ns | positive |
| TNS | 0.000 ns | no setup violation |
| WHS | +0.036 ns | positive |
| THS | 0.000 ns | no hold violation |
| Congestion | no level-`>=5` hotspot | development condition met in this attempt |

These figures show that the first Gen2 route remained below every development hard capacity stop and retained positive setup/hold slack. The post-opt and routed LUT levels nevertheless remain in the 85%-to-90% warning band and must be reported as headroom risk, not release capacity.

## First-attempt routed delta versus qualified R1i

Only like-for-like routed values are subtracted:

| Resource | Qualified R1i routed | First attempt routed | Diagnostic delta |
|---|---:|---:|---:|
| LUT | 18,181 | 18,181 | 0 |
| FF | 20,083 | 20,137 | +54 |
| BRAM tile equivalents | 26 | 26 | 0 |
| DSP | not frozen in the supplied R1i reference | 0 | not asserted |

The zero first-attempt routed LUT delta did not authorize carrying that result forward. The final embedded source identity differs, so the final R2 implementation was measured independently below.

## Final clean R2 measurements

| Metric | Final R2 value | Gate |
|---|---:|---|
| Post-opt LUT used / percent | `18,569 / 20,800 (89.274%)` | PASS; below 90% hard stop, above preferred 85% |
| Routed LUT used / percent | `18,178 / 20,800 (87.394%)` | PASS; below 90% hard stop, above preferred 85% |
| Qualified-R1i routed LUT delta | `-3 LUT` (`-0.015` percentage points) | PASS |
| Post-opt FF used / percent | `20,137 / 41,600 (48.406%)` | PASS |
| Routed FF used / percent | `20,137 / 41,600 (48.406%)` | PASS |
| Qualified-R1i routed FF delta | `+54 FF` (`+0.130` percentage points) | PASS |
| Post-opt BRAM used / percent | `26 / 50 (52.000%)` | PASS |
| Routed BRAM used / percent | `26 / 50 (52.000%)` | PASS |
| Qualified-R1i routed BRAM delta | `0` | PASS |
| DSP used / percent | post-opt and routed `0 / 90 (0.000%)` | PASS; exact qualified baseline not supplied, so no delta asserted |
| BUFG / MMCM / PLL | `8 / 2 / 0` | PASS; exact qualified baseline not supplied, so no delta asserted |
| Route congestion | `CONGESTION_GATE=PASS`; no window reported at the configured level-5 threshold | PASS |
| WNS / TNS | `+0.617 ns / 0.000 ns` | PASS |
| WHS / THS | `+0.024 ns / 0.000 ns` | PASS_WITH_TIMING_RISK |

The exact frozen input does not provide same-stage qualified R1i post-opt FF/BRAM/DSP or clock-resource counts, so no cross-stage or inferred delta is claimed for those fields. The routed LUT, FF, and BRAM deltas above are direct like-for-like comparisons against the Owner-supplied qualified-R1i routed reference.

At post-opt, R2 is 151 LUT below the 90% hard-stop boundary; routed R2 is 542 LUT below it. These are passing development results but retain meaningful LUT headroom risk. No diagnostic logic was removed to obtain closure.

## Final acceptance rule

The final R2 resource gate requires the clean implementation to remain at or below all G1 development caps, be fully routed without a level-`>=5` congestion finding, have the Owner-required strict positive margins `WNS > 0`, `TNS = 0`, `WHS > 0`, and `THS = 0`, and pass all DRC/clock/CDC gates independently. Clean R2 satisfies those conditions. Diagnostics were not removed to recover headroom.

Final clean R2 resource gate: `PASS`.  
Final clean R2 timing gate: `PASS`.  
Final timing classification: `PASS_WITH_TIMING_RISK` because WHS is only `+0.024 ns`.
