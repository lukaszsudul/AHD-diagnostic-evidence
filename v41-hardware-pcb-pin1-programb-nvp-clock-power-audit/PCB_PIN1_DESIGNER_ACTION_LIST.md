# PCB-PIN-1 Designer Action List

## Routing decisions

1. Remove the FPGA T12 to PROGRAM_B self-reset route. No replacement FPGA GPIO is required.
2. Keep the dedicated PROGRAM_B external pull-up to VCCO_0 and preserve normal programming/recovery access. If recovery must work without a running image, design a separate external supervisor/controller path.
3. Route the 27.000 MHz oscillator only to FPGA D13.
4. Route FPGA A14 to NVP SYS_CLK only after accepting the PCB-PIN-0 channel-1 video remap that frees A14.
5. Provide a source-series resistor footprint close to A14. Select stuffing/value after stackup and SI analysis.
6. Provide and stuff an NVP SYS_CLK pull-down that guarantees low against the worst-case FPGA configuration pull-up. Select its value from NVP VIL/leakage and AMD IRPU data; do not copy an arbitrary value.
7. Provide the locally required SYS_CLK measurement access as a low-capacitance, low-stub probe pad/test point, and include it in the final SI analysis.

## Passive safe states

8. Confirm A9 / EN_VDD1x power-device polarity first, then guarantee its inactive level before and during FPGA configuration (LOW under the reviewed active-high assumption). Confirm VIL/VIH, internal pulls, reverse-current isolation, and power-good behavior.
9. Apply the same polarity-first and passive-inactive-default review to A10 / EN_VDD3x.
10. Hold active-low NVP reset low while NVP is off and until rails/clock are valid. Confirm the unpowered reset-pin current from the NVP datasheet.
11. Resolve the PUDC_B-low consequence for every NVP-connected SelectIO. The 1 kOhm J18 strap enables weak FPGA pull-ups on CLK, RST, SDA, SCL, IRQ, and both enable controls during configuration.

## I2C and IRQ domains

12. Connect SDA/SCL pull-ups to switched NVP 3.3 V, not permanent FPGA 3.3 V.
13. Ensure SDA/SCL are isolated or proven fail-safe while NVP is off, including the FPGA configuration-pull-up interval.
14. Put any required IRQ pull-up on switched NVP 3.3 V and confirm whether IRQ is open-drain, push-pull, or high-Z when NVP is off.
15. Do not combine permanent FPGA 3.3 V and switched NVP 3.3 V into one schematic power domain merely because both are nominally 3.3 V.

## Required component/datasheet closure

16. Obtain the NVP6134C electrical and power-sequencing specifications: SYS_CLK VIH/VIL/duty/jitter/capacitance/Ioff, reset timing/Ioff, SDA/SCL fail-safe behavior, IRQ off-state, rail order, and all delays.
17. Obtain regulator/load-switch enable thresholds, internal pulls, ramp/discharge, reverse-current, and PG timing.
18. Validate pull-down values against the AMD 330 microamp worst-case configuration pull-up plus receiver leakage.
19. Perform board-level clock SI review using final stackup, trace geometry, receiver model, source strength/slew, pull-down, series option, and probe feature.

## Later governed implementation work

20. After Owner/Architect acceptance, update the schematic/PCB source, META/SSOT, RTL top-level, active XDC, and timing constraints in one governed change.
21. Implement D13 IBUF/BUFG to A14 ODDR/OBUF forwarding with a synchronized registered run state; never use a fabric-toggled clock output.
22. Implement deterministic startup/shutdown and keep I2C high-Z while switched 3.3 V is absent.
23. Re-run product-project synthesis, placement, route, DRC, timing, and power-domain validation. PCB-PIN-1 does not authorize a product bitstream.

## Decision summary

- Point 10: REMOVE the PROGRAM_B self-loop; route may proceed without a T12 replacement.
- Point 11: APPROVE_WITH_CHANGES the D13-to-FPGA-to-A14 NVP clock plan subject to every applicable action above.
