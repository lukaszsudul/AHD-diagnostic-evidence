# Read-only collector for one immutable, externally SHA-verified DCP copy.
# No timing reset, constraint load, implementation, checkpoint write, bitstream,
# or hardware command is present. The inherited excerpt contains procs only.
if {[version -short] ne {2025.2}} { error {WRONG_VIVADO_VERSION} }
set_param general.maxThreads 1
if {[llength $argv] != 2} { error {ARGS_DCP_AND_OUTPUT_ROOT_REQUIRED} }
set dcp [file normalize [lindex $argv 0]]
set output_root [file normalize [lindex $argv 1]]
if {![file isfile $dcp] || ![file isdirectory $output_root]} {
  error {INPUT_DCP_OR_OUTPUT_ROOT_MISSING}
}
if {[llength [glob -nocomplain -directory $output_root *]] != 0} {
  error {OUTPUT_ROOT_NOT_EMPTY}
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
write_lines [file join $output_root OPENED_IDENTITY.txt] [list \
  "DCP=$dcp" "PART=$part" "TOP=$top" \
  "VIVADO=[version -short]" {VIEW=AS_OPEN_UNMODIFIED}]
set pre [capture_signatures $output_root AS_OPEN_BEFORE_REPORTS]

# Options checked against the installed 2025.2 help. All report files are
# separately retained. Global report_bus_skew was historically prohibitively
# expensive with overlapping groups; inherited exact-group receipts are
# linked only after DCP and design-view identity have passed.
report_timing_summary -report_unconstrained -check_timing_verbose \
  -max_paths 10 -nworst 2 -path_type full \
  -file [file join $output_root report_timing_summary.rpt]
report_exceptions -summary -file [file join $output_root report_exceptions_summary.rpt]
report_exceptions -ignored -file [file join $output_root report_exceptions_ignored.rpt]
report_clocks -file [file join $output_root report_clocks.rpt]
report_clock_networks -endpoints_only -expand_buckets \
  -file [file join $output_root report_clock_networks.rpt]
report_cdc -details -file [file join $output_root report_cdc.rpt]
set post [capture_signatures $output_root AS_OPEN_AFTER_REPORTS]
require_same_signatures $pre $post REPORT_ONLY_AS_OPEN
write_lines [file join $output_root COLLECTOR_RECEIPT.txt] [list \
  {RESULT=PASS} {AS_OPEN_UNMODIFIED=YES} {REPORT_ONLY_IDENTITY=PASS} \
  {REPORT_BUS_SKEW=NOT_RUN_INHERITED_EXACT_GROUP_LINKAGE_REQUIRED} \
  "CLOCK_SHA=[dict get $pre CLOCK_SHA]" \
  "NETLIST_SHA=[dict get $pre NETLIST_SHA]" \
  "ROUTE_SHA=[dict get $pre ROUTE_SHA]" \
  "XDC_SHA=[dict get $pre XDC_SHA]" \
  "BUS_SKEW_COUNT=[dict get $pre BUS_SKEW]" \
  "MAX_DELAY_COUNT=[dict get $pre MAX_DELAY]" \
  "FALSE_PATH_COUNT=[dict get $pre FALSE_PATH]" \
  "CLOCK_GROUP_COUNT=[dict get $pre CLOCK_GROUP]" \
  "ROUTED=[dict get $pre ROUTED]/[dict get $pre ROUTABLE]"]
close_design
exit 0
