# R1b read-only property inventory. Performs zero programming operations.

set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set bit5_property {REGISTER.IR.BIT5_DONE}
set bit4_property {REGISTER.IR.BIT4_EOS}

proc emit {key value} {
  puts "$key=$value"
  flush stdout
}

proc normalized_idcode {dev} {
  if {[lsearch -exact [list_property $dev] IDCODE_HEX] >= 0} {
    return [string toupper [get_property IDCODE_HEX $dev]]
  }
  set raw [get_property IDCODE $dev]
  if {[string match -nocase 0x* $raw]} {
    return [string toupper [string range $raw 2 end]]
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
  open_hw_manager
  connect_hw_server
  set all_targets [get_hw_targets -quiet]
  emit GLOBAL_HW_TARGET_COUNT [llength $all_targets]
  if {[llength $all_targets] != 1} {
    error "expected exactly one global target"
  }
  set targets [get_hw_targets -quiet $intended_target]
  emit JTAG_TARGET_MATCH_COUNT [llength $targets]
  if {[llength $targets] != 1} {
    error "expected exact HS2 target"
  }
  current_hw_target [lindex $targets 0]
  open_hw_target
  set devices [get_hw_devices -quiet]
  emit JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} {
    error "expected exactly one JTAG device"
  }
  set dev [lindex $devices 0]
  set part [get_property PART $dev]
  set idcode [normalized_idcode $dev]
  emit FPGA_PART $part
  emit FPGA_IDCODE $idcode
  if {![string equal -nocase $part $expected_part] || ![string equal -nocase $idcode $expected_idcode]} {
    error "device identity mismatch"
  }
  current_hw_device $dev
  refresh_hw_device $dev
  set props [list_property $dev]
  emit PROPERTY_COUNT [llength $props]
  foreach prop [lsort $props] {
    emit DEVICE_PROPERTY $prop
  }
  set bit5_available [expr {[lsearch -exact $props $bit5_property] >= 0 ? "YES" : "NO"}]
  set bit4_available [expr {[lsearch -exact $props $bit4_property] >= 0 ? "YES" : "NO"}]
  emit BIT5_DONE_PROPERTY_AVAILABLE $bit5_available
  emit BIT4_EOS_PROPERTY_AVAILABLE $bit4_available
  emit BIT4_EOS_PROPERTY_QUERY_ATTEMPTED NO
  if {$bit5_available ne "YES"} {
    error "required BIT5 DONE property unavailable"
  }
  set done [get_property $bit5_property $dev]
  emit CURRENT_DONE $done
  emit PROGRAM_INVOCATIONS 0
  if {$done ne "1"} {
    error "current DONE is not 1"
  }
  emit READ_ONLY_PROPERTY_PREFLIGHT PASS
} err opts]} {
  emit PROGRAM_INVOCATIONS 0
  emit PREFLIGHT_ERROR $err
  emit PREFLIGHT_ERROR_OPTIONS $opts
  emit READ_ONLY_PROPERTY_PREFLIGHT FAIL
  set rc 1
}
cleanup_hw
exit $rc

