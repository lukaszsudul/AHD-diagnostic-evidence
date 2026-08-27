# R1i–R2 Measurements

## Functional comparison

| Measurement | A1 fixed R1i | B1 exact R1h control |
| --- | ---: | ---: |
| Programming | PASS | PASS |
| Runtime identity | PASS | PASS |
| `INIT_DONE` | 1 | 1 |
| `INIT_ERROR` | No | Yes |
| Video | Present | Absent |
| Reported frame rate | 24.803727 Hz | 0 Hz |
| SAV rate | 28,124.980562/s | 0/s |
| Autoinit NACK total | 0 | 4 |
| Post-init NACK total | 0 | 0 |

The 24.803727 Hz value is explicitly the decoded `FRAME_RATE`: 25 frame-count increments over 1.007913055 seconds. It is 24.804 Hz when rounded to three decimals. The source evidence separately reports a video clock near 148.5 MHz; the frame-rate value must not be relabeled as a pixel clock.

## Autoinit phase measurements

| Phase | A1 NACK / opportunities | A1 rate | B1 NACK / opportunities | B1 rate |
| --- | ---: | ---: | ---: | ---: |
| WADDR | 0 / 275 | 0% | 0 / 275 | 0% |
| REGADDR | 0 / 275 | 0% | 2 / 275 | 0.72727273% |
| DATA | 0 / 220 | 0% | 2 / 220 | 0.90909091% |
| Total | 0 / 770 | 0% | 4 / 770 | 0.51948052% |

## Post-init selected-target measurements

| Phase | A1 NACK / opportunities | A1 rate | B1 NACK / opportunities | B1 rate | Campaign observations |
| --- | ---: | ---: | ---: | ---: | ---: |
| WADDR | 0 / 10,000 | 0% | 0 / 10,000 | 0% | 20,000 / 20,000 |
| REGADDR | 0 / 10,000 | 0% | 0 / 10,000 | 0% | 20,000 / 20,000 |
| DATA | 0 / 10,000 | 0% | 0 / 10,000 | 0% | 20,000 / 20,000 |
| Total | 0 / 30,000 | 0% | 0 / 30,000 | 0% | 60,000 / 60,000 |

## Integrity and safety

| Gate | A1 | B1 |
| --- | ---: | ---: |
| Counter overflow | No | No |
| BRAM/failed-log overflow | No | No |
| Probe timeout | 0 | 0 |
| Bank-invariant errors | 0 | 0 |
| Runtime identity verified | Yes | Yes |
| Valid sample | Yes | Yes |

Exact machine-readable values are in [the raw CSV](../raw/AHD_v41_R1i_R2_RAW.csv), [the statistical CSV](../raw/AHD_v41_R1i_R2_STATISTICAL_ANALYSIS.csv), and the A1/B1 telemetry JSON directories.
