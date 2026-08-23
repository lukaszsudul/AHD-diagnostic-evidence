namespace eval r1e_r2 {
  variable expected_part "xc7a35tcsg325-2"
  variable rtl_top_from_manifest "ahd_capture_top_xdma"
}

proc r1e_r2::write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

proc r1e_r2::write_text {path value} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -translation lf
  puts -nonewline $fh $value
  close $fh
}

proc r1e_r2::read_text {path} {
  set fh [open $path r]
  set value [read $fh]
  close $fh
  return $value
}

proc r1e_r2::utilization_row {text wanted} {
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

proc r1e_r2::gate_open_design {routed_dcp output_root session_role} {
  variable expected_part
  variable rtl_top_from_manifest
  if {![file isfile $routed_dcp]} { error "routed DCP missing: $routed_dcp" }
  file mkdir $output_root
  open_checkpoint $routed_dcp

  set d [current_design]
  set checkpoint_design_name [string trim $d]
  if {$checkpoint_design_name eq ""} { error "no current design is open" }
  set checkpoint_part [get_property PART $d]
  if {$checkpoint_part ne $expected_part} { error "unexpected part: $checkpoint_part" }

  set port_signature [list \
    pci_exp_txp* 1 pci_exp_txn* 1 pci_exp_rxp* 1 pci_exp_rxn* 1 \
    sys_clk_p 1 sys_clk_n 1 sys_rst_n 1 vclk1 1 vdo1_data* 8 \
    nvp_rst 1 nvp_scl 1 nvp_sda 1 nvp_en_vdd1x 1 nvp_en_vdd3x 1 nvp_mpp* 4]
  set port_results [list]
  foreach {pattern expected_count} $port_signature {
    set actual_count [llength [get_ports -quiet $pattern]]
    lappend port_results "PORT_PATTERN=$pattern EXPECTED=$expected_count ACTUAL=$actual_count"
    if {$actual_count != $expected_count} { error "port signature mismatch for $pattern: $actual_count" }
  }

  set probe_cells [get_cells -quiet -hier -filter {ORIG_REF_NAME == nvp_i2c_address_probe}]
  set lifecycle_cells [get_cells -quiet -hier -filter {ORIG_REF_NAME == v41_axi_clock_lifecycle_monitor}]
  if {[llength $probe_cells] < 1} { error "R1e probe structural signature absent" }
  if {[llength $lifecycle_cells] < 1} { error "R1e lifecycle structural signature absent" }

  set route_text [report_route_status -return_string]
  set route_path [file join $output_root ROUTED_STATE.rpt]
  write_text $route_path $route_text
  set routable -1
  set fully_routed -1
  set route_errors -1
  regexp {# of routable nets[^:]*:[ \t]*([0-9]+)} $route_text -> routable
  regexp {# of fully routed nets[^:]*:[ \t]*([0-9]+)} $route_text -> fully_routed
  regexp {# of nets with routing errors[^:]*:[ \t]*([0-9]+)} $route_text -> route_errors
  if {$routable < 1 || $fully_routed != $routable || $route_errors != 0} {
    error "design is not fully routed: routable=$routable fully=$fully_routed errors=$route_errors"
  }

  write_lines [file join $output_root DESIGN_IDENTITY_GATE.txt] [concat [list \
    "SESSION_ROLE=$session_role" \
    "VIVADO_VERSION=[version -short]" \
    "CHECKPOINT_CURRENT_DESIGN_NAME=$checkpoint_design_name" \
    "RTL_TOP_FROM_BUILD_MANIFEST=$rtl_top_from_manifest" \
    "DESIGN_NAME_EQUALITY_REQUIRED=NO" \
    "CURRENT_DESIGN_TO_RTL_TOP_EQUALITY_COMPARISON_COUNT=0" \
    "PART=$checkpoint_part" \
    "ROUTABLE_NETS=$routable" \
    "FULLY_ROUTED_NETS=$fully_routed" \
    "ROUTE_ERRORS=$route_errors" \
    "IS_ROUTED=YES" \
    "PROBE_STRUCTURAL_CELL_COUNT=[llength $probe_cells]" \
    "LIFECYCLE_STRUCTURAL_CELL_COUNT=[llength $lifecycle_cells]" \
    "DESIGN_IDENTITY_GATE=PASS_NAMESPACE_CORRECT"] $port_results]
  puts "CHECKPOINT_CURRENT_DESIGN_NAME=$checkpoint_design_name"
  puts "RTL_TOP_FROM_BUILD_MANIFEST=$rtl_top_from_manifest"
  puts "DESIGN_NAME_EQUALITY_REQUIRED=NO"
  return [dict create design $d checkpoint_name $checkpoint_design_name part $checkpoint_part \
    routable $routable fully_routed $fully_routed route_errors $route_errors \
    probe_cells $probe_cells lifecycle_cells $lifecycle_cells]
}

proc r1e_r2::run_complete_report_tail {output_root gate_info} {
  set route_report [file join $output_root PHASE3_route_status.rpt]
  set timing_report [file join $output_root PHASE3_timing_summary.rpt]
  set drc_report [file join $output_root PHASE3_drc.rpt]
  set bus_skew_report [file join $output_root PHASE3_bus_skew.rpt]
  set cdc_report [file join $output_root PHASE3_cdc.rpt]
  set util_report [file join $output_root PHASE3_utilization.rpt]

  report_route_status -file $route_report
  report_timing_summary -delay_type min_max -max_paths 100 -file $timing_report
  report_drc -file $drc_report
  check_timing -verbose -file [file join $output_root PHASE3_check_timing.rpt]
  report_exceptions -coverage -file [file join $output_root PHASE3_exception_coverage.rpt]
  report_bus_skew -file $bus_skew_report
  report_clock_interaction -file [file join $output_root PHASE3_clock_interaction.rpt]
  report_cdc -details -file $cdc_report
  report_utilization -file $util_report
  report_utilization -hierarchical -hierarchical_depth 20 -file [file join $output_root PHASE3_utilization_hierarchical.rpt]
  report_clock_utilization -file [file join $output_root PHASE3_clock_utilization.rpt]
  report_design_analysis -congestion -file [file join $output_root PHASE3_congestion.rpt]
  report_methodology -file [file join $output_root PHASE3_methodology.rpt]
  report_power -file [file join $output_root PHASE3_power.rpt]
  report_io -file [file join $output_root PHASE3_io.rpt]
  report_clocks -file [file join $output_root PHASE3_clocks.rpt]

  set design_object [dict get $gate_info design]
  if {[llength $design_object] != 1} { error "design object cardinality changed" }
  report_property -file [file join $output_root PHASE3_design_properties.txt] $design_object

  set nvp_io_ports [get_ports {nvp_scl nvp_sda}]
  if {[llength $nvp_io_ports] != 2} { error "expected two NVP I/O ports" }
  report_timing -delay_type max -to $nvp_io_ports -max_paths 32 -nworst 16 -file [file join $output_root R1E_nvp_scl_sda_output_paths.rpt]
  report_timing -delay_type max -from $nvp_io_ports -max_paths 32 -nworst 16 -file [file join $output_root R1E_nvp_scl_sda_input_paths.rpt]

  set nvp_iobuf_cells [get_cells -quiet -hier -filter {NAME =~ *NVP_SCL_IOBUF || NAME =~ *NVP_SDA_IOBUF}]
  set nvp_iobuf_names [lsort -dictionary [get_property NAME $nvp_iobuf_cells]]
  if {[llength $nvp_iobuf_names] != 2} { error "expected exactly two NVP IOBUF objects, got [llength $nvp_iobuf_names]" }
  set property_index [list "OBJECT_COUNT=2" "ORDER=FULL_HIERARCHICAL_NAME_ASCENDING"]
  set object_index 0
  foreach object_name $nvp_iobuf_names {
    set one_object [get_cells -quiet [list $object_name]]
    if {[llength $one_object] != 1} { error "per-object cardinality failure for $object_name" }
    set property_file [file join $output_root [format "R1E_nvp_iobuf_%02d_properties.txt" $object_index]]
    lappend property_index "OBJECT_INDEX=$object_index OBJECT_NAME=$object_name PROPERTY_FILE=[file tail $property_file]"
    report_property -file $property_file $one_object
    incr object_index
  }
  write_lines [file join $output_root R1E_nvp_iobuf_properties_index.txt] $property_index

  set nvp_t_pins [get_pins -quiet -of_objects $nvp_iobuf_cells -filter {REF_PIN_NAME == T}]
  set nvp_o_pins [get_pins -quiet -of_objects $nvp_iobuf_cells -filter {REF_PIN_NAME == O}]
  if {[llength $nvp_t_pins] != 2 || [llength $nvp_o_pins] != 2} { error "unexpected NVP IOBUF T/O pin cardinality" }
  write_lines [file join $output_root R1E_nvp_output_fanin.txt] [lsort [get_property NAME [all_fanin -flat -to $nvp_t_pins]]]
  write_lines [file join $output_root R1E_nvp_input_fanout.txt] [lsort [get_property NAME [all_fanout -flat -from $nvp_o_pins]]]
  write_lines [file join $output_root R1E_probe_cells.txt] [lsort [get_property NAME [dict get $gate_info probe_cells]]]
  write_lines [file join $output_root R1E_lifecycle_cells.txt] [lsort [get_property NAME [dict get $gate_info lifecycle_cells]]]

  set vdo_ports [get_ports {vdo1_data[*]}]
  if {[llength $vdo_ports] != 8} { error "expected eight VDO ports" }
  report_timing -delay_type max -from $vdo_ports -max_paths 32 -nworst 4 -file [file join $output_root PHASE3_vdo_setup_paths.rpt]
  report_timing -delay_type min -from $vdo_ports -max_paths 32 -nworst 4 -file [file join $output_root PHASE3_vdo_hold_paths.rpt]

  set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
  set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
  set vdo_setup [get_timing_paths -quiet -delay_type max -from $vdo_ports -max_paths 1 -nworst 1]
  set vdo_hold [get_timing_paths -quiet -delay_type min -from $vdo_ports -max_paths 1 -nworst 1]
  if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1 || [llength $vdo_setup] != 1 || [llength $vdo_hold] != 1} { error "required timing path class is empty" }
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

  if {$route_errors != 0 || $drc_errors != 0 || $drc_critical_warnings != 0 || $reqp_1839_count != 4 || $bus_skew_violations != 0 || $cdc_critical_types != 0 || $cdc_unknown_types != 0 || $wns < 0.617 || $whs < 0.021 || $vdo_wns < 0.0 || $vdo_whs <= 0.0 || $lut_free_pct < 10.0 || $ff_free_pct < 10.0 || $bram_free_pct < 10.0} {
    error "post-route report gate failed"
  }

  write_lines [file join $output_root READ_ONLY_REPORT_TAIL_GATE.txt] [list \
    "WNS=$wns" "WHS=$whs" "VDO_WNS=$vdo_wns" "VDO_WHS=$vdo_whs" \
    "ROUTE_ERRORS=$route_errors" "DRC_ERRORS=$drc_errors" \
    "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" "DRC_WARNINGS=$drc_warnings" \
    "REQP_1839_COUNT=$reqp_1839_count" "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
    "CDC_CRITICAL_TYPES=$cdc_critical_types" "CDC_UNKNOWN_TYPES=$cdc_unknown_types" \
    "REPORT_PROPERTY_OBJECT_COUNT=[llength $nvp_iobuf_names]" \
    "REPORT_PROPERTY_PER_OBJECT_OUTPUTS=$object_index" \
    "LUT_FREE_PERCENT=[format %.2f $lut_free_pct]" \
    "FF_FREE_PERCENT=[format %.2f $ff_free_pct]" \
    "BRAM_FREE_PERCENT=[format %.2f $bram_free_pct]" \
    "DSP_FREE_PERCENT=[format %.2f $dsp_free_pct]" \
    "ALL_REMAINING_REPORT_ONLY_COMMANDS=PASS" \
    "READ_ONLY_REPORT_TAIL_GATE=PASS"]
}

