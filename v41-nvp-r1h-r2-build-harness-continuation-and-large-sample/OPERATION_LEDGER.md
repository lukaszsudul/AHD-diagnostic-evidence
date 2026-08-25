# Operation ledger — R1h-R2

Task: `V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION`

This ledger is task-local. It does not mutate the FPGA source repository.

| UTC time | Operation | Classification | Result / accounting |
|---|---|---|---|
| 2026-08-25T07:09:45.9545663Z | Created the required R1h-R2 task-root directory structure. | Task-local filesystem setup | PASS; source/RTL/Vivado/hardware untouched. |
| 2026-08-25T07:09:45.9545663Z | Created operation and time ledgers immediately after the directory structure. | Task-local evidence setup | PASS. |
| 2026-08-25T07:09:45.9545663Z | Requested an exact machine-readable copy of the owner prompt from the root agent. | Fail-closed prompt preservation | PENDING; no manual reconstruction or invented prompt text. |
| 2026-08-25T07:18:30.7277606Z | Verified the exact prompt recovered from the current session JSONL shared read. | Prompt preservation | PASS; 44,348 bytes; SHA-256 `395E5DDE111B006792BB75B3F95AF266E9EFF357E787CD854FDC4F35F01402A5`. The earlier pending item is resolved. |
| 2026-08-25T07:18:30.7277606Z | Verified exact terminal R1h commit, tree, parent, clean worktree, and 22 changed-path hashes. | Read-only source identity | PASS; no repository mutation. |
| 2026-08-25T07:18:30.7277606Z | Rehashed R1h report/package, all 1,799 manifest rows, and all 1,800 ZIP entries; streamed public commit-pinned report and LFS package. | Read-only evidence identity | PASS; public `main` is exact evidence commit `7dc8b8f...`. |
| 2026-08-25T07:18:30.7277606Z | Reverified R1g, resource-audit, formal-bit, R7-package, and 14 inherited tool identities. | Read-only predecessor identity | PASS. Formal Phase 2 remains historical and was not freshly confirmed. |
| 2026-08-25T07:22:33.1081229Z | Located and audited the exact terminal compile-order assertion and the adjacent SystemVerilog positional gate. | Read-only build-harness audit | PASS; ordinary SystemVerilog module binding has no relative-file-position requirement; the genuine VHDL dependency-order gate was retained. |
| 2026-08-25T07:27:13.0081317Z | Froze the task-local corrected full-build harness. | Task-local build-harness correction | PASS; corrected Tcl SHA-256 `5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F`; repository mutations and tracked harness commits remained zero. |
| 2026-08-25T07:56:28.2140353Z | Completed the sole project-setup dry-run. | Authorized non-synthesis Vivado project setup | PASS; one invocation, process exit 0, semantic gate PASS, no synth/opt/place/route/checkpoint/bitstream. |
| 2026-08-25T08:08:46.1399957Z | Started the sole semantic frontend/elaboration preflight. | Authorized simulation frontend | Consumed exactly once; `xvhdl/xvlog/xelab=1/1/1`. |
| 2026-08-25T08:09:23.6618725Z | Completed the sole semantic frontend/elaboration preflight. | Authorized simulation frontend | PASS; unresolved modules 0, unresolved black boxes 0, failed-record/probe-index/MMIO/top bindings PASS, process exit 0. |
| 2026-08-25T08:19:05.9448389Z | Finalized the R1h-R2 prebuild manifest after P3/P4 PASS. | Task-local provenance gate | PASS; manifest SHA-256 `9926A439A41967304202D77A669F2F6A8F976F3A239D9D602F2AD4D4857644A1`; 58 META, 224 source and 40 accepted-log records. |
| 2026-08-25T08:37:41Z | Atomically consumed the one newly authorized R1h-R2 clean build. | Full-build accounting boundary | PASS; exact `c4f4bfcf...` / tree `161e561f...`, corrected harness, manifest and Vivado 2025.2 build 6299465 bound before project creation. |
| 2026-08-25T08:58:33Z | Generated the exact post-synthesis checkpoint. | Sole full build, synthesis stage | PASS; `synth_design=1`, 0 errors, 0 critical warnings; DCP SHA-256 `807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E`. |
| 2026-08-25T08:59:30Z | Evaluated the mandatory full-top memory-mapping and resource-margin gates before optimization/placement. | Fail-closed post-synthesis gate | Memory mapping PASS (`6+1+1+1 RAMB18`, new payload total 9, RAM64M/RAMD64E 0, payload FDRE 81+3); register margin PASS (`20395 <= 37440`); Slice-LUT margin FAIL (`19255 > 18720`, excess 535). |
| 2026-08-25T08:59:35.7750435Z | Terminated the sole clean build at the post-synthesis gate. | Required hard stop | `BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING`; the evidence proves the failing sub-gate was LUT margin only. `opt/place/route/bitstream=0`; no retry and no hardware action. |

Initial accounting:

```text
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
PROJECT_SETUP_DRY_RUNS=0
SEMANTIC_ELABORATION_PREFLIGHTS=0
FULL_CLEAN_BUILDS=0
SYNTH_DESIGN_INVOCATIONS=0
OPT_DESIGN_INVOCATIONS=0
PLACE_INVOCATIONS=0
ROUTE_INVOCATIONS=0
BITSTREAMS=0
FPGA_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
DMA_TRANSFERS=0
PHYSICAL_ACTIONS=0
```

Terminal accounting after the sole authorized build:

```text
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
PROJECT_SETUP_DRY_RUNS=1
SEMANTIC_ELABORATION_PREFLIGHTS=1
FULL_CLEAN_BUILDS=1
SYNTH_DESIGN_INVOCATIONS=1
OPT_DESIGN_INVOCATIONS=0
PLACE_INVOCATIONS=0
ROUTE_INVOCATIONS=0
BITSTREAMS=0
FPGA_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
DMA_TRANSFERS=0
PHYSICAL_ACTIONS=0
```
