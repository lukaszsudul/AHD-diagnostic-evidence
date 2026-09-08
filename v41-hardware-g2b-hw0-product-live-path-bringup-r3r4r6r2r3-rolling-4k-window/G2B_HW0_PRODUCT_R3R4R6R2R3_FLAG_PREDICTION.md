# R3R4R6R2R3 frozen flag prediction

Frozen before stream enable and before any new capture data was observed.

## First primary record

- `VALID = 1`
- `DISCONTINUITY = 0 or 1`
- `OVERFLOW_OCCURRED = 0`
- `MALFORMED_PRECEDING = 0`

A first-record `DISCONTINUITY` is permitted startup metadata and does not fail
structural record integrity.

## Later primary records

- `VALID = 1`
- `OVERFLOW_OCCURRED = 0`
- `MALFORMED_PRECEDING = 0`
- `DISCONTINUITY = 0` after any initial transitional record

## Qualified frame

The selected frame must begin with `SOF = 1`, line `0`, `VALID = 1`, and no
`DISCONTINUITY`, `OVERFLOW_OCCURRED`, or `MALFORMED_PRECEDING`. All lines
`0..1079` must remain clean.

This prediction is immutable for the R3R4R6R2R3 hardware session.
