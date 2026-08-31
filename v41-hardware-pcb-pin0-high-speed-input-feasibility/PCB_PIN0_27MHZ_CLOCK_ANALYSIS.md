# PCB-PIN-0 27 MHz Clock Analysis

## Decision

`C13_27MHZ = NOT_RECOMMENDED`

C13 is bonded legal user I/O and its package name contains SRCC, but it is the N-side of the clock-capable pair. Vivado DRC `PLIO-9` rejects a single-ended C13 input driving a clock buffer: on this 7-series device only the P-side of the pair can drive the clock buffer in single-ended mode. Use D13, the P-side companion, for the 27.000 MHz oscillator.

## Device identity

- Package pin: C13
- Bank: 15, high-range
- I/O site: `IOB_X0Y77`
- Exact function: `IO_L11N_T1_SRCC_15`
- Clock region: `X0Y1`
- Vivado `BUFIO_2_REGION`: `LT`
- Clock capable: yes (`IS_CLK_CAPABLE=1`)
- Global-clock package flag: no (`IS_GLOBAL_CLK=0`)
- Differential companion: D13 (`IO_L11P_T1_SRCC_15`)
- Bonded/general-purpose/differential-capable: yes/yes/yes

The isolated full-pin sandbox instantiated `C13 -> IBUF -> BUFG`. Synthesis and initial DRC passed, but `place_design` stopped with:

> `PLIO-9`: clock source `ref27` is LOCed to an N-Type CCIO; for a single-ended input only the P-side can drive a clock buffer.

Using C13 through ordinary fabric routing or a clock-dedicated-route override would discard the deterministic clock path and is not recommended. C13 could still be sampled as ordinary data by another clock, but that does not satisfy the intended independent 27 MHz clock role.

`LVCMOS33` is legal in this HR bank when `VCCO_15` is 3.3 V. The new PCB must explicitly confirm that rail and that the oscillator high/low levels meet FPGA and NVP input specifications.

## Required alternative

D13 is `IO_L11P_T1_SRCC_15`, the P-side companion in the same Bank 15/T1/X0Y1 locality. It is the first-choice, minimal-change replacement and preserves MRCC resources. The controlled D13 variant is fully placed and fully routed, has zero post-place/post-route DRC checks, and routes all 73 routable nets with zero routing errors. Its result and reports are archived under `raw/placement`.

Both C13 and D13 are unassigned in the current accepted AHD design, so the correction creates no active signal conflict.

E13 (`IO_L12P_T1_MRCC_15`) is a second-choice alternative after VCLK1 moves to E16. It also works as a clock input but consumes an MRCC unnecessarily for ordinary 27 MHz fabric use.

## Shared oscillator fanout

After the required pin correction, the same oscillator may feed NVP SYS_CLK and FPGA D13 as two independent CMOS loads, provided the oscillator drive specification covers both inputs plus trace capacitance. The PCB review should:

- avoid a long daisy-chain/stub topology;
- check rise/fall time, overshoot and destination VIH/VIL at both loads;
- consider a source-series resistor or independently damped branches based on SI analysis, not a guessed value;
- verify that the oscillator output voltage matches both devices and Bank 15 VCCO;
- prevent input back-powering when the oscillator is alive while either destination is unpowered; and
- account for oscillator startup and reset release so NVP and FPGA logic do not assume a valid reference prematurely.

The direct 27 MHz signal is not a valid IDELAYCTRL reference. If IDELAYE2 is used, generate a compliant stable reference (normally 200 MHz) with an MMCM/PLL or another clock source, then hold/reset IDELAYCTRL until that source is stable and locked.
