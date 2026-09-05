# META-7R Project-State Diff

Complete zero-context unified diff for the exact 16-file revision-6 to
revision-7 transition. Prior SHA256 and resulting SHA256 are in the ledger.

```diff
--- a/project-current-state/ACTIVE_BASELINES.md
+++ b/project-current-state/ACTIVE_BASELINES.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -119,2 +119,2 @@
-| G2B-IMPL | lifecycle `BLOCKED`; `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; Group-14 candidate-XDC implementation and remaining routed hard gates are pending; no accepted offline-qualified implementation |
-| G2B-LUT1 | lifecycle `PLANNED`; readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-3` |
+| G2B-IMPL | lifecycle `BLOCKED`; `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; Groups 15–17 candidate-XDC implementation and remaining routed hard gates are pending; no accepted offline-qualified implementation |
+| G2B-LUT1 | lifecycle `PLANNED`; readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` |
@@ -139,2 +139,2 @@
-| Group-14 RTL/XDC disposition | `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from evidence commit `9e91315968453e859006077191cd5fc711fc6b96` |
-| Remaining sign-off | `GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`; `GROUP13 = PRESERVE_PASS`; `GROUPS_15_TO_17 = PENDING_UNCHANGED`; G2B-HW remains blocked |
+| HISTORICAL Group-14 promotion-time RTL/XDC disposition | `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from evidence commit `9e91315968453e859006077191cd5fc711fc6b96` |
+| Remaining sign-off | `GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`; `GROUP13 = PRESERVE_PASS`; `GROUPS_15_TO_17 = PROMOTED`; G2B-HW remains blocked |
@@ -146,10 +146,46 @@
-These accepted architecture baselines do not promote a source branch,
-profile implementation, bitstream, DMA result, Gen2 negotiation result,
-throughput result, or Linux/V4L2 implementation. The 17,512 LUT / 84.192%
-PRODUCT estimate remains unmeasured. G2A remains `ACTIVE`; G2B-LUT1 is the
-separate `READY_FOR_SIGNOFF_RECOVERY` gate. Its exact next step is
-`G2B-LUT1-SIGNOFF-RECOVERY-3`; no source or active-XDC change occurs in this
-META-6 transaction. That next engineering task may implement the promoted
-Group-14 candidate XDC, must preserve the authoritative Group-9, Groups
-10–12, and Group-13 PASS results, validate the Group-14 replacement, and then
-continue through Groups 15–17 and the remaining routed hard gates.
+These accepted architecture baselines do not promote source, bitstream, DMA,
+Gen2, throughput or Linux/V4L2 results. Resource estimates remain unmeasured.
+
+## META-7R combined release-slot promotion
+
+Groups 15–17 each promote `SETTLING_PLUS_STRUCTURAL_CDC` with three
+slot-specific semantic families, nine checks total, and a `6.000 ns` absolute
+settling cap. The `13.468 ns` minimum launch-to-use window provides `7.468 ns`
+gross reserve. `SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`,
+`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`, and
+`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`. Each former global
+`GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is
+`RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
+requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
+
--- a/project-current-state/CHANGELOG.md
+++ b/project-current-state/CHANGELOG.md
@@ -513,0 +514,47 @@
+
+
+## PROJECT_STATE_REV 7 — 2026-09-05 — META-7R
+
+Update type: `ARCHITECTURE_CHANGE`. Standalone `SSOT WRITE AUTHORIZED`.
+Expected prior revision: `6`; resulting revision: `7`.
+Owner/Architect approval: `META-7R_TASK_DIRECTIVE`. Corrected contract supersedes the
+rejected META-7 attempt, which changed no files and left revision 6.
+
+Accepted evidence: `v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+META-6 procedural precedent: `0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde`.
+Groups 15, 16 and 17 retire their global `GLOBAL_SET_BUS_SKEW_3NS` /
+`report_bus_skew` from required sign-off and promote independent three-family
+`SETTLING_PLUS_STRUCTURAL_CDC` methods, nine checks total, `6.000 ns` cap,
+`13.468 ns` launch-to-use basis and `7.468 ns` gross reserve.
+Routed relation is `PARTIALLY_EQUIVALENT`; safety protocol equivalence is
+`PROVEN`; independent slot-specific routed checks remain mandatory.
+Decision `GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY` is unnumbered,
+`RESOLVED`, as `PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC`.
+Groups 9–14 PASS and unrelated decisions/content remain preserved.
+RTL change required: `NO`; active XDC: `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`.
+G2B-LUT1 remains `READY_FOR_SIGNOFF_RECOVERY`; next task `G2B-LUT1-SIGNOFF-RECOVERY-4`;
+G2B-HW remains `BLOCKED`. No final sign-off, qualification, release, bitstream,
+hardware readiness, DMA operation or hardware proof is claimed.
+
+Exactly 16 affected files:
+
+- `project-current-state/ACTIVE_BASELINES.md`
+- `project-current-state/CHANGELOG.md`
+- `project-current-state/COMPATIBILITY_MATRIX.csv`
+- `project-current-state/CURRENT_ARCHITECTURE.md`
+- `project-current-state/CURRENT_INTERFACES.md`
+- `project-current-state/CURRENT_REQUIREMENTS.md`
+- `project-current-state/CURRENT_RESOURCE_STATE.md`
+- `project-current-state/CURRENT_STATUS.md`
+- `project-current-state/CURRENT_TRACKS.md`
+- `project-current-state/EVIDENCE_MAP.md`
+- `project-current-state/GOVERNANCE.md`
+- `project-current-state/OPEN_DECISIONS.md`
+- `project-current-state/PROJECT_STATE.json`
+- `project-current-state/README.md`
+- `project-current-state/SHA256_MANIFEST.txt`
+- `project-current-state/TRACK_STATUS.json`
+
+Audit package: `v41-meta-project-state-rev7-groups15-17-release-slot-signoff`. One ordinary non-force promotion commit;
+remote byte/hash read-back is an executor completion action recorded after
+publication. Earlier changelog bytes are preserved unchanged.
--- a/project-current-state/COMPATIBILITY_MATRIX.csv
+++ b/project-current-state/COMPATIBILITY_MATRIX.csv
@@ -7 +7 @@
-"Future G2B implementation","Frozen G2B transport ABI and MMIO contract","Not offline-qualified; G2B-LUT1 is READY_FOR_SIGNOFF_RECOVERY at G2B-LUT1-SIGNOFF-RECOVERY-3; Group-9 PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC and its PASS remain authoritative; Group-13 SETTLING_PLUS_STRUCTURAL_CDC and its PASS remain authoritative; Group-14 RELEASE_SLOT_0_AXI_TO_SOURCE requires SETTLING_PLUS_STRUCTURAL_CDC and its old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew is RETIRED_FROM_REQUIRED_SIGNOFF; no bitstream or hardware result","BLOCKED","6","An implementation could violate frozen bytes, ownership, reset-return or release-slot coherency, protected legacy timing, resource policy, or Linux expectations","Under governed source change implement G2B_G14A_CANDIDATE_CONSTRAINTS.xdc with the three exact 6.000 ns semantic families; preserve Group 9, Groups 10-12, and Group 13 results; validate Group 14; continue Groups 15-17, routed timing, DRC, CDC, clocks/PRODUCT resources, pre-bitstream gate, and only then seek implementation/hardware acceptance","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62:v41-development-g2b-bs1r-single-sink-bus-skew-retry; 4699632c591238fee46ada3b0de37532fddd0b6f:v41-development-g2b-bs2-alternative-timing-equivalence; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit"
+"Future G2B implementation","Frozen G2B transport ABI and MMIO contract","Not offline-qualified; G2B-LUT1 is READY_FOR_SIGNOFF_RECOVERY at G2B-LUT1-SIGNOFF-RECOVERY-4; Group-9 PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC and its PASS remain authoritative; Group-13 SETTLING_PLUS_STRUCTURAL_CDC and its PASS remain authoritative; Group-14 RELEASE_SLOT_0_AXI_TO_SOURCE requires SETTLING_PLUS_STRUCTURAL_CDC and its old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew is RETIRED_FROM_REQUIRED_SIGNOFF; no bitstream or hardware result; Groups 9-14 PASS preserved; Groups 15-17 SETTLING_PLUS_STRUCTURAL_CDC promoted; old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew RETIRED_FROM_REQUIRED_SIGNOFF for each; partial routed equivalence, proven safety protocol, independent slot checks","BLOCKED","7","An implementation could violate frozen bytes, ownership, reset-return or release-slot coherency, protected legacy timing, resource policy, or Linux expectations","In C:/FPGA/V41_G2B at G2B-LUT1-SIGNOFF-RECOVERY-4 implement G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc; validate nine independent 6.000 ns families with structural CDC, 13.468 ns launch-to-use basis and 7.468 ns gross reserve; preserve Groups 9-14 PASS and unrelated constraints; complete routed timing, DRC, CDC, clocks/PRODUCT resources and pre-bitstream gate; no META RTL/XDC/bitstream/hardware action","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62:v41-development-g2b-bs1r-single-sink-bus-skew-retry; 4699632c591238fee46ada3b0de37532fddd0b6f:v41-development-g2b-bs2-alternative-timing-equivalence; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit; fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c:v41-development-g2b-g15-17-release-slot-equivalence-audit"
@@ -13 +13 @@
-"Future G2B hardware","PRODUCT and RESEARCH_DIAGNOSTIC profiles","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; resource equivalence NOT_REQUIRED; research observability equivalence NOT_REQUIRED; G2B-HW is BLOCKED and NOT_PROVEN until Group-14 candidate implementation and validation, remaining final offline sign-off, the pre-bitstream hard gate, and a bitstream candidate exist","BLOCKED","6","A promoted Group-9, Group-13, or Group-14 sign-off method or estimated-fit PRODUCT profile could be mistaken for routed, bitstream, or hardware proof","After complete offline acceptance and a valid bitstream candidate, qualify authorized hardware separately and report the exact selected profile, routed resources, timing, ABI/MMIO behavior and DMA result","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit"
+"Future G2B hardware","PRODUCT and RESEARCH_DIAGNOSTIC profiles","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; resource equivalence NOT_REQUIRED; research observability equivalence NOT_REQUIRED; G2B-HW is BLOCKED and NOT_PROVEN until Groups 15-17 candidate implementation and validation, remaining final offline sign-off, the pre-bitstream hard gate, and a bitstream candidate exist; Groups 9-14 PASS preserved; Groups 15-17 SETTLING_PLUS_STRUCTURAL_CDC promoted; old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew RETIRED_FROM_REQUIRED_SIGNOFF for each; partial routed equivalence, proven safety protocol, independent slot checks","BLOCKED","7","A promoted Group-9, Group-13, or Group-14 sign-off method or estimated-fit PRODUCT profile could be mistaken for routed, bitstream, or hardware proof","After complete offline acceptance and a valid bitstream candidate, qualify authorized hardware separately and report the exact selected profile, routed resources, timing, ABI/MMIO behavior and DMA result","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit; fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c:v41-development-g2b-g15-17-release-slot-equivalence-audit"
--- a/project-current-state/CURRENT_ARCHITECTURE.md
+++ b/project-current-state/CURRENT_ARCHITECTURE.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -48,2 +48,2 @@
-| Application record-to-C2H plane | `BLOCKED` | `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` | Group-14 candidate-XDC implementation and complete final routed sign-off remain pending; no offline-qualified implementation |
-| G2B-LUT1 | `PLANNED` | `READY_FOR_SIGNOFF_RECOVERY / SIGNOFF_RECOVERY_PENDING` | Authorized next gate is `G2B-LUT1-SIGNOFF-RECOVERY-3`; active XDC is not changed by META-6 |
+| Application record-to-C2H plane | `BLOCKED` | `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` | Groups 15–17 candidate-XDC implementation and complete final routed sign-off remain pending; no offline-qualified implementation |
+| G2B-LUT1 | `PLANNED` | `READY_FOR_SIGNOFF_RECOVERY / SIGNOFF_RECOVERY_PENDING` | Authorized next gate is `G2B-LUT1-SIGNOFF-RECOVERY-4`; active XDC is not changed by META-6 |
@@ -159 +159 @@
-not required to be repeated by `G2B-LUT1-SIGNOFF-RECOVERY-3`. The retired
+not required to be repeated by `G2B-LUT1-SIGNOFF-RECOVERY-4`. The retired
@@ -277,0 +278,3 @@
+HISTORICAL META-6 promotion-time implementation boundary (SUPERSEDED
+as a current work instruction by revision 7; accepted Group-14 method unchanged):
+
@@ -286,0 +290,104 @@
+
+### Combined Groups 15–17 release-slot sign-off — revision 7
+
+Owner/Architect decision `META-7R_TASK_DIRECTIVE` promotes
+`PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` from `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`COMBINED_PROMOTION_SCOPE = GROUPS_15_16_17`.
+
+Group 15 `RELEASE_SLOT_1_AXI_TO_SOURCE`, Group 16
+`RELEASE_SLOT_2_AXI_TO_SOURCE`, and Group 17 `RELEASE_SLOT_3_AXI_TO_SOURCE`
+each retire `GLOBAL_SET_BUS_SKEW_3NS` as `RETIRED_FROM_REQUIRED_SIGNOFF`.
+The historical scope of each was 56 sources / 20 destinations. Group 15 mixed
+normal-state, fault/history and other-slot roles and omitted reset-overlap
+accounting endpoints. Group 16 mixed semantically different destination
+roles. Group 17 likewise did not describe one coherent relative-skew bus.
+All three path sets are `INVALID_FOR_SKEW_COMPARISON`; their global
+`report_bus_skew` queries are retired from every current required recipe.
+
+Each replacement is `SETTLING_PLUS_STRUCTURAL_CDC`, state `PROMOTED`:
+
+| Group | Slot | Semantic family | Permanent settling cap | Validated collection |
+|---|---|---|---|---|
+| 15 | 1 | `RELEASE_SLOT1_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 15 | 1 | `RELEASE_SLOT1_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 15 | 1 | `RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 16 | 2 | `RELEASE_SLOT2_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 16 | 2 | `RELEASE_SLOT2_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 16 | 2 | `RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 17 | 3 | `RELEASE_SLOT3_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 17 | 3 | `RELEASE_SLOT3_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 17 | 3 | `RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+
+One architecture covers three independently validated slot implementations,
+three families each, and nine independent timing checks. All nine candidate
+checks passed; runtime is `PRACTICAL`; replacement equivalence is
+`SAFER_AND_MORE_SEMANTICALLY_CORRECT`.
+
+`SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`;
+`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`;
+`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`.
+Routed cones are not exact copies of slot 0 or one another: mapped depths,
+LUT input pins and placement differ. Source and destination collections must
+be resolved independently for each slot and each routed cone validated.
+Shared containment/reset destination cells do not merge the independently
+scoped source-to-destination relations.
+
+The permanent requirement is `SETTLING_CAP = 6.000 ns` absolute datapath-only
+for each family. The basis is a `6.734 ns` destination clock period, at least
+two qualifying destination periods (`13.468 ns` launch-to-use window), and
+`7.468 ns` gross protocol reserve. This common cap is retained only after
+independent proof of each slot's clock period, qualifying synchronization
+depth, destination-use phase, stable-data lifetime and mismatch/reset/
+retirement semantics. Route-specific actual delays and slacks remain evidence,
+not permanent architectural bounds.
+
+The structural proof is inseparable from timing: hold the 56-bit token
+(24 generation bits and 32 epoch bits), launch token and release toggle on
+the same accepted final AXI beat, retain two direct `ASYNC_REG` release-toggle
+stages, and permit normal destination use only after the synchronized event.
+Hold the payload through consumption and prohibit premature overwrite or
+slot reuse. Generation/epoch/current-reset-epoch and ownership mismatch must
+fail closed, latch containment and disable admission.
+
+Reset-overlap accounting uses its separate two-stage transport-request
+synchronizer and the same-episode token. Capture the same-edge release phase,
+prevent stale release across reset, and require the independently synchronized
+release vector and ownership phase to match their captures before coherent
+retirement and acknowledgement. Each slot retains all eight proven safety
+invariants; its CDC disposition is `PASS_WITH_DISPOSITION`.
+
+The candidate creates no release-slot bus-skew relation. Remaining focused
+TIMING-34/TIMING-39 warnings arise from other preserved relations and remain
+subject to normal final sign-off disposition, outside this architecture
+decision. Project-wide warning closure is not claimed.
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
@@ -334,2 +441,2 @@
-  required sign-off; candidate-XDC implementation and validation remain the
-  next governed work.
+  required sign-off; its authoritative PASS is preserved. Groups 15–17
+  candidate implementation and validation are the next governed work.
@@ -337 +444 @@
-  `G2B-LUT1-SIGNOFF-RECOVERY-3`.
+  `G2B-LUT1-SIGNOFF-RECOVERY-4`.
--- a/project-current-state/CURRENT_INTERFACES.md
+++ b/project-current-state/CURRENT_INTERFACES.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -322,0 +323,3 @@
+HISTORICAL META-6 promotion-time implementation boundary (SUPERSEDED
+as a current work instruction by revision 7; accepted Group-14 method unchanged):
+
@@ -332,0 +336,104 @@
+
+#### Combined Groups 15–17 release-slot sign-off — revision 7
+
+Owner/Architect decision `META-7R_TASK_DIRECTIVE` promotes
+`PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` from `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`COMBINED_PROMOTION_SCOPE = GROUPS_15_16_17`.
+
+Group 15 `RELEASE_SLOT_1_AXI_TO_SOURCE`, Group 16
+`RELEASE_SLOT_2_AXI_TO_SOURCE`, and Group 17 `RELEASE_SLOT_3_AXI_TO_SOURCE`
+each retire `GLOBAL_SET_BUS_SKEW_3NS` as `RETIRED_FROM_REQUIRED_SIGNOFF`.
+The historical scope of each was 56 sources / 20 destinations. Group 15 mixed
+normal-state, fault/history and other-slot roles and omitted reset-overlap
+accounting endpoints. Group 16 mixed semantically different destination
+roles. Group 17 likewise did not describe one coherent relative-skew bus.
+All three path sets are `INVALID_FOR_SKEW_COMPARISON`; their global
+`report_bus_skew` queries are retired from every current required recipe.
+
+Each replacement is `SETTLING_PLUS_STRUCTURAL_CDC`, state `PROMOTED`:
+
+| Group | Slot | Semantic family | Permanent settling cap | Validated collection |
+|---|---|---|---|---|
+| 15 | 1 | `RELEASE_SLOT1_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 15 | 1 | `RELEASE_SLOT1_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 15 | 1 | `RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 16 | 2 | `RELEASE_SLOT2_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 16 | 2 | `RELEASE_SLOT2_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 16 | 2 | `RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 17 | 3 | `RELEASE_SLOT3_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 17 | 3 | `RELEASE_SLOT3_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 17 | 3 | `RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+
+One architecture covers three independently validated slot implementations,
+three families each, and nine independent timing checks. All nine candidate
+checks passed; runtime is `PRACTICAL`; replacement equivalence is
+`SAFER_AND_MORE_SEMANTICALLY_CORRECT`.
+
+`SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`;
+`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`;
+`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`.
+Routed cones are not exact copies of slot 0 or one another: mapped depths,
+LUT input pins and placement differ. Source and destination collections must
+be resolved independently for each slot and each routed cone validated.
+Shared containment/reset destination cells do not merge the independently
+scoped source-to-destination relations.
+
+The permanent requirement is `SETTLING_CAP = 6.000 ns` absolute datapath-only
+for each family. The basis is a `6.734 ns` destination clock period, at least
+two qualifying destination periods (`13.468 ns` launch-to-use window), and
+`7.468 ns` gross protocol reserve. This common cap is retained only after
+independent proof of each slot's clock period, qualifying synchronization
+depth, destination-use phase, stable-data lifetime and mismatch/reset/
+retirement semantics. Route-specific actual delays and slacks remain evidence,
+not permanent architectural bounds.
+
+The structural proof is inseparable from timing: hold the 56-bit token
+(24 generation bits and 32 epoch bits), launch token and release toggle on
+the same accepted final AXI beat, retain two direct `ASYNC_REG` release-toggle
+stages, and permit normal destination use only after the synchronized event.
+Hold the payload through consumption and prohibit premature overwrite or
+slot reuse. Generation/epoch/current-reset-epoch and ownership mismatch must
+fail closed, latch containment and disable admission.
+
+Reset-overlap accounting uses its separate two-stage transport-request
+synchronizer and the same-episode token. Capture the same-edge release phase,
+prevent stale release across reset, and require the independently synchronized
+release vector and ownership phase to match their captures before coherent
+retirement and acknowledgement. Each slot retains all eight proven safety
+invariants; its CDC disposition is `PASS_WITH_DISPOSITION`.
+
+The candidate creates no release-slot bus-skew relation. Remaining focused
+TIMING-34/TIMING-39 warnings arise from other preserved relations and remain
+subject to normal final sign-off disposition, outside this architecture
+decision. Project-wide warning closure is not claimed.
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
--- a/project-current-state/CURRENT_REQUIREMENTS.md
+++ b/project-current-state/CURRENT_REQUIREMENTS.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -89 +89 @@
-| `REQ-G2B-GROUP14-RELEASE-SLOT0-SIGNOFF` | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` requires `SETTLING_PLUS_STRUCTURAL_CDC`: exactly three semantic families with `6.000 ns` absolute datapath-only settling, held 56-bit generation/epoch token lifetime, same-edge token/toggle ordering, two-stage release-toggle synchronization for normal use, two-stage transport-request synchronization for reset accounting, fail-closed generation/epoch/ownership identity, captured release-phase retirement/completion barrier, destination-use ordering, and reset/release coherency | `FROZEN` | Method promoted from G14-A; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO`; active XDC update is authorized for `G2B-LUT1-SIGNOFF-RECOVERY-3` but not yet implemented |
+| `REQ-G2B-GROUP14-RELEASE-SLOT0-SIGNOFF` | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` requires `SETTLING_PLUS_STRUCTURAL_CDC`: exactly three semantic families with `6.000 ns` absolute datapath-only settling, held 56-bit generation/epoch token lifetime, same-edge token/toggle ordering, two-stage release-toggle synchronization for normal use, two-stage transport-request synchronization for reset accounting, fail-closed generation/epoch/ownership identity, captured release-phase retirement/completion barrier, destination-use ordering, and reset/release coherency | `FROZEN` | Method promoted from G14-A; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO`; HISTORICAL META-6 active-XDC boundary: authorized for recovery-3, not yet implemented at promotion; current Group-14 result `PRESERVE_PASS` |
@@ -127 +127 @@
-`G2B-LUT1-SIGNOFF-RECOVERY-3` unless later evidence invalidates it.
+`G2B-LUT1-SIGNOFF-RECOVERY-4` unless later evidence invalidates it.
@@ -170 +170 @@
-`G2B-LUT1-SIGNOFF-RECOVERY-3` must not repeat or alter Group 13 unless later
+`G2B-LUT1-SIGNOFF-RECOVERY-4` must not repeat or alter Group 13 unless later
@@ -229,0 +230,3 @@
+HISTORICAL META-6 promotion-time implementation boundary (SUPERSEDED
+as a current work instruction by revision 7; accepted Group-14 method unchanged):
+
@@ -241,0 +245,104 @@
+
+### Combined Groups 15–17 release-slot sign-off — revision 7
+
+Owner/Architect decision `META-7R_TASK_DIRECTIVE` promotes
+`PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` from `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`COMBINED_PROMOTION_SCOPE = GROUPS_15_16_17`.
+
+Group 15 `RELEASE_SLOT_1_AXI_TO_SOURCE`, Group 16
+`RELEASE_SLOT_2_AXI_TO_SOURCE`, and Group 17 `RELEASE_SLOT_3_AXI_TO_SOURCE`
+each retire `GLOBAL_SET_BUS_SKEW_3NS` as `RETIRED_FROM_REQUIRED_SIGNOFF`.
+The historical scope of each was 56 sources / 20 destinations. Group 15 mixed
+normal-state, fault/history and other-slot roles and omitted reset-overlap
+accounting endpoints. Group 16 mixed semantically different destination
+roles. Group 17 likewise did not describe one coherent relative-skew bus.
+All three path sets are `INVALID_FOR_SKEW_COMPARISON`; their global
+`report_bus_skew` queries are retired from every current required recipe.
+
+Each replacement is `SETTLING_PLUS_STRUCTURAL_CDC`, state `PROMOTED`:
+
+| Group | Slot | Semantic family | Permanent settling cap | Validated collection |
+|---|---|---|---|---|
+| 15 | 1 | `RELEASE_SLOT1_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 15 | 1 | `RELEASE_SLOT1_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 15 | 1 | `RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 16 | 2 | `RELEASE_SLOT2_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 16 | 2 | `RELEASE_SLOT2_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 16 | 2 | `RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 17 | 3 | `RELEASE_SLOT3_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+| 17 | 3 | `RELEASE_SLOT3_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
+| 17 | 3 | `RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
+
+One architecture covers three independently validated slot implementations,
+three families each, and nine independent timing checks. All nine candidate
+checks passed; runtime is `PRACTICAL`; replacement equivalence is
+`SAFER_AND_MORE_SEMANTICALLY_CORRECT`.
+
+`SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`;
+`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`;
+`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`.
+Routed cones are not exact copies of slot 0 or one another: mapped depths,
+LUT input pins and placement differ. Source and destination collections must
+be resolved independently for each slot and each routed cone validated.
+Shared containment/reset destination cells do not merge the independently
+scoped source-to-destination relations.
+
+The permanent requirement is `SETTLING_CAP = 6.000 ns` absolute datapath-only
+for each family. The basis is a `6.734 ns` destination clock period, at least
+two qualifying destination periods (`13.468 ns` launch-to-use window), and
+`7.468 ns` gross protocol reserve. This common cap is retained only after
+independent proof of each slot's clock period, qualifying synchronization
+depth, destination-use phase, stable-data lifetime and mismatch/reset/
+retirement semantics. Route-specific actual delays and slacks remain evidence,
+not permanent architectural bounds.
+
+The structural proof is inseparable from timing: hold the 56-bit token
+(24 generation bits and 32 epoch bits), launch token and release toggle on
+the same accepted final AXI beat, retain two direct `ASYNC_REG` release-toggle
+stages, and permit normal destination use only after the synchronized event.
+Hold the payload through consumption and prohibit premature overwrite or
+slot reuse. Generation/epoch/current-reset-epoch and ownership mismatch must
+fail closed, latch containment and disable admission.
+
+Reset-overlap accounting uses its separate two-stage transport-request
+synchronizer and the same-episode token. Capture the same-edge release phase,
+prevent stale release across reset, and require the independently synchronized
+release vector and ownership phase to match their captures before coherent
+retirement and acknowledgement. Each slot retains all eight proven safety
+invariants; its CDC disposition is `PASS_WITH_DISPOSITION`.
+
+The candidate creates no release-slot bus-skew relation. Remaining focused
+TIMING-34/TIMING-39 warnings arise from other preserved relations and remain
+subject to normal final sign-off disposition, outside this architecture
+decision. Project-wide warning closure is not claimed.
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
--- a/project-current-state/CURRENT_RESOURCE_STATE.md
+++ b/project-current-state/CURRENT_RESOURCE_STATE.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -46 +46 @@
-| Profile source/sign-off recovery | `PLANNED` | G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-3`; no source or active-XDC change implemented by META-6 |
+| Profile source/sign-off recovery | `PLANNED` | G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4`; no source or active-XDC change implemented by META-7R |
@@ -61 +61 @@
-achieved. `G2B-LUT1-SIGNOFF-RECOVERY-3`/G2B-IMPL must measure actual post-route
+achieved. `G2B-LUT1-SIGNOFF-RECOVERY-4`/G2B-IMPL must measure actual post-route
@@ -66,3 +66,4 @@
-Group 9 PASS, Groups 10–12 PASS, and Group 13 PASS are preserved; the Group-14
-candidate implementation and validation, Groups 15–17, and remaining routed
-resource hard gate are still pending.
+META-7R also changes no measured or estimated resource value. Groups 9–14
+PASS are preserved; Groups 15–17 candidate implementation and validation and
+the remaining routed resource hard gate are pending. The combined promotion
+uses nine independent `6.000 ns` checks; the next task is recovery-4.
--- a/project-current-state/CURRENT_STATUS.md
+++ b/project-current-state/CURRENT_STATUS.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -7,2 +7,2 @@
-promotion of the accepted G14-A release-slot CDC architecture and Group-14
-sign-off method through META-6
+promotion of the accepted combined Groups 15–17 release-slot CDC architecture
+and sign-off methods through META-7R
@@ -33 +33 @@
-| Product | G2B-IMPL | `BLOCKED` | Sign-off recovery pending; not offline-qualified | No G2B bitstream or hardware result; Group-14 candidate XDC is authorized but not implemented; remaining routed hard gates are pending |
+| Product | G2B-IMPL | `BLOCKED` | Sign-off recovery pending; not offline-qualified | No G2B bitstream or hardware result; Groups 15–17 candidate XDC is authorized but not implemented; remaining routed hard gates are pending |
@@ -35 +35 @@
-| Product | G2B-LUT1 | `PLANNED` | readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-3` | Preserve Group 9, Groups 10–12, and Group 13 authoritative results; implement and validate the promoted Group-14 candidate, then continue Groups 15–17 and remaining routed hard gates |
+| Product | G2B-LUT1 | `PLANNED` | readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` | Preserve Groups 9–14 authoritative PASS; implement and validate all nine Groups 15–17 candidate checks, then continue remaining routed hard gates |
@@ -45,0 +46,45 @@
+
+| META | META-7R | `ACCEPTED` | Combined Groups 15–17 release-slot methods promoted | SSOT only; no RTL, active XDC, bitstream or hardware action |
+
+## META-7R combined release-slot promotion
+
+Groups 15–17 each promote `SETTLING_PLUS_STRUCTURAL_CDC` with three
+slot-specific semantic families, nine checks total, and a `6.000 ns` absolute
+settling cap. The `13.468 ns` minimum launch-to-use window provides `7.468 ns`
+gross reserve. `SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`,
+`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`, and
+`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`. Each former global
+`GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is
+`RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
+requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
@@ -63 +108 @@
-| Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-14 `report_bus_skew` retired from required sign-off; `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` |
+| Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off (active-XDC literal is HISTORICAL at META-6 promotion; current result `PRESERVE_PASS`) | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-14 `report_bus_skew` retired from required sign-off; `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` |
--- a/project-current-state/CURRENT_TRACKS.md
+++ b/project-current-state/CURRENT_TRACKS.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -9 +9 @@
-| G-track | Product FPGA integration, data plane, qualification, and release architecture | G2B-LUT0 resource architecture | G2A remains separately active | `G2B-LUT1-SIGNOFF-RECOVERY-3` and complete offline requalification | `ACTIVE`; G2B-IMPL sign-off recovery pending |
+| G-track | Product FPGA integration, data plane, qualification, and release architecture | G2B-LUT0 resource architecture | G2A remains separately active | `G2B-LUT1-SIGNOFF-RECOVERY-4` and complete offline requalification | `ACTIVE`; G2B-IMPL sign-off recovery pending |
@@ -12 +12 @@
-| META track | Maintain current project truth, governance, provenance, revisions, and compatibility | META-6 | none | Next explicitly authorized accepted-state change | `ACCEPTED` |
+| META track | Maintain current project truth, governance, provenance, revisions, and compatibility | META-7R | none | Next explicitly authorized accepted-state change | `ACCEPTED` |
@@ -34 +34 @@
-  no bitstream exists; Group-14 candidate implementation and validation remain
+  no bitstream exists; Groups 15–17 candidate implementation and validation remain
@@ -39 +39 @@
-  `G2B-LUT1-SIGNOFF-RECOVERY-3`.
+  `G2B-LUT1-SIGNOFF-RECOVERY-4`.
@@ -71,2 +71,2 @@
-  sign-off, `RTL_CHANGE_REQUIRED = NO`, and active XDC implementation remains
-  an authorized next step;
+  sign-off and `RTL_CHANGE_REQUIRED = NO`; its HISTORICAL META-6 active-XDC
+  authorization remains recorded; current Group-14 PASS is preserved;
@@ -74,14 +74,37 @@
-- `GROUPS_15_TO_17 = PENDING_UNCHANGED`.
-
-### Next decision
-
-`G2B-LUT1-SIGNOFF-RECOVERY-3` may implement the accepted
-`G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` under the governed source-change
-procedure. It must preserve Group 9 PASS, Groups 10–12 PASS, and Group 13 PASS,
-validate Group 14 with the promoted settling-plus-structural-CDC method, then
-continue Groups 15, 16, and 17, routed setup/hold timing, DRC, CDC disposition,
-clocks, PRODUCT resources, and the pre-bitstream hard gate before any bitstream
-or hardware step. The retired global Group-9, Group-13, and Group-14
-`report_bus_skew` queries are not required. The PRODUCT hard gate remains
-routed LUT `<=90%`, with a preferred `80–85%` target; the 84.192% planning
-estimate is not an achieved result.
+- `GROUPS_15_TO_17 = PROMOTED`.
+
+### Next decision
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
+
+The PRODUCT hard gate remains routed LUT `<=90%`, with a preferred
+`80–85%` target; the 84.192% planning estimate is not an achieved result.
@@ -136 +159 @@
-- No accepted or active Linux gate exists at revision 6.
+- No accepted or active Linux gate exists at revision 7.
@@ -188,0 +212,3 @@
+META-7R promotes the combined Groups 15–17 architecture through one
+unnumbered governed decision while preserving Groups 9–14 PASS.
+
@@ -203 +229 @@
-After revision-6 publication, the next update begins only when a separate task
+After revision-7 publication, the next update begins only when a separate task
--- a/project-current-state/EVIDENCE_MAP.md
+++ b/project-current-state/EVIDENCE_MAP.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -5,2 +5,2 @@
-Evidence `main` accepted-evidence anchor used for revision 6:
-`9e91315968453e859006077191cd5fc711fc6b96`
+Evidence `main` accepted-evidence anchor used for revision 7:
+`fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`
@@ -49,0 +50,5 @@
+
+Revision 7 uses `META-7R_TASK_DIRECTIVE` and the corrected standalone authorization
+to promote Groups 15–17 from `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`. Earlier revision paragraphs above
+are HISTORICAL acceptance boundaries; no final engineering/hardware result is
+promoted.
@@ -194 +199 @@
-| `STMT-G2B-PRE` | G2B-PRE architecture freeze is accepted and its contract input was ready for implementation from the accepted G2A input base | `ACCEPTED` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; architecture-freeze report, state, consistency report, and decision log at `e8ab101...` | Engineering `PASS`, exact G2A input identity, complete ABI/MMIO decisions, and Linux consumer input contract | Historical contract-input readiness is not current G2B-IMPL readiness; current G2B-LUT1 readiness is `READY_FOR_SIGNOFF_RECOVERY` at `G2B-LUT1-SIGNOFF-RECOVERY-3` |
+| `STMT-G2B-PRE` | G2B-PRE architecture freeze is accepted and its contract input was ready for implementation from the accepted G2A input base | `ACCEPTED` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; architecture-freeze report, state, consistency report, and decision log at `e8ab101...` | Engineering `PASS`, exact G2A input identity, complete ABI/MMIO decisions, and Linux consumer input contract | Historical contract-input readiness is not current G2B-IMPL readiness; current G2B-LUT1 readiness is `READY_FOR_SIGNOFF_RECOVERY` at `G2B-LUT1-SIGNOFF-RECOVERY-4` |
@@ -198 +203 @@
-| `STMT-G2B-IMPL` | G2B-IMPL remains not offline-qualified; G2B-LUT1 is `READY_FOR_SIGNOFF_RECOVERY` and the next gate is `G2B-LUT1-SIGNOFF-RECOVERY-3` | `BLOCKED` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-LUT0`, `EVID-G2B-BS3`, `EVID-G2B-G13A`, and `EVID-G2B-G14A` | Accepted resource architecture; promoted Group-9, Group-13, and Group-14 sign-off methods; exact continuation boundary | Group-14 active XDC is not yet updated; no final sign-off, bitstream, or hardware proof |
+| `STMT-G2B-IMPL` | G2B-IMPL remains not offline-qualified; G2B-LUT1 is `READY_FOR_SIGNOFF_RECOVERY` and the next gate is `G2B-LUT1-SIGNOFF-RECOVERY-4` | `BLOCKED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-LUT0`, `EVID-G2B-BS3`, `EVID-G2B-G13A`, and `EVID-G2B-G14A`, `EVID-G2B-G15-17-EQ` | Accepted resource architecture; promoted Group-9, Group-13, and Group-14 sign-off methods; exact continuation boundary | Groups 15–17 active XDC is not yet updated; no final sign-off, bitstream, or hardware proof |
@@ -203 +208 @@
-| `STMT-GROUP14-SIGNOFF` | Current Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` method is `SETTLING_PLUS_STRUCTURAL_CDC`; its global `GLOBAL_SET_BUS_SKEW_3NS` and `report_bus_skew` are retired from required sign-off | `ACCEPTED` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-G14A` at `9e91315968453e859006077191cd5fc711fc6b96` | 56/20 scope, verified timeout, invalid skew comparison, three exact `6.000 ns` families, and complete release/reset structural CDC proof | `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; no safety relaxation; `RTL_CHANGE_REQUIRED = NO`; active XDC pending |
+| `STMT-GROUP14-SIGNOFF` | Current Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` method is `SETTLING_PLUS_STRUCTURAL_CDC`; its global `GLOBAL_SET_BUS_SKEW_3NS` and `report_bus_skew` are retired from required sign-off | `ACCEPTED` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-G14A` at `9e91315968453e859006077191cd5fc711fc6b96` | 56/20 scope, verified timeout, invalid skew comparison, three exact `6.000 ns` families, and complete release/reset structural CDC proof | `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; no safety relaxation; `RTL_CHANGE_REQUIRED = NO`; HISTORICAL META-6 active XDC pending at promotion; current result `PRESERVE_PASS` |
@@ -205 +210 @@
-| `STMT-G2B-HW` | G2B-HW is `BLOCKED` | `BLOCKED` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-BS3`, `EVID-G2B-G13A`, `EVID-G2B-G14A`, and current SSOT | Group-14 candidate implementation, remaining final offline sign-off, and bitstream candidate are absent | No hardware, qualification, release, or bitstream claim |
+| `STMT-G2B-HW` | G2B-HW is `BLOCKED` | `BLOCKED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-BS3`, `EVID-G2B-G13A`, `EVID-G2B-G14A`, `EVID-G2B-G15-17-EQ`, and current SSOT | Groups 15–17 candidate implementation, remaining final offline sign-off, and bitstream candidate are absent | No hardware, qualification, release, or bitstream claim |
@@ -207 +212 @@
-| `STMT-GROUPS-15-17` | `GROUPS_15_TO_17 = PENDING_UNCHANGED` | `FROZEN` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-G14A` state and continuation plan | Groups 15–17 were not executed or reinterpreted by G14-A | No relaxation; continue them after Group-14 replacement validation |
+| `STMT-GROUPS-15-17` | Groups 15–17 `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global methods retired; nine `6.000 ns` checks | `ACCEPTED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-G15-17-EQ` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c` | Partial routed equivalence; proven safety protocol; independent slot checks; 13.468 ns window and 7.468 ns reserve | Active XDC authorized but not implemented; no final sign-off or hardware proof |
@@ -241,0 +247,22 @@
+
+## Revision-7 authoritative combined evidence
+
+| Evidence ID | Immutable commit | Directory tree | Directory |
+|---|---|---|---|
+| `EVID-G2B-G15-17-EQ` | `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c` | `d3f336f5067e7e4814c65838da00aa50d4ab0425` | `v41-development-g2b-g15-17-release-slot-equivalence-audit` |
+
+Required sources: `G2B_G15_17_EQ_STATE.json`, `G2B_G15_17_EQ_CANDIDATE_RESULTS.csv`,
+`G2B_G15_17_EQ_PROTOCOL_TIMING_MARGINS.csv`, `G2B_G15_17_EQ_FAMILIES.csv`,
+`G2B_G15_17_EQ_CDC_COMPARISON.md`, `G2B_G15_17_EQ_SAFETY_INVARIANT_COMPARISON.md`,
+`G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc`, and
+`G2B_G15_17_EQ_STRUCTURAL_EQUIVALENCE_MATRIX.csv`.
+
+Supports `STMT-GROUPS-15-17`, `STMT-GROUPS15-17-DECISION`, `STMT-G2B-IMPL`,
+`STMT-G2B-HW` and preservation of Groups 9–14 PASS. Candidate SHA-256:
+`BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F`.
+Decision subject `GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY` is `RESOLVED`
+as `PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC`; record form is
+`UNNUMBERED_GOVERNED_DECISION`. Route-specific actual/slack values remain
+evidence only. See `CURRENT_ARCHITECTURE.md` for the complete accepted basis.
+META-6 precedent: `0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde` /
+`v41-meta-project-state-rev6-group14-release-slot-signoff` (HISTORICAL).
--- a/project-current-state/GOVERNANCE.md
+++ b/project-current-state/GOVERNANCE.md
@@ -4 +4 @@
-Project-state revision governed: `6`
+Project-state revision governed: `7`
--- a/project-current-state/OPEN_DECISIONS.md
+++ b/project-current-state/OPEN_DECISIONS.md
@@ -3 +3 @@
-`PROJECT_STATE_REV = 6`
+`PROJECT_STATE_REV = 7`
@@ -23,0 +24,21 @@
+
+## Decided at project-state revision 7 — Groups 15–17
+
+| Decision subject | Decision | Lifecycle status | Decision state | Covered groups |
+|---|---|---|---|---|
+| `GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY` | `PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` | `ACCEPTED` | `RESOLVED` | 15, 16, 17 |
+
+Record form: `UNNUMBERED_GOVERNED_DECISION`. Owner/Architect approval is
+granted by `META-7R_TASK_DIRECTIVE`; accepted evidence is `v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+Routed cones are `PARTIALLY_EQUIVALENT`; safety-protocol equivalence is
+`PROVEN`; every slot retains independent timing collections and routed
+checks. The global methods are retired; each slot's three-family replacement
+is promoted with a `6.000 ns` cap. RTL change required is `NO`.
+Active XDC is `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups 15–17.
+Next task is `G2B-LUT1-SIGNOFF-RECOVERY-4`; Groups 9–14 PASS are preserved and G2B-HW is `BLOCKED`.
+
+`EXISTING_UNRELATED_OD_ENTRIES_CHANGED = NO`. All earlier decision records
+below remain verbatim. Their implementation-pending and Groups 15–17 pending
+statements describe HISTORICAL promotion-time context and are SUPERSEDED as
+current continuation instructions by this revision-7 decision. Their accepted
+methods, numerical bounds and evidence identities remain authoritative.
--- a/project-current-state/PROJECT_STATE.json
+++ b/project-current-state/PROJECT_STATE.json
@@ -3 +3 @@
-  "project_state_revision": 6,
+  "project_state_revision": 7,
@@ -6 +6 @@
-  "last_update": "2026-09-03",
+  "last_update": "2026-09-05",
@@ -8 +8 @@
-  "acceptance_authorization": "META-6_TASK_DIRECTIVE",
+  "acceptance_authorization": "META-7R_TASK_DIRECTIVE",
@@ -12,4 +12,4 @@
-  "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-  "source_evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit",
-  "expected_previous_project_state_revision": 5,
-  "write_contract_receipt": "v41-meta-project-state-rev6-group14-release-slot-signoff/META6_WRITE_CONTRACT_RECEIPT.md",
+  "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+  "source_evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+  "expected_previous_project_state_revision": 6,
+  "write_contract_receipt": "v41-meta-project-state-rev7-groups15-17-release-slot-signoff/META7_FROZEN_WRITE_CONTRACT_RECEIPT.md",
@@ -43 +43 @@
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3",
+      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
@@ -74,2 +74,2 @@
-        "scope": "PRESERVE_PROMOTED_GROUP9_AND_GROUPS10_TO_12_AND_PROMOTED_GROUP13_APPLY_PROMOTED_GROUP14_AND_COMPLETE_ROUTED_SIGNOFF",
-        "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3",
+        "scope": "PRESERVE_GROUPS9_TO_14_PASS_APPLY_PROMOTED_GROUPS15_TO_17_AND_COMPLETE_ROUTED_SIGNOFF",
+        "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
@@ -81 +81,2 @@
-          "GROUP13"
+          "GROUP13",
+          "GROUP14"
@@ -84,2 +85,2 @@
-        "decision_source": "META-6_TASK_DIRECTIVE",
-        "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96"
+        "decision_source": "META-7R_TASK_DIRECTIVE",
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
@@ -119,4 +120,4 @@
-      "current_task": "META-6",
-      "acceptance_basis": "OWNER_ARCHITECT_PROMOTED_RELEASE_SLOT_CDC_GROUP14_SIGNOFF_METHOD",
-      "decision_source": "META-6_TASK_DIRECTIVE",
-      "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96"
+      "current_task": "META-7R",
+      "acceptance_basis": "OWNER_ARCHITECT_PROMOTED_COMBINED_GROUPS15_TO_17_RELEASE_SLOT_SIGNOFF_METHODS",
+      "decision_source": "META-7R_TASK_DIRECTIVE",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
@@ -394 +395 @@
-      "groups_15_to_17": "PENDING_UNCHANGED",
+      "groups_15_to_17": "PROMOTED",
@@ -440 +441 @@
-      "groups_15_to_17": "PENDING_UNCHANGED",
+      "groups_15_to_17": "PROMOTED",
@@ -445 +446,97 @@
-      "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96"
+      "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
+      "active_xdc_change_context": "HISTORICAL_META6_PROMOTION_TIME_BOUNDARY_CURRENT_GROUP14_PASS_PRESERVED",
+      "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
+      "reexecution": "DO_NOT_REPEAT"
+    },
+    {
+      "id": "REQ-G2B-GROUP15-RELEASE-SLOT-SIGNOFF",
+      "status": "FROZEN",
+      "requirement": "SETTLING_PLUS_STRUCTURAL_CDC",
+      "scope": "RELEASE_SLOT_1_AXI_TO_SOURCE",
+      "semantic_families": [
+        "RELEASE_SLOT1_NORMAL_STATE_TRANSITION",
+        "RELEASE_SLOT1_MISMATCH_CONTAINMENT",
+        "RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING"
+      ],
+      "settling_cap_ns": "6.000",
+      "minimum_launch_to_use_margin_ns": "13.468",
+      "gross_reserve_ns": "7.468",
+      "slot_specific_routed_checks_required": true,
+      "structural_requirements": [
+        "HELD_56_BIT_GENERATION_EPOCH_TOKEN",
+        "TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER",
+        "DESTINATION_USE_AFTER_SYNCHRONIZED_EVENT",
+        "STABLE_PAYLOAD_THROUGH_CONSUMPTION",
+        "FAIL_CLOSED_MISMATCH_CONTAINMENT",
+        "RESET_OVERLAP_STALE_RELEASE_PROTECTION",
+        "COHERENT_CAPTURED_PHASE_RETIREMENT",
+        "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
+      ],
+      "rtl_change_required": "NO",
+      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "qualification": "NOT_YET_QUALIFIED",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-7R_TASK_DIRECTIVE",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+    },
+    {
+      "id": "REQ-G2B-GROUP16-RELEASE-SLOT-SIGNOFF",
+      "status": "FROZEN",
+      "requirement": "SETTLING_PLUS_STRUCTURAL_CDC",
+      "scope": "RELEASE_SLOT_2_AXI_TO_SOURCE",
+      "semantic_families": [
+        "RELEASE_SLOT2_NORMAL_STATE_TRANSITION",
+        "RELEASE_SLOT2_MISMATCH_CONTAINMENT",
+        "RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING"
+      ],
+      "settling_cap_ns": "6.000",
+      "minimum_launch_to_use_margin_ns": "13.468",
+      "gross_reserve_ns": "7.468",
+      "slot_specific_routed_checks_required": true,
+      "structural_requirements": [
+        "HELD_56_BIT_GENERATION_EPOCH_TOKEN",
+        "TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER",
+        "DESTINATION_USE_AFTER_SYNCHRONIZED_EVENT",
+        "STABLE_PAYLOAD_THROUGH_CONSUMPTION",
+        "FAIL_CLOSED_MISMATCH_CONTAINMENT",
+        "RESET_OVERLAP_STALE_RELEASE_PROTECTION",
+        "COHERENT_CAPTURED_PHASE_RETIREMENT",
+        "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
+      ],
+      "rtl_change_required": "NO",
+      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "qualification": "NOT_YET_QUALIFIED",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-7R_TASK_DIRECTIVE",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+    },
+    {
+      "id": "REQ-G2B-GROUP17-RELEASE-SLOT-SIGNOFF",
+      "status": "FROZEN",
+      "requirement": "SETTLING_PLUS_STRUCTURAL_CDC",
+      "scope": "RELEASE_SLOT_3_AXI_TO_SOURCE",
+      "semantic_families": [
+        "RELEASE_SLOT3_NORMAL_STATE_TRANSITION",
+        "RELEASE_SLOT3_MISMATCH_CONTAINMENT",
+        "RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING"
+      ],
+      "settling_cap_ns": "6.000",
+      "minimum_launch_to_use_margin_ns": "13.468",
+      "gross_reserve_ns": "7.468",
+      "slot_specific_routed_checks_required": true,
+      "structural_requirements": [
+        "HELD_56_BIT_GENERATION_EPOCH_TOKEN",
+        "TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER",
+        "DESTINATION_USE_AFTER_SYNCHRONIZED_EVENT",
+        "STABLE_PAYLOAD_THROUGH_CONSUMPTION",
+        "FAIL_CLOSED_MISMATCH_CONTAINMENT",
+        "RESET_OVERLAP_STALE_RELEASE_PROTECTION",
+        "COHERENT_CAPTURED_PHASE_RETIREMENT",
+        "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
+      ],
+      "rtl_change_required": "NO",
+      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "qualification": "NOT_YET_QUALIFIED",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-7R_TASK_DIRECTIVE",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
@@ -513 +610 @@
-      "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3",
+      "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
@@ -516 +613 @@
-      "blocking_reason": "GROUP14_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
+      "blocking_reason": "GROUPS15_TO_17_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
@@ -734 +831 @@
-      "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3",
+      "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
@@ -759 +856 @@
-    "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3",
+    "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
@@ -768 +865 @@
-    "blocking_reason": "GROUP14_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
+    "blocking_reason": "GROUPS15_TO_17_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
@@ -771 +868 @@
-    "decision_source": "META-6_TASK_DIRECTIVE",
+    "decision_source": "META-7R_TASK_DIRECTIVE",
@@ -782,3 +879,10 @@
-    "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-    "evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+    "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "next_engineering_source": {
+      "worktree": "C:\\FPGA\\V41_G2B",
+      "branch": "integration/v41-g2b-onech-c2h",
+      "commit": "bdae16e06fb5b8564763941f530e4ce9e28896c7",
+      "tree": "e18833d46f7672f851c3cb8239f2f29091378294",
+      "scope": "AUTHORITATIVE_RECOVERY4_INPUT_NOT_QUALIFIED_BASELINE"
+    }
@@ -848 +952 @@
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
@@ -955,2 +1059,6 @@
-    "groups_15_to_17": "PENDING_UNCHANGED",
-    "future_signoff_recipe": [
+    "groups_15_to_17": "PROMOTED",
+    "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP13_REPORT_BUS_SKEW",
+    "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
+    "future_recipe_reexecution_required": false,
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "historical_future_signoff_recipe_at_revision6": [
@@ -973,4 +1081 @@
-    "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP13_REPORT_BUS_SKEW",
-    "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
-    "future_recipe_reexecution_required": false,
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+    "historical_recipe_disposition": "SUPERSEDED_BY_GROUPS15_17_RELEASE_SLOT_CDC_SIGNOFF_FUTURE_SIGNOFF_RECIPE"
@@ -1175,2 +1280,4 @@
-    "groups_15_to_17": "PENDING_UNCHANGED",
-    "future_signoff_recipe": [
+    "groups_15_to_17": "PROMOTED",
+    "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP14_REPORT_BUS_SKEW",
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "historical_future_signoff_recipe_at_revision6": [
@@ -1193,2 +1300,4 @@
-    "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP14_REPORT_BUS_SKEW",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+    "historical_recipe_disposition": "SUPERSEDED_BY_GROUPS15_17_RELEASE_SLOT_CDC_SIGNOFF_FUTURE_SIGNOFF_RECIPE",
+    "active_xdc_change_context": "HISTORICAL_META6_PROMOTION_TIME_BOUNDARY_CURRENT_GROUP14_PASS_PRESERVED",
+    "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
+    "reexecution": "DO_NOT_REPEAT"
@@ -1200 +1309 @@
-    "blocking_reason": "GROUP14_CANDIDATE_IMPLEMENTATION_FINAL_OFFLINE_SIGNOFF_PRE_BITSTREAM_GATE_AND_BITSTREAM_CANDIDATE_NOT_AVAILABLE",
+    "blocking_reason": "GROUPS15_TO_17_CANDIDATE_IMPLEMENTATION_FINAL_OFFLINE_SIGNOFF_PRE_BITSTREAM_GATE_AND_BITSTREAM_CANDIDATE_NOT_AVAILABLE",
@@ -1207,4 +1316,4 @@
-    "decision_source": "META-6_TASK_DIRECTIVE",
-    "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-    "evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+    "decision_source": "META-7R_TASK_DIRECTIVE",
+    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+    "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
@@ -1402,0 +1512,19 @@
+    },
+    {
+      "topic": "GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY",
+      "record_form": "UNNUMBERED_GOVERNED_DECISION",
+      "status": "ACCEPTED",
+      "decision_state": "RESOLVED",
+      "decision": "PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC",
+      "covered_groups": [
+        15,
+        16,
+        17
+      ],
+      "slot_structural_relation": "PARTIALLY_EQUIVALENT",
+      "safety_protocol_equivalence": "PROVEN",
+      "slot_specific_routed_checks_required": "YES",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-7R_TASK_DIRECTIVE",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit"
@@ -1690,0 +1819,24 @@
+    },
+    {
+      "id": "EVID-G2B-G15-17-EQ",
+      "repository": "lukaszsudul/AHD-diagnostic-evidence",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "payload_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+      "files": [
+        "G2B_G15_17_EQ_STATE.json",
+        "G2B_G15_17_EQ_CANDIDATE_RESULTS.csv",
+        "G2B_G15_17_EQ_PROTOCOL_TIMING_MARGINS.csv",
+        "G2B_G15_17_EQ_FAMILIES.csv",
+        "G2B_G15_17_EQ_CDC_COMPARISON.md",
+        "G2B_G15_17_EQ_SAFETY_INVARIANT_COMPARISON.md",
+        "G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc",
+        "G2B_G15_17_EQ_STRUCTURAL_EQUIVALENCE_MATRIX.csv"
+      ],
+      "supports": [
+        "STMT-GROUPS-15-17",
+        "STMT-GROUPS15-17-DECISION",
+        "STMT-G2B-IMPL",
+        "STMT-G2B-HW"
+      ],
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_SIGNOFF_ARCHITECTURE_ONLY_ACTIVE_XDC_UNCHANGED_NO_FINAL_TIMING_BITSTREAM_OR_HARDWARE_PROOF"
@@ -1692 +1844,254 @@
-  ]
+  ],
+  "groups15_17_release_slot_cdc_signoff": {
+    "status": "ACCEPTED",
+    "combined_promotion_scope": "GROUPS_15_16_17",
+    "decision": "PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC",
+    "slot_structural_relation": "PARTIALLY_EQUIVALENT",
+    "safety_protocol_equivalence": "PROVEN",
+    "slot_specific_routed_checks_required": "YES",
+    "groups": [
+      {
+        "status": "ACCEPTED",
+        "group": 15,
+        "slot": 1,
+        "group_name": "RELEASE_SLOT_1_AXI_TO_SOURCE",
+        "old_required_signoff": {
+          "method": "GLOBAL_SET_BUS_SKEW_3NS",
+          "source_count": 56,
+          "destination_count": 20,
+          "disposition": "RETIRED_FROM_REQUIRED_SIGNOFF",
+          "path_set_comparability": "INVALID_FOR_SKEW_COMPARISON"
+        },
+        "new_required_signoff": {
+          "method": "SETTLING_PLUS_STRUCTURAL_CDC",
+          "promotion_state": "PROMOTED",
+          "semantic_families": [
+            {
+              "name": "RELEASE_SLOT1_NORMAL_STATE_TRANSITION",
+              "source_count": 56,
+              "destination_count": 3,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Generation/epoch token settles before qualified DMA_OWNED to RELEASABLE state use",
+              "collection_prefix": "g2b_g15eq",
+              "independent_routed_validation_required": true
+            },
+            {
+              "name": "RELEASE_SLOT1_MISMATCH_CONTAINMENT",
+              "source_count": 56,
+              "destination_count": 4,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Generation/epoch/state mismatch asserts fatal/event/deferred containment and disables admission",
+              "collection_prefix": "g2b_g15eq",
+              "independent_routed_validation_required": true
+            },
+            {
+              "name": "RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING",
+              "source_count": 56,
+              "destination_count": 3,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Captured release phase participates in reset-abandoned accounting before retirement",
+              "collection_prefix": "g2b_g15eq",
+              "independent_routed_validation_required": true
+            }
+          ],
+          "semantic_family_count": 3,
+          "settling_cap_ns": "6.000"
+        },
+        "cdc_structure": "PASS_WITH_DISPOSITION",
+        "rtl_change_required": "NO",
+        "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "decision_source": "META-7R_TASK_DIRECTIVE",
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      },
+      {
+        "status": "ACCEPTED",
+        "group": 16,
+        "slot": 2,
+        "group_name": "RELEASE_SLOT_2_AXI_TO_SOURCE",
+        "old_required_signoff": {
+          "method": "GLOBAL_SET_BUS_SKEW_3NS",
+          "source_count": 56,
+          "destination_count": 20,
+          "disposition": "RETIRED_FROM_REQUIRED_SIGNOFF",
+          "path_set_comparability": "INVALID_FOR_SKEW_COMPARISON"
+        },
+        "new_required_signoff": {
+          "method": "SETTLING_PLUS_STRUCTURAL_CDC",
+          "promotion_state": "PROMOTED",
+          "semantic_families": [
+            {
+              "name": "RELEASE_SLOT2_NORMAL_STATE_TRANSITION",
+              "source_count": 56,
+              "destination_count": 3,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Generation/epoch token settles before qualified DMA_OWNED to RELEASABLE state use",
+              "collection_prefix": "g2b_g16eq",
+              "independent_routed_validation_required": true
+            },
+            {
+              "name": "RELEASE_SLOT2_MISMATCH_CONTAINMENT",
+              "source_count": 56,
+              "destination_count": 4,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Generation/epoch/state mismatch asserts fatal/event/deferred containment and disables admission",
+              "collection_prefix": "g2b_g16eq",
+              "independent_routed_validation_required": true
+            },
+            {
+              "name": "RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING",
+              "source_count": 56,
+              "destination_count": 3,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Captured release phase participates in reset-abandoned accounting before retirement",
+              "collection_prefix": "g2b_g16eq",
+              "independent_routed_validation_required": true
+            }
+          ],
+          "semantic_family_count": 3,
+          "settling_cap_ns": "6.000"
+        },
+        "cdc_structure": "PASS_WITH_DISPOSITION",
+        "rtl_change_required": "NO",
+        "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "decision_source": "META-7R_TASK_DIRECTIVE",
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      },
+      {
+        "status": "ACCEPTED",
+        "group": 17,
+        "slot": 3,
+        "group_name": "RELEASE_SLOT_3_AXI_TO_SOURCE",
+        "old_required_signoff": {
+          "method": "GLOBAL_SET_BUS_SKEW_3NS",
+          "source_count": 56,
+          "destination_count": 20,
+          "disposition": "RETIRED_FROM_REQUIRED_SIGNOFF",
+          "path_set_comparability": "INVALID_FOR_SKEW_COMPARISON"
+        },
+        "new_required_signoff": {
+          "method": "SETTLING_PLUS_STRUCTURAL_CDC",
+          "promotion_state": "PROMOTED",
+          "semantic_families": [
+            {
+              "name": "RELEASE_SLOT3_NORMAL_STATE_TRANSITION",
+              "source_count": 56,
+              "destination_count": 3,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Generation/epoch token settles before qualified DMA_OWNED to RELEASABLE state use",
+              "collection_prefix": "g2b_g17eq",
+              "independent_routed_validation_required": true
+            },
+            {
+              "name": "RELEASE_SLOT3_MISMATCH_CONTAINMENT",
+              "source_count": 56,
+              "destination_count": 4,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Generation/epoch/state mismatch asserts fatal/event/deferred containment and disables admission",
+              "collection_prefix": "g2b_g17eq",
+              "independent_routed_validation_required": true
+            },
+            {
+              "name": "RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING",
+              "source_count": 56,
+              "destination_count": 3,
+              "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+              "required_ns": "6.000",
+              "source_clock": "userclk1",
+              "destination_clock": "nvp_vclk1",
+              "semantic_role": "Captured release phase participates in reset-abandoned accounting before retirement",
+              "collection_prefix": "g2b_g17eq",
+              "independent_routed_validation_required": true
+            }
+          ],
+          "semantic_family_count": 3,
+          "settling_cap_ns": "6.000"
+        },
+        "cdc_structure": "PASS_WITH_DISPOSITION",
+        "rtl_change_required": "NO",
+        "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "decision_source": "META-7R_TASK_DIRECTIVE",
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      }
+    ],
+    "semantic_families_per_slot": 3,
+    "total_timing_checks": 9,
+    "candidate_timing_validation": "PASS",
+    "settling_cap_ns": "6.000",
+    "destination_clock_period_ns": "6.734",
+    "minimum_launch_to_use_margin_ns": "13.468",
+    "gross_reserve_ns": "7.468",
+    "structural_requirements": [
+      "HELD_56_BIT_GENERATION_EPOCH_TOKEN",
+      "TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER",
+      "DESTINATION_USE_AFTER_SYNCHRONIZED_EVENT",
+      "STABLE_PAYLOAD_THROUGH_CONSUMPTION",
+      "FAIL_CLOSED_MISMATCH_CONTAINMENT",
+      "RESET_OVERLAP_STALE_RELEASE_PROTECTION",
+      "COHERENT_CAPTURED_PHASE_RETIREMENT",
+      "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
+    ],
+    "reset_transport_request_synchronizer_stages": 2,
+    "signoff_runtime": "PRACTICAL",
+    "replacement_equivalence": "SAFER_AND_MORE_SEMANTICALLY_CORRECT",
+    "rtl_change_required": "NO",
+    "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+    "candidate_xdc": "G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc",
+    "candidate_xdc_sha256": "BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F",
+    "accepted_by_role": "OWNER_ARCHITECT",
+    "decision_source": "META-7R_TASK_DIRECTIVE",
+    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+    "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+    "preserved_results": {
+      "group9": "PRESERVE_PASS",
+      "group10": "PRESERVE_PASS",
+      "group11": "PRESERVE_PASS",
+      "group12": "PRESERVE_PASS",
+      "group13": "PRESERVE_PASS",
+      "group14": "PRESERVE_PASS"
+    },
+    "future_signoff_recipe": [
+      "PRESERVE_GROUPS9_TO_14_PASS",
+      "IMPLEMENT_G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS_XDC",
+      "VALIDATE_NINE_SLOT_SPECIFIC_SETTLING_AND_STRUCTURAL_CDC_CHECKS",
+      "ROUTED_SETUP_HOLD_TIMING",
+      "DRC",
+      "CDC_DISPOSITION",
+      "CLOCKS",
+      "PRODUCT_RESOURCES",
+      "PRE_BITSTREAM_HARD_GATE",
+      "BITSTREAM_ONLY_AFTER_PASS"
+    ],
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "remaining_methodology_warnings": "OTHER_PRESERVED_RELATIONS_REQUIRE_FINAL_DISPOSITION_OUTSIDE_THIS_DECISION",
+    "route_measurements_are_permanent_requirements": false
+  }
--- a/project-current-state/README.md
+++ b/project-current-state/README.md
@@ -15 +15 @@
-| `PROJECT_STATE_REV` | `6` |
+| `PROJECT_STATE_REV` | `7` |
@@ -18 +18 @@
-| Last update | `2026-09-03` |
+| Last update | `2026-09-05` |
@@ -22 +22 @@
-| Revision-6 decision basis | Accepted G14-A release-slot CDC architecture and promoted Group-14 sign-off method |
+| Revision-7 decision basis | Accepted combined G15–17 release-slot sign-off architecture; Groups 9–14 PASS preserved |
@@ -47 +47 @@
-| META | META-6 promotes the release-slot CDC Group-14 sign-off architecture while preserving META-4R2 Group-9 and META-5 Group-13 truth; no RTL or active-XDC implementation |
+| META | META-7R promotes Groups 15–17; Groups 9–14 decisions and PASS preserved; no RTL or active-XDC implementation |
@@ -60,2 +60,2 @@
-| G2B implementation | G2B-LUT1 readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-3` |
-| Active XDC change | `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; Group-14 candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc`; active production XDC unchanged |
+| G2B implementation | G2B-LUT1 readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` |
+| Active XDC change | Groups 15–17 `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` |
@@ -74 +74 @@
-`GROUPS_15_TO_17 = PENDING_UNCHANGED`. The retired global Group-9, Group-13,
+`GROUPS_15_TO_17 = PROMOTED`. The retired global Group-9, Group-13,
@@ -80,0 +81,43 @@
+
+## META-7R combined release-slot promotion
+
+Groups 15–17 each promote `SETTLING_PLUS_STRUCTURAL_CDC` with three
+slot-specific semantic families, nine checks total, and a `6.000 ns` absolute
+settling cap. The `13.468 ns` minimum launch-to-use window provides `7.468 ns`
+gross reserve. `SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`,
+`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`, and
+`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`. Each former global
+`GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is
+`RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
+requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.
+
+`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
+15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
+`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
+`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
+`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+
+`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
+`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
+promotion evidence and promotion-time active-XDC dispositions are preserved.
+The Group-14 pending-XDC statements at META-6 are historical promotion-time
+boundaries; the authoritative audit now preserves its PASS. They do not
+instruct recovery-4 to reimplement Group 14.
+
+`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
+`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
+`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
+commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
+`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
+global Groups 15–17 bus-skew constraints with the nine candidate checks,
+preserving every unrelated active constraint and Groups 9–14 PASS. It must
+validate all nine checks, then continue final routed timing, DRC, CDC
+disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
+Bitstream generation is a later engineering action allowed only after those
+gates pass; it is not performed or claimed by META-7R.
+
+`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
+final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
+complete; no G2B bitstream exists and hardware has not been tested. No final
+timing sign-off, qualification, release, hardware readiness, DMA operation,
+or hardware proof is promoted.
--- a/project-current-state/SHA256_MANIFEST.txt
+++ b/project-current-state/SHA256_MANIFEST.txt
@@ -1,11 +1,11 @@
-5C5D063640795F30667A0FD27E9CAF95B516857401689522785DE1E278EB0032  ACTIVE_BASELINES.md
-67CFCA246BADF3FE0AFE12EF5FA7FC2EA77AE33A0FD2A863BBAF44E008CAC5DD  CHANGELOG.md
-DFED00916CF81323417EFBEE0890B43314B836ED3476BEB1716EBDB542ED7076  COMPATIBILITY_MATRIX.csv
-81275FB9ACBCFE7667B80E6A1CBC6E77B796D94025781DDBE0A34B7DB6968374  CURRENT_ARCHITECTURE.md
-F035622664B2577287B0F0343B1EE3EDC35BF38085C411E785309C9A3CA80FD2  CURRENT_INTERFACES.md
-FB4E3D59E9614F7778C6821F7546FE4F012842AF47890956A65D4D666377F1EA  CURRENT_REQUIREMENTS.md
-DA22429E4A4CF2BCDF34540CF6DCA7DFCF3CA36650EDE5AC31A13A5A3A154B42  CURRENT_RESOURCE_STATE.md
-FA2812D29E759149BDF553AA5059403392C77DC1AF2F798522AD0838CC4E5394  CURRENT_STATUS.md
-A26B08EC36202B794E70A403489C4E60C0285CAC87BD6D47FFFAB8F03610421F  CURRENT_TRACKS.md
-22FE49C2249153315D0D516CA49A211717B7FC3B583ECC8BD6CD7E9420FC7CD9  EVIDENCE_MAP.md
-E26B6208F2707B637995305EB8D2521609E97F5F6DC9CE4AD517AC1FF9BE2B02  GOVERNANCE.md
+E25125DB6866D306C7930C197459B6736DB1FF70FB18F1BD91F5D9EA7D1414FD  ACTIVE_BASELINES.md
+682B1F9648B44D87A3BF812706624BBA68540158159EB6E7EDC321C2B164B2E7  CHANGELOG.md
+76D429FBB9C28589079E38817A96657FAB4DC64CDA47FE6B09BBEC9A30864058  COMPATIBILITY_MATRIX.csv
+55F3C765BB7B7BDF8C4BBD1038F322B44480EA14529E2222E424CEC83DDA0549  CURRENT_ARCHITECTURE.md
+FB391086FB448AFBFF0DC8766BF4FF9C7C89941B02F9A3C9D97ECBCA6219B72C  CURRENT_INTERFACES.md
+BC4820B32BB83E73F4879916AB42FCCEA1D84939833441D34190CDBFC1DB2684  CURRENT_REQUIREMENTS.md
+271F53443B3F063BD1505BFBBD4FB95FB40B0ADED2A8F86DEB8BAA3D64368B0B  CURRENT_RESOURCE_STATE.md
+BB3CF28F8E2AB06B8532838D6FAA2DE6408CBA0E10DACFDDCBE4516EDEC23164  CURRENT_STATUS.md
+5CB9898C95BD2E0BE7C137E147D5B0DFAA43DF6A76D4CDBF55E85F22F369A723  CURRENT_TRACKS.md
+20C5E803E922B9056F40849EAE7A41F40DE14D97FD4BF089E5DF81B5BF8259F4  EVIDENCE_MAP.md
+BEA6E809FD76C2D08DCE30B507A58CE1E1F8B88C851B8D9D20E18D381A9E5474  GOVERNANCE.md
@@ -13,3 +13,3 @@
-B1F8824CF980DEC523AF12BE4CA83873EECC60CB7E44C4EF651E3046129FDD75  OPEN_DECISIONS.md
-85B0643096DF6D135E0039342F947F206410B351B2A5F4F623E65930A3FED725  PROJECT_STATE.json
-172D059B800B5EF3D63D865A87CE1B9635F59416C4300ECABEA857203481DE01  README.md
+1A0E2F255A156A947E09880DD7FEED8F3A60489E5FC952C17D948871428C3950  OPEN_DECISIONS.md
+B800B561863202A34DA87EE6273F15F65FE1A4A716CDA82AEAC825C3A6AA872E  PROJECT_STATE.json
+CDB53488D8F4BCA0BFF933F7593CB1CE5DC61548101E643F00EE717E567243C9  README.md
@@ -17 +17 @@
-0FB18EB54C13535607FB0EB1922179F5ABF24CE4DB451D5AE3C06E963E8E974E  TRACK_STATUS.json
+92A6721670C214B5A178F309518B421412BA60974DA71BD85F6A7502BDBE2144  TRACK_STATUS.json
--- a/project-current-state/TRACK_STATUS.json
+++ b/project-current-state/TRACK_STATUS.json
@@ -3 +3 @@
-  "project_state_revision": 6,
+  "project_state_revision": 7,
@@ -6 +6 @@
-  "last_update": "2026-09-03",
+  "last_update": "2026-09-05",
@@ -8 +8 @@
-  "acceptance_authorization": "META-6_TASK_DIRECTIVE",
+  "acceptance_authorization": "META-7R_TASK_DIRECTIVE",
@@ -12,4 +12,4 @@
-  "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-  "source_evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit",
-  "expected_previous_project_state_revision": 5,
-  "write_contract_receipt": "v41-meta-project-state-rev6-group14-release-slot-signoff/META6_WRITE_CONTRACT_RECEIPT.md",
+  "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+  "source_evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+  "expected_previous_project_state_revision": 6,
+  "write_contract_receipt": "v41-meta-project-state-rev7-groups15-17-release-slot-signoff/META7_FROZEN_WRITE_CONTRACT_RECEIPT.md",
@@ -20 +20 @@
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3",
+    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
@@ -72 +72 @@
-        "blocking_reason": "GROUP14_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
+        "blocking_reason": "GROUPS15_TO_17_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
@@ -76,2 +76,3 @@
-        "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-        "evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit"
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+        "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+        "decision_source": "META-7R_TASK_DIRECTIVE"
@@ -93 +94 @@
-        "scope": "PRESERVE_PROMOTED_GROUP9_AND_GROUPS10_TO_12_AND_PROMOTED_GROUP13_APPLY_PROMOTED_GROUP14_AND_COMPLETE_ROUTED_SIGNOFF",
+        "scope": "PRESERVE_GROUPS9_TO_14_PASS_APPLY_PROMOTED_GROUPS15_TO_17_AND_COMPLETE_ROUTED_SIGNOFF",
@@ -100 +101,2 @@
-          "GROUP13"
+          "GROUP13",
+          "GROUP14"
@@ -103,4 +105,4 @@
-        "decision_source": "META-6_TASK_DIRECTIVE",
-        "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-        "depends_on": "META6_PROMOTED_GROUP14_RELEASE_SLOT_SIGNOFF_METHOD",
-        "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+        "decision_source": "META-7R_TASK_DIRECTIVE",
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+        "depends_on": "META7_PROMOTED_COMBINED_GROUPS15_TO_17_RELEASE_SLOT_SIGNOFF_METHODS",
+        "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
@@ -113 +115 @@
-        "blocking_reason": "GROUP14_CANDIDATE_IMPLEMENTATION_FINAL_OFFLINE_SIGNOFF_PRE_BITSTREAM_GATE_AND_BITSTREAM_CANDIDATE_NOT_AVAILABLE",
+        "blocking_reason": "GROUPS15_TO_17_CANDIDATE_IMPLEMENTATION_FINAL_OFFLINE_SIGNOFF_PRE_BITSTREAM_GATE_AND_BITSTREAM_CANDIDATE_NOT_AVAILABLE",
@@ -116,3 +118,3 @@
-        "decision_source": "META-6_TASK_DIRECTIVE",
-        "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
-        "evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit"
+        "decision_source": "META-7R_TASK_DIRECTIVE",
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+        "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit"
@@ -173 +175 @@
-      "groups_15_to_17": "PENDING_UNCHANGED",
+      "groups_15_to_17": "PROMOTED",
@@ -184 +186 @@
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
@@ -259 +261 @@
-      "groups_15_to_17": "PENDING_UNCHANGED",
+      "groups_15_to_17": "PROMOTED",
@@ -268 +270,264 @@
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-3"
+      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "active_xdc_change_context": "HISTORICAL_META6_PROMOTION_TIME_BOUNDARY_CURRENT_GROUP14_PASS_PRESERVED",
+      "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
+      "reexecution": "DO_NOT_REPEAT"
+    },
+    "groups15_17_release_slot_signoff": {
+      "status": "ACCEPTED",
+      "combined_promotion_scope": "GROUPS_15_16_17",
+      "decision": "PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC",
+      "slot_structural_relation": "PARTIALLY_EQUIVALENT",
+      "safety_protocol_equivalence": "PROVEN",
+      "slot_specific_routed_checks_required": "YES",
+      "groups": [
+        {
+          "status": "ACCEPTED",
+          "group": 15,
+          "slot": 1,
+          "group_name": "RELEASE_SLOT_1_AXI_TO_SOURCE",
+          "old_required_signoff": {
+            "method": "GLOBAL_SET_BUS_SKEW_3NS",
+            "source_count": 56,
+            "destination_count": 20,
+            "disposition": "RETIRED_FROM_REQUIRED_SIGNOFF",
+            "path_set_comparability": "INVALID_FOR_SKEW_COMPARISON"
+          },
+          "new_required_signoff": {
+            "method": "SETTLING_PLUS_STRUCTURAL_CDC",
+            "promotion_state": "PROMOTED",
+            "semantic_families": [
+              {
+                "name": "RELEASE_SLOT1_NORMAL_STATE_TRANSITION",
+                "source_count": 56,
+                "destination_count": 3,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Generation/epoch token settles before qualified DMA_OWNED to RELEASABLE state use",
+                "collection_prefix": "g2b_g15eq",
+                "independent_routed_validation_required": true
+              },
+              {
+                "name": "RELEASE_SLOT1_MISMATCH_CONTAINMENT",
+                "source_count": 56,
+                "destination_count": 4,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Generation/epoch/state mismatch asserts fatal/event/deferred containment and disables admission",
+                "collection_prefix": "g2b_g15eq",
+                "independent_routed_validation_required": true
+              },
+              {
+                "name": "RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING",
+                "source_count": 56,
+                "destination_count": 3,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Captured release phase participates in reset-abandoned accounting before retirement",
+                "collection_prefix": "g2b_g15eq",
+                "independent_routed_validation_required": true
+              }
+            ],
+            "semantic_family_count": 3,
+            "settling_cap_ns": "6.000"
+          },
+          "cdc_structure": "PASS_WITH_DISPOSITION",
+          "rtl_change_required": "NO",
+          "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
+          "accepted_by_role": "OWNER_ARCHITECT",
+          "decision_source": "META-7R_TASK_DIRECTIVE",
+          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        },
+        {
+          "status": "ACCEPTED",
+          "group": 16,
+          "slot": 2,
+          "group_name": "RELEASE_SLOT_2_AXI_TO_SOURCE",
+          "old_required_signoff": {
+            "method": "GLOBAL_SET_BUS_SKEW_3NS",
+            "source_count": 56,
+            "destination_count": 20,
+            "disposition": "RETIRED_FROM_REQUIRED_SIGNOFF",
+            "path_set_comparability": "INVALID_FOR_SKEW_COMPARISON"
+          },
+          "new_required_signoff": {
+            "method": "SETTLING_PLUS_STRUCTURAL_CDC",
+            "promotion_state": "PROMOTED",
+            "semantic_families": [
+              {
+                "name": "RELEASE_SLOT2_NORMAL_STATE_TRANSITION",
+                "source_count": 56,
+                "destination_count": 3,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Generation/epoch token settles before qualified DMA_OWNED to RELEASABLE state use",
+                "collection_prefix": "g2b_g16eq",
+                "independent_routed_validation_required": true
+              },
+              {
+                "name": "RELEASE_SLOT2_MISMATCH_CONTAINMENT",
+                "source_count": 56,
+                "destination_count": 4,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Generation/epoch/state mismatch asserts fatal/event/deferred containment and disables admission",
+                "collection_prefix": "g2b_g16eq",
+                "independent_routed_validation_required": true
+              },
+              {
+                "name": "RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING",
+                "source_count": 56,
+                "destination_count": 3,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Captured release phase participates in reset-abandoned accounting before retirement",
+                "collection_prefix": "g2b_g16eq",
+                "independent_routed_validation_required": true
+              }
+            ],
+            "semantic_family_count": 3,
+            "settling_cap_ns": "6.000"
+          },
+          "cdc_structure": "PASS_WITH_DISPOSITION",
+          "rtl_change_required": "NO",
+          "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
+          "accepted_by_role": "OWNER_ARCHITECT",
+          "decision_source": "META-7R_TASK_DIRECTIVE",
+          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        },
+        {
+          "status": "ACCEPTED",
+          "group": 17,
+          "slot": 3,
+          "group_name": "RELEASE_SLOT_3_AXI_TO_SOURCE",
+          "old_required_signoff": {
+            "method": "GLOBAL_SET_BUS_SKEW_3NS",
+            "source_count": 56,
+            "destination_count": 20,
+            "disposition": "RETIRED_FROM_REQUIRED_SIGNOFF",
+            "path_set_comparability": "INVALID_FOR_SKEW_COMPARISON"
+          },
+          "new_required_signoff": {
+            "method": "SETTLING_PLUS_STRUCTURAL_CDC",
+            "promotion_state": "PROMOTED",
+            "semantic_families": [
+              {
+                "name": "RELEASE_SLOT3_NORMAL_STATE_TRANSITION",
+                "source_count": 56,
+                "destination_count": 3,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Generation/epoch token settles before qualified DMA_OWNED to RELEASABLE state use",
+                "collection_prefix": "g2b_g17eq",
+                "independent_routed_validation_required": true
+              },
+              {
+                "name": "RELEASE_SLOT3_MISMATCH_CONTAINMENT",
+                "source_count": 56,
+                "destination_count": 4,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Generation/epoch/state mismatch asserts fatal/event/deferred containment and disables admission",
+                "collection_prefix": "g2b_g17eq",
+                "independent_routed_validation_required": true
+              },
+              {
+                "name": "RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING",
+                "source_count": 56,
+                "destination_count": 3,
+                "constraint_type": "MAX_DELAY_DATAPATH_ONLY",
+                "required_ns": "6.000",
+                "source_clock": "userclk1",
+                "destination_clock": "nvp_vclk1",
+                "semantic_role": "Captured release phase participates in reset-abandoned accounting before retirement",
+                "collection_prefix": "g2b_g17eq",
+                "independent_routed_validation_required": true
+              }
+            ],
+            "semantic_family_count": 3,
+            "settling_cap_ns": "6.000"
+          },
+          "cdc_structure": "PASS_WITH_DISPOSITION",
+          "rtl_change_required": "NO",
+          "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
+          "accepted_by_role": "OWNER_ARCHITECT",
+          "decision_source": "META-7R_TASK_DIRECTIVE",
+          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        }
+      ],
+      "semantic_families_per_slot": 3,
+      "total_timing_checks": 9,
+      "candidate_timing_validation": "PASS",
+      "settling_cap_ns": "6.000",
+      "destination_clock_period_ns": "6.734",
+      "minimum_launch_to_use_margin_ns": "13.468",
+      "gross_reserve_ns": "7.468",
+      "structural_requirements": [
+        "HELD_56_BIT_GENERATION_EPOCH_TOKEN",
+        "TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER",
+        "DESTINATION_USE_AFTER_SYNCHRONIZED_EVENT",
+        "STABLE_PAYLOAD_THROUGH_CONSUMPTION",
+        "FAIL_CLOSED_MISMATCH_CONTAINMENT",
+        "RESET_OVERLAP_STALE_RELEASE_PROTECTION",
+        "COHERENT_CAPTURED_PHASE_RETIREMENT",
+        "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
+      ],
+      "reset_transport_request_synchronizer_stages": 2,
+      "signoff_runtime": "PRACTICAL",
+      "replacement_equivalence": "SAFER_AND_MORE_SEMANTICALLY_CORRECT",
+      "rtl_change_required": "NO",
+      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "candidate_xdc": "G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc",
+      "candidate_xdc_sha256": "BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-7R_TASK_DIRECTIVE",
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
+      "preserved_results": {
+        "group9": "PRESERVE_PASS",
+        "group10": "PRESERVE_PASS",
+        "group11": "PRESERVE_PASS",
+        "group12": "PRESERVE_PASS",
+        "group13": "PRESERVE_PASS",
+        "group14": "PRESERVE_PASS"
+      },
+      "future_signoff_recipe": [
+        "PRESERVE_GROUPS9_TO_14_PASS",
+        "IMPLEMENT_G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS_XDC",
+        "VALIDATE_NINE_SLOT_SPECIFIC_SETTLING_AND_STRUCTURAL_CDC_CHECKS",
+        "ROUTED_SETUP_HOLD_TIMING",
+        "DRC",
+        "CDC_DISPOSITION",
+        "CLOCKS",
+        "PRODUCT_RESOURCES",
+        "PRE_BITSTREAM_HARD_GATE",
+        "BITSTREAM_ONLY_AFTER_PASS"
+      ],
+      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "remaining_methodology_warnings": "OTHER_PRESERVED_RELATIONS_REQUIRE_FINAL_DISPOSITION_OUTSIDE_THIS_DECISION",
+      "route_measurements_are_permanent_requirements": false
+    },
+    "next_engineering_source": {
+      "worktree": "C:\\FPGA\\V41_G2B",
+      "branch": "integration/v41-g2b-onech-c2h",
+      "commit": "bdae16e06fb5b8564763941f530e4ce9e28896c7",
+      "tree": "e18833d46f7672f851c3cb8239f2f29091378294",
+      "scope": "AUTHORITATIVE_RECOVERY4_INPUT_NOT_QUALIFIED_BASELINE"
@@ -348 +613 @@
-    "current_task": "META-6",
+    "current_task": "META-7R",
@@ -351 +616 @@
-    "acceptance_basis": "OWNER_ARCHITECT_PROMOTED_RELEASE_SLOT_GROUP14_SIGNOFF_METHOD",
+    "acceptance_basis": "OWNER_ARCHITECT_PROMOTED_COMBINED_GROUPS15_TO_17_RELEASE_SLOT_SIGNOFF_METHODS",
@@ -353,2 +618,2 @@
-    "decision_source": "META-6_TASK_DIRECTIVE",
-    "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96"
+    "decision_source": "META-7R_TASK_DIRECTIVE",
+    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
```
