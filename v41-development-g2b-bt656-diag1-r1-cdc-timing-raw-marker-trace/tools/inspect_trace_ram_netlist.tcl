if {$argc != 2} { exit 2 }
lassign $argv dcp_path out_path
open_checkpoint $dcp_path
set fh [open $out_path w]
fconfigure $fh -encoding utf-8 -translation lf
puts $fh "TRACE_NAME_MATCHES"
foreach cell [get_cells -quiet -hier -regexp {.*(TRACE_RAM|BT656_BOUNDARY_TRACE).*}] {
  puts $fh "[get_property NAME $cell]|REF_NAME=[get_property REF_NAME $cell]|PRIMITIVE_TYPE=[get_property PRIMITIVE_TYPE $cell]"
}
puts $fh "ALL_BRAM_PRIMITIVES"
foreach cell [get_cells -quiet -hier -filter {REF_NAME =~ RAMB*}] {
  puts $fh "[get_property NAME $cell]|REF_NAME=[get_property REF_NAME $cell]|PRIMITIVE_TYPE=[get_property PRIMITIVE_TYPE $cell]"
}
puts $fh "DIAG1_SYNC_PROPERTIES"
foreach cell [get_cells -quiet -hier -regexp \
  {.*BT656_BOUNDARY_TRACE/(clear_sync[12]_source|arm_sync[12]_source|abort_sync[12]_source|armed_sync[12]_axi|triggered_sync[12]_axi|done_sync[123]_axi|overflow_sync[12]_axi)_reg}] {
  puts $fh "[get_property NAME $cell]|ASYNC_REG=[get_property ASYNC_REG $cell]"
}
close $fh
close_design
