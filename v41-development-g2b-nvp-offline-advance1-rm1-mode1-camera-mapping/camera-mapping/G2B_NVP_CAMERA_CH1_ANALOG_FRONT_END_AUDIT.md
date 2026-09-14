# G2B NVP camera CH1 analog front-end audit

## Decision

The bounded search found no qualifying schematic, PCB/netlist, BOM, assembly
drawing or as-built record for the physical camera input path. The audit is
complete, but the CH1 external analog front end is not proven.

`CH1_ANALOG_FRONT_END_AUDIT = COMPLETE_WITH_AUTHORITY_GAP`

`CH1_ANALOG_FRONT_END_GATE = BLOCKED`

`AFE_AUDIT_FIRST_FAILED_GATE = QUALIFYING_CAMERA_INPUT_SCHEMATIC_NOT_FOUND`

This field is local to the analog-front-end sub-audit. The Workstream C and
umbrella first failed gate remains `CONNECTOR_REFDES_NOT_FOUND`.

## Required field audit

| Required field | Evidence-based value | Classification | Missing closure authority |
|---|---|---|---|
| nominal termination | 75 ohms appears only as the NVP6134C input expectation | DATASHEET_EXPECTATION_NOT_PROVEN | exact schematic topology, component value/tolerance, BOM and measurement |
| DC blocking | the NVP6134C datasheet requires external input coupling capacitance; the board capacitor and topology were not found | DATASHEET_EXPECTATION_NOT_PROVEN | schematic/netlist and populated coupling-capacitor evidence |
| protection | UNKNOWN | NOT_FOUND | protection-device refdes, part, pins, connectivity and population evidence |
| biasing | UNKNOWN | NOT_FOUND | exact external/internal bias topology and powered-state authority |
| filtering | UNKNOWN | NOT_FOUND | filter/AFE component chain, values and connectivity |
| expected signal type | analog composite video input over a nominal 75-ohm path is a datasheet expectation; the camera's emitted standard is not externally verified | DATASHEET_EXPECTATION_NOT_PROVEN | camera external-test result and exact board input specification |
| test points | UNKNOWN | NOT_FOUND | schematic/PCB test-point refdes and safe probing authority |
| component refdes | only the silicon endpoint U6.76 / VIN1 is supported; every external AFE/protection/coupling/termination refdes is UNKNOWN | PARTIAL_SILICON_ENDPOINT_ONLY | qualifying schematic, netlist and PCB source |
| population/as-built uncertainty | no current BOM or as-built evidence was found | NOT_FOUND | revision-matched BOM, assembly record and board photographs |

## 75-ohm conclusion

No scoped board source proves a true 75-ohm CH1 input path. The value `75` in
the mapping CSV is a datasheet expectation and must not be reported as a board
measurement, populated resistor or qualified impedance.

The prompt classification `SCHEMATIC_DESIGN_ONLY_NOT_AS_BUILT_PROVEN` is not
reached because the qualifying camera-input schematic itself was not found in
the bounded roots. If the Owner later supplies a hash-identified schematic but
not a matching BOM/as-built record, that future state must be classified
`SCHEMATIC_DESIGN_ONLY_NOT_AS_BUILT_PROVEN`.

## Boundary

No private KiCad file, proprietary schematic, vendor PDF, board photograph or
physical measurement is included here. No physical action is authorized by
this audit.
