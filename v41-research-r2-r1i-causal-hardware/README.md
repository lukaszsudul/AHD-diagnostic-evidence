# AHD v41 R2 R1i Causal Hardware Evidence

Result: `BLOCKED`

This directory records the offline R2 execution preflight performed during the
authorized R-track overnight continuation on 2026-08-28. No R2 arm was started
and no hardware was accessed.

The two independent stop conditions were:

1. exclusive ownership through the exact shared `FPGA_AHD_HW_LOCK` could not be
   proven because no canonical executable/state receipt exists; and
2. the frozen 32-run, eight-run-per-cell campaign could not be completed before
   the 07:45 no-new-work cutoff using the already proven hardware sequence.

The frozen R0 denominator, order, interpretation matrix, candidates, and
qualified product baseline were not changed.
