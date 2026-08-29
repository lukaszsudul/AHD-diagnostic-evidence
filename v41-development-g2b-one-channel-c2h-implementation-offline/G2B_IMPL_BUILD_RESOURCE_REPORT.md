# AHD v41 G2B-IMPL Build and Resource Report

## Result

The authoritative clean-from-source precommit build is **BLOCKED** at the mandatory post-optimization resource headroom gate.

`BLOCKED — RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW: LUT_GT_90_PERCENT`

Vivado synthesis and `opt_design` completed successfully. The post-opt design reports 21,412 LUTs against 20,800 available (102.942%), so the build harness stopped before placement. Placement, physical optimization, routing, routed timing, routed DRC, routed CDC, routed clock checks, and bitstream generation were not run.

This is not an offline-qualified implementation build and is not hardware evidence.

## Authoritative build identity

| Item | Value |
|---|---|
| Build evidence directory | `C:\FPGA\G2B_BUILD_EVIDENCE_20260829_PRECOMMIT_02` |
| Execution mode | `PRECOMMIT_FULL_BUILD` |
| Source identity | `MANIFEST_SEALED_UNCOMMITTED_WORKTREE` |
| Precommit input manifest SHA-256 | `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587` |
| Repository HEAD | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Repository HEAD tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Integration branch | `integration/v41-g2b-onech-c2h` |
| Vivado | 2025.2, SW build 6299465 |
| FPGA part | `xc7a35tcsg325-2` |
| Top | `ahd_capture_top_xdma` |
| Checkpoint reuse | `NO` |
| IP cache | `LOCAL_CLEAN` |
| Source identity after failure | `PASS` |
| Hardware accessed | `NO` |

“Clean” here describes the build flow: no checkpoint reuse and a locally clean IP cache. The implementation source was intentionally not committed and was sealed by the exact 34-line SHA-256 input manifest. The build result correctly records `SOURCE_CLEAN=NO`.

## Stage results

| Stage or gate | Result | Notes |
|---|---|---|
| Project creation | PASS | Fresh project flow |
| IP generation | PASS | XDMA effective property count: 1001 |
| Synthesis | PASS | One `synth_design` invocation |
| Optimization | PASS | One `opt_design` invocation |
| Post-opt resource gate | **BLOCKED** | `LUT_GT_90_PERCENT` |
| Placement | NOT_RUN | Zero `place_design` invocations |
| Physical optimization | NOT_RUN | Zero `phys_opt_design` invocations |
| Routing | NOT_RUN | Zero `route_design` invocations |
| Fully routed check | NOT_RUN | Routed design does not exist |
| Routed timing gate | NOT_RUN | WNS/TNS/WHS/THS are `UNKNOWN` |
| Routed DRC gate | NOT_RUN | Error/warning counts are `UNKNOWN` |
| Routed CDC gate | NOT_RUN | CDC and bus-skew routed checks were not reached |
| Routed clock gate | NOT_RUN | Effective routed clock values are `UNKNOWN` |
| Black-box gate | NOT_RUN | Not reached |
| Congestion gate | NOT_RUN | Not reached |
| Bitstream | NOT_PRODUCED | Zero `write_bitstream` invocations; SHA-256 `NONE` |
| Debug probes | NOT_PRODUCED | Zero `write_debug_probes` invocations |

The build harness reports `BUILD=FAIL` because it intentionally raised an error at the blocking resource gate. The engineering disposition is **BLOCKED**, not a synthesis failure.

## Post-opt resources

| Resource | G2B used | Available | Utilization | Gate limit | Accepted G2A used | Exact delta |
|---|---:|---:|---:|---:|---:|---:|
| LUT | 21,412 | 20,800 | 102.942% | 90.000% | 18,178 | **+3,234** |
| FF | 23,643 | 41,600 | 56.834% | 80.000% | 20,137 | **+3,506** |
| BRAM | 30 | 50 | 60.000% | 80.000% | 26 | **+4** |
| DSP | 0 | 90 | 0.000% | 85.000% | Not recorded in the G2A comparison | Not calculated |

The LUT count exceeds both the 90% safety gate and the physical device total. No placement or routing claim can be made from this netlist.

## Clock evidence

The generated post-synthesis timing report contains the clock entry:

`userclk1  {0.000 8.000}  16.000 ns  62.500 MHz`

This is a generated post-synthesis clock observation only. Because placement and routing were not run:

- Effective routed user clock: `UNKNOWN`
- Effective routed AXI clock: `UNKNOWN`
- Routed clock object count: `UNKNOWN`
- Routed WNS: `UNKNOWN`
- Routed WHS: `UNKNOWN`

The XDMA effective configuration also records `CONFIG.axisten_freq=62.5`, but configuration and post-synthesis generation do not substitute for routed effective-clock qualification.

## Checkpoints and report hashes

All hashes are SHA-256 and refer to files under `C:\FPGA\G2B_BUILD_EVIDENCE_20260829_PRECOMMIT_02`.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `G2B_BUILD_RESULT.txt` | 4,512 | `37875DBDC7C535D5599804C5BB7382505F81BAEE1CEDF4296C9B9D113EC79F98` |
| `G2B_BUILD_PROVENANCE.txt` | 1,481 | `7040C33229A7757084AF0D24631318113E1A7834494143B8E410E560BE20F68A` |
| `G2B_PRECOMMIT_INPUT_SHA256.txt` | 3,294 | `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587` |
| `G2B_BUILD_INPUT_SHA256.txt` | 3,294 | `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587` |
| `G2B_EXPECTED_RUNTIME_PROVENANCE.txt` | 2,783 | `06ACD717BD48FA9025D18999C374D55D54666536EBB6FA55E04F9674D16EEEAE` |
| `G2B_OPERATION_COUNTS.txt` | 132 | `940B4481917B0D5B809F81489B2E65B0FEB7C6C601C52E9B05224FC501C7357A` |
| `G2B_COMPILE_ORDER.rpt` | 29,737 | `A3F2FF35035C64F9C2F8A9089A5632297F01E54F4902AD5DFE94B4B8F1BAD7CD` |
| `G2B_XDMA_EFFECTIVE_CONFIG.txt` | 33,610 | `7FE9FF23092C37128CFC4C42E7DBCCD0F966E6BE876FAAADCC0E35E46AD4532C` |
| `G2B_XDMA_IP_PROPERTIES.txt` | 79,098 | `BE3D7DEE81892FF3340220A20524E540F559B449CCEA41C33D9739F67AEA344F` |
| `G2B_XDMA_IP_STATUS.rpt` | 6,239 | `9A6394507BA2EFBDE52D2B7D3FE465EE05044C63EB435E0B5271567C5E4363F9` |
| `POST_OPT_RESOURCE_GATE.txt` | 376 | `F2BFD3D14BC24563F680B87FA6BE8F06FEF69E1694101E1F6D484FBCB50E287B` |
| `POST_OPT_UTILIZATION_FLAT.rpt` | 10,521 | `0BF039B4E63AEC7489C0731663434F74E01A546608BACFA6B3FCB4C6023DEE60` |
| `POST_OPT_UTILIZATION_HIER.rpt` | 27,030 | `F97E7BD206D6E008B3ED8AB9FE7DDB3BD458801838E3442E361D4D95951F38E6` |
| `POST_SYNTH_UTILIZATION_FLAT.rpt` | 10,595 | `A847E43016A9919245350ADA163365E2AC5A54592EE933224F6FFA22E298DB64` |
| `POST_SYNTH_UTILIZATION_HIER.rpt` | 28,138 | `7BE330BBC6D4B4A44DD268CB165E98761FFE78392A3DED2FD7FE2545DC47FFEC` |
| `POST_SYNTH_TIMING_SUMMARY.rpt` | 11,248,398 | `F1AE8A560DF242033887CC2C86F713E5833946CD6779C72D1D424C442BE61900` |
| `G2B_SYNTH.dcp` | 53,646,390 | `5BF8F53109D230D527F85550CCE48E017BEA9234D4180699986E961664DDEF74` |
| `G2B_POST_OPT.dcp` | 53,018,092 | `C41B2888A3E9A52D5AC9B4E5302B18BDED6F9352143831DA6E75912BC58207DF` |
| Routed checkpoint | — | `NONE` |
| Bitstream | — | `NONE` |

## Qualification boundary

- Synthesis: PASS
- Optimization: PASS
- Placement: NOT_RUN
- Routing: NOT_RUN
- Timing: NOT_RUN
- Critical DRC: NOT_RUN
- Routed CDC: NOT_RUN
- Bitstream: NOT_PRODUCED
- Hardware throughput proven: NO
- Hardware accessed: NO

The first blocker is exactly `BLOCKED — RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW: LUT_GT_90_PERCENT`. Architecture/resource review is required before another implementation build; this report does not authorize removing protected R1i or diagnostic logic.
