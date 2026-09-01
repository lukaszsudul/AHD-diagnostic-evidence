# PCB-PIN-1 NVP Startup Sequence

## Result

NVP_STARTUP_SEQUENCE = DEFINED

No timing value below is invented. The NVP6134C datasheet and the selected regulator/load-switch datasheets are not present in the active workspace, so their required delays and rail order remain explicit closure actions.

## Required sequence

| Step | Required behavior | Delay classification | Evidence/closure |
|---:|---|---|---|
| 0 | Passive PCB defaults hold EN_VDD1x and EN_VDD3x inactive (LOW under the reviewed active-high assumption), NVP reset asserted low, NVP clock low, and SDA/SCL high-Z before FPGA ownership. | KNOWN | architecture requirement; confirm power-control polarity and verify the inactive level against configuration pulls |
| 1 | FPGA configuration reaches EOS with the application clock-run state zero and all NVP-safe outputs still held. | KNOWN | 7-series startup behavior plus later RTL/implementation contract |
| 2 | Confirm no I2C transaction is active and both I2C drivers remain released. | KNOWN | current low-only IOBUF architecture is compatible |
| 3 | Enable the 1.2 V and 3.3 V NVP rails in the order required by the NVP and regulator datasheets. | FROM_NVP_DATASHEET_REQUIRED | exact order is not available in this audit |
| 4 | Wait for power-good or for validated rail stabilization/ramp completion. | FROM_NVP_DATASHEET_REQUIRED; TO_BE_MEASURED if no power-good | use regulator PG when available; characterize board otherwise |
| 5 | Start the 27 MHz output through the synchronized ODDR run control, producing a full first pulse. | KNOWN | defined in the clock-forwarding architecture |
| 6 | Hold reset asserted for the required number of valid clock cycles or time after clock start. | FROM_NVP_DATASHEET_REQUIRED | do not infer a value |
| 7 | Release the active-low NVP reset only after all required rails and the clock are valid. | KNOWN ordering; FROM_NVP_DATASHEET_REQUIRED timing | confirm NVP reset VIH, Ioff, and minimum pulse/hold time |
| 8 | Wait the required reset-release-to-I2C interval. | FROM_NVP_DATASHEET_REQUIRED | no value available |
| 9 | Verify switched-domain SDA/SCL pull-ups are present and the bus is idle high, then begin I2C initialization. | KNOWN ordering; FROM_NVP_DATASHEET_REQUIRED timing | abort on missing/stuck bus |
| 10 | Declare NVP ready only after required initialization and clock/video readiness checks pass. | KNOWN | product policy; exact codec lock/status criteria require datasheet/bring-up evidence |

## Current implementation versus future requirement

The read-only v40 implementation:

- hard-wires both nvp_en_vdd1x and nvp_en_vdd3x high;
- holds active-low nvp_rst low for 500 ms;
- starts I2C at 1.5 s; and
- uses open-drain SDA/SCL IOBUFs that are high-Z while released.

Those 500 ms and 1.5 s values are KNOWN current implementation behavior, not proven NVP6134C requirements. Current RTL does not implement controlled rail shutdown and is not changed by this audit.

Driving reset high while the NVP rail is absent is not approved: it could inject current through the receiver structure. The preferred off/startup state is asserted LOW, or high-Z held LOW by a passive pull-down. The NVP power-off reset-pin specification is unavailable, so this item is explicitly `REQUIRES_NVP_DATASHEET_CONFIRMATION`.

## Preconfiguration safety condition

With J18/PUDC_B low, configuration-time weak pull-ups affect every SelectIO NVP control. Under the reviewed active-high enable assumption, passive enable pull-downs and the active-low reset pull-down must be sized to keep each actual receiver below its VIL limit against the worst-case 330 microamp FPGA pull-up and leakage. Confirm the enable polarity before applying this topology. If the safe state cannot be proven, change the PUDC_B policy or add power-off isolation/buffering.

## Required datasheet inputs

Before implementation signoff obtain:

- NVP rail order, ramp, current, and discharge requirements;
- SYS_CLK frequency/duty/jitter and clock-before-reset requirements;
- reset polarity, thresholds, internal pull, Ioff, minimum assertion, and release timing;
- reset-release-to-I2C delay;
- SDA/SCL power-off tolerance and bus timing; and
- regulator/load-switch enable polarity, thresholds, pulls, reverse-current behavior, and power-good timing.
