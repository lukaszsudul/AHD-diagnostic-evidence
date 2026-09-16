# CONT1R3 Manifest and Position Audit

Result: `PASS`.

- Exact entries: `82/82`.
- Actual execution groups: `10/10`.
- Clean physical register transactions: `105/105`.
- Semantic manifest digest: `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B`.
- CSV/JSON/package identities and generated entry/group tables: `PASS`.
- Contiguous equal-bank run boundaries: `0,27,37,48,59,70,81`.
- Actual execution-group boundaries: `0,1,4,11,27,37,48,59,70,81`.

## Execution groups

| Group | Name | Bank | Previous | Selection | Entries | Select tx | Verify tx |
|---:|---|---|---|---|---:|---:|---:|
| 0 | G0-PRE | 0x00 | N/A | FIRST_GROUP_NO_PREDECESSOR | 0..0 (1) | 2 | 3 |
| 1 | G0-ID | 0x00 | 0x00 | SAME_BANK_RESELECTION | 1..3 (3) | 5 | 6 |
| 2 | G0-LOCK | 0x00 | 0x00 | SAME_BANK_RESELECTION | 4..10 (7) | 10 | 11 |
| 3 | G0-CH | 0x00 | 0x00 | SAME_BANK_RESELECTION | 11..26 (16) | 19 | 20 |
| 4 | G1 | 0x01 | 0x00 | BANK_VALUE_CHANGE | 27..36 (10) | 37 | 38 |
| 5 | G2 | 0x05 | 0x01 | BANK_VALUE_CHANGE | 37..47 (11) | 49 | 50 |
| 6 | G3 | 0x06 | 0x05 | BANK_VALUE_CHANGE | 48..58 (11) | 62 | 63 |
| 7 | G4 | 0x07 | 0x06 | BANK_VALUE_CHANGE | 59..69 (11) | 75 | 76 |
| 8 | G5 | 0x08 | 0x07 | BANK_VALUE_CHANGE | 70..80 (11) | 88 | 89 |
| 9 | G0-POST | 0x00 | 0x08 | BANK_VALUE_CHANGE | 81..81 (1) | 101 | 102 |

The first four groups deliberately reselect Bank0. Therefore contiguous bank runs and execution groups are not interchangeable.

## CONT1R2 event join

- Ten occurrences occupied seven distinct manifest entries.
- Distinct contiguous-run-relative offsets: `0,1,1,3,4,4,5`.
- Correct distinct execution-group-relative offsets: `0,1,1,1,3,4,4`.
- Occurrence-weighted group-relative counts: `0:1, 1:4, 3:2, 4:3`.

Correction: the Bank0/0xB0 event at entry 5 is offset 5 in the contiguous Bank0 run, but offset 1 in actual execution group `G0-LOCK` (start entry 4). Prior bank-run offsets must not be relabeled as `POSITION_IN_GROUP`.

All joined bank/group/offset fields are derived from the byte-exact static manifest and FSM. They are not claims of a runtime bank readback. CONT1R3 telemetry will separately retain runtime-verified group context.
