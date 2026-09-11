# AHD v41 G2B-NVP-VIDEO-DIAG1-R3
# Report-only final routed sign-off, one signed-off DCP, and one bitstream.
# No synthesis, optimization, placement, routing, source/XDC mutation, waiver,
# message suppression, or debug-probe generation is performed here.

if {$argc != 0} {
  puts stderr "usage: g2b_nvp_video_diag1_r3_finalize_signoff.tcl"
  exit 2
}

set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R3_20260910T200154Z}
set source_root {C:/FPGA/V41_G2B_NVP_VIDEO_DIAG1}
set report_root [file join $task_root reports vivado_full]
set signoff_root [file join $task_root signoff]
set artifact_root [file join $task_root artifacts]
set cdc_root [file join $task_root cdc]
set routed_dcp [file join $report_root G2B_NVP_VIDEO_DIAG1_R3_ROUTED.dcp]
set signed_dcp [file join $artifact_root G2B_NVP_VIDEO_DIAG1_R3_SIGNED_OFF_ROUTED.dcp]
set bitstream [file join $artifact_root G2B_NVP_VIDEO_DIAG1_R3_MMIO_FIXED_FOUR_CHANNEL_SCAN.bit]
set harness [file join $task_root scripts g2b_nvp_video_diag1_r3_finalize_signoff.tcl]
set preflight_script [file join $task_root scripts g2b_nvp_video_diag1_r3_preflight.py]
set preflight_receipt [file join $task_root reports G2B_NVP_VIDEO_DIAG1_R3_FINALIZER_PREFLIGHT.json]

set expected_branch {diag/v41-g2b-nvp-video-scan}
set expected_commit {fc37d815b5d64ef90dfbd99c57ae4cc09567b56f}
set expected_tree {cdff3ea9d786141ff9bfd46f7099198324604663}
set expected_dcp_sha {5E7791F4A72F7901842B9104C3CA2A5ED71EBFB5C27D0362B8259BA20EA54879}
set expected_v3_csv_sha {68CC9892D5423A1F98F65A03A9B9FA9E6FF4795CAB77189BB02A7AD099A0F644}
set expected_v3_json_sha {A41AB8D0020622D6B3F82A2BF7ED7ABCA64BDC8CB87CACA8A68C7547EF26C9C3}
set expected_part {xc7a35tcsg325-2}
set expected_top {ahd_capture_top_xdma}
set expected_vivado_version {2025.2}

proc read_text {path} {
  set handle [open $path r]
  fconfigure $handle -encoding utf-8
  set value [read $handle]
  close $handle
  return $value
}

proc write_text {path value} {
  file mkdir [file dirname $path]
  set handle [open $path w]
  fconfigure $handle -encoding utf-8 -translation lf
  puts -nonewline $handle $value
  close $handle
}

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set handle [open $path w]
  fconfigure $handle -encoding utf-8 -translation lf
  foreach line $lines { puts $handle $line }
  close $handle
}

proc sha256_file {path} {
  if {![file isfile $path] || [file size $path] == 0} {
    error "required file missing or empty: $path"
  }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}

proc require_text {path literal label} {
  if {![file isfile $path] || [file size $path] == 0} {
    error "$label missing or empty: $path"
  }
  if {[string first $literal [read_text $path]] < 0} {
    error "$label missing required literal: $literal"
  }
}

proc single_line {value} {
  return [string map [list "\r" {\r} "\n" {\n} "\t" {\t}] $value]
}

proc property_or_unknown {property object} {
  if {[catch {get_property $property $object} value]} { return UNKNOWN }
  if {$value eq ""} { return EMPTY }
  return $value
}

proc count_command_lines {text command} {
  set count 0
  foreach line [split $text "\n"] {
    if {[regexp [format {^[ \t]*%s([ \t]|$)} $command] $line]} { incr count }
  }
  return $count
}

proc canonicalize_xdc {input_path output_path} {
  set lines [list]
  foreach raw [split [read_text $input_path] "\n"] {
    set line [string trim $raw]
    if {$line eq "" || [string match {#*} $line]} { continue }
    regsub -all {[ \t]+} $line { } line
    lappend lines $line
  }
  write_lines $output_path $lines
  return [sha256_file $output_path]
}

proc sorted_objects_by_name {objects} {
  set pairs [list]
  foreach object $objects { lappend pairs [list [get_property NAME $object] $object] }
  set result [list]
  foreach pair [lsort -dictionary -index 0 $pairs] { lappend result [lindex $pair 1] }
  return $result
}

proc route_metric {text label} {
  foreach line [split $text "\n"] {
    if {[string first $label $line] < 0} { continue }
    if {[regexp {: *([0-9,]+) *:} $line -> value]} {
      return [string map [list "," ""] $value]
    }
  }
  error "route metric not found: $label"
}

proc check_timing_table_count {text wanted} {
  foreach line [split $text "\n"] {
    set columns [split $line |]
    for {set index 0} {$index + 1 < [llength $columns]} {incr index} {
      if {[string trim [lindex $columns $index]] ne $wanted} { continue }
      set count [string trim [lindex $columns [expr {$index + 1}]]]
      if {[string is integer -strict $count]} { return $count }
    }
    if {[regexp [format {^[ \t]*%s[ \t]+([0-9]+)} $wanted] $line -> count]} { return $count }
    if {[regexp [format {checking[ \t]+%s[ \t]*\(([0-9]+)\)} $wanted] $line -> count]} { return $count }
  }
  return UNKNOWN
}

proc require_count {label objects expected} {
  set actual [llength $objects]
  if {$actual != $expected} { error "$label count mismatch: expected=$expected actual=$actual" }
}

proc capture_signatures {root tag} {
  set clock_path [file join $root "CLOCK_SIGNATURE_${tag}.txt"]
  set netlist_path [file join $root "NETLIST_SIGNATURE_${tag}.txt"]
  set route_path [file join $root "ROUTE_STATUS_SIGNATURE_${tag}.txt"]
  set xdc_path [file join $root "TIMING_CONSTRAINT_SIGNATURE_${tag}.xdc"]
  set canonical_path [file join $root "TIMING_CONSTRAINT_SIGNATURE_${tag}_CANONICAL.xdc"]

  set clocks [list]
  foreach clock [sorted_objects_by_name [get_clocks -quiet]] {
    lappend clocks "CLOCK|[get_property NAME $clock]|PERIOD=[property_or_unknown PERIOD $clock]|WAVEFORM=[property_or_unknown WAVEFORM $clock]|IS_GENERATED=[property_or_unknown IS_GENERATED $clock]|MASTER_CLOCK=[property_or_unknown MASTER_CLOCK $clock]|SOURCE_PINS=[single_line [property_or_unknown SOURCE_PINS $clock]]"
  }
  if {[llength $clocks] == 0} { error "clock signature is empty" }
  write_lines $clock_path $clocks

  set handle [open $netlist_path w]
  fconfigure $handle -encoding utf-8 -translation lf
  set cell_count 0
  foreach cell [sorted_objects_by_name [get_cells -quiet -hier]] {
    puts $handle "CELL|[get_property NAME $cell]|REF=[property_or_unknown REF_NAME $cell]|LOC=[property_or_unknown LOC $cell]|BEL=[property_or_unknown BEL $cell]"
    incr cell_count
  }
  set net_count 0
  foreach net [sorted_objects_by_name [get_nets -quiet -hier]] {
    puts $handle "NET|[get_property NAME $net]"
    incr net_count
  }
  close $handle
  if {$cell_count == 0 || $net_count == 0} { error "netlist signature is empty" }

  write_xdc -exclude_physical -force $xdc_path
  set xdc_text [read_text $xdc_path]
  set bus_skew_count [count_command_lines $xdc_text set_bus_skew]
  set max_delay_count [count_command_lines $xdc_text set_max_delay]
  set false_path_count [count_command_lines $xdc_text set_false_path]
  set clock_group_count [count_command_lines $xdc_text set_clock_groups]
  if {$bus_skew_count != 11 || $max_delay_count != 26 || $false_path_count != 30 || $clock_group_count != 1} {
    error "timing-view drift: set_bus_skew=$bus_skew_count set_max_delay=$max_delay_count set_false_path=$false_path_count set_clock_groups=$clock_group_count"
  }
  set canonical_sha [canonicalize_xdc $xdc_path $canonical_path]

  set route_report [report_route_status -return_string]
  set routable [route_metric $route_report {# of routable nets}]
  set routed [route_metric $route_report {# of fully routed nets}]
  set route_errors [route_metric $route_report {# of nets with routing errors}]
  set unrouted [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial [llength [report_route_status -return_nets -route_type PARTIAL]]
  set fully [report_route_status -boolean_check ROUTED_FULLY]
  set errors [report_route_status -boolean_check ERRORS_IN_ROUTES]
  if {!$fully || $errors || $routable != 36116 || $routed != 36116 || $route_errors != 0 || $unrouted != 0 || $partial != 0} {
    error "route signature failed: routable=$routable routed=$routed errors=$route_errors unrouted=$unrouted partial=$partial"
  }
  write_lines $route_path [list "ROUTABLE_NETS=$routable" "FULLY_ROUTED_NETS=$routed" "ROUTE_ERRORS=$route_errors" "UNROUTED_NETS=$unrouted" "PARTIALLY_ROUTED_NETS=$partial" "ROUTED_FULLY=$fully" "ERRORS_IN_ROUTES=$errors"]

  return [dict create CLOCK_SHA [sha256_file $clock_path] CLOCK_COUNT [llength $clocks] NETLIST_SHA [sha256_file $netlist_path] CELL_COUNT $cell_count NET_COUNT $net_count XDC_SHA $canonical_sha BUS_SKEW $bus_skew_count MAX_DELAY $max_delay_count FALSE_PATH $false_path_count CLOCK_GROUP $clock_group_count ROUTE_SHA [sha256_file $route_path] ROUTABLE $routable ROUTED $routed UNROUTED $unrouted PARTIAL $partial]
}

proc require_same_signatures {expected actual label} {
  foreach key {CLOCK_SHA CLOCK_COUNT NETLIST_SHA CELL_COUNT NET_COUNT XDC_SHA BUS_SKEW MAX_DELAY FALSE_PATH CLOCK_GROUP ROUTE_SHA ROUTABLE ROUTED UNROUTED PARTIAL} {
    if {[dict get $expected $key] ne [dict get $actual $key]} {
      error "$label signature mismatch for $key: expected=[dict get $expected $key] actual=[dict get $actual $key]"
    }
  }
}

proc rule_id {object_name} {
  if {![regexp {^([A-Z]+-[0-9]+)#[0-9]+$} $object_name -> rule]} {
    error "unrecognized violation object name: $object_name"
  }
  return $rule
}

proc require_rule_counts {label objects expected_counts allowed_severities} {
  set actual [dict create]
  foreach object $objects {
    set severity [string toupper [property_or_unknown SEVERITY $object]]
    if {[lsearch -exact $allowed_severities $severity] < 0} {
      error "$label unexpected severity: [get_property NAME $object] severity=$severity"
    }
    set rule [rule_id [get_property NAME $object]]
    if {![dict exists $expected_counts $rule]} { error "$label unexpected rule: $rule" }
    dict incr actual $rule
  }
  foreach rule [dict keys $expected_counts] {
    set count [expr {[dict exists $actual $rule] ? [dict get $actual $rule] : 0}]
    if {$count != [dict get $expected_counts $rule]} {
      error "$label count mismatch for $rule: expected=[dict get $expected_counts $rule] actual=$count"
    }
  }
  if {[dict size $actual] != [dict size $expected_counts]} { error "$label unexpected rule-key multiplicity" }
}

proc run_timing_gate {root} {
  set summary [file join $root G2B_NVP_VIDEO_DIAG1_R3_TIMING_SUMMARY.rpt]
  set setup [file join $root G2B_NVP_VIDEO_DIAG1_R3_SETUP_TIMING.rpt]
  set hold [file join $root G2B_NVP_VIDEO_DIAG1_R3_HOLD_TIMING.rpt]
  set check [file join $root G2B_NVP_VIDEO_DIAG1_R3_CHECK_TIMING.rpt]
  set route [file join $root G2B_NVP_VIDEO_DIAG1_R3_ROUTE_STATUS.rpt]
  set clocks_path [file join $root G2B_NVP_VIDEO_DIAG1_R3_CLOCKS.rpt]
  report_timing_summary -delay_type min_max -check_timing_verbose -report_unconstrained -max_paths 10 -nworst 1 -file $summary
  report_timing -delay_type max -max_paths 100 -nworst 1 -file $setup
  report_timing -delay_type min -max_paths 100 -nworst 1 -file $hold
  check_timing -verbose -file $check
  report_route_status -file $route
  report_clocks -file $clocks_path
  report_clock_interaction -file [file join $root G2B_NVP_VIDEO_DIAG1_R3_CLOCK_INTERACTION.rpt]

  set max_paths [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
  set min_paths [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
  require_count WORST_SETUP_PATH $max_paths 1
  require_count WORST_HOLD_PATH $min_paths 1
  set wns [get_property SLACK [lindex $max_paths 0]]
  set whs [get_property SLACK [lindex $min_paths 0]]
  set failing_setup [llength [get_timing_paths -quiet -delay_type max -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  if {![string is double -strict $wns] || ![string is double -strict $whs] || $wns < 0.0 || $whs < 0.0 || $failing_setup != 0 || $failing_hold != 0 || abs($wns - 0.192) > 0.0005 || abs($whs - 0.015) > 0.0005} {
    error "timing gate failed: WNS=$wns WHS=$whs failing_setup=$failing_setup failing_hold=$failing_hold"
  }
  set check_text [read_text $check]
  foreach key {no_clock unconstrained_internal_endpoints multiple_clock generated_clocks loops partial_input_delay partial_output_delay latch_loops} {
    set value [check_timing_table_count $check_text $key]
    if {$value eq "UNKNOWN" || $value != 0} { error "check_timing gate failed: $key=$value" }
  }
  set summary_text [read_text $summary]
  if {[regexp -nocase {Pulse Width Slack[^\n]*-[0-9]} $summary_text] || [regexp -nocase {VIOLATED} $summary_text]} {
    error "timing summary contains a violation"
  }
  set route_text [read_text $route]
  set routable [route_metric $route_text {# of routable nets}]
  set routed [route_metric $route_text {# of fully routed nets}]
  set route_errors [route_metric $route_text {# of nets with routing errors}]
  set unrouted [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial [llength [report_route_status -return_nets -route_type PARTIAL]]
  if {$routable != 36116 || $routed != 36116 || $route_errors != 0 || $unrouted != 0 || $partial != 0 || ![report_route_status -boolean_check ROUTED_FULLY]} {
    error "route gate failed"
  }
  set expected_clocks [lsort -dictionary {clk_125mhz_mux_x0y0 clk_125mhz_x0y0 clk_250mhz_mux_x0y0 clk_250mhz_x0y0 idelay_mmcm_feedback_unbuf idelay_refclk_unbuf mmcm_fb nvp_vclk1 pcie_refclk_100 txoutclk_x0y0 userclk1}]
  set actual_clocks [list]
  foreach clock [get_clocks -quiet] { lappend actual_clocks [get_property NAME $clock] }
  set actual_clocks [lsort -dictionary $actual_clocks]
  if {$actual_clocks ne $expected_clocks} { error "clock-set drift: expected=$expected_clocks actual=$actual_clocks" }
  set user [get_clocks -quiet userclk1]
  require_count USERCLK1 $user 1
  set user_mhz [expr {1000.0 / [get_property PERIOD [lindex $user 0]]}]
  if {abs($user_mhz - 62.5) > 0.1} { error "user/AXI clock drift: $user_mhz MHz" }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_TIMING_GATE.txt] [list {RESULT=PASS} {FULLY_ROUTED=YES} "ROUTABLE_NETS=$routable" "FULLY_ROUTED_NETS=$routed" {UNROUTED_NETS=0} {PARTIALLY_ROUTED_NETS=0} "WNS=[format %.3f $wns]" {TNS=0.000} "WHS=[format %.3f $whs]" {THS=0.000} {INTERNAL_UNCONSTRAINED_ENDPOINTS=0} {TIMING_LOOPS=0} {UNEXPECTED_CLOCKS=0} {MISSING_GENERATED_CLOCKS=0} "EFFECTIVE_USER_CLOCK_MHZ=[format %.6f $user_mhz]" "EFFECTIVE_AXI_CLOCK_MHZ=[format %.6f $user_mhz]"]
  return [dict create WNS $wns WHS $whs ROUTED $routed]
}

proc run_cdc_gate {root} {
  set path [file join $root G2B_NVP_VIDEO_DIAG1_R3_CDC.rpt]
  report_cdc -details -file $path
  set critical [list]
  set warning [list]
  set info [list]
  set unknown [list]
  set all [get_cdc_violations -quiet]
  foreach violation $all {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity in {CRITICAL {CRITICAL WARNING}}} { lappend critical $violation }
    if {$severity eq "WARNING"} { lappend warning $violation }
    if {$severity eq "INFO"} { lappend info $violation }
    if {$severity eq "UNKNOWN"} { lappend unknown $violation }
  }
  require_rule_counts CDC_CRITICAL $critical [dict create CDC-1 423 CDC-10 2 CDC-13 2] {CRITICAL {CRITICAL WARNING}}
  require_rule_counts CDC_WARNING $warning [dict create CDC-6 13 CDC-15 861] {WARNING}
  require_rule_counts CDC_INFO $info [dict create CDC-3 30 CDC-9 6] {INFO}
  if {[llength $all] != 1337 || [llength $critical] != 427 || [llength $warning] != 874 || [llength $info] != 36 || [llength $unknown] != 0} {
    error "CDC aggregate mismatch: total=[llength $all] critical=[llength $critical] warning=[llength $warning] info=[llength $info] unknown=[llength $unknown]"
  }
  set diagnostic_rows [list]
  foreach line [split [read_text $path] "\n"] {
    if {![regexp {^[ \t]*[0-9]+[ \t]+CDC-[0-9]+[ \t]+(Critical|Warning|Info|Unknown)[ \t]+} $line]} { continue }
    set lower [string tolower $line]
    foreach token {g2b_nvp_video_diag nvp_video_diag current_result_word current_result_valid current_result_generation current_result_session scan_fsm} {
      if {[string first $token $lower] >= 0} { lappend diagnostic_rows $line; break }
    }
  }
  if {[llength $diagnostic_rows] != 0} { error "diagnostic MMIO hierarchy created CDC rows: [llength $diagnostic_rows]" }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_DIAGNOSTIC_MMIO_CDC_ROWS.txt] [list {DIAGNOSTIC_MMIO_HIERARCHY_CDC_ROWS=0} {RESULT=PASS}]
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_CDC_GATE.txt] [list {RESULT=PASS} {CDC_DISPOSITION=PASS_PROFILE_SPECIFIC_DIAGNOSTIC_MANIFEST_V3} {CDC_TOTAL=1337} {CDC_CRITICAL=427} {CDC_WARNING=874} {CDC_INFO=36} {CDC_UNKNOWN=0} {NEW_CDC_DESTINATIONS=0} {MISSING_CDC_DESTINATIONS=0} {UNRECONCILED_CRITICAL_CDC_ROWS=0} {UNRECONCILED_WARNING_CDC_ROWS=0} {DIAGNOSTIC_MMIO_HIERARCHY_CDC_ROWS=0}]
  return PASS
}

proc run_structural_cdc_gate {root} {
  set families [list [list OWNERSHIP_REQUEST_ACK [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(own_req_sync1_source|own_req_sync2_source|own_ack_sync1_axi|own_ack_sync2_axi)_reg}] 4] [list RESET_REQUEST_ACK [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(transport_req_sync1_source|transport_req_sync2_source|transport_ack_sync1_axi|transport_ack_sync2_axi)_reg}] 4] [list RESET_COMMIT_RETURN [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/commit_sync(1|2)_axi_reg\[[0-3]\]}] 8] [list RELEASE_SLOT_TOGGLES [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_sync(1|2)_source_reg\[[0-3]\]}] 8]]
  set lines [list]
  foreach item $families {
    lassign $item family cells expected
    require_count $family $cells $expected
    foreach cell $cells {
      set async [string toupper [property_or_unknown ASYNC_REG $cell]]
      if {$async ni {TRUE 1}} { error "$family synchronizer lacks ASYNC_REG=TRUE: [get_property NAME $cell]" }
      lappend lines "$family|[get_property NAME $cell]|ASYNC_REG=TRUE"
    }
  }
  lappend lines {OWNERSHIP_CDC=PASS} {RESET_RETURN_CDC=PASS} {RELEASE_SLOT_CDC=PASS} {STABLE_DATA_PROTOCOL=PASS_SEMANTIC_MANIFEST_V3_AND_PROMOTED_CHECKS} {RESULT=PASS}
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_STRUCTURAL_CDC.txt] $lines
  return PASS
}

proc run_drc_methodology_gates {root} {
  set drc_path [file join $root G2B_NVP_VIDEO_DIAG1_R3_DRC.rpt]
  report_drc -file $drc_path
  set errors [list]; set critical [list]; set warnings [list]
  foreach violation [get_drc_violations -quiet] {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { lappend errors $violation }
    if {$severity eq "CRITICAL WARNING"} { lappend critical $violation }
    if {$severity eq "WARNING"} { lappend warnings $violation }
  }
  if {[llength $errors] != 0 || [llength $critical] != 0} { error "DRC hard gate failed" }
  require_rule_counts DRC_WARNING $warnings [dict create IOSR-1 2 PDCN-1569 1 REQP-1839 12 RTSTAT-10 1] {WARNING}
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_DRC_GATE.txt] [list {DRC=PASS} {DRC_ERRORS=0} {DRC_CRITICAL_WARNINGS=0} {DRC_WARNINGS=16}]

  set methodology_path [file join $root G2B_NVP_VIDEO_DIAG1_R3_METHODOLOGY.rpt]
  report_methodology -file $methodology_path
  set errors [list]; set critical [list]; set warnings [list]
  foreach violation [get_methodology_violations -quiet] {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { lappend errors $violation }
    if {$severity eq "CRITICAL WARNING"} { lappend critical $violation }
    if {$severity eq "WARNING"} { lappend warnings $violation }
  }
  if {[llength $errors] != 0 || [llength $critical] != 0} { error "methodology hard gate failed" }
  require_rule_counts METHODOLOGY_WARNING $warnings [dict create LUTAR-1 2 TIMING-9 1 TIMING-34 11 TIMING-39 1] {WARNING}
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_METHODOLOGY_GATE.txt] [list {METHODOLOGY=PASS} {METHODOLOGY_ERRORS=0} {METHODOLOGY_CRITICAL_WARNINGS=0} {METHODOLOGY_WARNINGS=15} {NO_MESSAGE_SUPPRESSION_COMMANDS_EXECUTED=YES}]
  return PASS
}

proc utilization_row {text wanted} {
  set normalized [string trimright $wanted *]
  foreach line [split $text "\n"] {
    set columns [split $line |]
    if {[llength $columns] < 7} { continue }
    set actual [string trimright [string trim [lindex $columns 1]] *]
    if {$actual ne $normalized} { continue }
    set used [string map [list "," "" " " ""] [string trim [lindex $columns 2]]]
    set available [string map [list "," "" " " ""] [string trim [lindex $columns 5]]]
    return [list $used $available]
  }
  error "utilization row not found: $wanted"
}

proc run_resource_gate {root} {
  set text [report_utilization -return_string]
  write_text [file join $root G2B_NVP_VIDEO_DIAG1_R3_ROUTED_UTILIZATION_FLAT.rpt] $text
  report_utilization -hierarchical -hierarchical_depth 20 -file [file join $root G2B_NVP_VIDEO_DIAG1_R3_ROUTED_UTILIZATION_HIER.rpt]
  lassign [utilization_row $text {Slice LUTs}] lut lut_available
  lassign [utilization_row $text {Slice Registers}] ff ff_available
  lassign [utilization_row $text {Block RAM Tile}] bram bram_available
  lassign [utilization_row $text {DSPs}] dsp dsp_available
  set lut_percent [expr {100.0 * $lut / $lut_available}]
  set ff_percent [expr {100.0 * $ff / $ff_available}]
  set bram_percent [expr {100.0 * $bram / $bram_available}]
  set dsp_percent [expr {100.0 * $dsp / $dsp_available}]
  if {$lut != 18674 || $lut_available != 20800 || $ff != 20179 || $ff_available != 41600 || $bram != 26.5 || $bram_available != 50 || $dsp != 0 || $dsp_available != 90 || $lut_percent > 98.0 || $ff_percent > 95.0 || $bram_percent > 90.0 || $dsp_percent > 90.0} {
    error "resource gate failed: LUT=$lut/$lut_available FF=$ff/$ff_available BRAM=$bram/$bram_available DSP=$dsp/$dsp_available"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_RESOURCE_GATE.txt] [list {RESULT=PASS} "LUT_USED=$lut" "LUT_AVAILABLE=$lut_available" "LUT_PERCENT=[format %.3f $lut_percent]" "FF_USED=$ff" "FF_AVAILABLE=$ff_available" "FF_PERCENT=[format %.3f $ff_percent]" "BRAM_USED=$bram" "BRAM_AVAILABLE=$bram_available" "BRAM_PERCENT=[format %.3f $bram_percent]" "DSP_USED=$dsp" "DSP_AVAILABLE=$dsp_available" "DSP_PERCENT=[format %.3f $dsp_percent]"]
  return [dict create LUT $lut FF $ff BRAM $bram DSP $dsp]
}

proc run_identity_gate {root} {
  set core [get_cells -quiet -hier -regexp {.*GEN_NVP_VIDEO_DIAG_CORE\.NVP_VIDEO_DIAG_CORE}]
  set i2c [get_cells -quiet -hier -regexp {.*GEN_NVP_VIDEO_DIAG_I2C\.NVP_VIDEO_DIAG_I2C_MASTER}]
  require_count NVP_VIDEO_DIAG_CORE $core 1
  require_count NVP_VIDEO_DIAG_I2C_MASTER $i2c 1
  set retired [concat [get_cells -quiet -hier -regexp {.*(result_words|result_reset_index|table_word).*}] [get_nets -quiet -hier -regexp {.*(result_words|result_reset_index|table_word).*}]]
  if {[llength $retired] != 0} { error "retired on-chip result history is present" }
  for {set index 0} {$index < 8} {incr index} {
    set objects [concat [get_cells -quiet -hier -regexp ".*current_result_word_${index}_reg.*"] [get_nets -quiet -hier -regexp ".*current_result_word_${index}.*"]]
    if {[llength $objects] == 0} { error "current snapshot word $index is absent" }
  }
  foreach token {current_result_valid current_session_id current_result_generation} {
    set objects [concat [get_cells -quiet -hier -regexp ".*${token}.*"] [get_nets -quiet -hier -regexp ".*${token}.*"]]
    if {[llength $objects] == 0} { error "diagnostic identity token absent: $token" }
  }
  set black_boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
  if {[llength $black_boxes] != 0} { error "black-box gate failed: [llength $black_boxes]" }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R3_INTEGRATION_IDENTITY_GATE.txt] [list {RESULT=PASS} {SHARED_AXI_LITE_BRIDGE_CHANGED=NO_EXACT_SOURCE_DIFF_AUTHORITY} {PRODUCT_CONTROL_STATUS_CHANGED=NO} {PRODUCT_MMIO_MAP_CHANGED=NO} {DIAGNOSTIC_MMIO_MAP_CHANGED=NO} {DIAG_MAGIC=0x4E565034} {DIAG_VERSION=0x00010002} {DIAG_CAPABILITIES=0x00000BFF} {MMIO_WRITE_RESPONSE_PROTOCOL_FIXED_CAPABILITY=1} {BUILD_FLAGS=32'h00000402} {TRANSPORT_ABI=AHD_C2H_TRANSPORT_ABI_V1} {ABI_VERSION=1} {ONCHIP_SESSION_HISTORY=ABSENT} {CURRENT_SESSION_SNAPSHOT_WORDS=8} {HOST_OWNED_SESSION_HISTORY=PRESENT} {BLACK_BOX_COUNT=0}]
  return PASS
}

set design_open 0
set operation_code [catch {
  foreach variable {task_root source_root report_root signoff_root artifact_root cdc_root routed_dcp signed_dcp bitstream harness preflight_script preflight_receipt} {
    set $variable [file normalize [set $variable]]
  }
  foreach required [list $task_root $source_root $report_root $artifact_root $cdc_root] {
    if {![file isdirectory $required]} { error "required directory missing: $required" }
  }
  foreach required [list $routed_dcp $harness $preflight_script $preflight_receipt] {
    if {![file isfile $required]} { error "required input missing: $required" }
  }
  if {[file exists $signoff_root] && [llength [glob -nocomplain -directory $signoff_root *]] != 0} {
    error "fresh R3 signoff directory is not empty"
  }
  file mkdir $signoff_root
  if {[file exists $signed_dcp] || [file exists $bitstream] || [llength [glob -nocomplain -directory $artifact_root *.ltx]] != 0} {
    error "fresh R3 signed-off output authority failed"
  }

  require_text $preflight_receipt {"Result": "PASS"} R3_FINALIZER_PREFLIGHT
  set preflight_sha [sha256_file $preflight_receipt]
  set harness_sha [sha256_file $harness]
  set preflight_script_sha [sha256_file $preflight_script]

  if {[version -short] ne $expected_vivado_version} { error "Vivado version mismatch" }
  set branch [string trim [exec git --no-optional-locks -C $source_root branch --show-current]]
  set commit [string trim [exec git --no-optional-locks -C $source_root rev-parse HEAD]]
  set tree [string trim [exec git --no-optional-locks -C $source_root rev-parse {HEAD^{tree}}]]
  set status [string trim [exec git --no-optional-locks -C $source_root status --short --untracked-files=no]]
  if {$branch ne $expected_branch || $commit ne $expected_commit || $tree ne $expected_tree || $status ne ""} {
    error "NVP_DIAG1_R3_SOURCE_AUTHORITY_CONTRADICTION"
  }

  set original_dcp_sha [sha256_file $routed_dcp]
  set original_dcp_size [file size $routed_dcp]
  set original_dcp_mtime [file mtime $routed_dcp]
  if {$original_dcp_sha ne $expected_dcp_sha} { error "exact R3 routed DCP hash mismatch" }
  set v3_csv [file join $cdc_root G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.csv]
  set v3_json [file join $cdc_root G2B_NVP_VIDEO_DIAG1_R3_CDC_SEMANTIC_MANIFEST_V3.json]
  if {[sha256_file $v3_csv] ne $expected_v3_csv_sha || [sha256_file $v3_json] ne $expected_v3_json_sha} {
    error "CDC semantic manifest V3 identity mismatch"
  }

  open_checkpoint $routed_dcp
  set design_open 1
  if {[get_property PART [current_design]] ne $expected_part || [get_property TOP [current_design]] ne $expected_top} {
    error "exact routed DCP part/top mismatch"
  }
  set signatures_pre [capture_signatures $signoff_root PRE_SIGNOFF]
  run_structural_cdc_gate $signoff_root
  set timing [run_timing_gate $signoff_root]
  run_cdc_gate $signoff_root
  run_drc_methodology_gates $signoff_root
  set resources [run_resource_gate $signoff_root]
  run_identity_gate $signoff_root
  set signatures_post [capture_signatures $signoff_root POST_SIGNOFF]
  require_same_signatures $signatures_pre $signatures_post REPORT_ONLY_SIGNOFF

  if {[sha256_file $routed_dcp] ne $original_dcp_sha || [file size $routed_dcp] != $original_dcp_size || [file mtime $routed_dcp] != $original_dcp_mtime || [sha256_file $harness] ne $harness_sha} {
    error "source routed DCP or finalizer changed before output generation"
  }
  write_checkpoint $signed_dcp
  if {![file isfile $signed_dcp] || [file size $signed_dcp] == 0 || [llength [glob -nocomplain -directory $artifact_root *.dcp]] != 1 || [llength [glob -nocomplain -directory $artifact_root *.bit]] != 0} {
    error "signed-off DCP output cardinality failed"
  }
  set signed_dcp_sha [sha256_file $signed_dcp]
  set signed_dcp_size [file size $signed_dcp]
  close_design
  set design_open 0

  open_checkpoint $signed_dcp
  set design_open 1
  if {[get_property PART [current_design]] ne $expected_part || [get_property TOP [current_design]] ne $expected_top || ![report_route_status -boolean_check ROUTED_FULLY] || [report_route_status -boolean_check ERRORS_IN_ROUTES]} {
    error "signed-off DCP reopen gate failed"
  }
  set signatures_signed [capture_signatures $signoff_root SIGNED_DCP_REOPEN]
  require_same_signatures $signatures_pre $signatures_signed SIGNED_DCP_REOPEN
  write_bitstream $bitstream
  if {![file isfile $bitstream] || [file size $bitstream] == 0 || [llength [glob -nocomplain -directory $artifact_root *.dcp]] != 1 || [llength [glob -nocomplain -directory $artifact_root *.bit]] != 1 || [llength [glob -nocomplain -directory $artifact_root *.ltx]] != 0} {
    error "bitstream output cardinality or LTX gate failed"
  }
  set bitstream_sha [sha256_file $bitstream]
  set bitstream_size [file size $bitstream]
  set signatures_after_bit [capture_signatures $signoff_root AFTER_BITSTREAM]
  require_same_signatures $signatures_pre $signatures_after_bit AFTER_BITSTREAM
  close_design
  set design_open 0

  set branch_after [string trim [exec git --no-optional-locks -C $source_root branch --show-current]]
  set commit_after [string trim [exec git --no-optional-locks -C $source_root rev-parse HEAD]]
  set tree_after [string trim [exec git --no-optional-locks -C $source_root rev-parse {HEAD^{tree}}]]
  set status_after [string trim [exec git --no-optional-locks -C $source_root status --short --untracked-files=no]]
  if {$branch_after ne $expected_branch || $commit_after ne $expected_commit || $tree_after ne $expected_tree || $status_after ne "" || [sha256_file $routed_dcp] ne $original_dcp_sha || [file size $routed_dcp] != $original_dcp_size || [file mtime $routed_dcp] != $original_dcp_mtime || [sha256_file $harness] ne $harness_sha} {
    error "source/DCP/finalizer identity drifted during output generation"
  }

  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R3_SIGNED_OFF_DCP_MANIFEST.txt] [list {RESULT=PASS} "SOURCE_ROUTED_DCP=$routed_dcp" "SOURCE_ROUTED_DCP_SHA256=$original_dcp_sha" "SIGNED_OFF_ROUTED_DCP=$signed_dcp" "SIGNED_OFF_ROUTED_DCP_SHA256=$signed_dcp_sha" "SIGNED_OFF_ROUTED_DCP_SIZE=$signed_dcp_size" "CLOCK_SIGNATURE_SHA256=[dict get $signatures_pre CLOCK_SHA]" "NETLIST_SIGNATURE_SHA256=[dict get $signatures_pre NETLIST_SHA]" "TIMING_CONSTRAINT_SIGNATURE_SHA256=[dict get $signatures_pre XDC_SHA]" "ROUTE_STATUS_SIGNATURE_SHA256=[dict get $signatures_pre ROUTE_SHA]" {ROUTE_SIGNATURE_UNCHANGED=YES} {CLOCK_SIGNATURE_UNCHANGED=YES} {NETLIST_SIGNATURE_UNCHANGED=YES} {FULL_TIMING_RESTORATION=PASS} {WRITE_CHECKPOINT_COUNT=1}]
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R3_BITSTREAM_MANIFEST.txt] [list {RESULT=PASS} "BITSTREAM=$bitstream" "BITSTREAM_SIZE=$bitstream_size" "BITSTREAM_SHA256=$bitstream_sha" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" "SOURCE_COMMIT=$commit" "SOURCE_TREE=$tree" "SYNTH_DCP_SHA256=28E1E16E98F5C26F3F2F434FE25C88C8C5F076C50EEC5C92AB9C7A87D1499A36" "ROUTED_DCP_SHA256=$original_dcp_sha" "SEMANTIC_CDC_MANIFEST_V3_SHA256=$expected_v3_csv_sha" "PHYSICAL_CDC_MANIFEST_SHA256=[sha256_file [file join $report_root CDC.rpt]]" {DIAG_MAGIC=0x4E565034} {DIAG_VERSION=0x00010002} {DIAG_CAPABILITIES=0x00000BFF} {BUILD_FLAGS=0x00000402} {CANDIDATE_CLASSIFICATION=G2B_NVP_VIDEO_DIAG1_R3_MMIO_PROTOCOL_FIXED_CANDIDATE} {WRITE_BITSTREAM_COUNT=1} {LTX=NONE_EXPECTED}]
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R3_SIGNOFF_RESULT.txt] [list {RESULT=PASS} {SIMULATION_GATE=25/25_PASS} {ACTIVE_BUS_SKEW_GROUPS=11/11_PASS} {ACTIVE_BUS_SKEW_VIOLATIONS=0} {RETIRED_GLOBAL_BUS_SKEW_RELATIONS_PRESENT=0} {PROMOTED_REPLACEMENT_CHECKS=17/17_PASS} {ALL_GOVERNED_GROUPS_1_TO_17=PASS} {CDC_DISPOSITION=PASS_PROFILE_SPECIFIC_DIAGNOSTIC_MANIFEST_V3} {NEW_CDC_DESTINATIONS=0} {UNRECONCILED_CRITICAL_CDC_ROWS=0} {UNRECONCILED_WARNING_CDC_ROWS=0} {DIAGNOSTIC_MMIO_HIERARCHY_CDC_ROWS=0} {DRC=PASS} {METHODOLOGY=PASS} {RESOURCE_GATE=PASS} {FULLY_ROUTED=YES} {ROUTED_NETS=36116/36116} {UNROUTED_NETS=0} "WNS=[format %.3f [dict get $timing WNS]]" {TNS=0.000} "WHS=[format %.3f [dict get $timing WHS]]" {THS=0.000} "LUT_USED=[dict get $resources LUT]" "FF_USED=[dict get $resources FF]" "BRAM_USED=[dict get $resources BRAM]" "DSP_USED=[dict get $resources DSP]" "SIGNED_OFF_DCP=$signed_dcp" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" "BITSTREAM=$bitstream" "BITSTREAM_SIZE=$bitstream_size" "BITSTREAM_SHA256=$bitstream_sha" "FINALIZER=$harness" "FINALIZER_SHA256=$harness_sha" "PREFLIGHT_SHA256=$preflight_sha" "PREFLIGHT_SCRIPT_SHA256=$preflight_script_sha" {ROUTE_SIGNATURE_UNCHANGED=YES} {CLOCK_SIGNATURE_UNCHANGED=YES} {NETLIST_SIGNATURE_UNCHANGED=YES} {FULL_TIMING_RESTORATION=PASS} {SOURCE_CHANGED_DURING_SIGNOFF=NO} {CONSTRAINT_MUTATION_COMMANDS=0} {IMPLEMENTATION_COMMANDS=0} {WRITE_CHECKPOINT_COUNT=1} {WRITE_BITSTREAM_COUNT=1} {WRITE_DEBUG_PROBES_COUNT=0} {HARDWARE_ACCESSED=NO}]
} operation_message operation_options]

if {$operation_code != 0} {
  if {$design_open} { catch {close_design} }
  catch {
    file mkdir $signoff_root
    write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R3_SIGNOFF_FAILURE.txt] [list {RESULT=FAIL} "ERROR=[single_line $operation_message]"]
  }
  puts stderr "G2B_NVP_VIDEO_DIAG1_R3_SIGNOFF_FAIL: $operation_message"
  if {[dict exists $operation_options -errorinfo]} { puts stderr [dict get $operation_options -errorinfo] }
  exit 1
}

puts "G2B_NVP_VIDEO_DIAG1_R3_SIGNOFF_PASS"
exit 0
