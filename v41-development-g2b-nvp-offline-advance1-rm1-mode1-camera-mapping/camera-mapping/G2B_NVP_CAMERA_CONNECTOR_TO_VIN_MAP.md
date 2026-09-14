# G2B NVP camera connector to VIN map

## Decision

The NVP6134C silicon-side mapping is established with HIGH confidence:

| Logical channel | Classifier bank | NVP input | NVP refdes and pin | VDO1 route code |
|---|---:|---|---|---:|
| CH1 | Bank5 | VIN1 | U6.76 | 0x0 |
| CH2 | Bank6 | VIN2 | U6.1 | 0x1 |
| CH3 | Bank7 | VIN3 | U6.6 | 0x2 |
| CH4 | Bank8 | VIN4 | U6.8 | 0x3 |

The physical board-side mapping is not established:

| Link | Status | Confidence |
|---|---|---|
| TESTED_CONNECTOR_INSTANCE -> logical CH1 | HIGH_CONFIDENCE_INSTANCE_ONLY | HIGH |
| TESTED_CONNECTOR_INSTANCE -> connector refdes | UNKNOWN | NONE |
| connector center pin -> external AFE/protection/coupling path | UNRESOLVED | NONE |
| external AFE/protection/coupling path -> U6.VIN1 | UNRESOLVED | NONE |
| any named connector -> VIN2/VIN3/VIN4 | UNRESOLVED | NONE |
| current as-built agreement | NOT_FOUND | NONE |

HIGH for TESTED_CONNECTOR_INSTANCE applies only to its association with logical CH1. It does not identify a schematic connector reference, connector pin, net, external AFE path, coupling component, termination component, or current as-built assembly.

The CSV keeps the Section 27 physical fields separate. For all four rows,
ESD/protection parts, the coupling capacitor, the termination network, and the
filter/AFE refdes and net paths are explicitly `UNKNOWN`/`NOT_FOUND`; none is
collapsed into a generic external-frontend claim.

## Evidence separation

Silicon and RTL evidence establish:

- NVP6134C VIN1, VIN2, VIN3 and VIN4 are analog video inputs 1 through 4.
- NVP6134C pin numbers are VIN1=76, VIN2=1, VIN3=6 and VIN4=8.
- The frozen board evidence identifies U6 as the NVP6134C QFN-76 device.
- The diagnostic source maps channel indices 0 through 3 to Bank5 through Bank8.
- Bank1 register C2 routes decoder selections 0 through 3 to VDO1.

The evidence does not establish:

- camera connector reference designators;
- connector center and return pin numbers;
- coax, protection, coupling or external AFE net names;
- component reference designators between a connector and U6;
- a current BOM or as-built assembly;
- a measured or component-backed 75-ohm termination.

## Termination status

The NVP6134C datasheet describes AC-coupled video inputs with 75-ohm AC and DC input impedance and says that external coupling capacitance is required. This is classified as DATASHEET_EXPECTATION_NOT_PROVEN.

No board source in the bounded search proves whether CH1 has an external shunt resistor, an internal-only input impedance, an optional stuffing choice, a different network, or an as-built defect. No resistor reference, value tolerance, placement, measurement, BOM row or as-built photograph was found.

The physical termination status for CH1 is therefore NOT_PROVEN.

## Source basis

- Allowed Section 26 root `C:/FPGA/V41_G2B`:
  `rtl/nvp/nvp6134c_diagnostics_pkg.vhd`, `out_c2` channel codes 0 through 3
  and `c_v38ek_format_bank` Bank5 through Bank8.
- Allowed Section 26 root `C:/FPGA/FPGA_AHD`:
  `A35T_R17_CANDIDATE_DIFF.md` identifies NVP device U6 and its reset pin;
  this supports the U6 device identity but not any camera connector path.
- Separate Section 2.10 document authority: NVP6134C Rev1.0 pin descriptions
  and channel diagrams. This is silicon evidence, not a bounded board-file
  search result.
- Owner prompt Section 27: TESTED_CONNECTOR_INSTANCE to logical CH1 at HIGH
  confidence, without a physical refdes.

No extra worktree contributes to the mapping.

No private KiCad design file or PDF is copied into this workstream.

## Gate result

SILICON_MAPPING_GATE = PASS

TESTED_CONNECTOR_INSTANCE_TO_LOGICAL_CH1_GATE = PASS_HIGH_CONFIDENCE

PHYSICAL_CONNECTOR_TO_AFE_TO_VIN_GATE = BLOCKED

FIRST_FAILED_GATE = CONNECTOR_REFDES_NOT_FOUND

AS_BUILT_GATE = BLOCKED_NOT_FOUND

CH1_TERMINATION_GATE = BLOCKED_DATASHEET_EXPECTATION_NOT_PROVEN
