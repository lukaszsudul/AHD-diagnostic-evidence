if {$argc != 3} {
    error "USAGE: inventory_checkpoint.tcl <dcp_path> <output_dir> <role>"
}

set dcp_path [lindex $argv 0]
set out_dir  [lindex $argv 1]
set role     [lindex $argv 2]
file mkdir $out_dir

proc write_text {path text} {
    set fh [open $path w]
    puts -nonewline $fh $text
    close $fh
}

proc prop_or_na {obj prop} {
    if {[catch {set value [get_property $prop $obj]}]} {
        return "NOT_AVAILABLE"
    }
    return $value
}

proc csv_field {value} {
    set escaped [string map [list "\"" "\"\""] $value]
    return "\"$escaped\""
}

proc must_report {label script out_path} {
    puts "AUDIT_REPORT_START=$label"
    if {[catch {uplevel #0 $script} err opts]} {
        puts "AUDIT_REPORT_ERROR=$label:$err"
        return -options $opts $err
    }
    if {![file exists $out_path] || [file size $out_path] == 0} {
        error "MANDATORY_REPORT_EMPTY=$label:$out_path"
    }
    puts "AUDIT_REPORT_PASS=$label:[file size $out_path]"
}

puts "AUDIT_ROLE=$role"
puts "AUDIT_STAGE=OPEN_CHECKPOINT"
puts "AUDIT_DCP=$dcp_path"
open_checkpoint $dcp_path

set design [current_design]
set part [prop_or_na $design PART]
set design_mode [prop_or_na $design DESIGN_MODE]
set top [prop_or_na $design TOP]

set summary "ROLE=$role\nCURRENT_DESIGN=$design\nPART=$part\nTOP_PROPERTY=$top\nDESIGN_MODE=$design_mode\n"
foreach prop {NAME TYPE STATUS IS_IMPLEMENTED IS_PLACED IS_ROUTED NEEDS_REFRESH} {
    append summary "$prop=[prop_or_na $design $prop]\n"
}
write_text [file join $out_dir CURRENT_DESIGN_PROPERTIES.txt] $summary

set report_path [file join $out_dir CURRENT_DESIGN_REPORT_PROPERTY.txt]
must_report CURRENT_DESIGN_REPORT_PROPERTY [list report_property -all -file $report_path [current_design]] $report_path

set pfh [open [file join $out_dir PORT_INVENTORY.csv] w]
puts $pfh "name,direction,package_pin,bank,iostandard,drive,slew,pulltype,diff_term,in_term,loc"
foreach port [lsort [get_ports -quiet *]] {
    set vals [list \
        $port \
        [prop_or_na $port DIRECTION] \
        [prop_or_na $port PACKAGE_PIN] \
        [prop_or_na $port BANK] \
        [prop_or_na $port IOSTANDARD] \
        [prop_or_na $port DRIVE] \
        [prop_or_na $port SLEW] \
        [prop_or_na $port PULLTYPE] \
        [prop_or_na $port DIFF_TERM] \
        [prop_or_na $port IN_TERM] \
        [prop_or_na $port LOC]]
    set quoted {}
    foreach v $vals { lappend quoted [csv_field $v] }
    puts $pfh [join $quoted ,]
}
close $pfh

set cfh [open [file join $out_dir CLOCK_INVENTORY.csv] w]
puts $cfh "name,period,waveform,is_generated,master_clock,source_pins"
foreach clk [lsort [get_clocks -quiet *]] {
    set vals [list \
        $clk \
        [prop_or_na $clk PERIOD] \
        [prop_or_na $clk WAVEFORM] \
        [prop_or_na $clk IS_GENERATED] \
        [prop_or_na $clk MASTER_CLOCK] \
        [prop_or_na $clk SOURCE_PINS]]
    set quoted {}
    foreach v $vals { lappend quoted [csv_field $v] }
    puts $cfh [join $quoted ,]
}
close $cfh

set ref_counts [dict create]
set all_cells [get_cells -hierarchical -quiet *]
foreach cell $all_cells {
    set ref [prop_or_na $cell REF_NAME]
    if {$ref eq ""} { set ref "EMPTY_REF_NAME" }
    dict incr ref_counts $ref
}
set hfh [open [file join $out_dir HIERARCHY_SUMMARY.txt] w]
puts $hfh "TOTAL_CELLS=[llength $all_cells]"
foreach ref [lsort [dict keys $ref_counts]] {
    puts $hfh "$ref=[dict get $ref_counts $ref]"
}
close $hfh

set path [file join $out_dir ROUTE_STATUS.rpt]
must_report ROUTE_STATUS [list report_route_status -file $path] $path

set path [file join $out_dir TIMING_SUMMARY.rpt]
must_report TIMING_SUMMARY [list report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 20 -file $path] $path

set path [file join $out_dir CHECK_TIMING_VERBOSE.rpt]
must_report CHECK_TIMING_VERBOSE [list check_timing -verbose -file $path] $path

set path [file join $out_dir DRC_SUMMARY.rpt]
must_report DRC_SUMMARY [list report_drc -file $path] $path

set path [file join $out_dir UTILIZATION.rpt]
must_report UTILIZATION [list report_utilization -file $path] $path

set path [file join $out_dir UTILIZATION_HIERARCHICAL.rpt]
must_report UTILIZATION_HIERARCHICAL [list report_utilization -hierarchical -hierarchical_depth 20 -file $path] $path

set path [file join $out_dir CLOCK_UTILIZATION.rpt]
must_report CLOCK_UTILIZATION [list report_clock_utilization -file $path] $path

set path [file join $out_dir CLOCKS.rpt]
must_report CLOCKS [list report_clocks -file $path] $path

set path [file join $out_dir CLOCK_INTERACTION.rpt]
must_report CLOCK_INTERACTION [list report_clock_interaction -file $path] $path

set path [file join $out_dir REPORT_IO.rpt]
must_report REPORT_IO [list report_io -file $path] $path

set path [file join $out_dir EXCEPTIONS_COVERAGE.rpt]
must_report EXCEPTIONS_COVERAGE [list report_exceptions -coverage -file $path] $path

set path [file join $out_dir CDC_DETAILS.rpt]
must_report CDC_DETAILS [list report_cdc -details -file $path] $path

set path [file join $out_dir DESIGN_ANALYSIS_CONGESTION.rpt]
must_report DESIGN_ANALYSIS_CONGESTION [list report_design_analysis -congestion -file $path] $path

puts "AUDIT_RESULT=INVENTORY_COMPLETE"
close_design
exit 0
