if {$argc != 3} {
  puts stderr "usage: preflight_exact_r1e_routed_dcp_r2.tcl COMMON_TCL ROUTED_DCP OUTPUT_ROOT"
  exit 2
}
set common_tcl [file normalize [lindex $argv 0]]
set routed_dcp [file normalize [lindex $argv 1]]
set output_root [file normalize [lindex $argv 2]]
source $common_tcl
set gate_info [r1e_r2::gate_open_design $routed_dcp $output_root READ_ONLY_DCP_PREFLIGHT]
r1e_r2::run_complete_report_tail $output_root $gate_info
r1e_r2::write_lines [file join $output_root READ_ONLY_DRY_RUN_RESULT.txt] [list \
  "READ_ONLY_DCP_PREFLIGHT_SESSIONS=1" \
  "DESIGN_IDENTITY_GATE=PASS_NAMESPACE_CORRECT" \
  "DCP_SAVED_OR_MODIFIED=NO" \
  "WRITE_BITSTREAM_COMMAND_COUNT=0" \
  "PROCESS_INTERNAL_RESULT=PASS"]
puts "READ_ONLY_DCP_PREFLIGHT=PASS"
close_design
exit 0

