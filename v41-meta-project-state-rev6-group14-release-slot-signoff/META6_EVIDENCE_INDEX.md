# META-6 Evidence Index

## Authorities

- Frozen SSOT start revision: `5`.
- G14-A evidence commit:
  `9e91315968453e859006077191cd5fc711fc6b96`.
- G14-A evidence directory:
  `v41-development-g2b-g14a-release-slot0-signoff-audit`.
- Successful META-5 precedent:
  `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314`.
- Successful META-4R2 precedent:
  `27dcf152e862c6db88a365328b92c0fd250f04c2`.
- Resulting SSOT revision: `6`.

## Published META-6 package

1. `META6_SSOT_UPDATE_REPORT.md`
2. `META6_WRITE_CONTRACT_RECEIPT.md`
3. `META6_GROUP14_DECISION.md`
4. `META6_GROUP14_SIGNOFF_PROMOTION.md`
5. `META6_EXPECTED_AFFECTED_FILES.md`
6. `META6_EXACT_FILE_CHANGE_LEDGER.md`
7. `META6_PROJECT_STATE_DIFF.md`
8. `META6_EVIDENCE_INDEX.md`
9. `META6_STATE.json`
10. `META6_SHA256_MANIFEST.txt`

The updated `project-current-state/` tree remains the authoritative SSOT; it
is not duplicated inside this package.

## Integrity and read-back boundary

`META6_SHA256_MANIFEST.txt` hashes the other nine package files. The SSOT's
own `SHA256_MANIFEST.txt` hashes all 18 non-self files in
`project-current-state/`.

Publication is one ordinary fast-forward commit on `main` with subject:

`Promote AHD v41 Group 14 release-slot sign-off method to project state rev6`

After push, the executor must freshly read back and verify all 19 SSOT files
and all 10 META-6 package files (`29` total). The containing commit SHA,
remote-HEAD equality, and completed read-back result are post-commit execution
facts and are therefore reported by the executor rather than invented inside
the commit.
