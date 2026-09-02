# META-4R2 Group-9 Sign-Off Promotion

## Diagnostic disposition

| Evidence | Governed conclusion |
|---|---|
| BS1R `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62` | Exact 58-to-1 `report_bus_skew` pathology reproduced. |
| BS2 `4699632c591238fee46ada3b0de37532fddd0b6f` | Path set invalid for skew comparison; equivalent checks feasible with constraint changes. |
| BS3 `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` | Stable-data ownership CDC structure and per-family settling method valid and semantically correct. |

Therefore `GLOBAL_GROUP9_REPORT_BUS_SKEW =
RETIRED_FROM_REQUIRED_SIGNOFF`. Another global Group-9 execution is not
required.

## Current Group-9 recipe

The governed `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` path requires:

1. ownership structural CDC proof;
2. request synchronizer validation;
3. acknowledgement synchronizer validation;
4. stable-data hold proof;
5. per-family settling checks;
6. reset/epoch coherency proof;
7. normal routed timing;
8. CDC disposition;
9. DRC;
10. clocks/resources; and
11. pre-bitstream hard gate.

The recipe excludes retired global Group-9 `report_bus_skew`. The settling
limit is exactly `6.000 ns`; its basis is `13.468 ns` minimum launch-to-use
and `7.468 ns` gross reserve. No other timing limit is introduced.

## Remaining sign-off

`GROUPS_10_TO_17 = UNCHANGED`. The future
`G2B-LUT1-SIGNOFF-RECOVERY` task may implement
`G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc` under governed source-change
procedure, then complete Group 9, Groups 10–17, routed timing, DRC, CDC,
clocks/resources, and the pre-bitstream hard gate. META-4R2 does not perform
that work and does not authorize hardware access.
