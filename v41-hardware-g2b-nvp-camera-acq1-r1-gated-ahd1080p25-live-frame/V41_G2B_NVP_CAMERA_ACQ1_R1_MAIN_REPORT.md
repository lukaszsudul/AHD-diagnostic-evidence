# AHD v41 G2B-NVP-CAMERA-ACQ1-R1 main report

## Result

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.
- Overall result: `BLOCKED`.
- First blocker: `ACQ1_R1_COMPLETE_ROLLBACK_AUTHORITY_NOT_PROVEN`.

## First failed gate

The prompt, accepted source parent/tree, clean diagnostic worktree, pinned reference commit/tree, reference-file bytes, and frozen SCAN0 semantic artifacts all matched their required identities. The corrected slice forward order also matches the pinned dynamic reference branch.

The exact selected AHD1080p25 reference path contains 211 semantic operations and 137 unique non-bank-select CH1 register targets. Slice targets Bank5 `0x08/0x05` and all nine functional targets of the exact `F0=0x31` discriminator are subsets of those 137. The separate conditional CH1-to-VDO1 route adds Bank1 `0xC2`, producing a complete union of `138` potentially modified functional registers.

Only `6/138` targets have pre-existing positive technical authority for a safe full-byte baseline/readback and exact restore: Bank0 `0x23/0x81/0x85`, Bank1 `0x84/0x8C`, and the already-qualified masked route at Bank1 `0xC2`. The remaining `132/138` targets lack positive safe-read or exact pre-campaign restore authority. `88/138` are mentioned by the current fixed v41 init sequence, but that is not proof of their exact pre-campaign bytes or of side-effect-free reads; `50/138` are not even targets of that current init sequence.

The touched set has zero intersection with the known 14-address Bank0 read-side-effect blacklist. That negative comparison cannot prove the unclassified 132 targets safe, nor can it determine how many are write-only. The exact count of write-only unrestorable targets and read-side-effect targets therefore remains `N/A`, not zero. Two reference RMW fields remain symbolic: Bank1 `0xED` and Bank9 `0x44`.

Phase A section 6 requires every touched register to be readable or exactly restorable, with no unresolved symbolic rollback field. That requirement is false before source implementation, so the task stopped exactly as `ACQ1_R1_COMPLETE_ROLLBACK_AUTHORITY_NOT_PROVEN`. No hardware-capable source or bitstream was created.

## Other Phase-A findings

The CVBS slice helper is `PROVEN_NOT_EXECUTED`: the accepted current v41 target is statically AHD 1080p25/1080p no-video and is not below the reference `NVP6134_VI_720P_2530` threshold. The exact `F0=0x31` discriminator branch was semantically extracted, including nine unique functional preconditioning/postlude targets and its threshold predicate, but its execution authority is `NOT_REACHED` after the earlier rollback gate.

## Preserved state and non-claims

Functional NVP writes are `0`. No DUT contact, camera gate, programming, reboot, driver load, MMIO, I2C, capture, or rollback occurred. The source branch remains clean at `c7e16fa3da26545cef960a6c75427a3614c4b655` and no source commit exists. The previous FPGA runtime profile is unchanged. PRODUCT, SSOT and META are unchanged; no reference source, vendor PDF, bitstream, DCP, driver, binary, capture, or camera pixels are published.

## Required closure

A future separately governed task must provide positive NVP6134C technical access/read-side-effect/restore authority for all 132 gap targets, including the private mode, EQ and ACP banks, and must reduce both symbolic RMW fields to exact captured bytes before implementation. Absence from a blacklist and reference-driver write behavior are not substitutes for that proof.

Generated UTC: `2026-09-12T08:41:24Z`.
