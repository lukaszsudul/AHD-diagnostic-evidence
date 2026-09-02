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

proc complete_query {output_dir query_id start_ms} {
  set elapsed [seconds_since $start_ms]
  write_text [file join $output_dir "QUERY_COMPLETED_${query_id}.marker"] \
      "QUERY_ID=$query_id\nQUERY_RUNTIME_SECONDS=$elapsed\nSTATUS=PASS\n"
  file delete -force [file join $output_dir ACTIVE_QUERY.marker]
  return $elapsed
}

proc require_count {label objects expected} {
  if {[llength $objects] != $expected} {
    error "$label count mismatch: expected $expected, got [llength $objects]"
  }
}

proc require_nonempty {label objects} {
  if {[llength $objects] == 0} { error "$label resolved empty" }
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

proc resolve_cell_name_list {label name_list} {
  set resolved [get_cells -quiet $name_list]
  if {[llength $resolved] != [llength $name_list]} {
    error "$label resolution shrank: literal [llength $name_list], resolved [llength $resolved]"
  }
  set literal_sorted [lsort -dictionary $name_list]
  set resolved_sorted [names $resolved]
  if {$literal_sorted ne $resolved_sorted} {
    error "$label resolved identity differs from literal list"
  }
  return $resolved
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
  if {[names $sources] ne $expected_sources} {
    error "Group-13 source identity differs from predecessor evidence"
  }
  if {[names $destinations] ne $expected_destinations} {
    error "Group-13 destination identity differs from predecessor evidence"
  }
}

proc write_path_properties {path output_path} {
  set lines [list]
  foreach property_name [lsort -dictionary [list_property $path]] {
    lappend lines "$property_name=[prop $path $property_name]"
  }
  write_text $output_path "[join $lines \n]\n"
}

proc validate_family {output_dir family sources destination_cells destination_d expected_sources expected_destinations} {
  require_count "$family sources" $sources $expected_sources
  require_count "$family destination cells" $destination_cells $expected_destinations
  require_count "$family destination D-pin inventory" $destination_d $expected_destinations
  set command_text "get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <$family sources> -to <$family destination cells; all endpoint pins>"
  set query_id "CANDIDATE_[string toupper $family]"
  set query_start [begin_query $output_dir $query_id $command_text]
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $sources -to $destination_cells]
  set elapsed [complete_query $output_dir $query_id $query_start]
  require_count "$family returned paths" $paths 1
  set path [lindex $paths 0]
  set actual [prop $path DATAPATH_DELAY]
  set requirement [prop $path REQUIREMENT]
  set slack [prop $path SLACK]
  if {![string is double -strict $actual] || $actual > 6.0005} {
    error "$family violates 6.000 ns datapath bound: $actual"
  }
  if {![string is double -strict $requirement] || abs($requirement - 6.000) > 0.0005} {
    error "$family requirement is not 6.000 ns: $requirement"
  }
  if {![string is double -strict $slack] || $slack < -0.0005} {
    error "$family slack is negative: $slack"
  }
  write_path_properties $path [file join $output_dir "G2B_G13A_${query_id}_PATH_PROPERTIES.txt"]
  return [dict create \
      FAMILY $family \
      SOURCE_COUNT [llength $sources] \
      DESTINATION_CELL_COUNT [llength $destination_cells] \
      DESTINATION_D_PIN_INVENTORY_COUNT [llength $destination_d] \
      TARGET_SCOPE CELLS_ALL_TIMING_ENDPOINT_PINS \
      REQUIRED_NS 6.000 \
      ACTUAL_NS $actual \
      SLACK_NS $slack \
      RESULT PASS \
      RUNTIME_SECONDS $elapsed \
      STARTPOINT_PIN [prop $path STARTPOINT_PIN] \
      ENDPOINT_PIN [prop $path ENDPOINT_PIN] \
      STARTPOINT_CLOCK [prop $path STARTPOINT_CLOCK] \
      ENDPOINT_CLOCK [prop $path ENDPOINT_CLOCK] \
      LOGIC_LEVELS [prop $path LOGIC_LEVELS] \
      EXCEPTION [prop $path EXCEPTION]]
}

proc family_csv_row {result} {
  set keys [list FAMILY SOURCE_COUNT DESTINATION_CELL_COUNT DESTINATION_D_PIN_INVENTORY_COUNT \
      TARGET_SCOPE REQUIRED_NS ACTUAL_NS SLACK_NS RESULT RUNTIME_SECONDS STARTPOINT_PIN \
      ENDPOINT_PIN STARTPOINT_CLOCK ENDPOINT_CLOCK LOGIC_LEVELS EXCEPTION]
  set fields [list]
  foreach key $keys { lappend fields [csv_field [dict get $result $key]] }
  return [join $fields ,]
}

proc validate_supplemental {output_dir commit_sources supplemental_cells} {
  set supplemental_d [get_pins -quiet -of_objects $supplemental_cells -filter {REF_PIN_NAME == D}]
  require_nonempty "supplemental D-pin inventory" $supplemental_d
  set command_text "get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <4 commit sources> -to <supplemental aggregate cells; all endpoint pins>"
  set query_start [begin_query $output_dir SUPPLEMENTAL_AGGREGATE_COVERAGE $command_text]
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $commit_sources -to $supplemental_cells]
  set elapsed [complete_query $output_dir SUPPLEMENTAL_AGGREGATE_COVERAGE $query_start]
  require_count "supplemental returned paths" $paths 1
  set path [lindex $paths 0]
  set actual [prop $path DATAPATH_DELAY]
  set requirement [prop $path REQUIREMENT]
  set slack [prop $path SLACK]
  if {![string is double -strict $actual] || $actual > 6.0005 ||
      ![string is double -strict $requirement] || abs($requirement - 6.000) > 0.0005 ||
      ![string is double -strict $slack] || $slack < -0.0005} {
    error "supplemental aggregate timing bound failed: actual=$actual requirement=$requirement slack=$slack"
  }
  set fields [list SUPPLEMENTAL_AGGREGATE_COVERAGE [llength $commit_sources] \
      [llength $supplemental_cells] [llength $supplemental_d] CELLS_ALL_TIMING_ENDPOINT_PINS \
      6.000 $actual $slack PASS $elapsed [prop $path STARTPOINT_PIN] [prop $path ENDPOINT_PIN] \
      [prop $path STARTPOINT_CLOCK] [prop $path ENDPOINT_CLOCK] [prop $path LOGIC_LEVELS] [prop $path EXCEPTION]]
  set quoted [list]
  foreach field $fields { lappend quoted [csv_field $field] }
  set header "Coverage_Record,Source_Count,Destination_Cell_Count,Destination_D_Pin_Inventory_Count,Target_Scope,Required_ns,Worst_Actual_ns,Slack_ns,Result,Runtime_s,Startpoint_Pin,Endpoint_Pin,Startpoint_Clock,Endpoint_Clock,Logic_Levels,Exception"
  write_text [file join $output_dir G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv] \
      "$header\n[join $quoted ,]\n"
  write_path_properties $path [file join $output_dir G2B_G13A_SUPPLEMENTAL_AGGREGATE_PATH_PROPERTIES.txt]
}

proc run_continuation {} {
  global argc argv
  if {$argc != 9} {
    error "usage: continuation DCP FULL_BASE BS3_CANDIDATE G13_CANDIDATE REFERENCE OUTPUT_DIR EVIDENCE_ROOT EXPECTED_DCP_SHA EXPECTED_BASE_SHA"
  }
  lassign $argv checkpoint full_base bs3_candidate g13_candidate reference_objects \
      output_dir evidence_root expected_dcp_sha expected_base_sha
  file mkdir $output_dir
  set worker_start [clock milliseconds]
  write_text [file join $output_dir WORKER_STARTED.marker] \
      "MODE=CANDIDATE_ONLY_CONTINUATION\nEPOCH_MILLISECONDS=$worker_start\nPRIMARY_A_B_REPEATED=NO\nFULL_GROUP13_BUS_SKEW_RETRIED=NO\n"
  write_text [file join $output_dir G2B_G13A_CONTINUATION_VIVADO_VERSION.txt] \
      "SHORT=[version -short]\nFULL=[version]\n"

  open_checkpoint $checkpoint
  if {[get_property PART [current_design]] ne "xc7a35tcsg325-2"} {
    error "sealed DCP part mismatch"
  }
  report_route_status -file [file join $output_dir G2B_G13A_CONTINUATION_ROUTE_STATUS.rpt]
  write_text [file join $output_dir G2B_G13A_CONTINUATION_ROUTE_SIGNATURE.txt] \
      "DESIGN=[get_property NAME [current_design]]\nPART=[get_property PART [current_design]]\nDCP_EXPECTED_SHA256=$expected_dcp_sha\n"
  reset_timing -invalid
  read_xdc $full_base
  read_xdc $bs3_candidate
  read_xdc $g13_candidate
  write_xdc -exclude_physical -force [file join $output_dir G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc]

  set all_sources [concat $g2b_g13a_abandoned_src $g2b_g13a_commit_phase_src]
  require_count "all Group-13 candidate sources" $all_sources 7
  require_count "all Group-13 candidate destinations" $g2b_g13a_all_dst_cells 207
  require_reference_identity $all_sources $g2b_g13a_all_dst_cells $reference_objects

  set aggregate_src_literal $_xlnx_shared_i7
  set aggregate_dst_literal [get_property NAME $_xlnx_shared_i8]
  set aggregate_src [resolve_cell_name_list "aggregate source list" $aggregate_src_literal]
  set aggregate_dst [resolve_cell_name_list "aggregate destination list" $aggregate_dst_literal]
  require_subset "all seven Group-13 sources in aggregate source collection" $all_sources $aggregate_src
  require_subset "all 207 Group-13 destinations in aggregate destination collection" $g2b_g13a_all_dst_cells $aggregate_dst
  set aggregate_dst_d [get_pins -quiet -of_objects $aggregate_dst -filter {REF_PIN_NAME == D}]
  require_subset "Group-13 D-pin inventory in aggregate D pins" $g2b_g13a_all_dst_d $aggregate_dst_d

  set supplemental_transport [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(transport_release_phase_hold_axi|transport_hard_hold_axi|transport_own_phase_hold_axi|transport_req_toggle_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
  set supplemental_commit_fifo [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(commit_fifo_head|commit_fifo_tail|commit_fifo_count)_reg.*}] {IS_SEQUENTIAL == 1}]
  set supplemental_shadow [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(shadow_last_global|shadow_last_channel|shadow_last_global_valid|shadow_last_channel_valid)_reg.*}] {IS_SEQUENTIAL == 1}]
  require_nonempty "supplemental transport cells" $supplemental_transport
  require_nonempty "supplemental commit-FIFO cells" $supplemental_commit_fifo
  require_nonempty "supplemental shadow cells" $supplemental_shadow
  set supplemental_cells [concat $supplemental_transport $supplemental_commit_fifo $supplemental_shadow]
  require_subset "supplemental cells in aggregate destinations" $supplemental_cells $aggregate_dst
  require_disjoint "supplemental cells versus original 207" $supplemental_cells $g2b_g13a_all_dst_cells

  set inventory "CATEGORY,OBJECT_NAME\n"
  foreach object_name [names $supplemental_transport] { append inventory "FOLLOWUP_TRANSPORT,[csv_field $object_name]\n" }
  foreach object_name [names $supplemental_commit_fifo] { append inventory "COMMIT_FIFO,[csv_field $object_name]\n" }
  foreach object_name [names $supplemental_shadow] { append inventory "SHADOW_LAST_STATE,[csv_field $object_name]\n" }
  write_text [file join $output_dir G2B_G13A_SUPPLEMENTAL_AGGREGATE_INVENTORY.csv] $inventory
  write_text [file join $output_dir G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt] \
      "STATUS=PASS\nAGGREGATE_SOURCE_LITERAL_COUNT=[llength $aggregate_src_literal]\nAGGREGATE_SOURCE_RESOLVED_COUNT=[llength $aggregate_src]\nAGGREGATE_DESTINATION_LITERAL_COUNT=[llength $aggregate_dst_literal]\nAGGREGATE_DESTINATION_RESOLVED_COUNT=[llength $aggregate_dst]\nGROUP13_SOURCE_MEMBER_COUNT=7\nGROUP13_DESTINATION_MEMBER_COUNT=207\nFOLLOWUP_TRANSPORT_SUPPLEMENTAL_COUNT=[llength $supplemental_transport]\nCOMMIT_FIFO_SUPPLEMENTAL_COUNT=[llength $supplemental_commit_fifo]\nSHADOW_LAST_STATE_SUPPLEMENTAL_COUNT=[llength $supplemental_shadow]\nTOTAL_SUPPLEMENTAL_COUNT=[llength $supplemental_cells]\n"

  set abandoned_result [validate_family $output_dir RESET_ABANDONED_HOLD \
      $g2b_g13a_abandoned_src $g2b_g13a_abandoned_dst_cells $g2b_g13a_abandoned_dst_d 3 32]
  set commit_result [validate_family $output_dir RESET_COMMIT_PHASE_HOLD \
      $g2b_g13a_commit_phase_src $g2b_g13a_all_dst_cells $g2b_g13a_all_dst_d 4 207]
  validate_supplemental $output_dir $g2b_g13a_commit_phase_src $supplemental_cells

  set family_header "Family,Source_Count,Destination_Cell_Count,Destination_D_Pin_Inventory_Count,Target_Scope,Required_ns,Worst_Actual_ns,Slack_ns,Result,Runtime_s,Startpoint_Pin,Endpoint_Pin,Startpoint_Clock,Endpoint_Clock,Logic_Levels,Exception"
  write_text [file join $evidence_root G2B_G13A_CANDIDATE_RESULTS.csv] \
      "$family_header\n[family_csv_row $abandoned_result]\n[family_csv_row $commit_result]\n"

  set methodology_command "report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}"
  set methodology_start [begin_query $output_dir FOCUSED_METHODOLOGY $methodology_command]
  set methodology_path [file join $output_dir G2B_G13A_FOCUSED_TIMING_METHODOLOGY.rpt]
  report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} -file $methodology_path
  set methodology_elapsed [complete_query $output_dir FOCUSED_METHODOLOGY $methodology_start]
  set methodology_text [read_text $methodology_path]
  set checks_found UNPARSED
  regexp {Checks found:\s+([0-9]+)} $methodology_text -> checks_found
  set g13_mentions [regexp -all -nocase {(reset_abandoned_hold_source|reset_commit_phase_hold_source|records_abandoned_axi)} $methodology_text]
  write_text [file join $output_dir G2B_G13A_FOCUSED_METHODOLOGY_SUMMARY.txt] \
      "STATUS=PASS\nCHECKS_FOUND=$checks_found\nGROUP13_OBJECT_MENTIONS=$g13_mentions\nQUERY_RUNTIME_SECONDS=$methodology_elapsed\n"

  write_text [file join $output_dir WORKER_COMPLETED.marker] \
      "STATUS=PASS\nMODE=CANDIDATE_ONLY_CONTINUATION\nWORKER_RUNTIME_SECONDS=[seconds_since $worker_start]\nPRIMARY_A_B_REPEATED=NO\nFULL_GROUP13_BUS_SKEW_RETRIED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\nDCP_EXPECTED_SHA256=$expected_dcp_sha\nBASE_EXPECTED_SHA256=$expected_base_sha\n"
  puts "G2B_G13A_CANDIDATE_CONTINUATION_PASS"
}

if {[catch {run_continuation} failure options]} {
  puts stderr "G2B_G13A_CONTINUATION_FAILURE: $failure"
  puts stderr [dict get $options -errorinfo]
  exit 1
}
exit 0
