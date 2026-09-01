# PCB-PIN-1 I2C Power-Domain Analysis

## Decision

I2C_PULLUP_DOMAIN = NVP_SWITCHED_3V3_RECOMMENDED

The FPGA's permanent 3.3 V Bank-14/15 supply and the NVP switched 3.3 V I/O supply are different power domains even though their nominal voltages are equal.

## Why the switched domain is preferred

Connecting SDA/SCL pull-ups to switched NVP 3.3 V removes the normal bus-high source when the codec is off. This reduces:

- clamp-diode current into an unpowered NVP;
- partial powering through SDA/SCL;
- undefined bus levels during NVP power transitions; and
- an always-on electrical dependency between the permanent FPGA rail and the switched codec rail.

With NVP 3.3 V off, both FPGA IOBUFs must be high-Z. No transaction may start and neither pin may ever be actively driven high.

## Compatibility with current open-drain architecture

The current top-level IOBUFs tie I to zero and use T as the output-disable control. The I2C engine initializes and resets scl_oen and sda_oen to one, which releases both pins. This is the correct low-only/open-drain structure and is compatible with switched-domain pull-ups.

Future sequencing must preserve:

- SDA high-Z before switched 3.3 V is valid;
- SCL high-Z before switched 3.3 V is valid;
- no active-high output mode;
- no bus recovery pulses or START until pull-ups are present;
- immediate return to high-Z before shutdown; and
- bus-idle validation after power-up.

## Configuration-time exception

Switched external pull-ups do not by themselves eliminate all off-domain current if J18/PUDC_B is low. AMD 7-series configuration logic then enables weak internal pull-ups on every SelectIO, including SDA and SCL, from the permanent FPGA VCCO bank.

Before PCB release, close at least one of these paths:

1. Select a PUDC_B state that leaves user I/O high-Z during configuration and provide individual passive defaults where needed.
2. Prove from the NVP datasheet that SDA/SCL are fail-safe and meet the required Ioff/clamp-current limits while NVP power is absent.
3. Add an I2C bus switch or level translator whose powered-off behavior isolates the domains.

Level translation is not yet classified mandatory because the NVP power-off I/O specification is unavailable. Isolation becomes mandatory if fail-safe behavior cannot be proven.

## FPGA behavior with NVP off

Bank 14 and Bank 15 remain powered at 3.3 V. High-Z FPGA inputs/IOBUFs are legal, but the board must avoid externally applying voltage to an unpowered NVP through the shared nets. Internal FPGA input leakage does not create a bus-high source when external and configuration pull-ups are absent.

Any bus pull-up and any IRQ pull-up should be on the switched NVP 3.3 V domain unless a dedicated power-off-safe translator explicitly defines another domain.

## Required verification

Obtain and review:

- NVP SDA/SCL absolute maximum ratings with VDD=0;
- Ioff or fail-safe specification;
- input leakage and clamp-current limits;
- I2C VIH/VIL and bus-capacitance limits;
- the actual switched-rail ramp/discharge behavior; and
- bus-switch/translator powered-off behavior if used.

