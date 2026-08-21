# Owner experiment statement

The authorized experiment changes exactly one functional source connection:

```text
rtl/top/ahd_capture_top_xdma.sv
I2C_HZ: 50000 -> 25000
```

It tests the `SLOWER_COMPLETE_I2C_TIMING_PROFILE`: every FSM interval expressed
in state ticks doubles, while the 62.5-MHz clock, local POR, R17 hold, 1.5-s
start delay, table, FSM source, filters, synchronizers, watchdog wall-clock
threshold, pins, I/O properties, XDMA, and capture logic remain unchanged.

The campaign authorization is one clean build and one interleaved A/B attempt,
with at most two FPGA programs and exact formal Phase 2 active at the end. No
scientific inference is permitted from an infrastructure-invalid arm.
