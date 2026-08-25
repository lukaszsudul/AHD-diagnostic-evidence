# R1h-R2 terminal-evidence publication preflight

## Scope and classification

This is a read-only publication preflight for:

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
EXPERIMENT_NAME=R1h
CONTINUATION_REVISION=R2
DESTINATION_REPOSITORY=lukaszsudul/AHD-diagnostic-evidence
DESTINATION_BRANCH=main
DESTINATION_PATH=v41-nvp-r1h-r2-build-harness-continuation-and-large-sample
PREFLIGHT_CLASSIFICATION=PASS_WITH_REQUIRED_GITATTRIBUTES_DELTA_AND_MANDATORY_TERMINAL_RESCAN
COPY_STAGE_COMMIT_PUSH_PERFORMED=NO
```

No file was copied to the evidence repository. Nothing was staged, committed,
or pushed. The only mutation made by this preflight is this task-local report.

The R1h-R2 terminal outcome bound by this preflight is:

```text
R1H_R2_TERMINAL_CLASSIFICATION=BLOCKED_R1H_R2_POST_SYNTH_RESOURCE_OR_MAPPING_GATE
CAUSE_DISAMBIGUATION=POST_SYNTH_RESOURCE_MARGIN_GATE_FAIL_LUT_ONLY
POST_SYNTH_SLICE_LUTS=19255
POST_SYNTH_SLICE_LUTS_LIMIT=18720
POST_SYNTH_SLICE_LUTS_EXCESS=535
POST_SYNTH_MEMORY_MAPPING_GATE=PASS
PLACE=NOT_RUN
ROUTE=NOT_RUN
BITSTREAM=NOT_GENERATED
HARDWARE_ACTIONS=0
```

The current authoritative report was intentionally frozen after a two-field
evidence-alignment correction:

```text
AUTHORITATIVE_REPORT_PATH=16_FINAL/R1H_R2_AUTHORITATIVE_FINAL_REPORT.md
AUTHORITATIVE_REPORT_SHA256=35FE8A9578D1CAE4A78187E76C0B80F6E7EE20E43BE0FBBBABEAE5FDFF297919
AUTHORITATIVE_REPORT_BYTES=20499
STALE_PRECORRECTION_SHA256=D465E647D57223BECDA72C167AC80535705EFE151052B7CE7E0BA37ED7FEE142
STALE_PRECORRECTION_SHA256_MUST_NOT_BE_PUBLISHED=YES
```

## Destination repository evidence

FACT — the existing publication worktree is:

```text
LOCAL_EVIDENCE_WORKTREE=C:/FPGA/EVIDENCE_WORKTREES/V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1
REMOTE_ORIGIN=https://github.com/lukaszsudul/AHD-diagnostic-evidence.git
BRANCH=main
UPSTREAM=origin/main
LOCAL_HEAD=7dc8b8fb07033148e7c232c235da012d8b14b621
LOCAL_HEAD_TREE=b6fa4e04471f47211ef70206f90adf45cb012d9b
LOCAL_REFS_HEADS_MAIN=7dc8b8fb07033148e7c232c235da012d8b14b621
LOCAL_ORIGIN_MAIN=7dc8b8fb07033148e7c232c235da012d8b14b621
PUBLIC_MAIN=7dc8b8fb07033148e7c232c235da012d8b14b621
PUBLIC_HEAD_SYMBOLIC_REF=refs/heads/main
WORKTREE_STATUS_PORCELAIN_ROWS=0
HEAD_VS_ORIGIN_MAIN_LEFT_RIGHT=0/0
HEAD_VS_PUBLIC_MAIN_LEFT_RIGHT=0/0
```

NETLIST-INDEPENDENT GIT FACT — `git ls-remote` proved that public `main` and
public `HEAD` both resolve to exact prior R1h evidence commit
`7dc8b8fb07033148e7c232c235da012d8b14b621`. The GitHub commit API independently
returned tree `b6fa4e04471f47211ef70206f90adf45cb012d9b` and parent
`31786f351a9b8aab86291b5058ce075da5fba46a`.

FACT — destination collision checks:

```text
NEW_PATH_TRACKED_ROWS=0
NEW_PATH_EXACT_TOP_LEVEL_MATCH=0
NEW_PATH_CASE_INSENSITIVE_TOP_LEVEL_MATCH=0
DESTINATION_TOP_LEVEL_CASEFOLD_COLLISION_GROUPS=0
DESTINATION_TRACKED_FILE_CASEFOLD_COLLISION_GROUPS=0
PRIOR_R1H_PATH_TRACKED_FILE_ROWS=1802
PUBLIC_RECURSIVE_TREE_TRUNCATED=FALSE
```

The requested R1h-R2 directory is therefore absent both exactly and under a
case-insensitive comparison. It can be added without overwriting prior evidence.

## Git LFS audit and required delta

FACT:

```text
GIT_VERSION=2.53.0.windows.3
GIT_LFS_VERSION=3.7.1
CORE_LONGPATHS=true
CURRENT_LFS_TRACKED_FILE_COUNT=33
GITATTRIBUTES_BLOB_SHA=853dd65aba607148143366eb9fd790239176b1f1
GITATTRIBUTES_SIZE_BYTES=1622
GITATTRIBUTES_LINES=14
```

The exact prior R1h ZIP is stored as a valid Git LFS pointer. Its LFS object is
`10310254` bytes with object ID
`c56fe89ce24403fe7bd4702b53778ba4c2b5403536185bcc66eb32b8118cbc78`,
which matches the authoritative R1h package SHA-256.

FACT — current `.gitattributes` correctly gives the prior R1h ZIP, `**/*.dcp`,
and `**/*.vcd` paths `filter=lfs diff=lfs merge=lfs -text`. The corresponding
hypothetical R1h-R2 paths currently resolve to:

```text
filter=unspecified
diff=unspecified
merge=unspecified
text=unset
```

Therefore publication must append exactly these three path-scoped rules before
staging any R1h-R2 payload:

```gitattributes
v41-nvp-r1h-r2-build-harness-continuation-and-large-sample/V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION_AND_LARGE_SAMPLE_EVIDENCE.zip filter=lfs diff=lfs merge=lfs -text
v41-nvp-r1h-r2-build-harness-continuation-and-large-sample/**/*.vcd filter=lfs diff=lfs merge=lfs -text
v41-nvp-r1h-r2-build-harness-continuation-and-large-sample/**/*.dcp filter=lfs diff=lfs merge=lfs -text
```

These rules are required even though the current synthesis checkpoint is below
GitHub's 50,000,000-byte warning threshold. They preserve the repository's
established policy for opaque FPGA checkpoints and any VCD evidence, and they
protect the final ZIP whose sealed size is not yet known.

Current directly publishable large binary:

```text
PATH=06_BUILD/FULL_BUILD/R1H_synth.dcp
SIZE_BYTES=46972058
SHA256=807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E
LFS_REQUIRED_BY_REPOSITORY_POLICY=YES
```

No routed DCP or bitstream exists because the hard stop occurred after the
post-synthesis resource gate.

## Task-root safety snapshot

The scan snapshot was taken at `2026-08-25T09:17:51.7502512Z`, before this
report was added. The task tree was still awaiting the independent terminal
sealing audit; consequently all safety and count checks below must be rerun once
after the last authorized report is frozen and before manifest generation.

FACT:

```text
TASK_FILES_BEFORE_THIS_REPORT=141
TASK_DIRECTORIES=25
TASK_TOTAL_BYTES_BEFORE_THIS_REPORT=57981631
MAX_FILE_BYTES=46972058
FILES_AT_OR_ABOVE_50000000_BYTES=0
FILES_AT_OR_ABOVE_100000000_BYTES=0
FILES_AT_OR_ABOVE_2_GIB=0
REPARSE_POINTS=0
NONDEFAULT_ALTERNATE_DATA_STREAMS=0
CASEFOLD_PATH_COLLISION_GROUPS=0
UNSAFE_OR_RESERVED_PATH_ROWS=0
MAX_TASK_ABSOLUTE_PATH_CHARS=134
MAX_TASK_RELATIVE_PATH_CHARS=84
MAX_PROJECTED_EVIDENCE_WORKTREE_PATH_CHARS=208
TASK_ABSOLUTE_PATHS_OVER_240=0
TASK_ABSOLUTE_PATHS_OVER_259=0
PROJECTED_EVIDENCE_PATHS_OVER_240=0
PROJECTED_EVIDENCE_PATHS_OVER_259=0
```

Secret scan FACT:

```text
TEXT_FILES_SCANNED=93
HIGH_CONFIDENCE_TEXT_SECRET_HITS=0
ALL_FILE_BYTE_SIGNATURE_PATTERNS=8
ALL_FILE_BYTE_SIGNATURE_HITS=0
SENSITIVE_FILENAME_CANDIDATES=0
```

The byte-signature scan covered all files, including the DCP, for private-key
headers, GitHub classic/fine-grained tokens, OpenAI keys, AWS access IDs, Slack
tokens, bearer authorization headers, and URLs containing inline credentials.
Only filenames/pattern identifiers—not candidate secret values—were eligible
for reporting.

SOURCE-DERIVED LIMITATION — this is a point-in-time preflight, not the terminal
secret-scan receipt. Any later file invalidates the counts above. The terminal
seal must repeat the complete scan over the final manifest input set.

## Exact recommended sealing procedure

All operations below are recommendations for the authorized root task. None was
executed by this preflight.

1. Finish the independent final-report audit. Rehash the authoritative report
   and require exact SHA-256
   `35FE8A9578D1CAE4A78187E76C0B80F6E7EE20E43BE0FBBBABEAE5FDFF297919`.
   Reject the stale `D465E647...` value everywhere.
2. Freeze all ledgers and terminal audit files. After this point, permit only
   the manifest, ZIP, ZIP sidecar, and external publication receipt to be
   created.
3. Rerun the reparse, alternate-data-stream, case-fold collision, unsafe-name,
   path-length, per-file-size, sensitive-filename, text-secret, and all-file
   byte-signature scans over the final task root. Fail closed on any nonzero
   unsafe result. Record the final counts and the scan script/hash.
4. Require these three output paths to be absent before sealing:

   ```text
   SHA256_MANIFEST.txt
   V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION_AND_LARGE_SAMPLE_EVIDENCE.zip
   V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION_AND_LARGE_SAMPLE_EVIDENCE_SHA256.txt
   ```

5. Enumerate every regular, non-reparse task-root file except those three
   outputs. Sort by task-root-relative path using ordinal comparison. Normalize
   separators to `/`. Create `SHA256_MANIFEST.txt` with exactly:

   ```text
   FORMAT=SHA256|SIZE_BYTES|TASK_ROOT_RELATIVE_PATH
   UPPERCASE_SHA256|DECIMAL_BYTE_COUNT|relative/path
   ```

   The manifest intentionally does not hash itself; it is included once in the
   ZIP as the non-circular self-manifest. The ZIP and its sidecar are excluded
   from both the manifest rows and ZIP inputs.
6. Rehash every manifest row directly from disk and require exact size/hash
   agreement before creating the archive.
7. Create the ZIP with every manifest-listed file plus
   `SHA256_MANIFEST.txt`, each exactly once and with task-root-relative `/`
   entry names. Do not add directory-only entries. Require:

   ```text
   ZIP_ENTRY_COUNT=MANIFEST_ROW_COUNT+1
   ZIP_DUPLICATE_ENTRY_COUNT=0
   ZIP_CASEFOLD_COLLISION_COUNT=0
   ZIP_ABSOLUTE_OR_TRAVERSAL_ENTRY_COUNT=0
   ZIP_UNLISTED_FILE_COUNT=0
   ZIP_MISSING_FILE_COUNT=0
   ```

8. Stream every ZIP entry and verify its uncompressed size and SHA-256 against
   the manifest; separately verify that the archived manifest is byte-identical
   to the on-disk manifest.
9. Hash the completed ZIP and create the sidecar with these exact fields:

   ```text
   SHA256=<uppercase SHA-256>
   BYTES=<decimal ZIP bytes>
   FILE=V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION_AND_LARGE_SAMPLE_EVIDENCE.zip
   MANIFEST_ROWS=<exact data-row count>
   ZIP_ENTRIES=<MANIFEST_ROWS+1>
   MANIFEST_SELF=INCLUDED_NONCIRCULAR
   ZIP_AND_SIDECAR=EXCLUDED_FROM_MANIFEST_AND_ZIP_INPUTS
   ```

10. Verify the complete on-disk package once more without changing it. Record
    package SHA, manifest row count, ZIP entry count, secret scan, reparse scan,
    and task-root inventory in the terminal sealing audit.

## Exact recommended publication procedure

1. Immediately before any repository mutation, rerun `git ls-remote` and
   require public `refs/heads/main` to remain
   `7dc8b8fb07033148e7c232c235da012d8b14b621`. Require local `HEAD`, local
   `main`, and `origin/main` to match; require status row count zero and
   divergence `0/0`. If public `main` moved, stop and reconcile read-only—do not
   force or overwrite.
2. Require the new destination path to remain absent under exact and
   case-insensitive comparison.
3. Append only the three `.gitattributes` rules specified above. Do not broaden
   them to unrelated paths.
4. Copy the sealed task-root contents into exactly
   `v41-nvp-r1h-r2-build-harness-continuation-and-large-sample/`. This future
   publication copy must include the manifest, ZIP, and ZIP sidecar. Preserve
   bytes; then rehash every copied file against the source task root.
5. Before staging, require `git check-attr filter diff merge text` to report
   `lfs/lfs/lfs/unset` for the exact ZIP and every `*.dcp`/`*.vcd` below the
   new path.
6. Stage only `.gitattributes` and the one new directory. Inspect the exact
   staged name list and `.gitattributes` patch; reject any deletion, rename, or
   unrelated path.
7. Require `git lfs ls-files --name-only` to contain the exact ZIP and every
   new DCP/VCD. Inspect each corresponding staged blob and require a valid
   three-line Git LFS pointer whose object ID equals the working-file SHA-256
   and whose size equals the working-file byte count. This is mandatory for
   `06_BUILD/FULL_BUILD/R1H_synth.dcp` and the final ZIP.
8. Create one normal evidence commit. Do not amend, rebase, force-push, tag, or
   create a Release. Push `main` normally to `origin` once.
9. Verify public `refs/heads/main` equals the new evidence commit. Query the
   public recursive tree and require it not truncated, require the exact new
   path/file count, and verify all ordinary Git blobs. Download every LFS-backed
   object through the public endpoint—not merely its pointer—and rehash it.
10. In a fresh read-only verification directory, verify the public ZIP SHA,
    sidecar, complete manifest, ZIP entry count, every ZIP entry hash/size,
    secret scan, and authoritative report SHA. Require the public report to hash
    to `35FE8A9578D1CAE4A78187E76C0B80F6E7EE20E43BE0FBBBABEAE5FDFF297919`.
11. Create the external publication receipt only after the push and public
    verification, because the new evidence commit hash cannot be embedded in
    the commit that creates it. The receipt must record the evidence commit,
    package SHA, report SHA, public verification result, and zero force-push/tag/
    Release operations. Keep it external to the already sealed non-circular
    package.

## Final preflight result

```text
EVIDENCE_REPOSITORY_IDENTITY=PASS
LOCAL_MAIN_EQUALS_PRIOR_R1H_EVIDENCE_COMMIT=PASS
PUBLIC_MAIN_EQUALS_PRIOR_R1H_EVIDENCE_COMMIT=PASS
LOCAL_WORKTREE_CLEAN=PASS
LOCAL_REMOTE_DIVERGENCE=0/0
NEW_DESTINATION_PATH_ABSENT=PASS
NEW_DESTINATION_CASE_COLLISION=0
GIT_LFS_TOOL_AVAILABLE=PASS
CURRENT_NEW_PATH_LFS_ATTRIBUTES=FAIL_EXPECTED_NOT_YET_DECLARED
REQUIRED_GITATTRIBUTES_DELTA=THREE_EXACT_PATH_SCOPED_LINES
TASK_ROOT_POINT_IN_TIME_REPARSE_SCAN=PASS
TASK_ROOT_POINT_IN_TIME_CASE_SCAN=PASS
TASK_ROOT_POINT_IN_TIME_PATH_SIZE_SCAN=PASS
TASK_ROOT_POINT_IN_TIME_SECRET_SCAN=PASS
TERMINAL_RESCAN_REQUIRED=YES
PUBLICATION_RELEASE=PASS_ONLY_AFTER_TERMINAL_RESCAN_AND_LFS_ATTRIBUTE_GATE
COPY_STAGE_COMMIT_PUSH_PERFORMED=NO
```
