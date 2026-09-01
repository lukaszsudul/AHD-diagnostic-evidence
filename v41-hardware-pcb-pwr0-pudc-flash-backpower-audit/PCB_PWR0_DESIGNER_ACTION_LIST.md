# PCB-PWR-0 Designer Action List

## Before routing release

1. Add mutually exclusive PUDC_B population options: J18-to-VCCO_14 and J18-to-GND. Propose HIGH as default. Mark “DNP alternate; never stuff both” in schematic and BOM.
2. Remove J18 from any legacy VDO assignment. The only local board archive uses J18 as VDO2_0 and is not compatible with a PUDC strap.
3. Provide the routing-final A35T schematic/netlist/BOM and confirm exact Flash part, VCC rail, pull-up destinations/values, M[2:0], PROGRAM_B, INIT_B, DONE, CFGBVS, and all bank VCCO rails.
4. Freeze the current A35T Master-SPI width explicitly. Historical A15T x4 build/programming evidence exists; the active A35T source width and autonomous cold-boot behavior remain unresolved.
5. Prove the FTDI M2 override is inactive at every cold boot unless intentional mode override is requested.
6. Resolve configuration-multifunction conflicts before assigning NVP signals. In particular, do not rely on T18/DOUT_CSO_B, T17/CSI_B, R18/RDWR_B, or other configuration-bus pins without exact Master-SPI behavior proof. Prefer PCB-PIN-1's M17/N17 I2C remap over active-XDC T18/T17.
7. Resolve VDO2 versus MPP pin ownership: proposed VDO2 uses U17/V17/U16/V16 while active XDC assigns those pins to MPP signals.

## Flash/power closure

8. Treat permanent Flash CS/Q2/Q3 pulls into unpowered VCCO_14 as open safety items. Obtain AMD A35T powered-off Ioff/injection limits and the retained Flash's powered-host-off behavior.
9. Obtain the applicable DS181 revision and transcribe the exact `TVCCO2VCCAUX` condition, footnotes, temperature applicability, and device scope. Compare against worst-case regulator timing.
10. Choose and document Flash power option A-E from `PCB_PWR0_FLASH_POWER_OPTIONS.md`; do not approve series resistance alone without an absolute-maximum/injection proof.
11. Confirm Flash CS_B is high until the configuration engine can validly select the device and that DQ2/WP_B and DQ3/HOLD_B/RESET_B defaults match the exact Flash and SPI width.
12. Keep HIGH tied to the actual VCCO_14 rail, not permanent PCIe 3.3 V.

## NVP/peripheral closure

13. Confirm final regulator enable polarity, thresholds, internal pulls, and power domains. If active-high is retained, add external pull-downs on EN_VDD1x and EN_VDD3x.
14. Add and validate an RSTB pull-down. Drive/release high only after NVP VDD3D is valid and the approved reset sequence permits it.
15. Add and validate A14 SYS_CLK pull-down. Use D13 -> FPGA -> ODDR/OLOGIC -> A14 with INIT=0/disabled-low behavior and 27 MHz SI/duty verification. Ensure the oscillator cannot drive D13 before VCCO_15 is valid, or add proven isolation.
16. Pull SDA/SCL only to switched NVP VDD3D and preserve low-only/open-drain FPGA behavior. Add a powered-off-safe bus switch if semiconductor confirmation does not grant safe off-state behavior.
17. Obtain NVP semiconductor confirmation for IRQ push-pull/open-drain type and VDD3D=0 behavior. Do not add a permanent-domain IRQ pull meanwhile.
18. Inventory every remaining FPGA-to-off-domain signal, not only NVP. For each, document direction, supply, preconfiguration state, explicit pull, powered-off limit, and shutdown state.
19. Ensure NVP cannot drive VDO/VCLK/MPP into an unpowered FPGA VCCO bank; sequence FPGA bank power first or isolate.
20. Validate the configured handoff separately: current RTL drives both enables high and later releases RSTB. Confirm it cannot override passive OFF/reset defaults before parent rails, power-good, and clock are valid; schedule a separate RTL change only if Owner authorizes it.

## Test and documentation

21. Add test access for VCCINT, VCCAUX, relevant VCCO rails, Flash 3.3 V, NVP rails, INIT_B, DONE, PROGRAM_B, FCS_B, A14, I2C, RSTB, and enables.
22. Execute the first-board LOW/HIGH comparison only with power removed for resistor changes and record the limits/waveforms listed in the test plan.
23. After Owner acceptance, update architecture/META/SSOT through its controlled process; do not promote this diagnostic evidence automatically.
24. In a separately authorized source change, correct the stale `pins.xdc` comment that says CFGBVS/CONFIG_VOLTAGE are absent; the included common XDC sets them.

## Explicit prior dispositions

- `J18/PUDC_B + 1 kOhm to GND = SUPERSEDED`
- `27 MHz -> D13 -> FPGA -> A14 -> NVP = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`
- `I2C pull-ups -> switched NVP Vdd3x = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`
