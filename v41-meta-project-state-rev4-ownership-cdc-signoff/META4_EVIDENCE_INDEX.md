# META-4R2 Evidence Index

## Transaction

- Project: `AHD_v41`
- Update: `META-4R2`
- Revision: `3 -> 4`
- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Branch: `main`
- Directory: `v41-meta-project-state-rev4-ownership-cdc-signoff`
- Commit model: one ordinary non-force publication commit
- Frozen header SHA-256:
  `D7456D989F0D879B2E1FD8777876F5AE786947D789CE1D480CA720316AC7342B`

## Files

| File | Purpose |
|---|---|
| `META4_SSOT_UPDATE_REPORT.md` | Main result, preflight, consistency, and protection report. |
| `META4_OWNERSHIP_CDC_DECISION.md` | Governed ownership CDC architecture decision. |
| `META4_GROUP9_SIGNOFF_PROMOTION.md` | Diagnostic disposition and future Group-9 recipe. |
| `META4_PROJECT_STATE_DIFF.md` | Revision-3 to revision-4 semantic and file-scope diff. |
| `META4_EXPECTED_AFFECTED_FILES.md` | Pre-write exact authorized path set. |
| `META4_EXACT_FILE_CHANGE_LEDGER.md` | Previous/new SHA-256 ledger for all 16 SSOT files. |
| `META4_FROZEN_CONTRACT_RECEIPT.md` | Header SHA and entire frozen header verbatim. |
| `META4_EVIDENCE_INDEX.md` | This index. |
| `META4_STATE.json` | Machine-readable META-4R2 result. |
| `META4_SHA256_MANIFEST.txt` | SHA-256 manifest for the other nine package files. |

## Authoritative evidence

| Stage | Commit | Directory |
|---|---|---|
| BS1R | `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62` | `v41-development-g2b-bs1r-single-sink-bus-skew-retry` |
| BS2 | `4699632c591238fee46ada3b0de37532fddd0b6f` | `v41-development-g2b-bs2-alternative-timing-equivalence` |
| BS3 | `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` | `v41-development-g2b-bs3-ownership-mailbox-settling-proof` |
| META-4P | `24be8a8c6eb227c548db130009ca495bfb472802` | `v41-meta-project-state-rev4-write-contract-preflight` |

The transaction updates exactly the 16 SSOT paths listed in
`META4_EXPECTED_AFFECTED_FILES.md`. Remote completion requires fresh
post-push SHA-256 read-back of all 19 SSOT files plus all 10 files in this
directory.
