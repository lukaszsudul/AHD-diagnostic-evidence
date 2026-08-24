# R1g source commit and tree proof

```text
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_SOURCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_COMMITS_ABOVE_R1F=1
R1G_BRANCH=diag/v41-nvp-r1g-vhdl-compatibility
R1G_CHANGED_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd
R1G_CHANGED_FILE_COUNT=1
R1G_CHANGED_LINES=5_ADDITIONS_1_DELETION
R1G_SOURCE_CHANGE_CLASS=VHDL_LANGUAGE_COMPATIBILITY_ONLY
R1G_FUNCTIONAL_RTL_CHANGE=NO
R1G_DIAGNOSTIC_SEMANTICS_CHANGE=NO
R1G_SCIENTIFIC_PARAMETER_CHANGE=NO
SOURCE_TREE_CLEAN=YES
```

The commit is the sole direct child of the frozen R1f diagnostic commit. Its
only tracked delta is the predeclared line-994 rewrite from a sequential
conditional signal assignment to a complete same-process `if/else` assignment.
The rewrite was committed only after the default-production-language compiler,
complete cross-standard equivalence matrix, inherited R1f scoreboards, host
fixtures, and independent precommit audit all passed.

Git object identity:

```text
R1G_BRINGUP_GIT_BLOB=acde0bc1c90b37a5e5c2b12f31e045ad2b3bfcc2
R1G_BRINGUP_BYTES=85350
R1G_BRINGUP_SHA256=66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024
COMMIT_SUBJECT=Make R1f diagnostics compatible with production VHDL frontend
COMMIT_AUTHOR=lukaszsudul <103749296+lukaszsudul@users.noreply.github.com>
COMMIT_DATE=2026-08-24T18:36:11+02:00
```
