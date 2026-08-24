# Exact R1f Git identity and R1g worktree proof

## Source-object gate

`PASS_EXACT_LOCAL_R1F_COMMIT_AVAILABLE`

```text
R1F_SOURCE_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1F_SOURCE_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6

R1F_PARENT_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1F_PARENT_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

COMMITS_ABOVE_R1E_BASE=
    1
```

`git cat-file -e 225544084dbfcaadb8592fcecc947aa1cec4970e^{commit}`
passed. Direct inspection of the commit object proved the exact tree and
single direct parent. The exact existing R1f worktree had zero staged or
unstaged tracked differences before the child worktree was created.

## Recovery decision

```text
R1F_RECOVERY_SOURCE=
    EXACT_EXISTING_LOCAL_COMMIT

PUBLISHED_PATCH_RECONSTRUCTION_USED=
    NO

APPROXIMATE_RECONSTRUCTION_USED=
    NO
```

## Authorized R1g child worktree

```text
R1G_WORKTREE=
    C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY

R1G_BRANCH=
    diag/v41-nvp-r1g-vhdl-compatibility

R1G_INITIAL_HEAD=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1G_INITIAL_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6

R1G_INITIAL_STATUS=
    CLEAN_ZERO_PORCELAIN_LINES

SOURCE_EDITS_AT_P0=
    0
```

The new branch initially points directly at the exact R1f commit. No commit,
amend, rebase, source edit, build, Vivado invocation, JTAG operation, SSH
operation, or hardware action occurred in this P0 task.

