# R1b task-local, fail-closed, single-program procedure.
# Usage through Vivado -tclargs:
#   ROLE BIT_PATH EXPECTED_FILENAME EXPECTED_SIZE EXPECTED_SHA256

if {$argc != 5} {
  puts stderr "usage: program_once_startup_high_done.tcl ROLE BIT_PATH EXPECTED_FILENAME EXPECTED_SIZE EXPECTED_SHA256"
  exit 2
}

lassign $argv role bit_arg expected_filename expected_size expected_sha256
set allowed_roles {ARM_A_25KHZ ARM_B_FORMAL_50KHZ}
if {[lsearch -exact $allowed_roles $role] < 0} {
  puts stderr "unsupported role: $role"
  exit 2
}
if {![string is integer -strict $expected_size] || $expected_size <= 0} {
  puts stderr "EXPECTED_SIZE must be a positive integer"
  exit 2
}
if {![regexp -nocase {^[0-9a-f]{64}$} $expected_sha256]} {
  puts stderr "EXPECTED_SHA256 must contain exactly 64 hexadecimal digits"
  exit 2
}

source [file join [file dirname [info script]] select_r6_jtag_target.tcl]

set expected_r6_full_target_path {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set bitfile [file normalize $bit_arg]
set bit5_property {REGISTER.IR.BIT5_DONE}
set bit4_property {REGISTER.IR.BIT4_EOS}

proc emit {key value} {
  puts "$key=$value"
  flush stdout
}

proc utc {} {
  return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1]
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

set invoked 0
set rc 0

if {[catch {
  if {![file exists $bitfile] || ![file isfile $bitfile]} {
    error "bit file does not exist as a regular file: $bitfile"
  }
  if {[file tail $bitfile] ne $expected_filename} {
    error "bit filename mismatch: [file tail $bitfile]"
  }
  if {[file size $bitfile] != $expected_size} {
    error "bit size mismatch: [file size $bitfile]"
  }

  emit PROGRAM_ROLE $role
  emit BIT_PATH $bitfile
  emit BIT_FILENAME [file tail $bitfile]
  emit BIT_SIZE [file size $bitfile]
  emit BIT_SHA256_EXPECTED [string toupper $expected_sha256]
  emit BIT_SHA256_VERIFICATION WINDOWS_SUPERVISOR_REQUIRED

  open_hw_manager
  connect_hw_server

  set selected_target [r6_target::select_live_target]
  if {[string trim $selected_target] ne $expected_r6_full_target_path} {
    error "R6 full selected target path mismatch: $selected_target"
  }
  current_hw_target $selected_target
  open_hw_target

  set devices [get_hw_devices -quiet]
  emit JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} {
    error "expected exactly one JTAG device; found [llength $devices]"
  }

  set dev [lindex $devices 0]
  r6_target::record_object_properties R6_SELECTED_DEVICE $dev
  set part [get_property PART $dev]
  set idcode [normalized_idcode $dev]
  emit FPGA_PART $part
  emit FPGA_IDCODE $idcode
  if {![string equal -nocase $part $expected_part] ||
      ![string equal -nocase $idcode $expected_idcode]} {
    error "JTAG device identity mismatch: part=$part idcode=$idcode"
  }

  current_hw_device $dev
  refresh_hw_device $dev
  set hw_props [list_property $dev]
  set bit5_available [expr {[lsearch -exact $hw_props $bit5_property] >= 0 ? "YES" : "NO"}]
  set bit4_available [expr {[lsearch -exact $hw_props $bit4_property] >= 0 ? "YES" : "NO"}]
  emit BIT5_DONE_PROPERTY_AVAILABLE $bit5_available
  emit BIT4_EOS_PROPERTY_AVAILABLE $bit4_available
  emit BIT4_EOS_PROPERTY_QUERY_ATTEMPTED NO
  if {$bit5_available ne "YES"} {
    error "required BIT5 DONE property is unavailable"
  }

  set preprogram_done [get_property $bit5_property $dev]
  emit PREPROGRAM_DONE $preprogram_done
  if {$preprogram_done ne "1"} {
    error "pre-program DONE gate failed: DONE=$preprogram_done"
  }

  set_property PROGRAM.FILE $bitfile $dev
  emit PROGRAM_START_UTC [utc]
  set invoked 1
  emit PROGRAM_INVOCATION_CONSUMED 1

  program_hw_devices $dev

  emit I25_PROGRAM_RETURN_MARKER [utc]
  refresh_hw_device $dev
  set done [get_property $bit5_property $dev]
  emit PROGRAM_DONE $done
  if {$done ne "1"} {
    error "post-program DONE gate failed: DONE=$done"
  }
  emit FRESH_DONE_OBSERVATION $done
  emit I25_FRESH_DONE_MARKER [utc]
  emit PROGRAM_END_UTC [utc]
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
