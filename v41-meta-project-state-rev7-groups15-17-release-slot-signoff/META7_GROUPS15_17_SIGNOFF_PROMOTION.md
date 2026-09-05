# META-7R Groups 15–17 Sign-Off Promotion

### Combined Groups 15–17 release-slot sign-off — revision 7

Owner/Architect decision `META-7R_TASK_DIRECTIVE` promotes
`PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` from `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
`COMBINED_PROMOTION_SCOPE = GROUPS_15_16_17`.

Group 15 `RELEASE_SLOT_1_AXI_TO_SOURCE`, Group 16
`RELEASE_SLOT_2_AXI_TO_SOURCE`, and Group 17 `RELEASE_SLOT_3_AXI_TO_SOURCE`
each retire `GLOBAL_SET_BUS_SKEW_3NS` as `RETIRED_FROM_REQUIRED_SIGNOFF`.
The historical scope of each was 56 sources / 20 destinations. Group 15 mixed
normal-state, fault/history and other-slot roles and omitted reset-overlap
accounting endpoints. Group 16 mixed semantically different destination
roles. Group 17 likewise did not describe one coherent relative-skew bus.
All three path sets are `INVALID_FOR_SKEW_COMPARISON`; their global
`report_bus_skew` queries are retired from every current required recipe.

Each replacement is `SETTLING_PLUS_STRUCTURAL_CDC`, state `PROMOTED`:

| Group | Slot | Semantic family | Permanent settling cap | Validated collection |
|---|---|---|---|---|
| 15 | 1 | `RELEASE_SLOT1_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 15 | 1 | `RELEASE_SLOT1_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
| 15 | 1 | `RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 16 | 2 | `RELEASE_SLOT2_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 16 | 2 | `RELEASE_SLOT2_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
| 16 | 2 | `RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 17 | 3 | `RELEASE_SLOT3_NORMAL_STATE_TRANSITION` | `6.000 ns` datapath-only | 56 sources / 3 destinations |
| 17 | 3 | `RELEASE_SLOT3_MISMATCH_CONTAINMENT` | `6.000 ns` datapath-only | 56 sources / 4 destinations |
| 17 | 3 | `RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING` | `6.000 ns` datapath-only | 56 sources / 3 destinations |

One architecture covers three independently validated slot implementations,
three families each, and nine independent timing checks. All nine candidate
checks passed; runtime is `PRACTICAL`; replacement equivalence is
`SAFER_AND_MORE_SEMANTICALLY_CORRECT`.

`SLOT_STRUCTURAL_RELATION = PARTIALLY_EQUIVALENT`;
`SAFETY_PROTOCOL_EQUIVALENCE = PROVEN`;
`SLOT_SPECIFIC_ROUTED_CHECKS_REQUIRED = YES`.
Routed cones are not exact copies of slot 0 or one another: mapped depths,
LUT input pins and placement differ. Source and destination collections must
be resolved independently for each slot and each routed cone validated.
Shared containment/reset destination cells do not merge the independently
scoped source-to-destination relations.

The permanent requirement is `SETTLING_CAP = 6.000 ns` absolute datapath-only
for each family. The basis is a `6.734 ns` destination clock period, at least
two qualifying destination periods (`13.468 ns` launch-to-use window), and
`7.468 ns` gross protocol reserve. This common cap is retained only after
independent proof of each slot's clock period, qualifying synchronization
depth, destination-use phase, stable-data lifetime and mismatch/reset/
retirement semantics. Route-specific actual delays and slacks remain evidence,
not permanent architectural bounds.

The structural proof is inseparable from timing: hold the 56-bit token
(24 generation bits and 32 epoch bits), launch token and release toggle on
the same accepted final AXI beat, retain two direct `ASYNC_REG` release-toggle
stages, and permit normal destination use only after the synchronized event.
Hold the payload through consumption and prohibit premature overwrite or
slot reuse. Generation/epoch/current-reset-epoch and ownership mismatch must
fail closed, latch containment and disable admission.

Reset-overlap accounting uses its separate two-stage transport-request
synchronizer and the same-episode token. Capture the same-edge release phase,
prevent stale release across reset, and require the independently synchronized
release vector and ownership phase to match their captures before coherent
retirement and acknowledgement. Each slot retains all eight proven safety
invariants; its CDC disposition is `PASS_WITH_DISPOSITION`.

The candidate creates no release-slot bus-skew relation. Remaining focused
TIMING-34/TIMING-39 warnings arise from other preserved relations and remain
subject to normal final sign-off disposition, outside this architecture
decision. Project-wide warning closure is not claimed.

`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.

`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
promotion evidence and promotion-time active-XDC dispositions are preserved.
The Group-14 pending-XDC statements at META-6 are historical promotion-time
boundaries; the authoritative audit now preserves its PASS. They do not
instruct recovery-4 to reimplement Group 14.

`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
global Groups 15–17 bus-skew constraints with the nine candidate checks,
preserving every unrelated active constraint and Groups 9–14 PASS. It must
validate all nine checks, then continue final routed timing, DRC, CDC
disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
Bitstream generation is a later engineering action allowed only after those
gates pass; it is not performed or claimed by META-7R.

`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
complete; no G2B bitstream exists and hardware has not been tested. No final
timing sign-off, qualification, release, hardware readiness, DMA operation,
or hardware proof is promoted.
