# G2B-HW0-PRODUCT-R1 fresh read-only JTAG discovery.
# This script does not assign PROGRAM.FILE and invokes no programming command.
if {$argc != 0} {
  puts stderr "usage: jtag_inventory_readonly.tcl"
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

emit TASK_ID G2B-HW0-PRODUCT-R1
emit PHASE READ_ONLY_JTAG_INVENTORY
emit UTC [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
emit EXPECTED_TARGET $intended_target
emit EXPECTED_PART $expected_part
emit EXPECTED_IDCODE $expected_idcode
emit PROGRAM_FILE_ASSIGNMENTS 0
emit FPGA_SRAM_PROGRAMS_THIS_SCRIPT 0
emit FLASH_OPERATIONS_THIS_SCRIPT 0
emit CFGMEM_OPERATIONS_THIS_SCRIPT 0
emit PROGRAM_B_OPERATIONS_THIS_SCRIPT 0

set rc 0
if {[catch {
  open_hw_manager
  connect_hw_server -url localhost:3121
  set targets [get_hw_targets -quiet]
  emit JTAG_TARGET_COUNT [llength $targets]
  foreach target $targets { emit DISCOVERED_JTAG_TARGET $target }
  set matches [get_hw_targets -quiet $intended_target]
  emit INTENDED_TARGET_MATCH_COUNT [llength $matches]
  if {[llength $matches] != 1} {
    error "expected one exact HS2 target; found [llength $matches]"
  }
  set target [lindex $matches 0]
  current_hw_target $target
  open_hw_target
  set devices [get_hw_devices -quiet]
  emit DEVICE_COUNT_ON_INTENDED_TARGET [llength $devices]
  set device_matches {}
  set index 0
  foreach dev $devices {
    set part [get_property PART $dev]
    set idcode [normalized_idcode $dev]
    emit DEVICE_${index}_NAME $dev
    emit DEVICE_${index}_PART $part
    emit DEVICE_${index}_IDCODE $idcode
    if {[string equal -nocase $part $expected_part] &&
        [string equal -nocase $idcode $expected_idcode]} {
      lappend device_matches $dev
    }
    incr index
  }
  emit EXACT_DEVICE_MATCH_COUNT [llength $device_matches]
  if {[llength $device_matches] != 1} {
    error "exact A35T/IDCODE match count is [llength $device_matches]"
  }
  set dev [lindex $device_matches 0]
  current_hw_device $dev
  refresh_hw_device $dev
  emit SELECTED_JTAG_TARGET $target
  emit SELECTED_FPGA_DEVICE $dev
  emit SELECTED_FPGA_PART [get_property PART $dev]
  emit SELECTED_FPGA_IDCODE [normalized_idcode $dev]
  emit PREPROGRAM_FPGA_DONE [get_property REGISTER.IR.BIT5_DONE $dev]
  emit READ_ONLY_JTAG_INVENTORY PASS
} err opts]} {
  emit ERROR $err
  emit ERROR_OPTIONS $opts
  emit READ_ONLY_JTAG_INVENTORY FAIL
  set rc 1
}
cleanup_hw
exit $rc
