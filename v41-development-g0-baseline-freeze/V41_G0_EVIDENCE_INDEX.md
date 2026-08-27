# AHD v41 G0 Evidence Index

## Authority

- Gate: `AHD_V41_G0_BASELINE_FREEZE`
- Date: 2026-08-27
- Source repository: `lukaszsudul/FPGA_AHD`
- Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
- Evidence directory: `v41-development-g0-baseline-freeze`

## Authoritative input packages

| Input | Directory | Commit | Use |
|---|---|---|---|
| Accepted G-1 inventory | `v41-development-g-minus-1-existing-work-inventory` | `654b9adf7d02cbf8946e420538955ffaaeae7eb2` | Donor findings, reuse matrix, gaps, branch inventory |
| Qualified R1i evidence | `v41-nvp-r1i-r2-qualified-poc-hardware-evidence` | `955ba0cd2462f4dec9dcb086175ab6eca57365bb` | R1i identities, source hashes, qualified behavior and outcomes |

## Source identity evidence

| Identity | Value | Verification |
|---|---|---|
| R1i preservation branch | `baseline/v41-r1i-qualified-poc` | remote read-back to original commit and exact tree |
| R1i historical commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` | exact original commit preserved directly |
| R1i qualified tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` | branch and annotated tag tree match |
| R1i annotated tag object | `f7847a259dbe43bf99fa6d6515ed85131fafffc0` | peels to historical commit |
| Primary XDMA donor | `c89e88bcdf389614c884fb129e8b2d42a585bccb` | branch and annotated tag target match |
| XDMA annotated tag object | `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` | peels to exact donor commit |

## Published files

| File | Purpose |
|---|---|
| `README.md` | Public gate summary and G1 entry condition |
| `V41_G0_BASELINE_FREEZE_REPORT.md` | Authoritative G0 execution and acceptance report |
| `V41_R1I_PROTECTED_BEHAVIOR_CONTRACT.md` | Mandatory R1i behavior preservation contract |
| `V41_R1I_PRESERVATION_RECEIPT.md` | R1i object/ref/tag creation and read-back receipt |
| `V41_XDMA_DONOR_RECEIPT.md` | Primary/secondary donor identity and role receipt |
| `V41_SECONDARY_DONOR_PROVENANCE_HARDENING_DIFF_RECEIPT.txt` | Exact sanitized secondary-donor delta receipt |
| `V41_INTEGRATION_BASELINE.md` | Frozen conceptual integration inputs |
| `V41_G0_INTEGRATION_CONFLICT_REGISTER.csv` | Five unresolved G1 design hotspots |
| `V41_PCIE_GEN2_FEASIBILITY_AUDIT.md` | Read-only Gen2 x1 architecture feasibility audit |
| `V41_PCIE_THROUGHPUT_ARCHITECTURE_CONTRACT.md` | Frozen throughput/link requirement |
| `V41_288MBPS_ACCEPTANCE_CONTRACT.md` | Later G8 measurement and pass/fail definition |
| `V41_DATA_PLANE_GAP.md` | Frozen application DMA gap |
| `V41_G1_INPUT_CONTRACT.md` | Complete G1 input package and mission boundary |
| `V41_G0_STATE.json` | Machine-readable gate state |
| `V41_G0_EVIDENCE_INDEX.md` | This evidence map |
| `V41_G0_SHA256_MANIFEST.txt` | SHA-256 integrity manifest for all non-manifest files |

## Publication receipt

- Payload commit: `64eca0cfbb76593d7e875df7b3271651668cbe61`
- Payload directory tree: `2e6c37ca6e650b716a652a93dd55cfe51d58dcd8`
- Payload remote read-back: `PASS`
- Final receipt commit: current Git commit containing this index; verified as remote `origin/main` after the finalization push

The SHA-256 manifest deliberately excludes itself to avoid recursive identity.
