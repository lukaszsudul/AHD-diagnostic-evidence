# R1h source commit and tree proof

Status: `PASS`

The sole authorized R1h source commit was created only after the independent
precommit release and the frozen P5/P6 scientific-equivalence gate passed.

```text
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_PARENT_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1H_COMMITS_ABOVE_R1G=1
R1H_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
R1H_SOURCE_COMMIT_SUBJECT=Back R1f observability storage with BRAM and synchronous MMIO reads
R1H_SOURCE_COMMITTER_DATE=2026-08-25T00:35:19+02:00
R1H_CHANGED_PATHS=22
R1H_CHANGED_INSERTIONS=2250
R1H_CHANGED_DELETIONS=179
R1H_SOURCE_WORKTREE_CLEAN=YES
SCIENTIFIC_SCOPE_REDUCTION=NO
SECOND_SOURCE_COMMIT=NO
```

The parent is the exact frozen R1g source commit. Git reports one and only one
commit in `e112a5addb7ac62700a9a71af81bf368fad0bada..HEAD`. The committed diff
contains the seven production storage/MMIO integration paths and fifteen
verification paths accepted by the precommit audit; no XDC, XDMA XCI,
functional NVP table/FSM, watchdog, filter, statistical script, or host decoder
was changed.

Companion identities:

```text
R1G_TO_R1H_PATCH_SHA256=C573FA3379F2C300BAD6AD464142923F2B5318DA93DD5594705B1472105EB8FF
R1H_SOURCE_SHA256_MANIFEST=C8419FE64BD673F464B450C425C6052B2FC0BA23F62C8B2384105CE4D26E7EE5
R1H_INDEPENDENT_PRECOMMIT_RELEASE_SHA256=AFDA49CC4ADE315DAE12D8848488A2800903B8626D888EF916DB698E5A806AF7
R1H_SCIENTIFIC_EQUIVALENCE_GATE_SHA256=6879A5D0F58783D156BD08336FF06B27CFDB6096A2E58A1976A1357C2F343283
```
