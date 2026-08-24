# R1g production VHDL-language contract

## Result

```text
PRODUCTION_LANGUAGE_CONTRACT_GATE=PASS
R1F_PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
R1G_PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
R1G_PRODUCTION_VHDL_STANDARD_EXACTLY_EQUAL_TO_R1F=YES
GLOBAL_VHDL_STANDARD_CHANGE=NO
FILE_TYPE_VHDL2008_CHANGES=0
READ_VHDL_VHDL2008_OPTION_ADDED=NO
PRODUCTION_LANGUAGE_CONTRACT_AMBIGUOUS=NO
```

The exact production contract is the installed Vivado file-type enum `VHDL`,
without the separately named `VHDL 2008` or `VHDL 2019` file types and without
any `-vhdl2008`/`-vhdl2019` read option. This is the canonical and reproducible
tool contract. The installed command help does not attach a separate numeric
IEEE revision label to the unqualified `VHDL` enum, so this report does not
invent a `93` versus `2002` sub-label. There is no operational ambiguity: the
exact enum, command path, file properties, library, compile order, top, part,
tool version, and absence of every opt-in newer-standard switch are proven.

## Frozen inputs

```text
R1F_SOURCE_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_SOURCE_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
R1F_FROZEN_BUILD_TCL=C:/FPGA/WORKTREES/V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY/scripts/v41/r1f_build.tcl
R1F_FROZEN_BUILD_TCL_SHA256=53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B
R1F_INVOKED_HELPER=C:/FPGA/WORKTREES/V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY/scripts/v41/xdma_config_common.tcl
R1F_INVOKED_HELPER_SHA256=3A76FC7893B2188871B340E326B53C7EE39B93C19EF416EAD2611CA9FDA9CDC7
R1F_GENERATED_PROJECT_XPR_SHA256=2C55CC97B1C9C447518251A367FC3BD1CFA16350F41BBAEF81BC0432EEE3D7E3
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
R1F_SYNTH_TOP=ahd_capture_top_xdma
R1F_PART=xc7a35tcsg325-2
```

The build Tcl has one executable `source` statement, and it names only
`xdma_config_common.tcl`. That helper fixes the XDMA part and IP configuration;
it contains no HDL read/add command, library assignment, language-standard
switch, or additional sourced helper.

## Exact HDL loading contract

The frozen build Tcl creates the project for `xc7a35tcsg325-2`, sets project
`target_language` to `Verilog`, sets `simulator_language` to `Mixed`, and then
loads repository HDL as follows:

```tcl
add_files -norecurse $sv_files
set_property FILE_TYPE SystemVerilog [get_files $sv_files]
add_files -norecurse $vhdl_files
```

There is no `read_vhdl` invocation. In particular, there is no `read_vhdl
-vhdl2008`, no `read_vhdl -vhdl2019`, and no `set_property FILE_TYPE {VHDL
2008}`. A read-only query of the exact project produced by the terminal R1f
build returned the following for every repository VHDL source:

```text
FILE_TYPE=VHDL
LIBRARY=xil_defaultlib
USED_IN=synthesis simulation
USED_IN_SYNTHESIS=1
IS_ENABLED=1
```

The four repository VHDL sources, in frozen analysis order, are:

```text
1. rtl/nvp/nvp6134c_diagnostics_pkg.vhd
2. rtl/nvp/r1f_transaction_serial_counter.vhd
3. rtl/nvp/nvp6134c_i2c_bringup.vhd
4. rtl/nvp/nvp6134c_autoinit.vhd
```

The frozen Tcl calls `update_compile_order -fileset sources_1`, then queries
the authoritative synthesis order with:

```tcl
get_files -compile_order sources -used_in synthesis
```

The terminal build recorded 112 objects: 39 Verilog, 32 Verilog Header, 31
SystemVerilog, and 10 VHDL objects. Repository units occupy positions 93--111;
the four VHDL units occupy 107--110 in the order above; the SystemVerilog top
is position 111. The complete byte-preserved build-recorded order is
`EXACT_COMPILE_ORDER.txt`:

```text
EXACT_COMPILE_ORDER_SHA256=1B0472FBF78388C4608C05C39E0E9289305EB6F64A0AFE98B2326657C71A1581
EXACT_COMPILE_ORDER_OBJECTS=112
```

The independent read-only project query additionally captured each object's
`FILE_TYPE`, `LIBRARY`, `USED_IN`, and `USED_IN_SYNTHESIS` properties. Because
the already-failed project's imported XDMA IP is locked when opened read-only,
that supplemental query is not substituted for the authoritative order
recorded live by the original build. Its purpose is property proof for the four
repository VHDL files. The complete authoritative order remains the original
R1f build record copied to `EXACT_COMPILE_ORDER.txt`.

## Installed frontend help

Installed Vivado `2025.2`, SW build `6299465`, was queried with help-only
commands. No project was created and `synth_design` was not invoked by the help
capture sessions.

The installed `read_vhdl -help` syntax is:

```text
read_vhdl -library <arg> [-vhdl2008] [-vhdl2019] ... <files>
```

It explicitly describes `-vhdl2008` and `-vhdl2019` as optional opt-ins. The
installed `xvhdl -help` likewise exposes `--2008` and `--2019` as explicit
options. Neither option is present in the frozen production build. The
installed `synth_design -help` confirms that `-rtl` is an explicit
elaboration-only mode; this capture did not invoke it. Installed help for
`get_files`, `get_property`, and `report_compile_order` confirms the exact
object/property/compile-order queries used by the build and this audit.

Raw help is under `INSTALLED_TOOL_HELP/`, with hashes in
`INSTALLED_TOOL_HELP_SHA256.txt`. Two early help-only capture attempts are
preserved: the first used a Tcl `redirect` command unavailable in this shell;
the second tried the generic `help` topic interface, which did not expose
`synth_design`. The passing capture used each installed command's `-help`
option. These were help sessions only and are not compiler iterations,
elaboration preflights, synthesis runs, or builds.

## Static no-switch proof

A case-insensitive audit of the exact frozen build Tcl, its only sourced
helper, and the generated R1f project found:

```text
R1F_BUILD_TCL_VHDL2008_TOKENS=0
R1F_BUILD_TCL_READ_VHDL_COMMANDS=0
R1F_BUILD_TCL_FILE_TYPE_VHDL2008_CHANGES=0
R1F_HELPER_VHDL2008_TOKENS=0
R1F_HELPER_READ_VHDL_COMMANDS=0
R1F_GENERATED_PROJECT_VHDL2008_TOKENS=0
R1F_READ_VHDL_COMMANDS=NONE
R1F_VHDL_FILE_TYPES=VHDL
R1F_LIBRARY_ASSIGNMENTS=REPOSITORY_VHDL_XIL_DEFAULTLIB
GLOBAL_VHDL_STANDARD_CHANGE=NO
FILE_TYPE_VHDL2008_CHANGES=0
READ_VHDL_VHDL2008_OPTION_ADDED=NO
```

The R1f terminal synthesis error is consistent with this exact contract:
Vivado rejected the sequential conditional signal assignment at committed
`rtl/nvp/nvp6134c_i2c_bringup.vhd:994` as supported only in VHDL 1076-2008.
That failure is evidence that the unqualified production `VHDL` mode did not
silently enable 2008 for this source.

## Contract handed to subsequent R1g gates

```text
R1G_REQUIRED_VHDL_FILE_TYPE=VHDL
R1G_FORBIDDEN_VHDL_FILE_TYPES=VHDL_2008,VHDL_2019
R1G_REQUIRED_VHDL_LIBRARY=xil_defaultlib
R1G_REQUIRED_VHDL_ORDER=nvp6134c_diagnostics_pkg,r1f_transaction_serial_counter,nvp6134c_i2c_bringup,nvp6134c_autoinit
R1G_REQUIRED_SYNTH_TOP=ahd_capture_top_xdma
R1G_REQUIRED_PART=xc7a35tcsg325-2
R1G_PRODUCTION_VHDL_STANDARD=EXACTLY_EQUAL_TO_R1F_PRODUCTION_VHDL_STANDARD
GLOBAL_VHDL_STANDARD_CHANGE=NO
```
