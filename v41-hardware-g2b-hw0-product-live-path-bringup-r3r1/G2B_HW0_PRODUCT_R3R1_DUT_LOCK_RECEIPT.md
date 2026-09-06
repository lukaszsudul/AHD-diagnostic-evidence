# R3R1 DUT lock receipt

The mandatory authority conflict was reached before any operation requiring a
hardware lock.

- controller lock acquired: `NO`
- Linux lock acquired: `NO`
- controller lock directory at final check: `ABSENT`
- Linux lock creation/release: `NOT_RUN`
- JTAG/PCIe/module/MMIO/DMA operation under R3R1: `NONE`

`CONTROLLER_LOCK = NOT_REACHED_DUE_TO_PRE_EXECUTION_BLOCKER`

`LINUX_LOCK = NOT_REACHED_DUE_TO_PRE_EXECUTION_BLOCKER`

No lock is claimed as proof of DUT exclusivity.
