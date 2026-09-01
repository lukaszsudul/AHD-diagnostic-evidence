# PCB-PWR-0 Flash Power Options

The Flash architecture should not be changed merely because PUDC_B HIGH is selected. PUDC_B and Flash-to-VCCO injection are independent. The following options are evaluated against boot availability, sequencing, back-power, complexity, startup timing, and reliability.

## A. Move Flash signal pull-ups to the applicable FPGA VCCO rail

- Boot availability: the pull states become valid with VCCO_14. This can be appropriate for DQ2/WP, DQ3/HOLD, and FCS_B once the FPGA bank is alive.
- Sequencing/back-power: removes the pull-resistor source into an unpowered bank.
- Limitation: Flash VCC can remain permanently on. Its outputs must be guaranteed high-Z, and CS_B must remain safely high, before VCCO_14 is valid. Moving CS_B's only pull to a dead rail can leave a powered Flash selected unless another power-off-safe mechanism defines deselect.
- Complexity: low, but only safe after exact Flash pin behavior is proven.
- Reliability: better than the current pull source if Flash standby behavior closes the remaining driven-path risk.

## B. Power Flash and all associated pulls from the sequenced compatible rail

- Boot availability: boot begins only after that rail is valid, which is normally compatible with FPGA configuration if ramp/order/startup requirements are met.
- Sequencing/back-power: removes both passive-pull and Flash-output sources while the FPGA bank is off.
- Complexity: moderate schematic/power-budget change; check regulator load, discharge, inrush, POR, and Flash power-up time.
- Reliability: electrically clean when the shared rail meets both FPGA and Flash requirements. It can reduce early service/programming availability and must not compromise configuration startup timing.

## C. Retain rail topology and add/increase series resistance

- Boot availability: generally preserved if SPI edge rate and setup/hold remain adequate.
- Sequencing/back-power: limits current but does not guarantee pad voltage, Ioff, VCCO lift, or aggregate limits.
- Complexity: low; existing 22 ohm elements are for SI, not isolation.
- Reliability: acceptable only when authoritative per-pin/aggregate injection limits and transient simulations/measurements prove compliance. It is not a standalone cure.

## D. Add a powered-off-safe buffer, bus switch, or level isolator

- Boot availability: the isolator must default to the safe direction/state and become transparent early enough for Master SPI.
- Sequencing/back-power: can provide a hard barrier and Flash deselect when one domain is off.
- Complexity: highest; select a part with explicit powered-off isolation, correct directionality/bandwidth, no back-power through enable, and valid default output states.
- Startup timing: enable only after both sides are valid; ensure CCLK and data timing for the selected SPI width.
- Reliability: strongest separation when implemented with a configuration-specific device and verified timing.

## E. Retain the current architecture with formally proven sequencing limits

- Boot availability: unchanged.
- Sequencing/back-power: acceptable only if AMD explicitly permits the applied pad voltage/current with VCCO_14 off, the Flash cannot create uncontrolled additional paths, VCCO/VCCAUX timing is within DS181, and measured worst-case waveforms match the proof.
- Complexity: low PCB change but high verification burden and sensitivity to regulator/temperature/tolerance changes.
- Reliability: defensible only with an auditable limit table, calculations using worst-case values, and first-board plus environmental measurement.

## Recommendation boundary

No single alternative is automatically selected without the final schematic and component data. The preferred decision sequence is:

1. obtain the exact A35T powered-off configuration-pad and aggregate injection limits;
2. verify the retained Flash's CS/Q1/Q2/Q3 behavior while powered and its host VCCO is absent;
3. verify DS181 rail-order timing from the released regulator design;
4. choose A or E only if those limits close cleanly; otherwise choose B or a purpose-built D solution;
5. treat C only as a supporting current/timing element, never the sole safety argument.

`FLASH_VCC_CHANGE_AUTOMATICALLY_REQUIRED = NO`

`CURRENT_TOPOLOGY_SIGNOFF = NOT_ALLOWED_WITHOUT_LIMIT_PROOF`
