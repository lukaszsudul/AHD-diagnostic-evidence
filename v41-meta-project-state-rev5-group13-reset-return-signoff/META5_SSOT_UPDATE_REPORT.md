# AHD v41 META-5 SSOT Update Report

## Result

- Engineering gate: `PASS`.
- Update type: `ARCHITECTURE_CHANGE`.
- Authorization literal: `SSOT WRITE AUTHORIZED`.
- Owner/Architect approval: `GRANTED` by `META-5_TASK_DIRECTIVE`.
- `PROJECT_STATE_REV_AT_START = 4`.
- `PROJECT_STATE_REV_AT_END = 5`.
- Frozen write contract: `VERIFIED`.
- META-4R2 procedural precedent: `VERIFIED` at
  `27dcf152e862c6db88a365328b92c0fd250f04c2`.
- G13-A evidence: `VERIFIED` at
  `10c7c2898d162af8e2262b3f99861c7d560c4557`.
- Expected SSOT files: `16`.
- Actual SSOT files: `16`.
- Unauthorized SSOT files: `0`.
- `SSOT_CONSISTENCY = PASS`.

The publication commit and fresh remote read-back are executor completion
actions. This in-commit report does not invent a not-yet-created containing
commit SHA or pre-complete the remote read-back.

## Frozen-contract preflight

Current frozen governance, update policy, META template, and state schema were
read before mutation. The supported contract is the standalone
`SSOT WRITE AUTHORIZED` literal plus the exact fields `UPDATE_TYPE`,
`EXPECTED_PROJECT_STATE_REV`, `OWNER_ARCHITECT_DECISION`,
`EVIDENCE_REPOSITORY`, `EVIDENCE_COMMIT`, `EVIDENCE_DIRECTORY`, and
`EXPECTED_AFFECTED_FILES`. There is no separate governed `AUTHORIZATION:`
input field.

Both machine mirrors reported revision 4, the 18-entry SSOT manifest passed,
remote `main` matched the local evidence authority, and the calculated
16-file footprint was recorded before the first SSOT edit. The complete input
and preflight are preserved in `META5_WRITE_CONTRACT_RECEIPT.md` and
`META5_EXPECTED_AFFECTED_FILES.md`.

## Accepted Group-13 promotion

Group 13 is `RESET_RETURN_SOURCE_TO_AXI`. The old required method
`GLOBAL_SET_BUS_SKEW_3NS`—the global `set_bus_skew 3.000` relation over seven
sources and 207 destinations—is `RETIRED_FROM_REQUIRED_SIGNOFF`. Its verified
timeout remains historical provenance; the full query was not retried. The
path set is `INVALID_FOR_SKEW_COMPARISON`.

The promoted method is `SETTLING_PLUS_STRUCTURAL_CDC`, decision
`REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`. The exact families are:

1. `RESET_ABANDONED_COUNT_STABLE_PAYLOAD`; and
2. `RESET_COMMIT_PHASE_COMPLETION_BARRIER`.

Both retain the accepted `6.000 ns` absolute datapath-only settling
requirements from G13-A. The unchanged broad source-mailbox `6.000 ns`
relation remains mandatory, including its validated 79-cell supplemental
commit-family coverage; that coverage is not a third semantic family.

The timing half is inseparable from single-edge capture, stable hold until
acknowledgement, two-stage request and acknowledgement synchronization,
two-stage live commit-phase synchronization, matching request/acknowledgement
and live/held phase completion predicates, hard-episode qualification,
reset-return coherency, destination-use sequencing, parity-alias exclusion by
protocol sequencing, atomic epoch/state publication, synchronous reset
observation, and later fresh global CDC closure.

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a safety
relaxation. `RTL_CHANGE_REQUIRED = NO`. Active production XDC was not changed;
`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`. Candidate
authority is `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` from the exact G13-A commit.

## Preserved state and next boundary

- Group-9 method remains `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`, promoted.
- Global Group-9 `report_bus_skew` remains retired from required sign-off.
- `GROUP9_GOVERNANCE_REGRESSION = NO`.
- `GROUPS_10_TO_12 = PRESERVE_PREVIOUS_RESULTS`.
- `GROUPS_14_TO_17 = PENDING_UNCHANGED`.
- The Group-13 decision uses `UNNUMBERED_GOVERNED_DECISION`; no OD number was
  invented and every existing OD record is preserved.
- G2B-LUT1 remains `READY_FOR_SIGNOFF_RECOVERY`, not qualified.
- G2B-HW remains `BLOCKED`, `NOT_STARTED`, and `NOT_PROVEN`.
- `NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-2`.

That next task must preserve Group 9 and Groups 10–12, implement and validate
the promoted Group-13 candidate while retaining the unchanged broad aggregate
relation, then continue Groups 14–17, routed timing, DRC, CDC disposition,
clocks, resources, and the pre-bitstream hard gate. Bitstream generation is
allowed only after PASS and is outside META-5.

## Validation and protection audit

- `PROJECT_STATE.json`: parse and schema/status-enum checks `PASS`.
- `TRACK_STATUS.json`: parse and schema/status-enum checks `PASS`.
- compatibility CSV: exact columns and 18 data rows `PASS`.
- revision and next-gate mirrors: `PASS`.
- evidence references and immutable G13-A artifacts: `PASS`.
- open/decided decision identity and no-invented-OD checks: `PASS`.
- current Group-13 stale required-signoff reference scan: `NONE`.
- Group-9 regression check: `NO`.
- final 18-entry SSOT SHA-256 manifest: `PASS`.
- exact expected-versus-actual SSOT change set: `PASS`.

Protection result: FPGA_AHD source modified `NO`; V41_G2B source/RTL modified
`NO`; active XDC modified `NO`; R-track modified `NO`; Vivado executed `NO`;
bitstream produced `NO`; DUT/hardware/JTAG/PCIe/DMA accessed `NO`; reboot and
power-cycle performed `NO`.

## Publication contract

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Exact commit subject: `Promote AHD v41 Group 13 reset-return sign-off method to project state rev5`.
- Push mode: ordinary fast-forward, never force.
- Required completion: remote HEAD equality plus fresh SHA-256 read-back of
  all 19 SSOT files and all 10 META-5 package files.
