# G2B-LUT0 Read-only Vivado Analysis Receipt

Purpose: resolve the G2B slot-memory attribution hidden by the published hierarchy report and obtain diagnostic name-group estimates. No synthesis, implementation, placement, routing, bitstream, source mutation or hardware access was performed.

- Tool: Vivado 2025.2
- Mode/options: `-mode tcl -nojournal -nolog -notrace`
- Input DCP: `C:/FPGA/G2B_BUILD_EVIDENCE_20260829_PRECOMMIT_02/G2B_POST_OPT.dcp`
- Input DCP SHA-256: `C41B2888A3E9A52D5AC9B4E5302B18BDED6F9352143831DA6E75912BC58207DF`
- Work directory: isolated `C:/FPGA/G2B_BUILD_20260829_PRECOMMIT_02`
- Output: stdout only; no report or Tcl file retained by the query

Primitive-query body after `open_checkpoint`:

```tcl
set cs [get_cells -hier -filter {NAME =~ G2B_ONECH_C2H/*}]
puts "TOTAL_CELLS=[llength $cs]"
array set cnt {}
foreach c $cs { incr cnt([get_property REF_NAME $c]) }
foreach k [lsort [array names cnt]] { puts "REF|$k|$cnt($k)" }
```

Key normalized output:

```text
DCP_OPEN=checkpoint_G2B_POST_OPT
TOTAL_CELLS=5569
REF|CARRY4|266
REF|FDRE|2780
REF|FDSE|128
REF|LUT1|10
REF|LUT2|353
REF|LUT3|291
REF|LUT4|251
REF|LUT5|249
REF|LUT6|1095
REF|RAM32M|9
REF|RAM32X1D|4
REF|RAMB36E1|4
```

The complete normalized 603-byte primitive-summary payload had SHA-256 `B3638DAF85A2E1DEEB79F5D62B1FBEC3AF1D8297FFD135F0C219C089727B2C65`. This is a hash of the normalized key payload, not the timestamped Vivado console.

`report_utilization -cells G2B_ONECH_C2H` returned 1,994 LUT, 2,908 FF and 4 RAMB36. The published hierarchical report returns 1,990 LUT, 2,908 FF and no BRAM on that row. The four-LUT difference and flattened BRAM placement are Vivado attribution-scope effects; report-to-report comparisons use 1,990, while direct core/file attribution explicitly labels 1,994.

