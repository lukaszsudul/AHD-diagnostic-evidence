# R1f provenance-correct one-build script requirements

## Status

```text
DOCUMENT_CLASS=INDEPENDENT_PRE_EXECUTION_SPECIFICATION
BUILD_EXECUTED_BY_THIS_REVIEW=NO
FULL_BUILDS_CONSUMED_BY_THIS_REVIEW=0
```

The inherited `scripts/v41/r1e_build.tcl` is a useful starting point but is
not an acceptable R1f build script unchanged.  The final dedicated script must
be part of the single R1f source commit and pass this static review before the
one clean-build authorization is consumed.

## Exact source and tool preconditions

The script must fail before project creation unless all of these hold:

- requested source commit is exactly the clean repository `HEAD`;
- `git status --porcelain --untracked-files=all` is empty;
- recorded source tree equals `git rev-parse HEAD^{tree}`;
- branch is `diag/v41-nvp-r1f-phase-complete-observability`;
- actual Vivado version is `2025.2`, actual SW build is `6299465`;
- part is exactly `xc7a35tcsg325-2` and top is
  `ahd_capture_top_xdma`;
- the build root is new/empty and no prior R1f build-consumed sentinel exists;
- the frozen pre-build simulation/source manifest matches the committed
  candidate sources and accepted logs.

The script must write a build-consumed marker before `create_project`.  A
failed synthesis/place/route still consumes the one authorized build and must
not be retried.

## Complete compile source list

VHDL analysis order must be:

```text
rtl/nvp/nvp6134c_diagnostics_pkg.vhd
rtl/nvp/r1f_transaction_serial_counter.vhd
rtl/nvp/nvp6134c_i2c_bringup.vhd
rtl/nvp/nvp6134c_autoinit.vhd
```

The SystemVerilog list must include every inherited source needed by the top
and these three new R1f modules before the top:

```text
rtl/v41/nvp_i2c_tri_phase_probe.sv
rtl/v41/r1f_failed_txn_logger.sv
rtl/v41/r1f_measurement_regs.sv
```

It must include the modified `rtl/v41/control_status_regs.sv` and exact top.
The obsolete `nvp_i2c_address_probe.sv` is not instantiated by the R1f top and
must not be treated as the active probe.  Compile order and a complete source
inventory must be written to evidence.

The exact unchanged XDMA XCI and complete XDC set/order are:

```text
ip/v41/xdma_v41_m1.xci
xdc/boards/current/xdma_pcie.xdc          EARLY
xdc/boards/current/pins.xdc               LATE
xdc/boards/current/vdo_input_timing.xdc   LATE
xdc/boards/current/pcie_pio.xdc           LATE
xdc/boards/current/nvp_control.xdc         LATE
xdc/common/cdc.xdc                         LATE
xdc/common/configuration_bank.xdc          LATE
```

## Frozen configuration/provenance

The script must pass the exact five 32-bit commit words and reconstruct the
40-hex source commit without loss.  It must set and later record/query:

```text
SLOT_COUNT=2
BUILD_FLAGS=0x00000002
ENABLE_MAREK_INIT_TABLE=1
AUTOINIT_I2C_HZ=25000
AUTOINIT_CLOCK_HZ=62500000
EXPECTED_CNT_AT_INIT_DONE=132584734
```

`BUILD_FLAGS=2` is diagnostic provenance only; no production meaning may be
invented.  The exact R1e measurement-register blob contains the expected
count, and the exact unchanged diagnostics-package blob contains the frozen
operation table.  Their identities must be recorded.

The imported-copy XDMA flow may reproduce the accepted configuration, but it
must preserve and record the exact source-XCI hash and prove queried imported
properties equal the accepted X1/Gen1/AXI-stream/128-KiB AXI-Lite values.

## One-build flow

Exactly one invocation may execute:

```text
synth_design
opt_design
place_design
phys_opt_design
route_design
```

No incremental or prior checkpoint may be used as an implementation input.
The routed DCP and all reports are written before gate evaluation.
`write_bitstream` is executed exactly once and only after every required gate
passes.  There is no retry loop.

All project, DCP, report, marker, and result names must use `R1F`, not the
inherited `PHASE3` label.  This diagnostic build does not resume Phase 3.

## Mandatory implementation gates

The script must query objects/results, not merely write expected literals:

```text
SYNTHESIS=PASS
PLACE=PASS
ROUTE=PASS
ROUTE_ERRORS=0
WNS>=0
WHS>0
VDO_WNS>0
VDO_WHS>0
DRC_ERRORS=0
DRC_CRITICAL_WARNINGS=0
REQP_1839_SEMANTIC_COUNT=4
REQP_1839_RAW_TEXT_COUNT_NOT_USED_AS_GATE=YES
CDC_CRITICAL=0
CDC_UNKNOWN=0
```

The `REQP-1839` count must come from the four actual Vivado violation objects
(or an equally semantic object-level enumeration), not the number of text
mentions in `report_drc`.

The gate must also record utilization, RAM type/count, congestion, clocks,
complete timing, CDC, power, I/O, and methodology reports.  Empty timing path
classes are a failure.

## R1f-specific implementation evidence

The script must inventory cells/nets for:

- `POST_INIT_TRI_PHASE_PROBE`;
- `R1F_FAILED_TXN_LOGGER`;
- `R1F_MEASUREMENT_REGS`;
- the 16-bit transaction serial counter;
- the inherited lifecycle monitor and NVP autoinit hierarchy.

It must preserve reports for SCL/SDA IOBUF properties, OEN-to-IOBUF paths,
pad-to-synchronizer paths, synchronizer placement, VDO paths, hierarchical
utilization, BRAM/distributed-RAM inference, congestion, and aggregate plus
NVP-hierarchy power.  These outputs are inputs to the required R1e-versus-R1f
routed-DCP impact audit.

## Static-review release condition

```text
R1F_BUILD_SCRIPT_STATIC_AUDIT=
    PENDING_DEDICATED_COMMITTED_SCRIPT
```

No build may start while that value is pending.  Once the final committed
script exists, this specification must be checked line-by-line against it and
the resulting script hash recorded in a separate static audit.
