# G2B-HW0-DRV-REUSE0 — HDMI repository discovery

## Audit boundary

This record is the result of a cross-project, read-only discovery performed on
2026-09-06. Local discovery was limited to targeted FPGA project locations under
`C:\FPGA` and to an exact historical HDMI worktree path named by published HDMI
evidence. Repository names were then resolved through authenticated GitHub
repository metadata for the already established Owner account `lukaszsudul`.

No clone, fetch, pull, checkout, branch change, worktree creation, remote change,
source edit, SSOT edit, driver operation, DUT access, MMIO, DMA, FPGA programming,
package operation, reboot, or power-cycle was performed by this discovery.

## Discovery result

```text
HDMI_REPOSITORY_DISCOVERY=PASS
HDMI_SOURCE_REPOSITORY=lukaszsudul/FPGA_HDMI
HDMI_EVIDENCE_OR_SSOT_REPOSITORY=lukaszsudul/HDMI-diagnostic-evidence
HDMI_LOCAL_SOURCE_WORKTREE=NOT_FOUND
HDMI_LOCAL_EVIDENCE_WORKTREE=NOT_FOUND
HDMI_SSOT_AUTHORITY_FOUND=YES
```

## Repository identities

| Role | Repository | Sanitized remote | Visibility | Default/canonical branch | Remote HEAD | HEAD tree | Current local tracked state | HDMI SSOT authority |
|---|---|---|---|---|---|---|---|---|
| HDMI source mainline | `lukaszsudul/FPGA_HDMI` | `https://github.com/lukaszsudul/FPGA_HDMI.git` | Private | `main` | `2d64e00b15c4dbb875cd04b4ba7df7c16f4fed1f` | `2a643626235b9b9e1ae67798e1069d140eaabc1e` | `NOT_APPLICABLE_NO_LOCAL_WORKTREE_FOUND` | Authoritative mainline baseline, but not the accepted C5 demo source |
| HDMI evidence and SSOT | `lukaszsudul/HDMI-diagnostic-evidence` | `https://github.com/lukaszsudul/HDMI-diagnostic-evidence.git` | Private | `FPGA_HDMI` | `2317361094d599717a9509bd9d508efd58f6d1a2` | `7bf324a9afb02d8da6947cc0748b16e07d1d0c55` | `NOT_APPLICABLE_NO_LOCAL_WORKTREE_FOUND` | Canonical HDMI SSOT repository and branch |

The remote identities above were re-read at the end of the discovery and had
not changed. A remote commit/tree is an immutable content identity; it is not a
substitute for a local-worktree cleanliness statement.

## SSOT-selected source baselines

The current HDMI SSOT intentionally separates source mainline from the accepted
demo baseline:

| Baseline | Branch | Commit | Tree | Authority and scope |
|---|---|---|---|---|
| Mainline after PR1/PR2 | `main` | `2d64e00b15c4dbb875cd04b4ba7df7c16f4fed1f` | `2a643626235b9b9e1ae67798e1069d140eaabc1e` | Accepted documentation/CI mainline; explicitly not the C5 demo implementation |
| Frozen demo C5 | `codex/demo-r0f-b123-universal-live-20260830` | `6fd13fe7994e454065448303850b8eb9fd140603` | `cab9a2d15a81f7687cdbee1c8e700744f14e8b64` | Accepted C5 FPGA and host-service source for finite HDMI demonstrations |
| Restricted-driver code surface | `codex/demo-r0f-a8-c1-kbuild-compat-20260829` | `b7ef83efcba95e74c25f67996e8c5686a6fa887c` | `01d33fea7f9d36e6772342e536990151ffd1ecc3` | Exact committed driver contract and Kbuild correction; ancestor of C5 |

GitHub comparison established that C5 is two commits ahead of the restricted
driver commit. The eight driver contract, helper, and patch blobs inspected at
both commits have identical Git blob IDs. C5 therefore retains the exact
restricted-driver source surface rather than silently replacing it.

## Local-worktree discovery

Targeted discovery under `C:\FPGA` found no Git worktree whose path or sanitized
remote identified either HDMI repository. No local HDMI repository was selected
on filename similarity alone.

Historical C5 evidence names this source worktree:

```text
C:\Users\Sudul\.codex\worktrees\b123\FPGA_HDMI
```

The exact reported path does not exist on the current controller. Consequently:

```text
CURRENT_HDMI_SOURCE_TRACKED_CLEANLINESS=NOT_CURRENTLY_VERIFIABLE_NO_LOCAL_WORKTREE
CURRENT_HDMI_EVIDENCE_TRACKED_CLEANLINESS=NOT_CURRENTLY_VERIFIABLE_NO_LOCAL_WORKTREE
HISTORICAL_WORKTREE_PATH_PRESENT_NOW=NO
```

Historical reports contain clean or controlled-scope Git assertions for their
own captures. Those assertions are evidence about those captures only and are
not promoted into a current local-worktree claim.

## Authority basis

At evidence commit
`2317361094d599717a9509bd9d508efd58f6d1a2`, the following SSOT paths establish
repository authority and the separation between SSOT and source:

- `project-current-state/README.md` names
  `lukaszsudul/HDMI-diagnostic-evidence`, canonical branch `FPGA_HDMI`, and
  distinguishes it from source repository `lukaszsudul/FPGA_HDMI` on `main`;
- `project-current-state/GOVERNANCE.md` declares
  `project-current-state/` on that canonical branch to be the accepted SSOT;
- `project-current-state/PROJECT_STATE.json` records revision 1 and the accepted
  immutable baselines;
- `project-current-state/ACTIVE_BASELINES.md` identifies the mainline and frozen
  C5 source commits/trees and the two kernel-specific XDMA module identities;
- `project-current-state/EVIDENCE_MAP.md` pins the accepted source and evidence
  commits rather than movable branches.

The SSOT commit has parent
`3143b8775be671381ca19f5feae042b4daa9152d`, the immutable bootstrap evidence
commit for `review/ssot_bootstrap_20260904`.

## Explicit non-claims

- This record does not claim either absent local worktree is clean or dirty.
- It does not treat the source default branch as the accepted C5 demo baseline.
- It does not treat an older evidence branch as a second SSOT.
- It does not claim that a remote repository commit proves a current DUT file.
- It does not claim that any file merely named `xdma.ko` belongs to HDMI.
- It does not authorize cloning, restoring, checking out, or modifying either
  repository.

