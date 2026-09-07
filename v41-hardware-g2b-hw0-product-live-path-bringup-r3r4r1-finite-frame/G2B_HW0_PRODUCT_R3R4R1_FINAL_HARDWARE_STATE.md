# R3R4R1 final hardware state

Hardware accessed: `NO`. Boot ID, FPGA DONE, PCIe link, endpoint state,
driver state, DMA state, and kernel taint are `NOT_REACHED` and are not
inferred from R3R3. FPGA programming, reboot, power-cycle, Flash programming,
driver load, MMIO, DMA, and capture counts are all zero.

Candidate left in volatile SRAM: `UNRESOLVED` because no current DUT
observation occurred.
