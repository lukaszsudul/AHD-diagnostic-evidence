if {$argc != 4} {
  puts stderr "usage: preflight_corrected_synth_constraints.tcl DCP XDC AUDIT_TCL OUT_DIR"
  exit 2
}
lassign $argv dcp_path xdc_path audit_path out_dir
file mkdir $out_dir

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

set status [catch {
  open_checkpoint $dcp_path
  read_xdc $xdc_path
  set all_sync1 [get_cells -quiet -hier -regexp \
    {.*BT656_BOUNDARY_TRACE/(clear_sync1_source|arm_sync1_source|abort_sync1_source|armed_sync1_axi|triggered_sync1_axi|done_sync1_axi|overflow_sync1_axi)_reg}]
  set all_sync1_d [get_pins -quiet -of_objects $all_sync1 \
    -filter {REF_PIN_NAME == D}]
  write_lines [file join $out_dir PRECHECK_CONSTRAINT_OBJECTS.txt] [list \
    "SYNC1_CELLS=[llength $all_sync1]" \
    "SYNC1_D_PINS=[llength $all_sync1_d]"]
  report_cdc -details -file [file join $out_dir PRECHECK_CDC.rpt]
  source $audit_path
  run_g2b_bt656_diag1_r1_synth_audit $out_dir \
    [file join $out_dir PRECHECK_CDC.rpt]
} failure options]
if {$status != 0} {
  puts stderr "PRECHECK_FAIL: $failure"
  catch {close_design}
  exit 1
}
puts "PRECHECK_PASS"
close_design
