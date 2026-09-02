# AHD v41 G2B-G13-A — Constraint and Replacement Analysis

## Strategy evaluation

| Strategy | Safety property proven | Property not proven | Runtime expectation | False-confidence risk | RTL impact | XDC impact |
|---|---|---|---|---|---|---|
| A. `KEEP_CURRENT_SET_BUS_SKEW` | If it completed, a 3 ns relative spread over the tool-selected paths | Stable hold, validity ordering, epoch association; timeout yields no result | `PATHOLOGICAL` on accepted evidence | High: unrelated paths can dominate a seemingly precise number | None | None |
| B. `KEEP_BUT_SPLIT_BY_SEMANTIC_FAMILY` | Relative spread within a selected family | Settling before ack; commit equality/hold; skew remains unnecessary | Marginal/unproven, especially the wide completion cone | Medium to high | None | Replace Group 13 with multiple skew commands |
| C. `PER_FAMILY_SET_MAX_DELAY_DATAPATH_ONLY` | Absolute payload/control-cone settling | Hold-until-ack and correct validity token if used alone | Practical | Medium if structural proof omitted | None | Replace Group 13 with two max-delay checks |
| D. `STRUCTURAL_RESET_CDC_PROOF_PLUS_ABSOLUTE_SETTLING` | Capture, hold, synchronized request/ack, commit equality, epoch ordering, and bounded settle-before-use | Later global CDC/timing gates outside Group 13 | Practical | Low when both halves are required | None | Replace only Group 13; retain aggregate 6 ns bound |
| E. `REMOVE_BUS_SKEW_USE_SYNCHRONIZER_PROOF` | Request/ack/commit synchronizer structure | Physical payload settling relative to validity | Practical | Medium: stable-data route could be arbitrarily late | None | Remove Group 13 without replacement; rejected |
| F. `REDESIGN_RESET_RETURN_CDC` | Could create an explicit FIFO or separately synchronized data protocol | Unnecessary until current protocol fails its actual invariant | Development/build/sign-off required | Low after a correct redesign, but high disruption | Yes | Yes |
| G. `OTHER_EVIDENCE_BASED_METHOD` | Formal hold-until-ack assertions could strengthen the structural proof | Routed absolute settling unless paired with timing | Practical after infrastructure exists | Low as a supplement, not a replacement | Possibly assertions only | No physical replacement by itself |

## Selected method

`SELECTED_STRATEGY = D`

The candidate XDC makes the two semantic family checks explicit at `6.000 ns`.
The governed aggregate source-mailbox max-delay constraint remains unchanged
and already covers a broader sink cone. The sign-off decision requires the RTL
structural proof in addition to routed family results; the XDC is not treated
as a complete CDC proof by itself.

Focused endpoint completeness is exact against the cited historical CDC
report: the 207 original commit-phase destinations plus 79 supplemental
aggregate destinations equal all 286 unique historically reported
commit-phase destination cells (`missing = 0`, `extra = 0`). The abandoned
family's 32 destinations likewise equal all 32 historically reported return
endpoints. The 79-cell supplemental check is coverage for the second semantic
family, not a third family.

## Candidate family properties

| Family | Correct property |
|---|---|
| `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` | `SETTLING_BEFORE_VALID` and `STABLE_UNTIL_ACK` |
| `RESET_COMMIT_PHASE_COMPLETION_BARRIER` | `SETTLING_BEFORE_VALID`, `STABLE_UNTIL_ACK`, and structural synchronized-phase equality |

Neither family requires `RELATIVE_SKEW`.

## Decision

`REPLACEMENT_EQUIVALENCE = SAFER_AND_MORE_SEMANTICALLY_CORRECT`

The replacement is not an approval of arbitrary skew. It retains the existing
6 ns absolute physical cap, explicitly checks both payload families, and adds
the protocol facts that the original bus-skew report could not establish. It
therefore proves the actual safety intent more directly without weakening it.

`RTL_CHANGE_REQUIRED = NO`

`GROUP13_FINAL_DISPOSITION = REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`

`CANDIDATE_XDC_READY_FOR_META = YES_WITH_OWNER_ARCHITECT_REVIEW`

The bounded routed validation passed for both semantic families and the
79-cell supplemental aggregate cone. These conclusions remain conditional on
retaining the unchanged broad 6 ns aggregate relation during promotion.
