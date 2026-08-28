# R2 Measurement Protocol Amendment Proposal

## PROPOSED — NOT AUTHORIZED

This document is a proposal only. It does not amend R0/R2, reclassify a run, authorize hardware access, or permit campaign continuation. It is prospective input to a separately authorized measurement-control experiment and, only after validation, a new causal campaign. Explicit Owner/Architect approval is required before it has any effect.

## Problem statement

The frozen frame clean gate uses an integer frame-counter delta over an approximately 1.008-second host monotonic window that is not phase-locked to frame events, then applies a `±0.10 Hz` tolerance. One event per window is approximately `0.992 Hz`; therefore the estimator cannot resolve the tolerance.

The frozen target came from the recorded qualified-R1i PoC interval: `25 / 1.007913055 = 24.803726746 Hz`, rounded to `24.803727`. It is an estimator outcome tied to a particular integer branch, not a sufficiently resolved physical-frequency reference.

## Proposed scope

Amend only the host-side video frame-rate corroboration method. Do not modify:

- candidate bitstreams or RTL;
- FPGA clocking or XDC;
- NVP table or I2C frequency;
- driver, kernel, MMIO ABI, or telemetry semantics;
- run order/count;
- autoinit/recovery/safety classification;
- cold-start or INIT_DONE protocols;
- R3 triggers.

## Proposed future-run measurement

### Raw capture requirements

For each run, retain:

- monotonic start timestamp in nanoseconds;
- monotonic end timestamp in nanoseconds;
- actual elapsed seconds;
- start/end frame counter values and width;
- unwrapped frame delta;
- start/end SAV counter values and delta;
- start/end VCLK counter values and delta;
- register-read order and host read-latency brackets;
- counter wrap/consistency checks;
- candidate and runtime identity.

### Duration and sampling

- First apply the existing frozen video-present observation. If video is absent and frame/SAV deltas remain zero through an initial `2.0 s` check, record `FRAME_RATE_NOT_APPLICABLE_VIDEO_ABSENT`; do not wait for 500 events. The other frozen criteria determine the run classification.
- For video-present runs, sample FRAME, SAV, and VCLK at nominal 1-second spacing using each counter's own `pread` midpoint bracket.
- The first sample after two consecutive advancing video samples is the measurement origin.
- End at the first sample satisfying both actual elapsed `T >= 20.0 s` and unwrapped frame delta `N >= 500`.
- Apply a hard cap at actual elapsed `30.0 s`. If `N < 500` at the cap, return `FRAME_RATE_INCONCLUSIVE_INSUFFICIENT_EVENTS`; never wait indefinitely.
- Require at least 21 usable samples including endpoints.
- Unwrap each 32-bit counter by adding modulo-`2^32` adjacent deltas. An adjacent modulo delta `>=2^31`, a nonpositive elapsed interval, or an inter-sample elapsed interval outside `0.5–2.0 s` is `COUNTER_INTEGRITY_INCONCLUSIVE`.

At 20 seconds, one-event resolution is at most `0.05 Hz`, below the intended `±0.10 Hz` half-band. The 30-second cap makes the procedure finite for unexpectedly low cadence.

### Exact arithmetic

For endpoint samples 0 and K:

```text
T = tK_midpoint - t0_midpoint
E = (t0_after - t0_before)/2 + (tK_after - tK_before)/2
N = unwrapped_frame_K - unwrapped_frame_0
f_endpoint = N/T
f_interval_low = (N-1)/(T+E)
f_interval_high = (N+1)/(T-E)
```

`T-E` must be positive. The `±1` event terms conservatively cover start/end boundary phase; `E` covers the measured `pread` timing brackets.

For each counter `X` in `{frame, SAV, VCLK}`, compute an ordinary least-squares slope independently from every usable unwrapped sample:

```text
f_X_ols = sum((ti-mean(t))*(Xi-mean(X))) / sum((ti-mean(t))^2)
```

Thus `f_frame_ols`, `f_sav_ols`, and `f_vclk_ols` are separately estimated slopes. Require `abs(f_frame_ols-f_endpoint) <= 0.05 Hz`. The frame endpoint interval is the primary acceptance estimate; frame OLS is its nonlinearity/outlier cross-check. Use `f_sav_ols/1125` for the SAV acceptance band and `f_vclk_ols` for the VCLK acceptance band.

### Proposed reference

Subject to Owner/Architect acceptance of the independent video-mode basis, the proposal is numerically complete:

- physical frame reference: `25.000000 Hz`;
- frame clean band: `25.000000 ± 0.10 Hz`;
- SAV corroboration: under the independently qualified 1,125-total-line mode, divide the OLS all-SAV (`H=0`) rate by 1,125 and require `24.900000–25.100000 Hz`;
- VCLK corroboration: require `148.3515–148.6485 MHz` (`148.5 MHz ±0.1%`).

The final authorized text must cite the independent video-mode/clock authority for these values. They must not be justified solely by fitting the ten observed runs. Owner/Architect approval may reject this proposal; it must not substitute undefined tolerances after any new hardware experiment begins.

### Acceptance rule

A frame-rate corroboration passes only when:

1. video is present;
2. `T>=20.0 s`, `N>=500`, and at least 21 usable samples exist before the 30-second cap;
3. `abs(f_frame_ols-f_endpoint)<=0.05 Hz`;
4. the full interval `[f_interval_low,f_interval_high]` lies inside `24.900000–25.100000 Hz`;
5. `f_sav_ols/1125` lies inside `24.900000–25.100000 Hz` under the qualified 1,125-total-line mode;
6. `f_vclk_ols` lies inside `148.3515–148.6485 MHz`;
7. no counter-integrity rule fails.

Frame corroboration remains subordinate to NACK/retry/recovery/safety criteria. It cannot turn a `RECOVERED_PASS` into `CLEAN_PASS`.

## Historical sequences 1–10

The existing receipts, raw data, halt, and classifications remain immutable. Do not create a retrospective CLEAN_PASS overlay. The short captures cannot be represented as missing 20-second observations, and post-hoc thresholds cannot restore prospective uniformity.

Disposition: `KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID`. This means invalid for pooling into a causal primary denominator, not that the recorded identity, autoinit, recovery, timing, or counter data is false. Sequences 1–10 remain exploratory evidence under the historical frozen protocol.

## Required measurement-control validation

Before this proposal can govern a new causal campaign, a separately authorized control experiment must predeclare and demonstrate:

1. a stable known video input plus an independent analyzer, VSYNC timing capture, or authoritative source timing reference;
2. simultaneous FRAME, all-SAV, and VCLK evidence;
3. repeated approximately one-second windows with deliberately varied sampling phase, showing the expected legacy 25/26-event branches without a physical cadence change;
4. the proposed at-least-20-second OLS/endpoint method agreeing with the independent cadence reference;
5. the finite two-second no-video branch terminating correctly;
6. candidate-neutral arithmetic, thresholds, and evidence retention.

## New campaign use if authorized and validated

1. Publish the approved amendment and measurement-control validation before causal DUT work.
2. Preserve all original R2 evidence and the historical 10/32 halt.
3. Assign a new experiment identifier, run ledger, and denominator.
4. Re-establish Owner-mediated DUT exclusivity and exact safe baseline.
5. Start a new full balanced causal campaign at its own sequence 1.
6. Use the amended measurement uniformly for every run in that new campaign and its separately specified qualification work.
7. Do not execute old R2 sequence 11 and do not pool sequences 1–10 into the new denominator.
8. Keep R3 required; do not start it without separate authorization.

## Bias and integrity controls

- one rule for every candidate;
- no candidate-specific target/tolerance;
- no deletion or overwriting;
- publish before any new hardware work;
- preserve original results as exploratory evidence outside the new denominator;
- predeclare counter-integrity and auxiliary-rate tolerances;
- require independent QA of calculations;
- require Owner approval in the same control channel.

## Approval block

- Proposal status: `PROPOSED — NOT AUTHORIZED`
- Owner approval: `NOT PROVIDED`
- Approval timestamp: `N/A`
- Effective protocol revision: `N/A`
- Hardware continuation authorized: `NO`
- New control experiment authorized: `NO`
- New causal campaign authorized: `NO`
