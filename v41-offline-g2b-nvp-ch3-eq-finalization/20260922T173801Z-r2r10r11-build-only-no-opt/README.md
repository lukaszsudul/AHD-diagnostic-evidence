# AHD v41 CH3 R2R10R11 — scoped EQ finalization build-only result

A source-only experimental EQ finalization for the pinned CH3 TVI1080p25 path was committed from `FPGA_AHD@bc20bfbde7b5eb9a6d9deec5796651ffa4be0886` to `d0f28b35c44d66bfd46c2b02388cdf03923e0c0a` (tree `082c6dbc7c2367ac872ca8bc71039926227360ac`). The change covers only deterministic finalization actions, bounded delays, readbacks, recovery of fields owned by the change, and the existing detector window after those actions. Full vendor adaptive EQ was not ported.

The only authorized Vivado candidate completed synthesis with 0 errors and 0 critical warnings. The exact post-synthesis result was 21,920 / 20,800 Slice LUT (105.38%). The Owner-defined physical capacity gate therefore stopped the run before placement. Placement, routing and bit generation were not invoked. No routed DCP or bitstream exists.

No simulation, regression, lint, formal analysis, extra timing/DRC/CDC/bus-skew/methodology report or hardware action was performed. The change remains behaviorally untested. It does not prove a live scene, a pattern root cause, timing closure or the cause of the historical REGADDR_NACK.

`BUILD_RESULT=BLOCKED_RESOURCE_PHYSICAL_LUT_STOP`

`FIRST_BLOCKER=POST_SYNTH_SLICE_LUT_USED_GREATER_THAN_OR_EQUAL_TO_AVAILABLE`