# P2 ODIV2 route-feasibility report

- `SYNTHESIS=PASS`
- `PLACE=PASS`
- `ROUTE=FAIL`
- `ROUTE_ERRORS=2`
- `ROUTE_CRITICAL_WARNINGS=2`
- `CLOCK_DEDICATED_ROUTE_OVERRIDES=0`
- `BITSTREAM_GENERATED=NO`
- `XCI_CHANGED=NO` (the XCI was copied into the non-Git scratch build)
- `CLASSIFICATION=BLOCKED_ODIV2_DEDICATED_ROUTE`

The retained probe connected `PCIE_REFCLK_IBUF.ODIV2` to one `BUFG` and an
8-bit `DONT_TOUCH`/`SHREG_EXTRACT=NO` counter. Synthesis and placement passed.
Routing failed before detailed routing with `pcie_refclk` incomplete, one
unroutable pin, `Route 35-7`, and terminal `Route 35-4445`. No placement or
`CLOCK_DEDICATED_ROUTE` override was used. This is the prompt-defined hard
stop; the functional NVP cone was not edited and no bitstream or hardware
operation occurred.

