# R1h-R2 P5 prebuild manifest/generator plan

## Status

`PREPARED_NOT_FINALIZED_P4_PASS_REQUIRED`

This plan is task-local. Preparation did not invoke Vivado, Git, a source
script, a hardware tool, or the generator. The generator must not be executed
until the sole R1h-R2 semantic frontend/elaboration preflight and its independent
post-run audit both pass.

## Frozen identities

| Item | Exact value |
|---|---|
| R1h source commit | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` |
| R1h source tree | `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| R1h branch | `diag/v41-nvp-r1h-bram-backed-large-sample` |
| Exact R1h prebuild manifest SHA-256 | `192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79` |
| Exact R1h manifest source rows | `224` |
| Exact R1h manifest accepted-log rows | `32` |
| Corrected task-local harness SHA-256 | `5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F` |
| P3 raw PASS receipt SHA-256 | `F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6` |
| P3 independent audit SHA-256 | `3232F2FA10C6036C3D8D7F3F8E9A3CBC45BAEA4821B8F7A2739F14806F3C60AD` |
| Harness/dry-run independent audit SHA-256 | `EA965F065BD35EEE281A8FD47446C4BB8BA6DC87A5CB84DABA06C9487E7A14C3` |
| P4 canonical runner SHA-256 | `265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546` |
| P4 pre-execution independent audit SHA-256 | `0A35C816A7B82C50B267D60F9AEA54F1517493E00783380C9867D0BFABC726C1` |

## Future P4 independent receipt contract

After P4 executes, an independent auditor must create, without altering the P4
result, this task-local receipt:

`05_SEMANTIC_ELABORATION/R1H_R2_SEMANTIC_ELABORATION_INDEPENDENT_AUDIT.txt`

It must contain unique `KEY=VALUE` lines with at least:

```text
INDEPENDENT_SEMANTIC_ELABORATION_AUDIT=PASS
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
SEMANTIC_ELABORATION_PREFLIGHTS=1
SEMANTIC_ELABORATION=PASS
R1H_TEST_ELABORATION=PASS
UNRESOLVED_MODULES=0
UNRESOLVED_BLACKBOXES=0
FAILED_RECORD_WRAPPER_BINDING=PASS
PROBE_INDEX_WRAPPER_BINDING=PASS
PROCESS_EXIT_CODE=0
CANONICAL_RUNNER_SHA256=265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546
SEMANTIC_RESULT_SHA256=<exact 64 uppercase hex digest>
BLOCKERS=NONE
```

The generator independently hashes the P4 result and requires the receipt's
`SEMANTIC_RESULT_SHA256` to match.

## Generator behavior after P4 PASS

`New-R1hR2PrebuildManifest.ps1 -FinalizeAfterP4Pass` is one-shot and
fail-closed. It will:

1. require the exact immutable R1h manifest and corrected harness hashes;
2. require exact P3 result/audit hashes;
3. require the P4 result, exact PASS/binding fields, tool-log hashes, duplicate
   normalization audit, and independent post-run receipt;
4. use read-only Git commands to prove exact `HEAD`, tree, branch, 224 tracked
   files, and a clean worktree;
5. require the tracked path set and all 224 source hashes to equal the exact
   R1h manifest;
6. reverify all 32 inherited accepted-log records;
7. copy every inherited scientific metadata record, changing only
   `R1H_BUILD_TCL_SHA256` to the corrected task-local harness hash;
8. add explicit R1h-R2 metadata proving zero RTL/XDC/XCI/register/host/statistical
   change and P3/P4 PASS;
9. add task-local accepted-log bindings for the corrected harness, P3, P4, and
   their independent audits;
10. atomically create a new manifest, SHA sidecar, and verification receipt.

No Vivado command exists in the generator. Its Git command allowlist is
read-only: `rev-parse`, `symbolic-ref`, `status`, and `ls-files`.

The generated manifest remains compatible with the corrected R1h-R2 harness:
all 224 source rows and inherited scientific metadata remain exact; only the
task-local build-harness digest and additional provenance/evidence records are
new.
