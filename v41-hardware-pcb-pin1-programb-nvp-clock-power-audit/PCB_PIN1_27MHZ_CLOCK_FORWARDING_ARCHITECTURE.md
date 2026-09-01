# PCB-PIN-1 27 MHz Clock Forwarding Architecture

## Classifications

D13_27MHZ_INPUT = VALID

A14_NVP_CLOCK_OUTPUT = VALID_WITH_CONSTRAINT

GLITCH_FREE_CLOCK_GATING = FEASIBLE_WITH_CONSTRAINTS

CLOCK_FORWARDING = ODDR/OLOGIC_RECOMMENDED

FPGA_GATED_27MHZ_TO_NVP = APPROVE_WITH_CHANGES

## Device resources

The exact target is xc7a35tcsg325-2.

| Pin | Bank | Exact package function | Site | Assessment |
|---|---:|---|---|---|
| D13 | 15 | IO_L11P_T1_SRCC_15 | IOB_X0Y78 | preferred corrected 27 MHz LVCMOS33 input |
| A14 | 15 | IO_L8N_T1_AD10N_15 | IOB_X0Y83 | ordinary user output after configuration; OLOGIC/ODDR available |

D13 is the P-side SRCC pin previously accepted as the correction to the invalid single-ended C13/N-side clock plan. Its SRCC role provides legal single-region clock access, including the regional BUFR resources for its clock region, and legal routing to BUFG for global/fabric use. The PCB-PIN-0 D13 sandbox placed and routed D13 through a dedicated IBUF-to-BUFG clock path with zero post-route DRC violations.

A14 is an HR Bank-15 user I/O. LVCMOS33 is legal when VCCO_15 is 3.3 V. At 27 MHz it is suitable for a forwarded clock using its dedicated output logic. Its exact pin name includes the `AD10N` configuration-bus multifunction role, which matters only in a configuration mode that consumes it. The local PCB requirements specify Master-SPI mode M[2:0]=001, which does not consume that AD10N function; the final mode straps must retain that compatibility.

## Pin conflict condition

The active v40 XDC currently assigns A14 to vdo1_data[0]. PCB-PIN-0's proposed product pin remap moves channel-1 video data away from A14, which makes the new clock use compatible with that proposed routing plan. A14 is not available if the current active v40 pinout is retained.

Therefore A14 is VALID_WITH_CONSTRAINT, with an explicit PCB condition: accept and implement the PCB-PIN-0 channel-1 remap before dedicating A14 to NVP SYS_CLK. This audit does not modify the active XDC.

## Recommended implementation

Use the continuously running input clock for internal control and the A14 OLOGIC for output edges:

    27.000 MHz oscillator
      -> D13 IBUF
      -> BUFG
      -> internal clk27

    firmware/control request
      -> two-stage clk27-domain synchronization
      -> registered run state

    ODDR in A14 OLOGIC
      C    = clk27
      CE   = 1
      D1   = registered run state
      D2   = 0
      INIT = 0
      R/S  = inactive during normal gating
      -> OBUF
      -> A14
      -> NVP SYS_CLK

In OPPOSITE_EDGE mode, D1 controls the output at each rising edge and D2 forces it low at each falling edge. With run registered in the same 27 MHz domain:

- enable takes effect on a defined rising edge;
- the first high interval ends on the following falling edge;
- disable can add at most a final complete pulse;
- the final falling edge returns the output low; and
- disabled operation remains low because both selected data values are zero.

This uses dedicated ODDR/OLOGIC output timing. It does not toggle a fabric GPIO and does not AND a clock with a combinational enable.

## Firmware and later RTL contract

Future implementation must guarantee:

1. The enable request is synchronized into the continuously running 27 MHz domain.
2. The run state is registered and is the only dynamic ODDR data control.
3. D2 remains constant zero and CE remains enabled for this architecture.
4. No asynchronous ODDR reset is asserted during a high pulse.
5. Startup initializes run and ODDR output state to zero.
6. Clock stop is acknowledged only after the output has reached and remains low.
7. NVP reset remains asserted throughout clock start/stop transients and until the NVP-required interval is satisfied.
8. Timing constraints explicitly cover D13, the internal clock, the run-to-ODDR path, and the forwarded clock at A14.

Dynamic ODDR CE alone is not the preferred low-forcing mechanism because CE can preserve the last Q state. A BUFGCE plus fixed D1=1/D2=0 is a possible alternative only with a synchronized, timing-clean CE and an always-running control clock.

## Duty cycle, jitter, and phase

The ODDR forwards rising and falling edges through a dedicated output path, so duty-cycle quality follows the input waveform plus I/O asymmetry and board loading. It avoids fabric routing skew and logic-generated jitter. It does not improve oscillator jitter. The NVP datasheet must confirm accepted frequency, duty cycle, jitter, and input thresholds/capacitance.

Clock phase is deterministic relative to D13 after implementation, but board trace delay and ODDR/OBUF delay must be included in any later timing model. Phase continuity exists only while enabled; a stop/start deliberately creates a phase discontinuity and must occur while NVP reset is asserted.

## Later constraint requirements

After Owner acceptance, the implementation should include:

- a primary-clock constraint derived from 27.000 MHz nominal and the oscillator's specified tolerance (37.037 ns nominal period);
- a generated/forwarded clock definition at A14 as required by timing analysis;
- output electrical properties compatible with Bank 15 and the NVP input;
- complete route/DRC/timing evidence in the governed product project; and
- no CLOCK_DEDICATED_ROUTE exception as a substitute for legal routing.

## PCB signal-integrity options

| Item | Classification | Note |
|---|---|---|
| source-series resistor footprint near A14 | RECOMMENDED | select stuffing/value after stackup, trace, receiver, and IBIS/SI analysis |
| pull-down footprint on NVP SYS_CLK | RECOMMENDED | resistor stuffing is required for the stated guaranteed-low requirement |
| clock test point | RECOMMENDED | local PCB requirements call for SYS_CLK waveform access; use a low-capacitance, low-stub probe feature |

No exact series or pull-down value is prescribed by this audit. The requirements file records prior clock degradation downstream of a series element and warns against added downstream loading, so the resistor, pull-down, probe feature, trace, and receiver must be analyzed and validated as one final topology.

## References

- AMD UG471, 7 Series FPGAs SelectIO Resources, ODDR and clock-forwarding sections: https://docs.amd.com/v/u/en-US/ug471_7Series_SelectIO
- AMD UG953, ODDR primitive: https://docs.amd.com/r/2023.1-English/ug953-vivado-7series-libraries/ODDR
- AMD UG903, Forwarded Clocks: https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Forwarded-Clocks
- Published PCB-PIN-0 evidence: ../v41-hardware-pcb-pin0-high-speed-input-feasibility/PCB_PIN0_27MHZ_CLOCK_ANALYSIS.md
