# G2B-LUT1 Recovery 2 DRC Summary

## Result

`DRC = NOT_REACHED`

The fresh final DRC required for recovery-2 was not launched because the
bounded Group-14 query produced the prior hard stop:

`REQUIRED_BUS_SKEW_TIMEOUT:GROUP_14:RELEASE_SLOT_0_AXI_TO_SOURCE`

| Required item | Result |
|---|---|
| Errors | N/A |
| Critical warnings | N/A |
| Warning inventory | `NOT_REACHED` |
| Minimum release requirement: errors = 0 | `NOT_REACHED` |
| Minimum release requirement: critical warnings = 0 | `NOT_REACHED` |

The three warnings captured by the Group-14 query process concern a duplicate
Vivado strategy definition and the BS3/G13 XDC files already being present in
the project. They are not final DRC results and are not used to claim DRC
sign-off. No historical DRC report is substituted for the required fresh run.
