# G2B-HW0-DRV-REUSE0 Evidence Index

## Package disposition

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS`, completed by external commit-pinned remote size/SHA-256 validation after push.
- Overall result: `BLOCKED`.
- First blocker: `BLOCKED — HDMI_DRIVER_DUT_ARTIFACT_NOT_FOUND`.
- Reuse decision: `NOT_REUSABLE_PCI_ALIAS_MISMATCH`.
- Repository/branch: `lukaszsudul/AHD-diagnostic-evidence` / `main`.
- Directory: `v41-host-g2b-hw0-hdmi-xdma-driver-reuse-audit`.
- Required commit message: `Audit reuse of HDMI PCIe XDMA driver for AHD v41`.

The package contains no binary module, credentials, password file, SSH key, repository token, MMIO data, or DMA payload.

## Contract-required artifacts

| File | Purpose |
|---|---|
| `V41_G2B_HW0_DRV_REUSE0_MAIN_REPORT.md` | Overall authority, audit, gate, blocker, and decision |
| `G2B_HW0_DRV_REUSE0_AHD_AUTHORITY.md` | Revision-8 SSOT, candidate, R2, and qualification authority |
| `G2B_HW0_DRV_REUSE0_HDMI_REPOSITORY_DISCOVERY.md` | Targeted repository discovery and immutable identities |
| `G2B_HW0_DRV_REUSE0_HDMI_SSOT_AUTHORITY.md` | HDMI rev1 SSOT and exact driver authority |
| `G2B_HW0_DRV_REUSE0_HDMI_DRIVER_PROVENANCE.md` | Upstream/source/build/binary provenance chain |
| `G2B_HW0_DRV_REUSE0_HDMI_PRIOR_USE_EVIDENCE.md` | Hash-linked historical load, bind, nodes, and DMA proof |
| `G2B_HW0_DRV_REUSE0_MODULE_IDENTITY.md` | Current missing-artifact boundary and platform-module distinction |
| `G2B_HW0_DRV_REUSE0_MODINFO.txt` | Governed historical HDMI metadata and fresh platform modinfo |
| `G2B_HW0_DRV_REUSE0_MODULE_ALIASES.txt` | Exact alias sets and comparison result |
| `G2B_HW0_DRV_REUSE0_MODALIAS_MATCH.md` | Field-by-field AHD/HDMI modalias mismatch |
| `G2B_HW0_DRV_REUSE0_PATCH_AND_CUSTOMIZATION_AUDIT.md` | Complete two-delta source audit and classifications |
| `G2B_HW0_DRV_REUSE0_AHD_HDMI_XDMA_COMPATIBILITY_MATRIX.csv` | Required AHD/HDMI XDMA property matrix |
| `G2B_HW0_DRV_REUSE0_MODULE_COLLISION_ANALYSIS.md` | Shared internal-name and exact-path controls |
| `G2B_HW0_DRV_REUSE0_REUSE_DECISION.md` | Exact terminal reuse decision and blocker separation |
| `G2B_HW0_DRV_REUSE0_NEXT_LOAD_BIND_PLAN.md` | Hard-stop/not-applicable successor record |
| `G2B_HW0_DRV_REUSE0_FINAL_DUT_STATE.md` | Final state and zero-operation ledger |
| `G2B_HW0_DRV_REUSE0_STATE.json` | Machine-readable state |
| `G2B_HW0_DRV_REUSE0_EVIDENCE_INDEX.md` | This package index |
| `G2B_HW0_DRV_REUSE0_SHA256_MANIFEST.txt` | Every other published file; self-excluded |

All 19 required filenames are present. The next-load/bind file deliberately contains a hard stop because exact reuse was not approved.

## Fresh sanitized raw receipts

| File | Purpose |
|---|---|
| `G2B_HW0_DRV_REUSE0_DUT_READONLY_INVENTORY.log` | Authenticated identity, endpoint, link, module, node, host-policy, and initial process snapshot |
| `G2B_HW0_DRV_REUSE0_CONCURRENT_OPERATION_CHECK.log` | Refined self-excluding process/job/package-lock check |
| `G2B_HW0_DRV_REUSE0_STATIC_MODULE_AUDIT.log` | Missing governed HDMI path, fresh platform module metadata, and preserved state |
| `G2B_HW0_DRV_REUSE0_AUTHORITY_SCOPED_ARTIFACT_SEARCH.log` | Search limited to HDMI-authorized `/opt` and `/run` namespaces |
| `G2B_HW0_DRV_REUSE0_FINAL_DUT_READONLY_STATE.log` | Final same-boot endpoint/module/node/no-concurrency checkpoint |

Each controller wrapper receipt records argument/environment sanitation, temporary restricted password-file creation and deletion, command exit state, stdout, and stderr. Secrets and the external authenticated-command helper are not published.

## Publish-safe read-only scripts

| Relative path | Purpose |
|---|---|
| `tools/dut_readonly_inventory.sh` | Initial read-only identity and PCIe/XDMA state |
| `tools/dut_readonly_concurrency.sh` | Refined read-only concurrency inspection |
| `tools/dut_static_module_audit.sh` | Exact governed-path and platform-module static inspection |
| `tools/dut_authority_scoped_artifact_search.sh` | Hash search only in HDMI-authorized namespaces |
| `tools/dut_final_readonly_state.sh` | Final state/non-mutation checkpoint |

These scripts perform reads only. They contain no credentials and were delivered through the pre-existing governed helper; they are evidence of what was inspected, not authority for future execution.

## Integrity and remote read-back convention

`G2B_HW0_DRV_REUSE0_SHA256_MANIFEST.txt` hashes every file in this directory except itself by exact relative path and byte content. Repository attributes disable text normalization, so commit-object bytes and working bytes are compared directly. The containing commit cannot truthfully embed its own future commit hash or remote result; final commit-pinned file count, sizes, SHA-256 values, and mismatch count are therefore validated and reported externally after push.
