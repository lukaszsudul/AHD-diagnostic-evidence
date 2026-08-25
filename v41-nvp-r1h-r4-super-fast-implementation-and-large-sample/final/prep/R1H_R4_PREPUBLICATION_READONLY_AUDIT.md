# R1h-R4 read-only evidence/publication preflight

```text
READ_ONLY_PREPUBLICATION_AUDIT=PASS_PREP_STAGE
AUDIT_UTC=2026-08-25T15:56:57.1956613Z

TASK_TREE_FILES=327
TASK_TREE_DIRECTORIES=24
TASK_TREE_BYTES=141669483
MAX_RELATIVE_PATH_LENGTH=77

REPARSE_POINTS=0
NONDEFAULT_ADS=0
UNSAFE_PATHS=0
OVERLONG_PATHS=0
CASEFOLD_COLLISION_GROUPS=0
SENSITIVE_FILENAMES=0
SECRET_SIGNATURE_CLASSES=12
HIGH_CONFIDENCE_SECRET_HITS=0

AUTHORITATIVE_REPORT_EXISTS=FALSE
ANALYSIS_RELEASE_EXISTS=FALSE
SEAL_OUTPUTS_EXIST=FALSE
READY_TO_SEAL=FALSE

EVIDENCE_REPO_HEAD=11d46c817ceaea79027886cd6199815a6a3ff0cb
EVIDENCE_REPO_TREE=968c7b89bdfa03f2eb5592393705c4851d4114f3
EVIDENCE_REPO_REMOTE_MAIN=11d46c817ceaea79027886cd6199815a6a3ff0cb
EVIDENCE_REPO_REMOTE=https://github.com/lukaszsudul/AHD-diagnostic-evidence.git
EVIDENCE_REPO_CLEAN=YES
EVIDENCE_TARGET_COLLISION=NO
EVIDENCE_TARGET_DIRECTORY=v41-nvp-r1h-r4-super-fast-implementation-and-large-sample

GIT_LFS_VERSION=git-lfs/3.7.1
CURRENT_ZIP_FILTER=unspecified
CURRENT_SYNTH_DCP_FILTER=unspecified
CURRENT_ROUTED_DCP_FILTER=unspecified
CURRENT_BIT_FILTER=unspecified
LFS_ATTRIBUTE_UPDATE_REQUIRED=TRUE

POWERSHELL_TOOL_COUNT=4
POWERSHELL_TOTAL_PARSE_ERRORS=0
REPOSITORY_MUTATIONS=0
PACKAGE_CREATED=NO
PUBLICATION_PERFORMED=NO
```

`READY_TO_SEAL=FALSE` is the expected preparation-stage classification, not a
scientific or hardware blocker. At the snapshot time the authoritative report
and root-issued analysis/campaign release had not yet been created. Sealing is
forbidden until both exist and pass independent audit.

The only repository preparation delta required before staging is the exact
three-line LFS addition documented in
`R1H_R4_SEALING_AND_PUBLICATION_PLAN.md`. It must cover the evidence ZIP, all
target DCPs and the diagnostic bit. The target path is currently collision-free.

No secret-bearing credential file was read. The scan was bounded to the R4
task tree and used high-confidence signature classes with zero hits.
