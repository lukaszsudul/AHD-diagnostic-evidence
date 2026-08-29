# AHD v41 META-2 Evidence Index

## META-2 transaction identity

| Field | Value |
|---|---|
| Task | `AHD v41 META-2 SSOT Update after G2B-PRE Acceptance` |
| Evidence repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Evidence branch | `main` |
| Evidence directory | `v41-meta-project-state-rev2-g2b-pre-promotion` |
| Prior SSOT revision | `1` |
| Resulting SSOT revision | `2` |
| Accepted input commit | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Publication payload commit | `7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b` |
| Final receipt commit | remote HEAD containing the completed receipt |

## Files in this package

| File | Purpose |
|---|---|
| `META2_SSOT_UPDATE_REPORT.md` | authority, decision, affected files, boundaries, validation and publication receipt |
| `META2_SSOT_DIFF_SUMMARY.md` | concise revision-1 to revision-2 semantic/file diff |
| `META2_SSOT_CONSISTENCY_REPORT.md` | exact local and remote invariant audit |
| `META2_EVIDENCE_INDEX.md` | this package index and provenance map |
| `META2_SHA256_MANIFEST.txt` | SHA-256 hashes for the other four META-2 files |

## Authoritative G2B-PRE inputs

All paths below are in
`v41-development-g2b-pre-c2h-abi-mmio-freeze` at immutable commit
`e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`.

| Artifact | Use in META-2 |
|---|---|
| `V41_G2B_PRE_ARCHITECTURE_FREEZE_REPORT.md` | primary engineering PASS and architecture-freeze boundary |
| `V41_C2H_TRANSPORT_ABI_V1.md` | normative human-readable ABI |
| `V41_C2H_TRANSPORT_ABI_V1.json` | machine-readable ABI and exact field semantics |
| `V41_G2B_MMIO_CONTRACT.md` | normative MMIO behavior |
| `V41_G2B_MMIO_MAP.csv` | exact 67-row register/bit map |
| `V41_C2H_LINUX_CONSUMER_CONTRACT.md` | frozen transport-facing Linux input contract |
| `G2B_PRE_ABI_CONSISTENCY_REPORT.md` | static `63/63 PASS` receipt |
| `G2B_PRE_DECISION_LOG.md` | 24 decisions / 15 closure groups and rationale |
| `G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md` | authorized revision-2 transaction requirements |
| `G2B_PRE_STATE.json` | machine-readable gate result and non-execution boundary |
| `G2B_PRE_EVIDENCE_INDEX.md` | accepted input provenance |
| `G2B_PRE_SHA256_MANIFEST.txt` | accepted package integrity manifest |

## Publication model

The revision-2 SSOT and initial META-2 evidence are published in the payload
commit `7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b` using the required commit
message. Remote `main` and 24 required file hashes were read back successfully.
Only this META-2 receipt and its package manifest are updated in the final
evidence-only closure commit. The SSOT is not rewritten by that receipt.
