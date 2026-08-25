# Exact terminal R1h Git identity

Verification time: `2026-08-25T07:18:30.7277606Z`

Verification was read-only against the local Git worktree and the exact local
objects. No checkout, fetch, branch creation, commit, source edit, or push was
performed.

```text
SOURCE_REPOSITORY=C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE
SOURCE_REMOTE=https://github.com/lukaszsudul/FPGA_AHD
CHECKED_OUT_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample

R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_DIRECT_PARENT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_COMMIT_SUBJECT=Back R1f observability storage with BRAM and synchronous MMIO reads
COMMITS_ABOVE_R1G=1

R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_SOURCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_DIRECT_PARENT=225544084dbfcaadb8592fcecc947aa1cec4970e

WORKTREE_STATUS_PORCELAIN_ENTRIES=0
WORKTREE_CLEAN=YES
R1H_SOURCE_BRANCH_PUBLIC_REMOTE_MATCH_COUNT=0
R1H_R2_SOURCE_BRANCH_PUBLIC_REMOTE_MATCH_COUNT=0
```

The exact R1g-to-R1h commit delta contains 22 paths, 2,250 insertions, and 179
deletions. The changed-path SHA-256 inventory in `R1H_SOURCE_SHA256.txt` was
freshly checked against the clean worktree: 22/22 paths present, correct size,
and correct SHA-256.

```text
R1H_HEAD_MATCH=PASS
R1H_TREE_MATCH=PASS
R1H_DIRECT_CHILD_OF_R1G=PASS
R1H_CHANGED_PATH_SHA256_RESULT=PASS_22_OF_22
R1H_EXACT_SOURCE_IDENTITY=PASS
FPGA_RTL_SOURCE_CHANGES_BY_R1H_R2=0
TRACKED_BUILD_HARNESS_COMMITS=0
```
