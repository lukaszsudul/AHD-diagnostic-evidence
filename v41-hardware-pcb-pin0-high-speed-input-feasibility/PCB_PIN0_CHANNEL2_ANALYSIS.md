# PCB-PIN-0 Channel 2 Analysis

## Decision

- `PIN_SET_VALID = YES`
- `CH2_BANK_LOCALITY = PASS`
- `CH2_SRCC_REACHABILITY = PASS`
- `CH2_DDR_FEASIBILITY = PASS`
- `CH2_IDELAY_FEASIBILITY = PASS`
- `CH2_148M5_SDR = STRONGLY_RECOMMENDED`
- `CH2_DDR_ARCHITECTURE = SUPPORTED_WITH_CONSTRAINTS`
- `PCB_ROUTING_RECOMMENDATION = APPROVE_WITH_CHANGES`

The proposed set is legal and locally clockable. The requested change is the material resource-preservation improvement `T15 -> U15` for the provisional data bit currently on T15. These are pin-feasibility findings, not routed timing closure.

## Exact locality

| Role | Pin | Vivado package function | IOB site | Bank | Clock region | Pin group | BUFIO subregion |
|---|---|---|---|---:|---|---|---|
| VCLK2 | R16 | `IO_L14P_T2_SRCC_14` | `IOB_X0Y22` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[0] | R18 | `IO_L15P_T2_DQS_RDWR_B_14` | `IOB_X0Y20` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[1] | T15 | `IO_L13N_T2_MRCC_14` | `IOB_X0Y23` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[2] | T18 | `IO_L15N_T2_DQS_DOUT_CSO_B_14` | `IOB_X0Y19` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[3] | T17 | `IO_L16P_T2_CSI_B_14` | `IOB_X0Y18` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[4] | U17 | `IO_L16N_T2_A15_D31_14` | `IOB_X0Y17` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[5] | V17 | `IO_L18N_T2_A11_D27_14` | `IOB_X0Y13` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[6] | U16 | `IO_L17N_T2_A13_D29_14` | `IOB_X0Y15` | 14 | `X0Y0` | T2 | `LB` |
| VDO2[7] | V16 | `IO_L18P_T2_A12_D28_14` | `IOB_X0Y14` | 14 | `X0Y0` | T2 | `LB` |

All nine proposed channel pins are in HR Bank 14, clock region X0Y0, T2, and `BUFIO_2_REGION=LB`. R16 is therefore a valid local source-synchronous SRCC for all eight data ILOGIC sites.

The set is slightly suboptimal because T15 is the N half of the L13 MRCC pair. `U15` is the unused `IO_L17P_T2_A14_D30_14` companion of proposed U16. Replacing T15 with U15 makes the data bus the complete L15/L16/L17/L18 P/N set and leaves T14/T15 available as an MRCC differential pair. T15 remains legal as single-ended data if PCB routing makes the change impractical.

## Clocking and capture resources

R16 is bonded general-purpose user I/O and SRCC clock capable. The preferred topology is:

`VCLK2 -> IBUF -> BUFIO -> IDDR/ISERDESE2 CLK`

plus:

`VCLK2 -> IBUF -> BUFR -> regional fabric / ISERDESE2 CLKDIV`

and, when deskew is needed:

`VDO2 -> IBUF -> IDELAYE2 -> IDDR/ISERDESE2`

All data paths have local ILOGIC and input-delay resources. IDDR is preferred for two-bit DDR; ISERDESE2 is available for future deserialization.

## Existing-project collisions

The proposed CH2 pins do not collide with PCIe, JTAG, dedicated configuration pins, `sys_clk`, or `sys_rst_n`. They do collide intentionally with accepted NVP assignments:

- T17: current `nvp_scl`
- T18: current `nvp_sda`
- V16/V17/U16/U17: current `nvp_mpp[0:3]`

The current top has no VCLK2/VDO2 ports. Owner acceptance must therefore be followed by a coordinated RTL/XDC update; this audit makes no such change. Repository analysis found `nvp_mpp` has no synthesizable consumer, so removing those four PCB connections breaks no current product function, subject to retiring the stale ports/LOCs in that later change.

## Electrical and timing conditions

- `LVCMOS33` requires PCB `VCCO_14 = 3.3 V`.
- Add NVP output and PCB-skew-derived input-delay constraints before timing sign-off.
- IDELAYE2 use requires a calibrated IDELAYCTRL group/region with a compliant reference, not direct 27 MHz.
- Several Bank 14 pins have configuration-mode alternate functions (`RDWR_B`, `DOUT_CSO_B`, `CSI_B`, address/data). They are legal user I/O after configuration; ensure the codec does not cause configuration-stage contention or back-powering.
- P/N members are legal single-ended. The corresponding differential use is unavailable while either half is assigned single-ended.

## Bit order

Arbitrary physical-to-logical bit permutation is acceptable. No data bit has a unique semantic placement requirement; keep all eight in Bank 14/T2 and preferably use U15 instead of T15.

