# AHD v41 G2B_BT656_DIAG1 one-shot, nonincremental Vivado 2025.2 build.
# This diagnostic-only flow preserves the accepted G2B source/IP/XDC order,
# adds only the raw-marker event trace and its CDC constraints, never reads a
# checkpoint, and never emits an LTX/debug-probes file.

if {$argc != 6} {
  puts stderr "usage: g2b_bt656_diag1_build.tcl REPO_ROOT BUILD_ROOT EVIDENCE_ROOT SOURCE_COMMIT SOURCE_TREE BIT_FILENAME"
  exit 2
}
lassign $argv repo_root build_root evidence_root source_commit source_tree bit_filename
set repo_root [file normalize $repo_root]
set build_root [file normalize $build_root]
set evidence_root [file normalize $evidence_root]

set expected_branch diag/v41-g2b-bt656-boundary-trace
set accepted_product_parent 92e9b3d914134c044371779def1ee18eaaeda98a
set expected_part xc7a35tcsg325-2
set expected_top ahd_capture_top_xdma
set expected_vivado_version 2025.2
set expected_vivado_build 6299465

set sv_rel_files {
  rtl/v41/axi_lite_host_bridge.sv
  rtl/v41/axi_clock_lifecycle_monitor.sv
  rtl/v41/axi_clock_measurement_regs.sv
  rtl/v41/r1e_measurement_regs.sv
  rtl/v41/r1h_probe_index_bram_store.sv
  rtl/v41/nvp_i2c_tri_phase_probe.sv
  rtl/v41/r1f_failed_txn_logger.sv
  rtl/v41/r1f_measurement_regs.sv
  rtl/v41/r1h_mmio_read_service.sv
  rtl/v41/g2b_product_profile_read_service.sv
  rtl/v41/control_status_regs.sv
  rtl/pio/pio_slot_adapter.sv
  rtl/pio/pio_bar_target.sv
  rtl/record/bt656_record_producer.sv
  rtl/record/capture_mailbox.sv
  rtl/video/video_capture.sv
  rtl/video/physical_frontend.sv
  rtl/g2b/v41_g2b_mmio_router.sv
  rtl/g2b/v41_g2b_onech_c2h.sv
  rtl/diagnostic/g2b_bt656_boundary_trace.sv
  rtl/top/ahd_capture_top_xdma.sv
}
set vhdl_rel_files {
  rtl/nvp/nvp6134c_diagnostics_pkg.vhd
  rtl/nvp/r1f_transaction_serial_counter.vhd
  rtl/nvp/nvp6134c_i2c_bringup.vhd
  rtl/nvp/nvp6134c_autoinit.vhd
}
set xdc_rel_files {
  xdc/boards/current/xdma_pcie.xdc
  xdc/boards/current/pins.xdc
  xdc/boards/current/vdo_input_timing.xdc
  xdc/boards/current/pcie_pio.xdc
  xdc/boards/current/nvp_control.xdc
  xdc/common/cdc.xdc
  xdc/common/g2b_cdc.xdc
  xdc/common/g2b_bt656_diag1_cdc.xdc
  xdc/common/configuration_bank.xdc
}

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

proc write_text {path value} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  puts -nonewline $fh $value
  close $fh
}

proc read_text {path} {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set value [read $fh]
  close $fh
  return $value
}

proc sha256_file {path} {
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}

proc git_value {args} {
  global repo_root
  return [string trim [exec git --no-optional-locks -C $repo_root {*}$args]]
}

proc require_files {paths} {
  foreach path $paths {
    if {![file isfile $path]} { error "required build input missing: $path" }
  }
}

proc effective_config_dict {ip} {
  set result [dict create]
  foreach property [lsort [list_property $ip]] {
    if {[string match {CONFIG.*} $property]} {
      dict set result $property [get_property $property $ip]
    }
  }
  return $result
}

proc assert_config_dict_equal {expected actual label} {
  if {[lsort [dict keys $expected]] ne [lsort [dict keys $actual]]} {
    error "$label CONFIG property-name drift"
  }
  foreach property [dict keys $expected] {
    if {[dict get $expected $property] ne [dict get $actual $property]} {
      error "$label CONFIG drift for $property"
    }
  }
}

proc utilization_row {text wanted} {
  set normalized_wanted [string trimright $wanted "*"]
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
    if {[llength $columns] < 7} { continue }
    set actual [string trimright [string trim [lindex $columns 1]] "*"]
    if {$actual ne $normalized_wanted} { continue }
    set used [string map [list "," "" " " ""] [string trim [lindex $columns 2]]]
    set available [string map [list "," "" " " ""] [string trim [lindex $columns 5]]]
    if {![string is double -strict $used] ||
        ![string is double -strict $available] || $available <= 0.0} {
      error "invalid utilization row $wanted"
    }
    return [list $used $available]
  }
  error "utilization row not found: $wanted"
}

proc resource_metrics {report_path args} {
  if {[llength $args] == 0} {
    set text [report_utilization -return_string]
  } else {
    set text [report_utilization -cells [lindex $args 0] -return_string]
  }
  write_text $report_path $text
  lassign [utilization_row $text "Slice LUTs"] lut_used lut_available
  lassign [utilization_row $text "Slice Registers"] ff_used ff_available
  lassign [utilization_row $text "Block RAM Tile"] bram_used bram_available
  return [dict create \
    LUT_USED $lut_used LUT_AVAILABLE $lut_available \
    LUT_PERCENT [expr {100.0 * $lut_used / $lut_available}] \
    FF_USED $ff_used FF_AVAILABLE $ff_available \
    FF_PERCENT [expr {100.0 * $ff_used / $ff_available}] \
    BRAM_USED $bram_used BRAM_AVAILABLE $bram_available \
    BRAM_PERCENT [expr {100.0 * $bram_used / $bram_available}]]
}

proc severity_counts {objects} {
  set errors 0
  set critical 0
  set warnings 0
  set unknown 0
  foreach object $objects {
    set severity [string toupper [get_property -quiet SEVERITY $object]]
    if {$severity eq "ERROR"} { incr errors }
    if {$severity eq "CRITICAL" || $severity eq "CRITICAL WARNING"} {
      incr critical
    }
    if {$severity eq "WARNING"} { incr warnings }
    if {$severity eq "UNKNOWN" || $severity eq ""} { incr unknown }
  }
  return [list $errors $critical $warnings $unknown]
}

# Resolve every critical CDC row to one reviewed protocol class. Existing G2B
# stable-data/toggle and generated XDMA PIPE crossings retain their accepted
# disposition. DIAG1 may add only its Max-Delay-bounded frozen-data mailbox.
proc audit_cdc_report {path} {
  set baseline_cdc1 0
  set baseline_cdc10 0
  set baseline_cdc13 0
  set diag_cdc1 0
  set total 0
  set unresolved [list]
  foreach line [split [read_text $path] "\n"] {
    if {![regexp {^[ \t]*[0-9]+[ \t]+(CDC-[0-9]+)[ \t]+Critical[ \t]+} $line -> id]} {
      continue
    }
    incr total
    if {[string first "BT656_BOUNDARY_TRACE" $line] >= 0} {
      if {$id eq "CDC-1" &&
          [string first "Max Delay Datapath Only" $line] >= 0 &&
          [regexp {BT656_BOUNDARY_TRACE/(valid_entries|pre_count|pre_start|post_count|trigger|stop_reason|clocks_since_trigger)} $line]} {
        incr diag_cdc1
      } else {
        lappend unresolved $line
      }
    } elseif {$id eq "CDC-1" &&
              [string first "G2B_ONECH_C2H" $line] >= 0 &&
              [string first "Max Delay Datapath Only" $line] >= 0} {
      incr baseline_cdc1
    } elseif {$id eq "CDC-10" &&
              [string first "G2B_ONECH_C2H" $line] >= 0 &&
              [string first "False Path" $line] >= 0} {
      incr baseline_cdc10
    } elseif {$id eq "CDC-13" && [string first "XDMA/" $line] >= 0 &&
              [string first "False Path" $line] >= 0} {
      incr baseline_cdc13
    } else {
      lappend unresolved $line
    }
  }
  return [dict create TOTAL $total BASELINE_CDC1 $baseline_cdc1 \
    BASELINE_CDC10 $baseline_cdc10 BASELINE_CDC13 $baseline_cdc13 \
    DIAG_CDC1 $diag_cdc1 UNRESOLVED $unresolved]
}

set stage PRECHECK
set source_manifest_path [file join $evidence_root DIAG1_SOURCE_MANIFEST_SHA256.txt]
set build_report_path [file join $evidence_root DIAG1_BUILD_REPORT.md]
set bit_path [file join $evidence_root artifacts $bit_filename]

set build_status [catch {
  if {![file isdirectory $repo_root]} { error "repository root missing" }
  if {[file exists $build_root] && [llength [glob -nocomplain -directory $build_root *]] != 0} {
    error "build root is not fresh"
  }
  if {[file exists $evidence_root] && [llength [glob -nocomplain -directory $evidence_root *]] != 0} {
    error "evidence root is not fresh"
  }
  if {[file tail $bit_filename] ne $bit_filename ||
      ![string equal -nocase [file extension $bit_filename] ".bit"]} {
    error "bit filename must be a .bit leaf"
  }
  if {![regexp {^[0-9a-f]{40}$} $source_commit] ||
      ![regexp {^[0-9a-f]{40}$} $source_tree]} {
    error "source commit/tree format invalid"
  }
  file mkdir $build_root
  file mkdir $evidence_root
  file mkdir [file dirname $bit_path]

  set actual_commit [git_value rev-parse HEAD]
  set actual_tree [git_value rev-parse {HEAD^{tree}}]
  set actual_branch [git_value symbolic-ref --short HEAD]
  set actual_merge_base [git_value merge-base HEAD $accepted_product_parent]
  set actual_status [git_value status --porcelain --untracked-files=all]
  if {$actual_commit ne $source_commit || $actual_tree ne $source_tree ||
      $actual_branch ne $expected_branch ||
      $actual_merge_base ne $accepted_product_parent || $actual_status ne ""} {
    error "clean diagnostic source identity mismatch"
  }

  set all_rel_files [concat $sv_rel_files $vhdl_rel_files $xdc_rel_files [list \
    ip/v41/xdma_v41_m1.xci scripts/v41/xdma_config_common.tcl \
    scripts/v41/g2b_bt656_diag1_build.tcl]]
  set all_files [list]
  set manifest_lines [list]
  foreach rel $all_rel_files {
    set path [file join $repo_root $rel]
    lappend all_files $path
  }
  require_files $all_files
  foreach rel $all_rel_files {
    lappend manifest_lines "$rel|[sha256_file [file join $repo_root $rel]]"
  }
  write_lines $source_manifest_path $manifest_lines
  set source_manifest_sha [sha256_file $source_manifest_path]

  set vivado_version [string trim [version -short]]
  regexp {SW Build[ \t]+([0-9]+)} [version] -> vivado_build
  if {$vivado_version ne $expected_vivado_version ||
      $vivado_build ne $expected_vivado_build} {
    error "wrong Vivado version/build: $vivado_version/$vivado_build"
  }

  set stage PROJECT_AND_IP
  cd $build_root
  create_project g2b_bt656_diag1 [file join $build_root vivado_project] \
    -part $expected_part
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
  set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
  config_ip_cache -use_cache_location [file join $build_root ip_cache]

  set sv_files [list]
  foreach rel $sv_rel_files { lappend sv_files [file join $repo_root $rel] }
  set vhdl_files [list]
  foreach rel $vhdl_rel_files { lappend vhdl_files [file join $repo_root $rel] }
  set xdc_files [list]
  foreach rel $xdc_rel_files { lappend xdc_files [file join $repo_root $rel] }
  add_files -norecurse $sv_files
  set_property FILE_TYPE SystemVerilog [get_files $sv_files]
  add_files -norecurse $vhdl_files

  source [file join $repo_root scripts v41 xdma_config_common.tcl]
  set xdma_source [file join $repo_root ip v41 xdma_v41_m1.xci]
  set xdma_dir [file join $build_root input_xci]
  file mkdir $xdma_dir
  set xdma_copy [file join $xdma_dir xdma_v41_m1.xci]
  file copy $xdma_source $xdma_copy
  import_ip -files $xdma_copy
  set xdma_ip [get_ips -quiet xdma_v41_m1]
  if {[llength $xdma_ip] != 1} { error "exact XDMA IP object absent" }
  v41_xdma::configure_minimal_c2h_stream $xdma_ip
  v41_xdma::assert_frozen_g1_invariants $xdma_ip
  set configured_xdma [effective_config_dict $xdma_ip]
  set imported_xci [get_files -quiet [get_property IP_FILE $xdma_ip]]
  set_property GENERATE_SYNTH_CHECKPOINT false $imported_xci
  generate_target all $xdma_ip
  assert_config_dict_equal $configured_xdma [effective_config_dict $xdma_ip] \
    "generated XDMA"
  v41_xdma::assert_frozen_g1_invariants $xdma_ip
  v41_xdma::dump_effective_config $xdma_ip \
    [file join $evidence_root DIAG1_XDMA_EFFECTIVE_CONFIG.txt]

  add_files -fileset constrs_1 -norecurse $xdc_files
  set_property PROCESSING_ORDER EARLY [get_files [lindex $xdc_files 0]]
  set_property PROCESSING_ORDER LATE [get_files [lrange $xdc_files 1 end]]
  set git_words [list]
  for {set i 0} {$i < 5} {incr i} {
    lappend git_words [string range $source_commit [expr {$i*8}] [expr {$i*8+7}]]
  }
  set generics "SLOT_COUNT=2"
  for {set i 0} {$i < 5} {incr i} {
    append generics " GIT_SHA_W$i=32'h[lindex $git_words $i]"
  }
  append generics " BUILD_FLAGS=32'h00000402 ENABLE_MAREK_INIT_TABLE=1"
  append generics " ENABLE_RTRACK_DIAGNOSTICS=0 ENABLE_BT656_DIAG1=1"
  set_property top $expected_top [get_filesets sources_1]
  set_property generic $generics [get_filesets sources_1]
  update_compile_order -fileset sources_1
  report_compile_order -fileset sources_1 -used_in synthesis \
    -file [file join $evidence_root DIAG1_COMPILE_ORDER.rpt]

  set stage SYNTHESIS
  synth_design -top $expected_top -part $expected_part -flatten_hierarchy rebuilt
  set trace_cells [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE.*}]
  if {[llength $trace_cells] == 0} {
    error "diagnostic trace did not elaborate"
  }
  if {[llength [get_cells -quiet -hier -regexp {.*POST_INIT_TRI_PHASE_PROBE.*}]] != 0} {
    error "unrelated R-track diagnostic elaborated"
  }
  write_checkpoint -force [file join $evidence_root DIAG1_SYNTH.dcp]
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $evidence_root DIAG1_SYNTH_UTILIZATION_HIER.rpt]
  report_timing_summary -delay_type min_max -max_paths 100 \
    -file [file join $evidence_root DIAG1_SYNTH_TIMING_SUMMARY.rpt]

  set stage OPT_DESIGN
  opt_design
  write_checkpoint -force [file join $evidence_root DIAG1_POST_OPT.dcp]

  set stage PLACE_DESIGN
  place_design
  set stage PHYS_OPT_DESIGN
  phys_opt_design
  set stage ROUTE_DESIGN
  route_design -directive AggressiveExplore
  set routed_dcp [file join $evidence_root DIAG1_ROUTED.dcp]
  write_checkpoint -force $routed_dcp

  set stage ROUTED_REPORTS_AND_GATES
  set route_report [file join $evidence_root DIAG1_ROUTE_STATUS.rpt]
  report_route_status -file $route_report
  set fully_routed [report_route_status -boolean_check ROUTED_FULLY]
  set errors_in_routes [report_route_status -boolean_check ERRORS_IN_ROUTES]
  set unrouted_nets [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial_nets [llength [report_route_status -return_nets -route_type PARTIAL]]
  report_timing_summary -delay_type min_max -max_paths 1000 \
    -report_unconstrained -check_timing_verbose \
    -file [file join $evidence_root DIAG1_TIMING_SUMMARY.rpt]
  report_timing -delay_type max -max_paths 1000 -nworst 10 \
    -file [file join $evidence_root DIAG1_SETUP_TIMING.rpt]
  report_timing -delay_type min -max_paths 1000 -nworst 10 \
    -file [file join $evidence_root DIAG1_HOLD_TIMING.rpt]
  check_timing -verbose -file [file join $evidence_root DIAG1_CHECK_TIMING.rpt]
  report_drc -file [file join $evidence_root DIAG1_DRC.rpt]
  set cdc_report [file join $evidence_root DIAG1_CDC.rpt]
  report_cdc -details -file $cdc_report
  report_methodology -file [file join $evidence_root DIAG1_METHODOLOGY.rpt]
  report_exceptions -coverage -file [file join $evidence_root DIAG1_EXCEPTION_COVERAGE.rpt]
  report_clock_interaction -file [file join $evidence_root DIAG1_CLOCK_INTERACTION.rpt]
  report_ram_utilization -file [file join $evidence_root DIAG1_RAM_UTILIZATION.rpt]

  if {$fully_routed != 1 || $errors_in_routes != 0 ||
      $unrouted_nets != 0 || $partial_nets != 0} {
    error "route gate failed"
  }
  set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
  set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
  if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1} {
    error "timing path class absent"
  }
  set wns [get_property SLACK [lindex $worst_setup 0]]
  set whs [get_property SLACK [lindex $worst_hold 0]]
  set setup_failures [llength [get_timing_paths -quiet -delay_type max \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set hold_failures [llength [get_timing_paths -quiet -delay_type min \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  if {$wns < 0.0 || $whs < 0.0 || $setup_failures != 0 || $hold_failures != 0} {
    error "timing gate failed WNS=$wns WHS=$whs"
  }
  set tns 0.0
  set ths 0.0

  lassign [severity_counts [get_drc_violations -quiet]] \
    drc_errors drc_critical drc_warnings drc_unknown
  if {$drc_errors != 0 || $drc_critical != 0} {
    error "DRC gate failed errors=$drc_errors critical=$drc_critical"
  }
  lassign [severity_counts [get_cdc_violations -quiet]] \
    cdc_errors cdc_critical cdc_warnings cdc_unknown
  set cdc_audit [audit_cdc_report $cdc_report]
  set unresolved_cdc [dict get $cdc_audit UNRESOLVED]
  if {$cdc_errors != 0 || $cdc_unknown != 0 ||
      [llength $unresolved_cdc] != 0 ||
      [dict get $cdc_audit TOTAL] != $cdc_critical} {
    write_lines [file join $evidence_root DIAG1_UNRESOLVED_CDC.txt] \
      $unresolved_cdc
    error "unresolved CDC gate failed errors=$cdc_errors critical=$cdc_critical parsed=[dict get $cdc_audit TOTAL] unresolved=[llength $unresolved_cdc]"
  }
  write_lines [file join $evidence_root DIAG1_CDC_DISPOSITION.txt] [list \
    {CDC_GATE=PASS_ALL_CRITICAL_ROWS_EXACT_PROTOCOL_DISPOSITION} \
    "CDC_TOTAL_CRITICAL=$cdc_critical" \
    "BASELINE_CDC1=[dict get $cdc_audit BASELINE_CDC1]" \
    "BASELINE_CDC10=[dict get $cdc_audit BASELINE_CDC10]" \
    "BASELINE_CDC13=[dict get $cdc_audit BASELINE_CDC13]" \
    "DIAG1_FROZEN_METADATA_CDC1=[dict get $cdc_audit DIAG_CDC1]" \
    {UNRESOLVED_CRITICAL_CDC=0} \
    {BROAD_CDC_WAIVER=NO}]

  lassign [severity_counts [get_methodology_violations -quiet]] \
    methodology_errors methodology_critical methodology_warnings methodology_unknown
  if {$methodology_errors != 0 || $methodology_critical != 0 ||
      $methodology_unknown != 0} {
    error "methodology gate failed errors=$methodology_errors critical=$methodology_critical unknown=$methodology_unknown"
  }
  set black_boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
  if {[llength $black_boxes] != 0} {
    error "black-box gate failed count=[llength $black_boxes]"
  }

  set total_metrics [resource_metrics \
    [file join $evidence_root DIAG1_ROUTED_UTILIZATION_FLAT.rpt]]
  set trace_cells [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE.*}]
  set trace_metrics [resource_metrics \
    [file join $evidence_root DIAG1_TRACE_UTILIZATION.rpt] $trace_cells]
  if {[dict get $total_metrics LUT_PERCENT] > 98.0 ||
      [dict get $total_metrics FF_PERCENT] > 95.0 ||
      [dict get $total_metrics BRAM_PERCENT] > 90.0} {
    error "diagnostic resource gate failed"
  }

  # Structural coverage for the DIAG1 CDC scheme.
  set trace_sync1 [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE/(clear_sync1_source|arm_sync1_source|abort_sync1_source|armed_sync1_axi|triggered_sync1_axi|done_sync1_axi|overflow_sync1_axi)_reg}]
  set trace_metadata_src [filter [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE/(valid_entries_source|pre_count_source|pre_start_source|post_count_source|trigger_logical_index_source|stop_reason_source|trigger_frame_source|trigger_line_source|clocks_since_trigger_source)_reg.*}] {IS_SEQUENTIAL == 1}]
  set trace_metadata_dst [filter [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE/(valid_entries_sync1_axi|pre_count_sync1_axi|pre_start_sync1_axi|post_count_sync1_axi|trigger_index_sync1_axi|stop_reason_sync1_axi|trigger_frame_sync1_axi|trigger_line_sync1_axi|trigger_clocks_sync1_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
  set trace_metadata_d [get_pins -quiet -of_objects $trace_metadata_dst -filter {REF_PIN_NAME == D}]
  if {[llength $trace_sync1] != 7 || [llength $trace_metadata_src] == 0 ||
      [llength $trace_metadata_dst] == 0 || [llength $trace_metadata_d] == 0} {
    error "DIAG1 CDC structural collection gate failed"
  }
  foreach cell $trace_sync1 {
    if {[string toupper [get_property ASYNC_REG $cell]] ne "TRUE"} {
      error "DIAG1 synchronizer lacks ASYNC_REG: [get_property NAME $cell]"
    }
  }
  report_timing -delay_type max -from $trace_metadata_src \
    -to $trace_metadata_d -max_paths 500 \
    -file [file join $evidence_root DIAG1_FROZEN_METADATA_TIMING.rpt]

  write_lines [file join $evidence_root DIAG1_PRE_BITSTREAM_GATE.txt] [list \
    {PROFILE=G2B_BT656_DIAG1} \
    {CLASSIFICATION=DIAGNOSTIC_ONLY_NOT_A_PRODUCT_CANDIDATE} \
    {SYNTHESIS=PASS} {IMPLEMENTATION=PASS} \
    "FULLY_ROUTED=$fully_routed" "UNROUTED_NETS=$unrouted_nets" \
    "PARTIAL_NETS=$partial_nets" "WNS=$wns" "TNS=$tns" \
    "WHS=$whs" "THS=$ths" \
    "DRC_ERRORS=$drc_errors" "DRC_CRITICAL_WARNINGS=$drc_critical" \
    {UNRESOLVED_CRITICAL_CDC=0} \
    {UNRESOLVED_METHODOLOGY_ERRORS=0} \
    "METHODOLOGY_WARNINGS=$methodology_warnings" \
    "LUT_USED=[dict get $total_metrics LUT_USED]" \
    "LUT_PERCENT=[format %.3f [dict get $total_metrics LUT_PERCENT]]" \
    {LUT_LIMIT_PERCENT=98.000} \
    "FF_USED=[dict get $total_metrics FF_USED]" \
    "FF_PERCENT=[format %.3f [dict get $total_metrics FF_PERCENT]]" \
    {FF_LIMIT_PERCENT=95.000} \
    "BRAM_USED=[dict get $total_metrics BRAM_USED]" \
    "BRAM_PERCENT=[format %.3f [dict get $total_metrics BRAM_PERCENT]]" \
    {BRAM_LIMIT_PERCENT=90.000} \
    "TRACE_LUT_USED=[dict get $trace_metrics LUT_USED]" \
    "TRACE_FF_USED=[dict get $trace_metrics FF_USED]" \
    "TRACE_BRAM_USED=[dict get $trace_metrics BRAM_USED]" \
    {CHECKPOINT_REUSE=NO} {LTX_GENERATED=NO} {RESULT=PASS}]

  set stage BITSTREAM
  write_bitstream $bit_path
  if {![file isfile $bit_path] || [file size $bit_path] == 0} {
    error "diagnostic bitstream missing"
  }
  set bit_sha [sha256_file $bit_path]
  set routed_sha [sha256_file $routed_dcp]
  set synth_sha [sha256_file [file join $evidence_root DIAG1_SYNTH.dcp]]
  set post_opt_sha [sha256_file [file join $evidence_root DIAG1_POST_OPT.dcp]]
  write_lines $build_report_path [list \
    {# G2B BT656 DIAG1 build report} {} \
    "- Profile: G2B_BT656_DIAG1" \
    "- Classification: BT656_DIAG1_RAW_MARKER_TRACE_CANDIDATE" \
    "- Source commit: $source_commit" \
    "- Source tree: $source_tree" \
    "- Vivado: $vivado_version build $vivado_build" \
    "- Full nonincremental build: PASS" \
    "- Checkpoint reuse: NO" \
    "- Fully routed: YES" \
    "- WNS/TNS: $wns / $tns" \
    "- WHS/THS: $whs / $ths" \
    "- DRC errors/critical warnings: $drc_errors / $drc_critical" \
    "- Unresolved critical CDC: 0" \
    "- Unresolved methodology errors: 0" \
    "- Total LUT/FF/BRAM percentages: [format %.3f [dict get $total_metrics LUT_PERCENT]] / [format %.3f [dict get $total_metrics FF_PERCENT]] / [format %.3f [dict get $total_metrics BRAM_PERCENT]]" \
    "- Trace LUT/FF/BRAM: [dict get $trace_metrics LUT_USED] / [dict get $trace_metrics FF_USED] / [dict get $trace_metrics BRAM_USED]" \
    "- Bitstream SHA-256: $bit_sha" \
    "- Routed DCP SHA-256: $routed_sha" \
    "- Source manifest SHA-256: $source_manifest_sha" \
    "- LTX generated: NO"]
  set report_sha [sha256_file $build_report_path]
  write_lines [file join $evidence_root DIAG1_BUILD_HASHES.txt] [list \
    "BITSTREAM_SHA256=$bit_sha" "SYNTH_DCP_SHA256=$synth_sha" \
    "POST_OPT_DCP_SHA256=$post_opt_sha" "ROUTED_DCP_SHA256=$routed_sha" \
    "SOURCE_MANIFEST_SHA256=$source_manifest_sha" \
    "MAIN_BUILD_REPORT_SHA256=$report_sha"]
  write_lines [file join $evidence_root DIAG1_BUILD_RESULT.txt] [list \
    {RESULT=PASS} {BUILD_CLASSIFICATION=BT656_DIAG1_RAW_MARKER_TRACE_CANDIDATE} \
    "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
    "BITSTREAM=$bit_path" "BITSTREAM_SHA256=$bit_sha" \
    "ROUTED_DCP_SHA256=$routed_sha" {LTX_GENERATED=NO}]
  puts "BT656_DIAG1_BUILD_PASS BITSTREAM=$bit_path SHA256=$bit_sha"
} build_error build_options]

if {$build_status != 0} {
  catch {write_lines [file join $evidence_root DIAG1_BUILD_RESULT.txt] [list \
    {RESULT=FAIL} "STAGE=$stage" "FIRST_FAILURE=$build_error"]}
  puts stderr "BT656_DIAG1_BUILD_FAIL STAGE=$stage ERROR=$build_error"
  catch {close_project}
  exit 1
}
catch {close_project}
exit 0
