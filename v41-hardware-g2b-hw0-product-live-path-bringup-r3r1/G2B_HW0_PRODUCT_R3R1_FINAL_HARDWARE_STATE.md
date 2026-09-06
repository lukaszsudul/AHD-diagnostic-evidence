# R3R1 final hardware state

R3R1 did not access the hardware. The run therefore makes no fresh claim about
the DUT's boot, FPGA, PCIe, module, nodes, stream, DMA, NVP, or kernel state.

- hardware accessed: `NO`
- current boot ID: `N/A`
- candidate operation continuity: `UNRESOLVED`
- FPGA identity/DONE: `N/A` / `N/A`
- endpoint/BDF/link state: `N/A`
- stream disabled at final state: `NOT_REACHED`
- DMA quiescent at final state: `NOT_REACHED`
- candidate module unloaded at end: `NOT_LOADED`
- endpoint automatically unbound at end: `NOT_BOUND`
- XDMA nodes removed at end: `NOT_CREATED`
- candidate left in volatile SRAM: `UNRESOLVED`
- persistent DUT filesystem state modified: `NO`
- FPGA SRAM programming: `NO`
- Flash programming: `NO`
- reboot: `NO`
- power-cycle: `NO`

The predecessor R3 final inventory remains historical only.
