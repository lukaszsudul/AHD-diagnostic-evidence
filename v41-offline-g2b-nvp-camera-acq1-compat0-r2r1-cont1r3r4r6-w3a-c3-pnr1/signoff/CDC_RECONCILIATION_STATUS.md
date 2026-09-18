# C3-PNR1 current-route CDC reconciliation

The current-route semantic reconciliation is `PASS_CURRENT_C3_SEMANTIC_MANIFEST_RECONCILED`. Its machine-checked receipt is `CDC_CURRENT_GATE.json`. No broad CDC waiver was applied.

- Current routed `report_cdc` SHA-256: `9AF9FAED82128AB7DF9FDC4C6A46560E78205336CA31BE4E012F1C0080B1BDDA`.
- Accepted R2R1 report SHA-256: `7409D7840381D1F4486677E7E66FF1BAC6AE9ED8CB1B71A213EEA4C13F3FA84B`; accepted semantic manifest SHA-256: `159E82D814E92DC4AE1B611DC98E1C46C8F01A11411363EFE53D0933880EA89A`.
- Both reports have 1337 rows with the same rule/severity distribution: 427 critical, 874 warning, 36 information. This aggregate equality does not prove row identity.
- For unchanged non-source row keys, 53 current physical source representatives differ (26 critical, 27 warning). The detailed mapping is in `CDC_CHANGED_SOURCES.csv`.
- Sixty-four `CDC-15` warning destinations moved from the `/D` to the `/S` pin of the same `G2B_ONECH_C2H/shadow_last_channel_reg[...]` or `shadow_last_global_reg[...]` cells. They account for 128 two-sided non-source multiset delta entries in `CDC_NON_SOURCE_DELTA.csv`.
- The C3 `rtl/g2b/v41_g2b_onech_c2h.sv` Git blob is the accepted `bd9b4b1d4b43d04086477657e57392440527c1d9`.
- Fresh current-route fan-in extraction confirms exact full and cross-clock source-set equality for all 53 changed representatives: 41 against the accepted destination-cone inventory and 12 against a new, read-only extraction from the hash-pinned accepted routed DCP.
- For all 64 `/D`→`/S` migrations, the cross-clock startpoint set on `/S` equals the accepted `/D` set exactly (four reset-commit stable-payload source registers); current `/D` has zero such cross-clock startpoints. Both routed netlist inventories retain the same 64 `FDSE` cells. Each full `/S` cone differs by one same-clock substitution: the accepted `last_channel_axi` or `last_global_axi` register is replaced by the current XDMA `user_reset_out_reg`, which is on `userclk1`. This is not a new CDC source.
- Current structural CDC, 17/17 promoted checks including both Group-13 settling checks, and 11/11 exact bus-skew groups passed. The bus-skew procedure restored the full XDC, clock and route signatures, and original WNS/WHS.

Disposition: `PASS_CURRENT_C3_SEMANTIC_MANIFEST_RECONCILED`. This is a static routed-cone and timing proof under the unchanged C2H RTL and accepted semantic manifest, not a new behavioral simulation or hardware qualification.
