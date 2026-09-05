# G2B-HW0-PRODUCT-R1 fail-closed single SRAM program procedure.
# Hash verification is performed by the Windows supervisor immediately before
# this script. This script programs volatile FPGA SRAM exactly once.
if {$argc != 4} {
  puts stderr {usage: program_g2b_product_r1_once.tcl BIT_PATH EXPECTED_FILENAME EXPECTED_SIZE EXPECTED_SHA256}
  exit 2
}
lassign $argv bit_arg expected_filename expected_size expected_sha256
if {![string is integer -strict $expected_size] || $expected_size <= 0} {
  puts stderr {EXPECTED_SIZE must be a positive integer}
  exit 2
}
if {![regexp -nocase {^[0-9a-f]{64}$} $expected_sha256]} {
  puts stderr {EXPECTED_SHA256 must contain exactly 64 hexadecimal digits}
  exit 2
}

set selector_path {C:/FPGA/AHD_G1_EVIDENCE/_agent_evidence_20260827_164925/v41-nvp-r1e-extended-observability-r1/r6/scripts/select_r6_jtag_target.tcl}
if {![file isfile $selector_path]} { error "accepted selector unavailable: $selector_path" }
source $selector_path

set expected_full_target_path {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}
set expected_part {xc7a35t}
set expected_idcode {0362D093}
set bitfile [file normalize $bit_arg]
set done_property {REGISTER.IR.BIT5_DONE}
set preprogram_sample_count 5
set preprogram_delay_ms 250

proc emit {key value} { puts "$key=$value"; flush stdout }
proc utc {} { return [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%SZ} -gmt 1] }
proc normalized_idcode {dev} {
  if {[lsearch -exact [list_property $dev] IDCODE_HEX] >= 0} {
    return [string toupper [get_property IDCODE_HEX $dev]]
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
emit TASK_ID G2B-HW0-PRODUCT-R1
emit PROGRAM_ROLE G2B_PRODUCT_R1_EXACT_CANDIDATE
emit PROGRAMMED_STORAGE FPGA_SRAM_VOLATILE_ONLY
emit FLASH_OPERATIONS_THIS_SCRIPT 0
emit CFGMEM_OPERATIONS_THIS_SCRIPT 0
emit PROGRAM_B_OPERATIONS_THIS_SCRIPT 0
emit AUTOMATIC_RETRY_ALLOWED NO

if {[catch {
  if {![file isfile $bitfile]} { error "bit file missing: $bitfile" }
  if {[file tail $bitfile] ne $expected_filename} { error "bit filename mismatch: [file tail $bitfile]" }
  if {[file size $bitfile] != $expected_size} { error "bit size mismatch: [file size $bitfile]" }
  emit BIT_PATH $bitfile
  emit BIT_FILENAME [file tail $bitfile]
  emit BIT_SIZE [file size $bitfile]
  emit BIT_SHA256_EXPECTED [string toupper $expected_sha256]
  emit BIT_SHA256_VERIFICATION WINDOWS_SUPERVISOR_PASS_REQUIRED
  emit PREPROGRAM_SAMPLE_COUNT_EXPECTED $preprogram_sample_count

  open_hw_manager
  connect_hw_server -url localhost:3121
  set selected_target [r6_target::select_live_target]
  set selected_path [string trim $selected_target]
  emit FULL_JTAG_TARGET_PATH $selected_path
  if {$selected_path ne $expected_full_target_path} { error "exact target mismatch: $selected_path" }
  current_hw_target $selected_target
  open_hw_target

  set devices [get_hw_devices -quiet]
  emit JTAG_DEVICE_COUNT [llength $devices]
  if {[llength $devices] != 1} { error "expected one JTAG device; found [llength $devices]" }
  set dev [lindex $devices 0]
  current_hw_device $dev
  set initial_device_path [string trim $dev]
  set done_samples {}
  for {set i 1} {$i <= $preprogram_sample_count} {incr i} {
    refresh_hw_device $dev
    set classification [r6_target::classify_target_paths [get_hw_targets -quiet]]
    if {[dict get $classification status] ne {PASS} ||
        [dict get $classification selected_path] ne $expected_full_target_path} {
      error "preprogram target selection changed at sample $i"
    }
    set sample_devices [get_hw_devices -quiet]
    if {[llength $sample_devices] != 1 || [string trim [lindex $sample_devices 0]] ne $initial_device_path} {
      error "preprogram device selection changed at sample $i"
    }
    set sample_dev [lindex $sample_devices 0]
    set part [get_property PART $sample_dev]
    set idcode [normalized_idcode $sample_dev]
    if {![string equal -nocase $part $expected_part] ||
        ![string equal -nocase $idcode $expected_idcode]} {
      error "device identity mismatch: part=$part idcode=$idcode"
    }
    if {[lsearch -exact [list_property $sample_dev] $done_property] < 0} {
      error "DONE property unavailable at sample $i"
    }
    set done [string trim [get_property $done_property $sample_dev]]
    if {$done ni {0 1}} { error "DONE unreadable at sample $i: $done" }
    lappend done_samples $done
    emit PREPROGRAM_SAMPLE_${i}_PART $part
    emit PREPROGRAM_SAMPLE_${i}_IDCODE $idcode
    emit PREPROGRAM_DONE_SAMPLE_${i} $done
    if {$i < $preprogram_sample_count} { after $preprogram_delay_ms }
  }
  if {[llength [lsort -unique $done_samples]] != 1} { error "preprogram DONE unstable: $done_samples" }
  emit PREPROGRAM_DONE_SAMPLES [join $done_samples ,]
  emit PROGRAM_PRECONDITION PASS_EXACT_TARGET_DEVICE_STABLE_DONE

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
  if {![string equal -nocase $post_part $expected_part]} { error "postprogram part mismatch: $post_part" }
  if {![string equal -nocase $post_idcode $expected_idcode]} { error "postprogram IDCODE mismatch: $post_idcode" }
  if {$post_done ne {1}} { error "postprogram DONE is not 1: $post_done" }
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
