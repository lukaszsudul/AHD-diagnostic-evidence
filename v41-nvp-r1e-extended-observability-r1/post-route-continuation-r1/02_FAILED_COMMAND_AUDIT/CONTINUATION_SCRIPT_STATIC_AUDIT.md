# Continuation-script static audit

SCRIPT=scripts\continue_exact_r1e_from_routed_dcp.tcl

- Every `report_property` call receives one object: PASS by construction.
- All two matched IOBUF objects are retained and sorted by full hierarchical name: PASS.
- Source-edit commands: 0.
- Synthesis commands: 0.
- Optimization commands: 0.
- Placement commands: 0.
- Physical-optimization commands: 0.
- Routing commands: 0.
- `write_checkpoint` commands: 0.
- New constraints: 0.
- Implementation-changing property assignments: 0.
- Possible `write_bitstream` commands: exactly 1.
- Retry loops around `write_bitstream`: 0.

STATIC_CONTINUATION_SCRIPT_AUDIT=PASS

