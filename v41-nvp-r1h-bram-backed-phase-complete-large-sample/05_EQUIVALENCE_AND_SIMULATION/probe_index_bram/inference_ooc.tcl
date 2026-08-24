set worktree {C:/FPGA/WORKTREES/V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE}
read_verilog -sv [file join $worktree rtl/v41/r1h_probe_index_bram_store.sv]
synth_design -top r1h_probe_index_bram_store -part xc7a35tcsg325-2 \
  -mode out_of_context -flatten_hierarchy none
report_utilization -file probe_index_bram_utilization.rpt
set fp [open probe_index_bram_primitives.csv w]
puts $fp {primitive,count}
foreach pattern {RAMB18E1 RAMB36E1 FDRE FDSE FDCE RAM32M RAM64M RAMD64E LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 MUXF7 MUXF8} {
  set cells [get_cells -hier -quiet -filter "REF_NAME == $pattern"]
  puts $fp "$pattern,[llength $cells]"
}
close $fp
set ram_fp [open probe_index_bram_cells.txt w]
foreach cell [lsort [get_cells -hier -quiet -filter {REF_NAME =~ RAMB*}]] {
  puts $ram_fp "$cell [get_property REF_NAME $cell]"
}
close $ram_fp
exit
