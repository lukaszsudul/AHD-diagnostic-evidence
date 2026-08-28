# AHD v41 G2A Offline Build Report

## 1. Current result

`FINAL CLEAN R2 BUILD: PASS`

`STRICT TIMING CLASSIFICATION: PASS_WITH_TIMING_RISK — WHS +0.024 ns`

`BUILD ATTEMPT: 2`

`CONTROLLED CONTINGENCY USED: YES — ONE AND ONLY CONTINGENCY`

`ADDITIONAL RETRY AUTHORIZED: NO`

The clean R2 build completed from the sealed final source identity. Vivado returned exit code `0`; the terminal build receipt, pre-bitstream hard-gate receipt, launch receipt, implementation reports, and independently re-read artifact hashes agree. Project/IP creation, synthesis, optimization, placement, physical optimization, routing, timing, DRC, CDC disposition, clock, XDC-object coverage, resource, congestion, black-box, source-to-bit provenance, and bitstream gates passed. The positive `+0.024 ns` hold margin satisfies the frozen numerical acceptance rule but is extremely small, so timing is explicitly classified `PASS_WITH_TIMING_RISK`; no slack waiver is asserted.

## 2. Frozen build identity

| Field | Required/final value |
|---|---|
| Task | `AHD_V41_G2A_R1I_GEN2_OFFLINE_INTEGRATION` |
| Qualified base commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Qualified base tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Integration branch | `integration/v41-r1i-gen2-g2a` |
| Final source commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Final source tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Vivado | `2025.2`, SW build `6299465` |
| Part | `xc7a35tcsg325-2` |
| Top | `ahd_capture_top_xdma` |
| Execution mode | `FULL_BUILD` |
| Canonical source root | `<SOURCE_ROOT>` |
| R2 build root | `<BUILD_ROOT>` |
| R2 evidence root | `<BUILD_EVIDENCE_ROOT>` |
| R2 temporary root | `<TEMP_ROOT>` |
| R2 launch root | `<LAUNCH_ROOT>` |

The final-source worktree was clean at launch. The child-only environment is `XILINX_LOCAL_USER_DATA=NO`, `XILINX_TCLAPP_REPO=C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore`, and `TEMP=TMP=<TEMP_ROOT>`. The R2 launch receipt records zero Vivado/tool processes before launch and `CHECKPOINT_REUSE=NO`.

## 3. Final source and offline-test readiness

The following facts are sealed independently of the running implementation:

- The integration commit is a direct child of the exact qualified R1i base and contains only the four authorized paths: XDMA XCI, authoritative XDMA configuration Tcl, G2A build wrapper, and G2A offline-check runner.
- Protected R1i NVP/I2C RTL, composite top, MMIO/control sources, legacy forwarding, and protected tests remain byte-identical to the qualified base.
- The sole effective XDMA user-property change is maximum link speed from `2.5_GT/s` to `5.0_GT/s`; x1, refclock, 64-bit AXI4-Stream, one C2H, one mandatory H2C, MSI, BARs, IDs, class, PERST, and requested 62.5 MHz AXI clock remain frozen.
- C2H application `TDATA`, `TKEEP`, `TLAST`, and `TVALID` remain tied low; H2C `TREADY` remains low. No C2H data plane, ring, scheduler, formatter, two-channel logic, or host DMA contract is implemented.
- The authoritative clean-committed offline suite passed against final commit/tree: `RESULT=PASS`, `MODE=CLEAN_COMMITTED`, `PYTHON_TESTS=PASS`, `FOCUSED_SIMULATION=PASS`, `PROVENANCE_TESTS=PASS`, and `HARDWARE_ACCESSED=NO`.
- The supplementary simulation matrix passed 7/7 tests and 18/18 tracked tool commands, including R1i MMIO, inherited read service, exhaustive MMIO integration, record-producer phases, slot-count regression, and the evidence-only AXI-Lite bridge protocol bench.
- Source remained clean before and after the final offline campaigns. No protected source or test was modified to obtain a pass.

Detailed test evidence is in `G2A_OFFLINE_TEST_REPORT.md`. Those tests are complemented by the completed R2 synthesis, implementation, timing, DRC, CDC, resource, provenance, and bitstream gates reported below.

## 4. First clean attempt — diagnostic history only

The first clean attempt used source commit `0937f97427f5727d76b9e9080e6c8298c1ecc225`, tree `9a6831172e585218eb8cf80c891d210687705b99`. It used Vivado 2025.2 build 6299465, created and regenerated the project/IP from scratch, and did not reuse a checkpoint.

| First-attempt stage or metric | Diagnostic result |
|---|---:|
| Project creation | PASS |
| IP generation | PASS |
| Synthesis | PASS |
| Optimization | PASS |
| Placement | PASS |
| Physical optimization | PASS |
| Routing | PASS; fully routed, zero route errors/unrouted/partial nets |
| Timing | PASS; WNS `+0.364 ns`, TNS `0.000 ns`, WHS `+0.036 ns`, THS `0.000 ns` |
| DRC | PASS; zero errors and zero critical warnings |
| Congestion | PASS; no level-`>=5` hotspot |
| Post-opt LUT | 18,579 / 20,800 (89.322%) |
| Routed LUT | 18,181 / 20,800 (87.409%) |
| Routed FF | 20,137 / 41,600 (48.406%) |
| Routed BRAM | 26 / 50 (52.000%) |
| Routed DSP | 0 / 90 (0.000%) |
| BUFG / MMCM / PLL | 8 / 2 / 0 |
| Routed XDMA user clock | `16.000 ns`, 62.500 MHz |
| CDC harness gate | FAIL on two expected Gen2 XDMA-generated `CDC-13` clock views |
| Bitstream / LTX | NOT PRODUCED |

The two CDC entries are two clock views of one internal XDMA BUFGCTRL selector endpoint. AMD-generated XDC applies exact false paths to the selector pins and a physically-exclusive generated-clock group; the routed CDC report classified both as `User Ignored` with `False Path`. Frozen G1 permits an exact critical-finding disposition when generated-clock and CDC exceptions resolve to their intended objects. It does not permit a broad waiver. The first harness rejected every critical CDC object without applying this exact frozen-policy disposition, so it stopped before all later gates and before bitstream generation.

The first attempt executed each major implementation operation exactly once: `synth_design=1`, `opt_design=1`, `place_design=1`, `phys_opt_design=1`, and `route_design=1`; `write_bitstream=0` and `write_debug_probes=0`. Its reports are retained at `<SOURCE_ROOT>_BUILD_EVIDENCE` as diagnostic history only.

## 5. Controlled-contingency classification

The sole controlled contingency is recorded by `<LAUNCH_ROOT>\G2A_CONTINGENCY_BUILD_LAUNCH_RECEIPT.txt` as:

`DETERMINISTIC_EXACT_CDC_REPORT_CLASSIFICATION_AND_LAUNCH_RECEIPT_FINALIZATION`

The prior result is classified as:

`FAIL_PRE_BITSTREAM_ON_OVERBROAD_CDC_HARNESS_GATE`

R2 is therefore build attempt 2, not an incremental continuation of attempt 1. It starts from the final clean commit/tree, uses new build/evidence/temp roots, regenerates IP through the normal flow, and reuses no synthesis, implementation, or routed checkpoint. No RTL, XCI, or XDC was edited after attempt 1; the amendment is limited to exact build-harness classification/receipt handling and changes the embedded source SHA. This is why every R2 implementation measurement and artifact must be regenerated and independently accepted.

This contingency does not mask a functional/design failure: it recognizes only the exact two generated-XDMA clock views on the exact vendor-constrained endpoint pair. Any count, endpoint, clock, exception, severity, or generated-constraint drift is outside the disposition and must fail R2.

R2 is the only contingency launch. If R2 fails, the execution stops and reports that result. No attempt 3, second contingency, repeated retry, checkpoint resume, or selective stage rerun is authorized by this report.

## 6. Authoritative clean R2 build result

The following values come only from `<BUILD_EVIDENCE_ROOT>`, the R2 launch receipt, and independent read-back of the final artifacts. No first-attempt checkpoint, metric, or artifact is promoted into this result.

| R2 field | Authoritative result |
|---|---|
| Final source commit/tree round trip | PASS — `224d194e5f82c85bcb29297561c5d5e76d28063b` / `283f98c02e6f9c61716875415cf000682f8ab856` |
| Vivado version/build | `2025.2` / `6299465` |
| Pre-launch Vivado/tool process count | `0 / 0` from launch receipt |
| Maximum / post-launch Vivado-tool process counts | maximum Vivado `3`, maximum all tracked tools `3`; post-launch all tools `0` |
| In-harness Vivado process receipt | PID `2972`; harness Vivado-process count `1` |
| Project creation/open | PASS |
| XDMA IP generation | PASS; `1,001` effective `CONFIG.*` properties dumped |
| Effective XDMA config / Gen2 x1 invariants | PASS — `5.0_GT/s`, `X1`; all frozen invariants preserved |
| Synthesis | PASS |
| Optimization | PASS |
| Placement | PASS |
| Physical optimization | PASS |
| Routing / route status | PASS — fully routed; zero route errors, unrouted nets, and partial nets |
| WNS / TNS | `+0.617 ns / 0.000 ns` |
| WHS / THS | `+0.024 ns / 0.000 ns` — `PASS_WITH_TIMING_RISK` |
| Failing setup / hold paths | `0 / 0` |
| No-clock / unconstrained internal endpoints | `0 / 0` |
| DRC errors / critical warnings / warnings | `0 / 0 / 15`; DRC gate PASS |
| CDC exact disposition / unknown count | PASS — `2/2` exact Gen2 XDMA clock views dispositioned; unknown `0` |
| Bus-skew gate | PASS — violations `0`, named MET constraints `3` |
| Unresolved black boxes | `0`; gate PASS |
| Effective user clock | `62.500000 MHz` |
| Effective AXI clock | `62.500000 MHz` |
| Post-opt LUT / FF / BRAM / DSP | `18,569 / 20,137 / 26 / 0` |
| Routed LUT / FF / BRAM / DSP | `18,178 / 20,137 / 26 / 0` |
| Routed LUT delta versus qualified R1i | `-3` LUT (`18,178 - 18,181`) |
| BUFG / MMCM / PLL | `8 / 2 / 0` |
| Route congestion | PASS — no level-`>=5` congestion finding |
| Bitstream produced / SHA-256 | YES — `4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E` |
| LTX write attempted / produced / SHA-256 / error | `YES / NO / NONE / NONE` |
| Source identity after build | PASS; source-to-bit provenance PASS |
| Clean-build/no-checkpoint-reuse receipt | PASS — `CHECKPOINT_REUSE=NO`; fresh R2 roots |

The implementation operations receipt records exactly one invocation each of `synth_design`, `opt_design`, `place_design`, `phys_opt_design`, `route_design`, `write_bitstream`, and `write_debug_probes`. The independently read SHA-256 values of the synthesis, post-opt, and routed checkpoints are respectively `F3DA2CA71A71FAE6C8DC55AC2B146A198089E67A614B54EFB9C246EBF5BDB0BF`, `9D1726EF8147BAAFF852056BCF9CD6DF0B07897DD20D50BCFA3D7558ACDF300C`, and `CC8E75AE7E8C5E19C813C97E0B48D470D9E175793F14814343C8DD26660720AC`; all match the pre-bitstream and terminal receipts.

## 7. R2 acceptance result and hard stop

R2 completed one clean project/IP/synthesis/implementation/route/bitstream flow from the final source identity. Setup and hold slack are positive with zero TNS/THS; no critical DRC, unresolved black box, unconstrained internal endpoint, unknown critical CDC, or forbidden congestion/resource condition remains. The routed user and AXI clocks are both 62.5 MHz. Source identity, protected R1i behavior by source identity, and the inactive C2H/H2C boundary remain sealed.

The strict timing result is `PASS_WITH_TIMING_RISK` because WHS is only `+0.024 ns`. This is a risk classification, not a waiver: the timing gate itself passed the frozen requirements. The bitstream was produced and sealed. `write_debug_probes` was attempted once, completed without a reported Tcl error (`LTX_ERROR=NONE`), and produced no LTX file; the authoritative LTX identity is therefore `NONE`.

## 8. Hardware and downstream-scope receipt

| Prohibited action/state | Receipt |
|---|---:|
| Hardware Manager / JTAG / FPGA programming | NOT PERFORMED |
| SSH / DUT connectivity / PCIe enumeration | NOT PERFORMED |
| MMIO / driver / DMA / throughput | NOT PERFORMED |
| Hardware accessed | NO |
| C2H application data plane implemented | NO |
| G2B started | NO |
| Additional build retry authorized | NO |

Final execution point remains the G2A offline-build hard stop. No G2B or hardware activity is authorized by this report.

## 9. Conclusion

`FINAL CLEAN R2 BUILD RESULT: PASS`

`STRICT TIMING CLASSIFICATION: PASS_WITH_TIMING_RISK`

`BITSTREAM: PRODUCED — SHA-256 4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E`

`LTX: NOT PRODUCED — SHA-256 NONE; WRITE ATTEMPTED YES; ERROR NONE`

`SOURCE POST-BUILD / SOURCE-TO-BIT PROVENANCE: PASS / PASS`

`HARDWARE ACCESSED: NO`

`C2H APPLICATION DATA PLANE IMPLEMENTED: NO`

`G2B STARTED: NO`

Source-branch publication completed with `PASS` at `224d194e5f82c85bcb29297561c5d5e76d28063b`. Evidence publication and remote evidence read-back are outside this build report and remain explicitly pending. Final execution remains the G2A offline-build hard stop; G2B may begin only after Owner/Architect acceptance of the consolidated G2A result.
