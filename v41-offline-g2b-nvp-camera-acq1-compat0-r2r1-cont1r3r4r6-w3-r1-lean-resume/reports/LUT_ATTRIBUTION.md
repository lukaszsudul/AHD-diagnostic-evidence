# Existing candidate-2 LUT attribution, same post-opt stage

The parent is commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`; W3 candidate 2 is `98d4d214c1219b29a60dc1a33af13e91fe33d27c`. Both reports are Vivado 2025.2 SW 6299465 `Design State: Optimized` for `xc7a35tcsg325-2`. Parent hierarchy: `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R1_20260916T105442Z\build\POST_OPT_HIERARCHY.rpt`, SHA-256 `05CF22FC2034E61849E6C9B6390A5C85CC5D1F56783B9D8AE7E118DEBB64C69D`. Candidate-2 hierarchy: old W3 run `build/candidate2/POST_OPT_HIERARCHY.rpt`, 27,473 bytes, SHA-256 `DE70937D8FB00BD6DA2857F3AA978CAAD3EE7F7AAA578C64C0594C3A28E5AD26`.

| Nonoverlapping category | Parent total LUT | Candidate 2 total LUT | Delta LUT | Parent FF | Candidate 2 FF | Delta FF | Parent RAMB36 | Candidate 2 RAMB36 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Scanner core, including W3 child | 995 | 4,346 | +3,351 | 1,676 | 6,842 | +5,166 | 1 | 2 |
| I2C master | 197 | 294 | +97 | 172 | 276 | +104 | 0 | 0 |
| ACQ executor | 404 | 460 | +56 | 375 | 375 | 0 | 0 | 0 |
| AXI-Lite host bridge | 1,583 | 1,731 | +148 | 110 | 110 | 0 | 0 | 0 |
| All remaining top-level logic and optimization effects | 17,007 | 16,943 | -64 | 19,205 | 19,204 | -1 | 25 | 25 |
| **Whole design** | **20,186** | **23,774** | **+3,588** | **21,538** | **26,807** | **+5,269** | **26** | **27** |

Within the scanner category, the new `W3_TELEMETRY` child alone is **3,321 logic LUT, 5,151 FF and one RAMB36E1**. It is a child of the 4,346-LUT scanner and is **not added again** to the whole-design total. The scanner's own local row rose from 995 to 1,025 LUT (+30) and 1,676 to 1,691 FF (+15). The remaining scanner-category differences include the wrapping hierarchy and optimization. The candidate's 1,024×32 W3 payload really inferred one BRAM, but its record packing, counters and broad MMIO read selection dominated logic and FF cost.

Whole-design logic LUT grew **18,862→22,450 (+3,588)** while LUT-as-memory stayed **1,324→1,324 (0)**. F7/F8 mux counts grew **430→725 (+295)** and **43→128 (+85)**. RAMB18 remained 4. Thus the overrun is not a new LUTRAM explosion, and adding `ram_style="block"` alone cannot recover it. The governed total is 20,384; candidate 2 is 3,390 above it. The approved W3a reduction removes the broad new W3 telemetry and retains only a small bank-failure record and delay controls. No new resource result is inferred from this attribution; candidate 3 must be measured.

## Measured W3a candidate 3

The new clean build at commit `70266f0b90c6fc6a853495eba1d526b285fd7286` reached post-opt. Whole-design Slice LUTs were **20,456** (logic 19,132; memory 1,324), FF **21,833**, RAMB36 **26**, RAMB18 **4**. The candidate-3 hierarchy report has SHA-256 `5045CF6AA71D258FF441B72BC1B1AD78E03F459D687D61F0678996D334292118`; the whole-design report has SHA-256 `EE763C8E076AC3B59F0FE40FCCD93C48411DBC53EDB104BB5064830AFFF01886`. The reduced W3a child is 184 logic LUT, 289 FF and no new BRAM; the scanner including that child is 1,186 LUT and 1,968 FF. These are overlapping hierarchy rows and are not added to the whole-design total.

| Nonoverlapping category | Stable parent LUT | Full W3 candidate 2 LUT | Lean W3a candidate 3 LUT | Candidate 3 delta to parent |
|---|---:|---:|---:|---:|
| Scanner including W3 child | 995 | 4,346 | 1,186 | +191 |
| I2C master | 197 | 294 | 245 | +48 |
| ACQ executor | 404 | 460 | 454 | +50 |
| AXI-Lite host bridge | 1,583 | 1,731 | 1,551 | -32 |
| All remaining top-level logic and optimization effects | 17,007 | 16,943 | 17,020 | +13 |
| **Whole design** | **20,186** | **23,774** | **20,456** | **+270** |

The W3a reduction saved **3,318 post-opt LUT** against candidate 2, yet remained **72 LUT over** the governed 20,384 threshold. That is the first failed candidate-3 gate. Placement, routing, routed utilization and bit generation were not executed. The 20,800 physical capacity does not replace the 20,384 governed threshold.
