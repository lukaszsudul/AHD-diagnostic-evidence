# AHD v41 R1i Preservation Receipt

## Result

`PASS` — the original historical R1i commit was recovered from the local object database, verified to contain the exact qualified tree, published directly as a permanent branch, and tagged with an annotated immutable identity tag. No preservation-wrapper commit was needed.

## Required identity

- Historical commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Qualified tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- R1h base commit/tree: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` / `161e561f007912d73dba93c5ecd78e3cc3a6955b`
- Qualified bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`

## Resolution attempts

All source-management work used isolated clones outside the primary source worktree.

1. Local primary object check: the exact R1i commit and R1h commit existed; `20c3323d...^{tree}` resolved to `70d801fd...`.
2. Direct isolated remote fetch by exact SHA: failed with `fatal: remote error: upload-pack: not our ref 20c3323d...`.
3. Read-only isolated fetch from `C:/FPGA/FPGA_AHD`: succeeded; the transferred object resolved to commit `20c3323d...`, parent `94fa9e77...`, and tree `70d801fd...`.

The recovered commit metadata identifies the exact original historical object; the preservation ref therefore points directly to it rather than to a newly created wrapper.

## Preservation refs

| Item | Identity | Verified target |
|---|---|---|
| Branch | `baseline/v41-r1i-qualified-poc` | commit `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Branch tree | — | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Annotated tag | `v41-r1i-qualified-poc-20260827` | commit `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Tag object | `f7847a259dbe43bf99fa6d6515ed85131fafffc0` | annotated tag object |
| Tag tree | — | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |

The tag message records the required `THESIS_CONFIRMED`, `STRONG_PASS`, qualified tree, historical commit, bitstream SHA-256, and `QUALIFIED POC BASELINE / NOT PRODUCTION RELEASE` scope.

## Publication

The branch and both G0 tags were pushed in one atomic, non-force operation. Git reported only three new refs:

- new branch `baseline/v41-r1i-qualified-poc`
- new tag `v41-r1i-qualified-poc-20260827`
- new tag `v41-xdma-primary-donor-g0-20260827`

A fresh isolated clone from GitHub then verified:

- branch commit `20c3323d79d3896edc586d6db1df7deee60f9e41`
- branch tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- R1i tag object `f7847a259dbe43bf99fa6d6515ed85131fafffc0`
- R1i tag peeled target `20c3323d79d3896edc586d6db1df7deee60f9e41`
- R1i tag tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`

No existing branch head changed.

## Authoritative reconstruction fallback retained

The original object is now preserved, so G0 did not need to reconstruct a wrapper tree. The public ordered chain remains a second, independently verified recovery route and must be applied in full from reachable base `f007dc172d43d30b02729755e60382f8ce3dbff4`:

| Stage | Public patch SHA-256 | Expected tree after `git apply --index` |
|---|---|---|
| R1e | `890538634C33A2DBB32BDBF36FBCD50D65E3EE7467F042F5AF9D30232DB69654` | `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| R1f | `C5AD60328EFE96D46FF604D9876A283818371E997DF9ACC0CBB3D7DA148530A7` | `cfde8769af95cf20586391c411fab3ddfa2c87b6` |
| R1g | `637749B37853DD2EF29FA965D51E215E2990F65474F3C18E6713BAB19FF38DFD` | `3a59ebec130103055d24a3a32ecda00dedde5534` |
| R1h | `C573FA3379F2C300BAD6AD464142923F2B5318DA93DD5594705B1472105EB8FF` | `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| R1i | `01A2CD8C5F87B9F532F1FA6152F7D2DC0A039525345F8AB1AAE6A4F2CCD55238` | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |

Applying only the final R1h-to-R1i patch to the donor is invalid. The untracked R1h-R2 harness patch is not part of source reconstruction.

## Configuration-management disposition

- Permanent branch: published
- Annotated tag: published and must never be moved, deleted, force-updated, or recreated
- Tree verification: `PASS`
- Source-ref publication: `PASS`
- Primary worktree source files or refs modified: `NO`
