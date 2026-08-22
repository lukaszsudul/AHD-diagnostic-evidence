# Fresh read-only JTAG identity/DONE check. No PROGRAM.FILE assignment and no
# program_hw_devices call are present.
if {$argc != 0} {
  puts stderr "usage: read_jtag_identity_done_strong.tcl"
  exit 2
}

set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set expected_hs2_serial {210241768436}
set expected_part {xc7a35t}
set expected_idcode {0362D093}

proc emit {key value} { puts "$key=$value"; flush stdout }
proc utc {} { return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1] }
proc normalized_idcode {dev} {
  if {[lsearch -exact [list_property $dev] IDCODE_HEX] >= 0} {
    return [string toupper [get_property IDCODE_HEX $dev]]
  }
  set raw [get_property IDCODE $dev]
  if {[string match -nocase 0x* $raw]} {
    return [string toupper [string range $raw 2 end]]
  }
  if {[string is integer -strict $raw]} { return [format %08X $raw] }
  return [string toupper $raw]
}
proc cleanup_hw {} {
  catch {close_hw_target}
  catch {disconnect_hw_server}
  catch {close_hw_manager}
}

set rc 0
if {[catch {
  emit READ_ONLY_JTAG_START_UTC [utc]
  open_hw_manager
  connect_hw_server
  set all_targets [get_hw_targets -quiet]
  emit GLOBAL_HW_TARGET_COUNT [llength $all_targets]
  set target_index 0
  foreach discovered_target $all_targets {
    emit GLOBAL_HW_TARGET_$target_index $discovered_target
    incr target_index
  }
  if {[llength $all_targets] != 1} {
    error "expected exactly one global hardware target; found [llength $all_targets]"
  }
  set targets [get_hw_targets -quiet $intended_target]
  emit JTAG_HS2_SERIAL $expected_hs2_serial
  emit JTAG_TARGET $intended_target
  emit JTAG_TARGET_MATCH_COUNT [llength $targets]
  if {[llength $targets] != 1} { error "expected exactly one HS2 target" }
  current_hw_target [lindex $targets 0]
  open_hw_target
  set devices [get_hw_devices -quiet]
  emit JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} { error "expected exactly one JTAG device" }
  set dev [lindex $devices 0]
  set part [get_property PART $dev]
  set idcode [normalized_idcode $dev]
  emit FPGA_PART $part
  emit FPGA_IDCODE $idcode
  if {![string equal -nocase $part $expected_part] ||
      ![string equal -nocase $idcode $expected_idcode]} {
    error "JTAG identity mismatch"
  }
  current_hw_device $dev
  refresh_hw_device $dev
  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  emit FPGA_DONE $done
  if {$done ne "1"} { error "DONE is not 1: $done" }
  emit READ_ONLY_JTAG_GATE PASS
  emit FPGA_SRAM_PROGRAMS_THIS_SCRIPT 0
  emit READ_ONLY_JTAG_END_UTC [utc]
} err opts]} {
  emit READ_ONLY_JTAG_ERROR $err
  emit READ_ONLY_JTAG_ERROR_OPTIONS $opts
  emit READ_ONLY_JTAG_GATE FAIL
  emit FPGA_SRAM_PROGRAMS_THIS_SCRIPT 0
  set rc 1
}
cleanup_hw
exit $rc
