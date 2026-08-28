# AHD v41 G2A CDC and Reset Static Review

## Result

`SOURCE STATIC REVIEW: PASS`

`FINAL CLEAN R2 CDC/RESET GATE: PASS`

The final G2A source identity is commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`. It changes no application RTL or active source XDC relative to qualified R1i. Clean R2 completed with `SOURCE_POST_BUILD=PASS`, reproduced the narrowly bounded Gen2-only XDMA generated-clock signature exactly, resolved all three named bus-skew constraints with zero violations, and reported no additional critical or Unknown CDC object.

## Protected NVP clock and reset independence

- `rtl/top/ahd_capture_top_xdma.sv:34-39` maps `autonomous_clk = axi_aclk` exactly as qualified.
- `rtl/top/ahd_capture_top_xdma.sv:47-54` freezes `NVP_AUTOINIT_CLK_HZ=62,500,000`, the 25 kHz I2C binding, and the 320-cycle POR counter.
- `rtl/top/ahd_capture_top_xdma.sv:55-87` implements the configuration-initialized POR state entirely on `autonomous_clk`; no `axi_aresetn`, `user_lnk_up`, PERST, DMA-enable, or host-command term controls it.
- `rtl/top/ahd_capture_top_xdma.sv:96-116` connects the protected autoinit block only to `autonomous_clk` and `nvp_por_reset`.
- `rtl/nvp/nvp6134c_autoinit.vhd:44-49,98-101,158-203` preserves the qualified 500 ms reset hold, 1.5 s start behavior, and protected reset/start sequencing.
- External PERST enters only the XDMA path at `rtl/top/ahd_capture_top_xdma.sv:24,41,1055-1060`.
- `user_lnk_up` feeds only the observation-only lifecycle monitor and unused bundle at `rtl/top/ahd_capture_top_xdma.sv:128-140,1088`. It cannot control NVP initialization.

Result: NVP reset/start remains independent of `user_lnk_up`, `axi_aresetn`, PERST, driver state, and host activity.

## AXI-Lite and application resets

- `rtl/top/ahd_capture_top_xdma.sv:931-947` gives the AXI-Lite host bridge synchronous logic reset `~axi_aresetn`; `rtl/v41/axi_lite_host_bridge.sv:85-95` clears its FSM and stored transactions to the qualified idle state.
- `rtl/top/ahd_capture_top_xdma.sv:950-971` gives `control_status_regs` reset `~axi_aresetn`; `rtl/v41/control_status_regs.sv:205-227` preserves the qualified scratch/response reset values.
- `rtl/top/ahd_capture_top_xdma.sv:863-889` preserves the inherited R1h read-service reset `(~axi_aresetn) || nvp_por_reset`.
- The C2H outputs and H2C `TREADY` are combinational constants in the XDMA port map. Their safe inactive meaning is independent of reset sequencing.

The downstream capture application intentionally observes PCIe user reset in the inherited design: top line `1015` supplies `~axi_aresetn` as `pcie_user_reset`, and `rtl/video/video_capture.sv:58-99` synchronizes/combines it for application storage/PIO state. This does **not** reset or restart the protected NVP POR/autoinit/I2C engine and is not a new G2A dependency.

## Existing video and control CDC mechanisms

- `rtl/video/physical_frontend.sv:40-45,100-185`: VCLK IBUF/BUFIO/BUFG structure, IDELAY-ready/reset synchronizers, IDDR capture, and explicit BUFIO-to-BUFG bridge register.
- `rtl/video/video_capture.sv:58-99,143-200`: async-assert/sync-release reset chains and registered Gray diagnostic crossings.
- `rtl/record/capture_mailbox.sv:63-82,130-230`: bundled configuration/status mailbox with synchronized request/acknowledge handshakes.
- `rtl/pio/pio_bar_target.sv:115-156,254-340`: dual-clock RAM and producer/PCIe toggle handshakes.
- `xdc/common/cdc.xdc:4-32`: bundled-data max-delay/bus-skew, first-stage toggle false paths, registered Gray constraints, and explicit async-reset-chain false paths.
- `xdc/boards/current/vdo_input_timing.xdc:24-44`: qualified recovered-video input timing and discarded-edge exclusion.
- `xdc/boards/current/xdma_pcie.xdc:4-6`: 100 MHz PCIe reference-clock constraint and PERST false path.

No application CDC RTL, synchronizer, reset source, active source XDC, constraint value, or hierarchy query is intentionally changed by G2A. Clean R2 post-generation/post-route reports prove that the inherited 6 ns max-delay and 3 ns bus-skew queries resolve after XDMA regeneration: all three named constraints are met and the violation count is zero.

## Gen2-only XDMA generated CDC-13 disposition

The final clean R2 route reported two `CDC-13` entries, but both are clock views of the same XDMA-generated internal endpoint pair rather than two independent application crossings:

`XDMA/inst/xdma_v41_m1_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_sel_reg/C`

to:

`XDMA/inst/xdma_v41_m1_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1`

The authoritative R2 clock views in `<BUILD_EVIDENCE_ROOT>\CDC.rpt` are:

| Report lines | Source clock | Destination clock | CDC classification | Exception |
|---|---|---|---|---|
| `39-45` | `clk_125mhz_mux_x0y0` | `clk_250mhz_x0y0` | `CDC-13 Critical`, `User Ignored` | `False Path` |
| `47-53` | `clk_250mhz_mux_x0y0` | `clk_250mhz_x0y0` | `CDC-13 Critical`, `User Ignored` | `False Path` |

This structure is newly elaborated by the intentional Gen2 setting, not by an R1i or application-CDC change. The regenerated XDMA RTL instantiates `pclk_i1_bufgctrl` only when `PCIE_LINK_SPEED != 1`; Gen2 generation supplies link-speed encoding `2`, whereas the Gen1 branch used encoding `1`.

AMD-generated XDC provides the exact disposition. In the final generated file `<BUILD_ROOT>\vivado_project\v41_g2a_r1i_gen2_offline.gen\sources_1\ip\xdma_v41_m1\ip_0\source\xdma_v41_m1_pcie2_ip-PCIE_X0Y0.xdc`, the exact S0 and S1 selector-pin false paths and the physically-exclusive 125/250 MHz generated-clock group were all revalidated. `<BUILD_EVIDENCE_ROOT>\CLOCK_INTERACTION.rpt` correspondingly resolves the affected pairs through the exclusive group or false path. These are narrow, generated-IP constraints; no broad CDC waiver or application false path is introduced.

This disposition follows frozen G1 policy rather than weakening it. `V41_G1_RESOURCE_HEADROOM_POLICY.md:22` permits development critical findings only when each is dispositioned and generated-clock/CDC exceptions resolve to the intended objects. `V41_G1_GEN2_XDMA_CHANGE_PLAN.md:71` explicitly anticipates Gen2 changes to generated internal clocks, exceptions, and clock buffers and requires routed CDC/clock reporting. The exact endpoint, two clock views, generated constraints, and physically-exclusive relationship above satisfy that review obligation for the final R2 design.

`G2A_CDC_EXACT_DISPOSITION.txt` records:

- `CDC_CRITICAL_TOTAL=2` and `CDC_CRITICAL_DISPOSITIONED=2`;
- exact IDs `CDC-13#1,CDC-13#2` on the endpoint pair above;
- both clock contexts exactly as tabulated, with `CDC_TYPE=User Ignored` and `EXCEPTION=False Path`;
- `GENERATED_XDC_S0_FALSE_PATH=PASS`, `GENERATED_XDC_S1_FALSE_PATH=PASS`, and `GENERATED_XDC_CLOCKS_PHYSICALLY_EXCLUSIVE=PASS`;
- `CDC_UNKNOWN=0`;
- `APPLICATION_CDC_DISPOSITIONED=0`;
- `BROAD_CDC_WAIVER_APPLIED=NO`.

The routed hard gates additionally record `BUS_SKEW_GATE=PASS`, `BUS_SKEW_VIOLATIONS=0`, `BUS_SKEW_MET_CONSTRAINTS=3`, `XDC_COLLECTION_GATE=PASS`, and `BLACK_BOX_COUNT=0`. No application/R1i CDC finding was waived or reclassified.

## Static stop-condition review

| Condition | Finding |
|---|---|
| New NVP dependence on `user_lnk_up` | none |
| New NVP dependence on `axi_aresetn` | none |
| New NVP dependence on PERST | none |
| PERST polarity/path change | none |
| AXI-Lite reset semantic change | none |
| C2H tie-off reset semantic change | none |
| Video CDC/reset logic change | none |
| Active XDC change | none |
| New application/R1i CDC/reset dependency outside G1 | none |
| Gen2-generated XDMA clock-mux CDC | exact two-view vendor-IP exception above; narrowly dispositioned, no broad waiver |
| Final clean R2 CDC/reset result | `PASS`; exact two-object generated-XDMA disposition, zero Unknown, zero application disposition, no broad waiver |

Source/pre-synthesis CDC/reset gate: `PASS`.

Final clean R2 CDC/reset gate: `PASS`.
