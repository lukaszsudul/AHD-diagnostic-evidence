# Product-equivalent autoinit receipt

Result: `PASS`

- trigger: exact FPGA configuration, automatic product-equivalent initialization
- AUTOINIT_DONE: `1`
- AUTOINIT_BUSY: `0`
- AUTOINIT_ERROR: `0`
- NACK_COUNT: `0`
- TIMEOUT_COUNT: `0`
- NVP_RESET_RELEASED: `1`
- raw NVP state: `0x000000F9`

The values were verified after the single warm reboot through the exact runtime MMIO gate.
