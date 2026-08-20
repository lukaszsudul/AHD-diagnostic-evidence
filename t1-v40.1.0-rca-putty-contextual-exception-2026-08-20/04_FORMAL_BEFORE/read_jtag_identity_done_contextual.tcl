# Fresh, read-only JTAG identity and DONE observation for the accepted A35T
# board.  This script never assigns PROGRAM.FILE and never programs a device.
if {$argc != 0} {
  puts stderr "usage: read_jtag_identity_done.tcl"
  exit 2
}

set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set expected_part {xc7a35t}
set expected_idcode {0362D093}

proc emit {key value} { puts "$key=$value" }

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
  open_hw_manager
  connect_hw_server
  set targets [get_hw_targets -quiet $intended_target]
  if {[llength $targets] != 1} {
    error "expected one exact HS2 target; found [llength $targets]"
  }
  set target [lindex $targets 0]
  current_hw_target $target
  open_hw_target

  set devices [get_hw_devices -quiet]
  emit DEVICE_COUNT [llength $devices]
  set matches {}
  foreach dev $devices {
    set part [get_property PART $dev]
    set idcode [normalized_idcode $dev]
    emit DEVICE_PART $part
    emit DEVICE_IDCODE $idcode
    if {[string equal -nocase $part $expected_part] &&
        [string equal -nocase $idcode $expected_idcode]} {
      lappend matches $dev
    }
  }
  if {[llength $matches] != 1} {
    error "exact A35T/IDCODE match count is [llength $matches]"
  }
  set dev [lindex $matches 0]
  current_hw_device $dev
  refresh_hw_device $dev

  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  emit JTAG_TARGET $intended_target
  emit FPGA_PART [get_property PART $dev]
  emit FPGA_IDCODE [normalized_idcode $dev]
  emit FPGA_DONE $done
  if {$done ne "1"} { error "DONE is not 1: $done" }
  emit READ_ONLY_JTAG_GATE PASS
  emit FPGA_SRAM_PROGRAMS_THIS_SCRIPT 0
} err opts]} {
  emit ERROR $err
  emit ERROR_OPTIONS $opts
  emit READ_ONLY_JTAG_GATE FAIL
  set rc 1
}

cleanup_hw
exit $rc
