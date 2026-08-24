# R1g static VHDL compatibility audit

## Scope and immutable identities

This is a bounded, read-only audit of every VHDL line changed between the exact
R1e base and exact R1f diagnostic commit. No source file was edited, no
`synth_design` was invoked, and no build authorization was consumed by this
audit.

```text
R1E_BASE_COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
R1F_SOURCE_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_SOURCE_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
R1F_BUILD_TCL_SHA256=53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B
R1F_TERMINAL_BUILD_LOG_SHA256=43C05651BEFA0DB30E00B7B16058D424AFEF38FEA2D0E15A9AF0381604A7E4D0
R1F_TERMINAL_AUDIT_SHA256=9E4DA8D0F966F652F1EAAA3B4FF39DE305CDB4511AE5570DE1D97797DC44E15E
AUDIT_SCOPE=R1E_TO_R1F_CHANGED_VHDL_LINES_AND_REQUIRED_EXACT_CONTEXT
SOURCE_MUTATIONS=0
SYNTH_DESIGN_INVOCATIONS=0
```

The frozen build adds four repository VHDL files without setting a VHDL-2008
file type or adding a VHDL-2008 read option. The failed project's queried file
properties identify all four as `VHDL`, library `xil_defaultlib`, used in both
synthesis and simulation. Its queried compile order places the repository
sources at indices 107 through 110:

```text
107|VHDL|rtl/nvp/nvp6134c_diagnostics_pkg.vhd
108|VHDL|rtl/nvp/r1f_transaction_serial_counter.vhd
109|VHDL|rtl/nvp/nvp6134c_i2c_bringup.vhd
110|VHDL|rtl/nvp/nvp6134c_autoinit.vhd
```

The exact production contract is therefore
`VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008`: the installed Vivado default `VHDL`
mode with no `-vhdl2008`, `--2008`, or `FILE_TYPE=VHDL 2008` selection. The
installed help does not numerically label that default as 1993 versus 2002, so
this report deliberately does not overclaim an edition number. This audit uses
the language-contract evidence captured independently under
`02_LANGUAGE_CONTRACT`; it does not infer compatibility from filename
extension alone.

## Exact changed-line inventory

The exact diff contains eight changed VHDL files, 1,270 added lines and eight
deleted lines. `R1F_CHANGED_VHDL_LINE_INVENTORY.csv` records all 1,278 changed
lines with old/new line coordinates, SHA-256 of the exact line text, synthesis
scope, construct class and disposition.

| File | Added | Deleted | Frozen production synthesis input |
|---|---:|---:|---|
| `rtl/nvp/nvp6134c_autoinit.vhd` | 20 | 2 | yes |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | 613 | 1 | yes |
| `rtl/nvp/r1f_transaction_serial_counter.vhd` | 44 | 0 | yes |
| `tests/nvp/tb_nvp_autoinit.vhd` | 335 | 3 | no |
| `tests/nvp/tb_nvp_d2b_sequence.vhd` | 8 | 1 | no |
| `tests/nvp/tb_power_timing.vhd` | 8 | 1 | no |
| `tests/v41/tb_r1f_preinit_equivalence.vhd` | 180 | 0 | no |
| `tests/v41/tb_r1f_transaction_serial_counter.vhd` | 62 | 0 | no |

Line classifications total:

```text
NOT_APPLICABLE_REMOVED_LINE=8
NOT_EXECUTABLE_LANGUAGE_CONSTRUCT=113
VIVADO_DEFAULT_NON_2008_COMPATIBLE_BY_EXACT_CONTEXT_AUDIT=1151
VHDL2008_ONLY_PRODUCTION_BLOCKER=1
VHDL2008_ONLY_TESTBENCH_HARNESS=5
TOTAL_CHANGED_LINES=1278
```

## Production blocker

Exactly one R1f-introduced construct in the production synthesis source set is
VHDL-2008-only:

```vhdl
-- rtl/nvp/nvp6134c_i2c_bringup.vhd:994, inside process(clk),
-- START_W_A transaction-start branch
r1f_tx_wdata_r <= write_data when is_read_op = '0' else x"00";
```

This is a sequential conditional signal assignment. It is not one of the
inherited concurrent conditional signal assignments at bringup line 333 or
autoinit line 99. Exact context proves that the statement is nested in the
clocked process beginning at line 459 and in the `when START_W_A` branch
beginning at line 935.

The production frontend independently classified the exact statement:

```text
ERROR=[Synth 8-2757] this construct is only supported in VHDL 1076-2008
FILE=rtl/nvp/nvp6134c_i2c_bringup.vhd
LINE=994
SOURCE_FILE_SHA256=A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533
```

The sole permitted rewrite is the prompt-specified complete `if/else` in the
same process and same branch:

```vhdl
if is_read_op = '0' then
  r1f_tx_wdata_r <= write_data;
else
  r1f_tx_wdata_r <= x"00";
end if;
```

That rewrite preserves target, condition polarity, branch coverage, assigned
values, clock edge, priority and signal-assignment scheduling. No default,
register, variable, state transition or functional fanout is added.

## Simulation-only VHDL-2008 constructs

The exact changed-line audit also finds five VHDL-2008 occurrences in two new
simulation-only testbenches:

```text
tests/v41/tb_r1f_preinit_equivalence.vhd:4=use std.env.all
tests/v41/tb_r1f_preinit_equivalence.vhd:49=process(all)
tests/v41/tb_r1f_preinit_equivalence.vhd:166=stop
tests/v41/tb_r1f_transaction_serial_counter.vhd:4=use std.env.all
tests/v41/tb_r1f_transaction_serial_counter.vhd:59=stop
```

These are genuine VHDL-2008 test-harness constructs, but neither testbench is
in the frozen production synthesis file list. They remain part of the exact
R1f reference-simulation language mode and are not production compatibility
rewrite candidates. This distinction prevents testbench syntax from inflating
the production rewrite count or changing the accepted R1f simulation oracle.

Thus the complete changed-line result is six VHDL-2008 occurrences in four
families, but only one production occurrence and only one authorized rewrite.

## Required construct-family audit

`VHDL2008_CONSTRUCT_INVENTORY.csv` records every required family and its exact
locations/counts. Exact-context review found no R1f-introduced production use
of:

- sequential selected signal assignment;
- conditional or selected expression;
- `process(all)` or another `all`-keyword sensitivity list;
- matching case or matching relational operators;
- external names;
- generic packages, generic types or generic subprograms;
- record or array features requiring VHDL-2008;
- context declarations;
- protected types;
- VHDL-2008-only aggregate or port-map forms;
- force/release statements;
- VHDL-2008 predefined unbounded vector types.

The many `(others => ...)` aggregates, ordinary generics, named port maps,
local procedures, qualified expression `unsigned'(x"FFFFFFFF")`, case
statements and concurrent conditional assignments were checked in context and
use pre-2008-compatible forms.

## Frozen rewrite inventory and gate

```text
VHDL_CHANGED_FILES=8
VHDL_CHANGED_LINES=1278
PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
VHDL2008_CONSTRUCT_OCCURRENCES_TOTAL=6
VHDL2008_CONSTRUCT_FAMILIES_TOTAL=4
VHDL2008_TESTBENCH_ONLY_OCCURRENCES=5
VHDL2008_PRODUCTION_OCCURRENCES=1

R1G_COMPATIBILITY_REWRITE_COUNT=1
R1G_COMPATIBILITY_REWRITE_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd
R1G_COMPATIBILITY_REWRITE_LOCATIONS=R1F_LINE_994_ONLY
R1G_COMPATIBILITY_REWRITE_KIND=SEQUENTIAL_CONDITIONAL_SIGNAL_ASSIGNMENT_TO_COMPLETE_IF_ELSE

UNCLASSIFIED_CHANGED_VHDL_CONSTRUCTS=0
UNCERTAIN_PRODUCTION_COMPATIBILITY_CANDIDATES=0
GLOBAL_VHDL_STANDARD_CHANGE_REQUIRED=NO
FILE_TYPE_VHDL2008_CHANGE_REQUIRED=NO
R1G_STATIC_COMPATIBILITY_AUDIT=PASS
NEXT_GATE=MECHANICAL_LINE_994_REWRITE_AND_EXACT_PRODUCTION_MODE_COMPILER
```

The inventory is frozen before source editing. Any additional production
rewrite is outside this audit unless a later exact production-mode compiler
iteration identifies another concrete language-only incompatibility; such a
finding must be preserved and returned through the prompt's compatibility
inventory/equivalence gates before commit.
