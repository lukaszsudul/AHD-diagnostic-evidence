# T4 simulation plan

1. Compile the unmodified diagnostics package, I2C sequencer and existing full regression; run all-ACK completion plus fault/reset regression.
2. Run an external integration-retention model with the same configuration-only local POR property. Pause its clock at six representative points and pulse PCIe/XDMA/PERST/link integration controls.
3. Treat every clock-pause case as `HYPOTHETICAL_NOT_PROVEN`; exact generated-IP reboot clock behavior is unavailable.
4. Generate no implementation or bitstream.