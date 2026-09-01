# PCB-PWR-0 PUDC_B Option Comparison

Neither state is treated as correct a priori. The comparison separates FPGA configuration behavior from peripheral power safety.

| Criterion | Option A: PUDC_B LOW | Option B: PUDC_B HIGH |
|---|---|---|
| FPGA configuration reliability | Supported 7-series strap state. Ordinary SelectIO receive weak pull-ups. This can conveniently prevent floating nodes, but it is not required for the dedicated configuration engine. | Supported 7-series strap state. Disables global SelectIO pulls; it does not disable dedicated or active configuration pins. Requires board-specific passive defaults. |
| Master SPI boot | Active FCS_B/CCLK/DQ functions remain configuration pins. Global pulls can provide incidental bias to inactive DQ/control pins, but boot must not rely on an undocumented incidental state. | Active FCS_B/CCLK/DQ functions remain configuration pins. Reliable boot is conditional on explicit mode, deselect, WP/HOLD/reset, PROGRAM_B, INIT_B, and DONE implementation. |
| NVP back-power | Highest risk. Every applicable FPGA-connected NVP input can become a source from powered FPGA VCCO. Related-board 1.2 V observation makes the mechanism credible. | Lower risk because ordinary FPGA pins are high-Z without global pulls. Remaining sources are explicit board pulls, configured/active pins, or other powered devices. |
| Other peripheral back-power | Same global risk exists on every SelectIO-connected off domain, not only NVP. Final schematic-wide inventory required. | Easier to audit because only explicit pulls/drivers remain; still requires full peripheral inventory. |
| Rail-enable startup | Weak pull-up can oppose an active-high enable's required off-state and can exceed a weak external pull-down. | External inactive-state resistor controls the pin without FPGA pull-up opposition. Active polarity must be confirmed. |
| Reset startup | For active-low RSTB, weak pull-up tends to release reset, contrary to the desired off/ramp state. Stronger pull-down may be needed and will load the configured output. | External pull-down can hold RSTB asserted until intentional release. Avoid a permanent high source while NVP VDD3D is off. |
| NVP SYS_CLK startup | A14 high-Z plus weak pull-up is not guaranteed LOW. It can inject into the off NVP clock input. | A14 high-Z plus external pull-down gives the intended LOW default, subject to resistor/SI validation. |
| I2C behavior | Switched-domain external pull-ups disappear when NVP is off, but configuration pull-ups remain an independent FPGA source. | With switched-domain pulls off, FPGA SDA/SCL are un-biased high-Z, assuming no active configuration role and open-drain RTL after configuration. |
| Need for external resistors | Still needs pull-downs strong enough to overcome worst-case internal pull current on safe-low controls. Fewer safe-high resistors may be needed. | Needs intentional resistors on every critical state: enable inactive, reset asserted, clock low, and configuration/Flash pins as required. |
| Deterministic safe state | Global default is deterministic only as a weak high bias. It cannot express mixed safe-high, safe-low, or domain-off behavior. | Net-specific defaults can express the required mixed policy and can reference the correct switched domain. |
| Flash/pull-up back-power | Does not solve permanent Flash pull-up injection into unpowered VCCO; may add additional SelectIO pull current after FPGA bank power appears. | Does not solve permanent Flash pull-up injection into unpowered VCCO. That is a separate architecture problem. |
| PCB complexity | Lowest resistor count but potentially stronger pull-downs, added isolation, and harder proof. | Modest added passive count and explicit BOM policy; may avoid isolation on some NVP controls if powered-off behavior is otherwise safe. |
| Diagnostic flexibility | Fixed LOW makes related-board A/B comparison impossible without rework. | A mutually exclusive HIGH/LOW footprint permits controlled first-board comparison. |

## Objective conclusion

LOW is not intrinsically wrong and HIGH is not intrinsically sufficient. LOW is unfavorable for AHD's powered-FPGA/unpowered-NVP operating case because its global weak-high policy conflicts with several required off states and creates many parallel injection candidates.

HIGH is the better proposed default because it removes that aggregate source and supports net-specific deterministic defaults. The remaining uncertainty is best managed by a mutually exclusive resistor population option and a first-board A/B measurement, while the Flash/VCCO path is closed independently.

`PUDC_B_RECOMMENDATION = CONFIGURABLE_0R_OPTION`

`DEFAULT_PROPOSED_POPULATION = HIGH_TO_VCCO_14`

`PUDC_CONFIGURABLE_OPTION = RECOMMENDED`
