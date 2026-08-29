# AHD v41 G2B-IMPL Source Identities

## Source disposition

The G2B implementation source is an exact, manifest-sealed **uncommitted worktree** based directly on the accepted G2A commit. No G2B integration commit was created because the mandatory clean build gate was blocked by post-opt LUT utilization.

| Item | Identity |
|---|---|
| Repository | AHD FPGA source repository |
| Integration branch | `integration/v41-g2b-onech-c2h` |
| Current repository HEAD | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Current repository HEAD tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Accepted G2A base commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Accepted G2A base tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Merge base with accepted G2A | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Direct-base relationship | `PRECOMMIT_HEAD_IS_ACCEPTED_G2A_BASE` |
| G2B integration commit | `NONE` |
| G2B integration commit count | 0 |
| Source identity kind | `MANIFEST_SEALED_UNCOMMITTED_WORKTREE` |
| Source clean | `NO` |
| Precommit input manifest lines | 34 |
| Precommit input manifest SHA-256 | `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587` |
| Source identity after failed resource gate | PASS |

The source generic embeds the accepted G2A repository HEAD words and uses `BUILD_FLAGS=32'h00000003`: dirty-source identity plus verified-manifest identity. These generic words identify the repository base, not the complete uncommitted implementation; the SHA-256 manifest is the complete build-input identity.

## Frozen inputs

| Frozen input | Identity |
|---|---|
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1 |
| Frozen G2B-PRE evidence directory | `v41-development-g2b-pre-c2h-abi-mmio-freeze` |
| Accepted G2B-PRE evidence commit | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| MMIO window | `0x3800..0x3BFF` |
| SSOT promotion evidence directory | `v41-meta-project-state-rev2-g2b-pre-promotion` |
| META evidence commit | `4452f6b4293bd4e4267f81c7c8d42cac3f14fd83` |
| Project-state revision at task start | 2 |
| Qualified R1i commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Qualified R1i tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Qualified R1i tag | `v41-r1i-qualified-poc-20260827` |

## Exact sealed build-input manifest

The pre-build and post-failure manifests are byte-identical and both hash to `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587`.

| Build input | SHA-256 |
|---|---|
| `rtl/v41/axi_lite_host_bridge.sv` | `D94BE3FC0AE7D9DDEC87DF4289277BDE5F3AEE2597F02AC2CE19EF9C4EDB890E` |
| `rtl/v41/axi_clock_lifecycle_monitor.sv` | `EC96D90784F5CF60C348CA1798340F79B3A067504D0A1F42DD8EF318810B4B9B` |
| `rtl/v41/axi_clock_measurement_regs.sv` | `CF0DDDB78B8C54F9D0597B67A2536B802B0B9949A029314C9E74A5795FC5A28B` |
| `rtl/v41/r1e_measurement_regs.sv` | `034F8C63258CA6436817CFFE1605CDF23EF04030047CCE36146E115F3C374939` |
| `rtl/v41/r1h_probe_index_bram_store.sv` | `67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F` |
| `rtl/v41/nvp_i2c_tri_phase_probe.sv` | `D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD` |
| `rtl/v41/r1f_failed_txn_logger.sv` | `F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761` |
| `rtl/v41/r1f_measurement_regs.sv` | `EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542` |
| `rtl/v41/r1h_mmio_read_service.sv` | `00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B` |
| `rtl/v41/control_status_regs.sv` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |
| `rtl/pio/pio_slot_adapter.sv` | `96B8E53B23295A9C8B597EF15E10DA819962E3F96B45FB02F6E472B108720CEE` |
| `rtl/pio/pio_bar_target.sv` | `E6BED9C57D5A79E4D2AD2C5E3CEEFCD4AEDCCC9CEA77A61C6A84F350FE6FF833` |
| `rtl/record/bt656_record_producer.sv` | `96ECA58AC2FE6D9A2E0A390076FA02370B85409F1F1353CB9F41784D2ED363EE` |
| `rtl/record/capture_mailbox.sv` | `91A55EC1DEE546F026E3DC92F04A788A779F8A3F8D9D3D8DABEF08F089CA3FF5` |
| `rtl/video/video_capture.sv` | `7DFB7253C6649885665DB8449E33CE2F31D584811586DAEAA746DE04DF4AFFC9` |
| `rtl/video/physical_frontend.sv` | `3F4BD5FC715E409C1FA0B6F3B3F13A825F892F0BCE61F880C73B0401417C3347` |
| `rtl/g2b/v41_g2b_mmio_router.sv` | `2C4B4B037116447DAF12FF1C78D7C9096BD77D14F6E2CB59EF2ABC9CB806BE25` |
| `rtl/g2b/v41_g2b_onech_c2h.sv` | `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471` |
| `rtl/top/ahd_capture_top_xdma.sv` | `E8AD4F54E6F3E91CC22E117318A6CF1D865700C5A4FFA701DEFA179BC7F32E57` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |
| `rtl/nvp/r1f_transaction_serial_counter.vhd` | `FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| `rtl/nvp/nvp6134c_autoinit.vhd` | `FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5` |
| `xdc/boards/current/xdma_pcie.xdc` | `65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A` |
| `xdc/boards/current/pins.xdc` | `A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9` |
| `xdc/boards/current/vdo_input_timing.xdc` | `6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78` |
| `xdc/boards/current/pcie_pio.xdc` | `BE7BFB70921AD272661071408C0820B4EC4BB60AB7C1102340011E57D8BE8503` |
| `xdc/boards/current/nvp_control.xdc` | `B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318` |
| `xdc/common/cdc.xdc` | `E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62` |
| `xdc/common/g2b_cdc.xdc` | `CF04780F16EDAD391393D15E6033E96EC89CC3CE31A6DF48ADF1C05408FA5246` |
| `xdc/common/configuration_bank.xdc` | `3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68` |
| `ip/v41/xdma_v41_m1.xci` | `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F` |
| `scripts/v41/xdma_config_common.tcl` | `4B240CE27E4C8065C897EF4D184EC7EB97BB1CF4BF747C1E06F92ED3A9AE2162` |
| `scripts/v41/g2b_build.tcl` | `7A1AAAC56ADFED64F9CA7A731EF5B6E2F870701FF798AAEBE6E48107D23EE13C` |

## Focused verification and host-tool source identities

These files are qualification fixtures or offline tools and are not synthesized into the FPGA image.

| File | Bytes | SHA-256 |
|---|---:|---|
| `tests/g2b/tb_v41_g2b_onech_c2h.sv` | 96,983 | `551D9E1766D5EDF571CCE5C06817572D4DD5DE5677D64FB9E78066A431176CD3` |
| `tests/g2b/run_g2b_onech_c2h_xsim.ps1` | 8,451 | `3EE7581C1C88C42CD262869CC2088FE5AFC49933936FE3D0094B46685BC8140E` |
| `tests/g2b/tb_v41_g2b_mmio_router.sv` | 7,230 | `A4A1E770E55643B3D682C93D7822EEAE634610FED055107A42711AFD0751AF50` |
| `tests/g2b/run_g2b_mmio_router_xsim.ps1` | 5,568 | `205616A966CD3B03AE3698EB0095C07DD22C5BF64A6E9ED8BDD5C46015631992` |
| `host/tools/g2b/__init__.py` | 578 | `0701AEAF6A8E0A5FF3EF9D954B7EAE81A423957EDED88428F97AB81EA1AC5135` |
| `host/tools/g2b/abi_v1.py` | 30,488 | `2939FC522A2D9679BB720F287AC022FC48FF042CE06E20877F8E686F35909F1E` |
| `host/tools/g2b/g2b_offline.py` | 18,641 | `C35E5616F61724D342C451220829742A4B7F6D4D7E5C438A3F1C8767E5E9B04C` |
| `tests/python/g2b_rtl_golden_check.py` | 6,774 | `59679C398D71455DAC693D64D0B1EA701697629C523A6373AACC852CB3E0FDBA` |
| `tests/python/test_g2b_host_tools.py` | 17,611 | `5479DB87055C8B91A05401A7BC56E62EFED57333F070FB54AEAA7E8F984F67A0` |

## XDMA preservation identity

The accepted G2A XDMA XCI and its common configuration Tcl are unchanged in the G2B worktree. Both paths are clean relative to repository HEAD.

| XDMA item | Identity |
|---|---|
| XCI path | `ip/v41/xdma_v41_m1.xci` |
| XCI SHA-256 | `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F` |
| XCI accepted-base Git blob | `450aa334e2bda4396cd5a7270ba15895c7f7ed54` |
| Build-local XCI SHA-256 | `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F` |
| Common configuration path | `scripts/v41/xdma_config_common.tcl` |
| Common configuration SHA-256 | `4B240CE27E4C8065C897EF4D184EC7EB97BB1CF4BF747C1E06F92ED3A9AE2162` |
| Common configuration accepted-base Git blob | `ea9c2b5a463e6c4e15743d53abab734ba5fdf516` |
| Effective configuration report SHA-256 | `7FE9FF23092C37128CFC4C42E7DBCCD0F966E6BE876FAAADCC0E35E46AD4532C` |
| Effective property count | 1001 |

Selected effective properties are unchanged: PCIe target 5.0 GT/s x1, AXI data width 64 bits, `axisten_freq=62.5`, AXI-Lite master enabled, and PF0 BAR0 enabled as a non-prefetchable 32-bit 128 KiB memory BAR. These are build-time configuration identities, not runtime link or hardware-throughput proof.

## Commit and access boundary

- Integration commit: `NONE`
- Integration tree for G2B implementation: `NONE`
- Bitstream identity: `NONE`
- Evidence publication commit from this documentation action: `NONE`
- Network accessed: `NO`
- Hardware accessed: `NO`
- FPGA programmed: `NO`
- Hardware DMA executed: `NO`

The resource blocker prevented the required “tests plus clean build PASS” precondition for an implementation commit. The exact uncommitted source remains identifiable by the sealed manifest, but it must not be labeled `OFFLINE_QUALIFIED_G2B_CANDIDATE`.
