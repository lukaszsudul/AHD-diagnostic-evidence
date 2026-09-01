# PCB-PWR-0 Configuration-Bank Power Sequence

## Configuration-bank map

| Bank / rail | Relevant signals | Evidence-backed voltage relationship | Exposure before rail valid |
|---|---|---|---|
| Bank 0 / VCCO_0 | E8 CCLK, F12 DONE, F13 M2, P10 PROGRAM_B, R11 M1, R12 M0, T10 INIT_B; E12 CFGBVS | Active XDC: `CONFIG_VOLTAGE=3.3`, `CFGBVS=VCCO`. Archive: VCCO_0 and CFGBVS on switched 3.3 V `Vcco`. | Mode ties and PROGRAM_B/INIT_B pulls reference switched Vcco in archive; no permanent 3.3 V pull shown on these pins. Final schematic required. |
| Bank 14 / VCCO_14 | J18 PUDC_B; L15 FCS_B; K16 D00; L17 D01; J15 D02; J16 D03; T18 DOUT_CSO_B; proposed controls | Archive: VCCO_14 on same switched 3.3 V `Vcco`. | Permanent Flash CS/Q2/Q3 pulls expose L15/J15/J16 before VCCO_14. Additional final-board controls unknown. |
| Bank 15 / VCCO_15 | D13 oscillator input, A14 proposed NVP SYS_CLK, EN controls, NVP video pins | Archive: same switched 3.3 V `Vcco`; designer's current rail report requires confirmation. | A14 has no permanent source proven. The proposed D13 oscillator supply/OE is unresolved, so pre-VCCO_15 drive cannot be excluded. PUDC LOW can bias pins after bank power appears; off-domain NVP paths remain. |
| Bank 34 / VCCO_34 | Other user/peripheral I/O | Archive: same switched 3.3 V `Vcco`. | Final peripheral inventory unavailable; cannot certify no permanent-domain pull or driver. |

Active-source documentation discrepancy: `xdc/boards/current/pins.xdc:19-20` comments that no CFGBVS/CONFIG_VOLTAGE property is asserted, but `scripts/project_common.tcl:64-72` includes `xdc/common/configuration_bank.xdc`, whose lines 4-5 set both properties. The executed common XDC is the stronger evidence; the board-specific comment is stale and should be corrected only in a future authorized source update.

VCCINT powers core configuration logic and VCCAUX powers auxiliary/configuration resources. Their actual regulator ramps and thresholds are not documented in the active source. In the archive, LM26480 SW2 feeds VCCAUX and its `~POR` participates in enabling the TPS22919 Vcco load switch. This suggests VCCAUX-before-VCCO intent, but component thresholds, delay, discharge, and FPGA pin exposure must be checked from the released schematic and regulator datasheets.

The archived power sheet labels the nominal FPGA rails at test points:

- TP2 / VCCINT: 1.0 V;
- TP3 / VCCAUX: 1.8 V;
- TP1 / VCCO: 3.3 V.

These are explicit Rev 0.1 nominal values, not measured ramps and not proof that the released A35T board retained the regulators or timing. The active source independently corroborates only the 3.3 V configuration-bank policy. Released A35T VCCINT/VCCAUX/VCCO values, tolerance, monotonicity, order, POR thresholds, and delays remain `REQUIRES_FINAL_SCHEMATIC_AND_DATASHEET_CONFIRMATION`.

## Permanent-rail exposure sequence

The hazardous candidate interval is:

1. PCIe-derived `V_3.3V` becomes valid.
2. Flash VCC and its CS/Q2/Q3 pull-ups become valid.
3. FPGA VCCO_14 remains 0 V or ramps later through the Vcco load switch.
4. L15, J15, and J16 are externally driven toward 3.3 V through 4.7 kOhm + 22 ohm paths.
5. Only later does the FPGA bank reach its valid operating range and the Master SPI engine take control.

The sequence can boot functionally and still violate a powered-off pad or rail-sequence condition; successful configuration alone is not proof of reliability.

## DS181 item

The designer referenced DS181 page 8 and a condition involving approximately:

- a 2.625 V relationship between VCCO and VCCAUX; and
- `TVCCO2VCCAUX` of about 800 ms at 85 C.

The applicable DS181 PDF/page was not locally available. The exact inequality, footnote, device applicability, temperature scope, and permitted duration were therefore not asserted as exact facts.

- `DS181_EXACT_REQUIREMENT = REQUIRES_AUTHORITATIVE_DS181_CONFIRMATION`
- `DS181_DEVICE_APPLICABILITY = REQUIRES_AUTHORITATIVE_DS181_CONFIRMATION`
- `DS181_VOLTAGE_RELATIONSHIP = REQUIRES_AUTHORITATIVE_DS181_CONFIRMATION`
- `DS181_ALLOWED_DURATION = REQUIRES_AUTHORITATIVE_DS181_CONFIRMATION`
- `DS181_TEMPERATURE_ASSUMPTION = REQUIRES_AUTHORITATIVE_DS181_CONFIRMATION`

When the correct DS181 revision is obtained, compare its requirement against oscilloscope captures of VCCINT, VCCAUX, VCCO_0, VCCO_14, permanent Flash 3.3 V, PROGRAM_B, INIT_B, and DONE across temperature and worst-case ramp/discharge. Do not substitute Flash 3.3 V for FPGA VCCO in the rail-to-rail formula. Separately check whether Flash-induced pad current partially lifts VCCO_14.

## Classification

The actual final A35T timing is unresolved, while the retained/reported topology exposes unpowered Bank-14 pads. The conservative architecture classification is:

`CURRENT_FLASH_POWER_SEQUENCE = POTENTIAL_VIOLATION`

It is not elevated to `VIOLATION` without the exact limit and waveform, and it is not reduced to `UNRESOLVED` because three physical source paths are already established in the reported/archived topology.
