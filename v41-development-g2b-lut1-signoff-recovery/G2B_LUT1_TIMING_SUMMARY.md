# AHD v41 G2B-LUT1 Routed Timing Summary

## Gate status

- `ROUTED_TIMING = FAIL`
- `EXECUTION_STATUS = NOT_RUN_AFTER_REQUIRED_BUS_SKEW_TIMEOUT`
- `FIRST_BLOCKER = Group 13 RESET_RETURN_SOURCE_TO_AXI`
- `BLOCKER_CLASSIFICATION = REQUIRED_BUS_SKEW_TIMEOUT`
- `WATCHDOG_BUDGET_SECONDS = 300`
- `OBSERVED_RUNTIME_SECONDS = 301.094`

The required Group 13 `report_bus_skew` query exceeded its bounded external watchdog. The recovery sequence therefore stopped before the final routed timing qualification, as required by the pre-bitstream policy.

## Fresh timing values

| Metric | Current recovery value |
|---|---|
| WNS | `N/A` |
| TNS | `N/A` |
| WHS | `N/A` |
| THS | `N/A` |
| Recovery/removal | `N/A — NOT_RUN` |
| No-clock endpoints | `N/A — NOT_RUN` |
| Unconstrained internal endpoints | `N/A — NOT_RUN` |
| Timing loops | `N/A — NOT_RUN` |
| Latch loops | `N/A — NOT_RUN` |

No previous raw, pre-recovery, or sealed-checkpoint timing value is accepted as current final sign-off. No fresh value is inferred or substituted.

`BITSTREAM_PRODUCED = NO`  
`HARDWARE_ACCESSED = NO`
