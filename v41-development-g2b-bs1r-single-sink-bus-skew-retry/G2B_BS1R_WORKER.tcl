proc utc_from_milliseconds {milliseconds} {
  set seconds [expr {$milliseconds / 1000}]
  set fraction [format %03d [expr {$milliseconds % 1000}]]
  return "[clock format $seconds -gmt true -format {%Y-%m-%dT%H:%M:%S}].${fraction}Z"
}

proc utc_now {} {
  return [utc_from_milliseconds [clock milliseconds]]
}

proc format_seconds_from_ms {milliseconds} {
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
  if {$normalized eq ""} {
    return [list]
  }
  return [split $normalized "\n"]
}

proc mark_phase {output_dir label t0_ms detail} {
  set now_ms [clock milliseconds]
  set timestamp [utc_from_milliseconds $now_ms]
  set elapsed [format_seconds_from_ms [expr {$now_ms - $t0_ms}]]
  write_text [file join $output_dir "${label}.marker"] "MARKER=${label}\nTIMESTAMP=${timestamp}\nEPOCH_MILLISECONDS=${now_ms}\nELAPSED_FROM_LAUNCH_SECONDS=${elapsed}\nDETAIL=${detail}\n"
  append_text [file join $output_dir G2B_BS1R_TIMELINE.log] "${label}|${timestamp}|${now_ms}|${elapsed}|${detail}\n"
  puts "BS1R_MARKER ${label} ${timestamp} elapsed=${elapsed}s"
  flush stdout
  return [list $now_ms $timestamp $elapsed]
}

proc property_or_na {property object} {
  if {[catch {get_property $property $object} value]} {
    return "N/A"
  }
  if {$value eq ""} {
    return "N/A"
  }
  return $value
}

proc run_bs1r {} {
  global argv argc
  if {$argc != 9} {
    error "usage: G2B_BS1R_WORKER.tcl DCP BASE_XDC SOURCE_LIST SINK_LIST OUTPUT_DIR T0_EPOCH_MS DCP_SHA256 SOURCE_SHA256 SINK_SHA256"
  }

  lassign $argv checkpoint base_xdc source_list sink_list output_dir t0_ms dcp_sha256 source_sha256 sink_sha256
  file mkdir $output_dir

  set worker_values [mark_phase $output_dir WORKER_STARTED $t0_ms "Tcl worker entered"]
  lassign $worker_values worker_started_ms worker_started_timestamp worker_start_elapsed
  set vivado_version [version -short]
  set vivado_version_full [version]
  write_text [file join $output_dir G2B_BS1R_VIVADO_VERSION.txt] "SHORT=${vivado_version}\nFULL=${vivado_version_full}\n"

  set checkpoint_open_start_ms [clock milliseconds]
  open_checkpoint $checkpoint
  set dcp_values [mark_phase $output_dir DCP_OPENED $t0_ms "sealed routed checkpoint opened"]
  lassign $dcp_values dcp_opened_ms dcp_opened_timestamp dcp_opened_elapsed

  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} {
    error "sealed routed DCP part mismatch: $part"
  }

  set route_report [file join $output_dir G2B_BS1R_ROUTE_STATUS.rpt]
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
  if {[llength $source_names] != 58} {
    error "authoritative source-list count mismatch: [llength $source_names]"
  }
  if {[llength $sink_names] != 1} {
    error "authoritative sink-list count mismatch: [llength $sink_names]"
  }

  set sources [get_cells -quiet $source_names]
  set sinks [get_cells -quiet $sink_names]
  set resolved_source_names [get_property NAME $sources]
  set resolved_sink_names [get_property NAME $sinks]
  if {[llength $sources] != 58} {
    error "resolved source count mismatch: [llength $sources]"
  }
  if {[llength $sinks] != 1} {
    error "resolved sink count mismatch: [llength $sinks]"
  }
  if {[lsort -dictionary $source_names] ne [lsort -dictionary $resolved_source_names]} {
    error "resolved source identity differs from authoritative S_FULL list"
  }
  if {[lsort -dictionary $sink_names] ne [lsort -dictionary $resolved_sink_names]} {
    error "resolved sink identity differs from authoritative K_OWNERSHIP_RESULT list"
  }

  set sink_name [lindex $resolved_sink_names 0]
  if {$sink_name ne "G2B_ONECH_C2H/own_ok_hold_source_reg"} {
    error "resolved singleton sink differs from required BS1R object: $sink_name"
  }
  set sink_ref_name [property_or_na REF_NAME $sinks]
  set sink_primitive_type [property_or_na PRIMITIVE_TYPE $sinks]
  write_text [file join $output_dir G2B_BS1R_SOURCE_SET_RESOLVED.txt] "[join $resolved_source_names \n]\n"
  write_text [file join $output_dir G2B_BS1R_SINK_SET_RESOLVED.txt] "[join $resolved_sink_names \n]\n"

  set objects_values [mark_phase $output_dir OBJECTS_RESOLVED $t0_ms "58 sources and singleton sink identity verified"]
  lassign $objects_values objects_resolved_ms objects_resolved_timestamp objects_resolved_elapsed

  set_bus_skew -from $sources -to $sinks 3.000
  write_xdc -exclude_physical -force [file join $output_dir G2B_BS1R_APPLIED_CONSTRAINT.xdc]

  set ready_ms [clock milliseconds]
  set ready_timestamp [utc_from_milliseconds $ready_ms]
  set initialization_elapsed [format_seconds_from_ms [expr {$ready_ms - $t0_ms}]]
  write_text [file join $output_dir COMMAND_READY.marker] "[join [list \
    "MARKER=COMMAND_READY" \
    "TIMESTAMP=$ready_timestamp" \
    "EPOCH_MILLISECONDS=$ready_ms" \
    "DCP_SHA256=$dcp_sha256" \
    "SOURCE_COUNT=[llength $sources]" \
    "SOURCE_SET_SHA256=$source_sha256" \
    "SINK_COUNT=[llength $sinks]" \
    "SINK_OBJECT=$sink_name" \
    "SINK_SET_SHA256=$sink_sha256" \
    "VIVADO_VERSION=$vivado_version" \
    "INITIALIZATION_ELAPSED_SECONDS=$initialization_elapsed" \
    "INITIALIZATION_WATCHDOG_SECONDS=900" \
    "BUS_SKEW_WATCHDOG_SECONDS=300" \
    "BUS_SKEW_COMMAND_EXECUTED=NO" \
  ] "\n"]\n"
  append_text [file join $output_dir G2B_BS1R_TIMELINE.log] "COMMAND_READY|${ready_timestamp}|${ready_ms}|${initialization_elapsed}|exact scope and constraint prepared\n"

  write_text [file join $output_dir G2B_BS1R_WORKER_STATE.txt] [join [list \
    "EXPERIMENT_ID=BS1R_EXP001" \
    "STATE=COMMAND_READY" \
    "VIVADO_VERSION=$vivado_version" \
    "PART=$part" \
    "ROUTE_STATUS=FULLY_ROUTED" \
    "ROUTABLE_NETS=$routable_nets" \
    "FULLY_ROUTED_NETS=$fully_routed_nets" \
    "ROUTING_ERROR_NETS=$routing_error_nets" \
    "WORKER_STARTED_TIMESTAMP=$worker_started_timestamp" \
    "CHECKPOINT_OPEN_STARTED_EPOCH_MILLISECONDS=$checkpoint_open_start_ms" \
    "DCP_OPENED_TIMESTAMP=$dcp_opened_timestamp" \
    "OBJECTS_RESOLVED_TIMESTAMP=$objects_resolved_timestamp" \
    "COMMAND_READY_TIMESTAMP=$ready_timestamp" \
    "INITIALIZATION_ELAPSED_SECONDS=$initialization_elapsed" \
    "SOURCE_COUNT=[llength $sources]" \
    "SOURCE_SET_SHA256=$source_sha256" \
    "SINK_COUNT=[llength $sinks]" \
    "SINK_NAME=$sink_name" \
    "SINK_REF_NAME=$sink_ref_name" \
    "SINK_PRIMITIVE_TYPE=$sink_primitive_type" \
    "SINK_SET_SHA256=$sink_sha256" \
    "REQUIRED_SKEW_NS=3.000" \
    "REPORT_BUS_SKEW_ATTEMPT_COUNT=0" \
    "REPORT_TIMING_CONTROL=NOT_RUN" \
  ] "\n"]
  append_text [file join $output_dir G2B_BS1R_WORKER_STATE.txt] "\n"
  puts "BS1R_COMMAND_READY $ready_timestamp initialization=${initialization_elapsed}s"
  flush stdout

  set bus_skew_start_ms [clock milliseconds]
  set bus_skew_start_timestamp [utc_from_milliseconds $bus_skew_start_ms]
  set bus_skew_start_elapsed [format_seconds_from_ms [expr {$bus_skew_start_ms - $t0_ms}]]
  write_text [file join $output_dir BUS_SKEW_STARTED.marker] "MARKER=BUS_SKEW_STARTED\nTIMESTAMP=${bus_skew_start_timestamp}\nEPOCH_MILLISECONDS=${bus_skew_start_ms}\nELAPSED_FROM_LAUNCH_SECONDS=${bus_skew_start_elapsed}\nSOURCE_COUNT=58\nSINK_COUNT=1\nSINK_OBJECT=${sink_name}\nREQUIRED_SKEW_NS=3.000\nREPORT_BUS_SKEW_ATTEMPT_COUNT=1\n"
  append_text [file join $output_dir G2B_BS1R_TIMELINE.log] "BUS_SKEW_STARTED|${bus_skew_start_timestamp}|${bus_skew_start_ms}|${bus_skew_start_elapsed}|single bounded report_bus_skew attempt\n"
  append_text [file join $output_dir G2B_BS1R_WORKER_STATE.txt] "STATE=BUS_SKEW_RUNNING\nBUS_SKEW_STARTED_TIMESTAMP=${bus_skew_start_timestamp}\nREPORT_BUS_SKEW_ATTEMPT_COUNT=1\n"
  puts "BS1R_BUS_SKEW_STARTED $bus_skew_start_timestamp"
  flush stdout

  report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file [file join $output_dir G2B_BS1R_REPORT_BUS_SKEW.rpt]

  set bus_skew_end_ms [clock milliseconds]
  set bus_skew_end_timestamp [utc_from_milliseconds $bus_skew_end_ms]
  set bus_skew_elapsed [format_seconds_from_ms [expr {$bus_skew_end_ms - $bus_skew_start_ms}]]
  set total_elapsed [format_seconds_from_ms [expr {$bus_skew_end_ms - $t0_ms}]]
  write_text [file join $output_dir BUS_SKEW_COMPLETED.marker] "MARKER=BUS_SKEW_COMPLETED\nTIMESTAMP=${bus_skew_end_timestamp}\nEPOCH_MILLISECONDS=${bus_skew_end_ms}\nBUS_SKEW_ELAPSED_SECONDS=${bus_skew_elapsed}\nTOTAL_ELAPSED_SECONDS=${total_elapsed}\nREPORT_BUS_SKEW_ATTEMPT_COUNT=1\n"
  append_text [file join $output_dir G2B_BS1R_TIMELINE.log] "BUS_SKEW_COMPLETED|${bus_skew_end_timestamp}|${bus_skew_end_ms}|${total_elapsed}|command_elapsed=${bus_skew_elapsed}s\n"
  append_text [file join $output_dir G2B_BS1R_WORKER_STATE.txt] "STATE=COMPLETE\nBUS_SKEW_COMPLETED_TIMESTAMP=${bus_skew_end_timestamp}\nBUS_SKEW_ELAPSED_SECONDS=${bus_skew_elapsed}\nTOTAL_ELAPSED_SECONDS=${total_elapsed}\nREPORT_TIMING_CONTROL=NOT_RUN\n"
  puts "BS1R_BUS_SKEW_COMPLETED $bus_skew_end_timestamp command=${bus_skew_elapsed}s"
  flush stdout

  close_design
}

if {$argc >= 5} {
  set bs1r_output_dir [lindex $argv 4]
} else {
  set bs1r_output_dir [pwd]
}
if {$argc >= 6} {
  set bs1r_t0_ms [lindex $argv 5]
} else {
  set bs1r_t0_ms [clock milliseconds]
}

if {[catch {run_bs1r} bs1r_error bs1r_options]} {
  set error_ms [clock milliseconds]
  set error_timestamp [utc_from_milliseconds $error_ms]
  set error_elapsed [format_seconds_from_ms [expr {$error_ms - $bs1r_t0_ms}]]
  write_text [file join $bs1r_output_dir VIVADO_ERROR.marker] "MARKER=VIVADO_ERROR\nTIMESTAMP=${error_timestamp}\nEPOCH_MILLISECONDS=${error_ms}\nELAPSED_FROM_LAUNCH_SECONDS=${error_elapsed}\nERROR=${bs1r_error}\n"
  append_text [file join $bs1r_output_dir G2B_BS1R_TIMELINE.log] "VIVADO_ERROR|${error_timestamp}|${error_ms}|${error_elapsed}|${bs1r_error}\n"
  set error_info [dict get $bs1r_options -errorinfo]
  write_text [file join $bs1r_output_dir G2B_BS1R_VIVADO_ERROR.txt] "ERROR=${bs1r_error}\n\n${error_info}\n"
  puts stderr "BS1R_VIVADO_ERROR: $bs1r_error"
  catch {close_design}
  exit 1
}

exit 0
