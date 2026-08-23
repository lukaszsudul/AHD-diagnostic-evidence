# One R6 read-only selected-target transport-stability session.

if {$argc != 4} {
  puts stderr {usage: r6_jtag_stability_session.tcl SESSION_INDEX SESSION_CSV TARGET_PROPERTIES DEVICE_PROPERTIES}
  exit 2
}

set session_index [lindex $argv 0]
set session_csv [file normalize [lindex $argv 1]]
set target_properties_path [file normalize [lindex $argv 2]]
set device_properties_path [file normalize [lindex $argv 3]]

if {$session_index ni {1 2}} {
  puts stderr "invalid session index: $session_index"
  exit 2
}

source [file join [file dirname [info script]] select_r6_jtag_target.tcl]

set expected_canonical_id {Xilinx/80802026a98b01}
set expected_full_target_path {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set sample_count 5
set inter_sample_delay_ms 500

proc emit {key value} {
  puts "$key=$value"
  flush stdout
}

proc utc_now {} {
  return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1]
}

proc monotonic_ms {} {
  return [clock clicks -milliseconds]
}

proc normalized_idcode {dev} {
  set properties [list_property $dev]
  if {[lsearch -exact $properties IDCODE_HEX] >= 0} {
    set raw [get_property IDCODE_HEX $dev]
  } else {
    set raw [get_property IDCODE $dev]
  }
  if {[string match -nocase {0x*} $raw]} {
    set raw [string range $raw 2 end]
  }
  if {[string is integer -strict $raw]} {
    return [format %08X $raw]
  }
  return [string toupper $raw]
}

proc target_metadata {target_path} {
  set normalized [r6_target::normalized_path $target_path]
  set marker {/xilinx_tcf/}
  set marker_index [string first $marker $normalized]
  if {$marker_index < 1} {
    error "target path lacks exact transport marker: $normalized"
  }
  set server_endpoint [string range $normalized 0 [expr {$marker_index - 1}]]
  return [dict create server_endpoint $server_endpoint transport_class {xilinx_tcf}]
}

proc cleanup_hw {} {
  catch {close_hw_target}
  catch {disconnect_hw_server}
  catch {close_hw_manager}
}

set csv_handle {}
set rc 0
if {[catch {
  foreach output_path [list $session_csv $target_properties_path $device_properties_path] {
    if {[file exists $output_path]} {
      error "session evidence already exists: $output_path"
    }
  }

  set csv_handle [open $session_csv {WRONLY CREAT EXCL}]
  puts $csv_handle {session_index,sample_index,monotonic_ms,utc,target_count,device_count,target_path,canonical_id,server_endpoint,transport_class,part,idcode,done,refresh_result}
  flush $csv_handle

  emit R6_JTAG_SESSION_START_UTC [utc_now]
  emit R6_JTAG_SESSION_INDEX $session_index
  emit EXPECTED_SAMPLE_COUNT $sample_count
  emit INTER_SAMPLE_DELAY_MS $inter_sample_delay_ms
  emit R6_LEGACY_HS2_REQUIRED NO
  emit R6_JTAG_FREQUENCY_CHANGED NO

  open_hw_manager
  connect_hw_server -url localhost:3121

  set selected_target [r6_target::select_live_target]
  set initial_target_path [string trim $selected_target]
  if {$initial_target_path ne $expected_full_target_path} {
    error "initial full target path mismatch: $initial_target_path"
  }
  set initial_canonical [r6_target::canonical_id_from_path $initial_target_path]
  if {$initial_canonical ne $expected_canonical_id} {
    error "initial canonical target mismatch: $initial_canonical"
  }
  set metadata [target_metadata $initial_target_path]
  set server_endpoint [dict get $metadata server_endpoint]
  set transport_class [dict get $metadata transport_class]
  emit R6_JTAG_SERVER_ENDPOINT $server_endpoint
  emit R6_JTAG_TRANSPORT_CLASS $transport_class

  r6_target::write_object_properties $selected_target $target_properties_path
  current_hw_target $selected_target
  open_hw_target

  set initial_devices [get_hw_devices -quiet]
  emit INITIAL_DEVICE_COUNT [llength $initial_devices]
  if {[llength $initial_devices] != 1} {
    error "expected exactly one hardware device; found [llength $initial_devices]"
  }

  set dev [lindex $initial_devices 0]
  current_hw_device $dev
  r6_target::write_object_properties $dev $device_properties_path
  set device_properties [list_property $dev]
  if {[lsearch -exact $device_properties REGISTER.IR.BIT5_DONE] < 0} {
    error {REGISTER.IR.BIT5_DONE property is unavailable}
  }

  for {set sample_index 1} {$sample_index <= $sample_count} {incr sample_index} {
    refresh_hw_device $dev
    set sample_monotonic_ms [monotonic_ms]
    set sample_utc [utc_now]

    set sample_targets [get_hw_targets -quiet]
    set classification [r6_target::classify_target_paths $sample_targets]
    set target_count [dict get $classification total_count]
    if {[dict get $classification status] ne {PASS}} {
      error "sample $sample_index selector status: [dict get $classification status]"
    }
    set sample_target_path [dict get $classification selected_path]
    set sample_canonical [dict get $classification canonical_id]
    if {$sample_target_path ne $initial_target_path ||
        $sample_target_path ne $expected_full_target_path} {
      error "sample $sample_index full target path changed: $sample_target_path"
    }

    set sample_devices [get_hw_devices -quiet]
    set device_count [llength $sample_devices]
    if {$device_count != 1} {
      error "sample $sample_index device count is $device_count, expected 1"
    }
    set sample_dev [lindex $sample_devices 0]
    set part [get_property PART $sample_dev]
    set idcode [normalized_idcode $sample_dev]
    if {![string equal -nocase $part $expected_part] ||
        ![string equal -nocase $idcode $expected_idcode]} {
      error "sample $sample_index device identity mismatch: part=$part idcode=$idcode"
    }

    set sample_properties [list_property $sample_dev]
    if {[lsearch -exact $sample_properties REGISTER.IR.BIT5_DONE] < 0} {
      error "sample $sample_index DONE property is unavailable"
    }
    set done [string trim [get_property REGISTER.IR.BIT5_DONE $sample_dev]]
    if {$done ni {0 1}} {
      error "sample $sample_index DONE value is unreadable: $done"
    }

    puts $csv_handle "$session_index,$sample_index,$sample_monotonic_ms,$sample_utc,$target_count,$device_count,$sample_target_path,$sample_canonical,$server_endpoint,$transport_class,$part,$idcode,$done,PASS"
    flush $csv_handle

    emit SAMPLE_${sample_index}_MONOTONIC_MS $sample_monotonic_ms
    emit SAMPLE_${sample_index}_TARGET_COUNT $target_count
    emit SAMPLE_${sample_index}_DEVICE_COUNT $device_count
    emit SAMPLE_${sample_index}_TARGET_PATH $sample_target_path
    emit SAMPLE_${sample_index}_CANONICAL_ID $sample_canonical
    emit SAMPLE_${sample_index}_PART $part
    emit SAMPLE_${sample_index}_IDCODE $idcode
    emit SAMPLE_${sample_index}_DONE $done
    emit SAMPLE_${sample_index}_REFRESH_RESULT PASS

    if {$sample_index < $sample_count} {
      after $inter_sample_delay_ms
    }
  }

  close $csv_handle
  set csv_handle {}
  emit SESSION_SAMPLE_COUNT $sample_count
  emit SESSION_GATE PASS
  emit R6_JTAG_SESSION_END_UTC [utc_now]
} err opts]} {
  puts stderr "R6_JTAG_SESSION_ERROR=$err"
  puts stderr "R6_JTAG_SESSION_ERROR_OPTIONS=$opts"
  flush stderr
  emit SESSION_GATE FAIL
  set rc 1
}

if {$csv_handle ne {}} {
  catch {close $csv_handle}
}
cleanup_hw
emit FPGA_PROGRAM_OPERATIONS_THIS_SESSION 0
exit $rc
