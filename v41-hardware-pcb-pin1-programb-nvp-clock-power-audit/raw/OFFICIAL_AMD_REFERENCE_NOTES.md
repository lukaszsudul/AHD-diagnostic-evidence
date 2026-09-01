# Official AMD Reference Notes

## UG470 v1.17, 7 Series FPGAs Configuration User Guide

URL: https://docs.amd.com/v/u/en-US/ug470_7Series_Config

Relevant statements:

- Table 2-4, pp. 20-21: PROGRAM_B is a dedicated active-low configuration reset. A falling edge initiates configuration reset and configuration begins after the following rising edge. An external pull-up no larger than 4.7 kOhm to VCCO_0 is required.
- Table 2-4, p. 21: PUDC_B low enables internal SelectIO pull-ups after power-up and during configuration; PUDC_B high disables them. PUDC_B must be tied directly or through no more than 1 kOhm to VCCO_14 or GND.
- pp. 80-81: after PROGRAM_B, JPROGRAM, or IPROG, configuration memory is cleared; GTS places user I/O in high-Z and PUDC_B low adds internal pull-ups.
- pp. 135-138: ICAPE2/IPROG can write WBSTAR and trigger reconfiguration; IPROG preserves dedicated reconfiguration logic and supports MultiBoot/fallback flows.

## DS181 v1.27.1, Artix-7 DC and AC Switching Characteristics

URL: https://docs.amd.com/v/u/en-US/ds181_Artix_7_Data_Sheet

Relevant statements:

- Table 3: selected 3.3 V pad pull-up current at VIN=0 is 90 to 330 microamps; sample-tested pin leakage maximum is 15 microamps.
- LVCMOS33 thresholds include VIL maximum 0.8 V and VIH minimum 2.0 V for HR I/O.
- Table 66: TPROGRAM minimum PROGRAM_B low pulse width is 250 ns for all listed speed grades.

## UG471 v1.10, 7 Series FPGAs SelectIO Resources

URL: https://docs.amd.com/v/u/en-US/ug471_7Series_SelectIO

Relevant statements:

- ODDR is the dedicated output DDR primitive in OLOGIC.
- Xilinx recommends ODDR clock forwarding rather than a fabric clock output.
- Traditional fixed clock forwarding uses D1 high and D2 low; PCB-PIN-1 uses the same OLOGIC edge selection with registered D1 as the run state and D2 fixed low to guarantee disabled-low operation.

## UG953, ODDR and ICAPE2

ODDR: https://docs.amd.com/r/2023.1-English/ug953-vivado-7series-libraries/ODDR

ICAPE2: https://docs.amd.com/r/2025.2-English/ug953-vivado-7series-libraries/ICAPE2

The primitive descriptions confirm the 7-series ODDR and ICAPE2 interfaces used in the architectural assessment. No RTL primitive was instantiated in the product source by this audit.

