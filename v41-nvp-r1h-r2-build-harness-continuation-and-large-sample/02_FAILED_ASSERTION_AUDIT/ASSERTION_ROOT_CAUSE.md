# R1h-R2 exact failed-assertion root-cause audit

## Identity and evidence boundary

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
EXPERIMENT_NAME=R1h
CONTINUATION_REVISION=R2
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_SOURCE_PARENT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_EVIDENCE_COMMIT=7dc8b8fb07033148e7c232c235da012d8b14b621
R1H_AUTHORITATIVE_REPORT_SHA256=E7B41C0DD5CF21499BE55D8C4019F07694B1255252AB7539A1A376E7839B6468
R1H_EVIDENCE_PACKAGE_SHA256=C56FE89CE24403FE7BD4702B53778BA4C2B5403536185BCC66EB32B8118CBC78
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
R1H_BUILD_TCL_SHA256=2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18
R1H_TERMINAL_FAILURE_RECEIPT_SHA256=BC21A70F01CDBE4EAAA929326711E3A0E0C48BBF9EE31FF017513C003B2BD363
R1H_SAVED_XPR_SHA256=35174F780F5AEA58284E037ABDC62F947AC2B7448FC103FEF6854D3ABA6DEF39
```

This is a read-only audit of the immutable terminal R1h source, build harness,
log, receipt, and saved pre-synthesis project. It did not invoke Vivado and did
not change any source or harness.

## Evidence before interpretation

### Exact terminal assertion

The executable harness is:

```text
C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\07_BUILD\r1h_build.tcl
```

Its exact terminal block is at lines 1005-1011:

```tcl
set index_store_compile_index [compile_order_index $actual_compile_names \
  [file join $repo_root rtl v41 r1h_probe_index_bram_store.sv]]
set probe_compile_index [compile_order_index $actual_compile_names \
  [file join $repo_root rtl v41 nvp_i2c_tri_phase_probe.sv]]
if {$index_store_compile_index >= $probe_compile_index} {
  error "R1h probe-index BRAM wrapper is not before its probe consumer"
}
```

Required audit fields:

```text
ASSERTION_FILE=C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\07_BUILD\r1h_build.tcl
ASSERTION_LINE=1009-1011
ASSERTION_EXPRESSION=if {$index_store_compile_index >= $probe_compile_index} { error "R1h probe-index BRAM wrapper is not before its probe consumer" }
WRAPPER_FILE_QUERY=compile_order_index $actual_compile_names [file join $repo_root rtl v41 r1h_probe_index_bram_store.sv]
CONSUMER_FILE_QUERY=compile_order_index $actual_compile_names [file join $repo_root rtl v41 nvp_i2c_tri_phase_probe.sv]
WRAPPER_FILE_COUNT=1
CONSUMER_FILE_COUNT=1
ASSERTION_EXECUTED_BEFORE_SYNTH_DESIGN=YES
```

The counts are exact in both the executable 17-file SystemVerilog source list
and the saved `sources_1` project. The terminal harness did not separately
receipt the multiplicity of its queried compile-order list; it proved presence
of both distinct normalized paths before the comparison. Because the paths are
distinct, the triggered `>=` test proves the strict queried relation:

```text
OBSERVED_RELATIVE_POSITIONS=
    QUERIED_INDEX(r1h_probe_index_bram_store.sv) >
    QUERIED_INDEX(nvp_i2c_tri_phase_probe.sv)
EXACT_NUMERIC_QUERIED_INDEXES=UNAVAILABLE_ASSERTION_PRECEDED_RECEIPT_WRITE
```

The saved project independently corroborates the relation: consumer ordinal 7,
wrapper ordinal 15, and top ordinal 21 in `sources_1` (zero based). Its XML file
elements occur at lines 145, 201, and 239 respectively. Project serialization
is corroborating evidence, not a replacement for the unavailable numeric
runtime-query receipt.

The terminal failure receipt records `TERMINAL_BUILD_STAGE=PROJECT_SETUP` and
zero synthesis, optimization, placement, routing, and bitstream runs. The only
`synth_design` command is later, at harness lines 1052-1054. Therefore:

```text
R1H_TERMINAL_ASSERTION_CAUSED_STOP=PROVEN
SYNTH_DESIGN_REACHED=NO
```

### Exact source constructs and dependency type

At exact commit `c4f4bfcf...`:

* `rtl/v41/r1h_probe_index_bram_store.sv:9` declares the standalone
  SystemVerilog module `r1h_probe_index_bram_store` exactly once.
* `rtl/v41/nvp_i2c_tri_phase_probe.sv:16` declares the standalone
  SystemVerilog module `nvp_i2c_tri_phase_probe` exactly once.
* `rtl/v41/nvp_i2c_tri_phase_probe.sv:687` contains one ordinary named-module
  instantiation: `r1h_probe_index_bram_store INDEX_PAYLOAD_STORE (...)`.
* `rtl/top/ahd_capture_top_xdma.sv:222-228` contains one ordinary instance of
  `nvp_i2c_tri_phase_probe`, named `POST_INIT_TRI_PHASE_PROBE`.
* The probe wrapper contains one syntactic `xpm_memory_sdpram` instance inside
  a constant three-iteration generate loop (`GEN_INDEX_BRAM`), yielding the
  three architectural index-memory instances.

Across all 17 SystemVerilog files in the executable production source list,
there are 18 module declarations and no duplicate module name. There is no
`include`, external package import, interface, `bind`, preprocessor macro
dependency, or scope-resolution reference. The two `typedef enum` declarations
in the probe are local to the probe module. The wrapper has no typedef. Both
files use the project default library `xil_defaultlib`, are SystemVerilog, and
the saved project marks each `UsedIn=synthesis`. XPM is a separate library
dependency explicitly enabled by harness line 889:
`XPM_LIBRARIES {XPM_CDC XPM_MEMORY}`; it is not a file-order dependency between
the wrapper and probe.

AMD UG901 2025.2 distinguishes order-sensitive compilation-unit declarations
from declarations scoped inside modules, packages, interfaces, or programs,
and states that Vivado automatically manages project compile order. Vivado
binding resolves an instantiated Verilog/SystemVerilog module by design-unit
name during elaboration. Relevant official documentation:

* https://docs.amd.com/r/2025.2-English/ug901-vivado-synthesis/Controlling-File-Compilation-Order
* https://docs.amd.com/r/2025.2-English/ug901-vivado-synthesis/Compilation-Units
* https://docs.amd.com/r/2025.2-English/ug901-vivado-synthesis/Binding

The exact source has none of the compilation-unit/package/include conditions
that could make the wrapper textually precede the consumer. Correctness is a
module availability, uniqueness, library, and elaboration/binding property.

```text
WRAPPER_CONSTRUCT=SYSTEMVERILOG_MODULE
CONSUMER_CONSTRUCT=SYSTEMVERILOG_MODULE
DEPENDENCY_CONSTRUCT=ORDINARY_NAMED_MODULE_INSTANTIATION
RELATIVE_FILE_POSITION_IS_SEMANTIC_REQUIREMENT=NO_FOR_MODULE_ENTITY_BINDING
R1H_FALSE_ASSERTION_CLASSIFICATION=REDUNDANT_RELATIVE_MODULE_FILE_ORDER_ASSERTION
```

### A second forbidden relative SystemVerilog position gate

Harness lines 991-1003 also require six ordinary SystemVerilog module source
files to precede the top file numerically in the queried list. These are the
probe-index wrapper, probe, failed-record logger, measurement registers, MMIO
read service, and control/status registers. The top binds those modules by
name; the audited sources have no external order-sensitive declaration.

Although that block did not trigger in R1h, it is the same invalid predicate
class. Leaving it would violate the R1h-R2 requirement `No relative
module-file-order gate`. Therefore the allowed task-local correction must
replace the complete SystemVerilog relative-position block at lines 991-1011,
not merely change the terminal error text or manually reorder files.

The VHDL analysis-order check at lines 983-990 is different. It preserves the
known package/entity analysis order across four VHDL design units and must
remain unchanged.

```text
R1H_TOP_RELATIVE_ORDER_GATE_CLASSIFICATION=REDUNDANT_RELATIVE_MODULE_FILE_ORDER_ASSERTION
SYSTEMVERILOG_RELATIVE_GATE_LINES_TO_REPLACE=991-1011
VHDL_ANALYSIS_ORDER_GATE_LINES_TO_PRESERVE=983-990
MANUAL_SOURCE_REORDER_REQUIRED=NO
```

### Non-authoritative planned inventory

`R1H_PLANNED_SOURCE_ORDER.md` lists 18 SystemVerilog files and includes
`rtl/v41/nvp_i2c_address_probe.sv`. The exact executable Tcl at lines 508-525
contains 17 SystemVerilog files and does not include that file; the saved XPR
also contains exactly 17 `.sv` files and no address-probe file. Consequently
the planned Markdown inventory is stale and must not be used for source-list or
position gates. The executable Tcl, terminal log, and saved XPR are
authoritative for this audit.

```text
R1H_PLANNED_SOURCE_ORDER_STATUS=STALE_NON_AUTHORITATIVE
EXECUTABLE_SYSTEMVERILOG_SOURCE_COUNT=17
SAVED_XPR_SYSTEMVERILOG_SOURCE_COUNT=17
SOURCE_LIST_RECONCILIATION_BASIS=EXECUTABLE_TCL_AND_SAVED_XPR
```

## Required semantic replacement

The task-local R1h-R2 harness should keep the exact source list and all build
commands, record compile order without using relative SystemVerilog positions
as a pass/fail gate, and replace lines 991-1011 with the following checks:

1. Query exactly one project file object for each expected source path.
2. Require `FILE_TYPE=SystemVerilog`, `LIBRARY=xil_defaultlib`, and synthesis
   use for wrapper, consumer, failed logger, measurement registers, MMIO
   service, control/status registers, and top.
3. Count exact module declarations across the 17 executable SystemVerilog
   sources and require no duplicate definition.
4. Require exactly one wrapper declaration and one consumer declaration.
5. Freeze source-derived binding topology and counts:

```text
FAILED_RECORD_WRAPPER_MODULE_NAME=v41_r1f_failed_txn_logger
FAILED_RECORD_WRAPPER_SOURCE_PATH=rtl/v41/r1f_failed_txn_logger.sv
FAILED_RECORD_WRAPPER_DECLARATION_COUNT=1
FAILED_RECORD_WRAPPER_INSTANTIATION_COUNT=1
FAILED_RECORD_XPM_GENERATED_BANK_COUNT=6

PROBE_INDEX_WRAPPER_MODULE_NAME=r1h_probe_index_bram_store
PROBE_INDEX_WRAPPER_SOURCE_PATH=rtl/v41/r1h_probe_index_bram_store.sv
PROBE_INDEX_WRAPPER_DECLARATION_COUNT=1
PROBE_INDEX_WRAPPER_INSTANTIATION_COUNT=1
PROBE_INDEX_XPM_GENERATED_BANK_COUNT=3

PROBE_CONSUMER_MODULE_NAME=nvp_i2c_tri_phase_probe
PROBE_CONSUMER_DECLARATION_COUNT=1
PROBE_CONSUMER_INSTANTIATION_COUNT=1
MMIO_SERVICE_MODULE_NAME=v41_r1h_mmio_read_service
MMIO_SERVICE_DECLARATION_COUNT=1
MMIO_SERVICE_INSTANTIATION_COUNT=1
```

6. Require no unresolved include/package dependencies; the exact source-derived
   expected count is zero.
7. Run `report_compile_order -fileset sources_1` and save it before any semantic
   gate error. Also save the exact `get_files -compile_order sources -used_in
   synthesis` inventory. Record relative positions, but do not gate on them.
8. Preserve the VHDL order check.
9. Prove actual wrapper and consumer binding, zero unresolved modules, and zero
   R1h-attributable black boxes in the separately authorized semantic
   elaboration preflight.

```text
COMPILE_ORDER_RECORDED=REQUIRED
COMPILE_ORDER_USED_AS_SYSTEMVERILOG_RELATIVE_POSITION_GATE=NO
PROJECT_SETUP_SEMANTIC_GATE_SPECIFICATION=COMPLETE
SYNTHESIS_IMPLEMENTATION_COMMAND_DELTA=0_REQUIRED
SOURCE_LIST_DELTA=0_REQUIRED
CONSTRAINT_DELTA=0_REQUIRED
XCI_DELTA=0_REQUIRED
PART_TOP_DELTA=0_REQUIRED
RESOURCE_GATE_DELTA=0_REQUIRED
SCIENTIFIC_PARAMETER_DELTA=0_REQUIRED
BUILD_HARNESS_CORRECTION_MODE=TASK_LOCAL_ZERO_REPOSITORY_MUTATION_RECOMMENDED
```

## Conclusion

The R1h build did not expose a source, module, or BRAM architecture failure. It
was stopped before synthesis by a task-local assertion that treated automatic
SystemVerilog project file ordering as an RTL semantic requirement. Exact
source and project evidence prove that the wrapper and consumer are unique,
synthesis-used SystemVerilog module design units linked by ordinary elaboration
binding, with no order-sensitive include/package/compilation-unit dependency.
The semantic correction is therefore confined to the task-local build harness;
no RTL, file reordering, XDC, XCI, test, host, register-map, or scientific
change is necessary or permitted.

