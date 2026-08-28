# R2 Review — Exact C3 Direct Comparison

## Question

Did halted run `R2OM-R03-P2-C3` show any exact-C3 abnormality independent of its one-second frame-counter estimate?

## Identity control

All three executed C3 runs match:

- role: exact qualified R1i;
- bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`;
- runtime source commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`;
- `BLOCK_ID=0xA40A0C07`;
- `PROTOCOL=0x0000400B`;
- `CAPABILITIES=0x00031002`;
- diagnostic magic `0x314B4C43`;
- runtime build flags `0x00000002`.

There is no C3 identity mismatch or rebuild confound.

| Receipt binding | Seq. 3 | Seq. 8 | Seq. 10 |
|---|---|---|---|
| Programming | `DB26B4402BC12322E4FC8C7DF0F391DB8FFEC9AB276E3162F8BAE2738EF74E81` | `4B1A4859EDEDB60C9F520CD9CBE2E55B62BD994251777DC3D498E90710CFCD5E` | `6C10A76AFF0E75CFE62CDF0C27EFBCB1E844B0F2107C9A1EDB010309B6BA9D2D` |
| Independent DONE | `935C6716ECBF64AA712E7CA9CD75DABE8BF957F66970660AAB0111D0E1BC8028` | `947D9AF093D260A6F81E0AFC30B04889A1F5388C551749E1983CE1FB51504A2B` | `F96CDCFA2DE2427741EE1DC13E4794A7EED4BF2535F329EE343442F9BBF19ACE` |
| Host transition | `6EFD6F645BDF8177A55BB56063A526A8717280CB09B425FDCD25322A4CACAD86` | `677984BCF8F3B416302B17832439FBBF096631E5E3B147667CA36AFE90014763` | `EB575AE188A6B6BA0163E6AFD856AD6FD01A2EE6DC22D61470EFF69F1468EAC0` |
| Candidate capture | `AF8CC44448E89C65889FF017C409F6C7A7246D3DEF7FF6D47D44E3BDEF6C814B` | `51E1B316D87C0F8C5F38387F261D9D0CFB955807EB0046AB55F53D4AE258373C` | `C911525528E125CE382024BA0D56B845564C94ADD1CE61FF009C5B308910E010` |

## Direct telemetry table

| Field | Seq. 3 | Seq. 8 | Seq. 10 halt |
|---|---:|---:|---:|
| Run | `R2OM-R01-P3-C3` | `R2OM-R02-P4-C3` | `R2OM-R03-P2-C3` |
| Historical class | CLEAN_PASS | CLEAN_PASS | INCONCLUSIVE |
| INIT_DONE | 1 | 1 | 1 |
| INIT_ERROR | 0 | 0 | 0 |
| Counter at INIT_DONE | 133683129 | 133683129 | 133683129 |
| Probe-start counter | 133745628 | 133745628 | 133745628 |
| Total autoinit NACK | 0 | 0 | 0 |
| Retry count | 0 | 0 | 0 |
| Recovered transactions | 0 | 0 | 0 |
| Retry exhausted | 0 | 0 | 0 |
| SCL timeout | 0 | 0 | 0 |
| SCL HIGH wait max, base cycles | 8 | 8 | 8 |
| NVP status word | `0xF9` | `0xF9` | `0xF9` |
| Captured video error counters | all zero | all zero | all zero |
| Video present | YES | YES | YES |
| Frame events | 25 | 25 | 26 |
| Actual raw midpoint window, s | 1.008097595500 | 1.007872322500 | 1.008668054000 |
| Published frame Hz | 24.799186 | 24.804729 | 25.776567 |
| all-SAV (`H=0`) events | 28,353 | 28,347 | 28,371 |
| Normalized all-SAV/s | 28,124.804603 | 28,125.121102 | 28,126.681031 |
| all-SAV/1125, Hz | 24.999826313 | 25.000107647 | 25.001494250 |
| VCLK events | 149,705,020 | 149,671,557 | 149,794,060 |
| Normalized VCLK/s | 148,500,299.809 | 148,500,212.495 | 148,504,303.098 |

The complete autoinit and safety vector is identical. The only classification-driving difference is the integer frame-event branch.

The `/1125` normalization is conditional on the independently qualified 1,125-total-line video mode; the all-SAV counter itself does not infer that mode.

## Auxiliary-rate comparison

Relative to the mean of clean C3 sequences 3/8, sequence 10 differs by only:

- SAV rate: approximately `+61 ppm`;
- VCLK rate: approximately `+27 ppm`.

The published frame estimates differ by approximately `3.94%` between branches.

The auxiliary channels do not corroborate a physical frame-rate shift of the magnitude implied by `25.776567 / 24.804729`.

## Run-context comparison

| Seq. | Capture UTC | Boot ID | Preceding scheduled cell |
|---:|---|---|---|
| 3 | `2026-08-28T13:56:14.271902637Z` | `c75e10c6-ceef-4fea-8aa0-c1bbdf839bed` | C1 |
| 8 | `2026-08-28T16:42:19.052471958Z` | `e973858e-0bc9-4822-a857-343cd930f9a2` | C0 |
| 10 | `2026-08-28T18:07:49.947408945Z` | `471fed49-f2ef-4693-8105-b61814d6e100` | C2 |

Each run used a distinct task-owned warm reboot epoch, as planned. The 25-event branch occurs after different predecessors; the 26-event branch also occurs in C1 and C2 elsewhere. No unique C3 predecessor or boot pattern is identified.

## Opposition and limitations

- Run 10's SAV/VCLK normalized rates are slightly above the two earlier C3 values. The deviations are small, but the review does not claim they are exactly equal.
- No analog SCL/SDA, pixel clock, VSYNC, rail, temperature, or HDMI-sink trace is available.
- Three C3 observations are too few to estimate rare hardware fault probability.
- No external event-phase timestamp stream exists, although exact host read-midpoint timestamps survive in the cryptographically bound raw captures.

These limitations permit small physical jitter, but they do not support an independent C3 fault at run 10.

## C3 verdict

- Exact C3 identity: `CONFIRMED_EXACT_R1I`
- `C3_IDENTITY_DRIFT`: `NO`
- Independent autoinit abnormality: `NONE OBSERVED`
- Independent video-mode abnormality: `NONE OBSERVED`
- Frame estimator artifact: `PROBABLE`, confidence `HIGH`
- Integer-event quantization: `CONFIRMED`
- Real timing change: `NOT ABSOLUTELY EXCLUDED`
- C3 replay required solely for this frame anomaly: `NOT SUPPORTED`
- Historical run-10 label: `PRESERVE; NO RETROSPECTIVE RECLASSIFICATION`
