puts "SCRIPT_ENTERED"
flush stdout

if {$argc != 4} {
    puts stderr "USAGE: run_power_breakdown.tcl <role> <dcp_path> <output_root> <expected_top>"
    exit 64
}

set role         [lindex $argv 0]
set dcp_path     [file normalize [lindex $argv 1]]
set output_root  [file normalize [lindex $argv 2]]
set expected_top [lindex $argv 3]
file mkdir $output_root

set ::command_log [open [file join $output_root REPORT_COMMAND_SEQUENCE.txt] w]
set ::design_open 0

proc csv_field {value} {
    return "\"[string map [list \" \"\"] $value]\""
}

proc prop_or_na {object property} {
    if {[catch {set value [get_property $property $object]}]} {
        return "NOT_AVAILABLE"
    }
    if {$value eq ""} { return "UNSET" }
    return $value
}

proc log_command {label command} {
    puts $::command_log "$label=[join $command { }]"
    flush $::command_log
}

proc require_nonempty {label path} {
    if {![file exists $path] || [file size $path] <= 0} {
        error "MANDATORY_OUTPUT_MISSING_OR_EMPTY=$label:$path"
    }
    puts "REPORT_PASS=$label:[file size $path]"
}

proc run_mandatory_report {label command path} {
    log_command $label $command
    if {[catch {uplevel #0 $command} message options]} {
        error "MANDATORY_REPORT_FAILED=$label:$message"
    }
    require_nonempty $label $path
}

proc write_text {path text} {
    set handle [open $path w]
    puts -nonewline $handle $text
    close $handle
}

proc capture_inventory {phase} {
    set root $::output_root
    set path [file join $root "${phase}_OPERATING_CONDITIONS_ALL.rpt"]
    run_mandatory_report "${phase}_OPERATING_CONDITIONS_ALL" [list report_operating_conditions -all -file $path] $path

    set path [file join $root "${phase}_OPERATING_CONDITIONS_CORE_VOLTAGE.rpt"]
    run_mandatory_report "${phase}_OPERATING_CONDITIONS_CORE_VOLTAGE" [list report_operating_conditions -voltage {VCCINT VCCAUX} -file $path] $path

    set path [file join $root "${phase}_SWITCHING_ACTIVITY_TOP_PORTS.rpt"]
    run_mandatory_report "${phase}_SWITCHING_ACTIVITY_TOP_PORTS" [list report_switching_activity -toggle_rate -average -file $path [get_ports -quiet *]] $path

    set path [file join $root "${phase}_SWITCHING_ACTIVITY_DEFAULTS.rpt"]
    run_mandatory_report "${phase}_SWITCHING_ACTIVITY_DEFAULTS" [list report_switching_activity -default_static_probability -default_toggle_rate -file $path] $path

    set path [file join $root "${phase}_CLOCKS.rpt"]
    run_mandatory_report "${phase}_CLOCKS" [list report_clocks -file $path] $path

    set path [file join $root "${phase}_CLOCK_NETWORKS.rpt"]
    run_mandatory_report "${phase}_CLOCK_NETWORKS" [list report_clock_networks -file $path] $path

    set path [file join $root "${phase}_CLOCK_NETWORK_ENDPOINTS.rpt"]
    run_mandatory_report "${phase}_CLOCK_NETWORK_ENDPOINTS" [list report_clock_networks -endpoints_only -expand_buckets -file $path] $path
}

proc capture_object_power_properties {} {
    set root $::output_root
    set properties_csv [open [file join $root OBJECT_POWER_PROPERTIES.csv] w]
    puts $properties_csv "object_class,object_name,property,value"

    set all_properties [open [file join $root OBJECT_PROPERTIES_ALL.txt] w]
    set seen [dict create]

    set banks [get_iobanks -quiet]
    foreach bank $banks {
        set key "IOBANK|$bank"
        dict set seen $key 1
        puts $all_properties "===== IOBANK $bank ====="
        foreach property [lsort [list_property $bank]] {
            set value [prop_or_na $bank $property]
            puts $all_properties "$property=$value"
            if {[regexp -nocase {(power|current|voltage|toggle|switch|activity|static|dynamic)} $property]} {
                puts $properties_csv "[csv_field IOBANK],[csv_field $bank],[csv_field $property],[csv_field $value]"
            }
        }
    }

    foreach rail [get_power_rails -quiet] {
        puts $all_properties "===== POWER_RAIL $rail ====="
        foreach property [lsort [list_property $rail]] {
            set value [prop_or_na $rail $property]
            puts $all_properties "$property=$value"
            if {[regexp -nocase {(power|current|voltage|toggle|switch|activity|static|dynamic)} $property]} {
                puts $properties_csv "[csv_field POWER_RAIL],[csv_field $rail],[csv_field $property],[csv_field $value]"
            }
        }
    }

    foreach port [lsort [get_ports -quiet *]] {
        puts $all_properties "===== PORT $port ====="
        foreach property [lsort [list_property $port]] {
            set value [prop_or_na $port $property]
            puts $all_properties "$property=$value"
            if {[regexp -nocase {(power|current|voltage|toggle|switch|activity|static|dynamic)} $property]} {
                puts $properties_csv "[csv_field PORT],[csv_field $port],[csv_field $property],[csv_field $value]"
            }
        }

        set port_nets [get_nets -quiet -of_objects $port]
        foreach net $port_nets {
            set key "NET|$net"
            if {![dict exists $seen $key]} {
                dict set seen $key 1
                puts $all_properties "===== NET $net ====="
                foreach property [lsort [list_property $net]] {
                    set value [prop_or_na $net $property]
                    puts $all_properties "$property=$value"
                    if {[regexp -nocase {(power|current|voltage|toggle|switch|activity|static|dynamic)} $property]} {
                        puts $properties_csv "[csv_field NET],[csv_field $net],[csv_field $property],[csv_field $value]"
                    }
                }
            }
        }

        foreach cell [get_cells -quiet -of_objects $port_nets] {
            set ref_name [prop_or_na $cell REF_NAME]
            if {![regexp -nocase {(IOBUF|IBUF|OBUF|OBUFT)} $ref_name]} { continue }
            set key "CELL|$cell"
            if {[dict exists $seen $key]} { continue }
            dict set seen $key 1
            puts $all_properties "===== IO_CELL $cell REF_NAME=$ref_name ====="
            foreach property [lsort [list_property $cell]] {
                set value [prop_or_na $cell $property]
                puts $all_properties "$property=$value"
                if {[regexp -nocase {(power|current|voltage|toggle|switch|activity|static|dynamic)} $property]} {
                    puts $properties_csv "[csv_field IO_CELL],[csv_field $cell],[csv_field $property],[csv_field $value]"
                }
            }
        }
    }
    close $all_properties
    close $properties_csv
}

proc capture_port_bank_inventory {} {
    set root $::output_root
    set handle [open [file join $root PORT_IOBANK_INVENTORY.csv] w]
    puts $handle "port,package_pin,iobank,direction,iostandard,drive,slew,pulltype,in_term,diff_term,clock_association"
    foreach port [lsort [get_ports -quiet *]] {
        set banks [get_iobanks -quiet -of_objects $port]
        if {[llength $banks] == 0} { set banks "NOT_AVAILABLE" }
        if {[catch {set clocks [get_clocks -quiet -of_objects $port]}]} { set clocks "NOT_AVAILABLE" }
        if {[llength $clocks] == 0} { set clocks "NONE_PROVEN" }
        set values [list $port [prop_or_na $port PACKAGE_PIN] $banks [prop_or_na $port DIRECTION] [prop_or_na $port IOSTANDARD] [prop_or_na $port DRIVE] [prop_or_na $port SLEW] [prop_or_na $port PULLTYPE] [prop_or_na $port IN_TERM] [prop_or_na $port DIFF_TERM] $clocks]
        set quoted {}
        foreach value $values { lappend quoted [csv_field $value] }
        puts $handle [join $quoted ,]
    }
    close $handle
}

proc main {} {
    puts "POWER_BREAKDOWN_ROLE=$::role"
    puts "POWER_BREAKDOWN_DCP=$::dcp_path"
    log_command OPEN_CHECKPOINT [list open_checkpoint $::dcp_path]
    open_checkpoint $::dcp_path
    set ::design_open 1

    set design [current_design]
    set top_property [prop_or_na $design TOP]
    set part [prop_or_na $design PART]
    set is_routed [prop_or_na $design IS_ROUTED]
    set design_mode [prop_or_na $design DESIGN_MODE]
    if {$top_property ne $::expected_top} { error "WRONG_TOP=$top_property:EXPECTED=$::expected_top" }
    if {$part ne "xc7a35tcsg325-2"} { error "WRONG_PART=$part" }

    set path [file join $::output_root ROUTE_STATUS.rpt]
    run_mandatory_report ROUTE_STATUS [list report_route_status -file $path] $path
    set route_handle [open $path r]
    set route_text [read $route_handle]
    close $route_handle
    if {![regexp {# of routable nets\.+\s*:\s*([0-9]+)\s*:} $route_text unused routable_nets]} {
        error "ROUTE_STATUS_PARSE_FAILED=ROUTABLE_NETS"
    }
    if {![regexp {# of fully routed nets\.+\s*:\s*([0-9]+)\s*:} $route_text unused fully_routed_nets]} {
        error "ROUTE_STATUS_PARSE_FAILED=FULLY_ROUTED_NETS"
    }
    if {![regexp {# of nets with routing errors\.+\s*:\s*([0-9]+)\s*:} $route_text unused routing_error_nets]} {
        error "ROUTE_STATUS_PARSE_FAILED=ROUTING_ERRORS"
    }
    if {$routing_error_nets != 0 || $fully_routed_nets != $routable_nets} {
        error "CHECKPOINT_NOT_ROUTED=ROUTABLE_$routable_nets:FULLY_$fully_routed_nets:ERRORS_$routing_error_nets"
    }
    set gate "ROLE=$::role\nCURRENT_DESIGN=$design\nTOP_PROPERTY=$top_property\nEXPECTED_TOP=$::expected_top\nPART=$part\nIS_ROUTED_PROPERTY=$is_routed\nDESIGN_MODE=$design_mode\nROUTABLE_NETS=$routable_nets\nFULLY_ROUTED_NETS=$fully_routed_nets\nROUTING_ERROR_NETS=$routing_error_nets\nIS_ROUTED=YES\n"
    write_text [file join $::output_root DESIGN_IDENTITY_GATE.txt] $gate
    set path [file join $::output_root REPORT_IO.rpt]
    run_mandatory_report REPORT_IO [list report_io -file $path] $path
    set path [file join $::output_root REPORT_IO.xml]
    run_mandatory_report REPORT_IO_XML [list report_io -format xml -file $path] $path
    set path [file join $::output_root UTILIZATION_HIERARCHICAL.rpt]
    run_mandatory_report UTILIZATION_HIERARCHICAL [list report_utilization -hierarchical -hierarchical_depth 0 -file $path] $path
    capture_port_bank_inventory

    capture_inventory PRE

    set path [file join $::output_root REPORT_POWER_STANDARD.rpt]
    run_mandatory_report POWER_STANDARD [list report_power -file $path] $path

    set path [file join $::output_root REPORT_POWER_HIERARCHY_ALL_VERBOSE.rpt]
    run_mandatory_report POWER_HIERARCHY_ALL_VERBOSE [list report_power -hier all -hierarchical_depth 0 -l 0 -verbose -file $path] $path

    set path [file join $::output_root REPORT_POWER_HIERARCHY_POWER.rpt]
    run_mandatory_report POWER_HIERARCHY_POWER [list report_power -hier power -hierarchical_depth 0 -file $path] $path

    set path [file join $::output_root REPORT_POWER_ADVISORY.rpt]
    run_mandatory_report POWER_ADVISORY [list report_power -advisory -file $path] $path

    set path [file join $::output_root REPORT_POWER.xml]
    run_mandatory_report POWER_XML [list report_power -hier all -hierarchical_depth 0 -l 0 -format xml -file $path] $path

    set text_path [file join $::output_root REPORT_POWER_WITH_RPX.rpt]
    set rpx_path [file join $::output_root REPORT_POWER.rpx]
    log_command POWER_RPX [list report_power -hier all -hierarchical_depth 0 -l 0 -rpx $rpx_path -file $text_path]
    if {[catch {report_power -hier all -hierarchical_depth 0 -l 0 -rpx $rpx_path -file $text_path} message options]} {
        error "MANDATORY_REPORT_FAILED=POWER_RPX:$message"
    }
    require_nonempty POWER_RPX_TEXT $text_path
    require_nonempty POWER_RPX $rpx_path

    capture_object_power_properties
    capture_inventory POST

    write_text [file join $::output_root OPTIONAL_REPORTS.txt] "REPORT_SSN_RUN=NO\nREASON=SUPPLEMENTARY_ONLY_NOT_REQUIRED_FOR_POWER_BREAKDOWN\n"
    puts "POWER_BREAKDOWN_RESULT=PASS"
}

if {[catch {main} message options]} {
    puts stderr "POWER_BREAKDOWN_RESULT=FAIL"
    puts stderr "POWER_BREAKDOWN_ERROR=$message"
    write_text [file join $output_root POWER_BREAKDOWN_FAIL.txt] "ERROR=$message\nOPTIONS=$options\n"
    if {$::design_open} { catch {close_design} }
    close $::command_log
    exit 1
}

if {$::design_open} { close_design }
close $::command_log
exit 0
