# G2B-NVP-OFFLINE-ADVANCE1-R1 continuation package

## Available governed continuation

`AHD_v41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1_PROMPT.md`

- Reuses protected COMPAT0-R2R1 bitstream SHA-256 `CFA58A46572094209997F6B1A3A5A033BF4E8C8A71EC261A5BBF1833B8BCF91B`.
- Performs no build.
- Resumes at `REMOTE_DUT_ROOT_BOOTSTRAP` only after DUT reachability returns.
- Ends after bounded CH1 format classification and exact rollback.

## Intentionally unavailable continuations

- RM1 HW1 prompt: `NONE`. Fresh synthesis passed, but the post-synthesis exact profile-elaboration gate failed. No routed DCP or bitstream exists.
- MODE1 HW1 prompt: `NONE`. Differential authority is incomplete: 27 of 63 minimum touched positions remain `PROHIBITED_UNRESOLVED`, recovery authority is 57.143%, and initial-EQ authority is incomplete. No MODE1 source candidate or build exists.

## Required execution order after DUT returns

1. Run COMPAT0-R2R1-CONT1.
2. If `AHD_1080P25_CONFIRMED`, run MODE1 HW1 only when a later governed offline task makes that prompt available.
3. When Tor A is resumed, run RM1 HW1 only when a later governed offline sign-off makes that prompt available.

This index does not authorize DUT access, MODE1, RM1, generic host I2C, DMA/AIO capture, rebuild, retry, PRODUCT mutation or SSOT/META mutation.
