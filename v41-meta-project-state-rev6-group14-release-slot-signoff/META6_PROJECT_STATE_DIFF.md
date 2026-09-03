# META-6 Project-State Semantic Diff

## Revision transaction

`PROJECT_STATE_REV 5 → 6`, update type `ARCHITECTURE_CHANGE`, authorized by the
standalone frozen literal `SSOT WRITE AUTHORIZED` and the explicit
Owner/Architect decision in `META-6_TASK_DIRECTIVE`.

## Added current truth

- Group 14 `RELEASE_SLOT_0_AXI_TO_SOURCE` now requires
  `SETTLING_PLUS_STRUCTURAL_CDC`.
- Its global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` method is retired
  from required sign-off for the historical 56-source/20-destination scope.
- Exactly three G14-A semantic families, their exact `6.000 ns` bounds and
  routed validation results, and the full structural CDC/protocol obligations
  are frozen.
- The unnumbered Group-14 decision is `RESOLVED` as
  `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`.
- G14-A immutable evidence provenance is added.
- Next allowed engineering step is `G2B-LUT1-SIGNOFF-RECOVERY-3`.

## Changed current continuation state

- G2B-LUT1 stays `READY_FOR_SIGNOFF_RECOVERY`, but its continuation now
  preserves Group 9, Groups 10–12, and Group 13, implements and validates the
  promoted Group-14 candidate, and proceeds through Groups 15–17 and the
  remaining hard gates.
- G2B-IMPL and G2B-HW blockers now explicitly include pending Group-14
  candidate implementation/validation.
- Product and META mirrors point to revision 6 and META-6 evidence.

## Explicitly preserved truth

- Group-9 and Group-13 promoted methods and retired global checks.
- All ABI/MMIO/interface and R1i state.
- All open OD records, OD-03, and the existing Group-9 and Group-13 unnumbered
  decisions.
- Group 9, Groups 10–12, and Group 13 authoritative PASS results.
- Groups 15–17 pending state.
- G2B-HW `BLOCKED`; no bitstream or hardware proof.
- R-track lifecycle/execution state and all unrelated tracks.
- Historical changelog and evidence references.

## Exact authorized file footprint

The transaction changes exactly 16 SSOT files, listed with pre-write and
post-write identities in `META6_EXACT_FILE_CHANGE_LEDGER.md`. No frozen policy,
template, schema, FPGA source, RTL, active XDC, or R-track source file changes.
