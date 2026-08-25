# R1h-R2 Independent Corrected-Harness and Dry-Run Static Audit

## Scope and verdict

This is an independent, read-only static audit of the sealed R1h-R2 corrected
full-build harness and project-setup dry-run script. It did not execute Vivado,
did not execute either Tcl script, and did not modify the source repository,
the corrected harness, the dry-run script, or their producer's evidence.

```text
INDEPENDENT_STATIC_AUDIT=PASS
BUILD_HARNESS_CORRECTION_MODE=TASK_LOCAL_ZERO_REPOSITORY_MUTATION
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
SYSTEMVERILOG_RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO
VHDL_DEPENDENCY_ORDER_GATE=PRESERVED_BYTE_IDENTICAL
FULL_HARNESS_BUILD_COMMAND_DELTA=0
FULL_HARNESS_SOURCE_LIST_DELTA=0
FULL_HARNESS_RESOURCE_GATE_DELTA=0
DRY_RUN_FORBIDDEN_BUILD_COMMAND_INVOCATIONS=0
VIVADO_INVOKED_BY_INDEPENDENT_AUDIT=NO
PROJECT_SETUP_DRY_RUN_EXECUTION_RESULT=NOT_CLAIMED_BY_THIS_STATIC_AUDIT
```

The corrected full harness is suitable to proceed to the separately counted
one-shot project-setup dry-run. The dry-run's actual process exit, queried
Vivado properties, and generated `report_compile_order` remain runtime gates;
this audit deliberately makes no PASS claim for an execution that it did not
perform.

## Exact identities

FACT — the independently queried source worktree is clean and exact:

```text
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
SOURCE_WORKTREE_STATUS=EMPTY_CLEAN
EXPECTED_VIVADO_VERSION=2025.2
EXPECTED_VIVADO_SW_BUILD=6299465
EXPECTED_PART=xc7a35tcsg325-2
EXPECTED_TOP=ahd_capture_top_xdma
```

FACT — independently recomputed sealed artifact hashes:

| Artifact | SHA-256 |
|---|---|
| Exact terminal R1h build Tcl | `2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18` |
| Corrected R1h-R2 full harness | `5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F` |
| Project-setup dry-run Tcl | `211426FACBC0DDEED1FE360AB554EF74FDE73304AFDACA3A9CC5CD932B8476F2` |
| Clean R1h-to-R1h-R2 harness patch | `4F0088EC240BE6554A4ABDEF7A18FF5A18D6A67940276A5C3D65A9613EA21B18` |
| Build-command reconciliation CSV | `38403B34C274D21DBB33160312C6E8E7F7311FC2C61D0B228C31D28E8CE8CABE` |
| Corrected-gate specification | `EEBEE92751315C9C9A6D889803D5634A877C88C4C85A9FDB1FBC3CC5A8BABD2E` |
| Producer static-audit sidecar | `375A0C25E019D16A3A56B1E4DF561178489181D02AF013A41ADCD580C76C3C8D` |
| Producer hash sidecar | `38778036BC4C38D881646412BB8D1E6B0B6CC70FBDB437E8A667E3447D693774` |

The clean patch begins directly with `diff --git`; no Git CRLF warning text is
embedded before the patch header.

## Exact full-harness delta containment

NETLIST/BUILD-SCRIPT-DERIVED FACT — an independent line comparison found:

```text
BASELINE_LINE_COUNT=1737
CORRECTED_LINE_COUNT=1932
COMMON_BYTE_EXACT_PREFIX_LINES=977
COMMON_BYTE_EXACT_SUFFIX_LINES=724
BASELINE_ONLY_CHANGED_SPAN=978..1013
CORRECTED_ONLY_CHANGED_SPAN=978..1208
DIFF_HUNKS=1_CONTIGUOUS
```

Therefore, every line outside that single project-setup gate region is exactly
unchanged. The delta does exactly the following:

1. Adds one mandatory, report-only `report_compile_order` command and writes
   the already collected queried compile-order evidence before the gate.
2. Removes the broad SystemVerilog-before-top relative-position gate from exact
   R1h lines 991–1003.
3. Removes the named probe-index-wrapper-before-consumer relative-position gate
   from exact R1h lines 1005–1011, including the terminal assertion at lines
   1009–1011.
4. Replaces both invalid SystemVerilog order gates with semantic source,
   declaration, property, dependency, instantiation, and source-architecture
   checks.
5. Leaves the actual VHDL analysis-order gate intact.

FACT — the following obsolete tokens have zero occurrences in both the
corrected full harness and the dry-run script:

```text
top_compile_index
index_store_compile_index
probe_compile_index
R1h SystemVerilog dependency is not before
R1h probe-index BRAM wrapper is not before its probe consumer
```

FACT — all remaining `compile_order_index` call sites in each corrected script
are limited to:

- presence of every exact VHDL/SystemVerilog source in the queried compile
  order; and
- relative order of the four genuinely analysis-order-sensitive VHDL files.

No SystemVerilog-to-SystemVerilog or SystemVerilog-to-top index comparison
remains.

## VHDL order, source list, and build-flow preservation

FACT — the extracted VHDL `prior_index` gate is byte-identical between exact
R1h and the corrected harness:

```text
VHDL_GATE_SHA256_BASELINE=B4581689EF5D48FFD09ECA092BE2E11635916A94E4C5BEA17228F9F712DC3B71
VHDL_GATE_SHA256_CORRECTED=B4581689EF5D48FFD09ECA092BE2E11635916A94E4C5BEA17228F9F712DC3B71
VHDL_GATE_EXACT_EQUAL=YES
```

FACT — the exact SV/VHDL/XDC/XCI source-list block is byte-identical:

```text
SOURCE_LIST_BLOCK_SHA256_BASELINE=281A0D829770504DFC797214158034C28C9BC3F9F2C62A6C4AA1D70D40348A9E
SOURCE_LIST_BLOCK_SHA256_CORRECTED=281A0D829770504DFC797214158034C28C9BC3F9F2C62A6C4AA1D70D40348A9E
SYSTEMVERILOG_FILES=17
VHDL_FILES=4
XDC_FILES=7
XCI_FILES=1
SOURCE_LIST_SEQUENCE_DELTA=0
```

FACT — active full-harness build-command counts are unchanged, except for the
new reporting command:

| Anchored Tcl command | Exact R1h | Corrected R1h-R2 | Delta |
|---|---:|---:|---:|
| `create_project` | 1 | 1 | 0 |
| `add_files` | 3 | 3 | 0 |
| `import_ip` | 1 | 1 | 0 |
| `generate_target` | 1 | 1 | 0 |
| `synth_design` | 1 | 1 | 0 |
| `opt_design` | 1 | 1 | 0 |
| `place_design` | 1 | 1 | 0 |
| `phys_opt_design` | 1 | 1 | 0 |
| `route_design` | 1 | 1 | 0 |
| `write_checkpoint` | 2 | 2 | 0 |
| `write_bitstream` | 1 | 1 | 0 |
| `report_compile_order` | 0 | 1 | +1 report-only evidence command |

The byte-identical 724-line common suffix contains build provenance,
`synth_design`, the complete post-synthesis BRAM/resource gates, optimization,
placement, routing, DRC/CDC/timing gates, checkpoint writing, and bitstream
writing. Thus the synthesis/implementation/resource commands and their order
are not merely count-equal; their entire suffix text is unchanged.

As additional sentinels, exact occurrences of the hard resource thresholds
remain equal between scripts: `18720` = 2/2, `37440` = 2/2, and the existing
`25000` contract token = 12/12. The named failed-record and total-new-payload
RAMB18 gate tokens also remain 3/3. No source, constraint, XCI, part/top,
scientific-parameter, or resource-gate delta was found.

## Source-derived semantic gate audit

SOURCE-DERIVED FACT — the exact executable 17-file SystemVerilog list contains
18 module declarations with zero duplicate module names, zero line-start
`` `include`` directives, zero package declarations, and zero imports. The
stale planning Markdown is not used as an executable authority.

SOURCE-DERIVED FACT — declaration and ordinary-instantiation counts independently
match every semantic object checked by the corrected harness:

| Label | Declaration source/module | Declarations | Instantiation source/line | Instantiations |
|---|---|---:|---|---:|
| Probe-index wrapper | `rtl/v41/r1h_probe_index_bram_store.sv` / `r1h_probe_index_bram_store` | 1 | `rtl/v41/nvp_i2c_tri_phase_probe.sv:687` | 1 |
| Probe consumer | `rtl/v41/nvp_i2c_tri_phase_probe.sv` / `nvp_i2c_tri_phase_probe` | 1 | `rtl/top/ahd_capture_top_xdma.sv:222` | 1 |
| Failed-record wrapper | `rtl/v41/r1f_failed_txn_logger.sv` / `v41_r1f_failed_txn_logger` | 1 | `rtl/top/ahd_capture_top_xdma.sv:376` | 1 |
| Measurement registers | `rtl/v41/r1f_measurement_regs.sv` / `v41_r1f_measurement_regs` | 1 | `rtl/top/ahd_capture_top_xdma.sv:786` | 1 |
| MMIO read service | `rtl/v41/r1h_mmio_read_service.sv` / `v41_r1h_mmio_read_service` | 1 | `rtl/top/ahd_capture_top_xdma.sv:852` | 1 |
| Control/status registers | `rtl/v41/control_status_regs.sv` / `v41_control_status_regs` | 1 | `rtl/top/ahd_capture_top_xdma.sv:939` | 1 |
| Top | `rtl/top/ahd_capture_top_xdma.sv` / `ahd_capture_top_xdma` | 1 | top root | n/a |

SOURCE-DERIVED FACT — the BRAM-wrapper architecture checks derive their counts
from exact RTL text rather than trusting receipt literals:

```text
rtl/v41/r1f_failed_txn_logger.sv:78
  for (bank_index = 0; bank_index < 6; ...)
FAILED_RECORD_GENERATE_BOUND_CAPTURE=6
FAILED_RECORD_XPM_MEMORY_SDPRAM_DECLARATIONS=1
FAILED_RECORD_NAMED_XPM_INSTANCE_DECLARATIONS=1 (R1H_RECORD_PAYLOAD_RAM)

rtl/v41/r1h_probe_index_bram_store.sv:64
  for (phase_bank = 0; phase_bank < 3; ...)
PROBE_INDEX_GENERATE_BOUND_CAPTURE=3
PROBE_INDEX_XPM_MEMORY_SDPRAM_DECLARATIONS=1
PROBE_INDEX_NAMED_XPM_INSTANCE_DECLARATIONS=1 (INDEX_PAYLOAD_RAM)
```

The corrected full harness and dry-run both require the capture operation to
match exactly once, require values 6 and 3 respectively, and require exactly
one XPM declaration plus the expected named instance declaration in each
generate body. These are source-architecture gates only. They do not claim the
post-synthesis primitive mapping; the later full-top netlist gate must still
prove six plus three RAMB18 instances and absence of prohibited payload
FDRE/LUTRAM mappings.

SCRIPT-DERIVED FACT — for every named semantic source, the corrected gate also
requires at runtime:

```text
get_files count = 1
FILE_TYPE = SystemVerilog
LIBRARY = xil_defaultlib
USED_IN_SYNTHESIS = true
module declaration count = 1
duplicate module/entity definitions = 0
unresolved include/package dependency count = 0
```

These property values are correctly enforced but are not reported here as
observed Vivado facts, because this independent audit did not consume the
authorized dry-run. The dry-run and semantic elaboration must provide that
runtime evidence.

## Project-setup dry-run static authorization audit

FACT — the dry-run exact source sequences independently match the full R1h
harness: 17/17 SystemVerilog, 4/4 VHDL, 7/7 XDC, and the same
`ip/v41/xdma_v41_m1.xci`. It pins the exact commit/tree, original R1h branch,
Vivado 2025.2 build 6299465, part, top, generic values, and clean worktree.

FACT — anchored active-command scan of the sealed dry-run Tcl:

| Command | Count |
|---|---:|
| `create_project` | 1 |
| `add_files` | 3 |
| `import_ip` | 1 |
| `generate_target` | 1 |
| `update_compile_order` | 1 |
| `report_compile_order` | 1 |
| `close_project` | 1 |
| `synth_design` | 0 |
| `opt_design` | 0 |
| `place_design` | 0 |
| `phys_opt_design` | 0 |
| `route_design` | 0 |
| `write_checkpoint` | 0 |
| `write_bitstream` | 0 |

`generate_target all` is limited to project/IP registration; immediately
before it the imported XCI object is assigned
`GENERATE_SYNTH_CHECKPOINT false`. It therefore does not silently invoke the
forbidden top-level synthesis/implementation/checkpoint/bitstream commands in
the Tcl source.

The dry-run creates its exclusive consumed marker before entering project
setup, refuses a nonempty dry-run root, requires evidence/build roots outside
the source repository, closes the project before writing its PASS receipt, and
contains no retry loop. Its only compile-order comparisons are source presence
and the preserved VHDL dependency order. No SystemVerilog relative-position
pass/fail remains.

## Qualification and next gate

The producer's `TCL_INFO_COMPLETE.console.txt` records `info complete` PASS for
both scripts, while its stderr also records a Tcl installation initialization
warning. This independent audit does not use that helper result as proof of
Vivado execution or semantic binding. The authorized one-shot project-setup
dry-run and the separately counted semantic elaboration remain the fail-closed
authorities for actual Vivado properties, module binding, process exit, and
black-box status.

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
AUDIT=R1H_R2_INDEPENDENT_HARNESS_AND_DRY_RUN_STATIC_AUDIT
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
CORRECTED_HARNESS_SHA256=5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F
PROJECT_SETUP_DRY_RUN_TCL_SHA256=211426FACBC0DDEED1FE360AB554EF74FDE73304AFDACA3A9CC5CD932B8476F2
PATCH_SHA256=4F0088EC240BE6554A4ABDEF7A18FF5A18D6A67940276A5C3D65A9613EA21B18
RELATIVE_SOURCE_POSITION_ASSERTION=REMOVED_OR_DISABLED
RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO
COMPILE_ORDER_RECORDED=YES
PROJECT_SETUP_SEMANTIC_GATE_STATIC_AUDIT=PASS
DRY_RUN_FORBIDDEN_BUILD_COMMAND_INVOCATIONS=0
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
VIVADO_INVOCATIONS=0
SYNTH_DESIGN_INVOCATIONS=0
OPT_DESIGN_INVOCATIONS=0
PLACE_DESIGN_INVOCATIONS=0
ROUTE_DESIGN_INVOCATIONS=0
WRITE_CHECKPOINT_INVOCATIONS=0
WRITE_BITSTREAM_INVOCATIONS=0
NEXT_ACTION=CONSUME_EXACTLY_ONE_PROJECT_SETUP_DRY_RUN_THEN_ONE_SEMANTIC_ELABORATION_PREFLIGHT
```
