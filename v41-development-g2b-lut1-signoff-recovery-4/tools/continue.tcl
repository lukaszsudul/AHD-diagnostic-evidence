set R {C:/FPGA/G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316}
proc save {name value} {set f [open "$::R/$name.tmp" w]; fconfigure $f -translation lf; puts $f $value; close $f; file rename -force "$::R/$name.tmp" "$::R/$name"}
proc phase {name seconds} {save phase2.txt "$name|$seconds|[clock seconds]"; puts "RECOVERY4_CONTINUATION_PHASE=$name";flush stdout}
proc require_count {label objects n} {if {[llength $objects]!=$n} {error "$label expected $n actual [llength $objects]"}}
source "$R/helpers.tcl"
proc run {} {
 phase CONTINUATION_INITIALIZE 900
 open_checkpoint {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp}
 reset_timing -invalid
 read_xdc "$::R/non_g2b_context.xdc"
 read_xdc {C:/FPGA/V41_G2B/xdc/common/g2b_cdc.xdc}
 write_xdc -exclude_physical -force "$::R/continuation_resolved.xdc"
 if {[route_signature] ne [list 1 0 0 0]} {error "continuation route identity drift"}
 set chain_rows {Cell,ASYNC_REG}
 foreach name {fatal_sync1_source_reg fatal_sync2_source_reg source_ready_sync1_axi_reg source_ready_sync2_axi_reg} {
  set c [get_cells -quiet G2B_ONECH_C2H/$name];require_count $name $c 1
  set async [get_property ASYNC_REG $c]
  if {![property_is_true $async]} {error "$name ASYNC_REG missing"}
  append chain_rows "\n$c,$async"
 }
 save cdc10_chain_attributes.csv $chain_rows
 save CDC_STRUCTURAL_PASS.marker PASS
 source "$::R/stage6.tcl"
 phase WAIT_HARD_GATE 900
 save READY_HARD_GATE.marker PASS
 while {![file exists "$::R/build_authorized.marker"]} {after 1000}
 set f [open "$::R/G2B_PRE_BITSTREAM_HARD_GATE_RECOVERY4.txt" r];set gate [read $f];close $f
 if {[string first "PRE_BITSTREAM_HARD_GATE = PASS" $gate]<0 || [string first "FAIL" $gate]>=0} {error "pre-bitstream hard gate not PASS"}
 phase SIGNED_CHECKPOINT 600
 write_checkpoint -force "$::R/G2B_PRODUCT_SIGNED_OFF.dcp"
 save SIGNED_DCP_PASS.marker PASS
 phase BITSTREAM 900
 write_bitstream -force "$::R/G2B_PRODUCT_RECOVERY4.bit"
 save BITSTREAM_PASS.marker "WRITE_BITSTREAM_RETURN_STATUS=0\nTIMESTAMP=[clock seconds]"
}
if {[catch {run} msg opts]} {save CONTINUATION_FAILURE.txt "$msg\n[dict get $opts -errorinfo]";exit 1}
save CANDIDATE_BUILD_SUCCESS.marker PASS
exit 0
