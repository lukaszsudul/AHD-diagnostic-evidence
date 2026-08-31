# PCB-PIN-0 DDR Feasibility

## Decisions

- `CH1_DDR_ARCHITECTURE = SUPPORTED_WITH_CONSTRAINTS`
- `CH2_DDR_ARCHITECTURE = SUPPORTED_WITH_CONSTRAINTS`
- `FPGA_PINOUT_2CH_DDR_MUX_READY = YES_WITH_CONSTRAINTS`
- `TIMING_RISK = MEDIUM`

The conditions are implementation and interface-timing work, not illegal pins. At 148.5 MHz physical clock, sampling both edges produces 297 million transfers/s per bit. The pin groups preserve the architecture needed for that future mode.

## Supported receive topology

For each channel:

`VCLK -> IBUF -> BUFIO -> IDDR/ISERDESE2 CLK`

and:

`VCLK -> IBUF -> BUFR -> regional word clock / ISERDESE2 CLKDIV`

with optional per-bit deskew:

`VDO -> IBUF -> IDELAYE2 -> IDDR/ISERDESE2`

Both SRCC pins and every associated data bit are in the same bank, same clock region, same T2 pin group, and same `BUFIO_2_REGION=LB`. Therefore the local high-speed clock can reach every intended ILOGIC without fabric-clock routing.

IDDR is the preferred primitive for the stated two-edge, two-sample case. ISERDESE2 is also present in the ILOGIC path and may be chosen if later logic benefits from deserialization/word alignment. It requires a correct `CLK`/`CLKB` and phase-related `CLKDIV` topology and legal data-width parameters.

## Required constraints and calibration

DDR support is conditional on all of the following:

1. Obtain the NVP output clock-to-data timing specification for the selected mux mode.
2. Budget PCB clock/data mismatch, connector/package variation, jitter and duty-cycle distortion.
3. Apply `create_clock` and rise/fall `set_input_delay -min/-max` constraints for both edges.
4. Pack the sampling elements into ILOGIC and keep the clock on dedicated BUFIO routing.
5. If IDELAYE2 is used, provide a compliant stable IDELAYCTRL reference and reset/ready sequencing.
6. Cross from the receive/word clock into the PCIe or system domain using an explicit CDC/FIFO boundary.
7. Prove timing only after the real design and PCB budgets are routed; this audit reports only `PIN_FEASIBILITY_PASS`.

## Two-channel time-multiplexed stream

The FPGA pinout itself does not prevent a future codec mode that places two logical channels on one eight-bit DDR/time-multiplexed port. All eight pins can capture both edges, and bit-order permutation is purely a logical mapping. The later implementation must establish edge/channel framing, codec mode, word alignment, reset behavior and CDC. This audit makes no claim about the NVP register configuration.

## Risk interpretation

SDR at 148.5 MHz is low architectural risk with these groups. DDR at 297 MT/s is reasonable for 7-series ILOGIC but still needs real source timing, PCB skew, IDELAY calibration if margin requires it, and routed analysis. That makes the combined planning risk `MEDIUM`, not because a selected pin lacks the required resources.
