# R1h-R2 independent P5 prebuild release audit

## Verdict

FACT — the finalized R1h-R2 prebuild input is internally consistent, binds the
exact clean terminal R1h source, preserves every exact R1h tracked blob, binds
all inherited and continuation evidence by SHA-256, and is accepted by the
manifest contract implemented in the corrected full-build harness.

```text
INDEPENDENT_FAIL_CLOSED_AUDIT=PASS
FULL_BUILD_RELEASE=PASS_ONE_NEW_CLEAN_BUILD_ONLY
```

This release authorizes only the one newly granted clean R1h-R2 build. It is
not evidence that synthesis, implementation, bitstream generation, source
publication, or hardware execution has passed.

## Exact identities

NETLIST/SOURCE-DERIVED FACT — independent read-only Git queries returned:

```text
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_SOURCE_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
R1H_SOURCE_WORKTREE_CLEAN=YES
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1E_MERGE_BASE=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
COMMITS_ABOVE_R1E=3
R1H_R2_TRACKED_DIFF_FROM_C4F4BFCF=0
```

FACT — the frozen public R1h evidence identities carried into this continuation
are:

```text
R1H_EVIDENCE_COMMIT=7dc8b8fb07033148e7c232c235da012d8b14b621
R1H_AUTHORITATIVE_REPORT_SHA256=E7B41C0DD5CF21499BE55D8C4019F07694B1255252AB7539A1A376E7839B6468
R1H_EVIDENCE_PACKAGE_SHA256=C56FE89CE24403FE7BD4702B53778BA4C2B5403536185BCC66EB32B8118CBC78
```

The exact P0 evidence verification remains an inherited prerequisite. This P5
audit did not redownload, rewrite, or republish it.

## Corrected harness identity

FACT — the task-local corrected full-build harness is outside the clean source
repository and has exact SHA-256:

```text
R1H_R2_BUILD_HARNESS_CORRECTION_MODE=TASK_LOCAL_ZERO_REPOSITORY_MUTATION
CORRECTED_BUILD_HARNESS_SHA256=5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F
ORIGINAL_R1H_BUILD_TCL_SHA256=2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18
R1H_R2_HARNESS_INDEPENDENT_AUDIT_SHA256=EA965F065BD35EEE281A8FD47446C4BB8BA6DC87A5CB84DABA06C9487E7A14C3
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
```

SOURCE-DERIVED FACT — the corrected harness still binds Vivado 2025.2 build
6299465, part `xc7a35tcsg325-2`, top `ahd_capture_top_xdma`, exact R1e/R1f/R1g
topology, and the frozen R1g build Tcl. The frozen R1g build Tcl was present and
rehash-matched:

```text
R1G_FROZEN_BUILD_TCL_SHA256=C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A
```

## Finalized manifest, sidecar, and verification receipt

FACT — all three finalized P5 outputs exist and were independently parsed and
rehash-verified:

| Artifact | SHA-256 |
|---|---|
| `R1H_R2_PREBUILD_MANIFEST.txt` | `9926A439A41967304202D77A669F2F6A8F976F3A239D9D602F2AD4D4857644A1` |
| `R1H_R2_PREBUILD_MANIFEST_SHA256.txt` | `02461A33605B106FED75AF5A9E8F9C89CE2319F232C49F515D93EC0AB81A75CA` |
| `R1H_R2_PREBUILD_MANIFEST_VERIFICATION.txt` | `5AEB06F677BF39591172ABB9195C25C6DF4849E5FE0707E5498407CD954C8637` |

FACT — the sidecar is exactly one line containing the manifest SHA followed by
`R1H_R2_PREBUILD_MANIFEST.txt`. The verification receipt is a unique-key
receipt and records `PASS`, exact commit/tree, a clean worktree, 224 source
records, 40 accepted logs, and zero consumed full builds.

FACT — strict grammar and shape checks passed:

```text
META_RECORDS=PASS_58_OF_58
SOURCE_SHA256_RECORDS=PASS_224_OF_224
ACCEPTED_LOG_SHA256_RECORDS=PASS_40_OF_40
DUPLICATE_META_KEYS=0
DUPLICATE_SOURCE_PATHS_CASE_INSENSITIVE=0
DUPLICATE_ACCEPTED_LOG_LABELS=0
UNKNOWN_MANIFEST_RECORD_TYPES=0
```

FACT — all 43 inherited R1h metadata keys retain their exact values except the
single authorized binding of `R1H_BUILD_TCL_SHA256` from the terminal R1h Tcl
to the corrected task-local Tcl. The following 15 continuation keys are all
present with exact expected values:

```text
R1H_R2_BUILD_HARNESS_CORRECTION_MODE=TASK_LOCAL_ZERO_REPOSITORY_MUTATION
R1H_R2_PROJECT_SETUP_DRY_RUN=PASS
R1H_R2_SEMANTIC_ELABORATION=PASS
R1H_R2_INDEPENDENT_AUDITS=PASS_P3_AND_P4
R1H_ORIGINAL_PREBUILD_MANIFEST_SHA256=192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79
R1H_SOURCE_MANIFEST_ROWS=224
R1H_SOURCE_MANIFEST_EQUAL_TO_C4F4BFCF=YES
R1H_RTL_BLOBS_UNCHANGED=YES
R1H_XDC_UNCHANGED=YES
R1H_XDMA_XCI_UNCHANGED=YES
R1H_REGISTER_MAP_UNCHANGED=YES
R1H_HOST_DECODERS_UNCHANGED=YES
R1H_STATISTICAL_PLAN_UNCHANGED=YES
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
```

## Exact source path and content proof

FACT — the 224 `SOURCE_SHA256` rows are byte-identical and in the same order as
the rows in the exact terminal R1h prebuild manifest, whose SHA-256 is
`192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79`.

FACT — the manifest path set equals the full current `git ls-files` set:

```text
TRACKED_PATHS=224
MANIFEST_SOURCE_PATHS=224
EXACT_PATH_SET_EQUALITY=PASS_224_OF_224
ACTUAL_SOURCE_SHA256=PASS_224_OF_224
MISSING_SOURCE_PATHS=0
EXTRA_SOURCE_PATHS=0
SOURCE_HASH_MISMATCHES=0
```

This exact all-tree proof includes 30 `rtl/` paths, all 8 tracked XDC files,
all 4 tracked XCI files, both `scripts/v41/read_nvp_*.py` host decoders, the
single `scripts/v41/r1f_statistics.py` statistical implementation, and all 44
tracked test paths. Therefore the narrower RTL/XDC/XCI/host/statistical
no-change gates are all subsumed by the exact 224-of-224 equality proof.

## Accepted-log proof

FACT — the exact terminal R1h manifest contains 32 accepted-log records. Every
one appears in the finalized R1h-R2 manifest with byte-identical label, path,
and expected digest. Eight continuation records are appended:

```text
R1H_R2_CORRECTED_BUILD_HARNESS
R1H_R2_HARNESS_AND_DRY_RUN_INDEPENDENT_AUDIT
R1H_R2_PROJECT_SETUP_DRY_RUN
R1H_R2_PROJECT_SETUP_DRY_RUN_INDEPENDENT_AUDIT
R1H_R2_SEMANTIC_PREFLIGHT_STATIC_INDEPENDENT_AUDIT
R1H_R2_SEMANTIC_ELABORATION
R1H_R2_SEMANTIC_ELABORATION_INDEPENDENT_AUDIT
R1H_R2_PREBUILD_GENERATOR
```

FACT — every referenced file exists and its current SHA-256 equals the recorded
digest:

```text
INHERITED_ACCEPTED_LOG_HASHES=PASS_32_OF_32
R1H_R2_ACCEPTED_LOG_HASHES=PASS_8_OF_8
ALL_ACCEPTED_LOG_HASHES=PASS_40_OF_40
```

## P3 and P4 receipts

FACT — the sole project-setup dry-run result rehashes to
`F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6`.
It contains 90 rows and 86 unique keys. Exactly the four documented identity
keys occur twice, each with multiplicity two and identical values; there are no
contradictory or unexpected duplicates. Its exact gates include:

```text
PROJECT_SETUP_DRY_RUNS=1
PROJECT_SETUP_DRY_RUN=PASS
PROJECT_SETUP_SEMANTIC_GATE=PASS
R1H_FALSE_ASSERTION_TRIGGERED=NO
RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO
COMPILE_ORDER_RECORDED=YES
DUPLICATE_DEFINITIONS=0
UNRESOLVED_INCLUDE_OR_PACKAGE_DEPENDENCIES=0
FAILED_RECORD_BRAM_BANK_COUNT=6
PROBE_INDEX_BRAM_INSTANCE_COUNT=3
PROCESS_EXIT_CODE=0
```

Its independent audit rehashes to
`3232F2FA10C6036C3D8D7F3F8E9A3CBC45BAEA4821B8F7A2739F14806F3C60AD`.

FACT — the sole semantic elaboration result rehashes to
`95A60F11432DA014AAF4B63989AFCF1FFD217139D8B979BB50CFD67EE1B1BDFD`.
It is a strict unique-key receipt and binds the exact 4 VHDL plus 17 production
SystemVerilog inputs, the accepted simulation-only XDMA stub, and these gates:

```text
SEMANTIC_ELABORATION_PREFLIGHTS=1
SEMANTIC_ELABORATION=PASS
R1H_TEST_ELABORATION=PASS
XVHDL_INVOCATIONS=1
XVLOG_INVOCATIONS=1
XELAB_INVOCATIONS=1
UNRESOLVED_MODULES=0
UNRESOLVED_BLACKBOXES=0
FAILED_RECORD_WRAPPER_BINDING=PASS
PROBE_INDEX_WRAPPER_BINDING=PASS
MMIO_READ_SERVICE_BINDING=PASS
SYNTHESIS_OR_IMPLEMENTATION_INVOCATIONS=0
PROCESS_EXIT_CODE=0
```

Its five bound-file digests (`xvhdl.log`, `xvlog.log`, `xelab.log`, semantic
input manifest, and duplicate-normalization audit) were independently
recomputed and matched. Its post-run independent audit rehashes to
`21775792D3BF9A56F3E190C4B7CAAB2B8537750951952394839FB6ECFA64E363`,
binds canonical runner SHA-256
`265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546`,
and reports `SOURCE_PRE_POST_HASH=PASS_23_OF_23` and `BLOCKERS=NONE`.

## Generator one-shot and read-only contract

FACT — the finalized generator rehashes to
`37475F9D80ACC3C01CCCFDCBEB71163919FB02CF78DD5863FFB60968BC104DCC`
and parses without PowerShell AST errors.

SOURCE-DERIVED FACT — independent static analysis established:

```text
POST_P4_FINALIZATION_SWITCH_REQUIRED=YES_EXACTLY_ONCE
EXISTING_OUTPUT_OVERWRITE_REFUSAL=YES_FOR_ALL_THREE_OUTPUTS
TEMPORARY_UNIQUE_OUTPUTS=YES
NON_OVERWRITING_ATOMIC_MOVES=3
VIVADO_OR_SIMULATOR_COMMANDS=0
SYNTHESIS_OR_IMPLEMENTATION_COMMANDS=0
HARDWARE_COMMANDS=0
GIT_MODE=READ_ONLY_ALLOWLIST
GIT_CALLS=5
GIT_SUBCOMMANDS=rev-parse,rev-parse,symbolic-ref,status,ls-files
GENERATOR_STATIC_CONTRACT=PASS_ONE_SHOT_READ_ONLY
```

The files `P5_PREBUILD_PREPARATION_STATUS.txt` and
`P5_PREBUILD_GENERATOR_STATIC_AUDIT.txt` intentionally describe the earlier
pre-finalization preparation state (`P5_PREBUILD_FINALIZED=NO`). They are not
final release receipts, are not substituted for the finalized manifest, and do
not contradict the later immutable manifest/sidecar/verification triplet. The
one-shot generator now refuses to overwrite that triplet.

## Corrected full-harness parser compatibility

SOURCE-DERIVED FACT — the exact corrected harness was independently inspected
against the finalized manifest contract. Its parser will:

1. rehash the manifest against the uppercase sidecar digest;
2. reject malformed, duplicate, missing, or hash-mismatched source/log rows;
3. require exact source commit, tree, and its own Tcl SHA-256;
4. require all inherited scientific metadata;
5. rehash each required source and every accepted log;
6. perform all checks before consuming the one-build sentinel.

The finalized manifest satisfies its complete current input set:

```text
HARNESS_REQUIRED_META=PASS_43_OF_43
HARNESS_REQUIRED_SOURCES=PASS_58_OF_58
HARNESS_REQUIRED_ACCEPTED_LOG_LABELS=PASS_27_OF_27
ALL_MANIFEST_ACCEPTED_LOG_HASHES=PASS_40_OF_40
CORRECTED_HARNESS_SELF_HASH_BINDING=PASS
FROZEN_R1G_TCL_HASH_BINDING=PASS
```

The 58 required source paths are the exact union of the full-build source,
constraint, XCI and helper inputs with the 38 paths changed from exact R1e to
exact R1h. Every one is present in the exact 224-row source manifest and
rehash-matched.

## Authorization accounting and release boundary

FACT — immediately before this report was written:

```text
R1H_R2_FULL_BUILD_ROOT_EXISTS=NO
R1H_R2_FULL_BUILD_EVIDENCE_ROOT_EXISTS=NO
R1H_R2_FULL_BUILD_CONSUMED_SENTINELS=0
FULL_CLEAN_BUILDS_CONSUMED=0
VIVADO_INVOCATIONS_DURING_THIS_AUDIT=0
SOURCE_MUTATIONS_DURING_THIS_AUDIT=0
GIT_MUTATIONS_DURING_THIS_AUDIT=0
LEDGER_MUTATIONS_DURING_THIS_AUDIT=0
HARDWARE_ACTIONS_DURING_THIS_AUDIT=0
```

Two local checker-development attempts produced no evidence artifact: the
first failed PowerShell parsing before execution; the second entered recursion
because its helper name shadowed `git.exe` and was terminated. Neither launched
Git, Vivado, a simulator, a build, or any write. The corrected independent
checker then completed the full audit above. These checker-development events
did not consume any prompt-limited gate.

## Final release block

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
AUDIT=R1H_R2_INDEPENDENT_PREBUILD_RELEASE_AUDIT
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_SOURCE_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
R1H_SOURCE_WORKTREE_CLEAN=YES
VIVADO_EXPECTED_VERSION=2025.2
VIVADO_EXPECTED_SW_BUILD=6299465
CORRECTED_BUILD_HARNESS_SHA256=5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F
R1H_R2_PREBUILD_MANIFEST_SHA256=9926A439A41967304202D77A669F2F6A8F976F3A239D9D602F2AD4D4857644A1
PREBUILD_MANIFEST_VERIFICATION=PASS
SOURCE_PATH_SET=PASS_224_OF_224
SOURCE_HASHES=PASS_224_OF_224
INHERITED_ACCEPTED_LOGS=PASS_32_OF_32
R1H_R2_ACCEPTED_LOGS=PASS_8_OF_8
ALL_ACCEPTED_LOGS=PASS_40_OF_40
PROJECT_SETUP_DRY_RUNS=1
PROJECT_SETUP_DRY_RUN=PASS
SEMANTIC_ELABORATION_PREFLIGHTS=1
SEMANTIC_ELABORATION=PASS
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
FULL_CLEAN_BUILDS_CONSUMED=0
BLOCKERS=NONE
FULL_BUILD_RELEASE=PASS_ONE_NEW_CLEAN_BUILD_ONLY
NEXT_ACTION=CONSUME_EXACTLY_ONE_NEW_CLEAN_BUILD_WITH_THE_CORRECTED_TASK_LOCAL_HARNESS
```
