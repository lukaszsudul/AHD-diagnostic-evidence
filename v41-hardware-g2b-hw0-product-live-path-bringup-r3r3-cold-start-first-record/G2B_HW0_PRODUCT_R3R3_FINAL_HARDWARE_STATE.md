# Final hardware state

- Boot ID: 614295f4-c62b-4430-ae67-06013bea7084; no unexpected later transition.
- FPGA: exact sole xc7a35t, IDCODE 0362D093, final DONE 1 in five samples.
- Candidate left in volatile SRAM: YES.
- FPGA SRAM programming: YES_ONCE; Flash: NO; power cycle: NO; warm reboot: YES_ONCE.
- AHD endpoint: 0000:01:00.0, present, unbound, Gen2 x1 through root 0000:00:01.1.
- xdma_ahd_pcie: unloaded normally; platform xdma: absent; XDMA nodes/holders: none.
- Last pre-unload transport state: CONTROL 0x00000000, STATUS 0x000004F4, quiescent; ERROR_STATUS 0x00000007 preserved.
- Kernel/AER fatal health: PASS; final taint 12288 expected.
- Linux and controller locks: released in required order.
- Persistent DUT filesystem modification: NO (driver was not installed).

The safe final state does not convert T3 to PASS. First-record ABI and counter qualification remain not proven.
