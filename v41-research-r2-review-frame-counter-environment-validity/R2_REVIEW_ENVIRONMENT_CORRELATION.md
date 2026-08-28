# R2 Review — Environment and Order Correlation

## Purpose

This review tests whether the 25/26 frame-event branch correlates with candidate, time, reboot epoch, predecessor, or an observed environment transition.

## Chronological video-present sequence

| Seq. | Cell | Capture UTC | Boot ID | Frame events | Historical class |
|---:|---|---|---|---:|---|
| 2 | C1 | `2026-08-28T12:43:00.550135121Z` | `f9579d81-131a-499c-a8b7-27a0d45d943a` | 26 | INCONCLUSIVE |
| 3 | C3 | `2026-08-28T13:56:14.271902637Z` | `c75e10c6-ceef-4fea-8aa0-c1bbdf839bed` | 25 | CLEAN_PASS |
| 4 | C2 | `2026-08-28T14:33:14.911984234Z` | `e1260e4e-7caa-455f-82e3-a8c4445c976d` | 25 | CLEAN_PASS |
| 5 | C1 | `2026-08-28T15:07:54.427864177Z` | `387df384-29f4-4c09-874b-a9c8b6a18adc` | 26 | INCONCLUSIVE |
| 6 | C2 | `2026-08-28T15:38:59.653345788Z` | `0d1ddd57-2c96-416f-af29-28b311a4cdbd` | 26 | RECOVERED_PASS |
| 8 | C3 | `2026-08-28T16:42:19.052471958Z` | `e973858e-0bc9-4822-a857-343cd930f9a2` | 25 | CLEAN_PASS |
| 9 | C2 | `2026-08-28T17:22:11.781192804Z` | `aa4bdc08-10ce-4513-9ec5-d4907e61a362` | 25 | RECOVERED_PASS |
| 10 | C3 | `2026-08-28T18:07:49.947408945Z` | `471fed49-f2ef-4693-8105-b61814d6e100` | 26 | INCONCLUSIVE |

Observed branch sequence: `26, 25, 25, 26, 26, 25, 25, 26`.

## Candidate correlation

- C1: 26, 26
- C2: 25, 26, 25
- C3: 25, 25, 26

C2 and C3 independently occupy both branches. C1's two observations occupy only 26, but the small count and cross-candidate occurrence do not support a C1-specific rate change.

Conditioned on four upper-branch positions among eight, the one-sided probability that both C1 positions are upper is `6/28=0.214`. This is not statistically persuasive.

## Time correlation

The pattern does not drift monotonically with wall time. Both branches appear early, middle, and late. Run 10 is the latest observation, but it is the fourth 26-event observation, not the first.

- high/low indicator versus sequence: Pearson `r≈-0.046`;
- numeric rate versus sequence: Pearson `r≈-0.052`.

## Reboot and predecessor correlation

Every run has a distinct planned warm-reboot boot ID. Both branches appear across distinct boots. C3's 25-event branch follows C1 and C0; its 26-event branch follows C2. C2 itself produces both branches after different scheduled predecessors.

The safe Formal baseline was restored after each completed run. The ledger reports no external state transition or authority-continuity loss.

The recorded programming/runtime environment is invariant:

- host: `VCDE-DUT-1`;
- kernel: `7.0.0-29-generic`;
- endpoint: `10ee:7011`, subsystem `10ee:0007`, class `058000`;
- link: `GEN1_X1`;
- XDMA load: exactly once per planned host transition;
- XDMA module SHA-256: `1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A`;
- XDMA loader SHA-256: `7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F`;
- candidate program result: `PASS_SAME_SESSION_DONE_1`, one invocation, zero retries;
- pre-capture NVP MMIO reads/writes: `0/0`;
- DMA: `0`;
- exact Formal Phase-2 restoration after every completed run: `PASS`.

Each Formal post-restore boot ID becomes the next candidate pre-reboot boot ID. That continuity rejects an unexplained host reboot or reset epoch.

## Measurement-window correlation

The exact raw-monotonic time windows overlap:

- 25-event windows: `1.007711409000–1.008097595500 s`
- 26-event windows: `1.007836160500–1.008668054000 s`

A longer window does not deterministically produce 26. Sequence 3's 25-event window exceeds the 26-event windows at sequences 2, 5, and 6.

Numeric rate versus actual window has Pearson `r≈0.386`, driven mainly by sequence 10. The branch ranges overlap, so this does not supply a window-length explanation.

## Recovery correlation

Recovery is not associated with the upper branch:

- C2 sequence 4: no recovery, 25 events;
- C2 sequence 6: one recovered transaction, 26 events;
- C2 sequence 9: two recovered transactions, 25 events.

Recovery indicator versus numeric rate has point-biserial `r≈0.0047`.

## Auxiliary environment proxies

Normalized SAV and VCLK rates are stable across the video-present prefix. They do not form two clusters aligned with the 25/26 frame count. The pattern is therefore not corroborated by these digital timing proxies.

## Opposition and missing covariates

The package contains no per-run:

- FPGA or board temperature;
- supply-rail voltage/current;
- NVP rail state during warm runs;
- HDMI sink lock/state details;
- oscilloscope or external analyzer timestamps;
- host scheduling latency trace around counter reads.

NVP lock status was not exposed as a dedicated recorded bit. NVP status `0xF9`, video counter evolution, video-present state, and zero marker/error counters are the retained proxies.

Consequently, the review cannot exclude all environmental covariance. It can say that none of the recorded environment/order fields explains the exact integer branch, while sample boundaries not phase-locked to frame events do.

## Environment verdict

- Candidate-specific correlation: `NOT SUPPORTED`
- Monotonic time drift: `NOT SUPPORTED`
- Boot-epoch correlation: `NOT SUPPORTED`
- Predecessor correlation: `NOT SUPPORTED`
- Recorded external-state discontinuity: `NONE`
- Programming-session correlation: `NOT SUPPORTED`
- Formal-restore correlation: `NOT SUPPORTED`
- Recovery correlation: `NOT SUPPORTED`
- Measurement-window correlation: `NOT CAUSAL; BRANCH RANGES OVERLAP`
- Unmeasured environment residual risk: `PRESENT BUT NOT EVIDENCE OF C3 FAILURE`
