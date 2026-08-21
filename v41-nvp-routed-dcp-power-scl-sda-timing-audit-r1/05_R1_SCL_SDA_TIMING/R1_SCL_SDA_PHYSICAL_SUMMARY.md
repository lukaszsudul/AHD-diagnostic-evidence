# R1 SCL/SDA Physical Summary

Both ports use the same electrical standard and open-drain structure: T17/T18, bank 14, LVCMOS33, DRIVE 12, SLOW, blank/unset PULLTYPE, and constant zero on the OBUFT data input. DIFF_TERM=0 and IN_TERM=NONE are reported. No OEN or synchronizer register is reported as IOB-packed.

| Path | SCL max/min (ns) | SDA max/min (ns) | absolute max/min delta (ns) | Status |
|---|---:|---:|---:|---|
| OEN register Q → OBUFT T | 2.303 / 1.090 | 1.709 / 0.767 | 0.594 / 0.323 | Physical direct delay from get_net_delays |
| IBUF O → sync0 D | 1.246 / 0.626 | 2.004 / 1.080 | 0.758 / 0.454 | Unconstrained asynchronous path; physical delay only |
| sync0 Q → sync1 D | 0.523 / 0.196 | 0.577 / 0.219 | 0.054 / 0.023 | Timed synchronous path |

The output max delta is 3.71% of the 16-ns AXI clock and 0.011861% of the 5.008-µs I²C midpoint. The input max delta is 4.74% of the AXI clock and 0.015136% of the midpoint. These nanosecond differences are measurable implementation facts, not proof of analog I²C margin.

Known external context: each line has a 4.7-kΩ pull-up to 3.3 V, or approximately 0.702 mA static current when driven low. External bus capacitance and rise time are unknown and unmeasured; they cannot be inferred from the FPGA route.