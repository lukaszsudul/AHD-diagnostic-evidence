# P2 route-classification erratum

The historical classification `BLOCKED_ODIV2_DEDICATED_ROUTE` is preserved,
but its architectural interpretation was too broad. The authoritative Vivado
log identifies this connection:

```text
CRITICAL WARNING: [Route 35-54] Net: pcie_refclk is not completely routed.
Type 1 : IBUFDS_GTE2.O->BUFGCTRL.I0
-----Representative Net: Net[6649] pcie_refclk
-----IBUFDS_GTE2_X0Y0.O -> BUFGCTRL_X0Y18.I0
-----Driver Term: PCIE_REFCLK_IBUF/O Load Term [33411]: XDMA/inst/xdma_v41_m1_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/cpllpd_refclk_inst/I
ERROR: [Route 35-7] Design has 1 unroutable pin
ERROR: [Route 35-4445] route_design is terminated
```

```text
ORIGINAL_CLASSIFICATION=BLOCKED_ODIV2_DEDICATED_ROUTE
CORRECTED_ARCHITECTURAL_INTERPRETATION=IBUFDS_GTE2_O_AND_ODIV2_BUFG_CONTENTION_AT_DEFAULT_PLACEMENT
UNROUTABLE_NET=pcie_refclk_FROM_IBUFDS_GTE2_O
BLOCKED_LOAD=XDMA_CPLLPD_REFCLK_BUFGCTRL_X0Y18
ODIV2_NET_REPORTED_UNROUTABLE=NO
ODIV2_FUNCTIONAL_TEST=NOT_RUN
NVP_ROOT_CAUSE=UNRESOLVED
```

This erratum is additive. It neither alters the original report nor reruns P2.
