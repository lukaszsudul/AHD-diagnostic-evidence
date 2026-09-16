# Targeted cache-state reconciliation and independent as-open identity check.
# Report-only; no constraint loading, reset, implementation or DCP save.
if {[version -short] ne {2025.2}} { error {WRONG_VIVADO_VERSION} }
set_param general.maxThreads 1
if {[llength $argv] != 2} { error {ARGS_DCP_AND_OUTPUT_ROOT_REQUIRED} }
set dcp [file normalize [lindex $argv 0]]
set output_root [file normalize [lindex $argv 1]]
if {![file isfile $dcp] || ![file isdirectory $output_root] ||
    [llength [glob -nocomplain -directory $output_root *]] != 0} {
  error {INPUT_OR_OUTPUT_GATE_FAILED}
}
set inherited {C:/FPGA/G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_20260912T121125Z/harness/g2b_nvp_camera_acq1_compat0_r2r1_finalize_signoff.tcl}
set f [open $inherited rb]
set body [read $f]
close $f
set start [string first "proc read_text {path} {" $body]
set end [string first "proc rule_id {object_name} {" $body]
if {$start < 0 || $end <= $start} { error {INHERITED_SCOPED_PROCEDURE_MARKERS_MISSING} }
uplevel #0 [string range $body $start [expr {$end - 1}]]
open_checkpoint $dcp
set part [get_property PART [current_design]]
set top [get_property TOP [current_design]]
if {$part ne {xc7a35tcsg325-2} || $top ne {ahd_capture_top_xdma}} {
  error "PART_OR_TOP_MISMATCH:$part:$top"
}
set pre [capture_signatures $output_root AS_OPEN_BEFORE_METHOD]
report_methodology -file [file join $output_root report_methodology.rpt]
set error_count 0
set critical_count 0
set warning_count 0
foreach violation [get_methodology_violations -quiet] {
  set severity [string toupper [get_property SEVERITY $violation]]
  if {$severity eq {ERROR}} { incr error_count }
  if {$severity eq {CRITICAL WARNING}} { incr critical_count }
  if {$severity eq {WARNING}} { incr warning_count }
}
if {$error_count != 0 || $critical_count != 0} {
  error "METHODOLOGY_HARD_GATE_FAILED:$error_count:$critical_count"
}
report_timing_summary -report_unconstrained -check_timing_verbose \
  -max_paths 10 -nworst 2 -path_type full \
  -file [file join $output_root report_timing_summary_after_method.rpt]
set post [capture_signatures $output_root AS_OPEN_AFTER_METHOD]
require_same_signatures $pre $post REPORT_ONLY_METHOD_AND_TIMING
write_lines [file join $output_root TARGETED_RECEIPT.txt] [list \
  {RESULT=PASS} {AS_OPEN_UNMODIFIED=YES} {REPORT_ONLY_IDENTITY=PASS} \
  "METHODOLOGY_ERRORS=$error_count" \
  "METHODOLOGY_CRITICAL_WARNINGS=$critical_count" \
  "METHODOLOGY_WARNINGS=$warning_count" \
  "CLOCK_SHA=[dict get $pre CLOCK_SHA]" \
  "NETLIST_SHA=[dict get $pre NETLIST_SHA]" \
  "ROUTE_SHA=[dict get $pre ROUTE_SHA]" \
  "XDC_SHA=[dict get $pre XDC_SHA]" \
  "ROUTED=[dict get $pre ROUTED]/[dict get $pre ROUTABLE]"]
close_design
exit 0
