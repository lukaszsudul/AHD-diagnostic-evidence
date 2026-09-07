# G2B-HW0-PRODUCT-R3R4R6 Frozen Flag Prediction

Status: `FROZEN_BEFORE_DUT_CONNECTION`

## First record after RESET_STREAM_STATE

- `VALID = 1`
- `DISCONTINUITY = 0 or 1`
- `OVERFLOW_OCCURRED = 0`
- `MALFORMED_PRECEDING = 0`

A first-record `DISCONTINUITY` is permitted as a transition marker and does
not change record-integrity classification.

## Records after the first record

- `VALID = 1`
- `DISCONTINUITY = 0`
- `OVERFLOW_OCCURRED = 0`
- `MALFORMED_PRECEDING = 0`

## Complete-frame window

The eligible frame starts with `SOF = 1`, line 0, `VALID = 1`, and none of
`DISCONTINUITY`, `OVERFLOW_OCCURRED`, or `MALFORMED_PRECEDING`. Its next 1079
records must likewise be integral and free of those three diagnostic flags.

This prediction is frozen before hardware data and will not be revised after
capture.
