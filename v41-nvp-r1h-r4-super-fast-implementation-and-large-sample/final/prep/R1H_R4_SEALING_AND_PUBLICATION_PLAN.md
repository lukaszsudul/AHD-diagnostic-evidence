# R1h-R4 deterministic sealing and publication plan

Status: `PREPARED_NOT_AUTHORIZED_TO_EXECUTE`

No package, manifest, evidence commit or repository mutation was created by
this preparation phase.

## Frozen locations and names

```text
TASK_ROOT=C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST
EVIDENCE_REPOSITORY=C:\FPGA\EVIDENCE_WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1
EVIDENCE_REMOTE=https://github.com/lukaszsudul/AHD-diagnostic-evidence.git
EVIDENCE_TARGET=v41-nvp-r1h-r4-super-fast-implementation-and-large-sample

AUTHORITATIVE_REPORT=final/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md
INDEPENDENT_FINAL_AUDIT=final/R1H_R4_INDEPENDENT_FINAL_AUDIT.md
ANALYSIS_RELEASE=final/R1H_R4_ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE.txt

MANIFEST=SHA256_MANIFEST.txt
ZIP=V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE.zip
SIDECAR=V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE_SHA256.txt
```

## Read-only repository baseline

Observed during preparation:

```text
BRANCH=main
LOCAL_HEAD=11d46c817ceaea79027886cd6199815a6a3ff0cb
LOCAL_TREE=968c7b89bdfa03f2eb5592393705c4851d4114f3
REMOTE_MAIN=11d46c817ceaea79027886cd6199815a6a3ff0cb
WORKTREE_CLEAN=YES
TARGET_COLLISION=NO
GIT_LFS_AVAILABLE=YES
```

The base is not frozen indefinitely. Immediately before staging, re-run
`ls-remote`; local HEAD and remote `main` must still equal the explicitly
authorized base. A remote change requires a fresh read-only reconciliation,
never force-push.

## Required LFS attributes

The target path currently has no matching LFS rules. Before `git add`, append
exactly these lines to the repository root `.gitattributes` in the same single
publication commit:

```gitattributes
v41-nvp-r1h-r4-super-fast-implementation-and-large-sample/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE.zip filter=lfs diff=lfs merge=lfs -text
v41-nvp-r1h-r4-super-fast-implementation-and-large-sample/**/*.dcp filter=lfs diff=lfs merge=lfs -text
v41-nvp-r1h-r4-super-fast-implementation-and-large-sample/**/*.bit filter=lfs diff=lfs merge=lfs -text
```

Before commit, `git check-attr filter` must return `lfs` and each staged large
artifact must be an LFS pointer beginning with the Git LFS specification line.
The working-tree file and LFS object SHA-256/size must still equal the sealed
task-root artifact.

## Release prerequisites

Sealing is permitted only after all of these exist and are hash-frozen:

1. Analysis/campaign audit release containing
   `ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE=PASS`.
2. Authoritative report with the exact required terminal block.
3. Independent final report audit `PASS`.
4. Exact final FormalReady restoration evidence.
5. Operation and time ledgers frozen.
6. No active hardware, Vivado or evidence-publication writer.
7. Read-only safety audit: zero reparse points, ADS, unsafe paths,
   casefold collisions, sensitive filenames and high-confidence secrets.

## Report/package/publication circularity rule

The report is an input to the package and the package is an input to the
evidence commit. Therefore the report must not be rewritten after sealing.
Use these approved noncircular sentinels in the immutable report terminal block:

```text
EVIDENCE_PACKAGE_SHA256=SEE_EXTERNAL_PACKAGE_SHA256_SIDECAR_NONCIRCULAR
EVIDENCE_REPOSITORY_COMMIT=SEE_EXTERNAL_PUBLICATION_RECEIPT_NONCIRCULAR
PUBLICATION_RESULT=SEE_EXTERNAL_PUBLICATION_RECEIPT_NONCIRCULAR
```

The actual package digest is authoritative in the sidecar and publication
receipt. The actual evidence commit/publication result is authoritative in the
post-commit remote-verification receipt. This is not an unavailable identity;
it is an explicit noncircular reference.

## Deterministic sealing algorithm

1. Pass the three exact release/report/audit SHA-256 values to
   `Seal-R1hR4EvidenceAfterRelease.ps1`.
2. Enumerate every task-root file except the not-yet-created manifest, ZIP and
   sidecar. Sort paths using ordinal comparison and normalize separators to `/`.
3. Reject root escapes, absolute/traversal/reserved/overlong paths, reparse
   points, non-default ADS, hidden/system files, casefold collisions,
   sensitive filenames and high-confidence secret signatures.
4. Record `SHA256|SIZE_BYTES|TASK_ROOT_RELATIVE_PATH` for every input.
5. Rehash/re-size all inputs immediately before writing outputs to detect
   concurrent mutation.
6. Create a ZIP with ordinal entry order, no directory-only entries and fixed
   UTC entry timestamp `2000-01-01T00:00:00Z`.
7. Add the manifest to the ZIP as a noncircular self entry; the manifest does
   not contain its own digest.
8. Stream-verify every ZIP entry name, size and SHA-256 against the input set.
9. Create the external ZIP SHA-256 sidecar. ZIP and sidecar are not ZIP inputs.
10. Rehash the report/audit/release and ZIP after sidecar creation.

No second sealing attempt may overwrite outputs. Any failure preserves the
unsealed inputs and requires fail-closed audit, not deletion or replacement.

## Normal publication algorithm

1. Require exact sealed ZIP/manifest/sidecar and analysis-release hashes.
2. Reconfirm clean local `main`, exact origin, local/remote base equality and
   target-path absence, including case-insensitive collision checks.
3. Copy the sealed task root once into the exact evidence target.
4. Add the three LFS rules above.
5. Stage only `.gitattributes` and the exact target directory.
6. Re-run secret/path/staged-set/LFS-pointer checks.
7. Create one commit with message:
   `Publish R1h-R4 super-fast implementation and large-sample evidence`.
8. Push normally with `git push origin HEAD:main`; no force, tag or Release.
9. Verify `ls-remote` equals the created commit and verify the public target,
   manifest, ZIP LFS object and sidecar.
10. Write a task-local publication receipt containing the actual commit,
    remote verification and package digest. Do not amend the published report
    or rerun hardware.

Publication failure does not alter the scientific result. Preserve the sealed
local package and record the exact blocker.

## Prepared tooling

```text
final/prep/Test-R1hR4EvidencePreflightReadOnly.ps1
final/prep/Test-R1hR4FinalReport.ps1
final/prep/Seal-R1hR4EvidenceAfterRelease.ps1
final/prep/Publish-R1hR4EvidenceAfterRelease.ps1
```

The sealing and publication scripts have not been executed.
