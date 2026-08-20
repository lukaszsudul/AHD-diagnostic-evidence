# T3 physical-inspection checklist

Preparation only. No physical inspection, probing, measurement, movement, or rework was performed or requested overnight.

Coordinate system: millimetres from the frozen `ahd.kicad_pcb` origin. `Gorna` = top; `Dolna` = bottom.

## Inspection order

1. **J2 JTAG header and nearby FPGA breakout — top side**
   - Designator/area: `J2`, center `(157.075, 135.100)`; pins span approximately `y=135.100` to `128.750`. Inspect the adjacent `U4.T17/T18` breakout beginning at `(151.750, 121.900)` and `(151.750, 121.100)`.
   - Expected: straight 1×6 through-hole header; intact solder joints and pads. `J2.1=Vcco`, `J2.2=GND`, pins 3–6 are TCK/TDO/TDI/TMS.
   - Photo angles: first a perpendicular top overview covering J2 and the upper-right U4 corner; then a 25–40° grazing angle along the header row; then a macro close-up of the two I2C breakout traces.
   - Safe reference: through-hole `J2.2` GND at approximately `(157.075, 133.830)`.
   - Look for: lifted or cracked header pad, solder bridge, contamination/flux, damaged connector body, mechanical board strain, hairline damage toward T17/T18, and scratched or delaminated copper.

2. **R20 SCL pull-up — top side**
   - Designator: `R20`, 0402, center `(134.625, 100.275)`.
   - Expected marking/value: nominal `4k7`; a 0402 body may have no legible marking. Pad 1 at approximately `(134.625, 100.760)` is `NVP_SCL`; pad 2 at approximately `(134.625, 99.790)` is `Vcco`.
   - Photo angles: perpendicular macro, then low-angle views from both long-axis directions so both fillets are visible.
   - Nearby safe ground/reference: GND via `(135.100, 103.750)`; it is approximately 3.51 mm away.
   - Look for: cracked 0402 body, missing/wrong pull-up, tombstoning, lifted pad, cold joint, solder bridge, contamination/flux, or local board flex damage.

3. **R21 SDA pull-up and SDA via — bottom side**
   - Designators/features: `R21`, 0402, center `(134.275, 102.575)`; `NVP_SDA` via `(133.800, 103.525)` with 0.48-mm diameter/0.25-mm drill.
   - Expected marking/value: nominal `4k7`; pad 2 at approximately `(133.790, 102.575)` is `NVP_SDA`; pad 1 at approximately `(134.760, 102.575)` is `Vcco`.
   - Photo angles: perpendicular bottom macro centered on R21 and the nearby via; two opposing grazing views to expose both solder fillets and the via annulus.
   - Nearby safe ground/reference: GND via `(135.100, 103.750)`, approximately 1.44 mm from R21 center.
   - Look for: cracked body, missing/wrong pull-up, lifted pad, cold joint, solder bridge, contamination, damaged/open via annulus, scratched trace, and local strain.

4. **U6 NVP6134C I2C corner — top side**
   - Designator: `U6`, QFN-76, center `(132.200, 107.075)`.
   - Exact pads: `U6.64 NVP_SCL` at `(133.400, 102.6375)` and `U6.63 NVP_SDA` at `(133.800, 102.6375)`; pad 62 immediately adjacent is reset in this KiCad revision.
   - Expected: NVP6134C package seated flat, uniform perimeter joints, no debris between 0.4-mm-pitch pads.
   - Photo angles: perpendicular package overview; high-magnification 20–30° grazing view across pads 62–65; second grazing view from the opposite direction.
   - Nearby safe ground/reference: GND via `(135.100, 103.750)`; do not use the fine QFN ground/exposed pad as a casual probe point.
   - Look for: NVP package solder anomaly, solder bridge, cold/open joint, lifted pad, contamination/flux, package tilt, corner impact, or damaged traces between U6 and the pull-ups.

5. **U4 FPGA T17/T18 fan-out — top side**
   - Designator: `U4`, center `(146.550, 127.900)`. Relevant BGA balls are `T17` at `(151.750, 121.900)` and `T18` at `(151.750, 121.100)`.
   - Expected: intact solder-mask-defined breakout and unbroken top copper leaving the BGA edge; the balls themselves are not optically inspectable beneath the package.
   - Photo angles: perpendicular macro covering the upper-right BGA edge to J2; shallow lighting parallel and perpendicular to the two traces.
   - Nearby safe reference: `J2.2` GND. Keep any later probes away from BGA fan-out unless an approved microprobe setup is used.
   - Look for: damaged T17/T18 route, solder-mask abrasion, copper nick, contamination, board strain, BGA edge/package displacement, or evidence of force transferred from J2.

6. **Vcco source area — top side**
   - Designator: `U1` TPS22919DCK, center `(121.350, 117.400)`; output is `U1.6` to `Vcco`.
   - Expected: intact SC-70-6 load switch and surrounding F1/input/output network.
   - Photo angles: perpendicular overview and a low-angle macro showing all six leads.
   - Reference/access: `J2.1` is a robust through-hole `Vcco` point and `J2.2` is ground. Schematic `TP1` is not present as a placed PCB footprint in this frozen layout.
   - Look for: package or lead damage, cold joint, bridge, contamination, cracked nearby passives, or rail-area strain.

## Visible failure-mode checklist

- [ ] cracked 0402 body
- [ ] lifted pad
- [ ] cold joint or insufficient wetting
- [ ] solder bridge
- [ ] contamination/flux residue spanning pads
- [ ] mechanical board strain/warpage
- [ ] damaged JTAG connector pad
- [ ] damaged T17/T18 route
- [ ] NVP package solder anomaly
- [ ] missing or wrong-value pull-up
- [ ] damaged SDA via/annulus
- [ ] no visible defect

No item in this checklist authorizes rework, cleaning, probing, or component replacement.
