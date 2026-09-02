# AHD v41 G2B-G13-A — Sign-Off Continuation Plan

## Preserved completed gates

- Group 9 `OWNERSHIP_AXI_TO_SOURCE`: preserve the authoritative promoted
  `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` PASS. Do not repeat it.
- Group 10 `DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI`: preserve predecessor PASS.
- Group 11 `DESCRIPTOR_GENERATION_SOURCE_TO_AXI`: preserve predecessor PASS.
- Group 12 `DESCRIPTOR_EPOCH_SOURCE_TO_AXI`: preserve predecessor PASS.

No G13-A evidence invalidates those results. The accepted routed DCP and
promoted Group-9 context are unchanged.

## Exact continuation after META acceptance

1. Owner/Architect reviews and promotes the Group-13 replacement method and
   candidate XDC through the governed META/source-change process.
2. In the existing routed sign-off flow, resume at Group 13 and run only the
   accepted per-family settling checks plus the recorded structural CDC proof.
3. Continue with unchanged Groups 14, 15, 16, and 17.
4. Continue the remaining routed hard gates that the predecessor did not reach:
   final setup/hold timing, timing methodology, DRC, focused/global CDC as
   governed, clocks/resources, protection checks, and the pre-bitstream gate.
5. Do not create a bitstream or enter G2B-HW until every remaining offline hard
   gate passes under current authority.

`GROUPS_10_TO_12 = PRESERVE_PREVIOUS_RESULTS`

`GROUPS_14_TO_17 = PENDING`

`FINAL_CONTINUATION_POINT = GROUP_13_REPLACEMENT_THEN_GROUPS_14_TO_17_THEN_REMAINING_ROUTED_HARD_GATES`

## Current project state

This audit does not promote the candidate and does not modify SSOT. G2B-LUT1
remains blocked in sign-off recovery, and G2B-HW remains `BLOCKED / NOT_PROVEN`.
`PROJECT_STATE_REV` remains 4.
