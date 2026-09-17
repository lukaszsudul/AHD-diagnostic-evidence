# Candidate 2 first failed gate: post-opt Slice LUT ceiling

Candidate 2 is source commit `98d4d214c1219b29a60dc1a33af13e91fe33d27c`, tree `1c43ee847bc468408f574125e3e37209cbb27d54`, built with Vivado 2025.2 SW 6299465, part `xc7a35tcsg325-2`, top `ahd_capture_top_xdma`, one worker. The frozen 40-input manifest is `W3_CANDIDATE2_SOURCE_BUILD_MANIFEST.json`, SHA-256 `45C74B282C85D750ED828C53F12131E66F8CEE3CB98810E5C06F35FE42E49CF6`. The executed Tcl is `w3_candidate2_full_implementation.tcl`, SHA-256 `8C141FFB9AF548B54968F81B731921FEABE99E147C5540BE923310CFB7DBD58D`.

Full synthesis and `opt_design` completed. The top-level candidate-1 one-bit W3 connection warning did not recur. Vivado found one inherited SCAN1 telemetry RAMB36E1 and one new W3 payload RAMB36E1. The first failing candidate-2 acceptance check is the scripted **post-opt Slice LUT gate**:

| Measurement | Value |
|---|---:|
| Post-synthesis Slice LUTs | 25,372 |
| Post-opt Slice LUTs | 23,774 |
| Governed ceiling | 20,384 |
| Excess over governed ceiling | 3,390 |
| Physical device capacity | 20,800 |
| Excess over device capacity | 2,974 |
| Pinned parent post-opt Slice LUTs | 20,186 |
| Candidate-2 increase over parent | 3,588 |
| Post-opt LUT as logic / memory | 22,450 / 1,324 |
| Post-opt flip-flops | 26,807 |
| Post-opt BRAM | 27 RAMB36E1 + 4 RAMB18E1, 29 tiles |
| Post-opt DSP | 0 |

`opt_design` itself reported 0 warnings, 0 critical warnings and 0 errors. The run then raised `POST_OPT_LUT_GATE_FAILED:23774` from the task-local Tcl at line 123 and exited with status 1. This is an engineering **FAIL**, not a missing tool or authority. No placement, physical optimization, routing, timing/DRC/CDC/bus-skew sign-off, qualified DCP, `write_bitstream`, firmware, final closed bundle, or private release package was attempted after the failed gate. The module-only early 3,412-LUT screen was diagnostic; this whole-design 23,774-LUT measurement is the governing result.

Raw byte-exact artifacts:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `candidate2_vivado.log` | 360,974 | `691FBD0D00BC720CE16BF2AD1F8E53A8BD2D8D88BB4025872064B3E2EE8C1EAE` |
| `candidate2/POST_SYNTH_UTILIZATION.rpt` | 10,647 | `019E0C1516F9BC96E6FB2E15D87F2E25CDAAEFDEB985B23E97CC39FF4AF9751E` |
| `candidate2/POST_OPT_UTILIZATION.rpt` | 10,643 | `7FE61C6DB36F3D53E81EF3AD24E1C115524C14DD8727BAE4CE6A90E8B774902F` |

The first failure is preserved. A third in-scope revision would need to remove at least 3,390 post-opt LUTs while retaining all required telemetry. The existing W3 module-only inference screen was 3,412 LUTs, and no narrow within-cone change has an evidence-based path to this reduction. A new BRAM-backed event architecture would be broader than the authorized minimal correction, so candidate 3 was not started. The next executable engineering step is a new governed architecture/resource decision, followed by a fresh candidate and full tests/build. W4 remains blocked.
