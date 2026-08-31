# AHD PCB-PIN-0 XC7A35T-CSG325 High-Speed Input Feasibility Audit

## Executive decision

- `ENGINEERING_GATE = PASS`
- `PIN_FEASIBILITY = PASS`
- `PCB_ROUTING_OVERALL = APPROVE_WITH_CHANGES`
- `TIMING_RISK = MEDIUM`
- Exact Vivado part: `xc7a35tcsg325-2`
- Source repository modified: NO
- XDC modified: NO
- Product bitstream created: NO
- Hardware/DUT accessed: NO
- SSOT/G-track/R-track modified: NO

Both proposed eight-bit video interfaces are architecturally suitable for 148.5 MHz source-synchronous SDR capture and preserve a clean future DDR path at 297 MT/s per bit. Each complete clock+data group occupies one HR bank, one clock region, one package-name T2 group, and one Vivado BUFIO subregion. E16 and R16 are valid SRCC inputs with local BUFIO/BUFR reach to every associated data ILOGIC.

Before PCB routing, change the 27 MHz oscillator input from C13 to D13. Vivado DRC `PLIO-9` proves that C13 is the N-side of the SRCC pair and cannot drive a clock buffer as a single-ended input; D13 is the P-side companion. Also change the provisional CH2 data pin T15 to U15 if practical. T15 is legal but consumes an MRCC; U15 completes four contiguous L15-L18 P/N data pairs and preserves the T14/T15 MRCC pair. Do not approve or stuff the proposed J18 1 kOhm pull-down until the schematic net and PUDC_B/configuration intent are known.

This is a pin-feasibility pass only. Final timing requires the codec clock-to-data specification, PCB skew budget, real RTL, input delays and routed implementation.

## Required channel decisions

| Field | CH1 | CH2 |
|---|---|---|
| PIN_SET_VALID | YES | YES |
| BANK_LOCALITY | PASS | PASS |
| CLOCK_PIN_VALID | YES, SRCC | YES, SRCC |
| BUFIO_REACHABILITY | PASS | PASS |
| IDDR_SUPPORTED | SUPPORTED | SUPPORTED |
| ISERDES_SUPPORTED | SUPPORTED | SUPPORTED |
| IDELAY_SUPPORTED | SUPPORTED | SUPPORTED |
| 148.5 MHz SDR | STRONGLY_RECOMMENDED | STRONGLY_RECOMMENDED |
| 148.5 MHz DDR | SUPPORTED_WITH_CONSTRAINTS | SUPPORTED_WITH_CONSTRAINTS |
| PCB recommendation | APPROVE_FOR_PCB_ROUTING | APPROVE_WITH_CHANGES |

Additional decisions:

- `C13_27MHZ = NOT_RECOMMENDED`
- `CONTROL_PINS = PASS_WITH_CONSTRAINTS`
- `MPP1-MPP4_CURRENT_USE = UNUSED`
- `MPP1-MPP4_REMOVAL = SAFE_WITH_CONSTRAINTS`
- `J18_PULLDOWN_REVIEW = NEEDS_SCHEMATIC_CONTEXT`
- `FPGA_PINOUT_2CH_DDR_MUX_READY = YES_WITH_CONSTRAINTS`

## Device identity and objective database evidence

Vivado 2025.2 accepted the requested `xc7a35t-csg325-2` spelling and returned canonical project part `xc7a35tcsg325-2`. The accepted AHD I/O report independently identifies device xc7a35t, package csg325, speed file -2. No different device/package/speed was substituted.

All 23 proposed pins and J18 resolve as bonded general-purpose user I/O in the package database. Banks 14 and 15 are `BT_HIGH_RANGE`. Exact package functions, IOB sites, differential companions, clock regions and local-buffer grouping are in `PCB_PIN0_PER_PIN_AUDIT.csv` and the raw Vivado property dump.

## Bank and T-group locality

### Channel 1

E16 is `IO_L14P_T2_SRCC_15`. B16/C16/A17/B17/C17/C18/E17/D18 are Bank 15 T2 L15-L18 and form four complete P/N pairs. Every site is in clock region X0Y1 and returns `BUFIO_2_REGION=LB`.

### Channel 2

R16 is `IO_L14P_T2_SRCC_14`. Every proposed data pin is Bank 14, T2, clock region X0Y0 and `BUFIO_2_REGION=LB`. T15 is `IO_L13N_T2_MRCC_14`; replacing it with U15 (`IO_L17P_T2_A14_D30_14`) creates the same complete L15-L18 pattern as CH1.

The designer's “T0-T3” language maps to the `Tn` token in the exact 7-series `PIN_FUNC` name. Vivado 2025.2 does not return a modern package-pin bytegroup object for these 7-series pins. Therefore this audit reports exact T2-name grouping plus bank, clock region and `BUFIO_2_REGION`, rather than inventing a separate bytegroup index. Both buses are optimally confined to only T2.

## Current versus proposed mapping

| Signal | Current accepted | Proposed | Conflict/action |
|---|---|---|---|
| VCLK1 | E13 | E16 | migrate after acceptance |
| VDO1[0:7] | A14 B14 A15 B15 B16 A17 B17 C18 | B16 C16 A17 B17 C17 C18 E17 D18 | four balls reused under provisional bit permutation |
| VCLK2 | absent | R16 | new top port/constraint later |
| VDO2[0:7] | absent | R18 T15 T18 T17 U17 V17 U16 V16 | T17/T18 currently I2C; U/V pins currently MPP |
| IRQ | absent; historical R17 removed | K17 | new port/consumer later |
| RST | R17 | L18 | migrate later |
| SDA | T18 | M17 | migrate later |
| SCL | T17 | N17 | migrate later |
| FPGA 27 MHz | absent | C13 | `PLIO-9`; replace with D13 before PCB routing |

No proposed pin collides with active PCIe D6/D5, C8, G4/G3, B2/B1; dedicated JTAG; `sys_clk`; or `sys_rst_n`. The current top has no CH2, IRQ or 27 MHz port, so this audit cannot and does not promote the pin plan into source.

## Capture architecture

The preferred topology for each channel is:

`VCLK -> IBUF -> BUFIO -> IDDR/ISERDESE2`

with a parallel clock branch:

`VCLK -> IBUF -> BUFR -> regional/divided fabric clock or ISERDESE2 CLKDIV`

and optional data deskew:

`VDO -> IBUF -> IDELAYE2 -> IDDR/ISERDESE2`

Vivado exposes a matching ILOGIC coordinate with `ILOGICE2/ISERDESE2` alternatives and a matching IDELAYE2 coordinate for every proposed video IOB. Direct isolated primitive placement verifies those resource types. The full sandbox assigned every proposed LOC/IOSTANDARD and synthesized the two BUFIO/BUFR/IDDR paths with zero warnings/errors, then correctly stopped at placement because C13/BUFG violates `PLIO-9`. The D13 correction variant is archived under `raw/placement`.

For the stated two-sample DDR mode, IDDR is the simplest choice. ISERDESE2 remains available for future wordization. Both require explicit clocking and CDC design; no DDR RTL is implemented here.

## IDELAYCTRL requirement

If data IDELAYE2 elements are used, plan separate physical calibration domains for CH1 (`IDELAYCTRL_X0Y1`) and CH2 (`IDELAYCTRL_X0Y0`), normally with separate `IODELAY_GROUP` names. They may share a clean reference. The installed 7-series model accepts 190-210, 290-310 or 390-410 MHz `REFCLK_FREQUENCY` windows; direct 27 MHz is invalid. A later MMCM/PLL may derive a stable 200 MHz reference, subject to normal VCO/divider, lock and IDELAYCTRL reset/RDY sequencing.

## 27 MHz reference and fanout

C13 is Bank 15 `IO_L11N_T1_SRCC_15`, clock region X0Y1, `BUFIO_2_REGION=LT`, but it is the N-side of the clock-capable pair. In single-ended mode only the P-side may drive the clock buffer. The exact `C13 -> IBUF -> BUFG` sandbox failed `place_design` with `PLIO-9`; fabric-clock overrides are not accepted as a PCB plan. Move the oscillator to D13 (`IO_L11P_T1_SRCC_15`). The D13-only variant fully placed and routed with zero DRC checks and zero routing errors. E13 is a valid but less resource-efficient MRCC second choice after VCLK1 moves.

The oscillator must be specified for two CMOS loads (NVP SYS_CLK and corrected FPGA D13), trace capacitance and both devices' VIH/VIL. Review topology, branch damping/SI, Bank 15 voltage, oscillator startup and unpowered-device back-power risk. A source-series value is an SI decision; this audit does not prescribe one.

## Controls, MPP and J18

K17/L18/M17/N17 are legal Bank 14 LVCMOS user I/O. K17 and L18 form a differential-capable pair but are legal as independent single-ended IRQ/RST. SDA/SCL can use IOBUF with data fixed at 0 and tri-state for release, with external pull-ups to a compatible rail. N17 is DQS-capable; N18 is an optional ordinary-I/O alternative if preserving that strobe pair matters.

Repository-wide analysis classifies MPP1-MPP4 as unused: `nvp_mpp` is only a top input and XDC LOC set. Physical removal is safe with the constraint that stale ports/LOCs must be retired in the later accepted change before CH2 owns those pins.

J18 is unassigned Bank 14 `IO_L3P_T0_DQS_PUDC_B_14`. Because PUDC_B is a configuration-stage special function and the repository has no schematic net/intent, a 1 kOhm pull-down is not approved. Resolve the net, configuration mode, desired level and contention current first.

## VCCO, special functions and differential pairs

Every affected pin is in HR Bank 14 or 15, where LVCMOS33 is architecturally legal. The PCB condition is explicit: `VCCO_14=3.3 V` and `VCCO_15=3.3 V`. Current accepted LVCMOS33 assignments prove Vivado legality but do not replace schematic rail verification.

Several selected pins also carry configuration-mode address/data/control names (`ADV_B`, `RDWR_B`, `DOUT_CSO_B`, `CSI_B`, Dxx/Axx). They are legal user I/O after configuration. The codec/oscillator/pull-up sequencing must avoid configuration interference and unpowered-bank injection.

All selected I/O are P or N members of differential-capable pairs. Single-ended use is legal. Occupying one or both halves only prevents that pair from simultaneously being used as a differential input/output; differential capability is not a blocker.

## Bit-order flexibility

Arbitrary physical-to-logical VDO permutation is acceptable. All data bits use equivalent local T2 ILOGIC paths, so a simple RTL/XDC logical mapping does not introduce a timing penalty of concern. The clock pins and bank/group boundaries are the placement-critical elements.

## Timing boundary

The pin architecture is strong for 148.5 MHz SDR and capable of 148.5 MHz dual-edge operation. `TIMING_RISK=MEDIUM` reflects the absent NVP output timing, PCB skew/stack-up, input-delay constraints, IDELAY calibration plan and routed final design. The accepted statement is `PIN_FEASIBILITY_PASS`; this report makes no routed timing-closure claim.

## Governance and non-action proof

The source checkout remained clean at `be94f88ee8d179f12928ab791bdae27c22cd1762` before and after read-only inspection. No PCB, RTL, XDC, project, SSOT, G-track or R-track file was changed. No FPGA, JTAG, PCIe/DUT or programmer access occurred. No product bitstream was created.

No SSOT change is required yet. After Owner acceptance, a later governed META/source update must capture the final pin table, U15/T15 decision, voltage plan, 27 MHz clock, MPP retirement, J18 decision and routed timing evidence.
