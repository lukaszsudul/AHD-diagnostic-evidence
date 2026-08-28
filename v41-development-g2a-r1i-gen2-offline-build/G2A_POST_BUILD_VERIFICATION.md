# AHD v41 G2A Post-Build Verification

## 1. Result

`POST-BUILD STATIC VERIFICATION: PASS`

`STRICT TIMING CLASSIFICATION: PASS_WITH_TIMING_RISK — WHS +0.024 ns`

The clean R2 Vivado flow completed with `BUILD=PASS`, `SOURCE_TO_BIT_PROVENANCE=PASS`, and exit code `0`. The final source identity, generated XDMA configuration, routed clocks, CDC/XDC objects, resources, DRC, route state, operation counts, and bitstream identity were re-read from the terminal, pre-bitstream, launch, configuration, clock, CDC, resource, and debug-probe receipts. Hardware remained untouched, the C2H application data plane remains absent, and G2B was not started.

## 2. Sealed source and build identity

| Field | Verified value | Result |
|---|---|---:|
| Integration branch | `integration/v41-r1i-gen2-g2a` | PASS |
| Integration commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` | PASS |
| Integration tree | `283f98c02e6f9c61716875415cf000682f8ab856` | PASS |
| Qualified base commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` | PASS |
| Qualified base tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` | PASS |
| Direct parent / integration commit count | exact qualified base / `1` | PASS |
| Source clean at launch | YES | PASS |
| Source post-build | `PASS` | PASS |
| 40-hex SHA reconstruction and round trip | exact integration commit / `PASS` | PASS |
| Embedded SHA words | `224d194e 5f82c85b cb292975 61c5d5e7 6d28063b` | PASS |
| Source-to-bit provenance | `PASS` | PASS |
| Checkpoint reuse | `NO` | PASS |

The Vivado generic string carries all five SHA words with `BUILD_FLAGS=32'h00000002`. The synthesis, post-opt, and routed checkpoints hash to:

- `F3DA2CA71A71FAE6C8DC55AC2B146A198089E67A614B54EFB9C246EBF5BDB0BF`
- `9D1726EF8147BAAFF852056BCF9CD6DF0B07897DD20D50BCFA3D7558ACDF300C`
- `CC8E75AE7E8C5E19C813C97E0B48D470D9E175793F14814343C8DD26660720AC`

Independent SHA-256 read-back matched all three terminal and pre-bitstream receipt values.

## 3. Clean-flow completion

Vivado `2025.2`, SW build `6299465`, targeted `xc7a35tcsg325-2` with top `ahd_capture_top_xdma` in `FULL_BUILD` mode. Project creation, XDMA IP generation, synthesis, optimization, placement, physical optimization, routing, and the pre-bitstream hard gate all passed. The design is fully routed with zero route errors, zero unrouted nets, and zero partial nets.

The operation receipt records exactly one invocation of every authorized implementation action:

| Operation | Count |
|---|---:|
| `synth_design` | 1 |
| `opt_design` | 1 |
| `place_design` | 1 |
| `phys_opt_design` | 1 |
| `route_design` | 1 |
| `write_bitstream` | 1 |
| `write_debug_probes` | 1 |

The wrapper observed zero Vivado/tool processes before launch, a maximum of three Vivado processes and three total tracked tool processes during the run, and zero tracked tool processes after completion. The harness itself recorded Vivado PID `2972` and a harness-local Vivado process count of one. Elapsed R2 wall time was `8792.558 s`. The launch receipt records `HARDWARE_ACCESSED=NO`.

## 4. Effective XDMA configuration

The generated R2 dump contains `1,001` effective `CONFIG.*` properties. The post-generation comparison passes with the approved user-controlled speed delta and no unexplained effective drift:

| Property | Effective G2A value | Result |
|---|---:|---:|
| Maximum link speed | `5.0_GT/s` | PASS |
| Maximum link width | `X1` | PASS |
| Differential reference-clock request | `100_MHz` | PASS |
| AXI-stream/application-clock request | `62.5 MHz` | PASS |
| AXI data width | `64_bit` | PASS |
| C2H / mandatory H2C channels | `1 / 1` | PASS |
| MSI / MSI-X | one MSI vector / disabled | PASS |
| PF0 BAR0 | enabled, 128 KiB | PASS |
| Vendor / device IDs | `10EE / 7011` | PASS |
| Subsystem vendor / subsystem IDs | `10EE / 0007` | PASS |
| Class code | `058000` | PASS |

The only user-controlled delta from the frozen donor is `CONFIG.pl_link_cap_max_link_speed=2.5_GT/s -> 5.0_GT/s`. Vivado's derived disabled PLL metadata resolves `CPLL -> QPLL1` for Gen2 and is already classified as unavoidable generated metadata. Width, IDs, BAR architecture, channel counts, interrupt mode, interface width, requested clocks, and PERST contract remain frozen. `BLOCKED — UNEXPECTED_XDMA_CONFIG_DRIFT` did not occur.

## 5. R1i protected behavior, MMIO, and telemetry

The R2 source commit/tree is the same clean identity used by the passing offline source-protection suite. Protected NVP/I2C RTL, the qualified composite top, MMIO/control sources, host bridge, PIO sources, qualified build oracle, and protected tests are byte-identical to qualified R1i. The NVP initialization table, 25 kHz I2C semantics, filtered SCL qualification, ACK/first-NACK behavior, STOP/bus-free, retry/backoff, timeouts, bank safety, reset/start/final-settle behavior, MMIO through `0x35FF`, and telemetry page `0x3600-0x367F` therefore remain preserved by source identity. The clean-committed offline tests and focused qualified-R1i simulation passed.

## 6. C2H/H2C inactive-boundary verification

The protected top remains byte-identical to qualified R1i and retains these direct application C2H constants:

| Signal | Value |
|---|---:|
| `s_axis_c2h_tdata_0` | `64'b0` |
| `s_axis_c2h_tkeep_0` | `8'b0` |
| `s_axis_c2h_tlast_0` | `1'b0` |
| `s_axis_c2h_tvalid_0` | `1'b0` |
| `m_axis_h2c_tready_0` | `1'b0` |

The constants are not reset-, PERST-, or link-state-dependent. No record-to-C2H adapter, formatter, FIFO/ring, channel scheduler, two-channel DMA logic, or host DMA contract exists in the final source delta. The terminal build receipt independently records `C2H_DATA_PLANE_IMPLEMENTED=NO`.

`C2H application data plane: NOT IMPLEMENTED`  
`C2H inactive boundary: PASS`  
`H2C inactive/backpressured boundary: PASS`

## 7. Routed clocks and timing

The requested 62.5 MHz application clock resolves to one routed `userclk1` object with a `16.000000 ns` period and `0.000 8.000` waveform. It clocks both the protected NVP consumers and AXI bridge consumers:

- NVP autoinit clock pins: `2,247`, clock object `userclk1`;
- AXI bridge clock pins: `110`, clock object `userclk1`;
- effective XDMA user clock: `62.500000 MHz`;
- effective AXI clock: `62.500000 MHz`;
- clock gate: PASS.

Gen2 did not move the application domain to 125 MHz and did not require retiming protected R1i logic. `BLOCKED — GEN2_CHANGED_APPLICATION_CLOCK` did not occur.

| Timing field | Routed result | Gate |
|---|---:|---:|
| WNS | `+0.617 ns` | PASS |
| TNS | `0.000 ns` | PASS |
| WHS | `+0.024 ns` | PASS_WITH_TIMING_RISK |
| THS | `0.000 ns` | PASS |
| Failing setup paths | `0` | PASS |
| Failing hold paths | `0` | PASS |
| No-clock endpoints | `0` | PASS |
| Unconstrained internal endpoints | `0` | PASS |

The numerical frozen acceptance requirements pass. The `24 ps` positive hold margin is nevertheless extremely marginal, so the strict engineering classification is `PASS_WITH_TIMING_RISK`. No slack waiver is used or implied.

## 8. CDC, reset, XDC, and bus-skew closure

The CDC gate passes with exactly two critical entries, both dispositioned as the two expected Gen2-only XDMA-generated clock views; unknown critical findings are zero. Both are `CDC-13`, `User Ignored`, `False Path`, from:

`XDMA/.../pipe_clock_i/pclk_sel_reg/C`

to:

`XDMA/.../pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1`

for clock pairs `clk_125mhz_mux_x0y0 -> clk_250mhz_x0y0` and `clk_250mhz_mux_x0y0 -> clk_250mhz_x0y0`. Generated XDC resolves the exact S0/S1 false paths and physically-exclusive generated-clock group. `APPLICATION_CDC_DISPOSITIONED=0` and `BROAD_CDC_WAIVER_APPLIED=NO`.

Routed XDC/CDC object coverage is exact: configuration `74/74`, status `291/291`, toggle first stages/D pins `8/8`, diagnostic Gray sources/first D pins `96/96`, NVP init asynchronous-reset pins `6`, PCIe refclock IBUF `1`, GTPE2 channel/common `1/1`, and PCIe hard block `1`. Bus-skew closure passes with zero violations and three named MET constraints. The final source identity also preserves the reviewed NVP, AXI-Lite, PERST, C2H tie-off, and video-crossing reset/CDC structure; no new application CDC/reset dependency was introduced.

## 9. DRC, black boxes, resources, and route quality

| Gate or resource | Final routed result |
|---|---:|
| DRC errors | `0` |
| DRC critical warnings | `0` |
| DRC warnings | `15` |
| Unresolved black boxes | `0` |
| Congestion gate | PASS; no level-`>=5` finding |
| LUT | `18,178 / 20,800 (87.394%)` |
| FF | `20,137 / 41,600 (48.406%)` |
| BRAM | `26 / 50 (52.000%)` |
| DSP | `0 / 90 (0.000%)` |
| BUFG / MMCM / PLL | `8 / 2 / 0` |

Post-opt utilization is LUT `18,569 / 20,800 (89.274%)`, FF `20,137 / 41,600 (48.406%)`, BRAM `26 / 50 (52.000%)`, and DSP `0 / 90`. Both post-opt and routed resource gates pass the frozen limits. Routed LUT use is three below the qualified R1i reference (`18,178 - 18,181 = -3`); FF delta is `+54`, BRAM delta is zero, and no diagnostic logic was removed to obtain closure.

## 10. Bitstream and debug-probe identity

The final bitstream exists at `<BUILD_EVIDENCE_ROOT>\artifacts\AHD_V41_G2A_R1I_GEN2_OFFLINE.bit`, is `2,192,144` bytes, and independently hashes to:

`4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E`

This matches the terminal build receipt. The pre-bitstream hard gate recorded `RESULT=PASS` before `write_bitstream` executed.

`write_debug_probes` was invoked exactly once and its receipt records:

- `WRITE_DEBUG_PROBES_ATTEMPTED=YES`;
- `LTX_PRODUCED=NO`;
- `LTX_SHA256=NONE`;
- `LTX_ERROR=NONE`.

No LTX file exists, so the correct LTX identity is `NONE`; no hash is invented and no command error is concealed.

## 11. Scope, publication, and conclusion

| Scope/gate | Result |
|---|---:|
| Final clean offline build | PASS |
| Source-to-bit provenance | PASS |
| Effective Gen2 x1 configuration | PASS |
| Protected R1i source/behavior identity | PASS |
| C2H inactive boundary | PASS |
| Clock gate | PASS |
| Timing | PASS_WITH_TIMING_RISK |
| CDC/reset/XDC static closure | PASS |
| DRC / black boxes | PASS |
| Resource / congestion policy | PASS |
| Bitstream | PRODUCED |
| Hardware accessed | NO |
| C2H application data plane implemented | NO |
| G2B started | NO |
| Source-branch publication | PASS — remote read-back matched `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Evidence publication | PENDING |
| Remote read-back | NOT RUN |

The G2A post-build technical verification passes, with the explicitly retained `PASS_WITH_TIMING_RISK` classification for the `+0.024 ns` hold margin. This document makes no hardware-qualification or throughput claim. G2B remains unstarted and may proceed only after Owner/Architect acceptance of the consolidated G2A evidence.
