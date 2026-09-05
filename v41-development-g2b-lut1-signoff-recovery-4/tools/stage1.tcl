phase COMMITTED_CONTEXT 900
reset_timing -invalid
read_xdc "$::R/non_g2b_context.xdc"
read_xdc {C:/FPGA/V41_G2B/xdc/common/g2b_cdc.xdc}
write_xdc -exclude_physical -force "$::R/current_resolved.xdc"
set results {Group,Slot,Family,Constraint_Type,Source_Count,Destination_Count,Required_ns,Actual_Worst_ns,Slack_ns,Runtime_s,Result,Reference_Actual_ns,Difference_ns,Notes}
set refs {5.548 5.576 4.338 5.473 5.772 4.480 5.515 5.729 4.585}; set ri 0
for {set slot 1} {$slot<=3} {incr slot} {
 set g [expr {$slot+14}]; set prefix g2b_g${g}eq
 foreach role {state fault reset} semantic {NORMAL_STATE_TRANSITION MISMATCH_CONTAINMENT RESET_OVERLAP_ACCOUNTING} count {3 4 3} {
  set family RELEASE_SLOT${slot}_${semantic}
  phase $family 300
  set start [clock milliseconds]
  set src [set ${prefix}_release_payload_src]; set dst [set ${prefix}_release_${role}_dst_cells]
  require_count source $src 56; require_count destination $dst $count
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from $src -to $dst]
  require_count path $paths 1
  set p [lindex $paths 0]
  set actual [get_property DATAPATH_DELAY $p]; set slack [get_property SLACK $p]; set required [get_property REQUIREMENT $p]
  report_timing -of_objects $paths -file "$::R/${family}.rpt"
  if {$actual>6.0005 || $slack<0 || abs($required-6)>0.0005} {error "$family timing failure actual=$actual slack=$slack required=$required"}
  if {[get_property STARTPOINT_CLOCK $p] ne "userclk1" || [get_property ENDPOINT_CLOCK $p] ne "nvp_vclk1"} {error "clock domain drift"}
  set ref [lindex $refs $ri]; incr ri
  set elapsed [expr {([clock milliseconds]-$start)/1000.0}]
  append results "\n$g,$slot,$family,MAX_DELAY_DATAPATH_ONLY,56,$count,6.000,$actual,$slack,$elapsed,PASS,$ref,[expr {$actual-$ref}],Fresh committed active XDC"
  save G2B_LUT1_RECOVERY4_GROUPS15_17_RESULTS.csv $results
 }
}
save GROUPS15_17_PASS.marker PASS
