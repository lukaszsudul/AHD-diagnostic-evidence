# AHD v41 META-3 Evidence Index

## META-3 transaction identity

| Field | Value |
|---|---|
| Task | `AHD v41 META-3 Build Profile Authorization` |
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Evidence branch | `main` |
| Evidence directory | `v41-meta-project-state-rev3-build-profile-authorization` |
| Prior SSOT revision | `2` |
| Resulting SSOT revision | `3` |
| Accepted input commit | `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` |
| Publication payload commit | `PENDING` |
| Final receipt commit | `PENDING` |

## Files in this package

| File | Purpose |
|---|---|
| `META3_SSOT_UPDATE_REPORT.md` | authority, decision, scope, invariants, validation, source protection and publication receipt |
| `META3_SSOT_DIFF_SUMMARY.md` | concise revision-2 to revision-3 semantic/file diff |
| `META3_SSOT_CONSISTENCY_REPORT.md` | exact local and remote invariant audit |
| `META3_EVIDENCE_INDEX.md` | this package index and provenance map |
| `META3_SHA256_MANIFEST.txt` | SHA-256 hashes for the other four META-3 files |

## Authoritative G2B-LUT0 inputs

All paths below are in
`v41-development-g2b-lut0-resource-attribution` at immutable commit
`a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`.

| Artifact | Use in META-3 |
|---|---|
| `V41_G2B_LUT0_ARCHITECTURE_REVIEW.md` | main engineering PASS and resource-architecture review |
| `G2B_LUT0_RTRACK_INSTRUMENTATION_INVENTORY.md` | functional-vs-research attribution and reversibility boundary |
| `G2B_LUT0_RECOMMENDED_PLAN.md` | selected Plan B and G2B-LUT1 direction |
| `G2B_LUT0_RESOURCE_TARGETS.md` | blocked utilization, hard gate, preferred target, and estimate boundary |
| `G2B_LUT0_BUILD_PROFILE_PROPOSAL.md` | PRODUCT / RESEARCH_DIAGNOSTIC proposal and observability requirements |
| `G2B_LUT0_G2B_COST_BREAKDOWN.md` | G2B incremental-resource attribution |
| `G2B_LUT0_HIERARCHICAL_RESOURCE_MAP.csv` | hierarchical resource evidence |
| `G2B_LUT0_FILE_RESOURCE_MAP.csv` | source/resource inventory |
| `G2B_LUT0_DEINSTRUMENTATION_PLANS.md` | plan alternatives and risk controls |
| `G2B_LUT0_BRAM_PACKING_REVIEW.md` | BRAM packing review |
| `G2B_LUT0_VIVADO_ANALYSIS_RECEIPT.md` | prior evidence-analysis receipt; META-3 runs no Vivado |
| `G2B_LUT0_STATE.json` | machine-readable gate result and qualification boundary |
| `G2B_LUT0_SSOT_IMPACT.md` | pre-META SSOT blocker/authority boundary |
| `G2B_LUT0_EVIDENCE_INDEX.md` | source package index |
| `G2B_LUT0_SHA256_MANIFEST.txt` | source package integrity manifest |

## Publication model

The revision-3 SSOT and initial META-3 evidence are published in one ordinary
payload commit with the required message. Remote `main` and all affected files
are then read back by exact SHA-256. A final evidence-only receipt commit may
record the payload SHA and remote PASS result without rewriting the
revision-3 SSOT.
