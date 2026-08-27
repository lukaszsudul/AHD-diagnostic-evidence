# AHD v41 R0 — Margin-Characterization Trigger and R3 Outline

## Decision rule

R3 margin characterization is **mandatory** if the valid primary result is:

`C1 FAIL, C2 FAIL, C3 PASS`.

This pattern supports a positive interaction at the tested levels: neither reduced configuration is sufficient, while combined qualified timing is clean. It does not reveal the size of the passing region.

R3 is also mandatory before any stronger mechanism/margin claim when one or more of the following predeclared conditions occurs:

- any exact-C3 cold start is not `CLEAN_PASS`;
- retry, recovered, timeout, or C2 endpoint-guard counters activate in any otherwise valid R1i-derived run;
- a C1, C2, or C3 cell contains mixed classifications;
- SCL wait maximum or qualified-NACK behavior is intermittent beyond the filter-only/reference distribution;
- INIT_DONE timing range exceeds `max(2% of median, 5 ms, 2 × maximum host bracket)` or shows a discrete retry/backoff mode;
- the same variant’s result/counters depend on order, predecessor, block, warm-up, or time since power application;
- C0 does not reproduce after its one permitted block repeat;
- C3 is non-clean after its one identity/environment replay;
- C2 safety guard activates, because its late sample was not physically legal at the endpoint.

If a trigger arises from identity, corrupted capture, loss of lock, or unrecoverable environment invalidity, resolve that validity issue before R3. Do not use a margin sweep to tune away an invalid experiment.

## First R3 sweep: sample offset only

Purpose: locate PASS, transition, and FAIL regions while preserving the qualified bus waveform and all non-sample variables.

Hold constant:

- qualified SCL-HIGH gating (Q=1);
- total C3 qualified-HIGH dwell and protocol-decision tick;
- I²C frequency at 25 kHz;
- NVP initialization table and order;
- reset/start/final-settle policy;
- synchronizer/filter, output decoder, STOP/BUS_FREE/retry/backoff/bank safety;
- top/XDC/XDMA, DUT, environment, tool flow, and capture method.

Let `D=DIVIDER+1`. Select and hold SDA at `k` base-clock cycles after the first controller edge observing filtered SCL HIGH. The coarse set is:

`{0, 1, 2, 4, 8, round(D/16), round(D/8), round(D/4), round(D/2), round(3D/4), D}`

Remove duplicates and points outside `[0,D]`. The state remains HIGH and the protocol decision remains at the original terminal tick regardless of `k`.

Use counterbalanced repeated starts and bracket each sweep block with exact C0/C3 controls. A coarse point is:

- PASS region when all strict runs are `CLEAN_PASS`;
- transition region when clean, recovered, NACK, or fail outcomes mix or telemetry varies;
- FAIL region when all valid runs fail the clean criterion.

After the first PASS/transition/FAIL boundary is bracketed, test every single base-clock cycle in that bracket. Repeat boundary points sufficiently to distinguish stable from intermittent behavior; predeclare the repetition count before R3 execution. Convert cycles to nanoseconds only with the clock frequency measured under `R0_INIT_DONE_TIMING_PROTOCOL.md`.

## Later sweeps, only if required by evidence

If sample-offset-only testing finds no boundary, a later authorized stage may vary qualified HIGH dwell or duty partition while preserving the 25 kHz period. That stage changes more than the sample latch and must be treated as a separate factor. Do not change I²C frequency, NVP table, or reset policy in the first margin sweep.

Readiness/retry isolation is secondary and uses the smallest safe contrast described in the main plan: Q+L retained, legal STOP/BUS_FREE/bank invalidation retained, retry disabled after the first failed attempt. This is not part of R3 unless explicitly authorized.

## Required R3 result language

Report the observed PASS, transition, and FAIL regions in cycles and, only after clock measurement, in time. Use `SUPPORTED` or `INCONCLUSIVE`; do not call a boundary a device specification, universal setup time, or proof of clock stretching. The measured boundary includes FPGA input/output/filter/placement, board rise time, slave behavior, and environmental effects on the tested DUT.
