# Non-synthesis production-mode compiler iteration 01

```text
ITERATION=1
SOURCE_ROLE=EXACT_R1F_BEFORE_REWRITE
SOURCE_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
SOURCE_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
BRINGUP_SHA256=A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533
COMPILER=C:\AMDDesignTools\2025.2\Vivado\bin\xvhdl.bat
LIBRARY=xil_defaultlib
VHDL2008_OPTION_USED=NO
RELAX_OPTION_USED=NO
SOURCE_ORDER=nvp6134c_diagnostics_pkg.vhd,r1f_transaction_serial_counter.vhd,nvp6134c_i2c_bringup.vhd,nvp6134c_autoinit.vhd
SYNTH_DESIGN_INVOKED=NO
PROCESS_EXIT_CODE=1
RESULT=EXPECTED_FAIL_EXACT_R1F_PRODUCTION_LANGUAGE_MODE
ERROR_CODE=VRFC_10_1449
ERROR_TEXT=this construct is only supported in VHDL 1076-2008
ERROR_FILE=rtl/nvp/nvp6134c_i2c_bringup.vhd
ERROR_LINE=994
XVHDL_LOG_SHA256=C31297C131E392D493B373DF06489B3519CC67685B44EAC916E330798068C347
SOURCE_MUTATIONS=0
```

The command used the exact production VHDL source list, dependency order and
`xil_defaultlib` library with no `--2008` or relaxation option. It reproduced
the production-language incompatibility before any R1g source edit and did
not invoke synthesis, elaboration, implementation, checkpoint or bitstream
commands.

