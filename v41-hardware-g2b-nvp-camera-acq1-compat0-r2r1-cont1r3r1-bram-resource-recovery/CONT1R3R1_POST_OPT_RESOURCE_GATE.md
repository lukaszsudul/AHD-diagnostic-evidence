# Candidate 1 post-opt resource gate

Fresh nonincremental Vivado 2025.2 post-opt screen, exact source commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`, part `xc7a35tcsg325-2`, profile `NVP_CAMERA_ACQ1_COMPAT0_R2`. This screen used a fresh regenerated project/IP and no prior implementation checkpoint. `POST_OPT_CANDIDATE_RESULT.txt` records one telemetry RAMB36E1 and successful `opt_design`.

| Metric | Accepted R2R1 reference | Failed CONT1R3 | Candidate 1 post-opt |
|---|---:|---:|---:|
| Whole-design Slice LUT | 19,574 | 21,446 | **20,186** |
| SCAN1 leaf Slice LUT | 687 | 2,017 | **995** |
| SCAN1 leaf LUTRAM (included in LUT) | 96 | 1,104 | **96** |
| AXI-Lite bridge hierarchy LUT | 1,294 | 1,791 | **1,583** |

Candidate 1 total is **1,260 LUT below** failed CONT1R3 and **612 above** R2R1. It is **198 LUT below** the mandatory post-opt ceiling of 20,384. The SCAN1 leaf has 1,022 fewer LUT than failed CONT1R3, including 1,008 fewer LUTRAM. Bridge hierarchy has 208 fewer LUT; these hierarchy deltas are descriptive and are not added to the whole-design delta. The bridge's remaining +289 versus R2R1 is an observed mapping result, not assigned to one RTL operator.

Candidate post-opt utilization: 20,186/20,800 LUT (97.05% physical capacity), 18,862 LUT as logic, 1,324 LUT as memory, 21,538/41,600 FF, 28/50 block RAM tiles and 0/90 DSP. `POST_OPT_HIERARCHY.rpt` reports SCAN1 leaf 995 LUT/1,676 FF, combined scanner/executor wrapper 1,412 LUT, fixed master 197 LUT and AXI-Lite bridge 1,583 LUT. Do not sum nested wrapper/leaf rows.

**Post-opt resource gate: PASS.** This is not final routed resource sign-off, timing sign-off, bitstream qualification or hardware evidence. The final fresh implementation is separate and must meet the same LUT ceiling after route.
