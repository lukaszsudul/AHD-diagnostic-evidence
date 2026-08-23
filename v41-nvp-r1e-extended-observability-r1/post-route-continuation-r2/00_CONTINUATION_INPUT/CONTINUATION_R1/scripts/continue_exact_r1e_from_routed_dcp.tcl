if {$argc != 3} {
  puts stderr "usage: continue_exact_r1e_from_routed_dcp.tcl ROUTED_DCP TASK_ROOT BIT_FILENAME"
  exit 2
}

set routed_dcp [file normalize [lindex $argv 0]]
set task_root [file normalize [lindex $argv 1]]
set bit_filename [lindex $argv 2]
set report_root [file join $task_root 03_DCP_CONTINUATION]
set bit_root [file join $task_root 04_BITSTREAM]

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

proc read_text {path} {
  set fh [open $path r]
  set text [read $fh]
  close $fh
  return $text
}

proc utilization_row {text wanted} {
  set normalized_wanted [string trimright $wanted "*"]
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
    set actual [string trimright [string trim [lindex $columns 1]] "*"]
    if {[llength $columns] >= 7 && $actual eq $normalized_wanted} {
      return [list [string trim [lindex $columns 2]] [string trim [lindex $columns 5]]]
    }
  }
  error "utilization row '$wanted' not found"
}

if {![file isfile $routed_dcp]} { error "frozen routed DCP missing: $routed_dcp" }
if {$bit_filename ne "ahd_capture_v41_i2c_25khz_r1e_observability.bit"} {
  error "unexpected bit filename: $bit_filename"
}
file mkdir $report_root
file mkdir $bit_root

set tool_version [version -short]
if {![string match "2025.2*" $tool_version]} { error "Vivado version mismatch: $tool_version" }

open_checkpoint $routed_dcp
set design_obj [current_design]
if {[llength $design_obj] != 1} { error "expected one current design" }
set design_name [get_property NAME $design_obj]
set design_part [get_property PART $design_obj]
if {$design_name ne "ahd_capture_top_xdma"} { error "top mismatch: $design_name" }
if {$design_part ne "xc7a35tcsg325-2"} { error "part mismatch: $design_part" }

set route_report [file join $report_root PHASE3_route_status.rpt]
set timing_report [file join $report_root PHASE3_timing_summary.rpt]
set drc_report [file join $report_root PHASE3_drc.rpt]
set bus_skew_report [file join $report_root PHASE3_bus_skew.rpt]
set cdc_report [file join $report_root PHASE3_cdc.rpt]

report_route_status -file $route_report
report_timing_summary -delay_type min_max -max_paths 100 -file $timing_report
report_drc -file $drc_report
check_timing -verbose -file [file join $report_root PHASE3_check_timing.rpt]
report_exceptions -coverage -file [file join $report_root PHASE3_exception_coverage.rpt]
report_bus_skew -file $bus_skew_report
report_clock_interaction -file [file join $report_root PHASE3_clock_interaction.rpt]
report_cdc -details -file $cdc_report
report_utilization -file [file join $report_root PHASE3_utilization.rpt]
report_utilization -hierarchical -hierarchical_depth 20 -file [file join $report_root PHASE3_utilization_hierarchical.rpt]
report_clock_utilization -file [file join $report_root PHASE3_clock_utilization.rpt]
report_design_analysis -congestion -file [file join $report_root PHASE3_congestion.rpt]
report_methodology -file [file join $report_root PHASE3_methodology.rpt]
report_power -file [file join $report_root PHASE3_power.rpt]
report_io -file [file join $report_root PHASE3_io.rpt]
report_clocks -file [file join $report_root PHASE3_clocks.rpt]
report_property -file [file join $report_root PHASE3_design_properties.txt] $design_obj

set nvp_io_ports [get_ports {nvp_scl nvp_sda}]
if {[llength $nvp_io_ports] != 2} { error "expected two NVP I/O ports" }
report_timing -delay_type max -to $nvp_io_ports -max_paths 32 -nworst 16 -file [file join $report_root R1E_nvp_scl_sda_output_paths.rpt]
report_timing -delay_type max -from $nvp_io_ports -max_paths 32 -nworst 16 -file [file join $report_root R1E_nvp_scl_sda_input_paths.rpt]

set nvp_iobuf_cells [get_cells -quiet -hier -filter {NAME =~ *NVP_SCL_IOBUF || NAME =~ *NVP_SDA_IOBUF}]
set nvp_iobuf_names [lsort -dictionary [get_property NAME $nvp_iobuf_cells]]
if {[llength $nvp_iobuf_names] != 2} { error "expected exactly two NVP IOBUF cells, got [llength $nvp_iobuf_names]" }
set property_index [list "OBJECT_COUNT=2" "ORDER=FULL_HIERARCHICAL_NAME_ASCENDING"]
set object_index 0
foreach object_name $nvp_iobuf_names {
  set one_object [get_cells -quiet [list $object_name]]
  if {[llength $one_object] != 1} { error "per-object lookup cardinality failure: $object_name" }
  set property_file [file join $report_root [format "R1E_nvp_iobuf_%02d_properties.txt" $object_index]]
  lappend property_index "OBJECT_INDEX=$object_index"
  lappend property_index "OBJECT_NAME=$object_name"
  lappend property_index "PROPERTY_FILE=[file tail $property_file]"
  report_property -file $property_file $one_object
  incr object_index
}
write_lines [file join $report_root R1E_nvp_iobuf_properties_index.txt] $property_index

set nvp_t_pins [get_pins -quiet -of_objects $nvp_iobuf_cells -filter {REF_PIN_NAME == T}]
set nvp_o_pins [get_pins -quiet -of_objects $nvp_iobuf_cells -filter {REF_PIN_NAME == O}]
if {[llength $nvp_t_pins] != 2 || [llength $nvp_o_pins] != 2} { error "unexpected NVP IOBUF pin cardinality" }
write_lines [file join $report_root R1E_nvp_output_fanin.txt] [lsort [get_property NAME [all_fanin -flat -to $nvp_t_pins]]]
write_lines [file join $report_root R1E_nvp_input_fanout.txt] [lsort [get_property NAME [all_fanout -flat -from $nvp_o_pins]]]
set probe_cells [get_cells -quiet -hier -filter {NAME =~ *POST_INIT_ADDRESS_PROBE*}]
set lifecycle_cells [get_cells -quiet -hier -filter {NAME =~ *LIFECYCLE_MONITOR*}]
write_lines [file join $report_root R1E_probe_cells.txt] [lsort [get_property NAME $probe_cells]]
write_lines [file join $report_root R1E_lifecycle_cells.txt] [lsort [get_property NAME $lifecycle_cells]]

set vdo_ports [get_ports {vdo1_data[*]}]
if {[llength $vdo_ports] != 8} { error "expected eight VDO ports" }
report_timing -delay_type max -from $vdo_ports -max_paths 32 -nworst 4 -file [file join $report_root PHASE3_vdo_setup_paths.rpt]
report_timing -delay_type min -from $vdo_ports -max_paths 32 -nworst 4 -file [file join $report_root PHASE3_vdo_hold_paths.rpt]

set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
set vdo_setup [get_timing_paths -quiet -delay_type max -from $vdo_ports -max_paths 1 -nworst 1]
set vdo_hold [get_timing_paths -quiet -delay_type min -from $vdo_ports -max_paths 1 -nworst 1]
if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1 || [llength $vdo_setup] != 1 || [llength $vdo_hold] != 1} {
  error "required timing path class is empty"
}
set wns [get_property SLACK $worst_setup]
set whs [get_property SLACK $worst_hold]
set vdo_wns [get_property SLACK $vdo_setup]
set vdo_whs [get_property SLACK $vdo_hold]

set drc_errors 0
set drc_critical_warnings 0
set drc_warnings 0
foreach violation [get_drc_violations -quiet] {
  switch -- [get_property SEVERITY $violation] {
    Error { incr drc_errors }
    {Critical Warning} { incr drc_critical_warnings }
    Warning { incr drc_warnings }
  }
}
set bus_skew_violations [regexp -all {Slack \(VIOLATED\)} [read_text $bus_skew_report]]
set cdc_critical_types [regexp -all -line {^CDC-[0-9]+[ \t]+Critical[ \t]+} [read_text $cdc_report]]
set cdc_unknown_types [regexp -all -line {^CDC-[0-9]+[ \t]+Unknown[ \t]+} [read_text $cdc_report]]
set reqp_1839_count [regexp -all {REQP-1839} [read_text $drc_report]]
set route_errors -1
regexp {# of nets with routing errors[^:]*:[ \t]*([0-9]+)} [read_text $route_report] -> route_errors

set util_text [report_utilization -return_string]
lassign [utilization_row $util_text "Slice LUTs*"] lut_used lut_available
lassign [utilization_row $util_text "Slice Registers"] ff_used ff_available
lassign [utilization_row $util_text "Block RAM Tile"] bram_used bram_available
lassign [utilization_row $util_text "DSPs"] dsp_used dsp_available
set lut_free_pct [expr {100.0 * ($lut_available - $lut_used) / $lut_available}]
set ff_free_pct [expr {100.0 * ($ff_available - $ff_used) / $ff_available}]
set bram_free_pct [expr {100.0 * ($bram_available - $bram_used) / $bram_available}]
set dsp_free_pct [expr {100.0 * ($dsp_available - $dsp_used) / $dsp_available}]

set gate PASS
if {$route_errors != 0 || $drc_errors != 0 || $drc_critical_warnings != 0 || $reqp_1839_count != 4 || $bus_skew_violations != 0 || $cdc_critical_types != 0 || $cdc_unknown_types != 0 || $wns < 0.617 || $whs < 0.021 || $vdo_wns < 0.0 || $vdo_whs <= 0.0 || $lut_free_pct < 10.0 || $ff_free_pct < 10.0 || $bram_free_pct < 10.0} {
  set gate FAIL
}

write_lines [file join $report_root ROUTED_DCP_CONTINUATION_GATE.txt] [list \
  "VIVADO_VERSION=$tool_version" \
  "TOP=$design_name" \
  "PART=$design_part" \
  "ROUTE_ERRORS=$route_errors" \
  "WNS=$wns" "WHS=$whs" "VDO_WNS=$vdo_wns" "VDO_WHS=$vdo_whs" \
  "DRC_ERRORS=$drc_errors" "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" "DRC_WARNINGS=$drc_warnings" \
  "REQP_1839_COUNT=$reqp_1839_count" \
  "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
  "CDC_CRITICAL_TYPES=$cdc_critical_types" "CDC_UNKNOWN_TYPES=$cdc_unknown_types" \
  "NVP_IOBUF_OBJECT_COUNT=[llength $nvp_iobuf_names]" \
  "LUT_FREE_PERCENT=[format %.2f $lut_free_pct]" \
  "FF_FREE_PERCENT=[format %.2f $ff_free_pct]" \
  "BRAM_FREE_PERCENT=[format %.2f $bram_free_pct]" \
  "DSP_FREE_PERCENT=[format %.2f $dsp_free_pct]" \
  "ROUTED_DCP_CONTINUATION_GATE=$gate"]

if {$gate ne "PASS"} {
  puts stderr "ROUTED_DCP_CONTINUATION_GATE=FAIL"
  close_design
  exit 1
}

set bit_path [file join $bit_root $bit_filename]
if {[file exists $bit_path]} { error "bit output pre-exists; refusing overwrite: $bit_path" }
write_bitstream $bit_path
if {![file isfile $bit_path] || [file size $bit_path] <= 0} { error "bitstream missing or empty after write_bitstream" }
write_lines [file join $bit_root POST_ROUTE_CONTINUATION_RESULT.txt] [list \
  "SOURCE_COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd" \
  "SOURCE_TREE=db8b5581a237e19905fd01c6d453793047bc3ba7" \
  "PRIOR_ROUTED_DCP_SHA256=1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1" \
  "FULL_BUILDS_THIS_TASK=0" \
  "SYNTHESIS_RUNS_THIS_TASK=0" \
  "PLACE_RUNS_THIS_TASK=0" \
  "ROUTE_RUNS_THIS_TASK=0" \
  "POST_ROUTE_CONTINUATION_SESSIONS=1" \
  "WRITE_BITSTREAM_ATTEMPTS=1" \
  "BITSTREAM=$bit_path" \
  "BITSTREAM_SIZE_BYTES=[file size $bit_path]" \
  "PROCESS_INTERNAL_RESULT=PASS"]
puts "POST_ROUTE_CONTINUATION=PASS BITSTREAM=$bit_path"
close_design
exit 0
