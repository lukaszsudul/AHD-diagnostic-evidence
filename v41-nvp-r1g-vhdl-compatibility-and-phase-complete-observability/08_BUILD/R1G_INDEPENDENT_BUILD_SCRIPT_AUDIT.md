# Independent audit — R1g single-consumption full-build script

## Scope and result

This audit compares the prepared P8 R1g build Tcl with the exact frozen R1f
build Tcl. Neither script was sourced or executed. No project, synthesis,
implementation, checkpoint, or bitstream operation was performed.

```text
AUDIT_RESULT=PASS_PREPARED_SCRIPT_NOT_EXECUTED
R1G_BUILD_TCL=../scripts/r1g_build.tcl
R1G_BUILD_TCL_SHA256=C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A
R1G_BUILD_TCL_BYTES=52824
R1G_BUILD_TCL_LINES=1345
R1F_FROZEN_BUILD_TCL_SHA256=53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B
R1F_TO_R1G_PATCH_SHA256=15574BCC4E3B5F8440C0668474DABB9A7455CD010866D527F18CB222FD457479
TCL_INFO_COMPLETE=1
FULL_CLEAN_BUILDS_EXECUTED_BY_THIS_AUDIT=0
BLOCKERS=NONE
```

An independent `git diff --no-index` regenerated the current delta. Its raw
LF file has SHA-256
`472BFBA396CC56F96670D6909CBBD73F8AA73233FADC01E204B80096B8D32301`.
The supplied patch has CRLF line endings, but both normalize to the same 8,011
bytes and the same SHA-256 above. Git reports no content difference between
the two patches.

## Delta classification

The actual R1f-to-R1g patch has 14 hunks. Every hunk is confined to:

- R1g comments, usage text, branch name, project name, task/result labels;
- the R1g bit, synthesis-DCP, routed-DCP, result, and failure output names;
- exact direct-child topology enforcement for parent
  `225544084dbfcaadb8592fcecc947aa1cec4970e`;
- the expected two commits above R1e instead of R1f's one;
- the R1g one-build sentinel and associated receipts.

No source list, source order, constraint list, XCI, XCI configuration, part,
top, project language property, generic, scientific constant, prebuild gate,
synthesis/implementation directive, timing/DRC/CDC gate, report query, or
bitstream gating condition changed.

```text
R1F_TO_R1G_BUILD_COMMAND_DELTA=PROVEN_PROVENANCE_AND_OUTPUT_NAMING_ONLY
SCIENTIFIC_OR_FUNCTIONAL_BUILD_DELTA=NONE
VHDL_LANGUAGE_STANDARD_DELTA=NONE
IMPLEMENTATION_COMMAND_DELTA=NONE
TIMING_DRC_CDC_GATE_DELTA=NONE
```

Legacy `R1F_*` names that are not provenance-sensitive remain intentionally
byte-identical to the frozen build script. The retained cosmetic error text
`R1f implementation gate failed` does not alter control flow, gate values, or
artifact identity.

## Exact frontend and project contract

The 15 SystemVerilog, four VHDL, and seven XDC lists match R1f exactly in
content and order. The script retains:

```text
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
PART=xc7a35tcsg325-2
TOP=ahd_capture_top_xdma
TARGET_LANGUAGE=Verilog
SIMULATOR_LANGUAGE=Mixed
XPM_LIBRARIES=XPM_CDC,XPM_MEMORY
VHDL_LOAD_COMMAND=add_files -norecurse $vhdl_files
VHDL_FILE_TYPE=VHDL_DEFAULT_NON_2008
VHDL_LIBRARY=xil_defaultlib_BY_DEFAULT
READ_VHDL_COMMANDS=0
VHDL2008_SWITCHES=0
XDMA_XCI=ip/v41/xdma_v41_m1.xci
XDMA_XCI_SHA256=EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C
GENERATE_SYNTH_CHECKPOINT=false
```

The generic list remains structurally identical:

```text
SLOT_COUNT=2
GIT_SHA_W0..W4=SOURCE_COMMIT_WORDS
BUILD_FLAGS=0x00000002
ENABLE_MAREK_INIT_TABLE=1
```

The R1g commit/tree are supplied at invocation and must match clean HEAD. The
script additionally requires the R1e merge base, exactly two commits above
R1e, and direct parent equal to the exact R1f commit. This is a strict
provenance addition, not a build-flow change.

## Full-build command sequence

Static executable command counts for R1g equal R1f exactly:

```text
CREATE_PROJECT=1
IMPORT_IP=1
GENERATE_TARGET=1
SYNTH_DESIGN=1
OPT_DESIGN=1
PLACE_DESIGN=1
PHYS_OPT_DESIGN=1
ROUTE_DESIGN=1
WRITE_CHECKPOINT=2
WRITE_BITSTREAM=1
READ_VHDL=0
WHILE_LOOPS=0
RETRY_LOOPS=0
```

The ordered synthesis/implementation commands and arguments remain:

```tcl
synth_design -top $top -part $expected_part -flatten_hierarchy rebuilt
write_checkpoint -force <R1g synthesis DCP>
opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore
write_checkpoint -force <R1g routed DCP>
write_bitstream $bit_path   ;# only after the unchanged implementation gate passes
```

The full implementation gate remains byte-identical: synthesis and placement
must pass; route errors must be zero; WNS must be nonnegative; WHS, VDO WNS,
and VDO WHS must be positive; DRC error/critical-warning counts must be zero;
the semantic REQP-1839 count must be four; CDC critical/unknown and bus-skew
violations must be zero. The raw REQP text count is still not used as a gate.

## One-build consumption and no retry

All Git, clean-tree, version, source-constant, source-hash, accepted-log, and
prebuild-manifest gates execute before build consumption. The script then
requires that neither the sentinel nor target bit exists and atomically opens:

```text
R1G_ONE_CLEAN_BUILD_CONSUMED.marker
MODE=WRONLY CREAT EXCL
CONSUMED_BEFORE_CREATE_PROJECT=YES
```

The sentinel open occurs exactly once and before the sole `create_project`.
All build commands occur once inside one `catch`. On any failure, the script
writes one terminal failure receipt with `PROGRAM_RETRY_AUTHORIZED=NO` and
exits nonzero. There is no loop or alternate execution mode around project,
synthesis, implementation, or bitstream generation.

## Independent conclusion

```text
R1G_BUILD_SCRIPT_STATIC_CONTRACT=PASS
TCL_COMPLETENESS=PASS
R1F_TO_R1G_SOURCE_LIST_EQUALITY=PASS
R1F_TO_R1G_BUILD_SEQUENCE_EQUALITY=PASS
R1F_TO_R1G_COMMAND_ARGUMENT_EQUALITY=PASS_EXCEPT_PROVEN_OUTPUT_NAMES
DEFAULT_NON_2008_VHDL_CONTRACT=PASS
DIRECT_CHILD_PROVENANCE_GATE=PASS_PREPARED
EXACT_ONE_BUILD_SENTINEL=PASS
NO_RETRY_CONTRACT=PASS
SAFE_TO_BIND_IN_R1G_PREBUILD_MANIFEST=YES_SUBJECT_TO_PARENT_GATES
```
