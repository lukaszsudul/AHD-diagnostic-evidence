
# AHD v41 CH3 R2R10R9 — targeted live-source review

## Result

- Retained SCAN1 generation 4 measured Bank0/0x7B as `0x11`. The CH3 nibble
  was `1`, the documented normal Y/C output mode. Rewriting `0x11` would have
  been a no-op.
- CH3 routing to VDO1 is partially confirmed: the loader performed and
  internally verified the Bank1/C2 low-nibble selection `2`, and the pinned
  source chain connects VDO1 through the physical frontend to G2B C2H. The
  host survey does not expose a full raw readback of C2/C8/CA/CD.
- The exact control that produced the retained static multicolor pattern was
  not identified. The documented background selector was already in normal
  mode, so it does not prove the working assumption that an NVP generator was
  active.
- No DUT contact, register write, new SCAN1, capture, patch, build or signoff
  was performed. The selected result is Branch C: preserve the evidence and do
  not guess a write.

## Constraint finding

The exact R5 source contained `vdo_input_timing.xdc`, the implementation input
manifest pinned its hash, and the retained Vivado log recorded that file being
parsed during implementation. It constrains `vdo1_data[*]` relative to
`nvp_vclk1` with max/min input delays. This review did not run timing or prove
the physical margin of the current TVI interface.

## Smallest next action

Under separate authorization, perform one bounded scene-dependency
observation using the same image/profile: sustain a controlled optical change
on CH3 and compare UYVY payloads from distinct complete frame keys before and
after. Correlated pixel changes would establish scene dependence for that
experiment. Identical pixels would not by themselves identify a generator or
prove an input-timing cause.

```text
OWNER_CAMERA_TEST=ATTESTED_LIVE_ON_OTHER_CAPTURE_SYSTEM
CURRENT_NVP_PATTERN_ORIGIN=UNRESOLVED_OWNER_WORKING_ASSUMPTION_NOT_REGISTER_PROOF
ACTUAL_BANK0_7B=0x11_RETAINED_SCAN1_GENERATION4
TARGET_CH3_ROUTE=PARTIAL_CONFIRMED_INTERNAL_VERIFY_PLUS_SOURCE_CHAIN_NO_FULL_HOST_READBACK
GENERATOR_CONTROL_IDENTIFIED=NO
GENERATOR_DISABLE_EXECUTED=NO
GENERATOR_DISABLE_READBACK=NOT_RUN
NEW_CH3_SYNC=NOT_MEASURED
LIVE_CAMERA_SCENE=NOT_RETESTED_NO_NEW_CAPTURE
SOURCE_PATCH=NONE
PRODUCT_QUALIFICATION=NOT_CLAIMED
```
