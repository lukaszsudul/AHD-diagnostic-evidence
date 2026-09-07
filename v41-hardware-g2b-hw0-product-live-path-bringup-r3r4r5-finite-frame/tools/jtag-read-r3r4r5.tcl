set root [file normalize [file join [file dirname [info script]] ..]]
set phase [lindex $argv 0]
if {$phase ni {continuity final}} {error "R3R4R5_INVALID_JTAG_PHASE"}
set output [file join $root logs jtag-$phase.csv]
if {[file exists $output]} {error "R3R4R5_JTAG_RESULT_EXISTS"}
set rc 0
if {[catch {
  open_hw_manager
  connect_hw_server -url localhost:3121
  set targets [get_hw_targets -quiet]
  if {[llength $targets] != 1} {error "R3R4R5_JTAG_TARGET_COUNT:[llength $targets]"}
  set target [lindex $targets 0]
  if {$target ne "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01"} {
    error "R3R4R5_JTAG_TARGET_IDENTITY:$target"
  }
  current_hw_target $target
  open_hw_target
  set devices [get_hw_devices -quiet]
  if {[llength $devices] != 1} {error "R3R4R5_JTAG_DEVICE_COUNT:[llength $devices]"}
  set device [lindex $devices 0]
  current_hw_device $device
  set handle [open $output {WRONLY CREAT EXCL}]
  puts $handle {sample,utc,target,device,part,idcode,done}
  for {set sample 0} {$sample < 5} {incr sample} {
    refresh_hw_device $device
    set part [get_property PART $device]
    set idcode [string toupper [get_property IDCODE $device]]
    if {[lsearch -exact [list_property $device] IDCODE_HEX] >= 0} {
      set idcode [string toupper [get_property IDCODE_HEX $device]]
    }
    set idcode [string map {0X {}} $idcode]
    set done [get_property REGISTER.IR.BIT5_DONE $device]
    puts $handle "$sample,[clock format [clock seconds] -format %Y-%m-%dT%H:%M:%SZ -gmt 1],$target,$device,$part,$idcode,$done"
    flush $handle
    if {$part ne "xc7a35t" || $idcode ne "0362D093" || $done ne "1"} {
      error "R3R4R5_JTAG_IDENTITY_OR_DONE:$part:$idcode:$done"
    }
    after 500
  }
  close $handle
  puts "R3R4R5_JTAG_GATE=PASS"
} problem]} {
  puts stderr $problem
  set rc 1
}
catch {close_hw_target}
catch {disconnect_hw_server}
catch {close_hw_manager}
exit $rc
