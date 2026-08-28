# AHD v41 R2-REVIEW Frame Counter / Environment Validity Investigation

## Executive decision

| Item | Result |
|---|---|
| Engineering review | `PASS` |
| Primary review result | `MEASUREMENT_ARTIFACT_PROBABLE` |
| Confidence | `HIGH` |
| 24.8/25.8 numerical bimodality | `EXPLAINED` |
| Integer/event-window quantization | `CONFIRMED` |
| Exact software `+1` | `ABSENT` |
| Real approximately 4% video timing change | `NOT SUPPORTED`, not absolutely excluded |
| C3 sequence-10 identity | `CONFIRMED_EXACT_R1I`; `C3_IDENTITY_DRIFT=NO` |
| Independent sequence-10 abnormality beyond frame estimate | `NO_RECORDED_INDEPENDENT_ABNORMALITY` |
| Recorded environment/state dependence | `NOT SUPPORTED` |
| Campaign decision | `NEW_CONTROL_EXPERIMENT_REQUIRED` |
| Existing ten observations | `KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID` |
| R3 status | `STILL_REQUIRED` |

The two nonzero populations are the exact outputs of a 25-event or 26-event integer numerator divided by an actual counter-specific window of about 1.008 seconds. One numerator count contributes about `0.992 Hz`; the frozen clean band is only `±0.10 Hz`. Independent SAV and VCLK counters remain near a 25.000-Hz/148.5-MHz video cadence and do not reproduce the apparent `3.9771%` frame-rate step.

The original sequence-10 halt was correct under the then-frozen protocol. This review does not delete, repeat, replace, or relabel any observation. A proposed host-measurement amendment is published separately as `PROPOSED — NOT AUTHORIZED`.

No DUT, SSH, JTAG, reset, programming, MMIO, DMA, firmware, driver, product-source modification, G-track operation, historical-evidence modification, or SSOT operation was performed.

## Authority and evidence integrity

Frozen input:

- repository: `lukaszsudul/AHD-diagnostic-evidence`
- directory: `v41-research-r2-r1i-causal-hardware-owner-mediated-continuation-halted-20260828`
- evidence commit: `a9461192e887db154bef911e2bcbae679cf7dd51`
- source manifest SHA-256: `D6D8FA70973A9A1DFC8406A90A93B527341BAF2A36C0B0F0E104C15A24822002`
- source state SHA-256: `FA3E9C1FC08A89F64729A4146E5049C4D80435D5829FB417B63686BDD4833EE4`
- raw-results SHA-256: `A4A55541D1457202D490C3F7855810B0C79049984FE991CDCF306D648F8189A0`
- halt-receipt SHA-256: `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B`
- final Formal-restore receipt SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`

The complete historical package manifest verified. The 227-event append-only ledger and all ten run completion/capture chains were audited. The historical directory was not modified.

All ten local aggregate raw JSON captures survive. For every run, the aggregate file SHA-256 equals `RAW_CAPTURE_SHA256` in that run's capture receipt committed at `a946119…`; thus the raw T0/T1 counter and monotonic data are cryptographically anchored by the historical evidence. Exact copies are included under `audit/linked_raw_captures/` in this separate review layer.

## Measurement-chain reconstruction

The exact source path is documented in `R2_REVIEW_FRAME_RATE_MEASUREMENT_CHAIN.md`. In summary:

1. VDO1 is captured in the NVP VCLK (`nvp_clk`) domain.
2. The BT.656 producer recognizes `FF 00 00 XY` markers.
3. In steady state, 32-bit `frame_seq_v` increments on the first active-video SAV after vertical blank: a start-of-active-frame event for progressive video. Because `prev_sav_v` resets to `1`, the first post-reset `V=0` SAV is an explicit initialization exception whose absolute count cancels from later T1−T0 windows.
4. A held 324-bit request/ack mailbox transfers the complete frame word coherently to PCIe clock domain; exact CDC constraints and the routed C1/C2/C3 build reports substantiate the source-level structure.
5. MMIO offset `0x0060` exposes one registered 32-bit word.
6. Remote Python executes a four-byte read-only `pread`, timestamped before/after with `time.monotonic()`.
7. A complete 1,532-read T0 inventory, `time.sleep(1.0)`, and complete T1 inventory produce the counter-specific interval.
8. Host arithmetic computes `((T1-T0) mod 2^32) / actual_monotonic_midpoint_elapsed`.
9. The unrounded result is compared with `24.803727 ± 0.10 Hz`; output is then rounded to six decimals.

The printed Hz is **not** `delta / assumed 1 second`. SSH startup/latency is outside the denominator. Scheduler delay, sleep overshoot, inventory traversal, and MMIO latency are incorporated in actual monotonic elapsed time.

## Independent recalculation

All ten observations are exactly recalculable from linked raw monotonic data.

| Seq. | Cell | Historical class | N | Actual frame window (s) | Recalculated Hz | all-SAV/1125 Hz | VCLK Hz |
|---:|---|---|---:|---:|---:|---:|---:|
| 1 | C0 | FAIL | 0 | 1.0079256505 | 0 | 0 | 148500926.903 |
| 2 | C1 | INCONCLUSIVE | 26 | 1.0079279000 | 25.795495888 | 25.000442358 | 148500419.699 |
| 3 | C3 | CLEAN_PASS | 25 | 1.0080975955 | 24.799186221 | 24.999826313 | 148500299.809 |
| 4 | C2 | CLEAN_PASS | 25 | 1.0077114090 | 24.808690044 | 24.999700590 | 148500254.334 |
| 5 | C1 | INCONCLUSIVE | 26 | 1.0079537005 | 25.794835603 | 24.999875243 | 148500331.450 |
| 6 | C2 | RECOVERED_PASS | 26 | 1.0078361605 | 25.797843954 | 25.000097082 | 148500390.757 |
| 7 | C0 | FAIL | 0 | 1.0079740525 | 0 | 0 | 148500479.991 |
| 8 | C3 | CLEAN_PASS | 25 | 1.0078723225 | 24.804729172 | 25.000107647 | 148500212.495 |
| 9 | C2 | RECOVERED_PASS | 25 | 1.0078171540 | 24.806086998 | 24.999682481 | 148500069.258 |
| 10 | C3 | INCONCLUSIVE | 26 | 1.0086680540 | 25.776567323 | 25.001494250 | 148504303.098 |

The all-SAV counter increments every valid `H=0` SAV, including vertical blank. Division by 1,125 here relies on the independently qualified 1,125-total-line video mode; it is not a mode inference made by that counter.

Every six-decimal historical rate is reproduced after ordinary rounding. `R2_REVIEW_FRAME_RATE_RECALCULATION.csv` contains full values, individual hashes, and exact linked evidence paths.

## Population statistics

Video-positive observations, `n=8`:

- overall mean: `25.297929401 Hz`;
- median: `25.292628683 Hz`;
- range: `24.799186221–25.797843954 Hz`.

Population A (`N=25`, n=4):

- mean: `24.804673109 Hz`;
- median: `24.805408085 Hz`;
- range: `24.799186221–24.808690044 Hz`.

Population B (`N=26`, n=4):

- mean: `25.791185692 Hz`;
- median: `25.795165746 Hz`;
- range: `25.776567323–25.797843954 Hz`.

The mean separation is `0.986512583 Hz`, or `3.9771%`. At the mean across all ten observed windows, one count is `0.992084751 Hz`, or `3.9683%` of 25 Hz; the video-positive-only mean gives `0.992077727 Hz`.

For a constant 25-Hz event source, the observed windows contain `25.192785–25.216701` expected events, so unknown phase yields exactly 25 or 26. Predicted bands `24.785161–24.808690` and `25.776567–25.801038 Hz` contain all observations.

## Candidate, order, recovery, session, and epoch review

- candidate distribution: C1=`26,26`; C2=`25,26,25`; C3=`25,25,26`;
- high/low indicator versus sequence: Pearson `r≈-0.046`;
- numeric rate versus sequence: Pearson `r≈-0.052`;
- recovery versus rate: point-biserial `r≈0.0047`;
- measurement window versus rate: `r≈0.386`, driven mainly by sequence 10; branch window ranges overlap;
- both C1 positions high, conditional one-sided probability `6/28=0.214` with only two C1 observations;
- random-phase 25-Hz model: exact varying-window `P(K≥4 of 8)=5.59%`, mildly unusual but plausible.

All runs used the same host, kernel, endpoint/link, XDMA module/loader identities, telemetry payload/adapter, and frame-path RTL. Each had its planned unique warm-reboot boot ID. Each completed run had exact Formal Phase-2 restoration and a continuous boot chain. No unexplained reset, programming event, authority loss, or external state change is recorded.

No temperature, rail, source-generator, external analyzer, or dedicated NVP-lock-bit measurement was recorded; those variables are not invented or treated as controlled evidence.

## C1 special review

Both C1 observations are exact C1 and have:

- `INIT_DONE=1`, `INIT_ERROR=0`;
- zero NACK, retry, recovery, exhaustion, and SCL timeout;
- NVP status `0xF9`;
- video present and all captured video error counters zero;
- SAV and VCLK cadence indistinguishable from clean C2/C3.

There is no independent evidence of a real C1 video-timing anomaly. Historical `INCONCLUSIVE` classifications remain preserved as immutable labels; no retrospective reclassification or pooling into a new primary denominator is permitted.

## C2 special review

Recovery does not correlate with the high frame branch:

- sequence 4: no recovery, 25 events, `24.808690 Hz`;
- sequence 6: one recovered transaction, 26 events, `25.797844 Hz`;
- sequence 9: two recovered transactions, 25 events, `24.806087 Hz`.

C2 recovery is real evidence independent of the frame estimator and continues to support the frozen R3 trigger.

## C3 sequence-10 review

Sequences 3, 8, and 10 independently bind exact C3/R1i:

- bitstream SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`;
- source commit `20c3323d79d3896edc586d6db1df7deee60f9e41`;
- `DONE=1`, `BLOCK_ID=0xA40A0C07`, `PROTOCOL=0x0000400B`, `CAPABILITIES=0x00031002`;
- diagnostic magic `0x314B4C43`, runtime build flags `0x00000002`;
- identical init count/timing words, NVP status, clean autoinit/retry/timeout telemetry, and zero video errors.

Relative to the mean of clean C3 sequences 3/8, sequence 10 is only about `+61 ppm` in SAV rate and `+27 ppm` in VCLK rate, not `+3.98%`. No independent recorded abnormality beyond the frame numerator exists.

`C3_IDENTITY_DRIFT=NO`.

## Historical known-good cadence

Earlier evidence does not establish a physical distribution centered at `24.803727 Hz`:

- `t1-v40.1.0-rca-putty-contextual-exception-2026-08-20/08_COMPARISON/RCA_CURRENT_VS_HISTORICAL_AND_V41.csv`, commit `5a885fd39378eab6608d92c895dc3270910e2bd5`, SHA-256 `AAD7B3474D54B03DBD0451BA6D8103302C32A7F9A53603D3AA411CFFF67CFA3D`, contains 11 valid known-good observations, all with `FRAME_DELTA=25` over approximately one second, VCLK `148520870–148564336`, and SAV `28129–28137`;
- `v41-nvp-i2c-25khz-paired-ab-r1/05_HARDWARE_PRECHECK/RATE_CLASSIFICATION_POLICY.md`, commit `5a81f5b115dddcdddd809a655fced115e113585e`, SHA-256 `F6886A865E7753CA41C834ED74667EA2A479BA4E6258BCDC61FD6BF8E46A4690`, records that the historical RC-A contract used positive deltas rather than a normalized precision band;
- `v41-nvp-r1i-r2-qualified-poc-hardware-evidence/final/R1I_R2_MEASUREMENTS.md`, payload commit `c1c552fa4fc693d6c375db9478abecd7960ec3ce`, provenance correction `955ba0cd2462f4dec9dcb086175ab6eca57365bb`, SHA-256 `B20D129D33BA0C08538D679F8B104B360044026E159D67D0B24A527B69D0B869`, records `25 / 1.007913055 = 24.803726746 Hz`, but the same observation's `SAV/1125` was `24.999982722 Hz` and VCLK was `148.500601 MHz`;
- the exact R1h PoC control in that package (raw B1 SHA-256 `9B8D6FA58D4ACA6E8F7DCF71E46C5AC005D637980AC9F1C1E0828850D230B5F0`) had zero video and does not define a positive cadence;
- `v41-nvp-r1h-r4-super-fast-implementation-and-large-sample/final/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md`, evidence commit `aad5e9cb1ae88fdd3b6ac71de02a2fb08a2c79a2`, SHA-256 `3E0D487A1EBDDAB63CABD829E2868ADF26BDFF9FC23AFEBC20A13A397298D6D8`, reports no positive R1h/R1h-R4 video cadence;
- local pre-Git `V40_FINAL_NVP_VIDEO.md`, SHA-256 `B8E7AB051BB3C3E455328C57E08B3BAB71F5A375A69288068578ACE65E828E60`, records frame delta 25, SAV 28136, and VCLK 148557100. This last item is contextual local evidence, not repository-qualified evidence.

The frozen center was one low-quantized sample, not a high-resolution estimate of source frequency.

## Evidence supporting the conclusion

1. The two displayed populations are exactly integer numerators 25 and 26.
2. Their separation equals the one-count rate quantum.
3. The observed windows and a 25-Hz periodic model predict both bands without a physical change.
4. Raw monotonic data independently reproduces every printed value.
5. Source inspection proves the counted event, actual elapsed formula, coherent CDC, and absence of a software `+1`.
6. SAV/1125 and VCLK remain stable across branches.
7. C2/C3 cross both branches; recovery, order, programming session, and reset epoch do not explain the split.
8. Sequence 10 is exact C3 with no independent error signature.

## Evidence opposing or limiting the conclusion

- no external source-format log, direct VSYNC timestamp stream, or independent video analyzer was retained;
- no direct total-lines-per-frame series was captured, so a vertical-total change at near-constant pixel/line cadence is logically possible;
- no temperature, analog rail, or electrical timing measurements were recorded;
- four upper-branch outcomes in eight are mildly uncommon under independent uniform phase (`5.59%` tail), although deterministic startup phase need not be uniform;
- SAV and VCLK are related on-FPGA digital counters, not independent analog instruments.

These limitations justify `MEASUREMENT_ARTIFACT_PROBABLE` rather than `MEASUREMENT_ARTIFACT_CONFIRMED`. They do not supply positive evidence for a real timing or environment-dependent mode.

## Protocol and campaign impact

Historical state remains immutable:

- halt at sequence 10 preserved;
- `C3_NON_CLEAN_SUSPEND_BLOCK` preserved;
- ten run rows and historical classifications preserved;
- denominator remains 32; sequence 10 is not deleted, replaced, or repeated;
- runs 11–32 were not executed;
- no C3 cold starts or INIT_DONE timing were executed.

Disposition: `KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID`.

Campaign decision: `NEW_CONTROL_EXPERIMENT_REQUIRED`.

The proposed amendment is candidate-neutral and host-side only. For video-present runs it requires at least 20 seconds and 500 events, with a 30-second hard cap; video-absent runs take a finite two-second no-progress branch. It defines exact monotonic-bracket uncertainty, OLS/endpoint agreement, counter-integrity rules, and numeric frame/SAV/VCLK bands. It is marked `PROPOSED — NOT AUTHORIZED` and applies prospectively only.

The one-second historical observations cannot be made equivalent to missing 20-second measurements by approval or a retrospective overlay. Mixing the two regimes would confound measurement method with sequence/session and violate the frozen experiment. Therefore the old campaign remains halted at 10/32; sequences 11–32 must not be appended. After the corrected method is validated in a separately authorized measurement-control experiment, any causal campaign must restart from its own run 1 with a fresh denominator and one predeclared measurement rule.

## R3 status

`STILL_REQUIRED`.

The measurement review does not cancel the frozen recovery trigger: C2 sequences 6 and 9 recorded recovery activity. R3 was not started and remains separately authorized work.

## Final conclusion

The engineering review passes. The 24.8/25.8 numerical split is explained and integer quantization is confirmed. The best physical classification is `MEASUREMENT_ARTIFACT_PROBABLE`, confidence `HIGH`. Exact-C3 identity drift, recorded environment dependence, recovery correlation, and an independent sequence-10 abnormality are not supported.

Do not resume the halted R2 campaign. The next decision is Owner/Architect approval or rejection of the proposed prospective measurement amendment and a separately identified control/new-campaign design; R3 remains separate work.
