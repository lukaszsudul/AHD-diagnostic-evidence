# G2B-LUT0 De-instrumentation Plans

All numbers are planning estimates until G2B-LUT1 performs paired same-tool, same-stage builds. No plan changes the frozen G2B ABI/MMIO, XDMA Gen2 configuration, four-slot architecture or R1i functional behavior.

## Plan A — Minimal isolated research islands

Profile out only the whole autonomous tri-phase probe/index stores, failed-history logger and lifecycle observer; replace only the deep-history portion of the R1h service with an approved deterministic responder. Keep all embedded D1/R1f/R1i counters and scalar muxes.

- Current G2B named lower bound: about 2,287 LUT for probe + logger + lifecycle, plus an unmeasured fraction of the 103-LUT read service.
- Expected recovery: 2,300–2,500 LUT; point estimate 2,400.
- Expected final: 19,012 LUT, 91.404% at the point estimate.
- BRAM recovery: 9 RAMB18 = 4.5 tiles.
- Target `<=90%`: NO at point estimate.
- Risk: low functional risk after open-drain tie-off, fanout proof and MMIO compatibility approval.
- Category: A (`ZERO_FUNCTIONAL_RISK`) for isolated blocks; compatible readout simplification is B.

## Plan B — Product profile

Plan A plus profile out D1 deep history/wide duplicate snapshot, R1f failed-record construction and research-only transaction accounting, and flattened R1e/R1f/R1h research decode/mux. Retain all R1i telemetry fields and their required R1f opportunity/NACK/serial inputs, all compact product health, and full G2B MMIO.

- Historical routed R1e→R1h research wave: +4,125 LUT/+3,359 FF/+4.5 BRAM tiles.
- Current named whole-island lower bound (including serial/read service): 2,445 LUT/3,430 FF/4.5 tiles, although serial/scalar portions retained by this first profile reduce immediately removable named cost.
- Expected recovery after embedded/decode optimization: 3,500–4,300 LUT; point estimate 3,900.
- Expected final: 17,512 LUT, 84.192% at the point estimate; range 17,112–17,912 LUT (82.269–86.115%).
- Target `<=90%`: YES across the range.
- Preferred `80–85%`: YES at the point estimate, uncertain at the conservative end.
- Risk: low-to-moderate implementation risk; no functional state-machine cone may be selected out.
- Category: A for proved research-only cones; B for equivalent responder/mux simplification.

## Plan C — Product profile plus safe G2B structural optimization

Plan B plus category-B G2B optimizations: serialized Gray conversion, proven descriptor-state reduction, equivalent fatal/reset qualification, and/or shared generation/epoch comparisons. Do not combine slot RAMs as a resource tactic.

- Additional realistic G2B recovery after overlap: 120–220 LUT; point estimate 170.
- Total point recovery: 4,070 LUT.
- Expected final: 17,342 LUT, 83.375%.
- Risk: medium. Snapshot, reset, ownership and backpressure corner cases require exhaustive proof.
- Category: B (`LOW_RISK_IMPLEMENTATION_OPTIMIZATION`), not de-instrumentation.

## Architectural changes rejected for LUT1

Reducing four slots, changing record geometry, dropping counters, returning zero for defined G2B statistics, changing snapshot coherency, weakening reset epoch semantics, modifying XDMA Gen2, or changing the frozen ABI/MMIO is category C (`ARCHITECTURAL_CHANGE`) and is not proposed. The evidence shows Plan B can reach the continuation target without category C.

## Ranking

1. **Plan B — recommended.** It reaches the preferred point target while leaving G2B transport untouched.
2. **Plan A.** Lowest change scope but does not meet 90% at its point estimate.
3. **Plan C.** Useful margin only if Plan B measures below expectation or routing needs more headroom.

