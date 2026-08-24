# Independent audit — R1g final RTL-elaboration preflight script

## Scope and result

This is a static/parser-only audit of the prepared P7 script. The target Tcl
was not sourced or executed. No Vivado project was created, no
`synth_design` command was invoked, and the one authorized final preflight was
not consumed by this audit.

```text
AUDIT_RESULT=PASS_PREPARED_SCRIPT_NOT_EXECUTED
SCRIPT=../scripts/r1g_final_rtl_elaboration_preflight.tcl
SCRIPT_SHA256=98EB91E4F39ECF41E47A62CC626514F6E1B091A6F99DD0127FDA7F51E514E26F
SCRIPT_BYTES=14292
SCRIPT_LINES=389
TCL_INFO_COMPLETE=1
TCL_COMPLETENESS_LOG_SHA256=AAD15B144C212A16B7178E3E0A6EDEE7DD86FF76AB9D89EE9DB7827B449B8A31
FINAL_RTL_ELABORATION_PREFLIGHTS_EXECUTED_BY_THIS_AUDIT=0
BLOCKERS=NONE
```

Tcl completeness was checked with `info complete` using installed Vivado
2025.2 `xtclsh`. The checker only opened the target files as text; it did not
evaluate them.

## Identity and production contract

The prepared script fails closed unless all of the following are exact:

```text
EXPECTED_BRANCH=diag/v41-nvp-r1g-vhdl-compatibility
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1G_PARENT_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
R1G_COMMITS_ABOVE_R1F=1
SOURCE_TREE_CLEAN=YES_REQUIRED
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
PART=xc7a35tcsg325-2
TOP=ahd_capture_top_xdma
XDMA_XCI_SHA256=EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C
XDMA_HELPER_SHA256=3A76FC7893B2188871B340E326B53C7EE39B93C19EF416EAD2611CA9FDA9CDC7
```

The 15 SystemVerilog, four VHDL, and seven XDC repository lists are exactly
equal, element for element and in order, to the prepared R1g build script and
the exact frozen R1f build Tcl. The VHDL order is:

```text
rtl/nvp/nvp6134c_diagnostics_pkg.vhd
rtl/nvp/r1f_transaction_serial_counter.vhd
rtl/nvp/nvp6134c_i2c_bringup.vhd
rtl/nvp/nvp6134c_autoinit.vhd
```

The project is in-memory, uses plain `add_files` for the four VHDL files, and
checks each queried object for `FILE_TYPE=VHDL` and
`LIBRARY=xil_defaultlib`. There is no `read_vhdl` command, `-vhdl2008`
option, `--2008` option, or `FILE_TYPE VHDL 2008` assignment. The two textual
`VHDL2008` occurrences are negative receipt field names whose values are zero;
they are not command options or file types.

```text
PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
GLOBAL_VHDL_STANDARD_CHANGE=NO
READ_VHDL_COMMANDS=0
READ_VHDL_VHDL2008_OPTIONS=0
FILE_TYPE_VHDL2008_ASSIGNMENTS=0
```

The top-level generic contract is identical to R1f except that the five Git
words are derived from the requested R1g commit, as required:

```text
SLOT_COUNT=2
GIT_SHA_W0..W4=EXACT_R1G_COMMIT_WORDS
BUILD_FLAGS=0x00000002
ENABLE_MAREK_INIT_TABLE=1
```

The imported XCI is copied and rehashed, the exact shared helper applies the
same frozen configuration, `GENERATE_SYNTH_CHECKPOINT` is set to `false`, and
the IP target is generated before compile-order checks.

## Command and single-consumption audit

Executable command counts are:

```text
CREATE_PROJECT_COMMANDS=1
CREATE_PROJECT_MODE=IN_MEMORY
SYNTH_DESIGN_COMMANDS=1
SYNTH_DESIGN_ARGUMENTS=-rtl -name r1g_rtl_preflight -top ahd_capture_top_xdma -part xc7a35tcsg325-2
OPT_DESIGN_COMMANDS=0
PLACE_DESIGN_COMMANDS=0
PHYS_OPT_DESIGN_COMMANDS=0
ROUTE_DESIGN_COMMANDS=0
WRITE_CHECKPOINT_COMMANDS=0
WRITE_BITSTREAM_COMMANDS=0
WHILE_LOOPS=0
RETRY_LOOPS=0
```

The sole `synth_design` command is not inside any loop or reusable procedure.
The outer `catch` records one terminal PASS or FAIL; the failure path exits
with `PROGRAM_RETRY_AUTHORIZED=NO`.

Before `create_project`, the script atomically opens
`R1G_FINAL_RTL_ELABORATION_PREFLIGHT_CONSUMED.marker` with
`WRONLY CREAT EXCL`. A pre-existing marker blocks the run. Therefore every
actual invocation that reaches project setup consumes exactly one preflight,
and no retry path exists.

## Independent conclusion

```text
FINAL_PREFLIGHT_STATIC_CONTRACT=PASS
TOP_AND_PART_CONTRACT=PASS
DEFAULT_NON_2008_VHDL_CONTRACT=PASS
SOURCE_LIST_AND_ORDER_CONTRACT=PASS
XCI_AND_GENERIC_CONTRACT=PASS
EXACTLY_ONE_SYNTH_DESIGN_RTL=YES
IMPLEMENTATION_OR_BITSTREAM_COMMANDS=0
NO_RETRY_CONTRACT=PASS
SAFE_TO_PROCEED_TO_SINGLE_AUTHORIZED_EXECUTION=YES_SUBJECT_TO_PARENT_GATES
```
