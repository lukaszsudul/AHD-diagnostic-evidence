# G2B-BS3 Recommended Ownership Sign-off Recipe

## Gate inputs

1. Verify the routed DCP identity and that it is fully routed.
2. Verify the qualified RTL/XDC source hashes and intended build profile.
3. Resolve `userclk1` exactly once at 16.000 ns and `nvp_vclk1` exactly once at 6.734 ns in the qualified STA model; reject changed periods, synchronizer depth, or ownership hierarchy until the margin derivation is redone.

## Ownership structural gate

4. Resolve exactly two request synchronizer cells and two acknowledgement synchronizer cells; require `ASYNC_REG=TRUE` on all four.
5. Confirm the first-stage D pins are false-pathed and sync1-to-sync2 is normally timed.
6. Review that payload/request launch occurs on one AXI edge; request consumption is sync2-vs-seen gated; `scheduler_pop` is impossible outside `AXIS_IDLE`; and the result is consumed only after ack sync2.
7. Review transport reset phase retirement, epoch installation, generation/epoch comparisons, and the documented clock-progress/config-initialization/wrap assumptions.

## Constraint/object gate

8. Start from the complete production timing constraints. Remove only the global `OWNERSHIP_AXI_TO_SOURCE set_bus_skew 3.000` statement. Preserve all unrelated constraints.
9. Load `G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc`.
10. In the companion sign-off Tcl harness, require exact source counts of 2 slot, 24 generation, and 32 epoch; require exactly 17 payload-dependent destination D pins. Compare every sorted identity against the qualified BS0 lists/hashes, not counts alone. Reject empty, extra, or changed collections. Do not place procedural `if` assertions in XDC because Vivado XDC parsing does not support them.
11. Export effective constraints and verify zero ownership bus-skew commands, the expected unchanged unrelated bus-skew count, and three 6.000 ns ownership max-delay commands.

## Bounded physical gate

12. Run one `get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1` query per family. Each query has an external 300-second deadline.
13. Require `DATAPATH_DELAY <= 6.000 ns`, nonnegative slack, `MaxDelay ... -datapath_only`, and the intended `userclk1 -> nvp_vclk1` direction for all three families.
14. Run candidate-isolated `report_exceptions -coverage` and `report_exceptions -ignored`. Correlate all three family scopes and explicitly disposition equal-value overlap with the retained broad 6.000 ns cap; absence from `-ignored` alone is insufficient because partially overridden exceptions are not listed.
15. Verify the retained reverse `own_ok_hold_source` max-delay relation and stable-result/ack protocol.
16. Run focused methodology checks `TIMING-32`, `TIMING-34`, `TIMING-37`, `TIMING-38`, and `TIMING-39`; require no candidate-attributable warning.

## System gate

17. Run normal global setup/hold timing, focused ownership CDC correlation/disposition, DRC, and build-methodology checks.
18. Confirm no unresolved reset/epoch issue and no ownership CDC-10/CDC-13 overlap.
19. At the pre-bitstream gate, require all prior evidence identities/results and the normal release criteria.

The ownership gate must not invoke the pathological global Group-9 `report_bus_skew`. Other separately justified bus-skew families remain governed by their own sign-off procedures.

## Decision

`GROUP9_FINAL_DISPOSITION = REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS`

`CANDIDATE_XDC_READY_FOR_META = YES_WITH_OWNER_ARCHITECT_REVIEW`

Owner/architect review is retained because production promotion must replace exactly one line in active XDC, confirm the synthesis-merge-resilient source patterns, and accept the explicit reset/counter-wrap assumptions. BS3 itself performs no promotion.
