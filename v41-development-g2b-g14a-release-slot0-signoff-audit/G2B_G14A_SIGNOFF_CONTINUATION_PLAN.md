# G2B-G14-A sign-off continuation plan

This is a future execution plan only. Nothing in this plan was executed by G14-A.

## META prerequisite

1. Conduct one owner/architect META review of `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` and this semantic/CDC proof.
2. If approved, promote only the Group-14 replacement into governed active XDC and update SSOT through the authorized governance process.
3. Reconfirm source commit/tree and routed-DCP applicability before continuing.

## Preserved gates and continuation order

1. Group 9: `PRESERVE_PASS`; do not repeat.
2. Groups 10-12: `PRESERVE_PASS`; do not repeat.
3. Group 13: `PRESERVE_PASS`; do not repeat.
4. Group 14: apply the governed replacement and validate the three settling families plus structural CDC/protocol checks.
5. Groups 15-17: continue from the existing pending boundary.
6. Run routed timing sign-off.
7. Run DRC sign-off.
8. Run focused/full CDC sign-off as governed.
9. Verify clocks.
10. Verify resources.
11. Complete pre-bitstream gate.
12. Generate and validate bitstream only after all preceding gates pass and separate authorization exists.

## Stop conditions

Stop on any source/DCP/SSOT drift, failed family bound, failed structural invariant, non-practical replacement runtime, or new first blocker. Do not silently weaken the 6.000 ns governed cap. Do not restore the global Group-14 bus-skew constraint unless new evidence establishes a genuinely comparable bus bundle.

## Current boundary

- Group 9: `PRESERVE_PASS`
- Groups 10-12: `PRESERVE_PASS`
- Group 13: `PRESERVE_PASS`
- Group 14: audited candidate ready for owner/architect META review
- Groups 15-17: `PENDING`
- Execution point: hard stop after G2B-G14-A
