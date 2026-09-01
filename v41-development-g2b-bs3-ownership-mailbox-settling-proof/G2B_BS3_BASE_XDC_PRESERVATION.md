# G2B-BS3 Temporary Base-XDC Preservation Proof

## Inputs

- Original full routed export: `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\BUS_SKEW_GROUPS\ROUTED_TIMING_FULL_SEMANTIC_PASS_2.xdc`
- Original SHA-256: `586917EE12FF31DDDCA58742E50F8342C8D1A97F2B8400176F916B87AFA5084D`
- Isolated BS3 base: `C:\FPGA\G2B_BS3_OWNERSHIP_20260902\G2B_BS3_FULL_BASE_WITHOUT_GROUP9.xdc`
- Isolated-base SHA-256: `3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507`

## Exact difference

`Compare-Object` found one original-only constraint line and two BS3-only comment lines. The original-only line is the single 3.000 ns ownership `set_bus_skew` whose source expression is `(own_slot_hold_axi|own_generation_hold_axi|own_epoch_hold_axi|axis_slot|axis_generation|axis_epoch)` and whose destination expression is the old 19-register ownership set. The two added lines state that Group 9 is intentionally omitted and that the isolated candidate loads afterward. No other constraint line differs.

| Property | Original | Isolated BS3 base | Result |
|---|---:|---:|---|
| `set_bus_skew` command count | 17 | 16 | PASS: exactly Group 9 removed |
| Non-Group-9 constraint lines | all | all preserved | PASS |
| Added active commands | 0 | 0 | PASS |

The candidate file is a replacement stanza, not a complete production XDC. Preservation is obtained by loading this verified temporary base and then the candidate. BS3 does not modify the original export or any active production XDC.

`BASE_XDC_PRESERVATION = PASS`
