# R7 authoritative-input identity

## Gate result

`R7_INPUT_IDENTITY=PASS`

The immutable R7 input was verified locally and against the public branch tip before any R1f source work.

| Item | Verified value |
|---|---|
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Local evidence worktree | `C:\FPGA\EVIDENCE_WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1` |
| Local `HEAD` | `16beec37a266c421da5838fbb986301d072cbb50` |
| Public `refs/heads/main` from read-only `git ls-remote` | `16beec37a266c421da5838fbb986301d072cbb50` |
| Commit tree | `52f722469cace71a5d0de03832e04ea37b67f269` |
| Parent commit | `636d8e5af51746ff5a439d39e576630d4c0edb02` |
| Commit subject | `Add completed mode-aware R1e R7 paired evidence` |
| Evidence-worktree status | clean; zero porcelain records |
| Authoritative report SHA-256 | `D28C782BBCE84A9EB5658052FEB70E112DBF43F6DD993284822A078708E1E1D2` |
| Evidence ZIP bytes | `3394246` |
| Evidence ZIP SHA-256 | `A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56` |
| ZIP SHA-256 sidecar SHA-256 | `643A70AD987E510FC99FA1645BEDEC5E02E23FDD29E2D9D65B6FCFED64F5EAC2` |
| R7 task manifest SHA-256 | `FB671D3C1E438C432B9CF2BDD2C70A0E6B649810828A2DD3C072D05E44DABF42` |
| R7 ordered-record CSV SHA-256 | `CD6E9463C00E51D14A7C02C61B3FD41998C23147DAC7C3BB6180F74836C01713` |

The report working-file Git blob and the blob at the exact evidence commit are both `22fe4efcc7b94b33ddbfc83ec4a89b8594197c84`. The R7 package is Git-LFS tracked with object ID `sha256:a1864da7ec52aee852169656808510c42d98fdce27816d82449946b610dd2a56`.

## Manifest verification

The first manifest line was treated as its format header:

```text
FORMAT=SHA256|SIZE_BYTES|TASK_ROOT_RELATIVE_PATH
```

Every remaining record was parsed, bounded beneath the sealed R7 task root, re-sized, and rehashed.

```text
MANIFEST_ENTRIES=209
DISK_FILES_EXCLUDING_MANIFEST=209
MISSING_FILES=0
EXTRA_FILES=0
SIZE_MISMATCHES=0
SHA256_MISMATCHES=0
R7_MANIFEST_INTEGRITY=PASS_209_OF_209
```

## ZIP-content verification

The ZIP was opened read-only. Every non-directory entry was streamed and SHA-256 compared to its matching sealed-task-root file, including the manifest itself.

```text
ZIP_FILE_ENTRIES=210
SEALED_TASK_ROOT_FILES=210
ZIP_DUPLICATE_PATHS=0
ZIP_MISSING_FILES=0
ZIP_EXTRA_FILES=0
ZIP_SIZE_MISMATCHES=0
ZIP_CONTENT_SHA256_MISMATCHES=0
R7_ZIP_CONTENT_INTEGRITY=PASS_210_OF_210
```

## Preserved raw input

This directory contains byte-preserved copies of:

- the R7 owner prompt;
- the R7 authoritative final report;
- the R7 task SHA-256 manifest;
- the external non-circular publication receipt;
- the package SHA-256 sidecar;
- the complete R7 evidence ZIP;
- the decoded ordered-NACK-record CSV used for the operation-86 replay.

No R7 history or raw evidence was modified.

