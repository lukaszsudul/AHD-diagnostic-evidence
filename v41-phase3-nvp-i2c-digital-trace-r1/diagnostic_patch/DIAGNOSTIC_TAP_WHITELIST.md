# Diagnostic Tap Whitelist

Only the following functional-source edits are permitted in the non-Git export:

| File | Permitted edit | Direction | Sole sink |
|---|---|---|---|
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | add one output-only packed diagnostic port; drive it from existing registered synchronizer/filter/FSM/drive/state signals and exact ACK predicates | outward only | wrapper diagnostic port |
| `rtl/nvp/nvp6134c_autoinit.vhd` | add one output-only 64-bit trace sample; pass through packed I2C taps and append existing wrapper reset/enable/init signals | outward only | top-level trace recorder |
| `rtl/top/ahd_capture_top_xdma.sv` | connect trace sample to observer; connect observer read-only metadata/data outputs to diagnostic decode | observer-only | trace observer and diagnostic read adapter |
| `rtl/top/ahd_capture_top_xdma.sv` | insert a diagnostic request/response mux between the existing host bridge and the unchanged formal register block | host readout only | AXI-Lite read response |

New standalone diagnostic files may implement the observer, schema-specific simulation, build/audit flow, and read-only host decoder.

No other functional RTL, XDC, XCI, NVP table, video/capture, AXI4-Stream, or XDMA file may change.

`rtl/v41/control_status_regs.sv` is explicitly excluded from the patch and
remains byte-for-byte identical to the base export. The selected diagnostic
ranges are implemented in the new `rtl/diag/nvp_trace_host_read_mux.sv`.

```text
FUNCTIONAL_EXPRESSION_CHANGE_ALLOWED=NO
NEW_FUNCTIONAL_INPUTS=0
TRACE_OUTPUTS_TO_I2C_FSM=0
TRACE_OUTPUTS_TO_NVP_RESET=0
TRACE_OUTPUTS_TO_VIDEO_CAPTURE=0
TRACE_OUTPUTS_TO_XDMA_STREAM=0
```
