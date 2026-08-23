# One R7 read-only selected-target reconfirmation session.

if {$argc != 3} {
  puts stderr {usage: r7_jtag_reconfirmation_session.tcl SESSION_CSV TARGET_PROPERTIES DEVICE_PROPERTIES}
  exit 2
}

set session_csv [file normalize [lindex $argv 0]]
set target_properties_path [file normalize [lindex $argv 1]]
set device_properties_path [file normalize [lindex $argv 2]]

set selector_path {C:/FPGA/V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6/scripts/select_r6_jtag_target.tcl}
if {![file exists $selector_path] || ![file isfile $selector_path]} {
  puts stderr "frozen R6 target selector is unavailable: $selector_path"
  exit 2
}
source $selector_path

set expected_canonical_id {Xilinx/80802026a98b01}
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
set rc 0
if {[catch {
  foreach output_path [list $session_csv $target_properties_path $device_properties_path] {
    if {[file exists $output_path]} { error "reconfirmation evidence already exists: $output_path" }
  }

  set csv_handle [open $session_csv {WRONLY CREAT EXCL}]
  puts $csv_handle {sample_index,monotonic_ms,utc,target_count,device_count,target_path,canonical_id,part,idcode,done,refresh_result}
  flush $csv_handle

  emit R7_JTAG_RECONFIRMATION_START_UTC [utc_now]
  emit EXPECTED_SAMPLE_COUNT $sample_count
  emit INTER_SAMPLE_DELAY_MS $inter_sample_delay_ms
  emit JTAG_FREQUENCY_CHANGED NO
  emit FPGA_PROGRAM_INVOCATIONS_THIS_SESSION 0

  open_hw_manager
  connect_hw_server

  set selected_target [r6_target::select_live_target]
  set frozen_target_path [string trim $selected_target]
  set frozen_canonical [r6_target::canonical_id_from_path $frozen_target_path]
  if {$frozen_canonical ne $expected_canonical_id} {
    error "initial canonical target mismatch: $frozen_canonical"
  }
  emit R7_SELECTED_JTAG_CANONICAL_ID $frozen_canonical
  emit R7_FULL_JTAG_TARGET_PATH $frozen_target_path
  r6_target::write_object_properties $selected_target $target_properties_path
  current_hw_target $selected_target
  open_hw_target

  set initial_devices [get_hw_devices -quiet]
  if {[llength $initial_devices] != 1} {
    error "expected exactly one hardware device; found [llength $initial_devices]"
  }
  set dev [lindex $initial_devices 0]
  set frozen_device_path [string trim $dev]
  current_hw_device $dev
  r6_target::write_object_properties $dev $device_properties_path
  if {[lsearch -exact [list_property $dev] REGISTER.IR.BIT5_DONE] < 0} {
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
      error "sample $sample_index target selector failed: [dict get $classification status]"
    }
    set sample_target_path [dict get $classification selected_path]
    set sample_canonical [dict get $classification canonical_id]
    if {$sample_target_path ne $frozen_target_path || $sample_canonical ne $expected_canonical_id} {
      error "sample $sample_index selected target changed"
    }

    set sample_devices [get_hw_devices -quiet]
    set device_count [llength $sample_devices]
    if {$device_count != 1 || [string trim [lindex $sample_devices 0]] ne $frozen_device_path} {
      error "sample $sample_index device selection changed"
    }
    set sample_dev [lindex $sample_devices 0]
    set part [get_property PART $sample_dev]
    set idcode [normalized_idcode $sample_dev]
    if {![string equal -nocase $part $expected_part] ||
        ![string equal -nocase $idcode $expected_idcode]} {
      error "sample $sample_index device identity mismatch: part=$part idcode=$idcode"
    }

    set properties [list_property $sample_dev]
    if {[lsearch -exact $properties REGISTER.IR.BIT5_DONE] < 0 ||
        [catch {get_property REGISTER.IR.BIT5_DONE $sample_dev} done]} {
      error "sample $sample_index DONE property is unreadable"
    }
    set done [string trim $done]
    if {$done ni {0 1}} { error "sample $sample_index DONE value is invalid: $done" }

    puts $csv_handle "$sample_index,$sample_monotonic_ms,$sample_utc,$target_count,$device_count,$sample_target_path,$sample_canonical,$part,$idcode,$done,PASS"
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

    if {$sample_index < $sample_count} { after $inter_sample_delay_ms }
  }

  close $csv_handle
  set csv_handle {}
  emit R7_JTAG_RECONFIRMATION_SAMPLES $sample_count
  emit R7_JTAG_RECONFIRMATION_SESSION_GATE PASS
  emit R7_JTAG_RECONFIRMATION_END_UTC [utc_now]
} err opts]} {
  puts stderr "R7_JTAG_RECONFIRMATION_ERROR=$err"
  puts stderr "R7_JTAG_RECONFIRMATION_ERROR_OPTIONS=$opts"
  flush stderr
  emit R7_JTAG_RECONFIRMATION_SESSION_GATE FAIL
  set rc 1
}

if {$csv_handle ne {}} { catch {close $csv_handle} }
cleanup_hw
emit FPGA_PROGRAM_INVOCATIONS_THIS_SESSION 0
exit $rc

