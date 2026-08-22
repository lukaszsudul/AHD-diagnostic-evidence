# R1b evidence closure checklist

## Required inclusions

- [x] Scope/authorization transcript with explicit non-verbatim limitation.
- [x] Immutable prior-R1 identity and result record.
- [x] Exact diagnostic/formal artifact identities and no-build proof.
- [x] Observer design, static audit, fixtures, preflight, and historical replay.
- [x] Pre-program manifest and formal start-state proof.
- [x] Complete raw Arm-A program transcript and both offline recovery records.
- [x] Arm-A reboot submission/monitor and post-reboot compatibility evidence.
- [x] Arm-A infrastructure classification.
- [x] Complete formal-restoration transcript and independent final DONE log/journal.
- [x] Formal-restoration and paired-A/B classifications.
- [x] Operation ledger, time ledger, CSV comparison, and final Markdown report.
- [ ] Final task-root SHA-256 manifest created after all report files are frozen.
- [ ] Measurement-evidence ZIP created without self-inclusion.
- [ ] ZIP entry count, duplicate-name check, per-entry hashes, and integrity report PASS.
- [ ] External ZIP SHA-256 sidecar created.
- [ ] Normal evidence commit/push completed, if the fast-forward gate passes.
- [ ] Local post-publication receipt created outside the sealed ZIP.

## Mandatory exclusions and security gates

```text
CREDENTIAL_FILE_PUBLISHED=NO
CREDENTIAL_HELPER_SOURCE_PUBLISHED=NO
TEMP_PASSWORD_FILE_PUBLISHED=NO
PRIVATE_KEY_MARKER_SCAN=PASS
INFERABLE_CREDENTIAL_PATTERN_SCAN=PASS
PLINK_PW_OPTION_USED=NO
PLINK_PWFILE_OPTION_USED=YES
PWFILE_CREATED=YES
PWFILE_DELETED=YES
```

Exclude the credential file, `pw-*.tmp`, the external contextual credential
helper source, private keys, `.git`, worktrees, transient Vivado state,
standalone `.bit`/`.dcp`, and any duplicate R1 build package. Sanitized logs,
the task-local `Invoke-R1BReadOnlyPayload.ps1`, and credential-helper identity
hashes may be included only after the scans above pass.

## LFS and package policy

R1b created no build artifact. Do not copy the existing 88,970,399-byte R1
build package into the R1b path or nest it in the measurement ZIP. Reference
the already-published exact-path LFS object:

```text
R1_BUILD_PACKAGE_OID_SHA256=918e0972f94cef0d21d87a4d92177b9db69ff9558f6ba3217571fe68d41cca3a
R1_BUILD_PACKAGE_SIZE=88970399
R1_BUILD_PACKAGE_PATH=v41-nvp-i2c-25khz-paired-ab-r1/packages/V41_NVP_I2C_25KHZ_PAIRED_AB_R1_BUILD_PACKAGE.zip
```

The R1b measurement ZIP should remain ordinary Git content unless its own
final size independently requires an exact-path LFS rule. Do not add a generic
LFS pattern.

## Publication gate

Preferred new path:

```text
v41-nvp-i2c-25khz-paired-ab-r1b/
```

The last read-only local audit found a clean `main` at
`5a81f5b115dddcdddd809a655fced115e113585e`, with cached `origin/main` equal.
Commit `f711325fab4e993bfaf1881626d23c2dac20c8af` is its direct parent and the
new R1b path was absent.

Before publication:

1. Fetch once and require both `f711325...` and `5a81f5b...` to remain
   ancestors of `origin/main`.
2. Require a clean fast-forward base; never force-push.
3. Require the destination path to remain absent or exactly known.
4. Stage only the new R1b path. `.gitattributes` should remain unchanged.
5. Prove zero staged changes under the immutable R1 evidence path.
6. Commit once and push once normally. A non-fast-forward rejection is a hard
   stop, not permission to retry unsafely.
7. Record the resulting commit and package SHA in a local receipt outside the
   ZIP. Do not rewrite the self-contained final report to embed its own package
   hash or evidence commit.
