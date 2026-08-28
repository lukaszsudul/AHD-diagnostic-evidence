set harness_path {<FPGA_WORKSPACE>/V41_G2A/scripts/v41/g2a_build.tcl}
set report_path {<SOURCE_ROOT>_BUILD_EVIDENCE/CDC.rpt}
set build_root {<SOURCE_ROOT>_BUILD}
set evidence_root {<FPGA_WORKSPACE>/V41_G2A_EVIDENCE/cdc_disposition_unit_test_output}

set fh [open $harness_path r]
set harness_text [read $fh]
close $fh
set procedure_start [string first {proc write_lines} $harness_text]
set boundary [string first {# Path and argument validation happens before either execution mode writes.} $harness_text]
if {$procedure_start < 0 || $boundary < 0 || $procedure_start >= $boundary} {
  error {procedure boundaries not found}
}
eval [string range $harness_text $procedure_start [expr {$boundary - 1}]]

proc get_property {property object} {
  if {$property eq {NAME}} { return $object }
  if {$property eq {SEVERITY}} { return CRITICAL }
  error "unsupported unit-test property $property"
}

file delete -force $evidence_root
set result [enforce_gen2_xdma_pipe_cdc_disposition $report_path [list CDC-13#1 CDC-13#2]]
if {$result != 2} { error "unexpected disposition count $result" }
puts {CDC_DISPOSITION_UNIT_TEST=PASS}
puts "CDC_CRITICAL_DISPOSITIONED=$result"
