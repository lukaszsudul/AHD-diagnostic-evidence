# Diagnostic tap whitelist

Only these tracked functional-source files differ from the exact base export:

| File | Observer-only purpose |
|---|---|
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | Adds output-only packing of already-registered SDA/SCL stages, drive enables, exact tick/ACK/first-NACK conditions, state, operation, table/bank, and first-error context. |
| `rtl/nvp/nvp6134c_autoinit.vhd` | Adds output-only wrapper packing for reset, power-enable intent, and init state. |
| `rtl/top/ahd_capture_top_xdma.sv` | Instantiates the R1 high-resolution observer, R2 context/shadow observer, and read-only address overlay. |
| `rtl/top/ahd_capture_top_pcie.v` | Leaves the diagnostic-only wrapper outputs open in the non-XDMA top. |

The three inherited testbenches change only to leave the added output ports
open. Every other functional RTL, XDC, XCI, NVP table, video/capture source,
AXI4-Stream source, and formal register implementation is byte-identical to
the exact base export.

No diagnostic output is a functional input. The only observer sinks are
diagnostic BRAM/metadata and the read-only AXI-Lite overlay.

NEW_FUNCTIONAL_INPUTS=0
NVP_I2C_FUNCTIONAL_EXPRESSIONS_CHANGED=0
NVP_RESET_FUNCTIONAL_EXPRESSION_CHANGED=0
XDMA_CONFIGURATION_CHANGED=0
V40B_AXIS_CONTRACT_CHANGED=0

