# AHD v41 G2B NVP DIAG2-RM1 routed-handoff finalizer.
#
# This process does not synthesize, optimize, place, or route.  It reopens the
# exact build-stage DCP, independently rechecks the terminal gates and profile,
# then writes exactly one signed-off DCP and one bitstream into a fresh root.

if {$argc != 7} {
  puts stderr "usage: g2b_nvp_diag2_rm1_finalize.tcl REPO_ROOT BUILD_EVIDENCE_ROOT ARTIFACT_ROOT SOURCE_COMMIT SOURCE_TREE BUILD_HARNESS ROUTED_HANDOFF_SHA256"
  exit 2
}
lassign $argv repo_root evidence_root artifact_root source_commit source_tree \
  build_harness expected_handoff_sha
set repo_root [file normalize $repo_root]
set evidence_root [file normalize $evidence_root]
set artifact_root [file normalize $artifact_root]
set build_harness [file normalize $build_harness]

set expected_parent fc37d815b5d64ef90dfbd99c57ae4cc09567b56f
set expected_branch diag/v41-g2b-nvp-video-diag2-rm1
set expected_part xc7a35tcsg325-2
set expected_donor_sha 74CA15C2FCEADBC59876249E8EEB08D71D7FD787A0F7B422DC69BE737FB57D59
set expected_lut_available 20800
set lut_hard_max 20384
set lut_preferred_max 19760
set authorized_changes [dict create \
  rtl/g2b/v41_g2b_onech_c2h.sv M \
  rtl/top/ahd_capture_top_xdma.sv M \
  rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv A \
  rtl/diagnostic/g2b_nvp_rm1_route_controller.sv A \
  rtl/g2b/g2b_nvp_video_diag2_rm1.sv A \
  xdc/common/g2b_nvp_diag2_rm1_cdc.xdc A \
  tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1 A \
  tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv A \
  tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv A \
  tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv A \
  tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1 A]

proc read_text {path} {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set value [read $fh]
  close $fh
  return $value
}
proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}
proc sha256_file {path} {
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set value [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $value]} { return $value }
  }
  error "SHA-256 unavailable for $path"
}
proc git_value {args} {
  global repo_root
  return [string trim [exec git --no-optional-locks -C $repo_root {*}$args]]
}
proc changed_set_current {} {
  global source_commit expected_parent authorized_changes
  set parent_words [regexp -all -inline {\S+} \
    [git_value rev-list --parents -n 1 $source_commit]]
  if {[llength $parent_words] != 2 ||
      [string tolower [lindex $parent_words 0]] ne $source_commit ||
      [string tolower [lindex $parent_words 1]] ne $expected_parent} {
    error "RM1 direct parent mismatch"
  }
  set output [git_value diff-tree --no-commit-id --name-status -r \
    --find-renames --find-copies --find-copies-harder \
    $expected_parent $source_commit]
  set seen [dict create]
  set rows [list]
  foreach raw_line [split $output "\n"] {
    set line [string trimright $raw_line "\r"]
    if {$line eq ""} { continue }
    set columns [split $line "\t"]
    if {[llength $columns] != 2} { error "RM1 rename/copy or malformed diff: $line" }
    lassign $columns status rel
    if {[file pathtype $rel] ne "relative" || [string first "\\" $rel] >= 0 ||
        [regexp {(^|/)\.\.(/|$)} $rel] || [dict exists $seen $rel]} {
      error "RM1 noncanonical or duplicate changed path: $rel"
    }
    if {![dict exists $authorized_changes $rel] ||
        [dict get $authorized_changes $rel] ne $status} {
      error "RM1 unauthorized changed path: $status:$rel"
    }
    dict set seen $rel 1
    lappend rows "$status|$rel"
  }
  if {[dict size $seen] != 11 || [dict size $authorized_changes] != 11} {
    error "RM1 authorized changed set count mismatch: [dict size $seen]/11"
  }
  dict for {rel status} $authorized_changes {
    if {![dict exists $seen $rel]} { error "RM1 authorized changed path missing: $status:$rel" }
  }
  return [lsort -ascii $rows]
}
proc read_key_values {path} {
  set values [dict create]
  foreach line [split [read_text $path] "\n"] {
    set line [string trimright $line "\r"]
    if {$line eq ""} { continue }
    set split [string first = $line]
    if {$split <= 0} { error "non-key/value receipt line: $line" }
    set key [string range $line 0 [expr {$split - 1}]]
    set value [string range $line [expr {$split + 1}] end]
    if {[dict exists $values $key]} { error "duplicate receipt key: $key" }
    dict set values $key $value
  }
  return $values
}
proc require_value {values key expected} {
  if {![dict exists $values $key]} { error "missing handoff value: $key" }
  set actual [dict get $values $key]
  if {$actual ne $expected} { error "handoff mismatch $key: expected=$expected actual=$actual" }
}
proc property_or_unknown {property object} {
  if {[catch {get_property $property $object} value] || $value eq ""} { return UNKNOWN }
  return $value
}
proc utilization_row {text wanted} {
  set wanted [string trimright $wanted *]
  foreach line [split $text "\n"] {
    set columns [split $line |]
    if {[llength $columns] < 7} { continue }
    if {[string trimright [string trim [lindex $columns 1]] *] ne $wanted} { continue }
    set used [string map [list , "" " " ""] [string trim [lindex $columns 2]]]
    set available [string map [list , "" " " ""] [string trim [lindex $columns 5]]]
    if {![string is double -strict $used] || ![string is double -strict $available]} {
      error "invalid utilization row: $wanted"
    }
    return [list $used $available]
  }
  error "utilization row absent: $wanted"
}
proc routed_slack {delay_type} {
  set paths [get_timing_paths -quiet -delay_type $delay_type -max_paths 1 -nworst 1]
  if {[llength $paths] != 1} { error "missing $delay_type timing path" }
  set value [get_property SLACK [lindex $paths 0]]
  if {![string is double -strict $value]} { error "nonnumeric $delay_type slack" }
  return $value
}
proc final_expected_check_timing_counts {} {
  return [dict create \
    no_clock 0 constant_clock 0 pulse_width_clock 2 \
    unconstrained_internal_endpoints 0 no_input_delay 0 no_output_delay 0 \
    multiple_clock 0 generated_clocks 0 loops 0 partial_input_delay 0 \
    partial_output_delay 0 latch_loops 0]
}
proc final_parse_check_timing_counts {text label} {
  set expected [final_expected_check_timing_counts]
  set observed [dict create]
  foreach raw_line [split $text "\n"] {
    set line [string trimright $raw_line "\r"]
    if {[regexp {^[ \t]*[0-9]+\.[ \t]+checking[ \t]+([a-z_]+)[ \t]+\(([0-9]+)\)[ \t]*$} \
        $line -> category count]} {
      dict lappend observed $category $count
    }
  }
  if {[dict size $observed] != [dict size $expected]} {
    error "$label check_timing category set mismatch"
  }
  dict for {category values} $observed {
    if {![dict exists $expected $category] || [llength $values] != 2 ||
        [lindex $values 0] ne [lindex $values 1] ||
        ![string is integer -strict [lindex $values 0]]} {
      error "$label unexpected or inconsistent check_timing category: $category=$values"
    }
  }
  set result [dict create]
  dict for {category wanted} $expected {
    if {![dict exists $observed $category]} { error "$label missing check_timing category: $category" }
    set actual [lindex [dict get $observed $category] 0]
    if {$actual != $wanted} {
      error "$label check_timing count mismatch: $category expected=$wanted actual=$actual"
    }
    dict set result $category $actual
  }
  return $result
}
proc final_unconstrained_path_table {text label} {
  set lines [split $text "\n"]
  set markers [list]
  for {set index 0} {$index < [llength $lines]} {incr index} {
    if {[string trim [string trimright [lindex $lines $index] "\r"]] eq
        {| Unconstrained Path Table}} {
      lappend markers $index
    }
  }
  if {[llength $markers] != 1} { error "$label unconstrained table section count != 1" }
  set header_index -1
  set from_index -1
  set to_index -1
  for {set index [expr {[lindex $markers 0] + 1}]} {$index < [llength $lines]} {incr index} {
    set line [string trimright [lindex $lines $index] "\r"]
    if {[regexp {^[ \t]*Path Group[ \t]+From Clock[ \t]+To Clock[ \t]*$} $line]} {
      set header_index $index
      set from_index [string first {From Clock} $line]
      set to_index [string first {To Clock} $line]
      break
    }
    if {$index > [lindex $markers 0] + 20} { break }
  }
  if {$header_index < 0 || $from_index <= 0 || $to_index <= $from_index} {
    error "$label unconstrained table header missing or malformed"
  }
  set rows [list]
  for {set index [expr {$header_index + 1}]} {$index < [llength $lines]} {incr index} {
    set line [string trimright [lindex $lines $index] "\r"]
    set trimmed [string trim $line]
    if {$trimmed eq ""} { continue }
    set compact [string map [list " " "" "\t" ""] $trimmed]
    if {[regexp {^-+$} $compact]} {
      if {[string length $compact] >= 40 && [llength $rows] > 0} { break }
      continue
    }
    if {[string index $trimmed 0] eq {|}} { break }
    set group [string trim [string range $line 0 [expr {$from_index - 1}]]]
    set from [string trim [string range $line $from_index [expr {$to_index - 1}]]]
    set to [string trim [string range $line $to_index end]]
    if {$group ne {(none)}} { error "$label unexpected unconstrained path group row: $line" }
    lappend rows "$group|$from|$to"
  }
  set rows [lsort -ascii $rows]
  if {[llength $rows] != 0} {
    error "$label raw unconstrained path table is not empty: $rows"
  }
  return $rows
}
proc final_unconstrained_gate {} {
  global artifact_root
  set timing_path [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_TIMING_SUMMARY.rpt]
  set check_path [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_CHECK_TIMING.rpt]
  report_timing_summary -delay_type min_max -check_timing_verbose \
    -report_unconstrained -max_paths 100 -nworst 1 -file $timing_path
  check_timing -verbose -file $check_path
  set timing_text [read_text $timing_path]
  set check_text [read_text $check_path]
  set timing_counts [final_parse_check_timing_counts $timing_text {FINAL timing-summary}]
  set check_counts [final_parse_check_timing_counts $check_text {FINAL standalone}]
  if {$timing_counts ne $check_counts} { error "final embedded/standalone check_timing mismatch" }
  set table_rows [final_unconstrained_path_table $timing_text FINAL]
  set rows [list {LABEL=FINAL} {REPORT_UNCONSTRAINED_OPTION=REQUIRED_AND_PRESENT}]
  dict for {category count} $timing_counts { lappend rows "CHECK_TIMING_$category=$count" }
  lappend rows \
    "RAW_NO_INPUT_DELAY=[dict get $timing_counts no_input_delay]" \
    "RAW_NO_OUTPUT_DELAY=[dict get $timing_counts no_output_delay]" \
    "RAW_UNCONSTRAINED_PATH_TABLE_ROWS=[llength $table_rows]" \
    {RAW_UNCONSTRAINED_ENDPOINTS=0} {UNCONSTRAINED_ENDPOINTS=0} \
    {UNCONSTRAINED_GATE=PASS}
  write_lines [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_UNCONSTRAINED_GATE.txt] $rows
  return [dict create RAW_TABLE_ROWS [llength $table_rows] RAW_ENDPOINTS 0]
}
proc final_violation_blob {violation} {
  set parts [list]
  foreach property [list_property $violation] {
    if {[catch {get_property $property $violation} value]} { continue }
    lappend parts "$property=$value"
  }
  return [string toupper [join $parts {|}]]
}
proc final_protocol_endpoint_leaf {value} {
  set normalized [string toupper [string trim $value " {}\t\r\n"]]
  if {[regexp {(^|/)RM1_RAW_MARKER_MONITOR/([^/]+/[A-Z0-9_]+)$} \
      $normalized -> prefix leaf]} {
    return $leaf
  }
  return UNKNOWN
}
proc final_expected_cdc_protocol {} {
  set expected [dict create]
  foreach pair {
    {CLEAR_TOGGLE_AXI_REG/C CLEAR_SYNC1_SOURCE_REG/D}
    {ARM_TOGGLE_AXI_REG/C ARM_SYNC1_SOURCE_REG/D}
    {FREEZE_TOGGLE_AXI_REG/C FREEZE_SYNC1_SOURCE_REG/D}
    {FREEZE_MANUAL_TOGGLE_AXI_REG/C FREEZE_MANUAL_SYNC1_SOURCE_REG/D}
    {ACK_TOGGLE_AXI_REG/C ACK_SYNC1_SOURCE_REG/D}
    {ABORT_EPOCH_TOGGLE_AXI_REG/C ABORT_EPOCH_SYNC1_SOURCE_REG/D}
    {ARMED_SOURCE_REG/C ARMED_SYNC1_AXI_REG/D}
    {DONE_TOGGLE_SOURCE_REG/C DONE_SYNC1_AXI_REG/D}
    {SNAPSHOT_VALID_SOURCE_REG/C VALID_SYNC1_AXI_REG/D}
    {TRACE_OVERFLOW_SOURCE_REG/C OVERFLOW_SYNC1_AXI_REG/D}
    {ACK_DONE_TOGGLE_SOURCE_REG/C ACK_DONE_SYNC1_AXI_REG/D}
    {ABORT_ACK_TOGGLE_SOURCE_REG/C ABORT_ACK_SYNC1_AXI_REG/D}
  } {
    lassign $pair source destination
    dict set expected "CDC-3|INFO|FALSE PATH|$source|$destination" 1
  }
  for {set bit 0} {$bit < 16} {incr bit} {
    dict set expected "CDC-15|WARNING|FALSE PATH|ARM_SESSION_HOLD_AXI_REG\[$bit\]/C|SESSION_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 3} {incr bit} {
    dict set expected "CDC-15|WARNING|FALSE PATH|ARM_ROUTE_HOLD_AXI_REG\[$bit\]/C|ROUTE_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 2} {incr bit} {
    dict set expected "CDC-15|WARNING|FALSE PATH|ARM_WINDOW_HOLD_AXI_REG\[$bit\]/C|WINDOW_SOURCE_REG\[$bit\]/D" 1
  }
  if {[dict size $expected] != 33} { error "internal final RM1 CDC allowlist size mismatch" }
  return $expected
}
proc final_expected_xdc_destinations {} {
  set expected [dict create]
  foreach destination {
    CLEAR_SYNC1_SOURCE_REG/D ARM_SYNC1_SOURCE_REG/D
    FREEZE_SYNC1_SOURCE_REG/D FREEZE_MANUAL_SYNC1_SOURCE_REG/D
    ACK_SYNC1_SOURCE_REG/D ABORT_EPOCH_SYNC1_SOURCE_REG/D
    ARMED_SYNC1_AXI_REG/D DONE_SYNC1_AXI_REG/D VALID_SYNC1_AXI_REG/D
    OVERFLOW_SYNC1_AXI_REG/D ACK_DONE_SYNC1_AXI_REG/D
    ABORT_ACK_SYNC1_AXI_REG/D
  } {
    dict set expected $destination 1
  }
  for {set bit 0} {$bit < 16} {incr bit} {
    dict set expected "SESSION_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 3} {incr bit} {
    dict set expected "ROUTE_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 2} {incr bit} {
    dict set expected "WINDOW_SOURCE_REG\[$bit\]/D" 1
  }
  if {[dict size $expected] != 33} {
    error "internal final RM1 XDC destination set size mismatch"
  }
  return $expected
}
proc final_xdc_destination_pin_gate {} {
  set expected_destinations [final_expected_xdc_destinations]
  set sync1_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/(clear_sync1_source|arm_sync1_source|freeze_sync1_source|freeze_manual_sync1_source|ack_sync1_source|abort_epoch_sync1_source|armed_sync1_axi|done_sync1_axi|valid_sync1_axi|overflow_sync1_axi|ack_done_sync1_axi|abort_ack_sync1_axi)_reg}]
  set sync1_d [get_pins -quiet -of_objects $sync1_cells -filter {REF_PIN_NAME == D}]
  set session_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/session_source_reg\[[0-9]+\]}]
  set route_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/route_source_reg\[[0-9]+\]}]
  set window_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/window_source_reg\[[0-9]+\]}]
  set mailbox_cells [concat $session_cells $route_cells $window_cells]
  set mailbox_d [get_pins -quiet -of_objects $mailbox_cells -filter {REF_PIN_NAME == D}]
  if {[llength $sync1_cells] != 12 || [llength $sync1_d] != 12 ||
      [llength $session_cells] != 16 || [llength $route_cells] != 3 ||
      [llength $window_cells] != 2 || [llength $mailbox_cells] != 21 ||
      [llength $mailbox_d] != 21} {
    error "final RM1 CDC resolved cell/D-pin collections are not exact 12+21"
  }
  set observed [dict create]
  set observed_cells [dict create]
  set sync_pin_count 0
  set mailbox_pin_count 0
  set rows [list]
  foreach pin [concat $sync1_d $mailbox_d] {
    set pin_name [get_property NAME $pin]
    set destination [final_protocol_endpoint_leaf $pin_name]
    if {$destination ne "UNKNOWN" && [dict exists $expected_destinations $destination]} {
      if {[dict exists $observed $destination]} {
        error "duplicate final RM1 CDC destination pin: $pin_name"
      }
      dict set observed $destination 1
      set parent_cells [get_cells -quiet -of_objects $pin]
      if {[llength $parent_cells] != 1} {
        error "final RM1 CDC destination parent-cell count != 1: $pin_name"
      }
      set cell_name [get_property NAME [lindex $parent_cells 0]]
      if {[dict exists $observed_cells $cell_name]} {
        error "duplicate final RM1 CDC destination cell: $cell_name"
      }
      dict set observed_cells $cell_name 1
      if {[regexp {^(SESSION_SOURCE_REG\[[0-9]+\]|ROUTE_SOURCE_REG\[[0-9]+\]|WINDOW_SOURCE_REG\[[0-9]+\])/D$} $destination]} {
        incr mailbox_pin_count
      } else {
        incr sync_pin_count
      }
      lappend rows "RM1_DESTINATION=$destination|PIN=$pin_name"
    }
  }
  if {[dict size $expected_destinations] != 33 || [dict size $observed] != 33 ||
      [dict size $observed_cells] != 33 || $sync_pin_count != 12 ||
      $mailbox_pin_count != 21} {
    error "final RM1 CDC resolved cell/D-pin set mismatch: pins=[dict size $observed]/33 cells=[dict size $observed_cells]/33 sync=$sync_pin_count/12 mailbox=$mailbox_pin_count/21"
  }
  dict for {destination count} $expected_destinations {
    if {![dict exists $observed $destination]} {
      error "missing final RM1 CDC destination pin: $destination"
    }
  }
  lappend rows {RM1_SYNC1_CELLS=12/12} {RM1_SYNC1_D_PINS=12/12} \
    {RM1_MAILBOX_CELLS=21/21} {RM1_MAILBOX_D_PINS=21/21}
  return [lsort -ascii $rows]
}
proc final_cdc_gate {} {
  global artifact_root
  set report_path [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_CDC.rpt]
  report_cdc -details -file $report_path
  set expected_protocol [final_expected_cdc_protocol]
  set destination_rows [final_xdc_destination_pin_gate]
  set observed_protocol [dict create]
  set legacy_counts [dict create]
  set rm1_total 0
  set rm1_info 0
  set rm1_warning 0
  set rm1_unmatched 0
  set unresolved_critical 0
  set unresolved_warning 0
  set unknown 0
  set rows [list]
  foreach destination_row $destination_rows { lappend rows $destination_row }
  foreach violation [get_cdc_violations -quiet] {
    set name [get_property NAME $violation]
    set rule [lindex [split $name #] 0]
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    set exception [string toupper [property_or_unknown EXCEPTION $violation]]
    set source_raw [property_or_unknown STARTPOINT_PIN $violation]
    set destination_raw [property_or_unknown ENDPOINT_PIN $violation]
    set source [final_protocol_endpoint_leaf $source_raw]
    set destination [final_protocol_endpoint_leaf $destination_raw]
    set blob [final_violation_blob $violation]
    if {$severity eq "UNKNOWN"} { incr unknown }
    if {$source ne "UNKNOWN" || $destination ne "UNKNOWN" ||
        [string first RM1_RAW_MARKER_MONITOR $blob] >= 0} {
      incr rm1_total
      if {$severity eq "INFO"} { incr rm1_info }
      if {$severity eq "WARNING"} { incr rm1_warning }
      set key "$rule|$severity|$exception|$source|$destination"
      set disposed [dict exists $expected_protocol $key]
      if {$disposed} {
        dict incr observed_protocol $key
      } else {
        incr rm1_unmatched
        if {$severity in {CRITICAL {CRITICAL WARNING} ERROR}} { incr unresolved_critical }
        if {$severity eq "WARNING"} { incr unresolved_warning }
      }
      lappend rows "RM1|$name|RULE=$rule|SEVERITY=$severity|EXCEPTION=$exception|STARTPOINT_PIN=$source_raw|ENDPOINT_PIN=$destination_raw|SOURCE=$source|DESTINATION=$destination|DISPOSITION=[expr {$disposed ? {EXACT_PROTOCOL_CANDIDATE} : {UNRESOLVED}}]"
    } else {
      dict incr legacy_counts "$severity|$rule"
    }
  }
  set inherited_expected [dict create \
    "CRITICAL|CDC-1" 423 "CRITICAL|CDC-10" 2 "CRITICAL|CDC-13" 2 \
    "WARNING|CDC-6" 13 "WARNING|CDC-15" 861]
  set inherited_ok 1
  dict for {key value} $legacy_counts {
    if {$key ni [dict keys $inherited_expected] &&
        ([string match {CRITICAL*|*} $key] || [string match {WARNING|*} $key])} {
      set inherited_ok 0
    }
  }
  dict for {key expected_count} $inherited_expected {
    set actual [expr {[dict exists $legacy_counts $key] ? [dict get $legacy_counts $key] : 0}]
    if {$actual != $expected_count} { set inherited_ok 0 }
    lappend rows "INHERITED_EXPECTED=$key|EXPECTED=$expected_count|ACTUAL=$actual"
  }
  set protocol_mismatches 0
  set false_path_destination_pins 0
  dict for {key expected_count} $expected_protocol {
    set actual [expr {[dict exists $observed_protocol $key] ? [dict get $observed_protocol $key] : 0}]
    if {$actual != $expected_count} { incr protocol_mismatches }
    if {$actual == 1 && [lindex [split $key |] 2] eq "FALSE PATH"} {
      incr false_path_destination_pins
    }
    lappend rows "RM1_EXPECTED=$key|EXPECTED=$expected_count|ACTUAL=$actual|DISPOSITION=[expr {$actual == $expected_count ? {EXACT_PROTOCOL} : {UNRESOLVED}}]"
  }
  set sync1_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/(clear_sync1_source|arm_sync1_source|freeze_sync1_source|freeze_manual_sync1_source|ack_sync1_source|abort_epoch_sync1_source|armed_sync1_axi|done_sync1_axi|valid_sync1_axi|overflow_sync1_axi|ack_done_sync1_axi|abort_ack_sync1_axi)_reg}]
  set async_ok [expr {[llength $sync1_cells] == 12}]
  foreach cell $sync1_cells {
    if {[string toupper [property_or_unknown ASYNC_REG $cell]] ni {TRUE 1}} { set async_ok 0 }
  }
  set unresolved [expr {$rm1_unmatched + $protocol_mismatches}]
  set result [expr {$unknown == 0 && $rm1_total == 33 && $rm1_info == 12 &&
                    $rm1_warning == 21 && $unresolved == 0 &&
                    $false_path_destination_pins == 33 &&
                    $unresolved_critical == 0 && $unresolved_warning == 0 &&
                    $inherited_ok && $async_ok ? {PASS} : {FAIL}}]
  lappend rows "RM1_CDC_FINDINGS=$rm1_total/33" "RM1_CDC3_INFO_ACTUAL=$rm1_info" \
    "RM1_CDC15_WARNING_ACTUAL=$rm1_warning" "RM1_UNRESOLVED_CDC=$unresolved" \
    "RM1_FALSE_PATH_DESTINATION_PINS=$false_path_destination_pins/33" \
    {RM1_DESTINATION_PINS=33/33} \
    "RM1_ASYNC_REG_FIRST_STAGES=[llength $sync1_cells]/12" \
    "NEW_UNRESOLVED_CRITICAL_CDC=$unresolved_critical" \
    "NEW_UNRESOLVED_WARNING_CDC=$unresolved_warning" \
    "UNKNOWN_CDC=$unknown" "INHERITED_R3_RULE_POPULATION=[expr {$inherited_ok ? {PASS} : {FAIL}}]" \
    "FINAL_CDC_GATE=$result"
  write_lines [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_CDC_GATE.txt] $rows
  if {$result ne "PASS"} { error "final RM1 CDC gate failed" }
  return $rm1_total
}
proc final_drc_methodology_gate {} {
  global artifact_root
  set outputs [list]
  foreach label {DRC METHODOLOGY} {
    set report_path [file join $artifact_root "G2B_NVP_DIAG2_RM1_FINAL_${label}.rpt"]
    if {$label eq "DRC"} {
      report_drc -file $report_path
      set violations [get_drc_violations -quiet]
    } else {
      report_methodology -file $report_path
      set violations [get_methodology_violations -quiet]
    }
    set errors 0
    set critical 0
    set warnings 0
    set advisory 0
    set informational 0
    set unknown_or_unrecognized 0
    foreach violation $violations {
      set severity [string toupper [property_or_unknown SEVERITY $violation]]
      switch -- $severity {
        ERROR { incr errors }
        "CRITICAL WARNING" - CRITICAL { incr critical }
        WARNING { incr warnings }
        ADVISORY { incr advisory }
        INFO - INFORMATION { incr informational }
        default { incr unknown_or_unrecognized }
      }
    }
    set result [expr {$errors == 0 && $critical == 0 &&
                      $unknown_or_unrecognized == 0 ? {PASS} : {FAIL}}]
    write_lines [file join $artifact_root \
        "G2B_NVP_DIAG2_RM1_FINAL_${label}_GATE.txt"] [list \
      "${label}_ERRORS=$errors" "${label}_CRITICAL_WARNINGS=$critical" \
      "${label}_WARNINGS=$warnings" "${label}_ADVISORIES=$advisory" \
      "${label}_INFORMATIONAL=$informational" \
      "${label}_UNKNOWN_OR_UNRECOGNIZED_SEVERITY=$unknown_or_unrecognized" \
      "${label}_GATE=$result"]
    if {$result ne "PASS"} { error "final $label hard gate failed" }
    lappend outputs $warnings
  }
  return $outputs
}
proc profile_cells {instance_pattern ref_pattern} {
  set matches [dict create]
  foreach cell [get_cells -quiet -hier] {
    set name [get_property NAME $cell]
    set ref [property_or_unknown REF_NAME $cell]
    if {[regexp -- $instance_pattern $name] || [regexp -- $ref_pattern $ref]} {
      dict set matches $name $cell
    }
  }
  return [dict values $matches]
}
proc final_profile_gate {} {
  global artifact_root
  set wrapper [profile_cells {(^|[/.])NVP_DIAG2_RM1_CORE($|[/.])} {^g2b_nvp_video_diag2_rm1($|_)}]
  set route [profile_cells {(^|[/.])RM1_ROUTE_CONTROLLER($|[/.])} {^g2b_nvp_rm1_route_controller($|_)}]
  set monitor [profile_cells {(^|[/.])RM1_RAW_MARKER_MONITOR($|[/.])} {^g2b_nvp_raw_marker_monitor($|_)}]
  set fixed_i2c [profile_cells {(^|[/.])NVP_VIDEO_DIAG_I2C_MASTER($|[/.])} {^nvp_i2c_fixed_master($|_)}]
  set route_state [get_cells -quiet -hier -regexp {.*RM1_ROUTE_CONTROLLER/.*state.*_reg.*}]
  set monitor_state [get_cells -quiet -hier -regexp {.*RM1_RAW_MARKER_MONITOR/.*state.*_reg.*}]
  set bram [get_cells -quiet -hier -regexp {.*RM1_SNAPSHOT_RAM.*} -filter {REF_NAME =~ RAMB*}]
  set r3 [profile_cells {(^|[/.])NVP_VIDEO_DIAG_CORE($|[/.])} {^g2b_nvp_video_diag($|_)}]
  set tri [profile_cells {POST_INIT_TRI_PHASE_PROBE} {^nvp_i2c_tri_phase_probe($|_)}]
  set history [profile_cells {R1F_FAILED_TXN_LOGGER|R1H_MMIO_READ_SERVICE|LIFECYCLE_MONITOR} {^(v41_r1f_failed_txn_logger|v41_r1h_mmio_read_service|v41_axi_clock_lifecycle_monitor)($|_)}]
  set forbidden [profile_cells {SCAN1|ACQ1|MODE1|BGDCOL.*(HISTORY|SESSION)} {^(g2b_nvp_camera_scan|g2b_nvp_camera_acq|g2b_nvp_camera_mode1)($|_)}]
  set required_ok [expr {([llength $wrapper] > 0 || ([llength $route_state] > 0 && [llength $monitor_state] > 0)) &&
                         ([llength $route] > 0 || [llength $route_state] > 0) &&
                         ([llength $monitor] > 0 || [llength $monitor_state] > 0) &&
                         [llength $fixed_i2c] > 0 && [llength $bram] == 1}]
  set absent_ok [expr {[llength $r3] == 0 && [llength $tri] == 0 && [llength $history] == 0 && [llength $forbidden] == 0}]
  set result [expr {$required_ok && $absent_ok ? {PASS} : {FAIL}}]
  write_lines [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_PROFILE_GATE.txt] [list \
    "RM1_WRAPPER_BOUNDARY_COUNT=[llength $wrapper]" \
    "RM1_ROUTE_BOUNDARY_COUNT=[llength $route]" \
    "RM1_MONITOR_BOUNDARY_COUNT=[llength $monitor]" \
    "RM1_ROUTE_STATE_COUNT=[llength $route_state]" \
    "RM1_MONITOR_STATE_COUNT=[llength $monitor_state]" \
    "RM1_SNAPSHOT_BRAM_PRIMITIVE_COUNT=[llength $bram]" \
    "FIXED_I2C_MASTER_COUNT=[llength $fixed_i2c]" \
    "R3_CORE_COUNT=[llength $r3]" "RTRACK_TRI_PROBE_COUNT=[llength $tri]" \
    "RTRACK_HISTORY_COUNT=[llength $history]" \
    "SCAN1_ACQ1_MODE1_BGDCOL_HISTORY_COUNT=[llength $forbidden]" \
    "FINAL_PROFILE_GATE=$result"]
  if {$result ne "PASS"} { error "final RM1 profile gate failed" }
}
proc source_seal_current {} {
  global source_commit source_tree expected_branch sealed_changed_set
  if {[catch {
    set ok [expr {[git_value rev-parse HEAD] eq $source_commit &&
                  [git_value rev-parse {HEAD^{tree}}] eq $source_tree &&
                  [git_value symbolic-ref --short HEAD] eq $expected_branch &&
                  [git_value status --porcelain=v1 --untracked-files=all] eq "" &&
                  [changed_set_current] eq $sealed_changed_set}]
  }]} { return 0 }
  return $ok
}
proc final_harness_seal_current {} {
  global sealed_harness_hashes
  if {![info exists sealed_harness_hashes] || [dict size $sealed_harness_hashes] != 9} {
    return 0
  }
  dict for {path expected_sha} $sealed_harness_hashes {
    if {![file isfile $path] || [sha256_file $path] ne $expected_sha} {
      return 0
    }
  }
  return 1
}
proc final_authority_seal_current {} {
  global sealed_authority_hashes
  if {![info exists sealed_authority_hashes] || [dict size $sealed_authority_hashes] != 6} {
    return 0
  }
  dict for {path expected_sha} $sealed_authority_hashes {
    if {![file isfile $path] || [sha256_file $path] ne $expected_sha} {
      return 0
    }
  }
  return 1
}

if {![file isdirectory $repo_root] || ![file isdirectory $evidence_root]} {
  error "repository or build evidence root missing"
}
if {[file exists $artifact_root]} { error "fresh ARTIFACT_ROOT required" }
file mkdir $artifact_root
if {![file isfile $build_harness]} { error "build harness missing" }
if {![regexp {^[0-9a-f]{40}$} $source_commit] || ![regexp {^[0-9a-f]{40}$} $source_tree]} {
  error "source identity format invalid"
}
if {![regexp {^[0-9A-F]{64}$} $expected_handoff_sha]} {
  error "routed handoff SHA authority format invalid"
}
set sealed_changed_set [changed_set_current]
if {![source_seal_current]} { error "source identity/branch/cleanliness mismatch" }

set handoff_path [file join $evidence_root G2B_NVP_DIAG2_RM1_ROUTED_BUILD_HANDOFF.txt]
if {![file isfile $handoff_path] || [sha256_file $handoff_path] ne $expected_handoff_sha} {
  error "launcher-pinned routed handoff receipt mismatch"
}
set original_handoff_sha $expected_handoff_sha
set handoff [read_key_values $handoff_path]
foreach requirement [list \
    [list RESULT PASS] [list PROFILE_ELABORATION PASS] \
    [list SOURCE_COMMIT $source_commit] [list SOURCE_TREE $source_tree] \
    [list EXPECTED_PARENT $expected_parent] [list DIRECT_PARENT_BINDING PASS] \
    [list AUTHORIZED_CHANGED_SET 11/11] \
    [list R3_DONOR_BUILD_TCL_SHA256 $expected_donor_sha] \
    [list TNS 0.000] [list THS 0.000] \
    [list RAW_UNCONSTRAINED_PATH_TABLE_ROWS 0] \
    [list RAW_UNCONSTRAINED_ENDPOINTS 0] \
    [list UNCONSTRAINED_GATE PASS] \
    [list RM1_CDC_FINDINGS_DISPOSITIONED 33] \
    [list LUT_HARD_GATE PASS_LE_98_PERCENT] \
    [list ACTIVE_BUS_SKEW_GROUPS 11/11] \
    [list PROMOTED_REPLACEMENT_CHECKS 17/17] \
    [list NEW_UNRESOLVED_CRITICAL_CDC 0] \
    [list NEW_UNRESOLVED_WARNING_CDC 0] \
    [list DRC_HARD_GATE PASS] [list METHODOLOGY_HARD_GATE PASS] \
    [list BITSTREAM_PRODUCED NO] [list WRITE_BITSTREAM_COUNT 0] \
    [list WRITE_DEBUG_PROBES_COUNT 0] [list HARDWARE_ACCESSED NO]] {
  lassign $requirement key expected
  require_value $handoff $key $expected
}
set routed_dcp [file normalize [dict get $handoff ROUTED_DCP]]
set expected_dcp_sha [dict get $handoff ROUTED_DCP_SHA256]
if {![file isfile $routed_dcp] || [sha256_file $routed_dcp] ne $expected_dcp_sha} {
  error "routed DCP identity mismatch"
}
set input_manifest [file join $evidence_root G2B_NVP_DIAG2_RM1_BUILD_INPUT_SHA256.txt]
if {![file isfile $input_manifest]} { error "build input manifest missing" }
if {[sha256_file $input_manifest] ne [dict get $handoff BUILD_INPUT_MANIFEST_SHA256]} {
  error "build input manifest hash does not match routed handoff"
}
set manifest_text [read_text $input_manifest]
set harness_root [file dirname $build_harness]
set sealed_harness_hashes [dict create]
set sealed_harness_casefold_paths [dict create]
foreach name {
    g2b_nvp_diag2_rm1_build.tcl
    g2b_nvp_diag2_rm1_finalize.tcl
    invoke_rm1_one_shot_build.ps1
    bind_rm1_receipts_to_source.ps1
    run_rm1_affected_regressions.ps1
    check_rm1_build_harness.ps1
    check_rm1_harness_syntax.tcl
    RM1_PUBLICATION_READBACK_RECEIPT_SCHEMA.json
    RM1_BUILD_HARNESS_README.md} {
  set path [file normalize [file join $harness_root $name]]
  set casefold_path [string tolower $path]
  if {[dict exists $sealed_harness_casefold_paths $casefold_path]} {
    error "case-alias/duplicate sealed harness path: $path"
  }
  dict set sealed_harness_casefold_paths $casefold_path $path
  if {![file isfile $path]} { error "sealed harness component missing: $path" }
  set component_sha [sha256_file $path]
  if {[string first "EXTERNAL:$path|$component_sha" $manifest_text] < 0} {
    error "harness component not sealed by build input manifest: $name"
  }
  dict set sealed_harness_hashes $path $component_sha
}
if {[dict size $sealed_harness_casefold_paths] != 9} {
  error "sealed harness case-folded path set mismatch"
}
if {![final_harness_seal_current]} { error "initial finalizer harness seal mismatch" }

set sealed_authority_hashes [dict create]
set sealed_authority_casefold_paths [dict create]
foreach {path_key sha_key} {
    PRE_VIVADO_SEAL PRE_VIVADO_SEAL_SHA256
    FOCUSED_RECEIPT FOCUSED_RECEIPT_SHA256
    AFFECTED_R3_RECEIPT AFFECTED_R3_RECEIPT_SHA256
    RECEIPT_BINDING RECEIPT_BINDING_SHA256
    PUBLICATION_READBACK_RECEIPT PUBLICATION_READBACK_RECEIPT_SHA256
    R3_DONOR_BUILD_TCL R3_DONOR_BUILD_TCL_SHA256} {
  if {![dict exists $handoff $path_key] || ![dict exists $handoff $sha_key]} {
    error "authority handoff field missing: $path_key/$sha_key"
  }
  set path [file normalize [dict get $handoff $path_key]]
  set casefold_path [string tolower $path]
  set expected_sha [dict get $handoff $sha_key]
  if {![regexp {^[0-9A-F]{64}$} $expected_sha] || ![file isfile $path] ||
      [sha256_file $path] ne $expected_sha ||
      [string first "EXTERNAL:$path|$expected_sha" $manifest_text] < 0 ||
      [dict exists $sealed_authority_hashes $path] ||
      [dict exists $sealed_authority_casefold_paths $casefold_path]} {
    error "authority receipt/seal does not match immutable build manifest: $path_key"
  }
  dict set sealed_authority_hashes $path $expected_sha
  dict set sealed_authority_casefold_paths $casefold_path $path_key
}
if {[dict size $sealed_authority_casefold_paths] != 6} {
  error "authority case-folded path set mismatch"
}
if {![final_authority_seal_current]} { error "initial finalizer authority seal mismatch" }

set original_dcp_sha [sha256_file $routed_dcp]
set final_code [catch {
  open_checkpoint $routed_dcp
  if {[get_property PART [current_design]] ne $expected_part} { error "routed part mismatch" }
  if {![report_route_status -boolean_check ROUTED_FULLY] ||
      [report_route_status -boolean_check ERRORS_IN_ROUTES] ||
      [llength [report_route_status -return_nets -route_type UNROUTED]] != 0 ||
      [llength [report_route_status -return_nets -route_type PARTIAL]] != 0} {
    error "final route status gate failed"
  }
  set wns [routed_slack max]
  set whs [routed_slack min]
  set failing_setup [llength [get_timing_paths -quiet -delay_type max -slack_lesser_than 0.0 -max_paths 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min -slack_lesser_than 0.0 -max_paths 1]]
  set tns [expr {$failing_setup == 0 ? 0.0 : -1.0}]
  set ths [expr {$failing_hold == 0 ? 0.0 : -1.0}]
  if {$wns < 0.0 || $whs < 0.0 || $failing_setup != 0 || $failing_hold != 0} {
    error "final timing gate failed"
  }
  set unconstrained [final_unconstrained_gate]
  if {[dict get $unconstrained RAW_ENDPOINTS] != 0} { error "final unconstrained gate failed" }
  set final_cdc_findings [final_cdc_gate]
  lassign [final_drc_methodology_gate] final_drc_warnings final_methodology_warnings
  final_profile_gate
  set utilization [report_utilization -return_string]
  report_utilization -file [file join $artifact_root G2B_NVP_DIAG2_RM1_FINAL_UTILIZATION.rpt]
  lassign [utilization_row $utilization {Slice LUTs}] lut_used lut_available
  lassign [utilization_row $utilization {Slice Registers}] ff_used ff_available
  lassign [utilization_row $utilization {Block RAM Tile}] bram_used bram_available
  lassign [utilization_row $utilization {DSPs}] dsp_used dsp_available
  set lut_used [expr {wide(round($lut_used))}]
  set lut_available [expr {wide(round($lut_available))}]
  set ff_percent [expr {100.0 * $ff_used / $ff_available}]
  set bram_percent [expr {100.0 * $bram_used / $bram_available}]
  set dsp_percent [expr {100.0 * $dsp_used / $dsp_available}]
  if {$lut_available != $expected_lut_available || $lut_used > $lut_hard_max ||
      $ff_percent > 95.0 || $bram_percent > 90.0 || $dsp_percent > 90.0} {
    error "final resource gate failed"
  }
  set debug_count 0
  if {![catch {get_debug_cores -quiet} cores]} { set debug_count [llength $cores] }
  if {$debug_count != 0} { error "debug cores are prohibited in RM1 output" }
  if {![source_seal_current] || ![final_harness_seal_current] ||
      ![final_authority_seal_current] ||
      [sha256_file $routed_dcp] ne $original_dcp_sha ||
      [sha256_file $handoff_path] ne $original_handoff_sha} {
    error "source/harness or routed handoff drifted before output generation"
  }

  set signed_dcp [file join $artifact_root G2B_NVP_VIDEO_DIAG2_RM1_R1_SIGNED_OFF_ROUTED.dcp]
  set bitstream [file join $artifact_root G2B_NVP_VIDEO_DIAG2_RM1_R1_RAW_MARKER.bit]
  if {[file exists $signed_dcp] || [file exists $bitstream]} { error "final output target already exists" }
  write_checkpoint $signed_dcp
  set signed_dcp_sha [sha256_file $signed_dcp]
  write_bitstream $bitstream
  if {![file isfile $bitstream] || [file size $bitstream] == 0} { error "bitstream not generated" }
  set bitstream_sha [sha256_file $bitstream]
  if {![source_seal_current] || ![final_harness_seal_current] ||
      ![final_authority_seal_current] ||
      [sha256_file $routed_dcp] ne $original_dcp_sha ||
      [sha256_file $handoff_path] ne $original_handoff_sha} {
    error "source/DCP/full-harness drifted during finalization"
  }
  write_lines [file join $artifact_root G2B_NVP_DIAG2_RM1_SIGNOFF_RESULT.txt] [list \
    {RESULT=PASS} \
    {CANDIDATE_CLASSIFICATION=RM1_R1_OFFLINE_QUALIFIED_NO_DMA_RAW_MARKER_CANDIDATE} \
    "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
    "EXPECTED_PARENT=$expected_parent" {DIRECT_PARENT_BINDING=PASS} \
    {AUTHORIZED_CHANGED_SET=11/11} \
    "BUILD_HANDOFF_SHA256=$original_handoff_sha" \
    "SOURCE_ROUTED_DCP=$routed_dcp" "SOURCE_ROUTED_DCP_SHA256=$original_dcp_sha" \
    "SIGNED_OFF_DCP=$signed_dcp" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" \
    "BITSTREAM=$bitstream" "BITSTREAM_SIZE=[file size $bitstream]" \
    "BITSTREAM_SHA256=$bitstream_sha" \
    "WNS=[format %.3f $wns]" "TNS=[format %.3f $tns]" \
    "WHS=[format %.3f $whs]" "THS=[format %.3f $ths]" \
    "RAW_UNCONSTRAINED_PATH_TABLE_ROWS=[dict get $unconstrained RAW_TABLE_ROWS]" \
    "RAW_UNCONSTRAINED_ENDPOINTS=[dict get $unconstrained RAW_ENDPOINTS]" \
    {UNCONSTRAINED_GATE=PASS} \
    "FINAL_RM1_CDC_FINDINGS_DISPOSITIONED=$final_cdc_findings" \
    "LUT_USED=$lut_used" "LUT_AVAILABLE=$lut_available" \
    "LUT_PERCENT=[format %.3f [expr {100.0 * $lut_used / $lut_available}]]" \
    "LUT_PREFERRED_GATE=[expr {$lut_used <= $lut_preferred_max ? {PASS} : {ADVISORY_MISS}}]" \
    {ACTIVE_BUS_SKEW_GROUPS=11/11_BUILD_HANDOFF_VERIFIED} \
    {PROMOTED_REPLACEMENT_CHECKS=17/17_BUILD_HANDOFF_VERIFIED} \
    {NEW_UNRESOLVED_CRITICAL_CDC=0_FINAL_DCP_VERIFIED} \
    {NEW_UNRESOLVED_WARNING_CDC=0_FINAL_DCP_VERIFIED} \
    "FINAL_DRC_WARNINGS=$final_drc_warnings" {FINAL_DRC_HARD_GATE=PASS} \
    "FINAL_METHODOLOGY_WARNINGS=$final_methodology_warnings" \
    {FINAL_METHODOLOGY_HARD_GATE=PASS} \
    {WRITE_CHECKPOINT_COUNT=1} {WRITE_BITSTREAM_COUNT=1} \
    {LTX=NONE_EXPECTED} {HARDWARE_ACCESSED=NO}]
} failure failure_options]

catch {close_design}
if {$final_code != 0} {
  write_lines [file join $artifact_root G2B_NVP_DIAG2_RM1_FINALIZER_FAILURE.txt] [list \
    {RESULT=FAIL} "ERROR=$failure" {BITSTREAM_AUTHORIZED=NO} {HARDWARE_ACCESSED=NO}]
  puts stderr "RM1_FINALIZER_FAIL: $failure"
  exit 1
}
puts "RM1_FINALIZER_PASS SIGNED_DCP=1 BITSTREAM=1 HARDWARE_ACCESSED=NO"
exit 0
