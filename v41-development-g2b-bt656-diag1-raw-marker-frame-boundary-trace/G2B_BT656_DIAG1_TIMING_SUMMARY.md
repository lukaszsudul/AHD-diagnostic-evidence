# Timing summary

- Gate: FAIL
- WNS: -4.675 ns
- TNS: -3545.498 ns
- Setup failing endpoints: 1415
- WHS: 0.031 ns
- THS: 0.000 ns
- Fully routed: YES
- Worst source: `G2B_ONECH_C2H/transport_hard_hold_axi_reg` (`userclk1`)
- Worst destination: `GEN_BT656_DIAG1_TRACE.BT656_BOUNDARY_TRACE/post_count_source_reg[0]` (`nvp_vclk1`)
- Path type: inter-clock setup
- Data path delay: 3.289 ns
- Requirement: 0.048 ns
- First blocker: `BT656_DIAG1_FULL_BUILD_TIMING_GATE_FAILED:WNS=-4.675ns,TNS=-3545.498ns`

The violating cone reaches the diagnostic trace event/write control. No timing exception or waiver was added after the failed build.
