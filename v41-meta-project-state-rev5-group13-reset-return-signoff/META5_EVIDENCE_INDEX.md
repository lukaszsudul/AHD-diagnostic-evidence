# META-5 Evidence Index

## Authorities

- Frozen SSOT start revision: `4`.
- G13-A evidence commit:
  `10c7c2898d162af8e2262b3f99861c7d560c4557`.
- G13-A evidence directory:
  `v41-development-g2b-g13a-reset-return-signoff-audit`.
- Successful META-4R2 precedent:
  `27dcf152e862c6db88a365328b92c0fd250f04c2`.
- Resulting SSOT revision: `5`.

## Published META-5 package

1. `META5_SSOT_UPDATE_REPORT.md`
2. `META5_WRITE_CONTRACT_RECEIPT.md`
3. `META5_GROUP13_DECISION.md`
4. `META5_GROUP13_SIGNOFF_PROMOTION.md`
5. `META5_EXPECTED_AFFECTED_FILES.md`
6. `META5_EXACT_FILE_CHANGE_LEDGER.md`
7. `META5_PROJECT_STATE_DIFF.md`
8. `META5_EVIDENCE_INDEX.md`
9. `META5_STATE.json`
10. `META5_SHA256_MANIFEST.txt`

The updated `project-current-state/` tree remains the authoritative SSOT; it
is not duplicated inside this package.

## Integrity and read-back boundary

`META5_SHA256_MANIFEST.txt` hashes the other nine package files. The SSOT's
own `SHA256_MANIFEST.txt` hashes all 18 non-self files in
`project-current-state/`.

Publication is one ordinary fast-forward commit on `main` with subject:

`Promote AHD v41 Group 13 reset-return sign-off method to project state rev5`

After push, the executor must freshly read back and verify all 19 SSOT files
and all 10 META-5 package files (`29` total). The containing commit SHA,
remote-HEAD equality, and completed read-back result are post-commit execution
facts and are therefore reported by the executor rather than invented inside
the commit.
