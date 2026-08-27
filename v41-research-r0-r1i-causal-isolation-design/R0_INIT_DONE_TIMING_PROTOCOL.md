# AHD v41 R0 — INIT_DONE Timing and Clock-Domain Protocol

## Objective

Measure actual initialization elapsed time and independently infer the active counter/autoinit clock frequency. Do not select 62.5 MHz or 125 MHz from an expected parameter, comment, or desired elapsed time.

No measurement is executed in R0.

## Existing measurement primitive and event definitions

The qualified source contains a 48-bit, configuration-initialized, free-running lifecycle counter clocked by `axi_aclk`, with no ordinary reset/enable, and a latch capturing the counter on the first sampled `nvp_init_done`. The top-level autoinit clock is also sourced from `axi_aclk`. The source’s nominal `CLK_HZ` value is a hypothesis/input to the design, not independent frequency evidence.

Published provenance already records:

- A1 `cnt_at_init_done = 133,683,129`;
- B1 `cnt_at_init_done = 132,584,735`;
- expected-active model `132,584,734`;
- historical expected-50-kHz reference `113,182,679`;
- routed `userclk1` period 16.000 ns (62.5 MHz);
- conflicting/stale XCI interface metadata containing 125 MHz.

At routed 62.5 MHz, A1 counter-origin→DONE is 2.138930064 s and B1 is 2.121355760 s. The historical reference is 1.810922864 s at 62.5 MHz or 0.905461432 s at 125 MHz. No independent host wall-clock DONE bracket was published, and the lifecycle monitor does not latch the true transaction-engine start. This protocol fills those gaps; it does not relabel the historical reference as measured autoinit duration.

Freeze two elapsed-time definitions:

1. **Configuration-counter epoch → first sampled INIT_DONE.** Start counter is the documented configuration initialization value (normally zero); done counter is the existing first-INIT_DONE latch. This is directly measurable if the configuration epoch is verified.
2. **Transaction-engine start → first sampled INIT_DONE.** This requires an observable/latching engine-start event. If no exact start latch or provably bounded status transition exists, report this narrower duration as `INCONCLUSIVE`; do not substitute a cycle-model expectation.

## Required evidence per measurement

- raw 48-bit free-running counter start value and event definition;
- raw 48-bit counter value latched at first `INIT_DONE`;
- modulo-2^48 counter delta;
- last decoded `INIT_DONE=0` and first decoded `INIT_DONE=1` raw snapshots;
- independent host UTC timestamps and monotonic timestamps for start brackets and DONE brackets;
- runtime common/source identity and bitstream SHA;
- counter register addresses, width, atomic-read method, rollover handling, and decoder revision;
- traced counter clock source/net and autoinit clock source/net;
- nominal clock declarations/generics, clearly labeled as expectations;
- independent live-counter frequency estimate if the counter is host-readable;
- any available board/clock-monitor or instrument frequency measurement, with its reference source and uncertainty.

## Atomic counter reading

For a split 48/64-bit MMIO counter, use high-low-high reads. Accept a sample only when the two high reads match; otherwise repeat once. Preserve each raw read and the two host monotonic timestamps bracketing it. Compute deltas modulo 2^48. A wrap is valid when unambiguous; otherwise the measurement is invalid.

Do not infer the start counter from the done counter or an expected cycle count. Verify configuration initialization/reset behavior from source and a raw pre-event capture where the interface permits it.

## Independent frequency measurement

Use one pinned host process and a monotonic clock. After runtime identity is valid, acquire at least 20 atomic live-counter samples spanning at least 10 seconds. Each sample has a host bracket `[t_before, t_after]`; use the midpoint for the regression and half-bracket width as timing uncertainty.

Fit counter value versus host monotonic time after unwrapping modulo 2^48:

`counter = intercept + f_hat × time`.

Report `f_hat`, residuals, slope confidence interval, maximum host bracket, sample count, and span. As a cross-check, calculate the slope from the first/last outer brackets. Reject the frequency measurement for counter discontinuity, non-monotonicity, identity change, host clock adjustment, or a confidence interval too broad to distinguish 62.5 MHz from 125 MHz.

If an independent hardware clock monitor or frequency counter is available without changing the candidate, record its value/reference/uncertainty and compare it with `f_hat`. A source generic alone is never the independent measurement.

## Host event brackets

Run the polling process before the start action.

- Start occurs in `[tS_before, tS_after]`, bracketing the exact configuration/start command or observed start transition.
- DONE occurs in `[tD_low, tD_high]`, where `tD_low` is the last coherent `INIT_DONE=0` poll and `tD_high` is the first coherent `INIT_DONE=1` poll.
- Poll interval target is ≤1 ms. Record actual maximum interval; do not claim tighter precision.

The host elapsed-time interval is:

`T_host ∈ [tD_low − tS_after, tD_high − tS_before]`.

For counter delta `ΔC` and independently inferred frequency interval `[f_low, f_high]`:

`T_counter ∈ [ΔC/f_high, ΔC/f_low]`.

The measurement is coherent only if `T_counter` intersects `T_host` after including stated event-synchronization and read-bracket uncertainty.

## Hypotheses and falsification

Evaluate these as hypotheses only:

- **H62.5:** the active counter/autoinit domain is approximately 62.5 MHz; a relevant measured delta may therefore map to approximately 1.81 s.
- **H125:** the active counter/autoinit domain is approximately 125 MHz; the same relevant delta may therefore map to approximately 0.905 s.
- **HOTHER:** neither nominal describes the active measured domain or the event definitions differ.

Classification:

- H62.5 `SUPPORTED` only if the `f_hat` interval includes 62.5 MHz, excludes 125 MHz, and the corresponding counter time intersects the host event bracket.
- H125 `SUPPORTED` only if the interval includes 125 MHz, excludes 62.5 MHz, and the corresponding counter time intersects the host bracket.
- If neither nominal is included, both are `NOT_SUPPORTED` and HOTHER is supported for investigation.
- If both remain possible, event start is not observable, or uncertainty is excessive, result is `INCONCLUSIVE`.

An apparent 1.81 s or 0.905 s host reading cannot by itself select a frequency. Conversely, an independently measured frequency can falsify both elapsed-time interpretations if the counter event is not the assumed start-to-done interval.

## Repetition and material variability

Collect timing fields for all 10 exact-R1i cold starts when doing so does not alter that protocol. Analyze timing separately.

Timing varies materially when the valid-run range exceeds:

`max(2% of the median, 5 ms, 2 × the largest host event-bracket width)`

for wall-derived elapsed time, or the equivalent counter-cycle bound using `f_hat`. Any discrete change matching a retry/backoff ladder is material regardless of percentage. Material variability, bimodality, order dependence, or correlation with retry/SCL-wait counters triggers R3/secondary review.

## Output record

The later execution package must preserve raw reads, decoded states, event brackets, regression inputs/results, formulas, clock-source trace, identities, and a conclusion using only `SUPPORTED`, `NOT_SUPPORTED`, or `INCONCLUSIVE`. It must state separately the configuration-to-done duration and the engine-start-to-done duration, if the latter is actually observable.
