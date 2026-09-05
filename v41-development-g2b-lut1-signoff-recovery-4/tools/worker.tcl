set R {C:/FPGA/G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316}
proc save {name value} {set f [open "$::R/$name.tmp" w]; fconfigure $f -translation lf; puts $f $value; close $f; file rename -force "$::R/$name.tmp" "$::R/$name"}
proc phase {name seconds} {save phase.txt "$name|$seconds|[clock seconds]"; puts "RECOVERY4_PHASE=$name"; flush stdout}
proc require_count {label objects n} {if {[llength $objects] != $n} {error "$label expected $n actual [llength $objects]"}}
proc run {} {
 phase INITIALIZE 900
 open_checkpoint {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp}
 if {[get_property PART [current_design]] ne "xc7a35tcsg325-2"} {error "part mismatch"}
 save version.txt [version]
 reset_timing -invalid
 read_xdc "$::R/non_g2b_context.xdc"
 read_xdc "$::R/proposed_g2b_cdc.xdc"
 set rows {Group,Slot,Family,Source_Count,Destination_Count}
 for {set slot 1} {$slot<=3} {incr slot} {
  set g [expr {$slot+14}]; set prefix g2b_g${g}eq
  require_count generation [set ${prefix}_release_generation_src] 24
  require_count epoch [set ${prefix}_release_epoch_src] 32
  require_count payload [set ${prefix}_release_payload_src] 56
  foreach role {state fault reset} n {3 4 3} {
   require_count $role [set ${prefix}_release_${role}_dst_cells] $n
   append rows "\n$g,$slot,$role,56,$n"
  }
 }
 write_xdc -exclude_physical -force "$::R/proposed_resolved.xdc"
 save scope_resolved.csv $rows
 phase WAIT_SOURCE_COMMIT 900
 save SCOPE_PASS.marker PASS
 while {![file exists "$::R/commit_ready.marker"]} {after 1000}
 read_xdc {C:/FPGA/V41_G2B/xdc/common/g2b_cdc.xdc}
 save COMMITTED_XDC_APPLIED.marker PASS
 for {set i 1} {$i<=20} {incr i} {
  phase WAIT_NEXT_STAGE 900
  set cmd "$::R/stage${i}.tcl"
  while {![file exists $cmd]} {after 1000}
  source $cmd
  save stage${i}_complete.marker PASS
  if {[info exists ::finished]} {return}
 }
}
if {[catch {run} msg opts]} {save FAILURE.txt "$msg\n[dict get $opts -errorinfo]"; exit 1}
save SUCCESS.marker PASS
exit 0
