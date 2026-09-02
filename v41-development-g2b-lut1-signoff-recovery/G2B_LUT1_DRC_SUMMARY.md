# AHD v41 G2B-LUT1 DRC Summary

## Gate status

- `DRC = FAIL`
- `EXECUTION_STATUS = NOT_RUN_AFTER_REQUIRED_BUS_SKEW_TIMEOUT`
- `FIRST_BLOCKER = Group 13 RESET_RETURN_SOURCE_TO_AXI`
- `BLOCKER_CLASSIFICATION = REQUIRED_BUS_SKEW_TIMEOUT`
- `WATCHDOG_BUDGET_SECONDS = 300`
- `OBSERVED_RUNTIME_SECONDS = 301.094`

The required Group 13 `report_bus_skew` query exceeded its bounded external watchdog. Execution stopped before the fresh final DRC gate.

| Required current result | Value |
|---|---|
| Errors | `N/A — NOT_RUN` |
| Critical warnings | `N/A — NOT_RUN` |
| Warnings inventory | `N/A — NOT_RUN` |
| Warning disposition | `N/A — NOT_RUN` |

Prior DRC reports are historical only and are not accepted as the current recovery DRC result. The absence of a fresh report is conservatively recorded as gate `FAIL`; no zero-count result is invented.

`BITSTREAM_PRODUCED = NO`  
`HARDWARE_ACCESSED = NO`
