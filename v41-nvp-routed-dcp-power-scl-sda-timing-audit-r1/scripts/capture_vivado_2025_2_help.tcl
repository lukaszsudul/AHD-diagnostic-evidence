set task_root {C:/FPGA/V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1}
set help_dir  [file join $task_root raw VIVADO_HELP_2025_2]
file mkdir $help_dir

proc write_text {path text} {
    set fh [open $path w]
    puts -nonewline $fh $text
    close $fh
}

set help_cmds {
    version
    open_checkpoint
    report_power
    report_timing
    get_timing_paths
    report_delay_calculation
    report_io
    report_property
    report_exceptions
    report_cdc
    report_design_analysis
    report_route_status
    report_timing_summary
    check_timing
    report_drc
    report_utilization
    report_clock_utilization
    report_clocks
    report_clock_interaction
    get_nets
    get_net_delays
    get_nodes
    get_wires
    get_sites
    get_site_pins
    get_bels
    get_pins
    get_cells
    all_fanin
    all_fanout
}

set version_out [file join $help_dir VIVADO_VERSION.txt]
if {[catch {set version_text [version]} err]} {
    write_text $version_out "VERSION_CAPTURE_ERROR=$err\n"
} else {
    write_text $version_out "$version_text\n"
}

foreach cmd $help_cmds {
    set out [file join $help_dir "${cmd}.help.txt"]
    if {[catch {set help_text [help $cmd]} err]} {
        write_text $out "HELP_CAPTURE_ERROR=$err\n"
    } else {
        write_text $out "$help_text\n"
    }
}

puts "AUDIT_RESULT=VIVADO_HELP_CAPTURE_COMPLETE"
exit 0
