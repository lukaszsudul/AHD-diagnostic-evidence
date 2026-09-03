# AHD v41 G2B-G14-A routed, read-only timing-method audit worker.
# It never calls report_bus_skew and never writes a checkpoint or bitstream.

set EXPECTED_DCP_SHA256 EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83
set EXPECTED_BASE_SHA256 5B285774E2CBCAD66D6C1A777761EE066D57811C648E8C2A909F8AC4DF29FF3B
set EXPECTED_BS3_SHA256 AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087
set EXPECTED_G13_SHA256 E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312
set EXPECTED_G14A_SHA256 094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A

proc write_text {path value} {
  file mkdir [file dirname $path]
  set handle [open $path w]
  fconfigure $handle -translation lf -encoding utf-8
  puts -nonewline $handle $value
  close $handle
}

proc read_text {path} {
  set handle [open $path r]
  fconfigure $handle -translation auto -encoding utf-8
  set value [read $handle]
  close $handle
  return $value
}

proc seconds_since {start_ms} {
  return [format %.3f [expr {double([clock milliseconds] - $start_ms) / 1000.0}]]
}

proc prop {object property_name} {
  if {[catch {get_property $property_name $object} value] || $value eq ""} {
    return N/A
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

proc sha256_file {path} {
  if {![file isfile $path]} { error "missing file for SHA-256: $path" }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "could not parse SHA-256 for $path"
}

proc require_hash {label path expected} {
  set actual [sha256_file $path]
  if {$actual ne $expected} { error "$label SHA-256 mismatch: $actual" }
}

proc require_count {label objects expected} {
  set actual [llength $objects]
  if {$actual != $expected} { error "$label count mismatch: expected $expected got $actual" }
}

proc require_subset {label subset superset} {
  set superset_names [names $superset]
  foreach object_name [names $subset] {
    if {[lsearch -exact $superset_names $object_name] < 0} {
      error "$label missing $object_name"
    }
  }
}

proc begin_query {output_dir query_id command_text} {
  set epoch [clock milliseconds]
  write_text [file join $output_dir ACTIVE_QUERY.marker] \
      "QUERY_ID=$query_id\nEPOCH_MILLISECONDS=$epoch\nTIMEOUT_SECONDS=300\nCOMMAND=$command_text\n"
  write_text [file join $output_dir "QUERY_STARTED_${query_id}.marker"] \
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
    error "Group-14 source identity differs from recovery-2 evidence"
  }
  if {[names $destinations] ne $expected_destinations} {
    error "Group-14 destination identity differs from recovery-2 evidence"
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

proc write_path_properties {path output_path} {
  set lines [list]
  foreach property_name [lsort -dictionary [list_property $path]] {
    lappend lines "$property_name=[prop $path $property_name]"
  }
  write_text $output_path "[join $lines \n]\n"
}

proc write_paths_csv {paths output_path} {
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

proc write_object_inventory {output_dir generation_src epoch_src current_dst state_dst fault_dst reset_dst} {
  set all_sources [concat $generation_src $epoch_src]
  set source_clocks [join [clocks_for_cells $all_sources] ";"]
  set destination_clocks [join [clocks_for_cells $current_dst] ";"]
  set state_names [names $state_dst]
  set fault_names [names $fault_dst]
  set lines [list "ROLE,FAMILY,OBJECT_NAME,CLOCKS,SEMANTIC_SCOPE"]
  foreach object_name [names $generation_src] {
    lappend lines "SOURCE,RELEASE_SLOT0_GENERATION_MATCH,[csv_field $object_name],[csv_field $source_clocks],YES"
  }
  foreach object_name [names $epoch_src] {
    lappend lines "SOURCE,RELEASE_SLOT0_EPOCH_MATCH,[csv_field $object_name],[csv_field $source_clocks],YES"
  }
  foreach object_name [names $current_dst] {
    set family CURRENT_GROUP14_IRRELEVANT_ENDPOINT
    set included NO
    if {[lsearch -exact $state_names $object_name] >= 0} {
      set family RELEASE_SLOT0_NORMAL_STATE_TRANSITION
      set included YES
    } elseif {[lsearch -exact $fault_names $object_name] >= 0} {
      set family RELEASE_SLOT0_MISMATCH_CONTAINMENT
      set included YES
    }
    lappend lines "DESTINATION,$family,[csv_field $object_name],[csv_field $destination_clocks],$included"
  }
  foreach object_name [names $reset_dst] {
    lappend lines "DESTINATION,RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING,[csv_field $object_name],[csv_field $destination_clocks],YES"
  }
  write_text [file join $output_dir G2B_G14A_OBJECT_INVENTORY.csv] "[join $lines \n]\n"
}

proc summarize_primary_paths {paths output_dir elapsed command_text} {
  if {[llength $paths] < 1 || [llength $paths] > 64} {
    error "primary get_timing_paths returned invalid bounded count: [llength $paths]"
  }
  set worst_path [lindex $paths 0]
  set startpoints [list]
  set endpoints [list]
  set start_clocks [list]
  set end_clocks [list]
  set logic_levels [list]
  set exceptions [list]
  set max_datapath -1.0
  foreach path $paths {
    lappend startpoints [prop $path STARTPOINT_PIN]
    lappend endpoints [prop $path ENDPOINT_PIN]
    lappend start_clocks [prop $path STARTPOINT_CLOCK]
    lappend end_clocks [prop $path ENDPOINT_CLOCK]
    lappend logic_levels [prop $path LOGIC_LEVELS]
    lappend exceptions [prop $path EXCEPTION]
    set path_delay [prop $path DATAPATH_DELAY]
    if {[string is double -strict $path_delay] && $path_delay > $max_datapath} {
      set max_datapath $path_delay
    }
  }
  set startpoints [lsort -unique -dictionary $startpoints]
  set endpoints [lsort -unique -dictionary $endpoints]
  set start_clocks [lsort -unique -dictionary $start_clocks]
  set end_clocks [lsort -unique -dictionary $end_clocks]
  set logic_levels [lsort -unique -integer $logic_levels]
  set exceptions [lsort -unique -dictionary $exceptions]
  write_paths_csv $paths [file join $output_dir G2B_G14A_PRIMARY_TIMING_PATHS.csv]
  write_path_properties $worst_path [file join $output_dir G2B_G14A_PRIMARY_WORST_PATH_PROPERTIES.txt]
  write_text [file join $output_dir G2B_G14A_GET_TIMING_PATHS_SUMMARY.txt] \
      "STATUS=PASS\nRETURNED_PATH_COUNT=[llength $paths]\nMAX_PATHS_BOUND=64\nNWORST_BOUND=7\nSOURCE_DIVERSITY=[llength $startpoints]\nDESTINATION_DIVERSITY=[llength $endpoints]\nSTARTPOINTS=[join $startpoints ;]\nENDPOINTS=[join $endpoints ;]\nSTARTPOINT_CLOCKS=[join $start_clocks ,]\nENDPOINT_CLOCKS=[join $end_clocks ,]\nLOGIC_LEVELS_PRESENT=[join $logic_levels ,]\nEXCEPTIONS_PRESENT=[join $exceptions ;]\nWORST_SLACK_NS=[prop $worst_path SLACK]\nWORST_PATH_DATAPATH_DELAY_NS=[prop $worst_path DATAPATH_DELAY]\nMAX_RETURNED_DATAPATH_DELAY_NS=$max_datapath\nWORST_PATH_REQUIREMENT_NS=[prop $worst_path REQUIREMENT]\nWORST_STARTPOINT_PIN=[prop $worst_path STARTPOINT_PIN]\nWORST_ENDPOINT_PIN=[prop $worst_path ENDPOINT_PIN]\nWORST_LOGIC_LEVELS=[prop $worst_path LOGIC_LEVELS]\nWORST_EXCEPTION=[prop $worst_path EXCEPTION]\nQUERY_RUNTIME_SECONDS=$elapsed\nCOMMAND=$command_text\n"
}

proc validate_family {output_dir family sources destination_cells expected_sources expected_destinations} {
  require_count "$family sources" $sources $expected_sources
  require_count "$family destination cells" $destination_cells $expected_destinations
  set destination_d [get_pins -quiet -of_objects $destination_cells -filter {REF_PIN_NAME == D}]
  require_count "$family destination D pins" $destination_d $expected_destinations
  set command_text "get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <$family sources> -to <$family destination cells>"
  set query_id "CANDIDATE_[string toupper $family]"
  set start_ms [begin_query $output_dir $query_id $command_text]
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $sources -to $destination_cells]
  set elapsed [complete_query $output_dir $query_id $start_ms PASS]
  require_count "$family candidate timing paths" $paths 1
  set path [lindex $paths 0]
  set actual [prop $path DATAPATH_DELAY]
  set requirement [prop $path REQUIREMENT]
  set slack [prop $path SLACK]
  if {![string is double -strict $actual] || $actual > 6.0005} {
    error "$family datapath delay violates 6.000 ns: $actual"
  }
  if {![string is double -strict $requirement] || abs($requirement - 6.000) > 0.0005} {
    error "$family path requirement is not 6.000 ns: $requirement"
  }
  if {![string is double -strict $slack] || $slack < -0.0005} {
    error "$family path slack is negative: $slack"
  }
  write_path_properties $path [file join $output_dir "G2B_G14A_${query_id}_PATH_PROPERTIES.txt"]
  return [dict create FAMILY $family CONSTRAINT_TYPE MAX_DELAY_DATAPATH_ONLY \
      SOURCE_COUNT [llength $sources] DESTINATION_COUNT [llength $destination_cells] \
      REQUIRED_NS 6.000 ACTUAL_NS $actual SLACK_NS $slack RESULT PASS \
      RUNTIME_SECONDS $elapsed STARTPOINT_PIN [prop $path STARTPOINT_PIN] \
      ENDPOINT_PIN [prop $path ENDPOINT_PIN] STARTPOINT_CLOCK [prop $path STARTPOINT_CLOCK] \
      ENDPOINT_CLOCK [prop $path ENDPOINT_CLOCK] LOGIC_LEVELS [prop $path LOGIC_LEVELS] \
      EXCEPTION [prop $path EXCEPTION]]
}

proc candidate_csv_row {result} {
  set keys [list FAMILY CONSTRAINT_TYPE SOURCE_COUNT DESTINATION_COUNT REQUIRED_NS ACTUAL_NS \
      SLACK_NS RESULT RUNTIME_SECONDS STARTPOINT_PIN ENDPOINT_PIN STARTPOINT_CLOCK \
      ENDPOINT_CLOCK LOGIC_LEVELS EXCEPTION]
  set fields [list]
  foreach key $keys { lappend fields [csv_field [dict get $result $key]] }
  return [join $fields ,]
}

proc run_g14a {} {
  global argc argv
  global EXPECTED_DCP_SHA256 EXPECTED_BASE_SHA256 EXPECTED_BS3_SHA256 EXPECTED_G13_SHA256 EXPECTED_G14A_SHA256
  if {$argc != 7} {
    error "usage: worker DCP BASE_WITHOUT_BUS_SKEW BS3_CANDIDATE G13_CANDIDATE G14A_CANDIDATE REFERENCE_OBJECTS OUTPUT_DIR"
  }
  lassign $argv checkpoint base_xdc bs3_candidate g13_candidate g14a_candidate reference_objects output_dir
  foreach required [list $checkpoint $base_xdc $bs3_candidate $g13_candidate $g14a_candidate $reference_objects] {
    if {![file isfile $required]} { error "required input missing: $required" }
  }
  require_hash DCP $checkpoint $EXPECTED_DCP_SHA256
  require_hash BASE $base_xdc $EXPECTED_BASE_SHA256
  require_hash BS3 $bs3_candidate $EXPECTED_BS3_SHA256
  require_hash G13 $g13_candidate $EXPECTED_G13_SHA256
  require_hash G14A $g14a_candidate $EXPECTED_G14A_SHA256
  if {![info exists ::env(XILINX_LOCAL_USER_DATA)] || $::env(XILINX_LOCAL_USER_DATA) ne "NO"} {
    error "XILINX_LOCAL_USER_DATA must be NO"
  }
  file mkdir $output_dir
  set worker_start [clock milliseconds]
  write_text [file join $output_dir WORKER_STARTED.marker] \
      "EPOCH_MILLISECONDS=$worker_start\nFULL_GROUP14_REPORT_BUS_SKEW_RETRIED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"
  write_text [file join $output_dir G2B_G14A_VIVADO_VERSION.txt] \
      "SHORT=[version -short]\nFULL=[version]\n"

  open_checkpoint $checkpoint
  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} { error "sealed routed DCP part mismatch: $part" }
  set routed_fully [report_route_status -boolean_check ROUTED_FULLY]
  set route_errors [report_route_status -boolean_check ERRORS_IN_ROUTES]
  if {!$routed_fully || $route_errors} { error "sealed DCP is not fully routed" }
  write_text [file join $output_dir G2B_G14A_ROUTE_SIGNATURE.txt] \
      "PART=$part\nROUTED_FULLY=$routed_fully\nERRORS_IN_ROUTES=$route_errors\nDCP_SHA256=$EXPECTED_DCP_SHA256\n"

  # Recovery-2-equivalent promoted context with every bus-skew command removed.
  reset_timing -invalid
  read_xdc $base_xdc
  read_xdc $bs3_candidate
  read_xdc $g13_candidate

  set generation_src [filter [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_generation_axi_reg\[0\].*}] {IS_SEQUENTIAL == 1}]
  set epoch_src [filter [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[0\].*}] {IS_SEQUENTIAL == 1}]
  set all_src [concat $generation_src $epoch_src]
  set current_dst [filter [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
      {IS_SEQUENTIAL == 1}]
  set state_dst [filter [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/slot_state_source_reg\[0\].*}] \
      {IS_SEQUENTIAL == 1}]
  set fault_dst [filter [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
      {IS_SEQUENTIAL == 1}]
  set reset_dst [filter [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
      {IS_SEQUENTIAL == 1}]
  set semantic_dst [concat $state_dst $fault_dst $reset_dst]
  require_count "Group-14 generation sources" $generation_src 24
  require_count "Group-14 epoch sources" $epoch_src 32
  require_count "Group-14 all sources" $all_src 56
  require_count "Group-14 current destinations" $current_dst 20
  require_count "Group-14 normal-state destinations" $state_dst 3
  require_count "Group-14 mismatch-containment destinations" $fault_dst 4
  require_count "Group-14 reset-overlap destinations" $reset_dst 3
  require_count "Group-14 complete semantic destinations" $semantic_dst 10
  require_reference_identity $all_src $current_dst $reference_objects
  require_subset "normal-state destinations in current Group-14 destinations" $state_dst $current_dst
  require_subset "mismatch-containment destinations in current Group-14 destinations" $fault_dst $current_dst
  if {![info exists _xlnx_shared_i4] || ![info exists _xlnx_shared_i5]} {
    error "retained aggregate AXI-to-source mailbox collections are absent"
  }
  require_subset "Group-14 payload in retained aggregate sources" $all_src $_xlnx_shared_i4
  require_subset "complete semantic destinations in retained aggregate destinations" $semantic_dst $_xlnx_shared_i5
  write_object_inventory $output_dir $generation_src $epoch_src $current_dst $state_dst $fault_dst $reset_dst
  write_text [file join $output_dir G2B_G14A_SCOPE_SUMMARY.txt] \
      "SOURCE_COUNT=56\nGENERATION_SOURCE_COUNT=24\nEPOCH_SOURCE_COUNT=32\nDESTINATION_COUNT=20\nNORMAL_STATE_DESTINATION_COUNT=3\nMISMATCH_CONTAINMENT_DESTINATION_COUNT=4\nRESET_OVERLAP_DESTINATION_COUNT=3\nCOMPLETE_SEMANTIC_DESTINATION_COUNT=10\nSOURCE_CLOCKS=[join [clocks_for_cells $all_src] ,]\nDESTINATION_CLOCKS=[join [clocks_for_cells $current_dst] ,]\nFULL_GROUP14_REPORT_BUS_SKEW_RETRIED=NO\n"

  # Required order: the capped get_timing_paths query precedes report_timing.
  set paths_command "get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 -from <all 56 Group-14 sources> -to <all 20 Group-14 destinations>"
  set paths_start [begin_query $output_dir PRIMARY_GET_TIMING_PATHS $paths_command]
  set primary_paths [get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 \
      -from $all_src -to $current_dst]
  set paths_elapsed [complete_query $output_dir PRIMARY_GET_TIMING_PATHS $paths_start PASS]
  summarize_primary_paths $primary_paths $output_dir $paths_elapsed $paths_command

  set report_command "report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <all 56 Group-14 sources> -to <all 20 Group-14 destinations>"
  set report_start [begin_query $output_dir PRIMARY_REPORT_TIMING $report_command]
  set report_path [file join $output_dir G2B_G14A_EXACT_SCOPE_REPORT_TIMING.rpt]
  report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 \
      -from $all_src -to $current_dst -file $report_path
  set report_elapsed [complete_query $output_dir PRIMARY_REPORT_TIMING $report_start PASS]
  set report_text [read_text $report_path]
  if {[regexp -nocase {no (timing )?paths? found} $report_text]} { error "report_timing returned no path" }
  set primary_worst [lindex $primary_paths 0]
  write_text [file join $output_dir G2B_G14A_REPORT_TIMING_SUMMARY.txt] \
      "STATUS=PASS\nPATH_COUNT_RETURNED=1\nWORST_STARTPOINT_PIN=[prop $primary_worst STARTPOINT_PIN]\nWORST_ENDPOINT_PIN=[prop $primary_worst ENDPOINT_PIN]\nWORST_DATAPATH_DELAY_NS=[prop $primary_worst DATAPATH_DELAY]\nWORST_REQUIREMENT_NS=[prop $primary_worst REQUIREMENT]\nWORST_SLACK_NS=[prop $primary_worst SLACK]\nSTARTPOINT_CLOCK=[prop $primary_worst STARTPOINT_CLOCK]\nENDPOINT_CLOCK=[prop $primary_worst ENDPOINT_CLOCK]\nLOGIC_LEVELS=[prop $primary_worst LOGIC_LEVELS]\nEXCEPTION=[prop $primary_worst EXCEPTION]\nQUERY_RUNTIME_SECONDS=$report_elapsed\nCOMMAND=$report_command\n"

  # Apply only the temporary Group-14 candidate in memory.
  read_xdc $g14a_candidate
  require_count "candidate generation sources" $g2b_g14a_release_generation_src 24
  require_count "candidate epoch sources" $g2b_g14a_release_epoch_src 32
  require_count "candidate payload sources" $g2b_g14a_release_payload_src 56
  require_count "candidate normal-state destinations" $g2b_g14a_release_state_dst_cells 3
  require_count "candidate mismatch-containment destinations" $g2b_g14a_release_fault_dst_cells 4
  require_count "candidate reset-overlap destinations" $g2b_g14a_release_reset_dst_cells 3
  if {[names $g2b_g14a_release_generation_src] ne [names $generation_src] || \
      [names $g2b_g14a_release_epoch_src] ne [names $epoch_src] || \
      [names $g2b_g14a_release_state_dst_cells] ne [names $state_dst] || \
      [names $g2b_g14a_release_fault_dst_cells] ne [names $fault_dst] || \
      [names $g2b_g14a_release_reset_dst_cells] ne [names $reset_dst]} {
    error "candidate collection identity differs from independently reconstructed scope"
  }
  write_xdc -exclude_physical -force [file join $output_dir G2B_G14A_APPLIED_CANDIDATE_CONTEXT.xdc]

  set state_result [validate_family $output_dir RELEASE_SLOT0_NORMAL_STATE_TRANSITION \
      $all_src $g2b_g14a_release_state_dst_cells 56 3]
  set fault_result [validate_family $output_dir RELEASE_SLOT0_MISMATCH_CONTAINMENT \
      $all_src $g2b_g14a_release_fault_dst_cells 56 4]
  set reset_result [validate_family $output_dir RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING \
      $all_src $g2b_g14a_release_reset_dst_cells 56 3]
  set header "Family,Constraint_Type,Source_Count,Destination_Count,Required_ns,Worst_Actual_ns,Slack_ns,Result,Runtime_s,Startpoint_Pin,Endpoint_Pin,Startpoint_Clock,Endpoint_Clock,Logic_Levels,Exception"
  write_text [file join $output_dir G2B_G14A_CANDIDATE_RESULTS.csv] \
      "$header\n[candidate_csv_row $state_result]\n[candidate_csv_row $fault_result]\n[candidate_csv_row $reset_result]\n"

  set methodology_command "report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}"
  set methodology_start [begin_query $output_dir FOCUSED_METHODOLOGY $methodology_command]
  set methodology_path [file join $output_dir G2B_G14A_FOCUSED_TIMING_METHODOLOGY.rpt]
  report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} -file $methodology_path
  set methodology_elapsed [complete_query $output_dir FOCUSED_METHODOLOGY $methodology_start PASS]
  set methodology_text [read_text $methodology_path]
  set checks_found UNPARSED
  regexp {Checks found:\s+([0-9]+)} $methodology_text -> checks_found
  set group14_mentions [regexp -all -nocase {(release_generation_axi|release_epoch_axi|release_sync1_source|release_sync2_source)} $methodology_text]
  write_text [file join $output_dir G2B_G14A_FOCUSED_METHODOLOGY_SUMMARY.txt] \
      "STATUS=PASS\nCHECKS_FOUND=$checks_found\nGROUP14_OBJECT_MENTIONS=$group14_mentions\nQUERY_RUNTIME_SECONDS=$methodology_elapsed\nCOMMAND=$methodology_command\n"

  set worker_elapsed [seconds_since $worker_start]
  write_text [file join $output_dir WORKER_COMPLETED.marker] \
      "STATUS=PASS\nWORKER_RUNTIME_SECONDS=$worker_elapsed\nFULL_GROUP14_REPORT_BUS_SKEW_RETRIED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"
  puts "G2B_G14A_COMPLETE runtime=${worker_elapsed}s"
}

if {[catch {run_g14a} failure options]} {
  puts stderr "G2B_G14A_FAILURE: $failure"
  puts stderr [dict get $options -errorinfo]
  if {$argc >= 7} {
    set failure_output [lindex $argv 6]
    catch {write_text [file join $failure_output WORKER_FAILED.marker] \
        "STATUS=FAIL\nERROR=$failure\nFULL_GROUP14_REPORT_BUS_SKEW_RETRIED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"}
  }
  exit 1
}
exit 0
