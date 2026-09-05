# AHD v41 META-7R Combined Groups 15–17 Release-Slot Sign-Off Promotion

Engineering gate: PASS. Corrected standalone write authorization: RECOGNIZED.
Frozen contract: VERIFIED. Owner/Architect approval: GRANTED.
PROJECT_STATE_REV_AT_START: 6. PROJECT_STATE_REV_AT_END: 7.
Expected and actual affected SSOT files: 16. SSOT_CONSISTENCY: PASS.
META6_PRECEDENT: VERIFIED at 0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde.
G15–17 authoritative evidence: VERIFIED at fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c.

## Accepted change

Groups 15, 16 and 17 retire GLOBAL_SET_BUS_SKEW_3NS and their global
report_bus_skew from required sign-off. Each promotes
SETTLING_PLUS_STRUCTURAL_CDC with three independently resolved semantic
families. All nine candidate checks PASS; permanent settling cap 6.000 ns;
minimum launch-to-use basis 13.468 ns; gross protocol reserve 7.468 ns.
Routed structural relation PARTIALLY_EQUIVALENT; safety protocol equivalence
PROVEN; SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED YES. Replacement is
SAFER_AND_MORE_SEMANTICALLY_CORRECT. See the promotion and slot-validation
reports for the complete proof requirements and numeric evidence boundary.

RTL_CHANGE_REQUIRED: NO for each slot and overall.
ACTIVE_XDC_CHANGE: AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED for Groups 15–17.
No FPGA source or active production constraints changed. The candidate is
authorized only for the next governed engineering task.

## Preserved state and next task

Groups 9–14: PRESERVE_PASS. Group-9, Group-13 and Group-14 governance
regression: NO. Their methods, numerical bounds, evidence and promotion-time
active-XDC statuses are preserved; historical implementation instructions are
explicitly marked as superseded continuation context. Existing unrelated OD
entries changed: NO. Every earlier decision record in OPEN_DECISIONS.md and
every earlier changelog byte remains intact. No OD number was invented.
The new unnumbered GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY decision is
RESOLVED as PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC.

G2B-LUT1: READY_FOR_SIGNOFF_RECOVERY. Next allowed engineering step:
G2B-LUT1-SIGNOFF-RECOVERY-4 in C:\FPGA\V41_G2B, branch
integration/v41-g2b-onech-c2h, commit bdae16e06fb5b8564763941f530e4ce9e28896c7,
tree e18833d46f7672f851c3cb8239f2f29091378294.
G2B-HW remains BLOCKED. Final routed timing, DRC, CDC disposition,
clocks/resources and the pre-bitstream hard gate remain pending; no G2B
bitstream exists and hardware has not been tested. Qualification, release,
hardware readiness, DMA operation and hardware proof are not claimed.

## Verification

- Corrected contract retained exactly, including Owner/Architect decision.
- SSOT prior manifest 18/18 PASS; META-6 package manifest 9/9 PASS;
  G15–17 package manifest 58/58 PASS; immutable Git blob equality verified.
- Candidate/source provenance: authoritative worktree/branch/commit/tree and
  routed DCP SHA256 EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83 verified from evidence.
- Nine timing rows, family/slot mappings, nonempty collections, independent
  candidate constraints and protocol-margin arithmetic verified.
- JSON and lifecycle validity, CSV 18 rows x 8 columns, revision mirrors,
  18-entry manifest and exact 16-file scope: PASS.
- 364 SSOT consistency assertions passed; detailed outcomes in
  META7_VALIDATION_RESULTS.json. Group-15/16/17 current stale sign-off
  references: NONE. Complete term scan retained in META7_STALE_REFERENCE_SCAN.txt.
- Source heads, trees, branches, tracked file hashes and working-tree status
  verified unchanged. FPGA_AHD had pre-existing untracked files; those are
  recorded, not described as created by this task. V41_G2B is clean.
- FPGA_AHD modified NO; authoritative G2B modified NO; active XDC modified NO;
  Vivado executed NO; bitstream produced NO; hardware/JTAG/PCIe/DMA accessed
  NO; R-track modified NO; HDMI project modified NO; reboot/power-cycle NO.
- SSOT_STALENESS NO_IMPACT; reason AUTHORIZED_SELF_UPDATE.

## Publication and completion boundary

Publish one ordinary commit to lukaszsudul/AHD-diagnostic-evidence main:
Promote AHD v41 Groups 15-17 release-slot sign-off methods to project state rev7

The updated 19-file root project-current-state directory accompanies this
package, following META-6; no redundant nested snapshot is created.
The SSOT manifest and exact change ledger bind those bytes.

The containing commit SHA, actual push outcome and fresh remote byte/hash
read-back are post-commit executor completion actions, following META-6.
This in-commit report does not pre-claim their success or invent its own Git
identity. The executor final response records the exact commit and verified
publication result. Read-back must cover all 19 SSOT files, this complete
META package, remote HEAD, exact 16 changed SSOT paths and unchanged older
evidence subtrees. No historical evidence directory is modified.

First blocker at validated prepublication point: NONE.
Final execution point: HARD STOP AFTER META-7R SSOT PROMOTION.
