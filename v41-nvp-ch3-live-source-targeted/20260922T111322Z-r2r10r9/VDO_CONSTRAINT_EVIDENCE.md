
# VDO constraint evidence

```text
XDC_PRESENT_IN_SOURCE=YES
XDC_LOADED_IN_EXACT_BUILD=YES
EFFECTIVE_VDO_COVERAGE=SOURCE_SCOPE_VDO1_DATA_7_0_RELATIVE_NVP_VCLK1_POST_ROUTE_OBJECT_COVERAGE_NOT_RETAINED
PHYSICAL_MARGIN_FOR_CURRENT_TVI=NOT_ESTABLISHED
NEW_TIMING_SIGNOFF=0
```

The exact R5 implementation input manifest listed
`xdc/boards/current/vdo_input_timing.xdc`, 2459 bytes, SHA-256
`6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78`,
git blob `3cb8a6dd2458c16113ee91a72bbc977b34f2f190`. The retained Vivado log
recorded this file being parsed both during project setup and implementation.

The file applies max `6.313 ns` and min `2.104 ns` input delays to
`vdo1_data[*]` relative to `nvp_vclk1` and excludes the unused falling-edge
capture path. The derivation is empirical and phase-dependent. This review did
not open a DCP, run timing, or establish a current TVI physical margin.
