if {$argc != 3} {
    error "USAGE: probe_direct_net_delays.tcl <dcp_path> <output_file> <role>"
}

set dcp_path [lindex $argv 0]
set out_path [lindex $argv 1]
set role [lindex $argv 2]

proc prop_or_na {obj prop} {
    if {[catch {set value [get_property $prop $obj]}]} { return "NOT_AVAILABLE" }
    return $value
}

proc pin_by_ref {cell refpin} {
    return [get_pins -quiet -of_objects $cell -filter "REF_PIN_NAME == $refpin"]
}

proc dump_delays {fh role line semantic mode net_obj target_pin} {
    if {$mode eq "INTERCONNECT_ONLY"} {
        set delays [get_net_delays -quiet -interconnect_only -of_objects $net_obj]
        set target_delays [get_net_delays -quiet -interconnect_only -of_objects $net_obj -to $target_pin]
    } else {
        set delays [get_net_delays -quiet -of_objects $net_obj]
        set target_delays [get_net_delays -quiet -of_objects $net_obj -to $target_pin]
    }
    puts $fh "ROLE=$role LINE=$line SEMANTIC=$semantic MODE=$mode NET=$net_obj TARGET=$target_pin ALL_DELAY_COUNT=[llength $delays] TARGET_DELAY_COUNT=[llength $target_delays]"
    set index 0
    foreach delay $delays {
        puts $fh "DELAY_${index}=NAME=$delay NET=[prop_or_na $delay NET] TO_PIN=[prop_or_na $delay TO_PIN] FAST_MAX_PS=[prop_or_na $delay FAST_MAX] FAST_MIN_PS=[prop_or_na $delay FAST_MIN] SLOW_MAX_PS=[prop_or_na $delay SLOW_MAX] SLOW_MIN_PS=[prop_or_na $delay SLOW_MIN] ROUTED=[prop_or_na $delay ROUTED]"
        incr index
    }
    puts $fh "TARGET_DELAYS_BEGIN"
    foreach delay $target_delays {
        puts $fh "TARGET_DELAY=NAME=$delay NET=[prop_or_na $delay NET] TO_PIN=[prop_or_na $delay TO_PIN] FAST_MAX_PS=[prop_or_na $delay FAST_MAX] FAST_MIN_PS=[prop_or_na $delay FAST_MIN] SLOW_MAX_PS=[prop_or_na $delay SLOW_MAX] SLOW_MIN_PS=[prop_or_na $delay SLOW_MIN] ROUTED=[prop_or_na $delay ROUTED]"
    }
    puts $fh "TARGET_DELAYS_END"
}

open_checkpoint $dcp_path
set fh [open $out_path w]
puts $fh "ROLE=$role"
puts $fh "DCP=$dcp_path"
puts $fh "CURRENT_DESIGN=[current_design]"
puts $fh "TOP=[prop_or_na [current_design] TOP]"
puts $fh "PART=[prop_or_na [current_design] PART]"

foreach {line port_name} {SCL nvp_scl SDA nvp_sda} {
    set lc [string tolower $line]
    set port [get_ports -quiet $port_name]
    set port_nets [get_nets -quiet -segments -of_objects $port]
    set ibuf_port_pin [get_pins -quiet -leaf -of_objects $port_nets -filter {REF_NAME == IBUF && REF_PIN_NAME == I}]
    set obuft_port_pin [get_pins -quiet -leaf -of_objects $port_nets -filter {REF_NAME == OBUFT && REF_PIN_NAME == O}]
    set ibuf_cell [get_cells -quiet -of_objects $ibuf_port_pin]
    set obuft_cell [get_cells -quiet -of_objects $obuft_port_pin]
    set t_pin [pin_by_ref $obuft_cell T]
    set o_pin [pin_by_ref $ibuf_cell O]

    set t_segments [get_nets -quiet -segments -of_objects $t_pin]
    set raw_segments [get_nets -quiet -segments -of_objects $o_pin]
    set sync0_regex [format {^NVP_AUTOINIT/u_sequence/%s_sync_r_reg\[0\]$} $lc]
    set sync0_cell [get_cells -quiet -hierarchical -regexp $sync0_regex]
    set sync0_d [pin_by_ref $sync0_cell D]

    puts $fh "${line}_T_SEGMENT_COUNT=[llength $t_segments]"
    foreach net_name $t_segments {
        set net_obj [get_nets -quiet $net_name]
        dump_delays $fh $role $line OEN_Q_TO_IOBUF_T FULL $net_obj $t_pin
        dump_delays $fh $role $line OEN_Q_TO_IOBUF_T INTERCONNECT_ONLY $net_obj $t_pin
    }
    puts $fh "${line}_RAW_SEGMENT_COUNT=[llength $raw_segments]"
    foreach net_name $raw_segments {
        set net_obj [get_nets -quiet $net_name]
        dump_delays $fh $role $line IBUF_O_TO_SYNC0 FULL $net_obj $sync0_d
        dump_delays $fh $role $line IBUF_O_TO_SYNC0 INTERCONNECT_ONLY $net_obj $sync0_d
    }
}

close $fh
puts "AUDIT_RESULT=DIRECT_NET_DELAY_PROBE_COMPLETE"
close_design
exit 0
