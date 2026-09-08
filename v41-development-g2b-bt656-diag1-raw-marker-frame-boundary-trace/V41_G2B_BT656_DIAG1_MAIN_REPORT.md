# AHD v41 G2B-BT656-DIAG1 main report

## Outcome

- Engineering gate: FAIL
- Evidence publication: pending at report generation
- Overall result: FAIL
- First blocker: `BT656_DIAG1_FULL_BUILD_TIMING_GATE_FAILED:WNS=-4.675ns,TNS=-3545.498ns`
- Hardware accessed: NO

The final clean nonincremental Vivado 2025.2 build completed synthesis, optimization, placement, physical optimization and routing. The design is fully routed with zero unrouted or partially routed nets, but setup timing failed: WNS = -4.675 ns and TNS = -3545.498 ns. Hold timing passed with WHS = 0.031 ns and THS = 0.000 ns. Per the governing rule that a build or timing failure is FAIL, execution stopped before creation of a bitstream and before any DUT contact.

The worst setup path begins at `G2B_ONECH_C2H/transport_hard_hold_axi_reg` in `userclk1` and ends at `GEN_BT656_DIAG1_TRACE.BT656_BOUNDARY_TRACE/post_count_source_reg[0]` in `nvp_vclk1`. The path is introduced through the observational trace event qualifier. The generated CDC report independently contains 624 DIAG1 critical CDC rows with no disposition. This CDC issue is secondary evidence; the first failed gate remains setup timing.

## Passed work

- Accepted PRODUCT base: `92e9b3d914134c044371779def1ee18eaaeda98a`
- Diagnostic source commit: `08cb9f6f227766f3353dfc9ce6b0205d62f03639`
- Diagnostic source tree: `dcd5f8e7da149c399ccad73fbf460ac18685a62d`
- Diagnostic branch push: PASS
- Simulation gate: 10/10 PASS
- Functional noninterference: PASS
- Synthesis: PASS
- Fully routed: YES
- Unrouted nets: 0
- DRC errors / critical warnings: 0 / 0
- Resource limits: PASS (LUT 88.48%, FF 49.60%, BRAM 60.00%)

## Not reached

No diagnostic bitstream was produced. FPGA programming, warm reboot, DUT connection, driver load, MMIO, DMA, trace acquisition, replay, root-cause decision and correction-candidate creation were not reached. The accepted PRODUCT image and running hardware were untouched.

## Exact corrective direction

Create a fresh governed DIAG1 corrective run that removes the new unqualified `userclk1` dependency from the source-clock trace event/write controls, or transfers the required observation through an explicit reviewed CDC protocol. Then repeat simulation, CDC, full timing sign-off and resource gates before any hardware access. A constraint-only waiver is not supported by this evidence.
