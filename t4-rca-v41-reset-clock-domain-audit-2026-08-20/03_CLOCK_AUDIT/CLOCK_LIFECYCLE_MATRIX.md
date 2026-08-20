# Clock lifecycle matrix

Both designs connect the byte-identical autoinit block to a nominal 62.5 MHz PCIe-generated user clock. Read-only routed reports identify `userclk1` (16.000 ns), ultimately generated from a GTPE2 `TXOUTCLK` through the PCIe pipe MMCM `CLKOUT2` and BUFG. RC-A reaches it as `pcie7.../user_clk_out`; v41 reaches it as `XDMA/axi_aclk` and aliases it to `autonomous_clk`.

There is no explicit RTL clock gate and neither `user_reset` nor `axi_aresetn` resets the NVP sequencer. However, the exact generated-IP lifecycle during PERST, link-down and a host warm reboot is not proven by retained artifacts. Consequently clock-active-before-link, clock-active-during-PERST, and reboot pause/phase-continuity are `UNKNOWN`, for both images. The source alone cannot prove v41-specific coupling.

If the clock pauses, synchronous registers retain state and the open-drain output enables retain their last values. On resumption, a partially completed byte continues; no physical reset or second start follows unless configuration/local NVP reset occurs. This is structural RTL behavior, not proof that a pause occurs in hardware.