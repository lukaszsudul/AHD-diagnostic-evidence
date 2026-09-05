phase CDC 900
report_cdc -details -file "$::R/CDC.rpt"
set ::active_xdc {C:/FPGA/V41_G2B/xdc/common/g2b_cdc.xdc}
set ::expected_active_xdc_sha [sha256_file $::active_xdc]
set ::build_root {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_BUILD_20260831_12}
set count [enforce_exact_cdc_disposition "$::R/CDC.rpt" [get_cdc_violations -quiet]]
save CDC_PASS.marker $count
