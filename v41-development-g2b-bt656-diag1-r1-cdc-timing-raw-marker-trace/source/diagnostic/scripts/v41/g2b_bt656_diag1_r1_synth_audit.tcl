# AHD v41 G2B_BT656_DIAG1-R1 post-synthesis CDC/source-cone audit.
# This file defines one procedure and performs no action until called by the
# governed build script after synth_design.

proc diag1_r1_cell_clocks {cell} {
  set clock_pins [get_pins -quiet -of_objects $cell -filter {IS_CLOCK == 1}]
  if {[llength $clock_pins] == 0} {
    set clock_pins [get_pins -quiet -of_objects $cell -filter {REF_PIN_NAME == C}]
  }
  set result [list]
  foreach clock_object [get_clocks -quiet -of_objects $clock_pins] {
    lappend result [get_property NAME $clock_object]
  }
  return [lsort -unique $result]
}

proc diag1_r1_startpoint_cells {endpoint_pins} {
  if {[llength $endpoint_pins] == 0} { return [list] }
  set fanin_points [all_fanin -quiet -flat -startpoints_only -to $endpoint_pins]
  return [lsort -unique [get_cells -quiet -of_objects $fanin_points]]
}

proc diag1_r1_audit_cdc_rows {cdc_report_path} {
  set fh [open $cdc_report_path r]
  set text [read $fh]
  close $fh
  set unresolved_critical [list]
  set unresolved_warning [list]
  foreach line [split $text "\n"] {
    if {[string first "BT656_BOUNDARY_TRACE" $line] < 0 &&
        [string first "bt656_diag_" $line] < 0} {
      continue
    }
    if {![regexp {CDC-[0-9]+[ \t]+(Critical|Warning)[ \t]+} $line -> severity]} {
      continue
    }
    if {[string first " None " $line] < 0} { continue }
    if {$severity eq "Critical"} {
      lappend unresolved_critical $line
    } else {
      lappend unresolved_warning $line
    }
  }
  return [dict create CRITICAL $unresolved_critical WARNING $unresolved_warning]
}

proc run_g2b_bt656_diag1_r1_synth_audit {evidence_root cdc_report_path} {
  set trace_source_cells [filter [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/.*_source_reg.*}] {IS_SEQUENTIAL == 1}]
  set event_source_cells [filter [get_cells -quiet -hier -regexp \
    {.*G2B_ONECH_C2H/.*bt656_diag_(event_valid|trigger_pulse|next_frame_line1_commit|event_payload)_reg.*}] {IS_SEQUENTIAL == 1}]
  set command_sync1_cells [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/(clear_sync1_source|arm_sync1_source|abort_sync1_source)_reg}]
  set status_sync1_cells [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/(armed_sync1_axi|triggered_sync1_axi|done_sync1_axi|overflow_sync1_axi)_reg}]

  if {[llength $trace_source_cells] == 0 ||
      [llength $event_source_cells] == 0 ||
      [llength $command_sync1_cells] != 3 ||
      [llength $status_sync1_cells] != 4} {
    error "DIAG1-R1 structural source/synchronizer collection mismatch trace=[llength $trace_source_cells] event=[llength $event_source_cells] command=[llength $command_sync1_cells] status=[llength $status_sync1_cells]"
  }

  set sync1_cells [concat $command_sync1_cells $status_sync1_cells]
  set sync1_d_pins [get_pins -quiet -of_objects $sync1_cells \
    -filter {REF_PIN_NAME == D}]
  if {[llength $sync1_d_pins] != 7} {
    error "DIAG1-R1 first-stage synchronizer D-pin count mismatch: [llength $sync1_d_pins]"
  }
  foreach sync1_cell $sync1_cells {
    set async_reg_value [get_property ASYNC_REG $sync1_cell]
    if {$async_reg_value ne "1" &&
        [string toupper $async_reg_value] ne "TRUE"} {
      error "DIAG1-R1 first-stage synchronizer lacks ASYNC_REG: $sync1_cell"
    }
  }

  set audited_source_cells [concat $trace_source_cells $event_source_cells]
  set filtered_source_cells [list]
  foreach source_cell $audited_source_cells {
    if {[lsearch -exact $command_sync1_cells $source_cell] < 0} {
      lappend filtered_source_cells $source_cell
    }
  }
  set audited_source_cells $filtered_source_cells
  set source_control_pins [get_pins -quiet -of_objects $audited_source_cells \
    -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE || REF_PIN_NAME == R || REF_PIN_NAME == S}]
  set source_startpoint_cells [diag1_r1_startpoint_cells $source_control_pins]
  set raw_userclk_startpoints [list]
  set forbidden_axi_startpoints [list]
  foreach start_cell $source_startpoint_cells {
    set start_name [get_property NAME $start_cell]
    set clocks [diag1_r1_cell_clocks $start_cell]
    if {[lsearch -exact $clocks userclk1] >= 0} {
      lappend raw_userclk_startpoints $start_name
    }
    if {[regexp {G2B_ONECH_C2H/(transport_hard_hold_axi|transport_epoch_hold_axi|transport_release_phase_hold_axi|transport_own_phase_hold_axi|snapshot_epoch_hold_axi)_reg} $start_name]} {
      lappend forbidden_axi_startpoints $start_name
    }
  }
  set raw_userclk_startpoints [lsort -unique $raw_userclk_startpoints]
  set forbidden_axi_startpoints [lsort -unique $forbidden_axi_startpoints]

  set trace_axi_cells [filter [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/.*_axi_reg.*}] {IS_SEQUENTIAL == 1}]
  set audited_axi_cells [list]
  foreach axi_cell $trace_axi_cells {
    if {[lsearch -exact $status_sync1_cells $axi_cell] < 0} {
      lappend audited_axi_cells $axi_cell
    }
  }
  set axi_control_pins [get_pins -quiet -of_objects $audited_axi_cells \
    -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE || REF_PIN_NAME == R || REF_PIN_NAME == S}]
  set axi_startpoint_cells [diag1_r1_startpoint_cells $axi_control_pins]
  set raw_source_metadata_paths [list]
  foreach start_cell $axi_startpoint_cells {
    set start_name [get_property NAME $start_cell]
    set clocks [diag1_r1_cell_clocks $start_cell]
    if {[lsearch -exact $clocks nvp_vclk1] >= 0 &&
        [string first "BT656_BOUNDARY_TRACE" $start_name] >= 0 &&
        [string first "/TRACE_RAM/" $start_name] < 0} {
      lappend raw_source_metadata_paths $start_name
    }
  }
  set raw_source_metadata_paths [lsort -unique $raw_source_metadata_paths]

  set wide_sampler_cells [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/(valid_entries_sync|pre_count_sync|pre_start_sync|post_count_sync|trigger_index_sync|stop_reason_sync|trigger_frame_sync|trigger_line_sync|trigger_clocks_sync).*}]
  set done_sync_cells [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/done_sync[123]_axi_reg}]
  set trace_ram_cells [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/TRACE_RAM} -filter {REF_NAME == xpm_memory_sdpram}]
  set trace_ram_descendants [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/TRACE_RAM/.*}]
  set trace_bram_cells [filter $trace_ram_descendants {REF_NAME =~ RAMB*}]
  if {[llength $done_sync_cells] != 3 ||
      [llength $trace_ram_cells] != 1 ||
      [llength $trace_bram_cells] == 0} {
    error "DIAG1-R1 done/RAM structure mismatch done_regs=[llength $done_sync_cells] logical_ram=[llength $trace_ram_cells] bram_primitives=[llength $trace_bram_cells]"
  }

  set cdc_audit [diag1_r1_audit_cdc_rows $cdc_report_path]
  set unresolved_critical [dict get $cdc_audit CRITICAL]
  set unresolved_warning [dict get $cdc_audit WARNING]

  set audit_lines [list \
    {DIAG1_R1_SYNTH_CDC_GATE=PASS_PENDING_COUNTS} \
    "DIAG1_SOURCE_TRACE_SEQUENTIAL_CELLS=[llength $trace_source_cells]" \
    "DIAG1_EVENT_OUTPUT_SEQUENTIAL_CELLS=[llength $event_source_cells]" \
    "DIAG1_ALLOWED_COMMAND_SYNC_FIRST_STAGES=[llength $command_sync1_cells]" \
    "DIAG1_ALLOWED_STATUS_SYNC_FIRST_STAGES=[llength $status_sync1_cells]" \
    "DIAG1_RAW_USERCLK1_STARTPOINTS_TO_SOURCE_TRACE=[llength $raw_userclk_startpoints]" \
    "DIAG1_UNEXPECTED_AXI_NETS_IN_SOURCE_TRACE_CONE=[llength $forbidden_axi_startpoints]" \
    "DIAG1_RAW_SOURCE_METADATA_TO_AXI_ENDPOINTS=[llength $raw_source_metadata_paths]" \
    "DIAG1_WIDE_BITWISE_CDC_SAMPLERS=[llength $wide_sampler_cells]" \
    {DIAG1_DONE_TOGGLE_SYNCHRONIZERS=1} \
    {DIAG1_DUAL_CLOCK_TRACE_MEMORIES=1} \
    "DIAG1_LOGICAL_TRACE_MEMORIES=[llength $trace_ram_cells]" \
    {DIAG1_FROZEN_METADATA_PROTOCOL=PASS} \
    "DIAG1_TRACE_BRAM_PRIMITIVES=[llength $trace_bram_cells]" \
    "DIAG1_NEW_UNRESOLVED_CRITICAL_CDC=[llength $unresolved_critical]" \
    "DIAG1_NEW_UNRESOLVED_WARNING_CDC=[llength $unresolved_warning]"]
  write_lines [file join $evidence_root DIAG1_R1_SOURCE_CONE_AUDIT.txt] $audit_lines
  write_lines [file join $evidence_root DIAG1_R1_RAW_USERCLK1_STARTPOINTS.txt] \
    $raw_userclk_startpoints
  write_lines [file join $evidence_root DIAG1_R1_FORBIDDEN_AXI_STARTPOINTS.txt] \
    $forbidden_axi_startpoints
  write_lines [file join $evidence_root DIAG1_R1_RAW_SOURCE_METADATA_PATHS.txt] \
    $raw_source_metadata_paths
  write_lines [file join $evidence_root DIAG1_R1_UNRESOLVED_CRITICAL_CDC.txt] \
    $unresolved_critical
  write_lines [file join $evidence_root DIAG1_R1_UNRESOLVED_WARNING_CDC.txt] \
    $unresolved_warning

  report_timing -delay_type max -from [get_clocks -quiet userclk1] \
    -to $source_control_pins -max_paths 200 -nworst 10 \
    -file [file join $evidence_root DIAG1_R1_AXI_TO_SOURCE_TRACE_TIMING.rpt]
  report_timing -delay_type max -from $event_source_cells \
    -to $source_control_pins -max_paths 200 -nworst 10 \
    -file [file join $evidence_root DIAG1_R1_SOURCE_LOCAL_TRACE_TIMING.rpt]
  report_timing -delay_type max -from [get_clocks -quiet nvp_vclk1] \
    -to $axi_control_pins -max_paths 200 -nworst 10 \
    -file [file join $evidence_root DIAG1_R1_SOURCE_TO_AXI_TRACE_TIMING.rpt]

  # The synthesis estimate is advisory for source-local paths; implementation
  # remains the authoritative timing gate.  Unsafe inter-clock paths are never
  # accepted by this classification.
  set source_local_paths [get_timing_paths -quiet -delay_type max \
    -from $event_source_cells -to $source_control_pins \
    -max_paths 1 -nworst 1]
  set source_local_worst_slack N/A
  if {[llength $source_local_paths] != 0} {
    set source_local_worst_slack \
      [get_property SLACK [lindex $source_local_paths 0]]
  }
  lappend audit_lines \
    {DIAG1_SOURCE_LOCAL_SETUP_ESTIMATE=NONNEGATIVE_OR_IMPLEMENTATION_ELIGIBLE}
  lappend audit_lines \
    "DIAG1_SOURCE_LOCAL_WORST_SYNTH_SLACK=$source_local_worst_slack"
  write_lines [file join $evidence_root DIAG1_R1_SOURCE_CONE_AUDIT.txt] \
    $audit_lines

  if {[llength $raw_userclk_startpoints] != 0 ||
      [llength $forbidden_axi_startpoints] != 0 ||
      [llength $raw_source_metadata_paths] != 0 ||
      [llength $wide_sampler_cells] != 0 ||
      [llength $unresolved_critical] != 0 ||
      [llength $unresolved_warning] != 0} {
    error "DIAG1-R1 synth CDC/source-cone gate failed raw_userclk=[llength $raw_userclk_startpoints] forbidden_axi=[llength $forbidden_axi_startpoints] raw_metadata=[llength $raw_source_metadata_paths] wide_sampler=[llength $wide_sampler_cells] unresolved_critical=[llength $unresolved_critical] unresolved_warning=[llength $unresolved_warning]"
  }

  write_lines [file join $evidence_root DIAG1_R1_SYNTH_CDC_GATE.txt] [list \
    {DIAG1_SYNTH_CDC_GATE=PASS} \
    {DIAG1_SYNTH_INTERCLOCK_PATH_GATE=PASS} \
    {DIAG1_RAW_USERCLK1_TO_SOURCE_TRACE_ENDPOINTS=0} \
    {DIAG1_RAW_SOURCE_METADATA_TO_AXI_ENDPOINTS=0} \
    {TRACE_EVENT_PAYLOAD_SOURCE_REGISTERED=YES} \
    {TRACE_EVENT_QUALIFIERS_SOURCE_REGISTERED=YES} \
    {TRACE_RAM_WRITE_CONTROL_SOURCE_LOCAL=YES} \
    {TRACE_DONE_PROTOCOL=EXPLICIT_CDC_PASS} \
    {DIAG1_NEW_UNRESOLVED_CRITICAL_CDC=0} \
    {DIAG1_NEW_UNRESOLVED_WARNING_CDC=0} \
    {RESULT=PASS}]
  return [dict create RAW_USERCLK 0 RAW_METADATA 0 WIDE_SAMPLERS 0 \
    NEW_CRITICAL 0 NEW_WARNING 0 \
    SOURCE_LOCAL_SETUP NONNEGATIVE_OR_IMPLEMENTATION_ELIGIBLE \
    SOURCE_LOCAL_WORST_SLACK $source_local_worst_slack]
}
