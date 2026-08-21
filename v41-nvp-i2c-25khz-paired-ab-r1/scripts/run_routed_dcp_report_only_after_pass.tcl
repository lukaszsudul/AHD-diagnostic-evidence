if {$argc != 3} {
  error "USAGE: run_routed_dcp_report_only_after_pass.tcl ROUTED_DCP OUTPUT_ROOT POST_BUILD_GATE_RESULT"
}

set dcp_path [file normalize [lindex $argv 0]]
set out_root [file normalize [lindex $argv 1]]
set gate_path [file normalize [lindex $argv 2]]
set expected_commit f007dc172d43d30b02729755e60382f8ce3dbff4
set expected_design ahd_capture_top_xdma
set expected_part xc7a35tcsg325-2

proc read_text {path} {
  set fh [open $path r]
  set text [read $fh]
  close $fh
  return $text
}

proc write_text {path text} {
  set fh [open $path w]
  fconfigure $fh -translation lf
  puts -nonewline $fh $text
  close $fh
}

proc prop_or_na {obj prop} {
  if {[catch {set value [get_property $prop $obj]}]} {
    return NOT_AVAILABLE
  }
  if {$value eq ""} {
    return EMPTY
  }
  return $value
}

proc must_nonempty {label path} {
  if {![file isfile $path] || [file size $path] <= 0} {
    error "REPORT_ONLY_OUTPUT_MISSING_OR_EMPTY=$label:$path"
  }
  puts "REPORT_ONLY_OUTPUT_PASS=$label:[file size $path]"
}

proc obj_line {obj} {
  set line "OBJECT=$obj"
  foreach prop {CLASS NAME REF_NAME ORIG_REF_NAME REF_PIN_NAME DIRECTION IS_PRIMITIVE IS_SEQUENTIAL ASYNC_REG SHREG_EXTRACT DONT_TOUCH KEEP LOC BEL SITE CLOCK_REGION IOB INIT ROUTE_STATUS TYPE} {
    append line " $prop=[prop_or_na $obj $prop]"
  }
  return $line
}

proc dump_collection {fh label collection} {
  puts $fh "${label}_COUNT=[llength $collection]"
  set index 0
  foreach obj [lsort $collection] {
    puts $fh "${label}_${index}=[obj_line $obj]"
    incr index
  }
}

if {![file isfile $gate_path]} {
  error "POST_BUILD_GATE_RESULT_MISSING=$gate_path"
}
set gate_text [read_text $gate_path]
if {![regexp -line {^POST_BUILD_GATE=PASS$} $gate_text]} {
  error "POST_BUILD_GATE_NOT_PASS"
}
if {![regexp -line "^SOURCE_HEAD=$expected_commit$" $gate_text]} {
  error "POST_BUILD_GATE_SOURCE_COMMIT_MISMATCH"
}
if {![file isfile $dcp_path] || [file size $dcp_path] <= 0} {
  error "ROUTED_DCP_MISSING_OR_EMPTY=$dcp_path"
}
file mkdir $out_root

puts "REPORT_ONLY_MODE=ROUTED_DCP_AFTER_PASS"
puts "REPORT_ONLY_DCP=$dcp_path"
puts "REPORT_ONLY_OUTPUT_ROOT=$out_root"
open_checkpoint $dcp_path

set design [current_design]
set top [prop_or_na $design TOP]
set part [prop_or_na $design PART]
set is_routed [prop_or_na $design IS_ROUTED]
set status [prop_or_na $design STATUS]
if {$top ne $expected_design} {
  error "REPORT_ONLY_WRONG_TOP=$top:CURRENT_DESIGN=$design"
}
if {$part ne $expected_part} {
  error "REPORT_ONLY_WRONG_PART=$part"
}
if {$is_routed ni {1 true TRUE YES EMPTY NOT_AVAILABLE}} {
  error "REPORT_ONLY_CHECKPOINT_EXPLICITLY_NOT_ROUTED=IS_ROUTED:$is_routed:STATUS:$status"
}

# Routed checkpoints opened in non-project mode may leave the design-level
# IS_ROUTED/STATUS properties empty.  Prove routed completeness using the
# report-only route-status database instead of treating the session metadata
# omission as an implementation failure.
set route_status_path [file join $out_root I25_ROUTE_STATUS.rpt]
report_route_status -file $route_status_path
must_nonempty ROUTE_STATUS $route_status_path
set route_status_text [read_text $route_status_path]
if {![regexp {# of nets with routing errors[^:]*:\s*0\s*:} $route_status_text]} {
  error "REPORT_ONLY_ROUTE_STATUS_NOT_CLEAN"
}

set identity "TASK=V41_NVP_I2C_25KHZ_PAIRED_AB_R1\n"
append identity "TASK_MODE=ROUTED_DCP_REPORT_ONLY_SUPPLEMENT\n"
append identity "UPSTREAM_POST_BUILD_GATE=PASS\n"
append identity "SOURCE_COMMIT=$expected_commit\n"
append identity "DCP=$dcp_path\n"
append identity "DCP_SIZE_BYTES=[file size $dcp_path]\n"
append identity "CURRENT_DESIGN=$design\n"
append identity "TOP=$top\n"
append identity "PART=$part\n"
append identity "IS_ROUTED=$is_routed\n"
append identity "STATUS=$status\n"
append identity "ROUTE_STATUS_ROUTING_ERRORS=0\n"
append identity "ROUTED_PROOF_METHOD=REPORT_ROUTE_STATUS\n"
append identity "OPERATING_CONDITION_CHANGES=0\n"
append identity "SWITCHING_ACTIVITY_CHANGES=0\n"
append identity "IMPLEMENTATION_COMMANDS=0\n"
append identity "BITSTREAM_COMMANDS=0\n"
write_text [file join $out_root I25_REPORT_ONLY_IDENTITY.txt] $identity

set path [file join $out_root I25_CURRENT_DESIGN_PROPERTIES.txt]
report_property -all -file $path $design
must_nonempty CURRENT_DESIGN_PROPERTIES $path

set path [file join $out_root I25_REPORT_POWER.rpt]
report_power -file $path
must_nonempty REPORT_POWER $path
if {[string first "Total On-Chip Power" [read_text $path]] < 0} {
  error "REPORT_POWER_TOTAL_ON_CHIP_POWER_NOT_FOUND"
}

set path [file join $out_root I25_REPORT_POWER_VERBOSE.rpt]
report_power -hier all -hierarchical_depth 0 -l 0 -verbose -file $path
must_nonempty REPORT_POWER_VERBOSE $path

set path [file join $out_root I25_REPORT_POWER_ADVISORY.rpt]
report_power -advisory -file $path
must_nonempty REPORT_POWER_ADVISORY $path

set path [file join $out_root I25_REPORT_POWER.xml]
report_power -format xml -file $path
must_nonempty REPORT_POWER_XML $path

set path [file join $out_root I25_REPORT_IO.rpt]
report_io -file $path
must_nonempty REPORT_IO $path
set io_text [read_text $path]
if {[string first "nvp_scl" $io_text] < 0 || [string first "nvp_sda" $io_text] < 0} {
  error "REPORT_IO_NVP_PORTS_NOT_FOUND"
}

set path [file join $out_root I25_REPORT_IO.xml]
report_io -format xml -file $path
must_nonempty REPORT_IO_XML $path

set path [file join $out_root I25_NVP_HIERARCHICAL_UTILIZATION.rpt]
report_utilization -hierarchical -hierarchical_depth 20 -file $path
must_nonempty NVP_HIERARCHICAL_UTILIZATION $path

set nvp_cells [get_cells -quiet -hierarchical -regexp {^NVP_AUTOINIT$}]
if {[llength $nvp_cells] != 1} {
  error "NVP_AUTOINIT_HIERARCHY_COUNT=[llength $nvp_cells]"
}
set nvp_cell [lindex $nvp_cells 0]
set sequence_cells [get_cells -quiet -hierarchical -regexp {^NVP_AUTOINIT/u_sequence$}]
if {[llength $sequence_cells] != 1} {
  error "NVP_AUTOINIT_SEQUENCE_HIERARCHY_COUNT=[llength $sequence_cells]"
}
set nvp_ref [prop_or_na $nvp_cell REF_NAME]
set nvp_orig_ref [prop_or_na $nvp_cell ORIG_REF_NAME]
if {$nvp_ref ne "v40a_nvp_autoinit" && $nvp_orig_ref ne "v40a_nvp_autoinit"} {
  error "NVP_AUTOINIT_REFERENCE_MISMATCH=REF:$nvp_ref:ORIG_REF:$nvp_orig_ref"
}
set sequence_cell [lindex $sequence_cells 0]
set sequence_ref [prop_or_na $sequence_cell REF_NAME]
set sequence_orig_ref [prop_or_na $sequence_cell ORIG_REF_NAME]
if {$sequence_ref ne "nvp_i2c_bringup_seq_v38ek" && $sequence_orig_ref ne "nvp_i2c_bringup_seq_v38ek"} {
  error "NVP_SEQUENCE_REFERENCE_MISMATCH=REF:$sequence_ref:ORIG_REF:$sequence_orig_ref"
}

set path [file join $out_root I25_NVP_AUTOINIT_PROPERTIES.txt]
report_property -all -file $path $nvp_cell
report_property -all -append -file $path $sequence_cell
must_nonempty NVP_AUTOINIT_PROPERTIES $path

set all_nvp_cells [get_cells -quiet -hierarchical -regexp {^NVP_AUTOINIT/.*}]
if {[llength $all_nvp_cells] <= 0} {
  error "NVP_AUTOINIT_DESCENDANT_CELL_COUNT=0"
}

set boundary_path [file join $out_root I25_NVP_AUTOINIT_BOUNDARY_CONNECTIVITY.txt]
set bfh [open $boundary_path w]
fconfigure $bfh -translation lf
puts $bfh "NVP_AUTOINIT_CELL=$nvp_cell"
puts $bfh "NVP_AUTOINIT_ORIG_REF_NAME=[prop_or_na $nvp_cell ORIG_REF_NAME]"
puts $bfh "NVP_AUTOINIT_DESCENDANT_CELL_COUNT=[llength $all_nvp_cells]"
set boundary_pins [get_pins -quiet -of_objects $nvp_cell]
if {[llength $boundary_pins] <= 0} {
  error "NVP_AUTOINIT_BOUNDARY_PIN_COUNT=0"
}
dump_collection $bfh NVP_BOUNDARY_PIN $boundary_pins
set input_pins {}
set output_pins {}
foreach pin $boundary_pins {
  set direction [prop_or_na $pin DIRECTION]
  if {$direction eq "IN"} { lappend input_pins $pin }
  if {$direction eq "OUT"} { lappend output_pins $pin }
  set nets [get_nets -quiet -segments -of_objects $pin]
  puts $bfh "BOUNDARY_PIN=$pin DIRECTION=$direction NETS=[join [lsort $nets] ,]"
  set direct_pins [get_pins -quiet -leaf -of_objects $nets]
  dump_collection $bfh "BOUNDARY_[string map {/ _ \[ _ \] _} $pin]_DIRECT_LEAF_PIN" $direct_pins
}
if {[llength $input_pins] <= 0 || [llength $output_pins] <= 0} {
  error "NVP_AUTOINIT_BOUNDARY_DIRECTION_DISCOVERY_FAILED:INPUTS=[llength $input_pins]:OUTPUTS=[llength $output_pins]"
}
set fanin_starts [all_fanin -flat -startpoints_only -trace_arcs all $input_pins]
set fanout_ends [all_fanout -flat -endpoints_only -trace_arcs all $output_pins]
dump_collection $bfh NVP_AGGREGATE_FANIN_STARTPOINT $fanin_starts
dump_collection $bfh NVP_AGGREGATE_FANOUT_ENDPOINT $fanout_ends
close $bfh
must_nonempty NVP_AUTOINIT_BOUNDARY_CONNECTIVITY $boundary_path

set sequential_cells {}
set clock_pins {}
foreach cell $all_nvp_cells {
  if {[prop_or_na $cell IS_SEQUENTIAL] in {1 true TRUE YES}} {
    lappend sequential_cells $cell
    foreach pin [get_pins -quiet -of_objects $cell -filter {REF_PIN_NAME == C}] {
      lappend clock_pins $pin
    }
  }
}
set sequential_cells [lsort -unique $sequential_cells]
set clock_pins [lsort -unique $clock_pins]
if {[llength $sequential_cells] <= 0 || [llength $clock_pins] <= 0} {
  error "NVP_AUTOINIT_SEQUENTIAL_CLOCK_DISCOVERY_FAILED"
}
set nvp_clocks [lsort -unique [get_clocks -quiet -of_objects $clock_pins]]
if {[llength $nvp_clocks] != 1} {
  error "NVP_AUTOINIT_CLOCK_COUNT=[llength $nvp_clocks]"
}
set nvp_clock [lindex $nvp_clocks 0]
set nvp_clock_period [prop_or_na $nvp_clock PERIOD]
if {![string is double -strict $nvp_clock_period] || abs($nvp_clock_period - 16.0) > 0.000001} {
  error "NVP_AUTOINIT_CLOCK_PERIOD_NOT_16NS=$nvp_clock_period"
}
set clock_path [file join $out_root I25_NVP_AUTOINIT_CLOCK_EVIDENCE.txt]
set cfh [open $clock_path w]
fconfigure $cfh -translation lf
puts $cfh "NVP_AUTOINIT_SEQUENTIAL_CELL_COUNT=[llength $sequential_cells]"
puts $cfh "NVP_AUTOINIT_CLOCK_PIN_COUNT=[llength $clock_pins]"
puts $cfh "NVP_AUTOINIT_CLOCK_COUNT=[llength $nvp_clocks]"
puts $cfh "NVP_AUTOINIT_CLOCK=$nvp_clock"
puts $cfh "NVP_AUTOINIT_CLOCK_PERIOD_NS=$nvp_clock_period"
puts $cfh "NVP_AUTOINIT_CLOCK_FREQUENCY_HZ=62500000"
dump_collection $cfh NVP_AUTOINIT_CLOCK_OBJECT $nvp_clocks
dump_collection $cfh NVP_AUTOINIT_SEQUENTIAL_CELL $sequential_cells
dump_collection $cfh NVP_AUTOINIT_CLOCK_PIN $clock_pins
foreach pin $clock_pins {
  set nets [get_nets -quiet -segments -of_objects $pin]
  puts $cfh "CLOCK_PIN=$pin NETS=[join [lsort $nets] ,]"
}
close $cfh
must_nonempty NVP_AUTOINIT_CLOCK_EVIDENCE $clock_path

set tick_count_cells [get_cells -quiet -hierarchical -regexp {^NVP_AUTOINIT/u_sequence/tick_cnt_reg\[[0-9]+\]$}]
set tick_cells [get_cells -quiet -hierarchical -regexp {^NVP_AUTOINIT/u_sequence/tick_reg$}]
if {[llength $tick_count_cells] != 11} {
  error "I2C_TICK_COUNTER_REGISTER_COUNT=[llength $tick_count_cells]:EXPECTED=11"
}
if {[llength $tick_cells] != 1} {
  error "I2C_TICK_REGISTER_COUNT=[llength $tick_cells]:EXPECTED=1"
}
set tick_indexes {}
foreach cell $tick_count_cells {
  if {![regexp {tick_cnt_reg\[([0-9]+)\]$} $cell -> index]} {
    error "I2C_TICK_COUNTER_INDEX_PARSE_FAILED=$cell"
  }
  lappend tick_indexes $index
}
set tick_indexes [lsort -integer -unique $tick_indexes]
if {$tick_indexes ne {0 1 2 3 4 5 6 7 8 9 10}} {
  error "I2C_TICK_COUNTER_INDEX_SET=$tick_indexes"
}
set tick_cell [lindex $tick_cells 0]
set tick_d_pins [get_pins -quiet -of_objects $tick_cell -filter {REF_PIN_NAME == D}]
if {[llength $tick_d_pins] != 1} {
  error "I2C_TICK_D_PIN_COUNT=[llength $tick_d_pins]"
}
set tick_d [lindex $tick_d_pins 0]
set tick_cone_cells [lsort -unique [all_fanin -flat -only_cells -trace_arcs all $tick_d]]
set tick_cone_starts [lsort -unique [all_fanin -flat -startpoints_only -trace_arcs all $tick_d]]
if {[llength $tick_cone_cells] <= 0 || [llength $tick_cone_starts] <= 0} {
  error "I2C_TICK_TERMINAL_DECODE_CONE_EMPTY"
}
set missing_tick_count_cells {}
foreach cell $tick_count_cells {
  if {[lsearch -exact $tick_cone_cells $cell] < 0} {
    lappend missing_tick_count_cells $cell
  }
}
if {[llength $missing_tick_count_cells] != 0} {
  error "I2C_TICK_CONE_MISSING_COUNTER_BITS=$missing_tick_count_cells"
}

set direct_generic_path [file join $out_root I25_I2C_DIVIDER_ELABORATION.txt]
set gfh [open $direct_generic_path w]
fconfigure $gfh -translation lf
puts $gfh "SOURCE_COMMIT=$expected_commit"
puts $gfh "SOURCE_I2C_HZ=25000"
puts $gfh "SOURCE_CLK_HZ=62500000"
puts $gfh "SOURCE_DIVIDER_FORMULA=CLK_HZ/(I2C_HZ*2)"
puts $gfh "SOURCE_DIVIDER=1250"
puts $gfh "EXPECTED_TICK_COUNTER_WIDTH_BITS=11"
puts $gfh "ROUTED_TICK_COUNTER_REGISTER_COUNT=[llength $tick_count_cells]"
puts $gfh "ROUTED_TICK_COUNTER_INDEXES=$tick_indexes"
puts $gfh "ROUTED_TICK_REGISTER_COUNT=[llength $tick_cells]"
puts $gfh "ROUTED_TICK_D_CONE_CELL_COUNT=[llength $tick_cone_cells]"
puts $gfh "ROUTED_TICK_D_CONE_STARTPOINT_COUNT=[llength $tick_cone_starts]"
puts $gfh "ROUTED_TICK_D_CONE_CONTAINS_ALL_11_COUNTER_BITS=YES"
set generic_property_count 0
set direct_i2c_property_count 0
set direct_divider_property_count 0
set i2c_property_match NO
set divider_property_match NO
foreach obj [list $nvp_cell $sequence_cell] {
  foreach prop [list_property $obj] {
    if {[regexp -nocase {(I2C|CLK_HZ|DIVIDER|GENERIC|PARAM)} $prop]} {
      incr generic_property_count
      set value [prop_or_na $obj $prop]
      puts $gfh "DIRECT_PROPERTY_OBJECT=$obj PROPERTY=$prop VALUE=$value"
      set normalized [string map {_ ""} $value]
      if {[regexp -nocase {I2C.*HZ} $prop]} {
        incr direct_i2c_property_count
        if {[regexp {(^|[^0-9])25000([^0-9]|$)} $normalized]} { set i2c_property_match YES }
      }
      if {[regexp -nocase {DIVIDER} $prop]} {
        incr direct_divider_property_count
        if {[regexp {(^|[^0-9])1250([^0-9]|$)} $normalized]} { set divider_property_match YES }
      }
    }
  }
}
puts $gfh "DIRECT_GENERIC_PROPERTY_COUNT=$generic_property_count"
puts $gfh "DIRECT_I2C_HZ_PROPERTY_COUNT=$direct_i2c_property_count"
puts $gfh "DIRECT_DIVIDER_PROPERTY_COUNT=$direct_divider_property_count"
puts $gfh "DIRECT_I2C_HZ_25000_PROPERTY_MATCH=$i2c_property_match"
puts $gfh "DIRECT_DIVIDER_1250_PROPERTY_MATCH=$divider_property_match"
if {$direct_i2c_property_count > 0 && $i2c_property_match ne "YES"} {
  error "DIRECT_I2C_HZ_PROPERTY_CONTRADICTS_25000"
}
if {$direct_divider_property_count > 0 && $divider_property_match ne "YES"} {
  error "DIRECT_DIVIDER_PROPERTY_CONTRADICTS_1250"
}
if {$direct_i2c_property_count == 0 && $direct_divider_property_count == 0} {
  puts $gfh "DIRECT_ELABORATED_GENERIC_PROPERTY=NOT_RETAINED_IN_ROUTED_DCP"
  puts $gfh "ELABORATION_EVIDENCE_METHOD=EXACT_SOURCE_COMMIT_TO_DCP_PROVENANCE_PLUS_11_BIT_TICK_COUNTER_AND_COMPLETE_TERMINAL_DECODE_CONE"
} else {
  puts $gfh "DIRECT_ELABORATED_GENERIC_PROPERTY=PRESENT_SEE_ROWS"
  puts $gfh "ELABORATION_EVIDENCE_METHOD=DIRECT_PROPERTIES_PLUS_STRUCTURAL_COUNTER_AND_TERMINAL_DECODE_CONE"
}
close $gfh
must_nonempty I2C_DIVIDER_ELABORATION $direct_generic_path

set cone_path [file join $out_root I25_I2C_TICK_TERMINAL_DECODE_CONE.txt]
set tfh [open $cone_path w]
fconfigure $tfh -translation lf
dump_collection $tfh I2C_TICK_COUNTER_REGISTER $tick_count_cells
dump_collection $tfh I2C_TICK_REGISTER $tick_cells
dump_collection $tfh I2C_TICK_D_FANIN_CELL $tick_cone_cells
dump_collection $tfh I2C_TICK_D_FANIN_STARTPOINT $tick_cone_starts
foreach cell $tick_cone_cells {
  set pins [get_pins -quiet -of_objects $cell]
  dump_collection $tfh "CONE_[string map {/ _ \[ _ \] _} $cell]_PIN" $pins
  foreach pin $pins {
    set nets [get_nets -quiet -segments -of_objects $pin]
    puts $tfh "CONE_PIN=$pin NETS=[join [lsort $nets] ,]"
  }
}
close $tfh
must_nonempty I2C_TICK_TERMINAL_DECODE_CONE $cone_path

set cone_properties_path [file join $out_root I25_I2C_TICK_CONE_CELL_PROPERTIES.txt]
set first 1
foreach cell $tick_cone_cells {
  if {$first} {
    report_property -all -file $cone_properties_path $cell
    set first 0
  } else {
    report_property -all -append -file $cone_properties_path $cell
  }
}
must_nonempty I2C_TICK_CONE_CELL_PROPERTIES $cone_properties_path

set result "TASK=V41_NVP_I2C_25KHZ_PAIRED_AB_R1\n"
append result "REPORT_ONLY_SUPPLEMENT=PASS\n"
append result "SOURCE_COMMIT=$expected_commit\n"
append result "CURRENT_DESIGN=$design\n"
append result "PART=$part\n"
append result "IS_ROUTED=$is_routed\n"
append result "REPORT_POWER=PASS\n"
append result "REPORT_IO=PASS\n"
append result "NVP_AUTOINIT_HIERARCHY_COUNT=1\n"
append result "NVP_AUTOINIT_SEQUENCE_HIERARCHY_COUNT=1\n"
append result "NVP_AUTOINIT_FANIN_STARTPOINT_COUNT=[llength $fanin_starts]\n"
append result "NVP_AUTOINIT_FANOUT_ENDPOINT_COUNT=[llength $fanout_ends]\n"
append result "NVP_AUTOINIT_CLOCK=$nvp_clock\n"
append result "NVP_AUTOINIT_CLOCK_PERIOD_NS=$nvp_clock_period\n"
append result "I2C_HZ_SOURCE_AND_PROVENANCE=25000\n"
append result "DIVIDER_SOURCE_AND_PROVENANCE=1250\n"
append result "I2C_TICK_COUNTER_REGISTER_COUNT=11\n"
append result "I2C_TICK_COUNTER_INDEXES=$tick_indexes\n"
append result "I2C_TICK_D_CONE_CONTAINS_ALL_COUNTER_BITS=YES\n"
append result "DIRECT_GENERIC_PROPERTY_COUNT=$generic_property_count\n"
append result "DIRECT_I2C_HZ_PROPERTY_COUNT=$direct_i2c_property_count\n"
append result "DIRECT_DIVIDER_PROPERTY_COUNT=$direct_divider_property_count\n"
append result "DIRECT_I2C_HZ_25000_PROPERTY_MATCH=$i2c_property_match\n"
append result "DIRECT_DIVIDER_1250_PROPERTY_MATCH=$divider_property_match\n"
append result "IMPLEMENTATION_COMMANDS=0\n"
append result "DESIGN_PROPERTY_CHANGES=0\n"
append result "OPERATING_CONDITION_CHANGES=0\n"
append result "SWITCHING_ACTIVITY_CHANGES=0\n"
append result "CHECKPOINT_SAVES=0\n"
append result "BITSTREAM_COMMANDS=0\n"
write_text [file join $out_root I25_REPORT_ONLY_RESULT.txt] $result
must_nonempty REPORT_ONLY_RESULT [file join $out_root I25_REPORT_ONLY_RESULT.txt]

close_design
puts "REPORT_ONLY_SUPPLEMENT=PASS"
exit 0
