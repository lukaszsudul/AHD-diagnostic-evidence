# PCB-PWR-0 SSOT Impact

## Current task

`SSOT_MODIFIED = NO`

This evidence package is diagnostic/architecture-review material. It does not promote a decision into `project-current-state`, change G-track/R-track state, or modify any active source/XDC/PCB file.

## Future META/architecture update if Owner accepts

The controlled future update should record:

1. exact device `xc7a35tcsg325-2` and final Master-SPI mode/width;
2. PUDC_B mutually exclusive population topology, default population, reference rail, resistor limit, and “never both” BOM rule;
3. the reason HIGH is proposed: eliminate global preconfiguration pull sources into off domains and enable net-specific defaults;
4. explicit NVP safe states for EN_VDD1x, EN_VDD3x, RSTB, SYS_CLK, SDA, SCL, IRQ, VDO/VCLK, and MPP;
5. the confirmed Flash VCC/pull/VCCO architecture and the exact approved powered-off/sequence proof or isolation change;
6. the exact DS181 power-sequence requirement and verified worst-case margin;
7. configuration-pin restrictions for J18, T18, T17, R18, DQ/FCS pins, and any parallel-configuration multifunction pad used as user I/O;
8. `27 MHz -> D13 -> ODDR/OLOGIC -> A14 -> NVP` constraints, including external A14 pull-down and disabled-low initialization;
9. switched-NVP-domain I2C pulls and the condition that global/internal or permanent-domain sources must be absent;
10. IRQ electrical type/pull domain once semiconductor evidence is obtained;
11. first-board A/B results and the final fixed/configurable PUDC disposition; and
12. all schematic/BOM references and evidence commit identifiers.

## Decisions not automatically promoted

- `PUDC_B_RECOMMENDATION = CONFIGURABLE_0R_OPTION`
- proposed default population HIGH to VCCO_14;
- `CURRENT_FLASH_POWER_SEQUENCE = POTENTIAL_VIOLATION` pending closure;
- `PUDC_HIGH_FLASH_BOOT = SUPPORTED_WITH_EXTERNAL_PULL_REQUIREMENTS`;
- `PUDC_LOW_AGGREGATE_INJECTION_RISK = HIGH`;
- `J18/PUDC_B + 1 kOhm GND = SUPERSEDED`;
- 27 MHz and switched I2C decisions confirmed only with their additional constraints.

Owner acceptance and the normal META/architecture workflow are required before any of these become project state.
