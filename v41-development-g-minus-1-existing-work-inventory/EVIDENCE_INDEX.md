# G-1 Evidence Index

## Audit anchors

- Primary source workspace: `C:\FPGA\FPGA_AHD`
- Source workspace branch/HEAD: `main` / `be94f88ee8d179f12928ab791bdae27c22cd1762`
- Primary source remote: `https://github.com/lukaszsudul/FPGA_AHD.git`
- Live source branches inventoried: 11
- Public evidence input head at audit start: `955ba0cd2462f4dec9dcb086175ab6eca57365bb`
- Public evidence head on the final pre-publication re-fetch: `aff7e32edc1cf71bde95b6c19e54e6f307764237`
- Source workspace writes/builds/hardware access: none

The intervening `aff7e32...` commit added the unrelated `v41-research-r0-r1i-causal-isolation-design` package. It did not touch the G-1 target path. The isolated publication history was rebased onto that remote head before the normal fast-forward push.

## Qualified R1i anchors

- R1h source commit/tree: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` / `161e561f007912d73dba93c5ecd78e3cc3a6955b`
- R1i source commit/tree: `20c3323d79d3896edc586d6db1df7deee60f9e41` / `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- R1i bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- Public package: `v41-nvp-r1i-r2-qualified-poc-hardware-evidence`
- Scientific verdict: `THESIS_CONFIRMED`, `STRONG_PASS`, `QUALIFIED_POC_BASELINE`
- Limitation: exact low-level causal mechanism remains inconclusive

The R1h/R1i commits are not advertised by current FPGA_AHD refs and direct fetch by SHA fails. Exact recoverability was checked in an isolated clone by applying, in order:

1. `v41-nvp-r1e-extended-observability-r1/03_SOURCE/0001-v41-diag-add-R1e-NVP-observability.patch`
2. `v41-nvp-r1f-phase-complete-observability/01_SOURCE_IDENTITY/0001-Add-R1f-phase-complete-NVP-observability.patch`
3. `v41-nvp-r1g-vhdl-compatibility-and-phase-complete-observability/07_R1G_SOURCE_IDENTITY/R1F_TO_R1G_COMMIT.patch`
4. `v41-nvp-r1h-bram-backed-phase-complete-large-sample/06_SOURCE_COMMIT/R1G_TO_R1H.patch`
5. `v41-nvp-r1i-r2-qualified-poc-hardware-evidence/final/R1H_TO_R1I_SOURCE.patch`

Starting from current reachable branch `diag/v41-nvp-i2c-25khz-r1` at `f007dc172d43d30b02729755e60382f8ce3dbff4`, the replay reproduced intermediate trees and exact R1h/R1i trees. The source workspace was not used for replay.

## XDMA donor anchors

- Primary candidate: `v41/xdma-v40.1.0-base` / `c89e88bcdf389614c884fb129e8b2d42a585bccb`
- Functional Phase 1 commit/tree: `fd32fcb65be3f1a59c569874195d1faeaf7d27e9` / `c54368c7e830904505ca58da7bb57ef62c3635dc`
- Phase 2 hardware acceptance: `9306c25a48dedd2372bf5d06e37344ae2aa3e85a`
- Secondary candidate: `dev/v41-xdma-offline-next` / `8464af66611f7c22b8a36a4aab915d598eedda3f`
- Historical original line: `v41/xdma` and archive alias / `f3cfa6bf72f3cdcc5688f3a28ff16e80afc5d875`
- XDMA XCI SHA-256: `EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C`

## Relevant public campaign directories

- `v41-phase3-nvp-i2c-digital-trace-r1`
- `v41-phase3-nvp-i2c-digital-trace-r2`
- `v41-phase3-nvp-i2c-z8-experiment-r1`
- `v41-nvp-axi-aclk-lifecycle-measurement-r1`
- `v41-nvp-i2c-25khz-paired-ab-r1`
- `v41-nvp-i2c-25khz-paired-ab-r1b`
- `v41-nvp-i2c-25khz-paired-ab-r1c`
- `v41-nvp-address-ack-probe-50k-vs-25k-r1d`
- `v41-nvp-r1c-control-flow-shortening-offline-r1`
- `v41-nvp-r1e-extended-observability-r1`
- `v41-nvp-r1f-phase-complete-observability`
- `v41-nvp-r1g-vhdl-compatibility-and-phase-complete-observability`
- `v41-nvp-r1h-bram-backed-phase-complete-large-sample`
- `v41-nvp-r1h-r2-build-harness-continuation-and-large-sample`
- `v41-nvp-r1h-r4-super-fast-implementation-and-large-sample`
- `v41-nvp-r1i-r2-qualified-poc-hardware-evidence`
- `t4-rca-v41-reset-clock-domain-audit-2026-08-20`
- `t4-delayed-warm-reboot-phase2-single-test-2026-08-20`
- `t4-delayed-reboot-salvage-xdma-vivado-forensic-2026-08-20`
- `t4-delayed-reboot-final-salvage-explicit-bash-loader-2026-08-20`
- `v41-nvp-odiv2-route-contention-p2-r1`
- `v41-nvp-routed-dcp-power-scl-sda-timing-audit-r1`
- `rca-vs-formal-phase2-power-breakdown-r1`
- `t1-v40.1.0-rca-current-hardware-control-2026-08-20`
- `overnight-2026-08-19-nvp-t1-t2-t4`

## Artifact routing

| Question | Primary artifact | Supporting artifact |
|---|---|---|
| What exists and what remains? | `V41_EXISTING_WORK_INVENTORY_AND_REUSE_REPORT.md` | `V41_ASSET_REUSE_MATRIX.csv` |
| Which branch contains what? | `V41_BRANCH_INVENTORY.csv` | `V41_BRANCH_GRAPH.txt` |
| Was the source workspace clean/read-only? | `V41_LOCAL_WORKSPACE_MANIFEST.txt` | `STATE.json` |
| How does R1i differ from donors? | `V41_R1I_XDMA_CONFLICT_MATRIX.csv` | report section 13 |
| What does each campaign prove? | `V41_EVIDENCE_CAMPAIGN_MATRIX.csv` | report section 12 |
| Which scripts/tests/constraints can be reused? | `V41_SCRIPT_INVENTORY.csv`, `V41_TEST_INVENTORY.csv`, `V41_XDC_INVENTORY.csv` | reuse matrix |
| What is the exact XDMA configuration? | `V41_IP_CONFIGURATION.csv` | report section 6 |
| Which documents remain authoritative? | `V41_DOCUMENT_INDEX.csv` | report sections 3–12 |
| Is the package intact? | `SHA256_MANIFEST.txt` | Git commit identity |

## Evidence boundaries

This package intentionally publishes identities, paths, summaries and small configuration facts rather than the full FPGA_AHD source tree. It contains no generated Vivado products, credentials, private keys, tokens, SSH authentication details, private host addresses, or unrelated personal data. The external scratch mirror/clones are local audit instruments and are not part of the publication.
