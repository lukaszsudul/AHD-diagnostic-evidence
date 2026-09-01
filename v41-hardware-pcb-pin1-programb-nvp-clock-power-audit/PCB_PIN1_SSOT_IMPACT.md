# PCB-PIN-1 SSOT Impact

PROJECT_STATE_REV remains unchanged.

PCB-PIN-1 is an offline, read-only architecture audit. It does not promote the decisions into project-current-state, G-track, R-track, RTL, active XDC, or PCB source. No SSOT file was modified.

If the Owner/Architect later accepts the decisions, a governed META/source change should record:

- PROGRAM_B self-reset loop removed and no replacement GPIO required;
- the retained external PROGRAM_B pull-up/service/recovery architecture;
- internal ICAPE2/IPROG support as the intended future self-reconfiguration mechanism;
- oscillator input D13 and its 27.000 MHz/tolerance/electrical contract;
- A14 ownership as NVP SYS_CLK after the PCB-PIN-0 video-pin remap;
- the ODDR/OLOGIC forwarding and glitch-free start/stop contract;
- A14 preconfiguration weak-pull-up behavior and the external pull-down requirement;
- the final PUDC_B policy;
- passive low reset default and passive inactive defaults for both rail enables (LOW only after active-high polarity is confirmed);
- switched-domain I2C pull-ups and any required power-off isolation;
- NVP startup/shutdown ordering and datasheet-derived timing;
- permanent FPGA 3.3 V versus switched NVP 3.3 V domain separation;
- final component values after NVP/regulator/SI closure; and
- later routed DRC/timing/clock and power-domain evidence.

The future governed change must update schematic/PCB, RTL, XDC, timing, and SSOT coherently. This evidence directory is advisory architecture evidence only.
