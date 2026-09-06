# G2B-HW0-PRODUCT-R3R3 fail-closed single volatile SRAM program procedure.
if {$argc != 0} {
  puts stderr {usage: program-product-once.tcl}
  exit 2
}

set bitfile {C:/FPGA/G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316/G2B_PRODUCT_RECOVERY4.bit}
set expected_filename {G2B_PRODUCT_RECOVERY4.bit}
set expected_size 2192144
set expected_sha256 {AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7}
set expected_target {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set done_property {REGISTER.IR.BIT5_DONE}

proc emit {key value} { puts "$key=$value"; flush stdout }
proc utc {} { return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1] }
proc normalized_idcode {dev} {
  if {[lsearch -exact [list_property $dev] IDCODE_HEX] >= 0} {
    return [string toupper [string map {0X {}} [get_property IDCODE_HEX $dev]]]
  }
  set raw [get_property IDCODE $dev]
  if {[string match -nocase {0x*} $raw]} { set raw [string range $raw 2 end] }
  if {[string is integer -strict $raw]} { return [format %08X $raw] }
  return [string toupper $raw]
}
proc cleanup_hw {} {
  catch {close_hw_target}
  catch {disconnect_hw_server}
  catch {close_hw_manager}
}

set invoked 0
set rc 0
emit TASK_ID G2B-HW0-PRODUCT-R3R3
emit PROGRAMMED_STORAGE FPGA_SRAM_VOLATILE_ONLY
emit AUTOMATIC_RETRY_ALLOWED NO
emit FLASH_OPERATIONS_THIS_SCRIPT 0
emit CFGMEM_OPERATIONS_THIS_SCRIPT 0

if {[catch {
  set bitfile [file normalize $bitfile]
  if {![file isfile $bitfile]} { error "bitstream missing: $bitfile" }
  if {[file tail $bitfile] ne $expected_filename} { error "bitstream filename mismatch" }
  if {[file size $bitfile] != $expected_size} { error "bitstream size mismatch" }
  emit BIT_PATH $bitfile
  emit BIT_SIZE [file size $bitfile]
  emit BIT_SHA256_EXPECTED $expected_sha256
  emit BIT_SHA256_VERIFICATION WINDOWS_SUPERVISOR_PASS

  open_hw_manager
  connect_hw_server -url localhost:3121
  set targets [get_hw_targets -quiet]
  emit JTAG_TARGET_COUNT [llength $targets]
  foreach target $targets { emit DISCOVERED_JTAG_TARGET $target }
  if {[llength $targets] != 1 || [lindex $targets 0] ne $expected_target} {
    error "exact target mismatch: $targets"
  }
  set target [lindex $targets 0]
  current_hw_target $target
  open_hw_target
  set devices [get_hw_devices -quiet]
  emit JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} { error "device count [llength $devices]" }
  set dev [lindex $devices 0]
  current_hw_device $dev
  refresh_hw_device $dev
  set part [get_property PART $dev]
  set idcode [normalized_idcode $dev]
  set done_before [string trim [get_property $done_property $dev]]
  emit SELECTED_TARGET $target
  emit SELECTED_DEVICE $dev
  emit PREPROGRAM_FPGA_PART $part
  emit PREPROGRAM_FPGA_IDCODE $idcode
  emit PREPROGRAM_FPGA_DONE $done_before
  if {$part ne $expected_part || $idcode ne $expected_idcode || $done_before ni {0 1}} {
    error "preprogram identity mismatch: $part $idcode $done_before"
  }
  if {[lsearch -exact [list_property $dev] PROBES.FILE] >= 0 &&
      [string trim [get_property PROBES.FILE $dev]] ne {}} {
    error "PROBES.FILE is not unset"
  }

  set_property PROGRAM.FILE $bitfile $dev
  emit PROGRAM_START_UTC [utc]
  set invoked 1
  emit PROGRAM_INVOCATION_CONSUMED 1
  program_hw_devices $dev
  emit PROGRAM_COMMAND_RETURNED_UTC [utc]

  refresh_hw_device $dev
  set post_part [get_property PART $dev]
  set post_idcode [normalized_idcode $dev]
  set post_done [string trim [get_property $done_property $dev]]
  emit POSTPROGRAM_FPGA_PART $post_part
  emit POSTPROGRAM_FPGA_IDCODE $post_idcode
  emit POSTPROGRAM_FPGA_DONE $post_done
  if {$post_part ne $expected_part || $post_idcode ne $expected_idcode || $post_done ne {1}} {
    error "postprogram identity/DONE mismatch: $post_part $post_idcode $post_done"
  }
  emit PROGRAM_INVOCATIONS 1
  emit PROGRAM_TCL_RESULT PASS_DONE_1
} err opts]} {
  emit PROGRAM_INVOCATIONS $invoked
  emit PROGRAM_ERROR $err
  emit PROGRAM_ERROR_OPTIONS $opts
  emit PROGRAM_TCL_RESULT FAIL_NO_RETRY
  set rc 1
}
cleanup_hw
exit $rc
