# G2B-IMPL Timing, Clock, DRC, and Route Summary

## Gate result

The full implementation gate was not reached. The clean flow stopped after
successful `opt_design` at the mandatory post-opt resource-headroom gate.

| Check | Result |
|---|---|
| Synthesis | PASS |
| `opt_design` | PASS |
| `opt_design` prerequisite DRC | 0 errors |
| Placement | NOT_RUN |
| Physical optimization | NOT_RUN |
| Routing | NOT_RUN |
| Full routed DRC | NOT_RUN |
| Routed CDC report | NOT_RUN |
| Routed bus-skew report | NOT_RUN |
| Routed timing summary | NOT_RUN |
| WNS | NOT_AVAILABLE |
| WHS | NOT_AVAILABLE |
| Critical paths / new C2H routed paths | NOT_AVAILABLE |
| Critical DRC qualification | NOT_SATISFIED |

No synthesis estimate is substituted for routed timing closure.

## Generated clock evidence

The generated post-synthesis timing database reported:

| Clock | Period | Frequency |
|---|---:|---:|
| `userclk1` | 16.000 ns | 62.500 MHz |
| `nvp_vclk1` | 6.734 ns | 148.500 MHz |
| `pcie_refclk_100` | 10.000 ns | 100.000 MHz |

The XDMA-generated `userclk1` clocks the exported AXI application interface,
but the build harness intentionally requires routed consumer binding before
classifying the effective user/AXI clock as proven. Consequently the build
receipt records both effective clock values as `UNKNOWN` even though the
generated clock itself is 62.500 MHz. There is no observed configuration drift;
routed confirmation remains unavailable.

## Constraints and exceptions

The clean build parsed the accepted board/project constraints and the new
`xdc/common/g2b_cdc.xdc`. The G2B file provides first-stage asynchronous CDC
exceptions and bounded/bus-skew constraints for acknowledged mailbox and
snapshot buses. A static endpoint audit passed, but the build stopped before
the harness could re-resolve all collections in the routed netlist and run
`report_cdc`, `report_bus_skew`, and exception-coverage gates.

## Disposition

Timing, routing, and critical DRC must be reported as FAIL/not qualified for the
G2B-IMPL acceptance gate. The first blocker is resource headroom, not a proven
timing or DRC defect. No bitstream was generated.
