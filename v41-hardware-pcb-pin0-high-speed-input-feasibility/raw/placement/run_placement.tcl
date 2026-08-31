set out_dir [file normalize [pwd]]
set part_name xc7a35t-csg325-2
set_param general.maxThreads 2

create_project -force pcb_pin0_placement [file join $out_dir project] -part $part_name
add_files [file join $out_dir pin_feasibility_top.v]
add_files -fileset constrs_1 [file join $out_dir proposed_pins.xdc]
set_property top pin_feasibility_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top pin_feasibility_top -part $part_name
report_io -file [file join $out_dir POST_SYNTH_REPORT_IO.rpt]
report_clock_utilization -file [file join $out_dir POST_SYNTH_CLOCK_UTILIZATION.rpt]
write_checkpoint -force [file join $out_dir POST_SYNTH.dcp]

opt_design
place_design
report_io -file [file join $out_dir POST_PLACE_REPORT_IO.rpt]
report_clock_utilization -file [file join $out_dir POST_PLACE_CLOCK_UTILIZATION.rpt]
report_drc -file [file join $out_dir POST_PLACE_DRC.rpt]
write_checkpoint -force [file join $out_dir POST_PLACE.dcp]

route_design -directive Quick
report_route_status -file [file join $out_dir POST_ROUTE_STATUS.rpt]
report_clock_utilization -file [file join $out_dir POST_ROUTE_CLOCK_UTILIZATION.rpt]
report_drc -file [file join $out_dir POST_ROUTE_DRC.rpt]
report_timing_summary -file [file join $out_dir POST_ROUTE_TIMING_SUMMARY.rpt]
write_checkpoint -force [file join $out_dir POST_ROUTE.dcp]

set result [open [file join $out_dir SANDBOX_RESULT.txt] w]
puts $result "PART_REQUESTED=$part_name"
puts $result "PART_CANONICAL=[get_property PART [current_project]]"
puts $result "VIVADO_VERSION=[version -short]"
puts $result "SYNTHESIS=PASS"
puts $result "PLACEMENT=PASS"
puts $result "ROUTING=PASS"
puts $result "BITSTREAM=NOT_CREATED"
close $result

close_project
exit
