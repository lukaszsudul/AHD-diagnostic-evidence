# Strong, parameterized, single-invocation SRAM programming procedure.
#
# This is a task-local draft derived from the accepted T4 script whose SHA-256
# is A89726768AF2ABC549A7936FAA5A88BB677D51D3275BB3315934CEE50FFEA070.
# It must be launched only through the supported Vivado 2025.2 wrapper after
# an independent Windows-side SHA-256 gate has verified the bit file.
#
# Usage (through Vivado -tclargs):
#   program_once_strong.tcl ROLE BIT_PATH EXPECTED_FILENAME EXPECTED_SIZE EXPECTED_SHA256
#
# ROLE is one of ARM_A_25KHZ or ARM_B_FORMAL_50KHZ.
# No formal bootstrap role exists: failure to prove the live exact formal
# Phase-2 start state is a pre-program hard stop with FPGA programs still zero.
# PROGRAM_INVOCATION_CONSUMED is emitted and flushed immediately before the
# sole program_hw_devices command. Any subsequent error consumes the attempt.

if {$argc != 5} {
  puts stderr "usage: program_once_strong.tcl ROLE BIT_PATH EXPECTED_FILENAME EXPECTED_SIZE EXPECTED_SHA256"
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

set intended_target {localhost:3121/xilinx_tcf/Digilent/210241768436}
set expected_hs2_serial {210241768436}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set bitfile [file normalize $bit_arg]

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

  set all_targets [get_hw_targets -quiet]
  emit GLOBAL_HW_TARGET_COUNT [llength $all_targets]
  set target_index 0
  foreach discovered_target $all_targets {
    emit GLOBAL_HW_TARGET_$target_index $discovered_target
    incr target_index
  }
  if {[llength $all_targets] != 1} {
    error "expected exactly one global hardware target; found [llength $all_targets]"
  }

  set targets [get_hw_targets -quiet $intended_target]
  emit JTAG_HS2_SERIAL $expected_hs2_serial
  emit JTAG_TARGET $intended_target
  emit JTAG_TARGET_MATCH_COUNT [llength $targets]
  if {[llength $targets] != 1} {
    error "expected exactly one HS2 target; found [llength $targets]"
  }
  current_hw_target [lindex $targets 0]
  open_hw_target

  set devices [get_hw_devices -quiet]
  emit JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} {
    error "expected exactly one JTAG device on the intended target; found [llength $devices]"
  }

  set dev [lindex $devices 0]
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
  set preprogram_done [get_property REGISTER.IR.BIT5_DONE $dev]
  emit PREPROGRAM_DONE $preprogram_done
  if {$preprogram_done ne "1"} {
    error "pre-program DONE gate failed: DONE=$preprogram_done"
  }

  set_property PROGRAM.FILE $bitfile $dev
  emit PROGRAM_START_UTC [utc]
  set invoked 1
  emit PROGRAM_INVOCATION_CONSUMED 1

  # The one and only programming invocation in this script.
  program_hw_devices $dev

  # The supervisor records a monotonic tick when it receives this marker.
  emit I25_PROGRAM_RETURN_MARKER [utc]

  refresh_hw_device $dev
  set eos [get_property REGISTER.IR.BIT4_EOS $dev]
  set done [get_property REGISTER.IR.BIT5_DONE $dev]
  emit PROGRAM_EOS $eos
  emit PROGRAM_DONE $done
  emit FRESH_DONE_OBSERVATION $done
  emit I25_FRESH_DONE_MARKER [utc]
  emit PROGRAM_END_UTC [utc]
  emit PROGRAM_INVOCATIONS 1

  if {$eos ne "1" || $done ne "1"} {
    error "post-program EOS/DONE gate failed: EOS=$eos DONE=$done"
  }
  emit PROGRAM_RESULT PASS_EOS_HIGH_DONE_1
} err opts]} {
  emit PROGRAM_INVOCATIONS $invoked
  emit PROGRAM_ERROR $err
  emit PROGRAM_ERROR_OPTIONS $opts
  emit PROGRAM_RESULT FAIL_NO_RETRY
  set rc 1
}

cleanup_hw
exit $rc
