
# R3R4R6R2R4 scope and authorization

Executed scope:

1. targeted retained-state cleanup;
2. task-local host disable critical-path correction and device-free tests;
3. read-only forensic parsing of the already preserved primary capture;
4. read-only RTL, NVP-mode, testbench, and VDO-timing audit;
5. directed XSim tests against the unmodified PRODUCT RTL;
6. an exact bounded diagnostic plan because an authoritative raw NVP marker
   trace is absent.

Explicitly not executed: new DMA capture, continuous capture, JTAG, FPGA
programming, bitstream generation, Flash access, power-cycle, source-worktree
modification, XDC modification, ABI modification, MMIO-map modification, or
speculative RTL/NVP correction.
