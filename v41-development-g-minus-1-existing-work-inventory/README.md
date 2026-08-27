# AHD v41 G-1 Existing-Work Inventory

This directory is the sanitized public evidence package for Gate G-1 of the AHD v41 plan. It inventories the existing local/remote FPGA_AHD work, reconstructs the XDMA lineage, correlates public hardware evidence, compares the qualified R1i state with XDMA donor candidates, and classifies reusable assets. It does not perform donor selection, integration, a build, simulation, Vivado execution, programming, or hardware access.

## Verdict

- Engineering gate: **PASS**
- Evidence publication: **PASS** (audited payload commit `510cb2ead5dc49d36031b745022742f912b54e77` remotely read back)
- Source workspace remained read-only: **YES**
- Qualified R1i identity: **PASS**
- Recommended primary XDMA donor candidate for G0 review: `v41/xdma-v40.1.0-base`
- Recommended secondary donor: the dev-only Phase 3 provenance hardening from `dev/v41-xdma-offline-next`
- Final donor selection: **NOT PERFORMED**

The endpoint/AXI-Lite/MMIO substrate is implemented and hardware proven. Application DMA is not: C2H data signals are tied off, H2C is backpressured, all recorded DMA-operation counts are zero, and no transfer/throughput tools or evidence exist.

The qualified R1i commits are no longer advertised by current FPGA_AHD refs, but the public ordered patch chain was independently replayed from reachable `f007dc1...` and reproduced the exact R1h and R1i trees. The published bitstream LFS payload also independently matches the qualified SHA-256.

## Primary artifacts

- `V41_EXISTING_WORK_INVENTORY_AND_REUSE_REPORT.md` — full engineering report and conclusions
- `V41_ASSET_REUSE_MATRIX.csv` — asset-level reuse classification
- `V41_BRANCH_INVENTORY.csv` — all 11 live FPGA_AHD remote branches
- `V41_LOCAL_WORKSPACE_MANIFEST.txt` — sanitized source-workspace baseline and safety record
- `V41_R1I_XDMA_CONFLICT_MATRIX.csv` — file/asset comparison without conflict resolution
- `V41_DOCUMENT_INDEX.csv` — relevant documentation index and authority status
- `V41_IP_CONFIGURATION.csv` — FPGA IP identity/configuration summary
- `V41_SCRIPT_INVENTORY.csv` — build, host, diagnostics and evidence procedures
- `V41_TEST_INVENTORY.csv` — test-to-gate mapping and evidence status
- `V41_XDC_INVENTORY.csv` — active/inactive constraints and reuse assessment
- `V41_EVIDENCE_CAMPAIGN_MATRIX.csv` — public campaign/source/result correlation
- `V41_BRANCH_GRAPH.txt` — concise lineage view
- `EVIDENCE_INDEX.md` — provenance and artifact routing
- `STATE.json` — machine-readable gate state
- `SHA256_MANIFEST.txt` — package integrity hashes

## Critical next-decision warning

The committed XDMA endpoint is PCIe Gen1 x1. Its post-8b/10b theoretical maximum is 250 MB/s before PCIe protocol overhead, so a requirement for 288 MB/s sustained application payload is infeasible without an architecture or requirement change. This must be resolved before a future DMA design is frozen.

All source identities, file paths, excerpts and result summaries in this package are review-safe. No credentials, private keys, tokens, SSH authentication material, unrelated personal data, full FPGA source tree, generated Vivado tree, or hardware access output was published.
