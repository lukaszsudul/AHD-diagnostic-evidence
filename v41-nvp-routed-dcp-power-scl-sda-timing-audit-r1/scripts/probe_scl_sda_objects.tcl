if {$argc != 3} {
    error "USAGE: probe_scl_sda_objects.tcl <dcp_path> <output_dir> <role>"
}

set dcp_path [lindex $argv 0]
set out_dir  [lindex $argv 1]
set role     [lindex $argv 2]
file mkdir $out_dir

proc prop_or_na {obj prop} {
    if {[catch {set value [get_property $prop $obj]}]} { return "NOT_AVAILABLE" }
    return $value
}

proc obj_line {obj} {
    set cls [prop_or_na $obj CLASS]
    set result "OBJECT=$obj CLASS=$cls"
    foreach prop {NAME REF_NAME ORIG_REF_NAME REF_PIN_NAME DIRECTION IS_SEQUENTIAL ASYNC_REG SHREG_EXTRACT DONT_TOUCH KEEP LOC BEL SITE CLOCK_REGION IOB ROUTE_STATUS TYPE} {
        append result " $prop=[prop_or_na $obj $prop]"
    }
    return $result
}

proc dump_collection {fh label collection} {
    puts $fh "${label}_COUNT=[llength $collection]"
    set idx 0
    foreach obj [lsort $collection] {
        puts $fh "${label}_${idx}=[obj_line $obj]"
        incr idx
    }
}

open_checkpoint $dcp_path

set raw_path [file join $out_dir "${role}_SCL_SDA_RAW_CONNECTIVITY_PROBE.txt"]
set fh [open $raw_path w]
puts $fh "ROLE=$role"
puts $fh "DCP=$dcp_path"
puts $fh "CURRENT_DESIGN=[current_design]"
puts $fh "TOP=[prop_or_na [current_design] TOP]"
puts $fh "PART=[prop_or_na [current_design] PART]"

set all_cells [get_cells -hierarchical -quiet *]

foreach {line port_name} {SCL nvp_scl SDA nvp_sda} {
    puts $fh "BEGIN_LINE=$line"
    set port [get_ports -quiet $port_name]
    dump_collection $fh "${line}_PORT" $port
    set port_nets [get_nets -quiet -segments -of_objects $port]
    dump_collection $fh "${line}_PORT_NET_SEGMENT" $port_nets
    set port_net_pins [get_pins -quiet -leaf -of_objects $port_nets]
    dump_collection $fh "${line}_PORT_NET_PIN" $port_net_pins

    set io_pins {}
    foreach pin $port_net_pins {
        if {[prop_or_na $pin REF_PIN_NAME] eq "IO"} { lappend io_pins $pin }
    }
    dump_collection $fh "${line}_IOBUF_IO_PIN" $io_pins

    set iobufs {}
    foreach pin $io_pins {
        foreach cell [get_cells -quiet -of_objects $pin] {
            if {[prop_or_na $cell REF_NAME] eq "IOBUF"} { lappend iobufs $cell }
        }
    }
    set iobufs [lsort -unique $iobufs]
    dump_collection $fh "${line}_IOBUF_CELL" $iobufs

    foreach iobuf $iobufs {
        foreach refpin {IO I T O} {
            set pins [get_pins -quiet "$iobuf/$refpin"]
            dump_collection $fh "${line}_IOBUF_${refpin}_PIN" $pins
            set nets [get_nets -quiet -segments -of_objects $pins]
            dump_collection $fh "${line}_IOBUF_${refpin}_NET" $nets
            set net_pins [get_pins -quiet -leaf -of_objects $nets]
            dump_collection $fh "${line}_IOBUF_${refpin}_NET_PIN" $net_pins
            if {$refpin eq "I"} {
                set drivers {}
                foreach np $net_pins {
                    if {[prop_or_na $np DIRECTION] eq "OUT"} { lappend drivers $np }
                }
                dump_collection $fh "${line}_IOBUF_I_DRIVER_PIN" $drivers
                set driver_cells {}
                foreach dp $drivers { lappend driver_cells {*}[get_cells -quiet -of_objects $dp] }
                dump_collection $fh "${line}_IOBUF_I_DRIVER_CELL" [lsort -unique $driver_cells]
            }
            if {$refpin eq "T"} {
                set drivers {}
                foreach np $net_pins {
                    if {[prop_or_na $np DIRECTION] eq "OUT"} { lappend drivers $np }
                }
                dump_collection $fh "${line}_IOBUF_T_DIRECT_DRIVER_PIN" $drivers
                set driver_cells {}
                foreach dp $drivers { lappend driver_cells {*}[get_cells -quiet -of_objects $dp] }
                dump_collection $fh "${line}_IOBUF_T_DIRECT_DRIVER_CELL" [lsort -unique $driver_cells]
                set starts [all_fanin -flat -startpoints_only -to $pins]
                dump_collection $fh "${line}_IOBUF_T_FANIN_STARTPOINT" $starts
            }
            if {$refpin eq "O"} {
                set loads {}
                foreach np $net_pins {
                    if {[prop_or_na $np DIRECTION] eq "IN"} { lappend loads $np }
                }
                dump_collection $fh "${line}_IOBUF_O_DIRECT_LOAD_PIN" $loads
                set endpoints [all_fanout -flat -endpoints_only -from $pins]
                dump_collection $fh "${line}_IOBUF_O_FANOUT_ENDPOINT" $endpoints
            }
        }
    }

    set line_lc [string tolower $line]
    set candidate_cells {}
    foreach cell $all_cells {
        set name_lc [string tolower $cell]
        if {[string first "${line_lc}_sync" $name_lc] >= 0 ||
            [string first "${line_lc}_filter" $name_lc] >= 0 ||
            [string first "${line_lc}_oen" $name_lc] >= 0 ||
            [string first "${line_lc}_timeout" $name_lc] >= 0 ||
            [string first "${line_lc}_low_released" $name_lc] >= 0} {
            lappend candidate_cells $cell
        }
    }
    dump_collection $fh "${line}_NAME_SUPPORTED_CANDIDATE_CELL" [lsort -unique $candidate_cells]
    puts $fh "END_LINE=$line"
}

set decision_candidates {}
foreach cell $all_cells {
    set name_lc [string tolower $cell]
    foreach token {last_ack cur_error nack_count first_error any_error nack_log data_rx fsm_onehot_state} {
        if {[string first $token $name_lc] >= 0} {
            lappend decision_candidates $cell
            break
        }
    }
}
dump_collection $fh "DECISION_NAME_SUPPORTED_CANDIDATE_CELL" [lsort -unique $decision_candidates]

close $fh
puts "AUDIT_RESULT=SCL_SDA_OBJECT_PROBE_COMPLETE"
close_design
exit 0
