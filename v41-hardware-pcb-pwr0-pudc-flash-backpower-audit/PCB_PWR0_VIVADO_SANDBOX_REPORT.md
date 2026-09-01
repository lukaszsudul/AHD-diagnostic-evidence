# PCB-PWR-0 Vivado Sandbox Report

## Purpose

The isolated sandbox checks the exact device/package, configuration-voltage properties, D13/A14 I/O legality, relevant configuration-pin identities, and whether the tool exposes any PUDC_B design property or DRC objection. It does not model external resistor straps, Flash power, receiver clamps, regulator ramps, or powered-off pad current.

## Isolation and inputs

- Sandbox directory: outside `C:\FPGA\FPGA_AHD`
- Vivado: 2025.2
- Exact requested part: `xc7a35tcsg325-2`
- HDL: two-port D13-to-A14 connectivity probe
- XDC: D13/A14 LVCMOS33, 27 MHz clock, `CONFIG_VOLTAGE=3.3`, `CFGBVS=VCCO`
- Product SPI width: deliberately not set; current A35T width remains `UNRESOLVED`
- Bitstream command: absent
- Product RTL/XDC read or modified by sandbox: no

The published v2 Tcl/XDC/HDL exactly match the v2 log/journal/reports. A discarded first run that used a sandbox-only SPI-width property is not published and is not product evidence.

## Exact device result

```
PART_NAME=xc7a35tcsg325-2
PART_DEVICE=xc7a35t
PART_PACKAGE=csg325
PART_SPEED=-2
PART_FAMILY=artix7
PART_ARCHITECTURE=artix7
```

Configuration properties read back as:

```
CONFIG_VOLTAGE=3.3
CFGBVS=VCCO
CURRENT_A35T_PRODUCT_SPI_WIDTH=UNRESOLVED
PUDC_DESIGN_PROPERTIES=
```

The empty PUDC property list is significant: the external J18 strap has no Vivado design-property representation in this probe.

## Exact configuration-pin result

| Pin | Function | Bank |
|---|---|---|
| E8 | CCLK_0 | 0 |
| F12 | DONE_0 | 0 |
| F13 | M2_0 | 0 |
| P10 | PROGRAM_B_0 | 0 |
| R11 | M1_0 | 0 |
| R12 | M0_0 | 0 |
| T10 | INIT_B_0 | 0 |
| J15 | IO_L2P_T0_D02_14 | 14 |
| J16 | IO_L2N_T0_D03_14 | 14 |
| J18 | IO_L3P_T0_DQS_PUDC_B_14 | 14 |
| K16 | IO_L1P_T0_D00_MOSI_14 | 14 |
| L15 | IO_L6P_T0_FCS_B_14 | 14 |
| L17 | IO_L1N_T0_D01_DIN_14 | 14 |
| T18 | IO_L15N_T2_DQS_DOUT_CSO_B_14 | 14 |

## Implementation/DRC result

- synthesis: successful;
- optimization: successful;
- placement command: successful;
- DRC error count: 0;
- DRC critical-warning count: 0;
- DRC warning count: 0;
- `NO_WRITE_BITSTREAM_COMMAND=TRUE`.

Synthesis warns that the intentionally minimal probe has an empty top module even though IBUF/OBUF cells and both constrained I/O appear in the I/O report. Placement correspondingly reports no remaining placeable instance and no critical timing terminals. These scope warnings are disclosed; they are not PUDC/configuration DRC objections.

## Classification

`VIVADO_DRC_NO_OBJECTION = PASS`

`PUDC_HIGH_VIVADO_LEGALITY = NOT_PROVEN`

The distinction is intentional. No tool-level objection exists for the exact part and tested properties, but Vivado cannot see whether J18 is strapped HIGH, whether both resistor options are stuffed, or whether Flash/NVP currents violate powered-off limits. The sandbox therefore supports the architecture review without claiming hardware proof.

## Raw integrity

| File | SHA-256 |
|---|---|
| `pudc_high_legality.v` | `48BA2F702A96E24FB92BF39BD2EA0B34C996E3DB4DC77FDC73362450568D5D72` |
| `pudc_high_legality.xdc` | `49FD4693E918911880008968692B5219ECE73AACE878B1161A7008B5FEEAF649` |
| `query_pudc_high_legality.tcl` | `E671BAFDE5AA6474BD26704C2C2225E17218E5060371EE43DFCF8C34BD1DCE71` |
| `pwr0_v2_vivado.log` | `AB846008EF5245F1FD8742322E4674C1F394D0EB1D20B430946392190AC86509` |
| `pwr0_v2_vivado.jou` | `721097334A41B47D7B47FFF26F578B777921209B39A954AA19D7867E275BBDA4` |
| `pwr0_v2_report_io.rpt` | `C3C40FAFABCE1B75BD2DEBAEC2A0A604768F75E4B6FDE397760A4934EF2362E9` |
| `pwr0_v2_report_drc.rpt` | `305002A202332F17139AEF2B108B53ADDF8DCA2D8996C8F685EAE1E7ECCFD275` |
