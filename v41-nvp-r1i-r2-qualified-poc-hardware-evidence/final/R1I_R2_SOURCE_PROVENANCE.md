# R1i–R2 Source Provenance

## Proven identities

| Item | Identity |
| --- | --- |
| Source repository | `lukaszsudul/FPGA_AHD` |
| Internal physical repository path | `[REDACTED_PERSONAL_PROFILE_PATH]/AHD_V41_CANONICAL_20260826T210038Z/R1I_R2/FPGA_AHD` |
| Build-time canonical workspace | `V:/R1I_R2/FPGA_AHD` |
| Candidate branch | `diag/v41-nvp-r1i-r2-qualified-ack-readiness-poc` |
| Exact R1h base commit/tree | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` / `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| Qualified R1i commit/tree | `20c3323d79d3896edc586d6db1df7deee60f9e41` / `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Working-tree state used for build | Clean; fully committed; 232 tracked files |
| FPGA part | `xc7a35tcsg325-2` |
| Top level | `ahd_capture_top_xdma` |
| Vivado | 2025.2 build 6299465 |
| Build flags | `0x00000002` |
| Qualified bitstream | `ahd_capture_v41_i2c_25khz_r1i_qualified_ack_readiness_poc.bit` |
| Bitstream SHA-256 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |

The commit range contains two commits: `94fa9e77ae58b791ebd884f767a26063fcf38e0a` (functional PoC) and `20c3323d79d3896edc586d6db1df7deee60f9e41` (child-local portable Vivado environment). Freeze receipts prove the canonical worktree was clean before and after the build. Source-to-bitstream provenance is therefore **PROVEN**.

## Candidate file hashes

| File | SHA-256 |
| --- | --- |
| `rtl/nvp/nvp6134c_autoinit.vhd` | `FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| `rtl/top/ahd_capture_top_xdma.sv` | `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4` |
| `rtl/v41/control_status_regs.sv` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |
| `scripts/v41/r1i_build.tcl` | `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F` |
| `scripts/v41/r1i_vivado_portable_launch.ps1` | `78166A16F2B0B75A837716CECDD4591B2D4464805E27E71B2210C286648D948F` |
| `scripts/v41/read_nvp_r1i.py` | `E217F3BE39CFF3A04178487EF8C4B2780DB8421CAFDB47A347DE31A65F080934` |
| `tests/python/test_nvp_r1i_tools.py` | `4455DC450189264D6B762B7A389D9869E73213F92D55B2EF380513DBDF172C8D` |
| `tests/v41/r1i_master_test_adapter.vhd` | `0A4948D6FCD444015DB56772B455FF45F62862F754E5022478547A4954830711` |
| `tests/v41/run_r1i_focused_sim.ps1` | `D7950823C8145B4059FD1E9DF9BA4BFDCAEA38ED97E9AF213840CDA08264704B` |
| `tests/v41/tb_r1i_poc_mmio.sv` | `50B71609A30B4A3FF5D92FA88439729CF2A0B9CBBE30AF78FDB5C8DFE94FA062` |
| `tests/v41/tb_r1i_qualified_ack_readiness.sv` | `75B7B5B330CB4CCB41234E91BE56633A0EBA1944CB28A9F13BD48AA718B2143B` |

## Unchanged constraints and IP identity

No XDC, XDMA XCI, or shared XDMA configuration file changed from R1h to R1i.

| File | SHA-256 |
| --- | --- |
| `xdc/boards/current/xdma_pcie.xdc` | `65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A` |
| `xdc/boards/current/pins.xdc` | `A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9` |
| `xdc/boards/current/vdo_input_timing.xdc` | `6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78` |
| `xdc/boards/current/pcie_pio.xdc` | `BE7BFB70921AD272661071408C0820B4EC4BB60AB7C1102340011E57D8BE8503` |
| `xdc/boards/current/nvp_control.xdc` | `B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318` |
| `xdc/common/cdc.xdc` | `E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62` |
| `xdc/common/configuration_bank.xdc` | `3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68` |
| XDMA XCI | `EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C` |
| `scripts/v41/xdma_config_common.tcl` | `3A76FC7893B2188871B340E326B53C7EE39B93C19EF416EAD2611CA9FDA9CDC7` |

The exact, path-limited source delta is [R1H_TO_R1I_SOURCE.patch](R1H_TO_R1I_SOURCE.patch). No LTX/probe file was produced or required; the qualification used MMIO/BRAM instrumentation.
