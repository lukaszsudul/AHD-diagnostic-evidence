# AHD v41 G2B-LUT1 Sign-Off Recovery 3

Engineering execution stopped at the required Group-15 watchdog boundary.

## Authority and source

- PROJECT_STATE_REV at start/end: `6`
- META-6: verified at evidence commit `0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde`
- G14-A candidate: verified at `9e91315968453e859006077191cd5fc711fc6b96`
- Source: `integration/v41-g2b-onech-c2h`, parent `64feb60de5d07f400e6b92527bfe54838b3372ee`, commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree `e18833d46f7672f851c3cb8239f2f29091378294`
- Recovery mode: `ROUTED_DCP_REUSE`; full rebuild: `NO`
- Routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`

## Preserved and fresh results

Groups 9, 10-12, and 13 are preserved authoritative PASS results. The new Group-14 replacement sign-off passed all promoted families: normal transition `5.467/6.000 ns`, mismatch containment `5.554/6.000 ns`, and reset-overlap accounting `4.191/6.000 ns`. The retired global Group-14 bus-skew report was not executed.

## Continuation blocker

Group 15 (`RELEASE_SLOT_1_AXI_TO_SOURCE`) started its required `report_bus_skew` query at `2026-09-03T21:38:51.204Z`. The external watchdog terminated the query at `300.679 s`, with no completion marker. The exact blocker is:

`REQUIRED_BUS_SKEW_TIMEOUT:GROUP_15:RELEASE_SLOT_1_AXI_TO_SOURCE`

Groups 16 and 17 were not run. Per policy, final timing, DRC, CDC, clock, PRODUCT resource, hard-gate PASS, and bitstream stages were not reached. Hardware accessed: `NO`.

