# G2B-LUT1 Recovery 2 Clock Summary

## Result

`CLOCKS = NOT_REACHED`

The fresh clock review was not launched because the Group-14 required
`report_bus_skew` query exceeded its external 300-second budget and forced the
governed hard stop.

| Required item | Fresh result |
|---|---|
| Effective XDMA user clock | N/A |
| Effective AXI clock | N/A |
| Source clocks | `NOT_REACHED` |
| Generated clocks | `NOT_REACHED` |
| Unconstrained clocks | `NOT_REACHED` |
| Clock interactions | `NOT_REACHED` |
| Clock-routing issues | `NOT_REACHED` |

The exact hash-bound offline protection receipt preserves an XDMA configured
user-clock value of approximately `62.5 MHz`, consistent with the historical
expectation. That configured value is retained only as protected source
context; it is not promoted to a fresh routed clock-sign-off result for this
execution. Therefore the reported current effective user and AXI clocks remain
N/A.
