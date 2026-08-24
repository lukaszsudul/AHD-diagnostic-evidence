# R1g Routed-DCP Impact Audit — Exact Post-Build Invocation Contract

This audit remains unavailable until the one R1g clean build has passed every
implementation and provenance gate and emitted both `R1G_BUILD_RESULT.txt` and
`R1G_routed.dcp`. Preparing these scripts does not open either checkpoint.

## Mandatory inputs

The invocation is permitted only after independently recording:

```text
R1G_BUILD_RESULT.TASK=V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY
R1G_BUILD_RESULT.FULL_BUILDS=1
R1G_BUILD_RESULT.SYNTHESIS=PASS
R1G_BUILD_RESULT.PLACE=PASS
R1G_BUILD_RESULT.ROUTE=PASS
R1G_BUILD_RESULT.ROUTE_ERRORS=0
R1G_BUILD_RESULT.WNS>=0
R1G_BUILD_RESULT.WHS>0
R1G_BUILD_RESULT.VDO_WNS>0
R1G_BUILD_RESULT.VDO_WHS>0
R1G_BUILD_RESULT.DRC_ERRORS=0
R1G_BUILD_RESULT.DRC_CRITICAL_WARNINGS=0
R1G_BUILD_RESULT.REQP_1839_SEMANTIC_COUNT=4
R1G_BUILD_RESULT.CDC_CRITICAL=0
R1G_BUILD_RESULT.CDC_UNKNOWN=0
R1G_BUILD_RESULT.SOURCE_COMMIT_TO_BIT_PROVENANCE=PASS
R1G_BUILD_RESULT.BITSTREAM_GENERATED=YES
R1G_BUILD_RESULT.R1G_IMPLEMENTATION_GATE=PASS
```

The expected R1g DCP SHA-256 passed to the wrapper must come from the sealed
post-build artifact-identity record. It must not be filled by trusting a
different path at audit time.

The R1e reference is frozen inside the wrapper:

```text
R1E_ROUTED_DCP_PATH=C:\FPGA\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1\07_BUILD\reports\PHASE3_routed.dcp
R1E_ROUTED_DCP_SIZE_BYTES=48609481
R1E_ROUTED_DCP_SHA256=1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1
```

## One permitted invocation

Substitute only values produced by the successful R1g build and source
identity gate:

```powershell
$audit = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\08_BUILD\ROUTED_DCP_IMPACT_AUDIT_TOOLING\Invoke-R1gRoutedDcpImpactAudit.ps1'

& $audit `
  -R1gDcpPath '<exact-R1G_routed.dcp-path>' `
  -ExpectedR1gDcpSha256 '<sealed-64-hex-R1g-DCP-SHA256>' `
  -R1gBuildPassReceiptPath '<exact-R1G_BUILD_RESULT.txt-path>' `
  -ExpectedR1gSourceCommit '<exact-40-hex-R1g-child-commit>' `
  -ExpectedR1gSourceTree '<exact-40-hex-R1g-source-tree>' `
  -OutputDirectory 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\08_BUILD\R1G_ROUTED_DCP_IMPACT_AUDIT'
```

The output directory must not already exist. The wrapper creates it only after
both DCP hashes, the full build receipt, the bitstream hash, the exact source
identity, and the static no-mutation audit have passed.

## Fail-closed behavior

Any of the following stops before `open_checkpoint`:

- missing or mismatched exact R1e checkpoint;
- missing or mismatched R1g checkpoint SHA-256;
- incomplete, duplicated, or failed build-receipt fields;
- source commit/tree mismatch;
- routed-DCP path mismatch between the receipt and invocation;
- bitstream absence or bitstream SHA-256 mismatch;
- a terminal build-failure receipt beside the claimed build-pass receipt;
- wrong Vivado executable path;
- any mutating or build command in the Tcl source;
- a reused output directory.

Vivado itself rechecks exact version `2025.2`, software build `6299465`, part
`xc7a35tcsg325-2`, and the routed object classes before producing a PASS
receipt. A failed query preserves partial evidence and authorizes no retry.

## Evidence and interpretation boundary

The audit captures paired R1e/R1g evidence for:

- SCL/SDA port and IOBUF properties;
- OEN-to-IOBUF timing paths and structural fan-in;
- pad-to-first-synchronizer timing paths and structural fan-out;
- synchronizer placement and properties;
- clocks and clocking-resource placement;
- flat/hierarchical utilization, BRAM inventory and placement;
- routed congestion;
- total/dynamic/static power, VCCINT/VCCAUX/VCCO lines, and NVP/probe/autoinit
  hierarchy lines.

The paired checkpoint evidence supports:

```text
R1G_IMPLEMENTATION_DELTA=QUANTIFIED
R1G_PLACEMENT_NEUTRAL=NOT_CLAIMED
```

The required conclusion
`R1G_LANGUAGE_REWRITE_CAUSED_FUNCTIONAL_NETLIST_CHANGE=NO_BY_LOGICAL_EQUIVALENCE_AND_EXPECTED_RTL`
must additionally cite the separate accepted R1f-reference/R1g-candidate
cross-standard equivalence receipt. The DCP comparison alone does not assert
logical equivalence.
