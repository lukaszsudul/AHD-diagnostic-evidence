# T2 KiCad I2C topology and pull-up audit

## Source identity and method

The preferred local source was present at `C:\Users\Łukasz Suduł\Documents\Private\FPGA\kicad-20260530T131751Z-3-001\kicad`. It was inspected read-only. The supplied expected hashes for `ahd.net`, `ahd.xml`, `ahd.kicad_pcb`, and `ahd_power.sch` all match exactly; `KICAD_REVISION_IDENTITY_DIFFERENT=NO`. The audit cross-checked the legacy schematics, both exported netlists, and the physical PCB routing.

Layer names in the board source are Polish: `Gorna` is top copper and `Dolna` is bottom copper.

## Exact I2C topology

### NVP_SCL

- Net name: `NVP_SCL` (`ahd.net` code 152; PCB net 93).
- Source/destination: FPGA `U4.T17` to NVP6134C `U6.64`.
- Pull-up: `R20`, 4.7 kΩ, pad 1 on `NVP_SCL`, pad 2 on `Vcco`.
- All net members: `U4.T17`, `U6.64`, and `R20.1`. No other member exists in either exported netlist.
- Physical routing: 13 top-copper segments, approximately 35.259 mm from FPGA pad to NVP pad. The R20 pad is tapped directly on this top-layer route.
- Vias: 0.
- Copper layers: top only.

### NVP_SDA

- Net name: `NVP_SDA` (`ahd.net` code 153; PCB net 94).
- Source/destination: FPGA `U4.T18` to NVP6134C `U6.63`.
- Pull-up: `R21`, 4.7 kΩ, pad 2 on `NVP_SDA`, pad 1 on `Vcco`.
- All net members: `U4.T18`, `U6.63`, and `R21.2`. No other member exists in either exported netlist.
- Physical routing: approximately 32.936 mm from FPGA pad to NVP pad on top copper. A further approximately 1.842-mm pull-up branch uses one via to reach bottom-side R21; total explicit segment length is approximately 34.778 mm.
- Vias: 1 at `(133.800, 103.525)` mm, 0.48-mm diameter with 0.25-mm drill.
- Copper layers: top for the FPGA-to-NVP path; top and bottom for the R21 branch. Small same-net zones on both layers form the via transition.

## Pull-up rail and current

- `R20=4k7` and `R21=4k7` are confirmed in schematics, XML, netlist, and PCB.
- Resistor tolerance is not specified in the inspected KiCad fields: `NOT_SPECIFIED`.
- Target rail: `Vcco`.
- Nominal voltage: 3.3 V, established by the `TP1` schematic value `3,3V` and the upstream `V_3.3V` source.
- Rail path: `V_3.3V` → ferrite bead `F1` (`BLM18AG601`) → `U1.1` (TPS22919DCK input) → load-switch output `U1.6` → `Vcco` → `R20.2` and `R21.1`.
- The schematic and exported netlists include `TP1.1` on `Vcco`. The physical `ahd.kicad_pcb` file contains no `TP1` footprint or pad. This is a schematic-to-layout documentation discrepancy, not evidence that the rail is absent; `J2.1` is a physically laid-out through-hole `Vcco` access point.
- Nominal static pull-up current when a line is low: `3.3 V / 4.7 kΩ = 0.702 mA` per line. Both lines low would draw approximately `1.404 mA` total through the two pull-ups.
- Bus capacitance: `UNKNOWN_NOT_MEASURED`.
- RC rise time: not calculated because the source contains no validated bus-capacitance model or measurement.

## Additional-device and crossing audit

Neither I2C line contains a series resistor, shunt capacitor/filter, ESD device, test point, connector crossing, level shifter, second target, or other component. The only three members of each net are the FPGA pad, NVP pad, and its pull-up resistor.

`TP1` is on the `Vcco` rail, not on either I2C signal. J2 is the JTAG header and also does not connect to either I2C net.

## Physical proximity and accessible inspection points

- JTAG header `J2` is centered at `(157.075, 135.100)` mm. Its courtyard is approximately 6.8 mm from the nearest `U4.T17/T18` route breakout. Center-to-pad distances are approximately 14.23 mm to `T17` and 14.98 mm to `T18`. The I2C routes do not cross J2, but the BGA breakout is close enough that mechanical damage or board strain around the JTAG header remains visually relevant.
- Pull-up center distances: R20 is approximately 30.09 mm from the FPGA center and 7.22 mm from the NVP center; R21 is approximately 28.14 mm from the FPGA center and 4.96 mm from the NVP center.
- More useful routed-distance interpretation: R20 lies roughly 2–3 mm of copper from `U6.64` and about 33 mm from `U4.T17`; R21 is immediately adjacent to the NVP-side via/pad branch and about 33 mm from `U4.T18`.
- Best later signal access: `R20.1` on the top for SCL and `R21.2` on the bottom for SDA. These are substantially easier and safer than the FPGA BGA pads or the NVP QFN pins.
- Best later rail access: `R20.2`/`R21.1` locally, or through-hole `J2.1` for `Vcco`.
- Nearby reference: ground via `(135.100, 103.750)` mm is 1.44 mm from R21 center and 3.51 mm from R20 center. Through-hole `J2.2` is a robust ground reference near the JTAG area.

## Reset revision/history discrepancy

This frozen KiCad revision maps `NVP_RST` to FPGA `U4.R18` and `NVP_IRQ` to `U4.R17`. The current board-designer declaration controls the present hardware: reset is package pin `R17`, active LOW, released HIGH, with an external 3.3-V pull-up. The older KiCad R18/R17 mapping is retained only as revision/history evidence and does not overturn the current declaration.

## T2 conclusion

The previously reported nominal I2C design intent is verified: `U6.64 ↔ U4.T17` with R20 ≈4.7 kΩ to `Vcco`, and `U6.63 ↔ U4.T18` with R21 ≈4.7 kΩ to `Vcco`. The bus has no extra electrical devices. The most inspection-relevant physical features are the 0402 pull-ups, the single SDA layer-transition via, the top-layer BGA breakouts near J2, and the two fine-pitch NVP pads.
