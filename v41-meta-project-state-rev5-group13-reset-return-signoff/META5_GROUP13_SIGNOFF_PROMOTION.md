# META-5 Group-13 Sign-Off Promotion

## Evidence-qualified disposition

| Field | Accepted value |
|---|---|
| Group | `13` |
| Name | `RESET_RETURN_SOURCE_TO_AXI` |
| Original sign-off | `GLOBAL_SET_BUS_SKEW_3NS` |
| Original constraint | `set_bus_skew 3.000 -from $g2b_reset_return_src -to $g2b_reset_return_dst` |
| Original source/destination count | `7 / 207` |
| Previous timeout | `VERIFIED` (`301.094 s`) |
| Full `report_bus_skew` retried | `NO` |
| `report_timing` | `PASS`; `56.827 s`; worst datapath `3.756 ns` |
| `get_timing_paths` | `PASS`; `0.185 s`; 64 paths; maximum returned datapath `3.934 ns` |
| Path-set comparability | `INVALID_FOR_SKEW_COMPARISON` |
| Semantic classification | `STABLE_DATA + HANDSHAKE + COMMIT_PHASE_COMPLETION_BARRIER + COMBINATIONAL_AGGREGATION` |
| Promoted sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` |
| Replacement equivalence | `SAFER_AND_MORE_SEMANTICALLY_CORRECT` |
| RTL change required | `NO` |

## Exact semantic families

| Family | Physical scope | Required settling | Validation | Structural/use meaning |
|---|---|---|---|---|
| `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` | 3 held source bits to 32 `records_abandoned_axi` destination cells; all timing endpoint roles | `6.000 ns` absolute datapath-only; settling before valid; stable until acknowledgement | worst actual `2.634 ns`; slack `3.467 ns`; `PASS` | Binary count of committed/DMA-owned slots abandoned by reset, consumed only after synchronized request/acknowledgement qualification |
| `RESET_COMMIT_PHASE_COMPLETION_BARRIER` | 4 held per-slot phase bits to the original 207 Group-13 destination cells; all timing endpoint roles | `6.000 ns` absolute datapath-only; settling before valid; stable until acknowledgement; synchronized phase equality | worst actual `3.756 ns`; slack `1.723 ns`; `PASS` | Held commit-toggle phase drives direct capture and the equality-qualified reset-completion cone |

Exactly two semantic families are governed. The unchanged broad source-mailbox
`6.000 ns` max-delay relation remains mandatory and contains all 7/207
Group-13 members. Its separately validated 79-cell supplemental
commit-family fanout is not a third family; its worst actual is `4.681 ns`,
slack `0.967 ns`, `PASS`. Removing or changing that aggregate relation
invalidates accepted equivalence and requires Group-13 revalidation.

## Structural CDC obligations

1. Capture both held payloads on one source-clock edge when a new synchronized
   request phase is accepted.
2. Hold both payloads stable throughout the outstanding acknowledgement.
3. Preserve intentional two-stage request and acknowledgement synchronizers.
4. Preserve the two-stage live commit-phase synchronizer.
5. Permit completion only with reset busy, acknowledgement phase equal to
   request phase, synchronized live commit phase equal to the held phase, and
   hard-episode qualification.
6. Preserve reset-return coherency and destination-use sequencing; publish
   epoch/state atomically only on the qualified completion edge.
7. Exclude commit-phase parity alias through protocol sequencing: reset
   handling is exclusive of ordinary source processing, admission is disabled,
   and commit enqueue/scheduler progress is suppressed while reset is busy.
8. Treat reset assertion/deassertion as synchronously observed process
   conditions, not async-assert/sync-release Group-13 crossings.
9. Retain fresh global CDC closure as a later hard gate.

Timing alone is not sufficient; structural proof alone is not sufficient. The
governed replacement is their conjunction.

## Implementation boundary

- Active production XDC change: `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`.
- Candidate authority: `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` at
  `10c7c2898d162af8e2262b3f99861c7d560c4557`.
- Groups 10–12: `PRESERVE_PREVIOUS_RESULTS`.
- Groups 14–17: `PENDING_UNCHANGED`.
- Group 9: preserve PASS; do not repeat.
- Next allowed step: `G2B-LUT1-SIGNOFF-RECOVERY-2`.
- Bitstream: only after all remaining hard gates pass; not part of META-5.
