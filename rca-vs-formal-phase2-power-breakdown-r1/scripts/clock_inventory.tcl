if {$argc != 4} {
    puts stderr "Usage: vivado -mode batch -source clock_inventory.tcl -tclargs ROLE DCP EXPECTED_TOP OUTPUT_DIR"
    exit 2
}

set role         [lindex $argv 0]
set dcp_path     [file normalize [lindex $argv 1]]
set expected_top [lindex $argv 2]
set out_dir      [file normalize [lindex $argv 3]]

proc csv_quote {value} {
    set escaped [string map [list "\"" "\"\""] $value]
    return "\"$escaped\""
}

proc safe_property {property object} {
    if {[catch {set value [get_property $property $object]}]} {
        return "UNAVAILABLE"
    }
    if {[string length [string trim $value]] == 0} {
        return "UNSET"
    }
    return $value
}

proc require_equal {label actual expected} {
    if {$actual ne $expected} {
        error "$label mismatch: expected '$expected', got '$actual'"
    }
}

file mkdir $out_dir
puts "CLOCK_INVENTORY_SCRIPT_ENTERED"
flush stdout
open_checkpoint $dcp_path

set design [current_design]
set top [safe_property TOP $design]
set part [safe_property PART $design]
require_equal TOP $top $expected_top
require_equal PART $part "xc7a35tcsg325-2"

set summary_path [file join $out_dir CLOCK_REGISTER_INVENTORY_RAW.csv]
set membership_path [file join $out_dir CLOCK_REGISTER_MEMBERSHIP_RAW.csv]
set status_path [file join $out_dir CLOCK_INVENTORY_STATUS.txt]
set sf [open $summary_path w]
set mf [open $membership_path w]

puts $sf "IMAGE_ROLE,CLOCK_NAME,SOURCE_PINS,PERIOD_NS,REGISTER_CELL_COUNT,REPRESENTATIVE_SINKS,TOP_HIERARCHY_COUNTS,REF_NAME_COUNTS"
puts $mf "IMAGE_ROLE,CLOCK_NAME,REGISTER_CELL,REF_NAME,TOP_HIERARCHY"

set clock_names [lsort -dictionary -unique [get_property NAME [get_clocks -quiet -include_generated_clocks *]]]
foreach clock_name $clock_names {
    set clock_obj [get_clocks -quiet $clock_name]
    if {[llength $clock_obj] != 1} {
        error "Expected one clock object for '$clock_name', got [llength $clock_obj]"
    }

    set source_pins [safe_property SOURCE_PINS $clock_obj]
    set period [safe_property PERIOD $clock_obj]
    set regs [all_registers -quiet -clock $clock_obj -cells]
    if {[llength $regs] == 0} {
        set reg_names {}
    } else {
        set reg_names [lsort -dictionary -unique [get_property NAME $regs]]
    }

    set ref_counts [dict create]
    set hierarchy_counts [dict create]
    set representatives {}
    foreach reg_name $reg_names {
        set reg_obj [get_cells -quiet $reg_name]
        set ref_name [safe_property REF_NAME $reg_obj]
        if {[string first "/" $reg_name] >= 0} {
            set top_hierarchy [lindex [split $reg_name "/"] 0]
        } else {
            set top_hierarchy "TOP"
        }
        dict incr ref_counts $ref_name
        dict incr hierarchy_counts $top_hierarchy
        if {[llength $representatives] < 5} {
            lappend representatives $reg_name
        }
        puts $mf [join [list \
            [csv_quote $role] \
            [csv_quote $clock_name] \
            [csv_quote $reg_name] \
            [csv_quote $ref_name] \
            [csv_quote $top_hierarchy]] ","]
    }

    set ref_parts {}
    foreach key [lsort -dictionary [dict keys $ref_counts]] {
        lappend ref_parts "$key=[dict get $ref_counts $key]"
    }
    set hierarchy_parts {}
    foreach key [lsort -dictionary [dict keys $hierarchy_counts]] {
        lappend hierarchy_parts "$key=[dict get $hierarchy_counts $key]"
    }

    puts $sf [join [list \
        [csv_quote $role] \
        [csv_quote $clock_name] \
        [csv_quote $source_pins] \
        [csv_quote $period] \
        [csv_quote [llength $reg_names]] \
        [csv_quote [join $representatives ";"]] \
        [csv_quote [join $hierarchy_parts ";"]] \
        [csv_quote [join $ref_parts ";"]]] ","]
}

close $sf
close $mf

set st [open $status_path w]
puts $st "ROLE=$role"
puts $st "TOP=$top"
puts $st "PART=$part"
puts $st "CLOCK_COUNT=[llength $clock_names]"
puts $st "CLOCK_REGISTER_INVENTORY=PASS"
puts $st "QUERY_METHOD=all_registers_-clock_-cells"
puts $st "DCP_WRITE_COMMANDS=0"
puts $st "IMPLEMENTATION_COMMANDS=0"
close $st

close_design
puts "CLOCK_INVENTORY_PASS role=$role clocks=[llength $clock_names]"
flush stdout
exit 0
