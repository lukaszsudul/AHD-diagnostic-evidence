# R1f-to-R1g source change scope

```text
R1G_COMPATIBILITY_REWRITE_COUNT=1
R1G_COMPATIBILITY_REWRITE_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd
R1G_COMPATIBILITY_REWRITE_LOCATIONS=R1F_LINE_994_ONLY
R1G_SOURCE_CHANGE_CLASS=VHDL_LANGUAGE_COMPATIBILITY_ONLY
R1G_FUNCTIONAL_RTL_CHANGE=NO
R1G_DIAGNOSTIC_SEMANTICS_CHANGE=NO
R1G_SCIENTIFIC_PARAMETER_CHANGE=NO
GLOBAL_VHDL_STANDARD_CHANGE=NO
FILE_TYPE_VHDL2008_CHANGES=0
READ_VHDL_VHDL2008_OPTION_ADDED=NO
R1F_BRINGUP_SHA256=A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533
R1G_CANDIDATE_BRINGUP_SHA256=66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024
CHANGED_FILES=1
LINES_ADDED=5
LINES_REMOVED=1
```

The only source change replaces the VHDL-2008 sequential conditional signal
assignment at exact R1f line 994 with a complete `if`/`else` assignment in
the same `process(clk)` branch. The target, condition polarity, true and false
values, width, assignment time, delta-cycle behavior, local priority and
complete coverage are unchanged. No assignment moved across a process or
clock/reset/FSM branch, and no variable, latch or register was introduced.

All other tracked source bytes remain at the exact R1f commit. The five other
VHDL-2008 constructs found by the complete changed-VHDL audit occur only in
simulation testbenches excluded from the production synthesis file list, so
they are not production compatibility rewrites.

