# AHD v41 G2A Provenance Preflight

## Result

`PASS — EXACT QUALIFIED R1i BASE VERIFIED`

The mandatory base-tree check completed before any product-source edit. Commit `20c3323d79d3896edc586d6db1df7deee60f9e41` resolves to tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`, exactly matching the frozen G1/Owner contract. `G2A_BASE_TREE_MISMATCH` did not occur.

Date: `2026-08-27`  
Hardware access: `NONE`  
G2B activity: `NONE`

## Final sealed integration identity

The preflight facts above remain the edit-entry authority. After the authorized implementation and the exact-signature CDC build-gate correction, the source candidate was sealed as follows:

| Item | Sealed value | Result |
|---|---|---|
| Integration branch | `integration/v41-r1i-gen2-g2a` | PASS |
| Integration commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` | PASS |
| Integration tree | `283f98c02e6f9c61716875415cf000682f8ab856` | PASS |
| Direct parent | `20c3323d79d3896edc586d6db1df7deee60f9e41` | PASS |
| Final worktree status | clean | PASS |
| Changed-file count | four, exactly matching the authorized allowlist | PASS |
| `G2A_SOURCE_DIFF.patch` SHA-256 | `BD2796E63CDBBA0AE974691F5F0A6511CBE9B23DE9CA369C9AA24A4837E449A2` | PASS |
| `scripts/v41/g2a_build.tcl` SHA-256 | `5817A5A6B80C1DD99B3270FC4625131582207C21CED3CEB2B3461D6BC92D2E28` | PASS |
| `tests/v41/run_g2a_offline_checks.ps1` SHA-256 | `C42993C7833DD51078F0A054C6456F0B023DF2FC56FDC7319297427746B6E73A` | PASS |
| Hardware accessed | NO | PASS |
| G2B started | NO | PASS |

## Source and target isolation

| Item | Verified value | Result |
|---|---|---|
| Source preservation branch | `origin/baseline/v41-r1i-qualified-poc` | PASS |
| Source branch commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` | PASS |
| Source tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` | PASS |
| Immutable source tag object | `f7847a259dbe43bf99fa6d6515ed85131fafffc0` | PASS |
| Immutable source tag peeled commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` | PASS |
| Target branch | `integration/v41-r1i-gen2-g2a` | CREATED FROM IMMUTABLE TAG; SEALED AT `224d194e...` |
| Isolated product worktree | `<SOURCE_ROOT>` / canonical `<SOURCE_ROOT>` | PASS |
| Isolated evidence directory | `<PRIVATE_EVIDENCE_ROOT>` | PASS |
| Integration worktree initial status | clean, no tracked or untracked changes | PASS |

The integration worktree was created directly from `v41-r1i-qualified-poc-20260827`. No donor merge, R-track merge, cherry-pick, or transplant was performed.

## Primary worktree preservation

| Item | Verified value | Result |
|---|---|---|
| Primary worktree | `<PRIMARY_WORKTREE>` | PASS |
| Primary branch | `main` | PASS |
| Primary HEAD | `be94f88ee8d179f12928ab791bdae27c22cd1762` | PASS |
| Primary tree | `e128ff47a5e21e8131971f5e5caa7657e2eccc7f` | PASS |
| Primary status before G2A edits | clean, including untracked files | PASS |
| Primary content modified by G2A | NO | PASS |

Fetching the authoritative remote-tracking refs and annotated tags changed Git metadata only; it did not alter primary worktree content.

## Authoritative donor and G1 identities

| Authority | Branch/tag/commit | Verified identity | Result |
|---|---|---|---|
| Primary XDMA donor branch | `origin/v41/xdma-v40.1.0-base` | `c89e88bcdf389614c884fb129e8b2d42a585bccb` | PASS |
| Primary XDMA donor tag object | `v41-xdma-primary-donor-g0-20260827` | `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` | PASS |
| Primary donor tag peeled commit | `v41-xdma-primary-donor-g0-20260827^{}` | `c89e88bcdf389614c884fb129e8b2d42a585bccb` | PASS |
| Secondary provenance donor | `origin/dev/v41-xdma-offline-next` | `8464af66611f7c22b8a36a4aab915d598eedda3f` | PASS |
| Primary donor ancestry | `c89e88bc...` ancestor of R1i | yes | PASS |
| Secondary donor ancestry | `8464af66...` ancestor of R1i | yes | PASS |
| Frozen G1 evidence commit | `f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd` | exact | PASS |
| Frozen G1 evidence tree | — | `769b930e643205e769ff97c4d49ffa040109c875` | PASS |
| Qualified R1i bitstream | public frozen `R1I_POC.bit` | SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | PASS |

The R1i `scripts/v41/phase3_build.tcl` blob and secondary-donor blob are both `b908146795f6bf0033a4e2ae211208ff20532583`; therefore the reviewed secondary provenance logic is already inherited, and only its frozen intent will be ported into the new G2A-specific harness.

## Authorized and realized changed files

No product-source edit is authorized outside this complete list:

| File | Classification | Authorized and realized change |
|---|---|---|
| `ip/v41/xdma_v41_m1.xci` | `GEN2_REQUIRED` | Change only `CONFIG.pl_link_cap_max_link_speed` from `2.5_GT/s` to `5.0_GT/s`. |
| `scripts/v41/xdma_config_common.tcl` | `GEN2_REQUIRED` | Apply the same speed change and add read-only frozen-property assertion/dump support required by G1. |
| `scripts/v41/g2a_build.tcl` | `PROVENANCE_HARDENING` | New G2A harness using the exact R1i source oracle and qualified build flow, with the approved provenance-mode/round-trip/receipt/early-exit intent plus required G2A reports and hard gates. Its CDC correction dispositions only the exact generated XDMA Gen2 PIPE-clock signature; it provides no broad CDC waiver. |
| `tests/v41/run_g2a_offline_checks.ps1` | `PROVENANCE_HARDENING` | New offline contract runner for protected identities, MMIO/telemetry, C2H/H2C tie-offs, XDMA invariants, provenance positive/negative tests, conflict-leakage checks, and the exact-signature/no-broad-waiver harness markers. |

Generated IP output products will not be hand-edited or committed. Evidence, reports, bitstream, LTX/probe output, logs, journals, DCPs, and manifests will remain outside the proprietary product branch.

## Expected immutable files

Every tracked file not named in **Planned changed files** is immutable for G2A. The following critical oracles and ownership anchors are explicitly sealed.

### Protected R1i oracles

| Path | Git blob at R1i | SHA-256 |
|---|---|---|
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `3757acf2677d0a13b31a285095c38cc7b30e567c` | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| `rtl/nvp/nvp6134c_autoinit.vhd` | `ec070a399d16ce3370469ee1b0079c153a39b5c1` | `FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `7ddd60fc86da49cda1adcd7af7b772b337c95df6` | `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |
| `rtl/nvp/r1f_transaction_serial_counter.vhd` | `58c6d7cfdddc23ebde8ccafa75d4c2bc40839e96` | `FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E` |
| `rtl/top/ahd_capture_top_xdma.sv` | `d04ff833994bc83e29647c0a7cce4cc941c3410e` | `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4` |
| `rtl/v41/control_status_regs.sv` | `16fc122686a7c11f99c5bc9750dad586d713e05f` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |
| `scripts/v41/r1i_build.tcl` | `843d644d1214bb2bc56b6afe50a42231df234ebc` | `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F` |
| `scripts/v41/phase3_build.tcl` | `b908146795f6bf0033a4e2ae211208ff20532583` | `D7531F2B12B5CCBF91484C8A28182B0C0FCF71C93277A697F2D6793338DA8440` |
| `tests/v41/run_r1i_focused_sim.ps1` | `47fc3c65b3b73976a41b2821a4606d7ad10a2695` | `D7950823C8145B4059FD1E9DF9BA4BFDCAEA38ED97E9AF213840CDA08264704B` |
| `tests/v41/tb_r1i_poc_mmio.sv` | `98a2ea8b63a97315a34b04357682a8390de48e33` | `50B71609A30B4A3FF5D92FA88439729CF2A0B9CBBE30AF78FDB5C8DFE94FA062` |
| `tests/v41/tb_r1i_qualified_ack_readiness.sv` | `a73020fa8631306584000f9b4351a7eed7ef78ec` | `75B7B5B330CB4CCB41234E91BE56633A0EBA1944CB28A9F13BD48AA718B2143B` |
| `tests/nvp/tb_power_timing.vhd` | `a50a65859d537e3adeafe01b2ddaf0373a7a8979` | `367557E9A505AAC0BDA8F8C5B3D71DB2E7B5EA497A6198D4812AB26F5EF80715` |
| `tests/nvp/tb_nvp_autoinit.vhd` | `5d6465f4fd8d8ddf81c0ea026a413c50ec4609f1` | `FD978BCF86A25B1E12CB5985FD29BA492E8A4F17306F2714896E4A6A295EF495` |

### Primary-donor anchors inherited byte-for-byte by R1i

The primary-donor and R1i Git blobs match for all of these files:

- `ip/v41/xdma_v41_m1.xci` — `5065b919254fe164ac831192b93c29734737b859`
- `scripts/v41/xdma_config_common.tcl` — `c79175e13ad7c94b03af3cbe80684b27de123c0b`
- `rtl/v41/axi_lite_host_bridge.sv` — `fde2499259d98da8c28ed26548032ebffb648007`
- `rtl/pio/pio_slot_adapter.sv` — `ccadf36ae16222977cc0571b242ff4037bbf117b`
- `rtl/pio/pio_bar_target.sv` — `1ab24dace7534d4c42d860e9234024440cb69f39`
- `rtl/record/bt656_record_producer.sv` — `7f39fa16a89a3c6e84c0644c624ea676d9fe3877`
- `rtl/record/capture_mailbox.sv` — `f4817decf75d3e126e16d393f6a0ca67f770cc31`
- `rtl/video/video_capture.sv` — `f3ec93c3e39de5288c138801132686e459c06778`
- `rtl/video/physical_frontend.sv` — `c11ea4de8493a14601d4ebfe627f9a318220bef6`
- `xdc/boards/current/xdma_pcie.xdc` — `810e0fa4e617dd66380cf1be5183203d064c69b6`
- `xdc/boards/current/pins.xdc` — `e73cd864c734774df2e47e747e142ae9075b2189`
- `xdc/boards/current/vdo_input_timing.xdc` — `3cb8a6dd2458c16113ee91a72bbc977b34f2f190`
- `xdc/boards/current/pcie_pio.xdc` — `6f0848148d5b104551cd1466bb0d9cc458b6b1d4`
- `xdc/boards/current/nvp_control.xdc` — `2e4a6f56d5dfa227a968492fe4476d25721f09f9`
- `xdc/common/cdc.xdc` — `3ca910b2203f2a4447a96d8e73e6142b338de815`
- `xdc/common/configuration_bank.xdc` — `64b554546504f911e3988e1bfa1e964292a7b85d`

## Tool and workspace preflight

| Item | Verified value | Result |
|---|---|---|
| Vivado | `v2025.2 (64-bit)` | PASS |
| Vivado SW Build | `6299465` | PASS |
| Vivado IP Build | `6300035` | RECORDED |
| Target part | `xc7a35tcsg325-2` | PASS |
| Top | `ahd_capture_top_xdma` | PASS |
| Canonical mapping | `V:\` maps to `<FPGA_WORKSPACE>` | PASS |
| Canonical source path | `<SOURCE_ROOT>` | PASS |
| Tcl app repository | `C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore` exists | PASS |
| Child-only local user data | `XILINX_LOCAL_USER_DATA=NO` | PLANNED/ENFORCED AT LAUNCH |
| Child-only temp | `TEMP=TMP=<TEMP_ROOT>` | ENFORCED BY THE FINAL R2 LAUNCH RECEIPT |

## Preflight conclusion

The G2A base, tag, branch, tree, bitstream, donor identities, donor ancestry, G1 evidence, protected sources, inherited donor substrate, clean isolation, and tool identity all pass. The completed source candidate is the clean direct child `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`, and contains exactly the four authorized changed files above. No protected R1i ref or primary-worktree content was modified.
