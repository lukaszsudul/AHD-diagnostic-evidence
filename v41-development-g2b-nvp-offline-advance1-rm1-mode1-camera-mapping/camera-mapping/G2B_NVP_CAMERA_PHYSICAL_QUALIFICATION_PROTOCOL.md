# G2B NVP camera physical qualification protocol

## Purpose

This protocol independently qualifies both the camera source and the physical path from a named camera connector to the NVP6134C input and its logical channel. It does not change RTL, XDC, SSOT, firmware, bitstream, driver, NVP registers or prior evidence.

The current starting state is:

- TESTED_CONNECTOR_INSTANCE -> logical CH1: HIGH confidence.
- TESTED_CONNECTOR_INSTANCE -> connector refdes: UNKNOWN.
- CH1 -> Bank5 -> VIN1 -> U6.76 -> VDO1 route code 0x0: HIGH confidence.
- Named connector -> external AFE/protection/coupling network -> VIN1: UNRESOLVED.
- CH1 75-ohm termination: DATASHEET_EXPECTATION_NOT_PROVEN.
- Current as-built evidence: NOT_FOUND.

## Authorization boundary

No physical inspection, probing, measurement, cable movement, signal injection, powered test or rework is authorized by this document.

A future campaign must have an explicit Owner authorization identifier. The authorization must state:

- exact board instance and assembly revision;
- allowed passive measurements;
- whether cable movement is allowed;
- whether powered correlation is allowed;
- maximum stimulus amplitude and permitted instruments;
- prohibited operations;
- stop and restoration requirements.

Stop at the first failed or unauthorized gate. Do not infer a missing connection from channel symptoms.

## Fixed silicon reference

| Logical channel | Classifier bank | NVP VIN | U6 pin | VDO1 route code |
|---|---:|---|---:|---:|
| CH1 | Bank5 | VIN1 | 76 | 0x0 |
| CH2 | Bank6 | VIN2 | 1 | 0x1 |
| CH3 | Bank7 | VIN3 | 6 | 0x2 |
| CH4 | Bank8 | VIN4 | 8 | 0x3 |

These tuples are fixed inputs to the qualification. The campaign identifies the board path leading to each tuple. It must not redefine the tuple to fit a measurement.

## Gate P0: campaign and identity

Required evidence:

1. Owner authorization ID and timestamp.
2. Board serial or unique physical identifier.
3. Assembly revision and visible revision markings.
4. Before-state photographs showing the complete connector group and U6 area.
5. Instrument make, model, serial and calibration status.
6. Exact design-source identities used for comparison.
7. Confirmation that private source files remain private references and are not copied into public evidence.

PASS requires all seven items. If any item is absent, record IDENTITY_OR_AUTHORIZATION_INCOMPLETE and stop.

## Gate P1: documentation correlation

Use the exact revision of schematic, netlist, PCB and BOM that is claimed to represent the tested board. Verify artifact hashes before interpretation.

For every camera connector, extract:

- connector refdes and signal/return pins;
- input net name;
- protection components and pins;
- termination components and stuffing options;
- series or zero-ohm links;
- coupling capacitor and both adjacent nets;
- any external filter or AFE component;
- final NVP VIN net and U6 pin;
- BOM value, tolerance, manufacturer part and assembly status for each relevant component.

Cross-check the schematic against both netlist and PCB connectivity. Cross-check populated parts against as-built photographs or assembly records.

PASS requires a complete, contradiction-free ordered path. A connector label without a refdes is not sufficient.

## Gate P2: de-energized inspection and safety

Preconditions:

- board power removed;
- all camera and host cables removed if authorized;
- stored-energy discharge confirmed using the Owner-approved method;
- no external source connected;
- ESD controls in place;
- safe ground and probe points identified from design evidence;
- maximum meter test voltage/current confirmed safe for the NVP and protection devices.

Record the before-state and every connector instance. Do not use a continuity buzzer on an unknown semiconductor path.

PASS requires all preconditions. Otherwise record DEENERGIZED_SAFETY_GATE_FAILED and stop.

## Gate P3: segmented continuity

AC coupling can block direct DC continuity. Test the path in documented segments:

1. connector signal pin to the first board-side component pin;
2. each protection, link or filter segment;
3. connector-side net to the near side of the coupling capacitor;
4. far side of the coupling capacitor to the applicable U6 VIN pin;
5. connector return to the documented board return;
6. intended channel against each non-target VIN to detect cross-channel shorts.

For each segment record endpoint refdes/pin, net, method, stimulus limits, raw reading, units, instrument ID, repeat count and result.

PASS requires:

- the ordered path matches the exact design evidence;
- every expected conductive segment passes its component-aware limit;
- every expected isolating segment behaves consistently with its component;
- no unintended short to another VIN is detected;
- readings repeat within the predeclared tolerance.

No generic numeric continuity threshold is introduced here. The Owner worksheet must bind thresholds to the component and instrument method before the test.

## Gate P4: CH1 termination

The datasheet value of 75 ohms is an expectation, not an as-built result.

For TESTED_CONNECTOR_INSTANCE and CH1:

1. identify the termination topology from exact design evidence;
2. identify any termination refdes, value, tolerance and stuffing option;
3. identify whether the expected impedance is external, internal to U6, or combined;
4. select a measurement method appropriate to DC resistance or frequency-dependent impedance;
5. record connector state, board power state, cable state and all parallel paths;
6. capture raw instrument evidence;
7. compare only against a predeclared tolerance derived from component specifications and method uncertainty.

A DMM result near 75 ohms cannot by itself prove broadband input impedance. An open DMM result across an AC-coupled or internally switched input cannot by itself prove missing termination.

PASS requires design identity, as-built component evidence and a method-appropriate measurement. Otherwise record DATASHEET_EXPECTATION_NOT_PROVEN.

## Gate P5: connector instance to logical channel

The current evidence permits:

TESTED_CONNECTOR_INSTANCE -> CH1 = HIGH_CONFIDENCE_INSTANCE_ONLY

To upgrade the mapping to QUALIFIED, require:

- connector refdes and pins established by P1;
- complete connector-to-U6.76 path established by P3;
- cross-channel isolation PASS;
- board identity and as-built evidence PASS;
- repeatable observation under a separately authorized correlation test if passive evidence alone is ambiguous.

Do not use a successful CH1 detector response to replace missing connector refdes or net evidence.

## Gate P6: optional powered correlation

This gate is optional and requires separate explicit authorization. It is not authorized by this protocol.

If authorized:

- use one identified connector and one controlled source at a time;
- preserve the qualified firmware and hardware state;
- use read-only observations unless the authorization explicitly permits a bounded action;
- record pre-state, source identity, connector identity, channel observation, post-state and restoration;
- repeat each association enough times to demonstrate deterministic correlation;
- stop on the first state mismatch, ambiguity or restoration failure.

Powered correlation cannot repair an incomplete design or as-built record. It is corroborating evidence.

## Gate P7: camera source qualification on an external tester

This gate qualifies the camera without using the AHD v41 DUT. It requires a known-working, independent DVR or video tester and separate Owner authorization for powering and handling the camera.

Before power is applied, record:

- manufacturer;
- exact model;
- serial number or identifying label;
- nameplate and approved supply voltage;
- camera connector type;
- cable type, exact cable instance and length;
- external tester make, model, serial and known-working evidence;
- camera region setting, including PAL or NTSC when applicable;
- OSD/menu state;
- AHD/TVI/CVI/CVBS selector state;
- UTC/coax-control setting when relevant;
- before-state photographs and their private artifact IDs.

During the external test, record actual supply voltage and measured current, test UTC, tester lock/result, reported standard, resolution and frame rate, and a photograph or raw report showing the result. Make one controlled scene change and verify that the displayed image changes correspondingly. A sales label or menu option is not proof of the emitted format.

Assign exactly one scientific classification:

- EXTERNALLY_CONFIRMED_AHD_1080P25 only when the independent tester passes, reports AHD, 1920x1080 and 25 fps, and the controlled scene change is observed;
- EXTERNALLY_CONFIRMED_OTHER_FORMAT only when the independent tester passes and reports a different explicit standard, resolution or frame rate;
- CAMERA_OUTPUT_CONFIGURABLE_BUT_NOT_VERIFIED when configuration controls exist but the emitted format was not independently measured;
- CAMERA_FORMAT_UNKNOWN when the camera operates but the output standard, resolution or frame rate remains unresolved;
- CAMERA_NOT_PROVEN_OPERATIONAL when operation itself is not proven.

CAMERA_EXTERNAL_QUALIFICATION_GATE may pass only for EXTERNALLY_CONFIRMED_AHD_1080P25 or EXTERNALLY_CONFIRMED_OTHER_FORMAT. Stop on unexpected current, unstable power, missing image, contradictory tester output or any unauthorized action.

## Gate P8: frozen first-image physical protocol for CH1

This is a future human gate and does not authorize any hardware action now. Before a later CH1 first-image run, the Owner must:

1. select a camera already classified EXTERNALLY_CONFIRMED_AHD_1080P25 when available;
2. use the exact qualified camera power supply and exact known cable recorded at P7;
3. identify the physical connector by refdes and confirm that its qualified path terminates at U6.76 / VIN1 / logical CH1;
4. verify and document the 75-ohm path, or explicitly carry DATASHEET_EXPECTATION_NOT_PROVEN as a blocking condition;
5. aim the camera at a bright, high-contrast target;
6. prepare one controlled scene change without moving or reconnecting the signal cable during acquisition;
7. record pre-state photographs, camera/tester evidence IDs, connector identity and the separately authorized DUT campaign ID;
8. stop before DUT contact unless the later hardware prompt independently authorizes it.

The Owner must not substitute a different camera, cable, connector instance, power supply or board revision without restarting the applicable identity and qualification gates.

## Acceptance

PHYSICAL_CONNECTOR_TO_VIN_GATE may be PASS only when:

- P0 through P5 pass;
- connector refdes and pins are known;
- the full external path is recorded;
- U6 pin and VIN match the fixed silicon tuple;
- as-built status is FOUND;
- continuity and cross-channel isolation pass;
- termination status is MEASURED_AND_DOCUMENTED or a justified NOT_APPLICABLE result is accepted by the Owner;
- all evidence validates against G2B_NVP_CAMERA_EXTERNAL_TEST_EVIDENCE_SCHEMA.json.

Any first failure terminates the campaign with overall status BLOCKED or FAIL. Preserve the failed reading and do not normalize it.

CAMERA_EXTERNAL_QUALIFICATION_GATE is separate from PHYSICAL_CONNECTOR_TO_VIN_GATE. Either may pass while the other remains blocked. A later first-image campaign requires both an externally qualified source and an independently authorized, identified physical path.

## Required output

The future campaign must produce one JSON evidence record conforming to G2B_NVP_CAMERA_EXTERNAL_TEST_EVIDENCE_SCHEMA_R1 and a private raw-evidence bundle. Only sanitized facts and hashes may enter public evidence.
