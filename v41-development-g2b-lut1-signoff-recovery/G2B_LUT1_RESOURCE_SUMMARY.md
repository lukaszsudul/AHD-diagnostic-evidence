# AHD v41 G2B-LUT1 PRODUCT Resource Summary

## Gate status

- `PRODUCT_RESOURCE_SIGNOFF = FAIL`
- `PRODUCT_LUT_LE_90_PERCENT = FAIL_NOT_ESTABLISHED`
- `EXECUTION_STATUS = NOT_RUN_AFTER_REQUIRED_BUS_SKEW_TIMEOUT`
- `FIRST_BLOCKER = Group 13 RESET_RETURN_SOURCE_TO_AXI`
- `BLOCKER_CLASSIFICATION = REQUIRED_BUS_SKEW_TIMEOUT`
- `WATCHDOG_BUDGET_SECONDS = 300`
- `OBSERVED_RUNTIME_SECONDS = 301.094`

The required Group 13 `report_bus_skew` query exceeded its bounded external watchdog. The recovery sequence stopped before a fresh routed PRODUCT utilization report could be generated and qualified.

## Current recovery values

| Resource | Used | Total | Percent | Current status |
|---|---:|---:|---:|---|
| LUT | `N/A` | `N/A` | `N/A` | `NOT_RUN` |
| FF | `N/A` | `N/A` | `N/A` | `NOT_RUN` |
| BRAM | `N/A` | `N/A` | `N/A` | `NOT_RUN` |

No fresh PRODUCT LUT percentage exists, so the hard condition `LUT <= 90%` is not established and is conservatively recorded as gate `FAIL`.

## Historical context only — not current sign-off

| Resource | Historical used | Historical total | Historical percent |
|---|---:|---:|---:|
| LUT | 17,779 | 20,800 | 85.476% |
| FF | 19,314 | 41,600 | 46.428% |
| BRAM | 26.5 | 50 | 53.000% |

These are prior post-opt values only. They are explicitly not accepted as fresh routed PRODUCT resource evidence and do not satisfy this recovery gate.

`BITSTREAM_PRODUCED = NO`  
`HARDWARE_ACCESSED = NO`
