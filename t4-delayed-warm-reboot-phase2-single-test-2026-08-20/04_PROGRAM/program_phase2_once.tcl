if {$argc != 0} { puts stderr "usage: program_phase2_once.tcl"; exit 2 }
set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set bitfile {C:/FPGA/T4_DELAYED_REBOOT_PHASE2_SINGLE_TEST_20260820/00_INPUT_IDENTITY/ahd_capture_v41_phase2_p1.bit}
proc emit {key value} { puts "$key=$value" }
proc utc {} { return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1] }
proc normalized_idcode {dev} {
  if {[lsearch -exact [list_property $dev] IDCODE_HEX] >= 0} { return [string toupper [get_property IDCODE_HEX $dev]] }
  set raw [get_property IDCODE $dev]
  if {[string match -nocase 0x* $raw]} { return [string toupper [string range $raw 2 end]] }
  if {[string is integer -strict $raw]} { return [format %08X $raw] }
  return [string toupper $raw]
}
proc cleanup_hw {} { catch {close_hw_target}; catch {disconnect_hw_server}; catch {close_hw_manager} }
set invoked 0
set rc 0
if {[catch {
  open_hw_manager
  connect_hw_server
  set targets [get_hw_targets -quiet $intended_target]
  if {[llength $targets] != 1} { error "expected one exact HS2 target; found [llength $targets]" }
  current_hw_target [lindex $targets 0]
  open_hw_target
  set matches {}
  foreach dev [get_hw_devices -quiet] {
    if {[string equal -nocase [get_property PART $dev] $expected_part] && [string equal -nocase [normalized_idcode $dev] $expected_idcode]} { lappend matches $dev }
  }
  if {[llength $matches] != 1} { error "exact target match count is [llength $matches]" }
  set dev [lindex $matches 0]
  current_hw_device $dev
  refresh_hw_device $dev
  emit PROGRAM_START_UTC [utc]
  emit BIT_PATH $bitfile
  emit FPGA_PART [get_property PART $dev]
  emit FPGA_IDCODE [normalized_idcode $dev]
  set_property PROGRAM.FILE $bitfile $dev
  set invoked 1
  program_hw_devices $dev
  refresh_hw_device $dev
  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  set eos [get_property REGISTER.IR.BIT4_EOS $dev]
  emit PROGRAM_END_UTC [utc]
  emit PROGRAM_INVOCATIONS 1
  emit PROGRAM_EOS $eos
  emit PROGRAM_DONE $done
  emit FRESH_DONE_OBSERVATION $done
  if {$done ne "1" || $eos ne "1"} { error "post-program EOS/DONE gate failed" }
  emit PROGRAM_RESULT PASS_EOS_HIGH_DONE_1
} err opts]} {
  emit PROGRAM_INVOCATIONS $invoked
  emit PROGRAM_ERROR $err
  emit PROGRAM_RESULT FAIL
  set rc 1
}
cleanup_hw
exit $rc
