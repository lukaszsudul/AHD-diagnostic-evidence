# R1g final RTL-elaboration preflight script — static audit

This audit covers the prepared single-use script only. The final post-commit
RTL elaboration has **not** been run and its accounting remains zero.

```text
SCRIPT=../scripts/r1g_final_rtl_elaboration_preflight.tcl
SCRIPT_SHA256=98EB91E4F39ECF41E47A62CC626514F6E1B091A6F99DD0127FDA7F51E514E26F
SCRIPT_BYTES=14292
SCRIPT_LINES=389
TCL_INFO_COMPLETE=1
TCL_INFO_COMPLETE_LOG_SHA256=B5D32916A412AC487C210934AC669A5613CAFF97D37198367DB706083BA56703
CREATE_PROJECT_COMMANDS=1
SYNTH_DESIGN_COMMANDS=1
SYNTH_DESIGN_MODE=RTL_ONLY
OPT_DESIGN_COMMANDS=0
PLACE_DESIGN_COMMANDS=0
PHYS_OPT_DESIGN_COMMANDS=0
ROUTE_DESIGN_COMMANDS=0
WRITE_CHECKPOINT_COMMANDS=0
WRITE_BITSTREAM_COMMANDS=0
READ_VHDL_COMMANDS=0
VHDL2008_OPTION_TOKENS=0
RETRY_LOOPS=0
FINAL_RTL_ELABORATION_PREFLIGHTS_EXECUTED=0
STATIC_AUDIT=PASS_PREPARED_NOT_EXECUTED
```

The one `retry` text occurrence is the fail-closed receipt literal
`PROGRAM_RETRY_AUTHORIZED=NO`; it is not control flow. The script checks the
exact R1g direct-child topology, clean branch, source commit/tree, Vivado
2025.2 build 6299465, part, top, four-file VHDL order, `VHDL` file type,
`xil_defaultlib`, frozen XDMA XCI/helper hashes, unchanged generics, and the
queried synthesis compile order before its sole allowed
`synth_design -rtl` command.

The Tcl completeness check was a parser-only Vivado invocation of
`check_tcl_complete.tcl`; it did not source or execute the preflight script,
create a project, invoke synthesis, or create the single-use sentinel.
