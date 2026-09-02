# META-5 Project-State Semantic Diff

## Revision transaction

`PROJECT_STATE_REV 4 → 5`, update type `ARCHITECTURE_CHANGE`, authorized by the
standalone frozen literal `SSOT WRITE AUTHORIZED` and the explicit
Owner/Architect decision in `META-5_TASK_DIRECTIVE`.

## Added current truth

- Group 13 `RESET_RETURN_SOURCE_TO_AXI` now requires
  `SETTLING_PLUS_STRUCTURAL_CDC`.
- Its global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` method is retired
  from required sign-off for the historical 7-source/207-destination scope.
- Exactly two G13-A semantic families, their exact `6.000 ns` bounds, retained
  broad aggregate relation, and structural CDC obligations are frozen.
- The unnumbered Group-13 decision is `RESOLVED` as
  `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`.
- G13-A immutable evidence provenance is added.
- Next allowed engineering step is `G2B-LUT1-SIGNOFF-RECOVERY-2`.

## Changed current continuation state

- G2B-LUT1 stays `READY_FOR_SIGNOFF_RECOVERY`, but its continuation now
  preserves Group 9 and Groups 10–12, resumes at Group 13 using the promoted
  method, and proceeds through Groups 14–17 and the remaining hard gates.
- G2B-IMPL and G2B-HW blockers now explicitly include pending Group-13
  candidate implementation/validation.
- Product and META mirrors point to revision 5 and META-5 evidence.

## Explicitly preserved truth

- Group-9 promoted method and retired global check.
- All ABI/MMIO/interface and R1i state.
- All open OD records, OD-03, and the existing Group-9 unnumbered decision.
- Group 9 PASS and Groups 10–12 authoritative PASS results.
- Groups 14–17 pending state.
- G2B-HW `BLOCKED`; no bitstream/hardware proof.
- R-track lifecycle/execution state and all unrelated tracks.
- Historical changelog and evidence references.

## Exact authorized file footprint

The transaction changes exactly 16 SSOT files, listed with pre-write and
post-write identities in `META5_EXACT_FILE_CHANGE_LEDGER.md`. No frozen policy,
template, schema, FPGA source, RTL, active XDC, or R-track source file changes.
