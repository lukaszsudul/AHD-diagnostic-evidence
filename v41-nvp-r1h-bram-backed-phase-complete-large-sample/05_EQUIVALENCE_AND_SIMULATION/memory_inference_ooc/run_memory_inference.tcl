set repo_root {C:/FPGA/WORKTREES/V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE}
set evidence_root {C:/FPGA/V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE/05_EQUIVALENCE_AND_SIMULATION/memory_inference_ooc}
set part xc7a35tcsg325-2

proc write_lines {path lines} {
  set fh [open $path w]
  foreach line $lines { puts $fh $line }
  close $fh
}

create_project -in_memory r1h_memory_inference -part $part
read_verilog -sv [file join $repo_root rtl v41 r1f_failed_txn_logger.sv]
read_verilog -sv [file join $repo_root rtl v41 r1h_probe_index_bram_store.sv]
read_verilog -sv [file join $repo_root tests v41 r1h_memory_inference_top.sv]
synth_design -mode out_of_context -flatten_hierarchy none \
  -top r1h_memory_inference_top -part $part

report_utilization -hierarchical -hierarchical_depth 10 \
  -file [file join $evidence_root utilization_hierarchical.rpt]
report_ram_utilization -file [file join $evidence_root ram_utilization.rpt]

set record_ramb18 [get_cells -quiet -hier -filter \
  {REF_NAME == RAMB18E1 && NAME =~ *FAILED_RECORD_STORE*}]
set record_ramb36 [get_cells -quiet -hier -filter \
  {REF_NAME == RAMB36E1 && NAME =~ *FAILED_RECORD_STORE*}]
set record_ram64m [get_cells -quiet -hier -filter \
  {REF_NAME == RAM64M && NAME =~ *FAILED_RECORD_STORE*}]
set record_ramd64e [get_cells -quiet -hier -filter \
  {REF_NAME == RAMD64E && NAME =~ *FAILED_RECORD_STORE*}]
set record_fdre [get_cells -quiet -hier -filter \
  {REF_NAME == FDRE && NAME =~ *FAILED_RECORD_STORE*}]
set index_ramb18 [get_cells -quiet -hier -filter \
  {REF_NAME == RAMB18E1 && NAME =~ *PROBE_INDEX_STORE*}]
set index_ramb36 [get_cells -quiet -hier -filter \
  {REF_NAME == RAMB36E1 && NAME =~ *PROBE_INDEX_STORE*}]
set index_fdre [get_cells -quiet -hier -filter \
  {REF_NAME == FDRE && NAME =~ *PROBE_INDEX_STORE*}]

set lines [list \
  "TASK=R1H_PRECOMMIT_MEMORY_INFERENCE" \
  "VIVADO_VERSION=[version -short]" \
  "PART=$part" \
  "TOP=r1h_memory_inference_top" \
  "FAILED_RECORD_RAMB18=[llength $record_ramb18]" \
  "FAILED_RECORD_RAMB36=[llength $record_ramb36]" \
  "FAILED_RECORD_RAM64M=[llength $record_ram64m]" \
  "FAILED_RECORD_RAMD64E=[llength $record_ramd64e]" \
  "FAILED_RECORD_HIERARCHY_FDRE=[llength $record_fdre]" \
  "PROBE_INDEX_RAMB18=[llength $index_ramb18]" \
  "PROBE_INDEX_RAMB36=[llength $index_ramb36]" \
  "PROBE_INDEX_HIERARCHY_FDRE=[llength $index_fdre]"]

foreach cell [lsort -dictionary [concat $record_ramb18 $index_ramb18]] {
  lappend lines "RAMB18_CELL=[get_property NAME $cell]"
}

set gate PASS
if {[llength $record_ramb18] != 6 ||
    [llength $record_ramb36] != 0 ||
    [llength $record_ram64m] != 0 ||
    [llength $record_ramd64e] != 0 ||
    [llength $index_ramb18] != 3 ||
    [llength $index_ramb36] != 0} {
  set gate FAIL
}
lappend lines "MEMORY_INFERENCE_GATE=$gate"
write_lines [file join $evidence_root MEMORY_INFERENCE_RESULT.txt] $lines
puts "MEMORY_INFERENCE_GATE=$gate"
if {$gate ne "PASS"} { error "R1h pre-commit memory inference gate failed" }
exit
