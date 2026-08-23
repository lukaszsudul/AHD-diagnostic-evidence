# R6 independent read-only selected-target identity and DONE confirmation.

if {$argc != 0} {
  puts stderr {usage: read_jtag_identity_done_r6_selected.tcl}
  exit 2
}

source [file join [file dirname [info script]] select_r6_jtag_target.tcl]

set expected_full_target_path {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}
set expected_part {xc7a35t}
set expected_idcode {0362D093}

proc emit {key value} {
  puts "$key=$value"
  flush stdout
}

proc utc_now {} {
  return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1]
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

set rc 0
if {[catch {
  emit READ_ONLY_JTAG_START_UTC [utc_now]
  open_hw_manager
  connect_hw_server -url localhost:3121

  set selected_target [r6_target::select_live_target]
  set selected_path [string trim $selected_target]
  if {$selected_path ne $expected_full_target_path} {
    error "R6 full selected target path mismatch: $selected_path"
  }
  current_hw_target $selected_target
  open_hw_target

  set devices [get_hw_devices -quiet]
  emit R6_JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} {
    error "expected exactly one JTAG device; found [llength $devices]"
  }
  set dev [lindex $devices 0]
  current_hw_device $dev
  r6_target::record_object_properties R6_SELECTED_DEVICE $dev

  set part [get_property PART $dev]
  set idcode [normalized_idcode $dev]
  emit FPGA_PART $part
  emit FPGA_IDCODE $idcode
  if {![string equal -nocase $part $expected_part] ||
      ![string equal -nocase $idcode $expected_idcode]} {
    error "JTAG device identity mismatch: part=$part idcode=$idcode"
  }

  refresh_hw_device $dev
  set properties [list_property $dev]
  if {[lsearch -exact $properties REGISTER.IR.BIT5_DONE] < 0} {
    error {REGISTER.IR.BIT5_DONE property is unavailable}
  }
  set done [string trim [get_property REGISTER.IR.BIT5_DONE $dev]]
  emit FPGA_DONE $done
  if {$done ne {1}} {
    error "independent DONE gate failed: $done"
  }

  emit READ_ONLY_JTAG_GATE PASS_SELECTED_TARGET_DONE_1
  emit FPGA_PROGRAM_OPERATIONS_THIS_SCRIPT 0
  emit READ_ONLY_JTAG_END_UTC [utc_now]
} err opts]} {
  emit READ_ONLY_JTAG_ERROR $err
  emit READ_ONLY_JTAG_ERROR_OPTIONS $opts
  emit READ_ONLY_JTAG_GATE FAIL
  emit FPGA_PROGRAM_OPERATIONS_THIS_SCRIPT 0
  set rc 1
}

cleanup_hw
exit $rc

