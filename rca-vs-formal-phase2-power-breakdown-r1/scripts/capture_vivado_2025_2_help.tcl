if {$argc != 1} {
    puts stderr "USAGE: vivado -mode batch -source capture_help.tcl -tclargs <output_dir>"
    exit 2
}

set out_dir [file normalize [lindex $argv 0]]
file mkdir $out_dir

set commands {
    report_power
    report_operating_conditions
    report_switching_activity
    report_clock_networks
    report_clocks
    report_io
    get_iobanks
    get_power_rails
    report_property
    list_property
    open_report
    report_objects
    report_utilization
    report_ssn
    get_clocks
    all_registers
    get_cells
    get_ports
    get_pins
    get_nets
    open_checkpoint
    close_design
}

set version_file [open [file join $out_dir VIVADO_VERSION.txt] w]
puts $version_file [version]
close $version_file

set summary [open [file join $out_dir HELP_CAPTURE_SUMMARY.csv] w]
puts $summary "command,status,message"
foreach command $commands {
    set path [file join $out_dir "${command}.help.txt"]
    if {[catch {set help_text [help $command]} message options]} {
        set escaped [string map [list "\"" "\"\"" "\r" " " "\n" " "] $message]
        puts $summary "${command},UNAVAILABLE,\"${escaped}\""
        set handle [open $path w]
        puts $handle "COMMAND=${command}"
        puts $handle "STATUS=UNAVAILABLE"
        puts $handle "MESSAGE=${message}"
        close $handle
    } else {
        set handle [open $path w]
        puts -nonewline $handle $help_text
        close $handle
        puts $summary "${command},AVAILABLE,\"\""
    }
}
close $summary

puts "HELP_CAPTURE_RESULT=PASS"
exit 0
