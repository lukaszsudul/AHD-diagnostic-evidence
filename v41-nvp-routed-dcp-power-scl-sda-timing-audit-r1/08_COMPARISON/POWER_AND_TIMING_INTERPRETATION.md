# Power and SCL/SDA Timing Interpretation

## Exact-control status

Both control checkpoints are admissible: the exact formal Phase-2 routed DCP has an explicit build-log chain to bit SHA-256 7E4E...449A2, and the RC-A routed DCP has an explicit chain to the passing A43B...3B6 bit. All three were audited with Vivado 2025.2 using identical report scripts and unchanged power assumptions.

## I/O and routed implementation

SCL/SDA electrical properties are identical across all three exact images: T17/T18, bank 14, LVCMOS33, DRIVE 12, SLOW, blank/unset PULLTYPE, and constant-zero OBUFT data. All use one IBUF plus one OBUFT per line, and the two-stage input synchronizers retain ASYNC_REG=TRUE and SHREG_EXTRACT=NO. No IOB packing is reported for the OEN or synchronizer registers.

Placement and routing differ substantially. Slow-max direct path delays (ns) are:

| Path | R1 | Formal Phase-2 | RC-A |
|---|---:|---:|---:|
| SCL OEN→T | 2.303 | 3.256 | 4.273 |
| SDA OEN→T | 1.709 | 3.017 | 5.696 |
| SCL pad→sync0 | 1.246 | 2.134 | 3.788 |
| SDA pad→sync0 | 2.004 | 2.418 | 3.987 |

The passing RC-A image is often the longest. Therefore the DCP comparison proves implementation movement/sensitivity but contradicts a simple explanation in which a longer internal digital path causes the v41 failure. R1 synchronous worst paths remain comfortably within 16 ns. Nanosecond route differences are tiny relative to the 5.008-µs I²C midpoint and 10.016-µs state tick. Asynchronous pad-to-sync paths are unconstrained; their reported physical delay is not setup slack or analog margin.

IMPLEMENTATION_IO_MARGIN_FINDING=SUPPORTED_BY_EXACT_DCP_COMPARISON means relevant implementation differences exist. It does not mean that v41 has worse FPGA digital timing or that an analog root cause is proven.

## Power context

R1 and exact formal Phase-2 are nearly equal: total power differs by +0.005 W (+0.79%) and dynamic power by +0.005 W (+0.91%), so R1 observer overhead is small in this estimate. Against passing RC-A, R1 is materially higher: total 0.636 versus 0.401 W (+58.60%) and dynamic 0.557 versus 0.323 W (+72.45%). Clock, signal, logic, BRAM, and MMCM estimates are also materially higher; GTP is unchanged. Estimated VCCINT and VCCAUX currents are approximately +98.6% and +113.6% versus RC-A.

The comparison is valid for ranking because the same Vivado version, report commands, and vectorless/default activity class were used. Confidence is nevertheless Low overall, I/O activity confidence is Low, and internal-node activity confidence is Medium. Aggregate Vcco33 is effectively identical at report precision and is not a bank-14 decomposition. The model therefore cannot prove board-level Vcco droop, ground bounce, SCL/SDA rise time, or VIH margin.

## Classification

~~~text
IMPLEMENTATION_IO_MARGIN_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

POWER_CONTEXT_FINDING=
    SUPPORTED_BY_EXACT_DCP_COMPARISON

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_I2C_MARGIN_PROVEN=
    NO

ROOT_CAUSE_SOLELY_PROVEN=
    NO
~~~

No hardware experiment is recommended automatically. Owner and auditor review is required before any hardware run.