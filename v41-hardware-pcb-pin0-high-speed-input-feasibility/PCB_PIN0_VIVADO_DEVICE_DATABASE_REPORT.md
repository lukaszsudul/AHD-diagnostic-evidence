# PCB-PIN-0 Vivado Device Database Report

## Tool and part identity

- Vivado: 2025.2, 64-bit, build 6299465
- Requested part spelling: `xc7a35t-csg325-2`
- Vivado canonical current-project part: `xc7a35tcsg325-2`
- Loaded device/package/speed: xc7a35t / csg325 / -2
- Package database version in accepted report: FINAL 2014-03-07
- Audit mode: isolated in-memory/temp project; no active-project save; no bitstream; no hardware access

Vivado accepted the requested hyphenated spelling and normalized it to the exact canonical part string `xc7a35tcsg325-2`. No A15T, other package, or other speed grade was used.

## Database query

The archived `raw/query_device.tcl` executed the equivalent of:

```tcl
set part_name xc7a35t-csg325-2
create_project -in_memory -part $part_name pcb_pin0_device_query
read_verilog dummy.v
synth_design -top dummy -part $part_name

set pobj [get_package_pins E16]
get_property PART [current_project]
report_property $pobj
get_sites -of_objects $pobj
get_iobanks -of_objects $pobj
get_bels -of_objects [get_sites -of_objects $pobj]
```

For every requested package pin, the script enumerated all package-pin, IOB-site and I/O-bank properties. It also wrote the full package pin inventory for alternative selection.

## Returned identifiers

| Pin | Exact `PIN_FUNC` | Site | Bank | Clock region | `BUFIO_2_REGION` | Clock capable | Pair |
|---|---|---|---:|---|---|---:|---|
| E16 | `IO_L14P_T2_SRCC_15` | `IOB_X0Y72` | 15 | X0Y1 | LB | 1 | D16 |
| B16 | `IO_L15P_T2_DQS_15` | `IOB_X0Y70` | 15 | X0Y1 | LB | 0 | A17 |
| C16 | `IO_L16P_T2_A28_15` | `IOB_X0Y68` | 15 | X0Y1 | LB | 0 | B17 |
| A17 | `IO_L15N_T2_DQS_ADV_B_15` | `IOB_X0Y69` | 15 | X0Y1 | LB | 0 | B16 |
| B17 | `IO_L16N_T2_A27_15` | `IOB_X0Y67` | 15 | X0Y1 | LB | 0 | C16 |
| C17 | `IO_L18P_T2_A24_15` | `IOB_X0Y64` | 15 | X0Y1 | LB | 0 | C18 |
| C18 | `IO_L18N_T2_A23_15` | `IOB_X0Y63` | 15 | X0Y1 | LB | 0 | C17 |
| E17 | `IO_L17P_T2_A26_15` | `IOB_X0Y66` | 15 | X0Y1 | LB | 0 | D18 |
| D18 | `IO_L17N_T2_A25_15` | `IOB_X0Y65` | 15 | X0Y1 | LB | 0 | E17 |
| R16 | `IO_L14P_T2_SRCC_14` | `IOB_X0Y22` | 14 | X0Y0 | LB | 1 | R17 |
| R18 | `IO_L15P_T2_DQS_RDWR_B_14` | `IOB_X0Y20` | 14 | X0Y0 | LB | 0 | T18 |
| T15 | `IO_L13N_T2_MRCC_14` | `IOB_X0Y23` | 14 | X0Y0 | LB | 1 | T14 |
| T18 | `IO_L15N_T2_DQS_DOUT_CSO_B_14` | `IOB_X0Y19` | 14 | X0Y0 | LB | 0 | R18 |
| T17 | `IO_L16P_T2_CSI_B_14` | `IOB_X0Y18` | 14 | X0Y0 | LB | 0 | U17 |
| U17 | `IO_L16N_T2_A15_D31_14` | `IOB_X0Y17` | 14 | X0Y0 | LB | 0 | T17 |
| V17 | `IO_L18N_T2_A11_D27_14` | `IOB_X0Y13` | 14 | X0Y0 | LB | 0 | V16 |
| U16 | `IO_L17N_T2_A13_D29_14` | `IOB_X0Y15` | 14 | X0Y0 | LB | 0 | U15 |
| V16 | `IO_L18P_T2_A12_D28_14` | `IOB_X0Y14` | 14 | X0Y0 | LB | 0 | V17 |
| K17 | `IO_L4P_T0_D04_14` | `IOB_X0Y42` | 14 | X0Y0 | LB | 0 | L18 |
| L18 | `IO_L4N_T0_D05_14` | `IOB_X0Y41` | 14 | X0Y0 | LB | 0 | K17 |
| M17 | `IO_L7N_T1_D10_14` | `IOB_X0Y35` | 14 | X0Y0 | LB | 0 | M16 |
| N17 | `IO_L9N_T1_DQS_D13_14` | `IOB_X0Y31` | 14 | X0Y0 | LB | 0 | N16 |
| C13 | `IO_L11N_T1_SRCC_15` | `IOB_X0Y77` | 15 | X0Y1 | LT | 1 | D13 |
| J18 | `IO_L3P_T0_DQS_PUDC_B_14` | `IOB_X0Y44` | 14 | X0Y0 | LB | 0 | K18 |

All returned `IS_BONDED=1` and `IS_GENERAL_PURPOSE=1`. All are differential-capable IOB halves; single-ended use is legal. Banks 14 and 15 return `BANK_TYPE=BT_HIGH_RANGE`. E16, R16, T15 and C13 return `IS_CLK_CAPABLE=1`; only E16/R16/C13 are proposed clocks, while T15 is proposed as data.

Vivado reports `IS_GLOBAL_CLK=0` for these SRCC/MRCC package pins. This property distinguishes them from a global-labelled package object; the placement sandbox determines whether each proposed single-ended side can legally drive a clock buffer. E16 and R16 pass. C13 is an N-side CCIO and fails that check with `PLIO-9`.

## Alternative identifiers

The full database inventory returns:

- D13: `IO_L11P_T1_SRCC_15`, `IOB_X0Y78`, Bank 15, X0Y1, clock capable, P companion of C13.
- U15: `IO_L17P_T2_A14_D30_14`, `IOB_X0Y16`, Bank 14, X0Y0, non-clock, companion U16.
- N18: `IO_L10P_T1_D14_14`, `IOB_X0Y30`, Bank 14, X0Y0, non-clock.
- E13: `IO_L12P_T1_MRCC_15`, `IOB_X0Y76`, Bank 15, X0Y1, clock capable.

These identifiers support the ranked alternatives report.

## T0/T1/T2 interpretation

The `T0`, `T1`, `T2` text is part of AMD/Xilinx's exact `PIN_FUNC` identifier and denotes the I/O byte group within the bank. Vivado does not present the designer's phrase “T0-T3” as an independent package-pin class in `report_io`; the auditable classification is the `IO_Lxx[PN]_Tn...` suffix together with bank, clock region and `BUFIO_2_REGION`.

The result is stronger than merely spreading each bus among T0-T3:

- CH1 clock and eight data bits are all Bank 15/X0Y1/T2/LB.
- CH2 clock and eight data bits are all Bank 14/X0Y0/T2/LB.

## Constraint/placement sandbox

The isolated sandbox source is archived under `raw/placement/`. It defines only dummy ports/primitives and applies every proposed LOC plus `LVCMOS33`, then exercises:

```tcl
synth_design -top pin_feasibility_top -part xc7a35t-csg325-2
report_io
opt_design
place_design
report_drc
route_design -directive Quick
report_route_status
report_clock_utilization
report_drc
```

The test topology is two independent `IBUF -> BUFIO/BUFR -> IDDR` input paths and `C13 -> IBUF -> BUFG`, plus the proposed control I/O. No product source, product constraint, product checkpoint or bitstream is used.

The first attempt is retained as `FAILED_ATTEMPT_IDDR_CB.log`; it failed during RTL elaboration because the dummy IDDR incorrectly named a nonexistent `CB` port. After that harness-only correction, synthesis completed with 16 IDDR, two BUFIO, two BUFR and one BUFG, with zero warnings/errors. Placement then stopped on the actual proposed pin defect:

```text
ERROR: [DRC PLIO-9] ... clock source ... LOCed to a N-Type CCIO: ref27
For a single-ended input in a CCIO pair, only the P-side can be used to drive a clock buffer.
```

The source was C13. The controlled D13 variant changes only REF27 from C13 to its P-side companion D13. It completed placement and routing, both post-place and post-route DRC reports contain zero checks, and the route-status report shows 73/73 routable nets fully routed with zero routing errors. The result is in `raw/placement/D13_SANDBOX_RESULT.txt`.

## Raw evidence

- `raw/EXACT_PART.txt`
- `raw/PIN_OBJECT_SUMMARY.tsv`
- `raw/PIN_OBJECT_ALL_PROPERTIES.txt`
- `raw/ALL_USER_PACKAGE_PINS.tsv`
- `raw/query_device.tcl`
- `raw/CURRENT_ACCEPTED_IO_REPORT.rpt`
- `raw/placement/*`
