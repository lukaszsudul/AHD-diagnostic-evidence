# PCB-PWR-0 Flash Boot with PUDC_B HIGH

## Classification

`PUDC_HIGH_FLASH_BOOT = SUPPORTED_WITH_EXTERNAL_PULL_REQUIREMENTS`

The locally published UG470 Table 2-4 transcription defines PUDC_B HIGH as a supported 7-series strap state that disables global weak pulls on ordinary/inactive SelectIO. Exact pin classification plus that SelectIO-specific wording support the engineering inference that HIGH does not disable the Master SPI engine or pins active in that mode. Reliable boot still depends on explicit board defaults, correct rail sequencing, and the exact Flash protocol.

This is an architecture classification derived from the prior citable Table 2-4 transcription plus exact pin classifications; it is not a retained HIGH-strapped AHD cold-boot result. `FINAL_AHD_PUDC_HIGH_COLD_BOOT = REQUIRES_FIRST_BOARD_TEST_OR_EQUIVALENT_DIRECT_EVIDENCE`.

The local archive proves historical `M[2:0]=001` Master SPI with an S25FL064L. A historical A15T build selected x4, and its cfgmem Program/Verify operation succeeded; no retained autonomous cold-boot result was found. The active A35T source has no `SPI_BUSWIDTH` property, so the current width is `UNRESOLVED`. The table does not assume x1, x2, or x4 for the current board.

For the exact A35T package, Bank-0 CCLK, DONE, INIT_B, PROGRAM_B, M[2:0], and CFGBVS are dedicated configuration pins and do not become ordinary SelectIO after startup. Bank-14 FCS_B, D00-D03, DOUT_CSO_B, and PUDC_B are dual-purpose SelectIO/configuration pins; after startup/EOS they can become user I/O only as allowed by the selected mode, persistence/reservation settings, and board architecture.

## Signal-by-signal review

“Archived board” means the 2020 Rev 0.1 A15T/CSG325 netlist. It is architecture provenance, not final A35T schematic proof. Package functions listed below were checked for the exact `xc7a35tcsg325-2`.

| Signal | Exact A35T CSG325 pin / type | Configuration behavior | External defined state | Archived board implementation | PUDC_B effect | PUDC_B=HIGH boot risk |
|---|---|---|---|---|---|---|
| CFGBVS | E12, dedicated selection pin | Selects configuration-bank voltage convention with VCCO_0 | Must match the actual VCCO_0/config-voltage architecture | E12 tied to switched `Vcco`; active XDC sets `CONFIG_VOLTAGE=3.3`, `CFGBVS=VCCO` | None | None if rail relationship is correct; final schematic must confirm |
| M0 | R12, dedicated mode | Sampled as part of M[2:0] | Logic 1 for 001 | Direct to switched `Vcco` | None | None from PUDC; must be valid when sampled |
| M1 | R11, dedicated mode | Sampled as part of M[2:0] | Logic 0 for 001 | Direct to GND | None | None from PUDC |
| M2 | F13, dedicated mode | Sampled as part of M[2:0] | Logic 0 for 001 | 1.5 kOhm to GND plus FTDI-controlled buffer path | None | External override reset state can change mode; confirm it cannot overpower the default unintentionally |
| PROGRAM_B | P10, dedicated active-low reset | Falling edge resets configuration; rising release permits configuration | Defined high when not intentionally resetting | 4.7 kOhm to switched `Vcco` | None | None from PUDC; verify released only after its reference rail is valid |
| INIT_B | T10, dedicated/bidirectional status | Configuration initialization/error status per UG470 | Follow UG470 topology and monitoring requirements | 4.7 kOhm to switched `Vcco` | None | None from PUDC; final pull/monitor topology must be checked |
| DONE | F12, dedicated status | Indicates successful configuration/startup; exact drive/pull mode follows UG470 and bitstream settings | Follow UG470 and downstream receiver requirements | Test point and FTDI-buffer input; no pull seen | None | PUDC HIGH does not remove a dedicated DONE behavior, but final external-pull requirement remains to be confirmed |
| CCLK | E8, dedicated configuration clock | FPGA drives in Master SPI | No generic data pull invented; control ringing with valid series element | 22 ohm series to Flash CLK | None | No PUDC-induced risk |
| FCS_B / Flash CS_B | L15, Bank 14 dual-purpose | FPGA drives Flash chip select in Master SPI | Flash must remain deselected before the configuration engine validly drives; high default referenced to an electrically compatible rail or enforced by isolation | 4.7 kOhm to permanent `V_3.3V`, then 22 ohm series to L15 | Active configuration behavior is not replaced by global pulls | Boot default is present, but this exact implementation creates a powered-Flash-to-unpowered-Bank-14 injection path |
| D00 / MOSI / Flash Q0 | K16, Bank 14 dual-purpose | FPGA output in serial modes; data role depends on width | No generic pull required if the configuration engine drives as specified | 22 ohm series, no external pull seen | Active role not replaced by global pulls | No risk solely from disabling global pulls; confirm Flash input behavior while FPGA is off |
| D01 / DIN / Flash Q1 | L17, Bank 14 dual-purpose | FPGA input from selected Flash | No generic pull required if Flash CS is guaranteed high until valid selection and Flash drives only when selected | 22 ohm series, no external pull seen | Active role not replaced by global pulls | Depends on Flash powered-off/standby/CS behavior; verify no drive before VCCO_14 is valid |
| D02 / Flash Q2 or WP_B | J15, Bank 14 dual-purpose | Data in widths that use D02; otherwise Flash control state is part-specific | Preserve a valid Flash WP/data state for the selected mode | 4.7 kOhm to permanent `V_3.3V` plus 22 ohm series | If inactive, LOW would add an FPGA pull; HIGH removes only that internal pull, not the board pull | Boot bias exists, but permanent pull causes a direct injection candidate while VCCO_14 is off |
| D03 / Flash Q3 or HOLD_B/RESET_B | J16, Bank 14 dual-purpose | Data in widths that use D03; otherwise Flash control state is part-specific | Preserve a valid Flash hold/reset/data state for the exact part and mode | 4.7 kOhm to permanent `V_3.3V` plus 22 ohm series | Same as D02 | Same injection issue as D02; exact function must be confirmed from the retained Flash part |
| DOUT_CSO_B | T18, Bank 14 dual-purpose | Mode/daisy-chain-dependent configuration output; exact Master-SPI state requires UG470 mode-table confirmation | Do not attach an off-domain control until its configuration behavior is closed | Active source currently assigns T18 to NVP SDA; PCB-PIN-1 proposed SDA=M17 instead | HIGH removes only global pulls when the pin is inactive | `UNRESOLVED` for a T18 user connection; use the non-configuration-pin proposed mapping unless explicitly proven |
| PUDC_B | J18, Bank 14 configuration control / later user-capable pin | Selects global SelectIO pull policy during power-up/configuration | Proposed HIGH to actual VCCO_14 through one mutually exclusive <=1 kOhm option | Old archive instead uses J18 as VDO2_0 and therefore proves no strap | It is the policy input | Final routing must reserve and strap J18; do not retain the old VDO assignment |

## What must be externally defined with HIGH

The board must define only states that are actually required; no blanket pull network is recommended.

1. M[2:0] must be a valid, uncontested `001` at the sampling interval. The FTDI M2 override must have a proven inactive reset state.
2. PROGRAM_B must have the UG470-required release pull to VCCO_0 and no obsolete FPGA feedback loop.
3. Flash CS_B must be high before the FPGA can validly select the Flash.
4. DQ2/WP_B and DQ3/HOLD_B/RESET_B must have the states required by the exact Flash part and selected bus width.
5. INIT_B and DONE must follow the exact UG470 reference topology and downstream receiver voltage domains.
6. Any configuration multifunction pin reused as application I/O must be reviewed for the selected mode. T18 is explicitly not cleared by this audit.

CCLK and D00 are actively driven configuration outputs; D01 is the selected-Flash return path. This audit does not invent generic pulls for them.

## Why HIGH does not mean “Flash safe”

The PUDC policy controls FPGA-internal weak pulls. It cannot remove external 4.7 kOhm pulls powered from permanent PCIe 3.3 V, cannot power down the Flash, and cannot establish A35T powered-off pad tolerance. The Flash boot-default question and the VCCO back-power question must therefore be closed together, but they are not the same mechanism.

## Required final confirmations

- routing-final A35T schematic and BOM retain or change the archived S25FL064L topology;
- selected SPI width and corresponding bitstream property;
- M2 override reset behavior;
- Flash CS/Q1/Q2/Q3 behavior when Flash is powered and FPGA VCCO_14 is absent;
- full UG470 text for INIT_B/DONE and original-PDF/full-caption confirmation of the secondary Figure 2-14 interpretation;
- AMD powered-off/Ioff/injection specification for the applicable Bank-14 configuration pads; and
- cold-boot testing with the proposed HIGH population.
