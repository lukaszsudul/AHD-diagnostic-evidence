# AHD v41 R0 R1i Causal Isolation Experiment Plan

## 1. Executive conclusion

R0 freezes a causal-isolation design and authorizes no implementation or execution. The design defines exactly two future candidates:

- **C1 / R1i-a:** retain qualified R1i physical-SCL gating and all recovery behavior, but select ACK from the first synchronous controller edge that observes the existing filtered SCL signal HIGH. The selected sample is held while the full qualified-HIGH `DIVIDER+1` dwell completes.
- **C2 / R1i-b:** retain qualified R1i recovery behavior and the late nominal ACK endpoint, but run ordinary protocol-HIGH states from the internal divider rather than pausing their timing for filtered SCL HIGH. A filtered-SCL-LOW endpoint is never treated as an ACK; it activates the frozen safety/recovery path and makes that causal run `INCONCLUSIVE`.

C3 is the exact qualified R1i image. C0 is the exact R1h control. STOP generation, BUS_FREE proof, bounded retries, backoff, error terminality, bank invalidation, telemetry ABI, initialization data, 25 kHz rate, reset/start/final-settle policy, synchronizers, filters, top level, XDC, and XDMA are held fixed across C1/C2/C3.

This is an **anchored**, not perfectly symmetric, 2×2. C0 must remain exact R1h and consequently has legacy recovery/readiness behavior. C0 is used to prove that the historical failure condition reproduces; causal sufficiency statements come from C1/C2/C3 and always mean “in the frozen R1i recovery/readiness background under the tested condition.”

Engineering design gate: **PASS**. The qualified functional verdict is unchanged. R1 is the next permissible phase and must stop before hardware unless separately authorized.

## 2. Qualified R1i baseline

The following identities are frozen and were cross-checked against the published source provenance, exact patch, artifact receipt, and qualified hardware evidence:

| Item | Frozen identity |
| --- | --- |
| R1h base commit / tree | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` / `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| Qualified R1i commit / tree | `20c3323d79d3896edc586d6db1df7deee60f9e41` / `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Qualified R1i bitstream SHA-256 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| Exact R1h control bitstream SHA-256 | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` |
| Formal Phase-2 safe bitstream SHA-256 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` |
| Exact published R1h→R1i source patch SHA-256 | `01A2CD8C5F87B9F532F1FA6152F7D2DC0A039525345F8AB1AAE6A4F2CCD55238` |
| FPGA / top / build tool | `xc7a35tcsg325-2` / `ahd_capture_top_xdma` / Vivado 2025.2 build 6299465 |
| Scientific verdict / outcome / scope | `THESIS_CONFIRMED` / `STRONG_PASS` / `QUALIFIED_POC_BASELINE` |
| Exact causal mechanism | `INCONCLUSIVE` |

The source patch is authoritative even if another local checkout lacks the historical objects. Published source anchors in qualified `rtl/nvp/nvp6134c_i2c_bringup.vhd` are: state and SCL-high predicates at approximately lines 103–143; unchanged 2-FF synchronizers and 3-sample filters at 333–350 and 481–522; open-drain phase decoder at 446–475; divider gating at 524–539; timeout handling at 541–580; early/qualified ACK helpers at 656–677; main high-state guard at 831–853; ACK state bodies at 1247–1389; and STOP/BUS_FREE/retry/bank-safety logic at 1409–1815. Line numbers are review anchors, not permission to change neighboring logic.

## 3. Known functional result

The frozen same-session A/B result was:

| Observation | A1: fixed R1i | B1: exact R1h |
| --- | ---: | ---: |
| Autoinit NACK total | 0 | 4 |
| `INIT_ERROR` | 0 | 1 |
| Video | Present | Absent |
| Frame rate | 24.803727 Hz | 0 Hz |
| Post-init selected-target phase observations | 0 NACK / 30,000 | 0 NACK / 30,000 |

The R1i runtime source identity was the frozen qualified commit. It reported zero raw qualified NACKs, recovered transactions, exhausted retries, timeouts, and bank-invariant errors. The observed maximum SCL-high wait was eight base-clock cycles; this includes synchronizer/filter latency and is not proof of slave clock stretching.

Post-init traffic is not used as evidence of autoinit robustness. The causal endpoint is the autoinit capture obtained before any post-init diagnostic traffic.

## 4. Remaining causal uncertainty

The qualification tested a combined correction. It did not establish which low-level timing or readiness component caused the result. In particular, the frozen evidence does not distinguish:

- waiting for resolved, filtered SCL HIGH from merely delaying the ACK sample;
- a single-factor effect from an interaction between qualification and sample offset;
- a clean first-attempt timing success from success enabled by STOP/BUS_FREE/retry readiness;
- input-filter observation latency from actual slave-driven SCL stretching; or
- expected clock-domain frequency from independently measured clock frequency.

R0 does not reinterpret or downgrade the qualified functional result. It narrows only the mechanism claim.

## 5. Hypothesis decomposition

The primary operational factors are:

- **M1 / Q — ordinary protocol-HIGH physical SCL qualification.** Q=1 means ordinary protocol HIGH progress is held/reset while `scl_filtered_r='0'`, then requires the existing complete qualified-HIGH dwell. Q=0 means ordinary protocol HIGH progress—including START/repeated-START scheduling—is driven by the internal divider. STOP, abort cleanup, and BUS_FREE remain physically qualified in all R1i-derived images because they are the fixed M4 safety shell.
- **M2 / L — selected ACK sample point.** L=early-qualified means SDA is selected on the first controller clock edge that observes `scl_filtered_r='1'` for the HIGH interval that ultimately completes. L=late means SDA is selected at the existing terminal HIGH-state divider tick.
- **M3 — Q×L interaction.** The successful region may require both physical qualification and the later sample.
- **M4 — recovery/readiness shell.** First-NACK abort, legal STOP, BUS_FREE proof, retry/backoff, terminal versus recovered error handling, and bank invalidation may contribute even if Q or L alone does not.

The primary estimand is a **clean autoinit success**: correct runtime identity, `INIT_DONE=1`, `INIT_ERROR=0`, zero selected/qualified autoinit NACKs, zero raw NACKs, no retry/recovery/timeout/exhaustion activity, valid bank telemetry, and normal video. A terminally successful initialization that required recovery is a `RECOVERED_PASS`, not a clean timing PASS.

The terms `SUPPORTED`, `NOT_SUPPORTED`, `SUFFICIENT_UNDER_TESTED_CONDITIONS`, `NECESSARY_UNDER_TESTED_CONDITIONS`, and `INCONCLUSIVE` are used only after the predeclared gates are met. No result is called universal proof of clock stretching or of a sampling-point mechanism.

## 6. Four-variant 2x2 design

| Variant | Q: ordinary protocol physical-HIGH gate | L: selected ACK point | Recovery background | Role |
| --- | --- | --- | --- | --- |
| C0 | Legacy absent | Legacy end-of-LOW / release transition | Exact R1h legacy | Reproducing negative control; not a clean factorial contrast |
| C1 / R1i-a | Present, exact C3 | First observed filtered-HIGH edge | Exact R1i | Tests whether Q supplies sufficient margin when late sampling is removed |
| C2 / R1i-b | Divider-only for ordinary protocol HIGH; safety qualification retained | Existing nominal late internal endpoint | Exact R1i | Tests whether L supplies sufficient margin without ordinary protocol-HIGH waiting |
| C3 | Present | Existing terminal tick after complete qualified-HIGH dwell | Exact qualified R1i | Positive baseline and combined Q+L cell |

C1 and C2 are separate direct derivatives of C3; neither may be derived from the other. C3 is not rebuilt for the primary hardware comparison: use the exact qualified bitstream. C0 uses the exact published R1h control bitstream.

### Primary run design

Use eight independent runs per cell under the exact frozen A/B start/reset/program recipe (or a single reproducing recipe frozen before execution). The four variants are counterbalanced with a Williams order, followed by the reverse campaign order:

1. C0, C1, C3, C2
2. C1, C2, C0, C3
3. C2, C3, C1, C0
4. C3, C0, C2, C1
5. C3, C0, C2, C1
6. C2, C3, C1, C0
7. C1, C2, C0, C3
8. C0, C1, C3, C2

Restore and verify the approved safe baseline after every run. Each row is performed while holding `FPGA_AHD_HW_LOCK`; the lock may be released only after safe restoration. Runs are independent, and no post-init probe is issued before the autoinit snapshot.

A C1/C2/C3 run is `CLEAN_PASS` only if every clean criterion in Section 5 is satisfied and the measured frame rate is 24.803727 Hz ±0.10 Hz using the same method. A final success with any raw NACK, retry, recovered transaction, or safety-guard activation is `RECOVERED_PASS`. A valid, consistently terminal non-pass is `FAIL`. Mixed clean/fail/recovered results make the cell `VARIABLE/INCONCLUSIVE`. Cell PASS requires 8/8 `CLEAN_PASS`.

C0 reproduces the negative condition when its exact image and identity are valid and it records at least one autoinit NACK with terminal error and absent video. The historical count of four is not required to repeat exactly. A C0 clean pass invalidates that block. Repeat the entire block once only after verifying identity, recipe, and environment; if C0 again passes, stop causal attribution rather than tuning the environment toward a preferred result.

Any non-clean C3 run invalidates its block and suspends the campaign for identity/environment review. It does not revise the frozen qualification.

## 7. Exact R1i-a definition

R1i-a is C1 and is derived directly from qualified R1i.

### Release and observation

- The existing terminal tick in each `ACK_W_LOW`, `ACK_REG_LOW`, `ACK_DATA_LOW`, and `ACK_R_LOW` state advances to its matching `ACK_*_HIGH` state.
- The unchanged combinational open-drain decoder holds SCL LOW and releases SDA in `ACK_*_LOW`. Entry to `ACK_*_HIGH` releases SCL. No output-enable equation changes.
- The only observed SCL is the existing `scl_filtered_r` produced by the unchanged two-register synchronizer and three-sample filter. The only sampled SDA is the existing `sda_filtered_r` from the corresponding unchanged path.

### Exact sample event

- On entry to `ACK_*_LOW`, arm/clear one local selected-ACK value/valid latch while preserving the existing end-of-LOW `capture_early_ack` telemetry.
- In `ACK_*_HIGH`, on the first rising edge of the controller base clock on which the sequential controller observes `scl_filtered_r='1'`, latch `sda_filtered_r` and assert selected-sample valid.
- “Immediately” means zero completed base-clock cycles after that filtered-HIGH observation: the sample occurs on that synchronous observation edge. It never means raw-pad or asynchronous sampling. Pad-to-sample latency remains phase-dependent because the frozen synchronizer/filter remains in the path.
- If `scl_filtered_r` returns LOW before the HIGH dwell completes, clear selected-sample valid. The next HIGH interval is sampled again on its first observed-HIGH edge. Thus the selected sample belongs to the same consecutive-HIGH interval that permits progress.

### Dwell, progress, and stretching

- The qualified R1i divider reset/stall expression is unchanged. While a state requiring HIGH observes filtered SCL LOW, `tick_cnt` is held/reset to zero.
- The complete existing `DIVIDER+1` consecutive-filtered-HIGH dwell is retained. The FSM advances only on the existing terminal `tick` after that dwell.
- At the terminal `ACK_*_HIGH` tick, all ACK decisions and qualified/raw NACK accounting use the held selected sample, not live SDA. SCL waveform and state duration remain C3.
- The existing 20 µs SCL-unavailable timeout, abort-high recovery, STOP, BUS_FREE, and retry path are unchanged. If SCL never qualifies, no ACK is sampled and the timeout path executes.
- Clock stretching is *honored by construction* in C1, but an observed wait does not by itself prove that a slave stretched SCL; filter latency and line rise time are alternative causes.

Only ACK selection changes. Read-data sampling remains exact C3.

Relative to C3, C1 changes the selected ACK latch and four ACK decisions only. Relative to R1h, it retains R1i physical qualification, full HIGH dwell, first-NACK abort, legal recovery, telemetry, and bank safety, while selecting ACK earlier than C3 but still after filtered physical HIGH is synchronously observed.

## 8. Exact R1i-b definition

R1i-b is C2 and is derived directly from qualified R1i.

### Divider-only ordinary protocol timing

- Define the ordinary protocol-HIGH set as `START_W_A`, `START_W_B`, `SEND_W_HIGH`, `ACK_W_HIGH`, `SEND_REG_HIGH`, `ACK_REG_HIGH`, `SEND_DATA_HIGH`, `ACK_DATA_HIGH`, `REP_HIGH`, `REP_START_A`, `SEND_R_HIGH`, `ACK_R_HIGH`, `READ_HIGH`, and `MASTER_NACK_HIGH`.
- For exactly this set, the HIGH-state divider starts at state entry/SCL release and runs to the existing `DIVIDER` endpoint without reset or stall based on `scl_filtered_r`.
- State advancement therefore follows the internal divider only during its nominal interval. No earlier or new sample state is added.
- START/repeated-START state bodies and output-drive equations remain exact C3, but their progress scheduler is part of Q and therefore divider-only in C2. STOP (`STOP_B`, `STOP_C`), abort recovery, and BUS_FREE keep exact C3 physical qualification. This explicit M4 exception is the smallest safe approximation; manufacturing a STOP or consuming ACK while SCL is known LOW is prohibited.

### ACK selection and low-at-endpoint guard

- At the existing terminal tick of each `ACK_*_HIGH` state, sample live `sda_filtered_r` only when `scl_filtered_r='1'` at that same edge. This is the C3 nominal late offset measured from commanded SCL release, not from a proven physical-HIGH transition.
- If filtered SCL remains LOW at any ordinary protocol-HIGH endpoint, do not sample SDA, do not count an ACK opportunity, and do not advance to a later protocol phase. Record one SCL-unavailable/deadline event through the existing timeout/error telemetry and enter the exact C3 `ABORT_HIGH_RECOVERY` → legal STOP/`ABORT_RELEASE` → `BUS_FREE` → bounded retry/terminal path.
- The existing 20 µs watchdog remains active. In the frozen 25 kHz source configuration, `DIVIDER=1250`, the scheduled state dwell is 1251 base-clock edges, and `C_SCL_TIMEOUT_CYCLES=1250`; a scheduled filtered-LOW miss therefore coincides with the existing bounded timeout rather than introducing a new shorter readiness bound. The same C3 cleanup/retry bodies execute. No silent workaround is allowed.

### Scientific limitation

It is impossible to guarantee a middle/later sample *relative to physical SCL HIGH* without observing physical SCL HIGH. C2 is therefore late relative to the controller’s internal SCL-release schedule. Any stretch or slow rise shortens the actual physical-HIGH aperture; a LOW endpoint activates the safety guard. If that guard or any timeout/retry/recovered counter is nonzero, C2 is not a valid M2 sufficiency test and the run is `INCONCLUSIVE`, even if initialization eventually succeeds.

Relative to C3, C2 changes only ordinary protocol-HIGH progress qualification and the endpoint-low dispatch. Relative to R1h, it retains R1i late nominal ACK sampling, first-NACK abort, legal STOP/BUS_FREE/retry, error terminality, bank safety, and telemetry. It is not permitted to remove STOP/BUS_FREE qualification merely to make Q=0 mathematically pure.

## 9. Controlled variables

The following are invariant across C1/C2/C3 and must be proven by source and build receipts:

- NVP initialization table and operation order;
- I²C frequency parameter: 25 kHz;
- reset, start, and final-settle policies;
- SDA/SCL two-register synchronizers and three-sample filters;
- open-drain output decoder except no changes are authorized at all;
- START/repeated-START implementation;
- first-qualified-NACK abort;
- STOP, abort-high recovery, BUS_FREE proof and bounds;
- three retries/four total attempts and fixed 100 µs, 500 µs, 2,000 µs backoffs;
- recovered versus terminal error handling;
- bank-state invalidation and bank-invariant checks;
- MMIO telemetry layout, addresses, magic, version, record formats, and legacy address behavior;
- instrumentation fanout into functional logic;
- top level, XDC, pins/electrical properties, XDMA XCI/configuration, and unrelated datapaths;
- FPGA part, Vivado version/build, synthesis/implementation strategy and seed;
- host decoder version, raw capture order, counter-clear policy, and video-rate method;
- one DUT, cable/pull-up/power configuration, environmental envelope, and start recipe.

Runtime source identity and bitstream SHA necessarily differ for C1/C2 and must identify the exact candidate. The R1i telemetry ABI remains unchanged; inherited policy flag value is not evidence of the selected sample mechanism. Candidate identity comes from the runtime source commit and evidence manifest.

## 10. Confounders

Predeclared confounders and controls are:

1. **C0 recovery mismatch.** Exact R1h lacks the frozen R1i recovery shell. C0 is only a reproducing negative control. No pure C0→C1/C2 single-factor claim is allowed.
2. **Legal early point differs from R1h.** C1’s first-filtered-HIGH sample is necessarily later than R1h’s end-of-LOW sample. This is the earliest legal/synchronous approximation.
3. **C2 cannot be physically late without physical observation.** Its selected point is late only in the internal schedule. Safety-guard activation invalidates M2 attribution.
4. **Recovery can mask timing failure.** Raw NACK/retry/recovered counters take precedence over terminal `INIT_ERROR`. A recovered run is not a clean causal pass.
5. **Filter latency can look like stretching.** SCL wait counts include synchronization, filter, line-rise, and slave-hold components. No clock-stretch proof is made without independent waveform or calibrated excess wait.
6. **P&R variation.** Candidate RTL changes can alter implementation placement. Use identical tool/seed/strategy and compare post-route timing, I/O paths, clocks, and utilization; remaining implementation variation is disclosed.
7. **Read timing.** C2’s Q factor also changes scheduling of the listed `READ_HIGH` transfer state. Read-data values and operation sequence must be checked; a read-integrity failure is a C2 failure, not silently reclassified as ACK evidence.
8. **Order/readiness drift.** Counterbalanced order, C0 reproduction, C3 positive control, safe restore, and per-run environmental records are mandatory.
9. **Post-init contamination.** Autoinit telemetry is captured before any diagnostic traffic. Post-init zero-NACK traffic cannot rescue an autoinit failure.
10. **Clock-frequency expectation.** The source’s nominal `CLK_HZ` value is not a measurement. INIT_DONE timing is interpreted only after counter slope is independently estimated.

## 11. STOP/BUS_FREE/retry handling

Primary experiment: **hold M4 constant in C1/C2/C3**. The code bodies, constants, predicates, telemetry, and bank effects of first-NACK abort, STOP, abort recovery, BUS_FREE, retry/backoff, recovered/terminal error distinction, and bank invalidation must be byte-for-byte identical to C3. C2 may dispatch into those bodies on its explicitly defined endpoint-low guard; it may not edit them.

C0 remains exact R1h, so its M4 mismatch is unavoidable and disclosed.

If any valid C1/C2/C3 run activates raw NACK, retry, recovered, timeout, or endpoint guard, primary attribution is suspended. The smallest secondary experiment is a separately authorized **C3-no-retry** image: retain Q+L, first-NACK abort, legal STOP, BUS_FREE, timeout, and bank invalidation, but terminate after the first failed attempt instead of entering retry/backoff. This would isolate bounded readiness retry from the qualified timing shell. Removing legal STOP or BUS_FREE is not proposed; they are safety invariants, not optional factors. No secondary candidate is authorized by R0 or R1.

## 12. Telemetry requirements

For every primary run, preserve raw words and decoded output and record:

- common/runtime identity, source commit and bitstream SHA;
- `INIT_DONE`, `INIT_ERROR`, decoded FSM/init state;
- WADDR, REGADDR, DATA, and RADDR autoinit opportunities and selected/qualified NACKs;
- raw qualified NACK total;
- legacy end-of-LOW early count and early-false count per phase;
- retry count, success-on-retry counts, recovered transaction/NACK counts, unrecovered count, exhausted count;
- SCL-high wait maximum and SCL-unavailable/timeout count;
- failed-attempt record(s), terminal error code, first recovered/unrecovered identifiers;
- bank validity and invariant counts;
- video present/absent and frame/SAV/video-clock measurements;
- counter clear time, autoinit snapshot time, and confirmation that no post-init probe preceded it.

Interpretation is frozen as follows:

- `INIT_DONE=1` is necessary but not sufficient.
- `INIT_ERROR=1` makes a valid run FAIL. `INIT_ERROR=0` with recovery activity is `RECOVERED_PASS`, not `CLEAN_PASS`.
- Any autoinit selected/qualified NACK or raw NACK prevents `CLEAN_PASS`, even when a retry succeeds.
- Video is a functional corroborator. Video absent with valid identity is FAIL; video present cannot override NACK/recovery evidence.
- Retry or recovered counts above zero mean M4 activated and M1/M2 sufficiency is `INCONCLUSIVE` for that run.
- Exhausted retry or unrecovered count above zero is terminal FAIL.
- Early/early-false counters are mechanistic evidence only. A nonzero early-false count with zero selected NACK supports early-point vulnerability; zero does not disprove it.
- Qualified-NACK counters define the selected decision result. Opportunities must reconcile with the executed transaction path.
- SCL wait above zero proves only that the filtered signal was not immediately observed HIGH. Timeout/endpoint-guard above zero prevents a clean causal pass. C2 guard activation invalidates its pure M2 interpretation.

## 13. Predeclared outcome interpretation

The detailed matrix is frozen in `R0_OUTCOME_INTERPRETATION_MATRIX.csv`. The core mapping, applied only when C0 reproduces, C3 is clean, all cells are stable, and no recovery/guard activates, is:

| C1 | C2 | C3 | Predeclared interpretation |
| --- | --- | --- | --- |
| PASS | FAIL | PASS | M1 configuration is `SUFFICIENT_UNDER_TESTED_CONDITIONS` in the frozen M4 background; M2-only sufficiency is `NOT_SUPPORTED` |
| FAIL | PASS | PASS | M2 configuration is `SUFFICIENT_UNDER_TESTED_CONDITIONS` in the frozen M4 background; M1-only sufficiency is `NOT_SUPPORTED` |
| PASS | PASS | PASS | Either reduced configuration independently supplies sufficient tested margin; neither factor is `NECESSARY_UNDER_TESTED_CONDITIONS` within this grid; M4-only sufficiency remains unresolved |
| FAIL | FAIL | PASS | Positive Q×L interaction: the combined timing is required at tested levels; individual sufficiency is `NOT_SUPPORTED`; R3 is mandatory |
| PASS | PASS | FAIL | Invalid/inconsistent experiment, identity/environment drift, or baseline replay failure; no causal claim |

Any C3 FAIL pattern is invalid for mechanism attribution. Any mixed, recovered, timeout, or safety-guard pattern is `INCONCLUSIVE`. A C0 PASS triggers the one-repeat reproduction rule in Section 6; repeated C0 PASS stops the campaign.

“Necessary” and “sufficient” never extend beyond this DUT, implementation levels, start condition, and fixed M4 background.

## 14. Cold-start robustness protocol

The exact qualified R1i undergoes a separate 10-consecutive-cold-start campaign defined in `R0_COLD_START_PROTOCOL.md`. It is not pooled with the primary factorial runs.

The campaign is one locked experiment: exact R1i is the first FPGA image allowed to exercise the NVP after each true rail-off start; no other image or unrelated task is interleaved. Required per-start fields are `INIT_DONE`, `INIT_ERROR`, WADDR/REGADDR/DATA NACKs, retry count, recovered count, exhausted count, SCL timeout, video, frame rate, and runtime identity, plus raw telemetry and environmental/order metadata.

Acceptance is 10/10 with `INIT_ERROR=0`, total required autoinit NACK=0, video present, valid runtime identity, no timeout, and no exhausted retry. Any retry/recovered activity is a margin warning and triggers secondary/R3 consideration even if the terminal result is successful. Restore the exact approved safe baseline after the ten-start campaign before releasing the hardware lock.

## 15. INIT_DONE timing protocol

`R0_INIT_DONE_TIMING_PROTOCOL.md` freezes a two-clock measurement rather than inferring time from source constants.

The qualified design contains an existing 48-bit configuration-initialized, free-running `axi_aclk` lifecycle counter and captures its value at the first sampled `INIT_DONE`; autoinit is also driven from `axi_aclk`. Published raw values are A1 `133,683,129` and B1 `132,584,735` counter-origin cycles. The routed timing summary reports `userclk1` at 16.000 ns (62.5 MHz), while stale/conflicting XCI interface metadata also contains 125 MHz. At 62.5 MHz the A1 counter-origin interval is 2.138930064 s—not 1.81 s. The 1.810922864 s / 0.905461432 s pair comes from the separate historical `113,182,679`-cycle reference divided by 62.5/125 MHz. These are provenance facts and hypotheses, not the missing independent wall-clock measurement.

Record the counter start definition/value, the latched counter at `INIT_DONE`, and the modulo-2^48 delta. Separately measure live counter slope against a host monotonic clock using repeated bracketed reads and record the counter’s traced clock source.

Host event timing uses a last-`DONE=0` / first-`DONE=1` bracket and start-command/configuration brackets. It distinguishes configuration-to-done from transaction-engine-start-to-done. If no exact transaction-engine start timestamp is observable, that narrower duration remains `INCONCLUSIVE` rather than being derived from an expected constant.

Evaluate, but do not assume:

- H62.5: about 1.81 s corresponds to a ~62.5 MHz counter domain;
- H125: about 0.905 s corresponds to a ~125 MHz counter domain.

A hypothesis is `SUPPORTED` only if the independently inferred clock-frequency interval includes it and excludes the other, and the counter-derived elapsed time agrees with the host event bracket. The design permits both hypotheses to be falsified.

## 16. Margin-characterization trigger

R3 is mandatory when C1 FAIL and C2 FAIL while C3 PASS. It is also mandatory or required before stronger mechanism claims if any of the following occurs:

- any of the 10 qualified-R1i cold starts is not clean;
- retry/recovery/timeout/endpoint-guard activity is intermittent;
- a primary cell is mixed/variable;
- INIT_DONE counter or wall timing varies materially beyond the frozen uncertainty rule;
- result classification, raw counters, or wait maxima depend on run order/predecessor;
- C2’s safety guard activates;
- C0 or C3 fails its required control role after the predeclared repeat.

Exact thresholds and actions are in `R0_MARGIN_CHARACTERIZATION_TRIGGER.md`.

## 17. Proposed R3 sweep

The first R3 sweep keeps Q=1, the total C3 qualified-HIGH dwell, I²C frequency, initialization table, reset, start, and recovery behavior fixed. Only the selected SDA latch offset changes.

Let `D=DIVIDER+1` and `k` be additional base-clock cycles after the first edge observing filtered SCL HIGH. Coarse points are the rounded, deduplicated set:

`k = {0, 1, 2, 4, 8, D/16, D/8, D/4, D/2, 3D/4, D}`.

The protocol decision still occurs at the original terminal dwell; only the held sample changes. Coarse points use counterbalanced repeated starts with C0/C3 bracketing. After a boundary appears, sweep every single cycle across the last PASS/first FAIL bracket. Convert cycles to time only with the independently measured clock frequency.

- PASS region: every strict run is clean.
- Transition region: mixed, recovered, NACK, or variable runs.
- FAIL region: every valid run fails the clean criterion.

Only if sample offset does not locate a boundary may a later, separately approved sweep vary HIGH duty/dwell while preserving the 25 kHz period. The first sweep does not change I²C frequency, NVP table, or reset policy.

## 18. Hardware-lock requirements

`FPGA_AHD_HW_LOCK` is a mandatory exclusive mutex for the one physical DUT.

Before any R-track hardware action, the operator must atomically acquire the project-approved lock and record owner, track/task, UTC and monotonic acquisition times, DUT identity, intended image hash, and current safe-baseline identity. A pre-existing G-track or R-track holder blocks all hardware work. Stale locks are never auto-broken; ownership is reconciled manually.

The holder keeps the lock through programming, reset/power sequencing, capture, and restoration. Analysis and builds may run in parallel elsewhere, but hardware experiments are sequential. After every primary run—and after the complete consecutive cold-start campaign—restore and verify the exact approved safe baseline. The preferred frozen image is Formal Phase-2 SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`; a replacement is allowed only if the current project state explicitly freezes its source/runtime/bitstream identities before the experiment.

Release the lock only after safe-image programming and runtime identity read-back pass. If restoration fails, retain the lock, stop, and escalate; do not leave the DUT available to G-track.

## 19. R1 implementation contract

The binding contract is `R0_R1_IMPLEMENTATION_CONTRACT.md`.

Both candidates are direct derivatives of qualified commit `20c3323d79d3896edc586d6db1df7deee60f9e41`. The only synthesizable file permitted to change is `rtl/nvp/nvp6134c_i2c_bringup.vhd`. No state enumeration or inherited debug encoding changes are allowed. Candidate A may add only the selected ACK value/valid latch and modify the four ACK decision sites/helpers. Candidate B may modify only the ordinary protocol-HIGH progress predicate/tick-stall dispatch and endpoint-low safety dispatch; STOP/abort/BUS_FREE/retry bodies remain untouched.

R1 uses the recommended isolated branch/worktree (`research/v41-r1i-causal-isolation`, `C:\FPGA\R1I_RCA`) but must create separate direct-base candidate refs so A and B are siblings, not stacked commits. R0 creates neither.

R1 must perform source allowlist review, signal-fanout review, state-encoding review, focused offline simulation, clean canonical builds, timing/DRC review, and bitstream hashing. Hardware execution in R1 is prohibited unless separately and explicitly authorized; any later hardware action also requires `FPGA_AHD_HW_LOCK`.

## 20. Risks and limitations

- The four canonical variants do not provide a recovery-matched Q=0/L=early cell because C0 must remain exact R1h. Claims are limited accordingly.
- C2 is necessarily a safe approximation. A pure “ignore LOW and consume SDA” variant would be protocol-illegal and is prohibited.
- One DUT and one NVP population limit generalization.
- Eight clean runs per cell and ten cold starts characterize observed repeatability, not rare-event production reliability.
- No waveform directly separates slave stretch from filter/rise-time latency in the primary campaign.
- P&R differences remain a residual implementation confound even with a frozen tool flow.
- Host polling brackets event time; the hardware counter supplies cycle precision, while an exact transaction-engine start requires an observable start event.
- Frame rate is corroborative and its tolerance is tied to the published measurement method; it is not an ACK-margin metric.
- Any secondary no-retry experiment or R3 parameterization requires a new authorization and contract. R0 authorizes only R1i-a and R1i-b.

## 21. Recommended next step

R1 — implement exactly R1i-a and R1i-b as separate direct derivatives of the qualified R1i commit under `R0_R1_IMPLEMENTATION_CONTRACT.md`; perform only the contracted source reviews, offline tests, and builds. Do not execute hardware without separate authorization. Hard stop after the R0 design and publication in this task.
