if {$argc != 5} {
  puts stderr "usage: r3_continue_exact_r1e_and_write_bit.tcl SEMANTIC_TCL COMMON_TCL ROUTED_DCP OUTPUT_ROOT BIT_PATH"
  exit 2
}
set semantic_tcl [file normalize [lindex $argv 0]]
set common_tcl [file normalize [lindex $argv 1]]
set routed_dcp [file normalize [lindex $argv 2]]
set output_root [file normalize [lindex $argv 3]]
set bit_path [file normalize [lindex $argv 4]]
source $semantic_tcl
source $common_tcl
set gate_info [r1e_r3::gate_open_design $routed_dcp $output_root WRITE_CAPABLE_CONTINUATION_R3]
r1e_r3::run_complete_report_tail $output_root $gate_info
if {[file tail $bit_path] ne "ahd_capture_v41_i2c_25khz_r1e_observability.bit"} { error "unexpected bit filename" }
if {[file exists $bit_path]} { error "bit output already exists; refusing overwrite" }
file mkdir [file dirname $bit_path]
write_bitstream -force $bit_path
if {![file isfile $bit_path] || [file size $bit_path] <= 0} { error "bitstream missing or empty after write" }
r1e_r3::write_lines [file join $output_root WRITE_CONTINUATION_RESULT.txt] [list \
  "WRITE_CAPABLE_CONTINUATION_SESSIONS=1" \
  "WRITE_BITSTREAM_ATTEMPTS=1" \
  "BITSTREAM_PROPERTY_ASSIGNMENT_COUNT=0" \
  "DESIGN_IDENTITY_GATE=PASS_NAMESPACE_CORRECT" \
  "BITSTREAM=$bit_path" \
  "BITSTREAM_SIZE_BYTES=[file size $bit_path]" \
  "PROCESS_INTERNAL_RESULT=PASS"]
puts "WRITE_CAPABLE_CONTINUATION=PASS BITSTREAM=$bit_path"
close_design
exit 0
