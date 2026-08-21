if {$argc != 3} {
    error "USAGE: audit_power.tcl <dcp_path> <output_dir> <role>"
}

set dcp_path [lindex $argv 0]
set out_dir  [lindex $argv 1]
set role     [lindex $argv 2]
file mkdir $out_dir

proc must_exist_nonempty {label path} {
    if {![file exists $path] || [file size $path] == 0} {
        error "POWER_REPORT_MISSING_OR_EMPTY=$label:$path"
    }
    puts "POWER_REPORT_PASS=$label:[file size $path]"
}

open_checkpoint $dcp_path

set base [file join $out_dir "${role}_REPORT_POWER.rpt"]
report_power -file $base
must_exist_nonempty BASE $base

set verbose [file join $out_dir "${role}_REPORT_POWER_VERBOSE.rpt"]
report_power -hier all -hierarchical_depth 0 -l 0 -verbose -file $verbose
must_exist_nonempty VERBOSE_DETAIL $verbose

set advisory [file join $out_dir "${role}_REPORT_POWER_ADVISORY.rpt"]
report_power -advisory -file $advisory
must_exist_nonempty ADVISORY $advisory

set xml [file join $out_dir "${role}_REPORT_POWER.xml"]
report_power -format xml -file $xml
must_exist_nonempty XML $xml

puts "AUDIT_RESULT=POWER_REPORTS_COMPLETE"
close_design
exit 0
