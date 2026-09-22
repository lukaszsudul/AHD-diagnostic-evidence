# AHD v41 R2R10R12R1 — PREPARE PC14 offline review

## Result

- Historical R12 remains `FAIL_PREPARE_I2C_RADDR_NACK`.
- The coherent first-failure record localizes the digital event to PREPARE PC14, Bank9/0x6C, READ, raw cause 3 (`I2C_RADDR_NACK`), terminal 19, without timeout or valid read data.
- No reachable code defect was demonstrated in the targeted loader, ownership wrapper, or fixed-master path.
- The physical cause remains unproven because no SCL/SDA waveform was retained.
- EQ, APPLY, SCAN1, and C2H were not executed in R12.

`DIAGNOSIS=ROOT_CAUSE_UNPROVEN_SMALLEST_OBSERVATION_DEFINED`

## Repeatability

| Cohort | Independent PREPARE trials | PC14 reached | Passes | PC14 RADDR_NACK | Other | Unknown |
|---|---:|---:|---:|---:|---:|---:|
| Exact R11R1 bitstream | 1 | 1 | 0 | 1 | 0 | 0 |
| Older bitstreams with source-equivalent PREPARE PC0–46 | 3 | 3 | 3 | 0 | 0 | 0 |

Exact-image classification: `NOT_ESTABLISHED_SINGLE_CONFIRMED_FAILURE`.

PC14 is the localized failure site. Repeatability on the current bitstream was not demonstrated. The older passes establish that the same source-level operation can complete, but they do not reproduce the R11R1 physical implementation.

The PREPARE instruction slice PC0–46 has SHA-256 `E7ACBB6123B7150234AC33119FD2344EC58F81673B28ABFC82FF5ED56A7E7189` in source commits d0f28b35, bc20bfbd, e804b5a8, and b2f80cf4. The fixed master, wrapper, and top are exact Git-blob matches across those commits.

The historical terminal 18 event is excluded: it was an APPLY `REGADDR_NACK`, and its PC/bank/register were not retained.

## Continuation boundary

The RTL can conditionally accept another PREPARE from DONE/`CAMP_VIRGIN`, but the first-failure record is reset-only. A direct retry would retain the old PC14 record and could not localize a new failure; it also would not satisfy the empty-record admission required before APPLY.

The one recommended future action, under separate authorization, is an exact R11R1 image reactivation followed by one PREPARE with a preverified SCL/SDA observation at the NVP pins, correlated to the ACK bit after read address 0x61 of the accepted PC14 transaction. Analyzer availability and probe access are not established.

## Scope

This task used retained files and commit-pinned source only. DUT contact, driver operations, PREPARE/APPLY, reset, capture, source changes, simulation, Vivado, build, and sign-off were all zero.

Source: `FPGA_AHD@d0f28b35c44d66bfd46c2b02388cdf03923e0c0a`
R12 evidence: `AHD-diagnostic-evidence@a6171fa3041c334ef0b9e8458a637ac8f1092849`
