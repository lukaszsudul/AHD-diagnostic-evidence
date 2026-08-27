# AHD v41 G1 Resource Headroom Policy

## Purpose

The policy reserves implementation margin for the Gen2 IP delta, the one-channel C2H ring/formatter, the second logical channel and scheduler, routing variability, and late fixes. It treats diagnostic reduction as a planned opportunity, not as uncommitted capacity.

The qualified R1i total of 18,181/20,800 LUT (87.41%) is already above the preferred development planning band. That does not invalidate the qualified proof-of-concept, but it means G2A must measure the Gen2-only delta and G2B may not assume that synthesis will absorb new logic. A release image must obtain headroom through an approved architecture or diagnostic-reduction gate.

## Acceptance limits

Post-synthesis percentages are trend warnings. Capacity hard stops apply at post-opt and route as stated below; final acceptance uses a fully routed implementation with all clocks and CDC paths present and the absolute timing/congestion criteria satisfied.

| Metric | Development build | Release-candidate build | Rationale |
|---|---:|---:|---|
| LUT | Preferred `<=85%`; hard stop `>90%` post-opt or routed | Objective `<=80%`; hard acceptance `<=85%` routed | LUT/routing is the present limiting resource. The 85% RC cap leaves 3,120 LUT; the 80% objective leaves 4,160 for ECO/seed variation and unmeasured channel logic. The 90% development ceiling is temporary, not a release target. |
| FF | `<=80%` post-opt and routed | `<=70%` routed | FF is not currently limiting, but wide counters, CDC pointers, and pipeline registers grow with C2H/two-channel support. |
| BRAM tile equivalents | `<=80%` post-opt and routed | `<=75%` routed | Two private four-record rings structurally require about eight RAMB36 equivalents before descriptor/control overhead; the RC reserve protects buffering and placement freedom. |
| DSP | `<=85%` | `<=75%` | No planned DMA function should consume many DSPs; unexpected growth is an architecture-review trigger. |
| Routing congestion | No unroutable/overused nodes; no unresolved tool level `>=5` global or local hotspot | No tool level `>=5`; each level-4 hotspot reviewed; no persistent hotspot in PCIe/C2H/video/CDC/reset corridors | Utilization alone is not a routeability measure. The qualified package has no quantitative congestion report, so its present congestion status is `UNKNOWN`. |
| Setup timing | `WNS >= 0`, `TNS = 0`, no unconstrained functional paths | `WNS >= max(0.25 ns, 3% of the shortest relevant period)`, `TNS = 0` | Development proves closure; RC carries explicit setup margin against implementation variance. |
| Hold timing | `WHS >= 0`, `THS = 0` | `WHS >= 0.02 ns`, `THS = 0` | The small positive guard is grounded below the qualified +0.036 ns result while rejecting effectively zero-margin closure. |
| DRC/clock/CDC | Zero errors; every critical warning dispositioned; generated clocks and CDC exceptions resolve to intended objects | Zero errors and zero unexplained critical warnings; reviewed CDC/reset report and no broad false paths | Gen2 may alter generated clocks/reset sequencing even when the nominal application clock is unchanged. |

All thresholds apply to the target device and actual release configuration. A passing percentage with failed timing, congestion, DRC, clock, or CDC evidence is a failure.

## Stage policy

### G2A — integration and Gen2 build

- G2A may proceed because its functional delta is deliberately small and C2H remains inactive.
- Record the exact Gen1-R1i versus Gen2-G2A same-stage post-synth, post-opt and routed hierarchy, primitives, clocking, WNS/WHS, congestion, and utilization. Post-synthesis is a trend indicator: qualified R1i falls from 97.69% post-synth to 89.31% post-opt and 87.41% routed, so post-synth percentage alone is not the hard capacity gate.
- Stop above 90% LUT at post-opt or route, above the FF/BRAM development caps, or on any timing/routing/CDC failure. Qualified R1i has only 143 LUT of post-opt and 539 LUT of routed margin to that hard ceiling. Between 85% and 90%, the result can inform G2B planning but cannot authorize a release candidate.
- Any effective application/NVP clock difference is a semantic blocker independent of utilization.

### G2B — minimal one-channel C2H

- Before RTL work, prepare a bounded estimate for one four-record ring, descriptor FIFO, formatter, counters, and one extension-page register bank.
- Accept only if the implemented design stays within the development hard limits while all qualified diagnostics coexist.
- If it cannot fit, stop and open an explicit productization/resource gate; do not opportunistically delete R-track instrumentation.

### Later two-channel gate

- Add the second private ring, per-channel descriptors/counters, and record-boundary scheduler only after G2B measurement.
- Meet the development limits with both channels enabled and traffic-accurate backpressure constraints.
- Enter release candidacy only after approved diagnostic reduction (if needed) produces the RC limits with both channels and Gen2 configuration present.
- Before commitment, require the measured remaining planned increment multiplied by `1.25`, plus a separate 5%-of-device LUT ECO reserve, to fit below the applicable absolute cap. Count shared infrastructure once and identify every assumption.

## Budget accounting rules

1. Use post-route totals from the same source, IP, constraints, tool version, directives, and target stage for comparisons.
2. Label standalone or cross-stage figures `MEASURED_NON_ADDITIVE`; never subtract them from a different integrated build to claim capacity.
3. Count one RAMB36 as one tile equivalent and one RAMB18 as one-half when making aggregate BRAM comparisons, while retaining primitive counts in reports.
4. Report incremental groups with hierarchical utilization plus a controlled same-stage A/B build when optimization crosses hierarchy.
5. Include generated XDMA support logic, debug cores, replicated high-fanout/reset logic, and routing/clock resources; do not count only handwritten RTL.
6. Treat an unmeasured future block as consuming unknown capacity, not zero.
7. Record at least three implementation seeds/directive variants for the release candidate if timing or utilization lies close to a limit; all release evidence must identify the selected result.

## Exception process

A threshold exception requires an owner-approved written waiver containing the exact routed report, congestion map, seed variance, residual feature budget, timing margins, reason an architectural reduction is unsafe, and a bounded exit plan. No waiver can excuse failed setup/hold, unresolved CDC, DRC errors, an unexplained generated clock, or inability to count data loss.

## Policy conclusion

The headroom policy is `PASS`. The current R1i proof-of-concept is a protected starting oracle, not a release-capacity claim. G2A measures the Gen2 delta; G2B and the later two-channel gate must earn space within the stated limits or stop for an explicit resource/productization decision.
