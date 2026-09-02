proc write_text {path text} {
  set handle [open $path w]
  fconfigure $handle -translation lf -encoding utf-8
  puts -nonewline $handle $text
  close $handle
}

proc read_text {path} {
  set handle [open $path r]
  fconfigure $handle -translation auto -encoding utf-8
  set text [read $handle]
  close $handle
  return $text
}

proc seconds_since {start_ms} {
  return [format %.3f [expr {double([clock milliseconds] - $start_ms) / 1000.0}]]
}

proc prop {object property_name} {
  if {[catch {get_property $property_name $object} value] || $value eq ""} {
    return "N/A"
  }
  return $value
}

proc names {objects} {
  if {[llength $objects] == 0} { return [list] }
  return [lsort -dictionary [get_property NAME $objects]]
}

proc csv_field {value} {
  set escaped [string map [list "\"" "\"\""] $value]
  return "\"$escaped\""
}

proc begin_query {output_dir query_id command_text} {
  set epoch [clock milliseconds]
  write_text [file join $output_dir ACTIVE_QUERY.marker] \
      "QUERY_ID=$query_id\nEPOCH_MILLISECONDS=$epoch\nTIMEOUT_SECONDS=300\nCOMMAND=$command_text\n"
  return $epoch
}

proc complete_query {output_dir query_id start_ms status} {
  set elapsed [seconds_since $start_ms]
  write_text [file join $output_dir "QUERY_COMPLETED_${query_id}.marker"] \
      "QUERY_ID=$query_id\nQUERY_RUNTIME_SECONDS=$elapsed\nSTATUS=$status\n"
  file delete -force [file join $output_dir ACTIVE_QUERY.marker]
  return $elapsed
}

proc require_count {label objects expected} {
  set actual [llength $objects]
  if {$actual != $expected} {
    error "$label count mismatch: expected $expected, got $actual"
  }
}

proc require_nonempty {label objects} {
  if {[llength $objects] == 0} {
    error "$label resolved empty"
  }
}

proc require_subset {label subset superset} {
  set superset_names [names $superset]
  foreach object_name [names $subset] {
    if {[lsearch -exact $superset_names $object_name] < 0} {
      error "$label is not a subset; missing $object_name"
    }
  }
}

proc require_disjoint {label first second} {
  set second_names [names $second]
  foreach object_name [names $first] {
    if {[lsearch -exact $second_names $object_name] >= 0} {
      error "$label is not disjoint; overlap $object_name"
    }
  }
}

proc read_reference_sets {path} {
  set expected_sources [list]
  set expected_destinations [list]
  foreach line [split [read_text $path] "\n"] {
    set line [string trim $line]
    if {[regexp {^SOURCE=(.+)$} $line -> object_name]} {
      lappend expected_sources $object_name
    } elseif {[regexp {^DESTINATION=(.+)$} $line -> object_name]} {
      lappend expected_destinations $object_name
    }
  }
  return [list [lsort -dictionary $expected_sources] [lsort -dictionary $expected_destinations]]
}

proc require_reference_identity {sources destinations reference_path} {
  lassign [read_reference_sets $reference_path] expected_sources expected_destinations
  set actual_sources [names $sources]
  set actual_destinations [names $destinations]
  if {$actual_sources ne $expected_sources} {
    error "Group-13 source identity differs from predecessor evidence"
  }
  if {$actual_destinations ne $expected_destinations} {
    error "Group-13 destination identity differs from predecessor evidence"
  }
}

proc clocks_for_cells {cells} {
  set clock_pins [get_pins -quiet -of_objects $cells -filter {REF_PIN_NAME == C}]
  if {[llength $clock_pins] == 0} {
    set clock_pins [get_pins -quiet -of_objects $cells -filter {IS_CLOCK == 1}]
  }
  set clocks [get_clocks -quiet -of_objects $clock_pins]
  if {[llength $clocks] == 0} { return [list] }
  return [lsort -unique -dictionary [get_property NAME $clocks]]
}

proc write_object_inventory {output_dir all_src abandoned_src commit_src all_dst abandoned_dst} {
  set src_clocks [join [clocks_for_cells $all_src] ";"]
  set dst_clocks [join [clocks_for_cells $all_dst] ";"]
  set lines [list "ROLE,FAMILY,OBJECT_NAME,CLOCKS"]
  foreach object_name [names $abandoned_src] {
    lappend lines "SOURCE,RESET_ABANDONED_HOLD,[csv_field $object_name],[csv_field $src_clocks]"
  }
  foreach object_name [names $commit_src] {
    lappend lines "SOURCE,RESET_COMMIT_PHASE_HOLD,[csv_field $object_name],[csv_field $src_clocks]"
  }
  set abandoned_names [names $abandoned_dst]
  foreach object_name [names $all_dst] {
    set family "RESET_RETURN_CONTROL_STATE"
    if {[lsearch -exact $abandoned_names $object_name] >= 0} {
      set family "RECORDS_ABANDONED_AXI"
    }
    lappend lines "DESTINATION,$family,[csv_field $object_name],[csv_field $dst_clocks]"
  }
  write_text [file join $output_dir G2B_G13A_OBJECT_INVENTORY.csv] "[join $lines \n]\n"
}

proc write_path_properties {path output_path} {
  set lines [list]
  foreach property_name [lsort -dictionary [list_property $path]] {
    lappend lines "$property_name=[prop $path $property_name]"
  }
  write_text $output_path "[join $lines \n]\n"
}

proc write_primary_paths_csv {paths output_path} {
  set lines [list "INDEX,STARTPOINT_PIN,ENDPOINT_PIN,STARTPOINT_CLOCK,ENDPOINT_CLOCK,DATAPATH_DELAY_NS,REQUIREMENT_NS,SLACK_NS,LOGIC_LEVELS,EXCEPTION,PATH_TYPE"]
  set index 0
  foreach path $paths {
    incr index
    set fields [list $index [prop $path STARTPOINT_PIN] [prop $path ENDPOINT_PIN] \
        [prop $path STARTPOINT_CLOCK] [prop $path ENDPOINT_CLOCK] \
        [prop $path DATAPATH_DELAY] [prop $path REQUIREMENT] [prop $path SLACK] \
        [prop $path LOGIC_LEVELS] [prop $path EXCEPTION] [prop $path PATH_TYPE]]
    set quoted [list]
    foreach field $fields { lappend quoted [csv_field $field] }
    lappend lines [join $quoted ,]
  }
  write_text $output_path "[join $lines \n]\n"
}

proc validate_candidate_family {output_dir family sources destination_cells destination_pins expected_sources expected_destinations} {
  require_count "$family sources" $sources $expected_sources
  require_count "$family destination cells" $destination_cells $expected_destinations
  require_count "$family destination D pins" $destination_pins $expected_destinations

  set command_text "get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <$family sources> -to <$family destination cells; all timing endpoint pins>"
  set query_id "CANDIDATE_[string toupper $family]"
  set query_start [begin_query $output_dir $query_id $command_text]
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $sources -to $destination_cells]
  set query_elapsed [complete_query $output_dir $query_id $query_start PASS]
  require_count "$family candidate timing paths" $paths 1
  set path [lindex $paths 0]
  set actual [prop $path DATAPATH_DELAY]
  set requirement [prop $path REQUIREMENT]
  set slack [prop $path SLACK]
  if {![string is double -strict $actual] || $actual > 6.0005} {
    error "$family actual datapath delay violates 6.000 ns: $actual"
  }
  if {![string is double -strict $requirement] || abs($requirement - 6.000) > 0.0005} {
    error "$family path requirement is not 6.000 ns: $requirement"
  }
  if {![string is double -strict $slack] || $slack < -0.0005} {
    error "$family path slack is negative: $slack"
  }
  set result [dict create \
      FAMILY $family \
      SOURCE_COUNT [llength $sources] \
      DESTINATION_CELL_COUNT [llength $destination_cells] \
      DESTINATION_PIN_COUNT [llength $destination_pins] \
      TARGET_SCOPE CELLS_ALL_TIMING_ENDPOINT_PINS \
      REQUIRED_NS 6.000 \
      ACTUAL_NS $actual \
      SLACK_NS $slack \
      RESULT PASS \
      RUNTIME_SECONDS $query_elapsed \
      STARTPOINT_PIN [prop $path STARTPOINT_PIN] \
      ENDPOINT_PIN [prop $path ENDPOINT_PIN] \
      STARTPOINT_CLOCK [prop $path STARTPOINT_CLOCK] \
      ENDPOINT_CLOCK [prop $path ENDPOINT_CLOCK] \
      LOGIC_LEVELS [prop $path LOGIC_LEVELS] \
      EXCEPTION [prop $path EXCEPTION]]
  write_path_properties $path [file join $output_dir "G2B_G13A_${query_id}_PATH_PROPERTIES.txt"]
  return $result
}

proc candidate_csv_row {result} {
  set keys [list FAMILY SOURCE_COUNT DESTINATION_CELL_COUNT DESTINATION_PIN_COUNT TARGET_SCOPE \
      REQUIRED_NS ACTUAL_NS SLACK_NS RESULT RUNTIME_SECONDS STARTPOINT_PIN \
      ENDPOINT_PIN STARTPOINT_CLOCK ENDPOINT_CLOCK LOGIC_LEVELS EXCEPTION]
  set fields [list]
  foreach key $keys { lappend fields [csv_field [dict get $result $key]] }
  return [join $fields ,]
}

proc validate_supplemental_aggregate {output_dir commit_sources supplemental_cells} {
  require_nonempty "supplemental aggregate cells" $supplemental_cells
  set supplemental_d [get_pins -quiet -of_objects $supplemental_cells -filter {REF_PIN_NAME == D}]
  require_nonempty "supplemental aggregate D-pin inventory" $supplemental_d
  set command_text "get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <4 commit-phase sources> -to <supplemental aggregate cells; all timing endpoint pins>"
  set query_start [begin_query $output_dir SUPPLEMENTAL_AGGREGATE_COVERAGE $command_text]
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $commit_sources -to $supplemental_cells]
  set query_elapsed [complete_query $output_dir SUPPLEMENTAL_AGGREGATE_COVERAGE $query_start PASS]
  require_count "supplemental aggregate timing paths" $paths 1
  set path [lindex $paths 0]
  set actual [prop $path DATAPATH_DELAY]
  set requirement [prop $path REQUIREMENT]
  set slack [prop $path SLACK]
  if {![string is double -strict $actual] || $actual > 6.0005} {
    error "supplemental aggregate actual datapath delay violates 6.000 ns: $actual"
  }
  if {![string is double -strict $requirement] || abs($requirement - 6.000) > 0.0005} {
    error "supplemental aggregate path requirement is not 6.000 ns: $requirement"
  }
  if {![string is double -strict $slack] || $slack < -0.0005} {
    error "supplemental aggregate path slack is negative: $slack"
  }
  set fields [list \
      SUPPLEMENTAL_AGGREGATE_COVERAGE \
      [llength $commit_sources] \
      [llength $supplemental_cells] \
      [llength $supplemental_d] \
      CELLS_ALL_TIMING_ENDPOINT_PINS \
      6.000 $actual $slack PASS $query_elapsed \
      [prop $path STARTPOINT_PIN] [prop $path ENDPOINT_PIN] \
      [prop $path STARTPOINT_CLOCK] [prop $path ENDPOINT_CLOCK] \
      [prop $path LOGIC_LEVELS] [prop $path EXCEPTION]]
  set quoted [list]
  foreach field $fields { lappend quoted [csv_field $field] }
  set header "Coverage_Record,Source_Count,Destination_Cell_Count,Destination_D_Pin_Inventory_Count,Target_Scope,Required_ns,Worst_Actual_ns,Slack_ns,Result,Runtime_s,Startpoint_Pin,Endpoint_Pin,Startpoint_Clock,Endpoint_Clock,Logic_Levels,Exception"
  write_text [file join $output_dir G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv] \
      "$header\n[join $quoted ,]\n"
  write_path_properties $path [file join $output_dir G2B_G13A_SUPPLEMENTAL_AGGREGATE_PATH_PROPERTIES.txt]
}

proc run_g13a {} {
  global argc argv
  if {$argc != 9} {
    error "usage: worker DCP PRIMARY_BASE FULL_BASE_MINUS_G13 BS3_CANDIDATE G13_CANDIDATE REFERENCE_OBJECTS OUTPUT_DIR EXPECTED_DCP_SHA EXPECTED_DERIVED_BASE_SHA"
  }
  lassign $argv checkpoint primary_base full_base_minus_g13 bs3_candidate g13_candidate \
      reference_objects output_dir expected_dcp_sha expected_derived_base_sha

  file mkdir $output_dir
  set worker_start [clock milliseconds]
  write_text [file join $output_dir WORKER_STARTED.marker] \
      "EPOCH_MILLISECONDS=$worker_start\nFULL_GROUP13_BUS_SKEW_RETRIED=NO\nHARDWARE_ACCESSED=NO\n"
  write_text [file join $output_dir G2B_G13A_VIVADO_VERSION.txt] \
      "SHORT=[version -short]\nFULL=[version]\n"

  open_checkpoint $checkpoint
  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} {
    error "sealed routed DCP part mismatch: $part"
  }
  report_route_status -file [file join $output_dir G2B_G13A_ROUTE_STATUS.rpt]
  set design_name [get_property NAME [current_design]]
  write_text [file join $output_dir G2B_G13A_ROUTE_SIGNATURE.txt] \
      "DESIGN=$design_name\nPART=$part\nDCP_EXPECTED_SHA256=$expected_dcp_sha\nIS_ROUTE_DESIGN=[prop [current_design] IS_ROUTE_DESIGN]\nROUTE_STATUS=[prop [current_design] ROUTE_STATUS]\n"

  # Primary A/B use the predecessor's accepted bus-skew-free context.
  reset_timing -invalid
  read_xdc $primary_base
  read_xdc $bs3_candidate

  set all_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*}] {IS_SEQUENTIAL == 1}]
  set abandoned_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] {IS_SEQUENTIAL == 1}]
  set commit_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/reset_commit_phase_hold_source_reg.*}] {IS_SEQUENTIAL == 1}]
  set all_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}] {IS_SEQUENTIAL == 1}]
  set abandoned_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/records_abandoned_axi_reg.*}] {IS_SEQUENTIAL == 1}]
  require_count "Group-13 all sources" $all_src 7
  require_count "Group-13 abandoned sources" $abandoned_src 3
  require_count "Group-13 commit-phase sources" $commit_src 4
  require_count "Group-13 all destinations" $all_dst 207
  require_count "Group-13 abandoned destinations" $abandoned_dst 32
  require_reference_identity $all_src $all_dst $reference_objects
  write_object_inventory $output_dir $all_src $abandoned_src $commit_src $all_dst $abandoned_dst

  set source_clocks [clocks_for_cells $all_src]
  set destination_clocks [clocks_for_cells $all_dst]
  write_text [file join $output_dir G2B_G13A_SCOPE_SUMMARY.txt] \
      "SOURCE_COUNT=7\nDESTINATION_COUNT=207\nABANDONED_SOURCE_COUNT=3\nCOMMIT_PHASE_SOURCE_COUNT=4\nABANDONED_DESTINATION_COUNT=32\nSOURCE_CLOCKS=[join $source_clocks ,]\nDESTINATION_CLOCKS=[join $destination_clocks ,]\nPRIMARY_CONTEXT=PREDECESSOR_BUS_SKEW_FREE\n"

  set report_command "report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <all 7 Group-13 sources> -to <all 207 Group-13 destination cells>"
  set report_start [begin_query $output_dir PRIMARY_REPORT_TIMING $report_command]
  set report_path [file join $output_dir G2B_G13A_EXACT_SCOPE_REPORT_TIMING.rpt]
  report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $all_src -to $all_dst -file $report_path
  set report_elapsed [complete_query $output_dir PRIMARY_REPORT_TIMING $report_start PASS]
  set report_text [read_text $report_path]
  if {[regexp -nocase {no (timing )?paths? found} $report_text]} {
    error "primary report_timing returned no path"
  }
  write_text [file join $output_dir G2B_G13A_REPORT_TIMING_SUMMARY.txt] \
      "STATUS=PASS\nPATH_COUNT_RETURNED=1\nDELAY_TYPE=max\nSETUP_HOLD_CONTEXT=MAX_SETUP_ANALYSIS;HOLD_NOT_REQUESTED\nQUERY_RUNTIME_SECONDS=$report_elapsed\nCOMMAND=$report_command\n"

  set paths_command "get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 -from <all 7 Group-13 sources> -to <all 207 Group-13 destination cells>"
  set paths_start [begin_query $output_dir PRIMARY_GET_TIMING_PATHS $paths_command]
  set primary_paths [get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 \
      -from $all_src -to $all_dst]
  set paths_elapsed [complete_query $output_dir PRIMARY_GET_TIMING_PATHS $paths_start PASS]
  if {[llength $primary_paths] < 1 || [llength $primary_paths] > 64} {
    error "primary get_timing_paths returned invalid bounded count: [llength $primary_paths]"
  }
  write_primary_paths_csv $primary_paths [file join $output_dir G2B_G13A_PRIMARY_TIMING_PATHS.csv]
  set worst_path [lindex $primary_paths 0]
  write_path_properties $worst_path [file join $output_dir G2B_G13A_PRIMARY_WORST_PATH_PROPERTIES.txt]
  set startpoints [list]
  set endpoints [list]
  set start_clocks [list]
  set end_clocks [list]
  set max_datapath -1.0
  foreach path $primary_paths {
    lappend startpoints [prop $path STARTPOINT_PIN]
    lappend endpoints [prop $path ENDPOINT_PIN]
    lappend start_clocks [prop $path STARTPOINT_CLOCK]
    lappend end_clocks [prop $path ENDPOINT_CLOCK]
    set path_delay [prop $path DATAPATH_DELAY]
    if {[string is double -strict $path_delay] && $path_delay > $max_datapath} {
      set max_datapath $path_delay
    }
  }
  set startpoints [lsort -unique -dictionary $startpoints]
  set endpoints [lsort -unique -dictionary $endpoints]
  set start_clocks [lsort -unique -dictionary $start_clocks]
  set end_clocks [lsort -unique -dictionary $end_clocks]
  write_text [file join $output_dir G2B_G13A_GET_TIMING_PATHS_SUMMARY.txt] \
      "STATUS=PASS\nRETURNED_PATH_COUNT=[llength $primary_paths]\nMAX_PATHS_BOUND=64\nNWORST_BOUND=7\nSOURCE_DIVERSITY=[llength $startpoints]\nDESTINATION_DIVERSITY=[llength $endpoints]\nSTARTPOINT_CLOCKS=[join $start_clocks ,]\nENDPOINT_CLOCKS=[join $end_clocks ,]\nWORST_SLACK_NS=[prop $worst_path SLACK]\nWORST_PATH_DATAPATH_DELAY_NS=[prop $worst_path DATAPATH_DELAY]\nMAX_RETURNED_DATAPATH_DELAY_NS=$max_datapath\nWORST_PATH_REQUIREMENT_NS=[prop $worst_path REQUIREMENT]\nWORST_STARTPOINT_PIN=[prop $worst_path STARTPOINT_PIN]\nWORST_ENDPOINT_PIN=[prop $worst_path ENDPOINT_PIN]\nWORST_LOGIC_LEVELS=[prop $worst_path LOGIC_LEVELS]\nWORST_EXCEPTION=[prop $worst_path EXCEPTION]\nQUERY_RUNTIME_SECONDS=$paths_elapsed\nCOMMAND=$paths_command\n"

  # Re-open the governed full timing context in memory, removing only Group 13,
  # then add the already-promoted Group-9 replacement and this audit candidate.
  reset_timing -invalid
  read_xdc $full_base_minus_g13
  read_xdc $bs3_candidate
  read_xdc $g13_candidate
  if {[string toupper $expected_derived_base_sha] eq ""} {
    error "derived-base identity argument is empty"
  }
  write_xdc -exclude_physical -force [file join $output_dir G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc]

  set candidate_all_src [concat $g2b_g13a_abandoned_src $g2b_g13a_commit_phase_src]
  require_reference_identity $candidate_all_src $g2b_g13a_all_dst_cells $reference_objects

  # The unchanged aggregate source-mailbox max-delay relation is broader than
  # Group 13.  Prove containment and explicitly exercise aggregate-only sinks.
  set aggregate_src $_xlnx_shared_i7
  set aggregate_dst $_xlnx_shared_i8
  require_nonempty "unchanged aggregate source collection" $aggregate_src
  require_nonempty "unchanged aggregate destination collection" $aggregate_dst
  require_subset "all seven Group-13 sources in aggregate source collection" $candidate_all_src $aggregate_src
  require_subset "all 207 Group-13 destinations in aggregate destination collection" $g2b_g13a_all_dst_cells $aggregate_dst
  set aggregate_dst_d [get_pins -quiet -of_objects $aggregate_dst -filter {REF_PIN_NAME == D}]
  require_subset "all 207 Group-13 D-pin inventory in aggregate destination D pins" $g2b_g13a_all_dst_d $aggregate_dst_d

  set supplemental_transport [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(transport_release_phase_hold_axi|transport_hard_hold_axi|transport_own_phase_hold_axi|transport_req_toggle_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
  set supplemental_commit_fifo [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(commit_fifo_head|commit_fifo_tail|commit_fifo_count)_reg.*}] {IS_SEQUENTIAL == 1}]
  set supplemental_shadow [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(shadow_last_global|shadow_last_channel|shadow_last_global_valid|shadow_last_channel_valid)_reg.*}] {IS_SEQUENTIAL == 1}]
  require_nonempty "supplemental follow-up transport targets" $supplemental_transport
  require_nonempty "supplemental commit-FIFO targets" $supplemental_commit_fifo
  require_nonempty "supplemental shadow last-state targets" $supplemental_shadow
  set supplemental_cells [concat $supplemental_transport $supplemental_commit_fifo $supplemental_shadow]
  require_subset "supplemental targets in aggregate destination collection" $supplemental_cells $aggregate_dst
  require_disjoint "supplemental aggregate-only targets versus original 207" $supplemental_cells $g2b_g13a_all_dst_cells
  set supplemental_inventory "CATEGORY,OBJECT_NAME\n"
  foreach object_name [names $supplemental_transport] {
    append supplemental_inventory "FOLLOWUP_TRANSPORT,[csv_field $object_name]\n"
  }
  foreach object_name [names $supplemental_commit_fifo] {
    append supplemental_inventory "COMMIT_FIFO,[csv_field $object_name]\n"
  }
  foreach object_name [names $supplemental_shadow] {
    append supplemental_inventory "SHADOW_LAST_STATE,[csv_field $object_name]\n"
  }
  write_text [file join $output_dir G2B_G13A_SUPPLEMENTAL_AGGREGATE_INVENTORY.csv] $supplemental_inventory
  write_text [file join $output_dir G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt] \
      "STATUS=PASS\nAGGREGATE_SOURCE_COUNT=[llength $aggregate_src]\nAGGREGATE_DESTINATION_COUNT=[llength $aggregate_dst]\nGROUP13_SOURCE_MEMBER_COUNT=[llength $candidate_all_src]\nGROUP13_DESTINATION_MEMBER_COUNT=[llength $g2b_g13a_all_dst_cells]\nFOLLOWUP_TRANSPORT_SUPPLEMENTAL_COUNT=[llength $supplemental_transport]\nCOMMIT_FIFO_SUPPLEMENTAL_COUNT=[llength $supplemental_commit_fifo]\nSHADOW_LAST_STATE_SUPPLEMENTAL_COUNT=[llength $supplemental_shadow]\nTOTAL_SUPPLEMENTAL_COUNT=[llength $supplemental_cells]\n"

  set abandoned_result [validate_candidate_family $output_dir RESET_ABANDONED_HOLD \
      $g2b_g13a_abandoned_src $g2b_g13a_abandoned_dst_cells $g2b_g13a_abandoned_dst_d 3 32]
  set commit_result [validate_candidate_family $output_dir RESET_COMMIT_PHASE_HOLD \
      $g2b_g13a_commit_phase_src $g2b_g13a_all_dst_cells $g2b_g13a_all_dst_d 4 207]
  validate_supplemental_aggregate $output_dir $g2b_g13a_commit_phase_src $supplemental_cells

  set csv_header "Family,Source_Count,Destination_Cell_Count,Destination_Pin_Count,Target_Scope,Required_ns,Worst_Actual_ns,Slack_ns,Result,Runtime_s,Startpoint_Pin,Endpoint_Pin,Startpoint_Clock,Endpoint_Clock,Logic_Levels,Exception"
  write_text [file join $output_dir .. .. G2B_G13A_CANDIDATE_RESULTS.csv] \
      "$csv_header\n[candidate_csv_row $abandoned_result]\n[candidate_csv_row $commit_result]\n"

  set methodology_command "report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}"
  set methodology_start [begin_query $output_dir FOCUSED_METHODOLOGY $methodology_command]
  set methodology_path [file join $output_dir G2B_G13A_FOCUSED_TIMING_METHODOLOGY.rpt]
  report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} \
      -file $methodology_path
  set methodology_elapsed [complete_query $output_dir FOCUSED_METHODOLOGY $methodology_start PASS]
  set methodology_text [read_text $methodology_path]
  set checks_found "UNPARSED"
  regexp {Checks found:\s+([0-9]+)} $methodology_text -> checks_found
  set g13_mentions [regexp -all -nocase {(reset_abandoned_hold_source|reset_commit_phase_hold_source|records_abandoned_axi)} $methodology_text]
  write_text [file join $output_dir G2B_G13A_FOCUSED_METHODOLOGY_SUMMARY.txt] \
      "STATUS=PASS\nCHECKS_FOUND=$checks_found\nGROUP13_OBJECT_MENTIONS=$g13_mentions\nQUERY_RUNTIME_SECONDS=$methodology_elapsed\nCOMMAND=$methodology_command\n"

  set worker_elapsed [seconds_since $worker_start]
  write_text [file join $output_dir WORKER_COMPLETED.marker] \
      "STATUS=PASS\nWORKER_RUNTIME_SECONDS=$worker_elapsed\nFULL_GROUP13_BUS_SKEW_RETRIED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"
  puts "G2B_G13A_COMPLETE runtime=${worker_elapsed}s"
}

if {[catch {run_g13a} failure options]} {
  puts stderr "G2B_G13A_FAILURE: $failure"
  puts stderr [dict get $options -errorinfo]
  exit 1
}
exit 0
