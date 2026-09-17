# W3a C4 resume journal

- Task: CONT1R3R4R6-W3A-C4-RESOURCE-RECOVERY; one Owner-authorized fourth candidate only.
- Parent source: commit 70266f0b90c6fc6a853495eba1d526b285fd7286, tree 5f2bd8377985406b45433418b20be8993399bcb6.
- Isolated source: `C:\FPGA\W3A_C4_RECOVERY_20260917T205032Z\source`, branch `codex/v41-w3a-c4-resource-recovery-20260917T205032Z`; primary checkout and old run roots preserved.
- Candidate ledger at resume: 1 top-width failure; 2 post-opt resource failure; 3 post-opt 20,456 LUT (72 over 20,384), no route or bitstream. C4 absent before this work.
- Process inventory: no previous-run Vivado, XSim, Git, or Python worker bound to the old roots; no process terminated.
- SSOT: project-state revision 9, checked in required order. Local current-state tree 24e8b5e3f7b151bebe6b8da5dc102d734037ee48 matches remote main; evidence-only main advance is not a technical-state change.
- Existing receipts: old W3 evidence 54/54, candidate-3 source 47/47, candidate-3 evidence 18/18 commit-pinned byte readback identities checked. No historical publication repeated.
- C3 resource attribution: 20,456 total; W3a child 184 LUT and 289 FF; stable parent 20,186; 3,318 LUT below full W3 C2. Candidate-3 report used read-only.
- C4 selected correction: collapse W3a MMIO read into the scanner's existing registered response, removing the additional W3a read register/pending stage; use a 64-byte word decoder and a two-block page decode. Resource benefit remains unmeasured until the one C4 build.
- C4 source frozen: commit 9ce74cd76ac33b3d37cde0bced7326a2c31fa0f1, tree f7da5163e29477e5c773fce43d657e2a6726cb6e, six changed source paths. Input manifest SHA-256 0C112E2004EE15B30BD3E4B33092D81B8791C76B61030DCB848FA32B0A30A729 (40 build inputs). Source branch push plus independent commit-pinned 47/47 byte readback PASS. Contract SHA-256 FAFF9B7638474BFD43E77A7866A337F49B869B36014A3677685E00CACF546424.
- Closed host bundle: seven source files copied byte-exactly; offline self-test PASS with `device_opened=false`. Bundle manifest SHA-256 382E5CF7DF9A7C12214AE7C41067E4A03566DC4DD078EF9C26A1AE7E769A6C81.
- One C4 Vivado 2025.2 SW build 6299465 started from the frozen recipe; synthesis completed with 0 errors/0 critical warnings, `opt_design` completed, then the first hard gate failed at 20,540 Slice LUT versus 20,384. Exit code 1; no place/route, routed DCP or bitstream. Independent process inventory after exit showed no Vivado/XSim worker. No source correction or retry followed.
- Hardware boundary: DUT contact, programming, new hardware scans, and camera frames all zero. No W4.
