# Exact successful autoinit duration

The divider is integer `62,500,000/(50,000*2)=625`; inclusive counter behavior produces a protocol tick every 626 clocks: 10.016 us. Two protocol states form one SCL period: 20.032 us or 49,920.1278 Hz.

- `POR_RELEASE_US=5.120` (320 clock cycles; configuration-init edge convention adds at most one 16 ns edge).
- `NVP_RESET_RELEASE_US=500000.016` from local POR reference.
- `FIRST_I2C_START_US=1500000.016` from local POR reference.
- Stage-2 table: 187 target writes, 25 bank changes, 26 disabled NOPs and one 10.026016 ms table delay.
- Pre/table/post total: 220 writes and 55 reads = 275 transactions.
- Writes use 61 protocol ticks; reads use 83. `SUCCESS_PATH_I2C_TRANSACTION_TIME_US=180137.760`.
- NOP, delay framing, settle, start-recognition and finish overhead: `SUCCESS_PATH_FIXED_DELAYS_US=130788.928`.
- Successful interval after first start: `310926.688 us`.
- `SUCCESS_PATH_TOTAL_FROM_FPGA_CONFIG_US=1810926.704` including the 16 ns local-POR edge convention.
- The successful path has no polling loop; bounded timeout paths are failure paths and are excluded from successful completion.
- `WORST_CASE_SUCCESS_TOTAL_US=1810926.704` plus at most one 10.016 us protocol-tick alignment uncertainty; conservatively round up to `1810937 us`.
- Preferred margin: max(1,000,000 us, 25% of 310,926.688 us = 77,731.672 us) = `1,000,000 us`.
- `RECOMMENDED_DELAYED_REBOOT_WAIT_US=2810937`.
- `RECOMMENDED_DELAYED_REBOOT_WAIT_SECONDS=2.810937`.

The operation counts are derived from the exact byte-identical table/functions and inclusive RTL counters. Simulation completes the same all-ACK sequence and checks table/bank/transaction counts, but at a scaled clock.