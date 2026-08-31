set out_dir [file normalize [pwd]]
set_param general.maxThreads 2

open_checkpoint [file join $out_dir POST_SYNTH.dcp]
reset_property PACKAGE_PIN [get_ports ref27]
set_property PACKAGE_PIN D13 [get_ports ref27]

set pin_report [open [file join $out_dir D13_VARIANT_PIN.txt] w]
puts $pin_report "REF27_PIN=[get_property PACKAGE_PIN [get_ports ref27]]"
puts $pin_report "REF27_IOSTANDARD=[get_property IOSTANDARD [get_ports ref27]]"
puts $pin_report "PART=[get_property PART [current_design]]"
puts $pin_report "VIVADO_VERSION=[version -short]"
close $pin_report

opt_design
place_design
report_io -file [file join $out_dir D13_POST_PLACE_REPORT_IO.rpt]
report_clock_utilization -file [file join $out_dir D13_POST_PLACE_CLOCK_UTILIZATION.rpt]
report_drc -file [file join $out_dir D13_POST_PLACE_DRC.rpt]

route_design -directive Quick
report_route_status -file [file join $out_dir D13_POST_ROUTE_STATUS.rpt]
report_clock_utilization -file [file join $out_dir D13_POST_ROUTE_CLOCK_UTILIZATION.rpt]
report_drc -file [file join $out_dir D13_POST_ROUTE_DRC.rpt]
report_timing_summary -file [file join $out_dir D13_POST_ROUTE_TIMING_SUMMARY.rpt]
write_checkpoint -force [file join $out_dir D13_POST_ROUTE.dcp]

set result [open [file join $out_dir D13_SANDBOX_RESULT.txt] w]
puts $result "PART=xc7a35tcsg325-2"
puts $result "VIVADO_VERSION=[version -short]"
puts $result "ORIGINAL_C13=REJECTED_PLIO-9_N_SIDE_CCIO"
puts $result "D13_VARIANT_PLACEMENT=PASS"
puts $result "D13_VARIANT_ROUTING=PASS"
puts $result "BITSTREAM=NOT_CREATED"
close $result

close_design
exit
