# G2B NVP camera bounded search report

## Outcome

The bounded search closes the silicon-side mapping but does not close the board-side connector mapping.

Engineering result:

- silicon channel map: PASS;
- tested connector instance to logical CH1: PASS_HIGH_CONFIDENCE;
- named connector to external AFE to NVP VIN: BLOCKED;
- CH1 termination: BLOCKED;
- as-built qualification: BLOCKED.

The first missing physical fact is the connector reference designator for TESTED_CONNECTOR_INSTANCE.

## Proven channel model

| Logical channel | Classifier register bank | NVP analog input | U6 pin | VDO1 route selector |
|---|---:|---|---:|---:|
| CH1 | Bank5 | VIN1 | 76 | 0x0 |
| CH2 | Bank6 | VIN2 | 1 | 0x1 |
| CH3 | Bank7 | VIN3 | 6 | 0x2 |
| CH4 | Bank8 | VIN4 | 8 | 0x3 |

Confidence is HIGH for all four silicon tuples. The evidence is explicitly
partitioned: the NVP6134C pin/channel description comes from the Section 2.10
document authority, the U6 NVP-device identity comes from
`C:/FPGA/FPGA_AHD/A35T_R17_CANDIDATE_DIFF.md`, and the bank/route functions
come from source inside the allowed V41_G2B root. No extra worktree contributes
to this result.

## Tested connector instance

The tested physical connector instance has a HIGH-confidence association with logical CH1. The strongest valid statement is:

TESTED_CONNECTOR_INSTANCE -> logical CH1

The evidence does not support:

TESTED_CONNECTOR_INSTANCE -> named connector refdes -> exact passives/nets -> U6.76

The connector refdes, signal pin, return pin, protection path, external AFE path, coupling component and VIN net are UNKNOWN.

This distinction prevents a runtime association from being promoted into a schematic or as-built claim.

## Board-source inventory

No qualifying PCB source, schematic, netlist, BOM, assembly record or as-built table exists in the bounded roots.

An existing audit receipt records hashes for a private frozen KiCad set containing ahd_codec.sch, ahd_xilinx_io.sch, ahd_power.sch, ahd.net, ahd.xml, ahd.kicad_pcb and ahd.sch. Those files were not opened or copied. The receipt proves only that a source set existed and matched the earlier expected identities. It does not expose the camera connector mapping.

The available KiCad-derived evidence is limited to an I2C topology extraction and a physical checklist. It identifies U6 as NVP6134C and J2 as JTAG. It contains no camera connector table.

## Termination analysis

The NVP6134C Section 2.10 datasheet authority, outside the bounded board-file
search, describes the input as AC-coupled with 75-ohm AC and DC input impedance
and states that external coupling capacitance is required.

This evidence supports:

TERMINATION_NOMINAL_OHM = 75

TERMINATION_STATUS = DATASHEET_EXPECTATION_NOT_PROVEN

It does not establish:

- whether the tested board uses an external 75-ohm shunt;
- whether the expected impedance is internal to U6;
- whether an optional resistor is fitted;
- the termination refdes or tolerance;
- the coupling capacitor refdes or value;
- the measured DC resistance or broadband impedance;
- current as-built agreement.

No arbitrary tolerance is assigned. A later qualification must derive limits from exact component data, topology and instrument uncertainty.

## Required closure evidence

The minimum closure package is:

1. exact board instance and assembly revision;
2. hash-verified schematic, netlist, PCB and BOM;
3. as-built photographs or assembly records;
4. connector refdes and pin table;
5. ordered connector-to-U6 component/net path;
6. component-aware segmented continuity measurements;
7. cross-channel isolation measurements;
8. topology-aware CH1 termination measurement;
9. one JSON record conforming to the external test evidence schema;
10. Owner disposition at the first failed gate.

The continuity plan is necessary because the mapping remains unresolved. AC coupling requires segmented measurements rather than one end-to-end continuity check.

## Confidence and gaps

| Claim | Status | Confidence | Gap |
|---|---|---|---|
| CH1 -> Bank5 -> VIN1 -> U6.76 -> route 0x0 | PROVEN | HIGH | none within silicon model |
| CH2 -> Bank6 -> VIN2 -> U6.1 -> route 0x1 | PROVEN | HIGH | none within silicon model |
| CH3 -> Bank7 -> VIN3 -> U6.6 -> route 0x2 | PROVEN | HIGH | none within silicon model |
| CH4 -> Bank8 -> VIN4 -> U6.8 -> route 0x3 | PROVEN | HIGH | none within silicon model |
| TESTED_CONNECTOR_INSTANCE -> CH1 | PROVEN_INSTANCE_ONLY | HIGH | refdes and physical path |
| named connector -> external AFE -> VIN | UNRESOLVED | NONE | design and as-built source |
| CH1 75-ohm termination | DATASHEET_EXPECTATION_NOT_PROVEN | NONE for board | topology, component and measurement |
| current as-built agreement | NOT_FOUND | NONE | assembly evidence |

## Final classification

SILICON_MAPPING_GATE = PASS

PHYSICAL_CONNECTOR_TO_VIN_GATE = BLOCKED

FIRST_FAILED_GATE = CONNECTOR_REFDES_NOT_FOUND

CONTINUITY_TEST_PLAN = REQUIRED_AND_PROVIDED

No private KiCad file, PDF or as-built image is present in this workstream.
