# Hardware gate status

`R1D_HARDWARE_WINDOW_ASSIGNED=NO`

`R1D_HARDWARE_PHASE=WAITING_FOR_OWNER_HARDWARE_WINDOW`

`HARDWARE_ACTIONS=0`

No separate Owner statement containing
`R1D_HARDWARE_WINDOW_ASSIGNED=YES`, assignment UTC, the exact R1d window scope,
and confirmation that LitePCIe remains offline/hardware-free was supplied.
Accordingly, work stopped before P7. No SSH connection to the DUT, hw_server,
JTAG, FPGA programming, reboot, driver operation, PCIe action, MMIO, or DMA was
performed. The diagnostic image has not been programmed, the two live campaign
counters do not exist yet, and no scientific frequency-effect classification
is available.

