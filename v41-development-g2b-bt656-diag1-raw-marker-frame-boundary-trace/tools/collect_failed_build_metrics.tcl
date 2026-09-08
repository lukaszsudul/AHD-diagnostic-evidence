if {$argc != 2} {
  puts stderr "usage: collect_failed_build_metrics.tcl <routed-dcp> <output-dir>"
  exit 64
}

set routed_dcp [file normalize [lindex $argv 0]]
set output_dir [file normalize [lindex $argv 1]]
file mkdir $output_dir

open_checkpoint $routed_dcp
report_utilization -file [file join $output_dir DIAG1_ROUTED_UTILIZATION_FLAT.rpt]
set trace_cells [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE.*}]
if {[llength $trace_cells] == 0} {
  puts stderr "trace hierarchy absent"
  close_design
  exit 2
}
report_utilization -cells $trace_cells \
  -file [file join $output_dir DIAG1_TRACE_UTILIZATION.rpt]
set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
set fh [open [file join $output_dir DIAG1_FAILED_BUILD_METRICS.txt] w]
puts $fh "WNS=[get_property SLACK [lindex $worst_setup 0]]"
puts $fh "WHS=[get_property SLACK [lindex $worst_hold 0]]"
puts $fh "TRACE_CELL_COUNT=[llength $trace_cells]"
close $fh
close_design
exit 0
