# AHD v41 G2B-G15-17-EQ-R1 routed read-only symmetry/timing audit.
# One Vivado process, one sealed routed DCP, no report_bus_skew, no checkpoint
# writes, no synthesis/implementation/bitstream/hardware operations.

set DCP {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp}
set BASE_XDC {C:/FPGA/V41_G2B_EVIDENCE/v41-development-g2b-g13a-reset-return-signoff-audit/raw/timing/G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc}
set BS3_XDC {C:/FPGA/V41_G2B_EVIDENCE/v41-development-g2b-bs3-ownership-mailbox-settling-proof/G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc}
set G13_XDC {C:/FPGA/V41_G2B_EVIDENCE/v41-development-g2b-g13a-reset-return-signoff-audit/G2B_G13A_CANDIDATE_CONSTRAINTS.xdc}
set G14_XDC {C:/FPGA/V41_G2B_EVIDENCE/v41-development-g2b-g14a-release-slot0-signoff-audit/G2B_G14A_CANDIDATE_CONSTRAINTS.xdc}
set ACTIVE_XDC {C:/FPGA/V41_G2B/xdc/common/g2b_cdc.xdc}
set RTL_SOURCE {C:/FPGA/V41_G2B/rtl/g2b/v41_g2b_onech_c2h.sv}

set EXPECTED_DCP EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83
set EXPECTED_BASE 3F7D8613AB3ECF579F3F1E7A09B1608602768D2B9C880CE3B755437081DF1F87
set EXPECTED_BS3 AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087
set EXPECTED_G13 E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312
set EXPECTED_G14 094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A
set EXPECTED_ACTIVE 49CE028909F25303807E85E8835BD3379F1C6965EC302E08812105C280736C4A
set EXPECTED_RTL 8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471

proc write_text {path value} {
  file mkdir [file dirname $path]
  set h [open $path w]
  fconfigure $h -translation lf -encoding utf-8
  puts -nonewline $h $value
  close $h
}

proc read_text {path} {
  set h [open $path r]
  fconfigure $h -translation auto -encoding utf-8
  set value [read $h]
  close $h
  return $value
}

proc seconds_since {start_ms} {
  return [format %.3f [expr {double([clock milliseconds]-$start_ms)/1000.0}]]
}

proc csv {value} {
  return "\"[string map [list \" \"\"] $value]\""
}

proc prop {object property_name} {
  if {[llength $object] == 0 || [catch {get_property $property_name $object} v] || $v eq ""} { return N/A }
  return $v
}

proc names {objects} {
  if {[llength $objects] == 0} { return [list] }
  return [lsort -dictionary -unique [get_property NAME $objects]]
}

proc sha256_file {path} {
  if {![file isfile $path]} { error "missing input: $path" }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set value [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $value]} { return $value }
  }
  error "cannot parse SHA-256: $path"
}

proc require_hash {label path expected} {
  set actual [sha256_file $path]
  if {$actual ne $expected} { error "$label hash mismatch: $actual" }
}

proc require_count {label objects expected} {
  set actual [llength $objects]
  if {$actual != $expected} { error "$label count mismatch: $actual expected $expected" }
}

proc clocks_for_cells {cells} {
  set resolved [get_cells -quiet $cells]
  set pins [get_pins -quiet -of_objects $resolved -filter {REF_PIN_NAME == C}]
  if {[llength $pins] == 0} {
    set pins [get_pins -quiet -of_objects $resolved -filter {IS_CLOCK == 1}]
  }
  set clocks [get_clocks -quiet -of_objects $pins]
  if {[llength $clocks] == 0} { return [list] }
  return [lsort -dictionary -unique [get_property NAME $clocks]]
}

proc type_histogram {cells} {
  set counts [dict create]
  foreach c $cells {
    set t [prop $c REF_NAME]
    dict incr counts $t
  }
  set rows [list]
  foreach key [lsort -dictionary [dict keys $counts]] { lappend rows "$key:[dict get $counts $key]" }
  return [join $rows {;}]
}

proc control_net_signature {cells} {
  set rows [list]
  foreach c $cells {
    set cpins [get_pins -quiet -of_objects $c -filter {REF_PIN_NAME =~ R* || REF_PIN_NAME =~ S* || REF_PIN_NAME =~ CLR* || REF_PIN_NAME =~ PRE*}]
    foreach p $cpins {
      set net_names [names [get_nets -quiet -of_objects $p]]
      if {[llength $net_names] == 0} { set net_names [list UNCONNECTED] }
      lappend rows "[prop $c NAME]/[prop $p REF_PIN_NAME]=[join $net_names +]"
    }
  }
  if {[llength $rows] == 0} { return NONE }
  return [join [lsort -dictionary -unique $rows] {;}]
}

proc direct_edge {from_cells to_cells} {
  set from_nets [get_nets -quiet -of_objects [get_pins -quiet -of_objects $from_cells -filter {REF_PIN_NAME == Q || REF_PIN_NAME =~ Q*}]]
  set to_nets [get_nets -quiet -of_objects [get_pins -quiet -of_objects $to_cells -filter {REF_PIN_NAME == D || REF_PIN_NAME =~ D*}]]
  foreach n [names $from_nets] {
    if {[lsearch -exact [names $to_nets] $n] >= 0} { return YES }
  }
  return NO
}

proc fanout_rows {slot family cells} {
  set rows [list]
  foreach c [lsort -dictionary $cells] {
    set q [get_pins -quiet -of_objects $c -filter {REF_PIN_NAME == Q || REF_PIN_NAME =~ Q*}]
    set nets [get_nets -quiet -of_objects $q]
    set sinks [get_pins -quiet -leaf -of_objects $nets -filter {DIRECTION == IN}]
    set sink_types [list]
    foreach p $sinks {
      set owner [get_cells -quiet -of_objects $p]
      lappend sink_types "[prop $owner REF_NAME]/[prop $p REF_PIN_NAME]"
    }
    set sink_types [lsort -dictionary -unique $sink_types]
    lappend rows "[csv $slot],[csv $family],[csv [prop $c NAME]],[csv [llength $sinks]],[csv [join $sink_types {;}]]"
  }
  return $rows
}

proc begin_query {out id command} {
  set start [clock milliseconds]
  write_text [file join $out ACTIVE_QUERY.marker] "QUERY_ID=$id\nEPOCH_MILLISECONDS=$start\nTIMEOUT_SECONDS=300\nCOMMAND=$command\n"
  write_text [file join $out "QUERY_STARTED_${id}.marker"] "QUERY_ID=$id\nEPOCH_MILLISECONDS=$start\nTIMEOUT_SECONDS=300\nCOMMAND=$command\n"
  return $start
}

proc complete_query {out id start status} {
  set runtime [seconds_since $start]
  write_text [file join $out "QUERY_COMPLETED_${id}.marker"] "QUERY_ID=$id\nQUERY_RUNTIME_SECONDS=$runtime\nSTATUS=$status\n"
  file delete -force [file join $out ACTIVE_QUERY.marker]
  return $runtime
}

proc endpoint_role {name slot} {
  if {[regexp "slot_state_source_reg\\\[$slot\\\]" $name]} { return NORMAL_STATE_TRANSITION }
  if {[regexp {source_ownership_fatal(_event|_deferred)?_reg|enable_applied_source_reg} $name]} { return MISMATCH_CONTAINMENT }
  if {[regexp {reset_abandoned_hold_source_reg} $name]} { return RESET_OVERLAP_ACCOUNTING }
  if {[regexp {release_seen_source_reg} $name]} { return RELEASE_PHASE_RETIREMENT }
  if {[regexp {slot_state_source_reg} $name]} { return OTHER_SLOT_STATE }
  return OTHER
}

proc write_paths {path out slot query_kind} {
  set lines [list {Slot,Query_Kind,Index,Startpoint_Pin,Endpoint_Pin,Startpoint_Clock,Endpoint_Clock,Datapath_Delay_ns,Requirement_ns,Slack_ns,Logic_Levels,Exception,Endpoint_Role,Path_Type}]
  set i 0
  foreach p $path {
    incr i
    set ep [prop $p ENDPOINT_PIN]
    set row [list $slot $query_kind $i [prop $p STARTPOINT_PIN] $ep [prop $p STARTPOINT_CLOCK] [prop $p ENDPOINT_CLOCK] [prop $p DATAPATH_DELAY] [prop $p REQUIREMENT] [prop $p SLACK] [prop $p LOGIC_LEVELS] [prop $p EXCEPTION] [endpoint_role $ep $slot] [prop $p PATH_TYPE]]
    set q [list]
    foreach value $row { lappend q [csv $value] }
    lappend lines [join $q ,]
  }
  write_text $out "[join $lines \n]\n"
}

proc summarize_paths {slot paths runtime command} {
  if {[llength $paths] < 1 || [llength $paths] > 64} { error "slot $slot invalid bounded path count [llength $paths]" }
  set starts [list]
  set ends [list]
  set roles [list]
  set levels [list]
  set sc [list]
  set dc [list]
  set exceptions [list]
  set delays [list]
  foreach p $paths {
    lappend starts [prop $p STARTPOINT_PIN]
    lappend ends [prop $p ENDPOINT_PIN]
    lappend roles [endpoint_role [prop $p ENDPOINT_PIN] $slot]
    lappend levels [prop $p LOGIC_LEVELS]
    lappend sc [prop $p STARTPOINT_CLOCK]
    lappend dc [prop $p ENDPOINT_CLOCK]
    lappend exceptions [prop $p EXCEPTION]
    lappend delays [prop $p DATAPATH_DELAY]
  }
  set worst [lindex $paths 0]
  return [list $slot [llength $paths] [llength [lsort -unique $starts]] [llength [lsort -unique $ends]] [join [lsort -dictionary -unique $roles] {;}] [join [lsort -integer -unique $levels] {;}] [join [lsort -dictionary -unique $sc] {;}] [join [lsort -dictionary -unique $dc] {;}] [join [lsort -dictionary -unique $exceptions] {;}] [prop $worst DATAPATH_DELAY] [prop $worst SLACK] $runtime $command]
}

proc row_csv {values} {
  set q [list]
  foreach value $values { lappend q [csv $value] }
  return [join $q ,]
}

proc count_command {text command} {
  return [regexp -all -line [format {^[ \t]*%s(?:[ \t]|$)} $command] $text]
}

proc derive_release_free_active_base {base_text output_path} {
  set kept [list]
  set removed [list]
  foreach line [split $base_text "\n"] {
    if {[regexp {^[ \t]*set_bus_skew(?:[ \t]|$)} $line] &&
        [string first {release_generation_axi_reg[} $line] >= 0 &&
        [string first {release_epoch_axi_reg[} $line] >= 0} {
      if {[regexp {\\[ \t]*$} $line]} { error "continued release bus-skew command is unsupported" }
      lappend removed $line
      continue
    }
    lappend kept $line
  }
  if {[llength $removed] != 4} { error "expected four release bus-skew removals, got [llength $removed]" }
  set derived [join $kept "\n"]
  if {[count_command $derived set_bus_skew] != 11} { error "release-free base must retain 11 unrelated bus-skew commands" }
  write_text $output_path $derived
  return $removed
}

proc family_result {out group slot family sources destinations expected_dst} {
  require_count "$family sources" $sources 56
  require_count "$family destinations" $destinations $expected_dst
  set id "CANDIDATE_[string toupper $family]"
  set command "get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <56 slot-$slot payload sources> -to <$expected_dst family destinations>"
  set start [begin_query $out $id $command]
  set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from $sources -to $destinations]
  set runtime [complete_query $out $id $start PASS]
  require_count "$family path" $paths 1
  set p [lindex $paths 0]
  set actual [prop $p DATAPATH_DELAY]
  set requirement [prop $p REQUIREMENT]
  set slack [prop $p SLACK]
  if {![string is double -strict $actual] || $actual > 6.0005} { error "$family actual delay violation: $actual" }
  if {![string is double -strict $requirement] || abs($requirement-6.000) > 0.0005} { error "$family requirement drift: $requirement" }
  if {![string is double -strict $slack] || $slack < -0.0005} { error "$family slack violation: $slack" }
  if {[prop $p STARTPOINT_CLOCK] ne "userclk1" || [prop $p ENDPOINT_CLOCK] ne "nvp_vclk1"} {
    error "$family clock-domain mismatch: [prop $p STARTPOINT_CLOCK] to [prop $p ENDPOINT_CLOCK]"
  }
  return [list $group $slot $family MAX_DELAY_DATAPATH_ONLY 56 $expected_dst 6.000 $actual $slack $runtime PASS [prop $p STARTPOINT_PIN] [prop $p ENDPOINT_PIN] [prop $p STARTPOINT_CLOCK] [prop $p ENDPOINT_CLOCK] [prop $p LOGIC_LEVELS] [prop $p EXCEPTION]]
}

proc run_audit {out candidate mode} {
  global DCP BASE_XDC BS3_XDC G13_XDC G14_XDC ACTIVE_XDC RTL_SOURCE
  global EXPECTED_DCP EXPECTED_BASE EXPECTED_BS3 EXPECTED_G13 EXPECTED_G14 EXPECTED_ACTIVE EXPECTED_RTL
  file mkdir $out
  set audit_start [clock milliseconds]
  write_text [file join $out WORKER_STARTED.marker] "EPOCH_MILLISECONDS=$audit_start\nGLOBAL_GROUP15_REPORT_BUS_SKEW_EXECUTED=NO\nGLOBAL_GROUP16_REPORT_BUS_SKEW_EXECUTED=NO\nGLOBAL_GROUP17_REPORT_BUS_SKEW_EXECUTED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"
  if {![info exists ::env(XILINX_LOCAL_USER_DATA)] || $::env(XILINX_LOCAL_USER_DATA) ne "NO"} { error "XILINX_LOCAL_USER_DATA must be NO" }
  require_hash DCP $DCP $EXPECTED_DCP
  require_hash BASE_XDC $BASE_XDC $EXPECTED_BASE
  require_hash BS3_XDC $BS3_XDC $EXPECTED_BS3
  require_hash G13_XDC $G13_XDC $EXPECTED_G13
  require_hash G14_XDC $G14_XDC $EXPECTED_G14
  require_hash ACTIVE_XDC $ACTIVE_XDC $EXPECTED_ACTIVE
  require_hash RTL_SOURCE $RTL_SOURCE $EXPECTED_RTL
  set candidate_hash [sha256_file $candidate]
  write_text [file join $out INPUT_HASHES.txt] "DCP=$EXPECTED_DCP\nBASE_XDC=$EXPECTED_BASE\nBS3_XDC=$EXPECTED_BS3\nG13_XDC=$EXPECTED_G13\nG14_XDC=$EXPECTED_G14\nACTIVE_XDC=$EXPECTED_ACTIVE\nRTL_SOURCE=$EXPECTED_RTL\nCANDIDATE_XDC=$candidate_hash\n"
  write_text [file join $out VIVADO_VERSION.txt] "SHORT=[version -short]\nFULL=[version]\n"

  set init_start [clock milliseconds]
  open_checkpoint $DCP
  set part [get_property PART [current_design]]
  set route_ok [report_route_status -boolean_check ROUTED_FULLY]
  set route_errors [report_route_status -boolean_check ERRORS_IN_ROUTES]
  if {$part ne "xc7a35tcsg325-2" || !$route_ok || $route_errors} { error "sealed route identity/status mismatch" }
  set pre_clocks [list]
  foreach c [lsort -dictionary [get_clocks -quiet]] { lappend pre_clocks "[prop $c NAME]|[prop $c PERIOD]|[prop $c WAVEFORM]" }

  set context_base [file join $out ACTIVE_CONTEXT_WITHOUT_RELEASE_SLOTS0_3_BUS_SKEW.xdc]
  set removed [derive_release_free_active_base [read_text $BASE_XDC] $context_base]
  write_text [file join $out REMOVED_RELEASE_BUS_SKEW_COMMANDS.txt] "[join $removed \n]\n"
  reset_timing -invalid
  read_xdc $context_base
  read_xdc $BS3_XDC
  read_xdc $G13_XDC
  read_xdc $G14_XDC

  set slot_data [dict create]
  set scope_lines [list {Slot,Generation_Count,Epoch_Count,Payload_Count,Original_Destination_Count,State_Destination_Count,Fault_Destination_Count,Reset_Destination_Count,Source_Clocks,Destination_Clocks,Source_Types,State_Types,Fault_Types,Reset_Types,Release_Toggle_Count,Release_Sync1_Count,Release_Sync2_Count,Release_Seen_Count,Sync1_ASYNC_REG,Sync2_ASYNC_REG,Toggle_to_Sync1_Direct,Sync1_to_Sync2_Direct,Source_Control_Nets,Sync_Control_Nets}]
  set sync_lines [list {Slot,Role,Object_Name,REF_NAME,Clock,ASYNC_REG,INIT,LOC,BEL,Control_Nets}]
  set fanout_lines [list {Slot,Field,Object_Name,Direct_Leaf_Sink_Count,Sink_Primitive_Pin_Types}]
  set common_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
  require_count "original common destinations" $common_dst 20
  set fault_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
  set reset_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] {IS_SEQUENTIAL == 1}]
  require_count "fault destinations" $fault_dst 4
  require_count "reset destinations" $reset_dst 3

  for {set slot 0} {$slot < 4} {incr slot} {
    set gen [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/release_generation_axi_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    set epoch [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/release_epoch_axi_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    set payload "$gen $epoch"
    set state [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/slot_state_source_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    set toggle [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/release_toggle_axi_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    set sync1 [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/release_sync1_source_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    set sync2 [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/release_sync2_source_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    set seen [filter [get_cells -quiet -hier -regexp ".*G2B_ONECH_C2H/release_seen_source_reg\\\[$slot\\\].*"] {IS_SEQUENTIAL == 1}]
    require_count "slot $slot generation" $gen 24
    require_count "slot $slot epoch" $epoch 32
    require_count "slot $slot payload" $payload 56
    require_count "slot $slot state" $state 3
    require_count "slot $slot toggle" $toggle 1
    require_count "slot $slot sync1" $sync1 1
    require_count "slot $slot sync2" $sync2 1
    require_count "slot $slot seen" $seen 1
    if {[string toupper [prop $sync1 ASYNC_REG]] ni {TRUE 1 YES} || [string toupper [prop $sync2 ASYNC_REG]] ni {TRUE 1 YES}} { error "slot $slot release synchronizer ASYNC_REG missing" }
    set sclk [clocks_for_cells $payload]
    set dclk [clocks_for_cells "$state $fault_dst $reset_dst"]
    if {[llength $sclk] == 0} { set sclk [list DEFERRED_TO_TIMING_PATHS] }
    if {[llength $dclk] == 0} { set dclk [list DEFERRED_TO_TIMING_PATHS] }
    dict set slot_data $slot generation $gen
    dict set slot_data $slot epoch $epoch
    dict set slot_data $slot payload $payload
    dict set slot_data $slot state $state
    dict set slot_data $slot toggle $toggle
    dict set slot_data $slot sync1 $sync1
    dict set slot_data $slot sync2 $sync2
    dict set slot_data $slot seen $seen
    lappend scope_lines [row_csv [list $slot [llength $gen] [llength $epoch] [llength $payload] [llength $common_dst] [llength $state] [llength $fault_dst] [llength $reset_dst] [join $sclk {;}] [join $dclk {;}] [type_histogram $payload] [type_histogram $state] [type_histogram $fault_dst] [type_histogram $reset_dst] [llength $toggle] [llength $sync1] [llength $sync2] [llength $seen] [prop $sync1 ASYNC_REG] [prop $sync2 ASYNC_REG] [direct_edge $toggle $sync1] [direct_edge $sync1 $sync2] [control_net_signature $payload] [control_net_signature "$sync1 $sync2"]]]
    foreach role_cells [list [list RELEASE_TOGGLE $toggle] [list RELEASE_SYNC1 $sync1] [list RELEASE_SYNC2 $sync2] [list RELEASE_SEEN $seen]] {
      lassign $role_cells role cells
      foreach c $cells {
        lappend sync_lines [row_csv [list $slot $role [prop $c NAME] [prop $c REF_NAME] [join [clocks_for_cells $c] {;}] [prop $c ASYNC_REG] [prop $c INIT] [prop $c LOC] [prop $c BEL] [control_net_signature $c]]]
      }
    }
    foreach row [fanout_rows $slot GENERATION $gen] { lappend fanout_lines $row }
    foreach row [fanout_rows $slot EPOCH $epoch] { lappend fanout_lines $row }
  }

  set treq [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/transport_req_toggle_axi_reg.*}] {IS_SEQUENTIAL == 1}]
  set treq1 [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/transport_req_sync1_source_reg.*}] {IS_SEQUENTIAL == 1}]
  set treq2 [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/transport_req_sync2_source_reg.*}] {IS_SEQUENTIAL == 1}]
  set tack [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/transport_ack_toggle_source_reg.*}] {IS_SEQUENTIAL == 1}]
  set tack1 [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/transport_ack_sync1_axi_reg.*}] {IS_SEQUENTIAL == 1}]
  set tack2 [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/transport_ack_sync2_axi_reg.*}] {IS_SEQUENTIAL == 1}]
  foreach pair [list [list transport_req_toggle $treq] [list transport_req_sync1 $treq1] [list transport_req_sync2 $treq2] [list transport_ack_toggle $tack] [list transport_ack_sync1 $tack1] [list transport_ack_sync2 $tack2]] { require_count [lindex $pair 0] [lindex $pair 1] 1 }
  if {[string toupper [prop $treq1 ASYNC_REG]] ni {TRUE 1 YES} || [string toupper [prop $treq2 ASYNC_REG]] ni {TRUE 1 YES} || [string toupper [prop $tack1 ASYNC_REG]] ni {TRUE 1 YES} || [string toupper [prop $tack2 ASYNC_REG]] ni {TRUE 1 YES}} { error "transport request/ack synchronizer ASYNC_REG missing" }
  write_text [file join $out TRANSPORT_PROTOCOL_TOPOLOGY.txt] "REQUEST_TOGGLE_COUNT=1\nREQUEST_SYNC1_COUNT=1\nREQUEST_SYNC2_COUNT=1\nREQUEST_SYNC1_ASYNC_REG=[prop $treq1 ASYNC_REG]\nREQUEST_SYNC2_ASYNC_REG=[prop $treq2 ASYNC_REG]\nREQUEST_TOGGLE_TO_SYNC1_DIRECT=[direct_edge $treq $treq1]\nREQUEST_SYNC1_TO_SYNC2_DIRECT=[direct_edge $treq1 $treq2]\nACK_TOGGLE_COUNT=1\nACK_SYNC1_COUNT=1\nACK_SYNC2_COUNT=1\nACK_SYNC1_ASYNC_REG=[prop $tack1 ASYNC_REG]\nACK_SYNC2_ASYNC_REG=[prop $tack2 ASYNC_REG]\nACK_TOGGLE_TO_SYNC1_DIRECT=[direct_edge $tack $tack1]\nACK_SYNC1_TO_SYNC2_DIRECT=[direct_edge $tack1 $tack2]\n"
  write_text [file join $out SLOT_SCOPE_SUMMARY.csv] "[join $scope_lines \n]\n"
  write_text [file join $out SYNCHRONIZER_INVENTORY.csv] "[join $sync_lines \n]\n"
  write_text [file join $out PAYLOAD_FANOUT_PROFILE.csv] "[join $fanout_lines \n]\n"

  set init_runtime [seconds_since $init_start]
  if {[expr {double($init_runtime)}] > 900.0} { error "Vivado initialization exceeded 900 seconds: $init_runtime" }
  write_text [file join $out COMMAND_READY.marker] "STATUS=COMMAND_READY\nINITIALIZATION_RUNTIME_SECONDS=$init_runtime\nDCP_SHA256=$EXPECTED_DCP\nSOURCE_DESTINATION_OBJECTS_RESOLVED=YES\n"

  # Independently characterize each original Group 15-17 path set without
  # creating or invoking any report_bus_skew command.
  if {$mode ne "CANDIDATE_ONLY"} {
    set path_summary [list {Slot,Returned_Path_Count,Source_Diversity,Destination_Diversity,Endpoint_Roles,Logic_Levels,Startpoint_Clocks,Endpoint_Clocks,Exceptions,Worst_Datapath_ns,Worst_Slack_ns,Runtime_s,Command}]
    for {set slot 1} {$slot <= 3} {incr slot} {
      set sources [dict get $slot_data $slot payload]
      set id "ORIGINAL_SLOT${slot}_BOUNDED_PATHS"
      set command "get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 -from <56 slot-$slot sources> -to <20 original destinations>"
      set start [begin_query $out $id $command]
      set paths [get_timing_paths -delay_type max -sort_by slack -max_paths 64 -nworst 7 -from $sources -to $common_dst]
      set runtime [complete_query $out $id $start PASS]
      write_paths $paths [file join $out "ORIGINAL_SLOT${slot}_TIMING_PATHS.csv"] $slot ORIGINAL_GROUP_SCOPE
      set summary [summarize_paths $slot $paths $runtime $command]
      if {[lindex $summary 6] ne "userclk1" || [lindex $summary 7] ne "nvp_vclk1"} {
        error "slot $slot timing-path clock-domain mismatch: [lindex $summary 6] to [lindex $summary 7]"
      }
      lappend path_summary [row_csv $summary]
    }
    write_text [file join $out ORIGINAL_PATH_SET_SUMMARY.csv] "[join $path_summary \n]\n"
  } else {
    write_text [file join $out ORIGINAL_PATH_QUERIES_DISPOSITION.txt] "NOT_REPEATED_IN_CANDIDATE_CONTINUATION=YES\nAUTHORITATIVE_PRIOR_SESSION=C:/FPGA/G2B_G15_17_EQ_R1_20260904_221706/raw_complete\n"
  }

  # Candidate file is applied only after all slot collections, clocks,
  # synchronizers, and common protocol structures have passed the assertions.
  read_xdc $candidate
  for {set slot 1} {$slot <= 3} {incr slot} {
    set g [expr {$slot+14}]
    set prefix "g2b_g${g}eq"
    foreach variable [list ${prefix}_release_generation_src ${prefix}_release_epoch_src ${prefix}_release_payload_src ${prefix}_release_state_dst_cells ${prefix}_release_fault_dst_cells ${prefix}_release_reset_dst_cells] {
      if {![info exists $variable]} { error "candidate variable missing: $variable" }
    }
    require_count "candidate slot $slot generation" [set ${prefix}_release_generation_src] 24
    require_count "candidate slot $slot epoch" [set ${prefix}_release_epoch_src] 32
    require_count "candidate slot $slot payload" [set ${prefix}_release_payload_src] 56
    require_count "candidate slot $slot state" [set ${prefix}_release_state_dst_cells] 3
    require_count "candidate slot $slot fault" [set ${prefix}_release_fault_dst_cells] 4
    require_count "candidate slot $slot reset" [set ${prefix}_release_reset_dst_cells] 3
    set candidate_payload_names [lsort -dictionary [concat \
        [get_property NAME [set ${prefix}_release_generation_src]] \
        [get_property NAME [set ${prefix}_release_epoch_src]]]]
    set expected_payload_names [lsort -dictionary [concat \
        [get_property NAME [dict get $slot_data $slot generation]] \
        [get_property NAME [dict get $slot_data $slot epoch]]]]
    set candidate_state_names [lsort -dictionary [get_property NAME [set ${prefix}_release_state_dst_cells]]]
    set candidate_fault_names [lsort -dictionary [get_property NAME [set ${prefix}_release_fault_dst_cells]]]
    set candidate_reset_names [lsort -dictionary [get_property NAME [set ${prefix}_release_reset_dst_cells]]]
    if {$candidate_payload_names ne $expected_payload_names || $candidate_state_names ne [names [dict get $slot_data $slot state]] || $candidate_fault_names ne [names $fault_dst] || $candidate_reset_names ne [names $reset_dst]} { error "candidate slot $slot collection identity drift" }
  }
  write_xdc -exclude_physical -force [file join $out APPLIED_COMBINED_CANDIDATE_CONTEXT.xdc]

  set result_lines [list {Group,Slot,Family,Constraint_Type,Source_Count,Destination_Count,Required_ns,Worst_Actual_ns,Slack_ns,Runtime_s,Result,Startpoint_Pin,Endpoint_Pin,Source_Clock,Destination_Clock,Logic_Levels,Exception}]
  for {set slot 1} {$slot <= 3} {incr slot} {
    set group [expr {$slot+14}]
    set sources [dict get $slot_data $slot payload]
    set state [dict get $slot_data $slot state]
    foreach result [list \
        [family_result $out $group $slot "RELEASE_SLOT${slot}_NORMAL_STATE_TRANSITION" $sources $state 3] \
        [family_result $out $group $slot "RELEASE_SLOT${slot}_MISMATCH_CONTAINMENT" $sources $fault_dst 4] \
        [family_result $out $group $slot "RELEASE_SLOT${slot}_RESET_OVERLAP_ACCOUNTING" $sources $reset_dst 3]] {
      lappend result_lines [row_csv $result]
    }
  }
  write_text [file join $out CANDIDATE_RESULTS_RAW.csv] "[join $result_lines \n]\n"

  # One focused report_timing confirmation per slot, spanning all three real
  # semantic-use families; each remains independently bounded to one path.
  set report_lines [list {Slot,Runtime_s,Report_File,Status,Worst_Datapath_ns,Worst_Slack_ns,Startpoint,Endpoint,Endpoint_Role}]
  for {set slot 1} {$slot <= 3} {incr slot} {
    set sources [dict get $slot_data $slot payload]
    set semantic_dst "[dict get $slot_data $slot state] $fault_dst $reset_dst"
    set id "FOCUSED_REPORT_TIMING_SLOT${slot}"
    set report_file [file join $out "FOCUSED_REPORT_TIMING_SLOT${slot}.rpt"]
    set command "report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from <slot-$slot payload> -to <10 semantic destinations>"
    set start [begin_query $out $id $command]
    report_timing -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from $sources -to $semantic_dst -file $report_file
    set p [lindex [get_timing_paths -delay_type max -sort_by slack -max_paths 1 -nworst 1 -from $sources -to $semantic_dst] 0]
    set runtime [complete_query $out $id $start PASS]
    if {[llength $p] != 1} { error "focused report_timing slot $slot returned no path" }
    lappend report_lines [row_csv [list $slot $runtime $report_file PASS [prop $p DATAPATH_DELAY] [prop $p SLACK] [prop $p STARTPOINT_PIN] [prop $p ENDPOINT_PIN] [endpoint_role [prop $p ENDPOINT_PIN] $slot]]]
  }
  write_text [file join $out FOCUSED_REPORT_TIMING_SUMMARY.csv] "[join $report_lines \n]\n"

  set mid "FOCUSED_TIMING_METHODOLOGY"
  set mcommand {report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}}
  set mstart [begin_query $out $mid $mcommand]
  set mfile [file join $out FOCUSED_TIMING_METHODOLOGY.rpt]
  report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} -file $mfile
  set mruntime [complete_query $out $mid $mstart PASS]
  set mtext [read_text $mfile]
  set checks UNPARSED
  regexp {Checks found:\s+([0-9]+)} $mtext -> checks
  set release_mentions [regexp -all -nocase {(release_generation_axi|release_epoch_axi|release_sync1_source|release_sync2_source)} $mtext]
  write_text [file join $out FOCUSED_TIMING_METHODOLOGY_SUMMARY.txt] "STATUS=PASS\nCHECKS_FOUND=$checks\nRELEASE_OBJECT_MENTIONS=$release_mentions\nQUERY_RUNTIME_SECONDS=$mruntime\n"

  set post_clocks [list]
  foreach c [lsort -dictionary [get_clocks -quiet]] { lappend post_clocks "[prop $c NAME]|[prop $c PERIOD]|[prop $c WAVEFORM]" }
  if {$pre_clocks ne $post_clocks} { error "clock signature changed" }
  if {![report_route_status -boolean_check ROUTED_FULLY] || [report_route_status -boolean_check ERRORS_IN_ROUTES]} { error "route status changed" }
  set total [seconds_since $audit_start]
  write_text [file join $out RUNTIME_SUMMARY.txt] "INITIALIZATION_RUNTIME_SECONDS=$init_runtime\nMETHODOLOGY_RUNTIME_SECONDS=$mruntime\nTOTAL_ANALYSIS_RUNTIME_SECONDS=$total\nSIGNOFF_RUNTIME=PRACTICAL\n"
  write_text [file join $out WORKER_COMPLETED.marker] "STATUS=PASS\nTOTAL_ANALYSIS_RUNTIME_SECONDS=$total\nGLOBAL_GROUP15_REPORT_BUS_SKEW_EXECUTED=NO\nGLOBAL_GROUP16_REPORT_BUS_SKEW_EXECUTED=NO\nGLOBAL_GROUP17_REPORT_BUS_SKEW_EXECUTED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"
  puts "G2B_G15_17_EQ_R1_COMPLETE runtime=${total}s"
}

if {$argc < 2 || $argc > 3} {
  puts stderr "usage: G2B_G15_17_EQ_BOUNDED_WORKER.tcl OUTPUT_DIR CANDIDATE_XDC ?CANDIDATE_ONLY?"
  exit 2
}
set out [lindex $argv 0]
set candidate [lindex $argv 1]
set mode FULL
if {$argc == 3} { set mode [lindex $argv 2] }
if {[catch {run_audit $out $candidate $mode} failure options]} {
  puts stderr "G2B_G15_17_EQ_R1_FAILURE: $failure"
  puts stderr [dict get $options -errorinfo]
  catch {write_text [file join $out WORKER_FAILED.marker] "STATUS=FAIL\nERROR=$failure\nGLOBAL_GROUP15_REPORT_BUS_SKEW_EXECUTED=NO\nGLOBAL_GROUP16_REPORT_BUS_SKEW_EXECUTED=NO\nGLOBAL_GROUP17_REPORT_BUS_SKEW_EXECUTED=NO\nBITSTREAM_PRODUCED=NO\nHARDWARE_ACCESSED=NO\n"}
  exit 1
}
exit 0
