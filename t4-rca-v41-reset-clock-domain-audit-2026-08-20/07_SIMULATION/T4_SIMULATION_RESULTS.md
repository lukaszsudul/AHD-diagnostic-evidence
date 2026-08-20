# T4 simulation results

- Unmodified full NVP regression: PASS. All-ACK sequence completed at scaled 1 MHz/50 kHz; exact table length, every write, bank-select/verify count, transaction total and restored bank were asserted. NACK, bus-stuck, selector, filter and reset/restart cases also passed.
- Integration-retention model: all six pause cases retained POR/FSM/SCL/SDA state; after clock resume the model continued without a second physical reset. Pulsing PCIe reset, AXI reset, PERST and link-down controls did not reset the modeled NVP cone.
- RC-A and v41 share the tested functional module byte-for-byte; nominal module-boundary behavior is equivalent.
- Limitation: the integration model demonstrates the consequence of the exact RTL fan-in, not the actual XDMA/legacy-IP clock lifecycle. Pause occurrence remains `HYPOTHETICAL_NOT_PROVEN`.