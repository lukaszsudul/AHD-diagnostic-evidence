# G2B NVP camera Owner input worksheet

Complete this worksheet before a physical qualification campaign. Do not replace UNKNOWN with an inference.

## Owner and authorization

| Field | Owner input |
|---|---|
| Owner name | |
| Authorization ID | |
| Authorization UTC | |
| Exact board instance/serial | |
| Assembly revision | |
| Board location | |
| Allowed passive actions | |
| Cable movement allowed | YES / NO |
| Powered correlation allowed | YES / NO |
| Signal injection allowed | YES / NO |
| Maximum allowed stimulus | |
| Prohibited actions | |
| Required final state | |
| First-failed-gate stop accepted | YES / NO |

## Design and as-built authority

| Artifact | Exact path or private reference | SHA-256 | Revision | Identity verified | Publication class |
|---|---|---|---|---|---|
| Main schematic | | | | YES / NO | PRIVATE_REFERENCE_ONLY |
| Codec/NVP schematic | | | | YES / NO | PRIVATE_REFERENCE_ONLY |
| Netlist | | | | YES / NO | PRIVATE_REFERENCE_ONLY |
| PCB source | | | | YES / NO | PRIVATE_REFERENCE_ONLY |
| BOM | | | | YES / NO | PRIVATE_REFERENCE_ONLY |
| Assembly drawing | | | | YES / NO | PRIVATE_REFERENCE_ONLY |
| As-built photographs | | | | YES / NO | PRIVATE_REFERENCE_ONLY |

## Connector inventory

| Connector instance ID | Physical label | Refdes | Signal pin | Return pin | Connector type | Photo artifact ID |
|---|---|---|---|---|---|---|
| TESTED_CONNECTOR_INSTANCE | | UNKNOWN | UNKNOWN | UNKNOWN | | |
| CONNECTOR_INSTANCE_2 | | UNKNOWN | UNKNOWN | UNKNOWN | | |
| CONNECTOR_INSTANCE_3 | | UNKNOWN | UNKNOWN | UNKNOWN | | |
| CONNECTOR_INSTANCE_4 | | UNKNOWN | UNKNOWN | UNKNOWN | | |

The existing high-confidence fact is TESTED_CONNECTOR_INSTANCE -> logical CH1. The refdes and all board-path fields remain UNKNOWN until qualified.

## Camera identity and configuration

Complete every field from the physical label, manual, measured value or external tester. A sales listing alone is not authority.

| Field | Owner input | Evidence ID |
|---|---|---|
| Manufacturer | | |
| Exact model | | |
| Serial or identifying label | | |
| Nameplate power voltage | | |
| Applied power voltage | | |
| Measured operating current | | |
| Camera connector type | | |
| Cable type | | |
| Exact cable instance ID | | |
| Cable length | | |
| PAL/NTSC region setting | PAL / NTSC / NOT_APPLICABLE / UNKNOWN | |
| OSD/menu setting | | |
| AHD/TVI/CVI/CVBS selector state | AHD / TVI / CVI / CVBS / AUTO / UNKNOWN / NOT_APPLICABLE | |
| UTC/coax-control setting | | |
| Camera photographs available | YES / NO | |

## External tester qualification

| Field | Owner input | Evidence ID |
|---|---|---|
| Tester/DVR make and model | | |
| Tester/DVR serial | | |
| Tester known-working proof | PASS / BLOCKED / FAIL | |
| Test UTC | | |
| External tester result | PASS / FAIL / NOT_RUN | |
| Reported output standard | AHD / TVI / CVI / CVBS / OTHER / UNKNOWN | |
| Reported resolution | | |
| Reported frame rate | | |
| Controlled scene change observed | YES / NO / NOT_RUN | |
| Result photograph/report available | YES / NO | |
| Scientific classification | EXTERNALLY_CONFIRMED_AHD_1080P25 / EXTERNALLY_CONFIRMED_OTHER_FORMAT / CAMERA_OUTPUT_CONFIGURABLE_BUT_NOT_VERIFIED / CAMERA_FORMAT_UNKNOWN / CAMERA_NOT_PROVEN_OPERATIONAL | |

The classification is based on measured external-test evidence. Do not infer EXTERNALLY_CONFIRMED_AHD_1080P25 from the camera label, selector position or advertised capabilities.

## Fixed silicon tuples

Do not edit these values.

| Logical channel | Classifier bank | NVP VIN | NVP refdes | NVP pin | VDO1 route code |
|---|---:|---|---|---:|---:|
| CH1 | Bank5 | VIN1 | U6 | 76 | 0x0 |
| CH2 | Bank6 | VIN2 | U6 | 1 | 0x1 |
| CH3 | Bank7 | VIN3 | U6 | 6 | 0x2 |
| CH4 | Bank8 | VIN4 | U6 | 8 | 0x3 |

## Physical path worksheet

Add one row for every ordered component. Do not compress several components into one row.

| Connector instance | Sequence | Refdes | Pin from | Pin to | Net in | Net out | Function | BOM value/tolerance | As-built status | Evidence ID |
|---|---:|---|---|---|---|---|---|---|---|---|
| TESTED_CONNECTOR_INSTANCE | 1 | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | CONNECTOR | | NOT_FOUND | |
| TESTED_CONNECTOR_INSTANCE | 2 | | | | | | PROTECTION / FILTER / LINK / COUPLING | | NOT_INSPECTED | |
| TESTED_CONNECTOR_INSTANCE | 3 | U6 | | 76 | | VIN1 | AFE | NVP6134C | NOT_INSPECTED | |

## Continuity limits

Define limits before measurement.

| Segment ID | Endpoint A | Endpoint B | Expected behavior | Method | Maximum stimulus | PASS range | Repeat count |
|---|---|---|---|---|---|---|---:|
| | | | CONDUCTIVE / ISOLATING / COMPONENT_DEPENDENT | | | | |

## CH1 termination

| Field | Owner input |
|---|---|
| Connector instance | TESTED_CONNECTOR_INSTANCE |
| Connector refdes | UNKNOWN |
| Logical channel | CH1 |
| NVP endpoint | U6.76 / VIN1 |
| Design topology | UNKNOWN |
| External termination refdes | UNKNOWN |
| Nominal resistance/impedance | 75 ohm DATASHEET_EXPECTATION |
| Component tolerance | UNKNOWN |
| Stuffing option | UNKNOWN |
| As-built status | NOT_FOUND |
| DC measurement method | |
| AC impedance method and frequency | |
| Instrument ID | |
| Method uncertainty | |
| Predeclared PASS range | |
| Raw evidence artifact ID | |
| Result | DATASHEET_EXPECTATION_NOT_PROVEN |

## Measurement record

| Record ID | UTC | Connector | Endpoint A | Endpoint B | Board state | Cable state | Reading | Unit | Instrument ID | Repeat | Result | Evidence ID |
|---|---|---|---|---|---|---|---:|---|---|---:|---|---|
| | | | | | DEENERGIZED | DISCONNECTED | | | | | | |

## Cross-channel isolation

| Connector instance | Intended VIN | VIN1 | VIN2 | VIN3 | VIN4 | Result |
|---|---|---|---|---|---|---|
| TESTED_CONNECTOR_INSTANCE | VIN1 | EXPECTED_PATH | | | | NOT_RUN |

## First-image CH1 readiness

| Required item | Owner record |
|---|---|
| Known powered camera identity | |
| EXTERNALLY_CONFIRMED_AHD_1080P25 evidence ID, when available | |
| Known cable identity | |
| Identified connector refdes | UNKNOWN |
| Qualified endpoint | U6.76 / VIN1 / logical CH1 |
| 75-ohm path status | DATASHEET_EXPECTATION_NOT_PROVEN |
| Bright high-contrast target prepared | YES / NO |
| One controlled scene change prepared | YES / NO |
| Separate DUT campaign authorization ID | |
| First failed readiness gate | |

## Owner disposition

| Gate | Owner disposition |
|---|---|
| Board identity | PASS / BLOCKED / FAIL |
| Design identity | PASS / BLOCKED / FAIL |
| Connector refdes | PASS / BLOCKED / FAIL |
| Connector-to-AFE path | PASS / BLOCKED / FAIL |
| AFE-to-VIN path | PASS / BLOCKED / FAIL |
| Cross-channel isolation | PASS / BLOCKED / FAIL |
| CH1 termination | PASS / BLOCKED / FAIL |
| As-built agreement | PASS / BLOCKED / FAIL |
| Camera external qualification | PASS / BLOCKED / FAIL |
| First-image CH1 readiness | PASS / BLOCKED / FAIL |
| Overall physical mapping | PASS / BLOCKED / FAIL |
| First failed gate | |

Owner signature/attestation:

Date:
