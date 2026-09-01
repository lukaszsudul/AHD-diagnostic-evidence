# PCB-PIN-1 A14 Startup State Analysis

## Result

A14_PRECONFIG_STATE = WEAK_PULLUP_EXPECTED

NVP_CLK_EXTERNAL_PULLDOWN = REQUIRED

This result assumes the current PCB-PIN-1 design input that J18/PUDC_B is held low by a 1 kOhm pull-down. The earlier published PCB-PIN-0 report itself left that resistor unapproved pending schematic context; this task treats the low strap as the newer design assumption.

## Before and during FPGA configuration

A14 is Bank-15 IO_L8N_T1_AD10N_15. For a configuration mode that does not actively use its AD10N configuration-bus multifunction role, global three-state makes it high impedance while configuration memory is being cleared and loaded.

AMD UG470 states that PUDC_B low enables weak internal pull-ups on each SelectIO pin after power-up and during configuration. Therefore high impedance does not mean electrically floating in this design: A14 is expected to be weakly pulled toward VCCO_15. It must not be assumed low.

If a configuration mode actively consumes A14's multifunction configuration role, its state follows that mode instead. The local PCB requirements specify Master-SPI mode M[2:0]=001, so AD10N is not active in the reviewed configuration plan. The product straps still must be verified before schematic release.

## Immediately after configuration

At startup/EOS, application ownership transfers to the configured output path. A later ODDR implementation must specify INIT=0 and initialize its run control to zero. That makes the configured state low once user I/O is active. There remains a preconfiguration interval in which the weak pull-up exists, so an RTL initial value alone cannot satisfy an always-low board requirement.

## Pull-up strength and external pull-down

Artix-7 DS181 specifies the selected 3.3 V pad pull-up current at VIN=0 as 90 to 330 microamps. A guaranteed-low external resistor must be selected using worst-case FPGA pull-up current, all leakage, and the NVP SYS_CLK maximum low threshold:

    R_PD <= VIL_MAX / (330 microamps + total leakage budget)

This relation is a selection bound, not a prescribed resistor value. Final selection requires the NVP6134C SYS_CLK VIH/VIL, leakage, capacitance, and powered-off tolerance plus the board SI model.

The design review must also check:

- DC current when A14 drives high, approximately 3.3 V divided by R_PD;
- A14 VOH margin and Bank-15 current budget;
- 27 MHz rise/fall time and duty-cycle distortion;
- receiver loading and any source-series element;
- current into an unpowered NVP input; and
- the transition from the configuration pull-up interval to the configured low driver.

Because the stated design requirement is NVP SYS_CLK guaranteed low until intentional start, an external pull-down or an equivalent power-off isolating/low-forcing circuit is required. A pull-down footprint alone is insufficient unless the stuffed value is validated against the limits above.

## Wider PUDC_B consequence

PUDC_B low applies the same configuration pull-up policy to other SelectIO-connected NVP signals. RST, SDA, SCL, IRQ, EN_VDD1x, and EN_VDD3x need the same off-domain review. In particular, active-high regulator enables cannot rely only on FPGA INIT=0; they require passive low defaults that overcome the configuration pull-up, or the board must change the PUDC_B policy.

## References

- AMD UG470, configuration pin definitions and configuration-memory clear behavior: https://docs.amd.com/v/u/en-US/ug470_7Series_Config
- AMD DS181, Table 3 pad pull-up current: https://docs.amd.com/v/u/en-US/ds181_Artix_7_Data_Sheet
