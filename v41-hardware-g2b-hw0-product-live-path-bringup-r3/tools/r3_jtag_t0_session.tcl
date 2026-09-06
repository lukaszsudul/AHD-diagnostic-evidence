# R3-local one-session, read-only JTAG identity and DONE inventory.

if {$argc != 4} {
  puts stderr {usage: r3_jtag_t0_session.tcl SESSION_INDEX SESSION_CSV TARGET_PROPERTIES DEVICE_PROPERTIES}
  exit 2
}

set session_index [lindex $argv 0]
set session_csv [file normalize [lindex $argv 1]]
set target_properties_path [file normalize [lindex $argv 2]]
set device_properties_path [file normalize [lindex $argv 3]]
if {$session_index ne {1}} { puts stderr "invalid session index: $session_index"; exit 2 }

source [file join [file dirname [info script]] r3_select_jtag_target.tcl]

set expected_canonical_id {Xilinx/80802026a98b01}
set expected_full_target_path {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set sample_count 5
set inter_sample_delay_ms 500

proc emit {key value} { puts "$key=$value"; flush stdout }
proc utc_now {} { return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1] }
proc monotonic_ms {} { return [clock clicks -milliseconds] }
proc cleanup_hw {} { catch {close_hw_target}; catch {disconnect_hw_server}; catch {close_hw_manager} }
proc normalized_idcode {dev} {
  set props [list_property $dev]
  if {[lsearch -exact $props IDCODE_HEX] >= 0} {
    set raw [get_property IDCODE_HEX $dev]
  } else {
    set raw [get_property IDCODE $dev]
  }
  if {[string match -nocase {0x*} $raw]} { set raw [string range $raw 2 end] }
  if {[string is integer -strict $raw]} { return [format %08X $raw] }
  return [string toupper $raw]
}

set fh {}
set rc 0
if {[catch {
  foreach path [list $session_csv $target_properties_path $device_properties_path] {
    if {[file exists $path]} { error "session evidence already exists: $path" }
  }
  set fh [open $session_csv {WRONLY CREAT EXCL}]
  puts $fh {session_index,sample_index,monotonic_ms,utc,target_count,device_count,target_path,canonical_id,part,idcode,done,refresh_result}
  flush $fh
  emit R3_JTAG_SESSION_START_UTC [utc_now]
  emit R3_JTAG_SESSION_INDEX $session_index
  emit EXPECTED_SAMPLE_COUNT $sample_count
  emit JTAG_CHAIN_INDEX 0
  emit JTAG_FREQUENCY_CHANGED NO

  open_hw_manager
  connect_hw_server -url localhost:3121
  set target [r3_target::select_live]
  set target_path [string trim $target]
  if {$target_path ne $expected_full_target_path} { error "full target path mismatch: $target_path" }
  if {[r3_target::canonical_id_from_path $target_path] ne $expected_canonical_id} {
    error "canonical target mismatch"
  }
  r3_target::write_properties $target $target_properties_path
  current_hw_target $target
  open_hw_target
  set devices [get_hw_devices -quiet]
  emit INITIAL_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} { error "expected exactly one device" }
  set dev [lindex $devices 0]
  current_hw_device $dev
  r3_target::write_properties $dev $device_properties_path
  if {[lsearch -exact [list_property $dev] REGISTER.IR.BIT5_DONE] < 0} {
    error {REGISTER.IR.BIT5_DONE unavailable}
  }

  for {set i 1} {$i <= $sample_count} {incr i} {
    refresh_hw_device $dev
    set now_ms [monotonic_ms]
    set now_utc [utc_now]
    set paths [get_hw_targets -quiet]
    set class [r3_target::classify_paths $paths]
    if {[dict get $class status] ne {PASS}} { error "sample $i target classification failed" }
    set current_path [dict get $class selected]
    if {$current_path ne $target_path} { error "sample $i target path changed" }
    set current_devices [get_hw_devices -quiet]
    if {[llength $current_devices] != 1} { error "sample $i device count changed" }
    set current [lindex $current_devices 0]
    set part [get_property PART $current]
    set idcode [normalized_idcode $current]
    set done [string trim [get_property REGISTER.IR.BIT5_DONE $current]]
    if {![string equal -nocase $part $expected_part] ||
        ![string equal -nocase $idcode $expected_idcode] || $done ne {1}} {
      error "sample $i identity/DONE mismatch: $part $idcode $done"
    }
    puts $fh "$session_index,$i,$now_ms,$now_utc,1,1,$current_path,$expected_canonical_id,$part,$idcode,$done,PASS"
    flush $fh
    emit SAMPLE_${i}_PART $part
    emit SAMPLE_${i}_IDCODE $idcode
    emit SAMPLE_${i}_DONE $done
    emit SAMPLE_${i}_REFRESH_RESULT PASS
    if {$i < $sample_count} { after $inter_sample_delay_ms }
  }
  close $fh
  set fh {}
  emit SESSION_SAMPLE_COUNT $sample_count
  emit SESSION_GATE PASS
  emit R3_JTAG_SESSION_END_UTC [utc_now]
} err opts]} {
  puts stderr "R3_JTAG_SESSION_ERROR=$err"
  puts stderr "R3_JTAG_SESSION_ERROR_OPTIONS=$opts"
  emit SESSION_GATE FAIL
  set rc 1
}
if {$fh ne {}} { catch {close $fh} }
cleanup_hw
emit FPGA_PROGRAM_OPERATIONS_THIS_SESSION 0
exit $rc
