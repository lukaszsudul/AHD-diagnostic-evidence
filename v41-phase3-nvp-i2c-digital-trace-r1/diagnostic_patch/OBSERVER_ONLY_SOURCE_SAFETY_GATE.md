# Observer-only source safety gate

The sealed non-Git source is a 185-file export-derived tree. Every file matches
`DIAGNOSTIC_SOURCE_MANIFEST_SHA256.txt`; the verification found zero missing,
extra, or mismatched files.

## Functional blob comparison

`SOURCE_BLOB_COMPARISON.csv` compares the base export and sealed diagnostic
tree. Only these functional-source files differ:

- `rtl/nvp/nvp6134c_i2c_bringup.vhd`: output-only packing from existing
  registered state and the exact ACK decision predicate;
- `rtl/nvp/nvp6134c_autoinit.vhd`: output-only wrapper sample packing;
- `rtl/top/ahd_capture_top_xdma.sv`: observer instantiation and isolated
  diagnostic request/response mux integration.

The following are byte-for-byte unchanged:

- NVP table/diagnostics package;
- physical frontend and video/capture logic;
- record producer and mailbox;
- AXI-Lite host bridge and all 53 formal registers;
- PIO slot/target implementation;
- XDMA XCI;
- NVP and VDO constraints.

The two new diagnostic modules expose no functional control output. Trace data
and metadata terminate in the read-only diagnostic mux. Requests outside the
exact diagnostic windows pass to the unchanged formal block; diagnostic writes
are consumed with no state effect.

```text
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
DIAGNOSTIC_PATCH_SHA256=0D7BD2907296D65401D83EF9F41CF7270940DF4FB392264C32B76E455CD45A6F
DIAGNOSTIC_SOURCE_MANIFEST_SHA256=3C415A97490E723829E6DE3A1B9F2CDE0F3A2A5AE605A1996A613A50CAF597BD
SEALED_SOURCE_FILE_COUNT=185
SEALED_SOURCE_MISMATCH_COUNT=0
FORMAL_CONTROL_STATUS_REGS_BLOB_CHANGED=0
XDMA_XCI_BLOB_CHANGED=0
VIDEO_CAPTURE_FUNCTIONAL_BLOBS_CHANGED=0
AXIS_RECORD_FUNCTIONAL_BLOBS_CHANGED=0
RAW_SDA_FUNCTIONAL_EXPRESSION_CHANGED=0
RAW_SCL_FUNCTIONAL_EXPRESSION_CHANGED=0
NVP_RST_FUNCTIONAL_EXPRESSION_CHANGED=0
EXISTING_53_REGISTER_OFFSETS_CHANGED=0
EXISTING_53_REGISTER_SEMANTICS_CHANGED=0
TRACE_OUTPUTS_TO_I2C_FSM=0
TRACE_OUTPUTS_TO_NVP_RESET=0
TRACE_OUTPUTS_TO_VIDEO_CAPTURE=0
TRACE_OUTPUTS_TO_XDMA_STREAM=0
SOURCE_OBSERVER_ONLY_GATE=PASS
```

R2 differs from R1 only by replacing two observer tap-export VHDL-2008 syntax
forms with equivalent syntax accepted by the preserved production VHDL mode.
No expression, state transition, timing parameter, or functional signal path
changed. The exact sealed R2 tree passed the complete inherited and
observer-specific simulation gate before build cycle 2.
