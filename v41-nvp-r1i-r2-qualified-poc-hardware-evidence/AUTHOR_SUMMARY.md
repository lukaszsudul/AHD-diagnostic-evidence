# Author Summary: Qualified R1i PoC

## Problem

The R1h control could observe NACKs during NVP autoinitialization, latch `INIT_ERROR`, and fail to produce video. The legacy I²C state machine released SCL and sampled SDA on the same sequential transition and continued later byte phases after a NACK.

## R1i objective and source delta

R1i tested a combined, bounded correction:

- ACK and slave-data sampling only after filtered physical SCL high;
- legal STOP at the first qualified NACK;
- up to three retries (four total attempts) with 100 µs, 500 µs, and 2,000 µs backoff;
- preserved bank/cache safety;
- separate raw, recovered, unrecovered, retry, early-sample, and qualified-sample telemetry;
- a new read-only MMIO page at `0x3600..0x367f`, leaving the R1h map through `0x35ff` unchanged.

The exact reviewable delta is [R1H_TO_R1I_SOURCE.patch](final/R1H_TO_R1I_SOURCE.patch). The candidate is fully committed at `20c3323d79d3896edc586d6db1df7deee60f9e41`; its exact R1h base is `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`.

## Frozen test

A1 was the fixed R1i candidate. B1 was the exact unmodified R1h control. Each arm collected 10,000 post-init WADDR, REGADDR, and DATA opportunities, followed by restoration of the exact approved Formal Phase-2 image.

## Measurements

| Metric | A1 fixed R1i | B1 exact R1h |
| --- | ---: | ---: |
| Autoinit WADDR | 0 / 275 | 0 / 275 |
| Autoinit REGADDR | 0 / 275 | 2 / 275 |
| Autoinit DATA | 0 / 220 | 2 / 220 |
| Autoinit NACK total | 0 | 4 |
| Post-init WADDR | 0 / 10,000 | 0 / 10,000 |
| Post-init REGADDR | 0 / 10,000 | 0 / 10,000 |
| Post-init DATA | 0 / 10,000 | 0 / 10,000 |
| `INIT_ERROR` | Not latched | Latched |
| Video | Present | Absent |
| Reported frame rate | 24.803727 Hz | 0 Hz |

## Conclusion

R1i was functionally confirmed under the frozen PoC hardware test: it initialized successfully and produced video, while the exact R1h control latched `INIT_ERROR` and produced no video. The frozen outcome is `STRONG_PASS`, and the publication scope is `QUALIFIED POC BASELINE`.

The experiment did not conclusively isolate whether the decisive mechanism was ACK sampling, device readiness, initialization timing, or a combined effect. R1i's causal early-false, qualified-NACK, and recovery counters were all zero in this run. Formal verification, production qualification, multi-board testing, and environmental/reliability campaigns remain outside this result.

## Identities

- R1i bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- Original internal evidence ZIP SHA-256: `6341F934D17F790E113C1C3013D9DD78E7387C6AA22469ABA7EB88D10C90519F`
- Candidate commit/tree: `20c3323d79d3896edc586d6db1df7deee60f9e41` / `70d801fd7a879080da399bfa9ee95fd6eb008e16`

## Suggested review questions

1. Does the qualified-high sampling sequence match the intended I²C timing model?
2. Is the first-NACK STOP/retry policy appropriate for every NVP table operation?
3. Should a later campaign isolate sampling timing from retry/readiness as separate candidates?
4. What additional boards, temperatures, voltages, and cold-start populations are required before production acceptance?

Start with the [measurements](final/R1I_R2_MEASUREMENTS.md), [source changeset](final/R1H_TO_R1I_CHANGESET.md), [raw data](raw/AHD_v41_R1i_R2_RAW.csv), and [limitations](final/R1I_R2_KNOWN_LIMITATIONS.md).
