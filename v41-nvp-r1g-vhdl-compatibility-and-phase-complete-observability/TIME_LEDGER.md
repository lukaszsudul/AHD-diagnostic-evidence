# R1g VHDL compatibility and phase-complete observability time ledger

| UTC | Event |
|---|---|
| 2026-08-24T15:06:33.1993890Z | Fresh R1g task root created; owner prompt saved; all counters initialized to zero before source mutation or live/toolchain action. |
| 2026-08-24T15:20:43.4888736Z | Exact R1f/default-production-mode `xvhdl` iteration reproduced only the known line-994 VHDL-2008 incompatibility; exit 1, no source mutation, no synthesis. |
| 2026-08-24T15:21:38.8800710Z | Frozen line-994 compatibility-only rewrite applied: 5 added lines, 1 removed line, one VHDL source file, source commits still 0. |
| 2026-08-24T15:24:00.2040044Z | R1g mechanical candidate compiled PASS_ALL_FILES in the exact default non-2008 production mode; exit 0, no synthesis. |
| 2026-08-24T15:37:12.2614755Z | Offline host/campaign tooling and 27 fixtures passed; active R1g hardware binding remains fail-closed pending commit and bit; no live action. |
| 2026-08-24T15:46:54.0382906Z | Independent preflight/build-script static audits passed; no preflight, synthesis, implementation, or build executed. |
| 2026-08-24T16:36:11.0000000Z | Created the sole R1g source commit `e112a5addb7ac62700a9a71af81bf368fad0bada`, tree `3a59ebec130103055d24a3a32ecda00dedde5534`, as the exact one-file direct child of R1f; source tree clean and source mutation closed. |
| 2026-08-24T16:38:21.0000000Z | Sole production-front-end RTL preflight consumed and PASS: exact commit/tree/top/part/default-VHDL contract, `synth_design -rtl`, zero unsupported-language errors, no implementation/checkpoint/bitstream, exit 0. |
| 2026-08-24T16:50:30.0000000Z | Prebuild manifest `F31220B0...473B9` finalized after two non-consuming fail-closed evidence-binding iterations; independent audit verified 51/51 source and 37/37 evidence records and released exactly one full clean build. |
| 2026-08-24T16:54:10.0000000Z | Sole full clean build sentinel consumed before project creation, bound to exact R1g commit/tree, manifest and Vivado 2025.2 build 6299465; no retry authorized. |
| 2026-08-24T16:56:12.0000000Z | Sole full-build synthesis invocation began for exact top `ahd_capture_top_xdma` and part `xc7a35tcsg325-2`; synthesis-run count is 1. |
| 2026-08-24T17:25:22.9183753Z | Full synthesis completed PASS with 0 errors, 0 critical warnings, and no recurrence of `Synth 8-2757`; the same sole build began implementation at `opt_design -directive Explore`, implementation-run count 1, retry count 0. |
| 2026-08-24T17:26:07.0000000Z | Sole clean build stopped at `place_design` precondition DRC `UTLZ-1`: LUT-as-logic 30,926/20,800 and register/slice-register 44,248/41,600; placer not run, no phys-opt/route/routed DCP/bitstream, no retry, hardware not released. |
| 2026-08-24T17:36:43.3965088Z | Independent terminal/routed/hardware/pre-seal evidence reconciled and the single authoritative R1g report created, SHA-256 `6BD146E4...0638B`, with 167/167 required fields populated; package and publication remain pending. |
