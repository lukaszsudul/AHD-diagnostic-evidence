proc utc_from_milliseconds {milliseconds} {
  set seconds [expr {$milliseconds / 1000}]
  set fraction [format %03d [expr {$milliseconds % 1000}]]
  return "[clock format $seconds -gmt true -format {%Y-%m-%dT%H:%M:%S}].${fraction}Z"
}

proc utc_now {} {
  return [utc_from_milliseconds [clock milliseconds]]
}

proc seconds_from_ms {milliseconds} {
  return [format %.3f [expr {double($milliseconds) / 1000.0}]]
}

proc write_text {path text} {
  set temporary_path "${path}.tmp.[pid].[clock clicks]"
  set handle [open $temporary_path w]
  fconfigure $handle -translation lf -encoding utf-8
  puts -nonewline $handle $text
  close $handle
  file rename -force $temporary_path $path
}

proc append_text {path text} {
  set handle [open $path a]
  fconfigure $handle -translation lf -encoding utf-8
  puts -nonewline $handle $text
  close $handle
}

proc read_exact_name_list {path} {
  set handle [open $path r]
  fconfigure $handle -translation auto -encoding utf-8
  set text [read $handle]
  close $handle
  set normalized [string map [list "\r" ""] [string trim $text]]
  if {$normalized eq ""} { return [list] }
  return [split $normalized "\n"]
}

proc resolve_cells_exact {names label} {
  set resolved [list]
  foreach name $names {
    set object [get_cells -quiet [list $name]]
    if {[llength $object] != 1} {
      error "$label object did not resolve exactly once: $name count=[llength $object]"
    }
    lappend resolved $object
  }
  return $resolved
}

proc mark_phase {output_dir label t0_ms detail} {
  set now_ms [clock milliseconds]
  set timestamp [utc_from_milliseconds $now_ms]
  set elapsed [seconds_from_ms [expr {$now_ms - $t0_ms}]]
  write_text [file join $output_dir "${label}.marker"] "MARKER=${label}\nTIMESTAMP=${timestamp}\nEPOCH_MILLISECONDS=${now_ms}\nELAPSED_FROM_LAUNCH_SECONDS=${elapsed}\nDETAIL=${detail}\n"
  append_text [file join $output_dir G2B_BS2_TIMELINE.log] "${label}|${timestamp}|${now_ms}|${elapsed}|${detail}\n"
  puts "BS2_MARKER ${label} ${timestamp} elapsed=${elapsed}s"
  flush stdout
  return [list $now_ms $timestamp $elapsed]
}

proc property_or_na {property object} {
  if {[catch {get_property $property $object} value]} { return "N/A" }
  if {$value eq ""} { return "N/A" }
  return $value
}

proc csv_quote {value} {
  set flattened [string map [list "\r" " " "\n" " "] $value]
  set escaped [string map [list "\"" "\"\""] $flattened]
  return "\"${escaped}\""
}

proc csv_row {fields} {
  set quoted [list]
  foreach field $fields { lappend quoted [csv_quote $field] }
  return [join $quoted ,]
}

proc object_clock_names {cell} {
  set clock_pins [get_pins -quiet -of_objects $cell -filter {IS_CLOCK == 1 || REF_PIN_NAME == C || REF_PIN_NAME == CLK}]
  set clocks [get_clocks -quiet -of_objects $clock_pins]
  if {[llength $clocks] == 0} { return "NONE" }
  return [join [lsort -dictionary -unique [get_property NAME $clocks]] ";"]
}

proc cell_from_endpoint_pin {pin_name} {
  if {$pin_name eq "" || $pin_name eq "N/A"} { return "N/A" }
  set pin_object [get_pins -quiet [list $pin_name]]
  if {[llength $pin_object] != 1} { return "N/A" }
  set cell_object [get_cells -quiet -of_objects $pin_object]
  if {[llength $cell_object] != 1} { return "N/A" }
  return [get_property NAME $cell_object]
}

proc write_endpoint_inventory {output_dir sources sinks} {
  set rows [list [csv_row {ROLE NAME REF_NAME PRIMITIVE_TYPE CLOCK_NAMES LOC IS_SEQUENTIAL}]]
  foreach source $sources {
    lappend rows [csv_row [list SOURCE [get_property NAME $source] [property_or_na REF_NAME $source] [property_or_na PRIMITIVE_TYPE $source] [object_clock_names $source] [property_or_na LOC $source] [property_or_na IS_SEQUENTIAL $source]]]
  }
  foreach sink $sinks {
    lappend rows [csv_row [list SINK [get_property NAME $sink] [property_or_na REF_NAME $sink] [property_or_na PRIMITIVE_TYPE $sink] [object_clock_names $sink] [property_or_na LOC $sink] [property_or_na IS_SEQUENTIAL $sink]]]
  }
  write_text [file join $output_dir G2B_BS2_ENDPOINT_INVENTORY.csv] "[join $rows \n]\n"
}

proc run_bs2 {} {
  global argv argc
  if {$argc != 9} {
    error "usage: G2B_BS2_WORKER.tcl DCP BASE_XDC SOURCE_LIST SINK_LIST OUTPUT_DIR T0_EPOCH_MS DCP_SHA256 SOURCE_SHA256 SINK_SHA256"
  }

  lassign $argv checkpoint base_xdc source_list sink_list output_dir t0_ms dcp_sha256 source_sha256 sink_sha256
  file mkdir $output_dir
  mark_phase $output_dir WORKER_STARTED $t0_ms "Tcl worker entered"
  write_text [file join $output_dir G2B_BS2_VIVADO_VERSION.txt] "SHORT=[version -short]\nFULL=[version]\n"

  open_checkpoint $checkpoint
  mark_phase $output_dir DCP_OPENED $t0_ms "sealed routed checkpoint opened"

  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} { error "sealed routed DCP part mismatch: $part" }

  set route_report [file join $output_dir G2B_BS2_ROUTE_STATUS.rpt]
  report_route_status -file $route_report
  set route_handle [open $route_report r]
  fconfigure $route_handle -translation auto -encoding utf-8
  set route_text [read $route_handle]
  close $route_handle
  if {![regexp -line {# of routable nets[^:\n]*:\s*([0-9]+)} $route_text route_match routable_nets]} {
    error "unable to parse routable-net count from route status"
  }
  if {![regexp -line {# of fully routed nets[^:\n]*:\s*([0-9]+)} $route_text fully_match fully_routed_nets]} {
    error "unable to parse fully-routed-net count from route status"
  }
  if {![regexp -line {# of nets with routing errors[^:\n]*:\s*([0-9]+)} $route_text error_match routing_error_nets]} {
    error "unable to parse routing-error count from route status"
  }
  if {$routable_nets != $fully_routed_nets || $routing_error_nets != 0} {
    error "sealed checkpoint is not fully routed: routable=$routable_nets fully_routed=$fully_routed_nets routing_errors=$routing_error_nets"
  }

  reset_timing -invalid
  read_xdc $base_xdc

  set source_names [read_exact_name_list $source_list]
  set sink_names [read_exact_name_list $sink_list]
  if {[llength $source_names] != 58} { error "authoritative source-list count mismatch: [llength $source_names]" }
  if {[llength $sink_names] != 1} { error "authoritative sink-list count mismatch: [llength $sink_names]" }

  set sources [resolve_cells_exact $source_names SOURCE]
  set sinks [resolve_cells_exact $sink_names SINK]
  set resolved_source_names [get_property NAME $sources]
  set resolved_sink_names [get_property NAME $sinks]
  if {[lsort -dictionary $source_names] ne [lsort -dictionary $resolved_source_names]} {
    error "resolved source identity differs from authoritative S_FULL list"
  }
  if {[lsort -dictionary $sink_names] ne [lsort -dictionary $resolved_sink_names]} {
    error "resolved sink identity differs from authoritative K_OWNERSHIP_RESULT list"
  }
  set sink_name [lindex $resolved_sink_names 0]
  if {$sink_name ne "G2B_ONECH_C2H/own_ok_hold_source_reg"} {
    error "resolved singleton sink differs from required object: $sink_name"
  }

  write_text [file join $output_dir G2B_BS2_SOURCE_SET_RESOLVED.txt] "[join $resolved_source_names \n]\n"
  write_text [file join $output_dir G2B_BS2_SINK_SET_RESOLVED.txt] "[join $resolved_sink_names \n]\n"
  write_endpoint_inventory $output_dir $sources $sinks
  mark_phase $output_dir OBJECTS_RESOLVED $t0_ms "58 sources and singleton sink identity verified"

  set ready_ms [clock milliseconds]
  set ready_timestamp [utc_from_milliseconds $ready_ms]
  set initialization_elapsed [seconds_from_ms [expr {$ready_ms - $t0_ms}]]
  write_text [file join $output_dir COMMAND_READY.marker] "MARKER=COMMAND_READY\nTIMESTAMP=${ready_timestamp}\nEPOCH_MILLISECONDS=${ready_ms}\nDCP_SHA256=${dcp_sha256}\nSOURCE_COUNT=58\nSOURCE_SET_SHA256=${source_sha256}\nSINK_COUNT=1\nSINK_OBJECT=${sink_name}\nSINK_SET_SHA256=${sink_sha256}\nVIVADO_VERSION=[version -short]\nPART=${part}\nROUTABLE_NETS=${routable_nets}\nFULLY_ROUTED_NETS=${fully_routed_nets}\nROUTING_ERROR_NETS=${routing_error_nets}\nINITIALIZATION_ELAPSED_SECONDS=${initialization_elapsed}\nINITIALIZATION_WATCHDOG_SECONDS=900\nREPORT_TIMING_WATCHDOG_SECONDS=300\nGET_TIMING_PATHS_WATCHDOG_SECONDS=300\nREPORT_BUS_SKEW_ATTEMPT_COUNT=0\n"
  append_text [file join $output_dir G2B_BS2_TIMELINE.log] "COMMAND_READY|${ready_timestamp}|${ready_ms}|${initialization_elapsed}|exact scope ready; prohibited query not invoked\n"
  puts "BS2_COMMAND_READY ${ready_timestamp} initialization=${initialization_elapsed}s"
  flush stdout

  set report_start_ms [clock milliseconds]
  mark_phase $output_dir REPORT_TIMING_STARTED $t0_ms "delay_type=max max_paths=1 nworst=1 exact 58-to-1 scope"
  set report_path [file join $output_dir G2B_BS2_EXACT_SCOPE_TIMING.rpt]
  report_timing -delay_type max -max_paths 1 -nworst 1 -from $sources -to $sinks -file $report_path
  set report_end_ms [clock milliseconds]
  set report_elapsed [seconds_from_ms [expr {$report_end_ms - $report_start_ms}]]
  set report_handle [open $report_path r]
  fconfigure $report_handle -translation auto -encoding utf-8
  set report_text [read $report_handle]
  close $report_handle
  set report_path_count [regexp -all -line {^\s*Path Group:} $report_text]
  write_text [file join $output_dir G2B_BS2_REPORT_TIMING_SUMMARY.txt] "STATUS=PASS\nDELAY_TYPE=max\nANALYSIS_CONTEXT=SETUP_MAX\nMAX_PATHS=1\nNWORST=1\nRETURNED_PATH_COUNT=${report_path_count}\nELAPSED_SECONDS=${report_elapsed}\n"
  set report_completed_ms [clock milliseconds]
  set report_completed_timestamp [utc_from_milliseconds $report_completed_ms]
  write_text [file join $output_dir REPORT_TIMING_COMPLETED.marker] "MARKER=REPORT_TIMING_COMPLETED\nTIMESTAMP=${report_completed_timestamp}\nEPOCH_MILLISECONDS=${report_completed_ms}\nREPORT_TIMING_ELAPSED_SECONDS=${report_elapsed}\nRETURNED_PATH_COUNT=${report_path_count}\nSTATUS=PASS\n"
  append_text [file join $output_dir G2B_BS2_TIMELINE.log] "REPORT_TIMING_COMPLETED|${report_completed_timestamp}|${report_completed_ms}|[seconds_from_ms [expr {$report_completed_ms - $t0_ms}]]|command_elapsed=${report_elapsed}s paths=${report_path_count}\n"
  puts "BS2_REPORT_TIMING_COMPLETED elapsed=${report_elapsed}s paths=${report_path_count}"
  flush stdout

  set paths_start_ms [clock milliseconds]
  mark_phase $output_dir GET_TIMING_PATHS_STARTED $t0_ms "delay_type=max max_paths=58 nworst=58 exact 58-to-1 scope"
  set paths [get_timing_paths -delay_type max -max_paths 58 -nworst 58 -from $sources -to $sinks]
  set path_count [llength $paths]
  set all_properties [list]
  foreach path $paths {
    foreach property [list_property $path] {
      if {[lsearch -exact $all_properties $property] < 0} { lappend all_properties $property }
    }
  }
  set all_properties [lsort -dictionary $all_properties]
  write_text [file join $output_dir G2B_BS2_TIMING_PATH_PROPERTY_NAMES.txt] "[join $all_properties \n]\n"

  set relevant_properties [list]
  set preferred_properties {SOURCE DESTINATION STARTPOINT_PIN ENDPOINT_PIN DATA_PATH_DELAY DATAPATH_DELAY ARRIVAL DATA_ARRIVAL_TIME SLACK REQUIREMENT STARTPOINT_CLOCK ENDPOINT_CLOCK LOGIC_LEVELS DELAY_TYPE PATH_GROUP SKEW UNCERTAINTY SOURCE_CLOCK_DELAY DESTINATION_CLOCK_DELAY}
  foreach candidate $preferred_properties {
    if {[lsearch -exact $all_properties $candidate] >= 0} { lappend relevant_properties $candidate }
  }
  foreach property $all_properties {
    if {[regexp -nocase {(arrival|delay|slack|requirement|clock|logic.level|source|destination|startpoint|endpoint|path.group|skew|uncertainty)} $property] && [lsearch -exact $relevant_properties $property] < 0} {
      lappend relevant_properties $property
    }
  }

  set path_rows [list [csv_row [concat {PATH_INDEX SOURCE_CELL_DERIVED DESTINATION_CELL_DERIVED} $relevant_properties]]]
  set inventory_rows [list [csv_row {PROPERTY PRESENT_ON_PATH_COUNT SAMPLE_VALUE}]]
  set unique_source_cells [list]
  set unique_destination_cells [list]
  set path_index 0
  foreach path $paths {
    incr path_index
    set startpoint_pin [property_or_na STARTPOINT_PIN $path]
    set endpoint_pin [property_or_na ENDPOINT_PIN $path]
    set source_cell [cell_from_endpoint_pin $startpoint_pin]
    set destination_cell [cell_from_endpoint_pin $endpoint_pin]
    if {$source_cell ne "N/A" && [lsearch -exact $unique_source_cells $source_cell] < 0} { lappend unique_source_cells $source_cell }
    if {$destination_cell ne "N/A" && [lsearch -exact $unique_destination_cells $destination_cell] < 0} { lappend unique_destination_cells $destination_cell }
    set fields [list $path_index $source_cell $destination_cell]
    foreach property $relevant_properties { lappend fields [property_or_na $property $path] }
    lappend path_rows [csv_row $fields]
  }
  foreach property $all_properties {
    set present_count 0
    set sample "N/A"
    foreach path $paths {
      set value [property_or_na $property $path]
      if {$value ne "N/A"} {
        incr present_count
        if {$sample eq "N/A"} { set sample $value }
      }
    }
    lappend inventory_rows [csv_row [list $property $present_count $sample]]
  }
  write_text [file join $output_dir G2B_BS2_TIMING_PATHS.csv] "[join $path_rows \n]\n"
  write_text [file join $output_dir G2B_BS2_TIMING_PATH_PROPERTY_VALUES.csv] "[join $inventory_rows \n]\n"
  set paths_end_ms [clock milliseconds]
  set paths_elapsed [seconds_from_ms [expr {$paths_end_ms - $paths_start_ms}]]
  set path_count_at_cap [expr {$path_count == 58 ? "YES" : "NO"}]
  write_text [file join $output_dir G2B_BS2_GET_TIMING_PATHS_SUMMARY.txt] "STATUS=PASS\nDELAY_TYPE=max\nANALYSIS_CONTEXT=SETUP_MAX\nMAX_PATHS=58\nNWORST=58\nPATH_COUNT=${path_count}\nPATH_COUNT_AT_CAP=${path_count_at_cap}\nUNIQUE_SOURCE_CELL_COUNT=[llength $unique_source_cells]\nUNIQUE_DESTINATION_CELL_COUNT=[llength $unique_destination_cells]\nUNIQUE_SOURCE_CELLS=[join [lsort -dictionary $unique_source_cells] {;}]\nUNIQUE_DESTINATION_CELLS=[join [lsort -dictionary $unique_destination_cells] {;}]\nELAPSED_SECONDS=${paths_elapsed}\n"
  set paths_completed_ms [clock milliseconds]
  set paths_completed_timestamp [utc_from_milliseconds $paths_completed_ms]
  write_text [file join $output_dir GET_TIMING_PATHS_COMPLETED.marker] "MARKER=GET_TIMING_PATHS_COMPLETED\nTIMESTAMP=${paths_completed_timestamp}\nEPOCH_MILLISECONDS=${paths_completed_ms}\nGET_TIMING_PATHS_ELAPSED_SECONDS=${paths_elapsed}\nPATH_COUNT=${path_count}\nUNIQUE_SOURCE_CELL_COUNT=[llength $unique_source_cells]\nSTATUS=PASS\n"
  append_text [file join $output_dir G2B_BS2_TIMELINE.log] "GET_TIMING_PATHS_COMPLETED|${paths_completed_timestamp}|${paths_completed_ms}|[seconds_from_ms [expr {$paths_completed_ms - $t0_ms}]]|command_elapsed=${paths_elapsed}s paths=${path_count}\n"
  puts "BS2_GET_TIMING_PATHS_COMPLETED elapsed=${paths_elapsed}s paths=${path_count}"
  flush stdout

  set methodology_start_ms [clock milliseconds]
  mark_phase $output_dir METHODOLOGY_STARTED $t0_ms "focused TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39 after exact in-memory bus-skew constraint application"
  set_bus_skew -from $sources -to $sinks 3.000
  set methodology_report [file join $output_dir G2B_BS2_TIMING_METHODOLOGY.rpt]
  set methodology_checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}
  report_methodology -checks $methodology_checks -file $methodology_report
  set methodology_end_ms [clock milliseconds]
  set methodology_elapsed [seconds_from_ms [expr {$methodology_end_ms - $methodology_start_ms}]]
  set methodology_completed_timestamp [utc_from_milliseconds $methodology_end_ms]
  write_text [file join $output_dir METHODOLOGY_COMPLETED.marker] "MARKER=METHODOLOGY_COMPLETED\nTIMESTAMP=${methodology_completed_timestamp}\nEPOCH_MILLISECONDS=${methodology_end_ms}\nMETHODOLOGY_ELAPSED_SECONDS=${methodology_elapsed}\nCHECKS=TIMING-32,TIMING-34,TIMING-37,TIMING-38,TIMING-39\nSTATUS=PASS\n"
  append_text [file join $output_dir G2B_BS2_TIMELINE.log] "METHODOLOGY_COMPLETED|${methodology_completed_timestamp}|${methodology_end_ms}|[seconds_from_ms [expr {$methodology_end_ms - $t0_ms}]]|command_elapsed=${methodology_elapsed}s\n"
  puts "BS2_METHODOLOGY_COMPLETED elapsed=${methodology_elapsed}s"
  flush stdout

  write_text [file join $output_dir G2B_BS2_WORKER_STATE.txt] "EXPERIMENT_ID=BS2_EXP001\nSTATE=COMPLETE\nVIVADO_VERSION=[version -short]\nPART=${part}\nROUTE_STATUS=FULLY_ROUTED\nSOURCE_COUNT=58\nSINK_COUNT=1\nSINK_NAME=${sink_name}\nREPORT_TIMING_STATUS=PASS\nREPORT_TIMING_ELAPSED_SECONDS=${report_elapsed}\nREPORT_TIMING_PATH_COUNT=${report_path_count}\nGET_TIMING_PATHS_STATUS=PASS\nGET_TIMING_PATHS_ELAPSED_SECONDS=${paths_elapsed}\nGET_TIMING_PATH_COUNT=${path_count}\nMETHODOLOGY_STATUS=PASS\nMETHODOLOGY_ELAPSED_SECONDS=${methodology_elapsed}\nREPORT_BUS_SKEW_ATTEMPT_COUNT=0\n"
  mark_phase $output_dir WORKER_COMPLETED $t0_ms "all bounded alternative timing stages completed"
  close_design
}

if {$argc >= 5} {
  set bs2_output_dir [lindex $argv 4]
} else {
  set bs2_output_dir [pwd]
}
if {$argc >= 6} {
  set bs2_t0_ms [lindex $argv 5]
} else {
  set bs2_t0_ms [clock milliseconds]
}

if {[catch {run_bs2} bs2_error bs2_options]} {
  set error_ms [clock milliseconds]
  set error_timestamp [utc_from_milliseconds $error_ms]
  set error_elapsed [seconds_from_ms [expr {$error_ms - $bs2_t0_ms}]]
  write_text [file join $bs2_output_dir VIVADO_ERROR.marker] "MARKER=VIVADO_ERROR\nTIMESTAMP=${error_timestamp}\nEPOCH_MILLISECONDS=${error_ms}\nELAPSED_FROM_LAUNCH_SECONDS=${error_elapsed}\nERROR=${bs2_error}\n"
  append_text [file join $bs2_output_dir G2B_BS2_TIMELINE.log] "VIVADO_ERROR|${error_timestamp}|${error_ms}|${error_elapsed}|${bs2_error}\n"
  set error_info [dict get $bs2_options -errorinfo]
  write_text [file join $bs2_output_dir G2B_BS2_VIVADO_ERROR.txt] "ERROR=${bs2_error}\n\n${error_info}\n"
  puts stderr "BS2_VIVADO_ERROR: $bs2_error"
  catch {close_design}
  exit 1
}

exit 0
