# CONT1R1 host projection test results

Gate: `CONT1R1_HOST_PROJECTION_GATE`

Result: `16/16 PASS`

| Test | Result | Requirement | Detail |
|---|---|---|---|
| T1 | PASS | exact 82-entry manifest preflight | exact 82-entry manifest projection preflight PASS |
| T2 | PASS | old Bank1/0x88 family fails preflight | HOST_PROJECTION_KEY_NOT_IN_SCANNER_MANIFEST:(0x01,0x88),(0x01,0x89),(0x01,0x8A),(0x01,0x8B) |
| T3 | PASS | ADC delay family 0x84-0x87 | Bank1/0x84-0x87 present and mapped to ADC clock delay |
| T4 | PASS | pre-clock family 0x8C-0x8F | Bank1/0x8C-0x8F present and mapped to pre-clock |
| T5 | PASS | wrong bank cannot satisfy full key | same register in Bank0 does not satisfy Bank1/0x84 |
| T6 | PASS | missing real key fails preflight | HOST_PROJECTION_KEY_NOT_IN_SCANNER_MANIFEST:(0x01,0x8F) |
| T7 | PASS | unused extra key is tolerated | unused extra manifest key does not alter projection compatibility |
| T8 | PASS | preserved snapshot qualification | exact preserved CONT1 snapshot host qualification PASS |
| T9 | PASS | preserved bytes unchanged | JSON and 584-byte raw snapshot remain byte-identical |
| T10 | PASS | physical scanner receipt | 82/82 entries, 10/10 groups, 105/105 transactions, restore PASS |
| T11 | PASS | no NVP write path added | no functional NVP write path added; ACQ controller subtree byte-identical |
| T12 | PASS | no FPGA/SCAN1 manifest/MMIO change | SCAN1 source/resources/manifest/MMIO files byte-identical |
| T13 | PASS | physical and projection receipts separate | physical scanner receipt and host projection receipt are separate fields |
| T14 | PASS | channel expansion exact | both channel families expand exactly for ch=0..3 |
| T15 | PASS | old/new expected result difference | old FAIL on 0x88-0x8B; corrected projection PASS on same bytes |
| T16 | PASS | deterministic projection output | DB00A53D85502582A9F5B9C121CC6021445204080E50B083F280897CF8DF6294 |
