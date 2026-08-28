# AHD v41 R2 R1i causal hardware — cold-reset execution attempt

This immutable suffixed package preserves the R2 attempt performed after the Owner's cold reset. It does not overwrite the earlier blocked package at `v41-research-r2-r1i-causal-hardware`.

The live preflight succeeded and resolved the starting state as an unprogrammed xc7a35t (`DONE=0` in 5/5 read-only JTAG samples), with no enumerated Xilinx PCIe function, no loaded XDMA module, and no readable MMIO identity. The exact C0/C1/C2/C3 and Formal Phase-2 bitstreams were rehashed successfully. A candidate-aware read-only C0/C1/C2/C3 identity decoder was added and passed its offline self-test.

R2 then stopped at the mandatory first mutation gate because the shared `FPGA_AHD_HW_LOCK` implementation, current holder, lease state, acquisition, and ownership could not be proven. No FPGA programming, reset, power cycle, MMIO write, DMA, driver change, flash change, product-track action, formal cold-start trial, or experimental run occurred.

- Engineering gate: `BLOCKED`
- Scientific result: `BLOCKED`
- First blocker: `FPGA_AHD_HW_LOCK_STATE_NOT_PROVABLE`
- Initial DUT state: `UNPROGRAMMED_OR_FPGA_UNKNOWN`
- Owner cold reset counted as a formal trial: `NO`
- R3 started: `NO`

See `R2_CAUSAL_HARDWARE_REPORT.md` and `R2_EVIDENCE_INDEX.md`.
