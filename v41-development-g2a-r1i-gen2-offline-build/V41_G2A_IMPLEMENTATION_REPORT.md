# AHD v41 G2A R1i + Gen2 Offline Integration

## 1. Executive result

**Engineering gate: PASS.**

**Engineering classification: PASS_WITH_TIMING_RISK.** The final clean R2 implementation satisfies the frozen G2A setup/hold acceptance rule, but the routed hold margin is only `+0.024 ns`; this is explicitly retained as timing risk and is not waived.

**G2B readiness: G2B_READY.** This is an engineering-readiness statement only. G2B was not started and must not begin before Owner/Architect acceptance of this G2A result.

The final source candidate is commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`. The clean R2 build completed project creation, IP generation, synthesis, optimization, placement, physical optimization, routing, all hard gates, and bitstream generation in Vivado 2025.2 build 6299465. It is fully routed with positive setup and hold slack, zero DRC errors/critical warnings, zero black boxes, the expected 62.5 MHz application clock, and the exact bounded Gen2-generated XDMA CDC disposition.

The application C2H data plane remains unimplemented and constant-inactive; H2C remains backpressured. Hardware was not accessed. Source-branch publication, public-evidence publication, LFS transfer, and independent remote read-back are all `PASS`. The remotely verified evidence payload commit is `bb8be9993726546cad2c120e300afd5499419951`.

## 2. Frozen inputs

| Input | Frozen authority |
|---|---|
| Qualified R1i branch | `baseline/v41-r1i-qualified-poc` |
| Qualified R1i commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Qualified R1i tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Immutable tag | `v41-r1i-qualified-poc-20260827` |
| Qualified bitstream SHA-256 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| Primary XDMA donor | `c89e88bcdf389614c884fb129e8b2d42a585bccb` / `v41-xdma-primary-donor-g0-20260827` |
| Secondary provenance donor | `8464af66611f7c22b8a36a4aab915d598eedda3f` |
| Frozen G1 evidence commit | `f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd` |
| Tool | Vivado `2025.2`, SW build `6299465` |
| Part | `xc7a35tcsg325-2` |
| Top | `ahd_capture_top_xdma` |

The base tree, tag peel, donor identities and ancestry, G1 evidence identity, tool identity, part, and top passed preflight. The Owner-frozen product constraints remain four physical video inputs, no more than two simultaneously active, future sustained application payload of at least 288 MB/s, and final PCIe Gen2 x1 or better. G2A establishes the Gen2-capable offline foundation; it does not claim throughput or hardware qualification.

## 3. Integration branch provenance

| Item | Final value | Result |
|---|---|---:|
| Branch | `integration/v41-r1i-gen2-g2a` | PASS |
| Commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` | PASS |
| Tree | `283f98c02e6f9c61716875415cf000682f8ab856` | PASS |
| Direct parent | `20c3323d79d3896edc586d6db1df7deee60f9e41` | PASS |
| Source clean before build | yes | PASS |
| Source clean after build | yes | PASS |
| Source-to-bit provenance | sealed commit/tree and embedded five SHA words | PASS |
| Primary worktree modified | no | PASS |
| Protected refs modified | no | PASS |

The isolated worktree was created from the immutable R1i tag. No old-donor merge, top-level replacement, R-track merge, or checkpoint reuse occurred. The final source patch SHA-256 is `BD2796E63CDBBA0AE974691F5F0A6511CBE9B23DE9CA369C9AA24A4837E449A2`.

Source branch publication: `PASS`. The integration branch was pushed without force and read back at `224d194e5f82c85bcb29297561c5d5e76d28063b`. Evidence publication: `PASS`. Independent remote evidence read-back: `PASS` at payload commit `bb8be9993726546cad2c120e300afd5499419951`. No release or protected-branch merge is claimed.

## 4. Source changes

The final base-to-integration diff contains exactly four authorized files and no `UNEXPECTED` functional source change:

| File | Classification | Final disposition |
|---|---|---|
| `ip/v41/xdma_v41_m1.xci` | `GEN2_REQUIRED`; terminal newline is `TOOL_GENERATED_METADATA` | Sole semantic XCI delta is link speed `2.5_GT/s -> 5.0_GT/s`. |
| `scripts/v41/xdma_config_common.tcl` | `GEN2_REQUIRED` | Matching link-speed delta plus read-only frozen-property assertions and effective-config dumping. |
| `scripts/v41/g2a_build.tcl` | `PROVENANCE_HARDENING` | Separate wrapper around the immutable R1i oracle, provenance modes/receipts, clean build flow, reports, hard gates, and exact-signature CDC disposition. |
| `tests/v41/run_g2a_offline_checks.ps1` | `PROVENANCE_HARDENING` | Offline contract, identity, configuration, tie-off, provenance, conflict-leakage, and exact-base focused-test runner. |

No application RTL, active source XDC, host driver, generated IP output, record-to-C2H adapter, formatter, FIFO/ring, scheduler, or host DMA contract was added or changed. Diff allowlist, `git diff --check`, conflict-marker, R-track-leakage, secret-pattern, and hardware-command checks passed.

## 5. R1i protection verification

Protected R1i authority is preserved by byte identity. Key final-tree anchors are:

| Protected path | Git blob | SHA-256 |
|---|---|---|
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `3757acf2677d0a13b31a285095c38cc7b30e567c` | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| `rtl/nvp/nvp6134c_autoinit.vhd` | `ec070a399d16ce3370469ee1b0079c153a39b5c1` | `FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5` |
| `rtl/top/ahd_capture_top_xdma.sv` | `d04ff833994bc83e29647c0a7cce4cc941c3410e` | `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4` |
| `rtl/v41/control_status_regs.sv` | `16fc122686a7c11f99c5bc9750dad586d713e05f` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |
| `scripts/v41/r1i_build.tcl` | `843d644d1214bb2bc56b6afe50a42231df234ebc` | `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F` |

The NVP init table, 25 kHz I2C semantics, physical filtered-SCL qualification, ACK timing, first-NACK abort, STOP/bus-free, retry/backoff, timeout, bank safety, reset/start/final-settle behavior, MMIO through `0x35FF`, and telemetry page `0x3600–0x367F` were not edited. The exact-base focused R1i suite passed. The build receipt records `SOURCE_POST_BUILD=PASS` and the final worktree remains clean at the sealed commit/tree.

R1i protected behavior gate: `PASS`.

## 6. Gen2 configuration

Final R2 IP generation and the 1,001-property effective configuration dump pass.

| Effective property | Final value |
|---|---|
| `CONFIG.pl_link_cap_max_link_speed` | `5.0_GT/s` |
| `CONFIG.pl_link_cap_max_link_width` | `X1` |
| `CONFIG.ref_clk_freq` | `100_MHz` |
| `CONFIG.axisten_freq` | `62.5` |
| `CONFIG.axi_data_width` | `64_bit` |
| `CONFIG.xdma_axi_intf_mm` | `AXI_Stream` |
| `CONFIG.xdma_rnum_chnl` / `xdma_wnum_chnl` | `1` / `1` |
| `CONFIG.xdma_num_usr_irq` | `1` |
| MSI / MSI-X | enabled, one vector / disabled |
| AXI-Lite aperture and BAR0 | `128 KiB`, BAR0 enabled; BAR1–BAR5 disabled |
| PERST polarity | `ACTIVE_LOW` |
| Vendor/device | `10EE` / `7011` |
| Subsystem vendor/subsystem | `10EE` / `0007` |
| Class code | `058000` |

The only user-controlled effective delta from the frozen Gen1 donor is link speed. Vivado-derived `CONFIG.plltype=QPLL1` is the unavoidable Gen2 dependent metadata; the disabled serialized `CPLL` source field was not edited. All other 999 effective properties match the frozen donor.

Gen2 configuration gate: `PASS`. Effective link target: `Gen2 x1`.

## 7. Provenance hardening

The G2A wrapper ports only the approved provenance intent from the secondary donor: `FULL_BUILD`/`PROVENANCE_ONLY`, lowercase 40-hex commit/tree validation, five-word SHA reconstruction, explicit receipt/PASS fields, and provenance-only exit before project commands. The qualified R1i build oracle remains unchanged.

Positive provenance-only execution passed without project creation. Invalid-mode and deliberately mutated one-word round-trip cases were rejected without project artifacts. Final source SHA words embedded into the build are `224d194e`, `5f82c85b`, `cb292975`, `61c5d5e7`, and `6d28063b`; build flags are `0x00000002`.

The controlled R2 launch corrected only the overbroad first-attempt CDC harness classification. No RTL, XCI, active XDC, or generated-IP source changed; R2 used no checkpoint and executed each major build/output operation exactly once. Checkpoint hashes recorded before bitstream are:

- synthesis: `F3DA2CA71A71FAE6C8DC55AC2B146A198089E67A614B54EFB9C246EBF5BDB0BF`;
- post-opt: `9D1726EF8147BAAFF852056BCF9CD6DF0B07897DD20D50BCFA3D7558ACDF300C`;
- routed: `CC8E75AE7E8C5E19C813C97E0B48D470D9E175793F14814343C8DD26660720AC`.

The pre-bitstream receipt records `SOURCE_TO_BIT_PROVENANCE=PASS`; the terminal receipt records `SOURCE_POST_BUILD=PASS`, `SOURCE_TO_BIT_PROVENANCE=PASS`, and `BUILD=PASS`.

## 8. C2H inactive-boundary proof

The byte-identical qualified composite top retains direct constant tie-offs:

| Signal | Exact source value |
|---|---|
| `s_axis_c2h_tdata_0` | `64'b0` |
| `s_axis_c2h_tkeep_0` | `8'b0` |
| `s_axis_c2h_tlast_0` | `1'b0` |
| `s_axis_c2h_tvalid_0` | `1'b0` |
| `m_axis_h2c_tready_0` | `1'b0` |

The constants are independent of reset, PERST, and link state. No payload generator, record formatter, C2H FIFO/ring, DMA-channel scheduler, descriptor contract, host DMA contract, or driver change exists. The inherited record path remains PIO-only. The build receipt records `C2H_DATA_PLANE_IMPLEMENTED=NO`.

C2H application data plane: `NOT IMPLEMENTED`. C2H inactive boundary: `PASS`. H2C inactive/backpressured boundary: `PASS`.

## 9. Clock result

The final routed clock-object receipt resolves the G1 metadata ambiguity:

| Evidence | Final R2 value |
|---|---:|
| XCI requested AXI-stream clock | `62.5 MHz` |
| Effective `user_clk` | `62.500000 MHz` |
| Effective `axi_aclk` | `62.500000 MHz` |
| Routed clock object | `userclk1` |
| Period / waveform | `16.000000 ns` / `0.000 8.000` |
| Clock source | XDMA MMCM `CLKOUT2` |
| Routed user-clock object count | `1` |
| NVP protected clock-pin count | `2247` |
| AXI-bridge clock-pin count | `110` |

The unchanged top continues to bind `autonomous_clk = axi_aclk` and preserves `NVP_AUTOINIT_CLK_HZ=62,500,000`. No NVP timing constant was rescaled.

Clock gate: `PASS`. `GEN2_CHANGED_APPLICATION_CLOCK` did not occur.

## 10. CDC/reset review

The source static review and final routed R2 CDC/reset gate both pass. G2A introduces no NVP dependency on `user_lnk_up`, `axi_aresetn`, or PERST; PERST polarity/path, AXI-Lite resets, C2H/H2C constant semantics, video-clock crossings, mailbox handshakes, dual-clock RAM, Gray crossings, and active source XDC remain inherited.

Final CDC receipt:

| Item | Final result |
|---|---|
| CDC critical objects | `2` |
| Critical objects dispositioned | `2` |
| CDC unknown | `0` |
| IDs | `CDC-13#1`, `CDC-13#2` |
| CDC type / exception | `User Ignored` / `False Path` |
| Disposition | `PASS_EXACT_GEN2_XDMA_PIPE_CLOCK_MUX` |
| Generated S0/S1 false paths | PASS / PASS |
| Generated 125/250 MHz clocks physically exclusive | PASS |
| Application CDC objects dispositioned | `0` |
| Broad CDC waiver applied | `NO` |
| Bus-skew violations / met constraints | `0` / `3` |

The two entries are the exact two clock views of the expected Gen2-generated XDMA PIPE selector endpoint pair. Any broader or different finding would have failed closed.

Routed XDC object coverage also resolved exactly: configuration `74/74`, status `291/291`, toggle first stages/data pins `8/8`, diagnostic Gray sources/first-D pins `96/96`, NVP-init asynchronous-reset pins `6`, PCIe refclk IBUF `1`, GTPE2 channel/common `1/1`, and PCIe hard block `1`.

CDC/reset gate: `PASS`.

## 11. Offline tests

Offline-test gate: `PASS` against the final commit/tree.

- Clean-committed contract suite: `PASS`; exact base/direct parent, protected source identities, four-file allowlist, R1i MMIO/telemetry, XDMA invariants, C2H/H2C tie-offs, four inherited Python suites, exact-base focused R1i simulation, provenance positive/negative cases, source cleanliness, and hardware prohibition all passed.
- Supplementary simulation matrix: `7/7 PASS`, `18/18` tracked tool commands exited zero, and zero failure tokens. Receipt SHA-256: `D854696B90FDE99D1FDDDA0A0A95B3B14275576453C39AA44B27D486FEAF3105`.
- Covered supplementary tops: `tb_r1i_poc_mmio`, `tb_r1h_mmio_read_service`, `tb_r1h_mmio_integration_exhaustive`, both record-producer phases, slot-count regression, and the evidence-only AXI-Lite host-bridge protocol bench.

The historical `tests/nvp/tb_nvp_autoinit.vhd` exploratory failure remains disclosed and non-gating: that unchanged legacy bench assumes continued ACK phases after a WADDR NACK, contrary to qualified R1i first-NACK abort. The byte-identical qualified focused suite explicitly tests the frozen semantics and passed; no RTL/test was changed to accommodate either result.

## 12. Synthesis

Project creation: `PASS`. IP generation: `PASS`. Synthesis: `PASS`. Optimization: `PASS`.

Vivado generated and audited 1,001 effective XDMA `CONFIG.*` properties. The build used the qualified R1i default source/XDC/top oracle, clean local IP cache, `generate_synth_checkpoint=false`, and no prior checkpoint reuse. Synthesis was executed exactly once. Unresolved black boxes after implementation: `0`.

Synthesis gate: `PASS`.

## 13. Implementation

Placement: `PASS`. Physical optimization: `PASS`. Routing: `PASS`. The design is fully routed:

- logical nets: `51,475`;
- routable nets: `35,855`;
- fully routed nets: `35,855`;
- routing errors: `0`;
- unrouted nets: `0`;
- partial nets: `0`.

Each operation ran exactly once: `synth_design`, `opt_design`, `place_design`, `phys_opt_design`, `route_design`, `write_bitstream`, and `write_debug_probes`. The clean R2 launch exited zero after `8,792.558 s`; maximum Vivado and total FPGA-tool process counts were both `3`, post-launch tool count was `0`, and checkpoint reuse was `NO`.

Implementation/routing gate: `PASS`.

## 14. Timing

Timing gate: `PASS` with the required explicit risk classification `PASS_WITH_TIMING_RISK`.

| Metric | Final R2 value | Gate |
|---|---:|---:|
| WNS | `+0.617 ns` | PASS |
| TNS | `0.000 ns` | PASS |
| WHS | `+0.024 ns` | PASS_WITH_TIMING_RISK |
| THS | `0.000 ns` | PASS |
| Failing setup paths | `0` | PASS |
| Failing hold paths | `0` | PASS |
| No-clock count | `0` | PASS |
| Unconstrained internal endpoints | `0` | PASS |

The `+0.024 ns` hold slack is positive and therefore satisfies the frozen G2A acceptance rule, but 24 ps is extremely marginal. No waiver or slack exception is applied. Any downstream source, tool, constraint, seed, placement, or routing change must re-run full timing and treat hold closure as a priority risk.

## 15. DRC

| Check | Final R2 value | Result |
|---|---:|---:|
| DRC errors | `0` | PASS |
| DRC critical warnings | `0` | PASS |
| DRC warnings | `15` | RECORDED |
| Vivado-log `ERROR:` lines | `0` | PASS |
| Vivado-log `CRITICAL WARNING:` lines | `0` | PASS |
| Black boxes | `0` | PASS |
| Route errors / unrouted / partial | `0 / 0 / 0` | PASS |

`check_timing` reports zero no-clock, unconstrained-internal-endpoint, multiple-clock, and disconnected-generated-clock findings. The raw log contains 465 ordinary `WARNING:` lines, predominantly generated-IP/tool diagnostics; none is a DRC error or critical warning. Detailed reports remain authoritative for review.

Critical DRC gate: `PASS`. Black-box gate: `PASS`.

## 16. Resource delta

| Resource | Qualified R1i routed | Final R2 post-opt | Final R2 routed | Routed delta vs R1i |
|---|---:|---:|---:|---:|
| LUT | `18,181 / 20,800` (`87.409%`) | `18,569 / 20,800` (`89.274%`) | `18,178 / 20,800` (`87.394%`) | `-3` |
| FF | `20,083 / 41,600` (`48.276%`) | `20,137 / 41,600` (`48.406%`) | `20,137 / 41,600` (`48.406%`) | `+54` |
| BRAM | `26 / 50` (`52.000%`) | `26 / 50` (`52.000%`) | `26 / 50` (`52.000%`) | `0` |
| DSP | not frozen | `0 / 90` (`0.000%`) | `0 / 90` (`0.000%`) | not asserted |

Clocking resources: BUFG `8`, MMCM `2`, PLL `0`. No placer or initial-router congestion window exists at tool level 5 or higher. Both post-opt and routed utilization remain below the frozen `>90%` LUT hard stop; FF, BRAM, and DSP remain below their caps. Post-opt LUT is only 151 LUT below the 90% boundary and remains a material headroom risk. No research diagnostic was removed to obtain closure.

Resource gate: `PASS`. Congestion gate: `PASS`.

## 17. Bitstream identity

Bitstream: `PRODUCED`.

| Artifact/receipt | Final value |
|---|---|
| Filename | `AHD_V41_G2A_R1I_GEN2_OFFLINE.bit` |
| Size | `2,192,144 bytes` |
| SHA-256 | `4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E` |
| Source commit/tree before write | exact final identity / PASS |
| Source commit/tree after build | exact final identity / PASS |
| Source-to-bit provenance | PASS |
| Checkpoint reuse | NO |

`write_debug_probes` was attempted exactly once. No LTX was produced; `LTX_SHA256=NONE` and `LTX_ERROR=NONE`. The harness explicitly permits this outcome when no debug-probe file is emitted. No LTX file is claimed or fabricated.

The artifact is an offline build product only. It was not programmed into hardware and has no hardware qualification status.

## 18. G1 policy compliance

| Frozen policy item | Final disposition |
|---|---:|
| Exact qualified R1i base/direct-child integration | PASS |
| Exactly four authorized source changes | PASS |
| Protected R1i source/MMIO/telemetry identity | PASS |
| Gen2 x1 effective configuration; all other frozen properties preserved | PASS |
| C2H inactive; H2C backpressured; no data plane | PASS |
| 62.5 MHz user/AXI clock | PASS |
| CDC/reset review and exact generated-XDMA disposition | PASS |
| Offline tests | PASS |
| Synthesis/optimization/placement/physical optimization | PASS |
| Fully routed implementation | PASS |
| Timing | PASS_WITH_TIMING_RISK |
| DRC/black boxes/clock coverage | PASS |
| Resource/congestion policy | PASS |
| Bitstream and source-to-bit provenance | PASS |
| Hardware untouched; G2B not started | PASS |

No slack waiver, protected-behavior workaround, diagnostic removal, application-clock retiming, hardware action, or C2H/G2B implementation is claimed.

## 19. Risks

- Routed hold slack is only `+0.024 ns`; engineering timing passes, but the result is classified `PASS_WITH_TIMING_RISK`.
- Post-opt LUT utilization is `89.274%`, only 151 LUT below the frozen 90% hard-stop boundary. Routed utilization is lower, but future data-plane work has limited headroom.
- The exact two-object XDMA PIPE-clock CDC disposition is intentionally narrow; any future count, endpoint, clock-pair, exception, or type drift is not covered.
- No LTX was generated. This does not fail G2A, but there is no probe file for later debug from this build.
- The design has not been programmed, enumerated, negotiated, or exercised on hardware. Gen2 negotiation, DMA operation, and the required 288 MB/s application payload remain unproven and outside G2A.
- Public evidence publication and LFS availability were verified from a fresh sparse clone at payload commit `bb8be9993726546cad2c120e300afd5499419951`; all 119 manifest entries matched. No publication blocker remains.

## 20. G2A conclusion

Final G2A engineering conclusion: `PASS`.

Timing classification: `PASS_WITH_TIMING_RISK` because final WHS is `+0.024 ns`. All other source, configuration, protection, inactive-boundary, clock, CDC/reset, offline-test, synthesis, implementation, routing, timing-threshold, DRC, black-box, resource, congestion, bitstream, and source-to-bit provenance gates pass.

Source branch publication: `PASS`. Evidence publication: `PASS`. Remote evidence read-back: `PASS`. The evidence payload was pushed by fast-forward and independently verified at `bb8be9993726546cad2c120e300afd5499419951`; the subsequent evidence closure commit records that observed result.

Hardware accessed: `NO`. C2H application data plane implemented: `NO`. G2B started: `NO`.

## 21. G2B readiness

`G2B_READY`

The engineering prerequisites listed by the frozen G2A contract are satisfied: source contract, Gen2 x1 effective configuration, protected R1i identity, inactive C2H boundary, 62.5 MHz application clock, CDC/reset gate, offline tests, clean synthesis/implementation/routing, positive timing, critical DRC, black-box, resource/congestion, bitstream, post-build source identity, and hardware-prohibition checks all pass.

Do not start G2B. Recommended next step: obtain Owner/Architect acceptance of this G2A result. Final execution point: `HARD STOP AFTER G2A OFFLINE BUILD`.
