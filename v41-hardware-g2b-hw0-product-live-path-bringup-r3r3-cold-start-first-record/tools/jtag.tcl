set root [file normalize [file join [file dirname [info script]] ..]]
set phase [lindex $argv 0]
if {$phase ni {preprogram postprogram postreboot final}} {error "invalid phase"}
set output [file join $root logs jtag-$phase.csv]
if {[file exists $output]} {error "existing result"}
set rc 0
if {[catch {
 open_hw_manager
 connect_hw_server -url localhost:3121
 set ts [get_hw_targets -quiet]
  if {[llength $ts] != 1} {error "target count [llength $ts]"}
 set target [lindex $ts 0]
  if {$target ne "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01"} {error "target identity $target"}
 current_hw_target $target
 open_hw_target
 set ds [get_hw_devices -quiet]
 if {[llength $ds] != 1} {error "device count"}
 set dev [lindex $ds 0]
 set f [open $output {WRONLY CREAT EXCL}]
  puts $f {sample,utc,target,device,part,idcode,done}
 for {set i 0} {$i<5} {incr i} {
  refresh_hw_device $dev
  set part [get_property PART $dev]
  set id [string toupper [get_property IDCODE $dev]]
  if {[lsearch -exact [list_property $dev] IDCODE_HEX]>=0} {set id [string toupper [get_property IDCODE_HEX $dev]]}
  set id [string map {0X {}} $id]
  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  puts $f "$i,[clock format [clock seconds] -format %Y-%m-%dT%H:%M:%SZ -gmt 1],$target,$dev,$part,$id,$done"
  flush $f
  if {$part ne "xc7a35t" || $id ne "0362D093" || $done ni {0 1}} {error "identity or DONE unreadable $part $id $done"}
  if {$phase ne "preprogram" && $done ne "1"} {error "DONE mismatch in $phase: $done"}
  after 500
 }
 close $f
 puts "JTAG_GATE=PASS"
} err]} {puts stderr $err;set rc 1}
catch {close_hw_target}
catch {disconnect_hw_server}
catch {close_hw_manager}
exit $rc
