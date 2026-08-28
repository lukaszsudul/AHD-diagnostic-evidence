# AHD v41 G2A C2H Inactive-Boundary Receipt

## Result

`STATIC SOURCE CONTRACT PASS — APPLICATION C2H REMAINS CONSTANT-INACTIVE; H2C REMAINS BACKPRESSURED`

This receipt is a static source proof against the final clean-committed G2A source identity:

- Integration commit: `224d194e5f82c85bcb29297561c5d5e76d28063b`
- Integration tree: `283f98c02e6f9c61716875415cf000682f8ab856`
- Integration branch: `integration/v41-r1i-gen2-g2a`
- Source status at inspection: clean

The final tree retains the exact qualified R1i composite top, `rtl/top/ahd_capture_top_xdma.sv`. Its final-tree blob is `d04ff833994bc83e29647c0a7cce4cc941c3410e` and its SHA-256 is `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4`, identical to qualified R1i. No G2A source commit changed that file.

## Exact C2H values

The XDMA instance in `rtl/top/ahd_capture_top_xdma.sv:1078-1080` connects the application C2H interface as follows:

| Signal | Exact source value | Functional result |
|---|---|---|
| `s_axis_c2h_tdata_0` | `64'b0` | No application payload data |
| `s_axis_c2h_tkeep_0` | `8'b0` | No valid payload bytes |
| `s_axis_c2h_tlast_0` | `1'b0` | No packet/record termination |
| `s_axis_c2h_tvalid_0` | `1'b0` | No C2H handshake can occur |

`s_axis_c2h_tready_0` is observed only into local wire `c2h_tready` and is included in the deliberately unused observation bundle at `rtl/top/ahd_capture_top_xdma.sv:1049-1053,1086-1091`. It has no application fanout.

The tie-offs are direct constants in the XDMA port map. They are not sequential, reset-gated, link-gated, or state-dependent; therefore C2H remains inactive before, during, and after `axi_aresetn`, PERST, or link-state transitions.

## H2C safe boundary

At `rtl/top/ahd_capture_top_xdma.sv:1081-1083`, all XDMA H2C outputs terminate in local observation-only wires and application input `m_axis_h2c_tready_0` is exactly `1'b0`. The mandatory single H2C engine is therefore permanently backpressured and unsupported, as frozen by G1.

## Structural absence proof

The clean-committed contract suite and production-source search found no second C2H connection and no application C2H implementation. The exact base-to-final source allowlist contains only `ip/v41/xdma_v41_m1.xci`, `scripts/v41/xdma_config_common.tcl`, `scripts/v41/g2a_build.tcl`, and `tests/v41/run_g2a_offline_checks.ps1`; it contains no RTL, XDC, driver, or application data-plane source. In particular:

- no record-to-C2H adapter was added;
- no C2H formatter was added;
- no C2H FIFO, queue, channel ring, or DMA ring was added;
- no DMA channel scheduler was added;
- no host DMA contract, descriptor contract, or driver change was added;
- no application source drives `TVALID`, `TDATA`, `TKEEP`, or `TLAST`.

The inherited BT.656 record path remains PIO-only: `rtl/video/video_capture.sv:275-375` feeds the record producer through `pio_slot_adapter` into BAR slot RAM. `rtl/pio/pio_slot_adapter.sv:3-5` explicitly describes this as the temporary PIO path; it never reaches XDMA C2H.

The only `scheduler` identifiers in production RTL belong to the protected R1f NVP diagnostic probe, not a DMA scheduler. The only test-side XDMA stream ports are dummy/elaboration-stub signals in `tests/v41/xdma_v41_m1_elaboration_stub.sv`.

## Telemetry confirmation

The inactive DMA telemetry inputs in `rtl/top/ahd_capture_top_xdma.sv:996-1000` remain tied to zero, including stream status, streamed/dropped records, C2H stall cycles, last streamed sequence, stream errors, IRQ count, and H2C attempts. No new DMA MMIO behavior is activated.

## Scope attestation

`C2H application data plane: NOT IMPLEMENTED`  
`C2H inactive-boundary static source check: PASS`  
`H2C inactive/backpressured static source check: PASS`  
`Final R2 post-build source identity check: PASS`  
`G2B started: NO`  
`Hardware accessed: NO`

Clean R2 completed from commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`, and the build receipt records `SOURCE_POST_BUILD=PASS`, `SOURCE_TO_BIT_PROVENANCE=PASS`, `C2H_DATA_PLANE_IMPLEMENTED=NO`, `HARDWARE_ACCESSED=NO`, and `G2B_STARTED=NO`. Because the protected composite-top blob and SHA-256 remain exactly those recorded above, the final routed/bitstream build preserves the same constant-inactive C2H and constant-backpressured H2C boundary.

Final C2H inactive-boundary gate: `PASS`. No application payload generator, record formatter, FIFO/ring, scheduler, or host DMA contract was added.
