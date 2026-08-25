# R1h-R4 frozen statistical analysis

## Result

The frozen R1h analysis completed successfully against the three exact valid Arm-A receipts and the three exact FormalReady Arm-B receipts. The exact inherited statistical implementation was used without method changes:

```text
FROZEN_STATISTICS_SHA256=
    C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD

TARGET_OPPORTUNITY_AUDIT=
    PASS_90000_OF_90000
```

Across all nine 10,000-opportunity post-init target-phase panels, the result was 90,000 ACK, zero NACK, and zero timeout. The pooled Wilson 95% interval for the post-init target NACK rate is `[0, 0.0000426810540]`; for each phase pooled across the three repetitions (`N=30,000`) it is `[0, 0.0001280322330]`.

This establishes a zero observed post-init target-NACK rate in the planned sample. It does not establish that the underlying rate is exactly zero. Because every individual panel had fewer than five events, the frozen temporal stationarity/independence classification is `INSUFFICIENT_EVENTS`, not a claim of a stationary memoryless process.

## Arm-A post-init panels

All nine panels have the same exact result:

| Run | Phase | N | ACK | NACK | Timeout | Rate | ppm | Wilson 95% | First/last index | Adjacent pairs | Binary runs | Max NACK run | Ten block NACK counts |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---|
| A1 | WADDR | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A1 | REGADDR | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A1 | DATA | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A2 | WADDR | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A2 | REGADDR | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A2 | DATA | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A3 | WADDR | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A3 | REGADDR | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |
| A3 | DATA | 10000 | 10000 | 0 | 0 | 0 | 0 | [0, 0.000383998371] | none/none | 0 | 1 | 0 | 0,0,0,0,0,0,0,0,0,0 |

For the frozen global family of 27 block/runs/adjacency tests, every raw and Holm-adjusted p-value is `1.0`; those p-values are the predeclared neutral values for uninformative zero-event panels.

## Arm-A autoinit phase results

| Run | Phase | Opportunities | ACK | NACK | Rate | Wilson 95% |
|---|---|---:|---:|---:|---:|---:|
| A1 | WADDR | 273 | 270 | 3 | 0.0109890110 | [0.0037441604, 0.0318049183] |
| A1 | REGADDR | 273 | 268 | 5 | 0.0183150183 | [0.0078478203, 0.0421499614] |
| A1 | DATA | 219 | 212 | 7 | 0.0319634703 | [0.0155677159, 0.0644957468] |
| A1 | RADDR | 54 | 54 | 0 | 0 | [0, 0.0664135881] |
| A2 | WADDR | 275 | 274 | 1 | 0.0036363636 | [0.0006421961, 0.0203068365] |
| A2 | REGADDR | 275 | 271 | 4 | 0.0145454545 | [0.0056705983, 0.0367960380] |
| A2 | DATA | 220 | 218 | 2 | 0.0090909091 | [0.0024966057, 0.0325347011] |
| A2 | RADDR | 55 | 54 | 1 | 0.0181818182 | [0.0032167805, 0.0960577606] |
| A3 | WADDR | 276 | 273 | 3 | 0.0108695652 | [0.0037033885, 0.0314645915] |
| A3 | REGADDR | 276 | 273 | 3 | 0.0108695652 | [0.0037033885, 0.0314645915] |
| A3 | DATA | 220 | 216 | 4 | 0.0181818182 | [0.0070927016, 0.0458083958] |
| A3 | RADDR | 56 | 56 | 0 | 0 | [0, 0.0641939367] |

Pooled descriptive autoinit totals were WADDR `7/824`, REGADDR `12/824`, DATA `13/659`, and RADDR `1/165`. The exact four-phase heterogeneity tests produced raw p-values A1 `0.3301522572`, A2 `0.3637048314`, and A3 `0.8634576758`; their Holm-adjusted values are all `0.9904567715`. Therefore:

```text
AUTOINIT_PHASE_RATE_HETEROGENEITY=
    NOT_DETECTED_NOT_EQUALITY_PROOF
```

## Autoinit versus post-init context

All rate-ratio point estimates are `+INF` because each post-init comparison count is zero. The finite profile-likelihood lower bounds, exact one-sided Fisher p-values, and within-run Holm adjustments are:

| Run | Phase | Autoinit / post-init | Rate difference (95% MN score CI) | RR lower 95% | Fisher p | Holm p | Run support |
|---|---|---|---|---:|---:|---:|---|
| A1 | WADDR | 3/273 vs 0/10000 | 0.0109890 [0.00374398, 0.03180640] | 40.9482 | 1.85667e-5 | 1.85667e-5 | yes |
| A1 | REGADDR | 5/273 vs 0/10000 | 0.0183150 [0.00784751, 0.04215155] | 78.4449 | 1.27865e-8 | 2.55731e-8 | yes |
| A1 | DATA | 7/219 vs 0/10000 | 0.0319635 [0.01556719, 0.06449783] | 145.1951 | 1.88834e-12 | 5.66501e-12 | yes |
| A2 | WADDR | 1/275 vs 0/10000 | 0.00363636 [0.00064215, 0.02030819] | 6.25165 | 0.0267640 | 0.0267640 | no |
| A2 | REGADDR | 4/275 vs 0/10000 | 0.0145455 [0.00567036, 0.03679756] | 59.1653 | 5.02274e-7 | 1.50682e-6 | yes |
| A2 | DATA | 2/220 vs 0/10000 | 0.00909091 [0.00249647, 0.03253646] | 28.2674 | 0.000461326 | 0.000922651 | yes |
| A3 | WADDR | 3/276 vs 0/10000 | 0.0108696 [0.00370321, 0.03146606] | 40.5020 | 1.91711e-5 | 3.83422e-5 | yes |
| A3 | REGADDR | 3/276 vs 0/10000 | 0.0108696 [0.00370321, 0.03146606] | 40.5020 | 1.91711e-5 | 3.83422e-5 | yes |
| A3 | DATA | 4/220 vs 0/10000 | 0.0181818 [0.00709240, 0.04581029] | 74.0083 | 2.09042e-7 | 6.27127e-7 | yes |

The frozen support rule is met by WADDR in A1 and A3, and by REGADDR and DATA in all three runs. Therefore all three context-rate-elevation classifications are `SUPPORTED`.

## Replicates, failed transactions, and paired controls

The three Arm-A runs had aggregate autoinit NACK counts `15, 8, 10`, failed-transaction totals `7, 5, 5`, and transaction starts `273, 275, 276`. All 17 failed records were stored, no failed-log overflow occurred, and every bank-invariant error count was zero.

The failed-transaction rate homogeneity p-value was `0.7869873089`; autoinit-rate family Holm p-values were all at least `0.7901526042`; probe-rate p-values were all `1.0`. Among failed-record compositions, the smallest raw p-value was `0.0294117647` for high-level phase, but its six-test Holm-adjusted p-value was `0.1764705882`. No estimable replicate-family hypothesis rejected at 0.05. The planned exact TABLE_SLOT composition test exceeded the frozen deterministic 250,000-table cap, so the strict aggregate classification is:

```text
R1H_REPLICATE_HOMOGENEITY=
    INSUFFICIENT_VALID_DATA
```

This label reflects one unestimable planned composition test; it is not evidence against homogeneity.

INIT_TARGET_WRITE was the modal failed-transaction kind in A1 (`6/7`) and A3 (`4/5`), but not A2 (`2/5`). Without category opportunity denominators, the frozen descriptive classification is:

```text
FAILED_TRANSACTION_DISTRIBUTION=
    REPEATABLE_FAILURE_COMPOSITION_CONCENTRATION_DENOMINATORS_LIMIT_RATE_CLAIM
```

The full formal controls each observed 12 aggregate NACKs with equal completed formal exposure. Their exact equal-multinomial p-value is `1.0`. Paired Arm-A minus Arm-B aggregate differences were `+3, -4, -2`, yielding a majority direction in two of three pairs (one-sided sign p `0.5`, two-sided `1.0`):

```text
PAIRED_AB_RESULT=
    DIRECTION_MAJORITY_2_OF_3
```

All three Arm-A samples and all three formal controls were valid scientific NVP FAIL observations. The paired direction is descriptive and not statistically compelling.

## Required classifications

```text
POSTINIT_WADDR_PROCESS=
    INSUFFICIENT_EVENTS

POSTINIT_REGADDR_PROCESS=
    INSUFFICIENT_EVENTS

POSTINIT_DATA_PROCESS=
    INSUFFICIENT_EVENTS

AUTOINIT_PHASE_RATE_HETEROGENEITY=
    NOT_DETECTED_NOT_EQUALITY_PROOF

AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
    SUPPORTED

AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
    SUPPORTED

AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
    SUPPORTED

R1H_REPLICATE_HOMOGENEITY=
    INSUFFICIENT_VALID_DATA

BANK_TRACKER_COHERENCE=
    PASS_ZERO_INVARIANT_ERRORS

FAILED_TRANSACTION_DISTRIBUTION=
    REPEATABLE_FAILURE_COMPOSITION_CONCENTRATION_DENOMINATORS_LIMIT_RATE_CLAIM

PAIRED_AB_RESULT=
    DIRECTION_MAJORITY_2_OF_3

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO
```

Machine-readable exact values, every input evidence hash, and all output hashes are in `R1H_R4_FROZEN_ANALYSIS.json` and `R1H_R4_INDEPENDENT_ANALYSIS_RECEIPT.txt`.
