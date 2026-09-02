# AHD v41 G2B-LUT1 Clock Summary

## Gate status

- `CLOCK_SIGNOFF = FAIL`
- `EXECUTION_STATUS = NOT_RUN_AFTER_REQUIRED_BUS_SKEW_TIMEOUT`
- `FIRST_BLOCKER = Group 13 RESET_RETURN_SOURCE_TO_AXI`
- `BLOCKER_CLASSIFICATION = REQUIRED_BUS_SKEW_TIMEOUT`
- `WATCHDOG_BUDGET_SECONDS = 300`
- `OBSERVED_RUNTIME_SECONDS = 301.094`

The required Group 13 `report_bus_skew` query exceeded its bounded external watchdog. The recovery sequence stopped before the fresh final clock review.

| Clock item | Current recovery value |
|---|---|
| XDMA configured user clock | `62.5 MHz` |
| Effective implemented user clock | `N/A — NOT_RUN` |
| Effective implemented AXI clock | `N/A — NOT_RUN` |
| Source clocks | `N/A — NOT_RUN` |
| Generated clocks | `N/A — NOT_RUN` |
| Unconstrained clocks | `N/A — NOT_RUN` |
| Clock interaction issues | `N/A — NOT_RUN` |
| Clock routing DRC | `N/A — NOT_RUN` |

The `62.5 MHz` value is the unchanged configured XDMA value, not a fresh effective routed-clock result. Previous reports are historical only and are not accepted as current final clock sign-off. No effective frequency is inferred.

`BITSTREAM_PRODUCED = NO`  
`HARDWARE_ACCESSED = NO`
