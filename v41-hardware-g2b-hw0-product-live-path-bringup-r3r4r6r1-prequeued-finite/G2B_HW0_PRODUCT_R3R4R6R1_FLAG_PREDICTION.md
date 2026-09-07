# R3R4R6R1 Frozen Flag Prediction

This prediction was frozen before driver load and before any new capture data
was observed.

## First record after RESET_STREAM_STATE

- `VALID = 1`
- `DISCONTINUITY = 0 or 1`
- `OVERFLOW_OCCURRED = 0`
- `MALFORMED_PRECEDING = 0`

A first-record `DISCONTINUITY` is permitted as transition metadata and does not
make that record structurally corrupt.

## Records after the first record

- `VALID = 1`
- `DISCONTINUITY = 0`
- `OVERFLOW_OCCURRED = 0`
- `MALFORMED_PRECEDING = 0`

## Qualified complete frame

The selected frame must start with `SOF = 1`, source line zero, `VALID = 1`,
and no `DISCONTINUITY`, `OVERFLOW_OCCURRED`, or `MALFORMED_PRECEDING`. Its next
1079 records must also contain none of those three event flags.

This prediction is immutable for the remainder of the governed run.
