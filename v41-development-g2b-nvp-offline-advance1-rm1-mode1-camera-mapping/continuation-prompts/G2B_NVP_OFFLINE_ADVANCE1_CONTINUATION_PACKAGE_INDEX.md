# G2B-NVP-OFFLINE-ADVANCE1 continuation package index

## Available prompt

- `AHD_v41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1_PROMPT.md`
  - starts from the existing signed-off COMPAT0-R2R1 DCP/bitstream identities;
  - performs the bounded reconnect/deployment and two-register campaign;
  - preserves rollback and first-failed-gate hard stops.

## Intentionally absent prompts

- RM1 HW1: `NONE` — the single full build failed before synthesis; no signed-off
  DCP or bitstream exists.
- MODE1 HW1: `NONE` — initial-EQ and deterministic recovery authority are
  incomplete; no MODE1 candidate, build, DCP or bitstream exists.

This index does not authorize DUT access by itself. Any continuation is governed
by the corresponding prompt and its own prerequisite checks.

