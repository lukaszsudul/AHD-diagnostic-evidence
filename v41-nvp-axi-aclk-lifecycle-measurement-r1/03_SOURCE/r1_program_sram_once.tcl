if {$argc != 2} { puts stderr "usage: r1_program_sram_once.tcl BIT_PATH EXPECTED_GIT_COMMIT"; exit 2 }
set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set bit_path [file normalize [lindex $argv 0]]
proc emit {k v} { puts "$k=$v"; flush stdout }
proc cleanup {} { catch {close_hw_target}; catch {disconnect_hw_server}; catch {close_hw_manager} }
set rc 0
if {[catch {
  open_hw_manager; connect_hw_server
  set targets [get_hw_targets -quiet $intended_target]
  if {[llength $targets] != 1} { error "exact HS2 target count [llength $targets]" }
  current_hw_target [lindex $targets 0]; open_hw_target
  set matches [get_hw_devices -quiet -filter {PART == xc7a35t}]
  if {[llength $matches] != 1} { error "exact xc7a35t count [llength $matches]" }
  set dev [lindex $matches 0]; current_hw_device $dev
  set_property PROGRAM.FILE $bit_path $dev
  emit PROGRAM_START_UTC [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
  program_hw_devices $dev
  emit R1_PROGRAM_RETURN_MARKER [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
  refresh_hw_device $dev
  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  emit POSTPROGRAM_DONE $done
  if {$done ne "1"} { error "DONE is $done" }
  emit PROGRAM_RESULT PASS_EOS_HIGH_DONE_1
} err opts]} { emit ERROR $err; emit PROGRAM_RESULT FAIL; set rc 1 }
cleanup
exit $rc
