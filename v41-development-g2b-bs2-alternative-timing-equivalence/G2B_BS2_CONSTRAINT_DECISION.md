# G2B-BS2 Constraint Decision

## Decision

`GROUP9_CONSTRAINT_DECISION = REPLACE_WITH_EQUIVALENT_TIMING_CHECKS`

`ALTERNATIVE_SIGNOFF = FEASIBLE_WITH_CONSTRAINT_CHANGES`

This is a diagnostic recommendation. BS2 did not edit the production XDC.

## Basis

1. The exact 58-to-1 `report_timing` query completed and proved a 4.868 ns global worst datapath with +1.162 ns slack against the existing 6.000 ns datapath-only max-delay requirement.
2. The exact capped `get_timing_paths` query completed but covered only 1 of 58 source cells. Its 58 objects are reconvergent alternatives from `axis_slot_reg[1]`, so no 58-source arrival spread can be calculated.
3. `TIMING-34` is present: 3.000 ns is below half the shorter 6.734 ns clock period and Vivado warns that the aggressive value increases runtime.
4. `TIMING-39` is present: the constraint covers paths with more than one logic level. The exact worst path has six levels.
5. RTL/XDC review proves a toggle/ack stable-data mailbox, not a 58-bit parallel capture bank. The payload is held while a two-stage synchronized request controls a selector/equality decision.
6. A bus-skew result would not prove the actual temporal invariant. Structural mailbox proof plus a justified absolute settling bound would.

## What is and is not concluded

- The 3.000 ns relative-skew requirement is **not verified** by BS2.
- `ALTERNATIVE_COMPUTED_SKEW` is **not available**.
- Official `report_bus_skew` remains `NOT_COMPLETED` and was not retried.
- The existing 6.000 ns max-delay success is **not** relabeled as an equivalent bus-skew result.
- The current CDC architecture does not require redesign on available evidence.
- Removing Group 9 without replacement structural and absolute-delay proof is not recommended.

## Required follow-up before any production XDC edit

Open one XDC-only methodology gate to derive the per-family absolute settling budget from the two-stage request window, prove the mailbox hold/ack structure, and validate replacement `set_max_delay -datapath_only` scopes on the sealed DCP.

