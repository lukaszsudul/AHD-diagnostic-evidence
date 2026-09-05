# DCP reuse proof — PASS

DCP_REUSE_VALID = YES
RECOVERY_MODE = ROUTED_DCP_REUSE
FULL_REBUILD_EXECUTED = NO

Exact sealed DCP size/hash verified in start.json. All 34 non-XDC entries of the 35-input Gen12 manifest match current source. The manifest hash is 0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD. The sole changed build input is g2b_cdc.xdc. All source changes after accepted recovery-1 source 66cc8e3 affect only that XDC. The original Gen12 was a precommit build; no inference that its parent commit alone contains the complete build sources is made.

The Gen12 project file matches its accepted hash 204E26DCC659EACC973A9F17D5C92863830CDFCD4770855E67E4724067BB044E, binding source set, top ahd_capture_top_xdma, part xc7a35tcsg325-2 and PRODUCT configuration. Generated PCIe XDC matches DD00E1DA9D2CAA6F27EBA21DB3BB6F73FC16A6F75C18C3394DB93430C815916B. The XDMA XCI is exact. No RTL, generated IP configuration, source set, top, profile or part change exists. The exact sealed DCP preserves its routed netlist and physical implementation; only timing constraints are reloaded.

Build inputs:
```json
[
  {
    "path": "rtl/v41/axi_lite_host_bridge.sv",
    "sealed": "D94BE3FC0AE7D9DDEC87DF4289277BDE5F3AEE2597F02AC2CE19EF9C4EDB890E",
    "current": "D94BE3FC0AE7D9DDEC87DF4289277BDE5F3AEE2597F02AC2CE19EF9C4EDB890E",
    "match": true
  },
  {
    "path": "rtl/v41/axi_clock_lifecycle_monitor.sv",
    "sealed": "EC96D90784F5CF60C348CA1798340F79B3A067504D0A1F42DD8EF318810B4B9B",
    "current": "EC96D90784F5CF60C348CA1798340F79B3A067504D0A1F42DD8EF318810B4B9B",
    "match": true
  },
  {
    "path": "rtl/v41/axi_clock_measurement_regs.sv",
    "sealed": "CF0DDDB78B8C54F9D0597B67A2536B802B0B9949A029314C9E74A5795FC5A28B",
    "current": "CF0DDDB78B8C54F9D0597B67A2536B802B0B9949A029314C9E74A5795FC5A28B",
    "match": true
  },
  {
    "path": "rtl/v41/r1e_measurement_regs.sv",
    "sealed": "034F8C63258CA6436817CFFE1605CDF23EF04030047CCE36146E115F3C374939",
    "current": "034F8C63258CA6436817CFFE1605CDF23EF04030047CCE36146E115F3C374939",
    "match": true
  },
  {
    "path": "rtl/v41/r1h_probe_index_bram_store.sv",
    "sealed": "67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F",
    "current": "67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F",
    "match": true
  },
  {
    "path": "rtl/v41/nvp_i2c_tri_phase_probe.sv",
    "sealed": "D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD",
    "current": "D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD",
    "match": true
  },
  {
    "path": "rtl/v41/r1f_failed_txn_logger.sv",
    "sealed": "F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761",
    "current": "F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761",
    "match": true
  },
  {
    "path": "rtl/v41/r1f_measurement_regs.sv",
    "sealed": "EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542",
    "current": "EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542",
    "match": true
  },
  {
    "path": "rtl/v41/r1h_mmio_read_service.sv",
    "sealed": "00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B",
    "current": "00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B",
    "match": true
  },
  {
    "path": "rtl/v41/g2b_product_profile_read_service.sv",
    "sealed": "18245E9B7F1EA75439445FD9743D98138D9EA58B8FA69E6396B936F0BD18B73A",
    "current": "18245E9B7F1EA75439445FD9743D98138D9EA58B8FA69E6396B936F0BD18B73A",
    "match": true
  },
  {
    "path": "rtl/v41/control_status_regs.sv",
    "sealed": "77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16",
    "current": "77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16",
    "match": true
  },
  {
    "path": "rtl/pio/pio_slot_adapter.sv",
    "sealed": "96B8E53B23295A9C8B597EF15E10DA819962E3F96B45FB02F6E472B108720CEE",
    "current": "96B8E53B23295A9C8B597EF15E10DA819962E3F96B45FB02F6E472B108720CEE",
    "match": true
  },
  {
    "path": "rtl/pio/pio_bar_target.sv",
    "sealed": "E6BED9C57D5A79E4D2AD2C5E3CEEFCD4AEDCCC9CEA77A61C6A84F350FE6FF833",
    "current": "E6BED9C57D5A79E4D2AD2C5E3CEEFCD4AEDCCC9CEA77A61C6A84F350FE6FF833",
    "match": true
  },
  {
    "path": "rtl/record/bt656_record_producer.sv",
    "sealed": "96ECA58AC2FE6D9A2E0A390076FA02370B85409F1F1353CB9F41784D2ED363EE",
    "current": "96ECA58AC2FE6D9A2E0A390076FA02370B85409F1F1353CB9F41784D2ED363EE",
    "match": true
  },
  {
    "path": "rtl/record/capture_mailbox.sv",
    "sealed": "91A55EC1DEE546F026E3DC92F04A788A779F8A3F8D9D3D8DABEF08F089CA3FF5",
    "current": "91A55EC1DEE546F026E3DC92F04A788A779F8A3F8D9D3D8DABEF08F089CA3FF5",
    "match": true
  },
  {
    "path": "rtl/video/video_capture.sv",
    "sealed": "7DFB7253C6649885665DB8449E33CE2F31D584811586DAEAA746DE04DF4AFFC9",
    "current": "7DFB7253C6649885665DB8449E33CE2F31D584811586DAEAA746DE04DF4AFFC9",
    "match": true
  },
  {
    "path": "rtl/video/physical_frontend.sv",
    "sealed": "3F4BD5FC715E409C1FA0B6F3B3F13A825F892F0BCE61F880C73B0401417C3347",
    "current": "3F4BD5FC715E409C1FA0B6F3B3F13A825F892F0BCE61F880C73B0401417C3347",
    "match": true
  },
  {
    "path": "rtl/g2b/v41_g2b_mmio_router.sv",
    "sealed": "2C4B4B037116447DAF12FF1C78D7C9096BD77D14F6E2CB59EF2ABC9CB806BE25",
    "current": "2C4B4B037116447DAF12FF1C78D7C9096BD77D14F6E2CB59EF2ABC9CB806BE25",
    "match": true
  },
  {
    "path": "rtl/g2b/v41_g2b_onech_c2h.sv",
    "sealed": "8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471",
    "current": "8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471",
    "match": true
  },
  {
    "path": "rtl/top/ahd_capture_top_xdma.sv",
    "sealed": "4ADC7B05197F3F5D4F21C4A57607407E0CDEBE4BD398D914BFCC0E499998E3B8",
    "current": "4ADC7B05197F3F5D4F21C4A57607407E0CDEBE4BD398D914BFCC0E499998E3B8",
    "match": true
  },
  {
    "path": "rtl/nvp/nvp6134c_diagnostics_pkg.vhd",
    "sealed": "36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156",
    "current": "36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156",
    "match": true
  },
  {
    "path": "rtl/nvp/r1f_transaction_serial_counter.vhd",
    "sealed": "FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E",
    "current": "FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E",
    "match": true
  },
  {
    "path": "rtl/nvp/nvp6134c_i2c_bringup.vhd",
    "sealed": "C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68",
    "current": "C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68",
    "match": true
  },
  {
    "path": "rtl/nvp/nvp6134c_autoinit.vhd",
    "sealed": "FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5",
    "current": "FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5",
    "match": true
  },
  {
    "path": "xdc/boards/current/xdma_pcie.xdc",
    "sealed": "65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A",
    "current": "65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A",
    "match": true
  },
  {
    "path": "xdc/boards/current/pins.xdc",
    "sealed": "A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9",
    "current": "A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9",
    "match": true
  },
  {
    "path": "xdc/boards/current/vdo_input_timing.xdc",
    "sealed": "6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78",
    "current": "6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78",
    "match": true
  },
  {
    "path": "xdc/boards/current/pcie_pio.xdc",
    "sealed": "BE7BFB70921AD272661071408C0820B4EC4BB60AB7C1102340011E57D8BE8503",
    "current": "BE7BFB70921AD272661071408C0820B4EC4BB60AB7C1102340011E57D8BE8503",
    "match": true
  },
  {
    "path": "xdc/boards/current/nvp_control.xdc",
    "sealed": "B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318",
    "current": "B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318",
    "match": true
  },
  {
    "path": "xdc/common/cdc.xdc",
    "sealed": "E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62",
    "current": "E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62",
    "match": true
  },
  {
    "path": "xdc/common/g2b_cdc.xdc",
    "sealed": "2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF",
    "current": "49CE028909F25303807E85E8835BD3379F1C6965EC302E08812105C280736C4A",
    "match": false
  },
  {
    "path": "xdc/common/configuration_bank.xdc",
    "sealed": "3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68",
    "current": "3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68",
    "match": true
  },
  {
    "path": "ip/v41/xdma_v41_m1.xci",
    "sealed": "9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F",
    "current": "9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F",
    "match": true
  },
  {
    "path": "scripts/v41/xdma_config_common.tcl",
    "sealed": "4B240CE27E4C8065C897EF4D184EC7EB97BB1CF4BF747C1E06F92ED3A9AE2162",
    "current": "4B240CE27E4C8065C897EF4D184EC7EB97BB1CF4BF747C1E06F92ED3A9AE2162",
    "match": true
  },
  {
    "path": "scripts/v41/g2b_build.tcl",
    "sealed": "1E22B28DC32314E10721CD8358FDE15011B196508CDB708EB0DB630FEA6BD072",
    "current": "1E22B28DC32314E10721CD8358FDE15011B196508CDB708EB0DB630FEA6BD072",
    "match": true
  }
]
```

## Generated local IP identity clarification

{
  "generated_local_XCI_sha256": "AD78651CEF97D01D01106E96C5E0A8FD3E2BA712947F8CB8D584A78D84BB47EB",
  "Gen12_effective_config_sha256": "7FE9FF23092C37128CFC4C42E7DBCCD0F966E6BE876FAAADCC0E35E46AD4532C",
  "component_parameters_compared": 958,
  "mismatches": [],
  "result": "PASS",
  "explanation": "Generated local XCI is the original 2026-08-31 elaborated artifact, distinct from the repository seed XCI. It matches all corresponding Gen12 effective component settings including QPLL1 and Gen2. Seed-to-generated differences are original elaboration/path/output-flow normalization, not recovery-4 source/IP drift. Current DCP PCIe primitive confirms Gen2 x1."
}
