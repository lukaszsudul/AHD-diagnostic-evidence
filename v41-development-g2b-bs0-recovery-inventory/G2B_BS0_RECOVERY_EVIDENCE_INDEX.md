# G2B-BS0 Recovery Evidence Index

## Publication identity

- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Branch: `main`
- Directory: `v41-development-g2b-bs0-recovery-inventory`
- Commit identity: the Git commit containing this directory; the exact SHA is recorded by push/remote read-back in the execution completion response.
- Pre-publication remote BS0 status: `NONE`
- Pre-publication remote HEAD: `a7db236b56340095f3521ec195d2a3b49d10f956`

## Published files

| File | Role |
|---|---|
| `V41_G2B_BS0_RECOVERY_INVENTORY_REPORT.md` | Primary forensic report, Git/remote inventory, sequence, interruption, and disposition |
| `G2B_BS0_RECOVERY_FILE_INVENTORY.csv` | Per-artifact absolute path, size, timestamp, SHA-256, type, expected flag, status, and notes |
| `G2B_BS0_RECOVERY_PROGRESS_MATRIX.md` | Fifteen-stage and experiment-level completion matrix |
| `G2B_BS0_RECOVERED_FINDINGS.md` | Artifact-supported findings with evidence hashes and confidence |
| `G2B_BS0_RECOVERY_RESUME_PLAN.md` | Reuse boundary, remaining work, and exact next-task scope |
| `G2B_BS0_RECOVERY_SSOT_IMPACT.md` | Revision equality, gate hold/block, and no-promotion statement |
| `G2B_BS0_RECOVERY_STATE.json` | Machine-readable recovery state |
| `G2B_BS0_RECOVERY_EVIDENCE_INDEX.md` | This index |
| `G2B_BS0_RECOVERY_SHA256_MANIFEST.txt` | SHA-256 manifest for the eight other published files |

The manifest intentionally excludes itself to avoid recursive self-hashing.

## Local source boundary

Primary interrupted-attempt root:

- `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831`
- 190 files, 34 directories, 360,647 bytes
- latest attempt artifact: `experiments\EXP005_FULL_BUS_SKEW\experiment_result.txt`
- latest artifact timestamp: `2026-08-31T20:59:04.7157077+02:00`
- latest artifact SHA-256: `EFF524FE16B471ED7F6BE87B3FAFF7BBA0E922C7EFD80C04A2BEB286A2AEF2F1`

Principal external provenance anchors:

- sealed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- Group-9 object list SHA-256: `CE4E8A35CB82CCD0A85AEBF340B997D74FEF9250C86BA76C61769E332079F4DB`
- historical Group-9 isolated XDC SHA-256: `06F27BB2D3E5E6D8691274F7C9D28A8C560F218ADCDD53D173ECFA6AE696A754`
- historical BUS_SKEW report SHA-256: `0E03F88CAD64BA2DC1C1BED1E1A13FF2E0CF674EF940B712FE1148956B30CDE9`
- Gen12 CDC report SHA-256: `FD1962A3353C5F6288989A39453C038709F5C1F41F1D6422D74D9AD28D5F553E`
- older Gen7B methodology antecedent SHA-256: `B80D705E897E613BAF96C9AC8643FD3A559AB4465E305C8757F01856F2BBDC98`

## Source-log policy

Raw DCPs, logs, XDCs, reports, process samples, and Codex session files were not copied into the evidence repository. They can contain bulky design detail, machine-local paths, or unrelated session context. Their absolute locations, sizes, timestamps, hashes, roles, and completion states are recorded in the CSV, and the critical hashes are cited in the findings. This preserves forensic identity without duplicating source material or modifying any pre-existing evidence directory.

## Verification rules

1. Verify all eight non-manifest files against `G2B_BS0_RECOVERY_SHA256_MANIFEST.txt`.
2. Verify the directory exists at the remotely advertised `main` commit.
3. Verify the five acceptance files exist remotely: main report, progress matrix, findings, resume plan, and manifest.
4. Verify the containing commit is the pushed non-force publication commit.
5. Verify `project-current-state` remains revision 3 and its subtree remains unchanged.
