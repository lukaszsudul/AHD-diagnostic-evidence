# AHD v41 CH3 R2R10R11R1 — post-synth continuation

## Result

The exact R11 post-synthesis checkpoint was continued with one default `opt_design`, followed by one conditional `place_design`, one `route_design` and one `write_bitstream`.

- Result: `BITSTREAM_GENERATED_UNTESTED`
- New synthesis: `0`
- Post-opt Slice LUT: `20321 / 20800` — PASS
- Routed Slice LUT: `19855 / 20800` — PASS
- Routing: `39033 / 39033` routable nets fully routed, 0 routing errors
- Native router estimate: WNS `+0.123 ns`, TNS `0`, WHS `+0.036 ns`, THS `0`
- Mandatory bitgen DRC: 0 errors

The source remains the scoped experimental EQ-finalization candidate. No source change, functional test, simulation or additional timing/CDC/bus-skew sign-off was performed. The generated artifacts remain private.

One technical pre-opt resume corrected a task validator that used the checkpoint object name instead of its top property. No opt/place/route/bitgen stage was repeated.

## Boundaries

This build does not demonstrate a live camera scene, full vendor adaptive EQ, product qualification, a pattern-root-cause repair or the physical cause of the historical REGADDR_NACK. No DUT access or hardware operation occurred. Hardware activation requires separate Owner authorization.