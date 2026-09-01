# PCB-PWR-0 NVP Safe-State Plan

## Objective

`FPGA unconfigured -> NVP electrically off and deterministic`

The plan uses PUDC_B HIGH as the proposed population so ordinary/inactive SelectIO are high-Z without global configuration pull-ups. It does not depend on RTL, configured INIT values, or NVP clamp diodes.

## External defaults

| Control | Proven information | Required preconfiguration state | Passive/isolation strategy | Release condition |
|---|---|---|---|---|
| EN_VDD1x | Archived regulator connection uses an active-high ENLDO2 input; released design unconfirmed | NVP 1.x V off | Pull to the regulator's proven inactive level; pull-down if active-high is confirmed. Reference the resistor to a domain valid whenever the enable input can respond. | FPGA configured, parent supply valid, intentional sequencer transition |
| EN_VDD3x | Archived regulator connection uses an active-high ON input; released design unconfirmed | NVP 3.x V off | Same policy as EN_VDD1x; verify EN threshold, internal pull, absolute max, and reverse-current behavior | Intentional sequence only |
| RSTB | NVP datasheet: active-low digital input | Asserted low | External pull-down. Do not provide a permanent-domain high pull. If the FPGA cannot guarantee high-Z/low while VDD3D is off, add powered-off isolation. | VDD1D/VDD3D valid, 27 MHz valid, required reset low pulse met; then release with margin beyond the documented timing |
| NVP SYS_CLK | NVP datasheet: 27 MHz digital input | Low | External pull-down on A14/NVP side. Validate VIL, leakage, FPGA high-state loading, 27 MHz SI and duty cycle. | VDD3D valid, NVP intentionally starting, ODDR run control asserted synchronously |
| SDA | 3.3-V-tolerant bidirectional pin while powered; powered-off tolerance absent | High-Z, no powered source | Pull-up only to switched NVP VDD3D; FPGA IOBUF low-or-Z; optional fail-safe bus switch if off-state cannot be proven | VDD3D valid and bus idle confirmed |
| SCL | 3.3-V-tolerant input while powered; powered-off tolerance absent | High-Z, no powered source | Pull-up only to switched NVP VDD3D; FPGA low-or-Z; optional fail-safe bus switch | VDD3D valid and bus idle confirmed |
| IRQ | Output type unknown | No permanent-domain bias | Leave unpulled until topology is confirmed. If open-drain, use switched NVP VDD3D pull; otherwise connect through proven powered-off-safe input/isolation. | NVP powered and output behavior valid |
| VDO/VCLK/MPP | NVP outputs; powered-off behavior unspecified | No FPGA-side high source | PUDC HIGH, no external pull. Ensure NVP remains off until FPGA VCCO is valid; isolate if independent sequencing is possible. | FPGA banks valid before NVP may drive |
| 27 MHz oscillator -> D13 | Proposed oscillator supply/OE domain unavailable | No drive into an unpowered VCCO_15 | Power from a compatible sequenced domain, hold output low/high-Z, or use proven isolation/Ioff. | VCCO_15 valid before oscillator output can drive |

No resistor value is prescribed without the released circuits and electrical limits. Values must be selected from worst-case thresholds/leakage, not typical current. The A14 pull-down additionally loads every configured high half-cycle and can affect 27 MHz edge rate and duty cycle.

## Postconfiguration handoff caveat

External defaults guarantee the board state only while FPGA drivers are high-Z and during the handoff into configured logic. The current read-only RTL at `rtl/nvp/nvp6134c_autoinit.vhd:80-83` drives both enable outputs high and later releases active-low reset according to its internal counter/reset behavior. Those configured outputs intentionally override passive defaults.

Therefore the released RTL/firmware sequence must prove that parent rails, power-good, 27 MHz clock, reset timing, and I2C readiness are valid before the configured enables/reset take effect. PCB-PWR-0 does not change RTL and does not approve the current counter behavior as a hardware power sequencer.

## Reset and clock sequence

The local NVP6134C Rev 1.0 datasheet records a minimum RSTB low pulse of 1 microsecond, a 10 microsecond low-to-high release timing entry, and SYS_CLK=27 MHz with 45-55% duty. It gives no complete rail/clock/reset sequence.

Conservative start sequence:

1. external pulls hold EN controls inactive, RSTB low, and SYS_CLK low;
2. FPGA configuration completes and its relevant VCCO banks are valid;
3. assert NVP rails in the order required by regulator/NVP confirmation;
4. keep RSTB low while rails settle;
5. start the ODDR/OLOGIC 27 MHz output from D13 to A14 with known INIT=0 and glitch-free gating;
6. after power-good, clock-valid, and reset timing margins, intentionally release RSTB;
7. only then release/start I2C activity and accept VDO/VCLK/IRQ.

Conservative shutdown is the reverse logical safety order: stop transactions, assert reset, stop SYS_CLK low, ensure NVP outputs are quiescent, disable rails, and keep FPGA pins high-Z/low so no source remains into the falling NVP domain.

## PUDC interaction

With PUDC_B LOW, the internal weak pull-up opposes every safe-low strategy above and remains a source on SDA/SCL even when their switched external pull-ups are dead. A stronger external pull-down can force a low, but only by accepting continuous configured-high current and a worst-case threshold/SI calculation.

With PUDC_B HIGH, the external passive element is the only intended preconfiguration bias on ordinary/inactive SelectIO. This makes A14 startup materially cleaner:

`FPGA unconfigured -> A14 high-Z -> external pull-down -> NVP SYS_CLK LOW`

`A14_STARTUP_CONCEPT = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`

The constraints are exact Master-SPI inactivity of A14's alternate configuration role, valid VCCO_15 before the D13 oscillator drives, a validated pull-down, no other board driver, and a configured disabled-low ODDR implementation.

## I2C decision

`I2C_PULLUPS_TO_SWITCHED_NVP_VDD3X = CONFIRMED_WITH_ADDITIONAL_CONSTRAINTS`

Switched-domain pulls are preferred over permanent FPGA-VCCO pulls because the high source disappears with NVP VDD3D. The additional constraints are PUDC_B HIGH (or equivalent isolation), low-only/open-drain FPGA behavior, no bus operation while off, and a powered-off-safe receiver path. PUDC_B LOW would leave configuration pull-ups active and therefore defeats the “no high source while off” objective.

## IRQ decision

`IRQ_POWER_OFF_BEHAVIOR = REQUIRES_NVP_DATASHEET_CONFIRMATION`

The available datasheet labels IRQ only as an output. It does not say push-pull or open-drain and does not specify VDD3D=0 behavior. A permanent FPGA-domain pull-up is not approved.

## Aggregate risk

At least 18 video pins, controls, and possible MPP pins can be biased by the global pull policy. Some are NVP outputs, for which the powered-off current path is not specified, and some are digital inputs whose absolute maximum is `VDD3D + 0.5 V`. The related-board ~1.2 V rail observation supports the mechanism.

`PUDC_LOW_AGGREGATE_INJECTION_RISK = HIGH`

No total current is calculated because the exact final connection count, active configuration roles, pad currents at their clamped node voltages, and NVP receiver paths are not all known.
