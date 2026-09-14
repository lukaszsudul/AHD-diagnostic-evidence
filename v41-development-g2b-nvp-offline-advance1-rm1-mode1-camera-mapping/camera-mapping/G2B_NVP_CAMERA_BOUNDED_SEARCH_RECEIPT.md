# G2B NVP camera bounded search receipt

## Receipt identity

WORKSTREAM = C_CAMERA_MAP

RUN_ROOT = G2B_NVP_OFFLINE_ADVANCE1_20260913T201843Z

EXECUTION_MODE = READ_ONLY_DISCOVERY_THEN_LOCAL_ARTIFACT_AUTHORING

DISCOVERY_MUTATION_COUNT = 0

PRIVATE_KICAD_COPY_COUNT = 0

PDF_COPY_COUNT = 0

AS_BUILT_ARTIFACT_COUNT = 0

## Bounded discovery scope

The final Section 26 design-file search was rerun at
`2026-09-14T05:30:53Z` and was bounded literally to these three roots:

- C:/FPGA/FPGA_AHD
- C:/FPGA/V41_G2B
- C:/FPGA/G2B_NVP_CAMERA_SCAN0_OFFLINE_20260911T135131Z

No other worktree, drive or user directory contributes to the Section 26
design-file-search result. The strict rerun found zero candidate design paths
in the current trees and zero matching design paths in the Git histories of
FPGA_AHD and V41_G2B.

The accepted R3 worktree and the primary NVP6134C datasheet were inspected
separately under the umbrella source/document authorities. Those inspections
are not treated as Section 26 design-file searches. No conclusion in this
receipt depends on the R3 worktree. The datasheet contributes only silicon pin
and device-input semantics under Section 2.10.

An existing evidence receipt inside FPGA_AHD was read. It names a private
KiCad source set, but the private root and files were not opened.

## Search classes

Within the three literal roots, the strict search covered:

- .kicad_sch
- .kicad_pcb
- legacy .sch
- .net
- PCB/netlist .xml
- BOM
- assembly and as-built records
- connector tables
- pin tables
- relevant local PDF identities
- text evidence containing connector, VIN, NVP, termination and 75-ohm terms
- Git history in the two named source repositories for PCB design file names

## Findings

QUALIFYING_BOARD_DESIGN_FILE_IN_SCOPED_ROOTS = NONE

QUALIFYING_BOM_IN_SCOPED_ROOTS = NONE

QUALIFYING_AS_BUILT_IN_SCOPED_ROOTS = NONE

CAMERA_CONNECTOR_TABLE_IN_SCOPED_ROOTS = NONE

CAMERA_CONNECTOR_REFDES_FOUND = NONE

EXTERNAL_AFE_REFDES_FOUND = NONE

CONNECTOR_TO_VIN_NET_CHAIN_FOUND = NONE

Unrelated XML implementation reports were not treated as PCB netlists.

One frozen NVP6134 reference PDF was present inside the SCAN0 root. It was not
copied and was not counted as a board schematic. The primary Rev1.0 datasheet
outside the three design-search roots was used only through the separate
Section 2.10 document authority.

## Indirect frozen-design inventory

An existing read-only source identity receipt records a frozen private design set. The receipt states that the following files matched their expected identities at the time of that audit:

| File | SHA-256 recorded by prior receipt |
|---|---|
| ahd_codec.sch | 5183D9216C54C06516F6C7B732AD97B50690E022AE30394D87584A3363A81ACB |
| ahd_xilinx_io.sch | D3431ED5915E1A27479899B49351925296C643A9C402A0140FD0283C7EC5D6B7 |
| ahd_power.sch | A2CB0E2D80C2FD8AB194EDF1D83AF628102E13C0DB597B751060E6EB2CCE90AD |
| ahd.net | 654CDF22FE883E534C726A3C4388894AAC645BABF10D16DAEDB74C93F9A7C056 |
| ahd.xml | 318AD6613E0095FE786D34AD6ED9BB5F6B501012C776EA2275DCC7E307B21DFB |
| ahd.kicad_pcb | 8D861286ABDF93FFF9526E50948F01AA74A73E99E206A524336885721745F997 |
| ahd.sch | 247A916B51225CF30290525A8DA4A635B0161D86B68C59E9A2BDD14950B84082 |

This inventory is not connector-map evidence because the design files were outside the bounded scope and were not inspected during this workstream.

## Positive evidence and its exact authority

- U6 is identified as the NVP device by
  `C:/FPGA/FPGA_AHD/A35T_R17_CANDIDATE_DIFF.md` inside the allowed FPGA_AHD
  root. This is device-identity evidence, not a camera connector path.
- NVP6134C VIN1, VIN2, VIN3 and VIN4 correspond to pins 76, 1, 6 and 8 under
  the separate Section 2.10 datasheet authority; this is not a design-search
  finding.
- Logical CH1 through CH4 correspond to VIN1 through VIN4 under the same
  silicon document authority.
- The diagnostic package in the allowed V41_G2B root maps CH1 through CH4 to
  Bank5 through Bank8 and VDO1 route codes 0x0 through 0x3.
- TESTED_CONNECTOR_INSTANCE is associated with logical CH1 at HIGH confidence
  by the Owner prompt Section 27; this is not inferred from an extra worktree.

## Negative evidence and boundary

- TESTED_CONNECTOR_INSTANCE has no found connector refdes.
- No complete connector-to-external-AFE-to-U6 path was found.
- No current BOM or as-built source was found.
- No board component proves 75-ohm termination.
- Datasheet wording is retained only as DATASHEET_EXPECTATION_NOT_PROVEN.
- J2 in the accessible KiCad audit is a JTAG connector and is not a camera connector.

## Receipt result

BOUNDED_SEARCH = COMPLETE

SILICON_MAPPING = HIGH_CONFIDENCE

TESTED_CONNECTOR_INSTANCE_TO_LOGICAL_CH1 = HIGH_CONFIDENCE

PHYSICAL_CONNECTOR_MAPPING = UNRESOLVED

FIRST_MISSING_ITEM = CONNECTOR_REFDES

CONTINUITY_TEST_PLAN_REQUIRED = YES
