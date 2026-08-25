# R1h-R4 SUPER-FAST exact post-synthesis implementation continuation.
#
# One session, one exact SHA-bound synthesized checkpoint, zero source reads,
# zero constraint reads, zero synthesis, one opt/place/phys-opt/route/bit pass.
# The R4 owner prompt explicitly supersedes the older Explore settings, so the
# implementation commands below intentionally carry no strategy option.

if {$argc != 2} {
  puts stderr "usage: continue_exact_r1h_r4_super_fast.tcl EXACT_SYNTH_DCP TASK_ROOT"
  exit 2
}

set synth_dcp [file normalize [lindex $argv 0]]
set task_root [file normalize [lindex $argv 1]]
set expected_task_root [file normalize {C:/FPGA/V41_NVP_R1H_R4_SUPER_FAST}]
set expected_dcp_sha256 807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E
set expected_source_commit c4f4bfcf577c92c3021d1fe83c05878dd12e001c
set expected_source_tree 161e561f007912d73dba93c5ecd78e3cc3a6955b
set expected_part xc7a35tcsg325-2
set expected_top ahd_capture_top_xdma
set expected_vivado_version 2025.2
set expected_vivado_sw_build 6299465
set expected_prompt_path [file normalize \
  {C:/FPGA/V41_NVP_R1H_R4_SUPER_FAST/raw/OWNER_PROMPT_VERBATIM.txt}]
set expected_prompt_sha256 61EC5F55015C28B5136251148D69FEED7071364EB7EE44002DD750E4CA15E4A1
set expected_lock_path [file normalize \
  {C:/FPGA/_VCDE_SHARED_BUILD_SLOT/OWNER.md}]
set expected_lock_sha256 B6D8A5D7DC18BC1BE3D40A2499833E41C984D72AA7524C0F8E4FB806157DA0A1
set expected_lock_nonce 68370740-036b-4bae-bcda-7fd7ada4b35f
set diagnostic_max_slice_luts 19760
set max_slice_registers 37440
set standard_max_slice_luts 18720
set bit_filename ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit

set raw_dir [file join $task_root raw]
set impl_dir [file join $task_root implementation]
set final_dir [file join $task_root final]
set marker_path [file join $impl_dir R1H_R4_IMPLEMENTATION_CONSUMED.marker]
set routed_dcp [file join $impl_dir R1H_routed.dcp]
set bit_path [file join $impl_dir $bit_filename]

proc write_text {path text} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  puts -nonewline $fh $text
  close $fh
}

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines {
    puts $fh $line
  }
  close $fh
}

proc read_text {path} {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set text [read $fh]
  close $fh
  return $text
}

proc sha256_file {path} {
  if {![file isfile $path]} {
    error "cannot hash missing file: $path"
  }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set compact [string toupper \
      [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $compact]} {
      return $compact
    }
  }
  error "certutil did not return a SHA-256 digest for $path"
}

proc safe_property {object property} {
  if {[catch {get_property $property $object} value]} {
    return NOT_AVAILABLE
  }
  if {$value eq ""} {
    return EMPTY
  }
  return $value
}

proc parse_nonnegative_integer {value description} {
  set compact [string map [list "," "" " " "" "\t" ""] \
    [string trim $value]]
  if {![regexp {^[0-9]+$} $compact]} {
    error "$description is not a nonnegative integer: '$value'"
  }
  return $compact
}

proc utilization_value {text wanted} {
  set normalized_wanted [string trimright $wanted "*"]
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
    if {[llength $columns] < 7} {
      continue
    }
    set actual [string trimright [string trim [lindex $columns 1]] "*"]
    if {$actual eq $normalized_wanted} {
      return [parse_nonnegative_integer [lindex $columns 2] $wanted]
    }
  }
  error "essential utilization row '$wanted' not found"
}

proc utilization_snapshot {report_text} {
  return [dict create \
    SLICE_LUTS [utilization_value $report_text "Slice LUTs*"] \
    LOGIC_LUTS [utilization_value $report_text "LUT as Logic"] \
    LUTRAM [utilization_value $report_text "LUT as Memory"] \
    SLICE_REGISTERS [utilization_value $report_text "Slice Registers"] \
    RAMB18 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB18E1}]] \
    RAMB36 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB36E1}]]]
}

proc resource_class {slice_luts slice_registers} {
  if {$slice_registers > 37440 || $slice_luts > 19760} {
    return FAIL
  }
  if {$slice_luts <= 18720} {
    return PASS_STANDARD_MARGIN
  }
  return PASS_DIAGNOSTIC_ONLY_5_TO_10_PERCENT_MARGIN
}

proc cell_names_by_ref_patterns {ref_name patterns} {
  set result [list]
  foreach cell [get_cells -quiet -hier -filter "REF_NAME == $ref_name"] {
    set name [get_property NAME $cell]
    set name_lower [string tolower $name]
    set accepted 1
    foreach pattern $patterns {
      if {![regexp -- $pattern $name_lower]} {
        set accepted 0
        break
      }
    }
    if {$accepted} {
      lappend result $name
    }
  }
  return [lsort -dictionary -unique $result]
}

proc hierarchy_name_count {pattern} {
  set count 0
  foreach cell [get_cells -quiet -hier] {
    if {[regexp -- $pattern [string tolower [get_property NAME $cell]]]} {
      incr count
    }
  }
  return $count
}

proc mapping_snapshot {} {
  set record_region [list {r1f_failed_txn_logger}]
  set index_region [list {index_payload_store}]
  set waddr_region [list {index_payload_store} {gen_index_bram\[0\]}]
  set regaddr_region [list {index_payload_store} {gen_index_bram\[1\]}]
  set data_region [list {index_payload_store} {gen_index_bram\[2\]}]

  set record_ramb18 [cell_names_by_ref_patterns RAMB18E1 $record_region]
  set waddr_ramb18 [cell_names_by_ref_patterns RAMB18E1 $waddr_region]
  set regaddr_ramb18 [cell_names_by_ref_patterns RAMB18E1 $regaddr_region]
  set data_ramb18 [cell_names_by_ref_patterns RAMB18E1 $data_region]
  set record_ram64m [cell_names_by_ref_patterns RAM64M $record_region]
  set record_ramd64e [cell_names_by_ref_patterns RAMD64E $record_region]
  set index_ram64m [cell_names_by_ref_patterns RAM64M $index_region]
  set index_ramd64e [cell_names_by_ref_patterns RAMD64E $index_region]
  set record_fdre [cell_names_by_ref_patterns FDRE $record_region]
  set index_fdre [cell_names_by_ref_patterns FDRE $index_region]
  set record_scope_count [hierarchy_name_count {r1f_failed_txn_logger}]
  set index_scope_count [hierarchy_name_count {index_payload_store}]
  set total_ramb18 [llength [get_cells -quiet -hier -filter {REF_NAME == RAMB18E1}]]
  set known_ramb18_total [expr {
    [llength $record_ramb18] + [llength $waddr_ramb18] +
    [llength $regaddr_ramb18] + [llength $data_ramb18]
  }]
  # An incomplete hierarchy-name match is not proof of a mapping regression:
  # opt_design is allowed to rewrite names. Exact attribution is declared
  # resolved only when all nine expected payload primitives are enumerated.
  set mapping_resolved [expr {
    $record_scope_count > 0 && $index_scope_count > 0 &&
    $known_ramb18_total == 9
  }]
  set positive_regression 0
  set regression_reasons [list]
  if {$total_ramb18 < 9} {
    set positive_regression 1
    lappend regression_reasons TOTAL_DEVICE_RAMB18_BELOW_NINE_PAYLOAD_MINIMUM
  }
  if {[llength $record_fdre] + [llength $index_fdre] > 1000} {
    set positive_regression 1
    lappend regression_reasons PAYLOAD_FDRE_COUNT_ABOVE_1000
  }
  if {[llength $record_ram64m] + [llength $index_ram64m] > 0} {
    set positive_regression 1
    lappend regression_reasons PAYLOAD_RAM64M_REAPPEARED
  }
  if {[llength $record_ramd64e] + [llength $index_ramd64e] > 0} {
    set positive_regression 1
    lappend regression_reasons PAYLOAD_RAMD64E_REAPPEARED
  }
  return [dict create \
    MAPPING_QUERY [expr {$mapping_resolved ? "RESOLVED" : "NOT_RESOLVED_AFTER_OPT"}] \
    RECORD_SCOPE_CELL_COUNT $record_scope_count \
    INDEX_SCOPE_CELL_COUNT $index_scope_count \
    TOTAL_DEVICE_RAMB18 $total_ramb18 \
    FAILED_RECORD_PAYLOAD_RAMB18 [llength $record_ramb18] \
    WADDR_INDEX_PAYLOAD_RAMB18 [llength $waddr_ramb18] \
    REGADDR_INDEX_PAYLOAD_RAMB18 [llength $regaddr_ramb18] \
    DATA_INDEX_PAYLOAD_RAMB18 [llength $data_ramb18] \
    KNOWN_R1H_PAYLOAD_RAMB18_TOTAL $known_ramb18_total \
    FAILED_RECORD_PAYLOAD_FDRE [llength $record_fdre] \
    INDEX_PAYLOAD_FDRE_TOTAL [llength $index_fdre] \
    FAILED_RECORD_PAYLOAD_RAM64M [llength $record_ram64m] \
    FAILED_RECORD_PAYLOAD_RAMD64E [llength $record_ramd64e] \
    INDEX_PAYLOAD_RAM64M [llength $index_ram64m] \
    INDEX_PAYLOAD_RAMD64E [llength $index_ramd64e] \
    POSITIVE_MAPPING_REGRESSION [expr {$positive_regression ? "YES" : "NO"}] \
    REGRESSION_REASONS [expr {[llength $regression_reasons] == 0 ? "NONE" : [join $regression_reasons ,]}] \
    RECORD_RAMB18_CELLS $record_ramb18 \
    WADDR_RAMB18_CELLS $waddr_ramb18 \
    REGADDR_RAMB18_CELLS $regaddr_ramb18 \
    DATA_RAMB18_CELLS $data_ramb18]
}

proc write_mapping {path mapping} {
  set lines [list \
    "MAPPING_QUERY=[dict get $mapping MAPPING_QUERY]" \
    "RECORD_SCOPE_CELL_COUNT=[dict get $mapping RECORD_SCOPE_CELL_COUNT]" \
    "INDEX_SCOPE_CELL_COUNT=[dict get $mapping INDEX_SCOPE_CELL_COUNT]" \
    "TOTAL_DEVICE_RAMB18=[dict get $mapping TOTAL_DEVICE_RAMB18]" \
    "FAILED_RECORD_PAYLOAD_RAMB18=[dict get $mapping FAILED_RECORD_PAYLOAD_RAMB18]" \
    "WADDR_INDEX_PAYLOAD_RAMB18=[dict get $mapping WADDR_INDEX_PAYLOAD_RAMB18]" \
    "REGADDR_INDEX_PAYLOAD_RAMB18=[dict get $mapping REGADDR_INDEX_PAYLOAD_RAMB18]" \
    "DATA_INDEX_PAYLOAD_RAMB18=[dict get $mapping DATA_INDEX_PAYLOAD_RAMB18]" \
    "KNOWN_R1H_PAYLOAD_RAMB18_TOTAL=[dict get $mapping KNOWN_R1H_PAYLOAD_RAMB18_TOTAL]" \
    "FAILED_RECORD_PAYLOAD_FDRE=[dict get $mapping FAILED_RECORD_PAYLOAD_FDRE]" \
    "INDEX_PAYLOAD_FDRE_TOTAL=[dict get $mapping INDEX_PAYLOAD_FDRE_TOTAL]" \
    "FAILED_RECORD_PAYLOAD_RAM64M=[dict get $mapping FAILED_RECORD_PAYLOAD_RAM64M]" \
    "FAILED_RECORD_PAYLOAD_RAMD64E=[dict get $mapping FAILED_RECORD_PAYLOAD_RAMD64E]" \
    "INDEX_PAYLOAD_RAM64M=[dict get $mapping INDEX_PAYLOAD_RAM64M]" \
    "INDEX_PAYLOAD_RAMD64E=[dict get $mapping INDEX_PAYLOAD_RAMD64E]" \
    "POSITIVE_MAPPING_REGRESSION=[dict get $mapping POSITIVE_MAPPING_REGRESSION]" \
    "REGRESSION_REASONS=[dict get $mapping REGRESSION_REASONS]"]
  foreach key {RECORD_RAMB18_CELLS WADDR_RAMB18_CELLS REGADDR_RAMB18_CELLS DATA_RAMB18_CELLS} {
    foreach cell [dict get $mapping $key] {
      lappend lines "$key=$cell"
    }
  }
  write_lines $path $lines
}

proc try_parse_report_count {text patterns description} {
  foreach pattern $patterns {
    if {[regexp -nocase -- $pattern $text -> value]} {
      return [parse_nonnegative_integer $value $description]
    }
  }
  return -1
}

proc verify_no_output_collision {paths} {
  foreach path $paths {
    if {[file exists $path]} {
      error "one-shot implementation output already exists: $path"
    }
  }
}

set stage PRECONSUMPTION
set opt_runs 0
set place_runs 0
set phys_opt_runs 0
set route_runs 0
set bit_runs 0
set post_opt_resource_class NOT_RUN
set final_resource_class NOT_RUN
set place_status NOT_RUN
set route_status NOT_RUN
set bit_sha256 NOT_GENERATED
set routed_dcp_sha256 NOT_GENERATED

if {$task_root ne $expected_task_root} {
  puts stderr "BLOCKED_R1H_R4_TASK_ROOT_IDENTITY"
  exit 1
}
if {![file isfile $synth_dcp] || [file size $synth_dcp] < 1000000} {
  puts stderr "BLOCKED_R1H_R4_ACTUAL_SYNTH_DCP_UNAVAILABLE"
  exit 1
}
if {[sha256_file $synth_dcp] ne $expected_dcp_sha256} {
  puts stderr "BLOCKED_R1H_R4_SYNTH_DCP_SHA256_MISMATCH"
  exit 1
}
if {![file isfile $expected_prompt_path] ||
    [sha256_file $expected_prompt_path] ne $expected_prompt_sha256} {
  puts stderr "BLOCKED_R1H_R4_OWNER_PROMPT_IDENTITY"
  exit 1
}
if {![file isfile $expected_lock_path] ||
    [sha256_file $expected_lock_path] ne $expected_lock_sha256} {
  puts stderr "BLOCKED_R1H_R4_SHARED_LOCK_IDENTITY"
  exit 1
}
set lock_text [read_text $expected_lock_path]
if {[string first "STATUS=HELD" $lock_text] < 0 ||
    [string first "LOCK_NONCE=$expected_lock_nonce" $lock_text] < 0 ||
    [string first "TASK=V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE" $lock_text] < 0} {
  puts stderr "BLOCKED_R1H_R4_SHARED_LOCK_CONTENT"
  exit 1
}
if {[file exists $marker_path]} {
  puts stderr "BLOCKED_R1H_R4_IMPLEMENTATION_ALREADY_CONSUMED"
  exit 1
}

set vivado_short [string trim [version -short]]
set vivado_detail [version]
set vivado_sw_build UNKNOWN
regexp {SW Build[ \t]+([0-9]+)} $vivado_detail -> vivado_sw_build
if {$vivado_short ne $expected_vivado_version ||
    $vivado_sw_build ne $expected_vivado_sw_build} {
  puts stderr "BLOCKED_R1H_R4_VIVADO_IDENTITY"
  exit 1
}

verify_no_output_collision [list \
  $routed_dcp $bit_path \
  [file join $impl_dir R1H_R4_IMPLEMENTATION_RESULT.txt] \
  [file join $final_dir R1H_R4_IMPLEMENTATION_TERMINAL_FAILURE.txt]]
file mkdir $raw_dir
file mkdir $impl_dir
file mkdir $final_dir
set marker_fh [open $marker_path {WRONLY CREAT EXCL}]
fconfigure $marker_fh -encoding utf-8 -translation lf
puts $marker_fh "IMPLEMENTATION_CONTINUATION_SESSIONS=1"
puts $marker_fh "SYNTH_DESIGN_INVOCATIONS_THIS_TASK=0"
puts $marker_fh "R1H_SYNTH_DCP_SHA256=$expected_dcp_sha256"
puts $marker_fh "OWNER_PROMPT_SHA256=$expected_prompt_sha256"
puts $marker_fh "SHARED_LOCK_SHA256=$expected_lock_sha256"
puts $marker_fh "SHARED_LOCK_NONCE=$expected_lock_nonce"
puts $marker_fh "UTC=[clock format [clock seconds] -gmt 1 -format {%Y-%m-%dT%H:%M:%SZ}]"
close $marker_fh

set flow_rc [catch {
  set stage OPEN_EXACT_DCP
  open_checkpoint $synth_dcp
  if {[current_design] eq "" || [llength [get_cells -quiet -hier]] == 0} {
    error "opened checkpoint has no current design or netlist cells"
  }
  set actual_part [string tolower [safe_property [current_design] PART]]
  if {$actual_part ne $expected_part} {
    error "wrong checkpoint part: expected $expected_part, got $actual_part"
  }

  # Same-session state evidence. Missing report formatting is explicitly not a
  # blocker in R4; exact checkpoint SHA is the primary state/provenance anchor.
  set design_state NOT_RESOLVED_REPORT_FORMAT_NONBLOCKING
  set initial_state_report_status REPORT_FAILED_NONBLOCKING
  if {![catch {report_utilization -return_string} initial_util_text]} {
    set initial_state_report_status PASS
    if {[regexp -nocase {Design State[ \t]*:[ \t]*([^\r\n|]+)} \
        $initial_util_text -> state_value]} {
      set design_state [string toupper [string trim $state_value]]
      if {[string first "ROUTED" $design_state] >= 0 ||
          [string first "PLACED" $design_state] >= 0} {
        error "exact input checkpoint is not synthesized/unplaced: $design_state"
      }
    }
  }
  write_lines [file join $impl_dir R1H_R4_SAME_SESSION_DCP_IDENTITY.txt] [list \
    "R1H_SYNTH_DCP=$synth_dcp" \
    "R1H_SYNTH_DCP_SHA256=$expected_dcp_sha256" \
    "PART=$actual_part" \
    "TOP_FROM_AUTHORITATIVE_BUILD_MANIFEST=$expected_top" \
    "DESIGN_STATE=$design_state" \
    "INITIAL_STATE_REPORT_STATUS=$initial_state_report_status" \
    "R1H_SOURCE_COMMIT=$expected_source_commit" \
    "R1H_SOURCE_TREE=$expected_source_tree" \
    "SOURCE_PROVENANCE=PASS_BY_EXACT_SHA_BOUND_DCP" \
    "RAW_NONEMPTY_ROUTE_PROPERTY_QUERIED=NO" \
    "RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE=NO" \
    "VIVADO_VERSION=$vivado_short" \
    "VIVADO_SW_BUILD=$vivado_sw_build"]

  set stage OPT_DESIGN
  set opt_runs 1
  opt_design

  set post_opt_util_text [report_utilization -return_string]
  write_text [file join $impl_dir R1H_R4_POST_OPT_UTILIZATION.rpt] $post_opt_util_text
  set post_opt_util [utilization_snapshot $post_opt_util_text]
  set post_opt_resource_class [resource_class \
    [dict get $post_opt_util SLICE_LUTS] \
    [dict get $post_opt_util SLICE_REGISTERS]]
  set post_opt_mapping [mapping_snapshot]
  write_mapping [file join $impl_dir R1H_R4_POST_OPT_MAPPING.txt] $post_opt_mapping
  set mapping_nonresolution_action NOT_APPLICABLE
  if {[dict get $post_opt_mapping MAPPING_QUERY] ne "RESOLVED"} {
    set mapping_nonresolution_action \
      CONTINUE_EXACT_INPUT_DCP_MAPPING_ALREADY_PROVEN
  }
  write_lines [file join $impl_dir R1H_R4_POST_OPT_HARD_GATE.txt] [list \
    "OPT_DESIGN_INVOCATIONS=$opt_runs" \
    "OPT_DESIGN_COMMAND=opt_design" \
    "POST_OPT_SLICE_LUTS=[dict get $post_opt_util SLICE_LUTS]" \
    "POST_OPT_LOGIC_LUTS=[dict get $post_opt_util LOGIC_LUTS]" \
    "POST_OPT_LUTRAM=[dict get $post_opt_util LUTRAM]" \
    "POST_OPT_SLICE_REGISTERS=[dict get $post_opt_util SLICE_REGISTERS]" \
    "POST_OPT_TOTAL_RAMB18E1=[dict get $post_opt_util RAMB18]" \
    "POST_OPT_TOTAL_RAMB36E1=[dict get $post_opt_util RAMB36]" \
    "POST_OPT_RESOURCE_CLASS=$post_opt_resource_class" \
    "MAPPING_QUERY=[dict get $post_opt_mapping MAPPING_QUERY]" \
    "POSITIVE_MAPPING_REGRESSION=[dict get $post_opt_mapping POSITIVE_MAPPING_REGRESSION]" \
    "MAPPING_NONRESOLUTION_ACTION=$mapping_nonresolution_action"]
  if {$post_opt_resource_class eq "FAIL"} {
    error "BLOCKED_R1H_R4_POST_OPT_RESOURCE_GATE"
  }
  if {[dict get $post_opt_mapping POSITIVE_MAPPING_REGRESSION] eq "YES"} {
    error "BLOCKED_R1H_R4_POSITIVE_POST_OPT_MAPPING_REGRESSION"
  }

  set stage PLACE_DESIGN
  set place_runs 1
  place_design
  set place_status PASS

  set stage PHYS_OPT_DESIGN
  set phys_opt_runs 1
  phys_opt_design

  set stage ROUTE_DESIGN
  set route_runs 1
  route_design

  set route_report [file join $impl_dir R1H_R4_ROUTE_STATUS.rpt]
  report_route_status -file $route_report
  set route_text [read_text $route_report]
  set route_errors [try_parse_report_count $route_text [list \
    {# of nets with routing errors[^:]*:[ \t]*([0-9,]+)} \
    {number of nets with routing errors[^:]*:[ \t]*([0-9,]+)}] ROUTE_ERRORS]
  set unrouted_nets [try_parse_report_count $route_text [list \
    {# of unrouted nets[^:]*:[ \t]*([0-9,]+)} \
    {number of unrouted nets[^:]*:[ \t]*([0-9,]+)}] UNROUTED_NETS]
  set routable_nets [try_parse_report_count $route_text [list \
    {# of routable nets[^:]*:[ \t]*([0-9,]+)} \
    {number of routable nets[^:]*:[ \t]*([0-9,]+)}] ROUTABLE_NETS]
  set fully_routed_nets [try_parse_report_count $route_text [list \
    {# of fully routed nets[^:]*:[ \t]*([0-9,]+)} \
    {number of fully routed nets[^:]*:[ \t]*([0-9,]+)}] FULLY_ROUTED_NETS]
  if {$unrouted_nets < 0 && $routable_nets >= 0 &&
      $fully_routed_nets >= 0 && $fully_routed_nets <= $routable_nets} {
    set unrouted_nets [expr {$routable_nets - $fully_routed_nets}]
  }
  set route_count_parse [expr {
    $route_errors >= 0 && $unrouted_nets >= 0 ? "RESOLVED" :
    "NOT_RESOLVED_REPORT_FORMAT_NONBLOCKING"
  }]
  if {$route_errors > 0 || $unrouted_nets > 0} {
    error "BLOCKED_R1H_R4_ROUTE_ERRORS_OR_UNROUTED_NETS"
  }
  set route_status PASS

  set timing_report [file join $impl_dir R1H_R4_TIMING_SUMMARY.rpt]
  report_timing_summary -delay_type min_max -max_paths 1000 -file $timing_report
  set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
  set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
  if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1} {
    error "required global timing path class is empty"
  }
  set wns [get_property SLACK $worst_setup]
  set whs [get_property SLACK $worst_hold]
  if {![string is double -strict $wns] || ![string is double -strict $whs]} {
    error "global timing slack is not numeric"
  }
  set failing_setup_paths [llength [get_timing_paths -quiet -delay_type max \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold_paths [llength [get_timing_paths -quiet -delay_type min \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  if {$wns < 0.0 || $whs <= 0.0 ||
      $failing_setup_paths != 0 || $failing_hold_paths != 0} {
    error "BLOCKED_R1H_R4_TIMING_GATE"
  }

  set final_util_text [report_utilization -return_string]
  write_text [file join $impl_dir R1H_R4_FINAL_UTILIZATION.rpt] $final_util_text
  set final_util [utilization_snapshot $final_util_text]
  set final_resource_class [resource_class \
    [dict get $final_util SLICE_LUTS] \
    [dict get $final_util SLICE_REGISTERS]]
  if {$final_resource_class eq "FAIL"} {
    error "BLOCKED_R1H_R4_FINAL_RESOURCE_GATE"
  }

  set drc_report [file join $impl_dir R1H_R4_DRC.rpt]
  report_drc -file $drc_report
  set drc_errors 0
  set drc_critical_warnings 0
  set drc_warnings 0
  foreach violation [get_drc_violations -quiet] {
    set severity [string toupper [get_property SEVERITY $violation]]
    switch -- $severity {
      ERROR {incr drc_errors}
      {CRITICAL WARNING} {incr drc_critical_warnings}
      WARNING {incr drc_warnings}
    }
  }
  if {$drc_errors != 0 || $drc_critical_warnings != 0} {
    error "BLOCKED_R1H_R4_DRC_GATE"
  }

  set cdc_report_status REPORT_FAILED_NONBLOCKING
  set cdc_critical NOT_AVAILABLE
  set cdc_unknown NOT_AVAILABLE
  set cdc_error NONE
  if {[catch {report_cdc -details -return_string} cdc_text cdc_options]} {
    set cdc_error $cdc_text
    write_lines [file join $impl_dir R1H_R4_CDC_OPTIONAL_FAILURE.txt] [list \
      "CDC_REPORT_STATUS=REPORT_FAILED_NONBLOCKING" \
      "CDC_REPORT_ERROR=$cdc_error"]
  } else {
    set cdc_report_status PASS
    write_text [file join $impl_dir R1H_R4_CDC.rpt] $cdc_text
    set cdc_critical [regexp -all -nocase -line {CDC-[0-9]+[^\r\n]*Critical} $cdc_text]
    set cdc_unknown [regexp -all -nocase -line {CDC-[0-9]+[^\r\n]*Unknown} $cdc_text]
    if {$cdc_critical != 0 || $cdc_unknown != 0} {
      error "BLOCKED_R1H_R4_CDC_CRITICAL_OR_UNKNOWN"
    }
  }

  write_checkpoint -force $routed_dcp
  if {![file isfile $routed_dcp] || [file size $routed_dcp] == 0} {
    error "routed checkpoint was not created"
  }
  set routed_dcp_sha256 [sha256_file $routed_dcp]

  write_lines [file join $impl_dir R1H_R4_PRE_BITSTREAM_HARD_GATE.txt] [list \
    "PLACE=$place_status" \
    "ROUTE=$route_status" \
    "ROUTE_ERRORS=$route_errors" \
    "UNROUTED_NETS=$unrouted_nets" \
    "ROUTE_COUNT_PARSE=$route_count_parse" \
    "RAW_NONEMPTY_ROUTE_PROPERTY_QUERIED=NO" \
    "RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE=NO" \
    "WNS=$wns" \
    "WHS=$whs" \
    "FAILING_SETUP_PATHS=$failing_setup_paths" \
    "FAILING_HOLD_PATHS=$failing_hold_paths" \
    "FINAL_SLICE_LUTS=[dict get $final_util SLICE_LUTS]" \
    "FINAL_SLICE_REGISTERS=[dict get $final_util SLICE_REGISTERS]" \
    "FINAL_RESOURCE_CLASS=$final_resource_class" \
    "DRC_ERRORS=$drc_errors" \
    "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" \
    "DRC_WARNINGS=$drc_warnings" \
    "REQP_1839_COUNT_GATE=DISABLED_OWNER_SUPER_FAST" \
    "CDC_REPORT_STATUS=$cdc_report_status" \
    "CDC_CRITICAL=$cdc_critical" \
    "CDC_UNKNOWN=$cdc_unknown" \
    "R1H_ROUTED_DCP_SHA256=$routed_dcp_sha256" \
    "R1H_R4_PRE_BITSTREAM_HARD_GATE=PASS"]

  set stage WRITE_BITSTREAM
  set bit_runs 1
  write_bitstream $bit_path
  if {![file isfile $bit_path] || [file size $bit_path] == 0} {
    error "write_bitstream returned without a nonzero bitstream"
  }
  set bit_sha256 [sha256_file $bit_path]

  write_lines [file join $impl_dir R1H_R4_IMPLEMENTATION_RESULT.txt] [list \
    "TASK=V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE" \
    "EXPERIMENT_NAME=R1h" \
    "CONTINUATION_REVISION=R4" \
    "SUPER_FAST_OWNER_RISK_ACCEPTED=YES" \
    "SOURCE_FILE_MUTATIONS=0" \
    "SOURCE_COMMITS=0" \
    "SYNTH_DESIGN_INVOCATIONS_THIS_TASK=0" \
    "R1H_SOURCE_COMMIT=$expected_source_commit" \
    "R1H_SOURCE_TREE=$expected_source_tree" \
    "R1H_SYNTH_DCP_SHA256=$expected_dcp_sha256" \
    "RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE=NO" \
    "OPT_DESIGN_INVOCATIONS=$opt_runs" \
    "PLACE_DESIGN_INVOCATIONS=$place_runs" \
    "PHYS_OPT_DESIGN_INVOCATIONS=$phys_opt_runs" \
    "ROUTE_DESIGN_INVOCATIONS=$route_runs" \
    "WRITE_BITSTREAM_INVOCATIONS=$bit_runs" \
    "POST_OPT_SLICE_LUTS=[dict get $post_opt_util SLICE_LUTS]" \
    "POST_OPT_SLICE_REGISTERS=[dict get $post_opt_util SLICE_REGISTERS]" \
    "POST_OPT_RESOURCE_CLASS=$post_opt_resource_class" \
    "POST_OPT_MAPPING_QUERY=[dict get $post_opt_mapping MAPPING_QUERY]" \
    "POST_OPT_POSITIVE_MAPPING_REGRESSION=[dict get $post_opt_mapping POSITIVE_MAPPING_REGRESSION]" \
    "PLACE=$place_status" \
    "ROUTE=$route_status" \
    "ROUTE_ERRORS=$route_errors" \
    "UNROUTED_NETS=$unrouted_nets" \
    "WNS=$wns" \
    "WHS=$whs" \
    "FAILING_SETUP_PATHS=$failing_setup_paths" \
    "FAILING_HOLD_PATHS=$failing_hold_paths" \
    "FINAL_SLICE_LUTS=[dict get $final_util SLICE_LUTS]" \
    "FINAL_SLICE_REGISTERS=[dict get $final_util SLICE_REGISTERS]" \
    "FINAL_RESOURCE_CLASS=$final_resource_class" \
    "DRC_ERRORS=$drc_errors" \
    "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" \
    "CDC_REPORT_STATUS=$cdc_report_status" \
    "CDC_CRITICAL=$cdc_critical" \
    "CDC_UNKNOWN=$cdc_unknown" \
    "R1H_BIT_SHA256=$bit_sha256" \
    "R1H_ROUTED_DCP_SHA256=$routed_dcp_sha256" \
    "SOURCE_COMMIT_TO_BIT_PROVENANCE=PASS_BY_EXACT_SHA_BOUND_DCP" \
    "DIAGNOSTIC_ONLY_IMAGE=YES" \
    "PRODUCTION_ACCEPTANCE_CLAIM=NO" \
    "R1H_R4_IMPLEMENTATION_RESULT=PASS"]

  close_design
  puts "R1H_R4_IMPLEMENTATION_RESULT=PASS"
  puts "R1H_BIT_SHA256=$bit_sha256"
} flow_error flow_options]

if {$flow_rc != 0} {
  catch {close_design}
  set error_info UNKNOWN
  if {[dict exists $flow_options -errorinfo]} {
    set error_info [dict get $flow_options -errorinfo]
  }
  write_lines [file join $final_dir R1H_R4_IMPLEMENTATION_TERMINAL_FAILURE.txt] [list \
    "IMPLEMENTATION_CONTINUATION_CONSUMED=YES" \
    "TERMINAL_STAGE=$stage" \
    "SYNTH_DESIGN_INVOCATIONS_THIS_TASK=0" \
    "OPT_DESIGN_INVOCATIONS=$opt_runs" \
    "PLACE_DESIGN_INVOCATIONS=$place_runs" \
    "PHYS_OPT_DESIGN_INVOCATIONS=$phys_opt_runs" \
    "ROUTE_DESIGN_INVOCATIONS=$route_runs" \
    "WRITE_BITSTREAM_INVOCATIONS=$bit_runs" \
    "POST_OPT_RESOURCE_CLASS=$post_opt_resource_class" \
    "FINAL_RESOURCE_CLASS=$final_resource_class" \
    "R1H_BIT_SHA256=$bit_sha256" \
    "R1H_ROUTED_DCP_SHA256=$routed_dcp_sha256" \
    "TERMINAL_ERROR=$flow_error" \
    "ERROR_INFO_BEGIN" \
    $error_info \
    "ERROR_INFO_END"]
  puts stderr "R1H_R4_IMPLEMENTATION_TERMINAL_FAILURE=$flow_error"
  exit 1
}

exit 0
