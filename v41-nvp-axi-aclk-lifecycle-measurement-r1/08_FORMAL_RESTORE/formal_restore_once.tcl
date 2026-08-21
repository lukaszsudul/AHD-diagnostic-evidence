if {$argc != 1} { puts stderr "usage: formal_restore_once.tcl BIT_PATH"; exit 2 }
set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set bitfile [file normalize [lindex $argv 0]]
proc emit {k v} { puts "$k=$v"; flush stdout }
proc cleanup {} { catch {close_hw_target}; catch {disconnect_hw_server}; catch {close_hw_manager} }
set invoked 0
set rc 0
if {[catch {
  open_hw_manager; connect_hw_server
  set targets [get_hw_targets -quiet $intended_target]
  if {[llength $targets] != 1} { error "exact target count [llength $targets]" }
  current_hw_target [lindex $targets 0]; open_hw_target
  set devs [get_hw_devices -quiet -filter {PART == xc7a35t}]
  if {[llength $devs] != 1} { error "exact device count [llength $devs]" }
  set dev [lindex $devs 0]; current_hw_device $dev; refresh_hw_device $dev
  set_property PROGRAM.FILE $bitfile $dev
  emit PROGRAM_START_UTC [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
  set invoked 1
  program_hw_devices $dev
  emit PROGRAM_EOS HIGH_VENDOR_STARTUP_STATUS
  refresh_hw_device $dev
  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  emit PROGRAM_DONE $done
  emit PROGRAM_END_UTC [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
  if {$done ne "1"} { error "DONE is $done" }
  emit PROGRAM_RESULT PASS_EOS_HIGH_DONE_1
} err opts]} { emit PROGRAM_INVOCATIONS $invoked; emit PROGRAM_ERROR $err; emit PROGRAM_RESULT FAIL; set rc 1 }
cleanup
exit $rc
