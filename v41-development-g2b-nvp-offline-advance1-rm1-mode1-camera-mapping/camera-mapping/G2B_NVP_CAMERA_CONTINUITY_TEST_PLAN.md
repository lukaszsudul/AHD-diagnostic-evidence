# G2B NVP camera continuity test plan

## Status

PLAN_ONLY = YES

AUTHORIZED_FOR_EXECUTION = NO

MAPPING_AT_ENTRY = UNRESOLVED

TESTED_CONNECTOR_INSTANCE_TO_LOGICAL_CH1 = HIGH_CONFIDENCE_INSTANCE_ONLY

CONNECTOR_REFDES = UNKNOWN

AS_BUILT = NOT_FOUND

CH1_TERMINATION = DATASHEET_EXPECTATION_NOT_PROVEN

## Objective

Establish an evidence-backed physical path from each camera connector to one fixed NVP6134C VIN endpoint without using channel symptoms as a substitute for connectivity evidence.

## Fixed endpoints

| Target | Logical channel | Classifier bank | U6 endpoint | VDO1 route code |
|---|---|---:|---|---:|
| T1 | CH1 | Bank5 | U6.76 / VIN1 | 0x0 |
| T2 | CH2 | Bank6 | U6.1 / VIN2 | 0x1 |
| T3 | CH3 | Bank7 | U6.6 / VIN3 | 0x2 |
| T4 | CH4 | Bank8 | U6.8 / VIN4 | 0x3 |

## Required inputs

- explicit Owner authorization;
- exact board identity and assembly revision;
- exact hash-verified schematic, netlist, PCB and BOM;
- current as-built photographs;
- completed Owner input worksheet;
- component-aware continuity thresholds;
- instrument identity and safe test-voltage/current limits.

If any input is absent, record INPUT_GATE_BLOCKED and do not probe.

## Safety boundary

1. Remove board power.
2. Disconnect external camera and host cables only if authorization permits.
3. Confirm stored-energy discharge using the approved method.
4. Apply ESD controls.
5. Confirm the meter or impedance instrument cannot exceed device limits.
6. Use board-defined safe ground and probe points.
7. Do not probe fine-pitch U6 pins until a safe adjacent pad or test point is identified.
8. Do not use continuity-buzzer behavior as a quantitative resistance result.

Stop on any unexpected powered state, unstable reading, unsafe access, unidentified board revision or mismatch with the design authority.

## Documentation-first extraction

For each connector, create an ordered path:

connector refdes.signal pin
-> connector net
-> protection/filter/link refdes and pins
-> coupling capacitor near-side net
-> coupling capacitor far-side net
-> any external AFE or filter
-> U6.VIN pin

Record the return path separately. Record every optional stuffing choice. The extracted path is the expected result, not the measured result.

## Passive measurement sequence

### C0: connector return

- Measure connector return to the documented board return.
- Record resistance, method, repeat count and evidence ID.
- Do not assume that a shell is signal ground without schematic evidence.

### C1: connector to first component

- Measure the connector signal pin to the first board-side component pin.
- PASS only against the predeclared conductor and contact limit.

### C2: component-by-component path

- Measure each expected conductive component segment.
- For protection devices or filters, use the device-specific expected behavior.
- Preserve polarity where a semiconductor protection path is involved.

### C3: coupling capacitor split

A series coupling capacitor normally prevents DC continuity across the complete path.

- Measure connector-side continuity only to the capacitor near-side pad.
- Measure the capacitor far-side pad separately to the U6 VIN endpoint.
- Do not classify lack of end-to-end DC continuity as an open circuit until the component topology is considered.

### C4: target VIN

- Confirm the far-side net reaches exactly one fixed U6 VIN endpoint.
- Record the safe probe point that represents the U6 pin.
- Do not directly contact U6 if a safer same-net component pad exists.

### C5: cross-channel isolation

For each connector, test against all four VIN paths:

| Connector under test | Expected endpoint | Non-target endpoints that must not be shorted |
|---|---|---|
| TESTED_CONNECTOR_INSTANCE | U6.76 / VIN1 | U6.1 / VIN2; U6.6 / VIN3; U6.8 / VIN4 |
| Connector instance 2 | to be determined | all non-target VIN endpoints |
| Connector instance 3 | to be determined | all non-target VIN endpoints |
| Connector instance 4 | to be determined | all non-target VIN endpoints |

Use topology-aware limits. Shared protection or bias networks may produce finite readings and must be interpreted against the exact schematic.

## CH1 termination sequence

1. Bind TESTED_CONNECTOR_INSTANCE to its actual refdes and signal/return pins.
2. Identify the design termination topology.
3. Record the exact termination refdes, value, tolerance, stuffing state and adjacent nets.
4. Identify all parallel paths that affect a connector resistance reading.
5. With the board de-energized and external cable removed, measure DC resistance only if the topology makes that measurement meaningful.
6. If broadband impedance is the requirement, use an Owner-approved low-amplitude impedance, VNA or TDR method at declared frequencies.
7. Save raw instrument data privately and expose only sanitized readings, hashes and result codes.
8. Compare against the predeclared component/method tolerance.

The nominal 75-ohm value is not a PASS threshold by itself. Until design, as-built and measurement evidence agree, retain DATASHEET_EXPECTATION_NOT_PROVEN.

## Result record

Each measurement must contain:

- record ID and UTC;
- authorization ID;
- board serial and revision;
- connector instance, refdes and pins;
- endpoint refdes/pin and net;
- board power and cable state;
- method and instrument ID;
- maximum applied stimulus;
- raw value and unit;
- repeat index;
- expected behavior and predeclared limit;
- PASS, FAIL, BLOCKED or NOT_RUN;
- raw evidence artifact ID;
- operator and witness where required.

## Acceptance matrix

| Gate | PASS condition | Current state |
|---|---|---|
| Q0 authority and identity | all required inputs verified | NOT_RUN |
| Q1 connector refdes | physical instance tied to design refdes/pins | BLOCKED |
| Q2 ordered AFE path | every component/net extracted and as-built checked | BLOCKED |
| Q3 continuity | intended segmented path passes | NOT_RUN |
| Q4 isolation | all non-target paths pass topology-aware limits | NOT_RUN |
| Q5 CH1 termination | design plus as-built plus measurement agree | BLOCKED |
| Q6 final map | connector-to-VIN tuple contradiction-free | BLOCKED |

CONTINUITY_PLAN_FIRST_FAILED_GATE = Q1_CONNECTOR_REFDES_NOT_FOUND

The Workstream C and umbrella first failed gate is
`CONNECTOR_REFDES_NOT_FOUND`.

Do not execute Q2 through Q6 as if Q1 passed. Documentation work may continue, but physical qualification remains blocked.
