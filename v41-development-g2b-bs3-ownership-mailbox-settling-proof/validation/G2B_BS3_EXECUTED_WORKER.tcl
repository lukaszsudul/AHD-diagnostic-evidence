proc write_text {path text} {
  set handle [open $path w]
  fconfigure $handle -translation lf -encoding utf-8
  puts -nonewline $handle $text
  close $handle
}

proc prop {object name} {
  if {[catch {get_property $name $object} value] || $value eq ""} {
    return "N/A"
  }
  return $value
}

proc seconds_since {start_ms} {
  return [format %.3f [expr {double([clock milliseconds] - $start_ms) / 1000.0}]]
}

proc collection_names {objects} {
  if {[llength $objects] == 0} { return "" }
  return [join [lsort -dictionary [get_property NAME $objects]] "\n"]
}

proc read_name_list {path} {
  set handle [open $path r]
  fconfigure $handle -translation auto -encoding utf-8
  set text [read $handle]
  close $handle
  set names [list]
  foreach line [split $text "\n"] {
    set name [string trim $line]
    if {$name ne ""} { lappend names $name }
  }
  return [lsort -dictionary $names]
}

proc require_exact_identity {label objects reference_path expected_count} {
  set actual [lsort -dictionary [get_property NAME $objects]]
  set expected [read_name_list $reference_path]
  if {[llength $actual] != $expected_count || [llength $expected] != $expected_count} {
    error "$label exact-identity count mismatch"
  }
  if {$actual ne $expected} {
    error "$label resolved identity differs from qualified BS0 reference"
  }
}

proc property_is_true {value} {
  return [expr {$value eq "1" || [string equal -nocase $value "true"] ||
                [string equal -nocase $value "yes"]}]
}

proc run_family_query {label family_src dst_cells dst_d output_dir} {
  set query_start [clock milliseconds]
  write_text [file join $output_dir QUERY_STARTED.marker] \
      "MODE=$label\nEPOCH_MILLISECONDS=$query_start\nTIMEOUT_SECONDS=300\nCOMMAND=get_timing_paths\n"
  set paths [get_timing_paths -delay_type max -sort_by slack \
      -max_paths 1 -nworst 1 -from $family_src -to $dst_d]
  set query_elapsed [seconds_since $query_start]
  if {[llength $paths] != 1} {
    error "family $label did not return exactly one worst path"
  }
  set path [lindex $paths 0]
  set datapath_delay [prop $path DATAPATH_DELAY]
  set path_slack [prop $path SLACK]
  set path_requirement [prop $path REQUIREMENT]
  set startpoint_clock [prop $path STARTPOINT_CLOCK]
  set endpoint_clock [prop $path ENDPOINT_CLOCK]
  if {![string is double -strict $datapath_delay] || $datapath_delay > 6.000} {
    error "family $label violates the absolute 6.000 ns datapath cap: $datapath_delay"
  }
  if {![string is double -strict $path_slack] || $path_slack < 0.0} {
    error "family $label has negative or invalid slack: $path_slack"
  }
  if {![string is double -strict $path_requirement] ||
      abs($path_requirement - 6.000) > 0.0005} {
    error "family $label has wrong max-delay requirement: $path_requirement"
  }
  if {$startpoint_clock ne "userclk1" || $endpoint_clock ne "nvp_vclk1"} {
    error "family $label has wrong clock direction: $startpoint_clock to $endpoint_clock"
  }
  set result "FAMILY=$label\n"
  append result "STATUS=PASS\n"
  append result "SOURCE_COUNT=[llength $family_src]\n"
  append result "DESTINATION_COUNT=[llength $dst_cells]\n"
  append result "PATH_COUNT=[llength $paths]\n"
  append result "REQUIRED_NS=6.000\n"
  append result "DATAPATH_DELAY_NS=$datapath_delay\n"
  append result "SLACK_NS=$path_slack\n"
  append result "PATH_REQUIREMENT_NS=$path_requirement\n"
  append result "STARTPOINT_PIN=[prop $path STARTPOINT_PIN]\n"
  append result "ENDPOINT_PIN=[prop $path ENDPOINT_PIN]\n"
  append result "STARTPOINT_CLOCK=$startpoint_clock\n"
  append result "ENDPOINT_CLOCK=$endpoint_clock\n"
  append result "LOGIC_LEVELS=[prop $path LOGIC_LEVELS]\n"
  append result "EXCEPTION=[prop $path EXCEPTION]\n"
  append result "QUERY_RUNTIME_SECONDS=$query_elapsed\n"
  write_text [file join $output_dir "G2B_BS3_[string toupper $label]_TIMING_RESULT.txt"] $result
  report_timing -of_objects $path \
      -file [file join $output_dir "G2B_BS3_[string toupper $label]_WORST_PATH.rpt"]
  write_text [file join $output_dir "QUERY_COMPLETED_[string toupper $label].marker"] \
      "MODE=$label\nQUERY_RUNTIME_SECONDS=$query_elapsed\nSTATUS=PASS\n"
}

proc run_bs3 {} {
  global argv argc
  if {$argc != 5} {
    error "usage: G2B_BS3_WORKER.tcl DCP BASE_XDC CANDIDATE_XDC OUTPUT_DIR MODE"
  }
  lassign $argv checkpoint base_xdc candidate_xdc output_dir mode
  file mkdir $output_dir
  set worker_start [clock milliseconds]
  write_text [file join $output_dir WORKER_STARTED.marker] \
      "MODE=$mode\nEPOCH_MILLISECONDS=$worker_start\n"
  write_text [file join $output_dir G2B_BS3_VIVADO_VERSION.txt] \
      "SHORT=[version -short]\nFULL=[version]\n"

  open_checkpoint $checkpoint
  set part [get_property PART [current_design]]
  if {$part ne "xc7a35tcsg325-2"} {
    error "sealed routed DCP part mismatch: $part"
  }
  reset_timing -invalid
  read_xdc $base_xdc
  read_xdc $candidate_xdc

  # The candidate XDC creates collections; this worker fails closed on their
  # exact qualified identities and cardinalities.
  set slot_src $g2b_bs3_ownership_slot_src
  set generation_src $g2b_bs3_ownership_generation_src
  set epoch_src $g2b_bs3_ownership_epoch_src
  set dst_cells $g2b_bs3_ownership_payload_dst_cells
  set dst_d $g2b_bs3_ownership_payload_dst_d

  if {[llength $slot_src] != 2} {
    error "G2B-BS3 ownership slot source count is not 2"
  }
  if {[llength $generation_src] != 24} {
    error "G2B-BS3 ownership generation source count is not 24"
  }
  if {[llength $epoch_src] != 32} {
    error "G2B-BS3 ownership epoch source count is not 32"
  }
  if {[llength $dst_cells] != 17 || [llength $dst_d] != 17} {
    error "G2B-BS3 ownership payload destination count is not 17"
  }
  require_exact_identity SLOT $slot_src \
      {C:/FPGA/G2B_BS0_GROUP9_ANALYSIS_20260831/sets/S_AXIS_SLOT.txt} 2
  require_exact_identity GENERATION $generation_src \
      {C:/FPGA/G2B_BS0_GROUP9_ANALYSIS_20260831/sets/S_AXIS_GENERATION.txt} 24
  require_exact_identity EPOCH $epoch_src \
      {C:/FPGA/G2B_BS0_GROUP9_ANALYSIS_20260831/sets/S_AXIS_EPOCH.txt} 32
  require_exact_identity DESTINATION $dst_cells \
      {C:/FPGA/G2B_BS0_GROUP9_ANALYSIS_20260831/sets/K_PAYLOAD_DEPENDENT.txt} 17

  set req_cell_names [list \
      G2B_ONECH_C2H/own_req_sync1_source_reg \
      G2B_ONECH_C2H/own_req_sync2_source_reg]
  set ack_cell_names [list \
      G2B_ONECH_C2H/own_ack_sync1_axi_reg \
      G2B_ONECH_C2H/own_ack_sync2_axi_reg]
  set req_cells [get_cells -quiet $req_cell_names]
  set ack_cells [get_cells -quiet $ack_cell_names]
  if {[llength $req_cells] != 2 || [llength $ack_cells] != 2} {
    error "ownership request/ack synchronizer cells did not resolve 2+2"
  }
  foreach sync_cell_name [concat $req_cell_names $ack_cell_names] {
    set sync_cell [get_cells -quiet $sync_cell_name]
    if {[llength $sync_cell] != 1 ||
        ![property_is_true [get_property ASYNC_REG $sync_cell]]} {
      error "synchronizer lacks exact ASYNC_REG=TRUE identity: $sync_cell_name"
    }
  }

  set user_clock [get_clocks -quiet userclk1]
  set source_clock [get_clocks -quiet nvp_vclk1]
  if {[llength $user_clock] != 1 || [llength $source_clock] != 1} {
    error "ownership clocks did not resolve exactly once"
  }
  set user_period [get_property PERIOD $user_clock]
  set source_period [get_property PERIOD $source_clock]
  if {![string is double -strict $user_period] || abs($user_period - 16.000) > 0.0005} {
    error "userclk1 period differs from qualified 16.000 ns: $user_period"
  }
  if {![string is double -strict $source_period] || abs($source_period - 6.734) > 0.0005} {
    error "nvp_vclk1 period differs from qualified 6.734 ns: $source_period"
  }

  set inventory "MODE=$mode\n"
  append inventory "PART=$part\n"
  append inventory "SLOT_SOURCE_COUNT=[llength $slot_src]\n"
  append inventory "GENERATION_SOURCE_COUNT=[llength $generation_src]\n"
  append inventory "EPOCH_SOURCE_COUNT=[llength $epoch_src]\n"
  append inventory "TOTAL_SOURCE_COUNT=[expr {[llength $slot_src] + [llength $generation_src] + [llength $epoch_src]}]\n"
  append inventory "DESTINATION_CELL_COUNT=[llength $dst_cells]\n"
  append inventory "DESTINATION_D_PIN_COUNT=[llength $dst_d]\n"
  append inventory "REQUEST_SYNC_COUNT=[llength $req_cells]\n"
  append inventory "ACK_SYNC_COUNT=[llength $ack_cells]\n"
  append inventory "USERCLK1_PERIOD_NS=$user_period\n"
  append inventory "NVP_VCLK1_PERIOD_NS=$source_period\n"
  append inventory "CANDIDATE_BOUND_NS=6.000\n"
  write_text [file join $output_dir G2B_BS3_OBJECT_INVENTORY.txt] $inventory

  write_text [file join $output_dir G2B_BS3_SLOT_SOURCES.txt] \
      "[collection_names $slot_src]\n"
  write_text [file join $output_dir G2B_BS3_GENERATION_SOURCES.txt] \
      "[collection_names $generation_src]\n"
  write_text [file join $output_dir G2B_BS3_EPOCH_SOURCES.txt] \
      "[collection_names $epoch_src]\n"
  write_text [file join $output_dir G2B_BS3_DESTINATION_CELLS.txt] \
      "[collection_names $dst_cells]\n"

  set sync_text ""
  foreach sync_cell_name $req_cell_names {
    set sync_cell [get_cells -quiet $sync_cell_name]
    append sync_text "REQUEST|[get_property NAME $sync_cell]|ASYNC_REG=TRUE\n"
  }
  foreach sync_cell_name $ack_cell_names {
    set sync_cell [get_cells -quiet $sync_cell_name]
    append sync_text "ACK|[get_property NAME $sync_cell]|ASYNC_REG=TRUE\n"
  }
  write_text [file join $output_dir G2B_BS3_SYNCHRONIZER_INVENTORY.txt] $sync_text

  if {$mode eq "inventory"} {
    write_xdc -force [file join $output_dir G2B_BS3_APPLIED_CONSTRAINTS.xdc]
  } elseif {$mode eq "slot" || $mode eq "generation" || $mode eq "epoch" ||
            $mode eq "validate_all"} {
    if {$mode eq "validate_all"} {
      write_xdc -force [file join $output_dir G2B_BS3_APPLIED_CONSTRAINTS.xdc]
      run_family_query slot $slot_src $dst_cells $dst_d $output_dir
      run_family_query generation $generation_src $dst_cells $dst_d $output_dir
      run_family_query epoch $epoch_src $dst_cells $dst_d $output_dir

      set query_start [clock milliseconds]
      write_text [file join $output_dir QUERY_STARTED.marker] \
          "MODE=full_methodology\nEPOCH_MILLISECONDS=$query_start\nTIMEOUT_SECONDS=300\nCOMMAND=report_methodology\n"
      report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} \
          -file [file join $output_dir G2B_BS3_FULL_CONTEXT_TIMING_METHODOLOGY.rpt]
      write_text [file join $output_dir QUERY_COMPLETED_FULL_METHODOLOGY.marker] \
          "MODE=full_methodology\nQUERY_RUNTIME_SECONDS=[seconds_since $query_start]\nSTATUS=PASS\n"

      # Reapply the skew-free BS2 base plus the candidate to isolate warnings
      # attributable to the replacement itself, without reopening the DCP.
      reset_timing -invalid
      read_xdc {C:/FPGA/G2B_BS2_ALT_TIMING_20260901T205518Z/G2B_BS2_CONSTRAINT_BASE.xdc}
      read_xdc $candidate_xdc
      set query_start [clock milliseconds]
      write_text [file join $output_dir QUERY_STARTED.marker] \
          "MODE=candidate_methodology\nEPOCH_MILLISECONDS=$query_start\nTIMEOUT_SECONDS=300\nCOMMAND=report_methodology\n"
      report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} \
          -file [file join $output_dir G2B_BS3_CANDIDATE_TIMING_METHODOLOGY.rpt]
      write_text [file join $output_dir QUERY_COMPLETED_CANDIDATE_METHODOLOGY.marker] \
          "MODE=candidate_methodology\nQUERY_RUNTIME_SECONDS=[seconds_since $query_start]\nSTATUS=PASS\n"

      set candidate_methodology_path [file join $output_dir G2B_BS3_CANDIDATE_TIMING_METHODOLOGY.rpt]
      set methodology_handle [open $candidate_methodology_path r]
      fconfigure $methodology_handle -translation auto -encoding utf-8
      set methodology_text [read $methodology_handle]
      close $methodology_handle
      if {![regexp {Checks found:\s+0} $methodology_text]} {
        error "candidate-attributable focused methodology checks are not zero"
      }

      set query_start [clock milliseconds]
      write_text [file join $output_dir QUERY_STARTED.marker] \
          "MODE=candidate_exception_coverage\nEPOCH_MILLISECONDS=$query_start\nTIMEOUT_SECONDS=300\nCOMMAND=report_exceptions_-coverage\n"
      report_exceptions -coverage \
          -file [file join $output_dir G2B_BS3_CANDIDATE_EXCEPTION_COVERAGE.rpt]
      write_text [file join $output_dir QUERY_COMPLETED_CANDIDATE_EXCEPTION_COVERAGE.marker] \
          "MODE=candidate_exception_coverage\nQUERY_RUNTIME_SECONDS=[seconds_since $query_start]\nSTATUS=PASS\n"

      set query_start [clock milliseconds]
      write_text [file join $output_dir QUERY_STARTED.marker] \
          "MODE=candidate_ignored_exceptions\nEPOCH_MILLISECONDS=$query_start\nTIMEOUT_SECONDS=300\nCOMMAND=report_exceptions_-ignored\n"
      report_exceptions -ignored \
          -file [file join $output_dir G2B_BS3_CANDIDATE_IGNORED_EXCEPTIONS.rpt]
      write_text [file join $output_dir QUERY_COMPLETED_CANDIDATE_IGNORED_EXCEPTIONS.marker] \
          "MODE=candidate_ignored_exceptions\nQUERY_RUNTIME_SECONDS=[seconds_since $query_start]\nSTATUS=PASS\n"
    } else {
    if {$mode eq "slot"} {
      set family_src $slot_src
    } elseif {$mode eq "generation"} {
      set family_src $generation_src
    } else {
      set family_src $epoch_src
    }
    run_family_query $mode $family_src $dst_cells $dst_d $output_dir
    }
  } elseif {$mode eq "methodology"} {
    set query_start [clock milliseconds]
    write_text [file join $output_dir QUERY_STARTED.marker] \
        "MODE=$mode\nEPOCH_MILLISECONDS=$query_start\nTIMEOUT_SECONDS=300\nCOMMAND=report_methodology\n"
    report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} \
        -file [file join $output_dir G2B_BS3_TIMING_METHODOLOGY.rpt]
    set query_elapsed [seconds_since $query_start]
    write_text [file join $output_dir QUERY_COMPLETED.marker] \
        "MODE=$mode\nQUERY_RUNTIME_SECONDS=$query_elapsed\nSTATUS=PASS\n"
  } else {
    error "unsupported mode: $mode"
  }

  set worker_elapsed [seconds_since $worker_start]
  write_text [file join $output_dir WORKER_COMPLETED.marker] \
      "MODE=$mode\nWORKER_RUNTIME_SECONDS=$worker_elapsed\nSTATUS=PASS\n"
  puts "G2B_BS3_COMPLETE mode=$mode runtime=${worker_elapsed}s"
}

if {[catch {run_bs3} failure options]} {
  puts stderr "G2B_BS3_FAILURE: $failure"
  puts stderr [dict get $options -errorinfo]
  exit 1
}
exit 0
