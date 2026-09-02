# G2B-LUT1 Recovery 2 Routed Timing Summary

## Result

`ROUTED_TIMING = NOT_REACHED`

Fresh final routed timing was not launched. The required Group-14
`RELEASE_SLOT_0_AXI_TO_SOURCE` `report_bus_skew` query exceeded the external
300-second budget and produced the mandatory blocker:

`REQUIRED_BUS_SKEW_TIMEOUT:GROUP_14:RELEASE_SLOT_0_AXI_TO_SOURCE`

The bounded-runtime policy required an immediate stop before the remaining
groups and downstream routed gates. Historical timing is not substituted for
this required fresh result.

| Metric or criterion | Result |
|---|---|
| WNS | N/A |
| TNS | N/A |
| WHS | N/A |
| THS | N/A |
| Setup | `NOT_REACHED` |
| Hold | `NOT_REACHED` |
| Recovery/removal | `NOT_REACHED` |
| `no_clock = 0` | `NOT_REACHED` |
| Unconstrained internal endpoints = 0 | `NOT_REACHED` |
| Combinational loops = 0 | `NOT_REACHED` |
| Latch loops = 0 | `NOT_REACHED` |

The routed DCP remains identified by SHA-256
`EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`,
but checkpoint identity alone is not a fresh timing sign-off.
