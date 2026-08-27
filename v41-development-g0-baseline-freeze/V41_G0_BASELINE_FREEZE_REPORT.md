# AHD v41 G0 Baseline Freeze Report

Gate date: 2026-08-27

## Executive result

- Engineering gate: `PASS`
- Source refs publication: `PASS`
- Evidence publication: `PASS`
- Overall result: `PASS`
- G1 readiness: `READY`

G0 permanently preserves the exact qualified R1i source state, freezes both XDMA donor identities and roles, freezes the v41 integration inputs, rejects Gen1 x1 as the final throughput configuration, and freezes PCIe Gen2 x1 or better with measured sustained application payload of at least 288 MB/s.

## Scope controls

The following actions were not performed: R1i/XDMA integration, XDMA XCI modification, build, simulation, Vivado execution, throughput testing, hardware access, merge, rebase, force push, existing-ref update, or G1 design.

The active primary worktree remained outside all source-management and evidence-publication actions.

## Primary worktree verification

| Check | Required | Observed | Result |
|---|---|---|---|
| Path | `C:\FPGA\FPGA_AHD` | `C:\FPGA\FPGA_AHD` | PASS |
| Branch | `main` | `main` | PASS |
| HEAD | `be94f88ee8d179f12928ab791bdae27c22cd1762` | same | PASS |
| Working tree | clean | clean | PASS |

Final invariant verification is recorded below and in `V41_G0_STATE.json`.

## Authoritative inputs

- G-1 evidence: `v41-development-g-minus-1-existing-work-inventory`, publication commit `654b9adf7d02cbf8946e420538955ffaaeae7eb2`
- R1i qualification evidence: `v41-nvp-r1i-r2-qualified-poc-hardware-evidence`, publication commit `955ba0cd2462f4dec9dcb086175ab6eca57365bb`
- Owner decisions: four physical inputs, maximum two active, sustained application payload at least 288 MB/s, and PCIe Gen2 x1 or better

## R1i permanent preservation

The original R1i commit object was absent from advertised remote refs. A direct fetch from GitHub by exact SHA failed with `not our ref`, as G-1 had found. The exact object remained in the local primary clone's object database. It was transferred read-only into an isolated clone and verified:

- Original commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Commit tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Expected qualified tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Result: exact historical commit safely available; no preservation wrapper was required

The new branch `baseline/v41-r1i-qualified-poc` points directly to that historical commit. Annotated tag `v41-r1i-qualified-poc-20260827` has tag object `f7847a259dbe43bf99fa6d6515ed85131fafffc0`, peels to the same commit, and resolves to the exact qualified tree.

The qualified bitstream identity remains `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`. The scientific classification remains `THESIS_CONFIRMED`, `STRONG_PASS`, `QUALIFIED_POC_BASELINE`; production qualification is not claimed and the exact low-level causal mechanism remains `INCONCLUSIVE`.

## XDMA donor freeze

The authoritative primary donor is `v41/xdma-v40.1.0-base` at `c89e88bcdf389614c884fb129e8b2d42a585bccb`, tree `417820c69c134161fcafae0947dc5976919814d1`. Its annotated identity tag `v41-xdma-primary-donor-g0-20260827` has tag object `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` and peels to the exact donor commit.

Anchors are functional Phase-1 `fd32fcb65be3f1a59c569874195d1faeaf7d27e9` and hardware Phase-2 acceptance `9306c25a48dedd2372bf5d06e37344ae2aa3e85a`. Accepted evidence covers PCIe Gen1 x1 enumeration, driver loading, BARs, identity, status and scratch/MMIO. It does not cover application DMA payload.

The secondary donor is `dev/v41-xdma-offline-next` at `8464af66611f7c22b8a36a4aab915d598eedda3f`. Its role is frozen as `SECONDARY_DONOR`, `PROVENANCE_HARDENING_ONLY`, `REQUIRES_REVIEW_BEFORE_ADOPTION`. The exact one-file semantic diff receipt is included; no hunk was applied.

## Integration baseline and conflicts

Qualified R1i is the NVP/I2C functional authority. The primary XDMA donor is the PCIe/XDMA/control-plane authority. The five G1 decision hotspots are NVP bringup, autoinit, XDMA top, control/status registers, and build/provenance composition. G0 registers but does not resolve them.

R-track experimental candidates are excluded from the G-track baseline. Legacy MMIO behavior through `0x35FF` and the R1i read-only telemetry page `0x3600-0x367F` are protected.

## Throughput architecture

The product requirement is at least 288 MB/s sustained application payload, measured in decimal MB/s at the application/host boundary with two concurrently active video channels. It is not reduced or reinterpreted to fit the donor.

Gen1 x1 has a 250 MB/s raw post-8b/10b ceiling before PCIe overhead and therefore cannot meet 288 MB/s sustained application payload. It is prohibited as the final v41 throughput configuration. The minimum target is Gen2 x1 or another configuration proven to meet the same measured payload requirement; the preferred current target is Gen2 x1.

Gen2 x1's 500 MB/s raw post-8b/10b ceiling is not acceptance. Link training at Gen2 is not acceptance. The later G8 measurement contract controls qualification.

## Gen2 feasibility audit

Classification: `LIKELY_FEASIBLE_NEEDS_G1_VALIDATION`.

Positive evidence is the `xc7a35tcsg325-2` target, one Series-7 PCIe hard block at `PCIE_X0Y0`, an XDMA 4.2 core, one physically routed RX/TX lane matching the supported X0Y0/GT channel mapping, a constrained 100 MHz differential reference clock, and a dedicated active-low PERST path. The current host platform is newer than Gen2, but exact root-port negotiated capability was not captured as a G0 proof.

The classification is not stronger because the current XCI is Gen1 x1; no Gen2 XCI/configuration was generated or checked; no Gen2 route/timing/DRC or 5 GT/s training exists; the repository lacks the board schematic, connector declaration and PCB signal-integrity/compliance evidence; host `LnkCap` is not frozen; no DMA payload exists; and R1i uses approximately 87.41% of LUTs. These are G1 and later validation constraints, not evidence of a required PCB redesign.

## Existing data-plane gap

The missing function remains `record/video data -> record-to-AXI-Stream adapter -> XDMA C2H -> host receive/correctness tooling`. The C2H IP interface exists, but application `tdata`, `tkeep`, `tlast` and `tvalid` are inactive/tied zero. One-channel DMA is missing/unproven, two-channel DMA is missing, and 288 MB/s is unproven.

## Remote source publication verification

All three new refs were pushed atomically without force and read back from a fresh isolated clone.

| Ref | Remote object/target | Verified resolution | Result |
|---|---|---|---|
| `baseline/v41-r1i-qualified-poc` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | tree `70d801fd7a879080da399bfa9ee95fd6eb008e16` | PASS |
| `v41-r1i-qualified-poc-20260827` | tag `f7847a259dbe43bf99fa6d6515ed85131fafffc0` | commit `20c3323d...`, tree `70d801fd...` | PASS |
| `v41-xdma-primary-donor-g0-20260827` | tag `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` | commit `c89e88bc...` | PASS |

Before/after remote branch snapshots differ only by the new authorized preservation branch. Every pre-existing branch retained its original head:

| Existing branch | Before | After |
|---|---|---|
| `archive/v41-xdma-pre-v40.1.0-20260817` | `f3cfa6bf72f3cdcc5688f3a28ff16e80afc5d875` | same |
| `archive/v42-ready-d3-r4-7707243` | `770724344ae35fb65f177c04b050f666e70439dc` | same |
| `archive/v42-ready-d3-r5-01acf49` | `01acf496b2b920c40f8564b08b9cefd9c7186e5a` | same |
| `dev/v41-xdma-offline-next` | `8464af66611f7c22b8a36a4aab915d598eedda3f` | same |
| `diag/v41-nvp-address-ack-probe-r1d` | `1beb70536d8e57305813f377a9e2c0e810b0bfc0` | same |
| `diag/v41-nvp-axi-clock-measure-r1` | `0af44dee3bc091eaff805704dd5c687eeaa01bbd` | same |
| `diag/v41-nvp-i2c-25khz-r1` | `f007dc172d43d30b02729755e60382f8ce3dbff4` | same |
| `main` | `be94f88ee8d179f12928ab791bdae27c22cd1762` | same |
| `release/v40.1.0-nvp` | `55ce0df41552bb74e0923f89eff43977b040f2e5` | same |
| `v41/xdma` | `f3cfa6bf72f3cdcc5688f3a28ff16e80afc5d875` | same |
| `v41/xdma-v40.1.0-base` | `c89e88bcdf389614c884fb129e8b2d42a585bccb` | same |
| New `baseline/v41-r1i-qualified-poc` | absent | `20c3323d79d3896edc586d6db1df7deee60f9e41` | authorized new ref |

Existing branch heads modified: `NO`.

## Evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Branch: `main`
- Directory: `v41-development-g0-baseline-freeze`
- Payload commit: `64eca0cfbb76593d7e875df7b3271651668cbe61`
- Payload directory tree: `2e6c37ca6e650b716a652a93dd55cfe51d58dcd8`
- Fresh-clone payload read-back: `PASS` (`origin/main` at the payload commit; 16 files present)
- Final receipt commit: the current Git commit containing this finalized report; its remote HEAD is verified after the non-force finalization push

## Final invariant audit

- Integration performed: `NO`
- XDMA XCI altered: `NO`
- Build performed: `NO`
- Vivado executed: `NO`
- Hardware accessed: `NO`
- Primary worktree modified: `NO`
- Existing branch heads modified: `NO`
- G1 started: `NO`

## Gate conclusion

Engineering G0 is `PASS`. Source-ref publication is `PASS`. Evidence publication and payload remote read-back are `PASS`. G1 input readiness is `READY`, with a hard stop after G0.
