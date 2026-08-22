# Formal Phase-2 zero-range proof

The unchanged v41 control-status plane handles only `0x0000..0x00FF` locally
and forwards `0x2200..0x2228` unchanged. The preserved
`g0p8c2_bar_target`, for reads below `0x10000`, derives the slot from address
bits `[15:12]`. For `0x22xx` that slot is 2. The formal top sets
`SLOT_COUNT=2`, making legal slots 0 and 1. Source lines 360-364 of
`rtl/pio/pio_bar_target.sv` therefore take the reserved-slot branch and return
`32'b0` deterministically. No existing formal register occupies any word in
the selected range.

`FORMAL_PHASE2_PROBE_RANGE_READS_ZERO=YES`

