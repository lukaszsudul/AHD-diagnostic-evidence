# R1h-R2 corrected build-harness gate specification

## Frozen identity

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
EXPERIMENT_NAME=R1h
CONTINUATION_REVISION=R2
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
PART=xc7a35tcsg325-2
TOP=ahd_capture_top_xdma
BUILD_HARNESS_CORRECTION_MODE=TASK_LOCAL_ZERO_REPOSITORY_MUTATION
```

The exact terminal R1h harness is
`C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\07_BUILD\r1h_build.tcl`,
SHA-256
`2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18`.
The R1h-R2 corrected copy is task-local. No tracked source, RTL, XDC, XCI,
test, host, or scientific file is modified.

## Source-derived semantic facts

- `r1h_probe_index_bram_store` is declared exactly once in
  `rtl/v41/r1h_probe_index_bram_store.sv` and instantiated exactly once as an
  ordinary SystemVerilog module in `nvp_i2c_tri_phase_probe.sv`.
- `nvp_i2c_tri_phase_probe` is declared exactly once and instantiated exactly
  once beneath `ahd_capture_top_xdma`.
- `v41_r1f_failed_txn_logger` is declared exactly once and instantiated
  exactly once beneath `ahd_capture_top_xdma`.
- The probe-index wrapper has exactly one syntactic `xpm_memory_sdpram`
  instance named `INDEX_PAYLOAD_RAM` inside a source-derived generate loop with
  bound `phase_bank < 3`.
- The failed-record logger has exactly one syntactic `xpm_memory_sdpram`
  instance named `R1H_RECORD_PAYLOAD_RAM` inside a source-derived generate loop
  with bound `bank_index < 6`.
- The exact executable R1h build list contains 17 SystemVerilog and four VHDL
  production files. The stale planned markdown entry
  `rtl/v41/nvp_i2c_address_probe.sv` is not added.
- None of the exact 17 SystemVerilog files contains an include directive,
  package declaration, or import. The wrapper and consumer do not use an
  interface, bind statement, configuration, external typedef, or macro include.
- The VHDL diagnostics package has a real analysis-order dependency. Its exact
  four-file order gate is retained unchanged.

SystemVerilog module binding is semantic, not a requirement that a module's
file precede every file containing an ordinary instantiation. Vivado itself
computes compile order from the selected top and design dependencies. The
official Vivado 2025.2 Compile Order documentation describes automatic compile
ordering and documents `report_compile_order -fileset sources_1`:
https://docs.amd.com/r/en-US/ug893-vivado-ide/Compile-Order-View

## Removed pass/fail conditions

The complete SystemVerilog relative-position block from terminal R1h lines
991 through 1011 is removed. This includes both:

```text
R1h SystemVerilog dependency is not before the queried top compile unit
R1h probe-index BRAM wrapper is not before its probe consumer
```

Neither `wrapper_position < consumer_position` nor
`module_position < top_position` remains a pass/fail condition. No
`reorder_files`, manual file-order override, or source-list reorder is added.

## Replacement semantic gate

Before the build reaches its unchanged synthesis command, the corrected
harness requires:

```text
WRAPPER/CONSUMER FILE QUERY COUNT=1 each
FILE_TYPE=SystemVerilog
LIBRARY=xil_defaultlib
USED_IN_SYNTHESIS=YES
TARGET MODULE DECLARATION COUNT=1 each
SOURCE-DERIVED WRAPPER INSTANTIATION COUNT=1 each
FAILED-RECORD GENERATE BOUND=6
FAILED-RECORD XPM DECLARATION/INSTANCE-NAME COUNT=1/1
PROBE-INDEX GENERATE BOUND=3
PROBE-INDEX XPM DECLARATION/INSTANCE-NAME COUNT=1/1
DUPLICATE SYSTEMVERILOG MODULE DEFINITIONS=0
DUPLICATE VHDL ENTITY DEFINITIONS=0
SYSTEMVERILOG INCLUDE/PACKAGE/IMPORT DEPENDENCIES=0
VHDL DIAGNOSTICS PACKAGE DECLARATION/USE COUNT=1/1
UNRESOLVED INCLUDE OR PACKAGE DEPENDENCIES=0
```

`report_compile_order -fileset sources_1 -used_in synthesis` and the
machine-readable queried file inventory are written before semantic gating.
SystemVerilog relative positions are evidence only. The exact VHDL dependency
order remains the sole relative compile-order pass/fail check.

## One-shot project-setup dry-run

`04_PROJECT_SETUP_DRY_RUN/r1h_r2_project_setup_dry_run.tcl` creates a new
disposable project, adds the exact 17+4 sources, copies/imports the exact XCI,
applies the exact shared XDMA configuration, adds the exact seven XDC files,
sets the exact part/top/generics, updates and reports compile order, executes
the semantic gate, closes the project, and exits. An atomic consumed marker is
created before project creation. Static scanning proves zero invocation of any
synthesis, optimization, placement, routing, checkpoint, or bitstream command.

## One-shot semantic elaboration

`05_SEMANTIC_ELABORATION/Run-R1hR2SemanticElaboration.ps1` is a separately
accounted one-shot `xvhdl`/`xvlog`/`xelab` frontend run. It uses the four exact
VHDL sources, 17 exact SystemVerilog production sources, XPM/unisim libraries,
and the already accepted simulation-only XDMA binding stub. It requires the
passing dry-run receipt and proves the wrapper, consumer, logger, MMIO service,
and exact top bind with zero unresolved modules or black boxes. It contains no
full-build or implementation command.

## Reconciliation

The static reconciliation proves the corrected full-build harness is
byte-identical to terminal R1h outside the compile-order/semantic-gate region.
It independently compares the exact source/XDC/XCI lists, VHDL dependency
gate, part/top, post-synthesis BRAM/resource gate, and ordered
synthesis/implementation commands.

```text
SYNTHESIS_IMPLEMENTATION_COMMAND_DELTA=0
SOURCE_LIST_DELTA=0
CONSTRAINT_DELTA=0
XCI_DELTA=0
PART_TOP_DELTA=0
RESOURCE_GATE_DELTA=0
SCIENTIFIC_PARAMETER_DELTA=0
BUILD_COMMAND_SEMANTICS_CHANGED=NO
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
```
