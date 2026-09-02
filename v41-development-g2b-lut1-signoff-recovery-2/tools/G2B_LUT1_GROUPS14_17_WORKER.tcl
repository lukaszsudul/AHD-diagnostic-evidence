# AHD v41 G2B-LUT1 Recovery-2 routed Groups 14-17 bus-skew worker.
#
# One Vivado process analyzes exactly one governed group.  It first loads the
# complete promoted timing context in this order:
#
#   1. G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc
#   2. G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc
#   3. G2B_G13A_CANDIDATE_CONSTRAINTS.xdc
#
# The immutable base contains the 15 still-governed bus-skew relations.  Since
# report_bus_skew has no constraint selector, a worker-local copy removes all
# 15 bus-skew command lines, both promoted candidate files are reapplied, and
# exactly one 3.000 ns Group 14-17 relation is reconstructed.  Group 9 and
# Group 13 report_bus_skew are rejected by construction and never execute.

set EXPECTED_DCP_SHA256 EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83
set EXPECTED_BASE_XDC_SHA256 3F7D8613AB3ECF579F3F1E7A09B1608602768D2B9C880CE3B755437081DF1F87
set EXPECTED_BS3_CANDIDATE_XDC_SHA256 AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087
set EXPECTED_G13_CANDIDATE_XDC_SHA256 E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312

proc write_lines_atomic {path lines} {
  file mkdir [file dirname $path]
  set temporary [format {%s.%s.tmp} $path [pid]]
  set handle [open $temporary w]
  fconfigure $handle -encoding utf-8 -translation lf
  foreach line $lines { puts $handle $line }
  close $handle
  file rename -force $temporary $path
}

proc write_text_atomic {path value} {
  file mkdir [file dirname $path]
  set temporary [format {%s.%s.tmp} $path [pid]]
  set handle [open $temporary w]
  fconfigure $handle -encoding utf-8 -translation lf
  puts -nonewline $handle $value
  close $handle
  file rename -force $temporary $path
}

proc read_text {path} {
  set handle [open $path r]
  fconfigure $handle -encoding utf-8 -translation auto
  set value [read $handle]
  close $handle
  return $value
}

proc safe_value {value} {
  return [string map [list "\r" {\r} "\n" {\n} "=" {:}] $value]
}

proc sha256_file {path} {
  if {![file isfile $path]} { error "file is absent for SHA-256: $path" }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper \
        [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}

proc count_xdc_command_lines {text command_name} {
  set expression [format {^[ \t]*%s(?:[ \t]|$)} $command_name]
  return [regexp -all -line $expression $text]
}

proc derive_bus_skew_free_base {base_text output_path} {
  set kept [list]
  set removed 0
  foreach line [split $base_text "\n"] {
    if {[regexp {^[ \t]*set_bus_skew(?:[ \t]|$)} $line]} {
      if {[regexp {\\[ \t]*$} $line]} {
        error "base XDC contains a continued set_bus_skew command"
      }
      incr removed
      continue
    }
    lappend kept $line
  }
  if {$removed != 15} {
    error "full base did not remove exactly 15 bus-skew commands: $removed"
  }
  set derived_text [join $kept "\n"]
  if {[count_xdc_command_lines $derived_text set_bus_skew] != 0} {
    error "worker-local query base still contains set_bus_skew"
  }
  write_text_atomic $output_path $derived_text
  return $removed
}

proc clock_signature {} {
  set rows [list]
  foreach clock [lsort -dictionary [get_clocks -quiet]] {
    lappend rows "[get_property NAME $clock]|[get_property PERIOD $clock]|[get_property WAVEFORM $clock]"
  }
  if {[llength $rows] == 0} { error "routed clock signature is empty" }
  return [join $rows "\n"]
}

proc route_signature {} {
  return [list \
    [report_route_status -boolean_check ROUTED_FULLY] \
    [report_route_status -boolean_check ERRORS_IN_ROUTES] \
    [llength [report_route_status -return_nets -route_type UNROUTED]] \
    [llength [report_route_status -return_nets -route_type PARTIAL]]]
}

proc sequential_cells {pattern} {
  return [filter [get_cells -quiet -hier -regexp $pattern] {IS_SEQUENTIAL == 1}]
}

proc sorted_object_names {objects} {
  set names [list]
  foreach object $objects { lappend names [get_property NAME $object] }
  set unique_names [lsort -dictionary -unique $names]
  if {[llength $unique_names] != [llength $names]} {
    error "duplicate objects resolved in collection"
  }
  return $unique_names
}

proc resolve_bus_skew_group {group_id} {
  if {$group_id < 14 || $group_id > 17} {
    error "Recovery-2 worker accepts only Groups 14, 15, 16, and 17; requested group=$group_id"
  }
  set slot [expr {$group_id - 14}]
  set name "RELEASE_SLOT_[set slot]_AXI_TO_SOURCE"
  set sources [sequential_cells ".*G2B_ONECH_C2H/(release_generation_axi|release_epoch_axi)_reg\\\[$slot\\\].*"]
  set destinations [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}]
  return [list $name $sources $destinations 56 20]
}

proc parse_compact_metric {report_path label} {
  set rows [list]
  set report_text [read_text $report_path]
  foreach line [split $report_text "\n"] {
    if {[regexp {(?:^|[ \t])(Slow|Fast)[ \t]+(-?[0-9]+(?:\.[0-9]+)?)[ \t]+(-?[0-9]+(?:\.[0-9]+)?)[ \t]+(-?[0-9]+(?:\.[0-9]+)?)[ \t]*$} \
        $line -> corner requirement actual slack]} {
      lappend rows [list $corner $requirement $actual $slack]
    }
  }
  if {[llength $rows] != 1} {
    error "$label metric-row count failed: [llength $rows]"
  }
  lassign [lindex $rows 0] corner requirement actual slack
  if {![string is double -strict $requirement] ||
      ![string is double -strict $actual] ||
      ![string is double -strict $slack] ||
      abs($requirement - 3.000) > 0.0005} {
    error "$label metric is invalid: requirement=$requirement actual=$actual slack=$slack"
  }
  set negative_display [string match {-*} $slack]
  set violation_marker \
      [regexp -nocase {Slack[ \t]*\([ \t]*VIOLATED[ \t]*\)} $report_text]
  return [list $corner $requirement $actual $slack \
      $negative_display $violation_marker]
}

proc require_promoted_candidate_collections {} {
  foreach variable_name {
    g2b_bs3_ownership_slot_src
    g2b_bs3_ownership_generation_src
    g2b_bs3_ownership_epoch_src
    g2b_bs3_ownership_payload_dst_cells
    g2b_bs3_ownership_payload_dst_d
    g2b_g13a_abandoned_src
    g2b_g13a_commit_phase_src
    g2b_g13a_abandoned_dst_cells
    g2b_g13a_all_dst_cells
    g2b_g13a_abandoned_dst_d
    g2b_g13a_all_dst_d
  } {
    if {![uplevel 1 [list info exists $variable_name]]} {
      error "promoted candidate collection is absent: $variable_name"
    }
  }
  set bs3_counts [list \
      [llength [uplevel 1 {set g2b_bs3_ownership_slot_src}]] \
      [llength [uplevel 1 {set g2b_bs3_ownership_generation_src}]] \
      [llength [uplevel 1 {set g2b_bs3_ownership_epoch_src}]] \
      [llength [uplevel 1 {set g2b_bs3_ownership_payload_dst_cells}]] \
      [llength [uplevel 1 {set g2b_bs3_ownership_payload_dst_d}]]]
  if {$bs3_counts ne [list 2 24 32 17 17]} {
    error "BS3 candidate collection count drift: $bs3_counts"
  }
  set g13_counts [list \
      [llength [uplevel 1 {set g2b_g13a_abandoned_src}]] \
      [llength [uplevel 1 {set g2b_g13a_commit_phase_src}]] \
      [llength [uplevel 1 {set g2b_g13a_abandoned_dst_cells}]] \
      [llength [uplevel 1 {set g2b_g13a_all_dst_cells}]] \
      [llength [uplevel 1 {set g2b_g13a_abandoned_dst_d}]] \
      [llength [uplevel 1 {set g2b_g13a_all_dst_d}]]]
  if {$g13_counts ne [list 3 4 32 207 32 207]} {
    error "G13-A candidate collection count drift: $g13_counts"
  }
  return [list $bs3_counts $g13_counts]
}

proc main {checkpoint base_xdc bs3_candidate_xdc g13_candidate_xdc output_dir group_id expected_worker_sha} {
  global EXPECTED_DCP_SHA256 EXPECTED_BASE_XDC_SHA256
  global EXPECTED_BS3_CANDIDATE_XDC_SHA256 EXPECTED_G13_CANDIDATE_XDC_SHA256
  global result_path selected_name selected_state

  if {![string is integer -strict $group_id] || $group_id < 14 || $group_id > 17} {
    error "governed worker group_id must be 14..17"
  }
  foreach required [list $checkpoint $base_xdc $bs3_candidate_xdc \
      $g13_candidate_xdc [info script]] {
    if {![file isfile $required]} { error "required file is absent: $required" }
  }
  if {[sha256_file [info script]] ne $expected_worker_sha} {
    error "worker Tcl changed after orchestration seal"
  }
  if {[sha256_file $checkpoint] ne $EXPECTED_DCP_SHA256} {
    error "sealed routed DCP hash mismatch"
  }
  if {[sha256_file $base_xdc] ne $EXPECTED_BASE_XDC_SHA256} {
    error "base-without-Group9/Group13 XDC hash mismatch"
  }
  if {[sha256_file $bs3_candidate_xdc] ne $EXPECTED_BS3_CANDIDATE_XDC_SHA256} {
    error "BS3 candidate XDC hash mismatch"
  }
  if {[sha256_file $g13_candidate_xdc] ne $EXPECTED_G13_CANDIDATE_XDC_SHA256} {
    error "G13-A candidate XDC hash mismatch"
  }
  if {![info exists ::env(XILINX_LOCAL_USER_DATA)] ||
      $::env(XILINX_LOCAL_USER_DATA) ne "NO"} {
    error "XILINX_LOCAL_USER_DATA must be NO"
  }
  if {![info exists ::env(TEMP)] || ![info exists ::env(TMP)] ||
      ![string equal -nocase [file normalize $::env(TEMP)] \
          [file normalize $::env(TMP)]]} {
    error "TEMP and TMP must identify the same worker-only directory"
  }

  write_lines_atomic $result_path [list \
    {STATE=RUNNING} "GROUP_ID=$group_id" {GROUP_NAME=UNKNOWN} \
    "CHECKPOINT=$checkpoint" "SEALED_DCP_SHA256=$EXPECTED_DCP_SHA256" \
    "BASE_XDC=$base_xdc" "BASE_XDC_SHA256=$EXPECTED_BASE_XDC_SHA256" \
    "BS3_CANDIDATE_XDC=$bs3_candidate_xdc" \
    "BS3_CANDIDATE_XDC_SHA256=$EXPECTED_BS3_CANDIDATE_XDC_SHA256" \
    "G13_CANDIDATE_XDC=$g13_candidate_xdc" \
    "G13_CANDIDATE_XDC_SHA256=$EXPECTED_G13_CANDIDATE_XDC_SHA256" \
    "WORKER_TCL_SHA256=$expected_worker_sha" \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO}]

  set vivado_version [string trim [version -short]]
  regexp {SW Build[ \t]+([0-9]+)} [version] -> vivado_sw_build
  if {$vivado_version ne "2025.2" || $vivado_sw_build ne "6299465"} {
    error "Vivado identity drift: $vivado_version/$vivado_sw_build"
  }

  open_checkpoint $checkpoint
  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} {
    error "sealed routed DCP part mismatch: $part"
  }
  set pre_clock_signature [clock_signature]
  set pre_route_signature [route_signature]
  if {$pre_route_signature ne [list 1 0 0 0]} {
    error "sealed routed DCP route signature failed: $pre_route_signature"
  }

  set base_text [read_text $base_xdc]
  set bs3_candidate_text [read_text $bs3_candidate_xdc]
  set g13_candidate_text [read_text $g13_candidate_xdc]
  if {[count_xdc_command_lines $base_text set_bus_skew] != 15 ||
      [count_xdc_command_lines $base_text set_max_delay] != 9 ||
      [count_xdc_command_lines $bs3_candidate_text set_bus_skew] != 0 ||
      [count_xdc_command_lines $bs3_candidate_text set_max_delay] != 3 ||
      [count_xdc_command_lines $g13_candidate_text set_bus_skew] != 0 ||
      [count_xdc_command_lines $g13_candidate_text set_max_delay] != 2} {
    error "promoted full constraint-context command-count drift"
  }

  reset_timing -invalid
  read_xdc $base_xdc
  read_xdc $bs3_candidate_xdc
  read_xdc $g13_candidate_xdc
  set full_candidate_counts [require_promoted_candidate_collections]
  if {[clock_signature] ne $pre_clock_signature ||
      [route_signature] ne $pre_route_signature} {
    error "clock or route signature changed in promoted full context"
  }
  set full_context_path [file join $output_dir FULL_PROMOTED_CONTEXT.xdc]
  write_xdc -exclude_physical -force $full_context_path
  set full_context_text [read_text $full_context_path]
  if {[count_xdc_command_lines $full_context_text set_bus_skew] != 15 ||
      [count_xdc_command_lines $full_context_text set_max_delay] != 14} {
    error "exported promoted full-context command-count drift"
  }

  set local_base [file join $output_dir QUERY_BASE_WITHOUT_BUS_SKEW.xdc]
  set removed_count [derive_bus_skew_free_base $base_text $local_base]

  reset_timing -invalid
  read_xdc $local_base
  read_xdc $bs3_candidate_xdc
  read_xdc $g13_candidate_xdc
  set query_candidate_counts [require_promoted_candidate_collections]
  if {$query_candidate_counts ne $full_candidate_counts} {
    error "promoted candidate collection identity changed in isolated query context"
  }
  if {[clock_signature] ne $pre_clock_signature ||
      [route_signature] ne $pre_route_signature} {
    error "clock or route signature changed in isolated query context"
  }

  lassign [resolve_bus_skew_group $group_id] \
      selected_name sources destinations expected_sources expected_destinations
  set source_names [sorted_object_names $sources]
  set destination_names [sorted_object_names $destinations]
  set source_count [llength $source_names]
  set destination_count [llength $destination_names]
  if {$source_count != $expected_sources ||
      $destination_count != $expected_destinations} {
    error "$selected_name collection drift: sources=$source_count/$expected_sources destinations=$destination_count/$expected_destinations"
  }
  foreach source_name $source_names {
    if {[lsearch -exact $destination_names $source_name] >= 0} {
      error "$selected_name has source/destination identity overlap: $source_name"
    }
  }

  set tag [format {%02d_%s} $group_id $selected_name]
  set objects_path [file join $output_dir [format {%s_OBJECTS.txt} $tag]]
  set isolated_path [file join $output_dir [format {%s_ISOLATED_CONTEXT.xdc} $tag]]
  set report_path [file join $output_dir [format {%s_BUS_SKEW.rpt} $tag]]
  set object_lines [list]
  foreach name $source_names { lappend object_lines "SOURCE=$name" }
  foreach name $destination_names { lappend object_lines "DESTINATION=$name" }
  write_lines_atomic $objects_path $object_lines

  set_bus_skew 3.000 -from $sources -to $destinations
  write_xdc -exclude_physical -force $isolated_path
  set isolated_text [read_text $isolated_path]
  if {[count_xdc_command_lines $isolated_text set_bus_skew] != 1 ||
      [count_xdc_command_lines $isolated_text set_max_delay] != 14} {
    error "$selected_name isolated query context command-count drift"
  }

  set command {report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file <GROUP_RAW_REPORT>}
  set query_start [clock milliseconds]
  write_lines_atomic [file join $output_dir QUERY_STARTED.marker] [list \
    "GROUP_ID=$group_id" "GROUP_NAME=$selected_name" \
    "EPOCH_MILLISECONDS=$query_start" {TIMEOUT_SECONDS=300} \
    "COMMAND=$command" \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO}]

  report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 \
      -warn_on_violation -file $report_path
  set query_end [clock milliseconds]
  set elapsed_ms [expr {$query_end - $query_start}]
  set elapsed_seconds [format %.3f [expr {double($elapsed_ms) / 1000.0}]]
  lassign [parse_compact_metric $report_path $selected_name] \
      corner requirement actual slack negative_display violation_marker
  set selected_state \
      [expr {$slack < 0.0 || $negative_display || $violation_marker \
          ? {VIOLATION} : {PASS}}]

  # End the externally watched query interval immediately after the governed
  # command returned and its compact metric parsed.  Input re-hashing and
  # receipt generation below are post-query work and are not charged to the
  # 300-second report_bus_skew budget.
  write_lines_atomic [file join $output_dir QUERY_COMPLETED.marker] [list \
    "GROUP_ID=$group_id" "GROUP_NAME=$selected_name" \
    "QUERY_START_EPOCH_MILLISECONDS=$query_start" \
    "QUERY_END_EPOCH_MILLISECONDS=$query_end" \
    "QUERY_RUNTIME_SECONDS=$elapsed_seconds" \
    {TIMEOUT_SECONDS=300} "STATUS=$selected_state" \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO}]

  if {[sha256_file $checkpoint] ne $EXPECTED_DCP_SHA256 ||
      [sha256_file $base_xdc] ne $EXPECTED_BASE_XDC_SHA256 ||
      [sha256_file $bs3_candidate_xdc] ne $EXPECTED_BS3_CANDIDATE_XDC_SHA256 ||
      [sha256_file $g13_candidate_xdc] ne $EXPECTED_G13_CANDIDATE_XDC_SHA256 ||
      [route_signature] ne $pre_route_signature} {
    error "sealed input or route signature changed during query"
  }

  lassign $full_candidate_counts bs3_counts g13_counts
  write_lines_atomic $result_path [list \
    "STATE=$selected_state" "GROUP_ID=$group_id" \
    "GROUP_NAME=$selected_name" "COMMAND=$command" \
    "CHECKPOINT=$checkpoint" "SEALED_DCP_SHA256=$EXPECTED_DCP_SHA256" \
    "BASE_XDC=$base_xdc" "BASE_XDC_SHA256=$EXPECTED_BASE_XDC_SHA256" \
    "BS3_CANDIDATE_XDC=$bs3_candidate_xdc" \
    "BS3_CANDIDATE_XDC_SHA256=$EXPECTED_BS3_CANDIDATE_XDC_SHA256" \
    "G13_CANDIDATE_XDC=$g13_candidate_xdc" \
    "G13_CANDIDATE_XDC_SHA256=$EXPECTED_G13_CANDIDATE_XDC_SHA256" \
    "WORKER_TCL_SHA256=$expected_worker_sha" \
    "VIVADO_VERSION=$vivado_version" "VIVADO_SW_BUILD=$vivado_sw_build" \
    "PART=$part" \
    "FULLY_ROUTED=[lindex $pre_route_signature 0]" \
    "ERRORS_IN_ROUTES=[lindex $pre_route_signature 1]" \
    "UNROUTED_NETS=[lindex $pre_route_signature 2]" \
    "PARTIAL_NETS=[lindex $pre_route_signature 3]" \
    {CLOCK_SIGNATURE_MATCH=YES} {ROUTE_SIGNATURE_UNCHANGED=YES} \
    {FULL_CONTEXT_BASE_BUS_SKEW_COMMAND_COUNT=15} \
    {FULL_CONTEXT_BASE_MAX_DELAY_COMMAND_COUNT=9} \
    {FULL_CONTEXT_BS3_BUS_SKEW_COMMAND_COUNT=0} \
    {FULL_CONTEXT_BS3_MAX_DELAY_COMMAND_COUNT=3} \
    {FULL_CONTEXT_G13_BUS_SKEW_COMMAND_COUNT=0} \
    {FULL_CONTEXT_G13_MAX_DELAY_COMMAND_COUNT=2} \
    {FULL_CONTEXT_TOTAL_BUS_SKEW_COMMAND_COUNT=15} \
    {FULL_CONTEXT_TOTAL_MAX_DELAY_COMMAND_COUNT=14} \
    "WORKER_LOCAL_REMOVED_BUS_SKEW_COMMAND_COUNT=$removed_count" \
    {QUERY_CONTEXT_BUS_SKEW_COMMAND_COUNT=1} \
    {QUERY_CONTEXT_MAX_DELAY_COMMAND_COUNT=14} \
    "FULL_PROMOTED_CONTEXT_SHA256=[sha256_file $full_context_path]" \
    "BS3_SLOT_SOURCE_COUNT=[lindex $bs3_counts 0]" \
    "BS3_GENERATION_SOURCE_COUNT=[lindex $bs3_counts 1]" \
    "BS3_EPOCH_SOURCE_COUNT=[lindex $bs3_counts 2]" \
    "BS3_DESTINATION_CELL_COUNT=[lindex $bs3_counts 3]" \
    "BS3_DESTINATION_PIN_COUNT=[lindex $bs3_counts 4]" \
    "G13_ABANDONED_SOURCE_COUNT=[lindex $g13_counts 0]" \
    "G13_COMMIT_PHASE_SOURCE_COUNT=[lindex $g13_counts 1]" \
    "G13_ABANDONED_DESTINATION_CELL_COUNT=[lindex $g13_counts 2]" \
    "G13_ALL_DESTINATION_CELL_COUNT=[lindex $g13_counts 3]" \
    "G13_ABANDONED_DESTINATION_PIN_COUNT=[lindex $g13_counts 4]" \
    "G13_ALL_DESTINATION_PIN_COUNT=[lindex $g13_counts 5]" \
    "SOURCE_COUNT=$source_count" "DESTINATION_COUNT=$destination_count" \
    "OBJECTS_SHA256=[sha256_file $objects_path]" \
    "QUERY_BASE_SHA256=[sha256_file $local_base]" \
    "ISOLATED_CONTEXT_XDC_SHA256=[sha256_file $isolated_path]" \
    "RAW_REPORT_SHA256=[sha256_file $report_path]" \
    "CORNER=$corner" "REQUIREMENT_NS=$requirement" \
    "ACTUAL_NS=$actual" "SLACK_NS=$slack" \
    "NEGATIVE_DISPLAY=$negative_display" \
    "VIOLATION_MARKER=$violation_marker" \
    "QUERY_RUNTIME_MILLISECONDS=$elapsed_ms" \
    "QUERY_RUNTIME_SECONDS=$elapsed_seconds" \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO}]
}

if {[llength $argv] != 7} {
  puts stderr "usage: worker.tcl CHECKPOINT BASE_XDC BS3_CANDIDATE_XDC G13_CANDIDATE_XDC OUTPUT_DIR GROUP_ID EXPECTED_WORKER_SHA"
  exit 2
}

lassign $argv checkpoint base_xdc bs3_candidate_xdc g13_candidate_xdc \
    output_dir group_id expected_worker_sha
set checkpoint [file normalize $checkpoint]
set base_xdc [file normalize $base_xdc]
set bs3_candidate_xdc [file normalize $bs3_candidate_xdc]
set g13_candidate_xdc [file normalize $g13_candidate_xdc]
set output_dir [file normalize $output_dir]
file mkdir $output_dir
set result_path [file join $output_dir worker_result.txt]
set selected_name UNKNOWN
set selected_state ERROR

write_lines_atomic [file join $output_dir WORKER_STARTED.marker] [list \
  "GROUP_ID=$group_id" "EPOCH_MILLISECONDS=[clock milliseconds]" \
  {INITIALIZATION_TIMEOUT_SECONDS=1800} \
  {QUERY_TIMEOUT_SECONDS=300} \
  {ATTEMPT=1} {MAX_ATTEMPTS=1} \
  {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
  {GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO} \
  {HARDWARE_ACCESSED=NO}]

set code [catch {
  main $checkpoint $base_xdc $bs3_candidate_xdc $g13_candidate_xdc \
      $output_dir $group_id $expected_worker_sha
} message options]
if {$code != 0} {
  set error_info $message
  if {[dict exists $options -errorinfo]} {
    set error_info [dict get $options -errorinfo]
  }
  write_lines_atomic $result_path [list \
    {STATE=ERROR} "GROUP_ID=$group_id" "GROUP_NAME=$selected_name" \
    "CHECKPOINT=$checkpoint" "SEALED_DCP_SHA256=$EXPECTED_DCP_SHA256" \
    "BASE_XDC=$base_xdc" "BASE_XDC_SHA256=$EXPECTED_BASE_XDC_SHA256" \
    "BS3_CANDIDATE_XDC=$bs3_candidate_xdc" \
    "BS3_CANDIDATE_XDC_SHA256=$EXPECTED_BS3_CANDIDATE_XDC_SHA256" \
    "G13_CANDIDATE_XDC=$g13_candidate_xdc" \
    "G13_CANDIDATE_XDC_SHA256=$EXPECTED_G13_CANDIDATE_XDC_SHA256" \
    "WORKER_TCL_SHA256=$expected_worker_sha" \
    "ERROR=[safe_value $message]" \
    "ERROR_INFO=[safe_value $error_info]" \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO}]
  puts stderr "G2B_GROUPS14_17_WORKER=ERROR GROUP_ID=$group_id ERROR=[safe_value $message]"
  exit 1
}
if {$selected_state ne "PASS"} {
  puts stderr "G2B_GROUPS14_17_WORKER=VIOLATION GROUP_ID=$group_id GROUP_NAME=$selected_name"
  exit 1
}
puts "G2B_GROUPS14_17_WORKER=PASS GROUP_ID=$group_id GROUP_NAME=$selected_name"
exit 0
