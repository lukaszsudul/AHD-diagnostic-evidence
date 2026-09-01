# PCB-PWR-0 First-Board Test Plan

## Purpose and boundary

This is the minimum controlled hardware comparison required if the HIGH population cannot be completely proven offline. It was **not executed** by this audit.

Compare two otherwise identical assemblies, or one assembly changed only while fully de-energized:

- A: PUDC_B -> GND through the documented mutually exclusive option;
- B: PUDC_B -> VCCO_14 through the documented mutually exclusive option.

Never populate both resistors. Never move or solder the option while any PCIe, auxiliary, Flash, FPGA, or NVP rail is energized.

## Preconditions

1. Confirm the tested PCB revision, BOM, exact FPGA `xc7a35tcsg325-2`, Flash part, M[2:0] straps, selected SPI width, and regulator population.
2. Review the exact AMD powered-off pad/injection and DS181 power-sequence limits before setting pass thresholds.
3. Use a current-limited, instrumented supply arrangement appropriate for the PCIe board; document all external cables/programmers.
4. Fit test access for permanent Flash 3.3 V, VCCINT, VCCAUX, VCCO_0, VCCO_14, VCCO_15, NVP VDD3D, NVP VDD1D, PROGRAM_B, INIT_B, DONE, FCS_B, A14/SYS_CLK, SDA, SCL, RSTB, and both enables.
5. Use high-impedance probes and a current measurement method that does not itself lift the off rail.
6. Start with the NVP rail enables held at their passive off states.

## Test 1: unpowered population/continuity audit

- Verify exactly one PUDC option is populated and record its resistance/reference rail.
- Verify external pull/default values and rail destinations for Flash CS/Q2/Q3, PROGRAM_B, INIT_B, RSTB, SYS_CLK, SDA, SCL, IRQ, and EN_VDD1x/EN_VDD3x.
- Confirm no short exists between permanent 3.3 V and switched VCCO/NVP rails.
- Record discharged residual voltages before every power-up.

## Test 2: Flash/FPGA cold boot

For each PUDC population, capture from first permanent-3.3-V rise through DONE:

- permanent Flash 3.3 V;
- VCCINT, VCCAUX, VCCO_0, and VCCO_14;
- PROGRAM_B, INIT_B, DONE, FCS_B, and CCLK;
- configuration time from the defined start event to DONE;
- supply current, including abnormal steps before VCCO is valid; and
- boot success without JTAG intervention.

Repeat cold starts after full discharge. Include nominal, slow-ramp, and fast-ramp cases permitted by the board power specification and a statistically useful repeat count agreed by engineering. Compare INIT_B faults, DONE failures, configuration time distribution, and Flash-select behavior.

Pass only if boot is repeatable and every observed voltage/current/time meets a cited AMD/Flash/regulator limit. “DONE went high once” is insufficient.

## Test 3: Flash-to-VCCO injection interval

With Flash 3.3 V present and switched VCCO held off or observed during its normal delay:

- measure VCCO_14 and, if separable, current into L15/FCS_B, J15/D02, and J16/D03 paths;
- check whether Q1/L17 is ever driven before VCCO_14 is valid;
- record the VCCAUX-to-VCCO relationship and duration against the exact DS181 rule;
- inspect FCS_B for a false-low interval that could enable the Flash; and
- repeat at worst-case permitted temperature/ramp conditions.

Any unexplained VCCO lift or limit exceedance is a fail requiring topology correction, not a resistor-value waiver.

## Test 4: NVP nominally off

Measure the unconfigured/pre-DONE interval while EN_VDD1x and EN_VDD3x are controlled only by their passive off states. The current configured RTL drives both enables high, so this comparison must either stop at the handoff to configured outputs or use a documented, non-contentious regulator-enable isolation/override fixture. Do **not** externally force an FPGA output low after EOS without series/current isolation and an approved fixture.

For LOW and HIGH populations measure:

- NVP VDD3D and VDD1D DC voltage and transient peak;
- board current and NVP-rail leakage/current if separable;
- A14/NVP SYS_CLK voltage/waveform;
- SDA and SCL voltage;
- RSTB voltage;
- both enable-node voltages; and
- representative VDO/VCLK/IRQ/MPP pins, with expansion to all pins if any rail lift is present.

The key A/B observation is whether LOW creates measurable off-rail lift and HIGH removes it. The related-board ~1.2 V value is not an AHD acceptance threshold.

## Test 5: controlled NVP startup/shutdown

Use an Owner-approved build or hardware fixture in which enables/reset can be sequenced without fighting configured FPGA outputs. For the HIGH population:

1. verify passive EN=inactive, RSTB=low, SYS_CLK=low, SDA/SCL unpowered/high-Z before configuration;
2. verify FPGA configuration and relevant VCCO banks become valid;
3. enable NVP rails according to the approved sequence;
4. verify RSTB remains asserted and no I2C traffic occurs while rails ramp;
5. start a clean 27.000 MHz A14 clock and confirm 45-55% duty at the NVP pin;
6. release RSTB with documented timing margin;
7. verify switched I2C pull-ups, idle bus, IRQ behavior, and video outputs; and
8. perform the safe shutdown order and check for rail lift during discharge.

Repeat with LOW only if needed for the architecture comparison and only with current/voltage limits in place.

## Recorded result fields

- board serial/revision/BOM;
- PUDC population and measured resistance;
- Flash part and SPI width;
- ambient/device temperature and supply ramp profile;
- pass/fail for Flash boot, INIT_B, DONE, and configuration time;
- peak/duration of VCCO_14 while nominally off;
- peak/steady NVP VDD3D while nominally off;
- off-state current;
- A14, SDA, SCL, RSTB, and enable states; and
- scope captures tied to exact AMD/NVP/Flash limits.

## Decision after test

Approve fixed HIGH only if it boots reliably and all off-domain measurements meet authoritative limits. Retain the configurable BOM option for diagnostics unless Owner intentionally freezes a single state after review. A HIGH boot failure must first be traced to a missing explicit Flash/configuration default; it does not establish that global pull-ups are generally safe for NVP.

`TEST_EXECUTED_BY_PCB_PWR0 = NO`
