# META-8A evidence index

Single ordinary promotion transaction; exact current SSOT snapshot included (19 files). Required evidence files:

- META8A_SSOT_UPDATE_REPORT.md
- META8A_WRITE_CONTRACT_RECEIPT.md
- META8A_PRODUCT_CANDIDATE_DECISION.md
- META8A_LOCAL_CANDIDATE_VERIFICATION.md
- META8A_DUAL_IDENTITY_CONTRACT.md
- META8A_HW0_PRODUCT_GATE_CONTRACT.md
- META8A_EXPECTED_AFFECTED_FILES.md
- META8A_EXACT_FILE_CHANGE_LEDGER.md
- META8A_PROJECT_STATE_DIFF.md
- META8A_EVIDENCE_INDEX.md
- META8A_STATE.json
- META8A_SHA256_MANIFEST.txt

Additional preflight and validation receipts retain the immutable evidence hash audit and consistency checks. META8A_SHA256_MANIFEST.txt seals all package files except itself; the snapshot SSOT manifest seals its 18 companion files. Post-commit publication/read-back completion is delivered separately in the final task receipt, avoiding self-referential Git hashes and premature PASS claims.
