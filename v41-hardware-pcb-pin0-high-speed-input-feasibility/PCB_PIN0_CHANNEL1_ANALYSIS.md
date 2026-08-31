# PCB-PIN-0 Channel 1 Analysis

## Decision

- `PIN_SET_VALID = YES`
- `CH1_BANK_LOCALITY = PASS`
- `CH1_SRCC_REACHABILITY = PASS`
- `CH1_DDR_FEASIBILITY = PASS`
- `CH1_IDELAY_FEASIBILITY = PASS`
- `CH1_148M5_SDR = STRONGLY_RECOMMENDED`
- `CH1_DDR_ARCHITECTURE = SUPPORTED_WITH_CONSTRAINTS`
- `PCB_ROUTING_RECOMMENDATION = APPROVE_FOR_PCB_ROUTING`

These are pin-architecture findings, not routed timing closure.

## Exact locality

| Role | Pin | Vivado package function | IOB site | Bank | Clock region | Pin group | BUFIO subregion |
|---|---|---|---|---:|---|---|---|
| VCLK1 | E16 | `IO_L14P_T2_SRCC_15` | `IOB_X0Y72` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[0] | B16 | `IO_L15P_T2_DQS_15` | `IOB_X0Y70` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[1] | C16 | `IO_L16P_T2_A28_15` | `IOB_X0Y68` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[2] | A17 | `IO_L15N_T2_DQS_ADV_B_15` | `IOB_X0Y69` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[3] | B17 | `IO_L16N_T2_A27_15` | `IOB_X0Y67` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[4] | C17 | `IO_L18P_T2_A24_15` | `IOB_X0Y64` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[5] | C18 | `IO_L18N_T2_A23_15` | `IOB_X0Y63` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[6] | E17 | `IO_L17P_T2_A26_15` | `IOB_X0Y66` | 15 | `X0Y1` | T2 | `LB` |
| VDO1[7] | D18 | `IO_L17N_T2_A25_15` | `IOB_X0Y65` | 15 | `X0Y1` | T2 | `LB` |

The eight data pins are the complete L15/L16/L17/L18 P/N set. This is an excellent physical grouping: one HR bank, one clock region, one T2 byte group, and the same Vivado `BUFIO_2_REGION=LB` as E16. The proposed clock is the adjacent L14P T2 SRCC input.

## Clocking and capture resources

E16 is bonded, general-purpose user I/O and clock capable (`IS_CLK_CAPABLE=1`). It is SRCC, not MRCC and not a global-clock-labelled package pin. That is the desired class for a local source-synchronous interface. Its dedicated local route can feed BUFIO for the Bank 15/X0Y1 ILOGIC sites. A BUFR branch can provide a regional/fabric or divided clock. A BUFG branch is optional when the sampled words must enter a wider fabric domain; use a defined clock-domain boundary rather than treating the clocks as interchangeable.

Each data pin has an ILOGIC input path supporting IDDR and ISERDESE2, and an input IODELAY path supporting IDELAYE2. The recommended receive path is:

`VCLK1 -> IBUF -> BUFIO -> IDDR/ISERDESE2 CLK`

with:

`VCLK1 -> IBUF -> BUFR -> regional fabric / ISERDESE2 CLKDIV`

and, when deskew is needed:

`VDO1 -> IBUF -> IDELAYE2 -> IDDR/ISERDESE2`

At a two-bit DDR ratio, IDDR is the simplest architecture. ISERDESE2 remains available for later wordization or wider deserialization.

## Electrical and timing conditions

- Bank 15 is a high-range bank. `LVCMOS33` is legal only when PCB `VCCO_15` is 3.3 V; that rail value must be confirmed in the new schematic/power plan.
- Add real input-delay constraints from the NVP clock-to-data specification and PCB skew. The current 6.734 ns clock constraint alone is not an interface timing budget.
- If IDELAYE2 is used, instantiate/calibrate an IDELAYCTRL for the applicable region/group from a compliant reference (normally 200 MHz). The 27 MHz oscillator is not a legal direct IDELAYCTRL reference.
- A17 has the configuration-time `ADV_B` alternate function. It is legal user I/O after configuration, but codec drive/startup behavior must respect FPGA configuration and bank power sequencing.
- P/N-labelled pins are legal as independent single-ended LVCMOS inputs. A used half can no longer participate in a differential pair with its companion.

## Bit order

The data pins may be permuted freely at PCB routing time. The RTL can map physical pins to logical `VDO1[n]` without a timing penalty of concern because all eight pins use equivalent local T2 ILOGIC paths. Preserve the clock pin and the complete bank/group locality.

