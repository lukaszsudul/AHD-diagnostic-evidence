
# Physical input map

PHYSICAL_INPUT_MAP = PARTIALLY_PROVEN

| Physical connector | PCB refdes | NVP input | NVP channel | Route | FPGA input | Selected |
|---|---|---|---|---|---|---|
| UNKNOWN | UNKNOWN | VIN1 | CHANNEL_1 | Bank1 C2[3:0]=0 -> VDO1 | INPUT_0 via VCLK1/VDO1 | YES |
| UNKNOWN | UNKNOWN | VIN2 | CHANNEL_2 | Documented selectable C2[3:0]=1; not current | INPUT_0 only if routed to VDO1 | NO |
| UNKNOWN | UNKNOWN | VIN3 | CHANNEL_3 | Documented selectable C2[3:0]=2; not current | INPUT_0 only if routed to VDO1 | NO |
| UNKNOWN | UNKNOWN | VIN4 | CHANNEL_4 | Documented selectable C2[3:0]=3; not current | INPUT_0 only if routed to VDO1 | NO |

The silicon/source route is proven: NVP decoder channel 1/VIN1 is selected by
Bank1 C2[3:0]=0, VDO1 is the only enabled one-channel output, and VCLK1/VDO1
feeds FPGA INPUT_0. The exact as-built front-panel/PCB connector, refdes, label,
and net leading to VIN1 are not present in the authoritative materials inspected.
Connector order was not used as evidence. Consequently the external connector
cannot be named without the missing as-built schematic/netlist.
