source "$::R/helpers.tcl"
set ::raw_root $::R
set timing [run_timing_gate]
save timing_result.txt $timing
