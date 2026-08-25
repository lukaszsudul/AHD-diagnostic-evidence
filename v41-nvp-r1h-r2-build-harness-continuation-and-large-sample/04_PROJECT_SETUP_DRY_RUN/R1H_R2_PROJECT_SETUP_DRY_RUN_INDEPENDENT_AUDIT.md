# R1h-R2 independent project-setup dry-run audit

## Verdict

This is an independent audit of the sole R1h-R2 project-setup dry-run. The
auditor did not launch Vivado, did not alter the source repository or task
ledgers, and did not edit any producer artifact. It statically released the
sealed command before launch, monitored the resulting process read-only, and
then inspected the immutable marker, result, compile-order reports, Vivado log,
journal, and disposable project.

```text
INDEPENDENT_PRELAUNCH_AUDIT=CLEAR
INDEPENDENT_POST_RUN_AUDIT=PASS
PROJECT_SETUP_DRY_RUNS=1
PROJECT_SETUP_DRY_RUN=PASS
PROJECT_SETUP_SEMANTIC_GATE=PASS
R1H_FALSE_ASSERTION_TRIGGERED=NO
PROCESS_EXIT_CODE=0
SYNTH_DESIGN_INVOCATIONS=0
OPT_DESIGN_INVOCATIONS=0
PLACE_DESIGN_INVOCATIONS=0
PHYS_OPT_DESIGN_INVOCATIONS=0
ROUTE_DESIGN_INVOCATIONS=0
WRITE_CHECKPOINT_INVOCATIONS=0
WRITE_BITSTREAM_INVOCATIONS=0
```

## Frozen input identity and prelaunch state

FACT - immediately before launch, the exact scientific source worktree was
clean and matched the required identity:

```text
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
SOURCE_STATUS_PORCELAIN_ENTRIES=0
```

FACT - the independent audit recomputed the two frozen script identities:

```text
CORRECTED_FULL_BUILD_HARNESS_SHA256=5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F
PROJECT_SETUP_DRY_RUN_TCL_SHA256=211426FACBC0DDEED1FE360AB554EF74FDE73304AFDACA3A9CC5CD932B8476F2
```

FACT - the P0 identity reports, P1 exact-assertion/root-cause reports, and P2
corrected-harness specification, reconciliation, clean patch, and static-audit
sidecars all existed before release. Their claims reconciled to the exact
source, terminal R1h harness, and the two hashes above. The prelaunch process
inventory contained no `vivado`, `vivado_lab`, `xvlog`, `xvhdl`, `xelab`, or
`xsim` process. The dry-run root did not exist, and the evidence root contained
only the sealed dry-run Tcl: no consumed marker, PASS result, or FAIL result
existed.

FACT - a whole-token scan of the dry-run Tcl and its only sourced helper,
`scripts/v41/xdma_config_common.tcl` (SHA-256
`3A76FC7893B2188871B340E326B53C7EE39B93C19EF416EAD2611CA9FDA9CDC7`),
found zero occurrences of every forbidden build command:

```text
synth_design=0
opt_design=0
place_design=0
phys_opt_design=0
route_design=0
write_checkpoint=0
write_bitstream=0
```

The active allowed project-setup command counts were `create_project=1`,
`add_files=3`, `import_ip=1`, `generate_target=1`,
`update_compile_order=1`, `report_compile_order=1`, and `close_project=1`.
`GENERATE_SYNTH_CHECKPOINT` was set false for the copied XCI. This statically
satisfied the authorization boundary before the single launch.

## Single invocation and process result

NETLIST/TOOL-DERIVED FACT - the independent monitor observed exactly one
Vivado frontend process for this dry-run:

```text
MONITORED_DISTINCT_VIVADO_PID_COUNT=1
VIVADO_PID=14752
VIVADO_PROCESS_CREATED_LOCAL=2026-08-25T09:54:19.157591+02:00
VIVADO_SESSION_START_LOCAL=2026-08-25T09:54:21+02:00
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
```

The log and journal each identify PID 14752 and this exact command contract:

```text
vivado.exe -mode batch
  -log C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\04_PROJECT_SETUP_DRY_RUN\R1H_R2_PROJECT_SETUP_DRY_RUN_VIVADO.log
  -journal C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\04_PROJECT_SETUP_DRY_RUN\R1H_R2_PROJECT_SETUP_DRY_RUN_VIVADO.jou
  -source C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\04_PROJECT_SETUP_DRY_RUN\r1h_r2_project_setup_dry_run.tcl
  -tclargs
    C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE
    C:\FPGA\BUILDS\V41_NVP_R1H_R2_PROJECT_SETUP_DRY_RUN
    C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\04_PROJECT_SETUP_DRY_RUN
```

The root executor independently reported outer process `exit_code=0` for
unified session 78528/chunk 203d85. The task monitor observed PID 14752 exit,
no second frontend process, a terminal `R1H_R2_PROJECT_SETUP_DRY_RUN=PASS`, and
normal `Exiting Vivado` at 09:56:28 local time. No FAIL receipt exists.

## Atomic accounting and exact output identities

FACT - the atomic consumed marker was created before project construction and
contains `PROJECT_SETUP_DRY_RUNS=1`, the exact source commit/tree, and
`CONSUMED_UTC=2026-08-25T07:54:54Z`.

| Artifact | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `r1h_r2_project_setup_dry_run.tcl` | 21,881 | 548 | `211426FACBC0DDEED1FE360AB554EF74FDE73304AFDACA3A9CC5CD932B8476F2` |
| `R1H_R2_PROJECT_SETUP_DRY_RUN_CONSUMED.marker` | 175 | 4 | `B9AB69C13842CC7D99283C563F28EE806A5BA24BD246DC3E048177BF964F2D82` |
| `R1H_R2_PROJECT_SETUP_DRY_RUN_RESULT.txt` | 3,897 | 90 | `F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6` |
| `R1H_R2_DRY_RUN_QUERIED_SYNTHESIS_COMPILE_ORDER.txt` | 19,746 | 114 | `E530D6F4DA38C3499D8AE580CD87B0958251FB6402C317C3277C3DF52F047D2E` |
| `R1H_R2_DRY_RUN_REPORT_COMPILE_ORDER.txt` | 32,016 | 125 | `45CF10783009B1822DD5D7B8E4CC7346D64E76F98BBCB528DBB137A4AF26A313` |
| `R1H_R2_PROJECT_SETUP_DRY_RUN_VIVADO.log` | 27,711 | 597 | `42E606B8837E58388F4F27119DF2455AA19D6E69A7EC285DB41A71C0478BD5E5` |
| `R1H_R2_PROJECT_SETUP_DRY_RUN_VIVADO.jou` | 1,842 | 24 | `8776D8644E9D661F424192B5718AA90BED616C0299F926915B4BB5F65D3F79A0` |

## Semantic source gate and compile-order evidence

TOOL-DERIVED FACT - the result records the exact required part and top,
`PART=xc7a35tcsg325-2` and `TOP=ahd_capture_top_xdma`. For the probe-index
wrapper, probe consumer, failed-record wrapper, measurement registers, MMIO
read service, control/status registers, and top, Vivado returned exactly one
source, `FILE_TYPE=SystemVerilog`, `LIBRARY=xil_defaultlib`, and
`USED_IN_SYNTHESIS=YES`. Every required declaration and source-derived
instantiation count is one. The source architecture checks returned six
failed-record BRAM banks and three probe-index BRAM instances. The aggregate
source checks returned:

```text
SYSTEMVERILOG_MODULE_DEFINITION_COUNT=18
DUPLICATE_DEFINITIONS=0
SYSTEMVERILOG_INCLUDE_DIRECTIVES=0
SYSTEMVERILOG_PACKAGE_DECLARATIONS=0
SYSTEMVERILOG_IMPORTS=0
UNRESOLVED_INCLUDE_OR_PACKAGE_DEPENDENCIES=0
```

TOOL-DERIVED FACT - both mandatory compile-order artifacts are nonempty. The
machine-readable query contains 114 entries. The human report ends with:

```text
Missing instances for 'synthesis' with fileset 'sources_1':
< empty >
```

The report records the probe consumer at one-based position 100 and the
probe-index wrapper at position 108 (zero-based queried positions 99 and 107).
This is the exact relation that invalidated the old positional assertion. It
is recorded as evidence and is not used as a SystemVerilog pass/fail gate. The
result explicitly records:

```text
RELATIVE_SOURCE_POSITION_ASSERTION=REMOVED_OR_DISABLED
RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO
COMPILE_ORDER_RECORDED=YES
SYSTEMVERILOG_RELATIVE_COMPILE_ORDER_USED_AS_PASS_FAIL_GATE=NO
VHDL_DEPENDENCY_ORDER_USED_AS_PASS_FAIL_GATE=YES
```

## Exact duplicate-key qualification

FACT - the immutable PASS result has 90 key/value rows and 86 unique keys.
Exactly four keys occur twice:

```text
FAILED_RECORD_WRAPPER_MODULE_NAME=2 identical values
FAILED_RECORD_WRAPPER_SOURCE_PATH=2 identical values
PROBE_INDEX_WRAPPER_MODULE_NAME=2 identical values
PROBE_INDEX_WRAPPER_SOURCE_PATH=2 identical values
```

Each duplicate pair is byte-for-byte identical. There are no contradictory
values and no other duplicate keys. The duplication results from reporting the
same identity once in the semantic-source section and once in the architecture
section; it does not weaken or change the PASS result. Downstream parsers must
accept only this exact duplicate set and multiplicity and must reject any
contradictory or additional duplicate.

## No-build proof and diagnostics

TOOL-DERIVED FACT - whole-token scans of both the completed Vivado log and
journal contain zero occurrences of `synth_design`, `opt_design`,
`place_design`, `phys_opt_design`, `route_design`, `write_checkpoint`, and
`write_bitstream`. The disposable project contains zero `.dcp`, `.bit`, or
`.ltx` files, zero synthesis/implementation run directories, and zero
synthesis/place/route log files.

The log contains zero `ERROR:` and zero `CRITICAL WARNING:` records. Its two
warnings are (1) a duplicate user strategy discarded in favor of the installed
Vivado 2025.2 strategy and (2) deprecation of the still-supported mandatory
`report_compile_order -fileset` spelling. Neither warning changes the project,
source, semantic result, or authorization accounting.

FACT - after completion, no Vivado/simulation frontend process remained and
the exact source worktree still matched commit/tree with an empty porcelain
status.

## Release

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
AUDIT=R1H_R2_PROJECT_SETUP_DRY_RUN_INDEPENDENT_AUDIT
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
PROJECT_SETUP_DRY_RUN_TCL_SHA256=211426FACBC0DDEED1FE360AB554EF74FDE73304AFDACA3A9CC5CD932B8476F2
PROJECT_SETUP_DRY_RUN_RESULT_SHA256=F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6
PROJECT_SETUP_DRY_RUNS=1
PROJECT_SETUP_DRY_RUN=PASS
PROJECT_SETUP_SEMANTIC_GATE=PASS
R1H_FALSE_ASSERTION_TRIGGERED=NO
RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO
COMPILE_ORDER_RECORDED=YES
PROCESS_EXIT_CODE=0
FORBIDDEN_BUILD_COMMAND_INVOCATIONS=0
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
NEXT_GATE=ONE_SEMANTIC_FRONTEND_ELABORATION_PREFLIGHT
```
