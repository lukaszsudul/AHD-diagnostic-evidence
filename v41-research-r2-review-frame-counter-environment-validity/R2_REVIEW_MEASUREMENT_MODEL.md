# R2 Review — Measurement Model

## Primary result

- Result: `MEASUREMENT_ARTIFACT_PROBABLE`
- Confidence: `HIGH`
- Integer/event-window quantization: `CONFIRMED`
- Explicit software off-by-one: `REJECTED`
- Real timing change: `NOT ABSOLUTELY EXCLUDED`

## Estimator

The frozen estimator is:

```text
N = (frame_T1 - frame_T0) mod 2^32
T = midpoint_monotonic_T1 - midpoint_monotonic_T0
f_hat = N / T
```

`N` is an integer; start and end are not synchronized to frame-event boundaries. For a periodic event rate `f`, the event count over a half-open interval is one of the adjacent integers around `fT`, depending on phase. The rate quantum is `1/T`.

Observed `T` spans `1.007711409–1.008668054 s`, so one event is `0.991406–0.992348 Hz`, about ten times the frozen `0.10 Hz` half-band.

## Observed populations

Eight video-positive observations split exactly:

| Population | Numerator | n | Mean Hz | Median Hz | Range Hz |
|---|---:|---:|---:|---:|---:|
| A | 25 | 4 | 24.804673109 | 24.805408085 | 24.799186221–24.808690044 |
| B | 26 | 4 | 25.791185692 | 25.795165746 | 25.776567323–25.797843954 |

- mean difference: `0.986512583 Hz`;
- relative difference from Population A: `3.9771%`;
- one count at the mean of all ten observed frame windows: `0.992084751 Hz`, or `3.9683%` of 25 Hz (the video-positive-only mean gives `0.992077727 Hz`).

There are no fractional numerators or intermediate branches.

## Model A — literal frozen center as true frequency

The frozen center `24.803727 Hz` came from one historical observation:

```text
25 / 1.007913055 = 24.803726746 Hz
```

Treating `24.803727 Hz` as the exact underlying periodic event rate gives `fT = 24.994999…25.018727` across the observed windows. Some shorter windows could then contain only 24 or 25 events, not 26. In particular, a 26-event result is impossible when `fT < 25` for an ideal periodic source.

Therefore the frozen 24.803727 value is not a defensible physical-rate estimate. It is the low integer branch of its own short-window measurement.

This directly addresses the requested `true frame rate ≈24.8 Hz` hypothesis: a literal 24.803727-Hz periodic model does not fit all retained numerators, whereas an approximately 25-Hz model does.

## Model B — independently corroborated approximately 25-Hz cadence

For `f=25.000 Hz`:

```text
fT = 25.192785…25.216701 events
```

Random boundary phase yields exactly 25 or 26 counts. The predicted printed bands are:

```text
N=25: 24.785161…24.808690 Hz
N=26: 25.776567…25.801038 Hz
```

Both observed populations lie completely inside these bands.

The independent all-SAV counter supplies the physical basis for this model. It increments on every valid `H=0` SAV, including vertical blank. Under the independently qualified 1,125-total-line video mode, all eight video-positive observations give:

```text
SAV_rate / 1125 = 24.999682481…25.001494250 Hz
mean = 25.000153245 Hz
```

VCLK remains approximately `148.500 MHz`.

## Random-phase frequency

At `f=25 Hz`, the per-run probability of the 26-count branch is the fractional part of `fT`, here about `0.193–0.217`. Using each exact window, the Poisson-binomial probability of at least four upper-branch results in eight observations is `5.59%`.

Four highs are mildly unusual but not incompatible with quantization. Capture startup may also create structured rather than independent-uniform phases. The data set is too small to infer such structure.

Both C1 observations are high, but conditioned on four highs among eight, the one-sided probability that both C1 positions are high is `6/28 = 0.214`. This is not candidate evidence.

## Host jitter and elapsed-window effects

The denominator uses actual `time.monotonic()` counter-read midpoints, so sleep overshoot and scheduler delay are already measured. Observed window jitter changes the within-branch decimal values but cannot create the one-integer numerator step by itself.

- 25/26 indicator versus run sequence: Pearson `r≈-0.046`;
- numeric rate versus run sequence: Pearson `r≈-0.052`;
- recovery indicator versus numeric rate: point-biserial `r≈0.0047`;
- elapsed window versus numeric rate: `r≈0.386`, driven mainly by sequence 10, with A/B window ranges overlapping.

## Endpoint and inclusive-count tests

| Mechanism | Result |
|---|---|
| one extra event at a boundary | exactly reproduces the observed gap |
| first/last event inclusion | inherent in unknown sample phase and plausible |
| explicit inclusive `+1` in software | absent from source |
| counter read race | can choose old/new coherent value; same endpoint quantization, not tearing |
| reset during window | contradicted by raw monotonic counter evolution |
| integer quantization | confirmed |

## Competing physical-change model

A real approximately `3.98%` frame-rate change should generally produce comparable evidence in line or pixel cadence. Instead:

- mean SAV-rate difference between frame populations is about `25.9 ppm`;
- mean VCLK-rate difference is about `7.76 ppm`;
- sequence 10 differs from the clean-C3 mean by only about `61 ppm` SAV and `27 ppm` VCLK.

A vertical-total change with almost unchanged pixel and line cadence is logically possible because no external format analyzer or direct total-lines-per-frame trace was retained. This is why the primary result is `PROBABLE`, not `CONFIRMED`, despite the confirmed numerical quantization mechanism.

## Required duration

To make one-event resolution no greater than `0.10 Hz`, `T` must be at least 10 seconds. For video-present runs the amendment proposes at least 20 seconds and 500 frame events, with a 30-second hard cap; this gives a one-event quantum no greater than `0.05 Hz` at the normal cadence. A finite two-second no-progress branch handles video absence. Intermediate samples and SAV/VCLK cross-checks make the rule executable and bounded.

## Conclusion

The observed bimodality is completely explained by an integer-event estimator operating for about one second with boundaries not phase-locked to frame events. The estimator defect is proven; the physical artifact interpretation is highly probable but remains bounded by the absence of an independent external timing measurement.
