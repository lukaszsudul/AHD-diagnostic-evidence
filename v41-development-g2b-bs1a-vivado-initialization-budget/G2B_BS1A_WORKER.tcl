proc utc_from_milliseconds {milliseconds} {
  set seconds [expr {$milliseconds / 1000}]
  set fraction [format %03d [expr {$milliseconds % 1000}]]
  return "[clock format $seconds -gmt true -format {%Y-%m-%dT%H:%M:%S}].${fraction}Z"
}

proc utc_now {} {
  return [utc_from_milliseconds [clock milliseconds]]
}

proc write_text {path text} {
  set handle [open $path w]
  fconfigure $handle -translation lf -encoding utf-8
  puts -nonewline $handle $text
  close $handle
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

proc csv_quote {value} {
  set escaped [string map [list "\"" "\"\""] $value]
  return "\"${escaped}\""
}

proc format_seconds_from_ms {milliseconds} {
  return [format %.3f [expr {double($milliseconds) / 1000.0}]]
}

proc mark_milestone {output_dir label t0_ms phase_start_ms detail} {
  set now_ms [clock milliseconds]
  set timestamp [utc_from_milliseconds $now_ms]
  set total_elapsed [format_seconds_from_ms [expr {$now_ms - $t0_ms}]]
  set phase_elapsed [format_seconds_from_ms [expr {$now_ms - $phase_start_ms}]]
  set row [join [list $label $timestamp $now_ms $total_elapsed $phase_elapsed [csv_quote $detail]] ","]
  append_text [file join $output_dir G2B_BS1A_INITIALIZATION_TIMELINE.csv] "${row}\n"
  write_text [file join $output_dir "${label}.marker"] "MILESTONE=${label}\nTIMESTAMP=${timestamp}\nEPOCH_MILLISECONDS=${now_ms}\nELAPSED_FROM_T0_SECONDS=${total_elapsed}\nPHASE_ELAPSED_SECONDS=${phase_elapsed}\nDETAIL=${detail}\n"
  puts "BS1A_MILESTONE ${label} ${timestamp} elapsed=${total_elapsed}s phase=${phase_elapsed}s"
  flush stdout
  return [list $now_ms $timestamp $total_elapsed $phase_elapsed]
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

proc write_timing_property_snapshot {path stage} {
  set rows [list "STAGE=${stage}"]
  set design [current_design]
  foreach property [lsort -dictionary [list_property $design]] {
    if {[string match -nocase "*TIMING*" $property]} {
      if {[catch {get_property $property $design} value]} {
        set value "ERROR_READING_PROPERTY"
      }
      lappend rows "${property}=${value}"
    }
  }
  write_text $path "[join $rows \n]\n"
}

proc resolve_exact_cells {names role} {
  set objects [list]
  foreach name $names {
    set matches [get_cells -quiet [list $name]]
    if {[llength $matches] != 1} {
      error "${role} object resolution count for ${name}: [llength $matches]"
    }
    set resolved_name [get_property NAME [lindex $matches 0]]
    if {$resolved_name ne $name} {
      error "${role} object identity mismatch: expected=${name} resolved=${resolved_name}"
    }
    lappend objects [lindex $matches 0]
  }
  return $objects
}

proc run_bs1a {} {
  global argv argc
  if {$argc != 9} {
    error "usage: G2B_BS1A_WORKER.tcl DCP BASE_XDC SOURCE_LIST SINK_LIST OUTPUT_DIR T0_EPOCH_MS DCP_SHA256 SOURCE_SHA256 SINK_SHA256"
  }

  lassign $argv checkpoint base_xdc source_list sink_list output_dir t0_ms dcp_sha256 source_sha256 sink_sha256
  file mkdir $output_dir

  set t1_values [mark_milestone $output_dir T1 $t0_ms $t0_ms "Tcl worker entered"]
  lassign $t1_values t1_ms t1_timestamp t1_total t1_phase
  set vivado_version [version -short]
  set vivado_version_full [version]
  write_text [file join $output_dir G2B_BS1A_VIVADO_VERSION.txt] "SHORT=${vivado_version}\nFULL=${vivado_version_full}\n"

  set t2_values [mark_milestone $output_dir T2 $t0_ms $t1_ms "open_checkpoint started"]
  lassign $t2_values t2_ms t2_timestamp t2_total t2_phase
  open_checkpoint $checkpoint
  set t3_values [mark_milestone $output_dir T3 $t0_ms $t2_ms "open_checkpoint completed"]
  lassign $t3_values t3_ms t3_timestamp t3_total t3_phase

  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} {
    error "sealed routed DCP part mismatch: $part"
  }

  set route_start_ms [clock milliseconds]
  set route_report [file join $output_dir G2B_BS1A_ROUTE_STATUS.rpt]
  report_route_status -file $route_report
  set t4_values [mark_milestone $output_dir T4 $t0_ms $route_start_ms "route-status query completed"]
  lassign $t4_values t4_ms t4_timestamp t4_total t4_phase

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

  set context_start_ms [clock milliseconds]
  reset_timing -invalid
  read_xdc $base_xdc
  write_timing_property_snapshot [file join $output_dir G2B_BS1A_TIMING_DATABASE_PROPERTIES.txt] COMMAND_PREPARATION_COMPLETE
  set t5_values [mark_milestone $output_dir T5 $t0_ms $context_start_ms "required XDC/context preparation completed"]
  lassign $t5_values t5_ms t5_timestamp t5_total t5_phase

  set source_start_ms [clock milliseconds]
  set source_names [read_exact_name_list $source_list]
  if {[llength $source_names] != 58} {
    error "authoritative source-list count mismatch: [llength $source_names]"
  }
  set sources [resolve_exact_cells $source_names SOURCE]
  set resolved_source_names [get_property NAME $sources]
  set t6_values [mark_milestone $output_dir T6 $t0_ms $source_start_ms "58 source objects resolved"]
  lassign $t6_values t6_ms t6_timestamp t6_total t6_phase

  set sink_start_ms [clock milliseconds]
  set sink_names [read_exact_name_list $sink_list]
  if {[llength $sink_names] != 1} {
    error "authoritative sink-list count mismatch: [llength $sink_names]"
  }
  set sinks [resolve_exact_cells $sink_names SINK]
  set resolved_sink_names [get_property NAME $sinks]
  set t7_values [mark_milestone $output_dir T7 $t0_ms $sink_start_ms "singleton sink object resolved"]
  lassign $t7_values t7_ms t7_timestamp t7_total t7_phase

  set identity_start_ms [clock milliseconds]
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
    error "resolved singleton sink differs from required BS1 object: $sink_name"
  }
  write_text [file join $output_dir G2B_BS1A_SOURCE_SET_RESOLVED.txt] "[join $resolved_source_names \n]\n"
  write_text [file join $output_dir G2B_BS1A_SINK_SET_RESOLVED.txt] "[join $resolved_sink_names \n]\n"
  set sink_ref_name [property_or_na REF_NAME $sinks]
  set sink_primitive_type [property_or_na PRIMITIVE_TYPE $sinks]
  set t8_values [mark_milestone $output_dir T8 $t0_ms $identity_start_ms "object identity verified"]
  lassign $t8_values t8_ms t8_timestamp t8_total t8_phase

  set readiness_start_ms [clock milliseconds]
  set_bus_skew -from $sources -to $sinks 3.000
  write_xdc -exclude_physical -force [file join $output_dir G2B_BS1A_APPLIED_CONSTRAINT.xdc]
  set t9_values [mark_milestone $output_dir T9 $t0_ms $readiness_start_ms "COMMAND_READY"]
  lassign $t9_values t9_ms t9_timestamp t9_total t9_phase

  set state_lines [list \
    "STATE=COMMAND_READY" \
    "VIVADO_VERSION=$vivado_version" \
    "PART=$part" \
    "ROUTE_STATUS=FULLY_ROUTED" \
    "ROUTABLE_NETS=$routable_nets" \
    "FULLY_ROUTED_NETS=$fully_routed_nets" \
    "ROUTING_ERROR_NETS=$routing_error_nets" \
    "PROCESS_STARTUP_TIME_SECONDS=$t1_phase" \
    "TCL_ENTRY_TIME_SECONDS=$t2_phase" \
    "CHECKPOINT_OPEN_TIME_SECONDS=$t3_phase" \
    "ROUTE_STATUS_TIME_SECONDS=$t4_phase" \
    "CONTEXT_PREPARATION_TIME_SECONDS=$t5_phase" \
    "SOURCE_RESOLUTION_TIME_SECONDS=$t6_phase" \
    "SINK_RESOLUTION_TIME_SECONDS=$t7_phase" \
    "IDENTITY_VERIFICATION_TIME_SECONDS=$t8_phase" \
    "COMMAND_READY_FINALIZATION_TIME_SECONDS=$t9_phase" \
    "TOTAL_TIME_TO_COMMAND_READY_SECONDS=$t9_total" \
    "SOURCE_COUNT=[llength $sources]" \
    "SOURCE_SET_SHA256=$source_sha256" \
    "SINK_COUNT=[llength $sinks]" \
    "SINK_SET_SHA256=$sink_sha256" \
    "SINK_NAME=$sink_name" \
    "SINK_OBJECT_TYPE=CELL" \
    "SINK_REF_NAME=$sink_ref_name" \
    "SINK_PRIMITIVE_TYPE=$sink_primitive_type" \
    "TIMING_DATABASE_EXPLICIT_UPDATE=NO" \
    "BUS_SKEW_COMMAND_EXECUTED=NO" \
  ]
  write_text [file join $output_dir G2B_BS1A_WORKER_STATE.txt] "[join $state_lines \n]\n"

  set ready_lines [list \
    "TIMESTAMP=$t9_timestamp" \
    "DCP_SHA256=$dcp_sha256" \
    "SOURCE_COUNT=[llength $sources]" \
    "SOURCE_SET_SHA256=$source_sha256" \
    "SINK_COUNT=[llength $sinks]" \
    "SINK_SET_SHA256=$sink_sha256" \
    "VIVADO_VERSION=$vivado_version" \
    "TOTAL_INITIALIZATION_ELAPSED_SECONDS=$t9_total" \
    "BUS_SKEW_COMMAND_EXECUTED=NO" \
  ]
  write_text [file join $output_dir COMMAND_READY.marker] "[join $ready_lines \n]\n"
  puts "BS1A_COMMAND_READY $t9_timestamp total=${t9_total}s"
  flush stdout

  close_design
}

if {$argc >= 5} {
  set bs1a_output_dir [lindex $argv 4]
} else {
  set bs1a_output_dir [pwd]
}
if {$argc >= 6} {
  set bs1a_t0_ms [lindex $argv 5]
} else {
  set bs1a_t0_ms [clock milliseconds]
}

if {[catch {run_bs1a} bs1a_error bs1a_options]} {
  set error_ms [clock milliseconds]
  set error_timestamp [utc_from_milliseconds $error_ms]
  set error_elapsed [format_seconds_from_ms [expr {$error_ms - $bs1a_t0_ms}]]
  write_text [file join $bs1a_output_dir VIVADO_ERROR.marker] "MARKER=VIVADO_ERROR\nTIMESTAMP=${error_timestamp}\nELAPSED_FROM_T0_SECONDS=${error_elapsed}\nERROR=${bs1a_error}\n"
  append_text [file join $bs1a_output_dir G2B_BS1A_INITIALIZATION_TIMELINE.csv] "ERROR,${error_timestamp},${error_ms},${error_elapsed},0.000,[csv_quote $bs1a_error]\n"
  set error_info [dict get $bs1a_options -errorinfo]
  write_text [file join $bs1a_output_dir G2B_BS1A_VIVADO_ERROR.txt] "ERROR=${bs1a_error}\n\n${error_info}\n"
  puts stderr "BS1A_VIVADO_ERROR: $bs1a_error"
  catch {close_design}
  exit 1
}

exit 0
