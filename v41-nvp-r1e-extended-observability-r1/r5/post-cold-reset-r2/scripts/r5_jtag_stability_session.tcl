# One R5 read-only Hardware Manager transport-stability session.
# This script only enumerates, refreshes, and reads hardware-device properties.

if {$argc != 3} {
  puts stderr {usage: r5_jtag_stability_session.tcl SESSION_INDEX SESSION_CSV PROPERTY_LIST}
  exit 2
}

set session_index [lindex $argv 0]
set session_csv [file normalize [lindex $argv 1]]
set property_list_path [file normalize [lindex $argv 2]]

if {$session_index ni {1 2}} {
  puts stderr "invalid session index: $session_index"
  exit 2
}

set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set expected_hs2_serial {210241768436}
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

proc cleanup_hw {} {
  catch {close_hw_target}
  catch {disconnect_hw_server}
  catch {close_hw_manager}
}

set csv_handle {}
set property_handle {}
set rc 0

if {[catch {
  if {[file exists $session_csv]} {
    error "session CSV already exists: $session_csv"
  }
  if {[file exists $property_list_path]} {
    error "property-list evidence already exists: $property_list_path"
  }

  set csv_handle [open $session_csv {WRONLY CREAT EXCL}]
  puts $csv_handle {session_index,sample_index,monotonic_ms,utc,target_count,device_count,target_name,hs2_serial,part,idcode,done,refresh_result}
  flush $csv_handle

  emit R5_JTAG_SESSION_START_UTC [utc_now]
  emit R5_JTAG_SESSION_INDEX $session_index
  emit EXPECTED_SAMPLE_COUNT $sample_count
  emit INTER_SAMPLE_DELAY_MS $inter_sample_delay_ms

  open_hw_manager
  connect_hw_server -url localhost:3121

  set initial_targets [get_hw_targets -quiet]
  emit INITIAL_TARGET_COUNT [llength $initial_targets]
  if {[llength $initial_targets] != 1} {
    error "expected exactly one hardware target; found [llength $initial_targets]"
  }

  set matching_targets [get_hw_targets -quiet $intended_target]
  emit INTENDED_TARGET_MATCH_COUNT [llength $matching_targets]
  if {[llength $matching_targets] != 1} {
    error "expected exactly one matching HS2 target; found [llength $matching_targets]"
  }

  set selected_target [lindex $matching_targets 0]
  current_hw_target $selected_target
  open_hw_target

  set initial_devices [get_hw_devices -quiet]
  emit INITIAL_DEVICE_COUNT [llength $initial_devices]
  if {[llength $initial_devices] != 1} {
    error "expected exactly one hardware device; found [llength $initial_devices]"
  }

  set dev [lindex $initial_devices 0]
  current_hw_device $dev
  set sorted_properties [lsort -dictionary [list_property $dev]]
  if {[lsearch -exact $sorted_properties REGISTER.IR.BIT5_DONE] < 0} {
    error {REGISTER.IR.BIT5_DONE property is unavailable}
  }

  set property_handle [open $property_list_path {WRONLY CREAT EXCL}]
  foreach property_name $sorted_properties {
    puts $property_handle $property_name
  }
  close $property_handle
  set property_handle {}
  emit LIST_PROPERTY_COUNT [llength $sorted_properties]
  emit LIST_PROPERTY_PATH $property_list_path

  for {set sample_index 1} {$sample_index <= $sample_count} {incr sample_index} {
    refresh_hw_device $dev
    set sample_monotonic_ms [monotonic_ms]
    set sample_utc [utc_now]

    set sample_targets [get_hw_targets -quiet]
    set target_count [llength $sample_targets]
    if {$target_count != 1} {
      error "sample $sample_index target count is $target_count, expected 1"
    }
    set target_name [lindex $sample_targets 0]
    set target_serial [lindex [split $target_name /] end]
    if {$target_name ne $intended_target || $target_serial ne $expected_hs2_serial} {
      error "sample $sample_index target identity mismatch: $target_name"
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

    puts $csv_handle "$session_index,$sample_index,$sample_monotonic_ms,$sample_utc,$target_count,$device_count,$target_name,$target_serial,$part,$idcode,$done,PASS"
    flush $csv_handle

    emit SAMPLE_${sample_index}_MONOTONIC_MS $sample_monotonic_ms
    emit SAMPLE_${sample_index}_TARGET_COUNT $target_count
    emit SAMPLE_${sample_index}_DEVICE_COUNT $device_count
    emit SAMPLE_${sample_index}_HS2_SERIAL $target_serial
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
  emit R5_JTAG_SESSION_END_UTC [utc_now]
} err opts]} {
  puts stderr "R5_JTAG_SESSION_ERROR=$err"
  puts stderr "R5_JTAG_SESSION_ERROR_OPTIONS=$opts"
  flush stderr
  emit SESSION_GATE FAIL
  set rc 1
}

if {$csv_handle ne {}} {
  catch {close $csv_handle}
}
if {$property_handle ne {}} {
  catch {close $property_handle}
}
cleanup_hw
emit FPGA_PROGRAM_OPERATIONS_THIS_SESSION 0
exit $rc


