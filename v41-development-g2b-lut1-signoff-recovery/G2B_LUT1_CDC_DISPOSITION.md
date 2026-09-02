# AHD v41 G2B-LUT1 CDC Disposition

## Overall CDC gate

- `CDC_DISPOSITION = FAIL`
- `EXECUTION_STATUS = NOT_RUN_AFTER_REQUIRED_BUS_SKEW_TIMEOUT`
- `FIRST_BLOCKER = Group 13 RESET_RETURN_SOURCE_TO_AXI`
- `BLOCKER_CLASSIFICATION = REQUIRED_BUS_SKEW_TIMEOUT`
- `WATCHDOG_BUDGET_SECONDS = 300`
- `OBSERVED_RUNTIME_SECONDS = 301.094`

The required Group 13 `report_bus_skew` query exceeded its bounded external watchdog. The fresh general product CDC report and its exact governed disposition were therefore not run. Historical raw CDC counts, including the prior 427 Critical entries, are neither automatically failed nor accepted as current recovery evidence. Because the current general CDC disposition was not completed, the overall CDC gate is `FAIL`.

## Ownership mailbox CDC already completed by Group 9

The independently completed promoted Group-9 ownership-mailbox sign-off remains valid and is not contradicted by a fresh general CDC report, because that general report was not run.

| Ownership check | Result |
|---|---|
| Request synchronizer | `PASS` |
| Ack synchronizer | `PASS` |
| Stable held payload | `PASS` |
| Slot-family settling | `PASS` |
| Generation-family settling | `PASS` |
| Epoch-family settling | `PASS` |
| Reset/epoch coherency | `PASS` |
| Ownership CDC | `PASS` |

This ownership-specific `PASS` does not replace the required whole-design CDC disposition. Current classifications for the remaining whole-design findings are `N/A — NOT_RUN`; no finding is silently classified as `INTENTIONAL_SYNCHRONIZER`, `GRAY_CDC`, `HANDSHAKE`, `FALSE_POSITIVE`, `REQUIRES_RTL_CHANGE`, or `UNRESOLVED` in this stopped run.

`BITSTREAM_PRODUCED = NO`  
`HARDWARE_ACCESSED = NO`
