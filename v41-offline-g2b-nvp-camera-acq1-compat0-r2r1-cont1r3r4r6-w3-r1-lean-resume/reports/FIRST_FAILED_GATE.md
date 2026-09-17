# W3a candidate 3: first failed gate

Task `CONT1R3R4R6-W3-R1-LEAN-RESUME`; source commit `70266f0b90c6fc6a853495eba1d526b285fd7286`, tree `5f2bd8377985406b45433418b20be8993399bcb6`. The frozen 40-input build manifest is `build/W3A_CANDIDATE3_SOURCE_BUILD_MANIFEST.json`, SHA-256 `2CA4660A9AE81099E230E573D6A40EC28BE411A9F867A00A87B04F1F7677D4F8`. One Vivado 2025.2 SW build 6299465 worker was run with `general.maxThreads 1`; exit code **1**.

Synthesis completed with zero errors and zero critical warnings. `opt_design` completed successfully. The hard stop in `build/w3a_candidate3_full_implementation.tcl:121` then raised the exact error `POST_OPT_LUT_GATE_FAILED:20456`. The governed limit is **20,384** whole-design Slice LUTs, so the excess is **72**. No placement, physical optimization, route, routed DCP, independent DCP reopen, bus-skew sign-off or bit generation was run. It would be invalid to claim routed timing, CDC or DRC results for this candidate.

| Stage | Slice LUT total | LUT logic | LUT memory | FF | RAMB36 | RAMB18 |
|---|---:|---:|---:|---:|---:|---:|
| Post-synthesis, diagnostic only | 22,053 | 20,664 | 1,389 | 22,740 | 26 | 6 |
| **Post-opt, hard gate** | **20,456** | **19,132** | **1,324** | **21,833** | **26** | **4** |

The inherited scanner telemetry RAM inferred one RAMB36 cell as expected. The reduced W3a child used 184 LUT and 289 FF, no RAMB36. It is already included in the 20,456 total. Compared with full W3 candidate 2, this saved 3,318 LUT, but it did not pass the threshold. All three originally budgeted candidate revisions are now used; no fourth candidate or source correction was attempted after build start.

Raw log: `build/candidate3_vivado.log`, 353,980 bytes, SHA-256 `B2A0CFAC6FE474CF6318563553EEA7C893E2AF33017D26C3B55CB77C1B504120`. Post-opt whole-design report: `build/candidate3/POST_OPT_UTILIZATION.rpt`, 10,628 bytes, SHA-256 `EE763C8E076AC3B59F0FE40FCCD93C48411DBC53EDB104BB5064830AFFF01886`. Post-opt hierarchy: 27,473 bytes, SHA-256 `5045CF6AA71D258FF441B72BC1B1AD78E03F459D687D61F0678996D334292118`. These task-local artifacts remain unmodified.

The new source branch has a commit-pinned byte read-back receipt for all 40 selected inputs and seven changed host files: `reports/SOURCE_REMOTE_READBACK.json`, result PASS 47/47. The source worktree remains clean. `XSIM_NEW_RUNS=0`; dynamic behavior of the changed W3a RTL is `NOT_RUN_OWNER_REQUESTED_SPEEDUP`, and static review is not functional equivalence proof.
