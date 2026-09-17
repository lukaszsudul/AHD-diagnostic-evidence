# W3 change allowlist and independent diff review

**Result: PASS_AT_PRECOMMIT_SCOPE_GATE.** This is a read-only candidate audit; the final source commit and Git tree are pending the source freeze.

- Source worktree: `C:\FPGA\CONT1R3R4R6_W3_20260917T165535Z\source` on `diag/v41-g2b-w3-first-terminal-wait-delay-20260917T165535Z`; pinned parent HEAD `09cd7cbb426027acaefd0cf3989579b80a451f3a` and parent tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`.
- Current complete non-ignored worktree file-content manifest SHA-256: `0E775E2495349B7F47E3688ED3161D68CEEEB0CD59851611ACCFF68BA144CA51` over 342 files (326 tracked, 16 new). The byte-exact path/size/SHA list is `SOURCE_WORKTREE_SHA256_MANIFEST.txt`. This is a SHA-256 content snapshot, **not** a Git commit or tree ID.
- Final W3 source commit: `PENDING`; final W3 Git tree: `PENDING`.
- Exactly 4 modified tracked files and 16 new files; no staged, deleted, renamed, or outside-allowlist path. `git diff --check` passed.

## Exact changed and new source paths

| Status | Path | Bytes | SHA-256 |
|---|---|---:|---|
| new | `host/w3/__init__.py` | 198 | `4DCC74C049D71CD730D5291C9DA5A42C5DF80FC82EFF00588B7F87F1BC6F39AD` |
| new | `host/w3/contract.py` | 2325 | `DF72D344A97FB1372FB6DF2795389A586DFB6982AA11B613C4ABCFEA776BDF00` |
| new | `host/w3/controller.py` | 9176 | `F10522D8610E229882504D4522BC9F1365AA5A3B9B2CBDB315A3F7DDE1F5E68A` |
| new | `host/w3/decoder.py` | 12319 | `7E95870A624A4613AFCA19DCD01B18190014AA8C0BB7752EC4C4CB5E518FB3D8` |
| new | `host/w3/device.py` | 5685 | `E31CF884F3F16F9D7F51EE4EBB04630E41267665A078D94BDF9583C7CB8AE7C8` |
| new | `host/w3/resources/W3_CONTRACT.json` | 17783 | `99868A4ECE2D859DA16224408F289EBEACE1F63315622109CBCEA9C4776A07B7` |
| new | `host/w3_launcher.py` | 2983 | `B2FCAD576C89BABCBCC30E4BACFA5EC812E263A3236CB76567F2A45C8D25C7D7` |
| modified | `rtl/g2b/g2b_nvp_camera_scan1.sv` | 44333 | `46488440CC33FEB9A4CD7FC34F727D87D3F3302D91FC691B1749B67DA5BF0855` |
| modified | `rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` | 6658 | `FA67D7ADFE83A98585E591200445ABC11587BC199A8CFECDD20C5DBDFAF13026` |
| new | `rtl/g2b/g2b_nvp_camera_w3_telemetry.sv` | 50568 | `E545FB629F3269168C626E7768A4EEA1D77EE7409439D84ED250D6DA71FEA587` |
| modified | `rtl/top/ahd_capture_top_xdma.sv` | 72464 | `4E465A004CE334F29D70CCF3B63253B8AA86CAC4ACB2DDA1C7A6499ED2BF53FA` |
| modified | `rtl/v41/nvp_i2c_fixed_master.sv` | 22100 | `62F2383B3F6E72FB2FCF513A28ABA2D0A34E388DB159FB747CEBE8F803FA73B9` |
| new | `tests/w3/tb_w3_delay_negative.sv` | 19647 | `C6EB3C2C39ED7DF3B85B661F2AC9C4856D5300D2A7237D9E303DF1CD49E29928` |
| new | `tests/w3/tb_w3_delay_scan.sv` | 15535 | `39D257C42F60A6F9C192F52DD7151F6FD0C3EC3F4140DB8AB65350D6112CD5BD` |
| new | `tests/w3/tb_w3_master_parent_equivalence.sv` | 6808 | `FA31D3C58AB794A04C28C7896D8CD23B5003FF21DCB073579BE7116F5EF1003E` |
| new | `tests/w3/tb_w3_master_saturation.sv` | 4192 | `55BBAB7CCFAEB7BCEB4154428A080DADEA8D18A25E382139E44274B22DE6D875` |
| new | `tests/w3/tb_w3_master_telemetry.sv` | 14511 | `3E54C1B6DED7CAC384D2897F0D316C469F296DAFCBE4F087C33C5FAAD153336C` |
| new | `tests/w3/tb_w3_scanner_mmio.sv` | 54076 | `9A2BA0BCF3A7FA67C91B426D78F9FF920D052D9DE4ABEC758BB406F1101ED93F` |
| new | `tests/w3/tb_w3_t18_t23_record.sv` | 17770 | `15BB5000FA8C3F497E7775B58413A9B8E971B91B0B31B54876570713BCCC8821` |
| new | `tests/w3/test_host_w3.py` | 10853 | `7696FF988E33D88DBDC98C8018A448849614E14DDA0321302529F60588196070` |

## Scope of tracked changes

The full four-file Git diff against the exact parent was reviewed. The fixed master adds observation signals and capture logic; its pre-existing transaction FSM, divider, timeout, SDA/SCL drive, ACK and STOP branches are unedited. The scanner adds the W3 telemetry instance, additive page read selection, guarded control/pause logic after successful scanner bank writes, and a bounded armed-block writer-drain admission gate. The scanner/ACQ wrapper extends only SCAN1 address decode to `0x147FF` and carries new signals; its ACQ address decode and arbitration branch are unchanged. Top-level edits carry the same signals, reset and additive SCAN1 page decode; PCIe/DMA datapath and existing ACQ outputs are unchanged. New files are confined to W3 telemetry, host decoder/controller/schema/launcher, and W3 tests.

## Immutable input byte checks

All 75 selected immutable tracked files are byte-identical to pinned parent `09cd7cbb426027acaefd0cf3989579b80a451f3a`. Each worktree SHA-256 was compared independently with `git show 09cd7cbb426027acaefd0cf3989579b80a451f3a:<path>` bytes; `git diff --quiet HEAD -- <all immutable paths>` also passed. The individual current and parent SHA-256 values are in `IMMUTABLE_SOURCE_SHA256.json`. Category coverage:

| Category | Files |
|---|---:|
| `ACQ_functional_executor` | 1 |
| `IP_XCI` | 4 |
| `XDC_pins_timing_CDC` | 9 |
| `autoinit_table_profile` | 10 |
| `driver_control_scripts` | 2 |
| `inherited_build_IP_config_scripts` | 20 |
| `legacy_manifest_and_scanner_host` | 20 |
| `legacy_projection_and_telemetry` | 9 |

Selected release-sensitive hashes:

| Path | SHA-256, current = pinned parent |
|---|---|
| `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json` | `ED83A3675FC8E869D53D967270517BC2DDCE71CCB34A8D98A16B4758B5B12F5E` |
| `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json` | `C6FC4C3C794CE41D58B0D332551A08196C8F0C92F08667FDB09A549FF4A08D3E` |
| `host/cont1r1_projection.py` | `46DD0D28658190FC7DDF66D60DEB525F187B23DAAAB35C4FB24EC405E0B5D1C9` |
| `host/cont1r3/projection.py` | `CC26781A94D78B95F06AFAAD4116ADF27C3BAD3834C328E907085855A49C5794` |
| `host/cont1r3/resources/CONT1R3_TELEMETRY_SCHEMA.json` | `438D630943B0D3A2BFCB2C23B9FB060FD0C347C16F331D008997DBB3B8B22F95` |
| `host/scan1/manifest.py` | `9406245BE89D0765ABCFD3810D69ECBF28C1976731851BB076FB4B737B9FAACF` |
| `host/scan1/resources/G2B_NVP_CAMERA_SCAN1_R1_READ_MANIFEST.json` | `69C6C3518A737C33E5DBC654D20616D5FEC4B9A828EA5CE52061001D564112B5` |
| `host/v41/phase2_load_xdma_driver.sh` | `7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F` |
| `ip/ila/capture_ila.xci` | `32475BC46005E551F91A734EFFEF1FE8B9D896FE0C19BF6D8CF2DB8633C05D3D` |
| `ip/pcie/pcie_endpoint.xci` | `8EC53E693D1E28231EC97A5FF94F6AC815451E89DE4978E7F59AFFC46A7FB414` |
| `ip/v41/xdma_v41_m1.xci` | `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F` |
| `ip/vio/control_status_vio.xci` | `F142DCD7C5D8753A91468355E702FC3EA5E25A378CE3CAA41AB3A7BAB33D5912` |
| `rtl/g2b/g2b_nvp_acq1_compat0_r2.sv` | `79792717C8AAB7659692DC8ACD04F2B9C74B1D3FD522179F71CEEA307177E70C` |
| `rtl/g2b/g2b_nvp_camera_scan1_manifest_pkg.sv` | `F21EE3718F84304DD40D29B0A5FE95BBBA15336D9B7BD642177B950CF7598DD6` |
| `rtl/nvp/nvp6134c_autoinit.vhd` | `FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| `rtl/nvp/r1f_transaction_serial_counter.vhd` | `FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E` |
| `scripts/v41/g2b_build.tcl` | `1E22B28DC32314E10721CD8358FDE15011B196508CDB708EB0DB630FEA6BD072` |
| `xdc/boards/current/nvp_control.xdc` | `B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318` |
| `xdc/boards/current/pcie_pio.xdc` | `BE7BFB70921AD272661071408C0820B4EC4BB60AB7C1102340011E57D8BE8503` |
| `xdc/boards/current/pins.xdc` | `A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9` |
| `xdc/boards/current/vdo_input_timing.xdc` | `6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78` |
| `xdc/boards/current/xdma_pcie.xdc` | `65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A` |
| `xdc/common/cdc.xdc` | `E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62` |
| `xdc/common/configuration_bank.xdc` | `3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68` |
| `xdc/common/g2b_cdc.xdc` | `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE` |
| `xdc/vendor/pcie.xdc` | `7C2A218EDC4C8F98B20BE6CC869312FCE65EB8C1365BBFCBCEE077A32BDCAEDE` |

The qualified external driver binary identity remains the pinned authority SHA-256 `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`. No binary is present in this source worktree for a fresh byte read; the inherited driver-loading script above is byte-identical to the parent. No driver action occurred in W3.

## Primary checkout boundary

`C:\FPGA\FPGA_AHD` remains on `main` at HEAD `be94f88ee8d179f12928ab791bdae27c22cd1762` with clean tracked and staged diffs. W3 `host/w3`, launcher, telemetry module and tests paths are absent there. The checkout contains pre-existing untracked `.codex_tmp/` and `reports/`; this audit did not mutate or baseline those unrelated bytes. The W3 candidate was edited only in its isolated worktree.

This scope gate does not replace the final post-commit tree/hash check or the separate build and routed sign-off gates.
