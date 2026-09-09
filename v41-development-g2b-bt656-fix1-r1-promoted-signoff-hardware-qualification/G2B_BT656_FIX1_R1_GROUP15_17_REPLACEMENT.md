# Groups 15-17 replacement

Promoted method: `SETTLING_PLUS_STRUCTURAL_CDC`. Global bus-skew relation: `RETIRED_ABSENT`. Replacement checks: **9/9 PASS**. Settling cap: 6.000 ns. Object-count contracts and routed timing details are preserved in the raw reports.

| Group | Family | Sources | Destinations | Delay ns | Slack ns | Result |
| --- | --- | --- | --- | --- | --- | --- |
| 15 | RELEASE_SLOT1_NORMAL_STATE_TRANSITION | 56 | 3 | 5.028 | 1.044 | PASS |
| 15 | RELEASE_SLOT1_MISMATCH_CONTAINMENT | 56 | 4 | 5.130 | 0.903 | PASS |
| 15 | RELEASE_SLOT1_RESET_OVERLAP_ACCOUNTING | 56 | 3 | 4.603 | 1.469 | PASS |
| 16 | RELEASE_SLOT2_NORMAL_STATE_TRANSITION | 56 | 3 | 5.884 | 0.148 | PASS |
| 16 | RELEASE_SLOT2_MISMATCH_CONTAINMENT | 56 | 4 | 5.143 | 0.890 | PASS |
| 16 | RELEASE_SLOT2_RESET_OVERLAP_ACCOUNTING | 56 | 3 | 4.345 | 1.727 | PASS |
| 17 | RELEASE_SLOT3_NORMAL_STATE_TRANSITION | 56 | 3 | 5.620 | 0.452 | PASS |
| 17 | RELEASE_SLOT3_MISMATCH_CONTAINMENT | 56 | 4 | 5.269 | 0.764 | PASS |
| 17 | RELEASE_SLOT3_RESET_OVERLAP_ACCOUNTING | 56 | 3 | 4.318 | 1.754 | PASS |

Governed earliest semantic use: 13.468 ns. Governed gross reserve: 7.468 ns.
