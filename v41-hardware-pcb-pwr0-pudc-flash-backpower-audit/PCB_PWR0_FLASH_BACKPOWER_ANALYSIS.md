# PCB-PWR-0 Flash-to-FPGA Back-Power Analysis

## Result

`CURRENT_FLASH_POWER_SEQUENCE = POTENTIAL_VIOLATION`

The reported architecture and the only local board archive both place Flash VCC and three Flash-side pull-ups on permanent PCIe-derived 3.3 V while the FPGA configuration banks are on a later load-switched `Vcco`. This establishes injection paths topologically. Electrical safety cannot be proven without the final schematic and the applicable AMD/Flash powered-off limits.

## Verified archived topology

The archived Rev 0.1 netlist has:

- U5 `S25FL064L` VCC on permanent `V_3.3V` from PCIe +3.3 V;
- R26, R27, R28 = 4.7 kOhm from permanent `V_3.3V` to CS_B, Q3, and Q2 respectively;
- R19 = 22 ohm in series from Flash CS_B to FPGA L15/FCS_B;
- RN1 = four 22 ohm elements in the Q0-Q3 paths;
- U1 `TPS22919` producing `Vcco` after a control relationship with the LM26480 `~POR` signal; and
- one switched `Vcco` rail feeding FPGA VCCO_0, VCCO_14, VCCO_15, VCCO_34 and CFGBVS.

The active A35T repository corroborates 3.3 V configuration-bank intent through `CONFIG_VOLTAGE=3.3` and `CFGBVS=VCCO`, but it contains no current PCB netlist. Retention of the archived topology is `REQUIRES_FINAL_SCHEMATIC_CONFIRMATION`.

## Explicit injection paths

| Permanent source | Series path | Exact A35T pad | Bank | State while VCCO_14=0 | Finding |
|---|---|---|---|---|---|
| 3.3 V through R26 4.7 kOhm | R19 22 ohm | L15 / FCS_B | 14 | Externally biased high | Direct powered-source-to-unpowered-pad path |
| 3.3 V through R28 4.7 kOhm | RN1 22 ohm | J15 / D02 | 14 | Externally biased high | Direct powered-source-to-unpowered-pad path |
| 3.3 V through R27 4.7 kOhm | RN1 22 ohm | J16 / D03 | 14 | Externally biased high | Direct powered-source-to-unpowered-pad path |

Direct passive path count in the archive: `3`.

Conditional additional paths:

- Flash Q1 -> 22 ohm -> L17/D01 if a permanently powered Flash drives when the FPGA bank is unpowered;
- Flash Q0 and CCLK are not pulled high in the archive, but their powered-off behavior still depends on which device drives and when;
- any final-board status buffer or programming header on the configuration nets can add another powered source.

## Why resistor values do not establish safety

A series/pull resistance can limit current, but it does not by itself prove any of the following:

- pad voltage remains inside the FPGA absolute maximum rating;
- injection current is below the per-pin and aggregate AMD limit;
- VCCO_14 cannot be lifted through protection structures;
- partial VCCO_14 does not create an invalid VCCO/VCCAUX relationship;
- the Flash remains deselected and its outputs are high-Z;
- configuration logic behaves deterministically during the ramp; or
- repeated cold starts meet reliability/lifetime requirements.

The locally available DS181 transcription gives normal/sample-tested leakage and selected powered pull-up current, not an A35T powered-off Ioff guarantee. Those values must not be substituted for a powered-off specification.

`FPGA_POWERED_OFF_PROTECTION_IOFF = NOT_PROVEN`

## Effect of PUDC_B

PUDC_B LOW can add internal pulls only after the FPGA bank supply is sufficiently alive; PUDC_B HIGH removes those internal pulls on inactive SelectIO. Neither state disconnects the three permanent Flash pull-ups. PUDC_B HIGH is preferred for NVP/peripheral safety but is neutral on the earliest external Flash-to-VCCO injection interval.

## Limit classification

No local authoritative text was found that grants fail-safe input operation to these Artix-7 configuration pads with VCCO_14=0. No final A35T schematic or measured rail waveform was available. The topology must therefore not be called SAFE, and “4.7 kOhm is probably enough” is not an acceptable signoff method.

The `POTENTIAL_VIOLATION` classification is resolved by one of two outcomes:

1. authoritative limits plus final waveforms and Flash behavior formally prove the retained architecture compliant; or
2. the power/pull/isolation topology is changed so no powered source reaches an unpowered configuration bank.
