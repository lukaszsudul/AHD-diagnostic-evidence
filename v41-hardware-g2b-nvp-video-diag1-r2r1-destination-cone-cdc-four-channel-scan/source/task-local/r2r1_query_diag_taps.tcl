proc names_or_empty {objects} {
  if {[llength $objects] == 0} { return {} }
  return [join [lsort -dictionary [get_property NAME $objects]] {|}]
}

open_checkpoint {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}
foreach pattern [list {*diag_stored_enable*} {*diag_c2h_active*} {*diag_ring_empty*} {*diag_ring_full*} {*diag_transport_stored_enable*} {*diag_transport_c2h_active*} {*diag_transport_ring_empty*} {*diag_transport_ring_full*} {*NVP_VIDEO_DIAG_CORE*/transport_stream_enabled*} {*NVP_VIDEO_DIAG_CORE*/transport_c2h_active*} {*NVP_VIDEO_DIAG_CORE*/transport_ring_empty*} {*NVP_VIDEO_DIAG_CORE*/transport_ring_full*} {*G2B_ONECH_C2H/stored_enable_axi_reg*/Q} {*G2B_ONECH_C2H/c2h_active_axi_reg*/Q} {*G2B_ONECH_C2H/ring_empty_sync2_axi_reg*/Q} {*G2B_ONECH_C2H/ring_full_sync2_axi_reg*/Q}] {
  puts "PATTERN=$pattern"
  puts "PINS=[names_or_empty [get_pins -quiet -hier $pattern]]"
  puts "NETS=[names_or_empty [get_nets -quiet -hier $pattern]]"
  puts "CELLS=[names_or_empty [get_cells -quiet -hier $pattern]]"
}
close_design
exit 0
