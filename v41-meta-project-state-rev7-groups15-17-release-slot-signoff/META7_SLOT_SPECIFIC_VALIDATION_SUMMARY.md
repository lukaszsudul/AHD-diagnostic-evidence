# META-7R Slot-Specific Validation Summary

Evidence inspected at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`; the engineering
audit was not repeated. The immutable candidate, family table, timing margins,
CDC comparison, safety invariant comparison, structural matrix, state, raw
timing-property table and three detailed worst-per-slot timing reports were
cross-checked. All 58 package manifest entries match and the package files
match the exact Git blobs.

Exactly nine independent checks exist, all PASS. Each has 56 sources and
3 normal-state, 4 containment, or 3 reset-accounting destinations. Collection
prefixes g2b_g15eq/g2b_g16eq/g2b_g17eq remain distinct; each source slot and
family matches the raw endpoint role. Shared destination cells do not merge
slot-specific timing relations. Each check has a 6.000 ns datapath-only cap,
actual delay below that cap, and positive reported slack.

## Evidence-only numerical cross-check

| Family | Actual datapath ns | Reported slack ns | Effective required ns | Endpoint adjustment ns | Arithmetic basis |
|---|---|---|---|---|---|
| `RELEASE_SLOT1_NORMAL_STATE_TRANSITION` | 5.548 | 0.528 | 6.076 | 0.076 | INFERRED_FROM_RAW_TIMING_PROPERTIES |
| `RELEASE_SLOT1_MISMATCH_CONTAINMENT` | 5.576 | 0.456 | 6.032 | 0.032 | EXPLICIT_SETUP_TERM_AND_REQUIRED_MINUS_ARRIVAL_IN_ROUTED_REPORT |
| `RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING` | 4.338 | 1.692 | 6.030 | 0.030 | INFERRED_FROM_RAW_TIMING_PROPERTIES |
| `RELEASE_SLOT2_NORMAL_STATE_TRANSITION` | 5.473 | 0.559 | 6.032 | 0.032 | INFERRED_FROM_RAW_TIMING_PROPERTIES |
| `RELEASE_SLOT2_MISMATCH_CONTAINMENT` | 5.772 | 0.260 | 6.032 | 0.032 | EXPLICIT_SETUP_TERM_AND_REQUIRED_MINUS_ARRIVAL_IN_ROUTED_REPORT |
| `RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING` | 4.480 | 1.550 | 6.030 | 0.030 | INFERRED_FROM_RAW_TIMING_PROPERTIES |
| `RELEASE_SLOT3_NORMAL_STATE_TRANSITION` | 5.515 | 0.557 | 6.072 | 0.072 | INFERRED_FROM_RAW_TIMING_PROPERTIES |
| `RELEASE_SLOT3_MISMATCH_CONTAINMENT` | 5.729 | 0.303 | 6.032 | 0.032 | EXPLICIT_SETUP_TERM_AND_REQUIRED_MINUS_ARRIVAL_IN_ROUTED_REPORT |
| `RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING` | 4.585 | 1.445 | 6.030 | 0.030 | INFERRED_FROM_RAW_TIMING_PROPERTIES |

Slack is the tool's required-time minus arrival-time value, not simply the
nominal max-delay cap minus datapath. The three detailed worst-per-slot
reports explicitly show a +0.032 ns endpoint setup contribution and
6.032 ns effective required time. For the six other rows, the table records
the implied endpoint adjustment from the matching raw properties; their
individual detailed setup arcs are not separately published in this package.
No inferred adjustment or measured actual/slack is made an architectural
requirement. The independently tested datapath cap is always 6.000 ns.

All nine protocol-margin rows independently establish 2 x 6.734 = 13.468 ns
minimum launch-to-use and 13.468 - 6.000 = 7.468 ns gross reserve. Normal use
and mismatch use the release-toggle qualifier; reset accounting uses the
separate two-stage transport-request qualifier and captured release phase.

All six pairwise structural comparisons are PARTIALLY_EQUIVALENT, including
slot 0 against slots 1, 2 and 3. Mapped depths and LUT input pins differ.
All eight safety invariants are PROVEN for every promoted slot. CDC structure
is PASS_WITH_DISPOSITION for each; no RTL change is required. The original
56/20 global scopes are INVALID_FOR_SKEW_COMPARISON. Previous Group-15 timeout
is VERIFIED; no global Group-15/16/17 report_bus_skew was executed in the audit
or in META-7R. Candidate scope COMBINED_ALL_THREE; runtime PRACTICAL;
replacement SAFER_AND_MORE_SEMANTICALLY_CORRECT. Owner review readiness was
YES_WITH_OWNER_ARCHITECT_REVIEW; this task supplies that approval.

The candidate creates no release-slot bus-skew relation. Other preserved
relations account for remaining TIMING-34/TIMING-39 findings; their final
disposition is outside this architecture decision. Global closure is not
claimed. Groups 9–14 PASS are preserved without repeating the audit.
